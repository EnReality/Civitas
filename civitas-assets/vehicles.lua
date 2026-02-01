-- civitas-assets/vehicles.lua
-- Asset vehicle definitions (placeholders)

local Assets = require 'assets'

local AssetVehicles = {}

function AssetVehicles.register(id, data)
    data.type = 'vehicle'
    data.id = id
    return Assets.register(data)
end

function AssetVehicles.get(id)
    return Assets.get(id)
end

function AssetVehicles.list()
    local out = {}
    for _, v in pairs(Assets.list()) do if v.type == 'vehicle' then table.insert(out, v) end end
    return out
end

return AssetVehicles
