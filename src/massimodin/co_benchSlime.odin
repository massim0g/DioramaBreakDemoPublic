#+feature using-stmt
package massimodin //@nested-tags:_components/debug
//@nested-tags:debug

BenchSlime :: struct{
	using base:ComponentBase,
	walkDir:Vec2,
	walkSpeed:f32,
	spinSpeed:f32,
	spriter:CoRef(Spriter),
	transform:CoRef(Transform),
	collider:CoRef(Collider),
	stageEntity:CoRef(StageEntity),
	actionTimer:CoRef(Timer)
}

benchSlime_switch_state :: proc(){
	self,_ := cofind(BenchSlime)
	using self
	
	switch(spriter.mySprite){
		case sp.slimeWalk_loop:
			spriter_set(spriter, choose([]^Sprite{sp.slimeGenericAttack_loop, sp.slimeIdle_loop}))
		case sp.slimeIdle_loop:
			spriter_set(spriter, choose([]^Sprite{sp.slimeGenericAttack_loop, sp.slimeWalk_loop}))
		case sp.slimeGenericAttack_loop:
			spriter_set(spriter, choose([]^Sprite{sp.slimeWalk_loop, sp.slimeIdle_loop}))
	}

	walkDir = vec2_random()
	 
	timer_start(
		actionTimer, 
		spriter.mySprite == sp.slimeGenericAttack_loop ? sprite_duration_f(sp.slimeGenericAttack_loop, .frames) : f32(random_range(45, 150))
	)
}

_benchSlime_process_event :: proc(base:^ComponentBase, event:Event, overrideDisabled:=false){
if(!overrideDisabled && event in base.disabledEvents) do return
last_context := entities.context_component
defer cowith(last_context)
cowith(base)
self := cast(^BenchSlime)base
using self
#partial switch event{
case .init:
	walkSpeed = random_range_f(1, 2)
	coadd(&spriter)
	coadd(&transform)
	coadd(&collider)
	coadd(&stageEntity)
	collider_mask_set(collider, sp.slimeIdle_loop)

	scale := random_range_f(1, 2)
	scale = choose([]f32{scale, 1/scale})
	//spriter.scale = Vec2{scale*choose([]f32{-1, 1}), scale}
	//spinSpeed = choose([]f32{0, random_range(-5, 5)})
	spriter_set(spriter, sp.slimeIdle_loop)

	transform_set(transform, Vec2{DISPLAY_WIDTH/2, DISPLAY_HEIGHT/2}+vec2_random()*random_range_f(0, 100))

	timer_add(&actionTimer, 1, benchSlime_switch_state)
	timer_start(actionTimer)
	
case .update:
	newPos := transform.pos
	
	if(spriter.mySprite == sp.slimeWalk_loop){
		newPos += walkDir*walkSpeed
	}
	
	if(newPos.x > DISPLAY_WIDTH) do newPos.x -= DISPLAY_WIDTH
	if(newPos.x < 0) do newPos.x += DISPLAY_WIDTH
	if(newPos.y > DISPLAY_HEIGHT) do newPos.y -= DISPLAY_HEIGHT
	if(newPos.y < 0) do newPos.y += DISPLAY_HEIGHT

	newPos = round(newPos)
	if(!collision(collider, newPos, Player)) do transform_set(transform, newPos)

	//spriter.depth = -int(newPos.y)
	//spriter.angle += spinSpeed
	if(ginputs[.cancel] && roll(0.5)) do entity_destroy(entity)

}}
