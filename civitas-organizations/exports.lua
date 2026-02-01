-- civitas-organizations/exports.lua
-- Exports for other resources to interact with organizations
local Orgs = require 'orgs'
local Members = require 'members'
local Ranks = require 'ranks'
local Permissions = require 'permissions'

-- Organization APIs
exports('CreateOrganization', function(orgType, name)
    -- Standardized signature: CreateOrganization(orgType, name)
    return Orgs.create({ name = name, organization_type = orgType })
end)

exports('GetOrganization', function(orgId)
    return Orgs.get(orgId)
end)

exports('ListOrganizations', function()
    return Orgs.list()
end)

-- Rank APIs
exports('CreateRank', function(orgId, rankData)
    return Ranks.define(orgId, rankData)
end)

exports('UpdateRank', function(rankId, attrs)
    return Ranks.update(rankId, attrs)
end)

exports('RemoveRank', function(rankId)
    return Ranks.remove(rankId)
end)

-- Membership APIs
exports('AddMember', function(orgId, characterId, rankId)
    return Members.add(orgId, characterId, rankId)
end)

exports('RemoveMember', function(orgId, characterId)
    return Members.remove(orgId, characterId)
end)

-- Permission APIs (grant/revoke are rank-scoped)
exports('GrantPermissionToRank', function(rankId, permissionCode, grant)
    -- grant: true = allow, false = deny; default true
    if grant == nil then grant = true end
    return Permissions.grant(rankId, permissionCode, grant)
end)

exports('RevokePermissionFromRank', function(rankId, permissionCode)
    return Permissions.revoke(rankId, permissionCode)
end)

exports('RegisterPermission', function(code)
    return Permissions.registerPermission(code)
end)

exports('HasPermissionInOrg', function(characterId, orgId, permissionCode)
    return Permissions.hasPermissionInOrg(characterId, orgId, permissionCode)
end)

-- Core exports requested by Civitas surface
-- HasPermission(characterId, permissionCode)
exports('HasPermission', function(characterId, permissionCode)
    return Permissions.hasPermission(characterId, permissionCode)
end)

-- GetOrganizations(characterId) -> list of organization membership records
exports('GetOrganizations', function(characterId)
    return Members.listOrganizationsForCharacter(characterId)
end)

-- Lightweight helpers for modules that want rank -> permissions
exports('ListPermissionsForRank', function(rankId)
    return Permissions.listForRank(rankId)
end)

-- Note: These implementations are server-side, in-memory primitives.
-- Persistence (database load/save) and concurrency controls should be
-- implemented by the application integration layer as needed.
