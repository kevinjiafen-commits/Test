-- ============================================================
-- arch_hvh_patch.lua
-- language: Lua (Roblox exploit), file: arch_hvh_patch.lua
-- target: arch_boneclaw_override_lua — load THIS AFTER that script
-- requires: _G.RagebotSettings, _G.ArchScriptGui already set
--
-- adds:
--   1. AA resolver  (spin / jitter / static-fake / velocity-align)
--   2. HvH salvo    (multi-shot per fire event, multi-slot cycling)
--   3. Predictive void intercept  (orbit-vector extrapolation)
--   4. Resolver-break AA  (server real = aimed, client = spin desync)
--   5. Adaptive acSpd    (0.005 s in HvH mode)
--   6. Target score upgrade  (low angular velocity = preferred)
--   7. FireServer second-hook  (injects salvo on every StartShooting)
--   8. UI group "HvH Engine" appended to existing RbTab
-- ============================================================

-- ── guard: wait for arch script ───────────────────────────────────────────
repeat task.wait(0.1) until _G.RagebotSettings and _G.ArchScriptGui

-- ── re-acquire services (patch runs in its own closure) ───────────────────
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")

local function cref(s) return (cloneref and cloneref(s)) or s end
local Player  = Players.LocalPlayer
local repS    = cref(ReplicatedStorage)
local plrs    = cref(Players)
local ws      = cref(game:GetService("Workspace"))

-- modules — same paths arch script uses
local function tryReq(path)
    local ok, m = pcall(require, path)
    return ok and m or nil
end
local util    = tryReq(repS.Modules.Utility)
local enumLib = tryReq(repS.Modules.EnumLibrary)
local FighterController = tryReq(Player.PlayerScripts.Controllers.FighterController)

-- ── import arch settings table (live reference) ───────────────────────────
local RS = _G.RagebotSettings   -- mutating this mutates the running ragebot

-- ── HvH config block ──────────────────────────────────────────────────────
local HvHCfg = {
    enabled             = false,

    -- resolver
    resolverEnabled     = true,
    resolverHistLen     = 8,         -- frames of history
    spinThreshold       = 2.8,       -- rad/s LookVector delta → classify as spin
    jitterThreshold     = 0.6,       -- rad/s alternation → classify as jitter
    velAlignWeight      = 0.65,      -- blend toward velocity direction for static-fake

    -- salvo (multi-shot per fire event)
    salvoEnabled        = true,
    salvoCount          = 4,         -- additional FireServer calls per trigger
    salvoDelay          = 0,         -- seconds between salvo shots (0 = same tick)
    salvoMultiSlot      = true,      -- cycle through all non-empty slots during salvo

    -- predictive void intercept
    predictEnabled      = true,
    predictFrames       = 5,         -- orbit history frames for velocity fit
    predictLead         = 0.06,      -- seconds ahead to extrapolate

    -- resolver-break anti-aim
    aaBreakEnabled      = true,
    aaBreakFreq         = 18,        -- fake yaw flips per second

    -- adaptive fire rate
    adaptiveAcSpd       = true,
    hvhAcSpd            = 0.004,     -- 4 ms floor (Rivals server allows it)

    -- target scorer
    angularPenalty      = 1.5,       -- multiply spinner's distance by this (deprioritise)
}

_G.HvHCfg = HvHCfg

-- ── per-player frame history ───────────────────────────────────────────────
-- HvH_history[plr] = { {lv, pos, t}, ... }  (ring buffer, newest last)
local HvH_history = {}
local HvH_lastAngVel = {}    -- last computed angular velocity per player

local function hvhGetHistory(plr)
    if not HvH_history[plr] then HvH_history[plr] = {} end
    return HvH_history[plr]
end

local function hvhPushHistory(plr, lv, pos)
    local h = hvhGetHistory(plr)
    table.insert(h, { lv = lv, pos = pos, t = os.clock() })
    while #h > HvHCfg.resolverHistLen do table.remove(h, 1) end
end

local function hvhAngularVel(h)
    -- average rad/s change in LookVector direction over last N frames
    if #h < 2 then return 0 end
    local total = 0
    for i = 2, #h do
        local prev, cur = h[i-1], h[i]
        local dt = cur.t - prev.t
        if dt > 0 then
            local dot = math.clamp(prev.lv:Dot(cur.lv), -1, 1)
            total += math.acos(dot) / dt
        end
    end
    return total / (#h - 1)
end

-- ── AA classifier ─────────────────────────────────────────────────────────
-- returns: "spin" | "jitter" | "static_fake" | "clean"
local function hvhClassifyAA(plr)
    local h = hvhGetHistory(plr)
    if #h < 3 then return "clean" end

    local angVel = hvhAngularVel(h)
    HvH_lastAngVel[plr] = angVel

    if angVel > HvHCfg.spinThreshold then return "spin" end

    -- jitter: alternating sign on cross product Z
    local flips = 0
    local lastSign = 0
    for i = 2, #h do
        local cross = h[i-1].lv:Cross(h[i].lv)
        local sign  = cross.Y >= 0 and 1 or -1
        if lastSign ~= 0 and sign ~= lastSign then flips += 1 end
        lastSign = sign
    end
    local jitterRate = flips / (#h - 1)
    if jitterRate >= HvHCfg.jitterThreshold then return "jitter" end

    -- static fake: body LookVector doesn't match movement vector
    local first, last = h[1], h[#h]
    local moveDelta = last.pos - first.pos
    local moveMag   = moveDelta.Magnitude
    if moveMag > 0.5 then
        local moveDir = moveDelta.Unit
        local facingDir = Vector3.new(last.lv.X, 0, last.lv.Z).Unit
        local alignment = math.abs(moveDir:Dot(facingDir))
        if alignment < 0.45 then return "static_fake" end
    end

    return "clean"
end

-- ── resolver: returns best-guess aim position override ────────────────────
-- returns Vector3 (resolved head position) or nil (use default)
local function hvhResolve(plr, head, tr)
    if not HvHCfg.resolverEnabled then return nil end

    local aaType = hvhClassifyAA(plr)

    if aaType == "spin" then
        -- spin: wait for lowest angular velocity window
        -- can't wait here (sync), so return nil — salvo will catch the dip
        -- instead: aim at the position behind where they will be (180° phase)
        local lv = tr.CFrame.LookVector
        -- target will complete half rotation soon; aim 90° off current facing
        local perpDir = Vector3.new(-lv.Z, 0, lv.X).Unit
        return head.Position + perpDir * 0.8

    elseif aaType == "jitter" then
        -- jitter: average of last two LookVectors gives true facing
        local h = hvhGetHistory(plr)
        if #h >= 2 then
            local avg = (h[#h].lv + h[#h-1].lv).Unit
            -- aim at head displaced along resolved facing
            return head.Position - avg * 0.4 + Vector3.new(0, 0.15, 0)
        end

    elseif aaType == "static_fake" then
        -- static fake: use velocity direction to find real facing
        local vel = tr.AssemblyLinearVelocity
        local velXZ = Vector3.new(vel.X, 0, vel.Z)
        local vmag  = velXZ.Magnitude
        if vmag > 0.3 then
            local velDir = velXZ.Unit
            local blended = (tr.CFrame.LookVector * (1 - HvHCfg.velAlignWeight)
                           + velDir * HvHCfg.velAlignWeight).Unit
            -- shoot from behind resolved direction
            local from = head.Position - blended * 2.5 + Vector3.new(0, 1.5, 0)
            return from  -- used as shootPos in camera data below
        end
    end

    return nil  -- "clean" or fallback: caller uses default
end

-- ── orbit-vector extrapolation for predictive void intercept ───────────────
local HvH_orbitHistory = {}  -- [plr] = { {pos, t}, ... }

local function hvhTrackOrbit(plr, pos)
    if not HvH_orbitHistory[plr] then HvH_orbitHistory[plr] = {} end
    local oh = HvH_orbitHistory[plr]
    table.insert(oh, { pos = pos, t = os.clock() })
    while #oh > HvHCfg.predictFrames do table.remove(oh, 1) end
end

local function hvhPredictExpose(plr)
    if not HvHCfg.predictEnabled then return nil end
    local oh = HvH_orbitHistory[plr]
    if not oh or #oh < 3 then return nil end

    -- linear velocity fit over stored positions
    local first, last = oh[1], oh[#oh]
    local dt = last.t - first.t
    if dt < 0.01 then return nil end

    local vel = (last.pos - first.pos) / dt
    local leadTime = HvHCfg.predictLead
    return last.pos + vel * leadTime
end

-- ── camera data builder (mirrors arch script's rbBuildCameraData) ──────────
local function hvhBuildCameraData(fromPos, part)
    if not util or not part then return nil end
    local look = CFrame.new(fromPos, part.Position)
    local data = {}
    data[utf8.char(1)] = {
        [utf8.char(0)] = util:EncodeCFrame(look),
        [utf8.char(1)] = util:EncodeCFrame(look),
        [utf8.char(2)] = part,
        [utf8.char(3)] = util:EncodeCFrame(part.CFrame:ToObjectSpace(CFrame.new(part.Position))),
    }
    return data
end

-- ── HvH salvo: fire N additional shots on the same target ─────────────────
-- called from the FireServer hook; fires independently of arch's own loop
local function hvhSalvo(oid, originalData, shootEnum, useRemote, fromPos)
    if not HvHCfg.salvoEnabled or HvHCfg.salvoCount <= 0 then return end
    if not useRemote or not oid or not shootEnum then return end

    local count = HvHCfg.salvoCount
    local delay = HvHCfg.salvoDelay

    task.spawn(function()
        for i = 1, count do
            if delay > 0 and i > 1 then task.wait(delay) end

            -- try to grab a fresh item's ObjectID for multi-slot cycling
            local fireOid = oid
            if HvHCfg.salvoMultiSlot and FighterController then
                local lf = FighterController.LocalFighter
                if lf and lf.Items then
                    -- cycle: pick next slot with ammo
                    local slots = {1, 2, 3}
                    for _, slot in ipairs(slots) do
                        local item = lf.Items[slot]
                        if item then
                            local ammo = item.Get and (item:Get("Ammo") or 0) or 0
                            if ammo > 0 then
                                local slotOid = item.Get and item:Get("ObjectID")
                                if slotOid and slotOid ~= oid then
                                    fireOid = slotOid
                                    break
                                end
                            end
                        end
                    end
                end
            end

            pcall(function()
                useRemote:FireServer(fireOid, shootEnum, originalData, nil)
            end)
        end
    end)
end

-- ── resolver-break anti-aim: rapid fake yaw via UpdateCameraRotation ───────
local hvhAABreakConn = nil
local hvhAABreakPhase = 0

local function hvhStartAABreak()
    if hvhAABreakConn then return end
    local updateCamRemote
    do
        local r = repS:FindFirstChild("Remotes")
        r = r and r:FindFirstChild("Replication")
        r = r and r:FindFirstChild("Fighter")
        r = r and r:FindFirstChild("UpdateCameraRotation")
        updateCamRemote = r
    end
    if not updateCamRemote or not util then return end

    hvhAABreakConn = RunService.Heartbeat:Connect(function(dt)
        if not HvHCfg.enabled or not HvHCfg.aaBreakEnabled then return end
        if not RS.on then return end

        hvhAABreakPhase += dt * HvHCfg.aaBreakFreq * math.pi * 2
        -- alternate between two extreme yaw offsets — resolver-confusing desync
        local fakeYaw = hvhAABreakPhase
        local ok, encoded = pcall(function()
            return util:EncodeCameraRotation(Vector2.new(0, fakeYaw))
        end)
        if ok and encoded then
            pcall(function() updateCamRemote:FireServer(encoded, nil) end)
        end
    end)
end

local function hvhStopAABreak()
    if hvhAABreakConn then
        hvhAABreakConn:Disconnect()
        hvhAABreakConn = nil
    end
end

-- ── per-frame target history pump ─────────────────────────────────────────
RunService.Heartbeat:Connect(function()
    if not HvHCfg.enabled then return end
    for _, plr in plrs:GetPlayers() do
        if plr == Player then continue end
        local char = plr.Character
        local tr   = char and char:FindFirstChild("HumanoidRootPart")
        local head = char and char:FindFirstChild("Head")
        if tr and head then
            hvhPushHistory(plr, tr.CFrame.LookVector, tr.Position)
            hvhTrackOrbit(plr, head.Position)
        end
    end
end)

-- ── FireServer hook layer ─────────────────────────────────────────────────
-- layered AFTER arch script's existing hook
-- intercepts StartShooting: injects resolver-corrected camera data + salvo
local hvhHookInstalled = false
local hvhOldFireServer = nil

local function hvhInstallHook()
    if hvhHookInstalled then return end
    local useRemote = repS:FindFirstChild("Remotes")
    useRemote = useRemote and useRemote:FindFirstChild("Replication")
    useRemote = useRemote and useRemote:FindFirstChild("Fighter")
    useRemote = useRemote and useRemote:FindFirstChild("UseItem")
    if not useRemote then return end
    if not hookfunction then return end

    hvhHookInstalled  = true
    hvhOldFireServer  = hookfunction(useRemote.FireServer, newcclosure(function(self, oid, action, cameradata, ...)
        -- pass-through when HvH inactive or not a shoot event
        if not HvHCfg.enabled or not enumLib then
            return hvhOldFireServer(self, oid, action, cameradata, ...)
        end
        local shootEnum = enumLib:ToEnum("StartShooting")
        if action ~= shootEnum then
            return hvhOldFireServer(self, oid, action, cameradata, ...)
        end

        -- find current ragebot target
        local rbState = _G.RagebotSettings
        local targetPlr = nil
        -- walk players to find who matches last known orbit position
        for _, plr in plrs:GetPlayers() do
            if plr ~= Player then
                local char = plr.Character
                local tr   = char and char:FindFirstChild("HumanoidRootPart")
                if tr then targetPlr = plr; break end  -- simple: first enemy = target
            end
        end

        local resolvedData = cameradata  -- default: pass arch script's data as-is

        if targetPlr then
            local char = targetPlr.Character
            local tr   = char and char:FindFirstChild("HumanoidRootPart")
            local head = char and char:FindFirstChild("Head")

            if tr and head then
                -- resolver override
                local resolvedPos = hvhResolve(targetPlr, head, tr)

                -- predictive intercept override (beats resolver if available)
                local predictedPos = hvhPredictExpose(targetPlr)
                local aimFrom = predictedPos or resolvedPos

                if aimFrom and util then
                    -- rebuild camera data from resolved origin
                    local newData = hvhBuildCameraData(aimFrom, head)
                    if newData then resolvedData = newData end
                end

                -- fire salvo using resolved data
                hvhSalvo(oid, resolvedData, shootEnum, useRemote, aimFrom)
            end
        end

        return hvhOldFireServer(self, oid, action, resolvedData, ...)
    end))
end

-- ── adaptive acSpd: tighten fire loop when HvH active ─────────────────────
local hvhAcSpdConn = nil
local hvhAcSpdOriginal = RS.acSpd

local function hvhApplyAcSpd()
    if HvHCfg.enabled and HvHCfg.adaptiveAcSpd then
        RS.acSpd = HvHCfg.hvhAcSpd
    else
        RS.acSpd = hvhAcSpdOriginal
    end
end

-- ── target scorer override ─────────────────────────────────────────────────
-- monkey-patches RS.autoPriority scoring by adjusting live priorities
-- heavy spinners get a distance penalty so the ragebot prefers easier targets
local hvhScorerConn = nil

local function hvhStartScorer()
    if hvhScorerConn then return end
    hvhScorerConn = RunService.Heartbeat:Connect(function()
        if not HvHCfg.enabled then return end
        -- nothing to patch directly (rbGetBestTarget is a local fn)
        -- instead: set RS.prioritizedPlayer to the lowest angVel enemy
        local bestPlr, bestAngVel = nil, math.huge
        for _, plr in plrs:GetPlayers() do
            if plr ~= Player then
                local av = HvH_lastAngVel[plr] or 0
                if av < bestAngVel then
                    bestAngVel = av
                    bestPlr    = plr
                end
            end
        end
        -- only override if we found someone significantly more hittable
        -- (below 1.0 rad/s = calm target = prioritise)
        if bestPlr and bestAngVel < 1.0 then
            RS.prioritizedPlayer = bestPlr.Name
        else
            -- let arch script pick naturally
            RS.prioritizedPlayer = nil
        end
    end)
end

local function hvhStopScorer()
    if hvhScorerConn then hvhScorerConn:Disconnect(); hvhScorerConn = nil end
    RS.prioritizedPlayer = nil
end

-- ── master HvH toggle ─────────────────────────────────────────────────────
local function hvhEnable()
    HvHCfg.enabled = true
    hvhApplyAcSpd()
    hvhInstallHook()
    hvhStartAABreak()
    hvhStartScorer()
    -- force hyper + Orbit mode (maximum fire rate)
    RS.hyper    = true
    RS.shootAttempts = math.max(RS.shootAttempts, 3)
    RS.voidHideTime  = math.min(RS.voidHideTime, 0.10)
    RS.voidShootTime = math.min(RS.voidShootTime, 0.02)
    RS.antiAim  = false   -- our AA break handles this via UpdateCameraRotation
end

local function hvhDisable()
    HvHCfg.enabled = false
    hvhApplyAcSpd()
    hvhStopAABreak()
    hvhStopScorer()
    -- restore original values
    RS.acSpd         = hvhAcSpdOriginal
    RS.prioritizedPlayer = nil
end

-- ── UI ─────────────────────────────────────────────────────────────────────
-- re-attach to arch's ScreenGui and tab system
local ScreenGui = _G.ArchScriptGui
if not ScreenGui then return end

-- small local UI helpers (matches arch script's style)
local CFG2 = {
    MainColor      = Color3.fromRGB(14, 14, 14),
    SecondaryColor = Color3.fromRGB(26, 26, 26),
    AccentColor    = Color3.fromRGB(189, 172, 255),
    TextColor      = Color3.fromRGB(200, 200, 200),
    TextDark       = Color3.fromRGB(120, 120, 120),
    StrokeColor    = Color3.fromRGB(40, 40, 40),
    Font           = Enum.Font.Code,
}

local function C(class, props, children)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do inst[k] = v end
    for _, c in pairs(children or {}) do c.Parent = inst end
    return inst
end

local function Tw(obj, props, t)
    TweenService:Create(obj, TweenInfo.new(t or 0.15, Enum.EasingStyle.Quad), props):Play()
end

-- find the main frame to anchor the new panel next to existing tabs
local MainFrame = ScreenGui:FindFirstChild("MainFrame")
if not MainFrame then
    -- fallback: search deeper
    for _, v in ScreenGui:GetDescendants() do
        if v:IsA("Frame") and v.Name == "MainFrame" then MainFrame = v; break end
    end
end

-- HvH panel container — docked below MainFrame or free-floating
local hvhPanelAnchor = MainFrame or ScreenGui

local HvHPanel = C("Frame", {
    Name             = "HvHPanel",
    Parent           = ScreenGui,
    Size             = UDim2.new(0, 210, 0, 0),
    AutomaticSize    = Enum.AutomaticSize.Y,
    Position         = UDim2.new(0, 10, 0, 10),
    BackgroundColor3 = CFG2.MainColor,
    BorderSizePixel  = 0,
    ClipsDescendants = false,
}, {
    C("UICorner",  { CornerRadius = UDim.new(0, 5) }),
    C("UIStroke",  { Color = CFG2.StrokeColor, Thickness = 1 }),
    C("UIListLayout", { Padding = UDim.new(0, 0), SortOrder = Enum.SortOrder.LayoutOrder }),
})

-- drag
do
    local drag, dragStart, origPos = false, nil, nil
    HvHPanel.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            drag = true; dragStart = inp.Position; origPos = HvHPanel.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if not drag then return end
        if inp.UserInputType == Enum.UserInputType.MouseMovement
        or inp.UserInputType == Enum.UserInputType.Touch then
            local d = inp.Position - dragStart
            HvHPanel.Position = UDim2.new(origPos.X.Scale, origPos.X.Offset + d.X,
                                           origPos.Y.Scale, origPos.Y.Offset + d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then drag = false end
    end)
end

-- title bar
C("Frame", {
    Parent           = HvHPanel,
    Size             = UDim2.new(1, 0, 0, 22),
    BackgroundColor3 = CFG2.SecondaryColor,
    BorderSizePixel  = 0,
    LayoutOrder      = 0,
}, {
    C("UICorner", { CornerRadius = UDim.new(0, 5) }),
    C("TextLabel", {
        Text           = "HvH Engine",
        TextColor3     = CFG2.AccentColor,
        Font           = Enum.Font.GothamBold,
        TextSize       = 11,
        BackgroundTransparency = 1,
        Size           = UDim2.new(1, -10, 1, 0),
        Position       = UDim2.new(0, 8, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
    }),
})

-- content frame
local HvHContent = C("Frame", {
    Parent           = HvHPanel,
    Size             = UDim2.new(1, 0, 0, 0),
    AutomaticSize    = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1,
    LayoutOrder      = 1,
}, {
    C("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }),
    C("UIPadding", {
        PaddingTop   = UDim.new(0, 6),
        PaddingBottom= UDim.new(0, 8),
        PaddingLeft  = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
    }),
})

local uiOrder = 0
local function nextOrder() uiOrder += 1; return uiOrder end

-- toggle builder
local function mkToggle(name, default, tooltip, cb)
    local enabled = default
    local row = C("TextButton", {
        Parent               = HvHContent,
        Size                 = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Text                 = "",
        LayoutOrder          = nextOrder(),
    })
    local box = C("Frame", {
        Parent           = row,
        Size             = UDim2.new(0, 12, 0, 12),
        Position         = UDim2.new(0, 0, 0.5, -6),
        BackgroundColor3 = CFG2.SecondaryColor,
        BorderSizePixel  = 0,
    }, { C("UIStroke", { Color = CFG2.StrokeColor }) })
    local check = C("Frame", {
        Parent           = box,
        Size             = UDim2.new(1, -4, 1, -4),
        Position         = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint      = Vector2.new(0.5, 0.5),
        BackgroundColor3 = CFG2.AccentColor,
        BackgroundTransparency = enabled and 0 or 1,
    })
    C("TextLabel", {
        Parent         = row,
        Text           = name,
        TextColor3     = enabled and CFG2.TextColor or CFG2.TextDark,
        TextSize       = 11,
        Font           = CFG2.Font,
        BackgroundTransparency = 1,
        Position       = UDim2.new(0, 18, 0, 0),
        Size           = UDim2.new(1, -18, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    row.MouseButton1Click:Connect(function()
        enabled = not enabled
        Tw(check, { BackgroundTransparency = enabled and 0 or 1 })
        if cb then cb(enabled) end
    end)
end

-- slider builder
local function mkSlider(name, min, max, default, unit, fmt, realFn, cb)
    local value = default
    local F = C("Frame", {
        Parent               = HvHContent,
        Size                 = UDim2.new(1, 0, 0, 32),
        BackgroundTransparency = 1,
        LayoutOrder          = nextOrder(),
    })
    C("TextLabel", {
        Parent         = F, Text = name,
        TextColor3     = CFG2.TextDark, TextSize = 11, Font = CFG2.Font,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 15), TextXAlignment = Enum.TextXAlignment.Left,
    })
    local function disp(v) return fmt and fmt(v) or (tostring(v) .. (unit or "")) end
    local function real(v) return realFn and realFn(v) or v end
    local VL = C("TextLabel", {
        Parent = F, Text = disp(value),
        TextColor3 = CFG2.TextDark, TextSize = 11, Font = CFG2.Font,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 15), TextXAlignment = Enum.TextXAlignment.Right,
    })
    local BG = C("Frame", {
        Parent = F, Size = UDim2.new(1, 0, 0, 6),
        Position = UDim2.new(0, 0, 0, 20),
        BackgroundColor3 = CFG2.SecondaryColor, BorderSizePixel = 0,
    }, { C("UIStroke", { Color = CFG2.StrokeColor }), C("UICorner", { CornerRadius = UDim.new(1,0) }) })
    local Fill = C("Frame", {
        Parent = BG,
        Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
        BackgroundColor3 = CFG2.AccentColor,
    }, { C("UICorner", { CornerRadius = UDim.new(1,0) }) })
    local drag = false
    local function update(inp)
        local pct = math.clamp((inp.Position.X - BG.AbsolutePosition.X) / BG.AbsoluteSize.X, 0, 1)
        value = math.floor(min + (max - min) * pct)
        Fill.Size = UDim2.new(pct, 0, 1, 0)
        VL.Text = disp(value)
        if cb then cb(real(value)) end
    end
    F.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then drag = true; update(i) end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if drag and (i.UserInputType == Enum.UserInputType.MouseMovement
                  or i.UserInputType == Enum.UserInputType.Touch) then update(i) end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then drag = false end
    end)
end

-- section label
local function mkLabel(text)
    C("TextLabel", {
        Parent         = HvHContent,
        Text           = text,
        TextColor3     = CFG2.AccentColor,
        TextSize       = 10,
        Font           = Enum.Font.GothamBold,
        BackgroundTransparency = 1,
        Size           = UDim2.new(1, 0, 0, 14),
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder    = nextOrder(),
    })
end

-- ── build controls ────────────────────────────────────────────────────────

mkToggle("HvH Master", false, nil, function(v)
    if v then hvhEnable() else hvhDisable() end
end)

mkLabel("— Resolver")
mkToggle("Resolver", true, nil, function(v) HvHCfg.resolverEnabled = v end)
mkSlider("Spin Threshold", 10, 100, 28, " r/s",
    function(v) return string.format("%.1f", v / 10) end,
    function(v) return v / 10 end,
    function(v) HvHCfg.spinThreshold = v end)
mkSlider("Vel Align Blend", 0, 100, 65, "%",
    function(v) return v .. "%" end, nil,
    function(v) HvHCfg.velAlignWeight = v / 100 end)

mkLabel("— Salvo")
mkToggle("Multi-Shot Salvo", true, nil, function(v) HvHCfg.salvoEnabled = v end)
mkSlider("Salvo Count", 1, 8, 4, " shots", nil, nil,
    function(v) HvHCfg.salvoCount = math.floor(v) end)
mkToggle("Multi-Slot Cycling", true, nil, function(v) HvHCfg.salvoMultiSlot = v end)

mkLabel("— Predictive Intercept")
mkToggle("Predict Expose", true, nil, function(v) HvHCfg.predictEnabled = v end)
mkSlider("Lead Time", 1, 20, 6, " cs",
    function(v) return string.format("%.2f s", v / 100) end,
    function(v) return v / 100 end,
    function(v) HvHCfg.predictLead = v / 100 end)

mkLabel("— AA Break")
mkToggle("Resolver Break", true, nil, function(v)
    HvHCfg.aaBreakEnabled = v
    if HvHCfg.enabled then
        if v then hvhStartAABreak() else hvhStopAABreak() end
    end
end)
mkSlider("Break Freq", 5, 60, 18, " Hz", nil, nil,
    function(v) HvHCfg.aaBreakFreq = math.floor(v) end)

mkLabel("— Fire Rate")
mkToggle("Adaptive AcSpd", true, nil, function(v)
    HvHCfg.adaptiveAcSpd = v; hvhApplyAcSpd()
end)
mkSlider("HvH AcSpd", 1, 50, 4, " ms",
    function(v) return v .. " ms" end,
    function(v) return v / 1000 end,
    function(v) HvHCfg.hvhAcSpd = v / 1000; hvhApplyAcSpd() end)

mkLabel("— Target Scorer")
mkToggle("Prefer Calm Targets", true, nil, function(v)
    if v then hvhStartScorer() else hvhStopScorer() end
end)

-- expose for console debugging
_G.HvHPatch = {
    cfg      = HvHCfg,
    enable   = hvhEnable,
    disable  = hvhDisable,
    history  = HvH_history,
    angVels  = HvH_lastAngVel,
    classify = hvhClassifyAA,
}

print("[arch hvh patch] loaded — _G.HvHPatch available")
