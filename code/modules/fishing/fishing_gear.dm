//file for da fishin gear

// rod flags are WIP, nonfunctional yet
#define ROD_WATER (1<<0) //can it fish in water?

/obj/item/fishing_rod
	name = "fishing rod"
	icon = 'icons/obj/items/fishing_gear.dmi'
	icon_state = "fishing_rod-inactive"
	inhand_image_icon = 'icons/mob/inhand/hand_fishing.dmi'
	item_state = "fishing_rod-inactive"
	/// average time to fish up something, in seconds - will vary on the upper and lower bounds by a maximum of 4 seconds, with a minimum time of 0.5 seconds.
	var/fishing_speed = 8 SECONDS
	/// how long to wait between casts in seconds - mainly so sounds dont overlap
	var/fishing_delay = 2 SECONDS
	/// set to TIME when fished, value is checked when deciding if the rod is currently on cooldown
	var/last_fished = 0
	/// true if the rod is currently "fishing", false if it isnt
	var/is_fishing = FALSE

	//todo: attack particle?? some sort of indicator of where we're fishing
	afterattack(atom/target, mob/user)
		if (target && user && (src.last_fished < TIME + src.fishing_delay))
			var/datum/fishing_spot/fishing_spot = global.fishing_spots[target.type]
			if (fishing_spot)
				actions.start(new /datum/action/fishing(user, src, fishing_spot, target), user)

	update_icon()
		//state for fishing
		if (src.is_fishing)
			src.icon_state = "fishing_rod-active"
			src.item_state = "fishing_rod-active"
		//state for not fishing
		else
			src.icon_state = "fishing_rod-inactive"
			src.item_state = "fishing_rod-inactive"

/// (invisible) action for timing out fishing. this is also what lets the fishing spot know that we fished
/datum/action/fishing
	var/mob/user = null
	/// the target of the action
	var/atom/target = null
	/// what fishing rod triggered this action
	var/obj/item/fishing_rod/rod = null
	/// the fishing spot that the rod is fishing from
	var/datum/fishing_spot/fishing_spot = null
	/// how long the fishing action loop will take in seconds, set on onStart(), varies by 4 seconds in either direction.
	duration = 0
	/// id for fishing action
	id = "fishing_for_fishies"

	New(var/user, var/rod, var/fishing_spot, var/target)
		..()
		src.user = user
		src.rod = rod
		src.fishing_spot = fishing_spot
		src.target = target

	onStart()
		..()
		if (!(BOUNDS_DIST(src.user, src.rod) == 0) || !(BOUNDS_DIST(src.user, src.target) == 0) || !src.user || !src.target || !src.rod || !src.fishing_spot)
			interrupt(INTERRUPT_ALWAYS)
			return

		src.duration = max(0.5 SECONDS, rod.fishing_speed + (pick(1, -1) * (rand(0,40) / 10) SECONDS)) //translates to rod duration +- (0,4) seconds, minimum of 0.5 seconds
		playsound(src.user, 'sound/items/fishing_rod_cast.ogg', 50, 1)
		src.user.visible_message("[src.user] starts fishing.")
		src.rod.is_fishing = TRUE
		src.rod.UpdateIcon()
		src.user.update_inhands()

	onUpdate()
		..()
		if (!(BOUNDS_DIST(src.user, src.rod) == 0) || !(BOUNDS_DIST(src.user, src.target) == 0) || !src.user || !src.target || !src.rod || !src.fishing_spot)
			interrupt(INTERRUPT_ALWAYS)
			src.rod.is_fishing = FALSE
			src.rod.UpdateIcon()
			src.user.update_inhands()
			return

	onEnd()
		if (!(BOUNDS_DIST(src.user, src.rod) == 0) || !(BOUNDS_DIST(src.user, src.target) == 0) || !src.user || !src.target || !src.rod || !src.fishing_spot)
			..()
			interrupt(INTERRUPT_ALWAYS)
			src.rod.is_fishing = FALSE
			src.rod.UpdateIcon()
			src.user.update_inhands()
			return

		if (src.fishing_spot.try_fish(src.user, src.rod, target)) //if it returns one we successfully fished, otherwise lets restart the loop
			..()
			src.rod.is_fishing = FALSE
			src.rod.UpdateIcon()
			src.user.update_inhands()
			return

		else //lets restart the action
			src.onRestart()

/obj/item/syndie_fishing_rod
	name = "\improper Scylla fishing rod"
	desc = "A high grade tactical fishing rod, completely impractical for reeling in bass."
	icon = 'icons/obj/items/fishing_gear.dmi'
	icon_state = "syndicate_fishing_rod-inactive"
	inhand_image_icon = 'icons/mob/inhand/hand_fishing.dmi'
	item_state = "syndicate_fishing_rod-inactive"
	hit_type = DAMAGE_STAB
	flags = FPRINT | TABLEPASS | USEDELAY
	w_class = W_CLASS_NORMAL
	force = 10
	throwforce = 5
	throw_speed = 1
	throw_range = 5
	contraband = 4
	is_syndicate = TRUE
	var/obj/item/implant/syndie_lure/lure = null
	// delay between tossing or reeling or etc
	var/usage_cooldown = 0.8 SECONDS
	// time per step to reel/filet a mob
	var/syndie_fishing_speed = 1 SECOND
	// cooldown after throwing a hooked target around
	var/yank_cooldown = 9 SECONDS
	// how far the line can stretch
	var/line_length = 8
	// true if the rod is currently ""fishing"", false if it isnt
	var/is_fishing = FALSE
	var/authorized = 0

	New()
		..()
		src.lure = new (src)
		src.lure.rod = src

	get_desc(dist)
		..()
		if (dist < 1) // on our tile or our person
			if (.) // we're returning something
				. += " " // add a space
			if (!src.lure)
				src.lure = new (src)
				src.lure.rod = src
			. += "There is \a [src.lure.name] presented as bait."

	attackby(obj/item/I, mob/user)
		if (!src.lure)
			src.lure = new (src)
			src.lure.rod = src
		if (src.lure.loc == src)
			if (istype(I, /obj/item/disk/data/floppy/read_only/authentication))
				if (src.authorized == 0)
					boutput(user, "You hook \the activation codes onto the [src.name] and reel out the valuable information.")
					I.changeStatus("acid", 3 SECONDS, list("leave_cleanable" = 1))
					src.authorized = 1
				return
			else
				boutput(user, "You scan \the [I.name] onto \the [src.name]'s holographic bait projector.")
			src.lure.name = I.name
			src.lure.real_name = I.name
			src.lure.desc = I.desc
			src.lure.real_desc = I.desc
			src.lure.icon = getFlatIcon(I)
			src.lure.set_dir(I.dir)
			src.lure.tooltip_rebuild = 1
			tooltip_rebuild = 1
		else
			boutput(user, "You can't change the bait while the line is out!")
		return

	attack_self(mob/user)
		. = ..()
		if (!src.lure)
			src.lure = new (src)
			src.lure.rod = src
		if (src.lure.loc == src)
			boutput(user, "You clean and reset \the [src.name]'s holographic bait projector.")
			src.lure.clean_forensic()
			src.lure.name = initial(src.lure.name)
			src.lure.real_name = initial(src.lure.real_name)
			src.lure.desc = initial(src.lure.desc)
			src.lure.real_desc = initial(src.lure.real_desc)
			src.lure.icon = initial(src.lure.icon)
			src.lure.set_dir(0)
			src.lure.tooltip_rebuild = 1
		else
			boutput(user, "You can't reset the lure while the line is out!")

	// here so that afterattack is called at range, which is the least bad way to throw the lure
	pixelaction(atom/target, params, mob/user, reach)
		..()

	afterattack(atom/target, mob/user)
		..()
		if (!src.lure)
			src.lure = new (src)
			src.lure.rod = src
			tooltip_rebuild = 1
		if (!ON_COOLDOWN(user, "syndie_fishing_delay", src.usage_cooldown))
			if(istype(target, /obj/submachine/syndicate_teleporter) && can_reach(user, target) && src.authorized == 1)
				src.authorized = 2
				playsound(user, 'sound/items/fishing_rod_cast.ogg', 50, 1)
				user.visible_message("<span class='alert'><b>[user] casts the authentication codes into the [target]!</b></span>")
				showswirl(target)
				var/obj/item/clothing/head/fish_fear_syndicate/reward = new /obj/item/clothing/head/fish_fear_syndicate(get_turf(target))
				user.visible_message("<span class='alert'><b>[user] reels in \the [reward]!</b></span>")
				return
			if (src.lure.owner && isliving(src.lure.owner))
				if (!actions.hasAction(user,"fishing_for_fools"))
					actions.start(new /datum/action/bar/syndie_fishing(user, src.lure.owner, src, src.lure), user)
				if (!ON_COOLDOWN(user, "syndie_fishing_yank", src.yank_cooldown))
					src.lure.owner.throw_at(target, 4, 1)
					user.visible_message("<span class='alert'><b>[user] thrashes [src.lure.owner] by yanking \the [src.name]!</b></span>")
			else if (src.lure.loc == src)
				if (target == loc)
					return
				playsound(user, 'sound/items/fishing_rod_cast.ogg', 50, 1)
				src.is_fishing = TRUE
				src.UpdateIcon()
				user.update_inhands()
				src.lure.pixel_x = rand(-12, 12)
				src.lure.pixel_y = rand(-12, 12)
				src.lure.set_loc(get_turf(src.loc))
				src.lure.throw_at(target, src.line_length, 2)
			else
				src.is_fishing = FALSE
				src.UpdateIcon()
				user.update_inhands()
				src.lure.throw_at(src, 15, 2)
				SPAWN(0.2 SECONDS)
					if (src.lure)
						if (src.lure.owner)
							src.lure.owner.throw_at(src, 2, 2)
						else
							src.lure.set_loc(src)

	update_icon()
		//state for fishing
		if (src.is_fishing)
			src.icon_state = "syndicate_fishing_rod-active"
			src.item_state = "fishing_rod-active"
		//state for not fishing
		else
			src.icon_state = "syndicate_fishing_rod-inactive"
			src.item_state = "fishing_rod-inactive"

	proc/reel_in(mob/target, mob/user, damage_per_reel = 5)
		target.setStatusMin("staggered", 4 SECONDS)
		if(BOUNDS_DIST(target, user) == 0)
			user.visible_message("<span class='alert'><b>[user] reels some meat out of [target] with \the [src.name]!</b></span>")
			if (prob(min(100,damage_per_reel * 2)))
				target.emote("scream")
				if (target.bioHolder && target.bioHolder.Uid && target.bioHolder.bloodType)
					gibs(target.loc, blood_DNA=target.bioHolder.Uid, blood_type=target.bioHolder.bloodType, headbits=FALSE, source=target)
				else
					gibs(target.loc, headbits=FALSE, source=target)
			take_bleeding_damage(target, user, damage_per_reel, DAMAGE_CUT)
			random_brute_damage(target, damage_per_reel)
		else
			step_towards(target, user)

/obj/item/implant/syndie_lure
	name = "barbed lure"
	icon = 'icons/obj/items/weapons.dmi'
	icon_state = "bear_trap-open"
	item_state = "bear_trap"
	object_flags = NO_GHOSTCRITTER
	throwforce = 5
	density = 0
	var/obj/item/syndie_fishing_rod/rod = null

	UpdateName()
		src.name = "[name_prefix(null, 1)][src.real_name][name_suffix(null, 1)]"

	attackby(obj/item/W, mob/user)
		if (!(W == src.rod) && isliving(user) && !user.nodamage && GET_DIST(src, src.rod) < src.rod.line_length)
			user.changeStatus("weakened", 5 SECONDS)
			user.TakeDamage(user.hand == LEFT_HAND ? "l_arm": "r_arm", 15, 0, 0, DAMAGE_STAB)
			user.force_laydown_standup()
			implanted(user, null)
		else
			return ..()

	attack_hand(mob/user)
		if (isliving(user) && !user.nodamage && GET_DIST(src, src.rod) < src.rod.line_length)
			user.changeStatus("weakened", 5 SECONDS)
			user.TakeDamage(user.hand == LEFT_HAND ? "l_arm": "r_arm", 15, 0, 0, DAMAGE_STAB)
			user.force_laydown_standup()
			implanted(user, null)
		else
			return ..()

	pickup(mob/user)
		if (isliving(user) && !user.nodamage && GET_DIST(src, src.rod) < src.rod.line_length)
			user.changeStatus("weakened", 5 SECONDS)
			user.TakeDamage(user.hand == LEFT_HAND ? "l_arm": "r_arm", 15, 0, 0, DAMAGE_STAB)
			user.force_laydown_standup()
			implanted(user, null)
		else
			return ..()

	pull(mob/user)
		if (isliving(user) && !user.nodamage && GET_DIST(src, src.rod) < src.rod.line_length)
			user.changeStatus("weakened", 5 SECONDS)
			user.TakeDamage(user.hand == LEFT_HAND ? "l_arm": "r_arm", 15, 0, 0, DAMAGE_STAB)
			user.force_laydown_standup()
			implanted(user, null)
		else
			return ..()

	throw_impact(mob/hit_atom, datum/thrown_thing/thr)
		if (hit_atom == src.rod.loc)
			return
		else if ((isliving(hit_atom) && !hit_atom.nodamage && GET_DIST(src, src.rod) < src.rod.line_length))
			implanted(hit_atom, null)
		return ..()

	implanted(mob/M, mob/I)
		if (istype(M))
			M.visible_message("<span class='alert'><b>[M] gets snagged by a fishing lure!</b></span>")
			logTheThing(LOG_COMBAT, M, "is caught by a barbed fishing lure at [log_loc(src)]")
			M.emote("scream")
			take_bleeding_damage(M, null, 10, DAMAGE_STAB)
			M.UpdateDamageIcon()
		return ..()

	on_life(mult)
		. = ..()
		if (GET_DIST(src, src.rod) > src.rod.line_length && src.owner)
			src.owner.visible_message("\The [src] rips out of [src.owner]!", "\The [src] rips out of you!")
			take_bleeding_damage(src.owner, null, 5, DAMAGE_STAB)
			src.set_loc(get_turf(src.loc))
			src.on_remove(src.owner)

	Eat(mob/M, mob/user, by_matter_eater)
		. = ..()
		M.emote("scream")
		M.TakeDamage("chest", 25, 0, 0, DAMAGE_CUT)
		M.visible_message("\The [src] tears a bunch of gore out of [M.name]!")
		if (M.bioHolder && M.bioHolder.Uid && M.bioHolder.bloodType)
			gibs(M.loc, blood_DNA=M.bioHolder.Uid, blood_type=M.bioHolder.bloodType, headbits=FALSE, source=M)
		else
			gibs(M.loc, headbits=FALSE, source=M)
		var/mob/living/carbon/human/H = M
		if (istype(H))
			if (H.organHolder)
				for(var/organ in list("left_kidney", "stomach", "intestines", "spleen", "pancreas"))
					var/obj/item/organ/O = H.drop_organ(organ, M.loc)
					if (istype(O))
						O.throw_at(src.rod.loc, rand(3,6), rand(1,2))
		qdel(src)

	disposing()
		. = ..()
		src.rod.lure = null

//action (with bar) for reeling in a mob with the Scylla
/datum/action/bar/syndie_fishing
	interrupt_flags = INTERRUPT_MOVE | INTERRUPT_STUNNED | INTERRUPT_ACTION
	var/mob/user = null
	/// the target of the action
	var/mob/target = null
	/// what fishing rod caught the mob
	var/obj/item/syndie_fishing_rod/rod = null
	/// what lure is snagged in the mob
	var/obj/item/implant/syndie_lure/lure = null
	/// how much damage is dealt on a filet, starting at 1 and increasing by 1 after each loop
	var/damage_per_reel = 1
	/// how long a step of reeling takes, set onStart
	duration = 0
	/// id for fishing action
	id = "fishing_for_fools"

	New(var/user, var/target, var/rod, var/lure)
		..()
		src.user = user
		src.target = target
		src.rod = rod
		src.lure = lure

	onStart()
		..()
		if (!src.user || !src.target || !src.rod || !src.lure || !(src.rod.loc == src.user) || GET_DIST(src.user, src.target) > src.rod.line_length)
			interrupt(INTERRUPT_ALWAYS)
			return

		src.duration = max(0.1 SECONDS, rod.syndie_fishing_speed)
		playsound(src.user, 'sound/items/fishing_rod_cast.ogg', 50, 1)
		APPLY_ATOM_PROPERTY(src.target, PROP_MOB_CANTSPRINT, src)
		APPLY_MOVEMENT_MODIFIER(src.target, /datum/movement_modifier/syndie_fishing, src)
		src.user.visible_message("[src.user] sets the hook!")
		src.rod.is_fishing = TRUE
		src.rod.UpdateIcon()
		src.user.update_inhands()

	onUpdate()
		..()
		if (!src.user || !src.target || !src.rod || !src.lure || !(src.rod.loc == src.user) || GET_DIST(src.user, src.target) > src.rod.line_length)
			interrupt(INTERRUPT_ALWAYS)
			return

	onEnd()
		if (!src.user || !src.target || !src.rod || !src.lure || !(src.rod.loc == src.user) || GET_DIST(src.user, src.target) > src.rod.line_length)
			..()
			interrupt(INTERRUPT_ALWAYS)
			return

		src.rod.reel_in(src.target, src.user, src.damage_per_reel)
		src.damage_per_reel += 1
		src.onRestart()

	onDelete()
		..()
		src.lure.set_loc(get_turf(src.lure.loc))
		if (src.lure.owner)
			src.lure.on_remove(src.lure.owner)
		REMOVE_ATOM_PROPERTY(src.target, PROP_MOB_CANTSPRINT, src)
		REMOVE_MOVEMENT_MODIFIER(src.target, /datum/movement_modifier/syndie_fishing, src)

// portable fishing portal currently found in a prefab in space
TYPEINFO(/obj/item/fish_portal)
	mats = 11

/obj/item/fish_portal
	name = "Fishing Portal Generator"
	desc = "A small device that creates a portal you can fish in."
	icon = 'icons/obj/items/fishing_gear.dmi'
	icon_state = "fish_portal"

	attack_self(mob/user as mob)
		new /obj/machinery/active_fish_portal(get_turf(user))
		playsound(src.loc, 'sound/items/miningtool_on.ogg', 40)
		user.visible_message("[user] flips on the [src].", "You turn on the [src].")
		user.u_equip(src)
		qdel(src)

/obj/machinery/active_fish_portal
	name = "Fishing Portal"
	desc = "A portal you can fish in. It's not big enough to go through."
	anchored = 1
	icon = 'icons/obj/items/fishing_gear.dmi'
	icon_state = "fish_portal-active"

	attack_hand(mob/user)
		new /obj/item/fish_portal(get_turf(src))
		playsound(src.loc, 'sound/items/miningtool_off.ogg', 40)
		user.visible_message("[user] flips off the [src].", "You turn off the [src].")
		qdel(src)
