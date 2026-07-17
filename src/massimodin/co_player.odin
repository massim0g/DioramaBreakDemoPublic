#+feature using-stmt
package massimodin //@nested-tags:_components/

Player :: struct{
    using base:RenderComponentBase,
	spriter:CoRef(Spriter),
	transform:CoRef(Transform),
	mover:CoRef(Mover),
	collider:CoRef(Collider),
	stageEntity:CoRef(StageEntity),
	stageCharacter:CoRef(StageCharacter),
	combatUnit:CoRef(CombatUnit),
	speed:f32,
	maxWalkSpeed:f32,
	maxRunSpeed:f32,
	dashToggled:bool,
	aclTime:f32,
	followerDistance:f32,
	followerPos:Vec2, //position around which followers place themselves
	spawnFollowers:bool,
	hasDashed:bool,
	facingBlockedFrames:int
}

PLAYER_COLLISION_BLACKLIST :: ColliderGroupMask{.pcs, .nonSolidInteractables}

//returns true if the player does not have control over the player character
player_dummy :: proc() -> bool{
	return combat.phase != .disabled || 
	debug_free_cam_enabled() || 
	cutscene.enabled || 
	entity_exists(PauseMenu) ||
	entity_exists(TextEntry) ||
	entity_exists(RestMenu) ||
	entity_exists(PivotalChoice)
}

player_spawn_followers :: proc(self:^Player=nil){
	self := self
	if self == nil do self = cofind(Player, 0)
	using self

	if !spawnFollowers do return
	followerPos = transform.pos - cardinal_to_vec2(stageCharacter.facing)*followerDistance
	for id in save.player_follower_ids{
		follower := entity_make(PlayerFollower)
		estring_set(&follower.stageCharacter.initID, id)
		stageCharacter_reload(follower.stageCharacter)
		follower.transform.pos = followerPos + follower.followOffset
		scface(follower.stageCharacter, stageCharacter.facing)
		if pcid,ok := player_character_string_to_id(id); !ok || !save.characters[pcid].inParty do follower.runFromCombat = true
	}
}

blade_swap_seq :: proc(newBlade:ItemRef) -> bool{
	if seq_open(){
		dur := sprite_duration(sp.pro_blade_swap_anim) + BOX_POPUP_TIME_DEFAULT*2
		if seq_cue(dur/2) do player_character_equip(.pro, newBlade)

		if seq_time() >= dur{
			return seq_close(.end)
		}
		else {
			palInd := item_ref_get(newBlade).paletteIndex
			seq_draw(callback_make(proc(palInd:^f32){
				pro := scfind("pro", true)
				if pro == nil do return
				
				dur := sprite_duration(sp.pro_blade_swap_anim) + BOX_POPUP_TIME_DEFAULT*2

				drawSize := Vec2{40, 40}
				drawRect := Rect{0, drawSize}
				t:=1
				if seq_cue(t) do audio_play(au.uiBoxOpen)
				if seq_cue(t, BOX_POPUP_TIME_DEFAULT) do drawRect.size *= box_popup_scale(seq_time()-t)
				t=dur-BOX_POPUP_TIME_DEFAULT+1
				if seq_cue(t, dur) do drawRect.size *= box_popup_scale(seq_time()-t, reverse=true)

				if seq_cue(BOX_POPUP_TIME_DEFAULT + int(sprite_frame_time_get(sp.pro_blade_swap_anim, 3))) do audio_play(au.equipClick)
				
				rect_align(&drawRect, scpos(pro) - {0, drawSize.y/2}, 0)
				drawRect.pos = round(drawRect.pos)
				rect_resize_in_place(&drawRect, 1)
				nineslice_draw(sp.menuBoxOutlined, drawRect)
				rect_resize_in_place(&drawRect, -1)

				pro_blade_pal_swap_set(palInd^)
				partRect := drawRect
				rect_align(&partRect, sprite_origin(sp.pro_blade_swap_anim), 0)
				partRect.pos = ceil(partRect.pos)
				sprite_draw_part(sp.pro_blade_swap_anim, drawRect.pos, partRect, sprite_frame_get(
					sp.pro_blade_swap_anim, f32(seq_time()-BOX_POPUP_TIME_DEFAULT), true
				))
				shader_reset()
			}, palInd), useStageCameraPos=true)
		}
	}
	return seq_close()
}

_player_process_event :: proc(base:^ComponentBase, event:Event, overrideDisabled:=false){
if(!overrideDisabled && event in base.disabledEvents) do return
last_context := entities.context_component
defer cowith(last_context)
cowith(base)
self := cast(^Player)base
using self
#partial switch event{
case .init:
    coadd(&spriter)
	coadd(&transform)
	coadd(&mover)
	coadd(&collider)
	coadd(&stageEntity)
	coadd(&stageCharacter)
	coadd(&combatUnit)

	maxWalkSpeed = 2
	maxRunSpeed = 4
	aclTime = 20
	followerDistance = 48

	collider.collisionGroups = {.pcs}
	stageEntity.identifyingComponentIndex = myEntityIndex
	stageEntity.shadowKind = .dropShadowEllipse
	stageEntity.dropShadowRadii.y = 3
	combatUnit.combatEntity.size = {3,3}
	//combatUnit.actionPreviewPinned = true
	
	estring_set(&stageCharacter.initID, "pro")
	combatUnit.unitType = .player
	combatUnit.forceCombatGridEntry = true
	stageCharacter_reload(stageCharacter)

	spawnFollowers = true

case .justMade: 
	player_spawn_followers(self)
case .stageStart: 
	if hasDashed do flag("playerHasDashed")
	proc_call_delayed(proc(){player_spawn_followers()}, 2) //extra delay due to warp positioning also being delayed

case .loaded:
	transform_set(transform, transform.pos) //update collider position

case .update: //@p 64
	if player_dummy(){
		stageCharacter.overrideFacing = .none
		mover_zero(mover)
		if follower,ok := cofind(PlayerFollower, 0); ok{
			followerPos = follower.transform.pos - follower.followOffset
		}
		break //kinda hacky
	}

	//pause
	if ginputs[.cancel] || ginputs[.start]{
		entity_make(PauseMenu)
		break
	}
	
	//input
	moveDir, animMoveDir:Vec2
	switch input_device(){
		case .keyboard:
			moveDir = {
				f32(int(ginputs[.rightHeld]) - int(ginputs[.leftHeld])),
				f32(int(ginputs[.downHeld]) - int(ginputs[.upHeld]))
			}
			animMoveDir = moveDir
		case .gamepad:
			moveDir = maxabs(input_gamepad_directional_axes(.lStick), input_gamepad_directional_axes(.dpad))
			animMoveDir = sign(moveDir)
			if abs(moveDir.x) <= GAMEPAD_DEFAULT_DEADZONE do animMoveDir.x = 0
			if abs(moveDir.y) <= GAMEPAD_DEFAULT_DEADZONE do animMoveDir.y = 0
	}

	// collided, ok := collision_component(collider, transform.pos.x + moveDir.x, transform.pos.y + moveDir.y, StageInteractable)
	// if ok do print(collided.stageEntity.spriter.mySprite.name)

	//movement
	dashing := false
	if !stage.indoors{
		switch settings.dash_mode{
			case .hold: dashing = ginputs[.optionHeld]
			case .toggle: 
				if ginputs[.option] do dashToggled = !dashToggled
				dashing = dashToggled
			case .onByDefault: dashing = !ginputs[.optionHeld]
		}
	}

	if dashing do hasDashed = true

	maxSpeed := dashing ? maxRunSpeed : maxWalkSpeed
	acl := maxSpeed/aclTime
	dcl := stage.indoors ? acl : maxRunSpeed/aclTime
	if(moveDir != 0){
		speed = approach(speed, maxSpeed, acl)
		moveDir = vec2_normalize(moveDir)
	}
	else{
		speed = approach(speed, 0, dcl)
		moveDir = vec2_normalize(mover.speed.xy)
	}
	mover.speed.xy = speed*moveDir
	stageCharacter.dashing = dashing && speed == maxSpeed

	mover_update_pre_collision(mover)
	mover_collide(mover, collider, &transform.pos, PLAYER_COLLISION_BLACKLIST)
	
	mover_apply(mover)

	truePos := transform.pos + mover.fractionalSpeed.xy
	followDist := vec2_distance(followerPos, truePos)
	followDist = min(followDist, followerDistance)
	followerPos = truePos + vec2_dir(followerPos, truePos)*followDist

	// Facing behaviour
	// Sticky: keep current facing if its axis is still pressed. 
	// Break stickiness after the faced axis has been consistently blocked for a few frames (avoids flicker on uneven walls but still redirects on flat walls).
	if animMoveDir != 0 {
		facingVec := cardinal_to_vec2(stageCharacter.overrideFacing)
		stillPressed := (facingVec.x != 0 && facingVec.x == animMoveDir.x) || (facingVec.y != 0 && facingVec.y == animMoveDir.y)
		
		if stillPressed {
			facingBlocked := (facingVec.x != 0 && mover.collided.x) || (facingVec.y != 0 && mover.collided.y)
			otherAxisFree := (facingVec.x != 0 && animMoveDir.y != 0 && !mover.collided.y) || (facingVec.y != 0 && animMoveDir.x != 0 && !mover.collided.x)
			if facingBlocked && otherAxisFree{
				facingBlockedFrames += 1
				if facingBlockedFrames >= 3 do stillPressed = false
			}
			else do facingBlockedFrames = 0
		}
		else do facingBlockedFrames = 0

		if !stillPressed {
			if facingVec.x != 0 && facingVec.x == -animMoveDir.x do stageCharacter.overrideFacing = animMoveDir.x > 0 ? .right : .left
			else if facingVec.y != 0 && facingVec.y == -animMoveDir.y do stageCharacter.overrideFacing = animMoveDir.y > 0 ? .down : .up
			else if animMoveDir.x != 0 && !mover.collided.x && (animMoveDir.y == 0 || mover.collided.y) do stageCharacter.overrideFacing = animMoveDir.x > 0 ? .right : .left
			else if animMoveDir.y != 0 && !mover.collided.y && (animMoveDir.x == 0 || mover.collided.x) do stageCharacter.overrideFacing = animMoveDir.y > 0 ? .down : .up
			else do stageCharacter.overrideFacing = vec2_cardinal(animMoveDir)
		}
	}
	else do facingBlockedFrames = 0

	camera_tracking_set(transform)

	//interacting with the stage
	if ginputs[.confirm] {
		interactRange :: 24
		interactRect:Rect
		interactRect.size = {interactRange, interactRange}
		switch stageCharacter.facing{
			case .right: 
				interactRect.pos.x = rect_get_right(collider.bounds) + 1
				interactRect.pos.y = rect_center(collider.bounds).y - interactRange/2
			case .up:
				interactRect.pos.x = rect_center(collider.bounds).x - interactRange/2
				interactRect.pos.y = collider.bounds.pos.y - interactRange
			case .left: 
				interactRect.pos.x = collider.bounds.pos.x - interactRange
				interactRect.pos.y = rect_center(collider.bounds).y - interactRange/2
			case .down: 
				interactRect.pos.x = rect_center(collider.bounds).x - interactRange/2
				interactRect.pos.y = rect_get_bottom(collider.bounds)
			case .none: //do nothing
		}

		foundInteractables := collision_components(interactRect, StageInteractable)

		//sort found interactables by distance (from collider center) to player
		sort(foundInteractables, proc(a,b:^StageInteractable)->bool{
			playerPos := cocontext(Player).transform.pos
			distA := vec2_distance(playerPos, rect_center(a.collider.bounds))
			distB := vec2_distance(playerPos, rect_center(b.collider.bounds))
			return distA < distB
		})

		for inter in foundInteractables{
			if inter.interactDir != .none && !equals(stageCharacter.facing, inter.interactDir, inter.interactDirB) do continue
			if inter.interactDialogue == nil{
				if inter.collectableItem != nil{
					stageEntity_persistent_data(inter.stageEntity).interactCount += 1
					inventory_add(inter.collectableItem)
					popup_make_item_collect(inter.collectableItem)
					entity_destroy(inter)
					break
				}
				continue
			} 
			pData := stageEntity_persistent_data(inter.stageEntity)
			if inter.maxInteractions < 0 || pData.interactCount < inter.maxInteractions{
				mover_zero(mover)
				pData.interactCount += 1
				flag("interactCount", int_to_string(pData.interactCount, context.temp_allocator))
				dialogue_open(inter.interactDialogue, inter.interactDialogueLabel.s)

				if character,ok := cofind(inter, StageCharacter); ok && character.facePlayer == .ifInteractedWith{
					mover_zero(character.mover) //todo: specific flag for zeroing out movement if interacted with?
					stageCharacter_facing_set(character, vec2_cardinal(transform.pos, character.transform.pos))
				}
				break
			} 
		}
	}

	//stage warps
	if warp, ok := collision_component(collider, Warp); ok{
		if (warp.enableFlag.s == "" || flag_check(warp.enableFlag.s)) && (warp.disableFlag.s == "" || !flag_check(warp.disableFlag.s)){
			stage_warp(warp.targetStage, stageCharacter, warp.targetPos)
		}
	}
}}
    