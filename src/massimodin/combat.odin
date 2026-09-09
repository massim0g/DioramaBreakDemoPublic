#+feature using-stmt
package massimodin //@nested-tags:combat/

CombatSystem :: struct{
	//combat state
	phase:CombatPhase,
	started:bool,
	current_step:int,
	preview_time:CombatPreviewTime,
	next_planning_step:int,
	encounter_id:string,
	encounter_flag_level:FlagLevel,
	success_callback:Callback, //called when last enemy is killed
	failure_callback:Callback, //called if all player units fall to 0 hp
	end_flag:bool, //if set to true during resolving phase, combat will end as soon as the current action has finished resolving
	reset_camera_on_end:bool, //if set to true, camera will pan back to the player during the ending sequence
	reactive_unit_exists:bool, //checked at the start of each planning phase, used to gate some potentially expensive checks
	
	//resolving state
	resolve_queue:[dynamic]^CombatUnit,
	resolve_head:int,
	action_resolve_allocator:Allocator,
	eventCallbacks:[dynamic]CombatEventCallback,
	units_async_resolve:[dynamic]^CombatUnit,
	units_bumped:[dynamic]^CombatUnit,
	defer_start_anim_unit_types:bit_set[CombatUnitType], //used in cases where a side gets ambushed, their combat start anims will only play after the first planning phase 
	defer_start_anim_units:[dynamic]^CombatUnit,
	waiting_for_cutscene:bool, //is enabled after any action resolves, wait for cutscenes to finish before continuing to resolve
	resolve_async:bool, //enables async action resolution
	phase_started:bool,
	resolve_action:CombatActionQueued,
	
	//grid
	grid:Grid(CombatGridTile),
	occupancy_grid:[128]u128,
	grid_size:Vec2i,
	grid_stage_pos:Vec2,

	//UI
	selected_unit:^CombatUnit,
	action_select_hover_index:int,
	selected_action:^CombatAction,
	selected_action_targetable_area:CombatTarget,
	selected_action_target:CombatTarget,
	action_targeting_allocator:Allocator, //freed when action targeting is done
	action_targeting_temp_allocator:Allocator, //freed when action targeting is updated
	camera_speed:f32,
	grid_ripples:[dynamic]Ellipse,
	time_stop_mode:enum{
		disabled,
		enabled,
		enabledWithEffect
	},
	time_stop_shader_set:bool,
	time_stop_saturation:f32,
	time_stop_transition_bg:Tex,
	time_stop_transition_maskA:Tex,
	time_stop_transition_maskB:Tex,
	time_stop_force_disable:bool,
	timeline_pips:map[^CombatUnit]map[uuid]CombatTimelinePip,
	timeline_resolve_time:struct{
		step:int,
		head:int
	},
	timeline_break_particle:^ParticleType,
	timeline_hovered:bool,
	timeline_hover_unit:^CombatUnit,
	timeline_gamepad_hover_pos:Vec2i,
	resolving_action_title:string,
	resolving_action_title_scale:f32,
	cues:UICueMap,
	disable_external_menus:bool, //for allowing the player to interact with the combat UI while disabling the pause menu and next turn button. Mainly for tutorials.
	resolving_ui_disable:bool, //mainly for footage capture
	gamepad_cursor_pos:Vec2, //relative to the grid
	gamepad_cursor_alpha:f32,

	//revival
	revival_pokes:int,
	revivals_remaining:int,
	revival_label_bag:Bag(string),
	revival_questions_remaining:int,
	revival_override_cutscene:string,
	revival_override_cutscene_namespace:string,

	//rendering
	grid_base_tex:Tex, //rendered once on system reload, grid lines
	grid_tex:Tex,
	grid_buffer_tex_a:Tex, //used to snapshot textures for various purposes when drawing the grid
	action_targets_stencil_tex:Tex,
	grid_tex_alpha_mask:Tex,
	aiming_ring_mask_tex:Tex,
	movement_ring_colors:[COMBAT_RESOLVE_INTERVAL]Color,
	aiming_colors:[CombatActionKind][2]Color,
	action_targets_to_draw:[dynamic]CombatActionTargetDrawInfo,

	//data
	unit_inits:map[string]proc(self:^CombatUnit),
	unit_init_names:[]string,
	actions:map[string]CombatAction,

	//audio
	music_override:AudioEvent,
	_music_overrided:AudioEvent
}
combat:^CombatSystem

//mainly for attack warning indicators
CombatMarker :: struct{
	pos:Vec2i,
	step:int
}

COMBAT_TILE_SIZE :: Vec2{16, 8}
COMBAT_TILE_RADIUS :: Vec2{8, 4} //can't do COMBAT_TILE_SIZE/2 for some reason
COMBAT_RESOLVE_INTERVAL :: 6
COMBAT_SUBSTEP_TIME :: 25 //roughly how long it takes for one unit to perform one simple action such as movement in one step 
COMBAT_UNIT_CAP :: 64

COMBAT_RIPPLE_OUTER_THICKNESS :: Vec2{60, 30}
COMBAT_RIPPLE_MIDDLE_THICKNESS :: Vec2{40, 20}
COMBAT_RIPPLE_INNER_THICKNESS :: Vec2{240, 120}
COMBAT_RIPPLE_THICKNESS := COMBAT_RIPPLE_OUTER_THICKNESS + COMBAT_RIPPLE_MIDDLE_THICKNESS + COMBAT_RIPPLE_INNER_THICKNESS

_combat_system_init :: proc(){
	trace("Combat System Init")
	combat = new(CombatSystem)
	ca = new(CombatBasicActionIDs)
	
	combat.grid = grid_make(CombatGridTile, 128, 128)
	for &tile in combat.grid.buf{
		init(&tile.occupants, 0, 1)
	}
	init(&combat.resolve_queue)
	combat.action_resolve_allocator  = allocator_make()
	combat.action_targeting_allocator = allocator_make()
	combat.action_targeting_temp_allocator = allocator_make()
	init(&combat.cues)
	init(&combat.units_async_resolve)
	init(&combat.units_bumped)
	init(&combat.defer_start_anim_units)
	bag_init(&combat.revival_label_bag, "")

	init(&combat.timeline_pips)

	combat.camera_speed = 3

	reserve(&entities._component_arrays.__combatUnit, COMBAT_UNIT_CAP) //ensures that adding units mid-combat won't invalidate unit pointers

	texSize := DISPLAY_SIZE+COMBAT_TILE_SIZE*2
	combat.grid_base_tex = tex_make(texSize)

	combat.grid_tex = tex_make(texSize)
	combat.grid_buffer_tex_a = tex_make(texSize)
	init(&combat.action_targets_to_draw)
	combat.action_targets_stencil_tex = tex_make(texSize)
	
	combat.aiming_ring_mask_tex = tex_make(texSize)
	combat.grid_tex_alpha_mask = tex_make(texSize)

	combat.time_stop_transition_bg = tex_make(DISPLAY_SIZE)
	combat.time_stop_transition_maskA = tex_make(DISPLAY_SIZE)
	combat.time_stop_transition_maskB = tex_make(DISPLAY_SIZE)

	combat.movement_ring_colors = [COMBAT_RESOLVE_INTERVAL]Color{
		// color_hex(0x60bf30), 
		// color_hex(0xdaad5d), 
		// color_hex(0xe07940),
		// color_hex(0xe14141),
		// color_hex(0x803c31),
		// color_hex(0x803c31),
		color_hex(0xdfffab), 
		color_hex(0x8cbb60), 
		color_hex(0x6c8950),
		color_hex(0x43694c),
		color_hex(0x353b32),
		color_hex(0x161616),
	}

	// {aim area, bounds ring}
	combat.aiming_colors = {
		.attack =	{color_hex(0xc05439), color_hex(0x7f3429)},
		.travel = 	{color_hex(0x7d8d22), color_hex(0x3d5c55)},
		.evasion = 	{color_hex(0x7d8d22), color_hex(0x3d5c55)},
		.support = 	{color_hex(0xc19019), color_hex(0x825b24)},
		.defense = 	{color_hex(0x7896c6), color_hex(0x445178)},
		.basic = 	{COLOR_WHITE, COLOR_BLACK},
	}

	init(&combat.eventCallbacks)

}

_combat_system_reload :: proc(){
	_combat_actions_reload_basic()
	_combat_actions_reload_pro()
	_combat_actions_reload_minima()

	_combat_unit_inits_reload()

	//set basic action pointers
	ca.wait = &combat.actions["wait"]
	ca.movement = &combat.actions["movement"]
	ca.testAttack = &combat.actions["testAttack"]

	//reload action ids and target masks
	for id, &action in combat.actions{ 
		action.id = id

		if action.aimingMasksDefaultUserSize == 0 do action.aimingMasksDefaultUserSize = 3
		action.aimingRangeMask = combatAction_aiming_range_mask(&action, action.aimingMasksDefaultUserSize, false, assets.allocator)
		#partial switch action.aimKind{
			case .directionalRanged: action.aimingBoundsMask = combatAction_aiming_bounds_mask(&action, action.aimingMasksDefaultUserSize, false, assets.allocator)
			case .freeAim, .freeAimCornered: action.aimingBoundsMask = action.aimingRangeMask
		}
	}
	

	tex_target_set(combat.grid_base_tex)
		texSize := Vec2(combat.grid_base_tex.size)

		// r := Rect{{0,0}, COMBAT_TILE_SIZE - Vec2{2, 3}}
		// for y:f32=0;y<texSize.y;y+=COMBAT_TILE_SIZE.y{
		// 	for x:f32=0;x<texSize.x;x+=COMBAT_TILE_SIZE.x{
		// 		r.pos = {x+1,y+2}
		// 		draw_rect(r, COLOR_BLACK)
		// 		r.y -= 1
		// 		draw_rect(r, COLOR_WHITE)
		// 	}
		// }
		
		for y:f32=0;y<texSize.y;y+=COMBAT_TILE_SIZE.y{
			draw_line(0, y, texSize.x, y, color=COLOR_BLACK)
		}
		for x:f32=0;x<texSize.x;x+=COMBAT_TILE_SIZE.x{
			draw_line(x, 0, x, texSize.y, color=COLOR_BLACK)
		}

		for y:f32=COMBAT_TILE_SIZE.y-1;y<texSize.y;y+=COMBAT_TILE_SIZE.y{
			draw_line(0, y, texSize.x, y, color=COLOR_WHITE)
		}
		for x:f32=COMBAT_TILE_SIZE.x-1;x<texSize.x;x+=COMBAT_TILE_SIZE.x{
			rightX := x+COMBAT_TILE_SIZE.x-1
			draw_line(x, 0, x, texSize.y, color=COLOR_WHITE)
		}

	tex_target_clear()

	combat.timeline_break_particle = particle_type(sp.timelinePips_wait, 100, 100, 2, 3, Vec2{0,0.21}, angleSpread=0, dir=90, dirSpread=90)
}

CombatGridTile :: struct{
	occupants:[dynamic]CoRefEx(CombatEntity)
}

CombatPhase :: enum{
	disabled,
	starting,
	ending,
	planning,
	resolving,
	revival
}

CombatDamageKind :: enum{
	physical,
	air
}

CombatPreviewTime :: struct{
	targetStep:int,
	displayedStep:f32,
	initiative:int
}

//HELPER FUNCTIONS

//Will return the center of the given grid tile.
//If corner is true, will return the top-left tile position instead
combat_to_stage_pos :: proc(pos:Vec2i, corner:=false) -> Vec2{
	return (Vec2(pos) + (corner ? {0,0} : {0.5, 0.5}))*COMBAT_TILE_SIZE + combat.grid_stage_pos
}

stage_to_combat_pos :: proc(pos:Vec2) -> Vec2i{
	return floori((pos - combat.grid_stage_pos)/COMBAT_TILE_SIZE)
}

combat_cursor_pos :: proc() -> Vec2i{
	switch input_device(){
		case .keyboard: return stage_to_combat_pos(mouse_stage_pos())
		case .gamepad: return floori(combat.gamepad_cursor_pos/COMBAT_TILE_SIZE)
	}
	unreachable()
}

//mainly for gamepad edge-cases, normally just returns mouse stage pos
combat_cursor_stage_pos :: proc() -> Vec2{
	switch input_device(){
		case .keyboard: return mouse_stage_pos()
		case .gamepad: return stage.combatBounds.pos + combat.gamepad_cursor_pos
	}
	unreachable()
}

//START
combat_start :: proc(musicOverride:AudioEvent=nil, encounterID:string="", encounterFlagLevel:=FlagLevel.temp, success:Callback=combat_success_callback_default, failure:Callback=combat_failure_callback_default, deferStartAnim:bit_set[CombatUnitType]=nil, timeStopForceDisable:=false, resetCameraOnEnd:=false){
	if combat.phase != .disabled do combat_end(true)

	ui_cue("combatStart")

	combat.grid_size = ceili(stage.combatBounds.size/COMBAT_TILE_SIZE)
	grid_size_set(&combat.grid, combat.grid_size.x, combat.grid_size.y)
	combat.grid_stage_pos = stage.combatBounds.pos

	combatEntities := coall(CombatEntity)
	for &combatEntity in combatEntities{
		unit, unitFound := cofind(&combatEntity, CombatUnit)

		cRect := combatEntity.rect
		
		if unitFound do cRect.pos = floori((combatEntity.transform.pos-combat.grid_stage_pos)/COMBAT_TILE_SIZE) - cRect.size/2
		else if combatEntity.spawnWithExactDimensions{
			stageBounds := combatEntity.transform.attachedCollider.bounds
			cRect.pos = stage_to_combat_pos(stageBounds.pos)
			cRect.size = Vec2i(stageBounds.size/COMBAT_TILE_SIZE)
		}
		else do cRect.pos = roundi((combatEntity.transform.pos-combat.grid_stage_pos)/COMBAT_TILE_SIZE) - Vec2i{cRect.size.x/2, cRect.size.y/2+2}

		inGrid := combat_rect_in_grid(cRect.x, cRect.y, cRect.size.x, cRect.size.y)

		if !inGrid && unitFound && unit.forceCombatGridEntry{
			cRect.pos = combat_nearest_free_space(unit, cRect.pos, false)
			inGrid = true
		}

		if(cRect.size.x != 0 && cRect.size.y != 0 && inGrid){
			if unitFound{
				combatUnit_player_actions_set(unit)
				if pf,ok:=cofind(unit, PlayerFollower);ok&&pf.runFromCombat{
					continue
				}
				combatUnit_add_to_system(unit, cRect.pos)
			}
			else{
				if combatEntity.spawnWithExactDimensions do combatEntity.size = cRect.size
				combatEntity_place(&combatEntity, cRect.pos)
			}
		}
	}

	//overlap check
	units := combatUnits_get()
	for unit in units{
		combatEntity_unplace(unit.combatEntity)
		if combat_collision(unit.combatEntity.rect) do combatEntity_place(unit.combatEntity, combat_nearest_free_space(unit, unit.combatEntity.pos, false))
		else do combatEntity_place(unit.combatEntity)
	}
	
	combat.music_override = musicOverride
	combat.encounter_id = encounterID
	combat.encounter_flag_level = encounterFlagLevel
	combat.success_callback = success
	combat.failure_callback = failure
	combat.defer_start_anim_unit_types = deferStartAnim
	combat.time_stop_force_disable = timeStopForceDisable
	combat.gamepad_cursor_pos = stage.combatBounds.size/2 //gets reset to camera position on planning start, but this ensures cursor is always in-bounds during combat
	combat.reset_camera_on_end = resetCameraOnEnd

	combat.revivals_remaining = 1

	combat.phase = .starting
	combat.current_step = 0
	combat.resolve_head = len(combat.resolve_queue) - 1
	combat.timeline_resolve_time = {combat.current_step, combat.resolve_head}
	combat.next_planning_step = COMBAT_RESOLVE_INTERVAL
	camera_tracking_set()

	_combat_timeline_update() //ensure pip maps are allocated

	if stage.onCombatStart != nil do stage.onCombatStart()
}

//Recommended that you only call this after resolving all current actions to minimize animation issues.
combat_end :: proc(immediately:=false){
	combat.phase = .ending
	combat.selected_action = nil
	combat.selected_unit = nil

	if immediately{
		if combat.music_override != nil do music_set(combat._music_overrided)
		combat_state_clear()
		audio_parameter_set("inBattle", 0)
		combat.time_stop_mode = .disabled
		_combat_timestop_update_stage_entities()
	}
}

combat_resolve_start :: proc(){
	if !equals(combat.phase, CombatPhase.planning, CombatPhase.revival) do return
	proc_call_delayed(proc(){combat.phase = .resolving}, 1)
	if !combat.time_stop_force_disable do cutscene_start("timestopEnd")
	combat.selected_unit = nil
	combat.phase_started = false
}

combat_revival_start :: proc(){
	dia, ok := &dialogue._dialogues_map[format("%sRevival", combat.selected_unit.initID)]
	assertf(ok, "Could not find revival dialogue for unit with id '%s'", combat.selected_unit.initID)
	d := dialogue_data(dia)
	combat.phase = .revival
	combat.revivals_remaining -= 1
	combat.revival_questions_remaining = 3

	clear(&combat.revival_label_bag.buf)
	for label in d.labelsMap{
		if label[0] == 'q' do bag_add(&combat.revival_label_bag, label)
	}

	//clear uncommitted actions
	units := combatUnits_get()
	for unit in units{
		if unit.unitType != .player do continue
		for action,i in unit.queuedActions{
			if action.startupCounter == action.startup do pop(&unit.queuedActions)
		}
	}
	for unit in units{
		if unit.reactionTime >= 0 do combatUnit_AI_plan_actions(unit)
	}

	dialogue_open(dia, "revivalStart")
	flag("revivalPoints", "0", .local)
}

combat_state_clear :: proc(){
	if combat.encounter_id != ""{
		flag(format("encounter__%s", combat.encounter_id), level=combat.encounter_flag_level)
	}

	if !flag_check("safeZone"){
		units := coall(CombatUnit)
		for &unit in units{
			pid,ok := player_character_string_to_id(unit.initID.s)
			if ok{
				if unit.hp > 0 do save.characters[pid].hp = unit.hp
				else do save.characters[pid].hp = 1
			}
		}
	}

	combat.started = false
	combat.phase_started = false
	combat.end_flag = false
	combat.music_override = nil
	combat._music_overrided = nil
	ents := coall(CombatEntity)
	for &ent in ents{
		if ent.placedInGrid do combatEntity_unplace(&ent)
	}

	combat.occupancy_grid = [128]u128{}
	clear(&combat.resolve_queue)
	clear(&combat.units_async_resolve)
	clear(&combat.units_bumped)
	clear(&combat.defer_start_anim_units)
	grid_zero(&combat.grid)
	clear(&combat.eventCallbacks)
	for key,&pips in combat.timeline_pips{
		delete(pips)
	}
	clear(&combat.timeline_pips)
	clear(&combat.cues)
	combat.current_step = 0
	combat.preview_time = CombatPreviewTime{}
	combat.encounter_id = ""
	combat.resolve_action = CombatActionQueued{}
	combat.reactive_unit_exists = false
	combat.reset_camera_on_end = false

	units := coall(CombatUnit)
	for &unit in units{
		unit.actionPreviewPinned = false
		unit.drawAttackWarningLevel = 0
		if unit.unitState == .dead do entity_destroy(&unit)
	}

	for key in seq._sequences_map{ //reset combat resolve sequences that may have been interrupted early
		if string_contains(key, "combat__"){
			seq_reset(key)
		}
	}

	combat.phase = .disabled
}

combat_end_seq :: proc(key:ImKey=#caller_location) -> bool{
	if seq_open(key){
		#partial switch combat.phase{
			case .ending: //do nothing
			case .disabled: return seq_close(.end)
			case: combat_end()
		}
	}
	return seq_close()
}

combat_success_callback_default :: proc(){
	if combat.phase == .resolving do combat.end_flag = true
	else do combat_end()
} 
combat_failure_callback_default :: proc(){
	game_over()
} 

//takes a stage position and snaps it to the center of the nearest combat grid tile.
combat_grid_snapped_pos :: proc(pos:Vec2) -> Vec2{
	return combat_to_stage_pos(floori((pos-combat.grid_stage_pos)/COMBAT_TILE_SIZE))
}

//refresh the planning of all reactive units
combat_reactive_units_refresh :: proc(){
	if !combat.reactive_unit_exists do return

	combat_refresh_all_targets() //prevents memory leak if queuing/unqueuing several actions before resolving

	//update enemy AI
	units := combatUnits_get()
	for unit in units{
		if unit.reactionTime >= 0 do combatUnit_AI_plan_actions(unit)
	}
}

//UPDATE
_combat_timestop_update_stage_entities :: proc(){
	sents := coall(StageEntity)
	mul :f32= (combat.time_stop_mode != .disabled) ? 0:1
	for &ent in sents{
		if !ent.ignoreTimeStop do ent.spriter.animSpeed = ent.defaultAnimSpeed*mul
	}
}

_combat_update :: proc(){
	unitStartSeq :: proc(unit:^CombatUnit) -> bool{
		if seq_open(imkey_combine(&unit.baseBase)){
			if seq_cue(0) && unit.audioEvents.combatStart != nil do audio_play(unit.audioEvents.combatStart)
			newFacing := unit.stageCharacter.facing
			if(!equals(newFacing, Dir.left, Dir.right)) do newFacing = .right
			if stageCharacter_anim_seq(unit.stageCharacter, setSprites={unit.sprites.combatStart, unit.sprites.idle}, newFacing=newFacing, key=imkey_combine(&unit.baseBase)){
				return seq_close(.end)
			}
		}
		return seq_close()
	}

	combat.action_select_hover_index = -1
	
	combat.timeline_hovered = false
	combat.timeline_hover_unit = nil
	
	lastTargetPreviewStep := combat.preview_time.targetStep
	combat.preview_time.targetStep = combat.current_step
	combat.preview_time.initiative = -1

	combat.gamepad_cursor_alpha = 0

	switch combat.phase{
		case .revival: //anything needed?
		case .planning:
			audio_parameter_set("battlePhase", 0)

			if cutscene.enabled do break

			if entity_exists(UnitDissolveEffect) do break

			inKo := false
			units := coall(CombatUnit)
			for &unit in units{
				if unit.stageCharacter.spriter.mySprite != sp.nil_ && equals(unit.stageCharacter.spriter.mySprite, unit.sprites.koStart, unit.sprites.koGetup){
					inKo = true
					break
				}
			}
			if inKo do break

			if combat.time_stop_mode == .disabled && !combat.time_stop_force_disable{
				cutscene_start("timestopStart")
				break
			}
			else if combat.time_stop_force_disable do ui_cue("timeStopped") //for execute button

			//ensure start behaviors trigger after the first timestop effect
			if !combat.started{
				if combat.music_override != nil{
					combat._music_overrided = audio_instance_event(audio.music)
					music_set(combat.music_override)
				}
				combat.started = true
				combat_event_process(CombatEventStarted{})
			}

			if !combat.phase_started{
				combat.phase_started = true
				combat.gamepad_cursor_pos = stage.target_camera_pos - stage.combatBounds.pos
				combat.timeline_gamepad_hover_pos = -1
				combat_event_process(CombatEventPlanningStarted{})

				combat.reactive_unit_exists = false
				units := combatUnits_get()
				for unit in units{
					if unit.reactionTime >= 0{
						combat.reactive_unit_exists = true
						break
					}
				}
			}

			//pause menu
			if entity_exists(PauseMenu) do return
			if ginputs[.start] && !combat.disable_external_menus{
				entity_make(PauseMenu)
				return
			}
	

			//timeline hover and gamepad cursor
			pipsX :f32=COMBAT_TIMELINE_PIPS_X
			pipsXOff :: COMBAT_TIMELINE_PIPS_X_OFF
			boxSizeFull, extraSteps := combat_timeline_box_size()
			boxPos := Vec2{2, DISPLAY_HEIGHT/2-boxSizeFull.y/2}
			mdp := mouse_display_pos()

			switch input_device(){
				case .keyboard:
					timelineHoverArea := Rect{boxPos, boxSizeFull}

					if rect_contains(timelineHoverArea, mdp){
						combat.timeline_hovered = true

						//determine hovered unit row
						pipY := sp.timelinePips_wait.size.y
						drawYs := combat_timeline_unit_draw_ys()
						units := combat.resolve_queue[:]
						for unit,i in units{
							rowTop := drawYs[i]
							if in_range(mdp.y, rowTop, rowTop+pipY){
								combat.timeline_hover_unit = unit
								break
							}
						}
						//snap to nearest unit when hovering divider gap or top area
						if combat.timeline_hover_unit == nil && len(units) > 0{
							lastRowBottom := drawYs[0] + pipY //units[0] is bottom-most in display
							if mdp.y < lastRowBottom{
								bestDist :f32= 9999
								for unit,i in units{
									dist := abs(mdp.y - (drawYs[i] + pipY/2))
									if dist < bestDist{
										bestDist = dist
										combat.timeline_hover_unit = unit
									}
								}
							}
						}
					}

					timelineHoverArea.pos.x += pipsX
					timelineHoverArea.size.x -= pipsX+pipsXOff

					if rect_contains(timelineHoverArea, mdp){
						combat.preview_time.targetStep = combat.current_step + floori((mdp.x - timelineHoverArea.x)/pipsXOff)+1
					}

				case .gamepad:
					units := combat.resolve_queue[:]

					if ginputs[.lb]{
						if combat.timeline_gamepad_hover_pos == -1 do combat.timeline_gamepad_hover_pos = {1, len(units)}
						else do combat.timeline_gamepad_hover_pos = -1
					}

					if combat.timeline_gamepad_hover_pos != -1{
						combat.timeline_hovered = true
						combat.timeline_gamepad_hover_pos += Vec2i{
							int(ginputs[.rightL]) - int(ginputs[.leftL]),
							int(ginputs[.downL]) - int(ginputs[.upL])
						}
						combat.timeline_gamepad_hover_pos.x = wrap(combat.timeline_gamepad_hover_pos.x, 1, COMBAT_RESOLVE_INTERVAL)
						combat.timeline_gamepad_hover_pos.y = wrap(combat.timeline_gamepad_hover_pos.y, 0, len(units))

						combat.preview_time.targetStep = combat.current_step + combat.timeline_gamepad_hover_pos.x
						if combat.timeline_gamepad_hover_pos.y < len(units) do combat.timeline_hover_unit = units[len(units)- 1 -combat.timeline_gamepad_hover_pos.y]
					}

					//gamepad cursor
					movement:Vec2
					if !(combat.timeline_hovered || (combat.selected_unit != nil && combat.selected_action == nil)){
						movement = maxabs(input_gamepad_directional_axes(.lStick), input_gamepad_directional_axes(.dpad))
					}
		
					moving := movement != 0
					combat.gamepad_cursor_alpha = ui_cue_map_stateful("combatGamepadCursorMoving", 10, f32(moving?1:0))
					if moving do combat.gamepad_cursor_pos += movement*3
					else{
						nearestTilePos := floor(combat.gamepad_cursor_pos/COMBAT_TILE_SIZE)*COMBAT_TILE_SIZE + COMBAT_TILE_SIZE/2
						combat.gamepad_cursor_pos = vec2_approach(combat.gamepad_cursor_pos, nearestTilePos, 3)
					}
			}

			if combat.timeline_hover_unit != nil && combat.preview_time.targetStep != combat.current_step{
				combat.preview_time.initiative = combatUnit_initiative(combat.timeline_hover_unit)
			}
			combat.gamepad_cursor_pos = clamp(combat.gamepad_cursor_pos, 0, stage.combatBounds.size-1)
			
			interactedWithMenu:bool
			lastSelectedUnit := combat.selected_unit
			if !combat.timeline_hovered && combat.selected_unit != nil{
				if combat.selected_unit.unitType == .player{
					switch combat.selected_unit.unitState{
						case .alive:
							prevActionCount := len(combat.selected_unit.queuedActions)
							combat.preview_time.targetStep = combatUnit_queued_action_tail(combat.selected_unit)
							if len(combat.selected_unit.queuedActions) > 0{
								lastAction := peek(combat.selected_unit.queuedActions)
								combat.preview_time.targetStep -= lastAction.cooldown
								if lastAction.action != ca.movement do combat.preview_time.initiative = combatUnit_initiative(combat.selected_unit)
							}
							if(combat.selected_action != nil){
								interactedWithMenu = _combat_action_targeting_update()
								if combat.selected_action != ca.movement do combat.preview_time.initiative = combatUnit_initiative(combat.selected_unit)
							}
							else do interactedWithMenu = _combat_action_select_menu_update()
							
							if combat.selected_unit != nil && prevActionCount != len(combat.selected_unit.queuedActions){ //player queued/unqueued an action
								combat_reactive_units_refresh()
							}
						case .knockedOut:
							if rect_contains(combat.selected_unit.combatEntity.rect, combat_cursor_pos()) && ginputs[.confirm]{
								combat.revival_pokes += 1
								stageEntity_shake(combat.selected_unit.stageEntity, 6, {1.5,0})
								if combat.revival_pokes >= 3 && combat.revivals_remaining > 0{
									combat_revival_start()
									break
								}
							}
							
						case .dead: panic("Selected a dead player unit!? Spooky!")
					}
				}
			}

			if(combat.selected_action == nil && !interactedWithMenu){
				hoveringResolveButton:=false
				hoveredUnit:^CombatUnit

				if combat.timeline_hovered{
					hoveredUnit = combat.timeline_hover_unit
				}
				else{
					
					hoveredPos := combat_cursor_pos()
					units := combatUnits_get()
					for unit in units{
						ce := unit.combatEntity
						ghostPos := combatUnit_ghost_position(unit, unit.actionPreviewPinned?-1:combat.preview_time.targetStep)
						if(
							(hoveredUnit == nil || (unit.unitType == .player && (ce.pos != ghostPos || hoveredUnit.unitType != .player))) &&
							(hoveredPos.x >= ghostPos.x && hoveredPos.y >= ghostPos.y && hoveredPos.x < ghostPos.x+ce.size.x && hoveredPos.y < ghostPos.y+ce.size.y))
						{
							hoveredUnit = unit
						}
					}
	
					resolveHoverCheckE := COMBAT_RESOLVE_ELLIPSE
					resolveHoverCheckE.radii /= 2
					hoveringResolveButton = ellipse_contains(resolveHoverCheckE, mouse_display_pos()) && !combat.disable_external_menus
					if hoveringResolveButton do ui_cue("resolveButtonHover")
				}

				if !combat.disable_external_menus && ((hoveringResolveButton && ginputs[.confirm]) || ginputs[.rt] || key_pressed(.TAB)){
					combat_resolve_start()
					combat_event_process(CombatEventPlanningEnded{})
				}
				else if(ginputs[.confirm]){
					if hoveredUnit != nil{
						if combat.selected_unit != hoveredUnit{
							ui_cue("combat_action_select_menu")
							ui_cue_reset("actionSelectHover")
							audio_play(au.combatUnitSelect)
							audio_play(au.uiBoxOpen)
							combat.selected_unit = hoveredUnit
							combat.revival_pokes = 0
						}
					}
					else do combat.selected_unit = nil
				}
				else if input_device() == .gamepad && !interactedWithMenu && ginputs[.cancel] do combat.selected_unit = nil

				if ginputs[.extra] && hoveredUnit != nil do hoveredUnit.actionPreviewPinned = !hoveredUnit.actionPreviewPinned
			}

			switch input_device(){
				case .keyboard:
					cameraMoveZone :: 8
					mouseInWindow := input.mouse_in_window && !debug_free_cam_enabled()
					camDir := Vec2i{
						int(ginputs[.rightHeld] || (mouseInWindow && mdp.x > DISPLAY_WIDTH-cameraMoveZone)) - int(ginputs[.leftHeld] || (mouseInWindow && mdp.x < cameraMoveZone)),
						int(ginputs[.downHeld] || (mouseInWindow && mdp.y > DISPLAY_HEIGHT-cameraMoveZone)) - int(ginputs[.upHeld] || (mouseInWindow && mdp.y < cameraMoveZone)),
					}
					stage.target_camera_pos += Vec2(camDir)*combat.camera_speed
				case .gamepad:
					stage.target_camera_pos += vec2_normalize(input_gamepad_directional_axes(.rStick))*combat.camera_speed
			}
			

			if !debug_free_cam_enabled(){
				stage.target_camera_pos = clamp(stage.target_camera_pos, 
					max(stage.bounds.pos + DISPLAY_SIZE/2, stage.combatBounds.pos - DISPLAY_SIZE/2), 
					min(rect_get_bottom_right(stage.bounds) - DISPLAY_SIZE/2, rect_get_bottom_right(stage.combatBounds) + DISPLAY_SIZE/2)
				)
			}

			easePreview := true
			if lastSelectedUnit != nil && combat.selected_unit == nil && !combat.timeline_hovered{
				combat.preview_time.targetStep = combat.current_step
				combat.preview_time.initiative = -1
				easePreview = false
			}

			if lastSelectedUnit != combat.selected_unit do ui_cue("combatUnitSelection")

			combat.preview_time.displayedStep = ui_cue_map_stateful("combatPreviewStepChanged", 6, f32(combat.preview_time.targetStep), cu.easeIn, easePreview, false)
		case .resolving:

			resolveBump :: proc(using unit:^CombatUnit) -> bool{
				key := &unit.baseBase
				state:^struct{
					startPos:Vec2,
					endPos:Vec2
				}
				seq_open(&state, imkey_combine(key, loc="combat__resolveBump"))
					if seq_cue(0){
						state.startPos = stageCharacter.transform.pos 
						state.endPos = combatEntity_stage_pos(combatEntity)
					}
					if(seq_cue(0, 6)){
						transform_set(stageCharacter.transform, seq_map(state.startPos, state.endPos))
					}
					facing := vec2_cardinal(state.startPos, state.endPos)
					if stageCharacter_anim_seq(stageCharacter, setSprites={sprites.hurtToStun, sprites.stunToIdle, sprites.idle}, key=imkey_combine(key)){
						transform_set(stageCharacter.transform, state.endPos)
						return seq_close(.end)
					}
				return seq_close()
			}
			
			resolveAsync :: proc(forceResetWalkAnim:=false){
				#reverse for unit, i in combat.units_async_resolve{
					using unit

					if stunCounter == 1{
						if stageCharacter_anim_seq(stageCharacter, sprites.stunToIdle, sprites.idle, key=&unit.baseBase){
							stunCounter -= 1
							unordered_remove(&combat.units_async_resolve, i)
						}
						continue
					}
					else if stunCounter > 0 {
						if seq_wait(COMBAT_SUBSTEP_TIME, &unit.baseBase){
							stunCounter -= 1
							unordered_remove(&combat.units_async_resolve, i)
						}
						continue
					}
				
					if(len(queuedActions) > 0){
						action := &queuedActions[0]
						if action.startupCounter > 0{
							if action.startupCounter == action.action.startup{
								if stageCharacter_anim_seq(stageCharacter, sprites.idleToReady, sprites.ready, newFacing=action.aimDir){
									action.startupCounter -= 1
									unordered_remove(&combat.units_async_resolve, i)
								}
							}
							else{
								if seq_wait(COMBAT_SUBSTEP_TIME, &unit.baseBase){
									action.startupCounter -= 1
									unordered_remove(&combat.units_async_resolve, i)
								}
							}
							continue
						}
				
						if action.resolve(action) { //SHOULD JUST BE FOR MOVEMENT AND WAIT ACTIONS. todo: if async is ever used again, ensure basic actions use the "combat__" imkey?
							if action.action == ca.movement{
								if bumped{
									append(&combat.units_bumped, unit)
									bumped = false
								}
								else if (
									forceResetWalkAnim || 
									combat.current_step+1 == combat.next_planning_step || 
									len(queuedActions) == 1 ||
									queuedActions[1].action != ca.movement
								){
									stageCharacter_sprite_set(stageCharacter, unit.sprites.idle)
								}
							}
								
							stunCounter = action.cooldown
							remove(&queuedActions, 0)
							unordered_remove(&combat.units_async_resolve, i)
						}
					}
				}
			}

			resolveAction :: proc(action:^CombatActionQueued)->bool{
				user := action.user
				if seq_open("combat__resolveAction"){
					if action.nameStream do combat.resolving_action_title = combatAction_stream_name_generate(action, context.temp_allocator)
					else do combat.resolving_action_title = dialogue_line(di.combatActions, action.id)
					if seq_cue(0){
						combatActionQueued_refresh_target(action, user.combatEntity.pos)
					}
					if seq_cue(0,6){
						combat.resolving_action_title_scale = seq_map(0,1)
					}
					if seq_cue(48, 48+6){
						combat.resolving_action_title_scale = seq_map(1,0)
					}

					camFocus:CameraPanTarget
					switch action.cameraFocus{
						case .target: 		camFocus = combat_to_stage_pos(rect_center(action.targetBounds))
						case .user: 		camFocus = action.user.stageCharacter.transform.pos + CAMERA_DEFAULT_TRACKING_OFFSET
						case .userTracking: camFocus = action.user.stageCharacter.transform._ptr
					}
					camPan := camera_pan_to_seq(camFocus, 48, cu.easeIn)
					readyUpDone := true
					if action.startup == 0 do readyUpDone = stageCharacter_anim_seq(user.stageCharacter, user.sprites.idleToReady, user.sprites.ready, newFacing=action.aimDir)
					if readyUpDone && camPan{
						if seq_cue(){
							action.resolve(action)
							action.initialized = true
						}
						else if action.resolve(action){
							camera_tracking_set()
							combat.resolving_action_title_scale = 0 //failsafe
							return seq_close(.end)
						}
					}
				}
				return seq_close()
			}


			audio_parameter_set("battlePhase", 1)

			if combat.waiting_for_cutscene{
				if cutscene.enabled do break
				else do combat.waiting_for_cutscene = false
			}

			if len(combat.defer_start_anim_units) > 0{
				#reverse for unit, i in combat.defer_start_anim_units{
					if unitStartSeq(unit) do unordered_remove(&combat.defer_start_anim_units, i) 
				} 
				break
			}

			if len(combat.units_bumped) > 0{
				if resolveBump(peek(combat.units_bumped)) do pop(&combat.units_bumped)
				break
			}

			if !combat.phase_started{
				combat.phase_started = true
				combat_event_process(CombatEventResolveStarted{})
				if combat.waiting_for_cutscene do break
			}

			if(combat.resolve_head >= 0){

				waitingForAction := false

				for combat.resolve_head >= 0{
					resolveUnit := combat.resolve_queue[combat.resolve_head]
					using resolveUnit

					if combat.resolve_action.action == nil{
						if(unitState == .dead){
							ordered_remove(&combat.resolve_queue, combat.resolve_head)
							combat.resolve_head -= 1
							continue
						}

							
						if stunCounter > 0{
							if combat.resolve_async{
								append(&combat.units_async_resolve, resolveUnit)
								combat.resolve_head -= 1
								continue
							}
							else{
								if stunCounter == 1{
									if stageCharacter_anim_seq(stageCharacter, sprites.stunToIdle, sprites.idle, key=&baseBase){
										stunCounter -= 1
										combat.resolve_head -= 1
									}
								}
								else if stunCounter > 0 {
									if seq_wait(COMBAT_SUBSTEP_TIME, &baseBase){
										stunCounter -= 1
										combat.resolve_head -= 1
									}
								}
								break
							}
						}

						
						if len(queuedActions) > 0{
							action := &queuedActions[0]
							if(action.startupCounter > 0){
								if combat.resolve_async{
									append(&combat.units_async_resolve, resolveUnit)
									combat.resolve_head -= 1
									continue
								}
								else{
									if(action.startupCounter == action.action.startup){
										if stageCharacter_anim_seq(stageCharacter, sprites.idleToReady, sprites.ready, newFacing=action.aimDir){
											action.startupCounter -= 1
											combat.resolve_head -= 1
										}
									}
									else{
										if seq_wait(COMBAT_SUBSTEP_TIME, &baseBase){
											action.startupCounter -= 1	
											combat.resolve_head -= 1
										}
									}
									break
								}
							}

							if equals(action.action, ca.movement, ca.wait){
								if !action.initialized{
									prevPos := combatEntity.pos
									action.resolve(action)
									action.initialized = true
									if action.action == ca.movement && (len(queuedActions) <= 1 || queuedActions[1].action != ca.movement){
										bumped = combatUnit_bump_check(resolveUnit, vec2i_cardinal(combatEntity.pos, prevPos))
									}
								}

								if combat.resolve_async{
									append(&combat.units_async_resolve, resolveUnit)
									combat.resolve_head -= 1
									continue
								}
								else{
									if action.resolve(action) {
										if action.action == ca.movement{
											if bumped{
												append(&combat.units_bumped, resolveUnit)
												bumped = false
											}
											else do stageCharacter_sprite_set(stageCharacter, sprites.idle)
										}
											
										stunCounter = action.cooldown
										remove(&queuedActions, 0)
										combat.resolve_head -= 1
									}
									break
								}
							}

							
							combat.resolve_action = action^ //store queued action info separately in case unit breaks during action resolve
						}
					}

					if combat.resolve_action.action != nil{
						if len(combat.units_async_resolve) > 0{
							waitingForAction = true
							break
						}

						caq := &combat.resolve_action
							
						if resolveAction(caq){
							combat_event_process(CombatEventDataActionResolved{caq})
							
							if combat.end_flag{
								combat_end()
								break
							}
	
							if stunCounter == 0 do stunCounter = caq.cooldown
							if len(queuedActions) > 0 do remove(&queuedActions, 0)
							combat.resolve_head -= 1
							combat.waiting_for_cutscene = true
							combat.resolve_action = CombatActionQueued{}
	
							//bump all units that aren't moving and might be overlapping after an action 
							bumpedToCheck := make([dynamic]^CombatUnit, context.temp_allocator)

							if(unitState == .dead) do ordered_remove(&combat.resolve_queue, combat.resolve_head)
							else do append(&bumpedToCheck, resolveUnit)

							for unit in combat.resolve_queue{
								if unit.unitState == .alive && unit.combatEntity.placedInGrid && unit != resolveUnit && (unit.stunCounter >0 || len(unit.queuedActions) == 0 || unit.queuedActions[0].action != ca.movement){
									append(&bumpedToCheck, unit)
								} 
							}
							for unit in bumpedToCheck{
								if combatUnit_bump_check(unit, unit.stageCharacter.facing){
									append(&combat.units_bumped, unit)
								}
							}
						}
						break
					}
					
					combat.resolve_head -= 1
				}
				if combat.resolve_async do resolveAsync(waitingForAction)
			}
			else{
				if combat.resolve_async do resolveAsync()

				if len(combat.units_async_resolve) == 0{
					nextStep :: proc(){
						combat_event_process(CombatEventDataStepEnd{})

						combat.current_step += 1
						combat.resolve_head = len(combat.resolve_queue) - 1
					}

					if(combat.current_step == combat.next_planning_step-1){
						nextStep()
						combat.phase = .planning
						combat.phase_started = false
						combat.next_planning_step += COMBAT_RESOLVE_INTERVAL
	
						//AI planning and target refresh
						combat_refresh_all_targets()
						units := combatUnits_get()
						for unit in units do combatUnit_AI_plan_actions(unit)

						combat_event_process(CombatEventResolveEnded{})
					}
					else do nextStep()
				}
			}
		
		case .starting:
			seq_open()
			if seq_cue(0){
				audio_parameter_set("inBattle", 1)
			}
			unitsFinished := true
			units := combatUnits_get()
			for unit,i in units{
				finished := false

				deferStartAnim := unit.unitType in combat.defer_start_anim_unit_types
				if unit.skipStartAnim || deferStartAnim{
					if deferStartAnim && !contains(combat.defer_start_anim_units, unit) do append(&combat.defer_start_anim_units, unit)
					if !unit.combatEntity.placedInGrid do combatEntity_place(unit.combatEntity)
					finished = true
				}
				else{
					if(combatUnit_move_sequence(unit, unit.combatEntity.pos, unit.stageCharacter.sprites.walk, 1.5, false)){
						finished = unitStartSeq(unit)
					}
				}
				if !finished do unitsFinished = false
			}
			if unitsFinished/*&& transition_seq(duration=60, kind=.combatStart)*/{
				combat.phase = .planning
				seq_close(.end)
				for unit in units{
					combatUnit_AI_plan_actions(unit)
				}

				if combat.time_stop_force_disable{
					for unit in units{
						if unit.unitType == .player do combat_grid_ripple(unit.stageCharacter.transform.pos)
					}
					audio_play(au.combatGridRipple)
				}
			}
			else do seq_close()
		case .ending:
			seq_open()
			if seq_cue(0){
				audio_parameter_set("inBattle", 0)
			}
			if !timestop_end_seq(){
				seq_close()
				break
			}
			unitsFinished := true
			units := combatUnits_get()
			for unit,i in units{
				if unit.skipEndAnim do continue
				newFacing := unit.stageCharacter.facing
				if(!equals(newFacing, Dir.left, Dir.right)) do newFacing = .right
				setSprites := make([dynamic]DirSprite, context.temp_allocator)
				if unit.unitState == .knockedOut do append(&setSprites, unit.sprites.koGetup)
				else if unit.stunCounter > 0 do append(&setSprites, unit.sprites.stunToIdle)
				append(&setSprites, unit.sprites.combatEnd)
				append(&setSprites, nil)
				if !stageCharacter_anim_seq(unit.stageCharacter, setSprites=setSprites[:], newFacing=newFacing, key=imkey_combine(i)) do unitsFinished = false
			}

			if player,ok := cofind(Player, 0); ok{
				followers := coall(PlayerFollower)
				for &follower in followers{
					targetPos := player.followerPos+follower.followOffset
					if follower.runFromCombat && !scmove(follower.stageCharacter, {targetPos}, player.maxRunSpeed, moveSprite=follower.stageCharacter.sprites.dash) do unitsFinished = false
				}

				if combat.reset_camera_on_end && !camera_pan_to_seq(player.stageCharacter) do unitsFinished = false
			}

			if(unitsFinished){
				if combat.music_override != nil do music_set(combat._music_overrided)
				combat_event_process(CombatEventEnded{})
				combat_state_clear()
				seq_close(.end)
			}
			else do seq_close()
		case .disabled:
	}

	if equals(combat.phase, CombatPhase.starting, CombatPhase.planning){
		#reverse for &ripple, i in combat.grid_ripples{
			ripple.radii += {8,4}
			if ripple.radii.y - COMBAT_RIPPLE_THICKNESS.y > max(stage.bounds.size){
				unordered_remove(&combat.grid_ripples, i)
			}
		}
	}
	else do clear(&combat.grid_ripples)

	if combat.phase != .disabled{
		_combat_timeline_update()
		combat_event_process(CombatEventUpdate{})

		_combat_timestop_update_stage_entities()
	}
}