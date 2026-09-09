package massimodin //@nested-tags:engine/camera

CameraSystem :: struct{
	tracking:[dynamic]CameraTrackingTarget,
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

CameraTrackingTarget :: union{
	Vec2,
	CoRefEx(Transform),
	CoRefEx(Mover)
}

CAMERA_DEFAULT_TRACKING_OFFSET :: Vec2{0, -36}
CAMERA_SHAKE_MAX :f32: 12

_camera_system_init :: proc(){
	camera = new(CameraSystem)
	init(&camera.shakeRequests)
}

//camera settings do not interact with depth-sorted render, they will carry through render_depth calls
camera_set :: proc(pos:Vec2){
	append(&render._entries, RenderEntryCameraSet{round(pos)})
}

camera_tracking_set :: proc(tracking:..CameraPanTarget, offset:=CAMERA_DEFAULT_TRACKING_OFFSET){
	clear(&camera.tracking)
	reserve(&camera.tracking, len(tracking))
	for target,i in tracking{
		switch tr in target{
			case Vec2:  append(&camera.tracking, tr)
			case ^Transform: append(&camera.tracking, crx(tr))
			case ^StageCharacter: append(&camera.tracking, crx(tr.mover))
			case ^StageEntity: append(&camera.tracking, crx(tr.transform))
			case string:
				sc := scfind(tr, true)
				if sc == nil{
					targetEnt := stageEntity_find(tr)
					assertf(targetEnt != nil, "Could not find stage character or entity with id '%s' for camera tracking set!", tr)
					append(&camera.tracking, crx(targetEnt.transform))
				}
				else do append(&camera.tracking, crx(sc.mover))
			case []^Transform: for transform in tr do append(&camera.tracking, crx(transform))
		}
		
	}
	camera.tracking_offset = offset
}

camera_tracking_target_get_pos :: proc(tracking:CameraTrackingTarget) -> (pos:Vec2, found:bool){
	switch tr in tracking{
		case Vec2: return tr, true
		case CoRefEx(Transform): if t := coget(tr); t != nil do return t.pos + {0,t.z}, true
		case CoRefEx(Mover): if m := coget(tr); m != nil do return m.transform.pos + {0,m.transform.z} + m.fractionalSpeed.xy + {0, m.fractionalSpeed.z}, true
	}
	return 0, false
}

camera_reset :: proc(resetCount:=1){
	append(&render._entries, RenderEntryCameraPop{resetCount})
}

camera_clear :: proc(){
	append(&render._entries, RenderEntryCameraClear{})
}

camera_shake :: proc(duration:int, force:Vec2){
	append(&camera.shakeRequests, CameraShakeRequest{
		duration,
		force,
	})
}


//Pans the camera to a Vec2 position or a transform (or stage character's transform).
//If panning to a transform or character, will pan to that transform's position + the default tracking offset, and set it as the new tracking target.
//If panning to a Vec2 position, disables tracking.
camera_pan_to_seq :: proc(target:CameraPanTarget, panDuration:int=48, curve:=cu.smooth, key:ImKey=#caller_location) -> bool{
	targetPos:Vec2
	tracking:CameraPanTarget
	
	switch t in target{
		case Vec2: targetPos = t
		case ^Transform:
			targetPos = t.pos + CAMERA_DEFAULT_TRACKING_OFFSET
			tracking = t
		case ^StageCharacter:
			targetPos = t.transform.pos + CAMERA_DEFAULT_TRACKING_OFFSET
			tracking = t
		case ^StageEntity: targetPos = rect_center(stageEntity_draw_rect(t))
		case string:
			sc := scfind(t, true)
			if sc == nil{
				targetEnt := stageEntity_find(t)
				assertf(targetEnt != nil, "Could not find stage character or entity with id '%s' for camera pan!", t)
				targetPos = rect_center(stageEntity_draw_rect(targetEnt))
			}
			else{
				targetPos = sc.transform.pos + CAMERA_DEFAULT_TRACKING_OFFSET
				tracking = sc
			}
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
			if tracking != nil do camera_tracking_set(tracking)
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
		lastTracking:CameraTrackingTarget
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
			if trackingPos,ok := camera_tracking_target_get_pos(state.lastTracking);ok do returnPos = trackingPos + camera.tracking_offset
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
		#reverse for tracking,i in camera.tracking{
			trackingPos,found := camera_tracking_target_get_pos(tracking)
			if !found do unordered_remove(&camera.tracking, i)
			else do total += trackingPos + camera.tracking_offset
		}
		if len(camera.tracking) != 0 do stage.target_camera_pos = total/f32(len(camera.tracking)) 
	}
	
	camPos := stage.target_camera_pos - display_size()/2
	if !DEBUG || (debug.freeCamSpeed == 0 && !stage_edit.enabled) do camPos = clamp(camPos, stage.bounds.pos, rect_get_bottom_right_f(stage.bounds) - display_size())
	stage.camera_pos, stage.camera_pos_subpixel = split(camPos)
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