package massimodin //@nested-tags:engine/imkey

import "core:path/filepath"
import "core:strings"

ImKey :: union{
	SourceLocation,
	^ComponentBase,
	string,
	int
}

//Note: Will *not* clone keys that are already strings
imkey_to_string :: proc(key:ImKey, allocator:=context.temp_allocator) -> string{
	switch k in key{
		case SourceLocation: return format("__LImK_%s_%i_%i", filepath.short_stem(k.file_path), k.line, k.column, allocator=allocator) //[L]ocation [Im]mediate [K]ey
		case ^ComponentBase: return format("__CImK_%i_%i", k.entity.id, k.myEntityIndex, allocator=allocator) //[C]omponent [Im]mediate [K]ey
		case string: return k
		case int: return int_to_string(k, allocator)
	}
	unreachable()
}

imkey_to_cstring :: proc(key:ImKey, allocator:=context.temp_allocator) -> cstring{
	s := imkey_to_string(key)
	return string_to_cstring(s, allocator)
}

//combines any given amount of imkeys with the caller location (or a custom key) to produce a unique key
imkey_combine :: proc(keys:..ImKey, loc:ImKey=#caller_location, allocator:=context.temp_allocator) -> ImKey{
	out:strings.Builder
	strings.builder_init(&out, allocator)
	for key in keys{
		strings.write_string(&out, imkey_to_string(key))
	}
	strings.write_string(&out, imkey_to_string(loc))
	shrink(&out.buf)
	return strings.to_string(out)
}

// //Generate an imkey from the caller location *and* an integer, useful for loops
// imkey_int :: proc(i:int, base:=#caller_location, allocator:=context.temp_allocator) -> string{
// 	return format("__LImKI__%s__%i__%i", filepath.short_stem(base.file_path), base.line, i, allocator=allocator) //[L]ocation [Im]mediate [K]ey [I]nteger
// }