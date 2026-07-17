#+feature using-stmt
package massimodin //@nested-tags:_components/

TrailParticle :: struct{
	using base:RenderComponentBase,
	spriter:CoRef(Spriter),
	baseAlpha:f32,
	drawPos:Vec2,
	scale:Vec2,
	angle:f32,
	duration:f32,
	age:f32,
	lerpColors:[2]Color
}

trailParticle_make :: proc(spr:^Sprite, pos:Vec2, depth:f32=0, duration:f32=1, frame:=0, animSpeed:f32=0, scale:=Vec2{1,1}, angle:f32=0, startColor:Color=COLOR_BLACK, endColor:Color=COLOR_WHITE, baseAlpha:f32=1) -> ^TrailParticle{
	out := entity_make(TrailParticle)
	spriter_set(out.spriter, spr, frame)
	out.spriter.animSpeed = animSpeed
	out.drawPos = pos
	out.depth = depth
	out.scale = scale
	out.angle = angle
	out.lerpColors = {startColor, endColor}
	out.baseAlpha = baseAlpha
	out.duration = duration
	return out
}

_trailParticle_process_event :: proc(base:^ComponentBase, event:Event, overrideDisabled:=false){
if(!overrideDisabled && event in base.disabledEvents) do return
last_context := entities.context_component
defer cowith(last_context)
cowith(base)
self := cast(^TrailParticle)base
using self
#partial switch event{
case .init:
	coadd(&spriter)
	scale = 1
case .update:
	age += 1
	if age > duration do entity_destroy(self)
case .draw:
	prog := age/duration
	drawAlpha := 1 - prog
	shader_set(sh.colorOnly) //custom shader for these?
	sprite_draw_ex(
		spriter.mySprite, drawPos, spriter.lastFrame, 
		scale, angle, color_lerp(lerpColors[0], lerpColors[1], prog), drawAlpha*baseAlpha
	)
	shader_reset()
}}
