#if defined _included_plague_zombie_const_
    #endinput
#endif

#define _included_plague_zombie_const_

enum ZombieData {
    any: Zombie_SystemName = -1,
    any: Zombie_Name,
    any: Zombie_Model,
    any: Zombie_ClawModel,
    any: Zombie_HurtSounds,
    any: Zombie_SpawnSounds,
    any: Zombie_DeathSounds,
     
    any: Zombie_Health,
    any: Zombie_Gravity,
    any: Zombie_Speed,
    any: Zombie_Knockback,
    any: Zombie_Painshock,
    any: Zombie_Flags,
    any: Zombie_MenuShow,
 
    any: Zombie_AttackDamage,
    any: Zombie_Attack2Damage,
    any: Zombie_AttackDelay, 
    any: Zombie_AttackDelay2,
    any: Zombie_Attack2Delay, 
    any: Zombie_Attack2Delay1,
    any: Zombie_AttackDelayMiss, 
    any: Zombie_AttackDelayMiss2,
    any: Zombie_Attack2DelayMiss, 
    any: Zombie_Attack2DelayMiss1,
    any: Zombie_AttackDistance,
    any: Zombie_Attack2Distance
};

stock const PClass_Zombie[] = "zombie";