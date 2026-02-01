-- civitas-duty-blips/client.lua
local Config = require 'config'

local Blips = {} -- [serverId] = blipId

local function clearBlips()
    for sid, b in pairs(Blips) do
        if DoesBlipExist(b) then RemoveBlip(b) end
        Blips[sid] = nil
    end
end

local function updateBlips(dutyList)
    -- dutyList: array of { source, characterId, orgId, role }
    local present = {}
    for _, entry in ipairs(dutyList or {}) do
        local sid = entry.source
        local role = entry.role
        if not sid then goto continue end
        if role ~= 'police' and role ~= 'fire' and role ~= 'ems' then goto continue end
        local sidNum = tonumber(sid)
        if not sidNum then goto continue end
        local ped = GetPlayerPed(GetPlayerFromServerId(sidNum))
        if ped and ped ~= 0 then
            local existing = Blips[sid]
            if not existing then
                local blip = AddBlipForEntity(ped)
                SetBlipAsFriendly(blip, true)
                SetBlipSprite(blip, 1)
                SetBlipColour(blip, Config.blip_colors[role] or 3)
                BeginTextCommandSetBlipName('STRING')
                AddTextComponentString(Config.blip_names[role] or 'On Duty')
                EndTextCommandSetBlipName(blip)
                Blips[sid] = blip
            else
                -- update colour in case
                SetBlipColour(existing, Config.blip_colors[role] or 3)
            end
            present[sid] = true
        end
        ::continue::
    end
    -- remove blips not present
    for sid, blip in pairs(Blips) do
        if not present[sid] then
            if DoesBlipExist(blip) then RemoveBlip(blip) end
            Blips[sid] = nil
        end
    end
end

RegisterNetEvent('civitas:dutyBlips:update', function(dutyList)
    updateBlips(dutyList)
end)

RegisterNetEvent('civitas:dutyBlips:clear', function()
    clearBlips()
end)

AddEventHandler('onClientResourceStart', function(resName)
    if resName == GetCurrentResourceName() then
        TriggerServerEvent('civitas:dutyBlips:request')
    end
end)

-- Also request on player spawn (useful when respawning)
AddEventHandler('playerSpawned', function()
    TriggerServerEvent('civitas:dutyBlips:request')
end)
