local GAME = {}

local matClass = require 'math.mat4'
local camera   = require 'class.camera' :new{ x=0, y=80, z=6 }
local meshes = {}


function GAME:draw()

    love.graphics.setWireframe( true )
    local dt = LT.getDelta()
    camera:update(dt)

    LG.setDepthMode('lequal', true)
    LG.setMeshCullMode('back')

    local identity = matClass:new():setTransformationMatrix({0,0,0},{0,0,0,1},{1,1,1})
    shader:send('viewproj',  camera:viewproj())
    shader:send('transform', identity)
    LG.setShader(shader)

    for _, mesh in ipairs(meshes) do
        LG.draw(mesh)
    end

    LG.setShader()
    LG.setDepthMode('always', false)
    LG.setMeshCullMode('none')
    love.graphics.setWireframe( false )

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
