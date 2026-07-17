package massimodin_builder

import "core:sys/windows"
import "core:time"
import "core:mem"
import "core:os"
import "core:sync"
import "core:strings"
import "core:thread"
import "core:reflect"

Pipeline :: struct{
	kind:PipelineKind,
	status:PipelineStatus,

	pendingFiles:[dynamic]PipelineChangedFile,
	debounceDeadline:time.Time,
	codegenDirty:bool, //set by runs that modified generated code, consumed by the watcher to dispatch a recompile
	
	watchDir:string,
	watchExtensions:[]string,
	watchRecursive:bool,
	watchHandle:windows.HANDLE,
	watchBuffer:[WATCH_BUFFER_SIZE]u8,
	watchOverlapped:windows.OVERLAPPED,
	
	allocator:mem.Allocator, //thread-safe allocator
	
	run:PipelineRunProc
}

// Pipeline types
PipelineKind :: enum{
	sprites,
	fonts,
	shaders,
	dialogues,
	curves,
	stages,
	audio,
	code,
	libs,
	packer,
}
PipelineKinds :: bit_set[PipelineKind]

PipelineStatus :: enum{
	idle,
	done,
	debouncing,
	running,
	failed,
}

PipelineChangedFile :: struct{
	path:string,
	exists:bool,
}

PipelineRunProc :: proc(pipeline:^Pipeline, fullRebuild:bool)

pipeline_status_get :: #force_inline proc(p:^Pipeline) -> PipelineStatus{
	return sync.atomic_load(&p.status)
}

pipeline_status_set :: #force_inline proc(p:^Pipeline, s:PipelineStatus){
	sync.atomic_store(&p.status, s)
}

//fully scan a pipeline's watch directory and queue all files in it
pipeline_full_scan :: proc(pipeline:^Pipeline, dir:=""){
	dir := dir == "" ? pipeline.watchDir : dir

	dh, err := os.open(dir)
	assertf(err==nil, "ERROR: Failed to open pipeline directory '%s', %v", dir, err)
	defer os.close(dh)

	entries, err2 := os.read_all_directory(dh, context.temp_allocator)
	assertf(err2==nil, "ERROR: Failed to read pipeline directory '%s', %v", dir, err)

	for entry in entries{
		if entry.type == .Directory{
			if pipeline.watchRecursive{
				pipeline_full_scan(pipeline, entry.fullpath)
			}
			continue
		}

		if len(pipeline.watchExtensions) > 0{
			if !file_has_extension(entry.name, pipeline.watchExtensions) do continue
		}

		if strings.has_suffix(entry.name, ".g.odin") do continue

		append(&pipeline.pendingFiles, PipelineChangedFile{
			path=entry.fullpath,
			exists=true,
		})
	}
}


//Threading
PipelineTask :: struct{
	pipeline:^Pipeline,
	fullRebuild:bool,
}
pipeline_task_proc :: proc(task:thread.Task){
	pt := cast(^PipelineTask)task.data
	p := pt.pipeline

	context.allocator = p.allocator
	context.temp_allocator = p.allocator

	if pt.fullRebuild && p.watchDir != "" do pipeline_full_scan(p)

	p.run(p, pt.fullRebuild)
	
	clear(&p.pendingFiles)
	free_all(p.allocator)

	if pipeline_status_get(p) != .failed do pipeline_status_set(p, .done)
}

pipeline_task_dispatch :: proc(p:^Pipeline, fullRebuild:bool){
	if p.kind != .packer do printf("REBUILDING %s...", strings.to_upper(reflect.enum_name_from_value(p.kind) or_else "", context.temp_allocator))
	pipeline_status_set(p, .running)
	pt := new(PipelineTask, p.allocator)
	pt^ = {p, fullRebuild}
	thread.pool_add_task(&pipeline_pool, p.allocator, pipeline_task_proc, pt)
}

pipeline_watch_start :: proc(p:^Pipeline){
	if len(p.watchDir) == 0 do return
	widePath := windows.utf8_to_wstring(p.watchDir)
	p.watchHandle = windows.CreateFileW(
		widePath,
		windows.FILE_LIST_DIRECTORY,
		windows.FILE_SHARE_READ | windows.FILE_SHARE_WRITE | windows.FILE_SHARE_DELETE,
		nil,
		windows.OPEN_EXISTING,
		windows.FILE_FLAG_BACKUP_SEMANTICS | windows.FILE_FLAG_OVERLAPPED,
		nil,
	)
	if p.watchHandle == windows.INVALID_HANDLE_VALUE{
		printf("ERROR: Failed to open watch directory: %s", p.watchDir)
		return
	}

	completionKey := cast(windows.ULONG_PTR)p.kind
	result := windows.CreateIoCompletionPort(p.watchHandle, iocp, completionKey, 0)
	if result == nil{
		printf("ERROR: Failed to associate IOCP for: %s", p.watchDir)
		return
	}

	pipeline_watch_read_request(p)
}

//Request an async read of changes to the directory. After changes are detected, a new request must be issued to detect further changes.
pipeline_watch_read_request :: proc(p:^Pipeline){
	p.watchOverlapped = {}
	windows.ReadDirectoryChangesW(
		p.watchHandle,
		&p.watchBuffer,
		WATCH_BUFFER_SIZE,
		p.watchRecursive ? windows.TRUE : windows.FALSE,
		windows.FILE_NOTIFY_CHANGE_FILE_NAME | windows.FILE_NOTIFY_CHANGE_LAST_WRITE | windows.FILE_NOTIFY_CHANGE_SIZE,
		nil,
		&p.watchOverlapped,
		nil,
	)
}