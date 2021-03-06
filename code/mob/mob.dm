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

	///vehicle shit, sue me
	var/obj/vehicle/mounted

	prevent_pickup = TRUE

/mob/New()
	..()
	spawn(1)
		makeSlotsFromRace(new/datum/race)
		spawn(1)
			defaultInterface()
			refreshInterface()
	mobFaction = new/datum/faction/colonist
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
	if(mounted)
		if(mounted.CanPass(newLoc))
			mounted.Move(newLoc)
			return ..()
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
	var/dex = victim.playerData.dex.statModified
	var/obj/item/mainHand = attacker.activeHand()
	var/attackString = "punch [victim]"
	if(mainHand)
		attackString = "hit [victim] with [mainHand.name]"
		damage += (mainHand.force+mainHand.weight)*mainHand.size
	if(do_roll(1,def,dex) > damage)
		var/tod = !victim.isMonster ? "parry" : "feint"
		src.popup("[tod]",rgb(255,255,0))
		var/newDamage = victim.isMonster ? damage/4 : damage/2
		newDamage = round(newDamage)
		attacker.takeDamage(newDamage)
	else
		var/realDamage = victim.takeDamage(damage)
		if(realDamage > 0)
			messageArea("You [attackString] for [realDamage]HP (1d[damage]-[def])","[attacker] hits [victim] for [realDamage]HP (1d[damage]-[def])",attacker,victim,"red")
		else
			messageArea("Your blow only glances! (1d[damage]-[def])","[attacker] hits [victim] with a glancing blow! (1d[damage]-[def])",attacker,victim,"green")

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
			messagePlayer("You brush yourself off",src,src)
		else
			messageArea("You hug [src]","[user] hugs [src]",user,src)
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
	screenObjs += new/obj/interface/intentButton(13,1,"box",32)
	screenObjs += new/obj/interface/leapButton(13,2,"box",32)

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
						var/image/sa = image(icon=SC.heldSpell.heldAbility.abilityIcon,icon_state=SC.heldSpell.heldAbility.abilityState)
						var/image/scd = image(icon='sprite/obj/ability.dmi',icon_state="cd_[cd]")
						SC.overlays |= sa
						SC.overlays |= scd
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
