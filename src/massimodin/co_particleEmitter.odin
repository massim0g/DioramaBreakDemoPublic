#+feature using-stmt
package massimodin //@nested-tags:_components/

ParticleEmitter :: struct{
	using base:ComponentBase,
	type:^ParticleType,
	count:f32, //amount of particles emitted per frame
	region:Rect,
	particleDepth:f32,
	emitCharge:f32,
	relativeToCamera:bool
}

particleEmitter_make :: proc(
	type:^ParticleType,
	count:f32,
	region:Rect,
	particleDepth:f32,
	relativeToCamera:=false
)->^ParticleEmitter{
	out := entity_make(ParticleEmitter)
	out.type = type
	out.count = count
	out.region = region
	out.particleDepth = particleDepth
	out.relativeToCamera = relativeToCamera
	return out
}

_particleEmitter_process_event :: proc(base:^ComponentBase, event:Event, overrideDisabled:=false){
if(!overrideDisabled && event in base.disabledEvents) do return
last_context := entities.context_component
defer cowith(last_context)
cowith(base)
self := cast(^ParticleEmitter)base
using self
#partial switch event{
case .init:
	
case .update:
	if combat.time_stop_mode != .disabled && particleDepth > layer_depth(.ui) do return
	region_ := region
	if relativeToCamera do region_.pos += stage.camera_pos
	emitCharge += count
	emitted := floor(emitCharge)
	if emitted > 0{
		particles_emit(type, int(emitted), particleDepth, region_)
		emitCharge -= emitted
	}
}}
