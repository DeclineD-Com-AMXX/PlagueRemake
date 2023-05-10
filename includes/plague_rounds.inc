#include <plague_rounds_const>

native pr_end_round(Float:delay, WinEvent:event, GameWin:win);
native RoundStatus: pr_round_status();
native GameWin: pr_get_last_win();
native WinEvent: pr_get_last_winevent();
native pr_get_remaining_seconds();
native pr_set_round_type(RoundType:type);
native RoundType: pr_get_round_type();

// Used only when you stop the Plague_RoundStart2 forward
native pr_start_round();

forward Plague_RoundStart();
forward Plague_RoundStart_Post();
forward Plague_RoundStart2();
forward Plague_RoundStart2_Post();
forward Plague_OnFreezeEnd();
forward Plague_OnFreezeEnd_Post();
forward Plague_Countdown_Start(iSeconds);
forward Plague_Counted(iSecond);
forward Plague_RoundEnd(endInfo[RoundEndInfo]);
forward Plague_RoundEnd_Post(endInfo[RoundEndInfo]);