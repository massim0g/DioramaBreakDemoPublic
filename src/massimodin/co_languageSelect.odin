#+feature using-stmt
package massimodin //@nested-tags:_components/

LanguageSelect :: struct{
	using base:RenderComponentBase,
	quitting:bool
}

_languageSelect_process_event :: proc(base:^ComponentBase, event:Event, overrideDisabled:=false){
if(!overrideDisabled && event in base.disabledEvents) do return
last_context := entities.context_component
defer cowith(last_context)
cowith(base)
self := cast(^LanguageSelect)base
using self
#partial switch event{
case .init:

case .drawEnd:

	fonts.default = fo.notoSerif__144


	textH := text_char_height()

	//split into two columns when too many locales are loaded to fit in one
	columns := len(dialogue.locales_loaded) > LOCALES_MAX/2 ? 2 : 1
	rows := (len(dialogue.locales_loaded) + columns - 1) / columns

	totalH := textH * f32(rows)
	startY := display_size().y/2 - totalH/2

	ui_begin("languageSelect", {display_size().x/2, startY})

	for _, i in dialogue.locales_loaded{
		colX := display_size().x * f32(i/rows + 1) / f32(columns + 1)
		ui_cursor()^ = {colX, startY + textH*f32(i%rows)}

		text := locale_display_name(LocaleID(i))
		tr := text_rect(text, ui_cursor()^, Alignment{0,-1})
		item := ui_item_process(tr)

		#partial switch item.interactState{
			case .idle, .disabled:
				text_draw(text, item.pos, COLOR_WHITE, 0.3, alignment=Alignment{-1,-1})
			case .hovered, .selected:
				text_draw(text, item.pos, COLOR_WHITE, alignment=Alignment{-1,-1})
				settings.locale = LocaleID(i)
		}

		if item.interactState == .selected && !quitting{
			settings_save()
			quitting = true
			ui_cue("languageSelectQuit")
		}
	}
	ui.disabled = false

	ui_end()

	if input_device() == .gamepad{
		text_draw(dialogue_line(di.title, "gamepadNote"), Vec2{display_size().x/2, startY + totalH + textH}, COLOR_WHITE, 0.3, fo.newsreaderItalic__64, alignment=Alignment{0,-1})
	}

	if quitting{
		draw_rect(0, display_size(), COLOR_BLACK, alpha=ui_cue_map("languageSelectQuit", 0, TITLE_SCREEN_FADE_TIME, 0, 1))
		if ui_cue_time("languageSelectQuit") > TITLE_SCREEN_FADE_TIME{
			titleScreen_goto()
		}
	}
}}
