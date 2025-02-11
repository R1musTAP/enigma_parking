fx_version 'cerulean'
game 'gta5'

author 'R1musTAP'
description 'Realistic Parking System for QBCore'
version '1.0.0'

shared_scripts {
    '@qb-core/shared/locale.lua',
    'locales/en.lua', -- Añadir más idiomas según sea necesario
    'config.lua'
}

client_scripts {
    '@PolyZone/client.lua',
    '@PolyZone/BoxZone.lua',
    '@PolyZone/EntityZone.lua',
    '@PolyZone/CircleZone.lua',
    '@PolyZone/ComboZone.lua',
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

dependencies {
    'qb-core',
    'oxmysql',
    'PolyZone',
    --'anigma_autoshop',
    'LegacyFuel'
}

lua54 'yes'