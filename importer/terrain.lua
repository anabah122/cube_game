local objLoader = require 'importer.formats.objTerrain'

local M = {}

local function parse_name(filename)
    local x, z = filename:match('^opt_chunk_(-?%d+)_(-?%d+)%.obj$')
    if x then return tonumber(x), tonumber(z) end
end

function M.load( args )
    local dir = args.path 
    local tex = args.tex
    
    local chunks = {}
    local files = love.filesystem.getDirectoryItems(dir)
    for _, filename in ipairs(files) do
        local x, z = parse_name(filename)
        if x then
            local mainMesh, noCullMesh = objLoader.load(dir .. '/' .. filename, args.map, args.tex:getWidth())
            mainMesh:setTexture( tex )
            noCullMesh:setTexture( tex )
            chunks[x .. '_' .. z] = {x=x, z=z, mainPass=mainMesh, noCullPass=noCullMesh}
        end
    end
    return chunks
end

return M
