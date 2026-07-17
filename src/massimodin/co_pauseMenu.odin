#+feature using-stmt
package massimodin //@nested-tags:_components/

import "base:intrinsics"
import "core:reflect"

PauseMenu :: struct{
	using base:RenderComponentBase,
	currentTab:PauseMenuTab,
	statusCharacter:Maybe(PlayerCharacterID),
	inventoryCategory:Maybe(ItemKind),
	inventorySelectedItem:^Item,
	controlsTab:PauseMenuControlsTab,
	quitting:bool,
	headerTex:Tex,
}

PauseMenuTab :: enum{
	status,
	inventory,
	settings,
	controls,
	quit
}

PauseMenuControlsTab :: enum{
	basic,
	dialogue,
	combat
}

PAUSE_MENU_TEXT_COL :: 0xc29566

//called when switching to the status tab, checks if only one party member exists and if so immediately selects them
pauseMenu_status_character_update :: proc(self:^PauseMenu){
	self.statusCharacter = .pro
	if true do return //todo: change this once character select page is in

	partyMemberFound:bool
	for charID in PlayerCharacterID{
		if save.characters[charID].inParty{
			if partyMemberFound{ //more than one party member, display character select
				self.statusCharacter = nil
				break
			}
			self.statusCharacter = charID
			partyMemberFound = true
		}
	}
}

pauseMenu_tab :: proc(self:^PauseMenu, tab:PauseMenuTab, centerPos:Vec2){
	text := dialogue_line(di.pause, "tabs", int(tab))

	ts := text_size(text)
	selectorRect:Rect
	selectorRect.size = ts
	rect_center_set(&selectorRect, centerPos)
	rect_resize_in_place(&selectorRect, 9, 3)
	selectorRect.pos = round(selectorRect.pos)
	selectorRect.size = round(selectorRect.size)
	item := ui_item_process(selectorRect)

	tabStateTarget:f32

	#partial switch item.interactState{
		case .selected:
			self.currentTab = tab
			#partial switch tab{
				case .status:
					pauseMenu_status_character_update(self)
				case .inventory:
					self.inventorySelectedItem = nil
			}
		case .hovered:
			tabStateTarget = 0.5
	}

	if self.currentTab == tab do tabStateTarget = 1

	tabState := ui_cue_map_stateful(imkey_combine(item.index), 5, tabStateTarget, cueMap=&ui_frame().cueMap)


	selectorFrame := int(lerp(0, 4, tabState))
	textCol := color_lerp(color_hex(0xa29179), color_hex(0xf1f1f1), tabState)

	nineslice_draw(sp.headerSelector, selectorRect, selectorFrame)
	text_draw(text, item.pos+{9,2}, textCol)
}

settings_menu :: proc(){
	descriptionDraw :: proc(label:string, descriptionRect:=Rect{}, textCol:Color=COLOR_WHITE){
		descriptionLabel := format("%sDescription", label)
		if display.hd_enabled && descriptionLabel in dialogue_data(di.settings).labelsMap{
			drawRect := descriptionRect
			buffer := Vec2{64,64}
			rect_resize_in_place(&drawRect, -buffer)
			drawRect.size.y = dialogue_paragraph_size(drawRect, di.settings, descriptionLabel, fo.newsreader__48).y
			rect_resize_in_place(&drawRect, buffer)
			dialogue_hd_box_draw(drawRect)
			rect_resize_in_place(&drawRect, -buffer)
			dialogue_paragraph_draw(drawRect, di.settings, descriptionLabel, textCol, fo.newsreader__48)
		}
	}

	toggle :: proc(label:string, itemSize:Vec2, val:^bool, textCol:Color, descriptionRect:=Rect{})->bool{
		item := ui_item_process(itemSize)

		if item.interactState == .selected do val^ = !val^

		drawCol := (item.interactState == .hovered || item.interactState == .selected) ? color_lerp(textCol, COLOR_WHITE, 0.5) : textCol
		text_draw(dialogue_line(di.settings, label), item.pos, drawCol, 1)
		spr := sprite_find(format("settings_toggleButton%s_flip%s", display.hd_enabled?"HD":"", (val^)?"On":"Off"))
		sprite_draw(spr, item.pos + Vec2{itemSize.x-spr.size.x,itemSize.y/2}, sprite_frame_get(spr, item.selectTime, true))

		if item.interactState == .hovered do descriptionDraw(label, descriptionRect, textCol)

		return item.interactState == .selected
	}

	selector :: proc(label:string, itemSize:Vec2, valPtr:union{^f32,^int}, textCol:Color, min:f32, max:f32, increment:f32=1, selectorText:="", descriptionRect:=Rect{}) -> bool{
		interacted:bool
		val:f32
		switch v in valPtr{
			case ^f32: val = v^
			case ^int: val = f32(v^)
		}
		selectorText := selectorText
		if selectorText == "" do selectorText = format("%.0f", val)

		frame := ui_frame()

		spr := display.hd_enabled ? sp.settings_selectorArrowHD : sp.settings_selectorArrow
		arrowSize := spr.size

		selectorRects:[2]Rect
		selectorRects[0].size = Vec2{text_size(selectorText).x + arrowSize.x*2 + 4, itemSize.y}
		selectorRects[0].pos.x = frame.cursorPos.x + itemSize.x - selectorRects[0].size.x
		selectorRects[0].pos.y = frame.cursorPos.y
		selectorRects[0].size.x /= 2
		selectorRects[1] = selectorRects[0]
		selectorRects[1].x += selectorRects[1].size.x

		hoveredDir:f32= 0
		itemIndex := frame.currentItem
		isHovered := frame.hoveredItem == itemIndex
		if input_device() == .keyboard{
			mdp := mouse_display_pos()
			if !ui.disabled{
				for r,i in selectorRects{
					if rect_contains(r, mdp){
						frame.hoveredItem = itemIndex
						isHovered = true
						hoveredDir = f32(i*2-1)
					}
				}
			}
		}
		else if isHovered && !ui.disabled{
			if ginputs[.left] do hoveredDir = -1
			else if ginputs[.right] do hoveredDir = 1
		}

		if hoveredDir != 0{
			if input_device() == .keyboard{
				if ginputs[.confirm]{
					lastVal := val
					val = clamp(val+increment*hoveredDir, min, max)
					if val != lastVal do interacted = true
				}
			}
			else{
				lastVal := val
				val = clamp(val+increment*hoveredDir, min, max)
				if val != lastVal do interacted = true
			}
		}

		drawCol := isHovered ? color_lerp(textCol, COLOR_WHITE, 0.25) : textCol
		arrowCol := isHovered ? COLOR_WHITE : 204
		text_draw(dialogue_line(di.settings, label), frame.cursorPos, drawCol, 1)
		text_draw(selectorText, selectorRects[0].pos + Vec2{arrowSize.x, 0}, drawCol, 1)
		sprite_draw_ex(spr, selectorRects[0].pos + Vec2{arrowSize.x-3, arrowSize.y/3}, color=arrowCol, scale=Vec2{-1,1})
		sprite_draw_ex(spr, rect_get_right(selectorRects[1]) - (arrowSize.x+2), selectorRects[1].y+arrowSize.y/3, color=arrowCol)

		if isHovered do descriptionDraw(label, descriptionRect, textCol)
		
		frame.currentItem += 1

		frame.cursorPos[frame.cursorMoveAxis] += itemSize[frame.cursorMoveAxis]

		switch v in valPtr{
			case ^f32: v^ = val
			case ^int: v^ = int(val)
		}

		return interacted
	}

	optionSelector :: proc(label:string, itemSize:Vec2, valPtr:^$T, textCol:Color, descriptionRect:=Rect{})->bool where intrinsics.type_is_enum(T){
		intPtr := cast(^int)valPtr
		selectorText:string
		selectorText = dialogue_line(di.settings, format("%sEnum", label), intPtr^)
		return selector(
			label, itemSize, intPtr, textCol, 
			0, f32(len(T)-1), 1,
			selectorText, 
			descriptionRect
		)
	}

	volumeSelector :: proc(label:string, itemSize:Vec2, v:^f32, textCol:Color){
		sLabel := format("%3.0f%%", v^*100)
		if sLabel[0] == '0'{
			b := transmute([]u8)sLabel
			b[0] = ' '
			if sLabel[1] == '0' do b[1] = ' '
		} 
		if selector(label, itemSize, v, textCol, 0,2, 0.1, sLabel) do audio_apply_settings()
	}

	buffer := 		display.hd_enabled ? Vec2{128,64} : Vec2{5,6}
	textCol := 		display.hd_enabled ? color_hex(HD_MENU_TEXT_COL) : color_hex(PAUSE_MENU_TEXT_COL)
	itemFont := 	display.hd_enabled ? fo.notoSerif__64 : fo.PixelCode__9

	windowRect:Rect
	if display.hd_enabled{
		windowRect = Rect{0, {1280, 1760}}
		rect_align(&windowRect, DISPLAY_SIZE_HD/2, 0)
		dialogue_hd_box_draw(windowRect)
	}
	else{
		windowRect = Rect{0, {200, 230}}
		rect_align(&windowRect, Vec2{DISPLAY_WIDTH/2, 151}, 0)
		nineslice_draw(sp.menuBoxOutlined, windowRect)
	}

	descriptionRect := windowRect
	descriptionRect.x += windowRect.size.x+64
	rect_set_right(&descriptionRect, DISPLAY_SIZE_HD.x - 64, true)
	
	rect_resize_in_place(&windowRect, -buffer)

	ui_frame_begin(windowRect)
	itemSize := Vec2{windowRect.size.x, text_char_height(itemFont)}

	sectionHeading :: proc(label:string, itemSize:Vec2, textCol:Color){
		ui_cursor().y += itemSize.y/2
		ui.disabled = true
		itemFont := fonts.default
		fonts.default = display.hd_enabled ? fo.newsreaderBold__70 	: fo.Compass__16
		ui_text(dialogue_line(di.settings, label), textCol)
		fonts.default = itemFont
		ui.disabled = false
	}

	fonts.default = itemFont

	//display
	sectionHeading("display", 0, textCol)
	if selector("windowScale", itemSize, &settings.window_scale, textCol, 1, min(ceil(monitor_size()/DISPLAY_SIZE)), descriptionRect=descriptionRect) do window_resize(settings.window_scale)
	if toggle("fullscreen", itemSize, &settings.window_fullscreen, textCol, descriptionRect) do window_set_fullscreen(settings.window_fullscreen)
	if display.hd_enabled{
		pm:=settings.performance_mode
		if optionSelector("displayQuality", itemSize, &pm, textCol, descriptionRect){
			proc_call_delayed(callback_make(proc(pm:^DisplayPerformanceMode){display_performance_mode_set(pm^)}, pm), 1) //this clears the tex target which could mess with rendering, so we delay the call
		}
	}

	//game
	sectionHeading("game", itemSize, textCol)
	optionSelector("dashMode", itemSize, &settings.dash_mode, textCol, descriptionRect)
	
	//dialogue
	sectionHeading("dialogue", itemSize, textCol)
	selector(
		"language", itemSize, cast(^int)&settings.locale, textCol, 
		0, f32(len(dialogue.locales_loaded)-1), 1,
		locale_display_name(settings.locale), 
		descriptionRect
	)
	toggle("dialogueAdvance", itemSize, &settings.dialogue_one_button_advance, textCol, descriptionRect)
	toggle("dialogueSkip", itemSize, &settings.dialogue_skip_enabled, textCol, descriptionRect)
	
	//audio
	sectionHeading("volume", itemSize, textCol)
	volumeSelector("volumeMaster", itemSize, &settings.master_volume, textCol)
	volumeSelector("volumeMusic", itemSize, &settings.music_volume, textCol)
	volumeSelector("volumeSFX", itemSize, &settings.sfx_volume, textCol)
	volumeSelector("volumeAmbience", itemSize, &settings.ambience_volume, textCol)

	ui_cursor()^ = Vec2{windowRect.x, rect_get_bottom(windowRect)} + {0, -100}

	fonts.default = fo.newsreader__70

	if display.hd_enabled && (titleScreen_main_button("back", textCol) || ginputs[.cancel]){
		settings_save()
		cofind(TitleScreen, 0).currentPage = .main
	}
	ui_frame_end()
}

ITEM_MENU_BUFFER :: Vec2{5,6}
menu_action_line :: proc(a:^CombatAction){
	fonts.default = fo.PixelCode__9
	name := dialogue_line(di.combatActions, a.id)
	spr := a.actionSelectIcon
	ts := text_size(name)

	infoPos := ui_cursor()^ + {spr.size.x + 3, 0}
	combatAction_draw_info(a, infoPos, false, fonts.default)

	descRect := Rect{infoPos, 188}
	rect_set_left(&descRect, infoPos.x + ceil(max(ts.x,40)/10)*10 + 6, true)

	dialogue.font = fo.yal6w4__16
	dialogue.color = color_hex(PAUSE_MENU_TEXT_COL)
	desc := dialogue_line_parsed(di.combatActions, a.id, 1)
	descRect.size.y = dialogue_text_size(desc, descRect.size.x).y
	rect_align(&descRect, {descRect.x, infoPos.y + 14}, {-1, 0})
	dialogue_text_draw(desc, descRect)

	sprite_draw(spr, ui_cursor()^+{ITEM_MENU_BUFFER.x, ts.y/2+4} + sprite_origin(spr)/2)
	ui_cursor().y += ts.y*2 + 6
}

menu_passive_line :: proc(p:Passive){
	fonts.default = fo.PixelCode__9
	name := passive_string_get(p)
	item := ui_item_process(text_size(name))

	text_draw(name, item.pos)
}

menu_item_box :: proc(item:^Item, windowRect:Rect, textCol:Color){
	windowRect:=windowRect
	
	nineslice_draw(sp.menuBoxOutlined, windowRect)

	rect_resize_in_place(&windowRect, -ITEM_MENU_BUFFER)

	ui_cursor()^ = windowRect.pos - {0,3}

	fonts.default = fo.Compass__16
	ui_text(dialogue_line(di.items, item.id), textCol)
	fonts.default = fo.fairfaxItalic__12
	ui_text(enum_name_get(item.kind), textCol)

	ui_cursor().y += 2

	for action in item.equipActions{
		menu_action_line(action)
	}

	for passive in item.equipPassives{
		menu_passive_line(passive)
	}

	sepY := ui_cursor().y+1
	draw_line(windowRect.x, sepY, rect_get_right(windowRect), sepY)

	windowRect.y = sepY + 2

	dialogue.font = fo.yal6w4__16
	dialogue.color = textCol
	dialogue_text_draw(dialogue_line_parsed(di.items, item.id, 1), windowRect)
}

menu_equipment_line :: proc(slot:PlayerCharacterEquippedItemSlot, textCol:Color, windowRect:=Rect{}, selected:=false) -> UIItemState{
	return menu_item_line(
		slot.item == nil ? slot.slotKind : slot.item,
		textCol, windowRect, selected
	)
}

menu_item_line :: proc(item:union{^Item, ItemKind}, textCol:Color, windowRect:=Rect{}, selected:=false, itemQuantity:=1) -> UIItemState{
	selectRect := windowRect
	rect_resize_in_place(&selectRect, ITEM_MENU_BUFFER.x-1, 0)
	selectorColor := color_hex(0xb9ac8e)

	selectRect.size.y = text_char_height()

	name:string
	kind:ItemKind

	switch it in item{
		case ^Item:
			if itemQuantity > 1 do name = format("%s x%i", dialogue_line(di.items, it.id), itemQuantity)
			else do name = dialogue_line(di.items, it.id)
			kind = it.kind
		case ItemKind:
			name = "---"
			kind = it
	}

	spr := ui.icons.itemKinds[kind]
	uiItem := ui_item_process(selectRect.size)
	selectRect.y = uiItem.pos.y
	
	selectorAlpha:f32
	if selected do selectorAlpha = 1
	else if uiItem.interactState==.hovered do selectorAlpha = 0.5

	col := color_lerp(textCol, color_hex(0xf1f1f1), selectorAlpha)
	
	draw_rect(selectRect, selectorColor, selectorAlpha)
	sprite_draw_ex(spr, uiItem.pos+{0,3}, color=col)
	text_draw(name, uiItem.pos + {spr.size.x + 3, 0}, color=col)
	return uiItem
}

menu_character_stats :: proc(pid:PlayerCharacterID, windowRect:Rect, textCol:Color, drawXP:=true){

	statusStat :: proc(label:string, stat:int, statMax:int=-1, width:f32=54, colCode:u32=PAUSE_MENU_TEXT_COL){
		statText:string
		if statMax>=0 do statText = format("%i/%i", stat, statMax)
		else do statText = int_to_string(stat, context.temp_allocator)

		text := dialogue_line(di.pause, label)
		item := ui_item_process(Vec2{width, max(text_size(text).y, text_size(statText).y)})
		col := color_hex(colCode)
		text_draw(text, item.pos, color=col)
		text_draw(statText, item.pos+{width,0}, color=col, alignment=Alignment{1,-1})
	}

	charInfo := player_character_info(pid)
	charData := save.characters[pid]

	windowRect := windowRect
	nineslice_draw(sp.menuBoxOutlined, windowRect)
	rect_resize_in_place(&windowRect, -ITEM_MENU_BUFFER)

	ui_frame_begin(windowRect.pos)
	portrait := ui.icons.playerCharacters[pid].portrait
	ui_sprite(portrait)
	ui_cursor()^ = windowRect.pos + Vec2{portrait.size.x + 3, -4}

	fonts.default = fo.Compass__16
	ui_text(string_prettify(reflect.enum_name_from_value(pid)), textCol)
	fonts.default = fo.PixelCode__9

	ui_cursor().y-=2
	statusStat("hp", charData.hp, charInfo.maxHp)
	drawPos :Vec2= ui_cursor()^
	draw_rect_outline(Rect{drawPos, Vec2{f32(charInfo.maxHp*2+3),7}}, textCol)
	draw_color(textCol)
	for i in 1..=charData.hp{
		x := drawPos.x+f32(i*2)
		draw_line(x, drawPos.y+2, x, drawPos.y+4)
	}
	ui_cursor().y += 7
	statusStat("move", charInfo.move)
	//todo: defense
	
	if drawXP{
		ui_cursor()^ = Vec2{rect_get_right(windowRect) - 54, windowRect.pos.y-3}
		
		statusStat("level", 1) //todo: level-up system
		drawPos = ui_cursor()^
		draw_rect_outline(Rect{drawPos, Vec2{54,7}}, textCol)
		if charData.xp != 0{
			drawPos += 2
			right := drawPos.x+f32(charData.xp/2)
			draw_line(drawPos.x, drawPos.y, right, drawPos.y)
			draw_line(drawPos.x, drawPos.y+1, min(drawPos.x+49, right+1), drawPos.y+1)
			draw_line(drawPos.x, drawPos.y+2, min(drawPos.x+49, right+2), drawPos.y+2)
		}
		ui_cursor().y += 7
		statusStat("xp", charData.xp, 100)
	}

	ui_frame_end()
}

_pauseMenu_process_event :: proc(base:^ComponentBase, event:Event, overrideDisabled:=false){
if(!overrideDisabled && event in base.disabledEvents) do return
last_context := entities.context_component
defer cowith(last_context)
cowith(base)
self := cast(^PauseMenu)base
using self
#partial switch event{
case .init:
	pauseMenu_status_character_update(self)
	headerTex = tex_make(DISPLAY_WIDTH+7, 27)
	if combat.phase != .disabled{
		currentTab = .settings
		controlsTab = .combat
	}
	ui_cue("pauseMenuStart")
case .clean:
	ui_free("pauseMenu")
	tex_destroy(headerTex)
	settings_save()

case .update:
	if (ginputs[.start] || ginputs[.cancel]) && !quitting{
		quitting = true
		ui_cue("pauseMenuQuit")
	}

	if quitting && ui_cue_time("pauseMenuQuit") > 12{
		entity_destroy(self)
	}
	

case .drawEnd:
	bgAlpha :f32= 0
	if currentTab == .quit && !quitting do bgAlpha = 1
	else if combat.phase != .disabled do bgAlpha = 0.5
	draw_rect(Rect{0, DISPLAY_SIZE}, COLOR_BLACK, ui_cue_map_stateful("pauseMenuBackground", 12, bgAlpha))

	headerPos := Vec2{-4,3}
	textCol := color_hex(PAUSE_MENU_TEXT_COL)

	tex_target_set(headerTex, headerPos)
		headerRect := rectf_make_points(-4,3,DISPLAY_WIDTH+3,30)
		nineslice_draw(sp.menuBox, headerRect, blendmode=BlendMode.one)

		ui_begin("pauseMenu", {112, 6})
		
		ui_frame_begin(nil, .tabs, {.gamepad})
		fonts.default = fo.Compass__16
		textSizes:[PauseMenuTab]f32
		tabsW :f32= 0 
		tabsBuffer :: 24
		for t in PauseMenuTab{
			if combat.phase != .disabled && t <= .inventory do continue
			name,_ := reflect.enum_name_from_value(t)
			textSizes[t] = text_size(name).x
			tabsW += textSizes[t] + tabsBuffer 
		}
		tabsW -= tabsBuffer
		drawX := rect_center(headerRect).x - tabsW/2
		for t in PauseMenuTab{
			if combat.phase != .disabled && t <= .inventory do continue
			pauseMenu_tab(self, t, headerRect.pos + Vec2{drawX + textSizes[t]/2, headerRect.size.y/2})
			drawX += textSizes[t] + tabsBuffer
		}
		ui_frame_end()

		if input_device() == .gamepad{
			arrowTextCol := color_hex(0xc29566)
			arrowY := rect_center(headerRect).y - sp.headerArrow.size.y/2
			fonts.default = fo.PixelCode__9
			lbSize := text_size("LB")
			rbSize := text_size("RB")

			arrowOff :: 24
			lbPos := Vec2{headerRect.x + arrowOff, arrowY}
			if ginputs[.lb] do ui_cue("lbPressed")
			sprite_draw_ex(sp.headerArrow, lbPos + {sp.headerArrow.size.x, 0}, sprite_frame_get(sp.headerArrow, f32(ui_cue_time("lbPressed")), true), scale=Vec2{-1,1})
			textPos := lbPos + {sp.headerArrow.size.x + 4, (sp.headerArrow.size.y - lbSize.y)/2 + 1}
			text_draw("LB", textPos + 1, color_hex(0x4f3e3b), 1)
			text_draw("LB", textPos, arrowTextCol, 1)

			rbPos := Vec2{rect_get_right(headerRect) - arrowOff - sp.headerArrow.size.x - rbSize.x - 2, arrowY}
			textPos = rbPos + {-1, (sp.headerArrow.size.y - rbSize.y)/2 + 1}
			text_draw("RB", textPos + 1, color_hex(0x4f3e3b), 1)
			text_draw("RB", textPos, arrowTextCol, 1)
			if ginputs[.rb] do ui_cue("rbPressed")
			sprite_draw_ex(sp.headerArrow, Vec2{rbPos.x + rbSize.x + 2, arrowY}, sprite_frame_get(sp.headerArrow, f32(ui_cue_time("rbPressed")), true))
		}

	tex_target_reset()
	
	scale := quitting?box_popup_scale(ui_cue_time("pauseMenuQuit"), true, true):box_popup_scale(ui_cue_time("pauseMenuStart"), true)
	tex_draw_ex(headerTex, headerPos+headerRect.size*(1-scale)/2, scale)

	if quitting do return

	buffer :: ITEM_MENU_BUFFER
	switch currentTab{
		case .status:
			//todo: holy shit my ui code sucks, needs to be drastically improved
			ui.disabled = true
			defer ui.disabled = false
			if sc,ok := statusCharacter.(PlayerCharacterID); ok{
				//main window
				windowRect := rectf_make_points(14, 41, 241, 116)
				menu_character_stats(sc, windowRect, textCol)

				//equipment window
				windowRect = Rect{Vec2{windowRect.x, rect_get_bottom(windowRect)+5}, Vec2{windowRect.size.x/2-2, 116}}
				nineslice_draw(sp.menuBoxOutlined, windowRect)
				rect_resize_in_place(&windowRect, -buffer)

				fonts.default = fo.Compass__16
				ui_cursor()^ = Vec2{rect_center(windowRect).x, windowRect.y-3}
				ui_text(dialogue_line(di.pause, "equipment"), textCol, alignment={0,-1})
				ui_cursor().x = windowRect.x

				fonts.default = fo.PixelCode__9
				

				kindCounts:[ItemKind][2]int
				charData := save.characters[sc]
				for slot in charData.equippedItems{
					kindCounts[slot.slotKind][1] += 1
				}

				for slot in charData.equippedItems{
					count := &kindCounts[slot.slotKind]
					menu_equipment_line(slot, textCol)
				}

				//passives window
				rect_resize_in_place(&windowRect, buffer)
				windowRect.x += windowRect.size.x + 4
				nineslice_draw(sp.menuBoxOutlined, windowRect)
				rect_resize_in_place(&windowRect, -buffer)

				fonts.default = fo.Compass__16
				ui_cursor()^ = Vec2{rect_center(windowRect).x, windowRect.y-3}
				ui_text(dialogue_line(di.pause, "passives"), textCol, alignment={0,-1})
				ui_cursor().x = windowRect.x

				fonts.default = fo.PixelCode__9
				

				passives := player_character_passives(sc)
				for p in passives{menu_passive_line(p)}
	
				//actions window
				rect_resize_in_place(&windowRect, buffer)
				actionsLeft := rect_get_right(windowRect)+5
				windowRect = rectf_make_points(actionsLeft, 41, actionsLeft + 220, rect_get_bottom(windowRect))
				nineslice_draw(sp.menuBoxOutlined, windowRect)
				rect_resize_in_place(&windowRect, -buffer)

				fonts.default = fo.Compass__16
				ui_cursor()^ = Vec2{rect_center(windowRect).x, windowRect.y-3}
				ui_text(dialogue_line(di.pause, "actions"), textCol, alignment={0,-1})
				ui_cursor().x = windowRect.x

				fonts.default = fo.PixelCode__9
				actions := player_character_actions(sc, true)
				for a in actions{menu_action_line(a)}

			}
			else{
				//todo: character select
			}
		case .inventory:
			//item select window
			windowRect := rectf_make_points(63, 41, 194, 236)
			nineslice_draw(sp.menuBoxOutlined, windowRect)
			rect_resize_in_place(&windowRect, -buffer)

			ui_frame_begin(windowRect.pos, .horizontal, {.gamepad})

			//get available categories and items in inventory
			shownCategories:[ItemKind]bool
			shownCount :f32= 1
			itemList := make([dynamic]^Item, len(save.inventory), context.temp_allocator)
			resetSelection := inventorySelectedItem == nil
			for i:=0; item in save.inventory{
				if !shownCategories[item.kind]{
					shownCategories[item.kind] = true //only show categories with items in them
					shownCount += 1
				}
				itemList[i] = item
				i+=1
			}

			//category selector
			selectColors := [3]Color{}
			selectColors[0] = textCol
			selectColors[2] = color_hex(0xf1f1f1)
			selectColors[1] = color_lerp(selectColors[0], selectColors[2], 0.5)
			{
				i:f32=1
				for kind in ItemKind{
					if shownCategories[kind]{
						ui_cursor()^ = windowRect.pos + Vec2{windowRect.size.x/(shownCount+1)*i, 0}
						if ui_sprite(ui.icons.itemKinds[kind], colors=selectColors, selected=kind==inventoryCategory){
							inventoryCategory = kind
							resetSelection = true
						}
						i+=1
					}
				}
				ui_cursor()^ = windowRect.pos + Vec2{windowRect.size.x/(shownCount+1)*i, 0}
				if ui_sprite(sp.itemIcons_nil, colors=selectColors, selected=inventoryCategory==nil){
					inventoryCategory = nil
					resetSelection = true
				}
			}
			
			//selected category title and filter item list
			catTitle:string
			if kind,ok := inventoryCategory.(ItemKind); ok{
				catTitle = dialogue_line(di.pause, "itemCategories", int(kind))
				#reverse for item,i in itemList{
					if item.kind != kind do unordered_remove(&itemList, i)
				}
			}
			else do catTitle = dialogue_line(di.pause, "itemCategoryAll")

			fonts.default = fo.Compass__16
			ui_cursor().x = rect_center(windowRect).x
			ui_text(catTitle, textCol, alignment={0,-1})
			ui_cursor().x = windowRect.x
			
			//sort items
			sort(&itemList, proc(a,b:^Item)->bool{return dialogue_line(di.items, a.id)<dialogue_line(di.items, b.id)})
			if resetSelection do inventorySelectedItem = itemList[0]

			//item list
			fonts.default = fo.PixelCode__9
			
			ui_frame_begin()
			for item in itemList{
				if menu_item_line(item, textCol, windowRect, inventorySelectedItem == item, save.inventory[item]).interactState == .selected do inventorySelectedItem = item
			}
			ui_frame_end()

			//item description window
			rect_resize_in_place(&windowRect, buffer)
			windowRect.x += windowRect.size.x + 5
			windowRect.size.x = 220
			menu_item_box(inventorySelectedItem, windowRect, textCol)

			ui_frame_end()

		case .settings:
			settings_menu()
		case .controls:
			fonts.default = fo.fairfax__12
			headerFont := fo.GoetheBold__20
			textCol = color_hex(PAUSE_MENU_TEXT_COL)

			// Size the box to the tallest tab
			windowRect := Rect{0, {DISPLAY_WIDTH, 230}}
			maxSize: Vec2
			for t in PauseMenuControlsTab {
				tLabel := format("controls%s%s", enum_name_get(input_device()), enum_name_get(t))
				tSize := dialogue_paragraph_size(windowRect, di.pause, tLabel, columnBuffer=6)
				maxSize.x = max(maxSize.x, tSize.x)
				maxSize.y = max(maxSize.y, tSize.y)
			}
			headerCharH := text_char_height(headerFont)
			maxSize.y += headerCharH
			windowRect.size = maxSize
			rect_resize_in_place(&windowRect, {9,6})
			rect_align(&windowRect, Vec2{DISPLAY_WIDTH/2, 151}, 0)
			nineslice_draw(sp.menuBoxOutlined, windowRect)
			rect_resize_in_place(&windowRect, -{9,6})

			// Arrow positions and click detection (using pre-update tab for hit rects)
			headerTop := windowRect.y - 3
			arrowY := headerTop + (headerCharH - sp.headerArrow.size.y) / 2 - 1
			arrowGap :f32= 8
			centerX := rect_center(windowRect).x
			tabNameW := text_size(enum_name_get(controlsTab), headerFont).x
			lArrowRect := Rect{Vec2{centerX - tabNameW/2 - sp.headerArrow.size.x - arrowGap, arrowY}, sp.headerArrow.size}
			rArrowRect := Rect{Vec2{centerX + tabNameW/2 + arrowGap, arrowY}, sp.headerArrow.size}
			lClicked := input_device() == .keyboard && rect_contains(lArrowRect, mouse_display_pos()) && ginputs[.confirm]
			rClicked := input_device() == .keyboard && rect_contains(rArrowRect, mouse_display_pos()) && ginputs[.confirm]

			controlsTab = PauseMenuControlsTab(wrap(int(controlsTab) + int(ginputs[.right] || rClicked) - int(ginputs[.left] || lClicked), 0, len(PauseMenuControlsTab)-1))

			// Recompute arrow positions for new tab and draw
			tabName := enum_name_get(controlsTab)
			tabNameW = text_size(tabName, headerFont).x
			lArrowRect = Rect{Vec2{centerX - tabNameW/2 - sp.headerArrow.size.x - arrowGap-1, arrowY}, sp.headerArrow.size}
			rArrowRect = Rect{Vec2{centerX + tabNameW/2 + arrowGap-1, arrowY}, sp.headerArrow.size}
			if ginputs[.left] || lClicked do ui_cue("controlsLPressed")
			sprite_draw_ex(sp.headerArrow, lArrowRect.pos + {sp.headerArrow.size.x, 0}, sprite_frame_get(sp.headerArrow, f32(ui_cue_time("controlsLPressed")), true), scale=Vec2{-1,1})
			if ginputs[.right] || rClicked do ui_cue("controlsRPressed")
			sprite_draw_ex(sp.headerArrow, rArrowRect.pos, sprite_frame_get(sp.headerArrow, f32(ui_cue_time("controlsRPressed")), true))

			// Draw tab name and content
			text_draw(tabName, Vec2{centerX, headerTop}, textCol, 1, headerFont, Alignment{0, -1})
			windowRect.y += headerCharH
			label := format("controls%s%s", enum_name_get(input_device()), tabName)
			dialogue_paragraph_draw(windowRect, di.pause, label, textCol=textCol, columnBuffer=6)
		case .quit:
			fonts.default = fo.PixelCode__9
			warningText := dialogue_line(di.pause, "quitWarning")
			toTitleText := dialogue_line(di.pause, "quitToTitle")
			quitText := dialogue_line(di.pause, "quitGame")
			windowRect := Rect{0, text_size(format("%s\n%s\n%s", warningText, toTitleText, quitText))}
			rect_align(&windowRect, DISPLAY_SIZE/2, 0)
			ui_frame_begin(Vec2{rect_center(windowRect).x, windowRect.y})

			ui.disabled = true
			ui_text(warningText, COLOR_GRAY, 1, {0,-1})
			ui.disabled = false

			selectColors := [3]Color{}
			selectColors[0] = color_hex(0xa27644)
			selectColors[1] = textCol
			selectColors[2] = COLOR_WHITE
			if ui_text(toTitleText, selectColors, 1, {0,-1}) do proc_call_delayed(titleScreen_goto, 1)
			if ui_text(quitText, selectColors, 1, {0,-1}) do game_quit()
			ui_frame_end()
	}
	ui_end()

}}
