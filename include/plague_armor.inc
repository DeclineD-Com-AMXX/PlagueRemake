#if defined _included_plague_armor_
    #endinput
#endif

#define _included_plague_armor_

#include <plague_armor_const>

native Float:pr_get_user_armor_protection(id);
native Float:pr_get_user_armor_damage(id);
native pr_set_user_armor_damage(id, Float:percent);
native pr_set_user_armor_protection(id, Float:percent);