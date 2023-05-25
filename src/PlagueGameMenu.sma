#include <amxmodx>
#include <reapi>
#include <plague_classes>
#include <plague_human_const>
#include <plague_zombie_const>

new const szMenuLang[][] = {
    "MENU_TITLE",
    "MENU_WEAPONS",
    "MENU_ZM",
    "MENU_HM",
    "MENU_UNSTUCK"
}

public plugin_init()
{
    register_dictionary("plague.txt");
}