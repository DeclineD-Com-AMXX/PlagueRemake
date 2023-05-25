#if defined _included_plague_round_
    #endinput
#endif

#define _included_plague_round_

#include <plague_rounds_const>

native pr_end_round(Float:delay, WinEvent:event, GameWin:win, const szMsg[] = "@default", const szSound[] = "@default", bool:call = true);
native RoundStatus:pr_round_status();
native GameWin:pr_get_last_win();
native WinEvent:pr_get_last_winevent();
native pr_get_remaining_seconds();
native pr_set_round_type(RoundType:type);
native RoundType:pr_get_round_type();
native pr_start_round();

forward Plague_RoundStart();
forward Plague_RoundStart_Post();
forward Plague_RoundStart2();
forward Plague_RoundStart2_Post();
forward Plague_OnFreezeEnd();
forward Plague_OnFreezeEnd_Post();
forward Plague_RoundEnd(szEndInfo[RoundEndInfo], szMsg[], szSound[]);
forward Plague_RoundEnd_Post(szEndInfo[RoundEndInfo], szMsg[], szSound[]);