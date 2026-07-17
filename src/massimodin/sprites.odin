package massimodin //@nested-tags:engine/sprites

import "../sdl2"
import "core:math/linalg"
import "core:math"


SpriteSystem :: struct{
	//all texture page and sprite info is loaded into memory on startup by asset unpacker
	_texture_groups_map:map[string]TextureGroup,
	_sprites_map:map[string]Sprite,
	names:[dynamic]string,
	_sprite_nil:Sprite,
	_spriteFrame_nil:SpriteFrame,
	_texture_page_nil:^sdl2.Texture,
	_texture_page_surface_nil:^sdl2.Surface,
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

	sprites._texture_page_nil = sdl2.CreateTexture(display._renderer, u32(sdl2.PixelFormatEnum.ABGR8888), sdl2.TextureAccess.STATIC, 1, 1)
	sprites._texture_page_surface_nil = sdl2.CreateRGBSurfaceWithFormat(0, 1, 1, 32, u32(sdl2.PixelFormatEnum.ABGR8888))
	sprites._spriteFrame_nil = SpriteFrame{
		sprites._texture_page_nil,
		sprites._texture_page_surface_nil,
		sdl2.Rect{0,0,1,1},
		sdl2.Point{0,0},
		20,
		0,
	}

	sprites._sprite_nil = Sprite{
		make([dynamic]SpriteFrame, 1, assets.allocator),
		"nil",
		nil,
		20,
		{1, 1},
		sdl2.Point{0,0},
		false
	}
	sp.nil_ = &sprites._sprite_nil
	sp.nil_.frames[0] = sprites._spriteFrame_nil
}

SpriteFrame :: struct{
    texturePage:^sdl2.Texture,
    texturePageSurface:^sdl2.Surface,
    texturePagePos:sdl2.Rect,
	trimOffset:sdl2.Point,
    duration:f32, //in ms
	framePosition:f32 //also in ms
}

Sprite :: struct{
    frames:[dynamic]SpriteFrame,
	name:string,
	mask:^ColliderMask,
	totalDuration:f32, //in ms
	size:Vec2,
	origin:sdl2.Point,
	pingPong:bool
}

TextureGroup :: struct{
	pages:[dynamic]TexturePage,
	name:string,
	loadState:TexturePageLoadState,
	isHD:bool
}

TexturePage :: struct{
	using texture:^sdl2.Texture,
	surface:^sdl2.Surface,
	
	//set these at startup while reading the index
	spriteFrames:[]^SpriteFrame,
	loadAllocator:Allocator, //freed when page is unloaded
	loadTempAllocator:Allocator, //freed when page is done loading
	size:i32,

	textureRowsLoaded:i32
}

sprite_page_size :: proc(s:^Sprite, frameInd:=0) -> Vec2{
	surf := s.frames[frameInd].texturePageSurface
	return Vec2{f32(surf.w), f32(surf.h)}
}

sprite_draw_i :: proc "contextless" (sp:^Sprite, #any_int x:i32, #any_int y:i32, frameIndex:=0){
	assert_contextless(sp != nil, "Trying to draw nil sprite!")

    //frame := sp.frames[i64(math.wrap(f32(frameIndex), f32(len(sp.frames))))]
	frame := sp.frames[frameIndex]
    destRect := frame.texturePagePos //copy the source width and height
    destRect.x = x + frame.trimOffset.x - sp.origin.x
    destRect.y = y + frame.trimOffset.y - sp.origin.y
	destRect.x -= camera.pos.x
	destRect.y -= camera.pos.y

	sdl2.SetTextureColorMod(frame.texturePage, 255, 255, 255)
	sdl2.SetTextureAlphaMod(frame.texturePage, 255)
	sdl2.SetTextureBlendMode(frame.texturePage, .BLEND)
    sdl2.RenderCopy(display._renderer, frame.texturePage, &frame.texturePagePos, &destRect)
}
sprite_draw_vec2 :: #force_inline proc "contextless" (sp:^Sprite, pos:Vec2, frameIndex := 0){
    sprite_draw_i(sp, i32(pos.x), i32(pos.y), frameIndex)
}
sprite_draw_f :: #force_inline proc "contextless" (sp:^Sprite, x,y:f32, frameIndex := 0){
    sprite_draw_i(sp, i32(x), i32(y), frameIndex)
}
sprite_draw :: proc{sprite_draw_i, sprite_draw_f, sprite_draw_vec2}


sprite_draw_ex_f :: proc "contextless" (sp:^Sprite, x,y:f32, frameIndex:=0, scale:=Vec2{1,1}, angle:f32=0, color:Color=COLOR_WHITE, alpha:f32=1, blendmode:=BlendMode.blend){
	assert_contextless(sp != nil, "Trying to draw nil sprite!")

	angle := angle
	flip := [2]int{int(scale.x < 0), int(scale.y < 0)}
	if (flip.x == 1 && flip.y == 1){
		angle += 180
		flip = {0,0}
	}
	flipConst := sdl2.RendererFlip(flip.x + flip.y*2)

	frame := sp.frames[frameIndex]

	//convert origin and new sizes to f32 for transformation and adjust for trim
	size := Vec2{f32(frame.texturePagePos.w), f32(frame.texturePagePos.h)}
	newSize := size*abs(scale)
	sizeDelta := newSize - size

	origin := Vec2{f32(sp.origin.x - frame.trimOffset.x), f32(sp.origin.y - frame.trimOffset.y)}
	origin.x += (size.x - origin.x*2 - 1)*f32(flip.x)
	origin.y += (size.y - origin.y*2 - 1)*f32(flip.y)

    destRect := sdl2.Rect{
		i32(math.round(x - origin.x - origin.x/size.x*sizeDelta.x)) - camera.pos.x,
    	i32(math.round(y - origin.y - origin.y/size.y*sizeDelta.y)) - camera.pos.y,
		i32(math.round(newSize.x)),
		i32(math.round(newSize.y))
	}

	pivot := sdl2.Point{i32(math.round(origin.x*abs(scale.x))), i32(math.round(origin.y*abs(scale.y)))}
	
	sdl2.SetTextureColorMod(frame.texturePage, color.r, color.g, color.b)
	sdl2.SetTextureAlphaMod(frame.texturePage, u8(clamp(alpha*255, 0, 255)))
	sdl2.SetTextureBlendMode(frame.texturePage, display.custom_blendmodes[blendmode])
	sdl2.RenderCopyEx(display._renderer, frame.texturePage, &frame.texturePagePos, &destRect, f64(-angle), &pivot, flipConst)
}
sprite_draw_ex_vec2 :: #force_inline proc "contextless" (sp:^Sprite, pos:Vec2, frameIndex:=0, scale:=Vec2{1,1}, angle:f32=0, color:Color=COLOR_WHITE, alpha:f32=1, blendmode:=BlendMode.blend){
	sprite_draw_ex_f(sp, pos.x, pos.y, frameIndex, scale, angle, color, alpha, blendmode)
}
sprite_draw_ex :: proc{sprite_draw_ex_f, sprite_draw_ex_vec2}


sprite_draw_part_i :: proc(sp:^Sprite, #any_int x:i32, #any_int y:i32, part:Rect, frameIndex:=0){
	assert(sp != nil, "Trying to draw sprite that was not initialized!")

	frame := sp.frames[frameIndex]

	srcRect := frame.texturePagePos
	srcRect.x += i32(part.x) - frame.trimOffset.x
	srcRect.y += i32(part.y) - frame.trimOffset.y
	srcRect.w = i32(part.size.x)
	srcRect.h = i32(part.size.y)

    destRect := srcRect
    destRect.x = x - camera.pos.x
    destRect.y = y - camera.pos.y

	sdl2.SetTextureColorMod(frame.texturePage, 255, 255, 255)
	sdl2.SetTextureAlphaMod(frame.texturePage, 255)
	sdl2.SetTextureBlendMode(frame.texturePage, .BLEND)
    sdl2.RenderCopy(display._renderer, frame.texturePage, &srcRect, &destRect)
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
sprite_draw_part_ex :: proc(sp:^Sprite, drawArea:Rect, part:Rect, frameIndex:=0, flipConst:=sdl2.RendererFlip.NONE, angle:f32=0, color:Color=COLOR_WHITE, alpha:f32=1, blendmode:=BlendMode.blend, pivotPoint:=Vec2{}){
	frame := sp.frames[frameIndex]

	srcRect := sdl2.Rect{
		frame.texturePagePos.x + i32(math.round(part.x)) - frame.trimOffset.x,
		frame.texturePagePos.y + i32(math.round(part.y)) - frame.trimOffset.y,
		i32(math.round(part.size.x)),
		i32(math.round(part.size.y))
	}

	destRect := sdl2.Rect{
		i32(math.round(drawArea.x)) - camera.pos.x,
    	i32(math.round(drawArea.y)) - camera.pos.y,
		i32(math.round(drawArea.size.x)),
		i32(math.round(drawArea.size.y))
	}


	pivot := sdl2.Point{i32(math.round(pivotPoint.x)), i32(math.round(pivotPoint.y))}
	
	sdl2.SetTextureColorMod(frame.texturePage, color.r, color.g, color.b)
	sdl2.SetTextureAlphaMod(frame.texturePage, u8(clamp(alpha*255, 0, 255)))
	sdl2.SetTextureBlendMode(frame.texturePage, display.custom_blendmodes[blendmode])
	sdl2.RenderCopyEx(display._renderer, frame.texturePage, &srcRect, &destRect, f64(-angle), &pivot, flipConst)
}

sprite_draw_rect_f :: proc(sp:^Sprite, x:f32=0, y:f32=0, frameIndex:=0, scale:=Vec2{1,1}) -> Rect{
	flip := [2]int{int(scale.x < 0), int(scale.y < 0)}

	frame := sp.frames[frameIndex]

	//convert origin and new sizes to f32 for transformation and adjust for trim
	size := Vec2{f32(frame.texturePagePos.w), f32(frame.texturePagePos.h)}
	newSize := size*abs(scale)
	sizeDelta := newSize - size

	origin := Vec2{f32(sp.origin.x - frame.trimOffset.x), f32(sp.origin.y - frame.trimOffset.y)}
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
// 	sdl2.QueryTexture(frame.texture, nil, nil, &tsizeI.x, &tsizeI.y)
// 	tsize := Vec2(tsizeI)
// 	p1 /= tsize
// 	p2 /= tsize
// 	return {p1.x, p1.y, p2.x, p2.y}
// }




