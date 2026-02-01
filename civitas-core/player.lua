-- civitas-core/player.lua
-- Player-related primitives (placeholders)

local Civitas = {}

-- Placeholder: get player metadata
function Civitas.getPlayer(id)
    -- Return minimal placeholder structure
    return { id = id, name = ('player_%s'):format(id) }
end

return Civitas
