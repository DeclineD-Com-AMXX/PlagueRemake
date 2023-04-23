#include <plague_const>

#include <plague_human>
#include <plague_zombie>

stock Array: PrepareSoundArray(...)
{
    if(!numargs())
        return Invalid_Array;
    
    new string[MAX_RESOURCE_PATH_LENGTH], ch, pos, len = charsmax(string);
    new Array: a = ArrayCreate(MAX_RESOURCE_PATH_LENGTH, 1);

    for(new i = 0; i < numargs(); i++)
    {
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