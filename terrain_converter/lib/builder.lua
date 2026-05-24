-- Build deduplicated verts + indices for one my-chunk (a group of source 16-chunks).
-- Vertex layout matches importer/formats/objTerrain.lua:
--   { x, y, z, normalSnap(0..7), 0, 0, 0, u, v, matIdx }

local M = {}

local match, gmatch = string.match, string.gmatch
local tonumber = tonumber
local abs = math.abs

local function snapNormalFromTri(p1, p2, p3)
    local ax, ay, az = p2[1]-p1[1], p2[2]-p1[2], p2[3]-p1[3]
    local bx, by, bz = p3[1]-p1[1], p3[2]-p1[2], p3[3]-p1[3]
    local nx = ay*bz - az*by
    local ny = az*bx - ax*bz
    local nz = ax*by - ay*bx
    local aax, aay, aaz = abs(nx), abs(ny), abs(nz)
    if aay >= aax and aay >= aaz then
        return ny >= 0 and 2 or 3
    end
    if aax > 0.25 and aaz > 0.25 then
        if (nx >= 0) == (nz >= 0) then return 6 else return 7 end
    end
    if aax >= aaz then
        return nx >= 0 and 0 or 1
    else
        return nz >= 0 and 4 or 5
    end
end

-- srcList: list of { x, z, faces }
-- vPool, vtPool: global pools from objparse.scan
function M.build(srcList, vPool, vtPool)
    local vertices, indices, lookup = {}, {}, {}
    local nVerts, nInd = 0, 0
    local K1, K2, K3 = 2^42, 2^28, 2^14

    local fv_p, fv_t = {}, {}

    for s = 1, #srcList do
        local faces = srcList[s].faces
        for fi = 1, #faces do
            local matIdx = faces[fi][1]
            local line   = faces[fi][2]

            local fc = 0
            for tok in gmatch(line, '%S+') do
                fc = fc + 1
                local vi, ti = match(tok, '^(%d+)/?(%d*)')
                fv_p[fc] = tonumber(vi)
                fv_t[fc] = tonumber(ti)
            end

            if fc >= 3 then
                local p1 = vPool[fv_p[1]]
                local p2 = vPool[fv_p[2]]
                local p3 = vPool[fv_p[3]]
                local nSnap = snapNormalFromTri(p1, p2, p3)

                local first_idx, prev_idx
                for vi = 1, fc do
                    local gvi = fv_p[vi]
                    local ti  = fv_t[vi] or 0
                    local key = gvi * K1 + ti * K2 + nSnap * K3 + matIdx
                    local idx = lookup[key]
                    if not idx then
                        local p = vPool[gvi]
                        local t = ti ~= 0 and vtPool[ti] or { 0, 0 }
                        nVerts = nVerts + 1
                        vertices[nVerts] = { p[1], p[2], p[3], nSnap, 0, 0, 0, t[1], t[2], matIdx }
                        lookup[key] = nVerts
                        idx = nVerts
                    end
                    if vi == 1 then
                        first_idx = idx
                    elseif vi == 2 then
                        prev_idx = idx
                    else
                        indices[nInd + 1] = first_idx
                        indices[nInd + 2] = prev_idx
                        indices[nInd + 3] = idx
                        nInd = nInd + 3
                        prev_idx = idx
                    end
                end
            end
        end
    end

    return vertices, indices
end

return M
