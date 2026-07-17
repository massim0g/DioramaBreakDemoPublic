package massimodin //@nested-tags:

game_over :: proc(instantDeath:=false){
	if instantDeath do flag("instantDeath", level=.local)
	_stage_unload()
	audio_background_stop(false)
	cutscene_start("gameOver")
}