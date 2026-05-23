

local atlas    = LG.newImage('pack/atlas.png')
atlas:setFilter('linear','nearest')

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

local matClass = require 'math.mat4'
local transform = matClass:new():setTransformationMatrix({0,0,0},{0,0,0},{1,1,1})

local meshSH = LG.newShader( LF.read('shader/main.glsl') )

return function( )
    LG.setDepthMode('lequal', true)
    LG.setFrontFaceWinding('cw')
    LG.setShader( meshSH )
    LG.setCanvas( LG.renderSetup ) 

    LG.clear( 0, 0, 0, 0 )

    meshSH:send('viewproj',   LG.viewProj)
    meshSH:send('uvOffsets',  uvOffsets)
    meshSH:send('min_alpha',  0.8)
    meshSH:send('main_tex',   atlas)
    meshSH:send('lightPos',   LG.lightPos)
    meshSH:send('lightColor', LG.lightColor)

    -- main pass 
    LG.setMeshCullMode('back')
    for _,chunk in pairs( terrain ) do
        LG.draw(chunk.mainPass)
    end

    -- no cull pass 
    LG.setMeshCullMode('none')
    for _,chunk in pairs( terrain ) do
        LG.draw(chunk.noCullPass)
    end

    LG.setCanvas()
    LG.setFrontFaceWinding('ccw')

end