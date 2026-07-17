#+feature using-stmt
package massimodin //@nested-tags:combat/actions

_combat_actions_reload_minima :: proc(){
	combat.actions["minimaSlash"] = CombatAction{
		startup=3,
		cooldown=4,
		damage=3,
		hitstun=3,
		aimRange=6,
		kind=.attack,
		aimKind=.directionalRanged,
		actionSelectIcon = sp.combatActionIcons_swordSwing, //todo: better icon
		targetMask = sp.minimaAttackMask_slash,
		resolve = proc(caq:^CombatActionQueued) -> bool{
			return combat_actions_basic_ranged_attack_sequence(caq, sp.minima_combatAction_swingCast,
				sp.minima_attackEffect_slash, sprite_frame_time_get(sp.minima_combatAction_swingCast, 11), 1,
				{au.minimaSwing, 7}, {au.minimaSlash, 0}
			)
		}
	}
	combat.actions["minimaHelix"] = CombatAction{
		startup=4,
		cooldown=3,
		damage=6,
		hitstun=4,
		aimRange=9,
		kind=.attack,
		aimKind=.freeAim,
		actionSelectIcon = sp.combatActionIcons_helix,
		targetMask = sp.minimaAttackMask_helix,
		resolve = proc(caq:^CombatActionQueued) -> bool{
			return combat_actions_basic_ranged_attack_sequence(caq, sp.minima_combatAction_upwardsCast,
				sp.minima_attackEffect_helix, sprite_frame_time_get(sp.minima_combatAction_upwardsCast, 8), 12,
				{au.minimaSwing, 6}, {au.minimaHelix, 0}
			)
		}
	}

}