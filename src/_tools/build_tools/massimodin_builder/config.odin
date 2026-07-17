package massimodin_builder

import "core:os"
import "core:path/filepath"
import "core:encoding/json"

Config :: struct{
	debug:bool,
	tracyEnable:bool,
	errorCheckDisable:bool,
	previewTexturePages:bool
}

config:Config
config_changed:bool

load_config :: proc(){
	configPath, _ := filepath.join({paths.src, "build_config.json"})
	data, readErr := os.read_entire_file(configPath, context.temp_allocator)
	if readErr != nil{
		printf("WARNING: Could not read build_config.json, using defaults")
		config = {debug = true}
		return
	}
	err := json.unmarshal(data, &config)
	if err != nil{
		printf("WARNING: Could not parse build_config.json, using defaults")
		config = {debug = true}
	}

	config_changed = false //config is now up-to-date
}