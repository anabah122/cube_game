-- Placeholder collision builder.
-- TODO: derive from vertex/index data (e.g. voxel grid, BVH of triangles).
local M = {}

function M.build(vertices, indices, aabb)
    return {
        kind = 'placeholder',
        aabb = aabb,
    }
end

return M
