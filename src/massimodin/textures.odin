package massimodin //@nested-tags:engine/visuals

import "../sdl2"
import "core:image/png"
import "core:os"
import "core:math"
import "core:mem"
import "../tracy"

Tex :: struct{
	using ptr:^sdl2.Texture,
	size:Vec2i, //"logical" size. The true size of hd texes is smaller in reduced performance modes.
	hd:bool
}

TexBuffer :: struct{
	textures:[2]Tex,
	active:int
}

//Sets the current drawing target.
tex_target_set :: proc(target:Tex, camPos:=Vec2{0,0}, clear:=true){
	append(&display._tex_target_stack, target)
	sdl2.SetRenderTarget(display._renderer, target)
	_render_scale_update()
	camera_set(camPos)
	if(clear) do draw_clear(COLOR_WHITE, 0)
}

//Sets the drawing target without affecting the stack. Should only be used for performance optimization.
tex_target_set_stackless :: proc(target:^sdl2.Texture, camPos:=Vec2{0,0}){
	sdl2.SetRenderTarget(display._renderer, target)
	camera.pos = {i32(round(camPos.x)), i32(round(camPos.y))}
}

//Resets the drawing target to the previous target. 
tex_target_reset :: proc(resetCount:=1){
	if len(display._tex_target_stack) < 1+resetCount{
		tex_target_clear()
		return
	}

	for i in 0..<resetCount{
		pop(&display._tex_target_stack)
	}

	stackL := len(display._tex_target_stack)
	sdl2.SetRenderTarget(display._renderer, display._tex_target_stack[stackL - 1])
	_render_scale_update()
	camera_reset(resetCount)
}

//Clears the texture target stack and targets the window (nil). Also resets the camera.
tex_target_clear :: proc(){
	clear(&display._tex_target_stack)
	sdl2.SetRenderTarget(display._renderer, nil)
	_render_scale_update()
	camera_clear()
}

//Returns the current texture target
tex_target_get :: #force_inline proc "contextless"() -> Tex{
	stackL := len(display._tex_target_stack)
	return (stackL > 0) ? display._tex_target_stack[stackL - 1] : Tex{size={-1, -1}}
}

//HD texes' true sizes are smaller than their "logical" size in reduced performance modes.
//This proc converts from that logical size to the true size based on the current perf setting.
tex_hd_size_to_true_size :: #force_inline proc "contextless" (w,h:int) -> Vec2i{
	dpf := int(display_performance_factor())
	return {w/dpf, h/dpf}
}

tex_make_i :: proc(w,h:int, hd:=false) -> Tex{
	assert(w >= 0 && h >= 0, "Cannot create a texture with negative size!")
	trueSize := hd ? tex_hd_size_to_true_size(w,h) : Vec2i{w,h}
	out := Tex{sdl2.CreateTexture(display._renderer, u32(sdl2.PixelFormatEnum.ABGR8888), .TARGET, i32(trueSize.x), i32(trueSize.y)), {w, h}, hd}
	sdl2.SetTextureBlendMode(out, .BLEND)
	if hd do sdl2.SetTextureScaleMode(out, .Linear) //hd content is high resolution art, sd targets keep nearest for pixel art
	//when tracy.TRACY_ENABLE do tracy.EmitAlloc(slice_from_ptr(cast(^u8)out.ptr, 1), trueSize.x*trueSize.y*4, tracy.TRACY_CALLSTACK, true)
	return out
}
tex_make_f :: #force_inline proc(w,h:f32, hd:=false) -> Tex{
	return tex_make_i(int(w), int(h), hd)
}
tex_make_vec2 :: #force_inline proc(size:Vec2, hd:=false) -> Tex{
	return tex_make_i(int(size.x), int(size.y), hd)
}
tex_make_vec2i :: #force_inline proc(size:Vec2i, hd:=false) -> Tex{
	return tex_make_i(size.x, size.y, hd)
}
tex_make :: proc{tex_make_i, tex_make_f, tex_make_vec2, tex_make_vec2i}

sprite_tex_make :: proc(spr:^Sprite, flip:bool=false) -> (tex:Tex, drawOffset:Vec2){
	tex = tex_make(spr.size)
	drawOffset = Vec2{f32(spr.origin.x), f32(spr.origin.y)}
	if flip do drawOffset.x += spr.size.x - drawOffset.x*2 - 1
	drawOffset = -drawOffset
	return
}

tex_make_from_file :: proc(path:string) -> Tex{
	fileData, readErr := os.read_entire_file(path, context.temp_allocator)
	assertf(readErr == nil, "Error '%v' when reading image file '%s'!", readErr, path)
	img, imgErr := png.load_from_bytes(fileData, options={.alpha_add_if_missing}, allocator=context.temp_allocator)
	assertf(imgErr == nil, "Error '%v' when loading image file '%s'!", imgErr, path)
	assertf(img.depth == 8 && img.channels == 4, "Image file '%s' has an unsupported format (%d channels, %d bit)!", path, img.channels, img.depth)

	surf := sdl2.CreateRGBSurfaceWithFormatFrom(
		raw_data(img.pixels.buf), i32(img.width), i32(img.height), 32, i32(img.width*4),
		u32(sdl2.PixelFormatEnum.ABGR8888),
	)
	defer sdl2.FreeSurface(surf)
	t := sdl2.CreateTextureFromSurface(display._renderer, surf)
	return Tex{t, Vec2i{img.width, img.height}, false}
}

tex_blendmode_set :: #force_inline proc(tex:Tex, blendmode:BlendMode){
	sdl2.SetTextureBlendMode(tex, display.custom_blendmodes[blendmode])
}

tex_destroy :: proc(tex:Tex){
	if tex.ptr == nil do return
	//when tracy.TRACY_ENABLE do tracy.EmitFree(tex.ptr, tracy.TRACY_CALLSTACK, true)
	sdl2.DestroyTexture(tex)
}


tex_resize_f :: #force_inline proc(tex:^Tex, w,h:f32){
	tex_resize_i(tex, int(w), int(h))
}
tex_resize_vec :: #force_inline proc(tex:^Tex, size:Vec2){
	tex_resize_i(tex, int(size.x), int(size.y))
}
tex_resize_veci :: #force_inline proc(tex:^Tex, size:Vec2i){
	tex_resize_i(tex, size.x, size.y)
}
tex_resize_i :: proc(tex:^Tex, w,h:int){
	if tex.ptr == nil{
		tex^ = tex_make_i(w,h)
		return
	}

	if tex.hd{ 
		trueW, trueH:i32
		sdl2.QueryTexture(tex.ptr, nil, nil, &trueW, &trueH)
		if (Vec2i{int(trueW), int(trueH)} == tex_hd_size_to_true_size(w,h)) do return
	}
	else if tex.size == {w,h} do return

	sm:sdl2.ScaleMode
	bm:sdl2.BlendMode
	sdl2.GetTextureScaleMode(tex, &sm)
	sdl2.GetTextureBlendMode(tex, &bm)
	tex_destroy(tex^)
	tex^ = tex_make_i(w,h, tex.hd)
	sdl2.SetTextureScaleMode(tex, sm)
	sdl2.SetTextureBlendMode(tex, bm)
}
//WARNING: Will delete and recreate (or just create, if nil) the underlying texture, ensure nothing else is using it.
tex_resize :: proc{tex_resize_i, tex_resize_veci, tex_resize_f, tex_resize_vec}

tex_draw_i :: proc(tex:Tex, x:i32, y:i32){
	assert(tex.ptr != tex_target_get().ptr, "Tried to draw current target texture!")
	dstRect := sdl2.Rect{x - camera.pos.x, y - camera.pos.y, i32(tex.size.x), i32(tex.size.y)}

	sdl2.SetTextureColorMod(tex.ptr, 255, 255, 255)
	sdl2.SetTextureAlphaMod(tex.ptr, 255)
	sdl2.RenderCopy(display._renderer, tex, nil, &dstRect)
}
tex_draw_f :: #force_inline proc(tex:Tex, x,y:f32){
	tex_draw_i(tex, i32(x), i32(y))
}
tex_draw_vec2 :: #force_inline proc(tex:Tex, pos:Vec2){
	tex_draw_i(tex, i32(pos.x), i32(pos.y))
}
//Draws a texture. Will throw an error if you try to draw the current target texture.
tex_draw :: proc{tex_draw_f, tex_draw_vec2}

tex_draw_ex_f :: proc(tex:Tex, x,y:f32, scale:=Vec2{1,1}, angle:f32=0, color:Color=COLOR_WHITE, alpha:f32=1, pivot:=Vec2{}){
	flip := [2]int{int(scale.x < 0), int(scale.y < 0)}
	assert(!(flip.x == 1 && flip.y == 1), "Only one tex scale can be negative at a time!")
	flipConst := sdl2.RendererFlip(flip.x + flip.y*2)

	//convert origin and new sizes to f32 for transformation and adjust for trim
	size := Vec2(tex.size)
	newSize := size*abs(scale)
	sizeDelta := newSize - size

    destRect := sdl2.Rect{
		i32(math.round(x)) - camera.pos.x,
    	i32(math.round(y)) - camera.pos.y,
		i32(math.round(newSize.x)),
		i32(math.round(newSize.y))
	}

	pivot := sdl2.Point{i32(pivot.x),i32(pivot.y)}
	
	sdl2.SetTextureColorMod(tex.ptr, color.r, color.g, color.b)
	sdl2.SetTextureAlphaMod(tex.ptr, u8(clamp(alpha*255, 0, 255)))
	sdl2.RenderCopyEx(display._renderer, tex.ptr, nil, &destRect, f64(-angle), &pivot, flipConst)
}
tex_draw_ex_vec2 :: #force_inline proc(tex:Tex, pos:Vec2, scale:=Vec2{1,1}, angle:f32=0, color:Color=COLOR_WHITE, alpha:f32=1, pivot:=Vec2{}){
	tex_draw_ex_f(tex, pos.x, pos.y, scale, angle, color, alpha, pivot)
}
tex_draw_ex :: proc{tex_draw_ex_f, tex_draw_ex_vec2}

//Draw a texture perspective-projected onto a quadrilateral
tex_draw_perspective :: proc(tex:Tex, quad:[4]Vec2){
	quad:=quad
	camPos := Vec2(camera.pos)
	for &p in quad{
		p -= camPos
	}

	shader_set(sh.perspective)

	transform := matrix_inverse(perspective_transform_make(quad))
	shader_uniform_set(sh.perspective, "texture", i32(0))
	shader_uniform_matrix_set(sh.perspective, "transform", &transform)
	shader_uniform_set_using_loc(shader_uniform_loc(sh.perspective, "screenSize"), f32(DISPLAY_WIDTH), f32(DISPLAY_HEIGHT))

	dstRect := sdl2.Rect{0, 0, i32(DISPLAY_WIDTH), i32(DISPLAY_HEIGHT)}
	sdl2.RenderCopy(display._renderer, tex, nil, &dstRect)
	
	shader_reset()
}

texes_to_sprite :: proc(texes:[]Tex, origin:=Vec2{}, durations:[]f32=nil, allocator:=context.temp_allocator) -> ^Sprite{
	out := new(Sprite, allocator)
	out.origin = sdl2.Point{i32(origin.x), i32(origin.y)}
	out.frames = make([dynamic]SpriteFrame, len(texes), allocator)
	t :f32= 0
	for tex,i in texes{
		d:f32
		if i < len(durations) do d = durations[i]
		out.frames[i] = SpriteFrame{
			tex.ptr,
			sprites._texture_page_surface_nil,
			sdl2.Rect{0,0,i32(tex.size.x), i32(tex.size.y)},
			sdl2.Point{},
			d,
			t,
		}
		t += d
	}
	return out
}

surface_pixel_get :: proc "contextless" (surf:^sdl2.Surface, x:int, y:int) -> Blend{
	if !rect_contains(Recti{0, {int(surf.w), int(surf.h)}}, Vec2i{x,y}) do return Blend{}
	format := surf.format
	pixels := uintptr(surf.pixels)
	pitch := uintptr(surf.pitch)
	bpp := int(format.BytesPerPixel)
	bppUip := uintptr(bpp)

	pixelData:u32
	mem.copy(&pixelData, rawptr(pixels + uintptr(x)*bppUip + uintptr(y)*pitch), bpp)

	out:Blend
	sdl2.GetRGBA(pixelData, format, &out.r, &out.g, &out.b, &out.a)
	
	return out
}

surface_pixel_filled :: #force_inline proc "contextless" (surf:^sdl2.Surface, x:int, y:int) -> bool{
	return surface_pixel_get(surf,x,y).a != 0
}

texBuffer_make :: proc(size:Vec2) -> TexBuffer{
	return TexBuffer{
		{tex_make(size), tex_make(size)},
		0
	}
}

texBuffer_active_tex :: proc(buf:TexBuffer) -> Tex{
	return buf.textures[buf.active]
}