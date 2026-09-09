package massimodin_builder

import "core:os"
import "core:strings"
import "core:path/filepath"

/*
lib/ is organized by target platform: lib/shared/ goes to every enabled target's build dir, lib/_win64/ and lib/_linux/ go to their target's build dir only.
Within a platform dir, _debugOnly/ and _releaseOnly/ contents are filtered by the current build config.
*/
pipeline_lib_run :: proc(pipeline:^Pipeline, fullRebuild:bool){
	libDir, _ := filepath.join({paths.project, "lib"})

	for &file in pipeline.pendingFiles{
		relative, relErr := filepath.rel(libDir, file.path)
		if relErr != nil do continue

		parts := strings.split(relative, filepath.SEPARATOR_STRING)
		if len(parts) < 2{
			printf("WARNING: lib file outside a platform dir, skipped: %s", relative)
			continue
		}

		//first component picks the destination build dir(s)
		destDirs:[2]string
		destCount := 0
		switch parts[0]{
			case "shared":
				destDirs[destCount] = paths.build_win64; destCount += 1
				if config_build.targetLinux{
					destDirs[destCount] = paths.build_linux; destCount += 1
				}
			case "_win64":
				destDirs[destCount] = paths.build_win64; destCount += 1
			case "_linux":
				if !config_build.targetLinux || strings.has_suffix(file.path, ".a") do continue //.a static libraries get scanned by the linux linker in the code pipeline, but do not need to be copied into the final build folder
				destDirs[destCount] = paths.build_linux; destCount += 1
			case:
				printf("WARNING: lib file in unknown platform dir, skipped: %s", relative)
				continue
		}
		parts = parts[1:]

		//debug/release filtering
		if strings.has_prefix(parts[0], "_"){
			skip := false
			switch parts[0]{
				case "_debugOnly": skip = !config_build.debug
				case "_releaseOnly": skip = config_build.debug
			}
			if skip do continue

			parts = parts[1:]
			if len(parts) == 0 do continue
		}

		destRelative := strings.join(parts, filepath.SEPARATOR_STRING)

		for destDir in destDirs[:destCount]{
			destPath, _ := filepath.join({destDir, destRelative})

			if file.exists{
				destParent := filepath.dir(destPath)
				if !os.exists(destParent){
					_ = os.make_directory_all(destParent)
				}

				data, readErr := os.read_entire_file(file.path, context.temp_allocator)
				if readErr == nil{
					_ = os.write_entire_file(destPath, data)
				}
			}
			else if os.exists(destPath) do os.remove(destPath)
		}
	}

	printf("LIB COPY DONE!")
}
