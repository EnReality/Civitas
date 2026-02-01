-- civitas-access/doors.lua
-- Door access primitives (placeholders)

local Doors = {
    byId = {}
}

function Doors.register(id, data)
    local d = Doors.byId[id] or {}
    d.id = id
    d.name = data.name or d.name
    d.building_id = data.building_id or d.building_id
    d.metadata = data.metadata or d.metadata or {}
    Doors.byId[id] = d
    if TriggerEvent then pcall(TriggerEvent, 'civitas:doorRegistered', d) end
    return d
end

function Doors.get(id)
    return Doors.byId[id]
end

function Doors.list()
    local out = {}
    for _, v in pairs(Doors.byId) do table.insert(out, v) end
    return out
end

function Doors.canAccess(characterId, doorId)
    -- Placeholder: consult civitas-access/buildings or org permissions
    local d = Doors.get(doorId)
    if not d then return { allowed = false, reason = 'unknown_door', org = nil } end
    if d.building_id and exports['civitas-access'] and exports['civitas-access'].CanAccessBuilding then
        return exports['civitas-access'].CanAccessBuilding(characterId, d.building_id)
    end
    return { allowed = true, reason = 'unknown_building_association', org = nil }
end

exports('RegisterDoor', function(id, data) return Doors.register(id, data) end)
exports('GetDoor', function(id) return Doors.get(id) end)
exports('ListDoors', function() return Doors.list() end)
exports('CanAccessDoor', function(characterId, doorId) return Doors.canAccess(characterId, doorId) end)

return Doors
