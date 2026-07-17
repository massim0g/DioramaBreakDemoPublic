package massimodin_builder

import "core:sync"
import "core:os"
import "core:strings"
import "core:path/filepath"
import "core:fmt"
import "core:time"

dll_hot_reloaded:bool

COMPILE_TIMEOUT :: 30*time.Second

compiler_process_wait :: proc(handle:os.Process) -> os.Process_State{
	state, err := os.process_wait(handle, COMPILE_TIMEOUT)
	if err == os.General_Error.Timeout{
		print("WARNING: Compiler process hung past the timeout! Killing it...")
		_ = os.process_kill(handle)
		state, _ = os.process_wait(handle) //reap the killed process and free the handle
	}
	return state
}

error_log_print :: proc(logPath:string){
	logContent, _ := os.read_entire_file(logPath, context.temp_allocator)
	print("CODE BUILD COMPLETED WITH ERROR(S):")
	if len(logContent) > 0 do printf("%s", string(logContent))
	else do printf("...error retrieving error log at '%s'... geez...", logPath)
}

code_compiler_flags_append :: proc(cmd:^[dynamic]string){
	if config.debug{
		append(cmd, "-debug")
	}
	else{
		resourcePath, _ := filepath.join({paths.script, "DioramaBreak.res"})
		append(cmd, fmt.aprintf("-resource:%s", resourcePath))
		append(cmd, "-subsystem:windows")
	}

	if config.tracyEnable{
		append(cmd, "-define:TRACY_ENABLE=true")
	}

	if config.errorCheckDisable{
		append(cmd, "-disable-assert")
		append(cmd, "-no-type-assert")
		append(cmd, "-no-bounds-check")
	}
}

//Recompile just the exe. Used after promoting a hot-reloaded DLL so the exe never goes stale relative to it.
code_exe_compile :: proc() -> bool{
	context.allocator = context.temp_allocator

	logPath, _ := filepath.join({paths.build_win64, "compile_error_log.txt"})

	exeCmd := make([dynamic]string)
	append(&exeCmd, "odin")
	append(&exeCmd, "build")
	append(&exeCmd, paths.src)
	append(&exeCmd, fmt.aprintf("-out:%s", paths.exe))
	code_compiler_flags_append(&exeCmd)

	logFile, logErr := os.open(logPath, os.O_WRONLY | os.O_CREATE | os.O_TRUNC | os.O_INHERITABLE)
	if logErr != nil{
		print("ERROR: Failed to open compile error log")
		return false
	}

	handle, err := os.process_start({command = exeCmd[:], stdout = logFile, stderr = logFile})
	if err != nil{
		os.close(logFile)
		print("ERROR: Failed to start odin compiler for .exe")
		return false
	}

	state := compiler_process_wait(handle)
	os.close(logFile) //close before reading/removing so the file isn't locked on Windows

	if state.exit_code != 0{
		print("WARNING: .exe recompilation failed!")
		error_log_print(logPath)
		return false
	}

	os.remove(logPath)
	return true
}

pipeline_code_run :: proc(pipeline:^Pipeline, fullRebuild:bool){
	outDir := paths.build_win64
	logPath, _ := filepath.join({outDir, "compile_error_log.txt"})

	changedComponents := make([dynamic]PipelineChangedFile)
	for &file in pipeline.pendingFiles{
		base := filepath.base(file.path)
		if strings.has_prefix(base, "co_"){
			append(&changedComponents, file)

			if !file.exists{
				genPath := strings.concatenate({
					file.path[:len(file.path) - len(".odin")],
					"_meta.g.odin",
				})
				if os.exists(genPath) do os.remove(genPath)
			}
			else do generate_component_meta(file.path)
		}
	}

	if len(changedComponents) > 0{
		generate_components_inits(changedComponents[:])
	}

	compilerFlags := make([dynamic]string)
	code_compiler_flags_append(&compilerFlags)

	dllCmd := make([dynamic]string)
	append(&dllCmd, "odin")
	append(&dllCmd, "build")
	append(&dllCmd, paths.massimodin)
	append(&dllCmd, "-build-mode=dll")
	for f in compilerFlags do append(&dllCmd, f)
	if !config.debug{
		append(&dllCmd, fmt.aprintf(
			"-extra-linker-flags:/DEBUG /OPT:REF /OPT:ICF /PDB:%s\\massimodin.pdb",
			outDir,
		))
	}

	gameRunning := process_running(paths.exe)

	if gameRunning{
		printf("Game running! Hot reloading engine DLL...")

		if config.debug{
			hotDir, _ := filepath.join({outDir, "massimodin_hot_reloaded"})
			if !os.exists(hotDir) do os.make_directory(hotDir)

			dllCount := count_files_with_ext(hotDir, ".dll")
			hotOut := filepath.join({hotDir, fmt.aprintf("massimodin%i.dll", dllCount)}) or_else ""
			append(&dllCmd, fmt.aprintf("-out:%s", hotOut))

			logFile, logErr := os.open(logPath, os.O_WRONLY | os.O_CREATE | os.O_TRUNC | os.O_INHERITABLE)
			if logErr != nil{
				print("ERROR: Failed to open compile error log")
				pipeline_status_set(pipeline, .failed)
				return
			}
			printf("Compiling hot-reload DLL...")
			
			//create lock file
			lockPath,_ := filepath.join({hotDir, ".compilelock"})
			lockErr := os.write_entire_file(lockPath, "")
			if lockErr != nil{
				print("WARNING: Error creating lock file, %v", lockErr)
				return
			}
			defer os.remove(lockPath)

			handle, err := os.process_start({command = dllCmd[:], stdout = logFile, stderr = logFile})
			if err != nil{
				os.close(logFile)
				printf("ERROR: failed to start odin compiler")
				pipeline_status_set(pipeline, .failed)
				return
			}

			state := compiler_process_wait(handle)
			os.close(logFile) //close before reading/removing so the file isn't locked on Windows

			if state.exit_code != 0{
				if os.exists(hotOut) do os.remove(hotOut)
				printf("WARNING: Hot-reload DLL compilation failed!")
				error_log_print(logPath)
				return
			}
			os.remove(logPath)

			sync.atomic_store(&dll_hot_reloaded, true)
		}

	}
	else{
		logFile, logErr := os.open(logPath, os.O_WRONLY | os.O_CREATE | os.O_TRUNC | os.O_INHERITABLE)
		if logErr != nil{
			print("ERROR: Failed to open build error log")
			pipeline_status_set(pipeline, .failed)
			return
		}
		exeCmd := make([dynamic]string)
		append(&exeCmd, "odin")
		append(&exeCmd, "build")
		append(&exeCmd, paths.src)
		append(&exeCmd, fmt.aprintf("-out:%s", paths.exe))
		for f in compilerFlags do append(&exeCmd, f)

		print("Compiling exe...")
		exeHandle, exeErr := os.process_start({command = exeCmd[:], stdout = logFile, stderr = logFile})
		if exeErr != nil{
			os.close(logFile)
			print("ERROR: Failed to start odin compiler for .exe")
			pipeline_status_set(pipeline, .failed)
			return
		}

		engineOut, _ := filepath.join({outDir, "massimodin.dll"})
		
		append(&dllCmd, fmt.aprintf("-out:%s", engineOut))

		print("Compiling engine DLL...")
		dllHandle, dllErr := os.process_start({command = dllCmd[:], stdout = logFile, stderr = logFile})
		if dllErr != nil{
			os.close(logFile)
			print("ERROR: failed to start odin compiler for DLL")
			pipeline_status_set(pipeline, .failed)
			return
		}

		dllState := compiler_process_wait(dllHandle)
		exeState := compiler_process_wait(exeHandle)

		os.close(logFile) //close before reading/removing so the file isn't locked on Windows

		compileFailed := exeState.exit_code != 0 || dllState.exit_code != 0
		if compileFailed{
			if exeState.exit_code != 0 do print("WARNING: .exe compilation failed!")
			if dllState.exit_code != 0 do print("WARNING: DLL compilation failed!")
			error_log_print(logPath)
			return
		}

		os.remove(logPath)

	}
	print("CODE BUILD COMPLETED WITH NO ERRORS!")
}
