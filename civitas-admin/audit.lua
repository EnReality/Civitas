-- civitas-admin/audit.lua
-- Audit utilities (placeholders)

local Audit = {}

function Audit.log(entry)
    local payload = {
        actor = entry.actor,
        action = entry.action or entry.type,
        details = entry.details or entry,
        timestamp = os.time()
    }
    if TriggerEvent then pcall(TriggerEvent, 'civitas:transaction', payload) end
    return true
end

return Audit
