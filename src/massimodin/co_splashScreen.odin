#+feature using-stmt
package massimodin //@nested-tags:_components/

SplashScreen :: struct{
	using base:RenderComponentBase,
	tease:bool,
	done:bool
}

splash_shine_seq :: proc(pos:Vec2, key:ImKey=#caller_location) -> bool{
	if seq_open(key){
		angle := random_f(360) + choose([]f32{0, 45})
		alpha1::115./255.
		alpha2::57./255.
		alpha3::222./255.
		if seq_cue(0){
			draw_color(COLOR_WHITE, 115)
			draw_circle(pos, 152)
			audio_play(au.splashShine)
		}
		if seq_cue(1){
			draw_color(COLOR_WHITE, 115)
			draw_circle(pos, 184)
			draw_rings(pos, {184, 152}, alphas={alpha1, alpha1})
			sprite_draw_ex(sp.splashShine, pos, angle=angle, alpha=alpha1)
		}
		if seq_cue(2){
			draw_rings(pos, {194, 152}, alphas={alpha2, alpha2})
			draw_rings(pos, {194, 184}, alphas={alpha3, alpha3})
			sprite_draw_ex(sp.splashShine, pos, 0, angle=angle, alpha=alpha2)
			sprite_draw_ex(sp.splashShine, pos, 1, angle=angle, alpha=alpha3)
		}
		if seq_cue(3){
			draw_rings(pos, {194, 184}, alphas={alpha3, alpha3})
			sprite_draw_ex(sp.splashShine, pos, 1, angle=angle, alpha=alpha3)
		}
		if seq_cue(4){
			return seq_close(.end)
		}
	}
	return seq_close()
}

_splashScreen_process_event :: proc(base:^ComponentBase, event:Event, overrideDisabled:=false){
if(!overrideDisabled && event in base.disabledEvents) do return
last_context := entities.context_component
defer cowith(last_context)
cowith(base)
self := cast(^SplashScreen)base
using self
#partial switch event{
case .init:
case .drawEnd:
	if tease{
		seq_open()
		region := Rect{0, DISPLAY_SIZE_HD}
		rect_resize_in_place(&region, -region.size*0.05)
		
		t := 5
		n :: 5
		it :: 6
		for i in 0..<it{
			if seq_time_above(&t, 2){ random_set_seed(u64((i+1)*100+n)); splash_shine_seq(region.pos + (region.size/(it-1))*f32(i) + vec2_random()*random_range(0.,250.), imkey_combine(i))}
		} 
		if mouse_pressed(.LEFT) do seq_close(.end)
		else do seq_close()
		return
	}


	if !done{
		seq_open()
			t := 90
			
			if seq_time_above(&t, 3){random_set_seed(58); splash_shine_seq({760, 982})}
			if seq_time_above(&t, 3){random_set_seed(59); splash_shine_seq({980, 1190})}
			if seq_time_above(&t, 3){random_set_seed(60); splash_shine_seq({1456, 982})}
			if seq_time_above(&t, 3){random_set_seed(61); splash_shine_seq({1942, 1210})}
			if seq_time_above(&t, 6){random_set_seed(62); splash_shine_seq({2393, 1132})}
			//if seq_time_above(&t, 15) do splash_shine_seq({2920, 1018})
			if seq_cue(t-31) do audio_play(au.splashShineBig)
			if seq_time_above(&t){
				//if time.frame%2 == 0 do splash_shine_seq({2788, 988})
				sprite_draw(sp.splashTitle, DISPLAY_SIZE_HD/2)
				if seq_cue(t, t+72){
					//draw_rect(camera_rect(), COLOR_WHITE, alpha=seq_map(1,0))
				}
				else{
					done = true
					seq_close(.end)
					return
				}
			}
			else if seq_cue(90,t) do sprite_draw_ex(sp.splashTitle, DISPLAY_SIZE_HD/2, 1, color=COLOR_WHITE, alpha=seq_map(0,1))
		seq_close()
	}
	else{
		sprite_draw(sp.splashTitle, DISPLAY_SIZE_HD/2)
		//if mouse_pressed(.LEFT) do done = false
	}
}}
