-- civitas-core/character_repo.lua
-- Database-backed character repository (async callbacks)

local DB = require 'db'

local CharacterRepo = {}

function CharacterRepo.findByIdentifier(identifier, cb)
    if not identifier then cb(nil); return end
    local q = 'SELECT * FROM characters WHERE identifier = ? LIMIT 1'
    DB.fetchAll(q, { identifier }, function(rows)
        if not rows or #rows == 0 then cb(nil); return end
        cb(rows[1])
    end)
end

function CharacterRepo.createDefault(identifier, cb)
    if not identifier then cb(nil); return end
    local metadata = json.encode({ created_by = 'civitas-core' })
    local q = 'INSERT INTO characters (identifier, first_name, last_name, metadata) VALUES (?, ?, ?, ? )'
    DB.execute(q, { identifier, 'John', 'Doe', metadata }, function(res)
        -- try to fetch the inserted row
        CharacterRepo.findByIdentifier(identifier, cb)
    end)
end

return CharacterRepo
