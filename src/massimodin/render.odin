package massimodin //@nested-tags:engine/visuals

import "base:intrinsics"
import "core:reflect"
import "../sdl3"
import "../shadercross" //device creation needs its shader formats, and Init/Quit bracket the device
import "core:mem"
import "core:sync"
import "core:os"

/*
The renderer.
Draw calls never touch the GPU: they append to an ordered list of RenderEntry during the update phase, and _render_plan_present walks that list once at present time, opening a render pass whenever the target changes and merging adjacent quads into single draws.

Ordering: render_depth(d) opens a depth span, and spans replay sorted by depth (descending, submission order as the tiebreaker).
Everything recorded before the frame's first render_depth call lives in the seed span, which replays first.
State (target/shader/blendmode/camera) is resolved in replay order: set and pop entries mutate recorder-side stacks, so a set+pop bracket straddling render_depth calls affects exactly the depth range that replays between them (e.g. stage layer shaders).
*/

RenderSystem :: struct{
	device:^sdl3.GPUDevice,
	swapchain_format:sdl3.GPUTextureFormat,

	samplers:[SamplerKind]^sdl3.GPUSampler,

	blank_tex:Tex, //1x1 opaque white, for untextured geometry

	_shaders_array:[intrinsics.type_union_variant_count(ShaderParams)]Shader, //fragment shaders only, keyed by union index
	_vert_shaders_map:map[string]^sdl3.GPUShader,
	_quad_vert_shader:^sdl3.GPUShader,
	_mesh_vert_shader:^sdl3.GPUShader,
	_compute_shader_pipelines_map:map[string]^sdl3.GPUComputePipeline,
	_base_shader:^Shader,

	_pipelines_map:map[RenderPipelineKey]^sdl3.GPUGraphicsPipeline,

	_pal_swap_sprite_map:map[^Sprite]PalSwapData,

	tex_destroy_list:[dynamic]^sdl3.GPUTexture,
	buffer_destroy_list:[dynamic]^sdl3.GPUBuffer,
	
	//render state
	depth_entries:[dynamic]RenderDepthEntry,

	//per-frame geometry
	_entries:[dynamic]RenderEntry,
	_quads:[dynamic]Quad,
	_mesh_vertices:[dynamic]Vertex,
	_sdf_shapes:[dynamic][4]f32, //frame stream of sdf shapes, referenced by offset+count from Sh_Sdf uniforms
	_compute_dispatches:[dynamic]GPUComputeDispatch,
	
	_geometry_transfer_buffer:GPUDynamicBuffer,
	_quad_buffer:GPUDynamicBuffer,
	_quad_index_buffer:GPUDynamicBuffer, //quad instance indices in sorted draw order, see the depth sort in _render_plan_present
	_mesh_buffer:GPUDynamicBuffer,
	_sdf_shape_buffer:GPUDynamicBuffer,
	_blank_buffer:^sdl3.GPUBuffer,
	
	_gpu_commands_submit_mutex:sync.Mutex, //SDL_GPU 3.4.12 does device-wide bookkeeping inside every submit, so two threads submitting at once can free a resource another submit still references. Since texture loading uploads from worker threads, so every submit in the engine goes through this.
	
	//vfx global state
	_palettes_buffer:GPUDynamicBuffer, //every palSwap palette packed rgba8, built at asset load, indexed via Sh_PalSwap offsets

	stats:RenderStats,
	stats_last:RenderStats, //stats reset every present, so finished frames are read from here
}
render:^RenderSystem

_render_system_init :: proc(){
	trace("Render System Init")

	render = new(RenderSystem)

	init(&render._vert_shaders_map, assets.allocator)
	init(&render._pipelines_map, assets.allocator)
	init(&render._compute_shader_pipelines_map, assets.allocator)
	init(&render._pal_swap_sprite_map, assets.allocator)
	init(&render.tex_destroy_list)
	init(&render.buffer_destroy_list)
	init(&render._entries)
	init(&render._quads)
	init(&render._mesh_vertices)
	init(&render._sdf_shapes)
	init(&render._compute_dispatches)

	gpu_dynamic_buffer_init(&render._geometry_transfer_buffer, true)
	gpu_dynamic_buffer_init(&render._quad_buffer)
	gpu_dynamic_buffer_init(&render._quad_index_buffer)
	gpu_dynamic_buffer_init(&render._mesh_buffer)
	gpu_dynamic_buffer_init(&render._sdf_shape_buffer)
	gpu_dynamic_buffer_init(&render._palettes_buffer)

	if !shadercross.Init() do panic("Failed to initialize SDL_shadercross!")

	//force selected render driver, fall back to whatever sdl picks if it is unsupported (typically d3d12 on older windows devices)
	render.device = sdl3.CreateGPUDevice(shadercross.GetSPIRVShaderFormats(), RENDER_DRIVER_DEBUG, RENDER_DRIVER)
	if render.device == nil do render.device = sdl3.CreateGPUDevice(shadercross.GetSPIRVShaderFormats(), RENDER_DRIVER_DEBUG, nil)
	if render.device == nil{
		printf("Failed to create GPU device! %s", sdl3.GetError())
		when ON_WINDOWS do apiNames :: "Vulkan or DirectX 12"
		else when ON_LINUX do apiNames :: "Vulkan"
		sdl3.ShowSimpleMessageBox({.ERROR}, "Diorama Break - Unsupported Graphics Device", cformat(
			"Oops! The game wasn't able to initialize its graphics!\nDiorama Break requires a GPU and driver with %s support.\nUpdating your graphics drivers may resolve this.\n\nIf your GPU is too old to support %s, the game unfortunately cannot run on it. Sorry!\n\nError Details: %s", 
			apiNames, apiNames, sdl3.GetError()
		), nil)
		os.exit(1)
	}
	printf("GPU device created (driver: %s)", sdl3.GetGPUDeviceDriver(render.device))

	_ = sdl3.SetGPUAllowedFramesInFlight(render.device, RENDER_FRAMES_IN_FLIGHT)

	if !sdl3.ClaimWindowForGPUDevice(render.device, display._window) do panicf("Could not claim the window for the GPU device! %s", sdl3.GetError())
	render.swapchain_format = sdl3.GetGPUSwapchainTextureFormat(render.device, display._window)

	render.samplers = {
		.nearest = sdl3.CreateGPUSampler(render.device, {
			min_filter=.NEAREST, mag_filter=.NEAREST,
			address_mode_u=.CLAMP_TO_EDGE, address_mode_v=.CLAMP_TO_EDGE,
		}),

		.linear = sdl3.CreateGPUSampler(render.device, {
			min_filter=.LINEAR, mag_filter=.LINEAR,
			address_mode_u=.CLAMP_TO_EDGE, address_mode_v=.CLAMP_TO_EDGE,
		}),

		.linearMip = sdl3.CreateGPUSampler(render.device, {
			min_filter=.LINEAR, mag_filter=.LINEAR, mipmap_mode=.LINEAR,
			address_mode_u=.CLAMP_TO_EDGE, address_mode_v=.CLAMP_TO_EDGE,
		})
	}

	render.blank_tex = Tex{ptr=texture_make_from_pixels({255, 255, 255, 255}, 1), size={1,1}}
	render._blank_buffer = sdl3.CreateGPUBuffer(render.device, {usage={.GRAPHICS_STORAGE_READ}, size=4}) //4 is minimum size

	render._base_shader = &render._shaders_array[intrinsics.type_variant_index_of(ShaderParams, Sh_Base)]

	_render_state_clear()
}

RENDER_DRIVER :: "vulkan"
RENDER_DRIVER_DEBUG :: DEBUG && true
RENDER_FRAMES_IN_FLIGHT :: 2
TEXTURE_FORMAT_DEFAULT :: sdl3.GPUTextureFormat.R8G8B8A8_UNORM
SHADER_BOUND_TEX_COUNT :: 3 //note that raising this may not be hardware supported on some systems.
SHADER_BOUND_BUFFER_COUNT :: 4

// TYPES & DRAW STATE

Blend :: [4]u8
Color :: [3]u8
BlendF :: [4]f32 //0-1 normalized
ColorF :: [3]f32

BLEND_WHITE		:: Blend{0xFF, 0xFF, 0xFF, 0xFF}
COLOR_WHITE		:: Color{0xFF, 0xFF, 0xFF}
COLOR_GRAY		:: Color{0x80, 0x80, 0x80}
COLOR_BLACK 	:: Color{0x00, 0x00, 0x00}
COLOR_RED 		:: Color{0xFF, 0x00, 0x00}
COLOR_GREEN 	:: Color{0x00, 0xFF, 0x00}
COLOR_BLUE 		:: Color{0x00, 0x00, 0xFF}
COLOR_CYAN 		:: Color{0x00, 0xFF, 0xFF}
COLOR_YELLOW 	:: Color{0xFF, 0xFF, 0x00}
COLOR_MAGENTA 	:: Color{0xFF, 0x00, 0xFF}

BLEND_DATA_DEFAULT :: BlendData{COLOR_WHITE, 1, .blend}

//Custom blend mode definitions
GPU_BLEND_STATES := [BlendMode]sdl3.GPUColorTargetBlendState{
	.none = { //blending disabled, but the factors must still be valid enums: D3D12 validates them (0 = INVALID fails pipeline creation)
		src_color_blendfactor=.ONE, dst_color_blendfactor=.ZERO, color_blend_op=.ADD,
		src_alpha_blendfactor=.ONE, dst_alpha_blendfactor=.ZERO, alpha_blend_op=.ADD,
		enable_blend=false,
	},
	.blend = { //was BLENDMODE_BLEND
		src_color_blendfactor=.SRC_ALPHA, dst_color_blendfactor=.ONE_MINUS_SRC_ALPHA, color_blend_op=.ADD,
		src_alpha_blendfactor=.ONE, dst_alpha_blendfactor=.ONE_MINUS_SRC_ALPHA, alpha_blend_op=.ADD,
		enable_blend=true,
	},
	.add = { //was BLENDMODE_ADD
		src_color_blendfactor=.SRC_ALPHA, dst_color_blendfactor=.ONE, color_blend_op=.ADD,
		src_alpha_blendfactor=.ZERO, dst_alpha_blendfactor=.ONE, alpha_blend_op=.ADD,
		enable_blend=true,
	},
	.mod = { //was BLENDMODE_MOD
		src_color_blendfactor=.ZERO, dst_color_blendfactor=.SRC_COLOR, color_blend_op=.ADD,
		src_alpha_blendfactor=.ZERO, dst_alpha_blendfactor=.ONE, alpha_blend_op=.ADD,
		enable_blend=true,
	},
	.mul = { //was BLENDMODE_MUL
		src_color_blendfactor=.DST_COLOR, dst_color_blendfactor=.ONE_MINUS_SRC_ALPHA, color_blend_op=.ADD,
		src_alpha_blendfactor=.DST_ALPHA, dst_alpha_blendfactor=.ONE_MINUS_SRC_ALPHA, alpha_blend_op=.ADD,
		enable_blend=true,
	},
	.multiply = { //Photoshop-style multiply: srcRGB * dstRGB, preserves dstA
		src_color_blendfactor=.DST_COLOR, dst_color_blendfactor=.ZERO, color_blend_op=.ADD,
		src_alpha_blendfactor=.ZERO, dst_alpha_blendfactor=.ONE, alpha_blend_op=.ADD,
		enable_blend=true,
	},
	.screen = {
		src_color_blendfactor=.ONE, dst_color_blendfactor=.ONE_MINUS_SRC_COLOR, color_blend_op=.ADD,
		src_alpha_blendfactor=.ONE, dst_alpha_blendfactor=.ONE_MINUS_SRC_ALPHA, alpha_blend_op=.ADD,
		enable_blend=true,
	},
	.accumulate = { //blend items on a separate texture
		src_color_blendfactor=.SRC_ALPHA, dst_color_blendfactor=.ONE, color_blend_op=.ADD,
		src_alpha_blendfactor=.ONE, dst_alpha_blendfactor=.ONE, alpha_blend_op=.ADD,
		enable_blend=true,
	},
	.premul = { //should be used for rendering textures drawn with "accumulate"
		src_color_blendfactor=.ONE, dst_color_blendfactor=.ONE_MINUS_SRC_ALPHA, color_blend_op=.ADD,
		src_alpha_blendfactor=.ONE, dst_alpha_blendfactor=.ONE_MINUS_SRC_ALPHA, alpha_blend_op=.ADD,
		enable_blend=true,
	},
	.subtract = {
		src_color_blendfactor=.ZERO, dst_color_blendfactor=.ONE, color_blend_op=.ADD,
		src_alpha_blendfactor=.ZERO, dst_alpha_blendfactor=.ONE_MINUS_SRC_ALPHA, alpha_blend_op=.ADD,
		enable_blend=true,
	},
	.subtractInverse = {
		src_color_blendfactor=.ZERO, dst_color_blendfactor=.ONE, color_blend_op=.ADD,
		src_alpha_blendfactor=.ZERO, dst_alpha_blendfactor=.SRC_ALPHA, alpha_blend_op=.ADD,
		enable_blend=true,
	},
	.one = {
		src_color_blendfactor=.ONE, dst_color_blendfactor=.ZERO, color_blend_op=.ADD,
		src_alpha_blendfactor=.ONE, dst_alpha_blendfactor=.ZERO, alpha_blend_op=.ADD,
		enable_blend=true,
	},
	.alphaMax = {
		src_color_blendfactor=.ZERO, dst_color_blendfactor=.ONE, color_blend_op=.MAX,
		src_alpha_blendfactor=.ONE, dst_alpha_blendfactor=.ONE, alpha_blend_op=.MAX,
		enable_blend=true,
	},
	.invert = {
		src_color_blendfactor=.ONE, dst_color_blendfactor=.DST_ALPHA, color_blend_op=.SUBTRACT,
		src_alpha_blendfactor=.ONE, dst_alpha_blendfactor=.ZERO, alpha_blend_op=.SUBTRACT,
		enable_blend=true,
	},
	.alphaOnly = {
		src_color_blendfactor=.ZERO, dst_color_blendfactor=.ONE, color_blend_op=.ADD,
		src_alpha_blendfactor=.ONE, dst_alpha_blendfactor=.ONE, alpha_blend_op=.ADD,
		enable_blend=true,
	},
}

BlendData :: struct{
	color:Color,
	alpha:f32,
	blendmode:BlendMode
}

BlendMode :: enum{
	none,
	blend,
	add,
	mod,
	mul,
	multiply,
	screen,
	accumulate,
	premul,
	subtract,
	subtractInverse,
	one,
	alphaMax,
	invert,
	alphaOnly
}

SamplerKind :: enum u8{
	nearest,
	linear,
	linearMip
}

RenderStats :: struct{
	entries:int, //draw calls requested
	draws:int,   //draw calls actually emitted after batching
	passes:int,
}

RenderTargetKind :: enum u8{
	rgba8,     //an offscreen render target
	swapchain, //the window, which may have a different format
}

RenderPipelineKey :: struct{
	vertShader:^sdl3.GPUShader,
	fragShader:^sdl3.GPUShader,
	blendmode:BlendMode,
	target:RenderTargetKind,
}

RenderDepthEntry :: struct{
	depth:f32,
	start:u32,
	end:u32
}

//GPU Quad for renderer.
//Must match Instance in quad.vert.hlsl.
//Structured buffer stride is the struct size rounded up to its alignment, and uvRect's float4 makes that alignment 16, so the size must stay a multiple of 16.
Quad :: struct #align(16){
	uvRect:[4]f32, //normalized min.xy / max.zw
	worldRect:Rect, //render position (in world pixels) and size, the camera is applied in the vertex shader
	feetPos:Vec2, //mainly for stage entities, center-bottom world position where the entity touches the floor (or would touch the floor, if it was grounded), usually the origin. 
	pivot:Vec2,    //rotation pivot relative to world pos, in pixels
	rotation:f32,  //radians, clockwise, about pivot
	blend:Blend,   //rgba, read as a packed uint by the shader (hlsl has no 8-bit scalar)
	flags:QuadFlags
}
#assert(size_of(Quad) == 64)

QuadFlags :: bit_set[enum{
	flipX,
	flipY,
	fullscreen, //covers the whole current target, ignoring pos/size/rotation and the camera
	verticalShading //the stage shader samples the shadow map at feetPos, across the quad's width
}; u32]

//GPU Mesh Vertex for renderer.
//Must match Vertex in mesh.vert.hlsl.
Vertex :: struct #align(8){
	pos:Vec2, //world pixels, the camera is applied in the vertex shader
	uv:Vec2,
	blend:Blend,
}
#assert(size_of(Vertex) == 24)

//Lightweight GPU quad that expands to mesh vertices for rendering bulk geometry.
MeshQuad :: struct{
	quad:[4]Vec2,
	blends:[4]Blend,
	uvs:[4]Vec2,
}

GPUDynamicBuffer :: struct{
	buf:union{^sdl3.GPUBuffer, ^sdl3.GPUTransferBuffer},
	cap:int
}

//uniform block pushed to both vertex shaders at slot 0
RenderBatchUniforms :: struct #align(16){
	targetSize:Vec2,
	camPos:Vec2,     //current camera position, subtracted from positions in-shader
	firstIndex:u32,  //start of this batch; a uniform because D3D12's SV_VertexID ignores the draw's base offset while Vulkan's includes it
	coordScale:f32,  //the current target's position multiplier
}
#assert(size_of(RenderBatchUniforms) == 32)

//For fragment shaders only
Shader :: struct{
	using ptr:^sdl3.GPUShader,
	name:string,
	samplerCount:u32,
	storageBufferCount:u32,
	_renderBoundTextures:ShaderBoundTextureArray,
	_renderBoundBuffers:ShaderBoundBufferArray,
	_renderParams:ShaderParams
}

ShaderBoundTextureArray :: [SHADER_BOUND_TEX_COUNT]^sdl3.GPUTexture
ShaderBoundBufferArray :: [SHADER_BOUND_BUFFER_COUNT]^GPUDynamicBuffer

GPUComputeDispatch :: struct{
	readWriteBuffers:[dynamic; 4]^sdl3.GPUBuffer, //u registers, space1; bound at pass begin, never cycled
	readBuffers:[dynamic; 4]^sdl3.GPUBuffer,      //t registers, space0
	pipeline:^sdl3.GPUComputePipeline,
	uniforms:rawptr,
	uniformsSize:u32,
	groups:[3]u32
}

/*
The frame is a flat command list. Draw entries carry only what is genuinely per-draw; everything else is
state that the entries below mutate as the recorder walks the list, and the recorder hands the current
state to each pass and draw call.

The state entries are also the batch boundaries: a run of adjacent quads with nothing between them shares
all its state by construction, so it collapses into one draw with no comparing needed.
*/

RenderEntrySource :: struct{
	src:^sdl3.GPUTexture,
	sampler:SamplerKind
}
RenderEntryTarget :: struct{
	target:^sdl3.GPUTexture,
	size:Vec2
}
RenderEntryTargetOverloaded :: struct{
	target:^sdl3.GPUTexture,
	size:Vec2,
	scratch:^sdl3.GPUTexture, //the target's snapshot scratch when it was pushed as a TexBuffered, for replay-resolved redraws
	coordScale:f32 //multiplies draw positions, so native-res draws can compose into the window-res tex (see _display_pre_draw)
}
RenderEntryTargetPop :: struct{amount:int}
RenderEntryTargetClear :: struct{}
//Copies the replay-current target to its scratch and stages the scratch as the draw source, so a following fullscreen quad redraws the target through the current shader.
RenderEntrySnapshot :: struct{}

RenderEntryQuad :: struct{
	ind:u32 //index into render.quad_instances
}
RenderEntryMesh :: struct{
	buffer:^sdl3.GPUBuffer, //nil = the frame's _mesh_buffer; otherwise a persistent external vertex buffer (e.g. compute-written foliage)
	first, count:u32, //range in the source buffer
}
RenderEntryClear :: struct{
	color:Blend,
}
//unused for now
RenderEntryVertShader :: struct{
	shader:^sdl3.GPUShader,
}
RenderEntryFragShader :: struct{
	shader:^Shader
}
RenderEntryShaderPop :: struct{amount:int}
RenderEntryShaderParams :: struct{
	params:^ShaderParams //ShaderParams union can get pretty big, params snapshots are stored on the heap using the temp allocator to prevent inflating RenderEntry
}
RenderEntryShaderParamsIndividual :: struct{
	edits:[]u8
}
RenderEntryShaderTextureRebind :: struct{
	uniformName:cstring, //use cstring to fit inside union
	texture:^sdl3.GPUTexture
}
RenderEntryShaderBufferRebind :: struct{
	uniformName:cstring,
	buffer:^GPUDynamicBuffer
}
RenderEntryCameraSet :: struct{
	pos:Vec2
}
RenderEntryCameraPop :: struct{amount:int}
RenderEntryCameraClear :: struct{}

RenderEntryBlendmode :: struct{
	blendmode:BlendMode,
}

RenderEntry :: union{
	RenderEntrySource,
	RenderEntryTarget,
	^RenderEntryTargetOverloaded,
	RenderEntryTargetPop,
	RenderEntryTargetClear,
	RenderEntrySnapshot,
	RenderEntryQuad,
	RenderEntryMesh,
	RenderEntryClear,
	RenderEntryVertShader,
	RenderEntryFragShader,
	RenderEntryShaderPop,
	RenderEntryShaderParams,
	RenderEntryShaderParamsIndividual,
	RenderEntryShaderTextureRebind,
	RenderEntryShaderBufferRebind,
	RenderEntryBlendmode,
	RenderEntryCameraSet,
	RenderEntryCameraPop,
	RenderEntryCameraClear
}

blendmode_set :: #force_inline proc (b:BlendMode){
	append(&render._entries, RenderEntryBlendmode{b})
}

color_f :: #force_inline proc "contextless"(r,g,b:f32)->Color{ return Color{u8(round(r*255)), u8(round(g*255)), u8(round(b*255))}}
color_f_arr :: #force_inline proc "contextless"(c:ColorF)->Color{ return color_f(c.r,c.g,c.b)}
color_hex :: #force_inline proc "contextless" (hexcode:u32) -> Color{ //converts a hexcode to a color
	out := transmute([4]u8)hexcode
	return Color{out.b, out.g, out.r}
}
color :: proc{color_f, color_f_arr, color_hex}

color_lerp :: proc "contextless" (c1,c2:Color, amount:f32, curve:^Curve=nil) -> Color{
	newCol:ColorF = lerp(ColorF(c1), ColorF(c2), amount, curve)
	return Color{u8(round(newCol.r)), u8(round(newCol.g)), u8(round(newCol.b))}
}
blend_lerp :: proc "contextless" (b1,b2:Blend, amount:f32, curve:^Curve=nil) -> Blend{
	newBlend:BlendF = lerp(BlendF(b1), BlendF(b2), amount, curve)
	return Blend{u8(round(newBlend.r)), u8(round(newBlend.g)), u8(round(newBlend.b)), u8(round(newBlend.a))}
}
color_mul :: proc "contextless" (c1,c2:Color) -> Color{
	c1f := ColorF(c1)/255
	c2f := ColorF(c2)/255
	newCol := c1f*c2f*255
	return Color{u8(round(newCol.r)), u8(round(newCol.g)), u8(round(newCol.b))}
}

color_to_blend :: #force_inline proc "contextless" (color:Color, alpha:f32=1) -> Blend{
	return Blend{**color, u8(clamp(alpha*255, 0, 255))}
}
color_to_f :: proc(c:Color)->ColorF{ return ColorF(c)/255 }
blend_to_f :: proc(c:Blend)->BlendF{ return BlendF(c)/255 }
blend_from_f :: proc(c:BlendF)->Blend{ return Blend{u8(round(c.r*255)), u8(round(c.g*255)), u8(round(c.b*255)), u8(round(c.a*255))}}

//Clears the current target. Becomes a pass with a CLEAR load op, so it always costs a pass break.
draw_clear :: proc(col:=COLOR_WHITE, alpha:u8=255){
	append(&render._entries, RenderEntryClear{color = Blend{**col, alpha}})
}

// SYSTEM


//every submit in the engine goes through here, see RenderSystem.submit_mutex
gpu_commands_submit :: proc(cmdBuf:^sdl3.GPUCommandBuffer) -> bool{
	sync.lock(&render._gpu_commands_submit_mutex)
	defer sync.unlock(&render._gpu_commands_submit_mutex)
	return sdl3.SubmitGPUCommandBuffer(cmdBuf)
}

// TEXTURES

//Creates a texture from pixel data. Will not generate mipmaps.
texture_make_from_pixels :: proc(pixels:[]u8, size:Vec2i) -> ^sdl3.GPUTexture{
	tex := sdl3.CreateGPUTexture(render.device, {
		type=.D2,
		format=TEXTURE_FORMAT_DEFAULT,
		usage={.SAMPLER},
		width=u32(size.x),
		height=u32(size.y),
		layer_count_or_depth=1,
		num_levels=1,
	})
	assertf(tex != nil, "GPU texture creation failed! %s", sdl3.GetError())
	texture_upload(tex, pixels, size)
	return tex
}

//Uploads pixel data to a GPU texture, optionally generating mipmaps.
texture_upload :: proc(tex:^sdl3.GPUTexture, pixels:[]u8, size:Vec2i, generateMipsAfter:=false){
	byteCount := size.x*size.y*4
	transferBuf := sdl3.CreateGPUTransferBuffer(render.device, {usage=.UPLOAD, size=u32(byteCount)})
	mapped := sdl3.MapGPUTransferBuffer(render.device, transferBuf, false)
	mem.copy(mapped, raw_data(pixels), byteCount)
	sdl3.UnmapGPUTransferBuffer(render.device, transferBuf)

	cmdBuf := sdl3.AcquireGPUCommandBuffer(render.device)
	copyPass := sdl3.BeginGPUCopyPass(cmdBuf)
	sdl3.UploadToGPUTexture(copyPass,
		{transfer_buffer=transferBuf},
		{texture=tex, w=u32(size.x), h=u32(size.y), d=1},
		false,
	)
	sdl3.EndGPUCopyPass(copyPass)
	if generateMipsAfter do sdl3.GenerateMipmapsForGPUTexture(cmdBuf, tex)
	_ = gpu_commands_submit(cmdBuf)
	sdl3.ReleaseGPUTransferBuffer(render.device, transferBuf)
}

// PIPELINES

render_pipeline_get :: proc(key:RenderPipelineKey) -> ^sdl3.GPUGraphicsPipeline{
	if pipeline, ok := render._pipelines_map[key]; ok do return pipeline

	pipeline := sdl3.CreateGPUGraphicsPipeline(render.device, {
		vertex_shader=key.vertShader,
		fragment_shader=key.fragShader,
		primitive_type=.TRIANGLELIST,
		depth_stencil_state={compare_op=.ALWAYS}, //no depth attachment anywhere, but D3D12 still validates the compare op and 0 (INVALID) fails creation
		target_info={
			num_color_targets=1,
			color_target_descriptions=&sdl3.GPUColorTargetDescription{
				format=key.target == .swapchain ? render.swapchain_format : TEXTURE_FORMAT_DEFAULT,
				blend_state=GPU_BLEND_STATES[key.blendmode],
			},
		},
	})
	assertf(pipeline != nil, "GPU pipeline creation failed (%v)! %s", key, sdl3.GetError())

	render._pipelines_map[key] = pipeline
	return pipeline
}

// SHADERS

/*
Only fragment shaders get an identity here: they are what sh.* names, what shader_set pushes, and what
carries uniforms. Vertex shaders are picked by string name out of _vert_shaders_map and there are only
two of them (the quad puller and the mesh puller).
*/

shader_find :: proc(name:string) -> ^Shader{
	for &sh in render._shaders_array{
		if sh.name == name do return &sh
	}
	return nil
}

//Sets the shader based on the passed params variant. Will not set params if passed value is nil, unless the zeroOut flag is set. 
shader_set_with_params :: proc(params:ShaderParams){
	append(&render._entries, RenderEntryFragShader{
		&render._shaders_array[union_variant_index(params)]
	})
	append(&render._entries, RenderEntryShaderParams{new_clone(params, context.temp_allocator)})
}
shader_set_no_params :: proc($T:typeid) where intrinsics.type_is_variant_of(ShaderParams, T){
	append(&render._entries, RenderEntryFragShader{
		&render._shaders_array[intrinsics.type_variant_index_of(ShaderParams, T)]
	})
}
shader_set :: proc{shader_set_with_params, shader_set_no_params}

shader_params_set_by_name :: proc($T:typeid, newParams:..struct{name:string, val:any}) where intrinsics.type_is_variant_of(ShaderParams, T){
	buf := buffer_make(0, 64*len(newParams), context.temp_allocator)
	buffer_write_val(&buf, u16(intrinsics.type_variant_index_of(ShaderParams, T)))
	for p in newParams{
		buffer_write_val(&buf, u16(len(p.name)))
		buffer_write_string(&buf, p.name)
		valSize := reflect.size_of_typeid(p.val.id)
		buffer_write_val(&buf, u16(valSize))
		buffer_write_rawptr(&buf, p.val.data, valSize)
	}

	append(&render._entries, RenderEntryShaderParamsIndividual{buf.buf[:]})
}
shader_params_set :: proc(params:ShaderParams){
	append(&render._entries, RenderEntryShaderParams{new_clone(params, context.temp_allocator)})
}

shader_reset :: proc(resetCount:=1){
	append(&render._entries, RenderEntryShaderPop{resetCount})
}

//Binds a texture to one of the active shader's extra sampler slots.
shader_texture_bind :: proc(uniformName:string, tex:Tex){
	append(&render._entries, RenderEntryShaderTextureRebind{
		string_to_cstring(uniformName, context.temp_allocator),
		tex.ptr
	})
}

//Bound textures are reset at the end of every frame, so only use this if you explicitly need to have a sampler unbound
shader_texture_unbind :: proc(uniformName:string){
	append(&render._entries, RenderEntryShaderTextureRebind{
		string_to_cstring(uniformName, context.temp_allocator),
		nil
	})
}

//Bound buffers reset at the end of every frame like bound textures, so bind alongside every shader_set
shader_buffer_bind :: proc(uniformName:string, buffer:^GPUDynamicBuffer){
	append(&render._entries, RenderEntryShaderBufferRebind{
		string_to_cstring(uniformName, context.temp_allocator),
		buffer
	})
}

//Queues a compute shader dispatch
//Dispatches run once, at the start of _render_plan_present
gpu_compute_dispatch :: proc(pipelineName:string, uniforms:$T, readWriteBuffers:[]^sdl3.GPUBuffer, readBuffers:[]^sdl3.GPUBuffer, groups:[3]int){
	dispatch := GPUComputeDispatch{
		pipeline=render._compute_shader_pipelines_map[pipelineName],
		uniforms=new_clone(uniforms, context.temp_allocator),
		uniformsSize=size_of(T),
		groups=cast([3]u32)groups
	}
	set(&dispatch.readWriteBuffers, newVal=readWriteBuffers)
	set(&dispatch.readBuffers, newVal=readBuffers)
	append(&render._compute_dispatches, dispatch)
}

// GEOMETRY

//todo: usage flags?
gpu_dynamic_buffer_init :: proc(buffer:^GPUDynamicBuffer, transfer:=false){
	buffer.buf = transfer ? cast(^sdl3.GPUTransferBuffer)nil : cast(^sdl3.GPUBuffer)nil
}

gpu_dynamic_buffer_reserve :: proc(buffer:^GPUDynamicBuffer, cap:int){
	if cap <= buffer.cap do return

	cap := cap
	cap = next_power_of_2(cap)

	buffer.cap = cap

	switch b in buffer.buf{
		case ^sdl3.GPUBuffer:
			if b != nil do sdl3.ReleaseGPUBuffer(render.device, b)
			buffer.buf = sdl3.CreateGPUBuffer(render.device, {usage={.GRAPHICS_STORAGE_READ}, size=u32(cap)})
		case ^sdl3.GPUTransferBuffer:
			if b != nil do sdl3.ReleaseGPUTransferBuffer(render.device, b)
			buffer.buf = sdl3.CreateGPUTransferBuffer(render.device, {usage=.UPLOAD, size=u32(cap)})
		case: panic("Tried to reserve uninitialized dynamic GPU buffer!")
	}
}


gpu_buffer_make :: proc(byteSize:int, usage:sdl3.GPUBufferUsageFlags) -> ^sdl3.GPUBuffer{
	buf := sdl3.CreateGPUBuffer(render.device, {usage=usage, size=u32(byteSize)})
	assertf(buf != nil, "Storage buffer creation failed! %s", sdl3.GetError())
	return buf
}

//deferred release: the buffer may still be referenced by an in-flight frame, so it drains after the next present
gpu_buffer_destroy :: proc(buf:^sdl3.GPUBuffer){
	if buf != nil do append(&render.buffer_destroy_list, buf)
}

//Upload data to a gpu buffer.
//If no copy pass is passed, acquires a command buffer to start, end, and sumbit one internally.
//If no transfer buffer is passed, creates and destroys one internally. Passed transfer buffers MUST be set to cycle.
gpu_buffer_upload :: proc(buffer:^sdl3.GPUBuffer, data:[]u8, copyPass:^sdl3.GPUCopyPass=nil, transferBuffer:^sdl3.GPUTransferBuffer=nil){
	transferBuf := transferBuffer == nil ? sdl3.CreateGPUTransferBuffer(render.device, {usage=.UPLOAD, size=u32(len(data))}) : transferBuffer
	defer if transferBuffer == nil do sdl3.ReleaseGPUTransferBuffer(render.device, transferBuf)

	cmdBuf:^sdl3.GPUCommandBuffer
	cPass:^sdl3.GPUCopyPass
	if copyPass == nil{
		cmdBuf = sdl3.AcquireGPUCommandBuffer(render.device)
		cPass = sdl3.BeginGPUCopyPass(cmdBuf)
	}
	else do cPass = copyPass

	defer if copyPass == nil{
		sdl3.EndGPUCopyPass(cPass)
		gpu_commands_submit(cmdBuf)
	}
	
	mapped := sdl3.MapGPUTransferBuffer(render.device, transferBuf, transferBuffer!=nil)
	mem.copy(mapped, raw_data(data), len(data))
	sdl3.UnmapGPUTransferBuffer(render.device, transferBuf)

	sdl3.UploadToGPUBuffer(cPass, {transfer_buffer=transferBuf}, {buffer=buffer, size=u32(len(data))}, transferBuffer!=nil)
}

//Every quad draw lands here.
render_quad :: proc(src:^sdl3.GPUTexture, sampler:SamplerKind, inst:Quad){
	if src == nil do return

	ind := u32(len(render._quads))
	append(&render._quads, inst)
	append(&render._entries, RenderEntrySource{src,sampler})
	append(&render._entries, RenderEntryQuad{ind})
}

//Draws a triangle list. The verts are copied onto the frame's mesh arena.
render_mesh :: proc(src:^sdl3.GPUTexture, sampler:SamplerKind, verts:[]Vertex){
	first := len(render._mesh_vertices)
	append(&render._mesh_vertices, ..verts)
	append(&render._entries, RenderEntrySource{src,sampler})
	append(&render._entries, RenderEntryMesh{first=u32(first), count=u32(len(verts))})
}

//expands a bulk quad array and appends it as one mesh
render_mesh_quads :: proc(src:^sdl3.GPUTexture, sampler:SamplerKind, quads:[]MeshQuad){
	first := len(render._mesh_vertices)
	reserve(&render._mesh_vertices, len(render._mesh_vertices) + len(quads)*6)
	for q in quads{
		verts := [6]Vertex{
			{pos=q.quad[0], uv=q.uvs[0], blend=q.blends[0]},
			{pos=q.quad[1], uv=q.uvs[1], blend=q.blends[1]},
			{pos=q.quad[2], uv=q.uvs[2], blend=q.blends[2]},
			{pos=q.quad[0], uv=q.uvs[0], blend=q.blends[0]},
			{pos=q.quad[2], uv=q.uvs[2], blend=q.blends[2]},
			{pos=q.quad[3], uv=q.uvs[3], blend=q.blends[3]},
		}
		append(&render._mesh_vertices, ..verts[:])
	}
	append(&render._entries, RenderEntrySource{src,sampler})
	append(&render._entries, RenderEntryMesh{first=u32(first), count=u32(len(quads))*6})
}

//Draws a vertex range from a persistent external storage buffer of Vertex, bypassing the frame's mesh stream.
render_mesh_from_gpu_buffer :: proc(src:^sdl3.GPUTexture, sampler:SamplerKind, buffer:^sdl3.GPUBuffer, first, count:u32){
	append(&render._entries, RenderEntrySource{src,sampler})
	append(&render._entries, RenderEntryMesh{buffer=buffer, first=first, count=count})
}


// DEPTH

render_depth :: proc(d:f32){
	append(&render.depth_entries, RenderDepthEntry{
		d, u32(len(render._entries)), 0
	})
}

render_depth_ui :: proc(layer:UILayer, offset:f32=0){
	render_depth(ui_layer_depth(layer) + offset)
}
render_depth_layer :: proc(layer:DepthLayer, offset:f32=0){
	render_depth(layer_depth(layer) + offset)
}



// FRAME LIFECYCLE

_render_state_clear :: proc(){
	//clear plan
	clear(&render._entries)
	clear(&render._quads)
	clear(&render._mesh_vertices)
	clear(&render._sdf_shapes)
	clear(&render._compute_dispatches)
	clear(&render.depth_entries)
	append(&render.depth_entries, RenderDepthEntry{INT_MAX_F32, 0, 0})
	when DEBUG{
		render.stats_last = render.stats
		render.stats = {}
	}

	for &shader in render._shaders_array{
		tag := reflect.get_union_variant_raw_tag(shader._renderParams)
		shader._renderParams = {}
		reflect.set_union_variant_raw_tag(shader._renderParams, tag)
		for &t in shader._renderBoundTextures do t=nil
		for &b in shader._renderBoundBuffers do b=nil
	}
}

//Immediately sorts, records, and submits the queued render plan to the GPU, then clears the render state.
//ONLY USE FOR OFFSCREEN RENDERING, mainly here as a way to avoid having heavy prerendering accumulate to _render_plan_present. 
render_flush :: proc(){
	defer _render_state_clear()

	cmdBuf := sdl3.AcquireGPUCommandBuffer(render.device)
	if cmdBuf == nil do return

	_render_plan_record(cmdBuf, nil, {})

	gpu_commands_submit(cmdBuf)
}

//Sorts and records the queued render plan into the given command buffer.
//Set swapchainTex to nil for offscreen render_flush calls.
_render_plan_record :: proc(cmdBuf:^sdl3.GPUCommandBuffer, swapchainTex:^sdl3.GPUTexture, swapchainSize:Vec2){
	//Sort render entries by depth.
	//Instances stay in submission order; only the entries and the quad index stream reorder, and quad draws read their instances through the index stream (see quad.vert.hlsl).
	for i in 0..<len(render.depth_entries)-1{
		render.depth_entries[i].end = render.depth_entries[i+1].start
	}
	peek_ptr(&render.depth_entries).end = u32(len(render._entries))

	sort_array(&render.depth_entries, proc(a,b:RenderDepthEntry)->bool{
		if a.depth != b.depth do return a.depth > b.depth
		return a.start < b.start //deterministic tiebreaker to mitigate z-fighting issues
	})

	sortedEntries := make([]RenderEntry, len(render._entries), context.temp_allocator)
	quadIndices := make([]u32, len(render._quads), context.temp_allocator)
	{
		entryInd := 0
		quadInd := 0
		for de in render.depth_entries{
			for n in de.start..<de.end{
				entry := render._entries[n]
				sortedEntries[entryInd] = entry
				entryInd += 1
				if quad, ok := entry.(RenderEntryQuad); ok{
					quadIndices[quadInd] = quad.ind
					quadInd += 1
				}
			}
		}
	}

	// Upload render plan geometry
	geometryCopyPass := sdl3.BeginGPUCopyPass(cmdBuf)

	geometryBufs := [?]struct{gpuBuf:^GPUDynamicBuffer, data:[]u8}{
		{&render._quad_buffer, 			slice_to_bytes(render._quads[:])},
		{&render._quad_index_buffer, 	slice_to_bytes(quadIndices)},
		{&render._mesh_buffer, 			slice_to_bytes(render._mesh_vertices[:])},
		{&render._sdf_shape_buffer, 	slice_to_bytes(render._sdf_shapes[:])}
	}

	dataMax := 0
	for b in geometryBufs do dataMax = max(dataMax, len(b.data))
	gpu_dynamic_buffer_reserve(&render._geometry_transfer_buffer, dataMax)

	for b in geometryBufs{
		if len(b.data) > 0{
			gpu_dynamic_buffer_reserve(b.gpuBuf, len(b.data))
			gpu_buffer_upload(b.gpuBuf.buf.(^sdl3.GPUBuffer), b.data, geometryCopyPass, render._geometry_transfer_buffer.buf.(^sdl3.GPUTransferBuffer))
		}
	}

	sdl3.EndGPUCopyPass(geometryCopyPass)

	// Record compute dispatches (before any render pass, so the barrier lands on the pass boundary)
	for &dispatch in render._compute_dispatches{
		if dispatch.uniformsSize > 0 do sdl3.PushGPUComputeUniformData(cmdBuf, 0, dispatch.uniforms, dispatch.uniformsSize)

		bindings:[4]sdl3.GPUStorageBufferReadWriteBinding
		for buf,i in dispatch.readWriteBuffers do bindings[i] = {buffer=buf, cycle=false}

		pass := sdl3.BeginGPUComputePass(cmdBuf, nil, 0, &bindings[0], u32(len(dispatch.readWriteBuffers)))
		sdl3.BindGPUComputePipeline(pass, dispatch.pipeline)
		if len(dispatch.readBuffers) > 0 do sdl3.BindGPUComputeStorageBuffers(pass, 0, &dispatch.readBuffers[0], u32(len(dispatch.readBuffers)))
		sdl3.DispatchGPUCompute(pass, dispatch.groups.x, dispatch.groups.y, dispatch.groups.z)
		sdl3.EndGPUComputePass(pass)
	}

	// Record render passes and draws
	pass:^sdl3.GPURenderPass

	//render state
	target:^sdl3.GPUTexture
	targetSize := swapchainSize
	coordScale:f32 = 1
	//vertShader:^sdl3.GPUShader
	fragShader := render._base_shader
	blendmode := BlendMode.blend
	camPos:Vec2 //an empty camera stack means screen space
	shaderStack := make([dynamic]^Shader, context.temp_allocator)
	targetStack := make([dynamic]RenderEntryTargetOverloaded, context.temp_allocator)
	cameraStack := make([dynamic]Vec2, context.temp_allocator)

	//draw state
	drawTex:^sdl3.GPUTexture
	drawSamplerKind:SamplerKind
	drawFirst, drawCount:u32
	drawIsMesh:bool
	drawExternalBuffer:^sdl3.GPUBuffer
	quadIndexCursor:u32 //quads are drawn through the sorted index stream, so batches consume it linearly

	//currently bound state, so unchanged state is never re-bound (bindings reset with each pass, pushed uniforms persist per command buffer)
	boundPipeline:^sdl3.GPUGraphicsPipeline
	boundStorage:^sdl3.GPUBuffer
	boundDrawTex:^sdl3.GPUTexture
	boundDrawSampler:^sdl3.GPUSampler
	shaderBoundTexturesDirty := true
	shaderBoundBuffersDirty := true
	shaderParamsDirty := true

	
	for i := 0; i < len(sortedEntries); i += 1{
		switch e in sortedEntries[i]{
			//pass changes
			case RenderEntryTarget:
				append(&targetStack, RenderEntryTargetOverloaded{e.target, e.size, nil, 1})
				coordScale = 1
				if e.target == target do continue //same target, keep the pass open
				if pass != nil{
					sdl3.EndGPURenderPass(pass)
					pass = nil
				}
				target = e.target
				targetSize = target == nil ? swapchainSize : e.size
				continue

			case ^RenderEntryTargetOverloaded:
				append(&targetStack, e^)
				coordScale = e.coordScale
				if e.target == target do continue //same target, keep the pass open
				if pass != nil{
					sdl3.EndGPURenderPass(pass)
					pass = nil
				}
				target = e.target
				targetSize = target == nil ? swapchainSize : e.size
				continue

			case RenderEntryTargetPop:
				for _ in 0..<e.amount{
					if len(targetStack) > 0 do pop(&targetStack)
				}
				newTop := len(targetStack) > 0 ? peek(targetStack) : RenderEntryTargetOverloaded{} //an empty target stack means the swapchain
				coordScale = newTop.target == nil ? 1 : newTop.coordScale
				if newTop.target == target do continue
				if pass != nil{
					sdl3.EndGPURenderPass(pass)
					pass = nil
				}
				target = newTop.target
				targetSize = target == nil ? swapchainSize : newTop.size
				continue

			case RenderEntryTargetClear:
				clear(&targetStack)
				coordScale = 1
				if target == nil do continue
				if pass != nil{
					sdl3.EndGPURenderPass(pass)
					pass = nil
				}
				target = nil
				targetSize = swapchainSize
				continue

			case RenderEntrySnapshot:
				scratch := len(targetStack) > 0 ? peek(targetStack).scratch : nil
				if scratch == nil{ //the current target is not buffered (e.g. the hd tex); sample blank instead, so shaders that discard on zero alpha no-op
					drawTex = render.blank_tex
					drawSamplerKind = .nearest
					continue
				}
				if pass != nil{
					sdl3.EndGPURenderPass(pass)
					pass = nil
				}
				cPass := sdl3.BeginGPUCopyPass(cmdBuf)
				sdl3.CopyGPUTextureToTexture(cPass,
					{texture=target},
					{texture=scratch},
					u32(targetSize.x), u32(targetSize.y), 1, false,
				)
				sdl3.EndGPUCopyPass(cPass)
				drawTex = scratch
				drawSamplerKind = .nearest
				continue

			case RenderEntryClear:
				//a clear can only be a pass's load op, so it ends the current pass and opens one right here.
				//Opening it immediately rather than waiting for a draw is what makes a clear with nothing after it still happen.
				if pass != nil do sdl3.EndGPURenderPass(pass)
				pass = sdl3.BeginGPURenderPass(cmdBuf,
					&sdl3.GPUColorTargetInfo{
						texture = target == nil ? swapchainTex : target,
						load_op = .CLEAR,
						store_op = .STORE,
						clear_color = sdl3.FColor(blend_to_f(e.color)),
					}, 1, nil,
				)
				when DEBUG do render.stats.passes += 1

				boundPipeline = nil
				boundStorage = nil
				boundDrawTex = nil
				boundDrawSampler = nil
				continue

			//state changes
			case RenderEntryVertShader: /*vertShader = e.shader;*/ continue

			case RenderEntryFragShader:
				append(&shaderStack, e.shader)
				fragShader = e.shader
				shaderBoundTexturesDirty = true
				shaderBoundBuffersDirty = true
				shaderParamsDirty = true
				continue

			case RenderEntryShaderPop:
				for _ in 0..<e.amount{
					if len(shaderStack) > 0 do pop(&shaderStack)
				}
				fragShader = len(shaderStack) > 0 ? peek(shaderStack) : render._base_shader
				shaderBoundTexturesDirty = true
				shaderBoundBuffersDirty = true
				shaderParamsDirty = true
				continue

			case RenderEntryShaderParams:
				assertf(&render._shaders_array[union_variant_index(e.params^)] == fragShader, "Tried to set params '%v' while shader '%s' was active!", reflect.union_variant_typeid(e.params^), fragShader.name)
				fragShader._renderParams = e.params^
				shaderParamsDirty = true
				continue

			case RenderEntryShaderParamsIndividual:
				reader := uintptr(raw_data(e.edits))
				readerEnd := reader + uintptr(len(e.edits))
				shader := &render._shaders_array[read_bytes(&reader, u16)]
				paramsType := reflect.union_variant_typeid(shader._renderParams)
				for reader < readerEnd{
					nameLen := uintptr(read_bytes(&reader, u16))
					name := string_from_ptr(reader, nameLen)
					reader += nameLen
					valSize := int(read_bytes(&reader, u16))

					sf := reflect.struct_field_by_name(paramsType, name)
					assertf(sf != reflect.Struct_Field{}, "Tried to set unknown shader parameter '%s' in shader '%s'!", name, shader.name)
					assertf(valSize == sf.type.size, "Wrong size %d when setting shader param '%s' in shader '%s' (field is %d bytes)!", valSize, name, shader.name, sf.type.size)
					mem.copy(rawptr(uintptr(&shader._renderParams) + sf.offset), rawptr(reader), valSize)
					reader += uintptr(valSize)
				}
				if shader == fragShader do shaderParamsDirty = true
				continue

			case RenderEntryShaderTextureRebind:
				slot, found := _shader_bound_texture_slot(fragShader.name, string(e.uniformName))
				assertf(found, "Shader '%s' has no bound texture named '%s'!", fragShader.name, e.uniformName)
				fragShader._renderBoundTextures[slot] = e.texture
				shaderBoundTexturesDirty = true
				continue

			case RenderEntryShaderBufferRebind:
				slot, found := _shader_bound_buffer_slot(fragShader.name, string(e.uniformName))
				assertf(found, "Shader '%s' has no storage buffer named '%s'!", fragShader.name, e.uniformName)
				fragShader._renderBoundBuffers[slot] = e.buffer
				shaderBoundBuffersDirty = true
				continue

			case RenderEntryBlendmode: blendmode = e.blendmode; continue

			case RenderEntryCameraSet:
				append(&cameraStack, e.pos)
				camPos = e.pos
				continue

			case RenderEntryCameraPop:
				for _ in 0..<e.amount{
					if len(cameraStack) > 0 do pop(&cameraStack)
				}
				camPos = len(cameraStack) > 0 ? peek(cameraStack) : Vec2{}
				continue

			case RenderEntryCameraClear:
				clear(&cameraStack)
				camPos = Vec2{}
				continue

			//draws
			case RenderEntrySource:
				drawTex = e.src
				drawSamplerKind = e.sampler
				continue

			case RenderEntryQuad:
				//nothing between adjacent quads means identical state, and their indices are consecutive in the index stream, so a run of them is one draw
				drawCount = 1
				lookahead: for i+1 < len(sortedEntries){ //batching optimization
					#partial switch next in sortedEntries[i+1]{
						case RenderEntryQuad: drawCount+=1 //keep going

						//check render entries likely to be duplicates
						case RenderEntrySource: if next != {drawTex, drawSamplerKind} do break lookahead //different source, break batch
						case RenderEntryBlendmode: if next.blendmode != blendmode do break lookahead //different blendmode, break batch

						//misc draw settings changed (unlikely to be dupes), break batch.
						case: break lookahead 
					}
					i += 1
				}

				drawFirst = quadIndexCursor
				quadIndexCursor += drawCount
				drawIsMesh = false

			case RenderEntryMesh: //mesh draws are rare and wouldn't usually batch anyway, so, unlike quads, no batching logic is used
				drawFirst = e.first
				drawCount = e.count
				drawIsMesh = true
				drawExternalBuffer = e.buffer
		}

		//open pass if necessary
		if pass == nil{
			pass = sdl3.BeginGPURenderPass(cmdBuf,
				&sdl3.GPUColorTargetInfo{
					texture = target == nil ? swapchainTex : target,
					load_op = .LOAD,
					store_op = .STORE,
				}, 1, nil,
			)
			when DEBUG do render.stats.passes += 1

			boundPipeline = nil
			boundStorage = nil
			boundDrawTex = nil
			boundDrawSampler = nil
			shaderBoundBuffersDirty = true
		}

		pipeline := render_pipeline_get(RenderPipelineKey{
			vertShader = drawIsMesh?render._mesh_vert_shader:render._quad_vert_shader,
			fragShader = fragShader,
			blendmode = blendmode,
			target = target == nil ? .swapchain : .rgba8,
		})
		if pipeline != boundPipeline{
			sdl3.BindGPUGraphicsPipeline(pass, pipeline)
			boundPipeline = pipeline
		}

		//quad draws also bind the sorted index stream at t1; the extra slot going stale on mesh draws is harmless since mesh.vert doesn't declare it
		if drawIsMesh{
			storageBuf := drawExternalBuffer != nil ? drawExternalBuffer : render._mesh_buffer.buf.(^sdl3.GPUBuffer)
			if storageBuf != boundStorage{
				sdl3.BindGPUVertexStorageBuffers(pass, 0, &storageBuf, 1)
				boundStorage = storageBuf
			}
		}
		else{
			storageBuf := render._quad_buffer.buf.(^sdl3.GPUBuffer)
			if storageBuf != boundStorage{
				storageBufs := [2]^sdl3.GPUBuffer{storageBuf, render._quad_index_buffer.buf.(^sdl3.GPUBuffer)}
				sdl3.BindGPUVertexStorageBuffers(pass, 0, &storageBufs[0], 2)
				boundStorage = storageBuf
			}
		}

		if fragShader.storageBufferCount > 0 && shaderBoundBuffersDirty{
			//like samplers, every slot the shader declares must be bound, so unbound slots get the blank buffer
			bufBindings:[SHADER_BOUND_BUFFER_COUNT]^sdl3.GPUBuffer
			for k in 0..<fragShader.storageBufferCount{
				buf := fragShader._renderBoundBuffers[k]
				bufBindings[k] = buf != nil ? buf.buf.(^sdl3.GPUBuffer) : render._blank_buffer
			}
			sdl3.BindGPUFragmentStorageBuffers(pass, 0, &bufBindings[0], fragShader.storageBufferCount)
			shaderBoundBuffersDirty = false
		}

		drawSampler := render.samplers[drawSamplerKind]
		if fragShader.samplerCount > 0 && (shaderBoundTexturesDirty || drawTex != boundDrawTex || drawSampler != boundDrawSampler){
			bindings:[SHADER_BOUND_TEX_COUNT+1]sdl3.GPUTextureSamplerBinding
			bindings[0] = {drawTex, drawSampler} //base draw tex is always bound
			for k in 1..<fragShader.samplerCount{
				boundTex := fragShader._renderBoundTextures[k-1]
				if boundTex == nil do boundTex = render.blank_tex //SDL needs every slot a shader declares to be bound, so unused extras get the blank texture
				bindings[k] = {texture=boundTex, sampler=render.samplers[.nearest]}
			}
			sdl3.BindGPUFragmentSamplers(pass, 0, &bindings[0], fragShader.samplerCount)
			shaderBoundTexturesDirty = false
			boundDrawTex = drawTex
			boundDrawSampler = drawSampler
		}

		uniforms := RenderBatchUniforms{targetSize=targetSize, camPos=camPos, firstIndex=drawFirst, coordScale=coordScale}
		sdl3.PushGPUVertexUniformData(cmdBuf, 0, &uniforms, size_of(uniforms))

		if shaderParamsDirty{
			fragUniformsSize := reflect.union_variant_type_info(fragShader._renderParams).size
			if fragUniformsSize > 0 do sdl3.PushGPUFragmentUniformData(cmdBuf, 0, rawptr(&fragShader._renderParams), u32(fragUniformsSize))
			shaderParamsDirty = false
		}

		sdl3.DrawGPUPrimitives(pass, drawIsMesh ? drawCount : drawCount*6, 1, 0, 0)
		when DEBUG do render.stats.draws += 1
	}

	if pass != nil do sdl3.EndGPURenderPass(pass)
}

//Presents queued render calls to the window.
//Acquires the swapchain texture to render to, records the render plan to a command buffer, sumbits it to the GPU, then clears it.
@export
_game_render_present :: proc(){
	when DEBUG do render.stats.entries = len(render._entries)

	//Always clear the render state, even if we early-out
	defer{
		_render_state_clear()

		for ptr in render.tex_destroy_list do sdl3.ReleaseGPUTexture(render.device, ptr)
		clear(&render.tex_destroy_list)
		for ptr in render.buffer_destroy_list do sdl3.ReleaseGPUBuffer(render.device, ptr)
		clear(&render.buffer_destroy_list)
	}

	// Get command buffer
	cmdBuf := sdl3.AcquireGPUCommandBuffer(render.device)
	if cmdBuf == nil do return

	// Get swapchain texture (vsync blocks here)
	time_frame_mark("Vsync")
	swapchainTex:^sdl3.GPUTexture
	winW, winH:u32
	if !sdl3.WaitAndAcquireGPUSwapchainTexture(cmdBuf, display._window, &swapchainTex, &winW, &winH) || swapchainTex == nil{
		_ = sdl3.CancelGPUCommandBuffer(cmdBuf)
		return
	}

	time_frame_mark("Render record")
	swapchainSize := Vec2{f32(winW), f32(winH)}
	
	_render_plan_record(cmdBuf, swapchainTex, swapchainSize)
	
	when DEBUG do _imgui_render(cmdBuf, swapchainTex)
	
	time_frame_mark("Render submit")
	gpu_commands_submit(cmdBuf)
	//when DEBUG do _render_renderdoc_update()
}

/*
RenderDoc capture support: when the game runs with RenderDoc's Vulkan layer enabled
(env ENABLE_VULKAN_RENDERDOC_CAPTURE=1 with the layer registered), render_renderdoc_capture()
captures the next frame to the given path template through the in-app API.
*/
// when DEBUG{

// 	render_renderdoc_capture :: proc(pathTemplate:cstring="renderdoc/capture"){
// 		_renderdoc_capture_path = pathTemplate
// 		_renderdoc_capture_requested = true
// 	}
// 	@private _renderdoc_capture_requested:bool
// 	@private _renderdoc_capture_path:cstring

// 	_render_renderdoc_update :: proc(){
// 		if !_renderdoc_capture_requested do return
// 		_renderdoc_capture_requested = false

// 		rdModule := win.GetModuleHandleW(win.L("renderdoc.dll"))
// 		if rdModule == nil{
// 			print("RenderDoc capture requested but the layer is not loaded (set ENABLE_VULKAN_RENDERDOC_CAPTURE=1)")
// 			return
// 		}
// 		getAPI := cast(proc "c" (version:i32, outPointers:^rawptr) -> i32)win.GetProcAddress(rdModule, "RENDERDOC_GetAPI")
// 		api:rawptr
// 		if getAPI == nil || getAPI(10000, &api) != 1 do return
// 		vtable := cast([^]rawptr)api
// 		setTemplate := cast(proc "c" (path:cstring))vtable[11] //SetCaptureFilePathTemplate
// 		setTemplate(_renderdoc_capture_path)
// 		trigger := cast(proc "c" ())vtable[15] //TriggerCapture
// 		trigger()
// 		printf("RenderDoc capture triggered (%s)", _renderdoc_capture_path)
// 	}

// }

