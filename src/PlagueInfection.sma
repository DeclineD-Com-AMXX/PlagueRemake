#include <amxmodx>
#include <reapi>

#include <plague_zombie>
#include <plague_rounds>
#include <plague_infection_const>
#include <plague_const>

/* -> Plugin Information <- */
new const pluginName[ ] = "[Plague] Infection Management";
new const pluginVer[ ] = "v1.0";
new const pluginAuthor[ ] = "DeclineD";

new InfectionType:gInfectionType;
new Float:g_flArmorProtection[MAX_PLAYERS + 1];
new Float:g_flArmorDamage[MAX_PLAYERS + 1];

new fwdSetArmorProtPre, fwdSetArmorProtPost;
new fwdSetArmorDmgPre, fwdSetArmorDmgPost;
new fwdArmorHurtPre, fwdArmorHurtPost;

public plugin_precache()
{
    fwdSetArmorProtPre = CreateMultiForward("Plague_SetArmorProtection_Pre", ET_CONTINUE, FP_CELL, FP_CELL);
    fwdSetArmorProtPost = CreateMultiForward("Plague_SetArmorProtection_Post", ET_IGNORE, FP_CELL, FP_CELL);
    fwdSetArmorDmgPre = CreateMultiForward("Plague_SetArmorDamage_Pre", ET_CONTINUE, FP_CELL, FP_CELL);
    fwdSetArmorDmgPost = CreateMultiForward("Plague_SetArmorDamage_Post", ET_IGNORE, FP_CELL, FP_CELL);
    fwdArmorHurtPre = CreateMultiForward("Plague_ArmorDamage_Pre", ET_CONTINUE, FP_CELL, FP_CELL, FP_CELL);
    fwdArmorHurtPost = CreateMultiForward("Plague_ArmorDamage_Post", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL);
}

public plugin_natives()
{
    register_native("pr_set_armor_protection", "Native_SetArmorProt");
    register_native("pr_get_armor_protection", "Native_GetArmroProt");
    register_native("pr_set_armor_damage", "Native_SetArmorDamage");
    register_native("pr_get_armor_damage", "Native_GetArmorDamage");
    register_native("pr_set_infection_type", "Native_SetInfType");
    register_native("pr_get_infection_type", "Native_GetInfType");
}

public plugin_init()
{
    register_plugin(pluginName, pluginVer, pluginAuthor);

    RegisterHookChain(RG_CBasePlayer_TakeDamage, "ReHook_TakeDamage_Pre", 0);

    g_flArmorProtection[0] = 1.0;
    g_flArmorDamage[0] = 1.0;
}

public client_putinserver(id)
{
    g_flArmorProtection[id] = g_flArmorProtection[0];
    g_flArmorDamage[id] = g_flArmorDamage[0];
}

public ReHook_TakeDamage_Pre(id, inflictor, attacker, Float:flDamage, dmgBits)
{
    static RoundStatus:status;
    status = pr_round_status();

    if(status != RoundStatus_Started || gInfectionType == Infection_None)
    {
        SetHookChainReturn(ATYPE_INTEGER, 0);
        return HC_SUPERCEDE;
    }

    if(id == attacker || pr_is_zombie(id) || 
    pr_is_human(attacker) || ~dmgBits & DMG_BULLET || 
    ~dmgBits & DMG_SLASH)
        return HC_CONTINUE;

    if(gInfectionType == Infection_Custom || 
        gInfectionType == Infection_Kill)
        return HC_CONTINUE;

    new bool:bCan = true;
    if(gInfectionType == Infection_InfectArmor)
    {
        new Float:armor = get_entvar(id, var_armorvalue);
        new Float:dmg = flDamage * g_flArmorDamage[attacker] * g_flArmorProtection[id];

        if(armor > 0)
        {
            bCan = false;

            new ret;
            ExecuteForward(fwdArmorHurtPre, ret, id, attacker, dmg);

            if(ret == _:Plague_Continue)
            {
                armor -= dmg;
                ExecuteForward(fwdArmorHurtPost, _, id, attacker, dmg);
            }

            if(armor < 0)
                armor = 0.0;

            set_entvar(id, var_armorvalue, armor);
        }
    }

    if(bCan)
        pr_set_user_zombie(id, .attacker = attacker);
    
    SetHookChainReturn(ATYPE_INTEGER, 0);
    return HC_SUPERCEDE;
}

public Native_SetArmorProt(plgId, params)
{
    if(params < 3)
        return;

    new id = get_param(1);

    if(-1 > id || id > 33)
        return;

    new Float:prot = get_param_f(2);
    new bool:call = bool:get_param(3);

    if(call)
    {
        new ret;
        ExecuteForward(fwdSetArmorProtPre, ret, id, prot);

        if(ret > _:Plague_Continue)
            return;
    }

    if(id == 0)
    {
        for(new i = 0; i < 33; i++)
        {
            g_flArmorProtection[i] = prot;
        }
    }
    else g_flArmorProtection[id] = prot;

    ExecuteForward(fwdSetArmorProtPost, _, id, prot);
}

public Native_SetArmorDamage(plgId, params)
{
    if(params < 3)
        return;

    new id = get_param(1);

    if(-1 > id || id > 33)
        return;

    new Float:dmg = get_param_f(2);
    new bool:call = bool:get_param(3);

    if(call)
    {
        new ret;
        ExecuteForward(fwdSetArmorDmgPre, ret, id, dmg);

        if(ret > _:Plague_Continue)
            return;
    }

    if(id == 0)
    {
        for(new i = 0; i < 33; i++)
        {
            g_flArmorDamage[i] = dmg;
        }
    }
    else g_flArmorDamage[id] = dmg;

    ExecuteForward(fwdSetArmorDmgPost, _, id, dmg);
}

public Float: Native_GetArmorProt(plgId, params)
{
    if(params < 1)
        return 0.0;

    new id = get_param(1);

    if(-1 < id || id > 33)
        return 0.0;

    return g_flArmorProtection[id];
}

public Float: Native_GetArmorDamage(plgId, params)
{
    if(params < 1)
        return 0.0;

    new id = get_param(1);

    if(-1 < id || id > 33)
        return 0.0;

    return g_flArmorDamage[id];
}

public Native_Set