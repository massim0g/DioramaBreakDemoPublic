package massimodin //@nested-tags:libraries/math

import "core:math/linalg"

Line :: [2]Vec2

lines_intersect :: #force_inline proc "contextless" (l1,l2:Line) -> bool{
	uA := ((l2[1].x-l2[0].x)*(l1[0].y-l2[0].y) - (l2[1].y-l2[0].y)*(l1[0].x-l2[0].x)) / ((l2[1].y-l2[0].y)*(l1[1].x-l1[0].x) - (l2[1].x-l2[0].x)*(l1[1].y-l1[0].y));
  	uB := ((l1[1].x-l1[0].x)*(l1[0].y-l2[0].y) - (l1[1].y-l1[0].y)*(l1[0].x-l2[0].x)) / ((l2[1].y-l2[0].y)*(l1[1].x-l1[0].x) - (l2[1].x-l2[0].x)*(l1[1].y-l1[0].y));

  	// if uA and uB are between 0-1, lines are colliding
	return uA >= 0 && uA <= 1 && uB >= 0 && uB <= 1
}

lines_intersection :: #force_inline proc "contextless" (l1,l2:Line) -> (point:Vec2, ok:bool){
	r := l1[1] - l1[0]
	s := l2[1] - l2[0]
	den := linalg.cross(r,s)
	if abs(den) <= 1e-12 do return 

	q := l2[0]-l1[0]
	t := linalg.cross(q, s)/den
	u := linalg.cross(q, r)/den

	point = Vec2{l1[0].x + t*r.x, l1[0].y + t*r.y}
	return point, true
}

//Returns the point on line l nearest to point p
line_nearest_point :: proc "contextless" (l:Line, p:Vec2) -> Vec2{
	//set origin to l[0]
    pVec := p - l[0];
    lVec := l[1] - l[0]
    
    mag := vec2_mag_get(lVec)
    lVec = vec2_normalize(lVec)
    dot := clamp(vec2_dot(pVec, lVec), 0, mag);
    
    return l[0] + lVec*dot;
}