#+feature using-stmt
package massimodin //@nested-tags:_components/

import "core:encoding/json"
import "../sdl3"
import "../imgui"

//also handles globals for blob foliage
FoliageSystem :: struct{
	blobs_texture_page:Tex,
	blobs_page:TexturePage, //the same texture as a sprite page, so blob frames can point at it
	blob_sprites:[BLOB_FOLIAGE_TYPE_COUNT]^Sprite,
	blob_frame_positions:[BLOB_FOLIAGE_TYPE_COUNT][BLOB_FOLIAGE_FRAME_COUNT_DISPLAYED]Rect,
	test_blob:Tex
}
foliage_system:^FoliageSystem

_foliage_system_init :: proc(){
	foliage_system = new(FoliageSystem)

	foliage_system.blobs_texture_page = tex_make(4096,4096)
	foliage_system.blobs_page = TexturePage{
		texture = foliage_system.blobs_texture_page.ptr,
		size = f32(foliage_system.blobs_texture_page.size.x),
	}
	//foliage_system.test_blob = tex_make(200, 200)
	for i in 0..<BLOB_FOLIAGE_TYPE_COUNT{ //pre-reserve space in sprites data structures
		clonedName := strmap_set(&sprites._sprites_map, format("blobFoliage__%i", i), Sprite{})
		append(&sprites.names, clonedName)
	}
}


Foliage :: struct{
	using base:RenderComponentBase,
	stageEntity:CoRef(StageEntity),
	allocator:Allocator,
	branchCount:int,
	updateNodes:[dynamic]FoliageBranchUpdateNode,
	branches:[dynamic]FoliageBranch,

	gpuNodes:^sdl3.GPUBuffer,
	gpuBranches:^sdl3.GPUBuffer,
	gpuVerts:^sdl3.GPUBuffer,
	gpuNodeCount:int,

	cullingArea:Rect,

	//branch density
	minBranches:int, //@e
	maxBranches:int, //@e
	branchDecayChance:f32, //@e
	branchSplitChance:f32, //@e
	branchMaxDecay:int, //@e
	branchSizeDecayFactor:f32, //@e
	branchDistribution:Distribution, //@e

	//draw info
	branchSprite:^Sprite, //@e
	leafSprite:^Sprite, //@e
	branchColor:Color, //@e
	leafColor:Color, //@e
	branchesVisible:bool, //@e

	//scale and parallax
	parallaxAmount:f32, //@e
	branchSegmentMinLength:f32, //@e
	branchSegmentMaxLength:f32, //@e
	leafScaleMin:f32, //@e
	leafScaleMax:f32, //@e
	branchBaseScale:f32, //@e

	//angling
	startAngleMin:f32, //@e
	startAngleMax:f32, //@e
	branchMaxAngleAdd:f32, //@e
	branchSplitAngleMin:f32, //@e
	branchSplitAngleMax:f32, //@e

	//wind effect
	windChance:f32, //@e
	windForceDamping:f32, //@e
	windForceCounter:f32, //@e
	windForceMax:f32, //@e
	windForceLeafDamping:f32, //@e
	windForceLeafCounter:f32, //@e
	windForceLeafMax:f32, //@e
	windForceLeafDistributionExponent:f32 //@e
}

FOLIAGE_NO_PARENT :: 0xFFFF_FFFF //branch roots and base leaves accumulate from zero at update time, so they have no parent link

//One node of a branch tree, stored in DFS preorder so parentInd < own index always.
//Must match Node in foliage.comp.hlsl.
FoliageBranchUpdateNode :: struct #align(8){
	size:Vec2,
	angle:f32, //degrees, relative to parent
	windForce:f32,
	windForceSpeed:f32,
	absAngle:f32, //per-frame scratch, written by the shader's angle phase
	parentInd:u32,
	branchInd:u32,
	decay:u32, //HLSL structured buffers have no 8-bit scalars, so decay and leaf get a full 32-bit field each. nbd since 16-bit alignment padding would use up that space anyway.
	leaf:b32
}
#assert(size_of(FoliageBranchUpdateNode) == 40)

//Must match Branch in foliage.comp.hlsl
FoliageBranch :: struct #align(8){
	pos:Vec2
}
#assert(size_of(FoliageBranch) == 8)

//Must match the cbuffer in foliage.comp.hlsl.
FoliageComputeUniforms :: struct #align(16){
	baseOffset:Vec2, //stageEntity pos + parallaxOffset
	frame:u32,       //hash RNG stream selector
	windEnabled:u32,
	windChance:f32,
	windForceCounter:f32,
	windForceDamping:f32,
	windForceMax:f32,
	windForceLeafCounter:f32,
	windForceLeafDamping:f32,
	windForceLeafMax:f32,
	windForceLeafDistributionExponent:f32,
	branchUVMin:Vec2,
	branchUVMax:Vec2,
	leafUVMin:Vec2,
	leafUVMax:Vec2,
	branchBlend:Blend,
	leafBlend:Blend,
	nodeCount:u32,
	rngSalt:u32, //per-component, decorrelates gusts across parallax layers
	phase:u32    //0 spring update, 1 angle accumulation, 2 position + verts
}
#assert(size_of(FoliageComputeUniforms) == 112)

FoliageUVs :: struct{
	branch:[4]Vec2,
	leaf:[4]Vec2
}

FOLIAGE_PARALLAX_EXPONENT_BASE :: 1.41421356237

FOLIAGE_MAX_NODES_PER_BRANCH :: 4096

FOLIAGE_WIND_FORCE_DEFAULT_WindChance ::  1./960. //per frame
FOLIAGE_WIND_FORCE_DEFAULT_LeafDamping ::  0.98
FOLIAGE_WIND_FORCE_DEFAULT_LeafCounter ::  0.5
FOLIAGE_WIND_FORCE_DEFAULT_LeafMax ::  30
FOLIAGE_WIND_FORCE_DEFAULT_LeafDistributionExponent ::  100

foliage_get_uvs :: proc(branchSprite:^Sprite, leafSprite:^Sprite) -> FoliageUVs{
	branchFrame := &branchSprite.frames[0]
	leafFrame := &leafSprite.frames[0]

	branchPageSize := sprite_page_size(branchSprite)
	branchP1 := branchFrame.texturePagePos.pos/branchPageSize
	branchP2 := (branchFrame.texturePagePos.pos + branchFrame.texturePagePos.size)/branchPageSize
	leafP1 := leafFrame.texturePagePos.pos/branchPageSize
	leafP2 := (leafFrame.texturePagePos.pos + leafFrame.texturePagePos.size)/branchPageSize

	return FoliageUVs{
		branch = {
			branchP1,
			{branchP2.x, branchP1.y},
			branchP2,
			{branchP1.x, branchP2.y}
		},
		leaf = {
			leafP1,
			{leafP2.x, leafP1.y},
			leafP2,
			{leafP1.x, leafP2.y}
		}
	}
}

foliage_regenerate_branches :: proc(using self:^Foliage){
	//error catching to prevent crashes and infinite loops
	if minBranches > maxBranches do maxBranches = minBranches
	if maxBranches < 0{
		minBranches = 1
		maxBranches = 1
	}
	if branchDecayChance <= 0 do branchDecayChance = 0.2
	branchMaxDecay = clamp(branchMaxDecay, 0, 254)

	@(no_instrumentation)
	initNode :: proc(using self:^Foliage, updateNode:^FoliageBranchUpdateNode, selfInd:u32, stageParallaxRect:Rect, angle:f32, pos:Vec2){
		decay := u8(updateNode.decay)
		isLeaf := int(decay) == branchMaxDecay
		updateNode.leaf = b32(isLeaf)
		decayF := f32(decay)

		size:Vec2
		if(!isLeaf){
			size = {
				random_range(branchSegmentMinLength, branchSegmentMaxLength)*pow(branchSizeDecayFactor, decayF),
				branchSprite.size.y*(0.5/(decayF+1))
			}*branchBaseScale

			splitAngleMin, splitAngleMax, splitChance:f32
			splitDecay:u8

			newAngle := angle + updateNode.angle
			newPos := vec2_offset(newAngle, size.x, pos)
			if !rect_contains(cullingArea, newPos) && rect_contains(stageParallaxRect, newPos) && len(updateNodes) < (FOLIAGE_MAX_NODES_PER_BRANCH-1)*branchCount - 3{ //prevents branches that extend past visible bounds from generating
				if(!roll(branchDecayChance)){
					nextInd := u32(len(updateNodes))
					append(&updateNodes, FoliageBranchUpdateNode{})
					nextNode := peek_ptr(&updateNodes)
					nextNode.parentInd = selfInd
					nextNode.branchInd = updateNode.branchInd
					nextNode.decay = u32(decay)
					nextNode.angle = random_range(-branchMaxAngleAdd, branchMaxAngleAdd)
					initNode(self, nextNode, nextInd, stageParallaxRect, newAngle, newPos)

					splitChance = clamp(branchSplitChance*(decayF+1), branchSplitChance, 1)
					splitAngleMin = self.branchSplitAngleMin
					splitAngleMax = self.branchSplitAngleMax
					splitDecay = choose([]u8{1, 2})
				}
				else{
					splitChance = 1
					splitAngleMin = 0
					splitAngleMax = 40
					splitDecay = 1
				}

				for i in 1..=2{
					if(roll(splitChance)){
						nextInd := u32(len(updateNodes))
						append(&updateNodes, FoliageBranchUpdateNode{})
						nextNode := peek_ptr(&updateNodes)
						nextNode.parentInd = selfInd
						nextNode.branchInd = updateNode.branchInd
						nextNode.decay = u32(min(decay + splitDecay, u8(branchMaxDecay)))
						nextNode.angle = f32(i*2-3)*random_range(splitAngleMin, splitAngleMax)
						initNode(self, nextNode, nextInd, stageParallaxRect, newAngle, newPos)
					}
				}
			}
		}
		else{
			size = {
				random_range(leafScaleMin/2, leafScaleMax/1.5),
				random_range(leafScaleMin, leafScaleMax)
			}*leafSprite.size
		}

		updateNode.size = size
	}

	if self.allocator.data == nil{
		allocator = allocator_make(size_of(FoliageBranchUpdateNode)*uint(maxBranches)*FOLIAGE_MAX_NODES_PER_BRANCH + size_of(FoliageBranch)*uint(maxBranches) + KILOBYTE)
	}
	else do free_all(self.allocator)

	context.allocator = self.allocator


	cullingBuffer :f32= 200
	stageExtraSize := stage.bounds.size + cullingBuffer - DISPLAY_SIZE
	stageSizeAdjusted := stageExtraSize*(1-parallaxAmount) + DISPLAY_SIZE
	extraBoundsSize := stageSizeAdjusted - stage.bounds.size
	stageParallaxRect:Rect
	stageParallaxRect.pos = stage.bounds.pos - extraBoundsSize/2
	stageParallaxRect.size = stageSizeAdjusted
	stageAreaAdjusted := stageSizeAdjusted.x*stageSizeAdjusted.y
	branchCount = random_range(minBranches, maxBranches) //roundi(stageAreaAdjusted/DISPLAY_AREA*STROMA_BG_BRANCH_DENSITY/initVals.parallaxScale)

	init(&updateNodes, 0, branchCount*FOLIAGE_MAX_NODES_PER_BRANCH)
	init(&branches, branchCount)

	drawRect := stageEntity_draw_rect(stageEntity)
	branchPositions := distribute_points(Rect{0, drawRect.size}, branchDistribution, branchCount)

	for &branch, i in branches{
		branch.pos = branchPositions[i]
		rootInd := u32(len(updateNodes))
		append(&updateNodes, FoliageBranchUpdateNode{})
		rootNode := peek_ptr(&updateNodes)
		rootNode.parentInd = FOLIAGE_NO_PARENT
		rootNode.branchInd = u32(i)
		rootNode.angle = random_range(startAngleMin, startAngleMax)
		initNode(self, rootNode, rootInd, stageParallaxRect, 0, drawRect.pos + branch.pos)

		//base leaves
		for j in 0..<3{
			ind := len(updateNodes)
			append(&updateNodes, FoliageBranchUpdateNode{})
			updateNodes[ind].parentInd = FOLIAGE_NO_PARENT
			updateNodes[ind].branchInd = u32(i)
			updateNodes[ind].decay = u32(u8(branchMaxDecay)-2)
			initNode(self, &updateNodes[ind], u32(ind), stageParallaxRect, rootNode.angle + 45 + random_range(90*f32(j), 90*(f32(j)+1)), drawRect.pos + branch.pos)
		}
	}

	_foliage_gpu_upload(self)
}

//(re)creates the component's persistent GPU buffers and uploads the node/branch arrays as-is
_foliage_gpu_upload :: proc(using self:^Foliage){
	gpu_buffer_destroy(gpuNodes)
	gpu_buffer_destroy(gpuBranches)
	gpu_buffer_destroy(gpuVerts)
	gpuNodes = nil
	gpuBranches = nil
	gpuVerts = nil

	gpuNodeCount = len(updateNodes)
	if gpuNodeCount == 0 do return

	gpuNodes = gpu_buffer_make(gpuNodeCount*size_of(FoliageBranchUpdateNode), {.COMPUTE_STORAGE_READ, .COMPUTE_STORAGE_WRITE})
	gpuBranches = gpu_buffer_make(len(branches)*size_of(FoliageBranch), {.COMPUTE_STORAGE_READ})
	gpuVerts = gpu_buffer_make(gpuNodeCount*6*size_of(Vertex), {.GRAPHICS_STORAGE_READ, .COMPUTE_STORAGE_WRITE}) //never uploaded, compute fills it before the first draw reads it
	
	cmdBuf := sdl3.AcquireGPUCommandBuffer(render.device)
	copyPass := sdl3.BeginGPUCopyPass(cmdBuf)
	gpu_buffer_upload(gpuNodes, slice_to_bytes(updateNodes[:]), copyPass)
	gpu_buffer_upload(gpuBranches, slice_to_bytes(branches[:]), copyPass)
	sdl3.EndGPUCopyPass(copyPass)
	gpu_commands_submit(cmdBuf)
}

_foliage_process_event :: proc(base:^ComponentBase, event:Event, overrideDisabled:=false){
if(!overrideDisabled && event in base.disabledEvents) do return
last_context := entities.context_component
defer cowith(last_context)
cowith(base)
self := cast(^Foliage)base
using self

#partial switch event{
case .init:

	minBranches = 1
	maxBranches = 1
	startAngleMax = 360

	branchSprite = sp.bgBranch
	leafSprite = sp.bgLeaf

	branchColor = color_hex(0x252b14)
	// branches[1].branchColor = color_hex(0x252b14)
	// branches[2].branchColor = color_hex(0x252b14)
	// branches[3].branchColor = color_hex(0x252b14)

	leafColor = color_hex(0x345134)
	// branches[1].leafColor = color_hex(0x346834)
	// branches[2].leafColor = color_hex(0x5c9028)
	// branches[3].leafColor = color_hex(0x96ca0f)

	branchDecayChance =  1./5.
	branchSplitChance =  5./14.
	branchSegmentMinLength =  26
	branchSegmentMaxLength =  64
	branchBaseScale = 1
	leafScaleMin =  0.2
	leafScaleMax =  0.21
	branchMaxDecay =  4
	branchSizeDecayFactor = 0.5
	branchMaxAngleAdd =  23
	branchSplitAngleMin =  50
	branchSplitAngleMax =  85
	windForceDamping =  0.995
	windForceCounter =  0.001
	windForceMax =  0.05
	windForceLeafDamping =  FOLIAGE_WIND_FORCE_DEFAULT_LeafDamping
	windForceLeafCounter =  FOLIAGE_WIND_FORCE_DEFAULT_LeafCounter
	windForceLeafMax = FOLIAGE_WIND_FORCE_DEFAULT_LeafMax
	windForceLeafDistributionExponent = FOLIAGE_WIND_FORCE_DEFAULT_LeafDistributionExponent
	windChance = FOLIAGE_WIND_FORCE_DEFAULT_WindChance

	depth = layer_depth(.stageBG)+100

	stage_mask_init(&stageEntity, sp.foliage)

case .update:
	depth = stageEntity.depth - 0.5

case .saving:
	json_marshal_field_as_base64(stage.savingComponentsBuilder, updateNodes[:], "updateNodes")
	json_marshal_field_as_base64(stage.savingComponentsBuilder, branches[:], "branches")

case .loading:
	nodeData := base64_slice_decode(stage.loadingComponentData["updateNodes"].(json.String), FoliageBranchUpdateNode)
	branchData := base64_slice_decode(stage.loadingComponentData["branches"].(json.String), FoliageBranch)

	nodeCount := len(nodeData)
	branchCount = len(branchData)
	self.allocator = allocator_make(size_of(FoliageBranchUpdateNode)*uint(nodeCount) + size_of(FoliageBranch)*uint(branchCount) + KILOBYTE)
	init(&updateNodes, nodeCount, self.allocator)
	init(&branches, branchCount, self.allocator)
	copy(updateNodes[:], nodeData[:])
	copy(branches[:], branchData[:])
	_foliage_gpu_upload(self)

case .editing:
	if imgui.Button("Regenerate") do foliage_regenerate_branches(self)

case .draw:
	if gpuNodeCount == 0 do return

	camPos := stage_camera_pos()
	stageExtraSize := stage.bounds.size - DISPLAY_SIZE
	stageCenterCameraPos := stage.bounds.pos + stageExtraSize/2
	parallaxOffset := (camPos - stageCenterCameraPos)*parallaxAmount

	uvs := foliage_get_uvs(branchSprite, leafSprite)

	uniforms := FoliageComputeUniforms{
		baseOffset = stageEntity.transform.pos + parallaxOffset,
		frame = u32(time.frame),
		windEnabled = combat.time_stop_mode == .disabled && !stage_edit.enabled ? 1 : 0,
		windChance = windChance,
		windForceCounter = windForceCounter,
		windForceDamping = windForceDamping,
		windForceMax = windForceMax,
		windForceLeafCounter = windForceLeafCounter,
		windForceLeafDamping = windForceLeafDamping,
		windForceLeafMax = windForceLeafMax,
		windForceLeafDistributionExponent = windForceLeafDistributionExponent,
		branchUVMin = uvs.branch[0],
		branchUVMax = uvs.branch[2],
		leafUVMin = uvs.leaf[0],
		leafUVMax = uvs.leaf[2],
		branchBlend = color_to_blend(branchColor, branchesVisible ? 1:0),
		leafBlend = color_to_blend(leafColor),
		nodeCount = u32(gpuNodeCount),
		rngSalt = u32(uintptr(rawptr(self)))
	}

	//three per-node passes: spring update, angle accumulation, position + verts (each depends on the previous one's writes)
	for phase in 0..<u32(3){
		uniforms.phase = phase
		gpu_compute_dispatch("foliage", uniforms, {gpuNodes, gpuVerts}, {gpuBranches}, {(gpuNodeCount+63)/64,1,1})
	}

	//the whole tree is one contiguous draw from the persistent compute-written vertex buffer
	frame := &sp.bgBranch.frames[0]
	render_mesh_from_gpu_buffer(frame.texturePage.texture, spriteFrame_sampler(frame), gpuVerts, 0, u32(gpuNodeCount*6))

case .clean:
	gpu_buffer_destroy(gpuNodes)
	gpu_buffer_destroy(gpuBranches)
	gpu_buffer_destroy(gpuVerts)
	allocator_delete(self.allocator)

}}
