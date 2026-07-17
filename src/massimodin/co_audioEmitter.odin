#+feature using-stmt
package massimodin //@nested-tags:_components/

AudioEmitter :: struct{
	using base:ComponentBase,
	transform:CoRef(Transform),
	instances:[dynamic]AudioEmitterInstance
}

AudioEmitterInstance :: struct{
	using inst:AudioInstance, 
	offset:TransformCoords
}

audioEmitter_play :: proc(using emitter:^AudioEmitter, event:AudioEvent, offset:=TransformCoords{}) -> AudioInstance{
	inst := audio_play_at(event, transform.pos + offset.pos, transform.z + offset.z)
	append(&instances, AudioEmitterInstance{inst, offset})
	return inst
}

_audioEmitter_process_event :: proc(base:^ComponentBase, event:Event, overrideDisabled:=false){
if(!overrideDisabled && event in base.disabledEvents) do return
last_context := entities.context_component
defer cowith(last_context)
cowith(base)
self := cast(^AudioEmitter)base
using self
#partial switch event{
case .init:
	coadd(&transform)
	init(&instances)
case .update:
	#reverse for instance,i in instances{
		if !audio_playing(instance){
			unordered_remove(&instances, i)
			continue
		}

		audio_pos_set(instance, transform.pos + instance.offset.pos, transform.z + instance.offset.z)
	}
case .clean:
	for instance in instances{
		if audio_playing(instance) do audio_stop(instance)
	}
	delete(instances)
}}
