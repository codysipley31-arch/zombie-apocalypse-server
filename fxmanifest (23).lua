fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'zombie-hordes'
description 'Roaming hordes and static horde nests (military bases, towns, bunkers)'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts { 'client.lua' }
server_scripts { 'server.lua' }

dependencies {
    'ox_lib',
    'zombie-ai',
}
