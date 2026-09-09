package massimodin //@nested-tags:cutscenes

timestop_start_seq :: proc()->bool{
	if seq_open(){
		if seq_cue(0){
			combat.time_stop_mode = .enabledWithEffect
			combat.time_stop_saturation = 1
			cutscene.enabled = true
			audio_play(au.combatTimeStop)
		}
		if seq_cue(25) && combat.current_step==0{
			units := combatUnits_get()
			for unit in units{
				if unit.unitType == .player do combat_grid_ripple(unit.stageCharacter.transform.pos)
			}
			audio_play(au.combatGridRipple)
		}
		duration :: 40
		if seq_cue(0, duration){
			if seq_time() != 0 do combat.time_stop_saturation = seq_map(0.66, 0.33)
			seq_draw(proc(){
				if seq_cue(0){
					tex_target_set(combat.time_stop_transition_bg)
					display_main_tex_draw()
					tex_target_reset()
				}
				tex_ghosts_draw(display_snapshot(), 4, 5, -1, 1/0.9, cu.easeInStrong, seq_time(), duration)
				ringStart :: 3
				if seq_cue(ringStart, duration/2+ringStart){
					r := seq_map(0,DISPLAY_RADIUS, cu.easeInStrong)
					tex_target_set(combat.time_stop_transition_maskA)
					tex_draw(combat.time_stop_transition_bg, 0,0)
					blendmode_set(.subtract)
					sprite_draw_ex(sp.circle256, DISPLAY_SIZE/2, scale=r*2/256)
					blendmode_set(.blend)
					tex_target_reset()
					tex_draw(combat.time_stop_transition_maskA,0,0)
					// fuzzy_circle_draw(Circle{DISPLAY_SIZE/2, r}, 0.8, 1, 18)
					t := f32(seq_time())
					fuzzy_circle_draw(Circle{DISPLAY_SIZE/2, r}, 0.8, max(4/(t/2.5), 0.75), max(72/(t/2.5), 0.75))

					if (seq_time() % 3 == 0) {
						particles_emit_circle(particle_type(
							sp.glassBreakParticle, 
							duration/4, duration/2,
							3, 10, cu.easeOut_inv,
							0, true,
							alphaCurve=cu.easeOutStrong_inv, angleMatchesDir=true
						), random_range(24, 32), layer_depth(.ui), Circle{DISPLAY_SIZE/2, r+48}, 4, false)
					}

				}
				if seq_cue(0){
					draw_rect_fullscreen(COLOR_WHITE)
					sprite_draw_ex(sp.shineSilhouette, DISPLAY_SIZE/2, color=COLOR_BLACK)
				}

			}, layer_depth(.stageTop) - 1, false) //in front of all stage content, behind the UI layers
		}
		if seq_cue(24) do ui_cue("timeStopped")
		if seq_cue(duration+1){
			cutscene.enabled = false
			return seq_close(.end)
		}
	}
	return seq_close()
}

timestop_end_seq :: proc()->bool{
	if seq_open(){
		duration :: 20
		if seq_cue(0){
			if combat.time_stop_mode == .disabled{
				return seq_close(.end)
			}
			cutscene.enabled = true
			audio_play(au.combatTimeStart)
		}
		if seq_cue(0, duration){
			seq_draw(proc(){
				if seq_cue(0){
					tex_target_set(combat.time_stop_transition_bg)
					display_main_tex_draw()
					tex_target_reset()
					combat.time_stop_saturation = 1
					combat.time_stop_mode = .disabled
				}
				if seq_cue(0, duration){
					r := seq_map(DISPLAY_RADIUS, 0, cu.easeOutStrong)
					tex_target_set(combat.time_stop_transition_maskB, clear=false)
					draw_clear()
					blendmode_set(.subtract)
					sprite_draw_ex(sp.circle256, DISPLAY_SIZE/2, scale=r*2/256)
					blendmode_set(.blend)
					tex_target_set(combat.time_stop_transition_maskA)
					tex_draw(combat.time_stop_transition_bg, 0,0)
					tex_ghosts_draw(combat.time_stop_transition_bg, 4, 5, -1, 0.9, cu.easeOutStrong, seq_time(), duration)
					blendmode_set(.subtract)
					tex_draw(combat.time_stop_transition_maskB, 0, 0)
					blendmode_set(.blend)
					tex_target_reset(2)
					tex_draw(combat.time_stop_transition_maskA,0,0)
					// fuzzy_circle_draw(Circle{DISPLAY_SIZE/2, r}, 0.8, 1, 16)
					fuzzy_circle_draw(Circle{DISPLAY_SIZE/2, r}, 0.8, max(2/(duration-cast(f32)seq_time()), 1), max(32/(duration-cast(f32)seq_time()), 16))

					// if seq_cue(duration/4) {
					// 	particles_emit_circle(particle_type(
					// 		sp.glassBreakParticle, 
					// 		duration/2, duration,
					// 		20, 30, cu.easeIn_inv,
					// 		0, true,
					// 		alphaCurve=cu.easeOutStrong_inv, angleMatchesDir=true
					// 	), random_range(24, 32), -INF, Circle{DISPLAY_SIZE/2, r}, 0, 4, true)
					// }
				}
			})
		}
		if seq_cue(duration+1){
			cutscene.enabled = false
			return seq_close(.end)
		}
	}
	return seq_close()
}

_cutscenes_reload_combat :: proc(){
	m := cutscene_namespace("_default") //using the default namespace since these are common effects that will be used in many places

	m["timestopStart"] = proc()->bool{
		return timestop_start_seq()
	}

	m["timestopEnd"] = proc()->bool{
		return timestop_end_seq()
	}
}