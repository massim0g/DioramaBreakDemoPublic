package massimodin //@nested-tags:characters

//only call after reloading combat actions and player character passives
_items_reload :: proc(){
	clear(&items.data)

	add :: proc(
		id:string,
		kind:=ItemKind.key,
		icon:^Sprite=nil,
		equipPassivesData:[]struct{name:string,params:[]f32}=nil,
		equipActionNames:[]string=nil,
		paletteIndex:^f32=nil
	){
		pInd:f32 = -1
		if paletteIndex != nil{
			pInd = paletteIndex^
			paletteIndex^ += 1
		}
		equipPassives:= make([]Passive, len(equipPassivesData), assets.allocator)
		for &passive,i in equipPassives{
			passive.info = &player_characters.passives_map[equipPassivesData[i].name]
			copy(passive.params[:], equipPassivesData[i].params)
			assertf(passive.info!=nil, "Unknown passive name '%s' in item definition.", equipPassivesData[i].name)
		}
		equipActions := make([]^CombatAction, len(equipActionNames), assets.allocator)
		for &action,i in equipActions{
			action = &combat.actions[equipActionNames[i]]
			assertf(action!=nil, "Unknown action name '%s' in item definition.", equipActionNames[i])
		}
		items.data[id] = Item{
			id,
			icon == nil ? sp.nil_ : icon,
			kind,
			equipPassives,
			equipActions,
			pInd
		}
	}

	//key items
	add("proHilt")
	add("proBladeFragments")
	add("paper")
	add("stromalInsignia")

	
	{//Pro blades. MAKE SURE THE ORDER OF THESE MATCHES THE ORDER IN THE PALETTE SPRITE!
		bladeInd :f32= 1
		add(
			"prosBlade",
			.blade,
			nil,
			nil,
			{"thrust", "swing"},
			&bladeInd
		)

		add(
			"trainingBlade",
			.blade,
			nil,
			nil,
			{"woodenSwing"},
			&bladeInd
		)

		add(
			"whistlingBlade",
			.blade,
			nil,
			nil,
			{"dashAttack", "airyThrust", "spinAttack"},
			&bladeInd
		)

		add(
			"prosBladeReconstructed",
			.blade,
			nil,
			nil,
			nil, //todo
			&bladeInd
		)
	}

	{//Minima programs.
		add(
			"startingProgram",
			.program,
			nil,
			nil,
			{"minimaSlash", "minimaHelix"}
		)
	}

	{//vests
		add(
			"shirt",
			.vest,
			nil,
			{{"hpUp", {1}}}
		)
		add(
			"irisVest",
			.vest,
			nil,
			{{"hpUp", {3}}}
		)
	}

	{//boots
		add(
			"firstBoots",
			.boots
		)

		add(
			"normalBoots",
			.boots,
			nil,
			nil,
			{"dash"}
		)

		add(
			"springyBoots",
			.boots,
			nil,
		)

		add(
			"windyBoots",
			.boots,
			nil,
			nil,
			{"dodge"}
		)

	}

	{//materials
		add("rareWood", .material)
		add("stringSprout", .material)
	}
}