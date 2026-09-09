#+feature using-stmt
package massimodin //@nested-tags:_components/collision
//@nested-tags:engine/collision

import "core:slice"
import "../sdl3"

Collider :: struct{
	using base:ComponentBase,
	using bounds:Rect,
	precisePoints:[dynamic][2]i16,
	transform:CoRef(Transform),
	baseSize:Vec2,
	origin:Vec2,
	basePrecisePoints:PrecisePoints,
	collisionGroups:ColliderGroupMask, //used only for blacklisting, does not need to be set to anything
	debugTex:Tex,
	debugTexPos:Vec2,
	maskInfo:union{
		^ColliderMask,
		^Sprite,
		Vec2,
		PrecisePoints
	} //tracks the last type of mask which was used to set the collider's data
}

ColliderMask :: struct{
	debugTex:Tex,//for debug visualization
	size:Vec2i, 
	origin:Vec2i, //keep at 0 for non-sprite masks, otherwise based on sprite origin
	precisePoints:PrecisePoints
}

PrecisePoints :: [][2]i16

ColliderGroupMask :: bit_set[ColliderGroup]
ColliderGroup :: enum{
	objects,
	npcs,
	pcs, //player and followers
	nonSolidInteractables
}

//adjusted for origin
collider_pos_get :: #force_inline proc(collider:^Collider) -> Vec2{
	return collider.pos + collider.origin
}

collider_mask_set_vec :: proc(collider:^Collider, size:Vec2, origin:Vec2=Vec2{}){
	collider_mask_set_precise_points(collider, nil)
	collider.baseSize = size
	collider.origin = origin
	_collider_update(collider)
	collider.maskInfo = size
}
collider_mask_set_f :: #force_inline proc(collider:^Collider, w,h:f32, origin:Vec2=Vec2{}){
	collider_mask_set_vec(collider, {w,h}, origin)
}
collider_mask_set_empty :: proc(collider:^Collider){
	collider_mask_set_vec(collider, {0,0})
	collider.maskInfo = nil
}
collider_mask_set_sprite :: #force_inline proc(collider:^Collider, sprite:^Sprite){
	if sprite == nil || sprite.mask == nil{
		collider_mask_set_empty(collider)
		return
	}
	collider_mask_set_mask(collider, sprite.mask)
	collider.maskInfo = sprite
}
collider_mask_set_mask :: proc(collider:^Collider, mask:^ColliderMask){
	if(len(mask.precisePoints) > 0){
		collider_mask_set_precise_points(collider, mask.precisePoints, Vec2(mask.origin), Vec2(mask.size))
	}
	else{
		collider_mask_set_vec(collider, Vec2(mask.size), Vec2(mask.origin))
	}
	when(DEBUG){
		collider.debugTex = mask.debugTex
	}

	collider.maskInfo = mask
}
collider_mask_set_precise_points :: proc(collider:^Collider, points:PrecisePoints, origin:Vec2=Vec2{}, size:Vec2={-1,-1}){
	collider.basePrecisePoints = points
	if(len(points) == 0) do return

	collider.origin = origin

	if(size.x<0 || size.y<0){
		newBounds := Rect{Vec2(points[0]), {1, 1}}
		for pi in points{
			p := Vec2(pi)
			rect_set_left(&newBounds, min(newBounds.x, p.x), true)
			rect_set_top(&newBounds, min(newBounds.y, p.y), true)
			rect_set_right(&newBounds, max(rect_get_right(newBounds), p.x), true)
			rect_set_bottom(&newBounds, min(rect_get_bottom(newBounds), p.y), true)
		}
		collider.baseSize = newBounds.size
	}
	else do collider.baseSize = size
	_collider_update(collider)

	collider.maskInfo = points
}
//Note: When setting a rect mask, the top-leftmost mask position will be subtracted from the provided origin
collider_mask_set :: proc{
	collider_mask_set_vec,
	collider_mask_set_f, 
	collider_mask_set_empty,
	collider_mask_set_precise_points,
	collider_mask_set_mask,
	collider_mask_set_sprite,
}

_collider_process_event :: proc(base:^ComponentBase, event:Event, overrideDisabled:=false){
if(!overrideDisabled && event in base.disabledEvents) do return
last_context := entities.context_component
defer cowith(last_context)
cowith(base)
self := cast(^Collider)base
using self
#partial switch event{
case .init:
	coadd(&transform, unique) //WARNING: Unique colliders can *only* be used to call a collision check, and will never turn up when checking with another collider. No deep reason, mostly for sanity's sake at the moment, change this behavior if absolutely needed
	assert(transform.attachedCollider._ptr == nil, "Tried to attach more than one collider to a transform!")
	coRef_init(&transform.attachedCollider, self, &transform.base)
	init(&precisePoints, 0, 0)
case .destroy:
	//todo: disable collider
case .clean:
	delete(precisePoints)
	regions := _collision_regions_get(bounds)
	exRef := crx(self)
	for region in regions{
		ind, found := slice.linear_search(region.colliders[:], exRef)
		if(found) do unordered_remove(&region.colliders, ind)
	}
}}
