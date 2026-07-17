package massimodin //@nested-tags:characters

import "core:reflect"
PlayerCharacterSystem :: struct{
	_base_info:[PlayerCharacterID]PlayerCharacterInfo,
	passives_map:map[string]PassiveInfo,
	player_name_attempts:[dynamic]string
}
player_characters:^PlayerCharacterSystem

PlayerCharacterID :: enum{
	pro,
	minima
}

PlayerCharacterInfo :: struct{ //stats and such
	maxHp:int,
	move:int,
	defense:[CombatDamageKind]int
}

PlayerCharacterData :: struct{
	inParty:bool,
	equippedItems:[dynamic]PlayerCharacterEquippedItemSlot,
	hp:int,
	xp:int
}

PlayerCharacterEquippedItemSlot :: struct{slotKind:ItemKind, item:^Item}

PassiveInfo :: struct{
	id:string,
	updateInfo:proc(info:^PlayerCharacterInfo, params:[4]f32),
	setCombatEvents:proc(params:[4]f32)
}

Passive :: struct{
	using info:^PassiveInfo,
	params:[4]f32
}



passive_string_get :: proc(passive:Passive, getDescription:=false) -> string{
	paramCount := 0
	for param in passive.params{
		if param == 0 do break
		paramCount += 1
	}

	args := make([]any, paramCount, context.temp_allocator)
	for &arg,i in args{
		arg = passive.params[i]
	}

	return format(dialogue_line(di.passives, passive.id, getDescription?1:0), args=args)
}

player_character_info :: proc(id:PlayerCharacterID, base:=false)->PlayerCharacterInfo{
	out := player_characters._base_info[id]
	if base do return out

	passives := player_character_passives(id)
	for passive in passives{
		passive.updateInfo(&out, passive.params) 
	}
	return out
}

player_character_string_to_id :: proc(s:string)->(id:PlayerCharacterID, ok:bool){
	return reflect.enum_from_name(PlayerCharacterID, s)
}

//certain characters do not have access to all their actions at all time, and this proc will take that into account, but you can force all actions to be returned 
player_character_actions :: proc(id:PlayerCharacterID, forceAll:=false)->[]^CombatAction{
	out := make([dynamic]^CombatAction, context.temp_allocator)

	//todo: level-up skills

	for slot,i in save.characters[id].equippedItems{
		if slot.item != nil && slot.item.equipActions != nil{
			if !forceAll{
				switch id{
					case .pro:
						if i>0 && slot.slotKind==.blade do continue //only receives actions from first blade slot
					case .minima: //no special-case
				}
			}
			append_elems(&out, args=slot.item.equipActions)
		}
	}

	return out[:]
}

player_character_passives :: proc(id:PlayerCharacterID)->[]Passive{
	out := make([dynamic]Passive, context.temp_allocator)

	//todo: level-up skills

	for slot in save.characters[id].equippedItems{
		if slot.item != nil && slot.item.equipPassives != nil{
			append_elems(&out, args=slot.item.equipPassives)
		}
	}

	return out[:]
}

//reset save data stats such as hp, called when changing equipment or healing up
player_character_reset_saved_stats :: proc(id:PlayerCharacterID){
	info := player_character_info(id)
	save.characters[id].hp = info.maxHp
}

player_character_join_party :: proc(id:PlayerCharacterID){
	save.characters[id].inParty = true
	switch id{
		case .pro:
			inventory_set("proHilt", 1)
			player_character_equip(.pro, "prosBlade")
			player_character_equip(.pro, "firstBoots")
			player_character_equip(.pro, "shirt")
		case .minima:
			player_character_equip(.minima, "startingProgram")
	}
}

_player_character_system_init :: proc(){
	player_characters = new(PlayerCharacterSystem, os_allocator)
	init(&player_characters.passives_map, assets.allocator)
	init(&player_characters.player_name_attempts)
	//base stats
	player_characters._base_info = {
		.pro={maxHp=5,move=3},
		.minima={maxHp=4,move=2},
	}
}


_passives_reload :: proc(){
	add :: proc(
		id:string,
		updateInfo:proc(info:^PlayerCharacterInfo, params:[4]f32)=nil,
		setCombatEvents:proc(params:[4]f32)=nil
	){
		player_characters.passives_map[id] = PassiveInfo{
			id,
			updateInfo,
			setCombatEvents,
		}
	}

	add(
		"hpUp",
		proc(info:^PlayerCharacterInfo, params:[4]f32){info.maxHp += int(params[0])}
	)
}
