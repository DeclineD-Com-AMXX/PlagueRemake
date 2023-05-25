#if defined _included_plague_
    #endinput
#endif

#define _included_plague_

#include <plague_const>
#include <plague_rounds>
#include <plague_classes>
#include <plague_zombie>
#include <plague_human>
#include <plague_armor>
#include <plague_gamemode>
#include <plague_spawn>
#include <plague_settings>
#include <plague_unstuck>

stock Array: Plague_PrepareArray(const size, ...)
{
    if(!numargs())
        return Invalid_Array;
    
    new string[2048], ch, pos, len = size;
    new Array: a = ArrayCreate(size, 1);

    for(new i = 1; i < numargs(); i++)
    {
        copy(string, charsmax(string), "");
        pos = 0;

        while((pos < len) && (ch = getarg(i, pos)))
        {
            string[pos] = ch;
            pos++;
        }

        string[pos] = '^0';

        ArrayPushString(a, string);
    }

    return a;
}