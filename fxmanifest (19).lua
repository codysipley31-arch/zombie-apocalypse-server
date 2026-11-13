fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'zombie-infection'
description 'Bite infection with progressive stages, cures and reanimation'
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
    'zombie-ai',
}
