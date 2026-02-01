-- civitas-organizations/members.lua
-- Membership primitives: add/remove membership and simple queries.

local Ranks = require 'ranks'

local Members = {
    -- keyed by composite "orgId:characterId" for quick lookup
    byKey = {},
    byOrg = {},
    byCharacter = {}
}

local function key(orgId, characterId)
    return tostring(orgId) .. ':' .. tostring(characterId)
end

local function ensureOrgBucket(orgId)
    if not Members.byOrg[orgId] then Members.byOrg[orgId] = {} end
end

local function ensureCharacterBucket(characterId)
    if not Members.byCharacter[characterId] then Members.byCharacter[characterId] = {} end
end

function Members.add(orgId, characterId, rankId)
    -- Validate rank belongs to the same org if provided
    if rankId then
        local r = Ranks.get(rankId)
        if not r or r.organization_id ~= orgId then
            return nil, 'rank_mismatch'
        end
    end
    local k = key(orgId, characterId)
    if Members.byKey[k] then
        -- already a member; update rank if changed
        Members.byKey[k].rank_id = rankId
        Members.byKey[k].joined_at = Members.byKey[k].joined_at or os.time()
        return Members.byKey[k]
    end
    local rec = {
        id = k,
        organization_id = orgId,
        character_id = characterId,
        rank_id = rankId,
        joined_at = os.time()
    }
    Members.byKey[k] = rec
    ensureOrgBucket(orgId)
    table.insert(Members.byOrg[orgId], rec)
    ensureCharacterBucket(characterId)
    table.insert(Members.byCharacter[characterId], rec)
    if TriggerEvent then pcall(TriggerEvent, 'civitas:memberAdded', rec) end
    return rec
end

function Members.remove(orgId, characterId)
    local k = key(orgId, characterId)
    local rec = Members.byKey[k]
    if not rec then return false end
    -- remove from byOrg
    local bucket = Members.byOrg[orgId]
    if bucket then
        for i=#bucket,1,-1 do
            if bucket[i].character_id == characterId then table.remove(bucket, i); break end
        end
    end
    -- remove from byCharacter
    local cb = Members.byCharacter[characterId]
    if cb then
        for i=#cb,1,-1 do
            if cb[i].organization_id == orgId then table.remove(cb, i); break end
        end
    end
    Members.byKey[k] = nil
    if TriggerEvent then pcall(TriggerEvent, 'civitas:memberRemoved', { organization_id = orgId, character_id = characterId }) end
    return true
end

function Members.getMembership(orgId, characterId)
    return Members.byKey[key(orgId, characterId)]
end

function Members.listForOrganization(orgId)
    return Members.byOrg[orgId] or {}
end

function Members.listOrganizationsForCharacter(characterId)
    local out = {}
    for _, rec in ipairs(Members.byCharacter[characterId] or {}) do
        table.insert(out, rec)
    end
    return out
end

return Members
