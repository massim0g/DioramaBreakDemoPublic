#+feature using-stmt
package massimodin //@nested-tags:_components/

StageInteractable :: struct{
	using base:ComponentBase,
	stageEntity:CoRef(StageEntity),
	transform:CoRef(Transform),
	collider:CoRef(Collider),
	interactDialogue:^Dialogue, //@e
	interactDialogueLabel:Estring, //@e
	maxInteractions:int, //@e
	interactDir:Dir, //@e
	interactDirB:Dir, //@e
	maskSprite:^Sprite, //@e
	maskNoSpriteSize:Vec2, //@e
	solid:bool, //@e
	collectableItem:^Item //@e
}


_stageInteractable_process_event :: proc(base:^ComponentBase, event:Event, overrideDisabled:=false){
if(!overrideDisabled && event in base.disabledEvents) do return
last_context := entities.context_component
defer cowith(last_context)
cowith(base)
self := cast(^StageInteractable)base
using self
#partial switch event{
case .init:
	coadd(&stageEntity)
	coadd(&transform)
	coadd(&collider)
	collider.collisionGroups = {.objects}

	maxInteractions = 1 //set to -1 for unlimited interactions
	solid = true
	editableFieldsVisible = false
	interactDir = .none
	interactDirB = .none
case .loaded:
	if(maskSprite != nil) do collider_mask_set(collider, maskSprite)
	else if collider.bounds.size == {0,0} && maskNoSpriteSize != {0,0}{
		originPoint:Vec2
		drawRect:Rect
		spr := stageEntity.spriter.mySprite
		if spr != nil{
			originPoint = sprite_origin(spr)
			drawRect = sprite_draw_rect(spr)
		}

		collider_mask_set(collider, maskNoSpriteSize, Vec2{maskNoSpriteSize.x/2, maskNoSpriteSize.y} + Vec2{drawRect.size.x/2, drawRect.size.y-1} - originPoint)
	}
	else do collider_mask_set_empty(collider)
	
	if !solid do collider.collisionGroups += {.nonSolidInteractables}

	//remove collectables that have already been collected
	if !stage_edit.enabled && collectableItem != nil && stageEntity_persistent_data(stageEntity).interactCount > 0{
		entity_destroy(self)
	}

case .editing:
	stage_edit_gui_field("Interact Dialogue", &interactDialogue)
	if interactDialogue != nil{
		@(static) suggestionsInd:int
		labels,_ := map_keys(interactDialogue.locales[0].labelsMap, context.temp_allocator)
		stage_edit_gui_text_field_with_suggestions("Interact Dialogue Label", &interactDialogueLabel, labels, &suggestionsInd)
	}

	stage_edit_gui_field("Max Interactions", &maxInteractions)
	stage_edit_gui_field("Interact Direction A", &interactDir)
	if interactDir != .none do stage_edit_gui_field("Interact Direction B", &interactDirB)
	stage_edit_gui_field("Mask Sprite", &maskSprite)
	if maskSprite == nil do stage_edit_gui_field("Mask No Sprite Size", &maskNoSpriteSize)
	stage_edit_gui_field("Solid", &solid)
	stage_edit_gui_field("Collectable Item", &collectableItem)

case .clean:
	estring_delete(&interactDialogueLabel)
	
}}
