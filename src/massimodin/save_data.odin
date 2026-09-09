package massimodin //@nested-tags:characters

import "core:path/filepath"
import "core:os"
import "core:encoding/json"
import "../sdl3"

SaveDataSystem :: struct{
	using save_data:Save,
	active:bool, //whether saving is active. Disabled by default mainly to mitigate unintentional save overwrites while debugging. 
	settings:Settings,
	dir:string, //directory to save user data to
	allocator:Allocator
}
save:^SaveDataSystem
settings:^Settings //points to settings in save data system just so I can do settings.whatever

SAVE_FILE_DIRECTORY_NAME :: "DioramaBreak"
SAVE_FILENAME :: "db_save.json"
SETTINGS_FILENAME :: "db_settings.json"
PRESTIGE_FILENAME :: "db_prestige.txt"

CHECKPOINT_MAX_TALK_CREDITS :: 3

save_file_path_make :: #force_inline proc(fileName:string, allocator:=context.temp_allocator) -> string{
	return filepath.join([]string{save.dir, fileName}, allocator) or_else ""
}

//serializable save data
Save :: struct{
	//"private" variables, get set on game init or only when saving 
	game_version:string, //simply tracks the game version on which the save was made
	format_version:string, //used for updating old save data
	globalFlags:string,
	persistentFlags:string, //flags get written to the save file as an encoded string (still just json) to make it easier to save/load individual flag levels
	stage:^Stage,
	playerPos:Vec2,
	loadDialogue:^Dialogue,
	loadDialogueLabel:string,

	//variables that game logic interacts with regularly
	characters:[PlayerCharacterID]PlayerCharacterData,
	inventory:map[^Item]int, //maps item IDs to quantities
	persistent_entity_data:map[string]StageEntityPersistentData,
	player_follower_ids:[dynamic]string,
	checkpoint_talk_credits:int, //number of times the player can talk to the party at a checkpoint, gets reset after resting or entering combat.
	checkpoint_rest_available:bool //whether the player can long rest at a checkpoint. Set to false after resting and resets to true when entering combat.
}

Settings :: struct{
	format_version:string,

	window_scale:int,
	window_fullscreen:bool,

	dialogue_skip_enabled:bool,
	dialogue_one_button_advance:bool,
	dash_mode:PlayerDashMode,

	locale:LocaleID,

	master_volume:f32,
	music_volume:f32,
	sfx_volume:f32,
	ambience_volume:f32
}

//unused
PronounKind :: enum{
	neutral,
	male,
	female
}

PlayerDashMode :: enum{
	hold,
	toggle,
	onByDefault
}

_save_system_init :: proc(){

	save = new(SaveDataSystem)
	settings = &save.settings

	save.allocator = allocator_make()

	init(&save.inventory)
	init(&save.persistent_entity_data)
	init(&save.player_follower_ids)

	for character in PlayerCharacterID{
		data := &save.characters[character]
		init(&data.equippedItems)
	}

	when ON_WINDOWS{
		appDataDir,_ := filepath.join([]string{os.get_env("APPDATA", context.temp_allocator), "../Local"}, context.temp_allocator)
		assertf(os.exists(appDataDir), "App data dir '%s' does not exist!", appDataDir)
		save.dir, _ = filepath.join([]string{appDataDir, SAVE_FILE_DIRECTORY_NAME}, os_allocator)
		if(!os.exists(save.dir)){
			err := os.make_directory(save.dir)
			assertf(err == nil, "Error creating save file directory: '%v'", err)
		}
	}
	else when ON_LINUX{
		//GetPrefPath also creates the directory ($XDG_DATA_HOME/DioramaBreak/, usually ~/.local/share/DioramaBreak/)
		prefPath := sdl3.GetPrefPath("", SAVE_FILE_DIRECTORY_NAME)
		assertf(prefPath != nil, "Could not get a save file directory!")
		save.dir = string_clone(string(cstring(prefPath)), os_allocator)
		sdl3.free(prefPath)
	}
}

//reset loaded save data
save_reset :: proc(){
	free_all(save.allocator)

	clear(&save.inventory)
	clear(&save.persistent_entity_data)
	clear(&save.player_follower_ids)
	save.checkpoint_talk_credits = CHECKPOINT_MAX_TALK_CREDITS
	save.checkpoint_rest_available = true
	flags_clear(.global)
	flags_clear(.temp)
	flags_clear(.persistent)

	for character in PlayerCharacterID{
		setSlots :: proc(arr:^[dynamic]PlayerCharacterEquippedItemSlot, kinds:..ItemKind){
			clear(arr)
			for kind in kinds{
				append(arr, PlayerCharacterEquippedItemSlot{kind, nil})
			}
		}

		data := &save.characters[character]

		ei := data.equippedItems
		data^ = PlayerCharacterData{}
		data.equippedItems = ei
	
		data.hp = player_character_info(character, true).maxHp
		switch character{
			case .pro:
				setSlots(&data.equippedItems,
					.blade,
					//.blade, todo: second blade slot should be granted by first level's passive
					.vest,
					.boots
				)
			case .minima:
				setSlots(&data.equippedItems,
					.program,
					.shoes
				)
		}	
	}

	//starting items, equipment, and flags
	player_character_join_party(.pro)

	flag("player", "Player") //default player name for debugging

	save.active = false
}

game_save :: proc(loadDialogue:^Dialogue=nil, loadDialogueLabel:="", loadPos:Maybe(Vec2)=nil, silent:=false){
	if !save.active do return

	if lp,ok:=loadPos.?;ok do save.playerPos = lp
	else if p,ok2:=cofind(Player,0);ok2 do save.playerPos = p.transform.pos
	else{
		print("Warning: Unable to determine a position to load the player in when saving! Exiting!")
		return
	}

	save.game_version = GAME_VERSION
	save.format_version = SAVE_FORMAT_VERSION
	save.stage = stage.loaded

	save.loadDialogue = loadDialogue
	save.loadDialogueLabel = loadDialogueLabel
	save.globalFlags = flags_encode(.global)
	save.persistentFlags = flags_encode(.persistent)

	path,_ := filepath.join({save.dir, SAVE_FILENAME}, context.temp_allocator)

	saveJson,err := json_encode(save.save_data, context.temp_allocator)
	assertf(err == nil, "Error encoding save '%v'!", err)
	_ = os.write_entire_file(path, transmute([]u8)saveJson)

	steamworks_stats_update_and_push()

	//save indicator
	if !silent do ui_cue("saveIndicator")
}

game_load :: proc()->(loaded:bool){
	path,_ := filepath.join({save.dir, SAVE_FILENAME}, context.temp_allocator)

	//set default values
	save_reset()

	save.active = true

	clear(&sprites.game_load_preloaded_texture_groups)
	defer{
		for name in sprites.texture_groups_dynamic{
			if contains(sprites.game_load_preloaded_texture_groups, name) do texture_group_preload(name)
			else if name != "title_screen_HD" do texture_group_unload(name)
		}
	}
	append(&sprites.game_load_preloaded_texture_groups, "cgs_ch1") //just always keep these loaded for now

	if !os.exists(path){
		append(&sprites.game_load_preloaded_texture_groups, "stroma")
		return
	}

	loadRetries := 0
	fileData:[]byte
	for{
		data, readErr := os.read_entire_file(path, context.temp_allocator)
		if readErr != nil{
			if loadRetries > 5{
				print("WARNING: Completely failed to load save data file!")
				return
			}
			else{
				print("WARNING: Failed to load save data file! Retrying...")
				sleep(100)
				loadRetries += 1
				continue
			}
		}

		fileData = data
		break
	}

	saveJson, err := json.parse(fileData, json.DEFAULT_SPECIFICATION, false, context.temp_allocator)
	jsonObj,ok2 := saveJson.(json.Object)

	if err != .None || !ok2{
		print("WARNING: Failed to parse save data, reverting to default")
		return
	} 

	if !save_data_upgrade(&jsonObj){
		print("WARNING: Failed to upgrade save data, reverting to default")
		return
	}
	
	{
		context.allocator = save.allocator
		json_unmarshal(jsonObj, &save.save_data, true)
	}
	flags_load(.global, save.globalFlags)
	flags_load(.persistent, save.persistentFlags)

	prestigePath,_ := filepath.join({save.dir, PRESTIGE_FILENAME}, context.temp_allocator)
	if os.exists(prestigePath){
		prestigeData, prestigeErr := os.read_entire_file(prestigePath, context.temp_allocator)
		if prestigeErr != nil do print("WARNING: Failed to load prestige data.")
		else do flags_load(.prestige, string(prestigeData))
	}

	stages_preparse_block()
	rtgs := save.stage.data["requiredTextureGroups"].(json.Array)
	for rtg in rtgs do append(&sprites.game_load_preloaded_texture_groups, rtg.(json.String))

	return true
}

//resets loaded save info and deletes the save file
game_save_file_delete :: proc(){
	if !save.active do return
	save_reset()
	path,_ := filepath.join({save.dir, SAVE_FILENAME}, context.temp_allocator)
	os.remove(path)
}

//load game data and last checkpoint stage. Can optionally just load the checkpoint stage if the game is already loaded.
//Runs a bevy of checks on various flags to see if a dialogue should start on load
game_load_to_checkpoint :: proc(doGameLoad:=true)->(loaded:bool){
	if doGameLoad{
		game_load() or_return
	}
	texture_group_load_block(groupNames=sprites.game_load_preloaded_texture_groups[:])
	rest_state_reset() //no matter what, treats player as if they just rested on load
	stage_load(save.stage)
	p := entity_make(Player)
	transform_set(p.transform, save.playerPos)
	camera_tracking_set(p.stageCharacter._ptr)
	proc_call_delayed(proc(){
		cutscene.enabled = false
		if save.loadDialogue != nil do dialogue_open(save.loadDialogue, save.loadDialogueLabel)
		else if flag_check("consequenceWarnable") && !flag_check("warnedProAboutConsequence") do dialogue_open(di.consequenceEncounter, "warnPro")
	}, 1)
	return true
}

SAVE_FORMAT_VERSION :: "0"
save_data_upgrade :: proc(data:^json.Object) -> bool{
	switch data["format_version"].(json.String){
		case SAVE_FORMAT_VERSION: return true
	}

	return false
}

settings_save :: proc(){
	settings.format_version = SETTINGS_FORMAT_VERSION

	path,_ := filepath.join({save.dir, SETTINGS_FILENAME}, context.temp_allocator)

	settingsJson,err := json_encode(settings^, context.temp_allocator)
	assertf(err == nil, "Error encoding settings '%v'!", err)
	_ = os.write_entire_file(path, transmute([]u8)settingsJson)
}

settings_load :: proc() -> (loaded:bool){
	path,_ := filepath.join({save.dir, SETTINGS_FILENAME}, context.temp_allocator)

	//set default values
	window_scale_to_display(0.75)

	settings.dialogue_skip_enabled = DEBUG

	settings.locale = 0
	settings.master_volume = 1
	settings.music_volume = 1
	settings.sfx_volume = 1
	settings.ambience_volume = 1

	defer{
		//apply loaded settings immediately
		display_apply_settings()
		audio_apply_settings()
	}

	if !os.exists(path){
		settings_save() //write default settings
		return
	}

	data, readErr := os.read_entire_file(path, context.temp_allocator)
	if readErr != nil{
		print("WARNING: Failed to load settings data! Reverting to defaults.")
		settings_save() //overwrite corrupted file with default settings
		return
	}

	settingsJson, err := json.parse(data, json.DEFAULT_SPECIFICATION, false, context.temp_allocator)
	jsonObj,ok2 := settingsJson.(json.Object)

	if err != .None || !ok2{
		print("WARNING: Failed to parse settings data, reverting to defaults")
		settings_save()
		return
	} 

	if !settings_upgrade(&jsonObj){
		print("WARNING: Failed to upgrade settings data, reverting to defaults")
		settings_save()
		return
	}

	context.allocator = assets.allocator //for settings strings
	json_unmarshal(jsonObj, settings, true)

	return true
}

SETTINGS_FORMAT_VERSION :: "0"
settings_upgrade :: proc(data:^json.Object) -> bool{
	switch data["format_version"].(json.String){
		case SETTINGS_FORMAT_VERSION: return true
	}

	return false
}
