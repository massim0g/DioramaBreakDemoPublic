#+feature using-stmt
package massimodin_builder

import "core:sync"
import "core:os"
import "core:strings"
import "core:path/filepath"
import "core:fmt"
import "core:time"

LinuxCompileHandles :: struct{
	soHandle,exeHandle:os.Process, 
	logFile:^os.File, 
	objRoot:string
}

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
	if config_build.debug{
		append(cmd, "-debug")
	}
	else{
		append(cmd, "-o:speed")
	}

	if config_build.tracyEnable{
		append(cmd, "-define:TRACY_ENABLE=true")
	}

	if config_build.errorCheckDisable{
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
	append(&exeCmd, fmt.aprintf("-resource:%s", filepath.join({paths.script, "DioramaBreak.res"}) or_else ""))
	if !config_build.debug do append(&exeCmd, "-subsystem:windows")
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



//Linux target

/*
The linux binaries are cross-compiled entirely on this machine: odin emits linux ELF objects (odin only refuses the LINK step for cross targets), and the builder links them itself with LLD against a Steam Linux Runtime (steamrt4) sysroot in .deps.
Linking against the steamrt4 sysroot pins the glibc/library floor to exactly what SteamOS and Steam's runtime container guarantee every player has.
The sysroot is fetched by install.ps1 (crane registry pull + tar extraction, no docker needed).
*/



//convert a windows absolute path to its WSL mount path (C:\foo\bar -> /mnt/c/foo/bar)
wsl_path :: proc(windowsPath:string, allocator:=context.temp_allocator) -> string{
	if len(windowsPath) < 3 || windowsPath[1] != ':' do return strings.clone(windowsPath, allocator)
	drive := strings.to_lower(windowsPath[:1], context.temp_allocator)
	rest, _ := strings.replace_all(windowsPath[2:], "\\", "/", context.temp_allocator)
	return strings.concatenate({"/mnt/", drive, rest}, allocator)
}

//Links the emitted ELF objects into the exe (isEngineLib=false, PIE) or the engine .so (isEngineLib=true)
code_linux_link_start :: proc(outPath:string, objDir:string, isEngineLib:bool, logFile:^os.File) -> (handle:os.Process, ok:bool){
	context.allocator = context.temp_allocator

	// Get paths
	sysroot, _ := filepath.join({paths.project, ".deps/steamrt4_sysroot"})
	if !os.exists(sysroot){
		print("ERROR: linux sysroot not found! Install linux build dependencies with install.ps1.")
		return
	}
	gccDir, _ := filepath.join({sysroot, "/usr/lib/gcc/x86_64-linux-gnu/14"})
	libDir, _ := filepath.join({sysroot, "/usr/lib/x86_64-linux-gnu"})
	libLinux, _ := filepath.join({paths.project, "lib/_linux"})

	cmd := make([dynamic]string)
	
	// Get linker and sysroot
	append(&cmd, 
		filepath.join({paths.project, ".deps/odin/bin/lld-link.exe"}) or_else "",
		"-flavor", "gnu", //odin only ships LLD under its COFF driver name, but it is the universal LLD binary; -flavor gnu selects the ELF driver
		fmt.tprintf("--sysroot=%s", sysroot), //also rewrites the absolute paths inside glibc's libc.so linker script
		"--error-limit=0"
	)

	// Engine Lib vs Runner Executable flags
	if isEngineLib{
		append(&cmd, "-shared", "-soname", filepath.base(outPath))
	}
	else{
		append(&cmd, 
			"-pie", 
			"--dynamic-linker", 
			"/lib64/ld-linux-x86-64.so.2", 
			filepath.join({libDir, "Scrt1.o"}) or_else ""
		)
	}

	// C runtime start objects
	append(&cmd, 
		filepath.join({libDir, "crti.o"}) or_else "",
		filepath.join({gccDir, "crtbeginS.o"}) or_else ""
	)

	// Odin compiler object output
	objFound := false
	for entries, _ := os.read_all_directory_by_path(objDir, context.temp_allocator); entry in entries{
		if strings.has_suffix(entry.name, ".o"){
			append(&cmd, entry.fullpath)
			objFound = true
		}
	}
	if !objFound{
		printf("ERROR: No compiled linux objects found for linker in '%s'!", objDir)
		return
	}

	// Add OS library paths to linker search
	append(&cmd, 
		fmt.aprintf("-L%s", gccDir),
		fmt.aprintf("-L%s", libDir)
	)

	// Game libraries from lib/_linux
	
	append(&cmd, "--as-needed") //under --as-needed only the .so's actually referenced are recorded as DT_NEEDED (resolved at runtime next to the exe via the $ORIGIN rpath).
	gameLibDirs := []string{
		libLinux,
		filepath.join({libLinux, config_build.debug ? "_debugOnly" : "_releaseOnly"}) or_else "",
	}
	for dir in gameLibDirs{
		for entries,_ := os.read_all_directory_by_path(dir, context.temp_allocator); entry in entries{
			if strings.has_prefix(entry.name, "tracy") && (!config_build.tracyEnable || !isEngineLib) do continue
			if strings.contains(entry.name, ".so") || strings.has_suffix(entry.name, ".a") do append(&cmd, entry.fullpath)
		}
	}
	
	// Other C standard libraries, C runtime end objects, and final output path
	append(&cmd, 
		"-lstdc++", "-lstdc++exp", //stdc++ for imgui; stdc++exp because core:debug/trace needs __glibcxx_backtrace_*, which gcc 14 ships only there
		"-lm", "-lc", "-lgcc", "-lgcc_s",
		"--no-as-needed",
		filepath.join({gccDir, "crtendS.o"}) or_else "",
		filepath.join({libDir, "crtn.o"}) or_else "",
		"-rpath", "$ORIGIN", //no shell is involved anywhere in this invocation, so $ORIGIN stays a literal
		"-o", outPath
	)
	
	h,startErr := os.process_start({command = cmd[:], stdout = logFile, stderr = logFile})
	if startErr != nil{
		printf("ERROR: Failed to start the linux linker (%v)", startErr)
		return
	}
	
	return h, true
}

//begins compiling linux code
code_linux_compile_start :: proc(compilerFlags:[]string) -> (handles:LinuxCompileHandles, err:os.Error){
	using handles
	context.allocator = context.temp_allocator

	print("Compiling linux binaries...")

	if !os.exists(paths.build_linux) do os.make_directory(paths.build_linux)

	//emit linux ELF objects for both binaries, in parallel like the windows compiles
	logPath, _ := filepath.join({paths.build_linux, "compile_error_log.txt"})
	logFile, _ = os.open(logPath, os.O_WRONLY | os.O_CREATE | os.O_TRUNC | os.O_INHERITABLE)
	defer if err != nil do os.close(logFile)

	objRoot,_ = filepath.join({paths.build, "linux_obj"}) //temp dir for intermediate linux compile artifacts
	engineObjDir, _ := filepath.join({objRoot, "engine"})
	_ = os.make_directory_all(engineObjDir)
	runnerObjDir, _ := filepath.join({objRoot, "runner"})
	_ = os.make_directory_all(runnerObjDir)

	soCmd := make([dynamic]string)
	append(&soCmd, "odin", "build", paths.massimodin, "-target:linux_amd64")
	append(&soCmd, fmt.aprintf("-out:%s", filepath.join({engineObjDir, "libmassimodin.o"}) or_else ""))
	append(&soCmd, "-build-mode:obj", "-reloc-mode:pic")
	for f in compilerFlags do append(&soCmd, f)
	soHandle = os.process_start({command = soCmd[:], stdout = logFile, stderr = logFile}) or_return
	
	exeCmd := make([dynamic]string)
	append(&exeCmd, "odin", "build", paths.src, "-target:linux_amd64")
	append(&exeCmd, fmt.aprintf("-out:%s", filepath.join({runnerObjDir, "DioramaBreak.o"}) or_else ""))
	append(&exeCmd, "-build-mode:obj", "-reloc-mode:pic")
	for f in compilerFlags do append(&exeCmd, f)
	exeHandle = os.process_start({command = exeCmd[:], stdout = logFile, stderr = logFile}) or_return

	return
}

code_linux_compile_end :: proc(using handles:LinuxCompileHandles)->(ok:bool){
	context.allocator = context.temp_allocator

	logPath, _ := filepath.join({paths.build_linux, "compile_error_log.txt"})
	engineObjDir, _ := filepath.join({objRoot, "engine"})
	runnerObjDir, _ := filepath.join({objRoot, "runner"})

	soState := compiler_process_wait(soHandle)
	exeState := compiler_process_wait(exeHandle)

	defer{
		os.close(logFile)
		if !ok do error_log_print(logPath)
		else do os.remove(logPath)
	}

	//link
	print("Linking linux binaries...")
	soLinkHandle, soOk := code_linux_link_start(filepath.join({paths.build_linux, "libmassimodin.so"}) or_else "", engineObjDir, true, logFile)
	if !soOk{
		print("WARNING: linux engine .so link start failed!")
		return
	}
	exeLinkHandle, exeOk := code_linux_link_start(filepath.join({paths.build_linux, "DioramaBreak"}) or_else "", runnerObjDir, false, logFile)
	if !exeOk{
		print("WARNING: linux engine .exe link start failed!")
		return
	}

	soLinkState := compiler_process_wait(soLinkHandle)
	if soLinkState.exit_code != 0{
		print("WARNING: linux engine .so link failed!")
		return
	}
	exeLinkState := compiler_process_wait(exeLinkHandle)
	if exeLinkState.exit_code != 0{
		print("WARNING: linux engine .exe link failed!")
		return
	}

	ok = true
	return
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
	if !config_build.debug{
		append(&dllCmd, fmt.aprintf(
			"-extra-linker-flags:/DEBUG /OPT:REF /OPT:ICF /PDB:%s\\massimodin.pdb",
			outDir,
		))
	}

	gameRunning := process_running(paths.exe)

	if gameRunning{
		if config_build.debug{
			printf("Game running! Hot reloading engine DLL...")
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
		append(&exeCmd, fmt.aprintf("-resource:%s", filepath.join({paths.script, "DioramaBreak.res"}) or_else ""))
		if !config_build.debug do append(&exeCmd, "-subsystem:windows")
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
			print("ERROR: Failed to start odin compiler for DLL")
			pipeline_status_set(pipeline, .failed)
			return
		}

		//other build targets
		linuxHandles:LinuxCompileHandles
		defer if linuxHandles.objRoot != "" do dir_remove(linuxHandles.objRoot)
		if config_build.targetLinux{
			err:os.Error
			linuxHandles,err = code_linux_compile_start(compilerFlags[:])
			if err != nil{
				os.close(logFile)
				print("ERROR: Failed to start odin compiler for linux")
				pipeline_status_set(pipeline, .failed)
				return
			}
		}
		//add other build targets as needed

		if config_build.targetLinux do code_linux_compile_end(linuxHandles)
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
