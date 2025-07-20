fx_version 'cerulean'
game 'gta5'

author 'GuilhermeDuck04(GHOST)'
description 'Ghost-HUD for VRPex'
version '1.0.0'

client_scripts {
    'client/main.lua',
    'client/voip.lua',
    'client/minimap.lua',
    'client/config.lua'
}

server_scripts {
    '@vrp/lib/utils.lua',
    'config.lua',
    'server.lua'
}

shared_script 'config.lua'

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