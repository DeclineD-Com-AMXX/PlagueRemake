#if defined _included_plague_human
    #endinput
#endif

#define _included_plague_human

#include <plague_human_const>

native bool: pr_is_human(id);

native pr_register_human(const sysName[], const name[], const model[], Array: soundsHurt, Array: soundsDie);
native pr_human_attributes(race, const hp, const Float:speed, const gravity, const Float:painshock, const flags);
native pr_human_races_count();

native pr_next_available_human_race(id);

native pr_get_human_users_count(bool: alive);
native pr_set_user_human(id, bool: human = true, attacker = -1, bool: spawn = true, bool: ignoreFlags = false, bool:health = true);

native pr_set_user_human_race(id, race);
native pr_get_user_human_race(id);

native pr_set_user_next_human_race(id, race);
native pr_get_user_next_human_race(id);

native any:pr_get_human_race_info(race, HumanInformation: info, any:...);
native pr_set_human_race_info(race, HumanInformation: info, any:...);

native any:pr_get_human_race_attribute(race, HumanAttributes: attr, any:...);
native pr_set_human_race_attribute(race, HumanAttributes: attr, any:...);

native pr_open_humans_menu(id);

native pr_apply_human_attributes(id, bool:health = true, bool:gravity = true, bool:speed = true);

forward Plague_Humanize(id, attacker, oldrace, race, bool:spawn);
forward Plague_Humanize_Post(id, attacker, oldrace, race, bool:spawn);
forward MenuShow: Plague_Human_MenuShow(id, race);
forward Plague_Human_Selected(id, race);