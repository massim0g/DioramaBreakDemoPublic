#+feature using-stmt
package massimodin //@nested-tags:_components/

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

	depth = layer_depth(.stageBG)+100

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
		blend := color_to_blend(color)
		for inst in layer{ //hot!
			//sprite_draw_ex(inst.sprite, inst.pos, sprite_frame_get(inst.sprite), parallaxScale*inst.flip, color=leafColors[i])

			angle :f32= 0
			flip := inst.flip
			if (flip.x == 1 && flip.y == 1){
				angle = -180
				flip = {0,0}
			}

			frame := &inst.sprite.frames[frameIndex]

			//adjust origin for trim
			size := frame.texturePagePos.size
			newSize := size*scale
			sizeDelta := newSize - size

			origin := inst.sprite.origin - frame.trimOffset
			origin.x += (size.x - origin.x*2 - 1)*f32(flip.x)
			origin.y += (size.y - origin.y*2 - 1)*f32(flip.y)

			flags:QuadFlags
			if flip.x == 1 do flags += {.flipX}
			if flip.y == 1 do flags += {.flipY}

			render_quad(frame.texturePage.texture, spriteFrame_sampler(frame), Quad{
				worldRect = {
					{
						f32(i32(inst.pos.x - origin.x - origin.x/size.x*sizeDelta.x)),
						f32(i32(inst.pos.y - origin.y - origin.y/size.y*sizeDelta.y)),
					},
					{f32(i32(newSize.x)), f32(i32(newSize.y))},
				},
				uvRect = spriteFrame_uv(frame, frame.texturePagePos),
				pivot = {f32(i32(origin.x*scale)), f32(i32(origin.y*scale))},
				rotation = angle_to_rads(angle),
				blend = blend,
				flags = flags,
			})
		}
	}

}}
