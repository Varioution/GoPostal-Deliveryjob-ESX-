fx_version 'cerulean'
game 'gta5'

lua54 'yes'

description 'GoPostal Deliveryjob (ESX)'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua'
}

dependencies {
    'es_extended',
    'ox_lib',
    'ox_target'
}