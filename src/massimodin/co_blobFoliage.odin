#+feature using-stmt
package massimodin //@nested-tags:_components/

import "core:mem"
import "../imgui"

BLOB_FOLIAGE_TYPE_COUNT :: 13
BLOB_FOLIAGE_FRAME_COUNT :: 512 //amount of frames per blob at 60fps
BLOB_FOLIAGE_FRAME_INTERVAL :: 2 //every n frame that actually gets prerendered and displayed
BLOB_FOLIAGE_FRAME_COUNT_DISPLAYED :: BLOB_FOLIAGE_FRAME_COUNT/BLOB_FOLIAGE_FRAME_INTERVAL
BLOB_FOLIAGE_LEAF_RANDOM_SCALING_FACTOR :: 1.15 //variation 
BLOB_FOLIAGE_LEAF_BASE_ANGLE_RANDOM_WIGGLE :: 10

BLOB_FOLIAGE_WIND_MAX_FORCE :: 0.25
BLOB_FOLIAGE_WIND_COUNTER :: 0.008
BLOB_FOLIAGE_WIND_DAMPING :: 0.98
BLOB_FOLIAGE_WIND_DISTRIBUTION :: 1
BLOB_FOLIAGE_WIND_CHANCE :: 1./480.


_blobFoliage_system_reload :: proc(){
	trace("Generate blob foliage")
	print("Generating blob foliage sprites...")

	texture_group_load_block("blob_foliage")

	blobData := [BLOB_FOLIAGE_TYPE_COUNT]struct{
		size:Vec2, //(size.x*BLOB_FOLIAGE_FRAME_COUNT/BLOB_FOLIAGE_FRAME_INTERVAL) should ideally be divisible 4096
		poleRadius:f32,
		poleCount:int,
		poleSDFRange:f32,
		baseScale:f32,
		leafLowerSeparation:f32,
		leafUpperSeparation:f32,
		leafOffsetVariation:f32,
		leafLowerOffset:f32,
		leafUpperOffset:f32,
		offsetUpperWithBiggerPoles:bool,
		splitChance:f32,
		splitMinAngle:f32,
		splitMaxAngle:f32,
		seed:u64 //semi-literal in this case lol
	}{
		//size			|pole rad/count/range		|scale	|leaf seps		|offset wiggle/low/high |split chance/min/max	|seed
		{{32,32}, 		2,			1, 		3,		0.4, 	0.1,  	3.5,	1, -3, 6,  		true,		0.0, 50, 120,  			3}, //tiny
		{{32,32}, 		1,			1, 		3,		0.4, 	0.1,  	3,		1, -2, 5.5,  	true,		0.0, 50, 120,  			5},
		{{32,32}, 		4,			1, 		3,		0.5, 	1,		3.5,	1, -3, 0.5,  	true,		0.0, 50, 120,  			3},
		
		{{48,40}, 		6.5,		2, 		1,		0.48, 	3,		4.5,	1, -1, 	5,  	true,		0.0, 50, 120,  			12}, //small
		{{48,40}, 		6.5,		2, 		1,		0.48, 	3,		4.5,	1, -1, 	3,  	true,		0.0, 50, 120,  			12},
		{{48,48}, 		11,			1, 		3,		0.5, 	3,		5,		1, -1, 	6.5,  	true,		0.0, 50, 120,  			1}, 
		{{48,48}, 		9,			1, 		3,		0.6, 	4,		7.5,	0.5, -2, 1.5,	false,		0.9, 50, 100,  			10}, 
		{{48,48}, 		6,			10, 	3,		0.6, 	3,		4.5,	2, -4, -1,  	false,		0.5, 50, 120,  			1},
		//{{48,48}, 		4,			7, 		3,		0.5, 	3,		9,		0.5, -4, -0.75,  false,		1, 85, 95,  			8},
		
		{{96,48}, 		7,			21, 	3,		0.5, 	3,		10,		0.5, -3, 0.25,  false,		1, 85, 95,  			3}, //medium
		{{96,48}, 		5,			18, 	2,		0.5, 	3,		10,		0.5, -3, 0.25,  false,		1, 85, 95,  			8},

		{{96,96},     	7,         	14,     6,    	0.7,  	4,      15,     0.5, -4, 0,     false,     	1.25, 90, 100,           1}, //large
		{{128,96},     	7,         	24,     6,    	0.79,  	4,      15,     0.5, -4, 0,     false,     	1.25, 90, 100,           1}, 

		{{128,136}, 	6.2,		25, 	5.75,	0.54, 	4,		11,		0.5, -3, -0.75, false,		1.25, 80, 95,  			1}  //giant
	}
	
	leaves := make([dynamic]BlobFoliageGeneratorLeaf, context.temp_allocator)
	poles := make([dynamic]SDFShape, context.temp_allocator)
	upperPoles := make([dynamic]SDFShape, context.temp_allocator)
	leafSourceSprite := sp.blobLeaf0
	leafScaleMaxFrame := len(leafSourceSprite.frames)-1
	leafSourcePage := leafSourceSprite.frames[0].texturePage
	leafSprites := []^Sprite{sp.blobLeaf0, sp.blobLeaf15, sp.blobLeaf30, sp.blobLeaf45, sp.blobLeaf60, sp.blobLeaf75}

	drawPos:Vec2

	blobFrameDuration := time_convert(BLOB_FOLIAGE_FRAME_INTERVAL, .frames, .milliseconds)
	for blob, blobInd in blobData{
		//reset the target and flush rendering per blob to prevent accumulated draw calls from overwhelming vulkan on low-end hardware.
		tex_target_set(foliage_system.blobs_texture_page, clear=blobInd == 0)

		random_set_seed(blob.seed)

		clear(&poles)
		clear(&leaves)

		resize(&poles, blob.poleCount)
		resize(&upperPoles, blob.poleCount)

		margin := blob.poleRadius + blob.baseScale*10*BLOB_FOLIAGE_LEAF_RANDOM_SCALING_FACTOR + blob.leafUpperOffset + blob.leafOffsetVariation
		contourStart:Vec2= -INF

		center := blob.size/2
		l := min(margin, center.x)
		r := max(blob.size.x - margin, center.x)
		t := min(margin, center.y)
		b := max(blob.size.y - margin, center.y)
		for &pole,i in poles{
			newPole := Circle{Vec2{random_range(l, r), random_range(t, b)}, blob.poleRadius}
			contourStart = max(contourStart, newPole.pos.x + newPole.radius)
			pole = newPole
			newPole.radius += blob.leafUpperOffset/2
			upperPoles[i] = newPole
		}

		// if len(poles) > 1{
		// 	//improve clustering
		// 	center := blob.baseScale/2
		// 	for &pole,i in poles{
		// 		nearest:^Vec2
		// 		nearestDist:f32=INF
		// 		for &pole_,j in poles{
		// 			if i==j do continue
		// 			curDist := vec2_distance(pole, pole_)
		// 			if curDist < nearestDist{
		// 				nearest = &pole_
		// 			}
		// 		}

		// 		if nearestDist > blob.poleRadius/2{
		// 			if vec2_distance(nearest^, center) < vec2_distance(pole, center) do pole = vec2_approach(pole, nearest^, nearestDist-blob.poleRadius/2)
		// 			else do nearest^ = vec2_approach(nearest^, pole, nearestDist-blob.poleRadius/2)
		// 		}
		// 	}
		// }

		lowerLeafRays := sdf_trace_contour(contourStart, poles[:], blob.poleSDFRange, blob.leafLowerSeparation)
		upperLeafRays := sdf_trace_contour(contourStart, blob.offsetUpperWithBiggerPoles ? upperPoles[:]:poles[:], blob.poleSDFRange, blob.leafUpperSeparation)
		leafRays := lowerLeafRays
		leafOffset := blob.leafLowerOffset
		{i:=0; layer:=0; for{
			ray := leafRays[i]
			baseAngle := ray.dir+random_range_f(-BLOB_FOLIAGE_LEAF_BASE_ANGLE_RANDOM_WIGGLE,BLOB_FOLIAGE_LEAF_BASE_ANGLE_RANDOM_WIGGLE)
			baseLeafPos := vec2_offset(ray.dir, leafOffset + random_range(-blob.leafOffsetVariation, blob.leafOffsetVariation), ray.pos)
			scale := random_range(blob.baseScale/BLOB_FOLIAGE_LEAF_RANDOM_SCALING_FACTOR, blob.baseScale*BLOB_FOLIAGE_LEAF_RANDOM_SCALING_FACTOR)
			frameInd := clamp(roundi(remap(scale, 0.5/BLOB_FOLIAGE_LEAF_RANDOM_SCALING_FACTOR, BLOB_FOLIAGE_LEAF_RANDOM_SCALING_FACTOR, 0, f32(leafScaleMaxFrame))), 0, leafScaleMaxFrame)
			angles:=[]f32{baseAngle}
			if blob.splitChance > 0 && layer==1{
				angleDiff := random_range(blob.splitMinAngle, blob.splitMaxAngle)/2
				if blob.splitChance >= 1 && roll(blob.splitChance-1) do angles = {baseAngle-angleDiff, baseAngle, baseAngle+angleDiff}
				else if blob.splitChance >= 1 || roll(blob.splitChance) do angles = {baseAngle-angleDiff, baseAngle+angleDiff}
			}

			for a in angles{
				angleOffInd := i8(round(wrap(a, 0, 90)/15))
				if angleOffInd == 6 do angleOffInd = 0
				leafSprite := leafSprites[angleOffInd]
				leafPos := baseLeafPos
				if len(angles)!=1 do leafPos = vec2_offset(a, 1, baseLeafPos)
				append(&leaves, BlobFoliageGeneratorLeaf{
					&leafSprite.frames[frameInd],
					leafSprite.origin,
					a,
					0,
					random_range(-BLOB_FOLIAGE_WIND_MAX_FORCE,BLOB_FOLIAGE_WIND_MAX_FORCE), //choose([]f32{-1,1})*(pow(random(), BLOB_FOLIAGE_WIND_DISTRIBUTION)*BLOB_FOLIAGE_WIND_MAX_FORCE),
					cast([2]u8)round(leafPos),
					angleOffInd*15
				})
			}
			
			if i == len(leafRays)-1{
				if layer == 0{
					layer+=1
					leafRays = upperLeafRays
					leafOffset = blob.offsetUpperWithBiggerPoles ? 0:blob.leafUpperOffset 
					i = 0
				}
				else do break
			}
			else do i += 1
		}}

		framePositions := &foliage_system.blob_frame_positions[blobInd]
		
		name, newSprite := strmap_get_ptr(sprites._sprites_map, format("blobFoliage__%i", blobInd))
		newSprite.name = name
		newSprite.size = blob.size
		newSprite.origin = floor(blob.size/2)
		newSprite.frames = make([dynamic]SpriteFrame, BLOB_FOLIAGE_FRAME_COUNT_DISPLAYED, assets.allocator)
		
		newSprite.pingPong = true

		foliage_system.blob_sprites[blobInd] = newSprite
		
		simOff :: 256
		framePos :f32= 0
		for n in 0..<BLOB_FOLIAGE_FRAME_COUNT+simOff{
			for &leaf in leaves{
				if roll(BLOB_FOLIAGE_WIND_CHANCE) do leaf.windForceSpeed += choose([]f32{-1,1})*(pow(random(), BLOB_FOLIAGE_WIND_DISTRIBUTION)*BLOB_FOLIAGE_WIND_MAX_FORCE)
				windAcl := leaf.windForce*-BLOB_FOLIAGE_WIND_COUNTER
				leaf.windForceSpeed += windAcl
				leaf.windForceSpeed *= BLOB_FOLIAGE_WIND_DAMPING
				leaf.windForce += leaf.windForceSpeed
				leaf.angle += leaf.windForce
			}
			renderN := n-simOff
			if renderN>=0 && renderN%BLOB_FOLIAGE_FRAME_INTERVAL==0{
				blendmode_set(.subtract)
				draw_rect(Rect{drawPos, blob.size}, COLOR_WHITE, 1)
				blendmode_set(.blend)
				for &leaf,i in leaves{
					x := drawPos.x + f32(leaf.pos.x)
					y := drawPos.y + f32(leaf.pos.y)
					frame := leaf.leafFrame

					//adjust origin for trim
					size := frame.texturePagePos.size
					origin := leaf.spriteOrigin - frame.trimOffset

					render_quad(leafSourcePage.texture, .nearest, Quad{
						worldRect = {{round(x - origin.x), round(y - origin.y)}, round(size)},
						uvRect = spriteFrame_uv(frame, frame.texturePagePos),
						pivot = {round(origin.x), round(origin.y)},
						rotation = angle_to_rads(-leaf.angle + f32(leaf.angleOffset)),
						blend=BLEND_WHITE,
					})
				}
				sdf_draw(poles[:], blob.poleSDFRange, offset=drawPos)

				tpp := Rect{drawPos, blob.size}
				frameInd := renderN/BLOB_FOLIAGE_FRAME_INTERVAL
				framePositions[frameInd] = tpp
				spriteFrame := &newSprite.frames[frameInd]
				spriteFrame.texturePagePos = tpp
				spriteFrame.framePosition = framePos
				spriteFrame.duration = blobFrameDuration
				framePos += blobFrameDuration
				spriteFrame.texturePage = &foliage_system.blobs_page
				
				drawPos.x += blob.size.x
				if drawPos.x+blob.size.x>=4096{
					drawPos.x = 0
					drawPos.y += blob.size.y
				}
			}
		}

		newSprite.totalDuration = framePos

		tex_target_reset()
		render_flush()
	}

	

	// tex_target_set(foliage_system.test_blob)
	// draw_color(COLOR_RED)
	// for &leaf in leaves[20:30]{
	// 	a := leaf.angle
	// 	dp := vec2_offset(leaf.angle, 20, Vec2{100,100})
	// 	x :f32= dp.x
	// 	y :f32= dp.y
	// 	frame := leaf.leafFrame


	// 	//convert origin and new sizes to f32 for transformation and adjust for trim
	// 	size := Vec2{f32(frame.texturePagePos.w), f32(frame.texturePagePos.h)}
	// 	origin := Vec2{f32(leaf.spriteOrigin.x - frame.trimOffset.x), f32(leaf.spriteOrigin.y - frame.trimOffset.y)}

	// 	dst := sdl3.Rect{
	// 		i32(round(x - origin.x)),
	// 		i32(round(y - origin.y)),
	// 		i32(round(size.x)),
	// 		i32(round(size.y))
	// 	}

	// 	pivot := sdl3.Point{i32(round(origin.x)), i32(round(origin.y))}
		
	// 	sdl3.RenderCopyEx(display._renderer, leafSourcePage, &frame.texturePagePos, &dst, f64(-leaf.angle)+f64(leaf.angleOffset), &pivot, .NONE)

	// 	draw_line(dp, 100)
	// }

	tex_target_clear()
}

BlobFoliageGeneratorLeaf :: struct{
	leafFrame:^SpriteFrame,
	spriteOrigin:Vec2,
	angle:f32,
	windForce:f32,
	windForceSpeed:f32,
	pos:[2]u8,
	angleOffset:i8
}

//COMPONENT STARTS HERE

BlobFoliage :: struct{
	using base:RenderComponentBase,
	stageEntity:CoRef(StageEntity),
	seed:u64, //@e
	clusterGens:[dynamic; BLOB_FOLIAGE_MAX_CLUSTERS]BlobFoliageClusterGenerator, //@e
	clusters:[dynamic; BLOB_FOLIAGE_MAX_CLUSTERS]BlobFoliageCluster,
	drawBlobs:[dynamic]MeshQuad,
	cull:bool,
}

BLOB_FOLIAGE_MAX_CLUSTERS :: 16
BLOB_FOLIAGE_SHUFFLE_CHANCE :: 0.4

BLOB_FOLIAGE_SWAY_MAX_FORCE :: 0.25
BLOB_FOLIAGE_SWAY_COUNTER :: 0.0008
BLOB_FOLIAGE_SWAY_DAMPING :: 0.98
BLOB_FOLIAGE_SWAY_DISTRIBUTION :: 10
BLOB_FOLIAGE_SWAY_CHANCE :: 1./20.

BLOB_FOLIAGE_LAYER_COUNT :: 8
BLOB_FOLIAGE_LAYER_COLORS := [BLOB_FOLIAGE_LAYER_COUNT]Color{
	color_hex(0x0f271c),
	color_hex(0x19342a),
	color_hex(0x1f4134),
	color_hex(0x28533a),
	color_hex(0x366a22),
	color_hex(0x4c852f),
	color_hex(0x77a634),
	color_hex(0xa4c245)
}

BlobFoliageClusterGenerator :: struct{
	pos:Vec2,
	radii:Vec2,
	growOffset:Vec2 //foliage "grows" towards this pos as depth decreases
}

BlobFoliageCluster :: struct{
	basePos:Vec2,
	//swayOffset:Vec2,
	swaySpeed:Vec2,
	swayAcceleration:Vec2,
	maxRad:f32, //used for culling
	blobs:[dynamic]BlobFoliageBlob
}

BlobFoliageBlob :: struct{
	basePos:Vec2,
	quadInd:u16,
	frame:u16,
	animReverse:bool,
	blobSpriteInd:u8,
	layer:u8,
	colorInd:u8,
	flip:[2]bool
}

blobFoliage_regenerate :: proc(using self:^BlobFoliage){
	prevRandom := random_state_get()
	defer random_state_set(prevRandom)

	clear(&clusters)
	clear(&drawBlobs)
	resize(&clusters, len(clusterGens))
	layerCount := len(BLOB_FOLIAGE_LAYER_COLORS)
	layerCounts:[BLOB_FOLIAGE_LAYER_COUNT]u16
	for gen, clusterInd in clusterGens{
		random_set_seed(u64(clusterInd)+seed)
		cluster := &clusters[clusterInd]
		cluster.basePos = gen.pos
		cluster.maxRad = max(gen.radii)
		clusterBlobs := &cluster.blobs
		if clusterBlobs[:] == nil do init(clusterBlobs, stage.allocator)
		else do clear(clusterBlobs)

		for layerInd in 0..<BLOB_FOLIAGE_LAYER_COUNT{
			currentEllipse := Ellipse{
				lerp(gen.pos, gen.pos + gen.growOffset, f32(layerInd)/f32(layerCount), cu.easeOut),
				lerp(gen.radii, Vec2{}, f32(layerInd)/f32(layerCount+1), cu.easeOut)
			}

			randomSizeInd :: proc()->int{
				cat := random_i(5)
				switch cat{
					case 0: return random_range(0,2)
					case 1: return random_range(3,7)
					case 2: return random_range(8,9)
					case 3: return random_range(9,10)
					case 4: return 12
				}
				unreachable()
			}
			area := ellipse_area(currentEllipse)
			for area > 0{
				ind:int
				if area <= 48*40 do ind = random_range(0,5)
				else do ind = randomSizeInd()
				indRect := foliage_system.blob_frame_positions[ind][0]
				indSize := indRect.size
				indArea := indSize.x*indSize.y
				if indArea > area && ind>5 do continue

				sampleEllipse := currentEllipse
				sampleEllipse.radii = max(sampleEllipse.radii-indSize/2, 0)
				append(clusterBlobs, BlobFoliageBlob{
					ellipse_sample(sampleEllipse),
					layerCounts[layerInd],
					u16(random_i(BLOB_FOLIAGE_FRAME_COUNT_DISPLAYED)),
					bool(random_i(2)),
					u8(ind),
					u8(layerInd),
					u8((layerInd <=4 && roll(BLOB_FOLIAGE_SHUFFLE_CHANCE))?layerInd+1:layerInd), //rng has to be caluclated here
					{roll(0.5), roll(0.5)}
				})
				layerCounts[layerInd] += 1
				
				area -= indArea
			}
		}
	}

	//generate draw quads depth-sorted
	for layerInd in 0..<BLOB_FOLIAGE_LAYER_COUNT{
		for n in 0..<layerCounts[layerInd]{
			append(&drawBlobs, MeshQuad{})
		}
	}

	//set proper quad indices
	for &cluster in clusters{
		for &blob in &cluster.blobs{
			qi := blob.quadInd
			for n in 0..<blob.layer do qi += layerCounts[n]
			blob.quadInd = qi
			col := BLOB_FOLIAGE_LAYER_COLORS[blob.colorInd]
			drawBlobs[qi].blends = color_to_blend(col)
		}
	}
}


_blobFoliage_process_event :: proc(base:^ComponentBase, event:Event, overrideDisabled:=false){
if(!overrideDisabled && event in base.disabledEvents) do return
last_context := entities.context_component
defer cowith(last_context)
cowith(base)
self := cast(^BlobFoliage)base
using self

widgetHoverRad :: 6
widgetHoverRadCenter :: 8
@(static) editorSelection:struct{
	using ptr:^BlobFoliageClusterGenerator,
	kind:enum{
		pos,
		growPos,
		radX,
		radY
	}
}
@(static) editorHovering:^BlobFoliageClusterGenerator

#partial switch event{
case .init:
	coadd(&stageEntity)
	seed = 1
	estring_set(&stageEntity.group, "blob_foliage")
	stageEntity.debugVisibleOnly = true

case .loaded:
	blobFoliage_regenerate(self)

case .editorUndo: fallthrough 
case .editorRedo:
	if stageEntity_editing(stageEntity) do blobFoliage_regenerate(self)
	
case .editing:
	editing := stageEntity_editing(stageEntity)
	if imgui.Checkbox("Edit Clusters", &editing){
		stage_edit.cursor_contents = editing ? stageEntity._ptr : crx(stageEntity)
		if editing do stage_edit_undo_push() //ensure foliage regenerates if undoing the first change made
	}
case .updateEditor:
	if !stageEntity_editing(stageEntity) do return

	mp := stage_edit.cursor_coords.pos - stageEntity_draw_pos(stageEntity)

	if mouse_held(.LEFT) && editorSelection.ptr != nil{
		switch editorSelection.kind{
			case .pos: editorSelection.pos = mp
			case .growPos: editorSelection.growOffset = mp - editorSelection.pos
			case .radX: editorSelection.radii.x = abs(mp.x - editorSelection.pos.x)
			case .radY: editorSelection.radii.y = abs(mp.y - editorSelection.pos.y)
		}
		blobFoliage_regenerate(self)
	}
	else{
		if editorSelection.ptr != nil{
			editorSelection.ptr = nil
			stage_edit_undo_push()
		}

		guiIO := imgui.GetIO()
		captureMouse := guiIO.WantCaptureMouse
		if captureMouse do return

		editorHovering = nil
		for &cluster in clusterGens{
			if vec2_distance(mp, cluster.pos + {cluster.radii.x, 0}) < widgetHoverRad || vec2_distance(mp, cluster.pos - {cluster.radii.x, 0}) < widgetHoverRad{
				editorHovering = &cluster
				editorSelection.kind = .radX
				break
			}
			else if vec2_distance(mp, cluster.pos + {0, cluster.radii.y}) < widgetHoverRad || vec2_distance(mp, cluster.pos - {0, cluster.radii.y}) < widgetHoverRad{
				editorHovering = &cluster
				editorSelection.kind = .radY
				break
			}
			else if vec2_distance(mp, cluster.pos + cluster.growOffset) < widgetHoverRad{
				editorHovering = &cluster
				editorSelection.kind = .growPos
				break
			}
			else if vec2_distance(mp, cluster.pos) < widgetHoverRadCenter{
				editorHovering = &cluster
				editorSelection.kind = .pos
				break
			}
		}

		if mouse_pressed(.LEFT){
			if editorHovering == nil{
				append(&clusterGens, BlobFoliageClusterGenerator{
					mp,
					{96,96},
					-{0,8}
				})
				editorHovering = peek_ptr(&clusterGens)
				editorSelection.kind = .pos
			}
			editorSelection.ptr = editorHovering
		}
		else if mouse_pressed(.RIGHT){
			if editorHovering != nil{
				remove_unordered(&clusterGens, mem.ptr_sub(editorHovering, &clusterGens[0]))
				blobFoliage_regenerate(self)
				stage_edit_undo_push()
				editorHovering = nil
			}
		}
	}

case .preDraw:
	cull = !stage_edit.enabled
	camRect := stage_camera_rect()
	entityPos := stageEntity_draw_pos(stageEntity)

	//update draw blobs
	for &cluster in clusters{
		// for &c, i in cluster.swayOffset{
		// 	if roll(BLOB_FOLIAGE_SWAY_CHANCE) do cluster.swaySpeed[i] += -(pow(random(), BLOB_FOLIAGE_SWAY_DISTRIBUTION)*BLOB_FOLIAGE_SWAY_MAX_FORCE)
		// 	cluster.swayAcceleration[i] = c*-BLOB_FOLIAGE_SWAY_COUNTER
		// 	cluster.swaySpeed[i] += cluster.swayAcceleration[i]
		// 	cluster.swaySpeed[i] *= BLOB_FOLIAGE_SWAY_DAMPING
		// 	c += cluster.swaySpeed[i]
		// }
		for &blob in cluster.blobs{
			//update frame ping-pong style to mask loop
			if time.frame%BLOB_FOLIAGE_FRAME_INTERVAL == 0{
				if blob.animReverse{
					if blob.frame==0{
						blob.animReverse = !blob.animReverse
						blob.frame += 1
					}
					else do blob.frame -= 1
				}
				else{
					if blob.frame==BLOB_FOLIAGE_FRAME_COUNT_DISPLAYED-1{
						blob.animReverse = !blob.animReverse
						blob.frame -= 1
					}
					else do blob.frame += 1
				}
			}
		}

		if cull{
			checkRect := camRect
			rect_resize_in_place(&checkRect, cluster.maxRad, cluster.maxRad)
			if rect_contains(checkRect, cluster.basePos + entityPos) do cull = false
		}
	}

	if cull do return

	for &cluster in clusters{
		for &blob in cluster.blobs{
			//uvs
			tpp := foliage_system.blob_frame_positions[blob.blobSpriteInd][blob.frame]
			p1 := tpp.pos/4096
			p2 := (tpp.pos+tpp.size)/4096

			u := Vec2{p1.x, p2.x}
			v := Vec2{p1.y, p2.y}
			if blob.flip.x do u = {u.y, u.x}
			if blob.flip.y do v = {v.y, v.x}

			drawBlobs[blob.quadInd].uvs = {
				{u.x, v.x}, {u.y, v.x},
				{u.y, v.y}, {u.x, v.y},
			}

			//draw pos
			drawPos := blob.basePos + entityPos //+ cluster.swayOffset*remap(f32(blob.layer), 0, BLOB_FOLIAGE_LAYER_COUNT-1, 0, 1, cu.easeOut)
			halfSize := tpp.size/2
			p1 = drawPos-halfSize
			p2 = drawPos+halfSize
			drawBlobs[blob.quadInd].quad = {p1, {p2.x, p1.y}, p2, {p1.x, p2.y}}
		}
	}
	depth = stageEntity.depth
case .draw:
	blobCount := len(drawBlobs)
	if blobCount == 0 || cull do return

	//the whole cluster is one contiguous mesh range, so it stays a single draw
	render_mesh_quads(foliage_system.blobs_texture_page.ptr, .nearest, drawBlobs[:])

case .drawEditor:
	if !stageEntity_editing(stageEntity) do return

	entityPos := stageEntity_draw_pos(stageEntity)
	shader_set(Sh_Base)
	for &cluster in clusterGens{
		clusterPos := cluster.pos + entityPos
		hoveringCluster := editorHovering == &cluster
		hovering := hoveringCluster && editorSelection.kind == .pos
		draw_circle(clusterPos, widgetHoverRadCenter/(hovering?1.:2.), color_hex(0x8324b4), hovering?0.7:0.3)
		
		draw_rings(clusterPos, {cluster.radii, cluster.radii+2}, {COLOR_WHITE, color_hex(0x1859b4)}, {0, hoveringCluster?0.7:0.3})
		
		hovering = hoveringCluster && editorSelection.kind == .radX
		draw_circle(clusterPos + {cluster.radii.x, 0}, widgetHoverRad/(hovering?1.:2.), color_hex(0x62beff), hovering?0.7:0.3)
		draw_circle(clusterPos - {cluster.radii.x, 0}, widgetHoverRad/(hovering?1.:2.), color_hex(0x62beff), hovering?0.7:0.3)

		hovering = hoveringCluster && editorSelection.kind == .radY
		draw_circle(clusterPos + {0,cluster.radii.y}, widgetHoverRad/(hovering?1.:2.), color_hex(0x62beff), hovering?0.7:0.3)
		draw_circle(clusterPos - {0,cluster.radii.y}, widgetHoverRad/(hovering?1.:2.), color_hex(0x62beff), hovering?0.7:0.3)

		hovering = hoveringCluster && editorSelection.kind == .growPos
		draw_circle(clusterPos+cluster.growOffset, widgetHoverRad/(hovering?1.:2.), color_hex(0xf6da62), hovering?0.7:0.3)
	}
	shader_reset()
}}
