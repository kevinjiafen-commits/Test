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
-- CONFIG
-- =========================================================
local Config = {
    -- Silent Aim
    SilentAim = false, SilentAimVisCheck = false, SilentAimJitter = true,
    SilentAimTargetPart = "Head", SilentAimFOV = 250, AvoidDeflect = true,
    SilentAimStickiness = 0.05, SilentAimMultipoint = false,
    SilentAimMultipointCount = 5, SilentAimTorsoFallback = false,
    SilentAimHitChance = 85, SilentAimBodyMix = 25, SilentAimJitterDeg = 1.5,
    -- Aimbot
    Aimbot = false, AimbotVisCheck = true, AimbotKey = "MB2",
    AimbotSmoothness = 0, AimbotSmoothnessX = 0, AimbotSmoothnessY = 0,
    AimbotLinkAxes = true, AimbotJumpDamping = 40, AimbotCancelSprings = true,
    AimbotCurvedFlick = false, AimbotCurvedIntensity = 0.35, AimbotTrackAssist = 100,
    AimbotFOVDeg = 20, AimbotMaxSpeed = 0, AimbotDeadzoneDeg = 0, AimbotSwitchDeg = 2,
    AimbotStickiness = 0.15, AimbotForgetTime = 0.2, AimbotTargetPart = "Best",
    AimbotPriority = "Crosshair", AimbotSkipImmune = true, AimbotPrediction = false,
    AimbotShotOverride = false, AimbotShowFOV = false, AimbotShowLock = false,
    AimbotDebug = false, AimbotReactionMs = 0, AimbotNoiseDeg = 0, AimbotOvershoot = 0,
    AimbotDirectCamera = false,
    -- Triggerbot
    Trigger = false, TriggerKey = "Always", TriggerHeadOnly = false,
    TriggerScopeCheck = false, TriggerDelayMs = 0, TriggerRefireMs = 0, TriggerMaxDist = 400,
    -- Shared targeting
    MaxDistance = 1200, TeamCheck = true, PredictiveLead = true, LeadCap = 15,
    ServerProcessingMs = 30, ProjectileLead = false, ProjectileSpeed = 300,
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
    -- ESP
    ESP = false, ESPTeamCheck = true, ESPMaxDistance = 1200, ESPMaxPlayers = 0,
    ESPFont = "Code", ESPTextSize = 14, ESPInfoTextSize = 12, ESPHealthTextSize = 11,
    ESPTextScale = 1, ESPTextCasing = 1, ESPDistanceScaling = true,
    ESPDistanceScalingRef = 50, ESPCasingThickness = 1, ESPBoxScale = 1,
    ESPBox = true, ESPBoxStyle = "Full Box", ESPBoxBrackets = false,
    ESPCornerLength = 0.28, ESPBoxFill = false, ESPBoxThickness = 1,
    ESPName = true, ESPDistance = true, ESPWeapon = false, ESPHealth = true,
    ESPHealthNumberMode = "OnDamage", ESPSkeleton = false, ESPSkeletonThickness = 1,
    ESPChams = false, ESPTracers = false, ESPTracerThickness = 1, ESPTracerOrigin = "Bottom",
    ESPArrows = false, ESPFlagStaring = false, ESPFlagDeflect = true,
    ESPFlagShield = true, ESPFlagInvincible = true, ESPFlagLowHP = true,
    ESPHeadDot = false, ESPHeadDotSize = 4,
    ESPBoxColorMode = "Solid", ESPBoxColor = Color3.fromRGB(255, 255, 255),
    ESPBoxGradA = Color3.fromRGB(255, 59, 78), ESPBoxGradB = Color3.fromRGB(255, 194, 75),
    ESPBoxFillColor = Color3.fromRGB(255, 59, 78),
    ESPHealthColorMode = "Ramp", ESPHealthColor = Color3.fromRGB(61, 224, 122),
    ESPHealthGradA = Color3.fromRGB(255, 68, 54), ESPHealthGradB = Color3.fromRGB(61, 224, 122),
    ESPNameColorMode = "Solid", ESPNameColor = Color3.fromRGB(255, 255, 255),
    ESPNameGradA = Color3.fromRGB(255, 255, 255), ESPNameGradB = Color3.fromRGB(255, 194, 75),
    ESPInfoColorMode = "Solid", ESPInfoColor = Color3.fromRGB(255, 255, 255),
    ESPInfoGradA = Color3.fromRGB(255, 255, 255), ESPInfoGradB = Color3.fromRGB(255, 158, 75),
    ESPFlagColorMode = "PerFlag", ESPFlagColor = Color3.fromRGB(255, 194, 75),
    ESPFlagGradA = Color3.fromRGB(255, 194, 75), ESPFlagGradB = Color3.fromRGB(255, 70, 85),
    ESPSkeletonColorMode = "Solid", ESPSkeletonColor = Color3.fromRGB(255, 255, 255),
    ESPSkeletonGradA = Color3.fromRGB(255, 255, 255), ESPSkeletonGradB = Color3.fromRGB(120, 180, 255),
    ESPTracerColorMode = "Solid", ESPTracerColor = Color3.fromRGB(255, 255, 255),
    ESPTracerGradA = Color3.fromRGB(255, 255, 255), ESPTracerGradB = Color3.fromRGB(255, 59, 78),
    ESPMarkColorMode = "Solid", ESPMarkColor = Color3.fromRGB(255, 255, 255),
    ESPMarkGradA = Color3.fromRGB(255, 255, 255), ESPMarkGradB = Color3.fromRGB(255, 194, 75),
    ESPGradientSpeed = 0, ESPGradientRotBox = 0, ESPGradientRotText = 90,
    ESPHeadDotColor = Color3.fromRGB(255, 255, 255),
    ESPChamsFillColor = Color3.fromRGB(255, 59, 78),
    ESPChamsOutlineColor = Color3.fromRGB(255, 255, 255),
    ColorEnemy = Color3.fromRGB(255, 59, 78), ColorTeam = Color3.fromRGB(53, 215, 199),
    ColorEnemyOcc = Color3.fromRGB(168, 85, 96), ColorTeamOcc = Color3.fromRGB(92, 153, 147),
    ColorVisible = Color3.fromRGB(41, 224, 255),
    ESPDistNearColor = Color3.fromRGB(80, 255, 140), ESPDistFarColor = Color3.fromRGB(255, 70, 90),
    ESPBoxTransparency = 0, ESPBoxFillTransparency = 0.75, ESPNameTransparency = 0,
    ESPHealthTransparency = 0.1, ESPSkeletonTransparency = 0.2,
    ESPTracerTransparency = 0.35, ESPHeadDotTransparency = 0,
    ESPChamsFillTransparency = 0.6, ESPChamsOutlineTransparency = 0,
    ESPChamsStyle = "Shade", ESPNameMode = "Display", ESPFadeIn = true,
    ESPLookLine = false, ESPLookLineLength = 8, ESPHealthSmooth = true,
    ESPHealthGhost = true, ESPDeclutter = true, ESPChamsVisSplit = true,
    ESPAmmoBar = false, ESPHealthNumber = true,
    -- GameVisuals (Cosmetics)
    GameVisuals = false, GVUnlockAll = true, GVUnlockWeapons = false, GVWrapInverted = false,
    GVEveryone = false, GVBirthHook = true, GVFinisherClone = true, GVRemember = true,
    GVRankCharmOn = false, GVRankCharmRank = "", GVRankCharmLb = 0, GVEmotes = false,
    -- Spoofer
    SpooferNameEnabled = false, SpooferName = "ProPlayer", SpooferDisplayName = "ProPlayer",
    SpooferLevelEnabled = false, SpooferLevel = 100,
    SpooferCasualWinsEnabled = false, SpooferCasualWins = 500,
    SpooferRankedWinsEnabled = false, SpooferRankedWins = 250,
    SpooferRankedEloEnabled = false, SpooferRankedElo = 2400,
    SpooferWinPercentEnabled = false, SpooferWinPercent = 75,
    SpooferWinStreakEnabled = false, SpooferWinStreak = 25,
    SpooferFavoriteMapEnabled = false, SpooferFavoriteMap = "Arena",
    -- World / Environment
    WeatherEnabled = false, WeatherType = "snow", WeatherColor = Color3.fromRGB(255, 255, 255), WeatherRate = 100,
    AtmoEnabled = false, AtmoDensity = 0.3, AtmoOffset = 0.25, AtmoColor = Color3.fromRGB(199, 199, 199), AtmoDecay = Color3.fromRGB(106, 112, 125), AtmoGlare = 0.5, AtmoHaze = 0,
    CCEnabled = false, CCSaturation = 0, CCContrast = 0, CCTint = Color3.fromRGB(255, 255, 255),
    FOVEnabled = false, FOVValue = 80, StretchedResEnabled = false, StretchedResAmount = 0.2,
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
local function hpRamp(frac)
    local stops = {
        { 0.00, Color3.fromRGB(255, 68, 54) }, { 0.20, Color3.fromRGB(255, 122, 61) },
        { 0.40, Color3.fromRGB(255, 194, 75) }, { 0.60, Color3.fromRGB(196, 226, 78) },
        { 1.00, Color3.fromRGB(61, 224, 122) },
    }
    frac = math.clamp(frac or 0, 0, 1)
    for i = 1, #stops - 1 do
        local a, b = stops[i], stops[i + 1]
        if frac <= b[1] then
            local t = (frac - a[1]) / (b[1] - a[1])
            return a[2]:Lerp(b[2], math.clamp(t, 0, 1))
        end
    end
    return stops[#stops][2]
end

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
        if not (Config.Aimbot or Config.SilentAim or Config.Rage) then return end
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

local function selectTarget(opts)
    opts = opts or {}
    local fov         = opts.fov or 90
    local checkVis    = opts.checkVis or false
    local mode        = opts.partMode or "Head"
    local sticky      = opts.stickyTarget
    local stickyBonus = opts.stickyBonus or 0
    local vp     = Camera.ViewportSize
    local center = Vector2.new(vp.X * 0.5, vp.Y * 0.5)
    local best, bestPart, bestScore = nil, nil, math.huge
    for _, player in ipairs(getSafePlayers()) do
        if player ~= lp and isValidTarget(player, false) then
            local char = player.Character
            local part = pickPart(char, mode)
            if part and (not checkVis or isVisible(part.Position)) then
                local sp, on = Camera:WorldToViewportPoint(part.Position)
                if on and sp.Z > 0 then
                    local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                    if d <= fov then
                        local score = d
                        if player == sticky then score = score * (1 - stickyBonus) end
                        if score < bestScore then bestScore, best, bestPart = score, player, part end
                    end
                end
            end
        end
    end
    return best, bestPart
end

local function isMouseButtonDown()
    if isMobile then return true end
    return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
end
local function isInputActive(key)
    if key == "MB1" then return isMouseButtonDown() end
    if key == "MB2" then
        if isMobile then return true end
        return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    end
    if key == "Always" then return true end
    local kc = Enum.KeyCode[key]
    if kc and not isMobile then return UserInputService:IsKeyDown(kc) end
    return false
end

local function silentPartVisible(part)
    if not part or not part:IsA("BasePart") then return false end
    if not Config.SilentAimMultipoint then return isVisible(part.Position) end
    if isVisible(part.Position) then return true end
    local n = math.max(1, math.floor(Config.SilentAimMultipointCount or 5))
    local r = math.min(part.Size.X, part.Size.Y, part.Size.Z) * 0.4
    for i = 1, n do
        local a   = (i / n) * math.pi * 2
        local off = Vector3.new(math.cos(a) * r, ((i % 2 == 0) and 0.5 or -0.5) * r, math.sin(a) * r)
        if isVisible(part.Position + off) then return true end
    end
    return false
end
local function pickSilentPart(char, primary)
    if not char then return primary end
    if silentPartVisible(primary) then return primary end
    for _, name in ipairs(HEAD_PARTS) do
        local p = char:FindFirstChild(name)
        if p and p ~= primary and silentPartVisible(p) then return p end
    end
    if Config.SilentAimTorsoFallback then
        for _, name in ipairs(TORSO_PARTS) do
            local p = char:FindFirstChild(name)
            if p and silentPartVisible(p) then return p end
        end
    end
    return primary
end

-- =========================================================
-- VISUALS (Stub + Spoofer)
-- =========================================================
local Visuals = {}
Visuals.notifyTarget = function() end
Visuals.worldSpark = function() end
Visuals.FX = { onHit = function() end, onIncoming = function() end }
Visuals.refreshViewModel = function() end

;(function()
    local _spooferActive = false
    local _spooferConns = {}
    local _isSpoofing = {}
    local _origText = {}
    local function anySpoofOn()
        return Config.SpooferNameEnabled or Config.SpooferLevelEnabled or Config.SpooferCasualWinsEnabled
            or Config.SpooferRankedWinsEnabled or Config.SpooferRankedEloEnabled
            or Config.SpooferWinPercentEnabled or Config.SpooferWinStreakEnabled
            or Config.SpooferFavoriteMapEnabled
    end
    local function escPat(s) return (s:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")) end
    local function escRep(s) return (s:gsub("%%", "%%%%")) end
    local function belongsToLp(obj)
        local node, depth = obj, 0
        while node ~= nil and node ~= game and depth < 12 do
            if node:IsA("BillboardGui") then
                local anchor = node.Adornee or node.Parent
                while anchor ~= nil and not anchor:IsA("Model") do anchor = anchor.Parent end
                if anchor ~= nil then
                    local plr = Players:GetPlayerFromCharacter(anchor)
                    if plr ~= nil then return plr == lp end
                end
            elseif node:IsA("Model") then
                local plr = Players:GetPlayerFromCharacter(node)
                if plr ~= nil then return plr == lp end
            end
            local asId = tonumber(node.Name)
            if asId ~= nil and Players:GetPlayerByUserId(asId) ~= nil then return asId == lp.UserId end
            node = node.Parent; depth = depth + 1
        end
        return true
    end
    local ALLOWED_TEXT_NAMES = {
        DisplayName = true, Username = true, Name = true, Handle = true, Nametag = true,
        Title = true, TitleText = true, Value = true, Text = true, Label = true,
        Wins = true, WinRate = true, Streak = true, WinStreak = true, ELO = true, Level = true,
    }
    local function applyTextSpoof(obj)
        if not (obj and obj.Parent) then return end
        if _isSpoofing[obj] then return end
        local text = obj.Text
        if not text or #text == 0 then return end
        local newText = text
        local changed = false
        if Config.SpooferNameEnabled then
            local fakeName = Config.SpooferName or "ProPlayer"
            local fakeDisp = Config.SpooferDisplayName or fakeName
            local realName = lp.Name
            local realDisp = lp.DisplayName
            if realDisp and #realDisp > 0 and newText:find(realDisp, 1, true) then
                newText = newText:gsub(escPat(realDisp), escRep(fakeDisp))
                changed = true
            end
            if realName and #realName > 0 and newText:find(realName, 1, true) then
                newText = newText:gsub(escPat(realName), escRep(fakeName))
                changed = true
            end
        end
        local pn = obj.Parent and obj.Parent.Name or ""
        local on = obj.Name
        local isVal = (on == "Value" or on == "Text")
        local is_level = (pn == "Level" or pn == "LevelContainer") and (isVal or on == "Level")
        local is_wins = (on == "Wins" or pn == "Wins" or pn == "WinsContainer") and (isVal or on == "Wins")
        local is_elo = (pn == "ELO" or pn == "RankedElo" or pn == "Rating" or pn == "Rank") and (isVal or on == "ELO")
        local is_winrate = (on == "WinRate" or on == "win rate" or pn == "WinRate") and (isVal or on == "WinRate")
        local is_streak = (pn == "Streak" or pn == "WinStreak" or pn == "StreakContainer" or on == "Streak" or on == "WinStreak")
            and (isVal or on == "Streak" or on == "WinStreak")
        if (is_level or is_wins or is_elo or is_winrate or is_streak) and belongsToLp(obj) then
            local sVal = nil
            if Config.SpooferLevelEnabled and is_level then sVal = tostring(Config.SpooferLevel or 100)
            elseif Config.SpooferCasualWinsEnabled and is_wins then sVal = tostring(Config.SpooferCasualWins or 500)
            elseif Config.SpooferRankedEloEnabled and is_elo then sVal = tostring(Config.SpooferRankedElo or 2400)
            elseif Config.SpooferWinPercentEnabled and is_winrate then sVal = tostring(Config.SpooferWinPercent or 75) .. "%"
            elseif Config.SpooferWinStreakEnabled and is_streak then sVal = tostring(Config.SpooferWinStreak or 25)
            end
            if sVal ~= nil and newText ~= sVal then newText = sVal; changed = true end
        end
        if changed and newText ~= text then
            if _origText[obj] == nil then _origText[obj] = text end
            _isSpoofing[obj] = true
            pcall(function() obj.Text = newText end)
            _isSpoofing[obj] = nil
        end
    end
    local function registerTextObj(obj)
        if not (obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox")) then return end
        if _spooferConns[obj] ~= nil then return end
        local txt = nil
        pcall(function() txt = obj.Text end)
        local mine = type(txt) == "string" and #txt > 0
            and ((#lp.Name > 0 and txt:find(lp.Name, 1, true) ~= nil)
              or (#lp.DisplayName > 0 and txt:find(lp.DisplayName, 1, true) ~= nil))
        if not ALLOWED_TEXT_NAMES[obj.Name] and not mine then return end
        applyTextSpoof(obj)
        _spooferConns[obj] = obj:GetPropertyChangedSignal("Text"):Connect(function() applyTextSpoof(obj) end)
        obj.Destroying:Once(function()
            local c = _spooferConns[obj]
            if c ~= nil then pcall(function() c:Disconnect() end) end
            _spooferConns[obj] = nil; _origText[obj] = nil; _isSpoofing[obj] = nil
        end)
    end
    local function stopGuiNameSpoofer()
        for k, c in pairs(_spooferConns) do
            pcall(function() c:Disconnect() end)
            _spooferConns[k] = nil
        end
        for obj, t in pairs(_origText) do
            pcall(function()
                if obj.Parent ~= nil then
                    _isSpoofing[obj] = true; obj.Text = t; _isSpoofing[obj] = nil
                end
            end)
            _origText[obj] = nil
        end
        _isSpoofing = {}
        _spooferActive = false
    end
    local function startGuiNameSpoofer()
        if _spooferActive or not anySpoofOn() then return end
        _spooferActive = true
        local pGui = lp:FindFirstChildOfClass("PlayerGui")
        if pGui then
            for _, inst in ipairs(pGui:GetDescendants()) do registerTextObj(inst) end
            _spooferConns["pGuiDesc"] = pGui.DescendantAdded:Connect(registerTextObj)
        end
        pcall(function()
            local cGui = cloneref(game:GetService("CoreGui"))
            if cGui then
                for _, inst in ipairs(cGui:GetDescendants()) do registerTextObj(inst) end
                _spooferConns["cGuiDesc"] = cGui.DescendantAdded:Connect(registerTextObj)
            end
        end)
        if Config.SpooferNameEnabled then
            _spooferConns["wsDesc"] = Workspace.DescendantAdded:Connect(function(inst)
                if inst:IsA("BillboardGui") or inst:IsA("SurfaceGui") then
                    for _, child in ipairs(inst:GetDescendants()) do registerTextObj(child) end
                    if _spooferConns[inst] == nil then
                        _spooferConns[inst] = inst.DescendantAdded:Connect(registerTextObj)
                    end
                end
            end)
        end
    end
    local function refreshGuiNameSpoofer()
        if not anySpoofOn() then stopGuiNameSpoofer(); return end
        if not _spooferActive then startGuiNameSpoofer(); return end
        for obj in pairs(_spooferConns) do
            if typeof(obj) == "Instance" then pcall(applyTextSpoof, obj) end
        end
    end
    local _pinnedAttrs = {}
    local _pinConns = {}
    local function pinAttr(attrName, val)
        _pinnedAttrs[attrName] = val
        if not _pinConns[attrName] then
            _pinConns[attrName] = lp:GetAttributeChangedSignal(attrName):Connect(function()
                local targetVal = _pinnedAttrs[attrName]
                if targetVal ~= nil and lp:GetAttribute(attrName) ~= targetVal then
                    pcall(function() lp:SetAttribute(attrName, targetVal) end)
                end
            end)
        end
        pcall(function() lp:SetAttribute(attrName, val) end)
    end
    local function unpinAttr(attrName)
        _pinnedAttrs[attrName] = nil
        if _pinConns[attrName] then
            _pinConns[attrName]:Disconnect()
            _pinConns[attrName] = nil
        end
    end
    local function unpinAll()
        local names = {}
        for k in pairs(_pinConns) do names[#names + 1] = k end
        for _, k in ipairs(names) do unpinAttr(k) end
    end
    local function updatePlayerSpoofer()
        if not anySpoofOn() then unpinAll(); return end
        pcall(function()
            local PDC = Rivals and Rivals.PlayerDataController
            if not PDC then
                pcall(function()
                    local scr = lp:FindFirstChild("PlayerScripts")
                    local ctrls = scr and scr:FindFirstChild("Controllers")
                    local pdcMod = ctrls and ctrls:FindFirstChild("PlayerDataController")
                    if pdcMod then PDC = require(pdcMod) end
                end)
            end
            local cData = PDC and PDC.CurrentData and PDC.CurrentData.Data
            local sLev = tonumber(Config.SpooferLevel) or 100
            local sElo = tonumber(Config.SpooferRankedElo) or 2400
            local sCWins = tonumber(Config.SpooferCasualWins) or 500
            local sRWins = tonumber(Config.SpooferRankedWins) or 250
            local sWP = (tonumber(Config.SpooferWinPercent) or 75) / 100
            local sStreak = tonumber(Config.SpooferWinStreak) or 25
            local sMap = tostring(Config.SpooferFavoriteMap or "Arena")
            if Config.SpooferLevelEnabled then
                pinAttr("Level", sLev)
                if cData then cData.Level = sLev end
            else unpinAttr("Level") end
            if Config.SpooferRankedEloEnabled then
                pinAttr("DisplayELO", sElo); pinAttr("RankedCurrentELO", sElo)
                if cData then
                    cData.RankedCurrentELO = sElo
                    if cData.Seasons then
                        for _, season in pairs(cData.Seasons) do
                            if season.RankedPerformances then
                                for _, perf in pairs(season.RankedPerformances) do
                                    perf.CurrentELO = sElo
                                end
                            end
                        end
                    end
                end
            else
                unpinAttr("DisplayELO"); unpinAttr("RankedCurrentELO")
            end
            if Config.SpooferCasualWinsEnabled then
                pinAttr("CasualWins", sCWins); pinAttr("StatisticDuelsWins", sCWins)
                if cData then cData.CasualWins = sCWins end
            else
                unpinAttr("CasualWins"); unpinAttr("StatisticDuelsWins")
            end
            if Config.SpooferRankedWinsEnabled then
                pinAttr("RankedWins", sRWins)
                if cData then cData.RankedWins = sRWins end
            else unpinAttr("RankedWins") end
            if Config.SpooferWinPercentEnabled then
                pinAttr("CasualWinPercent", sWP); pinAttr("RankedWinPercent", sWP)
                pinAttr("StatisticDuelsWinRate", sWP * 100); pinAttr("WinRate", sWP * 100)
                if cData then cData.CasualWinPercent = sWP; cData.RankedWinPercent = sWP end
            else
                unpinAttr("CasualWinPercent"); unpinAttr("RankedWinPercent")
                unpinAttr("StatisticDuelsWinRate"); unpinAttr("WinRate")
            end
            if Config.SpooferWinStreakEnabled then
                pinAttr("StatisticDuelsWinStreak", sStreak); pinAttr("WinStreak", sStreak)
                pinAttr("CurrentWinStreak", sStreak)
                if cData then
                    cData.StatisticDuelsWinStreak = sStreak
                    cData.WinStreak = sStreak
                    cData.CurrentWinStreak = sStreak
                end
            else
                unpinAttr("StatisticDuelsWinStreak"); unpinAttr("WinStreak"); unpinAttr("CurrentWinStreak")
            end
            if Config.SpooferFavoriteMapEnabled then
                pinAttr("FavoriteMap", sMap)
                if cData then cData.FavoriteMap = sMap end
            else unpinAttr("FavoriteMap") end
        end)
    end
    Visuals.applyGuiNameSpoof = refreshGuiNameSpoofer
    Visuals.updatePlayerSpoofer = updatePlayerSpoofer
    function Visuals.initSpoofer()
        updatePlayerSpoofer()
        refreshGuiNameSpoofer()
    end
end)()

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
    local _tgtConn = nil
    local function bump(p) State.RageCharTokens[p] = (State.RageCharTokens[p] or 0) + 1 end
    local function killFloor() return workspace.FallenPartsDestroyHeight + Config.RageKillPlaneBuffer end
    local function hasLOS(fromPos, toPos, ignore)
        local rp = RaycastParams.new()
        rp.FilterType = Enum.RaycastFilterType.Exclude
        rp.FilterDescendantsInstances = ignore
        local res = workspace:Raycast(fromPos, toPos - fromPos, rp)
        if not res then return true end
        return (res.Position - toPos).Magnitude < 3
    end
    local function lookCF(fromPos, toPos)
        local dir = toPos - fromPos
        if dir.Magnitude < 1e-4 then dir = Vector3.new(0, -1, 0) end
        local up = Vector3.new(0, 1, 0)
        if math.abs(dir.Unit.Y) > 0.999 then up = Vector3.new(0, 0, 1) end
        return CFrame.lookAt(fromPos, fromPos + dir, up)
    end
    Rage._lookCF = lookCF
    local function buildShotFields(camData, eyeCF, muzzleCF, hitPart, aimWorldPos, jitter, clampFrac, jitterFrac)
        local objSpace = hitPart.CFrame:PointToObjectSpace(aimWorldPos)
        local hs = hitPart.Size * (clampFrac or 0.45)
        objSpace = Vector3.new(math.clamp(objSpace.X, -hs.X, hs.X),
            math.clamp(objSpace.Y, -hs.Y, hs.Y), math.clamp(objSpace.Z, -hs.Z, hs.Z))
        if jitter then
            local jf = jitterFrac or 1.0
            objSpace = Vector3.new(
                math.clamp(objSpace.X + (math.random() - 0.5) * hs.X * jf, -hs.X, hs.X),
                math.clamp(objSpace.Y + (math.random() - 0.5) * hs.Y * jf, -hs.Y, hs.Y),
                math.clamp(objSpace.Z + (math.random() - 0.5) * hs.Z * jf, -hs.Z, hs.Z))
        end
        local hitWorld = hitPart.CFrame:PointToWorldSpace(objSpace)
        local objSpaceCF = hitPart.CFrame:ToObjectSpace(CFrame.new(hitWorld))
        camData[utf8.char(0)] = Rivals.Util:EncodeCFrame(eyeCF)
        camData[utf8.char(1)] = Rivals.Util:EncodeCFrame(muzzleCF)
        camData[utf8.char(2)] = hitPart
        camData[utf8.char(3)] = Rivals.Util:EncodeCFrame(objSpaceCF)
    end
    Rage._buildShotFields = buildShotFields
    local RAGE_CLAMP_FRAC, RAGE_JITTER_FRAC = 0.30, 1.0
    local function encodeShot(camData, hitPart, targetChar, fromCamPos, claimOffset)
        if not hitPart or not camData or not Rivals.Util then return false end
        local lead = calculateLead(targetChar, fromCamPos)
        local off  = (typeof(claimOffset) == "Vector3") and claimOffset or Vector3.zero
        local leadedPos = hitPart.Position + lead + off
        local eyeCF = lookCF(fromCamPos, leadedPos)
        local muzzlePos = fromCamPos + (eyeCF.RightVector * 0.2) + Vector3.new(0, -Config.RageEyeMuzzleSep, 0)
        local muzzleCF = lookCF(muzzlePos, leadedPos)
        buildShotFields(camData, eyeCF, muzzleCF, hitPart, leadedPos, Config.SilentAimJitter, 0.45, 1.0)
        return true
    end
    Rage._encodeShot = encodeShot
    local PICK_SLOT = { Primary = 1, Secondary = 2, Melee = 3 }
    ;(function()
        local function fighterItems() local lf = Rivals.Fighter and Rivals.Fighter.LocalFighter; return lf and lf.Items or nil end
        local function itemIsMelee(item)
            if not item then return false end
            local viaInfo = false
            pcall(function()
                local info = item.Info
                if info == nil then return end
                if info.Type == "Melee" or info.Class == "Melee" then viaInfo = true return end
                if type(info.AttackReach) == "number" and info.MaxAmmo == nil then viaInfo = true end
            end)
            if viaInfo then return true end
            local okN, nm = pcall(function() return item:Get("Name") or item.Name end)
            if okN and type(nm) == "string" and nm:lower():find("melee", 1, true) then return true end
            return false
        end
        Rage._itemIsMelee = itemIsMelee
        local function itemAmmo(item)
            if not item then return nil end
            local ok, a = pcall(function() return item:Get("Ammo") or item:Get("CurrentAmmo") end)
            if ok and type(a) == "number" then return a end
            return nil
        end
        local function slotItemByIndex(idx)
            local items = fighterItems(); if not items then return nil end
            if items[idx] then return items[idx] end
            if items[tostring(idx)] then return items[tostring(idx)] end
            return nil
        end
        local function whichSlotNow()
            local cur = getEquippedItem(); if not cur then return nil end
            local okId, oid = pcall(function() return cur:Get("ObjectID") end)
            if okId and oid then
                for idx = 1, 3 do
                    local it = slotItemByIndex(idx)
                    if it then
                        local okI, iid = pcall(function() return it:Get("ObjectID") end)
                        if okI and iid == oid then return idx end
                    end
                end
            end
            if itemIsMelee(cur) then return 3 end
            return nil
        end
        local function slotUsable(idx)
            local it = slotItemByIndex(idx); if not it then return false end
            if itemIsMelee(it) then return Config.RageSwitchMelee == true end
            local a = itemAmmo(it)
            return a == nil or a > 0
        end
        local function slotOrder()
            local pref = PICK_SLOT[Config.RageWeaponPick] or 1
            local order = { pref }
            for _, s in ipairs({ 1, 2, 3 }) do if s ~= pref then order[#order + 1] = s end end
            if not Config.RageSwitchMelee then
                local filtered = {}
                for _, s in ipairs(order) do if s ~= 3 then filtered[#filtered + 1] = s end end
                order = filtered
            end
            return order
        end
        local function nextUsableSlot(excludeIdx)
            for _, s in ipairs(slotOrder()) do if s ~= excludeIdx and slotUsable(s) then return s end end
            return nil
        end
        local function equipSlot(idx)
            if not idx then return false end
            if whichSlotNow() == idx then return true end
            local now = tick()
            if now - (State.RageSwitchLast or 0) < (Config.RageSwitchRateLimit or 0.06) then return false end
            State.RageSwitchLast = now
            local lf = Rivals.Fighter and Rivals.Fighter.LocalFighter
            local equipped = false
            if lf and lf.EquipItem then equipped = pcall(function() lf:EquipItem(idx) end) end
            if not equipped then
                pcall(function()
                    local kc = ({ Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three })[idx]
                    if kc then
                        VirtualInputMgr:SendKeyEvent(true, kc, false, game)
                        VirtualInputMgr:SendKeyEvent(false, kc, false, game)
                    end
                end)
            end
            return true
        end
        Rage._equipSlot = equipSlot
        Rage._nextUsableSlot = nextUsableSlot
        Rage._whichSlotNow = whichSlotNow
    end)()
    local function encodeRageShot(camData)
        if tick() - (State.RageFireStamp or 0) > 0.03 then return false end
        local hitPart, eyePos, aimPos = State.RageFireHitPart, State.RageFireFromPos, State.RageFireAimPos
        if not (hitPart and hitPart.Parent and eyePos and aimPos) then return false end
        if not isSanePos(eyePos) or not isSanePos(hitPart.Position) then return false end
        if (hitPart.Position - eyePos).Magnitude > (400 - 5) then return false end
        local ignore = { lp.Character }
        local t = State.RageTarget or State.Target
        if t and t.Character then ignore[2] = t.Character end
        if not Config.RageWallbang and not hasLOS(eyePos, hitPart.Position, ignore) then return false end
        local item = getEquippedItem(); if not item then return false end
        local okE, equipping = pcall(function() return item:IsEquipping() end)
        if okE and equipping then return false end
        if not (Rage._itemIsMelee and Rage._itemIsMelee(item)) then
            local okR, reloading = pcall(function() return (item._reload_cooldown or 0) > tick() end)
            if okR and reloading then return false end
            local okA, ammo = pcall(function() return item:Get("Ammo") end)
            if not okA or type(ammo) ~= "number" or ammo <= 0 then return false end
        end
        local interval = 0
        if Rage._fireInterval then interval = Rage._fireInterval() end
        if tick() - (State.RageLastFireTime or 0) < interval then return false end
        State.RageLastFireTime = tick()
        local eyeCF = lookCF(eyePos, aimPos)
        local muzzleCF = eyeCF - Vector3.new(0, Config.RageEyeMuzzleSep, 0)
        buildShotFields(camData, eyeCF, muzzleCF, hitPart, aimPos, true, RAGE_CLAMP_FRAC, RAGE_JITTER_FRAC)
        State.Shots = State.Shots + 1
        return true
    end
    Rage._encodeRageShot = encodeRageShot
    local function findTarget()
        local myChar = lp.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        local cands  = {}
        for _, p in ipairs(getSafePlayers()) do
            if isValidTarget(p, Config.RageVisCheck, true, true) then
                local hum = p.Character:FindFirstChildOfClass("Humanoid")
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                local d = 9999
                local sane = myRoot ~= nil and hrp ~= nil and isSanePos(hrp.Position)
                if sane then d = (hrp.Position - myRoot.Position).Magnitude end
                if (not sane) or d <= (Config.MaxDistance or 1200) then
                    table.insert(cands, { p = p, hp = hum.Health, d = d })
                end
            end
        end
        if #cands == 0 then return nil end
        if Config.RageHPPriority then
            table.sort(cands, function(a, b)
                if math.abs(a.hp - b.hp) > 10 then return a.hp < b.hp end
                return a.d < b.d
            end)
        else table.sort(cands, function(a, b) return a.d < b.d end) end
        return cands[1].p
    end
    Rage._findTarget = findTarget
    local function startTargetLoop()
        if _tgtConn then _tgtConn:Disconnect() end
        local lastPosMap, lastTimeMap = {}, {}
        _tgtConn = RunService.Heartbeat:Connect(function()
            if not Config.Rage then return end
            local nowTime = tick()
            for _, p in ipairs(getSafePlayers() or {}) do
                if p ~= lp and p.Character then
                    local pRoot = p.Character:FindFirstChild("HumanoidRootPart")
                    if pRoot then
                        local currentPos = pRoot.Position
                        if lastPosMap[p] and lastTimeMap[p] then
                            local dt = nowTime - lastTimeMap[p]
                            if dt > 0 then State.RageTrueVelocityMap[p] = (currentPos - lastPosMap[p]) / dt end
                        end
                        lastPosMap[p] = currentPos; lastTimeMap[p] = nowTime
                    end
                end
            end
            if Config.RageFastTargetSwitch and State.Target and not isValidTarget(State.Target, false, true, true) then
                State.Target = nil
            end
            State.Target = findTarget()
        end)
    end
    Rage._startTargetLoop = startTargetLoop
    function Rage.init()
        for _, p in ipairs(getSafePlayers()) do bump(p) end
        Players.PlayerAdded:Connect(function(p) bump(p); p.CharacterAdded:Connect(function() bump(p) end) end)
        for _, p in ipairs(getSafePlayers()) do p.CharacterAdded:Connect(function() bump(p) end) end
        Players.PlayerRemoving:Connect(function(p) State.RageCharTokens[p] = nil end)
        lp.CharacterAdded:Connect(function()
            bump(lp); State.RageRealCF = nil; State.RageRealChar = nil
            State.RageParkDirty = false; State.RageTarget = nil
        end)
        bump(lp)
    end
    local _rageConn, _rageCharConn = nil, nil
    local _rageStepConn, _rageDiedConn, _rageCooldownConn = nil, nil, nil
    local _rageRestoreName = "__jh_rage_restore"
    local function fireInterval() return Config.RageFireRateOverride or 0 end
    Rage._fireInterval = fireInterval
    local _preParkCF = nil
    local _identGet, _identSet, _identTried = nil, nil, false
    local function rawSetCFrame(hrp, cf)
        if not _identTried then
            _identTried = true
            pcall(function()
                local g = getthreadidentity or get_thread_identity
                local s = setthreadidentity or set_thread_identity or setidentity or setthreadcontext
                if type(g) == "function" and type(s) == "function" then _identGet, _identSet = g, s end
            end)
        end
        if _identSet ~= nil then
            local okPrev, prev = pcall(_identGet)
            if okPrev then
                pcall(_identSet, 8)
                local wrote = pcall(function() hrp.CFrame = cf end)
                pcall(_identSet, prev)
                if wrote then return true end
            end
        end
        return pcall(function() hrp.CFrame = cf end)
    end
    local function displace(hrp, cf)
        if _preParkCF == nil then _preParkCF = hrp.CFrame end
        return rawSetCFrame(hrp, cf)
    end
    Rage._displace = displace
    local ORBIT_PRIME_S, ORBIT_JITTER_MAX, ORBIT_JUMP = 0.07, 0.25, 5
    local _orbHiding, _orbPrimeUntil = true, 0
    local ORB_IMMUNE_MAX_HOLD = 6.0
    local _orbImmuneSince, _orbImmuneTgt = 0, nil
    local _orbLastDisp = nil
    local function voidAxis() local v = math.random(110000, 140000); if math.random(0, 1) == 0 then return -v end; return v end
    local function rollVoid() return CFrame.new(voidAxis(), math.random(110000, 140000), voidAxis()) end
    local function stepClears(cf, prev, minStep)
        if not prev then return true end
        return (cf.Position - prev.Position).Magnitude >= minStep
    end
    local function voidCFrame()
        local now = tick()
        if not Config.RageVoidMove then
            if (not State.RageVoidCF) or now >= (State.RageVoidNext or 0) then
                State.RageVoidCF = rollVoid(); State.RageVoidNext = now + 4 + math.random() * 4
            end
            return State.RageVoidCF
        end
        local prev = State.RageVoidCF
        local cf
        if Config.RageVoidJitterLocal then
            if (not State.RageVoidBase) or now >= (State.RageVoidNext or 0) then
                State.RageVoidBase = rollVoid(); State.RageVoidNext = now + 4 + math.random() * 4
            end
            local base = State.RageVoidBase.Position
            local span = Config.RageVoidJitterStuds or 2000
            local function offset() local v = 500 + math.random() * (span - 500); if math.random(0, 1) == 0 then return -v end; return v end
            local tries = 0
            repeat cf = CFrame.new(base.X + offset(), math.max(base.Y + offset(), 110000), base.Z + offset()); tries = tries + 1
            until tries >= 8 or stepClears(cf, prev, 600)
        else
            local minStep = Config.RageVoidMinStep or 25000
            local tries = 0
            repeat cf = rollVoid(); tries = tries + 1 until tries >= 8 or stepClears(cf, prev, minStep)
        end
        State.RageVoidCF = cf
        State.RageVoidSteps = (State.RageVoidSteps or 0) + 1
        return cf
    end
    local function weaponReady(it)
        if not it then return false end
        local okE, equipping = pcall(function() return it:IsEquipping() end)
        if okE and equipping then return false end
        if (it._reload_cooldown or 0) > tick() then return false end
        if Rage._itemIsMelee and Rage._itemIsMelee(it) then return true end
        local okA, ammo = pcall(function() return it:Get("Ammo") end)
        return okA and type(ammo) == "number" and ammo > 0
    end
    Rage._ensureReload = function(it)
        if it == nil then return "no item" end
        local okR, reloading = pcall(function() return (it._reload_cooldown or 0) > tick() end)
        if okR and reloading then return "waiting" end
        local okA, ammo = pcall(function() return it:Get("Ammo") end)
        if okA and type(ammo) == "number" and ammo > 0 then return "loaded" end
        local okRes, reserve = pcall(function() return it:Get("AmmoReserve") end)
        if okRes and type(reserve) == "number" and reserve <= 0 then
            local okInf, inf = pcall(function() return it.ClientFighter ~= nil and it.ClientFighter:Get("InfiniteAmmoReserve") == true end)
            if not okInf or inf ~= true then return "dry" end
        end
        if tick() - (State.RageReloadLast or 0) < 0.5 then return "throttled" end
        State.RageReloadLast = tick()
        pcall(function()
            local lf = Rivals.Fighter and Rivals.Fighter.LocalFighter
            if lf ~= nil then
                task.spawn(function()
                    if setthreadidentity then setthreadidentity(2) elseif setidentity then setidentity(2) end
                    pcall(function() lf:Input("StartReloading") end)
                    if setthreadidentity then setthreadidentity(8) elseif setidentity then setidentity(8) end
                end)
            end
        end)
        pcall(function() it:StartReloading() end)
        return "requested"
    end
    local _SLOT_INDEX = { Primary = 1, Secondary = 2 }
    Rage._weaponRecovery = function(it)
        local mode = Config.RageOnEmpty or "Reload"
        local okA, ammo = pcall(function() return it and it:Get("Ammo") end)
        local empty = not (okA and type(ammo) == "number" and ammo > 0)
        if mode ~= "Swap" or not empty then return Rage._ensureReload(it) end
        local lf = Rivals.Fighter and Rivals.Fighter.LocalFighter
        local items = lf and lf.Items
        if type(items) ~= "table" then return Rage._ensureReload(it) end
        if tick() - (State.RageSwitchLast or 0) < 0.5 then return "swap-wait" end
        local pref = _SLOT_INDEX[Config.RagePreferredSlot or "Primary"] or 1
        local other = pref == 1 and 2 or 1
        for _, slot in ipairs({ pref, other }) do
            local w = items[slot]
            if w and w ~= it then
                local okW, wammo = pcall(function() return w:Get("Ammo") end)
                if okW and type(wammo) == "number" and wammo > 0 then
                    local busy = false
                    pcall(function() if w:IsEquipping() then busy = true end end)
                    pcall(function() if (w._reload_cooldown or 0) > tick() then busy = true end end)
                    if not busy then
                        State.RageSwitchLast = tick()
                        local okE = pcall(function() lf.EquipItem(lf, slot) end)
                        if okE then State.AutoWeaponFails = 0 return "swap" end
                        State.AutoWeaponFails = (State.AutoWeaponFails or 0) + 1
                    end
                end
            end
        end
        return Rage._ensureReload(it)
    end
    local function flankPoint(tgt, hh)
        if not tgt or not tgt.Character or not hh or not isSanePos(hh.Position) then return nil end
        local katana = Config.AvoidDeflect and isKatana(tgt)
        local shield = Config.RageShieldBackstab and isRiotShield(tgt)
        local stowed = Config.RageShieldBackstab and ownsRiotShield(tgt)
        if not (katana or shield or stowed) then return nil end
        local thrp = tgt.Character:FindFirstChild("HumanoidRootPart")
        if not thrp then return nil end
        local look = thrp.CFrame.LookVector
        look = Vector3.new(look.X, 0, look.Z)
        if look.Magnitude < 1e-3 then return nil end
        local inv = -look.Unit
        if not katana and not shield and stowed then inv = look.Unit end
        local anchor, kf = hh.Position, killFloor()
        local dist = shield and 2.5 or 3.0
        local ignore = { tgt.Character, lp.Character }
        local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude
        rp.FilterDescendantsInstances = ignore
        local flank = anchor + inv * dist
        local wr = workspace:Raycast(anchor, inv * dist, rp)
        if wr then flank = wr.Position - inv * 0.5 end
        flank = Vector3.new(flank.X, math.max(flank.Y, kf + 3), flank.Z)
        if not hasLOS(flank, hh.Position, ignore) then return nil end
        return flank
    end
    local _shootEnum
    local function polarFire(eyePos, aimPos, hh)
        local reach = 1e9
        if hh and hh.Parent then reach = (hh.Position - eyePos).Magnitude end
        if not (reach <= 395) then State.RageBlankCanary = State.RageBlankCanary + 1 return end
        local it = getEquippedItem(); if not it then return end
        if Config.RageDirectFire then
            if Config.RageRateLimit then
                if tick() - (State.RageLastFireTime or 0) < fireInterval() then return end
                State.RageLastFireTime = tick()
            end
            pcall(function() it._shoot_cooldown = 0; it._shoot_cooldown_no_ammo = 0; it._last_shot = tick() - 1 end)
            if not (Rivals.Ready and Rivals.Enums and Rivals.Util) then return end
            if _shootEnum == nil then pcall(function() _shootEnum = Rivals.Enums:ToEnum("StartShooting") end) end
            if _shootEnum == nil then return end
            local okId, objId = pcall(function() return it:Get("ObjectID") end)
            if not okId or not objId then return end
            local eyeCF = Rage._lookCF(eyePos, aimPos)
            local muzzleCF = eyeCF - Vector3.new(0, Config.RageEyeMuzzleSep, 0)
            local taps = Config.RageTapsPerFrame
            if type(taps) ~= "number" then taps = 1 end
            taps = math.max(1, math.min(math.floor(taps), math.floor(Config.RageTaps or 6)))
            local sent, rayCast = 0, false
            pcall(function() rayCast = it.Info.IsRaycast == true end)
            State.RageForging = true
            pcall(function()
                local remote = ReplicatedStorage.Remotes.Replication.Fighter.UseItem
                for _ = 1, taps do
                    if not (hh and hh.Parent) then break end
                    local inner = {}
                    Rage._buildShotFields(inner, eyeCF, muzzleCF, hh, aimPos, true, 0.30, 1.0)
                    local env = { [utf8.char(1)] = inner }
                    if rayCast then env[utf8.char(2)] = true end
                    remote:FireServer(objId, _shootEnum, env, nil)
                    sent = sent + 1
                end
            end)
            State.RageForging = false
            State.Shots = State.Shots + sent
            return
        end
        if not weaponReady(it) then return end
        if not hh or not hh.Parent or not isSanePos(hh.Position) then return end
        local hpos = hh.Position
        if (hpos - eyePos).Magnitude > (400 - 5) then return end
        local ignore = { lp.Character }
        local tgt = State.RageTarget or State.Target
        if tgt and tgt.Character then ignore[2] = tgt.Character end
        if not Config.RageWallbang and not hasLOS(eyePos, hpos, ignore) then return end
        if tick() - (State.RageLastFireTime or 0) < fireInterval() then return end
        State.RageFireFromPos = eyePos
        State.RageFireAimPos  = aimPos
        State.RageFireHitPart = hh
        State.RageFireStamp   = tick()
        local lf = Rivals.Fighter and Rivals.Fighter.LocalFighter
        if not lf then return end
        task.spawn(function()
            if setthreadidentity then setthreadidentity(2) elseif setidentity then setidentity(2) end
            pcall(function() lf:Input("StartShooting") end)
            if setthreadidentity then setthreadidentity(8) elseif setidentity then setidentity(8) end
        end)
    end
    local function clearFireSolution()
        State.RageFireFromPos = nil; State.RageFireAimPos = nil
        State.RageFireHitPart = nil; State.RageFireStamp = 0
    end
    ;(function()
        local function orbitVantage(aimPos, ignore, kf, knife)
            State.OrbitAngle = ((State.OrbitAngle or 0) + 2.39996) % (math.pi * 2)
            local base = Config.RageCombatOrbitRadius or 60
            local radii = knife and { math.max(base, 75), 95 } or { base, base * 0.6, math.min(base * 1.5, 380) }
            for _, r in ipairs(radii) do
                for i = 0, 5 do
                    local ang = State.OrbitAngle + i * (math.pi / 3)
                    local jitter = 0
                    if Config.RageCombatOrbitJitter then jitter = (math.random() - 0.5) * 14 end
                    local h = (Config.RageCombatOrbitHeight or 8) + jitter
                    local pos = Vector3.new(aimPos.X + math.cos(ang) * r,
                        math.max(aimPos.Y + h, kf + 6), aimPos.Z + math.sin(ang) * r)
                    if isSanePos(pos) and not posIsOOB(pos) and hasLOS(pos, aimPos, ignore) then return pos end
                end
            end
            return nil
        end
        local function orbitVoid(hrp, status)
            State.RageStatus = status
            State.OrbitVantage = nil; State.OrbitVantageUntil = 0
            State.RageFiring = false; State.RageVoidActive = true
            clearFireSolution()
            _orbHiding = true; _orbPrimeUntil = 0; _orbLastDisp = nil
            Rage._displace(hrp, voidCFrame())
        end
        local _orbDeflectSince = 0
        local function orbitTick(ch, hrp, tgt)
            local kf = killFloor()
            if not tgt or not tgt.Character then return orbitVoid(hrp, "No target") end
            local tc, thrp = tgt.Character, tgt.Character:FindFirstChild("HumanoidRootPart")
            local hh = tc:FindFirstChild("HitboxHead") or tc:FindFirstChild("Head")
            if not hh or not isSanePos(hh.Position) then return orbitVoid(hrp, "Hiding") end
            if Config.AvoidDeflect and isDeflecting(tgt) then
                if _orbDeflectSince == 0 then _orbDeflectSince = tick() end
                if tick() - _orbDeflectSince < 1.5 then return orbitVoid(hrp, "Deflecting") end
            else _orbDeflectSince = 0 end
            if not weaponReady(getEquippedItem()) then
                local act = Rage._weaponRecovery(getEquippedItem())
                if act == "dry" then return orbitVoid(hrp, "Dry") end
                if act == "swap" or act == "swap-wait" then return orbitVoid(hrp, "Swapping") end
                return orbitVoid(hrp, "Reloading")
            end
            local aimPos = hh.Position
            if posIsOOB(aimPos) or aimPos.Y < kf + 1 then return orbitVoid(hrp, "Hiding") end
            local ignore = { tc, lp.Character }
            local vantage, status = nil, nil
            local flank = flankPoint(tgt, hh)
            if not flank and thrp and Config.RageKnifeBackstab and isLocalKnife() then
                local inv = -thrp.CFrame.LookVector
                local rp = RaycastParams.new()
                rp.FilterType = Enum.RaycastFilterType.Exclude
                rp.FilterDescendantsInstances = ignore
                local f = thrp.Position + inv * 3.0
                local wr = workspace:Raycast(thrp.Position, inv * 3.0, rp)
                if wr then f = wr.Position - inv * 0.5 end
                local cand = Vector3.new(f.X, math.max(f.Y, kf + 3), f.Z)
                if isSanePos(cand) and not posIsOOB(cand) and hasLOS(cand, hh.Position, ignore) then
                    flank = cand
                end
            end
            if flank then
                vantage = flank; State.OrbitVantage = nil
                if isRiotShield(tgt) then status = "Anti-riot"
                elseif isKatana(tgt) then status = "Katana flank"
                else status = "Backstab" end
            else
                local knife = isEnemyKnife(tgt)
                local held = State.OrbitVantage
                if (not held) or tick() >= (State.OrbitVantageUntil or 0) or not hasLOS(held, aimPos, ignore) then
                    local v = orbitVantage(aimPos, ignore, kf, knife)
                    if v then
                        State.OrbitVantage = v
                        State.OrbitVantageUntil = tick() + (Config.RageOrbitDwell or 0.09)
                        held = v
                    elseif held and hasLOS(held, aimPos, ignore) then
                        State.OrbitVantageUntil = tick() + (Config.RageOrbitDwell or 0.09)
                    else held = nil end
                end
                if held then
                    vantage = held
                    if knife then status = "Orbit (kept dist)" else status = "Orbit" end
                end
            end
            if not vantage or not isSanePos(vantage) or posIsOOB(vantage) then return orbitVoid(hrp, "Orbit (hiding)") end
            State.RageStatus = status or "Orbit"
            State.RageVoidActive = false
            local jumped = _orbLastDisp == nil or (vantage - _orbLastDisp).Magnitude > ORBIT_JUMP
            _orbLastDisp = vantage
            if _orbHiding or jumped then
                _orbHiding = false
                local extra = 0
                if Config.RageHideJitter ~= false then extra = math.random() * ORBIT_JITTER_MAX end
                _orbPrimeUntil = tick() + ORBIT_PRIME_S + extra
            end
            Rage._displace(hrp, CFrame.new(vantage))
            local holdFire = false
            if Config.RageSkipImmune ~= false then holdFire = isSpawnProtected(tgt) end
            if not holdFire then _orbImmuneSince, _orbImmuneTgt = 0, nil
            else
                local nowI = tick()
                if _orbImmuneTgt ~= tgt then _orbImmuneSince, _orbImmuneTgt = nowI, tgt end
                if nowI - _orbImmuneSince > ORB_IMMUNE_MAX_HOLD then
                    holdFire = false
                    State.RageImmuneOverride = (State.RageImmuneOverride or 0) + 1
                end
            end
            if holdFire then
                State.RageFiring = false
                State.RageStatus = "Protected — vantage held, holding fire"
            elseif tick() < _orbPrimeUntil then
                State.RageFiring = false
                State.RageStatus = "Priming"
            else
                State.RageFiring = true
                local eye = vantage + Vector3.new(0, Config.RagePBEyeUp or 3, 0)
                polarFire(eye, aimPos, hh)
            end
            pcall(Visuals.notifyTarget, tgt)
        end
        local function rageTick(ch, hrp, tgt)
            if (Config.RageMode or "Polar") ~= "Orbit" then
                State.RageStatus = "Mode error"; return
            end
            orbitTick(ch, hrp, tgt)
        end
        Rage._rageTick = rageTick
    end)()
    local function restoreHome(pin)
        if State.RagePostPark then State.RageOrderCanary = State.RageOrderCanary + 1 end
        local ch = lp.Character; if not ch then return end
        local hrp = ch:FindFirstChild("HumanoidRootPart")
        if not hrp or not hrp.Parent then return end
        local back = _preParkCF; _preParkCF = nil
        if back == nil then
            local real = State.RageRealCF
            if real and State.RageRealChar == ch then back = CFrame.new(real.Position) * hrp.CFrame.Rotation end
        end
        pcall(function()
            if back then hrp.CFrame = back end
            State.RageParkDirty = false
            if pin then
                local hu = ch:FindFirstChildOfClass("Humanoid")
                if hu and hu:GetState() == Enum.HumanoidStateType.Freefall and hu.FloorMaterial ~= Enum.Material.Air then
                    hu:ChangeState(Enum.HumanoidStateType.Running)
                end
            end
        end)
    end
    local function startRage()
        if _rageConn then return end
        local function hookDied(char)
            if _rageDiedConn then _rageDiedConn:Disconnect(); _rageDiedConn = nil end
            if not char then return end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then _rageDiedConn = hum.Died:Connect(function() end) end
        end
        hookDied(lp.Character)
        if not _rageCharConn then
            _rageCharConn = lp.CharacterAdded:Connect(function()
                State.RageRealCF = nil; State.RageRealChar = nil
                State.RageVoidCF = nil; State.RageVoidBase = nil
                State.RageParkDirty = false; State.RageLastParkPos = nil
                hookDied(lp.Character)
            end)
        end
        local function rageRestoreActive()
            if not Config.Rage then return false end
            if not State.RageInMatch then return false end
            if State.RageRealChar ~= lp.Character then return false end
            return true
        end
        pcall(function() RunService:UnbindFromRenderStep(_rageRestoreName) end)
        RunService:BindToRenderStep(_rageRestoreName, Enum.RenderPriority.First.Value - 1000, function()
            State.RagePostPark = false
            if rageRestoreActive() then restoreHome(true) end
        end)
        if not _rageStepConn then
            _rageStepConn = RunService.Stepped:Connect(function()
                State.RagePostPark = false
                if rageRestoreActive() then restoreHome(true) end
            end)
        end
        if not _rageCooldownConn then
            _rageCooldownConn = RunService.Heartbeat:Connect(function()
                if not Config.Rage then return end
                local it = getEquippedItem(); if not it then return end
                it._shoot_cooldown = 0
                it._shoot_cooldown_no_ammo = 0
                if (it._last_shot or 0) > tick() + 1 then it._last_shot = tick() - 1 end
                if it._shot_but_ammo_hasnt_updated then it._shot_but_ammo_hasnt_updated = false end
            end)
        end
        _rageConn = RunService.Heartbeat:Connect(function()
            if not Config.Rage or (Config.RageMode or "Polar") ~= "Orbit" then
                restoreHome(false)
                pcall(function() RunService:UnbindFromRenderStep(_rageRestoreName) end)
                if _rageConn then _rageConn:Disconnect(); _rageConn = nil end
                if _rageStepConn then _rageStepConn:Disconnect(); _rageStepConn = nil end
                if _rageCooldownConn then _rageCooldownConn:Disconnect(); _rageCooldownConn = nil end
                if _rageCharConn then _rageCharConn:Disconnect(); _rageCharConn = nil end
                if _rageDiedConn then _rageDiedConn:Disconnect(); _rageDiedConn = nil end
                State.RageRealCF = nil; State.RageRealChar = nil
                State.RageTarget = nil; State.RageVoidCF = nil; State.RageVoidBase = nil
                State.RageParkDirty = false; State.RageLastParkPos = nil
                State.RageInMatch = false
                State.OrbitVantage = nil; State.OrbitVantageUntil = 0
                clearFireSolution()
                return
            end
            local ch = lp.Character
            local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
            if not hrp or not hrp.Parent then clearFireSolution() return end
            if State.RageParkDirty and State.RageRealChar == ch then
                State.RageParkLatchCanary = State.RageParkLatchCanary + 1
                if State.RageLastParkPos then
                    State.RageLatchStuds = (hrp.Position - State.RageLastParkPos).Magnitude
                end
            elseif isSanePos(hrp.Position) then
                State.RageRealCF = hrp.CFrame
                State.RageRealChar = ch
            end
            State.RageInMatch = inMatch()
            if not State.RageInMatch then
                if not isSanePos(hrp.Position) then restoreHome(false) end
                State.RageTarget = nil
                State.RageStatus = "Lobby"
                State.RageFiring = false
                clearFireSolution()
                return
            end
            if not State.RageRealCF or State.RageRealChar ~= ch then
                State.RageStatus = "Waiting"; State.RageFiring = false
                clearFireSolution(); return
            end
            local hum0 = ch:FindFirstChildOfClass("Humanoid")
            if hum0 and hum0.Health <= 0 then
                if not isSanePos(hrp.Position) then restoreHome(false) end
                State.RageFiring = false; State.RageVoidActive = false; State.RageStatus = "Dead"
                clearFireSolution(); return
            end
            local tgt = State.RageTarget
            if tgt and (not tgt.Parent or not tgt.Character or not isAlive(tgt)
                or (Config.TeamCheck and isTeammate(tgt))) then tgt = nil end
            if not tgt then tgt = Rage._findTarget() end
            State.RageTarget = tgt
            State.RagePostPark = true
            Rage._rageTick(ch, hrp, tgt)
            local anchor = State.RageRealCF
            local displaced = false
            if anchor then displaced = (hrp.Position - anchor.Position).Magnitude > 0.001 end
            State.RageParkDirty = displaced
            if displaced then State.RageLastParkPos = hrp.Position end
        end)
    end
    function Rage.enable()
        Config.Rage = true
        if Rage._startTargetLoop then Rage._startTargetLoop() end
        if (Config.RageMode or "Polar") ~= "Orbit" then
            if Rage._polarCoreStart then Rage._polarCoreStart() end
            return
        end
        startRage()
    end
    function Rage.disable()
        Config.Rage = false
        if Rage._polarCoreStop then Rage._polarCoreStop() end
        State.RagePostPark = false
        pcall(function() RunService:UnbindFromRenderStep(_rageRestoreName) end)
        if _rageConn then _rageConn:Disconnect(); _rageConn = nil end
        if _rageStepConn then _rageStepConn:Disconnect(); _rageStepConn = nil end
        if _rageCooldownConn then _rageCooldownConn:Disconnect(); _rageCooldownConn = nil end
        if _rageCharConn then _rageCharConn:Disconnect(); _rageCharConn = nil end
        if _rageDiedConn then _rageDiedConn:Disconnect(); _rageDiedConn = nil end
        restoreHome(false)
        State.RageRealCF = nil; State.RageRealChar = nil
        State.RageTarget = nil; State.RageVoidCF = nil; State.RageVoidBase = nil
        State.RageParkDirty = false; State.RageLastParkPos = nil
        State.RageInMatch = false
        State.OrbitVantage = nil; State.OrbitVantageUntil = 0
        State.RageFiring = false; State.RageVoidActive = false; State.RageStatus = "Idle"
        clearFireSolution()
    end
    function Rage.unload()
        Rage.disable()
        if _tgtConn then pcall(function() _tgtConn:Disconnect() end); _tgtConn = nil end
    end
end)()

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
    local _preParkCF = nil
    local _prevPark, _prevParkTgt, _lastPark = nil, nil, nil
    local PRIME_S, HIDE_JITTER_MAX = 0.07, 0.25
    local _hiding, _primeUntil = false, 0
    local _identGet, _identSet, _identTried = nil, nil, false
    local function identEnsure()
        if _identTried then return _identSet ~= nil end
        _identTried = true
        pcall(function()
            local g = getthreadidentity or get_thread_identity
            local s = setthreadidentity or set_thread_identity or setidentity or setthreadcontext
            if type(g) == "function" and type(s) == "function" then _identGet, _identSet = g, s end
        end)
        State.RageRawSet = _identSet ~= nil
        return _identSet ~= nil
    end
    local function rawSetCFrame(hrp, cf)
        identEnsure()
        if _identSet ~= nil then
            local okPrev, prev = pcall(_identGet)
            if okPrev then
                pcall(_identSet, 8)
                local wrote = pcall(function() hrp.CFrame = cf end)
                pcall(_identSet, prev)
                if wrote then return true end
            end
        end
        return pcall(function() hrp.CFrame = cf end)
    end
    local function killFloor()
        local ok, val = pcall(function() return Workspace.FallenPartsDestroyHeight end)
        if ok and type(val) == "number" and val == val then return val + KILL_PLANE_BUF end
        return -400
    end
    local function isProtected(player)
        if not player or not player.Character then return false end
        if player.Character:FindFirstChildOfClass("ForceField") then return true end
        if not Config.RageSkipImmune then return false end
        return isSpawnProtected(player)
    end
    local function inMatchLocal()
        local envOk = false
        pcall(function()
            local lf = Rivals.Fighter and Rivals.Fighter.LocalFighter
            if lf ~= nil and lf:Get("EnvironmentID") ~= nil and lf:IsAlive() then envOk = true end
        end)
        if envOk then return true end
        if lp:GetAttribute("TeamID") ~= nil then return true end
        if lp.Team ~= nil then return true end
        return false
    end
    local function getEquippedItem()
        local ok, result = pcall(function()
            local lf = Rivals.Fighter and Rivals.Fighter.LocalFighter
            if lf and lf.EquippedItem then return lf.EquippedItem end
            return nil
        end)
        if ok then return result end
        return nil
    end
    local function weaponReady(it)
        if not it then return false end
        local okE, equipping = pcall(function() return it:IsEquipping() end)
        if okE and equipping then return false end
        if (it._reload_cooldown or 0) > tick() then return false end
        local magazine = true
        pcall(function() magazine = it.Info.MaxAmmo ~= nil end)
        if not magazine then return true end
        local okA, ammo = pcall(function() return it:Get("Ammo") end)
        return okA and type(ammo) == "number" and ammo > 0
    end
    local function findTarget()
        local myChar = lp.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        local cands, unreachable = {}, {}
        for _, p in Players:GetPlayers() do
            if p ~= lp and not isTeammate(p) and isAlive(p) then
                local c = p.Character
                local hrp = c and c:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local d = 9999
                    if myRoot then d = (hrp.Position - myRoot.Position).Magnitude end
                    local hum = c:FindFirstChildOfClass("Humanoid")
                    local health = hum and hum.Health or 9999
                    local entry = { p = p, hp = health, d = d, prot = isProtected(p) }
                    if isSanePos(hrp.Position) and d <= Config.MaxDistance then
                        table.insert(cands, entry)
                    else table.insert(unreachable, entry) end
                end
            end
        end
        if #cands == 0 then cands = unreachable end
        if #cands == 0 then return nil end
        table.sort(cands, function(a, b)
            if a.prot ~= b.prot then return b.prot end
            if math.abs(a.hp - b.hp) > 10 then return a.hp < b.hp end
            return a.d < b.d
        end)
        return cands[1].p
    end
    local function voidAxis() local v = math.random(VOID_R_MIN, VOID_R_MAX); if math.random(0, 1) == 0 then return -v end; return v end
    local function rollVoid() return CFrame.new(voidAxis(), math.random(VOID_R_MIN, VOID_R_MAX), voidAxis()) end
    local function voidCFrame()
        local prev = _voidCF
        local cf = rollVoid()
        if prev then
            local tries = 0
            while tries < 8 and (cf.Position - prev.Position).Magnitude < VOID_MIN_STEP do
                cf = rollVoid(); tries = tries + 1
            end
        end
        _voidCF = cf; _voidSteps = _voidSteps + 1
        return cf
    end
    local function parkHasLOS(from, to, ourChar, tgtChar)
        local rp = RaycastParams.new()
        rp.FilterType = Enum.RaycastFilterType.Exclude
        rp.FilterDescendantsInstances = { ourChar, tgtChar }
        local res = Workspace:Raycast(from, to - from, rp)
        if not res then return true end
        return (res.Position - to).Magnitude < 3
    end
    local function eyeRise(fromPos, tgtChar)
        local rise = EYE_UP_SANE
        pcall(function()
            local rp = RaycastParams.new()
            rp.FilterType = Enum.RaycastFilterType.Exclude
            rp.FilterDescendantsInstances = { lp.Character, tgtChar }
            local res = Workspace:Raycast(fromPos, Vector3.new(0, EYE_UP_SANE, 0), rp)
            if res ~= nil then
                local room = (res.Position.Y - fromPos.Y) - 0.25
                if room < rise then rise = math.max(room, 0.15) end
            end
        end)
        return rise
    end
    local _meleeDwellStart = nil
    local MELEE_DWELL_S = 0.07
    local function pointBlank(hp) return Vector3.new(hp.X, math.max(hp.Y, killFloor() + 3), hp.Z) end
    local function meleeProfile(it)
        local prof = nil
        pcall(function()
            local info = it.Info
            if info == nil then return end
            if info.MaxAmmo ~= nil then return end
            local heavy = info.CriticalDamage ~= nil and type(info.HeavyAttackCooldown) == "number"
            prof = { heavy = heavy }
        end)
        return prof
    end
    local function meleeStrike(firePark, hpos, hh, tgt)
        local it = getEquippedItem()
        if it == nil then State.RageKnifeStatus = "no item" return false end
        local prof = meleeProfile(it)
        if prof == nil then State.RageKnifeStatus = "not a melee item" return false end
        local now = tick()
        if _meleeDwellStart == nil then _meleeDwellStart = now end
        if now - _meleeDwellStart < MELEE_DWELL_S then State.RageKnifeStatus = "dwell" return false end
        local actionName = prof.heavy and "StartAiming" or "StartShooting"
        local actionEnum = nil
        pcall(function() actionEnum = Rivals.Enums:ToEnum(actionName) end)
        local tc = tgt.Character
        local trp = tc and tc:FindFirstChild("HumanoidRootPart")
        if trp == nil then State.RageKnifeStatus = "target has no root" return false end
        local vp, vy = trp.CFrame:ToOrientation()
        if prof.heavy and Config.RageKnifeCamForge ~= false then ViewAngle.forge(vp, vy) end
        local eyePos = firePark + Vector3.new(0, eyeRise(firePark, tgt.Character), 0)
        local eyeCF = Rage._lookCF(eyePos, hpos)
        local muzzleCF = eyeCF - Vector3.new(0, EYE_MUZZLE_SEP, 0)
        local lf = Rivals.Fighter and Rivals.Fighter.LocalFighter
        if lf == nil then return false end
        local restoreId = nil
        local g = getthreadidentity or get_thread_identity
        local s = setthreadidentity or set_thread_identity or setidentity
        if g and s then
            local prev = nil; pcall(function() prev = g() end)
            if prev and prev ~= 2 then
                pcall(s, 2)
                restoreId = function() pcall(s, prev) end
            end
        end
        local ok = pcall(function() lf:Input(actionName) end)
        if restoreId then restoreId() end
        if ok then
            _shots = _shots + 1
            State.Shots = State.Shots + 1
            State.RageKnifeSwings = (State.RageKnifeSwings or 0) + 1
            State.RageKnifeStatus = "swinging " .. actionName
            return true
        end
        State.RageKnifeStatus = "send failed"
        return false
    end
    local function polarFire(eyePos, aimPos, hh, taps)
        local it = getEquippedItem(); if not it then return 0 end
        pcall(function() it._shoot_cooldown = 0; it._shoot_cooldown_no_ammo = 0; it._last_shot = tick() - 1 end)
        if _shootEnum == nil then pcall(function() _shootEnum = Rivals.Enums:ToEnum("StartShooting") end) end
        if _shootEnum == nil then return 0 end
        if _useItem == nil then pcall(function() _useItem = ReplicatedStorage.Remotes.Replication.Fighter.UseItem end) end
        if _useItem == nil then return 0 end
        local okId, objId = pcall(function() return it:Get("ObjectID") end)
        if not okId or not objId then return 0 end
        local fireEyePos = eyePos
        local base = eyePos - Vector3.new(0, EYE_UP_SANE, 0)
        local ftgt = State.RageTarget or State.Target
        local rise = eyeRise(base, ftgt and ftgt.Character or nil)
        if rise < EYE_UP_SANE then fireEyePos = base + Vector3.new(0, rise, 0) end
        local eyeCF = Rage._lookCF(fireEyePos, aimPos)
        local muzzleCF = eyeCF - Vector3.new(0, EYE_MUZZLE_SEP, 0)
        local sent, rayCast = 0, false
        pcall(function() rayCast = it.Info.IsRaycast == true end)
        State.RageForging = true
        pcall(function()
            for _ = 1, taps do
                local inner = {}
                Rage._buildShotFields(inner, eyeCF, muzzleCF, hh, aimPos, true, RAGE_CLAMP_FRAC, 1.0)
                local env = { [utf8.char(1)] = inner }
                if rayCast and not parity() then env[utf8.char(2)] = true end
                _useItem:FireServer(objId, _shootEnum, env, nil)
                sent = sent + 1
            end
        end)
        State.RageForging = false
        _shots = _shots + sent
        State.Shots = State.Shots + sent
        return sent
    end
    local function tapsPerFrame()
        local n = Config.RageTapsPerFrame
        if type(n) ~= "number" then return 1 end
        if n < 1 then return 1 end
        if n > POLAR_TAPS_SANE then return POLAR_TAPS_SANE end
        return math.floor(n)
    end
    local ATTACK_GAP_HOLD = 0.30
    local _attackGapTgt, _attackGapUntil, _attackReadyTgt = nil, 0, nil
    local function clearAttackGap() _attackGapTgt = nil; _attackGapUntil = 0 end
    local function resetAttackContinuity() clearAttackGap(); _attackReadyTgt = nil end
    local function holdAttackGap(hrp, tgt, status)
        if Config.RageAttackContinuity == false then return false end
        local now = os.clock()
        if _attackGapTgt ~= tgt then
            if _attackReadyTgt ~= tgt or _prevPark == nil or _prevParkTgt ~= tgt then return false end
            _attackGapTgt = tgt; _attackGapUntil = now + ATTACK_GAP_HOLD
        elseif now > _attackGapUntil then clearAttackGap(); return false end
        _firing = false; State.RageFiring = false; State.RageStatus = status
        State.RageVoidActive = true; _lastPark = nil; _meleeDwellStart = nil
        rawSetCFrame(hrp, voidCFrame())
        return true
    end
    local function hide(hrp, status)
        resetAttackContinuity()
        _firing = false; State.RageFiring = false; State.RageStatus = status
        State.RageVoidActive = true
        _prevPark, _prevParkTgt, _lastPark = nil, nil, nil
        _hiding = true; _primeUntil = 0; _meleeDwellStart = nil
        rawSetCFrame(hrp, voidCFrame())
    end
    local function polarTick(ch, hrp)
        local tgt = _target
        if tgt and (not tgt.Parent or not tgt.Character or not isAlive(tgt) or isTeammate(tgt) or isProtected(tgt)) then tgt = nil end
        if not tgt then tgt = findTarget() end
        _target = tgt; State.RageTarget = tgt
        if not tgt or not tgt.Character then return hide(hrp, "No target") end
        local holdFire = isProtected(tgt)
        if not holdFire then _immuneSince, _immuneTgt = 0, nil
        else
            local now = tick()
            if _immuneTgt ~= tgt then _immuneSince, _immuneTgt = now, tgt end
            if now - _immuneSince > IMMUNE_MAX_HOLD then
                holdFire = false
                State.RageImmuneOverride = (State.RageImmuneOverride or 0) + 1
            end
        end
        if Config.AvoidDeflect and isDeflecting(tgt) then
            local now = tick()
            if _deflectSince == 0 then _deflectSince = now end
            if now - _deflectSince < DEFLECT_MAX_HOLD then return hide(hrp, "Deflecting") end
        else _deflectSince = 0 end
        local it = getEquippedItem()
        if not weaponReady(it) then
            local act = Rage._weaponRecovery(it)
            if act == "dry" then return hide(hrp, "Dry") end
            if act == "swap" or act == "swap-wait" then return hide(hrp, "Swapping") end
            return hide(hrp, "Reloading")
        end
        local hh = tgt.Character:FindFirstChild("HitboxHead") or tgt.Character:FindFirstChild("Head")
        if not hh then return hide(hrp, "Hiding") end
        if _hiding then
            _hiding = false
            local extra = 0
            if Config.RageHideJitter ~= false then extra = math.random() * HIDE_JITTER_MAX end
            _primeUntil = tick() + PRIME_S + extra
        end
        local hpos = hh.Position
        if not isSanePos(hpos) then
            if holdAttackGap(hrp, tgt, "Holding target swap") then return nil end
            return hide(hrp, "Head voided")
        end
        _firing = true
        State.RageFiring = not holdFire; State.RageVoidActive = false
        local melee = meleeProfile(it) ~= nil
        local park
        if melee then
            local trp = tgt.Character and tgt.Character:FindFirstChild("HumanoidRootPart")
            if trp and (it.name == "Knife" or (meleeProfile(it) and meleeProfile(it).heavy)) then
                park = trp.Position - (trp.CFrame.LookVector * 1.2) + Vector3.new(0, 0.6, 0)
            else park = hpos + (trp and (trp.CFrame.LookVector * -0.8) or Vector3.new(0, -0.5, 0)) end
        else park = pointBlank(hpos) end
        if posIsOOB(hpos) or posIsOOB(park) or not isSanePos(park) then
            if holdAttackGap(hrp, tgt, "Holding target swap") then return nil end
            return hide(hrp, "Hiding")
        end
        clearAttackGap()
        if Config.RageParkLift ~= false and not melee then
            local lifted = park + Vector3.new(0, 12, 0)
            if isSanePos(lifted) and not posIsOOB(lifted) and parkHasLOS(lifted, hpos, ch, tgt.Character) then
                park = lifted
            end
        end
        local parked = rawSetCFrame(hrp, CFrame.new(park))
        if parked then _prevPark, _prevParkTgt = park, tgt; _lastPark = CFrame.new(park)
        else _prevPark, _prevParkTgt, _lastPark = nil, nil, nil end
        local firePark = nil
        if _prevPark ~= nil and _prevParkTgt == tgt then firePark = _prevPark end
        if holdFire then State.RageStatus = "Protected — parked, holding fire"
        elseif firePark == nil then State.RageFiring = false; State.RageStatus = "Priming"; _meleeDwellStart = nil
        elseif (not parity()) and (tick() < _primeUntil) then State.RageFiring = false; State.RageStatus = "Priming"; _meleeDwellStart = nil
        elseif melee and Config.RageKnifeBot ~= false then
            if meleeStrike(firePark, hpos, hh, tgt) then _attackReadyTgt = tgt; State.RageStatus = "Melee"
            else State.RageFiring = false; State.RageStatus = "Melee (cooldown)" end
        else
            local sent = polarFire(firePark + Vector3.new(0, EYE_UP_SANE, 0), hpos, hh, tapsPerFrame())
            if sent > 0 then _attackReadyTgt = tgt end
            State.RageStatus = "Attacking"
        end
        if _notified ~= tgt then _notified = tgt; pcall(Visuals.notifyTarget, tgt) end
    end
    local function restoreHome(pin)
        local ch = lp.Character
        local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
        if not hrp or not hrp.Parent then return end
        local back = _preParkCF; _preParkCF = nil
        pcall(function()
            if back then hrp.CFrame = back end
            if pin then
                local hu = ch:FindFirstChildOfClass("Humanoid")
                if hu and hu:GetState() == Enum.HumanoidStateType.Freefall and hu.FloorMaterial ~= Enum.Material.Air then
                    hu:ChangeState(Enum.HumanoidStateType.Running)
                end
            end
        end)
    end
    local function cameraAnchor()
        if Config.RageCameraAnchor == false then return end
        local back = _preParkCF; if back == nil then return end
        local ch = lp.Character
        local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
        if not hrp or not hrp.Parent then return end
        local delta = back.Position - hrp.Position
        if not isSanePos(delta) then return end
        Camera.CFrame = Camera.CFrame + delta
    end
    local function reparkAfterRender()
        local cf = _lastPark; if cf == nil then return end
        local ch = lp.Character
        local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
        if not hrp or not hrp.Parent then return end
        rawSetCFrame(hrp, cf)
    end
    local function restoreMode()
        local m = Config.RageRestoreMode
        if m == "kicia" or m == "render" or m == "none" then return m end
        return "none"
    end
    function PolarCore.start()
        if _conn then return end
        _firing = false
        resetAttackContinuity()
        _notified = nil
        pcall(function() RunService:UnbindFromRenderStep(RENDER_NAME) end)
        pcall(function() RunService:UnbindFromRenderStep(CAMERA_NAME) end)
        RunService:BindToRenderStep(CAMERA_NAME, Enum.RenderPriority.Camera.Value + 5, function() pcall(cameraAnchor) end)
        RunService:BindToRenderStep(RENDER_NAME, Enum.RenderPriority.First.Value - 1000, function()
            if _firing and restoreMode() == "none" then return end
            restoreHome(false)
        end)
        _stepConn = RunService.Stepped:Connect(function()
            if _firing then
                local pol = restoreMode()
                if pol == "render" then return reparkAfterRender() end
                if pol ~= "kicia" then return end
            end
            restoreHome(true)
        end)
        _charConn = lp.CharacterAdded:Connect(function()
            _realCF, _realChar = nil, nil
            _voidCF, _target, _notified = nil, nil, nil
            _firing = false
            resetAttackContinuity()
            _preParkCF = nil
            _prevPark, _prevParkTgt, _lastPark = nil, nil, nil
            _hiding, _primeUntil = true, 0
        end)
        _conn = RunService.Heartbeat:Connect(function()
            if not Config.Rage or (Config.RageMode or "Polar") ~= "Polar" then
                PolarCore.stop(); return
            end
            local ch = lp.Character
            local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
            if not hrp or not hrp.Parent then return end
            if _preParkCF == nil and isSanePos(hrp.Position) then
                _realCF = hrp.CFrame; _realChar = ch
            end
            _inMatch = inMatchLocal()
            State.RageInMatch = _inMatch
            if not _inMatch then
                _target = nil; _firing = false; resetAttackContinuity()
                State.RageFiring = false; State.RageTarget = nil; State.RageStatus = "Lobby"
                if not isSanePos(hrp.Position) then restoreHome(false) end
                return
            end
            if not _realCF or _realChar ~= ch then
                _firing = false; resetAttackContinuity()
                State.RageFiring = false; State.RageStatus = "Waiting"; return
            end
            local hum = ch:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health <= 0 then
                _firing = false; resetAttackContinuity()
                State.RageFiring = false; State.RageVoidActive = false; State.RageStatus = "Dead"
                if not isSanePos(hrp.Position) then restoreHome(false) end
                return
            end
            polarTick(ch, hrp)
        end)
    end
    function PolarCore.stop()
        pcall(ViewAngle.restore)
        if _conn then _conn:Disconnect(); _conn = nil end
        if _stepConn then _stepConn:Disconnect(); _stepConn = nil end
        if _charConn then _charConn:Disconnect(); _charConn = nil end
        pcall(function() RunService:UnbindFromRenderStep(RENDER_NAME) end)
        pcall(function() RunService:UnbindFromRenderStep(CAMERA_NAME) end)
        _firing = false; resetAttackContinuity()
        local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        if hrp and hrp.Parent then
            if _realCF and _realChar == lp.Character then
                pcall(function() hrp.CFrame = CFrame.new(_realCF.Position) * hrp.CFrame.Rotation end)
            elseif not isSanePos(hrp.Position) then
                pcall(function() hrp.CFrame = CFrame.new(0, 100, 0) end)
            end
        end
        _realCF, _realChar, _target, _voidCF, _notified = nil, nil, nil, nil, nil
        State.RageFiring = false; State.RageVoidActive = false; State.RageTranslocating = false
        State.RageTarget = nil; State.RageInMatch = false; State.RageStatus = "Idle"
    end
    PolarCore.shots = function() return _shots end
    PolarCore.voidSteps = function() return _voidSteps end
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
            pcall(function()
                local wname = nil
                pcall(function() wname = self.Name end)
                if type(wname) ~= "string" then
                    local ci = self.ClientItem
                    pcall(function() wname = ci and ci.Name or nil end)
                end
                if type(wname) == "string" then
                    State.LastAttackWeapon = wname
                    State.LastAttackWeaponAt = tick()
                end
            end)
            local camData = results[3]
            if not camData or typeof(camData) ~= "table" then return end
            local camPos = Camera.CFrame.Position
            State.CamPos = camPos
            if Config.Rage then
                if Rage._encodeRageShot(camData) then results[4] = true end
                return
            end
            if Config.SilentAim then
                local tgt, part = selectTarget({
                    fov = Config.SilentAimFOV, checkVis = Config.SilentAimVisCheck,
                    partMode = Config.SilentAimTargetPart,
                    stickyTarget = State.SilentLastTarget,
                    stickyBonus = Config.SilentAimStickiness or 0.05,
                })
                if tgt and part then
                    State.SilentLastTarget = tgt
                    if math.random(1, 100) <= (Config.SilentAimHitChance or 100) then
                        local hitPart = pickSilentPart(tgt.Character, part)
                        if math.random(1, 100) <= (Config.SilentAimBodyMix or 0) then
                            local body = tgt.Character:FindFirstChild("HitboxBody")
                            if body and silentPartVisible(body.Position) then hitPart = body end
                        end
                        local jit = Vector3.zero
                        local jd = Config.SilentAimJitterDeg or 0
                        if jd > 0 then
                            local okD, unit = pcall(function()
                                return Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5)
                            end)
                            local dir = (okD and unit.Magnitude > 1e-4) and unit.Unit or Vector3.zero
                            local dist = 0
                            pcall(function() dist = (hitPart.Position - camPos).Magnitude end)
                            local off = math.min(math.tan(math.rad(jd)) * dist, 3) * (math.random() * 0.5)
                            jit = dir * off
                        end
                        if Rage._encodeShot(camData, hitPart, tgt.Character, camPos, jit) then
                            results[4] = true
                            State.Shots = State.Shots + 1
                            State.Hits  = State.Hits  + 1
                        end
                    end
                    return
                end
            end
            if Config.Aimbot and Config.AimbotShotOverride
                and State.AimbotTarget and State.AimbotPart and State.AimbotKeyHeld then
                local tgt = State.AimbotTarget
                if tgt and tgt.Character and isValidTarget(tgt, false) then
                    if Rage._encodeShot(camData, State.AimbotPart, tgt.Character, camPos) then
                        results[4] = true
                        State.Shots = State.Shots + 1
                        State.Hits  = State.Hits  + 1
                    end
                end
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
-- UI SETUP
-- =========================================================
Library.IsMobile = isMobile
Library.ShowCustomCursor = true

-- =========================================================
-- CUSTOM CURSOR (Added)
-- =========================================================
do
    local CoreGui = game:GetService('CoreGui')
    local cursorGui = Instance.new('ScreenGui')
    cursorGui.Name = 'JewHook_Cursor'
    cursorGui.IgnoreGuiInset = true
    cursorGui.ResetOnSpawn = false
    cursorGui.DisplayOrder = 2147483647
    cursorGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    local ok = pcall(function()
        cursorGui.Parent = gethui and gethui() or CoreGui
    end)
    if not ok then
        pcall(function() cursorGui.Parent = lp:FindFirstChildOfClass('PlayerGui') end)
    end

    local dot = Instance.new('Frame')
    dot.Size = UDim2.fromOffset(5, 5)
    dot.AnchorPoint = Vector2.new(0.5, 0.5)
    dot.BackgroundColor3 = Library.AccentColor or Color3.fromRGB(96, 165, 250)
    dot.BorderSizePixel = 0
    dot.ZIndex = 10
    dot.Visible = false
    dot.Parent = cursorGui
    Instance.new('UICorner', dot).CornerRadius = UDim.new(1, 0)

    local ring = Instance.new('Frame')
    ring.Size = UDim2.fromOffset(16, 16)
    ring.AnchorPoint = Vector2.new(0.5, 0.5)
    ring.BackgroundTransparency = 1
    ring.ZIndex = 9
    ring.Visible = false
    ring.Parent = cursorGui
    Instance.new('UICorner', ring).CornerRadius = UDim.new(1, 0)
    local stroke = Instance.new('UIStroke', ring)
    stroke.Color = Library.AccentColor or Color3.fromRGB(96, 165, 250)
    stroke.Thickness = 1.5
    stroke.Transparency = 0.15

    local _origMouseIcon = UserInputService.MouseIconEnabled
    local wasOpen = nil
    RunService.RenderStepped:Connect(function()
        local open = Library.MenuOpen == true
        if open ~= wasOpen then
            wasOpen = open
            dot.Visible = open
            ring.Visible = open
            pcall(function()
                UserInputService.MouseIconEnabled = open and false or _origMouseIcon
            end)
            if open then
                dot.BackgroundColor3 = Library.AccentColor
                stroke.Color = Library.AccentColor
            end
        end
        if open then
            local m = UserInputService:GetMouseLocation()
            dot.Position = UDim2.fromOffset(m.X, m.Y)
            ring.Position = UDim2.fromOffset(m.X, m.Y)
        end
    end)
end

pcall(function()
    Library.MainColor       = Color3.fromRGB(26, 27, 31)
    Library.BackgroundColor = Color3.fromRGB(17, 18, 21)
    Library.AccentColor     = Color3.fromRGB(96, 165, 250)
    Library.OutlineColor    = Color3.fromRGB(43, 45, 52)
    Library.FontColor       = Color3.fromRGB(239, 241, 245)
end)
local okWin, Window = pcall(function()
    return Library:CreateWindow({ Title='JewHook', Center=true, AutoShow=false, TabPadding=8,
        MenuFadeTime=0.2, NotifySide='Right', Resizable=true, UnlockMouseWhileOpen=true })
end)
if not okWin or not Window then warn("[JewHook] GUI window failed to build:", Window); return end
local Tabs = {
    Main     = Window:AddTab('Main'),
    Rage     = Window:AddTab('Rage'),
    ESP      = Window:AddTab('ESP'),
    Visuals  = Window:AddTab('Visuals'),
    World    = Window:AddTab('World'),
    Settings = Window:AddTab('Settings'),
}
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

