-- civitas-core/session.lua
-- In-memory session mapping between source, identifier, and characterId

local Session = {
    bySource = {}, -- [source] = { identifier, character, characterId, loaded }
    byCharacterId = {} -- [characterId] = source
}

-- set session with full character table
function Session.set(source, identifier, character)
    local characterId = character and character.id or nil
    Session.bySource[source] = { identifier = identifier, character = character, characterId = characterId, loaded = true }
    if characterId then
        Session.byCharacterId[characterId] = source
    end
end

function Session.get(source)
    return Session.bySource[source]
end

function Session.getCharacterId(source)
    local s = Session.bySource[source]
    return s and s.characterId or nil
end

function Session.getSource(characterId)
    return Session.byCharacterId[characterId]
end

function Session.clear(source)
    local s = Session.bySource[source]
    if s and s.characterId then
        Session.byCharacterId[s.characterId] = nil
    end
    Session.bySource[source] = nil
end

return Session
