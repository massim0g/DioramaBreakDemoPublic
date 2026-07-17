package massimodin_builder

import "core:os"
import "core:path/filepath"
import "core:strings"
import "core:sys/windows"
import "core:unicode/utf16"

game_launch_requested:bool
tracy_process:os.Process

//Game Launch
game_launch_hotkey_check :: proc(){
	keyState := windows.GetAsyncKeyState(windows.VK_F5)
	if keyState & 0x0001 == 0 do return

	hwnd := windows.GetForegroundWindow()
	if hwnd == nil do return

	titleBuf:[256]windows.WCHAR
	titleLen := windows.GetWindowTextW(hwnd, &titleBuf[0], 256)
	if titleLen <= 0 do return

	utf8Buf:[512]u8
	utf8Len := utf16.decode_to_utf8(utf8Buf[:], titleBuf[:titleLen])
	title := string(utf8Buf[:utf8Len])

	if !strings.contains(title, "DioramaBreak") do return

	print("GAME LAUNCH REQUESTED!")

	exePath, _ := filepath.join({paths.build_win64, "DioramaBreak.exe"})
	if process_running(exePath){
		print("Request failed: Game is already running!")
		return
	}

	game_launch_requested = true

	for kind in PipelineKind{
		s := pipeline_status_get(&pipelines[kind])
		if s != .idle do printf("Rebuild in progress, waiting for %v to finish...", kind)
	}
}

game_launch_check :: proc(){
	game_launch_hotkey_check()

	if !game_launch_requested do return

	for kind in PipelineKind{
		if pipeline_status_get(&pipelines[kind]) != .idle do return		
	}

	errorLogPath, _ := filepath.join({paths.build_win64, "compile_error_log.txt"})
	if os.exists(errorLogPath){
		data, readErr := os.read_entire_file(errorLogPath, context.temp_allocator)
		if readErr == nil && len(data) > 0{
			printf("Compile errors exist, cannot launch:\n%s", string(data))
			game_launch_requested = false
			return
		}
	}

	exePath, _ := filepath.join({paths.build_win64, "DioramaBreak.exe"})
	if !os.exists(exePath){
		print("ERROR: DioramaBreak.exe not found.")
		game_launch_requested = false
		return
	}

	if config_changed{
		//the daemon shares its console with the interactive shell, so it can't reliably read stdin. Ask with a popup instead.
		choice := windows.MessageBoxW(nil,
			windows.L("The build config has changed since the last full rebuild.\nRebuild from scratch with the new config?\n\n(\"No\" launches with the old config)"),
			windows.L("Massimodin Builder"),
			windows.MB_YESNO | windows.MB_ICONQUESTION | windows.MB_SETFOREGROUND | windows.MB_TOPMOST,
		)
		if choice == windows.IDYES{
			load_config()
			full_rebuild()
			return
		}
	}

	print("No build errors, launching...")
	//route the game's stdout/stderr to the daemon's console so its output shows in the terminal
	_,_ = os.process_start({command = {exePath}, stdout = os.stdout, stderr = os.stderr})

	if config.tracyEnable{
		if tracy_process.pid != 0{
			_ = os.process_kill(tracy_process)
			_,_ = os.process_wait(tracy_process) //also closes and frees the process handle
		}
		tracy_process,_ = os.process_start({command = {filepath.join({paths.src, "_tools/dev_tools/Tracy.exe"}) or_else "", "-a", "127.0.0.1"}})
	}

	game_launch_requested = false
}