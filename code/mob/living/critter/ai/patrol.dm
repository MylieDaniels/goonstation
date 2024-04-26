/datum/aiHolder/patroller/New()
	..()
	default_task = get_instance(/datum/aiTask/sequence/patrol, list(src))

/// move between targets found with targeting_subtask, interrupting to combat_interrupt if seek_target on owner finds a combat target
/datum/aiTask/sequence/patrol
	name = "patrolling"
	distance_from_target = 0
	max_dist = 7
	var/targeting_subtask_type = /datum/aiTask/succeedable/patrol_target_locate/global_cannabis
	var/combat_interrupt_type = /datum/aiTask/sequence/goalbased/critter/attack

/datum/aiTask/sequence/patrol/New(parentHolder, transTask)
	. = ..()
	add_task(src.holder.get_instance(src.targeting_subtask_type, list(holder)))
	var/datum/aiTask/succeedable/move/movesubtask = holder.get_instance(/datum/aiTask/succeedable/move, list(holder))
	if(istype(movesubtask))
		movesubtask.max_path_dist = 150
	add_task(movesubtask)

/datum/aiTask/sequence/patrol/next_task()
	. = ..()
	if (length(holder.priority_tasks)) //consume priority tasks first
		var/datum/aiTask/priority_task = holder.priority_tasks[1]
		holder.priority_tasks -= priority_task
		return priority_task

/datum/aiTask/sequence/patrol/on_tick()
	var/list/mob/living/combat_targets
	if(ismobcritter(src.holder.owner)) // check for targets
		var/mob/living/critter/C = src.holder.owner
		combat_targets = C.seek_target(src.max_dist)

	if(length(combat_targets) >= 1) // interrupt into combat_interrupt_type
		var/mob/living/combat_target = src.get_best_target(combat_targets)
		if(combat_target)
			var/datum/aiTask/sequence/goalbased/combat_instance = src.holder.get_instance(src.combat_interrupt_type, list(src.holder, src))
			if(combat_instance.precondition())
				src.holder.interrupt_to_task(combat_instance)
			return

	if(src.holder.target && istype(subtasks[subtask_index], /datum/aiTask/succeedable/move)) // MOVE TASK
		// make sure we both set our target and move to our target correctly
		var/datum/aiTask/succeedable/move/M = subtasks[subtask_index]
		if(M && !M.move_target)
			M.distance_from_target = src.distance_from_target
			M.move_target = get_turf(src.holder.target)
	. = ..()

/datum/aiTask/succeedable/patrol_target_locate
	max_dist = 120
	max_fails = 3

/datum/aiTask/succeedable/patrol_target_locate/switched_to()
	. = ..()
	src.holder.target = null

/datum/aiTask/succeedable/patrol_target_locate/succeeded()
	var/distance = GET_DIST(get_turf(src.holder.owner), get_turf(src.target))
	if(distance > 1 && distance <= src.max_dist)
		src.holder.target = get_turf(src.target)

	if(src.holder.target)
		return 1

/datum/aiTask/succeedable/patrol_target_locate/on_reset()
	. = ..()
	src.target = null

/// magically hunt down a weed on our z level
/datum/aiTask/succeedable/patrol_target_locate/global_cannabis/on_tick()
	. = ..()
	for(var/obj/item/X in by_cat[TR_CAT_CANNABIS_OBJ_ITEMS])
		var/obj/item/plant/herb/cannabis/C = X
		if (istype(C) && C.z == holder.owner.z)
			src.target = C
			break

/// securitron patrol pattern
/datum/aiHolder/patroller/packet_based
	var/net_id
	var/next_patrol_id
	var/atom/nearest_beacon
	var/nearest_beacon_id
	var/nearest_dist

/datum/aiHolder/patroller/packet_based/New()
	. = ..()

	default_task = get_instance(/datum/aiTask/sequence/patrol/packet_based, list(src))

	src.net_id = generate_net_id(src.owner)

	src.owner.AddComponent(
		/datum/component/packet_connected/radio, \
		"ai_beacon",\
		FREQ_NAVBEACON, \
		src.net_id, \
		null, \
		FALSE, \
		null, \
		FALSE \
	)
	RegisterSignal(src.owner, COMSIG_MOVABLE_RECEIVE_PACKET, PROC_REF(ai_receive_signal))

/datum/aiHolder/patroller/packet_based/disposing()
	qdel(get_radio_connection_by_id(src.owner, "ai_beacon"))
	UnregisterSignal(src.owner, COMSIG_MOVABLE_RECEIVE_PACKET)
	..()

/datum/aiHolder/patroller/packet_based/proc/ai_receive_signal(mob/attached, datum/signal/signal, transmission_method, range, connection_id)
	if(!src.enabled || !istype(src.current_task,/datum/aiTask/sequence/patrol)) // this ai is off or busy
		return

	if(connection_id == "ai_beacon")
		src.nav_beacon_signal(signal)

/datum/aiHolder/patroller/packet_based/proc/nav_beacon_signal(datum/signal/signal)
	if(signal.data["address_1"] != src.net_id) // commanding the bot requires directly addressing it
		return

	if(signal.data["auth_code"] != netpass_security) // commanding the bot requires netpass_security
		return

	if(!signal.data["beacon"] || !signal.data["patrol"] || !signal.data["next_patrol"])
		return

	if(!src.next_patrol_id) // we have not yet found a beacon
		var/dist = GET_DIST(get_turf(src.owner),get_turf(signal.source))
		if(nearest_beacon) // try to find a better beacon
			if(dist < nearest_dist)
				src.nearest_beacon = signal.source
				src.nearest_beacon_id = signal.data["beacon"]
				src.nearest_dist = dist
			return
		else // start the 1 second countdown to assigning best found beacon as target
			src.nearest_beacon = signal.source
			src.nearest_beacon_id = signal.data["beacon"]
			src.nearest_dist = dist
			SPAWN(1 SECOND) // nav beacons have a decisecond delay before responding
				src.target = src.nearest_beacon
				src.next_patrol_id = src.nearest_beacon_id
				src.nearest_beacon = null
				src.nearest_beacon_id = null
				src.nearest_dist = null

	else if(signal.data["beacon"] == src.next_patrol_id) // destination reached, or nerd successful
		src.target = signal.source
		src.next_patrol_id = signal.data["next_patrol"]

/datum/aiTask/sequence/patrol/packet_based
	targeting_subtask_type = /datum/aiTask/succeedable/patrol_target_locate/packet_based

/datum/aiTask/succeedable/patrol_target_locate/packet_based
	max_fails = 5 // very generous
	var/packet_sent = FALSE

/datum/aiTask/succeedable/patrol_target_locate/packet_based/on_reset()
	. = ..()
	packet_sent = FALSE

/datum/aiTask/succeedable/patrol_target_locate/packet_based/on_tick()
	. = ..()
	if(!src.packet_sent && istype(src.holder,/datum/aiHolder/patroller/packet_based))
		var/datum/aiHolder/patroller/packet_based/packet_holder = src.holder
		var/datum/signal/signal = get_free_signal()
		signal.source = src.holder.owner
		signal.data["sender"] = packet_holder.net_id
		if(packet_holder.next_patrol_id)
			signal.data["findbeacon"] = packet_holder.next_patrol_id
		else
			signal.data["findbeacon"] = "patrol"
		SEND_SIGNAL(src.holder.owner, COMSIG_MOVABLE_POST_RADIO_PACKET, signal, null, "ai_beacon")
		src.packet_sent = TRUE
