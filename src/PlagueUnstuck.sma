#include <amxmodx>
#include <fakemeta>
#include <reapi>

new const Float:fSize[][3] =
{
	{0.0, 0.0, 1.0}, {0.0, 0.0, -1.0}, {0.0, 1.0, 0.0}, {0.0, -1.0, 0.0}, {1.0, 0.0, 0.0}, {-1.0, 0.0, 0.0}, {-1.0, 1.0, 1.0}, {1.0, 1.0, 1.0}, {1.0, -1.0, 1.0}, {1.0, 1.0, -1.0}, {-1.0, -1.0, 1.0}, {1.0, -1.0, -1.0}, {-1.0, 1.0, -1.0}, {-1.0, -1.0, -1.0},
	{0.0, 0.0, 2.0}, {0.0, 0.0, -2.0}, {0.0, 2.0, 0.0}, {0.0, -2.0, 0.0}, {2.0, 0.0, 0.0}, {-2.0, 0.0, 0.0}, {-2.0, 2.0, 2.0}, {2.0, 2.0, 2.0}, {2.0, -2.0, 2.0}, {2.0, 2.0, -2.0}, {-2.0, -2.0, 2.0}, {2.0, -2.0, -2.0}, {-2.0, 2.0, -2.0}, {-2.0, -2.0, -2.0},
	{0.0, 0.0, 3.0}, {0.0, 0.0, -3.0}, {0.0, 3.0, 0.0}, {0.0, -3.0, 0.0}, {3.0, 0.0, 0.0}, {-3.0, 0.0, 0.0}, {-3.0, 3.0, 3.0}, {3.0, 3.0, 3.0}, {3.0, -3.0, 3.0}, {3.0, 3.0, -3.0}, {-3.0, -3.0, 3.0}, {3.0, -3.0, -3.0}, {-3.0, 3.0, -3.0}, {-3.0, -3.0, -3.0},
	{0.0, 0.0, 4.0}, {0.0, 0.0, -4.0}, {0.0, 4.0, 0.0}, {0.0, -4.0, 0.0}, {4.0, 0.0, 0.0}, {-4.0, 0.0, 0.0}, {-4.0, 4.0, 4.0}, {4.0, 4.0, 4.0}, {4.0, -4.0, 4.0}, {4.0, 4.0, -4.0}, {-4.0, -4.0, 4.0}, {4.0, -4.0, -4.0}, {-4.0, 4.0, -4.0}, {-4.0, -4.0, -4.0},
	{0.0, 0.0, 5.0}, {0.0, 0.0, -5.0}, {0.0, 5.0, 0.0}, {0.0, -5.0, 0.0}, {5.0, 0.0, 0.0}, {-5.0, 0.0, 0.0}, {-5.0, 5.0, 5.0}, {5.0, 5.0, 5.0}, {5.0, -5.0, 5.0}, {5.0, 5.0, -5.0}, {-5.0, -5.0, 5.0}, {5.0, -5.0, -5.0}, {-5.0, 5.0, -5.0}, {-5.0, -5.0, -5.0}
};

new Float:g_fLastCmdtime[MAX_PLAYERS + 1];
new cWait, Float:fUnstuckWait;

public plugin_natives()
{
    register_native("pr_unstuck_user", "Native_Unstuck", 1);
}

public plugin_init()
{
    register_plugin("[Plague] Unstuck", "v1.0", "DeclineD");

    register_dictionary("plague.txt");

    cWait = register_cvar("pr_unstuck_wait_time", "2.0");
    
    register_clcmd("say /unstuck", "cmdUnstuck");
    register_clcmd("say_team /unstuck", "cmdUnstuck");
}

public cmdUnstuck(id)
{
    unstuck(id);
    return PLUGIN_HANDLED;
}

public Native_Unstuck(id)
{
    if(!is_user_connected(id))
        return false;

    return unstuck(id);
}

// Credits to: NL)Ramon(NL
// Stock Remade by DeclineD
stock bool:unstuck(id)
{
    if(!is_user_alive(id))
    {
        client_print_color(id, 0, "^4[ZP] ^1%L", id, "UNSTUCK_NOT");
        return false;
    }

    if(get_entvar(id, var_movetype) == MOVETYPE_NOCLIP)
    {
        client_print_color(id, 0, "^4[ZP] ^1%L", id, "UNSTUCK_NOT");
        return false;
    }

    new Float:fElapsedCmdTime = get_gametime() - g_fLastCmdtime[id];
    fUnstuckWait = get_pcvar_float( cWait )
    
    if(fElapsedCmdTime < fUnstuckWait )
    {
        client_print_color(id, 0, "^4[ZP] ^1%L", id, "UNSTUCK_WAIT", fElapsedCmdTime);
        return false;
    }

    g_fLastCmdtime[id] = get_gametime();

    new Float:vecOrigin[3];
    new Hull;

    get_entvar(id, var_origin, vecOrigin);
    Hull = get_entvar(id, var_flags) & FL_DUCKING ? HULL_HEAD : HULL_HUMAN;

    if(!IsHullVacant(vecOrigin, Hull, id) && !(get_entvar(id, var_solid) & SOLID_NOT))
        return false;

    new Float:fVector[3], Float:fMins[3];
    new o;

    get_entvar(id, var_mins, fMins);
    fVector[2] = vecOrigin[2];
    for(o = 0; o < sizeof fSize; ++o)
    {
        fVector[0] = vecOrigin[0] - fMins[0] * fSize[o][0];
        fVector[1] = vecOrigin[1] - fMins[1] * fSize[o][1];
        fVector[2] = vecOrigin[2] - fMins[2] * fSize[o][2];
        if(IsHullVacant(fVector, Hull, id))
        {
            engfunc(EngFunc_SetOrigin, id, fVector);
            set_entvar(id, var_velocity, {0.0, 0.0, 0.0});
            break;
        }
    }

    client_print_color(id, 0, "^4[ZP] ^1%L", id, "UNSTUCK_WORKED");

    return true;
}

stock bool:IsHullVacant(Float:vecOrigin[3], iHullNumber, pSkipEnt = 0)
{
	new ptr;
	engfunc(EngFunc_TraceHull, vecOrigin, vecOrigin, 0, iHullNumber, pSkipEnt, ptr);
	return bool:(!get_tr2(ptr, TR_StartSolid) && !get_tr2(ptr, TR_AllSolid) && get_tr2(ptr, TR_InOpen))
}