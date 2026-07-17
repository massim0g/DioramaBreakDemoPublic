#+feature using-stmt
package massimodin //@nested-tags:engine/input

import "../sdl2"
import "core:simd"
import "core:math/bits"

InputSystem :: struct{
	keyboard_state:#sparse[Key]bool,
	keyboard_state_last_frame:#sparse[Key]bool,
	_mouse_state:[MouseButton]bool,
	_mouse_state_last_frame:[MouseButton]bool,
	_mouse_window_position:[2]i32,
	_mouse_window_position_last:[2]i32,
	mouse_in_window:bool,
	mouse_scroll:int,
	gamepad_states:[GAMEPADS_CAP]GamepadState,
	gamepad_states_last_frame:[GAMEPADS_CAP]GamepadState,
	gamepads_open:[GAMEPADS_CAP]^sdl2.GameController,
	last_device:int
}
input:^InputSystem

_input_system_init :: proc(){
	input = new(InputSystem, os_allocator)
	ginputs = new(GInputVerbArray, os_allocator)
	input.last_device = -1
}


GAMEPAD_DEFAULT_DEADZONE :: 0.3
GAMEPAD_DEFAULT_TRIGGER_DEADZONE :: 0.5
GAMEPADS_CAP :: 4
Key :: sdl2.Scancode
Button :: sdl2.GameControllerButton

MouseButton :: enum{
	LEFT,
	RIGHT,
	MIDDLE,
	BUTTON_4,
	BUTTON_5
}

KeyMod :: enum{
	CTRL,
	ALT,
	SHIFT
}

GamepadAxes :: struct{
	left:Vec2,
	right:Vec2,
	lt:f32,
	rt:f32
}

GamepadState :: struct{
	buttons:[Button]bool,
	axes:GamepadAxes
}

GamepadDirectional :: enum{
	lStick,
	rStick,
	dpad
}

InputDeviceKind :: enum{
	keyboard,
	gamepad
}
InputDeviceKinds :: bit_set[InputDeviceKind]

//clear all input state
input_clear :: proc(){
	using input
	keyboard_state = #sparse[Key]bool{}
	keyboard_state_last_frame = #sparse[Key]bool{}
	_mouse_state = [MouseButton]bool{}
	_mouse_state_last_frame = [MouseButton]bool{}
	_mouse_window_position = [2]i32{}
	_mouse_window_position_last = [2]i32{}
	mouse_scroll = int{}
	gamepad_states = [GAMEPADS_CAP]GamepadState{}
	gamepad_states_last_frame = [GAMEPADS_CAP]GamepadState{}
	last_device = -1
}

//returns the kind of the last input device used
input_device :: #force_inline proc "contextless"() -> InputDeviceKind{
	return input.last_device == -1 ? .keyboard : .gamepad
}

input_gamepad_directional_angle :: proc(directional:=GamepadDirectional.lStick, lastFrame:=false) -> (angle:f32, outOfDeadzone:bool){
	if input.last_device == -1 do return 0, false
	states := lastFrame ? &input.gamepad_states_last_frame : &input.gamepad_states
	axes := input_gamepad_directional_axes(directional, lastFrame, true)
	return vec2_angle(axes), abs(axes.x) > GAMEPAD_DEFAULT_DEADZONE || abs(axes.y) > GAMEPAD_DEFAULT_DEADZONE
}

input_gamepad_directional_axes :: proc(directional:=GamepadDirectional.lStick, lastFrame:=false, ignoreDeadzone:=false) -> Vec2{
	if input.last_device == -1 do return 0
	states := lastFrame ? &input.gamepad_states_last_frame : &input.gamepad_states
	axes:Vec2
	switch directional{
		case .lStick: axes = states[input.last_device].axes.left
		case .rStick: axes = states[input.last_device].axes.right
		case .dpad: axes = Vec2{
			f32(int(button_held(input.last_device, .DPAD_RIGHT)) - int(button_held(input.last_device, .DPAD_LEFT))),
			f32(int(button_held(input.last_device, .DPAD_DOWN)) - int(button_held(input.last_device, .DPAD_UP))),
		}
	}
	if !ignoreDeadzone && vec2_mag_get(axes) <= GAMEPAD_DEFAULT_DEADZONE do return 0
	return axes
}

//call once per frame after polling/pumping sdl events to update inputs
_input_update_states :: proc(){ 
	using sdl2

	input.keyboard_state_last_frame = input.keyboard_state
	input._mouse_state_last_frame = input._mouse_state
	input.gamepad_states_last_frame = input.gamepad_states

	newKeyState := GetKeyboardState(nil)

	for sc in Scancode{
		input.keyboard_state[sc] = newKeyState[sc] > 0
	}

	input._mouse_window_position_last = input._mouse_window_position
	newMouseState := GetMouseState(&input._mouse_window_position.x, &input._mouse_window_position.y)
	
	input._mouse_state[.LEFT] = newMouseState & BUTTON_LMASK > 0
	input._mouse_state[.RIGHT] = newMouseState & BUTTON_RMASK > 0
	input._mouse_state[.MIDDLE] = newMouseState & BUTTON_MMASK > 0
	input._mouse_state[.BUTTON_4] = newMouseState & BUTTON_X1MASK > 0
	input._mouse_state[.BUTTON_5] = newMouseState & BUTTON_X2MASK > 0

	for i in 0..<GAMEPADS_CAP{
		gamepad := input.gamepads_open[i]
		if(gamepad == nil) do continue
		for b in GameControllerButton{
			input.gamepad_states[i].buttons[b] = GameControllerGetButton(gamepad, b) > 0
		}
		
		MAX_AXIS :: f32(bits.I16_MAX)
		input.gamepad_states[i].axes.left.x = f32(GameControllerGetAxis(gamepad, GameControllerAxis.LEFTX))/MAX_AXIS
		input.gamepad_states[i].axes.left.y = f32(GameControllerGetAxis(gamepad, GameControllerAxis.LEFTY))/MAX_AXIS
		input.gamepad_states[i].axes.right.x = f32(GameControllerGetAxis(gamepad, GameControllerAxis.RIGHTX))/MAX_AXIS
		input.gamepad_states[i].axes.right.y = f32(GameControllerGetAxis(gamepad, GameControllerAxis.RIGHTY))/MAX_AXIS
		input.gamepad_states[i].axes.lt = f32(GameControllerGetAxis(gamepad, GameControllerAxis.TRIGGERLEFT))/MAX_AXIS
		input.gamepad_states[i].axes.rt = f32(GameControllerGetAxis(gamepad, GameControllerAxis.TRIGGERRIGHT))/MAX_AXIS
	}
}

key_held :: proc(key:Key) -> bool{
	when DEBUG do if shell._is_open do return false
	return input.keyboard_state[key]
}
key_pressed :: proc(key:Key) -> bool{
	when DEBUG do if shell._is_open do return false
	return input.keyboard_state[key] && !input.keyboard_state_last_frame[key]
}
key_released :: proc(key:Key) -> bool{
	when DEBUG do if shell._is_open do return false
	return !input.keyboard_state[key] && input.keyboard_state_last_frame[key]
}
//Can be used to check for a key combo, e.g. Ctrl+Shift+K
key_combo_pressed :: proc(mods:bit_set[KeyMod], pressedKey:Key) -> bool{ 
	return key_mods_held(mods) && key_pressed(pressedKey)
}
key_mods_held :: proc(mods:bit_set[KeyMod]) -> bool{
	return (
		(.CTRL not_in mods || key_held(.LCTRL) || key_held(.RCTRL)) &&
		(.ALT not_in mods || key_held(.LALT) || key_held(.RALT)) &&
		(.SHIFT not_in mods || key_held(.LSHIFT) || key_held(.RSHIFT)))
}

mouse_held :: proc(button:MouseButton) -> bool{
	return input._mouse_state[button]
}
mouse_pressed :: proc(button:MouseButton) -> bool{
	return input._mouse_state[button] && !input._mouse_state_last_frame[button]
}
mouse_released :: proc(button:MouseButton) -> bool{
	return !input._mouse_state[button] && input._mouse_state_last_frame[button]
}
mouse_display_pos :: proc() -> Vec2{
	if input_device() == .gamepad do return -1
	out := Vec2{f32(input._mouse_window_position.x), f32(input._mouse_window_position.y)}
	out -= window_offset()
	out *= display_size()/(DISPLAY_SIZE*f32(settings.window_scale))
	return floor(out)
}
mouse_delta :: proc() -> Vec2{
	out := Vec2{f32(input._mouse_window_position.x - input._mouse_window_position_last.x), f32(input._mouse_window_position.y - input._mouse_window_position_last.y)}
	out *= display_size()/window_size()
	return out
}

button_held :: proc(gamepadIndex:int, button:Button) -> bool{
	return input.gamepad_states[gamepadIndex].buttons[button]
}
button_pressed :: proc(gamepadIndex:int, button:Button) -> bool{
	return input.gamepad_states[gamepadIndex].buttons[button] && !input.gamepad_states_last_frame[gamepadIndex].buttons[button]
}
button_released :: proc(gamepadIndex:int, button:Button) -> bool{
	return !input.gamepad_states[gamepadIndex].buttons[button] && input.gamepad_states_last_frame[gamepadIndex].buttons[button]
}




