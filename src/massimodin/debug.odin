package massimodin //@nested-tags:debug

import time_ "core:time"
import "core:path/filepath"
import "core:os"
import "../sdl2"
import "../tinyfd"
import "core:fmt"
import "base:runtime"
import "base:intrinsics"
import stacktrace "core:debug/trace"
import "core:sys/posix"
import win32 "core:sys/windows"

DebugSystem :: struct{
	showInfo:bool,
	freeCamSpeed:f32,
	capture_enabled:bool,
	capture_pipe:^posix.FILE,
	capture_frame_size:[2]i32,
	capture_path:string,
	capture_hd_tex:Tex
}
debug:^DebugSystem

_debug_system_init :: proc(){
	debug = new(DebugSystem, os_allocator)
	debug.capture_hd_tex = tex_make(1920,1080)
}

DEBUG :: ODIN_DEBUG
STACKTRACE_ENABLED :: DEBUG && !ODIN_DISABLE_ASSERT && !#config(TRACY_ENABLE, false)

print :: proc(args:..any, sep := " ", flush := true) -> int{
	when ON_SWITCH{
		str := fmt.ctprint(..args, sep=sep)
		sdl2.Log(str)
		return len_cstring(str)
	}
	else{
		return fmt.println(..args, sep=sep, flush=flush)
	}
}
printf :: proc(format:string, args:..any, flush := true) -> int{
	when ON_SWITCH{
		str := fmt.ctprintf(format, ..args)
		sdl2.Log(str)
		return len_cstring(str)
	}
	else{
		return fmt.printfln(format, ..args, flush=flush)
	}
}

assertf :: fmt.assertf
panicf :: fmt.panicf

_debug_system_update :: proc(){
	switch input_device(){
		case .keyboard:
			stage.target_camera_pos += Vec2(Vec2i{
				int(key_held(.RIGHT)) - int(key_held(.LEFT)),
				int(key_held(.DOWN)) - int(key_held(.UP)),
			})*debug.freeCamSpeed
		case .gamepad:
			stage.target_camera_pos += vec2_normalize(input_gamepad_directional_axes(.rStick))*debug.freeCamSpeed
	}
}

_debug_info_draw :: proc(){
	fonts.default = fo.fairfax__24
	if(time.lastFrameDuration > 0){
		text_draw(
			format("FPS: %.2f (%.2fms)", 1/time.lastFrameDuration*1000, time.lastFrameDuration),
			10, 10, COLOR_YELLOW, 1
		)
	}

	defaultArena := cast(^Arena)default_allocator.data
	text_draw(
		format("Default allocator usage: %iMB", defaultArena.total_used/1_000_000),
		10, 12+text_char_height(), COLOR_YELLOW, 1
	)
	
}

debug_stacktrace_print :: proc(){
	ctx := _stacktrace_context
	if !stacktrace.in_resolve(ctx) {
		buf: [64]stacktrace.Frame
		fmt.println("Callstack:")
		// skip=1 to omit the current frame (this proc)
		frames := stacktrace.frames(ctx, 2, buf[:])
		for frame, i in frames {
			fl := stacktrace.resolve(ctx, frame, context.temp_allocator)
			if fl.loc.file_path != "" || fl.loc.line != 0 {
				fmt.printfln("%i: %v", i, fl.loc)
			}
		}
	}
}

debug_free_cam_enabled :: #force_inline proc "contextless"()->bool{
	return DEBUG && debug.freeCamSpeed != 0
}

_debug_capture_update :: proc(){
	bpp :: 4
	if key_pressed(.F9){
		debug.capture_enabled = !debug.capture_enabled 
		if !debug.capture_enabled{
			//end capture
			posix.pclose(debug.capture_pipe);
			debug.capture_pipe   = nil;
			audio_capture_stop()

			muxCmd := fmt.caprintf(
				"ffmpeg -loglevel warning -y " +
				"-f f32le -ar %i -ac %i -i \"%s.temp.raw\" " +
				"-i \"%s.temp.mov\" " +
				"-c:v copy -c:a pcm_f32le -ac 2 \"%s.mov\"",
				audio.capture_sample_rate, audio.capture_channels, debug.capture_path,
				debug.capture_path,              
				debug.capture_path,
				allocator = context.temp_allocator
			)
			
			if muxPipe := posix.popen(muxCmd, "rb"); muxPipe != nil do posix.pclose(muxPipe)

			os.remove(format("%s.temp.mov", debug.capture_path))
			os.remove(format("%s.temp.raw", debug.capture_path))

			delete(debug.capture_path)
			print("Capture ended!")
		}
		else{
			//start capture
			debug.capture_frame_size = display.hd_enabled ? {1920,1080}:{DISPLAY_WIDTH, DISPLAY_HEIGHT}
			
			saveDir,_ := filepath.join({project_directory, "media/captures"}, context.temp_allocator)
			if !os.exists(saveDir) do os.make_directory(saveDir)

			
			t:=time_.now()
			dBuf:[16]u8
			tBuf:[16]u8
			hms,_ := string_replace_all(time_.to_string_hms_12(t, tBuf[:]), ":", "-", context.temp_allocator)
			debug.capture_path, _ = filepath.join({saveDir, format(
				"capture %s %s", 
				time_.to_string_yyyy_mm_dd(t, dBuf[:]), 
				hms
			)})

			pixelProfile :: "-c:v prores_ks -profile:v 4 -pix_fmt yuva444p10le"
			hdProfile :: "-c:v prores_ks -profile:v 3 -pix_fmt yuv422p10le"

			cmd := fmt.caprintf(
				"ffmpeg -loglevel warning -y -f rawvideo -pixel_format rgba -video_size %ix%i -framerate 60 -i - %s \"%s.temp.mov\"",
				debug.capture_frame_size.x, debug.capture_frame_size.y, display.hd_enabled?pixelProfile:pixelProfile, debug.capture_path, 
				allocator=context.temp_allocator
			);

			debug.capture_pipe = posix.popen(cmd, "wb");
			if debug.capture_pipe == nil{
				debug.capture_enabled = false
				print("Warning: Capture failed to start.")
				return
			}

			print("Capture started successfully!")
			
			audio_capture_start(format("%s.temp.raw", debug.capture_path))
		}
	}

	if debug.capture_enabled{
		buffer := make([]u8, debug.capture_frame_size.x*debug.capture_frame_size.y*bpp, context.temp_allocator)
		if display.hd_enabled{ //4k GPU->CPU readback is bottlenecked by PCIe bandwidth, render down to HD to mitigate this
			target := tex_target_get()
			tex_target_set(debug.capture_hd_tex)
				sdl2.RenderCopy(display._renderer, target, nil, nil)
				sdl2.RenderReadPixels(display._renderer, nil, u32(sdl2.PixelFormatEnum.ABGR8888), &buffer[0], debug.capture_frame_size.x*bpp)
			tex_target_reset()
		}
		else do sdl2.RenderReadPixels(display._renderer, nil, u32(sdl2.PixelFormatEnum.ABGR8888), &buffer[0], debug.capture_frame_size.x*bpp)

		posix.fwrite(&buffer[0], 1, uint(len(buffer)), debug.capture_pipe)
	}
}