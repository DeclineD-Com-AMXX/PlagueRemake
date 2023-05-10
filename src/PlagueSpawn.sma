#include <amxmodx>
#include <hamsandwich>
#include <reapi>

#include <plague_zombie>
#include <plague_rounds>
#include <plague_const>
#include <plague_spawn_const>

new RespawnType:gRespawnType;
new bool:bCanSpawn[MAX_PLAYERS + 1];