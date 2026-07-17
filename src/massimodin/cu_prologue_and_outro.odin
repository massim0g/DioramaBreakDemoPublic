#+feature using-stmt
package massimodin //@nested-tags:cutscenes

_cutscenes_reload_prologue_and_outro :: proc(){
	m := cutscene_namespace(di.prologueAndOutro)

	m["prologueStart"] = proc()->bool{
		if seq_open(){
			if seq_cue(0){
				music_set(nil)
			}
			t:=40
			if seq_cue(t){
				dialogue.commands["steward"]({"l", "neutral"})
				dialogue.commands["steward"]({"r", "neutral"})
				dialogue.commands["hdPortrait"]({"both"})
			}
			t+=50
			if seq_cue(t){
				music_set(au.eventPrologue)
				return seq_close(.end)
			}
		}
		return seq_close()
	}

	m["meditationStart"] = proc()->bool{
		if seq_open(){
			titleScreen :^TitleScreen= cofind(TitleScreen, 0)
			using titleScreen
			if seq_cue(0){
				music_set(nil)
			}
			t:=0
			if seq_cue(&t, 30){
				entryPerlinAlpha = seq_map(0, 1)
			}

			if seq_cue(&t, 70){
				entryPerlinStrength = seq_map(0, MEDITATION_PERLIN_BASE_STR)
			}

			if seq_cue(t){
				meditationMode = true
				return seq_close(.end)
			}
		}
		return seq_close()
	}
	m["meditationFailed"] = proc()->bool{
		if seq_open(){
			titleScreen :^TitleScreen= cofind(TitleScreen, 0)
			using titleScreen
			if seq_cue(0){
				entryPerlinStrength = 0
				entryPerlinAlpha = 0
				entryTopLightAlpha = 1
				meditationMode = false
			}

			if seq_cue(2){
				entryTopLightAlpha = 0
				return seq_close(.end)
			}
		}
		return seq_close()
	}

	m["dioramaEntry"] = proc() -> bool{
		if seq_open(){
			titleScreen :^TitleScreen= cofind(TitleScreen, 0)
			using titleScreen

			if seq_cue(0){
				entryPerlinStrength = 0
				entryPerlinAlpha = 0
				entryTopLightAlpha = 1
				meditationMode = false
			}
			
			t:=95
			if seq_cue(2,t+5){
				entryTopLightAlpha = seq_map(1,0, cu.easeIn)
			}


			if seq_cue(t, t+72){
				entryShadowAlpha = seq_map(0, 0.5)
			}

			if seq_cue(t, t+140){
				entryRadialAlpha = seq_map(0, 0.4)
			}

			if seq_cue(t, t+500){
				entryRadialRadius = seq_map(100, 3840/3, cu.easeOut)
			}

			if seq_cue(t+150, t+500){
				entryTopLightAlpha = seq_map(0, 1)
			}

			if seq_cue(0, t+535){
				audio_volume_set(au.dioramaEntryBuzz, seq_map(0.5, 1))
			}

			if seq_cue(t+535){
				texture_group_load_block(groupNames=sprites.game_load_preloaded_texture_groups[:])
				stage_goto(st.prosRoom)
				proc_call_delayed(proc(){dialogue_open(di.intro, "wakeup")}, 1)
				return seq_close(.end)
			}
		}
		return seq_close()
	}

	m["demoContinues"] = proc()->bool{
		pro := scfind("pro")
		minima := scfind("minima")
		stageCharacter_pos_set(minima, pro.transform.pos - {48+64,0})
		scface(pro, .left)
		scface(minima, .right)
		return true
	}
	m["demoContinued"] = proc()->bool{
		flag("demoContinued")
		game_save()
		return true
	}

}