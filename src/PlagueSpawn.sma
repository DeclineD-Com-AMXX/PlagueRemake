/* -> Includes <- */
#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <reapi>

#include <plague_const>
#include <plague_zombie_const>
#include <plague_human_const>
#include <plague_classes>
#include <plague_rounds>
#include <plague_settings>
#include <plague_spawn_const>


/* -> Plugin Information <- */
new const pluginName[ ] = "[Plague] Respawn Management";
new const pluginVer[ ] = "v1.0";
new const pluginAuthor[ ] = "DeclineD";


/* -> Settings <- */
#define IsHuman(%0) bool:(pr_get_user_class(%0) == HumanClassId)
#define IsZombie(%0) bool:(pr_get_user_class(%0) == ZombieClassId)

new const pluginCfg[ ] = "addons/amxmodx/configs/plague.json";
new const pluginSection[ ] = "respawn";

enum _:MsgKeys {
    MSG_COUNT,
    MSG_SPAWNED
}

new const szDefaultMessages[MsgKeys][] = {
    "Respawning in %i Seconds.", "You got respawned!^nYou got respawned!^nYou got respawned!"
}

new const szMsgKey[MsgKeys][] = {
    "respawning_message", "respawned_message"
}

new gszMessages[MsgKeys][192];

LoadSettings()
{
    new JSON:section = json_object_get_object_safe( pr_open_settings(pluginCfg), pluginSection );
    new JSON:temp;
    for(new i = 0; i < MsgKeys; i++)
    {
        temp = json_object_get_string_safe( section, szMsgKey[i], szDefaultMessages[i], gszMessages[i], charsmax(gszMessages[]));
        json_free(temp);
    }

    json_free(section);
    pr_close_settings(pluginCfg);
}


/* -> Respawn Globals<- */
new RespawnType:gRespawnType;
new Float:flRespawnTime;

enum RespawnData {
    Float: RES_StartTime,
    Float: RES_EndTime,
    RES_LastSec
}

new gRespawn[MAX_PLAYERS + 1][RespawnData];

new fwdRespawn, fwdRespawnPost;
new fwdAddRes, fwdAddResPost;

new PlagueClassId: ZombieClassId;
new PlagueClassId: HumanClassId;

public plugin_precache()
{
    LoadSettings( );

    fwdRespawn = CreateMultiForward("Plague_Respawn_Pre", ET_CONTINUE, FP_CELL);
    fwdRespawnPost = CreateMultiForward("Plague_Respawn_Post", ET_IGNORE, FP_CELL);

    fwdAddRes = CreateMultiForward("Plague_AddToRespawn_Pre", ET_CONTINUE, FP_CELL, FP_CELL);
    fwdAddResPost = CreateMultiForward("Plague_AddToRespawn_Post", ET_IGNORE, FP_CELL, FP_CELL);
}

public plugin_natives()
{
    register_native("pr_add_to_respawn", "Native_AddToRes");
    register_native("pr_get_respawn_start_time", "Native_StartTime");
    register_native("pr_get_respawn_end_time", "Native_GetEndTime");
    register_native("pr_get_respawn_seconds_remaining", "Native_LastSec");
    register_native("pr_set_respawn_end_time", "Native_SetEndTime");
    register_native("pr_set_respawn_type", "Native_SetRespawnType");
    register_native("pr_get_respawn_type", "Native_GetRespawnType");
}

public Native_SetRespawnType(plgId, params)
{
    if(params < 1)
        return;

    new RespawnType:res = RespawnType:get_param(1);
    gRespawnType = res;
}

public RespawnType:Native_GetRespawnType()
{
    return gRespawnType;
}

public Native_AddToRes(plgId, params)
{
    if(params < 2)
        return;

    new id = get_param(1);

    if(id > 33 || id < 1)
        return;

    new bool:call = bool:get_param(2);

    AddToRespawn(id, call);
}

public Float:Native_GetEndTime(plgId, params)
{
    if(params < 1)
        return 0.0;

    new id = get_param(1);

    if(id > 33 || id < 1)
        return 0.0;

    return gRespawn[id][RES_EndTime];
}

public Float:Native_StartTime(plgId, params)
{
    if(params < 1)
        return 0.0;

    new id = get_param(1);

    if(id > 33 || id < 1)
        return 0.0;

    return gRespawn[id][RES_StartTime];
}

public Native_LastSec(plgId, params)
{
    if(params < 1)
        return 0;

    new id = get_param(1);

    if(id > 33 || id < 1)
        return 0;

    return gRespawn[id][RES_LastSec];
}

public Native_SetEndTime(plgId, params)
{
    if(params < 2)
        return;

    new id = get_param(1);

    if(id > 33 || id < 1)
        return;

    new Float:x = get_param_f(2);
    gRespawn[id][RES_EndTime] = x;
}

new cvarDefaultRespawnTime;
new Float:g_SpawnOrigins[99][3], g_SpawnCount;

public plugin_init()
{
    register_plugin(pluginName, pluginVer, pluginAuthor);

    ZombieClassId = pr_get_class_id(PClass_Zombie);
    HumanClassId = pr_get_class_id(PClass_Human);

    RegisterHookChain(RG_CBasePlayer_PostThink, "ReHook_Player_PostThink", 1);
    RegisterHookChain(RG_CSGameRules_FPlayerCanRespawn, "ReHook_FPlayerCanRespawn_Pre", 0);
    RegisterHookChain(RG_CBasePlayer_Killed, "ReHook_Player_Killed", 1);
    RegisterHookChain(RG_CBasePlayer_Spawn, "ReHook_Player_Spawn_Post", 1);
    RegisterHookChain(RG_CBasePlayer_GetIntoGame, "JoinGame_Post", 1);

    collect_spawns_ent("info_player_start");
    collect_spawns_ent("info_player_deathmatch");

    cvarDefaultRespawnTime = register_cvar("pr_default_respawn_time", "2.0");

    register_clcmd("say zm", "zm");
}

public zm(id)
{
    if( IsHuman(id) )
    pr_change_class(id, _, ZombieClassId, true );
    else
    pr_change_class(id, _, HumanClassId, true);
}

public client_connect(id)
{
    gRespawn[id][RES_StartTime] = gRespawn[id][RES_EndTime] = 0.0;
    gRespawn[id][RES_LastSec] = 0;
}

public Plague_RoundStart_Post()
{
    flRespawnTime = get_pcvar_float(cvarDefaultRespawnTime);
}

public JoinGame_Post(id)
{
    AssureTransformation(id);
    AddToRespawn(id);
}

public ReHook_Player_Killed(id)
{
    if(!CanRespawn(id))
        return;

    AddToRespawn(id);
}

public ReHook_FPlayerCanRespawn_Pre(id)
{
    SetHookChainReturn(ATYPE_INTEGER, 0);
    return HC_SUPERCEDE;
}

public ReHook_Player_Spawn_Post(id)
{
    if(get_member(id, m_bJustConnected) || !is_user_alive(id))
        return;
    
    AssureTransformation(id);
    choose_spawn(id);
}

public ReHook_Player_PostThink(id)
{
    if ( is_user_alive( id ) || pr_get_user_class( id ) == PClassId_None )
        return;

    if ( pr_round_status( ) == RoundStatus_Ended )
        return;
    
    static Float:flGametime; flGametime = get_gametime( );
    if ( gRespawn[ id ][ RES_EndTime ] == 0.0 )
        return;

    if ( gRespawn[ id ][ RES_StartTime ] >= flGametime )
        return;

    if ( gRespawn[ id ][ RES_EndTime ] >= flGametime )
    {
        static Remaining; Remaining = floatround( gRespawn[ id ][ RES_EndTime ] - flGametime, floatround_ceil );

        if ( gRespawn[ id ][ RES_LastSec ] != Remaining )
        {
            gRespawn[ id ][ RES_LastSec ] = Remaining;

            if ( Remaining > 0 )
            {
                UTIL_CenterMessage( id, gszMessages[ MSG_COUNT ], Remaining );
            }
        }

        return;
    }

    new ret;
    ExecuteForward( fwdRespawn, ret, id );

    if ( ret > Plague_Continue )
        return;
    
    gRespawn[ id ][ RES_StartTime ] = gRespawn[ id ][ RES_EndTime ] = 0.0;
    rg_round_respawn( id );


    ExecuteForward( fwdRespawnPost, _, id );
}

stock AssureTransformation(id)
{
    new rand = random_num(0, 1);
    new RoundStatus:status = pr_round_status();
    new bool:bStarted = !(status == RoundStatus_WaitingForPlayers || status == RoundStatus_Starting);
    if ( pr_get_user_class(id) == PClassId_None )
    {
        rand = !bStarted ? 0 : rand;

        if(rand == 1)
            pr_change_class(id, _, ZombieClassId, true);
        else
            pr_change_class(id, _, HumanClassId, true);

        return;
    }

    if ( !bStarted )
    {
        pr_change_class(id, _, HumanClassId, true);
        return;
    }

    if(gRespawnType == Respawn_Yes || gRespawnType == Respawn_None)
    {
        pr_change_class(id, _, pr_get_user_class(id), true);
        return;
    }

    if ( gRespawnType == Respawn_Human ||
        gRespawnType == Respawn_Human2 ||
        (gRespawnType == Respawn_Random && !rand) ||
        (gRespawnType == Respawn_Balanced && UTIL_CountAlive(_:TEAM_CT) < UTIL_CountAlive(_:TEAM_TERRORIST)) ||
        (gRespawnType == Respawn_Opposite && IsZombie(id)) )
        pr_change_class(id, _, HumanClassId, true);
    else
        pr_change_class(id, _, ZombieClassId, true);
}

stock AddToRespawn(id, bool:call = true)
{
    if ( pr_round_status( ) == RoundStatus_Starting || pr_round_status( ) == RoundStatus_WaitingForPlayers )
    {
        gRespawn[ id ][ RES_StartTime ] = get_gametime( ) + 0.1;
        gRespawn[ id ][ RES_EndTime ] = gRespawn[ id ][ RES_StartTime ] + 0.1;
        gRespawn[ id ][ RES_LastSec ] = 0;
        return;
    }

    if(call)
    {
        new ret;
        ExecuteForward(fwdAddRes, ret, id, gRespawn[ id ][ RES_StartTime ]);

        if(ret > Plague_Continue)
            return;
    }

    gRespawn[ id ][ RES_StartTime ] = get_gametime( ) + 1.0;
    gRespawn[ id ][ RES_EndTime ] = gRespawn[ id ][ RES_StartTime ] + flRespawnTime;
    gRespawn[ id ][ RES_LastSec ] = 0;

    if(call)
        ExecuteForward(fwdAddResPost, _, id, gRespawn[ id ][ RES_StartTime ]);
}

stock CanRespawn(id)
{
    if(pr_get_user_class(id) == PClassId_None)
        return false;
    
    if ( (gRespawnType == Respawn_Human && !IsHuman(id)) ||
        (gRespawnType == Respawn_Zombie && !IsZombie(id)) ||
        gRespawnType == Respawn_None )
        return false;

    return true;
}

stock choose_spawn(id)
{
    static hull, sp_index, i

    hull = (get_entvar(id, var_flags) & FL_DUCKING) ? HULL_HEAD : HULL_HUMAN
    sp_index = random_num(0, g_SpawnCount - 1)

    for (i = sp_index + 1; /*no condition*/; i++)
    {
        if(i >= g_SpawnCount) i = 0;

        if(IsHullVacant(g_SpawnOrigins[i], hull))
        {
            engfunc(EngFunc_SetOrigin, id, g_SpawnOrigins[i]);
            break;
        }

        if (i == sp_index) break;
    }
}

stock collect_spawns_ent(const classname[])
{
	new ent = -1;
	while ((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", classname)) != 0)
	{
		// get origin
		new Float:originF[3];
		get_entvar(ent, var_origin, originF);
		g_SpawnOrigins[g_SpawnCount][0] = originF[0];
		g_SpawnOrigins[g_SpawnCount][1] = originF[1];
		g_SpawnOrigins[g_SpawnCount][2] = originF[2];
		
		// increase spawn count
		g_SpawnCount++;
		if (g_SpawnCount >= sizeof g_SpawnOrigins) break;
	}
}

stock bool:IsHullVacant(Float:vecOrigin[3], iHullNumber, pSkipEnt = 0)
{
	new ptr;
	engfunc(EngFunc_TraceHull, vecOrigin, vecOrigin, 0, iHullNumber, pSkipEnt, ptr);
	return bool:(!get_tr2(ptr, TR_StartSolid) && !get_tr2(ptr, TR_AllSolid) && get_tr2(ptr, TR_InOpen))
}

stock UTIL_CenterMessage( player = 0, const msg[ ], any:... )
{
    new szMsg[ 192 ];
    vformat( szMsg, charsmax( szMsg ), msg, 3 );

    replace_all( szMsg, charsmax( szMsg ), "\n", "^r" );
    replace_all( szMsg, charsmax( szMsg ), "^n", "^r" );

    static msgTextMsg;
    if( !msgTextMsg ) msgTextMsg = get_user_msgid("TextMsg");

    message_begin( player ? MSG_ONE_UNRELIABLE : MSG_ALL, msgTextMsg, _, player );
    write_byte( 4 );
    write_string( szMsg );
    message_end( );

    return 1;
}

stock UTIL_CountAlive(team = 0)
{
    new players[MAX_PLAYERS], num;

    if(team > 0)
        get_players(players, num, "ae", team == 1 ? "TERRORIST" : "CT");
    else
        get_players(players, num, "a");

    return num;
}