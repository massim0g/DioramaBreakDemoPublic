package massimodin //@nested-tags:engine/visuals

import "../sdl2"

Blend :: [4]u8
Color :: [3]u8
BlendF :: [4]f32 //0-1 normalized
ColorF :: [3]f32 

COLOR_WHITE		:: Color{0xFF, 0xFF, 0xFF}
COLOR_GRAY		:: Color{0x80, 0x80, 0x80}
COLOR_BLACK 	:: Color{0x00, 0x00, 0x00}
COLOR_RED 		:: Color{0xFF, 0x00, 0x00}
COLOR_GREEN 	:: Color{0x00, 0xFF, 0x00}
COLOR_BLUE 		:: Color{0x00, 0x00, 0xFF}
COLOR_CYAN 		:: Color{0x00, 0xFF, 0xFF}
COLOR_YELLOW 	:: Color{0xFF, 0xFF, 0x00}
COLOR_MAGENTA 	:: Color{0xFF, 0x00, 0xFF}

//depth at which the floor draws, invert it to get the min (foreground) depth.
DEPTH_MAX:f32 : 100_000 

BlendData :: struct{
	color:Color,
	alpha:f32,
	blendmode:BlendMode
}

DrawQuad :: struct{ //stores info to be passed to RenderGeometryRaw; to be kept in an soa array
	quad:[4]Vec2,
	colors:[4]sdl2.Color,
	uvs:[4]Vec2,
	indices:[6]i32
}

BLEND_DATA_DEFAULT :: BlendData{COLOR_WHITE, 1, .blend}

draw_color_u8 :: #force_inline proc "contextless" (r,g,b:u8, a:u8=255){
	sdl2.SetRenderDrawColor(display._renderer, r, g, b, a)
	display.draw_color = Color{r,g,b}
	display.draw_alpha = a
}
draw_color_color :: #force_inline proc "contextless" (c:Color, a:u8=255){
	sdl2.SetRenderDrawColor(display._renderer, c.r, c.g, c.b, a)
	display.draw_color = c
	display.draw_alpha = a
}
draw_color :: proc{draw_color_u8, draw_color_color}

draw_blendmode :: #force_inline proc(b:BlendMode){
	sdl2.SetRenderDrawBlendMode(display._renderer, display.custom_blendmodes[b])
}

color_f :: #force_inline proc "contextless"(r,g,b:f32)->Color{ return Color{u8(round(r*255)), u8(round(g*255)), u8(round(b*255))}}
color_f_arr :: #force_inline proc "contextless"(c:ColorF)->Color{ return color_f(c.r,c.g,c.b)}
color_hex :: #force_inline proc "contextless" (hexcode:u32) -> Color{ //converts a hexcode to a color
	out := transmute([4]u8)hexcode
	return Color{out.b, out.g, out.r}
}
color :: proc{color_f, color_f_arr, color_hex}

color_lerp :: proc "contextless" (c1,c2:Color, amount:f32, curve:^Curve=nil) -> Color{
	newCol:ColorF = lerp(ColorF(c1), ColorF(c2), amount, curve)
	return Color{u8(round(newCol.r)), u8(round(newCol.g)), u8(round(newCol.b))}
}
color_mul :: proc "contextless" (c1,c2:Color) -> Color{
	c1f := ColorF(c1)/255
	c2f := ColorF(c2)/255
	newCol := c1f*c2f*255
	return Color{u8(round(newCol.r)), u8(round(newCol.g)), u8(round(newCol.b))}
}

color_to_f :: proc(c:Color)->ColorF{ return ColorF(c)/255 }
blend_to_f :: proc(c:Blend)->BlendF{ return BlendF(c)/255 }
blend_from_f :: proc(c:BlendF)->Blend{ return Blend{u8(round(c.r*255)), u8(round(c.g*255)), u8(round(c.b*255)), u8(round(c.a*255))}}

draw_clear :: #force_inline proc "contextless" (col:=COLOR_WHITE, alpha:u8=255){
	lastCol := display.draw_color
	lastAlpha := display.draw_alpha
	draw_color(col, alpha)
	sdl2.RenderClear(display._renderer)
	draw_color(lastCol, lastAlpha)
}