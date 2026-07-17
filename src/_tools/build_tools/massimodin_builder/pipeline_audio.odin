package massimodin_builder

import "core:os"
import "core:strings"
import "core:path/filepath"
import "core:encoding/xml"

AUDIO_IDS_DEFAULT :: `package massimodin

import "../fmod/core"

AudioIDs :: struct{
//<declarations>
//</declarations>
}

au:^AudioIDs

_reload_audioEvent_ids :: proc(){
//<assignments>
//</assignments>
}
`

FmodEventInfo :: struct{
	name:string,
	bankGuids:[]string,
}

parse_fmod_event_xml :: proc(path:string) -> (info:FmodEventInfo, ok:bool){
	data, readErr := os.read_entire_file(path, context.temp_allocator)
	if readErr != nil do return {}, false

	doc, parseErr := xml.parse(data, allocator=context.temp_allocator)
	if parseErr != nil do return {}, false

	for &elem, idx in doc.elements{
		if elem.ident == "object"{
			classVal := xml_attr(&elem, "class")
			if classVal == "Event"{
				info.name = xml_property_value(doc, idx, "name")
				info.bankGuids = xml_relationship_destinations(doc, idx, "banks")
				return info, true
			}
		}
	}
	return {}, false
}

xml_attr :: proc(elem:^xml.Element, attrName:string) -> string{
	for attr in elem.attribs{
		if attr.key == attrName{
			return attr.val
		}
	}
	return ""
}

xml_property_value :: proc(doc:^xml.Document, parentIdx:int, propName:string) -> string{
	parent := &doc.elements[parentIdx]
	for childVal in parent.value{
		childId, isElem := childVal.(xml.Element_ID)
		if !isElem do continue
		child := &doc.elements[childId]
		if child.ident == "property"{
			nameAttr := xml_attr(child, "name")
			if nameAttr == propName{
				for vcVal in child.value{
					vcId, vcIsElem := vcVal.(xml.Element_ID)
					if !vcIsElem do continue
					vc := &doc.elements[vcId]
					if vc.ident == "value"{
						return xml_element_text(vc)
					}
				}
			}
		}
	}
	return ""
}

xml_relationship_destinations :: proc(doc:^xml.Document, parentIdx:int, relName:string) -> []string{
	result := make([dynamic]string, context.temp_allocator)
	parent := &doc.elements[parentIdx]
	for childVal in parent.value{
		childId, isElem := childVal.(xml.Element_ID)
		if !isElem do continue
		child := &doc.elements[childId]
		if child.ident == "relationship"{
			nameAttr := xml_attr(child, "name")
			if nameAttr == relName{
				for destVal in child.value{
					destId, destIsElem := destVal.(xml.Element_ID)
					if !destIsElem do continue
					dest := &doc.elements[destId]
					if dest.ident == "destination"{
						text := xml_element_text(dest)
						if len(text) > 0 do append(&result, text)
					}
				}
			}
		}
	}
	return result[:]
}

xml_element_text :: proc(elem:^xml.Element) -> string{
	for child in elem.value{
		text, isText := child.(string)
		if isText do return text
	}
	return ""
}

audio_bank_name_get :: proc(bankFile:string) -> string{
	data, readErr := os.read_entire_file(bankFile, context.temp_allocator)
	if readErr != nil do return ""

	doc, parseErr := xml.parse(data, allocator=context.temp_allocator)
	if parseErr != nil do return ""

	for &elem, idx in doc.elements{
		if elem.ident == "object"{
			classVal := xml_attr(&elem, "class")
			if classVal == "Bank"{
				return xml_property_value(doc, idx, "name")
			}
		}
	}
	return ""
}

audio_banks_build :: proc(audioDir:string, bankGuids:[]string){
	banks := make([dynamic]string)

	if bankGuids == nil{ //full rebuild, rebuild all banks
		bankFiles,_ := os.read_directory_by_path(filepath.join({audioDir, "Metadata/Bank"}) or_else "", 0, context.temp_allocator)
		for file in bankFiles do append(&banks, audio_bank_name_get(file.fullpath))
	}
	else{
		append(&banks, "Master")
	
		for guid in bankGuids{
			bankFile, _ := filepath.join({audioDir, "Metadata/Bank", strings.concatenate({guid, ".xml"})})
			name := audio_bank_name_get(bankFile)
			if name != ""{
				found := false
				for existing in banks{
					if existing == name{
						found = true
						break
					}
				}
				if !found do append(&banks, name)
			}
		}
	}

	bankList := strings.join(banks[:], ",")

	fsproPath,_ := filepath.join({audioDir, "massimodin.fspro"})

	//Prefer the project-local FMOD Studio installed by install.ps1, falling back to PATH
	fmodStudioExe := "fmodstudio"
	localFmodStudio, _ := filepath.join({paths.project, ".deps/fmod_studio/fmodstudio.exe"}, context.temp_allocator)
	if os.exists(localFmodStudio) do fmodStudioExe = localFmodStudio

	//Args go straight to the process (no shell), so they must NOT be wrapped in quotes.
	//For a full rebuild, build everything; for incremental, restrict to the affected banks.
	cmd := make([dynamic]string, context.temp_allocator)
	append(&cmd, fmodStudioExe, "-build")
	if bankGuids != nil do append(&cmd, "-banks", bankList, "-platforms", "Desktop")
	append(&cmd, fsproPath)

	handle, fmodErr := os.process_start({command = cmd[:]})
	if fmodErr != nil{
		printf("ERROR: Failed to start FMOD build")
		return
	}

	//Wait so banks are present before the build is reported complete.
	state, _ := os.process_wait(handle)
	if state.exit_code != 0 do printf("ERROR: FMOD bank build failed (exit %d)", state.exit_code)
}

audio_event_cache_path :: proc() -> string{
	path, _ := filepath.join({paths.build, "cachedAudioEvents.txt"})
	return path
}

//each line is "filePath=eventName"
audio_event_cache_read :: proc() -> map[string]string{
	out := make(map[string]string)
	data, err := os.read_entire_file(audio_event_cache_path(), context.temp_allocator)
	if err != nil do return out

	for line in strings.split_lines(string(data)){
		eq := strings.index(line, "=")
		if eq < 0 do continue
		out[line[:eq]] = line[eq+1:]
	}
	return out
}

audio_event_cache_write :: proc(cache:map[string]string){
	b := strings.builder_make()
	for path, name in cache{
		strings.write_string(&b, path)
		strings.write_byte(&b, '=')
		strings.write_string(&b, name)
		strings.write_string(&b, "\r\n")
	}
	_ = os.write_entire_file(audio_event_cache_path(), transmute([]u8)strings.to_string(b))
}

pipeline_audio_run :: proc(pipeline:^Pipeline, fullRebuild:bool){
	idPath, _ := filepath.join({paths.massimodin, "audioIDs.g.odin"})
	audioDir, _ := filepath.join({paths.project, "audio"})

	idConfig := IDConfig{
		path              = idPath,
		declarationPattern = " :AudioEvent,", //leading space so ids_remove's "name " pattern matches declarations, not just assignments
		defaultTemplate   = AUDIO_IDS_DEFAULT,
		assignmentFormat  = "au.%s = audio._events_map[\"%s\"] or_else nil",
	}

	idState := ids_read(idConfig)
	idsToAdd := make([dynamic]string)
	bankGuids := make([dynamic]string)
	eventCache := fullRebuild ? make(map[string]string) : audio_event_cache_read()

	if fullRebuild{
		for file in pipeline.pendingFiles{
			eventInfo, ok := parse_fmod_event_xml(file.path)
			if !ok do continue
			camelName := to_camel_case(eventInfo.name)
			append(&idsToAdd, camelName)
			eventCache[file.path] = camelName
		}
	} 
	else{
		for file in pipeline.pendingFiles{
			if file.exists{
				eventInfo, ok := parse_fmod_event_xml(file.path)
				if !ok do continue

				camelName := to_camel_case(eventInfo.name)
				printf("Reloading fmod event: %s", camelName)

				if !(camelName in idState.existingIds) do append(&idsToAdd, camelName)
				eventCache[file.path] = camelName

				for guid in eventInfo.bankGuids{
					found := false
					for existing in bankGuids{
						if existing == guid{
							found = true
							break
						}
					}
					if !found do append(&bankGuids, guid)
				}
			} 
			else{
				cachedName, found := eventCache[file.path]
				if found{
					printf("Removing deleted fmod event: %s", cachedName)
					ids_remove(&idState, cachedName)
					delete_key(&eventCache, file.path)
				}
			}
		}
	}

	if ids_write(idConfig, &idState, idsToAdd[:]) do pipeline.codegenDirty = true
	audio_event_cache_write(eventCache)

	if fullRebuild || len(bankGuids) > 0 do audio_banks_build(audioDir, fullRebuild ? nil : bankGuids[:])

	printf("AUDIO BUILD DONE!")
}