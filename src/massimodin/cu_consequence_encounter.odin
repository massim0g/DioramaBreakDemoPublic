package massimodin //@nested-tags:cutscenes

consequence_smoke_bomb_effect :: proc(pos:Vec2, depth:f32){
	smokeParticleWhite := particle_type(
		sp.circle256, 15, 50,
		0, 20, cu.popIn_inv, minScale=1./256., maxScale=22./256., scaleCurves=cu.easeOutStrong_inv,  
	)
	smokeParticleGray_ := smokeParticleWhite^
	smokeParticleGray_.colors = COLOR_GRAY
	smokeParticleGray := particle_type_clone(smokeParticleGray_)

	smokeRegion := Rect{pos, 1}

	particles_emit(smokeParticleGray, 160, depth+2, 	smokeRegion)
	particles_emit(smokeParticleWhite, 500, depth+1, smokeRegion)
	particles_emit(smokeParticleWhite, 500, depth-1, smokeRegion)
	particles_emit(smokeParticleGray, 160, depth-2, smokeRegion)

	audio_play(au.consequenceSmokeBomb)
}

_cutscenes_reload_consequence_encounter :: proc(){
	m := cutscene_namespace(di.consequenceEncounter)

	m["minimaRunsAhead"] = proc()->bool{
		if seq_open(){
			a := scmove("minima", {{650,268}}, 3., moveSprite=sp.minima_overworld_dash_side)
			b := seq_wait(60) && scmove("pro", {sepos("ambushedPos")})
			if a&&b{
				return seq_close(.end)
			}
		}
		return seq_close()
	}

	m["ambushStart"] = proc()->bool{
		if seq_open(){
			if seq_cue(0){
				minimaUnit := scfind("minima").combatUnit._ptr
				minimaUnit.unitType = .ally
				minimaUnit.walkSpeed = 0
				minimaUnit.skipStartAnim = true
				cofind(minimaUnit, PlayerFollower).runFromCombat = false
				ambushPos := stageEntity_find("ambusherPos")
				ambusher := scmake("consequenceAmbusher", ambushPos.transform.pos, .left)
				ambusher.transform.z = ambushPos.transform.z
				ambusher.combatUnit.skipStartAnim = true
			}
			if seq_cue(1){
				if flag_check("warnedProAboutConsequence"){
					scface("pro", .right)
					combat_start(success=nil_proc, failure=nil_proc)
				}
				else{
					combat_start(success=nil_proc, failure=nil_proc, deferStartAnim={.player})

					combat_event_callback_add(proc(self: ^CombatEventCallback, event: CombatEventData){
						#partial switch e in event{
							case CombatEventStarted: 
								dialogue_open(di.consequenceEncounter, "ambushStarted")
							case CombatEventUpdate:
								if combat.preview_time.displayedStep == 1 && !flag_check("consequenceAmbusherChecked") && !flag_check("warnedProAboutConsequence"){
									flag("consequenceAmbusherChecked")
									dialogue_open(di.consequenceEncounter, "ambushCheckedAttack")
								}
						}
					})
				}

				combat_event_callback_add(proc(self: ^CombatEventCallback, event: CombatEventData){
					#partial switch e in event{
						case CombatEventStarted: 
							music_set(au.eventConsequenceAmbush)
					}
				})
				
				return seq_close(.end)
			}
		}
		return seq_close()
	}

	m["ambushEnd"] = proc()->bool{
		cgSeq :: proc()->bool{
			if seq_open(){
				trTime := 10
				if seq_cue(0){
					audio_play(au.wipeWooshIn)
					audio_play(au.interferenceDrone)
					audio_parameter_set(au.interferenceDrone, "fadeIn", 0.4)
					transition_make(nil, trTime, .wipe, COLOR_BLACK, true, .up)
				}

				if seq_cue(0, trTime){
					for inst in audio.background{
						audio_volume_set(inst, seq_map(1,0))
					}
				}

				t := trTime/2
				if seq_cue(&t, 160){
					seq_draw(proc(){
						drawY := seq_map(35, sp.cg_consequence.size.y+20, cu.popInHalf)
						draw_rect(0,DISPLAY_SIZE, color_hex(drawY > DISPLAY_HEIGHT ? 0x7f3429 : 0x2c2430))
						sprite_draw(sp.cg_consequence, {DISPLAY_WIDTH/2, drawY})
					})
				}

				if seq_cue(t-trTime/2){
					audio_play(au.wipeWooshOut)
					audio_parameter_set(au.interferenceDrone, "fadeIn", 0)
					transition_make(nil, trTime, .wipe, COLOR_BLACK, true, .up)
				}

				if seq_cue(t-trTime/2, t+trTime/2){
					for inst in audio.background{
						audio_volume_set(inst, seq_map(0,1))
					}
				}

				if seq_cue(t+trTime){
					audio_stop(au.interferenceDrone)
					return seq_close(.end)
				}
			}
			return seq_close()
		}
		if seq_open(){
			if seq_cue(0) do return seq_close()
			if seq_cue(1){
				combat_end(true)
				ambusher := scfind("consequenceAmbusher")
				consequence := scmake("consequence", ambusher.transform.pos, .left)
				stageCharacter_sprite_set(consequence, sp.consequence_combatAction_side_ambush)
				//camera_tracking_set(consequence.transform._ptr)
				entity_destroy(ambusher)
				stageCharacter_sprite_set("pro", sp.pro_combat_idle_side_ready)
			}

			consequence := scfind("consequence")

			
			a := seq_wait(90) && scanim(consequence, sp.consequence_combatAction_side_ambushEnd, consequence.combatUnit.sprites.idle)
			b := seq_wait(45) && cammove(consequence, 75)

			minima := scfind("minima")
			c := scmove(minima, {{8,0}}, 4., relative=true, moveBackwards=true) && seq_wait(25) && scmove(minima, {sepos("ambushedPos")-{75,0}}, 3., moveSprite=minima.sprites.dash)

			if a && b && c{
				if seq_cue() do scface(consequence, .right)
				if cgSeq() && scanim(consequence, consequence.combatUnit.sprites.combatEnd, nil) do return seq_close(.end)
			}

		}
		return seq_close()
	}

	m["cameraSnapsToPro"] = proc()->bool{
		if seq_open(){
			pro := scfind("pro")
			minima := scfind("minima")
			if seq_cue(0){
				transform_set(pro.transform, sepos("ambushedPos"))
				stageCharacter_sprite_set(pro, pro.combatUnit.sprites.idle)
				scface(pro, .left)
			}

			a := cammove(pro)
			b := scmove(minima, {pro.transform.pos + {40,0}}, 3., .left, moveSprite=minima.sprites.dash)
			if a&&b do return seq_close(.end)
		}
		return seq_close()
	}

	m["proPutsSwordAway"] = proc()->bool{
		return scanim("pro", sp.pro_combat_end, nil)
	}

	m["cameraSnapsToConsequence"] = proc()->bool{
		return cammove("consequence")
	}

	m["consequenceWalksToPro"] = proc()->bool{
		if seq_open(){
			pro := scfind("pro")
			consequence := scfind("consequence")
			if scmove(consequence, {pro.transform.pos - {135, 0}}) &&
				cammove([]^Transform{pro.transform._ptr, consequence.transform._ptr})
			{
				music_set(au.eventConsequence)
				audio_parameter_set(audio.music, "fadeIn", 1)
				return seq_close(.end)
			}
		}
		return seq_close()
	}

	m["consequenceStepsForward"] = proc()->bool{
		if seq_open(){
			if seq_cue(0) do camera_tracking_set()
			stageCharacter_move_step("consequence", {0.5,0})
			if flag_check("consequenceStops"){
				stageCharacter_move_step_end("consequence")
				return seq_close(.end)
			}
		}
		return seq_close()
	}

	m["proAndMinimaHuddle"] = proc()->bool{
		if seq_open(){
			a := cammove("pro")
			b := scmove("pro", {{8,0}}, 1., relative=true)
			if a && b{
				return seq_close(.end)
			}
		}
		return seq_close()
	}

	m["proConfrontsConsequence"] = proc()->bool{
		if seq_open(){
			pro := scfind("pro")
			consequence := scfind("consequence")
			a := cammove([]^Transform{pro.transform._ptr, consequence.transform._ptr})
			b := scmove(pro, {{-16,0}}, relative=true)
			c := scanim("minima", sp.minima_combat_start, sp.minima_combat_idle_side_loop)
			if a && b && c do return seq_close(.end)
		}
		return seq_close()
	}

	m["minimaReadiesAttack"] = proc()->bool{
		return scanim("minima", sp.minima_combat_idle_side_toReady, sp.minima_combat_idle_side_ready)
	}

	m["minimaAttacksConsequence"] = proc()->bool{
		if seq_open(){
			consequence := scfind("consequence")
			minima := scfind("minima")
			castTime := int(sprite_frame_time_get(sp.minima_combatAction_swingCast, 7))
			scanim(minima, sp.minima_combatAction_swingCast, sp.minima_combat_idleToStun, sp.minima_combat_stun_loop)
			backstep := sp.consequence_combatAction_side_backstepOverworld
			if seq_cue(castTime){
				audio_play(au.minimaHelix)
				music_set(nil)
				spriteEffect_make(sp.minima_attackEffect_helix, consequence.transform.pos)
			}

			if seq_time()>=castTime{
				b := scmove(consequence, {{-64, 0}}, sprite_duration(backstep), .none, true, true, backstep)
				if b && seq_time()>castTime + 60 do return seq_close(.end)
			}
		}
		return seq_close()
	}

	m["consequenceFightStart"] = proc()->bool{
		if seq_open(){
			if seq_cue(0){
				minima := scfind("minima", true)
				if scfind("consequence", true) == nil{ //for debugging
					spawnPos := sepos("arenaCenter")
					spawnPos.x = 800
					dist :: 480/6
					stage.target_camera_pos = spawnPos + CAMERA_DEFAULT_TRACKING_OFFSET
					scmake("consequence", spawnPos - {dist,0})
					stageCharacter_pos_set("pro", spawnPos+{dist,0})
					scface("pro", .left)
					if minima != nil do stageCharacter_pos_set("minima", spawnPos+{dist+24,0})
					_entities_just_made_process()
				}
				stage.combatBounds.size.x = 33*16
				
				if minima != nil do cofind(minima, PlayerFollower).runFromCombat = true
				//music_set(nil, false)
				
				//scfind("consequence").combatUnit.reactAfterBreak = true

				combat_start(au.battleConsequence, success=nil_proc, failure=nil_proc)
				combat_event_callback_add(proc(self: ^CombatEventCallback, event: CombatEventData){
					#partial switch e in event{
						case CombatEventDataHitEnd:
							if e.target.initID.s == "consequence"{
								combatAction_enqueue(e.target, &combat.actions["consequenceSmokeAttack"], rect_center(e.attacker.combatEntity.rect))
								combat_timeline_refresh_unit_pips(e.target)
								flag("consequenceHitPhase1")
							} 
							
						case CombatEventDataHit:
							flag("consequencePhase1Timeout", "0")
							if e.target.initID.s == "pro"{
								//if e.target.hp == e.target.maxHp && e.damage^ > 1 do dialogue_open(di.consequenceEncounter, "consequenceHitsPro") //cut this, doesn't really add much
								if e.target.hp - e.damage^ <= 2 do dialogue_open(di.consequenceEncounter, "midFight")
							}
						case CombatEventPlanningStarted:
							dialogue_expression_parse("consequencePhase1Timeout+=1")
						case CombatEventResolveEnded:
							if res,_ := dialogue_expression_parse("consequencePhase1Timeout>=2", true); res == "1"{
								flag("consequencePhase1TimedOut")
								dialogue_open(di.consequenceEncounter, "midFight")
							}
					}
				})
			}
			if combat.phase == .planning{
				return seq_close(.end)
			}
		}
		return seq_close()
	}

	m["proAndConsequenceCircleAroundEachOther"] = proc()->bool{
		state:^struct{
			proTarget:Vec2,
			consTarget:Vec2
		}
		if seq_open(&state){

			if scfind("consequence", true) == nil && seq_cue(0){ //for debugging
				spawnPos := sepos("ambushedPos")
				scmake("consequence", spawnPos - {64,0})
				stageCharacter_pos_set("pro", spawnPos)
				entity_destroy(scfind("minima", true))
			}
			
			pro := scfind("pro")
			consequence := scfind("consequence")
			
			if seq_cue(0){
				combat_end(true)
				centerPos := (pro.transform.pos + consequence.transform.pos)/2
				offset := Vec2{64,0}
				if pro.transform.x < consequence.transform.x{
					state.proTarget = centerPos - offset
					state.consTarget = centerPos + offset
				}
				else{
					state.proTarget = centerPos + offset
					state.consTarget = centerPos - offset
				}
			}

			a := scmove(pro, {state.proTarget}, moveSprite=pro.combatUnit.sprites.walk)
			b := scmove(consequence, {state.consTarget}, moveSprite=consequence.combatUnit.sprites.walk)
			c := cammove([]^Transform{pro.transform._ptr, consequence.transform._ptr})
			
			scface_other(pro, consequence)
			pro.overrideFacing = pro.facing
			scface_other(consequence, pro)
			consequence.overrideFacing = consequence.facing

			if a&&b{
				if seq_cue(){
					stageCharacter_sprite_set(pro, pro.combatUnit.sprites.idle)
					stageCharacter_sprite_set(consequence, consequence.combatUnit.sprites.idle)
				}
				if c do return seq_close(.end)
			}
		}
		return seq_close()
	}

	m["cameraPansToMissingMinima"] = proc()->bool{
		return camera_pan_to_and_back_seq(sepos("ambushedPos")+{64,0}+CAMERA_DEFAULT_TRACKING_OFFSET, 24, 60, 24)
	}

	m["proAndConsequenceFaceEachOther"] = proc()->bool{
		if seq_open(){
			pro := scfind("pro")
			consequence := scfind("consequence")
			scface_other(pro, consequence)
			scface_other(consequence, pro)
			a := cammove([]^Transform{pro.transform._ptr, consequence.transform._ptr})
			b := scanim(pro, pro.combatUnit.sprites.combatEnd, nil)
			if a&&b{
				return seq_close(.end)
			}
		}
		return seq_close()
	}

	transitionToMinimaConnection :: proc(){
		if dialogue.current != di.consequenceEncounter{ //edge-case if trying to call this raw, ensures cutscene is active during transition
			dialogue_open(di.consequenceEncounter, "minimaTransition")
			return
		}

		combat_end(true)
		entity_destroy(scfind("pro", true))
		entity_destroy(scfind("minima", true))
		entity_destroy(scfind("consequence", true))
		audio_background_stop(false)
		tr := transition_make(proc(){
			proPos := sepos("arenaCenter")
			cons := scmake("consequence", proPos - {64,0}, .right)
			p := entity_make(Player)
			p.spawnFollowers = false
			transform_set(p.transform, proPos)
			pro := p.stageCharacter
			if shatteredHilt:=spriteEffect_find(sp.proSword_shatteredHilt, true); shatteredHilt != nil{
				shatteredBlade := spriteEffect_find(sp.proSword_shatteredBlade)
				shatteredHilt.transform.pos = proPos + {-12, 8}
				shatteredBlade.transform.pos = proPos + {-16, 4}
				shatteredHilt.stageEntity.depthKind = .floor
				shatteredBlade.stageEntity.depthKind = .floor
				
			}
			stageCharacter_sprite_set(pro, flag_check("proBladeShattered") ? sp.pro_combat_ko_loop_noSword: sp.pro_combat_ko_loop)
			minima := scmake("minima", proPos + {64,0}, .left, true)
			entity_make(InterferenceEffect)
			camera_tracking_set(cons.transform, minima.transform)
			audio_background_add(au.interferenceDrone)
			audio_parameter_set(au.interferenceDrone, "fadeIn", 0.6)
		}, [3]int{0,150,185}, .hardCutToFade)
		tr.onEnd = proc(){cutscene_advance_dialogue(false, "minimaConnection")}
	}

	m["proAndConsequenceContinueFighting"] = proc()->bool{
		pro := scfind("pro")
		consequence := scfind("consequence")
		pro.combatUnit.skipStartAnim = true
		consequence.combatUnit.skipStartAnim = true
		combat_start(success=nil_proc, failure=transitionToMinimaConnection)
		combat_event_callback_add(proc(self: ^CombatEventCallback, event: CombatEventData){
			#partial switch e in event{
				case CombatEventDataHitEnd:
					if e.target.initID.s == "consequence"{
						combatAction_enqueue(e.target, &combat.actions["consequenceSmokeAttack"], rect_center(e.attacker.combatEntity.rect))
						combat_timeline_refresh_unit_pips(e.target)
						flag("consequenceHitPhase1")
					} 
			}
		})
		return true
	}

	m["proBluffsConsequence"] = proc()->bool{
		if seq_open(){
			pro := scfind("pro")
			consequence := scfind("consequence")
			cammove(consequence)
			stageCharacter_move_step(pro, {3, 0}, moveSprite=pro.sprites.dash)

			if seq_cue(48){
				scface(consequence, .right)
				cutscene_advance_dialogue(true)
			}

			t := 100

			if seq_cue(t){
				cutscene_advance_dialogue()
			}

			if seq_time() > t{
				scanim(consequence, sp.consequence_combatAction_side_gun, nil)
			}

			if seq_time() > t+int(sprite_frame_time_get(sp.consequence_combatAction_side_gun, 6)) do scanim(pro, pro.combatUnit.sprites.hurt, pro.combatUnit.sprites.hurtToStun)

			if seq_cue(t+int(sprite_frame_time_get(sp.consequence_combatAction_side_gun, 7))){
				transitionToMinimaConnection()
				return seq_close(.end)
			}
		}
		return seq_close()
	}

	m["consequenceWalksOverToPro"] = proc()->bool{
		if seq_open(){
			if seq_cue(0) do camera_tracking_set()
			consequence := scfind("consequence")
			if scanim(consequence, consequence.combatUnit.sprites.combatEnd, nil) &&
			scmove(consequence, {scfind("pro").transform.pos - {40,0}*consequence.transform.scale.x}, endFacing=.right){
				return seq_close(.end)
			}
		}
		return seq_close()
	}

	m["consequenceKnocksOutPro"] = proc()->bool{
		if seq_open(){
			consequence := scfind("consequence")
			spr := sp.consequence_combat_start
			scanim(consequence, spr, nil)
			if seq_cue(sprite_frame_time_get(spr, 5)){ //hit frame
				transitionToMinimaConnection()
				return seq_close(.end)
			}
				
		}
		return seq_close()
	}

	m["proAttacksConsequence"] = proc()->bool{

		swordBreakSeq :: proc() -> bool{
			if seq_open(){
				sword := spriteEffect_find(sp.proSword_whole, true)
				consequence := scfind("consequence")
				consPos := consequence.transform.pos
				if seq_cue(0, 60){
					sword.transform.angle = seq_map(0, 360*10, cu.easeIn)
					sword.transform.z = seq_map(0, -400, cu.easeInHeavy)
				}

				if seq_cue(60){
					audio_stop(au.cutsceneSwordSpinning)
					audio_pause_all(true)
					audio_play(au.cutsceneSwordBreak)
				}
				
				if seq_cue(60, 135){
					seq_draw(proc(){
						draw_clear(COLOR_BLACK)
						swordPos := stageEntity_draw_pos(spriteEffect_find(sp.proSword_whole).stageEntity)
						consPos := scpos("consequence")
						lineEndPos := vec2_dir(swordPos, consPos)*vec2_distance(swordPos, consPos)*2 + consPos
						draw_color(COLOR_WHITE)
						@(static) shatterTex:Tex
						@(static) shatterTexOffset:Vec2
						if seq_cue(61){
							shatterTex, shatterTexOffset = sprite_tex_make(sp.proSword_shattering) //required to prevent color shader from interfering with line render
							tex_target_set(shatterTex, shatterTexOffset)
							shader_set(sh.colorOnly)
							sprite_draw(sp.proSword_shattering, 0)
							shader_reset()
							tex_target_reset()
						}
						else if seq_cue(60,63) do draw_line(consPos, seq_map(consPos, lineEndPos))
						else do draw_line(consPos, lineEndPos)

						tex_draw(shatterTex, swordPos+shatterTexOffset)

						if seq_cue(136) do tex_destroy(shatterTex)
					}, useStageCameraPos=true)
				}

				if seq_cue(135) do audio_pause_all(false)

				t :=136
				if seq_cue(t, 30){
					seq_draw(proc(){
						swordPos := stageEntity_draw_pos(spriteEffect_find(sp.proSword_whole).stageEntity)
						sprite_draw(sp.proSword_shattering, swordPos)
					}, useStageCameraPos=true)
				}
				if seq_cue(t+30){
					swordPos := sword.transform.coords
					spriteEffect_make(sp.proSword_shatteredBlade, swordPos, swordPos.z, INF)
					spriteEffect_make(sp.proSword_shatteredHilt, swordPos, swordPos.z, INF)
					entity_destroy(sword)
				}

				if seq_cue(t){
					pro := scfind("pro")
					stageCharacter_sprite_set(pro, sp.pro_overworld_idle_side_noSword)
					transform_add(pro.transform, Vec2{-32*pro.transform.scale.x, 0})
				}

				if seq_time() >= t && cammove(Vec2{stage.target_camera_pos.x, consPos.y + CAMERA_DEFAULT_TRACKING_OFFSET.y}, curve=cu.popIn){
					pro := scfind("pro")
					proDir := cardinal_to_vec2(pro.facing).x

					t += 48 + 20
					if seq_cue(t, t+9){
						swordPart := spriteEffect_find(sp.proSword_shatteredBlade)
						swordPart.transform.x = seq_map(pro.transform.x, pro.transform.x-32*proDir)
						swordPart.transform.z = seq_map(-270, 0)
						swordPart.transform.angle = seq_map(360*3, 0)
					}
					if seq_cue(t+9) do audio_play(au.cutsceneDirtThud)

					t+=7

					if seq_cue(t, t+9){
						swordPart := spriteEffect_find(sp.proSword_shatteredHilt)
						swordPart.transform.x = seq_map(pro.transform.x, pro.transform.x-48*proDir)
						swordPart.transform.z = seq_map(-270, 0)
						swordPart.transform.angle = seq_map(360*3, 90)
					}
					if seq_cue(t+9) do audio_play(au.cutsceneDirtThud)

					t+=9+20

					dialoguePause :: 57
					if seq_cue(t+dialoguePause) do stageCharacter_sprite_set(consequence)
					attackSpr := dirSpriteSet_find("consequence_combatAction_%s_sword")
					if seq_time() > t+dialoguePause-int(sprite_frame_time_get(attackSpr.side, 6)){
						scanim(consequence, attackSpr, nil, spriteFrameCallbacks={
							{attackSpr, 4, proc(){audio_play(au.consequenceSword)}},
							{attackSpr, 5, proc(){audio_play(au.combatKO)}}
						})
					}
					if seq_cue(t) do cutscene_advance_dialogue(true)
					if seq_cue(t+45) do cutscene_advance_dialogue(true)
					t+=dialoguePause
					if seq_cue(t){
						flag("proBladeShattered")
						//todo: call out players trying to immediately reset here?
						cutscene_advance_dialogue(true)
						return seq_close(.end)
					}
				}
			}
			return seq_close()
		}

		if seq_open(){
			if scfind("consequence", true) == nil && seq_cue(0){ //for debugging
				spawnPos := sepos("ambushedPos")
				scmake("consequence", spawnPos - {64,0})
				stageCharacter_pos_set("pro", spawnPos)
				entity_destroy(scfind("minima", true))
				cutscene.enabled = true
			}

			pro := scfind("pro")
			consequence := scfind("consequence")
			proDir := sign(consequence.transform.x - pro.transform.x)
			if proDir == 0 do proDir = -1
			proFacing := vec2_cardinal(Vec2{proDir, 0})

			if seq_cue(0) do scface(consequence, vec2_cardinal(Vec2{-proDir, 0}))
			a := cammove([]^Transform{pro.transform._ptr, consequence.transform._ptr})
			b := scmove(pro, {consequence.transform.pos - {64*proDir,0}}, 3., proFacing, moveSprite=pro.combatUnit.sprites.walk)
			if a&&b{
				if seq_cue() do camera_tracking_set()
				if scmove(pro, {{32*proDir,0}}, 5., relative=true, moveSprite=sp.pro_combat_dash_side){
					if seq_cue(){
						swordPos := pro.transform.pos + {10,-24}
						camera_tracking_set(spriteEffect_make(sp.proSword_whole, swordPos, duration=INF).transform, offset=stage.target_camera_pos-swordPos)
						audio_play(au.cutsceneSwordKnock)
						audio_play(au.cutsceneSwordSpinning)
					}
					c := transition_seq(proc(){flag("didFlash", "1", .local)}, 6, .hardCutToFade, COLOR_WHITE)
					scanim(consequence, dirSpriteSet_find("consequence_combatAction_%s_sword"), consequence.combatUnit.sprites.ready)
					scanim(pro, sp.pro_combat_stun_hurt, sp.pro_combat_stun_hurt) //todo: hurt no sword pose
					if flag_check("didFlash") && swordBreakSeq(){
						transitionToMinimaConnection()
						return seq_close(.end)
					}

				}
			}
			else if b do stageCharacter_sprite_set(pro, pro.combatUnit.sprites.idle)
		}
		return seq_close()
	}

	m["minimaTransition"] = proc()->bool{
		transitionToMinimaConnection()
		return true
	}

	m["minimaFallsToHerKnees"] = proc()->bool{
		if seq_open(){
			if seq_cue(0) do audio_parameter_set(au.interferenceDrone, "fadeIn", 1)
			minima := scfind("minima")
			minima.spriter.animSpeed = 0.5
			a := cammove(minima)
			b := scanim(minima, sp.minima_combat_stun_fromIdle, sp.minima_combat_stun_loop)
			if a && b{
				return seq_close(.end)
			}
		}
		return seq_close()
	}

	m["minimaMeditationStart"] = proc()->bool{
		if seq_open(){
			minima := scfind("minima")
			if meditation_start_seq(minima){
				return seq_close(.end)
			}
		}
		return seq_close()
	}

	m["reachOutChoice"] = proc()->bool{
		choice := entity_make(PivotalChoice)
		choice.options = {
			{"Reach Out", proc(){dialogue_open(di.consequenceEncounter, "playerConnectsToMinima")}},
			{"DO NOT", proc(){ 
				flag("diedTo", "hatingMinima")
				game_over()
			}}
		}
		choice.timedOption = true
		audio_background_add(au.heartbeatDrone)
		audio_parameter_set(au.interferenceDrone, "fadeIn", 0)
		return true
	}

	m["minimaConnects"] = proc() -> bool{
		if seq_open(){
			if seq_cue(0){
				audio_background_stop(false)
				audio_play(au.connectionFlashImmediate)
				entity_destroy(InterferenceEffect)
			}
			t := 0
			if seq_cue(&t,60){
				seq_draw(proc(){
					draw_rect(0, DISPLAY_SIZE, COLOR_WHITE, seq_map(1,0,cu.easeInStrong))
				})
			}
			
			if seq_cue(t) do music_set(au.eventMeditation)
			if seq_cue(&t,60){
				bg := cofind(MeditationBG, 0)
				bg.perlinStrength = seq_map(0,0.36)
			}

			if seq_time() >= t && scanim("minima", sp.minima_combat_stun_toIdle, nil){
				return seq_close(.end)
			}
		}
		return seq_close()
	}

	m["minimaMeditationEnd"] = proc()->bool{
		if seq_open(){
			fromLoad := scfind("consequence", true) == nil
			if seq_cue(0){
				music_set(au.battleConsequencePart2)
				audio_background_set({au.irisEdgeAmbience})
				if fromLoad{
					proPos := sepos("arenaCenter")

					cons := scmake("consequence", proPos - {64,0}, .right)
					if scfind("pro", true) == nil{
						p := entity_make(Player)
						p.spawnFollowers = false
					}
					if scfind("minima", true) == nil do scmake("minima")
					pro := scfind("pro")
					minima := scfind("minima")
					stageCharacter_pos_set(pro, proPos)
					stageCharacter_pos_set(minima, proPos + {64,0})

					if flag_check("proBladeShattered"){
						shatteredHilt := spriteEffect_make(sp.proSword_shatteredHilt, proPos + {-12, 8}, 0, INF, angle=90)
						shatteredBlade := spriteEffect_make(sp.proSword_shatteredBlade, proPos + {-16, 4}, 0, INF)
						shatteredHilt.stageEntity.depthKind = .floor
						shatteredBlade.stageEntity.depthKind = .floor
					}

					stageCharacter_sprite_set(pro, flag_check("proBladeShattered") ? sp.pro_combat_ko_loop_noSword : sp.pro_combat_ko_loop)
					
					camera_tracking_set(minima.transform)
					camera_update_position()
					stageCharacter_sprite_set(minima, minima.combatUnit.sprites.idle)
					scface(minima, .left)

					_entities_just_made_process()

					stage.combatBounds.size.x = 33*16
				}
				else{
					audio_parameter_set(audio.music, "intensity", 0.99)
					minima := scfind("minima")
					minima.spriter.animSpeed = 1
					minima.useCombatSpritesInOverworld = false
					stageCharacter_reload(minima)
					stageCharacter_sprite_set(minima, minima.combatUnit.sprites.idle)
				}
				flag("minimaJoinedParty")
				player_character_join_party(.minima)
			}

			musicDropTime := int(time_convert(7.4, .seconds, .frames))
			minima := scfind("minima")
			if fromLoad || (
				meditation_end_seq(minima, musicDropTime - seq_timestamp(), 0, false)
			){
				save.characters[.minima].inParty = true	

				minima.combatUnit.unitType = .player
				minima.combatUnit.skipStartAnim = true

				pro := scfind("pro").combatUnit
				pro.skipStartAnim = true

				audio_parameter_set(audio.music, "intensity", 2, true)

				combat_start(success=nil_proc, failure=nil_proc, deferStartAnim={.enemy})

				pro.hp = 0
				pro.unitState = .knockedOut

				combatUnit_stun(scfind("consequence").combatUnit, COMBAT_RESOLVE_INTERVAL)
				
				if fromLoad do flag("fromLoad", level=.temp)
				combat_event_callback_add(proc(self: ^CombatEventCallback, event: CombatEventData){
					#partial switch e in event{
						case CombatEventPlanningEnded:
							if combat.current_step == 0{
								//audio_parameter_set(audio.music, "intensity", 3, true) //just doesn't feel quite right
							}
						case CombatEventStarted:
							if !flag_check("fromLoad"){
								dialogue_open(di.consequenceEncounter, "minimaCombatStart")
								game_save(di.consequenceEncounter, "minimaMeditationEnd")
							}
						case CombatEventDataHit:
							if e.target.initID.s == "consequence" do dialogue_open(di.consequenceEncounter, "consequenceHit")
						case CombatEventPlanningStarted:
							if combat.current_step == COMBAT_RESOLVE_INTERVAL{
								dialogue_open(di.consequenceEncounter, "minimaAttacked")
							}
					}
				})
				combat.revivals_remaining = 0 //disable until tutorial popup
				return seq_close(.end)
			}
		}
		return seq_close()
	}

	m["proHighlight"] = proc()->bool{
		if seq_open(){
			pro := combatUnit_find("pro")
			if seq_cue(0){
				ui_highlight(combatUnit_stage_rect(pro), true)
				cutscene.enabled = false
				combat.disable_next_turn_button = true
			}

			if combat.selected_unit == pro{
				ui_highlight()
				combat.revivals_remaining = 1
				combat.revival_override_cutscene = "proRevivalDone"
				combat.revival_override_cutscene_namespace = di.consequenceEncounter.name
				flag("nextRevivalGuaranteed", level=.temp)
				cutscene_advance_dialogue()
				return seq_close(.end)
			}
		}
		return seq_close()
	}

	m["proRevivalDone"] = proc()->bool{
		if seq_open(){
			if seq_cue(0){
				audio_parameter_set(au.interferenceDrone, "fadeIn", 0)
				music_set(nil, false) //stop paused battle music
				music_set(au.battleConsequencePart2)
				audio_parameter_set(audio.music, "intensity", 4, true)
			}
			if seq_cue(0,180){
				audio_volume_set(audio.music, seq_map(0,1))
			}
			charSprites := &combat.selected_unit.sprites
			if transition_seq(proc(){
				audio_background_remove(au.interferenceDrone, false)
				meditation_end_seq(combat.selected_unit.stageCharacter, 0, 0, false)
				proPos := sepos("arenaCenter")

				consequence := scfind("consequence")
				stageCharacter_pos_set(consequence,  proPos - {64,0})
				scface(consequence, .right)
				stageCharacter_sprite_set(consequence, consequence.combatUnit.sprites.idle)

				minima := scfind("minima")
				stageCharacter_pos_set("minima",  proPos + {64,0})
				scface("minima", .left)
				stageCharacter_sprite_set(minima, minima.combatUnit.sprites.idle)

				combat.time_stop_mode = .disabled
			}, [3]int{60,60,60}, .fade, COLOR_WHITE) &&
			seq_wait(40)
			{
				combat.disable_next_turn_button = false
				combat_end(true)
				proc_call_delayed(proc(){
					dialogue_open(di.consequenceEncounter, "proWakesUp")
				}, 1)
				return seq_close(.end)
			}
		}
		return seq_close()
	}

	m["consequenceRunsAtMinima"] = proc()->bool{
		slashSeq :: proc()->bool{
			if seq_open(){
				if seq_cue(0){
					cutscene_advance_dialogue()
					scface("pro", .left)
					stageCharacter_sprite_set("pro", sp.pro_combat_idle_side_ready)
					if flag_check("proBladeShattered"){
						player_character_equip(.pro, "trainingBlade")
						entity_destroy(spriteEffect_find(sp.proSword_shatteredHilt))
					}
					audio_play(au.cutsceneSwordSwing)
				}
				
				t := sprite_duration(sp.pro_combatAction_side_slashEffect)
				if seq_cue(t) do audio_play(au.cutsceneSwordParry)
				consequence := scfind("consequence")
				if seq_time() <= t{
					seq_draw(proc(){
						draw_clear(COLOR_BLACK)
						pro := scfind("pro").transform
						pro_blade_pal_swap_set()
						sprite_draw_ex(sp.pro_combatAction_side_slashEffect, pro.pos, sprite_frame_get(sp.pro_combatAction_side_slashEffect, f32(seq_time()-1)), pro.scale)
						shader_reset()
					}, useStageCameraPos=true)
				}
				else if scmove(consequence, {{-96,0}}, sprite_duration(consequence.combatUnit.sprites.hurt), .none, true, true, consequence.combatUnit.sprites.hurt, curve=cu.easeInStrong) && 
					scanim(consequence, consequence.combatUnit.sprites.hurtToStun, consequence.combatUnit.sprites.stunToIdle, consequence.combatUnit.sprites.idle){
					return seq_close(.end) 
				}
			}
			return seq_close()
		}
		if seq_open(){
			if seq_cue(0) do combat_end(true)

			pro := scfind("pro")
			consequence := scfind("consequence")
			if scanim(consequence, consequence.combatUnit.sprites.idleToReady, consequence.combatUnit.sprites.ready) && seq_wait(20) && scmove(consequence, {pro.transform.pos}, 12, moveSprite=sp.consequence_combatAction_side_ambush) && slashSeq(){ //todo: combat walk sprite
				cutscene_advance_dialogue()
				return seq_close(.end)
			}
		}
		return seq_close()
	}

	m["combatResumesAfterRevivingPro"] = proc()->bool{
		pro := scfind("pro").combatUnit
		minima := scfind("minima").combatUnit
		consequence := scfind("consequence").combatUnit
		pro.skipStartAnim = true
		minima.skipStartAnim = true
		consequence.skipStartAnim = true
		consequence.reactionTime = 2
		consHp := consequence.hp //preserve damage
		combat_start(success=nil_proc, failure=proc(){
			flag("diedTo", "consequence", level=.local)
			game_over()
		})
		combat_event_callback_add(proc(self: ^CombatEventCallback, event: CombatEventData){
			#partial switch e in event{
				case CombatEventDataHit:
					if e.target.initID.s == "consequence" && e.target.hp - e.damage^ <= 6 do dialogue_open(di.consequenceEncounter, "consequenceDefeated")
			}
		})
		combat.revivals_remaining = 0
		pro.hp = pro.maxHp/2
		consequence.hp = consHp 
		return true
	}

	consequenceNinjaJumpSeq :: proc(jumpOut:bool) -> bool{
		consequence := scfind("consequence")
		se := consequence.stageEntity
		if seq_open(){
			jumpH :: 24
			spr := sp.consequence_combatAction_side_backstep
			if seq_cue(int(sprite_frame_time_get(spr, 3))) do audio_play(au.consequenceBackstep)
			if jumpOut{
				if seq_cue(int(sprite_frame_time_get(spr, 3)),int(sprite_frame_time_get(spr, 4))){
					se.alpha = min(f32(1), seq_map(2,0))
					se.color = color_lerp(COLOR_WHITE, COLOR_BLACK, seq_map(0,1))
					transform_add(se.transform, Vec2{-4,0})
					se.transform.z = seq_map(0, -jumpH)
				}
			}
			else{
				if seq_cue(0){
					se.alpha = 0
					se.transform.z = -jumpH
					camera_tracking_set()
				}
				if seq_cue(int(sprite_frame_time_get(spr, 4)), int(sprite_frame_time_get(spr, 5))){
					se.alpha = seq_map(0,1)
					se.color = color_lerp(COLOR_BLACK, COLOR_WHITE, seq_map(0,1))
					transform_add(se.transform, Vec2{-4,0})
					se.transform.z = seq_map(-jumpH, 0)
				}
			}
			if scanim(consequence, spr, sp.consequence_combat_idle_side_loop){
				return seq_close(.end)
			}
		}
		return seq_close()
	}

	m["consequenceThrowsASmokeBomb"] = proc()->bool{
		if seq_open(){
			if scfind("consequence", true) == nil{ //for debugging
				scmake("consequence", sepos("ambushedPos")-{64,0}) 
				if scfind("minima", true) == nil do scmake("minima", sepos("ambushedPos")-{64,0})
				if spriteEffect_find(sp.proSword_shatteredBlade, true) == nil && flag_check("proBladeShattered"){
					spriteEffect_make(sp.proSword_shatteredBlade, scpos("pro") + {-16, 4}, 0, INF)
				}
			}

			if seq_cue(0) do music_set(nil)
			consequence := scfind("consequence")
			scface_other(consequence, "pro")
			if cammove(consequence) && scanim(consequence, sp.consequence_combatAction_side_gun, nil, spriteFrameCallbacks={
				//{3, proc(){/*spriteEffect_make() todo: sparkle effect*/}},
				{sp.consequence_combatAction_side_gun, 5,proc(){
					consequence := scfind("consequence")
					
					consequence_smoke_bomb_effect(consequence.transform.pos + {30,-37}*consequence.transform.scale, consequence.stageEntity.depth.(f32))
					proc_call_delayed(proc(){
						camera_tracking_set()
						consequence := scfind("consequence")
						consequence.transform.pos = sepos("cliffEdge")
						consequence.stageEntity.alpha = 0
					}, 12)
				 }},
			}){
				if cammove(consequence) && consequenceNinjaJumpSeq(false) && seq_wait(24){
					return seq_close(.end)
				}
			}
		}
		return seq_close()
	}

	m["consequenceLeapsAway"] = proc()->bool{
		if seq_open(){
			pro := scfind("pro")
			minima := scfind("minima")
			if seq_cue(0){
				centerPos := sepos("arenaCenter")
				transform_set(pro.transform, centerPos - {48,0})
				transform_set(minima.transform, centerPos + {64,0})
				scface(pro, .left)
				scface(minima, .left)
			}
			if consequenceNinjaJumpSeq(true) && cammove(pro){ //todo: would be hilarious to add a splash sfx here
				if seq_cue() do combat_end()
				if combat.phase == .disabled do return seq_close(.end)
			}
		}
		return seq_close()
	}

	m["minimaSits"] = proc()->bool{
		return scanim("minima", sp.minima_cutscene_rest_sit, sp.minima_cutscene_rest_loop)
	}

	m["proPicksUpSwordFragment"] = proc()->bool{
		if seq_open(){
			blade := spriteEffect_find(sp.proSword_shatteredBlade, true)
			pro := scfind("pro")
			if (blade == nil || scmove(pro, {blade.transform.pos-{32,0}})) && seq_wait(30){
				if seq_cue(){
					audio_play(au.proEquip)
					entity_destroy(blade)
					inventory_add("proBladeFragments")
					inventory_set("prosBlade", 0)
				}
				if popup_seq(item_collect_message("proBladeFragments")) do return seq_close(.end)
			}
		}
		return seq_close()
	}

	m["proWalksOverToMinima"] = proc()->bool{
		//if blade := spriteEffect_find(sp.proSword_shatteredBlade, true); blade != nil do entity_destroy(blade)
		if seq_open(){
			if scmove("pro", {scfind("minima").transform.pos - {48,0}}, endFacing=.right) && 
			scanim("minima", sp.minima_cutscene_rest_stand, nil){
				return seq_close(.end)
			}
		}
		return seq_close()
	}

	m["minimaStepsForward"] = proc()->bool{
		scface_other("pro", "minima")
		return scmove("minima", {scpos("pro")-{96, 0}})
	}

	m["demoOutroStart"] = proc() -> bool{
		flag("demoCompleted")
		flag("demoPreviouslyCompleted", level=.prestige)
		game_save(di.prologueAndOutro, "demoContinues")
		proc_call_delayed(proc(){
			titleScreen_goto()
			dialogue_open(di.prologueAndOutro, "outro")
		}, 1)
		return true	
	}
}