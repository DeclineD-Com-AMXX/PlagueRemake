/* *[-> INCLUDES <-]* */
#include <amxmodx>
#include <amxmisc>
#include <reapi>

#include <plague_const>
#include <plague_classes_const>

/* *[-> PLUGIN INFO <-]* */
new const pluginName[ ] = "[Plague] Classes";
new const pluginVersion[ ] = "Final";
new const pluginAuthor[ ] = "DeclineD";

/* *[-> VARIABLES <-]* */
const Task_Team = 43728472347823;

new PlagueClassId: iuClass[ MAX_PLAYERS + 1 ];
new PlagueClassId: giClassCount;

new Trie: tClasses, Array: aClassSystemName, Array: aClassTeam;

new fwdChange, fwdChangePost;

/* *[-> PLUGIN <-]* */
public plugin_natives( )
{
    register_native( "pr_register_class", "Native_RegClass" );
    register_native( "pr_get_class_id", "Native_ClassId" );
    register_native( "pr_get_class_system_name", "Native_SysName" );
    register_native( "pr_get_class_count", "Native_ClassCount", 1 );
 
    register_native( "pr_get_user_class", "Native_GetUserClass" );
    register_native( "pr_change_class", "Native_ChangeClass" );
}

public PlagueClassId: Native_ClassCount() return giClassCount;

public plugin_precache( )
{
    tClasses = TrieCreate( );
    aClassSystemName = ArrayCreate( 32, 1 );
    aClassTeam = ArrayCreate( 1, 1 );

    TrieSetCell( tClasses, PClass_None, PClassId_None );
    ArrayPushString( aClassSystemName, PClass_None );
    ArrayPushCell( aClassTeam, TEAM_SPECTATOR );

    giClassCount++;

    fwdChange = CreateMultiForward( "Plague_Change_Class", ET_CONTINUE, FP_CELL, FP_CELL, FP_CELL, FP_CELL );
    fwdChangePost = CreateMultiForward( "Plague_Change_Class_Post", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL, FP_CELL );
}

public plugin_init( )
{
    register_plugin( pluginName, pluginVersion, pluginAuthor );
}

public plugin_end( )
{
    TrieDestroy(tClasses);
    ArrayDestroy(aClassSystemName);
    ArrayDestroy(aClassTeam);
}

/* *[-> CLIENT <-]* */
public client_connect( pPlayer )
{
    iuClass[ pPlayer ] = PClassId_None;
}

public Task_ChangeTeam( id )
{
    id -= Task_Team;

    new TeamName: team = ArrayGetCell( aClassTeam, _:iuClass[ id ] );
    new TeamName: userClass = get_member( id, m_iTeam );

    if ( userClass == team )
        return;

    if ( iuClass[ id ] == PClassId_None && userClass == TEAM_UNASSIGNED )
        return;
    
    rg_set_user_team( id, team, MODEL_UNASSIGNED, .check_win_conditions = true );
}

/* *[-> NATIVES <-]* */
public PlagueClassId: Native_RegClass( plgId, params )
{
    if ( params < 2 )
    {
        log_error( AMX_ERR_NATIVE, "Not enough params to execute." );
        return PClassId_Invalid;
    }

    new szSysName[ 32 ]; get_string( 1, szSysName, charsmax( szSysName ) );
    
    if ( TrieKeyExists( tClasses, szSysName ) )
    {
        log_error( AMX_ERR_NATIVE, "Class ^"%s^" was already registered.", szSysName );
        return PClassId_Invalid;
    }

    new team = get_param( 2 );

    TrieSetCell( tClasses, szSysName, giClassCount );
    ArrayPushString( aClassSystemName, szSysName );
    ArrayPushCell( aClassTeam, team );

    giClassCount++;
    return giClassCount - PlagueClassId: 1;
}

public PlagueClassId: Native_ClassId( plgId, params )
{
    if ( params < 1 )
    {
        log_error( AMX_ERR_NATIVE, "Not enough params to execute." );
        return PClassId_Invalid;
    }

    new szSysName[ 32 ]; get_string( 1, szSysName, charsmax( szSysName ) );
    
    if ( !TrieKeyExists( tClasses, szSysName ) )
    {
        log_error( AMX_ERR_NATIVE, "Class ^"%s^" wasn't found in the system.", szSysName );
        return PClassId_Invalid;
    }

    new PlagueClassId: id;
    TrieGetCell( tClasses, szSysName, id );

    return id;
}

public Native_SysName( plgId, params )
{
    if ( params < 3 )
    {
        log_error( AMX_ERR_NATIVE, "Not enough params to execute." );
        return 0;
    }

    new PlagueClassId: id = PlagueClassId: get_param( 1 );

    if ( id <= PClassId_Invalid || id >= giClassCount )
    {
        log_error( AMX_ERR_NATIVE, "Unrecognizable class id %i", id );
        return 0;
    }

    new size = get_param( 3 );

    new szSysName[ 32 ]; ArrayGetString( aClassSystemName, _:id, szSysName, charsmax(szSysName) );
    set_string( 2, szSysName, size == -1 ? charsmax( szSysName ) : size );
    
    return 1;
}

public Native_ChangeClass( plgId, params )
{
    if ( params < 3 )
    {
        log_error( AMX_ERR_NATIVE, "Not enough params to execute." );
        return 0;
    }

    new id = get_param( 1 );

    if ( !is_user_connected( id ) )
    {
        log_error( AMX_ERR_NATIVE, "User %i is not connected", id );
        return 0;
    }

    new id2 = get_param( 2 );

    new PlagueClassId: class = PlagueClassId: get_param( 3 );

    if ( class <= PClassId_Invalid || class >= giClassCount )
    {
        log_error( AMX_ERR_NATIVE, "Unrecognizable class id %i" );
        return 0;
    }


    new bool: bSpawned = bool:(get_param( 4 ) && is_user_alive(id));
    new bool: call = bool: get_param( 5 );

    if ( call )
    {
        new ret;
        ExecuteForward( fwdChange, ret, id, id2, class, bSpawned );

        if ( ret > Plague_Continue )
            return 0;
    }

    set_task( 0.1, "Task_ChangeTeam", Task_Team + id );
    iuClass[ id ] = class;

    if ( class == PClassId_None )
    {
        rg_set_user_team( id, TEAM_SPECTATOR, _, .check_win_conditions = true );
        user_kill( id, 1 );
    }

    if ( call )
        ExecuteForward( fwdChangePost, _, id, id2, class, bSpawned );

    return 1;
}

public PlagueClassId: Native_GetUserClass( plgId, params )
{
    if ( params < 1 )
    {
        log_error( AMX_ERR_NATIVE, "Not enough params to execute." );
        return PClassId_Invalid;
    }

    new id = get_param( 1 );

    if ( id < 0 || id > 32 )
    {
        log_error( AMX_ERR_NATIVE, "User id %i is invalid.", id );
        return PClassId_Invalid;
    }

    return iuClass[ id ];
}