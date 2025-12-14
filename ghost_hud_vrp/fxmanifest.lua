fx_version 'cerulean'
game 'gta5'

author 'GuilhermeDuck04(GHOST)'
description 'Ghost-HUD for VRPex'
version '1.0.0'

lua54 'yes'

client_scripts {
    'client/config.lua', -- Adicionei o config aqui, antes do main
    'client/main.lua',
}

server_scripts {
    '@vrp/lib/utils.lua',
    'server/server.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/config.js',
    'html/images/*.png',
    'stream/minimap.gfx'
}

dependencies {
    'pma-voice',
    'vrp'
}

data_file 'DLC_ITYP_REQUEST' 'stream/minimap.gfx'