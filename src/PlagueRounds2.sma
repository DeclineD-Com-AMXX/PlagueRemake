/* -> Includes <- */
#include <amxmodx>
#include <amxmisc>
#include <reapi>

#include <plague_rounds_const>
#include <plague_const>
#include <plague_settings>


/* -> Plugin Info <- */
new const pluginName[] = "[Plague] Round Management";
new const pluginVersion[] = "Final";
new const pluginAuthor[] = "DeclineD";


/* -> Settings <- */
new const pluginCfg[] = "addons/amxmodx/configs/plague.json";
new const pluginSection[] = "round";

enum _:SettKeys {
    any: ROUND_MSG,
    any: ROUND_SOUND
}

enum _:MsgKeys {
    any: MSG_END_WINH,
    any: MSG_END_WINZ,
    any: MSG_END_DRAW,
    any: MSG_END_WFP,
    any: MSG_END_RESTART
}

enum _:SoundKeys {
    any: SOUND_END_WINH,
    any: SOUND_END_WINZ,
    any: SOUND_END_DRAW
}

new const szSettKey[SettKeys][] = {
   "messages", "sounds"
};

new const szMessageKey[MsgKeys][] = {
    "win_human", "win_zombie", "win_draw",
    "end_wfp", "end_restart"
};

new const szSoundKey[SoundKeys][] = {
    "win_human", "win_zombie", "win_draw"
};

new const szDefaultMessages[MsgKeys][] = {
    "Humans defeated the plague!", "Zombies infected the world!",
    "No one won!", "Waiting For Players Ended!", "Game will restart in %i seconds."
};

new const szDefaultSound[SoundKeys][] = {
    "radio/ctwin.wav", "radio/trwin.wav", "radio/rounddraw.wav"
};

new gszMessages[MsgKeys][192];
new Array:gaSounds[SoundKeys];

LoadSettings()
{
    new i;
    for(i = 0; i < SoundKeys; i++)
        gaSounds[i] = ArrayCreate(128, 1);

    new JSON: file = pr_open_settings(pluginCfg);

    new JSON:section = json_object_get_object_safe(file, pluginSection);

    new JSON:temp, JSON:temp2, any:value, x;
    temp = json_object_get_object_safe(section, szSettKey[ROUND_MSG]);

    for(i = 0; i < MsgKeys; i++)
    {
        temp2 = json_object_get_string_safe(temp, szMessageKey[i], szDefaultMessages[i], gszMessages[i], charsmax(gszMessages[]));
        json_free(temp2);
    }
    
    json_free(temp);

    temp = json_object_get_object_safe(section, szSettKey[ROUND_SOUND]);

    new szSound[128];

    for(i = 0; i < SoundKeys; i++)
    {
        temp2 = json_object_get_array_safe(temp, szSoundKey[i]);
        value = json_array_get_count(temp2);

        if(value == 0)
        {
            copy(szSound, charsmax(szSound), szDefaultSound[i]);
            json_array_append_string(temp2, szSound);
            ArrayPushString(gaSounds[i], szSound);
            precache_sound(szSound);
        }
        else
        for(x = 0; x < value; x++)
        {
            json_array_get_string(temp2, x, szSound, charsmax(szSound));
            ArrayPushString(gaSounds[i], szSound);
            precache_sound(szSound);
        }
    }

    pr_close_settings(pluginCfg);
}

/* -> Cvars <- */
enum _:plgCvars {
    START_DELAY,
    END_DELAY,
    FREEZE_DELAY,
    HUD_MSG_ON,
    WFP_ON,
    WFP_MIN,
    WFP_TIME
}

new gCvars[plgCvars];

get_pcvar_num_safe(cvar)
{
    new szValue[100];
    get_pcvar_string(cvar, szValue, charsmax(szValue));

    if(contain(szValue, ".") != -1)
        return floatround(str_to_float(szValue));
    
    return str_to_num(szValue);
}

Float: get_pcvar_float_safe(cvar)
{
    new szValue[100];
    get_pcvar_string(cvar, szValue, charsmax(szValue));

    if(contain(szValue, ".") == -1)
        return float(str_to_num(szValue));
    
    return str_to_float(szValue);
}

/* -> Counting Down <- */
new pCountdown;

/* -> WFP Works <- */
new bool:bWFP;
new Float:flWFPTime;
new iWFPMin;

/* -> Round Works <- */
new iDelay;
new bool:bFreezeDelay;

new RoundStatus:iRoundStatus;

new Float:flRoundStart = 0.0;

new fwdRoundStart[2], fwdRoundEnd[2];
new fwdFreezeEnd[2], fwdRoundStart2[2];
new fwdCounted[2];

new GameWin: iLastWin;
new WinEvent: iLastWinEvent;

new RoundType: iRoundType;

/* *[-> PLUGIN <-]* */
public plugin_precache()
{
    LoadSettings( );

    fwdRoundStart[ 0  ] = CreateMultiForward( "Plague_RoundStart",       ET_CONTINUE );
    fwdRoundStart[ 1  ] = CreateMultiForward( "Plague_RoundStart_Post",  ET_IGNORE );

    fwdRoundStart2[ 0 ] = CreateMultiForward( "Plague_RoundStart2",      ET_CONTINUE );
    fwdRoundStart2[ 1 ] = CreateMultiForward( "Plague_RoundStart2_Post", ET_IGNORE );

    fwdFreezeEnd[ 0   ] = CreateMultiForward( "Plague_OnFreezeEnd",      ET_CONTINUE );
    fwdFreezeEnd[ 1   ] = CreateMultiForward( "Plague_OnFreezeEnd_Post", ET_IGNORE );

    fwdRoundEnd[ 0    ] = CreateMultiForward( "Plague_RoundEnd",         ET_CONTINUE, FP_ARRAY, FP_STRING, FP_STRING );
    fwdRoundEnd[ 1    ] = CreateMultiForward( "Plague_RoundEnd_Post",    ET_IGNORE, FP_ARRAY, FP_STRING, FP_STRING );

    fwdCounted[ 0     ] = CreateMultiForward( "Plague_Counted_Pre",      ET_CONTINUE, FP_CELL );
    fwdCounted[ 1     ] = CreateMultiForward( "Plague_Counted_Post",     ET_IGNORE, FP_CELL );
}

public plugin_natives()
{
    register_native("pr_end_round", "Native_EndRound");
    register_native("pr_round_status", "Native_RoundStatus");
    register_native("pr_get_last_win", "Native_LastWin");
    register_native("pr_get_last_winevent", "Native_LastWinEvent");
    register_native("pr_get_remaining_seconds", "Native_RemainingSecs");
    register_native("pr_get_remaining_delay", "Native_RemainingDelay");
    register_native("pr_set_round_type", "Native_SetRoundType");
    register_native("pr_get_round_type", "Native_GetRoundType");
    register_native("pr_start_round", "Native_RoundStart", 1);
}

public plugin_init()
{
    register_plugin(pluginName, pluginVersion, pluginAuthor);

    RegisterHookChain(RG_RoundEnd, "ReHook_EndRound");
    RegisterHookChain(RG_CSGameRules_CheckWinConditions, "ReHook_CSGameRules_WinConditions");
    RegisterHookChain(RG_CSGameRules_CheckMapConditions, "MapConditions_Post", 1);

    RegisterHookChain(RG_CSGameRules_RestartRound, "ReHook_CSGameRules_RoundStart_Pre");
    RegisterHookChain(RG_CSGameRules_RestartRound, "ReHook_CSGameRules_RoundStart_Post", 1);
    RegisterHookChain(RG_CSGameRules_OnRoundFreezeEnd, "ReHook_CSGameRules_RoundFreezeEnd_Post", 1);

    RegisterHookChain(RG_CBasePlayer_Spawn, "ReHook_CBasePlayer_Spawn_Post", 1);

    gCvars[START_DELAY] = register_cvar("pr_start_delay", "10");
    gCvars[END_DELAY] = register_cvar("pr_end_delay", "5.0");
    gCvars[FREEZE_DELAY] = register_cvar("pr_freeze_delay", "1");
    gCvars[HUD_MSG_ON] = register_cvar("pr_message_hud_msg", "1");
    gCvars[WFP_ON] = register_cvar("pr_wfp_on", "1");
    gCvars[WFP_MIN] = register_cvar("pr_wfp_min", "2");
    gCvars[WFP_TIME] = register_cvar("pr_wfp_time", "20.0");

    pCountdown = rg_create_entity("info_target");
    SetThink(pCountdown, "Countdown");

    iRoundStatus = RoundStatus_WaitingForPlayers;
}

public plugin_cfg()
{
    server_cmd("exec addons/amxmodx/configs/plague.cfg");   
}

public plugin_end()
{
    new any:i;
    for(i = 0; i < SoundKeys; i++)
        ArrayDestroy(gaSounds[i]);
}

public client_connect()
{
    if(!get_pcvar_bool(gCvars[WFP_ON]))
        return;

    iWFPMin = get_pcvar_num(gCvars[WFP_MIN]);

    if(UTIL_CountAlive() < iWFPMin && !bWFP)
    {
        flRoundStart = 0.0;
        flWFPTime = get_pcvar_float_safe(gCvars[WFP_TIME]);
        bWFP = true;
    }
}

public Countdown()
{
    static Float: flGametime; flGametime = get_gametime();
    static Remaining; Remaining = UTIL_DelayRemaining();

    if(bWFP)
    {
        static Alive; Alive = UTIL_CountAlive();
        if(Remaining <= 0 && Alive >= iWFPMin)
        {
            UTIL_EndRound(2.0, WinEvent_WFP, Win_None);
            return;
        }
    }
    else {
        if(Remaining <= 0)
        {
            Native_RoundStart(true);
            return;
        }
    }

    new ret;

    set_entvar(pCountdown, var_nextthink, flGametime + 1.0);
}


// Making sure that RoundEnd is called when time is up!
public MapConditions_Post()
{
    set_member_game(m_bMapHasBombTarget, true);
}

public ReHook_CBasePlayer_Spawn_Post(id)
{
    if(!bWFP || get_member(id, m_bJustConnected) || flRoundStart != 0.0)
        return;

    rg_round_end(1.0, WINSTATUS_NONE, ROUND_GAME_RESTART, "", "");
}

public ReHook_CSGameRules_RoundStart_Pre()
{
    iRoundStatus = RoundStatus_Starting;
}

public ReHook_CSGameRules_RoundStart_Post()
{
    if(iLastWinEvent == WinEvent_WFP)
    {
        bWFP = false;
        set_member_game(m_bGameStarted, true);
        set_member_game(m_bNeededPlayers, false);
    }

    new ret;
    ExecuteForward( fwdRoundStart[0], ret );

    if ( ret == Plague_Continue )
        return;

    if(bWFP)
    {
        iRoundStatus = RoundStatus_WaitingForPlayers;

        if(flRoundStart == 0.0)
        {
            flRoundStart = get_member_game(m_fRoundStartTimeReal);
            iDelay = floatround(flWFPTime);
        }

        set_entvar(pCountdown, var_nextthink, flRoundStart + 1.0);
        set_member_game(m_iRoundTimeSecs, get_timeleft());
        set_member_game(m_bFreezePeriod, false);

        ExecuteForward( fwdRoundStart[1], ret );
        return;
    }

    flRoundStart = get_member_game(m_fRoundStartTimeReal);
    iDelay = get_pcvar_num_safe(gCvars[START_DELAY]);
    bFreezeDelay = bool:get_pcvar_num(gCvars[FREEZE_DELAY]);

    if(!bFreezeDelay)
    {
        ExecuteForward( fwdRoundStart[1], ret );
        return;
    }

    set_entvar(pCountdown, var_nextthink, flRoundStart + 1.0);

    ExecuteForward( fwdRoundStart[1], ret );
}

public ReHook_CSGameRules_RoundFreezeEnd_Post()
{
    if(bWFP)
        return;
    
    new ret;
    ExecuteForward(fwdFreezeEnd[0], ret);
    
    if(ret > Plague_Continue)
        return;

    if(!bFreezeDelay)
        set_entvar(pCountdown, var_nextthink, flRoundStart + 1.0);

    static iRoundTime; iRoundTime = get_member_game(m_iRoundTimeSecs);
    static iRoundFreezeTime; iRoundFreezeTime = get_member_game(m_iIntroRoundTime);
    iRoundFreezeTime -= iDelay + 2;

    static iTime;

    if(iRoundType == Round_Infinite || iRoundType == Round_InfiniteKill)
    {
        iTime = get_timeleft();
    }
    else if(!bFreezeDelay)
    {
        iTime =  iRoundTime + iDelay;
    }
    else
    {
        iTime = iRoundTime + (iRoundFreezeTime > 0 ? 0 : (iRoundFreezeTime < 0 ? -iRoundFreezeTime : iDelay));
    }

    set_member_game(m_iRoundTimeSecs, iTime);
    UTIL_RoundTime(_, iTime);

    ExecuteForward(fwdFreezeEnd[1]);
}

public ReHook_CSGameRules_WinConditions()
{
    if(bWFP || iRoundType == Round_Infinite || iRoundStatus != RoundStatus_Started)
        return HC_SUPERCEDE;

    static PlayerCount[2];
    for(new any:i = 0; i < 2; i++)
        PlayerCount[i++] = UTIL_CountAlive(i);

    if(UTIL_CountAlive(_:TEAM_TERRORIST) == 0)
        UTIL_EndRound(-1.0, WinEvent_Extermination, Win_Human);
    else if(UTIL_CountAlive(_:TEAM_CT) == 0)
        UTIL_EndRound(-1.0, WinEvent_Extermination, Win_Zombie);

    return HC_SUPERCEDE;
}

public ReHook_EndRound(Float:tmDelay, ScenarioEventEndRound:event)
{
    if(event == ROUND_GAME_RESTART)
    {
        UTIL_EndRound(UTIL_GetRestartSeconds(), WinEvent_Restart, Win_None);
        SetHookChainReturn(ATYPE_BOOL, false);
        return HC_SUPERCEDE;
    }

    if(bWFP)
    {
        SetHookChainReturn(ATYPE_BOOL, false);
        return HC_SUPERCEDE;
    }

    if(UTIL_RoundSecondsRemaining() <= 0 && 
    !(iRoundType == Round_Infinite || iRoundType == Round_InfiniteKill) && 
    iRoundStatus != RoundStatus_Ended)
    {
        UTIL_EndRound(-1.0, WinEvent_Expired, Win_Draw);
    }

    SetHookChainReturn(ATYPE_BOOL, false);
    return HC_SUPERCEDE;
}

/* *[-> NATIVES <-]* */
public Native_EndRound(plgId, params)
{
    if(params < 6)
    {
        log_error(AMX_ERR_NATIVE, "Not enough parameters to execute.");
        return;
    }

    new Float:delay = get_param_f(1);
    new WinEvent:event = WinEvent:get_param(2);
    new GameWin:win = GameWin:get_param(3);
    new bool:call = bool:get_param(6);
    new szMsg[192], szSound[128];

    get_string(4, szMsg, charsmax(szMsg));
    get_string(5, szSound, charsmax(szSound));

    UTIL_EndRound(delay, event, win, szMsg, szSound, call);
}

public RoundStatus:Native_RoundStatus()
{
    return iRoundStatus;
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
    return UTIL_RoundSecondsRemaining();
}

public Native_SetRoundType(plgId, params)
{
    if(params < 1)
    {
        log_error(AMX_ERR_NATIVE, "Not enough parameters to execute.");
        return;
    }

    iRoundType = RoundType:get_param(1);
}

public RoundType:Native_GetRoundType()
{
    return iRoundType;
}

public Native_RoundStart(bool:call)
{
    if(call)
    {
        new ret;
        ExecuteForward(fwdRoundStart2[0], ret);

        if(ret > Plague_Continue)
            return;
    }

    iRoundStatus = RoundStatus_Started;

    if ( call )
        ExecuteForward(fwdRoundStart2[1]);
}

public Native_RemainingDelay() return UTIL_DelayRemaining();

/* *[-> UTILS <-]* */
stock UTIL_EndRound(Float:delay = -1.0, WinEvent:event, GameWin:win, szMsg[192] = "@default", szSound[128] = "@default", bool:call = true)
{
    new szInfo[RoundEndInfo];

    new hmsg, hsound, hinfo;
    hinfo = PrepareArray(szInfo, 3, 1);

    if(equal(szMsg, "@default"))
        UTIL_GetEndMessage(event, win, szMsg, charsmax(szMsg));

    if(equal(szSound, "@default"))
    {
        if(event == WinEvent_Extermination)
        {
            UTIL_GetEndSound(win, szSound, charsmax(szSound));
        }
        else
        {
            copy(szSound, charsmax(szSound), "");
        }
    }

    if(delay < 0.0)
    {
        delay = get_pcvar_float_safe(gCvars[END_DELAY]);
    }

    szInfo[RE_Delay] = delay;
    szInfo[RE_Event] = event;
    szInfo[RE_Win] = win;

    hmsg = PrepareArray(szMsg, charsmax(szMsg), 1);
    hsound = PrepareArray(szSound, charsmax(szSound), 1);

    if(call)
    {
        new ret;
        ExecuteForward( fwdRoundEnd[ 0 ], ret, hinfo, hmsg, hsound);

        if( ret > Plague_Continue )
            return;
    }

    if ( iRoundType == Round_Custom )
    {
        ExecuteForward( fwdRoundEnd[ 1 ], _, hinfo, hmsg, hsound);
        return;
    }

    delay = szInfo[RE_Delay];
    event = szInfo[RE_Event];
    win = szInfo[RE_Win];

    set_entvar(pCountdown, var_nextthink, 0.0);

    iRoundStatus = RoundStatus_Ended;

    iLastWin = win;
    iLastWinEvent = event;

    UTIL_PlaySound(_, szSound);

    if ( strlen( szMsg ) > 0 )
        UTIL_CenterMessage(0, szMsg, floatround(delay));
    
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
            set_cvar_num("sv_restart", 0);
            set_cvar_num("sv_restartround", 0);

            set_member_game(m_flRestartRoundTime, get_gametime() + delay);
            set_member_game(m_bCompleteReset, true);

            event2 = ROUND_GAME_RESTART;
        }
        
        case WinEvent_Expired: event2 = ROUND_GAME_OVER;

        case WinEvent_Extermination: event2 = (win == Win_Human ? ROUND_CTS_WIN : ROUND_TERRORISTS_WIN);
    }

    rg_round_end(delay, win2, event2, "", "");

    if(call)
        ExecuteForward( fwdRoundEnd[ 1 ], _, hinfo, hmsg, hsound);
}

stock Float: UTIL_GetRestartSeconds()
{
    new str[10];
    get_cvar_string("sv_roundrestart", str, charsmax(str));

    new Float:delay;

    if(contain(str, ".") != 1)
    {
        delay = str_to_float(str);
    }
    else
    {
        delay = float(str_to_num(str));
    }

    if(delay <= 0.0)
    {
        get_cvar_string("sv_restart", str, charsmax(str));

        if(contain(str, ".") != 1)
        {
            delay = str_to_float(str);
        }
        else
        {
            delay = float(str_to_num(str));
        }
    }

    return delay;
}

stock UTIL_GetEndMessage(WinEvent:event, GameWin:win, szMsg[], len)
{
    switch(event)
    {
        case WinEvent_Restart:
        {
            copy(szMsg, len, gszMessages[MSG_END_RESTART]);
        }

        case WinEvent_WFP:
        {
            copy(szMsg, len, gszMessages[MSG_END_WFP]);
        }
        
        case WinEvent_Extermination:
        {
            if(win == Win_Human)
            {
                copy(szMsg, len, gszMessages[MSG_END_WINH]);
            }
            else if(win == Win_Zombie)
            {
                copy(szMsg, len, gszMessages[MSG_END_WINZ]);
            }
        }
        
        case WinEvent_Expired:
        {
            copy(szMsg, len, gszMessages[MSG_END_DRAW]);
        }

        default:
        {
            copy(szMsg, len, "");
        }
    }
}

stock UTIL_GetEndMsgSettingId(WinEvent:event, GameWin:win)
{
    new id = -1;
    switch(event)
    {
        case WinEvent_Restart:
        {
            id = MSG_END_RESTART;
        }

        case WinEvent_WFP:
        {
            id = MSG_END_WFP;
        }
        
        case WinEvent_Extermination:
        {
            if(win == Win_Human)
            {
                id = MSG_END_WINH;
            }
            else if(win == Win_Zombie)
            {
                id = MSG_END_WINZ;
            }
        }
        
        case WinEvent_Expired:
        {
            id = MSG_END_DRAW;
        }
    }

    return id;
}

stock UTIL_GetEndSound(GameWin:win, szSound[], len)
{
    new rand, Array:a = Invalid_Array;

    switch(win)
    {
        case Win_Human: a = gaSounds[0];
        case Win_Zombie: a = gaSounds[1];
        case Win_Draw: a = gaSounds[2];
    }
        
    if(a == Invalid_Array || !ArraySize(a))
        return;

    rand = random_num(0, ArraySize(a) - 1);
    ArrayGetString(a, rand, szSound, len);
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