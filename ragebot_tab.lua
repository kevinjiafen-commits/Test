-- =========================================================
-- RAGEBOT TAB — EXTRACTED STANDALONE
-- Source: JewHook original script
-- Contains: Rage engine, PolarCore, GunHook, Elisium Ragebot,
--           Fake Underground, Graviton Ragebot, UI: Rage tab only
-- =========================================================

-- =========================================================
-- LINORIA UI SETUP
-- =========================================================
local repo = 'https://raw.githubusercontent.com/mstudio45/LinoriaLib/main/'
local Library, ThemeManager, SaveManager
do
    local files, pending = {}, 3
    local urls = { 'Library.lua', 'addons/ThemeManager.lua', 'addons/SaveManager.lua' }
    for i = 1, 3 do
        task.spawn(function()
            local got, body = pcall(function() return game:HttpGet(repo .. urls[i]) end)
            if got and type(body) == 'string' and #body > 0 then files[i] = body end
            pending = pending - 1
        end)
    end
    local deadline = tick() + 20
    while pending > 0 and tick() < deadline do task.wait() end
    for i = 1, 3 do
        if files[i] == nil then warn("[Engine] failed to fetch " .. urls[i]); return end
    end
    local src = files[1]
    local patched, n = src:gsub('if not FetchIcons then', 'if not Icons then')
    if n > 0 then src = patched end
    Library      = loadstring(src)()
    ThemeManager = loadstring(files[2])()
    SaveManager  = loadstring(files[3])()
end
if not Library then return end

local cloneref = clonereference or cloneref or function(x) return x end
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local VirtualInputMgr   = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Lighting          = game:GetService("Lighting")
local Workspace         = workspace
local Camera            = workspace.CurrentCamera
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    Camera = workspace.CurrentCamera
end)
local lp                = Players.LocalPlayer
local isMobile          = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local Options = Library.Options or {}
local Toggles = Library.Toggles or {}
Library.Options = Options
Library.Toggles = Toggles

-- =========================================================
-- WAIT FOR GAME + MODULE LOADING
-- =========================================================
local _safePlayersCache = nil
local function getSafePlayers()
    if _safePlayersCache then return _safePlayersCache end
    local list = {}
    for _, p in ipairs(Players:GetChildren()) do
        if p:IsA("Player") then list[#list+1] = p end
    end
    _safePlayersCache = list
    return list
end
Players.PlayerAdded:Connect(function() _safePlayersCache = nil end)
Players.PlayerRemoving:Connect(function() _safePlayersCache = nil end)

local function waitForGameReady()
    repeat task.wait() until game:IsLoaded()
    if not lp then repeat task.wait() until Players.LocalPlayer; end
    if not lp:FindFirstChild("PlayerScripts") then
        repeat task.wait() until lp:FindFirstChild("PlayerScripts")
    end
    local deadline = tick() + 5
    while lp.Character == nil and tick() < deadline do task.wait() end
    return true
end
waitForGameReady()

local function safeRequire(path, timeout)
    if not path then return nil end
    timeout = timeout or 5
    local start = tick()
    while tick() - start < timeout do
        local ok, result = pcall(require, path)
        if ok then return result end
        task.wait(0.2)
    end
    return nil
end
local function waitModule(root, names, timeout)
    timeout = timeout or 10
    local obj = root
    for _, n in ipairs(names) do
        if not obj then return nil end
        local ok, child = pcall(function() return obj:WaitForChild(n, timeout) end)
        obj = ok and child or nil
    end
    return obj
end
local function awaitGameLoaded(moduleInst, timeout)
    if not moduleInst or type(getloadedmodules) ~= "function" then return end
    local deadline = tick() + (timeout or 15)
    repeat
        local ok, loaded = pcall(getloadedmodules)
        if ok and type(loaded) == "table" then
            for _, m in ipairs(loaded) do
                if m == moduleInst then return end
            end
        end
        task.wait(0.1)
    until tick() >= deadline
end
local function loadGameModule(root, names)
    local inst = waitModule(root, names)
    awaitGameLoaded(inst, 15)
    return safeRequire(inst)
end

local Rivals = { Ready = false }
local function resolveAll(jobs, timeout)
    local pending = #jobs
    for _, job in ipairs(jobs) do
        task.spawn(function() pcall(job); pending = pending - 1 end)
    end
    local deadline = tick() + (timeout or 25)
    while pending > 0 and tick() < deadline do task.wait() end
    return pending == 0
end
resolveAll({
    function() Rivals.Util      = loadGameModule(ReplicatedStorage, {"Modules","Utility"}) end,
    function() Rivals.Fighter   = loadGameModule(lp.PlayerScripts,  {"Controllers","FighterController"}) end,
    function() Rivals.Enums     = loadGameModule(ReplicatedStorage, {"Modules","EnumLibrary"}) end,
    function() Rivals.Cosmetics = loadGameModule(ReplicatedStorage, {"Modules","CosmeticLibrary"}) end,
    function() Rivals.ItemLib   = loadGameModule(ReplicatedStorage, {"Modules","ItemLibrary"}) end,
    function() Rivals.CameraController = loadGameModule(lp.PlayerScripts, {"Controllers","CameraController"}) end,
})
Rivals.Ready = (Rivals.Util ~= nil and Rivals.Fighter ~= nil)

local _weaponResolving = false
local hookGunModule
local function resolveWeaponModules()
    if _weaponResolving then return end
    if Rivals.Gun ~= nil and Rivals.Melee ~= nil and Rivals.Knife ~= nil then return end
    _weaponResolving = true
    task.spawn(function()
        resolveAll({
            function() if Rivals.Gun   == nil then Rivals.Gun   = loadGameModule(lp.PlayerScripts, {"Modules","ItemTypes","Gun"})   end end,
            function() if Rivals.Melee == nil then Rivals.Melee = loadGameModule(lp.PlayerScripts, {"Modules","ItemTypes","Melee"}) end end,
            function() if Rivals.Knife == nil then Rivals.Knife = loadGameModule(lp.PlayerScripts, {"Modules","Items","Knife"})     end end,
        })
        _weaponResolving = false
        if Rivals.Gun ~= nil and hookGunModule ~= nil then pcall(hookGunModule) end
    end)
end
resolveWeaponModules()
lp.CharacterAdded:Connect(function()
    task.wait(0.5)
    resolveWeaponModules()
    if Rivals.Ready and hookGunModule then hookGunModule() end
end)

-- =========================================================
-- CONFIG (Rage-relevant keys only)
-- =========================================================
local Config = {
    -- Shared targeting (used by rage)
    MaxDistance = 1200, TeamCheck = true, PredictiveLead = true, LeadCap = 15,
    ServerProcessingMs = 30, ProjectileLead = false, ProjectileSpeed = 300,
    AvoidDeflect = true,
    -- RAGE
    Rage = false, RageFireRateOverride = 0, RageRestoreWhileFiring = false,
    RageVoidMove = true, RageVoidMinStep = 25000, RageVoidJitterLocal = false,
    RageVoidJitterStuds = 2000, RageEyeMuzzleSep = 0.07, RageVoidDepth = "deep",
    RageGatePoison = true, RagePredictPrefire = true, RageSkipImmune = true,
    RagePredictResurface = true, RageAttackContinuity = true, RageKnifeBot = true,
    RageMeleeAsk = true, RageMeleeLog = false, RageKnifeCamForge = true,
    RageParkLift = false, RagePolarParity = true, RagePhysicsFlags = true,
    RageRestoreMode = "auto", RageCameraAnchor = true, RagePartGlue = false,
    RageGumMode = "on", RageGumVoidFire = true, RageAttackTranslocate = false,
    RageTapsPerFrame = 1, RagePrioritizeHackers = true, RageHideJitter = true,
    RageHPPriority = true, RageFastTargetSwitch = true, RageVisCheck = false,
    RageShieldBackstab = true, RageKnifeBackstab = true, RageKillPlaneBuffer = 200,
    RageLab = false, RageVoidPhase = true, RageMode = "Polar", RageDirectFire = true,
    RageRateLimit = false, RageTaps = 6, RageCombatOrbitRadius = 60,
    RageOrbitDwell = 0.30, RageCombatOrbitHeight = 8, RageCombatOrbitJitter = true,
    RagePBEyeUp = 3, RageOnEmpty = "Swap", RagePreferredSlot = "Primary",
    RageSwitchMelee = false, RageSwitchRateLimit = 0.06,
    RageWeaponPick = "Primary", RageGlueMode = "off",
    RageWallbang = false, RageWallbangVisCheck = false,
}
if isMobile then Config.AimbotKey = "Always" end

-- =========================================================
-- STATE
-- =========================================================
local State = {
    ESPObjects = {}, PrimaryTarget = nil, SilentLastTarget = nil,
    AimbotTarget = nil, AimbotPart = nil, AimbotLastTarget = nil, AimbotLastTargetTime = 0,
    AimbotKeyHeld = false, AimbotFlickActive = false, AimbotSpringOffset = Vector2.zero,
    TargetLockTarget = nil, TargetLockTap = false,
    CamPos = Vector3.zero, Shots = 0, Hits = 0, Target = nil,
    RageRealCF = nil, RageRealChar = nil, RageTarget = nil,
    RageVoidCF = nil, RageVoidNext = 0, RageVoidBase = nil, RageVoidSteps = 0,
    RageLastFireTime = 0, RageReloadLast = 0, RageSwitchLast = 0,
    OrbitAngle = 0, OrbitVantage = nil, OrbitVantageUntil = 0,
    RageForging = false, RageLeakCanary = 0, RageTracerCanary = 0, RageBlankCanary = 0,
    RageOOBParkCanary = 0, RageHitsOn = 0, RageHitsOff = 0,
    RageOffFromSelf = 0, RageOffFromTarget = 0, ViewAngleForged = false,
    RageKnifeSwings = 0, RageKnifeStatus = "idle", RageRawSet = false,
    RagePhysRate = "off", RageParkDirty = false, RageLastParkPos = nil,
    RageParkLatchCanary = 0, RageLatchStuds = 0, RageOrderCanary = 0,
    RagePostPark = false, RageBelowPlaneFrames = 0, RageBelowPlaneLast = 0,
    RageBelowPlaneDeaths = 0, RageParkDriftFrames = 0, RageParkDrift = 0,
    RageParkDriftY = 0, RageEyeClampFrames = 0, RageParkClampFrames = 0,
    RageTranslocateBaits = 0, RageVoidFires = 0, RagePoisonBlips = 0,
    RagePreFires = 0, RagePredTarget = nil,
    RagePredHide = 0, RagePredHideN = 0, RagePredAtk = 0, RagePredAtkN = 0,
    RagePredPhase = "?", RagePredFor = 0, RagePredDue = 0, RagePredWindow = false,
    RagePredMag = 0, RageGumMode = "off", RageKnifeHintLast = 0,
    RageInMatch = false, RageStatus = "Idle",
    RageFireFromPos = nil, RageFireAimPos = nil, RageFireHitPart = nil,
    RageFireStamp = 0, RageDealtTotal = 0, RageFiring = false,
    RageVoidActive = false, RageTranslocating = false,
    RageTrueVelocityMap = {}, RageSuspectedProtection = {}, RageBacktrackBuf = {},
    RageCharTokens = {},
    RageGlueBound = false, RageGlueVerified = nil, RageImmuneOverride = 0,
    RageAutoTransport = "kicia", RageTransportSwitches = 0, RageLastLossAt = 0,
    AutoWeaponFails = 0,
    LastAttackWeapon = nil, LastAttackWeaponAt = 0,
}

-- =========================================================
-- HELPERS
-- =========================================================
local HEAD_PARTS    = { "HitboxHead", "HitboxHeadSmall", "Head" }
local TORSO_PARTS   = { "HitboxBody", "UpperTorso", "HumanoidRootPart", "LowerTorso" }
local CLOSEST_PARTS = {
    "HitboxHead","Head","UpperTorso","LowerTorso","HumanoidRootPart",
    "LeftHand","RightHand","LeftFoot","RightFoot",
    "LeftUpperArm","RightUpperArm","LeftUpperLeg","RightUpperLeg",
}

local function envIdOf(player)
    local id = nil
    pcall(function()
        local fc = Rivals.Fighter
        if fc == nil then return end
        local f = (player == lp) and fc.LocalFighter or (fc._player_to_fighter and fc._player_to_fighter[player])
        if f == nil then return end
        id = f:Get("EnvironmentID")
        if id == nil and f.Entity ~= nil then id = f.Entity:Get("EnvironmentID") end
    end)
    return id
end
local function isTeammate(player)
    if player == lp then return true end
    local myEnv, theirEnv = envIdOf(lp), envIdOf(player)
    if myEnv ~= nil and theirEnv ~= nil and myEnv ~= theirEnv then return true end
    local a = lp:GetAttribute("TeamID")
    local b = player:GetAttribute("TeamID")
    if a == nil or b == nil then
        if lp.Team ~= nil and player.Team ~= nil then return lp.Team == player.Team end
        return false
    end
    return a == b
end
local function isAlive(player)
    local c = player.Character
    local h = c and c:FindFirstChildOfClass("Humanoid")
    return h ~= nil and h.Health > 0
end
local function getHealth(player)
    if not player.Character then return 0, 100 end
    local h = player.Character:FindFirstChildOfClass("Humanoid")
    if not h then return 0, 100 end
    return h.Health, h.MaxHealth
end
local function getWeaponName(player)
    if not player or not player.Character then return "?" end
    local ok, res = pcall(function()
        if Rivals.Ready and Rivals.Fighter and Rivals.Fighter._player_to_fighter then
            local f = Rivals.Fighter._player_to_fighter[player]
            if f and f.EquippedItem and f.EquippedItem.Info then
                return f.EquippedItem.Info.Name
            end
        end
        return nil
    end)
    if ok and type(res) == "string" and res ~= "" then return res end
    local ok2, fallback = pcall(function()
        for _, c in ipairs(player.Character:GetChildren()) do
            if c:IsA("Model") and not c:FindFirstChildOfClass("Humanoid") then
                if c.PrimaryPart or c:FindFirstChildWhichIsA("BasePart") then return c.Name end
            end
            if c:IsA("Tool") then return c.Name end
        end
        return "?"
    end)
    return (ok2 and type(fallback) == "string") and fallback or "?"
end
local function pickPart(char, mode)
    if not char then return nil end
    if mode == "Closest" then
        local best, bestDist = nil, math.huge
        local vp     = Camera.ViewportSize
        local center = Vector2.new(vp.X * 0.5, vp.Y * 0.5)
        for _, name in ipairs(CLOSEST_PARTS) do
            local p = char:FindFirstChild(name)
            if p and p:IsA("BasePart") then
                local sp, on = Camera:WorldToViewportPoint(p.Position)
                if on and sp.Z > 0 then
                    local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                    if d < bestDist then best, bestDist = p, d end
                end
            end
        end
        if best then return best end
    end
    local list = mode == "Torso" and TORSO_PARTS or HEAD_PARTS
    for _, name in ipairs(list) do
        local p = char:FindFirstChild(name)
        if p and p:IsA("BasePart") then return p end
    end
    return char:FindFirstChild("HumanoidRootPart")
end
local visParams = RaycastParams.new()
visParams.FilterType = Enum.RaycastFilterType.Exclude
local _visFilterChar = nil
local function isVisible(worldPos)
    local origin = Camera.CFrame.Position
    local _vc = lp.Character
    if _vc ~= _visFilterChar then
        visParams.FilterDescendantsInstances = { _vc }
        _visFilterChar = _vc
    end
    local result = Workspace:Raycast(origin, worldPos - origin, visParams)
    if not result then return true end
    local hitModel = result.Instance and result.Instance:FindFirstAncestorOfClass("Model")
    if hitModel and Players:GetPlayerFromCharacter(hitModel) then return true end
    return (result.Position - worldPos).Magnitude < 3
end

-- Deflect tracking
local DEFLECT_ANIM_IDS = {
    ["14761240825"] = true, ["14761220206"] = true,
    ["14761234917"] = true, ["14761221711"] = true, ["14761223422"] = true, ["14761225204"] = true, ["14761232380"] = true,
    ["90436105114997"] = true, ["90797895557136"] = true, ["77995180947430"] = true, ["111943779640553"] = true,
    ["131072510521727"] = true, ["132022220827223"] = true, ["116315405171252"] = true, ["110358509711635"] = true, ["98242486936084"] = true, ["81132288854196"] = true,
    ["123293403148826"] = true, ["136354716301184"] = true, ["120567011479119"] = true, ["92502373956550"] = true, ["83541611040586"] = true, ["92773106977434"] = true,
    ["75844592081515"] = true, ["75381142568185"] = true,
}
local function isDeflectingAnim(player)
    if not player or not player.Character then return false end
    local hum = player.Character:FindFirstChildOfClass("Humanoid")
    if not hum then return false end
    local animator = hum:FindFirstChildOfClass("Animator")
    if not animator then return false end
    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
        if track.Name:lower():find("deflect") then return true end
        local anim = track.Animation
        local id = anim and anim.AnimationId
        if id then
            local num = id:match("(%d+)")
            if num and DEFLECT_ANIM_IDS[num] then return true end
        end
    end
    return false
end
local _deflecting = {}
local _deflGen    = {}
local _deflHookLive = false
local DEFLECT_CLEAR_PAD = 0.05
local function isDeflecting(player)
    if not player then return false end
    if _deflecting[player.UserId] then return true end
    if _deflHookLive then return false end
    return isDeflectingAnim(player)
end
;(function()
    local function recordDeflect(self)
        local fighter = self and self.ClientFighter
        local plr = fighter and fighter.Player
        if not plr then return end
        local uid = plr.UserId
        local dur = self.Info and self.Info.DeflectDuration
        if type(dur) ~= "number" then dur = 0.1 end
        _deflecting[uid] = true
        local gen = (_deflGen[uid] or 0) + 1
        _deflGen[uid] = gen
        task.delay(dur + DEFLECT_CLEAR_PAD, function()
            if _deflGen[uid] == gen then _deflecting[uid] = nil end
        end)
    end
    task.spawn(function()
        local ok, katana = pcall(loadGameModule, lp.PlayerScripts, {"Modules", "Items", "Katana"})
        if not ok or type(katana) ~= "table" or type(katana._StartDeflecting) ~= "function" then return end
        local orig = shared._JH_KatanaDeflOrig
        if not orig then orig = clonefunction(katana._StartDeflecting) end
        shared._JH_KatanaMod      = katana
        shared._JH_KatanaDeflOrig = orig
        if setreadonly then pcall(setreadonly, katana, false) end
        katana._StartDeflecting = function(self, ...)
            pcall(recordDeflect, self)
            return orig(self, ...)
        end
        _deflHookLive = true
    end)
end)()

-- Spawn protection
local _invincible = {}
local _invincEnt  = {}
local function isSpawnProtected(player)
    if not player then return false end
    if not (Rivals.Ready and Rivals.Fighter) then return false end
    local map = Rivals.Fighter._player_to_fighter
    if not map then return false end
    local f = map[player]
    if not f then return false end
    local e = f.Entity
    if not e then return false end
    local uid = player.UserId
    if _invincEnt[uid] ~= e then
        _invincible[uid] = nil
        local ok = pcall(function()
            local live = e:Get("IsInvincible") == true
            e:GetDataChangedSignal("IsInvincible"):Connect(function()
                _invincible[uid] = e:Get("IsInvincible") == true
            end)
            _invincible[uid] = live
        end)
        if ok then _invincEnt[uid] = e end
    end
    return _invincible[uid] == true
end

-- Weapon class helpers
local KATANA_NAMES = { "katana", "saber", "lightning bolt", "evil trident", "tridant", "devil's trident", "linked sword", "keytana", "cutlass", "swordfish", "riptide" }
local function isKatana(player)
    local w = getWeaponName(player):lower()
    for _, n in ipairs(KATANA_NAMES) do
        if w:find(n, 1, true) then return true end
    end
    return isDeflecting(player)
end
local KNIFE_NAMES = { "knife", "karambit", "balisong", "chancla", "machete", "candy cane", "armature", "daggers", "axe" }
local function isEnemyKnife(player)
    if not player then return false end
    local w = getWeaponName(player):lower()
    for _, n in ipairs(KNIFE_NAMES) do
        if w:find(n, 1, true) then return true end
    end
    return false
end
local function isLocalKnife()
    local lf = Rivals.Fighter and Rivals.Fighter.LocalFighter
    if lf and lf.EquippedItem then
        local name = lf.EquippedItem.Name:lower()
        for _, n in ipairs(KNIFE_NAMES) do
            if name:find(n, 1, true) then return true end
        end
    end
    return false
end
local function isRiotShield(player)
    local w = getWeaponName(player):lower()
    return w:find("riot shield") or w:find("energy shield") or w:find("tombstone shield")
        or w:find("broken surfboard", 1, true) or w == "door" or w == "sled" or w == "masterpiece"
end
local function ownsRiotShield(player)
    if not player then return false end
    local ok, res = pcall(function()
        if not (Rivals.Ready and Rivals.Fighter and Rivals.Fighter._player_to_fighter) then return false end
        local f = Rivals.Fighter._player_to_fighter[player]
        local items = f and f.Items
        if type(items) ~= "table" then return false end
        for _, it in items do
            local n = nil
            if type(it) == "table" then
                n = it.Name
                if n == nil and it.Info then n = it.Info.Name end
            end
            if type(n) == "string" then
                local low = n:lower()
                if low:find("riot shield") or low:find("energy shield") or low:find("tombstone shield") then
                    return true
                end
            end
        end
        return false
    end)
    return ok and res == true
end

local function inMatch()
    local envOk = false
    pcall(function()
        local lf = Rivals.Fighter and Rivals.Fighter.LocalFighter
        if lf ~= nil and lf:Get("EnvironmentID") ~= nil and lf:IsAlive() then envOk = true end
    end)
    if envOk then return true end
    if lp:GetAttribute("TeamID") ~= nil then return true end
    if lp.Team ~= nil then return true end
    local lf = Rivals.Ready and Rivals.Fighter and Rivals.Fighter.LocalFighter
    if lf then
        local ok, objId = pcall(function() return lf.EquippedItem and lf.EquippedItem:Get("ObjectID") end)
        if ok and objId then return true end
    end
    return false
end

local function isSanePos(p)
    return p == p
        and math.abs(p.X) < 100000
        and math.abs(p.Y) < 100000
        and math.abs(p.Z) < 100000
end
local function posInPart(pos, part)
    if not part or not part.Parent then return false end
    local lpv = part.CFrame:PointToObjectSpace(pos)
    local s = part.Size * 0.5
    return math.abs(lpv.X) <= s.X and math.abs(lpv.Y) <= s.Y and math.abs(lpv.Z) <= s.Z
end
local function posIsOOB(pos)
    local ok, result = pcall(function()
        for _, p in ipairs(CollectionService:GetTagged("OutOfBoundsSafePart")) do
            if posInPart(pos, p) then return false end
        end
        for _, p in ipairs(CollectionService:GetTagged("OutOfBoundsPart")) do
            if posInPart(pos, p) then return true end
        end
        return false
    end)
    return ok and result == true
end

-- Velocity map
local _sharedVelMap = {}
;(function()
    local _svPos, _svTime = {}, {}
    local _svAccum = 0
    local SV_INTERVAL = 1 / 30
    local function velTrackerStep(dt)
        if not Config.Rage then return end
        _svAccum = _svAccum + (dt or 0)
        if _svAccum < SV_INTERVAL then return end
        _svAccum = 0
        local now = tick()
        for _, p in ipairs(getSafePlayers() or {}) do
            if p ~= lp and p.Character then
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local pos = hrp.Position
                    local lt  = _svTime[p]
                    if _svPos[p] and lt then
                        local d = now - lt
                        if d > 0 then
                            local v = (pos - _svPos[p]) / d
                            if v.Magnitude < 500 then _sharedVelMap[p] = v end
                        end
                    end
                    _svPos[p]  = pos
                    _svTime[p] = now
                end
            end
        end
    end
    if shared._JH_velConn then pcall(function() shared._JH_velConn:Disconnect() end) end
    shared._JH_velConn = RunService.Heartbeat:Connect(velTrackerStep)
end)()

local function calculateLead(targetChar, fromPos, wantLead)
    if wantLead == nil then wantLead = Config.PredictiveLead end
    if not targetChar then return Vector3.new() end
    local hum = targetChar:FindFirstChildOfClass("Humanoid")
    local hrp = targetChar:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return Vector3.new() end
    local lat = (lp:GetNetworkPing() or 0.05) + ((Config.ServerProcessingMs or 30) / 1000)
    if Config.ProjectileLead and (Config.ProjectileSpeed or 0) > 0 then
        lat = lat + (hrp.Position - fromPos).Magnitude / Config.ProjectileSpeed
    end
    local lead = Vector3.new()
    if wantLead then
        local ply     = Players:GetPlayerFromCharacter(targetChar)
        local trueVel = hrp.AssemblyLinearVelocity
        local calcVel = ply and (_sharedVelMap[ply] or State.RageTrueVelocityMap[ply])
        if calcVel then
            if (trueVel - calcVel).Magnitude > 25 then trueVel = calcVel end
        else
            if trueVel.Magnitude > 100 then trueVel = Vector3.new() end
        end
        if trueVel.Magnitude > 120 then trueVel = Vector3.new() end
        local md = hum.MoveDirection
        if md.Magnitude > 0.1 then
            lead = lead + Vector3.new(trueVel.X, 0, trueVel.Z) * lat
        end
        lead = lead + Vector3.new(0, trueVel.Y * lat, 0)
    end
    local cap = Config.LeadCap or 15
    if lead.Magnitude > cap then lead = lead.Unit * cap end
    return lead
end

local function isValidTarget(player, checkVis, keepDeflect, rageScope)
    if not player or player == lp then return false end
    if Config.TeamCheck and isTeammate(player) then return false end
    if not isAlive(player) then return false end
    if Config.AvoidDeflect and not keepDeflect and isDeflecting(player) then return false end
    if Config.RageSkipImmune and not rageScope and isSpawnProtected(player) then return false end
    local char = player.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    local sane = isSanePos(hrp.Position)
    if not rageScope then
        if not sane then return false end
        local myChar = lp.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if myRoot and (hrp.Position - myRoot.Position).Magnitude > Config.MaxDistance then return false end
    end
    if checkVis and sane and not Config.RageWallbang and not isVisible(hrp.Position) then return false end
    return true
end

-- =========================================================
-- ViewAngle
-- =========================================================
local ViewAngle = {}
;(function()
    local _remote     = nil
    local _forged     = nil
    local _loopFn, _utilIdx, _utilOrig = nil, nil, nil
    local _suppressed = false
    local _joints, _jointsOrig = nil, nil
    local function remote()
        if _remote == nil then
            pcall(function() _remote = ReplicatedStorage.Remotes.Replication.Fighter.UpdateCameraRotation end)
        end
        return _remote
    end
    local function resolveLoop()
        if _loopFn ~= nil then return true end
        if type(debug) ~= "table" or type(debug.getupvalues) ~= "function"
           or type(debug.setupvalue) ~= "function" then return false end
        pcall(function()
            local F = Rivals.Fighter
            if F == nil then return end
            local fn = rawget(F, "_CameraReplicationLoop")
            if type(fn) ~= "function" then
                local mt = getmetatable(F)
                local proto = mt and rawget(mt, "__index")
                if type(proto) == "table" then fn = rawget(proto, "_CameraReplicationLoop") end
            end
            if type(fn) ~= "function" then return end
            for i, v in debug.getupvalues(fn) do
                if type(v) == "table" then
                    local vmt = getmetatable(v)
                    local vidx = vmt and rawget(vmt, "__index")
                    if type(vidx) == "table" and rawget(vidx, "EncodeCameraRotation") ~= nil then
                        _loopFn, _utilIdx, _utilOrig = fn, i, v
                        return
                    end
                end
            end
        end)
        return _loopFn ~= nil
    end
    local function makeShim()
        local shim = {}
        shim.EncodeCameraRotation = function(_, rot)
            local last = nil
            pcall(function()
                local F = Rivals.Fighter
                if F ~= nil then
                    F._replication_stopped = false
                    last = F._last_encoded_camera_rotation
                end
            end)
            if last ~= nil then return last end
            return _utilOrig:EncodeCameraRotation(rot)
        end
        return setmetatable(shim, { __index = _utilOrig })
    end
    local function suppress(on)
        if on == _suppressed then return end
        if on then
            if not resolveLoop() then return end
            if pcall(debug.setupvalue, _loopFn, _utilIdx, makeShim()) then
                _suppressed = true
                State.ViewAngleForged = true
            end
            return
        end
        if _loopFn ~= nil and _utilOrig ~= nil then
            pcall(debug.setupvalue, _loopFn, _utilIdx, _utilOrig)
        end
        _suppressed = false
        State.ViewAngleForged = false
    end
    local function patchJoints(on)
        if on then
            if _jointsOrig ~= nil then return end
            pcall(function()
                _joints = loadGameModule(lp.PlayerScripts,
                    {"Modules", "ClientReplicatedClasses", "ClientFighter", "ClientFighterCharacter", "Joints"})
                if type(_joints) ~= "table" then _joints = nil return end
                local orig = rawget(_joints, "Update")
                if type(orig) ~= "function" then _joints = nil return end
                _jointsOrig = orig
                if setreadonly then pcall(setreadonly, _joints, false) end
                _joints.Update = function(selfJoints, dt, data)
                    if _forged ~= nil and type(data) == "table" then
                        pcall(function()
                            local cfc = selfJoints.ClientFighterCharacter
                            local cf = cfc and cfc.ClientFighter
                            if cf and cf.IsLocalPlayer == true then
                                data.CameraRotationRaw = _forged
                            end
                        end)
                    end
                    return orig(selfJoints, dt, data)
                end
            end)
            return
        end
        if _joints ~= nil and _jointsOrig ~= nil then
            pcall(function()
                if setreadonly then pcall(setreadonly, _joints, false) end
                _joints.Update = _jointsOrig
            end)
        end
        _jointsOrig = nil
    end
    function ViewAngle.forge(pitch, yaw)
        local r = remote()
        if r == nil or not Rivals.Util then return false end
        local ok = pcall(function()
            local enc = Rivals.Util:EncodeCameraRotation(Vector2.new(pitch, yaw))
            _forged = Rivals.Util:DecodeCameraRotation(enc)
            r:FireServer(enc, nil)
        end)
        if not ok then return false end
        suppress(true); patchJoints(true); return true
    end
    function ViewAngle.restore() _forged = nil; suppress(false); patchJoints(false) end
    ViewAngle.isForging = function() return _forged ~= nil end
end)()

-- =========================================================
-- RAGE
-- =========================================================
local Rage = {}
;(function()
    local function bump(p) State.RageCharTokens[p] = (State.RageCharTokens[p] or 0) + 1 end
    local function killFloor() return workspace.FallenPartsDestroyHeight + Config.RageKillPlaneBuffer end

    local function lookCF(eye, target)
        if (target - eye).Magnitude < 0.001 then return CFrame.new(eye) end
        return CFrame.lookAt(eye, target)
    end
    Rage._lookCF = lookCF

    local function buildShotFields(tbl, eyeCF, muzzleCF, hitPart, hitPos, forceEye, eyeMuzzleSep, clampFrac)
        if not tbl or not hitPart then return end
        local K0, K1, K2, K3 = utf8.char(0), utf8.char(1), utf8.char(2), utf8.char(3)
        eyeMuzzleSep = eyeMuzzleSep or Config.RageEyeMuzzleSep or 0.07
        clampFrac    = clampFrac    or 0.30
        local hitObjSpace = hitPart.CFrame:ToObjectSpace(CFrame.new(hitPos))
        tbl[K1] = {
            [K0] = Rivals.Util:EncodeCFrame(eyeCF),
            [K1] = Rivals.Util:EncodeCFrame(muzzleCF),
            [K2] = hitPart,
            [K3] = Rivals.Util:EncodeCFrame(hitObjSpace),
        }
    end
    Rage._buildShotFields = buildShotFields

    local function encodeShot(camData, hitPart, targetChar, fromPos, jitter)
        if not (Rivals.Ready and Rivals.Util) then return false end
        if not hitPart or not targetChar then return false end
        local hrp = targetChar:FindFirstChild("HumanoidRootPart")
        if not hrp then return false end
        fromPos = fromPos or Camera.CFrame.Position
        jitter  = jitter  or Vector3.zero
        local lead      = calculateLead(targetChar, fromPos)
        local hitPos    = hitPart.Position + lead + jitter
        local eyeCF     = lookCF(fromPos, hitPos)
        local muzzlePos = fromPos + eyeCF.LookVector * (Config.RageEyeMuzzleSep or 0.07)
        local muzzleCF  = lookCF(muzzlePos, hitPos)
        local ok = pcall(buildShotFields, camData, eyeCF, muzzleCF, hitPart, hitPos, false,
            Config.RageEyeMuzzleSep, 0.30)
        return ok
    end
    Rage._encodeShot = encodeShot

    local function getEquippedItem()
        if not Rivals.Ready then return nil end
        local f = Rivals.Fighter and Rivals.Fighter.LocalFighter
        return f and f.EquippedItem or nil
    end

    local function itemIsMelee(item)
        if not item then return false end
        local name = (item.Name or ""):lower()
        for _, n in ipairs(KNIFE_NAMES) do if name:find(n,1,true) then return true end end
        local KATANA_LOW = { "katana","saber","lightning bolt","evil trident","tridant","devil's trident","linked sword","keytana","cutlass","swordfish","riptide" }
        for _, n in ipairs(KATANA_LOW) do if name:find(n,1,true) then return true end end
        local info = item.Info
        if type(info) == "table" then
            local wtype = info.WeaponType or info.Type or ""
            if type(wtype) == "string" then
                local wl = wtype:lower()
                if wl == "melee" or wl == "knife" then return true end
            end
        end
        return false
    end
    Rage._itemIsMelee = itemIsMelee

    local function equipSlot(slotIdx)
        pcall(function()
            local lf = Rivals.Fighter and Rivals.Fighter.LocalFighter
            if lf then lf:EquipItem(slotIdx) end
        end)
    end
    local function nextUsableSlot(currentItem)
        if not Rivals.Ready or not Rivals.Fighter then return nil end
        local lf = Rivals.Fighter.LocalFighter
        if not lf or not lf.Items then return nil end
        local items = lf.Items
        if type(items) ~= "table" then return nil end
        local preferSlot = Config.RagePreferredSlot or "Primary"
        local slotOrder = preferSlot == "Secondary"
            and {2, 1, 3} or {1, 2, 3}
        for _, si in ipairs(slotOrder) do
            local it = items[si]
            if it and it ~= currentItem then
                local isM = itemIsMelee(it)
                if not isM then
                    return si, it
                end
            end
        end
        return nil, nil
    end
    local function whichSlotNow()
        if not Rivals.Ready or not Rivals.Fighter then return nil end
        local lf = Rivals.Fighter.LocalFighter
        if not lf then return nil end
        local cur = lf.EquippedItem
        local items = lf.Items
        if type(items) ~= "table" then return nil end
        for si, it in ipairs(items) do
            if it == cur then return si end
        end
        return nil
    end
    Rage._equipSlot       = equipSlot
    Rage._nextUsableSlot  = nextUsableSlot
    Rage._whichSlotNow    = whichSlotNow

    local function encodeRageShot(camData)
        if not (Rivals.Ready and Rivals.Util) then return false end
        local tgt = State.RageTarget
        if not tgt then return false end
        local char = tgt.Character
        if not char then return false end
        local it = getEquippedItem()
        if it and itemIsMelee(it) then return false end
        local head = char:FindFirstChild("HitboxHead") or char:FindFirstChild("Head")
        if not head then return false end
        local fromPos = State.RageFireFromPos or Camera.CFrame.Position
        return encodeShot(camData, head, char, fromPos)
    end
    Rage._encodeRageShot = encodeRageShot

    local function findTarget()
        local best, bestScore = nil, math.huge
        local myChar = lp.Character
        local myHRP  = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myHRP then return nil end
        for _, pl in ipairs(getSafePlayers()) do
            if isValidTarget(pl, Config.RageVisCheck, true, true) then
                local ch  = pl.Character
                local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local d = (myHRP.Position - hrp.Position).Magnitude
                    local hp, maxhp = getHealth(pl)
                    local score = d
                    if Config.RageHPPriority then score = score * (hp / math.max(maxhp, 1)) end
                    if Config.RagePrioritizeHackers and State.RageSuspectedProtection[pl] then
                        score = score * 0.1
                    end
                    if score < bestScore then bestScore, best = score, pl end
                end
            end
        end
        return best
    end
    Rage._findTarget = findTarget

    local _targetLoop = nil
    local function startTargetLoop()
        if _targetLoop then return end
        _targetLoop = task.spawn(function()
            while Config.Rage do
                local tgt = findTarget()
                if tgt ~= State.RageTarget then
                    State.RageTarget = tgt
                end
                task.wait(0.05)
            end
            _targetLoop = nil
        end)
    end
    Rage._startTargetLoop = startTargetLoop

    function Rage.init()
        -- init hook
    end

    local function fireInterval()
        local lf = Rivals.Fighter and Rivals.Fighter.LocalFighter
        local it = lf and lf.EquippedItem
        if not it then return 0 end
        local info = it.Info
        if type(info) ~= "table" then return 0 end
        local cd = tonumber(info.ShootCooldown) or 0
        local burst = tonumber(info.BurstCount) or 1
        local bcd = tonumber(info.BurstCooldown)
        if burst > 1 and bcd then cd = math.min(cd, bcd) end
        return math.clamp(cd, 0, 5)
    end
    Rage._fireInterval = fireInterval

    local function displace(part, cf)
        if not part or not cf then return false end
        local ok = pcall(function() part.CFrame = cf end)
        return ok
    end
    Rage._displace = displace

    local function ensureReload(it)
        if not it then return false end
        local lf = Rivals.Fighter and Rivals.Fighter.LocalFighter
        if not lf then return false end
        pcall(function() lf:ReloadItem(it) end)
        return true
    end
    Rage._ensureReload = ensureReload

    local function weaponRecovery(it)
        local mode = Config.RageOnEmpty or "Swap"
        local empty = false
        pcall(function()
            if it then
                local ammo = it:Get and it:Get("Ammo")
                empty = type(ammo) == "number" and ammo <= 0
            end
        end)
        if mode ~= "Swap" or not empty then return ensureReload(it) end
        local lf = Rivals.Fighter and Rivals.Fighter.LocalFighter
        if not lf then return ensureReload(it) end
        local items = lf.Items
        if type(items) ~= "table" then return ensureReload(it) end
        local si, newIt = nextUsableSlot(it)
        if si and newIt then
            State.RageSwitchLast = tick()
            equipSlot(si)
            return true
        end
        return ensureReload(it)
    end
    Rage._weaponRecovery = weaponRecovery

    -- Rage tick (main per-frame logic) referenced from PolarCore below
    local rageTick
    Rage._rageTick = function(ch, hrp, tgt)
        if rageTick then rageTick(ch, hrp, tgt) end
    end

    local function startRage()
        Config.Rage = true
        startTargetLoop()
        local conn
        conn = RunService.Heartbeat:Connect(function(dt)
            if not Config.Rage then conn:Disconnect(); return end
            local ch  = lp.Character
            local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
            if not (ch and hrp) then return end
            local tgt = State.RageTarget
            if not tgt then tgt = findTarget() end
            if Rage._rageTick then Rage._rageTick(ch, hrp, tgt) end
        end)
    end

    function Rage.enable()
        Config.Rage = true
        if Rage._startTargetLoop then Rage._startTargetLoop() end
        if Rage._polarCoreStart then Rage._polarCoreStart() end
    end
    function Rage.disable()
        Config.Rage = false
        if Rage._polarCoreStop then Rage._polarCoreStop() end
        pcall(ViewAngle.restore)
        State.RageTarget = nil
        State.RageFiring = false
        State.RageStatus = "Idle"
    end
    function Rage.unload()
        Rage.disable()
    end
end)()

-- =========================================================
-- ELISIUM RAGEBOT (ported from Elisium)
-- =========================================================
local ElisiumRage = {}
ElisiumRage.Enabled = false
ElisiumRage.Config = {
    FFA = false,
    OffsetX = 0, OffsetY = 2, OffsetZ = 0,
    Prediction = true,
    PredictionAmount = 1,
    Rate = 0,
}
do
    local ER = ElisiumRage
    local EC = ER.Config

    -- PREDICTION
    local Prediction = {
        enabled = false, multiplier = 1.2,
        velocity = Vector3.new(), acceleration = Vector3.new(),
        lastposition = nil, lasttime = 0,
        velbuffer = {}, posbuffer = {},
        maxvelsamples = 15, maxpossamples = 5,
    }
    function Prediction:Update(target)
        if not self.enabled or not target or not target.Character then
            self.velocity = Vector3.new(); self.acceleration = Vector3.new()
            self.lastposition = nil; self.velbuffer = {}; self.posbuffer = {}
            return
        end
        local root = target.Character:FindFirstChild("HumanoidRootPart")
        if not root then return end
        local now = tick(); local dt = now - self.lasttime
        if dt > 0 and dt < 0.1 then
            local cur = root.Position
            table.insert(self.posbuffer, 1, { position = cur, time = now })
            if #self.posbuffer > self.maxpossamples then table.remove(self.posbuffer) end
            if self.lastposition then
                local instVel = (cur - self.lastposition) / dt
                if self.velocity.Magnitude > 0.1 then
                    local instAcc = (instVel - self.velocity) / dt
                    self.acceleration = self.acceleration:Lerp(instAcc, 0.5)
                end
                table.insert(self.velbuffer, 1, { velocity = instVel, time = now, dt = dt })
                if #self.velbuffer > self.maxvelsamples then table.remove(self.velbuffer) end
                if #self.velbuffer > 0 then
                    local sum, tot = Vector3.new(), 0
                    for i, e in ipairs(self.velbuffer) do
                        local w = math.exp(-(i - 1) * 0.3)
                        sum = sum + e.velocity * w; tot = tot + w
                    end
                    self.velocity = sum / tot
                else self.velocity = instVel end
            end
            self.lastposition = cur; self.lasttime = now
        end
    end
    function Prediction:Predict(targetpart, origin)
        if not self.enabled or not targetpart then return targetpart.Position end
        local base = targetpart.Position
        local dist = (base - origin).Magnitude
        local ping = 0
        pcall(function() ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue() / 1000 end)
        local travel = dist / 3000
        local speed = self.velocity.Magnitude
        local mult = 1.0
        if speed > 150 then mult = 1.5 + math.min((speed - 150) / 300, 1.0)
        elseif speed > 80 then mult = 1.3
        elseif speed > 40 then mult = 1.1
        elseif speed < 10 then mult = 0.7 end
        local total = (travel + ping) * self.multiplier * mult
        local out = base + self.velocity * total
        if self.acceleration.Magnitude > 5 and speed > 50 then
            out = out + self.acceleration * (total * total * 0.5)
        end
        return out
    end

    -- DESYNC
    local Desync = {
        active = false, connection = nil,
        server = nil, client = nil, _hooked = false,
    }
    function Desync:Init()
        if self._hooked then return true end
        if not Rivals.CameraController then return false end
        if type(Rivals.CameraController.Update) ~= "function" then return false end
        self._hooked = true
        local orig = Rivals.CameraController.Update
        Rivals.CameraController.Update = function(...)
            if self.active and self.client then
                local lf = Rivals.Fighter and Rivals.Fighter.LocalFighter
                if lf and lf.Entity and lf.Entity.RootPart then
                    pcall(function() lf.Entity.RootPart.CFrame = self.client end)
                end
            end
            return orig(...)
        end
        return true
    end
    function Desync:Start(target)
        if self.active then return end
        if not lp.Character then return end
        local lf = Rivals.Fighter and Rivals.Fighter.LocalFighter
        if not lf or not lf.Entity or not lf.Entity.RootPart then return end
        if not self:Init() then return end
        self.active = true
        self.connection = RunService.Heartbeat:Connect(function()
            if not self.active then
                if self.connection then self.connection:Disconnect(); self.connection = nil end
                return
            end
            if not target or not target.Character then return end
            local troot = target.Character:FindFirstChild("HumanoidRootPart")
            if not troot then return end
            local lroot = lf.Entity and lf.Entity.RootPart
            if not lroot then return end
            self.server = lroot.CFrame
            local offset = CFrame.new(EC.OffsetX, EC.OffsetY, EC.OffsetZ)
            local toCF = troot.CFrame * offset
            self.client = toCF
            pcall(function() lroot.CFrame = toCF end)
        end)
    end
    function Desync:Stop()
        self.active = false
        if self.connection then self.connection:Disconnect(); self.connection = nil end
        local lf = Rivals.Fighter and Rivals.Fighter.LocalFighter
        if lf and lf.Entity and lf.Entity.RootPart and self.server then
            pcall(function() lf.Entity.RootPart.CFrame = self.server end)
        end
        self.client = nil
        self.server = nil
    end

    -- BOT
    local Bot = {
        connection = nil, lastFire = 0,
    }
    function Bot:FindTarget()
        local myChar = lp.Character
        local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myHRP then return nil end
        local best, bestD = nil, math.huge
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl ~= lp then
                local enemy = true
                if not EC.FFA then
                    local myTeam = lp:GetAttribute("TeamID") or (lp.Team and lp.Team.Name)
                    local theirTeam = pl:GetAttribute("TeamID") or (pl.Team and pl.Team.Name)
                    if myTeam and theirTeam and myTeam == theirTeam then enemy = false end
                end
                if enemy then
                    local ch = pl.Character
                    local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
                    local hum = ch and ch:FindFirstChildOfClass("Humanoid")
                    if hrp and hum and hum.Health > 0 then
                        local d = (myHRP.Position - hrp.Position).Magnitude
                        if d < bestD then bestD = d; best = pl end
                    end
                end
            end
        end
        return best
    end
    function Bot:Fire(target)
        if not (Rivals.Ready and Rivals.Util and Rivals.Enums) then return end
        local lf = Rivals.Fighter and Rivals.Fighter.LocalFighter
        if not lf or not lf.EquippedItem then return end
        local ch = target.Character
        if not ch then return end
        local head = ch:FindFirstChild("HitboxHead") or ch:FindFirstChild("Head")
        local hrp  = ch:FindFirstChild("HumanoidRootPart")
        if not (head and hrp) then return end
        local objectId
        pcall(function() objectId = lf.EquippedItem:Get("ObjectID") end)
        if not objectId then return end
        Prediction.enabled = EC.Prediction
        Prediction.multiplier = EC.PredictionAmount or 1
        Prediction:Update(target)
        local origin = Desync.client and Desync.client.Position or (lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") and lp.Character.HumanoidRootPart.Position) or Vector3.zero
        local aimPos = Prediction:Predict(head, origin)
        local eyePos = origin + Vector3.new(0, 1.5, 0)
        local aimCF  = CFrame.lookAt(eyePos, aimPos)
        local objSpace = head.CFrame:ToObjectSpace(CFrame.new(head.Position))
        local K0, K1, K2, K3 = utf8.char(0), utf8.char(1), utf8.char(2), utf8.char(3)
        local data = {
            [K1] = {
                [K0] = Rivals.Util:EncodeCFrame(aimCF),
                [K1] = Rivals.Util:EncodeCFrame(aimCF),
                [K2] = head,
                [K3] = Rivals.Util:EncodeCFrame(objSpace),
            }
        }
        local en
        pcall(function() en = Rivals.Enums:ToEnum("StartShooting") end)
        if not en then return end
        pcall(function()
            ReplicatedStorage.Remotes.Replication.Fighter.UseItem:FireServer(objectId, en, data, nil)
        end)
    end
    function Bot:Start()
        if self.connection then return end
        self.connection = RunService.Heartbeat:Connect(function()
            if not ER.Enabled then self:Disconnect(); return end
            local now = tick()
            if now - self.lastFire < EC.Rate then return end
            local tgt = self:FindTarget()
            if not tgt then return end
            Desync:Start(tgt)
            self.lastFire = now
            task.spawn(function() self:Fire(tgt) end)
        end)
    end
    function Bot:Disconnect()
        if self.connection then self.connection:Disconnect(); self.connection = nil end
        Desync:Stop()
    end

    ER.Start  = function() ER.Enabled = true;  Bot:Start() end
    ER.Stop   = function() ER.Enabled = false; Bot:Disconnect() end
    ER.Unload = function() ER.Enabled = false; Bot:Disconnect(); if ER.Desync then ER.Desync:Stop() end end
    ER.Desync = Desync
end

-- =========================================================
-- POLAR CORE
-- =========================================================
;(function()
    local PolarCore = {}
    local _realCF, _realChar = nil, nil
    local _voidCF, _target, _inMatch = nil, nil, false
    local _firing, _deflectSince, _shots, _voidSteps = false, 0, 0, 0
    local _shootEnum, _useItem, _notified = nil, nil, nil
    local _conn, _stepConn, _charConn = nil, nil, nil
    local RENDER_NAME = "JewHook_PolarCore_Restore"
    local CAMERA_NAME = "JewHook_PolarCore_CamAnchor"
    local POLAR_TAPS_SANE, EYE_UP_SANE, KILL_PLANE_BUF = 6, 2.5, 200
    local VOID_MIN_STEP, VOID_R_MIN, VOID_R_MAX = 25000, 110000, 140000
    local DEFLECT_MAX_HOLD, IMMUNE_MAX_HOLD = 1.5, 6.0
    local _immuneSince, _immuneTgt = 0, nil
    local EYE_MUZZLE_SEP, RAGE_CLAMP_FRAC = 0.07, 0.30
    local function parity() return Config.RagePolarParity ~= false end

    local function safeEnums()
        if _shootEnum then return true end
        local ok, en = pcall(function() return Rivals.Enums:ToEnum("StartShooting") end)
        if ok and en then _shootEnum = en end
        if not _useItem then
            pcall(function() _useItem = ReplicatedStorage.Remotes.Replication.Fighter.UseItem end)
        end
        return _shootEnum ~= nil and _useItem ~= nil
    end

    local function getKillPlane()
        return workspace.FallenPartsDestroyHeight + (Config.RageKillPlaneBuffer or 200)
    end

    local function voidPosition()
        local mode = Config.RageVoidDepth or "deep"
        local minStep = Config.RageVoidMinStep or 25000
        local r
        if mode == "shallow" then
            r = VOID_R_MIN + math.random() * (VOID_R_MAX - VOID_R_MIN) * 0.3
        else
            r = VOID_R_MIN + math.random() * (VOID_R_MAX - VOID_R_MIN)
        end
        local th = math.random() * math.pi * 2
        local ph = math.acos(math.clamp(2 * math.random() - 1, -1, 1))
        return Vector3.new(
            r * math.sin(ph) * math.cos(th),
            r * math.cos(ph),
            r * math.sin(ph) * math.sin(th)
        )
    end

    local function parkAtVoid(hrp)
        if not hrp then return false end
        local vp = voidPosition()
        local ok = pcall(function() hrp.CFrame = CFrame.new(vp) end)
        return ok
    end

    local function restoreFromVoid(hrp, savedCF)
        if not hrp or not savedCF then return false end
        local ok = pcall(function()
            hrp.CFrame = savedCF
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        end)
        return ok
    end

    local function fireShot(lf, tgt, fromCF)
        if not (lf and tgt and safeEnums()) then return false end
        local ch = tgt.Character
        if not ch then return false end
        local head = ch:FindFirstChild("HitboxHead") or ch:FindFirstChild("Head")
        local hrp  = ch:FindFirstChild("HumanoidRootPart")
        if not (head and hrp) then return false end
        local it = lf.EquippedItem
        if not it then return false end
        local objectId
        pcall(function() objectId = it:Get("ObjectID") end)
        if not objectId then return false end
        local eyePos = fromCF.Position + Vector3.new(0, EYE_UP_SANE, 0)
        local lead   = calculateLead(ch, eyePos)
        local aimPos = head.Position + lead
        local eyeCF  = CFrame.lookAt(eyePos, aimPos)
        local muzzlePos = eyePos + eyeCF.LookVector * EYE_MUZZLE_SEP
        local muzzleCF  = CFrame.lookAt(muzzlePos, aimPos)
        local objSpace = head.CFrame:ToObjectSpace(CFrame.new(head.Position))
        local K0, K1, K2, K3 = utf8.char(0), utf8.char(1), utf8.char(2), utf8.char(3)
        local data = {
            [K1] = {
                [K0] = Rivals.Util:EncodeCFrame(eyeCF),
                [K1] = Rivals.Util:EncodeCFrame(muzzleCF),
                [K2] = head,
                [K3] = Rivals.Util:EncodeCFrame(objSpace),
            }
        }
        local ok = pcall(function() _useItem:FireServer(objectId, _shootEnum, data, nil) end)
        if ok then State.RageVoidFires = State.RageVoidFires + 1 end
        return ok
    end

    local _knifeProfCache = {}
    local function knifeProfile(tgt)
        if not tgt then return { heavy = false, backstab = false } end
        local c = _knifeProfCache[tgt]
        if c then return c end
        local prof = { heavy = isEnemyKnife(tgt), backstab = Config.RageKnifeBackstab }
        if isKatana(tgt) then prof.heavy = true end
        _knifeProfCache[tgt] = prof
        return prof
    end

    local _orbitAngle = 0
    local _orbitVantage, _orbitVantageUntil = nil, 0

    local function getOrbitVantage(tgt)
        local now = tick()
        if _orbitVantage and now < _orbitVantageUntil then return _orbitVantage end
        if not tgt or not tgt.Character then return nil end
        local hrp = tgt.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return nil end
        _orbitAngle = (_orbitAngle + 0.15) % (math.pi * 2)
        local r = Config.RageCombatOrbitRadius or 60
        local h = Config.RageCombatOrbitHeight or 8
        local tp = hrp.Position
        local jitterY = 0
        if Config.RageCombatOrbitJitter then
            jitterY = math.sin(now * 3.7) * 2
        end
        _orbitVantage = Vector3.new(
            tp.X + math.cos(_orbitAngle) * r,
            tp.Y + h + jitterY,
            tp.Z + math.sin(_orbitAngle) * r
        )
        _orbitVantageUntil = now + (Config.RageOrbitDwell or 0.30)
        return _orbitVantage
    end

    local function polarTick(ch, hrp, tgt)
        if not Config.Rage then return end
        if not (ch and hrp) then return end
        if not Rivals.Ready then return end
        local lf = Rivals.Fighter and Rivals.Fighter.LocalFighter
        if not lf then return end
        if not safeEnums() then return end

        -- Immune handling
        if tgt and isSpawnProtected(tgt) then
            if Config.RageSkipImmune then
                if _immuneTgt ~= tgt then _immuneSince = tick(); _immuneTgt = tgt end
                if tick() - _immuneSince > IMMUNE_MAX_HOLD then
                    State.RageTarget = nil
                    return
                end
                return
            end
        else
            _immuneTgt = nil; _immuneSince = 0
        end

        if not tgt then return end
        if not isValidTarget(tgt, Config.RageVisCheck, true, true) then return end

        local now = tick()
        local mode = Config.RageMode or "Polar"

        -- Save real position
        local savedCF = hrp.CFrame

        -- Forge knife camera angle if needed
        if Config.RageKnifeCamForge then
            local prof = knifeProfile(tgt)
            if prof.heavy then
                local ch2 = tgt.Character
                local hrp2 = ch2 and ch2:FindFirstChild("HumanoidRootPart")
                if hrp2 then
                    local back = hrp2.CFrame.LookVector
                    local backPos = hrp2.Position + back * 3
                    local vp = Camera.CFrame.Position
                    local toBack = (backPos - vp)
                    local vp2 = math.atan2(-toBack.X, -toBack.Z)
                    local vy2 = math.atan2(toBack.Y, Vector2.new(toBack.X, toBack.Z).Magnitude)
                    pcall(function() ViewAngle.forge(vy2, vp2) end)
                end
            end
        end

        -- Determine fire origin
        local fireFrom
        if mode == "Orbit" then
            fireFrom = getOrbitVantage(tgt)
        else
            -- Polar: park at void, fire from there
            fireFrom = voidPosition()
        end

        -- Park
        if fireFrom then
            local parkCF = CFrame.new(fireFrom)
            pcall(function() hrp.CFrame = parkCF end)
            State.RageVoidActive = true
        end

        -- Fire
        State.RageFireFromPos = fireFrom
        State.RageFiring = true
        local taps = math.max(1, math.min(Config.RageTaps or 6, POLAR_TAPS_SANE))
        for i = 1, taps do
            if Config.Rage and tgt and isValidTarget(tgt, false, true, true) then
                local fromCF = CFrame.new(fireFrom or hrp.CFrame.Position)
                pcall(fireShot, lf, tgt, fromCF)
            end
            if i < taps then task.wait() end
        end
        State.RageFiring = false

        -- Restore
        pcall(function()
            hrp.CFrame = savedCF
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        end)
        State.RageVoidActive = false

        -- Weapon recovery
        local it = lf.EquippedItem
        if it then pcall(Rage._weaponRecovery, it) end

        -- Bait pulse (attack translocate)
        if Config.RageAttackTranslocate then
            task.spawn(function()
                task.wait(0.08)
                if lp.Character then
                    local h2 = lp.Character:FindFirstChild("HumanoidRootPart")
                    if h2 then
                        local baitPos = savedCF.Position + Vector3.new(
                            (math.random()-0.5)*6, 0, (math.random()-0.5)*6)
                        pcall(function() h2.CFrame = CFrame.new(baitPos) end)
                        task.wait(0.05)
                        pcall(function() h2.CFrame = savedCF end)
                    end
                end
                State.RageTranslocateBaits = State.RageTranslocateBaits + 1
            end)
        end

        State.RageStatus = "Fired"
    end

    local _hb = nil
    function PolarCore.start()
        if _hb then return end
        _hb = RunService.Heartbeat:Connect(function(dt)
            if not Config.Rage then return end
            local ch  = lp.Character
            local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
            if not (ch and hrp) then return end
            local tgt = State.RageTarget
            polarTick(ch, hrp, tgt)
        end)
    end
    function PolarCore.stop()
        if _hb then _hb:Disconnect(); _hb = nil end
        pcall(ViewAngle.restore)
        State.RageVoidActive = false
        State.RageFiring = false
    end

    Rage._polarCoreStart = PolarCore.start
    Rage._polarCoreStop  = PolarCore.stop
end)()

-- =========================================================
-- HOOK: Gun / Melee / Knife
-- =========================================================
local function getEquippedItem()
    if not Rivals.Ready then return nil end
    local f = Rivals.Fighter and Rivals.Fighter.LocalFighter
    return f and f.EquippedItem or nil
end

function hookGunModule()
    if not Rivals.Ready or not Rivals.Gun then return end
    if shared._JH_GunOrig then pcall(function() Rivals.Gun.StartShooting = shared._JH_GunOrig end) end
    if shared._JH_MeleeOrig and Rivals.Melee then pcall(function() Rivals.Melee.StartShooting = shared._JH_MeleeOrig end) end
    if shared._JH_KnifeOrig and Rivals.Knife then pcall(function() Rivals.Knife.StartAiming = shared._JH_KnifeOrig end) end
    local oldStart = Rivals.Gun.StartShooting
    shared._JH_GunOrig = oldStart
    local hookWrapper = function(self, ...)
        local suppress = (Config.Rage == true and Config.RageDirectFire == true)
        if suppress then
            pcall(function()
                local cf = self.ClientFighter
                if cf and cf.IsLocalPlayer == false then suppress = false end
            end)
        end
        if suppress then return false end
        local results = { oldStart(self, ...) }
        pcall(function()
            if not self.ClientFighter or not self.ClientFighter.IsLocalPlayer then return end
            local camData = results[3]
            if not camData or typeof(camData) ~= "table" then return end
            local camPos = Camera.CFrame.Position
            State.CamPos = camPos
            if Config.Rage then
                if Rage._encodeRageShot(camData) then results[4] = true end
                return
            end
        end)
        return unpack(results)
    end
    if setfenv then pcall(setfenv, hookWrapper, getfenv(oldStart)) end
    if setreadonly then pcall(setreadonly, Rivals.Gun, false) end
    Rivals.Gun.StartShooting = hookWrapper
    local function wrapMeleeAttack(cls, method, saveKey)
        if type(cls) ~= "table" then return end
        local orig = rawget(cls, method)
        if type(orig) ~= "function" then return end
        shared[saveKey] = shared[saveKey] or orig
        if setreadonly then pcall(setreadonly, cls, false) end
        cls[method] = function(selfItem, ...)
            local results = { orig(selfItem, ...) }
            pcall(function()
                if not selfItem.ClientFighter or not selfItem.ClientFighter.IsLocalPlayer then return end
                if not Config.Rage then return end
                local camData = results[3]
                if typeof(camData) ~= "table" then return end
                Rage._encodeRageShot(camData)
            end)
            return unpack(results)
        end
    end
    wrapMeleeAttack(Rivals.Melee, "StartShooting", "_JH_MeleeOrig")
    wrapMeleeAttack(Rivals.Knife, "StartAiming",  "_JH_KnifeOrig")
end
hookGunModule()

-- =========================================================
-- FAKE UNDERGROUND
-- =========================================================
local FU = { on = false, depth = 5.8, walk = true, hide = true, camera = false, orbit = false, noclip = true,
             panic = false, pMin = -5, pMax = 5, pZ = false, anim = true, zeroVel = true,
             virtualCF = nil, saved = nil, track = nil, hb = nil, alive = true,
             rage = false, radius = 14, speed = 4, rate = 0.1, slot = 'Primary', maxDist = 400, team = true,
             ang = 0, target = nil, nextPick = 0, lastShot = 0, localCF = nil, status = nil }
local function hideChar()
    local char = lp.Character; if not char then return end
    FU.saved = {}
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA('BasePart') or part:IsA('Decal') then
            FU.saved[#FU.saved + 1] = { part = part, t = part.Transparency }
            pcall(function() part.Transparency = 1 end)
        end
    end
end
local function showChar()
    if not FU.saved then return end
    for _, d in ipairs(FU.saved) do
        if d.part and d.part.Parent then pcall(function() d.part.Transparency = d.t end) end
    end
    FU.saved = nil
end
local function startAnim()
    local hum = lp.Character and lp.Character:FindFirstChildOfClass('Humanoid')
    if not hum or FU.track then return end
    pcall(function()
        local a = Instance.new('Animation')
        a.AnimationId = 'rbxassetid://10714003221'
        local t = hum:LoadAnimation(a)
        t:Play(0, 1, 0); t.TimePosition = 1.48
        FU.track = t
    end)
end
local function stopAnim()
    if FU.track then pcall(function() FU.track:Stop(); FU.track:Destroy() end); FU.track = nil end
end
local RS_ = game:GetService('ReplicatedStorage')
local mods, modErr = nil, nil
local function getMods()
    if mods then return mods end
    local ok, res = pcall(function()
        return {
            util = require(RS_.Modules.Utility),
            enumLib = require(RS_.Modules.EnumLibrary),
            FC = require(lp.PlayerScripts.Controllers.FighterController),
        }
    end)
    if ok then mods = res; modErr = nil else modErr = tostring(res) end
    return mods
end
local SLOT_IDX = { Primary = 1, Secondary = 2, Melee = 3 }
local function validTargetFU(plr, myPos)
    if plr == lp then return nil end
    if FU.team and plr.Team ~= nil and plr.Team == lp.Team then return nil end
    local ch = plr.Character
    local root = ch and ch:FindFirstChild('HumanoidRootPart')
    local head = ch and ch:FindFirstChild('Head')
    local hum = ch and ch:FindFirstChildOfClass('Humanoid')
    if not (root and head and hum) or hum.Health <= 0 then return nil end
    if root.Position.Y < -500 or root.Position.Y > 2000 then return nil end
    local d = (root.Position - myPos).Magnitude
    if d > FU.maxDist then return nil end
    return root, head, d
end
local function pickTargetFU(myPos)
    local cur = FU.target
    if cur and cur.plr and cur.plr.Parent then
        local root, head = validTargetFU(cur.plr, myPos)
        if root then cur.root, cur.head = root, head; return cur end
    end
    local best, bestD = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        local root, head, d = validTargetFU(plr, myPos)
        if root and d < bestD then bestD = d; best = { plr = plr, root = root, head = head } end
    end
    FU.target = best
    return best
end
local function shootAt(head, fromPos)
    local m = getMods(); if not m then return false end
    local lf = m.FC.LocalFighter; if not lf then return false end
    if lf.EquippedItem == nil then
        pcall(function() lf:EquipItem(SLOT_IDX[FU.slot] or 1) end)
        return false
    end
    local hp = head.Position
    local aimCF = CFrame.lookAt(fromPos + Vector3.new(0, 1.5, 0), hp)
    local objSpace = head.CFrame:ToObjectSpace(CFrame.new(hp))
    local data = {}
    data[utf8.char(1)] = {
        [utf8.char(0)] = m.util:EncodeCFrame(aimCF),
        [utf8.char(1)] = m.util:EncodeCFrame(head.CFrame),
        [utf8.char(2)] = head,
        [utf8.char(3)] = m.util:EncodeCFrame(objSpace),
    }
    return pcall(function()
        RS_.Remotes.Replication.Fighter.UseItem:FireServer(
            lf.EquippedItem:Get('ObjectID'), m.enumLib:ToEnum('StartShooting'), data, nil)
    end)
end
local function turnOffFU()
    FU.on = false; FU.localCF = nil; FU.target = nil
    pcall(function() RunService:UnbindFromRenderStep('FU_OrbitUndo') end)
    if FU.hb then FU.hb:Disconnect(); FU.hb = nil end
    pcall(function() RunService:UnbindFromRenderStep('FU_SurfaceCamera') end)
    showChar(); stopAnim()
    local hrp = lp.Character and lp.Character:FindFirstChild('HumanoidRootPart')
    if hrp and FU.virtualCF then
        pcall(function()
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            hrp.CFrame = FU.virtualCF
        end)
    end
    FU.virtualCF = nil
end
local function turnOnFU()
    FU.on = true
    local hrp = lp.Character and lp.Character:FindFirstChild('HumanoidRootPart')
    if hrp then FU.virtualCF = hrp.CFrame end
    if FU.hide then hideChar() end
    if FU.anim then startAnim() end
    pcall(function() RunService:UnbindFromRenderStep('FU_SurfaceCamera') end)
    RunService:BindToRenderStep('FU_SurfaceCamera', 201, function()
        if FU.on and FU.camera then
            local cam = workspace.CurrentCamera
            if cam and FU.depth > 0 then cam.CFrame = cam.CFrame + Vector3.new(0, FU.depth, 0) end
        end
    end)
    pcall(function() RunService:UnbindFromRenderStep('FU_OrbitUndo') end)
    RunService:BindToRenderStep('FU_OrbitUndo', Enum.RenderPriority.Camera.Value - 1, function()
        if FU.on and FU.localCF then
            local h = lp.Character and lp.Character:FindFirstChild('HumanoidRootPart')
            if h then h.CFrame = FU.localCF end
        end
    end)
    FU.hb = RunService.Heartbeat:Connect(function(dt)
        if not FU.on then return end
        local char = lp.Character
        local hrp2 = char and char:FindFirstChild('HumanoidRootPart')
        local hum = char and char:FindFirstChildOfClass('Humanoid')
        if not hrp2 or not hum then return end
        local cam = workspace.CurrentCamera
        local look = cam and cam.CFrame.LookVector or Vector3.new(0, 0, -1)
        local rot = CFrame.Angles(0, math.atan2(-look.X, -look.Z), 0)
        if not FU.virtualCF then FU.virtualCF = CFrame.new(hrp2.Position) * rot end
        local pos = FU.virtualCF.Position
        if FU.walk and hum.MoveDirection.Magnitude > 0 then
            pos = pos + hum.MoveDirection * (hum.WalkSpeed * dt)
        end
        FU.virtualCF = CFrame.new(pos) * rot
        local under = pos - Vector3.new(0, FU.depth, 0)
        if FU.panic then
            local lo, hi = math.min(FU.pMin, FU.pMax), math.max(FU.pMin, FU.pMax)
            under = under + Vector3.new(lo + math.random() * (hi - lo), 0, FU.pZ and (math.random() - 0.5) * (hi - lo) or 0)
        end
        if FU.noclip then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA('BasePart') and p.CanCollide then p.CanCollide = false end
            end
        end
        if FU.zeroVel then
            hrp2.AssemblyLinearVelocity = Vector3.zero
            hrp2.AssemblyAngularVelocity = Vector3.zero
        end
        local localCF = CFrame.new(under) * rot
        FU.localCF = nil
        if FU.rage then
            local tgt = pickTargetFU(pos)
            if tgt and not FU.orbit then
                FU.localCF = nil; hrp2.CFrame = localCF
                FU.status = 'shooting from under ' .. tostring(tgt.plr.Name)
                if tick() - FU.lastShot >= FU.rate then FU.lastShot = tick(); shootAt(tgt.head, localCF.Position) end
            elseif tgt then
                FU.ang = (FU.ang + FU.speed * dt) % (math.pi * 2)
                local tp = tgt.root.Position
                local orbit = Vector3.new(tp.X + math.cos(FU.ang) * FU.radius, tp.Y - FU.depth, tp.Z + math.sin(FU.ang) * FU.radius)
                local yaw = CFrame.new(orbit) * CFrame.Angles(0, math.atan2(-(tp.X - orbit.X), -(tp.Z - orbit.Z)), 0)
                FU.localCF = localCF; hrp2.CFrame = yaw
                FU.status = 'orbiting ' .. tostring(tgt.plr.Name)
                if tick() - FU.lastShot >= FU.rate then FU.lastShot = tick(); shootAt(tgt.head, orbit) end
            else
                FU.status = 'no target'; hrp2.CFrame = localCF
            end
        else hrp2.CFrame = localCF end
        if FU.hide and FU.saved then
            for _, d in ipairs(FU.saved) do
                if d.part and d.part.Parent and d.part.Transparency ~= 1 then pcall(function() d.part.Transparency = 1 end) end
            end
        end
    end)
end
lp.CharacterAdded:Connect(function()
    if FU.on then task.wait(1); turnOffFU(); turnOnFU() end
end)

-- =========================================================
-- UI SETUP (Rage tab only)
-- =========================================================
Library.IsMobile = isMobile
Library.ShowCustomCursor = true

pcall(function()
    Library.MainColor       = Color3.fromRGB(26, 27, 31)
    Library.BackgroundColor = Color3.fromRGB(17, 18, 21)
    Library.AccentColor     = Color3.fromRGB(96, 165, 250)
    Library.OutlineColor    = Color3.fromRGB(43, 45, 52)
    Library.FontColor       = Color3.fromRGB(239, 241, 245)
end)
local okWin, Window = pcall(function()
    return Library:CreateWindow({ Title='JewHook — Rage', Center=true, AutoShow=true, TabPadding=8,
        MenuFadeTime=0.2, NotifySide='Right', Resizable=true, UnlockMouseWhileOpen=true })
end)
if not okWin or not Window then warn("[JewHook] GUI window failed to build:", Window); return end
local Tabs = {
    Rage     = Window:AddTab('Rage'),
    Settings = Window:AddTab('Settings'),
}

-- =========================================================
-- UI: RAGE
-- =========================================================
do (function()
    local LTB = Tabs.Rage:AddLeftTabbox('Combat')
    local CORE = LTB:AddTab('Core')
    local DEF  = LTB:AddTab('Defense')

    CORE:AddToggle('Rage', { Text='Enable Rage', Default=Config.Rage,
        Callback=function(v) if v then Rage.enable() else Rage.disable() end end })
        :AddKeyPicker('RageToggleKey', { Default='None', Mode='Toggle', SyncToggleState=true, Text='Rage' })
    CORE:AddDropdown('RageMode', { Values={'Polar','Orbit'},
        Default=Config.RageMode, Text='Rage mode',
        Callback=function(v) Config.RageMode = v ; if Config.Rage then Rage.enable() end end })
    CORE:AddDivider('Engine')
    CORE:AddDropdown('RageGumMode', { Values={'off','lite','on'},
        Default=Config.RageGumMode, Text='Gum',
        Callback=function(v) Config.RageGumMode = v end })
    CORE:AddDropdown('RageVoidDepth', { Values={'shallow','deep'},
        Default=Config.RageVoidDepth, Text='Hide depth',
        Callback=function(v) Config.RageVoidDepth = v end })
    CORE:AddToggle('RageGatePoison', { Text='Gate poison', Default=Config.RageGatePoison,
        Callback=function(v) Config.RageGatePoison = v end })
    CORE:AddToggle('RagePredictPrefire', { Text='Prefire resurface', Default=Config.RagePredictPrefire,
        Callback=function(v) Config.RagePredictPrefire = v end })
    CORE:AddDivider('Engagement')
    CORE:AddToggle('RageSkipImmune', { Text='Hold fire on immune', Default=Config.RageSkipImmune,
        Callback=function(v) Config.RageSkipImmune = v end })
    CORE:AddToggle('RageWallbang', { Text='Wallbang (Ignore Walls)', Default=Config.RageWallbang,
        Callback=function(v) Config.RageWallbang = v end })
    CORE:AddToggle('RageWallbangVisCheck', { Text='Wallbang Vis Check Bypass', Default=Config.RageWallbangVisCheck,
        Callback=function(v) Config.RageWallbangVisCheck = v end })
    CORE:AddToggle('RagePrioritizeHackers', { Text='Target cheaters first', Default=Config.RagePrioritizeHackers,
        Callback=function(v) Config.RagePrioritizeHackers = v end })
    local orb = CORE:AddDependencyBox()
    orb:AddSlider('RageCombatOrbitRadius', { Text='Orbit radius', Default=Config.RageCombatOrbitRadius, Min=20, Max=380, Rounding=0,
        Callback=function(v) Config.RageCombatOrbitRadius = v end })
    orb:AddSlider('RageOrbitDwell', { Text='Vantage time', Default=Config.RageOrbitDwell, Min=0.10, Max=0.60, Rounding=2,
        Callback=function(v) Config.RageOrbitDwell = v end })
    orb:AddSlider('RageCombatOrbitHeight', { Text='Orbit height', Default=Config.RageCombatOrbitHeight, Min=0, Max=40, Rounding=0,
        Callback=function(v) Config.RageCombatOrbitHeight = v end })
    orb:AddToggle('RageCombatOrbitJitter', { Text='Vertical jitter', Default=Config.RageCombatOrbitJitter,
        Callback=function(v) Config.RageCombatOrbitJitter = v end })
    orb:AddSlider('RagePBEyeUp', { Text='Eye height', Default=Config.RagePBEyeUp, Min=1, Max=12, Rounding=0,
        Callback=function(v) Config.RagePBEyeUp = v end })
    orb:SetupDependencies({ { Options.RageMode, 'Orbit' } })

    DEF:AddDivider('Bait pulse')
    DEF:AddToggle('RageAttackTranslocate', { Text='Bait Pulse', Default=Config.RageAttackTranslocate,
        Callback=function(v) Config.RageAttackTranslocate = v end })
    DEF:AddDivider('Park transport')
    DEF:AddDropdown('RageRestoreMode', { Values={'auto','none','render','kerp'},
        Default=Config.RageRestoreMode, Text='Park transport',
        Callback=function(v) Config.RageRestoreMode = v end })
    DEF:AddLabel('auto: kerp <-> render on round losses to your target')

    local WEP = Tabs.Rage:AddRightGroupbox('Weapon')
    WEP:AddDivider('On empty magazine')
    WEP:AddDropdown('RageOnEmpty', { Values={'Swap','Reload'},
        Default=Config.RageOnEmpty, Text='Action',
        Callback=function(v) Config.RageOnEmpty = v end })
    WEP:AddDropdown('RagePreferredSlot', { Values={'Primary','Secondary','Melee'},
        Default=Config.RagePreferredSlot, Text='Prefer slot',
        Callback=function(v) Config.RagePreferredSlot = v end })

    local B = Tabs.Rage:AddRightGroupbox('Melee')
    B:AddToggle('AvoidDeflect', { Text='Avoid katana deflect', Default=Config.AvoidDeflect,
        Callback=function(v) Config.AvoidDeflect = v end })
    B:AddToggle('RageShieldBackstab', { Text='Riot shield bypass', Default=Config.RageShieldBackstab,
        Callback=function(v) Config.RageShieldBackstab = v end })
    B:AddToggle('RageKnifeBackstab', { Text='Force knife backstabs', Default=Config.RageKnifeBackstab,
        Callback=function(v) Config.RageKnifeBackstab = v end })

    -- ============ Graviton ragebot ============
    local _Players = game:GetService('Players')
    local _RunService = game:GetService('RunService')
    local _UIS = game:GetService('UserInputService')
    local _RS = game:GetService('ReplicatedStorage')
    local LP = _Players.LocalPlayer
    local GR = { on = false, rate = 0.001, slot = 1, desync = true, void = true, head = true, extra = true,
                 knife = true, equip = true, fov = 9999 }
    local _FC, _SC, _util, _enum, _remote = false, false, false, false, false
    local alive = true

    task.spawn(function()
        for _ = 1, 60 do
            if not alive then return end
            pcall(function()
                if not _util then _util = require(_RS.Modules.Utility) or false end
                if not _enum then _enum = require(_RS.Modules.EnumLibrary) or false end
                if not _FC then _FC = require(LP.PlayerScripts.Controllers.FighterController) or false end
                if not _SC then _SC = require(LP.PlayerScripts.Controllers:WaitForChild('SpectateController', 3)) or false end
                if not _remote then _remote = _RS.Remotes.Replication.Fighter.UseItem end
            end)
            if _util and _enum and _FC and _SC and _remote then break end
            task.wait(0.5)
        end
    end)

    local K0, K1, K2, K3 = utf8.char(0), utf8.char(1), utf8.char(2), utf8.char(3)
    local EYE = Vector3.new(0, 1.5, 0)
    local hb, equipLoop = nil, nil

    local function startEquip()
        if equipLoop then return end
        equipLoop = task.spawn(function()
            while GR.on and alive do
                if _FC and _FC.LocalFighter then pcall(function() _FC.LocalFighter:EquipItem(GR.slot) end) end
                task.wait(1)
            end
            equipLoop = nil
        end)
    end

    local deflecting, deflectAt = {}, 0
    _Players.PlayerRemoving:Connect(function(p) deflecting[p] = nil end)
    local function updateDeflection()
        local now = os.clock()
        if now - deflectAt < 0.1 then return end
        deflectAt = now
        if not _FC or not _FC.Objects then return end
        for _, fo in _FC.Objects do
            local pl = fo.Player
            if pl then
                local entity = fo.Entity
                if not entity or not entity:IsAlive() then
                    deflecting[pl] = false
                else
                    local eq = fo.EquippedItem
                    local vm = eq and eq.ViewModel
                    local d = false
                    if vm and vm.Name == 'Katana' then
                        d = (eq._attack_cooldown and eq._attack_cooldown > tick()) or false
                    end
                    deflecting[pl] = d
                end
            end
        end
    end

    local IMMUNE = { 'IsInvincible', 'Immune', 'IsImmune', 'SpawnProtection' }
    local function isImmune(pl)
        local ch = pl.Character
        if ch then
            if ch:FindFirstChildOfClass('ForceField') then return true end
            for _, a in ipairs(IMMUNE) do if ch:GetAttribute(a) == true then return true end end
        end
        for _, a in ipairs(IMMUNE) do if pl:GetAttribute(a) == true then return true end end
        return false
    end
    local function isEnemy(pl)
        if pl == LP then return false end
        if _SC then
            local ok, res = pcall(function()
                local duel = _SC.CurrentDuelSubject
                local ld = duel and duel:GetDueler(LP)
                local lt = ld and ld:Get('TeamID')
                if lt and duel and duel.Duelers then
                    for _, d in duel.Duelers do
                        if d.Player == pl then return d:Get('TeamID') ~= lt end
                    end
                end
                return nil
            end)
            if ok and res ~= nil then return res end
        end
        local pt, lt = pl:GetAttribute('TeamID'), LP:GetAttribute('TeamID')
        if pt and lt then return pt ~= lt end
        return true
    end
    local function inFov(hrp)
        if GR.fov >= 9999 then return true end
        local cam = workspace.CurrentCamera
        local p3, on = cam:WorldToViewportPoint(hrp.Position)
        if not on then return false end
        return (Vector2.new(p3.X, p3.Y) - _UIS:GetMouseLocation()).Magnitude <= GR.fov
    end
    local function hasKnifeVM(pl)
        local vm = workspace:FindFirstChild('ViewModels')
        if not vm then return false end
        for _, m in ipairs(vm:GetChildren()) do
            if m:IsA('Model') and string.find(m.Name, pl.Name, 1, true) and string.find(m.Name, 'Knife', 1, true) then return true end
        end
        return false
    end
    local ping, pingAt = 0.06, 0
    local function leadPos(hrp)
        if not GR.extra then return hrp.Position end
        local now = os.clock()
        if now - pingAt >= 1 then
            pingAt = now
            pcall(function() ping = math.clamp(LP:GetNetworkPing(), 0, 0.5) end)
        end
        local vel = Vector3.zero
        pcall(function() vel = hrp.AssemblyLinearVelocity end)
        if vel.Magnitude < 0.05 then return hrp.Position end
        local look = (ping * 1.2 + 0.016) * (1 + math.clamp(vel.Magnitude / 40, 0, 1.6) * 0.4)
        return hrp.Position + vel * math.clamp(look, 0, 0.5)
    end
    local function hitbox(ch, head, body)
        local h = ch and ch:FindFirstChild(body and 'HitboxBody' or 'HitboxHead')
        if h and h:IsA('BasePart') then return h end
        return body and (ch:FindFirstChild('HumanoidRootPart') or head) or head
    end
    local pelItem, pelCount = nil, 1
    local function pellets(item)
        if item == pelItem then return pelCount end
        pelItem, pelCount = item, 1
        pcall(function()
            local n = item.Info and item.Info.ShootPellets
            if type(n) == 'number' then pelCount = math.max(1, math.floor(n)) end
        end)
        return pelCount
    end
    local cdItem, cdVal = nil, 0
    local function cooldown(item)
        if item == cdItem then return cdVal end
        cdItem, cdVal = item, 0
        pcall(function()
            local info = item.Info
            if type(info) ~= 'table' then return end
            local cd = tonumber(info.ShootCooldown) or 0
            local burst = tonumber(info.BurstCount) or 1
            local bcd = tonumber(info.BurstCooldown)
            if burst > 1 and bcd then cd = math.min(cd, bcd) end
            cdVal = math.clamp(cd, 0, 5)
        end)
        return cdVal
    end

    local dsRoot, dsCF, dsVel, dsRot, dsBound, dsShown = nil, nil, Vector3.zero, Vector3.zero, false, nil
    local function flush()
        if dsBound then
            dsBound = false
            pcall(function() _RunService:UnbindFromRenderStep('GR_DsRestore') end)
        end
        local root, cf = dsRoot, dsCF
        dsRoot, dsCF, dsShown = nil, nil, nil
        if root and root.Parent and cf then
            pcall(function()
                root.CFrame = cf
                root.AssemblyLinearVelocity = dsVel
                root.AssemblyAngularVelocity = dsRot
            end)
        end
    end
    pcall(function()
        local pre = _RunService.PreSimulation
        if typeof(pre) == 'RBXScriptSignal' then
            pre:Connect(function() if dsBound or dsCF then flush() end end)
        end
    end)
    local function apply(cf)
        local ch = LP.Character
        local root = ch and ch:FindFirstChild('HumanoidRootPart')
        if not root or not root:IsA('BasePart') then return false end
        local keep = dsCF ~= nil and (dsBound or (dsShown and (root.Position - dsShown.Position).Magnitude < 0.2))
        if not keep or dsRoot ~= root then
            dsRoot, dsCF, dsVel, dsRot = root, root.CFrame, root.AssemblyLinearVelocity, root.AssemblyAngularVelocity
        end
        root.CFrame = cf
        dsShown = cf
        if not dsBound then
            dsBound = true
            _RunService:BindToRenderStep('GR_DsRestore', Enum.RenderPriority.Camera.Value - 1, flush)
        end
        return true
    end
    local function voidCF()
        local u, v = math.random(), math.random()
        local th, ph = math.pi * 2 * u, math.acos(math.clamp(2 * v - 1, -1, 1))
        local R = 9000
        return CFrame.lookAt(Vector3.new(R * math.sin(ph) * math.cos(th), R * math.cos(ph), R * math.sin(ph) * math.sin(th)), Vector3.zero)
    end

    local function pickTarget()
        local myChar = LP.Character
        local myHRP = myChar and myChar:FindFirstChild('HumanoidRootPart')
        if not myHRP then return end
        local bp, bh, bhd, bd = nil, nil, nil, math.huge
        for _, pl in ipairs(_Players:GetPlayers()) do
            if isEnemy(pl) and not isImmune(pl) then
                local ch = pl.Character
                local hrp = ch and ch:FindFirstChild('HumanoidRootPart')
                local head = ch and ch:FindFirstChild('Head')
                local hum = ch and ch:FindFirstChildOfClass('Humanoid')
                if hrp and head and hum and hum.Health > 0 and inFov(hrp) then
                    local d = (myHRP.Position - hrp.Position).Magnitude
                    if d < bd then bp, bh, bhd, bd = pl, hrp, head, d end
                end
            end
        end
        return bp, bh, bhd
    end

    local function fire(pl, hrp, head)
        if not (_util and _enum and _FC and _remote) then return end
        if not _FC.LocalFighter then return end
        local item = _FC.LocalFighter.EquippedItem
        if not item then return end
        local objectId
        pcall(function() objectId = item:Get('ObjectID') end)
        if not objectId then return end
        local ch = hrp and hrp.Parent
        if not (ch and head) then return end
        local hum = ch:FindFirstChildOfClass('Humanoid')
        if not hum or hum.Health <= 0 then return end
        if GR.knife and deflecting[pl] then return end
        local part = hitbox(ch, head, not GR.head)
        local aimPos = leadPos(hrp)
        local hitPoint = part.Position
        local dcf
        if hasKnifeVM(pl) then
            dcf = CFrame.lookAt(hrp.Position + Vector3.new(0, -5, 0), aimPos)
        else
            local f = hrp.CFrame.LookVector
            local flat = Vector3.new(f.X, 0, f.Z)
            if flat.Magnitude < 0.05 then flat = Vector3.new(0, 0, -1) end
            dcf = CFrame.lookAt(hrp.Position + flat.Unit + Vector3.new(0, 1, 0), aimPos)
        end
        if GR.desync then apply(dcf) end
        local eye = dcf.Position + EYE
        if (eye - aimPos).Magnitude < 0.1 then eye = aimPos + Vector3.new(0, 0.2, 0) end
        local aimCF = CFrame.lookAt(eye, aimPos)
        local offset = part.CFrame:ToObjectSpace(CFrame.new(hitPoint))
        local eAim, eOff
        if not pcall(function()
            eAim = _util:EncodeCFrame(aimCF)
            eOff = _util:EncodeCFrame(offset)
        end) or not eAim then return end
        local data = { [K1] = { [K0] = eAim, [K1] = eAim, [K2] = part, [K3] = eOff } }
        if pellets(item) > 1 then data[K2] = true end
        local en
        pcall(function() en = _enum:ToEnum('StartShooting') end)
        if not en then return end
        pcall(function() _remote:FireServer(objectId, en, data, nil) end)
    end

    local lastFire = 0
    local function start()
        if hb then hb:Disconnect(); hb = nil end
        if GR.equip then startEquip() end
        hb = _RunService.Heartbeat:Connect(function()
            if not GR.on then return end
            updateDeflection()
            local remaining = lastFire + GR.rate - tick()
            if remaining > 0.002 then
                local item = _FC and _FC.LocalFighter and _FC.LocalFighter.EquippedItem
                local cd = item and cooldown(item) or 0
                if GR.void and cd > 0.05 then apply(voidCF()) end
                return
            end
            local pl, hrp, head = pickTarget()
            if not pl then return end
            lastFire = tick()
            task.spawn(fire, pl, hrp, head)
        end)
    end
    local function stop()
        GR.on = false
        if hb then hb:Disconnect(); hb = nil end
        flush()
    end

    local Bg = Tabs.Rage:AddRightGroupbox('Graviton ragebot')
    Bg:AddToggle('GravRage', { Text = 'Graviton ragebot', Default = false,
        Tooltip = 'Ported from Graviton-9v2. Desyncs next to the closest enemy, fires from there, and restores your position before the camera updates. Do not run it with the other ragebots.',
        Callback = function(v)
            GR.on = v
            if v then start() else stop() end
        end })
        :AddKeyPicker('GravRageKey', { Default = 'None', Mode = 'Toggle', SyncToggleState = true, Text = 'Graviton ragebot' })
    Bg:AddToggle('GravDesync', { Text = 'Desync origin', Default = true, Callback = function(v) GR.desync = v end })
    Bg:AddToggle('GravVoid', { Text = 'Void park (shotgun)', Default = true, Callback = function(v) GR.void = v end })
    Bg:AddToggle('GravHead', { Text = 'Aim head', Default = true, Callback = function(v) GR.head = v end })
    Bg:AddToggle('GravExtra', { Text = 'Extrapolation', Default = true, Callback = function(v) GR.extra = v end })
    Bg:AddToggle('GravKnife', { Text = 'Knife deflect check', Default = true, Callback = function(v) GR.knife = v end })
    Bg:AddToggle('GravEquip', { Text = 'Auto equip slot', Default = true,
        Callback = function(v) GR.equip = v; if v and GR.on then startEquip() end end })
    Bg:AddSlider('GravRate', { Text = 'Fire rate (ms)', Default = 1, Min = 1, Max = 500, Rounding = 0, Suffix = ' ms',
        Callback = function(v) GR.rate = v / 1000 end })
    Bg:AddSlider('GravFov', { Text = 'FOV', Default = 9999, Min = 0, Max = 9999, Rounding = 0, Suffix = ' px',
        Callback = function(v) GR.fov = v end })
    Bg:AddDropdown('GravSlot', { Text = 'Weapon', Values = { 'Primary', 'Secondary', 'Melee' }, Default = 'Primary', Multi = false,
        Callback = function(v) GR.slot = ({ Primary = 1, Secondary = 2, Melee = 3 })[v] or 1 end })
    pcall(function() Library:OnUnload(function() alive = false; stop() end) end)

    -- ============ Elisium Ragebot ============
    local ERB = Tabs.Rage:AddRightGroupbox('Elisium Ragebot')
    ERB:AddToggle('ElisiumRageEnable', {
        Text = 'Enable Elisium Ragebot',
        Default = false,
        Tooltip = 'Desync to enemy position, silent-fire, restore. Disables the built-in Rage when enabled.',
        Callback = function(v) if v then ElisiumRage.Start() else ElisiumRage.Stop() end end,
    }):AddKeyPicker('ElisiumRageKey', { Default = 'None', Mode = 'Toggle', SyncToggleState = true, Text = 'Elisium Ragebot' })
    ERB:AddToggle('ElisiumRageFFA', {
        Text = 'FFA mode (ignore teams)',
        Default = false,
        Callback = function(v) ElisiumRage.Config.FFA = v end,
    })
    ERB:AddDivider('Desync offset')
    ERB:AddSlider('ElisiumRageOffX', { Text = 'Offset X', Default = 0, Min = -20, Max = 20, Rounding = 1, Callback = function(v) ElisiumRage.Config.OffsetX = v end })
    ERB:AddSlider('ElisiumRageOffY', { Text = 'Offset Y', Default = 2, Min = -20, Max = 20, Rounding = 1, Callback = function(v) ElisiumRage.Config.OffsetY = v end })
    ERB:AddSlider('ElisiumRageOffZ', { Text = 'Offset Z', Default = 0, Min = -20, Max = 20, Rounding = 1, Callback = function(v) ElisiumRage.Config.OffsetZ = v end })
    ERB:AddDivider('Prediction')
    ERB:AddToggle('ElisiumRagePred', { Text = 'Lead prediction', Default = true, Callback = function(v) ElisiumRage.Config.Prediction = v end })
    ERB:AddSlider('ElisiumRagePredAmt', { Text = 'Prediction strength', Default = 1, Min = 0, Max = 3, Rounding = 2, Callback = function(v) ElisiumRage.Config.PredictionAmount = v end })
    ERB:AddDivider('Rate limiter')
    ERB:AddSlider('ElisiumRageRate', { Text = 'Extra cooldown (ms)', Default = 0, Min = 0, Max = 500, Rounding = 0, Callback = function(v) ElisiumRage.Config.Rate = v / 1000 end })

    local FUG = Tabs.Rage:AddLeftGroupbox('Fake Underground')
    FUG:AddToggle('FakeUnderground', { Text='Fake Underground', Default=false,
        Tooltip='Holds your character underground while your view stays on the surface.',
        Callback=function(v) if v then turnOnFU() else turnOffFU() end end })
        :AddKeyPicker('FakeUndergroundKey', { Default='None', Mode='Toggle', SyncToggleState=true, Text='Fake Underground' })
    FUG:AddSlider('FUDepth', { Text='Depth', Default=FU.depth, Min=0, Max=150, Rounding=1, Suffix=' studs',
        Callback=function(v) FU.depth = v end })
    FUG:AddToggle('FUWalk', { Text='Walk mode', Default=FU.walk, Callback=function(v) FU.walk = v end })
    FUG:AddToggle('FUCamera', { Text='Surface camera', Default=FU.camera, Callback=function(v) FU.camera = v end })
    FUG:AddToggle('FUNoclip', { Text='Auto noclip', Default=FU.noclip, Callback=function(v) FU.noclip = v end })
    FUG:AddToggle('FUHide', { Text='Hide my character', Default=FU.hide,
        Callback=function(v) FU.hide = v ; if FU.on then if v then hideChar() else showChar() end end end })
    FUG:AddToggle('FUAnim', { Text='Animation desync', Default=FU.anim,
        Callback=function(v) FU.anim = v ; if FU.on then if v then startAnim() else stopAnim() end end end })
    FUG:AddToggle('FUPanic', { Text='Panic jitter', Default=FU.panic, Callback=function(v) FU.panic = v end })
    FUG:AddSlider('FUPanicMin', { Text='Jitter min X', Default=FU.pMin, Min=-50, Max=0, Rounding=0, Callback=function(v) FU.pMin = v end })
    FUG:AddSlider('FUPanicMax', { Text='Jitter max X', Default=FU.pMax, Min=0, Max=50, Rounding=0, Callback=function(v) FU.pMax = v end })
    FUG:AddToggle('FUPanicZ', { Text='Jitter Z too', Default=FU.pZ, Callback=function(v) FU.pZ = v end })
end)() end

-- =========================================================
-- SETTINGS TAB
-- =========================================================
do
    local L = Tabs.Settings:AddLeftGroupbox('Menu')
    L:AddButton({ Text='UNLOAD', DoubleClick=true, Func=function()
        pcall(function() Rage.unload() end)
        pcall(function() if ElisiumRage and ElisiumRage.Unload then ElisiumRage.Unload() end end)
        pcall(function() turnOffFU() end)
        Library:Unload()
    end })
end

-- =========================================================
-- CONFIGS + FINAL INIT
-- =========================================================
do
    ThemeManager:SetLibrary(Library)
    SaveManager:SetLibrary(Library)
    SaveManager:IgnoreThemeSettings()
    SaveManager:SetIgnoreIndexes({ 'MenuKeybind',
        'ElisiumRageEnable', 'ElisiumRageKey', 'ElisiumRageFFA',
        'ElisiumRageOffX', 'ElisiumRageOffY', 'ElisiumRageOffZ',
        'ElisiumRagePred', 'ElisiumRagePredAmt', 'ElisiumRageRate' })
    ThemeManager:SetFolder('JewHook')
    SaveManager:SetFolder('JewHook/configs')
    SaveManager:BuildConfigSection(Tabs.Settings)
    ThemeManager:ApplyToTab(Tabs.Settings)
    pcall(function() SaveManager:LoadAutoloadConfig() end)
end

pcall(Rage.init)

local _origUnload = Library.Unload
Library.Unload = function(self, ...)
    pcall(function()
        if shared._JH_GunOrig and Rivals.Gun then
            if setreadonly then pcall(setreadonly, Rivals.Gun, false) end
            Rivals.Gun.StartShooting = shared._JH_GunOrig
        end
        shared._JH_GunOrig = nil
        if shared._JH_KatanaMod and shared._JH_KatanaDeflOrig then
            if setreadonly then pcall(setreadonly, shared._JH_KatanaMod, false) end
            shared._JH_KatanaMod._StartDeflecting = shared._JH_KatanaDeflOrig
        end
        shared._JH_KatanaMod, shared._JH_KatanaDeflOrig = nil, nil
    end)
    pcall(function() if ElisiumRage and ElisiumRage.Unload then ElisiumRage.Unload() end end)
    pcall(ViewAngle.restore)
    return _origUnload(self, ...)
end

_G["\74\72"] = Library
pcall(function() Library:SetWatermark('JewHook Rage v1') end)
pcall(function() Library:SetWatermarkVisibility(false) end)
Library:Notify('JewHook Rage tab loaded (polar + graviton + elisium + fake underground)', 4)
