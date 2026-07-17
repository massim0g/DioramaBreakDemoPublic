package massimodin //@nested-tags:engine/flags

import "core:os"
import "core:encoding/json"
import "core:path/filepath"

FlagMap :: [FlagLevel]map[string]string
_flags:^FlagMap

_flags_init :: proc(){
	context.allocator = os_allocator
	_flags = new(FlagMap)
	for &m in _flags{
		init(&m)
	}
}

FlagLevel :: enum{
	local, //gets cleared at the end of every dialogue, for local variables
	temp, //gets cleared when resting at a checkpoint, does not persist on game close
	global, //default level, does not persist upon reloading an old save
	persistent, //persists upon reloading a save, only way to clear them is to do a true reset
	prestige //persists beyond a true reset, saved to a separate file.
}

//Sets a flag. Setting val to "" will delete a flag.
flag :: proc(name:string, val:="1", level:=FlagLevel.global){
	context.allocator = os_allocator
	_,ok := string_to_int(name)
	assertf(!ok && !string_contains_any(name, "<>;:~`'\"|\\{}[],.!?@#$%^&*()"), "Tried to set flag using non-alphanumerical name '%s'", name) //+-=/_ are allowed, partly in order to support base64 encoded data
	
	if(name in _flags[level]){
		delete(_flags[level][name])
		if(val == "") do strmap_delete_key(&_flags[level], name)
		else do _flags[level][name] = string_clone(val)
	}
	else if(val != "") do strmap_set(&_flags[level], name, string_clone(val))

	if level == .persistent{
		path,_ := filepath.join({save.dir, SAVE_FILENAME}, context.temp_allocator)

		if !os.exists(path) do return

		data,_ := os.read_entire_file(path, context.temp_allocator)

		saveJson,_ := json.parse(data, json.DEFAULT_SPECIFICATION, false, context.temp_allocator)
		jsonObj := saveJson.(json.Object)
		jsonObj["persistentFlags"] = flags_encode(.persistent)

		newSaveJson,err := json_encode(jsonObj, context.temp_allocator)
		_ = os.write_entire_file(path, transmute([]u8)newSaveJson)
	}

	if level == .prestige{
		path,_ := filepath.join({save.dir, PRESTIGE_FILENAME}, context.temp_allocator)
		_ = os.write_entire_file(path, transmute([]u8)flags_encode(.prestige))
	}
}

flag_delete :: proc(name:string, level:=FlagLevel.global){
	flag(name, "", level)
}

flag_exists :: proc(name:string) -> bool{
	for fMap in _flags{
		if(name in fMap) do return true
	}
	return false
}

flag_check :: proc(name:string) -> bool{
	val := flag_get(name)
	return val != "" && val != "0"
}

flag_get :: proc(name:string) -> string{
	for fMap in _flags{
		if(name in fMap) do return fMap[name]
	}
	return ""
}

//returns global by default if a flag does not exist
flag_get_level :: proc(name:string) -> FlagLevel{
	for fMap,l in _flags{
		if(name in fMap) do return l
	}
	return .global
}

flags_clear :: proc(level:FlagLevel){
	context.allocator = os_allocator
	for key, val in _flags[level]{
		delete(val)
		delete(key)
	}
	clear(&_flags[level])
}

flags_encode :: proc(level:FlagLevel, allocator:=context.temp_allocator)->string{
	out,_ := json_encode(_flags[level], context.temp_allocator)
	return base64_encode_string(out, allocator)
}

flags_load :: proc(level:FlagLevel, flagString:string){
	flags_clear(level)
	decodedFlags,_ := base64_decode(flagString, allocator=context.temp_allocator)
	flagsJson := json_parse(decodedFlags)
	flagsObj := flagsJson.(json.Object)

	fm := &_flags[level]
	for k,v in flagsObj{
		strmap_set(fm, k, string_clone(v.(json.String), os_allocator))
	}
}