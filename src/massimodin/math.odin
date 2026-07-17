#+no-instrumentation
package massimodin //@nested-tags:libraries/math

import "base:builtin"
import "core:math"
import "core:math/linalg"
import "base:intrinsics"

pow :: math.pow_f32
sqrt :: math.sqrt
mod :: math.mod
floor :: proc{math.floor_f32, linalg.floor}
ceil :: proc{math.ceil_f32, linalg.ceil}
round :: proc{math.round_f32, linalg.round}
abs :: linalg.abs
clamp :: linalg.clamp
next_power_of_2 :: math.next_power_of_two

sign_i :: #force_inline proc "contextless" (n:int) -> int{
	return int(n!=0)*(int(n > 0)*2 - 1)
}
sign_vec :: proc "contextless" (v: $A/[$N]$T) -> A{
	out:A
	for i in 0..<N {
		out[i] = #force_inline sign(v[i])
	}
	return out
}
sign :: proc{math.sign_f32, sign_i, sign_vec}

signi_f :: #force_inline proc "contextless" (n:f32) -> int{
	return int(math.sign_f32(n))
}
signi_vec :: #force_inline proc "contextless" (v: $A/[$N]$T) -> [N]int{
	return linalg.array_cast(linalg.sign(v), int)
}
//cast sign to int
signi :: proc{signi_f, signi_vec}



roundi_f :: #force_inline proc "contextless" (n:f32) -> int{
	return int(math.round_f32(n))
}
roundi_linalg :: #force_inline proc "contextless" (v: $A/[$N]$T) -> [N]int{
	return linalg.array_cast(linalg.round(v), int)
}
//round and cast to int
roundi :: proc{roundi_f, roundi_linalg}

floori_f :: #force_inline proc "contextless" (n:f32) -> int{
	return int(math.floor_f32(n))
}
floori_linalg :: #force_inline proc "contextless" (v: $A/[$N]$T) -> [N]int{
	return linalg.array_cast(linalg.floor(v), int)
}
//floor and cast to int
floori :: proc{floori_f, floori_linalg}

ceili_f :: #force_inline proc "contextless" (n:f32) -> int{
	return int(math.ceil_f32(n))
}
ceili_linalg :: #force_inline proc "contextless" (v: $A/[$N]$T) -> [N]int{
	return linalg.array_cast(linalg.ceil(v), int)
}
//ceil and cast to int
ceili :: proc{ceili_f, ceili_linalg}

split_f :: math.modf_f32
split_vec :: #force_inline proc "contextless" (v:$A/[$N]$T) -> (integer:[N]T, frac:[N]T){
	for i in 0..<N{
		integer[i], frac[i] = math.split_decimal(v[i]) 
	}
	return
}
split :: proc{split_f, split_vec}

maxabs_i :: #force_inline proc "contextless" (a,b:int) -> int{
	return abs(a) >= abs(b) ? a : b
}
maxabs_f :: #force_inline proc "contextless" (a,b:f32) -> f32{
	return abs(a) >= abs(b) ? a : b
}
maxabs_vec :: proc "contextless" (a,b: $A/[$N]$T) -> A{
	out:A
	for i in 0..<N {
		out[i] = maxabs(a[i], b[i])
	}
	return out
}
maxabs :: proc{maxabs_f, maxabs_i, maxabs_vec}

log10 :: math.log10
pow10 :: math.pow10
min :: linalg.min
max :: linalg.max
int_max :: math.max
int_min :: math.min
INT_MAX :: builtin.max(int) //shorthand
INT_MIN :: builtin.min(int)
log :: math.log_f32
INF :: math.INF_F32

PI :: math.PI
TAU :: math.TAU

//dsin
sin :: #force_inline proc "contextless" (a:f32)->f32{
	return math.sin_f32(a/(180/PI))
}
//dcos
cos :: #force_inline proc "contextless" (a:f32)->f32{
	return math.cos_f32(a/(180/PI))
}
//dtan
tan :: #force_inline proc "contextless" (a:f32)->f32{
	return math.tan(a/(180/PI))
}

rsin :: math.sin
rcos :: math.cos
rtan :: math.tan

angle_to_rads :: #force_inline proc "contextless" (a:f32)->f32{ return a*0.0174532925199 } 

approach_f :: #force_inline proc "contextless" (current,target,amount:f32) -> f32{
	out:f32
	if(current < target){
		out = current + amount
		if(out >= target) do return target
	}
	else{
		out = current - amount
		if(out <= target) do return target
	}
	return out
}
approach_i :: #force_inline proc "contextless" (current,target,amount:int) -> int{
	out:int
	if(current < target){
		out = current + amount
		if(out >= target) do return target
	}
	else{
		out = current - amount
		if(out <= target) do return target
	}
	return out
}
approach_vec :: proc(current,target:$A/[$N]f32, amount:f32) -> [N]f32{
	out:[N]f32
	for i in 0..<N{
		out[i] = approach_f(current[i], target[i], amount)
	}
	return out
}
approach :: proc{approach_f, approach_i, approach_vec}


wrapi :: proc "contextless" (val:int, min:int, max:int) -> int{
	if(min >= max) do return min;

	incr := max-min+1;
	if(val > max) do return ((val-max) % incr) + min - 1;
	if(val < min) do return ((val-min) % incr) + max + 1;

	return val;
}
wrapf :: proc "contextless" (val:f32, min:f32, max:f32) -> f32{
	if(min >= max) do return min;

	incr := max-min+1;

	if(val > max) do return mod(val-max, incr) + min - 1;
	if(val < min) do return mod(val-min, incr) + max + 1;

	return val;
}
wrap_vec :: proc "contextless" (val:$A/[$N]$T, min:A, max:A) -> A{
	out:A
	for i in 0..<N {
		out[i] = wrap(val[i], min[i], max[i])
	}
	return out
}
/*
If val is outside min/max range, wraps it around.
e.g. if the range is 0-3 and the value is 6, returns 2 because:
input:	0 1 2 3 4 5 [6] 7
output:	0 1 2 3 0 1 [2] 3
Note that the range is INCLUSIVE (i.e. [0, 3]).
*/
wrap :: proc{wrapi, wrapf, wrap_vec}

in_range_i :: #force_inline proc "contextless" (val:int, min:int, max:int) -> bool{
	return val >= min && val <= max
}
in_range_f :: #force_inline proc "contextless" (val:f32, min:f32, max:f32) -> bool{
	return val >= min && val <= max
}
in_ranges_i :: proc "contextless" (val:int, ranges:[][2]int) -> bool{
	for r in ranges{
		if(in_range_i(val, r[0], r[1])) do return true
	}
	return false
}
in_ranges_f :: proc "contextless" (val:f32, ranges:[][2]f32) -> bool{
	for r in ranges{
		if(in_range_f(val, r[0], r[1])) do return true
	}
	return false
}

in_range :: proc{in_range_i, in_range_f, in_ranges_i, in_ranges_f}

lerp_val :: #force_inline proc "contextless" (a,b:f32, amount:f32) -> f32{
	return a*(1.0 - amount) + b*amount
}
lerp_arr :: proc "contextless" (a,b:[$N]f32, amount:f32) -> [N]f32{
	out:[N]f32
	for i in 0..<N {
		out[i] = lerp(a[i], b[i], amount)
	}
	return out
}
lerp_val_curve :: #force_inline proc "contextless" (a,b:f32, amount:f32, curve:^Curve) -> f32{
	return lerp_val(a,b,curve_eval(curve, amount))
}
lerp_arr_curve :: proc "contextless" (a,b:[$N]f32, amount:f32, curve:^Curve) -> [N]f32{
	return lerp_arr(a,b,curve_eval(curve, amount))
}
lerp :: proc{lerp_val, lerp_arr, lerp_val_curve, lerp_arr_curve}

wave_val :: proc "contextless" (from,to:f32, duration:f32, offset:f32=0, currentTime:f32=-1, timeUnit:=TIME_UNIT_DEFAULT) -> f32{
	currentTime:=currentTime
	if currentTime == -1{
		switch timeUnit{
			case .frames: currentTime = f32(time.frame)
			case .milliseconds: currentTime = time_get()
			case .seconds: currentTime = time_get()*1000
		}
	}

	amplitude := (to-from)/2

	return from + amplitude + amplitude*math.sin_f32(((currentTime + duration*(offset+0.75))/duration)*TAU) //adding 0.75 to offset makes it so we start at `from` when currentTime and offset equal 0 

}
wave_arr :: proc "contextless" (from,to:[$N]f32, duration:f32, offset:f32=0, currentTime:f32=-1, timeUnit:=TIME_UNIT_DEFAULT) -> [N]f32{
	out:[N]f32
	for i in 0..<N {
		out[i] = wave_val(from[i], to[i], duration, offset, currentTime, timeUnit)
	}
	return out
}
wave :: proc{wave_val, wave_arr}

wave_triangle :: proc "contextless" (from,to:f32, duration:f32, offset:f32=0, currentTime:f32=-1, timeUnit:=TIME_UNIT_DEFAULT) -> f32{
	currentTime:=currentTime
	if currentTime == -1{
		switch timeUnit{
			case .frames: currentTime = f32(time.frame)
			case .milliseconds: currentTime = time_get()
			case .seconds: currentTime = time_get()*1000
		}
	}

	period := duration/2
	return ((to - from)/period)*(period - abs(mod(currentTime + offset*duration, duration) - period)) + from;
}

remap_arr :: proc "contextless" (old_value, old_min, old_max, new_min, new_max: [$N]$T) -> [N]T{
	out:[N]T
	for i in 0..<N {
		out[i] = remap_val(old_value[i], old_min[i], old_max[i], new_min[i], new_max[i])
	}
	return out
}
remap_val_curve :: #force_inline proc "contextless" (val, oldMin, oldMax, newMin, newMax:f32, curve:^Curve) -> f32{
	return remap_val(curve_eval(curve, remap_val(val, oldMin, oldMax, 0, 1)), 0, 1, newMin, newMax)
}
remap_arr_curve :: proc "contextless" (val, oldMin, oldMax, newMin, newMax:[$N]f32, curve:^Curve) -> [N]f32{
	out:[N]f32
	for i in 0..<N {
		out[i] = remap_val_curve(val[i], oldMin[i], oldMax[i], newMin[i], newMax[i], curve)
	}
	return out
}
remap_val :: math.remap
remap :: proc{remap_val, remap_arr, remap_val_curve, remap_arr_curve}

//maps a value from 1-0 using a gaussian distribution. Higher k gives a sharper falloff
gauss_falloff :: proc(val: f32, k: f32=2.77) -> f32 {
    r := clamp(val, 0.0, 1.0);
    ek := math.exp(-k);
    return (math.exp(-k*r*r) - ek) / (1.0 - ek);
}
