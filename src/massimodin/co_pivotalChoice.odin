#+feature using-stmt
package massimodin //@nested-tags:_components/

PivotalChoice :: struct{
	using base:RenderComponentBase,
	age:int,
	options:[2]struct{
		text:string,
		onSelect:Callback
	},
	timedOption:bool
}

_pivotalChoice_process_event :: proc(base:^ComponentBase, event:Event, overrideDisabled:=false){
if(!overrideDisabled && event in base.disabledEvents) do return
last_context := entities.context_component
defer cowith(last_context)
cowith(base)
self := cast(^PivotalChoice)base
using self
#partial switch event{
case .init:
case .update:
	age+=1
case .draw:
	render_depth_ui(.menus, -50) //in front of the other menus and the transition fade
	fadeInTime :: 120
	fadeOutTime :: 180
	fonts.default = fo.GoetheBold__20
	mdp := mouse_display_pos()
	selected := age>fadeInTime && ginputs[.confirm]
	ds := display_size()
	alpha := remap(f32(age), 0, fadeInTime, 0, 1, cu.easeOutStrong)

	if timedOption{
		optionTime :: 200
		if age > fadeInTime+fadeOutTime+optionTime{
			entity_destroy(self)
			callback_call(options[1].onSelect)
			return
		}

		if age > fadeInTime+optionTime{
			alpha = remap(f32(age), fadeInTime+optionTime, fadeInTime+fadeOutTime+optionTime, 1, 0, cu.easeOutStrong)
		}

		drawPos := Vec2{ds.x/2, ds.y/3}
		text := options[0].text
		rect := text_rect(text, drawPos, 0)
		hovering := rect_contains(rect, mdp) || input_device() == .gamepad

		//ghostly text cloud — ghosts are the only draw
		ghostCount :: 16
		flutterRange := 2 + (1 - alpha) * 12 - (hovering?1:0)
		for gi in 0..<ghostCount {
			xFreq := 0.013 + f32(gi) * 0.041
			yFreq := 0.017 + f32(gi % 5) * 0.053
			xPhase := f32(gi) * 2.399
			yPhase := f32(gi) * 1.618
			radiusVariant := 0.5 + f32(gi % 5) * 0.15
			ghostOffset := Vec2{
				rcos(f32(age)*xFreq + xPhase) * flutterRange * radiusVariant,
				rsin(f32(age)*yFreq + yPhase) * flutterRange * radiusVariant,
			}
			flickerPhase := f32(gi) * 1.1
			flickerFreq := 0.07 + f32(gi % 4) * 0.03
			flicker := rsin(f32(age)*flickerFreq + flickerPhase) * 0.5 + 0.5
			ghostAlpha := alpha * (0.4 + 0.25*(1-alpha)) * flicker
			text_draw(text, drawPos + ghostOffset, alpha=ghostAlpha, alignment=0)
		}

		connectionPressing:bool
		switch input_device(){
			case .keyboard: connectionPressing = key_pressed(.SPACE)
			case .gamepad: connectionPressing = button_pressed(input.last_device, .LEFT_STICK) || button_pressed(input.last_device, .RIGHT_STICK)
		}

		if (hovering && selected) || (age>fadeInTime && connectionPressing){
			entity_destroy(self)
			callback_call(options[0].onSelect)
		}
	}
	else{
		for opt,i in options{
			drawPos := Vec2{ds.x*((f32(i)+1)/3), ds.y/2}
			rect := text_rect(opt.text, drawPos, 0)
			hovering := rect_contains(rect, mdp)
			text_draw(opt.text, drawPos, alignment=0)
	
			if hovering && selected{
				entity_destroy(self)
				callback_call(opt.onSelect)
			}
		}
	}

}}
