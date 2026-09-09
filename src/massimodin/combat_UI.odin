#+feature using-stmt
package massimodin //@nested-tags:combat/

import slices "core:slice"
import "core:reflect"
import "../sdl3"

COMBAT_RESOLVE_ELLIPSE := Ellipse{Vec2{DISPLAY_WIDTH-1, 0}, DISPLAY_SIZE/4}

CombatTimelinePip :: struct{
	action:^CombatAction,
	unit:^CombatUnit,
	prevState:CombatTimelinePipDrawState,
	targetState:CombatTimelinePipDrawState,
	cooldown:int,
	spawnTimer:int,
	despawnTimer:int,
	tickDownTimer:int,
	shiftTimer:int,
	commitTimer:int,
	skipShift:bool
}

CombatTimelinePipDrawState :: struct{
	startup:int,
	timelinePos:int,
	committed:bool
}

CombatActionTargetDrawInfo :: struct{
	caq:^CombatActionQueued,
	drawTex:Tex,
	drawPos:Vec2,
	color:Color,
	alpha:f32,
	outlineAlpha:f32
}

COMBAT_TIMELINE_PIP_SPAWN_TIME :: 8
COMBAT_TIMELINE_PIP_DESPAWN_TIME :: 8
COMBAT_TIMELINE_PIP_TICKDOWN_TIME :: 12
COMBAT_TIMELINE_PIP_SHIFT_TIME :: 8
COMBAT_TIMELINE_TICK_TIME :: 6
COMBAT_TIMELINE_PIPS_X :: 33
COMBAT_TIMELINE_PIPS_X_OFF :: 9
COMBAT_TIMELINE_PIPS_DISPLAY_X :: COMBAT_TIMELINE_X + COMBAT_TIMELINE_PIPS_X+5-1
COMBAT_TIMELINE_X :: 2
COMBAT_TIMELINE_PADDING :: Vec2{7, 12}
COMBAT_TIMELINE_TOP_PADDING :: 5

//HELPER PROCS
//Draws a combat target to texture, and returns the position to draw it at in the stage
combat_target_draw :: proc(target:CombatTarget) -> (drawTex:Tex, stagePos:Vec2){
	switch t in target{
		case Vec2i:
			stagePos = combat_to_stage_pos(t, true)
			drawTex = tex_make(COMBAT_TILE_SIZE)
			tex_target_set(drawTex, clear=false)
				draw_clear()
			tex_target_reset()

		case []Vec2i:
			bounds := vec2i_array_bounds(t)
			topLeft := bounds.pos
			bottomRight := rect_get_bottom_right(bounds)
			drawTex = tex_make(Vec2(bottomRight - topLeft + {1,1})*COMBAT_TILE_SIZE)
			tex_target_set(drawTex)
				for p in t{
					drawPos := Vec2(p - topLeft)*COMBAT_TILE_SIZE
					draw_rect(Rect{drawPos, COMBAT_TILE_SIZE}, COLOR_WHITE)
				}
			tex_target_reset()
			stagePos = combat_to_stage_pos(topLeft, true)

		case ^CombatUnit, []^CombatUnit:
			units:[]^CombatUnit
			if unit,ok := t.(^CombatUnit); ok{
				units = make([]^CombatUnit, 1, context.temp_allocator)
				units[0] = unit
			}
			else do units = t.([]^CombatUnit)
			for unit, i in units{
				stagePos = combat_to_stage_pos(unit.combatEntity.pos, true)
				texSize := Vec2(unit.combatEntity.size)*COMBAT_TILE_SIZE
				if i == 0 do drawTex = tex_make(texSize) //todo: make this work properly for mutliple units
				tex_target_set(drawTex, clear=false)
					draw_clear()
				tex_target_reset()
			}
	}
	return
}

//ACTION SELECT MENU
COMBAT_ACTION_SELECT_MENU_RADIUS :: 48
COMBAT_ACTION_SELECT_MENU_SPACING :: 30 //must evenly divide 360
COMBAT_ACTION_SELECT_MENU_POPUP_TIME :: 3
COMBAT_ACTION_SELECT_MENU_MAX_IND :: 360/COMBAT_ACTION_SELECT_MENU_SPACING - 1

combat_grid_ripple :: proc(pos:Vec2){
	append(&combat.grid_ripples, Ellipse{pos, 0})
}

//returns whether the menu took input
_combat_action_select_menu_update :: proc() -> (interacted:bool){

	se := cofind(combat.selected_unit.entity, StageEntity)
	centerPos := combatUnit_center_draw_pos(combat.selected_unit, combatUnit_ghost_position(combat.selected_unit))

	hoverPos:Vec2
	switch input_device(){
		case .keyboard: hoverPos = mouse_display_pos()
		case .gamepad:
			angle, ok := input_gamepad_directional_angle()
			if ok{
				lastAngle,_ := input_gamepad_directional_angle(lastFrame=true)
	
				angle = round(angle/COMBAT_ACTION_SELECT_MENU_SPACING)*COMBAT_ACTION_SELECT_MENU_SPACING
				lastAngle = round(lastAngle/COMBAT_ACTION_SELECT_MENU_SPACING)*COMBAT_ACTION_SELECT_MENU_SPACING
				if angle == 360 do angle = 0
				if lastAngle == 360 do lastAngle = 0
	
				hoverPos = vec2_offset(angle, COMBAT_ACTION_SELECT_MENU_RADIUS, centerPos)
				if angle != lastAngle do ui_cue_reset("actionSelectHover")
			}
			else do hoverPos = centerPos
			combat.gamepad_cursor_pos = se.transform.pos - stage.combatBounds.pos
	}

	buttonRadius:f32= sp.testMoveIcon.size.x/2 + 4
	i:=0
	for a:=90; a>-270; a-=COMBAT_ACTION_SELECT_MENU_SPACING{
		buttonPos := vec2_offset(f32(a), COMBAT_ACTION_SELECT_MENU_RADIUS, centerPos)
		if(vec2_distance(buttonPos, hoverPos) <= buttonRadius){
			combat.action_select_hover_index = i
			break
		}
		i+=1
	}

	quit := false

	unqueueAction :: proc(){
		popped:=false
		poppingMovementTarget := Vec2i{-INT_MAX, -INT_MAX}
		for len(combat.selected_unit.queuedActions) > 0{
			caq := peek_ptr(&combat.selected_unit.queuedActions)
			if caq.action == ca.movement{
				movementTarget := peek(combat.selected_unit.queuedActions).target.(Vec2i)
				if poppingMovementTarget == {-INT_MAX, -INT_MAX} do poppingMovementTarget = movementTarget
				else if poppingMovementTarget != movementTarget do break
				pop(&combat.selected_unit.queuedActions)
				popped = true
			}
			else if poppingMovementTarget == {-INT_MAX, -INT_MAX} && !combatActionQueued_started(caq){
				pop(&combat.selected_unit.queuedActions)
				popped = true
				break
			}
			else do break
		}
		if popped do audio_play(au.actionUnqueue)
	}

	if(ginputs[.confirm]){
		interacted = true
		queueFull := combatUnit_action_queue_full(combat.selected_unit)
		switch combat.action_select_hover_index{
			case -1: interacted = false //do nothing
			case 0: //wait
				if queueFull{
					audio_play(au.uiFail)
					break
				}
				audio_play(au.actionQueueBasic)
				combatAction_enqueue(combat.selected_unit, ca.wait)
			case 1: //basic movement
				fillDist := combat.next_planning_step - combatUnit_queued_action_tail(combat.selected_unit)
				if fillDist <= 0{
					audio_play(au.uiFail)
					break
				}
				audio_play(au.uiBoxOpen)
				combat.selected_action = ca.movement
				combat.selected_action_targetable_area = flood_fill(
					combatUnit_ghost_position(combat.selected_unit),
					combat.selected_unit.walkSpeed*fillDist,
					{1,1},
					false,
					allocator=combat.action_targeting_allocator
				)
			case COMBAT_ACTION_SELECT_MENU_MAX_IND - 1: unqueueAction()
			case COMBAT_ACTION_SELECT_MENU_MAX_IND: quit = true
			case: //actions
				if queueFull{
					audio_play(au.uiFail)
					break
				}
				actionInd := combat.action_select_hover_index - 2
				if(actionInd < len(combat.selected_unit.equippedActions)){
					audio_play(au.uiBoxOpen)
					combat.selected_action = combat.selected_unit.equippedActions[actionInd]
					combat.selected_action_targetable_area = combatAction_get_targetable_area(
						combat.selected_action, 
						combat.selected_unit,
						combatUnit_ghost_position(combat.selected_unit),
						combat.action_targeting_allocator
					)
				}
				else{
					interacted = false //there's actually no button here
				}
		}
	}
	else{
		switch input_device(){
			case .keyboard: if ginputs[.cancel] do unqueueAction()
			case .gamepad: if ginputs[.lt] do unqueueAction()
		}
	} 

	if(quit){
		combat.selected_unit = nil
	}

	return
}

_combat_action_select_menu_draw :: proc(){
	drawRadius := ui_cue_map("combat_action_select_menu", 0, COMBAT_ACTION_SELECT_MENU_POPUP_TIME, 0, COMBAT_ACTION_SELECT_MENU_RADIUS)
	
	centerPos := combatUnit_center_draw_pos(combat.selected_unit, combatUnit_ghost_position(combat.selected_unit))

	// scale := drawRadius/COMBAT_ACTION_SELECT_MENU_RADIUS
	// sprite_draw_ex(sp.actionSelectRing, centerPos, 0, scale, scale)

	drawTex := tex_make(DISPLAY_SIZE)
	defer tex_destroy(drawTex)

	tex_target_set(drawTex)

	queueFull := combatUnit_action_queue_full(combat.selected_unit)

	i := 0
	for a:=90; a>-270; a-=COMBAT_ACTION_SELECT_MENU_SPACING{
		buttonPos := vec2_offset(f32(a), drawRadius, centerPos)

		col := COLOR_WHITE
		alpha :f32= 1
		if combat.timeline_hovered do alpha = 0.05
		else if (queueFull && !equals(i, COMBAT_ACTION_SELECT_MENU_MAX_IND - 1, COMBAT_ACTION_SELECT_MENU_MAX_IND)) {
			//col = COLOR_GRAY
			alpha = 0.5
		}

		hovering := combat.action_select_hover_index == i
		
		action :^CombatAction
		switch i{
			case 0: //wait
				blendmode_set(.none)
				sprite_draw_ex(sp.combatActionIcons_wait, buttonPos, color=col, alpha=alpha)
				blendmode_set(.blend)
				action = ca.wait
			case 1: //basic movement
				blendmode_set(.none)
				sprite_draw_ex(sp.combatActionIcons_movement, buttonPos, color=col, alpha=alpha)
				blendmode_set(.blend)
				action = ca.movement
			case COMBAT_ACTION_SELECT_MENU_MAX_IND - 1: //unqueue action
				if(len(combat.selected_unit.queuedActions) > 0 && !combatActionQueued_started(peek_ptr(&combat.selected_unit.queuedActions))){
					blendmode_set(.none)
					sprite_draw_ex(sp.miscCombatIcons_undo, buttonPos, int(hovering), color=col, alpha=alpha)
					blendmode_set(.blend)
					if input_device() == .gamepad{
						text_draw("LT", buttonPos + {3,2}, COLOR_WHITE, font=fo.yal5w3__16)
					}
				}
			case COMBAT_ACTION_SELECT_MENU_MAX_IND: //close
				blendmode_set(.none)
				sprite_draw_ex(sp.miscCombatIcons_close, buttonPos, int(hovering), color=col, alpha=alpha)
				blendmode_set(.blend)
				if input_device() == .gamepad{
					text_draw("B", buttonPos + {3,2}, COLOR_WHITE, font=fo.yal5w3__16)
				}
			case: //actions
				actionInd := i - 2
				if(actionInd < len(combat.selected_unit.equippedActions)){
					action = combat.selected_unit.equippedActions[actionInd]
					blendmode_set(.none)
					sprite_draw_ex(action.actionSelectIcon, buttonPos, color=col, alpha=alpha)
					blendmode_set(.blend)
				}
		}
		if action != nil && hovering {
			ui_cue("actionSelectHover")
			if ui_cue_time("actionSelectHover") == 0 do audio_play(au.actionSelectHover)
			off := Vec2{ui_cue_map("actionSelectHover", 0, 3, -6, 0), 0}
			sprite_draw_ex(sp.actionIconHighlight_ring, buttonPos)
			sprite_draw_ex(sp.actionIconHighlight_arrow, buttonPos, angle=ui_cue_map("actionSelectHover", 0, 2, 7.5, 0))

			combatAction_draw_info(action, buttonPos + {22, -18} + off)

		}
		i+=1
	}

	tex_target_reset()

	shader_set(Sh_ColorOnly)
	tex_draw_ex(drawTex, 1, 0, color=COLOR_BLACK)
	tex_draw_ex(drawTex, 1, 1, color=COLOR_BLACK)
	shader_reset()
	tex_draw(drawTex, 0, 0)

}

_combat_action_inspect_draw :: proc(){
	unit := combat.selected_unit
	drawData := len(unit.ghostDrawData) > 0 ? peek(combat.selected_unit.ghostDrawData) : CombatUnitGhostDrawData{
		unit.stageEntity.transform.pos, nil, unit.stageEntity.transform.scale.x == -1 ? .left:.right
	}

	actions:=unit.equippedActions[:]
	color := COLOR_WHITE
	if len(unit.queuedActions) > 0{
		targetStep := combat.preview_time.targetStep-1
		if combat.preview_time.initiative != -1 && combatUnit_initiative(unit) > combat.preview_time.initiative do targetStep -= 1 

		if unit.actionPreviewPinned{
			#reverse for &caq in unit.queuedActions{
				if caq.kind != .basic{
					actions = {caq.action}
					color = color_lerp(COLOR_WHITE, color_lerp(color_hex(0xc29566), color_hex(0xffe7b8), wave(0,1,50)), 0.5)
					break
				}
			}
		} 
		else if caq := combatUnit_queued_action_on_step(unit, targetStep); caq != nil && caq.kind!=.basic{
			targetStep = combatActionQueued_target_preview_step(caq)
			triggerStep := combatActionQueued_trigger_step(caq)+1
			if triggerStep >= targetStep{
				actions = {caq.action}
				color = color_lerp(COLOR_WHITE, color_hex(0xad3d30), triggerStep == targetStep?wave(0.33, 0.5, 25):wave(0.15, 0.33, 75))
			}
		}
	}

	camera_set(stage.camera_pos)

	drawTex := tex_make(DISPLAY_SIZE)
	defer tex_destroy(drawTex)

	tex_target_set(drawTex, stage.camera_pos)
		drawRect := sprite_draw_rect(combatUnitGhostDrawData_sprite(unit, drawData), drawData.pos, 0, Vec2{drawData.dir ==.left?-1:1,1})
		drawPos := Vec2{rect_get_right(drawRect) + ui_cue_map("combat_action_select_menu", 0, 3, -6, 0), drawRect.y}
		for action in actions{
			combatAction_draw_info(action, drawPos, false, fo.Notalot35__16)
			drawPos.y += text_char_height(fo.Notalot35__16)*2 + 5
		}
	tex_target_reset()
	camera_reset()

	shader_set(Sh_ColorOnly)
	tex_draw_ex(drawTex, Vec2{1,0}, color=COLOR_BLACK)
	tex_draw_ex(drawTex, 1, color=COLOR_BLACK)
	shader_reset()
	tex_draw_ex(drawTex, 0, color=color)
}


//ACTION TARGETING

//Returns -1 if not in a valid targeting state
combat_movement_targeting_distance :: proc() -> (fullDistance:int, walkStepDistance:int){
	fullDistance = -1
	walkStepDistance = -1
	if(combat.selected_action != ca.movement) do return
	if targetPos,ok := combat.selected_action_target.(Vec2i); ok{
		fullDistance = vec2_manhattan_distance(combatUnit_ghost_position(combat.selected_unit), targetPos)
		walkStepDistance = ceili(f32(fullDistance)/f32(combat.selected_unit.walkSpeed)) - 1 
	}
	return
}

_combat_action_targeting_update :: proc() -> (interacted:bool){

	queueAction :: proc(ghostPos,aimPos,validAimPos:Vec2i, aimDir:Dir, movement:bool, movementDistance:int){
		caq := CombatActionQueued{
			combat.selected_action,
			uuid_make(),
			combat.selected_action.startup,
			combat.selected_unit,
			combat.selected_action_target,
			combatTarget_bounds(combat.selected_action_target),
			ghostPos,
			aimPos - ghostPos,
			validAimPos,
			aimDir,
			false,
			nil
		}
		
		if movement{
			movementDistance:=movementDistance
			for movementDistance > 0 && !combatUnit_action_queue_full(combat.selected_unit){
				caq.uniqueID = uuid_make()
				append(&combat.selected_unit.queuedActions, caq)
				movementDistance -= combat.selected_unit.walkSpeed
			}
		}
		else{
			append(&combat.selected_unit.queuedActions, caq)
		}
	}

	lastTarget:CombatTarget
	switch t in combat.selected_action_target{
		case Vec2i, ^CombatUnit: lastTarget = combat.selected_action_target 
		case []Vec2i: lastTarget = clone(t, context.temp_allocator)
		case []^CombatUnit: lastTarget = clone(t, context.temp_allocator)
	}

	free_all(combat.action_targeting_temp_allocator)
	
	aimPos := combat_cursor_pos()
	movement := combat.selected_action == ca.movement
	aimDir := Dir.none
	validAimPos:Vec2i
	userTail := combatUnit_queued_action_tail(combat.selected_unit)
	ghostPos := combatUnit_ghost_position(combat.selected_unit)

	movementDistance:int
	if(movement){
		validPosDistance:f32=INF
		moveAimPos := Vec2(aimPos - {1,1})
		nearestValidPos:Vec2i
		for pos, i in combat.selected_action_targetable_area.([]Vec2i){
			if newDist := vec2_distance(Vec2(pos), moveAimPos); newDist < validPosDistance {
				nearestValidPos = pos
				if(newDist == 0) do break
				validPosDistance = newDist
			}
		}
		nearestValidPos = clamp(nearestValidPos, 0, combat.grid_size - combat.selected_unit.combatEntity.size )
		combat.selected_action_target = nearestValidPos
		movementDistance = vec2_manhattan_distance(ghostPos, nearestValidPos)
		combat.preview_time.targetStep = userTail + ceili(f32(movementDistance)/f32(combat.selected_unit.walkSpeed))
	}
	else{
		combat.selected_action_target, aimDir, validAimPos = combatAction_get_target(combat.selected_action, combat.selected_action_targetable_area, aimPos, ghostPos, combat.action_targeting_temp_allocator)
		combat.preview_time.targetStep = userTail + combat.selected_action.startup + 1
	}

	//check if target changed
	if reflect.union_variant_typeid(lastTarget) == reflect.union_variant_typeid(combat.selected_action_target){
		eq:bool
		switch t in combat.selected_action_target{
			case Vec2i: eq = t == lastTarget.(Vec2i)
			case ^CombatUnit: eq = t == lastTarget.(^CombatUnit)
			case []Vec2i: eq = slices.equal(t, lastTarget.([]Vec2i))
			case []^CombatUnit: eq = slices.equal(t, lastTarget.([]^CombatUnit))
		}
		if !eq{
			audio_play(au.uiHoverMove)
			if combat.reactive_unit_exists{
				//temporarily queue action and update enemy AI
				prevQueueLen := len(combat.selected_unit.queuedActions)
				queueAction(ghostPos, aimPos, validAimPos, aimDir, movement, movementDistance)
				combat_reactive_units_refresh()
				resize(&combat.selected_unit.queuedActions, prevQueueLen)
			}
		}
	}

	if(ginputs[.confirm] && !(movement && combat.selected_action_target.(Vec2i) == ghostPos)){
		interacted = true

		if t, ok := combat.selected_action_target.([]Vec2i); ok{
			newTarget := make([]Vec2i, len(t))
			copy(newTarget, t)
			combat.selected_action_target = newTarget
		}

		queueAction(ghostPos, aimPos, validAimPos, aimDir, movement, movementDistance)
		
		audio_play(movement ? au.actionQueueBasic : au.actionQueue)

		combat.selected_action = nil
		combat.selected_action_target = nil
		free_all(combat.action_targeting_allocator)
		//if(combatUnit_action_queue_full(combat.selected_unit)) do combat.selected_unit = nil
	}
	else if(ginputs[.cancel]){
		combat.selected_action = nil
		combat.selected_action_target = nil
		free_all(combat.action_targeting_allocator)
		interacted = true

		combat_reactive_units_refresh()
	}

	return
}

//Draws to the combat grid
_combat_action_targeting_draw :: proc(){
	unit := combat.selected_unit
	ui_cue("actionTargeting")
	if(combat.selected_action == ca.movement){ //special case
		ringTileCounts := make([]int, combat.next_planning_step - combatUnit_queued_action_tail(unit), context.temp_allocator)
		for &tc, i in ringTileCounts{
			tc = flood_fill_tile_count(unit.walkSpeed*(i+1), {1,1}, false)
		} 

		tex_target_set(combat.aiming_ring_mask_tex, stage.camera_pos)
			ringInd := len(ringTileCounts)-1
			#reverse for p, i in combat.selected_action_targetable_area.([]Vec2i){
				//wprint(i, ringInd, p, ringTileCounts[ringInd])
				drawRect := combatUnit_stage_rect(unit, p)
				//rect_resize_in_place(&drawRect, -1, -1)
				draw_rect(drawRect, combat.movement_ring_colors[ringInd], 1)

				if(i == 0 || (ringInd != 0 && i == ringTileCounts[ringInd-1])){
					ringInd -= 1
					//tex_target_set(combat.combat_grid_buffer_tex)
						// tex_draw(combat.aiming_ring_mask_tex, 1, 0)
						// tex_draw(combat.aiming_ring_mask_tex, 0, -1)
						// tex_draw(combat.aiming_ring_mask_tex, -1, 0)
						// tex_draw(combat.aiming_ring_mask_tex, 0, 1)
						// tex_blendmode_set(combat.aiming_ring_mask_tex, .subtract)
						// tex_draw(combat.aiming_ring_mask_tex, 0, 0)
						// tex_target_set(combat.grid_tex, {0,0}, false)
						// 	tex_draw_ex(combat.combat_grid_buffer_tex, 0, 0, color=ringColors[ringInd])
						//tex_blendmode_set(combat.aiming_ring_mask_tex, .blend)
					//tex_target_reset(2)
				}
			} 
		tex_target_set(combat.grid_buffer_tex_a)
			tex_draw(combat.grid_tex, 0,0)
		tex_target_set(combat.grid_tex, {0,0}, false)
			shader_set(Sh_AimingRings{
				texSize = Vec2(combat.grid_tex.size),
				outlineRevealAngle = ui_cue_map("actionTargeting", 0, 12, 0, 90, cu.easeIn),
				centerPos = combatUnit_draw_pos(unit, combatUnit_ghost_position(unit)),
			})
			shader_texture_bind("destination", combat.grid_buffer_tex_a)
			tex_draw_ex(combat.aiming_ring_mask_tex, 0, 0, alpha=ui_cue_map("actionTargeting", 0, 15, 0, 0.1, cu.easeIn))
			shader_reset()
		tex_target_reset(3)
		
		//target and move path
		distance, ringDist := combat_movement_targeting_distance()
		if(distance > 0 && ringDist < len(ringTileCounts)){
			targetPos := combat.selected_action_target.(Vec2i)
			drawRect := combatUnit_stage_rect(unit, targetPos)
			drawCol := combat.movement_ring_colors[ringDist]
			if unit.drawAttackWarningLevel > 0{
				drawCol = color_lerp(drawCol, color_hex(unit.drawAttackWarningLevel == 1 ? 0xffc20a:0xcc2d20), wave(0,0.4,50))
			}
			blendmode_set(.one)
			draw_rect(drawRect, drawCol, 0.5)
			blendmode_set(.blend)

			drawPath := make([]Vec2, ringDist+2)
			pathPos := combatUnit_ghost_position(unit)
			attackWarningStartInd := -1
			for &pos,i in drawPath{
				if unit.drawAttackWarningLevel > 0 && combatUnit_stun_tail(unit) + i == unit.drawAttackWarningMovementAimMarkers[0].step{
					attackWarningStartInd = i+1
				}
				pos = combatEntity_stage_pos(unit.combatEntity, pathPos)
				pathPos = combat_movement_step_simulate(pathPos, targetPos, unit.walkSpeed)
			}
			combat_movement_path_draw(drawPath, attackWarningStartInd)
		}
	}
	else{
		aimCols := combat.aiming_colors[combat.selected_action.kind]
		combatAction_aiming_ring_draw(unit, combatAction_aiming_bounds_mask(combat.selected_action, unit.combatEntity.size), aimCols[1])

		drawTex, drawPos := combat_target_draw(combat.selected_action_target)
		defer tex_destroy(drawTex)
		tex_draw_ex(drawTex, drawPos, color=aimCols[0], alpha=0.5)
	}
}

//TIMELINE

combatAction_timeline_sprites :: proc(action:^CombatAction) -> (main:^Sprite, bar:^Sprite, start:^Sprite, inProgress:^Sprite, end:^Sprite){
	end = sp.timelinePips_cooldown1_end
	if action == nil do return nil,sp.timelinePips_stun1_bar,nil,sp.timelinePips_stun1_inProgress,sp.timelinePips_stun1_end
	if action == ca.movement do return sp.timelinePips_moveStep_action,nil,nil,nil,nil
	if action.kind == .basic do return sp.timelinePips_wait,nil,nil,nil,nil

	prefix:string
	switch action.kind{
		case .attack: prefix = "atk"
		case .defense: prefix = "def"
		case .evasion, .travel: prefix = "mvmt" //todo: separate sprites for these kinds
		case .support: prefix = "misc" //todo: proper icons for these
		case .basic: unreachable()
	}

	main = sprite_find(format("timelinePips_%s_action", prefix))
	bar = sprite_find(format("timelinePips_%s_bar", prefix))
	start = sprite_find(format("timelinePips_%s_end", prefix))
	inProgress = sprite_find(format("timelinePips_%s_inProgress", prefix))

	return
}

//removes all of a units pips and adds new stun pips
combat_timeline_break :: proc(unit:^CombatUnit, spawnParticles:=true){
	pipsXOff :: COMBAT_TIMELINE_PIPS_X_OFF
	unitInd, ok := find_in_array(combat.resolve_queue, unit)
	if !ok do return
	drawX :f32= COMBAT_TIMELINE_PIPS_DISPLAY_X
	drawY := combat_timeline_unit_draw_ys()[unitInd]
	pips := &combat.timeline_pips[unit]
	removeKeys := make([]uuid, len(pips^), context.temp_allocator)
	for i:=0; key,&pip in pips{
		mainX := drawX+f32(pip.targetState.timelinePos)*pipsXOff
		startX := mainX - f32(pip.targetState.startup)*pipsXOff
		removeKeys[i] = key
		if spawnParticles{
			main,bar,start,inProgress,end := combatAction_timeline_sprites(pip.action)
			for j in 0..<pip.targetState.startup{
				dx := startX + f32(j)*pipsXOff
				if j == 0 do particles_emit(particle_type_clone(combat.timeline_break_particle, (pip.targetState.timelinePos - pip.targetState.startup == 0) ? inProgress : start), 1, layer_depth(.uiTop), Rect{{dx,drawY}, 0})
				else do particles_emit(particle_type_clone(combat.timeline_break_particle, bar), 1, layer_depth(.uiTop), Rect{{dx,drawY}, 0})
			}
			if main != nil do particles_emit(particle_type_clone(combat.timeline_break_particle, main), 1, layer_depth(.uiTop), Rect{{mainX, drawY}, 0})
			for j in 0..<pip.cooldown{
				dx := mainX + f32(j+1)*pipsXOff
				if j == pip.cooldown-1 do particles_emit(particle_type_clone(combat.timeline_break_particle, sp.timelinePips_cooldown1_end), 1, layer_depth(.uiTop), Rect{{dx,drawY}, 0})
				else do particles_emit(particle_type_clone(combat.timeline_break_particle, sp.timelinePips_cooldown1_bar), 1, layer_depth(.uiTop), Rect{{dx,drawY}, 0})
			}
		}
		i+=1
	}

	for key in removeKeys{
		delete_key(pips, key)
	}
	
	if unit.stunCounter > 0{
		pips[0] = CombatTimelinePip{
			unit = unit,
			targetState={
				startup=unit.stunCounter-1,
				timelinePos=unit.stunCounter-1+(combat.resolve_action.user == unit?1:0),
				committed=true
			},
			shiftTimer=999,
			despawnTimer=-1,
			tickDownTimer=-1,
			commitTimer=999,
			skipShift=combat.resolve_head<unitInd
		}
	}
}

combat_timeline_unit_draw_ys :: proc(display:=true) -> []f32{
	units := combat.resolve_queue[:]
	out := make([]f32, len(units), context.temp_allocator)

	pipY := sp.timelinePips_wait.size.y
	boxSize,_ := combat_timeline_box_size()
	drawY :f32= COMBAT_TIMELINE_TOP_PADDING + (display?(DISPLAY_HEIGHT/2 - boxSize.y/2):0)
	playersDone := false
	#reverse for unit,i in units{
		out[i] = drawY

		if !playersDone && i > 0 && units[i-1].unitType == .enemy{
			drawY += COMBAT_TIMELINE_PADDING.y*2+1
			playersDone = true
		}
		
		drawY += pipY
	}

	return out
}

combat_timeline_box_size :: proc() -> (size:Vec2, extraSteps:int){
	height := sp.timelinePips_atk_action.size.y*f32(len(combat.resolve_queue)) + COMBAT_TIMELINE_PADDING.y*3+COMBAT_TIMELINE_TOP_PADDING+3

	@(static) lastWidth:f32
	extraStepSize := 0
	units := coall(CombatUnit)
	for &unit in units{
		extraStepSize = max(extraStepSize, combatUnit_queued_action_tail(&unit) - combat.next_planning_step)
	}
	if combat.selected_action != nil{
		extraStepSize = max(extraStepSize, combat.preview_time.targetStep + combat.selected_action.cooldown - combat.next_planning_step)
	}
	newWidth :f32= 103 + f32(extraStepSize)*COMBAT_TIMELINE_PIPS_X_OFF
	if newWidth != lastWidth{
		ui_cue("timelineWidthChange")
		if ui_cue_time("timelineWidthChange") >= 5{
			lastWidth = newWidth
		}
		else do return Vec2{round(ui_cue_map("timelineWidthChange", 0, 5, lastWidth, newWidth)), height}, extraStepSize
	}
	return Vec2{newWidth, height}, extraStepSize
}

combat_timeline_refresh_unit_pips :: proc(unit:^CombatUnit){
	pips := &combat.timeline_pips[unit]
	for key,&pip in pips{
		if key != 0 do pip.despawnTimer=max(pip.despawnTimer, 0)
	}

	previewedAction:^CombatAction
	if(combat.selected_unit == unit && unit.unitType == .player){
		previewedAction = combat_previewed_action()
	}

	if previewedAction != nil{
		ghost := CombatTimelinePip{
			action=previewedAction,
			unit=unit,
			cooldown=previewedAction.cooldown,
			targetState={
				startup=previewedAction.startup,
				timelinePos=combatUnit_queued_action_tail(unit)+previewedAction.startup-combat.current_step
			},
			despawnTimer=-1,
			spawnTimer=999,
			tickDownTimer=-1,
			shiftTimer=999,
			commitTimer=999
		}
		if previewedAction == ca.movement{
			_, movementTargetingDist := combat_movement_targeting_distance()
			movementTargetingDist += 1
			for j in 1..=u8(movementTargetingDist){
				moveKey:uuid
				for &n in moveKey{n=j}
				pips[moveKey] = ghost
				ghost.targetState.timelinePos += 1
			}
		}
		else do pips[1] = ghost
	}
	
	for &caq in unit.queuedActions{
		if caq.uniqueID not_in pips{
			pips[caq.uniqueID] = CombatTimelinePip{
				action=caq.action,
				unit=unit,
				targetState={
					timelinePos=combatActionQueued_trigger_step(&caq)-combat.current_step,
				},
				cooldown=caq.cooldown,
				shiftTimer=999,
				tickDownTimer=-1,
				commitTimer=999,
			}
		}
		pip := &pips[caq.uniqueID]
		pip.despawnTimer = -1
		pip.targetState.startup = caq.startupCounter
	}

	// for i in 0..<unit.stunCounter{
	// 	key := format("%v_stun_%i", rawptr(unit), unit.stunCounter)
	// 	if key not_in combat.timeline_pips{
	// 		key = clone(key)
	// 		combat.timeline_pips[key] = CombatTimelinePip{
	// 			unit=unit,
	// 			targetState={
	// 				timelinePos=i
	// 			}
	// 		}
	// 	}

	// 	pip := &combat.timeline_pips[key]
	// 	if combat.phase != .resolving do pip.despawnTimer = -1
	// }
}

//only returns player actions, use combat_previewed_actions to include selected ally/enemy attacks
combat_previewed_action :: proc() -> ^CombatAction{
	
	if(combat.selected_action != nil) do return combat.selected_action

	unit := combat.selected_unit

	if unit == nil || unit.unitType != .player do return nil

	if(combat.action_select_hover_index == 1) do return ca.movement
	if (in_range(combat.action_select_hover_index, 2, len(unit.equippedActions)+1)) do return unit.equippedActions[combat.action_select_hover_index-2]

	return nil
}

//can return all attacks on a selected ally/enemy
combat_previewed_actions :: proc(allocator:=context.temp_allocator) -> []^CombatAction{
	out := make([dynamic]^CombatAction, 0, 1, allocator)

	if pa := combat_previewed_action(); pa != nil do append(&out, pa)
	else{
		unit := combat.selected_unit
		if unit != nil && unit.unitType != .player{
			for action in unit.equippedActions{
				if action.kind == .attack do append(&out, action)
			} 
		}
	}

	shrink(&out)
	return out[:]
}


_combat_timeline_update :: proc(){

	
	units := combat.resolve_queue[:]
	drawYs := combat_timeline_unit_draw_ys()
	
	resolving := combat.timeline_resolve_time.step < combat.current_step || combat.phase == .resolving
	
	for unit in units{
		if unit not_in combat.timeline_pips{
			combat.timeline_pips[unit] = make(map[uuid]CombatTimelinePip)
		}
	}

	if resolving && (combat.waiting_for_cutscene || len(combat.units_bumped) > 0) do return //stopgap
	if !resolving{
		#reverse for unit,i in units{
			combat_timeline_refresh_unit_pips(unit)
		}
	}
	else{
		if combat.timeline_resolve_time.head == -1{
			combat.timeline_resolve_time.head = len(units) - 1
			combat.timeline_resolve_time.step += 1

			shiftPip :: proc(pip:^CombatTimelinePip){
				if pip.skipShift{
					pip.skipShift = false
					return
				}
				pip.prevState = pip.targetState
				if pip.targetState.timelinePos - pip.targetState.startup == 0 do pip.targetState.startup -= 1
				pip.targetState.timelinePos -= 1
				pip.targetState.committed = true
				if !pip.prevState.committed do pip.commitTimer = 0
				pip.shiftTimer = 0
			}
			//shift timeline over by 1
			ui_cue("timelineShift")
			for unit in units{
				toStunKey:uuid
				pips := &combat.timeline_pips[unit]
				for key,&pip in pips{
					if pip.despawnTimer >= 0 do continue
					if pip.targetState.timelinePos == 0{
						if (key == 0) do shiftPip(&pip)
						else do toStunKey = key
					}
					else do shiftPip(&pip)
				}

				if (toStunKey != 0){
					pip := &pips[toStunKey]
					cooldown := pip.cooldown
					if cooldown > 0{
						pips[0] = {
							unit=unit,
							prevState={
								timelinePos=cooldown,
								startup=cooldown,
								committed=true
							},
							targetState={
								timelinePos=cooldown-1,
								startup=cooldown-1,
								committed=true
							},
							spawnTimer=999,
							despawnTimer=-1,
							tickDownTimer=-1,
							commitTimer=999,
						}
						delete_key(pips, toStunKey)
					}
					else do shiftPip(pip)

				}
			}
		}
		else if(
			(combat.timeline_resolve_time.step<combat.current_step || combat.timeline_resolve_time.head > combat.resolve_head)
		){
			if combat.timeline_resolve_time.head < len(combat.resolve_queue){
				pips := &combat.timeline_pips[combat.resolve_queue[combat.timeline_resolve_time.head]]
				for _,&pip in pips{
					if pip.targetState.timelinePos - pip.targetState.startup == 0{
						if ind,ok:=find_in_slice(units, pip.unit); ok && ind == combat.timeline_resolve_time.head{
							pip.tickDownTimer = 0
						}
					}
				}
			}

			// particles_emit(particle_type(sp.shineRing, sprite_duration(sp.shineRing), angleSpread=0), 1, layer_depth(.uiTop), Rect{{
			// 	COMBAT_TIMELINE_X + COMBAT_TIMELINE_PIPS_X+5-1, 
			// 	drawYs[combat.timeline_resolve_time.head] + (DISPLAY_HEIGHT/2 - combat_timeline_box_size().y/2)+f32(sp.timelinePips_wait.origin.y)-1
			// }, 0})

			combat.timeline_resolve_time.head -= 1
		}
	}

	for unit in units{
		pips := &combat.timeline_pips[unit]
		removeKeys := make([dynamic]uuid, context.temp_allocator)
		for key,&pip in pips{
			for j in 1..=u8(COMBAT_RESOLVE_INTERVAL){
				check:uuid
				for &n in check{n=j}
				if key == check{
					if pip.despawnTimer != -1 do append(&removeKeys, key)
					continue
				}
			}

			pip.spawnTimer += 1
			if pip.shiftTimer == 0{
				if pip.targetState.timelinePos == -1 do append(&removeKeys, key)
				else do pip.tickDownTimer = -1
			}
			pip.shiftTimer += 1
			pip.commitTimer += 1
			if pip.despawnTimer >= 0{
				pip.despawnTimer += 1
				if pip.despawnTimer >= COMBAT_TIMELINE_PIP_DESPAWN_TIME do append(&removeKeys, key)
			}
			if pip.tickDownTimer >= 0{
				pip.tickDownTimer += 1
			}
		}

		for key in removeKeys{
			delete_key(pips, key)
		}
	}
}

_combat_timeline_draw :: proc(){
	ui_cue("timelineDraw")
	units := combat.resolve_queue[:]

	padding :: COMBAT_TIMELINE_PADDING
	pipsX :f32=COMBAT_TIMELINE_PIPS_X
	pipsXOff :: COMBAT_TIMELINE_PIPS_X_OFF
	portraitsX :: 7
	pipSize := sp.timelinePips_atk_action.size

	boxSizeFull, extraSteps := combat_timeline_box_size()
	boxPopupSize := round(boxSizeFull*box_popup_scale(ui_cue_time("timelineDraw"), true))

	boxPos := Vec2{2, DISPLAY_HEIGHT/2-boxPopupSize.y/2}
	nineslice_draw(sp.timelineBox, Rect{boxPos, boxPopupSize})

	//frame
	totalStepsToDraw := extraSteps+COMBAT_RESOLVE_INTERVAL+1
	frameSegTex := tex_make(boxSizeFull.x,sp.timelineBaseFrame_solo.size.y)
	defer tex_destroy(frameSegTex)
	frameOrigin := sp.timelineBaseFrame_solo.origin
	turnLineDrawInfo := make([dynamic][2]f32, context.temp_allocator)
	stepLineDrawInfo := make([dynamic][2]f32, context.temp_allocator)
	tex_target_set(frameSegTex, -frameOrigin)
		blendmode_set(.one)
		prog := ui_cue_map("timelineShift", 0, COMBAT_TIMELINE_PIP_SHIFT_TIME, 0, 1)
		for n in -1..<totalStepsToDraw{
			curStep := n+combat.timeline_resolve_time.step
			drawX:= pipsX + (f32(n) + 1-prog)*pipsXOff
			alpha :f32= 1
			if n == totalStepsToDraw-1{
				alpha = prog
				sprite_draw_ex(sp.timelineBaseFrame_stepSegment_edge, drawX, 0, alpha=alpha)
			}
			else{
				if n == -1 do alpha = 1-prog
				sprite_draw_ex(sp.timelineBaseFrame_stepSegment, drawX, 0, alpha=alpha)
			}

			if curStep%COMBAT_RESOLVE_INTERVAL == 0{
				sprite_draw_ex(n <= 0?sp.timelineBaseFrame_turnLineMiddle_current:sp.timelineBaseFrame_turnLineMiddle, drawX, 0, alpha=alpha)
				append(&turnLineDrawInfo, [2]f32{drawX, alpha})
			}

			if n%2 == 1 do append(&stepLineDrawInfo, [2]f32{drawX+4, alpha})
		}
		blendmode_set(.blend)

	

	timelineTex := tex_make(DISPLAY_WIDTH, boxPopupSize.y)
	timelineBufferTex := tex_make(DISPLAY_WIDTH, boxPopupSize.y)
	defer tex_destroy(timelineTex)
	defer tex_destroy(timelineBufferTex)
	tex_target_set(timelineTex, boxSizeFull - boxPopupSize)
		display_window_tex_draw(boxSizeFull - boxPopupSize - boxPos) //for alpha blending
		uncommitCol :Color: 191 //gray, 191/255

		//step lines
		for di in stepLineDrawInfo{
			draw_rect(Rect{Vec2{di[0], 0}, Vec2{2, boxPopupSize.y}}, COLOR_WHITE, 0.02*di[1])
		}

		//portraits and frame
		drawY :f32= COMBAT_TIMELINE_TOP_PADDING
		playersDone := false
		drawFrameTop := true
		displayInd := 1
		#reverse for unit,i in units{
			tex_draw(frameSegTex, 0, drawY-frameOrigin.y)

			indPos := Vec2{portraitsX-1, drawY+unit.sprites.timelinePortrait.size.y/2-1}
			displayIndStr := int_to_string(displayInd)
			text_draw(displayIndStr, indPos+1, color_hex(0x4f3e3b), 1, fo.yal5w3__16, Alignment{1, 0})
			text_draw(displayIndStr, indPos, color_hex(PAUSE_MENU_TEXT_COL), 1, fo.yal5w3__16, Alignment{1, 0})
			displayInd += 1
			
			sprite_draw(unit.sprites.timelinePortrait, portraitsX, drawY)
			if drawFrameTop{
				for di in turnLineDrawInfo{
					sprite_draw_ex(sp.timelineBaseFrame_turnLineTop, di[0], drawY, alpha=di[1])
				}
				sprite_draw(sp.timelineBaseFrame_turnLineTop_current, pipsX, drawY)
				drawFrameTop = false
			}
			
			//mini turn line for reactive units, deprecated for now
			// if combat.phase == .planning && unit.reactionTime > 0{
			// 	sprite_draw_ex(sp.timelineBaseFrame_reactionLine, pipsX + f32(pipsXOff*unit.reactionTime), drawY, alpha=wave(0.667, 1, 120))
			// }

			if i == 0{
				for di in turnLineDrawInfo{
					sprite_draw_ex(sp.timelineBaseFrame_turnLineBottom, di[0], drawY, alpha=di[1])
				}
				sprite_draw(sp.timelineBaseFrame_turnLineBottom_current, pipsX, drawY)
			}
			else if !playersDone && units[i-1].unitType == .enemy{
				for di in turnLineDrawInfo{
					sprite_draw_ex(sp.timelineBaseFrame_turnLineBottom, di[0], drawY, alpha=di[1])
				}
				sprite_draw(sp.timelineBaseFrame_turnLineBottom_current, pipsX, drawY)

				drawY += pipSize.y + padding.y+1
				sprite_draw(sp.timelineDivider, portraitsX, drawY)
				drawY += padding.y
				drawFrameTop = true
				playersDone = true
			}
			else do drawY += pipSize.y
		}
		

		
		eyeDrawY := drawY + pipSize.y + 9

		pipsX += f32(sp.timelinePips_wait.origin.x)
		drawY = COMBAT_TIMELINE_TOP_PADDING+f32(sp.timelinePips_wait.origin.y)

		//preview eye
		if combat.preview_time.targetStep - combat.current_step > 0{
			ui_cue("timelinePreviewBar")
			eyePos:=Vec2{
				pipsX + (combat.preview_time.displayedStep-f32(combat.current_step)-1)*pipsXOff,
				eyeDrawY,
			}
			col := color_hex(0xc29566)
			alpha := ui_cue_map("timelinePreviewBar", 0, 6, 0, 1)
			if combat.timeline_hover_unit == nil{
				ui_cue("timelinePreviewEye")
				sprite_draw_ex(sp.timelineEye, eyePos, int(ui_cue_time("timelinePreviewEye")<=6), color=col, alpha=alpha)
			}
			draw_rect(eyePos.x-pipsXOff/2-1, 0, eyePos.x+pipsXOff/2, boxPopupSize.y-1, col, alpha*wave(0.16,0.2,100))
		}

		//timeline hover prompt
		if input_device() == .gamepad{
			hovering := combat.timeline_gamepad_hover_pos != -1
			textPos := Vec2{portraitsX-3, eyeDrawY-3}
			col := color_lerp(color_hex(PAUSE_MENU_TEXT_COL), COLOR_WHITE, wave(0, hovering?0.3:0.15, hovering?50:100))
			text_draw("LB", textPos+1, color_hex(0x4f3e3b), 1, fo.yal5w3__16)
			text_draw("LB", textPos, col, 1, fo.yal5w3__16)
			if !hovering do sprite_draw_ex(sp.timelineEye, Vec2{textPos.x + text_size("LB", fo.yal5w3__16).x + 5, eyeDrawY-1}, color=col)
		}

		//draw pips
		playersDone = false
		#reverse for unit,i in units{
			pips,ok := &combat.timeline_pips[unit]
			if !ok do continue
			
			for key,&pip in pips{
				main,bar,start,inProgress,end := combatAction_timeline_sprites(pip.action)
				//print(time.frame, unit.initID, pip.action.name, main == nil ? "":main.name, pip.targetState)
				//print(sp.timelinePips_moveStep_action.name)
				spawnProg := min(f32(pip.spawnTimer)/COMBAT_TIMELINE_PIP_SPAWN_TIME, 1)
				tickDownProg := min(f32(pip.tickDownTimer)/COMBAT_TIMELINE_PIP_TICKDOWN_TIME, 1)
				despawnProg := min(f32(pip.despawnTimer)/COMBAT_TIMELINE_PIP_DESPAWN_TIME, 1)
				commitProg := min(f32(pip.commitTimer)/COMBAT_TIMELINE_PIP_SHIFT_TIME, 1)
				shiftProg := min(f32(pip.shiftTimer)/COMBAT_TIMELINE_PIP_SHIFT_TIME, 1)

				col := color_lerp(
					pip.prevState.committed ? COLOR_WHITE : uncommitCol, 
					pip.targetState.committed ? COLOR_WHITE : uncommitCol, 
					commitProg
				)
				alpha :f32= 1

				//check if preview pip
				for j in 1..=u8(COMBAT_RESOLVE_INTERVAL){
					check:uuid
					for &n in check{n=j}
					if key == check{
						col = uncommitCol
						alpha = 0.667
					}
				}

				startTimelinePos := pip.targetState.timelinePos - pip.targetState.startup

				if combat.phase == .planning && 
					pip.unit.reactionTime >= 0 && 
					startTimelinePos >= pip.unit.reactionTime &&
					startTimelinePos >= combatUnit_stun_tail(pip.unit, true) - combat.current_step
				{
					col = uncommitCol
					alpha = 0.667
				}

				mainX := lerp(pipsX + f32(pip.prevState.timelinePos)*pipsXOff, pipsX + f32(pip.targetState.timelinePos)*pipsXOff, shiftProg)

				mainScale:Vec2=1.
				startScale:Vec2=1.
				middleScale:Vec2=1.
				endScale:Vec2=1.
				if spawnProg < 1{
					mainScale = lerp(0,1,spawnProg,cu.easeIn)
					if startTimelinePos==0 do startScale = lerp(0,1,spawnProg,cu.easeIn)
				}
				else if in_range(despawnProg, 0, 1){
					mainScale.y = lerp(1,0,despawnProg,cu.easeIn)
					startScale.y = mainScale.y
					middleScale.y = mainScale.y
					endScale.y = mainScale.y
				}
				else if in_range(tickDownProg, 0, 1){
					s := lerp(1,0,tickDownProg,cu.easeIn)
					if pip.targetState.timelinePos == 0 do mainScale=s
					else do startScale = s
				}
				else if shiftProg < 1{
					s := lerp(0,1,shiftProg,cu.easeIn)
					if startTimelinePos == 0 && (pip.targetState.timelinePos != 0 || key==0) do startScale=s
				}


				if pip.targetState.startup + pip.cooldown > 0{
					barSize := f32(pip.targetState.startup + pip.cooldown)*pipsXOff*lerp(0,1,spawnProg,cu.easeIn) + pipsXOff
					barX := pipsX + f32(pip.targetState.timelinePos-pip.targetState.startup)*pipsXOff

					//middle bar
					middleSize := barSize-pipsXOff*2
					middleX := barX + pipsXOff
					for middleSize > 0{
						spr := middleX <= mainX ? bar:sp.timelinePips_cooldown1_bar
						if middleSize < pipsXOff{
							drawSize := Vec2{middleSize, 6}
							sprite_draw_part_ex(spr, Rect{{middleX-f32(spr.origin.x), drawY-f32(spr.origin.y)+5}, drawSize}, Rect{{0,5},drawSize}, color=col, alpha=alpha)
						}
						else do sprite_draw_ex_f(spr, middleX, drawY, scale=middleScale, color=col, alpha=alpha)
						middleSize -= pipsXOff
						middleX += pipsXOff
					}

					//ends (arrows)
					if barX == pipsX{
						drawSize := Vec2{pipSize.x/2+1, 6*middleScale.y}
						scaledOff :f32= 6/2*(1-middleScale.y)
						sprite_draw_part_ex(bar, Rect{{barX-1, drawY-f32(bar.origin.y)+5+scaledOff}, drawSize}, Rect{{4,5+scaledOff},drawSize}, color=col, alpha=alpha)
						sprite_draw_ex_f(end, barX+barSize-pipsXOff, drawY, scale=endScale, color=col, alpha=alpha)
						sprite_draw_ex_f(inProgress, barX, drawY, scale=startScale, color=col, alpha=alpha)
					}
					else{
						sprite_draw_ex_f(start, barX, drawY, scale=startScale, color=col, alpha=alpha)
						sprite_draw_ex_f(end, barX+barSize-pipsXOff, drawY, scale=endScale, color=col, alpha=alpha)
					}
					
				}
				
				//main sprite
				if main != nil do sprite_draw_ex_f(main, mainX, drawY, scale=mainScale, color=col, alpha=alpha)
				else if pip.targetState.startup == 0 do sprite_draw_ex_f(inProgress, mainX, drawY, scale=mainScale, color=col, alpha=alpha)
			}

			//react highlight
			if combat.phase == .planning && unit.reactionTime >= 0{
				//highlight, also deprecated for now

				// loopDur := sprite_duration(sp.timelineReactWindowHighlight_fill)
				// prog := f32(time.frame%loopDur)/f32(loopDur)
				// moveProg := curve_eval(cu.easeInStrong, prog)

				fillL := pipsX + f32(pipsXOff*unit.reactionTime) + 1
				fillR := pipsX + pipsXOff*COMBAT_RESOLVE_INTERVAL - 1
				drawWBase := fillR-fillL
				
				//fillR -= sp.timelineReactWindowHighlight_cap.size.x
				//fillR = lerp(fillL, fillR, moveProg)

				//drawW := fillR-fillL
				// drawTex := tex_make(drawW + sp.timelineReactWindowHighlight_cap.size.x, sp.timelineReactWindowHighlight_fill.size.y)
				// defer tex_destroy(drawTex)

				texDrawPos := Vec2{fillL, drawY} - sprite_origin(sp.timelineReactWindowHighlight_fill)

				// tex_target_set(drawTex, texDrawPos)
				
				// sprite_draw_ex(
				// 	sp.timelineReactWindowHighlight_fill, fillL, drawY, 
				// 	sprite_frame_get(sp.timelineReactWindowHighlight_fill, prog*f32(loopDur)),
				// 	Vec2{drawW, 1}, blendmode=BlendMode.one
				// )
				// sprite_draw_ex(
				// 	sp.timelineReactWindowHighlight_cap, fillR, drawY, 
				// 	sprite_frame_get(sp.timelineReactWindowHighlight_cap, prog*f32(loopDur)),
				// 	blendmode=BlendMode.one
				// )
				// tex_target_set(timelineBufferTex)
				// tex_draw(timelineTex, 0, 0)
				// tex_target_reset(2)


				// shader_set(sh.screen)
				// shader_texture_bind("destination", timelineBufferTex)
				// defer shader_texture_unbind(timelineBufferTex)
				// shader_uniform_set(sh.screen, "destRect", Rect{texDrawPos - camera.pos, Vec2(drawTex.size)})
				// shader_uniform_set(sh.screen, "destSize", Vec2(timelineBufferTex.size))
				// tex_draw(drawTex, texDrawPos)
				// shader_reset()

				nineslice_draw(sp.timelineReactWindowOutline, Rect{texDrawPos-1 - Vec2{pipsXOff/2+2, 0}, Vec2{drawWBase+3, sp.timelineReactWindowHighlight_fill.size.y}+2}, sprite_frame_get(sp.timelineReactWindowOutline))
			}

			if !playersDone && i > 0 && units[i-1].unitType == .enemy{
				drawY += padding.y*2+1
				playersDone = true
			}
			drawY += pipSize.y
		}

		//timeline unit hover highlight (letterbox)
		highlightRect:Rect
		if combat.timeline_hover_unit != nil{
			unitDrawYs := combat_timeline_unit_draw_ys(false)
			for unit,i in units{
				if unit == combat.timeline_hover_unit{
					highlightRect = Rect{Vec2{0, unitDrawYs[i]}, Vec2{boxSizeFull.x, pipSize.y}}
					break
				}
			}
		}
		else{
			highlightRect = Rect{0, boxSizeFull}
		}

		travelTime :: 6
		drawHighlight := ui_cue_map_stateful("timelineUnitHover", travelTime, highlightRect, cu.easeIn)

		topRect := Rect{0, Vec2{boxSizeFull.x, drawHighlight.y}}
		bottomY := drawHighlight.y + drawHighlight.size.y
		bottomRect := Rect{Vec2{0, bottomY}, Vec2{boxSizeFull.x, boxSizeFull.y - bottomY}}
		if rect_is_positive(topRect) do draw_rect(topRect, COLOR_BLACK, 0.4)
		if rect_is_positive(bottomRect) do draw_rect(bottomRect, COLOR_BLACK, 0.4)

	tex_target_reset(2)


	tex_draw(timelineTex, boxPos)
}
_combat_timeline_draw_OLD :: proc(){
	lockedFrame :: proc(caq:^CombatActionQueued, t:f32, actionStartTime:f32) -> int{
		if(combatActionQueued_started(caq)) do return 1
		if(combat.phase == .planning) do return 0
		if(
			int(actionStartTime) < combat.next_planning_step || 
			combat.current_step + int(t) < combat.next_planning_step)
		{ 
			return 1
		}
		if(combat.current_step + int(t) < combat.next_planning_step) do return 1
		return 0
	}

	drawMovementBlock :: proc(beadStartPos:Vec2, beadSize:f32, tStart:f32, moveBlockSize:f32, frame:int, alpha:f32=1){
		blockDrawRect := Rect{
			{beadStartPos.x + beadSize*tStart, beadStartPos.y},
			{beadSize*moveBlockSize + 1, sp.timelineMoveBeadBack.size.y}
		}

		drawTex:Tex
		if(alpha != 1){
			drawTex = tex_make(blockDrawRect.size)
			tex_target_set(drawTex, blockDrawRect.pos)
		}

		nineslice_draw(sp.timelineMoveBeadBack, blockDrawRect, frame)
		sprite_draw(sp.timelineMoveBeadFront, blockDrawRect.pos.x + floor(blockDrawRect.size.x/2), beadStartPos.y)

		if(alpha != 1){
			tex_target_reset()
			tex_draw_ex(drawTex, blockDrawRect.pos, alpha=alpha)
			tex_destroy(drawTex)
		}
	}

    black :: Blend{0,0,0,255}
    blank :: Blend{0,0,0,0}
	gradientW :f32= 112
    vertices := [6]Vertex{
        // first triangle (top-left, bottom-left, top-right)
        {pos = {0, 0}, blend = black},
        {pos = {0, DISPLAY_SIZE.y}, blend = black},
        {pos = {gradientW, 0}, blend = blank},
        {pos = {0, DISPLAY_SIZE.y}, blend = black},
        {pos = {gradientW, DISPLAY_SIZE.y}, blend = blank},
        {pos = {gradientW, 0}, blend = blank},
    }

	draw_mesh_blank(vertices[:])

	beadSize := sp.timelineIdleBead.size.x
	previewAlpha :: 0.5
	portraitX:f32 = 13
	beadsStartX:f32 = 39
	drawY:f32 = 14
	_, movementTargetingDist := combat_movement_targeting_distance()
	movementTargetingDist += 1

	#reverse for unit in combat.resolve_queue{
		previewedAction:^CombatAction

		if(combat.selected_unit == unit && unit.unitType == .player){
			if(combat.selected_action != nil) do previewedAction = combat.selected_action
			else if(combat.action_select_hover_index == 1) do previewedAction = ca.movement
			else if(in_range(combat.action_select_hover_index, 2, len(unit.equippedActions)+1)){
				previewedAction = unit.equippedActions[combat.action_select_hover_index-2]
			}
		}
		
		timelineFullDuration := unit.stunCounter
		for &caq in unit.queuedActions{
			timelineFullDuration += caq.startupCounter + 1 + caq.cooldown
		}

		if(previewedAction != nil){
			if(previewedAction == ca.movement) do timelineFullDuration += movementTargetingDist
			else do timelineFullDuration += previewedAction.startup + 1 + previewedAction.cooldown
			
		}

		stickLength := beadsStartX+f32(timelineFullDuration)*beadSize+3
		sprite_draw_ex(sp.timelineStick, 0, drawY+3, scale=Vec2{stickLength, 1}) //stick
		sprite_draw(sp.timelineEndBead, stickLength, drawY+2) //stick end

		//idle beads
		t:f32 = 0
		for _ in 0..<unit.stunCounter{
			sprite_draw(sp.timelineIdleBead, beadsStartX + beadSize*t, drawY, 1)
			t += 1
		}
		for &caq in unit.queuedActions{
			actionStartTime := t
			for _ in 0..<caq.startupCounter{
				sprite_draw(sp.timelineIdleBead, beadsStartX + beadSize*t, drawY, lockedFrame(&caq, t, actionStartTime))
				t += 1
			}
			if caq.action == ca.wait do sprite_draw(sp.timelineIdleBead, beadsStartX + beadSize*t, drawY, lockedFrame(&caq, t, actionStartTime))
			t += 1
			for _ in 0..<caq.cooldown{
				sprite_draw(sp.timelineIdleBead, beadsStartX + beadSize*t, drawY, lockedFrame(&caq, t, actionStartTime))
				t+=1
			}
		}


		if(previewedAction != nil){
			for _ in 0..<previewedAction.startup{
				sprite_draw_ex(sp.timelineIdleBead, beadsStartX + beadSize*t, drawY, 0, alpha=previewAlpha)
				t+=1
			}
			if previewedAction == ca.wait do sprite_draw_ex(sp.timelineIdleBead, beadsStartX + beadSize*t, drawY, 0, alpha=previewAlpha)
			t += (previewedAction == ca.movement) ? f32(movementTargetingDist) : 1
			for _ in 0..<previewedAction.cooldown{
				sprite_draw_ex(sp.timelineIdleBead, beadsStartX + beadSize*t, drawY, 0, alpha=previewAlpha)
				t+=1
			}

		//action beads
			
			switch previewedAction{
				case ca.movement:
					if(movementTargetingDist > 0){
						blockSize := f32(movementTargetingDist)
						t -= blockSize
						drawMovementBlock({beadsStartX, drawY}, beadSize, t, blockSize, 0, previewAlpha)
					}
				case ca.wait: 
					t -= 1
				case:
					t -= f32(previewedAction.cooldown) + 1
					sprite_draw_ex(sp.timelineAttackBead, beadsStartX + beadSize*t, drawY, 0, alpha=previewAlpha)
					t -= f32(previewedAction.startup)
			}
		}

		moveBlockSize:f32 = 0
		#reverse for &caq, i in unit.queuedActions{
			switch caq.action{
				case ca.movement:
					moveBlockSize += 1
					if(i == 0 || unit.queuedActions[i-1].action != ca.movement){ //end of block
						t -= moveBlockSize
						drawMovementBlock({beadsStartX, drawY}, beadSize, t, moveBlockSize, lockedFrame(&caq, t, t), 1)
						moveBlockSize = 0
					}
				case ca.wait:
					t -= 1
				case:
					t -= f32(caq.cooldown) + 1
					sprite_draw(sp.timelineAttackBead, beadsStartX + beadSize*t, drawY, lockedFrame(&caq, t, t-f32(caq.startup)))
					t -= f32(caq.startup)
			}
		}

		//turn divider
		sprite_draw(sp.timelineDividerBead, beadsStartX + beadSize*COMBAT_RESOLVE_INTERVAL-2, drawY+1)

		sprite_draw(unit.sprites.timelinePortrait, portraitX, drawY-1)

		drawY += 12
	}
}

combat_timeline_draw_read_order :: proc(baseAlpha:f32){
	alpha := baseAlpha*wave(0.5,0.75,66)
	diagonalSpeedMult :f32 = 6 // tweak: arrow speed multiplier on diagonal segments
	scrollSpeed :f32 = 1

	boxSize,_ := combat_timeline_box_size()
	boxPos := Vec2{COMBAT_TIMELINE_X, DISPLAY_HEIGHT/2 - boxSize.y/2}

	pipsXOff :f32 = COMBAT_TIMELINE_PIPS_X_OFF
	topY := boxPos.y + COMBAT_TIMELINE_TOP_PADDING + 8
	bottomY := boxPos.y + boxSize.y - COMBAT_TIMELINE_TOP_PADDING - 17
	height := bottomY - topY

	numVerts :: COMBAT_RESOLVE_INTERVAL*2 + 1

	// Build zigzag vertices: top0, bot0, top1, bot1, ...
	verts: [numVerts]Vec2
	for i in 0..<COMBAT_RESOLVE_INTERVAL+1{
		colX := boxPos.x + COMBAT_TIMELINE_PIPS_X + f32(i) * pipsXOff + pipsXOff/2
		verts[i*2]   = {colX, topY}
		if i < COMBAT_RESOLVE_INTERVAL do verts[i*2+1] = {colX, bottomY}
	}

	draw_rect(Rect{boxPos, boxSize}, COLOR_BLACK, 0.3*baseAlpha)
	// Draw zigzag lines
	drawCol := color_hex(0xffe4aa)
	for i in 0..<numVerts-1{
		draw_line(verts[i], verts[i+1], color=drawCol, alpha=alpha)
	}

	arrowLoopDuration :: 66
	arrowProg := f32(time.frame%arrowLoopDuration)/arrowLoopDuration
	alternate := int(time.frame%(arrowLoopDuration*2) >= arrowLoopDuration)
	for i in 0..<COMBAT_RESOLVE_INTERVAL{
		if i%2 == alternate do continue
		startInd := i*2 + int(arrowProg >= 0.5)
		prog := arrowProg < 0.5 ? arrowProg*2 : arrowProg*2-1
		angle := vec2_angle(verts[startInd+1]-verts[startInd])
		sprite_draw_ex(sp.timelineArrowSolo, lerp(verts[startInd], verts[startInd+1], prog), angle=angle, alpha=alpha)
	}

	text_draw("Turn Ends!", verts[numVerts-1] + {-1,-4}, drawCol, alpha, fo.yal5w3__16, Alignment{-1, 1})

	
}
//POST-PROCESSING
combat_shader_set :: proc(active:bool){
	if combat.time_stop_mode != .enabledWithEffect do return
	
	shader_params_set_by_name(Sh_Stage, {"timeStopEffect", i32(active)})

	combat.time_stop_shader_set = active
}

//GRID
combat_movement_path_draw :: proc(drawPath:[]Vec2, attackWarningStartInd:=-1){
	pathCol := color_hex(0xa4c245)
	if len(drawPath) > 1{
		for pos, i in drawPath[1:]{
			if i == attackWarningStartInd do pathCol = color_lerp(pathCol, color_hex(0xcc2d20), wave(0,0.4,50))
			draw_line(pos, drawPath[i], color=pathCol, alpha=1./3.)
		}
	}
	pathCol = color_hex(0xe5eec9)
	for pos,i in drawPath{
		if i == attackWarningStartInd do pathCol = color_lerp(pathCol, color_hex(0xcc2d20), wave(0,0.4,50))
		sprite_draw_ex(sp.pathShine, pos, sprite_frame_get(sp.pathShine), 1, 0, pathCol, 0.75)
	}
}

//Draws the combat grid, as well as any floor-depth UI
_combat_grid_draw :: proc(){
	planning := combat.phase == .planning
	shader_set(Sh_Base)
	//subtraction mask
	// tex_target_set(combat.grid_subtract_mask_tex, stage.camera_pos)
	// 	combatEntities := coall(CombatEntity)
	// 	for &e in combatEntities{
	// 		pos := e.pos
	// 		if unit, ok := cofind(&e, CombatUnit); ok do pos = combatUnit_ghost_position(unit)
	// 		draw_rect(Rect{combat_to_stage_pos(pos, true), Vec2(e.size)*COMBAT_TILE_SIZE}, COLOR_WHITE, 1)
	// 	}
	// tex_target_reset()
	
	//first pass, draw which parts of the combat grid get "revealed" at what level of alpha
	tex_target_set(combat.grid_tex_alpha_mask, stage.camera_pos) 
		//tex_draw(combat.grid_subtract_mask_tex, stage.camera_pos)

		palettes := COMBAT_UNIT_TYPE_PALETTES
		units := combatUnits_get()

		//revealed areas
		blendmode_set(.alphaMax)
		//draw_ellipse(mouse_stage_pos(), COMBAT_TILE_SIZE*2, innerAlpha=0.25, outerAlpha=0.25)
		if planning do draw_ellipse(mouse_stage_pos(), COMBAT_TILE_SIZE*3, innerAlpha=0.25, outerAlpha=0)

		for unit in units{
			unitCenter := planning ? rect_center(combatUnit_stage_rect(unit, peek(unit.ghostPositions))) : unit.stageCharacter.transform.pos
			//draw_ellipse(unitCenter, COMBAT_TILE_SIZE*3.5, innerAlpha=0.25, outerAlpha=0.25)
			draw_ellipse(unitCenter, COMBAT_TILE_SIZE*5.5, innerAlpha=0.25, outerAlpha=0)
		}

		//alphas := {0,0.12,0.2,0.12,0.2,0}
		alphas := []f32{0,0.24,0.4,0.24,0.4,0}
		for ripple in combat.grid_ripples{
			draw_rings(ripple.pos, {ripple.radii, ripple.radii - COMBAT_RIPPLE_OUTER_THICKNESS, ripple.radii - COMBAT_RIPPLE_OUTER_THICKNESS,  ripple.radii - (COMBAT_RIPPLE_OUTER_THICKNESS+COMBAT_RIPPLE_MIDDLE_THICKNESS), ripple.radii - (COMBAT_RIPPLE_OUTER_THICKNESS+COMBAT_RIPPLE_MIDDLE_THICKNESS), ripple.radii - COMBAT_RIPPLE_THICKNESS}, alphas=alphas)
		}
		blendmode_set(.blend)

		//masks
		for unit in units{
			for pos, i in unit.ghostPositions{
				blendmode_set(.one)
				draw_rect(combatUnit_stage_rect(unit, pos), COLOR_WHITE, 0.1)
				blendmode_set(.blend)
			}
		}
	
	//second pass, draw pre-drawn combat grid texture at correct camera position then cut out parts which get revealed
	_,gridStageOffset := split(combat.grid_stage_pos/COMBAT_TILE_SIZE)
	gridStageOffset *= COMBAT_TILE_SIZE
	gridDrawPos := floor((stage.camera_pos-gridStageOffset)/COMBAT_TILE_SIZE)*COMBAT_TILE_SIZE + gridStageOffset
	tex_target_set(combat.grid_buffer_tex_a, stage.camera_pos)
		tex_draw_ex(combat.grid_base_tex, gridDrawPos)
		blendmode_set(.subtractInverse)
		tex_draw(combat.grid_tex_alpha_mask, stage.camera_pos)
		blendmode_set(.blend)
	
	//draw final combat grid
	tex_target_set(combat.grid_tex, stage.camera_pos, false)
		//copy over main tex for correct alpha blending
		tex_draw(display_main_tex(), stage.camera_pos)

		//draw revealed combat grid using shader for animated effect
		shader_set(Sh_GridBase{
			texSize = Vec2(combat.grid_tex.size),
			tileSize = COMBAT_TILE_SIZE,
			gridDisplayPos = gridDrawPos-stage.camera_pos,
			time = i32(time.frame),
		})
		tex_draw(combat.grid_buffer_tex_a, stage.camera_pos)
		shader_reset()


		blocks := combatEntities_static_get()

		for block in blocks{
			drawRect := Rect{combat_to_stage_pos(block.pos, true), Vec2(block.size)*COMBAT_TILE_SIZE}
			draw_rect_outline(drawRect, 1, COLOR_BLACK, 0.6)
		}

		if planning{
			//masks
			for unit in units{
				pal := palettes[unit.unitType]
				for pos, i in unit.ghostPositions{
					drawRect := combatUnit_stage_rect(unit, pos)
					if i == len(unit.ghostPositions)-1{
						if unit.unitState == .alive{
							draw_rect_outline(drawRect, 1, pal.light, 1)
							rect_resize_in_place(&drawRect, -1, -1)
							draw_rect_outline(drawRect, 1, pal.dark, 1)
							//rect_resize_in_place(&drawRect, -1, -1)
						}
						else do draw_rect_outline(drawRect, 1, pal.dark, 1)
					}
					else{
						draw_rect_outline(drawRect, 1, COLOR_BLACK, 0.6)
						//rect_resize_in_place(&drawRect, -2, -2)
					}
				}
			}

			//movement paths
			for unit in units{
				curPos := unit.combatEntity.pos
				lastPos := curPos
				ghostPathPositionsArr := make([dynamic]Vec2, 0, len(unit.queuedActions), context.temp_allocator)
				curStep := combat.current_step + unit.stunCounter
				attackWarningStartInd := -1
				for &caq in unit.queuedActions{
					curStep += caq.startup
					if(caq.action.updateGhostPosition != nil) do caq.action.updateGhostPosition(&caq, &curPos)

					if lastPos != curPos{
						append(&ghostPathPositionsArr, rect_center(combatUnit_stage_rect(unit, curPos)))
						if unit.unitType == .player && unit.drawAttackWarningLevel > 0 && curStep == unit.drawAttackWarningMovementAimMarkers[0].step{
							attackWarningStartInd = len(ghostPathPositionsArr)
						}
					}
					curStep += 1 + caq.cooldown
					lastPos = curPos
				}

				if len(ghostPathPositionsArr) > 0 do inject_at(&ghostPathPositionsArr, 0, rect_center(combatUnit_stage_rect(unit, unit.combatEntity.pos)))
				
				combat_movement_path_draw(ghostPathPositionsArr[:], attackWarningStartInd)
			}

		}
		else{
			//masks
			for unit in units{
				pal := palettes[unit.unitType]
				drawRect := Rect{unit.stageCharacter.transform.pos, Vec2(unit.combatEntity.size)*COMBAT_TILE_SIZE}
				drawRect.pos -= drawRect.size/2
				draw_rect_outline(drawRect, 1, pal.light, 1)
				rect_resize_in_place(&drawRect, -1, -1)
				draw_rect_outline(drawRect, 1, pal.dark, 1)
				rect_resize_in_place(&drawRect, -1, -1)
			}

		}

		//action targets
		appendTargetToDraw :: proc(caq:^CombatActionQueued){
			triggerStep := combatActionQueued_trigger_step(caq)
			alpha :f32= 0.5
			outlineAlpha:f32 = 1
			col := color_hex(0xad3d30)
			if combat.phase == .resolving{
				alpha = wave(0.33, 1, 35)
				outlineAlpha = alpha
			}
			else if !caq.user.actionPreviewPinned{
				previewStep := combatActionQueued_target_preview_step(caq)
				switch{
					case triggerStep+1>previewStep: 
						alpha = wave(0.15, 0.33, 75)
						outlineAlpha = 0.2
						col = color_lerp(col, COLOR_YELLOW, 0.08)
					case triggerStep+1==previewStep: alpha = wave(0.33, 0.5, 12)
					case triggerStep+1<previewStep: 
						alpha = 0.15
						outlineAlpha = 0.15
						col = color_lerp(col, COLOR_BLACK, 0.7)
				} 
			}
			else do col = color_mul(col, color_lerp(color_hex(0xc29566), color_hex(0xffe7b8), wave(0,1,50)))
			if triggerStep >= combat.next_planning_step{
				alpha *= 0.5
				outlineAlpha = 0.125
			}

			if alpha <= 0 do return

			drawTex, drawPos := combat_target_draw(caq.target)
			append(&combat.action_targets_to_draw, CombatActionTargetDrawInfo{caq, drawTex, drawPos, col, alpha, outlineAlpha})
		}

		if planning{
			//action previews
			for unit in units{
				curStep := combat.current_step + unit.stunCounter
				if !unit.actionPreviewPinned && combat.preview_time.targetStep <= curStep do continue
				previewStep := combatUnit_preview_step(unit)
				lastPreviewAction := false
				for &caq in unit.queuedActions{
					if previewStep != -1{
						curStep += caq.startupCounter
						//if previewStep <= curStep do break
						curStep += 1 + caq.cooldown
						if previewStep <= curStep do lastPreviewAction = true
					}
					
					if !(caq.kind in CombatActionKinds{.basic, .travel, .evasion}){
						if tUnit, ok := caq.target.(^CombatUnit); !ok || tUnit != caq.user{
							appendTargetToDraw(&caq)
						}
					}
					
					if lastPreviewAction do break
				}
			}
		}
		else if combat.resolve_head >= 0 && combat.resolve_action.action != nil{
			appendTargetToDraw(&combat.resolve_action)
		}

		tex_target_set(combat.action_targets_stencil_tex, stage.camera_pos)
			blendmode_set(.alphaOnly)
			for info in combat.action_targets_to_draw{
				using info
				tex_draw_ex(drawTex, drawPos, alpha=1./16.)
			}
			blendmode_set(.blend)
		tex_target_reset()

		//hoevered action aiming rings
		if planning && combat.selected_action == nil{
			if previewedActions := combat_previewed_actions(); len(previewedActions) > 0{
				user := combat.selected_unit
				for action in previewedActions{
					combatAction_aiming_ring_draw(
						user, 
						combatAction_aiming_range_mask(action, user.combatEntity.size), 
						combat.aiming_colors[action.kind][1]
					)
				}	
			}
		}

		//action targets
		shader_set(Sh_ActionTarget)
		shader_texture_bind("stencilTex", combat.action_targets_stencil_tex)
		stencilTexSize := Vec2(combat.action_targets_stencil_tex.size)

		//fill pass
		for info in combat.action_targets_to_draw{
			using info
			shader_params_set(Sh_ActionTarget{
				stencilTexSize = stencilTexSize,
				drawMode = 0,
				texSize = Vec2(drawTex.size),
				outlineRevealAngle = 90, //todo
				centerPos = combatUnit_draw_pos(caq.user, combatUnit_ghost_position(caq.user)),
				stencilOffset = drawPos - stage.camera_pos,
			})
			tex_draw_ex(drawTex, drawPos, color=color, alpha=alpha)
		}
		//outline pass
		for info in combat.action_targets_to_draw{
			using info
			shader_params_set(Sh_ActionTarget{
				stencilTexSize = stencilTexSize,
				drawMode = 1,
				texSize = Vec2(drawTex.size),
				outlineRevealAngle = 90, //todo
				centerPos = combatUnit_draw_pos(caq.user, combatUnit_ghost_position(caq.user)),
				stencilOffset = drawPos - stage.camera_pos,
			})
			tex_draw_ex(drawTex, drawPos, color=color, alpha=outlineAlpha)
		}
		shader_reset()
		
		//targets to draw get cleaned up in silhouette draw

		//action targeting
		if planning && combat.selected_action != nil do _combat_action_targeting_draw()

		//letterboxes, cut out grid UI if it falls outside the actual combat area
		cam := stage_camera_rect()
		gridRect := Rect{combat.grid_stage_pos-{1,1}, Vec2(combat.grid_size)*COMBAT_TILE_SIZE+{2,2}}
		letterBoxRects := [4]Rect{
			rect_make_points(cam.pos, 									Vec2{rect_get_right(gridRect), gridRect.y}),
			rect_make_points(Vec2{rect_get_right(gridRect), cam.y}, 		Vec2{rect_get_right(cam), rect_get_bottom(gridRect)}),
			rect_make_points(Vec2{gridRect.x, rect_get_bottom(gridRect)}, rect_get_bottom_right(cam)),
			rect_make_points(Vec2{cam.x, gridRect.y}, 					Vec2{gridRect.x, rect_get_bottom(cam)})
		}
		for rect in letterBoxRects{
			if(rect_is_positive(rect)){
				blendmode_set(.subtract)
				draw_rect(rect, COLOR_WHITE, 1)
				blendmode_set(.blend)
			}
		}
	tex_target_reset(3)

	tex_draw(combat.grid_tex, stage.camera_pos)

	//draw cursor
	for{ //for breaks
		if !planning || cutscene.enabled do break
		targetRect:Rect
		targetCol:Color
		ignoreTarget := false
		if combat.selected_unit != nil{
			if combat.selected_action == ca.movement{
				distance, ringDist := combat_movement_targeting_distance()
				if(distance > 0 && ringDist < COMBAT_RESOLVE_INTERVAL){
					targetRect = combatUnit_stage_rect(combat.selected_unit, combat.selected_action_target.(Vec2i))
					targetCol = color_lerp(combat.movement_ring_colors[ringDist], COLOR_WHITE, 0.25)
					if combat.selected_unit.drawAttackWarningLevel > 0{
						targetCol = color_lerp(targetCol, color_hex(combat.selected_unit.drawAttackWarningLevel == 1 ? 0xffc20a:0xcc2d20), wave(0,0.4,50))
					}
				}
				else do ignoreTarget=true
			}
			else{
				step := combatUnit_preview_step(combat.selected_unit)
				if combat.selected_unit.actionPreviewPinned do step = -1
				targetRect = combatUnit_stage_rect(combat.selected_unit, combatUnit_ghost_position(combat.selected_unit, step))
				targetCol = color_hex(0xffe4aa)
				rect_resize_in_place(&targetRect, 1, 1)
			}
		}
		else{
			combatCursorPos := combat_cursor_pos()
			if !combat_rect_in_grid(combatCursorPos.x, combatCursorPos.y, 1, 1) do break
			targetRect = Rect{combat_to_stage_pos(combatCursorPos, true), COMBAT_TILE_SIZE}
			targetCol = COLOR_WHITE
		}
		drawRect := ui_cue_map_stateful("combatUnitSelection", 6, targetRect, cu.easeIn, false, ignorePassedTarget=ignoreTarget)
		drawCol := ui_cue_map_stateful("combatUnitSelection", 6, targetCol, cu.easeIn, false, ignorePassedTarget=ignoreTarget)

		shader_set(Sh_CombatCursor{
			time = f32(time.frame),
			rectSize = drawRect.size,
		})
		ui_cue("combatCursorDraw")
		tex_draw_ex(render.blank_tex, drawRect.pos, drawRect.size, color=drawCol, alpha=ui_cue_map("combatCursorDraw", 1,7,0,1))
		shader_reset()
		break
	}

	shader_reset()

	tex_target_set(combat.grid_buffer_tex_a) //store main tex to sample later when drawing action target silhouettes
		tex_draw(display_main_tex(), 0,0)
	tex_target_reset()
}
_combat_action_target_silhouettes_draw :: proc(){
	mainTex := display_snapshot()

	shader_set(Sh_ActionTarget)
	shader_texture_bind("floorTex", combat.grid_buffer_tex_a)
	shader_texture_bind("mainTex", mainTex)
	for info in combat.action_targets_to_draw{
		using info
		shader_params_set(Sh_ActionTarget{
			floorTexSize = Vec2(mainTex.size),
			stencilTexSize = Vec2(combat.action_targets_stencil_tex.size),
			drawMode = 2,
			texSize = Vec2(drawTex.size),
			outlineRevealAngle = 90, //todo
			centerPos = combatUnit_draw_pos(caq.user, combatUnit_ghost_position(caq.user)),
			stencilOffset = drawPos - stage.camera_pos,
		})
		tex_draw_ex(drawTex, drawPos, color=color, alpha=alpha * 0.15)
	}
	shader_reset()

	//cleanup
	for info in combat.action_targets_to_draw{tex_destroy(info.drawTex)}
	clear(&combat.action_targets_to_draw)
}

_combat_aim_indicators_draw :: proc(){
	tailSize :: 0.667
	tailSpeed :: 0.02
	tailHead := mod(f32(time.frame)*tailSpeed, 1+tailSize)
	palettes := COMBAT_UNIT_TYPE_PALETTES

	units := combatUnits_get()
	for unit in units{

		//get color and adjust for desaturation
		tailCol := palettes[unit.unitType].light
		lum := 0.299*f32(tailCol.r) + 0.587*f32(tailCol.g) + 0.114*f32(tailCol.b)
		tailCol.r = u8(clamp(2*f32(tailCol.r) - lum, 0, 255))
		tailCol.g = u8(clamp(2*f32(tailCol.g) - lum, 0, 255))
		tailCol.b = u8(clamp(2*f32(tailCol.b) - lum, 0, 255))

		for &caq in unit.queuedActions{
			if caq.kind == .attack && 
			caq.aimKind in (CombatActionAimKinds{.freeAim, .freeAimCornered, .directionalRanged}) &&
			(caq.user.actionPreviewPinned || (
				combatUnit_queued_action_on_step(caq.user, combat.preview_time.targetStep-1) == &caq &&
				combatActionQueued_target_preview_displayed(&caq)
			))
			{
				startPos:=Vec3{0,1,0}
				startPos.xy += len(caq.user.ghostDrawData)>0 ? peek(caq.user.ghostDrawData).pos : caq.user.stageCharacter.transform.pos
				finalPos:Vec3
				finalPos.xy = combat_to_stage_pos(rect_center(caq.targetBounds))
				highestPos := Vec3{0,0,-50}
				highestPos.xy = lerp(startPos.xy, finalPos.xy, 0.5)

				
				
				dist := vec2_distance(startPos.xy, finalPos.xy)
				prevDrawPos := Vec2{startPos.x, startPos.y+startPos.z}
				step :: 2
				segs := dist/step
				for n:f32=step;n<=dist;n+=step{
					t := n/dist
					distBehind := tailHead-t

					projPos := arc_projectile_pos(startPos, highestPos, finalPos, n/dist)
					drawPos := Vec2{projPos.x, projPos.y+projPos.z}
					if distBehind >= 0 && distBehind <= tailSize{
						fade := 1 - distBehind/tailSize
						render_depth(-projPos.y)
						draw_line(prevDrawPos, drawPos, color=color_lerp(COLOR_WHITE, tailCol, 1-fade, cu.popIn), alpha=fade)
					}
					prevDrawPos = drawPos
				}
			}
		}
	}
}

//Draws any top-level combat UI
_combat_UI_draw :: proc(){
	switch combat.phase{
		case .planning:
			//gamepad cursor
			sprite_draw_ex(sp.combatGamepadCursor, combat.gamepad_cursor_pos + stage.combatBounds.pos - stage.camera_pos, alpha=combat.gamepad_cursor_alpha)

			if(combat.selected_unit == nil){
				//todo:?
			}
			else{
				if(combat.selected_unit.unitType == .player){
					if(combat.selected_action == nil && combat.selected_unit.unitState == .alive) do _combat_action_select_menu_draw()
				}
				else do _combat_action_inspect_draw()
			}

			if combat.timeline_hovered{
				units := combat.resolve_queue[:]
				displayInd := 1
				#reverse for unit in units{
					centerPos := combatUnit_center_draw_pos(unit, combatUnit_ghost_position(unit, combatUnit_preview_step(unit)))
					displayIndStr := int_to_string(displayInd, context.temp_allocator)
					sprite_draw_ex(sp.circle256, centerPos+{-1,0}, scale=9./256., color=COLOR_BLACK, alpha=0.6)
					text_draw(displayIndStr, centerPos+1, color_hex(0x4f3e3b), 1, fo.yal5w3__16, Alignment{0, 0})
					text_draw(displayIndStr, centerPos, color_hex(PAUSE_MENU_TEXT_COL), 1, fo.yal5w3__16, Alignment{0, 0})
					displayInd += 1
				}
			}

			_combat_timeline_draw()

			//execute button
			timeStoppedT := ui_cue_time("timeStopped")
			if !(cutscene.name == "timestopStart" && timeStoppedT >= 40) && (combat.time_stop_mode == .enabledWithEffect || combat.time_stop_force_disable){
				topRight := Vec2{DISPLAY_WIDTH-1, 0}
				clockPos := topRight+{-23,23}
				goPos := topRight+{-39,21}
				goSprite := input_device() == .gamepad ? sp.goButton_rt:sp.goButton_default
				if timeStoppedT < 40{
					ui_cue_seq_open("timeStopped")
						if seq_cue(0,40){
							drawE := COMBAT_RESOLVE_ELLIPSE
							drawE.radii *= seq_map(0,1)
							draw_ellipse(drawE, COLOR_BLACK, COLOR_BLACK, 1, 0)
						}
						if seq_cue(0, 15){
							curve := cu.easeOutStrong
							thick := seq_map(0, 12, curve)
							fuzzy_circle_draw(Circle{clockPos, seq_map(24, 6, curve)}, seq_map(0,0.5), thick*0.833, thick/0.833)
						}
						if seq_cue(15,40){
							sprite_draw_ex(goSprite, seq_map(clockPos, goPos, cu.popIn))
							sprite_draw_ex(sp.resolveClock_base, clockPos)
							sprite_draw_ex(sp.resolveClock_hand, clockPos, angle=90)
							shader_set(Sh_ColorOnly)
							sprite_draw_ex(sp.resolveClock_base, clockPos, alpha=seq_map(1,0, cu.easeInHeavy))
							shader_reset()
						}
					seq_close()
				}
				else{
					hoverT := f32(ui_cue_time("resolveButtonHover"))
					offset:= ui_cue_map_reversible("resolveButtonHover", 3, 0, -6)
					hovering := offset!=0
		
					col := hovering?color_lerp(COLOR_WHITE, color_hex(0xffe7b8), wave(0, 1, 30, currentTime=hoverT)):COLOR_WHITE
					drawE := COMBAT_RESOLVE_ELLIPSE
					drawE.pos.x += offset
					draw_ellipse(drawE, COLOR_BLACK, COLOR_BLACK, 1, 0)
					
					clockPos.x += offset
					goPos.x += offset*1.667
					sprite_draw_ex(goSprite, goPos, color=col)
					sprite_draw_ex(sp.resolveClock_base, clockPos, color=col)
					sprite_draw_ex(sp.resolveClock_hand, clockPos, angle=hovering?90-hoverT*24:90, color=col)
					//sprite_draw(sp.combatResolveButton, COMBAT_RESOLVE_BUTTON_POS)
				}
			}


		case .resolving:
			if DEBUG && combat.resolving_ui_disable do break
			_combat_timeline_draw()

			//action title
			if combat.resolving_action_title_scale > 0{
				drawY :: 44
				fonts.default = fo.fairfaxBold__12
				size := (text_char_height()+4)
				drawTex := tex_make(DISPLAY_WIDTH, size)
				defer tex_destroy(drawTex)
				tex_target_set(drawTex, clear=false)
				draw_clear(COLOR_BLACK, 255*0.8)
				text_draw(combat.resolving_action_title, DISPLAY_WIDTH/2, size/2, alignment=Alignment{0,0})
				tex_target_reset()
				tex_draw_ex(drawTex, 0, drawY-(size/2)*combat.resolving_action_title_scale, scale=Vec2{1, combat.resolving_action_title_scale})
			}
		
		case .starting:
		case .ending:
		case .revival:
		case .disabled:
	}
}

