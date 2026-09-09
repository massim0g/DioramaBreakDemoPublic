package massimodin //@nested-tags:engine/sprites

import "../sdl3"
import "core:math/linalg"
import "core:math"


SpriteSystem :: struct{
	//all texture page and sprite info is loaded into memory on startup by asset unpacker
	_texture_groups_map:map[string]TextureGroup,
	_sprites_map:map[string]Sprite,
	names:[dynamic]string,
	_sprite_nil:Sprite,
	_spriteFrame_nil:SpriteFrame,
	_texture_page_nil:TexturePage,
	nineslice_info:map[^Sprite]NinesliceInfo,
	file_tree:^FileTreeFolder, //used for asset browsing in debug mode
	_debug_mask_textures_loaded:bool,

	game_load_preloaded_texture_groups:[dynamic]string, //groups preloaded on game load, block on these when the first stage is loaded.
	texture_groups_dynamic:[dynamic]string //list of texture groups NOT in the permanent set
}
sprites:^SpriteSystem

_sprite_system_init :: proc(){
	sprites = new(SpriteSystem)
	sp = new(SpriteIDs, assets.allocator)
	
	init(&sprites._sprites_map, assets.allocator)
	init(&sprites._texture_groups_map, assets.allocator)
	init(&sprites.texture_groups_dynamic, assets.allocator)
	init(&sprites.names, assets.allocator)
	init(&sprites.nineslice_info, assets.allocator)

	when DEBUG{
		sprites.file_tree = file_tree_folder_new("sprites")
	}

	sprites._texture_page_nil = TexturePage{
		texture = texture_make_from_pixels({0,0,0,0}, 1),
		surface = sdl3.CreateSurface(1, 1, .ABGR8888),
		size = 1,
	}
	sprites._spriteFrame_nil = SpriteFrame{
		texturePage = &sprites._texture_page_nil,
		texturePagePos = Rect{{0,0},{1,1}},
		duration = 20,
	}

	sprites._sprite_nil = Sprite{
		make([dynamic]SpriteFrame, 1, assets.allocator),
		"nil",
		nil,
		20,
		{1, 1},
		Vec2{0,0},
		false
	}
	sp.nil_ = &sprites._sprite_nil
	sp.nil_.frames[0] = sprites._spriteFrame_nil
}

SpriteFrame :: struct{
    texturePage:^TexturePage,
    texturePagePos:Rect,
	trimOffset:Vec2,
    duration:f32, //in ms
	framePosition:f32 //also in ms
}

Sprite :: struct{
    frames:[dynamic]SpriteFrame,
	name:string,
	mask:^ColliderMask,
	totalDuration:f32, //in ms
	size:Vec2,
	origin:Vec2,
	pingPong:bool
}

TextureGroup :: struct{
	pages:[dynamic]TexturePage,
	name:string,
	loadState:TexturePageLoadState,
	hd:bool
}

TexturePage :: struct{
	//these fields are read by every sprite draw, keep them together
	using texture:^sdl3.GPUTexture,
	size:f32, //the virtual page size, which is what uvs normalize against. same as the actual size unless the page is mip-mapped. Pages are always square.
	hd:bool,

	//set these at startup while reading the index
	surface:^sdl3.Surface,
	spriteFrames:[]^SpriteFrame,
	loadAllocator:Allocator //freed when page is unloaded
}

sprite_page_size :: #force_inline proc "contextless" (s:^Sprite, frameInd:=0) -> Vec2{
	size := s.frames[frameInd].texturePage.size
	return Vec2{size, size}
}

//Normalized uv rect for a sub-rect of the frame's page.
//Divide by the virtual page size even for mip-mapped pages to keep coordinates consistent
texture_page_uv :: #force_inline proc "contextless" (page:^TexturePage, r:Rect) -> [4]f32{
	inv := 1.0/page.size
	return {r.x*inv, r.y*inv, (r.x+r.size.x)*inv, (r.y+r.size.y)*inv}
}
spriteFrame_uv :: #force_inline proc "contextless" (frame:^SpriteFrame, r:Rect) -> [4]f32{
	return texture_page_uv(frame.texturePage, r)
}

//hd pages are high resolution art and get a mip chain, sd pages keep nearest for pixel art
spriteFrame_sampler :: #force_inline proc "contextless" (frame:^SpriteFrame) -> SamplerKind{
	return frame.texturePage.hd ? .linearMip : .nearest
}

sprite_draw_vec2 :: #force_inline proc (sp:^Sprite, pos:Vec2, frameIndex := 0){
	assert(sp != nil, "Trying to draw nil sprite!")

	frame := &sp.frames[frameIndex]

	render_quad(frame.texturePage.texture, spriteFrame_sampler(frame), Quad{
		worldRect = {pos + frame.trimOffset - sp.origin, frame.texturePagePos.size},
		uvRect = spriteFrame_uv(frame, frame.texturePagePos),
		blend = BLEND_WHITE
	})
}
sprite_draw_i :: proc(sp:^Sprite, #any_int x:i32, #any_int y:i32, frameIndex:=0){
	sprite_draw_vec2(sp, {f32(x),f32(y)}, frameIndex)
}
sprite_draw_f :: #force_inline proc (sp:^Sprite, x,y:f32, frameIndex := 0){
    sprite_draw_vec2(sp, {x,y}, frameIndex)
}
sprite_draw :: proc{sprite_draw_i, sprite_draw_f, sprite_draw_vec2}


sprite_draw_ex_vec2 :: #force_inline proc (sp:^Sprite, pos:Vec2, frameIndex:=0, scale:=Vec2{1,1}, angle:f32=0, color:Color=COLOR_WHITE, alpha:f32=1, feetPos:Maybe(Vec2)=nil){
	assert(sp != nil, "Trying to draw nil sprite!")

	angle := angle
	flip := [2]bool{scale.x < 0, scale.y < 0}

	frame := &sp.frames[frameIndex]

	//adjust the origin and new sizes for trim
	size := frame.texturePagePos.size
	newSize := size*abs(scale)
	sizeDelta := newSize - size

	origin := sp.origin - frame.trimOffset
	origin += (size - origin*2 - 1)*Vec2(cast([2]u8)flip)

	flags:QuadFlags
	if flip.x do flags += {.flipX}
	if flip.y do flags += {.flipY}
	feet, hasFeet := feetPos.?
	if hasFeet do flags += {.verticalShading}

	render_quad(frame.texturePage.texture, spriteFrame_sampler(frame), Quad{
		worldRect = {round(pos - origin - origin/size*sizeDelta), round(newSize)},
		uvRect = spriteFrame_uv(frame, frame.texturePagePos),
		feetPos = feet,
		pivot = round(origin*abs(scale)),
		rotation = angle_to_rads(-angle),
		blend = color_to_blend(color, alpha),
		flags = flags,
	})
}
sprite_draw_ex_f :: proc (sp:^Sprite, x,y:f32, frameIndex:=0, scale:=Vec2{1,1}, angle:f32=0, color:Color=COLOR_WHITE, alpha:f32=1, feetPos:Maybe(Vec2)=nil){
	sprite_draw_ex_vec2(sp, {x,y}, frameIndex, scale, angle, color, alpha, feetPos)
}
sprite_draw_ex :: proc{sprite_draw_ex_f, sprite_draw_ex_vec2}


sprite_draw_part_i :: proc(sp:^Sprite, #any_int x:i32, #any_int y:i32, part:Rect, frameIndex:=0){
	assert(sp != nil, "Trying to draw sprite that was not initialized!")

	frame := &sp.frames[frameIndex]

	srcRect := Rect{frame.texturePagePos.pos + part.pos - frame.trimOffset, part.size}

	render_quad(frame.texturePage.texture, spriteFrame_sampler(frame), Quad{
		worldRect = {{f32(x), f32(y)}, srcRect.size},
		uvRect = spriteFrame_uv(frame, srcRect),
		blend = BLEND_WHITE,
	})
}
sprite_draw_part_vec2 :: #force_inline proc(sp:^Sprite, pos:Vec2, part:Rect, frameIndex := 0){
    sprite_draw_part_i(sp, i32(pos.x), i32(pos.y), part, frameIndex)
}
sprite_draw_part_f :: #force_inline proc(sp:^Sprite, x,y:f32, part:Rect, frameIndex := 0){
    sprite_draw_part_i(sp, i32(x), i32(y), part, frameIndex)
}
/*
Draws part of the sprite. Ignores the sprite's origin and always draws selected part from the top-left.
NOTE: Drawing untrimmed whitespace around the sprite might unintentionally draw other parts of the texture page.
*/
sprite_draw_part :: proc{sprite_draw_part_i, sprite_draw_part_f, sprite_draw_part_vec2}


/*
Draws part of a sprite, stretched to fit into a given destination area.
Ignores the sprite origin, you can provide a custom pivot point (relative to the draw area) for angled draws.
NOTE: Drawing untrimmed whitespace around the sprite might unintentionally draw other parts of the texture page.
*/
sprite_draw_part_ex :: proc(sp:^Sprite, drawArea:Rect, part:Rect, frameIndex:=0, flipConst:=sdl3.FlipMode.NONE, angle:f32=0, color:Color=COLOR_WHITE, alpha:f32=1, pivotPoint:=Vec2{}){
	frame := &sp.frames[frameIndex]

	srcRect := Rect{
		frame.texturePagePos.pos - frame.trimOffset + round(part.pos),
		round(part.size)
	}

	flags:QuadFlags
	if flipConst == .HORIZONTAL do flags += {.flipX}
	if flipConst == .VERTICAL do flags += {.flipY}

	render_quad(frame.texturePage.texture, spriteFrame_sampler(frame), Quad{
		worldRect = {{math.round(drawArea.x), math.round(drawArea.y)}, {math.round(drawArea.size.x), math.round(drawArea.size.y)}},
		uvRect = spriteFrame_uv(frame, srcRect),
		pivot = {math.round(pivotPoint.x), math.round(pivotPoint.y)},
		rotation = angle_to_rads(-angle),
		blend = color_to_blend(color, alpha),
		flags = flags,
	})
}

sprite_draw_rect_f :: proc(sp:^Sprite, x:f32=0, y:f32=0, frameIndex:=0, scale:=Vec2{1,1}) -> Rect{
	flip := [2]int{int(scale.x < 0), int(scale.y < 0)}

	frame := sp.frames[frameIndex]

	//adjust the origin and new sizes for trim
	size := frame.texturePagePos.size
	newSize := size*abs(scale)
	sizeDelta := newSize - size

	origin := sp.origin - frame.trimOffset
	origin.x += (size.x - origin.x*2 - 1)*f32(flip.x)
	origin.y += (size.y - origin.y*2 - 1)*f32(flip.y)

    return Rect{
		{
			round(x - origin.x - origin.x/size.x*sizeDelta.x),
			round(y - origin.y - origin.y/size.y*sizeDelta.y)
		},
		round(newSize)
	}
}
sprite_draw_rect_vec2 :: #force_inline proc(sp:^Sprite, pos:Vec2, frameIndex:=0, scale:=Vec2{1,1}) -> Rect{
	return sprite_draw_rect_f(sp, pos.x, pos.y, frameIndex, scale)
}
//Returns the destination rect a sprite will draw with the given draw settings, adjusting for origin and trim but NOT camera position
sprite_draw_rect :: proc{sprite_draw_rect_f, sprite_draw_rect_vec2}

sprite_draw_pos_f :: #force_inline proc(sp:^Sprite, x:f32=0, y:f32=0, frameIndex:=0, scale:=Vec2{1,1}) -> Vec2{
	return sprite_draw_rect_f(sp, x, y, frameIndex, scale).pos
}
sprite_draw_pos_vec2 :: #force_inline proc(sp:^Sprite, pos:Vec2, frameIndex:=0, scale:=Vec2{1,1}) -> Vec2{
	return sprite_draw_rect_f(sp, pos.x, pos.y, frameIndex, scale).pos
}
//Returns the position a sprite will draw at, adjusting for origin (i.e. the top left position)
sprite_draw_pos :: proc{sprite_draw_pos_f, sprite_draw_pos_vec2}


sprite_duration_f :: proc(sp:^Sprite, timeUnit:=TIME_UNIT_DEFAULT) -> f32{
	msDuration := f32(sp.totalDuration)

	//unnecessary, since duration is cached
	// for f in sp.frames{
	// 	msDuration += f.duration
	// }

	return time_convert(msDuration, TimeUnit.milliseconds, timeUnit)
}
//Returns a sprite's duration in frames. Use sprite_duration_f for custom time unit.
sprite_duration :: proc(sp:^Sprite) -> int{
	return int(sprite_duration_f(sp, .frames))
}

//get a sprite's origin as a vec2
sprite_origin :: proc(spr:^Sprite)->Vec2{
	return Vec2{f32(spr.origin.x), f32(spr.origin.y)}
}

//Gets what the a sprite's frame index is at given time t. 
//If given a negative time value, will use the current time.
//Sprite will loop by default with values of t higher than the duration, you can choose to clamp the value instead to prevent this.
sprite_frame_get :: proc(sp:^Sprite, t:f32=-1, clampT:=false, timeUnit:=TIME_UNIT_DEFAULT) -> int{
	t:=t
	//convert time position to ms time
	if(t < 0) do t = clampT ? 0:f32(time.frame)*time.target_delta
	else{
		#partial switch(timeUnit){
			case .frames:
				t *= time.target_delta
			case .seconds:
				t *= 1000
		}
	}
	
	if t>=sp.totalDuration{
		if clampT do return len(sp.frames)-1
		else if sp.pingPong{
			t = mod(t, sp.totalDuration*2)
			if t >= sp.totalDuration do t = sp.totalDuration*2 - t
		}
		else do t = mod(t, sp.totalDuration)
	}

	for i in 0..<len(sp.frames)-1{
		if(sp.frames[i+1].framePosition > t) do return i
	}
	return len(sp.frames)-1
}

//how long it takes to reach a certain frame in a sprite's animation
sprite_frame_time_get :: proc(sp:^Sprite, frame:int, timeUnit:=TIME_UNIT_DEFAULT) -> f32{
	assertf(frame >= 0 && frame < len(sp.frames), "Frame index '%i' is out of range '%i' on sprite '%s'!", frame, len(sp.frames), sp.name)
	return time_convert(sp.frames[frame].framePosition, TimeUnit.milliseconds, timeUnit)
}

//Returns sp.nil_ if not found
sprite_find :: #force_inline proc (name:string) -> ^Sprite{
	if out, ok := &sprites._sprites_map[name]; ok do return out
	when DEBUG do printf("Warning: Could not find sprite '%s'", name)
	return sp.nil_
}



// sprite_uvs :: proc(sp:^Sprite, frameIndex:=0) -> [4]f32{
// 	frame := &sp.frames[frameIndex]
// 	p1 :Vec2= {frame.texturePagePos.x, frame.texturePagePos.y}
// 	p2 := p1 + {frame.texturePagePos.w, frame.texturePagePos.h}

// 	tsizeI:[2]i32
// 	sdl3.QueryTexture(frame.texture, nil, nil, &tsizeI.x, &tsizeI.y)
// 	tsize := Vec2(tsizeI)
// 	p1 /= tsize
// 	p2 /= tsize
// 	return {p1.x, p1.y, p2.x, p2.y}
// }




