#+feature using-stmt
package massimodin //@nested-tags:_components/

Transform :: struct{
	using base:ComponentBase,
	using coords:TransformCoords, //@e
	scale:Vec2, //@e
	angle:f32, //@e
	attachedCollider:CoRef(Collider) //only gets set if a collider is added
}

TransformCoords :: struct{
	using pos:Vec2,
	z:f32
}

transform_set :: proc(transform:^Transform, newPos:[$N]f32){
	when N >= 1 do transform.x = newPos.x
	when N >= 2 do transform.y = newPos.y
	when N >= 3 do transform.z = newPos.z
	if(transform.attachedCollider._ptr != nil) do _collider_update(transform.attachedCollider)
}

transform_add :: proc(transform:^Transform, amount:[$N]f32){
	newPos:[N]f32 
	when N >= 1 do newPos.x = transform.x + amount.x
	when N >= 2 do newPos.y = transform.y + amount.y
	when N >= 3 do newPos.z = transform.z + amount.z
	transform_set(transform, newPos)
}

transform_set_scale :: proc(transform:^Transform, newScale:Vec2){
	transform.scale = newScale
	if(transform.attachedCollider._ptr != nil) do _collider_update(transform.attachedCollider)
}

_transform_process_event :: proc(base:^ComponentBase, event:Event, overrideDisabled:=false){
if(!overrideDisabled && event in base.disabledEvents) do return
last_context := entities.context_component
defer cowith(last_context)
cowith(base)
self := cast(^Transform)base
using self

#partial switch event{
	case .init:
		scale = {1,1}
		editableFieldsVisible = false
	case .stageStart:
		transform_set(self, pos) //ensure collider position is set properly on room start
	case .editing:
		newPos := transmute(Vec3)coords
		stage_edit_gui_field("Pos", &newPos)
		coords = transmute(TransformCoords)newPos

		if ent,ok:=cofind(StageEntity);ok do stage_edit_gui_field("entity depth offset", &ent.editableDepthOffset)
		
		stage_edit_gui_field("scale", &scale)
		stage_edit_gui_field("angle", &angle)
}
}
	