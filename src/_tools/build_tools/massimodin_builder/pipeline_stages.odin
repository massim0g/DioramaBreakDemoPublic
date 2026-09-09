package massimodin_builder

import "core:os"
import "core:strings"
import "core:path/filepath"

STAGE_IDS_DEFAULT :: `package massimodin

StageIDs :: struct{
//<declarations>
//</declarations>
}
st:^StageIDs

_reload_stage_ids :: proc(){
//<assignments>
//</assignments>
}
`

pipeline_stages_run :: proc(pipeline:^Pipeline, fullRebuild:bool){
	idPath, _ := filepath.join({paths.massimodin, "stageIDs.g.odin"})
	outDir, _ := filepath.join({paths.build, "stages"})

	idConfig := IDConfig{
		path              = idPath,
		declarationPattern = " :^Stage,",
		defaultTemplate   = STAGE_IDS_DEFAULT,
		assignmentFormat  = `st.%s = &stage._stages_map["%s"] or_else nil`,
	}

	state := ids_read(idConfig)
	namesToAdd := make([dynamic]string)

	for &file in pipeline.pendingFiles{
		stageName := sanitize_asset_name(filepath.stem(filepath.base(file.path)))

		outPath, _ := filepath.join({outDir, strings.concatenate({stageName, ".json"})})

		if !file.exists{
			ids_remove(&state, stageName)
			if os.exists(outPath) do os.remove(outPath)
			continue
		}

		if !fullRebuild do printf("Copying %s", stageName)

		stageData, readErr := os.read_entire_file(file.path, context.temp_allocator)
		if readErr != nil{
			printf("WARNING: Could not read %s", file.path)
			continue
		}

		stageContent := string(stageData)
		if config_build.debug{
			relativePath,_ := filepath.rel(pipeline.watchDir, filepath.dir(file.path))
			if relativePath == "." do relativePath = "" //stages at the root of stages/ use an empty path
			trimmed := strings.trim_left_space(stageContent)
			if len(trimmed) > 0 && trimmed[0] == '{'{
				relativePathNormalized, _ := strings.replace_all(relativePath, "\\", "/")
				stageContent = strings.concatenate({
					`{"filePath": "`, relativePathNormalized, `", `,
					trimmed[1:],
				})
			}
		} 

		_ = os.write_entire_file(outPath, transmute([]u8)stageContent)

		if !(stageName in state.existingIds) do append(&namesToAdd, stageName)
	}

	if ids_write(idConfig, &state, namesToAdd[:]) do pipeline.codegenDirty = true
	printf("STAGES BUILD DONE!")
}
