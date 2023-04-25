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

enum RestartType {
    RS_None,
    RS_Game,
    RS_Round
}

enum RespawnType {
    Respawn_None,
    Respawn_Zombie,
    Respawn_Human,
    Respawn_Zombie2,
    Respawn_Human2,
    Respawn_Opposite,
    Respawn_Balanced,
    Respawn_Random,
    Respawn_Yes
}

enum InfectionType {
    Infection_None,
    Infection_Kill,
    Infection_Infect,
    Infection_InfectArmor,
    //           > Future Update <
    // > Infection_Radiation ->
}

enum RoundTimer {
    RoundTimer_Inactive,
    RoundTimer_Active,
    RoundTimer_Timeleft
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

enum RoundStartType {
    RoundStart_NoDelay,
    RoundStart_Delay,
    RoundStart_FreezeDelay
}

enum FreezeDelayType {
    FreezeDelay_FreezeTime,
    FreezeDelay_Freeze
}

enum FreezeDelayTeam {
    FreezeTeam_Zombie,
    FreezeTeam_Human,
    FreezeTeam_All
}