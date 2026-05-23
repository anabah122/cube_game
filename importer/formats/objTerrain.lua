local M = {}
local passList = require 'importer.terrain_pass_list'

local fmt = {
    { "VertexPosition", "float", 3 },
    { "VertexNormal",   "float", 3 },
    { "VertexTexCoord", "float", 2 },
    { "VertexCellUV",   "float", 2 },
}

local function parseMtl(path)
    local src = love.filesystem.read(path)
    if not src then return {} end
    local mats, cur = {}, nil
    for line in (src .. '\n'):gmatch('([^\n]*)\n') do
        local w = line:match('^%s*newmtl%s+(.+)$')
        if w then cur = w:match('^%s*(.-)%s*$'); mats[cur] = {} end
        local tex = line:match('^%s*map_Kd%s+(.+)$')
        if tex and cur then
            local name = tex:match('^%s*(.-)%s*$')
            name = name:match('([^/\\]+)$') or name
            name = name:match('^(.+)%..+$') or name
            mats[cur].textureName = name
        end
    end
    return mats
end

function M.load(path, atlasMap, atlasW)
    local src = assert(love.filesystem.read(path), 'OBJ not found: ' .. path)
    local dir = path:match('^(.+)[/\\]') or ''
    local mats = {}

    local positions, normals, texcoords = {}, {}, {}
    local vertices, indices, indicesNoCull, lookup = {}, {}, {}, {}
    local curMat = ''
    local curTexName = ''

    local cellUV = atlasMap.cell / atlasW
    local cols   = math.floor(atlasW / atlasMap.cell + 0.5)

    local function getCellUV(matName)
        local name = matName:gsub('^minecraft_%a+%-', '')
        local idx = atlasMap.map[name]
        if not idx then idx = 0 end
        local col = idx % cols
        local row = math.floor(idx / cols)
        return col * cellUV, row * cellUV
    end

    local function addVert(vi, ti, ni, matName)
        local cu, cv = getCellUV(matName)
        local key = vi .. '/' .. (ti or 0) .. '/' .. (ni or 0) .. '/' .. matName
        if not lookup[key] then
            local p = positions[vi]
            local n = normals[ni]   or { 0, 1, 0 }
            local t = texcoords[ti] or { 0, 0 }
            lookup[key] = #vertices + 1
            vertices[#vertices + 1] = { p[1], p[2], p[3], n[1], n[2], n[3], t[1], t[2], cu, cv }
        end
        return lookup[key]
    end

    for line in (src .. '\n'):gmatch('([^\n]*)\n') do
        local tag, rest = line:match('^%s*(%S+)%s*(.*)')
        if not tag then goto continue end
        if tag == 'mtllib' then
            mats = parseMtl((dir ~= '' and (dir .. '/' .. rest:match('^%s*(.-)%s*$')) or rest:match('^%s*(.-)%s*$')))
        elseif tag == 'v' then
            local x,y,z = rest:match('(%S+)%s+(%S+)%s+(%S+)')
            positions[#positions+1] = { tonumber(x), tonumber(y), tonumber(z) }
        elseif tag == 'vn' then
            local x,y,z = rest:match('(%S+)%s+(%S+)%s+(%S+)')
            normals[#normals+1] = { tonumber(x), tonumber(y), tonumber(z) }
        elseif tag == 'vt' then
            local u,v = rest:match('(%S+)%s+(%S+)')
            texcoords[#texcoords+1] = { tonumber(u), 1 - tonumber(v) }
        elseif tag == 'usemtl' then
            curMat = rest:match('^%s*(.-)%s*$')
            local name = curMat:gsub('^minecraft_%a+%-', '')
            curTexName = name
        elseif tag == 'f' then
            local fv = {}
            for token in rest:gmatch('%S+') do
                local vi,ti,ni = token:match('^(%d+)/?(%d*)/?(%d*)$')
                fv[#fv+1] = addVert(tonumber(vi), tonumber(ti) or nil, tonumber(ni) or nil, curMat)
            end
            local dst = passList.no_cull[curTexName] and indicesNoCull or indices
            for i = 2, #fv - 1 do
                dst[#dst+1] = fv[1]
                dst[#dst+1] = fv[i]
                dst[#dst+1] = fv[i+1]
            end
        end
        ::continue::
    end

    local mainMesh = love.graphics.newMesh(fmt, vertices, 'triangles')
    mainMesh:setVertexMap(indices)

    local noCullMesh = love.graphics.newMesh(fmt, vertices, 'triangles')
    noCullMesh:setVertexMap(indicesNoCull)

    return mainMesh, noCullMesh
end

return M
