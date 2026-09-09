package massimodin_builder

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:strings"
import "core:time"
import "core:thread"
import "core:sys/windows"
import "core:mem"
import "core:slice"

DEBOUNCE_MS :: 20
POLL_TIMEOUT_MS :: 30
WATCH_BUFFER_SIZE :: 65536
//Named kernel event used to signal release_build_export.ps1 that the initial full rebuild is done
REBUILD_DONE_EVENT :: `Local\MassimodinBuilderRebuildDone`

//pipeline kinds that must be packed into the final packed asset file 
PIPELINE_PACKED_KINDS :: PipelineKinds{.fonts, .shaders, .curves, .stages}
//pipelines that produce generated code
PIPELINE_CODEGEN_KINDS :: PipelineKinds{.sprites, .fonts, .shaders, .curves, .stages, .dialogues, .audio}
//pipelines that depend on other pipelines and must wait to be dispatched
PIPELINE_DEPENDENT_KINDS :: PipelineKinds{.code, .packer, .otherTargets}
//pipelines whose build/_win64 outputs get mirrored into the other targets' build dirs by the otherTargets pipeline
PIPELINE_MIRRORED_KINDS :: PipelineKinds{.audio, .sprites, .dialogues, .packer}

pipelines:[PipelineKind]Pipeline
pipeline_pool:thread.Pool
iocp:windows.HANDLE
os_allocator:mem.Allocator

paths:struct{
	project:string,
	build:string,
	build_win64:string,
	build_linux:string,
	src:string,
	massimodin:string,
	script:string,
	exe:string
}

//Block execution until all provided pipeline kinds are idle
pipelines_block :: proc(kinds:PipelineKinds){
	for{
		allDone := true
		for kind in kinds{
			#partial switch pipeline_status_get(&pipelines[kind]){
				case .failed: panic(fmt.tprintf("%v pipeline failed unexpectedly", kind))
				case .running:
					allDone = false
					break
			}
		}
		if allDone do break
		tray_update()
		thread.yield()
	}
}


// Full rebuild
full_rebuild :: proc(){
	printf("Starting full rebuild...")

	dir_remove(paths.build)

	// Delete generated .g.odin files
	deleteCodegen :: proc(dir:string){
		dh, err := os.open(dir)
		if err != nil do return
		entries, err2 := os.read_all_directory(dh, context.temp_allocator)
		os.close(dh)
		if err2 != nil do return

		for entry in entries{
			if entry.type == .Directory do deleteCodegen(entry.fullpath)
			else if strings.has_suffix(entry.name, ".g.odin") do os.remove(entry.fullpath)
		}
	}
	deleteCodegen(paths.massimodin)

	buildSubdirs := [?]string{
		"_win64", 
		"_win64/texture_groups", 
		"_win64/dialogues", 
		"shaders", 
		"font_pages", 
		"font_page_indexes",
		"curves", 
		"stages"
	}
	os.make_directory(paths.build)
	for subdir in buildSubdirs{
		path, _ := filepath.join({paths.build, subdir}, context.temp_allocator)
		os.make_directory(path)
	}
	if config_build.previewTexturePages do os.make_directory(filepath.join({paths.build, "texture_page_previews"}, context.temp_allocator) or_else "")

	// Dispatch all non-dependent pipelines in parallel
	for kind in ~PIPELINE_DEPENDENT_KINDS{
		pipeline_task_dispatch(&pipelines[kind], true)
	}
	pipelines_block(~PIPELINE_DEPENDENT_KINDS)

	// Dependent pipelines
	pipeline_task_dispatch(&pipelines[.packer], true)
	pipeline_task_dispatch(&pipelines[.code], true)

	pipelines_block({.packer})

	// Other targets' builds mirror the artifacts produced above (code binaries come from the code pipeline)
	if building_other_targets{
		pipeline_task_dispatch(&pipelines[.otherTargets], true)
		pipelines_block({.otherTargets})
	}

	pipelines_block({.code})


	for &p in pipelines{
		pipeline_status_set(&p, .idle)
		p.codegenDirty = false //the full rebuild compiled everything already
	}

	//Signal the release export script that the initial full rebuild is done.
	//Manual-reset named event is a 1-bit kernel signal; the daemon keeps running afterwards.
	doneEvent := windows.CreateEventW(nil, windows.TRUE, windows.FALSE, windows.utf8_to_wstring(REBUILD_DONE_EVENT, context.temp_allocator))
	if doneEvent != nil{
		windows.SetEvent(doneEvent)
		windows.CloseHandle(doneEvent)
	}

	printf("----------------------")
	printf("FULL REBUILD COMPLETE!")
	printf("----------------------")
}

//Main
init :: proc(){
	process_tree_kill_on_exit_init() //nothing this daemon spawns may ever outlive it

	//Force the odin compiler to emit colored output even though we redirect it to the log file.
	_ = os.set_env("FORCE_COLOR", "1")

	// Directory resolution
	paths.project, _ = filepath.join({#location().file_path, "/../../../../../"})
	paths.build, _ = filepath.join({paths.project, "build"})
	paths.build_win64, _ = filepath.join({paths.build, "_win64"})
	paths.build_linux, _ = filepath.join({paths.build, "_linux"})
	paths.src, _ = filepath.join({paths.project, "src"})
	paths.massimodin, _ = filepath.join({paths.project, "src/massimodin"})
	paths.script, _ = filepath.join({#location().file_path, "/../../"})
	paths.exe, _ = filepath.join({paths.build_win64, "DioramaBreak.exe"})

	config_build_load()
	config_run_load() //result discarded, this is just so a missing/outdated run config gets generated and reviewed at startup

	PipelineDef :: struct{
		runProc:PipelineRunProc,
		watchDir:string,
		watchExtensions:[]string,
		watchRecursive:bool
	}
	defs := [PipelineKind]PipelineDef{
		.sprites   = {pipeline_sprites_run,   filepath.join({paths.project, "sprites"}) or_else "",   			{".aseprite", ".ase", ".png"}, 	true},
		.fonts     = {pipeline_fonts_run,     filepath.join({paths.project, "fonts"}) or_else "",     			{".json", ".ttf", ".index"},   	true},
		.shaders   = {pipeline_shaders_run,   filepath.join({paths.project, "shaders"}) or_else "",   			{".hlsl"},                     	true},
		.dialogues = {pipeline_dialogues_run, filepath.join({paths.project, "dialogues"}) or_else "", 			{".md"},                       	true},
		.curves    = {pipeline_curves_run,    filepath.join({paths.project, "curves"}) or_else "",    			{".curve"},                    	true},
		.stages    = {pipeline_stages_run,    filepath.join({paths.project, "stages"}) or_else "",    			{".json"},                     	true},
		.libs      = {pipeline_lib_run,       filepath.join({paths.project, "lib"}) or_else "",       			{},                            	true},
		.audio     = {pipeline_audio_run,     filepath.join({paths.project, "audio/Metadata/Event"}) or_else "", {".xml"},                      	false},
		.code      = {pipeline_code_run,      paths.src,     													{".odin"},             			true},
		.packer    = {pipeline_packer_run,    "",           													{},                            	false},
		.otherTargets = {pipeline_other_targets_run, "",											 		{},                            	false},
	}

	for kind in PipelineKind{
		def := defs[kind]
		pipelines[kind] = Pipeline{
			kind = kind,
			pendingFiles = make([dynamic]PipelineChangedFile),
			run = def.runProc,
			watchDir = def.watchDir,
			watchExtensions = slice.clone(def.watchExtensions),
			watchRecursive = def.watchRecursive,
			allocator=allocator_make()
		}
	}

}

main :: proc(){
	console_mode_capture()
	os_allocator = context.allocator //for doing os allocations from threaded code

	init()

	print("BUILDER STARTED")
	print("Build config:", config_build)

	threadCount := max(os.get_processor_core_count() / 2, 2)
	thread.pool_init(&pipeline_pool, allocator_make(), threadCount)
	thread.pool_start(&pipeline_pool)

	tray_init()
	full_rebuild()

	printf("Entering watch mode...")
	watcher_init()

	for{
		free_all(context.temp_allocator)
		watcher_update()
		game_launch_check()
		tray_update()
	}
}
