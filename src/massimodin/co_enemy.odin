#+feature using-stmt
package massimodin //@nested-tags:_components/

//Roaming overworld enemies
Enemy :: struct{
	using base:RenderComponentBase,
	stageEntity:CoRef(StageEntity),
	stageCharacter:CoRef(StageCharacter),
	transform:CoRef(Transform),
	mover:CoRef(Mover),
	wanderer:CoRef(Wanderer),
	combatUnit:CoRef(CombatUnit),
	encounterID:Estring, //@e
	encounterFlagLevel:FlagLevel, //@e
	perceptionRadius:f32, //@e
	aggroFXOffset:int,
	awareOfPlayer:bool,
	isAlertedEnemy:bool
}

_enemy_process_event :: proc(base:^ComponentBase, event:Event, overrideDisabled:=false){
if(!overrideDisabled && event in base.disabledEvents) do return
last_context := entities.context_component
defer cowith(last_context)
cowith(base)
self := cast(^Enemy)base
using self
#partial switch event{
case .init:
	coadd(&stageEntity)
	coadd(&stageCharacter)
	coadd(&transform)
	coadd(&mover)
	coadd(&wanderer)
	coadd(&combatUnit)
	estring_set(&encounterID, stage.name, true)
	encounterFlagLevel = .temp
	perceptionRadius = 100
	stageCharacter.useCombatSpritesInOverworld = true
	combatUnit.forceCombatGridEntry = true

case .loaded:
	if !stage_edit.enabled && flag_check(format("encounter__%s", encounterID)) do entity_destroy(self)
case .update:
	if combat.phase == .disabled{
		if !awareOfPlayer{
			if player,ok := cofind(Player, 0); ok{
				if vec2_distance(player.transform.pos, transform.pos) < perceptionRadius{
					enemies := coall(Enemy)
					for &enemy,i in enemies{
						enemy.awareOfPlayer = true
						enemy.wanderer.disabled = true
						aggroFXOffset = (i+1)*8
						mover_zero(enemy.mover)
						scface_other(enemy.stageCharacter, player.stageCharacter)
					}
					aggroFXOffset = 0
					isAlertedEnemy = true
					ui_cue("enemiesAlerted")
				}
			}
		}
		else if isAlertedEnemy{
			seq_open("enemyAlert")
			if seq_time() > 30{
				isAlertedEnemy = false
				combat_start(encounterID=encounterID.s, encounterFlagLevel=encounterFlagLevel, resetCameraOnEnd=true)
				seq_close(.end)
			}
			else do seq_close()
		}
	}
case .preDraw:
	depth = stageEntity.depth.(f32) - 0.5
case .draw:
	if awareOfPlayer{
		dr := stageEntity_draw_rect(stageEntity, 0)
		dp := Vec2{rect_center(dr).x, dr.y - 4}
		#partial switch combat.phase{
			case .starting:
				sprite_draw(sp.aggro_vfx_aggro_out, dp, sprite_frame_get(sp.aggro_vfx_aggro_out, f32(ui_cue_time("combatStart")), true))
			case .disabled:
				t := f32(ui_cue_time("enemiesAlerted") - aggroFXOffset)
				if t > f32(sprite_duration(sp.aggro_vfx_aggro_in)){
					sprite_draw(sp.aggro_vfx_aggro_loop, dp, sprite_frame_get(sp.aggro_vfx_aggro_loop, t))
				}
				else if t >= 0{
					sprite_draw(sp.aggro_vfx_aggro_in, dp, sprite_frame_get(sp.aggro_vfx_aggro_in, t, true))
				}
		}
	}
case .clean:
	if isAlertedEnemy{ //edge-case catch in case player leaves the room during alert sequence
		seq_open("enemyAlert")
		seq_close(.end)
	}
	estring_delete(&encounterID)
}}
