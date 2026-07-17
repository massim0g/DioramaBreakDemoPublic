package massimodin_builder

import "core:os"
import "core:strings"
import "core:path/filepath"

CURVE_IDS_DEFAULT :: `package massimodin

CurveIDs :: struct{
//<declarations>
//</declarations>
}
cu:^CurveIDs

_reload_curve_ids :: proc(){
//<assignments>
//</assignments>
}
`

pipeline_curves_run :: proc(pipeline:^Pipeline, fullRebuild:bool){
	idPath, _ := filepath.join({paths.massimodin, "curveIDs.g.odin"})
	outDir, _ := filepath.join({paths.build, "curves"})
	curvesDir, _ := filepath.join({paths.project, "curves"})

	idConfig := IDConfig{
		path              = idPath,
		declarationPattern = " :^Curve,",
		defaultTemplate   = CURVE_IDS_DEFAULT,
		assignmentFormat  = `cu.%s = &curves._curves_map["%s"] or_else nil`,
	}

	state := ids_read(idConfig)
	namesToAdd := make([dynamic]string)

	for &file in pipeline.pendingFiles{
		curveName := sanitize_asset_name(filepath.stem(filepath.base(file.path)))

		outPath, _ := filepath.join({outDir, strings.concatenate({curveName, ".curve"})})

		if !file.exists{
			ids_remove(&state, curveName)
			invName := strings.concatenate({curveName, "_inv"})
			ids_remove(&state, invName)
			if os.exists(outPath) do os.remove(outPath)
			continue
		}

		if !fullRebuild do printf("Copying curve: %s", curveName)

		curveData, readErr := os.read_entire_file(file.path, context.temp_allocator)
		if readErr != nil{
			printf("WARNING: Could not read %s", file.path)
			continue
		}
		curveContent := string(curveData)

		fullPath, _ := filepath.join({curvesDir, filepath.base(file.path)})
		processed := strings.concatenate({fullPath, "|", curveContent})
		_ = os.write_entire_file(outPath, transmute([]u8)processed)

		if !(curveName in state.existingIds){
			append(&namesToAdd, curveName)
			append(&namesToAdd, strings.concatenate({curveName, "_inv"}))
		}
	}

	if ids_write(idConfig, &state, namesToAdd[:]) do pipeline.codegenDirty = true
	printf("CURVES BUILD DONE!")
}
