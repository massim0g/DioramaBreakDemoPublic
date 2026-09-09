package massimodin //@nested-tags:combat/actions

import "core:strings"
CombatAction :: struct{
	id:string,
	nameStream:bool,
	startup:int,
	cooldown:int,
	damage:int,
	damageKind:CombatDamageKind,
	hitstun:int,
	kind:CombatActionKind,
	aimKind:CombatActionAimKind,
	aimRange:int,
	targetMask:CombatTargetMask,
	selfTargetable:bool, //whether free aim actions can aim within the user's bounds
	aimingMasksDefaultUserSize:Vec2i, //cached aiming masks must assume a user size. If the actual user size differs, masks will be recalculated on the spot
	aimingRangeMask:[]Vec2i, //determines the range outline when previewing the action
	aimingBoundsMask:[]Vec2i, //determines the aiming bounds during action targeting
	actionSelectIcon:^Sprite,
	cameraFocus:CombatActionCameraFocus,
	resolve:proc(caq:^CombatActionQueued)->bool,
	updateGhostPosition:proc(caq:^CombatActionQueued, ghostPos:^Vec2i)
}

CombatActionQueued :: struct{
	using action:^CombatAction,
	uniqueID:uuid,
	startupCounter:int,
	user:^CombatUnit,
	target:CombatTarget,
	targetBounds:Recti,
	userPosOnUsage:Vec2i,
	aimOffset:Vec2i,
	lastValidAimPos:Vec2i,
	aimDir:Dir,
	initialized:bool,
	resolveState:rawptr
}

CombatTarget :: union{
	[]Vec2i,
	Vec2i,
	^CombatUnit,
	[]^CombatUnit
}

CombatTargetMask :: union{
	int, //flood-fill mask
	Vec2i, //rectangular mask with no origin
	^ColliderMask, //precise/origined mask
	^Sprite //obtain ColliderMask from sprite
}

//Mainly used by unit AI
CombatActionKind :: enum{ 
	attack,
	travel,
	evasion,
	support,
	defense,
	basic //for certain special-case actions, such as basic movement
}
CombatActionKinds :: bit_set[CombatActionKind]

CombatActionAimKind :: enum{ 
	freeAim, //unrestricted aiming, place an area anywhere within a range centered on the user
	freeAimCornered, //similar to above, but range only expands from top-left corner of user. Mainly for movement.
	directionalRanged, //place an area within a range locked to the 4 cardinal directions
	directional, //aim the action in one of the 4 cardinal directions. Used for most melee actions
	noAim, //no aiming, action will always have the same target area. Used for actions that e.g. hit a fixed area around the user
	user //action only affects the user
}
CombatActionAimKinds :: bit_set[CombatActionAimKind]

CombatActionCameraFocus :: enum{
	target,
	user,
	userTracking
}


//TARGETS
combatTargetMask_bounds :: proc(mask:CombatTargetMask, aimPos:=Vec2i{0,0}) -> (bounds:Recti, origin:Vec2i){
	switch m in mask{
		case int: 
			origin = Vec2i{m,m}
			return Recti{aimPos - origin, 2*origin+{1,1}}, origin
		case Vec2i: return Recti{aimPos, m}, Vec2i{}
		case ^ColliderMask, ^Sprite:
			cMask:^ColliderMask
			if s, ok := mask.(^Sprite); ok do cMask = s.mask
			else do cMask = mask.(^ColliderMask)

			return Recti{aimPos - cMask.origin, cMask.size}, cMask.origin
	}
	unreachable()
}

//returns whether a hit occured
combat_target_damage :: proc(target:CombatTarget, damage:int, hitstun:int, damageKind:=CombatDamageKind.physical, attacker:^CombatUnit=nil) -> bool{
	
	hitUnits := combat_target_get_hit_units(target, attacker)

	for unit in hitUnits{
		combatUnit_damage(unit, damage, hitstun, damageKind, attacker)
	}

	combat_event_process(CombatEventAttackEnd{
		attacker,
		hitUnits
	})
	out := len(hitUnits) > 0

	if out{
		audio_play(au.combatHit)
		for unit in hitUnits{
			if unit.hp <= 0 do audio_play(au.combatKO)
		}
	}

	return out
}


combat_target_get_hit_units :: proc(target:CombatTarget, ignore:^CombatUnit=nil) -> []^CombatUnit{
	if target == nil do return nil

	hitUnits:[]^CombatUnit
	switch t in target{
		case []Vec2i: hitUnits = combat_collision_unit(t)
		case Vec2i: hitUnits = combat_collision_unit(t)
		case ^CombatUnit: 
			hitUnits = make([]^CombatUnit, 1, context.temp_allocator)
			hitUnits[0] = t
		case []^CombatUnit: hitUnits = t
	}

	if hitUnits == nil do return nil

	out := slice_to_array(hitUnits, context.temp_allocator)
	#reverse for unit,i in out{
		if unit == ignore || unit.unitState != .alive do unordered_remove(&out, i)
	}
	return out[:]
}

combat_target_damage_seq :: proc(target:CombatTarget, damage:int, hitstun:int, damageKind:=CombatDamageKind.physical, attacker:^CombatUnit=nil) -> bool{
	stopTime :: 16
	if seq_open("combat__target_damage"){
		if seq_cue(0){
			if !combat_target_damage(target, damage, hitstun, damageKind, attacker){
				return seq_close(.end)
			}
			combat.time_stop_mode = .enabled
			camera_shake(stopTime, 3.5)
		}

		if seq_cue(stopTime){
			combat.time_stop_mode = .disabled
			return seq_close(.end)
		}
	}
	return seq_close()
}

combatTarget_bounds :: proc(target:CombatTarget) -> Recti{
	switch t in target{
		case ^CombatUnit: return t.combatEntity.rect
		case Vec2i: return Recti{t, {1,1}}
		case []Vec2i: return vec2i_array_bounds(t)
		case []^CombatUnit:
			out:Recti = {INT_MAX, 0}
			for unit in t{
				uRect := unit.combatEntity.rect
				out.pos = min(out.pos, uRect)
				rect_set_right(&out, max(rect_get_right(out), rect_get_right(uRect)))
				rect_set_bottom(&out, max(rect_get_bottom(out), rect_get_bottom(uRect)))
			}
			return out
	}
	unreachable()
}

//ACTION HELPER PROCS
combatAction_get_targetable_area :: proc(action:^CombatAction, user:^CombatUnit, userPosOnUsage:Vec2i, allocator:=context.temp_allocator) -> CombatTarget{
	switch action.aimKind{
		case .freeAim:
			return flood_fill(userPosOnUsage, action.aimRange, user.combatEntity.size, action.selfTargetable, true, allocator)
		case .freeAimCornered:
			return flood_fill(userPosOnUsage, action.aimRange, {1,1}, action.selfTargetable, true, allocator)
		case .user, .directional, .directionalRanged, .noAim: return user
	}
	unreachable()
}

combatAction_effective_range :: proc(action:^CombatAction, extentsMultiplier:f32=0.5) -> int{
	switch action.aimKind{
		case .freeAim, .freeAimCornered, .directionalRanged: return action.aimRange
		case .directional:
			bounds, origin := combatTargetMask_bounds(action.targetMask)
			return int(f32(bounds.size.x - origin.x)*extentsMultiplier+0.5/extentsMultiplier)
		case .noAim: 
			bounds, origin := combatTargetMask_bounds(action.targetMask)
			return int(f32(origin.x)*extentsMultiplier+0.5/extentsMultiplier)
		case .user: return 0
	}
	unreachable()
}

combatAction_units_in_range :: proc(action:^CombatAction, startStep:int, user:^CombatUnit, userPosOnUsage:Vec2i, extentsMultiplier:f32=0.5, whitelist:=~CombatUnitTypes{}, ignore:^CombatUnit=nil, allocator:=context.temp_allocator) -> []^CombatUnit{
	out := make([dynamic]^CombatUnit, allocator)
	triggerStep := startStep + action.startup
	userRect := Recti{userPosOnUsage, user.combatEntity.size}
	switch action.aimKind{
		case .user: //do nothing
		case .freeAim, .freeAimCornered, .directional, .noAim:
			checkRect := (action.aimKind == .freeAimCornered) ? Recti{userRect.pos, {1,1}} : userRect
			effectiveRange := combatAction_effective_range(action, extentsMultiplier)

			units := combatUnits_get()
			for unit in units{
				if unit.unitState == .alive && unit.unitType in whitelist && unit!=ignore && recti_manhattan_distance(combatUnit_ghost_rect(unit, triggerStep), checkRect) <= effectiveRange do append(&out, unit)
			}

		case .directionalRanged:
			targetableRects := [4]Recti{
				Recti{{userRect.x+userRect.size.x, userRect.y}, {action.aimRange, userRect.size.y}},
				Recti{{userRect.x, userRect.y-action.aimRange}, {userRect.size.x, action.aimRange}},
				Recti{{userRect.x-action.aimRange, userRect.y}, {action.aimRange, userRect.size.y}},
				Recti{{userRect.x, userRect.y+userRect.size.y}, {userRect.size.x, action.aimRange}},
			}

			for rect in targetableRects{
				collidedUnits := combat_collision_unit_ghosts(rect, triggerStep, whitelist, ignore)
				for unit in collidedUnits{
					if unit.unitState == .alive do append(&out, unit)
				}
			}
	}
	
	//stricter mask check for directional actions
	#partial switch action.aimKind{case .directional, .directionalRanged:
		#reverse for unit,i in out{
			targetRect := combatUnit_ghost_rect(unit, triggerStep)
			target,_,_ := combatAction_get_target(action, user, rect_center(targetRect), userPosOnUsage)
			found := false
			for p in target.([]Vec2i){
				if rect_contains(targetRect, p){
					found = true
					break
				}
			}
			if !found do unordered_remove(&out, i)
		}
	}

	shrink(&out)
	return out[:]
}

combatAction_get_target :: proc(action:^CombatAction, targetableArea:CombatTarget, aimPos:Vec2i, userPosOnUsage:Vec2i, allocator:=context.temp_allocator) -> (target:CombatTarget, aimDir:Dir, nearestValidAimPos:Vec2i){

	aimDir = Dir.none
	maskRotation := 0

	switch t in targetableArea{
		case ^CombatUnit: 
			#partial switch action.aimKind{
				case .directional, .directionalRanged:
					entityRect := Recti{userPosOnUsage, t.combatEntity.size}
					center := entityRect.pos + entityRect.size/2 
					aimDir = vec2i_cardinal(aimPos, center)
					maskRotation = int(aimDir)
					surroundingPositions := recti_surrounding_positions(entityRect)
					nearestValidAimPos = surroundingPositions[maskRotation]

					if action.aimKind == .directionalRanged{
						snappedAimPos := aimPos
						#partial switch aimDir{
							case .left, .right: snappedAimPos.y = center.y
							case .up, .down: snappedAimPos.x = center.x
						}
	
						dist := clamp(recti_manhattan_distance(entityRect, Recti{snappedAimPos, {1,1}}), 1, action.aimRange)
						dirVecs := CARDINAL_VEC2IS
						nearestValidAimPos += dirVecs[maskRotation]*(dist-1)
						nearestValidAimPos.x = clamp(nearestValidAimPos.x, 0, combat.grid.w-1)
						nearestValidAimPos.y = clamp(nearestValidAimPos.y, 0, combat.grid.h-1)
					}
				case .noAim:
					if range,ok:=action.targetMask.(int); ok{
						return flood_fill(userPosOnUsage, range, t.combatEntity.size, false, true, allocator), Dir.none, userPosOnUsage
					}
					else do nearestValidAimPos = userPosOnUsage
				case: return targetableArea, .none, nearestValidAimPos
			}
		case Vec2i: nearestValidAimPos = t
		case []Vec2i:
			validPosDistance:f32=99999
			aimPosF := Vec2(aimPos)
			for pos in t{
				if newDist := vec2_distance(Vec2(pos), aimPosF); newDist < validPosDistance {
					nearestValidAimPos = pos
					if(newDist == 0) do break
					validPosDistance = newDist
				}
			}
		case []^CombatUnit:
			panic("todo: multi-unit targetable area")
			
	}
	
	return combatTargetMask_overlay(action.targetMask, nearestValidAimPos, maskRotation, true, allocator), aimDir, nearestValidAimPos
}

combatTargetMask_overlay :: proc(mask:CombatTargetMask, pos:Vec2i, cardinalRotation:=0, removeOutsideGrid:=false, allocator:=context.temp_allocator) -> []Vec2i{
	out:[dynamic]Vec2i
	switch m in mask{
		case int: return flood_fill(pos, m, removeOutsideGrid=removeOutsideGrid, allocator=allocator)
		case Vec2i:
			init(&out, 0, m.x*m.y, allocator)
			for y in 0..<m.y{
				for x in 0..<m.x{
					append(&out, pos + {x,y})
				}
			}

		case ^ColliderMask, ^Sprite:
			mask:^ColliderMask
			if s, ok := m.(^Sprite); ok{
				mask = s.mask
			}
			else do mask = m.(^ColliderMask)

			init(&out, 0, mask.size.x*mask.size.y, allocator)
			topLeft := pos - mask.origin
			if(mask.precisePoints != nil){
				for pp in mask.precisePoints{
					append(&out, topLeft+Vec2i(pp))
				}
			}
			else{
				for y in 0..<mask.size.y{
					for x in 0..<mask.size.x{
						append(&out, topLeft + {x,y})
					}
				}
			}
	}
	
	if cardinalRotation != 0{
		for &p in out{
			p = vec2i_cardinal_rotate(p, cardinalRotation, pos)
		}
	}

	if removeOutsideGrid{
		#reverse for p,i in out{
			if p.x<0||p.y<0||p.x>=combat.grid.w||p.y>=combat.grid.h do ordered_remove(&out, i)
		}
	}

	shrink(&out)
	return out[:]
}

combatAction_enqueue :: proc(user:^CombatUnit, action:^CombatAction, aimPos:=Vec2i{}){

	movement := action == ca.movement

	ghostPos := combatUnit_ghost_position(user)

	aimDir := Dir.none
	target:CombatTarget
	validAimPos:Vec2i
	if(movement){
		assert(user.walkSpeed > 0, "Units with no walk speed cannot use the movement action!")
		target = aimPos
	}
	else do target, aimDir, validAimPos = combatAction_get_target(action, combatAction_get_targetable_area(action, user, combatUnit_ghost_position(user)), aimPos, ghostPos, combat.action_resolve_allocator)
	
	caq := CombatActionQueued{
		action,
		uuid_make(),
		action.startup,
		user,
		target,
		combatTarget_bounds(target),
		ghostPos,
		aimPos - ghostPos,
		validAimPos,
		aimDir,
		false,
		nil
	}
	
	if movement{
		distance := vec2_manhattan_distance(ghostPos, aimPos)
		if distance == 0 do combatAction_enqueue(user, ca.wait) //ensures that enqueueing movement always enqueues something, necessary to prevent infinite loops in the AI
		else{
			for distance > 0 && !combatUnit_action_queue_full(user){
				caq.uniqueID = uuid_make() //ensure unique ids when enqueueing multiple movement actions
				append(&user.queuedActions, caq)
				distance -= user.walkSpeed
			}
		}
	}
	else do append(&user.queuedActions, caq)
}

combatAction_draw_info :: proc(action:^CombatAction, pos:Vec2, drawBox:=false, font:^Font=nil, textCol:Color=COLOR_WHITE){
	fonts.default = font == nil ? fo.Notalot35__16 : font

	name := dialogue_line(di.combatActions, action.id)
	ts := text_size(name)
	if drawBox{
		boxRect := Rect{pos, Vec2{max(ts.x+6, 18*2 + 3), ts.y+19}}
		nineslice_draw(sp.menuBoxOutlined, boxRect)
	}

	drawPos := pos + {3,2}

	if action.kind != .basic{
		padding :: 4
		n:=0
		for _ in 0..<action.startup{
			draw_rect(drawPos+Vec2{f32(n)*padding,0}, drawPos+Vec2{f32(n)*padding,0}+1, color_hex(0xffe7b8))
			n+=1
		}
		draw_rect(drawPos+Vec2{f32(n)*padding,0}-1, drawPos+Vec2{f32(n)*padding,0}+2, color_hex(0xcc2d20)) //todo: different color for different action types?
		n+=1
		for _ in 0..<action.cooldown{
			draw_rect(drawPos+Vec2{f32(n)*padding,0}, drawPos+Vec2{f32(n)*padding,0}+1, color_hex(0xffe7b8))
			n+=1
		}

		drawPos.y += 3
	}
	
	if action.nameStream{
		buf:[3]u8
		for &b in buf{
			if roll(1./45./3.) do b = choose([]u8{'!', '@', '#', '$', '%', '&', '*'})
			else do b = '?'
		}
		name = transmute(string)buf[:]
	}
	text_draw(name, drawPos, textCol)

	drawPos += {3,5+ts.y}

	if action.kind == .attack{

		sprite_draw(sp.miscCombatIcons_damage, drawPos)
		text_draw(int_to_string(action.damage), drawPos + {6, 0}, textCol, alignment=Alignment{-1,0})

		drawPos.x += 17

		sprite_draw(sp.miscCombatIcons_stun, drawPos)
		text_draw(int_to_string(action.hitstun), drawPos + {8, 0}, textCol, alignment=Alignment{-1,0})
	}
}

combatAction_stream_name_generate :: proc(action:^CombatAction, allocator:=context.allocator)->string{
	b := strings.builder_make(context.temp_allocator)
	b2 := strings.builder_make(context.temp_allocator)

	length :: 36
	splits := string_split(dialogue_line(di.combatActions, action.id), ". ")
	splitsCount := random_range(4,5)

	for n in 0..<splitsCount{
		split := get_random_elem(splits)
		l := string_count(split)
		if n == 0{
			strings.write_string(&b, split)
			strings.write_string(&b, ". ")
		}
		else if n == splitsCount-1{
			strings.write_string(&b, split)
		}
		else{
			strings.write_string(&b, split)
			strings.write_string(&b, ". ")
		}
	}
	for string_count(strings.to_string(b)) < length{
		strings.write_rune(&b, '.')
	}
	
	splitsString := strings.to_string(b)
	spill := string_count(splitsString) - length
	strings.write_string(&b2, splitsString[spill/2:][:length])

	return strings.to_string(b2)
}

combatAction_aiming_range_mask :: proc(action:^CombatAction, userSize:Vec2i, cachedAllowed:=true, allocator:=context.temp_allocator) -> []Vec2i{
	if cachedAllowed && userSize == action.aimingMasksDefaultUserSize do return action.aimingRangeMask
	if action.kind == .basic || (action.aimKind in CombatActionAimKinds{.user}) do return nil
	
	userRect := Recti{0, userSize}
	out := make([dynamic]Vec2i, 0, 256, allocator)
	switch action.aimKind{
		case .directional:
			positions := recti_surrounding_positions(userRect)
			for d in 0..<4{
				append_elems(&out, args=combatTargetMask_overlay(action.targetMask, positions[d], d))
			}
		case .directionalRanged:
			positions := recti_surrounding_positions(userRect)
			dirVecs := CARDINAL_VEC2IS
			for d in 0..<4{
				for n in 0..<action.aimRange{
					append_elems(&out, args=combatTargetMask_overlay(action.targetMask, positions[d]+dirVecs[d]*n, d))
				}
			}
		case .freeAim:
			fill := flood_fill(0, action.aimRange, userSize)
			target := combatTargetMask_overlay(action.targetMask, 0)
			for p in fill{
				for p2 in target{
					append(&out, p+p2)
				}
			}
		case .freeAimCornered:
			fill := flood_fill(0, action.aimRange, {1,1})
			for p in fill{
				for y in 0..<userSize.y{
					for x in 0..<userSize.x{
						append(&out, p+{x,y})
					}
				}
			}
		case .noAim: append_elems(&out, args=combatTargetMask_overlay(action.targetMask, 0))
		case .user: unreachable()
	}

	//remove duplicates
	if len(out) > 0{
		sort(&out, proc(a, b: Vec2i) -> bool {
			if a.x != b.x do return a.x < b.x
			return a.y < b.y
		})
		j := 1
		for i in 1..<len(out) {
			if out[i] != out[i-1] {
				out[j] = out[i]
				j += 1
			}
		}
		resize(&out, j)
	}

	shrink(&out)
	return out[:]
}
combatAction_aiming_bounds_mask :: proc(action:^CombatAction, userSize:Vec2i, cachedAllowed:=true, allocator:=context.temp_allocator) -> []Vec2i{
	if cachedAllowed && userSize == action.aimingMasksDefaultUserSize do return action.aimingBoundsMask
	if action.kind == .basic || (action.aimKind in CombatActionAimKinds{.noAim, .user, .directional}) do return nil

	userRect := Recti{0, userSize}
	out:[dynamic]Vec2i
	switch action.aimKind{
		case .directionalRanged:
			if(action.kind in CombatActionKinds{.evasion, .travel}) do return combatAction_aiming_range_mask(action, userSize, cachedAllowed, allocator)
			init(&out, 0, 256, allocator)
			positions := recti_surrounding_positions(userRect)
			dirVecs := CARDINAL_VEC2IS
			
			for d in 0..<4{
				row := make([]Vec2i, d%2==0?userSize.y:userSize.x, context.temp_allocator)
				for &p,i in row{ p = dirVecs[(d+3)%4]*i }
				for n in 0..<action.aimRange{
					for p in row{
						append(&out, positions[d]+dirVecs[d]*n+p)
					}
				}
			}
		case .freeAim, .freeAimCornered: return combatAction_aiming_range_mask(action, userSize, cachedAllowed, allocator)
		case .noAim, .user, .directional: unreachable()
	}

	//remove duplicates
	if len(out) > 0{
		sort(&out, proc(a, b: Vec2i) -> bool {
			if a.x != b.x do return a.x < b.x
			return a.y < b.y
		})
		j := 1
		for i in 1..<len(out) {
			if out[i] != out[i-1] {
				out[j] = out[i]
				j += 1
			}
		}
		resize(&out, j)
	}

	shrink(&out)
	return out[:]
}

combatAction_aiming_ring_draw :: proc(user:^CombatUnit, mask:[]Vec2i, col:=COLOR_BLACK){
	if mask == nil do return
	tex_target_set(combat.aiming_ring_mask_tex, stage.camera_pos)
		unitPos := combatUnit_ghost_position(user, combatUnit_preview_step(user))
		for p in mask{
			draw_rect(Rect{combat_to_stage_pos(unitPos+p, true), COMBAT_TILE_SIZE}, col, 1)
		}
	tex_target_set(combat.grid_buffer_tex_a)
		tex_draw(combat.grid_tex, 0,0)
	tex_target_set(combat.grid_tex, {0,0}, false)
		shader_set(Sh_AimingRings{
			texSize = Vec2(combat.grid_tex.size),
			outlineRevealAngle = ui_cue_map("actionSelectHover", 0, 12, 0, 90, cu.easeIn),
			centerPos = combatUnit_draw_pos(user, unitPos),
		})
		shader_texture_bind("destination", combat.grid_buffer_tex_a)
		tex_draw_ex(combat.aiming_ring_mask_tex, 0, 0, alpha=ui_cue_map("actionSelectHover", 0, 15, 0, 0.1, cu.easeIn))
		shader_reset()
	tex_target_reset(3)
}

//QUEUED ACTIONS
combatActionQueued_state_get :: proc(caq:^CombatActionQueued, statePtr:^^$T){
	if(caq.resolveState == nil){
		newState := new(T, combat.action_resolve_allocator)
		caq.resolveState = newState
	}
	statePtr^ = cast(^T)caq.resolveState
}

combatActionQueued_started :: proc(caq:^CombatActionQueued) -> bool{
	return caq.startupCounter < caq.action.startup
}


combatActionQueued_trigger_step :: proc(self:^CombatActionQueued) -> int{
	if self == &combat.resolve_action do return combat.current_step 
	out := combat.current_step + self.user.stunCounter
	for &caq in self.user.queuedActions{
		out += caq.startupCounter
		if &caq == self do return out
		out += 1 + caq.cooldown
	}
	when DEBUG do panic("Invalid pointer passed to combatActionQueued_trigger_step")
	else do return combat.current_step
}
combatActionQueued_start_step :: proc(self:^CombatActionQueued) -> int{
	if self == &combat.resolve_action do return combat.current_step 
	out := combat.current_step + self.user.stunCounter
	for &caq in self.user.queuedActions{
		if &caq == self do return out
		out += caq.startupCounter
		out += 1 + caq.cooldown
	}
	when DEBUG do panic("Invalid pointer passed to combatActionQueued_start_step")
	else do return combat.current_step
}

combatActionQueued_target_preview_step :: proc(self:^CombatActionQueued)->int{
	step := combat.preview_time.targetStep
	if combat.preview_time.initiative != -1 && combatActionQueued_trigger_step(self)+1 == combat.preview_time.targetStep && combatUnit_initiative(self.user) < combat.preview_time.initiative do step += 1 
	return step
}

combatActionQueued_target_preview_displayed :: proc(self:^CombatActionQueued) -> bool{
	return combatActionQueued_target_preview_step(self) <= combatActionQueued_trigger_step(self)+1 && combatUnit_preview_step(self.user) > combatActionQueued_start_step(self)
}

combatActionQueued_refresh_target :: proc(self:^CombatActionQueued, userPosOnUsage:Vec2i){
	target, aimDir, validAimPos := combatAction_get_target(self.action, combatAction_get_targetable_area(self.action, self.user, userPosOnUsage), userPosOnUsage + self.aimOffset, userPosOnUsage, combat.action_resolve_allocator)
	self.target = target
	self.aimDir = aimDir
	self.lastValidAimPos = validAimPos
	self.userPosOnUsage = userPosOnUsage
	self.targetBounds = combatTarget_bounds(target)
}

//frees all queued combat action targets then refreshes them
combat_refresh_all_targets :: proc(){
	free_all(combat.action_resolve_allocator)
	units := combatUnits_get()
	for unit in units{
		curPos := unit.combatEntity.pos
		for &caq in unit.queuedActions{
			caq.resolveState = nil  //not strictly necessary, mainly for stability
			if !equals(caq.action, ca.movement, ca.wait) do combatActionQueued_refresh_target(&caq, curPos)
			if(caq.action.updateGhostPosition != nil) do caq.action.updateGhostPosition(&caq, &curPos)
		}
	}
}
