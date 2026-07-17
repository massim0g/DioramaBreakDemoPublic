#+feature using-stmt
package massimodin //@nested-tags:_components/

Block :: struct{
	using base:ComponentBase,
}

_block_process_event :: proc(base:^ComponentBase, event:Event, overrideDisabled:=false){
if(!overrideDisabled && event in base.disabledEvents) do return
last_context := entities.context_component
defer cowith(last_context)
cowith(base)
self := cast(^Block)base
using self
#partial switch event{
case .init:
	coadd(StageInteractable)
	
case .loaded:
	inter := cofind(StageInteractable)
	inter.stageEntity.componentsVisible = stage_edit.enabled
}}
