package massimodin //@nested-tags:libraries/collections

import "core:mem"
import "base:builtin"
import "core:container/priority_queue"
import slices "core:slice"
import "core:strings"
import "base:intrinsics"

bs64 :: bit_set[0..<64; u64]

len_fixed_array :: #force_inline proc "contextless" (array:[$N]$T) -> int{
	return N
}
len_array :: #force_inline proc "contextless" (array: $T/[dynamic]$E) -> int{
	return builtin.len(array)
}
len_fixed_capacity :: #force_inline proc "contextless" (array: $T/[dynamic; $N]$E) -> int{
	return builtin.len(array)
}
len_fixed_capacity_ptr :: #force_inline proc "contextless" (array: ^$T/[dynamic; $N]$E) -> int{
	return builtin.len(array)
}
len_soa_array :: #force_inline proc "contextless" (array: $T/#soa[dynamic]$E) -> int{
	return builtin.len(array)
}
len_soa_slice :: #force_inline proc "contextless" (slice: $T/#soa[]$E) -> int{
	return builtin.len(slice)
}
len_array_ptr :: #force_inline proc "contextless" (array: ^$T/[dynamic]$E) -> int{
	return builtin.len(array)
}
len_slice :: #force_inline proc "contextless" (slice: $T/[]$E) -> int{
	return builtin.len(slice)
}
len_map :: #force_inline proc "contextless" (m:map[$K]$E) -> int{
	return builtin.len(m)
}
len_string :: #force_inline proc "contextless" (s:string) -> int{
	return builtin.len(s)
}
len_cstring :: #force_inline proc "contextless" (s:cstring) -> int{ //not added to overload to prevent ambiguity with string literals
	return builtin.len(s)
}
len_enum :: #force_inline proc "contextless" ($E:typeid) -> int where intrinsics.type_is_enum(E){
	return builtin.len(E)
}

len :: proc{
	len_fixed_array,
	len_array,
	len_fixed_capacity,
	len_fixed_capacity_ptr,
	len_soa_array,
	len_soa_slice,
	len_array_ptr,
	len_slice,
	len_map,
	len_string,
	priority_queue.len,
	len_enum,
}

append :: proc{
	append_elem,
	append_elems,
	append_soa_elem,
	append_soa_elems,
	append_fixed_capacity_elem,
	append_fixed_capacity_elems,
	append_string,
	priority_queue.push,
}

clear :: proc{
	clear_dynamic_array,
	clear_fixed_capacity_dynamic_array,
	clear_map,
	priority_queue.clear,
}

remove :: proc{
	ordered_remove_dynamic_array,
	ordered_remove_fixed_capacity_dynamic_array,
	priority_queue.remove,
}

remove_unordered :: proc{
	unordered_remove_dynamic_array,
	unordered_remove_fixed_capacity_dynamic_array,
}

resize :: proc{
	resize_dynamic_array,
	resize_fixed_capacity_dynamic_array,
	resize_soa
}

//return the last element of an array
peek_array :: #force_inline proc "contextless" (array: $T/[dynamic]$E) -> E{
	return array[len(array)-1]
}
peek_slice :: #force_inline proc "contextless" (slice: $T/[]$E) -> E{
	return slice[len(slice)-1]
}
peek_fixed_capacity :: #force_inline proc "contextless" (array: $T/[dynamic; $N]$E) -> E{
	return array[builtin.len(array)-1]
}
peek :: proc{peek_array, peek_slice, peek_fixed_capacity}

peek_ptr_array :: #force_inline proc "contextless" (array: ^$T/[dynamic]$E) -> ^E{
	return &array[len(array)-1]
}
peek_ptr_slice :: #force_inline proc "contextless" (slice: $T/[]$E) -> ^E{
	return &slice[len(slice)-1]
}
peek_ptr_fixed_capacity :: #force_inline proc "contextless" (array: ^$T/[dynamic; $N]$E) -> ^E{
	return &array[builtin.len(array)-1]
}
peek_ptr :: proc{peek_ptr_array, peek_ptr_slice, peek_ptr_fixed_capacity}

pop_array :: #force_inline proc(array: ^$T/[dynamic]$E, loc := #caller_location) -> E{
	return builtin.pop(array, loc)
}
pop_fixed_capacity :: #force_inline proc(array: ^$T/[dynamic; $N]$E, loc := #caller_location) -> E{
	return builtin.pop(array, loc)
}
pop :: proc{
	pop_array,
	pop_fixed_capacity,
	priority_queue.pop,
}

pop_front_array :: #force_inline proc(array: ^$T/[dynamic]$E, loc := #caller_location) -> E{
	return builtin.pop_front(array, loc)
}
pop_front :: proc{
	pop_front_array,
}

reset_array :: #force_inline proc(array: ^$T/[dynamic]$E, loc:=#caller_location){
	raw := cast(^mem.Raw_Dynamic_Array)array
	alloc := raw.allocator
	delete(array^)
	init(array, alloc)
}
reset_map :: #force_inline proc(m:^map[$K]$E){
	raw := cast(^mem.Raw_Map)m
	alloc := raw.allocator
	delete(m^)
	init(m, alloc)
}
//Resets an array or map, freeing its memory and reinitializing it elsewhere
reset :: proc{reset_array, reset_map}

find_in_array :: proc "contextless"(array: $T/[dynamic]$E, val:E) -> (ind:int, found:bool){
	for v, i in array{
		if(v == val) do return i, true
	}
	return -1, false
}
find_in_slice :: proc "contextless"(slice: $T/[]$E, val:E) -> (ind:int, found:bool){
	for v, i in slice{
		if(v == val) do return i, true
	}
	return -1, false
}
find :: proc{find_in_array, find_in_slice}

contained_in_array :: proc "contextless"(array: $T/[dynamic]$E, val:E) -> bool{
	for v, i in array{
		if(v == val) do return true
	}
	return false
}
contained_in_slice :: proc "contextless"(slice: $T/[]$E, val:E) -> bool{
	for v, i in slice{
		if(v == val) do return true
	}
	return false
}
contains :: proc{contained_in_array, contained_in_slice}

init_dynamic_array :: #force_inline proc(array: ^$T/[dynamic]$E, allocator:=context.allocator, loc:=#caller_location){
	array^ = make_dynamic_array(T, allocator, loc)
}
init_dynamic_array_len :: #force_inline proc(array: ^$T/[dynamic]$E, len:int, allocator:=context.allocator, loc:=#caller_location){
	array^ = make_dynamic_array_len(T, len, allocator, loc)
}
init_dynamic_array_len_cap :: #force_inline proc(array: ^$T/[dynamic]$E, len,cap:int, allocator:=context.allocator, loc:=#caller_location){
	array^ = make_dynamic_array_len_cap(T, len, cap, allocator, loc)
}
init_soa_dynamic_array :: #force_inline proc(array: ^$T/#soa[dynamic]$E, allocator:=context.allocator, loc:=#caller_location){
	array^ = make_soa_dynamic_array(T, allocator, loc)
}
init_soa_dynamic_array_len :: #force_inline proc(array: ^$T/#soa[dynamic]$E, len:int, allocator:=context.allocator, loc:=#caller_location){
	array^ = make_soa_dynamic_array(T, allocator, loc) //done this way to avoid bug where incorrect error is thrown with allocators that can't free
	reserve_soa(array, len)
	resize_soa(array, len)
}
init_soa_dynamic_array_len_cap :: #force_inline proc(array: ^$T/#soa[dynamic]$E, len,cap:int, allocator:=context.allocator, loc:=#caller_location){
	array^ = make_soa_dynamic_array(T, allocator, loc)
	reserve_soa(array, cap)
	resize_soa(array, len)
}
init_map :: #force_inline proc(m: ^map[$K]$E, allocator:=context.allocator, loc:=#caller_location){
	m^ = make_map(map[K]E, allocator, loc)
}
init_map_cap :: #force_inline proc(m: ^map[$K]$E, cap:int, allocator:=context.allocator, loc:=#caller_location){
	m^ = make_map_cap(map[K]E, cap, allocator, loc)
}
init :: proc{
	init_dynamic_array,
	init_dynamic_array_len,
	init_dynamic_array_len_cap,
	init_soa_dynamic_array,
	init_soa_dynamic_array_len,
	init_soa_dynamic_array_len_cap,
	init_map,
	init_map_cap,
	pqueue_init,
	grid_init,
}


//Wraps a slice in a dynamic array struct.
//Does not make a copy; be sure to pass the same allocator that was used to allocate the slice.
slice_to_array :: proc(a: $T/[]$E, allocator:=context.allocator) -> [dynamic]E {
	s := transmute(mem.Raw_Slice)a
	d := mem.Raw_Dynamic_Array{
		data = s.data,
		len  = s.len,
		cap  = s.len,
		allocator = allocator,
	}
	return transmute([dynamic]E)d
}


slice_from_ptr :: slices.from_ptr
slice_equal :: slices.equal
slice_to_bytes :: slices.to_bytes

sort_slice :: slices.sort_by
sort_array :: #force_inline proc(array:^$T/[dynamic]$E, less:proc(a,b:E)->bool){
	sort_slice(array[:], less)
}
/*
Return (in the "less" proc):
	a < b for ascending,
	a > b for descending
*/
sort :: proc{sort_slice, sort_array}

sort_slice_stable :: slices.stable_sort_by
sort_array_stable :: #force_inline proc(array:^$T/[dynamic]$E, less:proc(a,b:E)->bool){
	sort_slice_stable(array[:], less)
}
/*
Return (in the "less" proc):
	a < b for ascending
	a > b for descending
*/
sort_stable :: proc{sort_slice_stable, sort_array_stable}

sort_general_slice :: slices.sort
sort_general_array :: #force_inline proc(array:^$T/[dynamic]$E){
	sort_general_slice(array[:])
}
//Sorts without requiring a specific sorting proc, will use reasonable defaults. Useful for arrays of primitves like strings and numbers
sort_general :: proc{sort_general_slice, sort_general_array}

clone :: proc{strings.clone, slices.clone}

array_set_elems :: #force_inline proc "contextless" (array:^$T/[dynamic]$E, newVal:..E){
	resize(array, len(newVal))
	copy(array[:], newVal)
}
set_fixed_capacity :: #force_inline proc (array:^$T/[dynamic; $N]$E, newVal:..E){
	newLen := builtin.len(newVal)
	when !ODIN_NO_BOUNDS_CHECK do assertf(newLen <= N, "Tried to set a fixed-capacity array of capacity %v with a slice of length %v", N, newLen)

	builtin.resize(array, newLen)
	copy(array[:], newVal)
}
set :: proc{array_set_elems, set_fixed_capacity}

map_keys :: slices.map_keys
