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

/obj/machinery/computer/ragecage_signup
	name = "arena signup console"
	desc = "A console that lets you sign up to participate in rage cage fights. Supports duels and three on threes."
	icon_screen = "tram"
	icon_keyboard = "atmos_key"
	light_color = LIGHT_COLOR_CYAN
	/// List of participants signed up for duels, once we have a spot the first two participants are taken from the list and sent to fight
	var/list/datum/duel_group/duels = list()
	/// List of trio participant groups
	var/list/datum/duel_group/trios = list()
	/// Currently active duel datum
	var/datum/arena_duel/active_duel = null

/obj/machinery/computer/ragecage_signup/Destroy(force)
	. = ..()
	QDEL_LIST(duels)
	QDEL_LIST(trios)
	if (active_duel)
		active_duel.end_fight()
		QDEL_NULL(active_duel)

/obj/machinery/computer/ragecage_signup/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "RagecageConsole", name)
		ui.open()

/obj/machinery/computer/ragecage_signup/ui_data(mob/user)
	var/list/data = list()
	var/list/active_data = list()

	var/list/duel_data = list()
	for (var/datum/duel_group/group as anything in duels)
		var/list/group_members = list()
		for (var/datum/duel_member/member as anything in group.members)
			group_members += list(list(
				"name" = member.owner.real_name,
				"dead" = member.owner.stat == DEAD,
				"owner" = group.owner == member.owner,
			))
		var/list/duel_group = list("members" = group_members)
		duel_data += list(duel_group)
		if (active_duel?.first_group == group)
			active_data["firstTeam"] = duel_group
		else if (active_duel?.second_group == group)
			active_data["secondTeam"] = duel_group

	data["duelTeams"] = duel_data

	var/list/trio_data = list()
	for (var/datum/duel_group/group as anything in trios)
		var/list/group_members = list()
		for (var/datum/duel_member/member as anything in group.members)
			group_members += list(list(
				"name" = member.owner.real_name,
				"dead" = member.owner.stat == DEAD,
				"owner" = group.owner == member.owner,
			))
		var/list/duel_group = list("members" = group_members)
		trio_data += list(duel_group)
		if (active_duel?.first_group == group)
			active_data["firstTeam"] = duel_group
		else if (active_duel?.second_group == group)
			active_data["secondTeam"] = duel_group

	data["trioTeams"] = trio_data
	if (length(active_data))
		data["activeDuel"] = active_data
	return data
