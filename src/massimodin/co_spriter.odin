#+feature using-stmt
package massimodin //@nested-tags:_components/
//@nested-tags:engine/sprites

//Keeps track of a sprite's animation over time

Spriter :: struct{
	using base:ComponentBase,
	mySprite:^Sprite, //@e
	spriteFrameCallbacks:SpriteFrameCallbacks,
	lastFrame:int,
	animSpeed:f32,
	animProgress:f32, //in ms
	spriteDuration:f32,
	animEnded:bool, //flags whether the animation ended this frame
	disabled:bool //disables update behavior, mainly used by static entities for performance reasons
}

SpriteFrameCallbacks :: []struct{
	sprite:DirSprite,
	frame:int,
	c:Callback
}

spriter_frame_get :: #force_inline proc(spriter:^Spriter) -> int{
	return sprite_frame_get(spriter.mySprite, spriter.animProgress, false, TimeUnit.milliseconds)
}
spriter_frame_get_ptr :: #force_inline proc(spriter:^Spriter) -> ^SpriteFrame{
	return &spriter.mySprite.frames[spriter.lastFrame]
}
spriter_frame_set :: #force_inline proc(spriter:^Spriter, frame:int){
	spriter.lastFrame = frame
	spriter.animProgress = sprite_frame_time_get(spriter.mySprite, frame, TimeUnit.milliseconds)
}

spriter_origin :: #force_inline proc "contextless" (spriter:^Spriter)->Vec2{
	return Vec2{f32(spriter.mySprite.origin.x), f32(spriter.mySprite.origin.y)}
}

//Set newFrame to -1 to preserve animation progress
spriter_set :: proc(spriter:^Spriter, newSprite:^Sprite, newFrame:=0, updateMask:=false){
	using spriter

	if newSprite == nil || newSprite == sp.nil_{
		mySprite = sp.nil_
		animProgress = 0
		lastFrame = 0
		spriteDuration = 0
		return
	}
	
	newDuration := sprite_duration_f(newSprite, .milliseconds)
	if newFrame == 0{
		animProgress = 0
		mySprite = newSprite
		lastFrame = 0
		spriteDuration = newDuration
	}
	else if newFrame < 0{
		if(mySprite == newSprite) do return
		
		animProgress = remap(
			animProgress, 
			0, spriteDuration,
			0, newDuration
		)
		mySprite = newSprite
		lastFrame = spriter_frame_get(spriter)
		spriteDuration = newDuration
	}
	else{
		animProgress = sprite_frame_time_get(newSprite, newFrame, TimeUnit.milliseconds)
		mySprite = newSprite
		lastFrame = newFrame
		spriteDuration = newDuration
	}

	if updateMask{
		if collider,ok:=cofind(spriter, Collider);ok{
			collider_mask_set(collider, newSprite)
		}
	}
}

spriter_set_callbacks :: proc(spriter:^Spriter, callbacks:SpriteFrameCallbacks){
	for callback in spriter.spriteFrameCallbacks{callback_free(callback.c)}
	delete(spriter.spriteFrameCallbacks)
	spriter.spriteFrameCallbacks = clone(callbacks)
}

_spriter_process_event :: proc(base:^ComponentBase, event:Event, overrideDisabled:=false){
if(!overrideDisabled && event in base.disabledEvents) do return
last_context := entities.context_component
defer cowith(last_context)
cowith(base)
self := cast(^Spriter)base
using self
#partial switch event{
case .init:
	animSpeed = 1
	mySprite = sp.nil_
case .loaded:
	spriter_set(self, mySprite)

case .clean:
	for callback in spriteFrameCallbacks{callback_free(callback.c)}
	delete(spriteFrameCallbacks)
}
}

_spriters_bulk_update :: proc(){
	arr := coall(Spriter)
	for &self in arr{
		if self.disabled do continue

		using self

		animEnded = false

		if mySprite.pingPong{
			nextProg := animProgress + time.target_delta*animSpeed
			if (animSpeed > 0 && nextProg >= spriteDuration) || (animSpeed<0 && nextProg<0){
				animProgress = animSpeed > 0 ? spriteDuration - (nextProg - spriteDuration) : -nextProg
				animSpeed = -animSpeed
				animEnded = true
			}
			else do animProgress = nextProg
		}
		else{
			lastProg := animProgress
			animProgress = mod(animProgress + time.target_delta*animSpeed, spriteDuration)
			if animSpeed > 0 do animEnded = animProgress < lastProg
			else if animSpeed < 0 do animEnded = animProgress > lastProg
		}

		newFrame := spriter_frame_get(&self)
		if spriteFrameCallbacks != nil && newFrame != lastFrame{
			for callback in spriteFrameCallbacks{
				if callback.sprite == mySprite && callback.frame == newFrame do callback_call(callback.c)
			}
		}
		lastFrame = newFrame
	}
}
