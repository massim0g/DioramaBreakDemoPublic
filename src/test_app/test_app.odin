#+feature using-stmt
package test_app

import "core:fmt"
import "core:strings"
import SDL "../sdl2"
import IMG "../sdl2/image"
import gl "vendor:OpenGL"

WINDOW_WIDTH :: 480
WINDOW_HEIGHT :: 480

NX :: #config(ON_SWITCH, false)

when NX{
	print :: proc(args:..any, sep := " ", flush := true) -> int{
		builder := strings.builder_make()
        defer strings.builder_destroy(&builder)

        for arg, i in args {
            if i > 0 {
                strings.write_string(&builder, sep)
            }
            fmt.sbprint(&builder, arg)
        }

        result := strings.to_string(builder)
        SDL.Log("%s", cstring(raw_data(result)))

        return len(result)
	}
}
else{
	print :: fmt.println 
}

get_time :: proc() -> f32{
	using SDL
	return f32(GetPerformanceCounter())*1000/f32(GetPerformanceFrequency())
}

vertex_shader_source :cstring= `
varying vec4 v_color;
varying vec2 v_texCoord;

void main()
{
    gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
    v_color = gl_Color;
    v_texCoord = vec2(gl_MultiTexCoord0);
}
`

fragment_shader_source :cstring= `
varying vec4 v_color;
varying vec2 v_texCoord;

uniform sampler2D videoFrame;
uniform float time;

#define PI 3.1415926535897932384626433832795

void main()
{
	vec2 tCoord = v_texCoord;
	tCoord.x += sin(tCoord.y/0.1*PI+time/100.)*0.01;
    gl_FragColor = texture2D(videoFrame, tCoord) * v_color;
	gl_FragColor.r = sin(time/1000.)*gl_FragColor.a;
}
`

program_id: u32 = 0
texture_id: i32 = 0
time_id: i32 = 0

compile_program :: proc() -> bool {
    vertex_id, fragment_id: u32
    info_log: [512]u8
    success: i32

    vertex_id = gl.CreateShader(gl.VERTEX_SHADER)
    gl.ShaderSource(vertex_id, 1, &vertex_shader_source, nil)
    gl.CompileShader(vertex_id)
    gl.GetShaderiv(vertex_id, gl.COMPILE_STATUS, &success)
    if success == 0 {
        gl.GetShaderInfoLog(vertex_id, 512, nil, &info_log[0])
        print("ERROR::SHADER::VERTEX::COMPILATION_FAILED", string(info_log[:]))
        gl.DeleteShader(vertex_id)
        return false
    }
    print("Vertex shader compiled successfully! Id = ", vertex_id)

    fragment_id = gl.CreateShader(gl.FRAGMENT_SHADER)
    gl.ShaderSource(fragment_id, 1, &fragment_shader_source, nil)
    gl.CompileShader(fragment_id)
    gl.GetShaderiv(fragment_id, gl.COMPILE_STATUS, &success)
    if success == 0 {
        gl.GetShaderInfoLog(fragment_id, 512, nil, &info_log[0])
        print("ERROR::SHADER::FRAGMENT::COMPILATION_FAILED", string(info_log[:]))
        gl.DeleteShader(vertex_id)
        gl.DeleteShader(fragment_id)
        return false
    }
    print("Fragment shader compiled successfully! Id = ", fragment_id)

    program_id = gl.CreateProgram()
    gl.AttachShader(program_id, vertex_id)
    gl.AttachShader(program_id, fragment_id)
    gl.LinkProgram(program_id)

    gl.GetProgramiv(program_id, gl.LINK_STATUS, &success)
    if success == 0 {
        gl.GetProgramInfoLog(program_id, 512, nil, &info_log[0])
        print("ERROR::SHADER::PROGRAM::LINKING_FAILED", string(info_log[:]))
        gl.DeleteShader(vertex_id)
        gl.DeleteShader(fragment_id)
        return false
    }

    texture_id = gl.GetUniformLocation(program_id, "videoFrame")
    time_id = gl.GetUniformLocation(program_id, "time")

    gl.DeleteShader(vertex_id)
    gl.DeleteShader(fragment_id)
	

    return true
}

main :: proc() {
	SDL.SetHint(SDL.HINT_RENDER_DRIVER, "opengl")
    if SDL.Init(SDL.INIT_EVERYTHING) != 0 {
        print("SDL_Init failed:", SDL.GetError())
        return
    }
    defer SDL.Quit()

    window := SDL.CreateWindow("OpenGL Test", SDL.WINDOWPOS_CENTERED, SDL.WINDOWPOS_CENTERED,
                               WINDOW_WIDTH, WINDOW_HEIGHT, {.OPENGL})
    if window == nil {
        print("SDL_CreateWindow failed:", SDL.GetError())
        return
    }
    defer SDL.DestroyWindow(window)

    renderer := SDL.CreateRenderer(window, -1, {.ACCELERATED, .PRESENTVSYNC})
    if renderer == nil {
        print("SDL_CreateRenderer failed:", SDL.GetError())
        return
    }
    defer SDL.DestroyRenderer(renderer)

    renderer_info: SDL.RendererInfo
    SDL.GetRendererInfo(renderer, &renderer_info)
    print("Renderer: ", renderer_info.name)

	gl.load_up_to(3, 3, SDL.gl_set_proc_address)

    if compile_program() {
        print("Shader program compiled successfully")
    } else {
        print("Failed to compile shader program")
        return
    }

	when #config(ON_SWITCH, false){
		surf := IMG.Load("Contents:/swordsmanIdle.png")
		defer SDL.FreeSurface(surf)
		land := SDL.CreateTextureFromSurface(renderer, surf)
	}
	else {
		land := IMG.LoadTexture(renderer, "D:/Project code/__Maintained Projects and Libraries/ODIN/massimodin/build/TexturePacking/default/swordsmanIdle/0000_540_47x48.png")
	}

    if land == nil {
        print("Failed to load texture:", SDL.GetError())
        return
    }
    defer SDL.DestroyTexture(land)

    tex_target := SDL.CreateTexture(renderer, u32(SDL.PixelFormatEnum.RGBA8888),
                                    .TARGET, 96, 64)
	SDL.SetTextureBlendMode(tex_target, .BLEND)
    if tex_target == nil {
        print("Failed to create target texture:", SDL.GetError())
        return
    }
    defer SDL.DestroyTexture(tex_target)

	startTime := get_time()
    done := false
    for !done {
		dstRect := SDL.Rect{0, 0, 96, 64}
		//SDL.RenderFlush(renderer)
        // Render to the texture
        SDL.SetRenderTarget(renderer, tex_target)
        SDL.SetRenderDrawColor(renderer, 255, 255, 255, 0)
        SDL.RenderClear(renderer)
        SDL.RenderCopy(renderer, land, nil, nil)

        // Render to the screen
        SDL.SetRenderTarget(renderer, nil)
        SDL.SetRenderDrawColor(renderer, 0xBD, 0xE3, 255, 255)
        SDL.RenderClear(renderer)
		SDL.RenderCopy(renderer, land, nil, &dstRect)
        // Use shader program
        old_program: i32
        gl.GetIntegerv(gl.CURRENT_PROGRAM, &old_program)
        gl.UseProgram(program_id)

        // Bind texture
        //SDL.GL_BindTexture(tex_target, nil, nil)
        gl.Uniform1i(texture_id, 0)
        gl.Uniform1f(time_id, get_time() - startTime)
		//print(get_time() - startTime)

        // Render the texture using SDL_RenderCopy
		dstRect.x += 100
        SDL.RenderCopy(renderer, tex_target, nil, &dstRect)

        // Unbind texture
        //SDL.GL_UnbindTexture(tex_target)
		
        // Flush renderer and present
        //SDL.RenderFlush(renderer)
        // Restore old program
        gl.UseProgram(u32(old_program))

		dstRect.x += 100
		SDL.RenderCopy(renderer, land, nil, &dstRect)
        SDL.RenderPresent(renderer)


        event: SDL.SDLEvent
        for SDL.PollEvent(&event) {
            #partial switch event.type {
            case .QUIT:
                done = true
            case .KEYDOWN:
                if event.key.keysym.sym == .ESCAPE {
                    done = true
                }
            }
        }
    }
}