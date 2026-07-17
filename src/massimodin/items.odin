package massimodin //@nested-tags:characters

ItemSystem :: struct{
	data:map[string]Item
}
items:^ItemSystem

Item :: struct{
	id:string,
	icon:^Sprite,
	kind:ItemKind,
	equipPassives:[]Passive,
	equipActions:[]^CombatAction,
	paletteIndex:f32 //some equipped items modify a character's palette
}

ItemRef :: union{
	string,
	^Item
}

ItemKind :: enum{

	//collectables
	key,
	material,
	
	//equipment
	consumable,
	vest, //armor 
	blade, //pro weapon
	boots, //pro footwear
	
	program, //minima weapon
	shoes //minima footwear
}

_item_system_init :: proc(){
	items = new(ItemSystem)
	init(&items.data, assets.allocator)
}

item_ref_get :: proc(ref:ItemRef) -> ^Item{
	switch r in ref{
		case string: 
			assertf(r in items.data, "Item with id '%s' not found!", r)
			return &items.data[r]
		case ^Item: return r
	}

	unreachable()
}

player_character_equipped_item :: proc(character:PlayerCharacterID, kind:ItemKind, ind:=0) -> ^Item{
	ind := ind
	equippedItems := save.characters[character].equippedItems

	for slot in equippedItems{
		if slot.slotKind == kind{
			if ind > 0 do ind -= 1
			else do return slot.item
		}
	}

	return nil
}

item_equipped_to :: proc(item:^Item) -> (pid:PlayerCharacterID, equipped:bool){
	if equals(item.kind, ItemKind.key, ItemKind.material) do return
	for id in PlayerCharacterID{
		slots := save.characters[id].equippedItems
		for slot in slots{
			if slot.item == item do return id, true
		}
	}
	return
}

pro_blade_pal_swap_set :: proc(palInd:f32=-1){
	palInd := palInd
	if palInd == -1 do palInd = player_character_equipped_item(.pro, .blade).paletteIndex
	pal_swap_set(sp.proBladePalettes, palInd)
}

//will also add the item to the player's inventory if they don't have it
player_character_equip :: proc(character:PlayerCharacterID, item:ItemRef, ind:=0){
	item := item_ref_get(item)
	if inventory_get(item) == 0 do inventory_set(item, 1)
	ind := ind
	equippedItems := &save.characters[character].equippedItems

	for &slot in equippedItems{
		if slot.slotKind == item.kind{
			if ind > 0 do ind -= 1
			else{
				slot.item = item
				player_character_reset_saved_stats(character) //reset certain stats (mainly hp) to prevent equip changes from messing them up. todo: maybe more complicated rules?
				return
			}
		}
	}

	

	print("WARNING: Could not find a valid equip slot for item. Player Character: %v, Slot Ind: %i, Item: %s", character, ind, item.id)
}

//get the quantity of a specific item in the player inventory
inventory_get :: proc(item:ItemRef) -> int{
	item := item_ref_get(item)
	if out,ok := save.inventory[item];ok do return out
	return 0
}
//set the quantity of a specific item in the player inventory
inventory_set :: proc(item:ItemRef, amount:int){
	item := item_ref_get(item)
	if amount <= 0 do delete_key(&save.inventory, item)
	else do save.inventory[item] = amount
}
//add to the quantity of a specific item in the player inventory
inventory_add :: proc(item:ItemRef, amount:int=1){
	item := item_ref_get(item)
	stored := save.inventory[item] //returns 0 if item is not in inventory
	stored += amount
	inventory_set(item, stored)
}