#+feature using-stmt
package massimodin //@nested-tags:_components/

UnitDissolveEffect :: struct{
	using base:RenderComponentBase,
	transform:CoRef(Transform),
	sprite:^Sprite,
	drawTex:Tex
}

unitDissolveEffect_make :: proc(pos:Vec2, sprite:^Sprite, scale:Vec2) -> ^UnitDissolveEffect{
	out := entity_make(UnitDissolveEffect)
	audio_play(au.enemyDeath)
	transform_set(out.transform, pos)
	out.transform.scale = scale
	out.sprite = sprite
	out.depth = -out.transform.y
	tex_resize(&out.drawTex, out.sprite.size)
	return out
}

_unitDissolveEffect_process_event :: proc(base:^ComponentBase, event:Event, overrideDisabled:=false){
if(!overrideDisabled && event in base.disabledEvents) do return
last_context := entities.context_component
defer cowith(last_context)
cowith(base)
self := cast(^UnitDissolveEffect)base
using self

fadeDarkDur :: 12
dissolveDur :: 28

#partial switch event{
case .init:
	coadd(&transform)

case .update:
	seq_open(&baseBase)
	t:= fadeDarkDur+dissolveDur+3
	if seq_cue(t){
		particles_emit(particle_type(
			sp.circle16, 
			minLifetime=12, maxLifetime=36, 
			minSpeed=0.5, maxSpeed=1, acceleration=0.05,
			minScale=0.4, maxScale=0.5, scaleCurves=cu.easeOut_inv,
			colors=COLOR_BLACK,
			angleSpread=0, dir=90, dirSpread=10, 
		), 20, depth.(f32), sprite_draw_rect(sprite, transform.pos, len(sprite.frames)-1, transform.scale))
	}
	if seq_cue(t+40) do entity_destroy(self)
	seq_close(.pause)

case .draw:
	drawFrame := len(sprite.frames)-1
	texPos := transform.pos - sprite_origin(sprite)

	seq_open(&baseBase)

	tex_target_set(drawTex, texPos)
		baseCol := seq_time() >= fadeDarkDur+dissolveDur ? COLOR_WHITE:COLOR_BLACK
		shader_set(sh.colorOnly)
		sprite_draw_ex(sprite, transform.pos, drawFrame, transform.scale, color=baseCol)
		shader_reset()
		dr := sprite_draw_rect(sprite, transform.pos, drawFrame, transform.scale)
		sprite_draw_ex(sp.circle16, rect_center(dr), 0, 0.5, color=255-baseCol)
	tex_target_reset()
	
	t:=0
	if seq_cue(&t, fadeDarkDur){
		sprite_draw_ex(sprite, transform.pos, drawFrame, transform.scale)
		tex_draw_ex(drawTex, texPos, alpha=seq_map(0, 1))
	}

	if seq_cue(&t, dissolveDur){
		randSpread := seq_map(0, 5)
		tex_draw(drawTex, texPos)
		for n in 0..<6{
			tex_draw_ex(drawTex, texPos+vec2_random()*random_range(0, randSpread), alpha=1./6.)
		}
	}
	
	if seq_cue(&t, 1){
		tex_draw(drawTex, texPos)
	}

	seq_close()

case .clean:
	tex_destroy(drawTex)

}}
