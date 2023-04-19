enum PlagueClass {
    PlagueClass_None = -1,
    PlagueClass_Human,
    PlagueClass_Zombie
};

enum HumanAttributes {
    Human_Health,
    Human_Gravity,
    Human_SpeedAdd,
    Human_ArmorResistance,
    Human_ArmorDamage,
    Human_Painshock,
    Human_Flags,
    Human_Selectable
};

enum HumanInformation {
    Human_SystemName,
    Human_Name,
    Human_Model,
    Human_SoundsPain,
    Human_SoundsIdle,
    Human_SoundsDie
};

enum ZombieAttributes {
    Zombie_Health,
    Zombie_Gravity,
    Zombie_SpeedAdd,
    Zombie_KnockbackResistance,
    Zombie_Painshock,
    Zombie_ArmorPenetration,
    Zombie_Flags,
    Zombie_Selectable,
    Zombie_AttackDamage,
    Zombie_Attack2Damage,
    Zombie_AttackDelay, 
    Zombie_AttackDelay2,
    Zombie_Attack2Delay, 
    Zombie_Attack2Delay1,
    Zombie_AttackDelayMiss, 
    Zombie_AttackDelayMiss2,
    Zombie_Attack2DelayMiss, 
    Zombie_Attack2DelayMiss1,
    Zombie_AttackDistance,
    Zombie_Attack2Distance
};

enum ZombieInformation
{
    Zombie_SystemName,
    Zombie_Name,
    Zombie_Model,
    Zombie_ClawModel,
    Zombie_SoundsPain,
    Zombie_SoundsIdle,
    Zombie_SoundsDie
};

enum InfectionType {
    InfectionType_None,
    InfectionType_Kill,
    InfectionType_KillArmor,
    InfectionType_InfectArmor,
    InfectionType_Infect
}

enum SpawnType {
    Spawn_None,
    Spawn_Zombie,
    Spawn_Human,
    Spawn_Balanced,
    Spawn_Random
}

new const PlagueGame_iInfectionType[] = "iInfectionType";
new const PlagueGame_iFirstCount[] = "iFirstCount";
new const PlagueGame_iFirstArray[] = "iFirstArray"; // MAX_PLAYERS
new const PlagueGame_iSpawnType[] = "iSpawnType";
new const PlagueGame_flRespawnTime[] = "flRespawnTime";

#define MAX_SYSNAME_LENGHT 20