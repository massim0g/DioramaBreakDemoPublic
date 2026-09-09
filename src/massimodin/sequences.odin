package massimodin //@nested-tags:engine/sequences

//in bytes
SEQUENCE_ALLOCATORS_BLOCK_SIZE :: 128 

SequenceSystem :: struct{
	context_seq_stack:[dynamic]^Sequence,
	context_seq_pools_map:map[^Sequence]SequencePool, //store pointers to nested sequences, who are not reset until the base sequence ends 
	cue_prog:f32,
	_sequences_map:map[string]^Sequence,
	_component_sequence_keys:[dynamic]string, //these get cleaned up on stage unload
	_deferred_draws:[dynamic]SequenceDeferredDraw
}
seq:^SequenceSystem

_sequence_system_init :: proc(){
	seq = new(SequenceSystem)
	init(&seq.context_seq_stack)
	init(&seq.context_seq_pools_map)
	init(&seq._sequences_map)
}

Sequence :: struct{
	frame:int,
	ended:bool,
	state:rawptr
}

SequencePool :: struct{
	ended:[dynamic]^Sequence,
	allocator:Allocator,
	initialized:bool
}

SequenceDeferredDraw :: struct{
	callback:Callback,
	contextSeq:^Sequence,
	depth:f32,
	frame:int,   //captured at the seq_draw call, so callback-side seq_time/seq_cue match the update's numbering even though seq_close advances the sequence in between
	cueProg:f32, //allows you to use cue_map procs without resetting the cue inside the callback
	useStageCameraPos:bool
}

//returns whether the sequence has ended, only relevant for nested sequences
seq_open_with_state :: proc(statePtr:^^$T, key:ImKey=#caller_location) -> bool{
	keyString := imkey_to_string(key)

	if keyString not_in seq._sequences_map{
		if string_contains(keyString, "__CImK__") do append(&seq._component_sequence_keys, strmap_set(&seq._sequences_map, keyString, new(Sequence, stage.allocator)))
		else do strmap_set(&seq._sequences_map, keyString, new(Sequence))
	}

	newContext := seq._sequences_map[keyString]
	append(&seq.context_seq_stack, newContext)

	if len(seq.context_seq_stack) == 1 && !(newContext in seq.context_seq_pools_map){
		seq.context_seq_pools_map[newContext] = SequencePool{allocator=allocator_make(SEQUENCE_ALLOCATORS_BLOCK_SIZE)}
	}
	pool := &seq.context_seq_pools_map[seq.context_seq_stack[0]]

	if !pool.initialized{
		init(&pool.ended, pool.allocator)
		pool.initialized = true
	}

	if(statePtr != nil){
		seqState:^T
		if(newContext.state == nil){
			seqState = new(T, pool.allocator)
			newContext.state = seqState
		}
		else do seqState = cast(^T)newContext.state
		statePtr^ = seqState
	}

	return !newContext.ended
}
seq_open_no_state :: #force_inline proc(key:ImKey=#caller_location) -> bool{
	nilPtr:^^bool = nil
	return seq_open_with_state(nilPtr, key)
}
seq_open :: proc{seq_open_with_state, seq_open_no_state}

seq_allocator :: proc()->Allocator{
	return seq.context_seq_pools_map[seq.context_seq_stack[0]].allocator
}

//Sets the sequence context based on the source code location.
//If you need to access the same sequence in multiple places, you can pass a custom string key.

SeqCloseKind :: enum{
	normal, //reset sequence context and advance sequence frame
	end, //for when sequence is over, resets sequence context and frame and frees seqeuence allocator
	pause //for pausing sequence advancement (such as when waiting for a nested sequence to finish), resets context but doesn't advance frame timer
}
//Call at the end of a sequence block.
seq_close :: proc(kind:SeqCloseKind=.normal) -> (ended:bool){
	assert(len(seq.context_seq_stack) > 0, "Tried to close a sequence without any sequence open!")
	contextSeq := peek(seq.context_seq_stack)
	if contextSeq.ended do ended = true
	else{
		switch kind{
			case .normal:
				contextSeq.frame += 1
			case .end:
				endedPool := &seq.context_seq_pools_map[seq.context_seq_stack[0]]
				append(&endedPool.ended, contextSeq)
				contextSeq.ended = true
				if len(seq.context_seq_stack) == 1{
					for seq_ in endedPool.ended{ //reset all nested sequences
						seq_.frame = 0
						seq_.state = nil
						seq_.ended = false
					}
					free_all(endedPool.allocator)
					endedPool.initialized = false
				}
				ended = true
			case .pause: //do nothing
		}
	}

	pop(&seq.context_seq_stack)
	return
}

//opens and closes a sequence, resetting it and freeing its state if the call is not nested
seq_reset :: proc(key:ImKey){
	seq_open(key)
	seq_close(.end)
}

//returns true the first time it's called within a parent sequence, used to call one-off code 
seq_cue_context :: proc(key:ImKey=#caller_location) -> bool{
	if seq_open(key) do return seq_close(.end)
	seq_close()
	return false
}
seq_cue_point_f :: #force_inline proc(frame:f32) -> bool{
	return seq_cue_point_i(ceili(frame))
}
seq_cue_point_i :: proc(frame:int) -> bool{
	if len(seq.context_seq_stack) == 0{when DEBUG{panic("Cued seq with no seq context!")}else{return false}}
	inRange := peek(seq.context_seq_stack).frame == frame
	if(inRange) do seq.cue_prog = 1
	return inRange
}
seq_cue_range_i :: #force_inline proc(start,end:int) -> bool{
	return seq_cue_range_f(f32(start), f32(end))
}
seq_cue_range_f :: proc(start,end:f32) -> bool{
	if len(seq.context_seq_stack) == 0{when DEBUG{panic("Cued seq with no seq context!")}else{return false}}
	if(end <= start) do return seq_cue_point_f(start)
	frame := f32(peek(seq.context_seq_stack).frame)
	inRange := in_range(frame, start, end)
	if(inRange) do seq.cue_prog = (frame-start)/(end-start)
	return inRange
}
seq_cue_timestamp :: proc(t:^int, add:int)->bool{
	out := seq_cue_range_i(t^, t^+add)
	t^ += add
	return out
}
seq_cue :: proc{seq_cue_point_i, seq_cue_point_f, seq_cue_range_f, seq_cue_range_i, seq_cue_context, seq_cue_timestamp}

//after the first time this is called within a sequence with the condition set to true, continuously returns true
seq_latch :: proc(condition:bool, key:ImKey=#caller_location) -> bool{
	if seq_open(key){
		if condition do return seq_close(.end)
	}
	return seq_close()
}

//the first time this is reached in a sequence, records the current sequence time.
//Can then either continuously return that timestamp or a timer counting up from 0
seq_timestamp :: proc(staticTimestamp:=true, key:ImKey=#caller_location) -> int{
	assert(len(seq.context_seq_stack)>0, "Tried to get a sequence timestamp with no open sequence!")

	t_ := seq_time()
	t:^int
	if seq_open(&t, key){
		t^ = t_
		seq_close(.end)
	} 
	else do seq_close()

	return staticTimestamp ? t^ : t^-t_
}

seq_time :: proc() -> int{
	assert(len(seq.context_seq_stack) > 0, "Tried to get seq_time with no active sequence!")
	return peek(seq.context_seq_stack).frame
}

seq_time_above :: proc(t:^int, add:int=0) -> bool{
	out := seq_time() >= t^
	t^ += add
	return out
}

seq_wait :: proc(duration:int, key:ImKey=#caller_location) -> bool{
	if seq_open(key) && seq_cue(duration) do return seq_close(.end)
	return seq_close()
}

seq_map_val :: #force_inline proc "contextless" (start,end:f32, curve:^Curve=nil)->f32{
	return (curve != nil) ? lerp_val_curve(start, end, seq.cue_prog, curve) : lerp_val(start, end, seq.cue_prog)
}
seq_map_arr :: #force_inline proc "contextless" (start,end:[$N]f32, curve:^Curve=nil) -> [N]f32{
	return (curve != nil) ? lerp_arr_curve(start, end, seq.cue_prog, curve) : lerp_arr(start, end, seq.cue_prog)
}
seq_map :: proc{seq_map_val, seq_map_arr}

//Defers a draw call to draw on top of the stage (and most UI, though not dialogue).
//Will keep sequence context, including the frame the call was made on.
//DO NOT CALL ON THE SAME FRAME THE SEQUENCE CLOSES. todo: clean up the deferred draws when the sequence ends for safety?
seq_draw :: proc(callback:Callback, depth:DepthUnion=.seqDraws, useStageCameraPos:Maybe(bool)=nil){
	d := depthUnion_depth(depth)
	append(&seq._deferred_draws, SequenceDeferredDraw{
		callback,
		peek(seq.context_seq_stack),
		d,
		peek(seq.context_seq_stack).frame,
		seq.cue_prog,
		useStageCameraPos.? or_else d > layer_depth(.ui)
	})
}

//Runs a deferred draw callback with its sequence context, captured frame and cue progress restored. Cameras are the caller's job.
_sequence_deferred_draw_call :: proc(dd:SequenceDeferredDraw){
	append(&seq.context_seq_stack, dd.contextSeq)
	storedFrame := dd.contextSeq.frame
	dd.contextSeq.frame = dd.frame
	seq.cue_prog = dd.cueProg
	callback_call(dd.callback)
	dd.contextSeq.frame = storedFrame
	pop(&seq.context_seq_stack)
}

//draws all deferred draws then clears the buffer
_sequence_deferred_draws_draw :: proc(){
	if len(seq._deferred_draws) == 0 do return

	for &dd in seq._deferred_draws{
		render_depth(dd.depth)
		camera_set(dd.useStageCameraPos ? stage_camera_pos() : Vec2{})
		_sequence_deferred_draw_call(dd)
	}
	camera_reset(len(seq._deferred_draws))
	clear(&seq._deferred_draws)
}

