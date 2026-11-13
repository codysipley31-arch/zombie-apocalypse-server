fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'survival-basebuilding'
description 'Placeable base pieces (walls, barricades, crates, workbenches) persisted in MySQL'
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
    'qb-target',
    'zombie-ai',
}
