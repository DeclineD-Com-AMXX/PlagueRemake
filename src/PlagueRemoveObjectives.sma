#include <amxmodx>
#include <fakemeta>

new g_BlockedObj_Forward
new g_BlockedObj[][] =
{
    "func_bomb_target",
    "info_bomb_target",
    "info_vip_start",
    "func_vip_safetyzone",
    "func_escapezone",
    "hostage_entity",
    "monster_scientist",
    "func_hostage_rescue",
    "info_hostage_rescue",
    "item_longjump",
    "func_vehicle"
}

public plugin_precache() g_BlockedObj_Forward = register_forward(FM_Spawn, "SpawnObjective");
public plugin_init() unregister_forward(FM_Spawn, g_BlockedObj_Forward);

public SpawnObjective(ent)
{
    new szClassmenu[32]; pev(ent, pev_classname, szClassmenu, charsmax(szClassmenu));

    for(new i = 0; i < sizeof g_BlockedObj; i++)
    {
        if (equal(szClassmenu, g_BlockedObj[i]))
            return FMRES_SUPERCEDE;
    }

    return FMRES_IGNORED;
}