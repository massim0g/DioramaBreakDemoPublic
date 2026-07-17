package massimodin //@nested-tags:engine/shaders

import gl "vendor:OpenGL"

gl_test_draw_sprite :: proc() {
	//saves the previous shader and sets the current shader using GL_UseProgram. 
	//sh.wavy contains the index of a previously compiled shader
	shader_set(sh.wavy)

	//set uniforms with OpenGL calls
	gl.Uniform1i(gl.GetUniformLocation(sh.wavy, "texture"), 0)
	gl.Uniform1f(gl.GetUniformLocation(sh.wavy, "time"), time_get())

	//render a sprite from a texture page using SDL_RenderCopy
	sprite_draw(sp.swordsmanIdle_Loop, 100, 100)

	//resets to the previous shader
	shader_reset()
}

// gl_test_vertex_shader_source :cstring= `
// varying vec4 v_color;
// varying vec2 v_texCoord;

// void main()
// {
//     gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
//     v_color = gl_Color;
//     v_texCoord = vec2(gl_MultiTexCoord0);
// }
// `

// gl_test_fragment_shader_source :cstring= `
// varying vec4 v_color;
// varying vec2 v_texCoord;

// uniform sampler2D videoFrame;
// uniform float time;

// #define PI 3.1415926535897932384626433832795

// void main()
// {
// 	vec2 tCoord = v_texCoord;
// 	tCoord.x += sin(tCoord.y/0.1*PI+time/100.)*0.01;
//     gl_FragColor = texture2D(videoFrame, tCoord) * v_color;
// 	gl_FragColor.r = sin(time/1000.);
// }
// `

// gl_test_compile_program :: proc() -> bool {
//     vertex_id, fragment_id: u32
//     info_log: [512]u8
//     success: i32
	
//     vertex_id = gl.CreateShader(gl.VERTEX_SHADER)
//     gl.ShaderSource(vertex_id, 1, &gl_test_vertex_shader_source, nil)
//     gl.CompileShader(vertex_id)
//     gl.GetShaderiv(vertex_id, gl.COMPILE_STATUS, &success)
//     if success == 0 {
//         gl.GetShaderInfoLog(vertex_id, 512, nil, &info_log[0])
//         print("ERROR::SHADER::VERTEX::COMPILATION_FAILED", string(info_log[:]))
//         gl.DeleteShader(vertex_id)
//         return false
//     }
//     print("Vertex shader compiled successfully! Id = ", vertex_id)


//     fragment_id = gl.CreateShader(gl.FRAGMENT_SHADER)
//     gl.ShaderSource(fragment_id, 1, &gl_test_fragment_shader_source, nil)
//     gl.CompileShader(fragment_id)
//     gl.GetShaderiv(fragment_id, gl.COMPILE_STATUS, &success)
//     if success == 0 {
//         gl.GetShaderInfoLog(fragment_id, 512, nil, &info_log[0])
//         print("ERROR::SHADER::FRAGMENT::COMPILATION_FAILED", string(info_log[:]))
//         gl.DeleteShader(vertex_id)
//         gl.DeleteShader(fragment_id)
//         return false
//     }
//     print("Fragment shader compiled successfully! Id = ", fragment_id)

//     gl_test_program = gl.CreateProgram()
//     gl.AttachShader(gl_test_program, vertex_id)
//     gl.AttachShader(gl_test_program, fragment_id)
//     gl.LinkProgram(gl_test_program)

//     gl.GetProgramiv(gl_test_program, gl.LINK_STATUS, &success)
//     if success == 0 {
//         gl.GetProgramInfoLog(gl_test_program, 512, nil, &info_log[0])
//         print("ERROR::SHADER::PROGRAM::LINKING_FAILED", string(info_log[:]))
//         gl.DeleteShader(vertex_id)
//         gl.DeleteShader(fragment_id)
//         return false
//     }

//     gl.DeleteShader(vertex_id)
//     gl.DeleteShader(fragment_id)
	

//     return true
// }

// gl_test_init :: proc(){
// 	gl.load_up_to(3, 3, sdl2.gl_set_proc_address)
// 	gl_test_compile_program()
// 	gl_test_texture = sdl2.CreateTexture(display._renderer, u32(sdl2.PixelFormatEnum.RGBA8888),
// 	.TARGET, i32(sp.swordsmanIdle.width), i32(sp.swordsmanIdle.height))
// 	sdl2.SetTextureBlendMode(gl_test_texture, .BLEND)
// 	gl_test_start_time = time_get()
// 	_shader_ids_init()
// }



// gl_test_circ_tex:Tex

// gl_test_draw_circle :: proc() {
	

// 	//print("tex target?", uintptr(tex_target_get().ptr), uintptr(display.main_tex.ptr))
// 	tex := gl_test_circ_tex
// 	shader_set(sh.wavy)
// 	shader_uniform_set(shader_uniform_loc(sh.wavy, "texture"), 0)
// 	shader_uniform_set(shader_uniform_loc(sh.wavy, "time"), time_get())
// 	//tex_draw(gl_test_circ_tex, 100, 200)
// 	dstRect := sdl2.Rect{100, 200, i32(tex.w), i32(tex.h)}
// 	sdl2.RenderCopy(display._renderer, tex, nil, &dstRect)
// 	//sprite_draw(sp.slimeIdle, 200, 200)
// 	//draw_circle(100, 100, r, p)
// 	shader_reset()

// 	// tpf:u32
// 	// access:i32
// 	// w:i32
// 	// h:i32
// 	// sdl2.QueryTexture(sp.slimeIdle.frames[0].texturePage, &tpf, &access, &w, &h)
// 	// print("sprite?", tpf, access, w, h)
	
// 	// sdl2.QueryTexture(gl_test_circ_tex, &tpf, &access, &w, &h)
// 	// print("Tex?", tpf, access, w, h)
// }