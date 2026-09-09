package massimodin //@nested-tags:

import "core:bytes"

Buffer :: bytes.Buffer

buffer_make :: proc(len,cap:int, allocator:=context.allocator)->bytes.Buffer{
	out:bytes.Buffer
	bytes.buffer_init_allocator(&out, len, cap, allocator)
	return out
}

buffer_write_val :: #force_inline proc (buf:^bytes.Buffer, val:$T){
	val := val
	bytes.buffer_write_ptr(buf, &val, size_of(T))
}
buffer_write_ptr :: #force_inline proc "contextless" (buf:^bytes.Buffer, valPtr:^$T){
	bytes.buffer_write_ptr(buf, valPtr, size_of(T))
}
buffer_write_string :: bytes.buffer_write_string
buffer_write_slice :: bytes.buffer_write_slice
buffer_write_rawptr :: bytes.buffer_write_ptr

buffer_head :: #force_inline proc "contextless" (b:bytes.Buffer) -> uintptr{
	return uintptr(&raw_data(b.buf)[len(b.buf)])
}


read_bytes_val :: #force_inline proc "contextless" (reader:^uintptr, $T:typeid) -> T{
	val := (cast(^^T)reader)^^
	reader^ += size_of(T)
	return val
}
read_bytes_ptr :: #force_inline proc "contextless" (head:^uintptr, valPtr:^$T){
	valPtr^ = (cast(^^T)head)^^
	head^ += size_of(T)
}
//Reads bytes at a uintptr and advances it
read_bytes :: proc{read_bytes_val, read_bytes_ptr}

bytes_from_uip :: #force_inline proc "contextless" (ptr,len:uintptr) -> []u8{
	return slice_from_ptr(cast(^u8)ptr, int(len))
}