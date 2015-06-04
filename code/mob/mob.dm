/mob
	icon = 'sprite/mob/human.dmi'
	luminosity = 4
	var/list/screenObjs = list()
	var/intent = INTENT_HELP
	var/canMove = TRUE
	//spell vars
	var/casting = FALSE

	var/obj/spellHolder/castingSpell
	var/obj/interface/Cursor
	var/maxHotkeys = 9
	var/selectedHotKey = 1
	var/datum/faction/mobFaction

	prevent_pickup = TRUE

/mob/New()
	spawn(1)
		makeSlotsFromRace(new/datum/race)
		spawn(1)
			defaultInterface()
			refreshInterface()

	add_pane(/datum/windowpane/verbs)
	add_pane(/datum/windowpane/debug)

/mob/Login()
	if(!client.mob)
		spawn(5)
			var/mob/player/P = new
			client.mob = P
			spawn(5)
				P.playerSheet()
	..()

/mob/Move(var/atom/newLoc)
	if(!newLoc)
		return
	if(client)
		if(client.isDM)
			..()
	if(canMove && !checkEffectStack("no_move") && !newLoc.density && !anchored)
		..()

/client/Click(var/clickedOn)
	if(mob)
		if(mob.casting == TRUE && istype(clickedOn,/atom/movable))
			mob.castingSpell.heldAbility.tryCast(mob,clickedOn)
			mob.casting = FALSE
			mob.castingSpell = null
			mob.client.mouse_pointer_icon = null
		else
			..()
//////////////////////////////////////////////////////

/mob/proc/processAttack(var/mob/player/attacker,var/mob/player/victim)
	var/damage = attacker.playerData.str.statModified
	var/def = victim.playerData.def.statModified //only here for calculations in output
	var/obj/item/mainHand = attacker.activeHand()
	var/attackString = "punch [victim]"
	if(mainHand)
		attackString = "hit [victim] with [mainHand.name]"
		damage += (mainHand.force+mainHand.weight)*mainHand.size
	victim.takeDamage(damage)
	displayInfo("You [attackString] for [max(0,damage-def)]HP (1d[damage]-[def])","[attacker] hits [victim] for [max(0,damage-def)]HP (1d[damage]-[def])",attacker,victim,"red")

/mob/proc/intent2string()
	if(intent == 1)
		return "Helping"
	if(intent == 2)
		return "Harming"
	if(intent == 3)
		return "Sneaking"

/mob/objFunction(var/mob/user,var/obj/inHand)
	if(user.intent == INTENT_HELP)
		if(user == src)
			displayTo("You brush yourself off",src,src)
		else
			displayInfo("You hug [src]","[user] hugs [src]",user,src)
	if(user.intent == INTENT_HARM)
		processAttack(user,src)

/mob/proc/defaultInterface()
	for(var/i = 1; i <= maxHotkeys; ++i)
		screenObjs += new/obj/interface/spellContainer("[i]",1,"sphere")
		var/obj/interface/spellContainer/scrnobj = screenObjs[screenObjs.len]
		scrnobj.name = "Slot [i]"
		scrnobj.hotKey = i
	for(var/i = 1; i <= maxHotkeys; ++i)
		screenObjs += new/obj/interface("[i]",1,"[i]")
	for(var/slotid in slots)
		var/obj/interface/slot/S = slots[slotid]
		screenObjs += S
		interfaceSlots += S

	screenObjs += new/obj/interface/pickupButton(10,1,"box",32)
	screenObjs += new/obj/interface/dropButton(11,1,"box",32)
	screenObjs += new/obj/interface/storeButton(11,2,"box",32)
	screenObjs += new/obj/interface/useButton(12,1,"box",32)
	screenObjs += new/obj/interface/dropIButton(12,2,"box",32)
	screenObjs += new/obj/interface/throwButton(10,2,"box",32)

/mob/proc/refreshInterface()
	if(client)
		screenObjs -= Cursor
		client.screen = newlist()
		Cursor = new/obj/interface(selectedHotKey,1,"select")
		Cursor.layer = LAYER_INTERFACE+0.1
		screenObjs |= Cursor
		for(var/obj/interface/I in screenObjs)
			if(istype(I,/obj/interface/spellContainer))
				var/obj/interface/spellContainer/SC = I
				if(SC.heldSpell)
					if(SC.heldSpell.heldAbility.abilityCooldownTimer)
						I.overlays.Cut()
						var/cd = round(min(10,SC.heldSpell.heldAbility.abilityCooldownTimer/60),1)
						SC.overlays |= image(icon=SC.heldSpell.heldAbility.abilityIcon,icon_state=SC.heldSpell.heldAbility.abilityState)
						SC.overlays |= image(icon='sprite/obj/ability.dmi',icon_state="cd_[cd]")
						//hacky, sue me
						spawn(15)
							I.overlays.Cut()
							SC.overlays |= image(icon=SC.heldSpell.heldAbility.abilityIcon,icon_state=SC.heldSpell.heldAbility.abilityState)
			I.showTo(src)

		for(var/slotid in slots)
			var/obj/interface/slot/S = slots[slotid]

			S.align(src)
			S.rebuild()

		update_panes()
