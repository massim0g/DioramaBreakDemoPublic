package massimodin //@nested-tags:engine/curves

import "../imgui"
import "../tinyfd"
import "core:slice"
import "core:path/filepath"
import "core:os"

//References:
//https://www.youtube.com/watch?v=jvPPXbo87ds
//https://gist.github.com/jakubtomsu/577f2375aad587e09c2d75e085fef87f

CurveSystem :: struct{
	_curves_map:map[string]Curve,
	names:[dynamic]string,
	using edit:^struct{
		curve_editing:^Curve,
		curve_working:Curve,
		editing_tex:Tex,
		undoStack:[dynamic][]CurvePoint,
		redoStack:[dynamic][]CurvePoint,
		undo_allocator:Allocator,
		undo_flag:UndoFlag,
		selected_point:struct{ind:int, isVelocity:bool},
		mouse_drag_edit_dirty:bool,
		preview_tex:Tex,
		preview_duration:f32, //in seconds
		save_path:string,
		filepaths:map[string]string,
		last_save_stack_size:int
	}
}
curves:^CurveSystem

CURVE_EDITOR_GRAPH_SIZE :: 512
CURVE_EDITOR_VELOCITY_SCALE :f32: 6

_curve_editor_save :: proc(forceSaveAs:=false)->(ok:bool){ 
	when !ON_WINDOWS do return true //never save game project files on non-windows builds

	assert(DEBUG && curves.curve_editing != nil, "Attempted to save a curve outside of curve editing mode.")

	ce := curves.curve_editing

	if(forceSaveAs){
		saveAsResult := _curve_save_as(curves.curve_editing.name)
		if saveAsResult == nil do return false
		curves.curve_editing = saveAsResult
	}

	saveData := curves.curve_working.points[:]
	resize(&curves.curve_editing.points, len(saveData))
	copy(curves.curve_editing.points[:], saveData)

	err := os.write_entire_file(curves.filepaths[curves.curve_editing.name], slice.to_bytes(saveData))

	curves.last_save_stack_size = len(curves.undoStack)
	
	return true
}

_curve_save_as :: proc(name:string) -> ^Curve{
	savePath,_ := filepath.join([]string{project_directory, format("curves/%s.curve", name)}, context.temp_allocator)
	filter:cstring = "*.curve"
	dialogResult := tinyfd.saveFileDialog(
		"Save Curve", 
		string_to_cstring(savePath, context.temp_allocator),
		1, &filter, 
		nil
	)
	defer delete(dialogResult)
	if(dialogResult == "") do return nil
	savePath = clone(string(dialogResult), assets.allocator)
	
	newName := filepath.stem(savePath)

	newName = strmap_set(&curves._curves_map, newName, Curve{})
	out := &curves._curves_map[newName]
	out.name = newName
	init(&out.points, 2, assets.allocator)
	copy(out.points[:], []CurvePoint{
		{{0,0}, 0},
		{{1,1}, 0}
	})
	append(&curves.names, newName)
	curves.filepaths[out.name] = savePath

	return out
}

_curve_system_init :: proc(){
	curves = new(CurveSystem, os_allocator)

	init(&curves._curves_map, assets.allocator)
	init(&curves.names, assets.allocator)
	cu = new(CurveIDs, assets.allocator)

	when DEBUG{
		curves.edit = new(type_of(curves.edit^), os_allocator)
		curves.undo_allocator = allocator_make()
	
		init(&curves.undoStack, curves.undo_allocator)
		init(&curves.redoStack, curves.undo_allocator)

		init(&curves.curve_working.points)

		curves.editing_tex = tex_make(CURVE_EDITOR_GRAPH_SIZE, CURVE_EDITOR_GRAPH_SIZE)
		curves.preview_tex = tex_make(CURVE_EDITOR_GRAPH_SIZE, CURVE_EDITOR_GRAPH_SIZE/8)
		curves.selected_point.ind = -1
	}
}

//Defines a hermite spline with multiple points 
Curve :: struct{
	name:string, //in debug mode, this contains the full save path
	points:[dynamic]CurvePoint,
	invert:bool
}

CurvePoint :: struct{
	using pos:Vec2,
	velocity:f32 //y "speed" at the given point
}

_curve_editor_open :: proc(curve:^Curve){
	curves.curve_editing = curve
	resize(&curves.curve_working.points, len(curve.points))
	copy(curves.curve_working.points[:], curve.points[:])
	_curve_editor_undo_push()
	curves.last_save_stack_size = 1
}

_curve_editor_update :: proc(){
	if curves.curve_editing == nil do return

	pointVelocityGraphPos :: proc(point:CurvePoint) -> Vec2{
		return Vec2{point.x, point.y + point.velocity/CURVE_EDITOR_VELOCITY_SCALE}
	}

	texSize := Vec2(curves.editing_tex.size)
	imgui.Begin("Curve Editor - Points", nil, {.AlwaysAutoResize})
		for &point,i in &curves.curve_working.points{
			imgui.Text("P%i", i)
			imgui.SameLine()
			imgui.BeginDisabled(i == 0 || i == len(curves.curve_working.points)-1)
			stage_edit_gui_field("X", &point.pos.x, _curve_editor_undo_push)
			imgui.EndDisabled()
			imgui.SameLine()
			stage_edit_gui_field("Y", &point.pos.y, _curve_editor_undo_push)
			imgui.SameLine()
			stage_edit_gui_field("Velocity", &point.velocity, _curve_editor_undo_push)
		}
	imgui.End()
	
	imgui.Begin("Curve Editor", nil, {.AlwaysAutoResize, .NoMove})
		imgui.SetWindowPos(window_size()/2 - imgui.GetWindowSize()/2)
		graphPos :Vec2= imgui.GetCursorPos() + imgui.GetWindowPos()
		imgui_tex(curves.editing_tex)
		stage_edit_gui_field("Preview Duration (s)", &curves.preview_duration, nil_proc)
		imgui_tex(curves.preview_tex)
		imgui.Text(string_to_cstring(format("File: %s%s", 
			curves.curve_editing.name, 
			curves.last_save_stack_size == len(curves.undoStack) ? "" : "*"
		), context.temp_allocator))
		if imgui.Button("Save") do _curve_editor_save()
		if imgui.Button("Save As") do _curve_editor_save(true)
		if imgui.Button("Close (unsaved changes will be lost)"){
			imgui.End()
			_curve_editor_close()
			return
		}
	imgui.End()

	
	mouseGraphPos := remap(imgui.GetMousePos(), graphPos, graphPos+texSize, Vec2{0,0}, Vec2{1,1})
	hoverDistance :: 0.0267

	if mouse_held(.LEFT) && curves.selected_point.ind != -1{
		ind := curves.selected_point.ind
		curves.mouse_drag_edit_dirty = true
		point := &curves.curve_working.points[ind]
		if curves.selected_point.isVelocity{
			point.velocity = (mouseGraphPos.y - point.y)*CURVE_EDITOR_VELOCITY_SCALE
		}
		else{
			point.pos = mouseGraphPos
			if ind == 0 do point.pos.x = 0
			else if ind == len(curves.curve_working.points)-1 do point.pos.x = 1
			else do point.pos.x = clamp(point.pos.x, curves.curve_working.points[ind-1].x, curves.curve_working.points[ind+1].x)
		}
		
	}
	else{
		if curves.mouse_drag_edit_dirty{
			_curve_editor_undo_push()
			curves.mouse_drag_edit_dirty = false
		}

		
		curves.selected_point.ind = -1
		for &point, i in &curves.curve_working.points{
			if vec2_distance(mouseGraphPos, pointVelocityGraphPos(point)) < hoverDistance/2{
				curves.selected_point = {i, true}
				break
			}
			if vec2_distance(mouseGraphPos, point.pos) < hoverDistance{
				curves.selected_point = {i, false}
				break
			}
		}

		//create new point
		if curves.selected_point.ind == -1 && mouse_pressed(.LEFT) && rect_contains_f(Rect{{0,0},{1,1}}, mouseGraphPos){
			newInd:int
			for _, i in curves.curve_working.points{
				if curves.curve_working.points[i+1].x >= mouseGraphPos.x{
					newInd = i+1
					break
				}
			}

			inject_at(&curves.curve_working.points, newInd, CurvePoint{mouseGraphPos, 0})
			curves.selected_point = {newInd, false}
		}

		//delete point
		if in_range(curves.selected_point.ind, 1, len(curves.curve_working.points)-2) && mouse_pressed(.RIGHT){
			ordered_remove(&curves.curve_working.points, curves.selected_point.ind)
			curves.selected_point.ind = -1
			_curve_editor_undo_push()
		}

		if key_combo_pressed({.CTRL}, .Z) do curves.undo_flag = .undo
		else if key_combo_pressed({.CTRL}, .Y) do curves.undo_flag = .redo
	}

	tex_target_set(curves.editing_tex)
		//draw grid lines
		for x:f32=0;x<=1;x+=1./4.{
			drawX := x*texSize.x
			if x == 1 do drawX -= 1
			draw_line(drawX, 0, drawX, texSize.y, color=color_hex(0x515151))
		}
		for y:f32=0;y<=1;y+=1./4.{
			drawY := y*texSize.y
			if y == 1 do drawY -= 1
			draw_line(0, drawY, texSize.y, drawY, color=color_hex(0x515151))
		}
		//draw curve
		lastPos := Vec2{0, curve_eval(&curves.curve_working, 0)*texSize.y}
		increment := 1/f32(curves.editing_tex.size.x)
		cw := curves.curve_working

		for x:f32=0;x<=1;x+=increment{
			newPos := Vec2{x, curve_eval(&curves.curve_working, x)}*texSize
			draw_line(lastPos, newPos, color=color_hex(0xff3800))
			lastPos = newPos
		}

		//draw points
		pointOff := Vec2{hoverDistance, hoverDistance}*texSize/2
		for &point, i in &curves.curve_working.points{
			isSelected := i == curves.selected_point.ind && !curves.selected_point.isVelocity
			selectMul :f32= isSelected ? 2:1
			
			drawPos := point.pos*texSize
			draw_rect(drawPos-pointOff*selectMul, drawPos+pointOff*selectMul, color_hex(isSelected ? 0x62beff : 0x1881e6))

			isSelected = i == curves.selected_point.ind && curves.selected_point.isVelocity
			selectMul = isSelected ? 2:1

			velDrawPos := pointVelocityGraphPos(point)*texSize
			draw_line(drawPos, velDrawPos, color=color_hex(0xbd7d18))

			draw_rect(velDrawPos-pointOff/2*selectMul, velDrawPos+pointOff/2*selectMul, color_hex(isSelected ? 0xf6da62 : 0xf6aa08))
		}

	tex_target_set(curves.preview_tex)
		duration := time_convert(curves.preview_duration, .seconds, .frames)
		centerPos := Vec2{remap(mod(f32(time.frame),duration), 0, duration, 0, texSize.x, &curves.curve_working), f32(curves.preview_tex.size.y)/2}
		scale := texSize.x/8/256
		sprite_draw_ex(sp.circle256, centerPos, scale=scale)
	tex_target_clear()

	_curve_editor_undo_resolve()

	if key_combo_pressed({.CTRL, .SHIFT}, .S){
		_curve_editor_save(true)
	}
	else if key_combo_pressed({.CTRL}, .S){
		_curve_editor_save()
	}
}

_curve_editor_close :: proc(){
	free_all(curves.undo_allocator)
	init(&curves.undoStack, curves.undo_allocator)
	init(&curves.redoStack, curves.undo_allocator)

	curves.curve_editing = nil
	curves.mouse_drag_edit_dirty = false
}

_curve_editor_undo_push :: proc(){
	curves.undo_flag = .undoPush
}

_curve_editor_undo_resolve :: proc(){
	loadPoints :[]CurvePoint=nil
	switch curves.undo_flag{
		case .none:
		case .undoPush:
			for points in curves.redoStack{
				delete(points)
			}
			clear(&curves.redoStack)
			append(&curves.undoStack, clone(curves.curve_working.points[:], curves.undo_allocator))
		case .undo:
			if(len(curves.undoStack) > 1){
				append(&curves.redoStack, pop(&curves.undoStack))
				loadPoints = peek(curves.undoStack)
			}
		case .redo:
			if(len(curves.redoStack) > 0){
				loadPoints = pop(&curves.redoStack)
				append(&curves.undoStack, loadPoints)
			}
	}
	if loadPoints != nil{
		resize(&curves.curve_working.points, len(loadPoints))
		copy(curves.curve_working.points[:], loadPoints)
	}
	curves.undo_flag = .none
}



//t should be a normalized value between 0 and 1
curve_eval :: proc "contextless" (curve:^Curve, t:f32) -> f32{
	if curve == nil do return t
	m :: matrix[4,4]f32{ //hermite characteristic matrix
		 1, 0, 0, 0,
		 0, 1, 0, 0,
		-3,-2, 3,-1,
		 2, 1,-2, 1
	}
	out:f32
	if(t<=0) do out = curve.points[0].y
	else if(t>=1) do out = peek(curve.points).y
	else{
		for point,i in curve.points{
			nextPoint := curve.points[i+1]
			if t < nextPoint.x{
				t:=t
				t = remap(t, point.x, nextPoint.x, 0, 1)
				t2 := t * t
				t3 := t2 * t
				out =
					point.pos.y 			* (m[0][3] * t3 + m[0][2] * t2 + m[0][1] * t + m[0][0]) +
					point.velocity 		* (m[1][3] * t3 + m[1][2] * t2 + m[1][1] * t + m[1][0]) +
					nextPoint.pos.y 		* (m[2][3] * t3 + m[2][2] * t2 + m[2][1] * t + m[2][0]) +
					nextPoint.velocity 	* (m[3][3] * t3 + m[3][2] * t2 + m[3][1] * t + m[3][0])
				break
			}
		}
	}

	return curve.invert ? 1-out : out
}