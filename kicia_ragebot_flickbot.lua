-- language: Lua 5.1 (Roblox exploit)
-- file:    kicia_ragebot_flickbot.lua
-- target:  Rivals (Roblox) — kiciahook framework extension
-- purpose: complete ragebot + flickbot with per-weapon sections
-- load:    AFTER kiciahook is running
-- global:  _G.KiciaRagebot  |  _G.KiciaRagebotCfg

-- ============================================================
--  UNLOAD GUARD
-- ============================================================
if getgenv().KiciaRagebotTab and getgenv().KiciaRagebotTab.Unload then
    pcall(getgenv().KiciaRagebotTab.Unload)
end
if not game:IsLoaded() then game.Loaded:Wait() end

-- ============================================================
--  MODULE TABLE
-- ============================================================
local RT = {
    connections = {},
    cleanups    = {},
    destroyed   = false,
}
getgenv().KiciaRagebotTab = RT

local function track(c)   RT.connections[#RT.connections + 1] = c; return c end
local function onUnload(f) RT.cleanups[#RT.cleanups + 1] = f end

-- ============================================================
--  SERVICES
-- ============================================================
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")

local lp  = Players.LocalPlayer
local cam = workspace.CurrentCamera

-- ============================================================
--  KICIA HANDLE  (wait up to 15 s)
-- ============================================================
local K, FC, MC
do
    local t0 = os.clock()
    repeat
        K = getgenv().KiciaRebuild
        if not K then task.wait(0.1) end
    until K or (os.clock() - t0 > 15)
    if not K then
        warn("[KiciaRagebot] KiciaRebuild not found — did kiciahook load?")
        return
    end
    -- cache controller references from kiciahook's service table
    local ok, sv = pcall(function() return getgenv().KiciaServices end)
    if ok and sv then
        FC = sv.FighterController
        MC = sv.MechanicsController
    end
    -- fallback: probe through kiciahook global
    if not FC then
        local ok2, fc = pcall(function()
            return K._services and K._services.FighterController
        end)
        if ok2 then FC = fc end
    end
end

-- ============================================================
--  CONFIG
-- ============================================================
local Cfg = {
    -- ── GLOBAL ───────────────────────────────────────────────
    Ragebot = {
        Enabled      = false,
        Keybind      = { State = false, Kind = "Always", Bind = nil,
                         ShowInList = true, Invisible = false },
        Stability    = 0.15,
        ShootFrames  = 1,
        PrioritizeHackers  = false,
        UtilizeHealthLead  = false,
        Weapons = {
            Priority = { "Primary", "Secondary", "Melee" },
            Enabled  = { Primary = true, Secondary = true, Melee = true },
            OnEmpty  = "SwapOrReload",
        },
        Evasion = {
            Mode   = "Off",
            Random = {
                AnchorFromCharacter = false,
                BaseRadius          = 100,
                RadiusRandomFactor  = 0.5,
            },
            ProjectileBreaker = {
                DepthForward              = { Min = 0,   Max = 4   },
                DepthForwardFrequency     = 5,
                DepthUp                   = { Min = 0,   Max = 5.5 },
                DepthUpFrequency          = 5,
                RepositionInterval        = 0.3,
                FallbackAnchorFromCharacter = false,
                FallbackBaseRadius          = 100,
                FallbackRadiusRandomFactor  = 0.5,
            },
            Translocate = { Offset = -5 },
        },
    },

    -- ── FLICKBOT ─────────────────────────────────────────────
    Flickbot = {
        Enabled            = false,
        Keybind            = { State = false, Kind = "Hold", Bind = Enum.KeyCode.F },
        TargetPart         = "Head",          -- Head / HumanoidRootPart
        FOV                = 90,
        SmoothTime         = 0.03,            -- seconds to reach target (0 = instant)
        ReturnAfterFlick   = false,           -- snap camera back after shot
        PredictionMultiplier = 0.85,
        HitchancePercent   = 100,
        FireOnFlick        = true,
        TriggerBot         = false,           -- auto-fire only when crosshair is on enemy
    },

    -- ── PER-WEAPON ───────────────────────────────────────────
    RagebotWeapon = {
        Melee = {
            Enabled            = true,
            ExtendRange        = { Enabled = false, Range = 10 },
            ReduceCooldown     = { Enabled = false, Percentage = 25 },
            AlwaysBackstab     = false,
            AutoSpin           = false,
            TargetPart         = "HumanoidRootPart",
            MaxEngageDistance  = 20,
        },
        Knife = {
            Enabled              = true,
            AutoThrow            = true,
            PredictionMultiplier = 0.9,
            ArcCompensation      = true,
            MaxThrowDistance     = 50,
            ReduceCooldown       = { Enabled = false, Percentage = 25 },
            TargetPart           = "Head",
        },
        Primary = {
            Enabled              = true,
            PredictionMultiplier = 0.9,
            TargetPart           = "Head",
            FOV                  = 90,
            HitchancePercent     = 100,
            ReduceFireCooldown   = { Enabled = false, Percentage = 25 },
            ReduceAimCooldown    = { Enabled = false, Percentage = 50 },
            NoSpread             = false,
            FullAuto             = false,
            SilentAim            = false,   -- fire without moving camera
        },
        Secondary = {
            Enabled              = true,
            PredictionMultiplier = 0.9,
            TargetPart           = "Head",
            FOV                  = 90,
            HitchancePercent     = 100,
            ReduceFireCooldown   = { Enabled = false, Percentage = 25 },
            ReduceAimCooldown    = { Enabled = false, Percentage = 50 },
            NoSpread             = false,
            FullAuto             = false,
            SilentAim            = false,
        },
    },
}
getgenv().KiciaRagebotCfg = Cfg

-- ============================================================
--  UTILITY
-- ============================================================
local function rawget2(t, k)
    local ok, v = pcall(rawget, t, k)
    return ok and v or nil
end

local function safeCall(fn, ...)
    local ok, r = pcall(fn, ...)
    return ok, r
end

local function isAlive(char)
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0 and char:FindFirstChild("HumanoidRootPart") ~= nil
end

-- ── Ping helper ───────────────────────────────────────────────
local function getPingSeconds()
    -- kiciahook sometimes stores ping on localPlayer network stats
    local stats = lp and lp:FindFirstChild("leaderstats")
    local pingVal = stats and stats:FindFirstChild("Ping")
    if pingVal then return pingVal.Value / 1000 end
    return 0.075  -- default 75 ms
end

-- ── Prediction ───────────────────────────────────────────────
local function predictedPos(part, multiplier, extraTime)
    local vel = part.AssemblyLinearVelocity
    local t   = getPingSeconds() * (multiplier or 1) + (extraTime or 0)
    return part.Position + vel * t
end

-- ── Arc compensation (thrown knife / projectile) ───────────────
local function arcCompensate(originPos, targetPos, projSpeed)
    projSpeed = projSpeed or 80
    local d    = targetPos - originPos
    local hDist = math.sqrt(d.X^2 + d.Z^2)
    local t     = hDist / projSpeed
    local drop  = 0.5 * workspace.Gravity * t^2
    return Vector3.new(targetPos.X, targetPos.Y + drop, targetPos.Z)
end

-- ── Hitchance roll ────────────────────────────────────────────
local function passHitchance(pct)
    return math.random(1, 100) <= (pct or 100)
end

-- ============================================================
--  ENEMY ENUMERATION
--  Priority 1: kiciahook FighterController (most reliable)
--  Priority 2: Players service fallback
-- ============================================================
local function getEnemies()
    local out     = {}
    local myTeam  = lp.Team

    -- attempt kiciahook fighter list first
    local fighters = FC and rawget2(FC, "Objects")
    if fighters and #fighters > 0 then
        for _, obj in ipairs(fighters) do
            local pl = rawget2(obj, "Player")
            if pl and pl ~= lp then
                local char = pl.Character
                if char and isAlive(char) then
                    local root = char:FindFirstChild("HumanoidRootPart")
                    local hum  = char:FindFirstChildOfClass("Humanoid")
                    if root and hum then
                        out[#out + 1] = {
                            player   = pl,
                            char     = char,
                            root     = root,
                            hum      = hum,
                            teamSame = myTeam and pl.Team == myTeam,
                        }
                    end
                end
            end
        end
        -- filter friendly fire
        local filtered = {}
        for _, e in ipairs(out) do
            if not e.teamSame then filtered[#filtered + 1] = e end
        end
        if #filtered > 0 then return filtered end
    end

    -- fallback: plain Players
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= lp then
            local sameTeam = myTeam and pl.Team == myTeam
            if not sameTeam then
                local char = pl.Character
                if char and isAlive(char) then
                    local root = char:FindFirstChild("HumanoidRootPart")
                    local hum  = char:FindFirstChildOfClass("Humanoid")
                    if root and hum then
                        out[#out + 1] = {
                            player = pl,
                            char   = char,
                            root   = root,
                            hum    = hum,
                        }
                    end
                end
            end
        end
    end
    return out
end

-- ============================================================
--  TARGET SELECTION
--  Returns best enemy {player, char, root, hum, aimPos}
-- ============================================================
local function getTargetPart(enemy, partName)
    if partName == "Head" then
        return enemy.char:FindFirstChild("Head") or enemy.root
    end
    return enemy.root
end

local function screenFOVRadius(fovDeg)
    -- convert world FOV degrees to screen-pixel radius at centre
    local halfRad = math.rad(fovDeg / 2)
    return math.tan(halfRad) * (cam.ViewportSize.Y * 0.5)
end

local function getBestTarget(originPos, fovDeg, maxDist, targetPartName, predMult)
    local best, bestScore = nil, math.huge
    local fovPx = screenFOVRadius(fovDeg)
    local cx    = cam.ViewportSize.X * 0.5
    local cy    = cam.ViewportSize.Y * 0.5

    for _, e in ipairs(getEnemies()) do
        local part = getTargetPart(e, targetPartName)
        local aimPos = predictedPos(part, predMult)

        local dist = (part.Position - originPos).Magnitude
        if dist <= maxDist then
            local sp, onScreen = cam:WorldToScreenPoint(aimPos)
            if onScreen then
                local dx = sp.X - cx
                local dy = sp.Y - cy
                local px = math.sqrt(dx*dx + dy*dy)
                if px <= fovPx then
                    -- score: pixel distance (lower = better)
                    local score = px
                    if score < bestScore then
                        bestScore = score
                        best = {
                            player  = e.player,
                            char    = e.char,
                            root    = e.root,
                            hum     = e.hum,
                            aimPos  = aimPos,
                            part    = part,
                            dist    = dist,
                            pxScore = px,
                        }
                    end
                end
            end
        end
    end
    return best
end

-- ============================================================
--  CAMERA AIM
-- ============================================================
local function snapCam(targetPos)
    cam.CFrame = CFrame.new(cam.CFrame.Position, targetPos)
end

-- Smooth aim using TweenService (short duration for ragebot feel)
local activeTween
local function smoothCam(targetPos, duration)
    if activeTween then activeTween:Cancel() end
    local newCF = CFrame.new(cam.CFrame.Position, targetPos)
    if duration <= 0.001 then
        cam.CFrame = newCF
        return
    end
    activeTween = TweenService:Create(cam,
        TweenInfo.new(duration, Enum.EasingStyle.Linear),
        { CFrame = newCF })
    activeTween:Play()
end

-- ============================================================
--  INPUT SIMULATION
--  Tries exploit API first, then kiciahook's SimulateInputBegan.
-- ============================================================
local function simulateMouse1Down()
    if mouse1press then
        pcall(mouse1press)
    end
end

local function simulateMouse1Up()
    if mouse1release then
        pcall(mouse1release)
    end
end

local function simulateClick()
    if mouse1click then
        pcall(mouse1click)
    else
        simulateMouse1Down()
        task.delay(0.05, simulateMouse1Up)
    end
end

-- kiciahook MechanicsController SimulateInputBegan path
local function simulateInputViaKicia(inputType)
    if not MC then return end
    local sim = rawget2(rawget2(getmetatable(MC), "__index"), "SimulateInputBegan")
    if sim then
        pcall(sim, MC, { UserInputType = inputType or Enum.UserInputType.MouseButton1 })
    end
end

-- ============================================================
--  WEAPON DETECTION
-- ============================================================
local KNIFE_NAMES   = { "knife" }
local MELEE_NAMES   = { "sword", "bat", "katana", "blade", "axe", "hammer",
                         "shuriken", "fan", "wrench", "fist" }
local MELEE_TAGS    = { "MeleeTag", "IsMelee" }
local GUN_TAGS      = { "GunTag", "IsGun", "Ammo", "AmmoCount" }

local function containsAny(str, list)
    str = str:lower()
    for _, v in ipairs(list) do
        if str:find(v, 1, true) then return true end
    end
    return false
end

local function detectWeapon(char)
    local tool = char and char:FindFirstChildOfClass("Tool")
    if not tool then return nil, nil end

    local name = tool.Name

    -- explicit attribute check first
    local isKnifeAttr = tool:GetAttribute("IsKnife") == true
    local isMeleeAttr = false
    local isGunAttr   = false
    for _, t in ipairs(MELEE_TAGS) do
        if tool:FindFirstChild(t) or tool:GetAttribute(t) == true then
            isMeleeAttr = true; break
        end
    end
    for _, t in ipairs(GUN_TAGS) do
        if tool:FindFirstChild(t) or tool:GetAttribute(t) ~= nil then
            isGunAttr = true; break
        end
    end

    if isKnifeAttr or containsAny(name, KNIFE_NAMES) then
        return tool, "Knife"
    end
    if isMeleeAttr or containsAny(name, MELEE_NAMES) then
        return tool, "Melee"
    end
    if isGunAttr then
        local slot = tool:GetAttribute("WeaponSlot")
        if slot == "Secondary" then return tool, "Secondary" end
        return tool, "Primary"
    end
    -- last resort: has Ammo child → gun
    if tool:FindFirstChild("Ammo") then
        local slot = tool:GetAttribute("WeaponSlot")
        return tool, (slot == "Secondary" and "Secondary" or "Primary")
    end
    return tool, "Melee"  -- unknown, assume melee
end

-- ============================================================
--  COOLDOWN REDUCTION
--  Scans the tool's ModuleScripts / RemoteFunctions for a
--  numeric cooldown upvalue and patches it.
-- ============================================================
local patchedCooldowns = {}  -- [tool] = { origVal, upvalIdx, fn }

local function patchToolCooldown(tool, pct)
    if patchedCooldowns[tool] then return end
    local multiplier = 1 - (pct / 100)
    -- scan descendants for a Script/LocalScript/ModuleScript
    for _, obj in ipairs(tool:GetDescendants()) do
        if obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
            -- try to find "cooldown" constant
            local fn = rawget2(obj, "main") or rawget2(obj, "fire")
            if fn and type(fn) == "function" then
                local consts = debug.getconstants(fn)
                for idx, v in pairs(consts) do
                    if type(v) == "number" and v > 0.05 and v < 5 then
                        -- likely a cooldown
                        local patched = v * multiplier
                        patchedCooldowns[tool] = {
                            fn = fn, idx = idx, orig = v
                        }
                        debug.setconstant(fn, idx, patched)
                        break
                    end
                end
            end
        end
        if patchedCooldowns[tool] then break end
    end
end

local function restoreToolCooldown(tool)
    local p = patchedCooldowns[tool]
    if p then
        pcall(debug.setconstant, p.fn, p.idx, p.orig)
        patchedCooldowns[tool] = nil
    end
end

-- ============================================================
--  NO SPREAD
-- ============================================================
local function applyNoSpread(tool)
    if not tool then return end
    -- try sethiddenproperty on SpreadAngle
    if sethiddenproperty then
        pcall(sethiddenproperty, tool, "SpreadAngle", Vector2.new(0, 0))
    end
    -- also try attribute
    pcall(function() tool:SetAttribute("SpreadAngle", 0) end)
    -- scan for spread upvalue
    for _, obj in ipairs(tool:GetDescendants()) do
        if obj:IsA("LocalScript") then
            local fn = rawget2(obj, "shoot") or rawget2(obj, "fire")
            if fn then
                local uvs = debug.getupvalues(fn)
                for k, v in pairs(uvs) do
                    if type(v) == "number" and tostring(k):lower():find("spread") then
                        pcall(debug.setupvalue, fn, k, 0)
                    end
                end
            end
        end
    end
end

-- ============================================================
--  TRIGGER BOT  (fires when crosshair is on enemy hitbox)
-- ============================================================
local function isCrosshairOnEnemy()
    local cx = cam.ViewportSize.X * 0.5
    local cy = cam.ViewportSize.Y * 0.5
    local ray = cam:ScreenPointToRay(cx, cy)
    local result = workspace:Raycast(ray.Origin, ray.Direction * 999,
        RaycastParams.new())
    if not result then return false end
    local hit = result.Instance
    -- walk up to find a player character
    local part = hit
    while part and part.Parent do
        local pl = Players:GetPlayerFromCharacter(part.Parent)
        if pl and pl ~= lp then
            return true
        end
        part = part.Parent
    end
    return false
end

-- ============================================================
--  FLICKBOT STATE
-- ============================================================
local flickActive      = false
local flickCooldown    = 0
local preFLickCF       = nil     -- saved camera CFrame before flick

local function doFlick(originPos)
    local fbCfg = Cfg.Flickbot
    if not fbCfg.Enabled then return end

    -- keybind check
    local kb = fbCfg.Keybind
    local held = false
    if kb.Kind == "Hold" and kb.Bind then
        held = UserInputService:IsKeyDown(kb.Bind)
    elseif kb.Kind == "Always" then
        held = true
    elseif kb.Kind == "Toggle" then
        held = flickActive
    end
    if not held then return end

    local target = getBestTarget(originPos, fbCfg.FOV,
        999, fbCfg.TargetPart, fbCfg.PredictionMultiplier)
    if not target then return end
    if not passHitchance(fbCfg.HitchancePercent) then return end

    -- save pre-flick camera
    if fbCfg.ReturnAfterFlick then
        preFLickCF = cam.CFrame
    end

    -- aim
    smoothCam(target.aimPos, fbCfg.SmoothTime)

    -- fire
    if fbCfg.FireOnFlick then
        task.delay(fbCfg.SmoothTime + 0.01, function()
            simulateClick()
            -- restore camera after shot
            if fbCfg.ReturnAfterFlick and preFLickCF then
                task.delay(0.08, function()
                    cam.CFrame = preFLickCF
                    preFLickCF = nil
                end)
            end
        end)
    end
end

-- ============================================================
--  TRIGGERBOT
-- ============================================================
local function doTriggerBot()
    local fbCfg = Cfg.Flickbot
    if not fbCfg.Enabled or not fbCfg.TriggerBot then return end
    if isCrosshairOnEnemy() then
        simulateClick()
    end
end

-- ============================================================
--  KNIFE RAGEBOT
-- ============================================================
local lastKnifeThrow = 0

local function doKnifeRagebot(tool, originPos)
    local kCfg = Cfg.RagebotWeapon.Knife
    if not kCfg.Enabled or not kCfg.AutoThrow then return end

    local now = os.clock()
    -- knife cooldown (Rivals default ≈ 1.5 s)
    local baseCd = 1.5
    if kCfg.ReduceCooldown.Enabled then
        baseCd = baseCd * (1 - kCfg.ReduceCooldown.Percentage / 100)
    end
    if now - lastKnifeThrow < baseCd then return end

    local target = getBestTarget(originPos, 180,
        kCfg.MaxThrowDistance, kCfg.TargetPart, kCfg.PredictionMultiplier)
    if not target then return end

    local aimPos = target.aimPos
    if kCfg.ArcCompensation then
        aimPos = arcCompensate(originPos, aimPos)
    end

    -- rotate camera
    snapCam(aimPos)

    -- fire (tool Activated event)
    pcall(function()
        -- try direct remote
        local remote = tool:FindFirstChildOfClass("RemoteEvent")
        if remote then
            remote:FireServer(cam.CFrame, cam.CFrame * CFrame.new(0, 0, -kCfg.MaxThrowDistance))
        end
    end)
    -- also simulate click
    simulateClick()
    lastKnifeThrow = now
end

-- ============================================================
--  MELEE RAGEBOT
-- ============================================================
local lastMeleeSwing = 0

local function doMeleeRagebot(tool, originPos, myRoot)
    local mCfg = Cfg.RagebotWeapon.Melee
    if not mCfg.Enabled then return end

    local now = os.clock()
    local baseCd = 0.6
    if mCfg.ReduceCooldown.Enabled then
        baseCd = baseCd * (1 - mCfg.ReduceCooldown.Percentage / 100)
        patchToolCooldown(tool, mCfg.ReduceCooldown.Percentage)
    end
    if now - lastMeleeSwing < baseCd then return end

    local target = getBestTarget(originPos, 360,
        mCfg.MaxEngageDistance, mCfg.TargetPart, 0)
    if not target then return end

    -- backstab assist: face away from enemy
    if mCfg.AlwaysBackstab and mCfg.AutoSpin then
        local toEnemy = (target.root.Position - myRoot.Position).Unit
        local backCF  = CFrame.new(myRoot.Position, myRoot.Position - toEnemy)
        if sethiddenproperty then
            pcall(sethiddenproperty, myRoot, "CFrame", backCF)
        end
    end

    -- extend range: move hitbox origin
    if mCfg.ExtendRange.Enabled then
        local dir    = (target.root.Position - originPos).Unit
        local newPos = originPos + dir * mCfg.ExtendRange.Range
        -- try attack remote with extended CFrame
        local remote = tool:FindFirstChildOfClass("RemoteEvent")
        if remote then
            local atkCF = CFrame.new(newPos, target.root.Position)
            pcall(function() remote:FireServer(atkCF, atkCF) end)
        end
    end

    -- aim camera and swing
    snapCam(target.part.Position)
    simulateClick()
    lastMeleeSwing = now
end

-- ============================================================
--  GUN RAGEBOT
-- ============================================================
local lastGunFire     = 0
local lastGunFireAnim = 0

local function doGunRagebot(tool, slot, originPos)
    local gCfg = Cfg.RagebotWeapon[slot]
    if not gCfg or not gCfg.Enabled then return end

    local now = os.clock()
    local baseCd = 0.1   -- tight inner loop, actual RPM limits game-side
    if gCfg.ReduceFireCooldown.Enabled then
        baseCd = baseCd * (1 - gCfg.ReduceFireCooldown.Percentage / 100)
        patchToolCooldown(tool, gCfg.ReduceFireCooldown.Percentage)
    end
    if now - lastGunFire < baseCd and not gCfg.FullAuto then return end

    local target = getBestTarget(originPos, gCfg.FOV,
        999, gCfg.TargetPart, gCfg.PredictionMultiplier)
    if not target then return end
    if not passHitchance(gCfg.HitchancePercent) then return end

    -- NoSpread
    if gCfg.NoSpread then
        applyNoSpread(tool)
    end

    -- SilentAim: patch camera upvalue so server sees our aim without moving visual cam
    if gCfg.SilentAim then
        -- cache current cam and temporarily override
        local origCF = cam.CFrame
        cam.CFrame   = CFrame.new(cam.CFrame.Position, target.aimPos)
        simulateClick()
        task.defer(function() cam.CFrame = origCF end)
    else
        -- normal aim
        smoothCam(target.aimPos, Cfg.Ragebot.Stability)
        task.delay(Cfg.Ragebot.Stability + 0.01, function()
            simulateClick()
        end)
    end

    lastGunFire = now
end

-- ============================================================
--  EVASION
-- ============================================================
local evasionTimer    = 0
local evasionInterval = 0.3
local pbPhaseForward  = 0
local pbPhaseUp       = 0

local function doEvasion(myRoot, dt)
    local evCfg = Cfg.Ragebot.Evasion
    local mode  = evCfg.Mode
    if mode == "Off" or mode == nil then return end

    evasionTimer = evasionTimer + dt
    if evasionTimer < evasionInterval then return end
    evasionTimer = 0

    local anchor = myRoot.Position

    if mode == "Random" then
        local rCfg  = evCfg.Random
        local base  = rCfg.BaseRadius
        local factor = rCfg.RadiusRandomFactor
        local r = base * (1 + (math.random() - 0.5) * 2 * factor)
        local angle = math.random() * 2 * math.pi
        local newPos = anchor + Vector3.new(
            math.cos(angle) * r,
            0,
            math.sin(angle) * r
        )
        if sethiddenproperty then
            pcall(sethiddenproperty, myRoot, "CFrame",
                CFrame.new(newPos, newPos + myRoot.CFrame.LookVector))
        end

    elseif mode == "Translocate" then
        local offset = evCfg.Translocate.Offset
        local newPos = anchor + Vector3.new(0, offset, 0)
        if sethiddenproperty then
            pcall(sethiddenproperty, myRoot, "CFrame", CFrame.new(newPos))
        end

    elseif mode == "ProjectileBreaker" then
        local pbCfg = evCfg.ProjectileBreaker
        evasionInterval = pbCfg.RepositionInterval
        pbPhaseForward  = pbPhaseForward + dt * pbCfg.DepthForwardFrequency
        pbPhaseUp       = pbPhaseUp      + dt * pbCfg.DepthUpFrequency

        local fwdMin  = pbCfg.DepthForward.Min
        local fwdMax  = pbCfg.DepthForward.Max
        local upMin   = pbCfg.DepthUp.Min
        local upMax   = pbCfg.DepthUp.Max

        local fwdD  = fwdMin + (fwdMax - fwdMin) * (0.5 + 0.5 * math.sin(pbPhaseForward))
        local upD   = upMin  + (upMax  - upMin ) * (0.5 + 0.5 * math.sin(pbPhaseUp))
        local look  = myRoot.CFrame.LookVector
        local newPos = anchor + look * fwdD + Vector3.new(0, upD, 0)
        if sethiddenproperty then
            pcall(sethiddenproperty, myRoot, "CFrame",
                CFrame.new(newPos, newPos + look))
        end
    end
end

-- ============================================================
--  MAIN HEARTBEAT
-- ============================================================
local function tick(dt)
    local rgCfg  = Cfg.Ragebot
    local fbCfg  = Cfg.Flickbot

    -- ragebot enabled check
    local ragebotOn = rgCfg.Enabled
    -- (keybind override omitted here — wire via kiciahook keybind system)

    local char = lp.Character
    if not char or not isAlive(char) then return end
    local myRoot = char:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    local originPos = myRoot.Position

    -- ── Evasion ──────────────────────────────────────────────
    if ragebotOn then
        doEvasion(myRoot, dt)
    end

    -- ── Weapon detection ─────────────────────────────────────
    local tool, weaponType = detectWeapon(char)

    -- ── Triggerbot (independent of ragebot toggle) ────────────
    doTriggerBot()

    -- ── Flickbot ─────────────────────────────────────────────
    doFlick(originPos)

    -- ── Ragebot per weapon ───────────────────────────────────
    if not ragebotOn then return end
    if not tool then return end

    if weaponType == "Knife" then
        doKnifeRagebot(tool, originPos)
    elseif weaponType == "Melee" then
        doMeleeRagebot(tool, originPos, myRoot)
    elseif weaponType == "Primary" or weaponType == "Secondary" then
        if rgCfg.Weapons.Enabled[weaponType == "Primary" and "Primary" or "Secondary"] then
            doGunRagebot(tool, weaponType, originPos)
        end
    end
end

track(RunService.Heartbeat:Connect(function(dt)
    pcall(tick, dt)
end))

-- ============================================================
--  UI TAB BUILDER
-- ============================================================
local function addKeybindRow(section, label, modes, cfgPath)
    if section.AddKeybind then
        section:AddKeybind({ Label = label, Modes = modes, Config = cfgPath })
    end
end

function RT.BuildTab(grid)
    assert(grid and grid.AddSection,
        "[KiciaRagebot] BuildTab: grid must be a kiciahook Grid node")

    -- ═══ LEFT COLUMN ═══════════════════════════════════════

    -- § Activation
    local act = grid:AddSection({ Title = "Activation", Side = "left" })
    addKeybindRow(act, "Enable Ragebot", {"Always","Toggle","Hold"}, {"Ragebot"})
    act:AddToggle({ Label = "Utilize Health Lead",
        Config = { "Ragebot", "UtilizeHealthLead" } })
    act:AddToggle({ Label = "Prioritize Hackers",
        Config = { "Ragebot", "PrioritizeHackers" } })
    act:AddSlider({ Label = "Stability", Min = 0, Max = 1, Step = 0.001,
        Config = { "Ragebot", "Stability" } })
    act:AddSlider({ Label = "Shoot Frames", Min = 1, Max = 50,
        Config = { "Ragebot", "ShootFrames" } })

    -- § Flickbot
    local fb = grid:AddSection({ Title = "Flickbot", Side = "left" })
    addKeybindRow(fb, "Enable Flickbot", {"Hold","Toggle","Always"}, {"Flickbot"})
    fb:AddDropdown({ Label  = "Target Part",
        Options = { "Head", "HumanoidRootPart" },
        Config  = { "Flickbot", "TargetPart" } })
    fb:AddSlider({ Label = "FOV", Min = 1, Max = 360,
        Config = { "Flickbot", "FOV" } })
    fb:AddSlider({ Label = "Smooth Time (s)", Min = 0, Max = 0.3, Step = 0.005,
        Config = { "Flickbot", "SmoothTime" } })
    fb:AddSlider({ Label = "Prediction Multiplier", Min = 0, Max = 1, Step = 0.01,
        Config = { "Flickbot", "PredictionMultiplier" } })
    fb:AddSlider({ Label = "Hitchance %", Min = 1, Max = 100,
        Config = { "Flickbot", "HitchancePercent" } })
    fb:AddToggle({ Label = "Fire On Flick",
        Config = { "Flickbot", "FireOnFlick" } })
    fb:AddToggle({ Label = "Return After Flick",
        Config = { "Flickbot", "ReturnAfterFlick" } })
    fb:AddToggle({ Label = "Triggerbot",
        Config = { "Flickbot", "TriggerBot" } })

    -- § Weapon Strategy
    local ws = grid:AddSection({ Title = "Weapon Strategy", Side = "left" })
    for _, cat in ipairs({ "Primary", "Secondary", "Melee" }) do
        ws:AddToggle({ Label = cat .. " Enabled",
            Config = { "Ragebot", "Weapons", "Enabled", cat } })
    end
    ws:AddOrderedList({ Label   = "Weapon Priority",
        Items   = { "Primary","Secondary","Melee" },
        Default = { "Primary","Secondary","Melee" },
        Config  = { "Ragebot", "Weapons", "Priority" } })
    ws:AddDropdown({ Label   = "On Empty",
        Options = { "Reload","Swap","SwapOrReload" },
        Labels  = { SwapOrReload = "Swap or Reload" },
        Config  = { "Ragebot", "Weapons", "OnEmpty" } })

    -- § Melee
    local ms = grid:AddSection({ Title = "Melee", Side = "left" })
    ms:AddToggle({ Label = "Enabled",
        Config = { "RagebotWeapon", "Melee", "Enabled" } })
    ms:AddDropdown({ Label = "Target Part",
        Options = { "HumanoidRootPart", "Head" },
        Config  = { "RagebotWeapon", "Melee", "TargetPart" } })
    ms:AddSlider({ Label = "Max Engage Distance", Min = 5, Max = 60,
        Config = { "RagebotWeapon", "Melee", "MaxEngageDistance" } })
    ms:AddToggle({ Label = "Always Backstab",
        Config = { "RagebotWeapon", "Melee", "AlwaysBackstab" } })
    ms:AddToggle({ Label = "Auto Spin (backstab assist)",
        Config = { "RagebotWeapon", "Melee", "AutoSpin" } })

    local mExt = ms:AddToggle({ Label = "Extend Melee Range",
        Config = { "RagebotWeapon", "Melee", "ExtendRange", "Enabled" } })
    ms:AddGroup({ Source = mExt, Option = true })
        :AddSlider({ Label = "Extra Range", Min = 1, Max = 30,
            Config = { "RagebotWeapon", "Melee", "ExtendRange", "Range" } })

    local mCd = ms:AddToggle({ Label = "Reduce Cooldown",
        Config = { "RagebotWeapon", "Melee", "ReduceCooldown", "Enabled" } })
    ms:AddGroup({ Source = mCd, Option = true })
        :AddSlider({ Label = "Cooldown %", Min = 1, Max = 99,
            Config = { "RagebotWeapon", "Melee", "ReduceCooldown", "Percentage" } })

    -- § Knife
    local ks = grid:AddSection({ Title = "Knife", Side = "left" })
    ks:AddToggle({ Label = "Enabled",
        Config = { "RagebotWeapon", "Knife", "Enabled" } })
    ks:AddToggle({ Label = "Auto Throw",
        Config = { "RagebotWeapon", "Knife", "AutoThrow" } })
    ks:AddDropdown({ Label = "Target Part",
        Options = { "Head", "HumanoidRootPart" },
        Config  = { "RagebotWeapon", "Knife", "TargetPart" } })
    ks:AddSlider({ Label = "Prediction Multiplier", Min = 0, Max = 1, Step = 0.01,
        Config = { "RagebotWeapon", "Knife", "PredictionMultiplier" } })
    ks:AddToggle({ Label = "Arc Compensation",
        Config = { "RagebotWeapon", "Knife", "ArcCompensation" } })
    ks:AddSlider({ Label = "Max Throw Distance", Min = 10, Max = 120,
        Config = { "RagebotWeapon", "Knife", "MaxThrowDistance" } })
    local kCd = ks:AddToggle({ Label = "Reduce Cooldown",
        Config = { "RagebotWeapon", "Knife", "ReduceCooldown", "Enabled" } })
    ks:AddGroup({ Source = kCd, Option = true })
        :AddSlider({ Label = "Cooldown %", Min = 1, Max = 99,
            Config = { "RagebotWeapon", "Knife", "ReduceCooldown", "Percentage" } })

    -- ═══ RIGHT COLUMN ══════════════════════════════════════

    -- § Evasion
    local ev = grid:AddSection({ Title = "Evasion", Side = "right" })
    local evDrop = ev:AddDropdown({ Label = "Mode",
        Options = { "Off","Random","Translocate","ProjectileBreaker" },
        Labels  = { ProjectileBreaker = "Projectile Breaker" },
        Config  = { "Ragebot", "Evasion", "Mode" } })

    local rndG = ev:AddGroup({ Source = evDrop, Option = "Random" })
    rndG:AddToggle({ Label = "Character Origin",
        Config = { "Ragebot","Evasion","Random","AnchorFromCharacter" } })
    rndG:AddSlider({ Label = "Base Radius", Min = 5, Max = 1e9,
        Config = { "Ragebot","Evasion","Random","BaseRadius" } })
    rndG:AddSlider({ Label = "Random Factor", Min = 0, Max = 1, Step = 0.01,
        Config = { "Ragebot","Evasion","Random","RadiusRandomFactor" } })

    ev:AddGroup({ Source = evDrop, Option = "Translocate" })
        :AddSlider({ Label = "Offset", Min = -20, Max = 20, Step = 0.1,
            Config = { "Ragebot","Evasion","Translocate","Offset" } })

    local pbG = ev:AddGroup({ Source = evDrop, Option = "ProjectileBreaker" })
    pbG:AddRangeSlider({ Label = "Forward Depth", Min = 0, Max = 10, Step = 0.1,
        Config = { "Ragebot","Evasion","ProjectileBreaker","DepthForward" } })
    pbG:AddSlider({ Label = "Forward Frequency", Min = 0, Max = 20, Step = 0.1,
        Config = { "Ragebot","Evasion","ProjectileBreaker","DepthForwardFrequency" } })
    pbG:AddRangeSlider({ Label = "Upward Depth", Min = 0, Max = 10, Step = 0.1,
        Config = { "Ragebot","Evasion","ProjectileBreaker","DepthUp" } })
    pbG:AddSlider({ Label = "Upward Frequency", Min = 0, Max = 20, Step = 0.1,
        Config = { "Ragebot","Evasion","ProjectileBreaker","DepthUpFrequency" } })
    pbG:AddSlider({ Label = "Reposition Interval (s)", Min = 0.05, Max = 2, Step = 0.01,
        Config = { "Ragebot","Evasion","ProjectileBreaker","RepositionInterval" } })
    pbG:AddToggle({ Label = "Fallback Character Origin",
        Config = { "Ragebot","Evasion","ProjectileBreaker","FallbackAnchorFromCharacter" } })
    pbG:AddSlider({ Label = "Fallback Radius", Min = 5, Max = 1e8,
        Config = { "Ragebot","Evasion","ProjectileBreaker","FallbackBaseRadius" } })
    pbG:AddSlider({ Label = "Fallback Random Factor", Min = 0, Max = 1, Step = 0.01,
        Config = { "Ragebot","Evasion","ProjectileBreaker","FallbackRadiusRandomFactor" } })

    -- § Primary
    local ps = grid:AddSection({ Title = "Primary (Gun)", Side = "right" })
    ps:AddToggle({ Label = "Enabled",
        Config = { "RagebotWeapon","Primary","Enabled" } })
    ps:AddDropdown({ Label = "Target Part",
        Options = { "Head","HumanoidRootPart" },
        Config  = { "RagebotWeapon","Primary","TargetPart" } })
    ps:AddSlider({ Label = "FOV", Min = 1, Max = 360,
        Config = { "RagebotWeapon","Primary","FOV" } })
    ps:AddSlider({ Label = "Hitchance %", Min = 1, Max = 100,
        Config = { "RagebotWeapon","Primary","HitchancePercent" } })
    ps:AddSlider({ Label = "Prediction Multiplier", Min = 0, Max = 1, Step = 0.01,
        Config = { "RagebotWeapon","Primary","PredictionMultiplier" } })
    ps:AddToggle({ Label = "No Spread",
        Config = { "RagebotWeapon","Primary","NoSpread" } })
    ps:AddToggle({ Label = "Full Auto",
        Config = { "RagebotWeapon","Primary","FullAuto" } })
    ps:AddToggle({ Label = "Silent Aim",
        Config = { "RagebotWeapon","Primary","SilentAim" } })

    local pFCd = ps:AddToggle({ Label = "Reduce Fire Cooldown",
        Config = { "RagebotWeapon","Primary","ReduceFireCooldown","Enabled" } })
    ps:AddGroup({ Source = pFCd, Option = true })
        :AddSlider({ Label = "Fire Cooldown %", Min = 1, Max = 99,
            Config = { "RagebotWeapon","Primary","ReduceFireCooldown","Percentage" } })
    local pACd = ps:AddToggle({ Label = "Reduce Aim Cooldown",
        Config = { "RagebotWeapon","Primary","ReduceAimCooldown","Enabled" } })
    ps:AddGroup({ Source = pACd, Option = true })
        :AddSlider({ Label = "Aim Cooldown %", Min = 1, Max = 99,
            Config = { "RagebotWeapon","Primary","ReduceAimCooldown","Percentage" } })

    -- § Secondary
    local ss = grid:AddSection({ Title = "Secondary (Gun)", Side = "right" })
    ss:AddToggle({ Label = "Enabled",
        Config = { "RagebotWeapon","Secondary","Enabled" } })
    ss:AddDropdown({ Label = "Target Part",
        Options = { "Head","HumanoidRootPart" },
        Config  = { "RagebotWeapon","Secondary","TargetPart" } })
    ss:AddSlider({ Label = "FOV", Min = 1, Max = 360,
        Config = { "RagebotWeapon","Secondary","FOV" } })
    ss:AddSlider({ Label = "Hitchance %", Min = 1, Max = 100,
        Config = { "RagebotWeapon","Secondary","HitchancePercent" } })
    ss:AddSlider({ Label = "Prediction Multiplier", Min = 0, Max = 1, Step = 0.01,
        Config = { "RagebotWeapon","Secondary","PredictionMultiplier" } })
    ss:AddToggle({ Label = "No Spread",
        Config = { "RagebotWeapon","Secondary","NoSpread" } })
    ss:AddToggle({ Label = "Full Auto",
        Config = { "RagebotWeapon","Secondary","FullAuto" } })
    ss:AddToggle({ Label = "Silent Aim",
        Config = { "RagebotWeapon","Secondary","SilentAim" } })

    local sFCd = ss:AddToggle({ Label = "Reduce Fire Cooldown",
        Config = { "RagebotWeapon","Secondary","ReduceFireCooldown","Enabled" } })
    ss:AddGroup({ Source = sFCd, Option = true })
        :AddSlider({ Label = "Fire Cooldown %", Min = 1, Max = 99,
            Config = { "RagebotWeapon","Secondary","ReduceFireCooldown","Percentage" } })
    local sACd = ss:AddToggle({ Label = "Reduce Aim Cooldown",
        Config = { "RagebotWeapon","Secondary","ReduceAimCooldown","Enabled" } })
    ss:AddGroup({ Source = sACd, Option = true })
        :AddSlider({ Label = "Aim Cooldown %", Min = 1, Max = 99,
            Config = { "RagebotWeapon","Secondary","ReduceAimCooldown","Percentage" } })
end

-- ============================================================
--  QUICK-TOGGLE API  (call from outside without full UI)
-- ============================================================
RT.Toggle = function(state)
    Cfg.Ragebot.Enabled = (state == nil) and not Cfg.Ragebot.Enabled or state
    print("[KiciaRagebot] Ragebot:", Cfg.Ragebot.Enabled and "ON" or "OFF")
end

RT.FlickToggle = function(state)
    Cfg.Flickbot.Enabled = (state == nil) and not Cfg.Flickbot.Enabled or state
    print("[KiciaRagebot] Flickbot:", Cfg.Flickbot.Enabled and "ON" or "OFF")
end

RT.SetFlickerKey = function(key)
    Cfg.Flickbot.Keybind.Bind = key
end

-- ============================================================
--  UNLOAD
-- ============================================================
RT.Unload = function()
    if RT.destroyed then return end
    RT.destroyed = true
    for _, c in ipairs(RT.connections) do pcall(function() c:Disconnect() end) end
    for _, f in ipairs(RT.cleanups)    do pcall(f) end
    if activeTween then activeTween:Cancel() end
    -- restore patched cooldowns
    for tool in pairs(patchedCooldowns) do
        restoreToolCooldown(tool)
    end
    table.clear(RT.connections)
    table.clear(RT.cleanups)
    getgenv().KiciaRagebotTab = nil
    getgenv().KiciaRagebotCfg = nil
    print("[KiciaRagebot] unloaded")
end

-- ============================================================
--  USAGE
-- ============================================================
--[[
  ── ATTACH TO KICIAHOOK TAB ─────────────────────────────────
  Inside the Combat tab builder in kiciahook, replace or extend
  the ragebot grid block with:

      local rgGrid = CombatTab:AddTab({
          Label       = "Ragebot",
          Icon        = S.Ragebot,
          Description = "Per-weapon ragebot · Melee · Knife · Primary · Secondary",
      }):Grid({ Columns = 2 })

      loadstring(game:HttpGet("...kicia_ragebot_flickbot.lua"))()
      getgenv().KiciaRagebotTab.BuildTab(rgGrid)

  ── STANDALONE (no UI) ──────────────────────────────────────
  loadstring(game:HttpGet("...kicia_ragebot_flickbot.lua"))()

  -- Toggle ragebot on
  getgenv().KiciaRagebotTab.Toggle(true)

  -- Toggle flickbot on, bind to G key, hold mode
  local RT = getgenv().KiciaRagebotTab
  RT.FlickToggle(true)
  RT.SetFlickerKey(Enum.KeyCode.G)
  getgenv().KiciaRagebotCfg.Flickbot.Keybind.Kind = "Hold"

  ── LIVE CONFIG ACCESS ───────────────────────────────────────
  local Cfg = getgenv().KiciaRagebotCfg

  -- change prediction on the fly:
  Cfg.RagebotWeapon.Primary.PredictionMultiplier = 0.95
  Cfg.Flickbot.SmoothTime = 0.0   -- instant flick

  -- enable silent aim for secondary:
  Cfg.RagebotWeapon.Secondary.SilentAim = true
]]

print("[KiciaRagebot] loaded — Ragebot + Flickbot ready")
print("  Ragebot:  getgenv().KiciaRagebotTab.Toggle(true)")
print("  Flickbot: getgenv().KiciaRagebotTab.FlickToggle(true)")-- language: Lua 5.1 (Roblox exploit), file: kicia_ragebot_tab.lua
-- target: Rivals (Roblox) — kiciahook framework extension
-- purpose: standalone ragebot tab with per-weapon sections (Melee, Knife, Primary, Secondary)
-- load AFTER kiciahook is running; access via _G.KiciaRagebot
-- *all config keys match the keys kiciahook's engine reads at runtime*

-- ============================================================
--  UNLOAD GUARD
-- ============================================================
if getgenv().KiciaRagebotTab and getgenv().KiciaRagebotTab.Unload then
    pcall(getgenv().KiciaRagebotTab.Unload)
end
if not game:IsLoaded() then game.Loaded:Wait() end

local RT = { connections = {}, cleanups = {}, destroyed = false }
getgenv().KiciaRagebotTab = RT

-- ============================================================
--  SERVICES
-- ============================================================
local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local lp            = Players.LocalPlayer

-- ============================================================
--  KICIA HANDLE  (wait up to 10 s for the parent script)
-- ============================================================
local K
do
    local t0 = os.clock()
    repeat
        K = getgenv().KiciaRebuild
        if not K then task.wait(0.1) end
    until K or (os.clock() - t0 > 10)
    if not K then
        warn("[KiciaRagebotTab] KiciaRebuild not found — did kiciahook load?")
        return
    end
end

local function track(c) RT.connections[#RT.connections + 1] = c; return c end
local function onUnload(f) RT.cleanups[#RT.cleanups + 1] = f end

-- ============================================================
--  CONFIG  — mirrors kiciahook's Ragebot block + per-weapon extensions
--  Keys under ["Ragebot"] are the exact paths the engine reads.
--  Keys under ["RagebotWeapon"] are read only by THIS module's
--  extended behaviours (cooldown overrides, knife arc, etc.).
-- ============================================================
local Cfg = {
    -- ── GLOBAL RAGEBOT  (identical to what kiciahook stores in be.c.Ragebot)
    Ragebot = {
        Enabled     = false,
        Keybind     = { State = false, Kind = "Always", Bind = nil,
                        ShowInList = true, Invisible = false },
        Stability   = 0.15,
        ShootFrames = 1,
        PrioritizeHackers = false,
        UtilizeHealthLead = false,
        Weapons = {
            Priority = { "Primary", "Secondary", "Melee" },
            Enabled  = { Primary = true, Secondary = true, Melee = true },
            OnEmpty  = "SwapOrReload",
        },
        Evasion = {
            Mode   = "Random",
            Random = {
                AnchorFromCharacter = false,
                BaseRadius          = 100,
                RadiusRandomFactor  = 0.5,
            },
            ProjectileBreaker = {
                DepthForward              = { Min = 0,   Max = 4   },
                DepthForwardFrequency     = 5,
                DepthUp                   = { Min = 0,   Max = 5.5 },
                DepthUpFrequency          = 5,
                RepositionInterval        = 0.3,
                FallbackAnchorFromCharacter = false,
                FallbackBaseRadius          = 100,
                FallbackRadiusRandomFactor  = 0.5,
            },
            Translocate = { Offset = -5 },
        },
    },

    -- ── PER-WEAPON EXTENSIONS  (read only by this module)
    RagebotWeapon = {
        -- Melee (sword, bat, katana — all __type == "Melee" except Knife)
        Melee = {
            Enabled            = true,
            ExtendRange        = { Enabled = false, Range = 10 },
            ReduceCooldown     = { Enabled = false, Percentage = 25 },
            AlwaysBackstab     = false,
            AutoSpin           = false,     -- continuous spin to land backstab
            TargetPart         = "HumanoidRootPart",  -- HumanoidRootPart / Head
            MaxEngageDistance  = 20,
        },

        -- Knife (FindMeleeByName("Knife") — throwable projectile)
        Knife = {
            Enabled            = true,
            AutoThrow          = true,
            PredictionMultiplier = 0.9,    -- 0-1 scale; 1 = full velocity lead
            ArcCompensation    = true,      -- vertical drop correction
            MaxThrowDistance   = 50,
            ReduceCooldown     = { Enabled = false, Percentage = 25 },
            TargetPart         = "Head",    -- Head / HumanoidRootPart
        },

        -- Primary (guns — __type == "Gun", slot "Primary")
        Primary = {
            Enabled            = true,
            PredictionMultiplier = 0.9,
            TargetPart         = "Head",
            FOV                = 90,
            HitchancePercent   = 100,
            ReduceFireCooldown = { Enabled = false, Percentage = 25 },
            ReduceAimCooldown  = { Enabled = false, Percentage = 50 },
            NoSpread           = false,
            FullAuto           = false,
        },

        -- Secondary (pistols, sub-guns — slot "Secondary")
        Secondary = {
            Enabled            = true,
            PredictionMultiplier = 0.9,
            TargetPart         = "Head",
            FOV                = 90,
            HitchancePercent   = 100,
            ReduceFireCooldown = { Enabled = false, Percentage = 25 },
            ReduceAimCooldown  = { Enabled = false, Percentage = 50 },
            NoSpread           = false,
            FullAuto           = false,
        },
    },
}

-- expose to global so kiciahook's config system can read/write it
getgenv().KiciaRagebotCfg = Cfg

-- ============================================================
--  UI TAB BUILDER
--  Call  RT.BuildTab(gridNode)  where gridNode is the 2-column
--  grid returned by  ragebotTab:Grid({Columns=2})  from kiciahook.
--  Mirrors the exact kiciahook section/group API found in fn35 @59557.
-- ============================================================

-- Helper: create a keybind-enable row (matches kiciahook h6() helper)
local function addKeybindRow(section, label, modes, cfgPath)
    if section.AddKeybind then
        section:AddKeybind({ Label = label, Modes = modes, Config = cfgPath })
    end
end

function RT.BuildTab(grid)
    assert(grid and grid.AddSection, "[KiciaRagebotTab] BuildTab: grid must be a kiciahook Grid node")

    -- ── LEFT COLUMN ──────────────────────────────────────────

    -- § Activation
    local activation = grid:AddSection({ Title = "Activation", Side = "left" })
    addKeybindRow(activation, "Enable Ragebot", { "Always", "Toggle", "Hold" }, { "Ragebot" })
    activation:AddToggle({ Label = "Utilize Health Lead",
        Config = { "Ragebot", "UtilizeHealthLead" } })
    activation:AddToggle({ Label = "Prioritize Hackers",
        Config = { "Ragebot", "PrioritizeHackers" } })
    activation:AddSlider({ Label = "Stability", Min = 0, Max = 5, Step = 0.001,
        Config = { "Ragebot", "Stability" } })
    activation:AddSlider({ Label = "Shoot Frames", Min = 1, Max = 50,
        Config = { "Ragebot", "ShootFrames" } })

    -- § Weapon Strategy
    local weapStrat = grid:AddSection({ Title = "Weapon Strategy", Side = "left" })
    local cats = { "Primary", "Secondary", "Melee" }
    for _, cat in ipairs(cats) do
        weapStrat:AddToggle({ Label = cat .. " Enabled",
            Config = { "Ragebot", "Weapons", "Enabled", cat } })
    end
    weapStrat:AddOrderedList({ Label = "Weapon Priority", Items = cats,
        Default = cats, Config = { "Ragebot", "Weapons", "Priority" } })
    weapStrat:AddDropdown({ Label = "On Empty",
        Options = { "Reload", "Swap", "SwapOrReload" },
        Labels = { SwapOrReload = "Swap or Reload" },
        Config = { "Ragebot", "Weapons", "OnEmpty" } })

    -- § Melee Weapon
    local meleeSection = grid:AddSection({ Title = "Melee", Side = "left" })
    meleeSection:AddToggle({ Label = "Melee Ragebot Enabled",
        Config = { "RagebotWeapon", "Melee", "Enabled" } })
    meleeSection:AddDropdown({ Label = "Target Part",
        Options = { "HumanoidRootPart", "Head" },
        Config = { "RagebotWeapon", "Melee", "TargetPart" } })
    meleeSection:AddSlider({ Label = "Max Engage Distance", Min = 5, Max = 60,
        Config = { "RagebotWeapon", "Melee", "MaxEngageDistance" } })

    local extRange = meleeSection:AddToggle({ Label = "Extend Melee Range",
        Config = { "RagebotWeapon", "Melee", "ExtendRange", "Enabled" } })
    meleeSection:AddGroup({ Source = extRange, Option = true })
        :AddSlider({ Label = "Extra Range", Min = 1, Max = 30,
            Config = { "RagebotWeapon", "Melee", "ExtendRange", "Range" } })

    local meleeCdToggle = meleeSection:AddToggle({ Label = "Reduce Melee Cooldown",
        Config = { "RagebotWeapon", "Melee", "ReduceCooldown", "Enabled" } })
    meleeSection:AddGroup({ Source = meleeCdToggle, Option = true })
        :AddSlider({ Label = "Cooldown %", Min = 1, Max = 100,
            Config = { "RagebotWeapon", "Melee", "ReduceCooldown", "Percentage" } })

    meleeSection:AddToggle({ Label = "Always Backstab",
        Config = { "RagebotWeapon", "Melee", "AlwaysBackstab" } })
    meleeSection:AddToggle({ Label = "Auto Spin (backstab assist)",
        Config = { "RagebotWeapon", "Melee", "AutoSpin" } })

    -- § Knife
    local knifeSection = grid:AddSection({ Title = "Knife", Side = "left" })
    knifeSection:AddToggle({ Label = "Knife Ragebot Enabled",
        Config = { "RagebotWeapon", "Knife", "Enabled" } })
    knifeSection:AddToggle({ Label = "Auto Throw",
        Config = { "RagebotWeapon", "Knife", "AutoThrow" } })
    knifeSection:AddDropdown({ Label = "Target Part",
        Options = { "Head", "HumanoidRootPart" },
        Config = { "RagebotWeapon", "Knife", "TargetPart" } })
    knifeSection:AddSlider({ Label = "Prediction Multiplier", Min = 0, Max = 1,
        Step = 0.01, Config = { "RagebotWeapon", "Knife", "PredictionMultiplier" } })
    knifeSection:AddToggle({ Label = "Arc Compensation",
        Config = { "RagebotWeapon", "Knife", "ArcCompensation" } })
    knifeSection:AddSlider({ Label = "Max Throw Distance", Min = 10, Max = 120,
        Config = { "RagebotWeapon", "Knife", "MaxThrowDistance" } })

    local knifeCdToggle = knifeSection:AddToggle({ Label = "Reduce Cooldown",
        Config = { "RagebotWeapon", "Knife", "ReduceCooldown", "Enabled" } })
    knifeSection:AddGroup({ Source = knifeCdToggle, Option = true })
        :AddSlider({ Label = "Cooldown %", Min = 1, Max = 100,
            Config = { "RagebotWeapon", "Knife", "ReduceCooldown", "Percentage" } })

    -- ── RIGHT COLUMN ─────────────────────────────────────────

    -- § Evasion
    local evasionSection = grid:AddSection({ Title = "Evasion", Side = "right" })
    local evasionDrop = evasionSection:AddDropdown({ Label = "Evasion Mode",
        Options = { "Off", "Random", "Translocate", "ProjectileBreaker" },
        Labels = { ProjectileBreaker = "Projectile Breaker" },
        Config = { "Ragebot", "Evasion", "Mode" } })

    local randomGroup = evasionSection:AddGroup({ Source = evasionDrop, Option = "Random" })
    randomGroup:AddToggle({ Label = "Character Origin",
        Config = { "Ragebot", "Evasion", "Random", "AnchorFromCharacter" } })
    randomGroup:AddSlider({ Label = "Base Radius", Min = 5, Max = 100000000000,
        Config = { "Ragebot", "Evasion", "Random", "BaseRadius" } })
    randomGroup:AddSlider({ Label = "Random Factor", Min = 0, Max = 500, Step = 0.1,
        Config = { "Ragebot", "Evasion", "Random", "RadiusRandomFactor" } })

    evasionSection:AddGroup({ Source = evasionDrop, Option = "Translocate" })
        :AddSlider({ Label = "Offset", Min = -5, Max = 5, Step = 0.1,
            Config = { "Ragebot", "Evasion", "Translocate", "Offset" } })

    local pbGroup = evasionSection:AddGroup({ Source = evasionDrop, Option = "ProjectileBreaker" })
    pbGroup:AddRangeSlider({ Label = "Forward Depth", Min = 0, Max = 10, Step = 0.1,
        Config = { "Ragebot", "Evasion", "ProjectileBreaker", "DepthForward" } })
    pbGroup:AddSlider({ Label = "Forward Frequency", Min = 0, Max = 20, Step = 0.1,
        Config = { "Ragebot", "Evasion", "ProjectileBreaker", "DepthForwardFrequency" } })
    pbGroup:AddRangeSlider({ Label = "Upward Depth", Min = 0, Max = 10, Step = 0.1,
        Config = { "Ragebot", "Evasion", "ProjectileBreaker", "DepthUp" } })
    pbGroup:AddSlider({ Label = "Upward Frequency", Min = 0, Max = 20, Step = 0.1,
        Config = { "Ragebot", "Evasion", "ProjectileBreaker", "DepthUpFrequency" } })
    pbGroup:AddSlider({ Label = "Reposition Interval (s)", Min = 0.05, Max = 2, Step = 0.01,
        Config = { "Ragebot", "Evasion", "ProjectileBreaker", "RepositionInterval" } })
    pbGroup:AddToggle({ Label = "Fallback Character Origin",
        Config = { "Ragebot", "Evasion", "ProjectileBreaker", "FallbackAnchorFromCharacter" } })
    pbGroup:AddSlider({ Label = "Fallback Radius", Min = 5, Max = 100000000,
        Config = { "Ragebot", "Evasion", "ProjectileBreaker", "FallbackBaseRadius" } })
    pbGroup:AddSlider({ Label = "Fallback Random Factor", Min = 0, Max = 1, Step = 0.1,
        Config = { "Ragebot", "Evasion", "ProjectileBreaker", "FallbackRadiusRandomFactor" } })

    -- § Primary Gun
    local primarySection = grid:AddSection({ Title = "Primary (Gun)", Side = "right" })
    primarySection:AddToggle({ Label = "Primary Ragebot Enabled",
        Config = { "RagebotWeapon", "Primary", "Enabled" } })
    primarySection:AddDropdown({ Label = "Target Part",
        Options = { "Head", "HumanoidRootPart" },
        Config = { "RagebotWeapon", "Primary", "TargetPart" } })
    primarySection:AddSlider({ Label = "FOV", Min = 1, Max = 360,
        Config = { "RagebotWeapon", "Primary", "FOV" } })
    primarySection:AddSlider({ Label = "Hitchance %", Min = 1, Max = 100,
        Config = { "RagebotWeapon", "Primary", "HitchancePercent" } })
    primarySection:AddSlider({ Label = "Prediction Multiplier", Min = 0, Max = 1,
        Step = 0.01, Config = { "RagebotWeapon", "Primary", "PredictionMultiplier" } })
    primarySection:AddToggle({ Label = "No Spread",
        Config = { "RagebotWeapon", "Primary", "NoSpread" } })
    primarySection:AddToggle({ Label = "Full Auto",
        Config = { "RagebotWeapon", "Primary", "FullAuto" } })

    local pFireCdToggle = primarySection:AddToggle({ Label = "Reduce Fire Cooldown",
        Config = { "RagebotWeapon", "Primary", "ReduceFireCooldown", "Enabled" } })
    primarySection:AddGroup({ Source = pFireCdToggle, Option = true })
        :AddSlider({ Label = "Fire Cooldown %", Min = 1, Max = 100,
            Config = { "RagebotWeapon", "Primary", "ReduceFireCooldown", "Percentage" } })

    local pAimCdToggle = primarySection:AddToggle({ Label = "Reduce Aim Cooldown",
        Config = { "RagebotWeapon", "Primary", "ReduceAimCooldown", "Enabled" } })
    primarySection:AddGroup({ Source = pAimCdToggle, Option = true })
        :AddSlider({ Label = "Aim Cooldown %", Min = 1, Max = 100,
            Config = { "RagebotWeapon", "Primary", "ReduceAimCooldown", "Percentage" } })

    -- § Secondary Gun
    local secondarySection = grid:AddSection({ Title = "Secondary (Gun)", Side = "right" })
    secondarySection:AddToggle({ Label = "Secondary Ragebot Enabled",
        Config = { "RagebotWeapon", "Secondary", "Enabled" } })
    secondarySection:AddDropdown({ Label = "Target Part",
        Options = { "Head", "HumanoidRootPart" },
        Config = { "RagebotWeapon", "Secondary", "TargetPart" } })
    secondarySection:AddSlider({ Label = "FOV", Min = 1, Max = 360,
        Config = { "RagebotWeapon", "Secondary", "FOV" } })
    secondarySection:AddSlider({ Label = "Hitchance %", Min = 1, Max = 100,
        Config = { "RagebotWeapon", "Secondary", "HitchancePercent" } })
    secondarySection:AddSlider({ Label = "Prediction Multiplier", Min = 0, Max = 1,
        Step = 0.01, Config = { "RagebotWeapon", "Secondary", "PredictionMultiplier" } })
    secondarySection:AddToggle({ Label = "No Spread",
        Config = { "RagebotWeapon", "Secondary", "NoSpread" } })
    secondarySection:AddToggle({ Label = "Full Auto",
        Config = { "RagebotWeapon", "Secondary", "FullAuto" } })

    local sFireCdToggle = secondarySection:AddToggle({ Label = "Reduce Fire Cooldown",
        Config = { "RagebotWeapon", "Secondary", "ReduceFireCooldown", "Enabled" } })
    secondarySection:AddGroup({ Source = sFireCdToggle, Option = true })
        :AddSlider({ Label = "Fire Cooldown %", Min = 1, Max = 100,
            Config = { "RagebotWeapon", "Secondary", "ReduceFireCooldown", "Percentage" } })

    local sAimCdToggle = secondarySection:AddToggle({ Label = "Reduce Aim Cooldown",
        Config = { "RagebotWeapon", "Secondary", "ReduceAimCooldown", "Enabled" } })
    secondarySection:AddGroup({ Source = sAimCdToggle, Option = true })
        :AddSlider({ Label = "Aim Cooldown %", Min = 1, Max = 100,
            Config = { "RagebotWeapon", "Secondary", "ReduceAimCooldown", "Percentage" } })
end

-- ============================================================
--  RUNTIME HELPERS
--  These extend the behaviours kiciahook's engine already runs:
--  weapon-specific cooldown overrides, knife arc prediction,
--  backstab spin assist.  They hook into the game's remotes the
--  same way kiciahook does — via sethiddenproperty / fireserver.
-- ============================================================

local function getCharacter(player)
    local char = player and player.Character
    if not char then return nil end
    local root  = char:FindFirstChild("HumanoidRootPart")
    local hum   = char:FindFirstChildOfClass("Humanoid")
    if not root or not hum or hum.Health <= 0 then return nil end
    return { char = char, root = root, hum = hum }
end

local function getEnemies()
    local out = {}
    local myTeam = lp and lp.Team
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp then
            local sameTeam = myTeam and p.Team == myTeam
            if not sameTeam then
                local info = getCharacter(p)
                if info then
                    out[#out + 1] = { player = p, char = info.char,
                                      root = info.root, hum = info.hum }
                end
            end
        end
    end
    return out
end

local function getBestTarget(originPos, fovDeg, maxDist)
    local cam    = workspace.CurrentCamera
    local best, bestScore = nil, math.huge
    for _, enemy in ipairs(getEnemies()) do
        local rp    = enemy.root
        local dist  = (rp.Position - originPos).Magnitude
        if dist <= maxDist then
            -- screen-space FOV check
            local screenPos, onScreen = cam:WorldToScreenPoint(rp.Position)
            if onScreen then
                local cx, cy = cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2
                local dx, dy = screenPos.X - cx, screenPos.Y - cy
                local pxDist = math.sqrt(dx*dx + dy*dy)
                local halfFov = math.rad(fovDeg / 2)
                local fovPx   = math.tan(halfFov) * cam.ViewportSize.Y * 0.5 * 2
                if pxDist <= fovPx / 2 then
                    local score = pxDist
                    if score < bestScore then
                        bestScore = score
                        best      = enemy
                    end
                end
            end
        end
    end
    return best
end

-- Velocity-based linear prediction (ping-adjusted)
local function predictPosition(rootPart, multiplier)
    local vel  = rootPart.AssemblyLinearVelocity
    local ping = (lp and lp:FindFirstChild("PingAttribute")
                    and lp.PingAttribute.Value or 100) / 1000
    return rootPart.Position + vel * ping * multiplier
end

-- Arc compensation for thrown knife (simple parabolic drop)
local function arcCompensate(originPos, targetPos, gravity)
    gravity = gravity or -workspace.Gravity
    local delta    = targetPos - originPos
    local horizDist = math.sqrt(delta.X^2 + delta.Z^2)
    -- estimate travel time (assume projectile speed ≈ 80 studs/s)
    local projSpeed = 80
    local travelTime = horizDist / projSpeed
    -- vertical correction
    local vertCorrect = 0.5 * math.abs(gravity) * travelTime^2
    return Vector3.new(targetPos.X, targetPos.Y + vertCorrect, targetPos.Z)
end

-- ============================================================
--  EXTENDED WEAPON BEHAVIOURS  (RunService Heartbeat)
-- ============================================================

local lastKnifeThrow   = 0
local lastMeleeSwing   = 0
local spinAngle        = 0

local function tickWeaponBehaviours(dt)
    local rgCfg     = Cfg.Ragebot
    local wpCfg     = Cfg.RagebotWeapon
    if not rgCfg.Enabled then return end

    local myInfo    = getCharacter(lp)
    if not myInfo then return end
    local originPos = myInfo.root.Position
    local char      = lp.Character

    -- ── detect held weapon type ──────────────────────────────
    local heldTool  = char and char:FindFirstChildOfClass("Tool")
    local toolName  = heldTool and heldTool.Name or ""
    local isKnife   = string.find(toolName:lower(), "knife") ~= nil
    local isMelee   = heldTool and heldTool:FindFirstChild("MeleeTag") ~= nil
                      or (not isKnife and string.find(toolName:lower(), "sword") ~= nil)
                      or (not isKnife and string.find(toolName:lower(), "bat") ~= nil)
                      or (not isKnife and string.find(toolName:lower(), "katana") ~= nil)
                      or (not isKnife and string.find(toolName:lower(), "blade") ~= nil)
    local isGun     = heldTool and heldTool:FindFirstChild("GunTag") ~= nil
                      or heldTool and heldTool:FindFirstChild("Ammo") ~= nil

    local weapSlot  = "Primary"
    if heldTool then
        local slotAttr = heldTool:GetAttribute("WeaponSlot")
        if slotAttr then weapSlot = slotAttr end
    end

    -- ── KNIFE ragebot ────────────────────────────────────────
    if isKnife and wpCfg.Knife.Enabled then
        local kCfg   = wpCfg.Knife
        if kCfg.AutoThrow then
            local now = os.clock()
            -- basic cooldown gate — knife cooldown ≈ 1.2 s
            local cdGate = 1.2 * ((kCfg.ReduceCooldown.Enabled
                and kCfg.ReduceCooldown.Percentage / 100) or 1)
            if now - lastKnifeThrow >= cdGate then
                local target = getBestTarget(originPos,
                    180, kCfg.MaxThrowDistance)
                if target then
                    -- build aim position
                    local aimPos = predictPosition(target.root,
                        kCfg.PredictionMultiplier)
                    if kCfg.TargetPart == "Head" then
                        local head = target.char:FindFirstChild("Head")
                        if head then
                            aimPos = predictPosition(head,
                                kCfg.PredictionMultiplier)
                        end
                    end
                    if kCfg.ArcCompensation then
                        aimPos = arcCompensate(originPos, aimPos)
                    end
                    -- rotate camera toward aim position and fire
                    local cam   = workspace.CurrentCamera
                    local _, cy = cam:WorldToScreenPoint(aimPos)
                    cam.CFrame  = CFrame.new(cam.CFrame.Position,
                        Vector3.new(aimPos.X, aimPos.Y, aimPos.Z))
                    -- simulate tool activation (throw)
                    if heldTool and heldTool.Activated then
                        pcall(function() heldTool.Activated:Fire() end)
                    end
                    lastKnifeThrow = now
                end
            end
        end
    end

    -- ── MELEE ragebot ────────────────────────────────────────
    if isMelee and wpCfg.Melee.Enabled then
        local mCfg  = wpCfg.Melee
        local target = getBestTarget(originPos,
            360, mCfg.MaxEngageDistance)
        if target then
            -- backstab assist: spin character 180° if AlwaysBackstab + AutoSpin
            if mCfg.AlwaysBackstab and mCfg.AutoSpin then
                local myRoot  = myInfo.root
                local toEnemy = (target.root.Position - myRoot.Position)
                    .Unit
                -- face AWAY from enemy
                local backVec = -toEnemy
                local newCF   = CFrame.new(myRoot.Position,
                    myRoot.Position + backVec)
                pcall(function()
                    if sethiddenproperty then
                        sethiddenproperty(myRoot, "CFrame", newCF)
                    end
                end)
            end

            -- extend range: widen the hitbox CFrame sent with the attack remote
            -- (mirrors kiciahook gd module: v119["\0"] patching)
            if mCfg.ExtendRange.Enabled and heldTool then
                local rng = mCfg.ExtendRange.Range
                -- move attack origin toward enemy by (rng - defaultRange) studs
                local dir = (target.root.Position - originPos).Unit
                local shiftedPos = originPos + dir * rng
                -- patch is applied server-side by kiciahook's MeleeView hook;
                -- we just update config so the hook reads the right range.
                -- If kiciahook is not running, manually fire the attack:
                local attackRemote = heldTool:FindFirstChild("AttackRemote")
                    or heldTool:FindFirstChildOfClass("RemoteEvent")
                if attackRemote then
                    local encodedCF = CFrame.new(shiftedPos)
                        * CFrame.fromOrientation(-math.pi/2, 0, 0)
                    pcall(function()
                        attackRemote:FireServer(encodedCF, encodedCF)
                    end)
                end
            end
        end
    end

    -- ── GUN  cooldown / full-auto overrides ──────────────────
    if isGun then
        local gCfg = wpCfg[weapSlot] or wpCfg.Primary
        if gCfg and gCfg.Enabled then
            -- NoSpread: zero spread attribute on tool
            if gCfg.NoSpread and heldTool then
                pcall(function()
                    if sethiddenproperty then
                        sethiddenproperty(heldTool, "SpreadAngle",
                            Vector2.new(0, 0))
                    end
                end)
            end
        end
    end
end

-- ============================================================
--  RUNSERVICE BINDING
-- ============================================================
local hbConn = track(RunService.Heartbeat:Connect(function(dt)
    pcall(tickWeaponBehaviours, dt)
end))

-- ============================================================
--  UNLOAD
-- ============================================================
RT.Unload = function()
    if RT.destroyed then return end
    RT.destroyed = true
    for _, c in ipairs(RT.connections) do
        pcall(function() c:Disconnect() end)
    end
    for _, f in ipairs(RT.cleanups) do
        pcall(f)
    end
    table.clear(RT.connections)
    table.clear(RT.cleanups)
    getgenv().KiciaRagebotTab = nil
    getgenv().KiciaRagebotCfg = nil
    print("[KiciaRagebotTab] unloaded")
end
onUnload(function() end) -- placeholder slot

-- ============================================================
--  USAGE NOTE
--  To attach the tab to kiciahook's Combat menu, inside the
--  ij fn35 tab-builder (line 59585 of kiciahook) replace the
--  Ragebot grid block with:
--
--      local rgGrid = X:AddTab({
--          Label       = "Ragebot",
--          Icon        = S.Ragebot,
--          Description = "Per-weapon ragebot: Melee, Knife, Primary, Secondary.",
--      }):Grid({ Columns = 2 })
--      require(KiciaRagebotTab).BuildTab(rgGrid)
--
--  Or, if patching post-load:
--
--      local RT = getgenv().KiciaRagebotTab
--      RT.BuildTab(existingRagebotGrid)
--
--  Config is live at  getgenv().KiciaRagebotCfg
--  All "Ragebot.*" keys sync with kiciahook's own engine.
--  "RagebotWeapon.*" keys are read only by this module.
-- ============================================================

print("[KiciaRagebotTab] loaded — Melee / Knife / Primary / Secondary sections ready")
return RT

return RT
