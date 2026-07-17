#+feature using-stmt
package massimodin //@nested-tags:_components/

Trigger :: struct{
	using base:ComponentBase,
	stageEntity:CoRef(StageEntity),
	collider:CoRef(Collider),
	dialogueID:^Dialogue, //@e
	dialogueLabel:Estring, //@e
	dialogueIsBlocking:bool, //@e
	cutsceneNamespace:Estring, //@e
	cutsceneID:Estring, //@e
	cutsceneInterruptsDialogue:bool, //@e
	setFlag:Estring, //@e
	enableFlag:Estring, //@e
	disableFlag:Estring, //@e
	autoDestroy:bool //@e
}

trigger_destroyed_flag_make :: proc(using self:^Trigger, allocator:=context.temp_allocator)->string{
	return format("trigger_destroyed_%s_%s", stage.name, stageEntity.uniqueID, allocator=allocator)
}

_trigger_process_event :: proc(base:^ComponentBase, event:Event, overrideDisabled:=false){
if(!overrideDisabled && event in base.disabledEvents) do return
last_context := entities.context_component
defer cowith(last_context)
cowith(base)
self := cast(^Trigger)base
using self
#partial switch event{
case .init:
	stage_mask_init(&stageEntity, sp.trigger)
	estring_set(&stageEntity.group, "triggers")
	coadd(&collider)

	dialogueIsBlocking = true
	autoDestroy = true

	editableFieldsVisible = false

case .loaded:
	stageEntity.componentsVisible = stage_edit.enabled
	collider_mask_set(collider, Vec2{16, 16})
	if !stage_edit.enabled && autoDestroy && flag_check(trigger_destroyed_flag_make(self)) do entity_destroy(self)

case .update: //@p -96
	if(
		!cutscene.enabled && 
		dialogue.current == nil &&
		(enableFlag.s == "" || flag_check(enableFlag.s)) && 
		(disableFlag.s == "" || !flag_check(disableFlag.s)) &&
		collision(collider, collider.transform.pos, Player)
	){
		players := coall(Player)
		for player in players{mover_zero(player.mover)}
		if dialogueID != nil do dialogue_open(dialogueID, dialogueLabel.s, dialogueIsBlocking)
		if cutsceneID.s != ""{
			cutscene_start(cutsceneID.s, cutsceneNamespace.s, cutsceneInterruptsDialogue)
		}
		if setFlag.s != "" do flag(setFlag.s)
		
		if autoDestroy{
			flag(trigger_destroyed_flag_make(self))
			entity_destroy(self)
		}
	}
case .editing:
	@(static) suggestionsInd:int

	stage_edit_gui_field("Dialogue", &dialogueID)
	if dialogueID != nil{
		labels,_ := map_keys(dialogueID.locales[0].labelsMap, context.temp_allocator)
		stage_edit_gui_text_field_with_suggestions("Interact Dialogue Label", &dialogueLabel, labels, &suggestionsInd)
		stage_edit_gui_field("Dialogue Is Blocking", &dialogueIsBlocking)
	}
	
	namespaces,_ := map_keys(cutscene._cutscenes_map, context.temp_allocator)
	stage_edit_gui_text_field_with_suggestions("Cutscene Namespace", &cutsceneNamespace, namespaces, &suggestionsInd)
	if cutsceneNamespace.s != "" && cutsceneNamespace.s in cutscene._cutscenes_map{
		ids,_ := map_keys(cutscene._cutscenes_map[cutsceneNamespace.s], context.temp_allocator)
		stage_edit_gui_text_field_with_suggestions("Cutscene ID", &cutsceneID, ids, &suggestionsInd)
		stage_edit_gui_field("Cutscene Interrupts Dialogue", &cutsceneInterruptsDialogue)
	}

	stage_edit_gui_field("Set Flag", &setFlag)
	stage_edit_gui_field("Enable Flag", &enableFlag)
	stage_edit_gui_field("Disable Flag", &disableFlag)
	stage_edit_gui_field("Auto Destroy", &autoDestroy)
case .clean:
	estring_delete(&dialogueLabel)
	estring_delete(&cutsceneID)
	estring_delete(&cutsceneNamespace)
	estring_delete(&setFlag)
	estring_delete(&enableFlag)
	estring_delete(&disableFlag)
}}
