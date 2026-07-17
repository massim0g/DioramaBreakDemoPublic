#+feature using-stmt
package massimodin //@nested-tags:engine/visuals

import "core:path/filepath"
import "../sdl2"
import "core:image/png"
import "core:os"
import "../imgui"
import "core:math"
import gl "vendor:OpenGL"

DISPLAY_WIDTH :: 480
DISPLAY_HEIGHT :: 270
DISPLAY_WIDTH_HD :: 3840
DISPLAY_HEIGHT_HD :: 2160
DISPLAY_AREA :: f32(DISPLAY_WIDTH*DISPLAY_HEIGHT)
DISPLAY_SIZE :: Vec2{DISPLAY_WIDTH, DISPLAY_HEIGHT}
DISPLAY_RADIUS := math.sqrt(f32(DISPLAY_WIDTH/2*DISPLAY_WIDTH/2 + DISPLAY_HEIGHT/2*DISPLAY_HEIGHT/2))
DISPLAY_ELLIPSE_RADIUS := rect_enclosing_ellipse(DISPLAY_SIZE)
DISPLAY_SIZE_HD :: Vec2{DISPLAY_WIDTH_HD, DISPLAY_HEIGHT_HD}
DISPLAY_BASE_COLOR :: Color{0xBD, 0xE3, 255}

DisplaySystem :: struct{
	_window:^sdl2.Window,
	_renderer:^sdl2.Renderer,

	main_textures:TexBuffer,
	hd_tex:Tex,
	hd_enabled:bool,
	_tex_target_stack:[dynamic]Tex,
	draw_color:Color,
	draw_alpha:u8,
	custom_blendmodes:[BlendMode]sdl2.BlendMode,
	_system_cursor:^sdl2.Cursor,
	_system_cursor_id:sdl2.SystemCursor,
}
display:^DisplaySystem

DisplayPerformanceMode :: enum{
	normal,
	reduced,
	potato
}

DISPLAY_PERFORMANCE_FACTORS := [DisplayPerformanceMode]int{
	.normal=1,
	.reduced=2,
	.potato=3
}

BlendMode :: enum{
	none,
	blend,
	add,
	mod,
	mul,
	multiply,
	screen,
	accumulate,
	premul,
	subtract,
	subtractInverse,
	one,
	alphaMax,
	invert,
	alphaOnly
}

_display_system_init :: proc(){
	trace("Display System Init")
	using sdl2
	
	display = new(DisplaySystem)
	init(&display._tex_target_stack)

	display.custom_blendmodes = {
		.none = sdl2.BlendMode.NONE,
		.blend = sdl2.BlendMode.BLEND, //.SRC_ALPHA, .ONE_MINUS_SRC_ALPHA, .ADD, .ONE, .ONE_MINUS_SRC_ALPHA, .ADD
		.add = sdl2.BlendMode.ADD,
		.mod = sdl2.BlendMode.MOD,
		.mul = sdl2.BlendMode.MUL, //.DST_COLOR, .ONE_MINUS_SRC_ALPHA, .ADD, .DST_ALPHA, .ONE_MINUS_SRC_ALPHA, .ADD
		.multiply = ComposeCustomBlendMode(.DST_COLOR, .ZERO, .ADD, .ZERO, .ONE, .ADD), //Photoshop-style multiply: srcRGB * dstRGB, preserves dstA
		.screen = ComposeCustomBlendMode(.ONE, .ONE_MINUS_SRC_COLOR, .ADD, .ONE, .ONE_MINUS_SRC_ALPHA, .ADD),
		.accumulate = ComposeCustomBlendMode(.SRC_ALPHA, .ONE, .ADD, .ONE, .ONE, .ADD), //blend items on a separate texture
		.premul = ComposeCustomBlendMode(.ONE, .ONE_MINUS_SRC_ALPHA, .ADD, .ONE, .ONE_MINUS_SRC_ALPHA, .ADD), //should be used for rendering textures drawn with "accumulate"
		.subtract = ComposeCustomBlendMode(.ZERO, .ONE, .ADD, .ZERO, .ONE_MINUS_SRC_ALPHA, .ADD),
		.subtractInverse = ComposeCustomBlendMode(.ZERO, .ONE, .ADD, .ZERO, .SRC_ALPHA, .ADD),
		.one = ComposeCustomBlendMode(.ONE, .ZERO, .ADD, .ONE, .ZERO, .ADD),
		.alphaMax = ComposeCustomBlendMode(.ZERO, .ONE, .MAXIMUM, .ONE, .ONE, .MAXIMUM),
		.invert = ComposeCustomBlendMode(.ONE, .DST_ALPHA, .SUBTRACT, .ONE, .ZERO, .SUBTRACT),
		.alphaOnly = ComposeCustomBlendMode(.ZERO, .ONE, .ADD, .ONE, .ONE, .ADD),
	}

	display._window = CreateWindow(
        "Diorama Break Demo", 
        WINDOWPOS_CENTERED, WINDOWPOS_CENTERED, 
       	DISPLAY_WIDTH, DISPLAY_HEIGHT, 
        {.SHOWN, .OPENGL}
    )

	SetWindowIcon(display._window, LoadBMP(string_to_cstring(filepath.join({executable_directory, "windowIcon.bmp"}, context.temp_allocator) or_else "", context.temp_allocator)))

	display._renderer = CreateRenderer(display._window, -1, RENDERER_ACCELERATED)
	assert(display._renderer != nil, "Renderer failed to initialize! Please verify that your graphics drivers are up to date and support OpenGL!")
	
	draw_color(0xBD, 0xE3, 255)
	sdl2.SetRenderDrawBlendMode(display._renderer, .BLEND)
	display.main_textures = texBuffer_make(DISPLAY_SIZE)
	display.hd_tex = tex_make(DISPLAY_SIZE_HD, true)

	when !DEBUG{
		SetWindowSize(display._window, i32(DISPLAY_WIDTH*3), i32(DISPLAY_HEIGHT*3))
		window_center()
		
		splashPath := filepath.join({executable_directory, "splashScreen.png"}, context.temp_allocator) or_else ""
		splashImg, splashErr := png.load_from_file(splashPath, allocator=context.temp_allocator)
		if splashErr == nil{
			splashSurf := CreateRGBSurfaceWithFormatFrom(
				raw_data(splashImg.pixels.buf), i32(splashImg.width), i32(splashImg.height), 32, i32(splashImg.width*4),
				u32(PixelFormatEnum.ABGR8888),
			)
			defer FreeSurface(splashSurf)
			windowSurf := GetWindowSurface(display._window)
			BlitScaled(splashSurf, nil, windowSurf, nil)
			UpdateWindowSurface(display._window)
		}
	}
	else{ //force the window to appear on top after launching in debug mode
		SetHint("SDL_HINT_FORCE_RAISEWINDOW", "1")
		RaiseWindow(display._window)
	}
}

_display_init :: proc(){
	
}


//Sets the window scale and resizes the window based on that and the native display resolution
window_resize :: proc(scale:int){
	settings.window_scale = scale
	sdl2.SetWindowSize(display._window, i32(DISPLAY_WIDTH*settings.window_scale), i32(DISPLAY_HEIGHT*settings.window_scale))
	window_center()

	when DEBUG{
		_imgui_scale_update()
	}
}

//
window_scale_to_display :: proc(relativeScale:f32){
	mSize := monitor_size()

	scale:= min(floori(mSize.x*relativeScale/DISPLAY_SIZE.x), floori(mSize.y*relativeScale/DISPLAY_SIZE.y))
	window_resize(scale)
}

monitor_size :: proc() -> Vec2{
	displayBounds:sdl2.Rect
	sdl2.GetDisplayBounds(sdl2.GetWindowDisplayIndex(display._window), &displayBounds)
	return Vec2{f32(displayBounds.w), f32(displayBounds.h)}
}

//Centers the window
window_center :: proc(){
	displayBounds:sdl2.Rect
	sdl2.GetDisplayBounds(sdl2.GetWindowDisplayIndex(display._window), &displayBounds)
	windowW:i32
	windowH:i32
	sdl2.GetWindowSize(display._window, &windowW, &windowH)
	sdl2.SetWindowPosition(display._window, displayBounds.x + displayBounds.w/2-windowW/2, displayBounds.y + displayBounds.h/2 - windowH/2)
}

window_set_fullscreen :: proc(enabled:bool){
	settings.window_fullscreen = enabled
	sdl2.SetWindowFullscreen(display._window, enabled ? sdl2.WINDOW_FULLSCREEN_DESKTOP : {})
	proc_call_delayed(proc(){
		window_scale_to_display(settings.window_fullscreen?1:0.75)
	}, 1)
	
}

//Returns the current window size
window_size :: proc() -> Vec2{
	cw,ch:i32
	sdl2.GetWindowSize(display._window, &cw, &ch)
	return Vec2([2]i32{cw, ch})
}

//for letterboxing
window_offset :: proc()->Vec2{
	ws := window_size()
	ds := DISPLAY_SIZE*f32(settings.window_scale)
	return (ws-ds)/2
}

window_system_cursor_set :: proc(id:sdl2.SystemCursor){
	if(id == display._system_cursor_id) do return
	sdl2.FreeCursor(display._system_cursor)
	display._system_cursor = sdl2.CreateSystemCursor(id)
	sdl2.SetCursor(display._system_cursor)
	display._system_cursor_id = id
}

//Redraws the main texture, can be used with a shader to apply a screenwide effect
display_redraw :: proc(){
	if display.hd_enabled do return //todo if needed
	buffer := &display.main_textures
	when DEBUG{
		if stage_edit.enabled{
			buffer = &stage_edit.draw_textures
		}
	}
	lastTexInd := buffer.active
	newTexInd := int(!bool(lastTexInd))
	buffer.active = newTexInd
	lastTex := buffer.textures[lastTexInd]
	newTex := buffer.textures[newTexInd]
	if len(display._tex_target_stack) > 0{
		storedCamPos := camera.pos
		display._tex_target_stack[0] = newTex
		tex_target_set_stackless(newTex)
		tex_draw(lastTex, 0, 0)
		if len(display._tex_target_stack) > 1 do sdl2.SetRenderTarget(display._renderer, peek(display._tex_target_stack))
		camera.pos = storedCamPos
	}
	else{
		tex_target_set_stackless(newTex)
		tex_draw(lastTex, 0, 0)
		sdl2.SetRenderTarget(display._renderer, nil)
	}
}

display_main_tex :: proc() -> Tex{
	return display.hd_enabled ? display.hd_tex : texBuffer_active_tex(display.main_textures)
}

//Returns the display's inactive main texture. If copyContents is true, copies the current display contents to it before returning.
display_main_tex_inactive :: proc(copyActiveContents:=true) -> Tex{
	when DEBUG do buf := stage_edit.enabled ? stage_edit.draw_textures : display.main_textures
	else do buf := display.main_textures

	off := buf.textures[int(!bool(buf.active))]
	if copyActiveContents{
		tex_target_set(off)
		tex_draw(texBuffer_active_tex(buf),0,0)
		tex_target_reset()
	}
	return off
}

//Returns a display size value that depends on whether HD mode is on or not. For performance and safety, only use in cases where this is uncertain.
display_size :: #force_inline proc "contextless"() -> Vec2{
	return display.hd_enabled ? DISPLAY_SIZE_HD : DISPLAY_SIZE
}

_display_pre_draw :: proc(){
	tex_target_set(display_main_tex())
	draw_clear(DISPLAY_BASE_COLOR)
}

_display_post_draw :: proc(){
	tex_target_clear()
	draw_clear(COLOR_BLACK, 255)
	ws := window_size()
	ds := DISPLAY_SIZE*f32(settings.window_scale)
	dst := rect_to_sdl_rect({(ws-ds)/2, ds})
	sdl2.RenderCopy(display._renderer, display_main_tex(), nil, &dst)
}

_display_system_destroy :: proc(){
	sdl2.DestroyRenderer(display._renderer)
	sdl2.DestroyTexture(display.main_textures.textures[0])
	sdl2.DestroyTexture(display.main_textures.textures[1])
	sdl2.DestroyWindow(display._window)
}

//Any allocated hd texes need to be resized when this changes, fortunately than list is knowable and small.
display_performance_mode_set :: proc(mode:DisplayPerformanceMode){
	settings.performance_mode = mode

	tex_resize(&display.hd_tex, DISPLAY_SIZE_HD)
	tex_resize(&dialogue.hd_portraits_tex, DISPLAY_SIZE_HD)
	if titleScreen,ok := cofind(TitleScreen, 0); ok{
		tex_resize(&titleScreen.shineTex, sp.menuShineHD.size*2)
		tex_resize(&titleScreen.perlinTex, DISPLAY_SIZE_HD)
		tex_target_set(titleScreen.perlinTex,clear=false)
		draw_clear(COLOR_BLACK)
		tex_target_clear()
	}
}

//Picks the strongest performance mode the hardware can handle by timing synthetic worst-case frames through the real render pipeline.
//Runs once on first boot, the result gets saved with the other default settings.
display_performance_mode_detect :: proc(){
	trace("Performance mode detection")

	warmupFrames :: 3 //discarded, absorbs driver shader compilation and other first-use costs
	timedFrames :: 9
	layers :: 8 //rough worst-case overdraw for a busy scene
	frameBudget :: 8.0 //ms of pure fill per frame, leaving the rest of a 60fps frame for everything else

	//source texture at half display size, drawn scaled 2x with linear sampling like real HD content
	settings.performance_mode = .normal
	srcTex := tex_make(DISPLAY_SIZE_HD/2, true)
	defer tex_destroy(srcTex)
	tex_target_set(srcTex)
	draw_clear(DISPLAY_BASE_COLOR)
	tex_target_clear()

	display.hd_enabled = true
	defer display.hd_enabled = false

	for mode in DisplayPerformanceMode{
		display_performance_mode_set(mode) //resizes the hd targets to the mode's true size

		frameTimes:[timedFrames]f32
		for i in 0..<warmupFrames+timedFrames{
			startT := time_get()

			tex_target_set(display.hd_tex)
			for _ in 0..<layers do tex_draw_ex(srcTex, 0, 0, Vec2{2,2})
			tex_target_clear()

			//wait for the GPU to actually finish rendering, otherwise this would only time command submission
			sdl2.RenderFlush(display._renderer)
			gl.Finish()

			if i >= warmupFrames do frameTimes[i-warmupFrames] = time_get()-startT
		}

		sort_general(frameTimes[:])
		median := frameTimes[timedFrames/2]
		printf("Performance benchmark: %v mode, %.2fms median fill time", mode, median)

		if median <= frameBudget do break //this mode fits. If even potato doesn't, it stays selected as the floor
	}
}

//Called whenever the render target changes, global renderer scale is adjusted in HD mode for performance.
_render_scale_update :: proc "contextless" (){
	scale:f32 = 1
	if display.hd_enabled && sdl2.GetRenderTarget(display._renderer) != nil{
		scale = 1/display_performance_factor()
	}
	sdl2.RenderSetScale(display._renderer, scale, scale)
}

display_performance_factor :: #force_inline proc "contextless"() -> f32{
	return f32(DISPLAY_PERFORMANCE_FACTORS[settings.performance_mode])
}

display_apply_settings :: proc(){
	window_set_fullscreen(settings.window_fullscreen)
	window_resize(settings.window_scale)
	display_performance_mode_set(settings.performance_mode)
}

//mainly for window resize shortcuts
_window_system_update :: proc(){
	if key_pressed(.F11) || key_combo_pressed({.ALT}, .RETURN){
		window_set_fullscreen(!settings.window_fullscreen)
		settings_save()
	}
	
	newScale := max(1, settings.window_scale + int(key_pressed(.RIGHTBRACKET)) - int(key_pressed(.LEFTBRACKET)))
	if(newScale != settings.window_scale){
		window_resize(newScale)
		settings_save()
	}
}