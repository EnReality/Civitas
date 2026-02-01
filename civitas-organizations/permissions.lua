-- civitas-organizations/permissions.lua
-- Permission resolution (rank -> permissions). Supports grant/deny
-- semantics. Deny overrides allow. Also provides a small permission
-- catalog for admin convenience.

local Members = require 'members'
local Ranks = require 'ranks'

local Permissions = {
    -- permissions_by_rank[rankId] = { [permissionCode] = 1|-1 }
    permissions_by_rank = {},
    -- catalog of known permission codes
    catalog = {}
}

function Permissions.registerPermission(code)
    Permissions.catalog[code] = true
    return true
end

-- grant: true = allow, false = deny
function Permissions.grant(rankId, permissionCode, grant)
    grant = (grant == nil) and true or (grant and 1 or -1)
    Permissions.permissions_by_rank[rankId] = Permissions.permissions_by_rank[rankId] or {}
    Permissions.permissions_by_rank[rankId][permissionCode] = grant
    return true
end

function Permissions.revoke(rankId, permissionCode)
    local bucket = Permissions.permissions_by_rank[rankId]
    if bucket then bucket[permissionCode] = nil end
    return true
end

function Permissions.listForRank(rankId)
    local b = Permissions.permissions_by_rank[rankId]
    if not b then return {} end
    local out = {}
    for k,v in pairs(b) do out[k] = v end
    return out
end

local function resolveForRank(rankId, permissionCode)
    local b = Permissions.permissions_by_rank[rankId]
    if not b then return nil end
    return b[permissionCode]
end

-- Check permission for a character across all organizations they belong to.
-- Deny (-1) from any rank takes precedence over allow (1).
function Permissions.hasPermission(characterId, permissionCode)
    local memberships = Members.listOrganizationsForCharacter(characterId) or {}
    local allowFound = false
    for _, m in ipairs(memberships) do
        local rankId = m.rank_id
        if rankId then
            local res = resolveForRank(rankId, permissionCode)
            if res == -1 then
                return false
            elseif res == 1 then
                allowFound = true
            end
        end
    end
    return allowFound
end

-- Check permission for a character within a specific organization.
function Permissions.hasPermissionInOrg(characterId, orgId, permissionCode)
    local memberships = Members.listOrganizationsForCharacter(characterId) or {}
    local allowFound = false
    for _, m in ipairs(memberships) do
        if m.organization_id == orgId then
            local rankId = m.rank_id
            if rankId then
                local res = resolveForRank(rankId, permissionCode)
                if res == -1 then
                    return false
                elseif res == 1 then
                    allowFound = true
                end
            end
        end
    end
    return allowFound
end

return Permissions
