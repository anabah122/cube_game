-- Chunk: one terrain chunk. Owns mesh/bounds/collision.
-- Culling sets `visible`.

local Chunk = {}
Chunk.__index = Chunk

Chunk.cutDistance = 1500

function Chunk:new(data)
    local c = setmetatable({}, Chunk)
    c.x         = data.x
    c.z         = data.z
    c.mesh      = data.mesh
    c.aabb      = data.aabb
    c.sphere    = data.sphere
    c.collision = data.collision
    c.visible   = true
    return c
end

local function distToCenter(self, camPos)
    local c  = self.sphere.center
    local dx = camPos[1] - c[1]
    local dy = camPos[2] - c[2]
    local dz = camPos[3] - c[3]
    return math.sqrt(dx*dx + dy*dy + dz*dz)
end

function Chunk:cull(frustum, camPos)
    if distToCenter(self, camPos) > self.cutDistance then
        self.visible = false
        return
    end
    self.visible = frustum:testSphere(self.sphere.center, self.sphere.radius)
end

return Chunk
