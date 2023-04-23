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
    a[0] = PrepareSoundArray(Sounds[0], Sounds[1]);
    a[1] = PrepareSoundArray(Sounds[3]);
    a[2] = PrepareSoundArray(Sounds[2]);

    class[0] = pr_register_zombie("default", "Default", Model, ClawModel, a[0], a[1], a[2]);
    class[1] = pr_register_zombie("default2", "Default2", Model, ClawModel, a[0], a[1], a[2]);

    pr_zombie_attributes(class[0], 500, 25.0, 800, 0.5, 0.75, 0);
    pr_zombie_attributes(class[1], 800, 50.0, 600, 0.5, 0.45, 0);
}