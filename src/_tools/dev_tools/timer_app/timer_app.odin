package timer_app

import "../../../imgui"
import impl "../../../imgui/imgui_impl_sdl3"
import implr "../../../imgui/imgui_impl_sdlrenderer3"
import "../../../sdl3"
import "core:time"
import "core:fmt"
import "core:strings"
import "core:path/filepath"

print :: fmt.println

main :: proc() {
	//init
	displaySize := imgui.Vec2{640, 360}
	sdl3.SetHint(sdl3.HINT_RENDER_VSYNC, "1")

	_ = sdl3.Init(sdl3.INIT_VIDEO)
	window := sdl3.CreateWindow("Timer", i32(displaySize.x), i32(displaySize.y), {})
	renderer := sdl3.CreateRenderer(window, nil)
	assert(renderer != nil, string(sdl3.GetError()))
	sdl3.SetWindowIcon(window, sdl3.LoadBMP(strings.clone_to_cstring(filepath.join({#location().file_path, "../time.bmp"}) or_else "")))

    ctx := imgui.CreateContext()
	
	impl.InitForSDLRenderer(window, renderer)
	implr.Init(renderer)

	imgui.GetIO().ConfigFlags += {.NavEnableKeyboard}

	e:sdl3.Event
	quit:bool

	//stopwatch vars
	running:bool
	startTime:i64
	oldElapsedTime:i64
	currentElapsedTime:i64

	imgui.GetStyle().FontScaleMain = 4

    for !quit{
		for sdl3.PollEvent(&e){
			if e.type == .QUIT do quit = true

			impl.ProcessEvent(&e)
		}

        implr.NewFrame()
		impl.NewFrame()
		imgui.NewFrame()

        imgui.Begin("Timer", nil, {.NoTitleBar, .NoResize, .NoMove})
		imgui.SetWindowPos({0,0})
		imgui.SetWindowSize(displaySize)

		if running{
			if imgui.Button("Pause"){
				running = false
				oldElapsedTime += currentElapsedTime
				currentElapsedTime = 0
			}
			else do currentElapsedTime = time.now()._nsec - startTime
			imgui.SameLine()
			if imgui.Button("Reset and Start"){
				oldElapsedTime = 0
				currentElapsedTime = 0
				startTime = time.now()._nsec
			}
		}
		else{
			

			if imgui.Button("Reset and Start"){
				oldElapsedTime = 0
				currentElapsedTime = 0
				startTime = time.now()._nsec
				running = true
			}
			imgui.SameLine()
			if imgui.Button("Resume"){
				startTime = time.now()._nsec
				currentElapsedTime = 0
				running = true
			}

		}
		
        
		watchTime := oldElapsedTime + currentElapsedTime
        imgui.Text("TIME")
		imgui.Text("%.2f s", f64(watchTime)/1000000000.)
		imgui.Text("%.0f ms", f64(watchTime)/1000000.)
		imgui.Text("%.0f frames", f64(watchTime)/1000000000.*60.)
        imgui.End()

		sdl3.RenderClear(renderer)
        imgui.Render()
		implr.RenderDrawData(imgui.GetDrawData(), renderer)
		sdl3.RenderPresent(renderer)
		free_all(context.temp_allocator)
    }

    sdl3.Quit()
}