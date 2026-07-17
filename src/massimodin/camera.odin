package massimodin //@nested-tags:engine/camera

CameraSystem :: struct{
	stack:[dynamic]Vec2,
	pos:[2]i32,
	tracking:[dynamic]CoRefEx(Transform),
	tracking_offset:Vec2,
	default_pan_cutscene_target:CameraPanTarget,
	default_pan_cutscene_duration:int,
	shakeRequests:[dynamic]CameraShakeRequest, //gets cleared in stage_load()
}
camera:^CameraSystem

CameraShakeRequest :: struct{
	timeRemaining:int, //in frames
	force:Vec2,
}

CameraPanTarget :: union{
	Vec2,
	^Transform,
	^StageCharacter,
	^StageEntity,
	string,
	[]^Transform
}

CAMERA_DEFAULT_TRACKING_OFFSET :: Vec2{0, -36}
CAMERA_SHAKE_MAX :f32: 12

_camera_system_init :: proc(){
	camera = new(CameraSystem)
	init(&camera.stack)
	init(&camera.shakeRequests)
}

camera_set :: proc(pos:Vec2){
	append(&camera.stack, pos)
	camera.pos = {i32(round(pos.x)), i32(round(pos.y))}
}

camera_tracking_set :: proc(tracking:..^Transform, offset:=CAMERA_DEFAULT_TRACKING_OFFSET){
	resize(&camera.tracking, len(tracking))
	for tr,i in tracking{
		camera.tracking[i] = crx(tr)
	}
	camera.tracking_offset = offset
}

//Gets the camera position as a Vec2 for setter functions, rather than the [2]i32 used for drawing
camera_pos :: #force_inline proc "contextless" () -> Vec2{
	return (len(camera.stack) > 0) ? peek(camera.stack) : Vec2(camera.pos)
}

camera_reset :: proc(resetCount:=1){
	assert(len(camera.stack)>=resetCount, "Tried to reset camera with no camera set!")
	for i in 0..<resetCount{
		pop(&camera.stack)
	}
	
	if(len(camera.stack) > 0){
		lastPos := peek(camera.stack)
		camera.pos = {i32(round(lastPos.x)), i32(round(lastPos.y))}
	}
	else do camera.pos = {0,0}
}

camera_clear :: proc(){
	clear(&camera.stack)
	camera.pos = {0,0}
}

camera_rect :: proc() -> Rect{
	if len(camera.stack) == 0 do return Rect{0, display_size()}
	return Rect{peek(camera.stack), display_size()}
}

camera_shake :: proc(duration:int, force:Vec2){
	append(&camera.shakeRequests, CameraShakeRequest{
		duration,
		force,
	})
}


//Pans the camera to a Vec2 position or a transform (or stage character's transform).
//If panning to a transform, will pan to that transform's position + the default tracking offset, and set it as the new tracking target.
//If panning to a Vec2 position, disables tracking.
camera_pan_to_seq :: proc(target:CameraPanTarget, panDuration:int=48, curve:=cu.smooth, key:ImKey=#caller_location) -> bool{
	targetPos:Vec2
	tracking:[]^Transform
	
	switch t in target{
		case Vec2: targetPos = t
		case ^Transform:
			targetPos = t.pos + CAMERA_DEFAULT_TRACKING_OFFSET
			tracking = {t}
		case ^StageCharacter:
			targetPos = t.transform.pos + CAMERA_DEFAULT_TRACKING_OFFSET
			tracking = {t.transform}
		case ^StageEntity: targetPos = rect_center(stageEntity_draw_rect(t))
		case string:
			targetEnt := stageEntity_find(t)
			if targetEnt == nil{
				sc := scfind(t, true)
				assertf(sc != nil, "Could not find stage character or entity with id '%s' for camera pan!", t)
				targetPos = sc.transform.pos + CAMERA_DEFAULT_TRACKING_OFFSET
				tracking = {sc.transform}
			}
			else do targetPos = rect_center(stageEntity_draw_rect(targetEnt))
		case []^Transform:
			total:Vec2
			for tr in t{
				total += tr.pos + CAMERA_DEFAULT_TRACKING_OFFSET
			}
			targetPos = total/f32(len(t))
			tracking = t

	}
		
	startPos:^Vec2
	if seq_open(&startPos, key){

		if seq_cue(0){
			startPos^ = stage.camera_pos
			camera_tracking_set()
		}

		if seq_cue(0, panDuration){
			stage.target_camera_pos = seq_map(startPos^+DISPLAY_SIZE/2, targetPos, curve)
		}

		if seq_cue(panDuration){
			if tracking != nil do camera_tracking_set(tracking=tracking)
			return seq_close(.end)
		}

	}
	return seq_close()
}
cammove :: camera_pan_to_seq

//Pans the camera to a position, then back to where it was.
//Will preserve whatever was being tracked, but only single targets
camera_pan_to_and_back_seq :: proc(targetPos:Vec2, startDuration:int, holdDuration:int, endDuration:int, startCurve:=cu.easeInHeavy, endCurve:=cu.easeIn, key:ImKey=#caller_location) -> bool{
	state:^struct{
		startPos:Vec2,
		lastTracking:CoRefEx(Transform)
	}

	if seq_open(&state, key){

		if seq_cue(0){
			state.startPos = stage.target_camera_pos
			if len(camera.tracking) != 0 do state.lastTracking = camera.tracking[0]
			camera_tracking_set()
		}

		t:=startDuration
		if seq_cue(0, t){
			stage.target_camera_pos = seq_map(state.startPos, targetPos, startCurve)
		}

		t+=holdDuration

		if seq_cue(t, t+endDuration){
			returnPos := state.startPos
			if tracking := coget(state.lastTracking); tracking != nil do returnPos = tracking.pos + {0,tracking.z} + camera.tracking_offset
			stage.target_camera_pos = seq_map(targetPos, returnPos, endCurve)
		}
		t+=endDuration

		if seq_cue(t){
			append(&camera.tracking, state.lastTracking)
			return seq_close(.end)
		}

	}
	return seq_close()
}

camera_update_position :: proc(){
	if len(camera.tracking) != 0 && !debug_free_cam_enabled(){
		total:Vec2
		#reverse for ref,i in camera.tracking{
			tr := coget(ref)
			if tr == nil do unordered_remove(&camera.tracking, i)
			else do total += tr.pos + {0, tr.z} + camera.tracking_offset 
		}
		if len(camera.tracking) != 0 do stage.target_camera_pos = total/f32(len(camera.tracking)) 
	}
	stage.camera_pos = round(stage.target_camera_pos) - display_size()/2
	if !DEBUG || (debug.freeCamSpeed == 0 && !stage_edit.enabled) do stage.camera_pos = clamp(stage.camera_pos, stage.bounds.pos, rect_get_bottom_right_f(stage.bounds) - display_size())
}


_camera_system_update :: proc(){
	camera_update_position()

	shakeForce:Vec2
	#reverse for &request, i in camera.shakeRequests{
		if request.timeRemaining <= 0{
			unordered_remove(&camera.shakeRequests, i)
			continue
		}
		request.timeRemaining -= 1

		shakeForce += request.force
	}

	for &n, i in shakeForce{
		if n > 0 do n = clamp(n, 0.5, CAMERA_SHAKE_MAX)
		amount := random_range(n*0.5, n*2)
		stage.camera_pos[i] += choose([]f32{amount, -amount})
	}

}