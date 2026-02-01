-- civitas-access/interiors.lua
-- Interior primitives and metadata (placeholders)

local Interiors = {
    byId = {}
}

function Interiors.register(id, data)
    local i = Interiors.byId[id] or {}
    i.id = id
    i.name = data.name or i.name
    i.metadata = data.metadata or i.metadata or {}
    Interiors.byId[id] = i
    if TriggerEvent then pcall(TriggerEvent, 'civitas:interiorRegistered', i) end
    return i
end

function Interiors.get(id)
    return Interiors.byId[id]
end

function Interiors.list()
    local out = {}
    for _, v in pairs(Interiors.byId) do table.insert(out, v) end
    return out
end

function Interiors.canAccess(characterId, interiorId)
    local i = Interiors.get(interiorId)
    if not i then return { allowed = false, reason = 'unknown_interior', org = nil } end
    return { allowed = true, reason = 'no_restrictions_defined', org = nil }
end

exports('RegisterInterior', function(id, data) return Interiors.register(id, data) end)
exports('GetInterior', function(id) return Interiors.get(id) end)
exports('ListInteriors', function() return Interiors.list() end)
exports('CanAccessInterior', function(characterId, interiorId) return Interiors.canAccess(characterId, interiorId) end)

return Interiors
