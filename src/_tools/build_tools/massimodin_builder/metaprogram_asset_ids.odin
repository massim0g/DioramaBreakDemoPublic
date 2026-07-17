package massimodin_builder

import "core:os"
import "core:strings"
import "core:fmt"

IDConfig :: struct{
	path:string,
	declarationPattern:string,
	defaultTemplate:string,
	assignmentFormat:string,
}

IDFileState :: struct{
	existingIds:map[string]bool,
	contents:string,
	lines:[]string,
}

ids_read :: proc(idConfig:IDConfig) -> IDFileState{
	state:IDFileState
	state.existingIds = make(map[string]bool)

	if os.exists(idConfig.path){
		data, _ := os.read_entire_file(idConfig.path, context.allocator)
		state.contents = string(data)
		state.lines = strings.split_lines(state.contents)

		reachedDeclarations := false
		for line in state.lines{
			if !reachedDeclarations{
				reachedDeclarations = line == "//<declarations>"
				continue
			}
			if line == "//</declarations>" do break
			id, _ := strings.replace(line, idConfig.declarationPattern, "", 1)
			state.existingIds[id] = true
		}
	}
	else{
		state.contents = idConfig.defaultTemplate
		state.lines = strings.split_lines(state.contents)
	}
	return state
}

//Returns whether the ids file actually changed (additions, or lines blanked by ids_remove)
ids_write :: proc(idConfig:IDConfig, state:^IDFileState, namesToAdd:[]string) -> (changed:bool){
	newDeclLines := make([dynamic]string, 0, len(namesToAdd), context.temp_allocator)
	newAssignLines := make([dynamic]string, 0, len(namesToAdd), context.temp_allocator)

	for name in namesToAdd{
		append(&newDeclLines, fmt.aprintf("%s%s", name, idConfig.declarationPattern))
		append(&newAssignLines, fmt.aprintf(idConfig.assignmentFormat, name, name))
	}

	declInsert := find_line_index(state.lines[:], "//</declarations>")
	assignInsert := find_line_index(state.lines[:], "//</assignments>")

	if declInsert < 0 || assignInsert < 0{
		printf("could not find marker comments in %s", idConfig.path)
		return
	}

	result := make([dynamic]string, 0, len(state.lines) + len(namesToAdd) * 2)
	for i in 0..<declInsert{
		append(&result, state.lines[i])
	}
	for line in newDeclLines{
		append(&result, line)
	}
	for i in declInsert..<assignInsert{
		append(&result, state.lines[i])
	}
	for line in newAssignLines{
		append(&result, line)
	}
	for i in assignInsert..<len(state.lines){
		append(&result, state.lines[i])
	}

	output := strings.join(result[:], "\r\n", context.temp_allocator)
	if output == state.contents do return false //nothing changed, don't touch the file

	_ = os.write_entire_file(idConfig.path, transmute([]u8)output)
	return true
}

ids_remove :: proc(state:^IDFileState, nameToRemove:string){
	pattern := fmt.aprintf("%s ", nameToRemove, allocator=context.temp_allocator)

	for &line in state.lines{
		if strings.contains(line, pattern){
			line = ""
		}
	}
}

//blank every line containing the given substring. For ids with generated suffixes that ids_remove can't match, e.g. fonts' name__size
ids_remove_matching :: proc(state:^IDFileState, substr:string){
	for &line in state.lines{
		if strings.contains(line, substr){
			line = ""
		}
	}
}

