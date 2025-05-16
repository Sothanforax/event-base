/obj/machinery/computer/ragecage_signup
	name = "arena signup console"
	desc = "A console that lets you sign up to participate in rage cage fights. Supports duels and three on threes."
	icon_screen = "tram"
	icon_keyboard = "atmos_key"
	light_color = LIGHT_COLOR_CYAN
	/// List of participants signed up for duels, once we have a spot the first two participants are taken from the list and sent to fight
	var/list/datum/duel_member/duels = list()
	/// List of trio participant groups
	var/list/datum/duel_group/trios = list()
	/// Currently active duel datum
	var/datum/arena_duel/active_duel = null
