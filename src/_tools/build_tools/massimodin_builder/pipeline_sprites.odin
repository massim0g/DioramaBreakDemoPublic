package massimodin_builder

import "core:os"
import "core:strings"
import "core:path/filepath"
import "core:bytes"
import "core:mem"
import "core:math"
import "core:slice"
import "core:fmt"
import "core:thread"
import "core:compress/zlib"
import "core:image"
import "core:image/qoi"
import "core:image/png"

// Aseprite format constants

ASE_MAGIC			:: 0xA5E0
ASE_FRAME_MAGIC		:: 0xF1FA

ASE_CHUNK_LAYER		:: 0x2004
ASE_CHUNK_CEL		:: 0x2005
ASE_CHUNK_TAGS   	:: 0x2018
ASE_CHUNK_PALETTE	:: 0x2019
ASE_CHUNK_PALETTE_OLD		:: 0x0004
ASE_CHUNK_PALETTE_OLD_6BIT	:: 0x0011
ASE_CHUNK_SLICE		:: 0x2022
ASE_CHUNK_TILESET	:: 0x2023

ASE_LAYER_VISIBLE :: 1

AseCelKind :: enum u16{
	raw,
	linked,
	compressed,
	compressedTilemap
}

AseBlendMode :: enum u16{
	normal,
	multiply,
	screen,
	overlay,
	darken,
	lighten,
	color_dodge,
	color_burn,
	hard_light,
	soft_light,
	difference,
	exclusion,
	hue,
	saturation,
	color,
	luminosity,
	addition,
	subtract,
	divide,
}

AseCel :: struct{
	data:[]u8,
	order:i32, //layer index offset by the cel's z-index
	pos:[2]i16,
	size:[2]u16,
	blendmode:AseBlendMode,
	zIndex:i16,
	opacity:u8
}

AseCelCached :: struct{
	data:[]u8,
	size:[2]u16
}

AseTileset :: struct{
	pixels:[]u8, //all tiles' image data, stacked vertically
	tileSize:[2]u16,
	tileCount:u32,
	emptyFirstTile:bool
}

AseLayer :: struct{
	celCache:[]AseCelCached,
	tilesetIndex:u32,
	blendMode:AseBlendMode,
	opacity:u8,
	visible:bool,
	isOrigin:bool,
	isMask:bool,
}



Blend :: [4]u8
//While aseprite files can have palettes larger than 256, indexed file pixel color indices are u8, so cannot address palettes larger than 256 anyway
AsePalette :: [256]Blend

// Sprite pipeline constants

SPRITE_PAGE_SIZE :: 4096

SPRITE_IDS_DEFAULT :: `package massimodin

SpriteIDs :: struct{
//<declarations>
//</declarations>
nil_:^Sprite
}
sp:^SpriteIDs

_reload_sprite_ids :: proc(){
//<assignments>
//</assignments>
}`

// Types

SpriteFileEntry :: struct{
	fullpath:string,
	relativeDir:string,
	stem:string,
	groupIndex:int,
	indexBuffer:^bytes.Buffer, //NOT per file, points to the batch's buffer
	indexDataOff:uintptr,
	indexDataSize:uintptr,
	imageBuffer:^bytes.Buffer,
	imageDataOff:uintptr,
	imageDataSize:uintptr,
	addNames:bool,
	namesStart:int,
	namesCount:int
}

TexGroup :: struct{
	name:string,
	startIndex:int,
	count:int,
}

SpritesParseTask :: struct{
	spriteFiles:[]SpriteFileEntry,
	namesToAdd:[dynamic][2]string,
	out:bytes.Buffer,
	imageOut:bytes.Buffer,
	alloc:mem.Allocator
}

PackGroupTask :: struct{
	sprites:[]SpriteFileEntry,
	groupName:string,
	pagesDir:string,
	indexOut:bytes.Buffer,
	alloc:mem.Allocator
}

SpritePackRect :: struct{
	imageData:[^]u8,
	indexBufferPagePosPtr:uintptr,
	size:[2]u16
}

//globals to be accessed by threads
sprite_existing_ids:^map[string]bool

//Encodes ABGR8888 pixels as a .qoi file. Also used by the fonts pipeline for its pages.
qoi_write_to_file :: proc(pixels:[]u8, w, h:int, path:string){
	img:image.Image
	img.width = w
	img.height = h
	img.channels = 4
	img.depth = 8
	img.pixels.buf = slice_to_dynamic(pixels, context.allocator) //allocator doesn't matter here

	if err := qoi.save_to_file(path, &img, allocator=context.temp_allocator); err != nil{
		printf("ERROR: Failed to save page '%s', %v", path, err)
		return
	}
}
//Encodes ABGR8888 pixels as a .qoi stream APPENDED to the passed buffer. 
//Adapted from core:image/qoi save_to_buffer (odin dev-2026-06), which wants to own the entire output buffer instead of appending.
qoi_write_to_buffer :: proc(pixels:[]u8, w, h:int, out:^bytes.Buffer){
	assert(len(pixels) == w*h*4, "Pixel data doesn't match the given qoi page dimensions!")
	written := len(out.buf)

	//allocate the maximum possible size, reclaimed to the actually written size at the end
	max_size := w*h*5 + size_of(image.QOI_Header) + size_of(u64be)
	if resize(&out.buf, written + max_size) != nil{
		printf("ERROR: Failed to resize qoi page output buffer!")
		return
	}

	header := image.QOI_Header{
		magic       = image.QOI_Magic,
		width       = u32be(w),
		height      = u32be(h),
		channels    = 4,
		color_space = .sRGB,
	}
	headerBytes := transmute([size_of(image.QOI_Header)]u8)header
	copy(out.buf[written:], headerBytes[:])
	written += size_of(image.QOI_Header)

	seen:[64]qoi.RGBA_Pixel
	pix := qoi.RGBA_Pixel{0, 0, 0, 255}
	prev := pix

	input := pixels
	run := u8(0)

	for len(input) > 0{
		pix = (^qoi.RGBA_Pixel)(raw_data(input))^
		input = input[4:]

		if pix == prev{
			//as long as the pixel matches the last one, accumulate the run total.
			//if we reach the max run length or the end of the image, write the run
			run += 1
			if run == 62 || len(input) == 0{
				out.buf[written] = u8(qoi.QOI_Opcode_Tag.RUN) | (run - 1)
				written += 1
				run = 0
			}
		}
		else{
			if run > 0{ //the pixel differs from the previous one, but we still need to write the pending run
				out.buf[written] = u8(qoi.QOI_Opcode_Tag.RUN) | (run - 1)
				written += 1
				run = 0
			}

			index := qoi.qoi_hash(pix)
			if seen[index] == pix{
				out.buf[written] = u8(qoi.QOI_Opcode_Tag.INDEX) | index
				written += 1
			}
			else{
				seen[index] = pix

				//if the alpha matches the previous pixel's alpha, we don't need to write a full RGBA literal
				if pix.a == prev.a{
					d  := pix.rgb - prev.rgb
					_d := d + 2 //DIFF, biased and modulo 256
					_l := qoi.RGB_Pixel{d.r - d.g + 8, d.g + 32, d.b - d.g + 8} //LUMA, biased and modulo 256

					if _d.r < 4 && _d.g < 4 && _d.b < 4{
						//delta is between -2 and 1 inclusive
						out.buf[written] = u8(qoi.QOI_Opcode_Tag.DIFF) | _d.r << 4 | _d.g << 2 | _d.b
						written += 1
					}
					else if _l.r < 16 && _l.g < 64 && _l.b < 16{
						//biased luma is between {-8..7, -32..31, -8..7}
						out.buf[written]     = u8(qoi.QOI_Opcode_Tag.LUMA) | _l.g
						out.buf[written + 1] = _l.r << 4 | _l.b
						written += 2
					}
					else{
						out.buf[written] = u8(qoi.QOI_Opcode_Tag.RGB)
						copy(out.buf[written + 1:], pix[:3])
						written += 4
					}
				}
				else{
					out.buf[written] = u8(qoi.QOI_Opcode_Tag.RGBA)
					copy(out.buf[written + 1:], pix[:])
					written += 5
				}
			}
		}
		prev = pix
	}

	trailer := []u8{0, 0, 0, 0, 0, 0, 0, 1}
	copy(out.buf[written:], trailer[:])
	written += len(trailer)

	resize(&out.buf, written)
}
qoi_write :: proc{qoi_write_to_file, qoi_write_to_buffer}

// File parsing

mul_un8 :: #force_inline proc "contextless" (a, b:int) -> int{
	t := a * b + 0x80
	return (t + (t >> 8)) >> 8
}

ase_string_read :: proc(r:^uintptr) -> string{
	length := read(r, u16)
	if length == 0 do return ""
	s := strings.string_from_ptr(cast(^u8)r^, int(length))
	r^ += uintptr(length)
	return s
}

//Returns the data of a cell chunk. Opacity is the combined layer and cel opacity. Also caches it if applicable.
ase_cel_chunk_read :: proc(offset:uintptr, chunkSize:uintptr, frame:u16, layers:[]AseLayer, tilesets:[]AseTileset, frameOffsets:[]uintptr, palette:^AsePalette, fileEnd:uintptr, doMaskCheck:bool) -> (out:AseCel, isMask:bool, ok:bool){
	r := offset
	layerInd := read(&r, u16)
	layer := &layers[layerInd]
	isMask = layer.isMask && doMaskCheck
	if !layer.visible && !isMask do return

	read(&r, &out.pos)
	read(&r, &out.opacity)
	out.opacity = u8(mul_un8(int(out.opacity), int(layer.opacity)))
	out.blendmode = layer.blendMode

	celKind := read(&r, AseCelKind)
	read(&r, &out.zIndex)
	out.order = i32(layerInd) + i32(out.zIndex)
	r += 5 //skip reserved bytes

	switch celKind{
		case .compressed:
			read(&r, &out.size)
			compSize := chunkSize - (r - (offset-6))
			out.data = zlib_decompress(slice.bytes_from_ptr(rawptr(r), int(compSize)))

			if palette != nil{
				rgba := make([]Blend, int(out.size.x)*int(out.size.y), context.temp_allocator)
				for &b,i in rgba{
					b = palette[out.data[i]]
				}
				out.data = slice.to_bytes(rgba)
			}

			cache := &layer.celCache[frame]
			cache.data = out.data
			cache.size = out.size

		case .compressedTilemap:
			size := read(&r, [2]u16)
			sizei := cast([2]int)size
			bitsPerTile := read(&r, u16)
			tileIdMask := read(&r, u32)
			xFlipMask := read(&r, u32)
			yFlipMask := read(&r, u32)
			diagFlipMask := read(&r, u32)
			r += 10 //skip reserved bytes

			if bitsPerTile != 32{
				printf("WARNING: Unsupported tilemap bits-per-tile value '%v', skipping cel.", bitsPerTile)
				return
			}
			if int(layer.tilesetIndex) >= len(tilesets) || tilesets[layer.tilesetIndex].pixels == nil{
				print("WARNING: Tilemap cel references a missing tileset, skipping cel.")
				return
			}
			tileset := &tilesets[layer.tilesetIndex]

			compSize := chunkSize - (r - (offset-6))
			grid := slice.reinterpret([]u32, zlib_decompress(slice.bytes_from_ptr(rawptr(r), int(compSize))))
			if len(grid) < sizei.x*sizei.y{
				print("WARNING: Failed to decompress a tilemap cel's tile grid, skipping cel.")
				return
			}

			out.size = size*tileset.tileSize
			out.data = make([]u8, int(out.size.x)*int(out.size.y)*4, context.temp_allocator)

			tileSizei := cast([2]int)tileset.tileSize
			tilesetCounti := int(tileset.tileCount)

			//blit tile data pixel-by-pixel while applying per-tile rotation/flipping
			for ty in 0..<sizei.y{
				for tx in 0..<sizei.x{
					tile := grid[ty*sizei.x + tx]
					id := int(tile & tileIdMask)
					if id == 0 && tileset.emptyFirstTile do continue
					if id >= tilesetCounti do continue

					xFlip := tile & xFlipMask != 0
					yFlip := tile & yFlipMask != 0
					diagFlip := tile & diagFlipMask != 0

					for py in 0..<tileSizei.y{
						for px in 0..<tileSizei.x{
							srcPos := [2]int{
								xFlip ? tileSizei.x-1-px : px,
								yFlip ? tileSizei.y-1-py : py
							}
							if diagFlip do srcPos = {srcPos.y, srcPos.x}

							srcInd := (id*tileSizei.y + srcPos.y)*tileSizei.x + srcPos.x
							dstInd := ((ty*tileSizei.y + py)*sizei.x*tileSizei.x + tx*tileSizei.x + px)*4
							copy(out.data[dstInd:], 
								palette != nil ? palette[tileset.pixels[srcInd]][:] : tileset.pixels[srcInd*4:][:4]
							)
						}
					}
				}
			}

			tileCache := &layer.celCache[frame]
			tileCache.data = out.data
			tileCache.size = out.size

		case .linked:
			linkedFrame := read(&r, u16)
			cache := layer.celCache[linkedFrame]
			out.data = cache.data
			out.size = cache.size
			if out.data == nil{
				//seek to uncached cel with frame offsets
				r = frameOffsets[linkedFrame] + 16
				
				foundChunkSize:uintptr
				for{
					if r >= fileEnd do return //could not find cel in file

					chunkOff := r
					foundChunkSize = uintptr(read(&r, u32))
					foundChunkKind := read(&r, u16)

					if foundChunkKind == ASE_FRAME_MAGIC do return //could not find the cel in the frame to search

					if foundChunkKind == ASE_CHUNK_CEL && (cast(^u16)r)^ == layerInd do break //found

					r = chunkOff + foundChunkSize //go to next chunk
				}

				linkedCel,_ := ase_cel_chunk_read(r, foundChunkSize, linkedFrame, layers, tilesets, frameOffsets, palette, fileEnd, doMaskCheck) or_return
				out.data = linkedCel.data
				out.size = linkedCel.size
			}

		case .raw:
			print("WARNING: Raw aseprite cel kind found in file, skipping.") //not bothering to print the file name becasue this really should not happen
			return
	}

	if out.size == 0 do return

	ok = true
	return
}

ase_blit_cel :: proc(dst:[]u8, dstW, dstH:int, src:[]u8, srcW, srcH:int, offX, offY:int, opacity:u8 = 255, blendMode:AseBlendMode = .normal){
	mul_un8_v :: #force_inline proc "contextless" (a, b:[3]u16) -> [3]u16{
		t := a * b + 0x80
		return (t + t / 256) / 256
	}

	blend_hsl_lum :: proc "contextless" (r, g, b:int) -> int{
		return (r * 299 + g * 587 + b * 114) / 1000
	}

	blend_hsl_sat :: proc "contextless" (r, g, b:int) -> int{
		return max(r, g, b) - min(r, g, b)
	}

	blend_hsl_clip :: proc "contextless" (r, g, b:int) -> (int, int, int){
		r, g, b := r, g, b
		l := blend_hsl_lum(r, g, b)
		lo := min(r, g, b)
		hi := max(r, g, b)
		if lo < 0{
			r = l + (r - l) * l / (l - lo)
			g = l + (g - l) * l / (l - lo)
			b = l + (b - l) * l / (l - lo)
		}
		if hi > 255{
			r = l + (r - l) * (255 - l) / (hi - l)
			g = l + (g - l) * (255 - l) / (hi - l)
			b = l + (b - l) * (255 - l) / (hi - l)
		}
		return r, g, b
	}

	blend_hsl_set_lum :: proc "contextless" (r, g, b, lum:int) -> (int, int, int){
		d := lum - blend_hsl_lum(r, g, b)
		return blend_hsl_clip(r + d, g + d, b + d)
	}

	blend_hsl_set_sat :: proc "contextless" (r, g, b, sat:int) -> (int, int, int){
		r, g, b := r, g, b
		cMax := max(r, g, b)
		cMin := min(r, g, b)
		if cMax == cMin{
			return 0, 0, 0
		}
		scale := cMax - cMin
		if r == cMax{
			if g == cMin{
				b = (b - cMin) * sat / scale
				g = 0
			} else{
				g = (g - cMin) * sat / scale
				b = 0
			}
			r = sat
		} else if g == cMax{
			if r == cMin{
				b = (b - cMin) * sat / scale
				r = 0
			} else{
				r = (r - cMin) * sat / scale
				b = 0
			}
			g = sat
		} else{
			if r == cMin{
				g = (g - cMin) * sat / scale
				r = 0
			} else{
				r = (r - cMin) * sat / scale
				g = 0
			}
			b = sat
		}
		return r, g, b
	}

	blend :: proc "contextless" (d, s:Blend, mode:AseBlendMode) -> Blend{
		dv := [3]u16{u16(d[0]), u16(d[1]), u16(d[2])}
		sv := [3]u16{u16(s[0]), u16(s[1]), u16(s[2])}
		rv:[3]u16

		switch mode{
			case .normal:
				return s

			// Array ops
			case .multiply:
				rv = mul_un8_v(dv, sv)
			case .screen:
				rv = dv + sv - mul_un8_v(dv, sv)
			case .exclusion:
				rv = dv + sv - 2 * mul_un8_v(dv, sv)

			// Element-wise
			case .darken:
				return {min(d[0], s[0]), min(d[1], s[1]), min(d[2], s[2]), s[3]}
			case .lighten:
				return {max(d[0], s[0]), max(d[1], s[1]), max(d[2], s[2]), s[3]}
			case .addition:
				t := dv + sv
				for i in 0..<3 do rv[i] = min(255, t[i])
			case .subtract:
				for i in 0..<3 do rv[i] = dv[i] >= sv[i] ? dv[i] - sv[i] : 0
			case .difference:
				for i in 0..<3 do rv[i] = dv[i] >= sv[i] ? dv[i] - sv[i] : sv[i] - dv[i]
			case .divide:
				for i in 0..<3 do rv[i] = sv[i] == 0 ? 0 : min(255, dv[i] * 255 / sv[i])

			// Per-channel conditional
			case .overlay:
				for i in 0..<3{
					bi, si := int(dv[i]), int(sv[i])
					rv[i] = u16(bi < 128 ? mul_un8(si, bi << 1) : 255 - mul_un8(255 - si, (255 - bi) << 1))
				}
			case .hard_light:
				for i in 0..<3{
					bi, si := int(dv[i]), int(sv[i])
					rv[i] = u16(si < 128 ? mul_un8(bi, si << 1) : 255 - mul_un8(255 - bi, (255 - si) << 1))
				}
			case .color_dodge:
				for i in 0..<3{
					bi, si := int(dv[i]), int(sv[i])
					rv[i] = u16(bi == 0 ? 0 : (si == 255 ? 255 : min(255, bi * 255 / (255 - si))))
				}
			case .color_burn:
				for i in 0..<3{
					bi, si := int(dv[i]), int(sv[i])
					rv[i] = u16(bi == 255 ? 255 : (si == 0 ? 0 : max(0, 255 - (255 - bi) * 255 / si)))
				}
			case .soft_light:
				for i in 0..<3{
					bi, si := int(dv[i]), int(sv[i])
					if si < 128{
						rv[i] = u16(bi - mul_un8(mul_un8(255 - (si << 1), bi), 255 - bi))
					} else if si == 128{
						rv[i] = dv[i]
					} else{
						di := bi < 64 ? bi + mul_un8(mul_un8(bi, 16 * bi * 255 / 65025 - 12) + 1020, 255 - bi) : int(math.sqrt(f32(bi) / 255.0) * 255.0)
						rv[i] = u16(bi + mul_un8((si << 1) - 255, di - bi))
					}
				}

			// HSL
			case .hue:
				sr, sg, sb := int(sv[0]), int(sv[1]), int(sv[2])
				br, bg, bb := int(dv[0]), int(dv[1]), int(dv[2])
				r, g, b := blend_hsl_set_lum(blend_hsl_set_sat(sr, sg, sb, blend_hsl_sat(br, bg, bb)), blend_hsl_lum(br, bg, bb))
				return {u8(r), u8(g), u8(b), s[3]}
			case .saturation:
				sr, sg, sb := int(sv[0]), int(sv[1]), int(sv[2])
				br, bg, bb := int(dv[0]), int(dv[1]), int(dv[2])
				r, g, b := blend_hsl_set_lum(blend_hsl_set_sat(br, bg, bb, blend_hsl_sat(sr, sg, sb)), blend_hsl_lum(br, bg, bb))
				return {u8(r), u8(g), u8(b), s[3]}
			case .color:
				sr, sg, sb := int(sv[0]), int(sv[1]), int(sv[2])
				br, bg, bb := int(dv[0]), int(dv[1]), int(dv[2])
				r, g, b := blend_hsl_set_lum(sr, sg, sb, blend_hsl_lum(br, bg, bb))
				return {u8(r), u8(g), u8(b), s[3]}
			case .luminosity:
				sr, sg, sb := int(sv[0]), int(sv[1]), int(sv[2])
				br, bg, bb := int(dv[0]), int(dv[1]), int(dv[2])
				r, g, b := blend_hsl_set_lum(br, bg, bb, blend_hsl_lum(sr, sg, sb))
				return {u8(r), u8(g), u8(b), s[3]}
		}

		return {u8(rv[0]), u8(rv[1]), u8(rv[2]), s[3]}
	}

	if blendMode == .normal{ //hot path
		for y in 0..<srcH{
			dy := offY + y
			if dy < 0 || dy >= dstH do continue

			srcRow := y * srcW * 4
			dstRow := dy * dstW * 4

			x0 := max(0, -offX)
			x1 := min(srcW, dstW - offX)

			for x in x0..<x1{
				s := (cast(^Blend)&src[srcRow + x * 4])^
				if s.a == 0 do continue
				if opacity < 255 do s.a = u8(mul_un8(int(s.a), int(opacity)))
				d := cast(^Blend)&dst[dstRow + (offX + x) * 4]

				if d.a == 0 do d^ = s
				else{
					sAlpha := int(s.a)
					dAlpha := int(d.a)
					outAlpha := sAlpha + dAlpha - mul_un8(dAlpha, sAlpha)
					sCol := cast([3]int)s.rgb
					dCol := cast([3]int)d.rgb
					outCol := dCol + (sCol - dCol)*sAlpha/outAlpha
					d.rgb = cast([3]u8)outCol
					d.a = u8(outAlpha)
				}
			}
		}
	}
	else{
		for y in 0..<srcH{
			dy := offY + y
			if dy < 0 || dy >= dstH do continue

			srcRow := y * srcW * 4
			dstRow := dy * dstW * 4

			x0 := max(0, -offX)
			x1 := min(srcW, dstW - offX)

			for x in x0..<x1{
				s := (cast(^Blend)&src[srcRow + x * 4])^
				if s[3] == 0 do continue
				if opacity < 255 do s.a = u8(mul_un8(int(s.a), int(opacity)))
				d := cast(^Blend)&dst[dstRow + (offX + x) * 4]

				s = blend(d^, s, blendMode)

				if d.a == 0 do d^ = s
				else{
					sAlpha := int(s.a)
					dAlpha := int(d.a)
					outAlpha := sAlpha + dAlpha - mul_un8(dAlpha, sAlpha)
					sCol := cast([3]int)s.rgb
					dCol := cast([3]int)d.rgb
					outCol := dCol + (sCol - dCol)*sAlpha/outAlpha
					d.rgb = cast([3]u8)outCol
					d.a = u8(outAlpha)
				}
			}
		}
	}
}

zlib_decompress :: proc(compressed:[]u8, allocator:=context.temp_allocator) -> []u8{
	buf:bytes.Buffer
	bytes.buffer_init_allocator(&buf, 0, 0, allocator)
	err := zlib.inflate(compressed, &buf)
	if err != nil do return nil
	return bytes.buffer_to_bytes(&buf)
}

sprites_parse_batch_proc :: proc(task:thread.Task){
	data := cast(^SpritesParseTask)task.data

	context.allocator = task.allocator
	context.temp_allocator = allocator_make()
	defer allocator_delete(context.temp_allocator)

	for &entry in data.spriteFiles{
		free_all(context.temp_allocator)

		entry.indexBuffer = &data.out
		entry.imageBuffer = &data.imageOut
		entry.indexDataOff = uintptr(len(entry.indexBuffer.buf))
		entry.imageDataOff = uintptr(len(entry.imageBuffer.buf))

		entry.namesStart = len(data.namesToAdd)

		if filepath.ext(entry.fullpath) == ".png" do spritefile_png_parse(&entry, &data.namesToAdd)
		else do spritefile_aseprite_parse(&entry, &data.namesToAdd)

		entry.namesCount = len(data.namesToAdd) - entry.namesStart
		entry.indexDataSize = uintptr(len(entry.indexBuffer.buf)) - entry.indexDataOff
		entry.imageDataSize = uintptr(len(entry.imageBuffer.buf)) - entry.imageDataOff
	}
}

/*index specification:
Per sprite:
	- Sprite name size (u8)
	- Sprite name ([]u8)
	- Original w (u16)
	- Original h (u16)
	- Origin x (i16)
	- Origin y (i16)
	- Mask kind (u8)
	- If Mask kind not 0:
		- mask w (u16)
		- mask h (u16)
		- mask origin x (i16)
		- mask origin y (i16)
		- If Mask kind is 2:
			precise coords count (u32)
			precise coords ([][2]i16)
	- Frame count (u16)
	Per frame:
		- Frame duration (u16)
		- Trim offset x (i16)
		- Trim offset y (i16)
		- Trimmed frame w (u16)
		- Trimmed frame h (u16)
		- Page x (u16)
		- Page y (u16)
		- Page ind (u8)
	
*/
spritefile_aseprite_parse :: proc(fileInfo:^SpriteFileEntry, namesToAdd:^[dynamic][2]string){
	out := fileInfo.indexBuffer

	fileData, readErr := os.read_entire_file(fileInfo.fullpath, context.temp_allocator)
	if readErr != nil{
		printf("WARNING: Could not read sprite file '%s' (%v), skipping.", fileInfo.fullpath, readErr)
		return
	}
	if len(fileData) < 128{
		printf("WARNING: Aseprite file '%s' is truncated, skipping.", fileInfo.fullpath)
		return
	}

	r := uintptr(&fileData[0])
	fileEnd := r + uintptr(len(fileData))

	//Read file header (128 bytes)
	r += 4 //skip size
	if read(&r, u16) != ASE_MAGIC{
		printf("WARNING: Aseprite file '%s' is malformed, skipping.", fileInfo.fullpath)
		return
	}

	fileFrameCount := read(&r, u16)
	canvasSize := cast([2]int)read(&r, [2]u16)
	colorDepth := read(&r, u16)
	if colorDepth != 32 && colorDepth != 8{
		printf("WARNING: Aseprite file '%s' has an unsupported color depth, skipping.", fileInfo.fullpath)
		return
	}
	isIndexed := colorDepth == 8
	
	r += 14 //skip junk values
	transparentIdx := int(read(&r, u8))

	//Read any file metadata stored in the first frame's chunks (tags, layers, palettes, origin, mask) 
	r = uintptr(&fileData[0]) + 128 + 16 //skip frame 1 header

	origin:[2]i16
	hasMasks:bool
	palette:AsePalette
	paletteNewFound:bool

	layers := make([dynamic]AseLayer, context.temp_allocator)
	tilesets := make([dynamic]AseTileset, context.temp_allocator)

	AseTag :: struct{
		name:string,
		from:u16,
		to:u16,
	}
	tags := make([dynamic]AseTag, context.temp_allocator)

	frameOffsets := make([dynamic]uintptr, fileFrameCount, context.temp_allocator)

	visInherited:[16]bool

	for r < fileEnd{
		chunkOff := r
		chunkSize := read(&r, u32)
		defer r = chunkOff + uintptr(chunkSize) //go to next chunk

		chunkKind := read(&r, u16)

		if chunkKind == ASE_FRAME_MAGIC do break //we finished reading the first frame and are in frame 2's header

		switch chunkKind{
			case ASE_CHUNK_LAYER:
				layer:AseLayer
				defer append(&layers, layer) //always append layer, even if we skip, to preserve indexing

				layerVisible := (read(&r, u16) & ASE_LAYER_VISIBLE) == 1

				layerKind := read(&r, u16)
				layerChildLevel := read(&r, u16)

				visInherited[layerChildLevel] = layerVisible

				if layerKind == 1 do continue //group layer, skip

				r += 4 //skip some junk fields

				layer.blendMode = read(&r, AseBlendMode)
				layer.opacity = read(&r, u8)

				r += 3 //skip unused bytes

				layerName := ase_string_read(&r)
				if layerKind == 2 do layer.tilesetIndex = read(&r, u32) //tilemap layer
				if layerName == "_origin" do layer.isOrigin = true
				else if layerName == "_mask"{
					layer.isMask = true
					hasMasks = true
					layer.celCache = make([]AseCelCached, fileFrameCount, context.temp_allocator) //mask cels also get a cache despite being invisible
				}
				if layerName[0] == '_' do continue

				layer.visible = true
				for i:=i16(layerChildLevel); i>=0; i-=1{
					if !visInherited[i]{
						layer.visible = false
						break
					}
				}

				if layer.visible do layer.celCache = make([]AseCelCached, fileFrameCount, context.temp_allocator)
			
			case ASE_CHUNK_TAGS:
				tagsCount := read(&r, u16)
				r += 8 //unused
				for _ in 0..<tagsCount{
					from := read(&r, u16)
					to := read(&r, u16)
					r += 1 + 2 + 6 + 3 + 1 //skip irrelevant fields
					tagName := ase_string_read(&r)
					if tagName[0] == '_' do continue
					append(&tags, AseTag{tagName, from, to})
				}

			case ASE_CHUNK_PALETTE:
				if !isIndexed do continue
				paletteNewFound = true
				r += 4 //palette size (unused)
				first := read(&r, u32)
				last := read(&r, u32)
				r += 8
				for i in first..=last{
					flags := read(&r, u16)
					c:[4]u8
					c[0] = read(&r, u8)
					c[1] = read(&r, u8)
					c[2] = read(&r, u8)
					c[3] = read(&r, u8)
					if i < 256 do palette[i] = c
					if (flags & 1) != 0 do ase_string_read(&r)
				}
				palette[transparentIdx][3] = 0

			case ASE_CHUNK_PALETTE_OLD, ASE_CHUNK_PALETTE_OLD_6BIT: //"old" palette chunks, not a legacy thing, written by aseprite instead of the "new" chunks when the palette has no alpha or color names
				if !isIndexed || paletteNewFound do continue //per spec, old chunks are ignored when a new palette chunk exists
				colorInd := 0
				packetCount := read(&r, u16)
				for _ in 0..<packetCount{
					colorInd += int(read(&r, u8)) //entries skipped since the previous packet
					colorCount := int(read(&r, u8))
					if colorCount == 0 do colorCount = 256
					for _ in 0..<colorCount{
						c:[4]u8
						c[0] = read(&r, u8)
						c[1] = read(&r, u8)
						c[2] = read(&r, u8)
						c[3] = 255
						if chunkKind == ASE_CHUNK_PALETTE_OLD_6BIT{
							for &v in c[:3] do v = v<<2 | v>>4 //scale 0-63 up to 0-255
						}
						if colorInd < 256 do palette[colorInd] = c
						colorInd += 1
					}
				}
				palette[transparentIdx][3] = 0

			case ASE_CHUNK_TILESET:
				id := read(&r, u32)
				tsFlags := read(&r, u32)
				tileCount := read(&r, u32)
				tileSize := read(&r, [2]u16)
				r += 2 + 14 //skip base index and reserved bytes
				ase_string_read(&r) //skip name

				if tsFlags & 1 != 0{
					printf("WARNING: '%s' uses an external file tileset, which is unsupported! Skipping.", fileInfo.fullpath)
					continue
				}
				if tsFlags & 2 == 0 do continue //no embedded tile data

				compLen := read(&r, u32)
				for len(tilesets) <= int(id) do append(&tilesets, AseTileset{})
				tilesets[id] = AseTileset{
					pixels = zlib_decompress(mem.slice_ptr(cast(^u8)r, int(compLen))),
					tileSize = tileSize,
					tileCount = tileCount,
					emptyFirstTile = tsFlags & 4 != 0
				}

			case ASE_CHUNK_CEL:
				layer := layers[read(&r, u16)]
				if layer.isOrigin{
					origin = read(&r, [2]i16) //read cell position as origin
				}
		}
	}

	if len(tags) == 0 do append(&tags, AseTag{"", 0, fileFrameCount-1})

	//Get frame offsets
	r = uintptr(&fileData[0]) + 128

	for &off in frameOffsets{
		off = r
		r += uintptr((cast(^u32)r)^)
	}
	
	//Final per-tag write out, as well as compositing and write out of image data per frame
	frameCels := make([dynamic]AseCel, 0, len(layers), context.temp_allocator) //used for depth-sorting
	composite := make([]u8, canvasSize.x*canvasSize.y*4, context.temp_allocator)
	for tag in tags{
		tagSpriteName := sanitize_asset_name(fileInfo.stem)
		if tag.name != "" do tagSpriteName = fmt.aprintf("%s_%s", tagSpriteName, sanitize_tag_name(tag.name))

		write_v(out, u8(len(tagSpriteName)))
		bytes.buffer_write_string(out, tagSpriteName)
		write_v(out, cast([2]u16)canvasSize)
		write_v(out, origin)

		maskKind:u8
		maskSize:[2]u16
		maskOrigin:[2]i16
		maskPreciseData:[][2]i16
		
		for n in tag.from..=tag.to{
			mem.zero_slice(composite)
			
			r = frameOffsets[n]

			r += 6 //skip frame size and magic
			chunkCountOld := read(&r, u16)
			frameDuration := read(&r, u16)
			r += 2 //skip unused
			chunkCount := read(&r, u32)
			if chunkCount == 0 do chunkCount = u32(chunkCountOld)

			clear(&frameCels)
			doSort := false
			for _ in 0..<chunkCount{
				chunkOff := r
				chunkSize := uintptr(read(&r, u32))
				defer r = chunkOff + chunkSize //go to next chunk

				chunkKind := read(&r, u16)

				switch chunkKind{
					case ASE_CHUNK_CEL:
						//get cel image data (if visible)
						cel, isMask := ase_cel_chunk_read(r, chunkSize, n, layers[:], tilesets[:], frameOffsets[:], isIndexed?&palette:nil, fileEnd, hasMasks && n == tag.from) or_continue
						if isMask{
							maskOrigin = origin - cel.pos

							maskSize = cel.size
							s := cast([2]int)maskSize
							coords := make([dynamic][2]i16, context.temp_allocator)
							for y in 0..<s.y{
								for x in 0..<s.x{
									idx := y*s.x + x
									a := cel.data[idx*4 + 3]
									if a != 0 do append(&coords, [2]i16{i16(x), i16(y)})
								}
							}

							if len(coords) > 0{
								if len(coords) < s.x*s.y{
									maskKind = 2
									maskPreciseData = coords[:]
								} 
								else do maskKind = 1
							} 
							continue
						}
						append(&frameCels, cel)
						doSort = doSort || cel.zIndex != 0
				}
			}

			if n == tag.from{ //write out mask info and tag frame count
				write_v(out, maskKind)
				if maskKind != 0{
					write_v(out, maskSize)
					write_v(out, maskOrigin)
					if maskKind == 2{
						write_v(out, u32(len(maskPreciseData)))
						bytes.buffer_write_slice(out, maskPreciseData)
					}
				}
				write_v(out, tag.to - tag.from + 1)
			}

			//blit in z-order, matching aseprite's render order (cel z-index displaces it in the layer stack)
			if doSort{
				slice.sort_by(frameCels[:], proc(a,b:AseCel) -> bool{
					if a.order != b.order do return a.order < b.order
					return a.zIndex < b.zIndex
				})
			}

			for cel in frameCels{
				ase_blit_cel(
					composite, canvasSize.x, canvasSize.y,
					cel.data, int(cel.size.x), int(cel.size.y), int(cel.pos.x), int(cel.pos.y),
					cel.opacity, cel.blendmode
				)
			}

			//Write out
			write_v(out, frameDuration)

			// Trim composite
			left := canvasSize.x
			right := 0
			top := canvasSize.y
			bottom := 0
			for y in 0..<canvasSize.y{
				row := y * canvasSize.x * 4
				for x in 0..<canvasSize.x{
					if composite[row + x * 4 + 3] != 0{
						if x < left do left = x
						if x > right do right = x
						if y < top do top = y
						if y > bottom do bottom = y
					}
				}
			}

			if right < left{
				write_v(out, i16(0))
				write_v(out, i16(0))
				write_v(out, u16(0))
				write_v(out, u16(0))
				write_v(out, u32(len(fileInfo.imageBuffer.buf)) - u32(fileInfo.imageDataOff))
			}
			else{
				trimW := right - left + 1
				trimH := bottom - top + 1

				write_v(out, i16(left))
				write_v(out, i16(top))
				write_v(out, u16(trimW))
				write_v(out, u16(trimH))
				write_v(out, u32(len(fileInfo.imageBuffer.buf)) - u32(fileInfo.imageDataOff))

				rowBytes := trimW * 4
				for y in 0..<trimH{
					srcOff := ((top + y)*canvasSize.x + left)*4
					bytes.buffer_write(fileInfo.imageBuffer, composite[srcOff:][:rowBytes])
				}
			}
			
			write_v(out, u8(0)) //page ind, not used until later
		}

		if fileInfo.addNames{
			append(namesToAdd, [2]string{tagSpriteName, fileInfo.relativeDir})
		}
	}
}

spritefile_png_parse :: proc(fileInfo:^SpriteFileEntry, namesToAdd:^[dynamic][2]string){
	out := fileInfo.indexBuffer

	fileData, readErr := os.read_entire_file(fileInfo.fullpath, context.temp_allocator)
	if readErr != nil{
		printf("WARNING: Could not read PNG sprite '%s', skipping.", fileInfo.fullpath)
		return
	}
	img, imgErr := png.load_from_bytes(fileData, options={.alpha_add_if_missing}, allocator=context.temp_allocator)
	if imgErr != nil{
		printf("WARNING: Could not load PNG sprite '%s' (%v), skipping.", fileInfo.fullpath, imgErr)
		return
	}
	if img.depth != 8 || img.channels != 4{
		printf("WARNING: PNG sprite '%s' has an unsupported format (%d channels, %d bit), skipping.", fileInfo.fullpath, img.channels, img.depth)
		return
	}

	pixels := img.pixels.buf[:]
	w := img.width
	h := img.height

	//find the transparent-trimmed bounds. Fully transparent images keep the full canvas
	left := w
	right := -1
	top := h
	bottom := -1
	for y in 0..<h{
		row := y*w*4
		for x in 0..<w{
			if pixels[row + x*4 + 3] != 0{
				if x < left do left = x
				if x > right do right = x
				if y < top do top = y
				if y > bottom do bottom = y
			}
		}
	}

	trimX, trimY := 0, 0
	trimW, trimH := w, h
	if right >= left{
		trimX = left
		trimY = top
		trimW = right - left + 1
		trimH = bottom - top + 1
	}

	spriteName := sanitize_asset_name(fileInfo.stem)
	write_v(out, u8(len(spriteName)))
	bytes.buffer_write_string(out, spriteName)

	write_v(out, u16(w))
	write_v(out, u16(h))
	write_v(out, u16(0))
	write_v(out, u16(0))

	write_v(out, u8(0))

	write_v(out, u16(1))

	write_v(out, u16(0))
	write_v(out, i16(trimX))
	write_v(out, i16(trimY))
	write_v(out, u16(trimW))
	write_v(out, u16(trimH))

	//image data offset written to space reused for page coords later
	write_v(out, u32(len(fileInfo.imageBuffer.buf)) - u32(fileInfo.imageDataOff))
	for y in 0..<trimH{
		srcOff := ((trimY + y)*w + trimX)*4
		bytes.buffer_write(fileInfo.imageBuffer, pixels[srcOff:][:trimW*4])
	}

	write_v(out, u8(0))

	if fileInfo.addNames{
		append(namesToAdd, [2]string{spriteName, fileInfo.relativeDir})
	}
}


// Sprite data helpers

sprite_path_info :: proc(spritesDir:string, fullpath:string) -> (stem:string, relativeDir:string, texGroup:string){
	relativeDir, _ = filepath.rel(spritesDir, fullpath)
	fileName:string
	relativeDir, fileName = filepath.split(relativeDir)

	stem = filepath.stem(fileName)

	if relativeDir == ""{
		texGroup = "_extra"
		return
	}

	end := strings.index(relativeDir, "\\")
	texGroup = end <= 0 ? relativeDir : relativeDir[:end]

	return
}

sprites_scan_dir :: proc(dir:string, out:^[dynamic]string, recursive:=true){
	dh, err := os.open(dir)
	if err != nil do return
	entries, err2 := os.read_all_directory(dh, context.temp_allocator)
	os.close(dh)
	if err2 != nil do return

	for entry in entries{
		if entry.type == .Directory{
			if recursive do sprites_scan_dir(entry.fullpath, out)
		}
		else if file_has_extension(entry.name, {".aseprite", ".ase", ".png"}) do append(out, entry.fullpath)
	}
}

sprite_ids_cache_read :: proc(path:string) -> map[string][]string{
	out := make(map[string][]string)
	data, err := os.read_entire_file(path, context.temp_allocator)
	if err != nil do return out
	for line in strings.split_lines(string(data)){
		eq := strings.index(line, "=")
		if eq < 0 do continue
		ids := line[eq+1:]
		if len(ids) == 0 do continue
		out[line[:eq]] = strings.split(ids, ",")
	}
	return out
}

sprite_ids_cache_write :: proc(path:string, cache:map[string][]string){
	b := strings.builder_make()
	for fileName, ids in cache{
		if len(ids) == 0 do continue
		strings.write_string(&b, fileName)
		strings.write_byte(&b, '=')
		for id, i in ids{
			if i > 0 do strings.write_byte(&b, ',')
			strings.write_string(&b, id)
		}
		strings.write_string(&b, "\r\n")
	}
	_ = os.write_entire_file(path, transmute([]u8)strings.to_string(b))
}


// Atlas packing

//Strip-packs rects into a square pixel buffer, writing each rect's page position + index back into its index data slot. Returns the rects that didn't fit.
sprite_page_pack :: proc(rectsToPack:[]SpritePackRect, size:int, pixelsBase:uintptr, pageInd:u8) -> (leftovers:[]SpritePackRect){
	pagePitch := uintptr(size)*4
	maxDrawPos := u16(size)

	largestRowHeight:u16
	drawPos:[2]u16

	for &rect, i in rectsToPack{
		width := rect.size.x
		height := rect.size.y
		if drawPos.x + width > maxDrawPos{
			drawPos = {0, drawPos.y + largestRowHeight}
			largestRowHeight = 0
		}
		if drawPos.y + height > maxDrawPos{
			leftovers = rectsToPack[i:]
			break
		}

		(cast(^[2]u16)rect.indexBufferPagePosPtr)^ = drawPos
		(cast(^u8)(rect.indexBufferPagePosPtr + size_of([2]u16)))^ = pageInd

		rowByteSize := uintptr(width)*4
		for y in 0 ..<uintptr(height){
			mem.copy(
				rawptr(pixelsBase + uintptr(drawPos.x)*4 + (uintptr(drawPos.y) + y)*pagePitch),
				rawptr(&rect.imageData[y*rowByteSize]),
				int(rowByteSize)
			)
		}

		drawPos.x += width
		largestRowHeight = math.max(largestRowHeight, height)
	}

	return leftovers
}

//Walks one sprite's index data, collecting a pack rect for each non-empty frame. The u32 slot after each frame's
//size holds the frame's offset into the image buffer, and gets overwritten with page coords + index by packing.
sprite_index_rects_collect :: proc(r:uintptr, rEnd:uintptr, imageBase:uintptr, packRects:^[dynamic]SpritePackRect){
	r := r
	for r < rEnd{
		nameLen := read(&r, u8)
		r += uintptr(nameLen) // name
		r += size_of([2]u16) + size_of([2]i16) // canvasSize + origin

		maskKind := read(&r, u8)
		if maskKind != 0{
			r += size_of([2]u16) + size_of([2]i16) // maskSize + maskOrigin
			if maskKind == 2{
				precCount := read(&r, u32)
				r += uintptr(precCount) * size_of([2]i16)
			}
		}

		frameCount := read(&r, u16)
		for _ in 0..<frameCount{
			r += size_of(u16) + size_of([2]i16) // duration + trimOff
			size := read(&r, [2]u16)

			posPtr := r
			imageOff := read(&r, u32)

			if size.x > 0 && size.y > 0{
				append(packRects, SpritePackRect{
					cast([^]u8)(imageBase + uintptr(imageOff)),
					posPtr,
					size
				})
			}

			r += size_of(u8) // pageInd
		}
	}
}

//Packs just the changed sprites into a single small page and writes a reload request for the running game.
//The index and uncompressed image data are stored directly in the request file.
sprites_hot_request_write :: proc(hotFiles:[]SpriteFileEntry){
	//parse the changed files. This duplicates a sliver of the main rebuild's parse work, but gets the request out asap
	task := SpritesParseTask{spriteFiles=hotFiles, alloc=context.temp_allocator}
	task.namesToAdd = make([dynamic][2]string, context.temp_allocator)
	bytes.buffer_init_allocator(&task.out, 0, 64*len(hotFiles), task.alloc)
	bytes.buffer_init_allocator(&task.imageOut, 0, 128*mem.Kilobyte*len(hotFiles), task.alloc)
	sprites_parse_batch_proc(thread.Task{data=&task, allocator=task.alloc})

	if len(task.out.buf) == 0 do return

	write_v(&task.out, u8(0)) //parse stopper, the main code reads sprite entries until it hits a 0 name length

	packRects := make([dynamic]SpritePackRect, 0, len(hotFiles)*2)
	for &entry in task.spriteFiles{
		if entry.indexDataSize == 0 do continue

		imageBase := uintptr(raw_data(entry.imageBuffer.buf)) + entry.imageDataOff
		r := uintptr(raw_data(task.out.buf)) + entry.indexDataOff

		sprite_index_rects_collect(r, r + entry.indexDataSize, imageBase, &packRects)
	}

	slice.sort_by(packRects[:], proc(a, b:SpritePackRect) -> bool{
		return a.size.y < b.size.y
	})

	//size the page and pack. Everything must fit on a single page
	area:f32
	minSize:u16
	for rect in packRects{
		area += f32(rect.size.x)*f32(rect.size.y)
		minSize = max(rect.size.x, rect.size.y, minSize)
	}

	//maxDim + sqrt(area) is a guaranteed-fit page size for this packer: each row's area is at least
	//(pageSize - maxDim) * prevRowHeight thanks to the height sort, so the total height is bounded by
	//maxDim + area/(pageSize - maxDim), which fits whenever pageSize >= maxDim + sqrt(area)
	pageSize := next_power_of_two(int(minSize) + int(math.sqrt(area)) + 1)
	if pageSize > SPRITE_PAGE_SIZE{
		printf("WARNING: Hot-reloaded sprites can't fit on a single page, skipping hot reload.")
		return
	}

	pixels := make([]u8, int(pageSize)*int(pageSize)*4, context.temp_allocator)
	if len(sprite_page_pack(packRects[:], pageSize, uintptr(raw_data(pixels)), 0)) != 0{
		printf("WARNING: Failed to pack sprites onto a single page, skipping hot reload.") //should be impossible
		return
	}

	request:bytes.Buffer
	bytes.buffer_init_allocator(&request, 0, 8 + len(task.out.buf) + len(pixels), context.temp_allocator)
	write_v(&request, u32(pageSize))
	write_v(&request, u32(len(task.out.buf)))
	bytes.buffer_write(&request, task.out.buf[:])
	bytes.buffer_write(&request, pixels)
	reload_request_write("sprite", bytes.buffer_to_bytes(&request))
}

sprites_pack_group_proc :: proc(task:thread.Task){
	context.allocator = task.allocator
	context.temp_allocator = task.allocator

	data := cast(^PackGroupTask)task.data
	//printf("Packing texture group: %s", data.groupName)

	imagePath, _ := filepath.join({paths.build_win64, "texture_groups", fmt.aprintf("%s.texgroup", data.groupName)})
	if os.exists(imagePath) do os.remove(imagePath)

	if config.previewTexturePages{
		pagesPath, _ := filepath.join({data.pagesDir, data.groupName})
		for i := 0; true; i += 1{
			pagePath := fmt.aprintf("%s__%d.qoi", pagesPath, i)
			if !os.exists(pagePath) do break
			os.remove(pagePath)
		}
	}

	// Copy each file's index data into a single output buffer, collecting pack rects along the way
	packRects := make([dynamic]SpritePackRect, 0, len(data.sprites)*2)

	totalIndexSize :uintptr= 0
	totalImageSize :uintptr= 0
	for &entry in data.sprites{
		totalIndexSize += entry.indexDataSize
		totalImageSize += entry.imageDataSize
	}

	indexBuffer := &data.indexOut
	bytes.buffer_init_allocator(indexBuffer, 0, int(totalIndexSize) + 128)

	pageSizes:=make([dynamic]int, context.temp_allocator)

	imageBuffer:bytes.Buffer
	bytes.buffer_init_allocator(&imageBuffer, 0, int(f32(totalImageSize)*0.06))

	for &entry in data.sprites{
		if entry.indexDataSize == 0 do continue

		imageBase := uintptr(raw_data(entry.imageBuffer.buf)) + entry.imageDataOff

		r := buffer_head(indexBuffer^)
		bytes.buffer_write(indexBuffer, entry.indexBuffer.buf[entry.indexDataOff:][:entry.indexDataSize])

		sprite_index_rects_collect(r, r + entry.indexDataSize, imageBase, &packRects)
	}

	if len(packRects) == 0{
		if len(indexBuffer.buf) > 0{
			write_v(indexBuffer, u8(0))
			write_v(indexBuffer, u16(0))
		}
		return
	}

	slice.sort_by(packRects[:], proc(a, b:SpritePackRect) -> bool{
		return a.size.y < b.size.y
	})

	packCumulativeArea:f32 = 0
	packMinSize:u16 = 0
	pageInd:u8= 0
	PAGE_MAX_AREA :: SPRITE_PAGE_SIZE * SPRITE_PAGE_SIZE - 1

	leftovers := packRects[:]
	for len(leftovers) > 0{

		//estimate remaining area
		for leftover in leftovers{
			packCumulativeArea += f32(leftover.size.x)*f32(leftover.size.y)
			packMinSize = max(leftover.size.x, leftover.size.y, packMinSize)
			if packCumulativeArea > PAGE_MAX_AREA{
				packCumulativeArea = 0
				packMinSize = SPRITE_PAGE_SIZE - 1
				break
			}
		}

		pageSize := next_power_of_two(max(int(packMinSize), int(math.sqrt(packCumulativeArea))))
		append(&pageSizes, pageSize)

		pagePixels := make([]u8, pageSize*pageSize*4)

		leftovers = sprite_page_pack(leftovers, pageSize, uintptr(raw_data(pagePixels)), pageInd)

		imageStartOff := uintptr(len(imageBuffer.buf))
		write_v(&imageBuffer, u64(0))
		qoi_write(pagePixels, pageSize, pageSize, &imageBuffer)
		qoiSizePtr := uintptr(raw_data(imageBuffer.buf)) + imageStartOff
		qoiSize := u64(buffer_head(imageBuffer) - qoiSizePtr - 8)
		(cast(^u64)qoiSizePtr)^ = qoiSize

		if config.previewTexturePages{
			_ = os.write_entire_file(
				filepath.join({data.pagesDir, fmt.tprintf("%s__%d.qoi", data.groupName, pageInd)}, context.temp_allocator) or_else "", 
				slice.bytes_from_ptr(rawptr(qoiSizePtr+8), int(qoiSize))
			)
		}

		pageInd += 1
		packCumulativeArea = 0
		packMinSize = 0
	}

	write_v(indexBuffer, u8(0))
	for s in pageSizes do write_v(indexBuffer, u16(s))

	_ = os.write_entire_file(imagePath, imageBuffer.buf[:])
}


//Returns whether the ids file actually changed (additions, or lines blanked by ids_remove)
sprite_ids_write :: proc(idConfig:IDConfig, state:^IDFileState, namesToAdd:[][2]string) -> (changed:bool){
	newDeclLines := make([dynamic]string, context.temp_allocator)
	newAssignLines := make([dynamic]string, context.temp_allocator)

	for strs in namesToAdd{
		name := strs[0]
		append(&newDeclLines, fmt.aprintf("%s%s", name, idConfig.declarationPattern))
		append(&newAssignLines, fmt.aprintf(idConfig.assignmentFormat, name, name, name, strs[1]))
	}

	declInsert := find_line_index(state.lines[:], "//</declarations>")
	assignInsert := find_line_index(state.lines[:], "//</assignments>")

	if declInsert < 0 || assignInsert < 0{
		printf("Could not find marker comments in %s", idConfig.path)
		return
	}

	result := make([dynamic]string, 0, len(state.lines) + len(newDeclLines)*2)
	for i in 0..<declInsert{
		append(&result, state.lines[i])
	}
	for line in newDeclLines{
		append(&result, line)
	}
	for i in declInsert..<assignInsert{
		append(&result, state.lines[i])
	}
	for line in newAssignLines{
		append(&result, line)
	}
	for i in assignInsert..<len(state.lines){
		append(&result, state.lines[i])
	}

	output := strings.join(result[:], "\r\n", context.temp_allocator)
	if output == state.contents do return false //nothing changed, don't touch the file

	_ = os.write_entire_file(idConfig.path, transmute([]u8)output)
	return true
}

pipeline_sprites_run :: proc(pipeline:^Pipeline, fullRebuild:bool){
	spritesDir, _ := filepath.join({paths.project, "sprites"})
	pagesDir, _   := filepath.join({paths.build, "texture_page_previews"})
	idsPath, _    := filepath.join({paths.massimodin, "spriteIDs.g.odin"})
	cachedPathsFile, _ := filepath.join({paths.build, "cachedSpritePaths.txt"})

	idConfig := IDConfig{
		path              = idsPath,
		declarationPattern = " :^Sprite,",
		defaultTemplate   = SPRITE_IDS_DEFAULT,
		assignmentFormat  = "sp.%s = &sprites._sprites_map[\"%s\"]; _sprite_add_to_file_tree(sp.%s, `%s`)",
	}
	idState := ids_read(idConfig)
	sprite_existing_ids = &idState.existingIds

	idsCache := fullRebuild ? make(map[string][]string) : sprite_ids_cache_read(cachedPathsFile)

	// Collect sprites and group by texture group

	texGroups := make([dynamic]TexGroup)
	spriteFiles := make([dynamic]SpriteFileEntry)

	if fullRebuild{
		currentGroup := ""
		for &file in pipeline.pendingFiles{
			stem, relativeDir, texGroup := sprite_path_info(spritesDir, file.path)

			if texGroup != currentGroup{
				if len(texGroups) > 0 do texGroups[len(texGroups) - 1].count = len(spriteFiles) - texGroups[len(texGroups) - 1].startIndex
				append(&texGroups, TexGroup{name=texGroup, startIndex=len(spriteFiles)})
				currentGroup = texGroup
			}

			append(&spriteFiles, SpriteFileEntry{
				fullpath=file.path,
				relativeDir=relativeDir,
				stem=stem,
				groupIndex=len(texGroups) - 1,
				addNames=true
			})
		}
		if len(texGroups) > 0 do texGroups[len(texGroups) - 1].count = len(spriteFiles) - texGroups[len(texGroups) - 1].startIndex
	}
	else{
		pendingStems := make(map[string]bool, len(pipeline.pendingFiles), context.temp_allocator)
		dirtyGroups := make(map[string]bool, context.temp_allocator)
		hotFiles := make([dynamic]SpriteFileEntry, 0, len(pipeline.pendingFiles), context.temp_allocator)

		for &file in pipeline.pendingFiles{
			stem, relativeDir, texGroup := sprite_path_info(spritesDir, file.path)
			dirtyGroups[texGroup] = true

			known := stem in idsCache
			if file.exists{
				pendingStems[stem] = true
				//hot reload only supports overwriting existing sprites, never adding new ones
				if known do append(&hotFiles, SpriteFileEntry{fullpath=file.path, relativeDir=relativeDir, stem=stem})
			}
			else if known{
				//deleted file: remove its ids now. Modified files are diffed after parsing, when their new ids are known
				for id in idsCache[stem] do ids_remove(&idState, id)
				delete_key(&idsCache, stem)
			}
		}

		//write the hot reload request before the full group rebuild below, to get changes in-game asap
		if len(hotFiles) > 0 && process_running(paths.exe){
			sprites_hot_request_write(hotFiles[:])
		}

		// Re-scan each dirty group's directory
		scannedFiles := make([dynamic]string, context.temp_allocator)
		for group in dirtyGroups{
			groupIndex := len(texGroups)
			startIndex := len(spriteFiles)

			clear(&scannedFiles)
			if group == "_extra" do sprites_scan_dir(spritesDir, &scannedFiles, false)
			else{
				groupDir,_ := filepath.join({spritesDir, group})
				sprites_scan_dir(groupDir, &scannedFiles)
			}

			for path in scannedFiles{
				stem, relativeDir, _ := sprite_path_info(spritesDir, path)
				append(&spriteFiles, SpriteFileEntry{
					fullpath=path,
					relativeDir=relativeDir,
					stem=stem,
					groupIndex=groupIndex,
					addNames = stem in pendingStems
				})
			}

			append(&texGroups, TexGroup{name=group, startIndex=startIndex, count=len(spriteFiles) - startIndex})
		}
	}

	spriteFileCount := len(spriteFiles)
	if spriteFileCount == 0{
		sprite_ids_cache_write(cachedPathsFile, idsCache)
		printf("SPRITES BUILD DONE! (no sprites)")
		return
	}


	// Batch parse file data
	print("Parsing sprite files...")
	threadCount := os.get_processor_core_count()

	targetBatchCount := min(threadCount*4, spriteFileCount) //use more batches than threads to help spread work across potentially uneven batches  
	batchSize := spriteFileCount/targetBatchCount
	batchCount := (spriteFileCount + batchSize - 1)/batchSize //int ceil

	parsePoolAlloc := allocator_make()
	parsePool:thread.Pool
	thread.pool_init(&parsePool, parsePoolAlloc, threadCount)
	thread.pool_start(&parsePool)
	defer{
		thread.pool_destroy(&parsePool)
		allocator_delete(parsePoolAlloc)
	}

	parseTasks := make([dynamic]SpritesParseTask, batchCount)
	defer{
		for task in parseTasks do allocator_delete(task.alloc)
	}

	for i in 0..<batchCount{
		start := i*batchSize
		end := min((i+1)*batchSize, spriteFileCount)

		parseTasks[i] = SpritesParseTask{
			spriteFiles=spriteFiles[start:end],
			alloc=allocator_make()
		}
		parseTasks[i].namesToAdd = make([dynamic][2]string, 0, (end-start)*2, parseTasks[i].alloc)
		bytes.buffer_init_allocator(&parseTasks[i].out, 0, 64*(end-start), parseTasks[i].alloc)
		bytes.buffer_init_allocator(&parseTasks[i].imageOut, 0, 128*mem.Kilobyte*(end-start), parseTasks[i].alloc)
		thread.pool_add_task(&parsePool, parseTasks[i].alloc, sprites_parse_batch_proc, &parseTasks[i])
	}

	thread.pool_finish(&parsePool)

	// Pack groups
	print("Sprite files parsed, packing...")
	packPoolAlloc := allocator_make()
	packPool:thread.Pool
	thread.pool_init(&packPool, packPoolAlloc, threadCount)
	thread.pool_start(&packPool)
	defer{
		thread.pool_destroy(&packPool)
		allocator_delete(packPoolAlloc)
	}

	packTasks := make([dynamic]PackGroupTask, len(texGroups))
	defer{
		for task in packTasks do allocator_delete(task.alloc)
	}

	for &group,i in texGroups{
		task := &packTasks[i]
		task^ = PackGroupTask{
			sprites   = spriteFiles[group.startIndex:][:group.count],
			groupName = group.name,
			pagesDir  = pagesDir,
			alloc = allocator_make()
		}
		thread.pool_add_task(&packPool, task.alloc, sprites_pack_group_proc, task)
	}

	// Write IDs on main thread while pack tasks run

	//Collect the ids to add. On incremental runs, diff each changed file's parsed ids against the cache and only
	//touch the id state when a file's ids actually changed. Most edits leave them identical, and an untouched ids
	//file means no code rebuild gets triggered
	namesToAdd := make([dynamic][2]string)
	if fullRebuild{
		for &task in parseTasks do append_elems(&namesToAdd, args=task.namesToAdd[:])
	}
	else{
		for &task in parseTasks{
			for &entry in task.spriteFiles{
				if !entry.addNames do continue

				newNames := task.namesToAdd[entry.namesStart:][:entry.namesCount]
				oldIds := idsCache[entry.stem]

				idsUnchanged := len(oldIds) == len(newNames)
				if idsUnchanged{
					for id, i in oldIds{
						if id != newNames[i][0]{
							idsUnchanged = false
							break
						}
					}
				}
				if idsUnchanged do continue

				for id in oldIds do ids_remove(&idState, id)
				append(&namesToAdd, ..newNames)
			}
		}
	}
	
	if sprite_ids_write(idConfig, &idState, namesToAdd[:]) do pipeline.codegenDirty = true

	// Update and write sprite cache
	for &task in parseTasks{
		for &entry in task.spriteFiles{
			if entry.namesCount == 0 do continue
			names := task.namesToAdd[entry.namesStart:][:entry.namesCount]
			cacheIds := make([]string, entry.namesCount, context.temp_allocator)
			for n, i in names do cacheIds[i] = n[0]
			idsCache[entry.stem] = cacheIds
		}
	}
	sprite_ids_cache_write(cachedPathsFile, idsCache)

	//get dirty groups
	dirtyGroups := make([]string, len(packTasks))
	for t, i in packTasks do dirtyGroups[i] = t.groupName
	
	thread.pool_finish(&packPool)

	//preserve existing data for non-dirty groups when doing an incremental build
	if !fullRebuild{ 
		indexPath, _ := filepath.join({paths.build_win64, "texture_groups/.index"})
		oldIndex,_ := os.read_entire_file(indexPath, context.temp_allocator)
		r := uintptr(raw_data(oldIndex))
		oldCount := read(&r, u8)
		for _ in 0..<oldCount{
			nameLen := read(&r, u16)
			dataLen := read(&r, u64)
			name := strings.string_from_ptr(cast(^u8)r, int(nameLen))
			r += uintptr(nameLen)
			data := slice.bytes_from_ptr(rawptr(r), int(dataLen))
			r += uintptr(dataLen)
			
			if slice.contains(dirtyGroups, name) do continue
			append(&packTasks, PackGroupTask{
				groupName=name,
				indexOut=bytes.Buffer{buf=slice_to_dynamic(data, mem.panic_allocator())}
			})
		}
	}

	//write out index file
	indexSize := 0
	for &task in packTasks do indexSize += len(task.indexOut.buf)

	indexOut:bytes.Buffer
	bytes.buffer_init_allocator(&indexOut, 0, indexSize + 2048) //extra space for name and size headers

	write_v(&indexOut, u8(len(packTasks)))
	
	for &task in packTasks{
		nameBytes := transmute([]u8)task.groupName
		data := task.indexOut.buf[:]

		write_v(&indexOut, u16(len(nameBytes)))
		write_v(&indexOut, u64(len(data)))
		bytes.buffer_write(&indexOut, nameBytes)
		bytes.buffer_write(&indexOut, data)
	}

	indexPath, _ := filepath.join({paths.build_win64, "texture_groups/.index"})
	if os.exists(indexPath) do os.remove(indexPath)
	_ = os.write_entire_file(indexPath, indexOut.buf[:])

	printf("SPRITES BUILD DONE!")
}
