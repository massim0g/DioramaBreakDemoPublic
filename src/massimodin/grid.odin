package massimodin //@nested-tags:libraries/collections

import "core:mem"

//Used to efficiently store and retrieve data in a 2D grid.
Grid :: struct($T:typeid){
	buf:[dynamic]T,
	w:int,
	h:int
}

grid_make :: proc($T:typeid, w:int, h:int, allocator:=context.allocator) -> Grid(T){
	length:=w*h
	return Grid(T){make([dynamic]T, length, next_power_of_2(length), allocator), w, h}
}

grid_init :: proc(grid:^Grid($T), w:int, h:int, allocator:=context.allocator){
	grid^ = grid_make(T, w, h, allocator)
}

grid_get_i :: #force_inline proc(grid:Grid($T), x:int, y:int) -> T{
	assertf(x<grid.w && y<grid.h, "Invalid coordinates (%i, %i) for grid of size (%i, %i)", x, y, grid.w, grid.h)
	return grid.buf[y*grid.w + x]
}
grid_get_vec2i :: #force_inline proc(grid:Grid($T), pos:Vec2i) -> T{
	return grid_get_i(grid, pos.x, pos.y)
}
grid_get :: proc{grid_get_i, grid_get_vec2i}

grid_get_ptr_i :: #force_inline proc(grid:Grid($T), x:int, y:int) -> ^T{
	assertf(x>=0 && y>=0 && x<grid.w && y<grid.h, "Invalid coordinates (%i, %i) for grid of size (%i, %i)", x, y, grid.w, grid.h)
	return &grid.buf[y*grid.w + x]
}
grid_get_ptr_vec2i :: #force_inline proc(grid:Grid($T), pos:Vec2i) -> ^T{
	return grid_get_ptr_i(grid, pos.x, pos.y)
}
grid_get_ptr :: proc{grid_get_ptr_i, grid_get_ptr_vec2i}

grid_slice_row :: #force_inline proc(grid:Grid($T), y:int) -> []T{
	return grid.buf[y*grid.w:(y+1)*grid.w]
}


grid_set_i :: #force_inline proc(grid:^Grid($T), x:int, y:int, val:T){
	assertf(x<grid.w && y<grid.h, "Invalid coordinates (%i, %i) for grid of size (%i, %i)", x, y, grid.w, grid.h)
	grid.buf[y*grid.w + x] = val
}
grid_set_f :: #force_inline proc(grid:^Grid($T), x,y:f32, val:T){
	grid_set_i(grid, int(floor(x)), int(floor(y)), val)
}
grid_set_vec2 :: #force_inline proc(grid:^Grid($T), pos:Vec2, val:T){
	grid_set_f(grid, pos.x, pos.y, val)
}
grid_set_vec2i :: #force_inline proc(grid:^Grid($T), pos:Vec2i, val:T){
	grid_set_i(grid, pos.x, pos.y, val)
}
//Sets a value at a given grid position. If float coords are provided they will be **floored**.
grid_set :: proc{grid_set_i, grid_set_f, grid_set_vec2, grid_set_vec2i}

grid_resize :: proc(grid:^Grid($T), x1Delta:int, y1Delta:int, x2Delta:int, y2Delta:int){

	newW := grid.w - x1Delta + x2Delta
	newH := grid.h - y1Delta + y2Delta
	assert(newW >= 0 && newH >= 0, "Attempted to resize grid below 0!")
	
	rawBuf := cast(^mem.Raw_Dynamic_Array)&grid.buf
	assert(rawBuf.data != nil, "Trying to resize grid that was not initialized!")

	oldData := make_slice([]T, len(grid.buf), context.temp_allocator)
	copy(oldData, grid.buf[:])

	grid_zero(grid)
	resize(&grid.buf, newW*newH)

	for y in 0..<grid.h{
		newY := y - y1Delta
		if(newY < 0) do continue
		if(newY >= newH) do break
		for x in 0..<grid.w{
			newX := x - x1Delta
			if(newX < 0) do continue
			if(newX >= newW) do break
			grid.buf[newY*newW + newX] = oldData[y*grid.w + x]
		}
	}

	grid.w = newW
	grid.h = newH
}
grid_size :: #force_inline proc(grid:Grid($T)) -> Vec2i{
	return {grid.w, grid.h}
}
grid_size_set :: #force_inline proc(grid:^Grid($T), w,h:int){
	grid_resize(grid, 0, 0, w-grid.w, h-grid.h)
}

grid_delete :: proc(grid:Grid($T)){
	delete(grid.buf)
}

//Sets all values in grid to 0
grid_zero :: proc(grid:^Grid($T)){
	mem.zero_slice(grid.buf[:])
}

//Sets the size of the grid to 0 and clears the buffer
grid_clear :: proc(grid:^Grid($T)){
	clear(&grid.buf)
	grid.w = 0
	grid.h = 0
}

grid_index_to_pos_size :: #force_inline proc "contextless" (gridSize:Vec2i, ind:int) -> Vec2i{
	return Vec2i{ind%gridSize.x, ind/gridSize.x}
}
grid_index_to_pos_grid :: #force_inline proc "contextless" (grid:Grid($T), ind:int) -> Vec2i{
	return Vec2i{ind%grid.w, ind/grid.w}
}
grid_index_to_pos :: proc{grid_index_to_pos_size, grid_index_to_pos_grid}

grid_contains :: proc(grid:Grid($T), x,y:int) -> bool{
	return x < grid.w && y < grid.h
}

