-- civitas-core/character.lua
-- Character primitives (placeholders)

local DB = require 'db'
local Session = require 'session'
local Repo = require 'character_repo'

local Character = {}

-- Prefer license:* identifier
function Character.getPrimaryIdentifier(source)
    local ids = GetPlayerIdentifiers(source) or {}
    local first = nil
    for _, id in ipairs(ids) do
        if not first then first = id end
        if string.match(id, '^license:') then return id end
    end
    return first
end

-- Load or create character for a source. cb(character)
function Character.loadOrCreate(source, cb)
    local identifier = Character.getPrimaryIdentifier(source)
    if not identifier then cb(nil); return end

    -- DB unavailable fallback
    if not DB.isAvailable() then
        local tempChar = {
            id = -source,
            identifier = identifier,
            first_name = 'TEMP',
            last_name = 'PLAYER',
            metadata = { temporary = true, db_unavailable = true }
        }
        Session.set(source, identifier, tempChar)
        local payload = { actor = source, action = 'db_unavailable_fallback', details = { reason = DB.reason(), identifier = identifier }, timestamp = os.time() }
        if TriggerEvent then pcall(TriggerEvent, 'civitas:transaction', payload) end
        if TriggerEvent then pcall(TriggerEvent, 'civitas:characterLoaded', source, tempChar.id, identifier) end
        cb(tempChar)
        return
    end

    -- Try find
    Repo.findByIdentifier(identifier, function(row)
        if row then
            Session.set(source, identifier, row)
            local payload = { actor = source, action = 'character_loaded', details = { characterId = row.id, identifier = identifier }, timestamp = os.time() }
            if TriggerEvent then pcall(TriggerEvent, 'civitas:transaction', payload) end
            if TriggerEvent then pcall(TriggerEvent, 'civitas:characterLoaded', source, row.id, identifier) end
            cb(row)
        else
            -- create default
            Repo.createDefault(identifier, function(newrow)
                if newrow then
                    Session.set(source, identifier, newrow)
                    local payload = { actor = source, action = 'character_created', details = { characterId = newrow.id, identifier = identifier }, timestamp = os.time() }
                    if TriggerEvent then pcall(TriggerEvent, 'civitas:transaction', payload) end
                    if TriggerEvent then pcall(TriggerEvent, 'civitas:characterLoaded', source, newrow.id, identifier) end
                    cb(newrow)
                else
                    cb(nil)
                end
            end)
        end
    end)
end

function Character.get(source)
    local s = Session.get(source)
    return s and s.character or nil
end

function Character.getId(source)
    local s = Session.get(source)
    return s and s.characterId or nil
end

function Character.isLoaded(source)
    local s = Session.get(source)
    return s and s.loaded or false
end

function Character.cleanup(source)
    Session.clear(source)
end

return Character
