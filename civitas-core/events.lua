-- civitas-core/events.lua
-- Event helper primitives

local Events = {}

function Events.emit(name, payload)
    -- Server-side event emission placeholder
    TriggerEvent(name, payload)
end

function Events.on(name, cb)
    AddEventHandler(name, cb)
end

return Events
