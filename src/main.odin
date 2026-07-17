package main //@nested-tags:_main

import "core:math/rand"
import "core:fmt"
import "base:runtime"
import "core:path/filepath"
import "core:mem"
import "core:dynlib"
import "sdl2"
import "core:os"
import "core:strings"
import "core:time"
import "core:sys/windows"
import "kernel32"
import "dbghelp"
import "core:debug/trace"
//import "src/test_app"

MassimodinAPI :: struct{
	_game_init:proc(),
	_game_update:proc(),
	_game_render_present:proc(timeSinceFrameStart:f32),
	_game_quit:proc(),
	_init_default_allocators:proc(os:^mem.Allocator, default:^mem.Allocator),
	_set_entry_globals:proc(__os_allocator:mem.Allocator, __quit_flag:^bool, __sdl_ev:^sdl2.SDLEvent, __stacktrace_context:^trace.Context, __game_version:^string),
	_pre_hot_reload:proc()->rawptr,
	_post_hot_reload:proc(globalStatePtr:rawptr),
	time_get:proc()->f32,
	_time_target_delta_get:proc() -> f32,
	_texture_groups_textures_async_load:proc(timeBudget:f32),
	
	lib:dynlib.Library
}

ON_SWITCH :: #config(ON_SWITCH, false)
ON_PC :: !ON_SWITCH //hack, fix later
ON_WINDOWS :: ODIN_OS == .Windows
DEBUG :: ODIN_DEBUG
STACKTRACE_ENABLED :: DEBUG && !ODIN_DISABLE_ASSERT && !#config(TRACY_ENABLE, false)

executable_directory:string
massimodin_dll_path:string
trace_context:trace.Context
quit_flag:bool
sdl_ev:sdl2.SDLEvent
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
	sdl2.SetHint(sdl2.HINT_RENDER_SCALE_QUALITY, "0")
	sdl2.SetHint(sdl2.HINT_RENDER_VSYNC, "1")
	sdl2.SetHint(sdl2.HINT_RENDER_DRIVER, "opengl")

	sdlOk := sdl2.Init(sdl2.INIT_VIDEO | sdl2.INIT_GAMECONTROLLER)
	assert(sdlOk >= 0, "Error: SDL did not initialize properly")
}

massimodin_reload :: proc(massimodin_api:^MassimodinAPI, massimodin_dll_path:string){
	dynlib.initialize_symbols(massimodin_api, massimodin_dll_path, "", "lib")
}

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
			executable_directory, "massimodin_hot_reloaded", fmt.tprintf("massimodin%i.dll", hot_reload_generation^)
		})

		return true
	}

	return false
}

when ON_WINDOWS {

	_unhandled_exception_filter :: proc "system" (info: ^windows.EXCEPTION_POINTERS) -> windows.LONG {
		if DEBUG && _assert_fail_msg != "" do return windows.EXCEPTION_CONTINUE_SEARCH //if in debug, callstack printed here will be redundant and less detailed than the error_proc's, so don't bother

		context = runtime.default_context()

		_sym_search_path := strings.clone_to_cstring(executable_directory, context.allocator)
		
		fmt.println("==================================================================================================================")

		code := info.ExceptionRecord.ExceptionCode
		name,isOdin := dbghelp.exception_code_name(code)
		errorTitle := fmt.tprintf("!!!%s!!! %v (0x%X)", isOdin?"ODIN EXCEPTION":"UNHANDLED WINDOWS EXCEPTION", name, code)
		fmt.printfln(errorTitle)
		fmt.println("Callstack:")

		process := windows.GetCurrentProcess()
		thread  := windows.GetCurrentThread()
		windows.SymSetOptions(windows.SYMOPT_LOAD_LINES)
		windows.SymInitialize(process, _sym_search_path, true)
		defer windows.SymCleanup(process)

		// Explicitly load massimodin.dll in case fInvadeProcess missed it
		massimodin_mod_base: windows.DWORD64
		if _sym_search_path != nil {
			massimodin_path := fmt.ctprintf("%smassimodin.dll", _sym_search_path)
			mod_handle := windows.GetModuleHandleA("massimodin.dll")
			massimodin_mod_base = windows.DWORD64(uintptr(mod_handle))
			dbghelp.SymLoadModuleEx(process, nil, massimodin_path, nil, massimodin_mod_base, 0, nil, 0)
		}

		ctx := info.ContextRecord^ // copy so StackWalk64 can modify it
		frame: dbghelp.STACKFRAME64
		frame.AddrPC.Offset    = ctx.Rip ; frame.AddrPC.Mode    = .Flat
		frame.AddrStack.Offset = ctx.Rsp ; frame.AddrStack.Mode = .Flat
		frame.AddrFrame.Offset = ctx.Rsp ; frame.AddrFrame.Mode = .Flat // x64: use RSP, not RBP

		sym_buf: [size_of(dbghelp.SYMBOL_INFO) + 512]byte
		sym := cast(^dbghelp.SYMBOL_INFO)raw_data(sym_buf[:])

		for i in 0..<32 {
			sym.SizeOfStruct = size_of(dbghelp.SYMBOL_INFO)
			sym.MaxNameLen   = 512
			if !dbghelp.StackWalk64(dbghelp.IMAGE_FILE_MACHINE_AMD64, process, thread, &frame, &ctx, nil, dbghelp.SymFunctionTableAccess64, dbghelp.SymGetModuleBase64, nil) do break
			if frame.AddrPC.Offset < 0x10000 do break // filter null/garbage addresses

			// Frames after 0 contain return addresses (one past the call instruction).
			// Subtract 1 so symbol/line lookups land inside the call itself.
			addr := frame.AddrPC.Offset - (1 if i > 0 else 0)

			mod_base := dbghelp.SymGetModuleBase64(process, addr)

			name: string
			disp64: windows.DWORD64
			sym_ok := dbghelp.SymFromAddr(process, addr, &disp64, sym)
			if sym_ok do name = string(cstring(&sym.Name[0]))

			col_on  := DEBUG && strings.starts_with(name, "massimodin") ? "\x1b[93m":""
			col_off :=  col_on != "" ? "\x1b[0m":""

			line: dbghelp.IMAGEHLP_LINE64
			line.SizeOfStruct = size_of(dbghelp.IMAGEHLP_LINE64)
			disp32: windows.DWORD
			if dbghelp.SymGetLineFromAddr64(process, addr, &disp32, &line) {
				fmt.printfln("%v%2i: %v (%v:%v)%v", col_on, i, name, line.FileName, line.LineNumber, col_off)
			} else if sym_ok {
				fmt.printfln("%v%2i: %v (0x%X)%v", col_on, i, name, addr, col_off)
			} else if mod_base != 0 {
				fmt.printfln("%v%2i: 0x%X  [module at 0x%X, no symbol]%v", col_on, i, addr, mod_base, col_off)
			} else {
				fmt.printfln("%v%2i: 0x%X  [module not registered in symbol handler]%v", col_on, i, addr, col_off)
			}
		}
		fmt.println("==================================================================================================================")

		when !DEBUG{
			_show_error_window(_assert_fail_msg == "" ? errorTitle : _assert_fail_msg)
		}

		return windows.EXCEPTION_CONTINUE_SEARCH
	}
}

_show_error_window :: proc(crash_details:string){
	error_msg := fmt.tprintf("Oops! Looks like the game crashed! This is a little embarrassing!\nPlease report the details surrounding the crash (and paste the info copied using the button below) in the Diorama Break discord server bugs channel or at dioramabreak.com/feedback\n\nGame Version: %s\n\nError Info:\n---\n%v\n---\n\n(See log_runner.txt and log_engine.txt in the game files for full details.)", game_version, crash_details)
	buttons := [2]sdl2.MessageBoxButtonData{
		{flags = sdl2.MESSAGEBOX_BUTTON_ESCAPEKEY_DEFAULT,  buttonid = 0, text = "Close"},
		{flags = sdl2.MESSAGEBOX_BUTTON_RETURNKEY_DEFAULT, buttonid = 1, text = "Copy Logs"},
	}
	box_data := sdl2.MessageBoxData{
		flags      = sdl2.MESSAGEBOX_ERROR,
		title      = "Runtime Error",
		message    = strings.clone_to_cstring(error_msg, context.temp_allocator),
		numbuttons = 2,
		buttons    = &buttons[0],
	}
	buttonid: i32
	for {
		sdl2.ShowMessageBox(&box_data, &buttonid)
		if buttonid != 1 do break
		when ON_WINDOWS {
			engine_log, logErr1 := os.read_entire_file(filepath.join({executable_directory, "log_engine.txt"}, context.temp_allocator) or_else "", context.temp_allocator)
			runner_log, logErr2 := os.read_entire_file(filepath.join({executable_directory, "log_runner.txt"}, context.temp_allocator) or_else "", context.temp_allocator)
			outStr:string
			if logErr1 == nil && logErr2 == nil do outStr = fmt.tprintf("Version: %s\n\n===Engine Log===\n%s\n\n===Runner Log===\n%s", game_version, engine_log, runner_log)
			else do outStr = fmt.tprintf("Version:%s\nError (logs not found):\n%s", game_version, crash_details)
			
			//since sdl might be shut down by this point, cannot use sdl2 clipboard proc
			str_bytes := transmute([]u8)outStr
			byte_count := len(str_bytes) + 1
			hMem := windows.GlobalAlloc(windows.GMEM_MOVEABLE, uint(byte_count))
			if hMem != nil {
				ptr := windows.GlobalLock(windows.HGLOBAL(windows.HANDLE(hMem)))
				if ptr != nil {
					mem.copy(ptr, raw_data(str_bytes), len(str_bytes))
					(^u8)(uintptr(ptr) + uintptr(len(str_bytes)))^ = 0
					windows.GlobalUnlock(windows.HGLOBAL(windows.HANDLE(hMem)))
					if windows.OpenClipboard(nil) {
						windows.EmptyClipboard()
						windows.SetClipboardData(windows.CF_TEXT, windows.HANDLE(hMem))
						windows.CloseClipboard()
					}
				}
			}
		}
		buttons[1].text = "Copied!"
	}
}

_error_proc :: proc(prefix, message: string, loc: runtime.Source_Code_Location) -> !{

    fmt.println("==================================================================================================================")
    fmt.println("!!!RUNTIME ERROR!!!")
    fmt.println(prefix, loc)
    fmt.println(message)
	when STACKTRACE_ENABLED{
		fmt.println("------------------------------------------------------------------------------------------------------------------")
		ctx := &trace_context
		if !trace.in_resolve(ctx) {
			buf: [64]trace.Frame
			fmt.println("Callstack:")
			// skip=1 to omit the current frame (the error handler itself)
			frames := trace.frames(ctx, 2, buf[:])
			for frame, i in frames {
				fl := trace.resolve(ctx, frame, context.temp_allocator)
				if fl.loc.file_path != "" || fl.loc.line != 0 do fmt.printfln("%i: %v", i, fl.loc)
			}
		}
		fmt.println("------------------------------------------------------------------------------------------------------------------")
	}

    fmt.println("==================================================================================================================")

	_assert_fail_msg = fmt.tprintf("%v %v\n%v", prefix, loc, message)

    if(sdl2.WasInit({}) != {}) do sdl2.Quit() //force close the window
    runtime.trap()
	
}

main :: proc(){ //Program entry point, sets up context

	//init sdl
	sdl_init()

	//init dll loading stuff
	executable_directory = string(sdl2.GetBasePath())
	massimodin_dll_path, _ = filepath.join([]string{executable_directory, "massimodin.dll"})

	//exception filter can be set now that we have executable dir 
	when ON_WINDOWS do windows.SetUnhandledExceptionFilter(_unhandled_exception_filter)
	when DEBUG {
		hot_reload_generation := 0
	}

	//log files
	when !ODIN_DEBUG && ON_WINDOWS{
		logFile, err := os.open(filepath.join({executable_directory, "log_runner.txt"}, context.temp_allocator) or_else "", {.Write, .Create, .Trunc})
		if err == nil {
			os.stdout = logFile
			os.stderr = logFile
			handle := windows.HANDLE(os.fd(logFile))
       		kernel32.SetStdHandle(kernel32.STD_OUTPUT_HANDLE, handle)
       		kernel32.SetStdHandle(kernel32.STD_ERROR_HANDLE, handle)
		}
	}

	//init api
	massimodin_reload(&massimodin_api, massimodin_dll_path)
	delete(massimodin_dll_path)
	massimodin_dll_path, _ = filepath.join([]string{executable_directory, "massimodin_hot_reloaded/massimodin0.dll"})

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
		delayStartTime := massimodin_api.time_get()

		massimodin_api._game_update()

		massimodin_api._game_render_present(massimodin_api.time_get() - delayStartTime)

		when DEBUG{ //if I really need hot-reloading *and* profiling at the same time I'll take another look at this
			if(massimodin_hot_reload_update(&massimodin_api, &massimodin_dll_path, executable_directory, &hot_reload_generation)){
				massimodin_api._set_entry_globals(os_allocator, &quit_flag, &sdl_ev, &trace_context, &game_version)
				fmt.println("Successfully hot-reloaded game code!")
			}
		}

		massimodin_api._texture_groups_textures_async_load(massimodin_api._time_target_delta_get() - (massimodin_api.time_get() - delayStartTime) - 1.25)

		when ON_WINDOWS do windows.timeBeginPeriod(1)
		waitTime := massimodin_api._time_target_delta_get() - (massimodin_api.time_get() - delayStartTime)
		if(waitTime > 0){
			time.accurate_sleep(time.Duration(waitTime*1_000_000))
		}
		when ON_WINDOWS do windows.timeEndPeriod(1)
	}
	massimodin_api._game_quit()
	//test_app.main()
}

