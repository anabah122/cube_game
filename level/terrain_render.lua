local Frustum = require 'class.frustum'

local atlas  = require 'importer.atlas'.load{
    image = 'pack/atlas.png',
    map   = 'pack/atlas_map.json',
}
local chunks = require 'importer.terrain'.load{
    path = 'chunks',
    tex  = atlas.texture,
}

local frustum = Frustum:new()
local meshSH  = LG.newShader(LF.read('shader/main.glsl'))
local lodSH   = LG.newShader(LF.read('shader/lod.glsl'))

local w, h = LG.getDimensions()
local meshColor = LG.newCanvas(w, h)
local meshDepth = LG.newCanvas(w, h, { format = 'depth24', readable = true })
local lodColor  = LG.newCanvas(w, h)
local lodDepth  = LG.newCanvas(w, h, { format = 'depth24', readable = true })

local meshSetup = { meshColor, depth = true, depthstencil = meshDepth }
local lodSetup  = { lodColor,  depth = true, depthstencil = lodDepth  }

local LOD_START = 520     -- must match Chunk.switchDistance - Chunk.overlap-ish
local LOD_END   = 760     -- past this, mesh is fully gone / lod fully opaque

local stats = { drawn = 0, culled = 0, t = 0 }


local function DrawChunks()
    -- pass 1: full-detail chunks
    LG.setCanvas(meshSetup)
    LG.clear(0, 0, 0, 0)
    LG.setShader(meshSH)
    meshSH:send('viewproj',   LG.viewProj)
    meshSH:send('uvOffsets',  atlas.uvOffsets)
    meshSH:send('cellUV',     atlas.cellUV)
    meshSH:send('atlasCols',  atlas.cols)
    meshSH:send('main_tex',   atlas.texture)
    meshSH:send('lightPos',   LG.lightPos)
    meshSH:send('lightColor', LG.lightColor)
    meshSH:send('camPos',     LG.camPos)
    meshSH:send('lodStart',   LOD_START)
    meshSH:send('lodEnd',     LOD_END)
    for i = 1, #chunks do
        local ch = chunks[i]
        if ch.visible and ch.drawMesh then LG.draw(ch.mesh) end
    end
end

local function DrawLoads()
    -- pass 2: lods
    LG.setCanvas(lodSetup)
    LG.clear(0, 0, 0, 0)
    LG.setShader(lodSH)
    lodSH:send('viewproj', LG.viewProj)
    lodSH:send('camPos',   LG.camPos)
    lodSH:send('lightPos', LG.lightPos)
    lodSH:send('lightColor', LG.lightColor)
    lodSH:send('lodStart',   LOD_START)
    lodSH:send('lodEnd',     LOD_END)
    for i = 1, #chunks do
        local ch = chunks[i]
        if ch.visible and ch.drawLod then LG.draw(ch.lod) end
    end
end


return function()
    frustum:update(LG.viewProj)
    local camPos = LG.camPos
    local drawn, culled = 0, 0
    for i = 1, #chunks do
        local ch = chunks[i]
        ch:cull(frustum, camPos)
        if ch.visible then drawn = drawn + 1 else culled = culled + 1 end
    end

    LG.setDepthMode('lequal', true)
    LG.setMeshCullMode('none')


    DrawChunks()
    --DrawLoads()

    -- composite into the screen
    LG.setCanvas()
    LG.setShader()
    LG.setDepthMode('always', false)
    LG.setBlendMode('alpha')
    LG.draw(lodColor,  0, h, 0, 1, -1)
    LG.draw(meshColor, 0, h, 0, 1, -1)

    stats.t = stats.t + love.timer.getDelta()
    if stats.t >= 1 then
        stats.t = 0
        print(('[terrain] drawn=%d culled=%d / %d'):format(drawn, culled, #chunks))
    end
end
