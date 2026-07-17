#+feature using-stmt
package massimodin //@nested-tags:cutscenes

//also includes prologue cutscenes
_cutscenes_reload_stroma_village :: proc(){
	m := cutscene_namespace(di.stromaVillage)

	m["proWalksToTrainingDummy"] = proc() -> bool{
		return scmove("pro", {{792, 676}})
	}

	m["trainingDummyFightStart"] = proc()->bool{
		combat_start(au.battleTutorial, success=nil_proc, failure=nil_proc, timeStopForceDisable=true)
		combat_event_callback_add(proc(self: ^CombatEventCallback, event: CombatEventData){
			#partial switch e in event{
				case CombatEventStarted:
					audio_parameter_set(combat.music_override, "Intensity", 0)
				case CombatEventDataActionResolved:
					if combatUnit_find("trainingDummy").hp <= 4 do dialogue_open(di.stromaVillage, "trainingDummyEnd")
				case CombatEventUpdate:
					pro := combatUnit_find("pro")
					if combat.selected_unit == pro do flag("playerSelectedInTrainingDummyFight", level=.temp)
					if combat.phase == .planning && !flag_check("playerSelectedInTrainingDummyFight"){
						ui_cue("dummyFightClickIndicator")
						t := ui_cue_time("dummyFightClickIndicator")
						if t >= 270{
							sr := combatUnit_stage_rect(pro)
							spriteEffect_make(sp.white1, sr.pos, 0, 1, scale=sr.size, color=color_hex(0xf5daab), alpha=wave(0, 0.5, 90, currentTime=f32(t)), depthKind=.floor)
						}
					}
			}
		})
		return true
	}

	m["cameraPanToFixture"] = proc() -> bool{
		if seq_open(){
			player := cofind(Player, 0)
			if camera_pan_to_seq(Vec2{637,158}, 60) && 
				seq_wait(60) &&
				camera_pan_to_seq(Vec2{374, 421}, 60) &&
				seq_wait(60) &&
				camera_pan_to_seq(player.transform.pos+camera.tracking_offset)
			{
				camera_tracking_set(player.transform)
				return seq_close(.end)
			}
		}
		return seq_close()
	}

	m["momWalksToGreetPro"] = proc()->bool{
		if seq_open(){
			if seq_cue(0){
				salvia := stageCharacter_make("salvia", {168,370}, .down)
				salvia.stageInteractable.interactDialogue = di.stromaVillage
				estring_set(&salvia.stageInteractable.interactDialogueLabel, "salviaInteract")
			}

			if stageCharacter_move_seq("salvia", {{168, 470}, {311, 539}, {311, 578}}, 1.5){
				return seq_close(.end)
			}
		}
		return seq_close()
	}

	m["salviaStepsBack"] = proc() -> bool{
		return stageCharacter_move_seq("salvia", {{0, -16}}, 20, .none, true, true)
	}
	m["salviaWalksToKitchen"] = proc() -> bool{
		return stageCharacter_move_seq("salvia", {{288, 456}}, 1.5)
	}

	m["sprinklerCutsceneStart"] = proc()->bool{
		if seq_open(){
			if seq_cue(0){
				scmake("trabe", {491,304}, .left)
				arb := scmake("arb", {579,295}, .left)
				arb.facePlayer = .ifInteractedWith
				arb.facingMode = .sideOnly //todo: arb up sprite
				{using arb.stageInteractable
					interactDialogue = di.stromaVillage
					estring_set(&interactDialogueLabel, "arbInteract")
				}
			}

			if cammove("stromaFixture") && seq_wait(60) && cammove("trabe"){
				return seq_close(.end)
			}
		}
		return seq_close()
	}

	m["sprinklerActivation"] = proc() -> bool{
		if seq_open(){
			if seq_cue(24) do audio_play(au.pressureHose)
			if transition_seq(proc(){
				scmake("hinoki", {444,319}, .right)
				scfind("trabe").transform.pos = {480,319}
				stageEntity_set_visible(stageEntity_find("stromaSprinklerExtended"), false)
				retracted := stageEntity_find("stromaSprinklerRetracted")
				stageEntity_set_visible(retracted, true)
				spriter_set(retracted.spriter, sp.mainTrunkHose_withHead)
			}, [3]int{24, 420, 24}){
				return seq_close(.end)
			}
		}
		return seq_close()
	}

	m["trabeRunsOff"] = proc() -> bool{
		if seq_open(){
			if seq_cue(36) do scface("hinoki", .left)
			trabe := scfind("trabe", true)
			if scmove(trabe, {{457,303}, {357,237}, {115,148}}) && transition_seq(proc(){
				camera_tracking_set(scfind("pro").transform)
				entity_destroy(scfind("trabe"))
				entity_destroy(scfind("hinoki"))
				stageEntity_group_set_visible("hinokiSitting", true)
				transform_set(scfind("arb").transform, Vec2{687,206})
				spriter_set(stageEntity_find("stromaSprinklerRetracted").spriter, sp.mainTrunkHose_noHead)
			}, [3]int{15,45,15}){
				cutscene_advance_dialogue()
				return seq_close(.end)
			}
		}
		return seq_close()
	}

	m["proWalksToArb"] = proc()->bool{
		if seq_open(){
			if scmove("pro", {{660, 209}}, 1.5, .right) && cammove("arb"){
				return seq_close(.end)
			}
		}
		return seq_close()
	}

	m["arbLeaves"] = proc()->bool{
		if seq_open(){
			if seq_cue(0){
				camera_tracking_set()
				entity_destroy(scfind("arb"))
			}
			if seq_wait(36) && cammove("pro"){
				return seq_close(.end)
			}
		}
		return seq_close()
	}

	m["proWalksToFibra"] = proc()->bool{
		return scmove("pro", {{290, 521}}, 1.5, .left)
	}

	m["floraRunsAway"] = proc()->bool{
		if seq_open(){
			flora := scfind("flora")
			if seq_cue(0){
				cofind(flora, Wanderer).disabled = true
			}
			if scmove(flora, {{225, 507}, {223, 447}}, 3., .left){
				return seq_close(.end)
			}
		}
		return seq_close()
	}

	m["hederaWalksToPro"] = proc()->bool{
		hedera := scfind("hedera")
		hedera.facePlayer = .disabled
		//return scmove(hedera, {{483, 505}}, 1.5, .right) todo: hedera walk anim
		return cammove(hedera)
	}

	m["apiComesOut"] = proc()->bool{
		if seq_open(){
			if cammove(stageEntity_find("stromaApiDoor")){
				if seq_cue(){
					//todo: door sound
					scmake("api", {384,258})
				}
				if seq_wait(30){
					return seq_close(.end)
				}
			}
		}
		return seq_close()
	}

	m["apiLeaves"] = proc()->bool{
		if seq_open(){
			if seq_cue(0){
				camera_tracking_set()
				entity_destroy(scfind("api"))
			}
			if seq_wait(36) && cammove("pro"){
				return seq_close(.end)
			}
		}
		return seq_close()
	}

	m["hederaWalksBack"] = proc()->bool{
		hedera := scfind("hedera")
		//if scmove(hedera, {{483, 505}}, 1.5, .right){
		if true{ //todo: hedera walk
			hedera.facePlayer = .always
			return true
		}
		return false
	}
}