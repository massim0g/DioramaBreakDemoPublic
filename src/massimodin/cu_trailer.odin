#+feature using-stmt
package massimodin //@nested-tags:cutscenes

_cutscenes_reload_trailer :: proc(){
	m := cutscene_namespace("trailer")
	
	m["teaserSetup"] = proc()->bool{
		return transition_seq(proc(){audio_play(au.teaserPianoSting)}, 130)
	}

	m["teaserDioramaEntry"] = proc() -> bool{
		if seq_open(){
			titleScreen :^TitleScreen= cofind(TitleScreen, 0)
			using titleScreen

			if seq_cue(0){
				// dialogue.hd_portraits_prev = dialogue.hd_portraits
				// dialogue.hd_portraits = nil
				// ui_cue("dialogueHDFade")

				audio_play(au.dioramaEntryBuzz)
			}

			if seq_cue(0, 72){
				entryShadowAlpha = seq_map(0, 0.5)
			}

			if seq_cue(0, 140){
				entryRadialAlpha = seq_map(0, 0.4)
			}

			if seq_cue(0, 180){
				entryRadialRadius = seq_map(100, 3840/3, cu.easeOutThenBurst)
			}

			if seq_cue(170, 180){
				entryTopLightAlpha = seq_map(0, 1)
			}

			if seq_cue(180-128) do audio_play(au.dioramaEntryFlash)

			t:=230
			if seq_cue(0,180) do audio_volume_set(au.dioramaEntryBuzz, seq_map(0,1, cu.easeOut))
			if seq_cue(180,202) do audio_volume_set(au.dioramaEntryBuzz, seq_map(1,0))
			if seq_cue(202) do audio_stop(au.dioramaEntryBuzz)


			if seq_cue(t){
				entity_destroy(titleScreen)
				display.hd_enabled = false
				stage.target_camera_pos = DISPLAY_SIZE/2
				spriteEffect_make(sp.continentBG, {-84, 270}, duration=INF)
				bottomClouds := spriteEffect_make(sp.continentBGClouds, {DISPLAY_SIZE.x/2, 270}, -DEPTH_MAX, duration=INF)
				entity_persistent_set(bottomClouds.entity, true)
				dialogue.hd_portraits_prev = DialogueHDPortrait{}
				dialogue.hd_portraits = DialogueHDPortrait{}
				random_set_seed(0)

				for i in 0..<20{
					parallaxScale := random_range(0.5, 0.9)
					e := spriteEffect_make(choose([]^Sprite{sp.cloudA, sp.cloudB, sp.cloudC, sp.smallCloudA, sp.smallCloudB, sp.smallCloudC}), Vec2{random_range(0, DISPLAY_SIZE.x), DISPLAY_SIZE.y+60}, -parallaxScale, 215, scale={parallaxScale*random_range(1.,6.), parallaxScale*0.5}, alpha=0.5)
					spread :: 100.
					e.startPos.x = parallaxScale
					e.startPos.y = random_range(-spread, spread)
				}
			}

			if seq_cue(&t, 45){
				stage.backgroundColor = color_lerp(COLOR_WHITE, color_hex(0xeff8f8), seq.cue_prog)
			}

			if seq_cue(t-22) do audio_play(au.fallingWind)
			if seq_cue(t-22, t) do audio_volume_set(au.fallingWind, seq_map(0,1))

			continent:=spriteEffect_find(sp.continentBG, true)
			bottomClouds:=spriteEffect_find(sp.continentBGClouds, true)
			scrollStartPos :: Vec2{620,-3800}
			if seq_cue(t+170/4-46) do audio_play(au.continentWooshIn)
			if seq_cue(t+170/2) do stage.backgroundColor = color_hex(0x85c2e0)

			if seq_cue(t, t+170+30){
				bottomCloudsH := sp.continentBGClouds.size.y
				bottomClouds.transform.y = seq_map(bottomCloudsH*3,-bottomCloudsH*1.5, cu.easeInOutStrong) + DEPTH_MAX
				if stage.loaded == st.lowerArea{
					bottomClouds.transform.pos.x = stage.target_camera_pos.x
					bottomClouds.transform.pos.y += stage.camera_pos.y
				}
			}
			if seq_cue(&t, 170){
				bgH := sp.continentBG.size.y
				continent.transform.y = seq_map(bgH,-bgH, cu.easeInOutStrong)

				effects :[]SpriteEffect= coall(SpriteEffect)
				for e in effects{
					if e.transform.scale.y != 1{
						dist := bgH/(1-e.startPos.x)
						e.transform.y = seq_map(DISPLAY_SIZE.y/2+dist/2, DISPLAY_SIZE.y/2-dist/2, cu.easeInOutStrong) + e.startPos.y
					} 
				}

				if roll(1./40.) && seq_time()<t-30{
					cloud := spriteEffect_make(choose([]^Sprite{sp.cloudA, sp.cloudB, sp.cloudC, sp.smallCloudA, sp.smallCloudB, sp.smallCloudC}), Vec2{random_range(0, DISPLAY_SIZE.x), DISPLAY_SIZE.y+60+DEPTH_MAX}, -DEPTH_MAX, 30, scale={random_range(1., 3.), 1})
					cloud.mover.speed.y = -DISPLAY_SIZE.y/10
					proc_call_delayed(proc(){audio_play(au.cloudWoosh)}, 5)
				}
			}
			if seq_cue(t-170/4) do audio_play(au.continentWooshOut)


			if seq_cue(t){
				stage_load(st.lowerArea)
				debug.freeCamSpeed = 1 //allows camera to escape stage bounds
				pro := entity_make(Player).stageCharacter
				scface(pro, .left)
				pro.transform.pos = {700, 160}
				akro := stageCharacter_make("akro", {540, 160})
				stageCharacter_sprite_set(pro, sp.pro_combat_idle_side_ready)
				stageCharacter_sprite_set(akro, sp.akro_combat_idle_side_ready)
				stage.target_camera_pos = scrollStartPos
				stage.camera_pos = stage.target_camera_pos-DISPLAY_SIZE/2
			}
			if seq_cue(&t, 30){
				stage.backgroundColor = color_lerp(color_hex(0x85c2e0), color_hex(0x8ec3b0), seq.cue_prog)
			}

			if seq_cue(t-22) do audio_play(au.fallingWindWithLeaves)
			if seq_cue(t-22, t) do audio_volume_set(au.fallingWindWithLeaves, seq_map(0,1))
			if seq_cue(t) do audio_play(au.leavesTumble)
			
			if seq_cue(&t, 240){
				stage.target_camera_pos = seq_map(scrollStartPos, Vec2{620, 150}, cu.easeInStrong)
				stage.backgroundColor = color_lerp(color_hex(0x8ec3b0), color_hex(0x55776e), seq.cue_prog)
				foliage := coall_true(Foliage)
				sort(foliage, proc(a,b:^Foliage)->bool{
					return a.depth.(f32)<b.depth.(f32)
				})
				cols:[3][2]Color={
					{color_hex(0x28533a), color_hex(0x19342a)},
					{color_hex(0x387157), color_hex(0x334240)},
					{color_hex(0x4f8e82), color_hex(0x436057)}
				}
				for f,i in foliage{
					f.leafColor = color_lerp(cols[i][0], cols[i][1], seq.cue_prog)
					f.branchColor = f.leafColor
					for &node in f.updateNodes{
						foliage_node_update_colors(f, &node)
					}
				}
			}
			if seq_cue(t-22){
				audio_play(au.stromaAmbience)
				audio_play(au.stromaAmbienceWind)
			} 
			if seq_cue(t-22, t){
				audio_volume_set(au.fallingWind, seq_map(1,0))
				audio_volume_set(au.fallingWindWithLeaves, seq_map(1,0))
				audio_volume_set(au.stromaAmbience, seq_map(0,1))
				audio_volume_set(au.stromaAmbienceWind, seq_map(0,1))
			}
			if seq_cue(t){
				audio_stop(au.fallingWind)
				audio_stop(au.fallingWindWithLeaves)
			}

			t+=35
			if seq_cue(t){
				cutscene_advance_dialogue()
				return seq_close(.end)
			}


		}
		return seq_close()
	}

	m["teaserTitleDrop"] = proc()->bool{
		if seq_open(){
			if seq_cue(0){
				combat_start(au.battleTutorial)
				combat_grid_ripple(rect_center(stage.combatBounds))
				audio_play(au.combatGridRipple)
			}

			t:=110

			if seq_cue(t-50) do audio_play(au.cutToBlackBoom)
			if seq_cue(t){
				debug.freeCamSpeed = 0
				display.hd_enabled = true
				_stage_unload()

				entity_make(SplashScreen)
				audio_stop(au.stromaAmbience)
				audio_stop(au.stromaAmbienceWind)
			}

			t+=330

			if seq_cue(t){
				entity_destroy(SplashScreen)

			}

			t += 70

			if seq_cue(t){
				stage_load(st.lowerArea)
				pro := entity_make(Player).stageCharacter
				scface(pro, .left)
				pro.transform.pos = {700, 160}
				akro:=stageCharacter_make("akro", {540, 160})
				stageCharacter_sprite_set(pro, sp.pro_combat_stun_loop)
				stageCharacter_sprite_set(akro, sp.akro_combat_stun_loop)
				
				stage.target_camera_pos = Vec2{620, 150}
				stage.camera_pos = stage.target_camera_pos-DISPLAY_SIZE/2

				audio_play(au.stromaAmbience)
				audio_play(au.stromaAmbienceWind)
			}

			t+=80

			if seq_cue(t) do return seq_close(.end)
		}
		return seq_close()
	}

	m["teaserEnd"] = proc()->bool{
		audio_stop(au.stromaAmbience)
		audio_stop(au.stromaAmbienceWind)
		audio_play(au.cutToBlackBoomShort)
		display.hd_enabled = true
		_stage_unload()
		textEffect_make("Demo coming soon.", stage.target_camera_pos, 0, font=fo.notoSerif__144, alignment=0)
		return true
	}

	m["gameplayRevealEnding"] = proc()->bool{
		if seq_open(){
			if seq_cue(0){
				stage_load(st.IrisForestEdge)
				debug.freeCamSpeed = 0
				cutscene.enabled = true
				p := entity_make(Player)
				p.transform.pos = {605, 336}
				scface(p.stageCharacter, .up)
				camera_tracking_set(p.transform)
				stage.backgroundColor = color_hex(0x7AC5B0)
			}

			pro := scfind("pro")

			if scmove(pro, {{605, 224}}, 28, moveSprite=pro.sprites.dash){
				debug.freeCamSpeed = 1
				cammove(Vec2{stage.target_camera_pos.x,-2000}, 112, cu.easeOutLinearStart)
			} 

			t := 28
			if seq_cue(t+40, t+80) do stage.backgroundColor = color_lerp(color_hex(0x7AC5B0), COLOR_WHITE, seq.cue_prog)
			//if seq_cue(end-10) do transition_make(duration=20, color=COLOR_WHITE)

			if seq_cue(t+112){
				return seq_close(.end)
			}
		}
		return seq_close()
	}

	m["trailerDioramaEntry"] = proc()->bool{
		if seq_open(){
			if seq_cue(0){
				dialogue_close()
				titleScreen_goto()
				cutscene.enabled = true
			}

			t := 110
			if seq_cue(t){
				audio_background_add(au.dioramaEntryBuzz)
				audio_volume_set(au.dioramaEntryBuzz, 0)
			}
			if seq_cue(&t, 250){
				ts := cofind(TitleScreen, 0)
				ts.entryShadowAlpha = seq_map(0, 1)
			}
			if seq_cue(220, t){
				audio_volume_set(au.dioramaEntryBuzz, seq_map(0,0.6, cu.easeOutStrong))
			}
			
			if seq_cue(t){
				audio_stop_all()
				stage_load(st.new_stage)
				stage.target_camera_pos = DISPLAY_SIZE/2
				camera_update_position()
			}
			region := rectf_make_points(220,110,260,170)
			cells :: Vec2i{3,3}
			cellJitter :: 10
			cellSize := region.size/Vec2(cells)
			for n in 0..<cells.x*cells.y{
				random_set_seed(u64(n+10)*100)
				if seq_cue(t + random_range(0,8)){
					spd :f32= random_range(1.,3.)
					scale := random_range(0.8, 1./0.8)
					pos := region.pos + Vec2(grid_index_to_pos(cells, n))*cellSize + cellSize/2
					pos = ellipse_sample({pos, cellJitter})
					spriteEffect_make(sp.shineAnimated24pxFast, pos, 0, sprite_duration_f(sp.shineAnimated24pxFast)/spd, -1, spd, scale)
				}

			}

			t += 85

			bg,ok := cofind(MeditationBG, 0)
			if ok && seq_cue(t+50+70, t+50+70*2) do bg.perlinStrength = seq_map(0,0.36)
			
			if seq_time()>=t && 
				transition_seq(proc(){
					pro := entity_make(Player).stageCharacter
					transform_set(pro.transform, DISPLAY_SIZE/2)
					stageCharacter_sprite_set(pro, sp.pro_meditation_idleBreathing)
					meditation_start_seq(pro, 0, 0)
				}, [3]int{0,50,70}, .hardCutToFade) && 
				seq_wait(60*2)
			{
				dialogue_open(di.trailer, "ksTrailerIntro")
				return seq_close(.end)
			}
			
		}
		return seq_close()
	}

	m["proOpensEyes"] = proc()->bool{
		if seq_open(){
			if scanim("pro", sp.pro_meditation_openEyes, sp.pro_meditation_idleEyesOpen) && seq_wait(70){
				return seq_close(.end)
			}
		}
		return seq_close()
	}

	m["trailerStromaTransition"] = proc()->bool{
		if seq_open(){
			t:= 60
			if seq_time()>=t{
				transitionTimes := [3]int{70,15,70}
				transition_seq(proc(){
					dialogue_close()
					stage_load(st.townCenter)
				}, transitionTimes, .fade, COLOR_WHITE, true)
				t+=transitionTimes[0]+transitionTimes[1]
				if stage.loaded == st.townCenter && seq_cue(t,t+320){
					stage.target_camera_pos = seq_map(Vec2{1002,145}, Vec2{292,777})
				}
				t+=125
				a := seq_time()>=t && transition_seq(proc(){
					stage_load(st.prosNeighbourhood)
				}, 60, .fade, COLOR_WHITE)
				t+=30
				if stage.loaded == st.prosNeighbourhood && seq_cue(t,t+165){
					stage.target_camera_pos = seq_map(Vec2{274,276}, Vec2{776,325})
				}
				t+=135
				b := seq_time()>=t && transition_seq(proc(){
					stage_load(st.sidePlatform)
				}, 60, .fade, COLOR_WHITE)
				t+=30
				if stage.loaded == st.sidePlatform && seq_cue(t,t+165){
					stage.target_camera_pos = seq_map(Vec2{247,237}, Vec2{630,534})
				}
				t+=123
				c := seq_time()>=t && transition_seq(proc(){
					stage_load(st.upperPlatform)
					pro := entity_make(Player).stageCharacter
					transform_set(pro.transform, Vec2{434, 760})
					camera_tracking_set(pro.transform)
					scface(pro, .down)
					dialogue_open(di.trailer, "exitingTownHall")
				}, 60, .fade, COLOR_WHITE, true)
				if c{
					return seq_close(.end)
				}
			}
		}
		return seq_close()
	}


}