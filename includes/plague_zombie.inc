#if defined _included_plague_zombie
    #endinput
#endif

#define _included_plague_zombie

#include <plague_zombie_const>

native bool: pr_is_zombie(id);

native pr_register_zombie(const sysName[], const name[], const model[], const clawmodel[], Array: soundsHurt, Array:soundsSpawn, Array: soundsDie);
native pr_zombie_attributes(race, const hp, const Float:speed, const gravity, const Float:kb, const Float:painshock, const flags);
native pr_zombie_races_count();

native pr_next_available_zombie_race(id);

native pr_get_zombie_users_count(bool: alive);
native pr_set_user_zombie(id, bool: zombie = true, attacker = -1, bool: spawn = true, bool: ignoreFlags = false, bool:health = true);

native pr_set_user_zombie_race(id, race);
native pr_get_user_zombie_race(id);

native pr_set_user_next_zombie_race(id, race);
native pr_get_user_next_zombie_race(id);

native any:pr_get_zombie_race_info(race, ZombieInformation: info, any:...);
native pr_set_zombie_race_info(race, ZombieInformation: info, any:...);

native any:pr_get_zombie_race_attribute(race, ZombieAttributes: attr, any:...);
native pr_set_zombie_race_attribute(race, ZombieAttributes: attr, any:...);

native pr_open_zombies_menu(id);

native pr_apply_zombie_attributes(id, bool:health = true, bool:gravity = true, bool:speed = true);

forward Plague_Zombiefy(id, attacker, oldrace, newrace, bool:spawn);
forward Plague_Zombiefy_Post(id, attacker, oldrace, newrace, bool:spawn);
forward MenuShow: Plague_Zombie_MenuShow(id, race);
forward Plague_Zombie_Selected(id, race);