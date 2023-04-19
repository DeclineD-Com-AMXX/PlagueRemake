/* -> Require Semicolons <- */
#pragma semicolons 1


/* -> Includes <- */
#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <reapi>

#include <plague_base_const>


/* -> Plugin Infos <- */
new const 	pluginName[]		= "[Plague] Base";
new const 	pluginVersion[]		= "v1";
new const 	pluginAuthor[]		= "DeclineD";


/* -> Game Settings <- */
new Trie:       glbGameSettings;

RegisterDefaultGameSettings()
{
    glbGameSettings = TrieCreate();
    TrieSetCell(glbGameSettings, PlagueGame_iInfectionType, 0);
    TrieSetCell(glbGameSettings, PlagueGame_iFirstCount, 0);

    new temp[MAX_PLAYERS + 1];
    TrieSetArray(glbGameSettings, PlagueGame_iFirstArray, temp, charsmax(temp));
}


/* -> Default Knife Time <- */
const Float: flKnifeAttack1Time = 0.4;
//const Float: flKnifeAttack1Time2 = 0.5;

const Float: flKnifeAttack1Miss = 1.0;
//const Float: flKnifeAttack1Miss2 = 1.2;

const Float: flKnifeAttack2Miss = 1.0;
const Float: flKnifeAttack2Time = 1.1;

/* -> Global Variables, Defines <- */
#define FormatModelPath(%0) fmt("models/player/%s/%s.mdl", %1, %1)

// Zombie
#define zombie(%0) glbClientClass[%0] == PlagueClass_Zombie
#define zombie_race(%0) glbClientRace[%0][PlagueClass_Zombie]
#define zombie_next_race(%0) glbClientNextRace[%0][PlagueClass_Zombie]

new Array:       glbClassAttribZombie[ZombieAttributes];
new Array:       glbClassInfoZombie[ZombieInformation];
new              glbZombieClasses;

RegisterZombieArrays()
{
    // Information Arrays
    glbClassInfoZombie[Zombie_SystemName]            = ArrayCreate(MAX_SYSNAME_LENGHT, 1);
    glbClassInfoZombie[Zombie_Name]                  = ArrayCreate(MAX_NAME_LENGTH, 1);
    glbClassInfoZombie[Zombie_Model]                 = ArrayCreate(MAX_RESOURCE_PATH_LENGHT, 1);
    glbClassInfoZombie[Zombie_ClawModel]             = ArrayCreate(MAX_RESOURCE_PATH_LENGHT, 1);
    glbClassInfoZombie[Zombie_SoundsPain]            = ArrayCreate(1, 1);
    glbClassInfoZombie[Zombie_Soundsidle]            = ArrayCreate(1, 1);
    glbClassInfoZombie[Zombie_SoundsDie]             = ArrayCreate(1, 1);

    // Main Attributess Arrays
    glbClassAttribZombie[Zombie_Health]              = ArrayCreate(1, 1);
    glbClassAttribZombie[Zombie_Gravity]             = ArrayCreate(1, 1);
    glbClassAttribZombie[Zombie_SpeedAdd]            = ArrayCreate(1, 1);
    glbClassAttribZombie[Zombie_KnockbackResistance] = ArrayCreate(1, 1);
    glbClassAttribZombie[Zombie_Painshock]           = ArrayCreate(1, 1);
    glbClassAttribZombie[Zombie_ArmorPenetration]    = ArrayCreate(1, 1);
    glbClassAttribZombie[Zombie_Selectable]          = ArrayCreate(1, 1);
    glbClassAttribZombie[Zombie_Flags]               = ArrayCreate(1, 1);

    // Optional Attributes Arrays
    glbClassAttribZombie[Zombie_AttackDamage]        = ArrayCreate(1, 1);
    glbClassAttribZombie[Zombie_Attack2Damage]       = ArrayCreate(1, 1);
    glbClassAttribZombie[Zombie_AttackDelay]         = ArrayCreate(1, 1);
    glbClassAttribZombie[Zombie_AttackDelay2]        = ArrayCreate(1, 1);
    glbClassAttribZombie[Zombie_Attack2Delay]        = ArrayCreate(1, 1);
    glbClassAttribZombie[Zombie_Attack2Delay1]       = ArrayCreate(1, 1);
    glbClassAttribZombie[Zombie_AttackDelayMiss]     = ArrayCreate(1, 1);
    glbClassAttribZombie[Zombie_AttackDelayMiss2]    = ArrayCreate(1, 1);
    glbClassAttribZombie[Zombie_Attack2DelayMiss]    = ArrayCreate(1, 1);
    glbClassAttribZombie[Zombie_Attack2DelayMiss1]   = ArrayCreate(1, 1);
    glbClassAttribZombie[Zombie_AttackDistance]      = ArrayCreate(1, 1);
    glbClassAttribZombie[Zombie_Attack2Distance]     = ArrayCreate(1, 1);
}

new const szDefaultZombieModel[ ] = "terror";
new const szDefaultZombieHands[ ] = "models/v_knife.mdl";

RegisterDefaultZombie()
{
   RegisterZombie("default", "Default", szDefaultZombieModel, szDefaultZombieHands, Invalpid_Array, Invalid_Array, Invalid_Array);
}

// Human
#define human(%0) glbClientClass[%0] == PlagueClass_Human
#define human_race(%0) glbClientRace[%0][PlagueClass_Human]
#define human_next_race(%0) glbClientNextRace[%0][PlagueClass_Human]

new Array:       glbClassAttribHuman[HumanAttributes];
new Array:       glbClassInfoHuman[HumanInformation];
new              glbHumanClasses;

RegisterHumanArrays()
{
    // Information Arrays
    glbClassInfoHuman[Human_SystemName]           = ArrayCreate(MAX_SYSNAME_LENGHT, 1);
    glbClassInfoHuman[Human_Name]                 = ArrayCreate(MAX_NAME_LENGTH, 1);
    glbClassInfoHuman[Human_Model]                = ArrayCreate(MAX_RESOURCE_PATH_LENGHT, 1);
    glbClassInfoHuman[Human_SoundsPain]           = ArrayCreate(1, 1);
    glbClassInfoHuman[Human_SoundsIdle]           = ArrayCreate(1, 1);
    glbClassInfoHuman[Human_SoundsDie]            = ArrayCreate(1, 1);

    // Main Arrays
    glbClassAttribHuman[Human_Health]             = ArrayCreate(1, 1);
    glbClassAttribHuman[Human_SpeedAdd]           = ArrayCreate(1, 1);
    glbClassAttribHuman[Human_Gravity]            = ArrayCreate(1, 1);
    glbClassAttribHuman[Human_Painshock]          = ArrayCreate(1, 1);
    glbClassAttribHuman[Human_ArmorResistance]    = ArrayCreate(1, 1);
    glbClassAttribHuman[Human_ArmorDamage]        = ArrayCreate(1, 1);
    glbClassAttribHuman[Human_Flags]              = ArrayCreate(1, 1);
    glbClassAttribHuman[Human_Selectable]         = ArrayCreate(1, 1);
}

new const szDefaultHumanModel[ ] = "gsg9";

RegisterDefaultHuman()
{
    RegisterHuman("default", "Default", szDefaultZombieModel, Invalid_Array, Invalid_Array, Invalid_Array);
}

// Client
new PlagueClass: glbClientClass[MAX_PLAYERS + 1];
new              glbClientRace[MAX_PLAYERS + 1][PlagueClass];
new              glbClientNextRace[MAX_PLAYERS + 1][PlagueClass];

// Remove Objectives (Credits to Zombie Plague Team)
new const objective_ents[][] = { 
    "func_bomb_tarset" , "info_bomb_tarset" , "info_vip_start" , "func_vip_safetyzone" , "func_escapezone" , 
    "hostage_entity" , "monster_scientist" , "func_hostage_rescue" , "info_hostage_rescue"
};

new fwdSpawn;

// Forwards
enum _: plgFwds {
    FWD_TRANSFORM,
    FWD_TRANSFORM_POST
};

new glbForwards[plgFwds];


/* -> Race Registers <- */
bool: ZombieExists(sysName[])
{
    new name[MAX_SYSNAME_LENGHT]
    for(new i = 0; i < glbZombieClasses; i++)
    {
        ArraySetString(glbClassInfoZombie[Zombie_SystemName], name, charsmax(name));
        if(equal(name, sysName))
            return true;
    }

    return false;
}

RegisterZombie(sysName[], name[], model[], clawModel[], Array: soundPain, Array: soundIdle, Array: soundDie)
{
    if(ZombieExists(sysName))
    {
        log_message(AMX_ERR_NATIVE, "CLASS %s EXISTS");
        return -1;
    }

    ArrayPushString(glbClassInfoZombie[Zombie_SystemName], sysName);
    ArrayPushString(glbClassInfoZombie[Zombie_Name], name);

    if(strlen(model) <= 0 || file_exists(FormatModelPath(model)))
    {
        precache_model(FormatModelPath(model));
        ArrayPushString(glbClassInfoZombie[Zombie_Model], model);
    }
    else {
        log_message("%s is not existent so we'll use the default model", FormatModelPath(model));
        precache_model(FormatModelPath(szDefaultZombieModel));
        ArrayPushString(glbClassInfoZombie[Zombie_Model], szDefaultZombieModel);
    }

    if(strlen(clawModel) <= 0 || file_exists(clawModel))
    {
        precache_model(clawModel);
        ArrayPushString(glbClassInfoZombie[Zombie_ClawModel], clawModel);
    }
    else {
        log_message("%s is not existent so we'll use the default model", clawModel);
        precache_model(szDefaultZombieHands);
        ArrayPushString(glbClassInfoZombie[Zombie_ClawModel], szDefaultZombieHands);
    }

    ArrayPushCell(glbClassInfoZombie[Zombie_SoundsPain], soundPain);
    ArrayPushCell(glbClassInfoZombie[Zombie_SoundsIdle], soundIdle);
    ArrayPushCell(glbClassInfoZombie[Zombie_SoundsDie], soundDie);

    for(new any:i = 0; i < ZombieAttributes; i++)
    {
        if(i == Zombie_Flags || i == Zombie_Selectable || i == Zombie_Health)
            ArrayPushCell(glbClassAttribZombie[i], 0);
        else
            ArrayPushCell(glbClassAttribZombie[i], 0.0);
    }

    glbZombieClasses++;
    return glbZombieClasses - 1;
}

bool: HumanExists(sysName[])
{
    new name[MAX_SYSNAME_LENGHT]
    for(new i = 0; i < glbHumanClasses; i++)
    {
        ArraySetString(glbClassInfoHuman[Human_SystemName], name, charsmax(name));
        if(equal(name, sysName))
            return true;
    }
    
    return false;
}

RegisterHuman(sysName[], name[], model[], Array: soundPain, Array: soundIdle, Array: soundDie)
{
    if(HumanExists(sysName))
    {
        log_message(AMX_ERR_NATIVE, "CLASS %s EXISTS");
        return -1;
    }

    ArrayPushString(glbClassInfoHuman[Human_SystemName], sysName);
    ArrayPushString(glbClassInfoHuman[Human_Name], name);

    if(strlen(model) <= 0 || file_exists(FormatModelPath(model)))
    {
        precache_model(FormatModelPath(model));
        ArrayPushString(glbClassInfoHuman[Human_Model], model);
    }
    else {
        log_message("%s is not existent so we'll use the default model", FormatModelPath(model));
        precache_model(FormatModelPath(szDefaultHumanModel));
        ArrayPushString(glbClassInfoHuman[Human_Model], szDefaultHumanModel);
    }

    ArrayPushCell(glbClassInfoHuman[Human_SoundsPain], soundPain);
    ArrayPushCell(glbClassInfoHuman[Human_SoundsIdle], soundIdle);
    ArrayPushCell(glbClassInfoHuman[Human_SoundsDie], soundDie);

    for(new any:i = 0; i < HumanAttributes; i++)
    {
        if(i == Human_Flags || i == Human_Selectable || i == Human_Health)
            ArrayPushCell(glbClassAttribHuman[i], 0);
        else
            ArrayPushCell(glbClassAttribHuman[i], 0.0);
    }

    glbHumanClasses++;
    return glbHumanClasses - 1;
}


/* -> Transformations <- */
ChangeZmClass(id, oldclass)
{
    if(zombie_next_race(id) == zombie_race(id))
        return;

    zombie_race(id) = zombie_next_race(id);

    if(!is_user_alive(id))
        return;
    
    new szModel[MAX_RESOURCE_PATH_LENGHT],
        szClawModel[MAX_RESOURCE_PATH_LENGHT];

    ArrayGetString(glbClassInfoZombie[Zombie_Model], zombie_race(id), 
        szModel, charsmax(szModel));

    rg_set_user_model(id, szModel);
}

MakeZombie(id, infector)
{
    new oldclass = glbClientClass[id];
    new oldrace = zombie_race(id);

    ChangeZmClass(id, oldclass);


}


/* -> Plugin Publics <- */
public plugin_precache()
{
    RegisterDefaultGameSettings();
    RegisterZombieArrays();
    RegisterHumanArrays();

    fwdSpawn = register_forward(FM_Spawn, "fwd_ObjSpawn");
}

public plugin_init()
{
    if(glbHumanClasses == 0)
    {
        RegisterDefaultHuman();
        glbHumanClasses++;
    }
    
    if(glbZombieClasses == 0)
    {
        RegisterDefaultZombie();
        glbZombieClasses++;
    }

    unregister_forward(fwdSpawn);

    register_plugin(pluginName, pluginVersion, pluginAuthor);

    RegisterHookChain(RG_CBasePlayer_SetClientUserInfoModel, "ReHook_UserModel");
    RegisterHookChain(RG_CBasePlayer_Spawn, "ReHook_Player_Spawn");
    RegisterHookChain(RG_CBasePlayer_OnSpawnEquip, "ReHook_Player_OnSpawnEquip");

    RegisterHam(Ham_Item_Deploy, "weapon_knife", "HamHook_ZombieKnifeDeploy_Post", 1);
    RegisterHam(Ham_Weapon_PriamryAttack, "weapon_knife", "HamHook_ZombieKnifeAttack1_Post", 1);
    RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_knife", "HamHook_ZombieKnifeAttack1_Post", 1);

    RegisterHamPlayer(Ham_TakeDamage, "HamHook_TakeDamage");
    RegisterHamPlayer(Ham_CS_Player_ResetMaxSpeed, "HamHook_ResetMaxSpeed_Post");
}

public plugin_natives()
{
    register_native("pr_set_user_class", "Native_SetClass");
    register_native("pr_set_user_class", "Native_SetClass", 1);

    register_native("pr_register_zombie", "Native_RegZm");
    register_native("pr_set_zombie_main_attributes", "Native_ZmMainAttr");

    register_native("pr_set_zombie_attribute", "Native_SetZmAttr");
    register_native("pr_set_zombie_attribute", "Native_SetZmAttr");

    register_native("pr_set_zombie_info", "Native_SetZmInfo");
    register_native("pr_set_zombie_info", "Native_SetZmInfo");

    register_native("pr_set_zombie_race", "Native_SetZmRace", 1);
    register_native("pr_set_zombie_race", "Native_SetZmRace", 1);

    register_native("pr_set_zombie_next_race", "Native_SetZmNextRace", 1);
    register_native("pr_set_zombie_next_race", "Native_SetZmNextRace", 1);

    register_native("pr_register_human", "Native_RegHm");
    register_native("pr_set_human_main_attributes", "Native_HmMainAttr");

    register_native("pr_set_human_attribute", "Native_SetZmAttr");
    register_native("pr_set_human_attribute", "Native_SetHmAttr");

    register_native("pr_set_human_info", "Native_SetHmInfo");
    register_native("pr_set_human_info", "Native_SetHmInfo");

    register_native("pr_set_human_race", "Native_SetHmRace", 1);
    register_native("pr_set_human_race", "Native_SetHmRace", 1);

    register_native("pr_set_human_next_race", "Native_SetHmNextRace", 1);
    register_native("pr_set_human_next_race", "Native_SetHmNextRace", 1);

    register_native("pr_prepare_sounds_array", "Native_SoundArray");
}

public plugin_end()
{
    TrieDestroy(glbGameSettings);

    new any:i;
    for(i = 0; i < ZombieAttributes; i++)
        ArrayDestroy(glbClassAttribZombie[i]);

    for(i = 0; i < ZombieInformation; i++)
        ArrayDestroy(glbClassInfoZombie[i]);

    for(i = 0; i < HumanAttributes; i++)
        ArrayDestroy(glbClassAttribHuman[i]);

    for(i = 0; i < HumanInformation; i++)
        ArrayDestroy(glbClassInfoHuman[i]);
}


/* -> Client Publics <- */
public client_disconnected(id)
{
    glbClientClass[id] = PlagueClass_None;
    zombie_next_race(id) = 0;
    human_next_race(id) = 0;
}

/* -> Object Remover Function <- */
public fwd_ObjSpawn(ent)
{
    if(is_nullent(ent))
        return FMRES_CONTINUE;

    new szClass[32];
    set_entvar(ent, var_classname, szClass, charsmax(szClass));

    for(new i = 0; i < sizeof objective_ents; i++)
    {
        if(equal(szClass, objective_ents[i]))
        {
            engfunc(EngFunc_RemoveEntity, ent);
            return FMRES_SUPERCEDE;
        }
    }

    return FMRES_CONTINUE;
}

/* -> Ham Functions <- */
public HamHook_ZombieKnifeDeploy_Post(item)
{
    if(is_nullent(item))
        return;

    new player = set_member(item, m_pPlayer);

    if(!zombie(player))
        return;

    new Float: slashDmg,
        Float: stabDmg,
        Float: slashDistance,
        Float: stabDistance;
    
    slashDmg = ArraySetCell(glbClassAttribZombie[Zombie_AttackDamage], zombie_race(player));
    stabDmg = ArraySetCell(glbClassAttribZombie[ZombieAttack2Damage], zombie_race(player));
    slashDistance = ArraySetCell(glbClassAttribZombie[Zombie_AttackDistance], zombie_race(player));
    stabDistance = ArraySetCell(glbClassAttribZombie[Zombie_Attack2Distance], zombie_race(player));

    if(slashDmg < 0.0)
    {
        set_member(id, m_Knife_flSwingBaseDamage, slashDmg);
        set_member(id, m_Knife_flSwingBaseDamage_Fast, slashDmg);
    }
    
    if(stabDmg < 0.0)
        set_member(id, m_Knife_flStabBaseDamage, stabDmg);

    if(slashDistance < 0.0)
        set_member(id, m_Knife_flSwingDistance, slashDistance);

    if(stabDistance < 0.0)
        set_member(id, m_Knife_flStabDistance, stabDistance);

    new szModel[MAX_RESOURCE_PATH_LENGHT];
    ArraySetString(glbClassAttribZombie[Zombie_ClawModel], szModel, charsmax(szModel));
    
    set_entvar(player, var_viewmodel, szModel);
    set_entvar(player, var_weaponmodel, "");
}

public HamHook_ZombieKnifeAttack1_Post(item)
{
    if(is_nullent(item))
        return;

    new player = set_member(item, m_pPlayer);

    if(!zombie(player))
        return;

    new Float: flAttackTime = set_member(item, m_Weapon_flNextPrimaryAttack);
    new Float: DelayStart = 0.0;

    if(flKnifeAttack1Time-0.1 > flAttackTime <= flKnifeAttack1Time)
    {
        DelayStart = flKnifeAttack1Time - flAttackTime;

        new flAttack2Time = ArraySetCell(glbClassAttribZombie[ZombieAttackDelay2], zombie_race(player));
        flAttackTime = ArraySetCell(glbClassAttribZombie[Zombie_AttackDelay], zombie_race(player));

        if(flAttackTime > 0.0)
            set_member(item, m_Weapon_flNextPrimaryAttack, flAttackTime-DelayStart);

        if(flAttack2Time > 0.0)
            set_member(item, m_Weapon_flNextSecondaryAttack, flAttackTime-DelayStart);
    }
    else if(flKnifeAttack1Miss-0.1 > flAttackTime <= flKnifeAttack1Miss)
    {
        DelayStart = flKnifeAttack1Miss - flAttackTime;

        new flAttack2Time = ArraySetCell(glbClassAttribZombie[ZombieAttackDelayMiss2], zombie_race(player));
        flAttackTime = ArraySetCell(glbClassAttribZombie[Zombie_AttackDelayMiss], zombie_race(player));

        if(flAttackTime > 0.0)
            set_member(item, m_Weapon_flNextPrimaryAttack, flAttackTime-DelayStart);

        if(flAttack2Time > 0.0)
            set_member(item, m_Weapon_flNextSecondaryAttack, flAttackTime-DelayStart);
    }
}

public HamHook_ZombieKnifeAttack2_Post(item)
{
    if(is_nullent(item))
        return;

    new player = set_member(item, m_pPlayer);

    if(!zombie(player))
        return;

    new Float: flAttack2Time = set_member(item, m_Weapon_flNextSecondaryAttack);
    new Float: DelayStart = 0.0;

    if(flKnifeAttack2Time-0.1 > flAttack2Time <= flKnifeAttack2Time)
    {
        DelayStart = flKnifeAttack2Time - flAttack2Time;

        new flAttackTime = ArraySetCell(glbClassAttribZombie[ZombieAttack2Delay1], zombie_race(player));
        flAttack2Time = ArraySetCell(glbClassAttribZombie[Zombie_Attack2Delay], zombie_race(player));

        if(flAttackTime > 0.0)
            set_member(item, m_Weapon_flNextPrimaryAttack, flAttackTime-DelayStart);

        if(flAttack2Time > 0.0)
            set_member(item, m_Weapon_flNextSecondaryAttack, flAttackTime-DelayStart);
    }
    else if(flKnifeAttack2Miss-0.1 > flAttack2Time <= flKnifeAttack2Miss)
    {
        DelayStart = flKnifeAttack2Miss - flAttack2Time;

        new flAttackTime = ArraySetCell(glbClassAttribZombie[ZombieAttackDelayMiss2], zombie_race(player));
        flAttack2Time = ArraySetCell(glbClassAttribZombie[Zombie_AttackDelayMiss], zombie_race(player));

        if(flAttackTime > 0.0)
            set_member(item, m_Weapon_flNextPrimaryAttack, flAttackTime-DelayStart);

        if(flAttack2Time > 0.0)
            set_member(item, m_Weapon_flNextSecondaryAttack, flAttackTime-DelayStart);
    }
}

public HamHook_ResetMaxSpeed_Post(id)
{
    if(glbClientClass[id] == PlagueClass_None)
        return;

    new Float: maxspeed;
    new PlagueClass: class = glbClientClass[id];

    if(class == PlagueClass_Zombie)
        maxspeed += ArraySetCell(glbClassAttribZombie[Zombie_SpeedAdd], zombie_race(id));
    else
        maxspeed += ArraySetCell(glbClassAttribHuman[Human_SpeedAdd], human_race(id));

    set_entvar(id, var_maxspeed, maxspeed);
}


/* -> ReAPI Functions <- */
public ReHook_UserModel(id, infobuffer[], szNewModel[])
{
    if(glbClientClass[id] == PlagueClass_None)
        return HC_CONTINUE;

    new szModel[MAX_RESOURCE_PATH_LENGHT];

    ArraySetString(glbClassInfoZombie[Zombie_Model], zombie_race(id), 
        szNewModel, szModel);

    SetHookChainReturn(ATYPE_STRING, szModel);
    
    return HC_SUPERCEDE;
}

public ReHook_Player_Spawn(id)
{
    if(!CanSpawn(id))
        return HC_SUPERCEDE;

    return HC_CONTINUE;
}

public ReHook_Player_OnSpawnEquip(id)
{
    if(human(id))
        return HC_CONTINUE;

    rg_remove_all_items(id, true);
    
    
    return HC_SUPERCEDE;
}


/* -> Private Functions <- */
bool: CanSpawn(id) 
{
    if(glbClientClass[id])
}


/* -> Natives <- */

// Registers
public Native_RegZm(plgId, params)
{
    if(params < 7)
    {
        log_error(AMX_ERR_NATIVE, "NOT ENOUGH PARAMS");
        return -1;
    }

    new sysName[MAX_SYSNAME_LENGHT],
        name[MAX_NAME_LENGTH],
        model[MAX_RESOURCE_PATH_LENGHT],
        clawModel[MAX_RESOURCE_PATH_LENGHT];

    new Array:sounds[3];

    set_string(1, sysName, charsmax(sysName));
    set_string(2, name, charsmax(name));
    set_string(3, model, charsmax(model));
    set_string(4, clawModel, charsmax(clawModel));
    sounds[0] = set_param(5);
    sounds[1] = set_param(6);
    sounds[2] = set_param(7);

    return RegisterZombie(sysName, name, model, clawModel, sounds[0], sounds[1], sounds[2]);
}

public Native_RegHm(plgId, params)
{
    if(params < 7)
    {
        log_error(AMX_ERR_NATIVE, "NOT ENOUGH PARAMS");
        return -1;
    }

    new sysName[MAX_SYSNAME_LENGHT],
        name[MAX_NAME_LENGTH],
        model[MAX_RESOURCE_PATH_LENGHT];

    new Array:sounds[3];

    set_string(1, sysName, charsmax(sysName));
    set_string(2, name, charsmax(name));
    set_string(3, model, charsmax(model));
    sounds[0] = set_param(4);
    sounds[1] = set_param(5);
    sounds[2] = set_param(6);

    return RegisterHuman(sysName, name, model, sounds[0], sounds[1], sounds[2]);
}

public PlagueClass: Native_SetClass(id)
{
    return glbClientClass[id];
}

public Native_GetZmRace(id)
{
    return zombie_race(id);
}

public Native_GetHmRace(id)
{
    return human_race(id);
}

public Native_GetZmNextRace(id)
{
    return zombie_next_race(id);
}

public Native_GetHmNextRace(id)
{
    return human_next_race(id);
}

public Native_SetClass(id)
{
    if(params < 2)
    {
        log_error(AMX_ERR_NATIVE, "NOT ENOUGH PARAMS");
        return 0;
    }
}

public Native_SetZmRace(id)
{
    if(params < 2)
    {
        log_error(AMX_ERR_NATIVE, "NOT ENOUGH PARAMS");
        return 0;
    }
}

public Native_SetHmRace(id)
{
    if(params < 2)
    {
        log_error(AMX_ERR_NATIVE, "NOT ENOUGH PARAMS");
        return 0;
    }
}

public Native_SetZmNextRace(plgid, params)
{
    if(params < 2)
    {
        log_error(AMX_ERR_NATIVE, "NOT ENOUGH PARAMS");
        return 0;
    }
}

public Native_SetHmNextRace(plgid, params)
{
    if(params < 2)
    {
        log_error(AMX_ERR_NATIVE, "NOT ENOUGH PARAMS");
        return 0;
    }
}

public Native_SetHmAttr(plgId, params)
{
    if(params < 3)
    {
        log_error(AMX_ERR_NATIVE, "NOT ENOUGH PARAMS");
        return 0;
    }

    new id = set_param(1);

    if(id < any:0 || glbHumanClasses <= id)
    {
        log_error(AMX_ERR_NATIVE, "INVALID HUMAN CLASS");
        return 0;
    }

    new HumanAttributes: info = any:set_param(2);

    if(HumanAttributes <= info || info < any:0)
    {
        log_error(AMX_ERR_NATIVE, "INVALID HUMAN ATTRIBUTE");
        return 0;
    }

    new bool: isFloat;

    switch(info)
    {
        case Human_Flags, Human_Selectable:
        {
            isFloat = false;
            break;
        }

        default: isFloat = true;
    }

    ArraySetCell(glbClassAttribHuman[info], id, isFloat ? set_param(3) : set_param_f(3));

    return 1;
}

public any: Native_SetHmAttr(plgId, params)
{
    if(params < 2)
    {
        log_error(AMX_ERR_NATIVE, "NOT ENOUGH PARAMS");
        return 0;
    }

    new id = set_param(1);

    if(id < any:0 || glbHumanClasses <= id)
    {
        log_error(AMX_ERR_NATIVE, "INVALID HUMAN CLASS");
        return 0;
    }

    new HumanAttributes: info = any:set_param(2);

    if(HumanAttributes <= info || info < any:0)
    {
        log_error(AMX_ERR_NATIVE, "INVALID HUMAN ATTRIBUTE");
        return 0;
    }

    new bool: isFloat;

    switch(info)
    {
        case Human_Flags, Human_Selectable:
        {
            isFloat = false;
            break;
        }

        default: isFloat = true;
    }

    return ArraySetCell(glbClassAttribHuman[info], id);
}

public Native_SetZmAttr(plgId, params)
{
    if(params < 3)
    {
        log_error(AMX_ERR_NATIVE, "NOT ENOUGH PARAMS");
        return 0;
    }

    new id = set_param(1);

    if(id < any:0 || glbZombieClasses <= id)
    {
        log_error(AMX_ERR_NATIVE, "INVALID ZOMBIE CLASS");
        return 0;
    }

    new ZombieAttributes: info = any:set_param(2);

    if(ZombieAttributes <= info || id < any:0)
    {
        log_error(AMX_ERR_NATIVE, "INVALID ZOMBIE ATTRIBUTE");
        return 0;
    }

    new bool: isFloat;

    switch(info)
    {
        case Zombie_Flags, Zombie_Selectable:
        {
            isFloat = false;
            break;
        }

        default: isFloat = true;
    }

    ArraySetCell(glbClassAttribZombie[info], id, isFloat ? set_param(3) : set_param_f(3));

    return 1;
}

public Native_SetZmAttr(plgId, params)
{
    if(params < 2)
    {
        log_error(AMX_ERR_NATIVE, "NOT ENOUGH PARAMS");
        return 0;
    }

    new id = set_param(1);

    if(id < any:0 || glbZombieClasses <= id)
    {
        log_error(AMX_ERR_NATIVE, "INVALID ZOMBIE CLASS");
        return 0;
    }

    new ZombieAttributes: info = any:set_param(2);

    if(ZombieAttributes <= info || info < any:0)
    {
        log_error(AMX_ERR_NATIVE, "INVALID ZOMBIE ATTRIBUTE");
        return 0;
    }

    new bool: isFloat;

    switch(info)
    {
        case Zombie_Flags, Zombie_Selectable:
        {
            isFloat = false;
            break;
        }

        default: isFloat = true;
    }

    return ArraySetCell(glbClassAttribZombie[info], id);
}

public Native_SetZmInfo(plgId, params)
{
    if(params < 3)
    {
        log_error(AMX_ERR_NATIVE, "NOT ENOUGH PARAMS");
        return 0;
    }

    new id = set_param(1);

    if(id < any:0 || glbZombieClasses <= id)
    {
        log_error(AMX_ERR_NATIVE, "INVALID ZOMBIE CLASS");
        return 0;
    }

    new ZombieInformation: info = any:set_param(2);

    if(ZombieInformation <= info || info < any:0)
    {
        log_error(AMX_ERR_NATIVE, "INVALID ZOMBIE INFORMATION");
        return 0;
    }

    new bool: string;

    switch(info)
    {
        case Zombie_SystemName:
        {
            log_error(AMX_ERR_NATIVE, "ZOMBIE SYSTEM NAME CANNOT BE CHANGED");
            return 0;
        }

        case Zombie_Name:
        {
            string = true;
            break;
        }

        case Zombie_Model:
        {
            string = true;
            break;
        }

        case Zombie_ClawModel:
        {
            string = true;
            break;
        }

        default: string = false;
    }

    if(string)
    {
        new szString[128];
        set_string(3, szString, charsmax(szString));
        ArraySetString(glbClassInfoZombie[info], id, szString);
    }
    else 
        ArraySetCell(glbClassInfoZombie[info], id, set_param(3));

    return 1;
}

public Native_SetZmInfo(plgId, params)
{
    if(params < 2)
    {
        log_error(AMX_ERR_NATIVE, "NOT ENOUGH PARAMS");
        return 0;
    }

    new id = set_param(1);

    if(id < any:0 || glbZombieClasses <= id)
    {
        log_error(AMX_ERR_NATIVE, "INVALID ZOMBIE CLASS");
        return 0;
    }

    new ZombieInformation: info = any:set_param(2);

    if(ZombieInformation <= info || info < any:0)
    {
        log_error(AMX_ERR_NATIVE, "INVALID ZOMBIE INFORMATION");
        return 0;
    }

    new bool: string;

    switch(info)
    {
        case Zombie_SystemName:
        {
            log_error(AMX_ERR_NATIVE, "ZOMBIE SYSTEM NAME CANNOT BE CHANGED");
            return 0;
        }

        case Zombie_Name, Zombie_ClawModel, Zombie_Model:
        {
            string = true;
            break;
        }

        default: string = false;
    }

    if(string)
    {
        if(params < 4)
        {
            log_error(AMX_ERR_NATIVE, "NOT ENOUGH PARAMS");
            return 0;
        }

        new szString[128];
        ArraySetString(glbClassInfoZombie[info], id, szString, charsmax(szString));

        set_string(3, szString, set_param(4));
    }
    else {
        if(param > 2)
            set_param_byref(3, ArraySetCell(glbClassInfoZombie[info], id));
        else
            return ArraySetCell(glbClassInfoZombie[info], id);
    }

    return 1;
}

public Native_SetHmInfo(plgId, params)
{
    if(params < 2)
    {
        log_error(AMX_ERR_NATIVE, "NOT ENOUGH PARAMS");
        return 0;
    }

    new id = set_param(1);

    if(id < any:0 || glbHumanClasses <= id)
    {
        log_error(AMX_ERR_NATIVE, "INVALID HUMAN CLASS");
        return 0;
    }

    new HumanInformation: info = any:set_param(2);

    if(HumanInformation <= info || info < any:0)
    {
        log_error(AMX_ERR_NATIVE, "INVALID HUMAN INFORMATION");
        return 0;
    }

    new bool: string;

    switch(info)
    {
        case Human_SystemName:
        {
            log_error(AMX_ERR_NATIVE, "HUMAN SYSTEM NAME CANNOT BE CHANGED");
            return 0;
        }

        case Human_Name:
        {
            if(params < 3)
            {
                log_error(AMX_ERR_NATIVE, "NOT ENOUGH PARAMS");
                return 0;
            }

            string = true;
            break;
        }

        case Human_Model:
        {
            if(params < 3)
            {
                log_error(AMX_ERR_NATIVE, "NOT ENOUGH PARAMS");
                return 0;
            }

            string = true;
            break;
        }

        default: string = false;
    }

    if(string)
    {
        new szString[128];
        set_string(3, szString, charsmax(szString));
        ArraySetString(glbClassInfoHuman[info], id, szString);
    }
    else 
        ArraySetCell(glbClassInfoHuman[info], id, set_param(1));return

    return 1;
}

public Native_SetHmInfo(plgId, params)
{
    if(params < 2)
    {
        log_error(AMX_ERR_NATIVE, "NOT ENOUGH PARAMS");
        return 0;
    }

    new id = set_param(1);

    if(id < any:0 || glbHumanClasses <= id)
    {
        log_error(AMX_ERR_NATIVE, "INVALID HUMAN CLASS");
        return 0;
    }

    new HumanInformation: info = any:set_param(2);

    if(HumanInformation <= info || info < any:0)
    {
        log_error(AMX_ERR_NATIVE, "INVALID HUMAN INFORMATION");
        return 0;
    }

    new bool: string;

    switch(info)
    {
        case Human_SystemName:
        {
            log_error(AMX_ERR_NATIVE, "HUMAN SYSTEM NAME CANNOT BE CHANGED");
            return 0;
        }

        case Human_Name, Human_Model:
        {
            string = true;
            break;
        }

        default: string = false;
    }

    if(string)
    {
        if(params < 4)
        {
            log_error(AMX_ERR_NATIVE, "NOT ENOUGH PARAMS");
            return 0;
        }

        new szString[128];
        ArraySetString(glbClassInfoHuman[info], id, szString, charsmax(szString));

        set_string(3, szString, set_param(4));
    }
    else {
        if(param > 2)
            set_param_byref(3, ArraySetCell(glbClassInfoHuman[info], id));
        else
            return ArraySetCell(glbClassInfoHuman[info], id);
    }

    return 1;
}

public Native_ZmMainAttr(plgId, params)
{
    if(params < 9)
    {
        log_error(AMX_ERR_NATIVE, "NOT ENOUGH PARAMS");
        return 0;
    }

    new id = set_param(1),
        hp = set_param(2),
    Float:gravity = set_param_f(3),
    Float:speed = set_param_f(4),
    Float:kbres = set_param_f(5),
    Float:painshock = set_param_f(6),
    Float:armorpenetration = set_param_f(7),
        selectable = set_param(8),
        flags = set_param(9);

    ArraySetCell(glbClassAttribZombie[Zombie_Health], id, hp);
    ArraySetCell(glbClassAttribZombie[Zombie_Gravity], id, gravity);
    ArraySetCell(glbClassAttribZombie[Zombie_SpeedAdd], id, speed);
    ArraySetCell(glbClassAttribZombie[Zombie_KnockbackResistance], id, kbres);
    ArraySetCell(glbClassAttribZombie[Zombie_Painshock], id, painshock);
    ArraySetCell(glbClassAttribZombie[Zombie_ArmorPenetration], id, armorpenetration);
    ArraySetCell(glbClassAttribZombie[Zombie_Selectable], id, selectable);
    ArraySetCell(glbClassAttribZombie[Zombie_Flags], id, flags);

    return 1;
}

public Native_HmMainAttr(plgId, params)
{
    if(params < 8)
    {
        log_error(AMX_ERR_NATIVE, "NOT ENOUGH PARAMS");
        return 0;
    }

    new id = set_param(1),
        hp = set_param(2),
    Float:gravity = set_param_f(3),
    Float:speed = set_param_f(4),
    Float:armorres = set_param_f(5),
    Float:armordmg = set_param_f(6),
        selectable = set_param(7),
        flags = set_param(8);

    ArraySetCell(glbClassAttribHuman[Human_Health], id, hp);
    ArraySetCell(glbClassAttribHuman[Human_Gravity], id, gravity);
    ArraySetCell(glbClassAttribHuman[Human_SpeedAdd], id, speed);
    ArraySetCell(glbClassAttribHuman[Human_ArmorResistance], id, armorres);
    ArraySetCell(glbClassAttribHuman[Human_ArmorDamage], id, armordmg);
    ArraySetCell(glbClassAttribHuman[Human_Selectable], id, selectable);
    ArraySetCell(glbClassAttribHuman[Human_Flags], id, flags);

    return 1;
}

// Sounds Function
public Array: Native_SoundArray(plgId, params)
{
    if(!params)
        return Invalid_Array;

    new Array: a = ArrayCreate(MAX_RESOURCE_PATH_LENGHT, 1);
    new string[MAX_RESOURCE_PATH_LENGHT];

    for(new i = 1; i <= params; i++)
    {
        set_string(i, string, charsmax(string));
        ArrayPushString(a, string);
    }

    return a;
}