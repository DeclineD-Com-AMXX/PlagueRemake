/* *[-> INCLUDES <-]* */
#include <amxmodx>
#include <hamsandwich>
#include <reapi>

#include <plague_armor_const>

/* *[-> VARIABLES <-]* */
new Float: flArmorDamage[ MAX_PLAYERS + 1 ];
new Float: flArmorProtection[ MAX_PLAYERS + 1 ];

enum 
{
    Protection = 0,
    Damage
}

new fwdSetArmor[ 2 ];

/* *[-> PLUGIN <-]* */
public plugin_natives( )
{
    register_native( "pr_get_user_armor_protection", "Native_GetProt", 1 );
    register_native( "pr_get_user_armor_damage", "Native_GetDmg", 1 );
    register_native( "pr_set_user_armor_damage", "Native_SetDmg", 1 );
    register_native( "pr_set_user_armor_protection", "Native_SetProt", 1);
}

public plugin_precache( )
{
    fwdSetArmor[ Protection ] = CreateMultiForward( "Plague_SetArmorProtection", ET_IGNORE, FP_CELL, FP_CELL );
    fwdSetArmor[ Damage ] = CreateMultiForward( "Plague_SetArmorDamage", ET_IGNORE, FP_CELL, FP_CELL );
}

public plugin_init( )
{
    register_plugin( "[Plague] Custom Armor", "v1.0", "DeclineD" );

    flArmorDamage[ 0 ] = 1.0;
    flArmorProtection[ 0 ] = 1.0;

    RegisterHam( Ham_Touch, "item_kevlar", "HamHook_Armor_Touched", 1 );
    RegisterHam( Ham_Touch, "item_assaultsuit", "HamHook_Armor_Touched", 1 );
    RegisterHam( Ham_Killed, "player", "HamHook_Killed", 1 );
}

/* *[-> CLIENT <-]* */
public client_putinserver( pPlayer )
{
    flArmorDamage[ pPlayer ] = flArmorDamage[ 0 ];
    flArmorProtection[ pPlayer ] = flArmorProtection[ 0 ];
}

/* *[-> HAMSANDWICH <-]* */
public HamHook_Killed( pPlayer )
{
    set_member( pPlayer, m_iKevlar, 0 );
}

public HamHook_Armor_Touched( pItem, pPlayer )
{
    set_member( pPlayer, m_iKevlar, get_member( pPlayer, m_iKevlar ) + 2 );
}

/* *[-> NATIVES <-]* */
public Native_SetDmg( id, Float: percent )
{
    if ( id < 1 || id > 32 )
    {
        log_error( AMX_ERR_NATIVE, "Invalid player id %i.", id );
        return;
    }

    flArmorDamage[ id ] = percent;

    ExecuteForward( fwdSetArmor[ Damage ], _, id, percent );
}

public Native_SetProt( id, Float: percent )
{
    if ( id < 1 || id > 32 )
    {
        log_error( AMX_ERR_NATIVE, "Invalid player id %i.", id );
        return;
    }

    flArmorProtection[ id ] = percent;

    ExecuteForward( fwdSetArmor[ Protection ], _, id, percent );
}

public Float: Native_GetDmg( id )
{
    if ( id < 1 || id > 32 )
    {
        log_error( AMX_ERR_NATIVE, "Invalid player id %i.", id );
        return 0.0;
    }

    return flArmorDamage[ id ];
}

public Float: Native_GetProt( id )
{
    if ( id < 1 || id > 32 )
    {
        log_error( AMX_ERR_NATIVE, "Invalid player id %i.", id );
        return 0.0;
    }

    return flArmorProtection[ id ];
}