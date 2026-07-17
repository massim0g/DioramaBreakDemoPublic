package massimodin //@nested-tags:combat/

combat_rect_in_grid :: #force_inline proc "contextless"(x,y,w,h:int) -> bool{
	return x>=0 && y>=0 && x+w<=combat.grid_size.x && y+h<=combat.grid_size.y
}

//check if a rectangular space in the combat grid is occupied by an obstacle (either a non-unit, or is just outside the grid). Extremely fast.
combat_collision_static_i :: proc "contextless" (x,y,w,h:int) -> bool{ 
	if(!combat_rect_in_grid(x,y,w,h)) do return true
	bitMask:u128 = ((u128(1) << u128(w)) - u128(1)) << u128(x)
	for i in y..<(y+h){
		if(combat.occupancy_grid[i] & bitMask != 0) do return true
	}
	return false
}
combat_collision_static_rect :: #force_inline proc "contextless"(rect:Recti) -> bool{
	return combat_collision_static(rect.x, rect.y, rect.size.x, rect.size.y)
}
combat_collision_static :: proc{combat_collision_static_i, combat_collision_static_rect}

combat_collision :: proc(rect:Recti) -> bool{
	return combat_collision_static(rect) || len(combat_collision_entity_rect(rect)) > 0
}
// combat_collision_ghosts :: proc(rect:Recti, step:=-1) -> bool{
// 	return combat_collision_static(rect.x, rect.y, rect.size.x, rect.size.y) || len(combat_collision_unit_ghosts(rect, step)) > 0
// }

combat_collision_entity_position :: proc(pos:Vec2i, allocator:=context.temp_allocator) -> []^CombatEntity{
	if(!combat_rect_in_grid(pos.x, pos.y, 1, 1)) do return nil
	occupants := grid_get_ptr(combat.grid, pos.x, pos.y).occupants[:]
	out := make([]^CombatEntity, len(occupants), allocator)
	for &ptr,i in out{
		ptr = coget(occupants[i])
	}
	return out
}
combat_collision_entity_positions :: proc(positions:[]Vec2i, allocator:=context.temp_allocator) -> []^CombatEntity{
	out := make([dynamic]^CombatEntity, 0, len(positions), allocator)
	for pos in positions{
		occupants := combat_collision_entity_position(pos)
		for col in occupants{
			if !contains(out, col) do append(&out, col)
		}
	}

	shrink(&out)
	return out[:]
}
combat_collision_entity_rect :: proc(rect:Recti, allocator:=context.temp_allocator) -> []^CombatEntity{
	out := make([dynamic]^CombatEntity, 0, 1, allocator)

	if earlyCol := combat_collision_entity_position(rect.pos); len(earlyCol) > 0 && earlyCol[0].rect == rect{ //optimization for common "edge"-case
		append(&out, earlyCol[0])
		return out[:]
	}

	for y:=rect.y; y<=rect_get_bottom(rect);y+=1{
		for x:=rect.x; x<=rect_get_right(rect);x+=1{
			occupants := combat_collision_entity_position({x,y})
			for col in occupants{
				if !contains(out, col) do append(&out, col)
			}
		}
	}

	shrink(&out)
	return out[:]
}
combat_collision_entity :: proc{combat_collision_entity_position, combat_collision_entity_positions, combat_collision_entity_rect}

combat_collision_unit_position :: proc(pos:Vec2i, whitelist:=~CombatUnitTypes{}, ignore:^CombatUnit=nil, allocator:=context.temp_allocator) -> []^CombatUnit{
	out := make([dynamic]^CombatUnit, allocator)
	occupants := combat_collision_entity_position(pos)
	for ent in occupants{
		if unit, ok := cofind(ent, CombatUnit); ok && unit.unitType in whitelist && unit!=ignore do append(&out, unit)
	}
	shrink(&out)
	return out[:]
}
combat_collision_unit_positions :: proc(positions:[]Vec2i, whitelist:=~CombatUnitTypes{}, ignore:^CombatUnit=nil, allocator:=context.temp_allocator) -> []^CombatUnit{
	out := make([dynamic]^CombatUnit, allocator)
	for pos in positions{
		occupants := combat_collision_unit_position(pos, whitelist, ignore)
		for col in occupants{
			if !contains(out, col) do append(&out, col)
		}
	}

	shrink(&out)
	return out[:]
}
combat_collision_unit_rect :: proc(rect:Recti, whitelist:=~CombatUnitTypes{}, ignore:^CombatUnit=nil, allocator:=context.temp_allocator) -> []^CombatUnit{
	area := rect_area(rect)
	if area <= 0 do return nil
	
	out := make([dynamic]^CombatUnit, allocator)
	units := combatUnits_get()

	if area < len(units)/3{
		for y:=rect.y; y<=rect_get_bottom(rect);y+=1{
			for x:=rect.x; x<=rect_get_right(rect);x+=1{
				occupants := combat_collision_unit_position({x,y}, whitelist, ignore)
				for col in occupants{
					if !contains(out, col) do append(&out, col)
				}
			}
		}
	}
	else{ //since there are usually few units, compared to enities in general, this can often be much faster
		for unit in units{
			if unit.unitType in whitelist && unit!=ignore && rects_overlap(unit.combatEntity.rect, rect) do append(&out, unit)
		}
	}


	shrink(&out)
	return out[:]
}
combat_collision_unit :: proc{combat_collision_unit_position, combat_collision_unit_positions, combat_collision_unit_rect}

combat_collision_unit_ghosts :: proc(rect:Recti, step:=-1, whitelist:=~CombatUnitTypes{}, ignore:^CombatUnit=nil, allocator:=context.temp_allocator) -> []^CombatUnit{
	out := make([dynamic]^CombatUnit, allocator)

	units := combatUnits_get()

	for unit in units{
		if unit.unitType in whitelist && unit!=ignore && rects_overlap(combatUnit_ghost_rect(unit, step), rect){
			append(&out, unit)
		} 
	}

	shrink(&out)
	return out[:]
}

//performs an A* search to get the shortest path to the closest point within a given target rect. 
combat_pathfind :: proc(entity:^CombatEntity, targetRect:Recti, ignoreEntitiesAtTarget:=true, startPos:=Vec2i{-1,-1}, allocator:=context.temp_allocator) -> []Vec2i{
	MAX_ITERATIONS :: 512 //how long to search before giving up, in case there's no path
	Node :: struct{
		distanceFromStart:i16, //g-cost
		heuristicDistanceFromEnd:i16, //h-cost
		fCost:i16,
		prevDir:u8,
		searchPhase:u8 //0 - unvisited, 1 - open, 2 - closed
	}
	NodeRef :: struct{ //for priority queue
		using node:^Node,
		pos:Vec2i
	}

	@(static) nodeGrid:Grid(Node) //grid of pathfinding information
	if(combat.grid_size != {nodeGrid.w, nodeGrid.h}){
		if(nodeGrid.w == 0 && nodeGrid.h == 0) do nodeGrid = grid_make(Node, combat.grid_size.x, combat.grid_size.y, default_allocator)
		else do grid_resize(&nodeGrid, 0, 0, combat.grid_size.x - nodeGrid.w, combat.grid_size.y - nodeGrid.h)
	}
	grid_zero(&nodeGrid)

	//DEPRECATED since units no longer exist in occupancy grid
	// combatEntity_unplace(entity)
	// defer combatEntity_place(entity)

	// entitiesAtTarget:[]^CombatEntity
	// if(ignoreEntityAtTarget){
	// 	entitiesAtTarget = combat_collision_entity(targetRect)
	// 	if(entitiesAtTarget != nil){
	// 		for &e in entitiesAtTarget{
	// 			combatEntity_unplace(e)
	// 		}
	// 	}
	// }
	// defer if(entitiesAtTarget != nil){
	// 	for &e in entitiesAtTarget{
	// 		combatEntity_place(e)
	// 	}
	// }

	startRect := entity.rect
	if startPos != {-1,-1} do startRect.pos = startPos
	maskW := entity.size.x
	maskH := entity.size.y
	gridSize := cast([2]i16)combat.grid_size

	openQueue:PQueue(NodeRef)
	init(&openQueue, 
		proc(a,b:NodeRef) -> bool{ 
			if(a.fCost == b.fCost) do return a.heuristicDistanceFromEnd < b.heuristicDistanceFromEnd
			return a.fCost < b.fCost 
		},
		context.temp_allocator
	)

	nearestNode := NodeRef{grid_get_ptr(nodeGrid, startRect.pos), startRect.pos}
	nearestNode.heuristicDistanceFromEnd = i16(recti_manhattan_distance(Recti{startRect.pos, {1,1}}, targetRect))
	nearestNode.fCost = nearestNode.heuristicDistanceFromEnd
	nearestNode.searchPhase = 1
	append(&openQueue, nearestNode)

	checkAddend := CARDINAL_VEC2IS
	for i in 0..<MAX_ITERATIONS{
		if(len(openQueue) == 0) do break
		currentNode:NodeRef = pop(&openQueue)
		currentNode.searchPhase = 2

		if(rect_contains(targetRect, currentNode.pos)){
			nearestNode = currentNode
			break
		}

		if(currentNode.heuristicDistanceFromEnd < nearestNode.heuristicDistanceFromEnd) do nearestNode = currentNode
		
		newDist := currentNode.distanceFromStart+1

		//reverse every other iteration to preferentially create diagonals when pathing
		endD := i%2
		iter := endD*2-1
		startD := (i+1)%2
		startD = startD*4 - startD
		endD = endD*5 - 1
		for d:=startD; d!=endD; d+=iter{
			newPos := currentNode.pos + checkAddend[d]
			if(combat_collision_static(newPos.x, newPos.y, maskW, maskH)) do continue
			newNode:^Node = grid_get_ptr(nodeGrid, newPos)
			if(newNode.searchPhase == 2) do continue
			if(newNode.searchPhase == 0 || newNode.distanceFromStart > newDist){
				newNode.distanceFromStart = newDist
				if(newNode.heuristicDistanceFromEnd == 0) do newNode.heuristicDistanceFromEnd = i16(recti_manhattan_distance(Recti{newPos, {1,1}}, targetRect))
				newNode.fCost = newNode.distanceFromStart + newNode.heuristicDistanceFromEnd
				newNode.prevDir = u8(d)
				if(newNode.searchPhase == 0){
					newNode.searchPhase = 1
					append(&openQueue, NodeRef{newNode, newPos})
				}
			}
		}
	}

	path := make([dynamic]Vec2i, nearestNode.distanceFromStart+1, allocator)
	posAdjust := [4]Vec2i{
		{-1, 0},
		{0, 1},
		{1, 0},
		{0, -1}
	}
	for i:=len(path)-1;i>=1;i-=1{
		path[i] = nearestNode.pos
		newPos := nearestNode.pos + posAdjust[nearestNode.prevDir]
		nearestNode = {grid_get_ptr(nodeGrid, newPos), newPos}
	}
	path[0] = nearestNode.pos

	if !ignoreEntitiesAtTarget{
		ignore := cofind(entity, CombatUnit)
		rect := Recti{peek(path), startRect.size}
		for len(path) > 1 && (combat_collision_static(rect.x, rect.y, rect.size.x, rect.size.y) || len(combat_collision_unit_ghosts(rect, ignore=ignore))>0){
			pop(&path)
			rect.pos = peek(path)
		}
	}

	shrink(&path)
	return path[:]
}

combat_attackers_get :: proc(attacked:^CombatUnit, attackedRect:Recti, triggerStepFilter:=-1, checkExactTriggerStep:=false, whitelist:=~CombatUnitTypes{}) -> []^CombatActionQueued{
	out := make([dynamic]^CombatActionQueued, context.temp_allocator)

	units := combatUnits_get()
	for unit in units{
		if unit.unitType not_in whitelist do continue

		attack := combatUnit_queued_action_find(unit, triggerStepFilter=triggerStepFilter, checkExactTriggerStep=checkExactTriggerStep)
		if attack == nil || !rects_overlap(attack.targetBounds, attackedRect) do continue

		switch t in attack.target{
			case Vec2i, ^CombatUnit: append(&out, attack)
			case []^CombatUnit: if contains(t, attacked) do append(&out, attack)
			case []Vec2i:
				for p in t{
					if rect_contains(attackedRect, p){
						append(&out, attack)
						break
					}
				}
		}
	}

	shrink(&out)
	return out[:]
}

combat_nearest_safe_space :: proc(unit:^CombatUnit, startPos:Vec2i, step:=-1, attackersWhitelist:=~CombatUnitTypes{}) -> Vec2i{
	maxDist :: 512
	visitedMap := make(map[Vec2i]bool, context.temp_allocator)
	visitedArr := make([dynamic]Vec2i, context.temp_allocator)

	append(&visitedArr, startPos)
	visitedMap[startPos] = true

	distanceChecked := 0
	distanceThreshold := len(visitedArr)

	checkSize := unit.combatEntity.rect.size
	combatEntity_unplace(unit.combatEntity)
	defer combatEntity_place(unit.combatEntity)

	for i:=0; i<len(visitedArr); i+=1{
		if(i==distanceThreshold){
			distanceThreshold = len(visitedArr)
			distanceChecked += 1
			if(distanceChecked == maxDist) do return {-1,-1}
		}

		pos := visitedArr[i]

		checkRect := Recti{pos, checkSize}
		if combat_collision_static(checkRect.x, checkRect.y, checkRect.size.x, checkRect.size.y) do continue

		if len(combat_attackers_get(unit, checkRect, step, false, attackersWhitelist)) == 0 && len(combat_collision_unit_ghosts(checkRect, step)) == 0{
			return pos
		}

		for d in CARDINAL_VEC2IS{
			newPos := pos+d
			if !(newPos in visitedMap){
				visitedMap[newPos] = true
				append(&visitedArr, newPos)
			}
		}
	}
	return {-1,-1}
}

combat_nearest_free_space :: proc(unit:^CombatUnit, startPos:Vec2i, liftEntity:=true) -> Vec2i{
	maxDist :: 512
	visitedMap := make(map[Vec2i]bool, context.temp_allocator)
	visitedArr := make([dynamic]Vec2i, context.temp_allocator)

	append(&visitedArr, startPos)
	visitedMap[startPos] = true

	distanceChecked := 0
	distanceThreshold := len(visitedArr)

	checkSize := unit.combatEntity.rect.size

	if liftEntity do combatEntity_unplace(unit.combatEntity)
	defer if liftEntity do combatEntity_place(unit.combatEntity)

	for i:=0; i<len(visitedArr); i+=1{
		if(i==distanceThreshold){
			distanceThreshold = len(visitedArr)
			distanceChecked += 1
			if(distanceChecked == maxDist) do return {-1,-1}
		}

		pos := visitedArr[i]

		if !combat_collision(Recti{pos, checkSize}) do return pos

		for d in CARDINAL_VEC2IS{
			newPos := pos+d
			if !(newPos in visitedMap){
				visitedMap[newPos] = true
				append(&visitedArr, newPos)
			}
		}
	}
	return {-1,-1}
}