fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'survival-crafting'
description 'Hand crafting, workbench crafting and weapon repair'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts { 'client.lua' }
server_scripts { 'server.lua' }

dependencies {
    'ox_lib',
    'ox_inventory',
    'qb-core',
    'qb-target',
}
