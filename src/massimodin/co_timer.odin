#+feature using-stmt
package massimodin //@nested-tags:_components/
//@nested-tags:engine/time

TimerState :: enum{
	stopped,
	active,
	paused
}

Timer :: struct{
	using base:ComponentBase,
	counter:f32,
	state:TimerState,
	period:f32,
	autorepeat:bool,
	timeUnit:TimeUnit,
	destroyOnCallback:bool,
	callback:Callback,
}

timer_set_pause :: proc(t:^Timer, pause:bool){
	#partial switch(t.state){
		case .active:
		case .paused:
			t.state = pause ? .paused : .active
	}
}

timer_stop :: proc(t:^Timer){
	t.state = .stopped
	t.counter = -1
}

timer_start :: proc(t:^Timer, period:f32=-1){
	t.state = .active 
	if period != -1 do t.period = period
	t.counter = t.period
}

//returns how far the timer is from completion as a number between 0 (just started) and 1 (completed/inactive) based on its period
timer_progress :: proc(t:^Timer) -> f32{
	return (t.state == .active) ? 1 - t.counter/t.period : 1
}

timer_map :: proc(t:^Timer, start,end:f32, curve:^Curve=nil) -> f32{
	return (curve != nil) ? lerp_val_curve(start,end, timer_progress(t), curve) : lerp_val(start,end, timer_progress(t))
}

timer_add :: proc(t:^CoRef(Timer), period:f32=1, callback:Callback=nil, autorepeat:=false, timeUnit:=TIME_UNIT_DEFAULT){ //adds a timer using context
	coadd(t, true)
	t.period = period
	t.callback = callback
	t.timeUnit = timeUnit
}



_timer_process_event :: proc(base:^ComponentBase, event:Event, overrideDisabled:=false){
if(!overrideDisabled && event in base.disabledEvents) do return
last_context := entities.context_component
defer cowith(last_context)
cowith(base)
self := cast(^Timer)base
using self
#partial switch event{
case .init:
	counter = -1
	state = .stopped
	timeUnit = TIME_UNIT_DEFAULT
case .updateBegin: //@p 64
	if(state == .active){
		switch(timeUnit){
			case .frames: counter -= 1
			case .milliseconds: counter -= time.target_delta
			case .seconds: counter -= time.target_delta/1000
		}
		
		if(counter <= 0){
			if(autorepeat) do timer_start(self)
			else do timer_stop(self)
			if(destroyOnCallback) do entity_destroy(entity)
			callback_call(callback, false)
		}
	}

case .clean:
	callback_free(callback)
}}