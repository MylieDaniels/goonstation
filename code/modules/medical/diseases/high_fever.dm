
/datum/ailment/disease/high_fever
	name = "High Fever"
	max_stages = 5
	stage_prob = 10
	cure_flags = CURE_CUSTOM
	cure_desc = "Ice"
	reagentcure = list("ice")

	associated_reagent = "too much"
	affected_species = list("Human")

/datum/ailment/disease/high_fever/stage_act(var/mob/living/affected_mob, var/datum/ailment_data/D, mult)
	if (..())
		return
	switch(D.stage)
		if(2)
			if(probmult(10))
				boutput(affected_mob, SPAN_ALERT("Its getting warm around here..."))
				affected_mob.bodytemperature += 5
		if(3)
			if(probmult(10))
				boutput(affected_mob, SPAN_ALERT("You're starting to heat up..."))
				affected_mob.bodytemperature += 10
		if(4)
			if(probmult(10))
				boutput(affected_mob, SPAN_ALERT("You're REALLY starting to heat up..."))
				affected_mob.bodytemperature += 15

		if(5)
			boutput(affected_mob, SPAN_ALERT("You're a hundred and one!"))
			var/mob/living/carbon/human/H = affected_mob
			if(H.limbs != null)
				H.limbs.replace_with(LIMB_LEFT_ARM, /obj/item/parts/human_parts/arm/left/hot, null , 0)
				H.limbs.replace_with(LIMB_RIGHT_ARM, /obj/item/parts/human_parts/arm/right/hot, null , 0)
				H.update_body()
			D.stage_prob = 0
			D.stage = 1


