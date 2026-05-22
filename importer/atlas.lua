-- importer/atlas.lua
-- Maps material name -> atlas index using pack/atlas_map.json
--
-- Usage:
--   local atlas = require 'importer.atlas'
--   local idx = atlas.index("acacia_planks")  -- returns integer or nil

local json = require 'lib.json'
local M = {}

local _map  -- lazy load

local function load()
    if _map then return end
    local src = assert(love.filesystem.read('pack/atlas_map.json'), 'atlas_map.json not found')
    local data = json.decode(src)
    _map = data.map
end

function M.index(materialName)
    load()
    return _map[materialName]
end

return M
