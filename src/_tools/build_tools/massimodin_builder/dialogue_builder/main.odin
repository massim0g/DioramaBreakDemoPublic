package dialogue_builder

import "core:slice"
import "core:bytes"
import "core:os"
import "core:strings"
import "core:path/filepath"
import "core:fmt"
import "base:runtime"
import win "core:sys/windows"

// UTILS
write_v :: #force_inline proc (buf:^bytes.Buffer, val:$T){
	val := val
	bytes.buffer_write_ptr(buf, &val, size_of(T))
}

sanitize_asset_name :: proc(name:string, allocator := context.allocator) -> string{
	result, _ := strings.replace_all(name, " ", "_", allocator)
	result, _ = strings.replace_all(result, "-", "_", allocator)
	return result
}

//Drops a leading UTF-8 BOM (EF BB BF) if present
strip_bom :: proc(data:[]u8) -> []u8{
	if len(data) >= 3 && slice.simple_equal(data[:3], []u8{0xEF, 0xBB, 0xBF}) do return data[3:]
	return data
}

// EXPORTED
dialogue_build_file :: proc(inPath:string, out:^bytes.Buffer)->[]u8{
	dialogueData, readErr := os.read_entire_file(inPath, context.temp_allocator)
	if readErr != nil{
		fmt.printfln("Could not read %s", inPath)
		return nil
	}
	content := string(strip_bom(dialogueData))

	rawLines := strings.split_lines(content)
	processed := make([dynamic]string, 0, len(rawLines))

	for line in rawLines{
		l := line
		commentIdx := strings.index(l, "//")
		if commentIdx >= 0{
			l = l[:commentIdx]
		}

		trimmed := strings.trim_left_space(l)
		if len(trimmed) > 0 && trimmed[0] == '#'{
			stripped := strings.trim_left(trimmed, "#")
			stripped = strings.trim_left_space(stripped)
			l = strings.concatenate({"#", stripped})
		}

		l = strings.trim_right_space(l)

		if len(l) > 0{
			append(&processed, l)
		}
	}

	output := strings.join(processed[:], "\n")

	dialogueName := sanitize_asset_name(filepath.stem(inPath), context.temp_allocator)
	start := len(out.buf)
	write_v(out, u16(len(dialogueName)))
	write_v(out, u64(len(output)))
	bytes.buffer_write_string(out, dialogueName)
	bytes.buffer_write_string(out, output)
	return out.buf[start:]
}

//recursively builds every .md file under dir into out
dialogues_build_dir :: proc(dir:string, out:^bytes.Buffer) -> (built,failed:int){
	files, err := os.read_directory_by_path(dir, 0, context.temp_allocator)
	if err != nil do return
	for file in files{
		if file.type == .Directory{
			subBuilt, subFailed := dialogues_build_dir(file.fullpath, out)
			built += subBuilt
			failed += subFailed
		}
		else if filepath.ext(file.fullpath) == ".md"{
			if dialogue_build_file(file.fullpath, out) != nil do built += 1
			else do failed += 1
		}
	}
	return
}

// BUILDER WINDOW

CONTROL_ID_INPUT_BROWSE  :: 101
CONTROL_ID_OUTPUT_BROWSE :: 102
CONTROL_ID_BUILD         :: 103
CONTROL_ID_CLOSE         :: 104

window:win.HWND
window_font:win.HFONT
input_dir_field:win.HWND
output_dir_field:win.HWND
language_field:win.HWND
status_text:win.HWND

main :: proc(){
	win.CoInitializeEx() //the folder browser dialogs require COM

	instance := win.HINSTANCE(win.GetModuleHandleW(nil))
	class := win.WNDCLASSW{
		lpfnWndProc = window_message_handle,
		hInstance = instance,
		lpszClassName = win.L("DialogueBuilderWindow"),
		hCursor = win.LoadCursorW(nil, transmute(win.wstring)win.IDC_ARROW),
		hbrBackground = win.HBRUSH(rawptr(uintptr(win.COLOR_BTNFACE + 1))),
	}
	win.RegisterClassW(&class)

	window = win.CreateWindowExW(
		0, class.lpszClassName, win.L("Diorama Break Dialogue Builder"),
		win.WS_OVERLAPPED | win.WS_CAPTION | win.WS_SYSMENU | win.WS_MINIMIZEBOX,
		win.CW_USEDEFAULT, win.CW_USEDEFAULT, 560, 230,
		nil, nil, instance, nil
	)
	window_font = win.HFONT(win.GetStockObject(win.DEFAULT_GUI_FONT))

	control_make("STATIC", "Input directory:", 0, 12, 14, 126, 18)
	input_dir_field = control_make("EDIT", "", win.WS_BORDER | win.ES_AUTOHSCROLL, 140, 11, 350, 22)
	control_make("BUTTON", "...", 0, 496, 11, 30, 22, CONTROL_ID_INPUT_BROWSE)

	control_make("STATIC", "Output directory:", 0, 12, 44, 126, 18)
	output_dir_field = control_make("EDIT", "", win.WS_BORDER | win.ES_AUTOHSCROLL, 140, 41, 350, 22)
	control_make("BUTTON", "...", 0, 496, 41, 30, 22, CONTROL_ID_OUTPUT_BROWSE)

	control_make("STATIC", "Language code or name:", 0, 12, 74, 126, 18)
	language_field = control_make("EDIT", "", win.WS_BORDER | win.ES_AUTOHSCROLL, 140, 71, 120, 22)

	status_text = control_make("STATIC", "", 0, 12, 103, 514, 32)

	control_make("BUTTON", "Build", win.BS_DEFPUSHBUTTON, 360, 140, 80, 26, CONTROL_ID_BUILD)
	control_make("BUTTON", "Close", 0, 446, 140, 80, 26, CONTROL_ID_CLOSE)

	fields_load()

	win.ShowWindow(window, win.SW_SHOW)

	message:win.MSG
	for bool(win.GetMessageW(&message, nil, 0, 0)){
		win.TranslateMessage(&message)
		win.DispatchMessageW(&message)
	}
}

window_message_handle :: proc "system" (hwnd:win.HWND, message:win.UINT, wParam:win.WPARAM, lParam:win.LPARAM) -> win.LRESULT{
	context = runtime.default_context()
	switch message{
		case win.WM_COMMAND:
			switch win.LOWORD(win.DWORD(wParam)){
				case CONTROL_ID_INPUT_BROWSE: directory_field_browse(input_dir_field, "Select the folder containing only your translated dialogue .md files")
				case CONTROL_ID_OUTPUT_BROWSE: directory_field_browse(output_dir_field, "Select the folder to save the packed localization file to")
				case CONTROL_ID_BUILD: build_run()
				case CONTROL_ID_CLOSE: win.DestroyWindow(hwnd)
			}
		case win.WM_DESTROY:
			fields_save()
			win.PostQuitMessage(0)
		case: return win.DefWindowProcW(hwnd, message, wParam, lParam)
	}
	return 0
}

build_run :: proc(){
	defer free_all(context.temp_allocator)

	fields_save()

	inDir := strings.trim_space(window_text_get(input_dir_field))
	outDir := strings.trim_space(window_text_get(output_dir_field))
	language := strings.trim_space(window_text_get(language_field))

	if !os.is_directory(inDir){
		status_set("The input directory does not exist!")
		return
	}
	if !os.is_directory(outDir){
		status_set("The output directory does not exist!")
		return
	}
	if language == ""{
		status_set("Enter a language code or name!")
		return
	}
	if strings.contains_any(language, `\/:*?"<>|`){
		status_set(`The language code/name cannot contain \ / : * ? " < > |`)
		return
	}

	out:bytes.Buffer
	bytes.buffer_init_allocator(&out, 0, 0, context.temp_allocator)

	built, failed := dialogues_build_dir(inDir, &out)
	if built == 0{
		status_set("No dialogue .md files were found in the input directory!")
		return
	}

	fileName := fmt.tprintf("%s.dialogue", language)
	outPath := filepath.join({outDir, fileName}, context.temp_allocator) or_else ""
	if os.write_entire_file(outPath, out.buf[:]) != nil{
		status_set(fmt.tprintf("Could not write '%s'!", outPath))
		return
	}

	if failed > 0 do status_set(fmt.tprintf("Packed %i dialogues into '%s', but %i files could not be read!", built, fileName, failed))
	else do status_set(fmt.tprintf("Packed %i dialogues into '%s'!", built, fileName))
}

directory_field_browse :: proc(field:win.HWND, title:string){
	dialog:^win.IFileOpenDialog
	if !win.SUCCEEDED(win.CoCreateInstance(win.CLSID_FileOpenDialog, nil, win.CLSCTX_INPROC_SERVER, win.IID_IFileOpenDialog, cast(^rawptr)&dialog)) do return
	defer dialog.Release(dialog)

	dialog.SetOptions(dialog, win.FOS_PICKFOLDERS | win.FOS_FORCEFILESYSTEM | win.FOS_PATHMUSTEXIST)
	dialog.SetTitle(dialog, win.utf8_to_wstring(title))

	if !win.SUCCEEDED(dialog.Show(dialog, window)) do return //cancelled

	item:^win.IShellItem
	if !win.SUCCEEDED(dialog.GetResult(dialog, &item)) do return
	defer item.Release(item)

	path:win.LPWSTR
	if !win.SUCCEEDED(item.GetDisplayName(item, .FILESYSPATH, &path)) do return
	defer win.CoTaskMemFree(path)

	win.SetWindowTextW(field, win.wstring(path))
}

//The last entered value of each field is remembered between runs in appdata

fields_config_path :: proc() -> string{
	appData := os.get_env("LOCALAPPDATA", context.temp_allocator)
	if appData == "" do return ""
	return filepath.join({appData, "DioramaBreak", "dialogue_builder.cfg"}, context.temp_allocator) or_else ""
}

fields_save :: proc(){
	path := fields_config_path()
	if path == "" do return
	os.make_directory(filepath.dir(path))
	content := strings.join({
		window_text_get(input_dir_field),
		window_text_get(output_dir_field),
		window_text_get(language_field),
	}, "\n", context.temp_allocator)
	_ = os.write_entire_file(path, transmute([]u8)content)
}

fields_load :: proc(){
	data, err := os.read_entire_file(fields_config_path(), context.temp_allocator)
	if err != nil do return
	lines := strings.split_lines(string(data), context.temp_allocator)
	fields := [?]win.HWND{input_dir_field, output_dir_field, language_field}
	for field, i in fields{
		if i >= len(lines) do break
		if lines[i] != "" do win.SetWindowTextW(field, win.utf8_to_wstring(lines[i]))
	}
}

window_text_get :: proc(field:win.HWND, allocator := context.temp_allocator) -> string{
	buf:[win.MAX_PATH_WIDE]u16
	length := win.GetWindowTextW(field, cast(win.LPWSTR)&buf[0], win.MAX_PATH_WIDE)
	if length <= 0 do return ""
	text, _ := win.utf16_to_utf8(buf[:length], allocator)
	return text
}

status_set :: proc(text:string){
	win.SetWindowTextW(status_text, win.utf8_to_wstring(text))
}

control_make :: proc(class,text:string, style:win.DWORD, x,y,w,h:i32, id:=0) -> win.HWND{
	control := win.CreateWindowExW(
		0, win.utf8_to_wstring(class), win.utf8_to_wstring(text),
		style | win.WS_CHILD | win.WS_VISIBLE,
		x, y, w, h,
		window, win.HMENU(rawptr(uintptr(id))), nil, nil
	)
	win.SendMessageW(control, win.WM_SETFONT, win.WPARAM(uintptr(window_font)), 1)
	return control
}



