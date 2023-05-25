#include <amxmodx>
#include <json>

enum _:FileData {
    JSON:handler,
    openCount
}

new fileCount;

new Trie:tFile, Array:aFileData;

public plugin_precache()
{
    tFile = TrieCreate();
    aFileData = ArrayCreate(FileData, 1);
}

public plugin_natives()
{
    register_native("pr_open_settings", "Native_Open");
    register_native("pr_close_settings", "Native_Close");
}

public plugin_end()
{
    new Data[FileData];

    new TrieIter:iter = TrieIterCreate(tFile);
    new szFile[128];
    new id;
    while(!TrieIterEnded(iter))
    {
        TrieIterGetCell(iter, id);
        TrieIterGetKey(iter, szFile, charsmax(szFile));
        ArrayGetArray(aFileData, id, Data);

        if(Data[handler] != Invalid_JSON)
        {
            json_serial_to_file(Data[handler], szFile, true);
            json_free(Data[handler]);
        }

        TrieIterNext(iter);
    }

    TrieIterDestroy(iter)
    TrieDestroy(tFile);
    ArrayDestroy(aFileData);
}

public JSON:Native_Open(plgId, params)
{
    if(params < 1)
    {
        log_error(AMX_ERR_NATIVE, "Not enough params to execute.");
        return Invalid_JSON;
    }

    new szFile[128]; get_string(1, szFile, charsmax(szFile));

    if(strlen(szFile) < 1)
    {
        log_error(AMX_ERR_NATIVE, "Cannot open with empty name.");
        return Invalid_JSON;
    }

    new Data[FileData], id;
    if(!TrieKeyExists(tFile, szFile))
    {
        Data[handler] = Invalid_JSON;

        ArrayPushArray(aFileData, Data);

        id = fileCount;
        fileCount++;

        TrieSetCell(tFile, szFile, id);
    }
    else {
        TrieGetCell(tFile, szFile, id);
        ArrayGetArray(aFileData, id, Data);
    }

    if(Data[handler] == Invalid_JSON)
    {
        Data[handler] = json_parse(szFile, true, true);

        if(Data[handler] == Invalid_JSON)
            Data[handler] = json_init_object();
    }

    Data[openCount]++;
    ArraySetArray(aFileData, id, Data);
    return Data[handler];
}

public Native_Close(plgId, params)
{
    if(params < 1)
    {
        log_error(AMX_ERR_NATIVE, "Not enough params to execute.");
        return;
    }

    new szFile[128]; get_string(1, szFile, charsmax(szFile));

    if(strlen(szFile) < 1)
    {
        log_error(AMX_ERR_NATIVE, "Cannot open with empty name.");
        return;
    }

    if(!TrieKeyExists(tFile, szFile))
    {
        return;
    }

    new Data[FileData], id;
    TrieGetCell(tFile, szFile, id);
    ArrayGetArray(aFileData, id, Data);

    Data[openCount]--;

    if(Data[openCount] == 0)
    {
        json_serial_to_file(Data[handler], szFile, true);
        json_free(Data[handler]);
    }

    ArraySetArray(aFileData, id, Data);
    return;
}

public plugin_init() register_plugin("[Plague] Settings FIle Management", "Final", "DeclineD");