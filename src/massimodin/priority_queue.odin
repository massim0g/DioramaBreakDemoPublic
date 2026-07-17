package massimodin //@nested-tags:libraries/collections

import "core:container/priority_queue"
import "base:builtin"

//Warning: PQueues only guarantee the value at the end of the queue is correct, *not* that the whole queue is sorted correctly
PQueue :: priority_queue.Priority_Queue

//The queue will put 'a' at the front of the queue if 'less' returns true, and 'b' if less returns false.
//Therefore, returning 'a<b' puts the smaller value up front, and returning 'a>b' puts the larger 
pqueue_make :: #force_inline proc(less: proc(a, b: $T) -> bool, allocator:=context.allocator) -> PQueue(T){
	out:PQueue(T)
	pqueue_init(&out, less, allocator)
	return out
}

//The queue will put 'a' at the front of the queue if 'less' returns true, and 'b' if less returns false.
//Therefore, returning 'a<b' puts the smaller value up front, and returning 'a>b' puts the larger 
//NOTE: The 'front' of the queue means the *end* of the backing array, since popping removes from the end (i.e. index 0 of the backing array is the item at the *back* of the queue).
pqueue_init :: #force_inline proc(pq:^PQueue($T), less: proc(a, b: T) -> bool, allocator:=context.allocator){
	priority_queue.init(pq, less, priority_queue.default_swap_proc(T), priority_queue.DEFAULT_CAPACITY, allocator)
}

pqueue_remove_val :: proc(pq:^PQueue($T), val:T){
	if ind, ok := find(pq.queue, val); ok{
		pqueue_remove(pq, ind)
	}
}

pqueue_init_ex :: priority_queue.init
pqueue_push :: priority_queue.push
pqueue_len :: priority_queue.len
pqueue_clear :: priority_queue.clear
pqueue_peek :: priority_queue.peek
pqueue_pop :: priority_queue.pop
pqueue_remove :: proc(pq: ^PQueue($T), i: int){ //no idea why the built in function is broken for this
	ordered_remove(&pq.queue, i)
}
pqueue_destroy :: priority_queue.destroy


