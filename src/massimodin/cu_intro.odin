package massimodin //@nested-tags:cutscenes

_cutscenes_reload_intro :: proc(){
	
	m := cutscene_namespace(di.intro)
	m["introSetup"] = proc()->bool{
		when DEBUG do entity_destroy(cofind(Player, 0))
		pro := entity_make(Player).stageCharacter
		pro.transform.pos = {560,250}
		pro.stageEntity.shadowKind = .none
		stageCharacter_facing_set(pro, .right)
		stageCharacter_sprite_set(pro, sp.cutscene_intro_bed_pro)

		covers := stageEntity_find("bedCovers")
		covers.editableDepthOffset = -30

		stand := stageEntity_find("proSwordStand")
		spriter_set(stand.spriter, sp.swordHolder_sword)

		camera_tracking_set(pro)
		return true
	}

	m["momKnockOnDoor"] = proc()->bool{
		if seq_open(){
			if seq_cue(50) do audio_play(au.doorKnock)
			if seq_cue(64) do audio_play(au.doorKnock)
			if seq_cue(180) do return seq_close(.end)
		}

		return seq_close()
	}

	m["momWalkIn"] = proc()->bool{
		if seq_open(){
			salvia:^StageCharacter
			if seq_cue(0){
				salvia = stageCharacter_make("salvia", {375, 222}, .right) 
				audio_play(au.doorThrownOpen)
			}
			else do salvia = stageCharacter_find("salvia")

			if stageCharacter_move_seq(salvia, {{400, 222}, {560, 250}}, 96) {
				return seq_close(.end)
			}
		}

		return seq_close()
	}

	m["proDraggedOutOfBed"] = proc()->bool{
		salvia := stageCharacter_find("salvia")
		pro := stageCharacter_find("pro")
		if seq_open(){
			if seq_cue(0){
				cofind(pro, CombatUnit).visible = false
				audio_play(au.cutsceneBedDrag)
			}
			if stageCharacter_anim_seq(salvia, sp.cutscene_intro_bed_salvia, sp.salvia_overworld_idle_side){
				if seq_cue(){
					cofind(pro, CombatUnit).visible = true
					pro.stageEntity.shadowKind = .dropShadowEllipse
					transform_set(pro.transform, salvia.transform.pos)
					transform_add(salvia.transform, Vec2{-26, 2})
				}

				if stageCharacter_anim_seq(pro, sp.pro_cutscene_intro_getup_sitUp, sp.pro_cutscene_intro_getup_standUp, sp.pro_cutscene_intro_idle_side, newFacing=.left){
					cutscene_advance_dialogue()
					return seq_close(.end)
				}
			}
		}
		return seq_close()
	}

	m["proGetsReady"] = proc()->bool{
		if seq_open(){
			salvia := stageCharacter_find("salvia", true)
			pro := stageCharacter_find("pro")

			if(
			stageCharacter_move_seq(salvia, {{400, 222}}, 90)
			)
			{
			if seq_cue() do audio_play(au.doorOpen)
			if(
			seq_wait(36) &&
			stageCharacter_move_seq(salvia, {{375, 222}}, 30))
			{
			
			if seq_cue(){
				entity_destroy(salvia)
				audio_play(au.doorClose)
			}
			
			t := (
				seq_wait(sprite_duration(sp.pro_cutscene_intro_walk_up_scratch)-15) && 
				transition_seq(proc(){
					audio_play(au.proEquip)
					stand := stageEntity_find("proSwordStand")
					spriter_set(stand.spriter, sp.swordHolder_empty)
					scface("pro", .down)
				})
			)
			if stageCharacter_move_seq(pro, {{502, 178}}, sprite_duration(sp.pro_cutscene_intro_walk_up_scratch), moveSprite=sp.pro_cutscene_intro_walk_up_scratch) &&
			t
			{
				game_save(silent=true)
				return seq_close(.end)
			}
			}
			}
		}

		return seq_close()
	}

	m["proWalksDownstairs"] = proc()->bool{
		if seq_open(){
			salvia := stageCharacter_find("salvia", true)
			pro := stageCharacter_find("pro")
			if stageCharacter_move_seq(pro, {{176, 235}, {168,256}, {168, 336}}, 1.5) &&
			stage_warp_seq(st.prosHouseLivingRoom, pro, {168,370})
			{
			
			if seq_cue() do salvia = stageCharacter_make("salvia", {271, 617}, .up)

			if stageCharacter_move_seq(pro, {{168, 470}, {311, 539}, {311, 633}}, 1.5){
				scface(salvia, .right)
				return seq_close(.end)
			}
			}
		}
		return seq_close()
	}

	m["momWalksToPro"] = proc() -> bool{
		if seq_open(){
			salvia := stageCharacter_find("salvia")
			pro := scfind("pro")
			if stageCharacter_move_seq(salvia, {pro.transform.pos - {10,6}}, 1.0, .down){
				return seq_close(.end)
			}
		}
		return seq_close()
	}

	m["proWalksOut"] = proc() -> bool{
		if seq_open(){
			salvia := stageCharacter_find("salvia", true)
			pro := stageCharacter_find("pro")
			if seq_cue(0){
				stageEntity_set_visible(salvia.stageEntity, false)
				audio_play(au.cutsceneMomHug)
			}
			if stageCharacter_anim_seq(pro, sp.cutscene_intro_hug_hugIn, sp.cutscene_intro_hug_hugOut, nil){
				if seq_cue(){
					stageEntity_set_visible(salvia.stageEntity, true)
				}
				if seq_wait(30) && 
					stageCharacter_move_seq(pro, {{311, 656}}) && 
					stage_warp_seq(st.prosNeighbourhood, pro, {962,310})
				{
					return seq_close(.end)
				}
			} 
		}
		return seq_close()
	}

	m["proWalksToHall"] = proc() -> bool{
		creditsWarpSeq :: proc(creditsLabel:string, s:^Stage, warpCharacter:^StageCharacter, warpCharacterNewPos:Vec2, onMid:Callback=nil, key:ImKey=#caller_location) -> bool{
			if seq_open(key){
				creditsStartT :: 50
				creditsDur :: 140
				if seq_cue(creditsStartT, creditsStartT+creditsDur){
					seq_draw(callback_make(proc(l:^string){
						drawTex := tex_make(DISPLAY_SIZE)
						defer tex_destroy(drawTex)
						tex_target_set(drawTex, clear=false)
						draw_clear(COLOR_BLACK)
						dialogue_paragraph_draw(Rect{0, DISPLAY_SIZE}, di.credits, l^, COLOR_WHITE, fo.fairfax__12, true)
						tex_target_reset()
						alpha :f32= 0
						t := creditsStartT
						if seq_cue(&t, 15) do alpha = seq_map(0,1)
						if l^ == "introC"{
							if seq_cue(&t, creditsDur-15) do alpha = 1
							if seq_cue(t){
								audio_background_stop(false)
								audio_play(au.doorCloseBoom)
							}
						}
						else{
							if seq_cue(&t, creditsDur-30) do alpha = 1
							if seq_cue(&t, 15) do alpha = seq_map(1,0) 
						}
						tex_draw_ex(drawTex, 0, 0, alpha=alpha)
					}, creditsLabel))
				}
				if stage_warp_seq(s, warpCharacter, warpCharacterNewPos, duration=[3]int{40,creditsLabel == "introC"?creditsDur+10+90:160,40}, onMid=onMid, key=imkey_combine(key)){
					return seq_close(.end)
				}
			}
			return seq_close()
		}
		if seq_open(){
			if seq_cue(0){
				music_set(au.stromaVillage)
				audio_parameter_set(au.stromaVillage, "InPrologue", 1)
			}
			pro := scfind("pro")
			a := cammove(sepos("introPanEnd"), 320)
			
			if scmove(pro, {{960,355}, {907,355}, {803, 305}, {667,303}, {595,355}, {504,320}}, 2., endFacing=.up) &&
			seq_wait(36) &&
			scmove(pro, {{504,107}, {462, 81}, {456,11}}, 3., moveSprite=pro.sprites.dash) &&
			a &&
			creditsWarpSeq("introA", st.townCenter, pro, {670,797}, onMid=proc(){
				stage.target_camera_pos = sepos("introCamPos")
				camera_update_position()
				stageCharacter_pos_set("pro", {670, 705})
			}) &&
			scmove(pro, {{670,578}, {640,578}, {400,502}}, 3., moveSprite=pro.sprites.dash){
			
			b := equals(stage.loaded, st.upperPlatform, st.townHall) && seq_wait(80) && cammove(sepos("introPanEnd"), 120+40)
			
			if creditsWarpSeq("introB", st.upperPlatform, pro, {1032,1044}, onMid=proc(){
				stage.target_camera_pos = sepos("introPanStart")
				camera_update_position()
			}) &&
			scmove(pro, {{922,940}, {428,938}}, 3.5, moveSprite=pro.sprites.dash) &&
			scmove(pro, {{430,754}}, curve=cu.easeIn) &&
			b{
			if creditsWarpSeq("introC", st.townHall, pro, {335,783}, onMid=proc(){camera_tracking_set(scfind("pro"))})
			{
				proc_call_delayed(proc(){cutscene_advance_dialogue()}, 1)
				return seq_close(.end)
			}
			}
			}
		}
		return seq_close()
	}

	m["hallArrival"] = proc() -> bool{
		if seq_open(){
			pro := scfind("pro")
			if seq_cue(0){
				camera_tracking_set(pro)
				phyllo := stageCharacter_make("phyllo", {336, 400}, .up)
				phyllo.facePlayer = .ifInteractedWith
				phyllo.stageInteractable.interactDialogue = di.intro
				estring_set(&phyllo.stageInteractable.interactDialogueLabel, "phyllo")
				dendro := stageCharacter_make("dendro", {336, 288})
				dendro.facePlayer = .ifInteractedWith
				dendro.stageInteractable.interactDialogue = di.intro
				estring_set(&dendro.stageInteractable.interactDialogueLabel, "dendro")
			}
			else if stageCharacter_move_seq(pro, {{336, 535}}){
				stageCharacter_facing_set("phyllo", .down)
				return seq_close(.end)
			}
		}
		return seq_close()
	}
	
	m["phylloRunsOff"] = proc() -> bool{
		if seq_open(){
			phyllo := stageCharacter_find("phyllo")
			podium := stageEntity_find("podium")
			if stageCharacter_move_seq(phyllo, {{336, 288}, podium.transform.pos - {37, 6}}, 75, .right) && seq_wait(50) && dialogue.auto_advance_time == -1{
				cutscene_advance_dialogue()
				return seq_close(.end)
			}
		}
		return seq_close()
	}

	m["mayorWalksDown"] = proc() -> bool{
		return stageCharacter_move_seq("dendro", {{336, 444}}, 110)
	}
	m["mayorStepsBack"] = proc() -> bool{
		return stageCharacter_move_seq("dendro", {{0, -16}}, 20, .none, true, true)
	}

	m["proAndMayorGetIntoPosition"] = proc() -> bool{
		if seq_open(){
			pro:=stageCharacter_find("pro")
			dendro:=stageCharacter_find("dendro")

			podium := stageEntity_find("podium")
			
			a:=stageCharacter_move_seq(pro, {{336, 274}}, 1.25)
			b:=stageCharacter_move_seq(dendro, {{336, 288}, {360, 240}, podium.transform.pos - {1, 12}}, 1.5, .down)
			c:=camera_pan_to_and_back_seq({336, 140}, 340, 0, 20) //pan to the stained glass
			if a&&b&&c{
				stageEntity_set_visible(podium, false)
				stageCharacter_sprite_set(dendro, sp.dendro_cutscene_ceremony_lookOver, sp.dendro_cutscene_ceremony_lookOverIdle)
				return seq_close(.end)
			}
		}
		return seq_close()
	}

	m["phylloHandsOverScript"] = proc() -> bool{
		if seq_open(){
			if seq_cue(0){
				stageEntity_set_visible(scfind("phyllo").stageEntity, false)
				audio_play(au.cutsceneDendroHandoff)
			}
			if stageCharacter_anim_seq("dendro", sp.dendro_cutscene_ceremony_handoff, sp.dendro_cutscene_ceremony_gripIdle){
				stageEntity_set_visible(scfind("phyllo").stageEntity, true)
				return seq_close(.end)
			}
		}
		return seq_close()
	}
	
	m["proSits"] = proc() -> bool{
		if seq_open(){
			pro := stageCharacter_find("pro")
			if seq_cue(0){
				stageCharacter_facing_set(pro, .down)
				audio_play(au.sitDown)
			}
			if stageCharacter_anim_seq(pro, sp.pro_meditation_sitDown, sp.pro_meditation_idleEyesOpen){
				return seq_close(.end)
			}
		}
		return seq_close()
	}

	m["proMeditates"] = proc() -> bool{
		if seq_open(){
			pro := stageCharacter_find("pro")
			if seq_cue(0){ 
				stageCharacter_sprite_set(pro, sp.pro_meditation_closeEyes, sp.pro_meditation_idleBreathing)
			}
			if meditation_start_seq(pro){ 
				return seq_close(.end)
			}
		}
		return seq_close()
	}
	m["proConnects"] = proc() -> bool{
		if seq_open(){
			if seq_cue(0){
				audio_play(au.dioramaEntryFlash)
			}
			t := int(time_convert(2.1, .seconds, .frames))
			if seq_cue(&t,60){
				seq_draw(proc(){
					draw_rect_fullscreen(COLOR_WHITE, seq_map(1,0,cu.easeInStrong))
				})
			}
			
			if seq_cue(t) do music_set(au.eventMeditation)
			if seq_cue(&t,60){
				bg := cofind(MeditationBG, 0)
				bg.perlinStrength = seq_map(0,0.36)
			}

			if seq_cue(t) do return seq_close(.end)
		}
		return seq_close()
	}

	m["proOpensEyes"] = proc() -> bool{
		if seq_open(){
			if stageCharacter_anim_seq("pro", sp.pro_meditation_openEyes, sp.pro_meditation_idleEyesOpen) && seq_wait(20){
				return seq_close(.end)
			}
		}
		return seq_close()
	}

	m["startNameEntry"] = proc() -> bool{
		te := entity_make(TextEntry)
		te.invalidOutputs = player_characters.player_name_attempts[:]
		te.onCompletion = proc(output:string){
			flag("player", string_prettify(output))
			append(&player_characters.player_name_attempts, string_lower(output))
			dialogue_open(di.intro, "name")
		}

		return true
	}

	m["proStopsMeditating"] = proc() -> bool{
		clear(&player_characters.player_name_attempts)
		return meditation_end_seq(stageCharacter_find("pro"))
	}

	m["mayorSlamsPodium"] = proc() -> bool{
		return stageCharacter_anim_seq("dendro", sp.dendro_cutscene_ceremony_dendroSlam, sp.dendro_cutscene_ceremony_gripIdle, spriteFrameCallbacks={
			{sp.dendro_cutscene_ceremony_dendroSlam, 3, proc(){ audio_play(au.cutsceneDendroSlam); camera_shake(8, {0,1}) }}
		})
	}

	m["proStandsUp"] = proc() -> bool{
		if seq_open(){
			pro := stageCharacter_find("pro")
			a := stageCharacter_anim_seq(pro, sp.pro_meditation_standUp, nil)
			b := stageCharacter_anim_seq("dendro", sp.dendro_cutscene_ceremony_gripToIdle, nil)
			if b{
				stageEntity_set_visible(stageEntity_find("podium"), true)
				if a{
					//replace "intro" pro with proper player entity
					// player := entity_make(Player)
					// player.transform.pos = pro.transform.pos
					// stageCharacter_facing_set(player.stageCharacter, pro.facing)
					// entity_destroy(pro)
					game_save(di.intro, "loadIntoIntro")
					return seq_close(.end)
				}
			}
		}
		return seq_close()
	}

	m["loadIntoIntro"] = proc() -> bool{
		podium := stageEntity_find("podium")
		phyllo := stageCharacter_make("phyllo", podium.transform.pos - {37, 6}, .right)
		dendro := stageCharacter_make("dendro", podium.transform.pos - {1, 12}, .down)
		phyllo.stageInteractable.interactDialogue = di.intro
		estring_set(&phyllo.stageInteractable.interactDialogueLabel, "phyllo")
		dendro.stageInteractable.interactDialogue = di.intro
		estring_set(&dendro.stageInteractable.interactDialogueLabel, "dendro")
		return true
	}

	m["proWalksIntoLobby"] = proc()->bool{
		if seq_open(){
			backWall := stageEntity_find("lobbyBackWall")
			if scmove("pro", {backWall.transform.pos - {0,8}, backWall.transform.pos + {0,5}}){
				t := seq_timestamp()
				if seq_cue(t) do scface("pro", .up)
				if seq_cue(t+17) do audio_play(au.doorCloseIntro)
				if seq_cue(t+25) do spriter_set(backWall.spriter, sp.lobbyBackWall, 1, true)
				if seq_cue(t+50){
					scface("pro", .down)
					return seq_close(.end)
				}
			}
		}
		return seq_close()
	}

	m["exitedTownHall"] = proc()->bool{
		music_set(au.stromaVillage)
		audio_parameter_set(au.stromaVillage, "InPrologue", 0)
		audio_parameter_set(au.stromaVillage, "StartAtClimax", 1)
		flag("introDone")
		game_save()
		return true
	}
	
}