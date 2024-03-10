/datum/component/biocode
	dupe_mode = COMPONENT_DUPE_UNIQUE
	var/owner_mob = null
	var/failure_damage = 10
	var/block_pickup = TRUE

TYPEINFO(/datum/component/biocode)
	initialization_args = list(
		ARG_INFO("biocode", DATA_INPUT_MOB_REFERENCE, "The mob that can use this item up safely, if any", null),
		ARG_INFO("damage", DATA_INPUT_NUM, "Damage taken on an unsafe pickup", 10),
		ARG_INFO("block", DATA_INPUT_BOOL, "Does the item remain on the floor?", TRUE)
	)

/datum/component/biocode/Initialize(biocode, damage, block)
	. = ..()
	if(!isitem(parent))
		return COMPONENT_INCOMPATIBLE
	owner_mob = biocode
	failure_damage = damage
	block_pickup = block
	RegisterSignal(parent, COMSIG_ITEM_PICKUP, PROC_REF(attempted_pickup))

/datum/component/biocode/proc/attempted_pickup(obj/item/grabbed_item, mob/grabber)
	var/obj/item/I = src.parent
	var/mob/M = grabber
	if (M != owner_mob && !M.nodamage)
		if (!ON_COOLDOWN(M, "biocode_stab", 1 SECOND))
			var/area/T = get_area(I)
			if(failure_damage > 0 && !T?.sanctuary)
				boutput(M, SPAN_ALERT("The biocode lock on [I] gives you a nasty cut [block_pickup ? "trying to" : "when you"] pick it up! Maybe you can slice it off..."))
				random_brute_damage(M, failure_damage)
				take_bleeding_damage(M, null, failure_damage, DAMAGE_STAB)
			else
				boutput(M, SPAN_ALERT("The biocode lock on [I] beeps angrily [block_pickup ? "trying to" : "when you"] pick it up! Maybe you can slice it off..."))
		return block_pickup ? ITEM_PICKUP_DONT_PICKUP : 0

/datum/component/biocode/UnregisterFromParent()
	UnregisterSignal(parent, COMSIG_ITEM_PICKUP)
	. = ..()
