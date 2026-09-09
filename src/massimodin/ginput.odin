package massimodin //@nested-tags:engine/input
//abstracted global input detection from all connected devices.

import "core:reflect"

GInputVerbArray :: [GInputVerb]bool
ginputs:^GInputVerbArray //initialized in _input_system_init

GInputVerb :: enum{ //not comprehensive, add verbs as needed
	up,
	left,
	down,
	right,
	upHeld,
	leftHeld,
	downHeld,
	rightHeld,

	confirm,
	confirmHeld,
	cancel,
	cancelHeld,
	option,
	optionHeld,
	extra,

	start,
	select,
	enter,

	lb,
	rb,
	lt,
	rt,
	ltHeld,
	rtHeld,

	upL,
	leftL,
	downL,
	rightL,
	upHeldL,
	leftHeldL,
	downHeldL,
	rightHeldL,

	upR,
	leftR,
	downR,
	rightR,
	upHeldR,
	leftHeldR,
	downHeldR,
	rightHeldR,
}

ginputs_reset :: proc(inp:^GInputVerbArray){
	for v in GInputVerb{
		inp[v] = false
	}
}

ginput_poll_device :: proc(deviceIndex:int, inp:^GInputVerbArray){
	assert(deviceIndex < GAMEPADS_CAP)
	if(deviceIndex == -1){
		inp[.upL] = inp[.upL]						|| key_pressed(Key.W)
		inp[.leftL] = inp[.leftL]					|| key_pressed(Key.A)
		inp[.downL] = inp[.downL]					|| key_pressed(Key.S)
		inp[.rightL] = inp[.rightL]					|| key_pressed(Key.D)
		inp[.upHeldL] = inp[.upHeldL]				|| key_held(Key.W)
		inp[.leftHeldL] = inp[.leftHeldL]			|| key_held(Key.A)
		inp[.downHeldL] = inp[.downHeldL]			|| key_held(Key.S)
		inp[.rightHeldL] = inp[.rightHeldL]			|| key_held(Key.D)
		inp[.upR] = inp[.upR]						|| key_pressed(Key.UP) 
		inp[.leftR] = inp[.leftR]					|| key_pressed(Key.LEFT)
		inp[.downR] = inp[.downR]					|| key_pressed(Key.DOWN)
		inp[.rightR] = inp[.rightR]					|| key_pressed(Key.RIGHT)
		inp[.upHeldR] = inp[.upHeldR]				|| key_held(Key.UP)
		inp[.leftHeldR] = inp[.leftHeldR]			|| key_held(Key.LEFT)
		inp[.downHeldR] = inp[.downHeldR]			|| key_held(Key.DOWN)
		inp[.rightHeldR] = inp[.rightHeldR]			|| key_held(Key.RIGHT)

		inp[.confirm] = inp[.confirm]				|| key_pressed(Key.K) 		|| key_pressed(Key.SPACE) 	|| key_pressed(Key.Z) 		|| mouse_pressed(.LEFT)
		inp[.confirmHeld] = inp[.confirmHeld]		|| key_held(Key.K) 			|| key_held(Key.SPACE) 		|| key_held(Key.Z) 			|| mouse_held(.LEFT)
		inp[.cancel] = inp[.cancel]					|| key_pressed(Key.J) 		|| key_pressed(Key.X) 	|| mouse_pressed(.RIGHT)
		inp[.cancelHeld] = inp[.cancelHeld]			|| key_held(Key.J) 			|| key_held(Key.X) 		|| mouse_held(.RIGHT)
		inp[.option] = inp[.option]					|| key_pressed(Key.LSHIFT) 	|| key_pressed(Key.RSHIFT)
		inp[.optionHeld] = inp[.optionHeld]			|| key_held(Key.LSHIFT) 	|| key_held(Key.RSHIFT)
		inp[.extra] = inp[.extra]					|| key_pressed(Key.LCTRL) 	|| key_pressed(Key.RCTRL) || mouse_pressed(.MIDDLE)
		inp[.start] = inp[.start]					|| key_pressed(Key.RETURN) 	|| key_pressed(.ESCAPE) 
		inp[.select] = inp[.select]					|| key_pressed(Key.LALT) 	|| key_pressed(Key.RALT)
		inp[.lb] = inp[.lb]							|| key_pressed(Key.Q)
		inp[.rb] = inp[.rb]							|| key_pressed(Key.E)
		
		//rt/lt are gamepad exclusive
		//lt = key_pressed(Key.A) || lt
		//rt = key_pressed(Key.D) || rt
	}
	else if(input.gamepads_open[deviceIndex] != nil){
		axes := input.gamepad_states_last_frame[deviceIndex].axes

		leftStickHorizontalMovementLastFrame := abs(axes.left.x) > abs(axes.left.y)
		leftStickCenteredLastFrameHorizontal := (abs(axes.left.x) <= GAMEPAD_DEFAULT_DEADZONE) || !leftStickHorizontalMovementLastFrame
		leftStickCenteredLastFrameVertical := (abs(axes.left.y) <= GAMEPAD_DEFAULT_DEADZONE) || leftStickHorizontalMovementLastFrame

		rightStickHorizontalMovementLastFrame := abs(axes.right.x) > abs(axes.right.y)
		rightStickCenteredLastFrameHorizontal := (abs(axes.right.x) <= GAMEPAD_DEFAULT_DEADZONE) || !rightStickHorizontalMovementLastFrame
		rightStickCenteredLastFrameVertical := (abs(axes.right.y) <= GAMEPAD_DEFAULT_DEADZONE) || rightStickHorizontalMovementLastFrame

		leftTriggerPressedLastFrame := axes.lt > GAMEPAD_DEFAULT_TRIGGER_DEADZONE
		rightTriggerPressedLastFrame := axes.rt > GAMEPAD_DEFAULT_TRIGGER_DEADZONE
		
		axes = input.gamepad_states[deviceIndex].axes

		leftStickOutsideDeadzoneHorizontal := abs(axes.left.x) > GAMEPAD_DEFAULT_DEADZONE
		leftStickOutsideDeadzoneVertical := abs(axes.left.y) > GAMEPAD_DEFAULT_DEADZONE
		leftStickCrossedCenterHorizontal := leftStickCenteredLastFrameHorizontal && leftStickOutsideDeadzoneHorizontal
		leftStickCrossedCenterVertical := leftStickCenteredLastFrameVertical && leftStickOutsideDeadzoneVertical
		
		rightStickOutsideDeadzoneHorizontal := abs(axes.right.x) > GAMEPAD_DEFAULT_DEADZONE
		rightStickOutsideDeadzoneVertical := abs(axes.right.y) > GAMEPAD_DEFAULT_DEADZONE
		rightStickCrossedCenterHorizontal := rightStickCenteredLastFrameHorizontal && rightStickOutsideDeadzoneHorizontal
		rightStickCrossedCenterVertical := rightStickCenteredLastFrameVertical && rightStickOutsideDeadzoneVertical
		
		leftStickHorizontalMovement := abs(axes.left.x) > abs(axes.left.y)
		rightStickHorizontalMovement := abs(axes.right.x) > abs(axes.right.y)

		inp[.upL] = inp[.upL] 					|| button_pressed(deviceIndex, Button.DPAD_UP)		|| (leftStickCrossedCenterVertical && axes.left.y < 0 && !leftStickHorizontalMovement) 	
		inp[.leftL] = inp[.leftL] 				|| button_pressed(deviceIndex, Button.DPAD_LEFT)	|| (leftStickCrossedCenterHorizontal && axes.left.x < 0 && leftStickHorizontalMovement) 
		inp[.downL] = inp[.downL] 				|| button_pressed(deviceIndex, Button.DPAD_DOWN)	|| (leftStickCrossedCenterVertical && axes.left.y > 0 && !leftStickHorizontalMovement) 	
		inp[.rightL] = inp[.rightL] 			|| button_pressed(deviceIndex, Button.DPAD_RIGHT)	|| (leftStickCrossedCenterHorizontal && axes.left.x > 0 && leftStickHorizontalMovement) 
		inp[.upHeldL] = inp[.upHeldL] 			|| button_held(deviceIndex, Button.DPAD_UP)			|| (leftStickOutsideDeadzoneVertical && axes.left.y < 0 /*&& !leftStickHorizontalMovement*/) 
		inp[.leftHeldL] = inp[.leftHeldL] 		|| button_held(deviceIndex, Button.DPAD_LEFT)		|| (leftStickOutsideDeadzoneHorizontal && axes.left.x < 0 /*&& leftStickHorizontalMovement*/) 
		inp[.downHeldL] = inp[.downHeldL] 		|| button_held(deviceIndex, Button.DPAD_DOWN)		|| (leftStickOutsideDeadzoneVertical && axes.left.y > 0 /*&& !leftStickHorizontalMovement*/) 
		inp[.rightHeldL] = inp[.rightHeldL] 	|| button_held(deviceIndex, Button.DPAD_RIGHT)		|| (leftStickOutsideDeadzoneHorizontal && axes.left.x > 0 /*&& leftStickHorizontalMovement*/) 

		inp[.upR] = inp[.upR] 					|| (rightStickCrossedCenterVertical && axes.right.y < 0 && !rightStickHorizontalMovement) 	
		inp[.leftR] = inp[.leftR] 				|| (rightStickCrossedCenterHorizontal && axes.right.x < 0 && rightStickHorizontalMovement) 
		inp[.downR] = inp[.downR] 				|| (rightStickCrossedCenterVertical && axes.right.y > 0 && !rightStickHorizontalMovement) 	
		inp[.rightR] = inp[.rightR] 			|| (rightStickCrossedCenterHorizontal && axes.right.x > 0 && rightStickHorizontalMovement) 
		inp[.upHeldR] = inp[.upHeldR] 			|| (rightStickOutsideDeadzoneVertical && axes.right.y < 0 /*&& !rightStickHorizontalMovement*/) 
		inp[.leftHeldR] = inp[.leftHeldR] 		|| (rightStickOutsideDeadzoneHorizontal && axes.right.x < 0 /*&& rightStickHorizontalMovement*/) 
		inp[.downHeldR] = inp[.downHeldR] 		|| (rightStickOutsideDeadzoneVertical && axes.right.y > 0 /*&& !rightStickHorizontalMovement*/) 
		inp[.rightHeldR] = inp[.rightHeldR] 	|| (rightStickOutsideDeadzoneHorizontal && axes.right.x > 0 /*&& rightStickHorizontalMovement*/) 
		
		when ON_SWITCH{
			confirmButton :: Button.EAST
			cancelButton :: Button.SOUTH
		}
		else{
			confirmButton :: Button.SOUTH
			cancelButton :: Button.EAST
		}

		inp[.confirm] = inp[.confirm] 			|| button_pressed(deviceIndex, confirmButton)
		inp[.confirmHeld] = inp[.confirmHeld] 	|| button_held(deviceIndex, confirmButton)
		inp[.cancel] = inp[.cancel] 			|| button_pressed(deviceIndex, cancelButton)
		inp[.cancelHeld] = inp[.cancelHeld] 	|| button_held(deviceIndex, cancelButton)
		inp[.option] = inp[.option] 			|| button_pressed(deviceIndex, Button.WEST)
		inp[.optionHeld] = inp[.optionHeld] 	|| button_held(deviceIndex, Button.WEST)
		inp[.extra] = inp[.extra] 				|| button_pressed(deviceIndex, Button.NORTH)
		inp[.start] = inp[.start] 				|| button_pressed(deviceIndex, Button.START)
		inp[.select] = inp[.select] 			|| button_pressed(deviceIndex, Button.BACK)
		inp[.lb] = inp[.lb] 					|| button_pressed(deviceIndex, Button.LEFT_SHOULDER)
		inp[.rb] = inp[.rb] 					|| button_pressed(deviceIndex, Button.RIGHT_SHOULDER)
		inp[.lt] = inp[.lt]						|| axes.lt > GAMEPAD_DEFAULT_TRIGGER_DEADZONE && !leftTriggerPressedLastFrame
		inp[.rt] = inp[.rt]						|| axes.rt > GAMEPAD_DEFAULT_TRIGGER_DEADZONE && !rightTriggerPressedLastFrame
		inp[.ltHeld] = inp[.ltHeld]				|| axes.lt > GAMEPAD_DEFAULT_TRIGGER_DEADZONE
		inp[.rtHeld] = inp[.rtHeld]				|| axes.rt > GAMEPAD_DEFAULT_TRIGGER_DEADZONE
	}
}

ginput_check_any :: proc(inp:^GInputVerbArray) -> bool{
	for v in GInputVerb{
		if(inp[v]) do return true
	}
	return false
}

ginputs_update :: proc(inp:^GInputVerbArray){
	newLastDevice := -2
	ginputs_reset(inp)
	ginput_poll_device(-1, inp)
	if(ginput_check_any(inp)) do newLastDevice = -1

	for i in 0..<GAMEPADS_CAP{
		ginput_poll_device(i, inp)
		if(newLastDevice == -2 && ginput_check_any(inp)) do newLastDevice = i
	}

	inp[.up] = inp[.upL] || inp[.upR]							 
	inp[.left] = inp[.leftL] || inp[.leftR]						
	inp[.down] = inp[.downL] || inp[.downR]						
	inp[.right] = inp[.rightL] || inp[.rightR]					
	inp[.upHeld] = inp[.upHeldL] || inp[.upHeldR]				
	inp[.leftHeld] = inp[.leftHeldL] || inp[.leftHeldR]			
	inp[.downHeld] = inp[.downHeldL] || inp[.downHeldR]			
	inp[.rightHeld] = inp[.rightHeldL] || inp[.rightHeldR]	

	if newLastDevice != -2 do input.last_device = newLastDevice
}