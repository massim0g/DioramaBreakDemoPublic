#+feature using-stmt
package massimodin //@nested-tags:_components/

CombatBounds :: struct{
	using base:ComponentBase,
	stageEntity:CoRef(StageEntity)
}

_combatBounds_process_event :: proc(base:^ComponentBase, event:Event, overrideDisabled:=false){
if(!overrideDisabled && event in base.disabledEvents) do return
last_context := entities.context_component
defer cowith(last_context)
cowith(base)
self := cast(^CombatBounds)base
using self
#partial switch event{
case .init:
	stage_mask_init(&stageEntity, sp.combatBounds)

case .loaded:
	stage.combatBounds = stageEntity_draw_rect(stageEntity)
	
}}
