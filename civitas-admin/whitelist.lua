-- civitas-admin/whitelist.lua
-- Minimal whitelist placeholder (no enforced economy or jobs)

local Whitelist = {}

function Whitelist.isAllowed(identifier)
    -- Minimal permissive whitelist for now. Enforcement can be added later.
    return true
end

return Whitelist
