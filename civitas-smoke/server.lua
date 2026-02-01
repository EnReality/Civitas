-- civitas-smoke/server.lua

print('CIVITAS smoke ready')

RegisterCommand('civitas_smoke', function(source, args, raw)
    local src = source
    -- call civitas-core exports
    local identifier = nil
    local charId = nil
    local loaded = nil
    -- Wrap calls in pcall in case exports are missing
    pcall(function()
        identifier = exports['civitas-core'] and exports['civitas-core']:GetIdentifier(src) or nil
    end)
    pcall(function()
        charId = exports['civitas-core'] and exports['civitas-core']:GetCharacterId(src) or nil
    end)
    pcall(function()
        loaded = exports['civitas-core'] and exports['civitas-core']:IsCharacterLoaded(src) or false
    end)

    local msg = ('[civitas-smoke] source=%s identifier=%s characterId=%s loaded=%s'):format(tostring(src), tostring(identifier), tostring(charId), tostring(loaded))
    print(msg)
    pcall(function() TriggerClientEvent('chat:addMessage', src, { args = { '^2CIVITAS-SMOKE', msg } }) end)
end, false)
