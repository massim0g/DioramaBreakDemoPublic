#+feature using-stmt
package massimodin //@nested-tags:_components/

Fader :: struct{
	using base:ComponentBase,
	stageEntity:CoRef(StageEntity),
	faderCollider:CoRef(Collider),
	fadeCondition:FadeCondition, //@e
	maskSprite:^Sprite, //@e
	affectedGroup:Estring //@e
}

FadeCondition :: enum{
	cameraIsHigherThanTop,
	playerMeeting
}

_fader_process_event :: proc(base:^ComponentBase, event:Event, overrideDisabled:=false){
if(!overrideDisabled && event in base.disabledEvents) do return
last_context := entities.context_component
defer cowith(last_context)
cowith(base)
self := cast(^Fader)base
using self
#partial switch event{
case .init:
	coadd(&stageEntity)
	coadd(&faderCollider, true)

case .loaded:
	collider_mask_set(faderCollider, maskSprite)
case .update:
	fade:=false
	switch fadeCondition{
		case .cameraIsHigherThanTop:
			dr := stageEntity_draw_rect(stageEntity)
			if stage.camera_pos.y <= dr.y-28 do fade = true
		case .playerMeeting: 
			fade = collision(faderCollider, stageEntity.transform.pos, Player)
	}
	
	ents := []^StageEntity{stageEntity._ptr}
	if affectedGroup.s != "" do ents = stageEntity_group_get(affectedGroup.s)
	
	targetAlpha :f32= fade?0:1
	for ent in ents{
		ent.alpha = approach(ent.alpha, targetAlpha, 1./24.)
	}

case .clean:
	estring_delete(&affectedGroup)
	
}}
