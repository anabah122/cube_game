-- Worker thread: pulls my-chunk jobs, builds mesh+lods+bounds+collision, writes binary.
require 'love.filesystem'
require 'love.timer'

local args        = { ... }
local workerId    = args[1]
local outDirAbs   = args[2]   -- absolute path
local lodCellsStr = args[3]
local pkgPath     = args[4]

package.path = pkgPath

local binser    = require 'lib.binser'
local builder   = require 'lib.builder'
local lod       = require 'lib.lod'
local bounds    = require 'lib.bounds'
local collision = require 'lib.collision'

local lodCells = {}
for n in lodCellsStr:gmatch('[^,]+') do lodCells[#lodCells+1] = tonumber(n) end

local jobCh = love.thread.getChannel('jobs')
local resCh = love.thread.getChannel('results')
local vCh   = love.thread.getChannel('v')
local vtCh  = love.thread.getChannel('vt')

local function peekPool(ch, name)
    local raw = ch:peek()
    assert(raw, name .. ' pool not posted')
    return binser.deserialize(raw)[1]
end
local vPool  = peekPool(vCh,  'v')
local vtPool = peekPool(vtCh, 'vt')

local function writeFileRaw(path, data)
    local f, err = io.open(path, 'wb')
    if not f then return false, err end
    f:write(data)
    f:close()
    return true
end

local function buildOne(myX, myZ, srcList)
    local verts, inds = builder.build(srcList, vPool, vtPool)
    local aabb, sphere = bounds.compute(verts)

    local function pack(v, i) return { verts = v, indices = i } end

    local chunk = {
        x         = myX,
        z         = myZ,
        mesh      = pack(verts, inds),
        aabb      = aabb,
        sphere    = sphere,
        collision = collision.build(verts, inds, aabb),
    }

    local lv, li = lod.build(verts, inds, lodCells[1])
    chunk.lod = lv and pack(lv, li) or chunk.mesh

    return chunk
end

while true do
    local job = jobCh:demand()
    if job == 'STOP' then break end

    local t0 = love.timer.getTime()
    local ok, chunkOrErr = pcall(buildOne, job.x, job.z, job.srcList)
    if not ok then
        resCh:push({ ok = false, x = job.x, z = job.z, err = chunkOrErr })
    else
        local chunk = chunkOrErr
        if #chunk.mesh.verts == 0 then
            resCh:push({ ok = true, skipped = true, x = job.x, z = job.z, worker = workerId })
        else
            local blob = binser.serialize(chunk)
            local path = outDirAbs .. '/' .. job.x .. '_' .. job.z .. '.bin'
            local wok, werr = writeFileRaw(path, blob)
            if not wok then
                resCh:push({ ok = false, x = job.x, z = job.z, err = werr })
            else
                resCh:push({
                    ok    = true,
                    x     = job.x, z = job.z,
                    verts = #chunk.mesh.verts,
                    tris  = #chunk.mesh.indices / 3,
                    bytes = #blob,
                    dt    = love.timer.getTime() - t0,
                    worker= workerId,
                })
            end
        end
    end
end
