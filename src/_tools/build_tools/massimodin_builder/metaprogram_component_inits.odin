package massimodin_builder

import "core:os"
import "core:strings"
import "core:fmt"
import "core:path/filepath"

COMPONENTS_INITS_DEFAULT :: `package massimodin

CoID :: enum u16{
none,
//<ids>
//</ids>
}

ComponentArrays :: struct{
//<arrays>
//</arrays>
}

coid_of :: #force_inline proc "contextless" ($componentType:typeid) -> CoID{
//<idmap>
//</idmap>
{
	panic_contextless("Tried to get a component id for a non-component type")
}
}

_components_metadata_init :: proc(){
//<inits>
//</inits>
}
`

generate_components_inits :: proc(changedComponents:[]PipelineChangedFile){
	initFilePath, _ := filepath.join({paths.massimodin, "components_metadata_init.g.odin"})

	contents:string
	if os.exists(initFilePath){
		data, _ := os.read_entire_file(initFilePath, context.temp_allocator)
		contents = string(data)
	} else{
		contents = COMPONENTS_INITS_DEFAULT
	}

	lines := slice_to_dynamic(strings.split_lines(contents), context.temp_allocator)

	existingInits := make(map[string]bool)
	inInits := false
	for line in lines{
		if !inInits{
			inInits = line == "//<inits>"
			continue
		}
		if line == "//</inits>" do break
		trimmed := strings.trim_space(line)
		if strings.has_prefix(trimmed, "__") && strings.has_suffix(trimmed, "_set_metadata()"){
			name := trimmed[len("__"):len(trimmed) - len("_set_metadata()")]
			existingInits[name] = true
		}
	}

	initsToAdd := make([dynamic]string)

	for file in changedComponents{
		componentFile := filepath.stem(filepath.base(file.path))
		componentName := strings.trim_prefix(componentFile, "co_")

		if !file.exists{
			pattern := fmt.aprintf("__%s", componentName)
			newLines := make([dynamic]string, 0, len(lines))
			for line in lines{
				if !strings.contains(line, pattern){
					append(&newLines, line)
				}
			}
			lines = newLines
		} else{
			if !(componentName in existingInits){
				append(&initsToAdd, componentName)
			}
		}
	}

	if len(initsToAdd) == 0{
		output := strings.join(lines[:], "\r\n")
		_ = os.write_entire_file(initFilePath, transmute([]u8)output)
		return
	}

	newIdLines := make([dynamic]string, 0, len(initsToAdd))
	newArrayLines := make([dynamic]string, 0, len(initsToAdd))
	newIdmapLines := make([dynamic]string, 0, len(initsToAdd))
	newInitLines := make([dynamic]string, 0, len(initsToAdd))

	for name in initsToAdd{
		capped := capitalize_first(name)
		append(&newIdLines, fmt.aprintf("%s, //__%s", name, name))
		append(&newArrayLines, fmt.aprintf("__%s :[dynamic]%s,", name, capped))
		append(&newIdmapLines, fmt.aprintf("when componentType == %s do return .%s; else //__%s", capped, name, name))
		append(&newInitLines, fmt.aprintf("__%s_set_metadata()", name))
	}

	idInsert := find_line_index(lines[:], "//</ids>")
	arrayInsert := find_line_index(lines[:], "//</arrays>")
	idmapInsert := find_line_index(lines[:], "//</idmap>")
	initInsert := find_line_index(lines[:], "//</inits>")

	if idInsert < 0 || arrayInsert < 0 || idmapInsert < 0 || initInsert < 0{
		printf("ERROR: Marker comments missing in %s, cannot update component inits!", initFilePath)
		return
	}

	result := make([dynamic]string, 0, len(lines) + len(initsToAdd) * 4)

	for i in 0..<idInsert do append(&result, lines[i])
	for l in newIdLines do append(&result, l)
	for i in idInsert..<arrayInsert do append(&result, lines[i])
	for l in newArrayLines do append(&result, l)
	for i in arrayInsert..<idmapInsert do append(&result, lines[i])
	for l in newIdmapLines do append(&result, l)
	for i in idmapInsert..<initInsert do append(&result, lines[i])
	for l in newInitLines do append(&result, l)
	for i in initInsert..<len(lines) do append(&result, lines[i])

	output := strings.join(result[:], "\r\n")
	_ = os.write_entire_file(initFilePath, transmute([]u8)output)
}

