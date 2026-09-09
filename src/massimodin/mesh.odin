package massimodin //@nested-tags:libraries/mesh

//Data structure, NOT for renderer
Mesh :: struct{
	vertices:[dynamic]Vec2,
	edges:[dynamic][2]u16
}

mesh_init :: proc(m:^Mesh, allocator:=context.allocator){
	init(&m.vertices, allocator)
	init(&m.edges, allocator)
}

mesh_make :: proc(allocator:=context.allocator) -> Mesh{
	return Mesh{
		make([dynamic]Vec2, allocator),
		make([dynamic][2]u16, allocator)
	}
}

mesh_vertex_append :: proc(m:^Mesh, v:Vec2){
	append(&m.vertices, v)
}

mesh_vertex_remove :: proc(m:^Mesh, ind:int){
	if len(m.vertices) <= 2{
		unordered_remove(&m.vertices, ind)
		clear(&m.edges)
		return
	}

	movedOldInd := u16(len(m.vertices)-1)
	u16Ind := u16(ind)

	unordered_remove(&m.vertices, ind)

	#reverse for &edge, i in m.edges{
		if edge[0] == u16Ind || edge[1] == u16Ind{
			unordered_remove(&m.edges, i)
			continue
		}

		if edge[0] == movedOldInd do edge[0] = u16Ind
		if edge[1] == movedOldInd do edge[1] = u16Ind
	}
}

mesh_edge_append :: proc(m:^Mesh, vertexInds:[2]int){
	append(&m.edges, cast([2]u16)vertexInds)
}

mesh_edge_remove :: proc(m:^Mesh, edgeInd:int){
	unordered_remove(&m.edges, edgeInd)
}

mesh_edge_to_line :: proc(m:Mesh, edge:[2]u16) -> Line{
	return Line{m.vertices[edge[0]], m.vertices[edge[1]]}
}

mesh_clear :: proc(m:^Mesh){
	clear(&m.vertices)
	clear(&m.edges)
}

mesh_delete :: proc(m:Mesh){
	delete(m.vertices)
	delete(m.edges)
}

//split an existing edge into two with a new vertex in between the existing edge's vertices
mesh_edge_split :: proc(m:^Mesh, newVertex:Vec2, edgeInd:int){
	oldEdge := Vec2i(m.edges[edgeInd])
	mesh_edge_remove(m, edgeInd)
	newVertexInd := len(m.vertices)
	mesh_vertex_append(m, newVertex)
	mesh_edge_append(m, {oldEdge[0], newVertexInd})
	mesh_edge_append(m, {newVertexInd, oldEdge[1]})
}

//checks if a point is inside any closed shapes defined by the mesh (if any)
mesh_point_inside :: proc (m:Mesh, p:Vec2) -> bool{
	// compute vertex degrees to identify closed loops
	degrees := make([]u8, len(m.vertices), context.temp_allocator)
	for edge in m.edges{
		degrees[edge[0]] += 1
		degrees[edge[1]] += 1
	}

	// ray cast in +x direction, count crossings with edges that belong to closed loops
	crossings := 0
	for edge in m.edges{
		// skip edges connected to vertices not part of a closed loop
		if degrees[edge[0]] != 2 || degrees[edge[1]] != 2 do continue

		ay := m.vertices[edge[0]].y
		by := m.vertices[edge[1]].y
		ax := m.vertices[edge[0]].x
		bx := m.vertices[edge[1]].x

		// check if the ray from p in +x crosses this edge
		// one endpoint must be strictly above and the other at or below
		if (ay > p.y) == (by > p.y) do continue

		// x coordinate of intersection
		t := (p.y - ay) / (by - ay)
		ix := ax + t*(bx - ax)

		if ix > p.x do crossings += 1
	}

	return crossings % 2 == 1
}

mesh_nearest_point :: proc(m:Mesh, p:Vec2) -> (nearestPoint:Vec2, nearestPointEdgeInd:int, nearestVertexInd:int,){
	nearestDist := INF
	nearestPointEdgeInd = -1
	for edge, i in m.edges{
		nearestEdgePoint := line_nearest_point(mesh_edge_to_line(m, edge), p)
		newDist := vec2_distance(nearestEdgePoint, p)
		if newDist < nearestDist{
			nearestPoint = nearestEdgePoint
			nearestPointEdgeInd = i
			nearestDist = newDist
		} 
	}

	nearestDist = INF
	nearestVertexInd = -1
	for vert,i in m.vertices{
		newDist := vec2_distance(vert, p)
		if newDist < nearestDist{
			nearestVertexInd = i
			nearestDist = newDist
		} 
	}

	return
}

