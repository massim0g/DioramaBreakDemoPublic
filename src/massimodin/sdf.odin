package massimodin //@nested-tags:engine/visuals

import "core:reflect"
import gl "vendor:OpenGL"

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

//if you need to make multiple calls to this at once, it's recommended that you set the sdf shader outside of the proc call
sdf_draw :: proc(shapes:[]SDFShape, k:f32, color:=COLOR_WHITE, alpha:f32=1, offset:=Vec2{}){
	camPos := camera_pos()
	shaderActive := shader_get() == sh.sdf
	if !shaderActive do shader_set(sh.sdf)
	shader_uniform_set(sh.sdf, "offset", camPos-offset)
	shader_uniform_set(sh.sdf, "k", k)

	shapeCount := i32(len(shapes))
	assertf(shapeCount<=64, "sdf_draw shape count '%i' is above the maximum the shader can handle (64)! Increase the limit or reduce shapes drawn.", shapeCount)
	shader_uniform_set(sh.sdf, "shapeCount", shapeCount)
	shapeTags := make([dynamic]i32, shapeCount, context.temp_allocator)
	shapeData := make([dynamic][4]f32, shapeCount, context.temp_allocator)
	for shape,i in shapes{
		shapeTags[i] = i32(reflect.get_union_variant_raw_tag(shape))
		shapeData[i] = (cast(^[4]f32)(reflect.get_union_variant(shape).data))^
	}
	gl.Uniform1iv(shader_uniform_loc(sh.sdf, "shapeTags"), shapeCount, &shapeTags[0])
	gl.Uniform4fv(shader_uniform_loc(sh.sdf, "shapes"), shapeCount, &shapeData[0].x)

	@(static) drawTex:Tex
	targetSize := tex_target_get().size
	if drawTex.ptr == nil do drawTex = tex_make(targetSize)
	else if drawTex.size != targetSize do tex_resize(&drawTex, targetSize)
	tex_draw_ex(drawTex, camPos, color=color, alpha=alpha) //we don't actually sample the drawTex, we just need to draw something the same size as the target
	if !shaderActive do shader_reset()
}