-- civitas-admin/org_admin.lua
-- Organization administration helpers (placeholders)
local Config = require 'civitas-admin.config'
local Audit = require 'civitas-admin.audit'

local OrgAdmin = {}

local function getIdentifiers(src)
    if not src or src == 0 then return {} end
    local ids = GetPlayerIdentifiers(src) or {}
    return ids
end

local function isAdmin(src)
    if src == 0 then return true end -- console
    local ids = getIdentifiers(src)
    for _, id in ipairs(ids) do
        for _, allow in ipairs(Config.admins or {}) do
            if id == allow then return true end
        end
    end
    return false
end

local function recordTransaction(actor, action, details)
    local payload = { actor = actor, action = action, details = details, timestamp = os.time() }
    if Audit and Audit.log then
        pcall(Audit.log, payload)
    end
    if TriggerEvent then pcall(TriggerEvent, 'civitas:transaction', payload) end
end

-- Helper to send simple feedback to caller (server-side print only)
local function feedback(src, msg)
    if src == 0 then
        print(('[civitas-admin] %s'):format(msg))
    else
        -- server print
        print(('[civitas-admin] [src=%s] %s'):format(tostring(src), msg))
        -- client chat feedback for admin usability (non-UI, chat message)
        pcall(function()
            TriggerClientEvent('chat:addMessage', src, { args = { '^2CIVITAS', msg } })
        end)
    end
end

-- Create organization: /civitas_org_create <type> <name>
RegisterCommand('civitas_org_create', function(source, args, raw)
    if not isAdmin(source) then feedback(source, 'permission_denied'); return end
    local orgType = args[1]
    local name = table.concat(args, ' ', 2)
    if not orgType or name == '' then feedback(source, 'usage: /civitas_org_create <type> <name>'); return end
    local ok, org = pcall(function()
        if exports['civitas-organizations'] and exports['civitas-organizations'].CreateOrganization then
            return exports['civitas-organizations'].CreateOrganization(orgType, name)
        end
        return nil
    end)
    recordTransaction(source, 'civitas_org_create', { type = orgType, name = name, result = ok and org or nil })
    feedback(source, ok and ('organization_created id=' .. tostring(org and org.id)) or 'organization_create_failed')
end, false)

-- Create rank: /civitas_rank_create <orgId> <level> <name>
RegisterCommand('civitas_rank_create', function(source, args, raw)
    if not isAdmin(source) then feedback(source, 'permission_denied'); return end
    local orgId = tonumber(args[1])
    local level = tonumber(args[2])
    local name = table.concat(args, ' ', 3)
    if not orgId or not level or name == '' then feedback(source, 'usage: /civitas_rank_create <orgId> <level> <name>'); return end
    local ok, rank = pcall(function()
        if exports['civitas-organizations'] and exports['civitas-organizations'].CreateRank then
            return exports['civitas-organizations'].CreateRank(orgId, { name = name, level = level })
        end
        return nil
    end)
    recordTransaction(source, 'civitas_rank_create', { orgId = orgId, level = level, name = name, result = ok and rank or nil })
    feedback(source, ok and ('rank_created id=' .. tostring(rank and rank.id)) or 'rank_create_failed')
end, false)

-- Add member: /civitas_member_add <orgId> <characterId> <rankId>
RegisterCommand('civitas_member_add', function(source, args, raw)
    if not isAdmin(source) then feedback(source, 'permission_denied'); return end
    local orgId = tonumber(args[1])
    local characterId = tonumber(args[2])
    local rankId = tonumber(args[3])
    if not orgId or not characterId or not rankId then feedback(source, 'usage: /civitas_member_add <orgId> <characterId> <rankId>'); return end
    local ok, res = pcall(function()
        if exports['civitas-organizations'] and exports['civitas-organizations'].AddMember then
            return exports['civitas-organizations'].AddMember(orgId, characterId, rankId)
        end
        return nil
    end)
    recordTransaction(source, 'civitas_member_add', { orgId = orgId, characterId = characterId, rankId = rankId, result = ok and res or nil })
    feedback(source, ok and 'member_added' or 'member_add_failed')
end, false)

-- Remove member: /civitas_member_remove <orgId> <characterId>
RegisterCommand('civitas_member_remove', function(source, args, raw)
    if not isAdmin(source) then feedback(source, 'permission_denied'); return end
    local orgId = tonumber(args[1])
    local characterId = tonumber(args[2])
    if not orgId or not characterId then feedback(source, 'usage: /civitas_member_remove <orgId> <characterId>'); return end
    local ok, res = pcall(function()
        if exports['civitas-organizations'] and exports['civitas-organizations'].RemoveMember then
            return exports['civitas-organizations'].RemoveMember(orgId, characterId)
        end
        return nil
    end)
    recordTransaction(source, 'civitas_member_remove', { orgId = orgId, characterId = characterId, result = ok and res or nil })
    feedback(source, ok and 'member_removed' or 'member_remove_failed')
end, false)

-- Register permission: /civitas_perm_add <permCode>
RegisterCommand('civitas_perm_add', function(source, args, raw)
    if not isAdmin(source) then feedback(source, 'permission_denied'); return end
    local code = args[1]
    if not code then feedback(source, 'usage: /civitas_perm_add <permCode>'); return end
    local ok, res = pcall(function()
        if exports['civitas-organizations'] and exports['civitas-organizations'].RegisterPermission then
            return exports['civitas-organizations'].RegisterPermission(code)
        end
        return nil
    end)
    recordTransaction(source, 'civitas_perm_add', { perm = code, result = ok and res or nil })
    feedback(source, ok and 'permission_registered' or 'permission_register_failed')
end, false)

-- Grant or deny permission to rank: /civitas_rank_perm <rankId> <permCode> <grant|deny>
RegisterCommand('civitas_rank_perm', function(source, args, raw)
    if not isAdmin(source) then feedback(source, 'permission_denied'); return end
    local rankId = tonumber(args[1])
    local perm = args[2]
    local mode = args[3]
    if not rankId or not perm or not mode then feedback(source, 'usage: /civitas_rank_perm <rankId> <permCode> <grant|deny>'); return end
    local grant = (mode == 'grant') and true or false
    if mode ~= 'grant' and mode ~= 'deny' then
        feedback(source, 'usage: /civitas_rank_perm <rankId> <permCode> <grant|deny>')
        return
    end
    local grant = (mode == 'grant') and true or false
    local ok, res = pcall(function()
        if exports['civitas-organizations'] and exports['civitas-organizations'].GrantPermissionToRank then
            return exports['civitas-organizations'].GrantPermissionToRank(rankId, perm, grant)
        end
        return nil
    end)
    recordTransaction(source, 'civitas_rank_perm', { rankId = rankId, permission = perm, grant = grant, result = ok and res or nil })
    feedback(source, ok and 'rank_permission_updated' or 'rank_permission_failed')
end, false)

return OrgAdmin
