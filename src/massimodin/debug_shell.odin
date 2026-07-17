package massimodin //@nested-tags:debug

import "../imgui"
import "core:fmt"
import "core:strings"
import "core:slice"
import "base:runtime"
import "core:mem"
import "core:os"
import "core:encoding/json"

DebugShellSystem :: struct{
	_lines:[dynamic]cstring,
	_history:[dynamic]string,
	_history_head:int,
	_scroll_to_bottom:bool,
	_input_buffer:[256]byte,
	_input:cstring,
	_is_open:bool,
	_suggestions_filtered:[]string,
	_suggestions_selected_index:int,

	_commands:map[string]ShellCommand,
	_command_names:[dynamic]string
}
shell:^DebugShellSystem

SHELL_OPEN_KEY :: Key.GRAVE
SHELL_HISTORY_FILENAME :: "shell_history.json"

_shell_init :: proc(){
	shell = new(DebugShellSystem, os_allocator)
	init(&shell._lines, os_allocator)
	init(&shell._history, os_allocator)

	init(&shell._commands, assets.allocator)
	init(&shell._command_names, assets.allocator)

	shell._input = cstring(&shell._input_buffer[0])
	shell._history_head = -1

	historyPath := save_file_path_make(SHELL_HISTORY_FILENAME)
	if(os.exists(historyPath)){
		fileData, readErr := os.read_entire_file(historyPath, context.temp_allocator)
		assert(readErr == nil, "Error reading shell history file.")
		jsonArr := json_parse(fileData).(json.Array)
		reserve(&shell._history, len(jsonArr))
		for v in jsonArr{
			append(&shell._history, string_clone(v.(json.String), os_allocator))
		}
	}
	//_shell_commands_init() - commands get loaded in _packed_assets_reload_all since pointers to asset names need to be up-to-date  
}

_shell_print :: proc(fmt_str:string, args: ..any){
	newString := fmt.tprintf(fmt_str, ..args)
	append(&shell._lines, strings.clone_to_cstring(newString))
}

_shell_update_suggestions :: proc(commandStrings:[]string){
	i := len(commandStrings)-1

	suggestions:[]string
	if(i == 0) do suggestions = shell._command_names[:]
	else{
		command, ok := shell._commands[commandStrings[0]]
		if !ok do return
		if i-1 >= len(command.params) do return
		switch suggs in command.params[i-1].suggestions{
			case []string: suggestions = suggs
			case proc(params:[]string)->[]string: suggestions = suggs(commandStrings[1:])
		}
	}

	if(suggestions == nil) do return

	filter := strings.to_lower(commandStrings[i], context.temp_allocator)
	if(filter == "" && i == 0) do return
	
	shell._suggestions_filtered = strings_filter(suggestions, filter, os_allocator)

	sort_general(shell._suggestions_filtered)

	if(len(shell._suggestions_filtered) == 1 && filter == string(shell._suggestions_filtered[0])) do _shell_clear_suggestions()
}

_shell_clear_suggestions :: proc(){
	for str in shell._suggestions_filtered{
		delete(str, os_allocator)
	}
	delete(shell._suggestions_filtered, os_allocator)
	shell._suggestions_filtered = nil
	shell._suggestions_selected_index = 0
}


_shell_input_callback :imgui.InputTextCallback: proc "c" (data: ^imgui.InputTextCallbackData) -> i32{
	context = runtime.default_context()
	for flag in imgui.InputTextFlag do if flag in data.EventFlag {
		#partial switch flag{
			case .CallbackHistory:
				if(len(shell._suggestions_filtered) > 0) do return 0
				dir := int(data.EventKey == imgui.Key.UpArrow) - int(data.EventKey == imgui.Key.DownArrow)
				shell._history_head = clamp(shell._history_head + dir, -1, len(shell._history) - 1)
				imgui.InputTextCallbackData_DeleteChars(data, 0, data.BufTextLen)
				if(shell._history_head >= 0){
                    imgui.InputTextCallbackData_InsertChars(data, 0, strings.clone_to_cstring(shell._history[shell._history_head], context.temp_allocator))
				}
				data.CursorPos = data.BufTextLen
                data.SelectionStart = data.BufTextLen
                data.SelectionEnd = data.BufTextLen
				data.BufDirty = true
			case .CallbackEdit:
				shell._history_head = -1
				_shell_clear_suggestions()

				commandStrings := strings.split(string(data.Buf), " ", context.temp_allocator)
				_shell_update_suggestions(commandStrings)

			case .CallbackCompletion:
				if(len(shell._suggestions_filtered) == 0) do return 0
				commandStrings := strings.split(string(data.Buf), " ", context.temp_allocator)
				completedCommandStrings := make([dynamic]string, context.temp_allocator)
				for i in 0..<len(commandStrings)-1{
					append(&completedCommandStrings, commandStrings[i])
				}
				append(&completedCommandStrings, string(shell._suggestions_filtered[shell._suggestions_selected_index]))
				append(&completedCommandStrings, "")
				finalCommandString := strings.join(completedCommandStrings[:], " ", context.temp_allocator)
				imgui.InputTextCallbackData_DeleteChars(data, 0, data.BufTextLen)
				imgui.InputTextCallbackData_InsertChars(data, 0, strings.clone_to_cstring(
					finalCommandString,
					context.temp_allocator
				))
				data.CursorPos = data.BufTextLen
                data.SelectionStart = data.BufTextLen
                data.SelectionEnd = data.BufTextLen
				data.BufDirty = true
				_shell_clear_suggestions()
				_shell_update_suggestions(completedCommandStrings[:])
		}
	}
	return 0
}

_shell_execute_command :: proc(input:cstring){
	trimmedInput := strings.trim_right_space(string(input))
	commandStrings := strings.split(trimmedInput, " ", context.temp_allocator)
	command, ok := shell._commands[commandStrings[0]]
	if !ok {
		_shell_print("Error: Command not found!")
		return
	}

	requiredParamCount := 0
	for param in command.params{
		if(param.defaultValue == "") do requiredParamCount += 1
	}

	paramStrings := slice.to_dynamic(commandStrings[1:], context.temp_allocator)

	providedParamCount := len(paramStrings)

	if(providedParamCount > len(command.params)){
		_shell_print("Error: Too many parameters! Provided %i, max %i", providedParamCount, len(command.params))
		return
	}
	if(providedParamCount < requiredParamCount){
		_shell_print("Error: Not enough parameters! Provided %i, requires %i", providedParamCount, requiredParamCount)
		return
	}

	for len(paramStrings) < len(command.params){
		append(&paramStrings, command.params[len(paramStrings)].defaultValue)
	}

	command.callback(..paramStrings[:])
}



_shell_hint_get :: proc() -> cstring{

	commandStrings := strings.split(string(shell._input), " ", context.temp_allocator)
	if(commandStrings[0] == "") do return ""

	suggestion:string
	if(len(shell._suggestions_filtered) > 0) do suggestion = string(shell._suggestions_filtered[shell._suggestions_selected_index])
	
	commandName:string
	selectedCommand:ShellCommand
	ok:bool
	if(len(commandStrings) == 1 && suggestion != ""){
		commandName = suggestion
		selectedCommand, ok = shell._commands[suggestion]
	} 
	else{
		commandName = commandStrings[0]
		selectedCommand, ok = shell._commands[commandStrings[0]]
	}
	if !ok do return ""

	hintBuilder:strings.Builder
	strings.builder_init(&hintBuilder, context.temp_allocator)

	if(len(commandStrings) == 1) do strings.write_string(&hintBuilder, strings.trim_left(commandName, commandStrings[0]))

	for param, i in selectedCommand.params{
		commandInd := len(commandStrings)-2
		if(i < commandInd) do continue
		if(i == commandInd){
			if(commandStrings[len(commandStrings)-1] == "") do strings.write_string(&hintBuilder, param.name)
		}
		else{
			strings.write_string(&hintBuilder, " ")
			strings.write_string(&hintBuilder, param.name)
		}
	}

	return strings.clone_to_cstring(string(hintBuilder.buf[:]), context.temp_allocator)
}

_shell_update :: proc(){
	if(input.keyboard_state[SHELL_OPEN_KEY] && !input.keyboard_state_last_frame[SHELL_OPEN_KEY]) do shell._is_open = !shell._is_open //cannot use key_pressed since it's blocked while shell is open
	if(!shell._is_open) do return

	imgui.Begin("Debug Shell")
	imgui.SetWindowSize(Vec2{600, 350})

    // Display previous logs
    if(imgui.BeginChild("ScrollingRegion", Vec2{0, -imgui.GetFrameHeightWithSpacing()})){
        for line in shell._lines {
            imgui.TextUnformatted(line)
        }
        if(shell._scroll_to_bottom){
            imgui.SetScrollHereY(1.0)
            shell._scroll_to_bottom = false
        }
    }
    imgui.EndChild()

    // Command-line
    imgui.Separator()
	imgui.Text("%s", ">")
	imgui.SameLine()
    submitted := imgui.InputText("##input", shell._input, uint(len(shell._input_buffer)), 
		{.EnterReturnsTrue, .CallbackCompletion, .CallbackHistory, .CallbackEdit}, _shell_input_callback
	)
	imgui.SetKeyboardFocusHere(-1) //keep the text input field in focus while shell is open

	//update hint
	hint := _shell_hint_get()
    if hint != "" {
		hintPos := imgui.GetItemRectMin() + imgui.GetStyle().FramePadding
		hintPos.x += imgui.CalcTextSize(shell._input).x
		imgui.DrawList_AddText(
			imgui.GetWindowDrawList(), 
			hintPos, 
			imgui.GetColorU32ImVec4(imgui.Vec4{0.5, 0.5, 0.5, 0.5}),
			hint
		)
    }
	

    if submitted && shell._input != ""{

		if(shell._history_head >= 0){
			ordered_remove(&shell._history, shell._history_head)
			shell._history_head = -1
		}
		inject_at(&shell._history, 0, strings.clone_from_cstring(shell._input))
		_shell_history_save()

		_shell_print("> %s", shell._input)
		_shell_execute_command(shell._input)
        shell._scroll_to_bottom = true
		shell._input_buffer = {}
		_shell_clear_suggestions()
    }


	if len(shell._suggestions_filtered) > 0 {
		imgui_suggestions_selector(shell._suggestions_filtered, &shell._suggestions_selected_index)
	}

	imgui.End()
}

_shell_history_save :: proc(){
	save := strings.builder_make(context.temp_allocator)
	json_marshal(&save, shell._history)
	_ = os.write_entire_file(save_file_path_make(SHELL_HISTORY_FILENAME), save.buf[:])
}