package massimodin //@nested-tags:cutscenes

_cutscenes_reload_iris_forest :: proc(){
	m := cutscene_namespace(di.irisForest)

	m["proWalksAlongForestPath"] = proc()->bool{
		if seq_open(){
			if scmove("pro", {{470,125}, {415,127}, {294,168}, {162,126}, {96,176}}, endFacing=.down) && flag_check("doneTalking"){
				cutscene_advance_dialogue()
				return seq_close(.end)
			}
		}
		return seq_close()
	}

	m["monsterTease"] = proc()->bool{
		if seq_open(){
			if seq_cue(0){
				scmake("ranger", {stage.camera_pos.x-16,243}, .right, true)
			}

			if seq_wait(8) && scmove("ranger", {{-100, 0}}, 3., relative=true) do return seq_close(.end)
		}
		return seq_close()
	}

	m["monsterReveal"] = proc()->bool{
		firstMonsterCGSeq :: proc()->bool{
			if seq_open(){

				if flag_check("cgDone") do return seq_close(.end)
				
				seq_draw(proc(){

					moveSound :: proc(){
						inst := audio_play(au.footsteps)
						audio_parameter_set(inst, "groundSurface", f32(FootstepSurface.grass))
					}
					bodyFrame := 0
					bodyTransitionProg :f32= 1
					bodyOff :f32= 3

					t := 110
					shakeDur :: 12
					if seq_cue(t, t+shakeDur) do bodyOff = wave_triangle(1.5,0, shakeDur/2, 0, f32(seq_time()-t))
					for n in 0..<2{if seq_cue(t+n*shakeDur/2) do moveSound()}

					t += 120
					if seq_cue(t, t+shakeDur) do bodyOff = wave_triangle(1.5,0, shakeDur/2, 0, f32(seq_time()-t))
					for n in 0..<2{if seq_cue(t+n*shakeDur/2) do moveSound()}
					t+=90
					zoomStart := t
					
					if seq_cue(&t, 20) do bodyOff = seq_map(3,0)
					if seq_time()>=t do bodyOff = 0

					t += 106

					if seq_cue(t) do moveSound()
					if seq_time()>=t do bodyFrame+=1
					if seq_cue(&t, 12) do bodyTransitionProg = seq.cue_prog

					t += 30

					if seq_time()>=t do bodyFrame+=1
					if seq_cue(&t, 12) do bodyTransitionProg = seq.cue_prog

					letterBoxW :f32= 84
					if seq_cue(zoomStart, t){
						letterBoxW = seq_map(84, 111, cu.easeOut)
						audio_volume_set_event(au.irisAmbience, pow(10, seq_map(-60, 18)/20))
						audio_pitch_set(au.irisAmbience, seq_map(0.25, 0.33))
					}
					if seq_time() >= t do letterBoxW = 111

					t += 18

					if seq_cue(t) do flag("cgDone", level=.local)
					
					if bodyFrame == 2{
						sprite_draw_ex(sp.cg_firstMonster_bg, DISPLAY_SIZE/2, scale=1.5, alpha=bodyTransitionProg)
						if bodyTransitionProg < 1 do sprite_draw_ex(sp.cg_firstMonster_bg, DISPLAY_SIZE/2, alpha=1-bodyTransitionProg)
					}
					else do sprite_draw(sp.cg_firstMonster_bg, DISPLAY_SIZE/2)

					draw_rect(0,0,letterBoxW,DISPLAY_HEIGHT, COLOR_BLACK, 1)
					draw_rect(DISPLAY_WIDTH-letterBoxW,0,DISPLAY_WIDTH,DISPLAY_HEIGHT, COLOR_BLACK, 1)
					
					drawBody :: proc(frame:int, off:f32, alpha:f32){
						if frame == 0 do sprite_draw_ex(sp.cg_firstMonster_head0, DISPLAY_SIZE/2 + {0,off*1.5}, 0, alpha=alpha)
						sprite_draw_ex(sp.cg_firstMonster_body, DISPLAY_SIZE/2 + {0,off}, frame, alpha=alpha)
					}
					drawBody(bodyFrame, bodyOff, bodyTransitionProg)
					if bodyTransitionProg < 1 do drawBody(bodyFrame-1, bodyOff, 1-bodyTransitionProg)
				})
			}
			return seq_close()
		}

		if seq_open(){

			if scmove("pro", {{248,276}}, 2.){
			if seq_cue(){
				texture_group_load_block("cgs_ch1") //just in case the player never loaded to a checkpoint before, although these are certainly loaded by now
				audio_volume_set_event(au.fieldIris, 0)
				audio_volume_set_event(au.irisAmbience, 0)
			}
			if firstMonsterCGSeq(){
				audio_volume_set_event(au.irisAmbience, 1)
				audio_pitch_set(au.irisAmbience, 1)
				stageCharacter_sprite_set("ranger", sp.ranger_combat_idle_down_loop)
				cofind(Player, 0).combatUnit.skipStartAnim = true
				combat_start(deferStartAnim={.player})
				combat_event_callback_add(proc(self: ^CombatEventCallback, event: CombatEventData){
					#partial switch e in event{
						case CombatEventAIPlanningStart:
							if combat.current_step == 0 do combatAction_enqueue(e.unit, ca.wait)

						case CombatEventStarted:
							cofind(Player, 0).combatUnit.skipStartAnim = false
							dialogue_open(di.irisForest, "firstMonsterEncounterStarted")
							audio_volume_set_event(au.fieldIris, 1)
						case CombatEventDataHit:
							if e.target.hp == e.target.maxHp && e.target.initID.s == "pro" do dialogue_open(di.irisForest, "firstMonsterHit")
						case CombatEventEnded:
							flag("inIrisIntro", "2")
							audio_parameter_set(audio.music, "inIrisIntro", 2)
							dialogue_open(di.irisForest, "firstMonsterDefeated")
					}
				})
				return seq_close(.end)
			}
			} 
		}
		return seq_close()
	}

	m["minimaWalksToFixture"] = proc()->bool{
		if seq_open(){
			a := scmove("minima", {{845,520}, {888,460}}, 2.)
			b:=false
			if seq_wait(50) do b = scmove("pro", {{952,530}, {920,460}})
			if a&&b{
				return seq_close(.end)
			}
		}
		return seq_close()
	}

	vestBranchCost :: 1
	vestSproutCost :: 6
	bootsBranchCost :: 2
	bootsSproutCost :: 3
	
	m["fixVest"] = proc()->bool{
		if seq_open(){
			if transition_seq(){
				if seq_cue(){
					if inventory_get("rareWood") < vestBranchCost || inventory_get("stringSprout") < vestSproutCost{
						flag("craftFailed", level=.local)
						return seq_close(.end)
					}
				}

				item := item_ref_get("irisVest")
				if popup_seq(item_collect_message(item)){
					inventory_add(item)
					inventory_add("rareWood", -vestBranchCost)
					inventory_add("stringSprout", -vestSproutCost)
					flag("irisVestFixed")
					game_save()
					return seq_close(.end)
				}
			}
		}
		return seq_close()
	}
	m["fixBoots"] = proc()->bool{
		if seq_open(){
			if transition_seq(){
				if seq_cue(){
					if inventory_get("rareWood") < bootsBranchCost || inventory_get("stringSprout") < bootsSproutCost{
						flag("craftFailed", level=.local)
						return seq_close(.end)
					}
				}

				item := item_ref_get("windyBoots")
				if popup_seq(item_collect_message(item)){
					inventory_add(item)
					inventory_add("rareWood", -bootsBranchCost)
					inventory_add("stringSprout", -bootsSproutCost)
					flag("irisBootsFixed")
					game_save()
					return seq_close(.end)
				}
			}
		}
		return seq_close()
	}
	m["fixVestAndBoots"] = proc()->bool{
		if seq_open(){
			if transition_seq(){
				if seq_cue(){
					if inventory_get("rareWood") < vestBranchCost+bootsBranchCost || inventory_get("stringSprout") < vestSproutCost+bootsSproutCost{
						flag("craftFailed", level=.local)
						return seq_close(.end)
					}
				}

				vest := item_ref_get("irisVest")
				boots := item_ref_get("windyBoots")
				if popup_seq(item_collect_message(vest)) &&
				popup_seq(item_collect_message(boots))
				{
					inventory_add(vest)
					inventory_add(boots)
					inventory_add("rareWood", -(vestBranchCost+bootsBranchCost))
					inventory_add("stringSprout", -(vestSproutCost+bootsSproutCost))
					flag("irisVestFixed")
					flag("irisBootsFixed")
					game_save()
					return seq_close(.end)
				}
			}
		}
		return seq_close()
	}

	m["elevatorWait"] = proc()->bool{
		return transition_seq(duration=[3]int{15,100,15})
	}
}