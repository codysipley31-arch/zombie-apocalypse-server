fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'survival-needs'
description 'Hunger, thirst, medical items, death and respawn, plus the item definitions for the whole server'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts { 'client.lua' }
server_scripts { 'server.lua' }

-- The recipe merges this file into ox_inventory/data/items.lua
files { 'data/items.lua' }

dependencies {
    'ox_lib',
    'ox_inventory',
    'qb-core',
}
