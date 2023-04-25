/* -> Semicolon <- */
#pragma semicolon 1


/* -> Includes <- */
#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <reapi>
#include <xs>

#include <plague_const>
#include <plague_zombie_const>
#include <plague_human>


/* -> Plugin Info <- */
new const pluginName[ ] = "[Plague] Zombie Class";
new const pluginVer[ ] = "v1.0";
new const pluginAuthor[ ] = "DeclineD";


/* -> Default Knife Time <- */
const Float: flKnifeAttack1Time = 0.4;
const Float: flKnifeAttack1Miss = 0.35;

const Float: flKnifeAttack2Time = 1.1;
const Float: flKnifeAttack2Miss = 1.0;


/* -> Cvars <- */
enum _:plgcvars {
    PC_KBPOWER,
    PC_KBVERTICAL,
    PC_KBON,
    PC_KBCLASS,
    PC_KBDUCK,
    PC_KBDISTANCE,
    PC_KBDAMAGE
};

new glbCvars[plgcvars];


/* -> Knockback <- */
new Float:kb_weapon_power[] = 
{
	-1.0,	// ---
	1.2,	// P228
	-1.0,	// ---
	3.5,	// SCOUT
	-1.0,	// ---
	4.0,	// XM1014
	-1.0,	// ---
	1.3,	// MAC10
	2.5,	// AUG
	-1.0,	// ---
	1.2,	// ELITE
	1.0,	// FIVESEVEN
	1.2,	// UMP45
	2.25,	// SG550
	2.25,	// GALIL
	2.25,	// FAMAS
	1.1,	// USP
	1.0,	// GLOCK18
	2.5,	// AWP
	1.25,	// MP5NAVY
	2.25,	// M249
	4.0,	// M3
	2.5,	// M4A1
	1.2,	// TMP
	3.25,	// G3SG1
	-1.0,	// ---
	2.15,	// DEAGLE
	2.5,	// SG552
	3.0,	// AK47
	-1.0,	// ---
	1.0,	// P90
	-1.0 // ---
};


/* -> Client <- */
#define IsPlayer(%0) ( ( 0 < %0 ) && ( %0 <= MAX_PLAYERS ) && is_user_connected(%0) )
#define IsPlayerId(%0) ( ( 0 < %0 ) && ( %0 <= MAX_PLAYERS ) )
#define PlayerModelPath(%0) fmt("models/player/%s/%s.mdl", %0, %0)

new bool: bZombie[ MAX_PLAYERS + 1 ];

new iClass[ MAX_PLAYERS + 1 ];
new iNextClass[ MAX_PLAYERS + 1 ];


/* -> Class <- */
#define ValidRace(%0) ( ( 0 <= %0 ) && ( %0 < iClassCount ) )
#define ValidInfo(%0) ( ( ZombieInformation:0 <= %0 ) && %0 < ZombieInformation )
#define ValidAttribute(%0) ( ( ZombieAttributes:0 <= %0 ) && %0 < ZombieAttributes )

new iClassCount;

new ClassInfo[ZombieInformation];
new ClassAttributes[ZombieAttributes];

// new UserClassInfo[MAX_PLAYERS + 1][ZombieInformation];
// new UserClassAttributes[MAX_PLAYERS + 1][ZombieAttributes];


/* -> Forwards <- */
enum fwds {
    FWD_TRANSFORM,
    FWD_TRANSFORM_POST,
    FWD_MENU_SHOW,
    FWD_CLASS_SELECTED
}

new glForwards[fwds];


/* -> Private Functions <- */
ZombieExists(sysName[])
{
    new szName[32];
    for(new i = 0; i < iClassCount; i++)
    {
        ArrayGetString(ClassInfo[Zombie_SystemName], i, szName, charsmax(szName));

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
    flags = ArrayGetCell(ClassAttributes[Zombie_Flags], class);

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

MakeZombie(id, attacker, bool:spawn, bool:flags, bool:health)
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
        ArrayGetString(ClassInfo[Zombie_Model], iClass[id], szModel, charsmax(szModel));
        rg_set_user_model(id, szModel, true);

        ArrayGetString(ClassInfo[Zombie_ClawModel], iClass[id], szModel, charsmax(szModel));
        set_entvar(id, var_viewmodel, szModel);
        set_entvar(id, var_weaponmodel, "");

        if(health)
        {
            new hp = ArrayGetCell(ClassAttributes[Zombie_Health], iClass[id]);
            set_entvar(id, var_health, float(hp));
            set_entvar(id, var_max_health, float(hp));
        }

        if(spawn)
        {
            new Array: a = ArrayGetCell(ClassInfo[Zombie_SoundsSpawn], iClass[id]);

            if(a > Invalid_Array)
            {
                new rand = random_num(0, ArraySize(a)-1);

                new szSound[MAX_RESOURCE_PATH_LENGTH];
                ArrayGetString(a, rand, szSound, charsmax(szSound));

                emit_sound(id, CHAN_VOICE, szSound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
            }
        }

        new gravity = ArrayGetCell(ClassAttributes[Zombie_Gravity], iClass[id]);
        set_entvar(id, var_gravity, float(gravity)/800.0);

        ExecuteHamB(Ham_CS_Player_ResetMaxSpeed, id);

        if(attacker > -1)
            TransformNotice(id, attacker);
    }

    set_member(id, m_iTeam, TEAM_TERRORIST);
    rg_set_user_team(id, TEAM_TERRORIST);

    ExecuteForward(glForwards[FWD_TRANSFORM_POST], ret, id, attacker, oldclass, iNextClass[id], spawn);
}

Transform(id, bool:zombie, attacker, bool:spawn, bool:flags, bool:health)
{
    if(!IsPlayer(id))
    {
        log_message("%i not connected", id);
        return 0;
    }

    if(zombie)
        MakeZombie(id, attacker, spawn, flags, health);

    bZombie[id] = zombie;
    pr_set_user_human(id, !zombie, attacker, spawn, flags, health);

    return 1;
}

bool: CanShow(id, class)
{
    new MenuShow: show = ArrayGetCell(ClassAttributes[Zombie_MenuShow], class);
    
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
        new flags = ArrayGetCell(ClassAttributes[Zombie_Flags], class);

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
        
        ArrayGetString(ClassInfo[Zombie_Name], i, szName, charsmax(szName));
        formatex(szFormat, charsmax(szFormat), "%s%s", (iNextClass[id] == i ? "\d" : ""), szName);
        menu_additem(menu, szFormat, fmt("%i", i));
    }

    menu_display(id, menu);
}

ChatSelectionInfo(id)
{
    new szName[32];
    new hp = ArrayGetCell(ClassAttributes[Zombie_Health], iNextClass[id]),
        gravity = ArrayGetCell(ClassAttributes[Zombie_Gravity], iNextClass[id]),
        Float: speed = ArrayGetCell(ClassAttributes[Zombie_SpeedAdd], iNextClass[id]),
        Float: kb = ArrayGetCell(ClassAttributes[Zombie_Knockback], iNextClass[id]);

    ArrayGetString(ClassInfo[Zombie_Name], iNextClass[id], szName, charsmax(szName));

    client_print_color(id, 0, "^x04[ZP] ^x01Next infection your ^x03zombie race ^x01will be: ^x04%s.", szName);
    client_print_color(id, 0, "^x04[ZP] ^x01Health: ^x04%i ^x03| ^x01Gravity: ^x04%i ^x03| ^x01Speed: ^x04%.2f ^x03| ^x01Knockback: ^x04%.2f%%^x01.", hp, gravity, 250.0 + speed, kb*100.0);
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
    register_native("pr_is_zombie", "Native_IsZombie", 1);

    register_native("pr_register_zombie", "Native_Register", 1);
    register_native("pr_zombie_attributes", "Native_MainAttributes", 1);
    register_native("pr_zombie_races_count", "Native_Count", 1);

    register_native("pr_next_available_zombie_race", "Native_NextAvailable", 1);

    register_native("pr_get_zombie_users_count", "Native_Users", 1);
    register_native("pr_set_user_zombie", "Native_SetZombie", 1);

    register_native("pr_set_user_zombie_race", "Native_SetRace", 1);
    register_native("pr_get_user_zombie_race", "Native_GetRace", 1);

    register_native("pr_set_user_next_zombie_race", "Native_SetNextRace", 1);
    register_native("pr_get_user_next_zombie_race", "Native_GetNextRace", 1);

    register_native("pr_get_zombie_race_info", "Native_GetInfo");
    register_native("pr_set_zombie_race_info", "Native_SetInfo");

    register_native("pr_get_zombie_race_attribute", "Native_GetAttr");
    register_native("pr_set_zombie_race_attribute", "Native_SetAttr");

    register_native("pr_open_zombies_menu", "Native_ZombiesMenu", 1);

    register_native("pr_apply_zombie_attributes", "Native_ApplyAttr", 1);

    /* Future Updates
     * --------------
     * Change Zombie Class Info and Attributes
     * for one or more users.
     */

    // register_native("pr_get_user_zombie_race_info", "Native_GetUserInfo");
    // register_native("pr_set_user_zombie_race_info", "Native_SetUserInfo");

    // register_native("pr_get_user_zombie_race_attribute", "Native_GetUserAttr");
    // register_native("pr_set_user_zombie_race_attribute", "Native_SetUserAttr");
}

public bool: Native_IsZombie(id)
{
    return bZombie[id];
}

public Native_Register(sysName[], name[], model[], clawmodel[], Array: soundsHurt, Array: soundsSpawn, Array: soundsDie)
{
    param_convert(1);
    param_convert(2);
    param_convert(3);
    param_convert(4);

    if(ZombieExists(sysName))
    {
        log_message("CLASS EXISTS %s", sysName);
        return -1;
    }

    ArrayPushString(ClassInfo[Zombie_SystemName], sysName);
    ArrayPushString(ClassInfo[Zombie_Name], name);

    precache_model(PlayerModelPath(model));

    ArrayPushString(ClassInfo[Zombie_Model], model);

    precache_model(clawmodel);

    ArrayPushString(ClassInfo[Zombie_ClawModel], clawmodel);

    PrecacheSoundArray(soundsDie);
    PrecacheSoundArray(soundsSpawn);
    PrecacheSoundArray(soundsHurt);

    ArrayPushCell(ClassInfo[Zombie_SoundsDie], soundsDie);
    ArrayPushCell(ClassInfo[Zombie_SoundsSpawn], soundsSpawn);
    ArrayPushCell(ClassInfo[Zombie_SoundsPain], soundsHurt);

    ArrayPushCell(ClassAttributes[Zombie_Health], 100);
    ArrayPushCell(ClassAttributes[Zombie_SpeedAdd], 0.0);
    ArrayPushCell(ClassAttributes[Zombie_Gravity], 800);
    ArrayPushCell(ClassAttributes[Zombie_Painshock], 1.0);
    ArrayPushCell(ClassAttributes[Zombie_Knockback], 0.0);
    ArrayPushCell(ClassAttributes[Zombie_Flags], 0);
    ArrayPushCell(ClassAttributes[Zombie_MenuShow], MenuShow_Yes);
    ArrayPushCell(ClassAttributes[Zombie_AttackDamage], 0.0);
    ArrayPushCell(ClassAttributes[Zombie_Attack2Damage], 0.0);
    ArrayPushCell(ClassAttributes[Zombie_AttackDelay], 0.0); 
    ArrayPushCell(ClassAttributes[Zombie_AttackDelay2], 0.0);
    ArrayPushCell(ClassAttributes[Zombie_Attack2Delay], 0.0); 
    ArrayPushCell(ClassAttributes[Zombie_Attack2Delay1], 0.0);
    ArrayPushCell(ClassAttributes[Zombie_AttackDelayMiss], 0.0); 
    ArrayPushCell(ClassAttributes[Zombie_AttackDelayMiss2], 0.0);
    ArrayPushCell(ClassAttributes[Zombie_Attack2DelayMiss], 0.0); 
    ArrayPushCell(ClassAttributes[Zombie_Attack2DelayMiss1], 0.0);
    ArrayPushCell(ClassAttributes[Zombie_AttackDistance], 0.0);
    ArrayPushCell(ClassAttributes[Zombie_Attack2Distance], 0.0);

    iClassCount++;
    return iClassCount - 1;
}

public Native_MainAttributes(class, hp, Float:speed, gravity, Float:kb, Float:painshock, flags)
{
    if(!ValidRace(class))
    {
        log_error(AMX_ERR_NATIVE, "Class Id Invalid");
        return 0;
    }

    ArraySetCell(ClassAttributes[Zombie_Health], class, hp);
    ArraySetCell(ClassAttributes[Zombie_SpeedAdd], class, speed);
    ArraySetCell(ClassAttributes[Zombie_Gravity], class, gravity);
    ArraySetCell(ClassAttributes[Zombie_Painshock], class, painshock);
    ArraySetCell(ClassAttributes[Zombie_Knockback], class, kb);
    ArraySetCell(ClassAttributes[Zombie_Flags], class, flags);

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
        if(bZombie[i] && ((alive && is_user_alive(i)) || (!alive && !is_user_alive(i))))
            num++;
    }

    return num;
}


public Native_NextAvailable(id)
{
    return FirstAvailableClass(id);
}

public Native_SetZombie(id, bool:zombie, attacker, bool:spawn, bool:flags, bool:health)
{
    if(!IsPlayer(id))
    {
        log_error(AMX_ERR_NATIVE, "CLIENT INVALID");
        return 0;
    }

    Transform(id, zombie, attacker, spawn, flags, health);

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

    if(bZombie[id])
        Transform(id, true, -1, true, false, true);

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

    new ZombieInformation: id = ZombieInformation: get_param(2);

    if(!ValidInfo(id))
    {
        log_error(AMX_ERR_NATIVE, "INVALID ZOMBIE INFORMATION ID");
        return 0;
    }

    switch(id)
    {
        case Zombie_SystemName:
        {
            log_error(AMX_ERR_NATIVE, "SYSTEM NAME CANNOT BE CHANGED");
            return 0;
        }

        case Zombie_Name, Zombie_Model, Zombie_ClawModel:
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

    new ZombieInformation: id = ZombieInformation: get_param(2);

    if(!ValidInfo(id))
    {
        log_error(AMX_ERR_NATIVE, "INVALID ZOMBIE INFORMATION ID");
        return 0;
    }

    switch(id)
    {
        case Zombie_SystemName:
        {
            log_error(AMX_ERR_NATIVE, "SYSTEM NAME CANNOT BE CHANGED");
            return 0;
        }

        case Zombie_Name, Zombie_Model, Zombie_ClawModel:
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

    new ZombieAttributes: id = ZombieAttributes: get_param(2);

    if(!ValidAttribute(id))
    {
        log_error(AMX_ERR_NATIVE, "INVALID ZOMBIE ATTRIBUTE ID");
        return 0;
    }

    switch(id)
    {
        case Zombie_Health,
            Zombie_Gravity,
            Zombie_Flags,
            Zombie_MenuShow:
        {
            return ArrayGetCell(any:ClassAttributes[id], class);
        }

        default:
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

    new ZombieAttributes: id = ZombieAttributes: get_param(2);

    if(!ValidAttribute(id))
    {
        log_error(AMX_ERR_NATIVE, "INVALID ZOMBIE ATTRIBUTE ID");
        return 0;
    }

    switch(id)
    {
        case Zombie_Health,
            Zombie_Gravity,
            Zombie_Flags,
            Zombie_MenuShow:
        {
            new value = get_param(3);
            ArraySetCell(any:ClassAttributes[id], class, value);
        }

        default:
        {
            new Float: flValue = get_param_f(3);
            ArraySetCell(any:ClassAttributes[id], class, flValue);
        }
    }

    return 1;
}

public Native_ApplyAttr(id, bool:hp, bool:gravity, bool:speed)
{
    if(!IsPlayer(id))
    {
        log_error(AMX_ERR_NATIVE, "INVALID CLIENT");
        return 0;
    }

    if(!bZombie[id])
        return 0;

    if(hp)
    {
        new hp = ArrayGetCell(ClassAttributes[Zombie_Health], iClass[id]);
        set_entvar(id, var_health, float(hp));
        set_entvar(id, var_max_health, float(hp));
    }

    if(gravity)
    {
        new gravity = ArrayGetCell(ClassAttributes[Zombie_Gravity], iClass[id]);
        set_entvar(id, var_gravity, float(gravity)/800.0);
    }

    if(speed)
    {
        ExecuteHamB(Ham_CS_Player_ResetMaxSpeed, id);
    }

    return 1;
}

public Native_ZombiesMenu(id)
{
    RaceMenu(id);
}


/* -> Plugin Functions <- */
public plugin_precache()
{
    ClassInfo[Zombie_SystemName]               = ArrayCreate(32, 1);
    ClassInfo[Zombie_Name]                     = ArrayCreate(32, 1);
    ClassInfo[Zombie_Model]                    = ArrayCreate(32, 1);
    ClassInfo[Zombie_ClawModel]                = ArrayCreate(128, 1);
    ClassInfo[Zombie_SoundsPain]               = ArrayCreate(1, 1);
    ClassInfo[Zombie_SoundsSpawn]              = ArrayCreate(1, 1);
    ClassInfo[Zombie_SoundsDie]                = ArrayCreate(1, 1);

    ClassAttributes[Zombie_Health]             = ArrayCreate(1, 1);
    ClassAttributes[Zombie_SpeedAdd]           = ArrayCreate(1, 1);
    ClassAttributes[Zombie_Gravity]            = ArrayCreate(1, 1);
    ClassAttributes[Zombie_Painshock]          = ArrayCreate(1, 1);
    ClassAttributes[Zombie_Knockback]          = ArrayCreate(1, 1);
    ClassAttributes[Zombie_Flags]              = ArrayCreate(1, 1);
    ClassAttributes[Zombie_MenuShow]           = ArrayCreate(1, 1);

    ClassAttributes[Zombie_AttackDamage]       = ArrayCreate(1, 1);
    ClassAttributes[Zombie_Attack2Damage]      = ArrayCreate(1, 1);
    ClassAttributes[Zombie_AttackDelay]        = ArrayCreate(1, 1); 
    ClassAttributes[Zombie_AttackDelay2]       = ArrayCreate(1, 1);
    ClassAttributes[Zombie_Attack2Delay]       = ArrayCreate(1, 1); 
    ClassAttributes[Zombie_Attack2Delay1]      = ArrayCreate(1, 1);
    ClassAttributes[Zombie_AttackDelayMiss]    = ArrayCreate(1, 1); 
    ClassAttributes[Zombie_AttackDelayMiss2]   = ArrayCreate(1, 1);
    ClassAttributes[Zombie_Attack2DelayMiss]   = ArrayCreate(1, 1); 
    ClassAttributes[Zombie_Attack2DelayMiss1]  = ArrayCreate(1, 1);
    ClassAttributes[Zombie_AttackDistance]     = ArrayCreate(1, 1);
    ClassAttributes[Zombie_Attack2Distance]    = ArrayCreate(1, 1);

    glForwards[FWD_TRANSFORM] = CreateMultiForward("Plague_Zombiefy", ET_CONTINUE, FP_CELL, FP_CELL, FP_CELL, FP_CELL, FP_CELL);
    glForwards[FWD_TRANSFORM_POST] = CreateMultiForward("Plague_Zombiefy_Post", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL, FP_CELL, FP_CELL);
    glForwards[FWD_MENU_SHOW] = CreateMultiForward("Plague_Zombie_MenuShow", ET_CONTINUE, FP_CELL, FP_CELL);
    glForwards[FWD_CLASS_SELECTED] = CreateMultiForward("Plague_Zombie_Selected", ET_CONTINUE, FP_CELL, FP_CELL);
}

public plugin_init()
{
    register_plugin(pluginName, pluginVer, pluginAuthor);

    glbCvars[PC_KBPOWER] = register_cvar("plague_knockback_power", "1");
    glbCvars[PC_KBON] = register_cvar("plague_knockback_on", "1");
    glbCvars[PC_KBCLASS] = register_cvar("plague_knockback_class", "1");
    glbCvars[PC_KBVERTICAL] = register_cvar("plague_knockback_vertical", "1");
    glbCvars[PC_KBDUCK] = register_cvar("plague_knockback_duck_reduction", "0.25");
    glbCvars[PC_KBDISTANCE] = register_cvar("plague_knockback_max_distance", "750.0");

    RegisterHookChain(RG_CBasePlayer_TakeDamage, "TakeDamage_Post", 1);
    RegisterHookChain(RG_CBasePlayer_TraceAttack, "TraceAttack_Post", 1);
    RegisterHookChain(RG_CBasePlayer_Pain, "Pain");
    RegisterHookChain(RG_CBasePlayer_DeathSound, "DeathSound");

    RegisterHam(Ham_Item_Deploy, "weapon_knife", "Hands_Post", 1);
    RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_knife", "HandsAttack1_Post", 1);
    RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_knife", "HandsAttack2_Post", 1);
    RegisterHam(Ham_Spawn, "player", "Player_Spawn_Post", 1);

    RegisterHam(Ham_CS_Player_ResetMaxSpeed, "player", "ResetSpeed_Post", 1);

    register_clcmd("say /zm", "cmdZm");
    register_clcmd("say /zombie", "cmdZomb");
}

public client_connect(id)
{
    bZombie[id] = false;
}

public cmdZm(id)
{
    RaceMenu(id);
}

public cmdZomb(id)
{
    Transform(id, !bZombie[id], 0, true, false, true);
}

public Player_Spawn_Post(id)
{
    if(get_member(id, m_bJustConnected) || !bZombie[id])
        return;

    Transform(id, true, -1, true, false, true);
}

public TakeDamage_Post(id, inflictor, attacker, Float: flDamage, dmgBits)
{
    if(id == attacker || !bZombie[id] || bZombie[attacker])
        return;

    new Float: flPainshock = ArrayGetCell(ClassAttributes[Zombie_Painshock], iClass[id]);

    set_member(id, m_flVelocityModifier, flPainshock);
}

public Pain(id)
{
    if(!bZombie[id])
        return HC_CONTINUE;
    
    new Array: a = ArrayGetCell(ClassInfo[Zombie_SoundsPain], iClass[id]);

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
    if(!bZombie[id])
        return HC_CONTINUE;
    
    new Array: a = ArrayGetCell(ClassInfo[Zombie_SoundsDie], iClass[id]);

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
    if(!bZombie[id])
        return;

    new Float: flSpeed = ArrayGetCell(ClassAttributes[Zombie_SpeedAdd], iClass[id]);

    new Float: maxspeed = get_entvar(id, var_maxspeed);
    maxspeed += flSpeed;

    set_entvar(id, var_maxspeed, maxspeed);
}

public TraceAttack_Post(victim, attacker, Float:flDamage, Float:vecDir[3], tr, dmgBits)
{
    if((victim == attacker) ||
    bZombie[attacker] || 
    pr_is_human(victim) ||
    !IsPlayer(victim) || 
    !IsPlayer(attacker) ||
    (~dmgBits & DMG_BULLET) ||
    (~dmgBits & DMG_SLASH) ||
    get_pcvar_num(glbCvars[PC_KBON]) <= 0)
        return;

    static bool:bPower; bPower = bool:get_pcvar_num(glbCvars[PC_KBPOWER]);
    static bool:bClass; bClass = bool:get_pcvar_num(glbCvars[PC_KBCLASS]);
    static bool:bVertical; bVertical = bool:get_pcvar_num(glbCvars[PC_KBVERTICAL]);
    static bool:bDamage; bDamage = bool:get_pcvar_num(glbCvars[PC_KBDAMAGE]);
    static Float: flDuck; flDuck = get_pcvar_float(glbCvars[PC_KBDUCK]);
    static Float: flDistance; flDistance = get_pcvar_float(glbCvars[PC_KBDISTANCE]);

    static Float: vecOrigin[2][3];
    get_entvar(victim, var_origin, vecOrigin[0]);
    get_entvar(attacker, var_origin, vecOrigin[1]);

    if(xs_vec_distance(vecOrigin[0], vecOrigin[1]) > flDistance)
        return;

    static flags; flags = get_entvar(victim, var_flags);

    static bool: bDuck; bDuck = ((flags & FL_DUCKING) && (flags & FL_ONGROUND));

    static Float: vecNew[3];
    xs_vec_copy(vecDir, vecNew);

    static Float: vecVelocity[3];
    get_entvar(victim, var_velocity, vecVelocity);

    if(!bVertical)
        vecNew[2] = 0.0;

    new Float: flPower = 0.0;

    if(bPower)
    {
        static item; item = get_member(attacker, m_pActiveItem);

        if((get_member(item, m_iId) > MAX_WEAPONS || get_entvar(item, var_impulse) > 0))
            get_entvar(item, var_fuser4, flPower);
        else
            flPower = kb_weapon_power[get_member(item, m_iId)];

        xs_vec_mul_scalar(vecNew, flPower, vecNew);
    }

    if(bDamage)
    {
        flPower = flDamage;
        xs_vec_mul_scalar(vecNew, flPower, vecNew);
    }

    if(bClass)
    {
        flPower = ArrayGetCell(ClassAttributes[Zombie_Knockback], iClass[victim]);
        xs_vec_mul_scalar(vecNew, flPower, vecNew);
    }

    if(bDuck)
    {
        flPower = flDuck;
        xs_vec_mul_scalar(vecNew, flPower, vecNew);
    }

    xs_vec_add(vecVelocity, vecNew, vecVelocity);

    set_entvar(victim, var_velocity, vecVelocity);
}

public Hands_Post(item)
{
    if(is_nullent(item))
        return;

    new player = get_member(item, m_pPlayer);

    if(!bZombie[player])
        return;

    new szModel[MAX_RESOURCE_PATH_LENGTH];
    ArrayGetString(ClassInfo[Zombie_ClawModel], iClass[player], szModel, charsmax(szModel));
    
    set_entvar(player, var_viewmodel, szModel);
    set_entvar(player, var_weaponmodel, "");

    static Float: slashDmg,
        Float: stabDmg,
        Float: slashDistance,
        Float: stabDistance;
    
    slashDmg = ArrayGetCell(ClassAttributes[Zombie_AttackDamage], iClass[player]);
    stabDmg = ArrayGetCell(ClassAttributes[Zombie_Attack2Damage], iClass[player]);
    slashDistance = ArrayGetCell(ClassAttributes[Zombie_AttackDistance], iClass[player]);
    stabDistance = ArrayGetCell(ClassAttributes[Zombie_Attack2Distance], iClass[player]);

    if(slashDmg < 0.0)
    {
        set_member(player, m_Knife_flSwingBaseDamage, slashDmg);
        set_member(player, m_Knife_flSwingBaseDamage_Fast, slashDmg);
    }
    
    if(stabDmg < 0.0)
        set_member(player, m_Knife_flStabBaseDamage, stabDmg);

    if(slashDistance < 0.0)
        set_member(player, m_Knife_flSwingDistance, slashDistance);

    if(stabDistance < 0.0)
        set_member(player, m_Knife_flStabDistance, stabDistance);
}

public HandsAttack1_Post(item)
{
    if(is_nullent(item))
        return;

    new player = get_member(item, m_pPlayer);

    if(!bZombie[player])
        return;

    new Float: flAttackTime = get_member(item, m_Weapon_flNextPrimaryAttack);
    new Float: DelayStart;
    new Float: flAttack2Time;

    if(flKnifeAttack1Time-0.1 < flAttackTime <= flKnifeAttack1Time)
    {
        DelayStart = flKnifeAttack1Time - flAttackTime;

        flAttack2Time = ArrayGetCell(ClassAttributes[Zombie_AttackDelay2], iClass[player]);
        flAttackTime = ArrayGetCell(ClassAttributes[Zombie_AttackDelay], iClass[player]);

        if(flAttackTime > 0.0)
            set_member(item, m_Weapon_flNextPrimaryAttack, flAttackTime-DelayStart);

        if(flAttack2Time > 0.0)
            set_member(item, m_Weapon_flNextSecondaryAttack, flAttackTime-DelayStart);
    }
    else if(flKnifeAttack1Miss-0.1 > flAttackTime <= flKnifeAttack1Miss)
    {
        DelayStart = flKnifeAttack1Miss - flAttackTime;

        flAttack2Time = ArrayGetCell(ClassAttributes[Zombie_AttackDelayMiss2], iClass[player]);
        flAttackTime = ArrayGetCell(ClassAttributes[Zombie_AttackDelayMiss], iClass[player]);

        if(flAttackTime > 0.0)
            set_member(item, m_Weapon_flNextPrimaryAttack, flAttackTime-DelayStart);

        if(flAttack2Time > 0.0)
            set_member(item, m_Weapon_flNextSecondaryAttack, flAttackTime-DelayStart);
    }
}

public HandsAttack2_Post(item)
{
    if(is_nullent(item))
        return;

    new player = get_member(item, m_pPlayer);

    if(!bZombie[player])
        return;

    new Float: flAttack2Time = get_member(item, m_Weapon_flNextSecondaryAttack);
    new Float: DelayStart = 0.0;
    new Float: flAttackTime = 0.0;

    if(flKnifeAttack2Time-0.1 < flAttack2Time <= flKnifeAttack2Time)
    {
        DelayStart = flKnifeAttack2Time - flAttack2Time;

        flAttackTime = ArrayGetCell(ClassAttributes[Zombie_Attack2Delay1], iClass[player]);
        flAttack2Time = ArrayGetCell(ClassAttributes[Zombie_Attack2Delay], iClass[player]);

        if(flAttackTime > 0.0)
            set_member(item, m_Weapon_flNextPrimaryAttack, flAttackTime-DelayStart);

        if(flAttack2Time > 0.0)
            set_member(item, m_Weapon_flNextSecondaryAttack, flAttackTime-DelayStart);
    }
    else if(flKnifeAttack2Miss-0.1 < flAttack2Time <= flKnifeAttack2Miss)
    {
        DelayStart = flKnifeAttack2Miss - flAttack2Time;

        flAttackTime = ArrayGetCell(ClassAttributes[Zombie_AttackDelayMiss2], iClass[player]);
        flAttack2Time = ArrayGetCell(ClassAttributes[Zombie_AttackDelayMiss], iClass[player]);

        if(flAttackTime > 0.0)
            set_member(item, m_Weapon_flNextPrimaryAttack, flAttackTime-DelayStart);

        if(flAttack2Time > 0.0)
            set_member(item, m_Weapon_flNextSecondaryAttack, flAttackTime-DelayStart);
    }
}