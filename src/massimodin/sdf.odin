package massimodin //@nested-tags:engine/visuals

import "core:reflect"
import "../sdl3"

SDFShape :: union{ //ENSURE TAG INDEX MATCHES IN SDF SHADER
	Circle
}

//quadratic polynomial smooth min
smin :: proc "contextless"(a,b,k:f32)->f32{
    k := k
	k *= 4
    h := max(k-abs(a-b), 0)/k
    return min(a,b) - h*h*k*(1./4.)
}

sdf :: proc "contextless"(pos:Vec2, shape:SDFShape)->f32{
	switch sh in shape{
		case Circle: return vec2_distance(pos, sh.pos) - sh.radius
	}
	unreachable()
}

//"k" is the distance at which shapes begin merging with each other
sdf_union :: proc "contextless"(pos:Vec2, shapes:[]SDFShape, k:f32) -> f32{
	out := sdf(pos, shapes[0])
	for shape in shapes[1:]{
		out = smin(out, sdf(pos, shape), k)
	}
	return out
}

sdf_normal :: proc "contextless"(pos: Vec2, shapes: []SDFShape, k: f32) -> Vec2 {
	h :: 1e-3
	return vec2_normalize(Vec2{
		sdf_union(Vec2{pos.x + h, pos.y}, shapes, k) - sdf_union(Vec2{pos.x - h, pos.y}, shapes, k),
   		sdf_union(Vec2{pos.x, pos.y + h}, shapes, k) - sdf_union(Vec2{pos.x, pos.y - h}, shapes, k)
	})
}

//returns a list of positions and outward directions along the edge of an sdf shape union. 
//startPos should ideally be a known position somewhere on or close to an edge. Points will be traced counterclockwise along the line starting from said edge.
//precision is the distance between edge points in pixels
sdf_trace_contour :: proc(startPos:Vec2, shapes:[]SDFShape, k:f32, precision:f32=1, allocator:=context.temp_allocator)->[]Ray{
	out := make([dynamic]Ray, allocator)
	checkPos := startPos
	for len(out)<1000{
		normal := sdf_normal(checkPos, shapes, k)
		dist := sdf_union(checkPos, shapes, k)
		edgePos := checkPos-normal*dist
		append(&out, Ray{edgePos, vec2_angle(normal)})
		if len(out) > 2 && vec2_distance(edgePos, out[0].pos) < precision*1.5 do break
		tangent := Vec2{-normal.y, normal.x}
		checkPos = edgePos + tangent*precision
	}
	shrink(&out)
	return out[:]
}

//Draws sdf shapes as a quad shaded by the sdf shader. Shape positions are relative to the passed offset, in target pixels.
sdf_draw :: proc(shapes:[]SDFShape, k:f32, color:=COLOR_WHITE, alpha:f32=1, offset:=Vec2{}){
	first := i32(len(render._sdf_shapes))
	boundsMin:Vec2 = INF
	boundsMax:Vec2 = -INF
	for shape in shapes{
		data := (cast(^[4]f32)(reflect.get_union_variant(shape).data))^
		data.w = f32(reflect.get_union_variant_raw_tag(shape))
		append(&render._sdf_shapes, data)

		boundsMin = min(boundsMin, Vec2{data.x, data.y} - data.z)
		boundsMax = max(boundsMax, Vec2{data.x, data.y} + data.z)
	}

	pad := k + 1
	rect := Rect{boundsMin + offset - pad, boundsMax - boundsMin + pad*2}
	shader_set(Sh_Sdf{rect.pos, rect.size, -offset, k, first, i32(len(shapes))})
	shader_buffer_bind("sdfShapes", &render._sdf_shape_buffer)
	draw_rect(rect, color, alpha)
	shader_reset()
}