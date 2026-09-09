package imgui_impl_sdlrenderer3 //note: upstream odin-imgui ships this file with a wrong package name (imgui_impl_sdlgpu3)

import imgui "../"
import sdl "../../sdl3"

when      ODIN_OS == .Windows { foreign import lib "../imgui_windows_x64.lib" }
else when ODIN_OS == .Linux   { foreign import lib "../imgui_linux_x64.a" }
else when ODIN_OS == .Darwin  {
	when ODIN_ARCH == .amd64 { foreign import lib "../imgui_darwin_x64.a" } else { foreign import lib "../imgui_darwin_arm64.a" }
}

// imgui_impl_sdlrenderer3.h
// Last checked `v1.92.8-docking` (dee5bf3)
@(link_prefix="ImGui_ImplSDLRenderer3_")
foreign lib {
	Init           :: proc(renderer: ^sdl.Renderer) -> bool ---
	Shutdown       :: proc() ---
	NewFrame       :: proc() ---
	RenderDrawData :: proc(draw_data: ^imgui.DrawData, renderer: ^sdl.Renderer) ---

	// Called by Init/NewFrame/Shutdown
	CreateDeviceObjects  :: proc() ---
	DestroyDeviceObjects :: proc() ---

	// (Advanced) Use e.g. if you need to precisely control the timing of texture updates (e.g. for staged rendering), by setting ImDrawData::Textures = nullptr to handle this manually.
	UpdateTexture :: proc(tex: ^imgui.TextureData) ---
}

// [BETA] Selected render state data shared with callbacks.
// This is temporarily stored in GetPlatformIO().Renderer_RenderState during the ImGui_ImplSDLRenderer3_RenderDrawData() call.
// (Please open an issue if you feel you need access to more data)
RenderState :: struct {
	Renderer: ^sdl.Renderer,
}
