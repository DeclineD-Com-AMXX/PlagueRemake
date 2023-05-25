/* *[-> INCLUDES <-]* */
#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <reapi>
#include <xs>

#include <plague_const>
#include <plague_human_const>
#include <plague_zombie_const>
#include <plague_armor>
#include <plague_classes>
#include <plague_settings>

/* *[-> PLUGIN INFO <-]* */
new const pluginName[ ] = "[Plague] Class Zombie";
new const pluginVersion[ ] = "Final";
new const pluginAuthor[ ] = "DeclineD";

/* *[-> DEFINES <-]* */
#define IsZombie(%0) bool:(pr_get_user_class(%0) == ZombieClassId)
#define IsHuman(%0) bool:(pr_get_user_class(%0) == HumanClassId)
#define IsPlayer(%0) is_user_connected(%0)
#define PlayerModelPath(%0) fmt("models/player/%s/%s.mdl", %0, %0)

/* *[-> SETTINGS <-]* */
/* -> Default Knife Time <- */
const Float: flKnifeAttack1Time = 0.4;
const Float: flKnifeAttack1Miss = 0.35;

const Float: flKnifeAttack2Time = 1.1;
const Float: flKnifeAttack2Miss = 1.0;

enum _:plgcvars {
    any: PC_KBPOWER,
    any: PC_KBVERTICAL,
    any: PC_KBON,
    any: PC_KBCLASS,
    any: PC_KBDUCK,
    any: PC_KBDISTANCE,
    any: PC_KBDAMAGE
};

new glbCvars[plgcvars];
new any: glbCvarValues[plgcvars];

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
    5.0,	// M249
    4.0,	// M3
    2.5,	// M4A1
    1.2,	// TMP
    3.25,	// G3SG1
    -1.0,	// ---
    2.15,	// DEAGLE
    2.5,	// SG552
    3.0,	// AK47
    -1.0,	// KNIFE
    1.0,	// P90
    -1.0    // SHIELD GUN
};

new const pluginCfg[] = "addons/amxmodx/configs/plague.json";

new const szDataKeys[ ZombieData ][ ] = {
    "name", "model", "claw_model", "hurt_sounds", "spawn_sounds", "death_sounds", "health",
    "gravity", "speed", "knockback", "painshock", "flags", "show_menu",
    "attk_dmg", "attk2_dmg", "attk_delay_attk", "attk_delay_attk2",
    "attk2_delay_attk", "attk2_delay_attk2", "attk_delay_miss_attk",
    "attk_delay_miss_attk2", "attk2_delay_miss_attk", "attk2_delay_miss_attk2",
    "attk_distance", "attk2_distance"
};

new const szDataDefault[ ZombieData ][] = {
    "default", "terror", "models/v_knife", "player/bhit_flesh-1.wav", "", "player/die1.wav", "100",
    "800", "250.0", "0.5", "0.5", "", "2",
    "0.0", "0.0", "0.0", "0.0",
    "0.0", "0.0", "0.0",
    "0.0", "0.0", "0.0",
    "0.0", "0.0"
}

new JSON:ZombieSection = Invalid_JSON, JSON:RaceSection = Invalid_JSON;

new iRaceCount;
new Trie:tZombies, Array:aZombieSystemName, Array:aZombieData[ ZombieData ];

new Array:aZombiePlgLoaded;

new bool:bReg = true;

LoadRaces( )
{
    if ( !bReg )
        return;
    
    if ( ZombieSection == Invalid_JSON )
    {
        ZombieSection = json_object_get_object_safe( pr_open_settings( pluginCfg ), PClass_Zombie );
        RaceSection = json_object_get_object_safe( ZombieSection, "races" );
    }

    new x, any:y, size, JSON:temp, JSON:temp2;
    new szSound[ 64 ], szString[ 32 ], any:value;
    new Array:aTemp, id, szFlags[ 30 ], szClaw[ 128 ];

    for ( x = 0; x < json_object_get_count( RaceSection ); x++ )
    {
        json_object_get_name( RaceSection, x, szString, charsmax( szString ) );

        if ( TrieKeyExists( tZombies, szString ) )
            continue;
        
        id = iRaceCount;
        AddRace( false, szString, szSound, szClaw, szString, Invalid_Array, Invalid_Array, Invalid_Array, 0, 0, 0.0, 0.0, 0.0, 0, MenuShow_No);

        temp = json_object_get_object_at_safe( RaceSection, x );

        temp2 = json_object_get_string_safe( temp, szDataKeys[ Zombie_Name ], szDataDefault[ Zombie_Name ], szString, charsmax( szString ) );
        ArraySetString( aZombieData[ Zombie_Name ], id, szString );
        json_free( temp2 );

        temp2 = json_object_get_string_safe( temp, szDataKeys[ Zombie_Model ], szDataDefault[ Zombie_Model ], szString, charsmax( szString ) );
        ArraySetString( aZombieData[ Zombie_Model ], id, szString );
        json_free( temp2 );

        precache_model( PlayerModelPath( szString ) );

        temp2 = json_object_get_string_safe( temp, szDataKeys[ Zombie_ClawModel ], szDataDefault[ Zombie_ClawModel ], szString, charsmax( szString ) );
        ArraySetString( aZombieData[ Zombie_ClawModel ], id, szString );
        json_free( temp2 );

        precache_model( szString );

        aTemp = ArrayCreate( 64, 1 );

        temp2 = json_object_get_array_safe( temp, szDataKeys[ Zombie_DeathSounds ] );
        size = json_array_get_count( temp2 );

        if ( size )
        {
            for ( y = 0; y < size; y++ )
            {
                json_array_get_string( temp2, y, szSound, charsmax( szSound ) );
                precache_sound( szSound );
                ArrayPushString( aTemp, szSound );
            }
        }
        else {
            json_array_append_string( temp2, szDataDefault[ Zombie_DeathSounds ] );
            precache_sound( szDataDefault[ Zombie_DeathSounds ] );
            ArrayPushString( aTemp, szDataDefault[ Zombie_DeathSounds ] );
        }

        ArraySetCell( aZombieData[ Zombie_DeathSounds ], id, aTemp );
        json_free( temp2 );

        aTemp = ArrayCreate( 64, 1 );

        temp2 = json_object_get_array_safe( temp, szDataKeys[ Zombie_SpawnSounds ] );
        size = json_array_get_count( temp2 );

        if ( size )
        {
            for ( y = 0; y < size; y++ )
            {
                json_array_get_string( temp2, y, szSound, charsmax( szSound ) );
                precache_sound( szSound );
                ArrayPushString( aTemp, szSound );
            }
        }
        else {
            json_array_append_string( temp2, szDataDefault[ Zombie_SpawnSounds ] );
            precache_sound( szDataDefault[ Zombie_SpawnSounds ] );
            ArrayPushString( aTemp, szDataDefault[ Zombie_SpawnSounds ] );
        }

        ArraySetCell( aZombieData[ Zombie_SpawnSounds ], id, aTemp );
        json_free( temp2 );

        temp2 = json_object_get_array_safe( temp, szDataKeys[ Zombie_HurtSounds ] );
        size = json_array_get_count( temp2 );

        aTemp = ArrayCreate( 64, 1 );

        if ( size )
        {
            for ( y = 0; y < size; y++ )
            {
                json_array_get_string( temp2, y, szSound, charsmax( szSound ) );
                precache_sound( szSound );
                ArrayPushString( aTemp, szSound );
            }
        }
        else {
            json_array_append_string( temp2, szDataDefault[ Zombie_HurtSounds ] );
            precache_sound( szDataDefault[ Zombie_HurtSounds ] );
            ArrayPushString( aTemp, szDataDefault[ Zombie_HurtSounds ] );
        }

        ArraySetCell( aZombieData[ Zombie_HurtSounds ], id, aTemp );
        json_free( temp2 );

        temp2 = json_object_get_value_safe( temp, szDataKeys[ Zombie_Health ], szDataDefault[ Zombie_Health ], JSONNumber, value );
        ArraySetCell( aZombieData[ Zombie_Health ], id, value );
        json_free( temp2 );

        temp2 = json_object_get_value_safe( temp, szDataKeys[ Zombie_Gravity ], szDataDefault[ Zombie_Gravity ], JSONNumber, value );
        ArraySetCell( aZombieData[ Zombie_Gravity ], id, value );
        json_free( temp2 );

        temp2 = json_object_get_value_safe( temp, szDataKeys[ Zombie_Speed ], szDataDefault[ Zombie_Speed ], JSONNumber, value );
        ArraySetCell( aZombieData[ Zombie_Speed ], id, value );
        json_free( temp2 );

        temp2 = json_object_get_value_safe( temp, szDataKeys[ Zombie_Knockback ], szDataDefault[ Zombie_Knockback ], JSONNumber, value );
        ArraySetCell( aZombieData[ Zombie_Knockback ], id, value );
        json_free( temp2 );

        temp2 = json_object_get_value_safe( temp, szDataKeys[ Zombie_Painshock ], szDataDefault[ Zombie_Painshock ], JSONNumber, value );
        ArraySetCell( aZombieData[ Zombie_Painshock ], id, value );
        json_free( temp2 );

        temp2 = json_object_get_string_safe( temp, szDataKeys[ Zombie_Flags ], "", szFlags, charsmax( szFlags ) );
        value = read_flags( szFlags );
        ArraySetCell( aZombieData[ Zombie_Flags ], id, value );
        json_free( temp2 );

        temp2 = json_object_get_value_safe( temp, szDataKeys[ Zombie_MenuShow ], szDataDefault[ Zombie_MenuShow ], JSONNumber, value );
        ArraySetCell( aZombieData[ Zombie_MenuShow ], id, value );
        json_free( temp2 );

        for(y = Zombie_AttackDamage; y < ZombieData; y++)
        {
            temp2 = json_object_get_value_safe( temp, szDataKeys[ y ], szDataDefault[ y ], JSONNumber, value );
            ArraySetCell( aZombieData[ y ], id, value );
            json_free( temp2 );
        }

        json_free( temp );
    }
}

LoadRace( szSysName[ 32 ], szName[ 64 ], szClaw[ 128 ], szModel[ 32 ], Array:dSounds, Array:sSounds, Array:pSounds, 
            health, gravity, Float:speed, Float:painshock, Float:kb, flags, MenuShow:menuShow )
{
    if ( !bReg )
        return -1;
    
    if ( ZombieSection == Invalid_JSON )
    {
        ZombieSection = json_object_get_object_safe( pr_open_settings( pluginCfg ), PClass_Zombie );
        RaceSection = json_object_get_object_safe( ZombieSection, "races" );
    }

    new id;
    if ( !TrieKeyExists( tZombies, szSysName ) )
    {
        new any:y, size, JSON:temp, JSON:temp2, any:value;

        new szFlags[ 30 ], szSound[ 64 ];

        id = iRaceCount;
        AddRace( true, szSysName, szName, szClaw, szModel, Invalid_Array, Invalid_Array, Invalid_Array, 0, 0, 0.0, 0.0, 0.0, 0, MenuShow_No);

        temp = json_object_get_object_safe( RaceSection, szSysName );

        temp2 = json_object_get_string_safe( temp, szDataKeys[ Zombie_Name ], szName, szName, charsmax( szName ) );
        ArraySetString( aZombieData[ Zombie_Name ], id, szName );
        json_free( temp2 );

        temp2 = json_object_get_string_safe( temp, szDataKeys[ Zombie_Model ], szModel, szModel, charsmax( szModel ) );
        ArraySetString( aZombieData[ Zombie_Model ], id, szModel );
        json_free( temp2 );

        precache_model( PlayerModelPath( szModel ) );

        temp2 = json_object_get_string_safe( temp, szDataKeys[ Zombie_ClawModel ], szClaw, szClaw, charsmax( szClaw ) );
        ArraySetString( aZombieData[ Zombie_ClawModel ], id, szClaw );
        json_free( temp2 );

        precache_model( szClaw );

        if ( dSounds == Invalid_Array )
           dSounds = ArrayCreate( 64, 1 );

        if ( pSounds == Invalid_Array )
           pSounds = ArrayCreate( 64, 1 );
        
        if ( sSounds == Invalid_Array )
           sSounds = ArrayCreate( 64, 1 );

        temp2 = json_object_get_array_safe( temp, szDataKeys[ Zombie_DeathSounds ] );
        size = json_array_get_count( temp2 );

        if ( size )
        {
            ArrayClear( dSounds );

            for ( y = 0; y < size; y++ )
            {
                json_array_get_string( temp2, y, szSound, charsmax( szSound ) );
                precache_sound( szSound );
                ArrayPushString( dSounds, szSound );
            }
        }
        else {
            for ( y = 0; y < ArraySize( dSounds ); y++ )
            {
                ArrayGetString( dSounds, y, szSound, charsmax( szSound ) );
                json_array_append_string( temp2, szSound );
                precache_sound( szSound );
            }
        }

        ArraySetCell( aZombieData[ Zombie_DeathSounds ], id, dSounds );
        json_free( temp2 );

        temp2 = json_object_get_array_safe( temp, szDataKeys[ Zombie_SpawnSounds ] );
        size = json_array_get_count( temp2 );

        if ( size )
        {
            ArrayClear( sSounds );

            for ( y = 0; y < size; y++ )
            {
                json_array_get_string( temp2, y, szSound, charsmax( szSound ) );
                precache_sound( szSound );
                ArrayPushString( sSounds, szSound );
            }
        }
        else {
            for ( y = 0; y < ArraySize( sSounds ); y++ )
            {
                ArrayGetString( sSounds, y, szSound, charsmax( szSound ) );
                json_array_append_string( temp2, szSound );
                precache_sound( szSound );
            }
        }

        ArraySetCell( aZombieData[ Zombie_SpawnSounds ], id, sSounds );
        json_free( temp2 );

        temp2 = json_object_get_array_safe( temp, szDataKeys[ Zombie_HurtSounds ] );
        size = json_array_get_count( temp2 );

        if ( size )
        {
            ArrayClear( pSounds );

            for ( y = 0; y < size; y++ )
            {
                json_array_get_string( temp2, y, szSound, charsmax( szSound ) );
                precache_sound( szSound );
                ArrayPushString( pSounds, szSound );
            }
        }
        else {
            for ( y = 0; y < ArraySize( pSounds ); y++ )
            {
                ArrayGetString( pSounds, y, szSound, charsmax( szSound ) );
                json_array_append_string( temp2, szSound );
                precache_sound( szSound );
            }
        }

        ArraySetCell( aZombieData[ Zombie_HurtSounds ], id, pSounds );
        json_free( temp2 );

        formatex(szSound, charsmax(szSound), "%i", health);
        temp2 = json_object_get_value_safe( temp, szDataKeys[ Zombie_Health ], szSound, JSONNumber, health );
        ArraySetCell( aZombieData[ Zombie_Health ], id, health );
        json_free( temp2 );

        formatex(szSound, charsmax(szSound), "%i", gravity);
        temp2 = json_object_get_value_safe( temp, szDataKeys[ Zombie_Gravity ], szDataDefault[ Zombie_Gravity ], JSONNumber, gravity );
        ArraySetCell( aZombieData[ Zombie_Gravity ], id, gravity );
        json_free( temp2 );

        formatex(szSound, charsmax(szSound), "%f", speed);
        temp2 = json_object_get_value_safe( temp, szDataKeys[ Zombie_Speed ], szDataDefault[ Zombie_Speed ], JSONNumber, speed );
        ArraySetCell( aZombieData[ Zombie_Speed ], id, speed );
        json_free( temp2 );

        formatex(szSound, charsmax(szSound), "%f", kb);
        temp2 = json_object_get_value_safe( temp, szDataKeys[ Zombie_Knockback ], szDataDefault[ Zombie_Knockback ], JSONNumber, kb );
        ArraySetCell( aZombieData[ Zombie_Knockback ], id, kb );
        json_free( temp2 );

        formatex(szSound, charsmax(szSound), "%f", painshock);
        temp2 = json_object_get_value_safe( temp, szDataKeys[ Zombie_Painshock ], szDataDefault[ Zombie_Painshock ], JSONNumber, painshock );
        ArraySetCell( aZombieData[ Zombie_Painshock ], id, painshock );
        json_free( temp2 );

        get_flags( flags, szFlags, charsmax( szFlags ) );
        temp2 = json_object_get_string_safe( temp, szDataKeys[ Zombie_Flags ], "", szFlags, charsmax( szFlags ) );
        flags = read_flags( szFlags );
        ArraySetCell( aZombieData[ Zombie_Flags ], id, flags );
        json_free( temp2 );

        formatex(szSound, charsmax(szSound), "%i", menuShow);
        temp2 = json_object_get_value_safe( temp, szDataKeys[ Zombie_MenuShow ], szDataDefault[ Zombie_MenuShow ], JSONNumber, menuShow );
        ArraySetCell( aZombieData[ Zombie_MenuShow ], id, menuShow );
        json_free( temp2 );

        for(y = Zombie_AttackDamage; y < ZombieData; y++)
        {
            temp2 = json_object_get_value_safe( temp, szDataKeys[ y ], szDataDefault[ y ], JSONNumber, value );
            ArraySetCell( aZombieData[ y ], id, value );
            json_free( temp2 );
        }

        json_free( temp );
    }
    else {
        TrieGetCell( tZombies, szSysName, id );

        if ( ArrayGetCell( aZombiePlgLoaded, id ) == true )
            return -1;

        ArraySetCell( aZombiePlgLoaded, id, true );
    }

    return id;
}

AddRace( bool: plg, szSysName[ 32 ], szName[ 64 ], szClaw[ 128 ], szModel[ 32 ], Array:dSounds, Array:sSounds, Array:pSounds, 
            health, gravity, Float:speed, Float:painshock, Float:kb, flags, MenuShow:menuShow )
{
    TrieSetCell( tZombies, szSysName, iRaceCount );
    ArrayPushString( aZombieSystemName, szSysName );
    ArrayPushCell( aZombiePlgLoaded, plg );

    ArrayPushString( aZombieData[ Zombie_Name ], szName );
    ArrayPushString( aZombieData[ Zombie_Model ], szModel );
    ArrayPushString( aZombieData[ Zombie_ClawModel ], szClaw );
    ArrayPushCell( aZombieData[ Zombie_DeathSounds ], dSounds );
    ArrayPushCell( aZombieData[ Zombie_SpawnSounds ], sSounds );
    ArrayPushCell( aZombieData[ Zombie_HurtSounds ], pSounds );
    ArrayPushCell( aZombieData[ Zombie_Health ], health );
    ArrayPushCell( aZombieData[ Zombie_Gravity ], gravity );
    ArrayPushCell( aZombieData[ Zombie_Speed ], speed );
    ArrayPushCell( aZombieData[ Zombie_Painshock ], painshock );
    ArrayPushCell( aZombieData[ Zombie_Knockback ], kb );

    ArrayPushCell( aZombieData[ Zombie_Flags ], flags );
    
    ArrayPushCell( aZombieData[ Zombie_MenuShow ], menuShow );

    for(new any:i = Zombie_AttackDamage; i < ZombieData; i++)
        ArrayPushCell( aZombieData[ i ], 0.0 );

    iRaceCount++;
}

/* *[-> VARIABLES <-]* */
new PlagueClassId: HumanClassId;
new PlagueClassId: ZombieClassId;

new iRace[ MAX_PLAYERS + 1 ];
new iNextRace[ MAX_PLAYERS + 1 ];

new fwdZombify, fwdZombified;
new fwdShow;
new fwdChoose, fwdChoosePost;

/* *[-> PLUGIN <-]* */
public plugin_precache( )
{
    ZombieClassId = pr_register_class( PClass_Zombie, TEAM_TERRORIST );

    tZombies = TrieCreate( );
    aZombieSystemName = ArrayCreate( 32, 1 );
    aZombiePlgLoaded = ArrayCreate( 1, 1 );
    
    aZombieData[ Zombie_Name ] = ArrayCreate( 64, 1 );
    aZombieData[ Zombie_Model ] = ArrayCreate( 32, 1 );
    aZombieData[ Zombie_ClawModel ] = ArrayCreate( 128, 1 );
    aZombieData[ Zombie_DeathSounds ] = ArrayCreate( 1, 1 );
    aZombieData[ Zombie_SpawnSounds ] = ArrayCreate( 1, 1 );
    aZombieData[ Zombie_HurtSounds ] = ArrayCreate( 1, 1 );
    aZombieData[ Zombie_Health ] = ArrayCreate( 1, 1 );
    aZombieData[ Zombie_Gravity ] = ArrayCreate( 1, 1 );
    aZombieData[ Zombie_Speed ] = ArrayCreate( 1, 1 );
    aZombieData[ Zombie_Painshock ] = ArrayCreate( 1, 1 );
    aZombieData[ Zombie_Knockback ] = ArrayCreate( 1, 1 );
    aZombieData[ Zombie_Flags ] = ArrayCreate( 1, 1 );
    aZombieData[ Zombie_MenuShow ] = ArrayCreate( 1, 1 );

    for(new ZombieData:i = Zombie_AttackDamage; i < ZombieData; i++)
        aZombieData[ i ] = ArrayCreate( 1, 1 );

    LoadRaces( );

    fwdZombify = CreateMultiForward( "Plague_Zombify", ET_CONTINUE, FP_CELL, FP_CELL, FP_CELL );
    fwdZombified = CreateMultiForward( "Plague_Zombified", ET_CONTINUE, FP_CELL, FP_CELL, FP_CELL );
    fwdShow = CreateMultiForward( "Plague_ShowZombieInMenu", ET_CONTINUE, FP_CELL, FP_CELL );
    fwdChoose = CreateMultiForward( "Plague_ChooseZombieRace", ET_CONTINUE, FP_CELL, FP_CELL );
    fwdChoosePost = CreateMultiForward( "Plague_ChooseZombieRace_Post", ET_IGNORE, FP_CELL, FP_CELL );
}

public plugin_natives( )
{
    register_native( "pr_register_zombie_race", "Native_RegRace" );

    register_native( "pr_get_zombie_race_count", "Native_RaceCount", 1 );

    register_native( "pr_first_available_zombie_race", "Native_FirstAvailable" );

    register_native( "pr_get_user_zombie_race", "Native_GetRace" );
    register_native( "pr_set_user_zombie_race", "Native_SetRace" );

    register_native( "pr_get_user_next_zombie_race", "Native_GetNextRace" );
    register_native( "pr_set_user_next_zombie_race", "Native_SetNextRace" );

    register_native( "pr_set_zombie_data", "Native_SetZombieData" );
    register_native( "pr_get_zombie_data", "Native_GetZombieData" );

    register_native( "pr_open_zombies_menu", "Native_ZombiesMenu" );

    register_native( "pr_reset_zombie_attributes", "Native_ResetAttr", 1 );
}

public plugin_init( )
{
    bReg = false;

    // End of Settings
    json_free( ZombieSection );
    json_free( RaceSection );

    pr_close_settings( pluginCfg );

    // plugin
    register_plugin( pluginName, pluginVersion, pluginAuthor );

    HumanClassId = pr_get_class_id( PClass_Human );

    RegisterHookChain( RG_CBasePlayer_Pain, "ReHook_CBasePlayer_Pain", 1 );
    RegisterHookChain( RG_CBasePlayer_DeathSound, "ReHook_CBasePlayer_Death", 1 );

    RegisterHookChain( RG_CBasePlayer_TakeDamage, "ReHook_CBasePlayer_TakeDamage" );
    RegisterHookChain( RG_CBasePlayer_TakeDamage, "ReHook_CBasePlayer_TakeDamage_Post", 1 );

    RegisterHookChain( RG_CBasePlayer_AddPlayerItem, "ReHook_CBasePlayer_AddPlayerItem_Post", 1);
    RegisterHookChain( RG_CSGameRules_GiveC4, "C4");

    glbCvars[PC_KBPOWER] = register_cvar("plague_knockback_power", "1");
    glbCvarValues[PC_KBPOWER] = 1;
    bind_pcvar_num(glbCvars[PC_KBPOWER], glbCvarValues[PC_KBPOWER]);

    glbCvars[PC_KBON] = register_cvar("plague_knockback_on", "1");
    glbCvarValues[PC_KBON] = 1;
    bind_pcvar_num(glbCvars[PC_KBON], glbCvarValues[PC_KBON]);

    glbCvars[PC_KBCLASS] = register_cvar("plague_knockback_class", "1");
    glbCvarValues[PC_KBCLASS] = 1;
    bind_pcvar_num(glbCvars[PC_KBCLASS], glbCvarValues[PC_KBCLASS]);

    glbCvars[PC_KBVERTICAL] = register_cvar("plague_knockback_vertical", "1");
    glbCvarValues[PC_KBVERTICAL] = 1;
    bind_pcvar_num(glbCvars[PC_KBVERTICAL], glbCvarValues[PC_KBVERTICAL]);

    glbCvars[PC_KBDAMAGE] = register_cvar("plague_knockback_damage", "1");
    glbCvarValues[PC_KBDAMAGE] = 1;
    bind_pcvar_num(glbCvars[PC_KBDAMAGE], glbCvarValues[PC_KBDAMAGE]);

    glbCvars[PC_KBDUCK] = register_cvar("plague_knockback_duck_reduction", "0.25");
    glbCvarValues[PC_KBDUCK] = 1;
    bind_pcvar_float(glbCvars[PC_KBDUCK], glbCvarValues[PC_KBDUCK]);

    glbCvars[PC_KBDISTANCE] = register_cvar("plague_knockback_max_distance", "750.0");
    glbCvarValues[PC_KBDISTANCE] = 1;
    bind_pcvar_float(glbCvars[PC_KBDISTANCE], glbCvarValues[PC_KBDISTANCE]);

    RegisterHam(Ham_TraceAttack, "player", "TraceAttack_Post", 1);

    RegisterHam(Ham_Item_Deploy, "weapon_knife", "Hands_Post", 1);
    RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_knife", "HandsAttack1_Post", 1);
    RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_knife", "HandsAttack2_Post", 1);

    // Can t use turrets or weapons
    RegisterHam(Ham_Use, "func_tank", "fw_UseStationary");
    RegisterHam(Ham_Use, "func_tankmortar", "fw_UseStationary");
    RegisterHam(Ham_Use, "func_tankrocket", "fw_UseStationary");
    RegisterHam(Ham_Use, "func_tanklaser", "fw_UseStationary");
    RegisterHam(Ham_Use, "func_tank", "fw_UseStationary_Post", 1);
    RegisterHam(Ham_Use, "func_tankmortar", "fw_UseStationary_Post", 1);
    RegisterHam(Ham_Use, "func_tankrocket", "fw_UseStationary_Post", 1);
    RegisterHam(Ham_Use, "func_tanklaser", "fw_UseStationary_Post", 1);
    RegisterHam(Ham_Touch, "weaponbox", "fw_TouchWeapon");
    RegisterHam(Ham_Touch, "armoury_entity", "fw_TouchWeapon");
    RegisterHam(Ham_Touch, "weapon_shield", "fw_TouchWeapon");

    RegisterHookChain(RG_CBasePlayer_ResetMaxSpeed, "ResetSpeed_Post", 1);
}

public C4() return HC_SUPERCEDE;

public ReHook_CBasePlayer_AddPlayerItem_Post( pPlayer, pItem )
{
    new any:id;
    if ( is_nullent( pItem ) || ( (id = get_member( pItem, m_iId ) ) > WeaponIdType || id <= WEAPON_NONE ) )
        return;
    
    set_entvar( pItem, var_fuser4, kb_weapon_power[ id ] );
}

public plugin_end( )
{
    if ( ZombieSection != Invalid_JSON )
        json_free( ZombieSection );

    if ( RaceSection != Invalid_JSON )
        json_free( RaceSection );

    TrieDestroy( tZombies );
    ArrayDestroy( aZombieSystemName );

    new any:i, x, Array:a;
    for ( i = 0; i < ZombieData; i++ )
    {
        if ( i == Zombie_DeathSounds || i == Zombie_HurtSounds )
        {
            for ( x = 0; x < iRaceCount; x++ )
            {
                a = Array:ArrayGetCell( aZombieData[ i ], x )
                ArrayDestroy( a );
            }
        }

        ArrayDestroy( aZombieData[ i ] );
    }
}

/* *[-> NOWHERE TO PUT SHIT <-]* */

// Weapon and turret handling
public fw_UseStationary(entity, caller, activator, use_type)
{
	if (use_type == 2 && is_user_connected(caller) && IsZombie(caller))
		return HAM_SUPERCEDE;
	
	return HAM_IGNORED;
}

public fw_UseStationary_Post(entity, caller, activator, use_type)
{
	if(use_type == 0 && is_user_connected(caller) && IsZombie(caller))
	{
		// Reset Claws
		static Claw2[128];
		ArrayGetString(aZombieData[Zombie_ClawModel], iRace[caller], Claw2, charsmax(Claw2));
			
		set_entvar(caller, var_viewmodel, Claw2);
		set_entvar(caller, var_weaponmodel, "");	
	}
}

public fw_TouchWeapon(weapon, id)
{
	if(!is_user_connected(id))
		return HAM_IGNORED;

	if(IsZombie(id))
		return HAM_SUPERCEDE;
	
	return HAM_IGNORED;
}

public ResetSpeed_Post(id)
{
    if(!IsZombie(id) || get_member_game(m_bFreezePeriod))
        return;

    new Float: flSpeed = ArrayGetCell(aZombieData[Zombie_Speed], iRace[id]);

    new Float: maxspeed = get_entvar(id, var_maxspeed);
    maxspeed += (flSpeed - 250.0);

    set_entvar(id, var_maxspeed, maxspeed);
}

public TraceAttack_Post(victim, attacker, Float:flDamage, Float:vecDir[3], tr, dmgBits)
{
    if((victim == attacker) ||
        IsZombie(attacker) || 
        IsHuman(victim) ||
        !IsPlayer(victim) || 
        !IsPlayer(attacker) )
        return;

    new flags = get_entvar(victim, var_flags);
    new bool:bDuck = ((flags & FL_DUCKING) && (flags & FL_ONGROUND));

    if( !(dmgBits & DMG_BULLET || dmgBits & DMG_SLASH) ||
        glbCvarValues[PC_KBON] <= 0 ||
        flDamage <= 0.0 )
        return;

    if(bDuck && glbCvarValues[PC_KBDUCK] <= 0.0)
        return;

    new Float: vecOrigin[2][3];
    get_entvar(victim, var_origin, vecOrigin[0]);
    get_entvar(attacker, var_origin, vecOrigin[1]);

    if(xs_vec_distance(vecOrigin[0], vecOrigin[1]) > glbCvarValues[PC_KBDISTANCE])
        return;

    new Float:flPower = 1.0;

    if(glbCvarValues[PC_KBPOWER])
    {
        flPower = get_entvar( get_member( attacker, m_pActiveItem ), var_fuser4 );

        if(flPower > 0)
            flPower = 1.0;
    }

    if(glbCvarValues[PC_KBDAMAGE])
    {
        flPower *= flDamage;
    }

    if(glbCvarValues[PC_KBCLASS])
    {
        new Float:kb = ArrayGetCell(aZombieData[Zombie_Knockback], iRace[victim]);
        flPower *= kb;
    }

    if(bDuck)
    {
        flPower *= glbCvarValues[PC_KBDUCK];
    }

    MakeKnockback(victim, attacker, flPower, vecOrigin[1]);
}

public Hands_Post(item)
{
    if(is_nullent(item))
        return;

    new player = get_member(item, m_pPlayer);

    if(!IsZombie(player))
        return;

    new szModel[MAX_RESOURCE_PATH_LENGTH];
    ArrayGetString(aZombieData[Zombie_ClawModel], iRace[player], szModel, charsmax(szModel));
    
    set_entvar(player, var_viewmodel, szModel);
    set_entvar(player, var_weaponmodel, "");

    new Float: slashDmg,
        Float: stabDmg,
        Float: slashDistance,
        Float: stabDistance;
    
    slashDmg = ArrayGetCell(aZombieData[Zombie_AttackDamage], iRace[player]);
    stabDmg = ArrayGetCell(aZombieData[Zombie_Attack2Damage], iRace[player]);
    slashDistance = ArrayGetCell(aZombieData[Zombie_AttackDistance], iRace[player]);
    stabDistance = ArrayGetCell(aZombieData[Zombie_Attack2Distance], iRace[player]);

    if(slashDmg > 0.0)
    {
        set_member(player, m_Knife_flSwingBaseDamage, slashDmg);
        set_member(player, m_Knife_flSwingBaseDamage_Fast, slashDmg);
    }
    
    if(stabDmg > 0.0)
        set_member(player, m_Knife_flStabBaseDamage, stabDmg);

    if(slashDistance > 0.0)
        set_member(player, m_Knife_flSwingDistance, slashDistance);

    if(stabDistance > 0.0)
        set_member(player, m_Knife_flStabDistance, stabDistance);
}

public HandsAttack1_Post(item)
{
    if(is_nullent(item))
        return;

    new player = get_member(item, m_pPlayer);

    if(!IsZombie(player))
        return;

    new Float: flAttackTime = get_member(item, m_Weapon_flNextPrimaryAttack);
    new Float: flAttack2Time = 0.0;

    if(flAttackTime == flKnifeAttack1Time)
    {
        flAttack2Time = ArrayGetCell(aZombieData[Zombie_AttackDelay2], iRace[player]);
        flAttackTime = ArrayGetCell(aZombieData[Zombie_AttackDelay], iRace[player]);

        if(flAttackTime > 0.0)
            set_member(item, m_Weapon_flNextPrimaryAttack, flAttackTime);

        if(flAttack2Time > 0.0)
            set_member(item, m_Weapon_flNextSecondaryAttack, flAttackTime);
    }
    else if(flAttackTime == flKnifeAttack1Miss)
    {
        flAttack2Time = ArrayGetCell(aZombieData[Zombie_AttackDelayMiss2], iRace[player]);
        flAttackTime = ArrayGetCell(aZombieData[Zombie_AttackDelayMiss], iRace[player]);

        if(flAttackTime > 0.0)
            set_member(item, m_Weapon_flNextPrimaryAttack, flAttackTime);

        if(flAttack2Time > 0.0)
            set_member(item, m_Weapon_flNextSecondaryAttack, flAttackTime);
    }
}

public HandsAttack2_Post(item)
{
    if(is_nullent(item))
        return;

    new player = get_member(item, m_pPlayer);

    if(!IsZombie(player))
        return;

    new Float: flAttack2Time = get_member(item, m_Weapon_flNextSecondaryAttack);
    new Float: flAttackTime = 0.0;

    if(flAttack2Time == flKnifeAttack2Time)
    {
        flAttackTime = ArrayGetCell(aZombieData[Zombie_Attack2Delay1], iRace[player]);
        flAttack2Time = ArrayGetCell(aZombieData[Zombie_Attack2Delay], iRace[player]);

        if(flAttackTime > 0.0)
            set_member(item, m_Weapon_flNextPrimaryAttack, flAttackTime);

        if(flAttack2Time > 0.0)
            set_member(item, m_Weapon_flNextSecondaryAttack, flAttackTime);
    }
    else if(flAttack2Time == flKnifeAttack2Miss)
    {
        flAttackTime = ArrayGetCell(aZombieData[Zombie_AttackDelayMiss2], iRace[player]);
        flAttack2Time = ArrayGetCell(aZombieData[Zombie_AttackDelayMiss], iRace[player]);

        if(flAttackTime > 0.0)
            set_member(item, m_Weapon_flNextPrimaryAttack, flAttackTime);

        if(flAttack2Time > 0.0)
            set_member(item, m_Weapon_flNextSecondaryAttack, flAttackTime);
    }
}

stock MakeKnockback(id, attacker, Float:speed, Float:vecOrigin[3])
{
    new Float:vecAngles[3];
    get_entvar(attacker, var_v_angle, vecAngles);
    angle_vector(vecAngles, ANGLEVECTOR_FORWARD, vecOrigin);
    xs_vec_mul_scalar(vecOrigin, speed * 10.0, vecOrigin);

    new Float:vecVelocity[3]; get_entvar(id, var_velocity, vecVelocity);
    xs_vec_add(vecOrigin, vecVelocity, vecOrigin);

    if(!glbCvarValues[PC_KBVERTICAL])
        vecOrigin[2] = vecVelocity[2];

    set_entvar(id, var_velocity, vecOrigin);
}

stock GetGunPosition(id, Float:origin[3], Float:ret[3])
{
    new Float:vecView[3]; get_entvar(id, var_view_ofs, vecView);
    xs_vec_add(origin, vecView, vecView);
    ret = vecView;
}

/* *[-> CLIENT <-]* */
public client_connect( pPlayer )
{
    iRace[ pPlayer ] = 0;
    iNextRace[ pPlayer ] = 0;
}

public ReHook_CBasePlayer_Pain( pPlayer )
{
    if( !IsZombie( pPlayer ) )
        return HC_CONTINUE;

    new rand, szSound[ 64 ], Array: a;
    a = ArrayGetCell( aZombieData[ Zombie_HurtSounds ], iRace[ pPlayer ] );
    
    new size = ArraySize( a ) - 1;

    if ( a == Invalid_Array )
        return HC_CONTINUE;

    if ( size < 0 )
        return HC_SUPERCEDE;
    
    rand = random_num( 0, size );

    ArrayGetString( a, rand, szSound, charsmax( szSound ) );

    emit_sound( pPlayer, CHAN_VOICE, szSound, 1.0, ATTN_NORM, SND_SPAWNING, PITCH_NORM );

    return HC_SUPERCEDE;
}

public ReHook_CBasePlayer_Death( pPlayer )
{
    if( !IsZombie( pPlayer ) )
        return HC_CONTINUE;

    new rand, szSound[ 64 ], Array: a;
    a = ArrayGetCell( aZombieData[ Zombie_DeathSounds ], iRace[ pPlayer ] );
    
    new size = ArraySize( a ) - 1;

    if ( a == Invalid_Array )
        return HC_CONTINUE;

    if ( size < 0 )
        return HC_SUPERCEDE;
    
    rand = random_num( 0, size );

    ArrayGetString( a, rand, szSound, charsmax( szSound ) );

    emit_sound( pPlayer, CHAN_VOICE, szSound, 1.0, ATTN_NORM, SND_SPAWNING, PITCH_NORM );

    return HC_SUPERCEDE;
}

public ReHook_CBasePlayer_TakeDamage_Post( pPlayer, pInflictor, pAttacker, Float:flDamage, bitsDamage )
{
    if ( pPlayer == pAttacker || flDamage <= 0.0 || !(bitsDamage & DMG_BULLET || bitsDamage & DMG_SLASH) )
        return;

    if ( IsZombie( pAttacker ) || IsHuman( pPlayer ) )
        return;

    if ( get_entvar( pPlayer, var_armorvalue ) <= 0 )
        set_member( pPlayer, m_iKevlar, PlagueArmor_None );

    set_member( pPlayer, m_flVelocityModifier, ArrayGetCell( aZombieData[ Zombie_Painshock ], iRace[ pPlayer ] ) );
}

public ReHook_CBasePlayer_TakeDamage( pPlayer, pInflictor, pAttacker, Float:flDamage, bitsDamage )
{
    if ( pPlayer == pAttacker || flDamage <= 0.0 || !(bitsDamage & DMG_BULLET || bitsDamage & DMG_SLASH) )
        return HC_CONTINUE;

    if ( IsZombie( pAttacker ) || IsHuman( pPlayer ) )
        return HC_CONTINUE;

    new armor_value = get_entvar( pPlayer, var_armorvalue );
    new PlagueArmor: armor = get_member( pPlayer, m_iKevlar );

    if ( armor == PlagueArmor_None || ( armor == PlagueArmor_VestHelm && get_member( pPlayer, m_LastHitGroup ) == HITGROUP_HEAD ) )
        return HC_CONTINUE;

    new armor_dmg = floatround( flDamage * 0.25 );
    armor_value -= armor_dmg;

    if ( armor_value < 0 )
    {
        armor_dmg -= armor_value;
        armor_value = 0;
    }

    SetHookChainArg( 4, ATYPE_FLOAT, flDamage - float( armor_dmg ) );

    return HC_CONTINUE;
}

public Plague_Change_Class_Post( pPlayer, pAttacker, PlagueClassId: class, bool: bSpawned )
{
    if ( class != ZombieClassId )
        return;

    Transform( pPlayer, pAttacker, .bSpawned = bSpawned );
}

/* *[-> STOCKS <-]* */
stock Transform( pPlayer, pAttacker, bool:call = true, bool:bSpawned = true, bool:checkFlags = true )
{
    if ( call )
    {
        new ret;
        ExecuteForward( fwdZombify, _, pPlayer, pAttacker, bSpawned );
        
        if ( ret > Plague_Continue )
            return;
    }

    if ( iNextRace[ pPlayer ] != iRace[ pPlayer ] )
    {
        if ( !CanUseRace( pPlayer, iRace[ pPlayer ], checkFlags ) )
        {
            iNextRace[ pPlayer ] = iRace[ pPlayer ] = FirstRaceAvailable( pPlayer );
        }
        else {
            iRace[ pPlayer ] = iNextRace[ pPlayer ];
        }
    }

    if ( is_user_alive( pPlayer ) )
    {
        for(new any:i = 1; i < MAX_ITEM_TYPES; i++)
        {
            if(i < 3)
            rg_drop_items_by_slot(pPlayer, i);
            else
            rg_remove_items_by_slot(pPlayer, i);
        }

        rg_give_item(pPlayer, "weapon_hegrenade");
        new claw = rg_give_item(pPlayer, "weapon_knife");
        rg_switch_weapon(pPlayer, claw);

        if ( bSpawned )
        {
            new Array:a = ArrayGetCell( aZombieData[ Zombie_SpawnSounds ], iRace[ pPlayer ] );
            new size = ArraySize( a ) - 1;
            if ( size >= 0 )
            {
                new szSound[ 64 ];
                new rand = random_num( 0, size );
                ArrayGetString( a, rand, szSound, charsmax( szSound ) );
                emit_sound( pPlayer, CHAN_VOICE, szSound, 1.0, ATTN_NORM, SND_SPAWNING, PITCH_NORM );
            }
        }
        
        ResetTransformationStats( pPlayer, .bHealth = bSpawned );

        if ( pAttacker > -1 )
            TransformNotice( pPlayer, pAttacker );
    }

    if ( call )
        ExecuteForward( fwdZombified, _, pPlayer, pAttacker, bSpawned);
}

stock ResetTransformationStats( pPlayer, bool:bModel = true, bool:bHealth = true, bool:bGravity = true, bool:bSpeed = true )
{
    if ( !is_user_alive( pPlayer ) )
        return;
    
    new race = iRace[ pPlayer ];
    if ( bModel )
    {
        new szModel[ 32 ];
        ArrayGetString( aZombieData[ Zombie_Model ], race, szModel, charsmax( szModel ) );
        rg_set_user_model( pPlayer, szModel, true );
    }

    if ( bHealth )
    {
        new health = ArrayGetCell( aZombieData[ Zombie_Health ], race );
        set_entvar( pPlayer, var_health, float( health ) );
        set_entvar( pPlayer, var_max_health, float( health ) );
    }

    if ( bGravity )
    {
        new gravity = ArrayGetCell( aZombieData[ Zombie_Gravity ], race );
        set_entvar( pPlayer, var_gravity, float( gravity ) / 800.0 );
    }

    if ( bSpeed )
    {
        rg_reset_maxspeed( pPlayer );
    }
}

stock FirstRaceAvailable( pPlayer )
{
    new race = 0;
    for ( new i = 0; i < iRaceCount; i++ )
    {
        if ( CanUseRace( pPlayer, i ) )
        {
            race = i;
            break;
        }
    }

    return race;
}

stock bool:CanUseRace( pPlayer, race, bool:ignoreFlags = false )
{
    if( ignoreFlags )
        return true;

    new flags = 0;
    flags = ArrayGetCell( aZombieData[ Zombie_Flags ], race );

    if( ( get_user_flags( pPlayer ) & flags ) == flags || flags <= 0 )
        return true;

    return false;
}

stock bool:CanShow( pPlayer, race )
{
    new MenuShow: menuShow = ArrayGetCell( aZombieData[ Zombie_MenuShow ], race );

    if ( menuShow == MenuShow_No )
        return false;

    if ( menuShow == MenuShow_Flag )
    {
        new flags = ArrayGetCell( aZombieData[ Zombie_Flags ], race );

        if ( ( get_user_flags( pPlayer ) & flags ) == flags || flags <= 0 )
            return true;

        return false;
    }

    new ret;
    ExecuteForward( fwdShow, ret, pPlayer, race );

    if ( ret > Plague_Continue )
        return false;

    return true;
}

stock TransformNotice(id, attacker)
{
    static iDeathMsg, iScoreAttrib;
    if(!iDeathMsg) iDeathMsg = get_user_msgid("DeathMsg");
    if(!iScoreAttrib) iScoreAttrib = get_user_msgid("ScoreAttrib");

    message_begin(MSG_BROADCAST, iDeathMsg);
    write_byte(attacker);
    write_byte(id);
    write_byte(0);
    write_string("teammate");
    message_end();

    message_begin(MSG_BROADCAST, iScoreAttrib);
    write_byte(id);
    write_byte(0);
    message_end();
}

stock ShowRaceMenu( pPlayer )
{
    if ( iRaceCount <= 1 )
        return;
    
    new menu = menu_create( "Zombie Races", "RaceHandler" );

    new szFormat[ 128 ], szName[ 64 ];

    for ( new i = 0; i < iRaceCount; i++ )
    {
        if ( !CanShow( pPlayer, i ) )
            continue;

        ArrayGetString( aZombieData[ Zombie_Name ], i, szName, charsmax( szName ) );
        formatex( szFormat, charsmax( szFormat ), "%s%s", ( iNextRace[ pPlayer ] == i ? "\d" : "" ), szName );
        menu_additem( menu, szFormat, fmt( "%i", i ) );
    }

    menu_display( pPlayer, menu );
}

public RaceHandler( pPlayer, menu, item )
{
    if ( item == MENU_EXIT )
    {
        menu_destroy( menu );
        return;
    }

    new szDesc[ 3 ];
    menu_item_getinfo( menu, item, _, szDesc, charsmax( szDesc ) );

    new race = str_to_num( szDesc );

    new ret;
    ExecuteForward( fwdChoose, ret, pPlayer, race );

    if ( ret == Plague_Stop )
    {
        menu_display( pPlayer, menu );
        return;
    }

    menu_destroy( menu );

    if ( ret == Plague_Handled )
        return;

    if ( !CanUseRace( pPlayer, race, true ) )
        return;

    iNextRace[ pPlayer ] = race;

    ChatSelectionInfo( pPlayer );

    ExecuteForward( fwdChoosePost, _, pPlayer, race );
}

stock ChatSelectionInfo( pPlayer )
{
    new szName[ 64 ];
    new hp = ArrayGetCell( aZombieData[ Zombie_Health ], iNextRace[ pPlayer ]),
        gravity = ArrayGetCell( aZombieData[ Zombie_Gravity ], iNextRace[ pPlayer ]),
        Float: speed = ArrayGetCell( aZombieData[ Zombie_Speed ], iNextRace[ pPlayer ]),
        Float: kb = ArrayGetCell( aZombieData[ Zombie_Knockback ], iNextRace[ pPlayer ] );
    ArrayGetString( aZombieData[ Zombie_Name ], iNextRace[ pPlayer ], szName, charsmax( szName ) );

    client_print_color( pPlayer, 0, "^x04[ZP] ^x01You selected the ^x03Zombie Race: ^x04%s.", szName );
    client_print_color( pPlayer, 0, "^x04[ZP] ^x01Health: ^x04%i ^x03| ^x01Gravity: ^x04%i ^x03| ^x01Speed: ^x04%.2f ^x03| ^x01Knockback: ^x04%i%%^x01.", hp, gravity, speed, floatround( kb ) * 100 );
}

/* *[-> NATIVES <-]* */
public Native_RegRace( plgId, params )
{
    if ( params < 2 )
    {
        log_error( AMX_ERR_NATIVE, "Not enough params to execute." );
        return -1;
    }

    new szSysName[ 32 ];
    get_string( 1, szSysName, charsmax( szSysName ) );

    if ( strlen( szSysName ) <= 0 )
    {
        log_error( AMX_ERR_NATIVE, "Zombie Race can't be registered with empty name" );
        return -1;
    }

    new id, bool:exist;
    if ( ( exist = TrieKeyExists( tZombies, szSysName ) ) && TrieGetCell( tZombies, szSysName, id ) && ArrayGetCell( aZombiePlgLoaded, id ) )
    {
        log_error( AMX_ERR_NATIVE, "Zombie Race ^"%s^" was already loaded by a plugin.", szSysName );
        return -1;
    }

    if ( !exist )
    {
        new szName[ 64 ];
        get_string( 2, szName, charsmax( szName ) );

        new szModel[ 32 ];
        get_string( 3, szModel, charsmax( szModel ) );

        new szClaw[ 128 ];
        get_string( 4, szClaw, charsmax( szClaw ) );

        new health = get_param( 5 );
        new gravity = get_param( 6 );
        new Float:speed = get_param_f( 7 );
        new Float:kb = get_param_f( 8 );
        new Float:painshock = get_param_f( 9 );
        new Array:dSound = Array: get_param( 10 );
        new Array:sSound = Array: get_param( 11 );
        new Array:pSound = Array: get_param( 12 );
        new flags = get_param( 13 );
        new MenuShow: menuShow = MenuShow:get_param( 14 );

        return LoadRace( szSysName, szName, szClaw, szModel, dSound, sSound, pSound, 
            health, gravity, speed, painshock, kb, flags, menuShow );
    }

    new szName[ 64 ];
    new szModel[ 32 ];
    new szClaw[ 128 ];

    return LoadRace( szSysName, szName, szClaw, szModel, Invalid_Array, Invalid_Array, Invalid_Array, 
                0, 0, 0.0, 0.0, 0.0, 0, MenuShow_No );
}

public Native_RaceCount() return iRaceCount;

public Native_FirstAvailable( plgId, params )
{
    if ( params < 1 )
    {
        log_error( AMX_ERR_NATIVE, "Not enough params to execute." );
        return -1;
    }

    new id = get_param( 1 );

    if ( !is_user_connected( id ) )
    {
        log_error( AMX_ERR_NATIVE, "User %i not connected." );
        return -1;
    }

    return FirstRaceAvailable( id );
}

public Native_GetRace( plgId, params )
{
    if ( params < 1 )
    {
        log_error( AMX_ERR_NATIVE, "Not enough params to execute." );
        return -1;
    }

    new id = get_param( 1 );

    if ( !is_user_connected( id ) )
    {
        log_error( AMX_ERR_NATIVE, "User %i not connected." );
        return -1;
    }

    return iRace[ id ];
}

public Native_SetRace( plgId, params )
{
    if ( params < 5 )
    {
        log_error( AMX_ERR_NATIVE, "Not enough params to execute." );
        return;
    }

    new id = get_param( 1 );

    if ( !is_user_connected( id ) )
    {
        log_error( AMX_ERR_NATIVE, "User %i not connected." );
        return;
    }

    new race = get_param( 2 );

    if ( race < 0 || race >= iRaceCount )
    {
        log_error( AMX_ERR_NATIVE, "Race id invalid." );
        return;
    }

    new attacker = get_param( 3 );

    new bool:spawn = bool: get_param( 4 );
    new bool:check = bool: get_param( 5 );
    new bool:call = bool: get_param( 6 );

    iNextRace[ id ] = race;

    Transform( id, attacker, call, spawn, check );
}

public Native_GetNextRace( plgId, params )
{
    if ( params < 1 )
    {
        log_error( AMX_ERR_NATIVE, "Not enough params to execute." );
        return -1;
    }

    new id = get_param( 1 );

    if ( !is_user_connected( id ) )
    {
        log_error( AMX_ERR_NATIVE, "User %i not connected." );
        return -1;
    }

    return iNextRace[ id ];
}

public Native_SetNextRace( plgId, params )
{
    if ( params < 2 )
    {
        log_error( AMX_ERR_NATIVE, "Not enough params to execute." );
        return;
    }

    new id = get_param( 1 );

    if ( !is_user_connected( id ) )
    {
        log_error( AMX_ERR_NATIVE, "User %i not connected." );
        return;
    }

    new race = get_param( 2 );

    if ( race < 0 || race >= iRaceCount )
    {
        log_error( AMX_ERR_NATIVE, "Race id invalid." );
        return;
    }

    iNextRace[ id ] = race;
}

public any: Native_GetZombieData( plgId, params )
{
    if ( params < 2 )
    {
        log_error( AMX_ERR_NATIVE, "Not enough params to execute." );
        return 0;
    }

    new ZombieData: data = ZombieData: get_param( 1 );
    
    if ( data < Zombie_SystemName || data >= ZombieData )
    {
        log_error( AMX_ERR_NATIVE, "Zombie Data Invalid." );
        return 0;
    }

    new race = get_param( 2 );

    if ( race < 0 || race > iRaceCount )
    {
        log_error( AMX_ERR_NATIVE, "Race id invalid" );
        return 0;
    }

    switch( data )
    {
        case Zombie_Name: {
            if ( params < 4 )
            {
                log_error( AMX_ERR_NATIVE, "Not enough params to execute." );
                return 0;
            }

            new szString[ 64 ];
            ArrayGetString( aZombieData[ data ], race, szString, charsmax( szString ) );

            set_string( 3, szString, get_param( 4 ) );
        }

        case Zombie_SystemName, Zombie_Model: {
            if ( params < 4 )
            {
                log_error( AMX_ERR_NATIVE, "Not enough params to execute." );
                return 0;
            }

            new szString[ 32 ];
            ArrayGetString( aZombieData[ data ], race, szString, charsmax( szString ) );

            set_string( 3, szString, get_param( 4 ) );
        }

        case Zombie_Speed: {
            if ( params == 3 )
                set_float_byref( 3, ArrayGetCell( aZombieData[ data ], race ) );
            else 
                return ArrayGetCell( aZombieData[ data ], race );
        }

        default: {
            if ( params == 3 )
                set_param_byref( 3, ArrayGetCell( aZombieData[ data ], race ) );
            else
                return ArrayGetCell( aZombieData[ data ], race );
        }
    }

    return 1;
}

public Native_SetZombieData( plgId, params )
{
    if ( params < 3 )
    {
        log_error( AMX_ERR_NATIVE, "Not enough params to execute." );
        return 0;
    }

    new ZombieData: data = ZombieData: get_param( 1 );
    
    if ( data < Zombie_SystemName || data >= ZombieData )
    {
        log_error( AMX_ERR_NATIVE, "Zombie Data Invalid." );
        return 0;
    }

    new race = get_param( 2 );

    if ( race < 0 || race > iRaceCount )
    {
        log_error( AMX_ERR_NATIVE, "Race id invalid" );
        return 0;
    }

    switch( data )
    {
        case Zombie_Name: {
            new szString[ 64 ];
            get_string( 3, szString, charsmax( szString ) );
            ArraySetString( aZombieData[ data ], race, szString );
        }

        case Zombie_Model: {
            new szString[ 32 ];
            get_string( 3, szString, charsmax( szString ) );
            ArraySetString( aZombieData[ data ], race, szString );
        }

        case Zombie_SystemName: {
            log_error( AMX_ERR_NATIVE, "Zombie System Name cannot be changed." );
            return 0;
        }

        case Zombie_Speed: {
            ArraySetCell( aZombieData[ data ], race, get_param_f( 3 ) );
        }

        default: {
            ArrayGetCell( aZombieData[ data ], race, get_param( 3 ) );
        }
    }

    return 1;
}

public Native_ZombiesMenu( plgId, params )
{
    if ( params < 1 )
    {
        log_error( AMX_ERR_NATIVE, "Not enough params to execute." );
        return;
    }

    new id = get_param( 1 );

    if ( !is_user_connected( id ) )
    {
        log_error( AMX_ERR_NATIVE, "User %i not connected." );
        return;
    }

    ShowRaceMenu( id );
}

public Native_ResetAttr( pPlayer, bool:bModel, bool:bHealth, bool:bGravity, bool:bSpeed )
{
    if ( !is_user_connected( pPlayer ) )
    {
        log_error( AMX_ERR_NATIVE, "Player %i not connected.", pPlayer );
        return;
    }

    if ( !IsZombie( pPlayer ) )
    {
        log_error( AMX_ERR_NATIVE, "Attempted resetting attributes on non-Zombie class." );
        return;
    }

    ResetTransformationStats( pPlayer, bModel, bHealth, bGravity, bSpeed );
}