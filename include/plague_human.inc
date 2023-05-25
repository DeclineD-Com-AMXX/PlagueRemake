#if defined _included_plague_human_
    #endinput
#endif

#define _included_plague_human_

#include <plague_human_const>

native pr_register_human_race(const szSys[], const szName[], const szModel[], health, armor, gravity, Float:speed, Float:painshock, Array:dSound, Array:pSound, MenuShow:menuShow, flags);

native pr_get_human_race_count();

native pr_first_available_human_race(id);

native pr_get_user_human_race(id);
native pr_set_user_human_race(id, race, attacker = -1, bool:spawn = true, bool:checkFlags = true, bool:call = true);

native pr_get_user_next_human_race(id);
native pr_set_user_next_human_race(id, race);

native pr_set_user_infection_type(id, InfectionType:type);
native InfectionType:pr_get_user_infection_type(id);

native pr_set_human_data(HumanData:data, race, any:...);
native any:pr_get_human_data(HumanData:data, race, any:...);

native pr_open_humans_menu(id);

native pr_reset_human_attributes(id, bool:bModel = true, bool:bHealth = true, bool:bArmor = true, bool:bGravity = true, bool:bSpeed = true);

forward Plague_Humanize(id, attacker);
forward Plague_Humanize_Post(id, attacker);
forward Plague_ShowHumanInMenu(id, race);
forward Plague_ChooseHumanRace(id, race);
forward Plague_ChooseHumanRace_Post(id, race);
forward Plague_Humans_Loaded();