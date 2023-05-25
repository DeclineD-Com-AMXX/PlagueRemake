#include <amxmodx>
#include <plague>

new const Sounds[][] = {
    "girl/bhit_flesh-1.wav",
    "girl/bhit_flesh-2.wav",
    "girl/bhit_flesh-3.wav",
    "girl/die1.wav",
    "girl/die2.wav",
    "girl/die3.wav"
};

new const Sounds2[][] = {
    "hunter/pain_011.wav",
    "hunter/pain_021.wav",
    "hunter/die_02.wav",
    "hunter/infect_01.wav"
};

new const Model2[] = "toxhunter";
new const ClawModel[] = "models/v_begyH.mdl";

new const Model[] = "girlmodel";

public plugin_precache()
{
    new Array:death = Plague_PrepareArray( 64, Sounds[3], Sounds[4], Sounds[5] );
    new Array:pain = Plague_PrepareArray( 64, Sounds[0], Sounds[1], Sounds[2] );

    pr_register_human_race("girl", "Default", Model, 250, 85, 500, 500.0, 0.5, death, pain, MenuShow_Yes, 0);

    death = Plague_PrepareArray( 64, Sounds2[2] );
    pain = Plague_PrepareArray( 64, Sounds2[0], Sounds2[1] );
    new Array: infect = Plague_PrepareArray( 64, Sounds2[3] );

    pr_register_zombie_race("default", "Default", Model2, ClawModel, 500, 600, 450.0, 0.5, 0.5, death, infect, pain, 0, MenuShow_Yes);
}