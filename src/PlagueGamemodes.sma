#include <amxmodx>
#include <reapi>

#include <plague_rounds>
#include <plague_classes>
#include <plague_human>
#include <plague_settings>
#include <plague_const>


/* -> Plugin Information <- */
new const pluginName[ ] = "[Plague] Gamemode Management";
new const pluginVer[ ] = "v1.0";
new const pluginAuthor[ ] = "DeclineD";

new const pluginCfg[ ] = "addons/amxmodx/configs/plague.json";

/* -> Gamemodes Information <- */
enum GMInfo {
    Trie:GM_Population,
    Array:GM_SysName,
    Array:GM_Name,
    Array:GM_InfType
}

new gGamemodeInfo[GMInfo];


/* -> Gamemode <- */
new PlagueClassId:HumanClassId;
new gGamemodes;
new gCurrentGamemode;
new gDefaultGamemode;

new fwdChoosePre, fwdChoosePost;
new fwdChosen, fwdChosenPost;

/* -> Not-Twice Prevention <- */
new bitLastChosen, iLastChosen[MAX_PLAYERS], iLastChosenCount;

/* -> Private Functions <- */
LoadGamemode(szSys[32], szName[32], InfectionType:infType)
{
    new JSON:section = json_object_get_object_safe(pr_open_settings(pluginCfg), "gamemode");
    new JSON:section2 = json_object_get_object_safe(section, szSys);

    new JSON:temp = json_object_get_string_safe(section2, "name", szName, szName, charsmax(szName));
    json_free(temp);

    temp = json_object_get_value_safe(section2, "infection_type", fmt("%i", infType), JSONNumber, infType);
    json_free(temp);
    json_free(section2);
    json_free(section);

    pr_close_settings(pluginCfg);

    TrieSetCell(gGamemodeInfo[GM_Population], szSys, gGamemodes);
    ArrayPushString(gGamemodeInfo[GM_SysName], szSys);
    ArrayPushString(gGamemodeInfo[GM_Name], szName);
    ArrayPushCell(gGamemodeInfo[GM_InfType], infType);

    gGamemodes++
    return gGamemodes - 1;
}

ChooseGamemode(bool:skip_checks)
{
    if ( gGamemodes == 1 )
    {
        ExecuteForward(fwdChoosePost, _, 0, skip_checks);
        return 0;
    }

    if ( gGamemodes == 0 )
    {
        return -1;
    }
    
    new Array: toChoose;
    toChoose = ArrayCreate(1, 1);

    new chooseSize; chooseSize = 0;

    new last; last = 0;
    
    new ret;
    for(new i = 0; i < gGamemodes; i++)
    {
        ExecuteForward(fwdChoosePre, ret, i, skip_checks);

        if(ret > Plague_Continue)
            continue;

        ArrayPushCell(toChoose, i);
        last = i;
        chooseSize++;
    }

    if ( chooseSize > 1 )
        last = ArrayGetCell(toChoose, random_num(0, chooseSize - 1));

    ArrayDestroy(toChoose);

    ExecuteForward(fwdChoosePost, _, last, skip_checks);

    if(chooseSize > 0)
        return last;
    else
        return gDefaultGamemode;
}

ChoosePlayers(zmCount)
{
    if(zmCount > 32)
        zmCount = 32;
    
    new players[MAX_PLAYERS], num;
    get_players(players, num, "a");

    if(num < 1)
        return;

    new chosen[MAX_PLAYERS], id, i, ret, rand;

    for(i = 0; i < zmCount; i++)
    {
        if(num < zmCount)
            return;
        
        num--;
        rand = random_num(0, num);
        id = players[rand];

        players[rand] = players[num];
        players[num] = id;

        if(bitLastChosen & id)
        {
            bitLastChosen &= ~id;
            i--;
        }
        else {
            ExecuteForward(fwdChosen, ret, id);

            if(ret > Plague_Continue)
            {
                i--;
                continue;
            }

            bitLastChosen |= id;
            chosen[i] = id;

            ExecuteForward(fwdChosenPost, _, id);
        }
    }

    iLastChosen = chosen;
    iLastChosenCount = zmCount;
}

/* -> Public Functions <- */
public plugin_precache()
{
    gGamemodeInfo[GM_Population] = TrieCreate();
    gGamemodeInfo[GM_SysName] = ArrayCreate(32, 1);
    gGamemodeInfo[GM_Name] = ArrayCreate(32, 1);
    gGamemodeInfo[GM_InfType] = ArrayCreate(1, 1);

    fwdChoosePre = CreateMultiForward("Plague_Choose_Gamemode_Pre", ET_CONTINUE, FP_CELL, FP_CELL);
    fwdChoosePost = CreateMultiForward("Plague_Choose_Gamemode_Post", ET_IGNORE, FP_CELL, FP_CELL);

    fwdChosen = CreateMultiForward("Plague_Chosen_Pre", ET_CONTINUE, FP_CELL);
    fwdChosenPost = CreateMultiForward("Plague_Chosen_Post", ET_CONTINUE, FP_CELL);
}

public plugin_natives()
{
    register_native("pr_register_gamemode", "Native_Reg");
    register_native("pr_gamemode_init_choose", "Native_InitChoose");
    register_native("pr_set_current_gamemode", "Native_SetCurrent");
    register_native("pr_current_gamemode", "Native_CurrentGamemode");
    register_native("pr_set_default_gamemode", "Native_DefaultGamemode");

    register_native("pr_transform_chosen_players", "Native_InfectChosen", 1);
    register_native("pr_init_choose_transform", "Native_ChoosePlayers", 1);
    register_native("pr_get_chosen_list", "Native_ChosenList");
    register_native("pr_set_chosen_list", "Native_SetChosenList");

    register_native("pr_get_gamemode_system_name", "Native_SysName");
    register_native("pr_get_gamemode_id", "Native_GetId");
    register_native("pr_get_gamemode_name", "Native_GamemodeName");
    register_native("pr_set_gamemode_infection_type", "Native_InfType", 1);
    register_native("pr_gamemode_count", "Native_Count");
}

public plugin_init()
{
    register_plugin(pluginName, pluginVer, pluginAuthor);

    HumanClassId = pr_get_class_id(PClass_Human);

    RegisterHookChain(RG_CBasePlayer_Spawn, "ReHook_Spawned", 1);
}

public Plague_RoundStart_Post()
{
    if( pr_round_status() == RoundStatus_Starting )
        gCurrentGamemode = ChooseGamemode(false);
}

public Plague_RoundStart2_Post()
{
    pr_set_user_infection_type(0, InfectionType:ArrayGetCell(gGamemodeInfo[GM_InfType], gCurrentGamemode));
}

public ReHook_Spawned(id)
{
    if ( pr_get_user_class(id) == HumanClassId && is_user_alive( id ) )
    {
        pr_set_user_infection_type(id, InfectionType:ArrayGetCell(gGamemodeInfo[GM_InfType], gCurrentGamemode));
    }
}

public Native_InfType(id, InfectionType:infType)
{
    if( id < 0 || id >= gGamemodes )
        return 0;

    if ( infType < Infection_No || infType >= InfectionType )
        return 0;

    ArraySetCell(gGamemodeInfo[GM_InfType], id, infType);

    if ( pr_round_status( ) == RoundStatus_Started )
        pr_set_user_infection_type(0, infType);

    return 1;
}

public Native_DefaultGamemode(plgId, params)
{
    if(params < 1)
        return;

    new id = get_param(1);

    gDefaultGamemode = id;
}

public Native_InfectChosen(PlagueClassId:id)
{
    for(new i = 0; i < iLastChosenCount; i++)
    {
        pr_change_class(iLastChosen[i], .class = id);
    }
}

public Native_ChoosePlayers(num)
    ChoosePlayers(num);

public Native_ChosenList(plgId, params)
{
    if(params < 2)
        return;

    set_array(1, iLastChosen, charsmax( iLastChosen ) );
    set_param_byref(2, iLastChosenCount);
}

public Native_SetChosenList(plgId, params)
{
    if(params < 2)
        return;

    get_array(1, iLastChosen, charsmax( iLastChosen ) );
    iLastChosenCount = get_param(2);
}

public Native_Reg(plgId, params)
{
    if(params < 3)
        return -1;

    new sysName[32];
 
    get_string(1, sysName, charsmax(sysName));

    if(TrieKeyExists(gGamemodeInfo[GM_Population], sysName))
        return -1;
    
    new name[32];

    get_string(2, name, charsmax(name));

    return LoadGamemode(sysName, name, InfectionType:get_param(3));
}

public Native_InitChoose(plgId, params)
{
    if(params < 1)
        return;

    new bool:skip = bool:get_param(1);

    gCurrentGamemode = ChooseGamemode(skip);
}

public Native_SetCurrent(plgId, params)
{
    if(params < 1)
        return;

    new id = get_param(1);

    if(!(0 < id < gGamemodes))
        return;
    
    gCurrentGamemode = id;
    ExecuteForward(fwdChoosePost, _, gCurrentGamemode, true);
}

public Native_GamemodeName(plgId, params)
{
    if(params < 3)
        return;

    new gamemode = get_param(1);

    if(!(0 < gamemode < gGamemodes))
        return;

    new size = get_param(3);

    new szName[32];
    ArrayGetString(gGamemodeInfo[GM_Name], gCurrentGamemode, szName, charsmax(szName));

    set_string(2, szName, size);
}

public Native_SysName(plgId, params)
{
    if(params < 3)
        return;

    new gamemode = get_param(1);

    if(!(0 < gamemode < gGamemodes))
        return;
    
    new size = get_param(3);

    new szName[32];
    ArrayGetString(gGamemodeInfo[GM_SysName], gCurrentGamemode, szName, charsmax(szName));

    set_string(2, szName, size);
}

public Native_GetId(plgId, params)
{
    if(params < 1)
        return -1;

    new szName[32];
    get_string(1, szName, charsmax(szName));

    if(!TrieKeyExists(gGamemodeInfo[GM_Population], szName))
        return -1;

    new id;
    TrieGetCell(gGamemodeInfo[GM_Population], szName, id);

    return id;
}

public Native_CurrentGamemode()
    return gCurrentGamemode;

public Native_Count()
    return gGamemodes;