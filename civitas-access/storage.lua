-- civitas-access/storage.lua
-- Storage primitives (placeholders) for items and assets

local Storage = {
    byId = {}
}

function Storage.register(id, data)
    local s = Storage.byId[id] or {}
    s.id = id
    s.name = data.name or s.name
    s.organization_id = data.organization_id or s.organization_id
    s.metadata = data.metadata or s.metadata or {}
    Storage.byId[id] = s
    if TriggerEvent then pcall(TriggerEvent, 'civitas:storageRegistered', s) end
    return s
end

function Storage.get(id)
    return Storage.byId[id]
end

function Storage.list()
    local out = {}
    for _, v in pairs(Storage.byId) do table.insert(out, v) end
    return out
end

function Storage.canAccess(characterId, id)
    local s = Storage.get(id)
    if not s then return { allowed = false, reason = 'unknown_storage', org = nil } end
    if s.organization_id and exports['civitas-organizations'] and exports['civitas-organizations'].HasPermissionInOrg then
        if exports['civitas-organizations'].HasPermissionInOrg(characterId, s.organization_id, 'org.access.storage') then
            return { allowed = true, reason = 'org_permission', org = { id = s.organization_id } }
        end
        return { allowed = false, reason = 'no_permission', org = { id = s.organization_id } }
    end
    return { allowed = true, reason = 'unowned', org = nil }
end

exports('RegisterStorage', function(id, data) return Storage.register(id, data) end)
exports('GetStorage', function(id) return Storage.get(id) end)
exports('ListStorage', function() return Storage.list() end)
exports('CanAccessStorage', function(characterId, id) return Storage.canAccess(characterId, id) end)

return Storage
