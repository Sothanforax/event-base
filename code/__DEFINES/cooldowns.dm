//// COOLDOWN SYSTEMS
/*
 * We have 2 cooldown systems: timer cooldowns (divided between stoppable and regular) and world.time cooldowns.
 *
 * When to use each?
 *
 * * Adding a commonly-checked cooldown, like on a subsystem to check for processing
 * * * Use the world.time ones, as they are cheaper.
 *
 * * Adding a rarely-used one for special situations, such as giving an uncommon item a cooldown on a target.
 * * * Timer cooldown, as adding a new variable on each mob to track the cooldown of said uncommon item is going too far.
 *
 * * Triggering events at the end of a cooldown.
 * * * Timer cooldown, registering to its signal.
 *
 * * Being able to check how long left for the cooldown to end.
 * * * Either world.time or stoppable timer cooldowns, depending on the other factors. Regular timer cooldowns do not support this.
 *
 * * Being able to stop the timer before it ends.
 * * * Either world.time or stoppable timer cooldowns, depending on the other factors. Regular timer cooldowns do not support this.
*/


/*
 * Cooldown system based on an datum-level associative lazylist using timers.
*/

//INDEXES
#define COOLDOWN_BORG_SELF_REPAIR "borg_self_repair"
#define COOLDOWN_EXPRESSPOD_CONSOLE "expresspod_console"

//Mecha cooldowns
#define COOLDOWN_MECHA_MESSAGE "mecha_message"
#define COOLDOWN_MECHA_EQUIPMENT(type) ("mecha_equip_[type]")
#define COOLDOWN_MECHA_MELEE_ATTACK "mecha_melee"
#define COOLDOWN_MECHA_SMOKE "mecha_smoke"
#define COOLDOWN_MECHA_SKYFALL "mecha_skyfall"
#define COOLDOWN_MECHA_MISSILE_STRIKE "mecha_missile_strike"
#define COOLDOWN_MECHA_CABIN_SEAL "mecha_cabin_seal"

//skybulge cooldown
#define COOLDOWN_SKYBULGE_JUMP "skybulge_jump"

//car cooldowns
#define COOLDOWN_CAR_HONK "car_honk"

//clown car cooldowns
#define COOLDOWN_CLOWNCAR_RANDOMNESS "clown_car_randomness"

// item cooldowns
#define COOLDOWN_SIGNALLER_SEND "cooldown_signaller_send"
#define COOLDOWN_TOOL_SOUND "cooldown_tool_sound"

//circuit cooldowns
#define COOLDOWN_CIRCUIT_SOUNDEMITTER "circuit_soundemitter"
#define COOLDOWN_CIRCUIT_SPEECH "circuit_speech"
#define COOLDOWN_CIRCUIT_PATHFIND_SAME "circuit_pathfind_same"
#define COOLDOWN_CIRCUIT_PATHFIND_DIF "circuit_pathfind_different"
#define COOLDOWN_CIRCUIT_TARGET_INTERCEPT "circuit_target_intercept"
#define COOLDOWN_CIRCUIT_VIEW_SENSOR "circuit_view_sensor"

// mob cooldowns
#define COOLDOWN_YAWN_PROPAGATION "yawn_propagation_cooldown"

#define COOLDOWN_ARENA_SIGNUP_REQUEST "arena_signup_request"

//Shared cooldowns for actions
#define MOB_SHARED_COOLDOWN_1 (1<<0)
#define MOB_SHARED_COOLDOWN_2 (1<<1)
#define MOB_SHARED_COOLDOWN_3 (1<<2)
#define MOB_SHARED_COOLDOWN_BOT_ANNOUNCMENT (1<<3)

//TIMER COOLDOWN MACROS

#define COMSIG_CD_STOP(cd_index) "cooldown_[cd_index]"
#define COMSIG_CD_RESET(cd_index) "cd_reset_[cd_index]"

#define TIMER_COOLDOWN_START(cd_source, cd_index, cd_time) LAZYSET(cd_source.cooldowns, cd_index, addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(end_cooldown), cd_source, cd_index), cd_time))

/// Checks if a timer based cooldown is NOT finished.
#define TIMER_COOLDOWN_RUNNING(cd_source, cd_index) LAZYACCESS(cd_source.cooldowns, cd_index)

/// Checks if a timer based cooldown is finished.
#define TIMER_COOLDOWN_FINISHED(cd_source, cd_index) (!TIMER_COOLDOWN_RUNNING(cd_source, cd_index))

#define TIMER_COOLDOWN_END(cd_source, cd_index) LAZYREMOVE(cd_source.cooldowns, cd_index)

/*
 * Stoppable timer cooldowns.
 * Use indexes the same as the regular tiemr cooldowns.
 * They make use of the TIMER_COOLDOWN_RUNNING() and TIMER_COOLDOWN_END() macros the same, just not the TIMER_COOLDOWN_START() one.
 * A bit more expensive than the regular timers, but can be reset before they end and the time left can be checked.
*/

#define S_TIMER_COOLDOWN_START(cd_source, cd_index, cd_time) LAZYSET(cd_source.cooldowns, cd_index, addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(end_cooldown), cd_source, cd_index), cd_time, TIMER_STOPPABLE))

#define S_TIMER_COOLDOWN_RESET(cd_source, cd_index) reset_cooldown(cd_source, cd_index)

#define S_TIMER_COOLDOWN_TIMELEFT(cd_source, cd_index) (timeleft(TIMER_COOLDOWN_RUNNING(cd_source, cd_index)))


/*
 * Cooldown system based on storing world.time on a variable, plus the cooldown time.
 * Better performance over timer cooldowns, lower control. Same functionality.
*/

#define COOLDOWN_DECLARE(cd_index) var/##cd_index = 0

#define STATIC_COOLDOWN_DECLARE(cd_index) var/static/##cd_index = 0

#define COOLDOWN_START(cd_source, cd_index, cd_time) (cd_source.cd_index = world.time + (cd_time))

//Returns true if the cooldown has run its course, false otherwise
#define COOLDOWN_FINISHED(cd_source, cd_index) (cd_source.cd_index <= world.time)

#define COOLDOWN_RESET(cd_source, cd_index) cd_source.cd_index = 0

#define COOLDOWN_STARTED(cd_source, cd_index) (cd_source.cd_index != 0)

#define COOLDOWN_TIMELEFT(cd_source, cd_index) (max(0, cd_source.cd_index - world.time))

///adds to existing cooldown timer if its started, otherwise starts anew
#define COOLDOWN_INCREMENT(cd_source, cd_index, cd_increment) \
	if(COOLDOWN_FINISHED(cd_source, cd_index)) { \
		COOLDOWN_START(cd_source, cd_index, cd_increment); \
		return; \
	} \
	cd_source.cd_index += (cd_increment); \

/*
 * Same as the above cooldown system, but uses REALTIMEOFDAY
 * Primarily only used for times that need to be tracked with the client, such as sound or animations
*/

#define CLIENT_COOLDOWN_DECLARE(cd_index) var/##cd_index = 0

#define CLIENT_STATIC_COOLDOWN_DECLARE(cd_index) var/static/##cd_index = 0

#define CLIENT_COOLDOWN_START(cd_source, cd_index, cd_time) (cd_source.cd_index = REALTIMEOFDAY + (cd_time))

//Returns true if the cooldown has run its course, false otherwise
#define CLIENT_COOLDOWN_FINISHED(cd_source, cd_index) (cd_source.cd_index <= REALTIMEOFDAY)

#define CLIENT_COOLDOWN_RESET(cd_source, cd_index) cd_source.cd_index = 0

#define CLIENT_COOLDOWN_STARTED(cd_source, cd_index) (cd_source.cd_index != 0)

#define CLIENT_COOLDOWN_TIMELEFT(cd_source, cd_index) (max(0, cd_source.cd_index - REALTIMEOFDAY))
