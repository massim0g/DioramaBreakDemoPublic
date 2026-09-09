package main //@nested-tags:_main

import "core:math/rand"
import "core:fmt"
import "base:runtime"
import "core:path/filepath"
import "core:mem"
import "core:dynlib"
import "sdl3"
import "core:os"
import "core:time"
import "core:sys/windows"
import "core:debug/trace"
//import "src/test_app"

MassimodinAPI :: struct{
	_odin_runtime_init:proc "c" (),
	_game_init:proc(),
	_game_update:proc(),
	_game_render_present:proc(),
	_game_quit:proc(),
	_init_default_allocators:proc(os:^mem.Allocator, default:^mem.Allocator),
	_set_entry_globals:proc(__os_allocator:mem.Allocator, __quit_flag:^bool, __sdl_ev:^sdl3.Event, __stacktrace_context:^trace.Context, __game_version:^string),
	_pre_hot_reload:proc()->rawptr,
	_post_hot_reload:proc(globalStatePtr:rawptr),
	time_get:proc()->f32,
	_time_target_delta_get:proc() -> f32,
	_time_frame_marks_end:proc(frameStartTime:f32),

	lib:dynlib.Library
}

ON_SWITCH :: #config(ON_SWITCH, false)
ON_WINDOWS :: ODIN_OS == .Windows
ON_LINUX :: ODIN_OS == .Linux && !ON_SWITCH
ON_PC :: ON_WINDOWS || ON_LINUX
DEBUG :: ODIN_DEBUG
STACKTRACE_ENABLED :: DEBUG && !ODIN_DISABLE_ASSERT && !#config(TRACY_ENABLE, false)
ENGINE_HOT_RELOAD_ENABLED :: DEBUG && ON_WINDOWS && !#config(TRACY_ENABLE, false)

when ON_WINDOWS{
	ENGINE_LIB_NAME :: "massimodin.dll"
	ENGINE_HOT_LIB_NAME_FMT :: "massimodin%i.dll"
} 
else when ON_LINUX{
	ENGINE_LIB_NAME :: "libmassimodin.so"
}

executable_directory:string
massimodin_dll_path:string
trace_context:trace.Context
quit_flag:bool
sdl_ev:sdl3.Event
os_allocator:mem.Allocator
default_allocator:mem.Allocator
massimodin_api:MassimodinAPI
game_version:string //extracted from massimodin.dll
_assert_fail_msg:string //set by the error proc and then read by the windows exception handler

when ON_WINDOWS{
	@export
	NvOptimusEnablement:u32=0x00000001
	@export
	AmdPowerXpressRequestHighPerformance:i32=1
}


// @(export) hello :: proc "c" (){ //NX entry point, commented out until we actually start trying to port the game
// 	context = runtime.default_context()
// 	main()
// }

sdl_init :: proc(){
	//init SDL
	fmt.println("INITIALIZING SDL...")
	//scale quality hint is gone in SDL3, scale mode is set per-texture instead
	sdl3.SetHint(sdl3.HINT_RENDER_VSYNC, "1")

	sdlOk := sdl3.Init(sdl3.INIT_VIDEO | sdl3.INIT_GAMEPAD)
	assert(sdlOk, "Error: SDL did not initialize properly")
}

massimodin_reload :: proc(massimodin_api:^MassimodinAPI, massimodin_dll_path:string){
	dynlib.initialize_symbols(massimodin_api, massimodin_dll_path, "", "lib")
}

when ON_WINDOWS{
massimodin_hot_reload_update :: proc(massimodin_api:^MassimodinAPI, massimodin_dll_path:^string, executable_directory:string, hot_reload_generation:^int) -> bool{
	if(os.exists(massimodin_dll_path^)){

		//check if compile is still in progress
		lockPath,_ := filepath.join({executable_directory, "massimodin_hot_reloaded/.compilelock"}, context.temp_allocator)
		if os.exists(lockPath) do return false

		//reload scripts and update _scripts_dll_path to next expected path
		globalState := massimodin_api._pre_hot_reload() //saves global state of current .dll onto the heap
		massimodin_api.lib = nil //ensure the old dll does not get unloaded
		massimodin_reload(massimodin_api, massimodin_dll_path^)
		massimodin_api._post_hot_reload(globalState) //loads the global state into the new .dll and frees the global state that was put on the heap

		hot_reload_generation^ += 1
		delete(massimodin_dll_path^)
		massimodin_dll_path^, _ = filepath.join({
			executable_directory, "massimodin_hot_reloaded", fmt.tprintf(ENGINE_HOT_LIB_NAME_FMT, hot_reload_generation^)
		})

		return true
	}

	return false
}
}

//Program entry point, sets up context
main :: proc(){ 

	//init sdl
	sdl_init()

	//init dll loading stuff
	executable_directory = string(sdl3.GetBasePath())
	massimodin_dll_path, _ = filepath.join([]string{executable_directory, ENGINE_LIB_NAME})

	//crash handler can be set now that we have executable dir (SEH filter on windows, signal handlers on linux)
	crash_handler_install()
	when DEBUG {
		hot_reload_generation := 0
	}

	//log files
	when !ODIN_DEBUG do log_redirect(executable_directory, "log_runner.txt")

	//init api
	massimodin_reload(&massimodin_api, massimodin_dll_path)
	when ON_LINUX do massimodin_api._odin_runtime_init() //unlike windows, engine library runtime is not initialized automatically on linux
	when ENGINE_HOT_RELOAD_ENABLED{
		delete(massimodin_dll_path)
		massimodin_dll_path, _ = filepath.join([]string{executable_directory, "massimodin_hot_reloaded", fmt.tprintf(ENGINE_HOT_LIB_NAME_FMT, 0)})
	}

	//debug failure stuff
	when STACKTRACE_ENABLED{
		trace.init(&trace_context)
	}
	context.assertion_failure_proc = _error_proc

	//init default allocators
	massimodin_api._init_default_allocators(&os_allocator, &default_allocator)
	context.allocator = default_allocator

	//init random state
	context.random_generator = rand.pcg_random_generator(new(rand.PCG_Random_State, os_allocator))

	massimodin_api._set_entry_globals(os_allocator, &quit_flag, &sdl_ev, &trace_context, &game_version)

	massimodin_api._game_init()

	fmt.println("-ENTERING MAIN LOOP-")
	for !quit_flag{
		//frame delay and other time stuff
		frameStartTime := massimodin_api.time_get()

		massimodin_api._game_update()

		massimodin_api._game_render_present()

		when ENGINE_HOT_RELOAD_ENABLED{
			if(massimodin_hot_reload_update(&massimodin_api, &massimodin_dll_path, executable_directory, &hot_reload_generation)){
				massimodin_api._set_entry_globals(os_allocator, &quit_flag, &sdl_ev, &trace_context, &game_version)
				fmt.println("Successfully hot-reloaded game code!")
			}
		}

		free_all(context.temp_allocator)
		massimodin_api._time_frame_marks_end(frameStartTime)

		when ON_WINDOWS do windows.timeBeginPeriod(1) //temporarily increase scheduler accuracy to prevent oversleeping
		waitTime := massimodin_api._time_target_delta_get() - (massimodin_api.time_get() - frameStartTime)
		if(waitTime > 0) do time.accurate_sleep(time.Duration(waitTime*1_000_000))
		when ON_WINDOWS do windows.timeEndPeriod(1)
	}
	massimodin_api._game_quit()
	//test_app.main()
}

