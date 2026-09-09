package massimodin //@nested-tags:cutscenes

CutsceneSystem :: struct{
	enabled:bool,
	_cutscenes_map:map[string]CutsceneMap,
	current:CutsceneProc,
	name:string,
	interruptDialogue:bool
}
cutscene:^CutsceneSystem

CutsceneProc :: #type proc() -> bool
CutsceneMap :: map[string]CutsceneProc

_cutscene_system_init :: proc(){
	cutscene = new(CutsceneSystem)

	init(&cutscene._cutscenes_map, assets.allocator)
}

_cutscene_system_update :: proc(){
	if cutscene.current != nil && cutscene.current(){
		cutscene.current = nil
		cutscene.name = ""
		if cutscene.interruptDialogue && dialogue.current != nil{
			cutscene_advance_dialogue()
		}
	}
}

//Retrieve a cutscene namespace. Makes it if it doesn't exist.
cutscene_namespace :: proc(name:union{string,^Dialogue}) -> ^CutsceneMap{
	name_:string
	switch n in name{
		case string: name_ = n
		case ^Dialogue: name_ = n.name
	}
	if name_ not_in cutscene._cutscenes_map do cutscene._cutscenes_map[name_] = make(CutsceneMap, assets.allocator)
	return &cutscene._cutscenes_map[name_]
}

_cutscenes_reload :: proc(){
	m := cutscene_namespace("_default")
	m["walkBack"] = proc() -> bool{
		player := cofind(Player, 0).stageCharacter
		return stageCharacter_move_seq(player, {cardinal_to_vec2(player.facing)*16}, 1.5, .none, true)
	}
	m["combatEnd"] = proc()->bool{ 
		return combat_end_seq() 
	}
	m["cameraPan"] = proc()->bool{
		return camera_pan_to_seq(camera.default_pan_cutscene_target, camera.default_pan_cutscene_duration, key="default_camera_pan")
	}
	m["dialogueHDOverlayFade"] = proc()->bool{
		if seq_open(){
			if seq_cue(DIALOGUE_HD_OVERLAY_TRANSITION_DURATION+12){
				if dialogue.hd_overlay_fade_interrupt_disable_flag{
					dialogue.hd_overlay_enabled = false
					dialogue.hd_overlay_fade_interrupt_disable_flag = false
				}
				dialogue_reset_display_settings()
				return seq_close(.end)
			}
		}
		return seq_close()
	}
	m["gameOver"] = proc()->bool{
		if seq_open(){
			if seq_cue(0){
				cutscene.enabled = true
			}

			waitTime := flag_check("instantDeath")?0:90
			flashTime :: 75
			postFlashTime :: 35
			fadeInTime :: 30
			t := waitTime+flashTime+postFlashTime
			if seq_cue(t) do titleScreen_goto()
			if seq_cue(t+fadeInTime){
				flag("instantDeath", "0")
				proc_call_delayed(proc(){
					cutscene.enabled = false
					dialogue_open(di.gameOver)
				},1)
				return seq_close(.end)
			}
			else{
				seq_draw(proc(){
					waitTime := flag_check("instantDeath")?0:90
					rect := Rect{0,display_size()}
					t := waitTime
					if seq_cue(&t, flashTime) do draw_rect(rect, COLOR_RED, seq_map(1,0, cu.easeOutStrong))
					t += postFlashTime
					if seq_cue(&t, fadeInTime){
						draw_rect(rect, COLOR_BLACK, seq_map(1,0))
					}
				})
			}
		}
		return seq_close()
	}

	m["revivalStart"] = proc()->bool{
		if seq_open(){
			if seq_cue(0){
				if audio.music != nil do audio_pause(audio.music, true)

				audio_play(au.connectionFlashImmediate)
				audio_background_add(au.interferenceDrone)
				audio_parameter_set(au.interferenceDrone, "fadeIn", 0.6)
			}
			
			if transition_seq(proc(){
				camera_tracking_set(combat.selected_unit.stageCharacter._ptr)
				camera_update_position()
				camera_tracking_set()

				meditation_start_seq(combat.selected_unit.stageCharacter, 0, 0)
				cofind(MeditationBG,0).perlinStrength = 0.18
			}, 100, .hardCutToFade, COLOR_WHITE){
				return seq_close(.end)
			}
		}
		return seq_close()
	}
	m["revivalSuccess"] = proc()->bool{
		if seq_open(){
			if seq_cue(0){
				audio_parameter_set(au.interferenceDrone, "fadeIn", 0)
			}
			if audio.music != nil && seq_cue(86, 85+30) do audio_volume_set(audio.music, seq_map(0, 1))
			
			charSprites := &combat.selected_unit.sprites
			if transition_seq(proc(){
				audio_background_remove(au.interferenceDrone, false)
				if audio.music != nil {
					audio_pause(audio.music, false)
					audio_volume_set(audio.music, 0)
				}
				meditation_end_seq(combat.selected_unit.stageCharacter, 0, 0)
				combat.time_stop_mode = .disabled
			}, [3]int{70,30,15}, .fade, COLOR_WHITE) &&
			seq_wait(40) &&
			scanim(combat.selected_unit.stageCharacter, charSprites.koGetup, charSprites.idle)
			{
				combat.selected_unit.unitState = .alive
				combat.selected_unit.hp = max(combat.selected_unit.maxHp/2, 1)
				proc_call_delayed(combat_resolve_start, 1)
				return seq_close(.end)
			}
		}
		return seq_close()
	}
	m["revivalFailure"] = proc()->bool{
		if seq_open(){
			if seq_cue(0){
				audio_parameter_set(au.interferenceDrone, "fadeIn", 0)
			}
			if audio.music != nil && seq_cue(86, 85+30) do audio_volume_set(audio.music, seq_map(0, 1))

			charSprites := &combat.selected_unit.sprites
			if transition_seq(proc(){
				audio_background_remove(au.interferenceDrone, false)
				if audio.music != nil {
					audio_pause(audio.music, false)
					audio_volume_set(audio.music, 0)
				}
				meditation_end_seq(combat.selected_unit.stageCharacter, 0, 0)
			}, [3]int{70,30,15}, .fade, COLOR_BLACK) &&
			seq_wait(40)
			{
				proc_call_delayed(combat_resolve_start, 1)
				return seq_close(.end)
			}
		}
		return seq_close()
	}

	m["restStart"] = proc()->bool{
		if seq_open(){
			onMid :: proc(){
				centerPos := sepos("restCenter")
				chars := coall(StageCharacter)
				for &char in chars{
					stageCharacter_pos_set(&char, sepos(format("%sRestPos", char.initID)))
					switch char.initID.s{
						case "pro": stageCharacter_sprite_set(&char, sp.pro_cutscene_lean_idle)
						case "minima": stageCharacter_sprite_set(&char, sp.minima_cutscene_rest_loop)
					}
					scface_other(&char, centerPos)
				}
				camera_tracking_set()
				stage.target_camera_pos = sepos("restFocus")
			}
			if transition_seq(onMid, 50){
				if !entity_exists(RestMenu){
					entity_make(RestMenu)
					proc_call_delayed(proc(){cutscene.enabled = true}, 1)
				}
				return seq_close(.end)
			}
		}
		return seq_close()
	}

	m["restEnd"] = proc()->bool{
		if seq_open(){
			onMid :: proc(){ //rather than fiddle with positioning, just respawn player and followers
				entity_destroy(StageCharacter)

				centerPos := sepos("restCenter")
				p := entity_make(Player)
				transform_set(p.transform, centerPos + {0,64})
				scface(p.stageCharacter, .down)
				camera_tracking_set(p.stageCharacter._ptr)

				proc_call_delayed(proc(){game_save()}, 1) //save game after player array has settled
			}
			if transition_seq(onMid, 50){
				cutscene.enabled = false
				return seq_close(.end)
			}
		}
		return seq_close()
	}

	m["restTalkStart"] = proc()->bool{
		if seq_open(){
			onMid :: proc(){
				centerPos := sepos("restCenter")
				chars := coall(StageCharacter)
				for &char in chars{
					stageCharacter_pos_set(&char, sepos(format("%sRestTalkPos", char.initID)))
					switch char.initID.s{
						case "pro": stageCharacter_sprite_set(&char, sp.pro_meditation_idleEyesOpen)
						case "minima": stageCharacter_sprite_set(&char, sp.minima_cutscene_rest_loop)
					}
					scface_other(&char, centerPos)
				}
			}
			if transition_seq(onMid, 75) && seq_wait(50){
				return seq_close(.end)
			}
		}
		return seq_close()
	}

	m["popup"] = proc() -> bool{
		return !entity_exists(Popup)
	}

	m["interference"] = proc()->bool{
		return interference_seq(40)
	}

	m["demoReset"] = proc()->bool{
		return transition_seq(proc(){
			game_save_file_delete()
			titleScreen_goto()
		}, 120, .hardCutToFade)
	}

	_cutscenes_reload_combat()
	_cutscenes_reload_prologue_and_outro()
	_cutscenes_reload_intro()
	_cutscenes_reload_stroma_village()
	_cutscenes_reload_combat_tutorial()
	_cutscenes_reload_playtest()
	_cutscenes_reload_trailer()
	_cutscenes_reload_iris_forest()
	_cutscenes_reload_minima_encounter()
	_cutscenes_reload_consequence_encounter()
}

//Call at the end of a non-interrupting cutscene to advance the dialogue. If the dialogue does not advance automatically, use a label jump to interrupt from wherever you are.
//Can also be called at the end of an interrupting cutscene to jump to a specific label.
cutscene_advance_dialogue :: proc(keepAuto:=false, label:="", loc:=#caller_location){
	if DEBUG || label != "" do assert(dialogue.current != nil, "Tried to advance a dialogue within a cutscene with no active dialogue!")
	else{
		if dialogue.current == nil{
			printf("Warning! Tried to advance a dialogue within a cutscene with no active dialogue! Location: %v", loc)
			return
		}
	}

	dialogue_set_auto()
	if label != "" do dialogue_jump_to_label(label, !cutscene.interruptDialogue)
	else do dialogue_next_line()

	if keepAuto do dialogue_set_auto(-1)
}

cutscene_start :: proc(cutsceneID:string, namespace:string="", interruptDialogue:=true){
	csm:CutsceneMap	
	ok:bool
	if namespace != ""{
		csm = cutscene._cutscenes_map[namespace]
		ok = cutsceneID in csm
	}
	if !ok{
		csm = cutscene._cutscenes_map["_default"]
		ok = cutsceneID in csm
	}
	assertf(ok, "Cutscene '%s' not found in namespace '%s'!", cutsceneID, namespace)
	cutscene.name,cutscene.current = strmap_get(csm, cutsceneID)
	cutscene.interruptDialogue = interruptDialogue
	if interruptDialogue && dialogue.current != nil do dialogue_set_auto(-1)
}