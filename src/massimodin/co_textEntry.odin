#+feature using-stmt
package massimodin //@nested-tags:_components/

import "core:strings"
TextEntry :: struct{
	using base:RenderComponentBase,
	fadeTimer:CoRef(Timer),
	validRunes:[dynamic]rune,
	validRunesCapitalized:[dynamic]rune,
	input:strings.Builder,
	maxCharacters:int,
	font:^Font,
	inputCharacterSize:Vec2, //with padding
	onCompletion:proc(output:string),
	alpha:f32,
	shift:bool,
	done:bool,
	gamepadCursor:Vec2i, //col, row in virtual keyboard grid. special columns beyond grid width = backspace/shift/done
	invalidOutputs:[]string
}

_textEntry_process_event :: proc(base:^ComponentBase, event:Event, overrideDisabled:=false){
if(!overrideDisabled && event in base.disabledEvents) do return
last_context := entities.context_component
defer cowith(last_context)
cowith(base)
self := cast(^TextEntry)base
using self

virtualKeyBounds :: Rect{{480/2-130, 120}, {260, 120}}
#partial switch event{
case .init:
	init(&validRunes)
	init(&validRunesCapitalized)

	addRange :: proc(runes:^[dynamic]rune, min,max:int){
		for i in min..=max{ 
			append(runes, rune(i))
		}
	}
	addRange(&validRunes, 97,122)
	addRange(&validRunesCapitalized, 65,90)

	//extended latin
	addRange(&validRunes, 224,246)
	addRange(&validRunes, 248,255)
	addRange(&validRunesCapitalized, 192,214)
	addRange(&validRunesCapitalized, 216,223)

	append(&validRunes, '\'')
	append(&validRunes, '-')
	append(&validRunesCapitalized, '\'')
	append(&validRunesCapitalized, '-')

	font = fo.fairfax__24
	inputCharacterSize = char_size('M', font) + {11,0} 
	timer_add(&fadeTimer, 20)
	timer_start(fadeTimer)
	depth = -DEPTH_MAX
	maxCharacters = 14
	shift = true
case .update:
	if fadeTimer.state == .active{
		alpha = timer_map(fadeTimer, done?1:0, done?0:1)
	}
	else{
		alpha=done?0:1
		if done{
			onCompletion(strings.to_string(input))
			entity_destroy(self)
		}
	}
case .draw:
	drawString :: proc(str:string, pos:Vec2, hovering:bool, alignment:=Alignment{-1,-1}){
		text_draw(str, pos + 1, 48, alignment=alignment)
		text_draw(str, pos, hovering ? color_hex(0xffc960) : COLOR_WHITE, alignment=alignment)
	}

	camera_set(0)
	draw_rect(0, DISPLAY_SIZE, COLOR_BLACK, alpha*0.5)
	fonts.default = font
	mdp := mouse_display_pos()
	selected := fadeTimer.state != .active && ginputs[.confirm]
	checkRect := Rect{virtualKeyBounds.pos, char_size('M')}
	hovering := false
	
	runes := shift ? validRunesCapitalized:validRunes

	gamepad := input_device() == .gamepad
	gridSize:Vec2i
	gridSize.x = ceili(virtualKeyBounds.size.x/inputCharacterSize.x)
	gridSize.y = ceili(f32(len(runes))/f32(gridSize.x))
	assert(gridSize.y >= 2, "Text Entry requires at least two rows of text, at least 3 recommended!")
	if gamepad{
		movement := Vec2i{
			int(ginputs[.right]) - int(ginputs[.left]),
			int(ginputs[.down]) - int(ginputs[.up])
		}
		lastRowW := len(runes)%gridSize.x
		if lastRowW == 0 do lastRowW = gridSize.x

		if gamepadCursor.x == gridSize.x{ //side buttons
			if movement.y != 0{
				if gamepadCursor.y < gridSize.y/2 do gamepadCursor.y = gridSize.y - 2
				else do gamepadCursor.y = 0
			}
			else{
				if gamepadCursor.y < gridSize.y/2 do gamepadCursor.y = 0
				else do gamepadCursor.y = gridSize.y - 2
			}
			gamepadCursor.x += movement.x
		}
		else if gamepadCursor.y == gridSize.y{ //DONE button
			gamepadCursor.x = gridSize.x - 1
			gamepadCursor.y += movement.y
			if gamepadCursor.y == gridSize.y - 1 do gamepadCursor.x = lastRowW-1
		}
		else if gamepadCursor.y == gridSize.y -1{ //bottom characters
			gamepadCursor += movement
			gamepadCursor.x = wrap(gamepadCursor.x, 0, lastRowW)
			if gamepadCursor.x == lastRowW do gamepadCursor.x = gridSize.x
		}
		else do gamepadCursor += movement
		gamepadCursor = wrap(gamepadCursor, Vec2i{}, gridSize)
	}

	for r,i in runes{
		if gamepad{
			gridPos := grid_index_to_pos(gridSize, i)
			hovering = gridPos == gamepadCursor
		}
		else do hovering = rect_contains(checkRect, mdp)
		
		drawStr := runes_to_string({r}, context.temp_allocator)
		drawString(drawStr, checkRect.pos, hovering)
		if hovering && selected && string_count(strings.to_string(input)) < maxCharacters{
			strings.write_rune(&input, r)
			if len(input.buf) == 1 do shift = false
		}

		checkRect.x += inputCharacterSize.x
		if checkRect.x > rect_get_right(virtualKeyBounds){
			checkRect.x = virtualKeyBounds.x
			checkRect.y += inputCharacterSize.y
		}
	}

	checkRect.pos = {rect_get_right(virtualKeyBounds)+11, virtualKeyBounds.y} //backspace
	checkRect.size = text_size("←-")
	hovering = gamepad ? gamepadCursor.x == gridSize.x && gamepadCursor.y < gridSize.y/2 : rect_contains(checkRect, mdp)
	drawString("←-", checkRect.pos, hovering)
	if (hovering && selected) || ginputs[.cancel] do strings.pop_rune(&input)

	shiftStr := shift?"SHIFT":"shift"
	checkRect.size = text_size(shiftStr, font)
	checkRect.pos = {rect_get_right(virtualKeyBounds)+11, rect_get_bottom(virtualKeyBounds) - checkRect.size.y} //shift
	hovering = gamepad ? gamepadCursor.x == gridSize.x && gamepadCursor.y >= gridSize.y/2 : rect_contains(checkRect, mdp)
	drawString(shiftStr, checkRect.pos, hovering)
	if (hovering && selected) || ginputs[.lt] do shift = !shift
	
	doneStr := dialogue_line(di.textEntry, "done")
	checkRect.size = text_size(doneStr, font)
	checkRect.pos = {rect_get_right(virtualKeyBounds) - checkRect.size.x, rect_get_bottom(virtualKeyBounds)} //done
	hovering = gamepad ? gamepadCursor.y == gridSize.y : rect_contains(checkRect, mdp)
	drawString(doneStr, checkRect.pos, hovering)
	output := strings.to_string(input)
	if hovering && selected{
		if len(output) > 0 && !contains(invalidOutputs, string_lower(output, context.temp_allocator)){
			timer_start(fadeTimer)	
			done = true
		}
		else do audio_play(au.uiFail)
	}

	drawString(output, Vec2{DISPLAY_WIDTH/2, DISPLAY_HEIGHT/3}, false, 0)

	camera_reset()

case .clean:
	delete(validRunes)
	delete(validRunesCapitalized)
	strings.builder_destroy(&input)
	
}}
