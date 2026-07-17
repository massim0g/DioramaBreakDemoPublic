package massimodin_builder

import "core:os"
import "core:strings"
import "core:fmt"
import "core:path/filepath"

COMPONENT_META_TEMPLATE :: `package massimodin

import "core:mem"
import "core:slice"
import "core:reflect"

_{{COMPONENT_NAME}}_remove_from_array :: proc(index:int){
	unordered_remove(&{{ARRAY_NAME}}, index)

	//refresh pointers on the component that got moved to the old component's place
	if(len({{ARRAY_NAME}}) > index){
		component := &({{ARRAY_NAME}}[index])
		_component_entity_array_pointer_refresh(component)
		_component_refs_refresh(component)
	}
}
__{{COMPONENT_NAME}}_set_metadata :: proc(){

	if(raw_data({{ARRAY_NAME}}) == nil) do init(&{{ARRAY_NAME}})

	tid := typeid_of({{CAPPED_NAME}})

    eventPriorities := EVENT_NIL_ARRAY
    {{PRIORITIES}}

	eFieldNames := []string{
		{{EDITABLE_FIELDS}}
	}
	eFields := make([dynamic]reflect.Struct_Field, len(eFieldNames), assets.allocator)
	for name, i in eFieldNames{
		eFields[i] = reflect.struct_field_by_name(tid, name)
		assert(eFields[i].type.id != string, "Tried to use a string as an editable field! Use an Estring!")
	}

    entities.component_type_metadata[{{CO_ID}}] = ComponentTypeMetadata{
		name = "{{COMPONENT_NAME}}",
        EventPriorities = eventPriorities,
		editableFields = eFields[:],
        isRenderComponent = {{IS_RENDER}},
		type = tid,
        process_array = proc(event:Event){
            for &entity in {{ARRAY_NAME}}{
                _{{COMPONENT_NAME}}_process_event(&entity, event)
            }
        },
        process = _{{COMPONENT_NAME}}_process_event,
        append_to_array = proc(bufferedComponent:^ComponentBase) -> ^ComponentBase{
            preCap := cap({{ARRAY_NAME}})
            append_elem(&({{ARRAY_NAME}}), (cast(^{{CAPPED_NAME}})bufferedComponent)^)
			out := &({{ARRAY_NAME}}[len({{ARRAY_NAME}})-1])
            if(preCap != cap({{ARRAY_NAME}})){ //update entity pointers for other, existing components on array resize. Entity pointers all need to be done first.
				for i:=0;i<len({{ARRAY_NAME}});i+=1{
                    _component_entity_array_pointer_refresh(&({{ARRAY_NAME}}[i]))
                }
                for i:=0;i<len({{ARRAY_NAME}});i+=1{
                    _component_refs_refresh(&({{ARRAY_NAME}}[i]))
                }
            }
			else{
				_component_entity_array_pointer_refresh(out)
				_component_refs_refresh(out)
			}
            return out
        },
		remove_from_array = _{{COMPONENT_NAME}}_remove_from_array,
		move_to_heap = proc(index:int) -> ^ComponentBase{
			out := new_clone({{ARRAY_NAME}}[index])
			_{{COMPONENT_NAME}}_remove_from_array(index)
			return out
		},
		get_component_index = proc(component:^ComponentBase) -> int{
			return mem.ptr_sub(cast(^{{CAPPED_NAME}})component, &{{ARRAY_NAME}}[0])
		},
		get_array_pointer = proc() -> ^RawArray{
			return cast(^RawArray)&{{ARRAY_NAME}}
		},
		clear_array = proc(){
			clear(&{{ARRAY_NAME}})
			reserve(&{{ARRAY_NAME}}, 1)
		}
    }
    for e in RENDER_EVENTS{
        assert(entities.component_type_metadata[coid_of({{CAPPED_NAME}})].isRenderComponent || entities.component_type_metadata[coid_of({{CAPPED_NAME}})].EventPriorities[e] == EVENT_NIL_PRIORITY, "Error: {{CAPPED_NAME}} has a render event defined but isn't a render component.")
    }
}
`

generate_component_meta :: proc(componentPath:string){
	data, readErr := os.read_entire_file(componentPath, context.allocator)
	if readErr != nil{
		printf("ERROR: Could not read %s, %v", componentPath, readErr)
		return
	}
	contents := string(data)
	lines := strings.split_lines(contents)

	componentFile := filepath.stem(filepath.base(componentPath))
	componentName := strings.trim_prefix(componentFile, "co_")
	cappedName := capitalize_first(componentName)
	arrayName := fmt.aprintf("entities._component_arrays.__%s", componentName)
	coId := fmt.aprintf("CoID.%s", componentName)

	searchForBase := true
	isRenderComponent := "false"
	priorityLines := make([dynamic]string)
	editableFields := make([dynamic]string)

	//parse component file
	for line in lines{
		if searchForBase{
			if strings.contains(line, "using base:"){
				if strings.contains(line, "RenderComponentBase,"){
					isRenderComponent = "true"
				}
				searchForBase = false
			}
		} else{
			trimmed := strings.trim_left_space(line)

			//editable fields
			if strings.has_suffix(strings.trim_right_space(line), "//@e") || strings.has_suffix(strings.trim_right_space(line), "// @e"){
				colonIdx := strings.index(trimmed, ":")
				if colonIdx > 0{
					fieldPart := strings.trim_space(trimmed[:colonIdx])
					words := strings.fields(fieldPart)
					if len(words) > 0{
						append(&editableFields, words[len(words) - 1])
					}
				}
			}

			//event priorities. Match the archived `^case \.(.*?):` regex exactly: only top-level
			//event cases at column 0, NOT indented `case` lines inside nested switches.
			if strings.has_prefix(line, "case ."){
				colonIdx := strings.index(line, ":")
				if colonIdx > 0{
					eventName := line[len("case ."):colonIdx]

					//optional priority: `//@p <int>` right after the colon, else 0 (matches `:\s*//@p (-?\d+)`)
					priority := "0"
					afterColon := strings.trim_left_space(line[colonIdx + 1:])
					if strings.has_prefix(afterColon, "//@p"){
						nums := strings.fields(afterColon[len("//@p"):])
						if len(nums) > 0 do priority = nums[0]
					}
					append(&priorityLines, fmt.aprintf("eventPriorities[.%s] = %s", eventName, priority))
				}
			}
		}
	}

	priorities := strings.join(priorityLines[:], "\r\n    ")

	editableFieldsStr := ""
	if len(editableFields) > 0{
		quoted := make([dynamic]string, 0, len(editableFields))
		for f in editableFields{
			append(&quoted, fmt.aprintf("\"%s\"", f))
		}
		editableFieldsStr = strings.join(quoted[:], ",\r\n\t\t")
	}

	genPath := strings.concatenate({componentPath[:len(componentPath) - len(".odin")], "_meta.g.odin"})

	output := COMPONENT_META_TEMPLATE
	output, _ = strings.replace_all(output, "{{COMPONENT_NAME}}", componentName)
	output, _ = strings.replace_all(output, "{{CAPPED_NAME}}", cappedName)
	output, _ = strings.replace_all(output, "{{ARRAY_NAME}}", arrayName)
	output, _ = strings.replace_all(output, "{{CO_ID}}", coId)
	output, _ = strings.replace_all(output, "{{IS_RENDER}}", isRenderComponent)
	output, _ = strings.replace_all(output, "{{PRIORITIES}}", priorities)
	output, _ = strings.replace_all(output, "{{EDITABLE_FIELDS}}", editableFieldsStr)

	_ = os.write_entire_file(genPath, transmute([]u8)output)
}

