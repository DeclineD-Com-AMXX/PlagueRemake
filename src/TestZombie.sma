#include <amxmodx>
#include <plague>

new const Sounds[][] = {
    "hunter/pain_011.wav",
    "hunter/pain_021.wav",
    "hunter/die_02.wav",
    "hunter/infect_01.wav"
};

new const Model[] = "toxhunter";
new const ClawModel[] = "models/v_begyH.mdl";

static class[2];

public plugin_precache()
{
    new Array:a[3];
    a[0] = Plague_PrepareArray(128, Sounds[0], Sounds[1]);
    a[1] = Plague_PrepareArray(128, Sounds[3]);
    a[2] = Plague_PrepareArray(128, Sounds[2]);

    class[0] = pr_register_zombie("default", "Default", Model, ClawModel, a[0], a[1], a[2]);
    class[1] = pr_register_zombie("default2", "Default2", Model, ClawModel, a[0], a[1], a[2]);

    pr_zombie_attributes(class[0], 500, 25.0, 800, 0.5, 0.75, 0);
    pr_zombie_attributes(class[1], 800, 50.0, 600, 0.5, 0.45, 0);

    pr_set_zombie_race_attribute(class[1], Zombie_AttackDelay, 0.01);
    pr_set_zombie_race_attribute(class[1], Zombie_AttackDelay2, 0.02);
    pr_set_zombie_race_attribute(class[1], Zombie_Attack2Delay, 0.015);
    pr_set_zombie_race_attribute(class[1], Zombie_Attack2Delay1, 0.02);
    
    pr_set_zombie_race_attribute(class[1], Zombie_AttackDelayMiss, 0.02);
    pr_set_zombie_race_attribute(class[1], Zombie_AttackDelayMiss2, 0.02);
    pr_set_zombie_race_attribute(class[1], Zombie_Attack2DelayMiss, 0.035);
    pr_set_zombie_race_attribute(class[1], Zombie_Attack2DelayMiss1, 0.035);
}