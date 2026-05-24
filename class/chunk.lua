-- Chunk: one terrain chunk. Owns mesh/lod/bounds/collision.
-- Culling sets `visible`. Distance to camera defines a blend zone between
-- the full mesh and the coarse lod:
--   d <= switchDistance                       -> mesh only
--   switchDistance < d < switchDistance+OVER  -> mesh + lod (cross-fade)
--   d >= switchDistance + OVER                -> lod only
--   d >  cutDistance                          -> not drawn

local Chunk = {}
Chunk.__index = Chunk

Chunk.switchDistance = 520
Chunk.overlap        = 120
Chunk.cutDistance    = 1500

function Chunk:new(data)
    local c = setmetatable({}, Chunk)
    c.x         = data.x
    c.z         = data.z
    c.mesh      = data.mesh
    c.lod       = data.lod
    c.aabb      = data.aabb
    c.sphere    = data.sphere
    c.collision = data.collision
    c.visible   = true
    c.drawMesh  = true
    c.drawLod   = false
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
    local d = distToCenter(self, camPos)
    if d > self.cutDistance then
        self.visible = false
        return
    end
    self.visible = frustum:testSphere(self.sphere.center, self.sphere.radius)
    -- overlap zone: both passes draw and cross-fade in shader by per-pixel distance
    self.drawMesh = d <  self.switchDistance + self.overlap
    self.drawLod  = d >= self.switchDistance - self.overlap
end

return Chunk
