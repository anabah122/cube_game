-- class/frustum.lua
--
-- Frustum culling: builds 4 side-plane equations (left/right/bottom/top) from a
-- view-projection matrix and tests bounding spheres against them.
--
-- Planes are stored in world space; pass the column-major MVP / viewProj.

local Frustum = {}
Frustum.__index = Frustum

function Frustum:new()
    local f = setmetatable({}, Frustum)
    f.planes = { {0,0,0,0}, {0,0,0,0}, {0,0,0,0}, {0,0,0,0} }
    return f
end

function Frustum:update(M)
    local r0x, r0y, r0z, r0w = M[1],  M[2],  M[3],  M[4]
    local r1x, r1y, r1z, r1w = M[5],  M[6],  M[7],  M[8]
    local r3x, r3y, r3z, r3w = M[13], M[14], M[15], M[16]

    local p = self.planes
    p[1][1], p[1][2], p[1][3], p[1][4] = r3x + r0x, r3y + r0y, r3z + r0z, r3w + r0w  -- left
    p[2][1], p[2][2], p[2][3], p[2][4] = r3x - r0x, r3y - r0y, r3z - r0z, r3w - r0w  -- right
    p[3][1], p[3][2], p[3][3], p[3][4] = r3x + r1x, r3y + r1y, r3z + r1z, r3w + r1w  -- bottom
    p[4][1], p[4][2], p[4][3], p[4][4] = r3x - r1x, r3y - r1y, r3z - r1z, r3w - r1w  -- top
end

function Frustum:testSphere(center, radius)
    local cx, cy, cz = center[1], center[2], center[3]
    local planes = self.planes
    for i = 1, 4 do
        local p = planes[i]
        local nx, ny, nz = p[1], p[2], p[3]
        local px = cx + nx * radius
        local py = cy + ny * radius
        local pz = cz + nz * radius
        if nx * px + ny * py + nz * pz + p[4] < 0 then
            return false
        end
    end
    return true
end

return Frustum
