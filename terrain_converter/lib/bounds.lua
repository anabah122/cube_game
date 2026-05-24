-- AABB + bounding sphere from a vertex list.
local M = {}
local sqrt, huge = math.sqrt, math.huge

function M.compute(vertices)
    if #vertices == 0 then
        return { min = {0,0,0}, max = {0,0,0} }, { center = {0,0,0}, radius = 0 }
    end

    local minx, miny, minz =  huge,  huge,  huge
    local maxx, maxy, maxz = -huge, -huge, -huge
    for i = 1, #vertices do
        local v = vertices[i]
        local x, y, z = v[1], v[2], v[3]
        if x < minx then minx = x end
        if y < miny then miny = y end
        if z < minz then minz = z end
        if x > maxx then maxx = x end
        if y > maxy then maxy = y end
        if z > maxz then maxz = z end
    end

    local cx = (minx + maxx) * 0.5
    local cy = (miny + maxy) * 0.5
    local cz = (minz + maxz) * 0.5
    local dx = maxx - cx
    local dy = maxy - cy
    local dz = maxz - cz
    local radius = sqrt(dx*dx + dy*dy + dz*dz)

    return { min = {minx, miny, minz}, max = {maxx, maxy, maxz} },
           { center = {cx, cy, cz}, radius = radius }
end

return M
