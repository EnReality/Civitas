-- civitas-core/init.lua
-- Core server entry for CIVITAS RP Framework
-- This resource provides primitives only. Implementers should build game-specific logic in separate resources.

local DB = require 'db'
local Session = require 'session'
local Character = require 'character'

print('civitas-core initialized')

-- Load or create character for a connecting player
AddEventHandler('playerSpawned', function(name, setKickReason, deferrals)
	local src = source
	Character.loadOrCreate(src, function(char)
		if not char then
			print('[civitas-core] failed to load or create character for source ' .. tostring(src))
		end
		-- proceed regardless; Character.loadOrCreate binds session and emits events
	end)
end)

-- Cleanup on drop
AddEventHandler('playerDropped', function(reason)
	local src = source
	Character.cleanup(src)
end)

-- Exports
exports('GetIdentifier', function(source)
	return Character.getPrimaryIdentifier(source)
end)

exports('GetCharacterId', function(source)
	return Character.getId(source)
end)

exports('GetSourceFromCharacterId', function(characterId)
	return Session.getSource(characterId)
end)

exports('IsCharacterLoaded', function(source)
	return Character.isLoaded(source)
end)

exports('GetCharacter', function(source)
	return Character.get(source)
end)

exports('GetCoreObject', function()
	return { name = 'civitas-core', version = '0.1.0', author = 'Gritty Games' }
end)

-- Developer commands
RegisterCommand('civitas_whoami', function(source, args, raw)
	local src = source
	local id = Character.getPrimaryIdentifier(src)
	local char = Character.get(src)
	local charId = char and char.id or nil
	local loaded = Character.isLoaded(src)
	local msg = ('source=%s identifier=%s characterId=%s loaded=%s'):format(tostring(src), tostring(id), tostring(charId), tostring(loaded))
	print('[civitas-core] ' .. msg)
	pcall(function() TriggerClientEvent('chat:addMessage', src, { args = { '^2CIVITAS', msg } }) end)
end, false)

RegisterCommand('civitas_core_status', function(source, args, raw)
	local available = DB.isAvailable()
	local reason = DB.reason()
	local msg = ('DB available=%s reason=%s'):format(tostring(available), tostring(reason))
	print('[civitas-core] ' .. msg)
	if source and source > 0 then pcall(function() TriggerClientEvent('chat:addMessage', source, { args = { '^2CIVITAS', msg } }) end) end
end, false)

