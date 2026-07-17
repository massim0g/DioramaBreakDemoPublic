#+no-instrumentation
package massimodin //@nested-tags:libraries/math

import "core:math/rand"
import uuids "core:encoding/uuid"


random_f :: proc(max:f32=1) -> f32{
	return max*rand.float32()
}
random_i :: rand.int_max
random_u64 :: rand.uint64
random :: proc{random_f, random_i}

random_range_f :: proc(low,high:f32, gen:=context.random_generator) -> f32{
	if(low >= high) do return low
	return rand.float32_range(low, high, gen)
}
//'high' is inclusive
random_range_i :: proc(low,high:int, gen:=context.random_generator) -> int{
	if(low >= high) do return low
	return random_i(high+1-low, gen)+low
}
random_range :: proc{random_range_f, random_range_i}

random_set_seed :: proc(seed:u64){
	rand.reset(seed)
}

//Randomly returns true with given probability p
roll :: proc(p:f32) -> bool{
	assert(p >= 0 && p <= 1, "Probability for roll was out of range [0, 1]!")
	return rand.float32() < p
}
choose :: rand.choice 

//returns -1 or 1 at 50/50 odds
random_flip :: #force_inline proc()->f32{
	return f32(random_i(2)*2-1)
}

uuid :: uuids.Identifier


uuid_make :: proc() -> (result:uuid){
	bytes_generated := rand.read(result[:])
	assert(bytes_generated == 16, "RNG failed to generate 16 bytes for UUID v4.")

	result[uuids.VERSION_BYTE_INDEX] &= 0x0F
	result[uuids.VERSION_BYTE_INDEX] |= 0x40

	result[uuids.VARIANT_BYTE_INDEX] &= 0x3F
	result[uuids.VARIANT_BYTE_INDEX] |= 0x80

	return
}

uuid_make_string :: proc(allocator:=context.allocator) -> string{
	out := uuids.to_string(uuid_make(), allocator)
	out,_ = string_replace_all(out, "-", "_") //replace dashes with underscores for better alphanumeric compatability
	return out
}

RandomState :: rand.PCG_Random_State
random_state_get :: proc()->RandomState{
	return (cast(^RandomState)context.random_generator.data)^
}
random_state_set :: proc(r:RandomState){
	(cast(^RandomState)context.random_generator.data)^ = r
}

RNG :: struct{
	using gen:rand.Generator,
	alloc:Allocator
}
rng_make :: proc(allocator:=context.temp_allocator) -> RNG{
	state := new(rand.PCG_Random_State, allocator)
	gen := rand.pcg_random_generator(state)
	rand.reset(u64(rand.int63()), gen)
	return RNG{
		gen,
		allocator
	}
}

rng_destroy :: proc(rng:RNG){
	free(cast(^rand.PCG_Random_State)rng.data, rng.alloc)
}

get_random_elem :: #force_inline proc(s:[]$T)->T{
	return s[random(len(s))]
}