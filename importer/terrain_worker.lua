-- importer/terrain_worker.lua
-- Reads .bin chunks, deserializes them, and packs verts/indices into ByteData
-- so the main thread can spawn meshes without re-copying the data.
--
-- Mesh verts: { x, y, z, n0, n1, n2, n3, u, v, mat }   (28 bytes)

require 'love.filesystem'
require 'love.data'
require 'love.timer'

local args   = { ... }
package.path = args[1]

local ffi    = require 'ffi'
local binser = require 'lib.binser'

ffi.cdef[[
typedef struct __attribute__((packed)) {
    float    px, py, pz;
    uint8_t  n0, n1, n2, n3;
    float    u, v;
    float    mat;
} terrain_vert_t;
]]

local MESH_VSIZE = ffi.sizeof('terrain_vert_t')
assert(MESH_VSIZE == 28, 'mesh vertex layout size mismatch')

local jobCh = love.thread.getChannel('terrain_load_jobs')
local resCh = love.thread.getChannel('terrain_load_results')

local function packIndices(inds)
    local nI = #inds
    local iBD = love.data.newByteData(nI * 4)
    local iPtr = ffi.cast('uint32_t*', iBD:getFFIPointer())
    for i = 1, nI do
        iPtr[i - 1] = inds[i] - 1
    end
    return iBD, nI
end

local function packMesh(slice)
    local verts = slice.verts
    local nV = #verts
    local vBD = love.data.newByteData(nV * MESH_VSIZE)
    local vPtr = ffi.cast('terrain_vert_t*', vBD:getFFIPointer())
    for i = 1, nV do
        local s = verts[i]
        local d = vPtr[i - 1]
        d.px  = s[1]; d.py = s[2]; d.pz = s[3]
        d.n0  = s[4]; d.n1 = s[5]; d.n2 = s[6]; d.n3 = s[7]
        d.u   = s[8]; d.v  = s[9]
        d.mat = s[10]
    end
    local iBD, nI = packIndices(slice.indices)
    return { verts = vBD, vcount = nV, inds = iBD, icount = nI }
end

while true do
    local job = jobCh:demand()
    if job == 'STOP' then break end

    local raw  = love.filesystem.read(job.path)
    local data = binser.deserialize(raw)[1]

    resCh:push{
        x = data.x, z = data.z,
        aabb      = data.aabb,
        sphere    = data.sphere,
        collision = data.collision,
        mesh = packMesh(data.mesh),
    }
end
