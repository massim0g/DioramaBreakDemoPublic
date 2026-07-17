#+feature using-stmt
package massimodin //@nested-tags:_components/

DamageEffect :: struct{
	using base:ComponentBase,
	textEffect:CoRef(TextEffect),
	damage:int
}

//pass a negative value to represent healing
damageEffect_make :: proc(damage:int, pos:Vec2) -> ^DamageEffect{
	te := textEffect_make("", pos, -40, 100 + random_f(10), COLOR_WHITE, 1, fo.yal6w4__16, 0, EffectMovementCurves{{0,0,-16}, cu.popInStrong}, dropShadow=COLOR_BLACK)
	de := component_add(te.entity, DamageEffect)
	te.stageEntity.ignoreTimeStop = true

	de.damage = damage

	return de
}

_damageEffect_process_event :: proc(base:^ComponentBase, event:Event, overrideDisabled:=false){
if(!overrideDisabled && event in base.disabledEvents) do return
last_context := entities.context_component
defer cowith(last_context)
cowith(base)
self := cast(^DamageEffect)base
using self
#partial switch event{
case .init:
	coadd(&textEffect)
case .update:
	dur := int(textEffect.duration)
	blend := &textEffect.stageEntity.blendData
	seq_open(imkey_combine(&base))
		scrollDur := clamp(damage*2, 25, 40)
		if seq_cue(0, scrollDur){
			displayedDamage := -roundi(seq_map(0, f32(damage)))
			textEffect_set(textEffect, format("%+i", displayedDamage))
			blend.color = color_hex(0x7f3429)
		}
		if seq_cue(scrollDur, scrollDur+30){
			blend.color = color_lerp(color_hex(0xff602b), color_hex(0xcc2d20), seq.cue_prog, cu.easeIn)
		}
		if seq_cue(dur-30, dur){
			blend.alpha = (seq_time()%4<2)?1:0
		}
		if seq_cue(dur){
			seq_close(.end)
			entity_destroy(self)
			return
		}
	seq_close()
}}
