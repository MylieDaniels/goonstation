// ----------------------------------------- //
//            THE PELLET COLLIDER
// ----------------------------------------- //
#define COLLIDER_DELAY_SCALAR 15
#define COLLIDER_DELAY_BASE 5
#define COLLIDER_SPIN_HAZARD 500

/obj/pellet_collider_pipe
	icon = 'icons/obj/power_cond.dmi'
	icon_state = "1-2"
	name = "collider tube"
	desc = "A section of shielded tubing to rapidly accelerate regulation-compliant pellets of koshmarite."
	anchored = UNANCHORED
	density = TRUE
	HELP_MESSAGE_OVERRIDE({"Click-drag anything into the collider tube, and the direction into it will change to that direction.
		Click-drag the collider tube to anything, and the direction out of it will change to that direction."})

	var/dir_in = SOUTH
	var/dir_out = NORTH
	var/max_health = 20
	var/health = 20
	var/datum/pellet_collider_pellet/pellet = null

	disposing()
		if(pellet)
			pipe_breach(get_turf(src), turn(dir_in, 180))
		..()

	proc/get_next_pipe(var/turf/T)
		if(!T)
			return null

		for(var/obj/pellet_collider_pipe/P in T)
			if(src.dir_out == turn(P.dir_in, 180))
				return P
		return null

	proc/transfer()
		var/turf/next_turf = get_step(src,dir_out)
		var/obj/pellet_collider_pipe/next_pipe = src.get_next_pipe(next_turf)

		if(next_pipe)
			. = pellet.step_into(next_pipe)
			pellet = null
		else
			pipe_breach(pellet, next_turf, turn(dir_in, 180))
			return FALSE

	proc/pipe_breach(var/turf/T, var/direction)
		pellet.pellet_breach()
		pellet.location = null
		pellet = null

	proc/check_health()
		if(health <= 0)
			. = FALSE
			qdel(src)
		return TRUE

	proc/take_damage(var/damage)
		health -= damage
		return check_health()

	mouse_drop(over_object, src_location, over_location)
		if (!usr)
			return

		if (over_object == src || src_location == over_location)
			return ..()

		if (BOUNDS_DIST(src, usr))
			usr.show_text("You are too far away to do that!", "red")
			return
		else
			var/dir_target_atom = get_dir(src_location, over_location)

			if (dir_target_atom == src.dir_in) // Swap directions if the player is trying to set the same direction to both directions.
				src.dir_in = dir_out
			src.dir_out = dir_target_atom
			src.update_icon()
			return

	MouseDrop_T(dropped, user, src_location, over_location)
		if (!user)
			return
		if (dropped == src || src_location == over_location)
			return

		if (BOUNDS_DIST(src, user))
			usr.show_text("You are too far away to do that!", "red")
			return ..()
		else
			var/dir_target_atom = get_dir(over_location, src_location)

			if (dir_target_atom == src.dir_out)
				src.dir_out = src.dir_in
			src.dir_in = dir_target_atom
			src.update_icon()
			return

	proc/get_welding_positions()
		var/start = list(0, 0)
		var/stop = list(0, 0)

		if(dir_in & SOUTH)
			start[2] = -14
		else if(dir_in & NORTH)
			start[2] = 14
		if(dir_in & EAST)
			start[1] = 14
		else if(dir_in & WEST)
			start[1] = -14

		if(dir_out & SOUTH)
			stop[2] = -14
		else if(dir_out & NORTH)
			stop[2] = 14
		if(dir_out & EAST)
			stop[1] = 14
		else if(dir_out & WEST)
			stop[1] = -14

		if(prob(50))
			. = list(start, stop)
		else
			. = list(stop, start)

	proc/repair_pipe()
		src.health = src.max_health

	attackby(obj/item/W, mob/user, params, is_special = 0, silent = FALSE)
		if (iswrenchingtool(W))
			if(src.anchored == ANCHORED)
				playsound(src.loc, 'sound/items/Ratchet.ogg', 75, 1)
				boutput(user, "You loosen the external reinforcing bolts from the floor.")
				src.anchored = UNANCHORED
			else if(src.anchored == UNANCHORED)
				playsound(src.loc, 'sound/items/Ratchet.ogg', 75, 1)
				boutput(user, "You secure the external reinforcing bolts to the floor.")
				src.anchored = ANCHORED
			return
		else if (isweldingtool(W))
			if(src.health == src.max_health)
				boutput(user, "\The [src.name] is already in perfect condition.")
				return

			if(!W:try_weld(user, 0.8, noisy=2))
				return

			boutput(user, "You start to repair \the [src.name].")

			var/positions = src.get_welding_positions()
			actions.start(new /datum/action/bar/private/welding(user, src, 1.2 SECONDS, /obj/pellet_collider_pipe/proc/repair_pipe, \
					list(user), SPAN_NOTICE("[user] repairs \the [src.name]."), positions[1], positions[2]),user)
			return
		..()

	update_icon()
		icon_state = "[min(dir_in,dir_out)]-[max(dir_in,dir_out)]"

	proc/debug_start_pellet()
		if(pellet)
			return

		pellet = new/datum/pellet_collider_pellet()
		pellet.start(src)

/datum/pellet_collider_pellet
	var/obj/pellet_collider_pipe/location = null
	var/spin = 0
	var/density = 5
	var/ramp = 0
	var/hop_length = 1
	var/steps_taken = 0
	var/delay = COLLIDER_DELAY_BASE

	disposing()
		if(location)
			location.pellet = null
			location = null
		..()

	proc/step_into(var/obj/pellet_collider_pipe/new_location)
		steps_taken++
		location = new_location
		location.pellet = src
		var/spin_hazard = clamp(round(spin * 100 / COLLIDER_SPIN_HAZARD) - 20, 0, 80)
		location.obj_speak("[steps_taken]: [spin]")
		if(prob(spin_hazard))
			animate_storage_thump(location, round(spin_hazard / 20))
			location.take_damage(1 + round(spin / COLLIDER_SPIN_HAZARD))
		if(prob(spin_hazard / 2))
			SPAWN(rand(8,45))
				animate_storage_thump(location, round(spin_hazard / 25))
		return location

	proc/pellet_breach()
		var/turf/breach_turf = get_turf(location)
		if(!breach_turf)
			qdel(src)
			return
		elecflash(breach_turf,1,1,FALSE)
		qdel(src)

	proc/start(var/obj/pellet_collider_pipe/start_location)
		if(!start_location)
			return
		location = start_location
		SPAWN(delay)
			process()

	proc/process()
		while(steps_taken < 100000)
			for(var/i=1 to hop_length)
				if(!location || !location.transfer())
					break

				var/spin_increase = abs(dir_to_angle(location.dir_out) - dir_to_angle(location.dir_in))
				spin_increase = min(spin_increase, 360 - spin_increase)
				spin_increase = 2 * ((180 - spin_increase) / 45) ** 2
				spin += spin_increase

			if(!location)
				break
			ramp += delay
			spin = max(0,spin - delay)

			if(delay > 1)
				while(ramp >= (COLLIDER_DELAY_SCALAR * COLLIDER_DELAY_BASE / delay))
					ramp -= (COLLIDER_DELAY_SCALAR * COLLIDER_DELAY_BASE / delay)
					delay -= 1
			else if (ramp >= (COLLIDER_DELAY_BASE * COLLIDER_DELAY_SCALAR * hop_length))
				hop_length += 1
				ramp = 0
			sleep(delay)
		qdel(src)
