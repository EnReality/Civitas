-- civitas-organizations/ranks.lua
-- Rank management: define per-organization ranks, ordering (level), and
-- simple remove/update primitives.

local Ranks = {
    byId = {},
    byOrg = {},
    nextId = 1
}

local function ensureOrgBucket(orgId)
    if not Ranks.byOrg[orgId] then
        Ranks.byOrg[orgId] = {}
    end
end

function Ranks.define(orgId, rankData)
    ensureOrgBucket(orgId)
    -- rankData: { name, level, is_default, description }
    local id = Ranks.nextId
    Ranks.nextId = Ranks.nextId + 1
    local r = {
        id = id,
        organization_id = orgId,
        name = rankData.name or ('rank_' .. tostring(id)),
        level = rankData.level or 0,
        is_default = rankData.is_default and true or false,
        description = rankData.description,
        created_at = os.time(),
        updated_at = os.time()
    }
    Ranks.byId[id] = r
    table.insert(Ranks.byOrg[orgId], r)
    return r
end

function Ranks.get(rankId)
    return Ranks.byId[rankId]
end

function Ranks.listForOrganization(orgId)
    ensureOrgBucket(orgId)
    table.sort(Ranks.byOrg[orgId], function(a,b) return a.level > b.level end)
    return Ranks.byOrg[orgId]
end

function Ranks.update(rankId, attrs)
    local r = Ranks.byId[rankId]
    if not r then return nil end
    r.name = attrs.name or r.name
    r.level = (attrs.level ~= nil) and attrs.level or r.level
    r.is_default = (attrs.is_default ~= nil) and (attrs.is_default and true or false) or r.is_default
    r.description = attrs.description or r.description
    r.updated_at = os.time()
    return r
end

function Ranks.remove(rankId)
    local r = Ranks.byId[rankId]
    if not r then return false end
    local orgId = r.organization_id
    -- remove from byOrg
    local bucket = Ranks.byOrg[orgId]
    if bucket then
        for i= #bucket,1,-1 do
            if bucket[i].id == rankId then
                table.remove(bucket, i)
                break
            end
        end
    end
    Ranks.byId[rankId] = nil
    return true
end

return Ranks
