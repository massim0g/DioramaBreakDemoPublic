package massimodin //@nested-tags:debug

import "../imgui"
import impl "../imgui/imgui_impl_sdl2"
import implr "../imgui/imgui_impl_sdlrenderer2"
import "../sdl2"
import "core:strings"
import "core:path/filepath"

_imgui_sdlevent_process :: impl.ProcessEvent

ImguiSystem :: struct{
	_context:^imgui.Context,
	_io:^imgui.IO,
	_labels_id:[2]u8,
	scale:f32
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
	
	impl.InitForSDLRenderer(display._window, display._renderer)
	implr.Init(display._renderer)

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
	implr.Shutdown()
	impl.Shutdown()
	imgui.DestroyContext(imgui_system._context)
	free(imgui_system)
}


_imgui_update :: proc(){
	imgui_system._labels_id = {33, 33}
	implr.NewFrame()
	impl.NewFrame()
	imgui.NewFrame()
	//imgui.ShowDemoWindow()
}

_imgui_draw :: proc(){
	imgui.Render()
	implr.RenderDrawData(imgui.GetDrawData())
}

_imgui_scale_update :: proc(){
	lastScale := imgui_system.scale
	imgui_system.scale = f32(settings.window_scale)/3
	imgui_system._io.FontGlobalScale = imgui_system.scale
	imgui.Style_ScaleAllSizes(imgui.GetStyle(), imgui_system.scale/lastScale) //floating point errors will unfortunately compound with multiple calls, why did they design it this way?
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
	pageW:i32
	pageH:i32
	sdl2.QueryTexture(page, nil, nil, &pageW, &pageH)
	pageSize := Vec2{f32(pageW), f32(pageH)}
	framePos := Vec2{f32(frame.texturePagePos.x), f32(frame.texturePagePos.y)}
	frameSize := Vec2{f32(frame.texturePagePos.w), f32(frame.texturePagePos.h)}
	if(size == {-1,-1}){
		frame0 := sp.frames[0]
		size = Vec2{f32(frame0.texturePagePos.w), f32(frame0.texturePagePos.h)}
	}

	if(buttonName == ""){
		imgui.Image(
			imgui.TextureID(uintptr(page)), 
			size, 
			framePos/pageSize, 
			(framePos + frameSize)/pageSize
		)
		return false
	}
	else{
		return imgui.ImageButton(
			buttonName,
			imgui.TextureID(uintptr(page)), 
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
			imgui.TextureID(uintptr(tex.ptr)), 
			part.size*scale,
			part.pos/texSize,
			(part.pos + part.size)/texSize
		)
		return false
	}
	else{
		return imgui.ImageButton(
			buttonName,
			imgui.TextureID(uintptr(tex.ptr)), 
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