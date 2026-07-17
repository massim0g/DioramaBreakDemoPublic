#+feature using-stmt
package massimodin //@nested-tags:combat/

import "core:reflect"
_combat_unit_inits_reload :: proc(){
	inits := &combat.unit_inits
	init(inits, assets.allocator)

	setSingleAttack :: proc(unit:^CombatUnit){
		set(&unit.equippedActions, &combat.actions[format("%sAttack", unit.initID)])
	}

	//Player characters
		loadPC :: proc(using self:^CombatUnit){
			id, _ := reflect.enum_from_name(PlayerCharacterID, initID.s)
			info := player_character_info(id)
			maxHp = info.maxHp
			walkSpeed = info.move
			defense = info.defense

			hp = save.characters[id].hp
			unitType = save.characters[id].inParty ? .player : .ally
			initiative = u8(id)
		}
		inits["pro"] = loadPC
		inits["minima"] = loadPC
	
	//Stroma Guards
		inits["trainingDummy"] = proc(using self:^CombatUnit){
			maxHp = 10
			walkSpeed = 0
			spritesSlice :[]^Sprite = (cast([^]^Sprite)(&sprites))[:size_of(CombatUnitSpriteSet)/size_of(^Sprite)]
			for &spr in spritesSlice{
				spr = sp.trainingDummy
			}
			sprites.koStart = sp.nil_
			sprites.koGetup = sp.nil_
			sprites.hurt = sp.trainingDummy_combat_hurt
			sprites.timelinePortrait = sp.trainingDummy_timelinePortrait
		}

		combat.actions["polemaKneeAttack"] = {
			startup=1,
			cooldown=0,
			damage=1,
			hitstun=2,
			kind = .attack,
			aimKind = .directional,
			targetMask = sp.polemaAttackMask_kneeAttack,
			resolve = proc(caq:^CombatActionQueued) -> bool{
				return combat_actions_basic_attack_sequence(caq, dirSpriteSet_find("polema_combatAction_%s_KneeAttack"), 4, au.polema_combatAction_KneeAttack)
			}
		}
		combat.actions["polemaSwordAttack"] = {
			startup=2,
			cooldown=3,
			damage=4,
			hitstun=3,
			kind = .attack,
			aimKind = .directional,
			targetMask = sp.polemaAttackMask_swordAttack,
			resolve = proc(caq:^CombatActionQueued) -> bool{
				return combat_actions_basic_attack_sequence(caq, dirSpriteSet_find("polema_combatAction_%s_SwordAttackA"), 14, au.polema_combatAction_SwordAttackA, 0)
			}
		}
		inits["polema"] = proc(using self:^CombatUnit){
			maxHp = 12//6
			//defense[.physical] = 2
			reactionTime = 3 //drops to 2 in second phase
			reactAfterBreak = !flag_check("combatTutorialFailed")
			set(&equippedActions,
				&combat.actions["polemaKneeAttack"],
				&combat.actions["polemaSwordAttack"],
			)

			combatUnit_combo_add(self, &combat.actions["polemaKneeAttack"], &combat.actions["polemaSwordAttack"])
		}

		combat.actions["akroAttack"] = {
			startup=0,
			cooldown=2,
			damage=2,
			hitstun=2,
			kind = .attack,
			aimKind = .directional,
			targetMask = sp.guardAttackMask_akro,
			resolve = proc(caq:^CombatActionQueued) -> bool{
				return combat_actions_basic_attack_sequence_ex(caq, dirSpriteSet_find("akro_combatAction_%s"), 3, {{au.akro_combatAction, 1}, {au.akro_combatActionEnd,6}})
			}
		}
		inits["akro"] = proc(using self:^CombatUnit){
			maxHp = 9//7
			//defense[.physical] = 1
			setSingleAttack(self)
			initiative = 0
		}

		inits["chion"] = proc(using self:^CombatUnit){
			maxHp = 5
			initiative = 2
		}

		combat.actions["kionAttack"] = {
			startup=1,
			cooldown=4,
			damage=1,
			hitstun=2,
			kind = .attack,
			aimKind = .directional,
			targetMask = sp.guardAttackMask_kion,
			resolve = proc(caq:^CombatActionQueued) -> bool{
				return combat_actions_basic_attack_sequence(caq, dirSpriteSet_find("kion_combatAction_%s"), 4, au.kion_combatAction, 3)
			}
		}
		inits["kion"] = proc(using self:^CombatUnit){
			maxHp = 5
			initiative = 1
			setSingleAttack(self)
		}

	
	//iris enemies
		combat.actions["rangerAttack"] = {
			nameStream=true,
			startup=2,
			cooldown=4,
			damage=3,
			hitstun=4,
			aimRange=7,
			kind = .attack,
			aimKind = .freeAim,
			targetMask = sp.irisMonsterAttackMask_ranger,
			resolve = proc(using caq:^CombatActionQueued) -> bool{
				if seq_open("combat__rangerAttack"){
					projectileStartPos:=Vec3{0,1,-56}
					projectileStartPos.xy += user.stageCharacter.transform.pos
					projectileFinalPos:Vec3
					projectileFinalPos.xy = combat_to_stage_pos(rect_center(targetBounds))
					projectileHighestPos := Vec3{0,0,-200}
					projectileHighestPos.xy = lerp(projectileStartPos.xy, projectileFinalPos.xy, 0.5)

					if seq_cue(0){
						stageCharacter_sprite_set(user.stageCharacter, sp.ranger_combatAction, user.sprites.stun)
						spriteEffect_make(sp.ranger_projectile, projectileStartPos.xy, projectileStartPos.z, INF)

						audio_play(au.rangerSpit)
					}

					t:=60
					if seq_cue(0, t){
						
						proj := spriteEffect_find(sp.ranger_projectile)
						proj.transform.coords = transmute(TransformCoords)arc_projectile_pos(projectileStartPos, projectileHighestPos, projectileFinalPos, seq_map(0,1))
						proj.transform.angle = seq_map(0, 360*4)
						if seq_cue(t){
							audio_play(au.rangerPellet)
							entity_destroy(proj)
							spriteEffect_make(sp.flashBurst, projectileFinalPos.xy, projectileFinalPos.z, scale=0.25)
						}
					}

					t += 24

					if seq_cue(t){
						audio_play(au.rangerExplode)
						for pos,i in target.([]Vec2i){
							if i%2 == 0 do continue
							stagePos := combat_to_stage_pos(pos)
							sizeId := choose([]string{"XS", "S", "M", "L", "XL"})
							brightness := stagePos.y > projectileFinalPos.y ? "foreground" : "background"
							spr := sprite_find(format("ranger_attack_vines_%s_%s", sizeId, brightness))
							spriteEffect_make(spr, stagePos, 0, scale={choose([]f32{-1,1}), 1})
						}
					}

					t += int(sprite_frame_time_get(sp.ranger_attack_vines_M_foreground, 2))
					if seq_time() > t{
						combat_target_damage_seq(target, action.damage, action.hitstun, action.damageKind, user)
					}


					if stageCharacter_sprite_get(user.stageCharacter) == user.sprites.stun{
						#partial switch user.stageCharacter.facing{case .up, .down: scface(user.stageCharacter, .right)}
					}

					if seq_cue(t + 48) do return seq_close(.end)
				}
				return seq_close()
			}
		}
		inits["ranger"] = proc(using self:^CombatUnit){
			maxHp = 4
			setSingleAttack(self)
		}

		combat.actions["tonguelashAttack"] = {
			nameStream=true,
			startup=1,
			cooldown=1,
			damage=2,
			hitstun=1,
			kind = .attack,
			aimKind = .directional,
			targetMask = sp.irisMonsterAttackMask_tonguelash,
			resolve = proc(caq:^CombatActionQueued) -> bool{
				return combat_actions_basic_attack_sequence(caq, dirSpriteSet_find("tonguelash_combatAction_%s"), 8, au.tonguelashAttack, 5)
			}
		}
		{
			mirrored := combat.actions["tonguelashAttack"]
			mirrored.targetMask = sp.irisMonsterAttackMask_tonguelashMirrored
			combat.actions["tonguelashMirroredAttack"] = mirrored
		}
		inits["tonguelash"] = proc(using self:^CombatUnit){
			maxHp = 6
			initiative = 90
			set(&equippedActions, &combat.actions["tonguelashAttack"]) //todo: mirror every other spawn once mirrored anims are in
		}

		combat.actions["auctrucheAttack"] = {
			nameStream=true,
			startup=2,
			cooldown=3,
			damage=5,
			hitstun=3,
			kind = .attack,
			aimKind = .noAim,
			targetMask = sp.irisMonsterAttackMask_auctruche,
			aimingMasksDefaultUserSize = 5,
			resolve = proc(caq:^CombatActionQueued) -> bool{
				return combat_actions_basic_attack_sequence(caq, sp.auctruche_combatAction, 10, au.auctrucheAttack, 4)
			}
		}
		inits["auctruche"] = proc(using self:^CombatUnit){
			combatEntity.size = {5,5}
			maxHp = 8
			setSingleAttack(self)
			initiative = 110
		}
		
	//advisory squad
		combat.actions["consequenceAmbushAttack"] = {
			startup=0,
			cooldown=4,
			damage=30,
			hitstun=6,
			kind=.attack,
			aimKind=.directional,
			targetMask=sp.consequenceAttackMask_ambush,
			cameraFocus=.userTracking,
			resolve = proc(using caq:^CombatActionQueued) -> bool{
				state:^struct{
					startPos:Vec3
				}
				if seq_open(&state, "combat__consequenceAmbush"){
					if seq_cue(0){
						audio_play(au.consequenceAmbushAttack)
						state.startPos.xy = user.stageCharacter.transform.pos
						state.startPos.z = user.stageCharacter.transform.z
					}

					chargeTime :: 60
					dashEnd :: chargeTime + 16

					drawSilhouette :: proc(user:^CombatUnit){
						seq_draw(proc(){
							drawAlpha :f32= 1
							if seq_cue(dashEnd,dashEnd+12) do drawAlpha = seq_map(1,0)
							ambusher := scfind("consequenceAmbusher")
							shader_set(sh.colorOnly)
							using ambusher.stageEntity._ptr
							sprite_draw_ex(
								spriter.mySprite, stageEntity_draw_pos(ambusher.stageEntity), spriter.lastFrame, 
								transform.scale, transform.angle, COLOR_BLACK, drawAlpha, blendmode
							)
							shader_reset()
						}, user.stageEntity.depth.(f32)-0.5)
					}

					if seq_cue(chargeTime){
						stageCharacter_sprite_set(user.stageCharacter, sp.consequence_combatAction_side_ambush)
						music_set(nil, false)
					}

					hitTargets := combat_collision_unit(target.([]Vec2i))
					if seq_cue(chargeTime, dashEnd){
						if seq_time()%2 == 0{
							trailParticle_make(
								user.stageCharacter.spriter.mySprite, 
								stageEntity_draw_pos(user.stageEntity), user.stageEntity.depth.(f32)+0.5, 
								12, user.stageCharacter.spriter.lastFrame, 0,
								user.stageCharacter.transform.scale, 0,
								COLOR_BLACK, COLOR_WHITE, 0.7
							)
						}
						user.stageCharacter.transform.x = seq_map(state.startPos.x, state.startPos.x - 35*16)
						user.stageCharacter.transform.z = seq_map(state.startPos.z, 0)
						
						if len(hitTargets) > 0 && user.stageCharacter.transform.x <= hitTargets[0].stageCharacter.transform.x + 64{
							if combat_target_damage_seq(hitTargets[0], action.damage, action.hitstun, action.damageKind, user){
								proc_call_delayed(proc(){
									flag("diedTo", "consequenceAmbush", level=.local)
									flag("consequenceWarnable", level=.persistent)
									game_over(true)
								}, 1)
								return seq_close(.end)
							}
							else{
								drawSilhouette(user)
								return seq_close(.pause)
							}
						}
					}

					if seq_cue(chargeTime, dashEnd+12) do drawSilhouette(user)

					if seq_time() > dashEnd+12{
						dialogue_open(di.consequenceEncounter, "consequenceAppears")
						return seq_close(.end)
					}
				}
				return seq_close()
			}
		}
		combat.actions["consequenceAmbushAttackWarned"] = combat.actions["consequenceAmbushAttack"]
		(&combat.actions["consequenceAmbushAttackWarned"]).startup = 1
		inits["consequenceAmbusher"] = proc(using self:^CombatUnit){
			sprites.timelinePortrait = sp.consequence_timelinePortrait_silhouette
			maxHp = 20
			set(&equippedActions, flag_check("warnedProAboutConsequence") ? &combat.actions["consequenceAmbushAttackWarned"]: &combat.actions["consequenceAmbushAttack"])
		}

		combat.actions["consequenceSwordAttack"] = {
			startup=2,
			cooldown=2,
			damage=2,
			hitstun=2,
			kind = .attack,
			aimKind = .directional,
			targetMask = sp.consequenceAttackMask_sword,
			resolve = proc(caq:^CombatActionQueued) -> bool{
				return combat_actions_basic_attack_sequence(caq, dirSpriteSet_find("consequence_combatAction_%s_sword"), 6, au.consequenceSword, 4)
			}
		}
		combat.actions["consequenceGunAttack"] = {
			startup=2,
			cooldown=0,
			damage=1,
			hitstun=1,
			aimRange=10,
			kind = .attack,
			aimKind = .freeAim,
			targetMask = sp.consequenceAttackMask_gun,
			selfTargetable=true,
			resolve = proc(using caq:^CombatActionQueued) -> bool{
				scface_other(user.stageCharacter, combat_to_stage_pos(rect_center(targetBounds)))
				return combat_actions_basic_attack_sequence(caq, dirSpriteSet_find("consequence_combatAction_%s_gun"), 6, au.consequenceGun, 4)
			}
		}
		combat.actions["consequenceSmokeAttack"] = {
			startup=0,
			cooldown=0,
			damage=0,
			hitstun=6,
			aimRange=10,
			kind = .attack,
			aimKind = .freeAim,
			targetMask = sp.consequenceAttackMask_smoke,
			selfTargetable=true,
			resolve = proc(using caq:^CombatActionQueued) -> bool{
				attackCenter := combat_to_stage_pos(rect_center(targetBounds))
				scface_other(user.stageCharacter, attackCenter)
				if seq_open(){
					if seq_cue(sprite_frame_time_get(sp.consequence_combatAction_side_gun, 6)) do consequence_smoke_bomb_effect(attackCenter, -attackCenter.y)
					if combat_actions_basic_attack_sequence(caq, dirSpriteSet_find("consequence_combatAction_%s_gun"), 6, au.consequenceGun, 4) && seq_wait(50){
						return seq_close(.end)
					}
				}
				return seq_close()
			}
		}
		combat.actions["consequenceBackstep"] = CombatAction{
			startup=0,
			cooldown=4,
			kind=.evasion,
			aimKind=.freeAimCornered,
			aimRange=5,
			targetMask=Vec2i{3,3},
			resolve = proc(using caq:^CombatActionQueued) -> bool{
				startPos:^Vec2i
				if seq_open(&startPos, "combat__consequenceBackstep"){
					finalPos := target.([]Vec2i)[0]

					spr := dirSpriteSet_find("consequence_combatAction_%s_backstep")

					if seq_cue(0){
						stageCharacter_sprite_set(user.stageCharacter, spr, user.sprites.actionToStun, user.sprites.stun)
						startPos^ = user.combatEntity.pos
						scface(user.stageCharacter, vec2_cardinal(startPos^, finalPos))
					}

					dodgeStart := floor(sprite_frame_time_get(spr.side, 3))
					dodgeEnd := floor(sprite_frame_time_get(spr.side, 6))

					if seq_cue(dodgeStart) do audio_play(au.consequenceBackstep)

					if seq_cue(dodgeStart, dodgeEnd){
						transform_set(user.stageCharacter.transform, seq_map(combatEntity_stage_pos(user.combatEntity, startPos^), combatEntity_stage_pos(user.combatEntity, finalPos)))
					}

					if seq_cue(dodgeEnd){
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
		inits["consequence"] = proc(using self:^CombatUnit){
			maxHp = 20
			reactionTime = 0
			predictiveTargeting = true
			set(&equippedActions,
				&combat.actions["consequenceSwordAttack"],
				&combat.actions["consequenceGunAttack"],
				&combat.actions["consequenceBackstep"]
			)
		}

	combat.unit_init_names,_ = map_keys(inits^, assets.allocator)
	sort_general(combat.unit_init_names)
}