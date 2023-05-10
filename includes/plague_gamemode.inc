#if defined _included_plague_gamemode_
    #endinput
#endif

#define _included_plague_gamemode_

native pr_register_gamemode(sysName[], name[]);
native pr_gamemode_init_choose();
native pr_set_current_gamemode(gamemodeId);
native pr_current_gamemode();
native pr_set_default_gamemode(gamemodeId);

native pr_get_gamemode_system_name(gamemodeId);
native pr_get_gamemode_id(sysName[]);
native pr_get_gamemode_name(gamemodeId);
native pr_gamemode_count();

forward Plague_Choose_Gamemode_Pre(gamemodeId, bool:skip_checks);
forward Plague_Choose_Gamemode_Post(gamemodeId, bool:skip_checks);