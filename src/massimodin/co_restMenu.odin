#+feature using-stmt
package massimodin //@nested-tags:_components/

RestMenu :: struct{
	using base:RenderComponentBase,
	currentPage:enum{
		main,
		talk,
		equipment
	},
	equipmentCharacter:Maybe(PlayerCharacterID),
	equipmentSelectedSlot:^PlayerCharacterEquippedItemSlot
}

RestTalkOption :: struct{
	using dialogueRef:DialogueRef,
	title:string
}

rest_talk_dialogues_get :: proc() -> []RestTalkOption{
	check :: proc(arr:^[dynamic]RestTalkOption, d:^Dialogue, label:string, expr:string="", otherChecks:..bool){
		for c in otherChecks{ if !c do return}
		if dialogue_label_seen_get(d, label) do return
		res := "1"
		if expr != "" do res,_ = dialogue_expression_parse(expr, true)
		if res=="1"{
			append(arr, RestTalkOption{{d,label}, dialogue_line(di.rest, label)})
		}
	}

	a := make([dynamic]RestTalkOption, context.temp_allocator)

	if !flag_check("demoCompleted"){
		check(&a, di.minimaEncounter, "names")
		check(&a, di.minimaEncounter, "spellcaster", "minimaIntroduced")
		check(&a, di.minimaEncounter, "aboutMinima", "minimaMentionedFront")
		check(&a, di.irisForest, "opinionOfPlayer", "secondShrineReached")
	}

	check(&a, di.minimaEncounter, "anemomaterAndTimeStop", "minimaJoinedParty")

	return a[:]
}

//state that gets reset on a checkpoint rest, such as temp flags and player character hp
rest_state_reset :: proc(){
	for pid in PlayerCharacterID{
		player_character_reset_saved_stats(pid)
	}
	flags_clear(.temp)
}

_restMenu_process_event :: proc(base:^ComponentBase, event:Event, overrideDisabled:=false){
if(!overrideDisabled && event in base.disabledEvents) do return
last_context := entities.context_component
defer cowith(last_context)
cowith(base)
self := cast(^RestMenu)base
using self
#partial switch event{
case .init:
	equipmentCharacter = .pro
case .drawEnd:
	if dialogue.current != nil do return
	switch currentPage{
		case .main:
			n := dialogue_choice_menu(dialogue_lines(di.rest, "main"), DISPLAY_SIZE/2, 0)
			switch n{
				case 0: 
					currentPage = .equipment
					equipmentSelectedSlot = nil
				case 1: currentPage = .talk
				case 2:
					cutscene_start("restEnd")
					entity_destroy(self)
			}
		case .talk:
			menuPos := DISPLAY_SIZE/2
			dialogues := rest_talk_dialogues_get()
			options := make([dynamic]string, context.temp_allocator)

			for dia in dialogues{
				append(&options, dia.title)
			}
			append(&options, dialogue_line(di.rest, "back"))

			if len(dialogues) == 0{
				menuPos.y += 32 //maybe?
				ds := dialogue_line_parsed(di.rest, "nothingToSay")
				size := dialogue_text_size(ds)

				nsRect := Rect{0, size}
				rect_resize_in_place(&nsRect, {10,8})
				rect_align(&nsRect, DISPLAY_SIZE/2, 0)

				nineslice_draw(sp.menuBoxOutlined, nsRect)

				dialogue_text_draw(ds, nsRect, true, color_hex(0x87949d), 1)
			}

			n := dialogue_choice_menu(options[:], menuPos, 0)
			if n != -1{
				if n == len(dialogues) do currentPage = .main
				else do dialogue_open(dialogues[n], dialogues[n].label)
			}
			else if ginputs[.cancel] do currentPage = .main
		case .equipment:
			ui_begin("equipMenu", Vec2{})
			if ec,ok := equipmentCharacter.(PlayerCharacterID); ok{
				buffer :: ITEM_MENU_BUFFER
				textCol := color_hex(PAUSE_MENU_TEXT_COL)
				windowRect := rectf_make_points(8, 41, 139, 116)
				menu_character_stats(ec, windowRect, textCol, false)

				windowRect.y += windowRect.size.y
				nineslice_draw(sp.menuBoxOutlined, windowRect)
				rect_resize_in_place(&windowRect, -buffer)

				hoveredItem:^Item
				hoveredItemKind:ItemKind
				if equipmentSelectedSlot != nil{
					hoveredItem = equipmentSelectedSlot.item
					hoveredItemKind = equipmentSelectedSlot.slotKind
				}

				ui_frame_begin(windowRect.pos, equipmentSelectedSlot != nil ? .disabled : .vertical)
				charData := save.characters[ec]
				for &slot in charData.equippedItems{
					interactState := menu_equipment_line(slot, textCol, windowRect, equipmentSelectedSlot == &slot).interactState
					#partial switch interactState{
						case .selected: 
							equipmentSelectedSlot = &slot
							fallthrough
						case .hovered: 
							hoveredItem = slot.item
							hoveredItemKind = slot.slotKind
					}
				}
				ui_frame_end()

				rect_resize_in_place(&windowRect, buffer)
				windowRect.pos.x += windowRect.size.x
				windowRect.size.x = 112
				rect_set_top(&windowRect, 41, true)
				rect_set_bottom(&windowRect, DISPLAY_SIZE.y - windowRect.y, true)

				nineslice_draw(sp.menuBoxOutlined, windowRect)

				// previewListItemKind:ItemKind
				// if hoveredItemKind previewListItemKind = hoveredItemKind
				// if equipmentSelectedSlot != nil do previewListItemKind = equipmentSelectedSlot.slotKind
				// else do 

				if hoveredItemKind != .key{
					drawTex := tex_make(windowRect.size)
					defer tex_destroy(drawTex)
					tex_target_set(drawTex, windowRect.pos)
					rect_resize_in_place(&windowRect, -buffer)
					ui_frame_begin(windowRect.pos)

					slotItems := make([dynamic]^Item, context.temp_allocator)
					for item in save.inventory{
						if item.kind == hoveredItemKind do append(&slotItems, item)
					}
					sort(&slotItems, proc(a,b:^Item)->bool{return dialogue_line(di.items, a.id) < dialogue_line(di.items, b.id)}) //sort items by name

					if equipmentSelectedSlot == nil{ //force hover equipped item if slot is not selected
						for item,i in slotItems{
							if item == hoveredItem do ui_frame().hoveredItem = i
						}
					}

					hoverPrev := hoveredItem
					for item in slotItems{
						#partial switch menu_item_line(item, textCol, windowRect, hoverPrev == item).interactState{
							case .selected:
								equipmentSelectedSlot.item = item
								player_character_reset_saved_stats(ec)
								fallthrough
							case .hovered:
								hoveredItem = item
								
						} 
					}
					rect_resize_in_place(&windowRect, buffer)
					ui_frame_end()
					tex_target_reset()
					focused := equipmentSelectedSlot!=nil && hoveredItemKind == equipmentSelectedSlot.slotKind
					tex_draw_ex(drawTex, windowRect.pos, color=focused?COLOR_WHITE:COLOR_GRAY)
				}
				

				if hoveredItem != nil{
					windowRect.x += windowRect.size.x
					windowRect.size.x = 220
					menu_item_box(hoveredItem, windowRect, textCol)
				}


			}
			else{ 
				//todo: character select
			}
			ui_end()

			if ginputs[.cancel]{
				if equipmentSelectedSlot != nil do equipmentSelectedSlot = nil
				else do currentPage = .main
			}

			if input_device() == .keyboard && dialogue_choice_menu(dialogue_lines(di.rest, "back"), {8,264}, {-1,1}) != -1 do currentPage = .main
	}
}}
