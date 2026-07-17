#+feature dynamic-literals
package massimodin //@nested-tags:dialogue

import "core:reflect"
_dialogue_commands_init :: proc(){
	coms := &dialogue.commands
	coms["exit"] = proc(params:[]string) -> string{
		dialogue._exit_flag = true
		return ""
	}
	coms["x"] = coms["exit"]

	coms["player_x"] = proc(params:[]string) -> string{
		p,found := cofind(Player, 0)
		if(!found) do return "-1"
		return f32_to_string(p.transform.x)
	}

	//in characters per frame
	coms["speed"] = proc(params:[]string) -> string{
		if(len(params) == 0) do dialogue.typewriter_pause = dialogue.typewriter_pause_default
		else{
			newSpeed, ok := string_to_f32(params[0])
			assertf(ok, "Unable to parse given dialogue speed value '%s'", params[0])
			assert(newSpeed > 0, "Dialogue speed must be above 0!")
			dialogue.typewriter_pause = 1/newSpeed
		}
		return ""
	}

	coms["scale"] = proc(params:[]string) -> string{
		if(len(params) == 0) do dialogue.font = dialogue.font_unscaled
		else{
			newScale, ok := string_to_f32(params[0])
			assertf(ok, "Unable to parse given dialogue scale value '%s'", params[0])
			fontOtherSizes := fonts._font_sizeless_map[dialogue.font_unscaled.sizelessName]
			referenceSize := f32(dialogue.font_unscaled.size)*newScale
			dist:f32 = 9999
			nearestFont:^Font
			for f in fontOtherSizes{
				curDist := abs(referenceSize - f32(f.size))
				if(curDist < dist){
					dist = curDist
					nearestFont = f
				}
			}
			dialogue.font = nearestFont
		}
		return ""
	}
	coms["s"] = coms["scale"]

	coms["center"] = proc(params:[]string) -> string{
		if(len(params) == 0) do dialogue.text_centered = !dialogue.text_centered
		else{
			switch params[0]{
				case "true": dialogue.text_centered = true
				case "false": dialogue.text_centered = false
			}
		}
		return ""
	}

	coms["hdOverlay"] = proc(params:[]string) -> string{
		prev := dialogue.hd_overlay_enabled
		if(len(params) == 0) do dialogue.hd_overlay_enabled = !dialogue.hd_overlay_enabled
		else{
			switch params[0]{
				case "true": dialogue.hd_overlay_enabled = true
				case "false": dialogue.hd_overlay_enabled = false
			}
		}

		if dialogue.hd_overlay_enabled != prev{
			if (dialogue.text_rect == Rect{}){
				dialogue.hd_overlay_fade_interrupt_disable_flag = !dialogue.hd_overlay_enabled
				dialogue.hd_overlay_enabled = true
				cutscene_start("dialogueHDOverlayFade")
			}
			else do dialogue_reset_display_settings()
		}
		return ""
	}

	paramsToRect :: proc(params:[]string) -> Rect{
		r:[4]f32
		ok:bool
		for p,i in params{
			r[i],ok = string_to_f32(p)
			assertf(ok, "Error parsing f32 '%s' in dialogue rect!", p)
		}

		return rect_make_points(r[0], r[1], r[2], r[3])
	}

	coms["textRect"] = proc(params:[]string) -> string{
		if len(params) != 4{
			dialogue.text_rect = Rect{}
			return ""
		}
		
		dialogue.text_rect = paramsToRect(params)

		return ""
	}

	coms["uiHighlight"] = proc(params:[]string) -> string{
		if len(params) < 4{
			ui_highlight()
			return ""
		}

		stageCoords:=false
		if len(params) > 4 && params[4] == "true" do stageCoords = true

		ui_highlight(paramsToRect(params), stageCoords)

		return ""
	}

	coms["resetStyle"] = proc(params:[]string) -> string{dialogue_reset_display_settings(); return""}
	coms["rs"] = coms["resetStyle"]

	coms["pause"] = proc(params:[]string) -> string{
		pause, ok := string_to_f32(params[0])
		assertf(ok, "Unable to parse given dialogue pause value '%s'", params[0])
		dialogue.typewriter_pause_additional = pause*f32(FRAMERATE_TARGET)
		dialogue.unskippable = true
		return ""
	}
	coms["p"] = coms["pause"]

	coms["auto"] = proc(params:[]string) -> string{
		if len(params) == 0{
			dialogue_set_auto()
			return ""
		}

		autoAdvanceTime, ok := string_to_f32(params[0])
		assertf(ok, "Unable to parse given dialogue auto-advance time value '%s'", params[0])

		dialogue_set_auto(autoAdvanceTime)
		return ""
	}
	coms["a"] = coms["auto"]

	coms["unskip"] = proc(params:[]string) -> string{
		dialogue.unskippable = true
		return ""
	}

	coms["cutscene"] = proc(params:[]string) -> string{
		interrupt:bool
		if len(params) >= 2 && params[1] != "true"{
			interrupt = false
			dialogue_set_auto()
		}
		else do interrupt = true
		cutscene_start(params[0], dialogue.current.name, interrupt)
		return ""
	}
	coms["c"] = coms["cutscene"]

	coms["face"] = proc(params:[]string) -> string{
		char := stageCharacter_find(params[0])
		assertf(char != nil, "Could not find stage character '%s'!", params[0])
		switch params[1]{
			case "right", "0": stageCharacter_facing_set(char, .right)
			case "up", "1": stageCharacter_facing_set(char, .up)
			case "left", "2": stageCharacter_facing_set(char, .left)
			case "down", "3": stageCharacter_facing_set(char, .down)
			case: 
				targetPos:Vec2
				targetEnt := stageEntity_find(params[1])
				if targetEnt == nil{
					sc := scfind(params[1], true)
					assertf(sc != nil, "Invalid direction or character/entity ID '%s' for dialogue face!", params[1])
					targetPos = sc.transform.pos
				}
				else do targetPos = rect_center(stageEntity_draw_rect(targetEnt))

				stageCharacter_facing_set(char, vec2_cardinal(targetPos, char.transform.pos))
		}

		return ""
	}

	coms["facePlayer"] = proc(params:[]string) -> string{
		char := stageCharacter_find(params[0])
		assertf(char != nil, "Could not find stage character '%s'!", params[0])
		p,ok := cofind(Player, 0)
		assertf(ok, "Could not face player, player not found.")

		stageCharacter_facing_set(char, vec2_cardinal(p.transform.pos, char.transform.pos))
		return ""
	}

	coms["walkBack"] = proc(params:[]string) -> string{
		player := cofind(Player, 0).stageCharacter

		dialogue.commands["face"]({player.initID.s, params[0]})
		dialogue.commands["cutscene"]({"walkBack"})
		return ""
	}

	coms["hdPortrait"] = proc(params:[]string) -> string{
		newPortrait := DialogueHDPortrait{sp.nil_, sp.nil_}
		if len(params)>1 do newPortrait.head = sprite_find(params[1])
		if len(params)>2 do newPortrait.body = sprite_find(params[2])
		else if newPortrait.head != nil{
			newPortrait.body = sprite_find(string_concat({newPortrait.head.name, "_body"}, context.temp_allocator))
		}

		activeInd:int
		switch params[0]{
			case "0","l","left": activeInd=0
			case "1","r","right": activeInd=1
			case "2","b","both":
				if activeInd != 2{
					dialogue.hd_portrait_active = 2
					ui_cue("hdTalkerChanged")
				}
				return ""
			case "-1", "n", "none":
				dialogue.hd_portraits_prev = dialogue.hd_portraits
				dialogue.hd_portraits = DialogueHDPortrait{}
				dialogue.hd_portrait_active = 2
				ui_cue("hdPortraitChanged")
				return ""
		}

		if newPortrait.head == sp.nil_ do newPortrait.head = dialogue.hd_portraits[activeInd].head
		if newPortrait.body == sp.nil_ do newPortrait.body = dialogue.hd_portraits[activeInd].body

		if dialogue.hd_portraits[activeInd] != newPortrait{
			dialogue.hd_portraits_prev[activeInd] = dialogue.hd_portraits[activeInd]
			dialogue.hd_portraits[activeInd] = newPortrait
			ui_cue("hdPortraitChanged")
		}

		if activeInd != dialogue.hd_portrait_active{
			dialogue.hd_portrait_active = activeInd
			ui_cue("hdTalkerChanged")
		}

		return ""
	}
	coms["hdp"] = coms["hdPortrait"]

	coms["steward"] = proc(params:[]string) -> string{
		if len(params) == 1{
			dialogue.commands["hdPortrait"]({params[0]})
			return ""
		}

		stewardName:string
		switch params[0]{
			case "0","l","left": stewardName = "mrWindow"
			case "1","r","right": stewardName = "msWindow"
		}
		headName:string
		bodyName:string
		if len(params)>1 do headName = params[1]
		if len(params)>2 do bodyName = params[2]
		else do bodyName = headName
		
		dialogue.commands["hdPortrait"]({params[0], format("%s_%s", stewardName, headName), format("%s_%s_body", stewardName, bodyName)})

		return ""
	}

	coms["flag"] = proc(params:[]string) -> string{
		flagLevel := FlagLevel.local
		if len(params) > 2{
			ok:bool
			flagLevel,ok = reflect.enum_from_name(FlagLevel, params[2])
			assertf(ok, "Unknown flag level '%s'", params[2])
		}
		flag(params[0], len(params) > 1 ? params[1] : "1", flagLevel)
		return ""
	}
	coms["var"] = coms["flag"]

	coms["repoLine"] = proc(params:[]string) -> string{
		lines := dialogue_data(di.originalRepository).lines
		
		unseen:Bag(u16)
		if flag_exists("repoUnseen") do unseen.buf = base64_array_decode(flag_get("repoUnseen"), u16)
		else{
			bag_init(&unseen, 0, context.temp_allocator)
			reserve(&unseen.buf, len(lines))
			for i in 0..<len(lines){
				bag_add(&unseen, u16(i))
			}
		}

		lineInd := bag_get_random(&unseen)

		if len(unseen.buf) == 0 do flag_delete("repoUnseen")
		else do flag("repoUnseen", base64_array_encode(unseen.buf))

		return lines[lineInd]
	}

	coms["camPan"] = proc(params:[]string) -> string{
		if len(params) > 2{
			dur,ok := string_to_int(params[2])
			assertf(ok, "Could not parse camera pan duration '%s'!", params[1])
			camera.default_pan_cutscene_duration = dur
		}
		else do camera.default_pan_cutscene_duration = 48

		entTarget := stageEntity_find(params[0])
		if entTarget != nil{
			camera.default_pan_cutscene_target = rect_center(stageEntity_draw_rect(entTarget))
			cutscene_start("cameraPan")
			return ""
		}

		scTarget := scfind(params[0], true)
		assertf(scTarget != nil, "Could not find stage entity or character with id '%s' for camera pan!", params[0])

		camera.default_pan_cutscene_target = scTarget

		//interrupts and resets the camera pan cutscene for safety
		seq_reset("default_camera_pan")

		interrupt := true
		if len(params) >= 2{
			assertf(equals(params[1], "0", "1", "false", "true"), "Tried to pass a non-boolean value '%s' to camera pan interrupt flag!", params[1])
			if equals(params[1], "0", "false"){
				interrupt = false
				dialogue_set_auto()
			}
		}

		cutscene_start("cameraPan", interruptDialogue=interrupt)
		return ""
	}

	coms["camReset"] = proc(params:[]string) -> string{
		camera.default_pan_cutscene_duration = 48
		camera.default_pan_cutscene_target = cofind(Player, 0).stageCharacter._ptr
		cutscene_start("cameraPan")
		return ""
	}

	coms["gameLoad"] = proc(params:[]string) -> string{
		loaded := game_load_to_checkpoint()
		return loaded?"1":"0"
	}
	coms["gameSave"] = proc(params:[]string) -> string{
		game_save()
		return ""
	}

	coms["revivalAdvance"] = proc(params:[]string)->string{
		if combat.revival_questions_remaining == 0{
			guaranteed := flag_check("nextRevivalGuaranteed")
			flag("nextRevivalGuaranteed", "0")

			revivalPoints,_ := string_to_int(flag_get("revivalPoints"))

			if revivalPoints >= 1 do dialogue_jump_to_label("revivalSuccess")	
			else if guaranteed do dialogue_jump_to_label("revivalGuaranteedCatch")
			else do dialogue_jump_to_label("revivalFailure")
			
			return ""
		}

		combat.revival_questions_remaining -= 1
		dialogue_jump_to_label(bag_get_random(&combat.revival_label_bag))

		dialogue.typewriter_pause_additional = 60
		dialogue.unskippable = true

		return ""
	}

	coms["revivalEnd"] = proc(params:[]string)->string{
		if combat.revival_override_cutscene != ""{
			cutscene_start(combat.revival_override_cutscene, combat.revival_override_cutscene_namespace)
			combat.revival_override_cutscene = ""
		} 
		else if params[0] == "true" do dialogue.commands["cutscene"]({"revivalSuccess"})
		else do dialogue.commands["cutscene"]({"revivalFailure"})
		return ""
	}

	coms["restReset"] = proc(params:[]string)->string{
		rest_state_reset()
		return ""
	}

	coms["itemCollect"] = proc(params:[]string)->string{
		item := item_ref_get(params[0])
		inventory_add(item)
		popup_make_item_collect(item, false) //cutscene handles blocking
		dialogue.commands["cutscene"]({"popup"})
		return ""
	}
	
	coms["gamepad"] = proc(params:[]string)->string{
		return input_device() == .gamepad ? "1":"0"
	}
	
	//player name easter egg
	coms["pnee"] = proc(params:[]string)->string{
		cleanName := string_lower(flag_get("player"), context.temp_allocator)
		for p in params{
			if p == cleanName do return "1"
		}
		return "0"
	}

	coms["statsPush"] = proc(params:[]string)->string{
		steamworks_stats_update_and_push()
		return ""
	}

	coms["ksCheck"] = proc(params:[]string)->string{
		switch kickstarter_date_check(){
			case -1: return "pre"
			case 0: return "ongoing"
		}
		return "post"
	}
}

//on the backburner until I can figure out how to do verb constructions like "They/He seem/seems"
_dialogue_pronouns_map_init :: proc(){
	context.allocator = assets.allocator
	dialogue.pronounsMap = {
		"they"={.neutral="they",.male="he",.female="she"},
		"they're"={.neutral="they're",.male="he's",.female="she's"},
		"them"={.neutral="them",.male="him",.female="her"},
		"their"={.neutral="their",.male="his",.female="her"},
		"theirs"={.neutral="theirs",.male="his",.female="hers"},
		"themself"={.neutral="themself",.male="himself",.female="herself"},
	}
}
dialogue_command_call :: proc(name:string, params:..string){
	dialogue.commands[name](params)
}