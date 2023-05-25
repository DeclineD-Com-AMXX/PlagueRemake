#if defined _included_plague_human_const_
    #endinput
#endif

#define _included_plague_human_const_

enum HumanData {
    any: Human_SystemName = -1,
    any: Human_Name,
    any: Human_Model,
    any: Human_DeathSounds,
    any: Human_HurtSounds,
    any: Human_Health,
    any: Human_Armor,
    any: Human_Gravity,
    any: Human_Speed,
    any: Human_Painshock,
    any: Human_Flags,
    any: Human_MenuShow
}

enum InfectionType {
    Infection_No,
    Infection_Damage,
    Infection_DamageArmor,
    Infection_InfectArmor,
    Infection_Infect
}

stock const PClass_Human[] = "human";
