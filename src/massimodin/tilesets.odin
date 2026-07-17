package massimodin //@nested-tags:engine/sprites

TilesetSystem :: struct{
	_tilesets_map:map[string]Tileset,
	names:[dynamic]string
}
tilesets:^TilesetSystem

_tileset_system_init :: proc(){
	tilesets = new(TilesetSystem)
	init(&tilesets._tilesets_map, assets.allocator)
	init(&tilesets.names, assets.allocator)
}

Tileset :: struct{
	sprite:^Sprite,
	tileSize:Vec2i,
}

//return the tileset associated to a specific sprite
tileset_get :: proc(sprite:^Sprite) -> ^Tileset{
	assertf(sprite.name in tilesets._tilesets_map, "No tileset associated with sprite '%s'!", sprite.name)
	return &tilesets._tilesets_map[sprite.name]
}

tileset_len :: #force_inline proc(tileset:^Tileset) -> int{
	return int(ceil(tileset.sprite.size.x/f32(tileset.tileSize.x))*ceil(tileset.sprite.size.y/f32(tileset.tileSize.y)))
}

tileset_grid_size :: #force_inline proc "contextless" (tileset:^Tileset) -> Vec2i{
	return ceili(tileset.sprite.size/Vec2(tileset.tileSize))
}

tileset_tile_rect :: #force_inline proc(tileset:^Tileset, tileIndex:int) -> Rect{
	tileSize := Vec2(tileset.tileSize)
	tileIndf := f32(tileIndex)
	gridSize := tileset.sprite.size/tileSize.x
	return rect_make(tileSize.x*mod(tileIndf, gridSize.x), floor(tileIndf/gridSize.x)*tileSize.y, tileSize.x, tileSize.y)
}

_reload_tilesets :: proc(){
	ts :: proc(sprite:^Sprite, tileSize:Vec2i, padding:=0){
		tilesets._tilesets_map[sprite.name] = Tileset{sprite, tileSize}
		append(&tilesets.names, sprite.name)
	}

	clear(&tilesets._tilesets_map)
	clear(&tilesets.names)
	ts(sp.nil_, {1,1})
	ts(sp.sandTileTest, {24,24})
	ts(sp.testTileset, {16,16})
	ts(sp.debugTileset, {24,24})
	ts(sp.floorTiles, {48,48})
	ts(sp.cargoLiftTiles, {48,20})
	ts(sp.grassTileset, {48,48})
	ts(sp.townHallTileset, {48,48})
	ts(sp.townCenterTileset, {48,48})
	ts(sp.railingsTileset, {48,48})
	ts(sp.woodSupportTileset, {48,48})
	ts(sp.irisTilesetSand, {48,48})
	ts(sp.irisTilesetGrass, {48,48})
	ts(sp.oceanTilePlaceholder, {32,32})
	ts(sp.irisTilesetSky, {16,16})
	ts(sp.waveCrest, {16,16})
	ts(sp.irisTilesetSand_dim, {48,48})
	ts(sp.irisTilesetGrass_dim, {48,48})
	ts(sp.oceanTilePlaceholder_dim, {32,32})
	ts(sp.irisTilesetSky_dim, {16,16})
	ts(sp.waveCrest_dim, {16,16})
	
}