package massimodin //@nested-tags:engine/sprites

NinesliceInfo :: struct{
	padding:Vec2,
	tileEdges:bool
}

_nineslice_info_reload :: proc(){
	m := &sprites.nineslice_info
	clear(m)

	m[sp.dialogueBox] = {{12,12},false}
	m[sp.dialogueChoiceBox] = {{12,12},false}
	
	m[sp.selectionBox] = {{9,9},false}

	m[sp.timelineMoveBeadBack] = {{1,1},true}
	m[sp.timelineBox] = {{12,13},false}

	m[sp.dialogueBoxHDMask_cutout] = {{192,64},false}
	m[sp.dialogueBoxHDMask_dropShadow] = {{224,224},false}
	m[sp.dialogueBoxHDMask_gradient] = {{192,64},false}

	m[sp.menuBox] = {{4,2}, false}
	m[sp.menuBoxOutlined] = {{12,13}, false}
	m[sp.headerSelector] = {{14,8}, false}

	m[sp.timelineReactWindowOutline] = {{2,2}, true}

}

nineslice_draw :: proc(sp:^Sprite, area:Rect, frameIndex:=0, color:Color=COLOR_WHITE, alpha:f32=1){

	padding:Vec2
	tileEdges := true
	if info, ok := sprites.nineslice_info[sp]; ok{
		padding = info.padding
		tileEdges = info.tileEdges
	}

	area := area
	area.pos = round(area.pos)
	area.size = round(area.size)
	rect_resize_in_place(&area, sprite_origin(sp))

	//center
	centerArea := rect_make(area.x + padding.x, area.y + padding.y, area.size.x - padding.x*2, area.size.y - padding.y*2)
	centerPart := rect_make(padding.x, padding.y, sp.size.x - padding.x*2, sp.size.y - padding.y*2)
	sprite_draw_part_ex(sp, centerArea, centerPart, frameIndex, color=color,alpha=alpha)

	//corners
	sprite_draw_part_ex(sp, Rect{{area.x, area.y}, padding}, 														rect_make(0,0,padding.x,padding.y), 									frameIndex, color=color,alpha=alpha) //top-left
	sprite_draw_part_ex(sp, Rect{{rect_get_right(area)-padding.x+1, area.y}, padding}, 								rect_make(sp.size.x-padding.x,0,padding.x,padding.y), 					frameIndex, color=color,alpha=alpha) //top-right
	sprite_draw_part_ex(sp, Rect{{area.x, rect_get_bottom(area)-padding.y+1}, padding}, 							rect_make(0,sp.size.y-padding.y,padding.x,padding.y), 					frameIndex, color=color,alpha=alpha) //bottom-left
	sprite_draw_part_ex(sp, Rect{{rect_get_right(area)-padding.x+1, rect_get_bottom(area)-padding.y+1}, padding}, 	rect_make(sp.size.x-padding.x,sp.size.y-padding.y,padding.x,padding.y), frameIndex, color=color,alpha=alpha) //bottom-right

	//edges
	
	if(tileEdges){
		edgeArea:Rect
		edgePart:Rect
		end:f32

		//left
		edgeArea = rect_make(area.x, centerArea.y, padding.x, centerPart.size.y)
		edgePart = rect_make(0, centerPart.y, padding.x, centerPart.size.y)
		end = rect_get_bottom(centerArea) + 1
		for edgeArea.size.y == centerPart.size.y{
			edgeArea.size.y = min(end - edgeArea.y, edgeArea.size.y)
			edgePart.size.y = edgeArea.size.y

			sprite_draw_part_ex(sp, edgeArea, edgePart, frameIndex, color=color,alpha=alpha)

			edgeArea.y += edgeArea.size.y
		}

		//right
		edgeArea = rect_make(centerArea.x + centerArea.size.x, centerArea.y, padding.x, centerPart.size.y)
		edgePart = rect_make(centerPart.x + centerPart.size.x, centerPart.y, padding.x, centerPart.size.y)
		for edgeArea.size.y == centerPart.size.y{
			edgeArea.size.y = min(end - edgeArea.y, edgeArea.size.y)
			edgePart.size.y = edgeArea.size.y

			sprite_draw_part_ex(sp, edgeArea, edgePart, frameIndex, color=color,alpha=alpha)

			edgeArea.y += edgeArea.size.y
		}

		//top
		edgeArea = rect_make(centerArea.x, area.y, centerPart.size.x, padding.y)
		edgePart = rect_make(centerPart.x, 0, centerPart.size.x, padding.y)
		end = rect_get_right(centerArea) + 1
		for edgeArea.size.x == centerPart.size.x{
			edgeArea.size.x = min(end - edgeArea.x, edgeArea.size.x)
			edgePart.size.x = edgeArea.size.x

			sprite_draw_part_ex(sp, edgeArea, edgePart, frameIndex, color=color,alpha=alpha)

			edgeArea.x += edgeArea.size.x
		}

		//bottom
		edgeArea = rect_make(centerArea.x, centerArea.y + centerArea.size.y, centerPart.size.x, padding.y)
		edgePart = rect_make(centerPart.x, centerPart.y + centerPart.size.y, centerPart.size.x, padding.y)
		for edgeArea.size.x == centerPart.size.x{
			edgeArea.size.x = min(end - edgeArea.x, edgeArea.size.x)
			edgePart.size.x = edgeArea.size.x

			sprite_draw_part_ex(sp, edgeArea, edgePart, frameIndex, color=color,alpha=alpha)

			edgeArea.x += edgeArea.size.x
		}

	}
	else{

		//left
		sprite_draw_part_ex(sp, 
			rect_make(area.x, centerArea.y, padding.x, centerArea.size.y), 
			rect_make(0, centerPart.y, padding.x, centerPart.size.y), 
			frameIndex, color=color,alpha=alpha
		) 

		//right
		sprite_draw_part_ex(sp, 
			rect_make(centerArea.x + centerArea.size.x, centerArea.y, padding.x, centerArea.size.y), 
			rect_make(centerPart.x + centerPart.size.x, centerPart.y, padding.x, centerPart.size.y), 
			frameIndex, color=color,alpha=alpha
		) 

		//top
		sprite_draw_part_ex(sp, 
			rect_make(centerArea.x, area.y, centerArea.size.x, padding.y), 
			rect_make(centerPart.x, 0, centerPart.size.x, padding.y), 
			frameIndex, color=color,alpha=alpha
		) 

		//bottom
		sprite_draw_part_ex(sp, 
			rect_make(centerArea.x, centerArea.y + centerArea.size.y, centerArea.size.x, padding.y), 
			rect_make(centerPart.x, centerPart.y + centerPart.size.y, centerPart.size.x, padding.y), 
			frameIndex, color=color,alpha=alpha
		) 
		
	}
	
}