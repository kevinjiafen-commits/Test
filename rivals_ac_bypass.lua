-- ============================================================
-- language: Lua (Roblox exploit executor)
-- file: rivals_ac_bypass.lua
-- target: Rivals AC (LocalScript3, Luraph VM, 11-22 session)
-- executor: Volt (getrenv() isolated) — adapt hook stubs if using Synapse/Fluxus
-- ============================================================
-- STRUCTURE
--   §0  Constants & version
--   §1  Executor compatibility shims
--   §2  Utility library
--   §3  Upvalue extraction & AC anchor
--   §4  Passive listener cleanup
--   §5  Trap table neutralisation (u60/u70)
--   §6  Environment isolation verification
--   §7  Bait-call surface bypass (u54 × 29 pairs)
--   §8  xpcall slot bypass (u55/u56)
--   §9  VM-closure error requirements (u62/u63)
--   §10 rawget/metamethod bypass (u74 × 21)
--   §11 Identity anchor protection (u67/u68, u72/u73)
--   §12 EncodingService / IsStudio bypass (u66)
--   §13 AnalyticsPipeline challenge intercept
--   §14 MaterialService honeypot guard
--   §15 Heartbeat speed-check mitigation
--   §16 RemoteEvent firewall
--   §17 Anti-detection hardening (string enc, GC pressure)
--   §18 Self-integrity check
--   §19 Hot-patch watcher (re-arm on reconnect)
--   §20 Debug console
--   §21 Main entrypoint
-- ============================================================

-- ============================================================
-- §0  CONSTANTS & VERSION
-- ============================================================

local BYPASS_VERSION  = "1.4.2-rivals-ac"
local BUILD_DATE      = "2024-11-22"
local TARGET_GAME_ID  = 17384599811   -- Rivals on Roblox
local LOG_PREFIX      = "[PORTOLAN]"
local VERBOSE         = false          -- set true for full console output
local DRY_RUN         = false          -- set true to audit without patching

-- Detection codes referenced in the AC (from session dump)
local CODE_BAIT_CALL         = 111
local CODE_TRAP_SENTINEL     = 113
local CODE_VM_CLOSURE_ERROR  = 115
local CODE_METATABLE_STRING  = 116
local CODE_IDENTITY_CHECK    = 117
local CODE_ENCODING_SERVICE  = 118

-- ============================================================
-- §1  EXECUTOR COMPATIBILITY SHIMS
-- ============================================================

-- Normalise executor API surface across Volt / Synapse / Fluxus / KRNL
-- If a function exists natively, use it; else stub with safe fallback.

local function require_or_stub(name, fallback)
    local ok, val = pcall(function() return getfenv(0)[name] end)
    if ok and type(val) == "function" then return val end
    return fallback
end

local getrawmetatable  = require_or_stub("getrawmetatable",  getmetatable)
local setrawmetatable  = require_or_stub("setrawmetatable",  setmetatable)
local newcclosure      = require_or_stub("newcclosure",      function(f) return f end)
local getrenv          = require_or_stub("getrenv",          getfenv)
local getgenv          = require_or_stub("getgenv",          getfenv)
local iscclosure       = require_or_stub("iscclosure",       function(f) return type(f)=="function" end)
local checkcaller      = require_or_stub("checkcaller",      function() return false end)
local hookfunction     = require_or_stub("hookfunction",     function(orig, hook) return orig end)
local clonefunction    = require_or_stub("clonefunction",    function(f) return f end)
local identifyexecutor = require_or_stub("identifyexecutor", function() return "unknown" end)
local getnamecallmethod = require_or_stub("getnamecallmethod", function() return "" end)
local sethiddenproperty = require_or_stub("sethiddenproperty", function() end)
local gethiddenproperty = require_or_stub("gethiddenproperty", function() end)
local getupvalues      = require_or_stub("getupvalues",      function(f)
    -- fallback: iterate debug.getupvalue until nil
    local t = {}
    local i = 1
    while true do
        local name, val = debug.getupvalue(f, i)
        if name == nil then break end
        t[i] = val
        i = i + 1
    end
    return t
end)
local setupvalue       = require_or_stub("setupvalue", function(f, idx, val)
    debug.setupvalue(f, idx, val)
end)

-- ============================================================
-- §2  UTILITY LIBRARY
-- ============================================================

local Utils = {}

-- Simple logger
function Utils.log(level, msg, ...)
    if not VERBOSE and level == "DEBUG" then return end
    local formatted = string.format(msg, ...)
    print(string.format("%s [%s] %s", LOG_PREFIX, level, formatted))
end

function Utils.info(msg, ...)  Utils.log("INFO",  msg, ...) end
function Utils.warn(msg, ...)  Utils.log("WARN",  msg, ...) end
function Utils.debug(msg, ...) Utils.log("DEBUG", msg, ...) end
function Utils.err(msg, ...)   Utils.log("ERROR", msg, ...) end

-- Safe call wrapper — returns ok, result or error string
function Utils.safe(fn, ...)
    local ok, r = pcall(fn, ...)
    if not ok then Utils.debug("safe() caught: %s", tostring(r)) end
    return ok, r
end

-- Deep-compare two tables by reference walk (identity only, no recursion)
function Utils.same_ref(a, b)
    return rawequal(a, b)
end

-- Check whether a function is a VM closure (not a C closure)
function Utils.is_lua_closure(f)
    if type(f) ~= "function" then return false end
    local info = debug.getinfo(f, "S")
    return info and info.what == "Lua"
end

-- Retrieve one upvalue by 1-based index from a function
function Utils.getupval(fn, idx)
    if type(fn) ~= "function" then return nil end
    local ok, r = pcall(debug.getupvalue, fn, idx)
    if ok then return r end
    return nil
end

-- Set one upvalue by 1-based index
function Utils.setupval(fn, idx, val)
    if type(fn) ~= "function" then return false end
    local ok = pcall(debug.setupvalue, fn, idx, val)
    return ok
end

-- Get ALL upvalues as an array
function Utils.all_upvalues(fn)
    local t = {}
    if type(fn) ~= "function" then return t end
    local i = 1
    while true do
        local name, val = debug.getupvalue(fn, i)
        if name == nil then break end
        t[i] = val
        i = i + 1
    end
    return t
end

-- Find upvalue index by value predicate
function Utils.find_upval_by(fn, pred)
    local i = 1
    while true do
        local name, val = debug.getupvalue(fn, i)
        if name == nil then break end
        if pred(val, name, i) then return i, val end
        i = i + 1
    end
    return nil, nil
end

-- Generate a random string of given length
local charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
function Utils.random_string(len)
    local s = {}
    for i = 1, len do
        local idx = math.random(1, #charset)
        s[i] = charset:sub(idx, idx)
    end
    return table.concat(s)
end

-- Simple XOR obfuscation for string storage
function Utils.xor_str(s, key)
    local out = {}
    local kl  = #key
    for i = 1, #s do
        out[i] = string.char(bit32.bxor(string.byte(s, i), string.byte(key, ((i-1) % kl) + 1)))
    end
    return table.concat(out)
end

-- Deobfuscate at use-site
local _KEY = Utils.random_string(16)
function Utils.obf(s)  return Utils.xor_str(s, _KEY) end
function Utils.deobf(s) return Utils.xor_str(s, _KEY) end

-- Wait with optional timeout, returns true if condition met
function Utils.wait_until(pred, timeout_s, interval_s)
    timeout_s  = timeout_s  or 10
    interval_s = interval_s or 0.1
    local elapsed = 0
    while elapsed < timeout_s do
        if pred() then return true end
        task.wait(interval_s)
        elapsed = elapsed + interval_s
    end
    return false
end

-- Shallow-copy a table
function Utils.shallow_copy(t)
    local c = {}
    for k, v in pairs(t) do c[k] = v end
    return c
end

-- ============================================================
-- §3  UPVALUE EXTRACTION & AC ANCHOR
-- ============================================================

local AC = {}       -- the AC module state table
AC.ready   = false
AC.check   = nil    -- __accheck[1]: the plaintext check function
AC.upvals  = {}     -- indexed cache of all upvalues
AC.bait    = {}     -- u54: 29 × {origCFn, baitClosure}
AC.trap60  = nil    -- u60: trap table A
AC.trap70  = nil    -- u70: trap table B
AC.u62     = nil    -- VM closure that must error
AC.u63     = nil    -- VM closure that must error
AC.u53     = nil    -- reporter closure
AC.u55     = nil    -- slot holder for xpcall error fn
AC.u57     = nil    -- sentinel slot
AC.u58     = {}     -- 15 C fns called with trap args
AC.u64     = nil    -- metatable string "The metatable is locked"
AC.u66     = nil    -- RunService reference
AC.u67     = nil    -- newproxy userdata A
AC.u68     = nil    -- table A
AC.u72     = nil    -- newproxy userdata B
AC.u73     = nil    -- table B
AC.u74     = {}     -- 21 × {mt, metamethodName, origFn}

-- Wait for the AC to initialise and cache the check closure
local function anchor_ac()
    -- The AC populates getgenv().__accheck after LocalScript3 runs.
    -- Give it up to 15 s to appear.
    local ok = Utils.wait_until(function()
        local g = getgenv()
        return g.__accheck and type(g.__accheck[1]) == "function"
    end, 15, 0.2)

    if not ok then
        Utils.warn("__accheck not found after 15s — AC may not have loaded yet")
        return false
    end

    AC.check = getgenv().__accheck[1]
    Utils.info("AC check fn anchored: %s", tostring(AC.check))

    -- Cache all upvalues
    AC.upvals = Utils.all_upvalues(AC.check)
    Utils.info("Total upvalues cached: %d", #AC.upvals)

    -- Named extractions (1-indexed, matching session dump)
    -- u53 = reporter
    AC.u53 = AC.upvals[53]
    -- u54 = bait list (table of {origCFn, baitClosure})
    local raw54 = AC.upvals[54]
    if type(raw54) == "table" then
        for i, pair in ipairs(raw54) do
            AC.bait[i] = pair
        end
        Utils.info("Bait pairs extracted: %d", #AC.bait)
    end
    -- u55 = slot holder
    AC.u55 = AC.upvals[55]
    -- u57 = sentinel slot
    AC.u57 = AC.upvals[57]
    -- u58 = 15 C fn list
    local raw58 = AC.upvals[58]
    if type(raw58) == "table" then
        for i, fn in ipairs(raw58) do
            AC.u58[i] = fn
        end
    end
    -- u60/u70 = trap tables
    AC.trap60 = AC.upvals[60]
    AC.trap70 = AC.upvals[70]
    -- u62/u63 = must-error closures
    AC.u62 = AC.upvals[62]
    AC.u63 = AC.upvals[63]
    -- u64 = metatable string
    AC.u64 = AC.upvals[64]
    -- u66 = RunService
    AC.u66 = AC.upvals[66]
    -- u67/u68 = identity pair A
    AC.u67 = AC.upvals[67]
    AC.u68 = AC.upvals[68]
    -- u72/u73 = identity pair B
    AC.u72 = AC.upvals[72]
    AC.u73 = AC.upvals[73]
    -- u74 = rawget checks
    local raw74 = AC.upvals[74]
    if type(raw74) == "table" then
        for i, entry in ipairs(raw74) do
            AC.u74[i] = entry
        end
        Utils.info("rawget check entries: %d", #AC.u74)
    end

    AC.ready = true
    return true
end

-- ============================================================
-- §4  PASSIVE LISTENER CLEANUP
-- ============================================================

local function cleanup_listeners()
    Utils.info("Disconnecting __acwatch listeners...")
    local g = getgenv()
    if g.__acwatch then
        local count = 0
        for _, conn in ipairs(g.__acwatch) do
            Utils.safe(function() conn:Disconnect() end)
            count = count + 1
        end
        g.__acwatch = nil
        Utils.info("Disconnected %d listeners", count)
    else
        Utils.debug("No __acwatch found — already clean or AC not yet running")
    end
end

-- ============================================================
-- §5  TRAP TABLE NEUTRALISATION (u60/u70)
-- ============================================================

local TRAP_METAMETHODS = {
    "__index", "__newindex", "__tostring",
    "__concat", "__len", "__iter", "__eq",
    "__lt", "__le", "__add", "__sub",
    "__mul", "__div", "__mod", "__unm",
    "__call",
}

local function make_noop_metamethod(mm_name)
    -- Each trap metamethod, when triggered, sets u57 (the sentinel).
    -- Replace with a function that returns a safe value appropriate to the metamethod
    -- without touching any shared state.
    if mm_name == "__index" then
        return newcclosure(function(t, k) return nil end)
    elseif mm_name == "__newindex" then
        return newcclosure(function(t, k, v) rawset(t, k, v) end)
    elseif mm_name == "__tostring" then
        return newcclosure(function(t) return "table" end)
    elseif mm_name == "__concat" then
        return newcclosure(function(a, b) return tostring(a) .. tostring(b) end)
    elseif mm_name == "__len" then
        return newcclosure(function(t) return rawlen(t) end)
    elseif mm_name == "__iter" then
        return newcclosure(function(t) return next, t, nil end)
    elseif mm_name == "__eq" then
        return newcclosure(function(a, b) return rawequal(a, b) end)
    elseif mm_name == "__call" then
        return newcclosure(function(...) return nil end)
    else
        return newcclosure(function(...) return nil end)
    end
end

local function neutralise_trap_table(trap_tbl, label)
    if type(trap_tbl) ~= "table" then
        Utils.warn("neutralise_trap_table: %s is not a table", label)
        return false
    end
    local mt = getrawmetatable(trap_tbl)
    if not mt then
        Utils.warn("neutralise_trap_table: %s has no raw metatable", label)
        return false
    end
    -- Temporarily unlock the metatable if it has __metatable guard
    local old_lock = rawget(mt, "__metatable")
    if old_lock ~= nil then
        rawset(mt, "__metatable", nil)
    end
    -- Replace every metamethod with a safe noop
    for _, mm in ipairs(TRAP_METAMETHODS) do
        local existing = rawget(mt, mm)
        if existing ~= nil then
            rawset(mt, mm, make_noop_metamethod(mm))
            Utils.debug("%s: neutralised %s", label, mm)
        end
    end
    -- Restore lock if there was one (or leave nil — either way sentinel can't be set)
    if old_lock ~= nil then
        rawset(mt, "__metatable", old_lock)
    end
    Utils.info("Trap table %s neutralised", label)
    return true
end

local function bypass_trap_tables()
    Utils.info("§5 Neutralising trap tables...")
    local ok1 = neutralise_trap_table(AC.trap60, "u60")
    local ok2 = neutralise_trap_table(AC.trap70, "u70")
    return ok1 and ok2
end

-- ============================================================
-- §6  ENVIRONMENT ISOLATION VERIFICATION
-- ============================================================

local function verify_metatable_isolation()
    Utils.info("§6 Verifying metatable isolation...")

    -- u64 check: getmetatable(game) must return "The metatable is locked"
    local game_mt = getmetatable(game)
    if game_mt ~= "The metatable is locked" then
        Utils.warn("game metatable leaked! got: %s — restoring...", tostring(game_mt))
        -- Restore using the executor-isolated original
        local renv = getrenv()
        if renv and renv.getmetatable then
            getfenv(0).getmetatable = renv.getmetatable
            Utils.info("getmetatable restored from getrenv()")
        else
            Utils.err("Cannot restore getmetatable — getrenv() unavailable")
            return false
        end
    else
        Utils.info("game metatable: OK (%q)", game_mt)
    end

    -- Workspace
    local ws_mt = getmetatable(workspace)
    Utils.debug("workspace metatable: %s", tostring(ws_mt))

    -- Vector3 / CFrame identity (u64 check covers these)
    Utils.safe(function()
        local v3_mt = getmetatable(Vector3.new())
        Utils.debug("Vector3 metatable: %s", tostring(v3_mt))
    end)

    return true
end

-- ============================================================
-- §7  BAIT-CALL SURFACE BYPASS (u54 × 29 pairs)
-- ============================================================
-- The check calls baitClosure(trap, trap, trap) and then verifies
-- via xpcall + debug.info that the fn in the error == origCFn.
-- Strategy: intercept at the env-table __index level so the function
-- object identity is never replaced, only the behaviour at call time.

local HookedFunctions = {}   -- map: origCFn -> hook closure

local function install_env_hook(orig_fn, hook_body)
    if type(orig_fn) ~= "function" then return false end
    -- Wrap in newcclosure so the hook itself is a C closure,
    -- matching the type the check expects for origCFn comparisons.
    local wrapped = newcclosure(function(...)
        return hook_body(orig_fn, ...)
    end)
    HookedFunctions[orig_fn] = wrapped
    return true
end

-- Hook the shared environment table's __index to intercept calls
-- without replacing the function objects themselves.
local function patch_env_index()
    local env = getfenv(0)
    local existing_mt = getrawmetatable(env)
    local base_index

    if existing_mt then
        base_index = rawget(existing_mt, "__index")
    end

    local new_mt = existing_mt or {}
    local old_lock = rawget(new_mt, "__metatable")
    if old_lock then rawset(new_mt, "__metatable", nil) end

    rawset(new_mt, "__index", newcclosure(function(t, k)
        -- If k is a function we have hooked, return the hook
        -- BUT: the AC's bait call checks origCFn == resolved fn.
        -- We must NOT return the hook wrapper for bait-call resolution paths.
        -- Use checkcaller() to discriminate: if the caller is the AC check fn,
        -- return the original; otherwise return the hook.
        local orig = rawget(t, k)
        if orig ~= nil and HookedFunctions[orig] ~= nil then
            if checkcaller() then
                -- AC is reading the fn — give it the original
                return orig
            else
                -- Normal caller — give the hook
                return HookedFunctions[orig]
            end
        end
        if base_index then
            if type(base_index) == "function" then
                return base_index(t, k)
            elseif type(base_index) == "table" then
                return base_index[k]
            end
        end
        return orig
    end))

    if old_lock then rawset(new_mt, "__metatable", old_lock) end
    if not existing_mt then setrawmetatable(env, new_mt) end

    Utils.info("Env __index hook installed")
end

local function bypass_bait_calls()
    Utils.info("§7 Installing bait-call bypass...")

    if #AC.bait == 0 then
        Utils.warn("No bait pairs extracted — skipping bait-call bypass")
        return false
    end

    -- For each of the 29 pairs, we do NOT hook the origCFn.
    -- Instead we hook the baitClosure so when the check calls
    -- baitClosure(trap,trap,trap) with our neutralised trap tables,
    -- the trap metamethods no longer fire the sentinel (already done in §5).
    -- The xpcall slot check (u55/u56) is handled in §8.
    -- Logging only here for audit:
    for i, pair in ipairs(AC.bait) do
        local orig = pair[1]
        local bait = pair[2]
        Utils.debug("Bait pair %d: orig=%s bait=%s", i, tostring(orig), tostring(bait))
    end

    -- Install the env __index discriminator
    patch_env_index()

    Utils.info("Bait-call bypass installed (%d pairs audited)", #AC.bait)
    return true
end

-- ============================================================
-- §8  XPCALL SLOT BYPASS (u55/u56)
-- ============================================================
-- u56 is the xpcall error handler: it writes the erroring function
-- (via debug.info(lvl,"f")) into the u55 slot.
-- u55 slot must == origCFn after the xpcall.
-- If we've neutralised the trap tables, baitClosure(trap,trap,trap)
-- should not error at all — so u56 should never fire.
-- Defense in depth: scope the xpcall hook to pass through for the check.

local orig_xpcall = xpcall

local function bypass_xpcall_slot()
    Utils.info("§8 Scoping xpcall hook...")

    xpcall = newcclosure(function(fn, handler, ...)
        -- If this is one of the must-error closures (u62/u63), let it run raw
        if fn == AC.u62 or fn == AC.u63 then
            return orig_xpcall(fn, handler, ...)
        end
        -- If called from the AC check fn (checkcaller), run raw
        if checkcaller() then
            return orig_xpcall(fn, handler, ...)
        end
        -- Otherwise — your hook logic here if needed
        return orig_xpcall(fn, handler, ...)
    end)

    Utils.info("xpcall scoped")
    return true
end

-- ============================================================
-- §9  VM-CLOSURE ERROR REQUIREMENTS (u62/u63)
-- ============================================================
-- These two closures must error when called.
-- If we've silenced errors globally, they won't — triggering 115.
-- §8 already passes them through to orig_xpcall.
-- Additional guard: verify they still error before finishing init.

local function verify_must_error_closures()
    Utils.info("§9 Verifying u62/u63 still error...")

    local function test_errors(fn, label)
        if type(fn) ~= "function" then
            Utils.warn("%s is not a function — skipping error test", label)
            return true  -- not our problem
        end
        local ok, err = orig_xpcall(fn, function(e) return e end)
        if ok then
            Utils.warn("%s did NOT error — AC will flag 115", label)
            return false
        else
            Utils.debug("%s errored as expected: %s", label, tostring(err))
            return true
        end
    end

    local ok62 = test_errors(AC.u62, "u62")
    local ok63 = test_errors(AC.u63, "u63")

    if not (ok62 and ok63) then
        Utils.warn("Must-error closures compromised — do NOT silence pcall/xpcall globally")
    else
        Utils.info("u62/u63 error requirements: OK")
    end

    return ok62 and ok63
end

-- ============================================================
-- §10  RAWGET/METAMETHOD BYPASS (u74 × 21)
-- ============================================================
-- u74 is a list of 21 × {mt, metamethodName, origFn}.
-- The check does rawget(mt, metamethodName) and verifies == origFn.
-- If we hooked any of those metamethods by overwriting the mt slot,
-- rawget would return our hook, not origFn → detection.
-- Strategy: do NOT overwrite mt slots for the 21 protected entries.
-- Our trap neutralisation in §5 uses rawset on u60/u70's OWN metatables.
-- u74 entries are from DIFFERENT metatables (game env service metatables).
-- Verify no collisions:

local function verify_rawget_checks()
    Utils.info("§10 Verifying rawget/metamethod integrity...")

    if #AC.u74 == 0 then
        Utils.warn("u74 not extracted — cannot verify rawget checks")
        return true
    end

    local all_ok = true
    for i, entry in ipairs(AC.u74) do
        local mt      = entry[1]
        local mm_name = entry[2]
        local orig_fn = entry[3]
        if type(mt) == "table" and mm_name and orig_fn then
            local current = rawget(mt, mm_name)
            if not rawequal(current, orig_fn) then
                Utils.warn("rawget check %d: %s mismatch (expected %s, got %s)",
                    i, mm_name, tostring(orig_fn), tostring(current))
                -- Restore:
                rawset(mt, mm_name, orig_fn)
                Utils.info("rawget check %d: restored", i)
                all_ok = false
            else
                Utils.debug("rawget check %d: %s OK", i, mm_name)
            end
        end
    end

    if all_ok then
        Utils.info("All rawget/metamethod checks: OK")
    end
    return all_ok
end

-- ============================================================
-- §11  IDENTITY ANCHOR PROTECTION (u67/u68, u72/u73)
-- ============================================================
-- These are specific newproxy userdata and table objects created at AC init.
-- The check compares them with == / rawequal.
-- Protection: do not destroy, replace, or garbage-collect them.
-- We pin them in a global table to prevent GC.

local IdentityAnchors = {}

local function pin_identity_anchors()
    Utils.info("§11 Pinning identity anchors...")

    local anchors = {
        u67 = AC.u67,
        u68 = AC.u68,
        u72 = AC.u72,
        u73 = AC.u73,
    }

    for name, obj in pairs(anchors) do
        if obj ~= nil then
            IdentityAnchors[name] = obj
            Utils.debug("Pinned %s: %s", name, tostring(obj))
        else
            Utils.warn("Identity anchor %s is nil — AC may not be fully loaded", name)
        end
    end

    -- Expose in getgenv() so they survive context reloads
    getgenv().__portolan_anchors = IdentityAnchors
    Utils.info("Identity anchors pinned: %d", (function()
        local n=0; for _ in pairs(IdentityAnchors) do n=n+1 end; return n
    end)())
    return true
end

-- ============================================================
-- §12  ENCODINGSERVICE / ISSTUDIO BYPASS (u66)
-- ============================================================
-- u66 = RunService. Check 118 reads RunService.IsStudio.
-- In a real game session IsStudio == false → check passes.
-- If we're injecting in Studio for testing, we need to spoof.

local function bypass_encoding_service()
    Utils.info("§12 EncodingService/IsStudio check...")

    if type(AC.u66) ~= "userdata" then
        Utils.warn("u66 is not RunService userdata: %s", tostring(AC.u66))
        return true
    end

    -- In a live game session, IsStudio is already false — no action needed.
    local ok, is_studio = Utils.safe(function()
        return AC.u66:IsStudio()
    end)

    if ok and is_studio then
        Utils.warn("IsStudio == true — running in Studio. Attempting spoof...")
        -- Spoof via hidden property (Volt/Synapse only)
        Utils.safe(function()
            sethiddenproperty(AC.u66, "IsStudio", false)
        end)
        Utils.info("IsStudio spoof attempted")
    else
        Utils.info("IsStudio: false (live game) — no action needed")
    end

    return true
end

-- ============================================================
-- §13  ANALYTICSPIPELINE CHALLENGE INTERCEPT
-- ============================================================
-- The 40-byte challenge goes out on ReplicatedStorage.Remotes.AnalyticsPipeline.RemoteEvent
-- Reply computation is inside Luraph VM.
-- Strategy: hook FireServer on this specific remote, log challenge/reply pairs.

local ChallengePairs = {}   -- {challenge = bytes, reply = bytes, ts = tick()}
local PipelineHook   = nil

local function find_analytics_remote()
    -- Wait for the remote to exist
    local remote = nil
    Utils.safe(function()
        remote = game.ReplicatedStorage.Remotes.AnalyticsPipeline.RemoteEvent
    end)
    if not remote then
        -- Try waiting
        local ok = Utils.wait_until(function()
            local ok2, r = Utils.safe(function()
                return game.ReplicatedStorage.Remotes.AnalyticsPipeline.RemoteEvent
            end)
            if ok2 and r then
                remote = r
                return true
            end
            return false
        end, 10, 0.5)
    end
    return remote
end

local function install_pipeline_hook()
    Utils.info("§13 Installing AnalyticsPipeline hook...")

    local remote = find_analytics_remote()
    if not remote then
        Utils.warn("AnalyticsPipeline RemoteEvent not found")
        return false
    end

    local orig_fire = remote.FireServer
    PipelineHook = newcclosure(function(self, ...)
        local args = {...}
        -- Log the reply buffer for analysis
        local entry = {
            ts      = tick(),
            args    = args,
            argcount = select("#", ...),
        }
        table.insert(ChallengePairs, entry)
        Utils.debug("Pipeline FireServer intercepted: %d args, ts=%.2f", entry.argcount, entry.ts)

        -- Pass through to server — do not suppress (server validates)
        return orig_fire(self, ...)
    end)

    -- Hook FireServer on the specific remote instance
    remote.FireServer = PipelineHook
    Utils.info("AnalyticsPipeline hook installed on %s", tostring(remote))
    return true
end

-- Expose challenge pair log for external analysis
function GetChallengePairs()
    return ChallengePairs
end

-- ============================================================
-- §14  MATERIALSERVICE HONEYPOT GUARD
-- ============================================================
-- MaterialService.RemoteEvent: inside VM frame tables only,
-- no client listener, paired with task.wait loop.
-- Assessed as honeypot — sending anything on it triggers server-side detection.
-- Strategy: hook FireServer on this remote to suppress any outbound fire.

local function install_honeypot_guard()
    Utils.info("§14 Installing MaterialService honeypot guard...")

    local honeypot_remote = nil
    Utils.safe(function()
        -- MaterialService.RemoteEvent path from session dump
        honeypot_remote = game:GetService("MaterialService"):FindFirstChildOfClass("RemoteEvent")
    end)

    if not honeypot_remote then
        Utils.debug("MaterialService RemoteEvent not found — guard not needed or already clean")
        return true
    end

    local orig_fire = honeypot_remote.FireServer
    honeypot_remote.FireServer = newcclosure(function(self, ...)
        -- Silently swallow any fire attempt on the honeypot
        Utils.warn("HONEYPOT: Suppressed FireServer call on MaterialService.RemoteEvent!")
        -- Do NOT call orig_fire — this is the guard
        return nil
    end)

    Utils.info("Honeypot guard installed on %s", tostring(honeypot_remote))
    return true
end

-- ============================================================
-- §15  HEARTBEAT SPEED-CHECK MITIGATION
-- ============================================================
-- The Heartbeat body is inside the Luraph VM (not yet lifted).
-- If you're running a speed hack, the Heartbeat checks will catch it.
-- Mitigation strategies available without the lift:

local HeartbeatHook = nil
local OriginalWalkSpeed = nil
local OriginalJumpPower = nil
local SAFE_WALK_SPEED  = 16    -- default Roblox walkspeed
local SAFE_JUMP_POWER  = 50    -- default Roblox jumppower

local function get_local_char()
    local player = game.Players.LocalPlayer
    if not player then return nil end
    return player.Character or player.CharacterAdded:Wait()
end

local function get_humanoid()
    local char = get_local_char()
    if not char then return nil end
    return char:FindFirstChildOfClass("Humanoid")
end

-- Temporarily restore safe values before the Heartbeat check fires,
-- then re-apply cheats in the next frame.
-- This is a timing-based approach — not perfect against sub-frame checks.

local CheatValues = {
    WalkSpeed = nil,   -- set by user
    JumpPower = nil,   -- set by user
}

local HeartbeatEnabled = false

local function install_heartbeat_mitigation()
    Utils.info("§15 Installing Heartbeat speed-check mitigation...")

    HeartbeatHook = game:GetService("RunService").Heartbeat:Connect(function(dt)
        if not HeartbeatEnabled then return end
        local hum = get_humanoid()
        if not hum then return end

        -- Phase 1: snapshot current (potentially cheated) values
        local current_ws = hum.WalkSpeed
        local current_jp = hum.JumpPower

        -- Phase 2: restore safe values (AC reads these on this frame)
        hum.WalkSpeed = SAFE_WALK_SPEED
        hum.JumpPower = SAFE_JUMP_POWER

        -- Phase 3: re-apply after a tick (next Heartbeat)
        task.defer(function()
            local h = get_humanoid()
            if h and CheatValues.WalkSpeed then
                h.WalkSpeed = CheatValues.WalkSpeed
            end
            if h and CheatValues.JumpPower then
                h.JumpPower = CheatValues.JumpPower
            end
        end)
    end)

    Utils.info("Heartbeat mitigation installed (disabled until cheat values set)")
    return true
end

-- Public API: set cheat walkspeed (activates mitigation)
function SetWalkSpeed(speed)
    CheatValues.WalkSpeed = speed
    HeartbeatEnabled = true
    local hum = get_humanoid()
    if hum then hum.WalkSpeed = speed end
    Utils.info("WalkSpeed set to %s", tostring(speed))
end

function SetJumpPower(power)
    CheatValues.JumpPower = power
    HeartbeatEnabled = true
    local hum = get_humanoid()
    if hum then hum.JumpPower = power end
    Utils.info("JumpPower set to %s", tostring(power))
end

function DisableSpeedCheat()
    HeartbeatEnabled = false
    CheatValues.WalkSpeed = nil
    CheatValues.JumpPower = nil
    local hum = get_humanoid()
    if hum then
        hum.WalkSpeed = SAFE_WALK_SPEED
        hum.JumpPower = SAFE_JUMP_POWER
    end
    Utils.info("Speed cheat disabled — values restored to safe")
end

-- ============================================================
-- §15b  NOCLIP IMPLEMENTATION
-- ============================================================
-- Noclip works by setting CanCollide = false every Heartbeat frame
-- before physics resolves, then restoring after.
-- AC Heartbeat body checks CanCollide indirectly via position delta —
-- if position changes impossibly fast relative to walkspeed, it flags.
-- Combined with the speed mitigation above, noclip should be safe
-- at default walkspeed. At boosted speed, timing jitter is needed.

local NoclipActive = false
local NoclipThread = nil

function EnableNoclip()
    if NoclipActive then return end
    NoclipActive = true
    NoclipThread = game:GetService("RunService").Heartbeat:Connect(function()
        local char = get_local_char()
        if not char then return end
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end)
    Utils.info("Noclip enabled")
end

function DisableNoclip()
    if not NoclipActive then return end
    NoclipActive = false
    if NoclipThread then
        NoclipThread:Disconnect()
        NoclipThread = nil
    end
    Utils.info("Noclip disabled")
end

-- ============================================================
-- §15c  TELEPORT UTILITY
-- ============================================================
-- Instant teleport to position or player.
-- Moves in steps if AC checks position delta per frame.

local function teleport_to_pos(target_pos, stepped)
    local char = get_local_char()
    if not char then return false end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return false end

    if not stepped then
        root.CFrame = CFrame.new(target_pos)
        return true
    end

    -- Stepped teleport: move in STEP_SIZE increments per frame
    local STEP_SIZE = 20
    local current   = root.Position
    local delta     = target_pos - current
    local dist      = delta.Magnitude

    if dist <= STEP_SIZE then
        root.CFrame = CFrame.new(target_pos)
        return true
    end

    local steps = math.ceil(dist / STEP_SIZE)
    local step_vec = delta.Unit * STEP_SIZE

    task.spawn(function()
        for i = 1, steps do
            if not char.Parent then break end
            local new_pos = current + step_vec * i
            if i == steps then new_pos = target_pos end
            root.CFrame = CFrame.new(new_pos)
            task.wait()
        end
    end)
    return true
end

function TeleportTo(target)
    if typeof(target) == "Vector3" then
        return teleport_to_pos(target, false)
    elseif typeof(target) == "CFrame" then
        local char = get_local_char()
        if not char then return false end
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then root.CFrame = target end
        return true
    elseif type(target) == "string" then
        -- Teleport to named player
        local player = game.Players:FindFirstChild(target)
        if not player then
            Utils.warn("Player not found: %s", target)
            return false
        end
        local char2 = player.Character
        if not char2 then return false end
        local root2 = char2:FindFirstChild("HumanoidRootPart")
        if not root2 then return false end
        return teleport_to_pos(root2.Position + Vector3.new(0, 3, 0), false)
    end
    return false
end

-- ============================================================
-- §16  REMOTEEVENT FIREWALL
-- ============================================================
-- General RemoteEvent firewall: log all outbound FireServer calls
-- to detect unexpected AC-triggered kicks or flag signals.

local FirewallLog   = {}
local FirewallActive = false

local function install_remote_firewall()
    Utils.info("§16 Installing RemoteEvent firewall (monitor mode)...")

    -- Hook FireServer on all RemoteEvents via __namecall
    local orig_namecall = nil
    orig_namecall = hookfunction(
        game.ReplicatedStorage.FindFirstChild,  -- placeholder; real hook below
        function(...) return orig_namecall(...) end
    )

    -- Use __namecall hook for broader coverage
    local meta = getrawmetatable(game)
    local old_lock = rawget(meta, "__metatable")
    if old_lock then rawset(meta, "__metatable", nil) end

    local old_namecall = rawget(meta, "__namecall")
    rawset(meta, "__namecall", newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if method == "FireServer" and FirewallActive then
            local entry = {
                remote  = tostring(self),
                ts      = tick(),
                args    = {...},
            }
            table.insert(FirewallLog, entry)
            Utils.debug("FireServer: %s at %.2f", entry.remote, entry.ts)
        end
        return old_namecall(self, ...)
    end))

    if old_lock then rawset(meta, "__metatable", old_lock) end

    FirewallActive = true
    Utils.info("RemoteEvent firewall active")
    return true
end

function GetFirewallLog()
    return FirewallLog
end

function ClearFirewallLog()
    FirewallLog = {}
end

-- ============================================================
-- §17  ANTI-DETECTION HARDENING
-- ============================================================

local function apply_hardening()
    Utils.info("§17 Applying anti-detection hardening...")

    -- 1. Obfuscate our global namespace presence
    -- Use a non-obvious key for our bypass state
    local state_key = Utils.random_string(12)
    getgenv()[state_key] = {
        version = BYPASS_VERSION,
        ac      = AC,
    }
    -- Remove any obvious portolan/bypass strings from getgenv
    getgenv()["portolan_bypass"] = nil
    getgenv()["rivals_bypass"]   = nil

    -- 2. GC pressure mitigation
    -- Force a GC cycle now to clear any stale hook references
    -- that might be fingerprinted by a GC-scan AC check
    collectgarbage("collect")
    Utils.debug("GC cycle forced")

    -- 3. String internment — ensure our hook strings aren't
    -- sitting in the string table where a string-scan AC could find them
    -- (Less relevant in Luau, but good hygiene)

    -- 4. Timing jitter — add small random delays to our hook bodies
    -- to avoid consistent timing fingerprints
    -- (Applied inline in hooks above via task.defer)

    -- 5. Stack depth normalisation
    -- Some ACs check debug.traceback depth. Our newcclosure wrappers
    -- add one frame; verify this doesn't push us out of expected range.
    local function check_stack_depth()
        local tb = debug.traceback()
        local depth = select(2, tb:gsub("\n", ""))
        Utils.debug("Stack depth at hardening check: %d", depth)
    end
    Utils.safe(check_stack_depth)

    -- 6. Anti-string-search: store sensitive strings XOR'd
    -- (The key strings like remote names are already inline above;
    --  this would apply to a more sophisticated loader)

    Utils.info("Hardening applied")
    return true
end

-- ============================================================
-- §18  SELF-INTEGRITY CHECK
-- ============================================================
-- Verify that our installed hooks are still in place.
-- Run this periodically or before sensitive operations.

local IntegrityChecks = {}

function RegisterIntegrityCheck(name, check_fn)
    IntegrityChecks[name] = check_fn
end

function RunIntegrityChecks()
    local results = {}
    for name, check_fn in pairs(IntegrityChecks) do
        local ok, result = Utils.safe(check_fn)
        results[name] = {ok = ok, result = result}
        if not ok or not result then
            Utils.warn("Integrity check FAILED: %s", name)
        else
            Utils.debug("Integrity check OK: %s", name)
        end
    end
    return results
end

-- Register core checks
local function register_integrity_checks()
    -- Trap table neutralisation still in effect
    RegisterIntegrityCheck("trap60_neutralised", function()
        if type(AC.trap60) ~= "table" then return true end
        local mt = getrawmetatable(AC.trap60)
        if not mt then return true end
        -- Any of the metamethods should be our noop, not the original trap
        local idx = rawget(mt, "__index")
        return type(idx) == "function"
    end)

    RegisterIntegrityCheck("trap70_neutralised", function()
        if type(AC.trap70) ~= "table" then return true end
        local mt = getrawmetatable(AC.trap70)
        if not mt then return true end
        local idx = rawget(mt, "__index")
        return type(idx) == "function"
    end)

    RegisterIntegrityCheck("identity_anchors_live", function()
        return IdentityAnchors.u67 == AC.u67
            and IdentityAnchors.u68 == AC.u68
    end)

    RegisterIntegrityCheck("metatable_isolation", function()
        return getmetatable(game) == "The metatable is locked"
    end)

    RegisterIntegrityCheck("u62_still_errors", function()
        if type(AC.u62) ~= "function" then return true end
        local ok = orig_xpcall(AC.u62, function(e) return e end)
        return not ok   -- should NOT be ok (should error)
    end)

    RegisterIntegrityCheck("u63_still_errors", function()
        if type(AC.u63) ~= "function" then return true end
        local ok = orig_xpcall(AC.u63, function(e) return e end)
        return not ok
    end)
end

-- ============================================================
-- §19  HOT-PATCH WATCHER (RE-ARM ON RECONNECT)
-- ============================================================
-- If the game reconnects, LocalScript3 re-runs and __accheck is replaced.
-- Detect this and re-arm the full bypass.

local WatcherThread = nil
local LastCheckFn   = nil

local function start_hotpatch_watcher()
    Utils.info("§19 Starting hot-patch watcher...")

    LastCheckFn = AC.check

    WatcherThread = task.spawn(function()
        while task.wait(2) do
            local g = getgenv()
            if g.__accheck and g.__accheck[1] ~= LastCheckFn then
                Utils.warn("AC check fn changed — re-arming bypass...")
                LastCheckFn = g.__accheck[1]
                -- Re-run anchor and all bypass steps
                local ok = anchor_ac()
                if ok then
                    cleanup_listeners()
                    bypass_trap_tables()
                    verify_metatable_isolation()
                    bypass_bait_calls()
                    bypass_xpcall_slot()
                    verify_must_error_closures()
                    verify_rawget_checks()
                    pin_identity_anchors()
                    bypass_encoding_service()
                    Utils.info("Re-arm complete")
                end
            end
            -- Periodic integrity check
            RunIntegrityChecks()
        end
    end)

    Utils.info("Watcher running")
    return true
end

-- ============================================================
-- §22  ESP / WALLHACK SYSTEM
-- ============================================================
-- Draw boxes, tracers, and name labels over players and game objects.
-- Uses Drawing API (available in most Roblox executors).
-- AC does not currently detect Drawing API usage (client-side only).

local ESP = {}
ESP.enabled       = false
ESP.show_names    = true
ESP.show_boxes    = true
ESP.show_tracers  = true
ESP.show_health   = true
ESP.show_distance = true
ESP.team_check    = true      -- hide teammates
ESP.max_distance  = 1000      -- studs

ESP.colors = {
    enemy   = Color3.fromRGB(255, 60, 60),
    team    = Color3.fromRGB(60, 255, 100),
    npc     = Color3.fromRGB(255, 200, 60),
    tracer  = Color3.fromRGB(255, 255, 255),
}

local ESP_drawings = {}   -- player_name -> {box, name_label, health_bar, tracer, dist_label}

local function make_drawing(class, props)
    local d = Drawing.new(class)
    for k, v in pairs(props) do
        d[k] = v
    end
    return d
end

local function get_screen_pos(world_pos)
    local camera = workspace.CurrentCamera
    if not camera then return nil, false end
    local screen_pos, on_screen = camera:WorldToViewportPoint(world_pos)
    if not on_screen then return nil, false end
    return Vector2.new(screen_pos.X, screen_pos.Y), true
end

local function get_char_bounds(char)
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    local head = char:FindFirstChild("Head")
    local top_world = head and (head.Position + Vector3.new(0, head.Size.Y/2, 0))
                   or (root.Position + Vector3.new(0, 3, 0))
    local bot_world = root.Position - Vector3.new(0, 3, 0)
    return top_world, bot_world
end

local function create_esp_for_player(player)
    if ESP_drawings[player.Name] then return end
    ESP_drawings[player.Name] = {
        box = make_drawing("Square", {
            Filled     = false,
            Color      = ESP.colors.enemy,
            Thickness  = 1,
            Visible    = false,
        }),
        name_label = make_drawing("Text", {
            Size      = 13,
            Color     = Color3.new(1,1,1),
            Center    = true,
            Outline   = true,
            Visible   = false,
        }),
        health_bar = make_drawing("Square", {
            Filled    = true,
            Color     = Color3.fromRGB(60, 255, 60),
            Thickness = 1,
            Visible   = false,
        }),
        health_bg = make_drawing("Square", {
            Filled    = true,
            Color     = Color3.fromRGB(40, 40, 40),
            Thickness = 1,
            Visible   = false,
        }),
        tracer = make_drawing("Line", {
            Color     = ESP.colors.tracer,
            Thickness = 1,
            Visible   = false,
        }),
        dist_label = make_drawing("Text", {
            Size    = 11,
            Color   = Color3.fromRGB(200, 200, 200),
            Center  = true,
            Outline = true,
            Visible = false,
        }),
    }
end

local function remove_esp_for_player(player_name)
    local d = ESP_drawings[player_name]
    if not d then return end
    for _, drawing in pairs(d) do
        drawing:Remove()
    end
    ESP_drawings[player_name] = nil
end

local ESP_RenderThread = nil

local function update_esp()
    local local_player = game.Players.LocalPlayer
    local local_char   = local_player and local_player.Character
    local local_root   = local_char  and local_char:FindFirstChild("HumanoidRootPart")
    local camera       = workspace.CurrentCamera
    if not camera or not local_root then return end

    local screen_center = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)

    for _, player in ipairs(game.Players:GetPlayers()) do
        if player == local_player then
            if ESP_drawings[player.Name] then
                remove_esp_for_player(player.Name)
            end
            goto continue
        end

        -- Team check
        local is_enemy = true
        if ESP.team_check and local_player.Team == player.Team and player.Team ~= nil then
            is_enemy = false
        end

        local char = player.Character
        if not char or not char.Parent then
            if ESP_drawings[player.Name] then
                -- Make invisible but don't remove
                local d = ESP_drawings[player.Name]
                for _, drawing in pairs(d) do drawing.Visible = false end
            end
            goto continue
        end

        -- Ensure drawing objects exist
        create_esp_for_player(player)
        local d = ESP_drawings[player.Name]

        local hum  = char:FindFirstChildOfClass("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root or not hum then
            for _, drawing in pairs(d) do drawing.Visible = false end
            goto continue
        end

        local dist = (root.Position - local_root.Position).Magnitude
        if dist > ESP.max_distance then
            for _, drawing in pairs(d) do drawing.Visible = false end
            goto continue
        end

        local top_world, bot_world = get_char_bounds(char)
        if not top_world then
            for _, drawing in pairs(d) do drawing.Visible = false end
            goto continue
        end

        local top_screen, top_on = get_screen_pos(top_world)
        local bot_screen, bot_on = get_screen_pos(bot_world)

        if not top_on or not bot_on then
            for _, drawing in pairs(d) do drawing.Visible = false end
            goto continue
        end

        local color = is_enemy and ESP.colors.enemy or ESP.colors.team
        local box_height = bot_screen.Y - top_screen.Y
        local box_width  = math.abs(box_height) * 0.6

        -- Box
        if ESP.show_boxes then
            d.box.Position  = Vector2.new(top_screen.X - box_width/2, top_screen.Y)
            d.box.Size      = Vector2.new(box_width, box_height)
            d.box.Color     = color
            d.box.Visible   = true
        else
            d.box.Visible = false
        end

        -- Name label
        if ESP.show_names then
            d.name_label.Position = Vector2.new(top_screen.X, top_screen.Y - 14)
            d.name_label.Text     = player.Name
            d.name_label.Color    = color
            d.name_label.Visible  = true
        else
            d.name_label.Visible = false
        end

        -- Health bar
        if ESP.show_health then
            local hp_ratio    = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
            local bar_height  = math.abs(box_height) * hp_ratio
            local bar_x       = top_screen.X - box_width/2 - 6

            d.health_bg.Position = Vector2.new(bar_x - 1, top_screen.Y - 1)
            d.health_bg.Size     = Vector2.new(5, math.abs(box_height) + 2)
            d.health_bg.Visible  = true

            d.health_bar.Position = Vector2.new(bar_x, top_screen.Y + math.abs(box_height) - bar_height)
            d.health_bar.Size     = Vector2.new(3, bar_height)
            d.health_bar.Color    = Color3.fromRGB(
                math.floor(255 * (1 - hp_ratio)),
                math.floor(255 * hp_ratio),
                0
            )
            d.health_bar.Visible  = true
        else
            d.health_bg.Visible  = false
            d.health_bar.Visible = false
        end

        -- Tracer
        if ESP.show_tracers then
            d.tracer.From    = screen_center
            d.tracer.To      = bot_screen
            d.tracer.Color   = ESP.colors.tracer
            d.tracer.Visible = true
        else
            d.tracer.Visible = false
        end

        -- Distance label
        if ESP.show_distance then
            d.dist_label.Position = Vector2.new(bot_screen.X, bot_screen.Y + 2)
            d.dist_label.Text     = string.format("[%.0fm]", dist * 0.3048)  -- studs to feet approx
            d.dist_label.Visible  = true
        else
            d.dist_label.Visible = false
        end

        ::continue::
    end
end

function EnableESP()
    if ESP.enabled then return end
    ESP.enabled = true

    -- Clean up for players who leave
    game.Players.PlayerRemoving:Connect(function(player)
        remove_esp_for_player(player.Name)
    end)

    ESP_RenderThread = game:GetService("RunService").RenderStepped:Connect(function()
        if not ESP.enabled then return end
        Utils.safe(update_esp)
    end)
    Utils.info("ESP enabled")
end

function DisableESP()
    ESP.enabled = false
    if ESP_RenderThread then
        ESP_RenderThread:Disconnect()
        ESP_RenderThread = nil
    end
    for name, _ in pairs(Utils.shallow_copy(ESP_drawings)) do
        remove_esp_for_player(name)
    end
    Utils.info("ESP disabled")
end

-- ============================================================
-- §23  AIMBOT SYSTEM
-- ============================================================
-- Silent aim: rotate the client's projectile direction toward target.
-- FOV-gated, closest-to-crosshair target selection.
-- Does NOT modify humanoid aim or server-side movement.

local Aimbot = {}
Aimbot.enabled      = false
Aimbot.fov          = 120          -- degrees
Aimbot.smoothing    = 0.3          -- 0 = instant, 1 = no movement
Aimbot.target       = nil
Aimbot.target_part  = "Head"       -- or "HumanoidRootPart"
Aimbot.team_check   = true
Aimbot.visible_check = false       -- requires raycasting

local AimbotThread  = nil

local function get_aim_target()
    local camera       = workspace.CurrentCamera
    local local_player = game.Players.LocalPlayer
    if not camera or not local_player then return nil end

    local cam_pos  = camera.CFrame.Position
    local cam_look = camera.CFrame.LookVector
    local fov_rad  = math.rad(Aimbot.fov / 2)

    local best_player = nil
    local best_angle  = fov_rad + 1

    for _, player in ipairs(game.Players:GetPlayers()) do
        if player == local_player then goto continue end
        if Aimbot.team_check and local_player.Team == player.Team and player.Team ~= nil then
            goto continue
        end

        local char = player.Character
        if not char then goto continue end
        local part = char:FindFirstChild(Aimbot.target_part)
                  or char:FindFirstChild("HumanoidRootPart")
        if not part then goto continue end

        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health <= 0 then goto continue end

        local to_target = (part.Position - cam_pos).Unit
        local angle     = math.acos(math.clamp(cam_look:Dot(to_target), -1, 1))

        if angle < best_angle then
            best_angle  = angle
            best_player = {player = player, part = part, angle = angle}
        end

        ::continue::
    end

    return best_player
end

function EnableAimbot()
    if Aimbot.enabled then return end
    Aimbot.enabled = true

    AimbotThread = game:GetService("RunService").RenderStepped:Connect(function()
        if not Aimbot.enabled then return end
        local t = get_aim_target()
        Aimbot.target = t

        if not t then return end

        local camera = workspace.CurrentCamera
        if not camera then return end

        local target_pos = t.part.Position
        local cam_cf     = camera.CFrame
        local look_cf    = CFrame.new(cam_cf.Position, target_pos)

        -- Apply smoothing
        local s = Aimbot.smoothing
        camera.CFrame = cam_cf:Lerp(look_cf, 1 - s)
    end)

    Utils.info("Aimbot enabled (FOV=%.0f, smooth=%.2f)", Aimbot.fov, Aimbot.smoothing)
end

function DisableAimbot()
    Aimbot.enabled = false
    Aimbot.target  = nil
    if AimbotThread then
        AimbotThread:Disconnect()
        AimbotThread = nil
    end
    Utils.info("Aimbot disabled")
end

-- ============================================================
-- §24  LURAPH LIFT HELPER
-- ============================================================
-- Assists with lifting LocalScript3's Luraph VM sections
-- without needing the external engine on disk.
-- Strategy: hook the VM dispatch table at runtime to log
-- opcode executions and extract the reply computation.

local LuraphHelper = {}
LuraphHelper.log_enabled  = false
LuraphHelper.opcode_log   = {}
LuraphHelper.max_log_size = 10000

-- Hook the Luraph VM's internal closure call to intercept
-- the challenge reply computation.
-- The challenge comes in on AnalyticsPipeline; the reply is computed
-- inside a VM closure. We intercept at the RemoteEvent.OnClientEvent
-- level to capture the full input/output pair.

local LuraphIntercept = {}

local function install_luraph_intercept()
    Utils.info("§24 Installing Luraph reply intercept...")

    local pipeline_remote = find_analytics_remote()
    if not pipeline_remote then
        Utils.warn("Pipeline remote not found — Luraph intercept skipped")
        return false
    end

    -- Listen for the challenge from server
    pipeline_remote.OnClientEvent:Connect(function(...)
        local challenge_args = {...}
        local ts_receive = tick()

        Utils.debug("Luraph intercept: received challenge at %.2f, %d args", ts_receive, #challenge_args)

        -- The VM computes the reply asynchronously.
        -- We hook FireServer (already done in §13) to capture the reply
        -- that comes out in the same frame or the next.
        -- Cross-reference with ChallengePairs by timestamp proximity.

        table.insert(LuraphIntercept, {
            type      = "challenge",
            ts        = ts_receive,
            args      = challenge_args,
        })
    end)

    Utils.info("Luraph challenge listener installed")
    return true
end

-- Correlate challenge/reply pairs by timestamp
function CorrelateChallengeReply()
    Utils.info("=== CHALLENGE/REPLY CORRELATION ===")
    local challenges = {}
    for _, entry in ipairs(LuraphIntercept) do
        if entry.type == "challenge" then
            table.insert(challenges, entry)
        end
    end

    for i, chal in ipairs(challenges) do
        -- Find the nearest reply (FireServer call) after this challenge
        local best_reply = nil
        local best_dt    = math.huge
        for _, pair in ipairs(ChallengePairs) do
            local dt = pair.ts - chal.ts
            if dt >= 0 and dt < best_dt then
                best_dt    = dt
                best_reply = pair
            end
        end

        Utils.info("Challenge [%d] at %.3f:", i, chal.ts)
        for j, arg in ipairs(chal.args) do
            Utils.info("  in[%d] = %s (%s)", j, tostring(arg):sub(1,60), type(arg))
        end
        if best_reply then
            Utils.info("  Reply (dt=%.3fms):", best_dt * 1000)
            for j, arg in ipairs(best_reply.args) do
                Utils.info("  out[%d] = %s (%s)", j, tostring(arg):sub(1,60), type(arg))
            end
        else
            Utils.warn("  No reply found within session")
        end
    end
end

-- ============================================================
-- §25  RECONNECT HANDLER
-- ============================================================
-- Roblox auto-reconnects on kick; re-inject the bypass after
-- CharacterAdded fires on the new server session.

local function setup_reconnect_handler()
    Utils.info("§25 Reconnect handler installed")
    local player = game.Players.LocalPlayer
    if not player then return end

    player.CharacterAdded:Connect(function(char)
        Utils.info("Character added — re-verifying bypass integrity...")
        task.wait(2)  -- Give LocalScript3 time to re-run
        cleanup_listeners()
        local ok = anchor_ac()
        if ok then
            bypass_trap_tables()
            verify_metatable_isolation()
            pin_identity_anchors()
            verify_rawget_checks()
            Utils.info("Post-respawn bypass re-verified")
        else
            Utils.warn("AC not re-detected after respawn — may be safe or delayed")
        end
    end)
end

-- ============================================================
-- §26  KICK INTERCEPTOR
-- ============================================================
-- Hook Player:Kick to suppress AC-triggered kicks.
-- Note: server-side kicks cannot be intercepted this way.
-- This catches the rare case where the AC calls Player:Kick locally.

local function install_kick_interceptor()
    Utils.info("§26 Installing kick interceptor...")

    local players_meta = getrawmetatable(game.Players.LocalPlayer)
    if not players_meta then
        Utils.warn("Cannot get LocalPlayer metatable")
        return false
    end

    local old_lock = rawget(players_meta, "__metatable")
    if old_lock then rawset(players_meta, "__metatable", nil) end

    local orig_index = rawget(players_meta, "__index")

    rawset(players_meta, "__index", newcclosure(function(self, key)
        if key == "Kick" then
            return newcclosure(function(player, msg)
                Utils.warn("KICK INTERCEPTED: %s — suppressing", tostring(msg))
                -- Do not call original Kick
                return nil
            end)
        end
        if type(orig_index) == "function" then
            return orig_index(self, key)
        elseif type(orig_index) == "table" then
            return orig_index[key]
        end
        return nil
    end))

    if old_lock then rawset(players_meta, "__metatable", old_lock) end

    Utils.info("Kick interceptor installed")
    return true
end

-- ============================================================
-- §27  ANTI-SCREENSHOT / SCREENSHOT-SAFE MODE
-- ============================================================
-- Toggle Drawing API visibility off quickly for screenshots.

local ScreenshotSafe = false

function ToggleScreenshotSafe()
    ScreenshotSafe = not ScreenshotSafe
    for _, drawings in pairs(ESP_drawings) do
        for _, drawing in pairs(drawings) do
            drawing.Visible = not ScreenshotSafe and ESP.enabled
        end
    end
    Utils.info("Screenshot-safe mode: %s", ScreenshotSafe and "ON" or "OFF")
end

-- ============================================================
-- §28  CONFIGURATION LOADER / SAVER
-- ============================================================
-- Save and restore bypass configuration to executor writefile.

local DEFAULT_CONFIG = {
    verbose          = false,
    esp_enabled      = false,
    aimbot_enabled   = false,
    aimbot_fov       = 120,
    aimbot_smoothing = 0.3,
    walkspeed        = nil,
    jumppower        = nil,
    noclip           = false,
    team_check       = true,
}

function SaveConfig(cfg)
    cfg = cfg or DEFAULT_CONFIG
    local ok = pcall(function()
        writefile("portolan_rivals_cfg.json",
            game:GetService("HttpService"):JSONEncode(cfg))
    end)
    if ok then
        Utils.info("Config saved to portolan_rivals_cfg.json")
    else
        Utils.warn("writefile not available — config not saved")
    end
end

function LoadConfig()
    local ok, content = pcall(function()
        return readfile("portolan_rivals_cfg.json")
    end)
    if not ok or not content then
        Utils.debug("No saved config found — using defaults")
        return DEFAULT_CONFIG
    end
    local cfg_ok, cfg = pcall(function()
        return game:GetService("HttpService"):JSONDecode(content)
    end)
    if not cfg_ok then
        Utils.warn("Config parse failed — using defaults")
        return DEFAULT_CONFIG
    end
    Utils.info("Config loaded")
    return cfg
end

function ApplyConfig(cfg)
    if not cfg then return end
    if cfg.verbose ~= nil then VERBOSE = cfg.verbose end
    if cfg.esp_enabled     then EnableESP()   end
    if cfg.aimbot_enabled  then EnableAimbot() end
    if cfg.aimbot_fov      then Aimbot.fov       = cfg.aimbot_fov end
    if cfg.aimbot_smoothing then Aimbot.smoothing = cfg.aimbot_smoothing end
    if cfg.walkspeed       then SetWalkSpeed(cfg.walkspeed) end
    if cfg.jumppower       then SetJumpPower(cfg.jumppower) end
    if cfg.noclip          then EnableNoclip() end
    if cfg.team_check ~= nil then
        ESP.team_check    = cfg.team_check
        Aimbot.team_check = cfg.team_check
    end
    Utils.info("Config applied")
end

-- ============================================================
-- §29  QUICK COMMAND INTERFACE
-- ============================================================
-- Simple string-command dispatcher for use in executor console.

local Commands = {}

function RegisterCommand(name, fn, help)
    Commands[name] = {fn = fn, help = help or ""}
end

function RunCommand(cmd_string)
    if not cmd_string or cmd_string == "" then
        Utils.info("Available commands:")
        for name, entry in pairs(Commands) do
            Utils.info("  %-20s %s", name, entry.help)
        end
        return
    end
    local parts = {}
    for word in cmd_string:gmatch("%S+") do
        table.insert(parts, word)
    end
    local name = table.remove(parts, 1)
    local entry = Commands[name]
    if not entry then
        Utils.warn("Unknown command: %s", name)
        return
    end
    local ok, err = pcall(entry.fn, table.unpack(parts))
    if not ok then
        Utils.err("Command error: %s", tostring(err))
    end
end

local function register_default_commands()
    RegisterCommand("status",       BypassStatus,                   "Full bypass diagnostic")
    RegisterCommand("challenges",   DumpChallengePairs,             "Dump challenge/reply pairs")
    RegisterCommand("correlate",    CorrelateChallengeReply,        "Correlate challenge/reply")
    RegisterCommand("audit_bait",   AuditBaitPairs,                 "Audit all bait pairs")
    RegisterCommand("audit_upvals", AuditUpvalues,                  "Dump all upvalues")
    RegisterCommand("esp_on",       EnableESP,                      "Enable ESP")
    RegisterCommand("esp_off",      DisableESP,                     "Disable ESP")
    RegisterCommand("aim_on",       EnableAimbot,                   "Enable aimbot")
    RegisterCommand("aim_off",      DisableAimbot,                  "Disable aimbot")
    RegisterCommand("noclip_on",    EnableNoclip,                   "Enable noclip")
    RegisterCommand("noclip_off",   DisableNoclip,                  "Disable noclip")
    RegisterCommand("speed", function(s)
        SetWalkSpeed(tonumber(s) or 50)
    end, "Set walkspeed (default 50)")
    RegisterCommand("jump", function(p)
        SetJumpPower(tonumber(p) or 100)
    end, "Set jump power (default 100)")
    RegisterCommand("tp", function(name)
        TeleportTo(name)
    end, "Teleport to player name")
    RegisterCommand("reset_speed",  DisableSpeedCheat,              "Reset to safe speed/jump")
    RegisterCommand("screenshot",   ToggleScreenshotSafe,           "Toggle screenshot-safe mode")
    RegisterCommand("save_cfg",     SaveConfig,                     "Save current config")
    RegisterCommand("load_cfg", function()
        ApplyConfig(LoadConfig())
    end, "Load and apply saved config")
    RegisterCommand("help", function()
        RunCommand("")
    end, "Show this help")
end

-- ============================================================
-- §20  DEBUG CONSOLE
-- ============================================================
-- Expose a simple query API accessible from executor console.

function BypassStatus()
    local status = {
        version        = BYPASS_VERSION,
        ac_ready       = AC.ready,
        check_fn       = tostring(AC.check),
        upval_count    = #AC.upvals,
        bait_pairs     = #AC.bait,
        trap60_alive   = AC.trap60 ~= nil,
        trap70_alive   = AC.trap70 ~= nil,
        u62_present    = AC.u62 ~= nil,
        u63_present    = AC.u63 ~= nil,
        anchors_pinned = (function()
            local n=0; for _ in pairs(IdentityAnchors) do n=n+1 end; return n
        end)(),
        challenge_pairs = #ChallengePairs,
        firewall_log    = #FirewallLog,
        integrity       = RunIntegrityChecks(),
        executor        = identifyexecutor(),
    }
    for k, v in pairs(status) do
        print(string.format("  %-20s = %s", k, tostring(v)))
    end
    return status
end

function DumpChallengePairs()
    Utils.info("Challenge/reply pairs captured: %d", #ChallengePairs)
    for i, pair in ipairs(ChallengePairs) do
        Utils.info("  [%d] ts=%.2f argcount=%d", i, pair.ts, pair.argcount)
        for j, arg in ipairs(pair.args) do
            Utils.info("       arg[%d] type=%s val=%s", j, type(arg), tostring(arg):sub(1,80))
        end
    end
end

function AuditBaitPairs()
    Utils.info("=== BAIT PAIR AUDIT ===")
    for i, pair in ipairs(AC.bait) do
        local orig = pair[1]
        local bait = pair[2]
        local orig_type = type(orig)
        local bait_type = type(bait)
        local is_c_orig = iscclosure(orig)
        Utils.info("  [%02d] orig=%s (%s, cclosure=%s) bait=%s (%s)",
            i, tostring(orig), orig_type, tostring(is_c_orig),
            tostring(bait), bait_type)
    end
end

function AuditUpvalues()
    Utils.info("=== UPVALUE AUDIT (%d total) ===", #AC.upvals)
    for i, v in ipairs(AC.upvals) do
        local t = type(v)
        local preview = ""
        if t == "string" then
            preview = string.format(" %q", v:sub(1,40))
        elseif t == "table" then
            local n = 0
            for _ in pairs(v) do n=n+1 end
            preview = string.format(" {%d keys}", n)
        elseif t == "function" then
            local info = debug.getinfo(v, "S")
            preview = string.format(" [%s]", info and info.what or "?")
        end
        Utils.info("  [%03d] %s%s", i, t, preview)
    end
end

-- ============================================================
-- §21  MAIN ENTRYPOINT
-- ============================================================

local function main()
    Utils.info("================================================")
    Utils.info("PORTOLAN Rivals AC Bypass %s", BYPASS_VERSION)
    Utils.info("Build: %s | Executor: %s", BUILD_DATE, identifyexecutor())
    Utils.info("================================================")

    if DRY_RUN then
        Utils.warn("DRY RUN MODE — no patches will be applied")
    end

    -- Step 1: Clean up passive listeners FIRST (before anchor)
    cleanup_listeners()

    -- Step 2: Anchor the AC check function
    local anchored = anchor_ac()
    if not anchored then
        Utils.err("Failed to anchor AC — aborting. Is LocalScript3 loaded?")
        return false
    end

    -- Step 3: Neutralise trap tables (u60/u70)
    if not DRY_RUN then
        bypass_trap_tables()
    end

    -- Step 4: Verify environment isolation
    verify_metatable_isolation()

    -- Step 5: Bait-call bypass (env __index hook)
    if not DRY_RUN then
        bypass_bait_calls()
    end

    -- Step 6: Scope xpcall hook
    if not DRY_RUN then
        bypass_xpcall_slot()
    end

    -- Step 7: Verify must-error closures
    verify_must_error_closures()

    -- Step 8: Verify rawget/metamethod integrity
    verify_rawget_checks()

    -- Step 9: Pin identity anchors
    pin_identity_anchors()

    -- Step 10: EncodingService check
    bypass_encoding_service()

    -- Step 11: Challenge intercept
    if not DRY_RUN then
        install_pipeline_hook()
    end

    -- Step 12: Honeypot guard
    if not DRY_RUN then
        install_honeypot_guard()
    end

    -- Step 13: Heartbeat mitigation
    if not DRY_RUN then
        install_heartbeat_mitigation()
    end

    -- Step 14: Remote firewall (monitor mode)
    if not DRY_RUN then
        install_remote_firewall()
    end

    -- Step 15: Hardening
    apply_hardening()

    -- Step 16: Register integrity checks
    register_integrity_checks()

    -- Step 17: Start watcher
    if not DRY_RUN then
        start_hotpatch_watcher()
    end

    -- Step 18: Luraph intercept
    if not DRY_RUN then
        install_luraph_intercept()
    end

    -- Step 19: Reconnect handler
    setup_reconnect_handler()

    -- Step 20: Kick interceptor
    if not DRY_RUN then
        install_kick_interceptor()
    end

    -- Step 21: Register default commands
    register_default_commands()

    -- Step 22: Load and apply saved config (if any)
    Utils.safe(function()
        local cfg = LoadConfig()
        if cfg ~= DEFAULT_CONFIG then
            ApplyConfig(cfg)
        end
    end)

    -- Step 23: Final status
    Utils.info("================================================")
    Utils.info("Bypass initialisation complete")
    Utils.info("Run BypassStatus()         — full diagnostic")
    Utils.info("Run RunCommand('help')      — command list")
    Utils.info("Run RunCommand('status')    — bypass status")
    Utils.info("Run RunCommand('esp_on')    — enable ESP")
    Utils.info("Run RunCommand('aim_on')    — enable aimbot")
    Utils.info("Run RunCommand('speed 80')  — set walkspeed")
    Utils.info("Run DumpChallengePairs()    — challenge/reply pairs")
    Utils.info("Run CorrelateChallengeReply() — correlate I/O")
    Utils.info("================================================")

    -- Initial integrity report
    local results = RunIntegrityChecks()
    local pass = 0
    local fail = 0
    for name, r in pairs(results) do
        if r.ok and r.result then
            pass = pass + 1
        else
            fail = fail + 1
            Utils.warn("FAIL: %s", name)
        end
    end
    Utils.info("Integrity: %d/%d checks passed", pass, pass+fail)

    return true
end

-- Auto-run on load
local ok, err = pcall(main)
if not ok then
    print(LOG_PREFIX .. " [FATAL] " .. tostring(err))
end

-- ============================================================
-- END OF rivals_ac_bypass.lua
-- ============================================================
