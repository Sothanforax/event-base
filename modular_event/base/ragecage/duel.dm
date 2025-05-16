/// Datum holding one or multiple participants for a fight
/// When datums in the queue hold 6 participants that could be split 3/3, they're compressed into 2 teams
/// and excess datums are deleted. People can join existing teams by prompting the owner, up to 3 per team.
/datum/duel_group
	/// Participants in the group
	var/list/datum/duel_member/members = list()
	/// Mob who created the group
	var/mob/living/carbon/human/owner = null

/// Stores info about the mob and their belongings, mostly to avoid list jank
/datum/duel_member
	var/mob/living/carbon/human/owner = null
	/// Assoc list of items -> slot/storage item
	var/list/obj/item/belongings = list()

/datum/duel_member/New(mob/living/carbon/human/new_owner)
	. = ..()
	owner = new_owner
	RegisterSignal(owner, COMSIG_QDELETING, PROC_REF(owner_deleted))

/datum/duel_member/Destroy(force)
	owner = null
	belongings.Cut()
	return ..()

/datum/duel_member/proc/owner_deleted()
	SIGNAL_HANDLER
	qdel(src)

/// Track all of mob's equipment so we can give it back to them when they get TPed out
/datum/duel_member/proc/store_equipment()
	for (var/obj/item/thing as anything in owner.get_all_gear())
		if (thing.loc == owner)
			belongings[thing] = owner.get_slot_by_item(thing)
		else
			belongings[thing] = thing.loc
		RegisterSignal(thing, COMSIG_QDELETING, PROC_REF(on_delete))

/datum/duel_member/proc/on_delete(obj/item/deleted)
	SIGNAL_HANDLER
	belongings -= deleted

/// Return all of mob's equipment and delete whatever doesn't fit into them
/datum/duel_member/proc/return_equipment()
	for (var/obj/item/thing as anything in belongings)
		if (!isatom(belongings[thing]))
			owner.equip_to_slot_or_del(thing, belongings[thing])
			continue

		var/atom/storage = belongings[thing]
		if (!storage.atom_storage?.attempt_insert(thing, null, TRUE, STORAGE_FULLY_LOCKED, FALSE))
			qdel(thing) // don't steal others' stuff

	belongings.Cut()

/datum/arena_duel
	// Two participating groups
	var/datum/duel_group/first_group = null
	var/datum/duel_group/second_group = null

/datum/arena_duel/proc/start_fight()
	var/list/obj/effect/landmark/ragecage/first_team = list()
	var/list/obj/effect/landmark/ragecage/second_team = list()
	for (var/obj/effect/landmark/ragecage/mark in GLOB.landmarks_list)
		if (mark.index == ARENA_FIRST_FIGHTER)
			first_team += mark
		else
			second_team += mark

	for (var/datum/duel_member/member as anything in first_group.members)
		var/landmark = pick_n_take(first_team)
		if (!landmark)
			stack_trace("Arena duel was unable to find enough first team landmarks for a duel!")
			break
		member.start_duel(src, landmark)

	for (var/datum/duel_member/member as anything in second_group.members)
		var/landmark = pick_n_take(second_team)
		if (!landmark)
			stack_trace("Arena duel was unable to find enough second team landmarks for a duel!")
			break
		member.start_duel(src, landmark)

/// Called whenever a duelant dies, check if there are any other living duelants from the same team and if not, ends the fight
/// Not using a num tracker because this is barely called and tracking revives is just a pain in the ass
/datum/arena_duel/proc/duelant_death(datum/duel_member/just_died)
	var/datum/duel_group/loser_team = null
	if (just_died in first_group.members)
		loser_team = first_group
	else if (just_died in second_group.members)
		loser_team = second_group

	// Just in case
	if (!loser_team)
		return
