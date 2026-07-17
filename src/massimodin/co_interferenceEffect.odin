#+feature using-stmt
package massimodin //@nested-tags:_components/

InterferenceEffect :: struct{
	using base:RenderComponentBase,
	minInnerRadius:f32,
	alpha:f32
}

interference_seq :: proc(duration:int) -> bool{
	if seq_open(){
		if seq_cue(0){
			entity_make(InterferenceEffect)
			bg := entity_make(MeditationBG)
			player,ok := cofind(Player, 0)
			bg.depth = ok ? player.stageEntity.depth.(f32) + 0.5 : -DEPTH_MAX + 0.5
			bg.perlinStrength = 0.36
			audio_play(au.dioramaEntryBuzz)
		}
		if seq_cue(0, duration){
			prog := seq_map(0, 1, cu.easeInArc)
			audio_volume_set(au.dioramaEntryBuzz, prog)
			cofind(InterferenceEffect, 0).alpha = prog
			flicker :f32= roll(0.3) ? random_range_f(0.4, 0.7) : 1.0
			cofind(MeditationBG, 0).alpha = prog*0.5 * flicker
		}
		if seq_cue(duration){
			audio_stop(au.dioramaEntryBuzz)
			entity_destroy(InterferenceEffect)
			entity_destroy(MeditationBG)
			return seq_close(.end)
		}
	}
	return seq_close()
}

_interferenceEffect_process_event :: proc(base:^ComponentBase, event:Event, overrideDisabled:=false){
if(!overrideDisabled && event in base.disabledEvents) do return
last_context := entities.context_component
defer cowith(last_context)
cowith(base)
self := cast(^InterferenceEffect)base
using self
#partial switch event{
case .init:
	depth = -DEPTH_MAX
	alpha = 1
case .draw:
	camera_set(0)
	innerRadiusX := wave(minInnerRadius, minInnerRadius+50, 250)
	outerRadiusX :f32= minInnerRadius+200
	draw_rings(
		display_size()/2-CAMERA_DEFAULT_TRACKING_OFFSET/2, 
		{DISPLAY_ELLIPSE_RADIUS+abs(CAMERA_DEFAULT_TRACKING_OFFSET),  Vec2{outerRadiusX, outerRadiusX*(9./16.)}, Vec2{innerRadiusX, innerRadiusX*(9./16.)}, 0}, 
		{COLOR_BLACK, COLOR_BLACK, COLOR_BLACK, COLOR_BLACK}, 
		{alpha, alpha, 0.25*alpha, 0.25*alpha}
	)
	camera_reset()

}}
