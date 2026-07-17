package massimodin //@nested-tags:libraries/math

Circle :: struct{
	using pos:Vec2,
	radius:f32
}

Ellipse :: struct{
	using pos:Vec2,
	radii:Vec2
}

circumference :: proc(c:Circle)->f32{
	return c.radius*PI*2
}

ellipse_contains :: proc "contextless"(e:Ellipse, p:Vec2) -> bool{
    d := (p - e.pos)/e.radii
    return d.x*d.x + d.y*d.y <= 1
}

ellipse_area :: #force_inline proc "contextless"(e:Ellipse) -> f32{
	return e.radii.x*e.radii.y*PI
}

ellipse_edge_point :: #force_inline proc "contextless"(e:Ellipse, angle:f32)->Vec2{
	return Vec2{
		e.pos.x + e.radii.x*cos(angle),
		e.pos.y + e.radii.y*sin(angle)
	}
}
//sample a random point within an ellipse
ellipse_sample :: proc(e:Ellipse) -> Vec2{
    u := random()
    v := random()
    r := sqrt(u)
    theta := 2*PI*v

    return Vec2{
        e.x + e.radii.x*r*rcos(theta),
        e.y + e.radii.y*r*rsin(theta)
    }
}