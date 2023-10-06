
/*
/datum/lifeprocess/arrest_icon
	process(var/datum/gas_mixture/environment)
		if (!human_owner) //humans only, fix this later to work on critters!!!
			return ..()

		var/mob/living/carbon/human/H = owner
		if (H.arrestIcon) // Update security hud icon

			//TODO : move this code somewhere else that updates from an event trigger instead of constantly
			var/arrestState = ""
			var/visibleName = H.face_visible() ? H.real_name : H.name

			var/datum/db_record/record = data_core.security.find_record("name", visibleName)
			if(record)
				var/criminal = record["criminal"]
				if(criminal == "*Arrest*" || criminal == "Parolled" || criminal == "Incarcerated" || criminal == "Released" || criminal == "Clown")
					arrestState = criminal
			else if(H.traitHolder.hasTrait("stowaway") && H.traitHolder.hasTrait("jailbird"))
				arrestState = "*Arrest*"

			if (arrestState != "*Arrest*") // Check for loyalty implant statuses
				if (locate(/obj/item/implant/counterrev) in H.implant)
					if (H.mind?.get_antagonist(ROLE_HEAD_REVOLUTIONARY))
						arrestState = "RevHead"
					else if (H.mind?.get_antagonist(ROLE_REVOLUTIONARY))
						arrestState = "Loyal_Progress"
					else
						arrestState = "Loyal"

			if (H.arrestIcon.icon_state != arrestState)
				H.arrestIcon.icon_state = arrestState

		..()
*/

TYPEINFO(/datum/component/contraband_track)
	initialization_args = list()

/datum/component/contraband_track
	var/contrabandLevel = 0
	var/image/contrabandIcon = null

/datum/component/contraband_track/Initialize()
	. = ..()
	if (!ismob(src.parent))
		return COMPONENT_INCOMPATIBLE
	RegisterSignal(parent, COMSIG_MOB_DROPPED, PROC_REF(update_contraband))
	RegisterSignal(parent, COMSIG_MOB_PICKUP, PROC_REF(update_contraband))
	RegisterSignal(parent, COMSIG_MOB_EQUIP, PROC_REF(update_contraband))
	RegisterSignal(parent, COMSIG_MOB_UNEQUIP, PROC_REF(update_contraband))
	RegisterSignal(parent, COMSIG_ATOM_PROP_MOB_HIDE_ICONS, PROC_REF(on_hide_icons))

/datum/component/contraband_track/proc/on_hide_icons(mob/M, old_val)
	contrabandIcon.alpha = HAS_ATOM_PROPERTY(M, PROP_MOB_HIDE_ICONS) ? 0 : 255

/datum/component/contraband_track/proc/update_contraband(mob/M)
	src.contrabandLevel = 0
	var/mob/living/carbon/human/H = M
	var/obj/item/card/id/myID = M.equipped()

	if (!istype(myID) && istype(H))
		myID = H.wear_id

	if (myID)
		var/has_carry_permit = (access_carrypermit in myID.access)
		var/has_contraband_permit = (access_contrabandpermit in myID.access)
		if (has_carry_permit && has_contraband_permit)
			return

		if (!has_contraband_permit)
			contrabandLevel += GET_ATOM_PROPERTY(M, PROP_MOVABLE_CONTRABAND_OVERRIDE)

		if((istype(myID, /obj/item/card/id/syndicate)))
			src.contrabandLevel -= 2

		if (ismobcritter(M))
			var/mob/living/critter/parent_critter = M
			for(var/datum/handHolder/hand in parent_critter.hands)
				if (hand.item)
					if (istype(hand.item, /obj/item/gun/))
						if(!has_carry_permit)
							src.contrabandLevel += hand.item.get_contraband()
					else
						if(!has_contraband_permit)
							src.contrabandLevel += hand.item.get_contraband()
				return

		if (istype(H))
			if (H.l_hand)
				if (istype(H.l_hand, /obj/item/gun/))
					if(!has_carry_permit)
						src.contrabandLevel += H.l_hand.get_contraband()
				else
					if(!has_contraband_permit)
						src.contrabandLevel += H.l_hand.get_contraband()

			if (H.r_hand && H.r_hand != H.l_hand)
				if (istype(H.r_hand, /obj/item/gun/))
					if(!has_carry_permit)
						src.contrabandLevel += H.r_hand.get_contraband()
				else
					if(!has_contraband_permit)
						src.contrabandLevel += H.r_hand.get_contraband()

			if (!contrabandLevel && H.belt)
				if (istype(H.belt, /obj/item/gun/))
					if(!has_carry_permit)
						src.contrabandLevel += H.belt.get_contraband() * 0.5
				else
					if(!has_contraband_permit)
						src.contrabandLevel += H.belt.get_contraband() * 0.5

			if (!contrabandLevel && H.wear_suit)
				if(!has_contraband_permit)
					src.contrabandLevel += H.wear_suit.get_contraband()

			if (!contrabandLevel && H.back)
				if (istype(H.back, /obj/item/gun/))
					if (!has_carry_permit)
						src.contrabandLevel += H.back.get_contraband() * 0.5
				else
					if (!has_contraband_permit)
						src.contrabandLevel += H.back.get_contraband() * 0.5
			H.say("[src.contrabandLevel]")
		return

	if (ismobcritter(M))
		var/mob/living/critter/parent_critter = M
		for(var/datum/handHolder/hand in parent_critter.hands)
			if (hand.item)
				src.contrabandLevel += hand.item.get_contraband()
		return

	if (istype(H))
		if (H.l_hand)
			src.contrabandLevel += H.l_hand.get_contraband()
		if (H.r_hand && H.r_hand != H.l_hand)
			src.contrabandLevel += H.r_hand.get_contraband()
		if (H.belt)
			src.contrabandLevel += H.belt.get_contraband() * 0.5
		if (H.wear_suit)
			src.contrabandLevel += H.wear_suit.get_contraband()
		if (H.back)
			src.contrabandLevel += H.back.get_contraband() * 0.5
		H.say("[src.contrabandLevel]")

/datum/component/contraband_track/RegisterWithParent()
	. = ..()
	contrabandIcon = image('icons/effects/sechud.dmi',parent,null,EFFECTS_LAYER_UNDER_4)
	get_image_group(CLIENT_IMAGE_GROUP_ARREST_ICONS).add_image(contrabandIcon)

/datum/component/contraband_track/UnregisterFromParent()
	. = ..()
	UnregisterSignal(parent, list(COMSIG_MOB_DROPPED, COMSIG_MOB_PICKUP))

/datum/component/contraband_track/disposing()
	if(contrabandIcon)
		get_image_group(CLIENT_IMAGE_GROUP_ARREST_ICONS).remove_image(contrabandIcon)
		contrabandIcon.dispose()
		contrabandIcon = null
	..()
