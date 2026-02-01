fx_version 'cerulean'
game 'gta5'

author 'Gritty Games'
description 'CIVITAS Core systems: player, character, and event primitives'
version '0.1.0'

server_script 'db.lua'
server_script 'session.lua'
server_script 'character_repo.lua'
server_script 'character.lua'
server_script 'events.lua'
server_script 'player.lua'
server_script 'init.lua'

shared_script '../shared/config.lua'
shared_script '../shared/constants.lua'
shared_script '../shared/utils.lua'
