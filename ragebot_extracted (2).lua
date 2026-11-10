-- =======================================================================
--  RAGEBOT — Complete Extraction from graviton_final-2.lua
--  Game: Rivals (Roblox)   |   Framework: Graviton / KiciaRebuild
-- =======================================================================
-- Drop-in standalone ragebot module.  Expects the same game environment
-- as the original script (Rivals).  Set getgenv().GravitonConfig to the
-- existing ReactiveStore if the main script is also loaded, or let this
-- script create its own minimal config store.
-- =======================================================================

if getgenv()._RagebotRunning and getgenv()._RagebotCleanup then
    pcall(getgenv()._RagebotCleanup)
    task.wait(0.1)
end
getgenv()._RagebotRunning = true

if not game:IsLoaded() then game.Loaded:Wait() end

-- ─── Services ───────────────────────────────────────────────────────────
local Players          = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local HttpService      = game:GetService("HttpService")
local lp              = Players.LocalPlayer

-- ─── Executor helpers ───────────────────────────────────────────────────
local function _fn(name)
    local v
    pcall(function() v = getfenv(0)[name] end)
    if type(v) ~= "function" then pcall(function() v = getfenv()[name] end) end
    return type(v) == "function" and v or nil
end
local cloneref           = _fn("cloneref")           or function(x) return x end
local sethiddenproperty  = _fn("sethiddenproperty")
local setfflag           = _fn("setfflag")           or function() end
local setrawmetatable    = _fn("setrawmetatable")    or setmetatable
local getrawmetatable    = _fn("getrawmetatable")    or getmetatable
local isexecutorclosure  = _fn("isexecutorclosure")  or function() return false end
local setclipboard       = _fn("setclipboard") or _fn("toclipboard") or function() end
local getconnections     = _fn("getconnections")     or function() return {} end
local firetouchinterest  = _fn("firetouchinterest")  or function() end

local function clonefn(f)
    local c = _fn("clonefunction")
    if c and f then local ok, r = pcall(c, f); if ok and r then return r end end
    return f
end
local v112 = clonefn(getrawmetatable(game).__newindex)
local v108 = clonefn(setfflag)
local fireServer  = clonefn(Instance.new("RemoteEvent").FireServer)
local fireServer2 = clonefn(Instance.new("UnreliableRemoteEvent").FireServer)

-- ─── Trove (mini cleanup helper) ────────────────────────────────────────
local Trove = {}
Trove.__index = Trove
function Trove.new(name)
    return setmetatable({ _name = name, _items = {}, _cleaning = false }, Trove)
end
local function _cleanItem(o)
    local t = typeof(o)
    if t == "RBXScriptConnection" then o:Disconnect()
    elseif t == "Instance" then pcall(o.Destroy, o)
    elseif t == "thread" then pcall(task.cancel, o)
    elseif type(o) == "function" then pcall(o)
    elseif type(o) == "table" then
        local function mem(k) local ok,v=pcall(function()return o[k]end); return ok and type(v)=="function" and v or nil end
        local cancel,getStatus = mem("cancel"),mem("getStatus")
        if cancel and getStatus then pcall(cancel,o) return end
        local destroy = mem("Destroy");  if destroy then pcall(destroy,o) return end
        local disc    = mem("Disconnect"); if disc then pcall(disc,o) end
    end
end
function Trove:Add(o)   table.insert(self._items, o); return o end
function Trove:Connect(sig, fn) return self:Add(sig:Connect(fn)) end
function Trove:Extend()  return self:Add(Trove.new(self._name)) end
function Trove:Remove(o, keep)
    local i = table.find(self._items, o)
    if i then table.remove(self._items, i); if not keep then _cleanItem(o) end end
end
function Trove:Clean()
    local items, self._items = self._items, {}
    self._cleaning = true
    for i = #items, 1, -1 do _cleanItem(items[i]) end
    self._cleaning = false
end
Trove.Destroy = Trove.Clean

-- ─── Signal ─────────────────────────────────────────────────────────────
local Signal = {}
Signal.__index = Signal
function Signal.new() return setmetatable({ _handlers = {} }, Signal) end
function Signal:Connect(fn)
    local h = { fn = fn, connected = true }
    table.insert(self._handlers, h)
    local sig = self
    return { Connected = true, Disconnect = function(c)
        if not h.connected then return end
        h.connected = false; c.Connected = false
        local i = table.find(sig._handlers, h); if i then table.remove(sig._handlers, i) end
    end }
end
function Signal:Fire(...)
    for _, h in ipairs(table.clone(self._handlers)) do
        if h.connected then task.spawn(h.fn, ...) end
    end
end
function Signal:FireSync(...)
    for _, h in ipairs(table.clone(self._handlers)) do if h.connected then h.fn(...) end end
end
function Signal:Destroy() table.clear(self._handlers) end

-- ─── v86 constant pool ──────────────────────────────────────────────────
local v86 = {
    [6]=0,[18]="0",[34]=true,[45]=90,[48]=0.3,[56]=2,[62]=0.1,[63]=1,[75]="None",
    [83]=64,[91]=100,[95]="number",[101]=0.5,[108]=255,[116]="boolean",[118]=16,
    [122]=8,[126]=0.15,[127]="CFrame",[128]="Frame",[133]=14,[137]=256,[147]=0.1,
    [149]=1,[153]=false,[155]=3,[160]=50,[162]=8,[165]="string",[170]=9,[173]=0.88,
    [175]=8,[181]=10,[186]=0,[192]=30,[195]=0.7,[3]="Toggle",[9]=20,[12]=12,
    [26]=4,[44]="Enabled",[53]=92,[55]="Mode",[160]=50,
}
-- flag2/flag3: obfuscator integrity counters (always true in live builds)
local flag2, flag3 = true, true

-- ═══════════════════════════════════════════════════════════════════════
--  CONFIG STORE
--  If the main Graviton script is loaded, borrow its ReactiveStore.
--  Otherwise create a plain reactive table.
-- ═══════════════════════════════════════════════════════════════════════
local gc  -- will be assigned below
do
    -- Try to reuse existing GravitonConfig
    local existing = rawget(getgenv(), "GravitonConfig")
    if existing and type(existing) == "table" and type(existing.Data) == "table" then
        gc = existing
    else
        -- Minimal stand-alone config store
        local _data = {
            Ragebot = {
                Enabled         = false,
                Keybind         = { Bind = Enum.KeyCode.Unknown },
                PrioritizeHackers   = false,
                UtilizeHealthLead   = false,
                Stability           = 0,
                ShootFrames         = 2,
                EnemiesOnly         = true,
                IgnoreKnocked       = false,
                IgnoreForceField    = true,
                TargetPriority      = "Closest",
                AimPart             = "Head",
                Weapons = {
                    Enabled  = { Primary = true, Secondary = true, Melee = false },
                    Priority = "Primary First",
                    OnEmpty  = "SwapOrReload",
                },
                Evasion = {
                    Mode = "Off",
                    Random = { BaseRadius = 50, RadiusRandomFactor = 0.5, AnchorFromCharacter = false },
                    Translocate = { Offset = 0 },
                    ProjectileBreaker = {
                        DepthForward        = { Min = 0, Max = 4 },
                        DepthForwardFrequency = 5,
                        DepthUp             = { Min = 0, Max = 5.5 },
                        DepthUpFrequency    = 5,
                        RepositionInterval  = 0.3,
                        FallbackAnchorFromCharacter = false,
                        FallbackBaseRadius          = 100,
                        FallbackRadiusRandomFactor  = 0.5,
                    },
                },
                VoidSpam    = { HideTime = 0.25, AttackTime = 0.1 },
                TeleportV2  = { Offset = 0 },
                HarionVoid  = { HideTime = 0.25, ShootTime = 0.03 },
                OrbitDesync = { Radius = 3, Height = 1.5, StrafeSpeed = 2 },
            },
        }

        -- Deep-get/set for dot-path tables
        local _obs = {}
        local function _deepSet(t, keys, v)
            for i = 1, #keys - 1 do
                if type(t[keys[i]]) ~= "table" then t[keys[i]] = {} end
                t = t[keys[i]]
            end
            t[keys[#keys]] = v
            -- fire observers for path prefix
            for path, cbs in pairs(_obs) do
                local match = true
                local kk = string.split(path, ".")
                for i, k in ipairs(kk) do if keys[i] ~= k then match = false break end end
                if match then for _, cb in ipairs(cbs) do pcall(cb, v) end end
            end
        end
        local function _deepGet(t, keys)
            for _, k in ipairs(keys) do
                if type(t) ~= "table" then return nil end
                t = t[k]
            end
            return t
        end

        gc = {
            Data = _data,
            Get = function(_, path)
                if type(path) == "string" then path = string.split(path, ".") end
                return _deepGet(_data, path)
            end,
            Set = function(_, path, v)
                if type(path) == "string" then path = string.split(path, ".") end
                _deepSet(_data, path, v)
            end,
            Changed = function(_, path)
                if type(path) == "string" then path = string.split(path, ".") end
                local key = table.concat(path, ".")
                if not _obs[key] then _obs[key] = {} end
                local sig = Signal.new()
                table.insert(_obs[key], function(v) sig:Fire(v) end)
                return sig
            end,
        }
        getgenv().GravitonConfig = gc
    end

    -- Ensure Ragebot sub-table exists
    if type(gc.Data.Ragebot) ~= "table" then
        gc.Data.Ragebot = {
            Enabled=false, PrioritizeHackers=false, UtilizeHealthLead=false,
            Stability=0, ShootFrames=2, EnemiesOnly=true,
            IgnoreKnocked=false, IgnoreForceField=true,
            TargetPriority="Closest", AimPart="Head",
            Keybind={Bind=Enum.KeyCode.Unknown},
            Weapons={Enabled={Primary=true,Secondary=true,Melee=false},Priority="Primary First",OnEmpty="SwapOrReload"},
            Evasion={Mode="Off",Random={BaseRadius=50,RadiusRandomFactor=0.5,AnchorFromCharacter=false},Translocate={Offset=0},
                ProjectileBreaker={DepthForward={Min=0,Max=4},DepthForwardFrequency=5,DepthUp={Min=0,Max=5.5},DepthUpFrequency=5,RepositionInterval=0.3,FallbackAnchorFromCharacter=false,FallbackBaseRadius=100,FallbackRadiusRandomFactor=0.5}},
            VoidSpam={HideTime=0.25,AttackTime=0.1},TeleportV2={Offset=0},
            HarionVoid={HideTime=0.25,ShootTime=0.03},
            OrbitDesync={Radius=3,Height=1.5,StrafeSpeed=2},
        }
    end
end

-- ═══════════════════════════════════════════════════════════════════════
--  MODULE CACHE (tbl17 stand-in for ragebot-only modules)
-- ═══════════════════════════════════════════════════════════════════════
-- If the full Graviton tbl17 exists in the global env, borrow it.
-- Otherwise build a minimal stub cache.
local tbl17 = rawget(getgenv(), "_kicia_tbl17") or { cache = {} }
-- Always expose bG() so our modules below can call it.
tbl17.bG = tbl17.bG or function() return gc end
tbl17.k  = tbl17.k  or function() return { new = function(name) return Trove.new(name) end } end

-- pcall wrapper
local v107 = pcall

-- ─── jy  — Riot-shield orientation helper ───────────────────────────────
do
    local function fn35()
        -- Try to pull from existing tbl17; fall back to plain stub.
        if tbl17.cache.jy and tbl17.cache.jy.c then return tbl17.cache.jy.c end
        local function fn36(arg)
            local itemObserver = arg.ItemObserver
            if not itemObserver then return v86[75] end
            local equippedItem = itemObserver:GetEquippedItem and itemObserver:GetEquippedItem()
            if equippedItem ~= nil and equippedItem.Name == "Riot Shield" then
                local deg = math.deg(arg:GetCameraRotation and arg:GetCameraRotation().X or 0)
                if deg > 22 and deg < 91 then return "Below" end
                return "Above"
            end
            if itemObserver.GetItems then
                for _, v in itemObserver:GetItems() do
                    if v.Name == "Riot Shield" then
                        local deg = math.deg(arg:GetCameraRotation and arg:GetCameraRotation().X or 0)
                        if (deg > 315 and deg < 360) or (deg > 0 and deg < 91) then return "Above" end
                        return "Below"
                    end
                end
            end
            return v86[75]
        end
        if not flag2 then return end
        return fn36
    end
    tbl17.jy = tbl17.jy or function()
        if not tbl17.cache.jy then tbl17.cache.jy = { c = fn35() } end
        return tbl17.cache.jy.c
    end
end

-- ─── jz  — Defensive CFrame helpers ────────────────────────────────────
do
    local function fn35()
        if tbl17.cache.jz and tbl17.cache.jz.c then return tbl17.cache.jz.c end
        local v115 = tbl17.jy()
        local rng   = Random.new()
        return {
            getDefensiveCFrame = function(arg, arg2, arg3, arg4)
                if arg2 == "Equipped" then
                    return CFrame.new(arg.Position, arg4.Position)
                end
                if arg2 == "Unequipped" then
                    return CFrame.new(arg.Position, arg.Position + arg.Position - arg4.Position)
                end
                local melee = arg3.ItemObserver and arg3.ItemObserver:EquippedItemAsMelee and arg3.ItemObserver:EquippedItemAsMelee()
                if melee ~= nil and melee.Name == "Knife" then
                    local tau = math.pi * 2
                    return CFrame.new(arg.Position) * CFrame.fromOrientation(
                        rng:NextNumber(0, tau), rng:NextNumber(0, tau), rng:NextNumber(0, tau))
                end
                return arg
            end,
            getDefensiveViewAngles = function(arg, arg2)
                if arg == "None" then return nil end
                return {
                    Kind  = "Normalized",
                    Pitch = (arg == "Equipped") ~= (v115 and v115(arg2) == "Below") and v86[45] or -90,
                    Yaw   = rng:NextNumber(0, 360),
                }
            end,
        }
    end
    tbl17.jz = tbl17.jz or function()
        if not tbl17.cache.jz then tbl17.cache.jz = { c = fn35() } end
        return tbl17.cache.jz.c
    end
end

-- ─── jA  — ShootLock ────────────────────────────────────────────────────
do
    local function fn35()
        if tbl17.cache.jA and tbl17.cache.jA.c then return tbl17.cache.jA.c end
        local idx = {}
        idx.__index = idx
        idx.new = function() return setmetatable({}, idx) end
        idx.ShouldFire = function(self, trigger, lockDuration)
            local now = os.clock()
            local locked = self._lockedUntil ~= nil and now < self._lockedUntil
            if trigger then self._lockedUntil = now + lockDuration end
            return locked or trigger
        end
        idx.Reset = function(self) self._lockedUntil = nil end
        return idx
    end
    tbl17.jA = tbl17.jA or function()
        if not tbl17.cache.jA then tbl17.cache.jA = { c = fn35() } end
        return tbl17.cache.jA.c
    end
end

-- ─── jB  — TargetSelection ──────────────────────────────────────────────
do
    local function fn35()
        if tbl17.cache.jB and tbl17.cache.jB.c then return tbl17.cache.jB.c end
        local v115 = tbl17.bG()

        local function isValidTarget(fighterState)
            if not fighterState.IsEnemy then return false end
            if pcall(fighterState.IsInvincible, fighterState) and fighterState:IsInvincible() then return false end
            local charState = fighterState.Character and fighterState.Character.State
            if not charState or not charState.Alive then return false end
            local melee = fighterState.ItemObserver and fighterState.ItemObserver:EquippedItemAsMelee
                and fighterState.ItemObserver:EquippedItemAsMelee()
            if melee and pcall(melee.IsDeflecting, melee) and melee:IsDeflecting() then return false end
            return true
        end

        local function wrap(fs)
            return { FighterState = fs, AliveState = fs.Character.State }
        end

        local idx = {}
        idx.__index = idx
        idx.new = function(fighters, tags)
            return setmetatable({ _fighters = fighters, _playerTags = tags }, idx)
        end
        idx.GetTarget = function(self)
            local pri = v115.Data.Ragebot.PrioritizeHackers
            if pri and self._playerTags then
                for _, pl in self._playerTags:GetPlayersWith("Hacker") do
                    local fs = self._fighters.StateByPlayer[pl]
                    if fs and isValidTarget(fs) then return wrap(fs) end
                end
            end
            for pl, fs in self._fighters.EnemyByPlayer do
                if pri and self._playerTags and self._playerTags:Has(pl, "Hacker") then continue end
                if isValidTarget(fs) then return wrap(fs) end
            end
            return nil
        end
        idx.HasTargets = function(self)
            for _, fs in self._fighters.EnemyByPlayer do
                if isValidTarget(fs) then return true end
            end
            return false
        end
        idx.IsSameTarget = function(self, other)
            return self.FighterState == other.FighterState and self.AliveState == other.AliveState
        end
        return idx
    end
    tbl17.jB = tbl17.jB or function()
        if not tbl17.cache.jB then tbl17.cache.jB = { c = fn35() } end
        return tbl17.cache.jB.c
    end
end

-- ─── jC  — lookAtFlat helper ────────────────────────────────────────────
do
    local function fn35()
        if tbl17.cache.jC and tbl17.cache.jC.c then return tbl17.cache.jC.c end
        local up   = Vector3.new(0, -v86[63], 0)
        local fwd  = Vector3.new(0, 0, -v86[63])
        return function(from, to)
            local n = to - from
            local flat = Vector3.new(n.X, v86[186], n.Z)
            if flat.Magnitude < 0.001 then flat = fwd end
            return CFrame.lookAt(from, from + flat, up)
        end
    end
    tbl17.jC = tbl17.jC or function()
        if not tbl17.cache.jC then tbl17.cache.jC = { c = fn35() } end
        return tbl17.cache.jC.c
    end
end

-- ─── jD  — HitscanStrategy ──────────────────────────────────────────────
do
    local function fn35()
        if tbl17.cache.jD and tbl17.cache.jD.c then return tbl17.cache.jD.c end
        local cfg    = tbl17.bG()
        local ShootLock = tbl17.jA()
        local shieldDir = tbl17.jy()
        local lookFlat  = tbl17.jC()
        local offAbove = Vector3.new(0, -0.7,  0.05)
        local offBelow = Vector3.new(0, -3.85, 0.05)
        local angAboveMin = { ["\0"]=-9e37,["\1"]=0,     ["\2"]=0,         ["\3"]=-1.5707963267948966,["\4"]=3.14159,["\5"]=3.14159 }
        local angAboveMax = { ["\0"]=0,    ["\1"]=-90e6, ["\2"]=0,         ["\3"]=-1.5707963267948966,["\4"]=3.14159,["\5"]=3.14159 }
        local angBelowMin = { ["\0"]=-9e37,["\1"]=0,     ["\2"]=0,         ["\3"]=1.5707963267948966, ["\4"]=3.14159,["\5"]=3.14159 }
        local angBelowMax = { ["\0"]=0,    ["\1"]=90e6,  ["\2"]=0,         ["\3"]=1.5707963267948966, ["\4"]=3.14159,["\5"]=3.14159 }
        local angTail     = { ["\0"]=0,    ["\1"]=1,     ["\2"]=v86[186],  ["\3"]=v86[186],["\4"]=0,  ["\5"]=0 }

        local idx = {}
        idx.__index = idx
        idx.new = function(partGlue)
            return setmetatable({ _partGlue = partGlue, _shootLock = ShootLock.new() }, idx)
        end
        idx.Plan = function(self, dt, target, item, ourPart, inLimit)
            local hs     = target.AliveState.HitboxHead
            local above  = shieldDir and shieldDir(target.FighterState) ~= "Below" or true
            local offset = above and offAbove or offBelow
            local glued  = self._partGlue and self._partGlue:Acquire(ourPart, hs)
                           or (hs and hs.CFrame or CFrame.new())
            local n
            if above then
                n = glued + offset
            else
                n = lookFlat(glued.Position + offset, hs.Position)
            end
            local rbcfg  = cfg.Data.Ragebot
            if not self._shootLock:ShouldFire(inLimit, dt * rbcfg.ShootFrames) then
                return CFrame.new(math.random(-1e6,1e6), math.random(5000,10000), math.random(-1e6,1e6)), nil
            end
            local minAng = above and angAboveMin or angBelowMin
            local maxAng = above and angAboveMax or angBelowMax
            return n, function() item:ShootEncoded(minAng, maxAng, hs, angTail) end
        end
        return idx
    end
    tbl17.jD = tbl17.jD or function()
        if not tbl17.cache.jD then tbl17.cache.jD = { c = fn35() } end
        return tbl17.cache.jD.c
    end
end

-- ─── jE  — MeleeStrategy ────────────────────────────────────────────────
do
    local function fn35()
        if tbl17.cache.jE and tbl17.cache.jE.c then return tbl17.cache.jE.c end
        local cfg       = tbl17.bG()
        local ShootLock = tbl17.jA()
        local shieldDir = tbl17.jy()
        local lookFlat  = tbl17.jC()
        local offAbove  = Vector3.new(0, -v86[195], 0.05)
        local offBelow  = Vector3.new(v86[186], -3.85, 0.05)
        local aAMin = { ["\0"]=-9e37,["\1"]=0,    ["\2"]=0,        ["\3"]=-1.5707963267948966,["\4"]=3.14159,["\5"]=3.14159 }
        local aAMax = { ["\0"]=0,    ["\1"]=-90e6,["\2"]=v86[186], ["\3"]=-1.5707963267948966,["\4"]=3.14159,["\5"]=3.14159 }
        local aBMin = { ["\0"]=-9e37,["\1"]=0,    ["\2"]=v86[186], ["\3"]=1.5707963267948966, ["\4"]=3.14159,["\5"]=3.14159 }
        local aBMax = { ["\0"]=0,    ["\1"]=90e6, ["\2"]=v86[186], ["\3"]=1.5707963267948966, ["\4"]=3.14159,["\5"]=3.14159 }
        local aTail = { ["\0"]=0,    ["\1"]=1,    ["\2"]=v86[186], ["\3"]=0,["\4"]=0,["\5"]=0 }

        local function rand()
            return CFrame.new(math.random(-10000000,-100000), math.random(5000,10000), math.random(-10000000,-100000))
        end
        local function normAngles(pitch, yaw)
            return { Kind="Normalized", Pitch=math.deg(pitch), Yaw=math.deg(yaw) }
        end
        local function mergeAng(base, p3, p4, p5)
            return { ["\0"]=base["\0"],["\1"]=base["\1"],["\2"]=base["\2"],["\3"]=p3,["\4"]=p4,["\5"]=p5 }
        end

        local idx = {}
        idx.__index = idx
        idx.new = function(partGlue)
            return setmetatable({
                _partGlue = partGlue, _shootLock = ShootLock.new(),
                _hitboxWindowUntil = -1, _attackCooldown = -1
            }, idx)
        end
        idx.Plan = function(self, dt, target, item, ourPart, inLimit)
            local aliveState = target.AliveState
            local hs     = aliveState.HitboxHead
            local above  = shieldDir and shieldDir(target.FighterState) ~= "Below" or true
            local offset = above and offAbove or offBelow
            local glued  = self._partGlue and self._partGlue:Acquire(ourPart, hs)
                           or (hs and hs.CFrame or CFrame.new())
            self._gluedOurPart = ourPart
            local n
            if above then n = glued + offset
            else          n = lookFlat(glued.Position + offset, hs.Position) end

            local rx, ry, rz = aliveState.RootPart.CFrame:ToOrientation()
            local pitch3 = above and -1.5707963267948966 or 1.5707963267948966
            local minAng = mergeAng(above and aAMin or aBMin, pitch3, ry, rz)
            local maxAng = mergeAng(above and aAMax or aBMax, pitch3, ry, rz)
            local now = os.clock()

            if now < self._hitboxWindowUntil then
                return n, normAngles(rx, ry), function() item:HeavyAttackEncoded(minAng, maxAng, hs, aTail) end
            end
            local rbcfg = cfg.Data.Ragebot
            if not self._shootLock:ShouldFire(inLimit, dt * rbcfg.ShootFrames) then return rand(), nil, nil end
            if now < self._attackCooldown then return rand(), nil, nil end

            if item.Name == "Knife" then
                self:_RecordBackstab()
                return n, normAngles(rx, ry), function() item:HeavyAttackEncoded(minAng, maxAng, hs, aTail) end
            end
            return n, nil, function() item:AttackEncoded(minAng, maxAng, hs, aTail) end
        end
        idx._RecordBackstab = function(self)
            local now = os.clock()
            self._hitboxWindowUntil = now + 0.625
            self._attackCooldown    = now + 1.25
        end
        idx.ResetState = function(self)
            self._hitboxWindowUntil = -1
            self._attackCooldown    = -1
            self._shootLock:Reset()
            if self._gluedOurPart and self._partGlue then
                self._partGlue:Free(self._gluedOurPart)
                self._gluedOurPart = nil
            end
        end
        return idx
    end
    tbl17.jE = tbl17.jE or function()
        if not tbl17.cache.jE then tbl17.cache.jE = { c = fn35() } end
        return tbl17.cache.jE.c
    end
end

-- ─── jF  — Random circular position ────────────────────────────────────
do
    local function fn35()
        if tbl17.cache.jF and tbl17.cache.jF.c then return tbl17.cache.jF.c end
        local rng = Random.new()
        return function(origin, minR, maxR)
            local angle  = rng:NextNumber(0, math.pi * 2)
            local radius = rng:NextNumber(minR, maxR)
            local pos    = CFrame.new(origin + Vector3.new(math.cos(angle)*radius, 0, math.sin(angle)*radius))
            return pos * CFrame.fromOrientation(
                rng:NextNumber(0,math.pi*2), rng:NextNumber(0,math.pi*2), rng:NextNumber(0,math.pi*2))
        end
    end
    tbl17.jF = tbl17.jF or function()
        if not tbl17.cache.jF then tbl17.cache.jF = { c = fn35() } end
        return tbl17.cache.jF.c
    end
end

-- ─── jG  — Closest point + surface normal ────────────────────────────────
do
    local function fn35()
        if tbl17.cache.jG and tbl17.cache.jG.c then return tbl17.cache.jG.c end
        return function(part, queryPoint)
            local cp  = part:GetClosestPointOnSurface(queryPoint)
            local n   = queryPoint - cp
            if n.Magnitude < 1e-6 then return cp, nil end
            local d   = 0.05
            local n33 = part:GetClosestPointOnSurface(queryPoint + Vector3.xAxis*d) - cp
            local n34 = part:GetClosestPointOnSurface(queryPoint + Vector3.yAxis*d) - cp
            local n35 = part:GetClosestPointOnSurface(queryPoint + Vector3.zAxis*d) - cp
            local normal = n34:Cross(n33)
            if normal.Magnitude < 1e-6 then normal = n34:Cross(n35) end
            if normal.Magnitude < 1e-6 then normal = n33:Cross(n35) end
            if normal.Magnitude < 1e-6 then return cp, nil end
            return cp, normal.Unit
        end
    end
    tbl17.jG = tbl17.jG or function()
        if not tbl17.cache.jG then tbl17.cache.jG = { c = fn35() } end
        return tbl17.cache.jG.c
    end
end

-- ─── jH  — ProjectileBreaker teleport ───────────────────────────────────
do
    local function fn35()
        if tbl17.cache.jH and tbl17.cache.jH.c then return tbl17.cache.jH.c end
        local cfg    = tbl17.bG()
        local randPos = tbl17.jF()
        local closestPt = tbl17.jG()
        local CS     = cloneref(game:GetService("CollectionService"))
        local rng    = Random.new()
        local vBox   = Vector3.new(5, 5, 5)
        local op     = OverlapParams.new()
        op.FilterType = Enum.RaycastFilterType.Exclude
        op.FilterDescendantsInstances = {}
        op.BruteForceAllSlow = v86[34]

        local function osc(range, freq) return range.Min + (range.Max-range.Min) * (math.sin(os.clock()*freq*math.pi*2)+1) * 0.5 end
        local function depthUp()      local pb = cfg.Data.Ragebot.Evasion.ProjectileBreaker; return osc(pb.DepthUp, pb.DepthUpFrequency)       end
        local function depthFwd()     local pb = cfg.Data.Ragebot.Evasion.ProjectileBreaker; return osc(pb.DepthForward, pb.DepthForwardFrequency) end

        local function buildFrame(surf, up, fwd)
            return CFrame.fromMatrix(surf.SurfacePosition - surf.Up*0.01 - surf.Up*up + surf.Forward*fwd,
                surf.Right, surf.Up, -surf.Forward)
        end
        local function isBad(pos)
            for _, p in workspace:GetPartBoundsInBox(CFrame.new(pos), vBox, op) do
                if p.Name=="Barriers" or p:HasTag("OutOfBoundsPart") or p:HasTag("KillBrick") then return true end
            end
            return false
        end
        local function getSurface(part)
            if part.Transparency == 1 then return nil end
            local sz = part.Size; if sz.X*sz.Y*sz.Z < 64 then return nil end
            local mag = sz.Magnitude + 1000
            for _ = 1, v86[175] do
                local cp, norm = closestPt(part, part.Position + rng:NextUnitVector()*mag)
                if norm and norm.Y >= 0.98 then
                    local right = (part.Position - cp):Cross(norm).Unit
                    return { SurfacePosition=cp, Right=right, Up=norm, Forward=norm:Cross(right).Unit }
                end
            end
            local cp, norm = closestPt(part, part.Position + Vector3.yAxis*mag)
            if norm and norm.Y >= 0.98 then
                local right = (part.Position - cp):Cross(norm).Unit
                return { SurfacePosition=cp, Right=right, Up=norm, Forward=norm:Cross(right).Unit }
            end
            return nil
        end
        local function fallback(rootPart)
            local pb = cfg.Data.Ragebot.Evasion.ProjectileBreaker
            local br = pb.FallbackBaseRadius
            local maxR = br + br * pb.FallbackRadiusRandomFactor
            local origin = pb.FallbackAnchorFromCharacter and rootPart.Position or Vector3.new(0, rootPart.Position.Y, 0)
            local cf = randPos(origin, br, maxR)
            local pos = cf.Position
            local axis = rng:NextInteger(1, 3)
            if axis == 1 then return cf - pos + Vector3.new(1073741824, pos.Y, pos.Z)
            elseif axis == 2 then return cf - pos + Vector3.new(pos.X, 1073741824, pos.Z)
            else return cf - pos + Vector3.new(pos.X, pos.Y, 1073741824) end
        end

        local idx = {}
        idx.__index = idx
        idx.new = function(fighters, playerContext)
            local trove = Trove.new("ragebot.ProjectileBreakerTeleport")
            local self  = setmetatable({ _trove=trove, _fighters=fighters, _nextPosCD=-1, _poolEnvId=nil, _pool={}, _procSet={} }, idx)
            if playerContext and playerContext.ObserveContext then
                trove:Add(playerContext:ObserveContext("ragebot.ProjectileBreakerTeleport", function(ctx, innerTrove)
                    self:_BindEnv(ctx.FighterState.EnvironmentId)
                    if innerTrove then
                        innerTrove:Connect(ctx.FighterState.EnvironmentIdChanged, function(id) self:_BindEnv(id) end)
                    end
                end))
                trove:Connect(playerContext.ContextRemoved, function() self:_BindEnv(nil) end)
            end
            return self
        end
        idx.Destroy = function(self) self._trove:Destroy() end
        idx._BindEnv = function(self, envId)
            self._poolEnvId = envId; self._pool = {}; self._procSet = {}
        end
        idx.Compute = function(self, rootPart)
            if os.clock() < self._nextPosCD and self._lastSurf then
                return buildFrame(self._lastSurf, depthUp(), depthFwd())
            end
            if not self:_HasThreat() then self._lastSurf = nil; return fallback(rootPart) end
            local surf = self:_BreakLine()
            if surf then self._lastSurf = surf; return buildFrame(surf, depthUp(), depthFwd()) end
            return fallback(rootPart)
        end
        idx._HasThreat = function(self)
            for _, fs in self._fighters.EnemyByPlayer do
                local gun = fs.ItemObserver and fs.ItemObserver:EquippedItemAsGun and fs.ItemObserver:EquippedItemAsGun()
                if gun and not gun.IsRaycast and gun.Name == "Slingshot" then return true end
            end
            return false
        end
        idx._ScanBatch = function(self, envId)
            local pb   = cfg.Data.Ragebot.Evasion.ProjectileBreaker
            local avgU = (pb.DepthUp.Min + pb.DepthUp.Max) * 0.5
            local avgF = (pb.DepthForward.Min + pb.DepthForward.Max) * 0.5
            local count = 0
            for _, part in CS:GetTagged("RaycastWhitelist"..envId) do
                if part.Name=="Barriers" or part:HasTag("OutOfBoundsPart") or part:HasTag("KillBrick") then continue end
                if not self._procSet[part] then
                    self._procSet[part] = true; count += 1
                    local surf = getSurface(part)
                    if surf and not isBad(buildFrame(surf, avgU, avgF).Position) then
                        table.insert(self._pool, surf)
                    end
                end
                if count >= v86[83] or #self._pool >= 30 then return end
                for _, desc in part:GetDescendants() do
                    if desc:IsA("BasePart") and not self._procSet[desc] then
                        self._procSet[desc] = true; count += 1
                        local surf = getSurface(desc)
                        if surf and not isBad(buildFrame(surf, avgU, avgF).Position) then
                            table.insert(self._pool, surf)
                        end
                    end
                    if count >= 64 or #self._pool >= 30 then return end
                end
            end
        end
        idx._BreakLine = function(self)
            if not self._poolEnvId then return nil end
            if #self._pool < 30 then self:_ScanBatch(self._poolEnvId) end
            if #self._pool < 30 then return nil end
            local pb = cfg.Data.Ragebot.Evasion.ProjectileBreaker
            self._nextPosCD = os.clock() + pb.RepositionInterval
            return self._pool[rng:NextInteger(1, #self._pool)]
        end
        idx.ResetState = function(self)
            self._nextPosCD = -1; self._lastSurf = nil
        end
        return idx
    end
    tbl17.jH = tbl17.jH or function()
        if not tbl17.cache.jH then tbl17.cache.jH = { c = fn35() } end
        return tbl17.cache.jH.c
    end
end

-- ─── jI  — Random evasion ───────────────────────────────────────────────
do
    local function fn35()
        if tbl17.cache.jI and tbl17.cache.jI.c then return tbl17.cache.jI.c end
        local cfg    = tbl17.bG()
        local randPos = tbl17.jF()
        local rng    = Random.new()
        return { compute = function(rootPart)
            local rand2  = cfg.Data.Ragebot.Evasion.Random
            local base   = rand2.BaseRadius
            local maxR   = base + base * rand2.RadiusRandomFactor
            local pos    = rootPart.Position
            local origin = rand2.AnchorFromCharacter and pos or Vector3.new(0, pos.Y, 0)
            local cf     = randPos(origin, base, maxR)
            local p2     = cf.Position
            -- Always go skyward to avoid ground-level OOB kill zones
            return cf - p2 + Vector3.new(p2.X, 1073741824, p2.Z)
        end }
    end
    tbl17.jI = tbl17.jI or function()
        if not tbl17.cache.jI then tbl17.cache.jI = { c = fn35() } end
        return tbl17.cache.jI.c
    end
end

-- ─── jJ  — SpatialLimitGate ─────────────────────────────────────────────
do
    local function fn35()
        if tbl17.cache.jJ and tbl17.cache.jJ.c then return tbl17.cache.jJ.c end
        local cfg = tbl17.bG()

        local function isExtreme(pos)
            return math.abs(pos.X)>=4194304 or math.abs(pos.Y)>=4194304 or math.abs(pos.Z)>=4194304
        end

        local idx = {}
        idx.__index = idx
        idx.new = function(fighters)
            local self = setmetatable({ _trove=Trove.new("ragebot.SpatialLimitGate"), _measure={} }, idx)
            self:_Initialize(fighters)
            return self
        end
        idx._Initialize = function(self, fighters)
            if fighters and fighters.ObserveRemoteStates then
                self._trove:Add(fighters:ObserveRemoteStates(
                    function(fs) self._measure[fs] = { ExpectedDuration = 1 } end,
                    function(fs) self._measure[fs] = nil end
                ))
            end
        end
        idx.Tick = function(self, target)
            local now       = os.clock()
            local fs        = target.FighterState
            local measure   = self._measure[fs] or { ExpectedDuration = 1 }
            self._measure[fs] = measure
            local entryTime = measure.LimitEntryTime
            local hasAmmo   = fs.ItemObserver and fs.ItemObserver:GetEquippedAmmoState and
                              fs.ItemObserver:GetEquippedAmmoState() ~= false or true

            if not isExtreme(target.AliveState.RootPart.Position) then
                if entryTime ~= nil then
                    if hasAmmo then measure.ExpectedDuration = now - entryTime end
                    measure.LimitEntryTime = nil
                end
                return false
            end
            if entryTime == nil then measure.LimitEntryTime = now; entryTime = now end
            if hasAmmo and (measure.ExpectedDuration - cfg.Data.Ragebot.Stability <= now - entryTime) then
                return false
            end
            return v86[34]
        end
        idx.Destroy = function(self) self._trove:Destroy() end
        return idx
    end
    tbl17.jJ = tbl17.jJ or function()
        if not tbl17.cache.jJ then tbl17.cache.jJ = { c = fn35() } end
        return tbl17.cache.jJ.c
    end
end

-- ─── jK  — Translocate evasion ──────────────────────────────────────────
do
    local function fn35()
        if tbl17.cache.jK and tbl17.cache.jK.c then return tbl17.cache.jK.c end
        local cfg    = tbl17.bG()
        local randPos = tbl17.jF()
        local CS     = cloneref(game:GetService("CollectionService"))
        return { compute = function(rootPart, hasTargets)
            if not hasTargets then return randPos(rootPart.Position, 10000, 1e9) end
            local oobPart = nil
            for _, p in CS:GetTagged("OutOfBoundsPart") do
                if p:GetAttribute("KillDelay") == 0 then oobPart = p; break else oobPart = nil end
            end
            if oobPart == nil then return randPos(rootPart.Position, 10000, 1e9) end
            local offset = cfg.Data.Ragebot.Evasion.Translocate.Offset
            return oobPart.CFrame * CFrame.new(0, -oobPart.Size.Y/2 + offset, 0)
        end }
    end
    tbl17.jK = tbl17.jK or function()
        if not tbl17.cache.jK then tbl17.cache.jK = { c = fn35() } end
        return tbl17.cache.jK.c
    end
end

-- ─── jL  — Immune position rings ────────────────────────────────────────
do
    local function fn35()
        if tbl17.cache.jL and tbl17.cache.jL.c then return tbl17.cache.jL.c end
        local n   = 1121
        local rng = Random.new()
        local function randWord() return rng:NextInteger(0,65535)*65536 + rng:NextInteger(0,65535) end
        local w1,w2,w3,w4 = randWord(),randWord(),randWord(),randWord()
        local function hash(a,b)
            local h = (bit32.bxor(a,b,w1)+w2)%4294967296
            h = (bit32.bxor(h,bit32.lrotate(h,7))+w3)%4294967296
            h = (bit32.bxor(h,bit32.rrotate(h,11))+w4)%4294967296
            return bit32.bxor(h,bit32.lrotate(h,17))
        end
        local function makeRing(min, max)
            local salt = randWord()
            return { Min=min,Max=max,Cells=(max-min)/2048,
                     YMin=min+400+v86[83], YSpan=max-400-64-(min+400+v86[83])+1, Salt=salt }
        end
        local ring1 = makeRing(65536,   524288)
        local ring2 = makeRing(134217728,1073741824)

        local function cellPos(ring, cx, cz)
            local base = ring.Min+1024
            local function offset(axis, seed) return hash(bit32.bxor(cx,bit32.lshift(cz,16)), bit32.bxor(axis, ring.Salt)) % n - 560 end
            return Vector3.new(
                base + cx*2048 + offset(324508639, cx),
                ring.YMin + hash(bit32.bxor(cx,bit32.lshift(cz,16)), bit32.bxor(826366246, ring.Salt)) % ring.YSpan,
                base + cz*2048 + offset(610839776, cz)
            )
        end
        local function randomCell(ring)
            local cells = ring.Cells - 1
            local cp    = cellPos(ring, rng:NextInteger(0,cells), rng:NextInteger(0,cells))
            local r     = 200 * rng:NextNumber()^(1/3)
            local cosA  = rng:NextNumber(-1,1)
            local sinA  = math.sqrt(1-cosA*cosA)
            local phi   = rng:NextNumber(0, math.pi*2)
            return cp + Vector3.new(r*sinA*math.cos(phi), r*cosA, r*sinA*math.sin(phi))
        end
        local function inRing(ring, pos)
            local mn, mx = ring.Min, ring.Max
            local x,y,z = pos.X,pos.Y,pos.Z
            if x<=mn or x>=mx or y<=mn or y>=mx or z<=mn or z>=mx then return false end
            local cx = math.floor((x-mn)/2048); local cz = math.floor((z-mn)/2048)
            return (pos - cellPos(ring,cx,cz)).Magnitude < 400
        end
        local function wrapCF(pos)
            local tau = math.pi*2
            return CFrame.new(pos) * CFrame.fromOrientation(
                rng:NextNumber(-math.pi,math.pi), rng:NextNumber(-math.pi,math.pi), rng:NextNumber(-math.pi,math.pi))
        end
        return {
            SphereRadius    = 400,
            isInAnyRing     = function(pos) return inRing(ring1,pos) or inRing(ring2,pos) end,
            isInNormalRing  = function(pos) return inRing(ring1,pos) end,
            isInImmuneRing  = function(pos) if not flag3 then return end return inRing(ring2,pos) end,
            getNormal       = function() return wrapCF(randomCell(ring1)) end,
            getImmune       = function() return wrapCF(randomCell(ring2)) end,
        }
    end
    tbl17.jL = tbl17.jL or function()
        if not tbl17.cache.jL then tbl17.cache.jL = { c = fn35() } end
        return tbl17.cache.jL.c
    end
end

-- ─── jM  — Weapon strategy ──────────────────────────────────────────────
do
    local function fn35()
        if tbl17.cache.jM and tbl17.cache.jM.c then return tbl17.cache.jM.c end
        local cfg = tbl17.bG()
        local function slotOf(item)
            local idx = item.Index
            return idx==1 and "Primary" or idx==2 and "Secondary" or idx==3 and "Melee" or nil
        end
        local function enabled(slot) return cfg.Data.Ragebot.Weapons.Enabled[slot] end
        return { getAction = function(innerContext)
            local weapons = cfg.Data.Ragebot.Weapons
            local onEmpty = weapons.OnEmpty
            local rawPri  = weapons.Priority
            local pri
            if   type(rawPri) == "table"           then pri = rawPri
            elseif rawPri == "Secondary First"     then pri = {"Secondary","Primary","Melee"}
            elseif rawPri == "Melee First"         then pri = {"Melee","Primary","Secondary"}
            else                                        pri = {"Primary","Secondary","Melee"} end

            local bestItem, bestPri    = nil, math.huge
            local emptyItem, emptyPri  = nil, math.huge
            local hasAny = false

            for _, item in innerContext.ItemBehaviors:GetItems() do
                local slot = slotOf(item)
                if slot == nil or not enabled(slot) then continue end
                hasAny = true
                local rank = table.find(pri, slot) or math.huge
                if item.__type == "Gun" and item:GetAmmo() == 0 then
                    if item:GetAmmoReserve() > 0 then
                        if rank < emptyPri then
                            if onEmpty == "Reload" then bestItem, bestPri = item, rank
                            else emptyItem, emptyPri = item, rank end
                        end
                    end
                elseif bestItem == nil or rank < bestPri then
                    bestItem, bestPri = item, rank
                end
            end

            if not hasAny then return nil end

            if bestItem ~= nil then
                local isEmpty = bestItem.__type=="Gun" and bestItem:GetAmmo()==0
                if bestItem:IsEquipped() then
                    if isEmpty then return { Type="Reload", Item=bestItem } end
                    return { Type="Attack", Item=bestItem }
                end
                return { Type="Swap", Item=bestItem }
            end

            if onEmpty == "Swap" then return nil end
            if emptyItem ~= nil then
                if emptyItem:IsEquipped() then return { Type="Reload", Item=emptyItem } end
                return { Type="Swap", Item=emptyItem }
            end
            return nil
        end }
    end
    tbl17.jM = tbl17.jM or function()
        if not tbl17.cache.jM then tbl17.cache.jM = { c = fn35() } end
        return tbl17.cache.jM.c
    end
end

-- ─── jN  — Riot shield state ────────────────────────────────────────────
do
    local function fn35()
        if tbl17.cache.jN and tbl17.cache.jN.c then return tbl17.cache.jN.c end
        return function(itemBehaviors)
            local shield = itemBehaviors.FindMeleeByName and itemBehaviors:FindMeleeByName("Riot Shield")
            if shield == nil then return "None" end
            return shield:IsEquipped() and "Equipped" or "Unequipped"
        end
    end
    tbl17.jN = tbl17.jN or function()
        if not tbl17.cache.jN then tbl17.cache.jN = { c = fn35() } end
        return tbl17.cache.jN.c
    end
end

-- ═══════════════════════════════════════════════════════════════════════
--  jO — Main Ragebot controller
-- ═══════════════════════════════════════════════════════════════════════
do
    local function fn35()
        if tbl17.cache.jO and tbl17.cache.jO.c then return tbl17.cache.jO.c end
        local cfg         = tbl17.bG()
        local defHelper   = tbl17.jz()
        local HitscanStrat = tbl17.jD()
        local MeleeStrat   = tbl17.jE()
        local PBTeleport   = tbl17.jH()
        local RandomEv     = tbl17.jI()
        local SpatLimGate  = tbl17.jJ()
        local Translocate  = tbl17.jK()
        local ImmunPos     = tbl17.jL()
        local WeaponStrat  = tbl17.jM()
        local TargetSel    = tbl17.jB()
        local RiotState    = tbl17.jN()
        local TroveLib     = tbl17.k()

        local fallenDestH  = workspace.FallenPartsDestroyHeight

        local function immuneCF() return { CFrame = ImmunPos.getImmune(), ShouldSkipDefense = true } end

        local idx = {}
        idx.__index = idx

        idx.new = function(fighters, playerTags, playerContext, stateHook, partGlue)
            local trove = TroveLib.new("ragebot")
            local spatGate = trove:Add(SpatLimGate.new(fighters))
            local self = setmetatable({
                _trove              = trove,
                _enabled            = false,
                _lastTargetWorld    = nil,
                _lastDefViewAngles  = nil,
                _playerContext      = playerContext,
                _targetSelection    = TargetSel.new(fighters, playerTags),
                _spatialLimitGate   = spatGate,
                _hitscanStrategy    = HitscanStrat.new(partGlue),
                _meleeStrategy      = MeleeStrat.new(partGlue),
                _projectileBreakerTeleport = trove:Add(PBTeleport.new(fighters, playerContext)),
                _stateHook          = stateHook,
                _reloadGun          = nil,
                _reloadReadyAt      = nil,
                _reloadAcknowledgementDeadline = nil,
                _pendingDepletionAmmo = nil,
            }, idx)
            self:_Initialize()
            return self
        end

        idx._Initialize = function(self)
            if self._playerContext and self._playerContext.ObserveContext then
                self._trove:Add(self._playerContext:ObserveContext("ragebot", function(ctx)
                    if not flag2 then return end
                    self._innerContext = ctx
                    self:_ClearReloadTransport()
                end))
                self._trove:Connect(self._playerContext.ContextRemoved, function()
                    self:_Reset(); self._innerContext = nil
                end)
            end
            -- Keybind observer for Ragebot toggle
            self._trove:Add(RunService.Heartbeat:Connect(function()
                -- Delegate to ObserveEnabledKeybind if available via main tbl17
                local oek = tbl17.c4 and tbl17.c4()
                if oek and oek.ObserveEnabledKeybind then
                    -- already handled via main framework
                elseif type(cfg.Data.Ragebot.Enabled) == "boolean" then
                    self:SetEnabled(cfg.Data.Ragebot.Enabled)
                end
            end))
        end

        idx.SetEnabled = function(self, en)
            if self._enabled == en then return end
            self._enabled = en
            pcall(v112, workspace, "FallenPartsDestroyHeight", en and (0/0) or fallenDestH)
            pcall(v108, "DFIntS2PhysicsSenderRate",          en and "120" or "15")
            pcall(v108, "DFIntAssemblyHistoryBufferSize",     en and "2147483648" or "15")
            pcall(v108, "DFIntAssemblyHistorySkipSize",       en and v86[18] or "8")
            if not en then self:_ClearReloadTransport() end
        end

        idx.Update = function(self, dt)
            local ctx = self._innerContext
            if ctx == nil then self:_Reset(); return end
            local fs = ctx.FighterState
            if fs.EnvironmentId == nil or not self._enabled then self:_Reset(); return end
            local charState = fs.Character.State
            if not charState.Alive then self:_Reset(); return end

            local cc         = ctx.CharacterController
            local clientCF   = cc:GetClientCFrame()
            local mode       = cfg.Data.Ragebot.Evasion.Mode
            local action     = WeaponStrat.getAction(ctx)

            -- ── Translocate ──────────────────────────────────────────
            if mode == "Translocate" and self._reloadGun == nil and (action==nil or action.Type~="Reload") then
                self:_ApplyForcedCrouch(false)
                cc:SetServerCFrame(Translocate.compute(charState.RootPart, self._targetSelection:HasTargets()))
                if action ~= nil then
                    local tgt = self._targetSelection:GetTarget()
                    if tgt then
                        local plan = self:_Plan(dt, action, tgt, charState.RootPart, clientCF, mode)
                        if plan.WeaponAction then plan.WeaponAction() end
                    end
                end
                return
            end

            -- ── VoidSpam ─────────────────────────────────────────────
            if mode == "VoidSpam" then
                local now = os.clock()
                local cfg2 = cfg.Data.Ragebot.VoidSpam or {}
                local hideTime   = type(cfg2.HideTime)   == "number" and cfg2.HideTime   or 0.25
                local attackTime = type(cfg2.AttackTime) == "number" and cfg2.AttackTime or 0.1
                if not self._vsPhaseEnd then self._vsPhaseEnd = now+hideTime; self._vsHiding = true end
                if now >= self._vsPhaseEnd then
                    self._vsHiding  = not self._vsHiding
                    self._vsPhaseEnd = now + (self._vsHiding and hideTime or attackTime)
                end
                if self._vsHiding then
                    local hideCF
                    for _, p in CollectionService:GetTagged("OutOfBoundsPart") do
                        local kd = p:GetAttribute("KillDelay")
                        if kd ~= nil and kd ~= 0 then
                            hideCF = CFrame.new(p.Position)
                            break
                        end
                    end
                    cc:SetServerCFrame(hideCF or CFrame.new(0,-5000,0))
                    return
                end
                -- attack phase falls through
            end

            -- ── HarionVoid ───────────────────────────────────────────
            if mode == "HarionVoid" then
                local now  = os.clock()
                local hcfg = cfg.Data.Ragebot.HarionVoid or {}
                local hideT  = type(hcfg.HideTime)  == "number" and hcfg.HideTime  or 0.25
                local shootT = type(hcfg.ShootTime) == "number" and hcfg.ShootTime or 0.03
                if not self._hvPhaseEnd then self._hvPhaseEnd = now+hideT; self._hvHiding = true end
                if now >= self._hvPhaseEnd then
                    self._hvHiding  = not self._hvHiding
                    self._hvPhaseEnd = now + (self._hvHiding and hideT or shootT)
                end
                if self._hvHiding then
                    cc:SetServerCFrame(CFrame.new(0,1073741824,0)*CFrame.Angles(math.pi,math.pi,math.pi))
                    self._hvAttackCF = nil
                    return
                end
                local hvTgt = self._targetSelection:GetTarget()
                if hvTgt then
                    local hvChar = hvTgt.AliveState.Character
                    local hvRoot = hvChar and hvChar:FindFirstChild("HumanoidRootPart")
                    local hvHead = hvChar and (hvChar:FindFirstChild("Head") or hvRoot)
                    if hvRoot and hvHead then
                        local shootPos = hvRoot.Position - hvRoot.CFrame.LookVector*2.5 + Vector3.new(0,1.5,0)
                        self._hvAttackCF = CFrame.new(shootPos, hvHead.Position)
                    else self._hvAttackCF = nil end
                else self._hvAttackCF = nil end
            end

            -- ── OrbitDesync ──────────────────────────────────────────
            if mode == "OrbitDesync" then
                local now  = os.clock()
                local ocfg = cfg.Data.Ragebot.OrbitDesync or {}
                local radius = math.clamp(type(ocfg.Radius)==      "number" and ocfg.Radius      or 3,   1.25, 5)
                local height = math.clamp(type(ocfg.Height)==      "number" and ocfg.Height      or 1.5, -2,   6)
                local speed  = type(ocfg.StrafeSpeed)=="number"  and ocfg.StrafeSpeed or 2
                self._odAngle = ((self._odAngle or 0) + (now-(self._odLastT or now)) * math.max(1,speed*1.5)) % (math.pi*2)
                self._odLastT = now
                local odTgt = self._targetSelection:GetTarget()
                if odTgt then
                    local odChar = odTgt.AliveState.Character
                    local odRoot = odChar and odChar:FindFirstChild("HumanoidRootPart")
                    local odHead = odChar and (odChar:FindFirstChild("Head") or odRoot)
                    if odRoot and odHead then
                        local ang = self._odAngle
                        local orbitPos = odHead.Position + Vector3.new(math.cos(ang)*radius, height, math.sin(ang)*radius)
                        local orbitCF  = CFrame.new(orbitPos, odHead.Position)
                        self._odAttackCF  = orbitCF
                        self._odCurrentCF = orbitCF
                        if not self._odRenderBound then
                            self._odRenderBound = true
                            local rbRoot = charState.RootPart
                            RunService:BindToRenderStep("GravOrbit", Enum.RenderPriority.First.Value, function()
                                if cfg.Data.Ragebot.Evasion.Mode ~= "OrbitDesync" then
                                    RunService:UnbindFromRenderStep("GravOrbit")
                                    self._odRenderBound = nil
                                    return
                                end
                                local cf2 = self._odCurrentCF
                                if rbRoot and rbRoot.Parent and cf2 then rbRoot.CFrame = cf2 end
                            end)
                        end
                    else self._odAttackCF = nil end
                else
                    if self._odRenderBound then
                        RunService:UnbindFromRenderStep("GravOrbit")
                        self._odRenderBound = nil
                    end
                    self._odAttackCF = nil; self._odCurrentCF = nil
                    cc:SetServerCFrame(CFrame.new(0,1073741824,0))
                    return
                end
            end

            -- ── Normal update ─────────────────────────────────────────
            local target = self._targetSelection:GetTarget()
            self._lastTargetWorld = target and target.AliveState.RootPart.Position or nil

            local plan = self:_Plan(dt, action, target, charState.RootPart, clientCF, mode)
            self:_ApplyPlan(plan, target, ctx)

            if self._reloadGun ~= nil and self._reloadReadyAt == nil and
               self._pendingDepletionAmmo == nil and not self._reloadGun:IsReloading() then
                local delay = tbl17.cG and tbl17.cG().getEstimatedReplicationDelay and
                              tbl17.cG():getEstimatedReplicationDelay() or 0.1
                self._reloadReadyAt = os.clock() + delay
            end

            self:_ApplyForcedCrouch(plan.ShouldForceCrouch == true)
            local equippedGun = ctx.ItemBehaviors:EquippedItemAsGun and ctx.ItemBehaviors:EquippedItemAsGun()
            local ammo = equippedGun and equippedGun:GetAmmo() or 0
            local shotsBefore = equippedGun and equippedGun.ShotRequestCount or 0

            if plan.WeaponAction then
                plan.WeaponAction()
                local shotsAfter = equippedGun and equippedGun.ShotRequestCount or 0
                if equippedGun and (shotsAfter - shotsBefore) > 0 and equippedGun:GetExpectedAmmoAfterPendingShots() <= 0 then
                    local delay2 = tbl17.cG and tbl17.cG().getEstimatedReplicationDelay and
                                   tbl17.cG():getEstimatedReplicationDelay() or 0.1
                    local remDelay = tbl17.cG and tbl17.cG().getEstimatedRemoteDelay and
                                     tbl17.cG():getEstimatedRemoteDelay() or 0.05
                    local now3 = os.clock()
                    self._reloadGun = equippedGun
                    self._reloadReadyAt = now3 + delay2
                    self._pendingDepletionAmmo = ammo
                    self._reloadAcknowledgementDeadline = now3 + remDelay + delay2
                end
            end
        end

        idx._Plan = function(self, dt, action, target, ourPart, clientCF, mode)
            local inLimit = ourPart ~= nil and not self._spatialLimitGate:Tick(target or {AliveState={RootPart=ourPart},FighterState={}})
            local reloadPlan = self:_PlanReloadTransport(action)
            if reloadPlan then return reloadPlan end
            if action == nil then return self:_EvadePlan(ourPart, mode) end
            if action.Type == "Swap" then
                local ep = self:_EvadePlan(ourPart, mode)
                ep.WeaponAction = function() action.Item:Equip() end
                return ep
            end
            if action.Type == "Reload" then return immuneCF() end
            if target == nil then return self:_EvadePlan(ourPart, mode) end
            local item = action.Item
            if item.__type == "Gun" then
                if item:IsReloading() then return immuneCF() end
                local cf2, wa = self._hitscanStrategy:Plan(dt, target, item, ourPart, inLimit)
                return { CFrame=cf2, WeaponAction=wa, ShouldForceCrouch=true, IsAimPose=(wa~=nil) }
            end
            if item.__type == "Melee" then
                local cf2, va, wa = self._meleeStrategy:Plan(dt, target, item, ourPart, inLimit)
                return { CFrame=cf2, ViewAngles=va, WeaponAction=wa, ShouldSkipDefense=v86[34], ShouldForceCrouch=true }
            end
            return {}
        end

        idx._ClearReloadTransport = function(self)
            self._reloadGun = nil; self._reloadReadyAt = nil
            self._reloadAcknowledgementDeadline = nil; self._pendingDepletionAmmo = nil
        end

        idx._PlanReloadTransport = function(self, action)
            local gun = self._reloadGun
            local now = os.clock()
            if gun == nil then
                if action == nil or action.Type ~= "Reload" then return nil end
                self._reloadGun = action.Item; return immuneCF()
            end
            local ctx = self._innerContext
            local equippedGun = ctx and ctx.ItemBehaviors:EquippedItemAsGun and ctx.ItemBehaviors:EquippedItemAsGun()
            if equippedGun ~= gun or (action ~= nil and (action.Type=="Swap" or action.Type=="Attack") and action.Item~=gun) then
                self:_ClearReloadTransport(); return nil
            end
            if gun:IsReloading() then
                self._reloadReadyAt = nil; self._pendingDepletionAmmo = nil
                self._reloadAcknowledgementDeadline = nil
                return immuneCF()
            end
            local ammo = gun:GetAmmo()
            if self._pendingDepletionAmmo ~= nil then
                if not (ammo <= 0 and gun:GetAmmoReserve() > 0) then
                    local deadline = self._reloadAcknowledgementDeadline
                    local ok = deadline == nil or now >= deadline or gun:GetExpectedAmmoAfterPendingShots() > 0
                    if ok then self:_ClearReloadTransport(); return nil end
                    return immuneCF()
                end
                self._pendingDepletionAmmo = nil; self._reloadAcknowledgementDeadline = nil
            end
            if ammo > 0 or gun:GetAmmoReserve() <= 0 then self:_ClearReloadTransport(); return nil end
            if not self._reloadReadyAt then
                local delay = tbl17.cG and tbl17.cG().getEstimatedReplicationDelay and
                              tbl17.cG():getEstimatedReplicationDelay() or 0.1
                self._reloadReadyAt = now + delay
            end
            local plan = immuneCF()
            local deadline2 = self._reloadAcknowledgementDeadline
            if now >= self._reloadReadyAt and (deadline2 == nil or now >= deadline2) then
                local g2 = gun
                plan.WeaponAction = function()
                    if g2:Reload() then
                        local d1 = tbl17.cG and tbl17.cG().getEstimatedRemoteDelay and tbl17.cG():getEstimatedRemoteDelay() or 0.05
                        local d2 = tbl17.cG and tbl17.cG().getEstimatedReplicationDelay and tbl17.cG():getEstimatedReplicationDelay() or 0.1
                        self._reloadAcknowledgementDeadline = os.clock() + d1 + d2
                    end
                end
            end
            return plan
        end

        idx._EvadePlan = function(self, ourPart, mode)
            if mode == "Off"              then return {} end
            if mode == "ProjectileBreaker" then return { CFrame=self._projectileBreakerTeleport:Compute(ourPart), ShouldSkipDefense=v86[34] } end
            if mode == "TeleportV2"       then return {} end
            if mode == "VoidSpam"         then return {} end
            if mode == "HarionVoid"       then return self._hvAttackCF and { CFrame=self._hvAttackCF, ShouldSkipDefense=v86[34] } or {} end
            if mode == "OrbitDesync"      then return self._odAttackCF and { CFrame=self._odAttackCF, ShouldSkipDefense=v86[34] } or {} end
            -- Random / default
            if ourPart then return { CFrame=RandomEv.compute(ourPart) } end
            return {}
        end

        idx._ApplyPlan = function(self, plan, target, ctx)
            local cc = ctx.CharacterController
            if plan.CFrame == nil or target == nil or plan.ShouldSkipDefense then
                cc:SetServerCFrame(plan.CFrame)
                cc:SendViewAngles and cc:SendViewAngles(20, plan.ViewAngles)
                return
            end
            local aliveState = target.AliveState
            local shieldSt = RiotState(ctx.ItemBehaviors)
            local defCF = defHelper.getDefensiveCFrame(plan.CFrame, shieldSt, target.FighterState, aliveState.RootPart)
            cc:SetServerCFrame(defCF)
            if plan.IsAimPose or plan.ShouldDefendInPlace then
                self._lastDefViewAngles = defHelper.getDefensiveViewAngles(shieldSt, target.FighterState)
            end
            cc:SendViewAngles and cc:SendViewAngles(v86[9], plan.ViewAngles or self._lastDefViewAngles)
        end

        idx.GetLastTargetWorld = function(self) return self._lastTargetWorld end

        idx._ApplyForcedCrouch = function(self, force)
            if self._stateHook then
                if force then self._stateHook:SetForced("IsCrouching", true)
                else           self._stateHook:ClearForced("IsCrouching") end
            end
        end

        idx._Reset = function(self)
            self:_ClearReloadTransport()
            self._lastTargetWorld   = nil
            self._lastDefViewAngles = nil
            self:_ApplyForcedCrouch(false)
            self._meleeStrategy:ResetState()
            self._projectileBreakerTeleport:ResetState()
            self._vsPhaseEnd = nil; self._vsHiding = nil
            local ctx = self._innerContext
            if ctx == nil then return end
            ctx.CharacterController:SetServerCFrame(nil)
            ctx.CharacterController:SendViewAngles and ctx.CharacterController:SendViewAngles(20, nil)
        end

        idx.Destroy = function(self) self._trove:Destroy() end
        return idx
    end
    tbl17.jO = tbl17.jO or function()
        if not tbl17.cache.jO then tbl17.cache.jO = { c = fn35() } end
        return tbl17.cache.jO.c
    end
end

-- ═══════════════════════════════════════════════════════════════════════
--  UI  —  Ragebot Tab
--  Requires: Lib (linoria-compatible) and W (window/tab helper).
--  If the main Graviton UI is already loaded, this borrows its Lib/W.
--  Otherwise it loads Linoria from scratch.
-- ═══════════════════════════════════════════════════════════════════════
local Lib, W, combatTab
do
    -- Try to reuse already-loaded instances
    local existing_lib = rawget(getgenv(), "_kicia_Lib")
    local existing_W   = rawget(getgenv(), "_kicia_W")
    if existing_lib and existing_W then
        Lib = existing_lib
        W   = existing_W
    else
        -- Load Linoria UI library (adjust URL to your loader if needed)
        local ok, result = pcall(function()
            return loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua"))()
        end)
        if not ok then
            warn("[Ragebot] UI library failed to load: " .. tostring(result))
            warn("[Ragebot] Set getgenv()._kicia_Lib and _kicia_W before loading this script.")
        else
            Lib = result
            W   = Lib:CreateWindow({
                Title   = "Ragebot",
                Center  = true,
                AutoShow = true,
            })
        end
    end
    if W and type(W.Tab) == "function" then
        combatTab = W:Tab("Combat")
        if type(combatTab) == "function" then
            -- already a factory, use as-is
        else
            -- wrap: treat as a groupbox builder
            combatTab = function(name) return Lib:CreateGroupbox(W, name, 1), Lib:CreateGroupbox(W, name.."R", 2) end
        end
    end
end

-- ── Config get / set helpers used by UI helpers ──────────────────────────
local function get(path)
    local t = gc.Data
    for _, k in ipairs(path) do
        if type(t) ~= "table" then return nil end
        t = t[k]
    end
    return t
end
local function set(path, v)
    local t = gc.Data
    for i = 1, #path - 1 do
        if type(t[path[i]]) ~= "table" then t[path[i]] = {} end
        t = t[path[i]]
    end
    t[path[#path]] = v
end

-- ── UI element helpers ────────────────────────────────────────────────────
local flagsReg = {}
local function _regFlag(flag, handle, kind) flagsReg[flag] = { handle=handle, kind=kind } end

local function toggle(G, label, path, def, ord)
    if not Lib then return end
    local flag = table.concat(path, ".")
    local handle = Lib:CreateToggle(G, label, { Default=def~=nil and def or false, Callback=function(v) set(path,v) end, Order=ord })
    if handle then _regFlag(flag, handle, "toggle") end
end

local function slider(G, label, path, mn, mx, def, dec, ord)
    if not Lib then return end
    local flag = table.concat(path, ".")
    local handle = Lib:CreateSlider(G, label, { Min=mn, Max=mx, Default=def, Decimals=dec or 0, Callback=function(v) set(path,v) end, Order=ord })
    if handle then _regFlag(flag, handle, "slider") end
end

local function dropdown(G, label, path, values, def, ord)
    if not Lib then return end
    local flag = table.concat(path, ".")
    local handle = Lib:CreateDropdown(G, label, { Values=values, Default=def~=nil and def or values[1], Callback=function(v) set(path,v) end, Order=ord })
    if handle then _regFlag(flag, handle, "dropdown") end
end

local function colorpick(G, label, path, def, ord)
    if not Lib then return end
    local flag = table.concat(path, ".")
    local handle = Lib:CreateColorPicker(G, label, { Default=def or Color3.new(1,1,1), Callback=function(c) set(path,c) end, Order=ord })
    if handle then _regFlag(flag, handle, "color") end
end

local function keybind(G, label, path, def, ord)
    if not Lib then return end
    local flag = table.concat(path, ".")
    local handle = Lib:CreateKeybind(G, label, { Default=def or Enum.KeyCode.Unknown, Callback=function(k) set(path, k and k.Name or nil) end, Order=ord })
    if handle then _regFlag(flag, handle, "keybind") end
end

local function sec(name, fn)
    local ok, err = pcall(fn)
    if not ok then warn("[Ragebot UI] section '"..name.."' error: "..tostring(err)) end
end

-- ═══════════════════════════════════════════════════════════════════════
--  RAGEBOT UI SECTION
-- ═══════════════════════════════════════════════════════════════════════
sec("Ragebot", function()
    if not Lib or not combatTab then
        warn("[Ragebot] UI library not loaded — skipping UI build.")
        return
    end

    local L, R = combatTab("Ragebot")

    -- ── Activation ───────────────────────────────────────────────────
    local GA = Lib:CreateGroupbox(L, "Activation", 1)
    toggle   (GA, "Enable Ragebot",         {"Ragebot","Enabled"},              false)
    keybind  (GA, "Ragebot Hotkey",         {"Ragebot","Keybind","Bind"},        Enum.KeyCode.Unknown)
    toggle   (GA, "Prioritize Hackers",     {"Ragebot","PrioritizeHackers"},    false)
    toggle   (GA, "Utilize Health Lead",    {"Ragebot","UtilizeHealthLead"},    false)
    slider   (GA, "Stability",              {"Ragebot","Stability"},     0,   1.5, 0,   3)
    slider   (GA, "Shoot Frames",           {"Ragebot","ShootFrames"},   1,   5,   2,   0)

    -- ── Weapon Strategy ───────────────────────────────────────────────
    local GW = Lib:CreateGroupbox(L, "Weapon Strategy", 2)
    toggle   (GW, "Primary Enabled",    {"Ragebot","Weapons","Enabled","Primary"},   true)
    toggle   (GW, "Secondary Enabled",  {"Ragebot","Weapons","Enabled","Secondary"}, true)
    toggle   (GW, "Melee Enabled",      {"Ragebot","Weapons","Enabled","Melee"},     false)
    dropdown (GW, "Priority Order",     {"Ragebot","Weapons","Priority"},
        {"Primary First","Secondary First","Melee First"}, "Primary First")
    dropdown (GW, "On Empty",           {"Ragebot","Weapons","OnEmpty"},
        {"Reload","Swap","SwapOrReload"}, "SwapOrReload")

    -- ── Evasion ───────────────────────────────────────────────────────
    local GE = Lib:CreateGroupbox(R, "Evasion", 1)
    dropdown (GE, "Evasion Mode", {"Ragebot","Evasion","Mode"},
        {"Off","Random","Translocate","ProjectileBreaker","VoidSpam","TeleportV2","HarionVoid","OrbitDesync"}, "Off")
    slider   (GE, "Random Base Radius",       {"Ragebot","Evasion","Random","BaseRadius"},        5, 100000000, 50,  0)
    slider   (GE, "Random Factor",            {"Ragebot","Evasion","Random","RadiusRandomFactor"}, 0, 1,         0.5, 1)
    toggle   (GE, "Random Char Origin",       {"Ragebot","Evasion","Random","AnchorFromCharacter"}, false)
    slider   (GE, "Translocate Offset",       {"Ragebot","Evasion","Translocate","Offset"},       -5, 5, 0, 1)

    -- ── Target Filter ─────────────────────────────────────────────────
    local GTF = Lib:CreateGroupbox(R, "Target Filter", 2)
    toggle   (GTF, "Enemies Only",       {"Ragebot","EnemiesOnly"},       true)
    toggle   (GTF, "Ignore Knocked",     {"Ragebot","IgnoreKnocked"},     false)
    toggle   (GTF, "Ignore Force Field", {"Ragebot","IgnoreForceField"},  true)
    dropdown (GTF, "Target Priority", {"Ragebot","TargetPriority"},
        {"Closest","LowestHP","HighestHP","ClosestToCenter"}, "Closest")
    dropdown (GTF, "Aim Part", {"Ragebot","AimPart"},
        {"Head","UpperTorso","LowerTorso","ClosestPart"}, "Head")

    -- ── Projectile Breaker ────────────────────────────────────────────
    local GP = Lib:CreateGroupbox(L, "Projectile Breaker", 3)
    slider   (GP, "Fwd Depth Min",        {"Ragebot","Evasion","ProjectileBreaker","DepthForward","Min"},         0,    10,  0,   1)
    slider   (GP, "Fwd Depth Max",        {"Ragebot","Evasion","ProjectileBreaker","DepthForward","Max"},         0,    10,  4,   1)
    slider   (GP, "Fwd Frequency",        {"Ragebot","Evasion","ProjectileBreaker","DepthForwardFrequency"},      0,    20,  5,   1)
    slider   (GP, "Up Depth Min",         {"Ragebot","Evasion","ProjectileBreaker","DepthUp","Min"},              0,    10,  0,   1)
    slider   (GP, "Up Depth Max",         {"Ragebot","Evasion","ProjectileBreaker","DepthUp","Max"},              0,    10,  5.5, 1)
    slider   (GP, "Up Frequency",         {"Ragebot","Evasion","ProjectileBreaker","DepthUpFrequency"},           0,    20,  5,   1)
    slider   (GP, "Reposition Interval",  {"Ragebot","Evasion","ProjectileBreaker","RepositionInterval"},         0.05, 2,   0.3, 2)
    toggle   (GP, "Fallback Char Origin", {"Ragebot","Evasion","ProjectileBreaker","FallbackAnchorFromCharacter"},false)
    slider   (GP, "Fallback Radius",      {"Ragebot","Evasion","ProjectileBreaker","FallbackBaseRadius"},         5, 100000000, 100, 0)
    slider   (GP, "Fallback Rnd Factor",  {"Ragebot","Evasion","ProjectileBreaker","FallbackRadiusRandomFactor"}, 0, 1, 0.5, 1)

    -- ── Void Spam ─────────────────────────────────────────────────────
    local GVS = Lib:CreateGroupbox(L, "Void Spam", 4)
    slider   (GVS, "Hide Time (s)",   {"Ragebot","VoidSpam","HideTime"},   0.05, 2, 0.25, 2)
    slider   (GVS, "Attack Time (s)", {"Ragebot","VoidSpam","AttackTime"}, 0.05, 2, 0.1,  2)

    -- ── Teleport V2 ───────────────────────────────────────────────────
    local GTV2 = Lib:CreateGroupbox(L, "Teleport V2", 4)
    slider   (GTV2, "Y Offset", {"Ragebot","TeleportV2","Offset"}, -10, 10, 0, 1)

    -- ── Harion Void ───────────────────────────────────────────────────
    local GHV = Lib:CreateGroupbox(L, "Harion Void", 5)
    slider   (GHV, "Hide Time (s)",  {"Ragebot","HarionVoid","HideTime"},  0.05, 2, 0.25, 2)
    slider   (GHV, "Shoot Time (s)", {"Ragebot","HarionVoid","ShootTime"}, 0.01, 1, 0.03, 2)

    -- ── Orbit Desync ──────────────────────────────────────────────────
    local GOD = Lib:CreateGroupbox(L, "Orbit Desync", 6)
    slider   (GOD, "Orbit Radius",    {"Ragebot","OrbitDesync","Radius"},      1.25, 5,  3,   2)
    slider   (GOD, "Orbit Height",    {"Ragebot","OrbitDesync","Height"},      -2,   6,  1.5, 1)
    slider   (GOD, "Strafe Speed",    {"Ragebot","OrbitDesync","StrafeSpeed"}, 0.5,  10, 2,   1)

    -- ── Fake Position ─────────────────────────────────────────────────
    local GFP = Lib:CreateGroupbox(L, "Fake Position", 5)
    Lib:CreateToggle(GFP, "Enable Fake Pos", {
        Default  = false,
        Tooltip  = "Sends your character underground, desync-ing server from client position.",
        Callback = function(v) local fn = getgenv().SetFakePosition; if fn then fn(v) end end,
    })
    Lib:CreateSlider(GFP, "Underground Depth", {
        Min = 1, Max = 30, Default = 5.8, Decimals = 1,
        Callback = function(v) local fn = getgenv().SetFakePositionDepth; if fn then fn(v) end end,
    })
    Lib:CreateToggle(GFP, "Walk Mode", {
        Default  = true,
        Tooltip  = "Virtual position follows WASD movement on the surface.",
        Callback = function(v) local fn = getgenv().SetFakePosWalkMode; if fn then fn(v) end end,
    })
    Lib:CreateToggle(GFP, "Surface Camera", {
        Default  = true,
        Tooltip  = "Elevates camera so it stays at surface level while underground.",
        Callback = function(v) local fn = getgenv().SetFakePosSurfaceCamera; if fn then fn(v) end end,
    })
    Lib:CreateToggle(GFP, "Auto Noclip", {
        Default  = true,
        Tooltip  = "Disables collision on character parts while active.",
        Callback = function(v) local fn = getgenv().SetFakePosAutoNoclip; if fn then fn(v) end end,
    })
    Lib:CreateToggle(GFP, "Zero Velocity", {
        Default  = true,
        Tooltip  = "Zeroes assembly velocity each frame to prevent drift.",
        Callback = function(v) local fn = getgenv().SetFakePosZeroVelocity; if fn then fn(v) end end,
    })
    Lib:CreateToggle(GFP, "Hide Meshes", {
        Default  = true,
        Tooltip  = "Makes character invisible while underground.",
        Callback = function(v) local fn = getgenv().SetFakePosHideMeshes; if fn then fn(v) end end,
    })
    Lib:CreateToggle(GFP, "Animation Desync", {
        Default  = true,
        Tooltip  = "Plays a still animation to hide movement on the server.",
        Callback = function(v) local fn = getgenv().SetFakePosAnimDesync; if fn then fn(v) end end,
    })

    -- ── Visualizer ────────────────────────────────────────────────────
    local GFV = Lib:CreateGroupbox(R, "Visualizer", 3)
    Lib:CreateToggle(GFV, "Ghost Box", {
        Default  = true,
        Tooltip  = "Shows a box at your virtual (surface) position.",
        Callback = function(v) local fn = getgenv().SetFakePosVisualizerOn; if fn then fn(v) end end,
    })
    Lib:CreateColorPicker(GFV, "Ghost Color", {
        Default  = Color3.fromRGB(0, 162, 255),
        Callback = function(c) local fn = getgenv().SetFakePosVisualizerColor; if fn then fn(c) end end,
    })

    -- ── Panic Jitter ─────────────────────────────────────────────────
    local GFN = Lib:CreateGroupbox(R, "Panic Jitter", 4)
    Lib:CreateToggle(GFN, "Enable Panic Jitter", {
        Default  = false,
        Tooltip  = "Randomly offsets underground X position each frame.",
        Callback = function(v) local fn = getgenv().SetFakePosPanic; if fn then fn(v) end end,
    })
    Lib:CreateSlider(GFN, "Jitter Min X", {
        Min = -20, Max = 0, Default = -5, Decimals = 0,
        Callback = function(v) local fn = getgenv().SetFakePosPanicMinX; if fn then fn(v) end end,
    })
    Lib:CreateSlider(GFN, "Jitter Max X", {
        Min = 0, Max = 20, Default = 5, Decimals = 0,
        Callback = function(v) local fn = getgenv().SetFakePosPanicMaxX; if fn then fn(v) end end,
    })
    Lib:CreateToggle(GFN, "Z-Axis Jitter", {
        Default  = false,
        Tooltip  = "Also jitters on the Z axis.",
        Callback = function(v) local fn = getgenv().SetFakePosPanicZ; if fn then fn(v) end end,
    })

    -- ── SA Autofire (ragebot section) ─────────────────────────────────
    -- Silent-aim style autofire: fires UseItem directly at the closest enemy.
    do
        local _rbSAOn      = false
        local _rbSAHb      = nil
        local _rbFcCache   = nil
        local _rbHsV       = 65
        local _rbBodyV     = 35
        local _rbTeamCheck = true
        local _rbLastFire  = 0
        local _rbStartEnum = nil
        local _rbLP        = Players.LocalPlayer
        local _rbRS        = RunService
        local _rbEnums
        pcall(function()
            _rbEnums = require(ReplicatedStorage.Modules.EnumLibrary)
        end)

        local function _rbEncCF(cf)
            local rx, ry, rz = cf:ToOrientation()
            return {
                [utf8.char(0)]=cf.X, [utf8.char(1)]=cf.Y, [utf8.char(2)]=cf.Z,
                [utf8.char(3)]=rx,   [utf8.char(4)]=ry,   [utf8.char(5)]=rz,
            }
        end

        local function _rbGetRemote()
            local r = ReplicatedStorage:FindFirstChild("Remotes")
            local rep = r and r:FindFirstChild("Replication")
            local f   = rep and rep:FindFirstChild("Fighter")
            local u   = f and f:FindFirstChild("UseItem")
            if u and u:IsA("RemoteEvent") then return u end
            return ReplicatedStorage:FindFirstChild("UseItem", true)
        end

        local function _rbGetEnum()
            if _rbStartEnum then return _rbStartEnum end
            if _rbEnums then
                local ok, v = pcall(_rbEnums.ToEnum, _rbEnums, "StartShooting")
                if ok and v then _rbStartEnum = v; return v end
            end
            local ok2, elib = pcall(require, ReplicatedStorage.Modules.EnumLibrary)
            if ok2 and elib then
                local ok3, v3 = pcall(elib.ToEnum, elib, "StartShooting")
                if ok3 and v3 then _rbStartEnum = v3; return v3 end
            end
            return nil
        end

        local function _rbClosestEnemy()
            local myChar = _rbLP.Character
            local myHRP  = myChar and myChar:FindFirstChild("HumanoidRootPart")
            if not myHRP then return nil end
            local best, bestD = nil, math.huge
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr == _rbLP or not plr.Character then continue end
                if _rbTeamCheck and _rbLP.Team ~= nil and plr.Team == _rbLP.Team then continue end
                local char = plr.Character
                local hrp  = char:FindFirstChild("HumanoidRootPart")
                local hum  = char:FindFirstChildOfClass("Humanoid")
                if not hrp or not hum or hum.Health <= 0 then continue end
                local d = (hrp.Position - myHRP.Position).Magnitude
                if d < bestD then best, bestD = char, d end
            end
            return best
        end

        local function _rbToggle(v)
            _rbSAOn = v
            if v then
                if _rbSAHb then return end
                task.spawn(function()
                    local rem
                    for _ = 1, 300 do
                        rem = _rbGetRemote()
                        if rem then break end
                        task.wait(0.1)
                    end
                    if not rem then return end
                    _rbSAHb = _rbRS.Heartbeat:Connect(function()
                        if not _rbSAOn then return end
                        local now = tick()
                        if now - _rbLastFire < 0.02 then return end
                        if not _rbFcCache then
                            local ok, fc = pcall(function()
                                return require(_rbLP.PlayerScripts.Controllers.FighterController)
                            end)
                            if ok and fc then _rbFcCache = fc end
                        end
                        if not _rbFcCache then return end
                        local localFighter = _rbFcCache.LocalFighter
                        if not localFighter then return end
                        local item = localFighter.EquippedItem
                        if not item or not item.Get then return end
                        local startEnum = _rbGetEnum()
                        if not startEnum then return end
                        local target = _rbClosestEnemy()
                        if not target then return end
                        local roll = math.random(0, 100)
                        local hitbox
                        if roll <= _rbHsV then
                            hitbox = target:FindFirstChild("HitboxHead")
                                  or target:FindFirstChild("HitboxHeadSmall")
                                  or target:FindFirstChild("Head")
                        else
                            hitbox = target:FindFirstChild("HitboxBody")
                                  or target:FindFirstChild("HumanoidRootPart")
                        end
                        hitbox = hitbox or target:FindFirstChild("Head") or target:FindFirstChild("HumanoidRootPart")
                        if not hitbox then return end
                        local myChar2 = _rbLP.Character
                        local myHRP2  = myChar2 and myChar2:FindFirstChild("HumanoidRootPart")
                        local fromPos = myHRP2 and myHRP2.Position or workspace.CurrentCamera.CFrame.Position
                        local aimPos  = hitbox.Position
                        local look    = CFrame.new(fromPos, aimPos)
                        local camdata = {
                            [utf8.char(1)] = {
                                [utf8.char(0)] = _rbEncCF(look),
                                [utf8.char(1)] = _rbEncCF(look),
                                [utf8.char(2)] = hitbox,
                                [utf8.char(3)] = _rbEncCF(hitbox.CFrame:ToObjectSpace(CFrame.new(aimPos))),
                            }
                        }
                        local ok2 = pcall(function()
                            rem:FireServer(item:Get("ObjectID"), startEnum, camdata, nil)
                        end)
                        if ok2 then _rbLastFire = now end
                    end)
                end)
            else
                if _rbSAHb then _rbSAHb:Disconnect(); _rbSAHb = nil end
                _rbFcCache = nil
            end
        end

        -- (SA Autofire toggle removed per original — wired to external flag if needed)
        getgenv()._RagebotSAAutofire = _rbToggle
    end

    -- ── UE Counter ────────────────────────────────────────────────────
    local _ue_enabled  = false
    local _ue_cooldown = 0.2
    local _ue_distance = 100

    local function _ueCounterTick()
        local char = lp.Character or lp.CharacterAdded:Wait()
        local hrp  = char:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.CFrame = CFrame.new(hrp.Position + Vector3.new(0, _ue_distance, 0)) end
    end

    local GUE = Lib:CreateGroupbox(R, "UE Counter", 3)
    Lib:CreateToggle(GUE, "Enable UE Counter", {
        Default  = false,
        Callback = function(v)
            _ue_enabled = v
            if v then
                task.spawn(function()
                    while _ue_enabled do _ueCounterTick(); task.wait(_ue_cooldown) end
                end)
            end
        end,
    })
    Lib:CreateSlider(GUE, "Teleport Cooldown", { Min=0, Max=1, Default=0.2, Decimals=2, Callback=function(v) _ue_cooldown=v end })
    Lib:CreateSlider(GUE, "Y Distance",        { Min=10, Max=1000, Default=100, Decimals=0, Callback=function(v) _ue_distance=v end })
end)

-- ═══════════════════════════════════════════════════════════════════════
--  EXPOSE PUBLIC API
-- ═══════════════════════════════════════════════════════════════════════
getgenv()._RagebotTbl17 = tbl17
getgenv()._RagebotConfig = gc

-- Cleanup function
getgenv()._RagebotCleanup = function()
    getgenv()._RagebotRunning = nil
    RunService:UnbindFromRenderStep("GravOrbit")
    if tbl17.cache then
        for _, v in pairs(tbl17.cache) do
            if type(v) == "table" and type(v.c) == "table" then
                local d = type(v.c.Destroy)=="function" and v.c.Destroy or type(v.c.Clean)=="function" and v.c.Clean
                if d then pcall(d, v.c) end
            end
        end
    end
end

print("[Ragebot] Loaded successfully. Config at getgenv()._RagebotConfig.Data.Ragebot")
