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

local stats = { drawn = 0, culled = 0, t = 0 }

return function()
    LG.setDepthMode('lequal', true )
    LG.setShader(meshSH)
    LG.setMeshCullMode('none')

    meshSH:send('viewproj',   LG.viewProj)
    meshSH:send('uvOffsets',  atlas.uvOffsets)
    meshSH:send('cellUV',     atlas.cellUV)
    meshSH:send('atlasCols',  atlas.cols)
    meshSH:send('main_tex',   atlas.texture)
    meshSH:send('lightPos',   LG.lightPos)
    meshSH:send('lightColor', LG.lightColor)
    meshSH:send('camPos',     LG.camPos)

    frustum:update(LG.viewProj)
    local camPos = LG.camPos
    local drawn, culled = 0, 0
    for i = 1, #chunks do
        local ch = chunks[i]
        ch:cull(frustum, camPos)
        if ch.visible then
            drawn = drawn + 1
            LG.draw(ch.mesh)
        else
            culled = culled + 1
        end
    end

    stats.t = stats.t + love.timer.getDelta()
    if stats.t >= 1 then
        stats.t = 0
        print(('[terrain] drawn=%d culled=%d / %d'):format(drawn, culled, #chunks))
    end
end
