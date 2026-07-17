#+feature using-stmt
package massimodin //@nested-tags:_components/

Wanderer :: struct{
	using base:ComponentBase,
	transform:CoRef(Transform),
	mover:CoRef(Mover),
	timer:CoRef(Timer),
	startingPos:Vec2,
	lockAxes:[2]bool,
	wanderTimings:struct{
		idle:[2]int,
		moving:[2]int
	},
	recallDistance:f32, //@e
	walkSpeed:f32, //@e
	disabled:bool
}

_wanderer_process_event :: proc(base:^ComponentBase, event:Event, overrideDisabled:=false){
if(!overrideDisabled && event in base.disabledEvents) do return
last_context := entities.context_component
defer cowith(last_context)
cowith(base)
self := cast(^Wanderer)base
using self
#partial switch event{
case .init:
	coadd(&transform)
	coadd(&mover)
	coadd(&timer, true)

	wanderTimings.idle = {25, 60}
	wanderTimings.moving = {15, 40}

	recallDistance = 16

	walkSpeed = 1.5

case .justMade:
	startingPos = transform.pos

case .update: //@p 64
	if player_dummy() || disabled{
		mover_zero(mover)
		return
	}

	if timer.state != .active{
		if mover.speed.xy != 0{
			mover_zero(mover)
			timer_start(timer, f32(random_range(wanderTimings.idle[0], wanderTimings.idle[1])))
		}
		else{
			moveDir:Vec2
			if vec2_distance(startingPos, transform.pos) >= recallDistance{
				moveDir = vec2_dir(startingPos, transform.pos)
			}
			else{
				moveDir = vec2_random()
				for &c, i in moveDir{
					if lockAxes[i] do c = 0
				}
				moveDir = vec2_normalize(moveDir)
			}

			mover.speed.xy = moveDir*walkSpeed

			timer_start(timer, f32(random_range(wanderTimings.moving[0], wanderTimings.moving[1])))
		}

	}

	//print(mover.speed, timer.state)
	mover_update_pre_collision(mover)
	if transform.attachedCollider._ptr != nil do mover_collide(mover, transform.attachedCollider, &transform.pos)
	mover_apply(mover)

}}
