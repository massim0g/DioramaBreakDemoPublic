#+feature using-stmt
package massimodin //@nested-tags:_components/

MeditationBG :: struct{
	using base:RenderComponentBase,
	myTex:Tex,
	perlinStrength:f32,
	alpha:f32
}

meditation_start_seq :: proc(char:^StageCharacter, fadeTime:=75, holdTime:=125) -> bool{
	if seq_open(){
		if seq_cue(0){
			char.stageEntity.editableDepthOffset -= stage.bounds.size.y
			entity_make(MeditationBG)
		}
		
		bg := cofind(MeditationBG, 0)

		if fadeTime <= 0 do bg.alpha = 1
		else if seq_cue(0, fadeTime) do bg.alpha = seq_map(0, 1)
		
		if seq_cue(fadeTime + holdTime){

			return seq_close(.end)
		}
	}
	return seq_close()
}

meditation_end_seq :: proc(char:^StageCharacter, fadeTime:=75, holdTime:=125, stopMusic:=true) -> bool{
	if seq_open(){
		bg := cofind(MeditationBG, 0)

		if seq_cue(0) && stopMusic do music_set(nil)

		if fadeTime > 0 && seq_cue(0, fadeTime) do bg.alpha = seq_map(1, 0)

		if seq_cue(fadeTime + holdTime){
			char.stageEntity.editableDepthOffset += stage.bounds.size.y
			entity_destroy(bg)
			return seq_close(.end)
		}
	}
	return seq_close()
}

_meditationBG_process_event :: proc(base:^ComponentBase, event:Event, overrideDisabled:=false){
if(!overrideDisabled && event in base.disabledEvents) do return
last_context := entities.context_component
defer cowith(last_context)
cowith(base)
self := cast(^MeditationBG)base
using self
#partial switch event{
case .init:
	depth = -stage.bounds.size.y //draw above most stage entities
	alpha = 0
	myTex = tex_make(DISPLAY_SIZE)
	tex_target_set(myTex,clear=false)
	draw_clear(COLOR_BLACK)
	tex_target_clear()

case .draw:
	shader_set(Sh_MeditationBG{
		time = f32(time.frame),
		strength = f32(perlinStrength),
		scale = 5.5,
	})
	camera_set(0)
	tex_draw_ex(myTex, Vec2{}, alpha=alpha)
	camera_reset()
	shader_reset()
	
case .clean:
	tex_destroy(myTex)

}}
