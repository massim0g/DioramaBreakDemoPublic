package imgui

// Manually created bindings for certain helpers

Vector :: struct($T: typeid) {
	Size:     i32,
	Capacity: i32,
	Data:     [^]T,
}

// NOTE: Uses bit field. Supporting it manually is easier than auto generating bindings for it.
// Hold rendering data for one glyph.
// (Note: some language parsers may fail to convert the bitfield members, in this case maybe drop store a single u32 or we can rework this)
FontGlyph :: struct {
	using _: bit_field u32 {
		Colored:   u32 | 1, // Flag to indicate glyph is colored and should generally ignore tinting (make it usable with no shift on little-endian as this is used in loops)
		Visible:   u32 | 1, // Flag to indicate glyph has no visible pixels (e.g. space). Allow early out when rendering.
		SourceIdx: u32 | 4, // Index of source in parent font
		Codepoint: u32 | 26, // 0x0000..0x10FFFF
	},
	AdvanceX:  f32, // Horizontal distance to advance cursor/layout position.
	X0:        f32, // Glyph corners. Offsets from current cursor/layout position.
	Y0:        f32, // Glyph corners. Offsets from current cursor/layout position.
	X1:        f32, // Glyph corners. Offsets from current cursor/layout position.
	Y1:        f32, // Glyph corners. Offsets from current cursor/layout position.
	U0:        f32, // Texture coordinates for the current value of ImFontAtlas->TexRef. Cached equivalent of calling GetCustomRect() with PackId.
	V0:        f32, // Texture coordinates for the current value of ImFontAtlas->TexRef. Cached equivalent of calling GetCustomRect() with PackId.
	U1:        f32, // Texture coordinates for the current value of ImFontAtlas->TexRef. Cached equivalent of calling GetCustomRect() with PackId.
	V1:        f32, // Texture coordinates for the current value of ImFontAtlas->TexRef. Cached equivalent of calling GetCustomRect() with PackId.
	PackId:    i32, // [Internal] ImFontAtlasRectId value (FIXME: Cold data, could be moved elsewhere?)
}
