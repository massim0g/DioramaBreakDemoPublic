package massimodin //@nested-tags:engine/audio

import "base:runtime"
import "core:mem"
import fmcore "../fmod/core"
import fm "../fmod/studio"
import "core:os"

AudioEvent :: ^fm.EVENTDESCRIPTION
AudioInstance :: ^fm.EVENTINSTANCE

AudioSystem :: struct{
	_system:^fm.SYSTEM,
	_banks_map:map[string]^fm.BANK,
	_events_map:map[string]AudioEvent,
	_instances_playing:[dynamic]AudioInstance,

	background:[dynamic]AudioInstance,
	music:AudioInstance,

	capture_active:bool,
	capture_file:^os.File,
	capture_path:string,
	capture_sample_rate:i32,
	capture_channels:i32,
	capture_frames_written:i64,
	capture_dsp:^fmcore.DSP,
}
audio:^AudioSystem

_audio_system_init :: proc(){
	audio = new(AudioSystem)
	init(&audio._banks_map, assets.allocator)
	init(&audio._events_map, assets.allocator)
	init(&audio._instances_playing)
	init(&audio.background)
	au = new(AudioIDs, assets.allocator)
	
	fm.System_Create(&audio._system, fmcore.VERSION)
	fm.System_Initialize(audio._system, 100, fm.INIT_NORMAL, fmcore.INIT_NORMAL, nil)
}

_audio_system_update :: proc(){
	//trace("Audio Update")
	playbackState:fm.PLAYBACK_STATE
	for i:=0; i<len(audio._instances_playing);{
		instance := audio._instances_playing[i]
		fm.EventInstance_GetPlaybackState(instance, &playbackState)
		if(playbackState == .PLAYBACK_STOPPED){
			fm.EventInstance_Release(instance)
			unordered_remove(&audio._instances_playing, i)
		} 
		else do i+=1
	}

	//update 3d listener
	pos := stage.target_camera_pos
	pos.y -= camera.tracking_offset.y
	fm.System_SetListenerAttributes(audio._system, 0, 
		audio_pos_to_3d_attrs({pos,camera.tracking_offset.y}), nil
	)

	fm.System_Update(audio._system)
}



audio_event_find :: proc(name:string) -> AudioEvent{
	return audio._events_map[name]
}

audio_play :: proc(event:AudioEvent) -> (out:AudioInstance){
	assert(event != nil, "Audio event was invalid or not yet loaded!")
	fm.EventDescription_CreateInstance(event, &out)
	fm.EventInstance_Start(out)
	append(&audio._instances_playing, out)
	return
}

audio_stop_instance :: #force_inline proc(instance:AudioInstance, allowFade:=false){
	fm.EventInstance_Stop(instance, allowFade ? .STOP_ALLOWFADEOUT : .STOP_IMMEDIATE)
}
audio_stop_event :: proc(event:AudioEvent, allowFade:=false){
	for instance in audio._instances_playing{
		if audio_instance_event(instance) == event do audio_stop_instance(instance, allowFade)
	}
}
audio_stop :: proc{audio_stop_instance, audio_stop_event}

audio_stop_all :: proc(allowFade:=false){
	for instance in audio._instances_playing{
		audio_stop_instance(instance, allowFade)
	}
	clear(&audio._instances_playing)
	clear(&audio.background)
	audio.music = nil
}


audio_pause :: proc(instance:AudioInstance, pause:bool){
	fm.EventInstance_SetPaused(instance, b32(pause))
}

audio_pause_all :: proc(paused:bool){
	for instance in audio._instances_playing{
		audio_pause(instance, paused)
	}
}

audio_paused :: proc(instance:AudioInstance) -> bool{
	out:b32
	fm.EventInstance_GetPaused(instance, &out)
	return bool(out)
}

audio_instance_event :: #force_inline proc "contextless"(instance:AudioInstance) -> AudioEvent{
	if instance == nil do return nil
	out:AudioEvent
	fm.EventInstance_GetDescription(instance, &out)
	return out
}

audio_volume_set_instance :: proc(instance:AudioInstance, volume:f32){
	fm.EventInstance_SetVolume(instance, volume)
}
audio_volume_set_event :: proc(event:AudioEvent, volume:f32){
	for instance in audio._instances_playing{
		if audio_instance_event(instance) == event do fm.EventInstance_SetVolume(instance, volume)
	}
}
audio_volume_set_group :: proc(busName:string, volume:f32){
	bus:^fm.BUS
	fm.System_GetBus(audio._system, cformat("bus:/%s", busName), &bus)
	fm.Bus_SetVolume(bus, volume)
}
audio_volume_set_master :: proc(volume:f32){
	bus:^fm.BUS
	fm.System_GetBus(audio._system, "bus:/", &bus)
	fm.Bus_SetVolume(bus, volume)
}
audio_volume_set :: proc{audio_volume_set_instance, audio_volume_set_event, audio_volume_set_group, audio_volume_set_master}

audio_pitch_set_instance :: proc(instance:AudioInstance, pitch:f32){
	fm.EventInstance_SetPitch(instance, pitch)
}
audio_pitch_set_event :: proc(event:AudioEvent, pitch:f32){
	for instance in audio._instances_playing{
		if audio_instance_event(instance) == event do fm.EventInstance_SetPitch(instance, pitch)
	}
}
audio_pitch_set :: proc{audio_pitch_set_instance, audio_pitch_set_event}

audio_playing_event :: proc(event:AudioEvent) -> bool{
	playbackState:fm.PLAYBACK_STATE
	for inst in audio._instances_playing{
		fm.EventInstance_GetPlaybackState(inst, &playbackState)
		if playbackState == .PLAYBACK_PLAYING && audio_instance_event(inst) == event{
			return true
		}
	}
	return false
}
audio_playing_instance :: proc(instance:AudioInstance) -> bool{
	for inst in audio._instances_playing{
		if inst == instance do return true
	}
	return false
}
audio_playing :: proc{audio_playing_event, audio_playing_instance}

music_set :: proc(mus:AudioEvent, allowFade:=true){
	if mus == nil{
		if audio.music != nil{
			audio_stop(audio.music, allowFade)
			audio.music = nil
		}
		return
	}

	if mus != audio_instance_event(audio.music){
		if audio.music != nil do audio_stop(audio.music, allowFade)
		audio.music = audio_play(mus)
	}
}

//also stops music
audio_background_stop :: proc(allowFade:=true){
	for instance in audio.background{
		audio_stop(instance, allowFade)
	} 
	clear(&audio.background)

	music_set(nil, allowFade)
}

audio_background_set :: proc(events:[]AudioEvent, allowFade:=true){
	#reverse for instance, i in audio.background{
		if !contains(events, audio_instance_event(instance)){
			audio_stop_instance(instance, allowFade)
			unordered_remove(&audio.background, i)
		}
	}
	
	for ev in events{
		exists:=false
		for instance in audio.background{
			if audio_instance_event(instance) == ev{
				exists = true
				break
			}
		}

		if !exists{
			append(&audio.background, audio_play(ev))
		}
	}
}

audio_background_add :: proc(event:AudioEvent){
	if !audio_playing(event){
		instance := audio_play(event)
		append(&audio.background, instance)
	}
}
audio_background_remove :: proc(event:AudioEvent, allowFade:=true){
	#reverse for instance,i in audio.background{
		if audio_instance_event(instance) == event{
			unordered_remove(&audio.background, i)
			audio_stop_instance(instance, allowFade)
		}
	}
}

audio_parameter_set_event :: proc(event:AudioEvent, parameterName:string, val:f32, ignoreSeekSpeed:=false){
	for instance in audio._instances_playing{
		if audio_instance_event(instance) == event do audio_parameter_set_instance(instance, parameterName, val, ignoreSeekSpeed)
	}
}
audio_parameter_set_instance :: proc(instance:AudioInstance, parameterName:string, val:f32, ignoreSeekSpeed:=false){
	fm.EventInstance_SetParameterByName(instance, string_to_cstring(parameterName, context.temp_allocator), val, b32(ignoreSeekSpeed))
}
audio_parameter_set_global :: proc(parameterName:string, val:f32, ignoreSeekSpeed:=false){
	fm.System_SetParameterByName(audio._system, string_to_cstring(parameterName, context.temp_allocator), val, b32(ignoreSeekSpeed))
}
audio_parameter_set :: proc{audio_parameter_set_instance, audio_parameter_set_event, audio_parameter_set_global}

audio_parameter_get_event :: proc(event:AudioEvent, parameterName:string) -> (current:f32, target:f32){
	for instance in audio._instances_playing{
		if audio_instance_event(instance) == event do return audio_parameter_get_instance(instance, parameterName)
	}
	return
}
audio_parameter_get_instance :: proc(instance:AudioInstance, parameterName:string)->(current:f32, target:f32){
	fm.EventInstance_GetParameterByName(instance, string_to_cstring(parameterName, context.temp_allocator), &current, &target)
	return
}
audio_parameter_get_global :: proc(parameterName:string)->(current:f32, target:f32){
	fm.System_GetParameterByName(audio._system, string_to_cstring(parameterName, context.temp_allocator), &current, &target)
	return
}
audio_parameter_get :: proc{audio_parameter_get_instance, audio_parameter_get_event, audio_parameter_get_global}

//Convert game coordinates to FMOD 3D space.
//Game: +x right, +y down (depth), -z up (height). 1 game y = 2 real-world depth units.
//FMOD (right-handed): +x right, +y up, +z forward (into screen).
audio_pos_to_3d_attrs :: proc(pos:TransformCoords) -> fmcore._3D_ATTRIBUTES {
	scalingFactor :f32: 0.04 //for converting pixel distances to meters. based on pro being ~1.78m and 45px tall
	return {
		position = {pos.x * scalingFactor, -pos.z * scalingFactor, pos.y * 2 * scalingFactor},
		forward  = {0, 0, 1},
		up       = {0, 1, 0},
	}
}

//Play a sound at a world position
audio_play_at :: proc(event: AudioEvent, pos: Vec2, z: f32 = 0) -> AudioInstance {
	instance := audio_play(event)
	attrs := audio_pos_to_3d_attrs({pos, z})
	fm.EventInstance_Set3DAttributes(instance, &attrs)
	return instance
}

//Update the position of an already-playing 3D sound.
audio_pos_set :: proc(instance: AudioInstance, pos: Vec2, z: f32 = 0) {
	attrs := audio_pos_to_3d_attrs({pos, z})
	fm.EventInstance_Set3DAttributes(instance, &attrs)
}

audio_apply_settings :: proc(){
	audio_volume_set(settings.master_volume)
	audio_volume_set("DB_Music", settings.music_volume)
	audio_volume_set("DB_SFX", settings.sfx_volume)
	audio_volume_set("DB_Ambience", settings.ambience_volume)
}

//AUDIO CAPTURE PROCS
fm_capture_dsp_read :: proc "c"(
    dsp_state: ^fmcore.DSP_STATE,
    inbuffer: ^f32,
    outbuffer: ^f32,
    length: u32,
    inchannels: i32,
    outchannels: ^i32,
) -> fmcore.RESULT {
	context = runtime.default_context()
	frames := i32(length)
    total_samples := i32(length)*inchannels

    // tell FMOD how many channels we output
    outchannels^ = inchannels

    // Pass-through: out = in
    mem.copy(outbuffer, inbuffer, int(total_samples * size_of(f32)))

    if !audio.capture_active {
        return .OK
    }

    // remember actual channel count for mux
    audio.capture_channels = inchannels

	os.write(audio.capture_file, mem.ptr_to_bytes(inbuffer, int(total_samples)))

    // Interleaved write: [frame0 ch0][frame0 ch1]...[frameN chX]
    // for frame in 0..<frames{
    //     for c in 0..<inchannels {
    //         sample := mem.ptr_offset(inbuffer, frame*inchannels + c)
	// 		os.write(audio.capture_file, mem.ptr_to_bytes(sample, 1))
    //     }
    // }

    audio.capture_frames_written += i64(length)

    return .OK
}

audio_capture_start :: proc(path: string) -> bool {
    if audio.capture_active {
        return false
    }

    // Open WAV file
    file, err := os.open(path, {.Create, .Trunc, .Read, .Write})
    if err != nil {
        print("Warning: audio capture failed to open file")
        return false
    }

    // Get low-level FMOD system from Studio system
    low_level : ^fmcore.SYSTEM
    fm.System_GetCoreSystem(audio._system, &low_level)

    // Query software format for sample rate (and optionally channels)
    sample_rate  : i32
    speaker_mode : fmcore.SPEAKERMODE
    raw_speakers : i32
    fmcore.System_GetSoftwareFormat(low_level, &sample_rate, &speaker_mode, &raw_speakers)
	
    // Describe the DSP
    desc := fmcore.DSP_DESCRIPTION{
		version          = 0x00010000,
		numinputbuffers  = 1,
		numoutputbuffers = 1,
		read             = fm_capture_dsp_read

	}
	copy(desc.name[:], "CaptureDSP")

    // Create DSP
    dsp : ^fmcore.DSP
    fmcore.System_CreateDSP(low_level, desc, &dsp)

    // Attach to master channel group tail so we see final mix
    master_group : ^fmcore.CHANNELGROUP
    fmcore.System_GetMasterChannelGroup(low_level, &master_group)
    fmcore.ChannelGroup_AddDSP(master_group, i32(fmcore.CHANNELCONTROL_DSP_INDEX.CHANNELCONTROL_DSP_TAIL), dsp)

    // Store state
    audio.capture_active = true
    audio.capture_file = file
    audio.capture_sample_rate = sample_rate
    audio.capture_frames_written = 0
    audio.capture_dsp = dsp

    print("Audio capture started")
    return true
}

audio_capture_stop :: proc() {
    if !audio.capture_active do return

    audio.capture_active = false

    // Remove DSP from signal chain, then release
    if audio.capture_dsp != nil {
        low_level : ^fmcore.SYSTEM
        fm.System_GetCoreSystem(audio._system, &low_level)
        master_group : ^fmcore.CHANNELGROUP
        fmcore.System_GetMasterChannelGroup(low_level, &master_group)
        fmcore.ChannelGroup_RemoveDSP(master_group, audio.capture_dsp)
        fmcore.DSP_Release(audio.capture_dsp)
        audio.capture_dsp = nil
    }

    // Close file
   	os.close(audio.capture_file)

    print("Audio capture stopped")
}