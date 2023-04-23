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

new const Model[] = "girlmodel";

static class[2];

public plugin_precache()
{
    new Array:a[2];
    a[0] = PrepareSoundArray(Sounds[0], Sounds[1], Sounds[2]);
    a[1] = PrepareSoundArray(Sounds[3], Sounds[4], Sounds[5]);

    class[0] = pr_register_human("default", "Default", Model, a[0], a[1]);
    class[1] = pr_register_human("default2", "Default2", Model, a[0], a[1]);

    pr_human_attributes(class[0], 500, 25.0, 800, 0.5, 0);
    pr_human_attributes(class[1], 800, 50.0, 600, 0.5, 0);
}