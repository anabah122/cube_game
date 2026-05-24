
local skySH = LG.newShader( LF.read('shader/sky.glsl'))
local box = require'importer'.loadOBJ('data/box.obj')[1]

return function()
    skySH:send( 'viewproj', LG.viewProj )
    skySH:send( 'camPos', LG.camPos )
    skySH:send( 'lightPos', LG.lightPos )
    LG.setShader( skySH )
    LG.draw( box )
    
end