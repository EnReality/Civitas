-- civitas-starter/server.lua
local Config = require 'config'

local ox = exports['oxmysql']

local function isConsole(source)
    return source == 0
end

local function isAdmin(source)
    if isConsole(source) then return true end
    local id = nil
    if exports['civitas-core'] and exports['civitas-core'].GetIdentifier then
        id = exports['civitas-core']:GetIdentifier(source)
    else
        local ids = GetPlayerIdentifiers(source) or {}
        id = ids[1]
    end
    -- try civitas-admin export
    if exports['civitas-admin'] and exports['civitas-admin'].IsAllowed then
        local ok, allowed = pcall(function() return exports['civitas-admin'].IsAllowed(id) end)
        if ok and allowed then return true end
    end
    -- fallback to local config
    for _, a in ipairs(Config.admins or {}) do if a == id then return true end end
    return false
end

local PERMISSIONS = {
    'org.duty.toggle',
    'org.access',
    'org.access.building',
    'org.access.asset',
    'org.access.armory',
    'org.access.evidence',
    'org.manage.members',
    'org.manage.assets',
    'org.manage.buildings'
}

local GOV_ORGS = {
    { name = 'Police Department', tag = 'police' },
    { name = 'Fire Department', tag = 'fire' },
    { name = 'EMS / Medical', tag = 'ems' },
    { name = 'Courts', tag = 'courts' },
    { name = 'City Administration', tag = 'city' }
}

local RANKS = {
    { name = 'Chief', level = 100 },
    { name = 'Captain', level = 75 },
    { name = 'Lieutenant', level = 50 },
    { name = 'Officer', level = 25 },
    { name = 'Recruit', level = 10 }
}

-- Simple sequential executor for array of functions(cb)
local function runSequential(tasks, done)
    local i = 1
    local function nextStep()
        if i > #tasks then if done then done() end; return end
        local task = tasks[i]
        i = i + 1
        task(function() nextStep() end)
    end
    nextStep()
end

local function exec(sql, params, cb)
    if not exports['oxmysql'] then
        print('[civitas-starter] oxmysql not available; aborting')
        if cb then cb(nil) end
        return
    end
    exports['oxmysql']:execute(sql, params or {}, function(res)
        if cb then cb(res) end
    end)
end

local function fetchAll(sql, params, cb)
    if not exports['oxmysql'] then
        print('[civitas-starter] oxmysql not available; aborting')
        if cb then cb(nil) end
        return
    end
    exports['oxmysql']:execute(sql, params or {}, function(rows)
        if cb then cb(rows) end
    end)
end

RegisterCommand('civitas_seed', function(source, args, raw)
    local src = source
    if not isAdmin(src) then
        if src > 0 then pcall(function() TriggerClientEvent('chat:addMessage', src, { args = { '^1CIVITAS', 'You are not allowed to run this command.' } }) end) end
        print('[civitas-starter] civitas_seed denied for source ' .. tostring(src))
        return
    end

    if not exports['oxmysql'] then
        local msg = 'oxmysql not available; cannot run seed.'
        print('[civitas-starter] ' .. msg)
        if src > 0 then pcall(function() TriggerClientEvent('chat:addMessage', src, { args = { '^1CIVITAS', msg } }) end) end
        return
    end

    print('[civitas-starter] Starting seed process...')

    local counts = { permissions = 0, orgs = 0, ranks = 0, rank_permissions = 0 }

    -- Step 1: insert permissions
    local permTasks = {}
    for _, code in ipairs(PERMISSIONS) do
        table.insert(permTasks, function(cb)
            local sql = 'INSERT IGNORE INTO permissions (code, description) VALUES (?, ?)'
            exec(sql, { code, code }, function(res)
                counts.permissions = counts.permissions + 1
                cb()
            end)
        end)
    end

    -- Step 2: insert orgs
    local orgTasks = {}
    for _, o in ipairs(GOV_ORGS) do
        table.insert(orgTasks, function(cb)
            local sql = 'INSERT IGNORE INTO organizations (name, tag, organization_type, description) VALUES (?, ?, ?, ?)'
            exec(sql, { o.name, o.tag, 'government', o.name }, function(res)
                counts.orgs = counts.orgs + 1
                cb()
            end)
        end)
    end

    -- After orgs inserted, fetch org ids by tag
    local function afterOrgs(cb)
        local tags = {}
        for _, o in ipairs(GOV_ORGS) do table.insert(tags, o.tag) end
        local placeholders = table.concat((function()
            local a = {}
            for i=1,#tags do a[i] = '?' end
            return a
        end)(), ',')
        local sql = ('SELECT id, tag FROM organizations WHERE tag IN (' .. placeholders .. ')')
        fetchAll(sql, tags, function(rows)
            local orgByTag = {}
            for _, r in ipairs(rows or {}) do orgByTag[tostring(r.tag)] = r.id end

            -- Step 3: upsert ranks per org
            local rankTasks = {}
            for _, o in ipairs(GOV_ORGS) do
                local orgId = orgByTag[o.tag]
                if orgId then
                    for _, rk in ipairs(RANKS) do
                        table.insert(rankTasks, (function(orgId, rk)
                            return function(cb2)
                                local sql = 'INSERT INTO organization_ranks (organization_id, name, level, is_default) VALUES (?, ?, ?, 0) ON DUPLICATE KEY UPDATE level=VALUES(level)'
                                exec(sql, { orgId, rk.name, rk.level }, function(res)
                                    counts.ranks = counts.ranks + 1
                                    cb2()
                                end)
                            end
                        end)(orgId, rk))
                    end
                end
            end

            runSequential(rankTasks, function()
                cb(orgByTag)
            end)
        end)
    end

    -- After ranks, fetch permissions ids and map to ranks
    local function afterRanks(orgByTag, cb)
        -- fetch permission ids
        local placeholders = table.concat((function()
            local a = {}
            for i=1,#PERMISSIONS do a[i] = '?' end
            return a
        end)(), ',')
        local sql = ('SELECT id, code FROM permissions WHERE code IN (' .. placeholders .. ')')
        fetchAll(sql, PERMISSIONS, function(rows)
            local permByCode = {}
            for _, r in ipairs(rows or {}) do permByCode[tostring(r.code)] = r.id end

            -- For each org and rank, determine grants and insert into rank_permissions
            local rpTasks = {}
            for _, o in ipairs(GOV_ORGS) do
                local orgId = orgByTag[o.tag]
                if orgId then
                    for _, rk in ipairs(RANKS) do
                        table.insert(rpTasks, (function(orgId, rk)
                            return function(cb2)
                                -- find rank id
                                local q = 'SELECT id FROM organization_ranks WHERE organization_id = ? AND name = ? LIMIT 1'
                                fetchAll(q, { orgId, rk.name }, function(rrows)
                                    local rankId = rrows and rrows[1] and rrows[1].id
                                    if not rankId then cb2(); return end
                                    -- determine permissions for this rank
                                    local grants = {}
                                    if rk.name == 'Chief' then
                                        grants = PERMISSIONS
                                    elseif rk.name == 'Captain' then
                                        grants = { 'org.duty.toggle', 'org.access', 'org.access.building', 'org.access.asset', 'org.manage.members', 'org.manage.assets', 'org.manage.buildings' }
                                    elseif rk.name == 'Lieutenant' then
                                        grants = { 'org.duty.toggle', 'org.access', 'org.access.building', 'org.access.asset', 'org.manage.members' }
                                    elseif rk.name == 'Officer' then
                                        grants = { 'org.duty.toggle', 'org.access', 'org.access.building', 'org.access.asset' }
                                    elseif rk.name == 'Recruit' then
                                        grants = { 'org.duty.toggle', 'org.access' }
                                    end
                                    -- insert rank_permissions for each grant
                                    local innerTasks = {}
                                    for _, code in ipairs(grants) do
                                        local permId = permByCode[code]
                                        if permId then
                                            table.insert(innerTasks, function(cb3)
                                                local sql2 = 'INSERT INTO rank_permissions (rank_id, permission_id, granted) VALUES (?, ?, 1) ON DUPLICATE KEY UPDATE granted=VALUES(granted)'
                                                exec(sql2, { rankId, permId }, function(res2)
                                                    counts.rank_permissions = counts.rank_permissions + 1
                                                    cb3()
                                                end)
                                            end)
                                        end
                                    end
                                    runSequential(innerTasks, function() cb2() end)
                                end)
                            end
                        end)(orgId, rk))
                    end
                end
            end
            runSequential(rpTasks, function() cb() end)
        end)
    end

    -- run sequence: perms -> orgs -> ranks -> rank_permissions
    runSequential(permTasks, function()
        runSequential(orgTasks, function()
            afterOrgs(function(orgByTag)
                afterRanks(orgByTag, function()
                    -- done
                    local summary = ('permissions=%d orgs=%d ranks=%d rank_permissions=%d'):format(counts.permissions, counts.orgs, counts.ranks, counts.rank_permissions)
                    print('[civitas-starter] Seed complete: ' .. summary)
                    if src > 0 then pcall(function() TriggerClientEvent('chat:addMessage', src, { args = { '^2CIVITAS', 'Seed complete: ' .. summary } }) end) end
                    -- emit transaction
                    local caller = nil
                    if exports['civitas-core'] and exports['civitas-core'].GetIdentifier then caller = exports['civitas-core']:GetIdentifier(src) end
                    if TriggerEvent then pcall(TriggerEvent, 'civitas:transaction', { actor = src, action = 'db_seed_applied', details = counts, caller = caller, timestamp = os.time() }) end
                end)
            end)
        end)
    end)
end, false)
