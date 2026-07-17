package massimodin //@nested-tags:engine/collision

import "core:slice"
import "../tracy"

COLLISION_REGION_SIZE :: DISPLAY_WIDTH/4 //benchmark to get a good value

CollisionRegion :: struct{
	colliders:[dynamic]CoRefEx(Collider),
	stageMeshEdges:[dynamic]Line
}

CollisionSystem :: struct{
	_regions:Grid(CollisionRegion),
	_colliders_draw:bool
}
collision_system:^CollisionSystem

_collision_system_init :: proc(){
	collision_system = new(CollisionSystem)
} 

//called on stage start
_collision_regions_init :: proc(){
	size := ceili(stage.bounds.size/f32(COLLISION_REGION_SIZE))
	collision_system._regions = grid_make(CollisionRegion, size.x, size.y, stage.allocator)
	for &region,i in collision_system._regions.buf{
		init(&region.colliders, stage.allocator)
		init(&region.stageMeshEdges, stage.allocator)

		regionBounds := Rect{stage.bounds.pos + Vec2(grid_index_to_pos(collision_system._regions, i)*COLLISION_REGION_SIZE), COLLISION_REGION_SIZE}
		for edge in stage.collisionMesh.edges{
			l := mesh_edge_to_line(stage.collisionMesh, edge)
			if rect_intersects(regionBounds, l) do append(&region.stageMeshEdges, l)
		}
	}
}

_collision_regions_get :: proc(overlap:Rect, allocator:=context.temp_allocator) -> [dynamic]^CollisionRegion{
	out := make([dynamic]^CollisionRegion, allocator)
	if overlap.size == {0,0} do return out
	overlap := overlap
	overlap.pos -= stage.bounds.pos
	right := min(int(rect_get_right(overlap)), collision_system._regions.w*COLLISION_REGION_SIZE) 
	bottom := min(int(rect_get_bottom(overlap)), collision_system._regions.h*COLLISION_REGION_SIZE)
	for y:=max(0, int(floor(overlap.y/COLLISION_REGION_SIZE))); y*COLLISION_REGION_SIZE<=bottom; y+=1{
		for x:=max(0, int(floor(overlap.x/COLLISION_REGION_SIZE))); x*COLLISION_REGION_SIZE<=right; x+=1{
			if grid_contains(collision_system._regions, x, y) do append(&out, grid_get_ptr(collision_system._regions, x, y))
		}
	}

	return out
}

//Sets the collider bounds and updates its position in the region data structure, given a new position
_collider_update :: proc(collider:^Collider){
	previousRegions := _collision_regions_get(collider.bounds)

	scale := collider.transform.scale
	origin := collider.origin
	translation := collider.transform.pos - origin*scale

	//print(origin, scale, collider.transform.pos, translation)

	when DEBUG do collider.debugTexPos = round(origin*scale + translation)

	collider.bounds = rect_make_points_f(round(translation), round(collider.baseSize*scale + translation))

	if len(collider.basePrecisePoints) > 0{
		resize(&collider.precisePoints, len(collider.basePrecisePoints))

		for p,i in collider.basePrecisePoints{
			collider.precisePoints[i] = cast([2]i16)round(Vec2(p)*scale + translation)
		}
	}

	newRegions := _collision_regions_get(collider.bounds)

	//quick equality check
	prevSlice := previousRegions[:]
	newSlice := newRegions[:]
	if(slice.equal(prevSlice, newSlice)) do return

	exRef := crx(collider)
	for region in prevSlice{
		ind, found := slice.linear_search(newRegions[:], region)
		if(!found){
			ind, found = slice.linear_search(region.colliders[:], exRef)
			if(found) do unordered_remove(&region.colliders, ind)
		}
		else{
			unordered_remove(&newRegions, ind)
		}
	}

	for region in newRegions{
		append(&region.colliders, exRef)
	}
}

@(disabled=!DEBUG)
_colliders_debug_draw :: proc(){
	if(!collision_system._colliders_draw) do return
	camera_set(stage.camera_pos)
	drawRect := Recti{{0,0},{COLLISION_REGION_SIZE, COLLISION_REGION_SIZE}}
	for y in 0..<collision_system._regions.h{
		for x in 0..<collision_system._regions.w{
			drawRect.x = int(stage.bounds.pos.x) + x*COLLISION_REGION_SIZE
			drawRect.y = int(stage.bounds.pos.y) + y*COLLISION_REGION_SIZE
			draw_rect(drawRect, Color{u8(x)*50, u8(y)*50, 0},50./255.)
			colliders := &(grid_get_ptr(collision_system._regions, x, y).colliders)
			for ref in colliders{
				collider := coget(ref)
				if(collider.debugTex.ptr == nil){
					draw_rect(collider.bounds, Color{238, 125, 230}, 0.5)
				}
				else{
					spr := texes_to_sprite({collider.debugTex}, collider.origin)
					//print(cofind(collider, Spriter).mySprite.name, collider.origin, collider.debugTexPos, collider.pos)
					sprite_draw_ex(spr, collider.debugTexPos, 0, collider.transform.scale)
				}
			}
		}
	}
	camera_reset()
}

collision_components_rect :: proc(checkBounds:Rect, $componentType:typeid, ignore:^Collider=nil, precisePoints:PrecisePoints=nil, blacklist:=ColliderGroupMask{}, allocator:=context.temp_allocator) -> []^componentType{

	out := make([dynamic]^componentType, allocator)

	checkerPrecise := len(precisePoints) != 0
	regions := _collision_regions_get(checkBounds)
	
	for region in regions{
		for ref in region.colliders{
			foundCollider := coget(ref)
			if(foundCollider == nil || foundCollider == ignore || (foundCollider.collisionGroups & blacklist) != nil) do continue
			if(rects_overlap(checkBounds, foundCollider.bounds)){
				
				co, f := cofind(foundCollider.entity, componentType) //check this first to avoid expensive precise collisions
				if(!f) do continue

				overlap := false
				foundPrecise := len(foundCollider.precisePoints) != 0
				if(foundPrecise && checkerPrecise){ //hot!
					for p1 in precisePoints{
						for p2 in foundCollider.precisePoints{
							if(p1 == p2){
								append(&out, co)
							}
						}
					}
				}
				else if(foundPrecise){
					for p in foundCollider.precisePoints{
						if(rect_contains(checkBounds, Vec2(p))){
							append(&out, co)
						}
					}
				}
				else if(checkerPrecise){
					for p in precisePoints{
						if(rect_contains(foundCollider.bounds, Vec2(p))){
							append(&out, co)
						}
					}
				}
				else do append(&out, co)
			}
		}
	}

	shrink(&out)
	return out[:]
}
collision_components_vec2:: #force_inline proc(collider:^Collider, pos:Vec2, $componentType:typeid, blacklist:=ColliderGroupMask{}, allocator:=context.temp_allocator) -> []^componentType{
	return collision_components_rect(Rect{pos-collider.origin, collider.size}, componentType, collider, collider.precisePoints[:], blacklist, allocator)
}
collision_components_f :: #force_inline proc(collider:^Collider, x,y:f32, $componentType:typeid, blacklist:=ColliderGroupMask{}, allocator:=context.temp_allocator) -> []^componentType{
	return collision_components_vec2(collider, Vec2{x,y}, componentType, blacklist, allocator)
}
collision_components :: proc{collision_components_rect, collision_components_f, collision_components_vec2}

collision_component_rect :: proc(checkBounds:Rect, $componentType:typeid, ignore:^Collider=nil, precisePoints:PrecisePoints=nil, blacklist:=ColliderGroupMask{}) -> (component:^componentType, found:bool){ //Note: Because collider has `using bounds`, this cannot be added to the list of overloads since the compiler gets confused.
	checkerPrecise := len(precisePoints) != 0
	regions := _collision_regions_get(checkBounds)
	
	for region in regions{
		for ref in region.colliders{
			foundCollider := coget(ref)
			if(foundCollider == nil || foundCollider == ignore || (foundCollider.collisionGroups & blacklist) != nil || foundCollider.unique) do continue
			
			if(rects_overlap(checkBounds, foundCollider.bounds)){
				co, f := cofind(foundCollider.entity, componentType) //check this first to avoid expensive precise collisions
				if(!f) do continue

				overlap := false
				foundPrecise := len(foundCollider.precisePoints) != 0
				if(foundPrecise && checkerPrecise){ //hot!
					for p1 in precisePoints{
						for p2 in foundCollider.precisePoints{
							if(p1 == p2){
								return co, f
							}
						}
					}
				}
				else if(foundPrecise){
					for p in foundCollider.precisePoints{
						if(rect_contains(checkBounds, Vec2(p))){
							return co, f
						}
					}
				}
				else if(checkerPrecise){
					for p in precisePoints{
						if(rect_contains(foundCollider.bounds, Vec2(p))){
							return co, f
						}
					}
				}
				else do return co, f
			}
		}
	}

	return
}
collision_component_vec2 :: #force_inline proc(collider:^Collider, pos:Vec2, $componentType:typeid, blacklist:=ColliderGroupMask{}) -> (component:^componentType, found:bool){
	return collision_component_rect(Rect{pos-collider.origin, collider.size}, componentType, collider, collider.precisePoints[:], blacklist)
}
collision_component_collider :: #force_inline proc(collider:^Collider, $componentType:typeid, blacklist:=ColliderGroupMask{}) -> (component:^componentType, found:bool){
	return collision_component_rect(collider.bounds, componentType, collider, collider.precisePoints[:], blacklist)
}
collision_component_f :: #force_inline proc(collider:^Collider, x,y:f32, $componentType:typeid, blacklist:=ColliderGroupMask{}) -> (component:^componentType, found:bool){
	return collision_component_vec2(collider, Vec2{x,y}, componentType, blacklist)
}
collision_component :: proc{collision_component_f, collision_component_vec2, collision_component_collider}

collision_f :: proc(collider:^Collider, x,y:f32, $componentType:typeid, blacklist:=ColliderGroupMask{}) -> bool{
	_,found := collision_component_vec2(collider, Vec2{x,y}, componentType, blacklist)
	return found
}
collision_vec2 :: proc(collider:^Collider, pos:Vec2, $componentType:typeid, blacklist:=ColliderGroupMask{}) -> bool{
	_,found := collision_component_vec2(collider, pos, componentType, blacklist)
	return found
}
collision :: proc{collision_f, collision_vec2}

collision_stage_mesh_vec2 :: #force_inline proc(collider:^Collider, pos:Vec2) -> bool{
	return collision_stage_mesh_rect(Rect{pos-collider.origin, collider.size}, collider.precisePoints[:])
}
collision_stage_mesh_rect :: proc(checkBounds:Rect, precisePoints:PrecisePoints=nil) -> bool{
	regions := _collision_regions_get(checkBounds)

	if len(precisePoints) != 0{
		for region in regions{
			for edge in region.stageMeshEdges{
				if rect_intersects(checkBounds, edge){
					for p in precisePoints{
						if rect_intersects({Vec2(p), 1}, edge) do return true
					}
				}
			}
		}
	}
	else{
		for region in regions{
			for edge in region.stageMeshEdges{
				if rect_intersects(checkBounds, edge) do return true
			}
		}
	}

	return false
}
collision_stage_mesh :: proc{collision_stage_mesh_rect, collision_stage_mesh_vec2}

collision_stage :: proc(collider:^Collider, pos:Vec2, blacklist:=ColliderGroupMask{}) -> bool{
	when tracy.TRACY_ENABLE{ //the inner procs here loop *a lot*
		lastTAT := tracy_auto_trace
		tracy_auto_trace = false
		defer tracy_auto_trace = lastTAT
	}
	return collision(collider, pos, StageInteractable, blacklist) || collision_stage_mesh(collider, pos)
}

//Quickly calculate the number of tiles in a given flood fill
flood_fill_tile_count :: #force_inline proc "contextless" (distance:int, startSize:=Vec2i{1,1}, includeStart:=true) -> int{
	return (startSize.x+2*distance)*(startSize.y+2*distance) - 2*distance*(distance+1) - startSize.x*startSize.y*int(!includeStart)
}

flood_fill :: proc(startPos:Vec2i, distance:int, startSize:=Vec2i{1,1}, includeStart:=true, removeOutsideGrid:=false, allocator:=context.temp_allocator) -> []Vec2i{
	assert(distance > 0, "Attempted to flood fill distance below 1!")

	cap := flood_fill_tile_count(distance, startSize)
	visited := make(map[Vec2i]bool, cap, context.temp_allocator)
	out := make([dynamic]Vec2i, 0, cap, allocator)

	for y in 0..<startSize.y{
		for x in 0..<startSize.x{
			pos := Vec2i{x,y}+startPos
			append(&out, pos)
			visited[pos] = true
		}
	}

	distanceChecked := 0
	distanceThreshold := len(out)
	for i:=0; i<len(out); i+=1{
		if(i==distanceThreshold){
			distanceThreshold = len(out)
			distanceChecked += 1
			if(distanceChecked == distance) do break
		}

		pos := out[i]

		for d in CARDINAL_VEC2IS{
			newPos := pos+d
			if !(newPos in visited){
				visited[newPos] = true
				append(&out, newPos)
			}
		}
	}


	if(!includeStart) do remove_range(&out, 0, startSize.x*startSize.y)
	
	if removeOutsideGrid{
		#reverse for p,i in out{
			if p.x<0||p.y<0||p.x>=combat.grid.w||p.y>=combat.grid.h do ordered_remove(&out, i)
		}
	}

	shrink(&out)
	return out[:]
}

