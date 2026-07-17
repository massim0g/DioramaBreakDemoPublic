#+feature using-stmt
package massimodin //@nested-tags:engine/serialization

import "core:encoding/json"
import "core:encoding/base64"
import "core:strings"
import "core:reflect"
import "core:mem"
import "base:runtime"
import "core:os"
import "core:path/filepath"
import "core:io"
import "core:strconv"
import slices "core:slice"
import "core:math/bits"

_json_default_marshal_options := json.Marshal_Options{use_enum_names=true} //basically a constant


JSON_PRETTY_OPT := json.Marshal_Options{pretty=true, use_spaces=true, spaces=2, sort_maps_by_key=true}

//Copies the json value into the space at the given pointer using the given type info. String cloning is done using the context's allocator. 
json_unmarshal_uip :: proc(type:^reflect.Type_Info, val:json.Value, valPtr:uintptr, cloneStrings:=false){
	using reflect

	_, isNull := val.(json.Null)
	if val == nil || isNull{
		mem.zero(rawptr(valPtr), type.size)
		return
	}

	//special cases
	switch type.id{
		case LocaleID:
			id, found := find(dialogue.locales_loaded[:], val.(json.String))
			if !found do (cast(^LocaleID)valPtr)^ = 0
			else do (cast(^LocaleID)valPtr)^ = LocaleID(id)
			return
		case Shader:
			(cast(^Shader)valPtr)^ = shader_find(val.(json.String))
			return
		case Estring:
			es := cast(^Estring)valPtr
			estring_set(es, val.(json.String), cloneStrings)
			return
		case Mesh:
			m := cast(^Mesh)valPtr
			meshVertsString := val.(json.Object)["vertices"].(json.String)
			meshEdgesString := val.(json.Object)["edges"].(json.String)
			clear(&m.vertices)
			clear(&m.edges)
			append_elems(&m.vertices, args=base64_slice_decode(meshVertsString, Vec2))
			append_elems(&m.edges, args=base64_slice_decode(meshEdgesString, [2]u16))
			return
	}

	variant := type.variant
	tid := type.id
	if v, ok := variant.(Type_Info_Named); ok{
		variant = v.base.variant
	}

	switch ti in variant{
		case Type_Info_Struct:
			jsonObj, ok := val.(json.Object)
			if !ok{
				printf("Warning: Could not unmarshal json '%v' as struct!", val)
				return
			}

			fields := struct_fields_zipped(tid)
			for field in fields{
				json_unmarshal(field.type, jsonObj[field.name], valPtr + field.offset, cloneStrings)
			}
		case Type_Info_Array:
			arr, ok := val.(json.Array)
			if !ok{
				printf("Warning: Could not unmarshal json '%v' as array!", val)
				return
			}

			elemType := ti.elem
			elemSize := ti.elem_size
			for i in 0..<len(arr){
				json_unmarshal(elemType, arr[i], valPtr + uintptr(elemSize*i), cloneStrings)
			}
		case Type_Info_Pointer:
			if _,ok := val.(json.Null); ok{
				(cast(^rawptr)valPtr)^ = nil
				return
			}

			jsonString, ok := val.(json.String)
			if !ok{
				printf("Warning: Could not unmarshal json '%v' as %s!", val, type.id)
				return
			}

			switch tid{
				case ^Sprite:
					(cast(^^Sprite)valPtr)^ = &sprites._sprites_map[jsonString]
				case ^Tileset:
					(cast(^^Tileset)valPtr)^ = tileset_get(&sprites._sprites_map[jsonString])
				case ^Dialogue:
					(cast(^^Dialogue)valPtr)^ = &dialogue._dialogues_map[jsonString]
				case ^Stage:
					(cast(^^Stage)valPtr)^ = &stage._stages_map[jsonString]
				case ^Item:
					(cast(^^Item)valPtr)^ = &items.data[jsonString]
				case:
					runtime.print_type(type)
					panic("Unhandled pointer type when unmarshaling json!")
			}
		case Type_Info_Float:
			jsonFloat, ok := val.(json.Float)
			if !ok{
				printf("Warning: Could not unmarshal json '%v' as float!", val)
				return
			}

			switch tid{
				case f32: (cast(^f32)valPtr)^ = f32(jsonFloat)
				case f64: (cast(^f64)valPtr)^ = jsonFloat
				case: panic("Unhandled float type when unmarshaling json!")
			}
		case Type_Info_Integer:
			jsonFloat, ok := val.(json.Float)
			if !ok{
				printf("Warning: Could not unmarshal json '%v' as integer!", val)
				return
			}

			switch tid{
				case int: (cast(^int)valPtr)^ = int(jsonFloat)
				case u64: (cast(^u64)valPtr)^ = u64(jsonFloat)
				case i32: (cast(^i32)valPtr)^ = i32(jsonFloat)
				case u32: (cast(^u32)valPtr)^ = u32(jsonFloat)
				case i16: (cast(^i16)valPtr)^ = i16(jsonFloat)
				case u16: (cast(^u16)valPtr)^ = u16(jsonFloat)
				case i8: (cast(^i8)valPtr)^ = i8(jsonFloat)
				case u8: (cast(^u8)valPtr)^ = u8(jsonFloat)
				case: panicf("Unhandled integer type '%v' when unmarshaling json!", tid)
			}
		case Type_Info_Boolean:
			jsonBool, ok := val.(json.Boolean)
			if !ok{
				printf("Warning: Could not unmarshal json '%v' as boolean!", val)
				return
			}

			(cast(^bool)valPtr)^ = jsonBool
		case Type_Info_String:
			jsonString, ok := val.(json.String)
			if !ok{
				printf("Warning: Could not unmarshal json '%v' as string!", val)
				return
			}

			if(cloneStrings) do (cast(^string)valPtr)^ = string_clone(jsonString)
			else do (cast(^string)valPtr)^ = jsonString
		case Type_Info_Enum:
			#partial switch v in val{
				case json.String: 
					for n, i in ti.names{
						if n == v{
							json_unmarshal(ti.base, json.Float(ti.values[i]), valPtr)
							break
						} 
					}
				case json.Float: json_unmarshal(ti.base, val, valPtr)
				case:
					printf("Warning: Could not unmarshal json '%v' as enum value!", val)
			}
		case Type_Info_Dynamic_Array:
			arr, ok := val.(json.Array)
			if !ok{
				printf("Warning: Could not unmarshal json '%v' as array!", val)
				return
			}

			rawArr := cast(^runtime.Raw_Dynamic_Array)valPtr
			rawArr.len = 0

			elemType := ti.elem
			elemSize := ti.elem_size
			elemAlign := align_of_typeid(elemType.id)
			runtime.__dynamic_array_resize(rawArr, elemSize, elemAlign, len(arr))
			for i in 0..<len(arr){
				json_unmarshal(elemType, arr[i], uintptr(rawArr.data) + uintptr(elemSize*i), cloneStrings)
			}
		case Type_Info_Enumerated_Array:
			arr, ok := val.(json.Array)
			if !ok{
				printf("Warning: Could not unmarshal json '%v' as array!", val)
				return
			}

			elemType := ti.elem
			elemSize := ti.elem_size
			for i in 0..<len(arr){
				json_unmarshal(elemType, arr[i], valPtr + uintptr(elemSize*i), cloneStrings)
			}
		case Type_Info_Fixed_Capacity_Dynamic_Array:
			arr, ok := val.(json.Array)
			if !ok{
				printf("Warning: Could not unmarshal json '%v' as array!", val)
				return
			}

			elemType := ti.elem
			elemSize := ti.elem_size
			count := min(len(arr), ti.capacity)
			for i in 0..<count{
				json_unmarshal(elemType, arr[i], valPtr + uintptr(elemSize*i), cloneStrings)
			}
			(cast(^int)(valPtr + ti.len_offset))^ = count
		case Type_Info_Map:
			jsonObj, ok := val.(json.Object)
			if !ok{
				printf("Warning: Could not unmarshal json '%v' as map!", val)
				return
			}

			rawMap := cast(^runtime.Raw_Map)valPtr
			runtime.map_clear_dynamic(rawMap, ti.map_info)

			for k,v in jsonObj{
				keyVal := new_typeid(ti.key.id, context.temp_allocator)
				json_unmarshal(ti.key, k, uintptr(keyVal), cloneStrings)
				valVal := new_typeid(ti.value.id, context.temp_allocator)
				json_unmarshal(ti.value, v, uintptr(valVal), cloneStrings)
				runtime.__dynamic_map_set_without_hash(rawMap, ti.map_info, keyVal, valVal)
			}
			
		case Type_Info_Rune,              
		Type_Info_Complex,               
		Type_Info_Quaternion,            
		Type_Info_Any,                   
		Type_Info_Type_Id,               
		Type_Info_Multi_Pointer,         
		Type_Info_Procedure,             
		Type_Info_Slice,                 
		Type_Info_Parameters,            
		Type_Info_Union,                 
		Type_Info_Bit_Set,               
		Type_Info_Simd_Vector,           
		Type_Info_Matrix,                
		Type_Info_Soa_Pointer,
		Type_Info_Bit_Field,
		Type_Info_Named:
			runtime.print_type(type)
			panic("Unhandled type when unmarshaling json!")

	}
	
}
json_unmarshal_ptr :: proc(val:json.Value, ptr:^$T, cloneStrings:=false){
	json_unmarshal_uip(type_info_of(T), val, uintptr(ptr), cloneStrings)
}
json_unmarshal :: proc{json_unmarshal_uip, json_unmarshal_ptr}


json_marshal_field :: proc(builder:^strings.Builder, val:any, name:string, trailingComma:=true, options:^json.Marshal_Options=nil){
	strings.write_quoted_string(builder, name)
	strings.write_string(builder, ":")

	json_marshal(builder, val, options)

	if(trailingComma) do strings.write_string(builder, ",")
}

//Encodes raw bytes in a slice to a base64 string before marshalling
json_marshal_field_as_base64 :: proc(builder:^strings.Builder, val:[]$T, name:string, trailingComma:=true, options:^json.Marshal_Options=nil){
	strings.write_quoted_string(builder, name)
	strings.write_string(builder, ":")

	json_marshal(builder, base64.encode(slices.to_bytes(val), allocator=context.temp_allocator), options)

	if(trailingComma) do strings.write_string(builder, ",")
}

base64_slice_encode :: proc(slice:[]$T, allocator:=context.temp_allocator)->string{
	return base64.encode(slices.to_bytes(slice), allocator=allocator)
}
base64_slice_decode :: proc(base64String:string, $elemType:typeid, allocator:=context.temp_allocator) -> []elemType{
	decoded,_ := base64.decode(base64String, allocator=allocator)
	return slices.reinterpret([]elemType, decoded)
}
base64_array_encode :: proc(arr:[dynamic]$T, allocator:=context.temp_allocator)->string{
	return base64_slice_encode(arr[:], allocator)
}
base64_array_decode :: proc(base64String:string, $elemType:typeid, allocator:=context.temp_allocator) -> [dynamic]elemType{
	return slice_to_array(base64_slice_decode(base64String, elemType, allocator), allocator)
}

base64_encode_string :: proc(s:string, allocator:=context.temp_allocator)->string{
	out,_:=base64.encode(transmute([]u8)s, allocator=allocator)
	return out
}
base64_decode_string :: proc(s:string, allocator:=context.temp_allocator)->string{
	out,_:=base64.decode(s, allocator=allocator)
	return cast(string)out
}
base64_encode :: base64.encode
base64_decode :: base64.decode

//Will panic if json fails to parse
json_parse :: proc(data:[]byte, allocator:=context.temp_allocator, loc:=#caller_location) -> json.Value{
	jsonData, err := json.parse(data, json.DEFAULT_SPECIFICATION, false, allocator, loc)
	assertf(err == .None, "Error '%v' parsing json.", err, loc=loc)
	return jsonData
}

json_pointer_type_marshaled_name :: proc(v:any) -> (name:string, ok:bool){
	switch v.id{
		case ^Sprite: return v.(^Sprite).name, true
		case ^Tileset: return v.(^Tileset).sprite.name, true
		case ^Dialogue: return v.(^Dialogue).name, true
		case ^Stage: return v.(^Stage).name, true
		case ^Item: return v.(^Item).id, true
	}
	print("Warning: Tried to marshal unsupported pointer type '%v'!", v)
	return
}

json_marshal_to_builder :: #force_inline proc(b: ^strings.Builder, v: any, opt: ^json.Marshal_Options=nil) -> json.Marshal_Error {
	return json_marshal_to_writer(strings.to_writer(b), v, opt)
}
json_marshal_to_writer :: proc(w: io.Writer, v: any, opt: ^json.Marshal_Options=nil) -> (err: json.Marshal_Error) {
	using json

	if v == nil {
		io.write_string(w, "null") or_return
		return
	}

	opt:=opt
	if(opt == nil) do opt = &_json_default_marshal_options

	//special cases
	switch v.id{
		case LocaleID:
			err = json_marshal_to_writer(w, dialogue.locales_loaded[v.(LocaleID)], opt)
			return
		case Shader:
			err = json_marshal_to_writer(w, shader_name(v.(Shader)), opt)
			return
		case Estring:
			err = json_marshal_to_writer(w, v.(Estring).s, opt)
			return
		case Mesh:
			encoded:struct{
				vertices:string,
				edges:string
			}
			m := v.(Mesh)
			encoded.vertices = base64.encode(slices.to_bytes(m.vertices[:]), allocator=context.temp_allocator)
			encoded.edges = base64.encode(slices.to_bytes(m.edges[:]), allocator=context.temp_allocator)
			err = json_marshal_to_writer(w, encoded, opt)
			return
	}

	ti := runtime.type_info_base(type_info_of(v.id))
	a := any{v.data, ti.id}

	switch info in ti.variant {
	case runtime.Type_Info_Named:
		unreachable()

	case runtime.Type_Info_Integer:
		buf: [40]byte
		u := cast_any_int_to_u128(a)

		s: string

		// allow uints to be printed as hex
		if opt.write_uint_as_hex && (opt.spec == .JSON5 || opt.spec == .MJSON) {
			switch i in a {
			case u8, u16, u32, u64, u128:
				s = strconv.write_bits_128(buf[:], u, 16, info.signed, 8*ti.size, "0123456789abcdef", { .Prefix })

			case:
				s = strconv.write_bits_128(buf[:], u, 10, info.signed, 8*ti.size, "0123456789", nil)
			}
		} else {
			s = strconv.write_bits_128(buf[:], u, 10, info.signed, 8*ti.size, "0123456789", nil)
		}

		io.write_string(w, s) or_return


	case runtime.Type_Info_Rune:
		r := a.(rune)
		io.write_byte(w, '"')                  or_return
		io.write_escaped_rune(w, r, '"', true) or_return
		io.write_byte(w, '"')                  or_return

	case runtime.Type_Info_Float:
		switch f in a {
		case f16: io.write_f16(w, f) or_return
		case f32: io.write_f32(w, f) or_return
		case f64: io.write_f64(w, f) or_return
		case: return .Unsupported_Type
		}

	case runtime.Type_Info_Complex:
		r, i: f64
		switch z in a {
		case complex32:  r, i = f64(real(z)), f64(imag(z))
		case complex64:  r, i = f64(real(z)), f64(imag(z))
		case complex128: r, i = f64(real(z)), f64(imag(z))
		case: return .Unsupported_Type
		}

		io.write_byte(w, '[')    or_return
		io.write_f64(w, r)       or_return
		io.write_string(w, ", ") or_return
		io.write_f64(w, i)       or_return
		io.write_byte(w, ']')    or_return

	case runtime.Type_Info_Quaternion:
		return .Unsupported_Type

	case runtime.Type_Info_String:
		switch s in a {
		case string:  io.write_quoted_string(w, s, '"', nil, true)         or_return
		case cstring: io.write_quoted_string(w, string(s), '"', nil, true) or_return
		}

	case runtime.Type_Info_Boolean:
		val: bool
		switch b in a {
		case bool: val = bool(b)
		case b8:   val = bool(b)
		case b16:  val = bool(b)
		case b32:  val = bool(b)
		case b64:  val = bool(b)
		}
		io.write_string(w, val ? "true" : "false") or_return

	case runtime.Type_Info_Any:
		return .Unsupported_Type

	case runtime.Type_Info_Type_Id:
		return .Unsupported_Type

	case runtime.Type_Info_Pointer:
		if((cast(^rawptr)v.data)^ == nil) do io.write_string(w, "null") or_return
		else{
			if name, ok := json_pointer_type_marshaled_name(v); ok do io.write_quoted_string(w, name, '"', nil, true) or_return
			else do return .Unsupported_Type
		}

	case runtime.Type_Info_Multi_Pointer:
		if((cast(^rawptr)v.data)^ == nil) do io.write_string(w, "null") or_return
		else do return .Unsupported_Type

	case runtime.Type_Info_Soa_Pointer:
		if((cast(^rawptr)v.data)^ == nil) do io.write_string(w, "null") or_return
		else do return .Unsupported_Type

	case runtime.Type_Info_Procedure:
		return .Unsupported_Type

	case runtime.Type_Info_Parameters:
		return .Unsupported_Type

	case runtime.Type_Info_Simd_Vector:
		return .Unsupported_Type

	case runtime.Type_Info_Fixed_Capacity_Dynamic_Array:
		opt_write_start(w, opt, '[') or_return
		length := (cast(^int)(uintptr(v.data) + info.len_offset))^
		for i in 0..<length {
			opt_write_iteration(w, opt, i == 0) or_return
			data := uintptr(v.data) + uintptr(i*info.elem_size)
			json_marshal_to_writer(w, any{rawptr(data), info.elem.id}, opt) or_return
		}
		opt_write_end(w, opt, ']') or_return

	case runtime.Type_Info_Matrix:
		return .Unsupported_Type

	case runtime.Type_Info_Bit_Field:
		return .Unsupported_Type

	case runtime.Type_Info_Array:
		opt_write_start(w, opt, '[') or_return
		for i in 0..<info.count {
			opt_write_iteration(w, opt, i == 0) or_return
			data := uintptr(v.data) + uintptr(i*info.elem_size)
			json_marshal_to_writer(w, any{rawptr(data), info.elem.id}, opt) or_return
		}
		opt_write_end(w, opt, ']') or_return
		
	case runtime.Type_Info_Enumerated_Array:
		opt_write_start(w, opt, '[') or_return
		for i in 0..<info.count {
			opt_write_iteration(w, opt, i == 0) or_return
			data := uintptr(v.data) + uintptr(i*info.elem_size)
			json_marshal_to_writer(w, any{rawptr(data), info.elem.id}, opt) or_return
		}
		opt_write_end(w, opt, ']') or_return
		
	case runtime.Type_Info_Dynamic_Array:
		opt_write_start(w, opt, '[') or_return
		array := cast(^mem.Raw_Dynamic_Array)v.data
		for i in 0..<array.len {
			opt_write_iteration(w, opt, i == 0) or_return
			data := uintptr(array.data) + uintptr(i*info.elem_size)
			json_marshal_to_writer(w, any{rawptr(data), info.elem.id}, opt) or_return
		}
		opt_write_end(w, opt, ']') or_return

	case runtime.Type_Info_Slice:
		opt_write_start(w, opt, '[') or_return
		slice := cast(^mem.Raw_Slice)v.data
		for i in 0..<slice.len {
			opt_write_iteration(w, opt, i == 0) or_return
			data := uintptr(slice.data) + uintptr(i*info.elem_size)
			json_marshal_to_writer(w, any{rawptr(data), info.elem.id}, opt) or_return
		}
		opt_write_end(w, opt, ']') or_return

	case runtime.Type_Info_Map:
		m := (^mem.Raw_Map)(v.data)
		opt_write_start(w, opt, '{') or_return

		if m != nil {
			if info.map_info == nil {
				return .Unsupported_Type
			}
			map_cap := uintptr(runtime.map_cap(m^))
			ks, vs, hs, _, _ := runtime.map_kvh_data_dynamic(m^, info.map_info)

			if !opt.sort_maps_by_key {
				i := 0
				for bucket_index in 0..<map_cap {
					runtime.map_hash_is_valid(hs[bucket_index]) or_continue

					opt_write_iteration(w, opt, i == 0) or_return
					i += 1

					key   := rawptr(runtime.map_cell_index_dynamic(ks, info.map_info.ks, bucket_index))
					value := rawptr(runtime.map_cell_index_dynamic(vs, info.map_info.vs, bucket_index))

					// check for string type
					{
						kv  := any{key, info.key.id}
						kti := runtime.type_info_base(type_info_of(kv.id))
						ka  := any{kv.data, kti.id}
						name: string

						#partial switch info in kti.variant {
						case runtime.Type_Info_String:
							switch s in ka {
							case string: name = s
							case cstring: name = string(s)
							}
							opt_write_key(w, opt, name) or_return
						case runtime.Type_Info_Integer:
							buf: [40]byte
							u := cast_any_int_to_u128(ka)
							name = strconv.write_bits_128(buf[:], u, 10, info.signed, 8*kti.size, "0123456789", nil)
							
							opt_write_key(w, opt, name) or_return
						case runtime.Type_Info_Pointer:
							if((cast(^rawptr)kv.data)^ == nil) do opt_write_key(w, opt, "null") or_return
							else{
								if name_, ok := json_pointer_type_marshaled_name(kv); ok do opt_write_key(w, opt, name_) or_return
								else do return .Unsupported_Type
							}
						case: return .Unsupported_Type
						}
					}

					json_marshal_to_writer(w, any{value, info.value.id}, opt) or_return
				}
			} else {
				Entry :: struct {
					key: string,
					value: any,
				}

				// If we are sorting the map by key, then we temp alloc an array
				// and sort it, then output the result.
				sorted := make([dynamic]Entry, 0, map_cap, context.temp_allocator)
				for bucket_index in 0..<map_cap {
					runtime.map_hash_is_valid(hs[bucket_index]) or_continue

					key   := rawptr(runtime.map_cell_index_dynamic(ks, info.map_info.ks, bucket_index))
					value := rawptr(runtime.map_cell_index_dynamic(vs, info.map_info.vs, bucket_index))
					name: string

					// check for string type
					{
						kv  := any{key, info.key.id}
						kti := runtime.type_info_base(type_info_of(kv.id))
						ka  := any{kv.data, kti.id}

						#partial switch info in kti.variant {
						case runtime.Type_Info_String:
							switch s in ka {
							case string: name = s
							case cstring: name = string(s)
							}
						case runtime.Type_Info_Pointer:
							if((cast(^rawptr)kv.data)^ == nil) do name = "null"
							else{
								if _name,ok := json_pointer_type_marshaled_name(kv); ok do name = _name
								else do return .Unsupported_Type
							}
						case: return .Unsupported_Type
						}
					}

					append(&sorted, Entry { key = name, value = any{value, info.value.id}})
				}

				slices.sort_by(sorted[:], proc(i, j: Entry) -> bool { return i.key < j.key })

				for s, i in sorted {
					opt_write_iteration(w, opt, i == 0) or_return
					opt_write_key(w, opt, s.key) or_return
					json_marshal_to_writer(w, s.value, opt) or_return
				}
			}
		}

		opt_write_end(w, opt, '}') or_return

	case runtime.Type_Info_Struct:
		is_omitempty :: proc(v: any) -> bool {
			v := v
			if v == nil {
				return true
			}
			ti := runtime.type_info_core(type_info_of(v.id))
			#partial switch info in ti.variant {
			case runtime.Type_Info_String:
				switch x in v {
				case string:
					return x == ""
				case cstring:
					return x == nil || x == ""
				}
			case runtime.Type_Info_Any:
				return v.(any) == nil
			case runtime.Type_Info_Type_Id:
				return v.(typeid) == nil
			case runtime.Type_Info_Pointer,
			     runtime.Type_Info_Multi_Pointer,
			     runtime.Type_Info_Procedure:
				return (^rawptr)(v.data)^ == nil
			case runtime.Type_Info_Dynamic_Array:
				return (^runtime.Raw_Dynamic_Array)(v.data).len == 0
			case runtime.Type_Info_Slice:
				return (^runtime.Raw_Slice)(v.data).len == 0
			case runtime.Type_Info_Union,
			     runtime.Type_Info_Bit_Set,
			     runtime.Type_Info_Soa_Pointer:
				return reflect.is_nil(v)
			case runtime.Type_Info_Map:
				return (^runtime.Raw_Map)(v.data).len == 0
			}
			return false
		}

		marshal_struct_fields :: proc(w: io.Writer, v: any, opt: ^Marshal_Options) -> (err: Marshal_Error) {
			ti := runtime.type_info_base(type_info_of(v.id))
			info := ti.variant.(runtime.Type_Info_Struct)
			first_iteration := true
			for name, i in info.names[:info.field_count] {
				omitempty := false

				json_name, extra := json_name_from_tag_value(reflect.struct_tag_get(reflect.Struct_Tag(info.tags[i]), "json"))

				if json_name == "-" {
					continue
				}

				for flag in strings.split_iterator(&extra, ",") {
					switch flag {
					case "omitempty":
						omitempty = true
					}
				}

				id := info.types[i].id
				data := rawptr(uintptr(v.data) + info.offsets[i])
				the_value := any{data, id}

				if omitempty && is_omitempty(the_value) {
					continue
				}

				opt_write_iteration(w, opt, first_iteration) or_return
				first_iteration = false
				if json_name != "" {
					opt_write_key(w, opt, json_name) or_return
				} else {
					// Marshal the fields of 'using _: T' fields directly into the parent struct
					if info.usings[i] && name == "_" {
						marshal_struct_fields(w, the_value, opt) or_return
						continue
					} else {
						opt_write_key(w, opt, name) or_return
					}
				}


				json_marshal_to_writer(w, the_value, opt) or_return
			}
			return
		}
		
		opt_write_start(w, opt, '{') or_return
		marshal_struct_fields(w, v, opt) or_return
		opt_write_end(w, opt, '}') or_return

	case runtime.Type_Info_Union:
		if len(info.variants) == 0 || v.data == nil {
			io.write_string(w, "null") or_return
			return nil
		}

		tag_ptr := uintptr(v.data) + info.tag_offset
		tag_any := any{rawptr(tag_ptr), info.tag_type.id}

		tag: i64 = -1
		switch i in tag_any {
		case u8:   tag = i64(i)
		case i8:   tag = i64(i)
		case u16:  tag = i64(i)
		case i16:  tag = i64(i)
		case u32:  tag = i64(i)
		case i32:  tag = i64(i)
		case u64:  tag = i64(i)
		case i64:  tag = i64(i)
		case: panic("Invalid union tag type")
		}

		if !info.no_nil {
			if tag == 0 {
				io.write_string(w, "null") or_return
				return nil
			}
			tag -= 1
		}
		id := info.variants[tag].id
		return json_marshal_to_writer(w, any{v.data, id}, opt)

	case runtime.Type_Info_Enum:
		if !opt.use_enum_names || len(info.names) == 0 {
			return json_marshal_to_writer(w, any{v.data, info.base.id}, opt)
		} else {
			name, found := reflect.enum_name_from_value_any(v)
			if found {
				return json_marshal_to_writer(w, name, opt)
			} else {
				return json_marshal_to_writer(w, any{v.data, info.base.id}, opt)
			}
		}

	case runtime.Type_Info_Bit_Set:
		is_bit_set_different_endian_to_platform :: proc(ti: ^runtime.Type_Info) -> bool {
			if ti == nil {
				return false
			}
			t := runtime.type_info_base(ti)
			#partial switch info in t.variant {
			case runtime.Type_Info_Integer:
				switch info.endianness {
				case .Platform: return false
				case .Little:   return ODIN_ENDIAN != .Little
				case .Big:      return ODIN_ENDIAN != .Big
				}
			}
			return false
		}

		bit_data: u64
		bit_size := u64(8*ti.size)

		do_byte_swap := is_bit_set_different_endian_to_platform(info.underlying)

		switch bit_size {
		case  0: bit_data = 0
		case  8:
			x := (^u8)(v.data)^
			bit_data = u64(x)
		case 16:
			x := (^u16)(v.data)^
			if do_byte_swap {
				x = bits.byte_swap(x)
			}
			bit_data = u64(x)
		case 32:
			x := (^u32)(v.data)^
			if do_byte_swap {
				x = bits.byte_swap(x)
			}
			bit_data = u64(x)
		case 64:
			x := (^u64)(v.data)^
			if do_byte_swap {
				x = bits.byte_swap(x)
			}
			bit_data = u64(x)
		case: panic("unknown bit_size size")
		}
		io.write_u64(w, bit_data) or_return
	}

	return
}
//overrode core library's marshal function because it's bugged. Also added asset serialization functionality
json_marshal :: proc{json_marshal_to_builder, json_marshal_to_writer}

//makes a new builder and marshals to it, then returns the result
json_encode :: proc(v:any, allocator:=context.allocator,  opt: ^json.Marshal_Options=nil) -> (string, json.Marshal_Error){
	b := strings.builder_make(allocator)
	err := json_marshal_to_builder(&b, v, opt)
	shrink(&b.buf)
	return strings.to_string(b), err
}

cast_any_int_to_u128 :: proc(any_int_value: any) -> u128 {
	u: u128 = 0
	switch i in any_int_value {
	case i8:      u = u128(i)
	case i16:     u = u128(i)
	case i32:     u = u128(i)
	case i64:     u = u128(i)
	case i128:    u = u128(i)
	case int:     u = u128(i)
	case u8:      u = u128(i)
	case u16:     u = u128(i)
	case u32:     u = u128(i)
	case u64:     u = u128(i)
	case u128:    u = u128(i)
	case uint:    u = u128(i)
	case uintptr: u = u128(i)

	case i16le:  u = u128(i)
	case i32le:  u = u128(i)
	case i64le:  u = u128(i)
	case u16le:  u = u128(i)
	case u32le:  u = u128(i)
	case u64le:  u = u128(i)
	case u128le: u = u128(i)

	case i16be:  u = u128(i)
	case i32be:  u = u128(i)
	case i64be:  u = u128(i)
	case u16be:  u = u128(i)
	case u32be:  u = u128(i)
	case u64be:  u = u128(i)
	case u128be: u = u128(i)
	}

	return u
}
json_name_from_tag_value :: proc(value: string) -> (json_name, extra: string) {
	json_name = value
	if comma_index := strings.index_byte(json_name, ','); comma_index >= 0 {
		json_name = json_name[:comma_index]
		extra = value[1 + comma_index:]
	}
	return
}