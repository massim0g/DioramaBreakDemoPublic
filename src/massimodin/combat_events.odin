package massimodin //@nested-tags:combat/

/*
Combat events will pass in pointers to relevant data which can be modified. 
Events can be used for various things:
	- cutscene triggers
	- buffs/debuffs and other passive effects
*/

CombatEventData :: union{
	CombatEventDataHit,
	CombatEventDataHitEnd,
	CombatEventAttackEnd,
	CombatEventDataActionResolved,
	CombatEventDataStepEnd,
	CombatEventStarted,
	CombatEventEnded,
	CombatEventUpdate,
	CombatEventResolveStarted,
	CombatEventResolveEnded,
	CombatEventPlanningStarted,
	CombatEventPlanningEnded,
	CombatEventAIPlanningStart
}
CombatEventDataHit :: struct{
	attacker:^CombatUnit,
	target:^CombatUnit,
	damage:^int,
	hitstun:^int,
	damageKind:^CombatDamageKind
}
CombatEventDataHitEnd :: struct{
	attacker:^CombatUnit,
	target:^CombatUnit,
	damage:int,
	hitstun:int,
	damageKind:CombatDamageKind
}
CombatEventAttackEnd :: struct{
	attacker:^CombatUnit,
	hitUnits:[]^CombatUnit,
}

CombatEventDataStepEnd :: struct{}

CombatEventDataActionResolved :: struct{
	action:^CombatActionQueued
}

CombatEventResolveStarted :: struct{}
CombatEventResolveEnded :: struct{}
CombatEventPlanningStarted :: struct{}
CombatEventPlanningEnded :: struct{}

CombatEventStarted :: struct{}

//called after the combat end sequence
CombatEventEnded :: struct{}

CombatEventUpdate :: struct{}

CombatEventCallback :: struct{
	p:CombatEventProc,
	attachedTo:^CombatUnit,
	expiryTimer:int,
	priority:f32
} //todo: passives display info

//called after a unit clears its actions before planning but before it enters the planning loop
CombatEventAIPlanningStart :: struct{
	unit:^CombatUnit
}

CombatEventProc :: #type proc(self:^CombatEventCallback, event:CombatEventData)

combat_event_process :: proc(event:CombatEventData){
	_,isTurnEnd := event.(CombatEventDataStepEnd) 
	#reverse for &callback, i in combat.eventCallbacks{
		callback.p(&callback, event)
		if isTurnEnd && callback.expiryTimer > 0{
			callback.expiryTimer -= 1
			if callback.expiryTimer == 0 do ordered_remove(&combat.eventCallbacks, i)
		}
	} 
} 

combat_event_callback_add :: proc(
	callback:CombatEventProc,
	attachedTo:^CombatUnit=nil,
	expiryTimer:int=-1,
	priority:f32=0
){
	append(&combat.eventCallbacks, CombatEventCallback{
		callback,
		attachedTo,
		expiryTimer,
		priority
	})
	sort(&combat.eventCallbacks, proc(a,b:CombatEventCallback)->bool{
		return a.priority < b.priority
	})
}