package massimodin_builder

//Mirrors the platform-independent artifacts the windows pipelines produced into the other targets' build dirs.
pipeline_other_targets_run :: proc(pipeline:^Pipeline, fullRebuild:bool){
	patterns := []string{"*.mopak", "*.dialogue", "*.texgroup", "*.index", "*.bank"}
	if config_build.targetLinux do dir_copy(paths.build_win64, paths.build_linux, patterns)

	print("ARTIFACT MIRROR DONE!")
}
