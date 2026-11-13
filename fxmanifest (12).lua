fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'survival-start'
description 'One character per player: create on first join, spawn at last position or a survivor camp'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts { 'client.lua' }

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua',
}

dependencies {
    'ox_lib',
    'ox_inventory',
    'oxmysql',
    'qb-core',
    'illenium-appearance',
    'spawnmanager',
    'zombie-ai',
}
