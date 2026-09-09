package massimodin //@nested-tags:engine/memory

import "core:mem"
import "core:mem/virtual"
import "core:reflect"
import "base:runtime"
import "core:slice"
import "../tracy"

Allocator :: mem.Allocator
Allocator_Error :: mem.Allocator_Error
Arena :: virtual.Arena
RawArray :: mem.Raw_Dynamic_Array

KILOBYTE :: 1024
MEGABYTE :: 1024*KILOBYTE
GIGABYTE :: 1024*MEGABYTE

ArenaSnapshot :: struct{
	arena:^Arena,
	data:[dynamic][dynamic]byte
}
MemorySnapshot :: struct{
	location:rawptr,
	data:[dynamic]byte
}

os_allocator:Allocator
default_allocator:Allocator //assigned to context.allocator at the program entry point
panic_allocator :: mem.panic_allocator

//Creates a new arena with associated allocator. Buffer arenas are not supported by this function and will cause a panic.
allocator_make :: proc(blockSize:uint=KILOBYTE*512, kind:virtual.Arena_Kind=.Growing, loc:=#caller_location) -> Allocator{
	arena := new(Arena, os_allocator)
	err:mem.Allocator_Error
	switch kind{
		case .Growing: err = virtual.arena_init_growing(arena, blockSize)
		case .Static: err = virtual.arena_init_static(arena, blockSize)
		case .Buffer: panic("Buffer arenas not supported by this function!", loc)
	}
	
	assertf(err == .None, "Error creating allocator! %v", err, loc=loc)
	alloc := virtual.arena_allocator(arena)

	// when tracy.TRACY_ENABLE{
	// 	alloc = tracy.MakeProfiledAllocator(
	// 		alloc,
	// 		allocator=os_allocator
	// 	)
	// }

	return alloc
}

//Frees the contents of an arena allocator as well as the arena struct itself.
//WARNING: Allocator cannot be reused after this. If you just want to clear the arena use `free_all`
allocator_delete :: proc(alloc:Allocator){
	when tracy.TRACY_ENABLE{
		// profiledAlloc := cast(^tracy.ProfiledAllocatorData)alloc.data
		// alloc := profiledAlloc.backing_allocator
		// delete(profiledAlloc.allocations)
		// free(profiledAlloc, os_allocator)
	}
	virtual.arena_destroy(cast(^Arena)alloc.data)
	free(alloc.data, os_allocator)
}

//Coalesce the default allocator's buddy blocks, defragmenting it. Should be done occasionally when there's time to reduce the chances of a lag spike from a forced coalescence
@(disabled=true) //buddy deprecated in favor of just using the os allocator
default_allocator_coalesce :: proc(){
	backingStruct := cast(^mem.Buddy_Allocator)default_allocator.data
	mem.buddy_block_coalescence(backingStruct.head, backingStruct.tail)
}

new_typeid :: proc(t:typeid, allocator := context.allocator, loc := #caller_location) -> rawptr{
	out, _ := mem.alloc(reflect.size_of_typeid(t), reflect.align_of_typeid(t), allocator, loc)
	return out
}


arena_snapshot_allocator :: proc(alloc:Allocator, allocator:=os_allocator)->ArenaSnapshot{
	// when tracy.TRACY_ENABLE{
	// 	alloc := (cast(^tracy.ProfiledAllocatorData)alloc.data).backing_allocator
	// }
	return arena_snapshot_arena(cast(^Arena)alloc.data, allocator)
}
arena_snapshot_arena :: proc(arena:^Arena, allocator:=os_allocator)->ArenaSnapshot{
	out := ArenaSnapshot{
		arena,
		make([dynamic][dynamic]byte, allocator)
	}
	blocks := make([dynamic]^virtual.Memory_Block, context.temp_allocator)
	block := arena.curr_block
	for block != nil{
		append(&blocks, block)
		block = block.prev
	}
	for b in blocks{
		blockData := make([dynamic]byte, b.used, allocator)
		copy_slice(blockData[:], b.base[:b.used])
		append(&out.data, blockData)
	}
	return out
}
//Copies all the data in a given set of arenas to a separate set of byte buffers. WARNING: Allocators passed to this must be arena allocators (data pointer must be a pointer to an Arena)
arena_snapshot :: proc{arena_snapshot_allocator, arena_snapshot_arena}

//Loads arena data from a snapshot. 
//WARNING: May cause undefined behavior if any of the snapshotted arenas' memory blocks no longer exist at the same locations, since pointers might not point to the right location anymore. This should only be an issue if the arena is freed between snapshotting and loading.
arena_snapshot_load :: proc(snapshot:ArenaSnapshot){
	arena := snapshot.arena
	blocks := make([dynamic]^virtual.Memory_Block, context.temp_allocator)
	block := arena.curr_block
	for block != nil{
		append(&blocks, block)
		block = block.prev
	}

	assert(len(snapshot.data) <= len(blocks), "Tried to load a growing arena snapshot after shrinking the arena.") //this behavior is currently unsupported because it would invalidate pointers

	startInd := 0
	for len(blocks)-startInd > len(snapshot.data){
		virtual.arena_growing_free_last_memory_block(arena)
		startInd += 1
	}

	arena.total_used = 0
	for i:=startInd; i<len(blocks); i+=1{
		block = blocks[i]
		blockData := snapshot.data[i-startInd]
		block.used = uint(len(blockData))
		copy_slice(block.base[:block.used], blockData[:])
		arena.total_used += block.used
	}

}

arena_snapshot_free :: proc(snapshot:^ArenaSnapshot){
	for &block in snapshot.data{
		clear(&block)
	}
	clear(&snapshot.data)
}



