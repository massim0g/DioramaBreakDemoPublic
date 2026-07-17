#+no-instrumentation
package massimodin //@nested-tags:libraries/math

import "core:math"
import "core:math/linalg"

Vec2 :: [2]f32
Vec3 :: [3]f32
Vec2i :: [2]int

VEC2I_MAX :: Vec2i{int_max(int), int_max(int)}
VEC2I_MIN :: Vec2i{int_min(int), int_min(int)}

Dir :: enum{
	none=-1,
	right=0,
	up=1,
	left=2, 
	down=3
}

CARDINAL_VEC2IS :: [4]Vec2i{{1,0},{0,-1},{-1,0},{0,1}}

Ray :: struct{
	pos:Vec2,
	dir:f32
}

vec2_normalize :: #force_inline proc "contextless" (v:Vec2) -> Vec2{
	mag := vec2_mag_get(v)
	if(mag == 0) do return v
	return v/mag
}
vec2_distance :: linalg.distance

vec2_manhattan_distance :: #force_inline proc "contextless" (v1, v2: $A/[2]$T) -> T{
	return abs(v1.x - v2.x) + abs(v1.y - v2.y)
}

vec2_sqr_mag_get :: #force_inline proc "contextless" (v:Vec2) -> f32{
	return v.x*v.x + v.y*v.y
}
vec2_mag_get :: #force_inline proc "contextless" (v:Vec2) -> f32{
	return sqrt(vec2_sqr_mag_get(v));
}

vec2_random_range :: #force_inline proc(low,high:f32) -> Vec2{
	return Vec2{random_range(low,high), random_range(low,high)}
}

vec2_random :: #force_inline proc() -> Vec2{ //returns a normalized vector pointing in a random direction
	return vec2_offset(random_f(360))
}

vec2f_dir :: #force_inline proc "contextless" (target,origin:Vec2) -> Vec2{
	return vec2_normalize(target-origin)
}
vec2i_dir :: #force_inline proc "contextless" (target,origin:Vec2i) -> Vec2{
	return vec2_normalize(Vec2(target-origin))
}
vec2_dir :: proc{vec2f_dir, vec2i_dir}

vec2f_cardinal :: #force_inline proc "contextless" (target:Vec2, origin:=Vec2{}) -> Dir{
	return angle_to_cardinal(vec2_angle(target-origin))
}
vec2i_cardinal :: #force_inline proc "contextless" (target:Vec2i, origin:=Vec2i{}) -> Dir{
	return angle_to_cardinal(vec2_angle(Vec2(target-origin)))
}
vec2_cardinal :: proc{vec2f_cardinal, vec2i_cardinal}

vec2_angle :: #force_inline proc "contextless" (v:Vec2) -> f32{
	a := math.atan2(-v.y, v.x)*(180/PI)
	if(a<0) do a += 360
	return a
}

vec2_cardinal_set :: #force_inline proc "contextless" (v:^Vec2, dir:Vec2){
	v^ = dir*vec2_mag_get(v^)
}

vec2_offset :: #force_inline proc "contextless" (angle:f32, distance:f32=1, origin:=Vec2{0,0}) -> Vec2{
	return Vec2{cos(angle), -sin(angle)}*distance + origin
}

angle_to_vec2 :: #force_inline proc "contextless" (a:f32)->Vec2{
	return Vec2{cos(a), -sin(a)}
}

vec2_approach :: proc(current,target:Vec2, amount:f32)->Vec2{
	dist := vec2_distance(target, current)
	dist = approach(dist, 0, amount)
	return target + dist*vec2_dir(current,target)
}

angle_to_cardinal :: #force_inline proc "contextless" (a:f32) -> Dir{
	switch a{
		case 45..<135: return .up
		case 135..<225: return .left
		case 225..<315: return .down
	}
	return .right
}
angle_to_cardinal_sticky :: #force_inline proc "contextless" (a:f32, currentDir:Dir, deadzone:f32=22.5) -> Dir{
	switch a{
		case 45-deadzone..=45+deadzone: if currentDir == .right || currentDir == .up do return currentDir
		case 135-deadzone..=135+deadzone: if currentDir == .up || currentDir == .left do return currentDir
		case 225-deadzone..=225+deadzone: if currentDir == .left || currentDir == .down do return currentDir
		case 315-deadzone..=315+deadzone: if currentDir == .down || currentDir == .right do return currentDir
	}

	return angle_to_cardinal(a)
}

cardinal_to_vec2 :: #force_inline proc(d:Dir) -> Vec2{
	switch d{
		case .none: return Vec2{}
		case .right: return Vec2{1, 0}
		case .up: return Vec2{0, -1}
		case .left: return Vec2{-1, 0}
		case .down: return Vec2{0, 1}
	}
	unreachable()
}
cardinal_to_vec2i :: #force_inline proc(d:Dir) -> Vec2i{
	switch d{
		case .none: return Vec2i{}
		case .right: return Vec2i{1, 0}
		case .up: return Vec2i{0, -1}
		case .left: return Vec2i{-1, 0}
		case .down: return Vec2i{0, 1}
	}
	unreachable()
}
cardinal_to_angle :: #force_inline proc(d:Dir) -> f32{
	return f32(d)*90
}

cardinal_reverse :: proc(d:Dir) -> Dir{
	switch d{
		case .right: return .left
		case .up: return .down
		case .left: return .right
		case .down: return .up
		case .none: return .none
	}
	unreachable()
}

vec2_cardinal_rotate :: proc(v:Vec2, amount:int, origin:Vec2) -> Vec2{
	amount := amount
	amount = wrap(amount, 0, 3);
	out := v-origin
	switch(amount){
		case 1: out = {out.y, -out.x}
		case 2: out = {-out.x, -out.y}
		case 3: out = {-out.y, out.x}
	}
	out += origin
	return out
}
vec2i_cardinal_rotate :: proc(v:Vec2i, amount:int, origin:Vec2i) -> Vec2i{
	amount := amount
	amount = wrap(amount, 0, 3);
	out := v-origin
	switch(amount){
		case 1: out = {out.y, -out.x}
		case 2: out = {-out.x, -out.y}
		case 3: out = {-out.y, out.x}
	}
	out += origin
	return out
}

vec2_rotate_around :: proc(v:Vec2, amount:f32, origin:=Vec2{}) -> Vec2{
	v := v
	v -= origin
	sinA := sin(-amount)
	cosA := cos(-amount)
	
	newPos := Vec2{
		v.x*cosA - v.y*sinA,
		v.x*sinA + v.y*cosA
	}

	return newPos + origin
}

vec2_dot :: linalg.vector_dot

//Sets a vector's angle to the nearest of a set of numbers
vec2_snap_to_angle :: proc(p:Vec2, origin:=Vec2{}, angleSnaps:[]f32={25.8, 45, 64.2, 90, 115.8, 135, 154.2, 180, 205.8, 225, 244.2, 270, 295.8, 315, 334.2, 360}) -> Vec2{
	normalP := p - origin
	angle := vec2_angle(normalP)
	snappedAngle :f32= 0
	for snap in angleSnaps{
		currentSnappedAngle := round(angle/snap)*snap
		if abs(currentSnappedAngle-angle) < abs(snappedAngle-angle){
			snappedAngle = currentSnappedAngle
		}
	}

	return vec2_offset(snappedAngle, vec2_mag_get(normalP), origin)
}

arc_projectile_pos :: proc "contextless"(startPos, highestPos, finalPos:[$N]f32, prog:f32) -> [N]f32 {
    progInv := 1 - prog

    // Quadratic Bezier:
    // B(u) = (1-u)^2 * P0 + 2(1-u)u * P1 + u^2 * P2
    return progInv*progInv*startPos + 2*progInv*prog*highestPos + prog*prog*finalPos
}

vec2_nearest :: proc(p:Vec2, points:..Vec2) -> Vec2{
	dist := INF
	out:Vec2
	for point in points{
		newDist := vec2_distance(p, point)
		if newDist < dist{
			out = point
			dist = newDist
		}
	}
	return out
}