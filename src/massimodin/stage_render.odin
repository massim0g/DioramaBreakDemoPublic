#+feature using-stmt
package massimodin //@nested-tags:stages

import "core:reflect"
import "../sdl3"

DropShadow :: struct{
	shape:union{Ellipse, Rect},
	angle:f32,
	alpha:f32
}

_stage_render :: proc(){ //records the stage's draws, layered through the renderer's depth spans
	tracy_auto_trace = false
	defer tracy_auto_trace = true

	if stage_edit.enabled do tex_target_set(stage_edit.draw_tex, stage_camera_pos(), false)
	else do camera_set(stage.camera_pos)

	draw_clear(stage.backgroundColor)

	if !stage_edit.enabled{
		shader_set(Sh_Stage{
			stageRect = transmute([4]f32)(stage.bounds),
			shadowBlend = blend_to_f(stage.shadowBlend),
			lightBlend = blend_to_f(stage.lightBlend),
			timeStopSaturation = combat.time_stop_saturation,
		})
		shader_texture_bind("shadowMap", stage.shadow_map)
	}

	//ENTITIES

	//stage entity draws
	camRect := stage_camera_rect()
	camRect.size += {1,1} //the world tex has a pixel of overdraw for the smooth camera
	stageEntities := coall(StageEntity)
	{
		trace("Stage Entity Cull and Shadows")

		//culling and shadows
		clear(&stage.drop_shadows)
		tex_target_set(stage.shadow_map, stage.bounds.pos, true)
		shader_set(Sh_ColorOnly)
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
	
			switch shadowKind{
				case .none: //do nothing
				case .isShadow, .isLight:
					if invertShadowMargin > 0{
						shader_set(Sh_Base)
						drawRect := stageEntity_draw_rect(&ent)
						texSize := Vec2i(drawRect.size)
						if invertShadowTex.size != texSize do tex_resize(&invertShadowTex, texSize)
						spriteOrigin := spriter_origin(spriter)
						tex_target_set(invertShadowTex, clear=false)
							draw_clear()
							center := drawRect.size/2
							originAdjusted := -spriteOrigin + drawRect.size
							edgeEllipse := Ellipse{radii=drawRect.size}
							blendmode_set(.subtract)
							for a:f32=0;a<360;a+=360/8{
								edgePoint := ellipse_edge_point(edgeEllipse, a)
								sprite_draw_ex(spriter.mySprite, originAdjusted + vec2_normalize(edgePoint)*(vec2_mag_get(edgePoint)-invertShadowMargin), spriter.lastFrame)
							}
							blendmode_set(.blend)
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

		//composite the shadow layer over the floor
		render_depth_layer(.stageBG, -102)
		destination := display_snapshot()
		shader_set(Sh_ShadowLayer{
			shadowBlend = blend_to_f(stage.shadowBlend),
			lightBlend = blend_to_f(stage.lightBlend),
		})
		shader_texture_bind("destination", destination)
		tex_draw_ex(stage.shadow_layer, stage_camera_pos())
		shader_reset()
	}

	/*
	Timestop desaturation: redraw the screen so far (the floor bands) through the stage shader with the effect on, then leave timeStopEffect set so everything drawn in front desaturates per draw.
	Param edits apply to the stage shader in replay order, so the effect covers exactly the depth range between this span and wherever combat_shader_set(false) lands.
	*/
	if combat.time_stop_mode == .enabledWithEffect{
		render_depth_layer(.stageBG, -103)
		combat_shader_set(true)
		display_redraw()
	}

	_stageEntities_bulk_draw()

	//entity RenderComponent draws, each at its own depth
	entitiesDraw :: proc(ev:Event, depthOffset:f32){
		for componentType in entities.component_type_event_register[ev]{
			metadata := &entities.component_type_metadata[componentType]
			arr := metadata.get_array_pointer()
			process := metadata.process
			basePtr := uintptr(arr.data)
			size := uintptr(reflect.size_of_typeid(metadata.type))
			arrLen := uintptr(arr.len)

			for ptr:=basePtr; ptr<basePtr+size*arrLen; ptr+=size{
				renderPtr := cast(^RenderComponentBase)ptr
				if renderPtr.visible{
					render_depth(renderPtr.depth + depthOffset)
					process(cast(^ComponentBase)ptr, ev)
				}
			}
		}
	}
	entitiesDraw(.draw, 0)

	//PARTICLES
	for depth, group in particles._groups{
		render_depth(depth)
		if depth <= layer_depth(.ui) do camera_set(0)
		particles_draw(group.particles[:])
		if depth <= layer_depth(.ui) do camera_reset()
	}

	//LAYERS
	layerTilesDraw :: proc(tileset:^Tileset, pos:Vec2, tileData:[]TileLayerTile, w:int, blendData:BlendData){
		tileSize := cast([2]i32)tileset.tileSize
		gridW := tileset.sprite.size.x/f32(tileSize.x)

		sprite := tileset.sprite
		frame := sprite.frames[sprite_frame_get(sprite)]
		tPage := frame.texturePage
		tPagePos := frame.texturePagePos.pos
		drawPos := round(pos)
		srcRect := Rect{{0, 0}, {f32(tileSize.x), f32(tileSize.y)}}
		dstRect := srcRect

		areaW := i32(w) //in tiles
		areaH := i32(len(tileData)/w)

		tileBlend := color_to_blend(blendData.color, blendData.alpha)
		tileSampler := spriteFrame_sampler(&frame)
		blendmode_set(blendData.blendmode)

		i := 0
		for y in 0..<areaH{
			for x in 0..<areaW{
				tile := tileData[i]
				if(tile.ind != 0){
					tileInd := i32(tile.ind-1)

					srcRect.x = tPagePos.x + f32((tileInd%i32(gridW))*tileSize.x)
					srcRect.y = tPagePos.y + f32(i32(floor(f32(tileInd)/gridW))*tileSize.y)
					dstRect.x = drawPos.x + f32(tileSize.x*x)
					dstRect.y = drawPos.y + f32(tileSize.y*y)

					flipMode := sdl3.FlipMode(tile.flip%3)
					flags:QuadFlags
					if flipMode == .HORIZONTAL do flags += {.flipX}
					if flipMode == .VERTICAL do flags += {.flipY}

					render_quad(tPage.texture, tileSampler, Quad{
						worldRect = dstRect,
						uvRect = texture_page_uv(tPage, srcRect),
						rotation = angle_to_rads(f32(tile.angle) + ((tile.flip == 3) ? 180 : 0)),
						pivot = dstRect.size/2,
						blend = tileBlend,
						flags = flags,
					})
				}
				i+=1
			}
		}
		blendmode_set(.blend)
	}

	for &layer in stage.layers{
		if !layer.visible do continue
		switch variant in layer.variant{
			case StageLayerImage:
				if(variant.sprite == nil) do continue
				offset:=layer.offset
				depth:f32
				switch layer.depthKind{
					case .floor: depth = layer_depth(.stageBG)+layer.z
					case .foreground:
						depth = layer_depth(.stageFG)+layer.z
					case .wall:
						depth = -offset.y
						offset.y += ceil(layer.z)
				}
				render_depth(depth)
				blendmode_set(layer.blendData.blendmode)
				sprite_draw_ex(variant.sprite, offset + stage.camera_pos*variant.parallax, color=layer.blendData.color, alpha=layer.blendData.alpha)
				blendmode_set(.blend)
			case StageLayerTiles:
				tileset := variant.tileset
				if(tileset == nil) do continue
				drawPos := Vec2(variant.tilePos)*Vec2(tileset.tileSize) + layer.offset
				if(layer.depthKind == .wall){
					drawPos.y += ceil(layer.z)
					gridH := f32(tileset.tileSize.y)
					depth := -drawPos.y-gridH
					for i in 0..<variant.tileData.h{
						render_depth(depth)
						layerTilesDraw(tileset, drawPos, grid_slice_row(variant.tileData, i), variant.tileData.w, layer.blendData)
						drawPos.y += gridH
						depth -= gridH
					}
				}
				else{
					render_depth(layer.z + (layer.depthKind == .foreground ? layer_depth(.stageFG) + 1 : layer_depth(.stageBG) - 1))
					layerTilesDraw(tileset, drawPos, variant.tileData.buf[:], variant.tileData.w, layer.blendData)
				}
			case StageLayerTint:
				gradientRect := stage.bounds
				clampGradient := false
				depth:f32
				switch layer.depthKind{
					case .foreground: depth = layer_depth(.stageFG)+layer.z
					case .floor: depth = layer_depth(.stageBG)+layer.z
					case .wall:
						depth = -layer.offset.y
						rect_set_bottom(&gradientRect, layer.offset.y + layer.z, true)
						clampGradient = true
				}
				render_depth(depth)
				tp := Sh_StageTint{
					viewRect = transmute([4]f32)(stage_camera_rect()),
					viewportSize = stage_edit.enabled ? DISPLAY_SIZE/stage_edit.zoom : DISPLAY_SIZE,
					tintMode = i32(variant.tintData.tintMode),
					gradientRect = transmute([4]f32)(gradientRect),
					clampGradient = i32(clampGradient),
				}
				for b,c in variant.tintData.tint do tp.colors[c] = blend_to_f(b)
				shader_set(tp)
				display_redraw()
				shader_reset()
			case StageLayerShader:
				if variant.shader != nil && layer.z > variant.resetZ{
					baseDepth:f32
					switch layer.depthKind{
						case .floor: baseDepth = layer_depth(.stageBG)
						case .foreground: baseDepth = layer_depth(.stageFG)
						case .wall: baseDepth = 0
					}

					//the shader applies to the whole depth range between the set and the reset, via the renderer's sorted state flow
					render_depth(layer.z + baseDepth)
					shader_set(variant.shader._renderParams)
					switch variant.shader.name{
						case "shimmer": shader_params_set(Sh_Shimmer{f32(time.frame)})
						case "wavy": shader_params_set(Sh_Wavy{f32(time.frame)})
					}
					render_depth(variant.resetZ + baseDepth)
					shader_reset()
				}
		}
	}

	//UI
	#partial switch combat.phase{ case .planning, .resolving:
		render_depth_layer(.stageBG, -104)
		_combat_grid_draw()
		render_depth_layer(.stageTop, 1)
		_combat_action_target_silhouettes_draw()

		if combat.phase == .planning do _combat_aim_indicators_draw()
	}

	//STAGE EDITOR
	if(stage_edit.enabled){
		if(stage_edit.cursor_contents != nil){
			#partial switch contents in stage_edit.cursor_contents{
				case ^EntityPrefab:
					render_depth(-stage_edit.cursor_coords.y)
					sprite_draw_ex(contents.previewSprite, stage_edit.cursor_coords.pos, color=COLOR_WHITE, alpha=0.5)
				case ^Sprite:
					render_depth(-stage_edit.cursor_coords.y)
					sprite_draw_ex(contents, stage_edit.cursor_coords.pos, color=COLOR_WHITE, alpha=0.5)
				case ^Mesh:
					render_depth_layer(.stageTop, 1)
					{
							meshPtr := stage_edit.cursor_contents.(^Mesh)
							mesh := meshPtr^
							
							edgeColor := meshPtr == &stage.collisionMesh ? Color{246, 170, 8} : COLOR_GREEN
							vertexColor := Color{131, 36, 180}

							newEdge, drawingNewEdge := stage_edit.mesh_edit_content.(^[2]u16)
							_, draggingVertex := stage_edit.mesh_edit_content.(^Vec2)
							noSelection := !draggingVertex && !drawingNewEdge

							nearestPoint, nearestPointEdgeInd, nearestVertexInd := mesh_nearest_point(mesh, stage_edit.cursor_coords.pos)

							draw_rect(stage_camera_rect(), COLOR_BLACK, 0.5)
							edgeCount := len(mesh.edges)
							if edgeCount > 0{
								edges := drawingNewEdge ? mesh.edges[:edgeCount-1] : mesh.edges[:]
								for edge in edges{
									draw_line(mesh_edge_to_line(mesh, edge), color=edgeColor)
								}
	
								if drawingNewEdge{
									draw_line(mesh.vertices[newEdge[0]], stage_edit.cursor_coords.pos, color=edgeColor, alpha=0.5)
								}
							}
							
							for vertex, i in mesh.vertices{
								draw_circle(vertex, STAGE_EDIT_MESH_HOVER_RANGE/2, vertexColor)
							}

							if noSelection{
								if key_mods_held({.CTRL}){ 
									if nearestVertexInd != -1 && vec2_distance(mesh.vertices[nearestVertexInd], stage_edit.cursor_coords.pos) < STAGE_EDIT_MESH_HOVER_RANGE{
										draw_circle(mesh.vertices[nearestVertexInd], STAGE_EDIT_MESH_HOVER_RANGE, edgeColor, 0.5)
									}
									else{ 
										draw_circle(stage_edit.cursor_coords.pos, STAGE_EDIT_MESH_HOVER_RANGE/2, vertexColor, 0.5)
									}
								}
								else{ 
									if nearestVertexInd == -1{
										draw_circle(stage_edit.cursor_coords.pos, STAGE_EDIT_MESH_HOVER_RANGE/2, vertexColor, 0.5)
									}
									else{
										nearestVert := &mesh.vertices[nearestVertexInd]
										if vec2_distance(nearestVert^, stage_edit.cursor_coords.pos) < STAGE_EDIT_MESH_HOVER_RANGE{
											draw_circle(nearestVert^, STAGE_EDIT_MESH_HOVER_RANGE)
										}
										else if nearestPointEdgeInd != -1 && vec2_distance(nearestPoint, stage_edit.cursor_coords.pos) < STAGE_EDIT_MESH_HOVER_RANGE{
											draw_circle(nearestPoint, STAGE_EDIT_MESH_HOVER_RANGE/2, vertexColor, 0.5)
										}
										else{
											newPos := stage_edit.cursor_coords.pos
											if key_mods_held({.SHIFT}) && !stage_edit.grid_entity_snap do newPos = vec2_snap_to_angle(newPos, nearestVert^)
											draw_line(nearestVert^, newPos, color=edgeColor, alpha=0.5)
											draw_circle(newPos, STAGE_EDIT_MESH_HOVER_RANGE/2, vertexColor, 0.5)
										}
									}
								}
							}
					}
			}
		}

		depthWidgetDraw :: proc(top:Vec2, bottom:Vec2){
			draw_line(top, bottom, color=COLOR_GREEN, alpha=0.5)
			draw_circle(bottom, 2, COLOR_GREEN, 0.5)
		}

		if stage_edit.reference_tex.ptr != nil{
			render_depth_layer(.stageBG, 1)
			tex_draw_ex(stage_edit.reference_tex, Vec2(stage_edit.reference_offset), color=color_lerp(stage.backgroundColor, COLOR_WHITE, 0.5))
		}

		//stage bounds
		render_depth_layer(.stageTop, -1)
		draw_rect_outline(stage.bounds, 2, COLOR_WHITE, 0.5)

		//depth widgets
		if layer, ok := stage_edit.cursor_contents.(^StageLayer); ok && layer.z < 0 && layer.depthKind == .wall{
			if variant, ok2 := layer.variant.(StageLayerImage); ok2{
				offset := layer.offset
				parallaxAddend := stage.camera_pos*variant.parallax
				render_depth(-offset.y+0.1)
				depthWidgetDraw(Vec2{offset.x, offset.y + ceil(layer.z)} + parallaxAddend, offset + parallaxAddend)
			}
		}

		if entRef,ok := stage_edit.cursor_contents.(CoRefEx(StageEntity)); ok{
			ent := coget(entRef)
			if ent.transform.z < 0{
				render_depth(ent.depth+0.1)
				depthWidgetDraw(stageEntity_draw_pos(ent), ent.transform.pos)
			}
		}

		//entity extra draws
		entitiesDraw(.drawEditor, -0.01)

		//top-level UI
		render_depth_ui(.stageEditor)

		_colliders_debug_draw()

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
									0, sdl3.FlipMode(flip%3), angle, COLOR_WHITE, 0.5, partRect.size/2
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

		//the editor view is a zoomed crop of its own buffer, blown up to fill the whole target
		editTex := stage_edit.draw_tex
		zoomUV := (DISPLAY_SIZE/stage_edit.zoom)/Vec2(editTex.size)
		render_quad(editTex.ptr, tex_sampler(editTex), Quad{
			worldRect = {size = window_size()},
			uvRect = {0, 0, zoomUV.x, zoomUV.y},
			blend = BLEND_WHITE,
		})

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

			for x:=startPos.x;x<endPos.x;x+=tileSize.x{
				draw_line(x, startPos.y, x, endPos.y, color=COLOR_BLACK)
			}
			for y:=startPos.y;y<endPos.y;y+=tileSize.y{
				draw_line(startPos.x, y, endPos.x, y, color=COLOR_BLACK)
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
	else{ //reset stage draw settings
		render_depth_layer(.stageTop)
		shader_reset()
		camera_reset()
		_colliders_debug_draw()
	} 

}