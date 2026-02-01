-- civitas-assets/assets.lua
-- Central asset registry and access helpers (server-side only)
-- Responsibilities:
--  - Register assets (storage, armory, evidence, vehicle)
--  - Store assets in-memory by id
--  - Bind assets to organizations and optionally buildings
--  - Resolve access by calling exports['civitas-access'].CanAccessAsset
--  - Emit transaction-style events for access attempts
-- Exports:
--  - RegisterAsset(assetData)
--  - GetAsset(assetId)
--  - ListAssets()
--  - CanAccessAsset(characterId, assetId)
-- Notes: This module defines authority, not mechanics. No gameplay logic.

local Assets = {
    byId = {},
    nextId = 1
}

local function now()
    return os.time()
end

local function safeAccessExport(name, ...)
    if not exports['civitas-access'] then return nil end
    local ok, fn = pcall(function() return exports['civitas-access'][name] end)
    if not ok or not fn then return nil end
    local s, r = pcall(fn, ...)
    if not s then return nil end
    return r
end

local function emitTransaction(payload)
    -- Emit lightweight transaction-style events for audit purposes.
    -- Payload example: { actor = characterId, asset_id = id, action = 'access_attempt', allowed = bool, reason = '...' }
    if TriggerEvent then
        pcall(TriggerEvent, 'civitas:assetAccessAttempt', payload)
        pcall(TriggerEvent, 'civitas:transaction', payload)
    end
end

-- Register or update an asset. assetData may include:
--  id (optional), type ('vehicle'|'storage'|'armory'|'evidence'),
--  organization_id (optional), building_id (optional), character_id (optional), metadata
function Assets.register(assetData)
    local id = assetData.id or Assets.nextId
    if not assetData.id then Assets.nextId = Assets.nextId + 1 end

    local a = Assets.byId[id] or {}
    a.id = id
    a.type = assetData.type or a.type or 'generic'
    a.name = assetData.name or a.name
    a.organization_id = assetData.organization_id or a.organization_id
    a.building_id = assetData.building_id or a.building_id
    a.character_id = assetData.character_id or a.character_id
    a.metadata = assetData.metadata or a.metadata or {}
    a.created_at = a.created_at or now()
    a.updated_at = now()

    Assets.byId[id] = a

    if TriggerEvent then pcall(TriggerEvent, 'civitas:assetRegistered', a) end
    return a
end

function Assets.get(assetId)
    return Assets.byId[assetId]
end

function Assets.list()
    local out = {}
    for _, v in pairs(Assets.byId) do table.insert(out, v) end
    return out
end

-- Resolve access for a character to an asset id.
-- Returns the structured result from civitas-access and emits a transaction event.
function Assets.canAccess(characterId, assetId)
    local asset = Assets.get(assetId)
    if not asset then
        local payload = { actor = characterId, asset_id = assetId, action = 'access_attempt', allowed = false, reason = 'unknown_asset', timestamp = now() }
        emitTransaction(payload)
        return { allowed = false, reason = 'unknown_asset', org = nil }
    end

    -- Try to delegate to civitas-access; prefer CanAccessAsset(export) which
    -- accepts an asset table. If not available, fall back to org-scoped
    -- permission checks via civitas-organizations.
    local accessResult = safeAccessExport('CanAccessAsset', characterId, asset)
    if not accessResult then
        -- Fallback: org-scoped permission check
        local orgExports = exports['civitas-organizations']
        if asset.organization_id and orgExports and orgExports.HasPermissionInOrg then
            local ok, allowed = pcall(function() return orgExports.HasPermissionInOrg(characterId, asset.organization_id, 'org.access.asset') end)
            if ok and allowed then
                accessResult = { allowed = true, reason = 'org_permission_fallback', org = { id = asset.organization_id } }
            else
                accessResult = { allowed = false, reason = 'no_permission_fallback', org = { id = asset.organization_id } }
            end
        else
            accessResult = { allowed = false, reason = 'access_module_unavailable', org = nil }
        end
    end

    -- Emit audit event with minimal context
    local payload = {
        actor = characterId,
        asset_id = asset.id,
        organization_id = asset.organization_id,
        action = 'access_attempt',
        allowed = accessResult.allowed,
        reason = accessResult.reason,
        timestamp = now()
    }
    emitTransaction(payload)

    return accessResult
end

-- Exports
exports('RegisterAsset', function(assetData)
    return Assets.register(assetData)
end)

exports('GetAsset', function(assetId)
    return Assets.get(assetId)
end)

exports('ListAssets', function()
    return Assets.list()
end)

exports('CanAccessAsset', function(characterId, assetId)
    return Assets.canAccess(characterId, assetId)
end)

return Assets
