#+feature using-stmt
package massimodin //@nested-tags:_components/

import "core:slice"
import "../sdl2"
import "core:encoding/base64"
import "core:encoding/json"
import "../imgui"

//also handles globals for blob foliage
FoliageSystem :: struct{
	update_pool:ThreadPool,

	blobs_texture_page:Tex,
	blob_sprites:[BLOB_FOLIAGE_TYPE_COUNT]^Sprite,
	blob_frame_positions:[BLOB_FOLIAGE_TYPE_COUNT][BLOB_FOLIAGE_FRAME_COUNT_DISPLAYED]sdl2.Rect,
	test_blob:Tex
}
foliage_system:^FoliageSystem

_foliage_system_init :: proc(){
	foliage_system = new(FoliageSystem)

	thread_pool_init_and_start(&foliage_system.update_pool, allocator_make())

	foliage_system.blobs_texture_page = tex_make(4096,4096)
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
	drawNodes:#soa[dynamic]DrawQuad,
	updateNodes:[dynamic]FoliageBranchUpdateNode,
	branches:[dynamic]FoliageBranch,

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
	animInterval:int, //@e
	windChance:f32, //@e
	windForceDamping:f32, //@e
	windForceCounter:f32, //@e
	windForceMax:f32, //@e
	windForceLeafDamping:f32, //@e
	windForceLeafCounter:f32, //@e
	windForceLeafMax:f32, //@e
	windForceLeafDistributionExponent:f32 //@e
}

FoliageBranchUpdateNode :: struct{ //stores pointers and relative angles for recursive traversal and updating
	baseQuad:[4]Vec2,
	angle:f32,
	windForce:f32,
	windForceSpeed:f32,
	next:[3]u32,
	drawNodeInd:u32,
	decay:u8,
	leaf:bool
}

FoliageBranch :: struct{
	pos:Vec2,
	rootNodeInd:int,
	baseLeafInds:[3]int
}
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

	pageSizeI:[2]i32
	sdl2.QueryTexture(branchFrame.texturePage, nil, nil, &pageSizeI.x, &pageSizeI.y)
	branchPageSize := Vec2(pageSizeI)
	branchP1 := Vec2{f32(branchFrame.texturePagePos.x), f32(branchFrame.texturePagePos.y)}/branchPageSize
	branchP2 := Vec2{f32(branchFrame.texturePagePos.x + branchFrame.texturePagePos.w), f32(branchFrame.texturePagePos.y + branchFrame.texturePagePos.h)}/branchPageSize
	leafP1 := Vec2{f32(leafFrame.texturePagePos.x), f32(leafFrame.texturePagePos.y)}/branchPageSize
	leafP2 := Vec2{f32(leafFrame.texturePagePos.x + leafFrame.texturePagePos.w), f32(leafFrame.texturePagePos.y + leafFrame.texturePagePos.h)}/branchPageSize

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

foliage_node_update_colors :: proc(using self:^Foliage, node:^FoliageBranchUpdateNode){
	drawNode := &drawNodes[node.drawNodeInd]
	if node.leaf{
		for &blend in drawNode.colors{
			blend.r = leafColor.r
			blend.g = leafColor.g
			blend.b = leafColor.b
			blend.a = 255
		}
	}
	else{
		for &blend in drawNode.colors{
			blend.r = branchColor.r
			blend.g = branchColor.g
			blend.b = branchColor.b
			blend.a = branchesVisible ? 255:0
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
	initNode :: proc(using self:^Foliage, updateNode:^FoliageBranchUpdateNode, using initVals:^initValues, angle:f32, pos:Vec2){
		updateNode.drawNodeInd = u32(len(self.drawNodes)-1)
		drawNode := &self.drawNodes[updateNode.drawNodeInd]
		updateNode.leaf = int(updateNode.decay) == branchMaxDecay
		decayF := f32(updateNode.decay)

		baseRenderInd := i32(updateNode.drawNodeInd*4)
		drawNode.indices[0] = baseRenderInd
		drawNode.indices[1] = baseRenderInd+1
		drawNode.indices[2] = baseRenderInd+2
		drawNode.indices[3] = baseRenderInd+2
		drawNode.indices[4] = baseRenderInd+3
		drawNode.indices[5] = baseRenderInd
		
		size:Vec2
		if(!updateNode.leaf){
			size = {
				random_range(branchSegmentMinLength, branchSegmentMaxLength)*pow(branchSizeDecayFactor, decayF),
				branchSprite.size.y*(0.5/(decayF+1))
			}*branchBaseScale

			drawNode.uvs = uvs.branch

			splitAngleMin, splitAngleMax, splitChance:f32
			splitDecay:u8

			newAngle := angle + updateNode.angle
			newPos := vec2_offset(newAngle, size.x, pos)
			if !rect_contains(cullingArea, newPos) && rect_contains(stageParallaxRect, newPos) && len(updateNodes) < (FOLIAGE_MAX_NODES_PER_BRANCH-1)*branchCount - 3{ //prevents branches that extend past visible bounds from generating
				if(!roll(branchDecayChance)){
					append(&drawNodes, DrawQuad{})
					nextInd := u32(len(updateNodes))
					append(&updateNodes, FoliageBranchUpdateNode{})
					nextNode := peek_ptr(&updateNodes)
					updateNode.next[0] = nextInd
					nextNode.decay = updateNode.decay
					nextNode.angle = random_range(-branchMaxAngleAdd, branchMaxAngleAdd)
					initNode(self, nextNode, initVals, newAngle, newPos)

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
						append(&self.drawNodes, DrawQuad{})
						nextInd := u32(len(updateNodes))
						append(&updateNodes, FoliageBranchUpdateNode{})
						nextNode := peek_ptr(&updateNodes)
						updateNode.next[i] = nextInd
						nextNode.decay = min(updateNode.decay + splitDecay, u8(branchMaxDecay))
						nextNode.angle = f32(i*2-3)*random_range(splitAngleMin, splitAngleMax)
						initNode(self, nextNode, initVals, newAngle, newPos)
					}
				}
			}
		}
		else{
			drawNode.uvs = uvs.leaf
			size = {
				random_range(leafScaleMin/2, leafScaleMax/1.5),
				random_range(leafScaleMin, leafScaleMax)
			}*leafSprite.size
		}

		foliage_node_update_colors(self, updateNode)

		updateNode.baseQuad = {
			{0, -size.y/2},
			{size.x, -size.y/2},
			{size.x, size.y/2},
			{0, size.y/2}
		}
	}

	initValues :: struct{
		uvs:FoliageUVs,
		stageParallaxRect:Rect
	}

	if self.allocator.data == nil{
		allocator = allocator_make((size_of(DrawQuad)+size_of(FoliageBranchUpdateNode))*uint(maxBranches)*FOLIAGE_MAX_NODES_PER_BRANCH)
	}
	else do free_all(self.allocator) 

	context.allocator = self.allocator


	initVals := initValues{
		uvs = foliage_get_uvs(branchSprite, leafSprite)
	}

	cullingBuffer :f32= 200 //(settings.performance_mode == .normal ? 100 : 0)	
	stageExtraSize := stage.bounds.size + cullingBuffer - DISPLAY_SIZE
	stageSizeAdjusted := stageExtraSize*(1-parallaxAmount) + DISPLAY_SIZE
	extraBoundsSize := stageSizeAdjusted - stage.bounds.size
	initVals.stageParallaxRect.pos = stage.bounds.pos - extraBoundsSize/2
	initVals.stageParallaxRect.size = stageSizeAdjusted
	stageAreaAdjusted := stageSizeAdjusted.x*stageSizeAdjusted.y
	branchCount = random_range(minBranches, maxBranches) //roundi(stageAreaAdjusted/DISPLAY_AREA*STROMA_BG_BRANCH_DENSITY/initVals.parallaxScale)

	init(&drawNodes, 0, branchCount*FOLIAGE_MAX_NODES_PER_BRANCH)
	init(&updateNodes, 0, branchCount*FOLIAGE_MAX_NODES_PER_BRANCH)
	init(&branches, branchCount)
	
	drawRect := stageEntity_draw_rect(stageEntity)
	branchPositions := distribute_points(Rect{0, drawRect.size}, branchDistribution, branchCount)

	for &branch, i in branches{
		append(&drawNodes, DrawQuad{})
		branch.pos = branchPositions[i]
		branch.rootNodeInd = len(updateNodes)
		append(&updateNodes, FoliageBranchUpdateNode{})
		rootNode := peek_ptr(&updateNodes)
		rootNode.angle = random_range(startAngleMin, startAngleMax)
		initNode(self, rootNode, &initVals, 0, drawRect.pos + branch.pos)
		
		//base leaves
		for j in 0..<3{
			append(&drawNodes, DrawQuad{})
			append(&updateNodes, FoliageBranchUpdateNode{})
			ind := len(updateNodes)-1
			updateNodes[ind].decay = u8(branchMaxDecay)-2
			branch.baseLeafInds[j] = ind
			initNode(self, &updateNodes[ind], &initVals, rootNode.angle + 45 + random_range(90*f32(j), 90*(f32(j)+1)), drawRect.pos + branch.pos)
		}
	}
}

_foliage_process_event :: proc(base:^ComponentBase, event:Event, overrideDisabled:=false){
if(!overrideDisabled && event in base.disabledEvents) do return
last_context := entities.context_component
defer cowith(last_context)
cowith(base)
self := cast(^Foliage)base
using self

thread_pool_block(&foliage_system.update_pool)

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
	animInterval = 2
	windForceDamping =  0.995 
	windForceCounter =  0.001 
	windForceMax =  0.05 
	windForceLeafDamping =  FOLIAGE_WIND_FORCE_DEFAULT_LeafDamping
	windForceLeafCounter =  FOLIAGE_WIND_FORCE_DEFAULT_LeafCounter
	windForceLeafMax = FOLIAGE_WIND_FORCE_DEFAULT_LeafMax 
	windForceLeafDistributionExponent = FOLIAGE_WIND_FORCE_DEFAULT_LeafDistributionExponent 
	windChance = FOLIAGE_WIND_FORCE_DEFAULT_WindChance

	depth = DEPTH_MAX+100

	stage_mask_init(&stageEntity, sp.foliage)


// case .loaded:
// 	if minBranches > maxBranches do maxBranches = minBranches
// 	if maxBranches < 0{ //error catching
// 		minBranches = 1
// 		maxBranches = 1
// 	}
// 	allocator = allocator_make((size_of(DrawQuad)+size_of(FoliageBranchUpdateNode))*uint(maxBranches)*512)
// 	foliage_regenerate_branches(self)

case .saving:
	encodedData := base64.encode(slice.to_bytes(updateNodes[:]), allocator=context.temp_allocator)
	json_marshal_field_as_base64(stage.savingComponentsBuilder, updateNodes[:], "updateNodes")
	json_marshal_field_as_base64(stage.savingComponentsBuilder, branches[:], "branches")
	
case .loading:
	nodeData := base64_slice_decode(stage.loadingComponentData["updateNodes"].(json.String), FoliageBranchUpdateNode)
	branchData := base64_slice_decode(stage.loadingComponentData["branches"].(json.String), FoliageBranch)

	nodeCount := len(nodeData)
	branchCount = len(branchData)
	self.allocator = allocator_make((size_of(DrawQuad)+size_of(FoliageBranchUpdateNode))*uint(nodeCount) + size_of(FoliageBranch)*uint(branchCount) + KILOBYTE)
	init(&drawNodes, nodeCount, self.allocator)
	init(&updateNodes, nodeCount, self.allocator)
	init(&branches, branchCount, self.allocator)
	copy(updateNodes[:], nodeData[:])
	copy(branches[:], branchData[:])
	uvs := foliage_get_uvs(branchSprite, leafSprite)
	for &node in updateNodes{
		drawNode := &drawNodes[node.drawNodeInd]
		baseRenderInd := i32(node.drawNodeInd*4)
		drawNode.indices[0] = baseRenderInd
		drawNode.indices[1] = baseRenderInd+1
		drawNode.indices[2] = baseRenderInd+2
		drawNode.indices[3] = baseRenderInd+2
		drawNode.indices[4] = baseRenderInd+3
		drawNode.indices[5] = baseRenderInd

		drawNode.uvs = node.leaf ? uvs.leaf : uvs.branch
		foliage_node_update_colors(self, &node)
	}

case .editing: 
	if imgui.Button("Regenerate") do foliage_regenerate_branches(self)

case .updateEditor:
	for &node in updateNodes do foliage_node_update_colors(self, &node)
case .draw: //hot!
	//trace("foliage draw")

	//branchBaseSize := Vec2{f32(branchFrame.texturePagePos.w), f32(branchFrame.texturePagePos.h)}
	//leafBaseSize := Vec2{f32(leafFrame.texturePagePos.w), f32(leafFrame.texturePagePos.h)}
	//branchOrigin := Vec2{f32(sp.bgBranch.origin.x - branchFrame.trimOffset.x), f32(sp.bgBranch.origin.y - branchFrame.trimOffset.y)}
	//leafOrigin := Vec2{f32(sp.bgLeaf.origin.x - leafFrame.trimOffset.x), f32(sp.bgLeaf.origin.y - leafFrame.trimOffset.y)}

	nodeCount := i32(len(drawNodes))
	//print("node count?", nodeCount)
	if nodeCount == 0 do return

	
	sdl2.RenderGeometryRaw(
		display._renderer,  sp.bgBranch.frames[0].texturePage,
		cast([^]f32)&drawNodes[0].quad, 8,
		cast([^]sdl2.Color)&drawNodes[0].colors, 4,
		cast([^]f32)&drawNodes[0].uvs, 8,
		nodeCount*4,
		&drawNodes[0].indices, nodeCount*6, 4
	)


	// shader_set(sh.leaves)
	// shader_uniform_set(sh.leaves, "lightColor", bgColor)
	// display_redraw()
	// shader_reset()

case .clean:
	allocator_delete(self.allocator)

}}

_foliage_bulk_update :: proc(){
	thread_pool_block(&foliage_system.update_pool)

	//trace("foliage update")
	arr := coall(Foliage)
	
	if len(arr) == 0 do return

	@(no_instrumentation)
	updateNode :: proc(using self:^Foliage, node:^FoliageBranchUpdateNode, lastDecay:u8, newWindMul:f32, angle:f32, pos:Vec2){
		newWindMul := newWindMul

		newAngle := angle+node.angle
		if combat.time_stop_mode == .disabled && lastDecay != node.decay{
			if newWindMul == 0 && !node.leaf && roll(windChance) do newWindMul = choose([]f32{1, -1})
			if newWindMul != 0 do node.windForceSpeed += newWindMul*(node.leaf ? pow(random(), windForceLeafDistributionExponent)*windForceLeafMax : random(windForceMax*f32(node.decay+1)))
			if node.decay == 0 do newWindMul = 0

			windAcl := node.windForce*-(node.leaf ? windForceLeafCounter : windForceCounter)
			node.windForceSpeed += windAcl
			node.windForceSpeed *= node.leaf ? windForceLeafDamping : windForceDamping
			node.windForce += node.windForceSpeed
			newAngle += node.windForce
		}
		
		sinA := sin(-newAngle)
		cosA := cos(-newAngle)
		
		drawNodeQuad := &drawNodes[node.drawNodeInd].quad
		drawNodeQuad^ = node.baseQuad
		for &vert in drawNodeQuad{
			vx := vert.x
			vert.x = vx*cosA - vert.y*sinA + pos.x
			vert.y = vx*sinA + vert.y*cosA + pos.y
		}

		//layer.debugVisPoints[node.drawNodeInd].p = pos
		//layer.debugVisPoints[node.drawNodeInd].leaf = node.leaf

		if !node.leaf{
			newPos := vec2_offset(newAngle, node.baseQuad[1].x, pos)
			for next in node.next{
				if next != 0 do updateNode(self, &updateNodes[next], node.decay, newWindMul, newAngle, newPos)
			}
		}
	}

	@(no_instrumentation)
	updateBranchTask :: proc(t:ThreadTask){
		taskData := cast(^branchTaskData)t.data
		branchPos := taskData.self.stageEntity.transform.pos + taskData.branch.pos + taskData.camOffset
		updateNode(taskData.self, &taskData.self.updateNodes[taskData.branch.rootNodeInd], 255, 0, 0, branchPos) //taskData.parallaxBasePos + taskData.branch.pos - stage.camera_pos)
		for i in 0..<3{
			updateNode(taskData.self, &taskData.self.updateNodes[taskData.branch.baseLeafInds[i]], 255, 0, 0, branchPos)
		}
	}

	branchTaskData :: struct{
		self:^Foliage,
		branch:^FoliageBranch,
		camOffset:Vec2
	}

	camPos := stage_camera_pos()
	stageExtraSize := stage.bounds.size - DISPLAY_SIZE
	stageCenterCameraPos := stage.bounds.pos + stageExtraSize/2
	stageCameraDelta := camPos - stageCenterCameraPos 

	for &self in arr{
		using self
		depth = stageEntity.depth.(f32) - 0.5
		layerExtraSize := stageExtraSize
		parallaxOffset := stageCameraDelta*parallaxAmount
	
		for &branch in branches{
			taskData := new(branchTaskData, context.temp_allocator)
			taskData.self = &self
			taskData.branch = &branch
			taskData.camOffset = parallaxOffset - camPos
			thread_pool_add_task(&foliage_system.update_pool, updateBranchTask, taskData)
		}
	}

}
