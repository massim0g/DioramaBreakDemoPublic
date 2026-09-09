package massimodin //@nested-tags:_main

import "../sdl3"
import "../tracy"
import "../kernel32"
import "base:runtime"
import "core:os"
import "core:sys/windows"
import "core:sys/posix"
import "core:path/filepath"
import "core:mem"
import "core:mem/virtual"
import stacktrace "core:debug/trace"

GAME_VERSION :: "chapter_1_demo_v1.4.0"
GAME_VERSION_INT:i32

/*Versioning Guide:
The actual version is the last number (e.g. "v0.1.0"), this is *never* reset.
The version number is always preceded by a short descriptive lowercase string that is meant to be pretty-printed. This string describes the kind of release this is.
The three version numbers are used as follows:
- Major: Major update milestone (e.g. release, coming out of beta, major content additions)
- Minor: For significant planned updates (e.g. compilation of bugfixes/balance changes, minor content additions)
- Patch: For hotfixes and unexpected quick changes.
*/

_quit_flag:^bool
_sdl_ev:^sdl3.Event
_tracy_frame_name:^cstring
_stacktrace_context:^stacktrace.Context

game_quit :: proc(){ //exit the game at the end of the current loop
	_quit_flag^ = true
}

// The engine's odin runtime does not start up automatically on linux, so this is used to start it manually
@export
_odin_runtime_init :: proc "c" (){
	context = runtime.default_context()
	runtime._startup_runtime()
}

@export
_set_entry_globals :: proc(
	__os_allocator:Allocator,
	__quit_flag:^bool,
	__sdl_ev:^sdl3.Event,
	__stacktrace_context:^stacktrace.Context,
	__game_version:^string
){

	//import values from runner
	_quit_flag = __quit_flag
	_sdl_ev = __sdl_ev
	_stacktrace_context = __stacktrace_context
	os_allocator = __os_allocator
	default_allocator = context.allocator

	//export values to runner
	__game_version^ = GAME_VERSION

	//derive values independently
	executable_directory = string_clone(string(sdl3.GetBasePath()))
	
	verParts := string_split(peek(string_split(GAME_VERSION, "_v")), ".")
	GAME_VERSION_INT = i32(string_to_int(verParts[0]) or_else 0) << 16 | i32(string_to_int(verParts[1]) or_else 0) << 8 | i32(string_to_int(verParts[2]) or_else 0)

	thread_count = os.get_processor_core_count()
	when ON_PC{
		thread_count_optimum = max(thread_count/2, 2)
	}
	else{ //todo: set per-console
		thread_count_optimum = max(thread_count, 2)
	}

	when DEBUG{
		project_directory, _ = filepath.join({#location().file_path, "/../../.."})
	}

	when tracy.TRACY_ENABLE{
		massimodinDir, _ := filepath.join({project_directory, "src/massimodin"}, context.temp_allocator) //still works on linux since tracy is looking at the windows paths either way
		tracy_whitelist_directory,_ = filepath.replace_separators(massimodinDir, '/')
	}
}

@export
_init_default_allocators :: proc(os:^Allocator, default:^Allocator){
	defaultAllocBufferSize :: mem.Megabyte*512 //static reserve, pages only commit as used
	
	os^ = context.allocator

	when DEBUG{ //todo: fix stage editor undo/redo and cut this out
		defaultArena := new(virtual.Arena)
		err := virtual.arena_init_static(defaultArena, defaultAllocBufferSize)
		assertf(err == .None, "Error creating default arena! %v", err)
		default^ = virtual.arena_allocator(defaultArena)
	}
	else{
		default^ = os^ //just use the os allocator in release builds for individual frees. Overhead is likely not an issue, but do double-check when profiling
	}

	// when tracy.TRACY_ENABLE{
	// 	default^ = tracy.MakeProfiledAllocator(default^)
	// 	os^ = tracy.MakeProfiledAllocator(os^)
	// }
}

@export
_game_init :: proc(){
	when DEBUG do _testbed_pre_init()

	when !ODIN_DEBUG && ON_PC{
		//route stdout/stderr into a log file next to the executable.
		logFile, err := os.open(filepath.join({executable_directory, "log_engine.txt"}, context.temp_allocator) or_else "", {.Write, .Create, .Trunc})
		if err == nil {
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
	}

	print("-GAME INIT-")

	when(tracy.TRACY_ENABLE){
		tracy.SetThreadName("main")
		// tracy_auto_trace = true
		// defer tracy_auto_trace = false
	}

	print("Initializing critical systems and preloading heavy assets...")
	//order is important for these!
	_time_system_init()
	_asset_system_init()
	_audio_system_init()
	_audio_banks_preload_all()
	_save_system_init() //inits blank settings
	_display_system_init()
	_render_system_init()
	_display_targets_init()
	_sprite_system_init()
	_camera_system_init()
	_texture_groups_index_file_load()
	_dialogue_system_init()
	_dialogues_preload_all()
	
	print("Initializing other engine systems...")
	_entity_system_init()
	_flags_init()
	_input_system_init()
	_collision_system_init()
	_text_system_init()
	_tileset_system_init()
	_particles_system_init()
	_sequence_system_init()
	_ui_system_init()
	_curve_system_init()
	_steamworks_init()
	_release_channel_get()

	//if something failed to init (mainly steamworks), quit early
	if _quit_flag^{
		print("Warning: Init failed, quitting early...")
		return
	}

	print("Initializing game systems...")
	_stage_system_init()
	
	_combat_system_init()
	_item_system_init()
	_cutscene_system_init()
	_player_character_system_init()
	_foliage_system_init()

	//debug-only systems
	when(DEBUG){
		_imgui_init()
		_debug_system_init()
		_shell_init()
	}

	print("Loading packed assets...")
	for bank in AUDIO_BANKS_PERMANENT do audio_bank_load_block(bank) //bank files are probably loaded by now, block here and start preloading samples before other heavy loads
	_packed_assets_load()
	_assets_load_end()

	//prepare save file for new games/debugging
	save_reset()

	//Wait until all async loading is done
	{
		trace("async load wait")
		_fonts_load_block()
		texture_group_load_block(groupNames=TEXTURE_GROUPS_PERMANENT)
		audio_bank_sample_load_block()
	}

	//sort any entities created during the init calls
	_entities_just_made_process()

	//load settings
	print("Loading settings...")
	loadedSettings := settings_load()
	
	print("GAME INITIALIZED!")
	
	when DEBUG do _testbed_post_init()
	else{
		if !loadedSettings{
			display.hd_enabled = true
			entity_make(LanguageSelect)
		}
		else do titleScreen_goto()
		// stage_load(st.IrisForestMinimaEncounter)
		// p := entity_make(Player)
		// transform_set(p.transform, Vec2{400, 400})
	}
}

tracy_frame_name:cstring = "Main Frame" //can't technically be a constant, but is for practical purposes

@export
_game_update :: proc(){
	when tracy.TRACY_ENABLE{
		tracy.FrameMark()
		tracy.FrameMarkStart(tracy_frame_name)
		tracy_context_stack = make([dynamic]tracy.ZoneCtx, context.temp_allocator)
		tracy_auto_trace = true
		defer{
			tracy_auto_trace = false
			tracy.FrameMarkEnd(tracy_frame_name)
		}
	}
	else do time_frame_mark("Update")

	_delta_time_target_refresh()

	//poll events
	input.mouse_scroll = 0
	for sdl3.PollEvent(_sdl_ev){
		//print("poll event?")
		#partial switch _sdl_ev.type{
			case .QUIT:
				game_quit()

			case .GAMEPAD_ADDED:
				joyId := _sdl_ev.gdevice.which
				for i in 0..<GAMEPADS_CAP{
					if(input.gamepads_open[i] == nil && sdl3.IsGamepad(joyId)){
						input.gamepads_open[i] = sdl3.OpenGamepad(joyId)
						break
					}
				}

			case .GAMEPAD_REMOVED:
				joyId := _sdl_ev.gdevice.which
				for i in 0..<GAMEPADS_CAP{
					if(input.gamepads_open[i] != nil && joyId == sdl3.GetJoystickID(sdl3.GetGamepadJoystick(input.gamepads_open[i]))){
						sdl3.CloseGamepad(input.gamepads_open[i])
						input.gamepads_open[i] = nil
						input.gamepad_states[i] = GamepadState{}
						input.gamepad_states_last_frame[i] = GamepadState{}
					}
				}

			case .MOUSE_WHEEL:
				input.mouse_scroll = int(-_sdl_ev.wheel.y)

			case .WINDOW_MOUSE_ENTER: input.mouse_in_window = true
			case .WINDOW_MOUSE_LEAVE: input.mouse_in_window = false
		}

		when (DEBUG) do _imgui_sdlevent_process(_sdl_ev)
	}
	
	//INPUT
	{
		//trace("Input Update")
		_input_update_states()
		ginputs_update(ginputs)
	}

	//UPDATE
	when(DEBUG) do _imgui_update() //new frame
	
	_steamworks_update()
	_delayed_procs_update()

	//entities logical update
	{
		//trace("Entities Update")
		
		_spriters_bulk_update()
		
		if(!DEBUG || !stage_edit.enabled){
			_entities_event_process(.updateBegin)
			_entities_event_process(.update)
			_entities_event_process(.updateEnd)
		}
	}
	_combat_update()
	_dialogue_system_update()
	_particles_system_update()
	_stage_system_update()
	_cutscene_system_update()
	_camera_system_update()
	_audio_system_update()

	when(DEBUG){
		_shell_update()
		_stage_edit_update()
		_curve_editor_update()
		_debug_system_update()
		_testbed_update()
	}


	_entities_just_made_process()
	_entities_destruction_process()

	_stageEntities_bulk_update()

	
	//DRAW
	time_frame_mark("Draw")
	_window_system_update()
	_entities_event_process(.preDraw)
	
	//choose render mode
	if(stage_edit.enabled){ //stage edit
		_stage_render()
	}
	else if display.hd_enabled{ //hd rendering mode, for title screen
		_display_pre_draw() //targets main texture

		_stage_render()

		render_depth_ui(.misc)
		_ui_system_draw()
		render_depth_ui(.dialogue)
		_dialogue_system_draw()

		//sequence deferred draws (set their own depth)
		_sequence_deferred_draws_draw()
		
		when DEBUG{
			render_depth_layer(.uiTop)
			_testbed_draw()
			_debug_capture_update()
		}

		_display_post_draw()
	}
	else{ //standard in-game rendering mode
		_display_pre_draw() //targets main texture

		//draw stage elements depth-sorted
		_stage_render()

		//UI
		render_depth_ui(.combatUI)
		_combat_UI_draw()
		render_depth_ui(.misc)
		_ui_system_draw()
		if !dialogue.hd_overlay_enabled{
			render_depth_ui(.dialogue)
			_dialogue_system_draw()
		}

		//sequence deferred draws (set their own depth)
		_sequence_deferred_draws_draw()

		when DEBUG{
			render_depth_layer(.uiTop)
			_testbed_draw()
			_debug_capture_update()
		}

		if dialogue.hd_overlay_enabled{
			render_depth_ui(.dialogue)
			tex_target_set(display.hd_tex)
			draw_clear(DISPLAY_BASE_COLOR)
			render_quad(display.window_tex.ptr, tex_sampler(display.window_tex), Quad{
				worldRect = {0,Vec2(display.hd_tex.size)},
				uvRect = {0,0,1,1},
				blend = BLEND_WHITE,
			})
			display.hd_enabled = true
			_dialogue_system_draw()
			
			_display_post_draw()
			display.hd_enabled = false
		}
		else{
			_display_post_draw() //resets target and depth to window
		}
	}

	when DEBUG{
		_imgui_draw()
		if(debug.showInfo) do _debug_info_draw()
	}

	_entities_just_made_process() //ensures any entities somehow created during drawing get sorted properly before temp allocations are cleared

	//STAGE LOAD
	if(stage._goto != nil){
		goto := stage._goto
		stage_load(goto)
		stage._goto = nil
	}
	
	//ASSET HOT RELOAD
	_assets_hot_reload_check()

	//FINISH UPDATE
	time.frame += 1
}

@export
_game_quit :: proc(){
	print("QUITTING GAME")
	sdl3.DestroyWindow(display._window)
	_steamworks_shutdown()
	os.exit(0)
}
