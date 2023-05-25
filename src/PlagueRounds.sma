#include <amxmodx>
#include <reapi>
#include <hamsandwich>

#include <plague_rounds_const>

#include <amx_settings_api>

enum _:PlagueAction {
    Plague_Continue = 89,
    Plague_Handled,
    Plague_Stop
}

/* -> Plugin Information <- */
new const pluginName[ ] = "[Plague] Round Management";
new const pluginVer[ ] = "v1.0";
new const pluginAuthor[ ] = "DeclineD";

/* -> Settings <- */
new const pluginCfg[] = "plague_round.ini";
new const pluginSection[] = "ROUND";

enum _:PlgKeys {
    MSG_END_WINH,
    MSG_END_WINZ,
    MSG_END_DRAW,
    MSG_END_WFP,
    MSG_END_RESTART,
    MSG_COUNTDOWN,
    SOUND_END_WINH,
    SOUND_END_WINZ,
    SOUND_END_DRAW
}

new const pluginKeys[PlgKeys][] = {
    "MESSAGE_WINH",
    "MESSAGE_WINZ",
    "MESSAGE_DRAW",
    "MESSAGE_WFPEND",
    "MESSAGE_RESTART",
    "MESSAGE_COUNTDOWN",
    "SOUND_WINH",
    "SOUND_WINZ",
    "SOUND_DRAW"
}

new Array:gEndSounds[3];

new szMessages[PlgKeys - 3][192];

GetRandomSound(which, szRet[128])
{
    new ___entry_ = which - SOUND_END_WINH;
    if(0 < ___entry_ < sizeof(gEndSounds))
    {
        new ___rand_ = random_num(0, ArraySize(gEndSounds[___entry_]) - 1);
        ArrayGetString(gEndSounds[___entry_], ___rand_, szRet, charsmax(szRet));
    }
}

PrecacheSoundArray(Array:sound)
{
    static szSound[MAX_RESOURCE_PATH_LENGTH];
    for(new i = 0; i < ArraySize(sound); i++)
    {
        ArrayGetString(sound, i, szSound, charsmax(szSound));
        if(strlen(szSound)) precache_sound(szSound);
    }
}

LoadSettings()
{
    new szTemp[192];

    copy(szTemp, charsmax(szTemp), "Humans Win!");

    if(!amx_load_setting_string(pluginCfg, pluginSection, pluginKeys[MSG_END_WINH], szTemp, charsmax(szTemp)))
        amx_save_setting_string(pluginCfg, pluginSection, pluginKeys[MSG_END_WINH], szTemp);

    copy(szMessages[MSG_END_WINH], charsmax(szMessages[]), szTemp);

    copy(szTemp, charsmax(szTemp), "Zombies Win!");

    if(!amx_load_setting_string(pluginCfg, pluginSection, pluginKeys[MSG_END_WINZ], szTemp, charsmax(szTemp)))
        amx_save_setting_string(pluginCfg, pluginSection, pluginKeys[MSG_END_WINZ], szTemp);

    copy(szMessages[MSG_END_WINZ], charsmax(szMessages[]), szTemp);

    copy(szTemp, charsmax(szTemp), "Draw!");

    if(!amx_load_setting_string(pluginCfg, pluginSection, pluginKeys[MSG_END_DRAW], szTemp, charsmax(szTemp)))
        amx_save_setting_string(pluginCfg, pluginSection, pluginKeys[MSG_END_DRAW], szTemp);

    copy(szMessages[MSG_END_DRAW], charsmax(szMessages[]), szTemp);

    copy(szTemp, charsmax(szTemp), "WFP Over!");

    if(!amx_load_setting_string(pluginCfg, pluginSection, pluginKeys[MSG_END_WFP], szTemp, charsmax(szTemp)))
        amx_save_setting_string(pluginCfg, pluginSection, pluginKeys[MSG_END_WFP], szTemp);

    copy(szMessages[MSG_END_WFP], charsmax(szMessages[]), szTemp);

    copy(szTemp, charsmax(szTemp), "Game will restart in %i seconds.");

    if(!amx_load_setting_string(pluginCfg, pluginSection, pluginKeys[MSG_END_RESTART], szTemp, charsmax(szTemp)))
        amx_save_setting_string(pluginCfg, pluginSection, pluginKeys[MSG_END_RESTART], szTemp);

    copy(szMessages[MSG_END_RESTART], charsmax(szMessages[]), szTemp);

    copy(szTemp, charsmax(szTemp), "Round will start in %i seconds.");

    if(!amx_load_setting_string(pluginCfg, pluginSection, pluginKeys[MSG_COUNTDOWN], szTemp, charsmax(szTemp)))
        amx_save_setting_string(pluginCfg, pluginSection, pluginKeys[MSG_COUNTDOWN], szTemp);

    copy(szMessages[MSG_COUNTDOWN], charsmax(szMessages[]), szTemp);

    gEndSounds[0] = ArrayCreate(128, 1);
    ArrayPushString(gEndSounds[0], "");

    gEndSounds[1] = ArrayCreate(128, 1);
    ArrayPushString(gEndSounds[1], "");

    gEndSounds[2] = ArrayCreate(128, 1);
    ArrayPushString(gEndSounds[2], "");

    if(!amx_load_setting_string_arr(pluginCfg, pluginSection, pluginKeys[SOUND_END_WINH], gEndSounds[0]))
        amx_save_setting_string_arr(pluginCfg, pluginSection, pluginKeys[SOUND_END_WINH], gEndSounds[0]);

    PrecacheSoundArray(gEndSounds[0]);

    if(!amx_load_setting_string_arr(pluginCfg, pluginSection, pluginKeys[SOUND_END_WINZ], gEndSounds[1]))
        amx_save_setting_string_arr(pluginCfg, pluginSection, pluginKeys[SOUND_END_WINZ], gEndSounds[1]);

    PrecacheSoundArray(gEndSounds[1]);

    if(!amx_load_setting_string_arr(pluginCfg, pluginSection, pluginKeys[SOUND_END_DRAW], gEndSounds[2]))
        amx_save_setting_string_arr(pluginCfg, pluginSection, pluginKeys[SOUND_END_DRAW], gEndSounds[2]);

    PrecacheSoundArray(gEndSounds[2]);
}

/* -> Round Start Message <- */
new pCountdown;


/* -> Waiting For Players <- */
new bool:bWFP;
new bool:bWFPStartNext;

new Float:flWFPTime;
new iWFPMin;

new cWFP, cWFPMin, cWFPTime;


/* -> Rounds <- */
new iDelay;
new bool:bFreezeDelay;

new bool:bRoundStarted, bool:bRoundEnded;
new Float:flRoundStart;

new fwdRoundStart[2], fwdRoundEnd[2];
new fwdFreezeEnd[2], fwdRoundStart2[2];
new fwdCountdownStart, fwdCounted;

new cRoundEndDelay;
new cRoundDelay, cFreezeDelay;

new GameWin: iLastWin;
new WinEvent: iLastWinEvent;

new RoundType: iRoundType;

public plugin_precache()
{
    fwdRoundStart[ 0 ] = CreateMultiForward( "Plague_RoundStart", ET_CONTINUE );
    fwdRoundStart[ 1 ] = CreateMultiForward( "Plague_RoundStart_Post", ET_IGNORE );

    fwdRoundStart2[ 0 ] = CreateMultiForward( "Plague_RoundStart2", ET_CONTINUE );
    fwdRoundStart2[ 1 ] = CreateMultiForward( "Plague_RoundStart2_Post", ET_IGNORE );

    fwdFreezeEnd[ 0 ] = CreateMultiForward( "Plague_OnFreezeEnd", ET_CONTINUE );
    fwdFreezeEnd[ 1 ] = CreateMultiForward( "Plague_OnFreezeEnd_Post", ET_IGNORE );

    fwdRoundEnd[ 0 ] = CreateMultiForward( "Plague_RoundEnd", ET_CONTINUE, FP_ARRAY, FP_STRING, FP_STRING );
    fwdRoundEnd[ 1 ] = CreateMultiForward( "Plague_RoundEnd_Post", ET_IGNORE, FP_ARRAY, FP_STRING, FP_STRING );

    fwdCountdownStart = CreateMultiForward( "Plague_Countdown_Start", ET_IGNORE, FP_CELL );
    fwdCounted = CreateMultiForward( "Plague_Counted", ET_IGNORE, FP_CELL );

    LoadSettings();
}

public plugin_natives()
{
    register_native("pr_end_round", "Native_EndRound");
    register_native("pr_round_status", "Native_RoundStatus");
    register_native("pr_get_last_win", "Native_LastWin");
    register_native("pr_get_last_winevent", "Native_LastWinEvent");
    register_native("pr_get_remaining_seconds", "Native_RemainingSecs");
    register_native("pr_set_round_type", "Native_SetRoundType");
    register_native("pr_get_round_type", "Native_GetRoundType");
    register_native("pr_start_round", "Native_RoundStart");
}

public plugin_init()
{
    // Register plugin
    register_plugin(pluginName, pluginVer, pluginAuthor);

    // Round Pre Hooks
    RegisterHookChain(RG_RoundEnd, "RoundEnd");
    RegisterHookChain(RG_CSGameRules_CheckWinConditions, "WinConditions");

    // Round Post Hooks
    RegisterHookChain(RG_CSGameRules_RestartRound, "RoundStart", 1);
    RegisterHookChain(RG_CSGameRules_RestartRound, "RoundStart_Pre");
    RegisterHookChain(RG_CSGameRules_OnRoundFreezeEnd, "FreezeEnd", 1);

    // Player Hooks
    RegisterHookChain(RG_CBasePlayer_Spawn, "Player_Spawned");

    // Cvars
    cRoundEndDelay = register_cvar("pr_round_end_delay", "3.0");
    cRoundDelay = register_cvar("pr_round_start_delay", "1");
    cFreezeDelay = register_cvar("pr_round_freeze_delay", "1"); 
    cWFP = register_cvar("pr_waiting_for_players", "1");
    cWFPMin = register_cvar("pr_wfp_minimum", "2");
    cWFPTime = register_cvar("pr_wfp_wait_time", "20");

    // Countdown Entity
    pCountdown = rg_create_entity("info_target");
    SetThink(pCountdown, "Countdown");
}

public plugin_cfg()
{
    server_cmd("exec addons/amxmodx/configs/plague.cfg");
}

public client_connect()
{
    iWFPMin = get_pcvar_num(cWFPMin);
    
    if(UTIL_CountAlive() < iWFPMin && get_pcvar_num(cWFP) > 0 && !bWFP)
    {
        flWFPTime = get_pcvar_float(cWFPTime);

        bWFP = true;
        bWFPStartNext = true;

        flRoundStart = 0.0;
    }
}

RoundStart2()
{
    new ret;
    ExecuteForward(fwdRoundStart2[0], ret);

    if(ret > Plague_Continue)
        return;
    
    bRoundStarted = true;

    ExecuteForward(fwdRoundStart2[1]);
}

StartWaitingBehaviour()
{
    if(!bWFP)
        return;

    bRoundEnded = true;

    set_entvar(pCountdown, var_nextthink, flRoundStart + 1.0);
    set_member_game(m_iRoundTimeSecs, get_timeleft());

    if(!bWFPStartNext)
        return;

    if(get_member_game(m_bFreezePeriod))
    {
        set_member_game(m_bFreezePeriod, false);
    }

    iDelay = floatround(flWFPTime);

    bWFPStartNext = false;
}

StartNormalBehaviour()
{   
    bFreezeDelay = bool: get_pcvar_num(cFreezeDelay);
    iDelay = get_pcvar_num(cRoundDelay);

    if(bFreezeDelay)
    {
        ExecuteForward(fwdCountdownStart, _, iDelay);

        set_entvar(pCountdown, var_nextthink, flRoundStart + 1.0);
    }
}

public RoundStart_Pre()
{
    bRoundEnded = false;
}

public RoundStart()
{
    if(iLastWinEvent == WinEvent_WFP)
    {
        bWFP = false;
        set_member_game(m_bGameStarted, true);
        set_member_game(m_bNeededPlayers, false);
    }

    if(!bWFP || (bWFP && flRoundStart == 0.0))
        flRoundStart = get_member_game(m_fRoundStartTimeReal);

    new ret;
    ExecuteForward(fwdRoundStart[1], ret);

    if(ret > Plague_Continue)
        return;

    if(bWFP)
        StartWaitingBehaviour();
    else
        StartNormalBehaviour();

    ExecuteForward(fwdRoundStart[1]);
}

public FreezeEnd()
{
    if(bWFP)
        return;

    new ret;
    ExecuteForward(fwdFreezeEnd[0], ret);

    if(ret > Plague_Continue)
        return;

    if(!bFreezeDelay)
    {
        ExecuteForward(fwdCountdownStart, _, iDelay);

        set_entvar(pCountdown, var_nextthink, flRoundStart + 1.0);
    }

    new players[MAX_PLAYERS], num;
    for(new i = 0; i < num; i++)
        ExecuteHamB(Ham_CS_Player_ResetMaxSpeed, players[i]);

    static iRoundTime; iRoundTime = get_member_game(m_iRoundTimeSecs);
    static iRoundFreezeTime; iRoundFreezeTime = get_member_game(m_iIntroRoundTime);
    iRoundFreezeTime -= iDelay + 2;

    static iTime;

    if(iRoundType == Round_Infinite || iRoundType == Round_InfiniteKill)
        iTime = get_timeleft();
    else if(!bFreezeDelay)
        iTime =  iRoundTime + iDelay;
    else
        iTime = iRoundTime + (iRoundFreezeTime > 0 ? 0 : (iRoundFreezeTime < 0 ? -iRoundFreezeTime : iDelay));

    set_member_game(m_iRoundTimeSecs, iTime);
    UTIL_RoundTime(_, iTime);

    ExecuteForward(fwdFreezeEnd[1]);
}

HandCountWFP(Float:flGametime)
{
    static PlayerNum;
    PlayerNum = UTIL_CountAlive();

    static iRemainingTime;
    iRemainingTime = UTIL_DelayRemaining();

    if(iRemainingTime <= 0 && PlayerNum >= iWFPMin)
    {
        UTIL_EndRound(2.0, WinEvent_WFP, Win_None, szMessages[MSG_END_WFP], "");
        return;
    }

    set_entvar(pCountdown, var_nextthink, flGametime + 1.0);
}

HandCountNormal(Float:flGametime)
{
    static iRemainingTime;
    iRemainingTime = UTIL_DelayRemaining();

    if(iRemainingTime <= 0)
    {
        RoundStart2();
        return;
    }
    else ExecuteForward(fwdCounted, _, iRemainingTime);

    set_entvar(pCountdown, var_nextthink, flGametime + 1.0);
}

public Countdown()
{
    static Float:flGametime;
    flGametime = get_gametime();

    if(bWFP)
        HandCountWFP(flGametime);
    else 
        HandCountNormal(flGametime);
}

public Player_Spawned(id)
{
    if(!bWFP || !bWFPStartNext || get_member(id, m_bJustConnected) || bRoundEnded)
        return;

    bRoundEnded = true;
    rg_round_end(2.0, WINSTATUS_NONE, ROUND_GAME_RESTART, "", "");
}

public WinConditions()
{
    if(bWFP)
        return HC_CONTINUE;

    if(iRoundType == Round_Infinite)
        return HC_SUPERCEDE;

    if(!bRoundStarted)
        return HC_SUPERCEDE;

    if(UTIL_CountAlive(_:TEAM_TERRORIST) == 0)
    {
        new szSound[128];
        GetRandomSound(SOUND_END_WINZ, szSound);
        UTIL_EndRound(get_pcvar_float(cRoundEndDelay), WinEvent_Extermination, Win_Human, szMessages[MSG_END_WINH], szSound);
    }
    else
    if(UTIL_CountAlive(_:TEAM_CT) == 0)
    {
        new szSound[128];
        GetRandomSound(SOUND_END_WINZ, szSound);
        UTIL_EndRound(get_pcvar_float(cRoundEndDelay), WinEvent_Extermination, Win_Zombie, szMessages[MSG_END_WINZ], szSound);
    }

    return HC_SUPERCEDE;
}

public RoundEnd(Float:tmDelay, ScenarioEventEndRound:event)
{
    if(event == ROUND_GAME_RESTART)
    {
        UTIL_EndRound(tmDelay, WinEvent_Restart, Win_None, szMessages[MSG_END_RESTART], "");
        SetHookChainReturn(ATYPE_BOOL, false);
        return HC_SUPERCEDE;
    }
    
    if(bWFP)
    {        
        if(UTIL_DelayRemaining() <= 0)
        {
            static timeSecs; timeSecs = get_timeleft();
            set_member_game(m_iRoundTimeSecs, timeSecs);
            UTIL_RoundTime(_, timeSecs + 2);
        }

        SetHookChainReturn(ATYPE_BOOL, false);
        return HC_SUPERCEDE;
    }

    if(UTIL_RoundSecondsRemaining() <= 0 && !(iRoundType == Round_Infinite || iRoundType == Round_InfiniteKill) && !bRoundEnded)
    {
        new szSound[128];
        GetRandomSound(SOUND_END_DRAW, szSound);
        UTIL_EndRound(get_pcvar_float(cRoundEndDelay), WinEvent_Expired, Win_Draw, szMessages[MSG_END_RESTART], szSound);
    }

    SetHookChainReturn(ATYPE_BOOL, false);
    return HC_SUPERCEDE;
}


/* -> STOCKS <- */
stock UTIL_EndRound(Float:delay, WinEvent:event, GameWin:win, szMsg[192], szSound[128], bool:call = true)
{
    new szInfo[RoundEndInfo];

    szInfo[RE_Delay] = delay;
    szInfo[RE_Event] = event;
    szInfo[RE_Win] = win;

    new hmsg, hsound, hinfo;
    hinfo = PrepareArray(szInfo, 3, 1);
    hmsg = PrepareArray(szMsg, charsmax(szMsg), 1);
    hsound = PrepareArray(szSound, charsmax(szSound), 1);

    if(call)
    {
        new ret;
        ExecuteForward( fwdRoundEnd[ 0 ], ret, hinfo, hmsg, hsound);

        if( ret > Plague_Continue || iRoundType == Round_Custom)
            return;
    }

    delay = szInfo[RE_Delay];
    event = szInfo[RE_Event];
    win = szInfo[RE_Win];

    set_entvar(pCountdown, var_nextthink, 0.0);

    bRoundEnded = true;
    bRoundStarted = false;

    iLastWin = win;
    iLastWinEvent = event;

    UTIL_PlaySound(_, szSound);
    
    static WinStatus:win2;
    switch(win)
    {
        case Win_Human: win2 = WINSTATUS_CTS;
        case Win_Zombie: win2 = WINSTATUS_TERRORISTS;
        case Win_Draw: win2 = WINSTATUS_DRAW;
        default: win2 = WINSTATUS_NONE;
    }

    static ScenarioEventEndRound: event2;
    switch(event)
    {
        case WinEvent_None:
        {
            event2 = ROUND_NONE;
        }

        case WinEvent_WFP:
        {
            set_member_game(m_bCompleteReset, true);

            event2 = ROUND_GAME_COMMENCE;
        }

        case WinEvent_Restart:
        {
            new str[10];
            get_cvar_string("sv_roundrestart", str, charsmax(str));

            if(contain(str, "."))
                delay = str_to_float(str);
            else
                delay = float(str_to_num(str));

            if(delay == 0.0)
            {
                get_cvar_string("sv_restart", str, charsmax(str));

                if(contain(str, "."))
                    delay = str_to_float(str);
                else
                    delay = float(str_to_num(str));
            }

            set_cvar_num("sv_restart", 0);
            set_cvar_num("sv_restartround", 0);

            set_member_game(m_flRestartRoundTime, get_gametime() + delay);
            set_member_game(m_bCompleteReset, true);

            event2 = ROUND_GAME_RESTART;
        }
        
        case WinEvent_Expired: event2 = ROUND_GAME_OVER;

        case WinEvent_Extermination: event2 = (win == Win_Human ? ROUND_CTS_WIN : ROUND_TERRORISTS_WIN);
    }

    rg_round_end(delay, win2, event2, fmt(szMsg, floatround(delay, floatround_ceil)), szSound);

    if(call)
        ExecuteForward( fwdRoundEnd[ 1 ], _, hinfo, hmsg, hsound);
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

stock UTIL_RoundTime(id = 0, _time)
{
    static gmsgRoundTime;
    if(!gmsgRoundTime) gmsgRoundTime = get_user_msgid("RoundTime");

    if(!id)
    {
        static players[MAX_PLAYERS], num;
        get_players(players, num);
        for(new i = 0; i < num; i++)
        {
            message_begin(MSG_ONE, gmsgRoundTime, _, players[i]);
            write_short(_time);
            message_end();
        }

        return;
    }

    message_begin(MSG_ONE, gmsgRoundTime, _, id);
    write_short(_time);
    message_end();
}

stock UTIL_RoundSecondsRemaining()
{
    static iRoundTime; iRoundTime = get_member_game(m_iRoundTimeSecs);
    return floatround(flRoundStart + iRoundTime - get_gametime());
}

stock UTIL_DelayRemaining()
{
    return floatround(flRoundStart + iDelay - get_gametime() + 1);
}

stock UTIL_PlaySound(player = 0, szSound[])
{
    client_cmd(player, "spk ^"%s^"", szSound);
}

/* -> NATIVES <- */
public Native_EndRound(plgId, params)
{
    if(params < 6)
        return;

    new Float:delay = get_param_f(1),
        WinEvent:event = WinEvent:get_param(2),
        GameWin:win = GameWin:get_param(3),
        szMsg[192],
        szSound[128],
        bool:call = bool:get_param(6);

    get_string(4, szMsg, charsmax(szMsg));
    get_string(5, szSound, charsmax(szSound));

    UTIL_EndRound(delay, event, win, szMsg, szSound, call);
}

public RoundStatus:Native_RoundStatus(plgId, params)
{
    if(bWFP)
        return RoundStatus_WaitingForPlayers;

    if(bRoundEnded)
        return RoundStatus_Ended;

    if(!bRoundStarted && !bRoundEnded)
        return RoundStatus_Starting;

    return RoundStatus_Started;
}

public GameWin:Native_LastWin()
{
    return iLastWin;
}

public WinEvent:Native_LastWinEvent()
{
    return iLastWinEvent;
}

public Native_RemainingSecs()
{
    return UTIL_RoundSecondsRemaining() - 2;
}

public RoundType:Native_GetRoundType()
{
    return iRoundType;
}

public Native_SetRoundType(plgId, params)
{
    if(params < 1)
        return;

    new RoundType:i = RoundType:get_param(1);

    iRoundType = i;
}

public Native_RoundStart()
{
    if(!bRoundStarted && !bRoundEnded)
        RoundStart2();
}