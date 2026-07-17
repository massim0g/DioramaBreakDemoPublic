package massimodin //@nested-tags:dialogue

import "core:reflect"
DialogueSystem :: struct{
	_dialogues_map:map[string]Dialogue,
	names:[dynamic]string,
	load_allocator:Allocator,
	locales_loaded:[dynamic; LOCALES_MAX]string,
	dialogues_loaded:bool,

	current:^Dialogue,
	isBlocking:bool,
	current_label:string,
	head:int,
	display_runes:[dynamic]DialogueRune,
	_exit_flag:bool,
	_updating:bool, 
	_label_jump_interrupt:string,
	_block_stack:[dynamic]DialogueBlock,

	typewriter_count:int,
	typewriter_pause_default:f32,
	typewriter_pause:f32,
	typewriter_pause_remaining:f32,
	typewriter_pause_additional:f32,

	auto_advance:bool,
	auto_advance_time:f32,
	auto_advance_timer:f32,
	unskippable:bool,

	font_default:^Font,
	font_default_hd:^Font,
	font_unscaled:^Font,
	font:^Font,

	color_default:Color,
	color_default_hd:Color,
	color:Color,

	text_centered:bool,
	text_rect:Rect,

	portrait:^Sprite,
	name_tag:string,
	hd_portraits:[2]DialogueHDPortrait,
	hd_portraits_prev:[2]DialogueHDPortrait,
	hd_portrait_active:int,
	hd_portraits_tex:Tex,
	hd_overlay_enabled:bool,
	hd_overlay_fade_interrupt_disable_flag:bool, //tracks whether to disable the hd overlay rendering mode after the transition cutscene

	choices:[dynamic]DialogueChoice,
	//choices_text_tex:Tex,
	choices_shine_tex:Tex,
	choices_interjection_block_end:int,
	choices_show_interjection:bool,
	choices_allocator:Allocator, //freed whenever the player selects a dialogue choice or the dialogue closes. Also useful for per-line dialogue allocations.
	interjection_particle:^ParticleType,
	interjection_sprite_draw_rect:Rect,

	commands:map[string]proc(params:[]string) -> string,
	pronounsMap:map[string][PronounKind]string,

	log:[dynamic]DialogueLogEntry,
	log_open:bool,
	log_button_rect:Rect,
	log_button_font:^Font,
	log_scroll:f32
}
dialogue:^DialogueSystem

_dialogue_system_init :: proc(){
	dialogue = new(DialogueSystem)
	init(&dialogue.display_runes)
	init(&dialogue._block_stack)
	init(&dialogue.choices)
	dialogue.choices_allocator = allocator_make(KILOBYTE*8)

	dialogue.load_allocator = allocator_make()
	init(&dialogue._dialogues_map, dialogue.load_allocator)
	init(&dialogue.names, dialogue.load_allocator)
	init(&dialogue.commands, dialogue.load_allocator)

	dialogue.hd_portraits_tex = tex_make(DISPLAY_SIZE_HD, true)
	tex_blendmode_set(dialogue.hd_portraits_tex, .premul)

	init(&dialogue.log, 0, DIALOGUE_LOG_CAP+1)

	di = new(DialogueIDs, assets.allocator)

	_dialogue_commands_init()
	//_dialogue_pronouns_map_init()

	dialogue.head = -1

}

_dialogue_system_reload :: proc(){
	
	dialogue.font_default = fo.fairfax__12
	dialogue.font_default_hd = fo.newsreader__70
	dialogue.color_default = COLOR_WHITE
	dialogue.color_default_hd = color_hex(0x625955)
	dialogue.typewriter_pause_default = 1.375
	if dialogue.choices_shine_tex.ptr == nil do dialogue.choices_shine_tex = tex_make(sp.menuShine.size)

	shineMaxLife::46
	shineMaxSpeed:f32:2
	dialogue.interjection_particle = particle_type(sp.shineParticle, shineMaxLife-12, shineMaxLife, shineMaxSpeed*0.66, shineMaxSpeed, cu.slowdown, 1, true, 0.333, 0.5, {cu.popUp, cu.popOut}, angleSpread=0, angleMatchesDir=false)

	dialogue.log_button_font = fo.yal6w4__16
	

	dialogue_reset_display_settings()
}

dialogue_reset_display_settings :: proc(){
	dialogue.font = display.hd_enabled || dialogue.hd_overlay_enabled ? dialogue.font_default_hd : dialogue.font_default
	dialogue.font_unscaled = dialogue.font
	dialogue.color = display.hd_enabled ? dialogue.color_default_hd : dialogue.color_default
	dialogue.typewriter_pause = dialogue.typewriter_pause_default
	dialogue.text_centered = dialogue.hd_overlay_enabled
	dialogue.text_rect = Rect{}
}

DIALOGUE_HD_OVERLAY_TRANSITION_DURATION :: 40
DIALOGUE_LOG_CAP :: 64
DIALOGUE_LOG_DISABLE :: true //disables log in debug mode, mainly for trailer footage
DIALOGUE_BOX_RECT := rectf_make_points(57, 196, 422, 254)

DialogueLabelInfo :: struct{
	line:int
}

DialogueData :: struct{
	lines:[]string,
	labelsMap:map[string]DialogueLabelInfo,
	backingPtr:string //simple pointer to the dialogue data's backing memory on the heap, used when destroying the dialogue
}

Dialogue :: struct{
	locales:[dynamic; LOCALES_MAX]DialogueData,
	name:string
}

DialogueHDPortrait :: struct{
	head:^Sprite,
	body:^Sprite
}

DialogueConditional :: struct{
	expression:string,
	startLine:int,
	endLine:int
}

DialogueBlock :: struct{
	isChoice:bool,
	endIndex:int,
	blockEndIndex:int
}

DialogueRune :: struct{
	myRune:rune,
	col:Color,
	font:^Font,
	pause:f32 //amount of time in frames the dialogue should pause *before* displaying this character
}

DialogueString :: []DialogueRune

DialogueChoice :: struct{
	displayString:DialogueString,
	lineIndex:int,
	jumpLabel:string,
	disabled:bool
}

DialogueRef :: struct{
	using d:^Dialogue,
	label:string
}

DialogueLogEntry :: struct{
	line:DialogueString,
	speaker:^Sprite
}

dialogue_data :: #force_inline proc "contextless"(dia:^Dialogue) -> ^DialogueData{
	//fall back to english when the dialogue is missing from the current locale
	if int(settings.locale) >= len(dia.locales) || dia.locales[settings.locale].lines == nil do return &dia.locales[0]
	return &dia.locales[settings.locale]
}

dialogue_label_seen_set :: proc(dia:^Dialogue, label:string, val:bool=true){
	flag(format("DiLabelSeen__%s__%s", dia.name, label), val?"1":"0")
}

dialogue_label_seen_get :: proc(dia:^Dialogue, label:string) -> bool{
	return flag_check(format("DiLabelSeen__%s__%s", dia.name, label))
}

dialogue_delete :: proc(dia:^Dialogue){
	for &d in dia.locales{
		strmap_delete(&d.labelsMap)
		delete(d.lines)
		delete(d.backingPtr)
	}
}

dialogue_open :: proc(dia:^Dialogue, label:="", isBlocking:=true){
	if dialogue.current != nil do dialogue_close()
	label := label
	dialogue_reset_display_settings()
	dialogue.hd_portraits_prev = DialogueHDPortrait{}
	dialogue.hd_portraits = DialogueHDPortrait{}
	dialogue.current = dia

	if isBlocking && !cutscene.enabled{ //if cutscene is already enabled, dialogue will not touch cutscene flag no matter what
		cutscene.enabled = true
		dialogue.isBlocking = true
	}
	else do dialogue.isBlocking = false
	
	if(label == "") do dialogue.head = -1
	else{
		d := dialogue_data(dia)
		assertf(label in d.labelsMap, "Tried to open a dialogue with unknown label: '%s'", label)
		labelStruct:DialogueLabelInfo
		label, labelStruct = strmap_get(d.labelsMap, label)
		dialogue.head = labelStruct.line
	}
	_dialogue_label_change(label)
	dialogue_next_line()
	if display.hd_enabled do ui_cue("dialogueHDFade")
}

dialogue_close :: proc(){
	_dialogue_label_change("")
	dialogue_choice_close()
	dialogue.current = nil
	if dialogue.isBlocking do cutscene.enabled = false
	dialogue.head = -1
	clear(&dialogue.display_runes)
	dialogue.typewriter_count = 0
	dialogue_command_call("speed") //reset speed
	dialogue.typewriter_pause_remaining = 0
	dialogue.auto_advance = false
	dialogue._exit_flag = false
	dialogue._label_jump_interrupt = ""
	dialogue.portrait = nil
	dialogue.name_tag = ""
	dialogue.log_open = false
	dialogue.hd_portraits_prev = dialogue.hd_portraits
	dialogue.hd_portraits = DialogueHDPortrait{}
	clear(&dialogue._block_stack)
	flags_clear(.local)
	if display.hd_enabled do ui_cue("dialogueHDFade")
	dialogue.hd_overlay_enabled = false
}

dialogue_choice_close :: proc(){
	clear(&dialogue.choices)
	free_all(dialogue.choices_allocator)
	dialogue.choices_interjection_block_end = 0
	dialogue.choices_show_interjection = false
}

//Jumps to a label and advances the current dialogue, to be called by external code. Can be useful if you want e.g. cutscene code to interrupt dialogue and jump to a label.
dialogue_jump_to_label :: proc(newLabel:string, advance:=true){
	assert(dialogue.current != nil, "Tried to jump to a dialogue label with no active dialogue!")
	
	if dialogue._updating{
		dialogue._label_jump_interrupt = newLabel
		return
	}

	labelStruct, ok := dialogue_data(dialogue.current).labelsMap[newLabel]
	assertf(ok, "Tried to jump to unknown label: %s", newLabel)
	dialogue.head = labelStruct.line
	clear(&dialogue._block_stack)
	dialogue_choice_close()
	_dialogue_label_change(newLabel)
	if advance do dialogue_next_line()
}

//Retrieves a line from a dialogue file as a string. Most useful for localization.
//Can optionally provide an offset to get a line further down in the label 
dialogue_line :: proc(dia:^Dialogue, label:="", offset:=0) -> string{
	d := dialogue_data(dia)
	line := 0
	if label != ""{
		labelStruct, ok := d.labelsMap[label]
		if !ok{
			err := format("Tried to get dialogue line from unknown label: %s", label)
			when DEBUG {panic(err)} else{print(err); return ""}
		}
		line = labelStruct.line+1
	}

	return d.lines[line+offset]
}
dialogue_line_parsed :: proc(d:^Dialogue, label:="", offset:=0, allocator:=context.temp_allocator) -> DialogueString{
	return dialogue_line_parse(dialogue_line(d, label, offset), allocator)
}

//get every line in a dialogue label
dialogue_lines :: proc(dia:^Dialogue, label:="") -> []string{
	d := dialogue_data(dia)
	start := 0
	if label != ""{
		labelStruct, ok := d.labelsMap[label]
		assertf(ok, "Tried to get dialogue lines from unknown label: %s", label)
		start = labelStruct.line+1
	}

	i:=1
	for start+i < len(d.lines) && d.lines[start+i][0] != '#'{
		i+=1
	}
	return d.lines[start:][:i]
}

//internal, mainly used to update the "seen" flag when a label changes
_dialogue_label_change :: proc(newLabel:string){
	if dialogue.current == nil do return

	if dialogue.current_label != ""{
		dialogue_label_seen_set(dialogue.current, dialogue.current_label)
		delete(dialogue.current_label)
	}

	seen := false
	if newLabel in dialogue_data(dialogue.current).labelsMap{
		seen = dialogue_label_seen_get(dialogue.current, newLabel)
		dialogue.current_label = clone(newLabel)
	}
	else do dialogue.current_label = ""

	flag("seen", seen ? "1":"0", .local)
}

//Will set whether the dialogue advances automatically. If no time is provided, auto-advance will be disabled. If a time value below zero is provided, the dialogue will not be able to advance without outside intervention.
dialogue_set_auto :: proc(autoAdvanceTime:Maybe(f32)=nil){
	t, ok := autoAdvanceTime.?
	if !ok{
		dialogue.auto_advance = false
		dialogue.unskippable = false
		return
	}

	dialogue.auto_advance = true
	dialogue.unskippable = true
	dialogue.auto_advance_time = max(f32(-1), t*FRAMERATE_TARGET)
	dialogue.auto_advance_timer = dialogue.auto_advance_time
}

dialogue_expression_parse :: proc(expression:string, inConditional:=false) -> (result:string, insert:bool){
	e, _ := string_replace_all(expression, " ", "", context.temp_allocator) //remove whitespace

	if len(e) == 0{
		print("Warning: Tried to parse empty dialogue expression!")
		return "", false
	} 
	
	if(e[0] == '$'){
		assert(!inConditional, "Tried to insert the value of a dialogue expression into a conditional!")
		e = e[len("$"):]
		insert = true
	}

	if e[0] == '"' && e[len(e)-1] == '"' do return string_slice_between(e, "\"", "\""), insert //string literal

	parseCommand :: proc(e:string) -> (string, bool){
		hasCommas := string_contains(e, ",")
		if(hasCommas || e in dialogue.commands){
			commandName := e
			params:[]string

			if(hasCommas){
				split := string_split(e, ",")
				assertf(split[0] in dialogue.commands, "Attempted to call unknown dialogue command '%s'", split[0])
				commandName = split[0]
				params = split[1:]
			}

			return dialogue.commands[commandName](params), true
		}
		// else if lower := string_lower(e, context.temp_allocator); lower in dialogue.pronounsMap{
		// 	upper := string_upper(e, context.temp_allocator)
		// 	mappedPronoun := dialogue.pronounsMap[lower][save.playerPronounKind]
			
		// 	if e == upper do return string_upper(mappedPronoun, context.temp_allocator), true
		// 	else if e[0] == upper[0] do return string_prettify(mappedPronoun, false, context.temp_allocator), true
		// 	else do return mappedPronoun, true
		// }

		return "", false
	}
	

	parseComparison :: proc(e:string, comparator:string) -> string{
		operands := string_split(e, comparator, 2)

		parsedOperands := [2]string{operands[0], operands[1]}

		for &operand in parsedOperands{
			operand,_ = dialogue_expression_parse(operand, true)
		}

		if(comparator == "==") do return parsedOperands[0] == parsedOperands[1] ? "1" : "0"

		f32Operands:[2]f32
		for operand, i in parsedOperands{
			f32Val, ok := string_to_f32(operand)
			assertf(ok, "Invalid comparison in dialogue expression: '%s' between values '%s' and '%s'", e, parsedOperands[0], parsedOperands[1])
			f32Operands[i] = f32Val
		}

		switch comparator{
			case "<=": return f32Operands[0] <= f32Operands[1] ? "1" : "0"
			case ">=": return f32Operands[0] >= f32Operands[1] ? "1" : "0"
			case "<": return f32Operands[0] < f32Operands[1] ? "1" : "0"
			case ">": return f32Operands[0] > f32Operands[1] ? "1" : "0"
			case "&&": return f32Operands[0]>0 && f32Operands[1]>0 ? "1" : "0"
			case "||": return f32Operands[0]>0 || f32Operands[1]>0 ? "1" : "0"
		}

		assertf(false, "Should be impossible to get this error parsing dialogue comparator.")
		return "0"
	}

	parseAssignment :: proc(e:string, assigner:string) -> string{
		operands := string_split(e, assigner)

		flagLevel := flag_get_level(operands[0])

		if(len(operands) == 1){
			assertf(assigner == "=", "Error parsing dialogue assignment: '%s'", e)
			flag(operands[0], "", flagLevel)
			return ""
		}

		parsedOperands := [2]string{operands[0], operands[1]}

		for &operand in parsedOperands{
			operand,_ = dialogue_expression_parse(operand, true)
		}

		if(assigner == "="){
			flag(operands[0], parsedOperands[1], flagLevel)
			return parsedOperands[1]
		}
		
		f32Operands:[2]f32
		for operand, i in parsedOperands{
			f32Val, ok := string_to_f32(operand)
			assertf(ok, "Invalid comparison in dialogue expression: '%s' between values '%s' and '%s'", e, parsedOperands[0], parsedOperands[1])
			f32Operands[i] = f32Val
		}

		res:f32
		switch assigner{
			case "+=": res = f32Operands[0] + f32Operands[1]
			case "-=": res = f32Operands[0] - f32Operands[1]
		}

		resStr := f32_to_string(res, 8, context.temp_allocator)
		flag(operands[0], resStr, flagLevel)
		return flag_get(operands[0]) //returns the cloned value of resStr
	}
	
	if num,ok := string_to_f32(expression); ok do return expression, insert

	if !inConditional{
		if(string_contains(e, "+=")) do return parseAssignment(e, "+="), insert
		if(string_contains(e, "-=")) do return parseAssignment(e, "-="), insert
		if(string_contains(e, "=")) do return parseAssignment(e, "="), insert
	}

	if(string_contains(e, "||")) do return parseComparison(e, "||"), insert
	if(string_contains(e, "&&")) do return parseComparison(e, "&&"), insert
	if(string_contains(e, "==")) do return parseComparison(e, "=="), insert
	if(string_contains(e, "<=")) do return parseComparison(e, "<="), insert
	if(string_contains(e, ">=")) do return parseComparison(e, ">="), insert
	if(string_contains(e, "<")) do return parseComparison(e, "<"), insert
	if(string_contains(e, ">")) do return parseComparison(e, ">"), insert


	assertf(!(string_contains(e, "=") && !string_contains(e, "==")), "Incorrect number of '=' when doing dialogue comparison: '%s'", e)

	

	invert:=false
	if(e[0] == '!'){
		e = e[1:]
		invert = true
	}

	
	if commandVal, ok := parseCommand(e); ok{
		if invert{
			if commandVal == "0" do commandVal = "1"
			else if commandVal == "1" do commandVal = "0"
		}
		return commandVal, insert
	}

	if (inConditional || insert) && flag_exists(e){
		flagVal := flag_get(e)
		if invert{
			if flagVal == "0" do flagVal = "1"
			else if flagVal == "1" do flagVal = "0"
		}
		return flagVal, insert
	}

	if(inConditional) do return invert?"1":"0", false
	
	assertf(!insert, "Attempted to insert the value of a nonexistent flag into dialogue: '%s'", e)

	flag(e)
	return "1", false

}

//Parses all expressions and markup within a line of a dialogue file and returns the formatted dialogue string
dialogue_line_parse :: proc(line:string, allocator:=context.temp_allocator) -> DialogueString{
	out := make([dynamic]DialogueRune, 0, string_count(line), allocator)

	//non-positional expressions
	parsedLine := string_clone(line, context.temp_allocator)

	//portraits
	newPortraitExpression := string_slice_between(parsedLine, "![[", "]]", true)
	if(newPortraitExpression != ""){
		if(newPortraitExpression == "![[]]") do dialogue.portrait = nil
		else{
			dialogue.portrait = sprite_find(newPortraitExpression[len("![["):len(newPortraitExpression)-len(".png]]")])
			when DEBUG{
				if dialogue.portrait == nil do printf("Warning: Could not find sprite for dialogue portrait in expression '%s'", newPortraitExpression)
			}
		}
		dialogue.name_tag = ""
		parsedLine,_ = string_replace(parsedLine, newPortraitExpression, "", 1, context.temp_allocator)
	}
	else{
		newNameTagExpression := string_slice_between(line, "[", "]", true)
		if(newNameTagExpression != "" && !string_starts_with(newNameTagExpression, "[[#")){
			if(newNameTagExpression == "[]") do dialogue.name_tag = ""
			else do dialogue.name_tag = newNameTagExpression[1:len(newNameTagExpression)-1]
			dialogue.portrait = nil
			parsedLine,_ = string_replace(parsedLine, newNameTagExpression, "", 1, context.temp_allocator)
		}
	}

	darkenParentheticals := false
	darkening := false
	if dialogue.portrait != nil{
		for pid in PlayerCharacterID{
			name,_ := reflect.enum_name_from_value(pid)
			if string_contains(dialogue.portrait.name, name){
				darkenParentheticals = true
				break
			}
		}
	}
	
	boldItalic:[2]bool
	nextPause:f32
	for i:=0; i < string_count(parsedLine);{ //positional expression parsing
		r := string_rune(parsedLine, i)
		if(r == '\\'){
			append(&out, DialogueRune{
				string_rune(parsedLine, i+1), dialogue.color, font_bolditalic_get(dialogue.font, boldItalic), dialogue.typewriter_pause
			})
			i += 2
			continue
		}

		if(r == '`'){
			expression := string_slice_between(parsedLine, "`", "`", true)
			if(expression == "") do break
			
			result, insert := dialogue_expression_parse(expression[len("`"):len(expression)-len("`")])
			parsedLine,_ = string_replace(parsedLine, expression, insert ? result : "", 1, context.temp_allocator)
			continue
		}

		if(r == '*'){
			if(string_slice(parsedLine, 2, i) == "**"){
				boldItalic[0] = !boldItalic[0]
				i+=2
				continue
			}

			boldItalic[1] = !boldItalic[1]
			i += 1
			continue
		}

		if(r == '<'){
			colorExpression := string_slice(parsedLine, len(parsedLine)-i, i)
			colorExpression = string_slice_between(colorExpression, "<", ">", true)
			if(colorExpression == "</span>"){
				dialogue.color = dialogue.color_default
			}
			else{
				
				colRGBString := string_slice_between(colorExpression, "(", ")")
				colRGBSplit := string_split(colRGBString, ", ")
				assertf(len(colRGBSplit) == 3, "Could not parse dialogue color expression '%s", colorExpression)
				for s, j in colRGBSplit{
					cVal, ok := string_to_int(s)
					assertf(ok && in_range(cVal, 0, 255), "Could not parse dialogue color expression '%s'", colorExpression)
					dialogue.color[j] = u8(cVal)
				} 
			}
			i += string_count(colorExpression)
			continue
		}

		if r == '(' && darkenParentheticals do darkening = true

		pause := nextPause
		pauseMul := dialogue.typewriter_pause/dialogue.typewriter_pause_default
		
		if(dialogue.typewriter_pause_additional != 0){
			pause = dialogue.typewriter_pause_additional
			dialogue.typewriter_pause_additional = 0
		}
		if(pause == 0) do pause = dialogue.typewriter_pause
		
		nextPause = 0
		nextRune:rune
		if(i != string_count(parsedLine)-1) do nextRune = string_rune(parsedLine, i+1)
		
		if(nextRune == ' '){
			switch r{
				case ',', ';', ':', '-': nextPause = 9*pauseMul
				case '!', '?', '.': nextPause = 18*pauseMul
			}

		}
		//else if(r == '.' && nextRune == '.') do nextPause = 9*pauseMul

		append(&out, DialogueRune{
			r, color_lerp(dialogue.color, COLOR_BLACK, darkening?0.2:0), font_bolditalic_get(dialogue.font, boldItalic), pause
		})

		if r == ')' && darkenParentheticals do darkening = false
		i += 1
	}

	//trim trailing whitespace
	for len(out) > 0 && peek(out).myRune == ' '{ 
		pop(&out)
	}

	shrink(&out)
	return out[:]
}

//Draws a dialogue string with all formatting, wrapped to fit within the given rect
dialogue_text_draw :: proc(text:DialogueString, drawRect:Rect, center:=false, mixCol:=COLOR_WHITE, mixColAmount:f32=0, alpha:f32=1, maxChars:=-1, dropShadow:=false){
	//trace("Dialogue Text Draw")
	drawPos:=drawRect.pos

	TextLine :: struct{
		strStart:int,
		strEnd:int,
		w:f32,
		h:f32
	}

	textLines := make([dynamic]TextLine, 1, context.temp_allocator)

	line := &textLines[0]
	textLen := len(text)
	line.strEnd = textLen

	for &dRune, i in text{
		currentRune := dRune.myRune

		line.h = max(text_char_height(dRune.font), line.h)
		
		if(currentRune == ' '){ //check for line break
			if i == textLen-1{
				line.strEnd = textLen-1
				break
			}
			nextWordWidth:f32
			nextWordWidth += char_size(currentRune, dRune.font).x
			for j:=i+1; j < len(text); j+=1{
				nextRune := text[j]
				if(nextRune.myRune == ' ') do break
				nextWordWidth += char_size(nextRune.myRune, nextRune.font).x
			}
			if(drawPos.x + nextWordWidth > rect_get_right_f(drawRect)){
				drawPos.x = drawRect.pos.x
				line.strEnd = i
				append(&textLines, TextLine{strStart=i+1, strEnd=textLen})
				line = peek_ptr(&textLines)
				continue
			}
		}

		line.w += char_size(currentRune, dRune.font).x

		drawPos.x += char_size(dRune.myRune, dRune.font).x
	}

	drawChar :: proc(dRune:^DialogueRune, pos:Vec2, mixCol:Color, mixColAmount:f32, alpha:f32, dropShadow:bool){
		drawString := runes_to_string({dRune.myRune}, context.temp_allocator)
		if dropShadow{
			col := COLOR_WHITE-dRune.col
			grey := u8(0.299*f32(col[0]) + 0.587*f32(col[1]) + 0.114*f32(col[2]))
			col = Color{grey, grey, grey}
			text_draw(drawString, Vec2{pos.x+1, pos.y}, col, alpha, dRune.font)
			text_draw(drawString, pos+1, col, alpha, dRune.font)
		}
		text_draw(drawString, pos, color_lerp(dRune.col, mixCol, mixColAmount), alpha, dRune.font)
	}

	n := 0
	if center{
		totalH :f32= 0
		for line in textLines do totalH += line.h

		drawPos = rect_center(drawRect)
		drawPos.y -= totalH/2
		for line in textLines{
			drawX := drawPos.x - line.w/2
			for i in line.strStart..<line.strEnd{
				dRune := &text[i]
				drawChar(dRune, Vec2{drawX, drawPos.y}, mixCol, mixColAmount, alpha, dropShadow)
				drawX += char_size(dRune.myRune, dRune.font).x
				n+=1
				if maxChars >= 0 && n >= maxChars do return
			}
			drawPos.y += line.h
		}
	}
	else{
		drawPos = drawRect.pos
		for line in textLines{
			for i in line.strStart..<line.strEnd{
				dRune := &text[i]
				drawChar(dRune, drawPos, mixCol, mixColAmount, alpha, dropShadow)
				drawPos.x += char_size(dRune.myRune, dRune.font).x
				n+=1
				if maxChars >= 0 && n >= maxChars do return
			}
			drawPos.x = drawRect.x
			drawPos.y += line.h
		}
	}
	
}

dialogue_text_size :: proc(text:DialogueString, maxWidth:f32=-1) -> Vec2{
	out:Vec2
	if (maxWidth==-1){
		for &dRune in text{
			out.x += char_size(dRune.myRune, dRune.font).x
			out.y = max(out.y, text_char_height(dRune.font))
		}
	}
	else{
		charX:f32
		lineHeight:f32
		maxedWidth := false
		for &dRune, i in text{
			currentRune := dRune.myRune
			lineHeight = max(text_char_height(dRune.font), lineHeight)
			
			if(currentRune == ' '){ //check for line break
				if i == len(text){
					break
				}
				nextWordWidth:f32
				nextWordWidth += char_size(currentRune, dRune.font).x
				for j:=i+1; j < len(text); j+=1{
					nextRune := text[j]
					if(nextRune.myRune == ' ') do break
					nextWordWidth += char_size(nextRune.myRune, nextRune.font).x
				}
				if(charX + nextWordWidth > maxWidth){
					charX = 0
					out.x = maxWidth
					maxedWidth = true
					out.y += lineHeight
					lineHeight = 0
					continue
				}
			}

			charW := char_size(currentRune, dRune.font).x
			if !maxedWidth do out.x += charW
			charX += charW
		}

		out.y += lineHeight
	}
	return out
}

//draws a dialogue label block as a text paragraph with formatting
dialogue_paragraph_draw :: proc(drawRect:Rect, dia:^Dialogue, label:="", textCol:=COLOR_WHITE, font:^Font=nil, centered:=false, columnBuffer:f32=48){
	font:=font
	if font == nil do font = fonts.default
	dialogue.font = font
	dialogue.color = textCol
	maxW :f32= 0
	startPos := drawRect.pos
	drawRect := drawRect
	center := rect_center(drawRect)

	if centered{
		size := dialogue_paragraph_size(drawRect, dia, label, font)
		drawRect.y = center.y - size.y/2
	}

	d := dialogue_data(dia)
	startInd := 0
	if label != "" do startInd = d.labelsMap[label].line + 1
	for line in d.lines[startInd:]{
		if line[0] == '#' do break
		parsed := dialogue_line_parse(line)
		ts := dialogue_text_size(parsed, drawRect.size.x)
		maxW = max(maxW, ts.x)
		if line != "-" && line != "---"{
			if centered{
				dialogue_text_draw(parsed, Rect{{center.x-ts.x/2, drawRect.y}, drawRect.size})
			} 
			else do dialogue_text_draw(parsed, drawRect)
		}
		if line == "---"{
			drawRect.pos.x += maxW+columnBuffer
			maxW = 0
			drawRect.pos.y = startPos.y
		}
		else do drawRect.pos.y += ts.y
	}
}
dialogue_paragraph_size :: proc(drawRect:Rect, dia:^Dialogue, label:="", font:^Font=nil, columnBuffer:f32=48) -> Vec2{
	font:=font
	if font == nil do font = fonts.default
	dialogue.font = font
	maxW,maxH:f32
	startPos := drawRect.pos
	drawRect := drawRect

	d := dialogue_data(dia)
	startInd := 0
	if label != "" do startInd = d.labelsMap[label].line + 1
	for line in d.lines[startInd:]{
		if line[0] == '#' do break
		ts := dialogue_text_size(dialogue_line_parse(line), drawRect.size.x)
		maxW = max(maxW, ts.x)
		if line == "---"{
			drawRect.pos.x += maxW+columnBuffer
			maxW = 0
			maxH = max(maxH, drawRect.y)
			drawRect.pos.y = startPos.y
		}
		else do drawRect.pos.y += ts.y
	}

	maxH = max(maxH, drawRect.y)

	return {drawRect.x+maxW, maxH} - startPos
}

//Reads the dialogue starting from the line after the current dialogue.head until it reaches the next bit of displayable content
dialogue_next_line :: proc(){ 
	if(dialogue.current == nil) do return

	dialogue._updating = true
	defer dialogue._updating = false

	tempHead := dialogue.head+1

	d := dialogue_data(dialogue.current)
	for{
		if(tempHead >= len(d.lines) || dialogue._exit_flag){
			dialogue_close()
			return
		}

		//end of block
		if len(dialogue._block_stack) > 0{
			lastInd := len(dialogue._block_stack)-1
			block := dialogue._block_stack[lastInd]
			if(tempHead == block.endIndex){
				tempHead = block.blockEndIndex
				ordered_remove(&dialogue._block_stack, lastInd)
				continue
			}
		}

		line := _dialogue_line_remove_block_indent(d.lines[tempHead])

		//skip over labels
		if(line[0] == '#'){
			_dialogue_label_change(line[1:])
			tempHead += 1
			continue
		}

		//open choice menu
		if(line[0] == '>'){
			if dialogue.choices_interjection_block_end != 0{ //skip over ignored interjections
				tempHead = dialogue.choices_interjection_block_end
				clear(&dialogue.choices)
				dialogue.choices_interjection_block_end = 0
				continue
			}

			blockScanHead := tempHead
			blockScannedLine := line
			for len(blockScannedLine)>0 && blockScannedLine[0] == '>'{
				if(blockScannedLine[:len(">	")] != ">	"){ //new choice option
					choiceDisabled := false
					if string_contains(blockScannedLine, "`if"){
						e := string_slice_between(blockScannedLine, "`if", "`")
						if res,_:= dialogue_expression_parse(e, true); res != "1" do choiceDisabled = true
						blockScannedLine = blockScannedLine[:len(blockScannedLine)-(len(e)+len("`if`"))]
					}

					if labelJumpExpressionInd := string_index(blockScannedLine, "[[#"); labelJumpExpressionInd != -1{
						labelName := string_slice_between(blockScannedLine, "[[#", "]]")
						labelStruct, ok := d.labelsMap[labelName]
						assertf(ok, "Tried to use unknown label '%s' in choice", labelName)
						if dialogue_label_seen_get(dialogue.current, labelName) do choiceDisabled = true
						parsedLine := dialogue_line_parse(blockScannedLine[len(">"):labelJumpExpressionInd], dialogue.choices_allocator)
						append(&dialogue.choices, DialogueChoice{
							parsedLine,
							blockScanHead,
							labelName,
							choiceDisabled
						})
					}
					else{
						append(&dialogue.choices, DialogueChoice{
							dialogue_line_parse(blockScannedLine[len(">"):], dialogue.choices_allocator),
							blockScanHead,
							"",
							choiceDisabled
						})
					}
				}

				blockScanHead += 1
				blockScannedLine = _dialogue_line_remove_block_indent(d.lines[blockScanHead])
			}
			append(&dialogue._block_stack, DialogueBlock{
				isChoice = true,
				blockEndIndex = blockScanHead
			})
			return
		}

		//jump to new labels
		if(string_contains(line, "[[#")){
			dialogue._label_jump_interrupt = string_slice_between(line, "[[#", "]]")
		}

		//conditional blocks
		if(string_starts_with(line, "`if ")){
			conditionals := make([dynamic]DialogueConditional, context.temp_allocator)
			append(&conditionals, DialogueConditional{string_slice_between(line, "`if ", "`"), tempHead+1, -1})
			blockScanHead := tempHead+1
			for{
				blockScannedLine := _dialogue_line_remove_block_indent(d.lines[blockScanHead])
				if(string_starts_with(blockScannedLine, "	")){
					blockScanHead += 1
					continue
				}

				if(string_starts_with(blockScannedLine, "`else")){
					conditionals[len(conditionals)-1].endLine = blockScanHead
					expression:string
					if(string_starts_with(blockScannedLine, "`else if ")) do expression = string_slice_between(blockScannedLine, "`else if ", "`")
					else do expression = "1"
					append(&conditionals, DialogueConditional{expression, blockScanHead+1, -1})
					blockScanHead += 1
					continue
				}

				break
			}
			conditionals[len(conditionals)-1].endLine = blockScanHead

			conditionMet := false
			for &c in conditionals{
				res,_ := dialogue_expression_parse(c.expression, true)
				if(res != "0"){
					append(&dialogue._block_stack, DialogueBlock{
						false,
						c.endLine,
						blockScanHead
					})
					tempHead = c.startLine
					conditionMet = true
					break
				}
			}
			if(!conditionMet) do tempHead = blockScanHead
			continue
		}

		//parse line
		parsedLine := dialogue_line_parse(line)

		//label jump
		if dialogue._label_jump_interrupt != ""{
			labelName := dialogue._label_jump_interrupt
			labelStruct, ok := d.labelsMap[labelName]
			assertf(ok, "Tried to jump to unknown label: %s", labelName)
			tempHead = labelStruct.line+1
			clear(&dialogue._block_stack)
			_dialogue_label_change(labelName)
			dialogue._label_jump_interrupt = ""
			continue
		}

		if(len(parsedLine) == 0){
			if dialogue.auto_advance{ //never skip lines in auto mode 
				clear(&dialogue.display_runes)
				dialogue.typewriter_count = 0
				dialogue.head = tempHead
				break
			}
			else{
				tempHead += 1 //skip lines that are just expressions
				continue
			}
		}

		resize(&dialogue.display_runes, len(parsedLine))
		copy(dialogue.display_runes[:], parsedLine)

		firstPause := dialogue.display_runes[0].pause
		if(firstPause <= dialogue.typewriter_pause){
			dialogue.typewriter_count = 1 //looks better to start on the first character immediately
			if(len(dialogue.display_runes) >= 2) do dialogue.typewriter_pause_remaining = dialogue.display_runes[1].pause
		}
		else{
			dialogue.typewriter_count = 0
			dialogue.typewriter_pause_remaining = firstPause
		}

		dialogue.head = tempHead

		//interjections
		if tempHead+1 < len(d.lines){
			nextLine := _dialogue_line_remove_block_indent(d.lines[tempHead+1])
			if(string_starts_with(nextLine, ">!")){
				blockScanHead := tempHead+1
				blockScannedLine := nextLine
				for blockScannedLine[0] == '>'{
					if(!string_starts_with(blockScannedLine, ">	")){
						append(&dialogue.choices, DialogueChoice{
							dialogue_line_parse(blockScannedLine[len((blockScanHead == tempHead+1)?">!":">"):], dialogue.choices_allocator),
							blockScanHead,
							"",
							false
						})
					}
	
					blockScanHead += 1
					blockScannedLine = _dialogue_line_remove_block_indent(d.lines[blockScanHead])
				}
				dialogue.choices_interjection_block_end = blockScanHead
			}
		}
		break
	}

}

dialogue_choice_button :: proc(text:DialogueString, size:Vec2, itemVerticalPadding:f32) -> bool{
	selectedOffsetFactor :: 2.5

	ind := ui_frame().currentItem
	item := ui_item_process(size)
	pos := item.pos

	cs := char_size(display.hd_enabled?'S':text[0].myRune, text[0].font)
	//TODO: Baked-in ripple effect
	// if ui_frame().hoverChanged && state == .hovered{
	// 	// life :f32= 12
	// 	// r := cs.x
	// 	// spd := (r/life)*2
	// 	// shineParticle := particle_type(sp.white1, 
	// 	// 	int(life*0.667), int(life), spd,spd, acceleration=-spd/life, minScale=1, alphas={1,1,0}
	// 	// )
	// 	// particles_emit(shineParticle, 250, 1.75, Rect{pos+cs/2, 0})
	// 	ui_cue("dialogueChoiceHoverChanged")
	// }

	#partial switch item.interactState{
		case .idle, .disabled:
			if display.hd_enabled do dialogue_text_draw(text, Rect{pos, size}, false)
			else do dialogue_text_draw(text, Rect{pos, size}, false, color_hex(0x87949d), 1, 1, -1, true)
		case .hovered, .selected:
			if item.hoverTime == 0 do audio_play(au.uiHover)
			if item.interactState == .selected do audio_play(au.uiConfirm)
			off := ui_cue_map(item.hoverTime, 0, 2, 0, cs.x*selectedOffsetFactor)
			angle := ui_cue_map(item.hoverTime, 0, 5, 0, 90, cu.easeIn)
			scale := ui_cue_map(item.hoverTime, 0, 5,	0.33, 1, cu.easeIn)
			mixCol := display.hd_enabled ? COLOR_WHITE : color_hex(0x87949d)
			mixColAmount := display.hd_enabled ? ui_cue_map(item.hoverTime, 0, 5, 0, 0.3, cu.easeIn) : ui_cue_map(item.hoverTime, 0, 5, 1, 0, cu.easeIn)

			shineTex := dialogue.choices_shine_tex
			texDp := pos+cs/2 - Vec2(shineTex.size)/2
			if display.hd_enabled do sprite_draw_ex(sp.shineAnimatedHD, Vec2{pos.x, pos.y-size.y/4}, sprite_frame_get(sp.shineAnimatedHD, f32(item.hoverTime)), 0.5, 0)
			else do sprite_draw_ex(sp.menuShine, Vec2{pos.x+cs.x/2+1, pos.y+size.y/2-1 - itemVerticalPadding/2}, 0, scale, angle)
			dialogue_text_draw(text, Rect{pos+{off,0}, size}, false, mixCol, mixColAmount, dropShadow=!display.hd_enabled)
			// tex_target_set(shineTex, texDp, false)
			// draw_clear(COLOR_BLACK, 0)
			// dialogue_text_draw(text, Rect{pos+{off,0}, size}, false, false)
			// tex_target_reset()
			// tex_draw(shineTex, texDp)
	}

	return item.interactState == .selected
}

dialogue_hd_box_draw :: proc(rect:Rect, alpha:f32=1){
	//trace("HD Box")
	shadowPad :: 40
	drawTex := tex_make(rect.size, true)
	maskTex := tex_make(rect.size, true)
	gradientTex := tex_make(rect.size, true)
	finalTex := tex_make(rect.size+shadowPad*2, true)
	defer tex_destroy(drawTex)
	defer tex_destroy(maskTex)
	defer tex_destroy(gradientTex)
	defer tex_destroy(finalTex)

	tex_target_set(maskTex)
		nineslice_draw(sp.dialogueBoxHDMask_cutout, Rect{0,rect.size})
	tex_target_set(gradientTex)
		nineslice_draw(sp.dialogueBoxHDMask_gradient, Rect{0,rect.size})
	tex_target_set(drawTex)
		scale := Vec2{1,1}
		if rect.size.x > sp.matteCardstockLight.size.x do scale.x = rect.size.x/sp.matteCardstockLight.size.x
		if rect.size.y > sp.matteCardstockLight.size.y do scale.y = rect.size.y/sp.matteCardstockLight.size.y
		sprite_draw_ex(sp.matteCardstockLight, 0,0,scale=scale)

		tex_blendmode_set(maskTex, .subtractInverse)
		tex_draw(maskTex, 0, 0)
		tex_blendmode_set(gradientTex, .multiply)
		tex_draw(gradientTex, 0, 0)
	tex_target_set(finalTex) //reused for final render
		finalDrawPos := rect.pos-{shadowPad, shadowPad/2}
		tex_draw(display_main_tex(), -finalDrawPos) //for alpha blend
		nineslice_draw(sp.dialogueBoxHDMask_dropShadow, Rect{0,rect.size+shadowPad*2})
		tex_draw(drawTex, {shadowPad, shadowPad/2})
	tex_target_reset(4)

	tex_draw_ex(finalTex, finalDrawPos, alpha=alpha)
	//nineslice_draw(sp.dialogueBoxHDMask_cutout, rect)
}

DialogueChoiceOptions :: union{[]string, []DialogueString}
dialogue_choice_menu :: proc(options:DialogueChoiceOptions, pos:Vec2, alignment:Alignment={-1,-1}) -> int{
	ui_cue("dialogueChoice")
	choiceBoxRect:Rect
	choicePadding := Vec2{10,8}
	bottomPadding :f32= 10 //nineslice sprite has more empty space near bottom
	itemVerticalPadding :f32= 6
	selectedOffsetFactor :: 2.5

	if display.hd_enabled{
		choicePadding = {80,64}
		itemVerticalPadding = 30
		bottomPadding = 80
	}

	textDataStruct :: struct{
		ds:DialogueString,
		size:Vec2
	}
	textData:[]textDataStruct
	switch t in options{
		case []DialogueString:
			textData = make([]textDataStruct, len(t), context.temp_allocator) 
			for ds,i in t{textData[i].ds = ds}
		case []string: 
			textData = make([]textDataStruct, len(t), context.temp_allocator) 
			dialogue.color = COLOR_WHITE
			dialogue.font = fo.fairfax__12
			for str,i in t{ textData[i].ds = dialogue_line_parse(str)}
	}

	charWidth:f32
	for &data in textData{
		data.size = dialogue_text_size(data.ds, display.hd_enabled ? 1976:247)
		choiceBoxRect.size.x = max(choiceBoxRect.size.x, data.size.x+choicePadding.x)
		choiceBoxRect.size.y += data.size.y + itemVerticalPadding
		charWidth = max(charWidth, char_size(display.hd_enabled?'S':data.ds[0].myRune, data.ds[0].font).x)
	}

	choiceBoxRect.size += choicePadding
	choiceBoxRect.size.x += charWidth*selectedOffsetFactor
	choiceBoxRect.size.y += bottomPadding - itemVerticalPadding

	rect_align(&choiceBoxRect, pos, alignment)
	choiceBoxRect.pos = round(choiceBoxRect.pos)

	choicePopupRect:Rect
	if display.hd_enabled{
		dialogue_hd_box_draw(choiceBoxRect, ui_cue_map("dialogueChoice", 0,BOX_POPUP_TIME_DEFAULT,0,1))
		choicePopupRect=choiceBoxRect
	}
	else{
		if ui_cue_time("dialogueChoice") == 0 do audio_play(au.uiBoxOpen)
		choicePopupRect = rect_scaled_in_place(choiceBoxRect, box_popup_scale(ui_cue_time("dialogueChoice"), true))
		choicePopupRect.pos = round(choicePopupRect.pos)
		choicePopupRect.size = round(choicePopupRect.size)
		nineslice_draw(sp.dialogueChoiceBox, choicePopupRect)
	}

	if choicePopupRect != choiceBoxRect{
		choicePopupRect.x += choicePadding.x
		choicePopupRect.y += choicePadding.y
		choicePopupRect.size.x -= choicePadding.x*2
		choicePopupRect.size.y -= choicePadding.y*2
	}

	choiceBoxRect.x += choicePadding.x
	choiceBoxRect.y += choicePadding.y
	choiceBoxRect.size.x -= choicePadding.x
	choiceBoxRect.size.y -= choicePadding.y*2 - bottomPadding
	
	choicePopupRect.size = max(Vec2{}, choiceBoxRect.size)
	choiceTex := tex_make(choicePopupRect.size, display.hd_enabled)
	defer tex_destroy(choiceTex)

	tex_target_set(choiceTex, choicePopupRect.pos)

	out := -1
	ui_begin("dialogueChoices", choiceBoxRect.pos)
		if ui_cue_time("dialogueChoice") < 10 || dialogue.log_open || ui_cue_time("dialogueLogFade") < 10 do ui.disabled = true
		for data,i in textData{
			if dialogue_choice_button(data.ds, data.size + {0, itemVerticalPadding}, itemVerticalPadding){
				out = i
			}
		}
		ui.disabled = false
	ui_end()

	tex_target_reset()

	tex_draw(choiceTex, choicePopupRect.pos)
	return out
}

@(disabled=ODIN_DEBUG&&DIALOGUE_LOG_DISABLE)
dialogue_log_append :: proc(line:DialogueString, speaker:^Sprite=nil){
	if display.hd_enabled || dialogue.hd_overlay_enabled do return //hd speech is not logged (todo: for now?)
	inject_at(&dialogue.log, 0, DialogueLogEntry{clone(line), speaker})
	if len(dialogue.log) > DIALOGUE_LOG_CAP{
		popped := pop(&dialogue.log)
		delete(popped.line)
	}
}

_dialogue_line_remove_block_indent :: proc(line:string) -> string{
	out := line
	for block in dialogue._block_stack{
		cutInd := block.isChoice ? len(">	") : len("	")
		if len(out) < cutInd do break
		out = out[cutInd:]
	}
	return out
}

_dialogue_system_update :: proc(){
	if(dialogue.current == nil || (cutscene.current != nil && cutscene.interruptDialogue)) do return

	skipping := settings.dialogue_skip_enabled && ((key_mods_held({.CTRL}) && key_held(.RETURN)) || (ginputs[.ltHeld] && ginputs[.rtHeld]))

	choiceIsInterjection := dialogue.choices_interjection_block_end != 0

	if choiceIsInterjection && !dialogue.choices_show_interjection{
		checkRect := dialogue.interjection_sprite_draw_rect
		rect_resize_in_place(&checkRect, checkRect.size.x, checkRect.size.y)
		if !dialogue.log_open && (ginputs[.extra] || (rect_contains(checkRect, mouse_display_pos()) && ginputs[.confirm])){
			dialogue.choices_show_interjection = true
			ui_cue("dialogueChoiceInterjection")
			return
		}
	}
	else if(len(dialogue.choices) > 0){
		if choiceIsInterjection do ui_cue("dialogueChoiceInterjection")
		// oldInd := dialogue.choices_selected_index
		// dialogue.choices_selected_index = clamp(
		// 	dialogue.choices_selected_index + int(ginputs[.down]) - int(ginputs[.up]),
		// 	0, len(dialogue.choices)-int(!choiceIsInterjection)
		// )

		// if oldInd != dialogue.choices_selected_index do ui_cue("dialogueChoiceHoverChanged")

		return
	}

	lineLength := len(dialogue.display_runes)
	playDialogueSound :: proc(){
		if ui_cue_time("dialogueSound") >= 4{
			audio_play(display.hd_enabled ? au.hdSpeech : au.chipSpeech)
			ui_cue("dialogueSound")
		}
	}

	if(dialogue.typewriter_count < lineLength){
		if(
			!dialogue.auto_advance &&
			(skipping || 
				(!dialogue.unskippable && 
					((settings.dialogue_one_button_advance && ginputs[.confirm]) || ginputs[.cancel] || ginputs[.option])
				)
			)
		){
			dialogue.typewriter_count = lineLength
		}
		else if (dialogue.typewriter_pause_remaining > 0){
			dialogue.typewriter_pause_remaining -= 1
			if(dialogue.typewriter_pause_remaining <= 0){
				dialogue.typewriter_count += 1
				playDialogueSound()
			}
		}
		else{
			dialogue.typewriter_pause_remaining -= 1
			for dialogue.typewriter_count < lineLength{
				nextRune := dialogue.display_runes[dialogue.typewriter_count]
				dialogue.typewriter_pause_remaining += nextRune.pause
				if(dialogue.typewriter_pause_remaining < 1){
					dialogue.typewriter_count += 1
					playDialogueSound()
				}
				else do break
			}
		}
	}
	else{
		dialogue.typewriter_pause_remaining = 0

		if dialogue.auto_advance{
			if dialogue.auto_advance_time >= 0{
				dialogue.auto_advance_timer -= 1
				if dialogue.auto_advance_timer <= 0{
					dialogue.auto_advance_timer = dialogue.auto_advance_time
					dialogue_log_append(dialogue.display_runes[:], dialogue.portrait)
					dialogue_next_line()
				}
			}
		}
		else{
			dialogue.unskippable = false
			confirmed := ginputs[.confirm]
			if choiceIsInterjection do ui_cue("dialogueChoiceInterjection")
			if ui_cue_time("dialogueChoiceInterjection") <= 46 do confirmed = false

			dialogue.log_button_rect = Rect{0, text_size("Log", dialogue.log_button_font)}
			rect_align(&dialogue.log_button_rect, rect_get_bottom_right(DIALOGUE_BOX_RECT) - {6,9}, {1,1})
			if !(dialogue.log_open || rect_contains(dialogue.log_button_rect, mouse_display_pos())) && (confirmed || skipping){
				dialogue_log_append(dialogue.display_runes[:], dialogue.portrait)
				dialogue_next_line()
			}
		}
		
	}
}

_dialogue_system_draw :: proc(){
	//trace("Dialogue Draw")

	boxRect:Rect
	padding:Vec2
	if display.hd_enabled{
		boxRect = Rect{{468, 1584}, sp.dialogueBoxHD.size}
		padding = {530, 100}

		//portraits
		dpl := Vec2{boxRect.x-360, DISPLAY_HEIGHT_HD}
		dpr := Vec2{rect_get_right(boxRect)+155, DISPLAY_HEIGHT_HD}
		
		fadeProgress:[2]f32 = 1
		unfocusedColor :Color: 127
		color:[2]Color
		offsetAmount :: 20
		offset:[2]f32

		portraitChangedProgress := ui_cue_map("hdPortraitChanged", 0, 6, 0, 1)
		talkerChangedProgress := ui_cue_map("hdTalkerChanged", 0, 6, 0, 1)
		
		fadeTime := ui_cue_time("dialogueHDFade")
		if fadeTime < 60{
			fadeProgress = ui_cue_map("dialogueHDFade", 0, 60, 0, 1)
			if dialogue.hd_portrait_active != 2{
				color[dialogue.hd_portrait_active] = COLOR_WHITE
				color[(dialogue.hd_portrait_active+1)%2] = unfocusedColor
				offset[(dialogue.hd_portrait_active+1)%2] = offsetAmount*-f32(dialogue.hd_portrait_active*2-1)
			}
			else do color = COLOR_WHITE 
		}
		else if dialogue.current == nil do return
		else if dialogue.hd_portrait_active == 2{
			fadeProgress = portraitChangedProgress
			color = COLOR_WHITE
		}
		else{
			fadeProgress[dialogue.hd_portrait_active] = portraitChangedProgress
	
			color[dialogue.hd_portrait_active] = color_lerp(unfocusedColor, COLOR_WHITE, talkerChangedProgress)
			color[(dialogue.hd_portrait_active+1)%2] = color_lerp(COLOR_WHITE, unfocusedColor, talkerChangedProgress)
	
			offset[dialogue.hd_portrait_active] = (1-talkerChangedProgress)*offsetAmount*f32(dialogue.hd_portrait_active*2-1)
			offset[(dialogue.hd_portrait_active+1)%2] = talkerChangedProgress*offsetAmount*-f32(dialogue.hd_portrait_active*2-1)
		}

		drawHDPortrait :: proc(portrait:DialogueHDPortrait, drawPos:Vec2, headOffset:Vec2, color:Color, alpha:f32){
			//trace("HD Portrait")
			drawTex := tex_make(portrait.body.size, true)
			tex_blendmode_set(drawTex, .accumulate)
			defer tex_destroy(drawTex)
			tex_target_set(drawTex)
				sprite_draw(portrait.body, 0,0)
				sprite_draw(portrait.head, headOffset)
			tex_target_reset()
			tex_draw_ex(drawTex, drawPos, color=color, alpha=alpha)
		}

		tex_target_set(dialogue.hd_portraits_tex, clear=false)
		draw_clear(COLOR_BLACK, 0)
		if (dialogue.hd_portraits_prev[0] != DialogueHDPortrait{}){
			drawHDPortrait(dialogue.hd_portraits_prev[0], dpl - {0, dialogue.hd_portraits_prev[0].body.size.y}+{offset[0],0}, {695,49}*7./12., color[0], 1-fadeProgress[0])
		}
		if (dialogue.hd_portraits[0] != DialogueHDPortrait{}){
			drawHDPortrait(dialogue.hd_portraits[0], dpl - {0, dialogue.hd_portraits[0].body.size.y}+{offset[0],0}, {695,49}*7./12., color[0], fadeProgress[0])
		}

		if (dialogue.hd_portraits_prev[1] != DialogueHDPortrait{}){
			drawHDPortrait(dialogue.hd_portraits_prev[1], dpr - dialogue.hd_portraits_prev[1].body.size+{offset[1],72}, {1151,68}*9./16., color[1], 1-fadeProgress[1])
		}
		if (dialogue.hd_portraits[1] != DialogueHDPortrait{}){
			drawHDPortrait(dialogue.hd_portraits[1], dpr - dialogue.hd_portraits[1].body.size+{offset[1],72}, {1151,68}*9./16., color[1], fadeProgress[1])
		}
		tex_target_reset()

		tex_draw(dialogue.hd_portraits_tex, 0, 0)

		if dialogue.hd_overlay_enabled{ //do not use dialogue box when overlaying
			drawGradient := (dialogue.text_rect == Rect{}) && !dialogue.hd_overlay_fade_interrupt_disable_flag
			gradientH :f32= 804
			ds := DISPLAY_SIZE_HD
			if drawGradient{
				ui_cue("dialogueHDGradientFadeIn")
				gradientBaseCol := u8(ui_cue_map("dialogueHDGradientFadeIn", 0, DIALOGUE_HD_OVERLAY_TRANSITION_DURATION, 0, 255, cu.easeIn))
				gradientBlends := [4]Blend{0, 0, {0,0,0,gradientBaseCol}, {0,0,0,gradientBaseCol}}
				draw_rect_gradient(rect_make_points(Vec2{0, ds.y-gradientH}, ds), gradientBlends)
			}
			else{
				ui_cue("dialogueHDGradientFadeOut")
				gradientBaseCol := u8(ui_cue_map("dialogueHDGradientFadeOut", 0, DIALOGUE_HD_OVERLAY_TRANSITION_DURATION, 255, 0, cu.easeOut))
				gradientBlends := [4]Blend{0, 0, {0,0,0,gradientBaseCol}, {0,0,0,gradientBaseCol}}
				draw_rect_gradient(rect_make_points(Vec2{0, ds.y-gradientH}, ds), gradientBlends)
			}
		}
		else{
			if len(dialogue.display_runes) == 0 || dialogue.typewriter_count == 0{
				if ui_cue_time("dialogueHDBoxFadeIn", true) <= 6 do ui_cue("dialogueHDBoxFadeOut")
				if time.frame < 6 do return
				sprite_draw_ex(sp.dialogueBoxHD, boxRect.pos, alpha=ui_cue_map("dialogueHDBoxFadeOut", 0, 6, 1, 0))
				return //portraits always draw even during pauses in dialogue in hd mode
			}
	
			//box
			ui_cue("dialogueHDBoxFadeIn")
			dialogue_hd_box_draw(boxRect, ui_cue_map("dialogueHDBoxFadeIn", 0, 6, 0, 1))
			//sprite_draw_ex(sp.dialogueBoxHD, boxRect.pos, alpha=)
		}

	}
	else{
		if dialogue.current == nil || len(dialogue.display_runes) == 0 || dialogue.typewriter_count == 0 do return
		boxRect = DIALOGUE_BOX_RECT
		nineslice_draw(sp.dialogueBox, boxRect)
		padding = {18,12}
		
		//portrait/name tag
		if(dialogue.portrait != nil){
			pPos := boxRect.pos + {18, -15}
			sprite_draw(sp.dialoguePortraitShadow, pPos)
			sprite_draw(dialogue.portrait, pPos, sprite_frame_get(dialogue.portrait))
			sprite_draw(sp.dialoguePortraitBorder, pPos)
		}
		else if dialogue.name_tag != ""{
			ntBoxRect := Rect{0, text_size(dialogue.name_tag, fo.fairfax__12) + padding-6}
			rect_align(&ntBoxRect, boxRect.pos-{6,2}, Alignment{-1,0})
			nineslice_draw(sp.menuBoxOutlined, ntBoxRect)
			text_draw(dialogue.name_tag, rect_center(ntBoxRect), COLOR_WHITE, 1, fo.fairfax__12, 0)
		}

		//log button
		if len(dialogue.log) > 0{
			hovering := !dialogue.log_open && rect_contains(dialogue.log_button_rect, mouse_display_pos())

			alpha :f32= hovering?1:0.3
			if input_device() == .gamepad{
				alpha = 0.4
				sprite_draw_ex(sp.dialogueLogGamepadButtonPrompt, dialogue.log_button_rect.pos + {-4, 3}, alpha=alpha)
			}
			text_draw("Log", dialogue.log_button_rect, COLOR_WHITE, alpha, font=dialogue.log_button_font)

			if (dialogue.log_open && (ginputs[.confirm] || ginputs[.cancel])) || (hovering && ginputs[.confirm]) || (!key_mods_held({.CTRL}) && ginputs[.select]){
				dialogue.log_open = !dialogue.log_open
				dialogue.log_scroll = 0
				ui_cue("dialogueLogFade")
			}
		}
	}
	
	textRect := dialogue.text_rect
	if (textRect == Rect{}){ //if no custom rect is set, use default behavior 
		textRect = boxRect
		textRect.pos += padding
		if !display.hd_enabled && dialogue.portrait != nil do textRect.pos.x += dialogue.portrait.size.x + padding.x - 6
		rect_set_right(&textRect, rect_get_right(boxRect)-padding.x, true)
		rect_set_bottom(&textRect, rect_get_bottom(boxRect)-padding.y, true)
	}
	
	dialogue_text_draw(dialogue.display_runes[:], textRect, dialogue.text_centered, maxChars=dialogue.typewriter_count, dropShadow=!display.hd_enabled)

	fonts.default = dialogue.font_default
	choiceIsInterjection := dialogue.choices_interjection_block_end != 0
	if(choiceIsInterjection && !dialogue.choices_show_interjection){
		if dialogue.typewriter_count >= len(dialogue.display_runes){
			drawPos := Vec2{rect_get_right(boxRect)-padding.x+4, boxRect.y+padding.y+1}
			t := ui_cue_time("dialogueChoiceInterjection")
			if t == 0{
				particles_emit(dialogue.interjection_particle, 8, -INF, Rect{drawPos, 0})
				audio_play(au.interjectionAppears)
			}
			interjectionSpr := display.hd_enabled ? sp.shineAnimatedHD : sp.shineAnimated24px
			sprite_draw(interjectionSpr, drawPos, sprite_frame_get(interjectionSpr, f32(t)))
			dialogue.interjection_sprite_draw_rect = sprite_draw_rect(interjectionSpr, drawPos)
		}
	}
	else if(len(dialogue.choices) > 0){

		options := make([dynamic]DialogueString, context.temp_allocator)
		for choice in dialogue.choices{
			if choice.disabled do continue
			append(&options, choice.displayString)
		}

		if choiceIsInterjection{
			append(&options, DialogueString{
				{'.', dialogue.color, dialogue.font, 0},
				{'.', dialogue.color, dialogue.font, 0},
				{'.', dialogue.color, dialogue.font, 0},
			})
		}

		n := dialogue_choice_menu(options[:], Vec2{
			rect_get_right(boxRect) + 13,
			boxRect.y + 5
		}, {1,1})

		if n != -1{
			if choiceIsInterjection && n == len(options)-1 do dialogue.choices_show_interjection = false
			else{
				choice:DialogueChoice
				choiceInd:int
				for n_ := 0; c, i in dialogue.choices{
					if c.disabled do continue
					if n_ == n{
						choice = c
						choiceInd = i
						break
					}
					n_+=1
				}
				
				dialogue_log_append(choice.displayString, sp.shineAnimated24px)

				if dialogue.choices_interjection_block_end != 0 {
					append(&dialogue._block_stack, DialogueBlock{
						isChoice = true,
						blockEndIndex = dialogue.choices_interjection_block_end
					})
				}

				block := &dialogue._block_stack[len(dialogue._block_stack)-1]
				if(choiceInd < len(dialogue.choices)-1){
					block.endIndex = dialogue.choices[choiceInd+1].lineIndex
				}
				else do block.endIndex = block.blockEndIndex

				if choice.jumpLabel != "" do dialogue_jump_to_label(choice.jumpLabel)
				else{
					dialogue.head = choice.lineIndex
					dialogue_choice_close()
					dialogue_next_line()
				}
			}
		}
	}

	//dialogue log
	if !display.hd_enabled{
		fadeDur :: 10
		logAlpha :f32= dialogue.log_open ? ui_cue_map("dialogueLogFade", 0, fadeDur, 0, 1) : ui_cue_map("dialogueLogFade", 0, fadeDur, 1, 0)
		if logAlpha > 0{
			draw_rect(Rect{0, display_size()}, COLOR_BLACK, alpha=logAlpha*0.7)

			logPadding :Vec2= {15,12}
			startY :=  196 - text_char_height(dialogue.font_default)*2
			logBoxRect := DIALOGUE_BOX_RECT
			portraitPad := sp.pro.size.x*0.25 + 8
			rect_set_left(&logBoxRect, logBoxRect.x + logPadding.x + portraitPad, true)
			rect_set_top(&logBoxRect, startY)
			rect_set_right(&logBoxRect, rect_get_right(logBoxRect) - logPadding.x, true)
			logBoxRect.size.y = 1

			//compute total content height
			lineHeights := make([]f32, len(dialogue.log), context.temp_allocator)
			totalH :f32= 0
			for entry, i in dialogue.log{
				lineH := dialogue_text_size(entry.line, logBoxRect.size.x).y + text_char_height(dialogue.font_default)
				totalH += lineH
				lineHeights[i] = lineH
			}

			//scroll
			scrollMax := max(f32(0), totalH - startY + logPadding.y)
			if dialogue.log_open do dialogue.log_scroll = clamp(dialogue.log_scroll - f32(input.mouse_scroll)*16, 0, scrollMax)

			
			drawTex := tex_make(logBoxRect.size + Vec2{portraitPad, startY})
			texDrawPos := Vec2{logBoxRect.x - portraitPad, 0}
			defer tex_destroy(drawTex)

			tex_target_set(drawTex, texDrawPos)
			logBoxRect.y += dialogue.log_scroll
			for entry,i in dialogue.log{
				logBoxRect.y -= lineHeights[i]
				if logBoxRect.y > startY do continue
				if entry.speaker != nil{
					portraitScale :Vec2= 0.25
					portraitPos := Vec2{logBoxRect.x - entry.speaker.size.x*portraitScale.x - 4, logBoxRect.y}
					if entry.speaker == sp.shineAnimated24px{
						portraitScale = 1
						portraitPos = Vec2{logBoxRect.x, logBoxRect.y} + sprite_origin(sp.shineAnimated24px) - Vec2{sp.shineAnimated24px.size.x+1, 7}
					}
					sprite_draw_ex(entry.speaker, portraitPos, sprite_frame_get(entry.speaker), portraitScale)
				}
				dialogue_text_draw(entry.line, logBoxRect, mixCol=color_hex(0xffe7b8), mixColAmount=1)
				if logBoxRect.y < 0 do break
			}
			tex_target_reset()
			tex_draw_ex(drawTex, texDrawPos, alpha=logAlpha)
		}
	}
}
