package massimodin //@nested-tags:_main

import "core:reflect"
import "core:odin/ast"
import "core:prof/spall"
import "core:mem"
import "core:mem/virtual"
import "../tinyfd"
import "core:strings"
import "core:path/filepath"
import "core:encoding/json"
import "../imgui"
import "base:intrinsics"

_testbed_pre_init :: proc(){
}

_testbed_post_init :: proc(){

	titleScreen_goto()
	//stage_goto(st.townCenter)

	//player_character_join_party(.minima)
	//player_follower_add("minima")

	// display.hd_enabled = true
	// _stage_unload()
	// entity_make(SplashScreen).tease = true

	//player_character_equip(.pro, "whistlingBlade")
	//_testbed_equipment()
	//_testbed_consequence_encounter()
	//_testbed_polema_rematch()
	//_testbed_post_game()
	//dialogue_label_seen_set(di.combatTutorial, "polemaFightTutorial")
	
	
	//delayed
	proc_call_delayed(proc(){
		
	}, 2)
}


_testbed_update :: proc(){
}

_testbed_draw :: proc(){
}

//called on code reload
_testbed_reload :: proc(){
	//_blobFoliage_system_reload()
}


//scenario inits
_testbed_polema_rematch :: proc(){
	flag("encounteredPolema")
	flag("combatTutorialFailed")
	flag("tutorialLostTo", "polema")
	stage_goto(st.lowerArea)
}

_testbed_consequence_encounter :: proc(){
	player_follower_add("minima")
	flag("proAff", "0")
	flag("warnedProAboutConsequence")
	inventory_add("trainingBlade")
	inventory_add("normalBoots")
	stage_goto(st.IrisForestEdge)
}

_testbed_post_game :: proc(){
	player_follower_add("minima")
	player_character_join_party(.minima)
	flag("demoCompleted")
	stage_goto(st.IrisForestEdgeShrine)
}

_testbed_equipment :: proc(){
		inventory_add("trainingBlade")
		inventory_add("whistlingBlade")
		inventory_add("irisVest")
		inventory_add("normalBoots")
		inventory_add("windyBoots")
		//player_character_equip(.pro, "trainingBlade")
		//player_character_equip(.pro, "windyBoots")
}


//ARCHIVE

//INIT

	//pivotal choice
		// pc := entity_make(PivotalChoice)
		// pc.options = {
		// 	{"Reach Out", nil_proc},
		// 	{"No", proc(){
		// 		pc := cofind(PivotalChoice, 0)
		// 		pc.age = 0
		// 	}}
		// }
		// pc.timedOption = true



	
	//splash screen
		// display.hd_enabled = true
		// _stage_unload()
		// entity_make(SplashScreen).tease = true


// INIT DELAYED
	// p := entity_make(Player)
	// p.transform.pos = cofind(CheckpointRadius, 0).transform.pos
	// game_save()

	// chion := entity_make(CombatUnit)
	// //kion := entity_make(CombatUnit)
	// //akro := entity_make(CombatUnit)
	// polema := entity_make(CombatUnit)
	// chion.initID = "chion"
	// //kion.initID = "kion"
	// //akro.initID = "akro"
	// polema.initID = "polema"
	// chion.stageCharacter.initID = "chion"
	// //kion.stageCharacter.initID = "kion"
	// //akro.stageCharacter.initID = "akro"
	// polema.stageCharacter.initID = "polema"
	// combatUnit_reload(chion)
	// //combatUnit_reload(kion)
	// //combatUnit_reload(akro)
	// combatUnit_reload(polema)
	// // stageCharacter_reload(chion.stageCharacter)
	// // stageCharacter_reload(kion.stageCharacter)
	// // stageCharacter_reload(akro.stageCharacter)
	// // stageCharacter_reload(polema.stageCharacter)

	// chion.stageEntity.transform.pos = {576, 224} 
	// //kion.stageEntity.transform.pos = {576, 180} 
	// //akro.stageEntity.transform.pos = {576, 288} 
	// polema.stageEntity.transform.pos = {500, 224} 

	// _entities_just_made_process()

	// combat_start()

//UPDATE

	//Consequence ambush death
		// if key_pressed(.KP_0){
		// 	flag("diedTo", "consequenceAmbush", level=.local)
		// 	flag("consequenceWarnable", level=.persistent)
		// 	game_over(true)
		// } 

	//smoke bomb
		// if mouse_pressed(.LEFT){
		// 	smokeParticleWhite := particle_type(
		// 		sp.circle256, 15, 50,
		// 		0, 15, cu.popIn_inv, minScale=1./256., maxScale=22./256., scaleCurves=cu.easeOutStrong_inv,  
		// 	)
		// 	smokeParticleGray_ := smokeParticleWhite^
		// 	smokeParticleGray_.colors = COLOR_GRAY
		// 	smokeParticleGray := particle_type_clone(smokeParticleGray_)

		// 	particles_emit(smokeParticleGray, 100, layer_depth(.stageFG)+2, Rect{mouse_stage_pos(), 1})
		// 	particles_emit(smokeParticleWhite, 600, layer_depth(.stageFG), Rect{mouse_stage_pos(), 1})
		// 	particles_emit(smokeParticleGray, 100, layer_depth(.stageFG)-2, Rect{mouse_stage_pos(), 1})
		// }

//DRAW

	//display ghost (e.g. for timestop)
		// if key_pressed(.N) do ui_cue("ghostTest")
		// t := ui_cue_time("ghostTest")
		// //display_ghost_effect(4, 5, -1, 0.9, cu.easeInStrong, t, 60)
		// display_ghost_effect(4, 5, -1, 1/0.9, cu.easeInStrong, t, 60)
		// //if t > 60-36 do display_ghost_effect(6, 6, 0, 1/0.95, cu.easeInStrong, t, 60)

	//fuzzy circle
		//mdp := mouse_display_pos()
		//fuzzy_circle_draw(Circle{DISPLAY_SIZE/2, vec2_distance(DISPLAY_SIZE/2, mdp)}, 0.4, 1, 16)

	//sdf balls and contour test
		// mdp := mouse_display_pos()
		// balls := []SDFShape{
		// 	Circle{mdp, 30},
		// 	Circle{{00,00}, 30},
		// 	Circle{{200,120}, 30},
		// }
		// sdf_draw(balls, 30, COLOR_YELLOW, offset={30,30})

		// contour := sdf_trace_contour(mdp + {30, 0}, balls, 30, 2)
		// draw_color(COLOR_GREEN)
		// for ray in contour{
		// 	draw_line(ray.pos, vec2_offset(ray.dir, 5, ray.pos))
		// }
		// camera_reset()
	
	//blob foliage system tests
		//tex_draw(foliage_system.test_blob, mouse_display_pos()-100)
		//tex_draw(stage.shadow_map, 0, 0)

		//dst := sdl3.Rect{i32(-stage.camera_pos.x), i32(-stage.camera_pos.y), 4096, 4096}
		//sdl3.RenderCopy(display._renderer, foliage_system.texture_page, nil, &dst)
		
		// dst := sdl3.Rect{10, 10,0,0}
		// for type in foliage_system.blob_frame_positions{
		// 	src := type[0]
		// 	if dst.x+src.w >= DISPLAY_WIDTH-10{
		// 		dst.x = 10
		// 		dst.y += src.h
		// 	}
		// 	dst.w = src.w
		// 	dst.h = src.h
		// 	sdl3.RenderCopy(display._renderer, foliage_system.texture_page, &src, &dst)
		// 	dst.x += src.w
		// }

		// p1 := Vec2{100, 100}
		// p2 := Vec2{200, 120}
		// random_set_seed(10)
		// for n in 0..<1000{
		// 	pole := choose([]Vec2{p1, p2})
		// 	mdp := vec2_random()*(random_range(0,1)*100)+pole
		// 	p1c := gauss_falloff(min(vec2_distance(p1, mdp)/150, 1), BLOB_FOLIAGE_POLE_FALLOFF)*BLOB_FOLIAGE_POLE_BASE_PROBABILITY
		// 	p2c := gauss_falloff(min(vec2_distance(p2, mdp)/150, 1), BLOB_FOLIAGE_POLE_FALLOFF)*BLOB_FOLIAGE_POLE_BASE_PROBABILITY
		// 	totalC := p1c+p2c
	
		// 	avg := vec2_normalize(vec2_dir(mdp, p1)*(p1c/totalC)+vec2_dir(mdp, p2)*(p2c/totalC))
		
		// 	draw_color(COLOR_RED)
		// 	draw_line(mdp, mdp+avg*8)
		// 	draw_color(COLOR_YELLOW)
		// 	draw_point(mdp)
		// }
		// draw_color(COLOR_MAGENTA)
		// draw_point(p1)
		// draw_point(p2)
	
