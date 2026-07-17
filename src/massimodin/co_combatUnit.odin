#+feature using-stmt
package massimodin //@nested-tags:_components/
//@nested-tags:combat/

import "core:reflect"

CombatUnit :: struct{
	using base:RenderComponentBase,

	//refs
	combatEntity:CoRef(CombatEntity),
	stageCharacter:CoRef(StageCharacter),
	stageEntity:CoRef(StageEntity),

	//
	maxHp:int, 
	hp:int,
	lastHp:int,
	walkSpeed:int,
	unitType:CombatUnitType,
	defense:[CombatDamageKind]int,
	initiative:u8, //lower goes first
	initID:Estring, //@e
	lastInitID:string, //for stage editor
	queuedActions:[dynamic; COMBAT_RESOLVE_INTERVAL]CombatActionQueued,
	stunCounter:int,
	equippedActions:[dynamic; COMBAT_UNIT_MAX_EQUIPPED_ACTIONS]^CombatAction,
	combos:[dynamic; 4][dynamic; 4]^CombatAction,
	unitState:CombatUnitState,
	sprites:CombatUnitSpriteSet,
	ghostPositions:[]Vec2i,
	ghostDrawData:[]CombatUnitGhostDrawData,
	ghostBaseDrawData:CombatUnitGhostDrawData,
	targetPreference:CombatUnitAITargetPreference,
	reactionTime:int,
	reactAfterBreak:bool, //whether unit reacts immediately after being attacked
	predictiveTargeting:bool, //unit will target where the opponent will be, not where they are when the attack is queued
	bumped:bool,
	audioEvents:CombatUnitAudioSet,
	actionPreviewPinned:bool,
	dissolveOnKo:bool,
	skipStartAnim:bool,
	skipEndAnim:bool,
	forceCombatGridEntry:bool,
	drawAttackWarningLevel:int,
	drawAttackWarningMovementAimMarkers:[dynamic; COMBAT_RESOLVE_INTERVAL]CombatMarker
}

COMBAT_UNIT_MAX_EQUIPPED_ACTIONS :: 16


//unit types always resolve in the order laid out here
CombatUnitType :: enum{
	player,
	ally,
	enemy
}
CombatUnitTypes :: bit_set[CombatUnitType]

CombatUnitState :: enum{
	alive,
	knockedOut,
	dead
}

CombatUnitAITargetPreference :: enum{
	nearest,
	lowestMaxHP,
	weakestNearby
}

CombatUnitSpriteSet :: struct{
	idle:DirSpriteSet,
	idleToReady:DirSpriteSet,
	ready:DirSpriteSet,
	walk:DirSpriteSet,
	actionToStun:DirSpriteSet,
	actionToIdle:DirSpriteSet,
	stun:^Sprite,
	stunToIdle:^Sprite,
	hurt:^Sprite,
	hurtToStun:^Sprite,
	koStart:^Sprite,
	ko:^Sprite,
	koGetup:^Sprite,
	combatStart:^Sprite,
	combatEnd:^Sprite,
	timelinePortrait:^Sprite
}

CombatUnitAudioSet :: struct{
	combatStart:AudioEvent
}

CombatUnitTypePalette :: struct{
	light:Color,
	dark:Color,
}
CombatUnitHPPalette :: struct{
	dark:Color,
	darkSecondary:Color,
	middle:Color,
	light:Color,
	highlight:Color
}
CombatUnitHPPalettes :: struct{
	high:CombatUnitHPPalette,
	middle:CombatUnitHPPalette,
	low:CombatUnitHPPalette
}

CombatUnitGhostDrawData :: struct{
	pos:Vec2,
	caq:^CombatActionQueued,
	dir:Dir
}

COMBAT_UNIT_TYPE_PALETTES :: [CombatUnitType]CombatUnitTypePalette{
	.player = {
		Color{0x8d, 0xc3, 0x78},
		Color{0x44, 0x79, 0x5f},
	},
	.ally = {
		Color{0x8d, 0xc3, 0x78},
		Color{0x44, 0x79, 0x5f},
	},
	.enemy = {
		Color{0xc0, 0x54, 0x39},
		Color{0x80, 0x3c, 0x31},
	}
}

COMBAT_UNIT_HP_PALETTES :: CombatUnitHPPalettes{
	{
		Color{0x35, 0x39, 0x4a},
		Color{0x35, 0x39, 0x4a},
		Color{0x44, 0x79, 0x5f},
		Color{0x8d, 0xc3, 0x78},
		Color{0xff, 0xe7, 0xb8},
	},
	{
		Color{0x2c, 0x24, 0x30},
		Color{0x47, 0x24, 0x1f},
		Color{0x47, 0x24, 0x1f},
		Color{0xda, 0xad, 0x5d},
		Color{0xe9, 0xc1, 0x90},
	},
	{
		Color{0x2c, 0x24, 0x30},
		Color{0x47, 0x24, 0x1f},
		Color{0x80, 0x3c, 0x31},
		Color{0xe1, 0x41, 0x41},
		Color{0xe1, 0x41, 0x41},
	},

}

//Called on combat start, if the unit's id matches a valid player id sets its combat actions based on that character's equipped actions
combatUnit_player_actions_set :: proc(using self:^CombatUnit){
	id,ok := player_character_string_to_id(initID.s)
	if ok do set(&equippedActions, newVal=player_character_actions(id))
}


combatUnit_AI_plan_actions :: proc(using self:^CombatUnit){
	if unitType == .player do return

	attackWithCombo :: proc(using self:^CombatUnit, action:^CombatAction, aimPos:=Vec2i{}){
		
		for &combo in combos{
			if action == combo[0]{
				for comboAction in combo{
					if combatUnit_action_queue_full(self) do break
					combatAction_enqueue(self, comboAction, aimPos)
				}
				return
			}
		}

		combatAction_enqueue(self, action, aimPos)
	}

	opposingTypes := unitType == .enemy ? CombatUnitTypes{.player, .ally} : CombatUnitTypes{.enemy}

	if reactionTime > 0 && combat.phase == .planning{
		lockedStep := combat.current_step + reactionTime
		#reverse for &caq in queuedActions{
			if combatActionQueued_start_step(&caq) >= lockedStep do pop(&queuedActions)
			else do break
		}
	}
	else do combatUnit_queued_actions_clear(self)

	combat_event_process(CombatEventAIPlanningStart{self})
	
	for !combatUnit_action_queue_full(self){
		currentRect := Recti{combatUnit_ghost_position(self), combatEntity.rect.size}
		currentStep := combatUnit_queued_action_tail(self)
		reactionStep := currentStep
		if reactionTime >= 0 do reactionStep += 1 - reactionTime
		attackedBy := combat_attackers_get(self, currentRect, currentStep, false, opposingTypes)

		if len(attackedBy) > 0{ //Unit is attacked, defend or evade
			if len(attackedBy) == 1{ //try to counter attacker with faster attack
				attackingAction := attackedBy[0]
				attackerTriggerStep := combatActionQueued_trigger_step(attackingAction)
				attackerRect := Recti{attackingAction.userPosOnUsage, attackingAction.user.combatEntity.rect.size}
				attackerDistance := recti_manhattan_distance(combatEntity.rect, attackerRect)
				slowestFasterAction:^CombatAction
				for action in equippedActions{
					if(
						action.kind == .attack &&
						(slowestFasterAction == nil || slowestFasterAction.startup < action.startup) &&
						currentStep + action.startup < attackerTriggerStep &&
						attackerDistance <= combatAction_effective_range(action))
					{
						slowestFasterAction = action
					}
				}
				if slowestFasterAction != nil{
					waitSteps := combatActionQueued_start_step(attackingAction) - slowestFasterAction.startup - currentStep - 1
					for n in 0..<waitSteps{
						combatAction_enqueue(self, ca.wait, Vec2i{})
					}
					attackWithCombo(self, slowestFasterAction, rect_center(attackerRect))
					return
				}
			}

			//must evade or defend
			nearestSafeSpace := combat_nearest_safe_space(self, currentRect.pos, currentStep, opposingTypes) //in theory this could be made faster if it itself stored and returned a path
			if nearestSafeSpace == {-1,-1} do return //give up, nowhere is safe. This shouldn't usually happen
			distanceToSafeSpace := len(combat_pathfind(combatEntity, Recti{nearestSafeSpace, {1,1}}, false, currentRect.pos))
			
			fastestAttackingAction:^CombatActionQueued
			attackedStep:int
			for action in attackedBy{
				triggerStep := combatActionQueued_trigger_step(action)
				if fastestAttackingAction == nil || triggerStep < attackedStep{
					fastestAttackingAction = action
					attackedStep = triggerStep
				}
			}

			timeUntilAttack := attackedStep - currentStep

			if distanceToSafeSpace <= walkSpeed*timeUntilAttack{ //walk out of the way of the attack
				combatAction_enqueue(self, ca.movement, nearestSafeSpace)
				continue
			}

			//evasion action
			for action in equippedActions{
				if(
					action.kind == .evasion &&
					currentStep + action.startup < attackedStep &&
					distanceToSafeSpace <= combatAction_effective_range(action))
				{
					combatAction_enqueue(self, action, nearestSafeSpace)
					continue
				}
			}

			//can't abscond, bro!

			//try defensive action
			for action in equippedActions{
				if(
					action.kind == .defense &&
					currentStep + action.startup < attackedStep)
				{
					waitAmount := timeUntilAttack - action.startup - 1
					for _ in 0..<waitAmount{
						combatAction_enqueue(self, ca.wait, currentRect.pos)
					}
					combatAction_enqueue(self, action, currentRect.pos)
					return
				}
			}

			//move away from attacker
			if walkSpeed == 0 do return
			combatAction_enqueue(self, ca.movement, nearestSafeSpace)
			continue //todo: make continuing (retaliatory) or returning (purely passive/evasive) here a parameter? 
		}
		else{ //Unit is safe, try to attack opponents

			attackInfo :: struct{
				attack:^CombatAction,
				unitsInRange:[]^CombatUnit
			}
			validAttacksInfo := make([dynamic]attackInfo, context.temp_allocator)
			validTargets := make([dynamic]^CombatUnit, context.temp_allocator)

			for action, i in equippedActions{
				if action.kind != .attack do continue

				unitsInRange := combatAction_units_in_range(action, reactionStep, self, currentRect.pos, reactionTime >= 0 ? 0.5:1, opposingTypes)
				if len(unitsInRange) > 0{
					append(&validAttacksInfo, attackInfo{action, unitsInRange})
					append_elems(&validTargets, args=unitsInRange)
				}
			}

			if len(validAttacksInfo) == 0{ //move towards target
				if walkSpeed == 0 do return

				moveTarget:^CombatUnit
				switch targetPreference{
					case .nearest: moveTarget = combatUnit_nearest(rect_center(currentRect), -1, opposingTypes, self)
					case .lowestMaxHP:	//todo
					case .weakestNearby: //todo
				}

				if moveTarget == nil do return //no valid targets on the map, do nothing

				path := combat_pathfind(combatEntity, combatUnit_ghost_rect(moveTarget), false, currentRect.pos)

				foundPath := false
				for i:=min(len(path)-1, walkSpeed-1); i>=0; i-=1{
					pathRect := Recti{path[i], combatEntity.rect.size}
					if len(combat_attackers_get(self, pathRect, reactionStep, false, opposingTypes)) == 0 &&
						len(combat_collision_unit_ghosts(pathRect, ignore=self)) == 0
					{
						combatAction_enqueue(self, ca.movement, path[i])
						foundPath = true
						break
					}
				} 

				if !foundPath{
					combatAction_enqueue(self, ca.wait)
				}
				
				continue
			}

			//attack target
			attackTarget := combatUnit_weakest(validTargets[:])
			targetTail := combatUnit_stun_tail(attackTarget)
			
			slowestValidAttack:^CombatAction
			slowestStep := -1
			fastestValidAttack:^CombatAction
			fastestStep := INT_MAX
			for info in validAttacksInfo{
				if !contains(info.unitsInRange, attackTarget) do continue
				attackStep := reactionStep + info.attack.startup

				if attackStep < fastestStep{
					fastestValidAttack = info.attack
					fastestStep = attackStep
				}

				if attackStep < targetTail && attackStep > slowestStep{
					slowestValidAttack = info.attack
					slowestStep = attackStep
				}

			}

			attack := slowestValidAttack == nil ? fastestValidAttack : slowestValidAttack

			targetStep := reactionStep + (predictiveTargeting?attack.startup:0)
			targetRect := combatUnit_ghost_rect(attackTarget, targetStep)
			
			if(rects_overlap(targetRect, currentRect)){
				actionCheck := [2]^CombatActionQueued{combatUnit_queued_action_on_step(attackTarget, targetStep-1), combatUnit_queued_action_on_step(attackTarget, targetStep)}
				if !(actionCheck[0] != nil && actionCheck[0].action == ca.movement && actionCheck[1] != nil && actionCheck[1].action == ca.movement){
					//Target will be bumped aside by self on arrival - predict the post-bump position so
					//the attack aims where the target actually ends up, not the overlapping cell.
					//Determine facing by walking the target's ghost position back until it differs
					targetFacing := attackTarget.stageCharacter.facing
					refPos := combatUnit_ghost_position(attackTarget, targetStep)
					for s := targetStep - 1; s >= combat.current_step; s -= 1{
						priorPos := combatUnit_ghost_position(attackTarget, s)
						if priorPos != refPos{
							targetFacing = vec2i_cardinal(refPos, priorPos)
							break
						}
					}
					targetRect = combat_bump_rect(targetRect, targetFacing, {currentRect})
				}
			}

			attackWithCombo(self, attack, rect_center(targetRect))
			return
		}
	}
}

//Clears queued actions that haven't started their startup period yet
combatUnit_queued_actions_clear :: proc(using self:^CombatUnit){
	#reverse for &caq in queuedActions{
		if !combatActionQueued_started(&caq) do pop(&queuedActions)
	}
}

combatUnit_nearest :: proc(pos:Vec2i, step:=-1, whitelist:CombatUnitTypes, ignore:^CombatUnit=nil) -> ^CombatUnit{
	lowestDist := INT_MAX
	out:^CombatUnit

	units := combatUnits_get()
	for unit in units{
		if unit.unitType not_in whitelist || unit == ignore do continue
		dist := vec2_manhattan_distance(pos, rect_center(combatUnit_ghost_rect(unit, step)))
		if dist < lowestDist{
			out = unit
			lowestDist = dist
		}
	}

	return out
}

//Returns the unit of the whitelisted types with the highest stun. If no valid units are stunned, returns the unit with the lowest hp.
combatUnit_weakest :: proc(units:[]^CombatUnit=nil, whitelist:=~CombatUnitTypes{}, rangeLimit:=-1, rangeRect:=Recti{{0,0},{1,1}}) -> ^CombatUnit{

	highestTail := combat.current_step 
	highestTailUnit:^CombatUnit
	lowestHP := 9999
	lowestHPUnit:^CombatUnit

	units:=units
	if units == nil do units = combatUnits_get()

	for unit in units{
		if unit.unitType not_in whitelist do continue
		if rangeLimit != -1{
			if recti_manhattan_distance(unit.combatEntity.rect, rangeRect) > rangeLimit do continue
			if len(combat_pathfind(unit.combatEntity, rangeRect)) > rangeLimit do continue
		}

		tail := combatUnit_queued_action_tail(unit)
		if tail > highestTail{
			highestTailUnit = unit
			highestTail = tail
		}

		if unit.hp > 0 && unit.hp < lowestHP{
			lowestHPUnit = unit
			lowestHP = unit.hp
		}
	}

	if highestTailUnit != nil do return highestTailUnit
	return lowestHPUnit
}

//apply hitstun to a unit without triggering the stun anim, break effect, or timeline particles
combatUnit_stun :: proc(using self:^CombatUnit, amount:int){
	clear(&queuedActions)
	stunCounter = amount
	combat_timeline_break(self, false)
}

combatUnit_damage :: proc(using self:^CombatUnit, damage:int, hitstun:int, damageKind:=CombatDamageKind.physical, attacker:^CombatUnit=nil) -> bool{
	if(self == nil) do return false

	newFacing := (attacker != nil) ? vec2_cardinal(combatUnit_center_draw_pos(attacker), combatUnit_center_draw_pos(self)) : Dir.none

	damage:=damage
	hitstun:=hitstun
	damageKind:=damageKind
	
	combat_event_process(CombatEventDataHit{
		attacker,
		self,
		&damage,
		&hitstun,
		&damageKind
	})

	damage  = max(damage - self.defense[damageKind], 0)
	
	lastHp = hp
	hp -= damage
	if hp <= 0{
		clear(&queuedActions)
		stunCounter = 0
		combat_timeline_break(self)
		switch unitType{
			case .enemy:

				combatSuccess := true
				units := combatUnits_get()
				for unit in units{
					if unit.unitType == .enemy && unit != self && unit.unitState == .alive do combatSuccess = false
				}

				if combatSuccess do callback_call(combat.success_callback)

			case .ally:
				//todo: ally knockouts
			case .player:
				gameOver := true
				units := combatUnits_get()
				for unit in units{
					if unit.unitType == .player && unit != self && unit.unitState == .alive do gameOver = false
				}

				if gameOver do proc_call_delayed(combat.failure_callback, 1)
		}

		if dissolveOnKo{
			unitState = .dead
			stageCharacter_sprite_set_dirSprites(stageCharacter, sprites.hurt, sprites.hurtToStun, sprites.stun, newFacing=newFacing)
			combatEntity_unplace(combatEntity)
		}
		else{
			unitState = .knockedOut
			stageCharacter_sprite_set_dirSprites(stageCharacter, sprites.hurt, sprites.koStart, sprites.ko, newFacing=newFacing)
		}
	}
	else if hitstun > 0{
		if len(queuedActions) > 0{ //"BREAK!" effect
			dur := sprite_duration_f(sp.shineAnimated24px)*2
			startPos := stageCharacter.transform.pos+{0,2}
			startZ :: -24
			te := textEffect_make("BREAK!", startPos, startZ, dur, COLOR_WHITE, font=fo.fairfaxItalic__12, alignment=0, alphaCurve=cu.popOut, shake=20, shakeCurve=cu.popInFully_inv)
			se := spriteEffect_make(sp.shineAnimated24px, startPos-{3,1}, startZ, dur, animSpeed=0.5, color=color_hex(0x87949d))
			te.stageEntity.ignoreTimeStop = true
			se.stageEntity.ignoreTimeStop = true
		}
		clear(&queuedActions)
		stunCounter = hitstun
		stageCharacter_sprite_set_dirSprites(stageCharacter, sprites.hurt, sprites.hurtToStun, sprites.stun, newFacing=newFacing)
		combat_timeline_break(self)
		if reactAfterBreak{
			combatUnit_AI_plan_actions(self)
			combat_timeline_refresh_unit_pips(self)
		}
	}
	else if damage > 0{
		stageCharacter_sprite_set_dirSprites(stageCharacter, sprites.hurt, stageCharacter.spriter.mySprite, newFacing=newFacing)
	}

	if damage > 0{
		damageEffect_make(damage, stageCharacter.transform.pos + {0,1})
		ui_cue(imkey_combine(component_array_index(self), loc="unitDamageSeq")) //array index guaranteed stable in combat
	}
	//else todo: "No damage" effect

	combat_event_process(CombatEventDataHitEnd{
		attacker,
		self,
		damage,
		hitstun,
		damageKind
	})

	return true
}



combatUnit_move_sequence :: proc(using self:^CombatUnit, targetPos:Vec2i, moveSprite:DirSprite=nil, pace:union{f32,int}=COMBAT_SUBSTEP_TIME, updateFacing:=true) -> bool{
	state:^struct{
		startPos:Vec2,
		endPos:Vec2,
	}
	if seq_open(&state, imkey_combine(&self.baseBase, loc="combat__unit_move")){
		if(seq_cue(0)){
			state.startPos = combatEntity.transform.pos
			state.endPos = combatEntity_stage_pos(combatEntity, targetPos)
			combatEntity_move(self.combatEntity, targetPos)
			moveFacing := updateFacing?vec2_cardinal(state.endPos, state.startPos):stageCharacter.facing

			newSprite := (moveSprite != nil) ? moveSprite : DirSprite(self.stageCharacter.sprites.walk)
			if newSprite != stageCharacter_sprite_get(stageCharacter) || stageCharacter.facing != moveFacing do stageCharacter_sprite_set(self.stageCharacter, newSprite, moveFacing)
		}

		duration := pace.(int) or_else ceili(vec2_distance(state.startPos, state.endPos)/pace.(f32))

		if seq_cue(0, duration){
			footstep_sounds(stageCharacter, false)
			transform_set(self.stageCharacter.transform, seq_map(state.startPos, state.endPos))
		}

		if(seq_cue(duration)){
			return seq_close(.end)
		}
	}
	return seq_close()
}


//Gets a consistent rough center display position at which a combat unit's character is drawn
combatUnit_center_draw_pos :: proc(using self:^CombatUnit, pos:=Vec2i{-1,-1}) -> Vec2{
	pos := (pos == {-1,-1}) ? combatEntity.pos : pos

	drawPos := combatEntity_stage_pos(combatEntity, pos)
	
	out := rect_center(sprite_draw_rect(sprites.idle.side, drawPos))
	out.x = drawPos.x
	out -= stage.camera_pos
	return out
}

combatUnit_draw_pos :: proc(using self:^CombatUnit, pos:=Vec2i{-1,-1}) -> Vec2{
	return combatEntity_stage_pos(combatEntity, pos) - stage.camera_pos
}

combatUnit_ghost_position :: proc(using self:^CombatUnit, step:=-1) -> Vec2i{
	out := combatEntity.pos
	if step < 0{ //just get last position
		for &caq in queuedActions{
			if(caq.action.updateGhostPosition != nil) do caq.action.updateGhostPosition(&caq, &out)
		}
	}
	else{
		curStep := combat.current_step + stunCounter
		for &caq in queuedActions{
			curStep += caq.startupCounter
			if step <= curStep do return out
			if(caq.action.updateGhostPosition == nil){
				curStep += 1 + caq.cooldown
				if step <= curStep do return out
				continue
			} 
			
			caq.action.updateGhostPosition(&caq, &out)

			curStep += 1 + caq.cooldown
			if step <= curStep do return out
		}
	}
	return out
}
combatUnit_ghost_rect :: #force_inline proc(using self:^CombatUnit, step:=-1) -> Recti{
	return Recti{combatUnit_ghost_position(self, step), combatEntity.size}
}

combatUnitGhostDrawData_sprite :: proc(self:^CombatUnit, dd:CombatUnitGhostDrawData) -> ^Sprite{
	if dd.caq == nil || dd.caq.kind == .basic do return dirSprite_get(self.sprites.idle, dd.dir)

	step := combatActionQueued_target_preview_step(dd.caq)
	triggerStep := combatActionQueued_trigger_step(dd.caq)+1
	if step < combatActionQueued_start_step(dd.caq) || step > triggerStep+dd.caq.cooldown do return dirSprite_get(self.sprites.idle, dd.dir)
	else if step > triggerStep do return self.sprites.stun
	else do return dirSprite_get(self.sprites.ready, dd.dir)
	
}

//Returns the preview steps a unit should draw at
combatUnit_preview_step_lerped :: proc(self:^CombatUnit) -> (final:int, prev:int, next:int, prog:f32){
	if self.actionPreviewPinned do return -1,-1,-1,1
	
	initiative := combatUnit_initiative(self)
	initiativeAdjust := combat.preview_time.initiative > -1 ? int(initiative > combat.preview_time.initiative):0
	displayedInitiativeAdjust := ui_cue_map_stateful(imkey_combine(&self.baseBase, "displayedInitiativeAdjust"), 6, f32(initiativeAdjust), cu.easeIn, cueMap=&combat.cues)
	
	target := combat.preview_time.targetStep - initiativeAdjust
	displayed := combat.preview_time.displayedStep - displayedInitiativeAdjust
	target = max(target, combat.current_step)
	displayed = max(displayed, f32(combat.current_step))
	
	if f32(target) == displayed do return target, target, target, 1
	
	integer,frac := split(displayed)
	if f32(target) > displayed do return target, int(integer), int(integer)+1, frac
	
	return target, int(integer)+1, int(integer), 1-frac
}

combatUnit_preview_step :: #force_inline proc "contextless" (self:^CombatUnit) -> int{
	if self.actionPreviewPinned do return -1
	return combat.preview_time.targetStep - (combat.preview_time.initiative > -1 ? int(combatUnit_initiative(self) > combat.preview_time.initiative):0)
}



combatUnit_stage_rect :: proc(using self:^CombatUnit, pos:=Vec2i{-1,-1}) -> Rect{
	pos:=pos
	if(pos == {-1,-1}) do pos = combatEntity.pos
	return Rect{combat_to_stage_pos(pos, true), Vec2(combatEntity.size)*COMBAT_TILE_SIZE}
}

combatUnit_queued_action_tail :: proc(using self:^CombatUnit) -> int{
	out := combat.current_step + stunCounter
	for caq in queuedActions{
		out += caq.startupCounter + caq.cooldown + 1
	}
	return out
}
combatUnit_stun_tail :: proc(using self:^CombatUnit, committedActionOnly:=false) -> int{
	out := combat.current_step + stunCounter
	if len(queuedActions) > 0{
		action := &queuedActions[0]
		if !committedActionOnly || action.startupCounter != action.startup do out += action.startupCounter
	}
	return out
}

//by default, will check if the action triggers on or after the given trigger step
combatUnit_queued_action_find :: proc(using self:^CombatUnit, kind:=CombatActionKind.attack, reverse:=false, triggerStepFilter:=-1, checkExactTriggerStep:=false) -> ^CombatActionQueued{
	stepCheck :: proc(actionStep, checkStep:int, checkExact:bool) -> bool{
		if checkStep <= 0 do return true
		if checkExact do return actionStep == checkStep
		return actionStep >= checkStep
	}
	if reverse{
		#reverse for &caq in queuedActions{
			if caq.kind == kind && stepCheck(triggerStepFilter, combatActionQueued_trigger_step(&caq), checkExactTriggerStep) do return &caq
		}
	}
	else{
		for &caq in queuedActions{
			if caq.kind == kind && stepCheck(triggerStepFilter, combatActionQueued_trigger_step(&caq), checkExactTriggerStep) do return &caq
		}
	}
	return nil
} 

combatUnit_queued_action_on_step :: proc(using self:^CombatUnit, step:int) -> ^CombatActionQueued{
	checkStep := combat.current_step + stunCounter
	for &caq in queuedActions{
		lastCheckStep := checkStep
		checkStep += caq.startupCounter
		if in_range(step, lastCheckStep, checkStep) do return &caq
		checkStep += caq.cooldown + 1
	}
	return nil
}

combatUnit_action_queue_full :: proc(self:^CombatUnit) -> bool{
	return combatUnit_queued_action_tail(self) >= combat.next_planning_step
}

combatUnit_add_to_system :: proc(using self:^CombatUnit, pos:Vec2i){
	if combatEntity.placedInGrid do return //already in system

	hp = maxHp
	if !flag_check("safeZone"){
		pid,ok := player_character_string_to_id(initID.s)
		if ok do hp = save.characters[pid].hp
	}

	clear(&queuedActions)
	mover_zero(stageCharacter.mover)
	stunCounter = 0
	unitState = .alive
	append(&combat.resolve_queue, self)
	sort(&combat.resolve_queue, proc(a,b:^CombatUnit)->bool{
		return combatUnit_initiative(a, false) > combatUnit_initiative(b, false)
	})
	combatEntity_place(combatEntity, pos)
}

combatUnit_combo_add :: proc(using self:^CombatUnit, actions:..^CombatAction){
	append(&combos, [dynamic; 4]^CombatAction{})
	set(peek_ptr(&combos), newVal=actions)
}

combatUnit_initiative :: proc "contextless"(self:^CombatUnit, unique:=true) -> int{
	out := int(self.initiative) | (int(self.unitType)<<8)
	if unique{
		ind,ok := find(combat.resolve_queue, self)
		if ok do out |= (len(combat.resolve_queue)-1-ind)<<16
	}
	return out
}

//reload a unit based on its initID
combatUnit_reload :: proc(using self:^CombatUnit){
	if initID.s == "" do return
	
	//sprites
	sprites = {
		{
			sprite_find(format("%s_combat_idle_side_loop", initID)),
			sprite_find(format("%s_combat_idle_up_loop", initID)),
			sprite_find(format("%s_combat_idle_down_loop", initID)),
		},
		{
			sprite_find(format("%s_combat_idle_side_toReady", initID)),
			sprite_find(format("%s_combat_idle_up_toReady", initID)),
			sprite_find(format("%s_combat_idle_down_toReady", initID)),
		},
		{
			sprite_find(format("%s_combat_idle_side_ready", initID)),
			sprite_find(format("%s_combat_idle_up_ready", initID)),
			sprite_find(format("%s_combat_idle_down_ready", initID)),
		},
		{
			sprite_find(format("%s_combat_walk_side", initID)),
			sprite_find(format("%s_combat_walk_up", initID)),
			sprite_find(format("%s_combat_walk_down", initID)),
		},
		{
			sprite_find(format("%s_combat_actionToStun_side", initID)),
			sprite_find(format("%s_combat_actionToStun_up", initID)),
			sprite_find(format("%s_combat_actionToStun_down", initID)),
		},
		{
			sprite_find(format("%s_combat_actionToIdle_side", initID)),
			sprite_find(format("%s_combat_actionToIdle_up", initID)),
			sprite_find(format("%s_combat_actionToIdle_down", initID)),
		},
		sprite_find(format("%s_combat_stun_loop", initID)),
		sprite_find(format("%s_combat_stun_toIdle", initID)),
		sprite_find(format("%s_combat_stun_hurt", initID)),
		sprite_find(format("%s_combat_stun_hurtToStun", initID)),

		sprite_find(format("%s_combat_ko_start", initID)),
		sprite_find(format("%s_combat_ko_loop", initID)),
		sprite_find(format("%s_combat_ko_getup", initID)),
		
		sprite_find(format("%s_combat_start", initID)),
		sprite_find(format("%s_combat_end", initID)),
		sprite_find(format("%s_timelinePortrait", initID))
	}

	//ensure some very basic default anims are functional
	if sprites.idle.side == sp.nil_ do sprites.idle.side = sp.pro_combat_idle_side_loop

	directionals := cast(^[6]DirSpriteSet)&sprites //sorta hacky
	for &set in directionals{ //if only the sideways sprite is done for a given animation, use that for all directions
		if set.side != sp.nil_{
			if set.up == sp.nil_ do set.up = set.side
			if set.down == sp.nil_ do set.down = set.side
		}
	}

	sprSet :: proc(spr:^Sprite) -> DirSpriteSet{return {spr, spr, spr}}

	if sprites.actionToIdle == sprSet(sp.nil_) do sprites.actionToIdle = sprites.idle //for units whose actions end on their idle pose
	if sprites.actionToStun == sprSet(sp.nil_) do sprites.actionToStun = sprSet(sprites.stun) //for units whose actions end on their stun pose
	if sprites.hurtToStun == sp.nil_ do sprites.hurtToStun = sprites.stun //for units whose hurt ends on the stun pose
	if sprites.combatStart == sp.nil_ do sprites.combatStart = sprites.idle.side
	if sprites.combatEnd == sp.nil_ do sprites.combatEnd = sprites.idle.side
	if sprites.koStart == sp.nil_ do dissolveOnKo = true

	//audio
	audioEvents = {
		audio_event_find(format("%s_combat_start", initID))
	}
	
	if initID.s in combat.unit_inits do combat.unit_inits[initID.s](self)

	hp = maxHp
}

combatUnit_find :: proc(id:string, unsafe:=false) -> ^CombatUnit{
	units := combatUnits_get()
	for unit in units{
		if unit.initID.s == id do return unit
	}
	if unsafe do return nil
	panicf("No active combat unit with id '%s' found!", id)
}

//Only returns active combat units (in the grid and either alive or knocked out)
combatUnits_get :: proc()->[]^CombatUnit{
	out := slice_to_array(coall_true(CombatUnit), context.temp_allocator)
	#reverse for unit, i in out{
		if !combatUnit_active(unit) do unordered_remove(&out, i)
	}
	shrink(&out)
	return out[:]
}

combatUnit_active :: #force_inline proc(unit:^CombatUnit)->bool{
	return unit.combatEntity.placedInGrid && unit.unitState != .dead
}

//Checks if a unit is colliding with any other unit and moves it to a new position if it is
combatUnit_bump_check :: proc(unit:^CombatUnit, unitFacing:Dir) -> bool{
	ent := unit.combatEntity._ptr
	newPos := ent.pos
	combatEntity_unplace(ent)
	defer combatEntity_place(ent, newPos)
	collidingUnits := combat_collision_unit_rect(ent.rect)

	if len(collidingUnits) == 0 do return false

	//intuitive pushing algorithm
	push:Vec2i
	pushDir:Vec2
	entCenter := Vec2(ent.pos) + Vec2(ent.size)/2
	for col,i in collidingUnits{
		dir := vec2_dir(entCenter, Vec2(col.combatEntity.pos) + Vec2(col.combatEntity.size)/2)
		if i == 0 do pushDir = dir
		else do pushDir = vec2_normalize((pushDir + dir)/2)
	}

	absPushDir := abs(pushDir)

	if pushDir.x==0 && pushDir.y==0 do push = -cardinal_to_vec2i(unitFacing)
	else if abs(absPushDir.x-absPushDir.y) < 0.001 do push = Vec2i{signi(pushDir.x), signi(pushDir.y)}
	else if absPushDir.x > absPushDir.y do push = Vec2i{signi(pushDir.x), 0}
	else do push = Vec2i{0, signi(pushDir.y)}

	newPos += push
	for{
		newCollidingUnits := combat_collision_unit_rect(Recti{newPos, ent.size})
		found:bool
		for col in newCollidingUnits{
			if contains(collidingUnits, col){
				found = true
				break
			}
		}

		if found{
			newPos += push
		}
		else do break
	}

	//failsafe algorithm
	if combat_collision(Recti{newPos, ent.size}) do newPos = combat_nearest_free_space(unit, ent.pos, false)	
	return true
}

//pure version of the bump algo, does not account for new units outside of the provided bumpers
combat_bump_rect :: proc(bumped:Recti, bumpedFacing:Dir, bumpers:[]Recti) -> Recti{
	newPos := bumped.pos

	//intuitive pushing algorithm
	push:Vec2i
	pushDir:Vec2
	bumpedCenter := rect_center(rect_cast(bumped))
	for col,i in bumpers{
		dir := vec2_dir(bumpedCenter, rect_center(rect_cast(col)))
		if i == 0 do pushDir = dir
		else do pushDir = vec2_normalize((pushDir + dir)/2)
	}

	absPushDir := abs(pushDir)

	if pushDir.x==0 && pushDir.y==0 do push = -cardinal_to_vec2i(bumpedFacing)
	else if abs(absPushDir.x-absPushDir.y) < 0.001 do push = Vec2i{signi(pushDir.x), signi(pushDir.y)}
	else if absPushDir.x > absPushDir.y do push = Vec2i{signi(pushDir.x), 0}
	else do push = Vec2i{0, signi(pushDir.y)}

	newPos += push
	for{
		found := false
		for col in bumpers{
			if rects_overlap(Recti{newPos, bumped.size}, col){
				found = true
				break
			}
		}

		if found{
			newPos += push
		}
		else do break
	}

	return Recti{newPos, bumped.size}
}


_combatUnit_process_event :: proc(base:^ComponentBase, event:Event, overrideDisabled:=false){
if(!overrideDisabled && event in base.disabledEvents) do return
last_context := entities.context_component
defer cowith(last_context)
cowith(base)
self := cast(^CombatUnit)base
using self
#partial switch event{
case .init:
	assert(cocount_true(.combatUnit) <= COMBAT_UNIT_CAP, "Created too many combat units!")
	coadd(&combatEntity)
	coadd(&stageCharacter)
	coadd(&stageEntity)

	coRef_init(&stageCharacter.combatUnit, self, &stageCharacter.base)

	component_events_disable(stageEntity, {.draw})

	//reasonable defaults
	maxHp = 6
	hp = maxHp
	walkSpeed = 3
	unitType = .enemy
	combatEntity.size = {3,3}
	initiative = 100
	reactionTime = -1 //i.e. no reactivity


case .loaded:
	combatUnit_reload(self)
	hp = maxHp

	if stageCharacter.sprites.idle == {nil,nil,nil} do stageCharacter.sprites.idle = sprites.idle
	if stageCharacter.sprites.walk == {nil,nil,nil} do stageCharacter.sprites.walk = sprites.walk

case .justMade:
	if combat.phase != .disabled{
		combatUnit_add_to_system(self, floori((combatEntity.transform.pos-combat.grid_stage_pos)/COMBAT_TILE_SIZE) - floori(Vec2(combatEntity.size)/2))
	}

case .update:
	if unitState == .dead && stageCharacter.spriter.animEnded && stageCharacter.spriter.mySprite == sprites.hurtToStun{
		stageEntity.spriter.animSpeed = 0
		stageEntity_set_visible(stageEntity, false)
		unitDissolveEffect_make(stageCharacter.transform.pos, sprites.hurtToStun, stageCharacter.transform.scale)
	}

case .updateEditor:
	if initID.s != "" && initID.s != lastInitID{
		combatUnit_reload(self)
		spriter_set(stageEntity.spriter, sprites.idle.side)
		delete(lastInitID)
		lastInitID = initID.s
	}
case .preDraw:
	depth = stageEntity.depth
	ghostDrawData = nil
	ghostPositions = nil
	ghostBaseDrawData.caq = nil
	if equals(combat.phase, CombatPhase.planning, CombatPhase.starting) && combatUnit_active(self) {
		ghostPosArr := make([dynamic]Vec2i, 0, len(queuedActions), context.temp_allocator)
		append(&ghostPosArr, combatEntity.pos)
		ghostDrawDataArr := make([dynamic]CombatUnitGhostDrawData, 0, len(queuedActions), context.temp_allocator)
		depthArr := make([dynamic]f32, 0, len(queuedActions), context.temp_allocator)
		append(&depthArr, stageEntity.depth.(f32))
		lastPos := combatEntity.pos
		curPos := lastPos
		curStep := combat.current_step + stunCounter
		finalStep,finalStepPrev,finalStepNext,finalStepProg:=combatUnit_preview_step_lerped(self)
		for &caq, i in queuedActions{
			lastPreviewAction := false

			nextAction:^CombatActionQueued
			if i+1 < len(queuedActions) do nextAction = &queuedActions[i+1]

			if actionPreviewPinned{
				if(caq.action.updateGhostPosition != nil) do caq.action.updateGhostPosition(&caq, &curPos)
				if caq.action == ca.movement && nextAction != nil && nextAction.action == ca.movement do continue
			}
			else{
				curStep += caq.startupCounter
				if finalStep <= curStep{
					if curPos == combatEntity.pos && !equals(caq.action, ca.movement, ca.wait){
						ghostBaseDrawData.caq = &caq
						ghostBaseDrawData.dir = caq.aimDir
					}
					break
				}

				if(caq.action.updateGhostPosition != nil) do caq.action.updateGhostPosition(&caq, &curPos)
				curStep += 1 + caq.cooldown
				if finalStep <= curStep do lastPreviewAction = true
				else if caq.action == ca.movement && nextAction != nil && nextAction.action == ca.movement do continue
			}
			
			if(curPos != lastPos){
				ghostDir := vec2i_cardinal(curPos, lastPos)
				drawPos := combat_to_stage_pos(curPos + combatEntity.size/2)
				
				ghostCaq:^CombatActionQueued
				if nextAction != nil && !equals(nextAction.action, ca.movement, ca.wait) && finalStep != curStep{
					ghostDir = nextAction.aimDir
					ghostCaq = nextAction
				}

				append(&ghostPosArr, curPos)
				append(&ghostDrawDataArr, CombatUnitGhostDrawData{drawPos, ghostCaq, ghostDir})
				append(&depthArr, -drawPos.y)
				lastPos = curPos
			}
			
			if curPos == combatEntity.pos && !equals(caq.action, ca.movement, ca.wait){
				ghostBaseDrawData.caq = &caq
				ghostBaseDrawData.dir = caq.aimDir
			}
			if lastPreviewAction do break
		}

		if finalStepPrev != finalStepNext{
			prevPos := combat_to_stage_pos(combatUnit_ghost_position(self, finalStepPrev), true)
			nextPos := combat_to_stage_pos(combatUnit_ghost_position(self, finalStepNext), true)
			if prevPos != nextPos{
				lerpPos := lerp(prevPos, nextPos, finalStepProg) + Vec2(combatEntity.size)/2*COMBAT_TILE_SIZE

				if len(ghostDrawDataArr) == 0{
					append(&ghostDrawDataArr, CombatUnitGhostDrawData{lerpPos, nil, vec2_cardinal(prevPos, nextPos)})
					append(&ghostPosArr, combatEntity.pos)
					append(&depthArr, -lerpPos.y)
				}
				else do peek_ptr(&ghostDrawDataArr).pos = lerpPos
			}
		}

		ghostDrawData = ghostDrawDataArr[:]
		depth = depthArr[:]
		ghostPositions = ghostPosArr[:]
	}

	if unitType == .player{
		drawAttackWarningLevel = 0
		clear(&drawAttackWarningMovementAimMarkers)
		checkRect := combatEntity.rect
		curActionInd := 0
		curAction:^CombatActionQueued

		moveAimTarget,ok := combat.selected_action_target.(Vec2i)
		aimingMovement := ok && combat.selected_action == ca.movement && combat.selected_unit == self
		stunTail := combatUnit_stun_tail(self)

		for step in combat.current_step..<combat.preview_time.targetStep{
			if len(queuedActions) > curActionInd do curAction = &queuedActions[curActionInd]
			else do curAction = nil

			if curAction != nil{
				if step == combatActionQueued_trigger_step(curAction){
					if curAction.action.updateGhostPosition != nil do curAction.action.updateGhostPosition(curAction, &checkRect.pos)
					curActionInd += 1
				}
			}
			else if aimingMovement && step >= stunTail && checkRect.pos != moveAimTarget{
				checkRect.pos = combat_movement_step_simulate(checkRect.pos, moveAimTarget, walkSpeed)
			}

			attacks := combat_attackers_get(self, checkRect, step, true)
			if len(attacks) > 0{
				drawAttackWarningLevel = 2
				append(&drawAttackWarningMovementAimMarkers, CombatMarker{checkRect.pos, step})
			}
		}
	}

case .draw:
	using stageEntity
	player:^Player
	if unitType == .player do player = cofind(Player)
	ghostCol := COLOR_WHITE
	baseCol := COLOR_GRAY

	if(combat.phase == .planning){
		if combat.timeline_hover_unit == self{
			ghostCol = color_lerp(color_hex(0xc29566), color_hex(0xf4d9aa), wave(0,1,40))
			baseCol = color_lerp(baseCol, ghostCol, 0.7)
		}
		else if actionPreviewPinned do ghostCol = color_lerp(color_hex(0xc29566), color_hex(0xffe7b8), wave(0,1,50))
		else if drawAttackWarningLevel > 0 && !(combat.selected_action == ca.movement && combat.selected_unit == self){
			ghostCol = color_lerp(COLOR_WHITE, color_hex(drawAttackWarningLevel == 1 ? 0xffc20a:0xcc2d20), wave(0,0.4,50))
		}
	}
	
	switch entities.draw_step{
		case 0:
			inPlanning := combat.phase == .planning && combat.time_stop_mode != .disabled

			spr := spriter.mySprite
			scale := transform.scale
			if inPlanning && ghostBaseDrawData.caq != nil{
				spr = combatUnitGhostDrawData_sprite(self, ghostBaseDrawData)
				scale.x = ghostBaseDrawData.dir == .left ? -1:1
			}
			
			entAlpha := alpha
			alpha = 1
			defer alpha = entAlpha
			drawTex := tex_make(spr.size) //needed in order to preserve other shaders
			defer tex_destroy(drawTex)
			origin := Vec2{f32(spr.origin.x), f32(spr.origin.y)}
			if scale.x < 0 do origin.x += spr.size.x - origin.x*2 - 1
			drawTexPos := stageEntity_draw_pos(stageEntity) - origin
			tex_target_set(drawTex, drawTexPos)
			if player != nil{
				pro_blade_pal_swap_set()
			}

			if inPlanning{
				sprite_draw_ex(
					spr, stageEntity_draw_pos(stageEntity), 0, 
					scale, transform.angle, (ghostDrawData != nil) ? baseCol : ghostCol
				)
			}
			else{
				if player != nil{
					sprite_draw_ex(
						spr, stageEntity_draw_pos(stageEntity), spriter.lastFrame, 
						scale, transform.angle, color, 1, blendmode
					)
				}
				else do component_event_process(stageEntity, .draw)
			}

			if player != nil{
				shader_reset()
				stage_shader_uniforms_set(stageEntity)
			}
			tex_target_reset()
			drawAlpha :f32= 1
			if combat.phase == .planning && combatEntity.placedInGrid{
				alphaTarget :f32= (!cutscene.enabled && 
				rect_contains(stageEntity_draw_rect(stageEntity, spriter.lastFrame), combat_cursor_stage_pos()) &&
				!(input_device() == .gamepad && combat.selected_action == nil && combat.selected_unit == self)
				)?0.5:1
				drawAlpha = ui_cue_map_stateful(imkey_combine(&baseBase, "hoverFade"), 6, alphaTarget, cueMap=&combat.cues)
			}
			tex_draw_ex(drawTex, drawTexPos, alpha=drawAlpha*entAlpha)
			stage_shader_uniforms_reset(stageEntity)
			
		case:
			combat_shader_set(false)
			if player != nil do pal_swap_set(sp.proBladePalettes, player_character_equipped_item(.pro, .blade).paletteIndex)
			drawData := ghostDrawData[entities.draw_step-1]
			spr := combatUnitGhostDrawData_sprite(self, drawData)
			sprite_draw_ex(
				spr, drawData.pos, sprite_frame_get(spr), 
				Vec2{drawData.dir==.left ? -1:1, transform.scale.y}, transform.angle, (entities.draw_step == len(self.depth.([]f32))-1) ? ghostCol : baseCol, 0.5
			)
			if player != nil do shader_reset()
	}

	
	if(combat.phase == .planning && entities.draw_step == len(ghostDrawData) && combatUnit_active(self) && unitState == .alive){
		combat_shader_set(false)

		//HP bar
		pal:CombatUnitHPPalette
		switch -(f32(hp)/f32(maxHp)){
			case -1..<-0.5: pal = COMBAT_UNIT_HP_PALETTES.high
			case -0.5..<-0.25: pal = COMBAT_UNIT_HP_PALETTES.middle
			case -0.25..=0: pal = COMBAT_UNIT_HP_PALETTES.low
		}
		stageRectPos:Vec2
		rectSize := Vec2(combatEntity.size)*COMBAT_TILE_SIZE
		centerOff := rectSize/2
		if len(ghostDrawData) > 0 do stageRectPos = peek_ptr(ghostDrawData).pos - centerOff
		else do stageRectPos = combat_to_stage_pos(combatEntity.pos, true)
		hpRect := Rect{stageRectPos+Vec2{3, rectSize.y-9}, {2*ceil(f32(maxHp)) + 1, 6}}
		draw_rect(hpRect, pal.dark)
		hpRect.size.y -= 3
		draw_rect(hpRect, pal.darkSecondary)

		hpDrawn := 0
		pipRect := Rect{hpRect.pos+{1,3}, {1,2}}
		for hpDrawn < maxHp{
			draw_rect(pipRect, (hpDrawn < hp) ? pal.light : pal.middle)
			pipRect.pos.y -= 2
			draw_rect(pipRect, (hpDrawn < hp) ? pal.highlight : pal.middle)
			hpDrawn += 1
			if hpDrawn+1 < hp{
				pipRect.pos.x += 1
				draw_rect(pipRect, pal.middle)
				pipRect.pos.x += 1
			}
			else do pipRect.pos.x += 2
			pipRect.pos.y += 2
		}

		//HP text
		hpTextPos := hpRect.pos - Vec2{0, 11}
		hpText := format("%i/%i", hp, maxHp)
		text_draw(hpText, hpTextPos+ {0, 1}, COLOR_BLACK, 1, fo.yal6w4__16)
		text_draw(hpText, hpTextPos, COLOR_WHITE, 1, fo.yal6w4__16)

		//Preview eye
		if actionPreviewPinned{
			sprite_draw_ex(sp.timelineEye, stageRectPos+centerOff - {0, 52+wave(-1,1,50)}, color=ghostCol)
		}
		else if drawAttackWarningLevel > 0{ //attacked warning
			warningPos := stageRectPos + centerOff - {0, 52+wave(0,1,50)}
			
			sprite_draw_ex(drawAttackWarningLevel == 1 ? sp.combat_ui_danger_yellow : sp.combat_ui_danger_red, warningPos)
			for marker in drawAttackWarningMovementAimMarkers{
				if marker.pos == combatUnit_ghost_position(self, combat.preview_time.targetStep) do continue 
				warningPos = combat_to_stage_pos(marker.pos, true) + centerOff - {0,20}
				sprite_draw_ex(drawAttackWarningLevel == 1 ? sp.combat_ui_danger_yellow : sp.combat_ui_danger_red, warningPos)
				draw_rect(Rect{warningPos+{0,4}, {1, 15}}, color_hex(drawAttackWarningLevel == 1 ?0xffc20a:0xcc2d20))
			}
			
		}

	}
	else if combat.phase == .resolving{
		ui_cue_seq_open(imkey_combine(component_array_index(self), loc="unitDamageSeq"))
		if seq_time() < 70{
			displayHp := hp
			hpAlpha :f32= 1
			if seq_cue(0, 6){
				hpAlpha = seq_map(0,1, cu.easeIn)
			}
			if seq_cue(60, 70){
				hpAlpha = seq_map(1,0, cu.easeOut)
			}

			hpDiff := abs(lastHp-hp)
			if seq_cue(0, clamp(hpDiff*2, 12, 20)){
				displayHp = roundi(seq_map(f32(lastHp), f32(hp)))
			}

			highlight:f32 = (seq_time()<30)?1:0
			if seq_cue(30, 54){
				highlight = seq_map(1,0)
			}

			combat_shader_set(false)
			pal:CombatUnitHPPalette
			switch -(f32(hp)/f32(maxHp)){
				case -1..<-0.5: pal = COMBAT_UNIT_HP_PALETTES.high
				case -0.5..<-0.25: pal = COMBAT_UNIT_HP_PALETTES.middle
				case -0.25..=0: pal = COMBAT_UNIT_HP_PALETTES.low
			}
			stageRect := combatUnit_stage_rect(self)
			hpRect := Rect{stageRect.pos+Vec2{3, stageRect.size.y-9}, {2*ceil(f32(maxHp)) + 1, 6}}
			drawTex := tex_make(stageRect.size)
			defer tex_destroy(drawTex)

			tex_target_set(drawTex, stageRect.pos)
			draw_rect(hpRect, pal.dark)
			hpRect.size.y -= 3
			draw_rect(hpRect, pal.darkSecondary)

			hpDrawn := 0
			pipRect := Rect{hpRect.pos + {1,3}, {1,2}}
			minHp := min(hp, lastHp)
			for hpDrawn < maxHp{
				highlighted := in_range(hpDrawn, minHp, minHp + roundi(f32(hpDiff)*highlight)-1)
				draw_rect(pipRect, highlighted ? COLOR_WHITE : ((hpDrawn < hp) ? pal.light : pal.middle))
				pipRect.pos.y -= 2
				draw_rect(pipRect, highlighted ? COLOR_WHITE : ((hpDrawn < hp) ? pal.highlight : pal.middle))
				hpDrawn += 1
				if hpDrawn+1 < displayHp{
					pipRect.pos.x += 1
					draw_rect(pipRect, pal.middle)
					pipRect.pos.x += 1
				}
				else do pipRect.pos.x += 2
				pipRect.pos.y += 2
			}

			hpTextPos := hpRect.pos - Vec2{0, 11}
			hpText := format("%i/%i", displayHp, maxHp)
			text_draw(hpText, hpTextPos+ {0, 1}, COLOR_BLACK, 1, fo.yal6w4__16)
			text_draw(hpText, hpTextPos, COLOR_WHITE, 1, fo.yal6w4__16)
			tex_target_reset()

			tex_draw_ex(drawTex, stageRect.pos, alpha=hpAlpha)
		}
		seq_close()
	}

	combat_shader_set(true)

case .clean:
	estring_delete(&initID)
	when DEBUG do delete(lastInitID)
}}
