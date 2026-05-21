local matClass = require 'math.mat4'
local camera   = require 'class.camera' :new{ x=0, y=80, z=6 }
local chunkLib = require 'level.chunk'
local shader   = LG.newShader 'shader/chunk.glsl'

<<<<<<< HEAD
local meshes = chunkLib.load_dir('pack/chunks')
print('meshes loaded:', #meshes)
=======
local atlas    = require('importer.atlas').load()
local importer = require 'importer'

local shader = LG.newShader 'shader/main.glsl'

-- положи свой obj сюда
local meshes = importer.loadOBJ('test.obj', atlas)
>>>>>>> ae4c4a37cd8e2617fd64614a79bb14dffc52d56c

local game = {}


function game:draw()

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

function game:mousemoved(dx, dy) camera:mousemoved(dx, dy) end
function game:wheelmoved(dy)     camera:wheelmoved(dy)     end

function game:init()
    function love.draw()                game:draw() end
    function love.mousemoved(x,y,dx,dy) game:mousemoved(dx, dy) end
    function love.wheelmoved(x,y)       game:wheelmoved(y) end
end

return game
