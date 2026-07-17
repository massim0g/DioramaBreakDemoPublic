package massimodin //@nested-tags:cutscenes

CombatTutorialPhase :: enum{
	chion,
	kion,
	akro,
	guards,
	polema
}

combat_tutorial_fail_check :: proc(e:CombatEventDataHit, lostTo:string){
	if e.target.initID.s == "pro" && e.target.hp - e.damage^ <= 0{
		flag("tutorialLostTo", lostTo)
		flags_clear(.temp)
		stage_goto(st.prosRoom)
		transition_make(proc(){
			pro := entity_make(Player).stageCharacter
			pro.transform.pos = {560,250}
			pro.stageEntity.shadowKind = .none
			stageCharacter_facing_set(pro, .right)
			stageCharacter_sprite_set(pro, sp.cutscene_intro_bed_pro)

			covers := stageEntity_find("bedCovers")
			covers.editableDepthOffset = -30
			covers.transform.z = -13

			camera_tracking_set(pro.transform)

			dialogue_open(di.combatTutorial, "failure")
		}, 60, TransitionKind.hardCut)
	}
}

_cutscenes_reload_combat_tutorial :: proc(){
	m := cutscene_namespace(di.combatTutorial)

	m["polemaEncounterStart"] = proc()->bool{
		if seq_open(){
			if seq_cue(0){
				scmake("polema", {175, 138}, .left)
			}

			pro := stageCharacter_find("pro")
			polema := stageCharacter_find("polema") 

			a := stageCharacter_move_seq(pro, {{446, 138}, {312, 138}}, 1.5)
			b := camera_pan_to_seq(polema.transform.pos+camera.tracking_offset, 90)
			if a && b{
				return seq_close(.end)
			}
		}
		return seq_close()
	}

	m["polemaTurnsAround"] = proc() -> bool{
		if seq_open(){
			pro := stageCharacter_find("pro")
			polema := stageCharacter_find("polema") 
			if seq_cue(0) do stageCharacter_facing_set(polema, .right)
			
			if camera_pan_to_seq(lerp(polema.transform.pos, pro.transform.pos, 0.5)+camera.tracking_offset){
				return seq_close(.end)
			}
		}
		return seq_close()
	}

	m["polemaWalksOver"] = proc() -> bool{
		if seq_open(){

			if stageCharacter_move_seq("polema", {{286, 138}}, 200) && scmove("pro", {{312, 170}}, 1.5){
				scface("polema", .down)
				cutscene_advance_dialogue()
				return seq_close(.end)
			}
		}
		return seq_close()
	}

	m["polemaWalksDown"] = proc()->bool{
		if seq_open(){
			pro := stageCharacter_find("pro")
			polema := scfind("polema")
			a := stageCharacter_move_seq(polema, {{286, 416}}, 1.5)
			b := camera_pan_to_seq(pro.transform.pos+camera.tracking_offset)
			if a && b{
				entity_destroy(polema)
				camera_tracking_set(pro.transform)
				cutscene_advance_dialogue()
				return seq_close(.end)
			}
		}
		return seq_close()
	}

	// m["combatTutorialTriedToLeave"] = proc()->bool{
	// 	if !(flag_check("captainEncountered") && !flag_check("combatTutorialDone") && !flag_check("combatTutorialFailed")) do return true
	// 	dialogue_open(di.combatTutorial, "triedToLeave")
	// 	return true
	// }

	m["guardsEncounterStart"] = proc()->bool{ //started using "sc" shorthand here
		if seq_open(){
			if seq_cue(0){
				scmake("polema", {384, 416}, .left)
				scmake("chion", {100, 412}, .right, true)
				scmake("kion", {148, 412}, .right, true)
				akro := scmake("akro", {113, 382}, .right, true)
				akro.sprites.idle.side = sp.akro_combat_idle_side_alt
			}

			if scmove("pro", {{286, 412}, {270, 412}}, 1.5, .left){
				if seq_cue() do music_set(au.encounterTutorial)
				if cammove(Vec2{195, 381}) do return seq_close(.end)
			}
		}
		return seq_close()
	}

	m["proTurnsToPolema"] = proc() -> bool{
		if seq_open(){
			if seq_cue(0) do scface("pro", .right)
			if seq_cue(20){
				return seq_close(.end)
			}
		}
		return seq_close()
	}

	m["proPsychsOutKion"] = proc() -> bool{
		if seq_open(){
			a := scmove("pro", {{-9, 0}}, 3, .none, true)
			b:bool
			if seq_time() >= 8 do b = scmove("kion", {{-24, 0}}, 6, .none, true, true)
			if a&&b&&seq_wait(40){
				return seq_close(.end)
			}
		}
		return seq_close()
	}

	m["polemaSpeaksUp"] = proc() -> bool{
		if seq_open(){
			pro := scfind("pro")
			if seq_cue(0) do scface(pro, .right)
			a := scmove("polema", {{336, 412}})
			b := cammove(pro.transform.pos+camera.tracking_offset)
			if a&&b{
				camera_tracking_set(pro.transform)
				cutscene_advance_dialogue()
				return seq_close(.end)
			}
		}
		return seq_close()
	}

	m["everyoneBoardsElevator"] = proc() -> bool{
		if seq_open(){
			pro := scfind("pro")
			a := scmove(pro, {{385, 412}, {385, 472}, {385, 520}})
			b := scmove("akro", {{134, 412}, {385, 412}, {385, 452}, {518, 452}}, 1.5, .left)
			c := scmove("kion", {{385, 412}, {385, 472}, {511, 567}}, 2., .down)
			d := scmove("chion", {{385, 412}, {385, 472}, {512, 524}}, 1., .right)
			e := scmove("polema", {{385, 412}, {385, 443}, {448, 443}}, 1.5, .left)
			if a&&b&&c&&d&&e{
				if scmove("polema", {{454, 443}}, 1.0, .up) && seq_wait(30){
					if seq_cue() do audio_background_add(au.elevatorGateOpen)
					f := scmove("polema", {{-100,0}}, 1.5, .down, true)
					g := stageEntity_move_seq(stageEntity_find("elevatorGate"), {{-100, 0}}, 1.5, true)
					if f && g{ 
						audio_background_remove(au.elevatorGateOpen)
						audio_play(au.elevatorGateClose)
						scface("akro", .left)
						scface("kion", .up)
						scface("chion", .left)
						scface("pro", .up)
						cutscene_advance_dialogue(false, "elevatorBoarded")
						return seq_close(.end)
					}
				}
			}
		}
		return seq_close()
	}

	setupAkroConvo :: proc(){
		pro:^StageCharacter
		p, ok := cofind(Player, 0)
		if !ok do pro = entity_make(Player).stageCharacter
		else do pro = p.stageCharacter
		transform_set(pro.transform, Vec2{561, 151})
		stageCharacter_sprite_set(pro, sp.pro_cutscene_lean_idle, newFacing=Dir.left)
		scmake("akro", {594, 156}, .up)
		camera_tracking_set()
		stage.target_camera_pos = {655,144}
		stage.bounds.size.x += 500 //prevent camera snap
		audio_background_add(au.elevatorLoop)
	}

	m["elevatorDescends"] = proc() -> bool{
		startPositions:^[]f32
		if seq_open(&startPositions){
			ents := coall(StageEntity)
			elevatorGroup := make([dynamic]^StageEntity, context.temp_allocator)
			for &ent in ents{
				_,scFound := cofind(&ent, StageCharacter)
				if scFound || ent.group.s == "elevator" do append(&elevatorGroup, &ent)
			}

			inTutorial := !flag_check("polemaDefeated")

			if seq_cue(0){
				audio_play(au.elevatorStart)
				startPositions^ = make([]f32, len(elevatorGroup), seq_allocator())
				for ent, i in elevatorGroup{
					startPositions[i] = ent.transform.z
					stageEntity_unstatic(ent)
				}

				camera_shake(10, 3)
			}

			startTime :: 50
			descentTime :: 115
			transitionDescentTime := 80
			transitionStoppedTime := inTutorial?175:0

			if seq_cue(startTime) do audio_background_add(au.elevatorLoop)

			if seq_cue(startTime, startTime+descentTime) && stage.loaded == st.lowerArea{
				displacement := seq_map(0, 80)
				for ent, i in elevatorGroup{
					ent.transform.z = startPositions[i]+displacement
				}
			}

			if inTutorial && seq_cue(startTime+descentTime+transitionDescentTime) do cutscene_advance_dialogue()

			if seq_wait(startTime+descentTime-15) && 
				transition_seq(proc(){
					if flag_check("polemaDefeated"){
						flag("scrollingBackgroundFoliage")
						stage_load(st.newCargoLiftTest)
						setupAkroConvo()
						game_save(di.combatTutorial, "akroConvo")
					}
					else{
						stage_load(st.newCargoLiftTest)
						pro := entity_make(Player).stageCharacter
						transform_set(pro.transform, Vec2{476, 281})
						scface(pro, .up)
						scmake("chion", {623, 215}, .left, useCombatSpritesInOverworld=true)
						scmake("kion", {595, 270}, .left, useCombatSpritesInOverworld=true)
						akro := scmake("akro", {594, 156}, .left, useCombatSpritesInOverworld=true)
						akro.sprites.idle.side = sp.akro_combat_idle_side_alt
						scmake("polema", {471, 151}, .down)
						audio_play(au.elevatorTreeStop)
					}
				}, [3]int{15,transitionDescentTime+transitionStoppedTime,15}) &&
				seq_wait(inTutorial?20:150)
			{
				if inTutorial{
					cutscene_advance_dialogue()
				}
				return seq_close(.end)
			}
		}
		return seq_close()
	}

	m["setupAkroConvoFromLoad"] = proc() -> bool{
		if scfind("akro", true) == nil{
			setupAkroConvo()
			flag("fromLoad", level=.local)
		}
		return true
	}

	m["polemaApproachesPro"] = proc() -> bool{
		return scmove("polema", {{0, 32}}, relative=true)
	}
	m["polemaWalksBack"] = proc() -> bool{
		return scmove("polema", {{0, -32}}, 1.5, .down, true)
	}

	m["proAndChionGetInPosition"] = proc()->bool{
		if seq_open(){
			combatAreaPos := stage.combatBounds.pos
			a := scmove("pro", {combatAreaPos + {48, 64} + COMBAT_TILE_RADIUS}, 1.5, .right)
			b := scmove("chion", {combatAreaPos + {224, 64} + COMBAT_TILE_RADIUS}, 1.5, .left)
			c := scmove("kion", {combatAreaPos + {298, 67}}, 1.5, .left)
			d := scmove("akro", {combatAreaPos + {298, 24}}, 1.5, .left)
			if a && b &&c&&d{
				return seq_close(.end)
			}
		}
		return seq_close()
	}

	m["proEquipsTrainingBlade"] = proc()->bool{
		if seq_open(){
			combatAreaPos := stage.combatBounds.pos
			middleHolder := stageEntity_find("stromaMiddleSwordHolder")
			if scmove("pro", {middleHolder.transform.pos + {0, 4}}, 1.5, .up) && seq_wait(25){
				if seq_wait(62) && seq_cue() do spriter_set(middleHolder.spriter, sp.swordHolder_empty)

				if blade_swap_seq("trainingBlade") && 
				seq_wait(20) && 
				scmove("pro", {combatAreaPos + {48, 64}}, 1.5, .right)
				{
					flag("equippedElevatorSword")
					return seq_close(.end)
				}
			}
		}
		return seq_close()
	}

	m["chionFightStart"] = proc()->bool{
		music_set(nil)
		combat_start(au.battleTutorial, success=nil_proc, failure=nil_proc) //"failure" and "success" impossible
		combat_event_callback_add(proc(self: ^CombatEventCallback, event: CombatEventData){
			#partial switch e in event{
				case CombatEventStarted: 
					audio_parameter_set(combat.music_override, "Intensity", 1)
					dialogue_open(di.combatTutorial, "combatInterface")
				case CombatEventDataStepEnd: 
					if combat.current_step + 1 == COMBAT_RESOLVE_INTERVAL*3 do dialogue_open(di.combatTutorial, "combatInterface2")
					if combat.current_step == 4 do dialogue_open(di.combatTutorial, "chionQuip")
				case CombatEventDataHit:
					//we can just assume chion got hit lol
					if e.target.hp == e.target.maxHp do dialogue_open(di.combatTutorial, "chionQuip2")
				case CombatEventDataActionResolved:
					if combatUnit_find("chion").hp <= 2 do dialogue_open(di.combatTutorial, "kionStart")
			}
		})
		return true
	}

	m["highlightPro"] = proc()->bool{
		if seq_open(){
			pro := combatUnit_find("pro")
			if seq_cue(0){
				ui_highlight(combatUnit_stage_rect(pro), true)
				cutscene.enabled = false
				combat.disable_next_turn_button = true
			}

			if combat.selected_unit == pro{
				ui_highlight()
				combat.disable_next_turn_button = false
				proc_call_delayed(proc(){cutscene_advance_dialogue()}, 1)
				return seq_close(.end)
			}
		}
		return seq_close()
	}

	m["chionWalksOut"] = proc() -> bool{
		combatAreaPos := stage.combatBounds.pos
		combatEntity_unplace(scfind("chion").combatUnit.combatEntity)
		return scmove("chion", {combatAreaPos + {288, 0}}, 1.5, .left)
	}

	m["kionWalksIn"] = proc() -> bool{
		if seq_open(){
			combatAreaPos := stage.combatBounds.pos
			a := scmove("pro", {combatAreaPos + {48, 64} + COMBAT_TILE_RADIUS}, 1.5, .right)
			b := scmove("kion", {combatAreaPos + {224, 64} + COMBAT_TILE_RADIUS}, 2., .left)
			if a && b{
				return seq_close(.end)
			}
		}
		return seq_close()
	}

	m["kionFightStart"] = proc()->bool{
		combat_start(au.battleTutorial, success=nil_proc, failure=nil_proc) //"failure" and "success" impossible
		combat_event_callback_add(proc(self: ^CombatEventCallback, event: CombatEventData){
			#partial switch e in event{
				case CombatEventStarted:
					audio_parameter_set(combat.music_override, "Intensity", 1)
					dialogue_open(di.combatTutorial, "kionFightTutorial")
				case CombatEventDataHit:
					if e.target.hp == e.target.maxHp{
						switch e.target.initID.s{
							case "pro": dialogue_open(di.combatTutorial, "kionQuipTookHit")
							case "kion": dialogue_open(di.combatTutorial, "kionQuip")
						}
					}

					combat_tutorial_fail_check(e, "kion")
					
				case CombatEventDataActionResolved:
					if combatUnit_find("kion").hp <= 2 do dialogue_open(di.combatTutorial, "akroStart")
			}
		})
		return true
	}

	m["kionHighlight"] = proc()->bool{
		r := combatUnit_stage_rect(combatUnit_find("kion"))
		rect_set_left(&r, r.x-16*7, true)
		rect_set_top(&r, r.y - 2, true)
		r.size += 2
		ui_highlight(r, true)
		return true
	}

	m["kionWalksOut"] = proc() -> bool{
		combatAreaPos := stage.combatBounds.pos
		combatEntity_unplace(scfind("kion").combatUnit.combatEntity)
		return scmove("kion", {combatAreaPos + {288, 64}}, 1.5, .left)
	}

	m["akroWalksIn"] = proc() -> bool{
		if seq_open(){
			combatAreaPos := stage.combatBounds.pos
			a := scmove("pro", {combatAreaPos + {48, 64} + COMBAT_TILE_RADIUS}, 1.5, .right)
			b := scmove("akro", {combatAreaPos + {224, 64} + COMBAT_TILE_RADIUS}, 1.5, .left)
			if a && b{
				return seq_close(.end)
			}
		}
		return seq_close()
	}

	m["proEquipsRegularSword"] = proc()->bool{
		return blade_swap_seq("prosBlade") 
	}

	m["akroHighlight"] = proc()->bool{
		if seq_open(){
			akro := combatUnit_find("akro")
			if seq_cue(0){
				ui_highlight(combatUnit_stage_rect(akro), true)
				cutscene.enabled = false
				combat.disable_next_turn_button = true
			}

			if akro.actionPreviewPinned{
				ui_highlight()
				proc_call_delayed(proc(){cutscene_advance_dialogue()}, 1)
				combat.disable_next_turn_button = false
				return seq_close(.end)
			}

			if combat.selected_unit != nil || combatUnit_find("pro").actionPreviewPinned{
				ui_highlight()
				proc_call_delayed(proc(){cutscene_advance_dialogue(label="akroTutorialSpurned")}, 1)
				combat.disable_next_turn_button = false
				return seq_close(.end)
			}
		}
		return seq_close()
	}

	m["akroFightStart"] = proc()->bool{
		combat_start(au.battleTutorial, success=nil_proc, failure=nil_proc) //"failure" and "success" impossible
		combat_event_callback_add(proc(self: ^CombatEventCallback, event: CombatEventData){
			#partial switch e in event{
				case CombatEventStarted:
					audio_parameter_set(combat.music_override, "Intensity", 2)
					dialogue_open(di.combatTutorial, "akroFightTutorial")
				case CombatEventAttackEnd:
					if e.attacker.initID.s == "pro" && len(e.hitUnits) == 0 do flag("missedAkro")
				case CombatEventDataHit:
					if e.target.hp == e.target.maxHp{
						switch e.target.initID.s{
							case "pro": 
								flag("tookDamageFromAkro")
								dialogue_open(di.combatTutorial, "akroTookHit")
						}
					}

					combat_tutorial_fail_check(e, "akro")
					
				case CombatEventDataActionResolved:
					if combatUnit_find("akro").hp <= 4 do dialogue_open(di.combatTutorial, "traineesStart")
			}
		})
		return true
	}

	m["akroWalksOut"] = proc() -> bool{
		combatAreaPos := stage.combatBounds.pos
		combatEntity_unplace(scfind("akro").combatUnit.combatEntity)
		return scmove("akro", {combatAreaPos + {288, 32}}, 1.5, .left)
	}

	m["traineesShock"] = proc()->bool{
		if seq_open(){
			a := scmove("pro", {{-16, 0}}, 2., relative=true, moveBackwards=true)
			b := false
			if seq_time() > 6 do b = scmove("chion", {{16, 0}}, 2., relative=true, moveBackwards=true)
			c := false
			if seq_time() > 3 do c = scmove("kion", {{16, 0}}, 2., relative=true, moveBackwards=true)
			d := scmove("akro", {{16, 0}}, 2., relative=true, moveBackwards=true)
			if a&&b&&c&&d{
				return seq_close(.end)
			}
		}
		return seq_close()
	}

	m["traineesWalkIn"] = proc() -> bool{
		if seq_open(){
			combatAreaPos := stage.combatBounds.pos
			a := scmove("pro", {combatAreaPos + {48, 64} + COMBAT_TILE_RADIUS}, 1.5, .right)
			b := scmove("chion", {combatAreaPos + {240, 32} + COMBAT_TILE_RADIUS}, 1.5, .left)
			c := scmove("kion", {combatAreaPos + {240, 96} + COMBAT_TILE_RADIUS}, 2., .left)
			d := scmove("akro", {combatAreaPos + {224, 64} + COMBAT_TILE_RADIUS}, 1.5, .left)
			if a&&b&&c&&d{
				return seq_close(.end)
			}
		}
		return seq_close()
	}

	m["traineesFightStart"] = proc()->bool{
		combat_start(au.battleTutorial, success=nil_proc, failure=nil_proc) //"failure" and "success" impossible
		combat_event_callback_add(proc(self: ^CombatEventCallback, event: CombatEventData){
			#partial switch e in event{
				case CombatEventStarted:
					audio_parameter_set(combat.music_override, "Intensity", 2)
					dialogue_open(di.combatTutorial, "traineesFightTutorial")
				case CombatEventDataHit: combat_tutorial_fail_check(e, "trainees")
				case CombatEventDataActionResolved:
					removeTrainee :: proc(id:string){
						flag(format("%sDone", id))
						combatEntity_unplace(combatUnit_find(id).combatEntity)
					}
					chion := combatUnit_find("chion", true)
					kion := combatUnit_find("kion", true)
					akro := combatUnit_find("akro", true)
					chionDone := chion != nil && chion.hp <= 4
					kionDone := kion != nil && kion.hp <= 4
					akroDone := akro != nil && akro.hp <= 4
					if chionDone do removeTrainee("chion")
					if kionDone do removeTrainee("kion")
					if akroDone do removeTrainee("akro")
					if chionDone || kionDone || akroDone do dialogue_open(di.combatTutorial, "traineeDone")
			}
		})
		return true
	}

	m["unblockCamera"] = proc()->bool{
		cutscene.enabled = false
		combat.disable_next_turn_button = true
		return true
	}
	m["unblockCameraEnd"] = proc()->bool{
		combat.disable_next_turn_button = false
		return true
	}

	m["proGetsBackInTutorialPosition"] = proc()->bool{
		combatAreaPos := stage.combatBounds.pos
		return scmove("pro", {combatAreaPos + {48, 64} + COMBAT_TILE_RADIUS}, 1.5, .right)
	}

	m["polemaWalksIn"] = proc() -> bool{
		combatAreaPos := stage.combatBounds.pos
		return scmove("polema", {combatAreaPos + {224, 64} + COMBAT_TILE_RADIUS}, 1.5, .left)
	}

	m["polemaFightStart"] = proc()->bool{
		swordOffsetAkro := Vec2{-15,-24}
		swordOffsetPolema := Vec2{17,-31}
		if seq_open(){
			akro := scfind("akro")
			polema := scfind("polema")
			if scmove(akro, {sepos("polemaSwordInRack")}, endFacing=.up) && seq_wait(50){
				akroPos := scpos(akro)
				polemaPos := scpos(polema)
				if seq_cue(){
					swordRack,_ := stageEntity_nearest(akroPos, "polemaSwordRack")
					spriter_set(swordRack.spriter, sp.polemaSwordWeaponRack_noSword)
					scface(akro, vec2_cardinal(akroPos, Vec2{polemaPos.x, akroPos.y})) //face away from polema because sword throw anim is reversed for some reason?
				}
				 
				a := scanim(akro, sp.akro_cutscene_swordToPolema, nil)
				
				t := seq_timestamp() + int(sprite_frame_time_get(sp.akro_cutscene_swordToPolema, 6))
				flightTime :: 24
				swordStartPos := Vec3{akroPos.x + swordOffsetAkro.x*cardinal_to_vec2(akro.facing).x, akroPos.y, swordOffsetAkro.y}
				swordEndPos := Vec3{polemaPos.x + swordOffsetPolema.x*cardinal_to_vec2(polema.facing).x, polemaPos.y, swordOffsetPolema.y}
				swordMidPos := (swordStartPos+swordEndPos)/2
				swordMidPos.z = -200
				if seq_cue(t) do spriteEffect_make(sp.polema_sword, swordStartPos.xy, swordStartPos.z, INF, angle=90)
				if seq_cue(&t, flightTime){
					sword := spriteEffect_find(sp.polema_sword)
					transform_set(sword.transform, arc_projectile_pos(swordStartPos, swordMidPos, swordEndPos, curve_eval(cu.easeInOut, seq.cue_prog)))
					sword.transform.angle = seq_map(90, -360+90)
				}
				if seq_cue(t - sprite_duration(sp.polema_combat_start) + int(sprite_frame_time_get(sp.polema_combat_start, 6))-7){
					combat_start(au.battleTutorial, success=nil_proc, failure=nil_proc)
					combat_event_callback_add(proc(self: ^CombatEventCallback, event: CombatEventData){
						#partial switch e in event{
							case CombatEventStarted:
								audio_parameter_set(combat.music_override, "Intensity", 3)
								dialogue_open(di.combatTutorial, "polemaFightTutorial")
							case CombatEventDataHit: combat_tutorial_fail_check(e, "polema")
							case CombatEventAttackEnd:
								if len(e.hitUnits) > 0{
									hitUnit := e.hitUnits[0]
									if hitUnit.initID.s == "polema"{
										if hitUnit.hp <= 0{
											music_set(nil, false)
											dialogue_open(di.combatTutorial, "polemaDefeated")
										}
										else if hitUnit.hp <= hitUnit.maxHp/2 && !flag_check("polemaMidFight"){
											dialogue_open(di.combatTutorial, "polemaMid")
											flag("polemaMidFight", level=.temp)
										} 
									}
								}
						}
					})
				}
				if seq_cue(t){
					entity_destroy(spriteEffect_find(sp.polema_sword))
				}
				if a && seq_time() >= t do return seq_close(.end)
				
			}
		}
		return seq_close()
	}

	m["timelineReadOrder"] = proc()->bool{
		if seq_open(){
			fadeTime :: 16
			alpha :f32= 1
			if seq_cue(0,fadeTime) do alpha = seq_map(0,1)
			if flag_check("timelineReadOrderEnd"){
				t:=seq_timestamp()
				if seq_cue(t, t+fadeTime) do alpha = seq_map(1,0)
				if alpha == 0 do return seq_close(.end)
			}
			seq_draw(callback_make(proc(a:^f32){
				combat_timeline_draw_read_order(a^)
			}, alpha, context.temp_allocator))
		}
		return seq_close()
	}

	m["highlightTimelineAndUnblock"] = proc()->bool{
		ui_highlight(rectf_make_points(0,92,133,177))
		cutscene.enabled = false
		combat.disable_next_turn_button = true
		return true
	}
	m["unhighlightTimeline"] = proc()->bool{
		ui_highlight()
		combat.disable_next_turn_button = false
		return true
	}

	m["polemaEnterPhase2"] = proc()->bool{
		units := combatUnits_get()
		for unit in units{
			combatUnit_queued_actions_clear(unit)
			unit.stunCounter = 0
			combat_timeline_break(unit)
		}
		polema := combatUnit_find("polema")
		polema.reactionTime = 2
		return true
	}

	// m["polemaKneels"] = proc() -> bool{
	// 	return scanim("polema", sp.polema_cutscene_ko_toKneel, sp.polema_cutscene_ko_kneel)
	// }
	m["polemaCollapses"] = proc() -> bool{
		if seq_open(){
			polema := scfind("polema")
			if seq_cue(0) do audio_play(au.combatProTumble) //todo: needs bespoke sound
			if scanim(polema, sp.polema_combat_ko_collapse, sp.polema_combat_ko_collapsed){
				polema.combatUnit.skipEndAnim = true
				sword := spriteEffect_make(sp.polema_combat_ko_sword, polema.transform.pos, -2, INF, scale=polema.transform.scale)
				sword.stageEntity.depthKind = .floor
				cammove("arenaCenter")
				return seq_close(.end)
			}
		}
		return seq_close()
	}

	m["paxDemoOutro"] = proc() -> bool{
		titleScreen_goto()
		dialogue_open(di.paxDemoOutro)
		return true	
	}

	m["elevatorRises"] = proc()->bool{
		if seq_open(){

			onMid :: proc(){ //strange compiler issues if I try to define this anonymously
				boxPos := stageEntity_find("stromaElevatorBox").transform.pos
				relativePositions := []Vec2{
					scpos("pro"),
					scpos("chion"),
					scpos("kion"),
					scpos("akro"),
					scpos("polema"),
					stage.target_camera_pos
				}
			
				for &pos in relativePositions{
					pos -= boxPos 
				}
			
				stage_load(st.lowerArea)
			
				boxPos = stageEntity_find("stromaElevatorBox").transform.pos
			
				pro := entity_make(Player).stageCharacter
				
				transform_set(pro.transform, Vec2{232,514})
				scface(pro, .right)
				scmake("chion", 	relativePositions[1]+boxPos, .left)
				scmake("kion", 		relativePositions[2]+boxPos, .left)
				scmake("akro", 		relativePositions[3]+boxPos, .left)
				
				polema := scmake("polema", 	relativePositions[4]+boxPos, .down)
				stageCharacter_sprite_set(polema, sp.polema_combat_ko_collapsed)
			
				sword := spriteEffect_make(sp.polema_combat_ko_sword, scpos(polema), -2, INF)
				sword.stageEntity.depthKind = .floor

				spriter_set(stageEntity_find("polemaSwordRack").spriter, sp.polemaSwordWeaponRack_noSword)

				camera_tracking_set()
				stage.target_camera_pos = relativePositions[5]+boxPos 
			}

			if transition_seq(onMid, [3]int{15,80,15}){
				return seq_close(.end)
			}
		}
		return seq_close()
	}

	m["chionAndKionGetTheStretcher"] = proc()->bool{
		if seq_open(){
			kion := scfind("kion", true)
			chion := scfind("chion", true)
			proOutOfWay:bool

			arenaEdge, stretcherPos, stretcherSpawnPos:Vec2
			if flag_check("combatTutorialFailed"){
				arenaEdge = {490, 150}
				stretcherPos = {286, 128}
				stretcherSpawnPos = {356, 150}
				proOutOfWay = seq_wait(115) && scmove("pro", {{483,172}}, 1.5, .right)
			}
			else{
				arenaEdge = {386, 450}
				stretcherPos = {286, 356}
				stretcherSpawnPos = {384, 364}
				proOutOfWay = true
			}

			a := scmove(kion, {arenaEdge, stretcherPos}, 2., .right)
			b := scmove(chion, {arenaEdge, stretcherPos}, 1.75, .right)
			if a&&b&&proOutOfWay{
			if seq_cue(){
				entity_destroy(kion)
				entity_destroy(chion)
				scmake("stretcher", stretcherSpawnPos, facingMode=.disabled)
			}
			stretcher := scfind("stretcher")
			polema := scfind("polema", true)
			polemaPos:Vec2
			if polema != nil do polemaPos = polema.transform.pos
			if seq_wait(100) && scmove(stretcher, {arenaEdge, polemaPos + {16, 37}}, moveSprite=sp.polema_cutscene_stretcher_carryIn){
			if seq_cue(){
				entity_destroy(polema)
			}
			if scanim(stretcher, sp.polema_cutscene_stretcher_lift, sp.polema_cutscene_stretcher_carryIdle) &&
				scmove("akro", {stretcher.transform.pos + {10, -56}}, endFacing=.left){
				return seq_close(.end)
			}
			}
			}
		}
		return seq_close()
	}

	m["chionAndKionCarryPolemaAway"] = proc()->bool{
		if seq_open(){
			if seq_cue(0){
				scface("akro", flag_check("combatTutorialFailed") ? .right : .up)
			}
			path :[]Vec2= flag_check("combatTutorialFailed") ? {{763,174}, {917,174}} : {{401, 485}, {401, 356}}
			if scmove("stretcher", path, moveSprite=sp.polema_cutscene_stretcher_carryOut) && seq_wait(50){
				return seq_close(.end)
			}
		}
		return seq_close()
	}

	m["akroAndProWalkToElevator"] = proc()->bool{
		if seq_open(){
			//Note: deprecated this part, transition always goes straight to akro convo now since the other stuff added literally nothing to the story
			// if flag_check("combatTutorialFailed"){
			// 	if transition_seq(proc(){
			// 		boxPos := sepos("stromaElevatorBox")
			// 		stage.target_camera_pos = sepos("elevatorFocus")
			// 		stageCharacter_pos_set("pro", boxPos+{-32,32})
			// 		stageCharacter_pos_set("akro", boxPos+{0,6})
			// 		scface("pro", .right)
			// 		scface("akro", .up)
			// 	}, 60) && seq_wait(25){
			// 		return seq_close(.end)
			// 	}
			// }
			// else{
			// 	boxPos := sepos("stromaElevatorBox")
			// 	a := scmove("pro", {boxPos+{-32,32}}, 1.5, .right)
			// 	b := scmove("akro", {boxPos+{0,6}}, 1.5, .up)
			// 	if a&&b{
			// 		return seq_close(.end)
			// 	}

			// }

			if transition_seq(proc(){
				flag("scrollingBackgroundFoliage")
				stage_load(st.newCargoLiftTest)
				texture_group_preload("iris")
				setupAkroConvo()
				game_save(di.combatTutorial, "akroConvo")
			}, 80) && seq_wait(150){
				return seq_close(.end)
			}
		}
		return seq_close()
	}

	m["proConfrontsAkro"] = proc()->bool{
		if seq_open(){
			if scanim("pro", sp.pro_cutscene_lean_end, nil) && scmove("pro", {{0,5}}, 5, .right, true){
				return seq_close(.end)
			}
		}
		return seq_close()
	}

	m["elevatorReachesBottom"] = proc()->bool{
		if seq_open(){
			transitionTime :: 46
			transition_seq(duration=[3]int{15,transitionTime,15})
			t := 15+transitionTime/2
			if seq_cue(t){
				stage_load(st.IrisForestEntrance)
				audio_background_add(au.elevatorLoop)
				stage.defaultFootstepSurface = .wood
				pro := entity_make(Player).stageCharacter
				transform_set(pro.transform, Vec2{603, 268})
				scface(pro, .up)
				akro := scmake("akro", {729, 280}, .up)
				estring_set(&akro.stageEntity.group, "elevator")
				camera_tracking_set(pro.transform)
				_entities_just_made_process()
			}

			elevatorGroup := make([dynamic]^StageEntity, context.temp_allocator)
			if seq_time() >= t{
				ents := coall(StageEntity)
				for &ent in ents{
					if ent.group.s == "elevator" do append(&elevatorGroup, &ent)
				}
				append(&elevatorGroup, scfind("pro").stageEntity)
			}

			if seq_cue(t){
				for ent in elevatorGroup{
					ent.static = false
					ent.editableDepthOffset -= 400
				}
			}

			t += transitionTime/2

			maxDisplacement :: 831
			if seq_cue(&t, maxDisplacement/3){
				
				displacement := seq_map(-maxDisplacement, 0)
				for ent in elevatorGroup{
					ent.transform.z = displacement
				}

			}
			if seq_cue(t){
				audio_background_remove(au.elevatorLoop)
				audio_play(au.elevatorLand)
				camera_shake(10, Vec2{0,4})
				camera_tracking_set()
				stageEntity_find("stromaElevatorBase").depthKind = .floor //reenables drop shadows
				for ent in elevatorGroup{ent.editableDepthOffset += 400}
			}

			if seq_cue(t+70) do scface("akro", .left)

			if seq_time() >= t+60 && 
			scmove("pro", {{555, 268}}, 1.5, .up) &&
			seq_wait(30)
			{
			if seq_cue() do audio_background_add(au.elevatorGateOpen)
			a := scmove("pro", {{100,0}}, 1.5, .right, true)
			b := stageEntity_move_seq(stageEntity_find("stromaElevatorGate"), {{100, 0}}, 1.5, true)
			if a&&b{
			if seq_cue(){
				audio_background_remove(au.elevatorGateOpen)
				audio_play(au.elevatorGateClose)
			}
			if seq_wait(20)
			{
			c := scmove("pro", {{572, 268}}, endFacing=.up)
			d := scmove("akro", {{634, 268}}, endFacing=.up)
			if c&&d&&seq_wait(30){
				scface("pro", .right)
				scface("akro", .left)
				return seq_close(.end)
			}
			}
			}
			}
		}
		return seq_close()
	}

	m["proRunsOffTheElevator"] = proc()->bool{
		if seq_open(){
			if scmove("pro", {{0,-28}}, 2., .right, true, moveSprite=sp.pro_overworld_dash_up){
				return seq_close(.end)
			}
		}
		return seq_close()
	}

	m["elevatorReturnsWithAkro"] = proc()->bool{
		if seq_open(){
			if scmove("akro", {{655, 268}}, 1.5, .up) &&
			seq_wait(30)
			{
			if seq_cue() do audio_background_add(au.elevatorGateOpen)
			a := scmove("akro", {{-100,0}}, 1.5, .up, true)
			b := stageEntity_move_seq(stageEntity_find("stromaElevatorGate"), {{-100, 0}}, 1.5, true)
			if a&&b{
			if seq_cue(){
				audio_background_remove(au.elevatorGateOpen)
				audio_play(au.elevatorGateClose)
			}
			if seq_wait(20) && 
			scmove("akro", {{729,280}}, 1.5, .up) && 
			seq_wait(20)
			{

			elevator := stageEntity_group_get("elevator")
			if seq_cue(){
				audio_play(au.elevatorStart)
				audio_background_add(au.elevatorLoop)
				camera_shake(10, 3)

				stageEntity_find("stromaElevatorBase").depthKind = .origin

				for ent in elevator{
					ent.editableDepthOffset -= 400
					ent.shadowKind = .none
				}
			}

			t := seq_timestamp()
			if seq_cue(&t, 180){
				audio_volume_set(au.elevatorLoop, seq_map(1,0))
			}

			
			for ent in elevator do ent.transform.z -= 3
			if seq_time()>t && cammove("pro"){
				audio_background_remove(au.elevatorLoop)
				for ent in elevator do entity_destroy(ent)
				stage.defaultFootstepSurface = .grass
				return seq_close(.end)
			}
			}
			}
			}
		}
		return seq_close()
	}

	m["proWakesUpAfterFailure"] = proc() -> bool{
		if seq_open(){
			pro := scfind("pro")
			t:=90
			if seq_cue(t) do stageCharacter_sprite_set(pro, sp.cutscene_intro_bed_pro_eyesOpening, sp.cutscene_intro_bed_pro_eyesOpen)
			if seq_cue(t+60){
				return seq_close(.end)
			}
		}
		return seq_close()
	}

	m["salviaWalksInAfterFailure"] = proc()->bool{
		if seq_open(){
			salvia:^StageCharacter
			if seq_cue(0){
				salvia = stageCharacter_make("salvia", {375, 222}, .right) 
				//audio_play(au.doorThrownOpen) //todo: normal door sound?
			}
			else do salvia = stageCharacter_find("salvia")

			if stageCharacter_move_seq(salvia, {{400, 222}, {560, 250}}, 96) {
				return seq_close(.end)
			}
		}

		return seq_close()
	}

	m["salviaLeavesAfterFailure"] = proc()->bool{
		if seq_open(){
			salvia := stageCharacter_find("salvia", true)

			if stageCharacter_move_seq(salvia, {{400, 222}, {375, 222}})
			{

			if seq_cue(){
			audio_play(au.doorOpen)
			entity_destroy(salvia)
			}

			if seq_wait(60){
				return seq_close(.end)
			}
			}
		}
		return seq_close()
	}

	m["proGetsUpAfterFailure"] = proc() -> bool{
		return transition_seq(proc(){
			audio_play(au.proEquip)
			pro := scfind("pro")
			stageCharacter_sprite_set(pro)
			scplace(pro, {502, 178})
			scface(pro, .left)

			covers := stageEntity_find("bedCovers")
			covers.editableDepthOffset = 0
			covers.transform.z = -1

			game_save()
		})
	}

	m["proWalksUpToTrainees"] = proc()->bool{
		if seq_open(){
			if seq_cue(0){
				scmake("chion", {575,160}, .left, useCombatSpritesInOverworld=true)
				scmake("kion", {522,160}, .right, useCombatSpritesInOverworld=true)
				akro := scmake("akro", {560,87}, .down, useCombatSpritesInOverworld=true)
				akro.sprites.idle.side = sp.akro_combat_idle_side_alt
				scmake("polema", {624,160}, .left)
				spriter_set(stageEntity_find("polemaSwordRackArena").spriter, sp.polemaSwordWeaponRack_withSword)
			}
			if scmove("pro", {{718,160}}, 1.5, .left){
				scface("polema", .right)
				scface("chion", .right)
				scface("akro", .right)
				return seq_close(.end)
			}
		}
		return seq_close()
	}

	m["proThreatensPolema"] = proc()->bool{
		if seq_open(){
			if seq_cue(0) do audio_play(au.pro_combat_start)
			if scanim("pro", sp.pro_combat_start, sp.pro_combat_idle_side_loop) && seq_wait(20){
				return seq_close(.end)
			}
		}
		return seq_close()
	}

	m["proBacksOutOfFight"] = proc()->bool{
		return stage_warp_seq(st.MainTrunk, scfind("pro"), {395, 436}, .right)
	}

	m["tutorialReset"] = proc()->bool{
		if transition_seq(proc(){
			pro := scfind("pro")
			akro := scfind("akro")

			stageCharacter_sprite_set(pro)
			akro.useCombatSpritesInOverworld = true

			combatAreaPos := stage.combatBounds.pos
			scplace(pro, 		combatAreaPos + {140, 120})
			scplace("chion", 	combatAreaPos + {277, 32})
			scplace("kion", 	combatAreaPos + {294, 40})
			scplace(akro, 	combatAreaPos + {298, 67})
			scplace("polema", 	combatAreaPos + {135, -10})

			scface(pro, .up)
			scface("chion", .left)
			scface("kion", .left)
			scface(akro, .left)
			scface("polema", .down)

			if flag_get("tutorialLostTo") == "kion" do player_character_equip(.pro, "trainingBlade")
			else do player_character_equip(.pro, "prosBlade")

			camera_tracking_set()
			stage.target_camera_pos = combatAreaPos + {140, 45}
		}){
			cutscene_advance_dialogue(label=format("%sFightStart", flag_get("tutorialLostTo")))
			return true
		}
		return false
	}

	
}
