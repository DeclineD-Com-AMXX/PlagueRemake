#if defined _included_plague_gamemode_
    #endinput
#endif

#define _included_plague_gamemode_

native pr_register_gamemode(sysName[], name[], InfectionType:infType);
native pr_gamemode_init_choose();
native pr_set_current_gamemode(gamemodeId);
native pr_current_gamemode();
native pr_set_default_gamemode(gamemodeId);

native pr_get_gamemode_system_name(gamemodeId);
native pr_get_gamemode_id(sysName[]);
native pr_get_gamemode_name(gamemodeId);
native pr_gamemode_count();

native pr_transform_chosen_players(PlagueClassId:id);
native pr_init_choose_transform(num);
native pr_get_chosen_list(players[MAX_PLAYERS], &count);
native pr_set_chosen_list(players[MAX_PLAYERS], count);

forward Plague_Chosen_Pre(id);
forward Plague_Chosen_Post(id);

forward Plague_Choose_Gamemode_Pre(gamemodeId, bool:skip_checks);
forward Plague_Choose_Gamemode_Post(gamemodeId, bool:skip_checks);