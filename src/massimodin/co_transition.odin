#+feature using-stmt
package massimodin //@nested-tags:_components/

Transition :: struct{
	using base:RenderComponentBase,
	kind:TransitionKind,
	using blendData:BlendData,
	onMid:Callback,
	onEnd:Callback,
	done:^bool,
	durations:TransitionDuration,
	direction:Dir,
	useAddFade:bool,
	drawOnTop:bool
}

TransitionKind :: enum{
	fade,
	hardCut,
	hardCutToFade,
	combatStart,
	timestopStart,
	timestopEnd,
	wipe
}

TransitionDuration :: union{int,[3]int}

transition_make :: proc(onMid:=Callback{}, duration:TransitionDuration=30, kind:=TransitionKind.fade, color:=COLOR_BLACK, drawOnTop:=false, dir:=Dir.right) -> ^Transition{
	tr := entity_make(Transition)
	tr.onMid = onMid
	tr.durations = duration
	tr.kind = kind
	tr.color = color
	tr.drawOnTop = drawOnTop
	tr.direction = dir
	return tr
}
transition_seq :: proc(onMid:=Callback{}, duration:TransitionDuration=30, kind:=TransitionKind.fade, color:=COLOR_BLACK, drawOnTop:=false, dir:=Dir.right, key:ImKey=#caller_location) -> bool{
	done:^bool
	if seq_open(&done, key){
		if seq_cue(0){
			tr := transition_make(onMid, duration, kind, color, drawOnTop, dir)
			tr.done = done
		}

		if done^ do return seq_close(.end)
	}

	return seq_close()
}

_transition_process_event :: proc(base_:^ComponentBase, event:Event, overrideDisabled:=false){
if(!overrideDisabled && event in base_.disabledEvents) do return
last_context := entities.context_component
defer cowith(last_context)
cowith(base_)
self := cast(^Transition)base_
using self
#partial switch event{
case .init:
	blendmode = .blend
	entity_persistent_set(entity, true)
	depth = layer_depth(.stageTop) - 1
	durations = 30
	useAddFade = true
	
case .update:
	doEnd :: proc(using self:^Transition){
		entity_destroy(entity)
		if done != nil do done^ = true
		seq_close(.end)
		callback_call(onEnd)
	}
	switch kind{
		case .combatStart, .timestopStart: //"timestopStart" transition deprecated in favor of cutscene
			duration := durations.(int)
			seq_open()
				if seq_cue(0){
					alpha = 1
					color = COLOR_WHITE
					audio_play(au.combatTimeStop)
				}
				if seq_cue(0,duration){
					alpha = seq_map(1,0,cu.easeInStrong)
				}
				if seq_cue(duration){
					if kind == .combatStart{
						units := combatUnits_get()
						for unit in units{
							if unit.unitType == .player do combat_grid_ripple(unit.stageCharacter.transform.pos)
						}
						audio_play(au.combatGridRipple)
					}
					doEnd(self)
					return
				} 
			seq_close()
		case .timestopEnd: //"timestopEnd" transition deprecated in favor of cutscene
			duration := durations.(int)
			seq_open()
				if seq_cue(0){
					color = COLOR_WHITE
					audio_play(au.combatTimeStart)
				}
				if seq_cue(0,duration){
					alpha = 1-seq_map(1,0,cu.easeInStrong)
				}
				// if seq_cue(duration-6, duration){
				// 	alpha = seq_map(1,0)
				// }
				if seq_cue(duration){
					{
						combat.time_stop_mode = .disabled
						combat.phase = .resolving
					}
					doEnd(self)
					return
				} 
			seq_close()
		case .fade:
			start,mid,end,total:int
			switch d in durations{
				case int: 
					start = d/2
					mid = 0
					end = d/2
					total = d
				case [3]int:
					start = d[0]
					mid = d[1]
					end = d[2] 
					total = start+mid+end
			}
			seq_open()
				if seq_cue(0, start) {
					alpha = seq_map(0, 1)
				}

				if seq_cue(start+mid/2) do callback_call(onMid)

				if seq_cue(start+mid+1, total) {
					alpha = seq_map(1, 0)
				}

				if seq_cue(total) {
					doEnd(self)
					return
				}
			seq_close()
		case .hardCut:
			duration := durations.(int)
			seq_open()
				if seq_cue(0) do alpha = 1
				if seq_cue(duration/2) do callback_call(onMid)
				if seq_cue(duration){
					doEnd(self)
					return
				}
			seq_close()
		case .hardCutToFade:
			start,total:int
			switch d in durations{
				case int: 
					start = d/2
					total = d
				case [3]int:
					start = d[0]+d[1]
					total = start+d[2]
			}
			seq_open()
				if seq_cue(0) do alpha = 1
				if seq_cue(start) do callback_call(onMid)
				if seq_cue(start+1, total) do alpha = seq_map(1, 0)
				if seq_cue(total){
					doEnd(self)
					return
				}
			seq_close()
		case .wipe: 
			duration := durations.(int)
			seq_open("wipeTransition")
			if seq_cue(duration/2) do callback_call(onMid)
			if seq_cue(duration) {
				doEnd(self)
				return
			}
			seq_close()
	}

case .draw:
	if drawOnTop do render_depth_ui(.top)
	switch kind{
		case .fade, .hardCut, .hardCutToFade, .combatStart, .timestopStart, .timestopEnd:
			if useAddFade && alpha != 1{
				add_fade_set((color==COLOR_WHITE)?alpha:-alpha)
				display_redraw()
				shader_reset()
			}
			else{
				draw_rect_fullscreen(color, alpha)
			}
		case .wipe:
			duration := durations.(int)
			ds := display_size()
			wipeWidth := sp.wipeTransition.size.x
			minPos := -wipeWidth
			maxPos := ds + wipeWidth
			alpha = 1
			blendmode_set(blendmode)
			seq_open("wipeTransition")
				switch direction{
					case .none: //do nothing
					case .right:
						if seq_cue(0, duration/2){
							x := seq_map(minPos, ds.x)
							sprite_draw_ex(sp.wipeTransition, x, 0, 0, 1, 0, color, alpha)
							draw_rect(minPos,0,x, ds.y, color, alpha)
						}
						
						if seq_cue(duration/2, duration){
							x := seq_map(0, maxPos.x)
							sprite_draw_ex(sp.wipeTransition, x, 0, 0, Vec2{-1,1}, 0, color, alpha)
							draw_rect(x, 0, maxPos.x, ds.y, color, alpha)
						}
					case .left:
						if seq_cue(0, duration/2){
							x := seq_map(maxPos.x, 0)
							sprite_draw_ex(sp.wipeTransition, x, 0, 0, Vec2{-1,1}, 0, color, alpha)
							draw_rect(x, 0, maxPos.x, ds.y, color, alpha)
						}
						
						if seq_cue(duration/2, duration){
							x:=seq_map(ds.x, minPos)
							sprite_draw_ex(sp.wipeTransition, x, 0, 0, 1, 0, color, alpha)
							draw_rect(minPos, 0, x, ds.y, color, alpha)
							
						}
					case .up:
						if seq_cue(0, duration/2){
							y := seq_map(maxPos.y, 0)
							sprite_draw_ex(sp.wipeTransition, 0, y, 0, Vec2{1, 480./270.}, 90, color, alpha)
							draw_rect(0, y, ds.x, maxPos.y, color, alpha)
						}
						
						if seq_cue(duration/2, duration){
							y := seq_map(ds.y, minPos)
							sprite_draw_ex(sp.wipeTransition, 0, y, 0, Vec2{-1,480./270.}, 90, color, alpha)
							draw_rect(0, minPos, ds.x, y, color, alpha)
						}
					case .down:
						if seq_cue(0, duration/2){
							y := seq_map(minPos, ds.y)
							sprite_draw_ex(sp.wipeTransition, 0, y, 0, Vec2{1,-1}, 90, color, alpha)
							draw_rect(0, minPos, ds.x, y, color, alpha)
						}
						
						if seq_cue(duration/2, duration){
							y:=seq_map(0, maxPos.y)
							sprite_draw_ex(sp.wipeTransition, 0, y, 0, 1, 90, color, alpha)
							draw_rect(0, y, ds.x, maxPos.y, color, alpha)
						}
				}
			seq_close(.pause)
			blendmode_set(.blend)
	}

}}
