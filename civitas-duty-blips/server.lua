-- civitas-duty-blips/server.lua
local OnDutyBySource = {} -- [source] = { characterId, orgId, role }

local function isViewerEligible(src)
    if not exports['civitas-core'] or not exports['civitas-organizations'] then return false end
    local cid = exports['civitas-core']:GetCharacterId(src)
    if not cid then return false end
    local memberships = exports['civitas-organizations']:GetOrganizations(cid) or {}
    for _, m in ipairs(memberships) do
        local org = exports['civitas-organizations']:GetOrganization(m.orgId)
        if org and org.organization_type == 'government' then return true end
    end
    return false
end

local function buildDutyList()
    local list = {}
    for src, info in pairs(OnDutyBySource) do
        table.insert(list, { source = src, characterId = info.characterId, orgId = info.orgId, role = info.role })
    end
    return list
end

-- update and broadcast to eligible viewers
local function broadcastUpdates()
    local dutyList = buildDutyList()
    -- broadcast to each connected player who is eligible
    for _, playerId in ipairs(GetPlayers()) do
        local num = tonumber(playerId)
        if num and isViewerEligible(num) then
            TriggerClientEvent('civitas:dutyBlips:update', num, dutyList)
        else
            TriggerClientEvent('civitas:dutyBlips:clear', num)
        end
    end
end

-- listen for duty changes
AddEventHandler('civitas:dutyChanged', function(payload)
    if not payload then return end
    local src = payload.source
    local characterId = payload.characterId
    local orgId = payload.orgId
    local on = payload.on
    local role = payload.role
    if not src then
        -- try to resolve source
        if exports['civitas-core'] then src = exports['civitas-core']:GetSourceFromCharacterId(characterId) end
    end
    if on then
        OnDutyBySource[src] = { characterId = characterId, orgId = orgId, role = role }
    else
        OnDutyBySource[src] = nil
    end
    broadcastUpdates()
end)

-- handle request from client
RegisterNetEvent('civitas:dutyBlips:request', function()
    local src = source
    if isViewerEligible(src) then
        local dutyList = buildDutyList()
        TriggerClientEvent('civitas:dutyBlips:update', src, dutyList)
    else
        TriggerClientEvent('civitas:dutyBlips:clear', src)
    end
end)

-- on player dropped
AddEventHandler('playerDropped', function(reason)
    local src = source
    OnDutyBySource[src] = nil
    broadcastUpdates()
end)
