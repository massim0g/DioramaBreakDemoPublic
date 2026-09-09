package massimodin //@nested-tags:debug

import "../imgui"
import impl "../imgui/imgui_impl_sdl3"
import implg "../imgui/imgui_impl_sdlgpu3"
import "../sdl3"
import "core:strings"
import "core:sync"
import win32 "core:sys/windows"

_imgui_sdlevent_process :: impl.ProcessEvent

ImguiSystem :: struct{
	_context:^imgui.Context,
	_io:^imgui.IO,
	_style_default:imgui.Style,
	_labels_id:[2]u8,
	scale:f32,
}
imgui_system:^ImguiSystem

_imgui_init :: proc(){
	imgui_system = new(ImguiSystem)
	imgui.CHECKVERSION()
	imgui_system._context = imgui.CreateContext()
	imgui_system._io = imgui.GetIO()
	imgui_system._io.ConfigFlags += {.NavEnableKeyboard}

	//load emojis (requires rebuilding imgui so screw this)
	// fontPath := string_to_cstring(filepath.join({project_directory, "fonts/notoSans.ttf"}, context.temp_allocator), context.temp_allocator)
	// //imgui.FontAtlas_AddFontFromFileTTF(imgui_system._io.Fonts, fontPath, 16)
	// cfg := imgui.FontConfig{}
	// cfg.MergeMode = true
	// cfg.FontBuilderFlags |= (1 << 8) //load color flag, not defined by bindings for some reason
	// ranges := []imgui.Wchar{0x1, 0xFFFF, 0 }
	// imgui.FontAtlas_AddFontFromFileTTF(imgui_system._io.Fonts, fontPath, 16, &cfg, &ranges[0])

	imgui_system._labels_id = {33, 33}
	imgui_system.scale = 1
	imgui_system._style_default = imgui.GetStyle()^

	impl.InitForSDLGPU(display._window)
	initInfo := implg.InitInfo{
		Device = render.device,
		ColorTargetFormat = render.swapchain_format,
		MSAASamples = ._1,
	}
	implg.Init(&initInfo)

	/*
	The sdlgpu3 backend samples every texture with its linear sampler and exposes no way to change that (the nearest-sampler draw callbacks are static internals).
	Swapping the two sampler pointers in its backend data makes everything sample nearest instead.
	The struct prefix below mirrors ImGui_ImplSDLGPU3_Data from imgui_impl_sdlgpu3.cpp at v1.92.8, may need to be changed if imgui is updated.
	*/
	ImplSDLGPU3DataPrefix :: struct{
		initInfo:implg.InitInfo,
		renderState:rawptr,
		currentSampler:^sdl3.GPUSampler,
		vertexShader:rawptr,
		fragmentShader:rawptr,
		pipeline:rawptr,
		texSamplerLinear:^sdl3.GPUSampler,
		texSamplerNearest:^sdl3.GPUSampler,
	}
	implg.CreateDeviceObjects() //the backend creates its objects lazily on first NewFrame, force them so the samplers exist to swap
	bd := cast(^ImplSDLGPU3DataPrefix)imgui_system._io.BackendRendererUserData
	assert(bd != nil && bd.initInfo.Device == render.device, "imgui sdlgpu3 backend data mismatch, did the imgui version change?")
	bd.texSamplerLinear, bd.texSamplerNearest = bd.texSamplerNearest, bd.texSamplerLinear
}

//imgui 1.92's sdlgpu3 backend takes the texture pointer itself as the id and pairs it with its own sampler internally
_imgui_texture_id :: proc(texture:^sdl3.GPUTexture) -> imgui.TextureID{
	assert(texture != nil, "Tried to display a nil texture through imgui!")
	return imgui.TextureID(uintptr(texture))
}

FileTreeFolder :: struct{
	name:string,
	parent:^FileTreeFolder,
	root:^FileTreeFolder,
	contents:[dynamic]FileTreeNode
}
FileTreeNode :: union{
	^FileTreeFolder,
	^Sprite,
	^Stage
}

file_tree_folder_new :: proc(name:string, parent:^FileTreeFolder=nil, allocator:=assets.allocator) -> ^FileTreeFolder{
	out := new(FileTreeFolder, allocator)
	out.name = clone(name, allocator)
	out.parent = parent
	if parent == nil do out.root = out
	else do out.root = parent.root
	out.contents = make([dynamic]FileTreeNode, allocator)
	return out
}

_imgui_shutdown :: proc(){
	implg.Shutdown()
	impl.Shutdown()
	imgui.DestroyContext(imgui_system._context)
	free(imgui_system)
}


_imgui_update :: proc(){
	imgui_system._labels_id = {33, 33}
	implg.NewFrame()
	impl.NewFrame()
	imgui.NewFrame()
	//imgui.ShowDemoWindow()

	//refocuses window in case SDL loses keyboard focus, which can break imgui text entry fields
	when ON_WINDOWS{
		if imgui_system._io.WantTextInput && sdl3.GetKeyboardFocus() == nil{
			hwnd := win32.HWND(sdl3.GetPointerProperty(sdl3.GetWindowProperties(display._window), sdl3.PROP_WINDOW_WIN32_HWND_POINTER, nil))
			if hwnd != nil && win32.GetForegroundWindow() == hwnd{
				win32.SetFocus(nil)
				win32.SetFocus(hwnd)
			}
		}
	}

}

//only builds the draw data; the recording happens in _imgui_gpu_record, inside the frame's command buffer
_imgui_draw :: proc(){
	imgui.Render()
}

_imgui_render :: proc(cmdBuf:^sdl3.GPUCommandBuffer, swapchainTex:^sdl3.GPUTexture){
	drawData := imgui.GetDrawData()
	if drawData == nil do return

	//font atlas updates make the backend acquire and submit its own command buffer internally, which must not race the loader threads' submits
	sync.lock(&render._gpu_commands_submit_mutex)
	defer sync.unlock(&render._gpu_commands_submit_mutex)

	implg.PrepareDrawData(drawData, cmdBuf)

	pass := sdl3.BeginGPURenderPass(cmdBuf,
		&sdl3.GPUColorTargetInfo{texture=swapchainTex, load_op=.LOAD, store_op=.STORE}, 1, nil,
	)
	implg.RenderDrawData(drawData, cmdBuf, pass)
	sdl3.EndGPURenderPass(pass)
}

_imgui_scale_update :: proc(){
	imgui_system.scale = f32(settings.window_scale)/3
	imgui.GetStyle()^ = imgui_system._style_default
	imgui.Style_ScaleAllSizes(imgui.GetStyle(), imgui_system.scale)
	imgui.GetStyle().FontScaleMain = imgui_system.scale //imgui 1.92: FontGlobalScale moved into style
}


//creates a label cstring for use with imgui items and ensures it is unique (even if no arguments are passed).
imgui_label :: proc(displayString:="", idString:="", allocator:=context.temp_allocator) -> cstring{
	builder := strings.builder_make_len_cap(0, len(displayString)+5+len(idString), allocator)
	strings.write_string(&builder, displayString)
	strings.write_string(&builder, "##")
	strings.write_string(&builder, idString)
	strings.write_string(&builder, "_")
	strings.write_rune(&builder, rune(imgui_system._labels_id.x))
	strings.write_rune(&builder, rune(imgui_system._labels_id.y))
	imgui_system._labels_id.x += 1
	if(imgui_system._labels_id.x > 126){
		imgui_system._labels_id.x = 33
		imgui_system._labels_id.y += 1
	}

	return strings.to_cstring(&builder)
}

//If you want a button with no display text, pass in imgui_label()
imgui_sprite :: proc(sp:^Sprite, buttonName:cstring = "", size:=Vec2{-1,-1}, frameIndex:=-1) -> bool{
	size:=size
	frameIndex:=frameIndex
	
	if(frameIndex == -1) do frameIndex = sprite_frame_get(sp)

	frame := sp.frames[frameIndex]
	page := frame.texturePage
	pageSize := Vec2{page.size, page.size}
	framePos := frame.texturePagePos.pos
	frameSize := frame.texturePagePos.size
	if(size == {-1,-1}){
		size = sp.frames[0].texturePagePos.size
	}

	if(buttonName == ""){
		imgui.Image(
			imgui.TextureRef{_TexID = _imgui_texture_id(page.texture)}, 
			size, 
			framePos/pageSize, 
			(framePos + frameSize)/pageSize
		)
		return false
	}
	else{
		return imgui.ImageButton(
			buttonName,
			imgui.TextureRef{_TexID = _imgui_texture_id(page.texture)}, 
			size, 
			framePos/pageSize, 
			(framePos + frameSize)/pageSize
		)
	}
}

imgui_tex :: proc(tex:Tex, buttonName:cstring = "", part:=Rect{{-1,-1},{-1,-1}}, scale:f32=1) -> bool{

	part := part
	texSize := Vec2(tex.size)
	if(part == Rect{{-1,-1},{-1,-1}}) do part = Rect{{0,0}, texSize}

	if(buttonName == ""){
		imgui.Image(
			imgui.TextureRef{_TexID = _imgui_texture_id(tex.ptr)}, 
			part.size*scale,
			part.pos/texSize,
			(part.pos + part.size)/texSize
		)
		return false
	}
	else{
		return imgui.ImageButton(
			buttonName,
			imgui.TextureRef{_TexID = _imgui_texture_id(tex.ptr)}, 
			part.size*scale,
			part.pos/texSize,
			(part.pos + part.size)/texSize
		)
	}
}


imgui_suggestions_selector :: proc(suggestions:[]string, selectedIndex:^int){
	selectedIndex^ = clamp(selectedIndex^ + int(imgui.IsKeyPressed(.DownArrow)) - int(imgui.IsKeyPressed(.UpArrow)), 0, len(suggestions) - 1)
	inputPos := imgui.GetItemRectMin()
	inputSize := imgui.GetItemRectSize()
	imgui.SetNextWindowPos(Vec2{inputPos.x, inputPos.y + inputSize.y})

	cSuggs := make([]cstring, len(suggestions), context.temp_allocator)
	// Calculate the size for the popup
	maxWidth:f32
	for str,i in suggestions {
		cSuggs[i] = string_to_cstring(str, context.temp_allocator)
		width := imgui.CalcTextSize(cSuggs[i]).x
		if width > maxWidth {
			maxWidth = width
		}
	}
	suggestionsSize := Vec2{
		max(maxWidth + imgui.GetStyle().FramePadding.x * 2, inputSize.x),
		f32(len(suggestions))*imgui.GetTextLineHeightWithSpacing()
	}

	//imgui.SetNextWindowSize(suggestionsSize)
	if imgui.BeginTooltip(){
		for str, i in cSuggs{
			imgui.Selectable(str, i == selectedIndex^)
		}
		imgui.EndTooltip()
	}
}