package massimodin_builder

import "core:slice"
import "core:os"
import "core:strings"
import "core:path/filepath"
import "core:fmt"
import "core:bytes"
import "dialogue_builder"

DIALOGUE_IDS_DEFAULT :: `package massimodin

DialogueIDs :: struct{
//<declarations>
//</declarations>
}

di:^DialogueIDs

_reload_dialogue_ids :: proc(){
//<assignments>
//</assignments>
}
`

dialogues_locale_file_update :: proc(path:string, dialogueName:string, entryData:[]u8){
	existingData, _ := os.read_entire_file(path, context.temp_allocator)

	out:bytes.Buffer
	bytes.buffer_init_allocator(&out, 0, len(existingData) + len(entryData), context.temp_allocator)

	//copy over every entry except the one being updated
	r := uintptr(raw_data(existingData))
	eof := r + uintptr(len(existingData))
	for r<eof{
		entryStart := r
		nameLen := uintptr(read(&r, u16))
		dataLen := uintptr(read(&r, u64))
		entryLen := size_of(u16) + size_of(u64) + nameLen + dataLen //header + payload
		if dialogueName != strings.string_from_ptr(cast(^u8)r, int(nameLen)){
			bytes.buffer_write(&out, slice.bytes_from_ptr(rawptr(entryStart), int(entryLen)))
		}
		r = entryStart + entryLen
	}

	if entryData != nil do bytes.buffer_write(&out, entryData)

	if len(out.buf) == 0{
		os.remove(path)
		return
	}
	_ = os.write_entire_file(path, out.buf[:])
}

pipeline_dialogues_run :: proc(pipeline:^Pipeline, fullRebuild:bool){
	idPath, _ := filepath.join({paths.massimodin, "dialogueIDs.g.odin"})

	localeFilePath :: proc(locale:string) -> string{
		return filepath.join({paths.build_win64, "dialogues", fmt.tprintf("%s.dialogue", locale)}, context.temp_allocator) or_else ""
	}

	idConfig := IDConfig{
		path              = idPath,
		declarationPattern = " :^Dialogue,",
		defaultTemplate   = DIALOGUE_IDS_DEFAULT,
		assignmentFormat  = `di.%s = &dialogue._dialogues_map["%s"] or_else nil`,
	}

	state := ids_read(idConfig)
	namesToAdd := make([dynamic]string)

	localeBuffers := make(map[string]bytes.Buffer)

	for &file in pipeline.pendingFiles{
		dialogueName := sanitize_asset_name(filepath.stem(file.path))

		normalizedPath, _ := strings.replace_all(file.path, "\\", "/")
		locale := "en"
		if localeIdx := strings.index(normalizedPath, "/_locales/"); localeIdx >= 0{
			after := normalizedPath[localeIdx + len("/_locales/"):]
			slashIdx := strings.index(after, "/")
			if slashIdx > 0{
				locale = after[:slashIdx]
			}
		}

		if !file.exists{
			if locale == "en"{
				ids_remove(&state, dialogueName)
			}
			if !fullRebuild do dialogues_locale_file_update(localeFilePath(locale), dialogueName, nil)
			continue
		}

		if !fullRebuild do printf("Preprocessing dialogue: %s (%s)", dialogueName, locale)

		if locale not_in localeBuffers{
			localeBuffers[locale] = bytes.Buffer{}
			bytes.buffer_init_allocator(&localeBuffers[locale], 0, 0)
		}

		builtData := dialogue_builder.dialogue_build_file(file.path, &localeBuffers[locale])
		if builtData == nil do continue

		if !fullRebuild{
			if (dialogueName in state.existingIds) && process_running(paths.exe){ //hot reload only supports overwriting existing assets, never adding new ones
				rrBuffer:bytes.Buffer
				bytes.buffer_init_allocator(&rrBuffer, 0, 1 + len(locale) + len(builtData))
				write_v(&rrBuffer, u8(len(locale)))
				bytes.buffer_write_string(&rrBuffer, locale)
				bytes.buffer_write(&rrBuffer, builtData)
				reload_request_write("dialogue", rrBuffer.buf[:])
			}

			//rewrite the existing packed locale file in-place
			dialogues_locale_file_update(localeFilePath(locale), dialogueName, builtData)
		}

		if locale == "en" && !(dialogueName in state.existingIds){
			append(&namesToAdd, dialogueName)
		}
	}

	if fullRebuild{
		for locale,buffer in localeBuffers{
			_ = os.write_entire_file(localeFilePath(locale), buffer.buf[:])
		}
	}

	if ids_write(idConfig, &state, namesToAdd[:]) do pipeline.codegenDirty = true
	print("DIALOGUES BUILD DONE!")
}
