package massimodin //@nested-tags:libraries/collections

/*
Functions for use with string maps to ensure they own the memory of their keys
*/

import "core:strings"
import "base:runtime"

//If setting for the first time, will return the newly cloned key, otherwise just returns the passed key.
//Keys are cloned using the map's allocator
strmap_set :: proc(sm:^map[string]$T, key:string, val:T)->string{
	if v,ok:=&sm[key];ok{
		v^ = val
		return key
	}
	
	clonedKey := strings.clone(key, sm.allocator)
	sm[clonedKey] = val
	return clonedKey
}

strmap_delete_key :: proc(sm:^map[string]$T, key:string){
	sk,_ := strmap_get(sm^, key)
	delete_key(sm, sk)
	delete(sk, sm.allocator) //frees the key's backing memory
}

strmap_key_get :: proc "contextless" (sm:^map[string]$T, val:T) -> string{
	for key, sv in sm{
		if(sv == val){
			return key
		}
	}

	return ""
}

//slow, but returns the stored key
strmap_get :: proc "contextless" (sm:map[string]$T, key:string) -> (storedKey:string, storedVal:T){
	for sk, sv in sm{
		if(sk == key){
			return sk,sv
		}
	}
	return
}
strmap_get_ptr :: proc "contextless" (sm:map[string]$T, key:string) -> (storedKey:string, storedVal:^T){
	for sk, &sv in sm{
		if(sk == key){
			return sk,&sv
		}
	}
	return
}

strmap_delete :: proc(sm:^map[string]$T){
	for key in sm{
		delete(key)
	}

	delete(sm^)
}

strmap_clear :: proc(sm:^map[string]$T){
	for key in sm^{
		delete(key)
	}

	clear(sm)
}





