#+feature using-stmt
package massimodin //@nested-tags:_components/

SpriteEffect :: struct{
	using base:ComponentBase,
	stageEntity:CoRef(StageEntity),
	spriter:CoRef(Spriter),
	transform:CoRef(Transform),
	mover:CoRef(Mover),
	update:proc(self:^SpriteEffect),
	movement:EffectMovement,
	startPos:Vec3,
	timeRemaining:f32,
	duration:f32,
	destroy:bool
}

EffectMovementCurves :: struct{
	offset:Vec3,
	curves:[3]^Curve
}

EffectMovementAcceleration :: struct{
	initialSpeed:Vec3,
	acceleration:Vec3
}

//used to define an entire simple movement when spawning stuff like text or sprite effects
EffectMovement :: union{
	EffectMovementAcceleration,
	EffectMovementCurves,
}

effectMovement_init :: proc(movement:EffectMovement, mover:^Mover, startPos:^Vec3){
	if movement == nil do return
	switch m in movement{
		case EffectMovementAcceleration:
			mover.speed = m.initialSpeed.xy
			mover.zSpeed = m.initialSpeed.z
		case EffectMovementCurves:
			startPos^ = transmute(Vec3)mover.transform.coords
	}
}

effectMovement_apply :: proc(movement:EffectMovement, mover:^Mover, startPos:Vec3, progress:f32){
	if movement == nil do return	
	switch m in movement{
		case EffectMovementAcceleration:
			mover.speed += m.acceleration.xy
			mover.zSpeed += m.acceleration.z
			mover_update_pre_collision(mover)
			transform_add(mover.transform, mover.baseSpeed)
		case EffectMovementCurves:
			endPos := startPos + m.offset
			mover.transform.x = round(lerp(startPos.x, endPos.x, progress, m.curves.x))
			mover.transform.y = round(lerp(startPos.y, endPos.y, progress, m.curves.y))
			mover.transform.z = round(lerp(startPos.z, endPos.z, progress, m.curves.z))
	}
}

spriteEffect_make :: proc(spr:^Sprite, pos:Vec2, z:f32=0, duration:f32=-1, frame:=-1, animSpeed:f32=1, scale:=Vec2{1,1}, angle:f32=0, color:Color=COLOR_WHITE, alpha:f32=1, blendmode:=BlendMode.blend, movement:EffectMovement=nil, destroy:=true, depthOffset:f32=0, depthKind:=StageEntityDepthKind.origin) -> ^SpriteEffect{
	out := entity_make(SpriteEffect)

	spriter_set(out.spriter, spr)

	out.transform.coords = {pos, z}
	out.stageEntity.editableDepthOffset = depthOffset
	out.stageEntity.depthKind = depthKind

	if duration == INF{
		out.duration = INF
		out.timeRemaining = -1
	}
	else{
		if duration < 0 do out.duration = floor(sprite_duration_f(spr, .frames)/animSpeed)
		else do out.duration = floor(duration)
		out.timeRemaining = out.duration
	}

	if frame != -1 do spriter_frame_set(out.spriter, frame)

	out.stageEntity.defaultAnimSpeed = animSpeed
	out.spriter.animSpeed = animSpeed

	out.transform.scale = scale
	out.transform.angle = angle

	out.stageEntity.blendData = {color, alpha, blendmode}

	out.movement = movement
	effectMovement_init(movement, out.mover, &out.startPos)

	out.destroy = destroy

	return out
}

spriteEffect_find :: proc(spr:^Sprite, unsafe:=false) -> ^SpriteEffect{
	effects := coall_true(SpriteEffect)
	for e in effects{
		if e.spriter.mySprite == spr do return e
	}
	assertf(unsafe, "Sprite Effect for sprite '%s' not found!", spr.name)
	return nil
}

_spriteEffect_process_event :: proc(base:^ComponentBase, event:Event, overrideDisabled:=false){
if(!overrideDisabled && event in base.disabledEvents) do return
last_context := entities.context_component
defer cowith(last_context)
cowith(base)
self := cast(^SpriteEffect)base
using self
#partial switch event{
case .init:
	coadd(&stageEntity)
	coadd(&transform)
	coadd(&mover)
	coadd(&spriter)
	stageEntity.static = false
case .update:
	if spriter.animSpeed == 0 && stageEntity.defaultAnimSpeed != 0 do return 
	if timeRemaining == 0 && destroy{
		entity_destroy(self)
		return
	}
	
	effectMovement_apply(movement, mover, startPos, 1 - timeRemaining/duration)

	if update != nil do update(self)

	timeRemaining -= 1
}}
