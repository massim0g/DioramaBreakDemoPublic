package massimodin_builder

import "core:fmt"
import "core:os"
import "core:strings"
import "core:mem"
import "core:mem/virtual"
import "core:path/filepath"
import "core:bytes"
import "core:sys/windows"
import uuids "core:encoding/uuid"
import "core:math/rand"
import "core:slice"

console_output_mode:windows.DWORD

console_mode_capture :: proc(){
	windows.GetConsoleMode(windows.GetStdHandle(windows.STD_OUTPUT_HANDLE), &console_output_mode)
}

console_mode_ensure :: proc(){
	if console_output_mode == 0 do return
	h := windows.GetStdHandle(windows.STD_OUTPUT_HANDLE)
	mode:windows.DWORD
	if windows.GetConsoleMode(h, &mode) && mode != console_output_mode do windows.SetConsoleMode(h, console_output_mode)
}

print :: proc(args:..any, sep:=" ") -> int{
	console_mode_ensure()
	return fmt.println(..args, sep=sep)
}
printf :: proc(format:string, args:..any) -> int{
	console_mode_ensure()
	return fmt.printfln(format, ..args)
}
assertf :: fmt.assertf

//File Helpers

dir_remove :: proc(path:string){
	dh, err := os.open(path)
	if err != nil do return

	entries, err2 := os.read_all_directory(dh, context.temp_allocator)
	os.close(dh)
	if err2 != nil do return

	for entry in entries{
		if entry.type == .Directory do dir_remove(entry.fullpath)
		else do os.remove(entry.fullpath)
	}
	os.remove(path)
}

dir_copy :: proc(srcPath, destPath:string, patterns:[]string=nil) -> os.Error{
	dh := os.open(srcPath) or_return
	defer os.close(dh)

	entries := os.read_all_directory(dh, context.temp_allocator) or_return

	if !os.exists(destPath) do os.make_directory_all(destPath) or_return

	for entry in entries{
		entryDest, _ := filepath.join({destPath, entry.name}, context.temp_allocator)
		if entry.type == .Directory do dir_copy(entry.fullpath, entryDest, patterns) or_return
		else{
			matched := patterns == nil
			for p in patterns{
				if ok,_ := filepath.match(p, entry.name);ok{matched = true; break}
			}
			if matched do os.copy_file(entryDest, entry.fullpath) or_return
		}
	}
	return nil
}

count_files_with_ext :: proc(dir:string, ext:string) -> int{
	dh, err := os.open(dir)
	if err != nil do return 0
	entries, err2 := os.read_all_directory(dh, context.temp_allocator)
	os.close(dh)
	if err2 != nil do return 0

	count := 0
	for entry in entries{
		if strings.has_suffix(entry.name, ext) do count += 1
	}
	return count
}

//OS Helpers

//Job object bindings missing from core:sys/windows
foreign import kernel32 "system:Kernel32.lib"
@(default_calling_convention="system")
foreign kernel32{
	CreateJobObjectW :: proc(lpJobAttributes:rawptr, lpName:windows.LPCWSTR) -> windows.HANDLE ---
	SetInformationJobObject :: proc(hJob:windows.HANDLE, jobObjectInformationClass:i32, lpJobObjectInformation:rawptr, cbJobObjectInformationLength:windows.DWORD) -> windows.BOOL ---
	AssignProcessToJobObject :: proc(hJob:windows.HANDLE, hProcess:windows.HANDLE) -> windows.BOOL ---
}

JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE :: 0x2000
JOB_OBJECT_EXTENDED_LIMIT_INFORMATION_CLASS :: 9

JobObjectBasicLimitInformation :: struct{
	PerProcessUserTimeLimit:i64,
	PerJobUserTimeLimit:i64,
	LimitFlags:windows.DWORD,
	MinimumWorkingSetSize:uint,
	MaximumWorkingSetSize:uint,
	ActiveProcessLimit:windows.DWORD,
	Affinity:windows.ULONG_PTR,
	PriorityClass:windows.DWORD,
	SchedulingClass:windows.DWORD,
}
JobObjectIoCounters :: struct{
	ReadOperationCount:u64,
	WriteOperationCount:u64,
	OtherOperationCount:u64,
	ReadTransferCount:u64,
	WriteTransferCount:u64,
	OtherTransferCount:u64,
}
JobObjectExtendedLimitInformation :: struct{
	BasicLimitInformation:JobObjectBasicLimitInformation,
	IoInfo:JobObjectIoCounters,
	ProcessMemoryLimit:uint,
	JobMemoryLimit:uint,
	PeakProcessMemoryUsed:uint,
	PeakJobMemoryUsed:uint,
}

/*
Assigns the daemon process to a "kill on close" job object. 
Child processes (compilers, fmod, the game) join the job automatically, 
and when the daemon dies for any reason the os closes the job handle and kills every process in it,
guaranteeing a daemon restart never leaves stale children behind.
*/
process_tree_kill_on_exit_init :: proc(){
	job := CreateJobObjectW(nil, nil)
	if job == nil{
		print("WARNING: Failed to create job object, child processes may outlive the daemon!")
		return
	}

	info:JobObjectExtendedLimitInformation
	info.BasicLimitInformation.LimitFlags = JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE

	infoSet := SetInformationJobObject(job, JOB_OBJECT_EXTENDED_LIMIT_INFORMATION_CLASS, &info, size_of(info))
	assigned := AssignProcessToJobObject(job, windows.GetCurrentProcess())
	if infoSet == windows.FALSE || assigned == windows.FALSE{
		print("WARNING: Failed to configure job object, child processes may outlive the daemon!")
	}
}

process_running :: proc(exePath:string) -> bool{
	targetName := filepath.base(exePath)

	snapshot := windows.CreateToolhelp32Snapshot(windows.TH32CS_SNAPPROCESS, 0)
	if snapshot == windows.INVALID_HANDLE_VALUE do return false
	defer windows.CloseHandle(snapshot)

	entry:windows.PROCESSENTRY32W
	entry.dwSize = size_of(windows.PROCESSENTRY32W)
	if windows.Process32FirstW(snapshot, &entry) == windows.FALSE do return false

	for{
		nameBuf:[windows.MAX_PATH * 3]u8
		name := windows.wstring_to_utf8_buf(nameBuf[:], cast(windows.wstring)&entry.szExeFile[0])
		if strings.equal_fold(name, targetName) do return true
		if windows.Process32NextW(snapshot, &entry) == windows.FALSE do break
	}
	return false
}

reload_request_write :: proc(kind:string, data:[]u8){
	path,_ := filepath.join({
		paths.build, 
		strings.join({uuid_make(), kind, "rr"}, ".", context.temp_allocator)
	}, context.temp_allocator)
	_ = os.write_entire_file(path, data)
}

uuid_make :: proc(allocator:=context.temp_allocator) -> string{
	result:uuids.Identifier
	bytes_generated := rand.read(result[:])
	assert(bytes_generated == 16, "RNG failed to generate 16 bytes for UUID v4.")

	result[uuids.VERSION_BYTE_INDEX] &= 0x0F
	result[uuids.VERSION_BYTE_INDEX] |= 0x40

	result[uuids.VARIANT_BYTE_INDEX] &= 0x3F
	result[uuids.VARIANT_BYTE_INDEX] |= 0x80

	return uuids.to_string(result, allocator)
}

// Allocator helper

allocator_make :: proc(blockSize:uint = virtual.DEFAULT_ARENA_GROWING_MINIMUM_BLOCK_SIZE) -> mem.Allocator{
	arena := new(virtual.Arena, os_allocator)
	_ = virtual.arena_init_growing(arena, blockSize)
	return virtual.arena_allocator(arena)
}
allocator_delete :: proc(alloc:mem.Allocator){
	if alloc.data == nil do return
	arena := cast(^virtual.Arena)alloc.data
	virtual.arena_destroy(arena)
	free(arena, os_allocator)
}

// Binary helpers

read_v :: #force_inline proc "contextless" (head:^uintptr, $T:typeid) -> T{
	val := (cast(^^T)head)^^
	head^ += size_of(T)
	return val
}
read_p :: #force_inline proc "contextless" (head:^uintptr, valPtr:^$T){
	valPtr^ = (cast(^^T)head)^^
	head^ += size_of(T)
}
read :: proc{read_v, read_p}

// write :: #force_inline proc "contextless" (head:^uintptr, val:$T){
// 	(cast(^^T)head)^^ = val
// 	head^ += size_of(T)
// }

write_p :: #force_inline proc "contextless" (buf:^bytes.Buffer, valPtr:^$T){
	bytes.buffer_write_ptr(buf, valPtr, size_of(T))
}
write_v :: #force_inline proc (buf:^bytes.Buffer, val:$T){
	val := val
	bytes.buffer_write_ptr(buf, &val, size_of(T))
}

buffer_head :: #force_inline proc "contextless" (b:bytes.Buffer) -> uintptr{
	return uintptr(&raw_data(b.buf)[len(b.buf)])
}

next_power_of_two :: proc "contextless" (x:int) -> int{
	k := x - 1
	k = k | (k >> 16)
	k = k | (k >> 8)
	k = k | (k >> 4)
	k = k | (k >> 2)
	k = k | (k >> 1)
	k += 1 + int(x <= 0)
	return k
}

//Drops a leading UTF-8 BOM (EF BB BF) if present
strip_bom :: proc(data:[]u8) -> []u8{
	if len(data) >= 3 && slice.simple_equal(data[:3], []u8{0xEF, 0xBB, 0xBF}) do return data[3:]
	return data
}

// String helpers

sanitize_asset_name :: proc(name:string, allocator := context.allocator) -> string{
	result, _ := strings.replace_all(name, " ", "_", allocator)
	result, _ = strings.replace_all(result, "-", "_", allocator)
	return result
}

//sprite tag names sanitize differently from asset file names, for parity with the legacy lua exporter:
//whitespace is deleted rather than replaced, slashes become underscores, dashes are kept
sanitize_tag_name :: proc(name:string, allocator := context.allocator) -> string{
	b := strings.builder_make(allocator)
	for ch in name{
		switch ch{
			case ' ', '\t', '\n', '\r', '\v', '\f': continue
			case '/', '\\': strings.write_rune(&b, '_')
			case: strings.write_rune(&b, ch)
		}
	}
	return strings.to_string(b)
}

file_has_extension :: proc(filename:string, extensions:[]string) -> bool{
	ext := filepath.ext(filename)
	for e in extensions{
		if ext == e do return true
	}
	return false
}

to_camel_case :: proc(s:string) -> string{
	trimmed := strings.trim_space(s)
	if len(trimmed) == 0 do return ""

	if !strings.contains(trimmed, " "){
		if len(trimmed) <= 1 do return strings.to_lower(trimmed)
		buf := make([]u8, len(trimmed))
		buf[0] = lower_byte(trimmed[0])
		copy(buf[1:], trimmed[1:])
		return string(buf)
	}

	result := make([dynamic]u8, 0, len(trimmed))
	followsSpace := false
	first := true

	for ch in transmute([]u8)trimmed{
		if ch == ' ' || ch == '\t'{
			followsSpace = true
			continue
		}

		if first{
			append(&result, lower_byte(ch))
			first = false
		} else if followsSpace{
			append(&result, upper_byte(ch))
			followsSpace = false
		} else{
			append(&result, lower_byte(ch))
		}
	}

	return string(result[:])
}

lower_byte :: proc "contextless" (ch:u8) -> u8{
	if ch >= 'A' && ch <= 'Z' do return ch + 32
	return ch
}

upper_byte :: proc "contextless" (ch:u8) -> u8{
	if ch >= 'a' && ch <= 'z' do return ch - 32
	return ch
}

find_line_index :: proc(lines:[]string, target:string) -> int{
	for line, i in lines{
		if strings.trim_space(line) == target do return i
	}
	return -1
}

capitalize_first :: proc(s:string, allocator:=context.temp_allocator) -> string{
	if len(s) == 0 do return s
	first := s[0]
	if first >= 'a' && first <= 'z'{
		buf := make([]u8, len(s), allocator)
		buf[0] = first - 32
		copy(buf[1:], s[1:])
		return string(buf)
	}
	return strings.clone(s, allocator)
}

slice_to_dynamic :: proc(a: $T/[]$E, allocator:mem.Allocator) -> [dynamic]E {
	s := transmute(mem.Raw_Slice)a
	d := mem.Raw_Dynamic_Array{
		data = s.data,
		len  = s.len,
		cap  = s.len,
		allocator = allocator,
	}
	return transmute([dynamic]E)d
}



