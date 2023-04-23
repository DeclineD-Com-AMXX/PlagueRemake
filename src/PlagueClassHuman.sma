/* -> Semicolon <- */
#pragma semicolon 1


/* -> Includes <- */
#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <reapi>

#include <plague_const>
#include <plague_human_const>


/* -> Plugin Info <- */
new const pluginName[ ] = "[Plague] Human Class";
new const pluginVer[ ] = "v1.0";
new const pluginAuthor[ ] = "DeclineD";


/* -> Client <- */
#define IsPlayer(%0) ( ( 0 < %0 ) && ( %0 <= MAX_PLAYERS ) && is_user_connected(%0) )
#define IsPlayerId(%0) ( ( 0 < %0 ) && ( %0 <= MAX_PLAYERS ) )
#define PlayerModelPath(%0) fmt("models/player/%s/%s.mdl", %0, %0)

new bool: bHuman[ MAX_PLAYERS + 1 ];

new iClass[ MAX_PLAYERS + 1 ];
new iNextClass[ MAX_PLAYERS + 1 ];


/* -> Class <- */
#define ValidRace(%0) ( ( 0 <= %0 ) && ( %0 < iClassCount ) )
#define ValidInfo(%0) ( ( HumanInformation:0 <= %0 ) && %0 < HumanInformation )
#define ValidAttribute(%0) ( ( HumanAttributes:0 <= %0 ) && %0 < HumanAttributes )

new iClassCount;

new ClassInfo[HumanInformation];
new ClassAttributes[HumanAttributes];

// new UserClassInfo[MAX_PLAYERS + 1][HumanInformation];
// new UserClassAttributes[MAX_PLAYERS + 1][HumanAttributes];


/* -> Forwards <- */
enum fwds {
    FWD_TRANSFORM,
    FWD_TRANSFORM_POST,
    FWD_MENU_SHOW,
    FWD_CLASS_SELECTED
}

new glForwards[fwds];


/* -> Private Functions <- */
HumanExists(sysName[])
{
    new szName[32];
    for(new i = 0; i < iClassCount; i++)
    {
        ArrayGetString(ClassInfo[Human_SystemName], i, szName, charsmax(szName));

        if(equal(szName, sysName))
            return 1;
    }

    return 0;
}

PrecacheSoundArray(Array:sound)
{
    static szSound[MAX_RESOURCE_PATH_LENGTH];
    for(new i = 0; i < ArraySize(sound); i++)
    {
        ArrayGetString(sound, i, szSound, charsmax(szSound));
        precache_sound(szSound);
    }
}

bool: CanUseClass(id, class, bool:ignoreFlags)
{
    if(ignoreFlags)
        return true;

    new flags = 0;
    flags = ArrayGetCell(ClassAttributes[Human_Flags], class);

    if(flags <= 0)
        return true;

    if((get_user_flags(id) & flags) == flags)
        return true;

    return false;
}

FirstAvailableClass(id)
{
    for(new i = 0; i < iClassCount; i++)
    {
        if(CanUseClass(id, i, false))
            return i;    
    }

    return 0;
}

TransformNotice(id, attacker)
{
    static iDeathMsg, iScoreAttrib;
    if(!iDeathMsg) iDeathMsg = get_user_msgid("DeathMsg");
    if(!iScoreAttrib) iScoreAttrib = get_user_msgid("ScoreAttrib");

    message_begin(MSG_BROADCAST, iDeathMsg);
    write_byte(attacker);
    write_byte(id);
    write_byte(0);//write_byte(human(id) ? 0 : 1);
    write_string("worldspawn");//write_string(human(id) ? "worldspawn" : "teammate");
    message_end();

    message_begin(MSG_BROADCAST, iScoreAttrib);
    write_byte(id);
    write_byte(0);
    message_end();
}

MakeHuman(id, attacker, bool:spawn, bool:flags)
{
    new oldclass = iClass[id];

    new ret;
    ExecuteForward(glForwards[FWD_TRANSFORM_POST], ret, id, attacker, iClass[id], iNextClass[id], spawn);

    if(ret > _:Plague_Continue)
        return;

    if(iNextClass[id] != iClass[id])
    {
        if(!CanUseClass(id, iNextClass[id], flags))
            iNextClass[id] = iClass[id];
        else
            iClass[id] = iNextClass[id];
    }

    if(is_user_alive(id)) {
        for(new i = 1; i <= MAX_ITEM_TYPES; i++)
            rg_remove_items_by_slot(id, any:i);

        rg_give_item(id, "weapon_knife");

        new szModel[32];
        ArrayGetString(ClassInfo[Human_Model], iClass[id], szModel, charsmax(szModel));
        rg_set_user_model(id, szModel, true);

        if(spawn)
        {
            new hp = ArrayGetCell(ClassAttributes[Human_Health], iClass[id]);
            set_entvar(id, var_health, float(hp));
            set_entvar(id, var_max_health, float(hp));

            rg_give_item(id, "weapon_usp");
            rg_set_user_bpammo(id, WEAPON_USP, 48);
        }

        new gravity = ArrayGetCell(ClassAttributes[Human_Gravity], iClass[id]);
        set_entvar(id, var_gravity, float(gravity)/800.0);

        ExecuteHamB(Ham_CS_Player_ResetMaxSpeed, id);

        if(attacker > -1)
            TransformNotice(id, attacker);
    }

    set_member(id, m_iTeam, TEAM_CT);
    rg_set_user_team(id, TEAM_CT);

    ExecuteForward(glForwards[FWD_TRANSFORM_POST], ret, id, attacker, oldclass, iNextClass[id], spawn);
}

Transform(id, bool:human, attacker, bool:spawn, bool:flags)
{
    if(!IsPlayer(id))
    {
        log_message("%i not connected", id);
        return 0;
    }

    if(human)
        MakeHuman(id, attacker, spawn, flags);

    bHuman[id] = human;

    return 1;
}

bool: CanShow(id, class)
{
    new MenuShow: show = ArrayGetCell(ClassAttributes[Human_MenuShow], class);
    
    if(show == MenuShow_No)
        return false;

    if(show == MenuShow_Custom)
    {
        new ret;
        ExecuteForward(glForwards[FWD_MENU_SHOW], ret, id, class);

        show = MenuShow: ret;
    }

    if(show == MenuShow_Flag)
    {
        new flags = ArrayGetCell(ClassAttributes[Human_Flags], class);

        return bool:((get_user_flags(id) & flags) == flags);
    }

    return true;
}

RaceMenu(id)
{
    if(iClassCount <= 1)
        return;
    
    new menu = menu_create("Zombie Classes", "RaceHandler");

    new szFormat[128], szName[32];

    for(new i = 0; i < iClassCount; i++)
    {
        if(!CanShow(id, i))
            continue;
        
        ArrayGetString(ClassInfo[Human_Name], i, szName, charsmax(szName));
        formatex(szFormat, charsmax(szFormat), "%s%s", (iNextClass[id] == i ? "\d" : ""), szName);
        menu_additem(menu, szFormat, fmt("%i", i));
    }

    menu_display(id, menu);
}

ChatSelectionInfo(id)
{
    new szName[32];
    new hp = ArrayGetCell(ClassAttributes[Human_Health], iNextClass[id]),
        gravity = ArrayGetCell(ClassAttributes[Human_Gravity], iNextClass[id]),
        Float: speed = ArrayGetCell(ClassAttributes[Human_SpeedAdd], iNextClass[id]);

    ArrayGetString(ClassInfo[Human_Name], iNextClass[id], szName, charsmax(szName));

    client_print_color(id, 0, "^x04[ZP] ^x01You selected the ^x03human race: ^x04%s.", szName);
    client_print_color(id, 0, "^x04[ZP] ^x01Health: ^x04%i ^x03| ^x01Gravity: ^x04%i ^x03| ^x01Speed: ^x04%.2f^x01.", hp, gravity, 250.0 + speed);
}

public RaceHandler(id, menu, item)
{
    if(item == MENU_EXIT)
    {
        menu_destroy(menu);
        return;
    }

    new szDesc[3];
    menu_item_getinfo(menu, item, _, szDesc, charsmax(szDesc));

    new class = str_to_num(szDesc);

    new ret;
    ExecuteForward(glForwards[FWD_CLASS_SELECTED], ret, id, class);

    if(ret == _:Plague_Stop)
    {
        menu_display(id, menu);
        return;
    }

    menu_destroy(menu);

    if(ret == _:Plague_Handled)
        return;

    iNextClass[id] = class;

    ChatSelectionInfo(id);
}


/* -> Natives <- */
public plugin_natives()
{
    register_native("pr_is_human", "Native_IsHuman", 1);

    register_native("pr_register_human", "Native_Register", 1);
    register_native("pr_human_attributes", "Native_MainAttributes", 1);
    register_native("pr_human_races_count", "Native_Count", 1);

    register_native("pr_next_available_human_race", "Native_NextAvailable", 1);

    register_native("pr_get_human_users_count", "Native_Users", 1);
    register_native("pr_set_user_human", "Native_SetHuman", 1);

    register_native("pr_set_user_human_race", "Native_SetRace", 1);
    register_native("pr_get_user_human_race", "Native_GetRace", 1);

    register_native("pr_set_user_next_human_race", "Native_SetNextRace", 1);
    register_native("pr_get_user_next_human_race", "Native_GetNextRace", 1);

    register_native("pr_get_human_race_info", "Native_GetInfo");
    register_native("pr_set_human_race_info", "Native_SetInfo");

    register_native("pr_get_human_race_attribute", "Native_GetAttr");
    register_native("pr_set_human_race_attribute", "Native_SetAttr");

    register_native("pr_open_humans_menu", "Native_HumansMenu", 1);

    register_native("pr_apply_human_attributes", "Native_ApplyAttr", 1);

    /* Future Updates
     * --------------
     * Change Human Class Info and Attributes
     * for one or more users.
     */

    // register_native("pr_get_user_human_race_info", "Native_GetUserInfo");
    // register_native("pr_set_user_human_race_info", "Native_SetUserInfo");

    // register_native("pr_get_user_human_race_attribute", "Native_GetUserAttr");
    // register_native("pr_set_user_human_race_attribute", "Native_SetUserAttr");
}

public bool: Native_IsHuman(id)
{
    return bHuman[id];
}

public Native_Register(sysName[], name[], model[], Array: soundsHurt, Array: soundsDie)
{
    param_convert(1);
    param_convert(2);
    param_convert(3);

    if(HumanExists(sysName))
    {
        log_message("CLASS EXISTS %s", sysName);
        return -1;
    }

    ArrayPushString(ClassInfo[Human_SystemName], sysName);
    ArrayPushString(ClassInfo[Human_Name], name);

    precache_model(PlayerModelPath(model));

    ArrayPushString(ClassInfo[Human_Model], model);

    PrecacheSoundArray(soundsDie);
    PrecacheSoundArray(soundsHurt);

    ArrayPushCell(ClassInfo[Human_SoundsDie], soundsDie);
    ArrayPushCell(ClassInfo[Human_SoundsPain], soundsHurt);

    ArrayPushCell(ClassAttributes[Human_Health], 100);
    ArrayPushCell(ClassAttributes[Human_SpeedAdd], 0.0);
    ArrayPushCell(ClassAttributes[Human_Gravity], 800);
    ArrayPushCell(ClassAttributes[Human_Painshock], 1.0);
    ArrayPushCell(ClassAttributes[Human_Flags], 0);
    ArrayPushCell(ClassAttributes[Human_MenuShow], MenuShow_Yes);

    iClassCount++;
    return iClassCount - 1;
}

public Native_MainAttributes(class, hp, Float:speed, gravity, Float:painshock,/*  Float: armorRes, Float: armorDmg ,*/flags/* , Selectable: select */)
{
    if(!ValidRace(class))
    {
        log_error(AMX_ERR_NATIVE, "Class Id Invalid");
        return 0;
    }

    ArraySetCell(ClassAttributes[Human_Health], class, hp);
    ArraySetCell(ClassAttributes[Human_SpeedAdd], class, speed);
    ArraySetCell(ClassAttributes[Human_Gravity], class, gravity);
    ArraySetCell(ClassAttributes[Human_Painshock], class, painshock);
    //ArrayPushCell(ClassAttributes[Human_ArmorResistance], armorRes);
    //ArrayPushCell(ClassAttributes[Human_ArmorDamage], armorDmg);
    ArraySetCell(ClassAttributes[Human_Flags], class, flags);
    //ArrayPushCell(ClassAttributes[Human_Selectable], select);

    return 1;
}

public Native_Count()
{
    return iClassCount;
}


public Native_Users(bool: alive)
{
    static num;

    for(new i = 1; i <= MAX_PLAYERS; i++)
    {
        if(bHuman[i] && ((alive && is_user_alive(i)) || (!alive && !is_user_alive(i))))
            num++;
    }

    return num;
}


public Native_NextAvailable(id)
{
    return FirstAvailableClass(id);
}

public Native_SetHuman(id, bool:human, attacker, bool:spawn, bool:flags)
{
    if(!IsPlayer(id))
    {
        log_error(AMX_ERR_NATIVE, "CLIENT INVALID");
        return 0;
    }

    Transform(id, human, attacker, spawn, flags);

    return 1;
}

public Native_SetRace(id, race)
{
    if(!IsPlayer(id))
    {
        log_error(AMX_ERR_NATIVE, "CLIENT INVALID");
        return 0;
    }

    if(!ValidRace(race))
    {
        log_error(AMX_ERR_NATIVE, "INVALID RACE ID");
        return 0;
    }

    iNextClass[id] = race;

    if(bHuman[id])
        Transform(id, true, -1, true, false);

    return 1;
}

public Native_GetRace(id)
{
    if(!IsPlayerId(id))
    {
        log_error(AMX_ERR_NATIVE, "CLIENT INVALID");
        return 0;
    }

    return iClass[id];
}

public Native_SetNextRace(id, race)
{
    if(!IsPlayerId(id))
    {
        log_error(AMX_ERR_NATIVE, "CLIENT INVALID");
        return 0;
    }

    if(!ValidRace(race))
    {
        log_error(AMX_ERR_NATIVE, "INVALID RACE ID");
        return 0;
    }

    iNextClass[id] = race;

    return 1;
}

public Native_GetNextRace(id)
{
    if(!IsPlayerId(id))
    {
        log_error(AMX_ERR_NATIVE, "CLIENT INVALID");
        return 0;
    }
    
    return iNextClass[id];
}

public any:Native_GetInfo(plgId, argc)
{
    if(argc < 2)
    {
        log_error(AMX_ERR_NATIVE, "NOT ENOUGH PARAMS");
        return 0;
    }

    new class = get_param(1);

    if(!ValidRace(class))
    {
        log_error(AMX_ERR_NATIVE, "INVALID RACE ID");
        return 0;
    }

    new HumanInformation: id = HumanInformation: get_param(2);

    if(!ValidInfo(id))
    {
        log_error(AMX_ERR_NATIVE, "INVALID HUMAN INFORMATION ID");
        return 0;
    }

    switch(id)
    {
        case Human_SystemName:
        {
            log_error(AMX_ERR_NATIVE, "SYSTEM NAME CANNOT BE CHANGED");
            return 0;
        }

        case Human_Name, Human_Model:
        {
            if(argc < 4)
            {
                log_error(AMX_ERR_NATIVE, "NOT ENOUGH PARAMS");
                return 0;
            }

            new szString[32];
            ArrayGetString(any:ClassInfo[id], class, szString, charsmax(szString));

            set_string(3, szString, get_param(4));

            return 1;
        }

        default:
        {
            return ArrayGetCell(any:ClassInfo[id], class);
        }
    }

    return 1;
}

public any:Native_SetInfo(plgId, argc)
{
    if(argc < 3)
    {
        log_error(AMX_ERR_NATIVE, "NOT ENOUGH PARAMS");
        return 0;
    }

    new class = get_param(1);

    if(!ValidRace(class))
    {
        log_error(AMX_ERR_NATIVE, "INVALID RACE ID");
        return 0;
    }

    new HumanInformation: id = HumanInformation: get_param(2);

    if(!ValidInfo(id))
    {
        log_error(AMX_ERR_NATIVE, "INVALID HUMAN INFORMATION ID");
        return 0;
    }

    switch(id)
    {
        case Human_SystemName:
        {
            log_error(AMX_ERR_NATIVE, "SYSTEM NAME CANNOT BE CHANGED");
            return 0;
        }

        case Human_Name, Human_Model:
        {
            new szString[32];
            get_string(3, szString, charsmax(szString));

            ArraySetString(any:ClassInfo[id], class, szString);
        }

        default:
        {
            ArraySetCell(any:ClassInfo[id], class, get_param(3));
        }
    }

    return 1;
}

public any:Native_GetAttr(plgId, argc)
{
    if(argc < 2)
    {
        log_error(AMX_ERR_NATIVE, "NOT ENOUGH PARAMS");
        return 0;
    }

    new class = get_param(1);

    if(!ValidRace(class))
    {
        log_error(AMX_ERR_NATIVE, "INVALID RACE ID");
        return 0;
    }

    new HumanAttributes: id = HumanAttributes: get_param(2);

    if(!ValidAttribute(id))
    {
        log_error(AMX_ERR_NATIVE, "INVALID HUMAN ATTRIBUTE ID");
        return 0;
    }

    switch(id)
    {
        case Human_Health,
            Human_Gravity,
            Human_Flags,
            Human_MenuShow:
        {
            return ArrayGetCell(any:ClassAttributes[id], class);
        }

        case Human_SpeedAdd,
            Human_Painshock:
        {
            if(argc == 3)
            {
                new Float: flValue = ArrayGetCell(any:ClassAttributes[id], class);
                set_float_byref(3, flValue);
            }
            else return ArrayGetCell(any:ClassAttributes[id], class);
        }
    }

    return 1;
}

public any:Native_SetAttr(plgId, argc)
{
    if(argc < 3)
    {
        log_error(AMX_ERR_NATIVE, "NOT ENOUGH PARAMS");
        return 0;
    }

    new class = get_param(1);

    if(!ValidRace(class))
    {
        log_error(AMX_ERR_NATIVE, "INVALID RACE ID");
        return 0;
    }

    new HumanAttributes: id = HumanAttributes: get_param(2);

    if(!ValidAttribute(id))
    {
        log_error(AMX_ERR_NATIVE, "INVALID HUMAN ATTRIBUTE ID");
        return 0;
    }

    switch(id)
    {
        case Human_Health,
            Human_Gravity,
            Human_Flags,
            Human_MenuShow:
        {
            new value = get_param(3);
            ArraySetCell(any:ClassAttributes[id], class, value);
        }

        case Human_SpeedAdd,
            Human_Painshock:
        {
            new Float: flValue = get_param_f(3);
            ArraySetCell(any:ClassAttributes[id], class, flValue);
        }
    }

    return 1;
}

public Native_HumansMenu(id)
{
    RaceMenu(id);
}

public Native_ApplyAttr(id, bool:hp, bool:gravity, bool:speed)
{
    if(!IsPlayer(id))
    {
        log_error(AMX_ERR_NATIVE, "INVALID CLIENT");
        return 0;
    }

    if(!bHuman[id])
        return 0;

    if(hp)
    {
        new hp = ArrayGetCell(ClassAttributes[Human_Health], iClass[id]);
        set_entvar(id, var_health, float(hp));
        set_entvar(id, var_max_health, float(hp));
    }

    if(gravity)
    {
        new gravity = ArrayGetCell(ClassAttributes[Human_Gravity], iClass[id]);
        set_entvar(id, var_gravity, float(gravity)/800.0);
    }

    if(speed)
    {
        ExecuteHamB(Ham_CS_Player_ResetMaxSpeed, id);
    }

    return 1;
}


/* -> Plugin Functions <- */
public plugin_precache()
{
    ClassInfo[Human_SystemName]               = ArrayCreate(32, 1);
    ClassInfo[Human_Name]                     = ArrayCreate(32, 1);
    ClassInfo[Human_Model]                    = ArrayCreate(32, 1);
    ClassInfo[Human_SoundsPain]               = ArrayCreate(1, 1);
    ClassInfo[Human_SoundsDie]                = ArrayCreate(1, 1);

    ClassAttributes[Human_Health]             = ArrayCreate(1, 1);
    ClassAttributes[Human_SpeedAdd]           = ArrayCreate(1, 1);
    ClassAttributes[Human_Gravity]            = ArrayCreate(1, 1);
    ClassAttributes[Human_Painshock]          = ArrayCreate(1, 1);
    ClassAttributes[Human_Flags]              = ArrayCreate(1, 1);
    ClassAttributes[Human_MenuShow]           = ArrayCreate(1, 1);

    glForwards[FWD_TRANSFORM] = CreateMultiForward("Plague_Humanize", ET_CONTINUE, FP_CELL, FP_CELL, FP_CELL, FP_CELL, FP_CELL);
    glForwards[FWD_TRANSFORM_POST] = CreateMultiForward("Plague_Humanize_Post", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL, FP_CELL, FP_CELL);
    glForwards[FWD_MENU_SHOW] = CreateMultiForward("Plague_Human_MenuShow", ET_CONTINUE, FP_CELL, FP_CELL);
    glForwards[FWD_CLASS_SELECTED] = CreateMultiForward("Plague_Human_Selected", ET_CONTINUE, FP_CELL, FP_CELL);
}

public plugin_init()
{
    register_plugin(pluginName, pluginVer, pluginAuthor);

    RegisterHookChain(RG_CBasePlayer_Spawn, "Player_Spawn_Post", 1);
    RegisterHookChain(RG_CBasePlayer_TakeDamage, "TakeDamage_Post", 1);
    RegisterHookChain(RG_CBasePlayer_Pain, "Pain");
    RegisterHookChain(RG_CBasePlayer_DeathSound, "DeathSound");

    RegisterHam(Ham_CS_Player_ResetMaxSpeed, "player", "ResetSpeed_Post", 1);

    register_clcmd("say /hm", "cmdHm");
}

public client_connect(id)
{
    bHuman[id] = true;
}

public cmdHm(id)
{
    RaceMenu(id);
}

public Player_Spawn_Post(id)
{
    if(get_member(id, m_bJustConnected) || !bHuman[id])
        return;

    MakeHuman(id, -1, true, false);
}

public TakeDamage_Post(id, inflictor, attacker, Float: flDamage, dmgBits)
{
    if(id == attacker || !bHuman[id] || bHuman[attacker])
        return;

    new Float: flPainshock = ArrayGetCell(ClassAttributes[Human_Painshock], iClass[id]);

    set_member(id, m_flVelocityModifier, flPainshock);
}

public Pain(id)
{
    if(!bHuman[id])
        return HC_CONTINUE;
    
    new Array: a = ArrayGetCell(ClassInfo[Human_SoundsPain], iClass[id]);

    if(a == Invalid_Array)
        return HC_CONTINUE;

    new rand = random_num(0, ArraySize(a)-1);

    new szSound[MAX_RESOURCE_PATH_LENGTH];
    ArrayGetString(a, rand, szSound, charsmax(szSound));

    emit_sound(id, CHAN_VOICE, szSound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

    return HC_SUPERCEDE;
}

public DeathSound(id)
{
    if(!bHuman[id])
        return HC_CONTINUE;
    
    new Array: a = ArrayGetCell(ClassInfo[Human_SoundsDie], iClass[id]);

    if(a == Invalid_Array)
        return HC_CONTINUE;

    new rand = random_num(0, ArraySize(a)-1);

    new szSound[MAX_RESOURCE_PATH_LENGTH];
    ArrayGetString(a, rand, szSound, charsmax(szSound));

    emit_sound(id, CHAN_VOICE, szSound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

    return HC_SUPERCEDE;
}

public ResetSpeed_Post(id)
{
    if(!bHuman[id])
        return;

    new Float: flSpeed = ArrayGetCell(ClassAttributes[Human_SpeedAdd], iClass[id]);

    new Float: maxspeed = get_entvar(id, var_maxspeed);
    maxspeed += flSpeed;

    set_entvar(id, var_maxspeed, maxspeed);
}