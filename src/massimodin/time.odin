package massimodin //@nested-tags:engine/time

import time_ "core:time"
import "../sdl3"
import "core:math"
import "../tracy"

TimeSystem :: struct{
	frame:int, //current frame since game started
	target_delta:f32, //in ms
	_start_epoch:f64,
	frame_marks:[dynamic]TimeFrameMark,
	frame_marks_last_frame:[]TimeFrameMark,
	delayed_callbacks:[dynamic]DelayedCallback
}
time:^TimeSystem

_time_system_init :: proc(){
	time = new(TimeSystem)
	time._start_epoch = time_get_epoch_ms()
	time.target_delta = 1000/f32(FRAMERATE_TARGET)
	init(&time.delayed_callbacks, os_allocator)
	init(&time.frame_marks, os_allocator)
}

TimeUnit :: enum{
	seconds,
	milliseconds,
	frames
}

DelayedCallback :: struct{
	c:Callback,
	timeRemaining:int,
	calledStage:^Stage
}

TimeFrameMark :: struct{
	name:string,
	t:f32
}

FRAMERATE_TARGET :: 60
TIME_UNIT_DEFAULT :: TimeUnit.frames


time_get_epoch_ms :: proc "contextless" () -> f64{
	return f64(sdl3.GetPerformanceCounter())*1000/f64(sdl3.GetPerformanceFrequency())
}

@(disabled=tracy.TRACY_ENABLE)
time_frame_mark :: proc($name:string){
	append(&time.frame_marks, TimeFrameMark{name, time_get()})
}

@export
_time_frame_marks_end :: proc(frameStartTime:f32){
	if len(time.frame_marks) == 0{
		time.frame_marks_last_frame = nil
		return
	}

	time.frame_marks_last_frame = clone(time.frame_marks[:], context.temp_allocator)
	
	time.frame_marks_last_frame[0].t = frameStartTime
	for i in 0..<len(time.frame_marks_last_frame)-1{
		t := &time.frame_marks_last_frame[i].t
		t^ = time.frame_marks_last_frame[i+1].t - t^
	}
	last := peek_ptr(time.frame_marks_last_frame)
	last.t = time_get() - last.t

	clear(&time.frame_marks)
}

//Returns the number of milliseconds since the game started
@export
time_get :: proc "contextless" () -> f32{ 
	return f32(time_get_epoch_ms() - time._start_epoch)
}

//need to export this for main loop
@export 
_time_target_delta_get :: proc() -> f32{
	return time.target_delta
}

time_convert_f :: proc(t:f32, from:TimeUnit, to:TimeUnit) -> f32{
	switch(from){
		case .seconds:
			switch(to){
				case .seconds: return t
				case .milliseconds: return t*1000
				case .frames: return t*(1000/time.target_delta)
			}
		case .milliseconds:
			switch(to){
				case .seconds: return t/1000
				case .milliseconds: return t
				case .frames: return t/time.target_delta
			}
		case .frames:
			switch(to){
				case .seconds: return t/(1000/time.target_delta)
				case .milliseconds: return t*time.target_delta
				case .frames: return t
			}
	}
	unreachable()
}
time_convert_i :: #force_inline proc(t:int, from:TimeUnit, to:TimeUnit) -> f32{
	return time_convert_f(f32(t), from, to)
}
time_convert :: proc{time_convert_i, time_convert_f}

//sleep for a given duration in milliseconds. NOT ACCURATE.
sleep :: #force_inline proc "contextless" (d:int){
	time_.sleep(time_.Duration(d)*1_000_000)
}

_delta_time_target_refresh :: proc(){ //remains fixed, is based on the current monitor
	tolerance :: 2 //in fps
	targetFramerate :: f32(FRAMERATE_TARGET)
	displayMode := sdl3.GetDesktopDisplayMode(sdl3.GetDisplayForWindow(display._window))
	if(displayMode == nil || displayMode.refresh_rate == 0){
		time.target_delta = 1000/targetFramerate
		return
	}

	monitorFramerate := f32(displayMode.refresh_rate)

	multiplier := targetFramerate/monitorFramerate
	adjustedRate := (multiplier < 0.6) ? monitorFramerate/(math.round(1/multiplier)) : monitorFramerate*math.round(multiplier)
	if(adjustedRate >= targetFramerate - tolerance && adjustedRate <= targetFramerate+tolerance){
		time.target_delta = 1000/adjustedRate
	}
	else do time.target_delta = 1000/targetFramerate
}