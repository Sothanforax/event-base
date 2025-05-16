/// Plant these for first and second fighters or groups, 3 of each should be present
/obj/effect/landmark/ragecage
	name = "ragecage first fighter spawn"
	var/index = ARENA_FIRST_FIGHTER

/obj/effect/landmark/ragecage/second
	name = "ragecage second fighter spawn"
	index = ARENA_SECOND_FIGHTER

/// Landmark to which participants will be teleported after finishing the fight, at least 6 should be present
/obj/effect/landmark/ragecage_exit
	name = "ragecage exit"
