package imgui_impl_sdlgpu3

import imgui "../"
import sdl "../../sdl3"

when      ODIN_OS == .Windows { foreign import lib "../imgui_windows_x64.lib" }
else when ODIN_OS == .Linux   { foreign import lib "../imgui_linux_x64.a" }
else when ODIN_OS == .Darwin  {
	when ODIN_ARCH == .amd64 { foreign import lib "../imgui_darwin_x64.a" } else { foreign import lib "../imgui_darwin_arm64.a" }
}

// imgui_impl_sdlgpu3.h
// Last checked `v1.92.8-docking` (a310715)

InitInfo :: struct {
    Device:               ^sdl.GPUDevice,
    ColorTargetFormat:    sdl.GPUTextureFormat,
    MSAASamples:          sdl.GPUSampleCount,
    SwapchainComposition: sdl.GPUSwapchainComposition,     // Only used in multi-viewports mode.
    PresentMode:          sdl.GPUPresentMode,              // Only used in multi-viewports mode.
}

@(link_prefix="ImGui_ImplSDLGPU3_")
foreign lib {
	Init            :: proc(info: ^InitInfo) -> bool ---
	Shutdown        :: proc() ---
	NewFrame        :: proc() ---
	PrepareDrawData :: proc(draw_data: ^imgui.DrawData, command_buffer: ^sdl.GPUCommandBuffer) ---
	RenderDrawData  :: proc(draw_data: ^imgui.DrawData, command_buffer: ^sdl.GPUCommandBuffer, render_pass: ^sdl.GPURenderPass, pipeline: ^sdl.GPUGraphicsPipeline = nil) ---

	// Use if you want to reset your rendering device without losing Dear ImGui state.
	CreateDeviceObjects  :: proc() ---
	DestroyDeviceObjects :: proc() ---

	// (Advanced) Use e.g. if you need to precisely control the timing of texture updates (e.g. for staged rendering), by setting ImDrawData::Textures = nullptr to handle this manually.
	UpdateTexture :: proc(tex: ^imgui.TextureData) ---
}

RenderState :: struct {
	Device: ^sdl.GPUDevice,
}
