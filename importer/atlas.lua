-- importer/atlas.lua
-- Загружает atlas_map.json и даёт UV-прямоугольник тайла по имени текстуры.
-- Возвращает: { tx, ty, tw, th } в нормализованных UV [0..1].

local json = require 'lib.json'

local M = {}

function M.load(atlasImagePath, atlasMapPath)
    local mapData = assert(love.filesystem.read(atlasMapPath or 'texture_pack/atlas_map.json'))
    local info    = json.decode(mapData)

    local image = love.graphics.newImage(atlasImagePath or 'texture_pack/atlas.png')
    image:setFilter('nearest', 'nearest')
    image:setWrap('clamp', 'clamp')

    local iw   = image:getWidth()
    local ih   = image:getHeight()
    local cell = info.cell   -- размер ячейки с отступом (18)
    local tile = info.tile   -- размер тайла без отступа (16)
    local cols = info.cols

    -- нормализованный размер тайла (одинаков для всех)
    local tw = tile / iw
    local th = tile / ih

    local uvs = {}
    for name, idx in pairs(info.map) do
        local col = idx % cols
        local row = math.floor(idx / cols)
        -- +1 пиксель = pad
        local px = col * cell + 1
        local py = row * cell + 1
        uvs[name] = { px / iw, py / ih, tw, th }
    end

    -- fallback: первый тайл (0,0)
    local fallback = { 1/iw, 1/ih, tw, th }

    return {
        image    = image,
        tileSize = tile,
        uvs      = uvs,
        fallback = fallback,
        get = function(self, name)
            if self.uvs[name] then return self.uvs[name] end
            -- ищем тайл, чьё имя входит в name как подстрока с начала
            local best, bestLen = nil, 0
            for atlasName, uv in pairs(self.uvs) do
                if name:sub(1, #atlasName) == atlasName and #atlasName > bestLen then
                    best, bestLen = uv, #atlasName
                end
            end
            return best or self.fallback
        end,
    }
end

return M
