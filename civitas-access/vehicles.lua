-- civitas-access/vehicles.lua
-- Vehicle access and metadata (placeholders)

local AccessVehicles = {
    byId = {}
}

function AccessVehicles.register(id, data)
    local v = AccessVehicles.byId[id] or {}
    v.id = id
    v.model = data.model or v.model
    v.organization_id = data.organization_id or v.organization_id
    v.building_id = data.building_id or v.building_id
    v.metadata = data.metadata or v.metadata or {}
    AccessVehicles.byId[id] = v
    if TriggerEvent then pcall(TriggerEvent, 'civitas:vehicleAccessRegistered', v) end
    return v
end

function AccessVehicles.get(id)
    return AccessVehicles.byId[id]
end

function AccessVehicles.list()
    local out = {}
    for _, v in pairs(AccessVehicles.byId) do table.insert(out, v) end
    return out
end

function AccessVehicles.canAccess(characterId, id)
    local v = AccessVehicles.get(id)
    if not v then return { allowed = false, reason = 'unknown_vehicle', org = nil } end
    if v.organization_id and exports['civitas-organizations'] and exports['civitas-organizations'].HasPermissionInOrg then
        if exports['civitas-organizations'].HasPermissionInOrg(characterId, v.organization_id, 'org.access.vehicle') then
            return { allowed = true, reason = 'org_permission', org = { id = v.organization_id } }
        end
        return { allowed = false, reason = 'no_permission', org = { id = v.organization_id } }
    end
    return { allowed = true, reason = 'unowned', org = nil }
end

exports('RegisterVehicleAccess', function(id, data) return AccessVehicles.register(id, data) end)
exports('GetVehicleAccess', function(id) return AccessVehicles.get(id) end)
exports('ListVehicleAccess', function() return AccessVehicles.list() end)
exports('CanAccessVehicle', function(characterId, id) return AccessVehicles.canAccess(characterId, id) end)

return AccessVehicles
