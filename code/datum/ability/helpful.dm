/datum/ability/heal
	name = "Heal"
	desc = "Heals a target"
	abilityRange = 8
	abilityModifier = 1
	abilityCooldown = 1*60
	abilityProjectiles = 8
	abilityState = "redcross"
	abilityIconSelf = /obj/effect/pow
	abilityProjectile = /obj/projectile/healingblast
	abilityIconTarget = /obj/effect/heal

///
// DEFENDER SPELLS
///

/datum/ability/taunt
	name = "Taunt"
	desc = "Throws a chain at a target, dragging them to you."
	abilityRange = 8
	abilityModifier = -1
	abilityCooldown = 5*60
	abilityState = "shout"
	abilityHitsPlayers = TRUE
	abilityIconSelf = /obj/effect/pow
	abilityProjectile = /obj/projectile/spear
	abilityIconTarget = /obj/effect/target

/datum/ability/taunt/Cast(var/mob/player/caster,var/target)
	..()
	var/atom/movable/AM = target
	if(AM)
		caster.Beam(abilityCastedProjectile,time=15,icon_state="c_beam")