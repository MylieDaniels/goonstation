ABSTRACT_TYPE(/obj/item/mob_part)

/obj/item/mob_part
	name = "body part"
	icon = 'icons/obj/robot_parts.dmi'
	inhand_image_icon = 'icons/mob/inhand/hand_tools.dmi'
	item_state = "buildpipe"
	flags = FPRINT | TABLEPASS
	c_flags = ONBELT
	override_attack_hand = 0
	/// where can it fit? bitflags, check defines/mob.dm
	var/slot = null
	/// what streaks everywhere when it's cut off?
	var/streak_decal = /obj/decal/cleanable/blood
	/// bloody, oily, etc
	var/streak_descriptor = "bloody"
	/// used by arms for attack_hand overrides
	var/datum/limb/limb_data = null
	/// the type of limb_data
	var/limb_type = /datum/limb

	/// how attached this part is
	var/remove_stage = LIMB_SURGERY_ATTACHED

	/// the mob this part is attached to
	var/mob/living/holder = null

	/// for avoiding istype in update icon
	var/accepts_normal_human_overlays = TRUE
	/// When attached, applies this movement modifier
	var/datum/movement_modifier/movement_modifier
	/// Part is not attached to its original owner
	var/part_is_transplanted = FALSE

	New(atom/new_holder)
		..()
		if(istype(new_holder, /mob/living))
			src.holder = new_holder
		src.limb_data = new src.limb_type(src)
		if (src.holder && src.movement_modifier)
			APPLY_MOVEMENT_MODIFIER(holder, movement_modifier, src)

	disposing()
		if (src.limb_data)
			src.limb_data.holder = null
			src.limb_data = null

		if (src.holder && src.holder.organHolder)
			for(var/thing in src.holder.organHolder.organ_list)
				if(thing == "all")
					continue
				if(src.holder.organHolder.organ_list[thing] == src)
					src.holder.organHolder.organ_list[thing] = null

		src.holder = null
		..()

	/// just get rid of it. don't put it on the floor, don't show a message
	proc/delete()
		if (src.holder && src.movement_modifier)
			REMOVE_MOVEMENT_MODIFIER(holder, movement_modifier, src)

		qdel(src)
		return

	/// Cut it off, put it on the floor, and show a message sometimes
	proc/remove(var/show_message = TRUE)
		if (!src.holder) // fix for Cannot read null.loc, hopefully - haine
			return

		if (movement_modifier)
			REMOVE_MOVEMENT_MODIFIER(src.holder, src.movement_modifier, src)

		var/obj/item/object = src
		src.remove_stage = LIMB_SURGERY_DETACHED
		object.set_loc(src.holder.loc)

		//https://forum.ss13.co/showthread.php?tid=1774
		//object.name = "[src.holder.real_name]'s [initial(object.name)]"
		object.add_fingerprint(src.holder)

		if(show_message)
			holder.visible_message(SPAN_ALERT("[src.holder.name]'s [object.name] falls off!"))

		if(!QDELETED(src))
			src.holder = null
		return object

	/// Called every life tick when attached to a mob
	proc/on_life(datum/controller/process/mobs/parent)
		return

ABSTRACT_TYPE(/obj/item/mob_part/humanoid_part)

/obj/item/mob_part/humanoid_part
	name = "humanoid part"

	/// Used by getMobIcon to pass off to update_body. Typically holds image(the_limb's_icon, "[src.slot]")
	var/image/bodyImage
	/// The icon the mob sprite uses when attached, change if the limb's icon isnt in 'icons/mob/human.dmi'
	var/partIcon = 'icons/mob/human.dmi'
	/// The part of the icon state that differs per part, ie "brullbar" for brullbar arms
	var/partIconModifier = null
	var/partDecompIcon = 'icons/mob/human_decomp.dmi'
	/// Used by getHandIconState to determine the attached-to-mob-sprite hand sprite
	var/handlistPart
	/// Used by getPartIconState to determine the attached-to-mob-sprite non-hand sprite
	var/partlistPart
	/// If TRUE, it'll resist mutantraces trying to change them
	var/limb_is_unnatural = FALSE
	/// What kind of limb is this? So we dont have to do dozens of typechecks. is bitflags, check defines/item.dm
	var/kind_of_limb
	/// Can we roll this limb as a random humanoid limb?
	var/random_limb_blacklisted = TRUE
	///if the only icon is above the clothes layer ie. in the handlistPart list
	var/no_icon = FALSE

	/// set to TRUE if this limb has decomposition icons
	var/decomp_affected = TRUE
	var/current_decomp_stage_s = -1

	///Attachable without surgery?
	var/easy_attach = FALSE

	/// brute damage taken per surgery stage (times 3.5 for self-surgery)
	var/surgery_brute = 10
	/// bleeding damage taken per surgery stage
	var/surgery_bleeding = 15

	/// stage 1 and 3 surgery messages (for patient/surgeon)
	var/list/cut_messages = list("stupidly slices through", "stupidly slice through")
	/// stage 2 surgery messages (for patient/surgeon)
	var/list/saw_messages = list("throws the saw aside and tears through", "throw the saw aside and tear through")
	/// surgery material messages (per stage)
	var/limb_material = list("Source missing texture","unobtanium","strangelet loaf crust")

	delete()
		if(ishuman(src.holder))
			var/mob/living/carbon/human/H = src.holder
			H.limbs.vars[src.slot] = null
			H.update_clothing()
			H.update_body()
			H.set_body_icon_dirty()
			H.UpdateDamageIcon()
		..()

	disposing()
		if(ishuman(src.holder))
			var/mob/living/carbon/human/H = src.holder
			if(H.limbs.vars[src.slot] == src)
				H.limbs.vars[src.slot] = null
		..()

	remove()
		if(ishuman(holder))
			var/mob/living/carbon/human/H = holder
			H.limbs.vars[src.slot] = null
			//fix for gloves/shoes still displaying after limb loss
			H.update_clothing()
			H.update_body()
			H.set_body_icon_dirty()
			H.UpdateDamageIcon()
			if (src.slot & LIMB_LEFT_ARM)
				H.drop_from_slot(H.l_hand)
				H.hud.update_hands()
			if (src.slot & LIMB_RIGHT_ARM)
				H.drop_from_slot(H.r_hand)
				H.hud.update_hands()

	proc/getMobIcon(var/decomp_stage = DECOMP_STAGE_NO_ROT, icon/mutantrace_override, force = FALSE)
		if(no_icon)
			return 0
		if (force)
			qdel(src.bodyImage)
			src.bodyImage = null
		var/used_icon = mutantrace_override || getAttachmentIcon(decomp_stage)
		if (src.bodyImage && ((src.decomp_affected && src.current_decomp_stage_s == decomp_stage) || !src.decomp_affected))
			return src.bodyImage
		current_decomp_stage_s = decomp_stage
		var/icon_state = src.getMobIconState(decomp_stage)
		src.bodyImage = image(used_icon, icon_state)
		return bodyImage

	proc/getMobIconState(var/decomp_stage = DECOMP_STAGE_NO_ROT)
		var/decomp = ""
		if (src.decomp_affected && decomp_stage)
			decomp = "_decomp[decomp_stage]"
		return "[src.slot][src.partIconModifier ? "_[src.partIconModifier]" : ""][decomp]"

	proc/getAttachmentIcon(var/decomp_stage = DECOMP_STAGE_NO_ROT)
		if (src.decomp_affected && decomp_stage)
			return src.partDecompIcon
		return src.partIcon

	proc/getHandIconState(var/decomp_stage = DECOMP_STAGE_NO_ROT)
		var/decomp = ""
		if (src.decomp_affected && decomp_stage)
			decomp = "_decomp[decomp_stage]"

		//boutput(world, "Attaching standing hand [src.slot][decomp]_s on decomp stage [decomp_stage].")
		return "[src.handlistPart][decomp]"

	proc/getPartIconState(var/decomp_stage = DECOMP_STAGE_NO_ROT)
		var/decomp = ""
		if (src.decomp_affected && decomp_stage)
			decomp = "_decomp[decomp_stage]"

		//boutput(world, "Attaching standing part [src.slot][decomp]_s on decomp stage [decomp_stage].")
		return "[src.partlistPart][decomp]"

	proc/surgery(obj/item/tool, mob/surgeon)
		if(remove_stage > 0 && (istype(tool, /obj/item/staple_gun) || istype(tool, /obj/item/suture)) )
			remove_stage = 0

		else if(remove_stage == LIMB_SURGERY_ATTACHED || remove_stage == LIMB_SURGERY_STEP_TWO)
			if(istool(tool, TOOL_CUTTING))
				src.remove_stage++
			else
				return FALSE

		else if(remove_stage == LIMB_SURGERY_STEP_ONE)
			if(istool(tool, TOOL_SAWING))
				src.remove_stage++
			else
				return FALSE

		if(isalive(holder)) // dont scream if dead or unconscious
			if(prob(clamp(src.surgery_brute * 2, 0, 100)))
				holder.emote("scream")

		holder.TakeDamage("chest", src.surgery_brute, 0, 0, DAMAGE_STAB)
		take_bleeding_damage(holder, surgeon, src.surgery_bleeding, DAMAGE_STAB, surgery_bleed = TRUE)

		switch(remove_stage)
			if(0)
				surgeon.visible_message("<span class'alert'>[surgeon] attaches [src.name] to [holder.name] with [tool].</span>", SPAN_ALERT("You attach [src.name] to [holder.name] with [tool]."))
				logTheThing(LOG_COMBAT, surgeon, "attaches [src.name] to [constructTarget(holder,"combat")].")
			if(1)
				surgeon.visible_message(SPAN_ALERT("[surgeon] [src.cut_messages[1]] the [src.limb_material[1]] of [holder.name]'s [src.name] with [tool]."), SPAN_ALERT("You [src.cut_messages[2]] the [src.limb_material[2]] of [holder.name]'s [src.name] with [tool]."))
			if(2)
				surgeon.visible_message(SPAN_ALERT("[surgeon] [src.saw_messages[1]] the [src.limb_material[1]] of [holder.name]'s [src.name] with [tool]."), SPAN_ALERT("You [src.saw_messages[2]] the [src.limb_material[2]] of [holder.name]'s [src.name] with [tool]."))

				SPAWN(rand(15, 20) SECONDS)
					if(remove_stage == 2)
						src.remove(FALSE)
			if(3)
				surgeon.visible_message(SPAN_ALERT("[surgeon] [src.cut_messages[1]] the remaining [src.limb_material[3]] holding [holder.name]'s [src.name] on with [tool]."), SPAN_ALERT("You [src.cut_messages[2]] the remaining [src.limb_material[3]] holding [holder.name]'s [src.name] on with [tool]."))
				logTheThing(LOG_COMBAT, surgeon, "removes [src.name] to [constructTarget(holder,"combat")].")
				src.remove(FALSE)

		return TRUE

	proc/attach(var/mob/living/carbon/human/attachee,var/mob/attacher)
		if(!ishuman(attachee) || !(src.slot | attachee.limbs))
			return ..()

		var/can_secure = FALSE
		if(attacher)
			can_secure = ismob(attacher) && (attacher?.find_type_in_hand(/obj/item/suture) || attacher?.find_type_in_hand(/obj/item/staple_gun))

			if(!can_act(attacher))
				return
			if(!src.easy_attach)
				if(!surgeryCheck(attachee, attacher))
					return
			if(attacher.zone_sel.selecting != slot)
				return ..()

			attacher.remove_item(src)

			playsound(attachee, 'sound/effects/attach.ogg', 50, TRUE)
			attacher.visible_message(SPAN_ALERT("[attacher] attaches [src] to [attacher == attachee ? his_or_her(attacher) : "[attachee]'s"] stump. It [src.easy_attach ? "fuses instantly" : can_secure ? "looks very secure" : "doesn't look very secure"]!"))

		attachee.limbs.vars[src.slot] = src
		src.holder = attachee
		src.layer = initial(src.layer)
		src.screen_loc = ""
		src.set_loc(attachee)
		src.remove_stage = (src.easy_attach || can_secure) ? 0 : 2

		if (movement_modifier)
			APPLY_MOVEMENT_MODIFIER(src.holder, movement_modifier, src)

		SPAWN(rand(150,200))
			if(remove_stage == 2) src.remove()

		attachee.update_clothing()
		attachee.update_body()
		attachee.UpdateDamageIcon()
		if (src.slot == "l_arm" || src.slot == "r_arm")
			attachee.hud.update_hands()

		return TRUE


ABSTRACT_TYPE(/obj/item/mob_part/humanoid_part/carbon_part)

/obj/item/mob_part/humanoid_part/carbon_part
	name = "carbon part"
	icon = 'icons/obj/items/human_parts.dmi'
	inhand_image_icon = 'icons/mob/inhand/hand_medical.dmi'
	item_state = "arm-left"
	flags = FPRINT | TABLEPASS | CONDUCT
	force = 6
	stamina_damage = 40
	stamina_cost = 23
	stamina_crit_chance = 5
	hitsound = 'sound/impact_sounds/meat_smack.ogg'


	cut_messages = list("slices", "slice")
	saw_messages = list("saws", "saw")
	limb_material = list("skin and flesh","bone","strips of skin")

	random_limb_blacklisted = FALSE

	/// is this affected by human skin tones? Also if the severed limb uses a separate bloody-stump icon layered on top
	var/skintoned = TRUE

	// Gets overlaid onto the severed limb, under the stump if the limb is skintoned
	/// The icon of this overlay
	var/severed_overlay_1_icon
	/// The state of this overlay
	var/severed_overlay_1_state
	/// The color reference. null for uncolored("#ffffff"), CUST_1/2/3 for one of the mob's haircolors, SKIN_TONE for the mob's skintone
	var/severed_overlay_1_color

	/// Gets sent to update_body to overlay something onto this limb, like kudzu vines. Only handles the limb, not the hand/foot!
	var/image/limb_overlay_1
	/// The icon of this overlay
	var/limb_overlay_1_icon
	/// The state of this overlay
	var/limb_overlay_1_state
	/// The color reference. null for uncolored("#ffffff"), CUST_1/2/3 for one of the mob's haircolors, SKIN_TONE for the mob's skintone
	var/limb_overlay_1_color

	/// Gets sent to update_body to overlay something onto this hand/foot, like kudzu vines. Only handles the hand/foot, not the limb!
	var/image/handfoot_overlay_1
	/// The icon of this overlay
	var/handfoot_overlay_1_icon
	/// The state of this overlay
	var/handfoot_overlay_1_state
	/// The color reference. null for uncolored("#ffffff"), CUST_1/2/3 for one of the mob's haircolors, SKIN_TONE for the mob's skintone
	var/handfoot_overlay_1_color

	/// the original mob (probably a carbon/human) that this was a part of
	var/mob/living/original_holder = null
	/// the original appearance holder that this was a part of
	var/datum/appearanceHolder/holder_ahol
	/// the DNA of this limb
	var/limb_DNA = null
	/// the fingerprints of this limb, if any
	var/limb_fingerprints = null
	/// whether this limb appends a unique message on examine
	var/show_on_examine = FALSE
	/// the skin tone of this limb
	var/skin_tone = "#FFFFFF"

ABSTRACT_TYPE(/obj/item/mob_part/humanoid_part/silicon_part)

/obj/item/mob_part/humanoid_part/silicon_part

	var/max_health = 100
	var/dmg_blunt = 0
	var/dmg_burns = 0

/obj/item/mob_part/humanoid_part/artifact_part

/obj/item/mob_part/critter_part
