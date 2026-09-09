#+feature using-stmt
package massimodin //@nested-tags:_components/

TextEffect :: struct{
	using base:RenderComponentBase,
	stageEntity:CoRef(StageEntity),
	transform:CoRef(Transform),
	mover:CoRef(Mover),
	font:^Font,
	age:f32,
	duration:f32,
	scaleCurves:[2]^Curve,
	alphaCurve:^Curve,
	alignment:Alignment,
	movement:EffectMovement,
	shake:Vec2,
	shakeCurve:^Curve,
	startPos:Vec3,
	tex:Tex,
	dropShadow:Maybe(Color)
}

//prerenders texture once. if text needs to change, refactor to do so every frame
textEffect_make :: proc(
	text:string, 
	pos:Vec2, 
	z:f32=0, 
	duration:f32=INF, 
	color:Color=COLOR_WHITE, 
	alpha:f32=1, 
	font:^Font=nil, 
	alignment:Alignment=-1, 
	movement:EffectMovement=nil, 
	shake:Vec2=0, 
	shakeCurve:^Curve=nil, 
	scaleCurves:[2]^Curve=nil, 
	alphaCurve:^Curve=nil, 
	dropShadow:Maybe(Color)=nil
) -> ^TextEffect{
	out := entity_make(TextEffect)

	out.transform.coords = {pos, z}

	out.duration = round(duration)

	out.stageEntity.blendData = {color, alpha, .blend}
	out.font = (font == nil) ? fonts.default : font
	out.alignment = alignment

	out.movement = movement
	effectMovement_init(movement, out.mover, &out.startPos)

	out.shake = shake
	out.shakeCurve = shakeCurve

	out.scaleCurves = scaleCurves
	out.alphaCurve = alphaCurve

	out.dropShadow = dropShadow

	textEffect_set(out, text)

	return out
}

// text_popup_make :: proc(text:string, pos:Vec2, z:f32, type:enum{scalePop, fadeFloat}){
// 	switch type{
// 		case .scalePop:
// 			textEffect_make()
// 		case .fadeFloat:
// 	}
// }


textEffect_set :: proc(using self:^TextEffect, text:string){

	tex_resize(&tex, text_size(text, font)+(dropShadow!=nil?1:0))
	tex_target_set(tex)
	shader_set(Sh_Base) //prevent doubling-up shader effects
		if col,ok := dropShadow.(Color); ok{
			text_draw(text, 1, 0, col, font=font)
			text_draw(text, 1, 1, col, font=font)
		}
		text_draw(text, 0, 0, font=font)

	shader_reset()
	tex_target_reset()
}

_textEffect_process_event :: proc(base:^ComponentBase, event:Event, overrideDisabled:=false){
if(!overrideDisabled && event in base.disabledEvents) do return
last_context := entities.context_component
defer cowith(last_context)
cowith(base)
self := cast(^TextEffect)base
using self
#partial switch event{
case .init:
	coadd(&stageEntity)
	stageEntity.visible = false
	stageEntity.static = false
	coadd(&transform)
	coadd(&mover)
case .update:
	if stageEntity.spriter.animSpeed == 0 && stageEntity.defaultAnimSpeed != 0 do return 
	if age >= duration{
		entity_destroy(self)
		return
	}
	prog := age/duration
	if scaleCurves.x != nil do transform.scale.x = curve_eval(scaleCurves.x, prog)
	if scaleCurves.y != nil do transform.scale.y = curve_eval(scaleCurves.y, prog)
	if alphaCurve != nil do stageEntity.alpha = curve_eval(alphaCurve, prog)
	
	effectMovement_apply(movement, mover, startPos, prog)
	age += 1
	
case .preDraw: depth = stageEntity.depth
case .draw: 
	drawPos := stageEntity_draw_pos(stageEntity)
	drawPos -= (Vec2(alignment)+{1,1})*Vec2(tex.size)/2*transform.scale

	shake_ := shake
	if shakeCurve != nil do shake_ *= curve_eval(shakeCurve, age/duration)
	if shake_ != 0 do drawPos += {random_range(-shake_.x, shake_.x), random_range(-shake_.y, shake_.y)}
	tex_draw_ex(tex, drawPos, transform.scale, 0, stageEntity.color, stageEntity.alpha)
case .clean: tex_destroy(tex)
}}
