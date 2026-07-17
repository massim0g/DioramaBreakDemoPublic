package massimodin //@nested-tags:engine/visuals

import "../sdl2"
import "core:math"

draw_point_f :: #force_inline proc(x,y:f32){
	sdl2.RenderDrawPointF(display._renderer, x, y)
}
draw_point_i :: #force_inline proc(x,y:int){
	sdl2.RenderDrawPoint(display._renderer, i32(x), i32(y))
}
draw_point_vec2 :: #force_inline proc(p:Vec2){
	draw_point_f(p.x, p.y)
}
draw_point :: proc{draw_point_f, draw_point_i, draw_point_vec2}

draw_line_f :: #force_inline proc "contextless" (x1,y1,x2,y2:f32){
	cp := camera_pos()
	sdl2.RenderDrawLineF(display._renderer, x1-cp.x, y1-cp.y, x2-cp.x, y2-cp.y)
}
draw_line_i :: #force_inline proc "contextless" (x1,y1,x2,y2:int){
	sdl2.RenderDrawLine(display._renderer, i32(x1)-camera.pos.x,i32(y1)-camera.pos.y,i32(x2)-camera.pos.x,i32(y2)-camera.pos.y)
}
draw_line_vec2 :: #force_inline proc "contextless" (p1,p2:Vec2){
	draw_line_f(p1.x, p1.y, p2.x, p2.y)
}
draw_line_line :: #force_inline proc "contextless" (l:Line){
	draw_line_vec2(l[0], l[1])
}
draw_line :: proc{draw_line_f, draw_line_i, draw_line_vec2, draw_line_line}

draw_rect_f :: #force_inline proc(x1,y1,x2,y2:f32, color:Color, alpha:f32=1, blendmode:=BlendMode.blend){
	sprite_draw_ex(sp.white1, x1, y1, 0, Vec2{x2-x1+1, y2-y1+1}, 0, color, alpha, blendmode)
}
draw_rect_i :: #force_inline proc(x1,y1,x2,y2:int, color:Color, alpha:f32=1, blendmode:=BlendMode.blend){
	draw_rect_f(f32(x1), f32(y1), f32(x2), f32(y2), color, alpha, blendmode)
}
draw_rect_vec2 :: #force_inline proc(p1,p2:Vec2, color:Color, alpha:f32=1, blendmode:=BlendMode.blend){
	draw_rect_f(p1.x, p1.y, p2.x, p2.y, color, alpha, blendmode)
}
draw_rect_rectf :: #force_inline proc(drawRect:Rect, color:Color, alpha:f32=1, blendmode:=BlendMode.blend){
	draw_rect_f(drawRect.x, drawRect.y, rect_get_right(drawRect), rect_get_bottom(drawRect), color, alpha, blendmode)
} 
draw_rect_recti :: #force_inline proc(drawRect:Recti, color:Color, alpha:f32=1, blendmode:=BlendMode.blend){
	draw_rect_i(drawRect.x, drawRect.y, rect_get_right(drawRect), rect_get_bottom(drawRect), color, alpha, blendmode)
} 
//Draws a rectangle using sprite data.
draw_rect :: proc{draw_rect_f, draw_rect_i, draw_rect_vec2, draw_rect_rectf, draw_rect_recti}

draw_rect_outline_f :: proc(x1,y1,x2,y2:f32, color:Color, alpha:f32=1, thickness:=1, blendmode:=BlendMode.blend){
	frame := sp.white1.frames[0]

	thickness := i32(thickness)
	x1 := i32(x1) - camera.pos.x
	y1 := i32(y1) - camera.pos.y
	x2 := i32(x2) - camera.pos.x
	y2 := i32(y2) - camera.pos.y
	w := x2 - thickness - x1 + 1
	h := y2 - thickness - y1 + 1


	sdl2.SetTextureColorMod(frame.texturePage, color.r, color.g, color.b)
	sdl2.SetTextureAlphaMod(frame.texturePage, u8(clamp(alpha*255, 0, 255)))
	sdl2.SetTextureBlendMode(frame.texturePage, display.custom_blendmodes[blendmode])
	
	dst := sdl2.Rect{x1, y1, w, thickness}
	sdl2.RenderCopy(display._renderer, frame.texturePage, &frame.texturePagePos, &dst)
	dst = sdl2.Rect{x2-thickness+1, y1, thickness, h}
	sdl2.RenderCopy(display._renderer, frame.texturePage, &frame.texturePagePos, &dst)
	dst = sdl2.Rect{x1+thickness, y2-thickness+1, w, thickness}
	sdl2.RenderCopy(display._renderer, frame.texturePage, &frame.texturePagePos, &dst)
	dst = sdl2.Rect{x1, y1+thickness, thickness, h}
	sdl2.RenderCopy(display._renderer, frame.texturePage, &frame.texturePagePos, &dst)
}
draw_rect_outline_i :: #force_inline proc(x1,y1,x2,y2:int, color:Color, alpha:f32=1, thickness:=1, blendmode:=BlendMode.blend){
	draw_rect_outline_f(f32(x1), f32(y1), f32(x2), f32(y2), color, alpha, thickness, blendmode)
}
draw_rect_outline_vec2 :: #force_inline proc(p1,p2:Vec2, color:Color, alpha:f32=1, thickness:=1, blendmode:=BlendMode.blend){
	draw_rect_outline_f(p1.x, p1.y, p2.x, p2.y, color, alpha, thickness, blendmode)
}
draw_rect_outline_rectf :: #force_inline proc(drawRect:Rect, color:Color, alpha:f32=1, thickness:=1, blendmode:=BlendMode.blend){ //lol
	draw_rect_outline_f(drawRect.x, drawRect.y, rect_get_right(drawRect), rect_get_bottom(drawRect), color, alpha, thickness, blendmode)
} 
draw_rect_outline_recti :: #force_inline proc(drawRect:Recti, color:Color, alpha:f32=1, thickness:=1, blendmode:=BlendMode.blend){ //lol
	draw_rect_outline_i(drawRect.x, drawRect.y, rect_get_right(drawRect), rect_get_bottom(drawRect), color, alpha, thickness, blendmode)
} 
//Draws a rectangle outline using sprite data.
draw_rect_outline :: proc{draw_rect_outline_f, draw_rect_outline_i, draw_rect_outline_vec2, draw_rect_outline_rectf, draw_rect_outline_recti}

draw_rect_gradient :: proc(rect:Rect, cornerBlends:[4]Blend) {
	cam := camera_pos()
	x := rect.x - cam.x
	y := rect.y - cam.y
	w := rect.size.x
	h := rect.size.y

	// Vertices: TL(0), TR(1), BR(2), BL(3)
	verts:=[4]sdl2.Vertex{
		{{x,     y    }, transmute(sdl2.Color)cornerBlends[0], {}},
		{{x + w, y    }, transmute(sdl2.Color)cornerBlends[1], {}},
		{{x + w, y + h}, transmute(sdl2.Color)cornerBlends[2], {}},
		{{x,     y + h}, transmute(sdl2.Color)cornerBlends[3], {}}
	}

	// Indices for two triangles: (0,1,2) and (0,2,3)
	idx:=[6]i32{0,1,2,0,2,3}

	sdl2.RenderGeometry(
		display._renderer,
		nil,
		raw_data(&verts),
		4,
		raw_data(&idx),
		6,
	)
}

draw_triangle_f :: proc(x1,y1,x2,y2,x3,y3:f32, blends:[3]Blend){
	camPos := camera_pos()
	vertices := [3]sdl2.Vertex{
		{{x1-camPos.x, y1-camPos.y}, transmute(sdl2.Color)blends[0], {}},
		{{x2-camPos.x, y2-camPos.y}, transmute(sdl2.Color)blends[1], {}},
		{{x3-camPos.x, y3-camPos.y}, transmute(sdl2.Color)blends[2], {}}
	}

	sdl2.RenderGeometry(display._renderer, nil, raw_data(vertices[:]), 3, nil, 0)
}
draw_triangle_i :: #force_inline proc(x1,y1,x2,y2,x3,y3:int, blends:[3]Blend){
	draw_triangle_f(f32(x1),f32(y1),f32(x2),f32(y2),f32(x3),f32(y3), blends)
}
draw_triangle_vec2 :: #force_inline proc(p1,p2,p3:Vec2, blends:[3]Blend){
	draw_triangle_f(p1.x, p1.y, p2.x, p2.y, p3.x, p3.y, blends)
}
draw_triangle :: proc{draw_triangle_f, draw_triangle_i, draw_triangle_vec2}

draw_circle_f :: proc(x,y,r:f32, precision:f32=1)  {
	camPos := camera_pos()
	x:=x;y:=y
	x -= camPos.x
	y -= camPos.y
	
	//get render color
	color:sdl2.Color
	sdl2.GetRenderDrawColor(display._renderer, &color.r, &color.g, &color.b, &color.a)
	
    //determine the number of segments based on the circumference and precision
	//higher precision is more expensive, especially as the circle grows larger
    segments := max(i32(math.TAU*r*precision), 1)
	
	//RenderGeometry data
	vertices := make([dynamic]sdl2.Vertex, segments+1, context.temp_allocator)
	indices := make([dynamic]i32, segments*3, context.temp_allocator)

	//add center vertex
	vertices[0] = {{x,y}, color, {}}

	//determine circle edge vertices and vertex render order
	angle:f32 = 0
	angleIncr:f32 = math.TAU/f32(segments)
	for i:i32=1;i<segments+1;i+=1{
		vertices[i] = {{x+r*math.cos(angle),y+r*math.sin(angle)}, color, {}}
		
		indices[i*3-3] = 0
		indices[i*3-2] = i
		indices[i*3-1] = i+1
		angle += angleIncr
	}

	//set last index to first edge vertex
	indices[segments*3-1] = 1

	//render
	sdl2.RenderGeometry(display._renderer, nil, raw_data(vertices[:]), segments+2, raw_data(indices[:]), segments*3)
}
draw_circle_i :: #force_inline proc(x,y,r:int, precision:f32=1){
	draw_circle_f(f32(x), f32(y), f32(r), precision)
}
draw_circle_vec2 :: #force_inline proc(p:Vec2, r:f32, precision:f32=1){
	draw_circle_f(p.x, p.y, r, precision)
}
draw_circle_circle :: #force_inline proc(c:Circle, precision:f32=1){
	draw_circle_f(c.x, c.y, c.radius, precision)
}
draw_circle :: proc{draw_circle_f, draw_circle_i, draw_circle_vec2, draw_circle_circle}

draw_ellipse_vec2 :: proc(center:Vec2, radii:Vec2, innerCol:=COLOR_WHITE, outerCol:=COLOR_WHITE, innerAlpha:f32=1, outerAlpha:f32=1, precision:f32=1) {
    center := center
	center -= camera_pos()


	innerBlend := sdl2.Color{innerCol.r, innerCol.g, innerCol.b, u8(innerAlpha*255)}
	outerBlend := sdl2.Color{outerCol.r, outerCol.g, outerCol.b, u8(outerAlpha*255)}

    // Segment count via Ramanujan I circumference approx
    a := abs(radii.x)
    b := abs(radii.y)
    circ := PI * (3*(a+b) - sqrt((3*a + b) * (a + 3*b)))
    segs := max(i32(floor(circ * precision)), 3)

    // Buffers: center + segs perimeter verts; 3 indices/segment (tri fan)
    vertices := make([dynamic]sdl2.Vertex, segs+1, context.temp_allocator)
    indices  := make([dynamic]i32, segs*3, context.temp_allocator)

    // Center
    vertices[0] = sdl2.Vertex{position = sdl2.FPoint{center.x, center.y}, color = innerBlend}

    // Perimeter + indices
    angle: f32 = 0
    angleIncr := TAU/f32(segs)
    for i: i32 = 1; i <= segs; i += 1 {
        sx := center.x + radii.x*math.cos(angle)
        sy := center.y + radii.y*math.sin(angle)
        vertices[i] = sdl2.Vertex{position = sdl2.FPoint{sx, sy}, color = outerBlend}

        base := i*3 - 3
        indices[base+0] = 0
        indices[base+1] = i
        indices[base+2] = i + 1

        angle += angleIncr
    }
    // Close fan back to first perimeter vertex (1)
    indices[len(indices)-1] = 1
	
    sdl2.RenderGeometry(
        display._renderer,
        shaders.blank_tex,
        raw_data(vertices[:]),
        i32(len(vertices)),
        raw_data(indices[:]),
        i32(len(indices)),
    )
}
draw_ellipse_rect :: #force_inline proc(r:Rect, innerCol:=COLOR_WHITE, outerCol:=COLOR_WHITE, innerAlpha:f32=1, outerAlpha:f32=1, precision: f32 = 1){
	draw_ellipse_vec2(rect_center(r), r.size/2, innerCol, outerCol, innerAlpha, outerAlpha, precision)
}
draw_ellipse_ellipse :: #force_inline proc(e:Ellipse, innerCol:=COLOR_WHITE, outerCol:=COLOR_WHITE, innerAlpha:f32=1, outerAlpha:f32=1, precision: f32 = 1){
	draw_ellipse_vec2(e.pos, e.radii, innerCol, outerCol, innerAlpha, outerAlpha, precision)
}
draw_ellipse :: proc{draw_ellipse_vec2, draw_ellipse_rect, draw_ellipse_ellipse}

//radii are outer to inner
draw_rings :: proc(center:Vec2, radii:[]Vec2, colors:[]Color=nil, alphas:[]f32=nil, precision:f32=1) {
    center := center
	center -= camera_pos()

	N :i32= 0
	for &r in radii{
		N += 1
		if max(r) <= 0{
			r = max(r, Vec2{0,0})
			break
		}
	}

    cols := make([]sdl2.Color, N, context.temp_allocator)
	for i in 0..<N{
		c := (colors!=nil && i32(len(colors))>i) ? colors[i] : COLOR_WHITE
		a := (alphas!=nil && i32(len(alphas))>i) ? alphas[i] : 1
		cols[i] = sdl2.Color{c.r, c.g, c.b, u8(a*255)}
	} 

	a := abs(radii[0].x)
    b := abs(radii[0].y)
    circ := PI * (3*(a+b) - sqrt((3*a + b)*(a + 3*b)))
    segs := max(i32(floor(circ*precision)), 3)

    verts  := make([dynamic]sdl2.Vertex, N*(segs + 1),  context.temp_allocator)
    indices := make([dynamic]i32, 6*(N-1)*segs, context.temp_allocator)

    angle:f32=0
    angleIncr := TAU/f32(segs)

    // Generate vertices
    for i:i32 = 0; i <= segs; i+=1{
        cosA := math.cos(angle)
        sinA := math.sin(angle)

		for j in 0..<N{
			verts[N*i+j] = sdl2.Vertex{
				position = sdl2.FPoint{center.x + radii[j].x*cosA, center.y + radii[j].y*sinA},
				color = cols[j]
			}
		}

        angle += angleIncr
    }

    idx := 0
    for s: i32 = 0; s < segs; s += 1 {
        baseCur  := N*s           
        baseNext := N*(s + 1)     
        for b: i32 = 0; b < N-1; b += 1 {
            outer0 := baseCur  + b     
            inner0 := baseCur  + b + 1 
            outer1 := baseNext + b     
            inner1 := baseNext + b + 1 

            // triangle #1
            indices[idx+0] = outer0
            indices[idx+1] = inner0
            indices[idx+2] = outer1
            // triangle #2
            indices[idx+3] = inner0
            indices[idx+4] = outer1
            indices[idx+5] = inner1

            idx += 6
        }
    }

    sdl2.RenderGeometry(
        display._renderer,
        shaders.blank_tex,
        raw_data(verts[:]),
        i32(len(verts)),
        raw_data(indices[:]),
        i32(len(indices)),
    )
}

draw_letterbox :: proc(r:Rect, color:Color, alpha:f32=1, blendmode:=BlendMode.blend){
	r := r
	r.pos -= 1
	br := rect_get_bottom_right_f(r)
	cam := camera_rect()
	camBr := rect_get_bottom_right_f(cam)
	letterBoxRects := [4]Rect{
		rect_make_points(cam.pos-1, Vec2{br.x, r.y}),
		rect_make_points(Vec2{br.x+1, cam.y}, Vec2{camBr.x, br.y}),
		rect_make_points(Vec2{r.x+1, br.y+1}, camBr),
		rect_make_points(Vec2{cam.x-1, r.y+1}, Vec2{r.x, camBr.y})
	}
	for rect,i in letterBoxRects{
		if(rect_is_positive(rect)) do draw_rect(rect, color, alpha, blendmode)
	}
}