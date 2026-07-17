#+feature using-stmt
package massimodin //@nested-tags:_components/

import "core:math/noise"
PulseLight :: struct{
	using base:ComponentBase,
	stageEntity:CoRef(StageEntity),
	baseRadii:Vec2, //@e
	pulseFactor:f32, //@e
	pulseRangeFactor:f32 //@e
}

pulseLight_shadow_draw :: proc(ent:^StageEntity){
	self :^PulseLight= cofind(ent, PulseLight)
	using self
	radii := baseRadii*remap(noise.noise_2d(0, {f64(time.frame)*f64(pulseFactor), 0}), -1,1, 1/pulseRangeFactor, pulseRangeFactor)

	draw_ellipse(ent.transform.pos, radii, innerAlpha=0.6, outerAlpha=0.6)
	draw_ellipse(ent.transform.pos, radii*0.8)
	//sprite_draw_ex(sp.circle256, ent.transform.pos, 0, 1./256.*radii*2)
}

_pulseLight_process_event :: proc(base:^ComponentBase, event:Event, overrideDisabled:=false){
if(!overrideDisabled && event in base.disabledEvents) do return
last_context := entities.context_component
defer cowith(last_context)
cowith(base)
self := cast(^PulseLight)base
using self
#partial switch event{
case .init:
	coadd(&stageEntity)
	stageEntity.shadowKind = .isLight
	stageEntity.shadowDraw = pulseLight_shadow_draw

	baseRadii = Vec2{32, 16.}
	pulseFactor = 1
	pulseRangeFactor = 1.1

case .codeReload:
	stageEntity.shadowDraw = pulseLight_shadow_draw
}}
