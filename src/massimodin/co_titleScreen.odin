#+feature using-stmt
package massimodin //@nested-tags:_components/

import "../sdl3"
import time_ "core:time"
import "core:time/datetime"


TitleScreen :: struct{
	using base:RenderComponentBase,
	currentPage:enum{
		main,
		settings,
		credits
	},
	dustParticle:^ParticleType,
	shineTex:Tex,

	entryPerlinAlpha:f32,
	entryPerlinStrength:f32,
	entryShadowAlpha:f32,
	entryTopLightAlpha:f32,
	entryRadialAlpha:f32,
	entryRadialRadius:f32,
	perlinTex:Tex,

	meditationMode:bool,
	meditationTimeoutTimer:int,

}

MEDITATION_PERLIN_BASE_STR :: 0.066
HD_MENU_TEXT_COL :: 0x625955
TITLE_SCREEN_FADE_TIME :: 40


kickstarter_date_check :: proc() -> int{
	ksDate :: datetime.Date{2026, 04, 28}
	now := time_.time_to_datetime(time_.now()) or_else datetime.DateTime{}
	ksOrd := datetime.date_to_ordinal(ksDate) or_else 0
	nowOrd := datetime.date_to_ordinal({now.year, now.month, now.day}) or_else int_max(i64)
	if nowOrd < ksOrd - 1 do return -1
	if nowOrd <= ksOrd + 32 do return 0
	return 1
}

titleScreen_goto :: proc(){
	display.hd_enabled = true
	_stage_unload()

	texture_group_load_block("title_screen_HD") //block before stopping audio to reduce odds of an audio hitch

	audio_stop_all()
	entity_make(TitleScreen)
}

titleScreen_main_button :: proc(label:string, textCol:=COLOR_WHITE) -> bool{
	self := cast(^TitleScreen)entities.context_component
	using self

	ind := ui_frame().currentItem
	text := dialogue_line(di.title, label)
	item := ui_item_process(text_size(text))
	pos:=item.pos

	cs := char_size('M')

	#partial switch item.interactState{
		case .disabled:
			t :f32 = TITLE_SCREEN_FADE_TIME+36+48+12+f32(ind)*8
			fadeOutAlpha :f32= 1
			if ui_cue_time("titleFadeOut") < TITLE_SCREEN_FADE_TIME do fadeOutAlpha = ui_cue_map("titleFadeOut", 0, TITLE_SCREEN_FADE_TIME, 1, 0)
			text_draw(text, pos, textCol, ui_cue_map("titleInit", t, t+54, 0, 1) * fadeOutAlpha)
		case .idle:
			text_draw(text, pos, textCol)
		case .hovered, .selected:
			off := ui_cue_map(item.hoverTime, 0, 3, 0, cs.x/2-20)
			angle := ui_cue_map(item.hoverTime, 0, 5, 90, 0, cu.easeIn)
			scale := ui_cue_map(item.hoverTime, 0, 5, 0.66, 2, cu.easeIn)
			texDp := pos+cs/2 - Vec2(shineTex.size)/2
			text_draw(text, pos+{off,0}, textCol)
			tex_target_set(shineTex, texDp, false)
			draw_clear(COLOR_BLACK, 0)
			text_draw(text, pos+{off,0}, textCol)
			blendmode_set(.invert)
			sprite_draw_ex(sp.menuShineHD, pos+cs/2, 0, scale, angle)
			blendmode_set(.blend)
			tex_target_reset()
			tex_draw(shineTex, texDp)
	}

	
	if item.hoverTime <= 12 && item.interactState == .hovered{
		radius := ui_cue_map(item.hoverTime, 0, 12, 0, cs.x*1.2)
		alpha := ui_cue_map(item.hoverTime, 0, 12, 3.67, 0, cu.easeInLinearStart)
		draw_rings(pos+cs/2, {radius, radius-8}, alphas={alpha, alpha}, edgeSoftness=2)
	}

	return item.interactState == .selected
}

//simpler text button for the title screen's sub pages: lightens when hovered and slides right, no shine
titleScreen_page_button :: proc(label:string, textCol:=COLOR_WHITE) -> bool{
	text := dialogue_line(di.title, label)
	item := ui_item_process(text_size(text))

	off:f32
	drawCol := textCol
	if item.interactState == .hovered || item.interactState == .selected{
		off = ui_cue_map(item.hoverTime, 0, 3, 0, char_size('M').x/2-20)
		drawCol = color_lerp(textCol, COLOR_WHITE, 0.3)
	}
	text_draw(text, item.pos+{off,0}, drawCol)

	return item.interactState == .selected
}

_titleScreen_process_event :: proc(base:^ComponentBase, event:Event, overrideDisabled:=false){
if(!overrideDisabled && event in base.disabledEvents) do return
last_context := entities.context_component
defer cowith(last_context)
cowith(base)
self := cast(^TitleScreen)base
using self
#partial switch event{
case .init:
	shineTex = tex_make(sp.menuShineHD.size*2, true)
	music_set(au.titleScreen)
	ui_cue("titleInit")
	perlinTex = tex_make(DISPLAY_SIZE_HD, true)
	tex_target_set(perlinTex,clear=false)
	draw_clear(COLOR_BLACK)
	tex_target_clear()
	dustParticle = particle_type(sp.white1, 
		40, 140, 0.5, 2, minScale=1, maxScale=3, alphaCurve=cu.easeInArc, angleChange=-0.1, angleMatchesDir=false
	)
case .update:
	depth = 2 //diorama and menu layers draw in front via their own render_depth calls
	if random(10) == 0 do particles_emit(dustParticle, 1, choose([]f32{0.5, 1.5}), Rect{{1000, 10}, {1800, 1560}})

	if !cutscene.enabled && meditationMode{
		connectionFail :: proc(self:^TitleScreen, d:string){
			audio_stop_all()
			self.meditationTimeoutTimer=0
			dialogue_open(di.prologueAndOutro, d)
		}
		pressing:bool
		switch input_device(){
			case .keyboard: pressing = key_held(.SPACE)
			case .gamepad: pressing = button_held(input.last_device, .LEFT_STICK) || button_held(input.last_device, .RIGHT_STICK)
		}
		if pressing{
			ui_cue("titleMeditation")
			breatheOutDuration :: 290
			entryPerlinStrength = ui_cue_map("titleMeditation", 0, breatheOutDuration, MEDITATION_PERLIN_BASE_STR, 1, cu.easeInStrong)
			if !audio_playing(au.dioramaEntryBuzz) do audio_background_add(au.dioramaEntryBuzz)
			audio_volume_set(au.dioramaEntryBuzz, ui_cue_map("titleMeditation", 0, breatheOutDuration, 0, 0.5))
			if ui_cue_time("titleMeditation") == breatheOutDuration-130 do audio_play(au.dioramaEntryFlash)
			if entryPerlinStrength == 1 do dialogue_open(di.prologueAndOutro, "connectionComplete")
			meditationTimeoutTimer=0
		}
		else if entryPerlinStrength > MEDITATION_PERLIN_BASE_STR{
			entryPerlinStrength = approach(entryPerlinStrength, MEDITATION_PERLIN_BASE_STR, 1./24.)
			if entryPerlinStrength == MEDITATION_PERLIN_BASE_STR{
				connectionFail(self, "connectionFailed")
			}
		}
		else if ginput_check_any(ginputs){
			connectionFail(self, "connectionFailed")
		}
		else{
			meditationTimeoutTimer += 1
			if meditationTimeoutTimer>600{
				connectionFail(self, "forgotToBreathe")
			}
		}
	}
case .draw:
	//bg
	{
		sprite_draw(sp.titleScreenBG_BG, 0, 0)
		sprite_draw(sp.titleScreenBG_paintings, 0, 0)
		sprite_draw(sp.titleScreenBG_dioramaShadow, 0, 0)

		if entryShadowAlpha > 0 do draw_rect_fullscreen(COLOR_BLACK, entryShadowAlpha)
	}

	//diorama
	render_depth(1)
	{
		sprite_draw(sp.titleScreenBG_diorama, 0, 0)

		beamAlpha := min(entryRadialAlpha, entryRadialAlpha*0.25)
		if beamAlpha > 0{
			blendmode_set(.add)
			draw_ellipse(Vec2{1917, 1176}, wave(entryRadialRadius*2, entryRadialRadius*2*0.85, 3), innerAlpha=entryRadialAlpha, outerAlpha=0)
			beamRect := rectf_make_points(1783, 0, 2055, 1234)
			draw_rect(beamRect, COLOR_WHITE, wave(beamAlpha, beamAlpha*0.85, 3))
			blendmode_set(.blend)
		}
	}
	
	//menu
	if !(cutscene.enabled || meditationMode){
		render_depth_ui(.menus)

		fadingOut := ui_cue_time("titleFadeOut") < TITLE_SCREEN_FADE_TIME
		fadeOutAlpha :f32= fadingOut ? ui_cue_map("titleFadeOut", 0, TITLE_SCREEN_FADE_TIME, 1, 0) : 1

		t :f32= TITLE_SCREEN_FADE_TIME+36
		if currentPage == .main do sprite_draw_ex(sp.titleLogo, 100, 10, alpha=ui_cue_map("titleInit", t, t+48, 0, 1)*fadeOutAlpha)
		t+=48

		ui_begin("titleScreen", {140, 360})
		if ui_cue_time("titleInit") < int(t+96) || fadingOut do ui.disabled = true
		fonts.default = fo.anarcharsisSC__168
		switch currentPage{
			case .main:
				if titleScreen_main_button("begin"){
					ui_cue("titleFadeOut")
					proc_call_delayed(proc(){
						if game_load() do dialogue_open(di.prologueAndOutro, "loaded")
						else do dialogue_open(di.prologueAndOutro, "start")
					}, TITLE_SCREEN_FADE_TIME)
				}
				if titleScreen_main_button("settings"){
					currentPage = .settings
				}
				if titleScreen_main_button("credits"){
					currentPage = .credits
				}
				if titleScreen_main_button("community"){
					_ = sdl3.OpenURL("https://www.dioramabreak.com#community")
				}
				if titleScreen_main_button("quit") do game_quit()
				fonts.default = fo.anarcharsisSC__84
				ui_frame().cursorPos = Vec2{40, display_size().y - text_char_height()*2 - 48}
				if titleScreen_main_button("kickstarter"){
					_ = sdl3.OpenURL("https://www.kickstarter.com/projects/massimog/diorama-break")
				}
				if titleScreen_main_button("wishlist"){
					_ = sdl3.OpenURL(release_channel == .gog ? "https://www.gog.com/en/game/diorama_break" :
						"https://store.steampowered.com/app/3932580/Diorama_Break/"
					) 
				}
				text_draw(string_prettify(GAME_VERSION, true), display_size() - 40, COLOR_WHITE, ui_cue_map("titleInit", t, t+96, 0,1) * fadeOutAlpha, fo.notoSerif__64, alignment=Alignment{1,1})
			case .settings:
				settings_menu()
			case .credits:
				drawRect := rect_make_points(Vec2{100,100},display_size()-100)
				dialogue_hd_box_draw(drawRect)
				rect_resize_in_place(&drawRect, {-100, -64})
				fonts.default = fo.notoSerifJP__40 //note: make sure whatever font is used supports mariru's name kanji
				
				dialogue_paragraph_draw(drawRect, di.credits, "main", COLOR_BLACK)

				text_draw(dialogue_line(di.credits, "copyright"),
					Vec2{rect_center(drawRect).x-30, rect_get_bottom(drawRect) - 60},
					COLOR_BLACK, 0.5, fo.notoSerifJP__40, alignment=Alignment{0, -1}
				)

				fonts.default = fo.newsreader__70
				ui_frame_begin(Vec2{drawRect.x, rect_get_bottom(drawRect) - text_char_height()})
				if titleScreen_page_button("back", COLOR_BLACK) || ginputs[.cancel]{
					currentPage = .main
				}
				ui_frame_end()

		}
		ui.disabled = false
		ui_end()
	}

	//screen fade
	render_depth_ui(.top)
	{
		if entryTopLightAlpha > 0 do draw_rect_fullscreen(COLOR_WHITE, entryTopLightAlpha)
		
		if entryPerlinAlpha > 0{
			shader_set(Sh_MeditationBG{
				time = f32(time.frame),
				strength = f32(entryPerlinStrength),
				scale = 5.5,
			})
			tex_draw_ex(perlinTex, 0, 0, alpha=entryPerlinAlpha)
			shader_reset()
		
		}
		fadeInAlpha := ui_cue_map("titleInit", 0, TITLE_SCREEN_FADE_TIME, 1, 0)
		if fadeInAlpha > 0 do draw_rect_fullscreen(COLOR_BLACK, fadeInAlpha)
	}


case .clean:
	ui_free("titleScreen")
	tex_destroy(perlinTex)
	tex_destroy(shineTex)
}}
