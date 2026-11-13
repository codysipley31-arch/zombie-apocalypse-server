fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'zombie-ai'
description 'Slow zombie AI, detection/chasing, safe zones, night scaling, world cleanup'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'shared.lua',
}

client_scripts {
    'client/zombies.lua',
    'client/world.lua',
}

server_scripts {
    'server/main.lua',
}

dependencies {
    'ox_lib',
    'ox_inventory',
    'qb-core',
}
