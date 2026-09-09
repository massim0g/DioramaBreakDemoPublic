package massimodin_builder

import "core:os"
import "core:fmt"
import "core:strings"
import "core:strconv"
import "core:path/filepath"

/*
Shaders are HLSL, compiled at runtime through SDL_shadercross (SPIRV -> device backend).
This pipeline copies each .hlsl into the build dir for packing, and generates shaderParams.g.odin:
- one Sh_<PascalCase> struct per shader that declares a cbuffer.
- the ShaderParams union over them.
- _shader_params_init to attach the right variant at load.

The asset name keeps the stage suffix, e.g. quad.vert.hlsl packs as "quad.vert", which is how _shader_load tells vertex shaders from fragment shaders. Only fragment shaders get params.
*/

ShaderField :: struct{
	name:string,
	odinType:string,
	offset:int, //hlsl byte offset within the cbuffer
	size:int,
}

ShaderBoundTexture :: struct{
	name:string,
	slot:int, //index into the engine's extra-texture array, i.e. register number minus the draw's own t0
}

/*
Lays out a cbuffer member per HLSL packing rules:
- members pack on 4-byte granularity but may not straddle a 16-byte row
- arrays and matrices start on a row boundary with every element (or column) occupying a full row of its own.
That last rule means an int[64] costs 1024 bytes, not 256.
*/
shader_field_layout :: proc(hlslType:string, arrayCount:int) -> (odinType:string, size:int, rowAligned:bool, ok:bool){
	scalar:string
	rest:string
	switch{
		case strings.has_prefix(hlslType, "float"): scalar = "f32"; rest = hlslType[len("float"):]
		case strings.has_prefix(hlslType, "uint"):  scalar = "u32"; rest = hlslType[len("uint"):]
		case strings.has_prefix(hlslType, "int"):   scalar = "i32"; rest = hlslType[len("int"):]
		case: return "", 0, false, false
	}

	//arrays always get a full 16-byte row per element, so every element becomes a 4-wide vector
	if arrayCount > 0{
		return fmt.aprintf("[%d][4]%s", arrayCount, scalar), arrayCount*16, true, true
	}

	//matrix, e.g. float3x3 -> one 16-byte row per column
	if xInd := strings.index_byte(rest, 'x'); xInd >= 0{
		rows, rowsOk := strconv.parse_int(rest[:xInd])
		if !rowsOk || rows <= 0 do return "", 0, false, false
		return fmt.aprintf("[%d][4]%s", rows, scalar), rows*16, true, true
	}

	if rest == "" do return scalar, 4, false, true //plain scalar

	components, compOk := strconv.parse_int(rest)
	if !compOk || components < 2 || components > 4 do return "", 0, false, false
	return fmt.aprintf("[%d]%s", components, scalar), components*4, false, true
}



/*
Pulls additional bound texture Texture2D declarations out of an HLSL source.
The register number is the truth: t0 is always the draw's own texture, and everything above it is an extra the caller binds by name, so t1 becomes bound textures' slot 0.
*/
shader_bound_textures_parse :: proc(source:string) -> [dynamic]ShaderBoundTexture{
	out := make([dynamic]ShaderBoundTexture)

	for line in strings.split_lines(source, context.temp_allocator){
		text := line
		if c := strings.index(text, "//"); c >= 0 do text = text[:c]

		declInd := strings.index(text, "Texture2D")
		if declInd < 0 do continue
		text = text[declInd+len("Texture2D"):]

		//an optional element type, e.g. Texture2D<float4>
		if strings.has_prefix(strings.trim_left_space(text), "<"){
			close := strings.index_byte(text, '>')
			if close < 0 do continue
			text = text[close+1:]
		}

		colon := strings.index_byte(text, ':')
		if colon < 0 do continue
		name := strings.trim_space(text[:colon])

		regInd := strings.index(text, "register(t")
		if regInd < 0 do continue
		rest := text[regInd+len("register(t"):]
		end := 0
		for end < len(rest) && rest[end] >= '0' && rest[end] <= '9' do end += 1
		register, ok := strconv.parse_int(rest[:end])
		if !ok || register == 0 do continue //t0 is the draw's own texture, never bound by name

		append(&out, ShaderBoundTexture{name=name, slot=register-1})
	}

	return out
}

/*
Pulls fragment storage buffer (StructuredBuffer) declarations out of an HLSL source.
Storage buffers continue the t register numbering after the sampled textures, but their API binding slots restart at 0, so the slot is the register minus the sampled texture count.
*/
shader_storage_buffers_parse :: proc(source:string, sampledTextureCount:int) -> [dynamic]ShaderBoundTexture{
	out := make([dynamic]ShaderBoundTexture)

	for line in strings.split_lines(source, context.temp_allocator){
		text := line
		if c := strings.index(text, "//"); c >= 0 do text = text[:c]

		declInd := strings.index(text, "StructuredBuffer")
		if declInd < 0 do continue
		if declInd >= 2 && text[declInd-2:declInd] == "RW" do continue //RWStructuredBuffer is compute-only, never a graphics-stage read buffer
		text = text[declInd+len("StructuredBuffer"):]

		if strings.has_prefix(strings.trim_left_space(text), "<"){
			close := strings.index_byte(text, '>')
			if close < 0 do continue
			text = text[close+1:]
		}

		colon := strings.index_byte(text, ':')
		if colon < 0 do continue
		name := strings.trim_space(text[:colon])

		regInd := strings.index(text, "register(t")
		if regInd < 0 do continue
		rest := text[regInd+len("register(t"):]
		end := 0
		for end < len(rest) && rest[end] >= '0' && rest[end] <= '9' do end += 1
		register, ok := strconv.parse_int(rest[:end])
		if !ok do continue

		append(&out, ShaderBoundTexture{name=name, slot=register-sampledTextureCount})
	}

	return out
}

//Parses the first cbuffer in an HLSL source and returns its members with their computed byte offsets.
shader_cbuffer_parse :: proc(source:string, shaderName:string) -> (fields:[dynamic]ShaderField, totalSize:int){
	fields = make([dynamic]ShaderField)

	cbufInd := strings.index(source, "cbuffer")
	if cbufInd < 0 do return fields, 0
	openInd := strings.index_byte(source[cbufInd:], '{')
	if openInd < 0 do return fields, 0
	openInd += cbufInd
	closeInd := strings.index_byte(source[openInd:], '}')
	if closeInd < 0 do return fields, 0
	closeInd += openInd

	//strip line comments before splitting on ';', otherwise a commented-out member would parse as real
	body := strings.builder_make(context.temp_allocator)
	for line in strings.split_lines(source[openInd+1:closeInd], context.temp_allocator){
		text := line
		if c := strings.index(text, "//"); c >= 0 do text = text[:c]
		strings.write_string(&body, text)
		strings.write_byte(&body, '\n')
	}

	offset := 0
	for decl in strings.split(strings.to_string(body), ";", context.temp_allocator){
		trimmed := strings.trim_space(decl)
		if trimmed == "" do continue

		tokens := strings.fields(trimmed, context.temp_allocator)
		if len(tokens) < 2{
			printf("WARNING: shader '%s' has an unparseable cbuffer member '%s', skipping", shaderName, trimmed)
			continue
		}

		hlslType := tokens[0]
		name := tokens[1]
		arrayCount := 0
		if b := strings.index_byte(name, '['); b >= 0{
			closeB := strings.index_byte(name, ']')
			if closeB > b do arrayCount, _ = strconv.parse_int(name[b+1:closeB])
			name = name[:b]
		}

		odinType, size, rowAligned, ok := shader_field_layout(hlslType, arrayCount)
		if !ok{
			printf("WARNING: shader '%s' uses unsupported cbuffer type '%s' for '%s', skipping", shaderName, hlslType, name)
			continue
		}

		if rowAligned do offset = ((offset + 15)/16)*16
		else if (offset%16) + size > 16 do offset = ((offset + 15)/16)*16 //would straddle a row

		append(&fields, ShaderField{name=name, odinType=odinType, offset=offset, size=size})
		offset += size
	}

	return fields, ((offset + 15)/16)*16 //cbuffers round up to a whole row
}

SHADER_IDS_HEADER :: `package massimodin //@nested-tags:engine/shaders

//One Sh_<PascalCase> struct per shader that declares a cbuffer, laid out to match HLSL packing exactly.

`

//Regenerates shaderIDs.g.odin from every fragment shader in the build dir. Returns true if the file changed.
shader_ids_generate :: proc(outDir:string) -> bool{
	dirHandle, err := os.open(outDir)
	if err != nil{
		printf("WARNING: could not open '%s' to generate shader ids", outDir)
		return false
	}
	defer os.close(dirHandle)

	dirInfo, err2 := os.read_all_directory(dirHandle, context.temp_allocator)
	if err2 != nil do return false

	names := make([dynamic]string, context.temp_allocator)
	structs := strings.builder_make(context.temp_allocator)
	variants := make([dynamic]string, context.temp_allocator)
	inits := strings.builder_make(context.temp_allocator)
	texSlots := strings.builder_make(context.temp_allocator)
	bufSlots := strings.builder_make(context.temp_allocator)

	for fi in dirInfo{
		assetName := filepath.stem(fi.name) //"stage.frag"
		if !strings.has_suffix(assetName, ".frag") do continue
		name := assetName[:len(assetName)-len(".frag")]
		append(&names, name)

		source, readErr := os.read_entire_file(fi.fullpath, context.temp_allocator)
		if readErr != nil do continue

		structName := strings.concatenate({"Sh_", capitalize_first(name)}, context.temp_allocator)
		append(&variants, structName)

		boundTextures := shader_bound_textures_parse(string(source))
		if len(boundTextures) > 0{
			fmt.sbprintfln(&texSlots, "\t\tcase \"%s\":", name)
			fmt.sbprintln(&texSlots, "\t\t\tswitch uniformName{")
			for e in boundTextures do fmt.sbprintfln(&texSlots, "\t\t\t\tcase \"%s\": return %d, true", e.name, e.slot)
			fmt.sbprintln(&texSlots, "\t\t\t}")
		}

		//t0 is always the draw's own texture, so the sampled texture count is the named extras plus one
		if storageBuffers := shader_storage_buffers_parse(string(source), len(boundTextures)+1); len(storageBuffers) > 0{
			fmt.sbprintfln(&bufSlots, "\t\tcase \"%s\":", name)
			fmt.sbprintln(&bufSlots, "\t\t\tswitch uniformName{")
			for e in storageBuffers do fmt.sbprintfln(&bufSlots, "\t\t\t\tcase \"%s\": return %d, true", e.name, e.slot)
			fmt.sbprintln(&bufSlots, "\t\t\t}")
		}

		fields, totalSize := shader_cbuffer_parse(string(source), name)
		if len(fields) == 0{
			fmt.sbprintfln(&structs, "%s :: struct{{}}\n", structName)
			continue
		}

		fmt.sbprintfln(&structs, "%s :: struct #align(16){{", structName)
		odinOffset := 0
		padIndex := 0
		for f in fields{
			//explicit padding only where HLSL's no-straddle rule bumps a member past where Odin would put it
			if f.offset > odinOffset{
				fmt.sbprintfln(&structs, "\t_pad%d:[%d]u8,", padIndex, f.offset-odinOffset)
				odinOffset = f.offset
				padIndex += 1
			}
			fmt.sbprintfln(&structs, "\t%s:%s,", f.name, f.odinType)
			odinOffset += f.size
		}
		fmt.sbprintln(&structs, "}")
		fmt.sbprintln(&structs, "")

		fmt.sbprintfln(&inits, "\t\tcase \"%s\": info.params = %s{{}}; info.paramsSize = size_of(%s)", name, structName, structName)
	}

	out := strings.builder_make(context.temp_allocator)
	strings.write_string(&out, SHADER_IDS_HEADER)

	strings.write_string(&out, strings.to_string(structs))

	//the union is what ShaderInfo actually stores, so it has to cover every variant
	if len(variants) > 0{
		fmt.sbprintln(&out, "ShaderParams :: union #no_nil{")
		for v, i in variants{
			if i > 0 do fmt.sbprintln(&out, ",")
			fmt.sbprint(&out, "\t")
			fmt.sbprint(&out, v)
		}
		fmt.sbprintln(&out, "\n}\n")
	}
	else{
		fmt.sbprintln(&out, "Sh_Placeholder :: struct{ _unused:u32 }")
		fmt.sbprintln(&out, "ShaderParams :: union{ Sh_Placeholder }\n")
	}

	/*
	Which extra sampler slot each shader's named textures occupy, taken from the Texture2D declaration
	order in its HLSL. t0 is always the draw's own texture, so the extras here are indexed from t1.
	*/
	fmt.sbprintln(&out, "_shader_bound_texture_slot :: proc(shaderName:string, uniformName:string) -> (slot:int, found:bool){")
	fmt.sbprintln(&out, "\tswitch shaderName{")
	strings.write_string(&out, strings.to_string(texSlots))
	fmt.sbprintln(&out, "\t}")
	fmt.sbprintln(&out, "\treturn -1, false")
	fmt.sbprintln(&out, "}")

	/*
	Which storage buffer slot each shader's named buffers occupy, taken from the StructuredBuffer declarations in its HLSL.
	Storage buffers continue the t register numbering after the sampled textures, but their binding slots restart at 0.
	*/
	fmt.sbprintln(&out, "")
	fmt.sbprintln(&out, "_shader_bound_buffer_slot :: proc(shaderName:string, uniformName:string) -> (slot:int, found:bool){")
	fmt.sbprintln(&out, "\tswitch shaderName{")
	strings.write_string(&out, strings.to_string(bufSlots))
	fmt.sbprintln(&out, "\t}")
	fmt.sbprintln(&out, "\treturn -1, false")
	fmt.sbprintln(&out, "}")

	newText := strings.to_string(out)
	outPath, _ := filepath.join({paths.massimodin, "shaderIDs.g.odin"})
	if existing, existErr := os.read_entire_file(outPath, context.temp_allocator); existErr == nil{
		if string(existing) == newText do return false //unchanged, don't trigger a recompile
	}

	_ = os.write_entire_file(outPath, transmute([]u8)newText)
	return true
}

pipeline_shaders_run :: proc(pipeline:^Pipeline, fullRebuild:bool){
	outDir, _ := filepath.join({paths.build, "shaders"})

	for &file in pipeline.pendingFiles{
		//stem drops only the final extension, so "quad.vert.hlsl" keeps its stage suffix as "quad.vert"
		shaderFileName := filepath.base(file.path)
		shaderName := filepath.stem(shaderFileName)
		outPath, _ := filepath.join({outDir, shaderFileName})

		if !file.exists{
			if os.exists(outPath) do os.remove(outPath)
			continue
		}

		if !fullRebuild do printf("Copying shader: %s", shaderName)

		fileData, readErr := os.read_entire_file(file.path, context.temp_allocator)
		if readErr != nil{
			printf("WARNING: Could not read shader '%s'", file.path)
			continue
		}

		//the BOM would otherwise end up inside the shader source, and DXC rejects it
		_ = os.write_entire_file(outPath, strip_bom(fileData))

		//hot reload only supports overwriting existing assets, never adding new ones
		if !fullRebuild && process_running(paths.exe){
			reload_request_write("shader", transmute([]u8)outPath)
		}
	}

	if shader_ids_generate(outDir) do pipeline.codegenDirty = true

	printf("SHADER BUILD DONE!")
}


