package massimodin //@nested-tags:engine/ui

import "base:intrinsics"

UISystem :: struct{
	cues:UICueMap, //cleared on stage unload
	menus:map[string]UIMenu,

	//immediate gui variables
	frameStack:[dynamic]^UIFrame,
	currentMenu:^UIMenu,

	highlight_box_target:Maybe(Rect),
	highlight_box_current:Rect,
	highlight_box_stage_coords:bool,

	disabled:bool,

	icons:struct{
		playerCharacters:[PlayerCharacterID]PlayerCharacterIcons,
		itemKinds:[ItemKind]^Sprite
	}
}
ui:^UISystem

_ui_system_init :: proc(){
	ui = new(UISystem, os_allocator)
	init(&ui.frameStack, os_allocator)
	init(&ui.cues, os_allocator)
	init(&ui.menus, os_allocator)
	ui_highlight() //reset highlight
}

_ui_system_reload :: proc(){
	ui.icons.playerCharacters = {
		.pro={sp.pro},
		.minima={sp.minima},
	}

	ui.icons.itemKinds = {
		.key=		sp.itemIcons_key,
		.material=	sp.itemIcons_material,
		.consumable=sp.itemIcons_nil,
		.vest=		sp.itemIcons_vest, 
		.blade=		sp.itemIcons_blade, 
		.boots=		sp.itemIcons_boots, 
		.program=	sp.itemIcons_program, 
		.shoes=		sp.itemIcons_shoes,
	}
}

UILayer :: enum{
	stageEditor,
	combatUI,
	seqDraws,
	misc,
	dialogue,
	menus,
	top
}

UICue :: struct{
	lastStartFrame:int,
	lastUpdatedFrame:int,
	state:map[string]UICueState
}

UICueMap :: map[string]UICue

UICueState :: struct{
	last:[4]f32,
	current:[4]f32,
	target:[4]f32
}

UIItemState :: struct{
	interactState:UIInteractState,
	pos:Vec2,
	hoverTime:f32,
	selectTime:f32,
	index:int
}
UIInteractState :: enum{
	idle,
	hovered,
	selected,
	disabled
}

UIFrame :: struct{
	cursorPos:Vec2,
	cursorMoveAxis:int,
	currentItem:int,
	hoveredItem:int,
	disabledIndices:bs64,
	cueMap:UICueMap,
	gamepadHoverMode:UIFrameGamepadHoverMode,
	forceSelectDevices:InputDeviceKinds
}

UIFrameGamepadHoverMode :: enum{
	horizontal,
	vertical,
	tabs,
	disabled
}


UIMenu :: struct{
	allocator:Allocator,
	frameMap:map[string]^UIFrame
}

PlayerCharacterIcons :: struct{
	portrait:^Sprite
}

ui_layer_depth :: #force_inline proc "contextless" (layer:UILayer) -> f32{
	return layer_depth(.ui) - f32(layer)*100 
}

ui_frame :: #force_inline proc() -> ^UIFrame{ //returns the current ui frame
	assert(len(ui.frameStack)>0, "Tried to get a UI frame with no UI context!")
	return peek(ui.frameStack)
}

ui_cursor :: #force_inline proc() -> ^Vec2{
	return &ui_frame().cursorPos
}

ui_free :: proc(menuKey:string){
	if menu, ok := &ui.menus[menuKey]; ok{
		allocator_delete(menu.allocator)
		strmap_delete_key(&ui.menus, menuKey)
	}
}

//Gets the state of the next item in the current frame
ui_item_interact_state :: proc(itemSize:Vec2, mouseHoverSticky:=false) -> UIInteractState{
	frame := ui_frame()
	itemIndex := frame.currentItem
	out :UIInteractState= (frame.hoveredItem == itemIndex) ? .hovered : .idle
	hoverKey := imkey_combine(itemIndex, loc="hovered")
	if input_device() == .keyboard{
		if rect_contains(Rect{frame.cursorPos, itemSize}, mouse_display_pos()) && !ui.disabled{
			if frame.hoveredItem != itemIndex do ui_cue(hoverKey, &frame.cueMap)
			frame.hoveredItem = itemIndex
			out = .hovered
		}
		else if !mouseHoverSticky{
			if frame.hoveredItem == itemIndex do frame.hoveredItem = -1
			out = .idle
		}
	}

	if ui.disabled{
		out = .disabled
		frame.disabledIndices += bs64{itemIndex}
	}

	forceSelect := input_device() in frame.forceSelectDevices
	if out == .hovered && ((!forceSelect && ginputs[.confirm]) || (forceSelect && ui_cue_time(hoverKey, cueMap=&frame.cueMap) <= 1)){
		if frame.currentItem != itemIndex do ui_cue(imkey_combine(itemIndex, loc="selected"), &frame.cueMap)
		return .selected
	}

	return out
}



ui_item_process_vec2 :: proc(itemSize:Vec2, mouseHoverSticky:=false) -> UIItemState{
	out:UIItemState
	out.interactState = ui_item_interact_state(itemSize, mouseHoverSticky)
	cursor := ui_cursor()
	out.pos = cursor^
	frame := ui_frame()

	out.index = frame.currentItem
	out.hoverTime = f32(ui_cue_time(imkey_combine(frame.currentItem, loc="hovered"), false, &frame.cueMap))
	out.selectTime = f32(ui_cue_time(imkey_combine(frame.currentItem, loc="selected"), false, &frame.cueMap))

	frame.currentItem += 1

	cursor[frame.cursorMoveAxis] += itemSize[frame.cursorMoveAxis]

	return out
}
//sets the cursor pos too
ui_item_process_rect :: proc(itemRect:Rect, mouseHoverSticky:=false) -> UIItemState{
	ui_cursor()^ = itemRect.pos
	return ui_item_process_vec2(itemRect.size, mouseHoverSticky)
}
ui_item_process :: proc{ui_item_process_vec2, ui_item_process_rect}

ui_sprite :: proc(spr:^Sprite, frameIndex:=0, colors:[3]Color=COLOR_WHITE, alphas:[3]f32=1, selected:bool=false, mouseHoverSticky:=false, fullState:^UIItemState=nil) -> bool{
	out := ui_item_process(spr.size, mouseHoverSticky)
	blendInd := 0
	if selected do blendInd = 2
	else if out.interactState == .hovered do blendInd = 1
	sprite_draw_ex(spr, out.pos - sprite_origin(spr), frameIndex, color=colors[blendInd], alpha=alphas[blendInd])
	if fullState != nil do fullState^=out
	return out.interactState == .selected
}

ui_text :: proc(text:string, colors:[3]Color=COLOR_WHITE, alphas:[3]f32=1, alignment:Alignment=-1, selected:bool=false, mouseHoverSticky:=false, fullState:^UIItemState=nil, dropShadow:Maybe(Color)=nil) -> bool{
	cursor := ui_cursor()
	cursorPos := cursor^
	r := text_rect(text, cursorPos, alignment)
	out := ui_item_process(r, mouseHoverSticky)
	cursor^ = cursorPos
	cursor[ui_frame().cursorMoveAxis] += r.size[ui_frame().cursorMoveAxis]
	blendInd := 0
	if selected do blendInd = 2
	else if out.interactState == .hovered do blendInd = 1
	if dsc,ok := dropShadow.(Color); ok{
		text_draw(text, cursorPos+1, dsc, alphas[blendInd], nil, alignment)
	}
	text_draw(text, cursorPos, colors[blendInd], alphas[blendInd], nil, alignment)

	if fullState != nil do fullState^=out
	return out.interactState == .selected
}

ui_begin :: proc(key:string, cursorPos:Vec2){
	menu:^UIMenu
	if key not_in ui.menus{
		sk := strmap_set(&ui.menus, key, UIMenu{})
		menu = &ui.menus[sk]
		menu.allocator = allocator_make(16*KILOBYTE)
		init(&menu.frameMap, menu.allocator)
	}
	else do menu = &ui.menus[key]
	ui.currentMenu = menu
	ui_frame_begin(cursorPos, key="__base")
	ui_frame().cursorPos = cursorPos
}

ui_end :: proc(){
	assert(ui.currentMenu != nil, "Tried to close a ui menu without one being open!")
	ui_frame_end()
	ui.currentMenu = nil
}

ui_frame_begin :: proc(newPos:Maybe(Vec2)=nil, gamepadHoverMode:UIFrameGamepadHoverMode=.vertical, forceSelectDevices:=InputDeviceKinds{}, key:ImKey=#caller_location){
	assert(ui.currentMenu != nil, "Tried to begin a ui frame without a menu!")
	keyString := imkey_to_string(key)
	if keyString not_in ui.currentMenu.frameMap{
		newFrame := new(UIFrame, ui.currentMenu.allocator)
		newFrame.hoveredItem = -1
		init(&newFrame.cueMap, ui.currentMenu.allocator)
		strmap_set(&ui.currentMenu.frameMap, keyString, newFrame)
	}
	frame := ui.currentMenu.frameMap[keyString]
	frame.currentItem = 0
	frame.cursorPos = newPos.? or_else ui_cursor()^
	frame.cursorMoveAxis = 1
	frame.disabledIndices = bs64{}
	frame.gamepadHoverMode = gamepadHoverMode
	frame.forceSelectDevices = forceSelectDevices
	append(&ui.frameStack, frame)
}

ui_frame_end :: proc() -> ^UIFrame{
	frame :^UIFrame= pop(&ui.frameStack)

	allMask :u64= (1 << u64(frame.currentItem)) - 1
	if input_device() == .gamepad && allMask != transmute(u64)frame.disabledIndices{
		moveDir := 0
		if frame.hoveredItem == -1{
			moveDir = 1
		}
		else{
			switch frame.gamepadHoverMode{
				case .horizontal: moveDir = int(ginputs[.right]) - int(ginputs[.left])
				case .vertical: moveDir =  int(ginputs[.down]) - int(ginputs[.up])
				case .tabs: moveDir = int(ginputs[.rb]) - int(ginputs[.lb])
				case .disabled: moveDir = 0
			}
		}
		
		if moveDir != 0{
			start := true
			for start || (frame.hoveredItem in frame.disabledIndices){
				frame.hoveredItem = wrap(frame.hoveredItem + moveDir, 0, frame.currentItem-1)
				start = false
			}
			ui_cue(imkey_combine(frame.hoveredItem, loc="hovered"), &frame.cueMap)
		}
	}

	return frame
}

ui_cue :: proc(key:ImKey, cueMap:^UICueMap=nil){
	cueMap := cueMap
	if cueMap == nil do cueMap = &ui.cues

	id := imkey_to_string(key)

	if !(id in cueMap){
		strmap_set(cueMap, id, UICue{})
	}
	
	cue := &cueMap[id]

	if(cue.lastUpdatedFrame < time.frame-1){
		cue.lastStartFrame = time.frame
	}

	cue.lastUpdatedFrame = time.frame
}

ui_cue_delete :: proc(key:ImKey, cueMap:^UICueMap=nil){
	cueMap := cueMap
	if cueMap == nil do cueMap = &ui.cues

	id := imkey_to_string(key)

	cue, ok := &cueMap[id]
	if ok{
		if len(cue.state) > 0 do strmap_delete(&cue.state)
		strmap_delete_key(cueMap, id)
	}
}

ui_cue_reset :: proc(key:ImKey, cueMap:^UICueMap=nil){
	cueMap := cueMap
	if cueMap == nil do cueMap = &ui.cues

	id := imkey_to_string(key)

	if id not_in cueMap do strmap_set(cueMap, id, UICue{})
	else{
		cue := &cueMap[id]
		cue.lastStartFrame = 0
		cue.lastUpdatedFrame = 0
	}
}


ui_cue_time :: proc(key:ImKey, sinceLastUpdate:=false, cueMap:^UICueMap=nil) -> int{
	cueMap := cueMap
	if cueMap == nil do cueMap = &ui.cues

	id := imkey_to_string(key)

	if !(id in cueMap) do return time.frame
	cue := cueMap[id]
	return time.frame - (sinceLastUpdate ? cue.lastUpdatedFrame : cue.lastStartFrame)
}

//opens a sequence and sets its frame based on the ui cue, rather than using the normal frame counting behaviour.
//Will create an entry in the sequence map, be wary of leaks! 
ui_cue_seq_open :: proc(key:ImKey, sinceLastUpdate:=false, cueMap:^UICueMap=nil)->bool{
	out := seq_open(key)
	peek(seq.context_seq_stack).frame = ui_cue_time(key, sinceLastUpdate, cueMap)
	return out
}


ui_cue_map_val_time :: proc(t:f32, tStart:f32, tEnd:f32, start:f32, end:f32, curve:^Curve=nil) -> f32{
	mappedVal := (curve == nil) ? remap_val(t, tStart, tEnd, start, end) : remap_val_curve(t, tStart, tEnd, start, end, curve)
	return clamp(mappedVal, min(start,end), max(start,end))
}
ui_cue_map_val :: proc(key:ImKey, tStart:f32, tEnd:f32, start:f32, end:f32, curve:^Curve=nil, cueMap:^UICueMap=nil) -> f32{
	return ui_cue_map_val_time(f32(ui_cue_time(key, false, cueMap)), tStart, tEnd, start, end, curve)
}
ui_cue_map_arr :: proc(key:ImKey, tStart, tEnd:f32, start, end:[$N]f32, curve:^Curve=nil, cueMap:^UICueMap=nil) -> [N]f32{
	id := imkey_to_string(key)
	t := f32(ui_cue_time(key, false, cueMap))
	out:[N]f32
	for i in 0..<N {
		out[i] = ui_cue_map_val_time(t, tStart, tEnd, start[i], end[i], curve)
	}
	return out
}
//value will be clamped between start and end
ui_cue_map :: proc{ui_cue_map_val, ui_cue_map_arr, ui_cue_map_val_time}

//Maps a value from its "last" value to a given target value over a given time period starting from the start time of the UI cue.
//The last, current, and target value is tracked internally. If a new target is given, these values are updated.
//The target value's bytes must be interpretable as an array of up to 4 f32s with the exception of colors and blends, which have special-case handling
//Can optionally set the cue to be triggered whenever the target is updated
//If the state has not been initialized yet, you can initialize it to the passed target value or to 0
//Can optionally ignore the passed target and just use the previously set target. Will not work if a previous target has not been set.
//Can optionally return the last value used in mapping, rather than the mapped value
ui_cue_map_stateful :: proc(key:ImKey, duration:f32, target:$T, curve:^Curve=nil, cueOnTargetChange:=true, initializeToTarget:=true, ignorePassedTarget:=false, stateKey:ImKey=#caller_location, cueMap:^UICueMap=nil, returnLast:=false)->T{
	cueMap := cueMap
	if cueMap == nil do cueMap = &ui.cues

	id := imkey_to_string(key)
	
	cue,ok:=&cueMap[id]
	if !ok {
		if cueOnTargetChange{
			ui_cue(id, cueMap)
			cue = &cueMap[id]
		}
		else do return target
	}

	when T == Color{N :: 3; newTarget := color_to_f(target)}
	else when T == Blend{N :: 4; newTarget := blend_to_f(target)}
	else when T == Rect{N :: 4; newTarget := [4]f32{target.x, target.y, rect_get_right_f(target), rect_get_bottom_f(target)}}
	else{
		N :: size_of(T)/size_of(f32); #assert(N<=4)
		newTarget := transmute([N]f32)target
	}
	A :: [N]f32

	stateId := imkey_to_string(stateKey)
	if len(cue.state) == 0 do init(&cue.state, cueMap.allocator)

	initState := stateId not_in cue.state
	if initState do strmap_set(&cue.state, stateId, UICueState{})
	
	statePtr := &cue.state[stateId]
	last := cast(^A)&statePtr.last
	current := cast(^A)&statePtr.current
	lastTarget := cast(^A)&statePtr.target

	if initState && initializeToTarget{
		last^ = newTarget
		current^ = newTarget
		lastTarget^ = newTarget
		return target
	}

	if ignorePassedTarget do newTarget = lastTarget^

	if newTarget != lastTarget^{
		last^ = current^
		lastTarget^ = newTarget
		if cueOnTargetChange do ui_cue(id, cueMap)
	}

	current^ = ui_cue_map(id, 0, duration, last^, newTarget, curve, cueMap)

	out := returnLast?last:current

	when T == Color{return color(out^)}
	else when T == Blend{return blend_from_f(out^)}
	else when T == Rect{points:=out^; return rect_make_points_f(points.x, points.y, points.z, points.w)}
	else{ return (cast(^T)out)^}
}

ui_cue_map_reversible_val :: proc(key:ImKey, duration:f32, start,end:f32, curve:^Curve=nil, cueMap:^UICueMap=nil) -> f32{
	id := imkey_to_string(key)
	tSinceUpdate := ui_cue_time(id, true, cueMap)
	mappedVal:f32
	if tSinceUpdate >= 1 do mappedVal = lerp(end, start, f32(tSinceUpdate)/duration, curve)
	else do mappedVal = lerp(start, end, f32(ui_cue_time(id, false, cueMap))/duration, curve)
	return clamp(mappedVal, min(start,end), max(start,end))
}
ui_cue_map_reversible_arr :: proc(key:ImKey, duration:f32, start,end:[$N]f32, curve:^Curve=nil, cueMap:^UICueMap=nil) -> [N]f32{
	id := imkey_to_string(key)
	out:[N]f32
	for i in 0..<N {
		out[i] = ui_cue_map_reversible_val(id, duration, start[i], end[i], curve, cueMap)
	}
	return out
}
ui_cue_map_reversible :: proc{ui_cue_map_reversible_val, ui_cue_map_reversible_arr}

ui_highlight :: proc(highlight:Maybe(Rect)=nil, stageCoords:=false){
	ui_cue("highlightBox")
	_,ok := highlight.(Rect)
	stageCoords := ok?stageCoords:false

	if stageCoords != ui.highlight_box_stage_coords{
		if stageCoords do ui.highlight_box_current.pos += stage_camera_pos()
		else do ui.highlight_box_current.pos -= stage_camera_pos()
		ui.highlight_box_stage_coords = stageCoords
	}
	ui.highlight_box_target = highlight
}	

_ui_system_draw :: proc(){

	//highlight
	travelTime :: 6
	drawRect:Rect
	target,targetSet := ui.highlight_box_target.(Rect)
	
	if !targetSet do target = Rect{-1,DISPLAY_SIZE+2}

	drawRect = Rect{
		ui_cue_map("highlightBox", 0, travelTime, ui.highlight_box_current.pos, target.pos),
		ui_cue_map("highlightBox", 0, travelTime, ui.highlight_box_current.size, target.size)
	}

	if ui_cue_time("highlightBox") >= travelTime do ui.highlight_box_current = target

	if ui.highlight_box_stage_coords do drawRect.pos -= stage_camera_pos()

	if !display.hd_enabled{
		if targetSet || drawRect != target do draw_letterbox(drawRect, COLOR_BLACK, 0.667)
		
		//save indicator
		dur :: 60
		t := ui_cue_time("saveIndicator")
		if t < dur && !display.hd_enabled{
			if t <= sprite_duration(sp.shineAnimated24px) do sprite_draw(sp.shineAnimated24px, DISPLAY_SIZE - {50, 12}, sprite_frame_get(sp.shineAnimated24px, f32(t), true))
			tPos := DISPLAY_SIZE - {ui_cue_map("saveIndicator", 0, 50, 10, 0, cu.popIn)+2, 5}
			tAlpha := ui_cue_map("saveIndicator", 0, dur, 0, 1, cu.arc)
			text := dialogue_line(di.rest, "saved")
			text_draw(text, tPos+1, COLOR_BLACK, tAlpha, fo.fairfax__12, 1)
			text_draw(text, tPos, COLOR_WHITE, tAlpha, fo.fairfax__12, 1)
		}
	}
}