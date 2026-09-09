#+feature using-stmt
package massimodin //@nested-tags:stages

import "../sdl3"
import "core:reflect"
import "core:encoding/json"
import "core:strings"
import "core:mem"
import "core:mem/virtual"
import "core:path/filepath"
import "core:os"
import "../imgui"
import "../tinyfd"
import "../tracy"

StageSystem :: struct{
	_stages_map:map[string]Stage,
	names:[dynamic]string,
	using loaded:^Stage,
	started:bool,
	_goto:^Stage, //stage to be loaded at the end of the frame

	file_tree:^FileTreeFolder, //used for asset browsing in debug mode

	allocator:Allocator, //freed on stage end
	
	camera_pos:Vec2, //rounded stage camera position
	camera_pos_subpixel:Vec2, //fractional remainder of the camera position, applied as a shift when blitting to the window
	target_camera_pos:Vec2,
	debugEntitiesVisible:bool,
	shadow_map:Tex,
	shadow_layer:Tex,
	drop_shadows:[dynamic]DropShadow,

	combatBounds:Rect,

	loadingComponentData:^json.Object,
	savingComponentsBuilder:^strings.Builder,

	_preParseAllocator:Allocator,
	_preParseTempAllocator:Allocator,
	preParseDone:bool,

	using undoables:^struct{
		requiredTextureGroups:[dynamic]string,
		layers:[dynamic]StageLayer,
		bounds:Rect,
		backgroundColor:Color,
		indoors:bool,
		collisionMesh:Mesh,
		shadowBlend:Blend,
		lightBlend:Blend,
		//tintEnabled:bool,
		//tint:[4]Blend,
		randomSeed:int,
		defaultFootstepSurface:FootstepSurface,
		footstepSurfaceOverrides:[dynamic]FootstepSurfaceOverride
	}
}
stage:^StageSystem

StageEditSystem :: struct{
	enabled:bool,
	cursor_coords:TransformCoords,
	drag_offset:Vec2,
	multiselect_start_pos:Vec2,
	multiselect_mode:enum{
		none,
		tiles,
		entities
	},
	precise_select:bool,
	select_start_pos:Vec2,
	select_in_deadzone:bool,
	select_resizing_mode:StageEditResizingMode,
	zoom:f32,
	grid_tile_size:Vec2i,
	grid_offset:Vec2i,
	grid_entity_snap:bool,
	grid_camera_relative:bool,
	grid_visible:bool,
	shadows_selectable:bool,

	asset_selector_filter:imgui.TextFilter,
	asset_selector_selected_folder:^FileTreeFolder,

	sprite_entities_spawn_with_collision:bool,
	sprite_entities_spawn_group:Estring,

	tile_brush_selection:Grid(int),
	tile_brush_rotation:int,
	tile_brush_flip:[2]bool,
	tile_widget_tex:Tex,

	reference_tex:Tex,
	reference_offset:Vec2i,
	//reference_alpha:f32,

	collision_mesh_nearest_vertex_ind:int,
	mesh_edit_content:union{
		^Mesh,
		^Vec2, //vertex
		^[2]u16 //line
	},

	draw_tex:TexBuffered,

	using undoables:^struct{
		cursor_contents:union{
			^Sprite,
			CoRefEx(StageEntity),
			[]CoRefEx(StageEntity),
			^StageLayer,
			^EntityPrefab,
			^Mesh,
			^StageEntity //for entity-specific editor widgets
		},
		multiselect_bounds:Rect,
		multiselection_last:[dynamic]CoRefEx(StageEntity),
		entity_defaults:map[CoRefExGeneric][]string //save defaults to check against when saving to prevent wasting unneeded space on unedited fields
	},
	entity_clipboard:strings.Builder,
	undoAllocator:Allocator,
	undoStack:[dynamic][2]ArenaSnapshot,
	redoStack:[dynamic][2]ArenaSnapshot,
	last_save_undo_stack_size:int,
	undoFlag:UndoFlag,
	mouse_drag_edit_dirty:bool,

	gui_suggestions_completed:bool
}
stage_edit:^StageEditSystem

_stage_system_init :: proc(){
	stage = new(StageSystem, os_allocator)
	st = new(StageIDs, assets.allocator)

	stage.allocator = allocator_make(mem.Megabyte*128, .Static)
	stage._preParseAllocator = allocator_make()
	stage._preParseTempAllocator = allocator_make()
	stage.undoables = new(type_of(stage.undoables^))

	init(&stage._stages_map, assets.allocator)
	init(&stage.names, assets.allocator)
	init(&stage.layers)
	init(&stage.collisionMesh.vertices)
	init(&stage.collisionMesh.edges)
	init(&stage.footstepSurfaceOverrides)
	init(&stage.requiredTextureGroups)
	stage.shadow_map = tex_make(DISPLAY_SIZE)
	stage.shadow_layer = tex_make(DISPLAY_SIZE + {1,1}) //covers the world tex's overdraw pixel
	init(&stage.drop_shadows)

	stage.bounds = Rect{0, DISPLAY_SIZE}
	stage.combatBounds = stage.bounds
	stage.randomSeed = -1

	when(DEBUG){
		stage.file_tree = file_tree_folder_new("stages")
		_stage_edit_init()
	}
	else{
		stage_edit = new(StageEditSystem, os_allocator)
	}
}

_stage_edit_init :: proc(){
	stage_edit = new(StageEditSystem, os_allocator)

	init(&stage_edit.tile_brush_selection, 0, 0, os_allocator)

	imgui.TextFilter_Build(&stage_edit.asset_selector_filter)
	stage_edit.draw_tex = texBuffered_make(4096)
	stage_edit.tile_widget_tex = tex_make(1,1)
	stage_edit.grid_tile_size = {16, 16}
	stage_edit.grid_offset = {0,0}
	stage_edit.zoom = 1
	stage_edit.grid_visible = true
	stage_edit.precise_select = true
	stage_edit.undoables = new(type_of(stage_edit.undoables^))
	strings.builder_init(&stage_edit.entity_clipboard)
	init(&stage_edit.multiselection_last)
	init(&stage_edit.entity_defaults)

	stage_edit.undoAllocator = allocator_make()
	init(&stage_edit.undoStack, stage_edit.undoAllocator)
	init(&stage_edit.redoStack, stage_edit.undoAllocator)

	//stage_edit.enabled = true //for testing
}

StageLayerImage :: struct{
	sprite:^Sprite,
	parallax:Vec2,
}

StageLayerTiles :: struct{
	tileset:^Tileset,
	tilePos:Vec2i,
	tileData:Grid(TileLayerTile),
}

StageLayerShader :: struct{
	shader:^Shader,
	resetZ:f32
}

TintMode :: enum{
	overlay,
	screen,
	blend
}
TintData :: struct{
	tint:[4]Blend,
	tintMode:TintMode
}

StageLayerTint :: struct{
	using tintData:TintData,
	multicolor:bool
}

TileLayerTile :: struct{
	angle:f64,
	flip:i32,
	ind:u16
}

StageLayerType :: union{
	StageLayerImage,
	StageLayerTiles,
	StageLayerTint,
	StageLayerShader
}

StageLayerDepthKind :: enum{
	floor, //will render below all entities
	wall, //will render alongside entities
	foreground //will render above all entities 
}

StageLayer :: struct{
	name:string,
	offset:Vec2,
	depthKind:StageLayerDepthKind,
	z:f32,
	visible:bool,
	blendData:BlendData,
	variant:StageLayerType
}

UndoFlag :: enum{
	none,
	undoPush,
	undo,
	redo
}

//-1 to 1
StageEditResizingMode :: [2]i8 

Stage :: struct{
	name:string,
	init:proc(),
	initEditor:proc(),
	update:proc(),
	onCombatStart:proc(),
	data:json.Object,
	rawData:[]u8
}

STAGE_EDIT_ASSET_SELECTOR_ID:cstring: "stage_edit_asset_selector"

//In screen coordinates
STAGE_EDIT_DRAG_DEADZONE :f32: 8 
STAGE_EDIT_MESH_HOVER_RANGE :: 6

//compress a tile layer tile to be stored in a json
tile_layer_tile_compress :: proc(tile: TileLayerTile) -> f64 {
	//note: f64 can only store integers up to 53 bits safely
	indBits :: 10
	flipBits :: 2
	angleBits :: 2
    indMask :: (1 << indBits) - 1
    flipMask  :: (1 << flipBits) - 1
    angleMask :: (1 << angleBits) - 1

	angleIndex := u64(-round(tile.angle/90))

    bits: u64 = u64(tile.ind) & indMask
    bits |= (u64(tile.flip) & flipMask) << indBits
	bits |= (angleIndex & angleMask) << (indBits + flipBits)

    return f64(bits)
}

tile_layer_tile_uncompress :: proc(val: f64) -> TileLayerTile {
	indBits :: 10
	flipBits :: 2
	angleBits :: 2
    indMask :: (1 << indBits) - 1
    flipMask  :: (1 << flipBits) - 1
    angleMask :: (1 << angleBits) - 1

    bits := u64(val)

    return TileLayerTile{ 
		-f64(u64((bits >> (indBits + flipBits)) & angleMask)*90),
		i32((bits >> indBits) & flipMask), 
		u16(bits & indMask)
	}
}

mouse_stage_pos :: proc() -> Vec2{
	if input_device() == .gamepad do return -1
	
	when(DEBUG){
		if(stage_edit.enabled){
			out := Vec2(input._mouse_window_position)
			out = out/(f32(settings.window_scale)*stage_edit.zoom) + stage_camera_pos()
			return out
		}
	}

	return mouse_display_pos() + stage.camera_pos
}

stage_entity_at_mouse :: proc(precise:=false) -> ^StageEntity{
	out:^StageEntity
	// cursorEntity:^StageEntity
	// if(stage_edit.enabled){
	// 	if cursorEntityRef, ok := stage_edit.cursor_contents.(CoRefEx(StageEntity)); ok{
	// 		cursorEntity = coget(cursorEntityRef)
	// 	}
	// }
	mousePos := mouse_stage_pos()
	outDepth :f32= -1
	//if out != nil do outDepth = (out.depth == nil) ? -out.transform.y : out.depth.(f32)
	for &stageEntity in coall(StageEntity){
		entDepth := (stageEntity.depthKind == .precise) ? -stageEntity.transform.y + stageEntity.editableDepthOffset : stageEntity.depth
		spr := stageEntity.spriter.mySprite
		drawRect := sprite_draw_rect(stageEntity.spriter.mySprite, stageEntity_draw_pos(&stageEntity), 0, stageEntity.transform.scale)
		if(
			(stage_edit.shadows_selectable ? equals(stageEntity.shadowKind, StageEntityShadowKind.isShadow, StageEntityShadowKind.isLight) : stageEntity.visible) && 
			(out == nil || outDepth > entDepth) &&
			rect_contains(drawRect, mousePos)
		){
			frame := spr.frames[0]
			if precise && abs(stageEntity.transform.scale) == {1,1} && frame.texturePage.surface!=nil{
				tpp := frame.texturePagePos
				relativePos := Vec2i(mousePos - drawRect.pos)
				if stageEntity.transform.scale.x < 0 do relativePos.x = int(drawRect.size.x) - relativePos.x
				if stageEntity.transform.scale.y < 0 do relativePos.y = int(drawRect.size.y) - relativePos.y
				relativePos += Vec2i{int(tpp.x), int(tpp.y)}
				if !surface_pixel_filled(frame.texturePage.surface, relativePos.x, relativePos.y) do continue
			}
			out = &stageEntity
			outDepth = entDepth
			//if out == cursorEntity do return out
		}
	}
	return out
}

stage_edit_entities_in_rect :: proc(rect:Rect, precise:=false, allocator:=context.temp_allocator) -> (entities:[]^StageEntity, bounds:Rect){
	out := make([dynamic]^StageEntity, allocator)
	checkProc := precise ? rect_contains_rect_f : rectfs_overlap
	for &stageEntity in coall(StageEntity){
		if(!stageEntity.visible) do continue
		entityRect := sprite_draw_rect(stageEntity.spriter.mySprite, stageEntity_draw_pos(&stageEntity), 0, stageEntity.transform.scale)
		if(checkProc(rect, entityRect)){
			append(&out, &stageEntity)

			if(len(out) == 1) do bounds = entityRect
			else{
				rect_set_left(&bounds, min(entityRect.x, bounds.x), true)
				rect_set_top(&bounds, min(entityRect.y, bounds.y), true)
				rect_set_right(&bounds, max(rect_get_right(entityRect), rect_get_right(bounds)), true)
				rect_set_bottom(&bounds, max(rect_get_bottom(entityRect), rect_get_bottom(bounds)), true)
			}
		}
	}
	entities = out[:]
	return
}

//accounts for stage editing
stage_camera_pos :: #force_inline proc "contextless" () -> Vec2{
	when(DEBUG){
		if stage_edit.enabled{
			zoomFactor := (f32(1)/stage_edit.zoom - 1)/2
			return stage.camera_pos - zoomFactor*DISPLAY_SIZE
		}
	}
	
	return stage.camera_pos
}
stage_camera_rect :: proc() -> Rect{
	return Rect{stage_camera_pos(), DISPLAY_SIZE/(DEBUG?stage_edit.zoom:1)}
}

stage_edit_snap_pos_to_grid :: proc(p:Vec2) -> Vec2{
	off := Vec2(stage_edit.grid_offset)
	if stage_edit.grid_camera_relative do off += round(stage_camera_pos())
	tileSize := Vec2(stage_edit.grid_tile_size)
	return round((p-off)/tileSize)*tileSize + off
}

_stage_edit_undo_resolve :: proc(){
	switch stage_edit.undoFlag{
		case .none: //do nothing
		case .undoPush:
			for &snaps in stage_edit.redoStack{
				for &snap in snaps{
					arena_snapshot_free(&snap)
				}
			}
			clear(&stage_edit.redoStack)
			append(&stage_edit.undoStack, [2]ArenaSnapshot{
				arena_snapshot(default_allocator, stage_edit.undoAllocator),
				arena_snapshot(stage.allocator, stage_edit.undoAllocator)
			})
		case .undo:
			if(len(stage_edit.undoStack) > 1){
				append(&stage_edit.redoStack, pop(&stage_edit.undoStack))

				snaps := peek(stage_edit.undoStack)
				for snap in snaps{
					arena_snapshot_load(snap)
				}

				_entities_event_process(.editorUndo)
			}
		case .redo:
			if(len(stage_edit.redoStack) > 0){
				snaps := pop(&stage_edit.redoStack)

				for snap in snaps{
					arena_snapshot_load(snap)
				}

				append(&stage_edit.undoStack, snaps)

				_entities_event_process(.editorRedo)
			}
	}

	stage_edit.undoFlag = .none
}

stage_edit_undo_push :: proc(){
	stage_edit.undoFlag = .undoPush
	
}

stage_edit_undo :: proc(){
	stage_edit.undoFlag = .undo
	
}
stage_edit_redo :: proc(){
	stage_edit.undoFlag = .redo
}

stage_layer_depth :: proc(layer:StageLayer) -> f32{
	switch variant in layer.variant{
		case StageLayerImage, StageLayerTint, StageLayerShader:
			baseDepth:f32
			switch layer.depthKind{
				case .floor: baseDepth = layer_depth(.stageBG)
				case .foreground: baseDepth = layer_depth(.stageFG)
				case .wall: baseDepth = -layer.offset.y
			}
			return layer.z + baseDepth
		case StageLayerTiles:
			tileSize := (variant.tileset != nil) ? variant.tileset.tileSize : Vec2i{} 
			drawPos := Vec2(variant.tilePos)*Vec2(tileSize) + layer.offset
			if(layer.depthKind == .wall){ //returns highest depth
				drawPos.y += ceil(layer.z)
				return -drawPos.y + f32(tileSize.y*(variant.tileData.h-2))
			}
			else{
				return layer.z + (layer.depthKind == .foreground ? layer_depth(.stageFG) : layer_depth(.stageBG))
			}
	}
	unreachable()
}

_stage_edit_asset_selector_open :: proc(id:cstring){
	imgui.TextFilter_Clear(&stage_edit.asset_selector_filter)
	stage_edit.asset_selector_selected_folder = nil
	imgui.OpenPopup(id)
}
_stage_edit_asset_selector_update :: proc($assetType:typeid, popupId:cstring="") -> (asset:assetType,selected:bool){
	buttonSize := Vec2{64, 64}*imgui_system.scale
	windowSize:Vec2

	popup := popupId != ""

	if(popup){
		windowSize = Vec2{729, 405}*imgui_system.scale
		imgui.SetNextWindowSize(windowSize)
	}
	else do windowSize = imgui.GetWindowSize()

	if(!popup || imgui.BeginPopup(popupId)){
		if imgui.Button("Set Nil"){
			imgui.CloseCurrentPopup()
			selected = true
		}
		imgui.SameLine()

		imgui.TextFilter_Draw(&stage_edit.asset_selector_filter, "Search##")
		windowLeft := imgui.GetWindowPos().x
		windowRight := windowLeft + windowSize.x
		itemSpacing := imgui.GetStyle().ItemSpacing.x

		when(assetType == ^Sprite){
			if stage_edit.asset_selector_selected_folder == nil || stage_edit.asset_selector_selected_folder.root != sprites.file_tree do stage_edit.asset_selector_selected_folder = sprites.file_tree

			if !imgui.TextFilter_IsActive(&stage_edit.asset_selector_filter){
				if stage_edit.asset_selector_selected_folder.parent != nil{
					imgui.SameLine()
					if imgui.Button("Folder Up"){
						stage_edit.asset_selector_selected_folder = stage_edit.asset_selector_selected_folder.parent
					}
				}
				for node in stage_edit.asset_selector_selected_folder.contents{
					imgui.BeginGroup()
					cName:cstring
					#partial switch n in node{
						case ^FileTreeFolder:
							cName = string_to_cstring(n.name, context.temp_allocator)
							if imgui_sprite(sp.folderIcon, cName, buttonSize){
								stage_edit.asset_selector_selected_folder = n
							}
						case ^Sprite:
							cName = string_to_cstring(n.name, context.temp_allocator)
							if(imgui_sprite(n, cName, buttonSize)){
								imgui.CloseCurrentPopup()
								asset = n
							}
						case: panicf("Invalid asset type '%v' in sprite file tree!", n)
					}
					buttonRight := imgui.GetItemRectMax().x
					imgui.PushTextWrapPos(buttonRight-windowLeft)
					imgui.Text(cName)
					imgui.PopTextWrapPos()
					imgui.EndGroup()
					if(buttonRight + itemSpacing*2 + buttonSize.x < windowRight) do imgui.SameLine()
				}
			}
			else{

				for name in sprites.names{
					cName := string_to_cstring(name, context.temp_allocator)
					if(imgui.TextFilter_PassFilter(&stage_edit.asset_selector_filter, cName)){
						sprite := &sprites._sprites_map[name]
						imgui.BeginGroup()
							if(imgui_sprite(sprite, cName, buttonSize)){
								imgui.CloseCurrentPopup()
								asset = sprite
							}
							buttonRight := imgui.GetItemRectMax().x
							imgui.PushTextWrapPos(buttonRight-windowLeft)
							imgui.Text(cName)
							imgui.PopTextWrapPos()
						imgui.EndGroup()
						if(buttonRight + itemSpacing*2 + buttonSize.x < windowRight) do imgui.SameLine()
					}
				}
			}
		}
		else when(assetType == ^Tileset){
			for name in tilesets.names{
				cName := string_to_cstring(name, context.temp_allocator)
				if(imgui.TextFilter_PassFilter(&stage_edit.asset_selector_filter, cName)){
					tileset := &tilesets._tilesets_map[name]
					imgui.BeginGroup()
						if(imgui_sprite(tileset.sprite, cName, buttonSize)){
							imgui.CloseCurrentPopup()
							asset = tileset
						}
						buttonRight := imgui.GetItemRectMax().x
						imgui.PushTextWrapPos(buttonRight-windowLeft)
						imgui.Text(cName)
						imgui.PopTextWrapPos()
					imgui.EndGroup()
					if(buttonRight + itemSpacing*2 + buttonSize.x < windowRight) do imgui.SameLine()
				}
			}
		}
		else when(assetType == ^Stage){
			stages_preparse_block()
			
			buttonSize = {230, 20}*imgui_system.scale

			if stage_edit.asset_selector_selected_folder == nil || stage_edit.asset_selector_selected_folder.root != stage.file_tree do stage_edit.asset_selector_selected_folder = stage.file_tree

			if !imgui.TextFilter_IsActive(&stage_edit.asset_selector_filter){
				if stage_edit.asset_selector_selected_folder.parent != nil{
					imgui.SameLine()
					if imgui.Button("Folder Up"){
						stage_edit.asset_selector_selected_folder = stage_edit.asset_selector_selected_folder.parent
					}
				}
				for node in stage_edit.asset_selector_selected_folder.contents{
					imgui.BeginGroup()
					#partial switch n in node{
						case ^FileTreeFolder:
							cName := cformat("[FOLDER] %s", n.name)
							if imgui.Button(cName, buttonSize){
								stage_edit.asset_selector_selected_folder = n
							}
						case ^Stage:
							cName := string_to_cstring(n.name, context.temp_allocator)
							if(imgui.Button(cName, buttonSize)){
								imgui.CloseCurrentPopup()
								asset = n
							}
						case: panicf("Invalid asset type '%v' in sprite file tree!", n)
					}
					buttonRight := imgui.GetItemRectMax().x
					imgui.EndGroup()
					if(buttonRight + itemSpacing*2 + buttonSize.x < windowRight) do imgui.SameLine()
				}
			}
			else{
				for name in stage.names{
					cName := string_to_cstring(name, context.temp_allocator)
					if(imgui.TextFilter_PassFilter(&stage_edit.asset_selector_filter, cName) && name != "nilStage"){
						selectedStage := &stage._stages_map[name]
						imgui.BeginGroup()
							if(imgui.Button(cName, buttonSize)){
								imgui.CloseCurrentPopup()
								asset = selectedStage
							}
							buttonRight := imgui.GetItemRectMax().x
						imgui.EndGroup()
						if(buttonRight + itemSpacing*2 + buttonSize.x < windowRight) do imgui.SameLine()
					}
				}
			}
		}
		else when(assetType == ^Dialogue){
			buttonSize = {230, 20}*imgui_system.scale
			for name in dialogue.names{
				cName := string_to_cstring(name, context.temp_allocator)
				if(imgui.TextFilter_PassFilter(&stage_edit.asset_selector_filter, cName)){
					selectedDialogue := &dialogue._dialogues_map[name]
					imgui.BeginGroup()
						if(imgui.Button(cName, buttonSize)){
							imgui.CloseCurrentPopup()
							asset = selectedDialogue
						}
						buttonRight := imgui.GetItemRectMax().x
					imgui.EndGroup()
					if(buttonRight + itemSpacing*2 + buttonSize.x < windowRight) do imgui.SameLine()
				}
			}
		}
		else when(assetType == ^Shader){
			buttonSize = {230, 20}*imgui_system.scale
			for &shader in render._shaders_array{
				cName := string_to_cstring(shader.name, context.temp_allocator)
				if(imgui.TextFilter_PassFilter(&stage_edit.asset_selector_filter, cName)){
					selectedShader := &shader
					imgui.BeginGroup()
						if(imgui.Button(cName, buttonSize)){
							imgui.CloseCurrentPopup()
							asset = selectedShader
						}
						buttonRight := imgui.GetItemRectMax().x
					imgui.EndGroup()
					if(buttonRight + itemSpacing*2 + buttonSize.x < windowRight) do imgui.SameLine()
				}
			}
		}
		else when(assetType == ^Item){
			buttonSize = {230, 20}*imgui_system.scale
			for name in items.data{
				cName := string_to_cstring(name, context.temp_allocator)
				if(imgui.TextFilter_PassFilter(&stage_edit.asset_selector_filter, cName)){
					selectedItem := &items.data[name]
					imgui.BeginGroup()
						if(imgui.Button(cName, buttonSize)){
							imgui.CloseCurrentPopup()
							asset = selectedItem
						}
						buttonRight := imgui.GetItemRectMax().x
					imgui.EndGroup()
					if(buttonRight + itemSpacing*2 + buttonSize.x < windowRight) do imgui.SameLine()
				}
			}
		}
		else when(assetType == ^EntityPrefab){
			for &prefab in entities.prefabs{
				cName := string_to_cstring(prefab.name, context.temp_allocator)
				if(imgui.TextFilter_PassFilter(&stage_edit.asset_selector_filter, cName)){
					imgui.BeginGroup()
						if(imgui_sprite(prefab.previewSprite, cName, buttonSize)){
							imgui.CloseCurrentPopup()
							asset = &prefab
						}
						buttonRight := imgui.GetItemRectMax().x
						imgui.PushTextWrapPos(buttonRight-windowLeft)
						imgui.Text(cName)
						imgui.PopTextWrapPos()
					imgui.EndGroup()
					if(buttonRight + itemSpacing*2 + buttonSize.x < windowRight) do imgui.SameLine()
				}
			}
		}
		else when(assetType == CoID){
			buttonSize = {230, 20}*imgui_system.scale
			validIDs :: [?]CoID{
				.fader,
				.combatEntity
			}
			names := reflect.enum_field_names(CoID)
			for coid in validIDs{
				name := names[coid]
				cName := string_to_cstring(name, context.temp_allocator)
				if(imgui.TextFilter_PassFilter(&stage_edit.asset_selector_filter, cName)){
					imgui.BeginGroup()
						if(imgui.Button(cName, buttonSize)){
							imgui.CloseCurrentPopup()
							asset = coid
						}
						buttonRight := imgui.GetItemRectMax().x
					imgui.EndGroup()
					if(buttonRight + itemSpacing*2 + buttonSize.x < windowRight) do imgui.SameLine()
				}
			}
		}
		else do assertf(false, "Unknown Asset Selector Type %v!", typeid_of(assetType))

		if(popup) do imgui.EndPopup()
	}

	when assetType == ^Shader{
		if selected == false do selected = asset != nil
	}
	else{
		if selected == false do selected = asset != nil
	}

	if selected{
		if popup do imgui.TextFilter_Clear(&stage_edit.asset_selector_filter)
		stage_edit_undo_push()
	}
	return
}


stage_edit_gui_field_uip :: proc(type:^reflect.Type_Info, name:string, valPtr:uintptr, undoPush:=stage_edit_undo_push) -> bool{
	using reflect
	fieldLabel := imgui_label(string_prettify(name, true))

	pushUndo := false
	defer if pushUndo do undoPush()

	switch type.id{ //special cases
		case BlendData:
			if imgui.TreeNode(fieldLabel){
				v := cast(^BlendData)valPtr
				blend := [4]f32{
					f32(v.color.r)/255,
					f32(v.color.g)/255,
					f32(v.color.b)/255,
					v.alpha,
				}
				imgui.PushItemWidth(112*imgui_system.scale)
				imgui.ColorPicker4(imgui_label(), &blend)
				v.color = {
					u8(blend.r*255),
					u8(blend.g*255),
					u8(blend.b*255)
				}
				v.alpha = blend.a
				pushUndo = imgui.IsItemDeactivatedAfterEdit()
				imgui.PopItemWidth()
				stage_edit_gui_field(type_info_of(BlendMode), "blendmode", uintptr(&v.blendmode))
				imgui.TreePop()
			}
			return pushUndo
		case Estring:
			buf := strings.builder_make_len_cap(0, COMPONENT_EDITABLE_STRING_MAX_SIZE, context.temp_allocator)
			stringPtr := cast(^Estring)valPtr
			strings.write_string(&buf, stringPtr.s)
			cString := strings.to_cstring(&buf)
			imgui.InputText(fieldLabel, cString, COMPONENT_EDITABLE_STRING_MAX_SIZE)
			if imgui.IsItemDeactivatedAfterEdit(){
				estring_delete(stringPtr)
				stringPtr.s = strings.clone_from_cstring(cString)
				stringPtr.allocator = context.allocator
				pushUndo = true
			}
			return pushUndo
		case ^Shader:
			shaderPtr := cast(^^Shader)valPtr
			shader := shaderPtr^
			if(imgui.Button(imgui_label((shader == nil) ? "nil" : shader.name))){
				_stage_edit_asset_selector_open(fieldLabel)
			}
			if shader,pushUndo = _stage_edit_asset_selector_update(^Shader, fieldLabel); pushUndo do shaderPtr^ = shader
			return pushUndo
	}

	variant := type.variant
	if v, ok := type.variant.(Type_Info_Named); ok{
		variant = v.base.variant
	}

	floatFormat :: "%.2f"

	switch ti in variant{
		case Type_Info_Integer: 
			imgui.PushItemWidth(96*imgui_system.scale)
			intPtr := cast(^int)valPtr
			cVal := i32(intPtr^)
			imgui.InputInt(fieldLabel, &cVal, 1, 8)
			intPtr^ = int(cVal)
			pushUndo = imgui.IsItemDeactivatedAfterEdit()
			imgui.PopItemWidth()
		case Type_Info_Float:  
			imgui.PushItemWidth(96*imgui_system.scale)
			imgui.InputFloat(fieldLabel, cast(^f32)valPtr, 1, 8, floatFormat)
			pushUndo = imgui.IsItemDeactivatedAfterEdit()
			imgui.PopItemWidth()
		case Type_Info_String:
			buf := strings.builder_make_len_cap(0, COMPONENT_EDITABLE_STRING_MAX_SIZE, context.temp_allocator)
			stringPtr := cast(^string)valPtr
			strVal := stringPtr^
			strings.write_string(&buf, strVal)
			cString := strings.to_cstring(&buf)
			imgui.InputText(fieldLabel, cString, COMPONENT_EDITABLE_STRING_MAX_SIZE)
			if imgui.IsItemDeactivatedAfterEdit(){
				delete(strVal)
				stringPtr^ = strings.clone_from_cstring(cString)
				pushUndo = true
			}
		case Type_Info_Boolean:
			if imgui.Checkbox(fieldLabel, cast(^bool)valPtr) do pushUndo = true

		case Type_Info_Struct:
			if imgui.TreeNode(fieldLabel){
				fields := struct_fields_zipped(type.id)
				for field in fields{
					stage_edit_gui_field(field.type, field.name, valPtr + field.offset)
				}
				imgui.TreePop()
			}

		case Type_Info_Array:
			if(type.id == Vec2){
				imgui.PushItemWidth(96*imgui_system.scale)

				floatPtr := cast(^[2]f32)valPtr
				imgui.InputFloat(imgui_label(), &floatPtr[0], 1, 8, floatFormat)
				pushUndo ||= imgui.IsItemDeactivatedAfterEdit()
				imgui.SameLine()
				imgui.InputFloat(imgui_label(), &floatPtr[1], 1, 8, floatFormat)
				pushUndo ||= imgui.IsItemDeactivatedAfterEdit()
				imgui.SameLine()
				imgui.Text(string_to_cstring(string_prettify(name, true)))
				imgui.PopItemWidth()
				break
			}
			else if(type.id == Vec2i){
				imgui.PushItemWidth(96*imgui_system.scale)

				intPtr := cast(^[2]int)valPtr
				cInt := cast([2]i32)intPtr^

				imgui.InputInt(imgui_label(), &cInt[0], 1, 8)
				pushUndo ||= imgui.IsItemDeactivatedAfterEdit()
				imgui.SameLine()
				imgui.InputInt(imgui_label(), &cInt[1], 1, 8)
				pushUndo ||= imgui.IsItemDeactivatedAfterEdit()
				imgui.SameLine()
				imgui.Text(string_to_cstring(string_prettify(name, true)))
				imgui.PopItemWidth()

				intPtr^ = cast([2]int)cInt
				break
			}
			else if(type.id == Vec3){
				imgui.PushItemWidth(96*imgui_system.scale)
				floatPtr := cast(^[3]f32)valPtr
				imgui.InputFloat(imgui_label(), &floatPtr.x, 1, 8, floatFormat)
				pushUndo ||= imgui.IsItemDeactivatedAfterEdit()
				imgui.SameLine()
				imgui.InputFloat(imgui_label(), &floatPtr.y, 1, 8, floatFormat)
				pushUndo ||= imgui.IsItemDeactivatedAfterEdit()
				imgui.SameLine()
				imgui.InputFloat(imgui_label(), &floatPtr.z, 1, 8, floatFormat)
				pushUndo ||= imgui.IsItemDeactivatedAfterEdit()
				imgui.SameLine()
				imgui.Text(string_to_cstring(string_prettify(name, true)))
				imgui.PopItemWidth()
				break
			}
			else if type.id == Color{
				imgui.PushItemWidth(112*imgui_system.scale)
				colPtr := cast(^Color)valPtr
				cVal := ColorF(colPtr^)
				cVal /= 255
				imgui.ColorPicker3(fieldLabel, &cVal)
				cVal = round(cVal*255)
				colPtr^ = Color(cVal)
				pushUndo = imgui.IsItemDeactivatedAfterEdit()
				imgui.PopItemWidth()
				break
			}
			else if type.id == Blend{
				imgui.PushItemWidth(112*imgui_system.scale)
				blendPtr := cast(^Blend)valPtr
				bVal := BlendF(blendPtr^)
				bVal /= 255
				imgui.ColorPicker4(fieldLabel, &bVal)
				bVal = round(bVal*255)
				blendPtr^ = Blend(bVal)
				pushUndo = imgui.IsItemDeactivatedAfterEdit()
				imgui.PopItemWidth()
				break
			}

			if(imgui.TreeNode(fieldLabel)){
				for i in 0..<ti.count{
					stage_edit_gui_field(ti.elem, format("[%i]", i), valPtr + uintptr(i*ti.elem_size))
				}
				imgui.TreePop()
			}
		
		case Type_Info_Pointer: 
			switch type.id{
				case ^Sprite:
					spritePtr := cast(^^Sprite)valPtr
					sprite := spritePtr^
					if(sprite == nil) do sprite = sp.nil_
					imgui.Text("%s: %s", string_to_cstring(name, context.temp_allocator), string_to_cstring(sprite.name, context.temp_allocator))
					if(imgui_sprite(sprite, fieldLabel, {32, 32})){
						_stage_edit_asset_selector_open(fieldLabel)
					}

					if sprite,pushUndo = _stage_edit_asset_selector_update(^Sprite, fieldLabel); pushUndo do spritePtr^=sprite
				case ^Tileset:
					tilesetPtr := cast(^^Tileset)valPtr
					tileset := tilesetPtr^
					if(tileset == nil) do tileset = tileset_get(sp.nil_)
					imgui.Text("%s: %s", string_to_cstring(name, context.temp_allocator), string_to_cstring(tileset.sprite.name, context.temp_allocator))
					if(imgui_sprite(tileset.sprite, fieldLabel, {32, 32})){
						_stage_edit_asset_selector_open(fieldLabel)
					}

					if tileset,pushUndo = _stage_edit_asset_selector_update(^Tileset, fieldLabel); pushUndo do tilesetPtr^=tileset
				case ^Dialogue:
					dialoguePtr := cast(^^Dialogue)valPtr
					dia := dialoguePtr^
					if(imgui.Button(imgui_label((dia == nil) ? "nil" : dia.name))){
						_stage_edit_asset_selector_open(fieldLabel)
					}
					if dia,pushUndo = _stage_edit_asset_selector_update(^Dialogue, fieldLabel); pushUndo do dialoguePtr^=dia
					imgui.SameLine()
					imgui.Text(string_to_cstring(name, context.temp_allocator))
				case ^Stage:
					stagePtr := cast(^^Stage)valPtr
					stage := stagePtr^
					if(imgui.Button(imgui_label((stage == nil) ? "nil" : stage.name))){
						_stage_edit_asset_selector_open(fieldLabel)
					}
					if stage,pushUndo = _stage_edit_asset_selector_update(^Stage, fieldLabel); pushUndo do stagePtr^=stage
				case ^Item:
					itemPtr := cast(^^Item)valPtr
					item := itemPtr^
					if(imgui.Button(imgui_label((item == nil) ? "nil" : item.id))){
						_stage_edit_asset_selector_open(fieldLabel)
					}
					if item,pushUndo = _stage_edit_asset_selector_update(^Item, fieldLabel); pushUndo do itemPtr^=item
					imgui.SameLine()
					imgui.Text(string_to_cstring(name, context.temp_allocator))
				case:
					imgui.Text("Unimplemented Pointer Type: %s", fieldLabel)
			}
		case Type_Info_Dynamic_Array: imgui.Text("dynamic array type, todo")     
		case Type_Info_Enumerated_Array: imgui.Text("enum array type, todo")      
		case Type_Info_Map: imgui.Text("map type, todo")                
		case Type_Info_Enum:
			vals := reflect.enum_field_values(type.id)
			intPtr := cast(^reflect.Type_Info_Enum_Value)valPtr
			ind, _ := find(vals, intPtr^)
			currentItem := i32(ind)
			comboItems := make([dynamic]byte, context.temp_allocator)
			for enumValName in ti.names{
				append(&comboItems, enumValName)
				append(&comboItems, 0)
			}
			if(imgui.Combo(fieldLabel, &currentItem, cstring(raw_data(comboItems)))){
				intPtr^ = vals[currentItem]
				pushUndo = true
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
		Type_Info_Fixed_Capacity_Dynamic_Array,
		Type_Info_Named:
			imgui.Text("Unimplemented Type: %s", fieldLabel)
	}

	return pushUndo
}
stage_edit_gui_field_ptr :: #force_inline proc(name:string, valPtr:^$T, undoPush:=stage_edit_undo_push) -> bool{
	return stage_edit_gui_field_uip(type_info_of(T), name, uintptr(valPtr), undoPush)
}
stage_edit_gui_field :: proc{stage_edit_gui_field_uip, stage_edit_gui_field_ptr}

stage_edit_gui_text_field_with_suggestions :: proc(name:string, val:^Estring, suggestions:[]string, suggestionsSelectedIndex:^int, undoPush:=stage_edit_undo_push) -> bool{
	pushUndo := false

	buf := strings.builder_make_len_cap(0, COMPONENT_EDITABLE_STRING_MAX_SIZE, context.temp_allocator)
	strings.write_string(&buf, val.s)
	cString := strings.to_cstring(&buf)

	callback :imgui.InputTextCallback: proc "c" (data: ^imgui.InputTextCallbackData) -> i32{
		for flag in imgui.InputTextFlag do if flag in data.EventFlag {
			#partial switch flag{
				case .CallbackCompletion:
					 stage_edit.gui_suggestions_completed = true
					 data.BufDirty = true
			}
		
		}
		return 0
	}

	imgui.InputText(imgui_label(name), cString, COMPONENT_EDITABLE_STRING_MAX_SIZE, {.CallbackCompletion, .CallbackHistory}, callback)
	
	if imgui.IsItemDeactivatedAfterEdit(){
		if stage_edit.gui_suggestions_completed do stage_edit.gui_suggestions_completed = false
		else{
			estring_delete(val)
			val.s = strings.clone_from_cstring(cString)
			val.allocator = context.allocator
			pushUndo = true
		} 
	}

	filteredSuggestions := strings_filter(suggestions, string(cString))
	if imgui.IsItemActive(){
		if len(filteredSuggestions) > 0{
			sort_general(filteredSuggestions)
			imgui_suggestions_selector(filteredSuggestions, suggestionsSelectedIndex)
		}
		if stage_edit.gui_suggestions_completed{
			estring_set(val, filteredSuggestions[suggestionsSelectedIndex^], true)
			pushUndo = true
			imgui.SetKeyboardFocusHere()
			imgui.InvisibleButton("##sink", 1)
		}
	}

	
	if pushUndo{
		suggestionsSelectedIndex^ = 0
		undoPush()
	}
	return pushUndo
}

stage_edit_gui_multifield_uip :: proc(type:^reflect.Type_Info, name:string, valPtrs:[]uintptr, undoPush:=stage_edit_undo_push) -> bool{
	using reflect
	fieldLabel := imgui_label(string_prettify(name, true))

	variant := type.variant
	if v, ok := type.variant.(Type_Info_Named); ok{
		variant = v.base.variant
	}

	//special-case handling for any types that can't just be directly copied bit-by-bit
	#partial switch ti in variant{
		case Type_Info_String:
			pushUndo := false
			buf := strings.builder_make_len_cap(0, COMPONENT_EDITABLE_STRING_MAX_SIZE)
			strVal := (cast(^string)valPtrs[0])^
			alpha :f32=1
			for ptr in valPtrs{
				if (cast(^string)ptr)^ != strVal{
					strVal = ""
					alpha = 0.5
					break
				}
			}

			imgui.PushStyleVar(imgui.StyleVar.Alpha, alpha)
			defer imgui.PopStyleVar()
			strings.write_string(&buf, strVal)
			cString := strings.to_cstring(&buf)
			if(imgui.InputText(fieldLabel, cString, COMPONENT_EDITABLE_STRING_MAX_SIZE, imgui.InputTextFlags{.EnterReturnsTrue})){
				for ptr in valPtrs{
					stringPtr := cast(^string)ptr
					delete(stringPtr^)
					stringPtr^ = strings.clone_from_cstring(cString)
				}
				pushUndo = true
			}
			if pushUndo do undoPush()
			return pushUndo
		case Type_Info_Struct:
			if !equals(type.id, BlendData){
				out:=false
				if(imgui.TreeNode(fieldLabel)){
					fieldPtrs := make([]uintptr, len(valPtrs), context.temp_allocator)
					fields := struct_fields_zipped(type.id)
					for field in fields{
						for ptr,i in valPtrs do fieldPtrs[i] = ptr + field.offset
						out ||= stage_edit_gui_multifield(field.type, field.name, fieldPtrs, undoPush)
					}
					imgui.TreePop()
				}
				return out
			}
		case Type_Info_Array:
			if(!equals(type.id, Vec2, Vec2i, Color, Blend)){
				out:=false
				if(imgui.TreeNode(fieldLabel)){
					elemPtrs := make([]uintptr, len(valPtrs), context.temp_allocator)
					for i in 0..<ti.count{
						elemOff := uintptr(i*ti.elem_size)
						for ptr,j in valPtrs do elemPtrs[j] = ptr + elemOff
						out ||= stage_edit_gui_multifield(ti.elem, format("[%i]", i), elemPtrs, undoPush)
					}
					imgui.TreePop()
				}
				return out
			}
			
	}

	alpha :f32=1
	editVal := new_typeid(type.id, context.temp_allocator)
	mem.copy(editVal, rawptr(valPtrs[0]), type.size)
	for ptr in valPtrs{
		if mem.compare_ptrs(editVal, rawptr(ptr), type.size) != 0{
			mem.zero(editVal, type.size)
			alpha = 0.5
			break
		}
	}

	imgui.PushStyleVar(imgui.StyleVar.Alpha, alpha)
	defer imgui.PopStyleVar()
	if stage_edit_gui_field(type, name, uintptr(editVal), undoPush){
		for ptr in valPtrs{
			mem.copy(rawptr(ptr), editVal, type.size)
		}
		return true
	}
	return false
	
}
stage_edit_gui_multifield_ptr :: #force_inline proc(name:string, valPtrs:[]^$T, undoPush:=stage_edit_undo_push) -> bool{
	return stage_edit_gui_multifield_uip(type_info_of(T), name, cast([]uintptr)valPtrs, undoPush)
}
//Edit multiple values *of the same type* using one gui field 
stage_edit_gui_multifield :: proc{stage_edit_gui_multifield_ptr, stage_edit_gui_multifield_uip}

stage_edit_gui_group_selector :: proc(editStr:^Estring)->bool{
	out := false
	imgui.PushItemWidth(100*imgui_system.scale)
	previewVal := (editStr.s == "")? "(none)":string_to_cstring(editStr.s, context.temp_allocator)
	if imgui.BeginCombo(imgui_label(), previewVal){
		groupNames := make([dynamic]string, context.temp_allocator)
		append(&groupNames, "(none)")
		ents := coall(StageEntity)
		for &ent in ents{
			if ent.group.s != "" && !contains(groupNames, ent.group.s) do append(&groupNames, ent.group.s)
		}

		for name in groupNames{
			if imgui.Selectable(imgui_label(name), name == editStr.s || (name == "(none)" && editStr.s == "")){
				
				if name == "(none)" do estring_delete(editStr)
				else do estring_set(editStr, name, true)
				out = true
				stage_edit_undo_push()
			}
		}
		imgui.EndCombo()
	}
	imgui.SameLine()
	if stage_edit_gui_field("", editStr){
		out = true
	}
	imgui.PopItemWidth()
	imgui.SameLine()
	imgui.Text("Group")
	return out
}

_stage_edit_tile_editor_update :: proc(layer:^StageLayerTiles, layerOffset:Vec2){
	if(layer.tileset == nil) do return

	tileSize := Vec2(layer.tileset.tileSize)
	tilesetGridSize := tileset_grid_size(layer.tileset)

	if stage_edit.multiselect_mode == .tiles{
		if(!mouse_held(.LEFT)){
			selectRect := rect_make_points(floori((stage_edit.multiselect_start_pos - layerOffset)/tileSize) - layer.tilePos, floori((stage_edit.cursor_coords.pos- layerOffset)/tileSize) - layer.tilePos)
			gridSize := grid_size(layer.tileData)
			selectRect.pos = max(selectRect.pos, Vec2i{0,0})
			selectRect.size = min(gridSize - selectRect.pos, selectRect.size)
			clear(&stage_edit.tile_brush_selection.buf)
			for y:=selectRect.y; y<=rect_get_bottom(selectRect); y+=1{
				for x:=selectRect.x; x<=rect_get_right(selectRect); x+=1{
					tile := grid_get_ptr(layer.tileData, x, y)
					append(&stage_edit.tile_brush_selection.buf, int(tile.ind - 1))
					tile^ = TileLayerTile{}
				}
			}
			stage_edit.tile_brush_selection.w = selectRect.size.x
			stage_edit.tile_brush_selection.h = selectRect.size.y
			stage_edit.multiselect_mode = .none
			stage_edit_undo_push()
		}
		return
	}

	if mouse_pressed(.BUTTON_4) do stage_edit.tile_brush_flip.x = !stage_edit.tile_brush_flip.x
	if mouse_pressed(.BUTTON_5) do stage_edit.tile_brush_flip.y = !stage_edit.tile_brush_flip.y

	if(key_mods_held({.CTRL})){
		if stage_edit.multiselect_mode != .tiles{
			if mouse_pressed(.LEFT){
				stage_edit.multiselect_start_pos = stage_edit.cursor_coords.pos
				stage_edit.multiselect_mode = .tiles
				stage_edit.tile_brush_rotation = 0
				stage_edit.tile_brush_flip = false
				grid_clear(&stage_edit.tile_brush_selection)
				return
			} 
			else do stage_edit.tile_brush_rotation = (stage_edit.tile_brush_rotation-input.mouse_scroll)%4 //brushIndex = (brushIndex + input.mouse_scroll)%tileset_len(layer.tileset)
		}
	}

	if len(stage_edit.tile_brush_selection.buf) == 0 do return

	tileCursorBasePos := floori((stage_edit.cursor_coords.pos - layerOffset)/tileSize)

	rotationOrigin := Vec2(tileCursorBasePos) + (Vec2(grid_size(stage_edit.tile_brush_selection)) - {1,1})/2

	for brushIndex, i in stage_edit.tile_brush_selection.buf{
		//flip and rotate the tile position
		tileCursorPosf := vec2_cardinal_rotate(Vec2(tileCursorBasePos + grid_index_to_pos(stage_edit.tile_brush_selection, i)), stage_edit.tile_brush_rotation, rotationOrigin)
		tileCursorPosf -= rotationOrigin
		if stage_edit.tile_brush_flip.x do tileCursorPosf.x = -tileCursorPosf.x
		if stage_edit.tile_brush_flip.y do tileCursorPosf.y = -tileCursorPosf.y
		tileCursorPosf += rotationOrigin
		
		tileCursorPos := Vec2i(tileCursorPosf)

		if(mouse_held(.LEFT)){
			if(len(layer.tileData.buf) == 0){
				layer.tilePos = tileCursorPos
				grid_resize(&layer.tileData, 0, 0, 1, 1)
			}
			else{
				delta1 := min(tileCursorPos - layer.tilePos, 0)
				delta2 := max(tileCursorPos - (layer.tilePos + {layer.tileData.w-1, layer.tileData.h-1}), 0)
				if(delta1 != delta2){
					grid_resize(&layer.tileData, delta1.x, delta1.y, delta2.x, delta2.y)
					layer.tilePos += delta1
				}
			}
			setPos := Vec2i(tileCursorPos - layer.tilePos)
			setVal := TileLayerTile{
				f64(-stage_edit.tile_brush_rotation*90),
				i32(stage_edit.tile_brush_flip.x) + i32(stage_edit.tile_brush_flip.y)*2,
				u16(brushIndex+1)
			}
			if(grid_get(layer.tileData, setPos).ind != setVal.ind) do stage_edit.mouse_drag_edit_dirty = true
			grid_set(&layer.tileData, setPos, setVal)
		}
		else if(mouse_held(.RIGHT) && len(layer.tileData.buf) > 0){
			setPos := tileCursorPos - layer.tilePos
			if(
				(setPos.x >= 0 && setPos.y >= 0 && setPos.x < layer.tileData.w && setPos.y < layer.tileData.h) &&
				grid_get(layer.tileData, setPos).ind != 0)
			{
				stage_edit.mouse_drag_edit_dirty = true
				grid_set(&layer.tileData, setPos, TileLayerTile{})
	
				xMin:int = layer.tileData.w-1
				yMin:int = layer.tileData.h-1
				xMax:int
				yMax:int
	
				for y in 0..<layer.tileData.h{
					for x in 0..<layer.tileData.w{
						if(grid_get(layer.tileData, x, y).ind != 0){
							xMin = min(x, xMin)
							yMin = min(y, yMin)
							xMax = max(x, xMax)
							yMax = max(y, yMax)
						}
					}
				}
	
				x2Delta := xMax - (layer.tileData.w - 1)
				y2Delta := yMax - (layer.tileData.h - 1)
	
				if(xMin != 0 || yMin != 0 || x2Delta != 0 || y2Delta != 0){
					grid_resize(&layer.tileData, xMin, yMin, x2Delta, y2Delta)
					layer.tilePos += {xMin, yMin}
				}
	
			}
		}
	}

}


_stage_edit_start :: proc(reloadStage:=true){
	for name in sprites.texture_groups_dynamic do texture_group_preload(name) //all sprites need to be available when stage editing
	//defer texture_group_load_block(groupNames=sprites.texture_groups_dynamic[:]) //no need to block when debugging
	if dialogue.current != nil do dialogue_close()
	stage_edit.enabled = true
	if(stage.loaded != nil && reloadStage) do stage_goto(stage.loaded) //reload stage
	stage_edit_undo_push() //base undo
	stage_edit.last_save_undo_stack_size = 1
	stage_edit.sprite_entities_spawn_with_collision = false
	estring_delete(&stage_edit.sprite_entities_spawn_group) 

	tex_resize(&stage.shadow_layer, 4096)
}
_stage_edit_end :: proc(){
	stage_edit.enabled = false
	stage_edit.zoom = 1
	stage_edit.cursor_contents = nil
	stage_edit.last_save_undo_stack_size = 0
	stage_edit.shadows_selectable = false
	clear(&stage_edit.multiselection_last)
	clear(&stage_edit.entity_defaults)

	free_all(stage_edit.undoAllocator)
	reset(&stage_edit.undoStack)
	reset(&stage_edit.redoStack)

	stage_goto(stage.loaded) //reload stage
	tex_resize(&stage.shadow_layer, DISPLAY_SIZE + {1,1})
}
_stage_edit_update :: proc(){
	//ENABLE/DISABLE STAGE EDIT
	if(!stage_edit.enabled){
		if(key_pressed(.F5)){
			_stage_edit_start()
		}
		return
	}
	else{
		if(key_pressed(.F5) && _stage_save()){ //will attempt to save progress and only exit edit mode if save is successful
			mousePos := round(mouse_stage_pos())
			_stage_edit_end()
			proc_call_delayed(callback_make(proc(p:^Vec2){
				player := entity_make(Player)
				player.transform.pos = p^
			}, mousePos), 1)
			return
		}
	}

	//RESOLVE UNDO
	_stage_edit_undo_resolve()

	//SAVE SHORTCUT
	if(key_combo_pressed({.CTRL, .SHIFT}, .S)) do _stage_save(true)
	else if(key_combo_pressed({.CTRL}, .S)) do _stage_save()

	//VIEW SETTINGS
	imgui.Begin("View Settings", nil, {.AlwaysAutoResize})
		imgui.Text("ZOOM x%1.3f", stage_edit.zoom)
		imgui.SameLine()
		buttonSize := Vec2{20,20}*imgui_system.scale
		if(imgui.Button(imgui_label("-"), buttonSize)) do stage_edit.zoom = clamp(stage_edit.zoom-0.125, 0.125, 2)
		imgui.SameLine()
		if(imgui.Button(imgui_label("="), buttonSize)) do stage_edit.zoom = 1
		imgui.SameLine()
		if(imgui.Button(imgui_label("+"), buttonSize)) do stage_edit.zoom = clamp(stage_edit.zoom+0.125, 0.125, 2)
		imgui.SameLine()
		imgui.Text("|")

		//grid
		imgui.SameLine()
		imgui.Text("GRID")

		imgui.SameLine()
		imgui.Text("Size")
		imgui.SameLine()
		tileSize := cast([2]i32)stage_edit.grid_tile_size
		imgui.PushItemWidth(24*imgui_system.scale)
		imgui.InputInt(imgui_label(), &tileSize.x, 0, 0)
		imgui.SameLine()
		imgui.InputInt(imgui_label(), &tileSize.y, 0, 0)
		imgui.SameLine()
		if(imgui.Button(imgui_label("/2"), buttonSize)) do tileSize = cast([2]i32)max(Vec2(tileSize)/2, Vec2{1,1})
		imgui.SameLine()
		if(imgui.Button(imgui_label("x2"), buttonSize)) do tileSize = min(tileSize*2, [2]i32{65536, 65536})
		imgui.SameLine()
		if(imgui.Button(imgui_label("Cam"), Vec2{30,20}*imgui_system.scale)){
			tileSize = cast([2]i32)(DISPLAY_SIZE/2)
			stage_edit.grid_camera_relative = true
		}
		stage_edit.grid_tile_size = Vec2i(tileSize)

		imgui.SameLine()
		imgui.Text("Offset")
		imgui.SameLine()
		gridOffset := cast([2]i32)stage_edit.grid_offset
		imgui.InputInt(imgui_label(), &gridOffset.x, 0, 0)
		imgui.SameLine()
		imgui.InputInt(imgui_label(), &gridOffset.y, 0, 0)
		stage_edit.grid_offset = Vec2i(gridOffset)

		imgui.SameLine()
		imgui.Text("Snap")
		imgui.SameLine()
		imgui.Checkbox(imgui_label(), &stage_edit.grid_entity_snap)
		imgui.SameLine()
		imgui.Text("Visible")
		imgui.SameLine()
		imgui.Checkbox(imgui_label(), &stage_edit.grid_visible)
		imgui.SameLine()
		imgui.Text("Camera-Relative")
		imgui.SameLine()
		imgui.Checkbox(imgui_label(), &stage_edit.grid_camera_relative)
		imgui.SameLine()
		imgui.Text("|")
		imgui.SameLine()
		imgui.Text("Precise Select")
		imgui.SameLine()
		imgui.Checkbox(imgui_label(), &stage_edit.precise_select)
		imgui.SameLine()
		imgui.Text("|")
		imgui.SameLine()
		imgui.Text("Edit Collision")
		imgui.SameLine()
		editingCollision := false 
		if m,ok := stage_edit.cursor_contents.(^Mesh); ok && m == &stage.collisionMesh do editingCollision = true
		if imgui.Checkbox(imgui_label(), &editingCollision){
			stage_edit.cursor_contents = editingCollision ? &stage.collisionMesh : nil
			stage_edit_undo_push()
		}
		imgui.SameLine()
		imgui.Text("|")
		imgui.SameLine()
		imgui.Text("Edit Shadows")
		imgui.SameLine()
		imgui.Checkbox(imgui_label(), &stage_edit.shadows_selectable)

	imgui.End()
	
	//GET CAMERA/MOUSE POS
	mouseStagePos := mouse_stage_pos()
	camCenterPos := stage.camera_pos - DISPLAY_SIZE*((1/stage_edit.zoom - 1)/2) + DISPLAY_SIZE*(1/stage_edit.zoom)/2

	stage_edit.cursor_coords.pos = mouseStagePos

	//INPUT VARS
	guiIO := imgui.GetIO()
	captureMouse := guiIO.WantCaptureMouse
	captureKeyboard := guiIO.WantTextInput
	allowZoomInput := !captureMouse
	selectedEntities:[]^StageEntity

	//SWITCH ON CURSOR CONTENT
	entityInspector :: proc(selectedEntity:^StageEntity){
		imgui.Begin("Inspector", nil, {.AlwaysAutoResize})
		imgui.PushItemWidth(280*imgui_system.scale)
		stage_edit_gui_field("Entity Unique ID", &selectedEntity.uniqueID)
		stage_edit_gui_group_selector(&selectedEntity.group)
		imgui.PopItemWidth()
		for component in selectedEntity.entity.components{
			if(component == nil) do continue

			metadata := &entities.component_type_metadata[component.coID]
			if(len(metadata.editableFields) == 0) do continue

			if(imgui.CollapsingHeader(string_to_cstring(metadata.name, context.temp_allocator))){
				coPtr := uintptr(component)
				component_event_process(component, .editing)
				if component.editableFieldsVisible{
					for field in metadata.editableFields{
						if stage_edit_gui_field(field.type, field.name, coPtr+field.offset) do component_event_process(component, .loaded)
					}
				}
			}
			
		}
		if imgui.Button("Add Component") do _stage_edit_asset_selector_open("components")
		selectedComponent,_ := _stage_edit_asset_selector_update(CoID, "components")
		if selectedComponent != .none{
			coadd(selectedEntity.entity, selectedComponent)
		}
		imgui.End()
	}

	if _,ok:=stage_edit.cursor_contents.(^Mesh); !ok do stage_edit.mesh_edit_content = nil
	
	if(stage_edit.cursor_contents != nil){
		switch contents in stage_edit.cursor_contents{
			case ^StageEntity:
				entityInspector(contents)
				//handled by entity-specific event code
			case ^EntityPrefab:
				if(stage_edit.grid_entity_snap) do stage_edit.cursor_coords.pos = stage_edit_snap_pos_to_grid(stage_edit.cursor_coords.pos)

				if captureMouse do break

				if(mouse_pressed(.LEFT)){
					co := entity_make(contents.lastComponent)
					stage_edit_entity_save_defaults(co.entity)
					sEnt, ok := cofind(co, StageEntity)
					sEnt.identifyingComponentIndex = co.myEntityIndex
					assertf(ok, "Attempted to create a stage entity with component '%v' that doesn't depend on StageEntity!", contents.lastComponent)
					sEnt.transform.coords = stage_edit.cursor_coords
					sEnt.transform.coords.pos = round(sEnt.transform.coords.pos)
					spriter_set(sEnt.spriter, contents.previewSprite) //ensure placed entity always has a sprite
					sEnt.depth = -stage_edit.cursor_coords.y
					if contents.onCreateWrapper != nil do contents.onCreateWrapper(co, contents.onCreate)
					stage_edit_undo_push()
				}
				else if(mouse_pressed(.RIGHT)){
					stage_edit.cursor_contents = nil
					stage_edit_undo_push()
				}

			case ^Sprite:
				if stage_edit.grid_entity_snap do stage_edit.cursor_coords.pos = stage_edit_snap_pos_to_grid(stage_edit.cursor_coords.pos)

				if captureMouse do break

				if(mouse_pressed(.LEFT)){
					sInter := entity_make(StageInteractable)
					stage_edit_entity_save_defaults(sInter.entity)
					sEnt := sInter.stageEntity
					sEnt.identifyingComponentIndex = sEnt.spriter.myEntityIndex
					sEnt.transform.coords = stage_edit.cursor_coords
					sEnt.transform.coords.pos = round(sEnt.transform.coords.pos)
					spriter_set(sEnt.spriter, contents)
					if stage_edit.sprite_entities_spawn_with_collision{
						if contents.mask != nil do sInter.maskSprite = contents
						else do sInter.maskNoSpriteSize = {sprite_draw_rect(contents).size.x, 1}
					}
					if stage_edit.sprite_entities_spawn_group.s != ""{
						estring_set(&sEnt.group, stage_edit.sprite_entities_spawn_group.s, true)
					}
					sEnt.depth = -stage_edit.cursor_coords.y
					stage_edit_undo_push()
				}
				else if(mouse_pressed(.RIGHT)){
					stage_edit.cursor_contents = nil
					stage_edit_undo_push()
				}

			case CoRefEx(StageEntity): 
				selectedEntity := coget(contents)

				entityInspector(selectedEntity)

				if(!captureKeyboard){
					if(key_pressed(.DELETE) || key_pressed(.BACKSPACE)){
						entity_destroy(selectedEntity.entity)
						stage_edit.cursor_contents = nil
						stage_edit_undo_push()
						break
					}
				}

				if mouse_pressed(.BUTTON_4) do selectedEntity.transform.scale.x = -selectedEntity.transform.scale.x
				if mouse_pressed(.BUTTON_5) do selectedEntity.transform.scale.y = -selectedEntity.transform.scale.y


				selectedEntities = []^StageEntity{selectedEntity}
			case []CoRefEx(StageEntity):
				if(!captureKeyboard){
					if(key_pressed(.DELETE) || key_pressed(.BACKSPACE)){
						for ref in contents{
							entity_destroy(ref.entityID)
						}
						stage_edit.cursor_contents = nil
						stage_edit_undo_push()
						break
					}
				}

				selectedEntities = make([]^StageEntity, len(contents), context.temp_allocator)
				for e,i in contents{
					selectedEntities[i] = coget(e)
				}

				imgui.Begin("Inspector", nil, {.AlwaysAutoResize})
				newGroup := estring_clone(selectedEntities[0].group, context.temp_allocator)

				multiComponents := make(map[CoID][dynamic]^ComponentBase, context.temp_allocator)
				for selectedEntity in selectedEntities{
					if selectedEntity.group.s != newGroup.s do estring_delete(&newGroup)
					for component in selectedEntity.entity.components{
						if(component == nil) do continue

						coID := component.coID
						if coID not_in multiComponents{
							multiComponents[coID] = make([dynamic]^ComponentBase, context.temp_allocator)
						}

						append(&multiComponents[coID], component)

						// if(imgui.CollapsingHeader(string_to_cstring(metadata.name, context.temp_allocator))){
						// 	coPtr := uintptr(component)
						// 	component_event_process(component, .editing)
						// 	for field in metadata.editableFields{
						// 		if stage_edit_gui_field(field.type, field.name, coPtr+field.offset) do component_event_process(component, .loaded)
						// 	}

						// }
					}
				}

				if stage_edit_gui_group_selector(&newGroup){
					for selectedEntity in selectedEntities{
						estring_set(&selectedEntity.group, newGroup.s, true)
					}
				}

				for coID, components in multiComponents{
					metadata := &entities.component_type_metadata[coID]
					if(len(metadata.editableFields) == 0) do continue

					if(imgui.CollapsingHeader(string_to_cstring(metadata.name, context.temp_allocator))){
						//for component in components do component_event_process(component, .editing)
						for field in metadata.editableFields{
							fieldPtrs := make([]uintptr, len(components), context.temp_allocator)
							for component,i in components do fieldPtrs[i] = uintptr(component) + field.offset
							if stage_edit_gui_multifield(field.type, field.name, fieldPtrs){
								for component in components do component_event_process(component, .loaded)
							}
						}
					}
				}
				imgui.End()

			case ^StageLayer:
				switch &variant in contents.variant{
					case StageLayerImage:
						if(!captureMouse){
							if(mouse_pressed(.LEFT)){
								stage_edit.drag_offset = contents.offset
								stage_edit.drag_offset.y += contents.z
								stage_edit.drag_offset -= stage_edit.cursor_coords
							}
		
							if(mouse_held(.LEFT)){
								lastPos := TransformCoords{contents.offset, contents.z}
								contents.offset.x = stage_edit.cursor_coords.x + stage_edit.drag_offset.x
								if key_mods_held({.ALT}){
									contents.z = stage_edit.cursor_coords.y + stage_edit.drag_offset.y - contents.offset.y
								}
								else do contents.offset.y = stage_edit.cursor_coords.y + stage_edit.drag_offset.y - contents.z
								if(lastPos != TransformCoords{contents.offset, contents.z}) do stage_edit.mouse_drag_edit_dirty = true
							}
						}

					case StageLayerTiles:
						ts := variant.tileset
						if(ts != nil && stage_edit.multiselect_mode == .none){
							tileSize := Vec2(ts.tileSize)
							gridSize := tileset_grid_size(ts)
							
							scale := f32(settings.window_scale)*stage_edit.zoom
							imgui.Begin("Tileset", nil, {.AlwaysAutoResize, .NoMove, .NoTitleBar})
							imgui.SetWindowPos({0,0})

							mousePos := imgui.GetMousePos() - imgui.GetWindowPos() - imgui.GetCursorPos() //mouse pos within tileset widget

							widgetRect := Rect{{}, Vec2(stage_edit.tile_widget_tex.size)}

							if rect_contains(widgetRect, mousePos) {
								if mouse_pressed(.LEFT) do stage_edit.multiselect_start_pos = mousePos

								if mouse_held(.LEFT) {
									grid_clear(&stage_edit.tile_brush_selection)
									selectRect := rect_make_points(floori(stage_edit.multiselect_start_pos/tileSize), floori(mousePos/tileSize))
									for y:=selectRect.y; y<=rect_get_bottom(selectRect); y+=1{
										for x:=selectRect.x; x<=rect_get_right(selectRect); x+=1{
											append(&stage_edit.tile_brush_selection.buf, x + y*gridSize.x)
										}
									}
									stage_edit.tile_brush_selection.w = selectRect.size.x
									stage_edit.tile_brush_selection.h = selectRect.size.y
									//stage_edit.tile_brush_selection_rect = rect_make_points(grid_index_to_pos(gridSize, stage_edit.tile_brush_selection[0]), grid_index_to_pos(gridSize, peek(stage_edit.tile_brush_selection)))
								}
							}

							imgui_tex(stage_edit.tile_widget_tex)


							imgui.End()
						}

						if(!captureMouse || stage_edit.multiselect_mode == .tiles){
							if(key_mods_held({.CTRL})) do allowZoomInput = false
							_stage_edit_tile_editor_update(&variant, contents.offset)
						}
					case StageLayerTint, StageLayerShader:
						//do nothing
				}

				imgui.Begin("Inspector", nil, {.AlwaysAutoResize})
					standardFields :: proc(contents:^StageLayer){
						stage_edit_gui_field("name", &contents.name)
						stage_edit_gui_field("offset", &contents.offset)
						stage_edit_gui_field("depthKind", &contents.depthKind)
						stage_edit_gui_field("z", &contents.z)
						stage_edit_gui_field("blendData", &contents.blendData)
					}
					switch &variant in contents.variant{
						case StageLayerImage:
							standardFields(contents)
							stage_edit_gui_field("sprite", &variant.sprite)
							stage_edit_gui_field("parallax", &variant.parallax)
							
						case StageLayerTiles:
							standardFields(contents)
							stage_edit_gui_field("tileset", &variant.tileset)
						
						case StageLayerTint:
							stage_edit_gui_field("name", &contents.name)
							stage_edit_gui_field("depthKind", &contents.depthKind)
							if contents.depthKind == .wall{
								imgui.SliderFloat(imgui_label("Y"), &contents.offset.y, 0, stage.bounds.size.y, "%.0f")
							}
							stage_edit_gui_field("z", &contents.z)
							stage_edit_gui_field("tint mode", &variant.tintMode)
							stage_edit_gui_field("multicolor", &variant.multicolor)
							if variant.multicolor{
								stage_edit_gui_field("Top-left", &variant.tint[0])
								imgui.SameLine()
								stage_edit_gui_field("Top-right", &variant.tint[1])
								stage_edit_gui_field("Bottom-left", &variant.tint[3])
								imgui.SameLine()
								stage_edit_gui_field("Bottom-right", &variant.tint[2])
							}
							else{
								stage_edit_gui_field("Tint", &variant.tint[0])
								variant.tint = variant.tint[0]
							}
						case StageLayerShader:
							stage_edit_gui_field("name", &contents.name)
							stage_edit_gui_field("depthKind", &contents.depthKind)
							stage_edit_gui_field("z", &contents.z)
							stage_edit_gui_field("resetZ", &variant.resetZ)
							stage_edit_gui_field("shader", &variant.shader)


					}
				imgui.End()
				
				if !captureKeyboard{
					if(key_pressed(.BACKSPACE) || key_pressed(.DELETE)){
						remove_unordered(&stage.layers, mem.ptr_sub(contents, &stage.layers[0])) //WARNING: Allocated fields will not be cleaned up until the room is reloaded
						stage_edit.cursor_contents = nil
						stage_edit_undo_push()
					}
				}
			
			case ^Mesh: //edit stage mesh
				if stage_edit.mesh_edit_content == nil do stage_edit.mesh_edit_content = contents
				switch meshContents in stage_edit.mesh_edit_content{
					case ^Mesh:
						if(stage_edit.grid_entity_snap) do stage_edit.cursor_coords.pos = stage_edit_snap_pos_to_grid(stage_edit.cursor_coords.pos)

						if captureMouse do break

						if mouse_pressed(.LEFT){
							nearestPoint, nearestPointEdgeInd, nearestVertexInd := mesh_nearest_point(contents^, stage_edit.cursor_coords.pos)
							if key_mods_held({.CTRL}){ 
								if nearestVertexInd != -1 && vec2_distance(contents.vertices[nearestVertexInd], stage_edit.cursor_coords.pos) < STAGE_EDIT_MESH_HOVER_RANGE{ //create new edge
									mesh_edge_append(contents, {nearestVertexInd, nearestVertexInd})
									stage_edit.mesh_edit_content = peek_ptr(&contents.edges)
								}
								else{ //create new free-floating vertex
									mesh_vertex_append(contents, stage_edit.cursor_coords.pos)
									stage_edit.mesh_edit_content = peek_ptr(&contents.vertices)
									stage_edit_undo_push()
								}
							}
							else{
								if nearestVertexInd == -1{ //no existing vertices, create free-floating vertex
									mesh_vertex_append(contents, stage_edit.cursor_coords.pos)
									stage_edit.mesh_edit_content = peek_ptr(&contents.vertices)
									stage_edit_undo_push()
								}
								else{
									nearestVert := &contents.vertices[nearestVertexInd]
									if vec2_distance(nearestVert^, stage_edit.cursor_coords.pos) < STAGE_EDIT_MESH_HOVER_RANGE{ //move existing vertex
										stage_edit.mesh_edit_content = nearestVert
									}
									else if nearestPointEdgeInd != -1 && vec2_distance(nearestPoint, stage_edit.cursor_coords.pos) < STAGE_EDIT_MESH_HOVER_RANGE{ //create vertex along existing edge
										mesh_edge_split(contents, nearestPoint, nearestPointEdgeInd)
										stage_edit.mesh_edit_content = peek_ptr(&contents.vertices)
										stage_edit_undo_push()
									}
									else{ //create vertex connected to nearest existing vertex
										if key_mods_held({.SHIFT}) && !stage_edit.grid_entity_snap do stage_edit.cursor_coords.pos = vec2_snap_to_angle(stage_edit.cursor_coords.pos, nearestVert^)
										mesh_vertex_append(contents, stage_edit.cursor_coords.pos)
										mesh_edge_append(contents, {nearestVertexInd, len(contents.vertices)-1})
										stage_edit.mesh_edit_content = peek_ptr(&contents.vertices)
										stage_edit_undo_push()
									}
								}
							}
						}

						if mouse_pressed(.RIGHT){
							nearestPoint, nearestPointEdgeInd, nearestVertexInd := mesh_nearest_point(contents^, stage_edit.cursor_coords.pos)
							if nearestVertexInd != -1{
								nearestVert := &contents.vertices[nearestVertexInd]
								if vec2_distance(nearestVert^, stage_edit.cursor_coords.pos) < STAGE_EDIT_MESH_HOVER_RANGE{ //delete vertex
									mesh_vertex_remove(contents, nearestVertexInd)
									stage_edit_undo_push()
								}
								else if nearestPointEdgeInd != -1 && vec2_distance(nearestPoint, stage_edit.cursor_coords.pos) < STAGE_EDIT_MESH_HOVER_RANGE{ //delete edge
									mesh_edge_remove(contents, nearestPointEdgeInd)
									stage_edit_undo_push()
								}
							}
						}
					case ^Vec2: //move stage mesh vertex
						if(stage_edit.grid_entity_snap) do stage_edit.cursor_coords.pos = stage_edit_snap_pos_to_grid(stage_edit.cursor_coords.pos)
						else if key_mods_held({.SHIFT}){
							origin:Vec2= -INF
							for edge in contents.edges{
								l := mesh_edge_to_line(contents^, edge)
								if l[0] == meshContents^{ origin = l[1]; break}
								if l[1] == meshContents^{ origin = l[0]; break}
							}
							if origin != -INF do stage_edit.cursor_coords.pos = vec2_snap_to_angle(stage_edit.cursor_coords.pos, origin)
						}

						meshContents^ = stage_edit.cursor_coords.pos

						if !mouse_held(.LEFT){
							stage_edit.mesh_edit_content = contents
							stage_edit_undo_push()
						}

					case ^[2]u16: //define new stage mesh edge
						if !mouse_held(.LEFT){
							_, _, nearestVertexInd := mesh_nearest_point(contents^, stage_edit.cursor_coords.pos)
							u16Ind := u16(nearestVertexInd)
							if u16Ind != meshContents[0] && vec2_distance(contents.vertices[nearestVertexInd], stage_edit.cursor_coords.pos) < STAGE_EDIT_MESH_HOVER_RANGE{
								meshContents[1] = u16Ind
								stage_edit_undo_push()
							}
							else do pop(&contents.edges) //remove incomplete edge
							stage_edit.mesh_edit_content = contents
						}
				}
		}
	}

	
	
	//ENTITY EDITING
	if !editingCollision{
		//select and drag entities
		if(!captureMouse || stage_edit.multiselect_mode == .entities){
			if selectedEntities != nil || stage_edit.cursor_contents == nil{
				hoverResizingMode:StageEditResizingMode
				mousePos:Vec2

				//set mouse icon
				if(len(selectedEntities) == 1 && !(mouse_held(.LEFT) && !mouse_pressed(.LEFT))){
					drawRect := stageEntity_draw_rect(selectedEntities[0])
					if(drawRect != Rect{}){
						mousePos = mouse_stage_pos()
						if selectedEntities[0].resizable{
							range :: 3
							bottomRight := rect_get_bottom_right(drawRect)
							inHori := in_range(mousePos.x, drawRect.x-range, bottomRight.x+range)
							inVert := in_range(mousePos.y, drawRect.y-range, bottomRight.y+range)
							hoverResizingMode = {
								i8(in_range(mousePos.x, bottomRight.x-range, bottomRight.x+range) && inVert) - i8(in_range(mousePos.x, drawRect.x-range, drawRect.x+range) && inVert), 
								i8(in_range(mousePos.y, bottomRight.y-range, bottomRight.y+range) && inHori) - i8(in_range(mousePos.y, drawRect.y-range, drawRect.y+range) && inHori)
							}
						}
	
						switch hoverResizingMode{
							case {0,0}: window_system_cursor_set(.DEFAULT)
							case {1,1}, {-1,-1}: window_system_cursor_set(.NWSE_RESIZE)
							case {-1,1}, {1,-1}: window_system_cursor_set(.NESW_RESIZE)
							case {1,0}, {-1,0}: window_system_cursor_set(.EW_RESIZE)
							case {0,1}, {0,-1}: window_system_cursor_set(.NS_RESIZE)
						}
					}
				}
	
				//select
				if(mouse_pressed(.LEFT)){
					stage_edit.select_resizing_mode = {0,0}
					if(key_mods_held({.SHIFT})){
						stage_edit.multiselect_mode = .entities
						stage_edit.multiselect_start_pos = stage_edit.cursor_coords.pos
					}
					else{
						if(hoverResizingMode != {0,0}){
							stage_edit.select_resizing_mode = hoverResizingMode
							stage_edit.select_start_pos = mousePos
						}
						else{
							mousedEntity := stage_entity_at_mouse(stage_edit.precise_select)
							if(mousedEntity != nil){
								if(len(selectedEntities) > 1 && !key_mods_held({.CTRL}) && contains(selectedEntities, mousedEntity)){
									stage_edit.drag_offset = stage_edit.multiselect_bounds.pos
									stage_edit.select_start_pos = stage_edit.multiselect_bounds.pos
									stage_edit.drag_offset -= stage_edit.cursor_coords.pos
								}
								else{
									multiselection:bool
									if key_mods_held({.CTRL}){
										prevSelection := slice_to_array(selectedEntities, context.temp_allocator)
										if ind,ok:=find(selectedEntities, mousedEntity);ok do unordered_remove(&prevSelection, ind)
										else do append(&prevSelection, mousedEntity)
										selectedEntities = prevSelection[:]

										switch len(selectedEntities){
											case 1: mousedEntity = selectedEntities[0]
											case 0: mousedEntity = nil
											case: multiselection = true
										}
									}

									if multiselection{
										clear(&stage_edit.multiselection_last)
										resize(&stage_edit.multiselection_last, len(selectedEntities))
										stage_edit.multiselect_bounds = stageEntities_bounds(selectedEntities)
										for e, i in selectedEntities{
											stage_edit.multiselection_last[i] = crx(e)
										}
										stage_edit.cursor_contents = stage_edit.multiselection_last[:]

										stage_edit.drag_offset = stage_edit.multiselect_bounds.pos
										stage_edit.select_start_pos = stage_edit.multiselect_bounds.pos
										stage_edit.drag_offset -= stage_edit.cursor_coords.pos
										stage_edit_undo_push()
									}
									else if mousedEntity != nil{
										ref := crx(mousedEntity)
										if c,ok := stage_edit.cursor_contents.(CoRefEx(StageEntity)); !ok || c != ref do stage_edit_undo_push()
										stage_edit.cursor_contents = ref
										stage_edit.select_start_pos = mousedEntity.transform.coords
										stage_edit.drag_offset = mousedEntity.transform.coords.pos
										stage_edit.drag_offset.y += mousedEntity.transform.z
										stage_edit.drag_offset -= stage_edit.cursor_coords.pos
										selectedEntities = []^StageEntity{mousedEntity}
									}
									else{
										if stage_edit.cursor_contents != nil do stage_edit_undo_push()
										stage_edit.cursor_contents = nil
										selectedEntities = nil
									}
								}
								stage_edit.select_in_deadzone = true
							}
							else if !key_mods_held({.CTRL}){
								if stage_edit.cursor_contents != nil do stage_edit_undo_push()
								stage_edit.cursor_contents = nil
								selectedEntities = nil
							}
						}
					}
				}
	
				//drag/resize
				if(stage_edit.multiselect_mode == .entities){
					if(!mouse_held(.LEFT)){
						selectArea := rect_make_points(stage_edit.multiselect_start_pos, stage_edit.cursor_coords.pos)
						
						foundEntities, bounds := stage_edit_entities_in_rect(selectArea, stage_edit.precise_select)
						foundCount := len(foundEntities)
	
						if(foundCount == 0){
							if stage_edit.cursor_contents != nil do stage_edit_undo_push()
							stage_edit.cursor_contents = nil
						}
						else{
							clear(&stage_edit.multiselection_last)
							resize(&stage_edit.multiselection_last, foundCount)
							stage_edit.multiselect_bounds = bounds
							for e, i in foundEntities{
								stage_edit.multiselection_last[i] = crx(e)
							}
							stage_edit.cursor_contents = stage_edit.multiselection_last[:]
							stage_edit_undo_push()
						}
						stage_edit.multiselect_mode = .none
					}
				}
				else{
					if(mouse_held(.LEFT) && selectedEntities != nil){
						if(stage_edit.select_resizing_mode == {0,0}){
							newPos := stage_edit.cursor_coords.pos + stage_edit.drag_offset
							lastPos:TransformCoords 
							if (len(selectedEntities) > 1) {
								lastPos = TransformCoords{stage_edit.multiselect_bounds.pos, 0}
							}
							else{
								tr := selectedEntities[0].transform
								lastPos = tr.coords
								newPos.y -= key_mods_held({.ALT}) ? tr.y : tr.z
							}
							
							if!(stage_edit.select_in_deadzone && vec2_distance(newPos, lastPos) <= STAGE_EDIT_DRAG_DEADZONE/(f32(settings.window_scale)*stage_edit.zoom)){
								stage_edit.select_in_deadzone = false
								if(stage_edit.grid_entity_snap) do newPos = stage_edit_snap_pos_to_grid(newPos) 
								else do newPos = round(newPos)

								stage_edit.mouse_drag_edit_dirty = true
								if(len(selectedEntities) > 1){
									stage_edit.multiselect_bounds.pos = newPos
	
									for ent in selectedEntities{
										ent.transform.pos = newPos + (ent.transform.pos - lastPos)
									}
								}
								else{
									ent := selectedEntities[0]
									scaleOff := min(sign(ent.transform.scale), 0)
									ent.transform.pos.x = newPos.x + scaleOff.x
									if key_mods_held({.ALT}) do ent.transform.z = newPos.y
									else do ent.transform.y = newPos.y + scaleOff.y
								}
							}
						}
						else{
							ent := selectedEntities[0]
							newPos := stage_edit.cursor_coords.pos
							if(stage_edit.grid_entity_snap) do newPos = stage_edit_snap_pos_to_grid(newPos) 
							else do newPos = round(newPos)
	
							sprite := ent.spriter.mySprite
							lastScale := ent.transform.scale
	
							z := ent.transform.z
							ent.transform.z = 0
							defer ent.transform.z = z
	
							lastRect := sprite_draw_rect(sprite, stageEntity_draw_pos(ent), 0, ent.transform.scale)
							newRect := lastRect
							bottomRight := rect_get_bottom_right(newRect)
	
							flip := [2]int{int(lastScale.x < 0), int(lastScale.y < 0)}
	
							switch stage_edit.select_resizing_mode.x{
								case -1: 
									if(newPos.x > bottomRight.x){
										newRect.x = bottomRight.x
										rect_set_right(&newRect, newPos.x, true)
										flip.x = int(!bool(flip.x))
										stage_edit.select_resizing_mode.x = -stage_edit.select_resizing_mode.x
									}
									else do rect_set_left(&newRect, newPos.x, true)
								case 1: 
									if(stage_edit.grid_entity_snap) do newPos.x -= 1
									if(newPos.x < newRect.x){
										newRect.x = newPos.x
										rect_set_right(&newRect, lastRect.x, true)
										flip.x = int(!bool(flip.x))
										stage_edit.select_resizing_mode.x = -stage_edit.select_resizing_mode.x
									}
									else do rect_set_right(&newRect, newPos.x, true)
							}
							switch stage_edit.select_resizing_mode.y{
								case -1: 
									if(newPos.y > bottomRight.y){
										newRect.y = bottomRight.y
										rect_set_bottom(&newRect, newPos.y, true)
										flip.y = int(!bool(flip.y))
										stage_edit.select_resizing_mode.y = -stage_edit.select_resizing_mode.y
									}
									else do rect_set_top(&newRect, newPos.y, true)
								case 1: 
									if(stage_edit.grid_entity_snap) do newPos.y -= 1
									if(newPos.y < newRect.y){
										newRect.y = newPos.y
										rect_set_bottom(&newRect, lastRect.y, true)
										flip.y = int(!bool(flip.y))
										stage_edit.select_resizing_mode.y = -stage_edit.select_resizing_mode.y
									}
									else do rect_set_bottom(&newRect, newPos.y, true)
							}
	
							if(lastRect != newRect && flip != {1, 1}){
								stage_edit.mouse_drag_edit_dirty = true
	
								frame := sprite.frames[0]
								size := frame.texturePagePos.size
	
								flipVec := Vec2(flip)
								origin := sprite.origin - frame.trimOffset
								origin += (size - origin*2 - {1,1})*flipVec
	
								newScale := newRect.size/sprite_draw_rect(sprite, Vec2{0,0}).size
								sizeDelta := size*newScale - size
	
								ent.transform.pos = newRect.pos + origin + origin/size*sizeDelta
								ent.transform.scale = newScale*({1,1} - flipVec*2)
							}
						}
					}
				}
				
			}
	
		}
		
		//copy/paste entities
		if(!captureKeyboard){
			b := &stage_edit.entity_clipboard
			if(selectedEntities != nil && key_combo_pressed({.CTRL}, .C)){
				strings.builder_reset(b)
				stage.savingComponentsBuilder = b
				defer stage.savingComponentsBuilder = nil
				strings.write_string(b, "[")
				for ent in selectedEntities{
					stageEntity_serialize_to_builder(b, ent)
				}
				strings.pop_byte(b)
				strings.write_string(b, "]")
			}
	
			if(strings.builder_len(b^) != 0 && key_combo_pressed({.CTRL}, .V)){
				gs := Vec2(stage_edit.grid_tile_size)
	
				jsonArr := json_parse(b.buf[:]).(json.Array)
				newEntityCount := len(jsonArr) 
				newEntities := make([]^StageEntity, newEntityCount, context.temp_allocator)
				
				for ed, i in jsonArr{
					ent := stageEntity_make_from_json(ed.(json.Object))
					stageEntity,_ := cofind(ent, StageEntity)
					stageEntity.transform.pos.x += gs.x
					estring_delete(&stageEntity.uniqueID)
					stageEntity.uniqueID.s = uuid_make_string()
					stageEntity.uniqueID.allocator = context.allocator
					newEntities[i] = stageEntity
				}
	
				if(newEntityCount > 1){
					clear(&stage_edit.multiselection_last)
					resize(&stage_edit.multiselection_last, newEntityCount)
					stage_edit.multiselect_bounds.pos = {99999, 99999}
					for se, i in newEntities{
						stage_edit.multiselection_last[i] = crx(se)
						stage_edit.multiselect_bounds.pos = min(stage_edit.multiselect_bounds.pos, sprite_draw_rect(se.spriter.mySprite, stageEntity_draw_pos(se), 0, se.transform.scale).pos)
					}
					stage_edit.cursor_contents = stage_edit.multiselection_last[:]
				}
				else{
					stage_edit.cursor_contents = crx(newEntities[0])
				}
	
				stage_edit_undo_push()
			 }
		}
	}
	if(stage_edit.mouse_drag_edit_dirty && !mouse_held(.LEFT) && !mouse_held(.RIGHT)){
		stage_edit_undo_push()
		stage_edit.mouse_drag_edit_dirty = false
	}

	//CAMERA CONTROLS
	if(mouse_held(.MIDDLE)){
		stage.target_camera_pos -= mouse_delta()*(1/stage_edit.zoom)
	}
	
	zoomAmount := 0.125*f32(-input.mouse_scroll*int(allowZoomInput))
	stage_edit.zoom = clamp(stage_edit.zoom + zoomAmount, 0.125, 2)
	//stage.camera_pos -= {f32(DISPLAY_WIDTH)*zoomAmount/2, f32(DISPLAY_HEIGHT)*zoomAmount/2} 
	
	//EDITOR UI
	imgui.Begin("Stage Editor")
		imgui.SetWindowSize({600, 600}*imgui_system.scale)
		if(imgui.BeginTabBar("tabs")){
			if(imgui.BeginTabItem("Stage Info")){
				if(imgui.Button("Save")) do _stage_save()
				if(imgui.Button("Save As")) do _stage_save(true)
				if(imgui.Button("Load Stage")) do _stage_edit_asset_selector_open("stages")
				loadStage,_ := _stage_edit_asset_selector_update(^Stage, "stages")
				if(loadStage != nil) do stage_goto(loadStage)

				if(len(stage_edit.undoStack) <= 1) do imgui.BeginDisabled()
				if(imgui.Button("Undo")) do stage_edit_undo()
				if(len(stage_edit.undoStack) <= 1) do imgui.EndDisabled()

				if(len(stage_edit.redoStack) == 0) do imgui.BeginDisabled()
				if(imgui.Button("Redo")) do stage_edit_redo()
				if(len(stage_edit.redoStack) == 0) do imgui.EndDisabled()

				if stage_edit_gui_field("Bounds", &stage.bounds) do stage_edit_undo_push()
				if stage.bounds.size != Vec2(stage.shadow_map.size) do tex_resize(&stage.shadow_map, stage.bounds.size)
				if stage_edit_gui_field("Indoors", &stage.indoors) do stage_edit_undo_push()
				if stage_edit_gui_field("Random Seed", &stage.randomSeed) do stage_edit_undo_push()
				
				if imgui.Button("Load Reference Image") {
					filter :cstring = "*.png"
					referenceImagePath := tinyfd.openFileDialog("Select reference image", "", 1, &filter, nil, 0)
					defer delete(referenceImagePath)
					if referenceImagePath != ""{
						tex_destroy(stage_edit.reference_tex)
						stage_edit.reference_tex = tex_make_from_file(string(referenceImagePath))
						//stage_edit.reference_alpha = 0.5
					}
				}
				stage_edit_gui_field("Reference Offset", &stage_edit.reference_offset, nil_proc)
				//stage_edit_gui_field("Reference Opacity", &stage_edit.reference_alpha, nil_proc)

				imgui.PushItemWidth(imgui.CalcItemWidth() * 0.5)
				imgui.Text("Required Texture Groups")
				for &g,i in stage.requiredTextureGroups{
					stage_edit_gui_field("Group", &g)
					
					imgui.SameLine()
					if imgui.Button(imgui_label("X")){
						delete(g)
						ordered_remove(&stage.requiredTextureGroups, i)
						break
					}
				}
				if imgui.Button(imgui_label("+")) do append(&stage.requiredTextureGroups, "")
				imgui.PopItemWidth()

				imgui.EndTabItem()
			}
			if(imgui.BeginTabItem("New Entity (from prefab)")){
				prefab,_ := _stage_edit_asset_selector_update(^EntityPrefab)
				if(prefab != nil){
					stage_edit.cursor_contents = prefab
					stage_edit_undo_push()
				}
				imgui.EndTabItem()
			}
			if(imgui.BeginTabItem("New Entity (from sprite)")){
				imgui.Checkbox("Spawn with collision", &stage_edit.sprite_entities_spawn_with_collision)
				imgui.SameLine()
				stage_edit_gui_group_selector(&stage_edit.sprite_entities_spawn_group)
				spr,_ := _stage_edit_asset_selector_update(^Sprite)
				if(spr != nil){
					stage_edit.cursor_contents = spr
					stage_edit_undo_push()
				}
				imgui.EndTabItem()
			}
			if imgui.BeginTabItem("Lighting"){
				stage_edit_gui_field("Background Color", &stage.backgroundColor)
				// colorF := ColorF(stage.backgroundColor)/255
				// imgui.ColorPicker3("Background Color", &colorF, {})
				// stage.backgroundColor = Color(colorF*255)
				stage_edit_gui_field("Shadow Blend", &stage.shadowBlend)
				stage_edit_gui_field("Light Blend", &stage.lightBlend)
				imgui.EndTabItem()
			}
			if imgui.BeginTabItem("Audio"){
				imgui.PushItemWidth(imgui.CalcItemWidth() * 0.5)
				stage_edit_gui_field("Default Footstep Surface", &stage.defaultFootstepSurface)
				imgui.Text("Footstep Surface Overrides")
				for &override,i in stage.footstepSurfaceOverrides{
					stage_edit_gui_field("Surface", &override.surface)
					
					imgui.SameLine()
					editingMesh := false 
					if m,ok := stage_edit.cursor_contents.(^Mesh); ok && m == &override.mesh do editingMesh = true
					if imgui.Checkbox(imgui_label("Edit Mesh"), &editingMesh){
						stage_edit.cursor_contents = editingMesh ? &override.mesh : nil
						stage_edit_undo_push()
					}
					
					imgui.SameLine()
					if imgui.Button(imgui_label("Delete")){
						mesh_delete(override.mesh)
						ordered_remove(&stage.footstepSurfaceOverrides, i)
						break
					}
				}
				if imgui.Button("Add Override") do append(&stage.footstepSurfaceOverrides, FootstepSurfaceOverride{.none, mesh_make()})
				imgui.PopItemWidth()
				imgui.EndTabItem()
			}
			imgui.EndTabBar()
		}
	imgui.End()

	imgui.Begin("Depth List", nil, {.AlwaysAutoResize})

		if(imgui.Button("Add Layer")){
			imgui.OpenPopup("new_layer_popup")
		}

		if(imgui.BeginPopup("new_layer_popup")){
			focusNewLayer :: proc(){
				stage_edit.cursor_contents = peek_ptr(&stage.layers)
				stage_edit_undo_push()
				imgui.EndPopup()
				imgui.SetScrollY(imgui.GetScrollMaxY())
			}
			if(imgui.Button("Image")){
				append(&stage.layers, StageLayer{name=string_clone("New Image Layer", stage.allocator), visible=true, variant=StageLayerImage{sprite=sp.nil_}, blendData=BLEND_DATA_DEFAULT})
				focusNewLayer()
			}
			else if(imgui.Button("Tiles")){
				append(&stage.layers, StageLayer{name=string_clone("New Tiles Layer", stage.allocator), visible=true, variant=StageLayerTiles{tileData=grid_make(TileLayerTile, 0, 0, stage.allocator)}, blendData=BLEND_DATA_DEFAULT})
				focusNewLayer()
			}
			else if imgui.Button("Tint"){
				variant := StageLayerTint{}
				variant.tint = {0,0,0,255}
				append(&stage.layers, StageLayer{name=string_clone("New Tint Layer", stage.allocator), visible=true, variant=variant, blendData=BLEND_DATA_DEFAULT})
				focusNewLayer()
			}
			else if imgui.Button("Shader"){
				append(&stage.layers, StageLayer{name=string_clone("New Shader Layer", stage.allocator), visible=true, variant=StageLayerShader{}, blendData=BLEND_DATA_DEFAULT})
				focusNewLayer()
			}
			else do imgui.EndPopup()
		}

		entityGroup :: [dynamic]^StageEntity
		depthEntry :: struct{
			depth:f32,
			variant:union{^StageLayer, ^StageEntity, ^entityGroup}
		}
		depthList := make([dynamic]depthEntry, context.temp_allocator)
		
		for &layer in stage.layers{
			append(&depthList, depthEntry{
				stage_layer_depth(layer),
				&layer
			})
		}

		entityDepth :: proc(ent:^StageEntity)->f32{
			if ent.depthKind != .precise do return ent.depth
			return -ent.transform.y + ent.editableDepthOffset //precise entities don't keep a single depth
		}

		entityGroups := make([dynamic]entityGroup, context.temp_allocator)
		ents := coall(StageEntity)
		for &ent in ents{
			if ent.group.s != ""{
				group:^entityGroup
				for &g in entityGroups{
					if g[0].group == ent.group{
						group = &g
						break
					}
				}

				if group == nil{
					append(&entityGroups, make(entityGroup, context.temp_allocator))
					group = peek_ptr(&entityGroups)
				}
				append(group, &ent)
			}
			else do append(&depthList, depthEntry{entityDepth(&ent), &ent})
		}

		for &group in entityGroups{
			sort_stable(&group, proc(a,b:^StageEntity)->bool{
				return entityDepth(a) < entityDepth(b)
			})

			append(&depthList, depthEntry{
				layer_depth(.stageTop) + entityDepth(group[0]),
				&group
			})
		}

		sort_stable(&depthList, proc(a,b:depthEntry)->bool{
			return a.depth < b.depth
		})

		{
			entityEntry :: proc(v:^StageEntity, selectedEntities:[]^StageEntity){
				imgui.Checkbox(imgui_label(), &v.componentsVisible)
				stageEntity_set_visible(v, v.componentsVisible)
				imgui.SameLine()

				title:string

				identifyingComponentID := v.entity.components[v.identifyingComponentIndex].coID
				if identifyingComponentID == .spriter do title = string_prettify(v.spriter.mySprite.name)
				else do title = string_prettify(format("%v", identifyingComponentID))

				
				if imgui.Selectable(
					imgui_label(format("[ENTITY] (%s)", title)), 
					contains(selectedEntities, v)
				){
					if key_mods_held({.CTRL}){
						mousedEntity := v
						multiselection:bool
						prevSelection := slice_to_array(selectedEntities, context.temp_allocator)
						if ind,ok:=find(selectedEntities, mousedEntity);ok do unordered_remove(&prevSelection, ind)
						else do append(&prevSelection, mousedEntity)
						
						selectedEntities := selectedEntities
						selectedEntities = prevSelection[:]

						switch len(selectedEntities){
							case 1: mousedEntity = selectedEntities[0]
							case 0: mousedEntity = nil
							case: multiselection = true
						}

						if multiselection{
							clear(&stage_edit.multiselection_last)
							resize(&stage_edit.multiselection_last, len(selectedEntities))
							stage_edit.multiselect_bounds = stageEntities_bounds(selectedEntities)
							for e, i in selectedEntities{
								stage_edit.multiselection_last[i] = crx(e)
							}
							stage_edit.cursor_contents = stage_edit.multiselection_last[:]
						}
						else if mousedEntity != nil do stage_edit.cursor_contents = crx(mousedEntity)
						else do stage_edit.cursor_contents = nil
						stage_edit_undo_push()
					}
					else{
						stage_edit.cursor_contents = crx(v)
						stage_edit_undo_push()
					}
				}
				imgui.SameLine()
				imgui_sprite(v.spriter.mySprite, size={16,16})
			}
			context.allocator = context.temp_allocator
			for entry in depthList{
				switch v in entry.variant{
					case ^entityGroup:
						visible:=false
						for ent in v{
							if ent.componentsVisible{
								visible = true
								break
							}
						}

						if imgui.Checkbox(imgui_label(), &visible){
							for ent in v{
								stageEntity_set_visible(ent, visible)
							}
							stage_edit_undo_push()
						}

						imgui.SameLine()

						if imgui.CollapsingHeader(imgui_label(v[0].group.s)){
							imgui.Indent()
							if imgui.Button(imgui_label("Select All")){
								clear(&stage_edit.multiselection_last)
								resize(&stage_edit.multiselection_last, len(v))
								for ent,i in v do stage_edit.multiselection_last[i] = crx(ent)
								stage_edit.cursor_contents = stage_edit.multiselection_last[:]
								stage_edit_undo_push()
							}
							for ent in v{
								entityEntry(ent, selectedEntities)
							}
							imgui.Unindent()
						}

					case ^StageEntity:
						entityEntry(v, selectedEntities)

					case ^StageLayer:
						imgui.Checkbox(imgui_label(), &v.visible)
						imgui.SameLine()

						layerTitle:string
						spriteTitle:string
						switch variant in v.variant{
							case StageLayerImage: 
								if variant.sprite == nil do spriteTitle = "nil"
								else do spriteTitle = string_prettify(variant.sprite.name)
								layerTitle = format("[IMAGE LAYER] (%s) %s", spriteTitle, v.name)
							case StageLayerTiles: 
								if variant.tileset == nil do spriteTitle = "nil"
								else do spriteTitle = string_prettify(variant.tileset.sprite.name)
								layerTitle = format("[TILES LAYER] (%s) %s", spriteTitle, v.name)
							case StageLayerTint: 
								layerTitle = format("[TINT LAYER] %s", v.name)
							case StageLayerShader:
								layerTitle = format("[SHADER LAYER] %s", v.name)
						}
						selectedLayer, selectedIsLayer := stage_edit.cursor_contents.(^StageLayer)
						if imgui.Selectable(imgui_label(layerTitle), selectedIsLayer && selectedLayer == v){
							stage_edit.cursor_contents = v
							stage_edit_undo_push()
						}
				}
			}
		}
		

	imgui.End()

	imgui.Begin("Stage", nil, {.AlwaysAutoResize, .NoMove, .NoCollapse})
		imgui.SetWindowPos(Vec2{window_size().x - imgui.GetWindowSize().x, 0})
		dirty := stage_edit.last_save_undo_stack_size != len(stage_edit.undoStack)
		imgui.TextColored(dirty?{1,1,0,1}:{1,1,1,1}, string_to_cstring(format("%s%s", stage.loaded.name, dirty ? "*" : ""), context.temp_allocator))
	imgui.End()

	imgui.Begin("Helper Coords", nil, {.AlwaysAutoResize, .NoMove, .NoTitleBar})
		imgui.SetWindowPos(Vec2{0, window_size().y - imgui.GetWindowSize().y})
		imgui.Text("Mouse - (%.0f,%.0f), Camera - (%.0f,%.0f)", mouseStagePos.x, mouseStagePos.y, camCenterPos.x, camCenterPos.y)
	imgui.End()

	_entities_event_process(.updateEditor)

	if(stage_edit.undoFlag == .none){
		if(key_combo_pressed({.CTRL}, .Z)) do stage_edit_undo()
		else if(key_combo_pressed({.CTRL}, .Y)) do stage_edit_redo()
	}
}

@(disabled=!DEBUG)
stage_edit_entity_save_defaults :: proc(entity:^Entity){
	if !stage_edit.enabled do return

	for i:=0;i<len(entity.components);i+=1{
		component := entity.components[i]

		if(component == nil){
			if(i<COMPONENTS_MAX_PER_ENTITY){
				i = COMPONENTS_MAX_PER_ENTITY-1
				continue
			}
			else do break
		}

		metadata := entities.component_type_metadata[component.coID]
		
		if len(metadata.editableFields) == 0 do continue
		
		coType := metadata.type

		fieldStrings := make([]string, len(metadata.editableFields), stage.allocator)
		fieldBuilder := strings.builder_make(context.temp_allocator)
		for field,j in metadata.editableFields{
			val := reflect.struct_field_value(component^, field)
			json_marshal_field(&fieldBuilder, val, field.name)
			fieldStrings[j] = clone(strings.to_string(fieldBuilder), stage.allocator)
			strings.builder_reset(&fieldBuilder)
		}

		stage_edit.entity_defaults[crx_generic(component)] = fieldStrings
	}

}

stageEntity_serialize_to_builder :: proc(builder:^strings.Builder, stageEntity:^StageEntity){
	stage.savingComponentsBuilder = builder
	entity := stageEntity.entity

	//entity
	strings.write_string(builder, "{\"id\":\"")
	strings.write_string(builder, stageEntity.uniqueID.s)
	strings.write_string(builder, "\",\"requiredComponents\":[")

	fieldBuilder := strings.builder_make(context.temp_allocator)

	for i:=0;i<len(entity.components);i+=1{
		component := entity.components[i]

		if(i == COMPONENTS_MAX_PER_ENTITY){
			if(entity.requiredComponentCount > 0) do strings.pop_byte(builder)
			strings.write_string(builder, "],\"uniqueComponents\":[")
		}

		if(component == nil){
			if(i<COMPONENTS_MAX_PER_ENTITY){
				i = COMPONENTS_MAX_PER_ENTITY-1
				continue
			}
			else do break
		} 
		
		metadata := entities.component_type_metadata[component.coID]
		coType := metadata.type

		strings.write_string(builder, "{\"name\":\"")
		strings.write_string(builder, metadata.name)
		strings.write_string(builder, "\",")
		defer strings.write_string(builder, "},")

		defaults := stage_edit.entity_defaults[crx_generic(component)]
		for field, j in metadata.editableFields{
			val := reflect.struct_field_value(component^, field)
			if defaults == nil do json_marshal_field(builder, val, field.name)
			else{
				json_marshal_field(&fieldBuilder, val, field.name)
				fieldString := strings.to_string(fieldBuilder)
				if fieldString != defaults[j] do strings.write_string(builder, fieldString)
				strings.builder_reset(&fieldBuilder)
			}
		}
		component_event_process(component, .saving)
		strings.pop_byte(builder)
	}
	if(entity.uniqueComponentCount > 0) do strings.pop_byte(builder)
	strings.write_string(builder, "]},")
}

stageEntity_make_from_json :: proc(entityData:json.Object) -> ^Entity{
	addComponent :: proc(entity:^Entity, name:string, unique:bool){
		coID, ok := coid_from_name(name)
		assertf(ok, "Unknown component name '%s' found when loading stage entity from json!", name)
		coadd(entity, coID, unique, true, -1)
	}
	loadComponent :: proc(newComponent:^ComponentBase){
		metadata := entities.component_type_metadata[newComponent.coID]
		coType := metadata.type

		for field in metadata.editableFields{
			loadedVal := stage.loadingComponentData[field.name] or_continue
			valPtr := uintptr(newComponent) + field.offset
			json_unmarshal(field.type, loadedVal, uintptr(newComponent) + field.offset, true)
		}

		component_event_process(newComponent, .loading)
	}

	_,entity := entity_make_empty()

	reqComponentData := entityData["requiredComponents"].(json.Array)
	uniqueComponentData := entityData["uniqueComponents"].(json.Array)

	for componentData, i in reqComponentData{
		addComponent(entity, componentData.(json.Object)["name"].(json.String), false)

	}
	for componentData in uniqueComponentData{
		addComponent(entity, componentData.(json.Object)["name"].(json.String), true)
	}

	for i in 0..<entity.requiredComponentCount{
		co := entity.components[i]
		if(!co.initialized){
			component_event_process(co, .init)
			co.initialized = true
		}
	}
	for i in COMPONENTS_MAX_PER_ENTITY..<COMPONENTS_MAX_PER_ENTITY+entity.uniqueComponentCount{
		co := entity.components[i]
		if(!co.initialized){
			component_event_process(co, .init)
			co.initialized = true
		}
	}

	stage_edit_entity_save_defaults(entity)

	se,_ := cofind(entity, StageEntity)
	estring_set(&se.uniqueID, entityData["id"].(json.String), true)

	for &componentData, i in reqComponentData{
		stage.loadingComponentData = &componentData.(json.Object)
		loadComponent(entity.components[i])
	}
	for &componentData, i in uniqueComponentData{
		stage.loadingComponentData = &componentData.(json.Object)
		loadComponent(entity.components[COMPONENTS_MAX_PER_ENTITY+i])
	}

	for i in 0..<entity.requiredComponentCount{
		component_event_process(entity.components[i], .loaded)
	}
	for i in COMPONENTS_MAX_PER_ENTITY..<COMPONENTS_MAX_PER_ENTITY+entity.uniqueComponentCount{
		component_event_process(entity.components[i], .loaded)
	}

	return entity
}

//saves the current stage to a file
_stage_save :: proc(forceSaveAs:=false)->(ok:bool){ 
	when !ON_WINDOWS do return true //never save game project files on non-windows builds

	when tracy.TRACY_ENABLE{
		lastTAT := tracy_auto_trace
		tracy_auto_trace = false
		defer tracy_auto_trace = lastTAT
	}

	assert(DEBUG && stage_edit.enabled, "Attempted to save a stage outside of stage editing mode.")

	//get save path
	savePath:string
	stagesPath,_ := filepath.join({project_directory, "stages"}, context.temp_allocator)
	if(stage.loaded != nil){
		savePath, _ = filepath.join({stagesPath, stage.loaded.data["filePath"].(json.String), format("%s.json", stage.name)}, context.temp_allocator)
	}
	else do savePath, _ = filepath.join({stagesPath, "new_stage.json"}, context.temp_allocator)

	saveName:string
	savePathC:cstring
	defer delete(savePathC)
	savedAs:bool
	if(stage.loaded == nil || forceSaveAs){
		filter:cstring = "*.json"
		savePathC = tinyfd.saveFileDialog(
			"Save Stage", 
			string_to_cstring(savePath, context.temp_allocator),
			1, &filter, 
			nil
		)
		if(savePathC == "") do return false
		savePath = string(savePathC)
		saveName = filepath.stem(savePath)
		savedAs = true
	}
	else do saveName = stage.loaded.name


	//compile save data
	save := strings.builder_make(context.temp_allocator)

	{
		//main object
		strings.write_string(&save, "{")
		defer strings.write_string(&save, "}")

		//version
		json_marshal_field(&save, STAGE_FORMAT_VERSION, "format_version", true)

		//stage info
		json_marshal_field(&save, stage.requiredTextureGroups, "requiredTextureGroups")
		json_marshal_field(&save, stage.bounds, "bounds")
		json_marshal_field(&save, stage.indoors, "indoors")
		if stage.randomSeed >= 0 do json_marshal_field(&save, stage.randomSeed, "randomSeed")
		json_marshal_field(&save, stage.backgroundColor, "backgroundColor")
		json_marshal_field(&save, stage.shadowBlend, "shadowBlend")
		json_marshal_field(&save, stage.lightBlend, "lightBlend")
		json_marshal_field(&save, stage.collisionMesh, "collisionMesh")
		//json_marshal_field(&save, stage.tintEnabled, "tintEnabled")
		//json_marshal_field(&save, stage.tint, "tint")
		json_marshal_field(&save, stage.defaultFootstepSurface, "defaultFootstepSurface")
		json_marshal_field(&save, stage.footstepSurfaceOverrides, "footstepSurfaceOverrides")

		//entities
		{
			strings.write_string(&save, "\"entities\":[")
			defer strings.write_string(&save, "],")

			stageEntities := coall(StageEntity)
			for &stageEntity in stageEntities{
				stageEntity_serialize_to_builder(&save, &stageEntity)
			}
			if(len(stageEntities) > 0) do strings.pop_byte(&save)
		}


		//layers
		{
			strings.write_string(&save, "\"layers\":[")
			defer strings.write_string(&save, "]")
			for layer in stage.layers{
				strings.write_string(&save, "{")
				defer strings.write_string(&save, "},")

				json_marshal_field(&save, layer.name, "name")
				json_marshal_field(&save, layer.depthKind, "depthKind")
				json_marshal_field(&save, layer.offset, "offset")
				json_marshal_field(&save, layer.z, "z")
				json_marshal_field(&save, layer.visible, "visible")
				json_marshal_field(&save, layer.blendData, "blendData")

				switch variant in layer.variant{
					case StageLayerImage:
						json_marshal_field(&save, "Image", "variant")
						json_marshal_field(&save, variant.sprite, "sprite")
						json_marshal_field(&save, variant.parallax, "parallax")
					case StageLayerTiles:
						json_marshal_field(&save, "Tiles", "variant")
						json_marshal_field(&save, variant.tilePos, "tilePos")
						json_marshal_field(&save, variant.tileset, "tileset")
						compressedTileData := grid_make(f64, variant.tileData.w, variant.tileData.h, context.temp_allocator)
						for tile, i in variant.tileData.buf{
							compressedTileData.buf[i] = tile_layer_tile_compress(tile)
						}
						json_marshal_field(&save, compressedTileData, "tileData")
					case StageLayerTint:
						json_marshal_field(&save, "Tint", "variant")
						json_marshal_field(&save, variant.multicolor, "multicolor")
						json_marshal_field(&save, variant.tintMode, "tintMode")
						json_marshal_field(&save, variant.tint, "tint")
					case StageLayerShader:
						json_marshal_field(&save, "Shader", "variant")
						json_marshal_field(&save, variant.resetZ, "resetZ")
						json_marshal_field(&save, variant.shader, "shader")
				}
				strings.pop_byte(&save)
			}
			if(len(stage.layers) > 0) do strings.pop_byte(&save)

		}
	}
	
	parsedObject := json_parse(save.buf[:], os_allocator).(json.Object)

	saveDir,_ := filepath.split(savePath)
	relativeDir,_ := filepath.rel(stagesPath, saveDir, context.temp_allocator)
	if relativeDir == "." do relativeDir = ""
	else if savedAs{
		pathSplit := string_split(relativeDir, "/", allocator=context.temp_allocator)
		arr := cast(^json.Array)(&parsedObject["requiredTextureGroups"])
		if len(arr) == 0 do append(arr, pathSplit[0])
	}

	strings.builder_reset(&save)
	err := json_marshal(&save, parsedObject, &JSON_PRETTY_OPT)

	saveData := save.buf[:]

	_ = os.write_entire_file(savePath, saveData)

	parsedObject["filePath"] = string_clone(relativeDir, os_allocator) //filePath does not need to be saved to the actual stage file, can be rederived
	
	if(stage.loaded == nil || saveName != stage.loaded.name){
		if(saveName in stage._stages_map){
			stage.loaded = &stage._stages_map[saveName]
		}
		else{
			clonedName := strmap_set(&stage._stages_map, saveName, Stage{init=nil_proc})
			stage.loaded = &stage._stages_map[clonedName]
			stage.loaded.name = clonedName
			append(&stage.names, clonedName)
		}
	}
	
	json.destroy_value(stage.loaded.data)
	stage.loaded.data = parsedObject
	stage_edit.last_save_undo_stack_size = len(stage_edit.undoStack)

	return true
}

//Go to a given stage. Load will not happen until the end of the frame. 
stage_goto :: proc(s:^Stage){
	stage._goto = s
}
stage_warp_seq :: proc(s:^Stage, warpCharacter:^StageCharacter=nil, warpCharacterNewPos:=Vec2{}, warpCharacterNewFacing:=Dir.none, warpSound:AudioEvent=nil, duration:TransitionDuration=30, onMid:Callback=nil, key:ImKey=#caller_location) -> bool{
	done:^bool
	if seq_open(&done, key){
		if seq_cue(0){
			tr := stage_warp(s, warpCharacter, warpCharacterNewPos, warpCharacterNewFacing, false, warpSound, duration, onMid)
			tr.done = done
		}
		if done^ do return seq_close(.end)
	}
	return seq_close()
}
stage_warp :: proc(targetStage:^Stage, warpCharacter:^StageCharacter=nil, warpCharacterNewPos:=Vec2{}, warpCharacterNewFacing:=Dir.none, setCutscene:=true, warpSound:AudioEvent=nil, duration:TransitionDuration=30, onMid:Callback=nil) -> ^Transition{
	stages_preparse_block()

	targetIndoors := targetStage.data["indoors"].(json.Boolean)

	transition := entity_make(Transition)
	transition.color = stage.indoors && !targetIndoors ? COLOR_WHITE:COLOR_BLACK
	transition.durations = duration
	
	if setCutscene do cutscene.enabled = true

	if warpCharacter != nil{
		warpCharacter.spriter.animSpeed = 0
	}

	if warpSound != nil do audio_play(warpSound)
	else if stage.indoors || targetIndoors do audio_play(au.doorOpenClose) //todo: more complex warp sound behavior

	WarpState :: struct{
		targetStage:^Stage,
		warpCharacter:CoRefEx(StageCharacter),
		warpCharacterNewPos:Vec2,
		warpCharacterNewFacing:Dir,
		setCutscene:bool,
		onMid:Callback
	}
	state:=WarpState{
		targetStage=targetStage,
		setCutscene=setCutscene,
		onMid=onMid
	}

	if warpCharacter != nil{
		state.warpCharacter = crx(warpCharacter)
		state.warpCharacterNewPos = warpCharacterNewPos
		state.warpCharacterNewFacing = warpCharacterNewFacing
	}

	transition.onMid = callback_make(proc(state:^WarpState){
		stage_goto(state.targetStage)

		if state.warpCharacter.entityID != 0{
			entity_persistent_set(entity_get(state.warpCharacter.entityID), true)
	
			proc_call_delayed(callback_make(proc(state:^WarpState){
				char := coget(state.warpCharacter)
				char.transform.pos = state.warpCharacterNewPos
				if state.warpCharacterNewFacing != .none do scface(char, state.warpCharacterNewFacing)
				entity_persistent_set(char.entity, false)
	
				stage.target_camera_pos = char.transform.pos + CAMERA_DEFAULT_TRACKING_OFFSET

				callback_call(state.onMid)
			}, state^), 1)
		}

	}, state)

	transition.onEnd = callback_make(proc(state:^WarpState){
		if state.warpCharacter.entityID != 0{
			char := coget(state.warpCharacter)
			char.spriter.animSpeed = 1
		}
		if state.setCutscene do cutscene.enabled = false
	}, state)

	return transition
}

//Unloads the current stage and sets the current stage to nil
_stage_unload :: proc(){
	_entities_just_made_process()
	
	//close menus, exit any special game states
	combat_end(true)
	combat.phase = .disabled
	clear(&camera.shakeRequests)
	
	//unload current stage data
	_entities_clear_all()
	particles_clear_all()
	clear(&stage.layers)
	mesh_clear(&stage.collisionMesh)
	for key in seq._component_sequence_keys{
		delSeq := seq._sequences_map[key]
		if pool,ok:=seq.context_seq_pools_map[delSeq]; ok{
			allocator_delete(pool.allocator)
			delete_key(&seq.context_seq_pools_map, delSeq)
		}
		strmap_delete_key(&seq._sequences_map, key)
	}
	clear(&seq._component_sequence_keys)

	free_all(stage.allocator)

	for key in ui.cues{
		strmap_delete_key(&ui.cues, key)
	}
	clear(&ui.cues)
	stage.backgroundColor = COLOR_BLACK
	stage.bounds = Rect{0, display_size()}
	stage.target_camera_pos = display_size()/2
	stage.camera_pos = 0

	//coalesce default allocator (deprecated)
	//default_allocator_coalesce()

	stage.loaded = nil
	stage.started = false
}

stage_load :: proc(s:^Stage){
	when tracy.TRACY_ENABLE{
		lastTAT := tracy_auto_trace
		tracy_auto_trace = false
		defer tracy_auto_trace = lastTAT
	}

	stages_preparse_block()

	s:=s

	json_unmarshal(s.data["requiredTextureGroups"], &stage.requiredTextureGroups)
	for g in stage.requiredTextureGroups do texture_group_preload(g)
	texture_group_unload("title_screen_HD")

	if(stage_edit.enabled){ //clear stage edit state
		_stage_edit_end()
		_stage_edit_start(false)
	}

	_stage_unload() //unload current stage
	display.hd_enabled = false

	stage.loaded = s

	//init per-stage structures

	//load stage info
	json_unmarshal(type_info_of(Rect), s.data["bounds"], uintptr(&stage.bounds))
	json_unmarshal(type_info_of(bool), s.data["indoors"], uintptr(&stage.indoors))
	if "randomSeed" in s.data{
		json_unmarshal(type_info_of(int), s.data["randomSeed"], uintptr(&stage.randomSeed))
		random_set_seed(u64(stage.randomSeed))
	}
	else{
		stage.randomSeed = -1
		random_set_seed(u64(time_get_epoch_ms())) //prevent set seed from carrying over from a previous room
	}
	json_unmarshal(type_info_of(Color), s.data["backgroundColor"], uintptr(&stage.backgroundColor))
	json_unmarshal(type_info_of(Blend), s.data["shadowBlend"], uintptr(&stage.shadowBlend))
	json_unmarshal(type_info_of(Blend), s.data["lightBlend"], uintptr(&stage.lightBlend))
	//json_unmarshal(type_info_of(bool), s.data["tintEnabled"], uintptr(&stage.tintEnabled))
	//json_unmarshal(type_info_of([4]Blend), s.data["tint"], uintptr(&stage.tint))

	json_unmarshal(type_info_of(FootstepSurface), s.data["defaultFootstepSurface"], uintptr(&stage.defaultFootstepSurface))
	json_unmarshal(s.data["footstepSurfaceOverrides"], &stage.footstepSurfaceOverrides)

	//load stage collision mesh
	json_unmarshal(s.data["collisionMesh"], &stage.collisionMesh)

	//init collision regions
	_collision_regions_init()
	stage.target_camera_pos = rect_center(stage.bounds)
	stage.camera_pos = stage.target_camera_pos - DISPLAY_SIZE/2

	//resize stage textures
	tex_resize(&stage.shadow_map, stage.bounds.size)

	//load layers
	layersData := s.data["layers"].(json.Array)
	reserve(&stage.layers, len(layersData))
	for layerData in layersData{
		layerData := layerData.(json.Object)
		append(&stage.layers, StageLayer{})
		newLayer := &stage.layers[len(stage.layers)-1]
		newLayer.name = layerData["name"].(json.String)
		json_unmarshal(type_info_of(StageLayerDepthKind), layerData["depthKind"], uintptr(&newLayer.depthKind))
		off := layerData["offset"].(json.Array)
		newLayer.offset = Vec2{f32(off[0].(json.Float)), f32(off[1].(json.Float))}
		newLayer.z = f32(layerData["z"].(json.Float))
		newLayer.visible = layerData["visible"].(json.Boolean)
		json_unmarshal(type_info_of(BlendData), layerData["blendData"], uintptr(&newLayer.blendData))

		switch layerData["variant"].(json.String){
			case "Image":
				newLayer.variant = StageLayerImage{}
				variant := &newLayer.variant.(StageLayerImage)
				if spriteName,ok := layerData["sprite"].(json.String); ok do variant.sprite = &sprites._sprites_map[spriteName]
				parallax := layerData["parallax"].(json.Array)
				variant.parallax = Vec2{f32(parallax[0].(json.Float)), f32(parallax[1].(json.Float))}
			case "Tiles":
				newLayer.variant = StageLayerTiles{}
				variant := &newLayer.variant.(StageLayerTiles)
				tilePos := layerData["tilePos"].(json.Array)
				variant.tilePos = Vec2i{int(tilePos[0].(json.Float)), int(tilePos[1].(json.Float))}
				if tsName, ok := layerData["tileset"].(json.String); ok{
					variant.tileset = tileset_get(&sprites._sprites_map[tsName])
					tileData := layerData["tileData"].(json.Object)
					variant.tileData = grid_make(TileLayerTile, int(tileData["w"].(json.Float)), int(tileData["h"].(json.Float)), stage.allocator)
					for gridVal, i in tileData["buf"].(json.Array){
						variant.tileData.buf[i] = tile_layer_tile_uncompress(gridVal.(json.Float))
					}
				}
				else{
					variant.tileData = grid_make(TileLayerTile, 0, 0, stage.allocator)
				}
			case "Tint":
				newLayer.variant = StageLayerTint{}
				variant := &newLayer.variant.(StageLayerTint)
				json_unmarshal(layerData["tint"], &variant.tint)
				json_unmarshal(layerData["tintMode"], &variant.tintMode)
				variant.multicolor = layerData["multicolor"].(json.Boolean)
			case "Shader":
				newLayer.variant = StageLayerShader{}
				variant := &newLayer.variant.(StageLayerShader)
				json_unmarshal(layerData["resetZ"], &variant.resetZ)
				json_unmarshal(layerData["shader"], &variant.shader)
				
		}

	}

	texture_group_load_block(groupNames=stage.requiredTextureGroups[:]) //must block before entity load so that depth-sort values that rely on surface data work correctly

	//load entities
	entitiesData := s.data["entities"].(json.Array)
	for data in entitiesData{
		stageEntity_make_from_json(data.(json.Object))
	}

	_entities_just_made_process()

	if s.init != nil && !stage_edit.enabled do s.init()
	if s.initEditor != nil && stage_edit.enabled do s.initEditor()

	_entities_just_made_process()

	_entities_event_process(.stageStart)

	_entities_just_made_process()

	stage.started = true
}

_stage_system_update :: proc(){
	if stage.loaded != nil && stage.loaded.update != nil do stage.loaded.update()
}


// stage_data_load_from_file :: proc(path:string, allocator:=context.temp_allocator) -> Stage{
// 	pathCstr := string_to_cstring(path, context.temp_allocator)
// 	fileSize:uint
// 	fileDataPtr := sdl3.LoadFile(rawptr(pathCstr), &fileSize)
// 	defer sdl3.free(fileDataPtr)

// 	jsonData := slice.bytes_from_ptr(fileDataPtr, int(fileSize))
// 	jsonVal, err := json.parse(jsonData, json.DEFAULT_SPECIFICATION, false, allocator)
// 	assertf(err == .None, "Could not parse stage json from file '%s'!", path)

// 	jsonObject := jsonVal.(json.Object)
// 	assertf(stage_data_upgrade(&jsonObject), "Could not update stage data from file '%s'!", path)

// 	return Stage{
// 		jsonObject["name"].(json.String),
// 		jsonObject
// 	}
// }

STAGE_FORMAT_VERSION :: "11" //increment whenever you make a breaking change
stage_data_upgrade :: proc(data:^json.Object) -> bool{
	switch data["format_version"].(json.String){
		case "10":
			group := string_slice_between(data["filePath"].(json.String), "", "/")
			if group != ""{
				arr := make(json.Array, 1)
				arr[0] = group
				data["requiredTextureGroups"] = arr
			} 
			else do data["requiredTextureGroups"] = json.Array{}

			data["format_version"] = "11"
			return stage_data_upgrade(data)
		case "9":
			migrateSmallArrays :: proc(val:json.Value){
				#partial switch v in val{
					case json.Object:
						for _, &fieldVal in v{
							if obj, ok := fieldVal.(json.Object); ok{
								if dataArr, dok := obj["data"].(json.Array); dok{
									if lenF, lok := obj["len"].(json.Float); lok{
										n := min(int(lenF), len(dataArr))
										newArr := make(json.Array, n)
										for i in 0..<n do newArr[i] = dataArr[i]
										fieldVal = newArr
										continue
									}
								}
							}
							migrateSmallArrays(fieldVal)
						}
					case json.Array:
						for &elem in v do migrateSmallArrays(elem)
				}
			}
			
			migrateSmallArrays(data^)

			data["format_version"] = "10"
			return stage_data_upgrade(data)
		case "8":
			cMeshObj := make(json.Object)
			cMeshObj["vertices"] = data["collisionMeshVertices"]
			cMeshObj["edges"] = data["collisionMeshEdges"]
			data["collisionMesh"] = cMeshObj

			data["format_version"] = "9"
			return stage_data_upgrade(data)
		case "7":
			color := make(json.Array, 4)

			color[0] = json.Float(238)
			color[1] = json.Float(229)
			color[2] = json.Float(190)
			color[3] = json.Float(255.*0.2)
			data["lightBlend"] = color

			data["format_version"] = "8"
			return stage_data_upgrade(data)
		case "6":
			color := make(json.Array, 4)
			for &colorVal in color{
				colorVal = json.Float(255.*0.27450980392)
			}
			color[3] = json.Float(255.*0.45)
			data["shadowBlend"] = color

			data["format_version"] = "7"
			return stage_data_upgrade(data)
		case "5":
			data["defaultFootstepSurface"] = json.Float(3)
			data["format_version"] = "6"
			return stage_data_upgrade(data)
		case "4":
			tint := make(json.Array, 4)
			for &c in tint{
				color := make(json.Array, 4)
				for &colorVal in color{
					colorVal = json.Float(0)
				}
				c = color
			}
			data["tint"] = tint
			data["tintEnabled"] = false

			layersData := &data["layers"]
			
			blankBlendStr, _ := json_encode(BlendData{COLOR_WHITE, 1, .blend}, context.temp_allocator)
			blankBlend := transmute([]u8)blankBlendStr
			for &layerData in layersData.(json.Array){
				layerData := &layerData.(json.Object)
				layerData["blendData"] = json_parse(blankBlend, context.allocator)
			}

			data["format_version"] = "5"
			return stage_data_upgrade(data)
		case "3":
			data["collisionMeshVertices"] = ""
			data["collisionMeshEdges"] = ""
			data["format_version"] = "4"
			return stage_data_upgrade(data)
		case "2":
			layersData := &data["layers"]
			for &layerData in layersData.(json.Array){
				layerData := &layerData.(json.Object)
				if layerData["variant"].(json.String) == "Tiles"{
					tileDataV := &layerData["tileData"]
					tileData := &tileDataV.(json.Object)
					tileDataBuf := &tileData["buf"]
					for &gridVal in tileDataBuf.(json.Array){
						gridVal = tile_layer_tile_compress(TileLayerTile{
							0, 0, u16(gridVal.(json.Float))
						}) 
					}
				}
			}

			data["format_version"] = "3"
			return stage_data_upgrade(data)
		case "1":
			data["backgroundColor"] = make(json.Array, 3)
			for &elem in data["backgroundColor"].(json.Array){
				elem = json.Float(0)
			} 
			data["format_version"] = "2"
			return stage_data_upgrade(data)
		case STAGE_FORMAT_VERSION:
			return true
	}

	return false
}

