/mob/living/critter/small_animal/vermin_operative
	name = "vermin knight"
	real_name = "vermin knight"
	desc = "A rat.  In space.  With Nuclear Knight armor on.  Wait, what!?"
	flags = TABLEPASS | DOORPASS
	fits_under_table = 1
	hand_count = 2
	icon = 'icons/mob/vermin_operatives.dmi'
	icon_state = "vermin_knight"
	icon_state_dead = "mouse_white-dead"
	speechverb_say = "squeaks"
	speechverb_exclaim = "squeals"
	speechverb_ask = "squeaks"
	health_brute = 40
	health_burn = 40


/*
	New()
		..()
		fur_color =	pick("#101010", "#924D28", "#61301B", "#E0721D", "#D7A83D","#D8C078", "#E3CC88", "#F2DA91", "#F21AE", "#664F3C", "#8C684A", "#EE2A22", "#B89778", "#3B3024", "#A56b46")
		eye_color = "#FFFFF"

	setup_overlays()
		fur_color = src.client?.preferences.AH.customization_first_color
		eye_color = src.client?.preferences.AH.e_color
		var/image/overlay = image('icons/misc/critter.dmi', "mouse_colorkey")
		overlay.color = fur_color
		src.UpdateOverlays(overlay, "hair")

		var/image/overlay_eyes = image('icons/misc/critter.dmi', "mouse_eyes")
		overlay_eyes.color = eye_color
		src.UpdateOverlays(overlay_eyes, "eyes")

	death()
		src.ClearAllOverlays()
		var/image/overlay = image('icons/misc/critter.dmi', "mouse_colorkey-dead")
		overlay.color = fur_color
		src.UpdateOverlays(overlay, "hair")
		..()

	full_heal()
		..()
		src.ClearAllOverlays()
		src.setup_overlays()
*/
	specific_emotes(var/act, var/param = null, var/voluntary = 0)
		switch (act)
			if ("scream")
				if (src.emote_check(voluntary, 50))
					playsound(src, 'sound/voice/animal/mouse_squeak.ogg', 80, 1, channel=VOLUME_CHANNEL_EMOTE)
					return "<span class='emote'><b>[src]</b> squeaks!</span>"
			if ("smile")
				if (src.emote_check(voluntary, 50))
					return "<span class='emote'><b>[src]</b> wiggles [his_or_her(src)] tail happily!</span>"
		return null

	specific_emote_type(var/act)
		switch (act)
			if ("scream")
				return 2
			if ("smile")
				return 1
		return ..()

	setup_hands()
		..()
		var/datum/handHolder/HH = hands[1]
		HH.limb = new /datum/limb/small_critter/strong
		HH.icon = 'icons/mob/critter_ui.dmi'
		HH.icon_state = "handn"
		HH.name = "paw"
		HH.limb_name = "claws"

		HH = hands[2]
		HH.limb = new /datum/limb/mouth/small	// if not null, the special limb to use when attack_handing
		HH.icon = 'icons/mob/critter_ui.dmi'	// the icon of the hand UI background
		HH.icon_state = "mouth"					// the icon state of the hand UI background
		HH.name = "mouth"						// designation of the hand - purely for show
		HH.limb_name = "teeth"					// name for the dummy holder
		HH.can_hold_items = 0

	attackby(obj/item/I, mob/M)
		if(istype(I, /obj/item/reagent_containers/food/snacks/ingredient/cheese))
			src.visible_message("[M] feeds \the [src] some [I].", "[M] feeds you some [I].")
			for(var/damage_type in src.healthlist)
				var/datum/healthHolder/hh = src.healthlist[damage_type]
				hh.HealDamage(5)
			qdel(I)
			return
		. = ..()

/obj/item/heavy_c_tube
	name = "Bonker heavy cardboard tube"
	desc = "A heavy cardboard tube, likely salvaged from a roll of wrapping paper.  There seems to be a glowstick taped to it."
	icon = 'icons/obj/items/items.dmi'
	icon_state = "c_tube"
	inhand_image_icon = 'icons/mob/inhand/hand_weapons.dmi'
	flags = ONBACK | FPRINT | TABLEPASS
	contraband = 4
	w_class = W_CLASS_NORMAL
	force = 1
	throwforce = 1
	stamina_damage = 30
	stamina_cost = 35
	stamina_crit_chance = 20

	var/maximum_stamina_damage = 80
	var/datum/component/loctargeting/simple_light/light_c

	New()
		..()
		src.setItemSpecial(/datum/item_special/swipe/heavyctube)
		light_c = src.AddComponent(/datum/component/loctargeting/simple_light, 255, 0, 0, 210)
		light_c.update(TRUE)
		BLOCK_SETUP(BLOCK_ROD)

	attack(mob/M, mob/user, def_zone)
		var/turf/t = get_turf(user) // i guess technically rats could end up in a sanctuary
		if (t.loc:sanctuary)
			return

		..()
		if(ishuman(M) && isalive(M) && src.stamina_damage < src.maximum_stamina_damage) //build charge on living humans only, up to the cap
			src.stamina_damage += 5
			boutput(user, "<span class='alert'>[src]'s glowstick shines a bit brighter!</span>")
			src.tooltip_rebuild = TRUE

	dropped(mob/user)
		..()
		if (isturf(src.loc))
			user.visible_message("<span class='alert'>[src] drops from [user]'s hands and dims!</span>")
			stamina_damage = initial(src.stamina_damage)
			src.tooltip_rebuild = TRUE
			return
