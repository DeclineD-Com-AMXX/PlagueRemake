#include <plague_const>

#include <plague_human>
#include <plague_zombie>
#include <plague_rounds>

stock Array: Plague_PrepareArray(const size, ...)
{
    if(!numargs())
        return Invalid_Array;
    
    new string[2048], ch, pos, len = charsmax(string);
    new Array: a = ArrayCreate(size, 1);

    for(new i = 1; i < numargs(); i++)
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

stock UTIL_CenterMessage( player = 0, const msg[ ], any:... )
{
    new szMsg[ 192 ];
    vformat( szMsg, charsmax( szMsg ), msg, 3 );

    replace_all( szMsg, charsmax( szMsg ), "\n", "^r" );
    replace_all( szMsg, charsmax( szMsg ), "^n", "^r" );

    static msgTextMsg;
    if( !msgTextMsg ) msgTextMsg = get_user_msgid("TextMsg");

    message_begin( player ? MSG_ONE_UNRELIABLE : MSG_ALL, msgTextMsg, _, player );
    write_byte( 4 );
    write_string( szMsg );
    message_end( );

    return 1;
}

stock UTIL_PlaySound( player = 0, const Sound[] )
{
    client_cmd(player, "spk ^"%s^"", Sound);
}