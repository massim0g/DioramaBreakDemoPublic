package massimodin_builder

import "core:os"
import "core:strings"
import "core:path/filepath"

pipeline_lib_run :: proc(pipeline:^Pipeline, fullRebuild:bool){
	libDir, _ := filepath.join({paths.project, "lib"})

	for &file in pipeline.pendingFiles{
		relative, relErr := filepath.rel(libDir, file.path)
		if relErr != nil do continue

		parts := strings.split(relative, filepath.SEPARATOR_STRING)
		if len(parts) == 0 do continue

		skip := false
		destParts := parts

		if strings.has_prefix(parts[0], "_"){
			switch parts[0]{
				case "_debugOnly": skip = !config.debug
				case "_releaseOnly": skip = config.debug
				case "_switchOverrides": skip = true
			}

			if !skip do destParts = parts[1:]
		}

		if skip do continue

		destRelative := strings.join(destParts, filepath.SEPARATOR_STRING)
		destPath, _ := filepath.join({paths.build_win64, destRelative})

		if file.exists{
			destDir := filepath.dir(destPath)
			if !os.exists(destDir){
				os.make_directory(destDir)
			}

			data, readErr := os.read_entire_file(file.path, context.temp_allocator)
			if readErr == nil{
				_ = os.write_entire_file(destPath, data)
			}
		} 
		else if os.exists(destPath) do os.remove(destPath)
	}

	printf("LIB COPY DONE!")
}