package massimodin_builder

import "core:os"
import "core:fmt"
import "core:path/filepath"
import "core:encoding/json"
import "core:sys/windows"



//Both config files live at the workspace root and are gitignored; the builder generates them when missing or outdated.
ConfigBuild :: struct{
	debug:bool,
	targetLinux:bool,
	tracyEnable:bool,
	errorCheckDisable:bool,
	previewTexturePages:bool,
	schemaVersion:string
}

ConfigRun :: struct{
	runTarget:string,
	targetLinuxRemoteTestingIP:string,
	schemaVersion:string
}

CONFIG_BUILD_SCHEMA_VERSION :: "1"
CONFIG_RUN_SCHEMA_VERSION :: "1"
CONFIG_BUILD_DEFAULT :: ConfigBuild{schemaVersion = CONFIG_BUILD_SCHEMA_VERSION, debug = true}
CONFIG_RUN_DEFAULT :: ConfigRun{schemaVersion = CONFIG_RUN_SCHEMA_VERSION, runTarget = "win64"}

config_build:ConfigBuild
building_other_targets:bool

config_build_load :: proc(){
	config_build = config_load_or_generate("config_build.json", CONFIG_BUILD_DEFAULT, CONFIG_BUILD_SCHEMA_VERSION)
	building_other_targets = config_build.targetLinux //add other target flags here as needed
}

//The run config is reread on every game launch and allocated to temp, so it is only valid within the tick that loaded it. Nothing persists it.
config_run_load :: proc() -> ConfigRun{
	return config_load_or_generate("config_run.json", CONFIG_RUN_DEFAULT, CONFIG_RUN_SCHEMA_VERSION, context.temp_allocator)
}

config_load_or_generate :: proc(fileName:string, default:$T, schemaVersion:string, allocator:=context.allocator) -> T{
	path, _ := filepath.join({paths.project, fileName}, context.temp_allocator)

	for{
		cfg := default
		data, readErr := os.read_entire_file(path, context.temp_allocator)
		if readErr == nil{
			err := json.unmarshal(data, &cfg, allocator = allocator)
			if err == nil && cfg.schemaVersion == schemaVersion do return cfg
		}

		cfg.schemaVersion = schemaVersion
		serialized, marshalErr := json.marshal(cfg, {pretty = true}, context.temp_allocator)
		if marshalErr != nil{
			printf("ERROR: Could not serialize %s: %v", fileName, marshalErr)
			return cfg
		}
		writeErr := os.write_entire_file(path, serialized)
		if writeErr != nil{
			printf("ERROR: Could not write %s: %v", fileName, writeErr)
			return cfg
		}
		printf("%s was missing or outdated, regenerated it", fileName)

		//the daemon shares its console with the interactive shell, so it can't reliably read stdin. Ask with a popup instead.
		windows.MessageBoxW(nil,
			windows.utf8_to_wstring(fmt.tprintf(
				"%s was missing or had an outdated schema, so it has been regenerated:\n\n%s\n\nDouble-check it and make any edits now, then press OK to continue.",
				fileName, path,
			), context.temp_allocator),
			windows.L("Massimodin Builder"),
			windows.MB_OK | windows.MB_ICONINFORMATION | windows.MB_SETFOREGROUND | windows.MB_TOPMOST,
		)
		//loop around to pick up the user's edits, regenerating again if the file still doesn't check out
	}
}
