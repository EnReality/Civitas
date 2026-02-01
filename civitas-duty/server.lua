-- civitas-duty/server.lua
local Config = require 'config'

local DutyState = {} -- [characterId] = { [orgId] = true }

local function ensureCharEntry(characterId)
    if not DutyState[characterId] then DutyState[characterId] = {} end
    return DutyState[characterId]
end

local function getRoleForOrg(org)
    if not org then return 'other' end
    local name = (org.name or ''):lower()
    local tag = (org.tag or ''):lower()
    local metadata_str = ''
    if org.metadata then
        if type(org.metadata) == 'table' then
            for k,v in pairs(org.metadata) do metadata_str = metadata_str .. tostring(k) .. tostring(v) end
        else
            metadata_str = tostring(org.metadata)
        end
    end
    -- Prefer tag first, then name, then metadata for role detection
    for role, patterns in pairs(Config.role_rules) do
        for _, pat in ipairs(patterns) do
            if pat ~= '' and string.match(tag, pat) then return role end
        end
    end
    for role, patterns in pairs(Config.role_rules) do
        for _, pat in ipairs(patterns) do
            if pat ~= '' and string.match(name, pat) then return role end
        end
    end
    for role, patterns in pairs(Config.role_rules) do
        for _, pat in ipairs(patterns) do
            if pat ~= '' and string.match(metadata_str, pat) then return role end
        end
    end
    return 'other'
end

local function isGovOrg(orgId)
    if not exports['civitas-organizations'] then return false end
    local org = exports['civitas-organizations']:GetOrganization(orgId)
    if not org then return false end
    return org.organization_type == 'government'
end

local function checkPermissionGate(characterId, orgId)
    local orgs = exports['civitas-organizations']
    local perm = Config.permission_code
    if orgs and orgs.IsPermissionRegistered then
        local registered = pcall(function() return orgs.IsPermissionRegistered(perm) end)
        if registered then
            local ok, has = pcall(function() return orgs.HasPermissionInOrg(characterId, orgId, perm) end)
            if ok and has then
                return true, nil
            else
                return false, 'no_permission'
            end
        else
            -- permission not registered
            return true, 'permission_not_registered_allowed'
        end
    else
        -- cannot detect registration; soft allow
        return true, 'permission_not_registered_allowed'
    end
end

-- SetDuty(characterId, orgId, on) -> { ok, reason, on }
function SetDuty(characterId, orgId, on)
    if not characterId or not orgId then return { ok = false, reason = 'invalid_args', on = false } end
    if not isGovOrg(orgId) then return { ok = false, reason = 'not_government', on = false } end

    local allowed, reason = checkPermissionGate(characterId, orgId)
    if not allowed then return { ok = false, reason = reason or 'no_permission', on = false } end

    local entry = ensureCharEntry(characterId)
    entry[orgId] = not not on

    -- resolve source for character if available
    local src = nil
    if exports['civitas-core'] and exports['civitas-core'].GetSourceFromCharacterId then
        src = exports['civitas-core']:GetSourceFromCharacterId(characterId)
    end

    local org = nil
    if exports['civitas-organizations'] then org = exports['civitas-organizations']:GetOrganization(orgId) end
    local role = getRoleForOrg(org)

    -- events
    local action = on and 'duty_on' or 'duty_off'
    local payload = { actor = src or characterId, action = action, details = { characterId = characterId, orgId = orgId, role = role, reason = reason }, timestamp = os.time() }
    if TriggerEvent then pcall(TriggerEvent, 'civitas:transaction', payload) end
    if TriggerEvent then pcall(TriggerEvent, 'civitas:dutyChanged', { source = src, characterId = characterId, orgId = orgId, on = on, role = role }) end

    return { ok = true, reason = reason, on = entry[orgId] }
end

-- ToggleDuty(characterId, orgId)
function ToggleDuty(characterId, orgId)
    if not characterId or not orgId then return { ok = false, reason = 'invalid_args', on = false } end
    local entry = ensureCharEntry(characterId)
    local newOn = not entry[orgId]
    return SetDuty(characterId, orgId, newOn)
end

function IsOnDuty(characterId, orgId)
    if not characterId or not orgId then return false end
    local entry = DutyState[characterId]
    return entry and entry[orgId] or false
end

function GetDutyOrgs(characterId)
    local res = {}
    local entry = DutyState[characterId]
    if not entry then return res end
    for orgId, on in pairs(entry) do if on then table.insert(res, orgId) end end
    return res
end

function GetAllOnDuty()
    local out = {}
    for characterId, tbl in pairs(DutyState) do
        for orgId, on in pairs(tbl) do
            if on then
                local src = nil
                if exports['civitas-core'] and exports['civitas-core'].GetSourceFromCharacterId then
                    src = exports['civitas-core']:GetSourceFromCharacterId(characterId)
                end
                local org = nil
                if exports['civitas-organizations'] then org = exports['civitas-organizations']:GetOrganization(orgId) end
                local role = getRoleForOrg(org)
                table.insert(out, { source = src, characterId = characterId, orgId = orgId, role = role })
            end
        end
    end
    return out
end

-- Exports
exports('SetDuty', SetDuty)
exports('ToggleDuty', ToggleDuty)
exports('IsOnDuty', IsOnDuty)
exports('GetDutyOrgs', GetDutyOrgs)
exports('GetAllOnDuty', GetAllOnDuty)

-- Command: /duty [orgId]
RegisterCommand('duty', function(source, args, raw)
    local src = source
    local charId = nil
    if exports['civitas-core'] then charId = exports['civitas-core']:GetCharacterId(src) end
    if not charId then
        pcall(function() TriggerClientEvent('chat:addMessage', src, { args = { '^1CIVITAS', 'No character loaded.' } }) end)
        return
    end

    local targetOrg = nil
    if args and args[1] then
        targetOrg = tonumber(args[1])
        if not targetOrg then
            pcall(function() TriggerClientEvent('chat:addMessage', src, { args = { '^1CIVITAS', 'Invalid orgId.' } }) end)
            return
        end
        if not isGovOrg(targetOrg) then
            pcall(function() TriggerClientEvent('chat:addMessage', src, { args = { '^1CIVITAS', 'Org is not government.' } }) end)
            return
        end
    else
        -- choose first membership where org type is government
        if not exports['civitas-organizations'] then
            pcall(function() TriggerClientEvent('chat:addMessage', src, { args = { '^1CIVITAS', 'Organization service unavailable.' } }) end)
            return
        end
        local memberships = exports['civitas-organizations']:GetOrganizations(charId) or {}
        for _, m in ipairs(memberships) do
            local org = exports['civitas-organizations']:GetOrganization(m.orgId)
            if org and org.organization_type == 'government' then targetOrg = m.orgId break end
        end
        if not targetOrg then
            pcall(function() TriggerClientEvent('chat:addMessage', src, { args = { '^1CIVITAS', 'No government organization found for your character.' } }) end)
            return
        end
    end

    local res = ToggleDuty(charId, targetOrg)
    if res.ok then
        local msg = res.on and ('Now on duty for org ' .. tostring(targetOrg)) or ('Now off duty for org ' .. tostring(targetOrg))
        pcall(function() TriggerClientEvent('chat:addMessage', src, { args = { '^2CIVITAS', msg } }) end)
    else
        pcall(function() TriggerClientEvent('chat:addMessage', src, { args = { '^1CIVITAS', 'Duty toggle failed: ' .. tostring(res.reason) } }) end)
    end
end, false)

-- Cleanup on playerDropped: clear duty entries and emit off
AddEventHandler('playerDropped', function(reason)
    local src = source
    local charId = nil
    if exports['civitas-core'] then charId = exports['civitas-core']:GetCharacterId(src) end
    if not charId then return end
    local entry = DutyState[charId]
    if not entry then return end
    for orgId, on in pairs(entry) do
        if on then
            -- turn off and emit
            entry[orgId] = false
            local org = nil
            if exports['civitas-organizations'] then org = exports['civitas-organizations']:GetOrganization(orgId) end
            local role = getRoleForOrg(org)
            if TriggerEvent then pcall(TriggerEvent, 'civitas:transaction', { actor = src, action = 'duty_off', details = { characterId = charId, orgId = orgId, role = role }, timestamp = os.time() }) end
            if TriggerEvent then pcall(TriggerEvent, 'civitas:dutyChanged', { source = src, characterId = charId, orgId = orgId, on = false, role = role }) end
        end
    end
    DutyState[charId] = nil
end)
