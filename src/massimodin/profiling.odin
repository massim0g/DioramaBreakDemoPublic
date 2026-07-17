package massimodin //@nested-tags:debug

import "../tracy"
import "base:runtime"

@(thread_local) tracy_auto_trace:bool

when tracy.TRACY_ENABLE{

tracy_whitelist_directory:string

tracy_context_stack:[dynamic]tracy.ZoneCtx
trace :: proc{tracy.Zone, tracy.ZoneN}

@(instrumentation_enter)
_trace_auto_begin :: proc "contextless" (proc_address:rawptr, call_site_return_address: rawptr, loc: runtime.Source_Code_Location){
	if !tracy_auto_trace do return
	tracy_auto_trace = false
	defer tracy_auto_trace = true
	if loc.file_path[:len(tracy_whitelist_directory)] != tracy_whitelist_directory do return
	context = runtime.default_context()
	append(&tracy_context_stack, tracy.ZoneBegin(true, tracy.TRACY_CALLSTACK, loc))
}

@(instrumentation_exit)
_trace_auto_end :: proc "contextless" (proc_address, call_site_return_address: rawptr, loc: runtime.Source_Code_Location){
	if !tracy_auto_trace do return
	tracy_auto_trace = false
	defer tracy_auto_trace = true
	if loc.file_path[:len(tracy_whitelist_directory)] != tracy_whitelist_directory do return
	context = runtime.default_context()
	tracy.ZoneEnd(pop(&tracy_context_stack))
}

}
else{

@(disabled=true)
trace :: proc(_:string){}

}
