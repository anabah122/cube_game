-- importer/formats/obj.lua
-- Parses OBJ + MTL. Returns raw data, no love.graphics.
--
-- load(path) -> { [i] = { name, textureName, vertices, indices } }
-- vertices: array of { x,y,z, nx,ny,nz, u,v }

local M = {}

local function parseMtl(path)
    local src = love.filesystem.read(path)
    if not src then return {} end
    local mats = {}
    local cur
    for line in (src .. '\n'):gmatch('([^\n]*)\n') do
        local w = line:match('^%s*newmtl%s+(.+)$')
        if w then
            cur = w:match('^%s*(.-)%s*$')
            mats[cur] = {}
        end
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

function M.load(path)
    local src = assert(love.filesystem.read(path), 'OBJ not found: ' .. path)
    local dir = path:match('^(.+)[/\\]') or ''
    local mats = {}

    local positions = {}
    local normals   = {}
    local texcoords = {}
    local groups    = {}
    local cur

    local function newGroup(name, matName)
        cur = { name = name, matName = matName, vertices = {}, indices = {}, _lookup = {} }
        groups[#groups + 1] = cur
    end

    local function addVert(vi, ti, ni)
        local p = positions[vi]
        local n = normals[ni]   or { 0, 1, 0 }
        local t = texcoords[ti] or { 0, 0 }
        local key = vi .. '/' .. (ti or 0) .. '/' .. (ni or 0)
        local idx = cur._lookup[key]
        if not idx then
            idx = #cur.vertices + 1
            cur.vertices[idx] = { p[1], p[2], p[3], n[1], n[2], n[3], t[1], t[2] }
            cur._lookup[key] = idx
        end
        return idx
    end

    local curMat
    for line in (src .. '\n'):gmatch('([^\n]*)\n') do
        local tag, rest = line:match('^%s*(%S+)%s*(.*)')
        if not tag then goto continue end

        if tag == 'mtllib' then
            local f = rest:match('^%s*(.-)%s*$')
            mats = parseMtl((dir ~= '' and (dir .. '/' .. f) or f))

        elseif tag == 'v' then
            local x, y, z = rest:match('(%S+)%s+(%S+)%s+(%S+)')
            positions[#positions + 1] = { tonumber(x), tonumber(y), tonumber(z) }

        elseif tag == 'vn' then
            local x, y, z = rest:match('(%S+)%s+(%S+)%s+(%S+)')
            normals[#normals + 1] = { tonumber(x), tonumber(y), tonumber(z) }

        elseif tag == 'vt' then
            local u, v = rest:match('(%S+)%s+(%S+)')
            texcoords[#texcoords + 1] = { tonumber(u), 1 - tonumber(v) }

        elseif tag == 'usemtl' then
            curMat = rest:match('^%s*(.-)%s*$')
            newGroup(curMat, curMat)

        elseif tag == 'g' or tag == 'o' then
            if not cur then newGroup(rest, curMat) end

        elseif tag == 'f' then
            if not cur then newGroup('default', curMat) end
            local fverts = {}
            for token in rest:gmatch('%S+') do
                local vi, ti, ni = token:match('^(%d+)/?(%d*)/?(%d*)$')
                fverts[#fverts + 1] = addVert(tonumber(vi), tonumber(ti) or nil, tonumber(ni) or nil)
            end
            for i = 2, #fverts - 1 do
                local idx = cur.indices
                idx[#idx + 1] = fverts[1]
                idx[#idx + 1] = fverts[i]
                idx[#idx + 1] = fverts[i + 1]
            end
        end
        ::continue::
    end

    for _, g in ipairs(groups) do
        g._lookup = nil
        local m = mats[g.matName]
        g.textureName = (m and m.textureName) or g.matName
    end

    return groups
end

return M
