#include <amxmodx>
#include <reapi>
#include <plague_settings>
#include <plague_classes>
#include <plague_human>

new const pluginCfg[] = "addons/amxmodx/configs/plague.json";

enum _:WpnData {
    any: WEAPON_SYSNAME,
    any: WEAPON_NAME,
    any: WEAPON_ID,
    any: WEAPON_AMMO
}

enum {
    PRIMARY,
    SECONDARY,
    GRENADE,
    MAX_SLOTS
}

new szSlotKey[ MAX_SLOTS ][ ] = { "primary", "secondary", "grenade" };

new Trie:tWeapons, gaWpnData[ MAX_SLOTS ][ WpnData ], wpnCount[ MAX_SLOTS ];
new iLastWpn[ MAX_PLAYERS + 1 ][ GRENADE ];

new PlagueClassId:HumanClassId;

new bitShow, bitShowed;

public plugin_init()
{
    register_plugin("[Plague] Weapon Menu", "v1.0", "DeclineD");

    HumanClassId = pr_get_class_id( PClass_Human );

    register_dictionary("plague.txt");

    RegisterHookChain( RG_CBasePlayer_Spawn, "ReHook_CBasePlayer_Spawned", 1 );

    register_clcmd("say /guns", "cmdGuns");
    register_clcmd("say_team /guns", "cmdGuns");
}

public plugin_cfg()
{
    new JSON:jSection = json_object_get_object_safe(pr_open_settings(pluginCfg), "weapon_menu");

    new JSON:jSection2;

    new JSON:jSysName;
    new JSON:jName;
    new JSON:jBPAmmo;

    new size;

    tWeapons = TrieCreate( );
    
    for(new i = 0; i < MAX_SLOTS; i++)
    {
        gaWpnData[ i ][ WEAPON_SYSNAME ] = ArrayCreate( 32, 1 );
        gaWpnData[ i ][ WEAPON_ID ] = ArrayCreate( 1, 1 );
        gaWpnData[ i ][ WEAPON_AMMO ] = ArrayCreate( 1, 1 );

        jSection2 = json_object_get_object_safe( jSection, szSlotKey[ i ] );

        jSysName = json_object_get_array_safe(jSection2, "weapon");
        jBPAmmo = json_object_get_array_safe(jSection2, "ammo");

        size = min(
            json_array_get_count(jSysName),
            json_array_get_count(jBPAmmo)
        );

        if ( i != GRENADE )
        {
            gaWpnData[ i ][ WEAPON_NAME ] = ArrayCreate( 64, 1 );
            jName = json_object_get_array_safe(jSection2, "name");
            size = min( size, json_array_get_count( jName ) );
        }

        if ( size == 0 )
        {
            server_print( "There are no weapons to add." );
            continue;
        }

        new szWeaponSys[ 32 ], szWeaponName[ 64 ], iAmmo, iId;

        for ( new y = 0; y < size; y++ )
        {
            json_array_get_string( jSysName, y, szWeaponSys, charsmax( szWeaponSys ) );

            iId = get_weaponid( szWeaponSys )
            if ( iId == 0 )
            {
                server_print( "^"%s^" Isn't a valid cs weapon.", szWeaponSys );
                continue;
            }

            if ( TrieKeyExists( tWeapons, szWeaponSys ) )
            {
                server_print( "^"%s^" Was already added to the Weapon Menu.", szWeaponSys );
                continue;
            }

            iAmmo = json_array_get_number( jBPAmmo, y );

            TrieSetCell( tWeapons, szWeaponSys, 0 );
            ArrayPushString( gaWpnData[i][WEAPON_SYSNAME], szWeaponSys );
            ArrayPushCell( gaWpnData[i][WEAPON_ID], iId );
            ArrayPushCell( gaWpnData[i][WEAPON_AMMO], iAmmo );

            if ( i != GRENADE )
            {
                json_array_get_string( jName, y, szWeaponName, charsmax( szWeaponName ) );
                ArrayPushString( gaWpnData[i][WEAPON_NAME], szWeaponName );
            }

            wpnCount[ i ]++;
        }

        json_free( jSysName );
        json_free( jBPAmmo );

        if ( i != GRENADE )
            json_free( jName );

        json_free( jSection2 );
    }

    json_free( jSection );

    pr_close_settings(pluginCfg);
}

public client_connect(id)
{
    bitShow |= (1 << id);
}

public cmdGuns(id)
{
    if ( !is_user_alive(id) )
        return;

    if ( ~bitShow & (1 << id) )
    {
        client_print_color( id, 0, "^4[ZP] ^1%L", id, "WEAPONMENU_REENABLED");
        bitShow |= (1 << id);
    }

    if ( ~bitShowed & (1 << id) && pr_get_user_class(id) == HumanClassId )
        BuildMain( id );
}

public ReHook_CBasePlayer_Spawned(id)
{
    if(get_member(id, m_bJustConnected) || !is_user_alive(id) ||
    pr_get_user_class(id) != HumanClassId)
        return;

    if ( bitShowed & (1 << id) )
        bitShowed &= ~(1 << id);

    if ( ~bitShow & (1 << id) )
    {
        TakeWeapons( id );
        return;
    }

    BuildMain(id);
}

public Plague_Humanize_Post(id)
{
    if ( !is_user_alive(id) )
        return;
    
    if ( bitShowed & (1 << id) )
        bitShowed &= ~(1 << id);

    BuildMain(id);
}

stock BuildMain(id)
{
    if( pr_get_user_class(id) != HumanClassId )
        return;
    
    new szName[ 64 ], szBuffer[ 128 ];
    formatex( szBuffer, charsmax( szBuffer ), "%L", id, "WEAPONMENU_MAIN_TITLE" );

    new menu = menu_create( szBuffer, "handMain" );

    if ( wpnCount[ PRIMARY ] > 0 )
        ArrayGetString( gaWpnData[ PRIMARY ][ WEAPON_NAME ], iLastWpn[ id ][ PRIMARY ], szName, charsmax( szName ) );
    
    formatex( szBuffer, charsmax( szBuffer ), "%L \d[ %s \d]", id, "WEAPONMENU_ITEM_PRIMARY", szName );
    menu_additem( menu, szBuffer );

    if ( wpnCount[ SECONDARY ] > 0 )
        ArrayGetString( gaWpnData[ SECONDARY ][ WEAPON_NAME ], iLastWpn[ id ][ SECONDARY ], szName, charsmax( szName ) );
    else copy( szName, charsmax( szName ), "" );

    formatex( szBuffer, charsmax( szBuffer ), "%L \d[ \w%s \d]^n", id, "WEAPONMENU_ITEM_SECONDARY", szName );
    menu_additem( menu, szBuffer );

    formatex( szBuffer, charsmax( szBuffer ), "%L", id, "WEAPONMENU_ITEM_TAKE" );
    menu_additem( menu, szBuffer );

    formatex( szBuffer, charsmax( szBuffer ), "%L", id, "WEAPONMENU_ITEM_TAKE_NEVER" );
    menu_additem( menu, szBuffer );

    menu_display( id, menu );
}

public handMain(id, menu, item)
{
    if(item == MENU_EXIT || pr_get_user_class(id) != HumanClassId)
    {
        menu_destroy(menu);
        return;
    }

    switch(item)
    {
        case 0, 1: BuildOther(id, item);
        case 2: {
            TakeWeapons(id);
            bitShowed |= (1 << id);
        }
        case 3: {
            TakeWeapons(id);
            bitShow &= ~(1 << id);
            bitShowed |= (1 << id);
        }
    }

    menu_destroy(menu);
}

stock BuildOther(id, which)
{
    if ( wpnCount[ which ] == 0 )
    {
        BuildMain(id);
        return;
    }

    if(pr_get_user_class(id) != HumanClassId)
        return;

    new szName[ 128 ];
    formatex( szName, charsmax( szName ), "WEAPONMENU_%s_TITLE", szSlotKey[ which ]);
    strtoupper( szName );
    formatex( szName, charsmax( szName ), "%L", id, szName );

    new menu = menu_create( szName, fmt("hand%s", szSlotKey[ which ]) );

    for( new i = 0; i < wpnCount[ which ]; i++ )
    {
        ArrayGetString( gaWpnData[ which ][ WEAPON_NAME ], i, szName, charsmax( szName ) );
        menu_additem( menu, szName );
    }

    menu_display( id, menu );
}

public handprimary(id, menu, item)
{
    if(item == MENU_EXIT)
    {
        menu_destroy(menu);
        BuildMain(id);
        return;
    }

    if(!is_user_alive(id) || pr_get_user_class(id) != HumanClassId)
        return;

    iLastWpn[ id ][ PRIMARY ] = item;
    BuildMain(id);
    menu_destroy(menu);
}

public handsecondary(id, menu, item)
{
    if(item == MENU_EXIT)
    {
        menu_destroy(menu);
        BuildMain(id);
        return;
    }

    if(!is_user_alive(id))
        return;

    iLastWpn[ id ][ SECONDARY ] = item;
    BuildMain(id);
    menu_destroy(menu);
}

stock TakeWeapons(id)
{
    if(!is_user_alive(id))
        return;

    new szSys[ 32 ], wpn;

    for(new i = 0; i < MAX_SLOTS; i++)
    {
        if ( wpnCount[ i ] == 0 )
            continue;
        
        if ( i != GRENADE )
        {
            wpn = iLastWpn[ id ][ i ];
            ArrayGetString( gaWpnData[ i ][ WEAPON_SYSNAME ], wpn, szSys, charsmax( szSys ) );
            rg_give_item( id, szSys, GT_DROP_AND_REPLACE );
            rg_set_user_bpammo( id, 
                ArrayGetCell( gaWpnData[ i ][ WEAPON_ID ], wpn ), 
                ArrayGetCell( gaWpnData[ i ][ WEAPON_AMMO ], wpn ) 
            );
        }
        else {
            for(new y = 0; y < wpnCount[ i ]; y++)
            {
                ArrayGetString( gaWpnData[ i ][ WEAPON_SYSNAME ], y, szSys, charsmax( szSys ) );
                rg_give_item( id, szSys, GT_DROP_AND_REPLACE );
                rg_set_user_bpammo( id, 
                    ArrayGetCell( gaWpnData[ i ][ WEAPON_ID ], y ), 
                    ArrayGetCell( gaWpnData[ i ][ WEAPON_AMMO ], y ) 
                );
            }
        }
    }
}