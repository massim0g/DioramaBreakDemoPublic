package massimodin //@nested-tags:libraries/threading

import "core:thread"
import "core:sync"

ThreadTask :: thread.Task
ThreadTaskProc :: thread.Task_Proc
ThreadPool :: thread.Pool

atomic_set :: sync.atomic_store
atomic_get :: sync.atomic_load

//Runs a procedure on a different thread, automatically cleans up when it's done.
//Context in the thread proc will be nil! If allocations are needed, thread proc must set its own thread-safe allocators when it starts.
thread_task_run :: proc(p:proc(), priority:=thread.Thread_Priority.High){
	context.allocator = os_allocator
	thread.create_and_start(p, nil, priority, true)
}

thread_task_run_with_data :: proc(data:rawptr, p:proc(data:rawptr), priority:=thread.Thread_Priority.High){
	context.allocator = os_allocator
	thread.create_and_start_with_data(data, p, nil, priority, true)
}

thread_pool_init_and_start :: proc(p:^ThreadPool, allocator:Allocator, threadCount:=thread_count_optimum){
	thread.pool_init(p, allocator, threadCount)
	thread.pool_start(p)
}

//blocks until all pool tasks are done, does not finish the pool
thread_pool_block :: proc(p:^ThreadPool){
	for thread.pool_num_outstanding(p) > 0 {
		thread_yield()
	}
	for _ in thread.pool_pop_done(p){}
}

thread_pool_add_task :: proc(p:^ThreadPool, procedure:ThreadTaskProc, data:rawptr=nil, allocator:=Allocator{}){
	thread.pool_add_task(p, allocator.procedure==nil?panic_allocator():allocator, procedure, data)
}

thread_pool_finish :: thread.pool_finish
thread_pool_destroy :: thread.pool_destroy

thread_yield :: thread.yield


