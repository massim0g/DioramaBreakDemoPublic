package kernel32

import "core:sys/windows"

foreign import k32 "system:Kernel32.lib"

@(default_calling_convention="system")
foreign k32 {
    SetStdHandle :: proc(nStdHandle: windows.DWORD, hHandle: windows.HANDLE) -> windows.BOOL ---
}

STD_OUTPUT_HANDLE :: windows.DWORD(0xFFFFFFF5)  // -11
STD_ERROR_HANDLE  :: windows.DWORD(0xFFFFFFF4)  // -10