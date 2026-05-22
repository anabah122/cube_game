local GAME = {}

local shader = LG.newShader( LF.read('shader/main.glsl') )
local camera   = require 'class.camera' :new{ x=0, y=80, z=6 }

local matClass = require 'math.mat4'
local transform = matClass:new()


local atlas    = LG.newImage('pack/atlas.png')
atlas:setFilter('nearest','linear')

local atlasMap = json.decode(LF.read('pack/atlas_map.json'))
local uvOffsets = {
    atlasMap.pad / atlas:getWidth(),
    (atlasMap.cell - 2 * atlasMap.pad) / atlas:getWidth(),
}

local terrain = require'importer.terrain'.load{
    path = 'chunks',
    tex  = atlas,
    map  = atlasMap,
}


function GAME:draw()

    local dt = LT.getDelta()
    camera:update(dt)

    LG.setDepthMode('lequal', true)
    LG.setMeshCullMode('back')

    shader:send('viewproj',   camera:viewproj())
    shader:send('uvOffsets',  uvOffsets)
    LG.setShader(shader)

    for _,chunk in pairs( terrain ) do
        transform:setTransformationMatrix({chunk.x,0,chunk.z},{0,0,0},{1,1,1})
        shader:send('transform',transform)
        LG.draw(chunk.mesh)
    end

    LG.setShader()
    LG.setDepthMode('always', false)
    LG.setMeshCullMode('none')

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
