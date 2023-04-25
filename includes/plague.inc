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

stock UTIL_CenterMessage( player = 0, const msg[ ], ... )
{
    new szMsg[ 192 ];
    vformat( szMsg, charsmax( szMsg ), msg, 3 );

    replace_all( szMsg, charsmax( szMsg ), "\n", "^r" );
    replace_all( szMsg, charsmax( szMsg ), "^n", "^r" );

    static msgTextMsg;
    if( !msgTextMsg ) msgTextMsg = get_user_msgid("TextMsg");

    message_begin( player ? MSG_ONE_UNRELIABLE : MSG_BROADCAST, msgTextMsg, _, player );
    write_byte( 4 );
    write_string( szMsg );
    message_end( );

    return 1;
}

stock UTIL_PlaySound( player = 0, const Sound[] )
{
    client_cmd(player, "spk ^"%s^"", Sound);
}