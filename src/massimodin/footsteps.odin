package massimodin //@nested-tags:_components/

FootstepSurface :: enum{ //order should match that in footsteps audio event
	none,
	grass,
	stone,
	wood
}

FootstepSurfaceOverride :: struct{
	surface:FootstepSurface,
	mesh:Mesh
}

//Call every frame whenever footstep sounds have to be played, plays them at the correct interval based on move speed
footstep_sounds :: proc(sc:^StageCharacter, spatialize:=true){
	key := imkey_combine(&sc.base)
	ui_cue(key)
	freq := 24 //roundi(24*(1.5/moveSpeed))
	if ui_cue_time(key)%freq == freq-1{
		inst:AudioInstance
		if spatialize do inst = audioEmitter_play(sc.audioEmitter, au.footsteps)
		else do inst = audio_play(au.footsteps)
		audio_parameter_set(inst, "groundSurface", f32(int(stage_footstep_surface_get(sc.transform.pos))))
	}
}

stage_footstep_surface_get :: proc(p:Vec2) -> FootstepSurface{
	for override in stage.footstepSurfaceOverrides{
		if mesh_point_inside(override.mesh, p) do return override.surface
	}
	return stage.defaultFootstepSurface
}