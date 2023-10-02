/**
 * Playable bots
 */
ABSTRACT_TYPE(/mob/living/critter/robotic/bot)
/mob/living/critter/robotic/bot
	name = "base bot mob (you should never see me)"
	icon = 'icons/obj/bots/aibots.dmi'
	blood_id = "oil"
	speechverb_say = "beeps"
	speechverb_gasp = "warbles"
	speechverb_stammer = "bleeps"
	speechverb_exclaim = "boops"
	speechverb_ask = "bloops"
	stepsound = "step_plating"
	robot_talk_understand = TRUE
	hand_count = 1
	can_burn = FALSE
	dna_to_absorb = 0
	metabolizes = FALSE
	custom_gib_handler = /proc/robogibs
	stepsound = null
	/// defined in new, this is the base of the icon_state with the suffix removed, i.e. "cleanbot" without the "1"
	var/icon_state_base = null
	var/brute_hp = 25
	var/burn_hp = 25
	var/emagged = FALSE

	New()
		. = ..()
		remove_lifeprocess(/datum/lifeprocess/blindness)
		remove_lifeprocess(/datum/lifeprocess/viruses)
		remove_lifeprocess(/datum/lifeprocess/blood)
		remove_lifeprocess(/datum/lifeprocess/radiation)
		new /obj/item/implant/access/infinite/assistant(src)

	setup_hands()
		..()
		var/datum/handHolder/HH = hands[1]
		HH.limb = new /datum/limb/small_critter
		HH.icon = 'icons/mob/critter_ui.dmi'
		HH.icon_state = "handn"
		HH.name = "grabber"
		HH.limb_name = "grabber"
		HH.can_hold_items = 1
		HH.can_attack = 1
		HH.can_range_attack = 0
		if(src.emagged == TRUE)
			var/datum/limb/small_critter/L = HH.limb
			L.max_wclass = W_CLASS_SMALL

	setup_healths()
		add_hh_robot(brute_hp, 1)
		add_hh_robot_burn(burn_hp, 1)

	get_melee_protection(zone, damage_type)
		return 3

	get_ranged_protection()
		return 2

	death(var/gibbed)
		..(gibbed, 0)
		if (!gibbed)
			gib(src)
		else
			playsound(src.loc, 'sound/impact_sounds/Machinery_Break_1.ogg', 50, 1)
			make_cleanable(/obj/decal/cleanable/oil,src.loc)

	specific_emotes(var/act, var/param = null, var/voluntary = 0)
		switch (act)
			if ("scream")
				if (src.emote_check(voluntary, 50))
					playsound(get_turf(src), 'sound/voice/screams/robot_scream.ogg' , 10, 0, pitch = -1, channel=VOLUME_CHANNEL_EMOTE)
					return "<b>[src]</b> screams!"
		return null

	specific_emote_type(var/act)
		switch (act)
			if ("scream")
				return 2
		return ..()

	cleanbot
		name = "cleanbot"
		real_name = "cleanbot"
		desc = "A little cleaning robot, he looks so excited!"
		icon_state = "cleanbot1"
		icon_state_base = "cleanbot"

		New()
			. = ..()
			if(prob(50))
				icon_state = "cleanbot-red1"
				icon_state_base = "cleanbot-red"

			color = pick(list(
				null,\
				list(0,1,0,0,0,1,1,0,0),\
				list(0,0,1,1,0,0,0,1,0),\
				list(0.5,0.5,0,0,0.5,0.5,0.5,0,0.5),\
				list(0.5,0,0.5,0.5,0.5,0,0,0.5,0.5),
			))

			src.create_reagents(60)
			src.reagents.add_reagent("cleaner", 10)
			src.abilityHolder.addAbility(/datum/targetable/critter/bot/mop_floor)
			src.abilityHolder.addAbility(/datum/targetable/critter/bot/reagent_scan_self)
			src.abilityHolder.addAbility(/datum/targetable/critter/bot/dump_reagents)

		emag_act(mob/user, obj/item/card/emag/E)
			. = ..()
			if(!src.emagged)
				playsound(src, 'sound/effects/sparks4.ogg', 50)
				src.audible_message("<span class='alert'><B>[src] buzzes oddly!</B></span>")
				src.abilityHolder.addAbility(/datum/targetable/critter/bot/fill_with_chem/lube)
				src.abilityHolder.addAbility(/datum/targetable/critter/bot/fill_with_chem/phlogiston_dust)
				src.emagged = TRUE
				return TRUE

		is_open_container()
			return TRUE

		emagged
			brute_hp = 50
			burn_hp = 50
			emagged = TRUE
			New()
				. = ..()
				src.abilityHolder.addAbility(/datum/targetable/critter/bot/fill_with_chem/lube)
				src.abilityHolder.addAbility(/datum/targetable/critter/bot/fill_with_chem/phlogiston_dust)

ABSTRACT_TYPE(/datum/targetable/critter/bot)
/datum/targetable/critter/bot/mop_floor
	name = "Mop Floor"
	desc = "Clean the floor of dirt and other grime."
	icon_state = "clean_mop"
	targeted = TRUE
	target_anything = TRUE
	cooldown = 1.5 SECONDS
	max_range = 1

	cast(atom/target)
		if(!holder?.owner)
			return TRUE
		actions.start(new/datum/action/bar/icon/mob_cleanbot_clean(holder.owner, target), holder.owner)

ABSTRACT_TYPE(/datum/targetable/critter/bot/fill_with_chem)
/datum/targetable/critter/bot/fill_with_chem
	name = "Synthesize Reagent"
	targeted = FALSE
	cooldown = 30 SECONDS
	var/reagent_id = null

	cast(atom/target)
		if(!holder?.owner?.reagents)
			return TRUE
		holder.owner.reagents.add_reagent(reagent_id, 30)
		playsound(holder.owner.loc, 'sound/effects/zzzt.ogg', 50, 1, -6)
	lube
		name = "Synthesize Space Lube"
		desc = "Fill yourself will space lube. Creates a slipping hazard, but it makes those floors shine so well that you can see yourself in them!"
		reagent_id = "lube"
		icon_state = "clean_lube"

	phlogiston_dust
		name = "Synthesize Phlogiston Dust"
		desc = "Fill yourself will phlogiston dust. For those stuck on messes!"
		reagent_id = "firedust"
		icon_state = "clean_phlog"

/datum/targetable/critter/bot/reagent_scan_self
	name = "Reagent Scan Self"
	desc = "Scan yourself for reagents."
	targeted = FALSE
	cooldown = 5 SECONDS
	icon_state = "clean_scan"
	var/reagent_id = null

	cast(atom/target)
		if(!holder?.owner?.reagents)
			return TRUE
		boutput(holder.owner, "[scan_reagents(holder.owner, visible = 1)]")

/datum/targetable/critter/bot/dump_reagents
	name = "Dump Reagents"
	desc = "Dump all your reagents on the floor."
	targeted = FALSE
	cooldown = 10 SECONDS
	icon_state = "clean_dump"

	cast()
		if (!holder?.owner?.reagents)
			return TRUE
		holder.owner.setStatus("resting", INFINITE_STATUS) // flop over to spill the reagents
		holder.owner.force_laydown_standup()
		holder.owner.reagents.reaction(get_turf(holder.owner), TOUCH)
		holder.owner.reagents.clear_reagents()

/datum/action/bar/icon/mob_cleanbot_clean
	duration = 1 SECOND
	interrupt_flags = INTERRUPT_MOVE | INTERRUPT_STUNNED | INTERRUPT_ATTACKED
	id = "mob_cleanbot_clean"
	icon = 'icons/obj/janitor.dmi'
	icon_state = "mop"
	var/mob/master
	var/turf/T
	var/const/cleaning_reagent = "cleaner"

	New(mob/user, atom/target)
		..()
		src.master = user
		src.T = get_turf(target)

	onStart()
		..()
		if (!master || is_incapacitated(master) || !T)
			interrupt(INTERRUPT_ALWAYS)
			return

		playsound(get_turf(master), 'sound/impact_sounds/Liquid_Slosh_2.ogg', 25, 1)
		master.anchored = ANCHORED
		if(istype(master, /mob/living/critter/robotic/bot))
			var/mob/living/critter/robotic/bot/bot = master
			master.icon_state = "[bot.icon_state_base]-c"
		master.visible_message("<span class='alert'>[master] begins to clean the [T.name].</span>")

	onUpdate()
		..()
		if (!master || is_incapacitated(master) || !T)
			interrupt(INTERRUPT_ALWAYS)
			return

	onInterrupt(flag)
		. = ..()
		if(istype(master, /mob/living/critter/robotic/bot))
			var/mob/living/critter/robotic/bot/bot = master
			master.icon_state = "[bot.icon_state_base]1"

	onEnd()
		if (master)
			if (master.reagents)
				master.reagents.remove_any(10)
				var/cleaner_amt = master.reagents.get_reagent_amount(cleaning_reagent)
				if (cleaner_amt <= 10)
					master.reagents.add_reagent(cleaning_reagent, 10 - cleaner_amt)
				master.reagents.reaction(T, TOUCH, 10)

			if (T.active_liquid)
				if (T.active_liquid.group)
					T.active_liquid.group.drain(T.active_liquid,1,master)

			if(istype(master, /mob/living/critter/robotic/bot))
				var/mob/living/critter/robotic/bot/bot = master
				master.icon_state = "[bot.icon_state_base]1"
		..()

/mob/living/critter/robotic/bot/firebot
	name = "firebot"
	real_name = "firebot"
	desc = "A little fire-fighting robot!  He looks so darn chipper."
	icon_state = "firebot1"
	icon_state_base = "firebot"

	New()
		. = ..()
		color = pick(list(
			null,\
			list(0.780465,0.129599,0.76233,0,0.0941811,0.94407,0.867769,0,0.858187,0.639099,0.46042,0,0,0,0,1,0,0,0,0),\
			list(0.309832,0.486208,0.704786,0,0.57733,0.407169,0.343657,0,0.440741,0.307279,0.0361456,0,0,0,0,1,0,0,0,0),\
			list(0.923407,0.489071,0.0133575,0,0.416634,0.00596684,0.0659536,0,0.151125,0.954365,0.946033,0,0,0,0,1,0,0,0,0),\
			list(0.34802,0.586676,0.382593,0,0.265555,0.208964,0.409951,0,0.395675,0.227339,0.498367,0,0,0,0,1,0,0,0,0),
		))

		src.abilityHolder.addAbility(/datum/targetable/critter/bot/spray_foam)


	emag_act(mob/user, obj/item/card/emag/E)
		. = ..()
		if(!src.emagged)
			playsound(src, 'sound/effects/sparks4.ogg', 50)
			src.audible_message("<span class='alert'><B>[src] buzzes oddly!</B></span>")
			src.abilityHolder.addAbility(/datum/targetable/critter/bot/spray_fire)
			src.abilityHolder.addAbility(/datum/targetable/critter/bot/spray_foam/fuel)
			src.abilityHolder.addAbility(/datum/targetable/critter/bot/spray_foam/throw_humans)
			src.emagged = TRUE
			return TRUE

	emagged
		brute_hp = 50
		burn_hp = 50
		emagged = TRUE
		New()
			. = ..()
			src.abilityHolder.addAbility(/datum/targetable/critter/bot/spray_fire)
			src.abilityHolder.addAbility(/datum/targetable/critter/bot/spray_foam/fuel)
			src.abilityHolder.addAbility(/datum/targetable/critter/bot/spray_foam/throw_humans)


/datum/targetable/critter/bot/spray_foam
	name = "Spray Foam"
	desc = "Unleash your spray foam cannon to kill the fire."
	targeted = TRUE
	target_anything = TRUE
	cooldown = 5 SECONDS
	icon = 'icons/mob/critter_ui.dmi'
	icon_state = "firebot_foam"
	var/const/num_water_effects = 5
	/// list of reagents to spray and their quantities
	var/list/spray_reagents = list("water"=2, "ff-foam"=8)
	/// reagent container size, passed to the spray proc
	var/max_spray = 15
	/// temp of the sprayed reagents
	var/spray_temperature=T20C

	cast(atom/target)
		if(!holder?.owner)
			return TRUE
		flick("firebot-c", holder.owner)
		playsound(get_turf(holder.owner), 'sound/effects/spray.ogg', 50, 1, -3)

		var/direction = get_dir(holder.owner,target)

		var/turf/T = get_turf(target)
		var/turf/T1 = get_step(T,turn(direction, 90))
		var/turf/T2 = get_step(T,turn(direction, -90))

		var/list/the_targets = list(T,T1,T2)

		for(var/i in 0 to num_water_effects)
			var/obj/effects/water/W = new /obj/effects/water
			if(!W) return
			W.set_loc(get_turf(holder.owner))
			var/turf/my_target = pick(the_targets)
			var/datum/reagents/R = new/datum/reagents(max_spray)
			for(var/reagent_key in spray_reagents)
				R.add_reagent(reagent_key, spray_reagents[reagent_key], temp_new = spray_temperature)
			W.spray_at(my_target, R, 1)

	fuel
		name = "Spray Burning Fuel"
		desc = "Spray burning fuel all over the place. Highly flammable but near useless in flooded areas."
		icon_state = "firebot_fire"
		spray_reagents = list("fuel"=5)
		spray_temperature = T0C + 200
		cooldown = 15 SECONDS

	throw_humans
		name = "High Pressure Foam"
		desc = "Unleash your spray foam cannon to send humans flying."
		cooldown = 10 SECONDS

		cast(atom/target)
			if(..())
				return TRUE
			for(var/mob/living/carbon/human/H in view(1, target))
				var/atom/targetTurf = get_edge_target_turf(H, get_dir(holder.owner, get_step_away(H, holder.owner)))
				boutput(H, "<span class='alert'><b>[holder.owner] knocks you back!</b></span>")
				H.changeStatus("weakened", 2 SECONDS)
				H.throw_at(targetTurf, 200, 4)


/datum/targetable/critter/bot/spray_fire
	name = "Spray Flames"
	desc = "Sometimes you gotta make your own fun. Spray a short range flammable aerosol. Works in flooded areas."
	targeted = TRUE
	target_anything = TRUE
	cooldown = 10 SECONDS
	icon = 'icons/mob/critter_ui.dmi'
	icon_state = "firebot_fire"
	var/max_fire_range = 3
	cooldown = 10 SECONDS
	var/temp = 7000

	cast(atom/target)
		if (..())
			return 1

		var/turf/T = get_turf(target)
		var/list/affected_turfs = getline(holder.owner, T)
		flick("firebot-c", holder.owner)
		playsound(holder.owner.loc, 'sound/effects/mag_fireballlaunch.ogg', 50, 0)
		var/turf/currentturf
		var/turf/previousturf
		for(var/turf/F in affected_turfs)
			previousturf = currentturf
			currentturf = F
			if(currentturf.density || istype(currentturf, /turf/space))
				break
			if(previousturf && LinkBlocked(previousturf, currentturf))
				break
			if (F == get_turf(holder.owner))
				continue
			if (GET_DIST(holder.owner,F) > max_fire_range)
				continue
			tfireflash(F,0.5,temp)

/mob/living/critter/robotic/securitron
	name = "securitron"
	real_name = "securitron"
#ifdef HALLOWEEN
	desc = "A little security robot, apparently carved out of a pumpkin.  He looks...spooky?"
	icon = 'icons/misc/halloween.dmi'
#else
	desc = "A little security robot.  He looks less than thrilled."
	icon = 'icons/obj/bots/aibots.dmi'
#endif
	icon_state = "secbot0"
	blood_id = "oil"
	speechverb_say = "beeps"
	speechverb_gasp = "warbles"
	speechverb_stammer = "bleeps"
	speechverb_exclaim = "boops"
	speechverb_ask = "bloops"
	stepsound = "step_plating"
	robot_talk_understand = TRUE
	density = FALSE
	hand_count = 1
	can_burn = FALSE
	dna_to_absorb = 0
	metabolizes = FALSE
	custom_gib_handler = /proc/robogibs
	stepsound = null
	health_brute = 25
	health_brute_vuln = 1
	health_burn = 25
	health_burn_vuln = 0.8
	var/emagged = 0
	var/emote_cooldown = 7 SECONDS
	var/siren_active = FALSE
	var/list/req_access = list(access_security)
	var/check_contraband = TRUE
	var/check_records = TRUE
	// TRUE if detaining, FALSE if arresting
	var/arrest_type = FALSE
	var/report_arrests = TRUE
	var/list/datum/contextAction/contexts = list()
	var/datum/contextLayout/configContextLayout = new /datum/contextLayout/experimentalcircle

	New()
		. = ..()
		remove_lifeprocess(/datum/lifeprocess/blindness)
		remove_lifeprocess(/datum/lifeprocess/viruses)
		remove_lifeprocess(/datum/lifeprocess/blood)
		remove_lifeprocess(/datum/lifeprocess/radiation)

		new /obj/item/implant/access/infinite/captain(src)

		src.abilityHolder.addAbility(/datum/targetable/critter/bot/handcuff)

		APPLY_MOVEMENT_MODIFIER(src, /datum/movement_modifier/robot_base, "robot_health_slow_immunity")

		get_image_group(CLIENT_IMAGE_GROUP_ARREST_ICONS).add_mob(src)

		add_simple_light("secbot", list(255, 255, 255, 0.4 * 255))

		MAKE_SENDER_RADIO_PACKET_COMPONENT("pda", FREQ_PDA)

		for(var/actionType in childrentypesof(/datum/contextAction/securitron)) //see context_actions.dm
			src.contexts += new actionType()

	setup_hands()
		..()
		var/datum/handHolder/HH = hands[1]
		HH.limb = new /datum/limb/small_critter/med
		HH.icon = 'icons/mob/critter_ui.dmi'
		HH.icon_state = "handn"
		HH.name = "long arm"
		HH.limb_name = "long arm"
		HH.can_hold_items = 1
		HH.can_attack = 1
		HH.can_range_attack = 1

	setup_healths()
		add_hh_robot(src.health_brute, src.health_brute_vuln)
		add_hh_robot_burn(src.health_burn, src.health_burn_vuln)

	get_melee_protection(zone, damage_type)
		return 3

	get_ranged_protection()
		return 2

	death(var/gibbed)
		..(gibbed, 0)
		if (!gibbed)
			gib(src)
		else
			playsound(src.loc, 'sound/impact_sounds/Machinery_Break_1.ogg', 50, 1)
			make_cleanable(/obj/decal/cleanable/oil,src.loc)

	specific_emotes(var/act, var/param = null, var/voluntary = 0)
		if (act == "scream")
			src.siren()
			return null
		if (ON_COOLDOWN(src, "secbot_emote_cooldown", src.emote_cooldown))
			return null
		switch (act)
			if ("laugh")
				src.say("YOU CAN'T OUTRUN A RADIO.")
				playsound(src, "sound/voice/bradio.ogg", 50, FALSE, 0, 1)
			if ("fart")
				src.say("YOUR MOVE, CREEP.")
				playsound(src, "sound/voice/bcreep.ogg", 50, FALSE, 0, 1)
			if ("salute")
				src.say("HAVE A SECURE DAY.")
				playsound(src, "sound/voice/bsecureday.ogg", 50, FALSE, 0, 1)
			if ("snap")
				src.say("GOD MADE TOMORROW FOR THE CROOKS WE DON'T CATCH TODAY.")
				playsound(src, "sound/voice/bgod.ogg", 50, FALSE, 0, 1)
			if ("flex")
				src.say("I AM THE LAW.")
				playsound(src, "sound/voice/biamthelaw.ogg", 50, FALSE, 0, 1)
		return ..()

	proc/siren()
		if(siren_active)
			return
		SPAWN(0)
			siren_active = TRUE
			var/weeoo = 10
			playsound(src, 'sound/machines/siren_police.ogg', 50, TRUE)
			while (weeoo)
				add_simple_light("secbot", list(255 * 0.9, 255 * 0.1, 255 * 0.1, 0.8 * 255))
				sleep(0.2 SECONDS)
				add_simple_light("secbot", list(255 * 0.1, 255 * 0.1, 255 * 0.9, 0.8 * 255))
				sleep(0.2 SECONDS)
				weeoo--

			add_simple_light("secbot", list(255, 255, 255, 0.4 * 255))
			siren_active = FALSE

	attack_hand(mob/M, params)
		if (M.a_intent == INTENT_HELP && src.allowed(M))
			M.showContextActions(src.contexts, src, src.configContextLayout)
		else
			..()

	proc/configure(var/setting, var/mob/M)
		switch(setting)
			if ("check_contraband")
				src.check_contraband = !src.check_contraband
				src.say("Ten-Four. Contraband Checks: [src.check_contraband ? "ENGAGED" : "DISENGAGED"].")
				return src.check_contraband
			if ("check_records")
				src.check_records = !src.check_records
				src.say("Ten-Four. Security Records: [src.check_records ? "REFERENCED" : "IGNORED"].")
				return src.check_records
			if ("arrest_type")
				src.arrest_type = !src.arrest_type
				src.say("Ten-Four. Arrest Mode: [src.arrest_type ? "DETAIN" : "RESTRAIN"].")
				return src.arrest_type
			if ("report_arrests")
				src.report_arrests = !src.report_arrests
				src.say("Ten-Four. [src.report_arrests ? "Reporting arrests on [FREQ_PDA]" : "No longer reporting arrests"].")
				return src.report_arrests

	proc/allowed(mob/M)
		//check if it doesn't require any access at all
		if(src.check_access(null))
			return 1
		if(src.check_access(M.equipped()))
			return 1
		if(ishuman(M))
			var/mob/living/carbon/human/H = M
			//if they are holding or wearing a card that has access, that works
			if(src.check_access(H.wear_id))
				return 1
		return 0

	proc/check_access(obj/item/I)
		if(!istype(src.req_access, /list)) //something's very wrong
			return 1

		var/obj/item/card/id/id_card = get_id_card(I)
		var/list/L = src.req_access
		if(!L.len) //no requirements
			return 1
		if(!istype(id_card, /obj/item/card/id) || !id_card:access) //not ID or no access
			return 0
		for(var/req in src.req_access)
			if(!(req in id_card:access)) //doesn't have this access
				return 0
		return 1

/datum/targetable/critter/bot/handcuff
	name = "Detain"
	desc = "Attempts to handcuff a target."
	targeted = TRUE
	target_anything = TRUE
	cooldown = 4 SECONDS
	icon = 'icons/mob/critter_ui.dmi'
	icon_state = "firebot_fire"

	cast(atom/target)
		if (..())
			return TRUE
		var/mob/living/carbon/human/H = target
		if (!ishuman(target))
			target = get_turf(target)
		if (isturf(target))
			H = locate(/mob/living/carbon/human) in target
			if (!H)
				boutput(holder.owner, "<span class='alert'>Nothing to detain there.</span>")
				return TRUE
		if (H == holder.owner)
			return TRUE
		if (!H.lying)
			boutput(holder.owner, "<span class='alert'>The target must be lying down.</span>")
			return TRUE
		if (BOUNDS_DIST(holder.owner, H) > 0)
			boutput(holder.owner, "<span class='alert'>That is too far away to detain.</span>")
			return TRUE
		var/mob/M = holder.owner
		if (!isturf(M.loc))
			boutput(holder.owner, "<span class='alert'>You'll need to get out of \the [M.loc] before trying to detain someone.")
			return TRUE
		if (target.hasStatus("handcuffed"))
			boutput(holder.owner, "<span class='alert'>That target is already cuffed.</span>")
			return TRUE
		actions.start(new/datum/action/bar/icon/mob_secbot_cuff(M, H), M)
		return 0

/datum/action/bar/icon/mob_secbot_cuff
	duration = 4 SECONDS
	interrupt_flags = INTERRUPT_MOVE | INTERRUPT_ACT | INTERRUPT_STUNNED | INTERRUPT_ACTION
	id = "secbot_cuff"
	icon = 'icons/obj/items/items.dmi'
	icon_state = "buddycuff"
	var/mob/master
	var/mob/living/carbon/human/target

	New(var/mob/living/M, var/mob/living/carbon/human/H)
		src.master = M
		src.target = H
		..()

	onStart()
		..()
		playsound(master, 'sound/weapons/handcuffs.ogg', 30, TRUE, -2)
		master.visible_message("<span class='alert'><B>[master] is trying to put handcuffs on [target]!</B></span>")

	onEnd()
		..()
		if(ishuman(target))
			target.handcuffs = new /obj/item/handcuffs/guardbot(target)
			target.setStatus("handcuffed", duration = INFINITE_STATUS)
			logTheThing(LOG_COMBAT, master, "handcuffs [constructTarget(target,"combat")] at [log_loc(master)].")

			var/user_location = get_area(master)
			var/turf/target_loc = get_turf(target)
			if(!target_loc)
				target_loc = get_turf(master)

				//////PDA NOTIFY/////

			var/message2send ="Notification: [target] detained by [master] in [user_location] at coordinates [target_loc.x], [target_loc.y]."

			var/datum/signal/signal = get_free_signal()
			signal.source = src
			signal.data["sender"] = "00000000"
			signal.data["command"] = "text_message"
			signal.data["sender_name"] = "SECURITY-MAILBOT"
			signal.data["group"] = list(MGD_SECURITY, MGA_ARREST)
			signal.data["address_1"] = "00000000"
			signal.data["message"] = message2send
			SEND_SIGNAL(src.master, COMSIG_MOVABLE_POST_RADIO_PACKET, signal, null, "pda")

	canRunCheck(in_start)
		. = ..()
		if ((BOUNDS_DIST(master, target) > 0) || master == null || target == null || target.hasStatus("handcuffed"))
			interrupt(INTERRUPT_ALWAYS)
