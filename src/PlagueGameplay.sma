#include <amxmodx>
#include <engine>
#include <reapi>

#include <plague_settings>
#include <plague_zombie>
#include <plague_human>

const Task_Fog = 832784273;

new const pluginCfg[] = "addons/amxmodx/configs/plague.json";

/* *[-> Countdown Settings <-]* */
enum _:KeyHudSettings {
    any:HUDKEY_MSG,
    any:HUDKEY_HUD,
    any:HUDKEY_COLOR_R,
    any:HUDKEY_COLOR_G,
    any:HUDKEY_COLOR_B,
    any:HUDKEY_COORDS_X,
    any:HUDKEY_COORDS_Y,
    any:HUDKEY_EFFECT,
    any:HUDKEY_HOLD,
    any:HUDKEY_FADEIN,
    any:HUDKEY_FADEOUT
}

new const szDefaultHudSettings[KeyHudSettings][] = {
    "",
    "1",
    "255", "255", "255",
    "-1.0", "-1.0",
    "0",
    "2.0",
    "0.1","0.1"
}

new const szHudKey[KeyHudSettings][] = {
    "message",
    "custom_hud",
    "color_r", "color_g", "color_b",
    "x", "y",
    "effect",
    "display_time",
    "fadein_time", "fadeout_time"
}

enum _:KeyMessages {
    KEYMSG_COUNT,
    KEYMSG_COUNT_WFP,
    KEYMSG_WAIT_WFP,
    KEYMSG_INFECT,
    KEYMSG_ANTIDOTE
}

new const szMsgKey[KeyMessages][] = {
    "countdown",
    "wfp_time",
    "wfp_wait",
    "infected",
    "used_antidote"
}

new const szDefaultMsg[KeyMessages][] = {
    "Round will start in %i.", "Waiting for players ending in %i.",
    "Waiting for players: %i/%i.", "%n got their brains eaten by %n!",
    "%n used antidote!"
}

new gszMessages[KeyMessages][192];
new giValues[KeyMessages][KeyHudSettings];

/* *[-> Weather Settings<-]* */
new iFogColor[3], Float:fFogDensity;
new iSkyColor[3];
new skyName[64] = "tornsky";
new const skyPrefix[][] = {"bk", "dn", "ft", "lf", "rt", "up"};

public plugin_precache()
{
    new JSON:section = json_object_get_object_safe(pr_open_settings(pluginCfg), "gameplay");
    new JSON:section2 = json_object_get_object_safe(section, "fog");

    new JSON:temp = json_object_get_value_safe(section2, "r", "255", JSONNumber, iFogColor[0]);
    json_free(temp);

    temp = json_object_get_value_safe(section2, "g", "255", JSONNumber, iFogColor[1]);
    json_free(temp);

    temp = json_object_get_value_safe(section2, "b", "255", JSONNumber, iFogColor[2]);
    json_free(temp);

    temp = json_object_get_value_safe(section2, "density", "0.1", JSONNumber, fFogDensity);
    json_free(temp);
    json_free(section2);

    section2 = json_object_get_object_safe(section, "sky");

    temp = json_object_get_value_safe(section2, "r", "255", JSONNumber, iSkyColor[0]);
    json_free(temp);

    temp = json_object_get_value_safe(section2, "g", "255", JSONNumber, iSkyColor[1]);
    json_free(temp);

    temp = json_object_get_value_safe(section2, "b", "255", JSONNumber, iSkyColor[2]);
    json_free(temp);

    temp = json_object_get_string_safe(section2, "sky_name", skyName, skyName, charsmax(skyName));
    json_free(temp);
    json_free(section2);

    section2 = json_object_get_object_safe(section, "messages");

    new JSON:temp2, i, x;
    for(i = 0; i < KeyMessages; i++)
    {   
        temp = json_object_get_object_safe(section2, szMsgKey[i]);
        for(x = 0; x < KeyHudSettings; x++)
        {
            switch( x )
            {
                case HUDKEY_MSG: temp2 = json_object_get_string_safe(temp, szHudKey[x], szDefaultMsg[i], gszMessages[i], charsmax(gszMessages[]));
                default: temp2 = json_object_get_value_safe(temp, szHudKey[x], szDefaultHudSettings[x], JSONNumber, giValues[i][x]);
            }

            json_free(temp2);
        }
        json_free(temp);
    }

    json_free(section);

    pr_close_settings(pluginCfg);

    new szBuffer[68];

    for(new i = 0; i < sizeof skyPrefix; i++)
    {
        formatex( szBuffer, charsmax( szBuffer ), "gfx/env/%s%s.tga", skyName, skyPrefix[i] );
        precache_generic(szBuffer);
    }
}

public plugin_cfg()
{
    Game_MakeSky();
}

public plugin_init()
{
    register_plugin("[Plague] Gameplay Settings", "", "" );
    RegisterHookChain(RG_CBasePlayer_Spawn, "Spawn", 1);
    register_clcmd("say /zm", "cmdZm");
}

public cmdZm(id)
{
    pr_open_zombies_menu(id);
}

public fog(id)
{
    id -= Task_Fog;
    CreateFog( id, iFogColor[0], iFogColor[1], iFogColor[2], fFogDensity );
}

public Spawn(id)
{
    set_task(0.3, "fog", Task_Fog+id);
}

public Plague_Humanize_Post(id, attacker)
{
    set_dhudmessage(
        giValues[KEYMSG_ANTIDOTE][HUDKEY_COLOR_R], 
        giValues[KEYMSG_ANTIDOTE][HUDKEY_COLOR_G],
        giValues[KEYMSG_ANTIDOTE][HUDKEY_COLOR_B],
        giValues[KEYMSG_ANTIDOTE][HUDKEY_COORDS_X],
        giValues[KEYMSG_ANTIDOTE][HUDKEY_COORDS_Y],
        giValues[KEYMSG_ANTIDOTE][HUDKEY_EFFECT],
        0.1,
        giValues[KEYMSG_ANTIDOTE][HUDKEY_HOLD],
        giValues[KEYMSG_ANTIDOTE][HUDKEY_FADEIN],
        giValues[KEYMSG_ANTIDOTE][HUDKEY_FADEOUT]
    );
    show_dhudmessage(0, gszMessages[KEYMSG_ANTIDOTE], id);
}

public Plague_Zombified(id, attacker)
{
    
}

stock Game_MakeSky()
{
    set_cvar_string("sv_skyname", skyName);
    set_cvar_num("sv_skycolor_r", iSkyColor[0]);
    set_cvar_num("sv_skycolor_g", iSkyColor[1]);
    set_cvar_num("sv_skycolor_b", iSkyColor[2]);
}

stock CreateFog ( const index = 0, const red = 127, const green = 127, const blue = 127, const Float:density_f = 0.001, bool:clear = false )
{
    static msgFog;
    
    if ( msgFog || ( msgFog = get_user_msgid( "Fog" ) ) )
    {
        new density = _:floatclamp( density_f, 0.0001, 0.25 ) * _:!clear;
        
        message_begin( index ? MSG_ONE_UNRELIABLE : MSG_BROADCAST, msgFog, .player = index );
        write_byte( clamp( red  , 0, 255 ) );
        write_byte( clamp( green, 0, 255 ) );
        write_byte( clamp( blue , 0, 255 ) );
        write_long( _:density );
        message_end();
    }
}