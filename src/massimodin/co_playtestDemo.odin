#+feature using-stmt
package massimodin //@nested-tags:_components/

import "core:reflect"
PlaytestDemo :: struct{
	using base:ComponentBase,
	phase:int
}

playtest_phase_names := []string{"reset", "chion", "kion", "akro", "trainees", "polema"}

playtest_demo_reset :: proc(phaseName:string){
	flags_clear(.temp)
	if phaseName == "reset"{
		flags_clear(.global)
		if !entity_exists(TitleScreen) do titleScreen_goto()
		return
	}
	stage_load(st.newCargoLiftTest)

	pro := entity_make(Player).stageCharacter
	pro.transform.pos = {476, 281}
	scface(pro, .up)
	scmake("chion", 	{609, 184}, .left)
	scmake("kion", 		{634, 185}, .left)
	scmake("akro", 		{634, 228}, .left)
	scmake("polema", 	{471, 151}, .down)
	
	_entities_just_made_process()

	if phaseName == "kion" do player_character_equip(.pro, "trainingBlade")
	else do player_character_equip(.pro, "prosBlade")
	
	phaseName_ := string_clone(phaseName)
	proc_call_delayed(callback_make(proc(phaseName:^string){
		dialogue_open(di.combatTutorial, format("%sFightStart", phaseName^))
		delete(phaseName^)
	}, phaseName_), 1)
}

// playtest_demo_start :: proc(){
// 	stage_goto(st.newCargoLiftTest)

// 	proc_call_delayed(proc(){
// 		entity_make(PlaytestDemo)
// 		p := entity_make(Player)
// 		p.transform.pos = Vec2{368, 224}
		
// 		_entities_just_made_process()

// 		dialogue_open(di.playtestDemo)
// 	}, 1)
// }

_playtestDemo_process_event :: proc(base:^ComponentBase, event:Event, overrideDisabled:=false){
if(!overrideDisabled && event in base.disabledEvents) do return
last_context := entities.context_component
defer cowith(last_context)
cowith(base)
self := cast(^PlaytestDemo)base
using self
#partial switch event{
case .init:
	phase = -1
case .update:
	// if combat.phase != .planning || dialogue.current != nil do return

	// playerIsDead := false
	// enemiesAreDead := true

	// units := combatUnits_get()

	// for unit in units{
	// 	switch unit.unitType{
	// 		case .player: if unit.unitState != .alive do playerIsDead = true
	// 		case .enemy: if unit.unitState == .alive do enemiesAreDead = false
	// 		case .ally: //unreachable
	// 	}
	// }

	// if playerIsDead{
	// 	combat_end()
	// 	dialogue_open(di.playtestDemo, "failure")
	// }
	// else if enemiesAreDead{
	// 	if phase >= len(playtest_combat_labels)-1{
	// 		combat_end()
	// 		dialogue_open(di.playtestDemo, "end")
	// 	}
	// 	else{
	// 		combat_end()
	// 		phase+=1
	// 		dialogue_open(di.playtestDemo, playtest_combat_labels[phase])
	// 	}
	// }

}}
