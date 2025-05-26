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
	. = ..()
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "RagecageConsole", name)
		ui.open()

/obj/machinery/computer/ragecage_signup/ui_data(mob/user)
	var/list/data = list("duelSigned" = FALSE, "trioSigned" = FALSE)
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

			if (user == member.owner)
				data["duelSigned"] = TRUE

		var/list/duel_group = list("members" = group_members, "canJoin" = FALSE)
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

			if (user == member.owner)
				data["trioSigned"] = TRUE

		var/list/duel_group = list("members" = group_members, "group" = REF(group), "canJoin" = (length(group_members) < 3 && group.owner != user && !group.active_duel))
		trio_data += list(duel_group)
		if (active_duel?.first_group == group)
			active_data["firstTeam"] = duel_group
		else if (active_duel?.second_group == group)
			active_data["secondTeam"] = duel_group

	data["trioTeams"] = trio_data
	data["joinRequestCooldown"] = TIMER_COOLDOWN_RUNNING(user, COOLDOWN_ARENA_SIGNUP_REQUEST)

	if (length(active_data))
		data["activeDuel"] = active_data
	return data

/obj/machinery/computer/ragecage_signup/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	var/mob/living/carbon/human/user = ui.user
	if (!istype(user))
		return

	var/datum/duel_group/duel = null
	var/datum/duel_group/trio = null

	for (var/datum/duel_group/group as anything in duels)
		for (var/datum/duel_member/member as anything in group.members)
			if (member.owner == user)
				duel = group
				break
		if (duel)
			break

	for (var/datum/duel_group/group as anything in trios)
		for (var/datum/duel_member/member as anything in group.members)
			if (member.owner == user)
				trio = group
				break
		if (trio)
			break

	switch(action)
		if ("duel_signup")
			if (duel)
				to_chat(user, span_alert("You've already signed up for a duel!"))
				return

			duels += new /datum/duel_group(user, src)
			check_matches()

		if ("trio_signup")
			if (trio)
				to_chat(user, span_alert("You've already signed up for a three on three fight!"))
				return

			trios += new /datum/duel_group(user, src)
			check_matches()

		if ("duel_drop")
			if (!duel)
				to_chat(user, span_alert("You're not signed up for a duel!"))
				return

			if (duel.active_duel)
				to_chat(user, span_alert("You can't drop out mid-fight!"))
			else
				qdel(duel)

		if ("trio_drop")
			if (!trio)
				to_chat(user, span_alert("You're not signed up for a three on three fight!"))
				return

			if (trio.active_duel)
				to_chat(user, span_alert("You can't drop out mid-fight!"))
			else
				qdel(trio)

		if ("request_join")
			if (trio)
				to_chat(user, span_alert("You cannot join another team while already signed up!"))
				return

			var/datum/duel_group/group = locate(params["ref"]) in trios
			if (!group || TIMER_COOLDOWN_RUNNING(user, COOLDOWN_ARENA_SIGNUP_REQUEST) || length(group.members) >= 3 || group.active_duel)
				return

			TIMER_COOLDOWN_START(user, COOLDOWN_ARENA_SIGNUP_REQUEST, 60 SECONDS)
			tgui_alert(user, "Awaiting [group.owner.real_name]'s response to your request", "Team Join Request")
			var/choice = tgui_alert(user, "[user.real_name] is requesting to join your arena team. Do you accept their request?", "Team Join Request", list("Yes", "No"), timeout = 60 SECONDS)

			if (QDELETED(user))
				return

			if (choice != "Yes" || QDELETED(group) || QDELETED(group.owner))
				to_chat(user, span_alert("Your request to join [group.owner.real_name]'s team was rejected."))
				return

			for (var/datum/duel_group/trio_group as anything in trios)
				for (var/datum/duel_member/member as anything in trio_group.members)
					if (member.owner == user)
						trio = trio_group
						break
				if (trio)
					break

			if (TIMER_COOLDOWN_RUNNING(user, COOLDOWN_ARENA_SIGNUP_REQUEST) || length(group.members) >= 3 || group.active_duel || trio)
				to_chat(user, span_alert("You can no longer join [group.owner.real_name]'s team."))
				return

			to_chat(user, span_notice("You've been added to [group.owner.real_name]'s team."))
			group.members += new /datum/duel_member(user, group)
			check_matches()

/obj/machinery/computer/ragecage_signup/proc/check_matches()
	return
