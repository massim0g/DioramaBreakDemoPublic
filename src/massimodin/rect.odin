package massimodin //@nested-tags:libraries/math

Rect :: struct{
    using pos:Vec2,
    size:Vec2
}
Recti :: struct{
    using pos:Vec2i,
    size:Vec2i
}

rect_cast :: proc(r:Recti)->Rect{
	return {Vec2(r.pos), Vec2(r.size)}
}

rectf_make :: #force_inline proc "contextless"(x:f32=0, y:f32=0, w:f32=0, h:f32=0) -> Rect{
    return Rect{{x,y}, {w, h}}
}
recti_make :: #force_inline proc "contextless"(x:int=0, y:int=0, w:int=0, h:int=0) -> Recti{
    return Recti{{x,y}, {w, h}}
}
rect_make :: proc{rectf_make, recti_make}

rectf_make_points :: proc "contextless" (x1:f32=0, y1:f32=0, x2:f32=0, y2:f32=0) -> Rect{
	_x1 := min(x1, x2)
	_x2 := max(x1, x2)
	_y1 := min(y1, y2)
	_y2 := max(y1, y2)

    out := Rect{{_x1, _y1}, {-1, -1}}
	rect_set_right(&out, _x2, true)
	rect_set_bottom(&out, _y2, true)
	return out
}
rectf_make_points_vec2 :: #force_inline proc "contextless"(p1:Vec2, p2:Vec2) -> Rect{
	return rectf_make_points(p1.x, p1.y, p2.x, p2.y)
}
recti_make_points :: proc "contextless" (x1:int=0, y1:int=0, x2:int=0, y2:int=0) -> Recti{
	_x1 := min(x1, x2)
	_x2 := max(x1, x2)
	_y1 := min(y1, y2)
	_y2 := max(y1, y2)

    out := Recti{{_x1, _y1}, {-1, -1}}
	rect_set_right(&out, _x2, true)
	rect_set_bottom(&out, _y2, true)
	return out
}
recti_make_points_vec2 :: #force_inline proc "contextless"(p1:Vec2i, p2:Vec2i) -> Recti{
	return recti_make_points(p1.x, p1.y, p2.x, p2.y)
}
//Points can be anywhere, the output rect's true position and size will be adjusted automatically
rect_make_points :: proc{rectf_make_points, rectf_make_points_vec2, recti_make_points, recti_make_points_vec2}

rect_make_points_f_f :: proc "contextless" (x1:f32=0, y1:f32=0, x2:f32=0, y2:f32=0) -> Rect{
	_x1 := min(x1, x2)
	_x2 := max(x1, x2)
	_y1 := min(y1, y2)
	_y2 := max(y1, y2)

    out := Rect{{_x1, _y1}, {-1, -1}}
	rect_set_right_f(&out, _x2, true)
	rect_set_bottom_f(&out, _y2, true)
	return out
}
rect_make_points_vec2_f :: #force_inline proc "contextless"(p1:Vec2, p2:Vec2) -> Rect{
	return rect_make_points_f_f(p1.x, p1.y, p2.x, p2.y)
}
//Points can be anywhere, the output rect's true position and size will be adjusted automatically
rect_make_points_f :: proc{rect_make_points_f_f, rect_make_points_vec2_f}

rectf_get_right :: #force_inline proc "contextless"(r:Rect) -> f32{
	return r.x + r.size.x - 1
}
rectf_get_bottom :: #force_inline proc "contextless"(r:Rect) -> f32{
	return r.y + r.size.y - 1
}
rectf_get_bottom_right :: #force_inline proc "contextless"(r:Rect) -> Vec2{
	return r.pos + r.size - {1,1}
}

recti_get_right :: #force_inline proc "contextless"(r:Recti) -> int{
	return r.x + r.size.x - 1
}
recti_get_bottom :: #force_inline proc "contextless"(r:Recti) -> int{
	return r.y + r.size.y - 1
}
recti_get_bottom_right :: #force_inline proc "contextless"(r:Recti) -> Vec2i{
	return r.pos + r.size - {1,1}
}

rect_get_right :: proc{rectf_get_right, recti_get_right}
rect_get_bottom :: proc{rectf_get_bottom, recti_get_bottom}
rect_get_bottom_right :: proc{rectf_get_bottom_right, recti_get_bottom_right}

rect_get_right_f :: #force_inline proc "contextless"(r:Rect) -> f32{
	return r.x + r.size.x
}
rect_get_bottom_f :: #force_inline proc "contextless"(r:Rect) -> f32{
	return r.y + r.size.y
}
rect_get_bottom_right_f :: #force_inline proc "contextless"(r:Rect) -> Vec2{
	return r.pos + r.size
}

rectf_set_left :: #force_inline proc "contextless"(r:^Rect, pos:f32, adjustSize:=false){
	if(adjustSize) do r.size.x += r.x - pos
	r.x = pos
}
rectf_set_top :: #force_inline proc "contextless"(r:^Rect, pos:f32, adjustSize:=false){
	if(adjustSize) do r.size.y += r.y - pos
	r.y = pos
}
rectf_set_right :: #force_inline proc "contextless"(r:^Rect, pos:f32, adjustSize:=false){
	if(adjustSize) do r.size.x = pos - r.x + 1;
	else do r.x = pos - r.size.x + 1;
}
rectf_set_bottom :: #force_inline proc "contextless"(r:^Rect, pos:f32, adjustSize:=false){
	if(adjustSize) do r.size.y = pos - r.y + 1;
	else do r.y = pos - r.size.y + 1;
}
recti_set_left :: #force_inline proc "contextless"(r:^Recti, pos:int, adjustSize:=false){
	if(adjustSize) do r.size.x += r.x - pos
	r.x = pos
}
recti_set_top :: #force_inline proc "contextless"(r:^Recti, pos:int, adjustSize:=false){
	if(adjustSize) do r.size.y += r.y - pos
	r.y = pos
}
recti_set_right :: #force_inline proc "contextless"(r:^Recti, pos:int, adjustSize:=false){
	if(adjustSize) do r.size.x = pos - r.x + 1;
	else do r.x = pos - r.size.x + 1;
}
recti_set_bottom :: #force_inline proc "contextless"(r:^Recti, pos:int, adjustSize:=false){
	if(adjustSize) do r.size.y = pos - r.y + 1;
	else do r.y = pos - r.size.y + 1;
}
rect_set_left :: proc{rectf_set_left, recti_set_left}
rect_set_top :: proc{rectf_set_top, recti_set_top}
rect_set_right :: proc{rectf_set_right, recti_set_right}
rect_set_bottom :: proc{rectf_set_bottom, recti_set_bottom}

rect_set_right_f :: #force_inline proc "contextless"(r:^Rect, pos:f32, adjustSize:=false){
	if(adjustSize) do r.size.x = pos - r.x;
	else do r.x = pos - r.size.x;
}
rect_set_bottom_f :: #force_inline proc "contextless"(r:^Rect, pos:f32, adjustSize:=false){
	if(adjustSize) do r.size.y = pos - r.y;
	else do r.y = pos - r.size.y;
}

rectfs_overlap :: proc "contextless"(r1,r2:Rect) -> bool{
	right1 := rect_get_right(r1)
	right2 := rect_get_right(r2)
	bottom1 := rect_get_bottom(r1)
	bottom2 := rect_get_bottom(r2)
	return r1.x <= right2 && right1 >= r2.x && r1.y <= bottom2 && bottom1 >= r2.y
}
rectis_overlap :: proc "contextless"(r1,r2:Recti) -> bool{
	right1 := rect_get_right(r1)
	right2 := rect_get_right(r2)
	bottom1 := rect_get_bottom(r1)
	bottom2 := rect_get_bottom(r2)
	return r1.x <= right2 && right1 >= r2.x && r1.y <= bottom2 && bottom1 >= r2.y
}
rects_overlap :: proc{rectfs_overlap, rectis_overlap}

rectf_contains_rect ::  proc "contextless"(outer:Rect, inner:Rect) -> bool{
	rightOuter := rect_get_right(outer)
	rightInner := rect_get_right(inner)
	bottomOuter := rect_get_bottom(outer)
	bottomInner := rect_get_bottom(inner)
	return inner.x >= outer.x && inner.y >= outer.y && rightInner <= rightOuter && bottomInner <= bottomOuter
}
recti_contains_rect ::  proc "contextless"(outer:Recti, inner:Recti) -> bool{
	rightOuter := rect_get_right(outer)
	rightInner := rect_get_right(inner)
	bottomOuter := rect_get_bottom(outer)
	bottomInner := rect_get_bottom(inner)
	return inner.x >= outer.x && inner.y >= outer.y && rightInner <= rightOuter && bottomInner <= bottomOuter
}
rectf_contains_point :: #force_inline proc "contextless"(r:Rect, p:Vec2) -> bool{
	return p.x >= r.x && p.x <= rectf_get_right(r) && p.y >= r.y && p.y <= rectf_get_bottom(r)
}
recti_contains_point :: #force_inline proc "contextless"(r:Recti, p:Vec2i) -> bool{
	return p.x >= r.x && p.x <= recti_get_right(r) && p.y >= r.y && p.y <= recti_get_bottom(r)
}
rect_contains :: proc{rectf_contains_rect, recti_contains_rect, rectf_contains_point, recti_contains_point}

rect_contains_rect_f :: proc "contextless"(outer:Rect, inner:Rect) -> bool{
	rightOuter := rect_get_right_f(outer)
	rightInner := rect_get_right_f(inner)
	bottomOuter := rect_get_bottom_f(outer)
	bottomInner := rect_get_bottom_f(inner)
	return inner.x >= outer.x && inner.y >= outer.y && rightInner <= rightOuter && bottomInner <= bottomOuter
}
rect_contains_point_f :: #force_inline proc "contextless"(r:Rect, p:Vec2) -> bool{
	return p.x >= r.x && p.x <= rect_get_right_f(r) && p.y >= r.y && p.y <= rect_get_bottom_f(r)
}
rect_contains_f :: proc{rect_contains_rect_f, rect_contains_point_f}

//Returns whether the rectangle intersects a line
rect_intersects :: proc "contextless"(r:Rect, l:Line) -> bool{
	br := rect_get_bottom_right_f(r)
	c1 := Vec2{br.x, r.y}
	c3 := Vec2{r.x, br.y}
	return lines_intersect({r.pos, c1}, l) || lines_intersect({c1, br}, l) || lines_intersect({br, c3}, l) || lines_intersect({c3, r.pos}, l) || (l[0].x >= r.x && l[0].x <= br.x && l[0].y >= r.y && l[0].y <= br.y)
}

rect_resize_in_place_f :: proc(r:^Rect, widthChange:f32, heightChange:f32){
	r.x -= widthChange
	r.y -= heightChange
	r.size.x += widthChange*2
	r.size.y += heightChange*2
}
rect_resize_in_place_vec :: proc(r:^Rect, sizeChange:Vec2){
	rect_resize_in_place_f(r, sizeChange.x, sizeChange.y)
}
rect_resize_in_place :: proc{rect_resize_in_place_f, rect_resize_in_place_vec}

rect_scaled_in_place :: proc(r:Rect, scale:Vec2) -> Rect{
	out := r
	out.size = r.size*scale
	out.pos += (r.size-out.size)/2
	return out
}

rectf_center :: proc(r:Rect) -> Vec2{
	return r.pos + r.size/2
}
recti_center :: proc(r:Recti) -> Vec2i{
	return r.pos + r.size/2
}
rect_center :: proc{rectf_center, recti_center}

rectf_center_set :: proc(r:^Rect, c:Vec2){
	r.pos = c-r.size/2
}
recti_center_set :: proc(r:^Recti, c:Vec2i){
	r.pos = c-r.size/2
}
rect_center_set :: proc{rectf_center_set, recti_center_set}

rect_is_positive :: proc(r:Rect) -> bool{
	return r.size.x >= 0 && r.size.y >= 0
}

recti_area :: proc(r:Recti) -> int{
	return r.size.x*r.size.y
}
rectf_area :: proc(r:Rect) -> f32{
	return r.size.x*r.size.y
}
rect_area :: proc{recti_area, rectf_area}

recti_manhattan_distance :: proc(r1:Recti, r2:Recti) -> int{
	xDist := (max(r1.x + r1.size.x, r2.x + r2.size.x) - min(r1.x, r2.x)) - (r1.size.x + r2.size.x);
	yDist := (max(r1.y + r1.size.y, r2.y + r2.size.y) - min(r1.y, r2.y)) - (r1.size.y + r2.size.y);
	return max(xDist, -1) + max(yDist, -1) + 2;
}

recti_surrounding_positions :: #force_inline proc "contextless" (r:Recti) -> [4]Vec2i{
	return [4]Vec2i{
		{r.pos.x+r.size.x, r.pos.y},
		{r.pos.x, r.pos.y-1},
		{r.pos.x-1, r.pos.y+r.size.y-1},
		{r.pos.x+r.size.x-1, r.pos.y+r.size.y}
	}
}

rect_enclosing_ellipse :: proc "contextless" (rectSize:Vec2)->Vec2{
	return Vec2{
		sqrt(rectSize.x*rectSize.x + rectSize.y*rectSize.y*f32(256./81.))/2,
		sqrt(rectSize.x*rectSize.x*f32(81./256.) + rectSize.y*rectSize.y)/2
	}
}

//place a specific part of a rect at a given position based on the provided alignment
rect_align :: proc(r:^Rect, pos:Vec2, alignment:Alignment){
	switch alignment.x{
		case -1: r.x = pos.x
		case 0: r.x = pos.x - r.size.x/2
		case 1: rect_set_right(r, pos.x)
		case: panicf("Invalid alignment '%v' provided!", alignment)
	}
	switch alignment.y{
		case -1: r.y = pos.y
		case 0: r.y = pos.y - r.size.y/2
		case 1: rect_set_bottom(r, pos.y)
		case: panicf("Invalid alignment '%v' provided!", alignment)
	}
}

vec2i_array_bounds :: proc(positions:[]Vec2i) -> Recti{
	p1 := VEC2I_MAX
	p2 := VEC2I_MIN

	for p in positions{
		p1 = min(p, p1)
		p2 = max(p, p2)
	}

	return rect_make_points(p1, p2)
} 

rect_sample :: proc(r:Rect) -> Vec2{
	return Vec2{
		random_range(r.x, r.x+r.size.x),
		random_range(r.y, r.y+r.size.y)
	}
}