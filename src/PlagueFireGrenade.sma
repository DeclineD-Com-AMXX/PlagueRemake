#include <amxmodx>
#include <reapi>
#include <fakemeta>
#include <hamsandwich>
#include <plague>

enum {
    Sprite_Beam,
    Sprite_Flame,
    Sprite_Smoke,
    Sprite_Exp,
    Sprites
}

new const szSprites[ Sprites ][ ] = {
    "sprites/laserbeam.spr",
    "sprites/fire.spr",
    "sprites/black_smoke3.spr",
    "sprites/fexplo1_fgren.spr"
};

new gszSprite[ Sprites ];

new const szExplodeSound[ ] = "zombie_plague/grenade_explode.wav";
new const pluginCfg[ ] = "addons/amxmodx/configs/plague.json";

const WeaponSpecialCode = 893128312;
new Float:flRadius, Float:flTime, Float:flRate, Float:flDamage;

new PlagueClassId: HumanClassId, PlagueClassId: ZombieClassId;

new playerFire[ MAX_PLAYERS + 1 ];

public plugin_precache()
{
    for(new i = 0; i < Sprites; i++)
        gszSprite[ i ] = precache_model(szSprites[i]);

    precache_sound(szExplodeSound);
}

public plugin_init()
{
    register_plugin("[Plague] Fire Grenade", "v1.0", "DeclineD");

    HumanClassId = pr_get_class_id(PClass_Human);
    ZombieClassId = pr_get_class_id(PClass_Zombie);

    RegisterHookChain(RG_CBasePlayer_ThrowGrenade, "ThrowGren_Post", 1);
    RegisterHookChain(RG_CBasePlayer_AddPlayerItem, "AddGren_Post", 1);
    RegisterHookChain(RG_CBasePlayer_Killed, "Killed", 1);

    RegisterHookChain(RG_CBasePlayer_PostThink, "Player_PostThink", 1);
}

public plugin_cfg()
{
    new JSON:FireSett = json_object_get_object_safe(pr_open_settings(pluginCfg), "fire_grenade");

    new JSON:temp = json_object_get_value_safe(FireSett, "radius", "150.0", JSONNumber, flRadius);
    json_free( temp );

    temp = json_object_get_value_safe(FireSett, "burn_time", "5.0", JSONNumber, flTime);
    json_free( temp );

    temp = json_object_get_value_safe(FireSett, "burn_dmg_rate", "0.01", JSONNumber, flRate);
    json_free( temp );

    temp = json_object_get_value_safe(FireSett, "burn_damage", "10.0", JSONNumber, flDamage);
    json_free( temp );
    json_free( FireSett );

    pr_close_settings(pluginCfg);
}

public client_connect(id)
{
    playerFire[ id ] = -1;
}

public client_disconnected(id)
{
    if (playerFire[ id ] != -1)
    {
        set_entvar( playerFire[ id ], var_flags, FL_KILLME );
        set_entvar( playerFire[ id ], var_nextthink, get_gametime( ) );
        playerFire[ id ] = -1;
    }
}

public Killed(id)
{
    if (playerFire[ id ] != -1)
    {
        set_entvar( playerFire[ id ], var_flags, FL_KILLME );
        set_entvar( playerFire[ id ], var_nextthink, get_gametime( ) );
        playerFire[ id ] = -1;
    }
}

public ThrowGren_Post(id, gren)
{
    new special = get_entvar( gren, var_impulse );
    if ( special != WeaponSpecialCode )
        return;

    new ent = GetHookChainReturn(ATYPE_INTEGER);
    set_entvar(ent, var_impulse, special);

    message_begin(MSG_ALL, SVC_TEMPENTITY);
    write_byte(TE_BEAMFOLLOW);
    write_short(ent);
    write_short(gszSprite[ Sprite_Beam ]);
    write_byte(10);
    write_byte(10);
    write_byte(255);
    write_byte(0);
    write_byte(0);
    write_byte(200);
    message_end();

    SetThink(ent, "ExpThink");
}

public ExpThink(id)
{
    if(get_entvar(id, var_dmgtime) > get_gametime())
    {
        set_entvar(id, var_nextthink, get_entvar(id, var_dmgtime));
        return;
    }

    new Float:flOrigin[3]; get_entvar(id, var_origin, flOrigin);

    message_begin(MSG_PVS, SVC_TEMPENTITY);
    write_byte(TE_BEAMTORUS);
    write_coord_f(flOrigin[0]);
    write_coord_f(flOrigin[1]);
    write_coord_f(flOrigin[2]);
    write_coord_f(-flOrigin[0]);
    write_coord_f(-flOrigin[1]);
    write_coord_f(flOrigin[2] + flRadius);
    write_short(gszSprite[ Sprite_Beam ] );
    write_byte(0);
    write_byte(30);
    write_byte(10);
    write_byte(35);
    write_byte(0);
    write_byte(255);
    write_byte(0);
    write_byte(0);
    write_byte(255);
    write_byte(0);
    message_end();

    message_begin(MSG_PVS, SVC_TEMPENTITY);
    write_byte(TE_BEAMTORUS);
    write_coord_f(flOrigin[0]);
    write_coord_f(flOrigin[1]);
    write_coord_f(flOrigin[2]);
    write_coord_f(-flOrigin[0]);
    write_coord_f(-flOrigin[1]);
    write_coord_f(flOrigin[2] + flRadius);
    write_short( gszSprite[ Sprite_Beam ] );
    write_byte(0);
    write_byte(30);
    write_byte(10);
    write_byte(25);
    write_byte(0);
    write_byte(255);
    write_byte(150);
    write_byte(0);
    write_byte(255);
    write_byte(0);
    message_end();

    message_begin(MSG_PVS, SVC_TEMPENTITY);
    write_byte(TE_BEAMTORUS);
    write_coord_f(flOrigin[0]);
    write_coord_f(flOrigin[1]);
    write_coord_f(flOrigin[2]);
    write_coord_f(-flOrigin[0]);
    write_coord_f(-flOrigin[1]);
    write_coord_f(flOrigin[2] + flRadius);
    write_short(gszSprite[ Sprite_Beam ] );
    write_byte(0);
    write_byte(30);
    write_byte(10);
    write_byte(15);
    write_byte(0);
    write_byte(255);
    write_byte(150);
    write_byte(150);
    write_byte(150);
    write_byte(0);
    message_end();

    message_begin(MSG_PVS, SVC_TEMPENTITY);
    write_byte(TE_DLIGHT);
    write_coord_f(flOrigin[0]);
    write_coord_f(flOrigin[1]);
    write_coord_f(flOrigin[2] + 20.0);
    write_byte(20);
    write_byte(255);
    write_byte(0);
    write_byte(0);
    write_byte(30);
    write_byte(40);
    message_end();

    message_begin(MSG_PVS, SVC_TEMPENTITY);
    write_byte(TE_EXPLOSION);
    write_coord_f(flOrigin[0]);
    write_coord_f(flOrigin[1]);
    write_coord_f(flOrigin[2] + 20.0);
    write_short(gszSprite[ Sprite_Exp ]);
    write_byte(35);
    write_byte(22);
    write_byte(TE_EXPLFLAG_NODLIGHTS | TE_EXPLFLAG_NOSOUND | TE_EXPLFLAG_NOPARTICLES);
    message_end();

    new attacker = get_entvar(id, var_owner);

    emit_sound(id, CHAN_BODY, szExplodeSound, 1.0, ATTN_NORM, SND_SPAWNING, PITCH_NORM);

    set_entvar(id, var_flags, FL_KILLME);
    set_entvar(id, var_nextthink, get_gametime());

    LightUp(attacker, flOrigin);
}

public AddGren_Post(id, gren)
{
    if ( get_member(gren, m_iId) != WEAPON_HEGRENADE ||
        get_entvar( gren, var_impulse ) != 0 || pr_get_user_class(id) == ZombieClassId )
        return;

    set_entvar( gren, var_impulse, WeaponSpecialCode );
}

stock LightUp(attacker, Float:flOrigin[3])
{
    new ent = -1;
    while((ent = engfunc(EngFunc_FindEntityInSphere, ent, flOrigin, flRadius)) != -1 && ent < 33)
    {
        if ( pr_get_user_class( ent ) == HumanClassId || !is_user_connected( ent ) )
            continue;

        if ( playerFire[ ent ] != -1 )
        {
            set_entvar(playerFire[ ent ], var_iuser2, floatround( flTime / flRate ) );
            set_entvar(playerFire[ ent ], var_owner, attacker);
            continue;
        }
        
        new fire = rg_create_entity("env_sprite");
        playerFire[ ent ] = fire;
        set_entvar(fire, var_spawnflags, SF_SPRITE_STARTON);
        set_entvar(fire, var_model, szSprites[ Sprite_Flame ]);
        set_entvar(fire, var_modelindex, gszSprite[ Sprite_Flame ]);
        set_entvar(fire, var_owner, attacker);
        set_entvar(fire, var_enemy, ent);
        set_entvar(fire, var_scale, 0.5);
        set_entvar(fire, var_aiment, ent);
        set_entvar(fire, var_movetype, MOVETYPE_FOLLOW);
        set_entvar(fire, var_iuser2, floatround( flTime / flRate ) );
        set_entvar(fire, var_rendermode, kRenderTransAdd );
        set_entvar(fire, var_renderamt, 255.0);
        set_entvar(fire, var_origin, flOrigin);
        set_entvar(fire, var_framerate, 30.0);
        dllfunc(DLLFunc_Spawn, fire);
        set_entvar(fire, var_nextthink, get_gametime());
    }
}

public Player_PostThink(id)
{
    static fire; fire = playerFire[ id ];

    if ( fire == -1 )
        return;

    static Times; Times = get_entvar( fire, var_iuser2 );
    static Float:flGametime; flGametime = get_gametime( );
    static Float: nextTime; nextTime = get_entvar( fire, var_fuser1 );

    if ( flGametime < nextTime )
        return;

    if ( Times == 0 )
    {
        playerFire[ get_entvar( fire, var_enemy ) ] = -1;
        set_entvar(fire, var_flags, FL_KILLME);
        set_entvar(fire, var_nextthink, flGametime);
        return;
    }

    set_entvar( fire, var_iuser2, Times - 1 );

    static Float:flOrigin[ 3 ]; get_entvar( fire, var_origin, flOrigin );

    ExecuteHamB(Ham_TakeDamage, get_entvar(fire, var_enemy), fire, get_entvar(fire, var_owner), flDamage, DMG_NEVERGIB | DMG_BURN);

    set_entvar( fire, var_fuser1, flGametime + flRate );
}