-- civitas-assets/armories.lua
-- Armory storage and access placeholders

local Assets = require 'assets'

local Armories = {}

function Armories.register(id, data)
    data.type = 'armory'
    data.id = id
    return Assets.register(data)
end

function Armories.get(id)
    return Assets.get(id)
end

function Armories.list()
    local out = {}
    for _, v in pairs(Assets.list()) do if v.type == 'armory' then table.insert(out, v) end end
    return out
end

return Armories
