package massimodin //@nested-tags:engine/distribution

Distribution :: enum{
	even,
	center,
	edges
}

distribute_points :: proc(bounds:Rect, distribution:Distribution, numPoints:int, allocator:=context.temp_allocator) -> []Vec2{
	points := make([]Vec2, numPoints, allocator)
	switch distribution{
		case .even:
			br := rect_get_bottom_right_f(bounds)
			for &p in points{
				p = {
					random_range(bounds.x, br.x),
					random_range(bounds.y, br.y),
				}
			}
		case .center:
			center := rect_center(bounds)
			for &p in points{
				p = center
			}
		case .edges:
			br := rect_get_bottom_right_f(bounds)
			for &p in points{
				if roll(0.5) do p = {random_range(bounds.x, br.x), choose([]f32{bounds.y, br.y})}
				else do p = {choose([]f32{bounds.x, br.x}), random_range(bounds.y, br.y)}
			}
	}

	return points
}