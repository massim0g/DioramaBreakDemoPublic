#+feature using-stmt
package massimodin //@nested-tags:_components/

CheckpointRadius :: struct{
	using base:RenderComponentBase,
	stageEntity:CoRef(StageEntity),
	transform:CoRef(Transform),
	radii:Vec2, //@e
	playerInRange:Maybe(bool)
}

_checkpointRadius_process_event :: proc(base:^ComponentBase, event:Event, overrideDisabled:=false){
if(!overrideDisabled && event in base.disabledEvents) do return
last_context := entities.context_component
defer cowith(last_context)
cowith(base)
self := cast(^CheckpointRadius)base
using self
#partial switch event{
case .init:
	coadd(&stageEntity)
	coadd(&transform)
	radii = 100
	playerInRange = nil
case .update:
	last := playerInRange
	if p,ok := cofind(Player,0); ok do playerInRange = ellipse_contains(Ellipse{transform.pos, radii}, p.transform.pos)
	else do playerInRange = false

	if last != nil && playerInRange != last{
		game_save()
	}

case .drawEditor:
	draw_rings(transform.pos, {radii, radii-2, radii-2, 0}, {COLOR_GREEN, COLOR_GREEN, COLOR_GREEN, COLOR_GREEN}, {1,1,0,0})

}}
