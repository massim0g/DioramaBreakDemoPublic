#+feature using-stmt
package massimodin //@nested-tags:stages

import "core:reflect"
import "../sdl2"
import gl "vendor:OpenGL"

DepthListEntrySprite :: struct{
	blendData:BlendData,
	sprite:^Sprite,
	pos:Vec2
}
DepthListEntryTex :: struct{
	tex:Tex,
	pos:Vec2,
	alpha:f32
}

DepthListEntryParticles :: struct{
	parts:[]Particle
}

DepthListEntryEntity :: struct{
	base:^ComponentBase,
	drawStep:int,
	process:proc(base: ^ComponentBase, event: Event, overrideDisabled:=false),
	ev:Event
}

DepthListEntryPreciseDepthEntity :: struct{
	ent:^StageEntity,
	segmentInd:int
}

DepthListEntryTiles :: struct{
	tileset:^Tileset,
	pos:Vec2,
	tileData:[]TileLayerTile,
	w:int,
	h:int,
	blendData:BlendData
}

DepthListEntryTint :: struct{
	using tintData:TintData,
	gradientRect:Rect,
	clampGradient:bool
}

DepthListEntryShader :: struct{
	s:Shader,
	reset:bool
}

DepthListEntryDepthWidget :: struct{
	top:Vec2,
	bottom:Vec2
}


DepthListEntryProc :: struct{
	c:proc()
}

DepthListEntryEditCursor :: struct{}

DepthListEntryPoint :: struct{
	pos:Vec2,
	blendData:BlendData
}
DepthListEntryLine :: struct{
	l:Line,
	blendData:BlendData
}

//some larger uncommon variants are passed as pointers to keep the size of the union below 32 bytes
DepthListEntry :: union{
	DepthListEntryEntity,
	DepthListEntryPreciseDepthEntity,
	^DepthListEntryTiles,
	DepthListEntryEditCursor,
	DepthListEntrySprite,
	DepthListEntryPoint,
	DepthListEntryLine,
	DepthListEntryTex,
	DepthListEntryParticles,
	DepthListEntryProc,
	^DepthListEntryTint,
	DepthListEntryShader,
	DepthListEntryDepthWidget,
	^SequenceDeferredDraw
}
DepthListRef :: struct{
	depth:f32,
	ind:u16
}

DropShadow :: struct{
	shape:union{Ellipse, Rect},
	angle:f32,
	alpha:f32
}

stage_shader_uniforms_set :: proc(self:^StageEntity){
	using self
	if depthKind != .floor && receivesVerticalShadow && !stage_edit.enabled{
		shader_uniform_set(sh.stage, "verticalShading", true)
		
		frame := &spriter.mySprite.frames[spriter.lastFrame]
		shader_uniform_set(sh.stage, "tpPos", sdl_rect_to_rect(frame.texturePagePos)); 
		// tpw,tph:i32
		// sdl2.QueryTexture(frame.texturePage.texture, nil, nil, &tpw, &tph)
		//shader_uniform_set(sh.stage, "tpSize", Vec2{f32(tpw), f32(tph)});
		//shader_uniform_set(sh.stage, "baseZ", transform.z);
		shader_uniform_set(sh.stage, "feetPos", transform.pos)
	}
}

stage_shader_uniforms_reset :: proc(self:^StageEntity){
	if self.depthKind != .floor && self.receivesVerticalShadow && !stage_edit.enabled do shader_uniform_set(sh.stage, "verticalShading", false)
}

_stage_render :: proc(){ //handles depth-sorted rendering for the stage
	tracy_auto_trace = false
	defer tracy_auto_trace = true
	//trace("Stage Render")
	//todo: static stage elements should be sorted into depth list only once, on stage load
	
	stage.render_depth_list = make([dynamic]DepthListEntry, 0, 2048, context.temp_allocator)
	stage.render_depth_list_sorted_refs = make([dynamic]DepthListRef, 0, 2048, context.temp_allocator)

	entryAppend :: proc(depth:f32, entry:DepthListEntry){
		append(&stage.render_depth_list_sorted_refs, DepthListRef{depth, u16(len(stage.render_depth_list))})
		append(&stage.render_depth_list, entry)
	}

	//ENTITIES

	//precise-depth stage entity and culling and shadows
	camRect := stage_camera_rect()
	stageEntities := coall(StageEntity)
	{
		trace("Stage Entity Cull and Shadows")

		clear(&stage.drop_shadows)
		tex_target_set(stage.shadow_map, stage.bounds.pos, true)
		shader_set(sh.colorOnly)
		for &ent in stageEntities{
			using ent
			if !componentsVisible do continue

			//cull check
			if !stage_edit.enabled && 
				staticSet && 
				drawParallax == {0,0} && 
				!debugVisibleOnly &&
				!(shadowKind == .isShadow || shadowKind == .isLight)
			{
				visible = rects_overlap(camRect, cullRect)
				if !visible do continue
			}
	
			if depthKind == .precise{ 
				baseDepth := -ent.transform.y + ent.editableDepthOffset
				for segment,i in ent.preciseDepthSegments{ //hot!
					
					entryAppend(
						baseDepth + segment.internalDepthOffset,
						DepthListEntryPreciseDepthEntity{&ent, i}
					)
				}
			}
			
			switch shadowKind{
				case .none: //do nothing
				case .isShadow, .isLight:
					if invertShadowMargin > 0{
						shader_set(shaders._base_shader)
						drawRect := stageEntity_draw_rect(&ent)
						texSize := Vec2i(drawRect.size)
						if invertShadowTex.size != texSize do tex_resize(&invertShadowTex, texSize)
						spriteOrigin := spriter_origin(spriter)
						tex_target_set(invertShadowTex, clear=false)
							draw_clear()
							center := drawRect.size/2
							originAdjusted := -spriteOrigin + drawRect.size
							edgeEllipse := Ellipse{radii=drawRect.size}
							for a:f32=0;a<360;a+=360/8{
								edgePoint := ellipse_edge_point(edgeEllipse, a)
								sprite_draw_ex(spriter.mySprite, originAdjusted + vec2_normalize(edgePoint)*(vec2_mag_get(edgePoint)-invertShadowMargin), spriter.lastFrame, blendmode=BlendMode.subtract)
							}
						tex_target_reset()
						shader_reset()
						tex_draw(invertShadowTex, drawRect.pos)
					}
					else{
						ent.shadowDraw(&ent)
					}
				case .dropShadowEllipse:
					append(&stage.drop_shadows, DropShadow{
						Ellipse{
							Vec2{transform.x, transform.y + max(transform.z, 0)} + dropShadowOffset, 
							dropShadowRadii
						}, 
						dropShadowAngle,
						ent.alpha
					})
				case .dropShadowRect:
					append(&stage.drop_shadows, DropShadow{Rect{
						Vec2{transform.x, transform.y + max(transform.z, 0)} + dropShadowOffset - dropShadowRadii, 
						dropShadowRadii*2
					}, dropShadowAngle, ent.alpha})
			}
		}
		shader_reset()
		tex_target_set(stage.shadow_layer, stage_camera_pos(), clear=false)
		draw_clear(COLOR_BLACK, 0)
		tex_draw(stage.shadow_map, stage.bounds.pos)
		for shadow in stage.drop_shadows{
			switch ds in shadow.shape{
				case Ellipse: sprite_draw_ex(sp.circle256, ds.pos, scale=ds.radii*2./256., angle=shadow.angle, color=COLOR_BLACK, alpha=shadow.alpha)
				case Rect: draw_rect(ds, COLOR_BLACK, shadow.alpha) //todo: angled rects?
			}
		}
		tex_target_reset(2)

		entryAppend(
			DEPTH_MAX-102,
			DepthListEntryProc{proc(){
				destination := display_main_tex_inactive()
				shader_set(sh.shadowLayer)
				shader_texture_bind(sh.shadowLayer, "destination", destination)
				defer shader_texture_unbind(destination)
				shader_uniform_set(sh.shadowLayer, "shadowBlend", stage.shadowBlend)
				shader_uniform_set(sh.shadowLayer, "lightBlend", stage.lightBlend)
				tex_draw_ex(stage.shadow_layer, stage_camera_pos())
				shader_reset()
			}}
		)
	}

	addEntityDraws :: proc(ev:Event, internalDepthOffset:f32=0){
		for componentType in entities.component_type_event_register[ev]{
			metadata := &entities.component_type_metadata[componentType]
			arr := metadata.get_array_pointer()
			process := metadata.process
			basePtr := uintptr(arr.data)
			size := uintptr(reflect.size_of_typeid(metadata.type))
			arrLen := uintptr(arr.len)

			for ptr:=basePtr; ptr<basePtr+size*arrLen; ptr+=size{
				renderPtr := cast(^RenderComponentBase)ptr
				if(renderPtr.visible && renderPtr.depth != nil){
					switch depth in renderPtr.depth{
						case f32:
							entryAppend(
								depth+internalDepthOffset,
								DepthListEntryEntity{cast(^ComponentBase)ptr, 0, process, ev}
							)
						case []f32:
							for d, i in depth{
								entryAppend(
									d+internalDepthOffset,
									DepthListEntryEntity{cast(^ComponentBase)ptr, i, process, ev}
								)
							}
					}
				}
			}
		}
	}
	addEntityDraws(.draw)
	

	//PARTICLES
	for depth, group in particles._groups{
		if depth == -INF do continue
		entryAppend(
			depth,
			DepthListEntryParticles{group.particles[:]}
		)
	}

	//LAYERS
	for &layer in stage.layers{
		if !layer.visible do continue
		switch variant in layer.variant{
			case StageLayerImage:
				if(variant.sprite == nil) do continue
				offset:=layer.offset
				depth:f32
				switch layer.depthKind{
					case .floor: depth = DEPTH_MAX+layer.z
					case .foreground: 
						depth = -DEPTH_MAX+layer.z
					case .wall:
						depth = -offset.y
						offset.y += ceil(layer.z)
				}
				entryAppend(
					depth,
					DepthListEntrySprite{layer.blendData, variant.sprite, offset + stage.camera_pos*variant.parallax}
				)
			case StageLayerTiles:
				tileset := variant.tileset
				if(tileset == nil) do continue
				drawPos := Vec2(variant.tilePos)*Vec2(tileset.tileSize) + layer.offset
				if(layer.depthKind == .wall){
					drawPos.y += ceil(layer.z)
					gridH := f32(tileset.tileSize.y)
					depth := -drawPos.y-gridH
					for i in 0..<variant.tileData.h{
						entry := new(DepthListEntryTiles, context.temp_allocator)
						entry^ = {
							tileset, drawPos,
							grid_slice_row(variant.tileData, i), variant.tileData.w, 1, layer.blendData
						} 
						entryAppend(depth, entry)
						drawPos.y += gridH
						depth -= gridH
					}
				}
				else{
					entry := new(DepthListEntryTiles, context.temp_allocator)
					entry^ = {
						tileset, drawPos,
						variant.tileData.buf[:], variant.tileData.w, variant.tileData.h, layer.blendData
					} 
					entryAppend(
						layer.z + (layer.depthKind == .foreground ? -DEPTH_MAX + 1 : DEPTH_MAX - 1),
						entry
					)
				}
			case StageLayerTint:
				entry := new(DepthListEntryTint, context.temp_allocator)
				entry^ = {
					variant.tintData,
					stage.bounds,
					false
				}
				depth:f32
				switch layer.depthKind{
					case .foreground: depth = -DEPTH_MAX+layer.z
					case .floor: depth = DEPTH_MAX+layer.z
					case .wall: 
						depth = -layer.offset.y
						rect_set_bottom(&entry.gradientRect, layer.offset.y + layer.z, true)
						entry.clampGradient = true
				}
				entryAppend(depth, entry)
			case StageLayerShader:
				if variant.shader != 0 && layer.z > variant.resetZ{
					baseDepth:f32
					switch layer.depthKind{
						case .floor: baseDepth = DEPTH_MAX
						case .foreground: baseDepth = -DEPTH_MAX
						case .wall: baseDepth = 0
					}
					
					entryAppend(layer.z + baseDepth, DepthListEntryShader{variant.shader, false})
					entryAppend(variant.resetZ + baseDepth, DepthListEntryShader{0, true})
				}
		}
	}

	//UI
	#partial switch combat.phase{ case .planning, .resolving:
		entryAppend(
			DEPTH_MAX-104,
			DepthListEntryProc{_combat_grid_draw}
		)
		entryAppend(
			-DEPTH_MAX,
			DepthListEntryProc{_combat_action_target_silhouettes_draw}
		)

		if combat.phase == .planning do _combat_aim_indicators_append(entryAppend)
	}
	

	if combat.time_stop_mode == .enabledWithEffect{
		entryAppend(
			DEPTH_MAX-103,
			DepthListEntryProc{
				proc(){
					combat_shader_set(true)
					display_redraw()
				}
			}
		)
	}

	//SEQUENCE DRAWS
	for &dd in seq._deferred_draws{
		if dd.depth != -INF do entryAppend(dd.depth, &dd)
	}

	//STAGE EDITOR
	if(stage_edit.enabled){
		if(stage_edit.cursor_contents != nil){
			#partial switch contents in stage_edit.cursor_contents{
				case ^Sprite, ^EntityPrefab:
					entryAppend(
						-stage_edit.cursor_coords.y,
						DepthListEntryEditCursor{}
					)
				case ^Mesh:
					entryAppend(
						-DEPTH_MAX, DepthListEntryProc{proc(){
							meshPtr := stage_edit.cursor_contents.(^Mesh)
							mesh := meshPtr^
							
							edgeColor := meshPtr == &stage.collisionMesh ? Color{246, 170, 8} : COLOR_GREEN
							vertexColor := Color{131, 36, 180}

							newEdge, drawingNewEdge := stage_edit.mesh_edit_content.(^[2]u16)
							_, draggingVertex := stage_edit.mesh_edit_content.(^Vec2)
							noSelection := !draggingVertex && !drawingNewEdge

							nearestPoint, nearestPointEdgeInd, nearestVertexInd := mesh_nearest_point(mesh, stage_edit.cursor_coords.pos)

							draw_rect(Rect{stage_camera_pos(), window_size()}, COLOR_BLACK, 0.5)
							edgeCount := len(mesh.edges)
							if edgeCount > 0{
								draw_color(edgeColor)
								edges := drawingNewEdge ? mesh.edges[:edgeCount-1] : mesh.edges[:]
								for edge in edges{
									draw_line(mesh_edge_to_line(mesh, edge))
								}
	
								if drawingNewEdge{
									draw_color(edgeColor, 127)
									draw_line(mesh.vertices[newEdge[0]], stage_edit.cursor_coords.pos)
								}
							}
							
							draw_color(vertexColor)
							for vertex, i in mesh.vertices{
								draw_circle(vertex, STAGE_EDIT_MESH_HOVER_RANGE/2)
							}

							if noSelection{
								if key_mods_held({.CTRL}){ 
									if nearestVertexInd != -1 && vec2_distance(mesh.vertices[nearestVertexInd], stage_edit.cursor_coords.pos) < STAGE_EDIT_MESH_HOVER_RANGE{
										draw_color(edgeColor, 127)
										draw_circle(mesh.vertices[nearestVertexInd], STAGE_EDIT_MESH_HOVER_RANGE)
									}
									else{ 
										draw_color(vertexColor, 127)
										draw_circle(stage_edit.cursor_coords.pos, STAGE_EDIT_MESH_HOVER_RANGE/2)
									}
								}
								else{ 
									if nearestVertexInd == -1{
										draw_color(vertexColor, 127)
										draw_circle(stage_edit.cursor_coords.pos, STAGE_EDIT_MESH_HOVER_RANGE/2)
									}
									else{
										nearestVert := &mesh.vertices[nearestVertexInd]
										if vec2_distance(nearestVert^, stage_edit.cursor_coords.pos) < STAGE_EDIT_MESH_HOVER_RANGE{
											draw_circle(nearestVert^, STAGE_EDIT_MESH_HOVER_RANGE)
										}
										else if nearestPointEdgeInd != -1 && vec2_distance(nearestPoint, stage_edit.cursor_coords.pos) < STAGE_EDIT_MESH_HOVER_RANGE{
											draw_color(vertexColor, 127)
											draw_circle(nearestPoint, STAGE_EDIT_MESH_HOVER_RANGE/2)
										}
										else{
											newPos := stage_edit.cursor_coords.pos
											if key_mods_held({.SHIFT}) && !stage_edit.grid_entity_snap do newPos = vec2_snap_to_angle(newPos, nearestVert^)
											draw_color(edgeColor, 127)
											draw_line(nearestVert^, newPos)
											draw_color(vertexColor, 127)
											draw_circle(newPos, STAGE_EDIT_MESH_HOVER_RANGE/2)
										}
									}
								}
							}

						}}
					)
			}
		}

		if stage_edit.reference_tex.ptr != nil{
			// entryAppend(
			// 	DEPTH_MAX+1, DepthListEntryTex{stage_edit.reference_tex, Vec2(stage_edit.reference_offset), 1}
			// })
			entryAppend(
				DEPTH_MAX+1, DepthListEntryProc{proc(){
					tex_draw_ex(stage_edit.reference_tex, Vec2(stage_edit.reference_offset), color=color_lerp(stage.backgroundColor, COLOR_WHITE, 0.5))
				}}
			)
		}

		//stage bounds
		entryAppend(
			-DEPTH_MAX-1, DepthListEntryProc{proc(){
				draw_rect_outline(stage.bounds, COLOR_WHITE, 0.5, 2)
			}}
		)

		//depth widgets
		if layer, ok := stage_edit.cursor_contents.(^StageLayer); ok && layer.z < 0 && layer.depthKind == .wall{
			if variant, ok2 := layer.variant.(StageLayerImage); ok2{
				offset := layer.offset
				parallaxAddend := stage.camera_pos*variant.parallax
				entryAppend(
					-offset.y+0.1,
					DepthListEntryDepthWidget{Vec2{offset.x, offset.y + ceil(layer.z)} + parallaxAddend, offset + parallaxAddend}
				)
			}
		}

		if entRef,ok := stage_edit.cursor_contents.(CoRefEx(StageEntity)); ok{
			ent := coget(entRef)
			if ent.transform.z < 0{
				depth:f32
				switch d in ent.depth{
					case f32: depth = d
					case []f32: depth = d[0]
				}
				entryAppend(
					depth+0.1,
					DepthListEntryDepthWidget{stageEntity_draw_pos(ent), ent.transform.pos}
				)
			}
		}

		//entity extra draws
		addEntityDraws(.drawEditor, -0.01)
		
		tex_target_set(texBuffer_active_tex(stage_edit.draw_textures), stage_camera_pos(), false)
	}
	else do camera_set(stage.camera_pos)

	draw_clear(stage.backgroundColor)

	//SORT LIST
	{
		trace("Depth list sort")
		sort(&stage.render_depth_list_sorted_refs, proc(a,b:DepthListRef)->bool{
			if a.depth != b.depth do return a.depth > b.depth
			return a.ind < b.ind //deterministic tiebreaker to mitigate z-fighting issues
		})
		
	}

	//SET STAGE SHADER UNIFORMS
	if !stage_edit.enabled{
		shader_set(sh.stage)
		shader_texture_bind(sh.stage, "shadowMap", stage.shadow_map)
		shader_uniform_set(sh.stage, "stageRect", stage.bounds)
		shader_uniform_set(sh.stage, "shadowBlend", stage.shadowBlend)
		shader_uniform_set(sh.stage, "lightBlend", stage.lightBlend)
		shader_uniform_set(sh.stage, "verticalShading", false)
		shader_uniform_set(sh.stage, "timeStopEffect", false)
		shader_uniform_set(sh.stage, "timeStopSaturation", combat.time_stop_saturation)
	}
	defer if !stage_edit.enabled{shader_texture_unbind(stage.shadow_map)}

	//DRAW
	camPosF := Vec2(camera.pos)
	for ref in stage.render_depth_list_sorted_refs{
		switch variant in &stage.render_depth_list[ref.ind]{
			case DepthListEntryEntity:
				entities.draw_step = variant.drawStep
				variant.process(variant.base, variant.ev)

			case DepthListEntryPreciseDepthEntity: //hot!
				segment := &variant.ent.preciseDepthSegments[variant.segmentInd]
				dstRect := segment.dstRect
				dstOffset := variant.ent.internalDepthOffset.([2]i32) - camera.pos
				dstRect.x += dstOffset.x
				dstRect.y += dstOffset.y
				sdl2.RenderCopyEx(display._renderer, 
					variant.ent.preciseDepthTexturePage,
					&segment.srcRect,
					&dstRect,
					0, nil, variant.ent.transform.scale.x < 0? .HORIZONTAL : .NONE
				)

			case ^DepthListEntryTiles:
				tileSize := cast([2]i32)variant.tileset.tileSize
				gridW := variant.tileset.sprite.size.x/f32(tileSize.x)
				
				sprite := variant.tileset.sprite
				frame := sprite.frames[sprite_frame_get(sprite)]
				tPage := frame.texturePage
				tPageX := frame.texturePagePos.x
				tPageY := frame.texturePagePos.y
				drawPos := cast([2]i32)round(variant.pos) - camera.pos
				srcRect := sdl2.Rect{0, 0, tileSize.x, tileSize.y}
				dstRect := srcRect

				areaW := i32(variant.w) //in tiles
				areaH := i32(variant.h)

				sdl2.SetTextureColorMod(tPage, variant.blendData.color.r, variant.blendData.color.g, variant.blendData.color.b)
				sdl2.SetTextureAlphaMod(tPage, u8(variant.blendData.alpha*255))
				sdl2.SetTextureBlendMode(tPage, display.custom_blendmodes[variant.blendData.blendmode])

				i := 0
				for y in 0..<areaH{
					for x in 0..<areaW{
						tile := variant.tileData[i]
						if(tile.ind != 0){
							tileInd := i32(tile.ind-1)

							srcRect.x = tPageX + (tileInd%i32(gridW))*tileSize.x
							srcRect.y = tPageY + i32(floor(f32(tileInd)/gridW))*tileSize.y
							dstRect.x = drawPos.x + tileSize.x*x
							dstRect.y = drawPos.y + tileSize.y*y

							sdl2.RenderCopyEx(
								display._renderer, tPage, &srcRect, &dstRect, 
								tile.angle + ((tile.flip == 3) ? 180 : 0), nil, sdl2.RendererFlip(tile.flip%3)
							)
						}
						i+=1
					}
				}

			case DepthListEntrySprite:
				sprite_draw_ex(variant.sprite, variant.pos, color=variant.blendData.color, alpha=variant.blendData.alpha, blendmode=variant.blendData.blendmode)
			case DepthListEntryPoint:
				sprite_draw_ex(sp.white1, variant.pos, color=variant.blendData.color, alpha=variant.blendData.alpha, blendmode=variant.blendData.blendmode)
			case DepthListEntryLine:
				//software rendered to not mess up GL state
				//todo: move to dedicated draw_line_software procs
				x0 := i32(variant.l[0].x)
				y0 := i32(variant.l[0].y)
				x1 := i32(variant.l[1].x)
				y1 := i32(variant.l[1].y)
				dx := abs(x1 - x0)
				dy := -abs(y1 - y0)
				sx :i32 = x0 < x1 ? 1 : -1
				sy :i32 = y0 < y1 ? 1 : -1
				err := dx + dy
				src := sdl2.Rect{0,0,1,1}
				sdl2.SetTextureColorMod(shaders.blank_tex, variant.blendData.color.r, variant.blendData.color.g, variant.blendData.color.b)
				sdl2.SetTextureAlphaMod(shaders.blank_tex, u8(clamp(variant.blendData.alpha*255, 0, 255)))
				sdl2.SetTextureBlendMode(shaders.blank_tex, display.custom_blendmodes[variant.blendData.blendmode])
				for {
					dst := sdl2.Rect{x0-camera.pos.x,y0-camera.pos.y, 1, 1}
					sdl2.RenderCopy(display._renderer, shaders.blank_tex, &src, &dst)
					if x0 == x1 && y0 == y1 do break
					e2 := 2 * err
					if e2 >= dy { err += dy; x0 += sx }
					if e2 <= dx { err += dx; y0 += sy }
				}
			case DepthListEntryTex:
				tex_draw_ex(variant.tex, variant.pos, alpha=variant.alpha)
			case ^DepthListEntryTint:
				shader_set(sh.stageTint)
				cols:[16]f32
				n:=0
				for b in variant.tint{
					for cv in b{
						cols[n] = f32(cv)/255
						n+=1
					}
				}
				gl.Uniform4fv(shader_uniform_loc(sh.stageTint, "colors"), 4, raw_data(&cols))
				shader_uniform_set(sh.stageTint, "viewRect", stage_camera_rect())
				shader_uniform_set(sh.stageTint, "viewportSize", stage_edit.enabled ? DISPLAY_SIZE/stage_edit.zoom : DISPLAY_SIZE)
				shader_uniform_set(sh.stageTint, "tintMode", i32(variant.tintMode))
				shader_uniform_set(sh.stageTint, "gradientRect", variant.gradientRect)
				shader_uniform_set(sh.stageTint, "clampGradient", variant.clampGradient)
				display_redraw()
				shader_reset()
			case DepthListEntryShader:
				if variant.reset do shader_reset()
				else{
					shader_set(variant.s)

					//set uniforms
					switch variant.s{
						case sh.shimmer:
							shader_uniform_set(variant.s, "time", f32(time.frame))
					}
				}
			case DepthListEntryEditCursor:
				#partial switch contents in stage_edit.cursor_contents{
					case ^EntityPrefab:
						sprite_draw_ex(contents.previewSprite, stage_edit.cursor_coords.pos, color=COLOR_WHITE, alpha=0.5)
					case ^Sprite:
						sprite_draw_ex(contents, stage_edit.cursor_coords.pos, color=COLOR_WHITE, alpha=0.5)
					
				}
			case DepthListEntryParticles:
				particles_draw(variant.parts)
			case DepthListEntryProc: variant.c()
			case DepthListEntryDepthWidget:
				draw_color(COLOR_GREEN, 127)
				draw_line(variant.top, variant.bottom)
				draw_circle(variant.bottom, 2)
			case ^SequenceDeferredDraw:
				append(&seq.context_seq_stack, variant.contextSeq)
				if !variant.useStageCameraPos do camera_set(Vec2{})
				callback_call(variant.callback)
				if !variant.useStageCameraPos do camera_reset()
				pop(&seq.context_seq_stack)
		}
	}
	if !stage_edit.enabled do shader_reset()

	if (stage_edit.enabled){
		selectRects := make([dynamic]Rect, context.temp_allocator)
		if(stage_edit.cursor_contents != nil){
			#partial switch contents in stage_edit.cursor_contents{
				case []CoRefEx(StageEntity):
					for ref in contents{
						se := coget(ref)
						append(&selectRects, sprite_draw_rect(se.spriter.mySprite, stageEntity_draw_pos(se), 0, se.transform.scale))
					}
					append(&selectRects, stage_edit.multiselect_bounds)
					for &rect in selectRects{
						rect_resize_in_place(&rect, 2, 2)
					}
				case CoRefEx(StageEntity):
					se := coget(contents)
					append(&selectRects, sprite_draw_rect(se.spriter.mySprite, stageEntity_draw_pos(se), 0, se.transform.scale))
					rect_resize_in_place(&selectRects[0], 2, 2)
				case ^StageLayer:
					if tileLayer, ok := contents.variant.(StageLayerTiles); ok && tileLayer.tileset != nil{
						ts := tileLayer.tileset

						tileSize := Vec2(ts.tileSize)
						
						if len(stage_edit.tile_brush_selection.buf) > 0{
							tileCursorBasePos :Vec2i= Vec2i(floor(stage_edit.cursor_coords.pos/tileSize))
							tilesetGridSize := tileset_grid_size(ts)

							rotationOrigin := Vec2(tileCursorBasePos) + (Vec2(grid_size(stage_edit.tile_brush_selection)) - {1,1})/2

							for brushIndex, i in stage_edit.tile_brush_selection.buf{
								//flip and rotate the tile position
								tileCursorPosf := vec2_cardinal_rotate(Vec2(tileCursorBasePos + grid_index_to_pos(stage_edit.tile_brush_selection, i)), stage_edit.tile_brush_rotation, rotationOrigin)
								tileCursorPosf -= rotationOrigin
								if stage_edit.tile_brush_flip.x do tileCursorPosf.x = -tileCursorPosf.x
								if stage_edit.tile_brush_flip.y do tileCursorPosf.y = -tileCursorPosf.y
								tileCursorPosf += rotationOrigin
								
								tileCursorPos := Vec2i(tileCursorPosf)

								partRect := tileset_tile_rect(ts, int(brushIndex))
								
								flip := i32(stage_edit.tile_brush_flip.x) + i32(stage_edit.tile_brush_flip.y)*2
								angle := f32(stage_edit.tile_brush_rotation*90) + ((flip == 3) ? 180 : 0)
								sprite_draw_part_ex(
									ts.sprite,
									Rect{Vec2(tileCursorPos)*tileSize, partRect.size},
									partRect,
									0, sdl2.RendererFlip(flip%3), angle, COLOR_WHITE, 0.5, .blend, partRect.size/2
								)
							}
						}

						if(Vec2(stage_edit.tile_widget_tex.size) != ts.sprite.size){
							tex_resize(&stage_edit.tile_widget_tex, ts.sprite.size)
						}
						tex_target_set(stage_edit.tile_widget_tex)
						sprite_draw(ts.sprite, 0, 0)
						for brushIndex in stage_edit.tile_brush_selection.buf{
							draw_rect(tileset_tile_rect(ts, int(brushIndex)), COLOR_BLUE, 0.5)
						}
						tex_target_reset()
					}
			}
		}

		_testbed_draw()
		
		tex_target_clear()

		srcRect := sdl2.Rect{0, 0, i32(f32(DISPLAY_WIDTH)/stage_edit.zoom), i32(f32(DISPLAY_HEIGHT)/stage_edit.zoom)}
		sdl2.RenderCopy(display._renderer, texBuffer_active_tex(stage_edit.draw_textures), &srcRect, nil)

		sizeFactor := f32(settings.window_scale)*stage_edit.zoom

		camPos := round(stage_camera_pos())
		if(stage_edit.grid_visible){
			tileSize := Vec2(stage_edit.grid_tile_size)
			gridOffset := Vec2(stage_edit.grid_offset)
			if stage_edit.grid_camera_relative do gridOffset += stage_camera_pos()
			if contents, ok := stage_edit.cursor_contents.(^StageLayer); ok {
				if variant, ok2 := contents.variant.(StageLayerTiles); ok2 && variant.tileset != nil{
					tileSize = Vec2(variant.tileset.tileSize)
				}
			}

			tileSize *= sizeFactor

			startPos := -(camPos-gridOffset)*sizeFactor/tileSize
			_,startPos.x = split(startPos.x)
			_,startPos.y = split(startPos.y)
			startPos -= {1,1}
			startPos *= tileSize
			endPos := startPos + window_size() + tileSize*2

			draw_color(COLOR_BLACK)
			for x:=startPos.x;x<endPos.x;x+=tileSize.x{
				draw_line(x, startPos.y, x, endPos.y)
			}
			for y:=startPos.y;y<endPos.y;y+=tileSize.y{
				draw_line(startPos.x, y, endPos.x, y)
			}


		}

		for &selectRect in selectRects{
			selectRect.pos = (selectRect.pos - camPos)*sizeFactor
			selectRect.size *= sizeFactor
			nineslice_draw(sp.selectionBox, selectRect)
		}

		if(stage_edit.multiselect_mode != .none){
			multiSelectRect := rect_make_points(stage_edit.multiselect_start_pos, stage_edit.cursor_coords)
			multiSelectRect.pos = (multiSelectRect.pos - camPos)*sizeFactor
			multiSelectRect.size *= sizeFactor
			draw_rect(multiSelectRect, COLOR_BLUE, 0.3)
		}
	}
	else{
		camera_reset()
	}
}