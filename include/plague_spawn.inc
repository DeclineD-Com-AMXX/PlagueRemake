#include <plague_spawn_const>

native pr_add_to_respawn(id);
native Float: pr_get_respawn_start_time(id);
native Float: pr_get_respawn_end_time(id);
native pr_get_respawn_seconds_remaining(id);
native pr_set_respawn_end_time(id, Float:flTime);
native pr_set_respawn_type(RespawnType:type);
native RespawnType:pr_get_respawn_type();

forward Plague_Respawn_Pre(id);
forward Plague_Respawn_Post(id);

forward Plague_AddToRespawn_Pre(id, Float:startTime);
forward Plague_AddToRespawn_Post(id, Float:startTime);