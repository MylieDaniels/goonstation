/proc/vegetablegibs(turf/T, list/ejectables, bdna, btype)
	var/list/vegetables = list(/obj/item/reagent_containers/food/snacks/plant/soylent, \
		                       /obj/item/reagent_containers/food/snacks/plant/lettuce, \
		                       /obj/item/reagent_containers/food/snacks/plant/cucumber, \
		                       /obj/item/reagent_containers/food/snacks/plant/carrot, \
		                       /obj/item/reagent_containers/food/snacks/plant/slurryfruit)

	var/list/dirlist = list(list(NORTH, NORTHEAST, NORTHWEST), \
		                    list(SOUTH, SOUTHEAST, SOUTHWEST), \
		                    list(WEST, NORTHWEST, SOUTHWEST),  \
		                    list(EAST, NORTHEAST, SOUTHEAST))

	var/list/produce = list()

	for (var/i = 1, i <= 4, i++)
		var/PT = pick(vegetables)
		var/obj/item/reagent_containers/food/snacks/plant/P = new PT(T)
		P.streak_object(dirlist[i])
		produce += P

	var/extra = rand(2,4)
	for (var/i = 1, i <= extra, i++)
		var/PT = pick(vegetables)
		var/obj/item/reagent_containers/food/snacks/plant/P = new PT(T)
		P.streak_object(alldirs)
		produce += P

	return produce

/mob/living/critter/plant/maneater
	name = "man-eating plant"
	real_name = "man-eating plant"
	desc = "It looks hungry..."
	density = 1
	icon_state = "maneater"
	icon_state_dead = "maneater-dead"
	custom_gib_handler = /proc/vegetablegibs
	blood_id = "poo"
	hand_count = 2
	can_throw = 1
	can_grab = 1
	can_disarm = 1
	is_npc = 1
	//if someone is really annoying and an ally, give them a smack to put them in their place
	ai_retaliates = TRUE
	ai_retaliate_patience = 1
	ai_retaliate_persistence = RETALIATE_ONCE
	add_abilities = list(/datum/targetable/critter/maneater_devour)

	faction = FACTION_BOTANY
	planttype = /datum/plant/maneater
	stamina = 300
	stamina_max = 300
	var/baseline_health = 100 //! how much health the maneater should get normally and at 0 endurance
	var/scaleable_limb = null //! used for scaling the values on one of the critters limbs

	specific_emotes(var/act, var/param = null, var/voluntary = 0)
		switch (act)
			if ("scream")
				if (src.emote_check(voluntary, 50))
					playsound(src, 'sound/voice/MEraaargh.ogg', 70, 1, channel=VOLUME_CHANNEL_EMOTE)
					return "<b><span class='alert'>[src] roars!</span></b>"
		return null

	specific_emote_type(var/act)
		switch (act)
			if ("scream")
				return 2
		return ..()

	setup_equipment_slots()
		src.equipment += new /datum/equipmentHolder/ears(src)
		src.equipment += new /datum/equipmentHolder/head(src)

	setup_hands()
		..()
		var/datum/handHolder/holdinghands = src.hands[1]
		holdinghands.name = "tendrils"
		holdinghands = src.hands[2]
		holdinghands.name = "mouth"								// designation of the hand - purely for show
		holdinghands.icon = 'icons/mob/critter_ui.dmi'			// the icon of the hand UI background
		holdinghands.icon_state = "mouth"						// the icon state of the hand UI background
		holdinghands.limb_name = "teeth"						// name for the dummy holder
		holdinghands.limb = new /datum/limb/maneater_mouth		// if not null, the special limb to use when attack_handing
		src.scaleable_limb = holdinghands.limb //we need this later for applying botany chems with it
		holdinghands.can_hold_items = 0

	HYPsetup_DNA(var/datum/plantgenes/passed_genes, var/obj/machinery/plantpot/harvested_plantpot, var/datum/plant/origin_plant, var/quality_status)
		var/health_per_endurance = 3 // how much health the maneater should get per point of endurance
		var/baseline_stamina = 300 // how much stamina the maneater should have baseline
		var/stamina_per_potency = 5 // how much stamina each point of potency should add
		var/stamreg_per_potency = 0.1 // how much stamina regen each point of potency should add
		var/maximum_stamreg = 60 // how much stamina regen should be the max. Don't want to have complete immunity to stun batoning
		var/baseline_injection = 3 // how much chems the maneater should inject upon attacking
		var/injection_amount_per_yield = 0.1 //how much their injection amount should scale with yield

		var/scaled_health = src.baseline_health + (passed_genes?.get_effective_value("endurance") * health_per_endurance)
		for (var/T in healthlist)
			var/datum/healthHolder/lifepool = healthlist[T]
			lifepool.maximum_value = scaled_health
			lifepool.value = scaled_health
			lifepool.last_value = scaled_health
		src.stamina = baseline_stamina + (passed_genes?.get_effective_value("potency") * stamina_per_potency)
		src.stamina_max = baseline_stamina + (passed_genes?.get_effective_value("potency") * stamina_per_potency)
		src.stamina_regen = min(STAMINA_REGEN + round(passed_genes?.get_effective_value("potency") * stamreg_per_potency), maximum_stamreg)

		//now, we set the arm injection up
		if (length(origin_plant.assoc_reagents) > 0)
			var/datum/limb/maneater_mouth/manipulated_limb = src.scaleable_limb
			manipulated_limb.amount_to_inject = max(1, round(baseline_injection + injection_amount_per_yield * passed_genes?.get_effective_value("cropsize")))
			manipulated_limb.chems_to_inject |= origin_plant.assoc_reagents
		..()
		return src

	New()
		APPLY_MOVEMENT_MODIFIER(src, /datum/movement_modifier/maneater, src) // They are approaching you, slowly and menacing...
		//Maneaters are scary and big, they should not be pinned for helplessly thrown around
		APPLY_ATOM_PROPERTY(src, PROP_MOB_CANT_BE_PINNED, "Maneater")
		APPLY_ATOM_PROPERTY(src, PROP_MOB_CANTTHROW, "Maneater")
		src.ai = new /datum/aiHolder/maneater(src)
		..()

	disposing()
		REMOVE_ATOM_PROPERTY(src, PROP_MOB_CANTTHROW, "Maneater")
		REMOVE_ATOM_PROPERTY(src, PROP_MOB_CANT_BE_PINNED, "Maneater")
		..()

	setup_healths()
		add_hh_flesh(src.baseline_health, 1)
		add_hh_flesh_burn(src.baseline_health, 1.25)
		var/datum/healthHolder/toxin/tox = add_health_holder(/datum/healthHolder/toxin)
		tox.maximum_value = src.baseline_health
		tox.value = src.baseline_health
		tox.last_value = src.baseline_health
		tox.damage_multiplier = 1

	valid_target(var/mob/living/potential_target)
		if (isintangible(potential_target)) return FALSE
		if (isdead(potential_target) && !ishuman(potential_target)) return FALSE
		if (potential_target in src.growers) return FALSE
		if (istype(potential_target, src.type)) return FALSE
		if (iskudzuman(potential_target)) return FALSE
		var/datum/targetable/critter/checked_ability = src.abilityHolder.getAbility(/datum/targetable/critter/maneater_devour)
		//if we got a human corpse but our ability is on cooldown/not avaible, we don't want to target them
		if ((checked_ability.disabled || checked_ability.cooldowncheck()) && isdead(potential_target) && ishuman(potential_target)) return FALSE
		//if we don't have a faction we hate everyone
		//But we love corpses, also the one of botanists that didn't grew us
		return isdead(potential_target) && ishuman(potential_target) || !src.faction || !(potential_target.faction & src.faction)

	critter_attack(mob/target)
		var/datum/targetable/critter/selected_ability = src.abilityHolder.getAbility(/datum/targetable/critter/maneater_devour)
		//we check here for valid target because we could retaliate against an ally and dont want to devour them
		//if the target is unconscious and we are unable to eat them, we gotta wack them a bit
		if(isunconscious(target) && ishuman(target) && valid_target(target)&& !selected_ability.disabled && selected_ability.cooldowncheck())
			//we want to grab with our left tentacle hand
			src.set_a_intent(INTENT_GRAB)
			src.set_dir(get_dir(src, target))
			src.active_hand = 1

			var/list/params = list()
			params["left"] = TRUE
			params["ai"] = TRUE

			var/obj/item/grab/G = src.equipped()
			if (!istype(G)) //if it hasn't grabbed something, try to
				if(!isnull(G)) //if we somehow have something that isn't a grab in our hand
					src.drop_item()
				src.hand_attack(target, params)
				return
			else
				if (G.affecting == null || G.assailant == null || G.disposed || !ishuman(G.affecting))
					src.drop_item()
					return

				if (G.state <= GRAB_PASSIVE)
					G.AttackSelf(src)
					return
				else
					selected_ability.handleCast(target)
					return
		else
			//we want to nibble on them with out right hand
			src.set_a_intent(INTENT_HARM)
			src.set_dir(get_dir(src, target))
			src.active_hand = 2

			var/list/params = list()
			params["right"] = TRUE
			params["ai"] = TRUE

			src.hand_attack(target, params)
			return

/mob/living/critter/plant/maneater_polymorph
	name = "man-eating plant"
	real_name = "Wizard-eating plant"
	desc = "It looks upset about something..."
	density = 1
	icon_state = "maneater"
	icon_state_dead = "maneater-dead"
	custom_gib_handler = /proc/vegetablegibs
	blood_id = "poo"
	hand_count = 2
	can_throw = 1
	can_grab = 1
	can_disarm = 1
	stamina = 300
	stamina_max = 300
	add_abilities = list(/datum/targetable/critter/slam/polymorph, /datum/targetable/critter/bite/maneater_bite)   //Devour way too abusable, but plant with teeth needs bite =)
	planttype = /datum/plant/maneater

	specific_emotes(var/act, var/param = null, var/voluntary = 0)
		switch (act)
			if ("scream")
				if (src.emote_check(voluntary, 50))
					playsound(src, 'sound/voice/MEraaargh.ogg', 50, 1, channel=VOLUME_CHANNEL_EMOTE)
					return "<b><span class='alert'>[src] roars!</span></b>"
		return null

	specific_emote_type(var/act)
		switch (act)
			if ("scream")
				return 2
		return ..()

	setup_equipment_slots()
		equipment += new /datum/equipmentHolder/ears(src)
		equipment += new /datum/equipmentHolder/head(src)

	setup_hands()
		..()
		var/datum/handHolder/HH = hands[1]
		HH.name = "tendrils"
		HH = hands[2]
		HH.name = "mouth"					// designation of the hand - purely for show
		HH.icon = 'icons/mob/critter_ui.dmi'	// the icon of the hand UI background
		HH.icon_state = "mouth"				// the icon state of the hand UI background
		HH.limb_name = "teeth"					// name for the dummy holder
		HH.limb = new /datum/limb/mouth		// if not null, the special limb to use when attack_handing
		HH.can_hold_items = 1

	New()
		..()

	setup_healths()
		add_hh_flesh(120, 1)
		add_hh_flesh_burn(120, 1.25)
		var/datum/healthHolder/toxin/tox = add_health_holder(/datum/healthHolder/toxin)
		tox.maximum_value = 100
		tox.value = 100
		tox.last_value = 100
		tox.damage_multiplier = 1
