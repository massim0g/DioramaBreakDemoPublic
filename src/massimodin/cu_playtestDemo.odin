package massimodin //@nested-tags:cutscenes

playtest_spawn :: proc(id:string){
	unit := entity_make(CombatUnit)
	estring_set(&unit.initID, id, true)
	combatUnit_reload(unit)
	unit.stageEntity.transform.pos = {576, 224} 
	_entities_destruction_process()
	_entities_just_made_process()
	combat_start(au.battleTutorial)
}
_cutscenes_reload_playtest :: proc(){ //DEPRECATED
	m := &cutscene._cutscenes_map["_default"]
	m["explodeEnemy"] = proc()->bool{
		units := combatUnits_get()
		for unit in units{
			if unit.unitType == .enemy{
				spriteEffect_make(sp.crappyExplosion, unit.stageEntity.transform.pos)
				entity_destroy(unit)
			}
		}
		return true
	}
	m["startChion"] = proc()->bool{
		playtest_spawn("chion")
		return true
	}
	m["startKion"] = proc()->bool{
		playtest_spawn("kion")
		return true
	}
	m["startAkro"] = proc()->bool{
		playtest_spawn("akro")
		return true
	}
	m["startPolema"] = proc()->bool{
		playtest_spawn("polema")
		return true
	}

	m["playtestReset"] = proc() -> bool{
		handler := cofind(PlaytestDemo, 0)
		units := combatUnits_get()
		for unit in units{
			spriteEffect_make(sp.crappyExplosion, unit.stageEntity.transform.pos)
			entity_destroy(unit)
		}
		p := entity_make(Player)
		p.transform.pos = Vec2{368, 224}
		//playtest_spawn(playtest_combat_labels[handler.phase])
		return true
	}

	m["playtestEnd"] = proc()->bool{
		if seq_open(){
			if seq_time()%10 == 0{
				spriteEffect_make(sp.crappyExplosion, Vec2{random_range(stage.bounds.pos.x, rect_get_right(stage.bounds)), random_range(stage.bounds.pos.y, rect_get_bottom(stage.bounds))})
			}
			
			if seq_cue(50){
				game_quit()	
			}
		}
		return seq_close()
	}

	m["resetDemo"] = proc()->bool{
		playtest_demo_reset("reset")
		return true
	}
}