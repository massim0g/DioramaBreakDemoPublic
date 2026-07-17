package massimodin //@nested-tags:cutscenes

_cutscenes_reload_minima_encounter :: proc(){
	m := cutscene_namespace(di.minimaEncounter)
	
	m["startEncounter"] = proc()->bool{
		if seq_open(){
			if seq_cue(0){
				minima := scmake("minima", sepos("minimaSpawnPoint"), .left, true)
				minima.useCombatSpritesInOverworld = true
				scmake("tonguelash", minima.transform.pos-{72,0}, .right, true)
				scmake("tonguelash", minima.transform.pos+{56,0}, .left, true)
				
				camera_shake(10, 5)
				audio_play(au.cutsceneExplosion)
				music_set(nil)
			}
			if seq_cue(60){
				return seq_close(.end)
			}
		}
		return seq_close()
	}
	m["proWalksBehindRock"] = proc()->bool{
		if seq_open(){
			pro := scfind("pro")
			minima := scfind("minima")
			enemies := stageCharacter_find_all("tonguelash")
			hidingPos := sepos("irisRockHidingPos")
			if scmove(pro, {hidingPos+{0,110}, hidingPos+{0,100}}, 2., .up) &&
			seq_wait(25) &&
			scmove(pro, {hidingPos}, 4., .up, moveSprite=pro.sprites.dash)
			{
			if seq_cue(){
				music_set(au.battleTutorial)
				audio_parameter_set(audio.music, "inTenseCutscene", 1)
				audio_parameter_set(audio.music, "intensity", 2)
			}
			if cammove(minima, 30) &&
			seq_wait(12) &&
			scmove(enemies[1], {{-8,0}}, relative=true) &&
			scface(minima, .right, 30) &&
			scmove(enemies[0], {{8,0}}, relative=true) &&
			scface(minima, .left, 38) &&
			cammove(pro, 30)
			{
				return seq_close(.end)
			}
			}
		}
		return seq_close()
	}

	m["proJumpsIn"] = proc()->bool{
		if seq_open(){
			pro := scfind("pro")
			minima := scfind("minima")
			if scmove(pro, {{-24, 0}}, 2., relative=true) &&
			scanim(pro, pro.combatUnit.sprites.combatStart, pro.combatUnit.sprites.idle) &&
			scmove(pro, {minima.transform.pos-{8,0}}, 3., .left, moveSprite=dirSpriteSet_find("pro_combat_dash_%s")){
			a := scmove(minima, {{16,0}}, 4, relative=true,moveBackwards=true)
			b := scanim(pro, pro.combatUnit.sprites.idleToReady, pro.combatUnit.sprites.ready)
			if seq_cue() do audio_play(au.pro_combat_start)
			if a&&b &&
			scface(minima, .right, 16) &&
			scface(minima, .left, 20) &&
			scmove(minima, {sepos("irisMinimaHidingPos")}, 4., moveSprite=minima.sprites.dash)
			{
				stageEntity_set_visible(minima.stageEntity, false)

				pro.combatUnit.skipStartAnim = true
				//todo: sick-ass cutaway
				music_set(nil)
				combat_start(au.fieldIris)

				combat_event_callback_add(proc(self: ^CombatEventCallback, event: CombatEventData){
					#partial switch e in event{
						case CombatEventStarted:
							flag("inIrisIntro", "3")
							audio_parameter_set(audio.music, "inIrisIntro", 3)
						case CombatEventEnded: 
							flag("inIrisIntro", "0")
							scfind("pro").combatUnit.skipStartAnim = false
							dialogue_open(di.minimaEncounter, "postCombat")
					}
				})
				return seq_close(.end)
			}

			}
		}
		return seq_close()
	}

	m["proLooksAround"] = proc()->bool{
		if seq_open(){
			if seq_cue(0){
				if minima :=scfind("minima",true);minima==nil do scmake("minima", sepos("irisMinimaHidingPos")) //for debugging
			}

			if scmove("pro", {sepos("proFindsMinimaPos")}) &&
			seq_wait(20) &&
			scmove("pro", {0,20}, relative=true)
			{
				return seq_close(.end)
			}
		}
		return seq_close()
	}

	m["minimaEmerges"] = proc()->bool{
		cgSeq :: proc() -> bool{
			if seq_open(){
				fadeDur :: 65

				minima := scfind("minima")
				if seq_cue(fadeDur){
					minima.useCombatSpritesInOverworld = false
					stageCharacter_reload(minima)
					stageCharacter_sprite_set(minima, sp.minima_combat_ko_sit)
				}

				alpha:f32=1
				t:=0
				if seq_cue(&t,fadeDur) do alpha = seq_map(0,1)
				if seq_time()>t && seq_latch(ginputs[.confirm]){
					t = seq_timestamp()
					if seq_cue(&t,fadeDur) do alpha = seq_map(1,0)
					if seq_time() > t do return seq_close(.end)
				}
				
				seq_draw(callback_make(proc(alpha:^f32){
					buffer :: Vec2{2,2}
					spr := sp.cg_minimaIntroduction
					drawRect := Rect{0, spr.size+buffer*2}
					rect_align(&drawRect, DISPLAY_SIZE/2, 0)
					nineslice_draw(sp.menuBoxOutlined, drawRect, alpha=alpha^)
					rect_resize_in_place(&drawRect, -buffer)
					sprite_draw_ex(spr, drawRect.pos, alpha=alpha^)
				}, alpha, context.temp_allocator))
			}
			return seq_close()
		}
		if seq_open(){
			minima := scfind("minima")
			if seq_cue(0){
				stageEntity_set_visible(minima.stageEntity, true)
				minima.useCombatSpritesInOverworld = true
				stageCharacter_reload(minima)
			}

			if cammove([]^Transform{scfind("pro").transform, minima.transform}, 25) && 
			seq_wait(20) &&
			scmove(minima, {scpos("pro") + {80,0}}) &&
			scface(minima, .right, 23) &&
			scshake(minima, 6, {2, 0}, 38, au.cutsceneBushRustle) && 
			scshake(minima, 6, {2, 0}, 6, au.cutsceneBushRustle) &&
			scmove(minima, {scpos("pro") + {48,0}}, 3.5, moveBackwards=true) && //todo: leaf particles?
			scface(minima, .left, 4) &&
			scanim(minima, sp.minima_combat_ko_start, sp.minima_combat_ko_loop) && 
			seq_wait(15) &&
			scanim(minima, sp.minima_combat_ko_getupPartway, sp.minima_combat_ko_sit) && 
			seq_wait(30) &&
			cgSeq() &&
			seq_wait(30) &&
			scanim(minima, sp.minima_combat_ko_getupPartwayEnd, sp.minima_combat_end, nil) &&
			seq_wait(12){
				return seq_close(.end)
			}
		}
		return seq_close()
	}

	m["minimaWalksNextToPro"] = proc()->bool{
		return scmove("minima", {scpos("pro") + {48,0}}, 1., .left)
	}

	m["proStartsLeaving"] = proc()->bool{
		return scmove("pro", {{270,262}}, endFacing=Dir.right)
	}

	m["proWalksAway"] = proc()->bool{
		if seq_open(){
			pro := scfind("pro")
			minima := scfind("minima", true)
			leavePath := []Vec2{
				sepos("leavePathA"),
				sepos("leavePathB"),
				sepos("leavePathC"),
				sepos("leavePathD"),
			}
			if scmove(pro, leavePath){
				if seq_cue(){
					cutscene_advance_dialogue(false, "firstEncounterDone")
					player_follower_add("minima")
					flag("minimaEncountered")
					stageCharacter_move_step_end(minima, .left)
				}
				if stage_warp_seq(st.IrisForestDeepShrine, pro, {992,961}, .left){
					cutscene_advance_dialogue()
					return seq_close(.end)
				}
			}
			else{
				if cammove(minima) && 
					seq_wait(20) &&
					scmove(minima, {{333,277}}) &&
					scface(minima, .down, 40) &&
					scface(minima, .left, 50) &&
					scmove(minima, {pro.transform.pos + {32,0}}, 4., moveSprite=minima.sprites.dash)
				{
					if seq_cue() do cutscene_advance_dialogue()
					cammove(pro)
					stageCharacter_move_step_target(minima, pro.transform.pos+{32,0}, 1.5, movingTarget=true)
				}
			}

		}
		return seq_close()
	}

	m["walkBackToRestArea"] = proc()->bool{
		player := scfind("pro")
		scface_other(player, sepos("restCenter"))
		return stageCharacter_move_seq(player, {cardinal_to_vec2(player.facing)*16}, 1.5, .none, true)
	}

	m["minimaGetsUpToTwirl"] = proc()->bool{
		if seq_open(){
			minima := scfind("minima")
			if scanim(minima, sp.minima_cutscene_rest_stand, nil) && scmove(minima, {{16, 0}}, relative=true, moveBackwards=true){
				return seq_close(.end)
			}
		}
		return seq_close()
	}

	m["minimaTwirl"] = proc()->bool{
		if seq_open(){
			if scanim("minima", sp.minima_cutscene_twirl_in, sp.minima_cutscene_twirl_loop){
				return seq_close(.end)
			}
		}
		return seq_close()
	}

	m["minimaStopsPosing"] = proc()->bool{
		return scanim("minima", sp.minima_cutscene_twirl_toIdle, nil)
	}

	m["minimaWalksToPro"] = proc()->bool{
		if seq_open(){
			proPos := scpos("pro")
			if scmove("minima", {vec2_nearest(scpos("minima"), proPos + {48,0}, proPos - {48,0})}){
				return seq_close(.end)
			}
		}
		return seq_close()
	}
}