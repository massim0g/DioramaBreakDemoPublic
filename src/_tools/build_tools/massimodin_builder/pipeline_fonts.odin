package massimodin_builder

import "core:os"
import "core:strings"
import "core:path/filepath"
import "core:encoding/json"
import "core:bytes"
import "core:math"
import "core:fmt"

import "../../../sdl2"
import "../../../sdl2/ttf"

FONT_PAGE_SIZE :: 4096
FONT_IDS_DEFAULT :: `package massimodin

FontIDs :: struct{
//<declarations>
//</declarations>
}
fo:^FontIDs

_reload_font_ids :: proc(){
//<assignments>
//</assignments>
}`

FontPage :: struct{
	buf:bytes.Buffer,
	surf:^sdl2.Surface,
	drawPos:[2]i32,
	rowH:i32,
}

//index layout per font: u8 name length, name, u32 rune count, then 12 bytes per rune (see _font_page_index_load)
font_index_ids_parse :: proc(data:[]u8) -> []string{
	ids := make([dynamic]string, context.temp_allocator)
	pos := 0
	for pos + 1 <= len(data){
		nameLen := int(data[pos])
		pos += 1
		if pos + nameLen + 4 > len(data) do break
		append(&ids, string(data[pos:pos + nameLen]))
		pos += nameLen
		runeCount := int((cast(^u32)&data[pos])^)
		pos += 4 + runeCount * 12
	}
	return ids[:]
}

pipeline_fonts_run :: proc(pipeline:^Pipeline, fullRebuild:bool){
	idsPath, _    := filepath.join({paths.massimodin, "fontIDs.g.odin"})
	fontsDir, _   := filepath.join({paths.project, "fonts"})
	pagesDir, _   := filepath.join({paths.build, "font_pages"})
	indexesDir, _ := filepath.join({paths.build, "font_page_indexes"})

	sdl2.Init(sdl2.INIT_VIDEO)
	ttf.Init()

	idConfig := IDConfig{
		path              = idsPath,
		declarationPattern = " :^Font,",
		defaultTemplate   = FONT_IDS_DEFAULT,
		assignmentFormat  = `fo.%s = &fonts._fonts_map["%s"]`,
	}
	idState := ids_read(idConfig)

	//repack on deletions too, so removed fonts disappear from the rebuilt pages
	if !fullRebuild{
		for &file in pipeline.pendingFiles{
			if !file.exists{
				if strings.has_suffix(file.path, ".index"){
					//prebaked page removed: recover its ids from the previously built index, then drop the built pair
					pageName := filepath.stem(filepath.base(file.path))
					builtPagePath, _ := filepath.join({pagesDir, strings.concatenate({pageName, ".qoi"})})
					builtIndexPath, _ := filepath.join({indexesDir, strings.concatenate({pageName, ".index"})})
					if indexData, readErr := os.read_entire_file(builtIndexPath, context.temp_allocator); readErr == nil{
						for id in font_index_ids_parse(indexData){
							ids_remove(&idState, id)
							delete_key(&idState.existingIds, id)
						}
					}
					_ = os.remove(builtPagePath)
					_ = os.remove(builtIndexPath)
					continue
				}
	
				//font ids are "<stem><variant>__<size>", remove every size of every variant
				fontName := filepath.stem(filepath.base(file.path))
				for variant in ([?]string{"__", "Bold__", "Italic__", "BoldItalic__"}){
					ids_remove_matching(&idState, strings.concatenate({fontName, variant}, context.temp_allocator))
				}
			}
		}
	}

	namesToAdd := make([dynamic]string)

	pagesData := make(map[string]FontPage)
	prebakedPages := make([dynamic]string)

	dirHandle, err := os.open(fontsDir)
	if err != nil{
		print("ERROR: Could not open fonts directory!")
		pipeline_status_set(pipeline, .failed)
		return
	}
	dirInfo, err2 := os.read_all_directory(dirHandle, context.temp_allocator)
	os.close(dirHandle)
	if err2 != nil{
		print("ERROR: Could not read fonts directory!")
		pipeline_status_set(pipeline, .failed)
		return
	}

	for fi in dirInfo{
		//prebaked pages: an already built .qoi/.index pair produced by this pipeline, copied to the build folder as-is. Mainly used to avoid licensing issues in the public repo.
		if strings.has_suffix(fi.name, ".index"){
			pageName := filepath.stem(fi.name)
			if !fullRebuild do printf("Copying prebaked font page: %s", pageName)

			srcPagePath, _ := strings.replace(fi.fullpath, ".index", ".qoi", 1)
			if !os.exists(srcPagePath){
				printf("WARNING: Prebaked font index '%s' has no matching .qoi, skipping page!", fi.fullpath)
				continue
			}

			indexData, indexErr := os.read_entire_file(fi.fullpath, context.temp_allocator)
			if indexErr != nil{
				printf("WARNING: Could not read prebaked font index '%s', skipping page!", fi.fullpath)
				continue
			}

			outPagePath, _ := filepath.join({pagesDir, strings.concatenate({pageName, ".qoi"})})
			outIndexPath, _ := filepath.join({indexesDir, strings.concatenate({pageName, ".index"})})
			if os.copy_file(outPagePath, srcPagePath) != nil{
				printf("WARNING: Could not copy prebaked font page '%s', skipping page!", pageName)
				continue
			}

			for id in font_index_ids_parse(indexData){
				if !(id in idState.existingIds){
					append(&namesToAdd, id)
				}
			}

			_ = os.write_entire_file(outIndexPath, indexData)
			append(&prebakedPages, pageName)
			continue
		}

		if !strings.has_suffix(fi.name, ".json") do continue

		fontName := filepath.stem(fi.name)
		
		if !fullRebuild do printf("Exporting font: %s", fontName)

		extReplace :: proc(path:string, newExt:string) -> string{
			out, _ := strings.replace(path, ".json", newExt, 1)
			return out
		}
		ttfPaths := []string{
			extReplace(fi.fullpath, ".ttf"),
			extReplace(fi.fullpath, "Bold.ttf"),
			extReplace(fi.fullpath, "Italic.ttf"),
			extReplace(fi.fullpath, "BoldItalic.ttf"),
		}

		ranges := make([dynamic][2]i32)
		append(&ranges, [2]i32{33, 126})

		sizes := make([dynamic]i32)
		append(&sizes, 12)

		pageName := "_default"

		jsonDataBytes, readErr := os.read_entire_file(fi.fullpath, context.temp_allocator)
		if readErr != nil{
			printf("ERROR: Could not read font config '%s', skipping font!", fi.fullpath)
			continue
		}
		jsonVal, jsErr := json.parse(jsonDataBytes)
		if jsErr != nil{
			printf("ERROR: Could not parse font config '%s', skipping font!", fi.fullpath)
			continue
		}
		jsonObj, isObj := jsonVal.(json.Object)
		if !isObj{
			printf("ERROR: Font config '%s' is not a json object, skipping font!", fi.fullpath)
			continue
		}
		if jsSizes, found := jsonObj["sizes"].(json.Array); found{
			clear(&sizes)
			for size in jsSizes{
				append(&sizes, i32(size.(json.Float)))
			}
		}
		if jsRanges, found := jsonObj["ranges"].(json.Array); found{
			for r in jsRanges{
				arr := r.(json.Array)
				append(&ranges, [2]i32{i32(arr[0].(json.Float)), i32(arr[1].(json.Float))})
			}
		}
		if jsPage, found := jsonObj["page"].(json.String); found{
			pageName = jsPage
		}

		if pageName not_in pagesData{
			newPage := FontPage{}
			newPage.surf = sdl2.CreateRGBSurfaceWithFormat(
				0, FONT_PAGE_SIZE, FONT_PAGE_SIZE, 32,
				u32(sdl2.PixelFormatEnum.ABGR8888),
			)
			bytes.buffer_init_allocator(&newPage.buf, 0, 4096)
			pagesData[pageName] = newPage
		}
		page := &pagesData[pageName]

		append(&ranges, [2]i32{32, 32}) //space comes at the end to not cause weird line-break issues

		outRunes := make([dynamic]rune)
		for r in ranges{
			for i in r[0] ..= r[1]{
				append(&outRunes, rune(i))
			}
		}

		for ttfPath in ttfPaths{
			if !os.exists(ttfPath) do continue
			stem := filepath.stem(ttfPath)
			cPath := strings.clone_to_cstring(ttfPath)

			for size in sizes{
				fontId := fmt.aprintf("%s__%d", stem, size)
				if !(fontId in idState.existingIds){
					append(&namesToAdd, fontId)
				}

				write_v(&page.buf, u8(len(fontId)))
				bytes.buffer_write_string(&page.buf, fontId)
				write_v(&page.buf, u32(len(outRunes)))

				loadedFont := ttf.OpenFont(cPath, size)
				ttf.SetFontKerning(loadedFont, false)
				ttf.SetFontHinting(loadedFont, .MONO)
				defer ttf.CloseFont(loadedFont)

				for r in outRunes{
					charSurf := ttf.RenderGlyph32_Solid(loadedFont, r, sdl2.Color{255, 255, 255, 255})
					if charSurf == nil{
						write_v(&page.buf, r)
						write_v(&page.buf, u16(0))
						write_v(&page.buf, u16(0))
						write_v(&page.buf, u16(0))
						write_v(&page.buf, u16(0))
						continue
					}
					defer sdl2.FreeSurface(charSurf)

					if page.drawPos.x + charSurf.w > FONT_PAGE_SIZE{
						page.drawPos.x = 0
						page.drawPos.y += page.rowH
						page.rowH = 0
						if page.drawPos.y + charSurf.h > FONT_PAGE_SIZE{
							printf("WARNING: Fonts don't fit on page '%s'! Use a different grouping!", pageName) //mostly a failsafe. If this becomes onerous, implement multi-page groups like with sprites.
						}
					}

					drawRect := sdl2.Rect{
						page.drawPos.x,
						page.drawPos.y,
						charSurf.w,
						charSurf.h,
					}

					write_v(&page.buf, r)
					write_v(&page.buf, u16(drawRect.x))
					write_v(&page.buf, u16(drawRect.y))
					write_v(&page.buf, u16(drawRect.w))
					write_v(&page.buf, u16(drawRect.h))

					sdl2.BlitSurface(charSurf, nil, page.surf, &drawRect)

					page.rowH = math.max(drawRect.h, page.rowH)
					page.drawPos.x += drawRect.w
				}
			}
		}
	}

	for pageName, page in pagesData{
		for p in prebakedPages{
			if p==pageName{
				printf("ERROR: Font page '%s' is both generated and prebaked!", pageName)
				pipeline_status_set(pipeline, .failed)
				return
			}
		}

		pagePath, _ := filepath.join({pagesDir, strings.concatenate({pageName, ".qoi"})})
		indexPath, _ := filepath.join({indexesDir, strings.concatenate({pageName, ".index"})})

		pagePixels := (cast([^]u8)page.surf.pixels)[:int(page.surf.w)*int(page.surf.h)*4]
		qoi_write(pagePixels, int(page.surf.w), int(page.surf.h), pagePath)
		_ = os.write_entire_file(indexPath, page.buf.buf[:])

		//hot reload only supports overwriting existing assets: skip if this run added any new font id
		if !fullRebuild && len(namesToAdd) == 0 && process_running(paths.exe){
			reload_request_write("font", transmute([]u8)strings.join({pagePath, indexPath}, "\n"))
		}

		sdl2.FreeSurface(page.surf)
	}

	if ids_write(idConfig, &idState, namesToAdd[:]) do pipeline.codegenDirty = true
	print("FONTS BUILD DONE!")
}
