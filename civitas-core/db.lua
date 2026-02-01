-- civitas-core/db.lua
-- Minimal DB adapter wrapper that prefers oxmysql and falls back to safe no-op.
local DB = {
    available = false,
    _reason = 'unknown'
}

local function updateAvailability()
    if GetResourceState and GetResourceState('oxmysql') == 'started' then
        DB.available = true
        DB.reason = 'oxmysql started'
    else
        DB.available = false
        local state = 'not started'
        if GetResourceState then state = GetResourceState('oxmysql') or state end
        DB.reason = 'oxmysql resource state: ' .. tostring(state)
    end
end

-- initialize
updateAvailability()

-- watch resource start/stop to keep status accurate
AddEventHandler('onResourceStart', function(resName)
    if resName == 'oxmysql' then
        updateAvailability()
        print('[civitas-core][db] oxmysql became available')
    end
end)

AddEventHandler('onResourceStop', function(resName)
    if resName == 'oxmysql' then
        updateAvailability()
        print('[civitas-core][db] oxmysql stopped')
    end
end)

function DB.isAvailable()
    return DB.available
end

function DB.reason()
    return DB._reason
end

-- fetchAll: executes a SELECT and returns rows (cb(rows))
function DB.fetchAll(query, params, cb)
    if DB.available and exports and exports['oxmysql'] then
        local ok, res = pcall(function()
            return exports['oxmysql']:execute(query, params, cb)
        end)
        if not ok then
            print('[civitas-core][db] oxmysql fetchAll failed: ' .. tostring(res))
            cb(nil)
        end
    else
        print('[civitas-core][db] oxmysql not available; DB.fetchAll is a no-op; reason=' .. tostring(DB._reason))
        cb(nil)
    end
end

-- fetchScalar: returns first column of first row (cb(value))
function DB.fetchScalar(query, params, cb)
    DB.fetchAll(query, params, function(rows)
        if not rows or #rows == 0 then cb(nil); return end
        local first = rows[1]
        for k, v in pairs(first) do
            cb(v)
            return
        end
        cb(nil)
    end)
end

-- execute: runs INSERT/UPDATE/DELETE; cb(result)
function DB.execute(query, params, cb)
    if DB.available and exports and exports['oxmysql'] then
        local ok, res = pcall(function()
            return exports['oxmysql']:execute(query, params, cb)
        end)
        if not ok then
            print('[civitas-core][db] oxmysql execute failed: ' .. tostring(res))
            cb(nil)
        end
    else
        print('[civitas-core][db] oxmysql not available; DB.execute is a no-op; reason=' .. tostring(DB._reason))
        cb(nil)
    end
end

return DB
