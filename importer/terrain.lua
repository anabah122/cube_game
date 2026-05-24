-- importer/terrain.lua
--
-- Parallel chunk loader. Workers do IO + binser deserialize + repack into
-- ByteData. Main thread only spawns meshes from the ByteData.

local Chunk = require 'class.chunk'

local M = {}

local WORKERS = 8

local meshFmt = {
    { "VertexPosition", "float", 3 },
    { "VertexNormal",   "byte",  4 },
    { "VertexTexCoord", "float", 2 },
    { "VertexMatIdx",   "float", 1 },
}

local function parseName(filename)
    local x, z = filename:match('^(-?%d+)_(-?%d+)%.bin$')
    if x then return tonumber(x), tonumber(z) end
end

local function buildMesh(slice, tex)
    local m = love.graphics.newMesh(meshFmt, slice.vcount, 'triangles', 'static')
    m:setVertices(slice.verts)
    m:setVertexMap(slice.inds, 'uint32')
    if tex then m:setTexture(tex) end
    return m
end

function M.load(args)
    local dir = args.path
    local tex = args.tex

    local files = {}
    for _, filename in ipairs(love.filesystem.getDirectoryItems(dir)) do
        if parseName(filename) then
            files[#files + 1] = dir .. '/' .. filename
        end
    end

    local jobCh = love.thread.getChannel('terrain_load_jobs')
    local resCh = love.thread.getChannel('terrain_load_results')
    jobCh:clear(); resCh:clear()

    for i = 1, #files do jobCh:push{ path = files[i] } end
    for i = 1, WORKERS do jobCh:push('STOP') end

    local threads = {}
    for w = 1, WORKERS do
        local th = love.thread.newThread('importer/terrain_worker.lua')
        th:start(package.path)
        threads[w] = th
    end

    local chunks = {}
    local totalVerts = 0
    for i = 1, #files do
        local d = resCh:demand()
        local ch = Chunk:new{
            x         = d.x,
            z         = d.z,
            mesh      = buildMesh(d.mesh, tex),
            aabb      = d.aabb,
            sphere    = d.sphere,
            collision = d.collision,
        }
        chunks[#chunks + 1] = ch
        totalVerts = totalVerts + d.mesh.vcount
    end

    for w = 1, WORKERS do
        local err = threads[w]:getError()
        if err then print('[terrain] worker error: ' .. err) end
        threads[w]:wait()
    end

    print(('[terrain] chunks=%d verts=%d (parallel %d workers)'):format(#chunks, totalVerts, WORKERS))
    return chunks
end

return M
