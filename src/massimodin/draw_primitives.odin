package massimodin //@nested-tags:engine/visuals

import "core:math"

//Renders an untextured mesh
draw_mesh_blank :: #force_inline proc(verts:[]Vertex){
	render_mesh(render.blank_tex, .nearest, verts)
}

draw_point_f :: proc(x,y:f32, color:=COLOR_WHITE, alpha:f32=1){
	render_quad(render.blank_tex, .nearest, {
		worldRect = {{x, y}, {1, 1}},
		uvRect = {0,0,1,1},
		blend = color_to_blend(color, alpha),
	})
}
draw_point_i :: #force_inline proc(x,y:int, color:=COLOR_WHITE, alpha:f32=1){
	draw_point_f(f32(x), f32(y), color, alpha)
}
draw_point_vec2 :: #force_inline proc(p:Vec2, color:=COLOR_WHITE, alpha:f32=1){
	draw_point_f(p.x, p.y, color, alpha)
}
draw_point :: proc{draw_point_f, draw_point_i, draw_point_vec2}

draw_line_f :: proc (x1,y1,x2,y2:f32, thickness:f32=1, color:=COLOR_WHITE, alpha:f32=1){
	d := Vec2{x2-x1, y2-y1}
	length := sqrt(d.x*d.x + d.y*d.y)
	if length == 0 do return

	halfThickness := thickness/2
	render_quad(render.blank_tex, .nearest, Quad{
		worldRect = {{x1, y1+0.5-halfThickness}, {length+1, thickness}},
		uvRect = {0,0,1,1},
		pivot = {0.5, halfThickness},
		rotation = math.atan2(d.y, d.x),
		blend = color_to_blend(color, alpha),
	})
}
draw_line_i :: #force_inline proc (x1,y1,x2,y2:int, thickness:f32=1, color:=COLOR_WHITE, alpha:f32=1){
	draw_line_f(f32(x1), f32(y1), f32(x2), f32(y2), thickness, color, alpha)
}
draw_line_vec2 :: #force_inline proc (p1,p2:Vec2, thickness:f32=1, color:=COLOR_WHITE, alpha:f32=1){
	draw_line_f(p1.x, p1.y, p2.x, p2.y, thickness, color, alpha)
}
draw_line_line :: #force_inline proc (l:Line, thickness:f32=1, color:=COLOR_WHITE, alpha:f32=1){
	draw_line_vec2(l[0], l[1], thickness, color, alpha)
}
draw_line :: proc{draw_line_f, draw_line_i, draw_line_vec2, draw_line_line}

draw_rect_rectf :: #force_inline proc(drawRect:Rect, color:Color, alpha:f32=1){
	render_quad(render.blank_tex, .nearest, {
		worldRect = drawRect,
		uvRect = {0,0,1,1},
		blend = color_to_blend(color, alpha),
	})
}
draw_rect_f :: #force_inline proc(x1,y1,x2,y2:f32, color:Color, alpha:f32=1){
	p := Vec2{x1,y1}
	draw_rect_rectf(Rect{p, {x2,y2}-p+1}, color, alpha)
}
draw_rect_i :: #force_inline proc(x1,y1,x2,y2:int, color:Color, alpha:f32=1){
	draw_rect_f(f32(x1), f32(y1), f32(x2), f32(y2), color, alpha)
}
draw_rect_vec2 :: #force_inline proc(p1,p2:Vec2, color:Color, alpha:f32=1){
	draw_rect_f(p1.x, p1.y, p2.x, p2.y, color, alpha)
}
draw_rect_recti :: #force_inline proc(drawRect:Recti, color:Color, alpha:f32=1){
	draw_rect_rectf({Vec2(drawRect.pos), Vec2(drawRect.size)}, color, alpha)
}
//Draws a rectangle using sprite data.
draw_rect :: proc{draw_rect_f, draw_rect_i, draw_rect_vec2, draw_rect_rectf, draw_rect_recti}

//Draws a quad covering the whole current target, ignoring the camera. Mainly a carrier for fullscreen shader effects.
draw_rect_fullscreen :: proc(color:=COLOR_WHITE, alpha:f32=1){
	render_quad(render.blank_tex, .nearest, {
		uvRect = {0,0,1,1},
		blend = color_to_blend(color, alpha),
		flags = {.fullscreen},
	})
}

draw_rect_outline_f :: proc(x1,y1,x2,y2:f32, thickness:f32=1, color:Color, alpha:f32=1){
	w := x2 - thickness - x1 + 1
	h := y2 - thickness - y1 + 1

	edges := [4]Rect{
		{{x1, y1}, {w, thickness}},
		{{x2-thickness+1, y1}, {thickness, h}},
		{{x1+thickness, y2-thickness+1}, {w, thickness}},
		{{x1, y1+thickness}, {thickness, h}},
	}
	for e in edges{
		render_quad(render.blank_tex, .nearest, Quad{
			worldRect = e,
			uvRect = {0,0,1,1},
			blend = color_to_blend(color, alpha)
		})
	}
}
draw_rect_outline_i :: #force_inline proc(x1,y1,x2,y2:int, thickness:f32=1, color:Color=COLOR_WHITE, alpha:f32=1){
	draw_rect_outline_f(f32(x1), f32(y1), f32(x2), f32(y2), thickness, color, alpha)
}
draw_rect_outline_vec2 :: #force_inline proc(p1,p2:Vec2, thickness:f32=1, color:Color=COLOR_WHITE, alpha:f32=1){
	draw_rect_outline_f(p1.x, p1.y, p2.x, p2.y, thickness, color, alpha)
}
draw_rect_outline_rectf :: #force_inline proc(drawRect:Rect, thickness:f32=1, color:Color=COLOR_WHITE, alpha:f32=1){
	draw_rect_outline_f(drawRect.x, drawRect.y, rect_get_right(drawRect), rect_get_bottom(drawRect), thickness, color, alpha)
}
draw_rect_outline_recti :: #force_inline proc(drawRect:Recti, thickness:f32=1, color:Color=COLOR_WHITE, alpha:f32=1){
	draw_rect_outline_i(drawRect.x, drawRect.y, rect_get_right(drawRect), rect_get_bottom(drawRect), thickness, color, alpha)
}
//Draws a rectangle outline using sprite data.
draw_rect_outline :: proc{draw_rect_outline_f, draw_rect_outline_i, draw_rect_outline_vec2, draw_rect_outline_rectf, draw_rect_outline_recti}

draw_rect_gradient :: proc(rect:Rect, cornerBlends:[4]Blend) {
	x := rect.x
	y := rect.y
	w := rect.size.x
	h := rect.size.y

	//corners in TL, TR, BR, BL order
	render_mesh_quads(render.blank_tex, .nearest, {{
		quad={{x, y}, {x+w, y}, {x+w, y+h}, {x, y+h}},
		blends=cornerBlends
	}})
}

draw_triangle_f :: proc(x1,y1,x2,y2,x3,y3:f32, blends:[3]Blend){
	verts := [3]Vertex{
		{pos={x1, y1}, blend=blends[0]},
		{pos={x2, y2}, blend=blends[1]},
		{pos={x3, y3}, blend=blends[2]},
	}
	draw_mesh_blank(verts[:])
}
draw_triangle_i :: #force_inline proc(x1,y1,x2,y2,x3,y3:int, blends:[3]Blend){
	draw_triangle_f(f32(x1),f32(y1),f32(x2),f32(y2),f32(x3),f32(y3), blends)
}
draw_triangle_vec2 :: #force_inline proc(p1,p2,p3:Vec2, blends:[3]Blend){
	draw_triangle_f(p1.x, p1.y, p2.x, p2.y, p3.x, p3.y, blends)
}
draw_triangle :: proc{draw_triangle_f, draw_triangle_i, draw_triangle_vec2}

/*
Draws concentric ellipse rings from outermost to innermost, blending colors between consecutive rings per pixel.
Repeated radii create hard color steps.
Rings past a fully collapsed one are dropped, and an innermost radius above zero leaves the center transparent.
All ellipse/circle draws run through this proc.
Softness >0 causes pixels only partially inside the ellipse to be drawn at interpolated fractional alpha, better for HD mode.
*/
draw_rings :: proc(center:Vec2, radii:[]Vec2, colors:[]Color=nil, alphas:[]f32=nil, edgeSoftness:f32=0) {
	params:Sh_Ellipse
	assertf(len(radii) <= len(params.ringRadii), "draw_rings supports at most %v rings, got %v! Move the ring data to a storage buffer if significantly more are ever needed.", len(params.ringRadii), len(radii))
	
	N := 0
	for r in radii{
		c := (colors!=nil && len(colors)>N) ? colors[N] : COLOR_WHITE
		a := (alphas!=nil && len(alphas)>N) ? alphas[N] : 1
		rc := max(r, Vec2{0,0})
		params.ringRadii[N] = {rc.x, rc.y, 0, 0}
		params.ringBlends[N] = blend_to_f(color_to_blend(c, a))
		N += 1
		if max(r) <= 0 do break
	}
	if N < 2 do return

	params.ringCount = i32(N)
	params.edgeSoftness = edgeSoftness

	outer := Vec2{params.ringRadii[0].x, params.ringRadii[0].y}
	pad := edgeSoftness + 1
	rect := Rect{center - outer - pad, outer*2 + pad*2}
	params.rectSize = rect.size

	shader_set(params)
	draw_rect(rect, COLOR_WHITE, 1)
	shader_reset()
}

draw_ellipse_vec2 :: proc(center:Vec2, radii:Vec2, innerCol:=COLOR_WHITE, outerCol:=COLOR_WHITE, innerAlpha:f32=1, outerAlpha:f32=1, edgeSoftness:f32=0) {
	draw_rings(center, {{abs(radii.x), abs(radii.y)}, 0}, {outerCol, innerCol}, {outerAlpha, innerAlpha}, edgeSoftness)
}
draw_ellipse_rect :: #force_inline proc(r:Rect, innerCol:=COLOR_WHITE, outerCol:=COLOR_WHITE, innerAlpha:f32=1, outerAlpha:f32=1, edgeSoftness:f32=0){
	draw_ellipse_vec2(rect_center(r), r.size/2, innerCol, outerCol, innerAlpha, outerAlpha, edgeSoftness)
}
draw_ellipse_ellipse :: #force_inline proc(e:Ellipse, innerCol:=COLOR_WHITE, outerCol:=COLOR_WHITE, innerAlpha:f32=1, outerAlpha:f32=1, edgeSoftness:f32=0){
	draw_ellipse_vec2(e.pos, e.radii, innerCol, outerCol, innerAlpha, outerAlpha, edgeSoftness)
}
draw_ellipse :: proc{draw_ellipse_vec2, draw_ellipse_rect, draw_ellipse_ellipse}

draw_circle_vec2 :: #force_inline proc(p:Vec2, r:f32, col:=COLOR_WHITE, alpha:f32=1, edgeSoftness:f32=0){
	draw_ellipse_vec2(p, {r,r}, col, col, alpha, alpha, edgeSoftness)
}
draw_circle_f :: #force_inline proc(x,y,r:f32, col:=COLOR_WHITE, alpha:f32=1, edgeSoftness:f32=0)  {
	draw_circle_vec2({x, y}, r, col, alpha, edgeSoftness)
}
draw_circle_i :: #force_inline proc(x,y,r:int, col:=COLOR_WHITE, alpha:f32=1, edgeSoftness:f32=0){
	draw_circle_vec2({f32(x), f32(y)}, f32(r), col, alpha, edgeSoftness)
}
draw_circle_circle :: #force_inline proc(c:Circle, col:=COLOR_WHITE, alpha:f32=1, edgeSoftness:f32=0){
	draw_circle_vec2({c.x, c.y}, c.radius, col, alpha, edgeSoftness)
}
draw_circle :: proc{draw_circle_f, draw_circle_i, draw_circle_vec2, draw_circle_circle}

draw_letterbox :: proc(r:Rect, color:Color, alpha:f32=1, bounds:=Rect{{0,0}, DISPLAY_SIZE}){
	r := r
	r.pos -= 1
	br := rect_get_bottom_right_f(r)
	cam := bounds
	camBr := rect_get_bottom_right_f(cam)
	letterBoxRects := [4]Rect{
		rect_make_points(cam.pos-1, Vec2{br.x, r.y}),
		rect_make_points(Vec2{br.x+1, cam.y}, Vec2{camBr.x, br.y}),
		rect_make_points(Vec2{r.x+1, br.y+1}, camBr),
		rect_make_points(Vec2{cam.x-1, r.y+1}, Vec2{r.x, camBr.y})
	}
	for rect,i in letterBoxRects{
		if(rect_is_positive(rect)) do draw_rect(rect, color, alpha)
	}
}
