#+feature using-stmt
package massimodin //@nested-tags:_components/

import "../sdl2"

GodRay :: struct{
	using base:RenderComponentBase,
	stageEntity:CoRef(StageEntity),
	transform:CoRef(Transform),
	spriter:CoRef(Spriter),
	sourcePoint:Vec2, //@e
	beamWidth:f32, //@e
	beamWidthAtSource:f32, //@e
	beamOffset:Vec2, //@e
	beamFadeOutStartOffset:f32, //@e
	beamEndOffset:f32, //@e
	rayEnabled:bool, //@e
	drawVertices:[5]Vec2
}

godRay_update_vertices :: proc(using self:^GodRay){
	drawVertices[1] = Vec2{transform.x-beamWidth/2, transform.y} + beamOffset
	drawVertices[2] = Vec2{transform.x+beamWidth/2, transform.y} + beamOffset
	sourceLeft := Vec2{sourcePoint.x-beamWidthAtSource/2, sourcePoint.y}
	sourceRight := Vec2{sourcePoint.x+beamWidthAtSource/2, sourcePoint.y}
	trueSourcePoint,ok := lines_intersection(Line{drawVertices[1], sourceLeft}, Line{drawVertices[2], sourceRight})
	if !ok do trueSourcePoint = sourcePoint
	drawVertices[0] = trueSourcePoint
	drawVertices[3] = drawVertices[1]
	drawVertices[4] = drawVertices[2]
	drawVertices[1] = vec2_approach(drawVertices[1], trueSourcePoint, -beamFadeOutStartOffset)
	drawVertices[2] = vec2_approach(drawVertices[2], trueSourcePoint, -beamFadeOutStartOffset)
	drawVertices[3] = vec2_approach(drawVertices[3], trueSourcePoint, -beamEndOffset)
	drawVertices[4] = vec2_approach(drawVertices[4], trueSourcePoint, -beamEndOffset)
}

_godRay_process_event :: proc(base:^ComponentBase, event:Event, overrideDisabled:=false){
if(!overrideDisabled && event in base.disabledEvents) do return
last_context := entities.context_component
defer cowith(last_context)
cowith(base)
self := cast(^GodRay)base
using self
#partial switch event{
case .init:
	coadd(&stageEntity)
	coadd(&transform)
	coadd(&spriter)
	estring_set(&stageEntity.group, "god_rays")
	stageEntity.shadowKind = .isLight
	rayEnabled = true

case .loaded:
	if beamWidth == 0{
		beamWidth = stageEntity_draw_rect(stageEntity).size.x
	}

	godRay_update_vertices(self)

case .updateEditor:
	godRay_update_vertices(self)

case .preDraw:
	depth = stageEntity.depth
	visible = rayEnabled && stageEntity.componentsVisible
	
case .draw:
	camPos := stage_camera_pos()
	tex_target_set(stage.shadow_layer, camPos)
		shader_set(shaders._base_shader)
		
		vertices:[5]sdl2.Vertex
		for &v, i in vertices{
			v.color = sdl2.Color{255,255,255,255}
			v.position = transmute(sdl2.FPoint)(drawVertices[i] - camPos)
		}

		if beamFadeOutStartOffset < beamEndOffset{
			vertices[3].color.a = 0
			vertices[4].color.a = 0
		}

		indices := [9]i32{
			0, 1, 2,
			1, 3, 4,
			1, 4, 2,
		}

		sdl2.RenderGeometry(display._renderer, nil, &vertices[0], 5, &indices[0], 9)
		if stageEntity.invertShadowMargin > 0{
			drawRect := stageEntity_draw_rect(stageEntity)
			tex_blendmode_set(stageEntity.invertShadowTex, .subtract)
			tex_draw(stageEntity.invertShadowTex, drawRect.pos)
			tex_blendmode_set(stageEntity.invertShadowTex, .blend)
		}
		else{
			sprite_draw_ex(
				spriter.mySprite, stageEntity_draw_pos(stageEntity), spriter.lastFrame,
				transform.scale, transform.angle, COLOR_WHITE, 1, BlendMode.subtract
			)
			sdl2.SetTextureBlendMode(spriter_frame_get_ptr(spriter).texturePage, .BLEND) //otherwises messes with precise-depth entities 
		}
	tex_target_reset()

	destination := display_main_tex_inactive()
	shader_set(sh.shadowLayer)
	shader_texture_bind(sh.shadowLayer, "destination", destination)
	defer shader_texture_unbind(destination)
	tex_draw_ex(stage.shadow_layer, camPos)
	shader_reset()
	shader_reset()

}}
