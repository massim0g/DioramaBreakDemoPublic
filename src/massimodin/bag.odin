package massimodin //@nested-tags:libraries/collections

//array of elements intended to be sampled with removal. If bag is empty, returns a default value when sampling. 
Bag :: struct($T:typeid){
	buf:[dynamic]T,
	default:T
}

bag_make :: proc(default:$T, allocator:=context.allocator)->Bag(T){
	return Bag(T){
		make([dynamic]T, allocator),
		default
	}
}

bag_init :: proc(b:^Bag($T), default:T, allocator:=context.allocator){
	b^ = bag_make(default, allocator)
}

bag_get :: proc(b:^Bag($T), ind:int)->T{
	if len(b.buf) == 0 do return b.default
	out := b.buf[ind]
	unordered_remove(&b.buf, ind)
	return out
}

bag_add :: proc(b:^Bag($T), val:T){
	append(&b.buf, val)
}

bag_get_random :: proc(b:^Bag($T)) -> T{
	if len(b.buf) == 0 do return b.default
	ind := random(len(b.buf))
	return bag_get(b, ind)
}