package massimodin //@nested-tags:engine/visuals

import gl "vendor:OpenGL"

PalSwapData :: struct{
	size:Vec2i,
	colors:[dynamic][3]f32
}

PalSwapBlendmode :: enum i32{
	replace,
	multiply,
	hardLight
}


pal_swap_set_swap_data:: proc(swapData:PalSwapData, index:f32, alwaysApplyWithShortestDistance:=false, blendmode:=PalSwapBlendmode.replace){

	indexIntf, indexFrac := split(index)
	index1 := int(indexIntf) % swapData.size.x
	index2 := (index1 == swapData.size.x - 1) ? 0 : index1+1
	index1 *= swapData.size.y
	index2 *= swapData.size.y

	shader_set(sh.palSwap)
	
	palSize := i32(swapData.size.y)
	shader_uniform_set(sh.palSwap, "paletteSize", palSize)
	gl.Uniform3fv(shader_uniform_loc(sh.palSwap, "sourceColors"), palSize, &swapData.colors[0][0])
	gl.Uniform3fv(shader_uniform_loc(sh.palSwap, "destColors1"), palSize, &swapData.colors[index1][0])
	gl.Uniform3fv(shader_uniform_loc(sh.palSwap, "destColors2"), palSize, &swapData.colors[index2][0])
	shader_uniform_set(sh.palSwap, "alwaysApplyWithShortestDistance", alwaysApplyWithShortestDistance)
	shader_uniform_set(sh.palSwap, "blendmode", i32(blendmode))
	shader_uniform_set(sh.palSwap, "destMix", indexFrac)

	//print(swapData, index)

}
pal_swap_set_sprite :: proc(paletteSprite:^Sprite, index:f32, alwaysApplyWithShortestDistance:=false, blendmode:=PalSwapBlendmode.replace){

	swapData, ok := shaders._pal_swap_sprite_map[paletteSprite]

	assertf(ok, "Could not retrieve palette swap data for palette sprite '%s'!", paletteSprite.name)

	pal_swap_set_swap_data(swapData, index, alwaysApplyWithShortestDistance, blendmode)
}



// pal_swap_set_tex :: proc(palette:Tex, index:f32){
// 	//convert tex to palswapdata 
// }

pal_swap_set :: proc{pal_swap_set_swap_data, pal_swap_set_sprite}


add_fade_set :: proc(amount:f32){
	shader_set(sh.addFade)
	shader_uniform_set(sh.addFade, "add", amount)
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

fuzzy_circle_draw :: proc(c:Circle, density:f32, thickMin:f32, thickMax:f32, color:=COLOR_WHITE, alpha:=1){
	draw_color(color, u8(alpha*255))
	circ := circumference(c)
	lineCount := roundi(circ*density)
	for n in 0..<lineCount{
		length := random_range(thickMin, thickMax)
		dir := vec2_random()
		p1 := c.pos+dir*(c.radius-length/2)
		p2 := c.pos+dir*(c.radius+length/2)
		draw_line(p1, p2)
	}
}
