package timer_app

import "../../../imgui"
import impl "../../../imgui/imgui_impl_sdl2"
import implr "../../../imgui/imgui_impl_sdlrenderer2"
import "../../../sdl2"
import "core:time"
import "core:fmt"
import "core:strings"
import "core:path/filepath"

print :: fmt.println

main :: proc() {
	//init
	displaySize := imgui.Vector2{640, 360}
    sdl2.SetHint(sdl2.HINT_RENDER_SCALE_QUALITY, "0")
	sdl2.SetHint(sdl2.HINT_RENDER_VSYNC, "1")
	sdl2.SetHint(sdl2.HINT_RENDER_DRIVER, "opengl")

	sdl2.Init(sdl2.INIT_VIDEO)
	window := sdl2.CreateWindow("Timer",
        sdl2.WINDOWPOS_CENTERED, sdl2.WINDOWPOS_CENTERED,
		i32(displaySize.x), i32(displaySize.y),
        {.SHOWN, .OPENGL}
	)
	renderer := sdl2.CreateRenderer(window, -1, sdl2.RENDERER_ACCELERATED)
	assert(renderer != nil, string(sdl2.GetError()))
	sdl2.SetWindowIcon(window, sdl2.LoadBMP(strings.clone_to_cstring(filepath.join({#location().file_path, "../time.bmp"}) or_else "")))

    ctx := imgui.CreateContext()
	
	impl.InitForSDLRenderer(window, renderer)
	implr.Init(renderer)

	imgui.GetIO().ConfigFlags += {.NavEnableKeyboard}

	e:sdl2.SDLEvent
	quit:bool

	//stopwatch vars
	running:bool
	startTime:i64
	oldElapsedTime:i64
	currentElapsedTime:i64

	imgui.GetIO().FontGlobalScale = 4

    for !quit{
		for sdl2.PollEvent(&e){
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

		sdl2.RenderClear(renderer)
        imgui.Render()
		implr.RenderDrawData(imgui.GetDrawData())
		sdl2.RenderPresent(renderer)
		free_all(context.temp_allocator)
    }

    sdl2.Quit()
}