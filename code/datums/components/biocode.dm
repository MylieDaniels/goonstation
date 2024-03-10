/datum/component/biocode
	dupe_mode = COMPONENT_DUPE_UNIQUE
	var/owner_mob = null
	var/failure_damage = 10
	var/block_interact = TRUE

TYPEINFO(/datum/component/biocode)
	initialization_args = list(
		ARG_INFO("biocode", DATA_INPUT_MOB_REFERENCE, "The mob that can interact with the parent safely, if any", null),
		ARG_INFO("damage", DATA_INPUT_NUM, "Damage taken on certain unsafe interactions", 10),
		ARG_INFO("block", DATA_INPUT_BOOL, "Does the action go through despite damage?", TRUE)
	)

/datum/component/biocode/Initialize(biocode, damage, block)
	. = ..()
	owner_mob = biocode
	failure_damage = damage
	block_interact = block
	if(isitem(parent))
		RegisterSignal(parent, COMSIG_ITEM_PICKUP, PROC_REF(attempted_pickup))
		return
	if(ismob(parent))
		RegisterSignal(parent, COMSIG_MOB_HELPED, PROC_REF(attempted_help))
		return
	return COMPONENT_INCOMPATIBLE

/datum/component/biocode/proc/attempted_pickup(obj/item/grabbed, mob/grabber)
	var/obj/item/I = grabbed
	var/mob/M = grabber
	if (M != owner_mob && !M.nodamage)
		if (!ON_COOLDOWN(M, "biocode_stab", 1 SECOND))
			var/area/T = get_area(I)
			if(failure_damage > 0 && !T?.sanctuary)
				boutput(M, SPAN_ALERT("The biocode lock on [I] gives you a nasty cut [block_interact ? "trying to" : "when you"] pick it up!"))
				random_brute_damage(M, failure_damage)
				take_bleeding_damage(M, null, failure_damage, DAMAGE_STAB)
			else
				boutput(M, SPAN_ALERT("The biocode lock on [I] beeps angrily [block_interact ? "trying to" : "when you"] pick it up!"))
		return block_interact ? ITEM_PICKUP_DONT_PICKUP : 0

/datum/component/biocode/proc/attempted_help(mob/helped, mob/helper)
	var/mob/helped_mob = helped
	var/mob/helper_mob = helper
	if (helper_mob != owner_mob && !helper_mob.nodamage)
		if (!ON_COOLDOWN(helper_mob, "biocode_stab", 1 SECOND))
			var/area/T = get_area(helper_mob)
			if(failure_damage > 0 && !T?.sanctuary)
				boutput(helper_mob, SPAN_ALERT("The biocode lock on [helped_mob] gives you a nasty cut [block_interact ? "trying to" : "when you"] help!"))
				random_brute_damage(helper_mob, failure_damage)
				take_bleeding_damage(helper_mob, null, failure_damage, DAMAGE_STAB)
			else
				boutput(helper_mob, SPAN_ALERT("The biocode lock on [helped_mob] beeps angrily [block_interact ? "trying to" : "when you"] help!"))
		return block_interact

/datum/component/biocode/UnregisterFromParent()
	UnregisterSignal(parent, list(COMSIG_ITEM_PICKUP, COMSIG_MOB_HELPED))
	. = ..()
