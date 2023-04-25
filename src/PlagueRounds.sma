/* -> Semicolon <- */
#pragma semicolon 1


/* -> Includes <- */
#include <amxmodx>
#include <reapi>

#include <plague_rounds_const>
#include <plague>


/* -> Some Macros <- */
#define Call->%0->Pre() \
    new ret; \
    ExecuteForward(%0[0], ret); \
    if(ret > _:Plague_Continue) \
        return

#define Call->%0->Pre(%2) \
    new ret; \
    ExecuteForward(%0[0], ret, %2); \
    if(ret > _:Plague_Continue) \
        return

#define Call->%0->Post(%2) ExecuteForward(%0[0], _, %2)
#define Call->%0->Post ExecuteForward(%0[0])


/* -> Plugin Info <- */
new const pluginName[ ] = "[Plague] Rounds & Gamemodes";
new const pluginVer[ ] = "v1.0";
new const pluginAuthor[ ] = "DeclineD";


/* -> Countdown <- */
static iEnt;


/* -> Respawn Handling <- */
new fwdRespawn[2], fwdRespawnQueue[2];

const Float:glbDefaultRespawnTime = 2.0;
new Float: glbRespawnTime;

new bool: bRespawnPending;

enum ServerResData {
           Res_Player,
    Float: Res_Time,
           Res_SecondsRemaining
}

new glbRespawnData[ MAX_PLAYERS + 1 ][ ServerResData ];
new glbRespawnPos[ MAX_PLAYERS + 1 ];
new glbRespawnCount;


/* -> Waiting For Players <- */
new fwdWFPEnd[2];

new cWFPMin, cWFPRestartTime, cWFPTime;
new Float: flWFPTime;
new bool: bWFP;


/* -> Round <- */
new fwdRoundStart[2], fwdRoundEnd[2];
new fwdFreezeEnd[2], fwdRoundStart2[2];

new cpRoundTime, cRounds;
new cpFreezeTime, cRoundEndDelay;
new cRoundDelay, cFreezeDelay;

new iRounds, iMaxRounds;
new GameWin: iLastWin;
new GameWin: iGameWIn;
new WinEvent: iLastWinEvent;
new WinEvent: iWinEvent;
new RestartType: iLastRestart;
new RestartType: iRestart;

new SpawnType: iRespawnType;
new InfectionType: iInfectionType;
new RoundType: iRoundType;

new RoundStartType: iStartType;
new FreezeDelayType: iFreezeType;
new FreezeDelayTeam: iFreezeTeam;

new iWinConditions;

new bool: bRoundEnded;
new bool: bRoundStarted;

new bool: iRoundTimer;

new iAlivePlayers[2];


/* -> Gamemodes <- */
new fwdGamemodeStart[2];

new Array: aGamemodePlugin;
new Array: aGamemodeSystemName;
new Array: aGamemodeName;
new Array: aGamemodeInfectionType;
new Array: aGamemodeSpawnType;
new Array: aGamemodeMinPlayers;
new Array: aGamemodeChance;

new iCurrentGamemode;
new iGamemodes;

const Float:glbDefaultFlSpread = 0.5;
new Float: glbFlSpread;


/* -> Join Game <- */
const Task_JoinGame = 231231;


/* -> Natives <- */
public plugin_natives()
{
    // Round
    register_native("pr_get_round_status",              "Native_RoundStatus",           1);

    register_native("pr_get_last_winevent",             "Native_LastWinEvent",          1);
    register_native("pr_get_last_restart",              "Native_LastRestart",           1);
    register_native("pr_get_last_gamewin",              "Native_LastGameWin",           1);

    register_native("pr_get_round_type",                "Native_GetRoundType",          1);
    register_native("pr_set_round_type",                "Native_SetRoundType",          1);

    register_native("pr_get_round_timer_status",        "Native_GetTimerStatus",        1);
    register_native("pr_set_round_timer_status",        "Native_SetTimerStatus",        1);

    register_native("pr_get_freeze_team",               "Native_GetFreezeTeam",         1);
    register_native("pr_get_freeze_type",               "Native_GetFreezeType",         1);

    register_native("pr_set_freeze_team",               "Native_SetFreezeTeam",         1);
    register_native("pr_set_freeze_type",               "Native_SetFreezeType",         1);

    register_native("pr_get_round_start_type",          "Native_GetRoundStartType",     1);
    register_native("pr_set_round_start_type",          "Native_SetRoundStartType",     1);

    register_native("pr_end_round",                     "Native_EndRound",              0);

    // Gamemode 
    register_native("pr_get_current_gamemode",          "Native_GetCurrentGamemode",    1);
    register_native("pr_set_current_gamemode",          "Native_SetCurrentGamemode",    1);

    register_native("pr_register_gamemode",             "Native_RegisterGamemode",      1);

    register_native("pr_get_gamemode_name",             "Native_GamemodeName",          1);
    register_native("pr_get_gamemode_id",               "Native_GamemodeId",            1);
    register_native("pr_get_gamemodes",                 "Native_GamemodeCount",         1);

    register_native("pr_get_infection_type",            "Native_GetInfectionType",      1);
    register_native("pr_get_spawn_type",                "Native_GetSpawnType",          1);

    register_native("pr_set_infection_type",            "Native_SetInfectionType",      1);
    register_native("pr_set_spawn_type",                "Native_SetSpawnType",          1);

    register_native("pr_get_spread",                    "Native_GetSpread",             1);
    register_native("pr_reset_spread",                  "Native_ResetSpread",           1);
    register_native("pr_set_spread",                    "Native_SetSpread",             1);

    // Respawn
    register_native("pr_add_to_respawn_queue",          "Native_AddToRespawn",          1);
    register_native("pr_remove_from_respawn_queue",     "Native_RemoveFromRespawn",     1);
    register_native("pr_is_user_respawning",            "Native_IsRespawning",          1);

    register_native("pr_get_user_respawn_seconds_left", "Native_GetRespawnTimeLeft",    1);
    register_native("pr_get_user_respawn_time",         "Native_GetRespawnTime",        1);

    register_native("pr_set_user_respawn_seconds_left", "Native_SetRespawnTimeLeft",    1);
}

public Native_RoundStatus()
{
    
}


/* -> Private Functions <- */
// Player Count
CountAlivePlayers()
{
    iAlivePlayers[0] = iAlivePlayers[1] = 0;

    for(new i = 1; i <= get_playersnum(); i++)
        if(is_user_connected(i) && is_user_alive(i))
            iAlivePlayers[pr_is_zombie(i) ? 0 : 1]++;
}

// Respawn
NextRespawnSpotAvailable( )
{
    new i;
    do
    {
        if( !glbRespawnData[ i ][ Res_Player ] )
           return i;

        i++; 
    }
    while( i < glbRespawnCount );

    return i;
}

RemoveFromRespawnQueue( id, pos )
{
    // If already out of the queue exit
    if( glbRespawnPos[ id ] == -1 )
        return;

    glbRespawnPos[ id ] = -1;
    glbRespawnData[ pos ][ Res_Player ] = 0;

    glbRespawnCount--;
}

AddToRespawnQueue( id )
{
    Call->fwdRespawnQueue->Pre(id);

    // If already in the queue exit
    if( glbRespawnPos[ id ] > -1 )
        return;

    new pos = NextRespawnSpotAvailable( );

    glbRespawnData[ pos ][ Res_Player ] = id;
    glbRespawnData[ pos ][ Res_SecondsRemaining ] = floatround( glbRespawnTime );
    glbRespawnData[ pos ][ Res_Time ] = get_gametime( ) + glbRespawnTime;

    glbRespawnPos[ id ] = pos;

    glbRespawnCount++;

    Call->fwdRespawnQueue->Post(id);
}

CheckRespawning( Float: flGametime )
{
    if(!bRespawnPending)
        return;
    
    new i = 1, pos = 0;
    do
    {
        pos++;

        if( !glbRespawnData[ pos ][ Res_Player ] || 
        !IsPlayer( glbRespawnData[ pos ][ Res_Player ] ) )
            continue;

        i++;

        glbRespawnData[ pos ][ Res_SecondsRemaining ]--;

        if(glbRespawnData[ pos ][ Res_SecondsRemaining ])
            UTIL_CenterMessage( glbRespawnData[ pos ][ Res_Player ], 
            "You're respawning^nSeconds left: %i", glbRespawnData[ pos ][ Res_SecondsRemaining ]);
        else
            UTIL_CenterMessage( glbRespawnData[ pos ][ Res_Player ], 
            "You're respawned^nYou're respawned!");

        if( glbRespawnData[ pos ][ Res_Time ] <= flGametime )
        {
            rg_round_respawn( glbRespawnData[ pos ][ Res_Player ] );

            RemoveFromRespawnQueue( glbRespawnData[ pos ][ Res_Player ], pos );

            continue;
        }
    }
    while( i < glbRespawnCount && pos < MAX_PLAYERS + 1 );
}

bool: CanRespawn( id )
{
    if(iRespawnType == Respawn_None)
        return false;

    if(iRespawnType == Respawn_Zombie &&
        !pr_is_zombie(id))
        return false;
    
    if(iRespawnType == Respawn_Human &&
        !pr_is_human(id))
        return false;

    return true;
}

Respawn( id )
{
    Call->fwdRespawn->Pre(id);

    new iRand = random_num(0, 1);
    if(iRespawnType == Respawn_Zombie2 ||
        (iRespawnType == Respawn_Oppsite && pr_is_human(id)) ||
        (iRespawnType == Respawn_Balanced && (iAlivePlayer[0] > iAlivePlayers[1])) ||
        (iRespawnType == Respawn_Random && iRand == 0))
    {
        pr_set_user_zombie(id, true);
    }
    else if(iRespawnType == Respawn_Human2 ||
        (iRespawnType == Respawn_Oppsite && pr_is_zombie(id)) ||
        (iRespawnType == Respawn_Balanced && (iAlivePlayer[0] > iAlivePlayers[1])) ||
        (iRespawnType == Respawn_Random && iRand == 1))
    {
        pr_set_user_zombie(id, false);
    }

    rg_round_respawn(id);

    Call->fwdRespawn->Post(id);
}

// Round
EndRound(Float:delay, WinEvent:event, GameWin:win, msg[], sound[])
{
    new hmsg = PrepareArray(msg, 128);
    new hsound = PrepareArray(sound, 128);

    Call->fwdRoundEnd->Pre(delay, event, win, hmsg, hsound);

    if(iRoundType == Round_Custom)
        return;

    bRoundEnded = true;
    bRoundStarted = false;
    
    static WinStatus:win2;
    switch(win)
    {
        case Win_Human: win2 = WINSTATUS_CTS;
        case Win_Zombie: win2 = WINSTATUS_TERRORISTS;
        default: win2 = WINSTATUS_NONE;
    }

    static ScenarioEventEndRound: event2;
    switch(event)
    {
        case WinEvent_WFP: event2 = ROUND_GAME_COMMENCE;
        case WinEvent_Restart: event2 = ROUND_GAME_RESTART;
        case WinEvent_Expired: event2 = ROUND_GAME_OVER;
        case WinEvent_Extermination: event2 = (win == Win_Human ? ROUND_CTS_WIN : ROUND_TERRORISTS_WIN);
    }

    rg_round_end(delay, win2, event2, msg, "");
    UTIL_PlaySound(.Sound = sound);

    Call->fwdRoundEnd->Post(delay, event, win, hmsg, hsound);
}

// Waiting For Players Check
bool: IsWFP( )
{
    if(flWFPTime <= get_gametime())
        return true;

    static NeededPlayers; NeededPlayers = get_pcvar_num(cWFPMin);
    CountAlivePlayers();
    if(!NeededPlayers || iAlivePlayers[0]+iAlivePlayers[1] > NeededPlayers)
        return false;

    EndRound( get_pcvar_float(cWFPRestartTime), WinEvent_WFP, Win_None, "Game Commencing", "" );

    return true;
}

// Exterminaton Check
bool: IsExtermination( )
{
    CountAlivePlayers();
    if(iAlivePlayers[0] > 0 && iAlivePlayers[1] > 0)
        return false;

    EndRound( get_pcvar_float(cRoundEndDelay), WinEvent_Extermination, iAlivePlayers[0] > 0 ? Win_Zombie : Win_Human, "Humans Win", "" );

    return true;
}

// Check Round
bool: IsRoundTerminable( )
{
    if(iRoundType == Round_Infinite)
        return false;

    return true;
}

// Check Win Conditions
__CheckWinConditions( )
{
    if((bWFP = IsWFP( )))
        return;

    if(!IsRoundTerminable( ))
        return;

    if(!IsExtermination( ))
        return;
}


/* -> Public Functions <- */
public plugin_precache()
{
    fwdRoundStart[ 0 ] = CreateMultiForward( "Plague_RoundStart", ET_CONTINUE );
    fwdRoundStart[ 1 ] = CreateMultiForward( "Plague_RoundStart_Post", ET_IGNORED );

    fwdRoundStart2[ 0 ] = CreateMultiForward( "Plague_RoundStart2", ET_CONTINUE );
    fwdRoundStart2[ 1 ] = CreateMultiForward( "Plague_RoundStart2_Post", ET_IGNORED );

    fwdFreezeEnd[ 0 ] = CreateMultiForward( "Plague_OnFreezeEnd", ET_CONTINUE );
    fwdFreezeEnd[ 1 ] = CreateMultiForward( "Plague_OnFreezeEnd_Post", ET_IGNORED );

    fwdRoundEnd[ 0 ] = CreateMultiForward( "Plague_RoundEnd", ET_CONTINUE, FP_CELL, FP_CELL, FP_CELL, FP_STRING, FP_STRING );
    fwdRoundEnd[ 1 ] = CreateMultiForward( "Plague_RoundEnd_Post", ET_IGNORED, FP_CELL, FP_CELL, FP_CELL, FP_STRING, FP_STRING );

    fwdWFPEnd[ 0 ] = CreateMultiForward( "Plague_WaitForPlayers_End", ET_CONTINUE );
    fwdWFPEnd[ 1 ] = CreateMultiForward( "Plague_WaitForPlayers_End_Post", ET_IGNORED );

    fwdRespawn[ 0 ] = CreateMultiForward( "Plague_Respawn", ET_CONTINUE, FP_CELL );
    fwdRespawn[ 1 ] = CreateMultiForward( "Plague_Respawn_Post", ET_IGNORED, FP_CELL );

    fwdRespawnQueue[ 0 ] = CreateMultiForward( "Plague_EnterRespawnQueue", ET_CONTINUE, FP_CELL );
    fwdRespawnQueue[ 1 ] = CreateMultiForward( "Plague_EnterRespawnQueue_Post", ET_IGNORED, FP_CELL );
}

public plugin_init( )
{
    register_plugin( pluginName, pluginVer, pluginAuthor );

    register_event( "HLTV", "eventNewRound", "a", "1=0", "2=0" );

    RegisterHookChain( RG_CBasePlayer_Spawn, "Spawn_Post", 1 );
    RegisterHookChain( RG_CBasePlayer_Killed, "Death_Post", 1 );

    RegisterHookChain( RG_CSGameRules_OnRoundFreezeEnd, "OnFreezeEnd_Post", 1 );
    
    RegisterHookChain( RG_CSGameRules_GoToIntermission, "Intermission" );
    RegisterHookChain( RG_CSGameRules_CheckWinConditions, "CheckWinConditions" );
    RegisterHookChain( RG_CSGameRules_FPlayerCanRespawn, "CanRespawn" );

    RegisterHookChain( RG_RoundEnd, "RoundEnd" );

    // Countdown Entity
    iEnt = rg_create_entity( "info_target" );

    if( is_nullent( iEnt ) )
    {
        set_fail_state( "Couldn't create countdown entity" );
    }
    
    SetThink( iEnt, "Countdown" );
    set_entvar( iEnt, var_nextthink, get_gametime( ) + 1.0 );

    bWFP = true;
}

public client_connect( id )
{
    glbRespawnPos[ id ] = -1;
}

public client_disconnected( id )
{
    RemoveFromRespawnQueue( id );

    if(!get_playersnum())
        flWFPTime = 0.0;
}

public client_putinserver(id)
{
    set_task(0.25, "JoinGame", Task_JoinGame+id);

    if(flWFPTime == 0.0)
        flWFPTime = get_gametime() + get_cvar_float(cWFPTime);
}

public JoinGame(id)
{
    id -= Task_JoinGame;
    rg_join_team(id, TEAM_SPECTATOR);

    // Code to respawn as the game has started or is starting
}

// Blocking the Counter-Strike's Respawn Mechanism to replace it with our own
public CanRespawn(id)
{
    SetHookChainReturn(ATYPE_BOOL, false);
    return HC_SUPERCEDE;
}

public Spawn_Post(id)
{
    if(get_member(id, m_bJustConnected))
        return;

    iAlivePlayers[pr_is_zombie(id) ? 0 : 1]++;
}

public Death_Post(id)
{
    iAlivePlayers[pr_is_zombie(id) ? 0 : 1]--;

    if(CanRespawn(id))
    {
        AddToRespawnQueue(id);
    }
}

public CheckWinConditions()
{
    __CheckWinConditions();

    return HC_SUPERCEDE;
}

public eventNewRound()
{
    Call->fwdRoundStart->Pre();

    Call->fwdRoundStart->Post();
}

public OnFreezeEnd_Post()
{
    Call->fwdFreezeEnd->Pre();

    Call->fwdFreezeEnd->Post();
}