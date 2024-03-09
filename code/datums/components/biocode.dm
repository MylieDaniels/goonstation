/datum/component/biocode
	dupe_mode = COMPONENT_DUPE_UNIQUE
	var/stamper_real_name = null

TYPEINFO(/datum/component/biocode)
	initialization_args = list(
		ARG_INFO("stamper", DATA_INPUT_TEXT, "real_name that can pick this item up safely", "Father Grife")
	)

/datum/component/biocode/Initialize(stamper)
	. = ..()
	if(!isitem(parent))
		return COMPONENT_INCOMPATIBLE
	stamper_real_name = stamper
	RegisterSignal(parent, COMSIG_ITEM_PICKUP, PROC_REF(attempted_pickup))

/datum/component/biocode/proc/attempted_pickup(mob/grabber)
	var/mob/M = grabber
	if (M.real_name != stamper_real_name)
		if(ON_COOLDOWN(M, "biocode_stab", 1 SECOND))
			boutput(M, SPAN_ALERT("The biocode stamp on [src] gives you a nasty cut trying to pick it up! Maybe you can slice it off..."))
			random_brute_damage(M, 10)
			take_bleeding_damage(M, null, 10, DAMAGE_STAB)
		return ITEM_PICKUP_DONT_PICKUP

/datum/component/biocode/UnregisterFromParent()
	UnregisterSignal(parent, COMSIG_ITEM_PICKUP)
	. = ..()
