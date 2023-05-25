#if defined _included_plague_classes_
    #endinput
#endif

#define _included_plague_classes_

#include <plague_classes_const>

native PlagueClassId: pr_register_class(const sysName[], TeamName:team);
native PlagueClassId: pr_get_class_id(const sysName[]);
native pr_get_class_system_name(PlagueClassId:class);
native PlagueClassId: pr_get_user_class(id);
native pr_change_class(id, attacker = -1, PlagueClassId:class = PClassId_None, bool:bSpawned = false, bool:call = true);

forward Plague_Change_Class(id, attacker, PlagueClassId:class, bool:bSpawned);
forward Plague_Change_Class_Post(id, attacker, PlagueClassId:class, bool:bSpawned);