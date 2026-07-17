#+feature using-stmt
package massimodin //@nested-tags:_components/

import "core:slice"
//For non-static entities in stages that need to be moved and animated in complex ways as part of cutscenes or gameplay
StageCharacter :: struct{
	using base:ComponentBase,
	mover:CoRef(Mover),
	spriter:CoRef(Spriter),
	transform:CoRef(Transform),
	collider:CoRef(Collider),
	stageEntity:CoRef(StageEntity),
	stageInteractable:CoRef(StageInteractable),
	combatUnit:CoRef(CombatUnit), //optional
	audioEmitter:CoRef(AudioEmitter),
	initID:Estring, //@e
	facing:Dir, //@e
	facingMode:StageCharacterFacingMode, //@e
	useCombatSpritesInOverworld:bool, //@e
	dashing:bool,
	sprites:StageCharacterSpriteSet, //standard sprites that stage characters commonly need
	overrideSprites:[dynamic]DirSprite, //last sprite in this list will always play, overriding normal animation behavior. If multiple sprites are appended, they will play in order first
	overrideFacing:Dir,
	facePlayer:StageCharacterPlayerTrackingMode //@e
}

StageCharacterFacingMode :: enum{
	normal, //full side, up, and down sprites
	diagonal, //up and down "3/4" angle sprites
	sideOnly, //only side-facing sprites
	disabled //do not apply any "facing" behavior, usually for one-off cutscene animations like the stretcher
}
StageCharacterPlayerTrackingMode :: enum{
	disabled,
	ifInteractedWith,
	always
}

//Set of all possible directional sprites for an action 
DirSpriteSet :: struct{
	side:^Sprite,
	up:^Sprite,
	down:^Sprite
}

//Directional sprite
DirSprite :: union{
	DirSpriteSet,
	^Sprite
}

StageCharacterSpriteSet :: struct{
	idle:DirSpriteSet,
	walk:DirSpriteSet,
	dash:DirSpriteSet
}

//Useful for procs that get called often from cutscene code, don't overuse
StageCharacterRef :: union{
	^StageCharacter,
	CoRef(StageCharacter),
	string,
	CoRefEx(StageCharacter),
}

stageCharacterRef_get :: proc(ref:StageCharacterRef, unsafe:=false) -> ^StageCharacter{
	switch r in ref{
		case ^StageCharacter: return r
		case CoRef(StageCharacter): return r._ptr
		case string: return stageCharacter_find(r, unsafe)
		case CoRefEx(StageCharacter): 
			out := coget(r)
			assertf(unsafe || out != nil, "Stage character not found using external component ref '%v'", r)
			return out
	}
	unreachable()
}

stageCharacter_make :: proc(id:string="", pos:=Vec2{}, facing:=Dir.right, useCombatSpritesInOverworld:=false, facingMode:=StageCharacterFacingMode.normal) -> ^StageCharacter{
	out := entity_make(StageCharacter)
	if id != ""{
		estring_set(&out.initID, id, true)
		out.useCombatSpritesInOverworld = useCombatSpritesInOverworld
		stageCharacter_reload(out)
	}
	transform_set(out.transform, pos)
	out.facingMode = facingMode
	stageCharacter_facing_set(out, facing)
	return out
}
scmake :: stageCharacter_make

stageCharacter_reload :: proc(using self:^StageCharacter){
	if initID.s == "" do return
	
	sprites = {
		{
			sprite_find(format("%s_overworld_idle_side", initID)),
			sprite_find(format("%s_overworld_idle_up", initID)),
			sprite_find(format("%s_overworld_idle_down", initID)),
		},
		{
			sprite_find(format("%s_overworld_walk_side", initID)),
			sprite_find(format("%s_overworld_walk_up", initID)),
			sprite_find(format("%s_overworld_walk_down", initID)),
		},
		{
			sprite_find(format("%s_overworld_dash_side", initID)),
			sprite_find(format("%s_overworld_dash_up", initID)),
			sprite_find(format("%s_overworld_dash_down", initID)),
		}
	}

	if sprites.idle.side.mask != nil do collider_mask_set(collider, sprites.idle.side)

	if initID.s in combat.unit_inits{
		newCombatUnit :^CombatUnit= coadd(self.entity, CombatUnit)
		estring_set(&combatUnit.initID, initID.s, true)
		combatUnit_reload(combatUnit)

		if useCombatSpritesInOverworld{
			sprites.idle = combatUnit.sprites.idle
			sprites.walk = combatUnit.sprites.walk
		}
	}

}

//"pace" by default refers to the speed of the movement, but can optionally be set to the total duration of the movement in frames.
//Using a speed value is easier for "standard" movements (i.e. when you just want a character to get from point A to point B), but a duration can allow for finer/more intuitive control for more deliberate movements
//You can give a curve, this will cause every individual movement from point to point to follow that curve, so is only really intended for simple movements.
stageCharacter_move_seq :: proc(ref:StageCharacterRef, targetPositions:[]Vec2, pace:union{f32, int}=1.5, endFacing:=Dir.none, relative:=false, moveBackwards:=false, moveSprite:DirSprite=nil, curve:^Curve=nil, key:ImKey=#caller_location) -> bool{
	self := stageCharacterRef_get(ref)
	using self
	if seq_open(key){

		footstep_sounds(self)

		seqPositions := make([]MoveSeqPos, len(targetPositions)+1, context.temp_allocator)
		if stageEntity_move_seq(self.stageEntity, targetPositions, pace, relative, nil, curve, imkey_combine(key), seqPositions){
			stageCharacter_sprite_set(self) //resets the overriden sprite
			if endFacing != .none do scface(self, endFacing)
			return seq_close(.end)
		}

		for i in 0..<len(targetPositions){
			if seq_cue(seqPositions[i].time){
				lastPos := seqPositions[i].pos
				pos := seqPositions[i+1].pos
				moveFacing := vec2_cardinal(moveBackwards ? lastPos - pos : pos - lastPos)
				if(moveSprite != nil) do stageCharacter_sprite_set(self, moveSprite, moveFacing)
				else do stageCharacter_sprite_set(self, sprites.walk, moveFacing)
			}
		}
	}
	return seq_close()
}
scmove :: stageCharacter_move_seq

stageCharacter_move_step_speed :: proc(ref:StageCharacterRef, speed:Vec2, moveBackwards:=false, moveSprite:DirSprite=nil){
	self := stageCharacterRef_get(ref)
	using self
	footstep_sounds(self)
	moveFacing := vec2_cardinal(moveBackwards ? -speed : speed)
	setSprite :DirSprite= moveSprite != nil ? moveSprite:sprites.walk
	if len(overrideSprites) == 0 || overrideSprites[0] != setSprite do stageCharacter_sprite_set(self, moveSprite, moveFacing)
	mover.speed = speed
	mover_update_pre_collision(mover)
	mover_apply(mover)
}
stageCharacter_move_step_target :: proc(ref:StageCharacterRef, target:Vec2, speed:f32, endFacing:=Dir.none, moveBackwards:=false, moveSprite:DirSprite=nil, movingTarget:=false){
	self := stageCharacterRef_get(ref)
	using self
	if !movingTarget && vec2_distance(transform.pos, target) <= speed{
		transform_set(transform, target)
		stageCharacter_move_step_end(self, endFacing)
		return
	}

	stageCharacter_move_step_speed(self, vec2_dir(target, transform.pos)*speed, moveBackwards, moveSprite)
}
//Call every frame to move the stage character (w/ proper sfx and animations). Useful in cutscenes.
//Can provide a raw speed vector or a target and speed. If you don't provide a target (or the target is moving), make sure to call stageCharacter_move_step_end when done moving.
stageCharacter_move_step :: proc{stageCharacter_move_step_speed, stageCharacter_move_step_target}

//Call after calling stageCharacter_move_step_speed. Zeroes speed and resets animation.
stageCharacter_move_step_end :: proc(ref:StageCharacterRef, endFacing:=Dir.none){
	self := stageCharacterRef_get(ref)
	stageCharacter_sprite_set(self) //resets the sprite
	if endFacing != .none do scface(self, endFacing)
	mover_zero(self.mover)
}

stageCharacter_find :: proc(id:string, unsafe:bool=false) -> ^StageCharacter{
	chars := coall_true(StageCharacter)
	for char in chars{
		if char.initID.s == id do return char
	}
	if unsafe do return nil
	else do panicf("No stage character with id '%s' found!", id)
}
scfind :: stageCharacter_find

stageCharacter_pos_set :: proc(ref:StageCharacterRef, pos:Vec2){
	self := stageCharacterRef_get(ref)
	transform_set(self.transform, pos)
}
scplace :: stageCharacter_pos_set

//sorts output by entity id produce a consistent order
stageCharacter_find_all :: proc(id:string, allocator:=context.temp_allocator) -> []^StageCharacter{
	out := make([dynamic]^StageCharacter, allocator)
	chars := coall_true(StageCharacter, true)
	for char in chars{
		if char.initID.s == id do append(&out, char)
	}
	shrink(&out)
	return out[:]
}

dirSprite_get :: proc(set:DirSprite, dir:Dir) -> ^Sprite{
	if s, ok := set.(^Sprite); ok do return s

	switch dir{
		case .left, .right, .none: return set.(DirSpriteSet).side
		case .up: return set.(DirSpriteSet).up
		case .down: return set.(DirSpriteSet).down
	}
	unreachable()
}

//Finds all three variants of a directional sprite based on a format string
dirSpriteSet_find :: proc(formatString:string) -> DirSpriteSet{
	return DirSpriteSet{
		sprite_find(format(formatString, "side")),
		sprite_find(format(formatString, "up")),
		sprite_find(format(formatString, "down")),
	}
}

stageCharacter_sprite_set_dirSprites :: proc(ref:StageCharacterRef, setSprites:..DirSprite, newFacing:Dir=.none){
	self := stageCharacterRef_get(ref)
	using self
	if(len(setSprites) == 0 || setSprites[0] == nil){
		stageCharacter_sprite_set_facing(self, newFacing)
		return
	}
	clear(&overrideSprites)
	for s in setSprites{
		append(&overrideSprites, s) 
	}
	overrideFacing = newFacing
	if(newFacing != .none) do stageCharacter_facing_set(self, newFacing)

	spriter_set(spriter, dirSprite_get(overrideSprites[0], facing))
}
stageCharacter_sprite_set_dirSprite :: #force_inline proc(ref:StageCharacterRef, sprite:DirSprite, newFacing:Dir=.none){
	stageCharacter_sprite_set_dirSprites(ref, sprite, newFacing=newFacing)
}
stageCharacter_sprite_set_facing :: proc(ref:StageCharacterRef, newFacing:Dir){
	self := stageCharacterRef_get(ref)
	using self
	clear(&overrideSprites)
	overrideFacing = newFacing
	if(newFacing != .none) do stageCharacter_facing_set(self, newFacing)
}
//Forces a stage character to use an animation, overrides normal animation behavior. Mainly for cutscenes. 
//Can pass a series of sprites to cycle through them in order. 
//Passing "nil" as the last sprite will disable the override when sprites are done playing.
stageCharacter_sprite_set :: proc{stageCharacter_sprite_set_dirSprites, stageCharacter_sprite_set_dirSprite, stageCharacter_sprite_set_facing}

//Can pass a slice of callback + frame number tuples to have stuff occur on a given sprite's frame.
stageCharacter_anim_seq :: proc(ref:StageCharacterRef, setSprites:..DirSprite, newFacing:=Dir.none, spriteFrameCallbacks:SpriteFrameCallbacks=nil, key:ImKey=#caller_location) -> bool{
	assertf(len(setSprites) > 1, "Tried to play a sequence of sprites on a stage character with only `%i` sprite(s)!", len(setSprites))
	self := stageCharacterRef_get(ref)
	if seq_open(key){
		if seq_cue(0){
			stageCharacter_sprite_set(self, setSprites=setSprites, newFacing=newFacing)
		}
		else{ //interrupt sequence if no override found or something else changes the character's sprites
			if len(self.overrideSprites) == 0 do return seq_close(.end)
			i:=0
			#reverse for spr in self.overrideSprites{
				checkInd := len(setSprites)-i-1
				if checkInd < 0 || setSprites[checkInd] != spr{
					return seq_close(.end)
				} 
				i+=1
			}
		}

		for callback in spriteFrameCallbacks{
			t := sprite_frame_time_get(dirSprite_get(callback.sprite, self.facing), callback.frame)
			for spr in setSprites{
				if spr != callback.sprite do t += sprite_duration_f(dirSprite_get(spr, self.facing))
				else do break
			}
			if seq_cue(t) do callback_call(callback.c)
		}

		lastSprite := peek(setSprites)
		if self.overrideSprites[0] == lastSprite{
			return seq_close(.end)
		}
	}
	return seq_close()
}
scanim :: stageCharacter_anim_seq

stageCharacter_sprite_get :: proc(using self:^StageCharacter) -> DirSprite{
	if(len(overrideSprites) > 0) do return overrideSprites[0]
	return nil
}

stageCharacter_facing_set :: proc(ref:StageCharacterRef, newFacing:Dir){
	assert(newFacing != .none, "Tried to set a stage character's facing direction to none!")
	self := stageCharacterRef_get(ref)
	switch self.facingMode{
		case .normal:
			self.facing = newFacing
			self.transform.scale.x = (newFacing == .left) ? -1 : 1

		case .sideOnly:
			switch newFacing{
				case .up, .down:
					self.facing = (self.transform.scale.x > 0) ? .right : .left 
				case .left, .right: 
					self.facing = newFacing
					self.transform.scale.x = (newFacing == .left) ? -1 : 1
				case .none: //unreachable
			}

		case .diagonal:
			switch newFacing{
				case .up:
					self.facing = newFacing
				case .down:
					self.facing = (self.transform.scale.x > 0) ? .right : .left 
				case .left, .right: 
					self.facing = newFacing
					self.transform.scale.x = (newFacing == .left) ? -1 : 1
				case .none: //unreachable
			}
		
		case .disabled:
			self.facing = .right
	}
}
stageCharacter_face_seq :: proc(ref:StageCharacterRef, newFacing:Dir, waitTime:int, key:ImKey=#caller_location) -> bool{
	if seq_open(key){
		if seq_cue(0) do stageCharacter_facing_set(ref, newFacing)
		if seq_time() >= waitTime{
			return seq_close(.end)
		}
	}
	return seq_close()
}
scface :: proc{stageCharacter_facing_set, stageCharacter_face_seq}

stageCharacter_shake :: proc(ref:StageCharacterRef, duration:int, force:Vec2){
	self := stageCharacterRef_get(ref)
	stageEntity_shake(self.stageEntity, duration, force)
	
}
stageCharacter_shake_seq :: proc(ref:StageCharacterRef, duration:int, force:Vec2, waitTime:int, audioEvent:AudioEvent=nil, key:ImKey=#caller_location) -> bool{
	if seq_open(key){
		if seq_cue(0){
			if audioEvent != nil do audio_play(audioEvent)
			stageCharacter_shake(ref, duration, force)
		}
		if seq_time() >= waitTime{
			return seq_close(.end)
		}
	}
	return seq_close()
}
scshake :: proc{stageCharacter_shake, stageCharacter_shake_seq}

stageCharacter_face_pos :: proc(ref:StageCharacterRef, target:Vec2){
	self := stageCharacterRef_get(ref)
	stageCharacter_facing_set(self, vec2_cardinal(target, self.transform.pos))
}
stageCharacter_face_stageCharacter :: proc(ref:StageCharacterRef, targetRef:StageCharacterRef){
	self := stageCharacterRef_get(ref)
	target := stageCharacterRef_get(targetRef)
	stageCharacter_facing_set(self, vec2_cardinal(target.transform.pos, self.transform.pos))
}
scface_other :: proc{stageCharacter_face_stageCharacter, stageCharacter_face_pos}

//Gets a stage character's position
stageCharacter_position :: proc(ref:StageCharacterRef, unsafe:=false)->Vec2{
	char := stageCharacterRef_get(ref, unsafe)
	if char != nil do return char.transform.pos
	return Vec2{}
}
scpos :: stageCharacter_position

_stageCharacter_process_event :: proc(base:^ComponentBase, event:Event, overrideDisabled:=false){
if(!overrideDisabled && event in base.disabledEvents) do return
last_context := entities.context_component
defer cowith(last_context)
cowith(base)
self := cast(^StageCharacter)base
using self
#partial switch event{
case .init:
	coadd(&mover)
	coadd(&spriter)
	coadd(&transform)
	coadd(&collider)
	coadd(&stageEntity)
	coadd(&stageInteractable)
	coadd(&audioEmitter)
	
	overrideFacing = .none
	stageInteractable.maskSprite = sp.characterTemplate
	collider_mask_set(collider, sp.characterTemplate)
	collider.collisionGroups = {.npcs}
	
	stageEntity.shadowKind = .dropShadowEllipse
	stageEntity.dropShadowRadii.y = 3
	stageEntity.static = false
case .loaded:
	stageCharacter_reload(self)
	if facing == .none{
		print("Warning: Cannot set stage character facing to none!")
		facing = .right
	}
	scface(self, facing)


case .updateEditor:
	spriter_set(spriter, dirSprite_get(sprites.idle, facing), -1)
case .update: //@p -64
	if(overrideFacing == .none){
		if(mover.speed != 0){
			stageCharacter_facing_set(self, vec2_cardinal(mover.speed.xy))
		}
		else if facePlayer == .always{
			if player,ok := cofind(Player, 0); ok do stageCharacter_facing_set(self, vec2_cardinal(player.transform.pos, transform.pos))
		}
	}
	else do stageCharacter_facing_set(self, overrideFacing)

	if(len(overrideSprites) != 0){
		if(spriter.animEnded && len(overrideSprites) > 1){
			ordered_remove(&overrideSprites, 0)
			if(overrideSprites[0] == nil){
				stageCharacter_sprite_set_dirSprites(self) //clear override sprite and facing
				spriter_set(spriter, dirSprite_get(sprites.idle, facing))
			}
			else do spriter_set(spriter, dirSprite_get(overrideSprites[0], facing))
		}
		else do spriter_set(spriter, dirSprite_get(overrideSprites[0], facing), -1)
	}
	else{
		colH,colV:bool
		if cofind(Player) != nil{
			#partial switch facing{
				case .left, .right:
					if mover.collided.x do colH = true
					else if mover.speed.x != 0{
						newPos := transform.pos + Vec2{sign(mover.speed.x), 0}
						colH = 	collision_stage(collider, newPos, PLAYER_COLLISION_BLACKLIST) && 
								collision_stage(collider, newPos + {0,1}, PLAYER_COLLISION_BLACKLIST) && 
								collision_stage(collider, newPos + {0,-1}, PLAYER_COLLISION_BLACKLIST)
					}
				case .up, .down:
					if mover.collided.y do colV = true
					else if mover.speed.y != 0{
						newPos := transform.pos + Vec2{0, sign(mover.speed.y)}
						colH = 	collision_stage(collider, newPos, PLAYER_COLLISION_BLACKLIST) && 
								collision_stage(collider, newPos + {1,0}, PLAYER_COLLISION_BLACKLIST) && 
								collision_stage(collider, newPos + {-1,0}, PLAYER_COLLISION_BLACKLIST)
					}
			}

		}

		if(mover.speed.xy != {0,0} && !(colH || colV)){
			spriter_set(spriter, dirSprite_get(dashing ? sprites.dash : sprites.walk, facing), -1)
			footstep_sounds(self)
		}
		else do spriter_set(spriter, dirSprite_get(sprites.idle, facing), -1)
	}

	//misc visuals
	stageEntity.dropShadowRadii.x = stageEntity_draw_rect(stageEntity).size.x/2

case .clean:
	estring_delete(&initID)

}}
