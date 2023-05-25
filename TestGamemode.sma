#include <amxmodx>
#include <plague>

new iGamemode;
new PlagueClassId: ZombieClassId;

public plugin_init()
{
    ZombieClassId = pr_get_class_id(PClass_Zombie);
    iGamemode = pr_register_gamemode( "default", "Infection", Infection_InfectArmor );
}

public Plague_RoundStart2_Post()
{
    if ( pr_current_gamemode() != iGamemode )
        return;

    pr_init_choose_transform(1);
    pr_transform_chosen_players(ZombieClassId);
    pr_set_respawn_type(Respawn_Balanced);
}