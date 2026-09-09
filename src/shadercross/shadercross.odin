/*
Minimal bindings for SDL3_shadercross (runtime HLSL -> SPIRV -> backend shader compilation).
Prebuilt binaries come from the libsdl-org/SDL_shadercross nightly CI artifacts,
extracted at C:\Projects\Libraries\Code\C\SDL_shadercross.
Requires SDL3_shadercross.dll, dxcompiler.dll, dxil.dll and spirv-cross-c-shared.dll next to the exe.
*/
package shadercross

import sdl "../sdl3"

when ODIN_OS == .Windows {
	foreign import lib "SDL3_shadercross.lib"
} 
else when ODIN_OS == .Linux {
	foreign import lib "system:SDL3_shadercross"
}

ShaderStage :: enum i32 {
	VERTEX,
	FRAGMENT,
	COMPUTE,
}

IOVarType :: enum i32 {
	UNKNOWN,
	INT8,
	UINT8,
	INT16,
	UINT16,
	INT32,
	UINT32,
	INT64,
	UINT64,
	FLOAT16,
	FLOAT32,
	FLOAT64,
}

IOVarMetadata :: struct {
	name:        cstring,
	location:    u32,
	vector_type: IOVarType,
	vector_size: u32,
}

GraphicsShaderResourceInfo :: struct {
	num_samplers:         u32,
	num_storage_textures: u32,
	num_storage_buffers:  u32,
	num_uniform_buffers:  u32,
}

GraphicsShaderMetadata :: struct {
	resource_info: GraphicsShaderResourceInfo,
	num_inputs:    u32,
	inputs:        [^]IOVarMetadata,
	num_outputs:   u32,
	outputs:       [^]IOVarMetadata,
}

ComputePipelineMetadata :: struct {
	num_samplers:                   u32,
	num_readonly_storage_textures:  u32,
	num_readonly_storage_buffers:   u32,
	num_readwrite_storage_textures: u32,
	num_readwrite_storage_buffers:  u32,
	num_uniform_buffers:            u32,
	threadcount_x:                  u32,
	threadcount_y:                  u32,
	threadcount_z:                  u32,
}

SPIRV_Info :: struct {
	bytecode:      [^]u8,
	bytecode_size: uint,
	entrypoint:    cstring,
	shader_stage:  ShaderStage,
	props:         sdl.PropertiesID,
}

HLSL_Define :: struct {
	name:  cstring,
	value: cstring,
}

HLSL_Info :: struct {
	source:       cstring,
	entrypoint:   cstring,
	include_dir:  cstring,
	defines:      [^]HLSL_Define,
	shader_stage: ShaderStage,
	props:        sdl.PropertiesID,
}

PROP_SHADER_DEBUG_ENABLE_BOOLEAN        :: "SDL_shadercross.spirv.debug.enable"
PROP_SHADER_DEBUG_NAME_STRING           :: "SDL_shadercross.spirv.debug.name"
PROP_SHADER_CULL_UNUSED_BINDINGS_BOOLEAN :: "SDL_shadercross.spirv.cull_unused_bindings"
PROP_HLSL_SKIP_SPIRV_ROUNDTRIP_BOOLEAN  :: "SDL_shadercross.hlsl.skip_spirv_roundtrip"

@(default_calling_convention="c", link_prefix="SDL_ShaderCross_")
foreign lib {
	Init                            :: proc() -> bool ---
	Quit                            :: proc() ---
	GetSPIRVShaderFormats           :: proc() -> sdl.GPUShaderFormat ---
	GetHLSLShaderFormats            :: proc() -> sdl.GPUShaderFormat ---
	CompileSPIRVFromHLSL            :: proc(#by_ptr info: HLSL_Info, size: ^uint) -> rawptr ---
	CompileDXILFromHLSL             :: proc(#by_ptr info: HLSL_Info, size: ^uint) -> rawptr ---
	CompileDXBCFromHLSL             :: proc(#by_ptr info: HLSL_Info, size: ^uint) -> rawptr ---
	CompileDXILFromSPIRV            :: proc(#by_ptr info: SPIRV_Info, size: ^uint) -> rawptr ---
	CompileDXBCFromSPIRV            :: proc(#by_ptr info: SPIRV_Info, size: ^uint) -> rawptr ---
	TranspileMSLFromSPIRV           :: proc(#by_ptr info: SPIRV_Info) -> rawptr ---
	TranspileHLSLFromSPIRV          :: proc(#by_ptr info: SPIRV_Info) -> rawptr ---
	ReflectGraphicsSPIRV            :: proc(bytecode: [^]u8, bytecode_size: uint, props: sdl.PropertiesID) -> ^GraphicsShaderMetadata ---
	ReflectComputeSPIRV             :: proc(bytecode: [^]u8, bytecode_size: uint, props: sdl.PropertiesID) -> ^ComputePipelineMetadata ---
	CompileGraphicsShaderFromSPIRV  :: proc(device: ^sdl.GPUDevice, #by_ptr info: SPIRV_Info, #by_ptr resource_info: GraphicsShaderResourceInfo, props: sdl.PropertiesID) -> ^sdl.GPUShader ---
	CompileComputePipelineFromSPIRV :: proc(device: ^sdl.GPUDevice, #by_ptr info: SPIRV_Info, #by_ptr metadata: ComputePipelineMetadata, props: sdl.PropertiesID) -> ^sdl.GPUComputePipeline ---
}
