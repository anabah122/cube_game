-- Single-pass OBJ scanner for jmc2obj output.
-- Returns:
--   v    : { {x,y,z}, ... }  global vertex positions
--   vt   : { {u,v},  ... }   global texcoords (v flipped)
--   srcs : array of { x, z, faces = {{matIdx, faceLine}, ...} }

local M = {}

local find, sub, byte, match = string.find, string.sub, string.byte, string.match
local tonumber = tonumber

local function parse_chunk_header(line)
    local x, z = match(line, '^o chunk_(-?%d+)_(-?%d+)')
    if x then return tonumber(x), tonumber(z) end
end

function M.scan(src, materialResolve)
    local len = #src
    local pos = 1

    local v, vt = {}, {}
    local srcs = {}
    local cur
    local curMat = 0

    while pos <= len do
        local nl = find(src, '\n', pos, true) or (len + 1)
        local b = byte(src, pos)

        if b == 118 then -- 'v'
            local b2 = byte(src, pos + 1)
            if b2 == 32 then -- "v "
                local x, y, z = match(sub(src, pos + 2, nl - 1), '(%S+)%s+(%S+)%s+(%S+)')
                v[#v + 1] = { tonumber(x), tonumber(y), tonumber(z) }
            elseif b2 == 116 then -- "vt"
                local u, w = match(sub(src, pos + 3, nl - 1), '(%S+)%s+(%S+)')
                vt[#vt + 1] = { tonumber(u), 1 - tonumber(w) }
            end

        elseif b == 111 then -- 'o'
            local cx, cz = parse_chunk_header(sub(src, pos, nl - 1))
            if cx then
                cur = { x = cx, z = cz, faces = {} }
                srcs[#srcs + 1] = cur
                curMat = 0
            end

        elseif b == 117 then -- usemtl
            if sub(src, pos, pos + 5) == 'usemtl' then
                local name = match(sub(src, pos + 7, nl - 1), '^%s*(.-)%s*$')
                curMat = materialResolve(name) or 0
            end

        elseif b == 102 then -- 'f'
            if cur then
                cur.faces[#cur.faces + 1] = { curMat, sub(src, pos + 2, nl - 1) }
            end
        end

        pos = nl + 1
    end

    return v, vt, srcs
end

return M
