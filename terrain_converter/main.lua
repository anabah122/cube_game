-- Terrain OBJ -> binary converter (love-based, parallel).
-- Run from project root:  love terrain_converter
--
-- Pipeline:
--   1. Read minecraft.obj fully (raw io).
--   2. Single-pass scan -> vt pool + per-source-chunk records.
--   3. Group source chunks by floor(x/G), floor(z/G) into my-chunks.
--   4. Spawn N workers; push one job per my-chunk.
--   5. Workers build verts/inds + LODs + bounds + collision, write chunks/X_Z.bin.

local cfg      = require 'config'
local binser   = require 'lib.binser'
local objparse = require 'lib.objparse'

local floor = math.floor

local function readFileRaw(path)
    local f, err = io.open(path, 'rb')
    assert(f, 'cannot open ' .. path .. ': ' .. tostring(err))
    local data = f:read('*a')
    f:close()
    return data
end

local function writeFileRaw(path, data)
    local f, err = io.open(path, 'wb')
    assert(f, 'cannot open ' .. path .. ': ' .. tostring(err))
    f:write(data)
    f:close()
end

local function ensureDir(path)
    -- love.filesystem can't write outside save dir; use OS mkdir.
    if love.system.getOS() == 'Windows' then
        os.execute('if not exist "' .. path .. '" mkdir "' .. path .. '"')
    else
        os.execute('mkdir -p "' .. path .. '"')
    end
end

local function loadAtlasMap(path)
    local raw = readFileRaw(path)
    local json = require 'lib.json'
    return json.decode(raw)
end

local function buildMaterialResolver(atlasMap)
    local map = atlasMap.map
    local cache = {}
    return function(matName)
        if not matName then return 0 end
        local c = cache[matName]
        if c ~= nil then return c end
        local name = matName:gsub('^minecraft_%a+%-', '')
        local idx = map[name] or 0
        cache[matName] = idx
        return idx
    end
end

local function groupBy(srcs, G)
    local groups = {}
    for i = 1, #srcs do
        local r = srcs[i]
        local gx = floor(r.x / G)
        local gz = floor(r.z / G)
        local key = gx .. '_' .. gz
        local g = groups[key]
        if not g then
            g = { x = gx, z = gz, srcList = {} }
            groups[key] = g
        end
        g.srcList[#g.srcList + 1] = r
    end
    return groups
end

-- ---------------------------------------------------------------------------

function love.load()
    local t0 = love.timer.getTime()
    local srcObj   = cfg.CONVERTER_ROOT .. '/' .. cfg.SRC_OBJ
    local outAbs   = cfg.CONVERTER_ROOT .. '/' .. cfg.OUT_DIR
    local atlasMap = cfg.PROJECT_ROOT   .. '/' .. cfg.ATLAS_MAP

    print('[main] reading ' .. srcObj)
    local objText = readFileRaw(srcObj)
    print(('[main] obj size: %.1f MB'):format(#objText / 1048576))

    print('[main] loading atlas map: ' .. atlasMap)
    local atlas = loadAtlasMap(atlasMap)
    local resolveMat = buildMaterialResolver(atlas)

    print('[main] scanning OBJ...')
    local v, vt, srcs = objparse.scan(objText, resolveMat)
    print(('[main] v=%d vt=%d source-chunks=%d (scan %.2fs)'):format(
        #v, #vt, #srcs, love.timer.getTime() - t0))
    objText = nil
    collectgarbage('collect')

    print(('[main] grouping by %dx%d into my-chunks...'):format(cfg.CHUNK_GROUP, cfg.CHUNK_GROUP))
    local groups = groupBy(srcs, cfg.CHUNK_GROUP)
    srcs = nil

    local jobsList = {}
    for _, g in pairs(groups) do jobsList[#jobsList + 1] = g end
    print(('[main] my-chunks: %d'):format(#jobsList))

    ensureDir(outAbs)

    -- Set up channels.
    local jobCh = love.thread.getChannel('jobs')
    local resCh = love.thread.getChannel('results')
    local vCh   = love.thread.getChannel('v')
    local vtCh  = love.thread.getChannel('vt')
    jobCh:clear(); resCh:clear(); vCh:clear(); vtCh:clear()

    -- Broadcast shared pools (workers peek, never consume).
    vCh:push(binser.serialize(v))
    vtCh:push(binser.serialize(vt))

    -- Push jobs.
    for i = 1, #jobsList do
        jobCh:push(jobsList[i])
    end
    -- Stop sentinels.
    for i = 1, cfg.WORKERS do jobCh:push('STOP') end

    local lodStr = table.concat(cfg.LOD_CELLS, ',')

    local threads = {}
    for w = 1, cfg.WORKERS do
        local th = love.thread.newThread('worker.lua')
        th:start(w, outAbs, lodStr, package.path)
        threads[w] = th
    end

    print(('[main] spawned %d workers'):format(cfg.WORKERS))
    _G.__state = {
        threads  = threads,
        total    = #jobsList,
        done     = 0,
        failed   = 0,
        totalBytes = 0,
        totalTris  = 0,
        t0       = t0,
    }
end

function love.update()
    local st = _G.__state
    if not st then return end
    local resCh = love.thread.getChannel('results')

    while true do
        local r = resCh:pop()
        if not r then break end
        st.done = st.done + 1
        if r.ok and r.skipped then
            st.skipped = (st.skipped or 0) + 1
        elseif r.ok then
            st.totalBytes = st.totalBytes + r.bytes
            st.totalTris  = st.totalTris  + r.tris
            print(('  [w%d] %s_%s  v=%d t=%d  %.0fKB  %.2fs   (%d/%d)'):format(
                r.worker, r.x, r.z, r.verts, r.tris, r.bytes/1024, r.dt, st.done, st.total))
        else
            st.failed = st.failed + 1
            print(('  [FAIL] %s_%s : %s'):format(r.x, r.z, tostring(r.err)))
        end
    end

    if st.done >= st.total then
        -- Check thread errors.
        for w, th in ipairs(st.threads) do
            local err = th:getError()
            if err then print(('[w%d] ERROR: %s'):format(w, err)) end
            th:wait()
        end
        print(('[main] DONE  chunks=%d  skipped=%d  fail=%d  tris=%d  size=%.1fMB  total=%.2fs'):format(
            st.total - st.failed - (st.skipped or 0), st.skipped or 0, st.failed,
            st.totalTris, st.totalBytes/1048576, love.timer.getTime() - st.t0))
        print('=====================================')
        print('=========  CONVERSION END  ==========')
        print('=====================================')
        io.stdout:flush()
        love.event.quit()
    end
end
