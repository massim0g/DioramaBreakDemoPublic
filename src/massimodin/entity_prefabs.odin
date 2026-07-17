package massimodin //@nested-tags:_components/prefabs

@(disabled=!DEBUG)
_reload_entity_prefabs :: proc(){
	clear(&entities.prefabs)
	add_with_create :: proc($T:typeid, previewSprite:^Sprite, name:string, onCreate:proc(^T)){
		name:=name
		if name == "" do name = entities.component_type_metadata[coid_of(T)].name
		wrapper :: proc(co:^ComponentBase, p:rawptr){
			p := cast(proc(^T))p
			p(cast(^T)co)
		}
		append(&entities.prefabs, EntityPrefab{
			coid_of(T),
			previewSprite,
			name,
			rawptr(onCreate),
			wrapper
		})
	}
	add_no_create :: proc($T:typeid, previewSprite:^Sprite, name:=""){
		name:=name
		if name == "" do name = entities.component_type_metadata[coid_of(T)].name
		append(&entities.prefabs, EntityPrefab{
			coid_of(T),
			previewSprite,
			name,
			nil, nil
		})
	}
	add :: proc{add_no_create, add_with_create}

	add(Player, sp.pro_overworld_idle_side)
	//add(CombatUnit, sp.slimeIdle_loop)
	add(Enemy, sp.ranger_combat_idle_side_loop, "enemy", proc(enemy:^Enemy){
		estring_set(&enemy.stageCharacter.initID, "ranger")
		enemy.stageCharacter.useCombatSpritesInOverworld = true
		stageCharacter_reload(enemy.stageCharacter)
	})
	add(CombatBounds, sp.combatBounds)
	add(Foliage, sp.foliage)
	add(Block, sp.block, "block", proc(block:^Block){
		cofind(block, StageInteractable).maskSprite = sp.block
	})
	add(Block, sp.slopeBlock, "slope block", proc(block:^Block){
		cofind(block, StageInteractable).maskSprite = sp.slopeBlock
	})
	add(Trigger, sp.trigger)
	add(Warp, sp.warp)
	add(Fader, sp.wallShort)
	add(StageEntity, sp.stageNode, "stage node", proc(ent:^StageEntity){
		ent.resizable = false
		ent.displayID = true
		ent.debugVisibleOnly = true
		ent.editableDepthOffset = -10000
		estring_set(&ent.uniqueID, "new_node")
		estring_set(&ent.group, "nodes")
	})
	add(BlobFoliage, sp.blobFoliage)
	add(StageEntity, sp.leaves01, "shadow", proc(ent:^StageEntity){
		ent.shadowKind = .isShadow
		estring_set(&ent.group, "shadows")
	})
	add(GodRay, sp.leaves01)
	add(StageCharacter, sp.minima_overworld_idle_side, "stage character", proc(sc:^StageCharacter){
		estring_set(&sc.initID, "minima")
		stageCharacter_reload(sc)
	})
	add(StageInteractable, sp.interactableMask, "interactable mask", proc(si:^StageInteractable){
		last_context := entities.context_component
		defer cowith(last_context)
		cowith(si)
		stage_mask_init(&si.stageEntity, sp.interactableMask)
		si.maskSprite = sp.interactableMask
		si.solid = false
	})
	add(StageInteractable, sp.interactableMaskSlope, "interactable mask slope", proc(si:^StageInteractable){
		last_context := entities.context_component
		defer cowith(last_context)
		cowith(si)
		stage_mask_init(&si.stageEntity, sp.interactableMaskSlope)
		si.maskSprite = sp.interactableMaskSlope
		si.solid = false
	})
	add(CheckpointRadius, sp.checkpointRadiusNode, "checkpoint radius", proc(cr:^CheckpointRadius){
		cr.stageEntity.debugVisibleOnly = true
	})
	add(PulseLight, sp.circle16)

	add(StageInteractable, sp.collectableShine, "collectable", proc(si:^StageInteractable){
		si.maskSprite = sp.collectableShine
	})
}