local GAME = {}

local camera   = require 'class.camera' :new{ x=0, y=80, z=6 }
LG.camera = camera

local SkyRender = require( ThisDir()        .. '.sky_render')
local TerrainRender = require( ThisDir()    .. '.terrain_render')


LG.lightColor = {1.0, 0.98, 0.8}

local time = 0

function GAME:draw()
    local dt = LT.getDelta()
    time=time+dt*0.1

    camera:update(dt)

    LG.viewProj = camera:viewproj()
    LG.camPos   = camera.pos:get()
    LG.lightPos   = {math.sin( time ), math.cos( time ), 0}

    SkyRender()
    TerrainRender()
    
    LG.setShader()

    LG.setDepthMode('always', false)
    LG.print(LT.realFPS)
end

function GAME:mousemoved(dx, dy) camera:mousemoved(dx, dy) end
function GAME:wheelmoved(dy)     camera:wheelmoved(dy)     end

function GAME:init()
    function love.draw()                GAME:draw() end
    function love.mousemoved(x,y,dx,dy) GAME:mousemoved(dx, dy) end
    function love.wheelmoved(x,y)       GAME:wheelmoved(y) end
end

return GAME
