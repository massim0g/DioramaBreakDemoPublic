#+feature using-stmt
package massimodin_builder

import "core:os"
import "core:path/filepath"
import "core:sys/windows"
import "base:runtime"

TRAY_CALLBACK_MESSAGE :: windows.WM_APP + 1
TRAY_MENU_LAUNCH_GAME :: 1
TRAY_MENU_EXIT :: 2

tray_window:windows.HWND
tray_data:windows.NOTIFYICONDATAW
taskbar_created_message:windows.UINT

tray_init :: proc(){
	using windows

	instance := HINSTANCE(GetModuleHandleW(nil))

	windowClass := WNDCLASSW{
		lpfnWndProc = tray_window_proc,
		hInstance = instance,
		lpszClassName = L("MassimodinBuilderTray")
	}
	if RegisterClassW(&windowClass) == 0{
		printf("WARNING: Tray window class registration failed (error %v), no tray icon", GetLastError())
		return
	}

	//hidden window that only exists to receive tray icon messages
	tray_window = CreateWindowExW(0, windowClass.lpszClassName, L("Massimodin Builder"), 0, 0, 0, 0, 0, nil, nil, instance, nil)
	if tray_window == nil{
		printf("WARNING: Tray window creation failed (error %v), no tray icon", GetLastError())
		return
	}

	//explorer broadcasts this when it (re)starts, the icon must be re-added or it disappears
	taskbar_created_message = RegisterWindowMessageW(L("TaskbarCreated"))

	//load the icon bmp, falling back to the stock application icon
	icon:HICON
	iconPath,_ := filepath.join({paths.script, "massimodin_builder/tray_icon.bmp"}, context.temp_allocator)
	bitmap := HBITMAP(LoadImageW(nil, utf8_to_wstring(iconPath, context.temp_allocator), IMAGE_BITMAP, 0, 0, LR_LOADFROMFILE | LR_CREATEDIBSECTION))
	if bitmap != nil{
		defer DeleteObject(HGDIOBJ(bitmap))

		bitmapInfo:BITMAP
		GetObjectW(HANDLE(bitmap), size_of(BITMAP), &bitmapInfo)
		mask := CreateBitmap(INT(bitmapInfo.bmWidth), INT(bitmapInfo.bmHeight), 1, 1, nil) //ignored when the bmp has an alpha channel, but must exist
		defer DeleteObject(HGDIOBJ(mask))

		iconInfo := ICONINFO{fIcon = TRUE, hbmMask = mask, hbmColor = bitmap}
		icon = CreateIconIndirect(&iconInfo)
	}
	if icon == nil do icon = LoadIconW(nil, LPCWSTR(_IDI_APPLICATION))

	tray_data = NOTIFYICONDATAW{
		cbSize = size_of(NOTIFYICONDATAW),
		hWnd = tray_window,
		uID = 1,
		uFlags = NIF_MESSAGE | NIF_ICON | NIF_TIP,
		uCallbackMessage = TRAY_CALLBACK_MESSAGE,
		hIcon = icon
	}
	tip := utf8_to_utf16("Massimodin Builder", context.temp_allocator)
	for c,i in tip do tray_data.szTip[i] = WCHAR(c)

	if Shell_NotifyIconW(NIM_ADD, &tray_data) == FALSE{
		printf("WARNING: Failed to add tray icon (error %v)", GetLastError())
	}
}

//pumps this thread's pending window messages, keeping the tray icon responsive. Only does anything on the thread that ran tray_init.
tray_update :: proc(){
	msg:windows.MSG
	for windows.PeekMessageW(&msg, tray_window, 0, 0, windows.PM_REMOVE){
		windows.TranslateMessage(&msg)
		windows.DispatchMessageW(&msg)
	}
}

tray_window_proc :: proc "system" (hwnd:windows.HWND, msg:windows.UINT, wParam:windows.WPARAM, lParam:windows.LPARAM) -> windows.LRESULT{
	context = runtime.default_context()
	using windows

	if msg == taskbar_created_message{
		Shell_NotifyIconW(NIM_ADD, &tray_data)
		return 0
	}

	if msg == TRAY_CALLBACK_MESSAGE{
		switch UINT(lParam){
			case WM_RBUTTONUP:
				menu := CreatePopupMenu()
				defer DestroyMenu(menu)
				AppendMenuW(menu, MF_STRING, TRAY_MENU_LAUNCH_GAME, L("Launch Game"))
				AppendMenuW(menu, MF_SEPARATOR, 0, nil)
				AppendMenuW(menu, MF_STRING, TRAY_MENU_EXIT, L("Exit"))

				cursorPos:POINT
				GetCursorPos(&cursorPos)
				SetForegroundWindow(hwnd) //without this the menu won't close when clicking away
				choice := transmute(i32)TrackPopupMenu(menu, TPM_RETURNCMD | TPM_RIGHTBUTTON, INT(cursorPos.x), INT(cursorPos.y), 0, hwnd, nil)
				PostMessageW(hwnd, WM_NULL, 0, 0) //classic tray menu quirk, ensures the menu fully dismisses

				switch choice{
					case TRAY_MENU_LAUNCH_GAME:
						print("GAME LAUNCH REQUESTED!")
						game_launch_requested = true

					case TRAY_MENU_EXIT:
						print("Exiting...")
						Shell_NotifyIconW(NIM_DELETE, &tray_data)
						os.exit(0)
				}

			case WM_LBUTTONDBLCLK:
				SetForegroundWindow(GetConsoleWindow())
		}
		return 0
	}

	return DefWindowProcW(hwnd, msg, wParam, lParam)
}
