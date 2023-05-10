#include <amxmodx>
#include <reapi>

#include <plague_rounds>
#include <plague_zombie>
#include <plague_human>
#include <plague_const>


/* -> Plugin Information <- */
new const pluginName[ ] = "[Plague] Gamemode Management";
new const pluginVer[ ] = "v1.0";
new const pluginAuthor[ ] = "DeclineD";


/* -> Gamemodes Information <- */
enum GMInfo {
    Array:GM_SysName,
    Array:GM_Name
}

new gGamemodeInfo[GMInfo];


/* -> Gamemode <- */
new gGamemodes;
new gCurrentGamemode;
new gDefaultGamemode;

new fwdChoosePre, fwdChoosePost;


/* -> Private Functions <- */
GamemodeExists(sysName[])
{
    new szSysName[32];
    for(new i = 0; i < gGamemodes; i++)
    {
        ArrayGetString(gGamemodeInfo[GM_SysName], i, szSysName, charsmax(szSysName));
        if(equal(szSysName, sysName))
            return 1;
    }

    return 0;
}

ChooseGamemode(bool:skip_checks)
{
    static Array: toChoose;
    toChoose = ArrayCreate(1, 1);

    static chooseSize; chooseSize = 0;

    static last; last = 0;
    
    static ret;
    for(new i = 0; i < gGamemodes; i++)
    {
        if(gDefaultGamemode == i)
            ExecuteForward(fwdChoosePre, ret, i, true);
        else
            ExecuteForward(fwdChoosePre, ret, i, skip_checks);

        if(ret > _:Plague_Continue)
            continue;

        ArrayPushCell(toChoose, i);
        last = i;
        chooseSize++;
    }

    if(chooseSize > 1)
        last = ArrayGetCell(toChoose, random_num(0, chooseSize - 1));

    ArrayDestroy(toChoose);

    ExecuteForward(fwdChoosePost, _, last, skip_checks);

    if(chooseSize > 0)
        return last;
    else
        return gDefaultGamemode;
}

/* -> Public Functions <- */
public plugin_precache()
{
    gGamemodeInfo[GM_SysName] = ArrayCreate(32, 1);
    gGamemodeInfo[GM_Name] = ArrayCreate(32, 1);

    fwdChoosePre = CreateMultiForward("Plague_Choose_Gamemode_Pre", ET_CONTINUE, FP_CELL, FP_CELL);
    fwdChoosePost = CreateMultiForward("Plague_Choose_Gamemode_Post", ET_IGNORE, FP_CELL, FP_CELL);
}

public plugin_natives()
{
    register_native("pr_register_gamemode", "Native_Reg");
    register_native("pr_gamemode_init_choose", "Native_InitChoose");
    register_native("pr_set_current_gamemode", "Native_SetCurrent");
    register_native("pr_current_gamemode", "Native_CurrentGamemode");
    register_native("pr_set_default_gamemode", "Native_DefaultGamemode");

    register_native("pr_get_gamemode_system_name", "Native_SysName");
    register_native("pr_get_gamemode_id", "Native_GetId");
    register_native("pr_get_gamemode_name", "Native_GamemodeName");
    register_native("pr_gamemode_count", "Native_Count");
}

public plugin_init()
{
    register_plugin(pluginName, pluginVer, pluginAuthor);
}

public Native_Reg(plgId, params)
{
    if(params < 3)
        return -1;

    new sysName[32];
 
    get_string(1, sysName, charsmax(sysName));

    if(GamemodeExists(sysName))
        return -1;
    
    new name[32];

    get_string(2, name, charsmax(name));

    ArrayPushString(gGamemodeInfo[GM_SysName], sysName);
    ArrayPushString(gGamemodeInfo[GM_Name], name);

    return (gGamemodes++) - 1;
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

    new szName2[32];
    for(new i = 0; i < gGamemodes; i++)
    {
        ArrayGetString(gGamemodeInfo[GM_SysName], i, szName2, charsmax(szName2));
        if(equal(szName, szName2))
            return i;
    }

    return -1;
}

public Native_CurrentGamemode()
    return gCurrentGamemode;

public Native_Count()
    return gGamemodes;

public Plague_RoundStart_Post()
    gCurrentGamemode = ChooseGamemode(false);