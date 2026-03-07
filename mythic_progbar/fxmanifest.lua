client_script "@bt_defender/module/client.lua"

fx_version 'adamant'

game 'gta5'

ui_page('html/index.html') 

client_scripts {
    'client/main.lua'
}

files {
    'html/index.html',
    'html/css/style.css',
    'html/js/script.js',
    'html/Vector.svg'
}

exports {
    'Progress',
    'ProgressWithStartEvent',
    'ProgressWithTickEvent',
    'ProgressWithStartAndTick'
}

lua54 'yes'