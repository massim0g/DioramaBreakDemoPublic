#+feature using-stmt
package massimodin //@nested-tags:_components/

import "../sdl2"

ScrollingFoliage :: struct{
	using base:RenderComponentBase,
	layers:[3][dynamic]ScrollingFoliageInstance,
	scrollSpeed:Vec2, //with no parallax
}

ScrollingFoliageInstance :: struct{
	sprite:^Sprite,
	pos:Vec2,
	flip:[2]u8
}

_scrollingFoliage_process_event :: proc(base:^ComponentBase, event:Event, overrideDisabled:=false){
if(!overrideDisabled && event in base.disabledEvents) do return
last_context := entities.context_component
defer cowith(last_context)
cowith(base)
self := cast(^ScrollingFoliage)base
using self
#partial switch event{
case .init:
	for &layer in layers{
		init(&layer, stage.allocator)
	}

	scrollSpeed = {0, -2}

	depth = DEPTH_MAX+100

	for n in 0..<200{ //populate foliage
		component_event_process(self, .update)
	}

case .update:
	instancesPerFrame := [3]f32{
		0.5,
		0.7,
		1.6,
	}

	camRect := stage_camera_rect()
	spawnY := scrollSpeed.y > 0 ? 0:rect_get_bottom(camRect)
	for &layer,i in layers{
		parallaxScale := 1/pow(FOLIAGE_PARALLAX_EXPONENT_BASE, f32(i))
		#reverse for &inst,j in layer{
			inst.pos += scrollSpeed*parallaxScale

			if !in_range(inst.pos.y, -inst.sprite.size.y, rect_get_bottom(camRect) + inst.sprite.size.y) do unordered_remove(&layer, j)
		}

		ipf, ipfFrac := split(instancesPerFrame[i])
		if roll(ipfFrac) do ipf += 1
		for n in 0..<ipf{
			spr := foliage_system.blob_sprites[random_range(3,BLOB_FOLIAGE_TYPE_COUNT-1)]
			append(&layer, ScrollingFoliageInstance{
				spr,
				Vec2{random_range(camRect.x, rect_get_right(camRect)), spawnY+spr.size.y/2*-sign(scrollSpeed.y)},
				{u8(random_i(2)), u8(random_i(2))}
			})
		}
	}

case .draw:

	leafColors := [3]Color{
		color_hex(0x19342a),
		color_hex(0x334240),
		color_hex(0x436057)
	}
	frameIndex := sprite_frame_get(foliage_system.blob_sprites[0])
	#reverse for layer,i in layers{
		scale := 1/pow(FOLIAGE_PARALLAX_EXPONENT_BASE, f32(i))
		color := leafColors[i]
		sdl2.SetTextureColorMod(foliage_system.blobs_texture_page, color.r, color.g, color.b)
		for inst in layer{ //hot!
			//sprite_draw_ex(inst.sprite, inst.pos, sprite_frame_get(inst.sprite), parallaxScale*inst.flip, color=leafColors[i])

			angle :f64= 0
			flip := inst.flip
			if (flip.x == 1 && flip.y == 1){
				angle = -180
				flip = {0,0}
			}
			flipConst := sdl2.RendererFlip(flip.x + flip.y*2)

			frame := inst.sprite.frames[frameIndex]

			//convert origin and new sizes to f32 for transformation and adjust for trim
			size := Vec2{f32(frame.texturePagePos.w), f32(frame.texturePagePos.h)}
			newSize := size*scale
			sizeDelta := newSize - size

			origin := Vec2{f32(inst.sprite.origin.x - frame.trimOffset.x), f32(inst.sprite.origin.y - frame.trimOffset.y)}
			origin.x += (size.x - origin.x*2 - 1)*f32(flip.x)
			origin.y += (size.y - origin.y*2 - 1)*f32(flip.y)

			destRect := sdl2.Rect{
				i32(inst.pos.x - origin.x - origin.x/size.x*sizeDelta.x) - camera.pos.x,
				i32(inst.pos.y - origin.y - origin.y/size.y*sizeDelta.y) - camera.pos.y,
				i32(newSize.x),
				i32(newSize.y)
			}

			pivot := sdl2.Point{i32(origin.x*scale), i32(origin.y*scale)}
			
			sdl2.RenderCopyEx(display._renderer, frame.texturePage, &frame.texturePagePos, &destRect, angle, &pivot, flipConst)
		}
	}

}}
