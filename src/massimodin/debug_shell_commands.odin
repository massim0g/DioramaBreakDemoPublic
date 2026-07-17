#+feature dynamic-literals
package massimodin //@nested-tags:debug

import "core:strings"
import "core:strconv"
import "core:slice"
import "../tinyfd"
import "core:path/filepath"
import "core:reflect"


ShellCommand :: struct{
	description:string,
	params:[dynamic]ShellParam,
	callback:proc(params:..string)
}
ShellParam :: struct{
	name:string,
	suggestions:union{[]string,proc(params:[]string)->[]string},
	defaultValue:string
}

_shell_commands_reload :: proc(){
	context.allocator = assets.allocator
	clear(&shell._command_names)
	clear(&shell._commands)
	shell._commands = {
		"help" = {
			"Get information about a command.",
			{
				{
					"command_name",
					nil,
					""
				}
			},
			proc(params:..string){
				if !(params[0] in shell._commands){
					_shell_print("Error: Command '%s' not found!", params[0])
					return
				}

				command := shell._commands[params[0]]
				namesToPrint := make([dynamic]string, context.temp_allocator)
				append(&namesToPrint, params[0])
				for param in command.params{
					append(&namesToPrint, param.name)
				}
				_shell_print("%s", strings.join(namesToPrint[:], " ", context.temp_allocator))
				_shell_print("%s", command.description)
			}
		},
		"draw" = {
			"Create an entity that draws a sprite.",
			{
				{"sprite", sprites.names[:], ""},
				{"x=0", nil, "0"},
				{"y=0", nil, "0"}
			},
			proc(params:..string){
				sprite, ok := &sprites._sprites_map[params[0]]
				if !ok{
					_shell_print("Error: Sprite '%s' not found!", params[0])
					return
				}

				x := 0
				y := 0
				if(len(params) > 1){
					x,ok = strconv.parse_int(params[1])
					if !ok do x = 0
				}
				if(len(params) > 2){
					y,ok = strconv.parse_int(params[2])
					if !ok do y = 0
				}

				spr := entity_make(Spriter)
				transform := coadd(spr.entity, Transform)
				transform.pos = {f32(x),f32(y)}
				spriter_set(spr, sprite)

			}
		},
		"spawn" = {
			"Spawn entities",
			{
				{"component", entities._component_names, ""},
				{"n=1", nil, "1"}
			},
			proc(params:..string){
				n,ok := string_to_int(params[1])
				if(!ok){
					_shell_print("Could not parse number of entities '%s'!", params[1])
					return
				}

				componentType, cOk := coid_from_name(params[0])
				if(!cOk){
					_shell_print("Component type '%s' not found!", params[0])
					return
				}

				for i in 0..<n{
					entity_make(componentType)
				}
			}
		},
		"flag" = {
			"Sets a flag.",
			{
				{"flag", nil, ""},
				{"val=1", nil, "1"}
			},
			proc(params:..string){
				flag(params[0], params[1])
			}
		},
		"flag_get" = {
			"Prints the value of a flag.",
			{
				{"flag", nil, ""},
			},
			proc(params:..string){
				_shell_print(flag_get(params[0]))
			}
		},
		"flags_clear" = {
			"Clears a flag level.",
			{
				{"level=temp", reflect.enum_field_names(FlagLevel), "temp"}
			},
			proc(params:..string){
				if l,ok := reflect.enum_from_name(FlagLevel, params[0]); ok{
					flags_clear(l)
				}
				else do _shell_print("Unknown flag level '%s'", params[0])
			}
		},
		"debug_info" = {
			"Toggles the debug info display",
			{},
			proc(params:..string){
				debug.showInfo = !debug.showInfo
			}
		},
		"combat_start" = {
			"Starts combat mode",
			{{"disable_timestop=false", nil, "false"}},
			proc(params:..string){
				combat_start(au.battleTutorial, timeStopForceDisable=params[0]=="true")
			}
		},
		"combat_end" = {
			"Ends combat mode",
			{{"immediately=false",nil,"false"}},
			proc(params:..string){
				combat_end(params[0]=="true"?true:false)
			}
		},
		"dialogue" = {
			"Plays a dialogue",
			{
				{"dialogue", dialogue.names[:], ""},
				{"label", proc(params:[]string)->[]string{
					dl, ok := &dialogue._dialogues_map[params[0]]
					if !ok do return nil
					out,_ := map_keys(dl.locales[0].labelsMap, context.temp_allocator)
					return out
				}, "nil"}
			},
			proc(params:..string){
				dl, ok := &dialogue._dialogues_map[params[0]]
				if !ok{
					_shell_print("Error: Dialogue '%s' not found!", params[0])
					return
				}

				label := params[1]
				if(label == "nil") do label = ""
				if(label != "" && !(label in dl.locales[0].labelsMap)){
					_shell_print("Error: Dialogue '%s' does not contain label '%s'!", params[0], params[1])
					return
				}
				
				dialogue_open(dl, label)
			}
		},
		"dialogue_close" = {
			"Closes the current dialogue.",
			{},
			proc(params:..string){
				dialogue_close()
			}
		},
		"stage" = {
			"Go to a stage",
			{
				{"stage", stage.names[:], ""}
			},
			proc(params:..string){
				s, ok := &stage._stages_map[params[0]]
				if !ok{
					_shell_print("Error: Stage '%s' not found!", params[0])
					return
				}

				stage_goto(s)
			}
		},
		"title_screen" = {
			"Return to the title screen.",
			{},
			proc(params:..string){titleScreen_goto()}
		},
		"free_cam" = {
			"Enables free camera movement with arrow keys. Set to 0 to disable and reset camera.",
			{
				{"speed=3", nil, "3"}
			},
			proc(params:..string){
				speed,ok := string_to_f32(params[0])
				if(!ok){
					_shell_print("Could not parse free cam speed '%s'!", params[0])
					return
				}

				if(speed == 0){
					debug.freeCamSpeed = 0
					stage.target_camera_pos = DISPLAY_SIZE/2
				}
				else{
					debug.freeCamSpeed = speed
				}
			}
		},
		"collision_visible" = {
			"Toggles collider visibility.",
			{},
			proc(params:..string){
				_sprite_masks_load_debug_textures()
				collision_system._colliders_draw = !collision_system._colliders_draw
			}
		},
		"curve_edit" = {
			"Opens the curve editor to a specific curve. If the specified curve does not exist, creates it.",
			{
				{"curve", curves.names[:], ""}
			},
			proc(params:..string){
				_curve_editor_close() //clear previous working state

				name := params[0]
				if name == "" do return
				
				c, ok := &curves._curves_map[name]
				if !ok{
					c = _curve_save_as(name)
					if c == nil do return
				}

				_curve_editor_open(c)

				shell._is_open = false
			}
		},

		"playtest_demo" = {
			"Reset the playtest demo to a specific phase.",
			{{"phase", playtest_phase_names, ""}},
			proc(params:..string){
				if !contains(playtest_phase_names, params[0]){
					_shell_print("Unknown phase name '%s'!", params[0])
					return
				}
				playtest_demo_reset(params[0])
			}
		},
		"demo_reset" = {
			"Reset the demo.",
			{},
			proc(params:..string){
				save.active = true
				game_save_file_delete()
				titleScreen_goto()
			}
		},
		"save_enable" = {
			"Enables saving.",
			{},
			proc(params:..string){
				save.active = true
			}
		},
		"combat_test" = {
			"Test combat against a specific unit",
			{
				{"unitID", combat.unit_init_names, ""},
				{"playerUnit=pro", combat.unit_init_names, "pro"}
			},
			proc(params:..string){
				pid,ok:=player_character_string_to_id(params[1])
				if !ok{
					_shell_print("Invalid player unit ID '%s'!", params[1])
					return
				}
				if !save.characters[pid].inParty do player_character_join_party(pid)

				stage_load(st.newCargoLiftTest)

				combatAreaPos := stage.combatBounds.pos
				
				p := entity_make(Player).stageCharacter
				estring_set(&p.initID, params[1], true)
				stageCharacter_reload(p)

				transform_set(p.transform, combatAreaPos + {48, 64})
				scface(p, .right)

				scmake(params[0], combatAreaPos + {224, 64}, .left)
				
				_entities_just_made_process()

				//player_character_equip(.pro, "prosBlade")
				
				proc_call_delayed(proc(){
					combat_start()
				}, 1)
			}
		},

		"display_performance_mode" = {
			"Sets the display performance mode",
			{{"mode", reflect.enum_field_names(DisplayPerformanceMode), ""}},
			proc(params:..string){
				mode,ok := reflect.enum_from_name(DisplayPerformanceMode, params[0])
				if !ok{
					_shell_print("Unknown performance mode '%s'!", params[0])
					return
				}
				display_performance_mode_set(mode)
			}
		},

		"test" ={
			"Calls a preset custom proc, for testing.",
			{},
			proc(params:..string){
				flag("tutorialLostTo", "polema")
				titleScreen_goto()
				dialogue_open(di.paxDemoOutro, "combatFailure")
			}
		},

		"cutscene"={
			"Starts a cutscene",
			{
				{"namespace", proc(params:[]string)->[]string{out,_:=map_keys(cutscene._cutscenes_map, context.temp_allocator); return out}, ""},
				{"cutscene", proc(params:[]string)->[]string{
					ns := params[0]
					if m,ok := cutscene._cutscenes_map[ns];ok{
						out,_:=map_keys(m, context.temp_allocator)
						return out
					}
					return nil
				}, ""}
			},
			proc(params:..string){
				ns := params[0]
				if ns not_in cutscene._cutscenes_map{
					_shell_print("Cutscene namespace '%s' not found!", ns)
					return
				}

				cutsceneName := params[1]

				if cutsceneName not_in cutscene._cutscenes_map[ns]{
					_shell_print("Cutscene '%s' not found in namespace '%s'!", cutsceneName, ns)
					return
				}

				cutscene_start(cutsceneName, ns)
			}
		},

		"combat_revive_all"={
			"Revives all knocked out combat units.",
			{},
			proc(params:..string){
				units := coall(CombatUnit)
				for &unit in units{
					if unit.unitState == .knockedOut{
						unit.hp = unit.maxHp
						unit.unitState = .alive
						stageCharacter_sprite_set(unit.stageCharacter, unit.sprites.koGetup, unit.sprites.idle)
					}
				}
				combat_resolve_start()
			}
		},
		"combat_resolving_ui_toggle"={
			"Toggles top-level resolving UI draws.",
			{},
			proc(params:..string){
				combat.resolving_ui_disable = !combat.resolving_ui_disable
			}
		},
		"combat_kill"={
			"Kills a specific unit.",
			{{"unitID", proc(params:[]string)->[]string{
				out := make([dynamic]string, context.temp_allocator)
				units := combatUnits_get()
				for unit in units{
					print("Got init ID:", unit.initID)
					if unit.initID.s != "" do append(&out, unit.initID.s)
				}
				return out[:]
			}, ""}},
			proc(params:..string){
				units := combatUnits_get()
				for unit in units{
					if unit.initID.s == params[0]{
						combatUnit_damage(unit, 999, 12)
					}
				}
				combat_resolve_start()
			}
		},
		"combat_damage"={
			"Damages a specific unit.",
			{
				{"unitID", proc(params:[]string)->[]string{
					out := make([dynamic]string, context.temp_allocator)
					units := combatUnits_get()
					for unit in units{
						if unit.initID.s != "" do append(&out, unit.initID.s)
					}
					return out[:]
				}, ""}, 
				{"damage", nil, ""},
				{"hitstun=1", nil, "1"},
			},
			proc(params:..string){
				units := combatUnits_get()
				for unit in units{
					if unit.initID.s == params[0]{
						damage, ok1 := string_to_int(params[1])
						if !ok1 {_shell_print("Could not parse damage value '%s'", params[1]); return}
						hitstun, ok2 := string_to_int(params[2])
						if !ok1 {_shell_print("Could not parse hitstun value '%s'", params[2]); return}
						combatUnit_damage(unit, damage, hitstun)
					}
				}
				combat_resolve_start()
			}
		},

		"follower"={
			"Add a unit as a player follower.",
			{{"unitID", reflect.enum_field_names(PlayerCharacterID), ""}},
			proc(params:..string){
				player_follower_add(params[0])
				player_spawn_followers()
			}
		},

		"stages_overwrite_all"={
			"Saves over all stages.",
			{},
			proc(params:..string){
				_stage_edit_start(false)
				for _,&stage in stage._stages_map{
					stage_load(&stage)
					_stage_save()
				}
			}
		}
	}

	for key in shell._commands{
		append(&shell._command_names, key)
	}
	shell._commands["help"].params[0].suggestions = shell._command_names[:]
}