package main //@nested-tags:

import "core:fmt"
import "core:mem"
import "core:strings"
import "base:runtime"
import "core:sys/windows"
import "dbghelp"
import "core:os"
import "core:path/filepath"
import "core:sys/posix"
import "kernel32"
import "sdl3"
import "core:debug/trace"

//Routes stdout/stderr into a log file next to the executable, including C-side writes (SDL, FMOD)
log_redirect :: proc(directory, fileName:string){
	logFile, err := os.open(filepath.join({directory, fileName}, context.temp_allocator) or_else "", {.Write, .Create, .Trunc})
	if err != nil do return

	os.stdout = logFile
	os.stderr = logFile

	when ON_WINDOWS{
		handle := windows.HANDLE(os.fd(logFile))
		kernel32.SetStdHandle(kernel32.STD_OUTPUT_HANDLE, handle)
		kernel32.SetStdHandle(kernel32.STD_ERROR_HANDLE, handle)
	}
	else when ON_LINUX{
		fd := posix.FD(os.fd(logFile))
		posix.dup2(fd, 1)
		posix.dup2(fd, 2)
	}
}

CRASH_LOGS_BUTTON_TEXT :: "Copy Logs"
CRASH_LOGS_BUTTON_DONE_TEXT :: "Copied!"
when ON_LINUX{
	LINUX_CRASH_SIGNALS :: [?]posix.Signal{.SIGSEGV, .SIGBUS, .SIGFPE, .SIGILL, .SIGABRT}
}


crash_handler_install :: proc(){
	when ON_WINDOWS do windows.SetUnhandledExceptionFilter(_windows_unhandled_exception_filter)
	else when ON_LINUX{
		@(static) crash_signal_stack:[posix.SIGSTKSZ]u8
		
		//dedicated signal stack so stack-overflow crashes can still run the handler
		stack := posix.stack_t{
			ss_sp = &crash_signal_stack[0],
			ss_size = len(crash_signal_stack),
		}
		posix.sigaltstack(&stack, nil)
	
		action:posix.sigaction_t
		action.sa_sigaction = _linux_crash_signal_handler
		action.sa_flags = {.SIGINFO, .ONSTACK}
		posix.sigemptyset(&action.sa_mask)
	
		for sig in LINUX_CRASH_SIGNALS{
			posix.sigaction(sig, &action, nil)
		}

		//when remote-launched over ssh, killing the ssh session leaves stdout/stderr as dead pipes and the default SIGPIPE disposition would silently terminate the game on its next print.
		//Ignoring it turns those writes into harmless EPIPE errors instead.
		posix.signal(.SIGPIPE, cast(proc "c"(_:posix.Signal))posix.SIG_IGN)
	}
}

//Copies the composed crash report to the clipboard.
//sdl might be shut down by this point, cannot use the sdl clipboard proc
crash_logs_export :: proc(text:string){
	when ON_WINDOWS{
		strBytes := transmute([]u8)text
		byteCount := len(strBytes) + 1
		hMem := windows.GlobalAlloc(windows.GMEM_MOVEABLE, uint(byteCount))
		if hMem != nil {
			ptr := windows.GlobalLock(windows.HGLOBAL(windows.HANDLE(hMem)))
			if ptr != nil {
				mem.copy(ptr, raw_data(strBytes), len(strBytes))
				(^u8)(uintptr(ptr) + uintptr(len(strBytes)))^ = 0
				windows.GlobalUnlock(windows.HGLOBAL(windows.HANDLE(hMem)))
				if windows.OpenClipboard(nil) {
					windows.EmptyClipboard()
					windows.SetClipboardData(windows.CF_TEXT, windows.HANDLE(hMem))
					windows.CloseClipboard()
				}
			}
		}
	}
	else when ON_LINUX{
		pipe := posix.popen("wl-copy 2>/dev/null || xclip -selection clipboard 2>/dev/null || xsel -ib 2>/dev/null", "w")
		if pipe == nil do return
		_ = posix.fwrite(raw_data(text), 1, len(text), pipe)
		_ = posix.pclose(pipe)
	}
}

_show_error_window :: proc(crash_details:string){
	error_msg := fmt.tprintf("Oops! Looks like the game crashed! This is a little embarrassing!\nPlease report the details surrounding the crash (and attach the info exported using the button below) in the Diorama Break discord server bugs channel or at dioramabreak.com/feedback\n\nGame Version: %s\n\nError Info:\n---\n%v\n---\n\n(See log_runner.txt and log_engine.txt in the game files for full details.)", game_version, crash_details)
	buttons := [2]sdl3.MessageBoxButtonData{
		{flags = {.ESCAPEKEY_DEFAULT}, buttonID = 0, text = "Close"},
		{flags = {.RETURNKEY_DEFAULT}, buttonID = 1, text = CRASH_LOGS_BUTTON_TEXT},
	}
	box_data := sdl3.MessageBoxData{
		flags      = {.ERROR},
		title      = "Runtime Error",
		message    = strings.clone_to_cstring(error_msg, context.temp_allocator),
		numbuttons = 2,
		buttons    = &buttons[0],
	}
	buttonid: i32
	for {
		sdl3.ShowMessageBox(box_data, &buttonid)
		if buttonid != 1 do break

		engine_log, logErr1 := os.read_entire_file(filepath.join({executable_directory, "log_engine.txt"}, context.temp_allocator) or_else "", context.temp_allocator)
		runner_log, logErr2 := os.read_entire_file(filepath.join({executable_directory, "log_runner.txt"}, context.temp_allocator) or_else "", context.temp_allocator)
		outStr:string
		if logErr1 == nil && logErr2 == nil do outStr = fmt.tprintf("Version: %s\n\n===Engine Log===\n%s\n\n===Runner Log===\n%s", game_version, engine_log, runner_log)
		else do outStr = fmt.tprintf("Version:%s\nError (logs not found):\n%s", game_version, crash_details)

		crash_logs_export(outStr)

		buttons[1].text = CRASH_LOGS_BUTTON_DONE_TEXT
	}
}

//Runs on failed assertions. Unhandled OS-level exceptions handled by the procs below this one.
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
	
    if(sdl3.WasInit({}) != {}) do sdl3.Quit() //force close the window
    runtime.trap()
	
}


when ON_WINDOWS{

_windows_unhandled_exception_filter :: proc "system" (info: ^windows.EXCEPTION_POINTERS) -> windows.LONG {
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
		massimodin_path := fmt.ctprintf("%s%s", _sym_search_path, ENGINE_LIB_NAME)
		mod_handle := windows.GetModuleHandleA(ENGINE_LIB_NAME)
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

	frameModuleName :: proc(modBase:windows.DWORD64) -> string{
		pathWide:[windows.MAX_PATH]u16
		if windows.GetModuleFileNameW(windows.HMODULE(rawptr(uintptr(modBase))), &pathWide[0], windows.DWORD(len(pathWide))) == 0 do return "unknown module"
		path,_ := windows.wstring_to_utf8(windows.wstring(&pathWide[0]), -1)
		return filepath.base(path)
	}

	for i in 0..<32 {
		sym.SizeOfStruct = size_of(dbghelp.SYMBOL_INFO)
		sym.MaxNameLen   = 512
		if !dbghelp.StackWalk64(dbghelp.IMAGE_FILE_MACHINE_AMD64, process, thread, &frame, &ctx, nil, dbghelp.SymFunctionTableAccess64, dbghelp.SymGetModuleBase64, nil) do break
		if frame.AddrPC.Offset < 0x10000 do break // filter null/garbage addresses

		// Frames after 0 contain return addresses (one past the call instruction).
		// Subtract 1 so symbol/line lookups land inside the call itself.
		addr := frame.AddrPC.Offset - (1 if i > 0 else 0)

		mod_base := dbghelp.SymGetModuleBase64(process, addr)

		stackName: string
		disp64: windows.DWORD64
		sym_ok := dbghelp.SymFromAddr(process, addr, &disp64, sym)
		if sym_ok do stackName = string(cstring(&sym.Name[0]))

		col_on  := DEBUG && strings.starts_with(stackName, "massimodin") ? "\x1b[93m":""
		col_off :=  col_on != "" ? "\x1b[0m":""

		line: dbghelp.IMAGEHLP_LINE64
		line.SizeOfStruct = size_of(dbghelp.IMAGEHLP_LINE64)
		disp32: windows.DWORD
		if dbghelp.SymGetLineFromAddr64(process, addr, &disp32, &line) {
			fmt.printfln("%v%2i: %v (%v:%v)%v", col_on, i, stackName, line.FileName, line.LineNumber, col_off)
		} else if sym_ok {
			fmt.printfln("%v%2i: %v (0x%X)%v", col_on, i, stackName, addr, col_off)
		} else if mod_base != 0 {
			fmt.printfln("%v%2i: %v+0x%X [no symbol]%v", col_on, i, frameModuleName(mod_base), addr - mod_base, col_off)
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
else when ON_LINUX{

foreign import execinfo_ "system:c"
foreign execinfo_{
	backtrace :: proc "c" (buffer:[^]rawptr, size:i32) -> i32 ---
	backtrace_symbols_fd :: proc "c" (buffer:[^]rawptr, size:i32, fd:i32) ---
}

_linux_crash_signal_handler :: proc "c" (sig:posix.Signal, info:^posix.siginfo_t, ctx:rawptr){
	//restore default dispositions immediately: the re-raise below then terminates with a core dump, and a second fault inside this handler can't loop
	for s in LINUX_CRASH_SIGNALS do posix.signal(s, auto_cast posix.SIG_DFL)

	context = runtime.default_context()

	if !(DEBUG && _assert_fail_msg != ""){ //if in debug, the error_proc's output is more detailed than anything printed here, so don't bother
		fmt.println("==================================================================================================================")
		errorTitle := fmt.tprintf("!!!UNHANDLED SIGNAL!!! %v (fault address 0x%X)", sig, uintptr(info.si_addr))
		fmt.println(errorTitle)

		//raw backtrace from the fault context: prints module(+offset) lines to stderr, resolvable offline against the unstripped binaries.
		//glibc backtrace() can't unwind past the signal trampoline here, so read RIP/RBP out of the ucontext and walk the frame-pointer chain by hand.
		regs := cast(^[23]u64)(uintptr(ctx)+40) //linux x86_64 ucontext_t.uc_mcontext.gregs
		rip := regs[16]
		rbp := regs[10]
		frame := rawptr(uintptr(rip))
		backtrace_symbols_fd(&frame, 1, 2)
		for _ in 0..<30{
			if rbp < 0x10000 || rbp % 8 != 0 do break
			ret := (cast(^u64)(uintptr(rbp)+8))^
			if ret < 0x10000 do break
			frame = rawptr(uintptr(ret))
			backtrace_symbols_fd(&frame, 1, 2)
			rbp = (cast(^u64)uintptr(rbp))^
		}

		fmt.println("==================================================================================================================")

		when !DEBUG{
			_show_error_window(_assert_fail_msg == "" ? errorTitle : _assert_fail_msg)
		}
	}

	posix.raise(sig)
}

}