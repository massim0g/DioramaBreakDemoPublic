package massimodin //@nested-tags:engine/shaders

import gl "vendor:OpenGL"
import "../sdl2"

ShaderSystem :: struct{
	_shaders_map:map[string]Shader,

	_stack:[dynamic]Shader,
	_base_shader:Shader,

	_pal_swap_sprite_map:map[^Sprite]PalSwapData,
	_bound_textures:[8]^sdl2.Texture,
	blank_tex:Tex //useful for certain operations
}
shaders:^ShaderSystem

_shader_system_init :: proc(){
	shaders = new(ShaderSystem)
	sh = new(ShaderIDs, assets.allocator)
	
	init(&shaders._shaders_map, assets.allocator)
	init(&shaders._stack)
	init(&shaders._pal_swap_sprite_map, assets.allocator)

	_gl_init()

	shaders.blank_tex = tex_make(1,1)
	tex_target_set(shaders.blank_tex, clear=false)
	draw_clear()
	tex_target_reset()
}

Shader :: u32
ShaderUniformLoc :: i32

_gl_init :: proc(){
	gl.load_up_to(3, 3, sdl2.gl_set_proc_address)
}

shader_name :: proc(shader:Shader) -> string{
	return strmap_key_get(&shaders._shaders_map, shader)	
}

shader_find :: proc(name:string) -> Shader{
	return shaders._shaders_map[name]
}

shader_set :: proc(shader:Shader){
	if(len(shaders._stack) == 0){ //ensures base shader is kept up-to-date
		baseShader:i32
		gl.GetIntegerv(gl.CURRENT_PROGRAM, &baseShader)
		shaders._base_shader = u32(baseShader)
	}
	
	append(&shaders._stack, shader)
	gl.UseProgram(shader)
}

shader_reset :: proc(){
	if(len(shaders._stack) > 0) do pop(&shaders._stack)
	
	stackL := len(shaders._stack)
	if(stackL > 0) do gl.UseProgram(shaders._stack[stackL - 1])
	else do gl.UseProgram(shaders._base_shader)
	
}

//Returns the currently active shader
shader_get :: proc() -> Shader{
	stackL := len(shaders._stack)
	return (stackL > 0) ? shaders._stack[stackL - 1] : shaders._base_shader 
}

shader_uniform_loc :: #force_inline proc (shader:Shader, uniformName:cstring) -> ShaderUniformLoc{
	out := gl.GetUniformLocation(shader, uniformName)
	assertf(out != -1, "Shader uniform '%s' not found!", uniformName)
	return out
}

shader_uniform_set_bool_using_loc :: #force_inline proc "contextless" (loc:ShaderUniformLoc, val:bool){gl.Uniform1i(loc, i32(val))}
shader_uniform_set_int_using_loc :: #force_inline proc "contextless" (loc:ShaderUniformLoc, #any_int val:int){gl.Uniform1i(loc, i32(val))}
shader_uniform_set_2f_using_loc :: #force_inline proc "contextless" (loc:ShaderUniformLoc, val:[2]f32){gl.Uniform2f(loc, val[0], val[1])}
shader_uniform_set_3f_using_loc :: #force_inline proc "contextless" (loc:ShaderUniformLoc, val:[3]f32){gl.Uniform3f(loc, val[0], val[1], val[2])}
shader_uniform_set_4f_using_loc :: #force_inline proc "contextless" (loc:ShaderUniformLoc, val:[4]f32){gl.Uniform4f(loc, val[0], val[1], val[2], val[3])}
shader_uniform_set_2i_using_loc :: #force_inline proc "contextless" (loc:ShaderUniformLoc, val:[2]i32){gl.Uniform2i(loc, val[0], val[1])}
shader_uniform_set_3i_using_loc :: #force_inline proc "contextless" (loc:ShaderUniformLoc, val:[3]i32){gl.Uniform3i(loc, val[0], val[1], val[2])}
shader_uniform_set_4i_using_loc :: #force_inline proc "contextless" (loc:ShaderUniformLoc, val:[4]i32){gl.Uniform4i(loc, val[0], val[1], val[2], val[3])}
shader_uniform_set_color_using_loc :: #force_inline proc "contextless" (loc:ShaderUniformLoc, val:Color){gl.Uniform3f(loc, f32(val[0])/255, f32(val[1])/255, f32(val[2])/255)}
shader_uniform_set_blend_using_loc :: #force_inline proc "contextless" (loc:ShaderUniformLoc, val:Blend){gl.Uniform4f(loc, f32(val[0])/255, f32(val[1])/255, f32(val[2])/255, f32(val[3])/255)}
shader_uniform_set_rect_using_loc :: #force_inline proc "contextless" (loc:ShaderUniformLoc, val:Rect){gl.Uniform4f(loc, val.x, val.y, val.size.x, val.size.y)}
shader_uniform_set_using_loc :: proc{
	gl.Uniform1f,
	gl.Uniform2f,
	gl.Uniform3f,
	gl.Uniform4f,
	gl.Uniform1i,
	gl.Uniform2i,
	gl.Uniform3i,
	gl.Uniform4i,
	shader_uniform_set_bool_using_loc,
	shader_uniform_set_int_using_loc,
	shader_uniform_set_2f_using_loc,
	shader_uniform_set_3f_using_loc,
	shader_uniform_set_4f_using_loc,
	shader_uniform_set_2i_using_loc,
	shader_uniform_set_3i_using_loc,
	shader_uniform_set_4i_using_loc,
	shader_uniform_set_color_using_loc,
	shader_uniform_set_blend_using_loc,
	shader_uniform_set_rect_using_loc,
}

shader_uniform_set :: #force_inline proc (shader:Shader, uniformName:cstring, val:$T){
	shader_uniform_set_using_loc(shader_uniform_loc(shader, uniformName), val)
}

//Sets a shader sampler uniform to an index and binds a texture at that index to make it available to the shader 
shader_texture_bind :: proc(shader:Shader, uniformName:cstring, tex:Tex){
	for &t, i in shaders._bound_textures{
		if t == tex.ptr{
			shader_uniform_set(shader, uniformName, i)
			return
		}
	}
	for &t, i in shaders._bound_textures{
		if t == nil && i !=0{
			t = tex.ptr
			shader_uniform_set(shader, uniformName, i)
			gl.ActiveTexture(gl.TEXTURE0+u32(i))
			sdl2.GL_BindTexture(tex, nil, nil)
			gl.ActiveTexture(gl.TEXTURE0)
			return
		}
	}
	panic("Tried to bind too many shader textures at once, max 7! Did you forget to unbind after binding?")
}

shader_texture_unbind :: proc(tex:Tex){
	sdl2.GL_UnbindTexture(tex)
	for &t in shaders._bound_textures{
		if t == tex.ptr do t = nil
	}
}


shader_uniform_matrix_set_using_loc :: proc(loc:ShaderUniformLoc, mat:^matrix[$R,$C]f32){
	matPtr := cast([^]f32)mat
	when C == 2 && R == 2 do gl.UniformMatrix2fv(loc, 1, false, matPtr)
	else when C == 3 && R == 3 do gl.UniformMatrix3fv(loc, 1, false, matPtr)
	else when C == 4 && R == 4 do gl.UniformMatrix4fv(loc, 1, false, matPtr)
	else when C == 2 && R == 3 do gl.UniformMatrix2x3fv(loc, 1, false, matPtr)
	else when C == 3 && R == 2 do gl.UniformMatrix3x2fv(loc, 1, false, matPtr)
	else when C == 2 && R == 4 do gl.UniformMatrix2x4fv(loc, 1, false, matPtr)
	else when C == 4 && R == 2 do gl.UniformMatrix4x2fv(loc, 1, false, matPtr)
	else when C == 3 && R == 4 do gl.UniformMatrix3x4fv(loc, 1, false, matPtr)
	else when C == 4 && R == 3 do gl.UniformMatrix4x3fv(loc, 1, false, matPtr)
	else do panicf("Invalid matrix size ('%v', '%v') used for setting shader uniform!", R, C)

}
shader_uniform_matrix_set :: proc(shader:Shader, uniformName:cstring, mat:^matrix[$R,$C]f32){
	shader_uniform_matrix_set_using_loc(shader_uniform_loc(shader, uniformName), mat)
}

shader_compile :: proc(vertSource:cstring, fragSource:cstring) -> Shader{
	vertSource := vertSource
	fragSource := fragSource
    info_log: [512]u8
    success: i32
	
    vertex_id := gl.CreateShader(gl.VERTEX_SHADER)
    gl.ShaderSource(vertex_id, 1, &vertSource, nil)
    gl.CompileShader(vertex_id)
	defer gl.DeleteShader(vertex_id)
    gl.GetShaderiv(vertex_id, gl.COMPILE_STATUS, &success)
    if success == 0 {
        gl.GetShaderInfoLog(vertex_id, 512, nil, &info_log[0])
        print("ERROR::SHADER::VERTEX::COMPILATION_FAILED", string(info_log[:]))
        gl.DeleteShader(vertex_id)
        panic("Shader compile failed")
    }
    //print("Vertex shader compiled successfully! Id = ", vertex_id)

    fragment_id := gl.CreateShader(gl.FRAGMENT_SHADER)
    gl.ShaderSource(fragment_id, 1, &fragSource, nil)
    gl.CompileShader(fragment_id)
	defer gl.DeleteShader(fragment_id)
    gl.GetShaderiv(fragment_id, gl.COMPILE_STATUS, &success)
    if success == 0 {
        gl.GetShaderInfoLog(fragment_id, 512, nil, &info_log[0])
        print("ERROR::SHADER::FRAGMENT::COMPILATION_FAILED", string(info_log[:]))
        gl.DeleteShader(vertex_id)
        gl.DeleteShader(fragment_id)
        panic("Shader compile failed")
    }
    //print("Fragment shader compiled successfully! Id = ", fragment_id)

    out := gl.CreateProgram()
    gl.AttachShader(out, vertex_id)
    gl.AttachShader(out, fragment_id)
    gl.LinkProgram(out)

    gl.GetProgramiv(out, gl.LINK_STATUS, &success)
    if success == 0 {
        gl.GetProgramInfoLog(out, 512, nil, &info_log[0])
        print("ERROR::SHADER::PROGRAM::LINKING_FAILED", string(info_log[:]))
        panic("Shader linking failed")
    }

    return Shader(out)
}

shader_destroy :: proc(shader:Shader){
	gl.DeleteProgram(shader)
}