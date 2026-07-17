package massimodin_builder

import "core:mem"
import "core:os"
import "core:bytes"
import "core:path/filepath"

PackedAssetKind :: enum{
	fontPageIndex,
	fontPage,
	shader,
	curve,
	stage
}

pipeline_packer_run :: proc(pipeline:^Pipeline, fullRebuild:bool){
	print("STARTING ASSET PACK...")

	//set asset subdirectories
	assetDirs := [PackedAssetKind]string{ //relative to the build dir
		.fontPageIndex = "font_page_indexes",
		.fontPage = "font_pages",
		.shader = "shaders",
		.curve = "curves",
		.stage = "stages"
	}

	//output buffer
	outBuffer:bytes.Buffer
	bytes.buffer_init_allocator(&outBuffer, 0, mem.Megabyte*128)

	for assetType in PackedAssetKind{
		printf("Packing %v...", assetType)

		fullDir, _ := filepath.join({paths.build, assetDirs[assetType]})
		dirHandle, err := os.open(fullDir)
		defer os.close(dirHandle)

		if err != nil{
			printf("WARNING: Could not open %v directory, skipping", assetType)
			write_v(&outBuffer, u32(0))
			continue
		}

		dirInfo, err2 := os.read_all_directory(dirHandle, context.temp_allocator)

		if err2 != nil{
			printf("WARNING: Could not read %v directory, skipping", assetType)
			write_v(&outBuffer, u32(0))
			continue
		}

		write_v(&outBuffer, u32(len(dirInfo)))

		for fi in dirInfo{
			assetName := filepath.stem(fi.name)
			nameBytes := transmute([]u8)assetName
			fileData, readErr := os.read_entire_file(fi.fullpath, context.temp_allocator)
			if readErr != nil{
				//write an empty entry so the count stays truthful, otherwise the reader desyncs and misparses everything after it
				printf("WARNING: Failed to read asset to pack '%s', writing empty entry!", assetName)
				write_v(&outBuffer, u16(0))
				write_v(&outBuffer, u64(0))
				continue
			}

			write_v(&outBuffer, u16(len(nameBytes)))
			write_v(&outBuffer, u64(len(fileData)))
			bytes.buffer_write(&outBuffer, nameBytes)
			bytes.buffer_write(&outBuffer, fileData)
		}
	}

	outputFile, _ := filepath.join({paths.build_win64, "assets.mopak"})
	_ = os.write_entire_file(outputFile, bytes.buffer_to_bytes(&outBuffer))

	printf("ASSETS PACK DONE!")
}
