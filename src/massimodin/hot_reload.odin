package massimodin //@nested-tags:engine/metaprogramming

import "core:reflect"

GlobalState :: struct{
	audio:^AudioSystem,
	au:^AudioIDs,
	camera:^CameraSystem,
	collision_system:^CollisionSystem,
	curves:^CurveSystem,
	cu:^CurveIDs,
	debug:^DebugSystem,
	shell:^DebugShellSystem,
	display:^DisplaySystem,
	entities:^EntitySystem,
	_flags:^FlagMap,
	input:^InputSystem,
	ginputs:^GInputVerbArray,
	assets:^AssetSystem,
	particles:^ParticlesSystem,
	seq:^SequenceSystem,
	shaders:^ShaderSystem,
	sh:^ShaderIDs,
	sprites:^SpriteSystem,
	sp:^SpriteIDs,
	fonts:^FontSystem,
	fo:^FontIDs,
	tilesets:^TilesetSystem,
	time:^TimeSystem,
	ui:^UISystem,
	steamworks:^SteamworksSystem,

	dialogue:^DialogueSystem,
	di:^DialogueIDs,
	stage:^StageSystem,
	st:^StageIDs,
	stage_edit:^StageEditSystem,
	combat:^CombatSystem,
	ca:^CombatBasicActionIDs,
	items:^ItemSystem,
	save:^SaveDataSystem,
	cutscene:^CutsceneSystem,
	player_characters:^PlayerCharacterSystem,
	foliage_system:^FoliageSystem

	//imgui_system:ImguiSystem, //must be reinitialized due to the library not being a .dll, state is preserved in imgui.ini

}

//save global variables
@export
_pre_hot_reload :: proc() -> rawptr{
	gs := new(GlobalState, os_allocator)

	gs.audio = audio
	gs.au = au 
	gs.camera = camera 
	gs.collision_system = collision_system 
	gs.curves = curves
	gs.cu = cu
	gs.debug = debug
	gs.shell = shell 
	gs.display = display 
	gs.entities = entities 
	gs._flags = _flags
	gs.input = input 
	gs.ginputs = ginputs 
	gs.assets = assets
	gs.particles = particles
	gs.seq = seq
	gs.shaders = shaders 
	gs.sh = sh 
	gs.sprites = sprites 
	gs.sp = sp 
	gs.fonts = fonts 
	gs.fo = fo 
	gs.tilesets = tilesets 
	gs.time = time
	gs.ui = ui
	gs.steamworks = steamworks

	gs.dialogue = dialogue 
	gs.di = di 
	gs.stage = stage 
	gs.st = st 
	gs.stage_edit = stage_edit 
	gs.combat = combat
	gs.ca = ca
	gs.items = items
	gs.save = save
	gs.cutscene = cutscene
	gs.player_characters = player_characters
	gs.foliage_system = foliage_system

	_imgui_shutdown()

	return gs
}

//load global variables
@export
_post_hot_reload :: proc(globalStatePtr:rawptr){
	gs := cast(^GlobalState)globalStatePtr
	
	audio = gs.audio 
	au = gs.au 
	camera = gs.camera 
	collision_system = gs.collision_system
	curves = gs.curves
	cu = gs.cu
	debug = gs.debug
	shell = gs.shell 
	display = gs.display 
	entities = gs.entities
	_flags = gs._flags
	input = gs.input 
	ginputs = gs.ginputs 
	assets = gs.assets
	particles = gs.particles
	seq = gs.seq
	shaders = gs.shaders 
	sh = gs.sh 
	sprites = gs.sprites 
	sp = gs.sp 
	fonts = gs.fonts 
	fo = gs.fo 
	tilesets = gs.tilesets 
	time = gs.time
	ui = gs.ui
	steamworks = gs.steamworks

	dialogue = gs.dialogue 
	di = gs.di 
	stage = gs.stage 
	st = gs.st 
	stage_edit = gs.stage_edit 
	combat = gs.combat
	ca = gs.ca
	items = gs.items
	save = gs.save
	settings = &save.settings
	cutscene = gs.cutscene
	player_characters = gs.player_characters
	foliage_system = gs.foliage_system

	//libraries that need to be reinitialized
	_imgui_init()
	_gl_init()

	//must be reinitialized to refresh stored type ids and proc pointers
	_components_metadata_init() 
	//_combat_actions_reload()
	_combat_unit_inits_reload()
	_reload_stage_procs()
	_cutscenes_reload()
	_shell_commands_reload()

	free(gs)

	_entities_event_process(.codeReload)

	_imgui_scale_update()

	_testbed_reload()
}