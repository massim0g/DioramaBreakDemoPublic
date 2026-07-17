package massimodin_builder

import "core:os"
import "core:strings"
import "core:path/filepath"

SHADER_IDS_DEFAULT :: `package massimodin

ShaderIDs :: struct{
//<declarations>
//</declarations>
}
sh:^ShaderIDs

_reload_shader_ids :: proc(){
//<assignments>
//</assignments>
}
`

//Drops a leading UTF-8 BOM (EF BB BF) if present
shader_strip_bom :: proc(data:[]u8) -> []u8{
	if len(data) >= 3 && data[0] == 0xEF && data[1] == 0xBB && data[2] == 0xBF do return data[3:]
	return data
}

pipeline_shaders_run :: proc(pipeline:^Pipeline, fullRebuild:bool){
	idPath, _ := filepath.join({paths.massimodin, "shaderIDs.g.odin"})
	outDir, _ := filepath.join({paths.build, "shaders"})

	idConfig := IDConfig{
		path              = idPath,
		declarationPattern = " :Shader,",
		defaultTemplate   = SHADER_IDS_DEFAULT,
		assignmentFormat  = `sh.%s = shaders._shaders_map["%s"] or_else 0`,
	}

	state := ids_read(idConfig)
	namesToAdd := make([dynamic]string)

	for &file in pipeline.pendingFiles{
		shaderName := sanitize_asset_name(filepath.stem(filepath.base(file.path)))

		outPath, _ := filepath.join({outDir, strings.concatenate({shaderName, ".glsl"})})

		if !file.exists{
			ids_remove(&state, shaderName)
			if os.exists(outPath) do os.remove(outPath)
			continue
		}

		if !fullRebuild do printf("Bundling shader: %s", shaderName)

		fragData, fragErr := os.read_entire_file(file.path, context.temp_allocator)
		if fragErr != nil{
			printf("WARNING: Could not read shader '%s'", file.path)
			continue
		}
		//strip the UTF-8 BOM if present, otherwise it ends up in the shader source and the GLSL compiler rejects it
		fragContent := string(shader_strip_bom(fragData))

		vertPath, _ := strings.replace(file.path, ".frag", ".vert", 1)
		vertData, vertErr := os.read_entire_file(vertPath, context.temp_allocator)
		vertContent := ""
		if vertErr == nil{
			vertContent = string(shader_strip_bom(vertData))
		}

		vertStripped, _ := strings.replace_all(vertContent, "#version 330 core", "")
		fragStripped, _ := strings.replace_all(fragContent, "#version 330 core", "")
		combined := strings.concatenate({
			vertStripped,
			"\n<fragment>",
			fragStripped,
		})

		_ = os.write_entire_file(outPath, transmute([]u8)combined)

		//hot reload only supports overwriting existing assets, never adding new ones
		if !fullRebuild && (shaderName in state.existingIds) && process_running(paths.exe){
			reload_request_write("shader", transmute([]u8)outPath)
		}

		if !(shaderName in state.existingIds){
			append(&namesToAdd, shaderName)
		}
	}

	if ids_write(idConfig, &state, namesToAdd[:]) do pipeline.codegenDirty = true
	printf("SHADER BUILD DONE!")
}
