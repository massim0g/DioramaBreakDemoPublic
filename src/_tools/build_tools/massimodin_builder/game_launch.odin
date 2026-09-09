package massimodin_builder

import "core:os"
import "core:fmt"
import "core:path/filepath"
import "core:strings"
import "core:sys/windows"
import "core:unicode/utf16"

game_launch_requested:bool
tracy_process:os.Process
linux_ssh_process:os.Process

//ensures ssh to a given remote machine running linux is working, and sets it up with a password request if not 
linux_ssh_ensure :: proc(target:string) -> bool{
	//BatchMode forbids interactive prompts, so this succeeds only if key auth already works
	testCmd := []string{"wsl.exe", "ssh", "-o", "BatchMode=yes", "-o", "ConnectTimeout=5", "-o", "StrictHostKeyChecking=accept-new", target, "true"}
	state, _, _, err := os.process_exec({command = testCmd}, context.temp_allocator)
	if err == nil && state.exit_code == 0 do return true

	printf("No ssh key auth to %s yet, setting it up...", target)

	/*
	wsl.exe parses its command line with windows double-quote rules only, so the process quoting already keeps this one argv element intact.
	Literal single quotes would reach bash as characters and turn the script into one giant command name.
	*/
	keygenCmd := []string{"wsl.exe", "bash", "-c",
		`mkdir -p ~/.ssh && ([ -f ~/.ssh/id_ed25519 ] || ssh-keygen -q -t ed25519 -N '' -f ~/.ssh/id_ed25519)`
	}
	kgState, _, _, kgErr := os.process_exec({command = keygenCmd}, context.temp_allocator)
	if kgErr != nil || kgState.exit_code != 0{
		print("ERROR: Failed to generate an ssh key in WSL!")
		return false
	}

	//ssh password request
	print("Enter the remote machine's password in the window that just opened.")
	copyCmd := []string{
		"powershell.exe", "-Command",
		fmt.tprintf("$p = Start-Process -Wait -PassThru wsl.exe -ArgumentList 'ssh-copy-id','-o','StrictHostKeyChecking=accept-new','%s'; exit $p.ExitCode", target),
	}
	cpState, _, _, cpErr := os.process_exec({command = copyCmd}, context.temp_allocator)
	if cpErr != nil || cpState.exit_code != 0{
		print("ERROR: ssh-copy-id failed! Is the machine reachable and the password correct?")
		return false
	}

	state2, _, _, err2 := os.process_exec({command = testCmd}, context.temp_allocator)
	if err2 != nil || state2.exit_code != 0{
		print("ERROR: ssh key auth still failing after setup!")
		return false
	}
	print("ssh key auth ready!")
	return true
}

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

	runConfig := config_run_load() //resample run settings on every launch

	//pick up any build config edits made since the last full rebuild
	newConfig := config_load_or_generate("config_build.json", CONFIG_BUILD_DEFAULT, CONFIG_BUILD_SCHEMA_VERSION, context.temp_allocator)
	if newConfig != config_build{
		//the daemon shares its console with the interactive shell, so it can't reliably read stdin. Ask with a popup instead.
		choice := windows.MessageBoxW(nil,
			windows.L("The build config has changed since the last full rebuild.\nRebuild from scratch with the new config?\n\n(\"No\" launches with the old config)"),
			windows.L("Massimodin Builder"),
			windows.MB_YESNO | windows.MB_ICONQUESTION | windows.MB_SETFOREGROUND | windows.MB_TOPMOST,
		)
		if choice == windows.IDYES{
			config_build_load() //the temp-allocated comparison copy must not be kept, re-read with the persistent allocator
			full_rebuild()
			return
		}
	}

	defer game_launch_requested = false

	buildErrorCheck :: proc(parentDir:string, exeName:string)->(exePath:string, ok:bool){
		errorLogPath, _ := filepath.join({parentDir, "compile_error_log.txt"}, context.temp_allocator)
		if os.exists(errorLogPath){
			data, readErr := os.read_entire_file(errorLogPath, context.temp_allocator)
			if readErr == nil && len(data) > 0{
				printf("Compile errors exist, cannot launch:\n%s", string(data))
				return
			}
		}
	
		exePath, _ = filepath.join({parentDir, exeName}, context.temp_allocator)
		if !os.exists(exePath){
			printf("ERROR: '%s' not found.", exeName)
			return
		}

		ok = true
		return
	}

	tracyRun :: proc(remoteIP:string=""){
		if config_build.tracyEnable{
			if tracy_process.pid != 0{
				_ = os.process_kill(tracy_process)
				_,_ = os.process_wait(tracy_process) //also closes and frees the process handle
			}

			cmd := []string{
				filepath.join({paths.src, "_tools/dev_tools/Tracy.exe"}) or_else "",
				"-a", "127.0.0.1"
			}
			if remoteIP != ""{
				if at := strings.index_byte(remoteIP, '@'); at >= 0 do cmd[2] = remoteIP[at+1:]
				else do cmd[2] = remoteIP
			}
			tracy_process,_ = os.process_start({command=cmd})
		}
	}

	//kill any lingering linux ssh process
	if linux_ssh_process.pid != 0{
		_ = os.process_kill(linux_ssh_process)
		_,_ = os.process_wait(linux_ssh_process)
		linux_ssh_process = {}
	}

	switch runConfig.runTarget{
		case "win64", "windows":
			exePath,ok := buildErrorCheck(paths.build_win64, "DioramaBreak.exe")
			if !ok do return

			print("No build errors, launching...")

			//Route the game's stdout/stderr to the daemon's console so its output shows in the terminal.
			_,_ = os.process_start({command = {exePath}, stdout = os.stdout, stderr = os.stderr})
		
			tracyRun()
		
		case "linux":
			if !config_build.targetLinux{
				print("ERROR: Linux is not enabled as a build target! Set targetLinux to true in config_build.json and rebuild.")
				return
			}

			target := runConfig.targetLinuxRemoteTestingIP
			if target == ""{
				print("ERROR: targetLinuxRemoteTestingIP in config_run.json not set.")
				return
			}

			exePath,ok := buildErrorCheck(paths.build_linux, "DioramaBreak")
			if !ok do return

			if !linux_ssh_ensure(target) do return

			//deploy
			remoteDir :: "DioramaBreak" //relative to the remote home dir
			printf("Deploying linux build to %s...", target)
			rsyncCmd := []string{
				"wsl.exe", "rsync", "-az", "--delete",
				fmt.tprintf("%s/", wsl_path(paths.build_linux)),
				fmt.tprintf("%s:%s/", target, remoteDir),
			}
			rsyncHandle, rsyncErr := os.process_start({command = rsyncCmd, stdout = os.stdout, stderr = os.stderr})
			if rsyncErr != nil{
				printf("ERROR: Failed to start rsync (%v). Is WSL set up?", rsyncErr)
				return
			}
			rsyncState, _ := os.process_wait(rsyncHandle)
			if rsyncState.exit_code != 0{
				print("ERROR: Deploy failed! Is the machine reachable?")
				return
			}

			display := ":0"
			whoCmd := []string{"wsl.exe", "ssh", target, "who"}
			whoState, whoOut, _, whoErr := os.process_exec({command = whoCmd}, context.temp_allocator)
			if whoErr == nil && whoState.exit_code == 0{
				out := string(whoOut)
				if i := strings.index(out, "(:"); i >= 0{
					if j := strings.index_byte(out[i:], ')'); j > 0 do display = out[i+1:][:j-1]
				}
			}

			//Launch remotely with output streamed back into this console, inside Valve's Steam Linux Runtime 4.0 container (Steam + app 4183110 must be installed on the remote machine).
			//The binaries target the steamrt4 glibc floor (2.41), so on older distros they only run inside that container; this is also what the Steam depot runs under in production.
			printf("Launching on remote machine at '%s'...", target)
			sshCmd := []string{
				"wsl.exe", "ssh", target,
				fmt.tprintf("cd %s && chmod +x DioramaBreak && ulimit -c unlimited && DISPLAY=%s ~/.steam/steam/steamapps/common/SteamLinuxRuntime_4/run -- ./DioramaBreak", remoteDir, display),
			}
			linux_ssh_process,_ = os.process_start({command = sshCmd, stdout = os.stdout, stderr = os.stderr})

			tracyRun(target)

		case:
			printf("ERROR: Target '%s' is not implemented yet, please select a different run target.", runConfig.runTarget)
	}
}