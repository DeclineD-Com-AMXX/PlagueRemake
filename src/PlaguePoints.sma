#include <amxmodx>
#include <amxmisc>
#include <reapi>
#include <nvault>

#include <plague>

#define IsPlayerId(%0) ( 0 < %0 <= MAX_PLAYERS )
#define pr_get_user_vip(%0) false

enum PlayerData {
            Currency,
            Kills,
            Infects,
    Float:  Damage
}

new         gData[MAX_PLAYERS + 1][PlayerData];

new         cOn,
            cSave, 
            cSaveType, 
            cSaveCount, 
            cSaveCountVip, 
            cKillReward, 
            cKillRewardVip,
            cInfectReward, 
            cInfectRewardVip,
            cKillCount, 
            cKillCountVip, 
            cInfectCount,
            cInfectCountVip, 
            cDamageReward, 
            cDamageRewardVip, 
            cDamageCount,
            cDamageCountVip;

new         gOn,
            gSave, 
            gSaveType, 
            gSaveCount, 
            gSaveCountVip, 
            gKillReward, 
            gKillRewardVip,
            gInfectReward, 
            gInfectRewardVip,
            gKillCount, 
            gKillCountVip, 
            gInfectCount,
            gInfectCountVip,  
            gDamageReward, 
            gDamageRewardVip, 
    Float:  gDamageCount,
    Float:  gDamageCountVip;

new const   szVaultName[] = "currency_points_save";
new         vault;
new         vaultCount; // Using count

new fwdChangedAmmo, fwdChangedAmmoPost;

Load(id)
{
    if(vault == INVALID_HANDLE)
    {
        vault = nvault_open(szVaultName);
        vaultCount++;

        if(vault == INVALID_HANDLE)
            return;
    }
    else
    vaultCount++;

    new szCSave[45];

    switch(gSaveType)
    {
        case 1: get_user_ip(id, szCSave, charsmax(szCSave), 1);
        case 2: get_user_authid(id, szCSave, charsmax(szCSave));
        default: get_user_name(id, szCSave, charsmax(szCSave));
    }

    new szSaveData[100];
    nvault_get(vault, szCSave, szSaveData, charsmax(szSaveData));

    gData[id][Currency] = str_to_num(szSaveData);

    vaultCount--;

    if(vaultCount <= 0 && vault != INVALID_HANDLE)
    {
        nvault_close(vault);
        vault = INVALID_HANDLE;
    }
}

Save(id)
{
    if(vault == INVALID_HANDLE)
    {
        vault = nvault_open(szVaultName);
        vaultCount++;

        if(vault == INVALID_HANDLE)
            return;
    }
    else
    vaultCount++;

    new szCSave[45];

    switch(gSaveType)
    {
        case 1: get_user_ip(id, szCSave, charsmax(szCSave), 1);
        case 2: get_user_authid(id, szCSave, charsmax(szCSave));
        default: get_user_name(id, szCSave, charsmax(szCSave));
    }

    new szSaveData[100];
    formatex(szSaveData, charsmax(szSaveData), "%i", gData[id][Currency]);

    nvault_set(vault, szCSave, szSaveData);

    vaultCount--;

    if(vaultCount <= 0 && vault != INVALID_HANDLE)
    {
        nvault_close(vault);
        vault = INVALID_HANDLE;
    }
}

SetPoints(id, amount, bool:add)
{
    if(!IsPlayerId(id))
        return;
    
    if(add)
        amount += gData[id][Currency];

    new ret;
    ExecuteForward(fwdChangedAmmo, ret, id, amount);

    if(ret > Plague_Continue)
        return;

    gData[id][Currency] = amount;
    Save(id);

    ExecuteForward(fwdChangedAmmoPost, _, id, amount);
}

public plugin_precache()
{
    fwdChangedAmmo = CreateMultiForward("Plague_SetUserPoints", ET_CONTINUE, FP_CELL, FP_CELL);
    fwdChangedAmmoPost = CreateMultiForward("Plague_SetUserPoints_Post", ET_IGNORE, FP_CELL, FP_CELL);
}

public plugin_natives()
{
    register_native("pr_set_user_points", "Native_SetPacks");
    register_native("pr_get_user_points", "Native_GetPacks");
}

public Native_SetPacks(plgId, params)
{
    if(params < 3)
        return;

    new id = get_param(1), amount = get_param(2);
    new bool:add = bool:get_param(3);

    SetPoints(id, amount, add);
}

public Native_GetPacks(plgId, params)
{
    if(params < 1)
        return 0;

    new id = get_param(1);

    if(!IsPlayerId(id))
        return 0;

    return gData[id][Currency];
}

public plugin_init()
{
    register_plugin("[Plague] Currency: Model (Points)", "v1.0", "DeclineD");

    register_concmd("amx_points", "cmdAmmo", ADMIN_PASSWORD, "Usage: amx_points <name/all> <set/add/take> <amount>");

    RegisterHookChain(RG_CBasePlayer_TakeDamage, "ReHook_CBasePlayer_TakeDamage_Post", 1);
    RegisterHookChain(RG_CBasePlayer_Killed, "ReHook_CBasePlayer_Killed_Post", 1);

    vault = INVALID_HANDLE;

    cOn = register_cvar("pr_currency_points_on", "1");
    cSave = register_cvar("pr_currency_points_save", "1");
    cSaveType = register_cvar("pr_currency_points_save_type", "0");
    cSaveCount = register_cvar("pr_currency_points_save_max", "20000");
    cSaveCountVip = register_cvar("pr_currency_points_save_max_vip", "50000");
    cKillReward = register_cvar("pr_currency_points_kill_reward", "5");
    cKillRewardVip = register_cvar("pr_currency_points_kill_reward_vip", "5");
    cInfectReward = register_cvar("pr_currency_points_infect_reward", "3");
    cInfectRewardVip = register_cvar("pr_currency_points_infect_reward_vip", "3");
    cKillCount = register_cvar("pr_currency_points_kill_to_reward", "1");
    cKillCountVip = register_cvar("pr_currency_points_kill_to_reward_vip", "1");
    cInfectCount = register_cvar("pr_currency_points_infect_to_reward", "1");
    cInfectCountVip = register_cvar("pr_currency_points_infect_to_reward_vip", "1");
    cDamageReward = register_cvar("pr_currency_points_damage_reward", "2");
    cDamageRewardVip = register_cvar("pr_currency_points_damage_reward_vip", "2");
    cDamageCount = register_cvar("pr_currency_points_damage_to_reward", "2.0");
    cDamageCountVip = register_cvar("pr_currency_points_damage_to_reward_vip", "2.0");

    bind_pcvar_num(cOn, gOn);
    bind_pcvar_num(cSave, gSave);
    bind_pcvar_num(cSaveType, gSaveType);
    bind_pcvar_num(cSaveCount, gSaveCount);
    bind_pcvar_num(cSaveCountVip, gSaveCountVip);
    bind_pcvar_num(cKillReward, gKillReward);
    bind_pcvar_num(cKillRewardVip, gKillRewardVip);
    bind_pcvar_num(cInfectReward, gInfectReward);
    bind_pcvar_num(cInfectRewardVip, gInfectRewardVip);
    bind_pcvar_num(cKillCount, gKillCount);
    bind_pcvar_num(cKillCountVip, gKillCountVip);
    bind_pcvar_num(cInfectCount, gInfectCount);
    bind_pcvar_num(cInfectCountVip, gInfectCountVip);
    bind_pcvar_num(cDamageReward, gDamageReward);
    bind_pcvar_num(cDamageRewardVip, gDamageRewardVip);
    bind_pcvar_float(cDamageCount, gDamageCount);
    bind_pcvar_float(cDamageCountVip, gDamageCountVip);
}

public plugin_end()
{
    if(!gSave)
        return;

    new players[MAX_PLAYERS], num;
    get_players(players, num);
    for(new i = 0; i < num; i++)
        Save(players[i]);
}

public client_connect(id)
{
    gData[id][Currency] = 0;
    gData[id][Kills] = 0;
    gData[id][Infects] = 0;  
    gData[id][Damage] = 0.0;

    if(!get_pcvar_num(cSave))
        return;

    Load(id);
}

public client_disconnected(id)
{
    if(!gSave)
        return;

    Save(id);
}

public cmdAmmo(id, level, cid)
{
    if(!cmd_access(id, level, cid, 3))
        return PLUGIN_HANDLED;

    new szMethod[5], iMethod = -1;
    read_argv(2, szMethod, charsmax(szMethod));

    if(equali(szMethod, "set"))
        iMethod = 0;
    else if(equali(szMethod, "add"))
        iMethod = 1;
    else if(equali(szMethod, "take"))
        iMethod = 2;

    if(iMethod == -1)
        return PLUGIN_HANDLED;

    new szArg[32], szAmount[100], iAmount, player;
    read_argv(1, szArg, charsmax(szArg));
    read_argv(3, szAmount, charsmax(szAmount));

    iAmount = str_to_num(szAmount);

    if(equali(szArg, "all"))
    {
        new players[MAX_PLAYERS], num;
        get_players(players, num);

        for(new i = 0; i < num; i++)
            SetPoints(players[i], iMethod == 2 ? -iAmount : iAmount, iMethod > 0 ? true : false);
    }
    else {
        player = find_player("bl", szArg);

        if(!player)
            return PLUGIN_HANDLED;

        SetPoints(player, iMethod == 2 ? -iAmount : iAmount, iMethod > 0 ? true : false);
    }

    client_print_color(id, 0, "^4[ZP] ^3Admin ^4%n ^1%s ^4%s ^3%i ^4Points^1.", id, (iMethod == 0 ? "set" : (iMethod == 1 ? "gave" : "took")), (player > 0 ? fmt("%n", player) : "Everyone"), iAmount);

    return PLUGIN_HANDLED;
}

public ReHook_CBasePlayer_Killed_Post(id, attacker)
{
    if(!gOn || id == attacker)
        return;
    
    gData[id][Kills]++;

    new count, reward;

    if(pr_get_user_vip(attacker) && gKillCountVip > 0 && gKillRewardVip > 0)
    {
        count = gKillCountVip;
        reward = gKillRewardVip;
    }
    else {
        if(gKillCount <= 0 || gKillReward <= 0)
            return;

        count = gKillCount;
        reward = gKillReward;
    }

    if(gData[attacker][Kills] >= count)
    {
        gData[attacker][Kills] -= count;
        SetPoints(attacker, reward, true);
    }
}

public ReHook_CBasePlayer_TakeDamage_Post(id, inflictor, attacker, Float:flDamage, dmgBits)
{
    if(pr_is_human(id) || pr_is_zombie(attacker) || flDamage <= 0.0 || !(dmgBits & DMG_BULLET))
        return;

    new Float: count, reward, num;

    if(pr_get_user_vip(attacker) && gDamageRewardVip > 0 && gDamageCountVip > 0.0)
    {
        count = gDamageCountVip;
        reward = gDamageRewardVip;
    }
    else {
        if(gDamageReward <= 0 || gDamageCount <= 0.0)
            return;

        count = gDamageCount;
        reward = gDamageReward;
    }

    gData[attacker][Damage] += flDamage;

    while(gData[attacker][Damage] - count > 0.0)
    {
        gData[attacker][Damage] -= count;
        num++;
    }

    if(num > 0)
        SetPoints(attacker, reward * num, true);
}

public Plague_User_Infected_Post(id, attacker)
{
    // Making sure the attacker is valid
    if(attacker <= 0 || id == attacker || !is_user_alive(id))
        return;
    
    new count, reward;

    if(pr_get_user_vip(id) && gInfectCountVip > 0 && gInfectRewardVip > 0)
    {
        count = gInfectCountVip;
        reward = gInfectRewardVip;
    }
    else {
        if(gInfectCount <= 0 || gInfectReward <= 0)
            return;
        
        count = gInfectCount;
        reward = gInfectReward;
    }

    gData[attacker][Infects]++;

    if(gData[attacker][Infects] >= count)
    {
        gData[attacker][Infects] -= count;
        SetPoints(attacker, reward, true);
    }
}