#if defined _included_plague_settings_
    #endinput
#endif

#define _included_plague_settings_

#include <json>

native JSON:pr_open_settings(const szFilePath[]);
native pr_close_settings(const szFilePath[]);

stock JSON:json_object_get_value_safe(const JSON:object, const key[], const _default[], JSONType:type, &any:x)
{
    new JSON:temp2 = json_object_get_value(object, key);
    new JSONType:type2 = JSONError;

    if(temp2 != Invalid_JSON)
        type2 = json_get_type(temp2);

    if(type2 != type)
    {
        json_free(temp2);

        switch(type)
        {
            case JSONNumber: temp2 = json_init_real(contain(_default, ".") != -1 ? str_to_float(_default) : float(str_to_num(_default)));
            case JSONBoolean: temp2 = json_init_bool(bool:str_to_num(_default));
            case JSONNull: temp2 = json_init_null();
            default: temp2 = Invalid_JSON;
        }

        json_object_set_value( object, key, temp2 );

        return temp2;
    }
    
    switch(type)
    {
        case JSONNumber: {
            if(contain(_default, ".") != -1)
                x = json_get_real(temp2);
            else
                x = json_get_number(temp2);
        }
        case JSONBoolean: x = json_get_bool(temp2);
        case JSONNull: x = 0;
        default: x = 0;
    }

    return temp2;
}

stock JSON:json_object_get_value_at_safe(const JSON:object, id, const _default[], JSONType:type, &any:x)
{
    new key[128]; json_object_get_name(object, id, key, charsmax(key));
    return json_object_get_value_safe(object, key, _default, type, x);
}

stock JSON:json_object_get_object_at_safe(const JSON:object, id)
{
    new key[128]; json_object_get_name(object, id, key, charsmax(key));
    return json_object_get_object_safe(object, key);
}

stock JSON:json_object_get_array_at_safe(const JSON:object, id)
{
    new key[128]; json_object_get_name(object, id, key, charsmax(key));
    return json_object_get_array_safe(object, key);
}

stock JSON:json_object_get_string_at_safe(const JSON:object, id, const _default[], x[], size)
{
    new key[128]; json_object_get_name(object, id, key, charsmax(key));
    return json_object_get_string_safe(object, key, _default, x, size);
}

stock JSON:json_object_get_object_safe(const JSON:object, const key[])
{
    new JSON:obj = json_object_get_value(object, key);
    if(!json_is_object(obj))
    {
        json_object_remove(object, key);
        obj = json_init_object();
        json_object_set_value(object, key, obj);
    }

    return obj;
}

stock JSON:json_object_get_array_safe(const JSON:object, const key[])
{
    new JSON:obj = json_object_get_value(object, key);
    if(!json_is_array(obj))
    {
        json_object_remove(object, key);
        obj = json_init_array();
        json_object_set_value(object, key, obj);
    }

    return obj;
}

stock JSON:json_object_get_string_safe(const JSON:object, const key[], const _default[], x[], size)
{
    new JSON:obj = json_object_get_value(object, key);
    if(!json_is_string(obj))
    {
        json_object_remove(object, key);
        obj = json_init_string(_default);
        json_object_set_value(object, key, obj);
    }

    json_get_string(obj, x, size);

    return obj;
}