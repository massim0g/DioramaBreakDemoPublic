package massimodin //@nested-tags:engine/asset_loading
/*
System for unpacking small assets that get loaded into RAM at game start.
NOT INTENDED for assets that are potentially too big, and are loaded from disk after the game has started, such as audio.
*/

import "../sdl3"
import "../shadercross"
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
		loading,
		loaded
	}

	//Creates a page texture, with a mip chain for HD pages.
	/*
	Mip cap: 0 means the full chain.
	Capping it is the single knob that makes reduced-resolution atlas pages possible later without touching uvs, because sprite rects stay in virtual page space.
	*/
	TEXTURE_PAGE_MIP_CAP :: 0

	_texture_page_texture_make :: proc(size:u32, hd:bool, mipCap:u32=TEXTURE_PAGE_MIP_CAP) -> ^sdl3.GPUTexture{
		levels:u32 = 1
		usage:sdl3.GPUTextureUsageFlags = {.SAMPLER}
		if hd{
			s := size
			for s > 1{
				levels += 1
				s >>= 1
			}
			if mipCap > 0 do levels = min(levels, mipCap)
			usage += {.COLOR_TARGET} //GenerateMipmapsForGPUTexture blits down the chain, which requires render-target usage
		}
		tex := sdl3.CreateGPUTexture(render.device, {
			type=.D2, format=TEXTURE_FORMAT_DEFAULT, usage=usage,
			width=size, height=size, layer_count_or_depth=1, num_levels=levels,
		})
		assertf(tex != nil, "Texture page creation failed (%d, hd=%v)! %s", size, hd, sdl3.GetError())
		return tex
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
			atomic_set(&group.loadState, .loading)
			thread_task_run_with_data(rawptr(group), _texture_group_load_task)
		}
	}

	@(disabled=DEBUG)
	texture_group_unload :: proc(groupName:string){
		group,ok := &sprites._texture_groups_map[groupName]
		if !ok do return
		switch atomic_get(&group.loadState){
			case .unloaded: return
			case .loading: texture_group_load_block(groupName) //failsafe
			case .loaded: //do nothing
		}

		//non-threaded, free all allocators surfaces and textures and set all sprite page pointers to the nil page
		for &page in group.pages{
			for frame in page.spriteFrames{
				frame.texturePage = &sprites._texture_page_nil
			}

			tex_destroy({ptr=page.texture}) //defers release of texture until after all draws complete
			page.texture = nil
			sdl3.DestroySurface(page.surface)
			page.surface = nil

			free_all(page.loadAllocator)
		}

		atomic_set(&group.loadState, .unloaded)
	}

	//Waits until texture groups are done loading. The loader task does all the work, so this only spins.
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
					case .loading: done=false
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
			/*
			Create the texture and surface here so sprites can be pointed at them before the pixel data is ready.
			The "From" surface variant marks the pixels as externally owned, so DestroySurface won't free the decode allocation the task points it at.
			HD pages never get a surface: nothing reads their pixels back on the CPU, and keeping one just wastes the RAM.
			*/
			page.texture = _texture_page_texture_make(u32(page.size), group.hd)
			if !group.hd{
				page.surface = sdl3.CreateSurfaceFrom(i32(page.size), i32(page.size), .ABGR8888, nil, i32(page.size)*4)
				sdl3.SetSurfaceBlendMode(page.surface, sdl3.BLENDMODE_NONE)
			}

			qoiSize := uintptr(read_bytes(&reader, u64))
			taskData := new(TexturePageLoadTask)
			taskData^ = {group, &page, bytes_from_uip(reader, qoiSize)}
			reader += qoiSize
			thread_pool_add_task(&pool, _texture_page_load_task, taskData, panic_allocator())
		}

		//update sprites to point to the correct page
		for &page in group.pages{
			for frame in page.spriteFrames{
				frame.texturePage = &page
			}
		}

		//finish pool
		thread_pool_finish(&pool)

		atomic_set(&group.loadState, .loaded)
	}

	//Decodes AND uploads a page, entirely off the main thread.
	_texture_page_load_task :: proc(task:ThreadTask){
		data := cast(^TexturePageLoadTask)task.data

		context.allocator = data.page.loadAllocator
		context.temp_allocator = allocator_make()
		defer allocator_delete(context.temp_allocator)

		img, imgErr := qoi.load_from_bytes(data.qoiData, allocator=data.group.hd?context.temp_allocator:context.allocator)
		assertf(imgErr == nil, "Failed to decode a page of texture group '%s'! %v", data.group.name, imgErr)
		assertf(img.width == int(data.page.size), "A decoded page of texture group '%s' doesn't match its index size!", data.group.name)

		if !data.group.hd do data.page.surface.pixels = raw_data(img.pixels.buf)

		//upload the whole page right here on the loader thread, HD pages get their mip chain in the same command buffer
		texture_upload(data.page.texture, img.pixels.buf[:], int(data.page.size), generateMipsAfter=data.group.hd)
	}

	//also starts preloading textures
	_texture_groups_index_file_load :: proc(){
		context.allocator = assets.allocator

		palettesSurf:^sdl3.Surface
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
			group.hd = string_has_suffix(clonedName, "_HD")
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

		palettesPackedData := make([dynamic]u32, context.temp_allocator)

		palettesSurf = palettesGroup.pages[0].surface
		sdl3.LockSurface(palettesSurf)

		formatDetails := sdl3.GetPixelFormatDetails(palettesSurf.format)
		pixels := uintptr(palettesSurf.pixels)
		pitch := uintptr(palettesSurf.pitch)
		bpp := int(formatDetails.bytes_per_pixel)
		bppUip := uintptr(bpp)

		for name in paletteSpriteNames{
			sprite := &sprites._sprites_map[name]
			pageRect := sprite.frames[0].texturePagePos
			pagePos := Vec2i(pageRect.pos)
			size := Vec2i(pageRect.size)
			render._pal_swap_sprite_map[sprite] = PalSwapData{size, i32(len(palettesPackedData))}

			for x in pagePos.x..<pagePos.x+size.x{
				for y in pagePos.y..<pagePos.y+size.y{
					pixelData:u32
					mem.copy(&pixelData, rawptr(pixels + uintptr(x)*bppUip + uintptr(y)*pitch), bpp)
					c:Color
					sdl3.GetRGB(pixelData, formatDetails, nil, &c.r, &c.g, &c.b)
					append(&palettesPackedData, u32(c.r) | u32(c.g)<<8 | u32(c.b)<<16)
				}
			}

		}
		sdl3.UnlockSurface(palettesSurf)

		gpu_dynamic_buffer_reserve(&render._palettes_buffer, len(palettesPackedData)*size_of(u32))
		gpu_buffer_upload(render._palettes_buffer.buf.(^sdl3.GPUBuffer), slice_to_bytes(palettesPackedData[:]))
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
			newSprite.origin = {f32(origin.x), f32(origin.y)}

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
					f32(read_bytes(&reader, i16)),
					f32(read_bytes(&reader, i16))
				}

				//the pack stores u16 components in w/h/x/y order
				frame.texturePagePos.size.x = f32(read_bytes(&reader, u16))
				frame.texturePagePos.size.y = f32(read_bytes(&reader, u16))
				frame.texturePagePos.pos.x = f32(read_bytes(&reader, u16))
				frame.texturePagePos.pos.y = f32(read_bytes(&reader, u16))
				frame.texturePage = &sprites._texture_page_nil
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
				size=f32(pageSize),
				hd=group.hd
			}
		}

		return nil
	}

	@(disabled=!DEBUG)
	_sprite_add_to_file_tree :: proc(s:^Sprite, parentPath:string, sExpr := #caller_expression(s)){
		assertf(s != nil, "Sprite not found for id '%s'!", sExpr)
		_asset_add_to_file_tree(s, parentPath, sprites.file_tree)
	}

	/*
	Builds the collider mask debug overlays.
	Pixels are laid out on the CPU and uploaded to a GPU texture.
	*/
	@(disabled=!DEBUG)
	_sprite_masks_load_debug_textures :: proc(){
		if sprites._debug_mask_textures_loaded do return

		maskBlend :: Blend{223, 113, 38, 255}

		for _,&spr in sprites._sprites_map{
			if spr.mask == nil || spr.mask.size == 0 do continue

			size := spr.mask.size
			pixels := make([]Blend, size.x*size.y, context.temp_allocator)

			if len(spr.mask.precisePoints) > 0{
				for p in spr.mask.precisePoints{
					x, y := int(p.x), int(p.y)
					if x < 0 || y < 0 || x >= size.x || y >= size.y do continue
					pixels[y*size.x + x] = maskBlend
				}
			}
			else{
				for &p in pixels do p = maskBlend
			}

			spr.mask.debugTex = Tex{texture_make_from_pixels(slice.to_bytes(pixels), size), size, false}
		}
		sprites._debug_mask_textures_loaded = true
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
		page := new(TexturePage, assets.allocator)
		page^ = TexturePage{
			texture = texture_make_from_pixels(imageData, {int(pageSize), int(pageSize)}),
			size = f32(pageSize),
			surface = sdl3.CreateSurfaceFrom(pageSize, pageSize, .ABGR8888, raw_data(imageData), pageSize*4),
		}

		//point the reloaded sprites at the hot page instead of their normal texture pages, which are never hot reloaded
		frames := _texture_group_index_load("", indexData)
		for frame in frames{
			frame.texturePage = page
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

		page.hd = string_has_suffix(pageName, "_HD")
		page.texture = _texture_page_texture_make(FONT_PAGE_SIZE, page.hd)

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
			newFont.pageHD = page.hd
			newFont.runeMap = make(map[rune]Rect)

			runeCount := read_bytes(&reader, u32)
			for n in 0..<runeCount{
				r := read_bytes(&reader, rune)
				rect := Rect{
					{f32(read_bytes(&reader, u16)), f32(read_bytes(&reader, u16))},
					{f32(read_bytes(&reader, u16)), f32(read_bytes(&reader, u16))}
				}
				newFont.runeMap[r] = rect
			}
		}
	}

	_font_page_load_task :: proc(data:rawptr){
		task := cast(^FontPageLoadTask)data

		context.allocator = allocator_make()
		context.temp_allocator = context.allocator
		defer allocator_delete(context.allocator)

		img, imgErr := qoi.load_from_bytes(task.fileData)
		assertf(imgErr == nil, "ERROR: Failed to decode font page! %v", imgErr)

		texture_upload(task.page.texture, img.pixels.buf[:], FONT_PAGE_SIZE, generateMipsAfter=task.page.hd)

		atomic_set(&task.page.loadState, .loaded)
	}

	_font_page_preload :: proc(pageFileData:[]u8, pageName:string){
		task := new(FontPageLoadTask, context.temp_allocator)
		task.fileData = pageFileData
		task.page = &fonts._pages[pageName]

		atomic_set(&task.page.loadState, .loading)

		thread_task_run_with_data(task, _font_page_load_task)
	}

	_fonts_load_block :: proc(){
		for{
			done := true
			for pageName,&page in fonts._pages{
				switch atomic_get(&page.loadState){
					case .unloaded: panicf("Blocked on font page '%s' that wasn't preloaded!", pageName)
					case .loading: done = false
					case .loaded: //do nothing
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
		tex_destroy({ptr=oldPage.texture})

		_font_page_index_load(indexFileData, pageName)
		_font_page_preload(pageFileData, pageName)
		_fonts_load_block()
	}

// SHADERS
	//Compiles a shader from packed HLSL source. Runs at init, as each shader comes out of the asset pack.
	_shader_load :: proc(hlslFileData:[]u8, assetName:string){
		stage:shadercross.ShaderStage
		if string_has_suffix(assetName, ".frag") do stage = .FRAGMENT
		else if string_has_suffix(assetName, ".vert") do stage = .VERTEX
		else if string_has_suffix(assetName, ".comp") do stage = .COMPUTE
		else do panicf("Shader '%s' has no stage suffix!", assetName)

		spirvSize:uint
		spirv := shadercross.CompileSPIRVFromHLSL({
			source=string_to_cstring(string(hlslFileData), context.temp_allocator),
			entrypoint="main",
			shader_stage=stage,
		}, &spirvSize)
		assertf(spirv != nil, "Shader compile failed (%s): %s", assetName, sdl3.GetError())
		defer sdl3.free(spirv)

		name := assetName[:len(assetName)-5] //drop the ".vert"/".frag"/".comp" suffixes

		if stage == .COMPUTE{
			computeMeta := shadercross.ReflectComputeSPIRV(cast([^]u8)spirv, spirvSize, 0)
			assertf(computeMeta != nil, "Shader reflection failed (%s): %s", assetName, sdl3.GetError())
			defer sdl3.free(computeMeta)

			pipeline := shadercross.CompileComputePipelineFromSPIRV(render.device, {
				bytecode=cast([^]u8)spirv,
				bytecode_size=spirvSize,
				entrypoint="main",
				shader_stage=stage,
			}, computeMeta^, 0)
			assertf(pipeline != nil, "GPU compute pipeline '%s' failed to compile! %s", assetName, sdl3.GetError())

			strmap_set(&render._compute_shader_pipelines_map, name, pipeline)
			return
		}

		//reflection fills in the resource counts CreateGPUShader would otherwise need by hand
		meta := shadercross.ReflectGraphicsSPIRV(cast([^]u8)spirv, spirvSize, 0)
		assertf(meta != nil, "Shader reflection failed (%s): %s", assetName, sdl3.GetError())
		defer sdl3.free(meta)

		compiled := shadercross.CompileGraphicsShaderFromSPIRV(render.device, {
			bytecode=cast([^]u8)spirv,
			bytecode_size=spirvSize,
			entrypoint="main",
			shader_stage=stage,
		}, meta.resource_info, 0)
		assertf(compiled != nil, "GPU shader '%s' failed to compile! %s", assetName, sdl3.GetError())

		if stage == .VERTEX{
			strmap_set(&render._vert_shaders_map, name, compiled)
			if name == "quad" do render._quad_vert_shader = compiled
			else if name == "mesh" do render._mesh_vert_shader = compiled
			return
		}

		shaderInd,_ := union_variant_index_by_name(ShaderParams, format("Sh_%s", string_capitalize(name, context.temp_allocator)))
		sh := &render._shaders_array[shaderInd]
		sh.name = clone(name, assets.allocator)
		sh.ptr = compiled
		sh.samplerCount = meta.resource_info.num_samplers
		sh.storageBufferCount = meta.resource_info.num_storage_buffers
		reflect.set_union_variant_raw_tag(sh._renderParams, shaderInd)
	}

	//data is the path to the intermediate .hlsl file
	_shader_hot_reload :: proc(data:[]u8){
		hlslFilePath := string(data)
		assetName := filepath.stem(hlslFilePath)
		shaderName := assetName[:len(assetName)-5]
		printf("Hot-reloading shader '%s'...", assetName)

		hlslFileData,_ := os.read_entire_file(hlslFilePath, context.temp_allocator)

		_ = sdl3.WaitForGPUIdle(render.device)

		if string_has_suffix(assetName, ".comp"){
			oldPipeline := render._compute_shader_pipelines_map[shaderName]
			_shader_load(hlslFileData, assetName)
			if oldPipeline != nil{
				for &dispatch in render._compute_dispatches{
					if dispatch.pipeline == oldPipeline do dispatch.pipeline = render._compute_shader_pipelines_map[shaderName]
				}
				sdl3.ReleaseGPUComputePipeline(render.device, oldPipeline)
			}
			return
		}

		old:^sdl3.GPUShader
		isVert := string_has_suffix(assetName, ".vert")
		if isVert do old = render._vert_shaders_map[shaderName]
		else{
			ind, found := union_variant_index_by_name(ShaderParams, format("Sh_%s", string_capitalize(shaderName, context.temp_allocator)))
			if found do old = render._shaders_array[ind]
		}

		staleKeys := make([dynamic]RenderPipelineKey, context.temp_allocator)
		for key in render._pipelines_map{
			if key.vertShader == old || key.fragShader == old do append(&staleKeys, key)
		}
		for key in staleKeys{
			sdl3.ReleaseGPUGraphicsPipeline(render.device, render._pipelines_map[key])
			delete_key(&render._pipelines_map, key)
		}
		if old != nil do sdl3.ReleaseGPUShader(render.device, old)

		_shader_load(hlslFileData, assetName)
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
					sdl3.ShowSimpleMessageBox({.ERROR}, "Diorama Break", string_to_cstring(format("Error: Cannot load more than %i dialogue localization files! Delete some!!", LOCALES_MAX), context.temp_allocator), nil)
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
		page:^sdl3.Texture,
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
			assetDataPtr = sdl3.LoadFile(rawptr(packFileCstr), &assetFileSize)
		}
		defer sdl3.free(assetDataPtr) //TODO: this needs to be freed at the end of game_init, not at the end of this proc
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

