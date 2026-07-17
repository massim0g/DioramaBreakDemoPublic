package dbghelp

import "core:sys/windows"

when ODIN_OS == .Windows{
foreign import lib "system:Dbghelp.lib"

ADDR_MODE :: enum windows.DWORD { Flat = 3 }

ADDRESS64 :: struct {
	Offset:  windows.DWORD64,
	Segment: windows.WORD,
	Mode:    ADDR_MODE,
}

KDHELP64 :: struct {
	Thread:                         windows.DWORD64,
	ThCallbackStack:                windows.DWORD,
	ThCallbackBStore:               windows.DWORD,
	KiCallUserMode:                 windows.DWORD,
	KeUserCallbackDispatcher:       windows.DWORD,
	SystemRangeStart:               windows.DWORD,
	KiUserExceptionDispatcher:      windows.DWORD,
	StackBase:                      windows.DWORD,
	StackLimit:                     windows.DWORD,
	BuildVersion:                   windows.DWORD,
	RetpolineStubFunctionTableSize: windows.DWORD,
	RetpolineStubFunctionTable:     windows.DWORD64,
	RetpolineStubOffset:            windows.DWORD,
	RetpolineStubSize:              windows.DWORD,
	Reserved0:                      [2]windows.DWORD64,
}

STACKFRAME64 :: struct {
	AddrPC:         ADDRESS64,
	AddrReturn:     ADDRESS64,
	AddrFrame:      ADDRESS64,
	AddrStack:      ADDRESS64,
	AddrBStore:     ADDRESS64,
	FuncTableEntry: rawptr,
	Params:         [4]windows.DWORD64,
	Far:            windows.BOOL,
	Virtual:        windows.BOOL,
	Reserved:       [3]windows.DWORD64,
	KdHelp:         KDHELP64,
}

// ASCII versions of SYMBOL_INFO and IMAGEHLP_LINE64 (avoid wstring conversion overhead)
SYMBOL_INFO :: struct {
	SizeOfStruct: windows.ULONG,
	TypeIndex:    windows.ULONG,
	Reserved:     [2]windows.ULONG64,
	Index:        windows.ULONG,
	Size:         windows.ULONG,
	ModBase:      windows.ULONG64,
	Flags:        windows.ULONG,
	Value:        windows.ULONG64,
	Address:      windows.ULONG64,
	Register:     windows.ULONG,
	Scope:        windows.ULONG,
	Tag:          windows.ULONG,
	NameLen:      windows.ULONG,
	MaxNameLen:   windows.ULONG,
	Name:         [1]byte, // variable-length, allocate extra bytes after struct
}

IMAGEHLP_LINE64 :: struct {
	SizeOfStruct: windows.DWORD,
	Key:          rawptr,
	LineNumber:   windows.DWORD,
	FileName:     cstring,
	Address:      windows.DWORD64,
}

IMAGE_FILE_MACHINE_AMD64 :: windows.DWORD(0x8664)

exception_code_name :: proc(code: windows.DWORD) -> (name:string,isOdinException:bool) {
	switch code {
	case 0xC0000005: return "Access Violation", false
	case 0xC00000FD: return "Stack Overflow", false
	case 0xC0000094: return "Integer Divide by Zero", false
	case 0xC000008E: return "Float Divide by Zero", false
	case 0xC000001D: return "Illegal Instruction", false
	case 0xC0000096: return "Privileged Instruction", false
	case 0x80000002: return "Datatype Misalignment", false
	case 0x80000003: return "Breakpoint", false
	case 0xC0000409: return "Stack Buffer Overrun", false

	case 0xC000008C: return "Array Bounds Exceeded/Type Assertion", true
	}
	return "Unknown", false
}

FunctionTableAccessProc64 :: #type proc "system" (windows.HANDLE, windows.DWORD64) -> rawptr
GetModuleBaseProc64       :: #type proc "system" (windows.HANDLE, windows.DWORD64) -> windows.DWORD64

@(default_calling_convention = "system")
foreign lib {
	StackWalk64              :: proc(MachineType: windows.DWORD, hProcess, hThread: windows.HANDLE, StackFrame: ^STACKFRAME64, ContextRecord: rawptr, ReadMemoryRoutine: rawptr, FunctionTableAccessRoutine: FunctionTableAccessProc64, GetModuleBaseRoutine: GetModuleBaseProc64, TranslateAddress: rawptr) -> windows.BOOL ---
	SymFunctionTableAccess64 :: proc(hProcess: windows.HANDLE, AddrBase: windows.DWORD64) -> rawptr ---
	SymGetModuleBase64       :: proc(hProcess: windows.HANDLE, dwAddr: windows.DWORD64) -> windows.DWORD64 ---
	SymLoadModuleEx          :: proc(hProcess: windows.HANDLE, hFile: windows.HANDLE, ImageName: cstring, ModuleName: cstring, BaseOfDll: windows.DWORD64, DllSize: windows.DWORD, Data: rawptr, Flags: windows.DWORD) -> windows.DWORD64 ---
	SymFromAddr              :: proc(hProcess: windows.HANDLE, Address: windows.DWORD64, Displacement: ^windows.DWORD64, Symbol: ^SYMBOL_INFO) -> windows.BOOL ---
	SymGetLineFromAddr64     :: proc(hProcess: windows.HANDLE, dwAddr: windows.DWORD64, pdwDisplacement: ^windows.DWORD, Line: ^IMAGEHLP_LINE64) -> windows.BOOL ---
}
}