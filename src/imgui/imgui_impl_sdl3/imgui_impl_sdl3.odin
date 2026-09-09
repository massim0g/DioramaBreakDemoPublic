package imgui_impl_sdl3

import sdl "../../sdl3"

when      ODIN_OS == .Windows { foreign import lib "../imgui_windows_x64.lib" }
else when ODIN_OS == .Linux   { foreign import lib "../imgui_linux_x64.a" }
else when ODIN_OS == .Darwin  {
	when ODIN_ARCH == .amd64 { foreign import lib "../imgui_darwin_x64.a" } else { foreign import lib "../imgui_darwin_arm64.a" }
}

// imgui_impl_sdl3.h
// Last checked `v1.92.8-docking` (2a1b69f)
@(link_prefix="ImGui_ImplSDL3_")
foreign lib {
	InitForOpenGL :: proc(window: ^sdl.Window, sdl_gl_context: rawptr) -> bool ---
	InitForVulkan :: proc(window: ^sdl.Window) -> bool ---
	InitForD3D :: proc(window: ^sdl.Window) -> bool ---
	InitForMetal :: proc(window: ^sdl.Window) -> bool ---
	InitForSDLRenderer :: proc(window: ^sdl.Window, renderer: ^sdl.Renderer) -> bool ---
	InitForSDLGPU :: proc(window: ^sdl.Window) -> bool ---
	InitForOther :: proc(window: ^sdl.Window) -> bool ---
	Shutdown :: proc() ---
	NewFrame :: proc() ---
	ProcessEvent :: proc(event: ^sdl.Event) -> bool ---

	// Gamepad selection automatically starts in AutoFirst mode, picking first available SDL_Gamepad. You may override this.
	// When using manual mode, caller is responsible for opening/closing gamepad.
	SetGamepadMode :: proc(mode: GamepadMode, manual_gamepads_array: [^]^sdl.Gamepad = nil, manual_gamepads_count := i32(-1)) ---

	// (Advanced, for X11 users) Override Mouse Capture mode. Mouse capture allows receiving updated mouse position after clicking inside our window and dragging outside it.
	// Having this 'Enabled' is in theory always better. But, on X11 if you crash/break to debugger while capture is active you may temporarily lose access to your mouse.
	// The best solution is to setup your debugger to automatically release capture, e.g. 'setxkbmap -option grab:break_actions && xdotool key XF86Ungrab' or via a GDB script. See #3650.
	// But you may independently decide on X11, when a debugger is attached, to set this value to MouseCaptureMode_Disabled.
	SetMouseCaptureMode :: proc(mode: MouseCaptureMode) ---
}

GamepadMode :: enum i32 { AutoFirst, AutoAll, Manual }
MouseCaptureMode :: enum { Enabled, EnabledAfterDrag, Disabled }
