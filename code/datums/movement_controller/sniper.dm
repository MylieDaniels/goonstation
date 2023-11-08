/datum/movement_controller/sniperscope
	var/input_x = 0
	var/input_y = 0
	var/speed = 12
	var/delay = 1

	New(speed = 12)
		..()
		src.speed = speed

	keys_changed(mob/owner, keys, changed)
		if (changed & (KEY_FORWARD|KEY_BACKWARD|KEY_RIGHT|KEY_LEFT|KEY_RUN))
			if (ishuman(owner))

				input_x = 0
				input_y = 0
				if (keys & KEY_FORWARD)
					input_y += 1
				if (keys & KEY_BACKWARD)
					input_y -= 1
				if (keys & KEY_RIGHT)
					input_x += 1
				if (keys & KEY_LEFT)
					input_x -= 1

				//normalized vector
				var/input_magnitude = vector_magnitude(input_x, input_y)
				if (input_magnitude)
					input_x /= input_magnitude
					input_y /= input_magnitude

					attempt_move(owner)

	process_move(mob/owner, keys)
		if (owner.client)
			owner.client.pixel_x += input_x * speed
			owner.client.pixel_y += input_y * speed

			animate(owner.client, pixel_x = owner.client.pixel_x + input_x * speed, pixel_y = owner.client.pixel_y + input_y * speed, time = delay, flags = ANIMATION_END_NOW)

		return 0.5

/// SNIPER SCOPE COMPONENT - when shift is held, overlay a reticle on the screen and movement of the player is cancelled and turned into movement of the screen
TYPEINFO(/datum/component/holdertargeting/sniperscope)
	initialization_args = list(
		ARG_INFO("speed", DATA_INPUT_NUM, "Scope movement per tick (in pixels)", 12),
		ARG_INFO("scopetype", DATA_INPUT_TYPE, "Type of the scope overlay", /datum/overlayComposition/sniper_scope),
	)

/datum/component/holdertargeting/sniperscope
	dupe_mode = COMPONENT_DUPE_HIGHLANDER
	mobtype = /mob/living
	var/speed = 12
	var/scoped = FALSE
	var/datum/overlayComposition/scopetype = /datum/overlayComposition/sniper_scope
	var/client/aimer
	var/datum/movement_controller/sniperscope/movement_controller

	Initialize(speed = 12, datum/overlayComposition/scopetype = /datum/overlayComposition/sniper_scope)
		if(..() == COMPONENT_INCOMPATIBLE || !isitem(parent))
			return COMPONENT_INCOMPATIBLE
		else
			var/obj/item/I = parent
			src.speed = speed
			src.scopetype = scopetype
			src.movement_controller = new(src.speed)

			RegisterSignal(I, COMSIG_ITEM_SWAP_TO, PROC_REF(init_scope_mode))
			RegisterSignal(I, COMSIG_ITEM_SWAP_AWAY, PROC_REF(end_scope_mode))
			if(ismob(I.loc))
				on_pickup(null, I.loc)

	UnregisterFromParent()
		aimer = null
		. = ..()

	on_pickup(datum/source, mob/user)
		. = ..()
		if(user.equipped() == parent)
			init_scope_mode(source, user)

	on_dropped(datum/source, mob/user)
		end_scope_mode(source, user)
		. = ..()

/datum/component/holdertargeting/sniperscope/proc/init_scope_mode(datum/source, mob/user) // they are holding the gun
	RegisterSignal(user, COMSIG_MOB_SPRINT, PROC_REF(toggle_scope))

/datum/component/holdertargeting/sniperscope/proc/end_scope_mode(datum/source, mob/user) // they are no longer holding the gun
	UnregisterSignal(user, COMSIG_MOB_SPRINT)
	src.stop_sniping(user)

/datum/component/holdertargeting/sniperscope/proc/toggle_scope(mob/user)
	if(scoped)
		src.stop_sniping(user)
	else
		src.begin_sniping(user)
	scoped = !scoped

/datum/component/holdertargeting/sniperscope/proc/begin_sniping(mob/user) // add overlay + sound here
	user.override_movement_controller = src.movement_controller
	user.keys_changed(0,0xFFFF)
	if(!user.hasOverlayComposition(src.scopetype))
		user.addOverlayComposition(src.scopetype)
	playsound(user, 'sound/weapons/scope.ogg', 50, TRUE)

/datum/component/holdertargeting/sniperscope/proc/stop_sniping(mob/user) // remove overlay and reset vision here
	user.override_movement_controller = null
	if (user.client)
		user.client.pixel_x = 0
		user.client.pixel_y = 0
		user.keys_changed(0,0xFFFF)

	user.removeOverlayComposition(src.scopetype)
