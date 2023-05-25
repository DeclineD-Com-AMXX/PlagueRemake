/* *[-> INCLUDES <-]* */
#include <amxmodx>
#include <amxmisc>
#include <reapi>

#include <plague_const>
#include <plague_human_const>
#include <plague_zombie_const>
#include <plague_armor>
#include <plague_rounds>
#include <plague_classes>
#include <plague_settings>

/* *[-> PLUGIN INFO <-]* */
new const pluginName[ ] = "[Plague] Class Human";
new const pluginVersion[ ] = "Final";
new const pluginAuthor[ ] = "DeclineD";

/* *[-> DEFINES <-]* */
#define IsHuman(%0) bool:(pr_get_user_class(%0) == HumanClassId)
#define IsZombie(%0) bool:(pr_get_user_class(%0) == ZombieClassId)
#define PlayerModelPath(%0) fmt("models/player/%s/%s.mdl", %0, %0)

/* *[-> SETTINGS <-]* */
new const pluginCfg[] = "addons/amxmodx/configs/plague.json";

new const szDataKeys[ HumanData ][ ] = {
    "name", "model", "death_sounds", "hurt_sounds", "health",
    "armor", "gravity", "speed", "painshock", "flags", "show_menu"
}

new const szDataDefault[ HumanData ][] = {
    "default", "terror", "player/die1.wav", "player/bhit_flesh-1.wav", "100",
    "100", "800", "250.0", "0.5", "", "2"
}

new JSON:ZombieSection = Invalid_JSON, JSON:RaceSection = Invalid_JSON;

new iRaceCount;
new Trie:tHumans, Array:aHumanSystemName, Array:aHumanPlgLoaded, Array:aHumanData[ HumanData ];
new bool:bReg = true;

LoadRaces( )
{
    if ( !bReg )
        return;
    
    if ( ZombieSection == Invalid_JSON )
    {
        ZombieSection = json_object_get_object_safe( pr_open_settings( pluginCfg ), PClass_Human );
        RaceSection = json_object_get_object_safe( ZombieSection, "races" );
    }

    new x, y, size, JSON:temp, JSON:temp2;
    new szSound[ 64 ], szString[ 32 ], any:value;
    new Array:aTemp, id, szFlags[ 30 ];

    for ( x = 0; x < json_object_get_count( RaceSection ); x++ )
    {
        json_object_get_name( RaceSection, x, szString, charsmax( szString ) );
        if ( TrieKeyExists( tHumans, szString ) )
            continue;
        
        AddRace( false, szString, szSound, szString, Invalid_Array, Invalid_Array, 0, 0, 0, 0.0, 0.0, 0, MenuShow_No);

        temp = json_object_get_object_at_safe( RaceSection, x );

        temp2 = json_object_get_string_safe( temp, szDataKeys[ Human_Name ], szDataDefault[ Human_Name ], szString, charsmax( szString ) );
        ArraySetString( aHumanData[ Human_Name ], id, szString );
        json_free( temp2 );

        temp2 = json_object_get_string_safe( temp, szDataKeys[ Human_Model ], szDataDefault[ Human_Model ], szString, charsmax( szString ) );
        ArraySetString( aHumanData[ Human_Model ], id, szString );
        json_free( temp2 );

        precache_model( PlayerModelPath( szString ) );

        aTemp = ArrayCreate( 64, 1 );

        temp2 = json_object_get_array_safe( temp, szDataKeys[ Human_DeathSounds ] );
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
            json_array_append_string( temp2, szDataDefault[ Human_DeathSounds ] );
            precache_sound( szDataDefault[ Human_DeathSounds ] );
            ArrayPushString( aTemp, szDataDefault[ Human_DeathSounds ] );
        }

        ArraySetCell( aHumanData[ Human_DeathSounds ], id, aTemp );
        json_free( temp2 );

        temp2 = json_object_get_array_safe( temp, szDataKeys[ Human_HurtSounds ] );
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
            json_array_append_string( temp2, szDataDefault[ Human_HurtSounds ] );
            precache_sound( szDataDefault[ Human_HurtSounds ] );
            ArrayPushString( aTemp, szDataDefault[ Human_HurtSounds ] );
        }

        ArraySetCell( aHumanData[ Human_HurtSounds ], id, aTemp );
        json_free( temp2 );

        temp2 = json_object_get_value_safe( temp, szDataKeys[ Human_Health ], szDataDefault[ Human_Health ], JSONNumber, value );
        ArraySetCell( aHumanData[ Human_Health ], id, value );
        json_free( temp2 );

        temp2 = json_object_get_value_safe( temp, szDataKeys[ Human_Armor ], szDataDefault[ Human_Armor ], JSONNumber, value );
        ArraySetCell( aHumanData[ Human_Armor ], id, value );
        json_free( temp2 );

        temp2 = json_object_get_value_safe( temp, szDataKeys[ Human_Gravity ], szDataDefault[ Human_Gravity ], JSONNumber, value );
        ArraySetCell( aHumanData[ Human_Gravity ], id, value );
        json_free( temp2 );

        temp2 = json_object_get_value_safe( temp, szDataKeys[ Human_Speed ], szDataDefault[ Human_Speed ], JSONNumber, value );
        ArraySetCell( aHumanData[ Human_Speed ], id, value );
        json_free( temp2 );

        temp2 = json_object_get_value_safe( temp, szDataKeys[ Human_Painshock ], szDataDefault[ Human_Painshock ], JSONNumber, value );
        ArraySetCell( aHumanData[ Human_Painshock ], id, value );
        json_free( temp2 );

        temp2 = json_object_get_string_safe( temp, szDataKeys[ Human_Flags ], "", szFlags, charsmax( szFlags ) );
        value = read_flags( szFlags );
        ArraySetCell( aHumanData[ Human_Flags ], id, value );
        json_free( temp2 );

        temp2 = json_object_get_value_safe( temp, szDataKeys[ Human_MenuShow ], szDataDefault[ Human_MenuShow ], JSONNumber, value );
        ArraySetCell( aHumanData[ Human_MenuShow ], id, value );
        json_free( temp2 );
        json_free( temp );
    }
}

LoadRace( szSysName[ 32 ], szName[ 64 ], szModel[ 32 ], Array:dSounds, Array:pSounds, health, armor, gravity, Float:speed, Float:painshock, flags, MenuShow:menuShow )
{
    if ( !bReg )
        return -1;
    
    if ( ZombieSection == Invalid_JSON )
    {
        ZombieSection = json_object_get_object_safe( pr_open_settings( pluginCfg ), PClass_Human );
        RaceSection = json_object_get_object_safe( ZombieSection, "races" );
    }

    new id;
    if ( !TrieKeyExists( tHumans, szSysName ) )
    {
        new y, size, JSON:temp, JSON:temp2;

        new szFlags[ 30 ], szSound[ 64 ];

        id = iRaceCount;
        AddRace(true, szSysName, "", "", Invalid_Array, Invalid_Array, 0, 0, 0, 0.0, 0.0, 0, MenuShow_No);

        temp = json_object_get_object_safe( RaceSection, szSysName );

        temp2 = json_object_get_string_safe( temp, szDataKeys[ Human_Name ], szName, szName, charsmax( szName ) );
        ArraySetString( aHumanData[ Human_Name ], id, szName );
        json_free( temp2 );

        temp2 = json_object_get_string_safe( temp, szDataKeys[ Human_Model ], szModel, szModel, charsmax( szModel ) );
        ArraySetString( aHumanData[ Human_Model ], id, szModel );
        json_free( temp2 );

        precache_model( PlayerModelPath( szModel ) );

        if ( dSounds == Invalid_Array )
            dSounds = ArrayCreate( 64, 1 );

        if ( pSounds == Invalid_Array )
            pSounds = ArrayCreate( 64, 1 );

        temp2 = json_object_get_array_safe( temp, szDataKeys[ Human_DeathSounds ] );
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

        ArraySetCell( aHumanData[ Human_DeathSounds ], id, dSounds );
        json_free( temp2 );

        temp2 = json_object_get_array_safe( temp, szDataKeys[ Human_HurtSounds ] );
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

        ArraySetCell( aHumanData[ Human_HurtSounds ], id, pSounds );
        json_free( temp2 );

        get_flags( flags, szFlags, charsmax( szFlags ) );

        formatex( szSound, charsmax( szSound ), "%i", health );
        temp2 = json_object_get_value_safe( temp, szDataKeys[ Human_Health ], szSound, JSONNumber, health );
        ArraySetCell( aHumanData[ Human_Health ], id, health );
        json_free( temp2 );

        formatex( szSound, charsmax( szSound ), "%i", armor );
        temp2 = json_object_get_value_safe( temp, szDataKeys[ Human_Armor ], szSound, JSONNumber, armor );
        ArraySetCell( aHumanData[ Human_Armor ], id, armor );
        json_free( temp2 );

        formatex( szSound, charsmax( szSound ), "%i", gravity );
        temp2 = json_object_get_value_safe( temp, szDataKeys[ Human_Gravity ], szSound, JSONNumber, gravity );
        ArraySetCell( aHumanData[ Human_Gravity ], id, gravity );
        json_free( temp2 );

        formatex( szSound, charsmax( szSound ), "%f", speed );
        temp2 = json_object_get_value_safe( temp, szDataKeys[ Human_Speed ], szSound, JSONNumber, speed );
        ArraySetCell( aHumanData[ Human_Speed ], id, speed );
        json_free( temp2 );

        formatex( szSound, charsmax( szSound ), "%f", painshock );
        temp2 = json_object_get_value_safe( temp, szDataKeys[ Human_Painshock ], szSound, JSONNumber, painshock );
        ArraySetCell( aHumanData[ Human_Painshock ], id, painshock );
        json_free( temp2 );

        temp2 = json_object_get_string_safe( temp, szDataKeys[ Human_Flags ], szFlags, szFlags, charsmax( szFlags ) );
        flags = read_flags( szFlags );
        ArraySetCell( aHumanData[ Human_Flags ], id, flags );
        json_free( temp2 );

        formatex( szSound, charsmax( szSound ), "%i", menuShow );
        temp2 = json_object_get_value_safe( temp, szDataKeys[ Human_MenuShow ], szSound, JSONNumber, menuShow );
        ArraySetCell( aHumanData[ Human_MenuShow ], id, menuShow );
        json_free( temp2 );
        json_free( temp );
    }
    else {
        TrieGetCell( tHumans, szSysName, id );

        if ( ArrayGetCell( aHumanPlgLoaded, id ) == true )
            return -1;

        ArraySetCell( aHumanPlgLoaded, id, true );
    }

    return id;
}

AddRace( bool: plg, szSysName[ 32 ], szName[ 64 ], szModel[ 32 ], Array:dSounds, Array:pSounds, health, armor, gravity, Float:speed, Float:painshock, flags, MenuShow:menuShow )
{
    TrieSetCell( tHumans, szSysName, iRaceCount );
    ArrayPushString( aHumanSystemName, szSysName );
    ArrayPushCell( aHumanPlgLoaded, plg );

    ArrayPushString( aHumanData[ Human_Name ], szName );
    ArrayPushString( aHumanData[ Human_Model ], szModel );
    ArrayPushCell( aHumanData[ Human_DeathSounds ], dSounds );
    ArrayPushCell( aHumanData[ Human_HurtSounds ], pSounds );
    ArrayPushCell( aHumanData[ Human_Health ], health );
    ArrayPushCell( aHumanData[ Human_Armor ], armor );
    ArrayPushCell( aHumanData[ Human_Gravity ], gravity );
    ArrayPushCell( aHumanData[ Human_Speed ], speed );
    ArrayPushCell( aHumanData[ Human_Painshock ], painshock );

    ArrayPushCell( aHumanData[ Human_Flags ], flags );
    
    ArrayPushCell( aHumanData[ Human_MenuShow ], menuShow );

    iRaceCount++;
}

/* *[-> VARIABLES <-]* */
new PlagueClassId: HumanClassId;
new PlagueClassId: ZombieClassId;

new iRace[ MAX_PLAYERS + 1 ];
new iNextRace[ MAX_PLAYERS + 1 ];

new InfectionType: iInfectionType[ MAX_PLAYERS + 1 ];

new fwdHumanize, fwdHumanized;
new fwdShow;
new fwdChoose, fwdChoosePost;

/* *[-> PLUGIN <-]* */
public plugin_precache( )
{
    HumanClassId = pr_register_class( PClass_Human, TEAM_CT );

    tHumans = TrieCreate( );
    aHumanSystemName = ArrayCreate( 32, 1 );
    aHumanPlgLoaded = ArrayCreate( 1, 1 );
    
    aHumanData[ Human_Name ] = ArrayCreate( 64, 1 );
    aHumanData[ Human_Model ] = ArrayCreate( 32, 1 );
    aHumanData[ Human_DeathSounds ] = ArrayCreate( 1, 1 );
    aHumanData[ Human_HurtSounds ] = ArrayCreate( 1, 1 );
    aHumanData[ Human_Health ] = ArrayCreate( 1, 1 );
    aHumanData[ Human_Armor ] = ArrayCreate( 1, 1 );
    aHumanData[ Human_Painshock ] = ArrayCreate( 1, 1 );
    aHumanData[ Human_Gravity ] = ArrayCreate( 1, 1 );
    aHumanData[ Human_Speed ] = ArrayCreate( 1, 1 );
    aHumanData[ Human_Flags ] = ArrayCreate( 1, 1 );
    aHumanData[ Human_MenuShow ] = ArrayCreate( 1, 1 );

    LoadRaces( );

    fwdHumanize = CreateMultiForward( "Plague_Humanize", ET_CONTINUE, FP_CELL, FP_CELL, FP_CELL );
    fwdHumanized = CreateMultiForward( "Plague_Humanize_Post", ET_CONTINUE, FP_CELL, FP_CELL, FP_CELL );
    fwdShow = CreateMultiForward( "Plague_ShowHumanInMenu", ET_CONTINUE, FP_CELL, FP_CELL );
    fwdChoose = CreateMultiForward( "Plague_ChooseHumanRace", ET_CONTINUE, FP_CELL, FP_CELL );
    fwdChoosePost = CreateMultiForward( "Plague_ChooseHumanRace_Post", ET_IGNORE, FP_CELL, FP_CELL );
}

public plugin_natives( )
{
    register_native( "pr_register_human_race", "Native_RegRace" );

    register_native( "pr_get_human_race_count", "Native_RaceCount", 1 );

    register_native( "pr_first_available_human_race", "Native_FirstAvailable" );

    register_native( "pr_get_user_human_race", "Native_GetRace" );
    register_native( "pr_set_user_human_race", "Native_SetRace" );

    register_native( "pr_get_user_next_human_race", "Native_GetNextRace" );
    register_native( "pr_set_user_next_human_race", "Native_SetNextRace" );

    register_native( "pr_set_user_infection_type", "Native_SetInfType", 1 );
    register_native( "pr_get_user_infection_type", "Native_GetInfType", 1 );

    register_native( "pr_set_human_data", "Native_SetHumanData" );
    register_native( "pr_get_human_data", "Native_GetHumanData" );

    register_native("pr_open_humans_menu", "Native_HumansMenu" );

    register_native( "pr_reset_human_attributes", "Native_ResetAttr", 1 );
}

public Native_SetInfType( id, InfectionType:type )
{
    if ( !is_user_connected( id ) && id != 0 )
    {
        log_error( AMX_ERR_NATIVE, "User %i is not connected.", id );
        return;
    }

    if ( type < Infection_No || type >= InfectionType )
    {
        log_error( AMX_ERR_NATIVE, "Infection type invalid." );
        return;
    }

    if ( id != 0 )
    {
        iInfectionType[ id ] = type;
    }
    else
    {
        for(new i = 0; i < 33; i++)
        {
            iInfectionType[ i ] = type;
        }
    }
}

public InfectionType:Native_GetInfType( id )
{
    if ( !is_user_connected( id ) && id != 0 )
    {
        log_error( AMX_ERR_NATIVE, "User %i is not connected.", id );
        return Infection_No;
    }

    return iInfectionType[ id ];
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

    ZombieClassId = pr_get_class_id( PClass_Zombie );

    iInfectionType[ 0 ] = Infection_No;

    RegisterHookChain( RG_CBasePlayer_Pain, "ReHook_CBasePlayer_Pain", 1 );
    RegisterHookChain( RG_CBasePlayer_DeathSound, "ReHook_CBasePlayer_Death", 1 );

    RegisterHookChain( RG_CBasePlayer_TakeDamage, "ReHook_CBasePlayer_TakeDamage" );
    RegisterHookChain( RG_CBasePlayer_TakeDamage, "ReHook_CBasePlayer_TakeDamage_Post", 1 );

    RegisterHookChain(RG_CBasePlayer_ResetMaxSpeed, "ResetSpeed_Post", 1);
}

public plugin_end( )
{
    if ( ZombieSection != Invalid_JSON )
        json_free( ZombieSection );

    if ( RaceSection != Invalid_JSON )
        json_free( RaceSection );

    TrieDestroy( tHumans );
    ArrayDestroy( aHumanSystemName );

    new any:i, x, Array:a;
    for ( i = 0; i < HumanData; i++ )
    {
        if ( i == Human_DeathSounds || i == Human_HurtSounds )
        {
            for ( x = 0; x < iRaceCount; x++ )
            {
                a = Array:ArrayGetCell( aHumanData[ i ], x )
                ArrayDestroy( a );
            }
        }

        ArrayDestroy( aHumanData[ i ] );
    }
}

/* *[-> NOWHERE TO PUT SHIT <-]* */
public ResetSpeed_Post(id)
{
    if(!IsHuman(id) || get_member_game(m_bFreezePeriod))
        return;

    new Float: flSpeed = ArrayGetCell(aHumanData[Human_Speed], iRace[id]);

    new Float: maxspeed = get_entvar(id, var_maxspeed);
    maxspeed += (flSpeed - 250.0);

    set_entvar(id, var_maxspeed, maxspeed);
}

/* *[-> CLIENT <-]* */
public client_connect( pPlayer )
{
    iInfectionType[ pPlayer ] = Infection_No;
    iRace[ pPlayer ] = 0;
    iNextRace[ pPlayer ] = 0;
}

public ReHook_CBasePlayer_Pain( pPlayer )
{
    if( !IsHuman( pPlayer ) )
        return HC_CONTINUE;

    new rand, szSound[ 64 ], Array: a;
    a = ArrayGetCell( aHumanData[ Human_HurtSounds ], iRace[ pPlayer ] );
    
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
    if( !IsHuman( pPlayer ) )
        return HC_CONTINUE;

    new rand, szSound[ 64 ], Array: a;
    a = ArrayGetCell( aHumanData[ Human_DeathSounds ], iRace[ pPlayer ] );
    
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

public ReHook_CBasePlayer_TakeDamage( pPlayer, pInflictor, pAttacker, Float:flDamage, bitsDamage )
{
    if ( pr_round_status( ) != RoundStatus_Started )
    {
        SetHookChainReturn( ATYPE_INTEGER, 0 );
        return HC_SUPERCEDE;
    }

    if ( pPlayer == pAttacker || flDamage <= 0.0 )
        return HC_CONTINUE;

    if ( ( ~bitsDamage & DMG_BULLET ) && ( ~bitsDamage & DMG_SLASH ) )
        return HC_CONTINUE;

    if ( IsHuman( pAttacker ) || IsZombie( pPlayer ) || !is_user_connected( pPlayer ) || !is_user_connected( pAttacker ) || iInfectionType[ pPlayer ] == Infection_Damage )
        return HC_CONTINUE;

    if ( iInfectionType[ pPlayer ] == Infection_No )
    {
        SetHookChainReturn( ATYPE_INTEGER, 0 );
        return HC_SUPERCEDE;
    }

    new Float:flPainshock = ArrayGetCell( aHumanData[ Human_Painshock ], iRace[ pPlayer ] );

    if ( iInfectionType[ pPlayer ] == Infection_DamageArmor )
    {
        new Float:armor_value = get_entvar( pPlayer, var_armorvalue );
        new PlagueArmor: armor = get_member( pPlayer, m_iKevlar );

        if ( armor == PlagueArmor_None )
            return HC_CONTINUE;

        if ( get_member( pPlayer, m_LastHitGroup ) == HITGROUP_HEAD && armor != PlagueArmor_VestHelm )
            return HC_CONTINUE;

        if ( armor_value <= 0 )
            return HC_CONTINUE;

        new Float: armor_dmg = flDamage * pr_get_user_armor_damage( pAttacker ) * pr_get_user_armor_protection( pPlayer );
        armor_value -= armor_dmg;

        if ( armor_value < 0 )
        {
            set_member( pPlayer, m_iKevlar, PlagueArmor_None );
            armor_dmg -= armor_value;
            armor_value = 0.0;
        }

        set_entvar( pPlayer, var_armorvalue, armor_value );

        SetHookChainArg( 4, ATYPE_FLOAT, flDamage - armor_dmg );

        return HC_CONTINUE;
    }
    else if ( iInfectionType[ pPlayer ] == Infection_InfectArmor )
    {
        new Float: armor_value = get_entvar( pPlayer, var_armorvalue );
        new PlagueArmor: armor = get_member( pPlayer, m_iKevlar );

        if ( ( ( get_member( pPlayer, m_LastHitGroup ) == HITGROUP_HEAD && armor == PlagueArmor_VestHelm ) 
        || ( armor != PlagueArmor_None && iInfectionType[ pPlayer ] == Infection_InfectArmor ) )
        && armor_value > 0 )
        {
            new Float: armor_dmg = flDamage * pr_get_user_armor_damage( pAttacker ) * pr_get_user_armor_protection( pPlayer );
            armor_value -= armor_dmg;

            if ( armor_value < 0 )
            {
                set_member( pPlayer, m_iKevlar, PlagueArmor_None );
                armor_dmg -= armor_value;
                armor_value = 0.0;
            }

            set_entvar( pPlayer, var_armorvalue, armor_value );
            set_member( pPlayer, m_flVelocityModifier, flPainshock );

            ReHook_CBasePlayer_Pain( pPlayer );

            SetHookChainReturn( ATYPE_INTEGER, 0 );
            return HC_SUPERCEDE;
        }
    }

    set_member( pPlayer, m_flVelocityModifier, flPainshock );

    set_member( pPlayer, m_iKevlar, PlagueArmor_None );
    pr_change_class( pPlayer, pAttacker, ZombieClassId, true );

    SetHookChainReturn( ATYPE_INTEGER, 0 );
    return HC_SUPERCEDE;
}

public ReHook_CBasePlayer_TakeDamage_Post( pPlayer, pInflictor, pAttacker, Float:flDamage, bitsDamage )
{
    if ( pPlayer == pAttacker || flDamage <= 0.0 )
        return;

    if ( ( ~bitsDamage & DMG_BULLET ) && ( ~bitsDamage & DMG_SLASH ) )
        return;

    if ( IsHuman( pAttacker ) || IsZombie( pPlayer ) )
        return;

    set_member( pPlayer, m_flVelocityModifier, ArrayGetCell( aHumanData[ Human_Painshock ], iRace[ pPlayer ] ) );
}

public Plague_Change_Class_Post( pPlayer, pAttacker, PlagueClassId: class, bool: bSpawned )
{
    if ( class != HumanClassId )
        return;

    Transform( pPlayer, pAttacker, .bSpawned = bSpawned );
}

/* *[-> STOCKS <-]* */
stock Transform( pPlayer, pAttacker, bool:call = true, bool:bSpawned = true, bool:checkFlags = true )
{
    if ( call )
    {
        new ret;
        ExecuteForward( fwdHumanize, _, pPlayer, pAttacker, bSpawned );
        
        if ( ret > Plague_Continue )
            return;
    }

    iInfectionType[ pPlayer ] = iInfectionType[ 0 ];

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

        rg_give_item( pPlayer, "weapon_knife" );
        rg_give_item( pPlayer, "weapon_usp" );
        rg_set_user_bpammo( pPlayer, WEAPON_USP, 12 * 5 );

        ResetTransformationStats( pPlayer, .bHealth = bSpawned );

        if ( pAttacker > -1 )
            TransformNotice( pPlayer, pAttacker );
    }

    if ( call )
        ExecuteForward( fwdHumanized, _, pPlayer, pAttacker, bSpawned);
}

stock ResetTransformationStats( pPlayer, bool:bModel = true, bool:bHealth = true, bool:bArmor = true, bool:bGravity = true, bool:bSpeed = true )
{
    new race = iRace[ pPlayer ];
    if ( bModel )
    {
        new szModel[ 32 ];
        ArrayGetString( aHumanData[ Human_Model ], race, szModel, charsmax( szModel ) );
        rg_set_user_model( pPlayer, szModel, true );
    }

    if ( bHealth )
    {
        new health = ArrayGetCell( aHumanData[ Human_Health ], race );
        set_entvar( pPlayer, var_health, float( health ) );
        set_entvar( pPlayer, var_max_health, float( health ) );
    }

    if ( bArmor )
    {
        new armor = ArrayGetCell( aHumanData[ Human_Armor ], race );
        
        if ( armor )
        {
            rg_give_item( pPlayer, "item_assaultsuit" );
            set_entvar( pPlayer, var_armorvalue, float( armor ) );
        }
    }

    if ( bGravity )
    {
        new gravity = ArrayGetCell( aHumanData[ Human_Gravity ], race );
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
    flags = ArrayGetCell( aHumanData[ Human_Flags ], race );

    if( ( get_user_flags( pPlayer ) & flags ) == flags || flags <= 0 )
        return true;

    return false;
}

stock bool:CanShow( pPlayer, race )
{
    new MenuShow: menuShow = ArrayGetCell( aHumanData[ Human_MenuShow ], race );

    if ( menuShow == MenuShow_No )
        return false;

    if ( menuShow == MenuShow_Flag )
    {
        new flags = ArrayGetCell( aHumanData[ Human_Flags ], race );

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

stock ShowRaceMenu( pPlayer )
{
    if ( iRaceCount <= 1 )
        return;
    
    new menu = menu_create( "Human Races", "RaceHandler" );

    new szFormat[ 128 ], szName[ 64 ];

    for ( new i = 0; i < iRaceCount; i++ )
    {
        if ( !CanShow( pPlayer, i ) )
            continue;
        
        ArrayGetString( aHumanData[ Human_Name ], i, szName, charsmax( szName ) );
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
    new hp = ArrayGetCell( aHumanData[ Human_Health ], iNextRace[ pPlayer ]),
        gravity = ArrayGetCell( aHumanData[ Human_Gravity ], iNextRace[ pPlayer ]),
        Float: speed = ArrayGetCell( aHumanData[ Human_Speed ], iNextRace[ pPlayer ]);

    ArrayGetString( aHumanData[ Human_Name ], iNextRace[ pPlayer ], szName, charsmax( szName ) );

    client_print_color( pPlayer, 0, "^x04[ZP] ^x01You selected the ^x03human race: ^x04%s.", szName );
    client_print_color( pPlayer, 0, "^x04[ZP] ^x01Health: ^x04%i ^x03| ^x01Gravity: ^x04%i ^x03| ^x01Speed: ^x04%.2f^x01.", hp, gravity, speed );
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
        log_error( AMX_ERR_NATIVE, "Human Race can't be registered with empty name" );
        return -1;
    }

    new id, bool:exist;
    if ( ( exist = TrieKeyExists( tHumans, szSysName ) ) && TrieGetCell( tHumans, szSysName, id ) && ArrayGetCell( aHumanPlgLoaded, id ) )
    {
        log_error( AMX_ERR_NATIVE, "Human Race ^"%s^" was already loaded by a plugin.", szSysName );
        return -1;
    }

    if ( !exist )
    {
        new szName[ 64 ];
        get_string( 2, szName, charsmax( szName ) );

        new szModel[ 32 ];
        get_string( 3, szModel, charsmax( szModel ) );

        new health = get_param( 4 );
        new armor = get_param( 5 );
        new gravity = get_param( 6 );
        new Float:speed = get_param_f( 7 );
        new Float:painshock = get_param_f( 8 );
        new Array:dSound = Array: get_param( 9 );
        new Array:pSound = Array: get_param( 10 );
        new MenuShow: menuShow = MenuShow:get_param( 11 );
        new flags = get_param( 12 );

        return LoadRace( szSysName, szName, szModel, dSound, pSound, 
                health, armor, gravity, speed, painshock, flags, menuShow );
    }

    new szName[ 64 ];
    new szModel[ 32 ];

    return LoadRace( szSysName, szName, szModel, Invalid_Array, Invalid_Array, 
                0, 0, 0, 0.0, 0.0, 0, MenuShow_No );
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

public any: Native_GetHumanData( plgId, params )
{
    if ( params < 2 )
    {
        log_error( AMX_ERR_NATIVE, "Not enough params to execute." );
        return 0;
    }

    new HumanData: data = HumanData: get_param( 1 );
    
    if ( data < Human_SystemName || data >= HumanData )
    {
        log_error( AMX_ERR_NATIVE, "Human Data Invalid." );
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
        case Human_Name: {
            if ( params < 4 )
            {
                log_error( AMX_ERR_NATIVE, "Not enough params to execute." );
                return 0;
            }

            new szString[ 64 ];
            ArrayGetString( aHumanData[ data ], race, szString, charsmax( szString ) );

            set_string( 3, szString, get_param( 4 ) );
        }

        case Human_SystemName, Human_Model: {
            if ( params < 4 )
            {
                log_error( AMX_ERR_NATIVE, "Not enough params to execute." );
                return 0;
            }

            new szString[ 32 ];
            ArrayGetString( aHumanData[ data ], race, szString, charsmax( szString ) );

            set_string( 3, szString, get_param( 4 ) );
        }

        case Human_Speed, Human_Painshock: {
            if ( params == 3 )
                set_float_byref( 3, ArrayGetCell( aHumanData[ data ], race ) );
            else 
                return ArrayGetCell( aHumanData[ data ], race );
        }

        default: {
            if ( params == 3 )
                set_param_byref( 3, ArrayGetCell( aHumanData[ data ], race ) );
            else
                return ArrayGetCell( aHumanData[ data ], race );
        }
    }

    return 1;
}

public Native_SetHumanData( plgId, params )
{
    if ( params < 3 )
    {
        log_error( AMX_ERR_NATIVE, "Not enough params to execute." );
        return 0;
    }

    new HumanData: data = HumanData: get_param( 1 );
    
    if ( data < Human_SystemName || data >= HumanData )
    {
        log_error( AMX_ERR_NATIVE, "Human Data Invalid." );
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
        case Human_Name: {
            new szString[ 64 ];
            get_string( 3, szString, charsmax( szString ) );
            ArraySetString( aHumanData[ data ], race, szString );
        }

        case Human_Model: {
            new szString[ 32 ];
            get_string( 3, szString, charsmax( szString ) );
            ArraySetString( aHumanData[ data ], race, szString );
        }

        case Human_SystemName: {
            log_error( AMX_ERR_NATIVE, "Human System Name cannot be changed." );
            return 0;
        }

        case Human_Speed, Human_Painshock: {
            ArraySetCell( aHumanData[ data ], race, get_param_f( 3 ) );
        }

        default: {
            ArrayGetCell( aHumanData[ data ], race, get_param( 3 ) );
        }
    }

    return 1;
}

public Native_HumansMenu( plgId, params )
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

public Native_ResetAttr( pPlayer, bool:bModel, bool:bHealth, bool:bArmor, bool:bGravity, bool:bSpeed )
{
    if ( !is_user_connected( pPlayer ) )
    {
        log_error( AMX_ERR_NATIVE, "Player %i not connected.", pPlayer );
        return;
    }

    if ( !IsHuman( pPlayer ) )
    {
        log_error( AMX_ERR_NATIVE, "Attempted resetting attributes on non-human class." );
        return;
    }

    ResetTransformationStats( pPlayer, bModel, bHealth, bArmor, bGravity, bSpeed );
}