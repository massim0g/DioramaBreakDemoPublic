package massimodin //@nested-tags:

import "core:os"
import "core:path/filepath"

release_channel:ReleaseChannel
ReleaseChannel :: enum{
	unknown,
	steam,
	gog,
	itch
}

@(disabled=DEBUG)
_release_channel_get :: proc(){
	filePath,_ := filepath.join({executable_directory, "release_channel.txt"}, context.temp_allocator)
	rcFileData, err := os.read_entire_file(filePath, context.temp_allocator)
	if err == nil{
		release_channel,_ = enum_value_get(ReleaseChannel, string(rcFileData))
	}
}