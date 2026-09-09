package massimodin //@nested-tags:engine/metaprogramming

import "base:runtime"
import "core:reflect"
import "base:intrinsics"

SourceLocation :: runtime.Source_Code_Location

Callback :: union{
	proc(),
	CallbackStateful
}

CallbackStateful :: struct{
	wrapper:proc(self:CallbackStateful, freeState:bool),
	p:rawptr,
	state:rawptr,
	stateAllocator:Allocator
}

project_directory:string
executable_directory:string
thread_count:int
//for per-frame tasks
thread_count_optimum:int

equals :: proc "contextless" (val:$T, compareVals:..T) -> bool{
	for v in compareVals{
		if(val == v) do return true
	}
	return false
}

nil_proc :: proc(){} //do nothing

struct_set_by_field_offset :: #force_inline proc(s:^$T, offset:uintptr, val:$E){
	(cast(^E)(uintptr(s)+offset))^ = val
}
struct_set_by_field :: #force_inline proc(s:^$T, field:reflect.Struct_Field, val:$E){
	struct_set_by_field_offset(s, field.offset, val)
}
struct_set_by_var_name :: #force_inline proc(s:^$T, field:string, val:$E){
	struct_set_by_field_offset(s, reflect.struct_field_by_name(T, field).offset, val)
}
struct_set :: proc{struct_set_by_field_offset, struct_set_by_var_name, struct_set_by_field}

//Remember, union indices are 1-indexed by default (0 means nil)
union_variant_index_by_name :: proc($U:typeid, name:string) -> (ind:i64, found:bool){
	ti := reflect.type_info_base(type_info_of(U)).variant.(reflect.Type_Info_Union)

	for v,i in ti.variants{
		if named, ok := v.variant.(reflect.Type_Info_Named); ok && named.name == name do return i64(i)+i64(!ti.no_nil), true
	}

	return i64(!ti.no_nil)-1, false
}
union_variant_index :: reflect.get_union_variant_raw_tag

proc_call_delayed :: proc(callback:Callback, delay:f32, timeUnit:=TimeUnit.frames, persistent:=true){
	append(&time.delayed_callbacks, DelayedCallback{
		callback,
		roundi(time_convert(delay, timeUnit, .frames)),
		persistent?nil:stage.loaded
	})
}

_delayed_procs_update :: proc(){
	#reverse for &dc,i in time.delayed_callbacks{
		dc.timeRemaining -= 1
		if dc.timeRemaining <= 0{
			if equals(dc.calledStage, nil, stage.loaded) do callback_call(dc.c)
			unordered_remove(&time.delayed_callbacks, i)
		}
	}
}

//for making stateful callbacks
callback_make :: proc(p:proc(^$T), state:T, allocator:=context.allocator) -> CallbackStateful{
	wrapper :: proc(self:CallbackStateful, freeState:bool){
		p := cast(proc(^T))self.p
		state := cast(^T)self.state
		p(state)
		if freeState do free(self.state, self.stateAllocator)
	}

	statePtr := new(T, allocator)
	statePtr^ = state

	return CallbackStateful{
		wrapper,
		rawptr(p),
		statePtr,
		allocator
	}
}

callback_call :: proc(callback:Callback, freeState:=true){
	switch c in callback{
		case proc(): if c != nil do c()
		case CallbackStateful: if c.wrapper != nil do c.wrapper(c, freeState)
	}
}

callback_free :: proc(callback:Callback){
	if c,ok:=callback.(CallbackStateful); ok && c.state != nil{
		free(c.state, c.stateAllocator)
	}
}

//if prettifying, uses temp allocator
enum_name_get :: proc(value: $T, pretty:=true) -> string where intrinsics.type_is_enum(T){
	n,_ := reflect.enum_name_from_value(value)
	if pretty do return string_prettify(n)
	return n
}

enum_value_get :: reflect.enum_from_name