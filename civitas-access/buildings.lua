-- civitas-access/buildings.lua
-- Building definitions and access checks (placeholders)
-- civitas-access/buildings.lua
-- Building registry and access resolution. This module stores building
-- metadata in-memory and provides exports to resolve access using
-- organization + rank permissions (via civitas-organizations exports).

local Buildings = {
    byId = {}
}

local function safeOrgExport(name, ...)
    if not exports['civitas-organizations'] then return nil end
    local ok, fn = pcall(function() return exports['civitas-organizations'][name] end)
    if not ok or not fn then return nil end
    local s, r = pcall(fn, ...)
    if not s then return nil end
    return r
end

-- Register or update a building
function Buildings.register(id, data)
    local b = Buildings.byId[id] or {}
    b.id = id
    b.name = data.name or b.name
    b.organization_id = data.organization_id or b.organization_id
    b.access_mode = data.access_mode or b.access_mode or 'organization' -- organization/public/restricted/mixed
    b.address = data.address or b.address
    b.pos = data.pos or b.pos
    b.metadata = data.metadata or b.metadata or {}
    b.updated_at = os.time()
    if not b.created_at then b.created_at = b.updated_at end
    Buildings.byId[id] = b
    if TriggerEvent then pcall(TriggerEvent, 'civitas:buildingRegistered', b) end
    return b
end

function Buildings.get(id)
    return Buildings.byId[id]
end

function Buildings.list()
    local out = {}
    for _, v in pairs(Buildings.byId) do table.insert(out, v) end
    return out
end

-- Resolve whether a character can access a building.
-- Returns: { allowed = bool, reason = string, org = orgTable or nil }
function Buildings.canAccess(characterId, buildingId)
    local b = Buildings.get(buildingId)
    if not b then
        return { allowed = false, reason = 'unknown_building', org = nil }
    end

    -- Unowned buildings are treated as public unless metadata says otherwise
    if not b.organization_id then
        local pub = b.access_mode == 'public' or (b.metadata and b.metadata.public == true)
        if pub then
            return { allowed = true, reason = 'unowned_public', org = nil }
        end
        return { allowed = true, reason = 'unowned', org = nil }
    end

    -- Try to get organization info from civitas-organizations (export)
    local org = safeOrgExport('GetOrganization', b.organization_id)
    if not org then
        return { allowed = false, reason = 'org_module_unavailable', org = nil }
    end

    local mode = b.access_mode or 'organization'
    if mode == 'public' then
        return { allowed = true, reason = 'public', org = org }
    end

    -- Helper to test permissions via organizations export
    local function hasPerm(code)
        local ok, res = pcall(function()
            local orgExports = exports['civitas-organizations']
            if orgExports then
                if orgExports.HasPermissionInOrg then
                    return orgExports.HasPermissionInOrg(characterId, b.organization_id, code)
                elseif orgExports.HasPermission then
                    return orgExports.HasPermission(characterId, code)
                end
            end
            return false
        end)
        return ok and res
    end

    -- Check membership and permissions using civitas-organizations.GetOrganizations
    local memberships = safeOrgExport('GetOrganizations', characterId) or {}
    local memberOfOrg = false
    for _, m in ipairs(memberships) do
        if m.organization_id == b.organization_id then memberOfOrg = true; break end
    end

    -- Decision logic
    if mode == 'organization' then
        if not memberOfOrg then
            return { allowed = false, reason = 'not_member', org = org }
        end
        -- application can grant rank permissions like 'org.access.building'
        if hasPerm('org.access.building') or hasPerm('org.access') then
            return { allowed = true, reason = 'member_with_permission', org = org }
        end
        return { allowed = false, reason = 'no_permission', org = org }
    end

    if mode == 'restricted' then
        -- restricted requires explicit permission even if member
        if hasPerm('org.access.building.restricted') or hasPerm('org.access.building') then
            return { allowed = true, reason = 'has_restricted_permission', org = org }
        end
        return { allowed = false, reason = 'no_permission_restricted', org = org }
    end

    if mode == 'mixed' then
        -- mixed: prefer explicit permission; otherwise allow if metadata.public
        if hasPerm('org.access.building') then
            return { allowed = true, reason = 'member_with_permission', org = org }
        end
        if b.metadata and b.metadata.public == true then
            return { allowed = true, reason = 'mixed_public', org = org }
        end
        return { allowed = false, reason = 'no_permission_mixed', org = org }
    end

    -- Fallback deny
    return { allowed = false, reason = 'access_mode_unknown', org = org }
end

-- Asset access resolution (assets may be org-owned or character-owned)
-- Expects asset table with fields: id, organization_id, character_id, metadata
function Buildings.canAccessAsset(characterId, asset)
    if not asset then
        return { allowed = false, reason = 'unknown_asset', org = nil }
    end

    -- Personal ownership wins
    if asset.character_id and tostring(asset.character_id) == tostring(characterId) then
        return { allowed = true, reason = 'owner', org = nil }
    end

    if not asset.organization_id then
        return { allowed = true, reason = 'unowned', org = nil }
    end

    local org = safeOrgExport('GetOrganization', asset.organization_id)
    if not org then
        return { allowed = false, reason = 'org_module_unavailable', org = nil }
    end

    -- Check organization-scoped permission for assets
    local function hasPerm(code)
        local ok, res = pcall(function()
            local orgExports = exports['civitas-organizations']
            if orgExports then
                if orgExports.HasPermissionInOrg then
                    return orgExports.HasPermissionInOrg(characterId, asset.organization_id, code)
                elseif orgExports.HasPermission then
                    return orgExports.HasPermission(characterId, code)
                end
            end
            return false
        end)
        return ok and res
    end

    if hasPerm('org.access.asset') or hasPerm('org.access') then
        return { allowed = true, reason = 'org_permission', org = org }
    end

    -- If user is member of org but lacks explicit permission, deny with informative reason
    local memberships = safeOrgExport('GetOrganizations', characterId) or {}
    for _, m in ipairs(memberships) do
        if m.organization_id == asset.organization_id then
            return { allowed = false, reason = 'no_permission', org = org }
        end
    end

    return { allowed = false, reason = 'not_member', org = org }
end

-- Exports for other resources
exports('CanAccessBuilding', function(characterId, buildingId)
    return Buildings.canAccess(characterId, buildingId)
end)

exports('CanAccessAsset', function(characterId, assetOrAssetId)
    -- Support both passing an asset table or an id (in which case caller must
    -- resolve the asset and call back into this resource to pass the object).
    if type(assetOrAssetId) == 'table' then
        return Buildings.canAccessAsset(characterId, assetOrAssetId)
    end
    -- unknown id handling: asset lookup not implemented in this module
    return { allowed = false, reason = 'asset_lookup_not_implemented', org = nil }
end)

exports('RegisterBuilding', function(buildingId, data)
    return Buildings.register(buildingId, data)
end)

exports('GetBuilding', function(buildingId)
    return Buildings.get(buildingId)
end)

exports('ListBuildings', function()
    return Buildings.list()
end)

return Buildings
