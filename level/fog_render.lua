local fogSH = LG.newShader( LF.read('shader/fog.glsl') )


return function()
    LG.setShader( fogSH )

    fogSH:send( 'camPos',      LG.camPos )
    fogSH:send( 'lightPos',   LG.lightPos )
    fogSH:send( 'lightColor', LG.lightColor )
    
    LG.draw( LG.renderSetup.posCanv, 0, LG.getHeight(), 0, 1, -1 )
end