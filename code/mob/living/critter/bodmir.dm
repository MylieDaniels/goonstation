/mob/living/critter/bodmir_cableworm
	name = "cableworm"
	real_name = "cableworm"
	icon_state = "bodmir_cableworm"
	desc = "It writhes, seeking a host."
	hand_count = 1
	density = 0
	can_grab = 1

	ai_retaliates = TRUE
	ai_retaliate_persistence = RETALIATE_UNTIL_DEAD

	faction = list(FACTION_SYNDICATE)

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
		abilityHolder.addAbility(/datum/targetable/critter/slam/cableworm)
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

		G = src.equipped()
		if (istype(G))
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

/mob/living/critter/bodmir_cableworm/ai_controlled
	ai_type = /datum/aiHolder/aggressive_closing_ability/cableworm
	is_npc = TRUE

/datum/aiHolder/aggressive_closing_ability/cableworm
	New()
		..()
		default_task = get_instance(/datum/aiTask/prioritizer/critter/aggressive/closing_ability_cableworm, list(src))

/datum/aiTask/prioritizer/critter/aggressive/closing_ability_cableworm/New()
	..()
	transition_tasks += holder.get_instance(/datum/aiTask/critter/closing_ability/cableworm, list(holder, src))

//--------------------------------------------------------------------------------------------------------------------------------------------------//

/// This one makes the critter use an ability towards a target returned from holder.owner.seek_target()
/datum/aiTask/critter/closing_ability
	name = "closing ability"
	weight = 12 // above base attacking
	ai_turbo = TRUE //attack behaviour gets a speed boost for robustness
	max_dist = 7
	var/ability_type = /datum/targetable/critter/slam
	var/datum/aiTask/transition_task = null
	move_through_space = TRUE

/datum/aiTask/critter/closing_ability/New(parentHolder, transTask)
		transition_task = transTask
		..()

/datum/aiTask/critter/closing_ability/evaluate()
	. = 0
	var/mob/living/critter/C = holder.owner
	var/datum/targetable/critter/ability = C.abilityHolder.getAbility(src.ability_type)
	if (!ability.disabled && ability.cooldowncheck())
		return score_target(get_best_target(get_targets())) * weight

/datum/aiTask/critter/closing_ability/get_targets()
	var/mob/living/critter/C = holder.owner
	return C.seek_target(src.max_dist)

/datum/aiTask/critter/closing_ability/on_tick()
	..()
	if(!holder.target)
		holder.target = get_best_target(get_targets())
	var/mob/living/critter/C = holder.owner
	var/mob/T = holder.target
	if(C && T)
		holder.owner.set_dir(get_dir(holder.owner, holder.target))
		var/datum/targetable/critter/ability = C.abilityHolder.getAbility(src.ability_type)
		if (!ability.disabled && ability.cooldowncheck())
			ability.handleCast(holder.target)

/datum/aiTask/critter/closing_ability/next_task()
	var/mob/living/critter/C = holder.owner
	holder.owner.set_dir(get_dir(holder.owner, holder.target))
	var/datum/targetable/critter/ability = C.abilityHolder.getAbility(src.ability_type)
	if (ability.disabled || !ability.cooldowncheck())
		return transition_task
	return null

//--------------------------------------------------------------------------------------------------------------------------------------------------//

/datum/aiTask/critter/closing_ability/cableworm
	ability_type = /datum/targetable/critter/slam/cableworm

/datum/targetable/critter/slam/cableworm
	cooldown = 5 SECONDS

// ----------- //
/datum/ailment/parasite/bodmir_cable
	name = "Writhing Cables"
	max_stages = 5
	affected_species = list("Human")
	stage_prob = 0
	var/static/list/common_halluc_sounds = list(
				'sound/weapons/gunload_heavy.ogg',
				'sound/weapons/gunload_light.ogg',
				'sound/weapons/gunload_click.ogg',
				'sound/items/blade_pull.ogg',
				new /datum/hallucinated_sound('sound/misc/step/step_lattice_3.ogg', min_count = 6, max_count = 12, delay = 0.1 SECONDS),
				'sound/weapons/gun_cocked_colt45.ogg',
				new /datum/hallucinated_sound('sound/impact_sounds/Metal_Hit_1.ogg', min_count = 1, max_count = 3, delay = COMBAT_CLICK_DELAY),
				new /datum/hallucinated_sound('sound/machines/airlock_bolt.ogg', min_count = 1, max_count = 3, delay = 0.3 SECONDS),
				'sound/machines/airlock_swoosh_temp.ogg',
				'sound/machines/airlock_deny.ogg',
				'sound/machines/airlock_pry.ogg',
				'sound/impact_sounds/Flesh_Break_2.ogg',
				'sound/impact_sounds/Flesh_Crush_1.ogg',
				'sound/impact_sounds/Flesh_Tear_1.ogg',
				'sound/impact_sounds/Flesh_Tear_2.ogg',
				'sound/impact_sounds/Flesh_Tear_3.ogg',
				'sound/impact_sounds/Flesh_Stab_1.ogg',
				'sound/impact_sounds/Glub_1.ogg',
				'sound/machines/sawfly1.ogg',
				'sound/machines/sawfly2.ogg',
				'sound/machines/sawfly3.ogg'
			)
	var/static/list/rare_halluc_sounds = list(
				new /datum/hallucinated_sound('sound/weapons/Gunshot.ogg', min_count = 1, max_count = 3, delay = 0.4 SECONDS),
				new /datum/hallucinated_sound('sound/weapons/9x19NATO.ogg', min_count = 2, max_count = 8, delay = 0.2 SECONDS),
				new /datum/hallucinated_sound('sound/weapons/smg_shot.ogg', min_count = 3, max_count = 9, delay = 0.1 SECONDS),
				'sound/weapons/gunload_mprt.ogg',
				'sound/weapons/gunload_heavy.ogg',
				'sound/items/blade_pull.ogg',
				new /datum/hallucinated_sound('sound/weapons/railgun.ogg', min_count = 1, max_count = 2, delay = 1.8 SECONDS),
				new /datum/hallucinated_sound('sound/misc/step/step_lattice_3.ogg', min_count = 1, max_count = 3, delay = 0.1 SECONDS),
				'sound/weapons/gun_cocked_colt45.ogg',
				'sound/items/security_alert.ogg',
				'sound/impact_sounds/Flesh_Break_2.ogg',
				'sound/impact_sounds/Flesh_Crush_1.ogg',
				'sound/impact_sounds/Flesh_Tear_1.ogg',
				'sound/impact_sounds/Flesh_Tear_2.ogg',
				'sound/impact_sounds/Flesh_Tear_3.ogg',
				'sound/impact_sounds/Flesh_Stab_1.ogg',
				'sound/impact_sounds/Glub_1.ogg',
				'sound/weapons/hadar_pickup.ogg',
				'sound/misc/headspiderability.ogg'
			)

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
			surgeon.TakeDamage(surgeon.hand ? "l_arm" : "r_arm", 0, numb ? 15 : 25, 0, DAMAGE_BURN)
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
			surgeon.TakeDamage(surgeon.hand ? "l_arm" : "r_arm", 0, numb ? 5 : 10, 0, DAMAGE_BURN)
			playsound(affected_mob, 'sound/effects/electric_shock_short.ogg', 50)
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

/datum/ailment/parasite/bodmir_cable/stage_act(mob/living/affected_mob, datum/ailment_data/parasite/D, mult)
	if (..())
		return

	if (probmult(5))
		boutput(affected_mob, pick("Your [pick("guts","innards","bones","nerves","organs","muscles")] [pick("spark","move","twist","shudder","bend")].",\
			"The cables inside you [pick("writhe","tighten","loosen","go still for a moment","spark to life")]."))
		take_bleeding_damage(affected_mob, affected_mob, rand(1,5))

	if (probmult(5 + 4 * D.stage))
		affected_mob.reagents?.add_reagent(pick("carbon","iron","aluminium","chromium","silver","graphene","copper"), 6)
		affected_mob.emote(pick("twitch_v","twitch","groan"))

	if (probmult(5 + 4 * D.stage))
		if (prob(10))
			if (D.stage < 3)
				affected_mob.vomit()
			else
				affected_mob.visible_message("<span class='alert'>[affected_mob] vomits a slurry of blood, metal, and oil!</span>")
				take_bleeding_damage(affected_mob, affected_mob, rand(20,30))

	if (probmult(5 + D.stage ** 2))
		if (!ON_COOLDOWN(affected_mob, "grendel_voice_drugs", 20 SECONDS))
			boutput(affected_mob, "<span class='alert'>Let me save you.</span>")
		affected_mob.reagents?.add_reagent(pick("synaptizine","epinephrine","oculine","silicate","smelling_salt","anti_rad"), 4)
		affected_mob.reagents?.add_reagent(pick("saline","strychnine","teporone","lexorin","salicylic_acid","salbutamol","strange_reagent","aranesp"), 2)

	affected_mob.AddComponent(/datum/component/hallucination/random_sound, timeout=10, sound_list=src.common_halluc_sounds, sound_prob=(5 + 3 * D.stage), min_distance=5)
	affected_mob.AddComponent(/datum/component/hallucination/random_sound, timeout=10, sound_list=src.rare_halluc_sounds, sound_prob=D.stage, min_distance=5)
	affected_mob.AddComponent(/datum/component/hallucination/random_image_override,\
					timeout=10,\
					image_list=list(\
						image(icon = 'icons/misc/meatland.dmi', icon_state = "bloodfloor_1"),\
						image(icon = 'icons/misc/meatland.dmi', icon_state = "bloodfloor_2"),\
						image(icon = 'icons/misc/meatland.dmi', icon_state = "bloodfloor_3"),\
					),\
					target_list=list(/turf/simulated/floor,/turf/unsimulated/floor),\
					range=8,\
					image_prob=40 + 12 * D.stage,\
					image_time=60,\
					override=TRUE,\
					visible_creation = FALSE\
				)
	affected_mob.AddComponent(/datum/component/hallucination/random_image_override,\
					timeout=10,\
					image_list=list(\
						image(icon = 'icons/obj/scrap.dmi', icon_state = "Crusher_1"),\
						image(icon = 'icons/obj/turrets.dmi', icon_state = "turretCover"),\
						image(icon = 'icons/obj/delivery.dmi', icon_state = "floorflush_o"),\
						image(icon = 'icons/obj/items/weapons.dmi', icon_state = "bear_trap-open")\
					),\
					target_list=list(/turf/simulated/floor,/turf/unsimulated/floor),\
					range=8,\
					image_prob=D.stage,\
					image_time=120,\
					override=FALSE,\
					visible_creation = FALSE\
				)
	affected_mob.AddComponent(/datum/component/hallucination/random_image_override,\
					timeout=10,\
					image_list=list(\
						image(icon = 'icons/mob/mob.dmi', icon_state = "metalcube-squish"),\
						image(icon = 'icons/mob/abomination.dmi', icon_state = "abomination"),\
						image(icon = 'icons/mob/critter/robotic/gunbot.dmi', icon_state = "nukebot")\
					),\
					target_list=list(/mob/living/carbon/human),\
					range=8,\
					image_prob=3 * D.stage,\
					image_time=20,\
					override=TRUE,\
					visible_creation = FALSE\
				)

	if(D.stage > 1)
		if(probmult(4 * D.stage))
			affected_mob.reagents?.add_reagent(pick("mannitol","mercury"), 2)
			if(affected_mob.canmove && isturf(affected_mob.loc) && !affected_mob.lying)
				step(affected_mob, pick(alldirs))
				affected_mob.change_misstep_chance(3)

		if (probmult(D.stage ** 2))
			if (!ON_COOLDOWN(affected_mob, "grendel_voice_heal", 20 SECONDS))
				boutput(affected_mob, "<span class='alert'>Let me heal you.</span>")
			boutput(affected_mob, pick("Your [pick("wounds","sores","injuries")] [pick("cauterize","knit closed","singe shut")]."))
			if (affected_mob.bleeding > 2)
				repair_bleeding_damage(affected_mob, 100, 2)
			affected_mob.HealDamage("All", D.stage * 1.5, D.stage, D.stage / 2)
