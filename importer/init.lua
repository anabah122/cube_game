-- importer/init.lua
-- Proxies file formats. Returns raw data tables, no love.graphics.
--
-- loadOBJ(path)  -> { [i] = { name, vertices, indices, textureName } }
-- loadGLTF(path) -> { [i] = { name, vertices, indices, material, trs, ... } }
--
-- vertices: array of { x,y,z, nx,ny,nz, u,v }

local objLoader  = require 'importer.formats.obj'
local gltfLoader = require 'importer.formats.gltf'
local terrainLoader = require 'importer.terrain'

local M = {}

function M.loadOBJ(path)
    return objLoader.load(path)
end

function M.loadGLTF(path)
    return gltfLoader.load({ path = path })
end

function M.terrain(path)
    return terrainLoader.load(path)
end

return M
