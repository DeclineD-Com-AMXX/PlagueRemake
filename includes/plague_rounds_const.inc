#if defined _included_plague_rounds_const
    #endinput
#endif

#define _included_plague_rounds_const

enum GameWin {
    Win_None,
    Win_Draw,
    Win_Zombie,
    Win_Human
}

enum WinEvent {
    WinEvent_WFP,
    WinEvent_Restart,
    WinEvent_Expired,
    WinEvent_Extermination
}

enum RoundType {
    Round_Normal,
    Round_InfiniteKill,
    Round_Infinite,
    Round_Custom
}

enum RoundStatus {
    RoundStatus_WaitingForPlayers,
    RoundStatus_Starting,
    RoundStatus_Started,
    RoundStatus_Ended
}

enum _:RoundEndInfo {
    Float: RE_Delay,
    WinEvent: RE_Event,
    GameWin: RE_Win
}