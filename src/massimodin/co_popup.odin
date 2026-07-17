#+feature using-stmt
package massimodin //@nested-tags:_components/

Popup :: struct{
	using base:ComponentBase,
	popupString:Estring,
	popupTime:int,
	isBlocking:bool
}

BOX_POPUP_TIME_DEFAULT :: 8
box_popup_scale :: proc(t:int, verticalOnly:=false, reverse:=false, popupTime:=BOX_POPUP_TIME_DEFAULT)->Vec2{
	scale := Vec2{1,1}
	if verticalOnly{
		switch t{
			case 0..=popupTime/2: scale.y = remap(f32(t), 0,f32(popupTime/2), 1./6., 1, cu.easeIn)
		}
		if reverse do scale.y = 1-scale.y
	}
	else{
		if reverse{
			switch t{
				case 0..=popupTime/2: 
					scale.y = remap(f32(t), 0, f32(popupTime/2), 1, 1./6.,cu.easeOut)
				case popupTime/2+1..=popupTime: 
					scale.x = remap(f32(t), f32(popupTime/2), f32(popupTime), 1,0,cu.easeOut)
					scale.y = 1./6.
			}
		}
		else{
			switch t{
				case 0..=popupTime/2: 
					scale.x = remap(f32(t), 0, f32(popupTime/2), 0,1,cu.easeIn)
					scale.y = 1./6.
				case popupTime/2+1..=popupTime: scale.y = remap(f32(t), f32(popupTime/2), f32(popupTime), 1./6.,1,cu.easeIn)
			}
		}
	}
	return scale
}

// box_popup_seq :: proc(key:ImKey=#caller_location) -> (scale:Vec2, done:bool){
// 	scale = {1,1}
// 	if seq_open(){
// 		scale = box_popup_scale(seq_time())
// 		if seq_cue(BOX_POPUP_TIME){
// 			return scale, seq_close(.end)
// 		}
// 	}
// 	return scale, seq_close()
// }

popup_seq :: proc(popupString:string, popupTime:=BOX_POPUP_TIME_DEFAULT, key:=#caller_location) -> bool{
	openT:^int
	if seq_open(&openT, key){
		if seq_cue(0) do audio_play(au.uiBoxOpen)
		if seq_cue() do openT^ = -1
		if seq_time() > 20 && seq_latch(ginputs[.confirm]){
			if seq_cue() do openT^ = time.frame
			if seq_wait(popupTime) do return seq_close(.end)
		}

		State :: struct{
			openT:int,
			popupString:string,
			popupTime:int
		}
		seq_draw(callback_make(proc(state:^State){
			reverse := state.openT != -1
			scale := box_popup_scale(reverse?time.frame-state.openT:seq_time(), reverse=reverse, popupTime=state.popupTime)

			dialogue.font = fo.fairfax__12
			dialogue.color = COLOR_WHITE
			displayString := dialogue_line_parse(state.popupString)

			buffer :: Vec2{5,6}
			
			drawRect := Rect{0, dialogue_text_size(displayString) + buffer*2}

			drawTex := tex_make(drawRect.size)
			defer tex_destroy(drawTex)

			tex_target_set(drawTex)
				nineslice_draw(sp.menuBoxOutlined, drawRect)
				drawRect.pos.x += 2
				dialogue_text_draw(displayString, drawRect, true, dropShadow=true)
				drawRect.pos.x -= 2
			tex_target_reset()

			drawRect.size *= scale
			rect_align(&drawRect, DISPLAY_SIZE/2, 0)

			tex_draw_ex(drawTex, drawRect.pos, scale)
			
		}, State{openT^, popupString, popupTime}, context.temp_allocator))
	}
	return seq_close()
}

popup_make_item_collect :: proc(item:^Item, isBlocking:=true){
	popup_make(item_collect_message(item), isBlocking)
}

//temp allocates
item_collect_message :: proc(item:ItemRef) -> string{
	return format(dialogue_line(di.items, "obtainedMessage"), dialogue_line(di.items, item_ref_get(item).id))
}

//clones the provided string
popup_make :: proc(popupString:string, isBlocking:=true, popupTime:=BOX_POPUP_TIME_DEFAULT) -> ^Popup{
	p := entity_make(Popup)
	estring_set(&p.popupString, popupString, true)
	p.isBlocking = isBlocking
	if isBlocking do cutscene.enabled = true
	p.popupTime = popupTime

	return p
}

_popup_process_event :: proc(base:^ComponentBase, event:Event, overrideDisabled:=false){
if(!overrideDisabled && event in base.disabledEvents) do return
last_context := entities.context_component
defer cowith(last_context)
cowith(base)
self := cast(^Popup)base
using self
#partial switch event{
case .init:
	popupTime = BOX_POPUP_TIME_DEFAULT
case .update:
	if popup_seq(popupString.s, popupTime) do entity_destroy(self)

case .destroy:
	if isBlocking do cutscene.enabled = false

case .clean:
	estring_delete(&popupString)

}}
