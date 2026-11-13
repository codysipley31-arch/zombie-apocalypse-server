fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'survival-looting'
description 'Lootable props, military bunkers, supply drops, vehicle scavenging and fuel'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'client/looting.lua',
    'client/vehicles.lua',
    'client/airdrops.lua',
}

server_scripts {
    'server/main.lua',
}

dependencies {
    'ox_lib',
    'ox_inventory',
    'qb-core',
    'qb-target',
    'zombie-ai',
}
