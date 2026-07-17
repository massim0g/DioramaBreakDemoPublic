#+feature using-stmt
package massimodin //@nested-tags:_components/

CombatEntity :: struct{
	using base:ComponentBase,
	using rect:Recti, //@e
	spawnWithExactDimensions:bool, //@e
	transform:CoRef(Transform),
	placedInGrid:bool
}

//remove a combat entity from the combat grid
combatEntity_unplace :: proc(using self:^CombatEntity){
	_,isUnit := cofind(self, CombatUnit)
	bitMask:u128
	if !isUnit do bitMask = ((u128(1) << u128(size.x)) - u128(1)) << u128(x)
	for _y in y..<y+size.y{
		combat.occupancy_grid[_y] ~= bitMask
		gridRow := grid_slice_row(combat.grid, _y)
		for _x in x..<x+size.x{
			occupants := &gridRow[_x].occupants
			for ref,i in occupants{
				if ref.entityID == entity.id{
					unordered_remove(occupants, i)
					break
				}
			}
		}
	}
	placedInGrid = false
}

combatEntity_place_using_current_pos :: proc(using self:^CombatEntity){
	assertf(combat_rect_in_grid(x,y,size.x,size.y), "Tried to place a combat entity outside of the combat grid (x:%i, y:%i, w:%i, h:%i)!", x,y,size.x,size.y)
	_,isUnit := cofind(self, CombatUnit)
	bitMask:u128
	if !isUnit do bitMask = ((u128(1) << u128(size.x)) - u128(1)) << u128(x)
	cre := crx(self)
	for _y in y..<y+size.y{
		combat.occupancy_grid[_y] |= bitMask

		gridRow := grid_slice_row(combat.grid, _y)
		for _x in x..<x+size.x{
			append(&gridRow[_x].occupants, cre)
		}
	}
	placedInGrid = true
}
combatEntity_place_using_new_pos_i :: #force_inline proc(using self:^CombatEntity, newX:int, newY:int){
	x = newX
	y = newY
	combatEntity_place_using_current_pos(self)
}
combatEntity_place_using_new_pos_vec2i :: #force_inline proc(using self:^CombatEntity, newPos:Vec2i){
	pos = newPos
	combatEntity_place_using_current_pos(self)
}
//Place a combat entity onto the combat grid. Can optionally provide a new position for it to be placed at.
combatEntity_place :: proc{combatEntity_place_using_new_pos_i, combatEntity_place_using_new_pos_vec2i, combatEntity_place_using_current_pos}

combatEntity_move_veci :: proc(using self:^CombatEntity, newPos:Vec2i){
	combatEntity_unplace(self)
	combatEntity_place(self, newPos)
}
combatEntity_move_i :: #force_inline proc(using self:^CombatEntity, newX:int, newY:int){
	combatEntity_move_veci(self, {newX, newY})
}
combatEntity_move :: proc{combatEntity_move_i, combatEntity_move_veci}

combatEntity_is_unit :: proc(using self:^CombatEntity) -> bool{
	_, out := cofind(self, CombatUnit)
	return out
}

combatEntity_stage_pos :: proc(self:^CombatEntity, pos:Vec2i={-1,-1}) -> Vec2{
	pos := pos
	if(pos == {-1,-1}) do pos = self.pos
	pos += self.size/2 //integer division is intentional
	return combat_to_stage_pos(pos, self.size.x%2 == 0)
}

combatEntity_surrounding_positions :: proc(self:^CombatEntity, pos:Vec2i) -> [4]Vec2i{
	return [4]Vec2i{
		{pos.x+self.size.x, pos.y},
		{pos.x, pos.y-1},
		{pos.x-1, pos.y+self.size.y-1},
		{pos.x+self.size.x-1, pos.y+self.size.y}
	}
}

combatEntity_center :: proc(using self:^CombatEntity) -> Vec2i{
	return pos + size/2
}


//returns all active non-unit combat entities
combatEntities_static_get :: proc() -> []^CombatEntity{
	out := make([dynamic]^CombatEntity, context.temp_allocator)
	ents := coall(CombatEntity)
	for &ent in ents{
		if ent.placedInGrid{
			if _,ok := cofind(&ent, CombatUnit); !ok do append(&out, &ent)
		}
	}
	return out[:]
}

_combatEntity_process_event :: proc(base:^ComponentBase, event:Event, overrideDisabled:=false){
if(!overrideDisabled && event in base.disabledEvents) do return
last_context := entities.context_component
defer cowith(last_context)
cowith(base)
self := cast(^CombatEntity)base
using self
#partial switch event{
case .init:
	coadd(StageEntity)
	coadd(&transform)

	rect.size = {1,1}

}}
