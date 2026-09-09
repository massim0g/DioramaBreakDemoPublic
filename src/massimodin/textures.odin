package massimodin //@nested-tags:engine/visuals

import "../sdl3"
import "core:image/png"
import "core:os"
import "core:mem"

Tex :: struct{
	using ptr:^sdl3.GPUTexture,
	size:Vec2i,
	hd:bool
}

TexBuffered :: struct{
	using tex:Tex,
	scratch:Tex
}

tex_target_set_tex :: proc(target:Tex, camPos:=Vec2{0,0}, clear:=true, coordScale:f32=1){
	if coordScale == 1 do append(&render._entries, RenderEntryTarget{target, Vec2(target.size)})
	else do append(&render._entries, new_clone(RenderEntryTargetOverloaded{target, Vec2(target.size), nil, coordScale}, context.temp_allocator))

	camera_set(camPos)
	if clear do draw_clear(COLOR_WHITE, 0)
}
tex_target_set_buffered :: proc(target:TexBuffered, camPos:=Vec2{0,0}, clear:=true, coordScale:f32=1){
	append(&render._entries, new_clone(RenderEntryTargetOverloaded{target.tex, Vec2(target.size), target.scratch, coordScale}, context.temp_allocator))

	camera_set(camPos)
	if clear do draw_clear(COLOR_WHITE, 0)
}
tex_target_set :: proc{tex_target_set_tex, tex_target_set_buffered}

//Resets the drawing target to the previous target.
tex_target_reset :: proc(resetCount:=1){
	camera_reset(resetCount)
	append(&render._entries, RenderEntryTargetPop{resetCount})
}

//Clears the texture target stack and targets the window. Also resets the camera.
tex_target_clear :: proc(){
	append(&render._entries, RenderEntryTargetClear{})
	camera_clear()
}

//hd content is high resolution art, sd targets keep nearest for pixel art
tex_sampler :: #force_inline proc "contextless" (tex:Tex) -> SamplerKind{
	return tex.hd ? .linear : .nearest
}

tex_make_i :: proc(w,h:int, hd:=false) -> Tex{
	assert(w >= 0 && h >= 0, "Cannot create a texture with negative size!")
	ptr := sdl3.CreateGPUTexture(render.device, {
		type=.D2,
		format=TEXTURE_FORMAT_DEFAULT,
		usage={.SAMPLER, .COLOR_TARGET},
		width=u32(max(w, 1)),
		height=u32(max(h, 1)),
		layer_count_or_depth=1,
		num_levels=1,
	})
	assertf(ptr != nil, "GPU texture creation failed (%dx%d)! %s", w, h, sdl3.GetError())
	return Tex{ptr, {w, h}, hd}
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

	size := Vec2i{img.width, img.height}
	return Tex{texture_make_from_pixels(img.pixels.buf[:], size), size, false}
}

tex_destroy :: proc(tex:Tex){
	if tex.ptr == nil do return
	append(&render.tex_destroy_list, tex)
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

	if tex.size == {w,h} do return

	hd := tex.hd
	tex_destroy(tex^)
	tex^ = tex_make_i(w,h, hd)
}
//WARNING: Will delete and recreate (or just create, if nil) the underlying texture, ensure nothing else is using it.
//If called on a texture that has already been used as a target this frame, the render plan will still use the old texture.
tex_resize :: proc{tex_resize_i, tex_resize_veci, tex_resize_f, tex_resize_vec}

tex_draw_f :: #force_inline proc(tex:Tex, x,y:f32){
	tex_draw_vec2(tex, {x,y})
}
tex_draw_vec2 :: #force_inline proc(tex:Tex, pos:Vec2){
	render_quad(tex.ptr, tex_sampler(tex), Quad{
		worldRect = {pos, Vec2(tex.size)},
		uvRect = {0,0,1,1},
		blend = BLEND_WHITE,
	})
}
//Draws a texture. Will throw an error if you try to draw the current target texture.
tex_draw :: proc{tex_draw_f, tex_draw_vec2}

tex_draw_ex_f :: proc(tex:Tex, x,y:f32, scale:=Vec2{1,1}, angle:f32=0, color:Color=COLOR_WHITE, alpha:f32=1, pivot:=Vec2{}, feetPos:Maybe(Vec2)=nil){

	size := Vec2(tex.size)
	newSize := size*abs(scale)

	flags:QuadFlags
	if scale.x < 0 do flags += {.flipX}
	if scale.y < 0 do flags += {.flipY}
	feet, hasFeet := feetPos.?
	if hasFeet do flags += {.verticalShading}

	render_quad(tex.ptr, tex_sampler(tex), Quad{
		worldRect = {{round(x), round(y)}, {round(newSize.x), round(newSize.y)}},
		uvRect = {0,0,1,1},
		feetPos = feet,
		pivot = pivot,
		rotation = angle_to_rads(-angle),
		blend = color_to_blend(color, alpha),
		flags = flags,
	})
}
tex_draw_ex_vec2 :: #force_inline proc(tex:Tex, pos:Vec2, scale:=Vec2{1,1}, angle:f32=0, color:Color=COLOR_WHITE, alpha:f32=1, pivot:=Vec2{}, feetPos:Maybe(Vec2)=nil){
	tex_draw_ex_f(tex, pos.x, pos.y, scale, angle, color, alpha, pivot, feetPos)
}
tex_draw_ex :: proc{tex_draw_ex_f, tex_draw_ex_vec2}

//Draw a texture perspective-projected onto a quadrilateral. The quad corners are in screen space.
tex_draw_perspective :: proc(tex:Tex, quad:[4]Vec2){
	transform := matrix_inverse(perspective_transform_make(quad))
	p := Sh_Perspective{screenSize = Vec2{DISPLAY_WIDTH, DISPLAY_HEIGHT}}
	//hlsl cbuffer matrices are column_major, one column per 16-byte row, so the 3x3 spreads into a [3][4]f32
	for c in 0..<3{
		for r in 0..<3 do p.transform[c][r] = transform[r, c]
	}
	shader_set(p)

	//the shader does the projection, the draw is just a fullscreen quad sampling the source
	camera_set(0)
	render_quad(tex.ptr, tex_sampler(tex), Quad{
		worldRect = {size = DISPLAY_SIZE},
		uvRect = {0,0,1,1},
		blend = BLEND_WHITE,
	})
	camera_reset()

	shader_reset()
}

texes_to_sprite :: proc(texes:[]Tex, origin:=Vec2{}, durations:[]f32=nil, allocator:=context.temp_allocator) -> ^Sprite{
	out := new(Sprite, allocator)
	out.origin = origin
	out.frames = make([dynamic]SpriteFrame, len(texes), allocator)
	t :f32= 0
	for tex,i in texes{
		d:f32
		if i < len(durations) do d = durations[i]

		//each tex becomes its own one-frame page. Page uvs normalize against a single dimension, so a non-square tex here would sample wrong
		page := new(TexturePage, allocator)
		page^ = TexturePage{texture=tex.ptr, size=f32(tex.size.x), hd=tex.hd}

		out.frames[i] = SpriteFrame{
			texturePage = page,
			texturePagePos = Rect{{0,0}, Vec2(tex.size)},
			duration = d,
			framePosition = t,
		}
		t += d
	}
	return out
}

surface_pixel_get :: proc "contextless" (surf:^sdl3.Surface, x:int, y:int) -> Blend{
	if !rect_contains(Recti{0, {int(surf.w), int(surf.h)}}, Vec2i{x,y}) do return Blend{}
	formatDetails := sdl3.GetPixelFormatDetails(surf.format) //SDL3: surface format is an enum, details struct holds the layout
	pixels := uintptr(surf.pixels)
	pitch := uintptr(surf.pitch)
	bpp := int(formatDetails.bytes_per_pixel)
	bppUip := uintptr(bpp)

	pixelData:u32
	mem.copy(&pixelData, rawptr(pixels + uintptr(x)*bppUip + uintptr(y)*pitch), bpp)

	out:Blend
	sdl3.GetRGBA(pixelData, formatDetails, nil, &out.r, &out.g, &out.b, &out.a)

	return out
}

surface_pixel_filled :: #force_inline proc "contextless" (surf:^sdl3.Surface, x:int, y:int) -> bool{
	return surface_pixel_get(surf,x,y).a != 0
}

texBuffered_make :: proc(size:Vec2) -> TexBuffered{
	return TexBuffered{tex_make(size), tex_make(size)}
}

texBuffered_destroy :: proc(tex:TexBuffered){
	tex_destroy(tex.tex)
	tex_destroy(tex.scratch)
}

//snapshots the contents of a buffered tex to its scratch tex
texBuffered_snapshot :: proc(tex:TexBuffered){
	tex_target_set(tex.scratch)
	tex_draw(tex, 0, 0)
	tex_target_reset()
}

