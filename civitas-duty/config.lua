-- civitas-duty/config.lua
local Config = {}

-- Role detection rules (case-insensitive substring match)
Config.role_rules = {
    police = { 'police' },
    fire = { 'fire' },
    ems = { 'ems', 'medical' }
}

-- Default permission code for toggling duty
Config.permission_code = 'org.duty.toggle'

return Config
