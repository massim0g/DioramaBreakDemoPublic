package massimodin //@nested-tags:engine/asset_loading
/*
System for unpacking small assets that get loaded into RAM at game start.
NOT INTENDED for assets that are potentially too big, and are loaded from disk after the game has started, such as audio.
*/

import "../sdl2"
import "core:image"
import "core:image/qoi"
import "core:os"
import "core:path/filepath"
import "core:strings"
import "core:encoding/json"
import "core:c"
import "core:slice"
import "core:reflect"
import "base:runtime"
import gl "vendor:OpenGL"
import "core:mem"
import fm "../fmod/studio"

AssetSystem :: struct{
	allocator:Allocator,
	pack_file_path:string,
}
assets:^AssetSystem

_asset_system_init :: proc(){
	assets = new(AssetSystem)

	//initialize the asset allocator such that additional memory block allocations should not be necessary
	assetSize:i64
	when ON_SWITCH{
		assetSize = MEGABYTE*127 //manually enter the size of the assets file
	}
	else{
		assets.pack_file_path,_ = filepath.join([]string{executable_directory, "assets.mopak"})
		assetFileInfo, statErr := os.stat(assets.pack_file_path, context.temp_allocator)
		assetSize = statErr == nil ? assetFileInfo.size : 0
		assert(assetSize > 0, "Error retrieving size of asset file!")
	}

	alloc := allocator_make(uint(next_power_of_2(int(assetSize*2))), .Growing) //double initial size as buffer
	
	assets.allocator = alloc
}

@(disabled=!DEBUG)
_asset_add_to_file_tree :: proc(asset:FileTreeNode, parentPath:string, topFolder:^FileTreeFolder){
	curNode := topFolder

	if parentPath != ""{
		splitPath := string_split(parentPath, `/`)
		for dir in splitPath{
			folderExists:=false
			for node in curNode.contents{
				if folder, ok := node.(^FileTreeFolder); ok{
					if folder.name == dir{
						folderExists = true
						curNode = folder
						break
					}
				}
			}
	
			if !folderExists{
				newFolder := file_tree_folder_new(dir, curNode)
				append(&curNode.contents, newFolder)
				curNode = newFolder
			}
		}
	}

	for node in curNode.contents{
		switch n in node{
			case ^Stage: if n.name == asset.(^Stage).name do return
			case ^Sprite: if n.name == asset.(^Sprite).name do return
			case ^FileTreeFolder: //do nothing
		}
	}
	append(&curNode.contents, asset)
}

//AUDIO
	/*
	Audio loading right now is very brute. Just load everything on a separate thread at startup.
	If it takes up too much ram or starts dominating init time, it may become necessary down the line to split things up more and do loading and unloading
	*/
	AUDIO_BANKS_PERMANENT :: []string{
		"Master.strings",
		"Master",
		"SFX",
		"Music"
	}

	_audio_banks_preload_all :: proc(){
		for bank in AUDIO_BANKS_PERMANENT do audio_bank_preload(bank)
		fm.System_Update(audio._system) //submits the queued nonblocking loads so they start now, not at the block
	}

	audio_bank_preload :: proc(name:string){
		trace(format("Audio Bank '%s' Load ", name))
		fullName := strings.concatenate({name, ".bank"}, context.temp_allocator)

		bankFilePathString:string
		bankFilePath:cstring
		when(ON_SWITCH){
			bankFilePathString = strings.concatenate({"Contents:/", fullName}, context.temp_allocator)
		}
		else{
			bankFilePathString, _ = filepath.join({executable_directory, fullName}, context.temp_allocator)
			assertf(os.exists(bankFilePathString), "Bank file for bank '%s' was not found!", name)
		}
		bankFilePath = strings.clone_to_cstring(bankFilePathString, context.temp_allocator)
		
		if(name in audio._banks_map) do audio_bank_free(name)

		newBankPtr:^fm.BANK
		result := fm.System_LoadBankFile(audio._system, bankFilePath, fm.LOAD_BANK_NONBLOCKING, &newBankPtr)
		assertf(result == .OK, "Failed to preload bank '%s' (FMOD result: %v)", name, result)

		strmap_set(&audio._banks_map, name, newBankPtr)
	}

	//blocks on bank file load, starts preloading that bank's samples
	audio_bank_load_block :: proc(name:string){
		trace("audio bank load block")
		bank := audio._banks_map[name]

		state:fm.LOADING_STATE
		for{
			fm.System_Update(audio._system) //nonblocking loads only progress when queued commands get submitted
			fm.Bank_GetLoadingState(bank, &state)
			done:=false
			switch state{
				case .LOADING_STATE_LOADING: //do nothing
				case .LOADING_STATE_LOADED: done = true
				case .LOADING_STATE_UNLOADED: panicf("Tried to block on audio bank '%s' that was never preloaded!", name) //audio_bank_preload(name)
				case .LOADING_STATE_UNLOADING: panic("Current engine does not support unloading audio banks!")
				case .LOADING_STATE_ERROR: panicf("Error loading audio bank '%s'!", name)
			}
			if done do break
			thread_yield()
		}

		fm.Bank_LoadSampleData(bank)
		fm.System_Update(audio._system) //same deal, update here to trigger the async load

		newEventsCount:i32
		fm.Bank_GetEventCount(bank, &newEventsCount)
		if(newEventsCount > 0){
			newEvents := make([dynamic]^fm.EVENTDESCRIPTION, newEventsCount, context.temp_allocator)
			fm.Bank_GetEventList(bank, &(newEvents[0]), newEventsCount, &newEventsCount)
			
			pathBuf:[256]u8
			retrieved:i32
			for ed in newEvents{
				fm.EventDescription_GetPath(ed, &pathBuf[0], i32(len(pathBuf)), &retrieved)
				if retrieved <= 0 do continue
				strmap_set(&audio._events_map, filepath.stem(string(pathBuf[:retrieved-1])), ed)
			}
		}
	}

	//Reloads audio ids and blocks execution until all audio sample data has been loaded
	audio_bank_sample_load_block :: proc(){
		trace("audio samples load block")
		_reload_audioEvent_ids()
		print("Waiting for audio load...")
		state:fm.LOADING_STATE
		for name, bank in audio._banks_map{
			for{
				fm.Bank_GetSampleLoadingState(bank, &state)
				if state == .LOADING_STATE_LOADED do break
				assertf(state != .LOADING_STATE_ERROR, "Error loading sample data for bank '%s'!", name)
				thread_yield()
			}
		}
	}

	audio_bank_free :: proc(name:string){
		bank := audio._banks_map[name]

		eventsCount:i32
		fm.Bank_GetEventCount(bank, &eventsCount)
		if(eventsCount > 0){
			bankEvents := make([dynamic]^fm.EVENTDESCRIPTION, eventsCount, context.temp_allocator)
			fm.Bank_GetEventList(bank, &(bankEvents[0]), eventsCount, &eventsCount)

			pathBuf:[256]u8
			retrieved:i32
			for ed in bankEvents{
				fm.EventDescription_GetPath(ed, &pathBuf[0], i32(len(pathBuf)), &retrieved)
				if retrieved <= 0 do continue
				strmap_delete_key(&audio._events_map, filepath.stem(string(pathBuf[:retrieved-1])))
			}
			_reload_audioEvent_ids()
		}

		fm.Bank_UnloadSampleData(bank)
		fm.System_FlushSampleLoading(audio._system) //block until sample data has been unloaded
		fm.Bank_Unload(bank)
		strmap_delete_key(&audio._banks_map, name)
	}
// SPRITES/TEXTURE GROUPS

	TexturePageLoadState :: enum{
		unloaded,
		loadingSurface,
		loadingTexture,
		loaded
	}

	TexturePageLoadTask :: struct{
		group:^TextureGroup,
		page:^TexturePage,
		qoiData:[]u8,
	}

	//these groups are loaded at startup and never unloaded
	TEXTURE_GROUPS_PERMANENT :: []string{
		"_default",
		"_extra",
		"_masks",
		"_palettes",
		"blob_foliage",
		"foliage",
		"portraits"
	}

	texture_group_preload :: proc(groupName:string){
		group,ok := &sprites._texture_groups_map[groupName]
		if !ok{
			printf("Warning: Tried to preload unknown texture group '%s'!", groupName)
			return
		}
		if atomic_get(&group.loadState) == .unloaded{
			atomic_set(&group.loadState, .loadingSurface)
			for &page in group.pages{
				page.texture = sdl2.CreateTexture(display._renderer, u32(sdl2.PixelFormatEnum.ABGR8888), .STATIC, page.size, page.size)
				sdl2.SetTextureBlendMode(page.texture, .BLEND)
			}
			thread_task_run_with_data(rawptr(group), _texture_group_load_task)
		}
	}

	@(disabled=DEBUG)
	texture_group_unload :: proc(groupName:string){
		group,ok := &sprites._texture_groups_map[groupName]
		if !ok do return
		switch atomic_get(&group.loadState){
			case .unloaded: return
			case .loadingSurface: texture_group_load_block(groupName) //failsafe
			case .loadingTexture, .loaded: //do nothing
		}

		//non-threaded, free all allocators surfaces and textures and set all sprite page pointers to the nil page
		for &page in group.pages{
			for frame in page.spriteFrames{
				frame.texturePage = sprites._texture_page_nil
				frame.texturePageSurface = sprites._texture_page_surface_nil
			}

			sdl2.DestroyTexture(page.texture)
			page.texture = nil
			sdl2.FreeSurface(page.surface)
			page.surface = nil

			free_all(page.loadAllocator)
			free_all(page.loadTempAllocator)
			page.textureRowsLoaded = 0
		}

		atomic_set(&group.loadState, .unloaded)
	}

	//Waits until texture groups are done loading. Does all main-thread texture loading on the spot if needed. 
	texture_group_load_block :: proc(groupNames:..string){
		trace("texture load block")
		for{
			done := true
			for name in groupNames{
				group,ok := &sprites._texture_groups_map[name]
				if !ok{
					printf("Warning: Tried to load unknown texture group '%s'!", name)
					continue
				}
				switch atomic_get(&group.loadState){
					case .unloaded: 
						texture_group_preload(name)
						done=false
					case .loadingSurface: done=false
					case .loadingTexture:
						_texture_group_texture_load_chunk(group, -1)
						atomic_set(&group.loadState, .loaded)
					case .loaded: //do nothing
				}
			}
			if done do break
			thread_yield()
		}
	}

	_texture_group_load_task :: proc(data:rawptr){
		group := cast(^TextureGroup)data

		//the file bytes and pool bookkeeping only need to live until the decodes finish
		taskAlloc := allocator_make()
		context.allocator = taskAlloc
		context.temp_allocator = taskAlloc
		defer allocator_delete(taskAlloc)

		//load texgroup file
		path := filepath.join({executable_directory, "texture_groups", format("%s.texgroup", group.name)}) or_else ""
		fileData, readErr := os.read_entire_file(path, taskAlloc)
		assertf(readErr == nil, "Failed to read texture group file '%s'! %v", path, readErr)

		//set up pool
		pool:ThreadPool
		thread_pool_init_and_start(&pool, taskAlloc, min(thread_count, len(group.pages)))

		reader := uintptr(raw_data(fileData))
		for &page in group.pages{
			//create the surface here so sprites can be pointed to it before its pixel data is ready. 
			//The "From" variant marks the pixels as externally owned, so FreeSurface won't free the decode allocation the task points it at
			page.surface = sdl2.CreateRGBSurfaceWithFormatFrom(nil, page.size, page.size, 32, page.size*4, u32(sdl2.PixelFormatEnum.ABGR8888))
			sdl2.SetSurfaceBlendMode(page.surface, .NONE)

			qoiSize := uintptr(read_bytes(&reader, u64))
			taskData := new(TexturePageLoadTask)
			taskData^ = {group, &page, bytes_from_uip(reader, qoiSize)}
			reader += qoiSize
			thread_pool_add_task(&pool, _texture_page_load_task, taskData, page.loadTempAllocator)
		}

		//update sprites to point to the correct texture and surface
		for &page in group.pages{
			for frame in page.spriteFrames{
				frame.texturePage = page.texture
				if !group.isHD do frame.texturePageSurface = page.surface
			}
		}

		//finish pool
		thread_pool_finish(&pool)


		atomic_set(&group.loadState, .loadingTexture)
	}

	_texture_page_load_task :: proc(task:ThreadTask){
		data := cast(^TexturePageLoadTask)task.data

		context.allocator = data.page.loadAllocator
		context.temp_allocator = data.page.loadTempAllocator

		img, imgErr := qoi.load_from_bytes(data.qoiData, allocator=data.group.isHD?context.temp_allocator:context.allocator)
		assertf(imgErr == nil, "Failed to decode a page of texture group '%s'! %v", data.group.name, imgErr)
		assertf(i32(img.width) == data.page.size, "A decoded page of texture group '%s' doesn't match its index size!", data.group.name)

		data.page.surface.pixels = raw_data(img.pixels.buf)
	}

	//Pass a negative chunk size to load everything immediately
	_texture_group_texture_load_chunk :: proc(group:^TextureGroup, chunkSize:i32=MEGABYTE) -> bool{
		for &page in group.pages{
			if page.textureRowsLoaded == page.size do continue

			rowsToLoad := chunkSize < 0 ? page.size - page.textureRowsLoaded : clamp(chunkSize/(page.size*4), 1, page.size - page.textureRowsLoaded)
			rect := sdl2.Rect{0, page.textureRowsLoaded, page.size, rowsToLoad}
			pixels := rawptr(uintptr(page.surface.pixels) + uintptr(page.textureRowsLoaded*page.surface.pitch))
			sdl2.UpdateTexture(page.texture, &rect, pixels, page.surface.pitch)
			
			page.textureRowsLoaded += rowsToLoad
			if page.textureRowsLoaded < page.size do return false

			if group.isHD{
				_texture_mipmaps_generate(page.texture)

				//the surface was only staging for the upload, drop it to save RAM
				sdl2.FreeSurface(page.surface)
				page.surface = nil
			}
			free_all(page.loadTempAllocator)
		}
		return true
	}

	@export //needs to be called from main loop to get time budget
	_texture_groups_textures_async_load :: proc(timeBudget:f32){
		startT := time_get()
		groups := make([dynamic]^TextureGroup, 0, len(sprites._texture_groups_map), context.temp_allocator)
		for _,&group in sprites._texture_groups_map{
			if atomic_get(&group.loadState) == .loadingTexture do append(&groups, &group)
		}

		if len(groups) == 0 do return

		for{
			group := peek(groups)
			if _texture_group_texture_load_chunk(group){
				atomic_set(&group.loadState, .loaded)
				pop(&groups)
				if len(groups) == 0 do return
			}
			if time_get() - startT >= timeBudget do return
		}
	}

	//also starts preloading textures
	_texture_groups_index_file_load :: proc(){
		context.allocator = assets.allocator

		palettesSurf:^sdl2.Surface
		paletteSpriteNames := make([dynamic]string, context.temp_allocator)

		path, _ := filepath.join({executable_directory, "texture_groups/.index"}, context.temp_allocator)

		fileData,err := os.read_entire_file(path, context.temp_allocator)
		assertf(err==nil, "Error loading texture groups index! %v", err)

		r := uintptr(raw_data(fileData))
		indexCount := read_bytes(&r, u8)
		for _ in 0..<indexCount{
			nameLen := uintptr(read_bytes(&r, u16))
			dataLen := uintptr(read_bytes(&r, u64))
			name := string_from_uip(r, nameLen)
			r += nameLen

			clonedName := strmap_set(&sprites._texture_groups_map, name, TextureGroup{})
			group := &sprites._texture_groups_map[clonedName]
			group.name = clonedName
			group.isHD = string_has_suffix(clonedName, "_HD")
			if !contains(TEXTURE_GROUPS_PERMANENT, clonedName) do append(&sprites.texture_groups_dynamic, clonedName)

			if dataLen == 0 do continue

			_texture_group_index_load(clonedName, bytes_from_uip(r, dataLen), clonedName == "_palettes" ? &paletteSpriteNames : nil)
			r += dataLen
		}

		for groupName in TEXTURE_GROUPS_PERMANENT do texture_group_preload(groupName)
		when !DEBUG do texture_group_preload("title_screen_HD") //we always go to the title screen in release mode, so start preloading as early as possible

		for _, &sp in sprites._sprites_map{
			if len(sp.frames) > 0{ //how does this happen...
				totalDuration :f32= 0
				for &frame in sp.frames{
					frame.framePosition = totalDuration
					totalDuration += frame.duration
				}
				sp.totalDuration = totalDuration
			}
		}

		texture_group_load_block("_palettes")
		palettesGroup, palettesOk := &sprites._texture_groups_map["_palettes"]
		assert(palettesOk && len(palettesGroup.pages) > 0, "Palettes texture group is missing or empty!")
		palettesSurf = palettesGroup.pages[0].surface
		sdl2.LockSurface(palettesSurf)
		format := palettesSurf.format
		pixels := uintptr(palettesSurf.pixels)
		pitch := uintptr(palettesSurf.pitch)
		bpp := int(format.BytesPerPixel)
		bppUip := uintptr(bpp)
		for name in paletteSpriteNames{
			sprite := &sprites._sprites_map[name]
			pageRect := sprite.frames[0].texturePagePos
			size := Vec2i{int(pageRect.w), int(pageRect.h)}
			shaders._pal_swap_sprite_map[sprite] = PalSwapData{size, make([dynamic][3]f32, 0, size.x*size.y)}
			colors := &(&shaders._pal_swap_sprite_map[sprite]).colors

			for x in pageRect.x..<pageRect.x+pageRect.w{
				for y in pageRect.y..<pageRect.y+pageRect.h{
					pixelData:u32
					mem.copy(&pixelData, rawptr(pixels + uintptr(x)*bppUip + uintptr(y)*pitch), bpp)
					pixelCol:Color
					sdl2.GetRGB(pixelData, format, &pixelCol.r, &pixelCol.g, &pixelCol.b)
					append(colors, ColorF(pixelCol)*(1./255.))
				}
			}

		}

		sdl2.UnlockSurface(palettesSurf)
	}


	//If the group name is empty, returns a list of sprite frames for hot-reloading
	_texture_group_index_load :: proc(groupName:string, indexFileData:[]u8, paletteSpriteNames:^[dynamic]string=nil) -> []^SpriteFrame{
		reader := uintptr(raw_data(indexFileData))
		pageFrames := make([dynamic][dynamic]^SpriteFrame, context.temp_allocator)
		for{
			//name
			nameLen := read_bytes(&reader, u8)
			if nameLen == 0 do break
			spriteName := string_from_ptr(cast(^u8)reader, int(nameLen))
			if paletteSpriteNames != nil do append(paletteSpriteNames, spriteName)
			reader += uintptr(nameLen)

			clonedName := strmap_set(&sprites._sprites_map, spriteName, Sprite{})
			newSprite := &sprites._sprites_map[clonedName]
			newSprite.name = clonedName

			//dimensions
			size   := read_bytes(&reader, [2]u16)
			origin := read_bytes(&reader, [2]i16)
			newSprite.size = Vec2(size)
			newSprite.origin = {i32(origin.x), i32(origin.y)}

			// mask block
			maskKind := read_bytes(&reader, u8)
			if maskKind > 0 {
				trace("mask read")
				newSprite.mask = new(ColliderMask)
				newSprite.mask.size = Vec2i(read_bytes(&reader, [2]u16))
				newSprite.mask.origin = Vec2i(read_bytes(&reader, [2]i16))

				if maskKind == 2{
					ppCount := read_bytes(&reader, u32)
					newSprite.mask.precisePoints = make([][2]i16, ppCount)
					byteSize := int(ppCount)*size_of([2]i16)
					mem.copy(rawptr(&newSprite.mask.precisePoints[0]), rawptr(reader), byteSize)
					reader += uintptr(byteSize)
				}
			}

			// frames
			frameCount := read_bytes(&reader, u16)
			newSprite.frames = make([dynamic]SpriteFrame, frameCount)
			framePos :f32= 0
			for &frame in newSprite.frames {
				frame.framePosition = framePos
				frame.duration = f32(read_bytes(&reader, u16))
				framePos += frame.duration

				frame.trimOffset = {
					i32(read_bytes(&reader, i16)),
					i32(read_bytes(&reader, i16))
				}

				frame.texturePagePos.w = i32(read_bytes(&reader, u16))
				frame.texturePagePos.h = i32(read_bytes(&reader, u16))
				frame.texturePagePos.x = i32(read_bytes(&reader, u16))
				frame.texturePagePos.y = i32(read_bytes(&reader, u16))
				frame.texturePage = sprites._texture_page_nil
				frame.texturePageSurface = sprites._texture_page_surface_nil
				pageInd := int(read_bytes(&reader, u8))
				for len(pageFrames) <= pageInd do append(&pageFrames, make([dynamic]^SpriteFrame))
				append(&pageFrames[pageInd], &frame)
			}
			newSprite.totalDuration = framePos
		}

		if groupName == "" do return pageFrames[0][:]

		group := &sprites._texture_groups_map[groupName]
		group.pages = make([dynamic]TexturePage, len(pageFrames))
		for frameArr,i in pageFrames{
			pageSize := i32(read_bytes(&reader, u16))
			if pageSize == 0{
				clear(&group.pages)
				break
			}
			group.pages[i] = TexturePage{
				spriteFrames=frameArr[:],
				loadAllocator=allocator_make(),
				loadTempAllocator=allocator_make(),
				size=pageSize
			}
		}

		return nil
	}

	@(disabled=!DEBUG)
	_sprite_add_to_file_tree :: proc(s:^Sprite, parentPath:string, sExpr := #caller_expression(s)){
		assertf(s != nil, "Sprite not found for id '%s'!", sExpr)
		_asset_add_to_file_tree(s, parentPath, sprites.file_tree)
	}

	@(disabled=!DEBUG)
	_sprite_masks_load_debug_textures :: proc(){
		if sprites._debug_mask_textures_loaded do return

		maskCol :: Color{223, 113, 38}
		draw_color(maskCol)

		for _,&spr in sprites._sprites_map{
			if spr.mask != nil && spr.mask.size != 0{
				spr.mask.debugTex = tex_make(spr.mask.size)
				if len(spr.mask.precisePoints) > 0{
					tex_target_set_stackless(spr.mask.debugTex)
					draw_clear(COLOR_WHITE, 0)
					for p in spr.mask.precisePoints{
						sdl2.RenderDrawPoint(display._renderer, i32(p.x), i32(p.y))
					}
				}
				else{
					tex_target_set_stackless(spr.mask.debugTex)
					draw_clear(maskCol, 255)
				}
			}
		}
		sprites._debug_mask_textures_loaded = true
	}

	//Generates real GPU mipmaps for a texture through direct OpenGL calls. 
	//Mainly just for HD texture pages. Reduced performance modes draw into smaller targets, and the GPU picks the fitting mip level per draw.
	_texture_mipmaps_generate :: proc(texture:^sdl2.Texture){
		sdl2.GL_BindTexture(texture, nil, nil)
		gl.GenerateMipmap(gl.TEXTURE_2D)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR)
		sdl2.GL_UnbindTexture(texture)
	}

	//data is [u32 pageSize][u32 indexSize][index data][raw ABGR8888 page pixels]
	_sprite_hot_reload :: proc(data:[]u8){
		context.allocator = assets.allocator
		printf("Hot-reloading sprite(s)...")

		r := uintptr(raw_data(data))
		pageSize := i32(read_bytes(&r, u32))
		indexSize := int(read_bytes(&r, u32))
		indexData := bytes_from_uip(r, uintptr(indexSize))
		r += uintptr(indexSize)

		//upload the hot page. Old hot pages are kept, sprites from earlier reloads may still point to them.
		imageData := clone(bytes_from_uip(r, uintptr(pageSize*pageSize*4)))
		surf := sdl2.CreateRGBSurfaceWithFormatFrom(raw_data(imageData), pageSize, pageSize, 32, pageSize*4, u32(sdl2.PixelFormatEnum.ABGR8888))
		texture := sdl2.CreateTextureFromSurface(display._renderer, surf)

		//point the reloaded sprites at the hot page instead of their normal texture pages, which are never hot reloaded
		frames := _texture_group_index_load("", indexData)
		for frame in frames{
			frame.texturePage = texture
			frame.texturePageSurface = surf
		}
	}

// FONTS

	FontPageLoadTask :: struct{
		fileData:[]u8,
		page:^FontPage
	}

	FONT_PAGE_SIZE :: 4096

	_font_page_index_load :: proc(indexFileData:[]u8, pageName:string){
		strmap_set(&fonts._pages, pageName, FontPage{})
		page := &fonts._pages[pageName]

		page.texture = sdl2.CreateTexture(display._renderer, u32(sdl2.PixelFormatEnum.ABGR8888), .STATIC, FONT_PAGE_SIZE, FONT_PAGE_SIZE)
		sdl2.SetTextureBlendMode(page.texture, .BLEND)
		page.loadTempAllocator = allocator_make()
		page.isHD = string_has_suffix(pageName, "_HD")

		reader := uintptr(raw_data(indexFileData))
		eof := reader + uintptr(len(indexFileData))
		for reader < eof{
			nameLen := read_bytes(&reader, u8)
			fontName := strings.string_from_ptr(cast(^u8)reader, int(nameLen))
			reader += uintptr(nameLen)

			nameSplit := string_split(fontName, "__")
			sizelessName := nameSplit[0]
			size,_ := string_to_int(nameSplit[1])

			fontName = strmap_set(&fonts._fonts_map, fontName, Font{})
			newFont := &fonts._fonts_map[fontName]

			if sizelessName not_in fonts._font_sizeless_map{
				strmap_set(&fonts._font_sizeless_map, sizelessName, make([dynamic]^Font))
			}

			sizelessName,_  = strmap_get(fonts._font_sizeless_map, sizelessName)

			newFont.name = fontName
			newFont.size = size
			newFont.sizelessName = sizelessName
			newFont.page = page.texture
			newFont.runeMap = make(map[rune]sdl2.Rect)

			runeCount := read_bytes(&reader, u32)
			for n in 0..<runeCount{
				r := read_bytes(&reader, rune)
				rect := sdl2.Rect{
					i32(read_bytes(&reader, u16)),
					i32(read_bytes(&reader, u16)),
					i32(read_bytes(&reader, u16)),
					i32(read_bytes(&reader, u16))
				}
				newFont.runeMap[r] = rect
			}
		}
	}

	_font_page_load_task :: proc(data:rawptr){
		task := cast(^FontPageLoadTask)data

		context.allocator = task.page.loadTempAllocator
		context.temp_allocator = allocator_make()
		defer allocator_delete(context.temp_allocator)

		//decoded pixels only need to live until the texture upload below, so they can go on the temp allocator
		img, imgErr := qoi.load_from_bytes(task.fileData)
		assertf(imgErr == nil, "ERROR: Failed to decode font page! %v", imgErr)

		task.page.surface = sdl2.CreateRGBSurfaceWithFormatFrom(
			raw_data(img.pixels.buf), i32(img.width), i32(img.height), 32, i32(img.width*4),
			u32(sdl2.PixelFormatEnum.ABGR8888)
		)

		atomic_set(&task.page.loadState, .loadingTexture)
	}

	_font_page_preload :: proc(pageFileData:[]u8, pageName:string){
		task := new(FontPageLoadTask, context.temp_allocator)
		task.fileData = pageFileData
		task.page = &fonts._pages[pageName]

		atomic_set(&task.page.loadState, .loadingSurface)

		thread_task_run_with_data(task, _font_page_load_task)
	}

	_fonts_load_block :: proc(){
		for{
			done := true
			for pageName,&page in fonts._pages{
				switch atomic_get(&page.loadState){
					case .unloaded: panicf("Blocked on font page '%s' that wasn't preloaded!", pageName)
					case .loadingSurface: done = false
					case .loaded: //do nothing
					case .loadingTexture: 
						rect := sdl2.Rect{0, 0, FONT_PAGE_SIZE, FONT_PAGE_SIZE}
						sdl2.UpdateTexture(page.texture, &rect, page.surface.pixels, page.surface.pitch)
						
						if page.isHD do _texture_mipmaps_generate(page.texture)
						sdl2.FreeSurface(page.surface)
						page.surface = nil
						allocator_delete(page.loadTempAllocator)
						atomic_set(&page.loadState, .loaded)
				}
			}
			if done do break
			thread_yield()
		}
	}
	

	//data is the paths to the built page .png and .index files, newline-separated
	_font_hot_reload :: proc(data:[]u8){
		context.allocator = assets.allocator

		dataSplit := string_split(string(data), "\n")
		pagePath := dataSplit[0]
		indexPath := dataSplit[1]
		pageName := filepath.stem(pagePath)
		printf("Hot-reloading font page '%s'...", pageName)

		pageFileData, pageErr := os.read_entire_file(pagePath, context.temp_allocator)
		indexFileData, indexErr := os.read_entire_file(indexPath, context.temp_allocator)
		if pageErr != nil || indexErr != nil{
			printf("WARNING: Could not read built font page '%s', skipping reload.", pageName)
			return
		}

		oldPage := fonts._pages[pageName]
		sdl2.DestroyTexture(oldPage.texture)

		_font_page_index_load(indexFileData, pageName)
		_font_page_preload(pageFileData, pageName)
		_fonts_load_block()
	}

// SHADERS
	_shader_load :: proc(glslFileData:[]u8, assetName:string){
		sourceStrings := strings.split(string(glslFileData), "<fragment>", context.temp_allocator)
		vertSource := strings.clone_to_cstring(strings.concatenate({"#version 130\n", sourceStrings[0]}, context.temp_allocator), context.temp_allocator)
		fragSource := strings.clone_to_cstring(strings.concatenate({"#version 130\n", sourceStrings[1]}, context.temp_allocator), context.temp_allocator)
		strmap_set(&shaders._shaders_map, assetName, shader_compile(vertSource, fragSource))
	}

	//data is path to the intermediate shader .glsl file
	_shader_hot_reload :: proc(data:[]u8){
		glslFilePath := string(data)
		assetName := filepath.stem(glslFilePath)
		printf("Hot-reloading shader '%s'...", assetName)
		
		glslFileData,_ := os.read_entire_file(glslFilePath, context.temp_allocator)
		
		mapPtr := &shaders._shaders_map[assetName]
		shader_destroy(mapPtr^)
		_shader_load(glslFileData, assetName)
		struct_set(sh, assetName, mapPtr^)
	}

// STAGES
	_stages_preparse_task :: proc(){
		context.allocator = stage._preParseAllocator
		context.temp_allocator = stage._preParseTempAllocator

		for _,&stg in stage._stages_map{
			jsonData, jsErr := json.parse(stg.rawData)
			assertf(jsErr == json.Error.None, "Failed to parse stage json. Error: %v", jsErr)
			jsonObject := jsonData.(json.Object)
			assertf(stage_data_upgrade(&jsonObject), "Stage data could not be updated for stage '%s', format version '%s'", stg.name, jsonObject["format_version"])
			stg.data = jsonObject
			stg.rawData = nil

			_asset_add_to_file_tree(&stg, stg.data["filePath"].(json.String), stage.file_tree)
		}

		allocator_delete(stage._preParseTempAllocator)
		atomic_set(&stage.preParseDone, true)
	}

	stages_preparse_block :: #force_inline proc() {
		for !atomic_get(&stage.preParseDone) do thread_yield()
	}

// DIALOGUES
	
	_dialogues_preload_all :: proc(){
		thread_task_run(_dialogues_load_task)
	}

	_dialogues_load_task :: proc(){
		context.allocator = dialogue.load_allocator
		context.temp_allocator = allocator_make()
		defer allocator_delete(context.temp_allocator)

		files, err := os.read_directory_by_path(filepath.join({executable_directory, "dialogues"}, context.temp_allocator) or_else "", 0, context.temp_allocator)
		assertf(err == nil, "Error reading dialogues directory! %v", err)

		append(&dialogue.locales_loaded, "en") //first locale is always english
		for file in files{
			if filepath.ext(file.fullpath) != ".dialogue" do continue //users may leave stray files in the dialogues folder

			locCode := filepath.stem(file.fullpath)
			locID := 0
			if locCode != "en"{
				if len(dialogue.locales_loaded) >= LOCALES_MAX{
					sdl2.ShowSimpleMessageBox({.ERROR}, "Diorama Break", string_to_cstring(format("Error: Cannot load more than %i dialogue localization files! Delete some!!", LOCALES_MAX), context.temp_allocator), nil)
					panic("Too many dialogue localization files!")
				}
				locID = len(dialogue.locales_loaded)
				append(&dialogue.locales_loaded, clone(locCode))
			}

			fileData,fileErr := os.read_entire_file(file.fullpath, context.allocator) //permanent allocation, no need to clone things
			assertf(fileErr == nil, "Error reading dialogues file '%s'! %v", file.fullpath, fileErr)

			r := uintptr(raw_data(fileData))
			eof := r + uintptr(len(fileData))
			for r<eof{
				nameLen := uintptr(read_bytes(&r, u16))
				rawDataLen := uintptr(read_bytes(&r, u64))
				assetName := string_from_uip(r, nameLen)
				r += nameLen
				_dialogue_load(bytes_from_uip(r, rawDataLen), assetName, locID)
				r += rawDataLen
			}
		}
		
		atomic_set(&dialogue.dialogues_loaded, true)
	}

	_dialogues_load_block :: proc(){
		for !atomic_get(&dialogue.dialogues_loaded) do thread_yield()
	}

	_dialogue_load :: proc(rawData:[]u8, assetName:string, locID:int){
		dialogueString := string(rawData)
		lines := strings.split_lines(dialogueString)
		labelsMap := make(map[string]DialogueLabelInfo)
		for line, i in lines{
			if(line != "" && line[0] == '#') do labelsMap[line[1:]] = DialogueLabelInfo{i}
		}
		if assetName not_in dialogue._dialogues_map{
			dialogue._dialogues_map[assetName] = Dialogue{name=assetName}
		}
		locales := &(&dialogue._dialogues_map[assetName]).locales
		if len(locales) <= locID do resize(locales, locID+1)
		locales[locID] = DialogueData{lines, labelsMap, dialogueString}
	}

	//data is localization code header + dialogue built data, permanently allocated
	_dialogue_hot_reload :: proc(data:[]u8) -> bool{
		context.allocator = dialogue.load_allocator

		r := uintptr(raw_data(data))
		locCodeLen := uintptr(read_bytes(&r, u8))
		locCode := string_from_uip(r, locCodeLen)
		locID := find(dialogue.locales_loaded[:], locCode) or_return
		r+=locCodeLen
		nameLen := uintptr(read_bytes(&r, u16))
		rawDataLen := uintptr(read_bytes(&r, u64))
		assetName := string_from_uip(r, nameLen)
		r += nameLen

		//don't bother deleting old dialogue data since dialogue load allocator can't do individual frees anyway

		//if the reloaded dialogue is currently open in the active locale, close it and reopen it at its current label
		dia := &dialogue._dialogues_map[assetName]
		isOpen := dia != nil && dialogue.current == dia && LocaleID(locID) == settings.locale

		reopenLabel:string
		wasBlocking:bool
		if isOpen{
			reopenLabel = string_clone(dialogue.current_label, context.temp_allocator) //cloned, dialogue_close deletes it
			wasBlocking = dialogue.isBlocking
			dialogue_close()
		}

		_dialogue_load(bytes_from_uip(r, rawDataLen), assetName, locID)

		if isOpen{
			if reopenLabel != "" && reopenLabel not_in dialogue_data(dia).labelsMap do return true //the label no longer exists, don't bother reopening
			dialogue_open(dia, reopenLabel, wasBlocking)
		}

		return true
	}

_packed_assets_load :: proc(){
	trace("Packed asset load")
	PackedAssetKind :: enum{
		fontPageIndex,
		fontPage,
		shader,
		curve,
		stage
	}

	context.allocator = assets.allocator

	//fonts temp vars
	FontSubPageIndexKey :: struct{
		font:^Font,
		index:int
	}
	FontSubPageData :: struct{
		page:^sdl2.Texture,
		x:i32,
		y:i32
	}
	FontCharPosition :: struct{
		char:rune,
		subPageIndex:int,
		x:i32,
		y:i32,
		w:i32,
		h:i32
	}
	fontSubPageIndex := make(map[FontSubPageIndexKey]FontSubPageData, 1<<3, context.temp_allocator)
	fontCharPositions := make(map[string][dynamic]FontCharPosition, 1<<3, context.temp_allocator)


	print("Reading packed asset data...")

	//load .mopak
	when(ON_SWITCH){
		//use sdl instead of core:os for compatability
		packFileCstr = "Contents:/assets.mopak"
		assetFileSize:c.size_t
		assetDataPtr:rawptr
		{
			trace("Load asset file")
			assetDataPtr = sdl2.LoadFile(rawptr(packFileCstr), &assetFileSize)
		}
		defer sdl2.free(assetDataPtr) //TODO: this needs to be freed at the end of game_init, not at the end of this proc
		assetData := slice.bytes_from_ptr(assetDataPtr, int(assetFileSize))
	}
	else{
		assert(os.exists(assets.pack_file_path), "Asset pack file not found!")
		assetData,err := os.read_entire_file(assets.pack_file_path, context.temp_allocator)
		assertf(err==nil, "Error loading asset pack file! %v", err)
	}
	
	assetReader := uintptr(raw_data(assetData))

	assetKindNames := reflect.enum_field_names(PackedAssetKind)

	for assetKind in PackedAssetKind{
		t := time_get()
		assetCount := read_bytes(&assetReader, u32)
		trace(format("Reading %s", assetKindNames[assetKind]))
		for i in 0..<assetCount{
			assetNameSize := uintptr(read_bytes(&assetReader, u16))
			fileSize := uintptr(read_bytes(&assetReader, u64))

			//get asset name
			assetName := string_from_uip(assetReader, assetNameSize)
			assetReader += assetNameSize

			trace(assetName)

			fileData := assetReader
			assetReader += fileSize

			if(assetNameSize == 0) do continue //empty entry, the builder failed to read this asset while packing

			switch(assetKind){
				case .shader:
					_shader_load(bytes_from_uip(fileData, fileSize), assetName)

				case .fontPageIndex:
					_font_page_index_load(bytes_from_uip(fileData, fileSize), assetName)

				case .fontPage:
					_font_page_preload(bytes_from_uip(fileData, fileSize), assetName)

				case .curve:
					clonedName := strmap_set(&curves._curves_map, assetName, Curve{})
					curve := &curves._curves_map[clonedName]
					curve.name = clonedName
					split := strings.split_n(string_from_uip(fileData, fileSize), "|", 2, context.temp_allocator)
					when DEBUG do curves.filepaths[clonedName] = clone(split[0])
					pointsData := slice.reinterpret([]CurvePoint, transmute([]u8)split[1])
					init(&curve.points, len(pointsData))
					copy(curve.points[:], pointsData)

					invName := format("%s_inv", assetName)
					clonedName = strmap_set(&curves._curves_map, invName, Curve{})
					invCurve := &curves._curves_map[clonedName]
					invCurve.name = clonedName
					invCurve.invert = true
					invCurve.points = curve.points

				case .stage:
					clonedName := strmap_set(&stage._stages_map, assetName, Stage{init=nil_proc})
					newStage := &stage._stages_map[assetName]
					newStage.name = clonedName
					newStage.rawData = clone(bytes_from_uip(fileData, fileSize), stage._preParseTempAllocator)
			}
			

			when DEBUG do print("Read", assetKindNames[assetKind],"-",assetName)
		}

		printf("Read %ss (%.0fms)", assetKindNames[assetKind], time_get()-t)
	}

} 

//handles remaining init tasks that depend all systems and asset file data to be loaded
_assets_load_end :: proc(){
	reloadAssetNames :: proc(strmap:^map[string]$T, names:^[dynamic]string){
		clear(names)
		for key in strmap{
			append(names, key)
		}
		sort_general(names)
	}

	//sprites
	_reload_sprite_ids()
	reloadAssetNames(&sprites._sprites_map, &sprites.names)
	_reload_tilesets()
	_reload_entity_prefabs()
	_nineslice_info_reload()
	
	//shaders
	_reload_shader_ids()

	//fonts
	for fontName in fonts._fonts_map{
		font := &fonts._fonts_map[fontName]
		append(&fonts._font_sizeless_map[font.sizelessName], font)
	} 
	_reload_font_ids()

	//curves
	_reload_curve_ids()
	reloadAssetNames(&curves._curves_map, &curves.names)
	
	//stages
	_reload_stage_ids()
	reloadAssetNames(&stage._stages_map, &stage.names)
	_reload_stage_procs()
	thread_task_run(_stages_preparse_task)

	//dialogues
	_dialogues_load_block()
	_reload_dialogue_ids()
	reloadAssetNames(&dialogue._dialogues_map, &dialogue.names)

	//asset-dependent systems
	print("Reloading asset-dependent system elements...")
	_passives_reload()
	_combat_system_reload()
	_dialogue_system_reload()
	_items_reload()
	_ui_system_reload()
	_cutscenes_reload()
	_blobFoliage_system_reload()
	
	when DEBUG{
		_shell_commands_reload()
		_entities_event_process(.assetReload)
	}
}

@(disabled=!DEBUG)
_assets_hot_reload_check :: proc(){
	buildDir := filepath.dir(executable_directory[:len(executable_directory)-1]) //trims the trailing '\'
	buildDirFiles,_ := os.read_all_directory_by_path(buildDir, context.temp_allocator)
	for file in buildDirFiles{
		if filepath.ext(file.name) != ".rr" do continue
		
		requestKind := string_slice_between(file.name, ".", ".")
		requestData,_ := os.read_entire_file(file.fullpath, requestKind == "dialogue"?dialogue.load_allocator:context.temp_allocator)
		
		switch requestKind{
			case "sprite": _sprite_hot_reload(requestData)
			case "font": _font_hot_reload(requestData)
			case "shader": _shader_hot_reload(requestData)
			case "dialogue": _dialogue_hot_reload(requestData)
			case: panicf("Unknown asset reload request '%s'", string(requestKind))
		}

		os.remove(file.fullpath)
		printf("%s hot-reload done!", requestKind)
	}
}

