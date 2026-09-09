package massimodin //@nested-tags:libraries/strings

import "core:strings"
import "core:unicode"
import "core:unicode/utf8"
import "core:strconv"
import "core:mem"
import "core:fmt"

//editable string. Used for strings that are sometimes allocated and sometimes not
Estring :: struct{
	s:string,
	allocator:Allocator
}

estring_set :: proc(old:^Estring, new:string, cloneString:=false, allocator:=context.allocator){
	if old.allocator.procedure != nil do delete(old.s, old.allocator)
	if cloneString{
		old.s = clone(new, allocator)
		old.allocator = allocator
	}
	else{
		old.s = new
		old.allocator = Allocator{}
	}
}

estring_delete :: proc(es:^Estring){
	if es.allocator.procedure != nil do delete(es.s, es.allocator)
	es.s = ""
	es.allocator = Allocator{}
}

estring_clone :: proc(es:Estring, allocator:=context.allocator) -> Estring{
	out:Estring
	estring_set(&out, es.s, true, allocator)
	return out
}


string_contains ::  proc "contextless" (s, substr: string) -> bool {
	return strings.index(s, substr) >= 0
}
string_contains_any :: strings.contains_any
string_clone :: strings.clone
string_replace :: strings.replace
string_replace_all :: strings.replace_all
string_join :: strings.join
string_starts_with :: strings.starts_with
string_ends_with :: strings.ends_with
string_concat :: strings.concatenate
string_to_cstring :: strings.clone_to_cstring
string_trim :: strings.trim
string_trim_right :: strings.trim_right
string_index :: strings.index
string_lower :: strings.to_lower
string_upper :: strings.to_upper
string_has_prefix :: strings.has_prefix
string_has_suffix :: strings.has_suffix

rune_lower :: unicode.to_upper
rune_upper :: unicode.to_lower


//Returns the length of the string in runes (as opposed to len(string), which returns the byte length)
string_count :: utf8.rune_count_in_string

//Returns the rune at a given rune index
string_rune :: utf8.rune_at_pos

runes_to_string :: utf8.runes_to_string

string_capitalize :: proc(s:string, allocator:=context.temp_allocator) -> string{
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

string_from_uip :: #force_inline proc(ptr,len:uintptr) -> string{
	return strings.string_from_ptr(cast(^u8)ptr, int(len))
}
string_from_ptr :: proc{strings.string_from_ptr, string_from_uip}

string_split :: proc(s:string, sep:string, n:=-1, allocator:=context.temp_allocator) -> []string{
	if n == -1 do return strings.split(s, sep, allocator)
	return strings.split_n(s, sep, n, allocator)
}

//Returns a portion of the string sliced based on a given rune count and position.
//A negative rune count will return the whole string after the start rune.
string_slice :: proc "contextless" (s:string, runeCount:int, startRune:int=0) -> string{
	endRune := startRune + runeCount
	start := 0
	end := 0
	count := 0
	for r in s{
		runeSize := utf8.rune_size(r)
		if(count < startRune) do start += runeSize
		if(count < endRune) do end += runeSize
		else do break
		count += 1
	}
	if(runeCount < 0) do return s[start:]
	return s[start:end]
}

//Returns the portion of the string between the start substring and end substring. Will only check the first instances of each substring.
//If the start substring is not found, returns an empty string.
//If the start substring is left blank, returns everything up to the end substring.
//If the end substring is not found or is left blank, returns everything after the start substring.
string_slice_between :: proc "contextless" (s:string, startSubstring:string, endSubstring:string, includeDelimiters:=false) -> string{
	delimStartLen := includeDelimiters ? len(startSubstring) : 0
	delimEndLen := includeDelimiters ? len(endSubstring) : 0
	
	startOff := 0
	if startSubstring != ""{
		start := strings.index(s, startSubstring)
		if(start == -1) do return ""
		startOff = start+len(startSubstring)
	}

	endOff := len(s)
	if endSubstring != ""{
		end := strings.index(s[startOff:], endSubstring)
		if end == -1 do delimEndLen = 0
		else do endOff = startOff + end
	}
	
	return s[startOff-delimStartLen:endOff+delimEndLen]
}

string_to_int :: strconv.parse_int
string_to_f32 :: strconv.parse_f32
string_to_bool :: strconv.parse_bool

//Converts an f32 to a string. Precision here specifies the number of digits to be kept *after the decimal point*.
f32_to_string :: proc(n:f32, precision:=2, allocator := context.allocator, loc := #caller_location) -> string{
	if(n == 0) do return string_clone("0", allocator, loc)

	digits:int //number of digits pre-decimal point
	if(abs(n)<10) do digits = 1
	else do digits = int(floor(log10(abs(n)))) + 1

	buf := make([dynamic]byte, digits+2+precision, allocator, loc) //add 2 for sign and decimal point
	strconv.write_float(buf[:], f64(n), 'f', precision, 32);
	if(n >= 0){
		ordered_remove(&buf, 0) //remove sign if number is positive
	}
	resize(&buf, len(strings.trim_right(transmute(string)buf[:], "0")))
	if(string_ends_with(transmute(string)buf[:], ".")) do resize(&buf, len(buf)-1)
	shrink(&buf)
	return transmute(string)buf[:]
}

ptr_to_string :: proc(ptr:rawptr, allocator := context.allocator) -> string{
	return fmt.aprint(ptr, allocator=allocator)
}

int_to_string :: proc(n:int, allocator := context.allocator, loc := #caller_location) -> string{
	digits:int
	if(abs(n) < 10) do digits = 1
	else do digits = int(floor(log10(f32(abs(n))))) + 1

	cap := digits+((n<0)?1:0)
	buf := make([dynamic]byte, cap, cap, allocator, loc)
	return strconv.write_int(buf[:], i64(n), 10)
}

format :: #force_inline proc(formatString:string, args:..any, allocator:=context.temp_allocator) -> string{
	for &arg in args{
		if es,ok:=arg.(Estring); ok do arg=es.s
	}
	return fmt.aprintf(formatString, args=args, allocator=allocator, newline=false)
}
cformat :: #force_inline proc(formatString:string, args:..any, allocator:=context.temp_allocator) -> cstring{
	return fmt.caprintf(formatString, args=args, allocator=allocator, newline=false)
}

//converts a snake_case or camelCase string into a Pretty String.
string_prettify :: proc(s:string, capitalizeAllWords:=false, allocator:=context.temp_allocator) -> string{
	builder := strings.builder_make(allocator)

	firstRune := true
	justSpaced := false
	prevR:rune
	for r in s{
		if(firstRune){
			if(r == '_' || r == ' ') do continue
			prevR = unicode.to_upper(r)
			
			firstRune = false
		}
		else if(r == '_' || r == ' '){
			prevR = ' '
			justSpaced = true
		}
		else{
			if(unicode.is_upper(r) && !unicode.is_upper(prevR)){
				if(!justSpaced) do strings.write_rune(&builder, ' ')
				prevR = capitalizeAllWords ? r : unicode.to_lower(r)
			}
			else do prevR = (justSpaced && capitalizeAllWords) ? unicode.to_upper(r) : r
			justSpaced = false
		}

		strings.write_rune(&builder, prevR)
	}
	
	return strings.to_string(builder)
}

//returns the subset of a list of strings which contain the given filter string (case-insensitive). Clones all filtered strings using the given allocator.
strings_filter :: proc(strs:[]string, filter:string, allocator:=context.temp_allocator) -> []string{
	out := make([dynamic]string, allocator)
	for str in strs{
		lowerStr := strings.to_lower(str, context.temp_allocator)
		if(filter == "" || strings.contains(lowerStr, filter)) do append(&out, string_clone(str, allocator))
	}

	shrink(&out)
	return out[:]
}
