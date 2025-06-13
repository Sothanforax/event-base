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

			trios += new /datum/duel_group(user, src, params["join_random"])
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
	if (prob(50))
		if (!check_duel())
			check_trio()
	else if (!check_trio())
		check_duel()

/obj/machinery/computer/ragecage_signup/proc/check_duel()
	if (length(duels) < 2)
		return FALSE

	new /datum/arena_duel(src, duels[1], duels[2])
	duels.Cut(1, 3)
	return TRUE

/obj/machinery/computer/ragecage_signup/proc/check_trio()
	var/datum/duel_group/first_best = null
	var/datum/duel_group/second_best = null
	for (var/datum/duel_group/group as anything in trios)
		if (length(group.members) > length(first_best?.members) || (length(group.members) == length(first_best?.members) && !first_best.join_random && group.join_random))
			second_best = first_best
			first_best = group
		else if (length(group.members) > length(second_best?.members) || (length(group.members) == length(second_best?.members) && !second_best.join_random && group.join_random))
			second_best = group

	if (!first_best || !second_best)
		return FALSE

	if (length(first_best.members) == 3 && length(second_best.members) == 3)
		var/datum/arena_duel/duel = new(src, first_best, second_best)
		return TRUE

	if (length(first_best.members) < 3 && !first_best.join_random)
		first_best = null
		for (var/datum/duel_group/group as anything in (trios - second_best))
			if (length(group.members) > length(first_best?.members) && group.join_random)
				first_best = group

	if (length(second_best.members) < 3 && !second_best.join_random)
		second_best = null
		for (var/datum/duel_group/group as anything in (trios - first_best))
			if (length(group.members) > length(second_best?.members) && group.join_random)
				second_best = group

	if (!first_best || !second_best)
		return FALSE

	var/list/datum/duel_group/first_merge = list()
	var/list/datum/duel_group/second_merge = list()
	var/first_miss = 3 - length(first_best.members)
	var/second_miss = 3 - length(second_best.members)

	for (var/datum/duel_group/group as anything in (trios - first_best - second_best))
		if (!group.join_random)
			continue

		if (length(group.members) <= first_miss)
			first_merge += group
			first_miss -= length(group.members)
		else if (length(group.members) <= second_miss)
			second_merge += group
			second_miss -= length(group.members)

	if (first_miss || second_miss)
		return FALSE

	for (var/datum/duel_group/group as anything in first_merge)
		first_best.members += group.members
		group.members.Cut()
		qdel(group)

	for (var/datum/duel_group/group as anything in second_merge)
		second_best.members += group.members
		group.members.Cut()
		qdel(group)

	var/datum/arena_duel/duel = new(src, first_best, second_best)
	duels -= first_best
	duels -= second_best
	return TRUE

