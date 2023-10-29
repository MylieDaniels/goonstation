/mob/living/critter/bodmir_cable
	name = "cableworm"
	real_name = "cableworm"
	desc = "It writhes, seeking a host."
	hand_count = 1
	density = 0
	can_grab = 1

	ai_retaliates = TRUE
	ai_retaliate_persistence = RETALIATE_UNTIL_DEAD

	specific_emotes(var/act, var/param = null, var/voluntary = 0)
		switch (act)
			if ("scream")
				if (src.emote_check(voluntary, 50))
					playsound(src, 'sound/voice/creepyshriek.ogg', 50, TRUE, 0.2, 1.7, channel=VOLUME_CHANNEL_EMOTE)
					return "<b><span class='alert'>[src] screams!</span></b>"
		return null

	specific_emote_type(var/act)
		switch (act)
			if ("scream")
				return 2
		return ..()

	setup_hands()
		..()
		var/datum/handHolder/HH = hands[1]
		HH.name = "cable"				 // designation of the hand - purely for show
		HH.icon = 'icons/mob/critter_ui.dmi'	// the icon of the hand UI background
		HH.icon_state = "mouth"			 // the icon state of the hand UI background
		HH.limb_name = "teeth"					// name for the dummy holder
		HH.limb = new /datum/limb/small_critter/med
		HH.can_hold_items = 1

	New()
		..()
		abilityHolder.addAbility(/datum/targetable/critter/slam)
		abilityHolder.updateButtons()
		src.flags ^= TABLEPASS | DOORPASS

	setup_healths()
		add_hh_flesh(25, 1)
		add_hh_flesh_burn(25, 1)

	critter_attack(mob/target)
		src.set_a_intent(INTENT_GRAB)
		src.set_dir(get_dir(src, target))

		var/list/params = list()
		params["left"] = TRUE
		params["ai"] = TRUE

		var/obj/item/grab/G = src.equipped()
		if (!istype(G)) //if it hasn't grabbed something, try to
			if(!isnull(G)) //if we somehow have something that isn't a grab in our hand
				src.drop_item()
			src.hand_attack(target, params)
		else
			if (G.affecting == null || G.assailant == null || G.disposed || isdead(G.affecting))
				src.drop_item()
				return

			if (G.state <= GRAB_STRONG)
				G.AttackSelf(src)
			else
				if (G.state <= GRAB_AGGRESSIVE)
					var/turf/T = get_turf(src)
					T.grab_smash(G, src)
				else
					infect_target(G.affecting)
					src.drop_item()

	proc/infect_target(mob/M)
		if(ishuman(M) && !isdead(M))
			var/mob/living/carbon/human/H = M
			H.TakeDamage("chest", 15, 5, 0, DAMAGE_BLUNT)
			src.visible_message("<font color='#FF0000'><B>\The [src]</B> extrudes cabling down [H.name]'s throat!</font>")
			playsound(src, 'sound/misc/headspiderability.ogg', 60)
			H.setStatusMin("paralysis", 10 SECONDS)

			var/datum/ailment_data/parasite/BC = H.find_ailment_by_type(/datum/ailment/parasite/bodmir_cable)
			if (BC)
				BC.stage += 1
			else
				BC = new /datum/ailment_data/parasite
				BC.master = get_disease_from_path(/datum/ailment/parasite/bodmir_cable)
				BC.affected_mob = H
				H.ailments += BC

			logTheThing(LOG_COMBAT, src, "infects [constructTarget(H,"combat")] with Bodmir cabling at [log_loc(src)].")
			src.gib()
		else


/mob/living/critter/bodmir_cable/ai_controlled
	ai_type = /datum/aiHolder/aggressive
	is_npc = TRUE

/datum/ailment/parasite/bodmir_cable
	name = "Unidentified Foreign Body"
	max_stages = 5
	affected_species = list("Human")
	cure = "Surgery"
	stage_prob = 0

/datum/ailment/parasite/bodmir_cable/surgery(var/mob/living/surgeon, var/mob/living/affected_mob, var/datum/ailment_data/D)
	if (D.disposed)
		return 0
	var/outcome = rand(40)
	if (surgeon.traitHolder.hasTrait("training_medical"))
		outcome += 10
	outcome -= 5 * D.stage
	var/numb = affected_mob.reagents.has_reagent("morphine") || affected_mob.sleeping
	if (numb)
		outcome += 15
	if (affected_mob.hasStatus("defibbed"))
		outcome += 15
	switch (outcome)
		if (-INFINITY to 5)
			// bzap!
			surgeon.visible_message("<span class='alert'><b>[surgeon] cuts open [affected_mob] in all the wrong places, causing electricity and blood to fly!</b></span>", "You dig around in [affected_mob]'s chest and accidentally snip some important looking cabling!")
			affected_mob.show_message("<span class='alert'><b>You feel a [numb ? "numb" : "sharp"] sparking pain in your chest!</b></span>")
			affected_mob.TakeDamage("chest", numb ? 5 : 20, 15, 0, DAMAGE_CUT)
			surgeon.TakeDamage(surgeon.hand ? "l_arm" : "r_arm", 0, numb ? 15 : 30, 0, DAMAGE_BURN)
			playsound(affected_mob, 'sound/effects/power_charge.ogg', 50)
			actions.start(new/datum/action/bar/private/flash(), affected_mob)
		if (6 to 20)
			surgeon.visible_message("<span class='alert'><b>[surgeon] cuts open [affected_mob] and sparks fly!</b></span>", "You dig around in [affected_mob]'s chest and get shocked!")
			affected_mob.show_message("<span class='alert'><b>You feel a [numb ? "mild " : " "]sparking pain in your chest!</b></span>")
			affected_mob.TakeDamage("chest", numb ? 5 : 15, 5, 0, DAMAGE_CUT)
			arcFlash(affected_mob, surgeon, 200)
			surgeon.TakeDamage(surgeon.hand ? "l_arm" : "r_arm", 0, numb ? 5 : 15, 0, DAMAGE_BURN)
		if (21 to 40)
			surgeon.visible_message("<span class='notice'><b>[surgeon] cuts open [affected_mob] and removes a part of the cabling, but sparks fly.</b></span>", "<span class='notice'>You remove some of the pulsing cables from [affected_mob], aggravating the parasite.</span>")
			arcFlash(affected_mob, surgeon, 60)
			surgeon.TakeDamage(surgeon.hand ? "l_arm" : "r_arm", 0, numb ? 5 : 10, 0, DAMAGE_BURN)
			if (!numb)
				affected_mob.show_message("<span class='alert'><b>You feel a mild jolting pain in your chest!</b></span>")
				affected_mob.TakeDamage("chest", 10, 10, 0, DAMAGE_STAB)
			D.stage -= 1
		if (41 to INFINITY)
			surgeon.visible_message("<span class='notice'><b>[surgeon] cuts open [affected_mob] and smoothly snips out large parts of the cabling.</b></span>", "<span class='notice'>You masterfully remove some of the pulsing cabling within [affected_mob].</span>")
			if (!numb)
				affected_mob.show_message("<span class='alert'><b>You feel a mild jolt in your chest!</b></span>")
				affected_mob.TakeDamage("chest", 5, 5, 0, DAMAGE_STAB)
			D.stage -= 1
	return (D.stage < 1)

/datum/ailment/parasite/bodmir_cable/stage_act(var/mob/living/affected_mob, var/datum/ailment_data/parasite/D, mult)
	if (..())
		return

	if (D.stage < 1)
		affected_mob.cure_disease(src)
		return

	if (probmult(5 + 3 * D.stage))
		boutput(affected_mob, pick("Your [pick("guts","innards","bones","nerves","organs","muscles")] [pick("spark","move","twist","shudder","bend")].",\
			"The cables inside you [pick("writhe","tighten","loosen","go still for a moment","spark to life")]."))

	if (probmult(5 + 4 * D.stage))
		affected_mob.reagents?.add_reagent("iron", 4)
		affected_mob.emote(pick("twitch_v","twitch","groan"))

	if (probmult(5 + 4 * D.stage))
		affected_mob.reagents?.add_reagent("oil", 3)
		if (prob(10))
			if (D.stage < 4)
				affected_mob.vomit()
			else
				affected_mob.visible_message("<span class='alert'>[affected_mob] vomits a slurry of blood, metal, and oil!</span>")
				bleed(affected_mob, rand(20,30), 3)

	if(D.stage > 1)
		if(probmult(4 * D.stage))
			if(affected_mob.canmove && isturf(affected_mob.loc) && !affected_mob.lying)
				step(affected_mob, pick(alldirs))
				affected_mob.change_misstep_chance(3 + D.stage)

/datum/ailment/parasite/bodmir_cable/on_infection(var/mob/living/affected_mob,var/datum/ailment_data/D)
	..()
	SPAWN(15 SECONDS)
		boutput(affected_mob, "<span class='alert'>We are Grendel. Welcome, [pick("broken","wretched","unformed")] thing.</span>")
