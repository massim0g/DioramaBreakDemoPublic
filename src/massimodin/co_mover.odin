#+feature using-stmt
package massimodin //@nested-tags:_components/

//Handle subpixel movement for an entity
Mover :: struct{
	using base:ComponentBase,
	transform:CoRef(Transform),
	speed:Vec2,
	zSpeed:f32,
	fractionalSpeed:Vec3,
	baseSpeed:Vec3, //vec for simplicity, but should only hold int values
	collided:[2]bool
}

mover_update_pre_collision :: proc(using self:^Mover){
	totalSpeed := Vec3{speed.x, speed.y, zSpeed}+fractionalSpeed
	baseSpeed, fractionalSpeed = split(totalSpeed)
	collided = {false, false}
}

//Applies a mover's basespeed to a transform, call in an update loop after pre-collision update and collision. Defaults to using the mover's attached transform. 
mover_apply :: proc(mover:^Mover, transform:^Transform=nil){
	transform := transform 
	if transform == nil do transform = mover.transform
	transform_add(transform, mover.baseSpeed)
}

mover_zero :: proc(using self:^Mover, zeroX:=true, zeroY:=true, zeroZ:=true){
	mul := Vec3(cast([3]int)[3]bool{!zeroX, !zeroY, !zeroZ})
	speed *= mul.xy
	zSpeed *= mul.z
	fractionalSpeed *= mul
	baseSpeed *= mul
}

//adjusts
mover_collide :: proc(mover:^Mover, collider:^Collider, pos:^Vec2, blacklist:=ColliderGroupMask{}){
	newPos := pos^
	signSpeed := sign(mover.baseSpeed.xy)
	absSpeed := abs(mover.baseSpeed.xy)

	slopeRange :: 1 //size of steepest slope segment the player will slide along

	//vertical movement
	for i in 0..<absSpeed.y{
		newPos.y += signSpeed.y

		if collision_stage(collider, newPos, blacklist){
			if !collision_stage(collider, {newPos.x-slopeRange,newPos.y}, blacklist){
				newPos.x -= slopeRange
				continue
			}
			if !collision_stage(collider, {newPos.x+slopeRange,newPos.y}, blacklist){
				newPos.x += slopeRange
				continue
			} 

			newPos.y -= signSpeed.y
			pos.y = newPos.y
			mover_zero(mover, false, true)
			mover.collided.y = true
			break
		}
	}

	//horizontal movement
	for i in 0..<absSpeed.x{
		newPos.x += signSpeed.x
		if collision_stage(collider, newPos, blacklist){
			if !collision_stage(collider, {newPos.x,newPos.y-slopeRange}, blacklist){
				newPos.y -= slopeRange
				continue
			}
			if !collision_stage(collider, {newPos.x,newPos.y+slopeRange}, blacklist){
				newPos.y += slopeRange
				continue
			} 

			newPos.x -= signSpeed.x
			pos.x = newPos.x
			mover_zero(mover, true, false)
			mover.collided.x = true
			break
		}
	}

	mover.baseSpeed.xy = newPos - pos^
}

mover_collided :: proc(using mover:^Mover, checkX:=true, checkY:=true)->bool{
	return (collided.x && checkX) || (collided.y && checkY)
}

_mover_process_event :: proc(base:^ComponentBase, event:Event, overrideDisabled:=false){
if(!overrideDisabled && event in base.disabledEvents) do return
last_context := entities.context_component
defer cowith(last_context)
cowith(base)
self := cast(^Mover)base
using self
#partial switch event{
	case .init: coadd(&transform)

}}
