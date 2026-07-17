#+feature using-stmt
package massimodin //@nested-tags:combat/actions

import "base:runtime"
CombatBasicActionIDs :: struct{
	wait:^CombatAction,
	movement:^CombatAction,
	testAttack:^CombatAction,
}
ca:^CombatBasicActionIDs

AudioCue :: struct{
	event:AudioEvent,
	spriteFrame:int
}

//audio frame defaults to hit frame
combat_actions_basic_attack_sequence :: proc(caq:^CombatActionQueued, attackSprite:DirSprite, hitFrame:int, audioEvent:AudioEvent, audioFrame:=-1) -> bool{
	return combat_actions_basic_attack_sequence_ex(caq, attackSprite, hitFrame, {{audioEvent, audioFrame>=0?audioFrame:hitFrame}}, nil)
}
combat_actions_basic_attack_sequence_ex :: proc(using caq:^CombatActionQueued, attackSprite:DirSprite, hitFrame:int, audioCues:[]AudioCue, onHit:proc(target:CombatTarget)=nil) -> bool{
	if seq_open("combat__basic_attack"){
		if seq_cue(0){
			setSprites := make([dynamic]DirSprite, 0, 3,context.temp_allocator)
			append(&setSprites, attackSprite)
			if action.cooldown > 0{
				append(&setSprites, user.sprites.actionToStun)
				append(&setSprites, user.sprites.stun)
			}
			else{
				append(&setSprites, user.sprites.actionToIdle)
				append(&setSprites, user.sprites.idle)
			}
			stageCharacter_sprite_set(user.stageCharacter, setSprites=setSprites[:])
		}
		
		spr:^Sprite
		switch s in attackSprite{
			case DirSpriteSet: spr = dirSprite_get(s, user.stageCharacter.facing)
			case ^Sprite: spr = s
		}

		for ac in audioCues{
			if seq_cue(int(sprite_frame_time_get(spr, ac.spriteFrame))) do audio_play(ac.event)
		}

		if hitFrame >= 0 && seq_time() > int(sprite_frame_time_get(spr, hitFrame)){
			combat_target_damage_seq(target, action.damage, action.hitstun, action.damageKind, user)
			if onHit != nil do onHit(target)
		}

		userSprite := stageCharacter_sprite_get(user.stageCharacter)
		if userSprite == (action.cooldown > 0 ? user.sprites.stun : user.sprites.idle){
			if userSprite == user.sprites.stun{
				#partial switch user.stageCharacter.facing{case .up, .down: 
					if nearest := combatUnit_nearest(rect_center(user.combatEntity.rect), combat.current_step, ~CombatUnitTypes{user.unitType}); nearest != nil{
						scface(user.stageCharacter, nearest.stageCharacter.transform.pos.x < user.stageCharacter.transform.pos.x?.left:.right)
					}
					else do scface(user.stageCharacter, .right)
				}
			}
			return seq_close(.end)
		}
	}
	return seq_close()
}
combat_actions_basic_ranged_attack_sequence :: proc(using caq:^CombatActionQueued, attackSprite:DirSprite, projectileSprite:^Sprite, projectileSpawnDelay:f32, hitFrame:int, userAudio:AudioCue, projectileAudio:AudioCue, onHit:proc(target:CombatTarget)=nil) -> bool{
	if seq_open("combat__basic_ranged_attack"){
		spawnDelay := int(projectileSpawnDelay)
		if seq_cue(spawnDelay){
			angle:f32=0
			scale:=Vec2{1,1}
			if aimKind == .directionalRanged{
				switch aimDir{
					case .left, .right: scale = {1,0.5}
					case .up, .down: scale = {0.5,1}
					case .none: unreachable()
				}
				angle = cardinal_to_angle(aimDir)
			}
			spriteEffect_make(projectileSprite, combat_to_stage_pos(lastValidAimPos), scale=scale, angle=angle)
		}

		if seq_cue(spawnDelay + int(sprite_frame_time_get(projectileSprite, projectileAudio.spriteFrame))) do audio_play(projectileAudio.event)
		
		if hitFrame >= 0 && seq_time() > spawnDelay + int(sprite_frame_time_get(projectileSprite, hitFrame)){
			combat_target_damage_seq(target, action.damage, action.hitstun, action.damageKind, user)
			if onHit != nil do onHit(target)
		}
		
		if combat_actions_basic_attack_sequence_ex(caq, attackSprite, -1, {userAudio}, nil) &&
			seq_time()>spawnDelay &&
			spriteEffect_find(projectileSprite, true)==nil
		{
			return seq_close(.end)
		}
	}
	return seq_close()
}

//Does a cheap imitation of pathfinding with no collision to simulate one step of movement between point a and b at a given speed.
combat_movement_step_simulate :: proc(startPos,finalPos:Vec2i, userWalkSpeed:int) -> Vec2i{
	pathPos := finalPos
	if vec2_manhattan_distance(startPos, finalPos) > userWalkSpeed{
		pathPos = startPos
		for n in 0..<userWalkSpeed{ //sort of overwrought, but done this way to match how pathfinding works 
			moveSign := sign(finalPos - pathPos)
			if moveSign.x == 0 || moveSign.y == 0 do pathPos += moveSign
			else if n%2 == 0{
				if moveSign.y == 1 do pathPos.y+=1
				else if moveSign.x == -1 do pathPos.x-=1
				else do pathPos.y-=1
			}
			else{
				if moveSign.x == 1 do pathPos.x+=1
				else if moveSign.y == -1 do pathPos.y-=1
				else do pathPos.x-=1
			}
		}
	}
	return pathPos
}

_combat_actions_reload_basic :: proc(){
	combat.actions["wait"] = CombatAction{
		kind=.basic,
		aimKind=.user,
		resolve = proc(using caq:^CombatActionQueued) -> bool{ return seq_wait(COMBAT_SUBSTEP_TIME, imkey_combine(&user.baseBase, "combat__wait")) }
	}

	combat.actions["movement"] = CombatAction{
		kind = .basic,
		aimKind = .freeAimCornered,
		resolve = proc(using caq:^CombatActionQueued) -> bool{
			state:^struct{movePos:Vec2i}
			combatActionQueued_state_get(caq, &state)
			if(!initialized){
				path := combat_pathfind(user.combatEntity, Recti{target.(Vec2i), {1,1}}, true)
				pathInd := min(len(path)-1, user.walkSpeed)
				state.movePos = path[pathInd]
			}
			return combatUnit_move_sequence(user, state.movePos, user.sprites.walk)
		},
		updateGhostPosition = proc(caq:^CombatActionQueued, ghostPos:^Vec2i){
			ghostPos^ = combat_movement_step_simulate(ghostPos^, caq.target.(Vec2i), caq.user.walkSpeed)
		}
	}

	combat.actions["testAttack"] = CombatAction{
		startup=2,
		cooldown=3,
		damage=3,
		hitstun=2,
		kind = .attack,
		aimKind = .directional,
		actionSelectIcon = sp.testAttackIcon,
		targetMask = sp.testAttackMask,
		resolve = proc(caq:^CombatActionQueued) -> bool{
			return combat_actions_basic_attack_sequence(caq, sp.pro_combatAction_side_BasicAttackA, 7, au.pro_combatAction_BasicAttackA)
		}
	}
}