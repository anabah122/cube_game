-- LOD builder: cluster-decimates the mesh (positions only) and adds a vertical
-- skirt along the chunk's XZ-rim to hide cracks between LODs.
--
-- LOD vertex layout: { x, y, z }  (no normals, no uv, no material)

local M = {}
local floor, huge = math.floor, math.huge

M.SKIRT_Y       = -254
M.SKIRT_OVERLAP = 1

function M.build(vertices, indices, cell)
    local cluster = {}
    local lv, li = {}, {}
    local cells = {}
    local nLv, nLi = 0, 0

    local function clusterOf(vIdx)
        local v = vertices[vIdx]
        local cx = floor(v[1] / cell)
        local cy = floor(v[2] / cell)
        local cz = floor(v[3] / cell)
        local key = cx * 1099511627776 + cy * 1048576 + cz
        local id = cluster[key]
        if id then return id end
        nLv = nLv + 1
        lv[nLv] = {
            cx * cell + cell * 0.5,
            cy * cell + cell * 0.5,
            cz * cell + cell * 0.5,
        }
        cells[nLv] = { cx, cz }
        cluster[key] = nLv
        return nLv
    end

    for i = 1, #indices, 3 do
        local a = clusterOf(indices[i])
        local b = clusterOf(indices[i + 1])
        local c = clusterOf(indices[i + 2])
        if a ~= b and b ~= c and a ~= c then
            li[nLi + 1] = a
            li[nLi + 2] = b
            li[nLi + 3] = c
            nLi = nLi + 3
        end
    end

    if nLi == 0 then return nil, nil end

    local minCX, maxCX =  huge, -huge
    local minCZ, maxCZ =  huge, -huge
    for i = 1, nLv do
        local cx, cz = cells[i][1], cells[i][2]
        if cx < minCX then minCX = cx end
        if cx > maxCX then maxCX = cx end
        if cz < minCZ then minCZ = cz end
        if cz > maxCZ then maxCZ = cz end
    end

    local push = M.SKIRT_OVERLAP
    local skirtY = M.SKIRT_Y

    local function addQuad(x1, z1, x2, z2, yTop)
        local i1 = nLv + 1; lv[i1] = { x1, yTop,   z1 }
        local i2 = nLv + 2; lv[i2] = { x2, yTop,   z2 }
        local i3 = nLv + 3; lv[i3] = { x2, skirtY, z2 }
        local i4 = nLv + 4; lv[i4] = { x1, skirtY, z1 }
        nLv = nLv + 4
        li[nLi + 1] = i1; li[nLi + 2] = i2; li[nLi + 3] = i3
        li[nLi + 4] = i1; li[nLi + 5] = i3; li[nLi + 6] = i4
        nLi = nLi + 6
    end

    local half = cell * 0.5
    local origNLv = nLv
    for i = 1, origNLv do
        local cx, cz = cells[i][1], cells[i][2]
        local v = lv[i]
        local x, y, z = v[1], v[2], v[3]

        if cx == minCX then
            addQuad(x - half - push, z + half,
                    x - half - push, z - half, y)
        end
        if cx == maxCX then
            addQuad(x + half + push, z - half,
                    x + half + push, z + half, y)
        end
        if cz == minCZ then
            addQuad(x - half, z - half - push,
                    x + half, z - half - push, y)
        end
        if cz == maxCZ then
            addQuad(x + half, z + half + push,
                    x - half, z + half + push, y)
        end
    end

    return lv, li
end

return M
