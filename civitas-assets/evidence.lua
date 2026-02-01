-- civitas-assets/evidence.lua
-- Evidence tracking placeholders (minimal schema-level support only)

local Assets = require 'assets'

local Evidence = {}

function Evidence.register(id, data)
    data.type = 'evidence'
    data.id = id
    return Assets.register(data)
end

function Evidence.get(id)
    return Assets.get(id)
end

function Evidence.list()
    local out = {}
    for _, v in pairs(Assets.list()) do if v.type == 'evidence' then table.insert(out, v) end end
    return out
end

return Evidence
