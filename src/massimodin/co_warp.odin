#+feature using-stmt
package massimodin //@nested-tags:_components/

Warp :: struct{
	using base:ComponentBase,
	stageEntity:CoRef(StageEntity),
	collider:CoRef(Collider),
	targetStage:^Stage, //@e
	targetPos:Vec2, //@e
	enableFlag:Estring, //@e
	disableFlag:Estring //@e
}

_warp_process_event :: proc(base:^ComponentBase, event:Event, overrideDisabled:=false){
if(!overrideDisabled && event in base.disabledEvents) do return
last_context := entities.context_component
defer cowith(last_context)
cowith(base)
self := cast(^Warp)base
using self
#partial switch event{
case .init:
	stage_mask_init(&stageEntity, sp.warp)
	estring_set(&stageEntity.group, "warps")
	coadd(&collider)

case .loaded:
	stageEntity.componentsVisible = stage_edit.enabled
	collider_mask_set(collider, Vec2{16, 16})

case .clean:
	estring_delete(&enableFlag)
	estring_delete(&disableFlag)
}}
