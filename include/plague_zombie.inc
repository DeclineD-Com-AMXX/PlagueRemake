#if defined _included_plague_zombie_
    #endinput
#endif

#define _included_plague_zombie_

#include <plague_zombie_const>

native pr_register_zombie_race(const szSys[], const szName[], const szModel[], const szClaw[], health, gravity, Float:speed, Float:kb, Float:painshock, Array:dSound, Array:sSound, Array:pSound, flags, MenuShow: menuShow);
native pr_get_zombie_race_count();
native pr_first_available_zombie_race(id);
native pr_get_user_zombie_race(id);
native pr_set_user_zombie_race(id, race, attacker = -1, bool:spawn = true, bool:checkFlags = true, bool:call = true);
native pr_get_user_next_zombie_race(id);
native pr_set_user_next_zombie_race(id, race);
native pr_set_zombie_data(ZombieData:data, race, any:...);
native any:pr_get_zombie_data(ZombieData:data, race, any:...);
native pr_open_zombies_menu(id);
native pr_reset_zombie_attributes(id, bool:bModel = true, bool:bHealth, bool:bGravity, bool:bSpeed);

forward Plague_Zombify(id, attacker);
forward Plague_Zombified(id, attacker);
forward Plague_ShowZombieInMenu(id, race);
forward Plague_ChooseZombieRace(id, race);
forward Plague_ChooseZombieRace_Post(id, race);
forward Plague_Zombies_Loaded();