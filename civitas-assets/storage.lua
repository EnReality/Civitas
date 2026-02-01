-- civitas-assets/storage.lua
-- Asset storage helper (placeholders)

local Assets = require 'assets'

local Storage = {}

function Storage.register(id, data)
    data.type = 'storage'
    data.id = id
    return Assets.register(data)
end

function Storage.get(id)
    return Assets.get(id)
end

function Storage.list()
    local out = {}
    for _, v in pairs(Assets.list()) do if v.type == 'storage' then table.insert(out, v) end end
    return out
end

return Storage
