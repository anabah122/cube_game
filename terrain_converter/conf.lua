function love.conf(t)
    t.identity        = 'terrain_converter'
    t.window          = nil
    t.modules.window  = false
    t.modules.graphics= false
    t.modules.audio   = false
    t.modules.sound   = false
    t.modules.physics = false
    t.modules.joystick= false
    t.modules.touch   = false
    t.modules.video   = false
    t.console         = false
end
