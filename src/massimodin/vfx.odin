package massimodin //@nested-tags:engine/visuals

import "../sdl3"

PalSwapData :: struct{
	size:Vec2i,
	bufferOffset:i32 //element offset of this palette's colors in render._palette_buffer
}

PalSwapBlendmode :: enum i32{
	replace,
	multiply,
	hardLight
}


pal_swap_set :: proc(paletteSprite:^Sprite, index:f32, alwaysApplyWithShortestDistance:=false, blendmode:=PalSwapBlendmode.replace){

	swapData, ok := render._pal_swap_sprite_map[paletteSprite]

	assertf(ok, "Could not retrieve palette swap data for palette sprite '%s'!", paletteSprite.name)

	indexIntf, indexFrac := split(index)
	index1 := int(indexIntf) % swapData.size.x
	index2 := (index1 == swapData.size.x - 1) ? 0 : index1+1
	index1 *= swapData.size.y
	index2 *= swapData.size.y

	//the colors live preloaded in render._palette_buffer; source colours are the palette sprite's first column, the two dest columns are picked by the index
	shader_set(Sh_PalSwap{
		paletteSize = i32(swapData.size.y),
		destMix = indexFrac,
		alwaysApplyWithShortestDistance = i32(alwaysApplyWithShortestDistance),
		blendmode = i32(blendmode),
		sourceOff = swapData.bufferOffset,
		dest1Off = swapData.bufferOffset + i32(index1),
		dest2Off = swapData.bufferOffset + i32(index2),
	})
	shader_buffer_bind("palettes", &render._palettes_buffer)
}


add_fade_set :: proc(amount:f32){
	shader_set(Sh_AddFade{add = amount})
}

tex_ghosts_draw :: proc(drawTex:Tex, ghostCount:int, interval:int, endRot:f32, endScale:f32, scaleCurve:^Curve=nil, t:=time.frame, endFrame:=INT_MAX){
	if t > endFrame do return
	// if centerCut.x >=0 && centerCut.y>=0{
	// 	tex_target_set(drawTex, clear=false)
	// 	cutRect := Rect{0, centerCut}
	// 	cutRect.pos = (DISPLAY_SIZE-cutRect.size)/2
	// 	draw_rect(cutRect, COLOR_WHITE, 1, BlendMode.subtract)
	// 	tex_target_reset()
	// }

	trueT := t
	t := t
	t = t%interval

	alphaInterval := 1/(f32(ghostCount))

	totalDuration := ghostCount*interval

	for n in 0..<ghostCount{
		age := t + n*interval
		remaining := totalDuration - age
		if age >trueT || trueT+remaining > endFrame do continue

		prog := f32(age)/f32(totalDuration)

		alpha := lerp(1,0, prog)
		scale:Vec2 = lerp(1, endScale, prog, scaleCurve)
		rot:= lerp(0, endRot, prog)

		newSize := DISPLAY_SIZE*scale

		tex_draw_ex(drawTex, -(newSize-DISPLAY_SIZE)/2, scale, rot, COLOR_WHITE, alpha, newSize/2)
	}
}

fuzzy_circle_draw :: proc(c:Circle, density:f32, thickMin:f32, thickMax:f32, color:=COLOR_WHITE, alpha:f32=1){
	circ := circumference(c)
	lineCount := roundi(circ*density)
	for n in 0..<lineCount{
		length := random_range(thickMin, thickMax)
		dir := vec2_random()
		p1 := c.pos+dir*(c.radius-length/2)
		p2 := c.pos+dir*(c.radius+length/2)
		draw_line(p1, p2, color=color, alpha=alpha)
	}
}
