-- importer/atlas.lua
--
-- Two faces of the same atlas:
--   M.index(materialName)        -- material name -> atlas index (existing helper)
--   M.load{ image, map }         -- texture + shader uniforms bundle

local json = require 'lib.json'
local M = {}

local _map  -- lazy-loaded for M.index

local function ensureMap()
    if _map then return end
    local src = assert(love.filesystem.read('pack/atlas_map.json'), 'atlas_map.json not found')
    _map = json.decode(src).map
end

function M.index(materialName)
    ensureMap()
    return _map[materialName]
end

function M.load(args)
    local tex = love.graphics.newImage(args.image)
    tex:setFilter('linear', 'nearest')

    local map = json.decode(love.filesystem.read(args.map))
    local w = tex:getWidth()

    return {
        texture   = tex,
        map       = map,
        pad       = map.pad,
        cell      = map.cell,
        uvOffsets = {
            map.pad / w,
            (map.cell - 2 * map.pad) / w,
        },
        cellUV    = map.cell / w,
        cols      = math.floor(w / map.cell + 0.5),
    }
end

return M
