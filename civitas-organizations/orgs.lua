-- civitas-organizations/orgs.lua
-- Organization manager (in-memory core). Persistence is left to the
-- application integration layer; this module provides creation, lookup,
-- update and deletion primitives.

local Orgs = {
    byId = {},
    nextId = 1
}

local function normalizeOrgData(data)
    return {
        name = data.name or "",
        tag = data.tag,
        organization_type = data.organization_type or 'civil',
        description = data.description,
        metadata = data.metadata or {}
    }
end

function Orgs.create(data)
    local id = Orgs.nextId
    Orgs.nextId = Orgs.nextId + 1
    local org = normalizeOrgData(data)
    org.id = id
    org.is_active = (data.is_active == nil) and 1 or (data.is_active and 1 or 0)
    org.created_at = os.time()
    org.updated_at = org.created_at
    Orgs.byId[id] = org
    -- lightweight event for other systems
    if TriggerEvent then
        pcall(TriggerEvent, 'civitas:orgCreated', org)
    end
    return org
end

function Orgs.get(id)
    return Orgs.byId[id]
end

function Orgs.list()
    local out = {}
    for _, v in pairs(Orgs.byId) do
        table.insert(out, v)
    end
    return out
end

function Orgs.update(id, data)
    local org = Orgs.byId[id]
    if not org then return nil, 'not_found' end
    local d = normalizeOrgData(data)
    org.name = d.name or org.name
    org.tag = d.tag or org.tag
    org.organization_type = d.organization_type or org.organization_type
    org.description = d.description or org.description
    org.metadata = data.metadata or org.metadata
    org.updated_at = os.time()
    if TriggerEvent then
        pcall(TriggerEvent, 'civitas:orgUpdated', org)
    end
    return org
end

function Orgs.remove(id)
    local org = Orgs.byId[id]
    if not org then return false end
    Orgs.byId[id] = nil
    if TriggerEvent then
        pcall(TriggerEvent, 'civitas:orgRemoved', id)
    end
    return true
end

return Orgs
