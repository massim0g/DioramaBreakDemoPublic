#+feature using-stmt
package massimodin //@nested-tags:_components/

import "core:sync"
PlayerFollower :: struct{
	using base:ComponentBase,
	stageCharacter:CoRef(StageCharacter),
	transform:CoRef(Transform),
	mover:CoRef(Mover),
	collider:CoRef(Collider),
	combatUnit:CoRef(CombatUnit),
	timeInRange:int,
	followOffset:Vec2,
	lastTargetPos:Vec2,
	runFromCombat:bool
}

player_follower_add :: proc(id:string){
	append(&save.player_follower_ids, string_clone(id, save.allocator))	
}

_playerFollower_process_event :: proc(base:^ComponentBase, event:Event, overrideDisabled:=false){
if(!overrideDisabled && event in base.disabledEvents) do return
last_context := entities.context_component
defer cowith(last_context)
cowith(base)
self := cast(^PlayerFollower)base
using self
#partial switch event{
case .init:
	coadd(&stageCharacter)
	coadd(&transform)
	coadd(&mover)
	coadd(&collider)
	coadd(&combatUnit)
	collider.collisionGroups = {.pcs}
	followOffset = vec2_random()*random_range_f(8,16)
	combatUnit.forceCombatGridEntry = true
case .update:
	if runFromCombat && combat.phase == .starting{
		ms:DirSprite = (stageCharacter.sprites.dash.side != sp.nil_) ? stageCharacter.sprites.dash : nil
		stageCharacter_move_step(stageCharacter, stage_node_nearest(transform.pos, "followerHidingPos"), 3, moveSprite=ms)
		return
	}

	if player_dummy(){
		mover.speed = 0
		stageCharacter.overrideFacing = .none
		break
	}

	if player,ok := cofind(Player, 0); ok{
		targetPos := player.followerPos+followOffset
		for collision_stage(collider, targetPos, PLAYER_COLLISION_BLACKLIST){
			targetPos = approach(targetPos, player.followerPos, 1)
			if targetPos == player.followerPos do break
		}
		for collision_stage(collider, targetPos, PLAYER_COLLISION_BLACKLIST){
			targetPos = approach(targetPos, player.transform.pos, 1)
			if targetPos == player.transform.pos do break
		}

		transform_set(transform, vec2_approach(transform.pos, round(targetPos), stageCharacter.dashing ? player.maxRunSpeed : player.maxWalkSpeed))

		if transform.pos == round(targetPos) do mover.speed = targetPos-lastTargetPos
		else do mover.speed = vec2_dir(round(targetPos), transform.pos)

		if mover.speed != 0{
			playerMoveSpeed := player.mover.speed
			if playerMoveSpeed != 0{
				pFacingVec := cardinal_to_vec2(player.stageCharacter.facing)
				playerFacingBlocked := (pFacingVec.x != 0 && player.mover.collided.x) || (pFacingVec.y != 0 && player.mover.collided.y)
				if !playerFacingBlocked do stageCharacter.overrideFacing = player.stageCharacter.facing
				else do stageCharacter.overrideFacing = vec2_cardinal(playerMoveSpeed)
			}
			else do stageCharacter.overrideFacing = vec2_cardinal(mover.speed)
			stageCharacter.dashing = player.stageCharacter.dashing
		}

		lastTargetPos = targetPos

	}
// case .updateEnd: 
// 	if player,ok := cofind(Player, 0); ok{
// 		if mover.speed != 0 do scface(stageCharacter, player.stageCharacter.facing)
// 	}

}}
