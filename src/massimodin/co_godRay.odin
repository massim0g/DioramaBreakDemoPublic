#+feature using-stmt
package massimodin //@nested-tags:_components/

import "../sdl3"

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
	camRect := stage_camera_rect()
	//check visibility. Also, god ray rendering is a bit expensive, so do a culling check.
	visible = rayEnabled && stageEntity.componentsVisible && (
		rect_intersects(camRect, {drawVertices[0], drawVertices[3]}) ||
		rect_intersects(camRect, {drawVertices[0], drawVertices[4]}) ||
		rect_intersects(camRect, {drawVertices[3], drawVertices[4]}) ||
		(beamWidthAtSource > 0 && rect_intersects(camRect, {drawVertices[1], drawVertices[2]}))
	)

case .draw:
	camPos := stage_camera_pos()
	shader_set(Sh_Base)
	tex_target_set(stage.shadow_layer, camPos)
		
		corners:[5]Vertex
		for &v, i in corners{
			v.blend = BLEND_WHITE
			v.pos = drawVertices[i]
		}

		if beamFadeOutStartOffset < beamEndOffset{
			corners[3].blend.a = 0
			corners[4].blend.a = 0
		}

		//the fan was indexed, the mesh path takes a flat triangle list
		verts := [9]Vertex{
			corners[0], corners[1], corners[2],
			corners[1], corners[3], corners[4],
			corners[1], corners[4], corners[2],
		}
		draw_mesh_blank(verts[:])

		blendmode_set(.subtract)
		if stageEntity.invertShadowMargin > 0{
			drawRect := stageEntity_draw_rect(stageEntity)
			tex_draw(stageEntity.invertShadowTex, drawRect.pos)
		}
		else{
			sprite_draw_ex(
				spriter.mySprite, stageEntity_draw_pos(stageEntity), spriter.lastFrame,
				transform.scale, transform.angle, COLOR_WHITE, 1
			)
		}
		blendmode_set(.blend)
	tex_target_reset()

	destination := display_snapshot()
	shader_set(Sh_ShadowLayer)
	shader_texture_bind("destination", destination)
	tex_draw_ex(stage.shadow_layer, camPos)
	shader_reset(2)

}}
