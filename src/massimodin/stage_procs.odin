#+feature using-stmt
package massimodin //@nested-tags:stages

_reload_stage_procs :: proc(){
	//st.cargoLiftTest.init = stage_preset_stroma

	//stroma
		elevatorSwordCheck :: proc(){
			if holder := stageEntity_find("stromaMiddleSwordHolder"); holder != nil && flag_check("equippedElevatorSword") do spriter_set(holder.spriter, sp.swordHolder_empty)
			if flag_check("combatTutorialFailed") do spriter_set(stageEntity_find("polemaSwordRack").spriter, sp.polemaSwordWeaponRack_noSword)
		}

		st.prosRoom.init = stage_preset_stroma
		st.prosHouseUpstairsHallway.init = stage_preset_stroma
		st.prosHouseUpstairsHallway.update = proc(){
			if !flag_check("introDone") && !player_dummy(){
				player,ok := cofind(Player, 0)
				if !ok do return
				turned := player.stageCharacter.facing != .left
				if turned || player.transform.x < 240{
					dialogue_open(di.intro, "interference")
					if turned do flag("turnedInHallway", level=.local)
				}
			}
		}
		st.prosHouseLivingRoom.init = proc(){
			stage_preset_stroma()
			if flag_check("spokeToMom") && !flag_check("combatTutorialFailed"){
				salvia := scmake("salvia", {288, 456}, .up)
				salvia.stageInteractable.interactDialogue = di.stromaVillage
				estring_set(&salvia.stageInteractable.interactDialogueLabel, "salviaInteract")
			}
		}
		st.prosNeighbourhood.init = stage_preset_stroma
		st.townCenter.init = stage_preset_stroma
		st.sidePlatform.init = proc(){
			stage_preset_stroma()
			oiko := scfind("oiko")
			spriter_set_callbacks(oiko.spriter, {{sp.oiko_overworld_idle_up, 3, proc(){
				oiko := scfind("oiko")
				audio_play_at(au.oikoSmithing, oiko.transform.pos, -20)
			}}})
		}
		st.MainTrunk.init = proc(){
			stage_preset_stroma()
			if flag_check("sprinklerCutsceneDone"){
				if !flag_check("spokeToArb"){
					arb := scmake("arb", {687,206}, .left)
					arb.facePlayer = .ifInteractedWith
					arb.facingMode = .sideOnly //todo: arb up sprite
					{using arb.stageInteractable
						interactDialogue = di.stromaVillage
						estring_set(&interactDialogueLabel, "arbInteract")
					}
				}
				stageEntity_set_visible(stageEntity_find("stromaSprinklerExtended"), false)
			}
			else{
				stageEntity_set_visible(stageEntity_find("stromaSprinklerRetracted"), false)
				stageEntity_group_set_visible("hinokiSitting", false)
			}
			dialogue_expression_parse("playerPassedThroughStromaMainTrunk+=1")
			if flag_get("playerPassedThroughStromaMainTrunk") == "3"{
				flag("stromaPlayerIsLost")
			}
		}
		st.upperPlatform.init = proc(){
			stage_preset_stroma()
			dummy := entity_make(CombatUnit)
			transform_set(dummy.stageEntity.transform, Vec2{792, 612})
			estring_set(&dummy.stageCharacter.initID, "trainingDummy")
			inter :^StageInteractable= cofind(dummy, StageInteractable)
			inter.interactDialogue = di.stromaVillage
			estring_set(&inter.interactDialogueLabel, "trainingDummy")
			inter.maxInteractions = -1
			stageCharacter_reload(dummy.stageCharacter)
			stageCharacter_sprite_set(dummy.stageCharacter, sp.trainingDummy)
			spritesSlice :[]^Sprite = (cast([^]^Sprite)(&dummy.stageCharacter.sprites))[:size_of(StageCharacterSpriteSet)/size_of(^Sprite)]
			for &spr in spritesSlice{
				spr = sp.trainingDummy
			}
		}
		st.foliageExperiment.init = stage_preset_stroma
		st.newCargoLiftTest.init = proc(){
			stage_preset_stroma()
			elevatorSwordCheck()
		}
		st.lowerArea.init = proc(){
			stage_preset_stroma()
			elevatorSwordCheck()
		}
		st.townHall.init = proc(){
			if flag_check("introDone"){
				audio_background_stop()
				food := stageEntity_group_get("food")
				for ent in food do entity_destroy(ent)
			}
		}
		st.artisansHouse.init = proc(){
			stage_preset_stroma()

			flora := scmake("flora", {358, 507}, .left, facingMode=.sideOnly)
			flora.facePlayer = .ifInteractedWith
			{using flora.stageInteractable
				interactDialogue = di.stromaVillage
				estring_set(&interactDialogueLabel, "flora")
				maxInteractions = -1
			}
			
			if flag_check("spokeToFlora"){
				transform_set(flora.transform, Vec2{223, 447})
			}
			else{
				wanderer := coadd(flora, Wanderer)
				wanderer.lockAxes.y = true
			}
		}
		st.mayorsHouse.init = stage_preset_stroma
		st.mayorsOffice.init = stage_preset_stroma
		st.architectsHouse.init = proc(){
			stage_preset_stroma()
			if flag_check("sprinklerCutsceneDone"){
				scmake("trabe", {516,507})
				scmake("edif", {552,507}, .left)
			}
		}
		st.library.init = proc(){
			stage_preset_stroma()
			if flag_check("sprinklerCutsceneDone"){
				scmake("phyllo", {303, 396}, .left)
				xylo := stageEntity_group_get("xyloLadder")
				for ent in xylo{ entity_destroy(ent) }
			}
			else{
				scmake("libra", {303, 396}, facingMode=.sideOnly)
			}
		}
		st.libraryPlatform.init = proc(){
			stage_preset_stroma()
			if flag_check("sprinklerCutsceneDone"){
				entity_destroy(scfind("edif"))
			}
		}

		
	//iris
		st.IrisForestEntrance.init = proc(){
			elevatorSwordCheck()
			audio_background_set({au.stromaAmbienceWind}) //quieter?
			music_set(nil)
			if flag_check("combatTutorialDone"){
				elevator := stageEntity_group_get("elevator")
				for ent in elevator{
					entity_destroy(ent)
				}
			}
		}
		st.IrisForestFirstMonsterEncounter.init = proc(){
			//if !flag_check("firstMonsterDefeated") && !stage_edit.enabled do scmake("ranger", {45,270}, .down)
			stage_preset_iris()

			texture_group_unload("stroma") //player is far enough away from the forest entrance that this is an opportune place to unload the stroma textures

			if !flag_check("firstMonsterDefeated"){
				firstMonsterUnit := entity_make(CombatUnit)
				firstMonsterUnit.skipStartAnim = true
				firstMonster := firstMonsterUnit.stageCharacter
				transform_set(firstMonster.transform, Vec2{248, 221})
				estring_set(&firstMonster.initID, "ranger")
				stageCharacter_reload(firstMonster)
				scface(firstMonster, .down)
				stageCharacter_sprite_set(firstMonster, sp.ranger_combat_idle_down_ready)
			}
		}

		st.IrisForestArena.init = stage_preset_iris
		st.IrisForestArena.onCombatStart = proc(){
			if !flag_check("minimaCommentedOnCombat"){
				combat_event_callback_add(proc(self:^CombatEventCallback, event:CombatEventData){
					if e,ok:=event.(CombatEventEnded); ok{
						dialogue_open(di.minimaEncounter, "afterNextCombat")
					}
				})
			}
		}
		st.IrisForestEdge.init = proc(){
			music_set(nil)
			audio_background_set({au.irisEdgeAmbience})
		}
		st.IrisForestHiddenGrove.init = proc(){
			stage_preset_iris()
			music_set(nil)
		}
		st.IrisForestDeepShrine.init = stage_preset_iris
		st.IrisForestBackDoor.init = stage_preset_iris
		st.IrisForestCorridorHorizontal.init = stage_preset_iris
		st.IrisForestCorridorVertical.init = stage_preset_iris
		st.IrisForestEdgeShrine.init = proc(){
			flag("secondShrineReached")
			stage_preset_iris()
		}
		st.IrisForestExit.init = stage_preset_iris
		st.IrisForestHub.init = stage_preset_iris
		st.IrisForestHub2.init = stage_preset_iris
		st.IrisForestMinimaEncounter.init = stage_preset_iris
		st.IrisForestSecondMonsterEncounter.init = stage_preset_iris
		st.IrisForestSecretClearing.init = stage_preset_iris
		st.IrisForestSecretDitch.init = stage_preset_iris
		st.IrisForestSecretTurn.init = stage_preset_iris
		st.IrisForestSideHub.init = stage_preset_iris
}

stage_preset_stroma :: proc(){
	flag("safeZone", "1")

	audioBG := make([dynamic]AudioEvent, context.temp_allocator)
	if (flag_check("introDone") || audio_playing(au.stromaVillage)) && !equals(stage.loaded, st.lowerArea, st.newCargoLiftTest){
		music_set(au.stromaVillage)
		audio_parameter_set(audio.music, "idle", f32(int(stage.indoors)))
	}
	else do music_set(nil)

	if flag_check("introDone") && !equals(stage.loaded, st.lowerArea, st.newCargoLiftTest, st.prosRoom){
		proc_call_delayed(proc(){game_save()}, 2) //ensure save is triggered after warp ends
	}

	if !stage.indoors{

		//audio
		append(&audioBG, au.stromaAmbience)
		append(&audioBG, au.stromaAmbienceWind)
		//stage.backgroundColor = color_hex(0xf7eec5)

		//Foliage
		if flag_check("scrollingBackgroundFoliage"){
			ents := coall(StageEntity)
			for &ent in ents{
				#partial switch ent.shadowKind{case .isLight, .isShadow: entity_destroy(&ent)}
			}
			entity_make(ScrollingFoliage)
		}
		else{
			layerLimit:=99
			area := rect_area(stage.bounds)
			if area > 1_000_000 || settings.performance_mode == .potato do layerLimit = 1
			else if area > 300_000 || settings.performance_mode == .reduced do layerLimit = 2
			branchDensity :f32= (layerLimit<99)?3:4 //per screen
			baseParallax :f32: 1
			foliageLayers:[3]^Foliage
			stageExtraSize := stage.bounds.size-DISPLAY_SIZE
	
			leafColors := [3]Color{
				color_hex(0x19342a),
				color_hex(0x334240),
				color_hex(0x436057)
				//color_hex(0x96ca0f)
			}
	
			cullingArea := Rect{}
	
			switch stage.loaded{
				case st.lowerArea: cullingArea = rectf_make_points(240,108,888,332)
				case st.townCenter: cullingArea = rectf_make_points(200,250,1115,800)
			}
	
			for &layer,i in foliageLayers{
				if i >= layerLimit do break
				layer = entity_make(Foliage)
				layer.cullingArea = cullingArea
	
				parallaxScale := 1/pow(FOLIAGE_PARALLAX_EXPONENT_BASE, f32(i))
				stageSizeAdjusted := stageExtraSize*parallaxScale*baseParallax + DISPLAY_SIZE
				extraBoundsSize := stageSizeAdjusted - stage.bounds.size
				stageAreaAdjusted := stageSizeAdjusted.x*stageSizeAdjusted.y
				branchCount := roundi(stageAreaAdjusted/DISPLAY_AREA*branchDensity/parallaxScale)
				layer.minBranches = branchCount
				layer.maxBranches = branchCount
	
				layer.parallaxAmount = 1 - parallaxScale*baseParallax
				layer.branchBaseScale = parallaxScale
				layer.branchSizeDecayFactor = 0.5
				layer.branchMaxDecay = 4
				layer.branchDecayChance = 1./5.
				layer.leafSprite = sp.bgLeafRound
				layer.branchSegmentMinLength =  26
				layer.branchSegmentMaxLength =  64
				layer.leafScaleMin=0.14
				layer.leafScaleMax=0.27
				layer.leafScaleMin *= parallaxScale  
				layer.leafScaleMax *= parallaxScale 
				layer.leafColor = leafColors[i]
				layer.branchColor = leafColors[i]
				layer.branchesVisible = true
	
				layer.stageEntity.transform.pos = stage.bounds.pos - extraBoundsSize/2
				layer.stageEntity.transform.scale = stageSizeAdjusted/16
				layer.stageEntity.depthKind = .floor
				layer.stageEntity.editableDepthOffset = 10000+f32(i)
				layer.stageEntity.visible = false
	
				foliage_regenerate_branches(layer)
			}
		}

		//Falling Leaves
		@(static) fallingLeaf:^ParticleType
		if fallingLeaf == nil{
			fallingLeaf = particle_type(
				[]^Sprite{sp.fallingLeaf_twisting, sp.fallingLeaf_twisting, sp.fallingLeaf_twisting, sp.fallingLeaf_spinning},
				1000, 1000, 1.95, 2.5, dir=331, dirSpread=12 
			)
		}
		leafCount :: 0.000033 //per pixel of emitter
		size := stage.bounds.size
		sizeTotal := size.x+size.y
		particleEmitter_make(fallingLeaf, leafCount*size.x, Rect{stage.bounds.pos + {0,-1}, {size.x, 1}}, -DEPTH_MAX+2)
		particleEmitter_make(fallingLeaf, leafCount*size.y, Rect{stage.bounds.pos + {-1,0}, {1, size.y}}, -DEPTH_MAX+2)
		particles_emit(fallingLeaf, roundi(0.000023*size.x*size.y), -DEPTH_MAX+2, stage.bounds)
		
		// append(&stage.render_depth_list_static_entries, DepthListEntry{
		// 	DEPTH_MAX + 99,
		// 	DepthListEntryCallback{proc(){
		// 		shader_set(sh.leaves)
		// 		shader_uniform_set(sh.leaves, "lightColor", stage.backgroundColor)
		// 		display_redraw()
		// 		shader_reset()
		// 	}}
		// })
	}
	else{
		append(&audioBG, au.stromaIndoorAmbience)
	}
	audio_background_set(events=audioBG[:])
}

stage_preset_iris :: proc(){
	flag("safeZone", "0")

	music_set(au.fieldIris)
	audio_parameter_set(audio.music, "inIrisIntro", string_to_f32(flag_get("inIrisIntro")))

	audioBG := make([dynamic]AudioEvent, context.temp_allocator)
	append(&audioBG, au.irisAmbience)

	audio_background_set(events=audioBG[:])
}