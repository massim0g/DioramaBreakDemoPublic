package massimodin //@nested-tags:libraries/matrices

import "core:math/linalg/glsl"
import "core:math/linalg"

matrix_inverse :: glsl.inverse

PerspectiveTransform :: glsl.mat3
Mat4 :: glsl.mat4

//Creates a matrix that will map coordinates from the given 'src' Rect to the given quadrilateral.
//Coordinate order is top–left, top–right, bottom–right, bottom–left
perspective_transform_make :: proc(quad: [4]Vec2, src:=Rect{{0,0}, {1, 1}}) -> PerspectiveTransform {
	p0 := quad[0]  	// top-left
    p1 := quad[1]  	// top-right
    p2 := quad[2]  	// bottom-right
    p3 := quad[3] 	// bottom-left

	// Compute intermediate terms.
	dx := p0.x - p1.x + p2.x - p3.x
    dy := p0.y - p1.y + p2.y - p3.y

    A := p1.x - p2.x
    B := p3.x - p2.x
    C := p1.y - p2.y
    D := p3.y - p2.y

    denom := A*D - B*C
    g := (dx*D - B*dy) / denom
    h := (A*dy - dx*C) / denom

    a := (g + 1.0)*p1.x - p0.x
    b := (h + 1.0)*p3.x - p0.x
    d := (g + 1.0)*p1.y - p0.y
    e := (h + 1.0)*p3.y - p0.y

    // The homography H (which maps the unit square to the quad) is:
    H:PerspectiveTransform = {
    	a,      b,      p0.x,
    	d,      e,      p0.y,
    	g,      h,      1.0,
    }

	//Additional transformation for non-unit-square rects
	invW := 1.0 / src.size.x
    invH := 1.0 / src.size.y
    srcToUnitTransform := matrix[3,3]f32{
		invW,	0.0,	-src.x*invW,
		0.0,	invH,	-src.y*invH,
		0.0,	0.0,	1.0,
    }
	
	return H*srcToUnitTransform;
}
