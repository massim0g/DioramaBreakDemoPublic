package massimodin_builder

import "core:sync"
import "core:path/filepath"
import "core:fmt"
import "core:strconv"
import "core:strings"
import "core:time"
import "core:sys/windows"
import "core:unicode/utf16"
import "core:os"

watcher_init :: proc(){
	iocp = windows.CreateIoCompletionPort(windows.INVALID_HANDLE_VALUE, nil, 0, 1)
	if iocp == nil{
		printf("failed to create IOCP")
		return
	}

	for &pipeline in pipelines do pipeline_watch_start(&pipeline)
}

watcher_update :: proc(){
	//Poll file changes
	bytesTransferred:windows.DWORD
	completionKey:windows.ULONG_PTR
	overlapped:^windows.OVERLAPPED

	timeout := windows.DWORD(POLL_TIMEOUT_MS)
	for{
		result := windows.GetQueuedCompletionStatus(
			iocp, &bytesTransferred, &completionKey, &overlapped, timeout,
		)
		if result == windows.FALSE{
			if overlapped == nil do break //timeout, queue is drained

			//a watch's async read failed, re-arm it so the directory doesn't silently stop being watched
			kind := cast(PipelineKind)completionKey
			printf("WARNING: Directory watch failed for %v pipeline, re-arming", kind)
			pipeline_watch_read_request(&pipelines[kind])
			timeout = 0
			continue
		}

		kind := cast(PipelineKind)completionKey
		p := &pipelines[kind]

		pipelines_block({kind}) //failsafe in case file is changed while pipeline is running

		if bytesTransferred == 0{ //zero bytes on a successful completion means the watch buffer overflowed and changes were lost, queue a full re-scan of the directory so nothing is missed
			printf("WARNING: Watch buffer overflowed for %v pipeline, re-scanning whole directory", kind)

			//clear pending, but keep pending deletions (the full scan can't rediscover those). The scan re-adds everything else
			#reverse for pending, i in p.pendingFiles{
				if pending.exists do unordered_remove(&p.pendingFiles, i)
			}

			{
				context.temp_allocator = p.allocator //scanned paths must outlive this tick, the task frees them when done
				pipeline_full_scan(p)
			}
			pipeline_status_set(p, .debouncing)
			p.debounceDeadline = time.time_add(time.now(), DEBOUNCE_MS * time.Millisecond)
			pipeline_watch_read_request(p)
			timeout = 0
			continue
		}

		offset:u32 = 0
		for{
			info := cast(^windows.FILE_NOTIFY_INFORMATION)&p.watchBuffer[offset]

			nameLen := info.file_name_length / 2
			nameWide := ([^]u16)(&info.file_name[0])[:nameLen]

			utf8Buf:[512]u8
			utf8Len := utf16.decode_to_utf8(utf8Buf[:], nameWide)
			fileName := string(utf8Buf[:utf8Len])

			//keep the native backslash separators so paths compare equal with pipeline_full_scan output
			fullPath := strings.concatenate({p.watchDir, "\\", fileName}, context.temp_allocator)

			if len(p.watchExtensions) > 0{
				if !file_has_extension(fileName, p.watchExtensions){
					if info.next_entry_offset == 0 do break
					offset += info.next_entry_offset
					continue
				}
			}

			if kind == .code{
				if strings.has_suffix(fileName, ".g.odin"){
					if info.next_entry_offset == 0 do break
					offset += info.next_entry_offset
					continue
				}
				if strings.has_suffix(fileName, "build_config.json"){
					config_changed = true
					printf("build_config.json changed (will prompt on next launch)")
				}
			}

			//dedup: one entry per path, last event wins
			exists := info.action != windows.FILE_ACTION_REMOVED && info.action != windows.FILE_ACTION_RENAMED_OLD_NAME
			alreadyPending := false
			for &pending in p.pendingFiles{
				if pending.path == fullPath{
					pending.exists = exists
					alreadyPending = true
					break
				}
			}
			if !alreadyPending{
				append(&p.pendingFiles, PipelineChangedFile{
					path   = strings.clone(fullPath, p.allocator),
					exists = exists,
				})
			}
			
			pipeline_status_set(p, .debouncing)
			p.debounceDeadline = time.time_add(time.now(), DEBOUNCE_MS * time.Millisecond)

			if info.next_entry_offset == 0 do break
			offset += info.next_entry_offset
		}

		pipeline_watch_read_request(p)

		timeout = 0
	}

	//Update pipelines
	now := time.now()
	for &p in pipelines{
		switch pipeline_status_get(&p){
			case .debouncing: 
				if time.diff(now, p.debounceDeadline) <= 0 do pipeline_task_dispatch(&p, false)
			
			case .done:
				if p.codegenDirty{
					p.codegenDirty = false
					pipelines_block({.code} + PIPELINE_CODEGEN_KINDS) //failsafe
					pipeline_task_dispatch(&pipelines[.code], false)
				}
				if p.kind in PIPELINE_PACKED_KINDS{
					pipelines_block({.packer} + PIPELINE_PACKED_KINDS) //failsafe
					pipeline_task_dispatch(&pipelines[.packer], false)
				}

				pipeline_status_set(&p, .idle)
			
			case .failed:
				panic(fmt.tprintf("%v pipeline failed unexpectedly", p.kind))
			case .idle, .running: //do nothing
		}
	}

	if sync.atomic_load(&dll_hot_reloaded) && !process_running(paths.exe){
		print("Game was hot-reloaded, ensuring .exe and .dll are up-to-date...")
		hotDir, _ := filepath.join({paths.build_win64, "massimodin_hot_reloaded"}, context.temp_allocator)
		mainDll, _ := filepath.join({paths.build_win64, "massimodin.dll"}, context.temp_allocator)

		dh, dirErr := os.open(hotDir)
		if dirErr == nil{
			entries, _ := os.read_all_directory(dh, context.temp_allocator)
			os.close(dh)

			lastDll := ""
			lastNum := -1
			for entry in entries{
				if !strings.has_suffix(entry.name, ".dll") do continue
				numStr := strings.trim_prefix(strings.trim_suffix(entry.name, ".dll"), "massimodin")
				num, ok := strconv.parse_int(numStr)
				if ok && num > lastNum{
					lastNum = num
					lastDll = entry.fullpath
				}
			}

			if lastDll != ""{
				os.remove(mainDll)
				os.rename(lastDll, mainDll)
			}

			dir_remove(hotDir)
		}

		//the exe skipped rebuilding while the game ran, catch it up so it can't go stale relative to the DLL
		code_exe_compile()

		sync.atomic_store(&dll_hot_reloaded, false)
		print("Hot-reload reconciliation done!")
	}
}