#+feature using-stmt
package massimodin //@nested-tags:_components/

import "../sdl3"

//Holds all information and requires all components that are necessary to rendering and using an entity in a stage
StageEntity :: struct{
	using base:RenderComponentBase,
	spriter:CoRef(Spriter),
	transform:CoRef(Transform),
	uniqueID:Estring,
	group:Estring, //@e
	componentsVisible:bool, //@e
	identifyingComponentIndex:int, //@e
	debugVisibleOnly:bool, //@e
	depthKind:StageEntityDepthKind, //@e
	using blendData:BlendData, //@e
	drawParallax:Vec2, //@e
	defaultAnimSpeed:f32, //@e
	editableDepthOffset:f32, //@e
	internalDepthOffset:union{f32, Vec2},
	preciseDepthTexturePage:^TexturePage, //cached to save time
	preciseDepthSegments:[]StageEntityPreciseDepthSegment,
	resizable:bool, //@e
	displayID:bool, //@e
	receivesVerticalShadow:bool, //@e
	shadowKind:StageEntityShadowKind, //@e
	invertShadowMargin:f32, //@e
	invertShadowTex:Tex,
	dropShadowOffset:Vec2, //@e
	dropShadowRadii:Vec2, //@e
	dropShadowAngle:f32, //@e
	shakeDuration:int,
	shakeForce:Vec2,
	shadowDraw:proc(self:^StageEntity),
	cullRect:Rect,
	ignoreTimeStop:bool,
	static:bool, //@e
	staticSet:bool
}

//MUST BE SERIALIZABLE
StageEntityPersistentData :: struct{
	interactCount:int
}

StageEntityDepthKind :: enum{
	origin,
	baseTop,
	floor,
	precise
}

StageEntityPreciseDepthSegment :: struct{
	internalDepthOffset:f32,
	srcRect:Rect,
	dstRect:Rect //add dstOffset
}

StageEntityShadowKind :: enum{
	none,
	isShadow, //entity renders to the shadow mask
	isLight, //entity renders to the shadow mask as a bright spot
	dropShadowEllipse, //entity renders a drop shadow
	dropShadowRect, //entity renders a drop shadow
}

stageEntity_persistent_data :: proc(se:^StageEntity) -> ^StageEntityPersistentData{
	if se.uniqueID.s not_in save.persistent_entity_data{
		key := string_clone(se.uniqueID.s, save.allocator)
		save.persistent_entity_data[key] = StageEntityPersistentData{}
	}
	return &save.persistent_entity_data[se.uniqueID.s]
}

stageEntity_draw_pos :: #force_inline proc(se:^StageEntity) -> Vec2{
	out := se.transform.pos
	out.y += ceil(se.transform.z)
	out += stage.camera_pos*se.drawParallax
	if se.shakeForce != 0{
		for &n, i in se.shakeForce{
			amount := random_range(n*0.5, n*2)
			out[i] += choose([]f32{amount, -amount})
		}
	}
	return out
}

//Returns the feetPos draw param for an entity's vertically shaded draws.
//Returns nil if the entity should not receive vertical shading.
stageEntity_feet_pos :: #force_inline proc "contextless" (self:^StageEntity) -> Maybe(Vec2){
	return (self.depthKind != .floor && self.receivesVerticalShadow && !stage_edit.enabled) ? self.transform.pos : nil
}

//Will use the current frame by default, but you can pass a frame index if you want a consistent rect
stageEntity_draw_rect :: #force_inline proc(se:^StageEntity, frameIndex:=-1) -> Rect{
	frameIndex := (frameIndex == -1) ? se.spriter.lastFrame : frameIndex 
	return sprite_draw_rect(se.spriter.mySprite, stageEntity_draw_pos(se), frameIndex, se.transform.scale)
}

stageEntity_find :: proc(uniqueID:string) -> ^StageEntity{
	ents := coall(StageEntity)
	for &ent in ents{
		if ent.uniqueID.s == uniqueID do return &ent
	}
	when DEBUG do printf("Warning: Stage Entity with ID '%s' not found.", uniqueID)
	return nil
}

stageEntity_group_get :: proc(groupName:string, allocator:=context.temp_allocator) -> []^StageEntity{
	out := make([dynamic]^StageEntity, allocator)
	ents := coall(StageEntity)
	for &ent in ents{ if ent.group.s == groupName do append(&out, &ent)}
	shrink(&out)
	return out[:]
}
stageEntity_group_set_visible :: proc(groupName:string, visible:bool){
	group := stageEntity_group_get(groupName)
	for ent in group{
		stageEntity_set_visible(ent, visible)
	}
}

//useful if you want to, say, suddenly move a giant elevator around without it getting culled
stageEntity_unstatic :: proc(se:^StageEntity){
	se.static = false
	se.staticSet = false
	se.spriter.disabled = false
	se.visible = true
}

//Gets the stage entity closest to a position (does not account for z position).
//If id pattern is not empty, will only return entities whose uniqueID contains the given string.
stageEntity_nearest :: proc(pos:Vec2, idPattern:string="") -> (entity:^StageEntity, found:bool){
	dist:f32
	ents := coall(StageEntity)
	for &ent in ents{
		if idPattern == "" || string_contains(ent.uniqueID.s, idPattern){
			if entity == nil{
				entity = &ent
				dist = vec2_distance(ent.transform.pos, pos)
				continue
			}

			newDist := vec2_distance(ent.transform.pos, pos)
			if newDist < dist{
				entity = &ent
				dist = newDist
			}
		}
	}

	return entity, entity!=nil
}

//Returns bounds that encompass all entities' draw rects
stageEntities_bounds :: proc(ents:[]^StageEntity) -> Rect{
	bounds:Rect
	for stageEntity,i in ents{
		entityRect := sprite_draw_rect(stageEntity.spriter.mySprite, stageEntity_draw_pos(stageEntity), 0, stageEntity.transform.scale)
		if(i==0) do bounds = entityRect
		else{
			rect_set_left(&bounds, min(entityRect.x, bounds.x), true)
			rect_set_top(&bounds, min(entityRect.y, bounds.y), true)
			rect_set_right(&bounds, max(rect_get_right(entityRect), rect_get_right(bounds)), true)
			rect_set_bottom(&bounds, max(rect_get_bottom(entityRect), rect_get_bottom(bounds)), true)
		}
	}
	return bounds
}

//whether a stage entity is in a custom editing mode (as opposed merely selected or not selected at all)
stageEntity_editing :: proc(se:^StageEntity) -> bool{
	if !stage_edit.enabled do return false
	if ptr,ok := stage_edit.cursor_contents.(^StageEntity); ok do return ptr == se
	return false
}

//sets the visiblity of all components on a stage entity
stageEntity_set_visible :: proc(se:^StageEntity, visible:bool){
	se.componentsVisible = visible
	if !visible || (se.shadowKind == .isShadow || se.shadowKind == .isLight){
		renderComponents := entity_render_components(se.entity)
		for co in renderComponents{
			co.visible = false
		}
	}
	else{
		renderComponents := entity_render_components(se.entity)
		for co in renderComponents{
			co.visible = true
		}
	}
}

stageEntity_shake :: proc(se:^StageEntity, duration:int, force:Vec2){
	se.shakeDuration = duration
	se.shakeForce = force
}

stage_node_nearest :: proc(pos:Vec2, idPattern:string="") -> Vec2{
	dist:f32
	entity:^StageEntity
	ents := coall(StageEntity)
	for &ent in ents{
		if ent.group.s == "nodes" && (idPattern == "" || string_contains(ent.uniqueID.s, idPattern)){
			if entity == nil{
				entity = &ent
				dist = vec2_distance(ent.transform.pos, pos)
				continue
			}

			newDist := vec2_distance(ent.transform.pos, pos)
			if newDist < dist{
				entity = &ent
				dist = newDist
			}
		}
	}

	if entity == nil do return Vec2{}
	return entity.transform.pos
}

stageEntity_pos :: proc(id:string) -> Vec2{
	se := stageEntity_find(id)
	if se != nil do return se.transform.pos
	return Vec2{}
}
sepos :: stageEntity_pos

stage_mask_init :: proc(ent:^CoRef(StageEntity), sprite:^Sprite){
	coadd(ent)
	spriter_set(ent.spriter, sprite)
	ent.debugVisibleOnly = true
	ent.resizable = true
}

MoveSeqPos :: struct{
	pos:Vec2,
	time:int
}
//can optionally provide a slice to be filled with the position data, i.e. the time and position at which the entity *starts* moving towards each target position 
stageEntity_move_seq :: proc(using self:^StageEntity, targetPositions:[]Vec2, pace:union{f32, int}=1.5, relative:=false, moveSprite:^Sprite=nil, curve:^Curve=nil, key:ImKey=#caller_location, outData:[]MoveSeqPos=nil) -> bool{
	state:^struct{
		startPos:Vec2,
		lastSprite:^Sprite
	}
	assertf(outData == nil || len(outData) == len(targetPositions)+1, "stageEntity move sequence out data length '%i' does not match target position count '%i' + 1", len(outData), len(targetPositions))
	if seq_open(&state, key){
		if(seq_cue(0)){
			state.startPos = transform.pos
			state.lastSprite = spriter.mySprite
			if moveSprite != nil do spriter_set(spriter, moveSprite)
		}

		targetPositions := targetPositions
		if relative{
			targetPositions = clone(targetPositions, context.temp_allocator)
			curPos := state.startPos
			for &pos in targetPositions{
				pos += curPos
				curPos = pos
			}
		}

		endPos := peek(targetPositions)
		totalDistance:f32
		_, paceIsSpeed := pace.(f32)
		if !paceIsSpeed{
			for lastPos := state.startPos; pos in targetPositions{
				totalDistance += vec2_distance(lastPos, pos)
				lastPos = pos
			}
		}

		lastPos := state.startPos
		t:=0
		for pos,i in targetPositions{
			if outData != nil do outData[i] = {lastPos, t}
			duration:int
			if paceIsSpeed do duration = roundi(vec2_distance(lastPos, pos)/pace.(f32))
			else do duration = roundi(vec2_distance(lastPos, pos)/totalDistance*f32(pace.(int)))
			if(seq_cue(t, t+duration)){
				transform_set(transform, seq_map(lastPos, pos, curve))
			}
			lastPos = pos
			t += duration
		}

		if outData != nil do outData[len(targetPositions)] = {lastPos, t}

		if(seq_cue(t)){
			if moveSprite != nil do spriter_set(spriter, state.lastSprite)
			transform_set(transform, endPos)
			return seq_close(.end)
		}
	}
	return seq_close()
}

stageEntity_shadow_draw_default :: proc(using self:^StageEntity){
	sprite_draw_ex(
		spriter.mySprite, transform.pos, spriter.lastFrame, 
		transform.scale, transform.angle, shadowKind == .isShadow?COLOR_BLACK:COLOR_WHITE, 1
	)
}

_stageEntity_process_event :: proc(base:^ComponentBase, event:Event, overrideDisabled:=false){
if(!overrideDisabled && event in base.disabledEvents) do return
last_context := entities.context_component
defer cowith(last_context)
cowith(base)
self := cast(^StageEntity)base
using self
#partial switch event{
case .init:
	coadd(&spriter)
	coadd(&transform)
	blendData = BLEND_DATA_DEFAULT
	defaultAnimSpeed = 1
	componentsVisible = true
	receivesVerticalShadow = true
	shadowDraw = stageEntity_shadow_draw_default
	depth = INF //a lot of code assumes f32, so start with a placeholder max depth val
	static = true

case .loaded:

	spriter.animSpeed = defaultAnimSpeed
	#partial switch depthKind{
		case .baseTop:
			frame := spriter.mySprite.frames[0]
			tppX := int(frame.texturePagePos.x)
			tppY := int(frame.texturePagePos.y)
			tppW := int(frame.texturePagePos.size.x)
			tppH := int(frame.texturePagePos.size.y)
			highestBaseY := tppY+tppH
			for x:=tppX;x<tppX+tppW;x+=1{
				for y:=tppY+tppH-1;y>=0;y-=1{
					if surface_pixel_filled(frame.texturePage.surface, x, y){
						if y < highestBaseY do highestBaseY = y
						break
					}
				}
			}

			internalDepthOffset = spriter.mySprite.origin.y - (f32(highestBaseY) - frame.texturePagePos.y + frame.trimOffset.y)

		case .precise:
			frame := spriter.mySprite.frames[0]
			preciseDepthTexturePage = spriter.mySprite.frames[0].texturePage
			tppX := int(frame.texturePagePos.x)
			tppY := int(frame.texturePagePos.y)
			tppW := int(frame.texturePagePos.size.x)
			tppH := int(frame.texturePagePos.size.y)
			segmentStartX := tppX
			segmentEndX := segmentStartX
			lastY := -1
			segments := make([dynamic]StageEntityPreciseDepthSegment, 0, tppW)
			origin := spriter.mySprite.origin - frame.trimOffset
			segmentMake :: proc(segmentStartX, segmentEndX, lastY:int, frame:^SpriteFrame, origin:Vec2, flipX:bool) -> StageEntityPreciseDepthSegment{
				srcRect := Rect{
					{f32(segmentStartX), frame.texturePagePos.y},
					{f32(segmentEndX - segmentStartX + 1), frame.texturePagePos.size.y}
				}
				dstX := f32(segmentStartX) - frame.texturePagePos.x - origin.x
				if flipX{
					dstX*=-1
					dstX -= srcRect.size.x-1
				}
				return {
					origin.y - (f32(lastY) - frame.texturePagePos.y),
					srcRect,
					Rect{{dstX, -origin.y}, srcRect.size}
				}
			}
			for x:=tppX;x<tppX+tppW;x+=1{
				for y:=tppY+tppH-1;y>=0;y-=1{
					if surface_pixel_filled(frame.texturePage.surface, x, y){
						if y != lastY && lastY != -1{
							append(&segments, segmentMake(segmentStartX, segmentEndX, lastY, &frame, origin, transform.scale.x < 0))
							segmentStartX = x
						}
						lastY = y
						segmentEndX = x
						break
					}
				}
			}

			//last segment
			append(&segments, segmentMake(segmentStartX, segmentEndX, lastY, &frame, origin, transform.scale.x < 0))

			// if transform.scale.x == -1{ //special case to allow flipping objects
			// 	// sort(&segments, proc(a,b:StageEntityPreciseDepthSegment)->bool{
			// 	// 	return a.dstRect.x < b.dstRect.x
			// 	// })
			// 	for seg,i in segments do print(i, seg.dstRect.x)
			// 	segCount := len(segments)
			// 	for i in 0..=segCount/2{
			// 		lastX := segments[i].dstRect.x
			// 		segments[i].dstRect.x = segments[segCount-i-1].dstRect.x
			// 		segments[segCount-i-1].dstRect.x = lastX
			// 	}
			// }

			shrink(&segments)
			preciseDepthSegments = segments[:]
	}

	if dropShadowRadii == 0{
		#partial switch shadowKind{
			case .dropShadowEllipse, .dropShadowRect:
				dr := stageEntity_draw_rect(self, 0)
				dropShadowRadii.x = dr.size.x/2
				if col,ok:=cofind(Collider);ok{
					dropShadowRadii.y = col.bounds.size.y/2
				}
				else do dropShadowRadii.y = 3
				if shadowKind == .dropShadowRect{
					if col,ok:=cofind(Collider);ok{
						dropShadowOffset = col.bounds.pos - (transform.pos - dropShadowRadii)
					} 
				}
		}
	}

case .justMade:
	if uniqueID.s == ""{
		uniqueID.s = uuid_make_string() //ensure entities that are not loaded from the stage have a unique id
		uniqueID.allocator = context.allocator
	}
	visibility := true
	if !componentsVisible do visibility = false

	stageEntity_set_visible(self, visibility)

	if debugVisibleOnly do visible = componentsVisible && (stage_edit.enabled || stage.debugEntitiesVisible)
	
//normal .draw handled in bulk in stage_render

case .drawEditor:
	if displayID do text_draw(uniqueID.s, stageEntity_draw_pos(self), font=fo.yal6w4__16, alignment=0)
case .clean:
	delete(preciseDepthSegments)
	estring_delete(&uniqueID)
	estring_delete(&group)
	if invertShadowTex.ptr != nil do tex_destroy(invertShadowTex)
}}

_stageEntities_bulk_update :: proc(){
	arr := coall(StageEntity)
	for &self in arr{
		if self.staticSet do continue
		using self

		if shakeDuration > 0 do shakeDuration -= 1
		else do shakeForce = 0
		
		switch depthKind{
			case .origin: depth = -transform.y
			case .baseTop: depth = -transform.y + internalDepthOffset.(f32)
			case .floor: depth = layer_depth(.stageBG) + transform.z 
			case .precise:
				//precise entities draw per segment in stage_render, their .draw is skipped there
				internalDepthOffset = stageEntity_draw_pos(&self)
		}
		if depthKind != .precise do depth += editableDepthOffset

		if static && !stage_edit.enabled{
			cullRect = stageEntity_draw_rect(&self)
			if len(spriter.mySprite.frames) <= 1 do spriter.disabled = true
			staticSet = true
		}
	}
}

//stage entity draws
//precise-depth stage entities draw per segment, layered independently
_stageEntities_bulk_draw :: proc(){
	when DEBUG do debug.onScreenStageEntities = 0

	arr := coall(StageEntity)
	for &self in arr{
		using self
		if !componentsVisible || !visible || .draw in disabledEvents do continue

		when DEBUG do debug.onScreenStageEntities += 1

		if depthKind == .precise{
			baseDepth := -transform.y + editableDepthOffset
			dstOffset := internalDepthOffset.(Vec2)
			page := preciseDepthTexturePage
			flags:QuadFlags = transform.scale.x < 0 ? {.flipX} : {}
			for &segment in preciseDepthSegments{ //hot!
				render_depth(baseDepth + segment.internalDepthOffset)
				render_quad(page.texture, page.hd ? .linearMip : .nearest, Quad{
					worldRect = {segment.dstRect.pos + dstOffset, segment.dstRect.size},
					uvRect = texture_page_uv(page, segment.srcRect),
					blend = BLEND_WHITE,
					flags = flags,
				})
			}
		}
		else{
			render_depth(depth)
			blendmode_set(blendmode)
			sprite_draw_ex(
				spriter.mySprite, stageEntity_draw_pos(&self), spriter.lastFrame,
				transform.scale, transform.angle, color, alpha, stageEntity_feet_pos(&self)
			)
			blendmode_set(.blend)
		}
	}
}
