#+feature using-stmt
package massimodin //@nested-tags:engine/visuals

import "core:path/filepath"
import "../sdl3"
import "core:image/png"
import "core:os"
import "../imgui"
import "core:math"

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
	_window:^sdl3.Window,

	main_tex:TexBuffered, //native res +1, anything below the ui draws here, gets sub-pixel shifted slightly when blown up and drawn to the window tex for smooth camera movement 
	window_tex:TexBuffered, //window-res, main_tex draws on here, then all UI draws (scaled appropriately using renderer coordinate scaling). Treat as though it's native-res when drawing to it. 
	hd_tex:Tex,
	hd_enabled:bool,
	_system_cursor:^sdl3.Cursor,
	_system_cursor_id:sdl3.SystemCursor,
}
display:^DisplaySystem

//Creates the window only. The GPU device claims it in _render_system_init, which must run straight after.
_display_system_init :: proc(){
	trace("Display System Init")
	using sdl3

	display = new(DisplaySystem)

	display._window = CreateWindow("Diorama Break Demo", DISPLAY_WIDTH, DISPLAY_HEIGHT, {})

	SetWindowIcon(display._window, LoadBMP(string_to_cstring(filepath.join({executable_directory, "windowIcon.bmp"}, context.temp_allocator) or_else "", context.temp_allocator)))

	when !DEBUG{
		SetWindowSize(display._window, i32(DISPLAY_WIDTH*3), i32(DISPLAY_HEIGHT*3))
		window_center()
	}
	else{ //force the window to appear on top after launching in debug mode
		SetHint(HINT_FORCE_RAISEWINDOW, "1")
		RaiseWindow(display._window)
	}
}

//Called once the GPU device exists. Creates the render targets and shows the splash.
_display_targets_init :: proc(){
	display.main_tex = texBuffered_make(DISPLAY_SIZE + {1,1}) //one pixel of overdraw for the smooth camera blit shift
	display.window_tex = texBuffered_make(DISPLAY_SIZE*f32(settings.window_scale))
	display.hd_tex = tex_make(DISPLAY_SIZE_HD, true)

	when !DEBUG do _display_splash_draw()
}

DepthLayer :: enum{
	stageBottom, //all stage draws should be above this
	stageBG, //floor draws here
	stage, //0, most stage elements draw right around here (+/- stage height)
	stageFG, //stage foreground draws here
	stageTop, //all stage draws should be below this
	ui, //ui sub-layers start drawing here
	uiTop, //all ui draws should be below this
	window //anything above this draws directly to the window
}
DEPTH_LAYER_ZERO :: DepthLayer.stage
DEPTH_LAYER_RANGE :: 100_000 //distance between depth layers

DepthUnion :: union{
	f32,
	DepthLayer,
	UILayer
}

/*
The loading splash, shown before any assets (and therefore any shader) exist.
BlitGPUTexture needs no pipeline, so this can run with nothing but a device and an uploaded texture.
*/
_display_splash_draw :: proc(){
	splashPath := filepath.join({executable_directory, "splashScreen.png"}, context.temp_allocator) or_else ""
	splashImg, splashErr := png.load_from_file(splashPath, allocator=context.temp_allocator)
	if splashErr != nil do return

	splashSize := Vec2i{splashImg.width, splashImg.height}
	splashTex := texture_make_from_pixels(splashImg.pixels.buf[:], splashSize)
	defer sdl3.ReleaseGPUTexture(render.device, splashTex)

	cmdBuf := sdl3.AcquireGPUCommandBuffer(render.device)
	swapchainTex:^sdl3.GPUTexture
	winW, winH:u32
	if !sdl3.WaitAndAcquireGPUSwapchainTexture(cmdBuf, display._window, &swapchainTex, &winW, &winH) || swapchainTex == nil{
		_ = sdl3.CancelGPUCommandBuffer(cmdBuf)
		return
	}
	sdl3.BlitGPUTexture(cmdBuf, {
		source={texture=splashTex, w=u32(splashSize.x), h=u32(splashSize.y)},
		destination={texture=swapchainTex, w=winW, h=winH},
		load_op=.CLEAR,
		clear_color={0, 0, 0, 1},
		filter=.LINEAR,
	})
	_ = gpu_commands_submit(cmdBuf)
	_ = sdl3.WaitForGPUIdle(render.device)
}

// WINDOW SCALING/POSITIONING

//Sets the window scale and resizes the window based on that and the native display resolution
window_resize :: proc(scale:int){
	settings.window_scale = scale
	sdl3.SetWindowSize(display._window, i32(DISPLAY_WIDTH*settings.window_scale), i32(DISPLAY_HEIGHT*settings.window_scale))
	
	when ON_LINUX do sdl3.SyncWindow(display._window) //X11 applies size changes asynchronously, so without a sync window_center reads the old size
	
	window_center()

	tex_resize(&display.window_tex.tex, DISPLAY_SIZE*f32(scale))
	tex_resize(&display.window_tex.scratch, DISPLAY_SIZE*f32(scale))

	when DEBUG{
		_imgui_scale_update()
	}
}

window_scale_to_display :: proc(relativeScale:f32){
	mSize := monitor_size()

	scale:= min(floori(mSize.x*relativeScale/DISPLAY_SIZE.x), floori(mSize.y*relativeScale/DISPLAY_SIZE.y))
	window_resize(scale)
}

monitor_size :: proc() -> Vec2{
	displayBounds:sdl3.Rect
	sdl3.GetDisplayBounds(sdl3.GetDisplayForWindow(display._window), &displayBounds)
	return Vec2{f32(displayBounds.w), f32(displayBounds.h)}
}

//Centers the window
window_center :: proc(){
	displayBounds:sdl3.Rect
	sdl3.GetDisplayBounds(sdl3.GetDisplayForWindow(display._window), &displayBounds)
	windowW:i32
	windowH:i32
	sdl3.GetWindowSize(display._window, &windowW, &windowH)
	sdl3.SetWindowPosition(display._window, displayBounds.x + displayBounds.w/2-windowW/2, displayBounds.y + displayBounds.h/2 - windowH/2)
}

window_set_fullscreen :: proc(enabled:bool){
	settings.window_fullscreen = enabled
	sdl3.SetWindowFullscreen(display._window, enabled) //SDL3: bool fullscreen, borderless desktop mode unless an exclusive mode is set
	proc_call_delayed(proc(){
		window_scale_to_display(settings.window_fullscreen?1:0.75)
	}, 1)
	
}

//Returns the current window size
window_size :: proc() -> Vec2{
	cw,ch:i32
	sdl3.GetWindowSize(display._window, &cw, &ch)
	return Vec2([2]i32{cw, ch})
}

//for letterboxing
window_offset :: proc()->Vec2{
	ws := window_size()
	ds := DISPLAY_SIZE*f32(settings.window_scale)
	return (ws-ds)/2
}

window_system_cursor_set :: proc(id:sdl3.SystemCursor){
	if(id == display._system_cursor_id) do return
	sdl3.DestroyCursor(display._system_cursor)
	display._system_cursor = sdl3.CreateSystemCursor(id)
	_ = sdl3.SetCursor(display._system_cursor)
	display._system_cursor_id = id
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

// DISPLAY MAIN TEXTURE

//Redraws the current render target through the currently pushed shader, used to apply a screenwide effect.
display_redraw :: proc(){
	if display.hd_enabled do return //todo if needed

	append(&render._entries, RenderEntrySnapshot{})
	append(&render._quads, Quad{uvRect={0,0,1,1}, blend=BLEND_WHITE, flags={.fullscreen}})
	append(&render._entries, RenderEntryQuad{u32(len(render._quads)-1)})
}

display_main_tex :: proc() -> Tex{
	return display.hd_enabled ? display.hd_tex : display.main_tex
}

display_main_tex_draw :: proc(offset:Vec2=0){
	if display.hd_enabled do tex_draw(display.hd_tex, offset)
	else do tex_draw(display.main_tex, -round(stage.camera_pos_subpixel) + offset)
}

display_window_tex_draw :: proc(offset:Vec2=0){
	tex_draw_ex(display.window_tex, offset, 1./f32(settings.window_scale))
}

//Copies the current screen contents to the snapshot scratch and returns it, e.g. for shaders that sample their destination.
display_snapshot :: proc() -> Tex{
	when DEBUG do tex := stage_edit.enabled ? stage_edit.draw_tex : display.main_tex
	else do tex := display.main_tex

	texBuffered_snapshot(tex)
	return tex.scratch
}

//Returns a display size value that depends on whether HD mode is on or not. For performance and safety, only use in cases where this is uncertain.
display_size :: #force_inline proc "contextless"() -> Vec2{
	return display.hd_enabled ? DISPLAY_SIZE_HD : DISPLAY_SIZE
}

// DISPLAY DEPTH

//Returns the depth of a depth layer
layer_depth :: #force_inline proc "contextless" (layer:DepthLayer) -> f32{
	return -f32(layer)*DEPTH_LAYER_RANGE + f32(DEPTH_LAYER_ZERO)*DEPTH_LAYER_RANGE
}

depthUnion_depth :: proc(du:DepthUnion)->f32{
	switch d in du{
		case f32: return d
		case DepthLayer: return layer_depth(d)
		case UILayer: return ui_layer_depth(d)
	}
	unreachable()
}

// DISPLAY SETTINGS

display_apply_settings :: proc(){
	window_set_fullscreen(settings.window_fullscreen)
	window_resize(settings.window_scale)
}

// DISPLAY DRAWS

_display_pre_draw :: proc(){
	if display.hd_enabled do tex_target_set(display.hd_tex)
	else do tex_target_set(display.main_tex) //buffered, so replay-resolved snapshots reach the scratch
	draw_clear(DISPLAY_BASE_COLOR)

	if !display.hd_enabled{
		render_depth_layer(.ui, 100)
		tex_target_set(display.window_tex, clear=false, coordScale=f32(settings.window_scale))
		render_quad(display.main_tex, tex_sampler(display.main_tex), Quad{
			worldRect = {0, DISPLAY_SIZE}, //coordScale expands this to the full target
			uvRect = display_world_blit_uv(),
			blend = BLEND_WHITE,
		})
	}
	render_depth(INT_MAX_F32-1)
}

/*
The world tex has a pixel of overdraw beyond the display size.
This returns the uv rect of a display-sized window into it, offset by the camera's subpixel remainder quantized to whole window pixels, which pans the world smoothly while keeping every texel aligned to window pixels.
*/
display_world_blit_uv :: proc() -> [4]f32{
	scale := f32(settings.window_scale)
	shift := round(stage.camera_pos_subpixel*scale)/scale
	texSize := Vec2(display.main_tex.size)
	uvMin := shift/texSize
	uvMax := (shift + DISPLAY_SIZE)/texSize
	return {uvMin.x, uvMin.y, uvMax.x, uvMax.y}
}

_display_post_draw :: proc(){
	render_depth_layer(.window)
	tex_target_clear()
	draw_clear(COLOR_BLACK, 255)
	ws := window_size()
	ds := DISPLAY_SIZE*f32(settings.window_scale)
	presentTex := display.hd_enabled ? display.hd_tex : display.window_tex.tex
	render_quad(presentTex, tex_sampler(presentTex), Quad{
		worldRect = {(ws-ds)/2, ds},
		uvRect = {0,0,1,1},
		blend = BLEND_WHITE,
	})
}