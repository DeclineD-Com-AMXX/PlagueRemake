#if defined _included_plague_const
    #endinput
#endif

#define _included_plague_const

enum PlagueAction
{
    Plague_Continue = 89,
    Plague_Handled,
    Plague_Stop
}

enum MenuShow {
    MenuShow_No,
    MenuShow_Flag,
    MenuShow_Yes,
    MenuShow_Custom
}