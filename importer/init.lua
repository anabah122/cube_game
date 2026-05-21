-- importer/init.lua
-- Импортирует OBJ в набор love.Mesh, готовых к рендеру через shader/main.glsl.
--
-- Формат вершины совпадает с chunk_mesh:
--   VertexPosition (vec3), VertexTexCoord (vec2 localUV), VertexNormal (vec3),
--   VertexTile (vec4: tx,ty,tw,th в нормализованных UV)
--
-- Использование:
--   local importer = require 'importer'
--   local atlas    = require('importer.atlas').load()
--   local meshes   = importer.loadOBJ('models/house.obj', atlas)
--   -- meshes: массив love.Mesh

local objLoader = require 'importer.formats.obj'

local VERTEX_FMT = {
    { 'VertexPosition', 'float', 3 },
    { 'VertexTexCoord', 'float', 2 },
    { 'VertexNormal',   'float', 3 },
    { 'VertexTile',     'float', 4 },
}

local M = {}

function M.loadOBJ(path, atlas)
    local groups = objLoader.load(path)
    local meshes = {}

    for _, g in ipairs(groups) do
        if #g.verts == 0 or #g.indices == 0 then goto skip end

        local tile = atlas:get(g.textureName)
        local tx, ty, tw, th = tile[1], tile[2], tile[3], tile[4]

        local vdata = {}
        for _, v in ipairs(g.verts) do
            -- v = { x,y,z, nx,ny,nz, u,v }
            vdata[#vdata+1] = {
                v[1], v[2], v[3],    -- VertexPosition
                v[7], v[8],          -- VertexTexCoord (localUV; шейдер берёт fract)
                v[4], v[5], v[6],    -- VertexNormal
                tx, ty, tw, th,      -- VertexTile
            }
        end

        local mesh = love.graphics.newMesh(VERTEX_FMT, vdata, 'triangles', 'static')
        mesh:setVertexMap(g.indices)
        mesh:setTexture(atlas.image)

        meshes[#meshes+1] = mesh

        ::skip::
    end

    return meshes
end

return M
