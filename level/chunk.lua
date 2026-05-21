local VERTEX_FMT = {
    { 'VertexPosition', 'float', 3 },
    { 'VertUv',         'float', 2 },
    { 'VertNormal',     'float', 3 },
    { 'VertMat',        'float', 1 },
}

local function load_dir(dir)
    local meshes = {}
    for _, name in ipairs(love.filesystem.getDirectoryItems(dir)) do
        if name:match('%.lua$') then
            local mod  = dir:gsub('/', '.') .. '.' .. name:gsub('%.lua$', '')
            local data = require(mod)
            local mesh = love.graphics.newMesh(VERTEX_FMT, data.verts, 'triangles', 'static')
            mesh:setVertexMap(data.imap)
            meshes[#meshes+1] = mesh
        end
    end
    return meshes
end

return { load_dir = load_dir }
