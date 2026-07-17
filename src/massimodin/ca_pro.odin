#+feature using-stmt
package massimodin //@nested-tags:combat/actions

_combat_actions_reload_pro :: proc(){
	combat.actions["woodenSwing"] = CombatAction{
		startup=3,
		cooldown=1,
		damage=2,
		hitstun=3,
		kind=.attack,
		aimKind=.directional,
		actionSelectIcon = sp.combatActionIcons_dullSwing,
		targetMask = sp.proAttackMask_woodenSwing,
		resolve = proc(caq:^CombatActionQueued) -> bool{
			return combat_actions_basic_attack_sequence(caq, dirSpriteSet_find("pro_combatAction_%s_BasicAttackA"), 6, au.pro_combatAction_BasicAttackA)
		}
	}
	combat.actions["swing"] = CombatAction{
		startup=3,
		cooldown=2,
		damage=4,
		hitstun=3,
		kind=.attack,
		aimKind=.directional,
		actionSelectIcon = sp.combatActionIcons_swordSwing,
		targetMask = sp.proAttackMask_swing,
		resolve = proc(caq:^CombatActionQueued) -> bool{
			return combat_actions_basic_attack_sequence(caq, dirSpriteSet_find("pro_combatAction_%s_BasicAttackA"), 6, au.pro_combatAction_BasicAttackA)
		}
	}
	combat.actions["thrust"] = CombatAction{
		startup=2,
		cooldown=1,
		damage=2,
		hitstun=2,
		kind=.attack,
		aimKind=.directional,
		actionSelectIcon = sp.combatActionIcons_swordThrust,
		targetMask = sp.proAttackMask_thrust,
		resolve = proc(caq:^CombatActionQueued) -> bool{
			return combat_actions_basic_attack_sequence(caq, dirSpriteSet_find("pro_combatAction_%s_BasicAttackB"), 5, au.pro_combatAction_BasicAttackB)
		}
	}
	combat.actions["guard"] = CombatAction{
		startup=0,
		cooldown=0,
		kind=.defense,
		aimKind=.user,
		actionSelectIcon = sp.combatActionIcons_defend,
		resolve = proc(using caq:^CombatActionQueued) -> bool{
			if stageCharacter_anim_seq(user.stageCharacter, sp.pro_combat_guard_side, newFacing=Dir.right, key="combat__guard"){
				combat_event_callback_add(proc(self:^CombatEventCallback, event:CombatEventData){
					if e,ok:=event.(CombatEventDataHit); ok && e.target == self.attachedTo{
						e.damage^ = max(e.damage^-3, 0)
					}
				}, user, 1)
				return true
			}
			return false
		}
	}
	combat.actions["dodge"] = CombatAction{
		startup=0,
		cooldown=6,
		kind=.evasion,
		aimKind=.freeAimCornered,
		aimRange=6,
		actionSelectIcon = sp.combatActionIcons_roll,
		targetMask=Vec2i{3,3},
		resolve = proc(using caq:^CombatActionQueued) -> bool{
			startPos:^Vec2i
			if seq_open(&startPos, "combat__dodge"){
				finalPos := target.([]Vec2i)[0]

				if seq_cue(0){
					stageCharacter_sprite_set(user.stageCharacter, sp.pro_combatAction_side_Dodge, user.sprites.actionToStun, user.sprites.stun)
					startPos^ = user.combatEntity.pos
					scface(user.stageCharacter, startPos.x > finalPos.x ? .left : .right)
				}

				dodgeStart := floor(sprite_frame_time_get(sp.pro_combatAction_side_DashAttack, 3))
				dodgeEnd := floor(sprite_frame_time_get(sp.pro_combatAction_side_DashAttack, 12))

				if seq_cue(dodgeStart, dodgeEnd){
					transform_set(user.stageCharacter.transform, seq_map(combatEntity_stage_pos(user.combatEntity, startPos^), combatEntity_stage_pos(user.combatEntity, finalPos)))
				}

				if seq_cue(dodgeEnd){
					#partial switch user.stageCharacter.facing{case .up, .down: scface(user.stageCharacter, .right)}
					combatEntity_move(user.combatEntity, finalPos)
				}

				if stageCharacter_sprite_get(user.stageCharacter) == user.sprites.stun{
					return seq_close(.end)
				}
			}
			return seq_close()
		},
		updateGhostPosition = proc(using caq:^CombatActionQueued, ghostPos:^Vec2i){
			ghostPos^ = target.([]Vec2i)[0]
		}
	}
	combat.actions["dash"] = CombatAction{
		startup=1,
		cooldown=0,
		kind=.evasion,
		aimKind=.directionalRanged,
		aimRange=9,
		actionSelectIcon = sp.combatActionIcons_dash,
		targetMask=Vec2i{3,3},
		resolve = proc(using caq:^CombatActionQueued) -> bool{
			startPos:^Vec2i
			if seq_open(&startPos, "combat__dash"){
				if seq_cue(0) do startPos^ = user.combatEntity.pos
				checkRect := Recti{startPos^, user.combatEntity.size}
				targetPos := checkRect.pos
				for targetPos != targetBounds.pos{
					checkRect.pos.x = approach(checkRect.pos.x, targetBounds.pos.x, 1)
					checkRect.pos.y = approach(checkRect.pos.y, targetBounds.pos.y, 1)
					if combat_collision_static(checkRect) || len(combat_collision_unit(checkRect, ignore=user))>0 do break
					targetPos = checkRect.pos
				}
				if combatUnit_move_sequence(user, targetPos, dirSpriteSet_find("pro_combat_dash_%s"), 3.){
					if targetPos != targetBounds.pos{
						if seq_cue() do combatUnit_damage(user, 0, 1, attacker=user)
						if scanim(user.stageCharacter, user.sprites.hurtToStun, user.sprites.stun) do return seq_close(.end)
					}
					else{
						stageCharacter_sprite_set_dirSprite(user.stageCharacter, user.sprites.idle)
						return seq_close(.end)
					}
				}
			}
			return seq_close()
		},
		updateGhostPosition = proc(using caq:^CombatActionQueued, ghostPos:^Vec2i){
			ghostPos^ = targetBounds.pos
		}
	}

	combat.actions["dashAttack"] = CombatAction{
		startup=3,
		cooldown=2,
		damage=3,
		damageKind=.air,
		hitstun=2,
		kind=.attack,
		aimKind=.directional,
		actionSelectIcon = sp.combatActionIcons_dashAttack,
		targetMask = sp.proAttackMask_dashAttack,
		resolve = proc(using caq:^CombatActionQueued) -> bool{
			startPos:^Vec2i
			if seq_open(&startPos, "combat__dashAttack"){
				if seq_cue(0){
					stageCharacter_sprite_set(user.stageCharacter, dirSpriteSet_find("pro_combatAction_%s_DashAttack"), user.sprites.actionToStun, user.sprites.stun)
					startPos^ = user.combatEntity.pos
				}
				finalPos := startPos^ + cardinal_to_vec2i(aimDir)*6	

				dashStart := floor(sprite_frame_time_get(sp.pro_combatAction_side_DashAttack, 6))
				dashEnd := floor(sprite_frame_time_get(sp.pro_combatAction_side_DashAttack, 13))
				attackFrame := int(sprite_frame_time_get(sp.pro_combatAction_side_DashAttack, 7))

				if seq_cue(dashStart, dashEnd){
					transform_set(user.stageCharacter.transform, seq_map(combatEntity_stage_pos(user.combatEntity, startPos^), combatEntity_stage_pos(user.combatEntity, finalPos), cu.popIn))
				}

				if seq_cue(dashEnd){
					combatEntity_move(user.combatEntity, finalPos)
				}

				if seq_time() >= attackFrame{
					combat_target_damage_seq(target, action.damage, action.hitstun, action.damageKind, user)
				}

				if stageCharacter_sprite_get(user.stageCharacter) == user.sprites.stun{
					#partial switch user.stageCharacter.facing{case .up, .down: scface(user.stageCharacter, .right)}
					return seq_close(.end)
				}
			}
			return seq_close()
		}
	}

	combat.actions["airyThrust"] = CombatAction{
		startup=3,
		cooldown=1,
		damage=6,
		damageKind=.air,
		hitstun=2,
		kind=.attack,
		aimKind=.directionalRanged,
		aimRange=5,
		actionSelectIcon = sp.combatActionIcons_windyThrust,
		targetMask = sp.proAttackMask_airyThrust,
		resolve = proc(caq:^CombatActionQueued) -> bool{
			//todo
			return true
		}
	}

	combat.actions["spinAttack"] = CombatAction{
		startup=1,
		cooldown=4,
		damage=1,
		hitstun=0,
		kind=.attack,
		aimKind=.noAim,
		actionSelectIcon = sp.combatActionIcons_spinAttack,
		targetMask = 3,
		resolve = proc(caq:^CombatActionQueued) -> bool{
			return combat_actions_basic_attack_sequence_ex(caq, sp.pro_combatAction_side_AreaofEffectAttack, 8, {{au.kion_combatAction, 0}}, proc(target:CombatTarget){
				//todo: push units back
			})

		}
	}
}