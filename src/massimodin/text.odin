package massimodin 
//@nested-tags:engine/visuals
//@nested-tags:engine/text

import "../sdl3"
import "core:bytes"
import "core:strings"

FontSystem :: struct{
	_fonts_map:map[string]Font,
	_pages:map[string]FontPage,
	_font_sizeless_map:map[string][dynamic]^Font,

	default:^Font
}
fonts:^FontSystem
_text_system_init :: proc(){
	fonts = new(FontSystem)
	fo = new(FontIDs, assets.allocator)

	init(&fonts._fonts_map, assets.allocator)
	init(&fonts._font_sizeless_map, assets.allocator)
	init(&fonts._pages, assets.allocator)
}

Font :: struct{
	runeMap:map[rune]Rect,
	name:string,
	sizelessName:string,
	size:int,
	page:^sdl3.GPUTexture,
	pageHD:bool
}

FontPage :: struct{
	using texture:^sdl3.GPUTexture,
	loadState:TexturePageLoadState,
	hd:bool
}

//{-1,-1}: left-top, {0,0}: centered, {1,-1}: right-top, {0, 1}: middle-bottom, etc.
Alignment :: [2]i8 


//Warning: Slow. If making many calls, prefer drawing *from cached fonts* using text_draw.
// text_draw_to_tex :: proc(text:string, color:Color, alpha:u8=255, font:^Font=nil) -> Tex{
// 	assert(_font_active != nil, "Trying to render text with no active font!")
// 	cText := strings.clone_to_cstring(text)
// 	defer delete(cText)
	
// 	renderSurf := ttf.RenderUTF8_Solid(_font_active, cText, sdl3.Color{color.r, color.g, color.b, alpha})
// 	if(renderSurf == nil){ //can happen if the active font's point size is too small or unsupported, just return an empty texture
// 		return Tex{
// 			sdl3.CreateTexture(display._renderer, u32(sdl3.PixelFormatEnum.RGBA8888), sdl3.TextureAccess.STATIC, 1, 1),
// 			1, 1
// 		}
// 	} 
// 	defer sdl3.FreeSurface(renderSurf)

// 	return Tex{
// 		sdl3.CreateTextureFromSurface(display._renderer, renderSurf),
// 		int(renderSurf.w), int(renderSurf.h)
// 	}
// }


text_draw_vec2 :: proc(text:string, pos:Vec2, color:Color=COLOR_WHITE, alpha:f32=1, font:^Font=nil, alignment:Alignment=-1){
	font := font
	if(font == nil) do font = fonts.default
	assert(font != nil, "Trying to render text with no set font!")

	blend := color_to_blend(color, alpha)
	sampler :SamplerKind= font.pageHD ? .linearMip : .nearest
	uvScale := 1.0/f32(FONT_PAGE_SIZE)

	dst := floor(pos)

	if alignment != -1{
		textHalfSize := floor(text_size(text, font)/2)
		dst.x -= (f32(alignment.x)+1)*textHalfSize.x
		dst.y -= (f32(alignment.y)+1)*textHalfSize.y
	}

	runeMap := font.runeMap
	for r in text{
		if r == '\n'{
			dst.x = floor(pos.x)
			dst.y += runeMap['M'].size.y
			continue
		}
		src := runeMap[r]
		render_quad(font.page, sampler, Quad{
			worldRect = {dst, src.size},
			uvRect = {
				src.x*uvScale, src.y*uvScale,
				(src.x+src.size.x)*uvScale, (src.y+src.size.y)*uvScale,
			},
			blend = blend,
		})
		dst.x += src.size.x
	}
}
text_draw_i :: #force_inline proc(text:string, #any_int x:i32, #any_int y:i32, color:Color=COLOR_WHITE, alpha:f32=1, font:^Font=nil, alignment:Alignment=-1){
	text_draw_vec2(text, Vec2{f32(x), f32(y)}, color, alpha, font, alignment)
	
}
text_draw_f :: #force_inline proc(text:string, x,y:f32, color:Color=COLOR_WHITE, alpha:f32=1, font:^Font=nil, alignment:Alignment=-1){
	text_draw_vec2(text, Vec2{x, y}, color, alpha, font, alignment)
}
//Defaults to fonts.default
text_draw :: proc{text_draw_vec2, text_draw_i, text_draw_f}

char_size :: proc(char:rune, font:^Font=nil) -> Vec2{
	font := font
	if(font == nil) do font = fonts.default
	return font.runeMap[char].size
}

text_size :: proc(text:string, font:^Font=nil) -> Vec2{
	font := font
	if(font == nil) do font = fonts.default
	assert(font != nil, "Trying to get text size with no set font!")

	runeMap := font.runeMap
	width:f32
	out:Vec2
	for r in text{
		if r == '\n'{
			out.x = max(width, out.x)
			width = 0
			out.y += runeMap['M'].size.y
			continue
		}
		width += runeMap[r].size.x
	}
	out.x = max(width, out.x)
	out.y += runeMap['M'].size.y
	return out
}

text_rect :: proc(text:string, pos:Vec2, alignment:Alignment=-1, font:^Font=nil) -> Rect{
	out := Rect{pos, text_size(text, font)}

	if alignment != -1{
		textHalfSize := out.size/2
		out.pos.x -= (f32(alignment.x)+1)*textHalfSize.x
		out.pos.y -= (f32(alignment.y)+1)*textHalfSize.y
	}

	return out
}

//returns the height of the highest possible character based on the current text rendering settings
text_char_height :: proc(font:^Font=nil) -> f32{
	return char_size('M', font).y
}


font_find :: proc(name:string) -> (font:^Font, found:bool){
	return &fonts._fonts_map[name]
}

font_bolditalic_get :: proc(f:^Font, boldItalic:[2]bool) -> ^Font{
	if(boldItalic == [2]bool{}) do return f


	newFontName := format("%s%s%s__%i", f.sizelessName, boldItalic[0] ? "Bold":"", boldItalic[1] ? "Italic":"", f.size)

	newFont, found := font_find(newFontName)
	if !found do return f
	//assertf(found, "Could not find matching bolditalic font '%s'", newFontName)
	return newFont
}