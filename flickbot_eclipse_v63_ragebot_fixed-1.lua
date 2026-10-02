-- ═══════════════════════════════════════════════════════════════════════════
--  Eclipse Flickbot v6.3  ×  Ragebot Fixed Build
--  Flickbot logic : flickbot_eclipse_v63_no_void_spam_no_comments.lua
--  Ragebot logic  : ragebot_fixed-1.lua  (replaces original RageCfg system)
-- ═══════════════════════════════════════════════════════════════════════════

-- ── Services ─────────────────────────────────────────────────────────────
local Players           = game:GetService("Players")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")
local Player = Players.LocalPlayer
local function cref(s) return (cloneref and cloneref(s)) or s end
local cloneref = cloneref or function(obj) return obj end
local repS = cref(ReplicatedStorage)
local plrs = cref(Players)
local ws   = cref(Workspace)

local FighterController, SpectateController, util, enumLib
do
    local ok
    ok, FighterController  = pcall(require, Player.PlayerScripts.Controllers.FighterController)
    if not ok then FighterController = nil end
    ok, SpectateController = pcall(require, Player.PlayerScripts.Controllers:WaitForChild("SpectateController", 5))
    if not ok then SpectateController = nil end
    ok, util    = pcall(require, repS.Modules.Utility)
    if not ok then util = nil end
    ok, enumLib = pcall(require, repS.Modules.EnumLibrary)
    if not ok then enumLib = nil end
end

-- ── Flickbot config ───────────────────────────────────────────────────────
local CFG = {
    MainColor      = Color3.fromRGB(14,  14,  14),
    SecondaryColor = Color3.fromRGB(26,  26,  26),
    AccentColor    = Color3.fromRGB(189, 172, 255),
    TextColor      = Color3.fromRGB(200, 200, 200),
    TextDark       = Color3.fromRGB(120, 120, 120),
    StrokeColor    = Color3.fromRGB(40,  40,  40),
    Font           = Enum.Font.Code,
    BaseSize       = Vector2.new(700, 470),
}
local FlickCfg = {
    Active          = false,
    Desync          = true,
    PredictionOn    = true,
    PredictionScale = 0.08,
    TeamFilter      = true,
    AntiVelocity    = true,
    OffsetX         = 0,
    OffsetY         = 0,
    OffsetZ         = 0,
    FlickSpeed      = 99999,
    FlickRadius     = 0.25,
    WritesPerFrame  = 3,
    RandomizeOffset = false,
    _SavedOffsetX   = 0,
    _SavedOffsetY   = 0,
    _SavedOffsetZ   = 0,
    FlickLerpAlpha  = 1.0,
}

-- ══════════════════════════════════════════════════════════════════════════
--  RAGEBOT (ragebot_fixed-1.lua)
-- ══════════════════════════════════════════════════════════════════════════

-- ── isShootingRange() ─────────────────────────────────────────────────────
local shootingRangeCache, shootingRangeChecked = false, 0
local function isShootingRange()
    local now = os.clock()
    if now - shootingRangeChecked < 0.5 then return shootingRangeCache end
    shootingRangeChecked = now

    local function matches(value)
        if value == nil then return false end
        local text = tostring(value):lower():gsub("[%s_%-]", "")
        return text:find("shootingrange", 1, true) ~= nil
            or text:find("firingrange",   1, true) ~= nil
            or text:find("사격장",         1, true) ~= nil
    end

    local LocalPlayer = plrs.LocalPlayer
    for _, object in ipairs({workspace, LocalPlayer}) do
        for _, attribute in ipairs({"Map","MapName","Mode","GameMode","Arena","Environment","EnvironmentName","ShootingRange"}) do
            local value = object:GetAttribute(attribute)
            if (value == true and attribute == "ShootingRange") or matches(value) then
                shootingRangeCache = true
                return true
            end
        end
    end

    local character = LocalPlayer.Character
    local current   = character
    while current and current ~= workspace do
        if matches(current.Name) then
            shootingRangeCache = true
            return true
        end
        current = current.Parent
    end

    local root = character and character:FindFirstChild("HumanoidRootPart")
    local function matchingAreaIsNear(object)
        if not matches(object.Name) or not root then return false end
        local part = object:IsA("BasePart") and object
                     or object:FindFirstChildWhichIsA("BasePart", true)
        return part and (part.Position - root.Position).Magnitude < 2000
    end
    for _, child in ipairs(workspace:GetChildren()) do
        if matchingAreaIsNear(child) then
            shootingRangeCache = true
            return true
        end
        for _, grandchild in ipairs(child:GetChildren()) do
            if matchingAreaIsNear(grandchild) then
                shootingRangeCache = true
                return true
            end
        end
    end

    shootingRangeCache = false
    return false
end

-- ── Ragebot mainapi / ScreenGui ───────────────────────────────────────────
local RbScreenGui = Instance.new("ScreenGui")
RbScreenGui.Name             = "RagebotGui"
RbScreenGui.ResetOnSpawn     = false
RbScreenGui.ZIndexBehavior   = Enum.ZIndexBehavior.Sibling
RbScreenGui.IgnoreGuiInset   = true
RbScreenGui.DisplayOrder     = 999

local rbGuiParented = false
pcall(function()
    RbScreenGui.Parent = game:GetService("CoreGui")
    rbGuiParented = true
end)
if not rbGuiParented then
    RbScreenGui.Parent = Player:WaitForChild("PlayerGui")
end

local RbClickGui = Instance.new("Frame")
RbClickGui.Name                   = "ClickGui"
RbClickGui.Size                   = UDim2.fromScale(0, 0)
RbClickGui.BackgroundTransparency = 1
RbClickGui.Parent                 = RbScreenGui

local rbCleanupConns = {}
local mainapi = {
    Font           = Enum.Font.BuilderSans,
    ClickGuiStatus = false,
    ThreadFix      = false,
    Scale          = {Value = 1},
    MainScreenGui  = RbScreenGui,
}
function mainapi:Clean(conn)
    if conn then table.insert(rbCleanupConns, conn) end
    return conn
end
function mainapi:Notify(arg)
    if type(arg) == "table" then
        print(("[Ragebot] %s: %s"):format(tostring(arg.Title or ""), tostring(arg.Text or "")))
    end
end
function mainapi:SafeNotify(arg)
    task.spawn(function()
        if self.ThreadFix and setthreadidentity then
            pcall(setthreadidentity, 8)
        end
        pcall(function() self:Notify(arg) end)
    end)
end

-- ── Gradient stubs ────────────────────────────────────────────────────────
local RbGradients     = {}
local InterfaceMode   = {Value = "Static"}
local uipallet        = {
    MainColor      = Color3.fromRGB(200, 118, 189),
    SecondaryColor = Color3.fromRGB(228, 196, 202),
}
local function buildGradientKeypoints()
    return {
        ColorSequenceKeypoint.new(0, uipallet.MainColor),
        ColorSequenceKeypoint.new(1, uipallet.SecondaryColor),
    }
end

-- ── Ragebot UI helpers (prefixed rb_ to avoid collision) ──────────────────
local function rb_makeDraggable(obj)
    obj.InputBegan:Connect(function(inputObj)
        if not mainapi.ClickGuiStatus then return end
        if inputObj.UserInputType == Enum.UserInputType.MouseButton1
            or inputObj.UserInputType == Enum.UserInputType.Touch then
            local dragPosition = Vector2.new(
                obj.AbsolutePosition.X - inputObj.Position.X,
                obj.AbsolutePosition.Y - inputObj.Position.Y + game:GetService("GuiService"):GetGuiInset().Y
            ) / mainapi.Scale.Value
            local changed = UserInputService.InputChanged:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseMovement
                    or input.UserInputType == Enum.UserInputType.Touch then
                    obj.Position = UDim2.fromOffset(
                        (input.Position.X / mainapi.Scale.Value) + dragPosition.X,
                        (input.Position.Y / mainapi.Scale.Value) + dragPosition.Y
                    )
                end
            end)
            local ended
            ended = inputObj.Changed:Connect(function()
                if inputObj.UserInputState == Enum.UserInputState.End then
                    if changed then changed:Disconnect() end
                    if ended  then ended:Disconnect()   end
                end
            end)
        end
    end)
end
local function rb_addCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = radius or UDim.new(0, 5)
    corner.Parent       = parent
    return corner
end
local function rb_addBlur(parent)
    local blur = Instance.new("ImageLabel")
    blur.Name                  = "Blur"
    blur.Size                  = UDim2.new(1, 89, 1, 52)
    blur.Position              = UDim2.fromOffset(-48, -31)
    blur.BackgroundTransparency = 1
    blur.Image                 = "rbxassetid://74663567791967"
    blur.ScaleType             = Enum.ScaleType.Slice
    blur.SliceCenter           = Rect.new(52, 31, 261, 502)
    blur.ZIndex                = -100
    blur.Parent                = parent
    return blur
end
local function rb_addGradient(parent)
    local UIGradient = Instance.new("UIGradient")
    UIGradient.Color  = ColorSequence.new(buildGradientKeypoints())
    table.insert(RbGradients, UIGradient)
    UIGradient.Parent = parent
    return UIGradient
end

-- ── RagebotStatus indicator ───────────────────────────────────────────────
local screenY = RbScreenGui.AbsoluteSize.Y > 0 and RbScreenGui.AbsoluteSize.Y or 600

local RagebotStatusMain = Instance.new("Frame")
RagebotStatusMain.Name                   = "RagebotStatus"
RagebotStatusMain.AnchorPoint            = Vector2.new(0, 0)
RagebotStatusMain.Position               = UDim2.new(0.5, -(screenY / 8.4), 0.08, 0)
RagebotStatusMain.Size                   = UDim2.new(0, screenY / 4.2, 0, screenY / 28)
RagebotStatusMain.BackgroundTransparency = 1
RagebotStatusMain.Visible                = false
RagebotStatusMain.Parent                 = RbScreenGui
getgenv().RagebotStatusMain              = RagebotStatusMain

local RagebotStatusFrame = Instance.new("Frame")
RagebotStatusFrame.Size                   = UDim2.fromScale(1, 1)
RagebotStatusFrame.BackgroundColor3       = Color3.fromRGB(20, 20, 20)
RagebotStatusFrame.BackgroundTransparency = 0.12
RagebotStatusFrame.BorderSizePixel        = 0
RagebotStatusFrame.Parent                 = RagebotStatusMain

local RagebotStatusAccent = Instance.new("Frame")
RagebotStatusAccent.AnchorPoint     = Vector2.new(0, 0.5)
RagebotStatusAccent.Position        = UDim2.fromScale(0.035, 0.5)
RagebotStatusAccent.Size            = UDim2.fromScale(0.022, 0.56)
RagebotStatusAccent.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
RagebotStatusAccent.BorderSizePixel = 0
RagebotStatusAccent.Parent          = RagebotStatusFrame
rb_addGradient(RagebotStatusAccent)

local RagebotStatusText = Instance.new("TextLabel")
RagebotStatusText.BackgroundTransparency = 1
RagebotStatusText.Position               = UDim2.fromScale(0.085, 0)
RagebotStatusText.Size                   = UDim2.fromScale(0.89, 1)
RagebotStatusText.Font                   = mainapi.Font
RagebotStatusText.Text                   = "Ragebot : void"
RagebotStatusText.TextColor3             = Color3.fromRGB(240, 240, 240)
RagebotStatusText.TextScaled             = true
RagebotStatusText.TextXAlignment         = Enum.TextXAlignment.Left
RagebotStatusText.TextYAlignment         = Enum.TextYAlignment.Center
RagebotStatusText.Parent                 = RagebotStatusFrame

local RagebotStatusTextConstraint = Instance.new("UITextSizeConstraint")
RagebotStatusTextConstraint.MinTextSize = 8
RagebotStatusTextConstraint.MaxTextSize = 18
RagebotStatusTextConstraint.Parent      = RagebotStatusText

rb_addCorner(RagebotStatusFrame)
rb_addCorner(RagebotStatusAccent, UDim.new(1, 0))
rb_addBlur(RagebotStatusFrame)
rb_makeDraggable(RagebotStatusMain)

local RagebotStatusScale = Instance.new("UIScale")
RagebotStatusScale.Scale  = 0
RagebotStatusScale.Parent = RagebotStatusFrame

local RagebotStatusLastText = ""
local RagebotStatusVisible  = false

local function setRagebotStatus(enabled, target, voiding)
    shared.RagebotActive = enabled
    if not RagebotStatusMain then return end
    local text = "Harion Rage : void"
    if enabled and target and not voiding then
        text = "Harion Rage : " .. (target.Name or "target")
    end
    if RagebotStatusLastText ~= text then
        RagebotStatusLastText  = text
        RagebotStatusText.Text = text
    end
    if enabled ~= RagebotStatusVisible then
        RagebotStatusVisible      = enabled
        RagebotStatusMain.Visible = true
        TweenService:Create(RagebotStatusScale, TweenInfo.new(0.18, Enum.EasingStyle.Exponential), {
            Scale = enabled and 1 or 0
        }):Play()
        if not enabled then
            task.delay(0.2, function()
                if not RagebotStatusVisible then
                    RagebotStatusMain.Visible = false
                end
            end)
        end
    end
end

mainapi:Clean(RbScreenGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
    RagebotStatusMain.Size = UDim2.new(
        0, RbScreenGui.AbsoluteSize.Y / 4.2,
        0, RbScreenGui.AbsoluteSize.Y / 28
    )
end))

-- ── Movement catalog stub ─────────────────────────────────────────────────
local function makeCleanable()
    local self = {_conns = {}}
    function self:Clean(conn)
        if conn then table.insert(self._conns, conn) end
        return conn
    end
    function self:Destroy()
        for _, c in ipairs(self._conns) do pcall(function() c:Disconnect() end) end
        self._conns = {}
    end
    return self
end

local function makeControl(_, def)
    local ctrl = {
        Enabled = def.Default == true or false,
        Value   = def.Default,
        _list   = def.List or {},
        _fn     = def.Function,
    }
    function ctrl:SetList(list) self._list = list end
    function ctrl:Set(val)
        self.Value   = val
        self.Enabled = (val == true)
        if self._fn then pcall(self._fn, val) end
    end
    if def.Function and def.Default ~= nil then
        pcall(def.Function, def.Default)
    end
    return ctrl
end

local function makeModule(_, def)
    local mod = makeCleanable()
    mod.Name    = def.Name
    mod.Enabled = false
    mod._fn     = def.Function

    function mod:AddToggle(d)   return makeControl(mod, d) end
    function mod:AddSlider(d)   return makeControl(mod, d) end
    function mod:AddDropdown(d) return makeControl(mod, d) end
    function mod:AddInputBox(d) return makeControl(mod, d) end
    function mod:AddLabel(_)    return {} end
    function mod:AddModule(d)   return makeModule(mod, d) end

    function mod:SetEnabled(val)
        self.Enabled = val
        if self._fn then pcall(self._fn, val) end
    end
    return mod
end

local Movement = {}
function Movement:AddModule(def)
    return makeModule(self, def)
end

local function run(func)
    task.spawn(func)
end

-- ── RAGEBOT MODULE (from ragebot_fixed-1.lua) ─────────────────────────────
run(function()
    local Ragebot
    local RagebotSettings = {
        on = false,
        targetMode = "Closest",
        autoSwitch = true,
        autoSwapSecondary = true,
        autoReloadPrimary = true,
        attackMode = "gun",
        preferredWeapon = "primary",
        meleeSlot = 3,
        weaponSpecialize = true,
        autoEquipPreferred = true,
        preferProjectile = false,
        autoPriority = false,
        priorityAttackers = true,
        priorityVoided = true,
        sendNotification = false,
        prioritizedPlayer = nil,
        primarySlot = 1,
        secondarySlot = 2,
        acSpd = 0.05,
        shootDelay = 0,
        teleportDelay = 0.04,
        orbitDist = 3,
        orbitHeight = 2,
        randomMovement = false,
        randomRefresh = 0.08,
        mode = "Orbit",
        strafeSpeed = 5,
        undergroundDepth = 6,
        behindDist = 4,
        antiAim = false,
        hyper = false,
        useManipulation = true,
        voidSpam = true,
        voidHideTime = 0.25,
        voidShootTime = 0.03,
        shootAttempts = 1,
        otherMatchAvoidDistance = 1000,
        settleUntil = 0,
        dirBack = true,
        dirFront = false,
        dirLeft = true,
        dirRight = true,
        dirUp = true,
        dirDown = false,
    }

    local function markRagebotSettingsDirty()
        RagebotSettings.settleUntil = 0
    end

    local rbGen = 0
    local rbDuelMod, rbInMatchT, rbInMatch = nil, 0, false
    local rbTgtT = 0
    local slotKey = {[1] = Enum.KeyCode.One, [2] = Enum.KeyCode.Two, [3] = Enum.KeyCode.Three, [4] = Enum.KeyCode.Four}

    Ragebot = Movement:AddModule({
        Name = 'Ragebot',
        Function = function(callback)
            local cfg = RagebotSettings

            if callback then
                if getgenv().__IDKRagebotStop then
                    pcall(getgenv().__IDKRagebotStop)
                    getgenv().__IDKRagebotStop = nil
                end

                cfg.on         = true
                cfg.settleUntil = 0

                local players    = cloneref(game:GetService("Players"))
                local runservice = cloneref(game:GetService("RunService"))
                local vim        = cloneref(game:GetService("VirtualInputManager"))
                local ws2        = cloneref(game:GetService("Workspace"))
                local rs2        = cloneref(game:GetService("ReplicatedStorage"))
                local lplr       = players.LocalPlayer

                local rbUtil, rbEnums, useItemRemote, fighterCtrl
                pcall(function()
                    rbUtil        = require(rs2.Modules.Utility)
                    rbEnums       = require(rs2.Modules.EnumLibrary)
                    useItemRemote = rs2.Remotes.Replication.Fighter.UseItem
                    fighterCtrl   = require(lplr.PlayerScripts.Controllers.FighterController)
                end)

                local state = {
                    active          = true,
                    target          = nil,
                    conn            = nil,
                    ammoThread      = nil,
                    voidThread      = nil,
                    voidHbConn      = nil,
                    csyncHbConn     = nil,
                    voidExposed     = false,
                    voidTargetCF    = nil,
                    nextTeleportAt  = 0,
                    ammoActionAt    = 0,
                    hideOrbitUntil  = 0,
                    randPos         = nil,
                    randT           = 0,
                    lastFakePos     = nil,
                    csyncCF         = nil,
                    csyncLV         = nil,
                    csyncAV         = nil,
                    csyncLocalCF    = nil,
                    csyncLocalLV    = nil,
                    csyncLocalAV    = nil,
                    csyncWroteFake  = false,
                    noclipConn      = nil,
                    suspended       = isShootingRange(),
                }

                local function getRoot(char)
                    return char and char:FindFirstChild("HumanoidRootPart")
                end

                local function getFighter()
                    if fighterCtrl and fighterCtrl.LocalFighter then return fighterCtrl.LocalFighter end
                    if fighterCtrl and fighterCtrl.GetFighter then
                        local ok, fighter = pcall(fighterCtrl.GetFighter, fighterCtrl, lplr)
                        if ok then return fighter end
                    end
                    return nil
                end

                local function pressKey(kc)
                    vim:SendKeyEvent(true,  kc, false, game)
                    task.wait(0.03)
                    vim:SendKeyEvent(false, kc, false, game)
                end

                local function scanWeapon(plr)
                    local vms = ws2:FindFirstChild("ViewModels")
                    if not vms then return "" end
                    for _, model in vms:GetChildren() do
                        if model:IsA("Model") then
                            local sp = model.Name:find(" - ", 1, true)
                            if sp and model.Name:sub(1, sp - 1) == plr.Name then
                                return model.Name:sub(sp + 3):lower()
                            end
                        end
                    end
                    return ""
                end

                local function playerIsDead(plr)
                    local char = plr and plr.Character
                    local hum  = char and char:FindFirstChildOfClass("Humanoid")
                    return not char or not hum or hum.Health <= 0 or not getRoot(char)
                end

                local function isInvincible(plr)
                    local char = plr and plr.Character
                    if not char then return true end
                    local root = getRoot(char)
                    if not root then return true end
                    for _, obj in root:GetChildren() do
                        if obj:IsA("Attachment") and obj.Name == "Attachment" then
                            return true
                        end
                    end
                    return char:FindFirstChild("InvincibilityParticles", true) ~= nil
                end

                local function isKatana(plr)
                    return scanWeapon(plr):find("katana", 1, true) ~= nil
                end

                local function isRiotShield(plr)
                    local weapon = scanWeapon(plr)
                    return weapon:find("riot", 1, true) ~= nil or weapon:find("shield", 1, true) ~= nil
                end

                local function IsValidMatch(player)
                    return player:GetAttribute("EnvironmentID") == lplr:GetAttribute("EnvironmentID")
                end

                local function isNearOtherMatch(pos, ignorePlayer)
                    local avoidDistance = cfg.otherMatchAvoidDistance or 1000
                    if typeof(pos) ~= "Vector3" or avoidDistance <= 0 then return false end
                    for _, plr in players:GetPlayers() do
                        if plr ~= lplr and plr ~= ignorePlayer and not IsValidMatch(plr) then
                            local otherRoot = getRoot(plr.Character)
                            if otherRoot and (otherRoot.Position - pos).Magnitude <= avoidDistance then
                                return true
                            end
                        end
                    end
                    return false
                end

                local function isSafeRagebotPos(pos, targetPlayer)
                    return not isNearOtherMatch(pos, targetPlayer)
                end

                local function shouldSkip(plr)
                    if plr == lplr or playerIsDead(plr) then return true end
                    if not IsValidMatch(plr) then return true end
                    if isInvincible(plr) then return true end
                    local root = getRoot(plr.Character)
                    if root and isNearOtherMatch(root.Position, plr) then return true end
                    return root and root:FindFirstChild("TeammateLabel") ~= nil
                end

                local function getBestTarget()
                    local root = getRoot(lplr.Character)
                    if not root then return nil end
                    if cfg.prioritizedPlayer then
                        local priorityPlayer = players:FindFirstChild(cfg.prioritizedPlayer)
                        if priorityPlayer and not shouldSkip(priorityPlayer) then
                            return priorityPlayer
                        end
                    end
                    local best, bestV = nil, math.huge
                    local useHP = cfg.targetMode == "Lowest Health"
                    for _, plr in players:GetPlayers() do
                        if not shouldSkip(plr) then
                            local char  = plr.Character
                            local tr    = getRoot(char)
                            local hum   = char and char:FindFirstChildOfClass("Humanoid")
                            local value = useHP and hum.Health or (tr.Position - root.Position).Magnitude
                            if cfg.autoPriority then
                                if cfg.priorityVoided and tr.Position.Magnitude > 1000000 then
                                    value -= 2000000000
                                end
                                if cfg.priorityAttackers and scanWeapon(plr) ~= "" then
                                    value -= 1000000000
                                end
                            end
                            if value < bestV then
                                bestV = value
                                best  = plr
                            end
                        end
                    end
                    return best
                end

                local function hasValidTarget()
                    return state.target and not playerIsDead(state.target) and not isInvincible(state.target)
                end

                local function updateRagebotStatus()
                    local target  = hasValidTarget() and state.target or nil
                    local voiding = not target or ((cfg.mode == "Void" or cfg.mode == "Orbit") and not state.voidExposed)
                    setRagebotStatus(state.active and cfg.on, target, voiding)
                end

                local function shouldShoot()
                    if not hasValidTarget() then return false end
                    if isKatana(state.target) then return false end
                    if cfg.mode == "Void" and not state.voidExposed then return false end
                    return true
                end

                local function getEquippedSlot()
                    local fighter = getFighter()
                    local item    = fighter and fighter.EquippedItem
                    if not item then return nil end
                    local slot = item:Get("Slot")
                    return tonumber(slot)
                end

                local function equipSlot(slot)
                    slot = tonumber(slot) or 1
                    local key = slotKey[slot] or Enum.KeyCode.One
                    pcall(function() pressKey(key) end)
                end

                local function applyWeaponRageProfile()
                    if cfg.weaponSpecialize == false then return "default" end
                    local slot = getEquippedSlot()
                    local pref = cfg.preferredWeapon or "primary"

                    if cfg.autoEquipPreferred ~= false then
                        local want = (pref == "secondary" and (cfg.secondarySlot or 2))
                            or (pref == "melee" and (cfg.meleeSlot or 3))
                            or (cfg.primarySlot or 1)
                        if slot ~= want then
                            equipSlot(want)
                            slot = want
                        end
                    end

                    local kind
                    if slot == (cfg.meleeSlot or 3) or pref == "melee" then
                        kind = "melee"
                    elseif slot == (cfg.secondarySlot or 2) or pref == "secondary" then
                        kind = "secondary"
                    else
                        kind = "primary"
                    end

                    if kind == "primary" then
                        cfg.mode           = "Orbit"
                        cfg.hyper          = true
                        cfg.orbitDist      = 3.2
                        cfg.orbitHeight    = 2.2
                        cfg.strafeSpeed    = 6
                        cfg.teleportDelay  = 0.035
                        cfg.predictLead    = 0.14
                        cfg.behindDist     = 3.5
                        cfg.randomMovement = false
                        cfg.dirBack        = true
                        cfg.dirFront       = false
                        cfg.dirLeft        = true
                        cfg.dirRight       = true
                    elseif kind == "secondary" then
                        cfg.mode           = "Teleport"
                        cfg.hyper          = false
                        cfg.orbitDist      = 2.6
                        cfg.orbitHeight    = 1.6
                        cfg.strafeSpeed    = 4
                        cfg.teleportDelay  = 0.028
                        cfg.predictLead    = 0.11
                        cfg.behindDist     = 3.0
                        cfg.randomMovement = true
                        cfg.randomRefresh  = 0.07
                        cfg.dirBack        = true
                        cfg.dirFront       = true
                        cfg.dirLeft        = true
                        cfg.dirRight       = true
                    else
                        cfg.mode             = "Underground"
                        cfg.hyper            = true
                        cfg.orbitDist        = 1.6
                        cfg.orbitHeight      = 0.6
                        cfg.strafeSpeed      = 8
                        cfg.teleportDelay    = 0.02
                        cfg.predictLead      = 0.08
                        cfg.behindDist       = 2.2
                        cfg.undergroundDepth = 4
                        cfg.randomMovement   = false
                        cfg.dirBack          = true
                        cfg.dirFront         = false
                        cfg.dirLeft          = true
                        cfg.dirRight         = true
                        cfg.dirDown          = true
                    end

                    state.weaponKind = kind
                    return kind
                end

                local function handleAmmo()
                    local fighter = getFighter()
                    local item    = fighter and fighter.EquippedItem
                    if not fighter or not item then return false end
                    local ammo = item:Get("Ammo") or 0
                    local slot = item:Get("Slot") or 1
                    local now  = tick()
                    if fighter:Get("Reloading") then
                        state.hideOrbitUntil = math.max(state.hideOrbitUntil or 0, now + 0.25)
                        state.ammoActionAt   = math.max(state.ammoActionAt   or 0, now + 0.1)
                        return true
                    end
                    if ammo > 0 then return false end
                    if now < (state.ammoActionAt or 0) then return true end

                    local primary   = cfg.primarySlot   or 1
                    local secondary = cfg.secondarySlot  or 2
                    if slot == primary and cfg.autoSwapSecondary then
                        state.ammoActionAt   = now + 0.45
                        state.hideOrbitUntil = math.max(state.hideOrbitUntil or 0, now + 0.45)
                        pressKey(slotKey[secondary] or Enum.KeyCode.Two)
                        return true
                    end
                    if slot == secondary and cfg.autoReloadPrimary then
                        state.ammoActionAt   = now + 0.6
                        state.hideOrbitUntil = math.max(state.hideOrbitUntil or 0, now + 0.75)
                        pressKey(slotKey[primary] or Enum.KeyCode.One)
                        task.delay(0.18, function()
                            if not state.active then return end
                            local f2 = getFighter()
                            local i2 = f2 and f2.EquippedItem
                            if f2 and i2 and (i2:Get("Slot") or 1) == primary and (i2:Get("Ammo") or 0) <= 0 and not f2:Get("Reloading") then
                                pressKey(Enum.KeyCode.R)
                            end
                        end)
                        return true
                    end
                    if slot == primary and cfg.autoReloadPrimary then
                        state.ammoActionAt   = now + 0.5
                        state.hideOrbitUntil = math.max(state.hideOrbitUntil or 0, now + 0.75)
                        pressKey(Enum.KeyCode.R)
                        return true
                    end
                    return true
                end

                local function buildCameraData(fromPos, part)
                    if not rbUtil or not part then return nil end
                    local look = CFrame.new(fromPos, part.Position)
                    local data = {}
                    data[utf8.char(1)] = {
                        [utf8.char(0)] = rbUtil:EncodeCFrame(look),
                        [utf8.char(1)] = rbUtil:EncodeCFrame(look),
                        [utf8.char(2)] = part,
                        [utf8.char(3)] = rbUtil:EncodeCFrame(part.CFrame:ToObjectSpace(CFrame.new(part.Position)))
                    }
                    return data
                end

                local function doFire(part)
                    local fighter = getFighter()
                    local item    = fighter and fighter.EquippedItem
                    if not item or not part then return false end

                    local cam      = ws2.CurrentCamera
                    local fromPos  = (state.csyncCF and state.csyncCF.Position) or (cam and cam.CFrame.Position) or part.Position
                    local anyFired = false
                    local attempts = math.max(1, math.floor(cfg.shootAttempts or 1))

                    for _ = 1, attempts do
                        local fired = false
                        if cfg.useManipulation and useItemRemote and rbEnums and rbUtil then
                            local ammo = item.Get and (item:Get("Ammo") or 0) or 0
                            if ammo > 0 then
                                local oid       = item:Get("ObjectID")
                                local shootEnum = rbEnums:ToEnum("StartShooting")
                                local data      = buildCameraData(fromPos, part)
                                if oid and shootEnum and data then
                                    fired = pcall(function()
                                        useItemRemote:FireServer(oid, shootEnum, data, nil)
                                    end)
                                end
                            end
                        end
                        if not fired and item.UseItem then
                            fired = pcall(function() item:UseItem() end)
                        end
                        if not fired and fighter and fighter.UseItem then
                            fired = pcall(function() fighter:UseItem() end)
                        end
                        anyFired = anyFired or fired
                    end
                    return anyFired
                end

                local function isLobby()
                    local playerGui = lplr:FindFirstChild("PlayerGui")
                    local mainGui   = playerGui and playerGui:FindFirstChild("MainGui")
                    local mainFrame = mainGui   and mainGui:FindFirstChild("MainFrame")
                    local lobby     = mainFrame  and mainFrame:FindFirstChild("Lobby")
                    local currency  = lobby      and lobby:FindFirstChild("Currency")
                    return currency and currency.Visible == true
                end

                local function getDuel()
                    if not rbDuelMod then
                        local ps = lplr:FindFirstChild("PlayerScripts")
                        local ct = ps and ps:FindFirstChild("Controllers")
                        local dc = ct and ct:FindFirstChild("DuelController")
                        if dc then
                            local ok, mod = pcall(require, dc)
                            if ok and mod then rbDuelMod = mod end
                        end
                    end
                    if rbDuelMod and rbDuelMod.GetDuel then
                        local ok, duel = pcall(rbDuelMod.GetDuel, rbDuelMod, lplr)
                        if ok then return duel end
                    end
                end

                local function isValidMatch()
                    if isLobby() or isShootingRange() then return false end
                    local char = lplr.Character
                    local root = getRoot(char)
                    local hum  = char and char:FindFirstChildOfClass("Humanoid")
                    if not char or not root or not hum or hum.Health <= 0 then return false end
                    local duel = getDuel()
                    if duel ~= nil then return true end
                    local fighter = getFighter()
                    return fighter ~= nil
                end

                local function inMatch()
                    local now = tick()
                    if now - rbInMatchT < 0.25 then return rbInMatch end
                    rbInMatchT = now
                    rbInMatch  = isValidMatch()
                    return rbInMatch
                end

                local function undergroundPos(head, targetRoot)
                    local depth  = math.clamp(cfg.undergroundDepth or 6, 3, 8)
                    local radius = math.clamp(cfg.orbitDist or 3, 1.25, 4)
                    return head.Position - targetRoot.CFrame.LookVector * radius + Vector3.new(0, -depth, 0)
                end

                local oldFireServerRagebot
                local rbHookInstalled = false
                local enterVoidState
                local setVoidCsync

                local function setCsync(cf, pos, dt)
                    local old       = state.lastFakePos
                    state.csyncCF   = cf
                    state.csyncLV   = old and dt and dt > 0 and (pos - old) / dt or Vector3.zero
                    state.csyncAV   = Vector3.zero
                    state.lastFakePos = pos
                end

                local function applyExternalMovementVelocity()
                    local fn = getgenv and getgenv().__LionApplyMovementVelocity
                    if type(fn) == "function" then pcall(fn) end
                end

                local function clearCsyncTarget()
                    state.csyncCF     = nil
                    state.csyncLV     = nil
                    state.csyncAV     = nil
                    state.lastFakePos = nil
                end

                local function isRagebotSettling()
                    return os.clock() < (cfg.settleUntil or 0)
                end

                local function restoreLocalRoot(root)
                    if not root or not state.csyncLocalCF then return false end
                    local liveVelocity = root.AssemblyLinearVelocity
                    root.CFrame        = state.csyncLocalCF
                    if state.csyncLocalLV then
                        root.AssemblyLinearVelocity = Vector3.new(state.csyncLocalLV.X, liveVelocity.Y, state.csyncLocalLV.Z)
                    end
                    if state.csyncLocalAV then
                        root.AssemblyAngularVelocity = state.csyncLocalAV
                    end
                    return true
                end

                local function startCsync()
                    if state.csyncHbConn then return end
                    state.csyncHbConn = runservice.Heartbeat:Connect(function()
                        local root = getRoot(lplr.Character)
                        if not root then return end
                        if state.csyncWroteFake and state.csyncLocalCF then
                            restoreLocalRoot(root)
                        end
                        if isRagebotSettling() then
                            state.csyncLocalCF   = root.CFrame
                            state.csyncLocalLV   = root.AssemblyLinearVelocity
                            state.csyncLocalAV   = root.AssemblyAngularVelocity
                            state.csyncWroteFake = false
                            return
                        end
                        state.csyncLocalCF = root.CFrame
                        state.csyncLocalLV = root.AssemblyLinearVelocity
                        state.csyncLocalAV = root.AssemblyAngularVelocity
                        if state.csyncCF then
                            root.CFrame = state.csyncCF
                            local fakeVelocity  = state.csyncLV or state.csyncLocalLV or root.AssemblyLinearVelocity
                            local localVelocity = state.csyncLocalLV or root.AssemblyLinearVelocity
                            root.AssemblyLinearVelocity  = Vector3.new(fakeVelocity.X, localVelocity.Y, fakeVelocity.Z)
                            root.AssemblyAngularVelocity = state.csyncAV or state.csyncLocalAV or root.AssemblyAngularVelocity
                            state.csyncWroteFake = true
                        else
                            state.csyncWroteFake = false
                        end
                    end)
                    runservice:BindToRenderStep("IDK_RagebotCsync", Enum.RenderPriority.Camera.Value - 1, function()
                        local root = getRoot(lplr.Character)
                        if not root or not state.csyncLocalCF then return end
                        local restored = false
                        if state.csyncWroteFake and restoreLocalRoot(root) then
                            state.csyncWroteFake = false
                            restored = true
                        end
                        if restored then applyExternalMovementVelocity() end
                    end)
                end

                local function stopCsync()
                    if state.csyncHbConn then state.csyncHbConn:Disconnect(); state.csyncHbConn = nil end
                    runservice:UnbindFromRenderStep("IDK_RagebotCsync")
                    restoreLocalRoot(getRoot(lplr.Character))
                    clearCsyncTarget()
                    state.csyncLocalCF   = nil
                    state.csyncLocalLV   = nil
                    state.csyncLocalAV   = nil
                    state.csyncWroteFake = false
                end

                local function voidRand()
                    local n = math.random(-2147483646, 2147483646)
                    repeat n = math.random(-2147483646, 2147483646)
                    until n < -1147483646 or n > 1147483646
                    return n
                end

                local function voidRandCF()
                    return CFrame.new(voidRand(), voidRand(), voidRand()) * CFrame.Angles(math.pi, math.pi, math.pi)
                end

                setVoidCsync = function(cf, lv, av)
                    state.csyncCF     = cf
                    state.csyncLV     = lv or Vector3.zero
                    state.csyncAV     = av or Vector3.zero
                    state.lastFakePos = cf and cf.Position or nil
                end

                enterVoidState = function()
                    state.voidTargetCF  = nil
                    state.voidExposed   = false
                    state.orbitClientCF = nil
                    if not state.active or not cfg.on then
                        clearCsyncTarget()
                        updateRagebotStatus()
                        return
                    end
                    if cfg.voidSpam then
                        setVoidCsync(voidRandCF())
                    else
                        clearCsyncTarget()
                    end
                    updateRagebotStatus()
                end

                local function installRagebotHook()
                    if rbHookInstalled then return end
                    if not useItemRemote then return end
                    rbHookInstalled = true
                    oldFireServerRagebot = hookfunction(useItemRemote.FireServer, newcclosure(function(self, oid, action, cameradata, ...)
                        if state.active and cfg.on and cfg.mode == "Void" and cfg.useManipulation and action == rbEnums:ToEnum("StartShooting") then
                            if isLobby() or not inMatch() then
                                return oldFireServerRagebot(self, oid, action, cameradata, ...)
                            end
                            local target = state.target
                            if hasValidTarget() and not isKatana(target) then
                                local tc   = target.Character
                                local tr   = getRoot(tc)
                                local head = tc and (tc:FindFirstChild("Head") or tr)
                                if tr and head then
                                    local shootPos = isRiotShield(target)
                                        and (tr.Position - tr.CFrame.LookVector * (cfg.behindDist or 4))
                                        or  (tr.Position - tr.CFrame.LookVector * 2.5 + Vector3.new(0, 1.5, 0))
                                    if not isSafeRagebotPos(shootPos, target) then
                                        enterVoidState()
                                        return oldFireServerRagebot(self, oid, action, cameradata, ...)
                                    end
                                    local shootCF = CFrame.new(shootPos, head.Position)
                                    state.voidExposed  = true
                                    state.voidTargetCF = shootCF
                                    setVoidCsync(shootCF, Vector3.zero, Vector3.zero)
                                    updateRagebotStatus()
                                    task.wait(0.02)
                                    local newData = buildCameraData(shootPos, head) or cameradata
                                    task.spawn(function()
                                        task.wait(0.05)
                                        enterVoidState()
                                    end)
                                    return oldFireServerRagebot(self, oid, action, newData, ...)
                                end
                            end
                        end
                        return oldFireServerRagebot(self, oid, action, cameradata, ...)
                    end))
                end

                local function enableVoidCsync()
                    if state.voidHbConn then return end
                    startCsync()
                    state.voidHbConn = runservice.Heartbeat:Connect(function()
                        if isRagebotSettling() then
                            state.voidTargetCF = nil
                            state.voidExposed  = false
                            clearCsyncTarget()
                            return
                        end
                        local targetCF = state.voidTargetCF
                        if targetCF then
                            setVoidCsync(targetCF, Vector3.zero, Vector3.zero)
                        elseif cfg.voidSpam then
                            setVoidCsync(voidRandCF())
                        else
                            clearCsyncTarget()
                        end
                    end)
                end

                local function disableVoidCsync()
                    if state.voidHbConn then state.voidHbConn:Disconnect(); state.voidHbConn = nil end
                    runservice:UnbindFromRenderStep("IDK_RagebotVoid")
                    state.voidTargetCF = nil
                    state.voidThread   = nil
                    state.voidExposed  = false
                end

                local function StartOrbitRenderFix()
                    if state.orbitRenderRunning then return end
                    state.orbitRenderRunning = true
                    runservice:BindToRenderStep("IDK_RagebotOrbit", Enum.RenderPriority.First.Value, function()
                        if not state.orbitClientCF then return end
                        local root = getRoot(lplr.Character)
                        if not root then return end
                        root.CFrame = state.orbitClientCF
                        applyExternalMovementVelocity()
                    end)
                end

                local function StopOrbitRenderFix()
                    if not state.orbitRenderRunning then return end
                    runservice:UnbindFromRenderStep("IDK_RagebotOrbit")
                    state.orbitRenderRunning = false
                    state.orbitClientCF      = nil
                end

                local function startVoidLoop(myGen)
                    if state.voidThread then return end
                    enableVoidCsync()
                    local voidThread
                    voidThread = task.spawn(function()
                        while state.active and cfg.on and rbGen == myGen and not state.suspended do
                            if isRagebotSettling() then
                                state.voidTargetCF = nil
                                state.voidExposed  = false
                                clearCsyncTarget()
                                task.wait(0.03)
                                continue
                            end
                            if not inMatch() or not hasValidTarget() or isKatana(state.target) then
                                enterVoidState()
                                task.wait(0.1)
                                continue
                            end
                            enterVoidState()
                            if cfg.voidHideTime > 0 then task.wait(cfg.voidHideTime) end
                            if not state.active or not cfg.on or rbGen ~= myGen or state.suspended or not inMatch() then break end
                            local target = state.target
                            if hasValidTarget() and not isKatana(target) then
                                local tc   = target.Character
                                local tr   = getRoot(tc)
                                local head = tc and (tc:FindFirstChild("Head") or tr)
                                if tr and head then
                                    local shootPos = isRiotShield(target)
                                        and (tr.Position - tr.CFrame.LookVector * (cfg.behindDist or 4))
                                        or  (tr.Position - tr.CFrame.LookVector * 2.5 + Vector3.new(0, 1.5, 0))
                                    if not isSafeRagebotPos(shootPos, target) then
                                        enterVoidState()
                                        task.wait(0.1)
                                        continue
                                    end
                                    local shootCF = CFrame.new(shootPos, head.Position)
                                    state.voidExposed  = true
                                    state.voidTargetCF = shootCF
                                    setVoidCsync(shootCF, Vector3.zero, Vector3.zero)
                                    updateRagebotStatus()
                                    if cfg.voidShootTime > 0 then task.wait(cfg.voidShootTime) end
                                    if hasValidTarget() and not isKatana(target) then
                                        doFire(head)
                                    end
                                    task.wait(0.05)
                                    enterVoidState()
                                end
                            end
                        end
                        if state.voidThread == voidThread then state.voidThread = nil end
                        if rbGen == myGen and not state.suspended and state.voidThread == nil then
                            disableVoidCsync()
                        end
                    end)
                    state.voidThread = voidThread
                end

                local function enableNoclip()
                    if state.noclipConn then return end
                    state.noclipConn = runservice.Stepped:Connect(function()
                        local char = lplr.Character
                        if not char then return end
                        for _, part in char:GetDescendants() do
                            if part:IsA("BasePart") then
                                part.CanCollide = false
                            end
                        end
                    end)
                end

                local function startAmmoLoop()
                    if state.ammoThread then return end
                    state.ammoThread = task.spawn(function()
                        while state.active do
                            if isShootingRange() then task.wait(0.1); continue end
                            if not handleAmmo() and shouldShoot() and not cfg.hyper then
                                local tc   = state.target and state.target.Character
                                local head = tc and (tc:FindFirstChild("Head") or getRoot(tc))
                                if head then
                                    if cfg.shootDelay > 0 then task.wait(cfg.shootDelay) end
                                    doFire(head)
                                end
                            end
                            task.wait(math.max(0.01, cfg.acSpd))
                        end
                        state.ammoThread = nil
                    end)
                end

                local function stopRagebot()
                    rbGen += 1
                    state.active         = false
                    cfg.on               = false
                    setRagebotStatus(false)
                    if state.conn       then state.conn:Disconnect();       state.conn       = nil end
                    if state.noclipConn then state.noclipConn:Disconnect(); state.noclipConn = nil end
                    state.target         = nil
                    state.voidExposed    = false
                    state.nextTeleportAt = 0
                    state.ammoActionAt   = 0
                    state.hideOrbitUntil = 0
                    state.randPos        = nil
                    state.randT          = 0
                    state.lastFakePos    = nil
                    rbInMatchT           = 0
                    rbInMatch            = false
                    stopCsync()
                    disableVoidCsync()
                    StopOrbitRenderFix()
                    local char = lplr.Character
                    if char then
                        for _, part in char:GetDescendants() do
                            if part:IsA("BasePart") then
                                part.CanCollide = true
                            end
                        end
                    end
                end

                rbGen += 1
                local myGen = rbGen
                setRagebotStatus(true, nil, true)
                startAmmoLoop()
                installRagebotHook()
                if not state.suspended then
                    enableNoclip()
                    if cfg.mode == "Void" then
                        startVoidLoop(myGen)
                    elseif cfg.mode == "Orbit" then
                        enableVoidCsync()
                    else
                        startCsync()
                    end
                end

                local aaPhase    = 0
                local orbitAngle = math.random() * math.pi * 2

                local function rnd()    return math.random() * 2 - 1 end
                local function rndDir()
                    local angle = math.random() * math.pi * 2
                    return Vector3.new(math.cos(angle), 0, math.sin(angle))
                end

                local function getDirs(targetRoot)
                    local dirs  = {}
                    local look  = targetRoot.CFrame.LookVector
                    local right = targetRoot.CFrame.RightVector
                    if cfg.dirBack  then table.insert(dirs, -look)  end
                    if cfg.dirFront then table.insert(dirs, look)   end
                    if cfg.dirLeft  then table.insert(dirs, -right) end
                    if cfg.dirRight then table.insert(dirs, right)  end
                    if #dirs == 0 then
                        dirs[1] = -look
                        dirs[2] = right
                        dirs[3] = -right
                    end
                    return dirs
                end

                local function pickOffset(targetRoot, head)
                    local dirs   = getDirs(targetRoot)
                    local dir    = dirs[math.random(1, #dirs)]
                    local radius = math.clamp(cfg.orbitDist  or 3, 1.25, 5)
                    local height = math.clamp(cfg.orbitHeight or 2, -2,   6)
                    local pos    = head.Position + dir * radius + Vector3.new(0, height, 0)
                    if cfg.dirUp   and math.random() < 0.2  then
                        pos += Vector3.new(0,  math.max(1, height), 0)
                    elseif cfg.dirDown and math.random() < 0.15 then
                        pos += Vector3.new(0, -math.max(1, math.min(3, cfg.undergroundDepth or 2)), 0)
                    end
                    return pos
                end

                state.conn = runservice.Stepped:Connect(function(_, dt)
                    if not state.active or not cfg.on then
                        if state.conn then state.conn:Disconnect(); state.conn = nil end
                        return
                    end

                    if isShootingRange() then
                        if not state.suspended then
                            state.suspended    = true
                            state.target       = nil
                            state.randPos      = nil
                            state.voidTargetCF = nil
                            state.voidExposed  = false
                            if state.noclipConn then
                                state.noclipConn:Disconnect()
                                state.noclipConn = nil
                            end
                            stopCsync()
                            disableVoidCsync()
                            StopOrbitRenderFix()
                            updateRagebotStatus()
                        end
                        return
                    end

                    if state.suspended then
                        state.suspended = false
                        enableNoclip()
                        if cfg.mode == "Void" then
                            startVoidLoop(myGen)
                        elseif cfg.mode == "Orbit" then
                            enableVoidCsync()
                            StartOrbitRenderFix()
                        else
                            startCsync()
                        end
                    end

                    local root = getRoot(lplr.Character)
                    if not root then return end

                    if isRagebotSettling() then
                        state.voidTargetCF  = nil
                        state.voidExposed   = false
                        state.orbitClientCF = nil
                        clearCsyncTarget()
                        updateRagebotStatus()
                        return
                    end

                    if not inMatch() then
                        clearCsyncTarget()
                        state.target = nil
                        if cfg.mode == "Orbit" then
                            enterVoidState()
                        else
                            updateRagebotStatus()
                        end
                        return
                    end

                    local now = tick()
                    if state.target and playerIsDead(state.target) then
                        state.target = nil
                    end
                    if state.target and isInvincible(state.target) then
                        clearCsyncTarget()
                        if cfg.mode == "Orbit" then
                            enterVoidState()
                        else
                            updateRagebotStatus()
                        end
                        return
                    end

                    if now - rbTgtT >= 0.05 and (cfg.autoSwitch or not state.target) then
                        rbTgtT = now
                        if cfg.autoSwitch then
                            local target = getBestTarget()
                            if target then
                                if cfg.sendNotification and state.target ~= target then
                                    mainapi:SafeNotify({
                                        Title    = "ragebot",
                                        Text     = "prioritized " .. target.Name,
                                        Duration = 2,
                                    })
                                end
                                state.target = target
                            end
                        elseif not state.target then
                            state.target = getBestTarget()
                        end
                    end

                    if not state.target then
                        clearCsyncTarget()
                        if cfg.mode == "Orbit" then
                            enterVoidState()
                        else
                            updateRagebotStatus()
                        end
                        return
                    end

                    local tc   = state.target.Character
                    local tr   = getRoot(tc)
                    local head = tc and (tc:FindFirstChild("Head") or tr)
                    if not tc or not tr or not head then
                        state.target = nil
                        updateRagebotStatus()
                        return
                    end

                    if isNearOtherMatch(tr.Position, state.target) then
                        state.target  = nil
                        state.randPos = nil
                        if cfg.mode == "Orbit" or cfg.mode == "Void" then
                            enterVoidState()
                        else
                            clearCsyncTarget()
                            updateRagebotStatus()
                        end
                        return
                    end

                    updateRagebotStatus()
                    applyWeaponRageProfile()

                    if cfg.mode == "Void" then return end

                    if cfg.mode == "Orbit" and (now < (state.hideOrbitUntil or 0) or handleAmmo()) then
                        state.voidTargetCF  = nil
                        state.voidExposed   = false
                        state.orbitClientCF = nil
                        enterVoidState()
                        return
                    end

                    local isUnderground = cfg.mode == "Underground"
                    local isShield      = isRiotShield(state.target)
                    local height        = math.clamp(cfg.orbitHeight or 2,  -2, 6)
                    local radius        = math.clamp(cfg.orbitDist   or 3, 1.25, 5)
                    local targetPos

                    if isShield then
                        targetPos = tr.Position - tr.CFrame.LookVector * (cfg.behindDist or 3)
                    elseif isUnderground then
                        targetPos = undergroundPos(head, tr)
                    elseif cfg.mode == "Teleport" then
                        if cfg.randomMovement then
                            if not state.randPos or (now - (state.randT or 0)) >= (cfg.randomRefresh or 0.08) then
                                state.randT   = now
                                state.randPos = pickOffset(tr, head) + rndDir() * (math.random() * 1.05) + Vector3.new(0, rnd() * 0.7, 0)
                            end
                            targetPos = state.randPos
                        else
                            targetPos = pickOffset(tr, head)
                        end
                    elseif cfg.mode == "Orbit" then
                        orbitAngle += dt * math.max(1, (cfg.strafeSpeed or 5) * 1.5)
                        targetPos   = head.Position + Vector3.new(math.cos(orbitAngle) * radius, height, math.sin(orbitAngle) * radius)
                    else
                        targetPos = undergroundPos(head, tr)
                    end

                    if not isSafeRagebotPos(targetPos, state.target) then
                        state.randPos = nil
                        if cfg.mode == "Orbit" then
                            state.voidTargetCF  = nil
                            state.voidExposed   = false
                            state.orbitClientCF = nil
                            enterVoidState()
                        else
                            clearCsyncTarget()
                            updateRagebotStatus()
                        end
                        return
                    end

                    local faceCF = CFrame.new(targetPos, head.Position)
                    if cfg.antiAim then
                        aaPhase += dt * 20
                        faceCF  = CFrame.new(targetPos, head.Position) * CFrame.Angles(0, math.rad(math.sin(aaPhase) * 70), 0)
                    end

                    if cfg.mode == "Orbit" then
                        if cfg.hyper or not isUnderground then
                            state.voidExposed  = true
                            state.voidTargetCF = faceCF
                            setCsync(faceCF, targetPos, dt)
                            updateRagebotStatus()
                            if shouldShoot() then doFire(head) end
                        end
                    else
                        setCsync(faceCF, targetPos, dt)
                        if cfg.hyper or (cfg.mode == "Orbit" and not isUnderground) then
                            if shouldShoot() then doFire(head) end
                        elseif cfg.mode == "Teleport" and not isUnderground then
                            if now >= (state.nextTeleportAt or 0) then
                                state.nextTeleportAt = now + math.max(0.01, cfg.teleportDelay or 0.04)
                                if shouldShoot() then doFire(head) end
                            end
                        end
                    end
                end)

                Ragebot:Clean(lplr.CharacterAdded:Connect(function()
                    stopCsync()
                    disableVoidCsync()
                    StopOrbitRenderFix()
                    state.target         = nil
                    clearCsyncTarget()
                    state.csyncLocalCF   = nil
                    state.csyncLocalLV   = nil
                    state.csyncLocalAV   = nil
                    state.csyncWroteFake = false
                    state.voidExposed    = false
                    state.hideOrbitUntil = 0
                    if state.active then
                        task.wait(0.5)
                        if state.active then
                            if cfg.mode == "Void" then
                                startVoidLoop(myGen)
                            elseif cfg.mode == "Orbit" then
                                enableVoidCsync()
                                StartOrbitRenderFix()
                            else
                                startCsync()
                            end
                        end
                    end
                end))

                getgenv().__IDKRagebotStop = stopRagebot
                Ragebot:Clean(stopRagebot)
            else
                cfg.on = false
                if getgenv().__IDKRagebotStop then
                    pcall(getgenv().__IDKRagebotStop)
                    getgenv().__IDKRagebotStop = nil
                end
            end
        end
    })

    Ragebot:AddToggle({
        Name     = 'void spam',
        Default  = true,
        Function = function(callback)
            RagebotSettings.voidSpam = callback
            markRagebotSettingsDirty()
        end
    })

    local RagebotHide = Ragebot:AddSlider({
        Name     = 'hide',
        Min      = 0,
        Max      = 1,
        Default  = 0.25,
        Decimal  = 100,
        Suffix   = 's',
        Compact  = true,
        Function = function(value)
            RagebotSettings.voidHideTime = value
            markRagebotSettingsDirty()
        end
    })

    Ragebot:AddSlider({
        Name     = 'attack',
        Min      = 0,
        Max      = 1,
        Default  = 0.03,
        Decimal  = 100,
        Suffix   = 's',
        Compact  = true,
        Parent   = RagebotHide,
        Function = function(value)
            RagebotSettings.voidShootTime = value
            markRagebotSettingsDirty()
        end
    })

    Ragebot:AddSlider({
        Name     = 'shoot attempts',
        Min      = 1,
        Max      = 10,
        Default  = 1,
        Suffix   = 'x',
        Function = function(value)
            RagebotSettings.shootAttempts = math.floor(value)
            markRagebotSettingsDirty()
        end
    })

    Ragebot:AddDropdown({
        Name     = 'attack mode',
        List     = {'gun', 'knife', 'melee'},
        Default  = 'gun',
        Function = function(value)
            RagebotSettings.attackMode = value
            markRagebotSettingsDirty()
        end
    })

    Ragebot:AddDropdown({
        Name     = 'preferred weapon',
        List     = {'primary', 'secondary', 'melee'},
        Default  = 'primary',
        Function = function(value)
            RagebotSettings.preferredWeapon = value
            if value == 'primary' then
                RagebotSettings.primarySlot   = 1
                RagebotSettings.secondarySlot = 2
            elseif value == 'secondary' then
                RagebotSettings.primarySlot   = 2
                RagebotSettings.secondarySlot = 1
            else
                RagebotSettings.primarySlot   = 1
                RagebotSettings.secondarySlot = 2
            end
            markRagebotSettingsDirty()
            pcall(function()
                local keys = {[1]=Enum.KeyCode.One,[2]=Enum.KeyCode.Two,[3]=Enum.KeyCode.Three}
                local slot = (value == 'primary' and 1) or (value == 'secondary' and 2) or 3
                local vim2 = game:GetService("VirtualInputManager")
                vim2:SendKeyEvent(true,  keys[slot], false, game)
                task.wait()
                vim2:SendKeyEvent(false, keys[slot], false, game)
            end)
        end
    })

    Ragebot:AddToggle({
        Name     = 'weapon specialize',
        Default  = true,
        Function = function(callback)
            RagebotSettings.weaponSpecialize = callback
            markRagebotSettingsDirty()
        end
    })

    Ragebot:AddDropdown({
        Name     = 'settings',
        List     = {'swap weapons when empty', 'prefer projectile weapon'},
        Default  = {['swap weapons when empty'] = true},
        Multi    = true,
        Function = function(value)
            RagebotSettings.autoSwapSecondary = value['swap weapons when empty'] == true
            RagebotSettings.autoReloadPrimary = value['swap weapons when empty'] == true
            RagebotSettings.preferProjectile  = value['prefer projectile weapon'] == true
            markRagebotSettingsDirty()
        end
    })

    Ragebot:AddToggle({
        Name     = 'auto prioritize',
        Tab      = 'priority',
        Default  = true,
        Function = function(callback)
            RagebotSettings.autoPriority = callback
            RagebotSettings.autoSwitch   = callback
            markRagebotSettingsDirty()
        end
    })

    Ragebot:AddToggle({
        Name     = 'send notification',
        Tab      = 'priority',
        Function = function(callback)
            RagebotSettings.sendNotification = callback
            markRagebotSettingsDirty()
        end
    })

    Ragebot:AddDropdown({
        Name     = 'auto priority settings',
        Tab      = 'priority',
        List     = {'attackers', 'voided players'},
        Default  = {attackers = true, ['voided players'] = true},
        Multi    = true,
        Function = function(value)
            RagebotSettings.priorityAttackers = value.attackers == true
            RagebotSettings.priorityVoided    = value['voided players'] == true
            markRagebotSettingsDirty()
        end
    })

    local function getPlayerNames()
        local names = {}
        for _, player in game:GetService('Players'):GetPlayers() do
            if player ~= game:GetService('Players').LocalPlayer then
                table.insert(names, player.Name)
            end
        end
        table.sort(names)
        return names
    end

    local Prioritized = Ragebot:AddDropdown({
        Name      = 'prioritized',
        Tab       = 'priority',
        List      = getPlayerNames(),
        AllowNull = true,
        Function  = function(value)
            RagebotSettings.prioritizedPlayer = value
            markRagebotSettingsDirty()
        end
    })

    local function refreshPriorityPlayers()
        Prioritized:SetList(getPlayerNames())
    end
    Ragebot:Clean(game:GetService('Players').PlayerAdded:Connect(refreshPriorityPlayers))
    Ragebot:Clean(game:GetService('Players').PlayerRemoving:Connect(refreshPriorityPlayers))

    Ragebot:SetEnabled(true)
end)

-- ══════════════════════════════════════════════════════════════════════════
--  FLICKBOT GUI  (flickbot_eclipse_v63, unchanged)
-- ══════════════════════════════════════════════════════════════════════════

local Library = { Unloaded = false }

local function Create(class, props, children)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do inst[k] = v end
    for _, c in pairs(children or {}) do c.Parent = inst end
    return inst
end
local function Tween(obj, props, time, style, dir)
    TweenService:Create(
        obj,
        TweenInfo.new(time or 0.2,
                      style or Enum.EasingStyle.Quad,
                      dir   or Enum.EasingDirection.Out),
        props
    ):Play()
end
local function GetTextSize(text, size, font)
    return game:GetService("TextService"):GetTextSize(
        text, size, font, Vector2.new(10000, 10000))
end

if _G.EclipseFlickbotGui then _G.EclipseFlickbotGui:Destroy() end
local ScreenGui = Create("ScreenGui", {
    Name           = "EclipseFlickbotGui",
    Parent         = game:GetService("CoreGui"),
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    ResetOnSpawn   = false,
    IgnoreGuiInset = true,
})
_G.EclipseFlickbotGui = ScreenGui
local UIScale = Create("UIScale", { Parent = ScreenGui })
local function UpdateScale()
    local vp    = ws.CurrentCamera.ViewportSize
    local scale = math.min(
        (vp.X - 40) / CFG.BaseSize.X,
        (vp.Y - 40) / CFG.BaseSize.Y, 1)
    UIScale.Scale = math.max(scale, 0.55)
end
local function BindCameraScale()
    ws.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateScale)
    UpdateScale()
end
ws:GetPropertyChangedSignal("CurrentCamera"):Connect(BindCameraScale)
BindCameraScale()

local NotifContainer = Create("Frame", {
    Parent      = ScreenGui,
    Position    = UDim2.new(1, -20, 0, 20),
    AnchorPoint = Vector2.new(1, 0),
    Size        = UDim2.new(0, 300, 1, 0),
    BackgroundTransparency = 1,
    ZIndex      = 100,
}, {
    Create("UIListLayout", {
        Padding             = UDim.new(0, 5),
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment   = Enum.VerticalAlignment.Top,
    })
})
local function Notify(msg, ntype)
    local color = (ntype == "success" and Color3.fromRGB(100, 255, 100))
               or (ntype == "warning" and Color3.fromRGB(255, 100, 100))
               or CFG.AccentColor
    local F = Create("Frame", {
        Parent           = NotifContainer,
        Size             = UDim2.new(0, 0, 0, 30),
        BackgroundColor3 = CFG.MainColor,
        BorderSizePixel  = 0,
        ClipsDescendants = true,
    }, {
        Create("UIStroke",  { Color = CFG.AccentColor, Thickness = 1, Transparency = 0.5 }),
        Create("Frame",     { Size  = UDim2.new(0, 2, 1, 0), BackgroundColor3 = color }),
        Create("TextLabel", {
            Text           = msg,
            TextColor3     = CFG.TextColor,
            Font           = CFG.Font,
            TextSize       = 12,
            Size           = UDim2.new(1, -10, 1, 0),
            Position       = UDim2.new(0, 10, 0, 0),
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left,
        }),
    })
    Tween(F, { Size = UDim2.new(0, 260, 0, 35) }, 0.5, Enum.EasingStyle.Back)
    task.delay(3, function()
        Tween(F, { Size = UDim2.new(0, 260, 0, 0), BackgroundTransparency = 1 }, 0.5)
        task.wait(0.5)
        F:Destroy()
    end)
end

local TooltipLabel = Create("TextLabel", {
    Parent           = ScreenGui,
    Size             = UDim2.new(0, 0, 0, 20),
    BackgroundColor3 = CFG.SecondaryColor,
    TextColor3       = CFG.TextColor,
    TextSize         = 11,
    Font             = CFG.Font,
    BorderSizePixel  = 0,
    Visible          = false,
    ZIndex           = 200,
}, {
    Create("UIPadding", { PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5) }),
    Create("UIStroke",  { Color = CFG.StrokeColor }),
})
local function AddTooltip(obj, text)
    obj.MouseEnter:Connect(function()
        TooltipLabel.Text    = text
        TooltipLabel.Size    = UDim2.fromOffset(
            GetTextSize(text, 11, CFG.Font).X + 12, 20)
        TooltipLabel.Visible = true
    end)
    obj.MouseLeave:Connect(function() TooltipLabel.Visible = false end)
end
RunService.RenderStepped:Connect(function()
    if TooltipLabel.Visible then
        local m = UserInputService:GetMouseLocation()
        TooltipLabel.Position = UDim2.fromOffset(m.X + 15, m.Y + 15)
    end
end)

local MainFrame = Create("Frame", {
    Name             = "MainFrame",
    Parent           = ScreenGui,
    Size             = UDim2.fromOffset(CFG.BaseSize.X, CFG.BaseSize.Y),
    Position         = UDim2.new(0.5, -350, 0.5, -235),
    BackgroundColor3 = CFG.MainColor,
    BorderSizePixel  = 0,
}, {
    Create("UIStroke", { Color = CFG.StrokeColor }),
    Create("UICorner", { CornerRadius = UDim.new(0, 3) }),
})
local Dragging, DragInput, DragStart, StartPos = false, nil, nil, nil
MainFrame.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1
    or i.UserInputType == Enum.UserInputType.Touch then
        Dragging  = true
        DragStart = i.Position
        StartPos  = MainFrame.Position
        i.Changed:Connect(function()
            if i.UserInputState == Enum.UserInputState.End then Dragging = false end
        end)
    end
end)
MainFrame.InputChanged:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseMovement
    or i.UserInputType == Enum.UserInputType.Touch then
        DragInput = i
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if i == DragInput and Dragging then
        local d = i.Position - DragStart
        Tween(MainFrame, {
            Position = UDim2.new(
                StartPos.X.Scale, StartPos.X.Offset + d.X,
                StartPos.Y.Scale, StartPos.Y.Offset + d.Y)
        }, 0.05)
    end
end)

local TopBar = Create("Frame", {
    Parent           = MainFrame,
    Size             = UDim2.new(1, 0, 0, 30),
    BackgroundColor3 = CFG.MainColor,
    BorderSizePixel  = 0,
}, {
    Create("Frame", {
        Size             = UDim2.new(1, 0, 0, 1),
        Position         = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = CFG.StrokeColor,
    }),
})
local TitleLabel = Create("TextLabel", {
    Parent         = TopBar,
    Text           = "flickbot | rivals",
    TextColor3     = CFG.TextDark,
    TextSize       = 13,
    Font           = CFG.Font,
    BackgroundTransparency = 1,
    Size           = UDim2.new(0, 240, 1, 0),
    Position       = UDim2.new(0, 10, 0, 0),
    TextXAlignment = Enum.TextXAlignment.Left,
    RichText       = true,
})
task.spawn(function()
    local textList = {
        "", "f","fl","fli","flic","flick","flickb","flickbo","flickbot",
        "flickbot |","flickbot | r","flickbot | ri","flickbot | riv",
        "flickbot | riva","flickbot | rival","flickbot | rivals",
        "flickbot | rival","flickbot | riva","flickbot | riv",
        "flickbot | ri","flickbot | r","flickbot |",
        "flickbot","flickbo","flickb","flick","flic","fli","fl","f",
    }
    while not Library.Unloaded do
        for _, text in ipairs(textList) do
            if Library.Unloaded then break end
            local display = text
            if string.find(text, "rivals") then
                display = string.gsub(text, "rivals",
                    '<font color="#bdacff">rivals</font>')
            elseif string.find(text, "flickbot") then
                display = string.gsub(text, "flickbot",
                    '<font color="#bdacff">flickbot</font>')
            end
            TitleLabel.Text = display
            task.wait(0.18)
        end
    end
end)

local Content = Create("Frame", {
    Parent   = MainFrame,
    Size     = UDim2.new(1, 0, 1, -30),
    Position = UDim2.new(0, 0, 0, 30),
    BackgroundTransparency = 1,
})
local Sidebar = Create("Frame", {
    Parent           = Content,
    Size             = UDim2.new(0, 60, 1, 0),
    BackgroundColor3 = Color3.fromRGB(17, 17, 17),
    BorderSizePixel  = 0,
}, {
    Create("UIListLayout", {
        Padding             = UDim.new(0, 10),
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment   = Enum.VerticalAlignment.Top,
    }),
    Create("UIPadding", { PaddingTop = UDim.new(0, 15) }),
})
local Pages = Create("Frame", {
    Parent   = Content,
    Size     = UDim2.new(1, -60, 1, 0),
    Position = UDim2.new(0, 60, 0, 0),
    BackgroundTransparency = 1,
})
local Tabs = {}
local function MakeTab(icon)
    local Btn = Create("TextButton", {
        Parent           = Sidebar,
        Size             = UDim2.new(0, 40, 0, 40),
        BackgroundColor3 = CFG.MainColor,
        Text             = "",
        AutoButtonColor  = false,
        Font             = CFG.Font,
    }, {
        Create("ImageLabel", {
            Size                   = UDim2.new(0.6, 0, 0.6, 0),
            Position               = UDim2.new(0.2, 0, 0.2, 0),
            BackgroundTransparency = 1,
            Image                  = "rbxassetid://" .. icon,
            ImageColor3            = CFG.TextDark,
        }),
        Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
    })
    local Page = Create("ScrollingFrame", {
        Parent                 = Pages,
        Size                   = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Visible                = false,
        ScrollBarThickness     = 2,
        ScrollBarImageColor3   = CFG.AccentColor,
        CanvasSize             = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize    = Enum.AutomaticSize.Y,
    })
    Create("UIPadding", {
        Parent        = Page,
        PaddingTop    = UDim.new(0, 15),
        PaddingLeft   = UDim.new(0, 15),
        PaddingRight  = UDim.new(0, 15),
        PaddingBottom = UDim.new(0, 15),
    })
    local LeftCol = Create("Frame", {
        Parent                 = Page,
        Size                   = UDim2.new(0.48, 0, 1, 0),
        BackgroundTransparency = 1,
    }, {
        Create("UIListLayout", {
            Padding   = UDim.new(0, 10),
            SortOrder = Enum.SortOrder.LayoutOrder,
        })
    })
    local RightCol = Create("Frame", {
        Parent                 = Page,
        Size                   = UDim2.new(0.48, 0, 1, 0),
        Position               = UDim2.new(0.52, 0, 0, 0),
        BackgroundTransparency = 1,
    }, {
        Create("UIListLayout", {
            Padding   = UDim.new(0, 10),
            SortOrder = Enum.SortOrder.LayoutOrder,
        })
    })
    Btn.MouseButton1Click:Connect(function()
        for _, t in pairs(Tabs) do
            Tween(t.Btn,  { BackgroundColor3 = CFG.MainColor }, 0.2)
            t.Page.Visible = false
        end
        Tween(Btn, { BackgroundColor3 = CFG.SecondaryColor }, 0.2)
        Page.Visible = true
    end)
    table.insert(Tabs, { Btn = Btn, Page = Page })
    if #Tabs == 1 then
        Tween(Btn, { BackgroundColor3 = CFG.SecondaryColor }, 0.2)
        Page.Visible = true
    end
    local leftNext = true
    local GF = {}
    function GF:Group(title)
        local col  = leftNext and LeftCol or RightCol
        leftNext   = not leftNext
        local GFrame = Create("Frame", {
            Parent            = col,
            Size              = UDim2.new(1, 0, 0, 0),
            AutomaticSize     = Enum.AutomaticSize.Y,
            BackgroundColor3  = Color3.fromRGB(17, 17, 17),
            BorderSizePixel   = 0,
        }, {
            Create("UIStroke", { Color = CFG.StrokeColor }),
            Create("UICorner", { CornerRadius = UDim.new(0, 2) }),
        })
        Create("Frame", {
            Parent           = GFrame,
            Size             = UDim2.new(1, 0, 0, 25),
            BackgroundColor3 = CFG.SecondaryColor,
            BorderSizePixel  = 0,
        }, {
            Create("UICorner", { CornerRadius = UDim.new(0, 2) }),
            Create("Frame", {
                Size             = UDim2.new(1, 0, 0, 5),
                Position         = UDim2.new(0, 0, 1, -5),
                BackgroundColor3 = CFG.SecondaryColor,
                BorderSizePixel  = 0,
            }),
            Create("TextLabel", {
                Text           = title,
                Size           = UDim2.new(1, -20, 1, 0),
                Position       = UDim2.new(0, 8, 0, 0),
                BackgroundTransparency = 1,
                TextColor3     = CFG.TextColor,
                Font           = Enum.Font.GothamBold,
                TextSize       = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
            }),
            Create("Frame", {
                Size             = UDim2.new(0, 4, 0, 4),
                Position         = UDim2.new(1, -10, 0.5, -2),
                BackgroundColor3 = CFG.AccentColor,
                BorderSizePixel  = 0,
            }, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) }),
        })
        local GContent = Create("Frame", {
            Parent            = GFrame,
            Size              = UDim2.new(1, 0, 0, 0),
            Position          = UDim2.new(0, 0, 0, 25),
            AutomaticSize     = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
        }, {
            Create("UIListLayout", {
                Padding   = UDim.new(0, 5),
                SortOrder = Enum.SortOrder.LayoutOrder,
            }),
            Create("UIPadding", {
                PaddingTop    = UDim.new(0, 8),
                PaddingBottom = UDim.new(0, 8),
                PaddingLeft   = UDim.new(0, 8),
                PaddingRight  = UDim.new(0, 8),
            }),
        })
        local IF = {}
        function IF:Toggle(cfg2)
            local Enabled = cfg2.Default or false
            local Frame = Create("TextButton", {
                Parent                 = GContent,
                Size                   = UDim2.new(1, 0, 0, 20),
                BackgroundTransparency = 1,
                Text                   = "",
            })
            local Box = Create("Frame", {
                Parent           = Frame,
                Size             = UDim2.new(0, 12, 0, 12),
                Position         = UDim2.new(0, 0, 0.5, -6),
                BackgroundColor3 = CFG.SecondaryColor,
                BorderSizePixel  = 0,
            }, { Create("UIStroke", { Color = CFG.StrokeColor }) })
            local Check = Create("Frame", {
                Parent           = Box,
                Size             = UDim2.new(1, -4, 1, -4),
                Position         = UDim2.new(0.5, 0, 0.5, 0),
                AnchorPoint      = Vector2.new(0.5, 0.5),
                BackgroundColor3 = CFG.AccentColor,
                BackgroundTransparency = Enabled and 0 or 1,
            })
            local Label = Create("TextLabel", {
                Parent         = Frame,
                Text           = cfg2.Name,
                TextColor3     = Enabled and CFG.TextColor or CFG.TextDark,
                TextSize       = 11,
                Font           = CFG.Font,
                BackgroundTransparency = 1,
                Position       = UDim2.new(0, 18, 0, 0),
                Size           = UDim2.new(1, -18, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
            })
            if cfg2.Risky   then Label.TextColor3 = Color3.fromRGB(200, 80, 80) end
            if cfg2.Tooltip then AddTooltip(Frame, cfg2.Tooltip) end
            local function Update()
                Enabled = not Enabled
                Tween(Check, { BackgroundTransparency = Enabled and 0 or 1 }, 0.1)
                Tween(Label, {
                    TextColor3 = Enabled and CFG.TextColor
                              or (cfg2.Risky and Color3.fromRGB(200, 80, 80) or CFG.TextDark)
                }, 0.1)
                if cfg2.Callback then cfg2.Callback(Enabled) end
            end
            Frame.MouseButton1Click:Connect(Update)
            return { Set = function(v) if v ~= Enabled then Update() end end }
        end
        function IF:Slider(cfg2)
            local Value = cfg2.Default or cfg2.Min
            local Drag2 = false
            local F = Create("Frame", {
                Parent                 = GContent,
                Size                   = UDim2.new(1, 0, 0, 32),
                BackgroundTransparency = 1,
            })
            Create("TextLabel", {
                Parent         = F,
                Text           = cfg2.Name,
                TextColor3     = CFG.TextDark,
                TextSize       = 11,
                Font           = CFG.Font,
                BackgroundTransparency = 1,
                Size           = UDim2.new(1, 0, 0, 15),
                TextXAlignment = Enum.TextXAlignment.Left,
            })
            local function GetDisplay(v)
                return cfg2.Format and cfg2.Format(v) or (v .. (cfg2.Unit or ""))
            end
            local function GetReal(v)
                return cfg2.RealValue and cfg2.RealValue(v) or v
            end
            local VL = Create("TextLabel", {
                Parent         = F,
                Text           = GetDisplay(Value),
                TextColor3     = CFG.TextDark,
                TextSize       = 11,
                Font           = CFG.Font,
                BackgroundTransparency = 1,
                Size           = UDim2.new(1, 0, 0, 15),
                TextXAlignment = Enum.TextXAlignment.Right,
            })
            local BG = Create("Frame", {
                Parent           = F,
                Size             = UDim2.new(1, 0, 0, 6),
                Position         = UDim2.new(0, 0, 0, 20),
                BackgroundColor3 = CFG.SecondaryColor,
                BorderSizePixel  = 0,
            }, {
                Create("UIStroke", { Color = CFG.StrokeColor }),
                Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
            })
            local Fill = Create("Frame", {
                Parent           = BG,
                Size             = UDim2.new(0, 0, 1, 0),
                BackgroundColor3 = CFG.AccentColor,
            }, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
            local function SliderUpdate(input)
                local Pct = math.clamp(
                    (input.Position.X - BG.AbsolutePosition.X) / BG.AbsoluteSize.X,
                    0, 1)
                Value     = math.floor(cfg2.Min + (cfg2.Max - cfg2.Min) * Pct)
                Fill.Size = UDim2.new(Pct, 0, 1, 0)
                VL.Text   = GetDisplay(Value)
                if cfg2.Callback then cfg2.Callback(GetReal(Value)) end
            end
            F.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1
                or i.UserInputType == Enum.UserInputType.Touch then
                    Drag2 = true; SliderUpdate(i)
                end
            end)
            UserInputService.InputChanged:Connect(function(i)
                if Drag2 and (i.UserInputType == Enum.UserInputType.MouseMovement
                           or i.UserInputType == Enum.UserInputType.Touch) then
                    SliderUpdate(i)
                end
            end)
            UserInputService.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1
                or i.UserInputType == Enum.UserInputType.Touch then
                    Drag2 = false
                end
            end)
            local ip = math.clamp((Value - cfg2.Min) / (cfg2.Max - cfg2.Min), 0, 1)
            Fill.Size = UDim2.new(ip, 0, 1, 0)
            if cfg2.Tooltip then AddTooltip(F, cfg2.Tooltip) end
        end
        function IF:Dropdown(cfg2)
            local current = cfg2.Default or cfg2.Options[1]
            local Open    = false
            local Wrapper = Create("Frame", {
                Parent            = GContent,
                Size              = UDim2.new(1, 0, 0, 0),
                AutomaticSize     = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
            })
            Create("TextLabel", {
                Parent         = Wrapper,
                Text           = cfg2.Name,
                TextColor3     = CFG.TextDark,
                TextSize       = 11,
                Font           = CFG.Font,
                BackgroundTransparency = 1,
                Size           = UDim2.new(1, 0, 0, 14),
                TextXAlignment = Enum.TextXAlignment.Left,
            })
            local DropBtn = Create("TextButton", {
                Parent           = Wrapper,
                Size             = UDim2.new(1, 0, 0, 22),
                Position         = UDim2.new(0, 0, 0, 16),
                BackgroundColor3 = CFG.SecondaryColor,
                Text             = current,
                TextColor3       = CFG.TextColor,
                Font             = Enum.Font.GothamBold,
                TextSize         = 10,
                AutoButtonColor  = false,
            }, {
                Create("UIStroke", { Color = CFG.StrokeColor }),
                Create("UICorner", { CornerRadius = UDim.new(0, 3) }),
            })
            Create("TextLabel", {
                Parent         = DropBtn,
                Text           = "▾",
                TextColor3     = CFG.AccentColor,
                TextSize       = 12,
                Font           = CFG.Font,
                BackgroundTransparency = 1,
                Size           = UDim2.new(0, 16, 1, 0),
                Position       = UDim2.new(1, -18, 0, 0),
                TextXAlignment = Enum.TextXAlignment.Center,
            })
            local ListFrame = Create("Frame", {
                Parent           = Wrapper,
                Size             = UDim2.new(1, 0, 0, 0),
                Position         = UDim2.new(0, 0, 0, 40),
                BackgroundColor3 = CFG.SecondaryColor,
                BorderSizePixel  = 0,
                Visible          = false,
                ZIndex           = 50,
                ClipsDescendants = true,
            }, {
                Create("UICorner",     { CornerRadius = UDim.new(0, 3) }),
                Create("UIStroke",     { Color = CFG.StrokeColor }),
                Create("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }),
                Create("UIPadding",    {
                    PaddingTop    = UDim.new(0, 4),
                    PaddingBottom = UDim.new(0, 4),
                    PaddingLeft   = UDim.new(0, 4),
                    PaddingRight  = UDim.new(0, 4),
                }),
            })
            for _, opt in ipairs(cfg2.Options) do
                local Item = Create("TextButton", {
                    Parent         = ListFrame,
                    Size           = UDim2.new(1, 0, 0, 20),
                    BackgroundTransparency = 1,
                    Text           = opt,
                    TextColor3     = (opt == current) and CFG.AccentColor or CFG.TextDark,
                    Font           = CFG.Font,
                    TextSize       = 11,
                    AutoButtonColor = false,
                    TextXAlignment = Enum.TextXAlignment.Left,
                })
                Create("UIPadding", { Parent = Item, PaddingLeft = UDim.new(0, 4) })
                Item.MouseButton1Click:Connect(function()
                    current      = opt
                    DropBtn.Text = opt
                    for _, child in ipairs(ListFrame:GetChildren()) do
                        if child:IsA("TextButton") then
                            child.TextColor3 = (child.Text == opt) and CFG.AccentColor or CFG.TextDark
                        end
                    end
                    Tween(ListFrame, { Size = UDim2.new(1, 0, 0, 0) }, 0.15)
                    task.wait(0.15)
                    ListFrame.Visible = false
                    Open = false
                    if cfg2.Callback then cfg2.Callback(opt) end
                end)
            end
            DropBtn.MouseButton1Click:Connect(function()
                Open = not Open
                if Open then
                    ListFrame.Visible = true
                    Tween(ListFrame, { Size = UDim2.new(1, 0, 0, #cfg2.Options * 22 + 8) }, 0.15)
                else
                    Tween(ListFrame, { Size = UDim2.new(1, 0, 0, 0) }, 0.15)
                    task.wait(0.15)
                    ListFrame.Visible = false
                end
            end)
            if cfg2.Tooltip then AddTooltip(DropBtn, cfg2.Tooltip) end
            return {
                Set = function(v)
                    current      = v
                    DropBtn.Text = v
                    if cfg2.Callback then cfg2.Callback(v) end
                end
            }
        end
        function IF:Button(cfg2)
            local Btn2 = Create("TextButton", {
                Parent           = GContent,
                Size             = UDim2.new(1, 0, 0, 22),
                BackgroundColor3 = CFG.SecondaryColor,
                Text             = cfg2.Name,
                TextColor3       = CFG.TextDark,
                Font             = Enum.Font.GothamBold,
                TextSize         = 10,
            }, {
                Create("UIStroke", { Color = CFG.StrokeColor }),
                Create("UICorner", { CornerRadius = UDim.new(0, 3) }),
            })
            if cfg2.Variant == "Primary" then
                Btn2.BackgroundColor3 = CFG.AccentColor
                Btn2.TextColor3       = Color3.new(0, 0, 0)
            elseif cfg2.Variant == "Danger" then
                Btn2.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
                Btn2.TextColor3       = Color3.new(0, 0, 0)
            end
            Btn2.MouseButton1Click:Connect(function()
                if cfg2.Callback then cfg2.Callback() end
            end)
            if cfg2.Tooltip then AddTooltip(Btn2, cfg2.Tooltip) end
        end
        return IF
    end
    return GF
end

-- ── Flickbot logic ────────────────────────────────────────────────────────
local deflecting = {}
plrs.PlayerRemoving:Connect(function(p) deflecting[p] = nil end)
local function updateDeflection()
    if not FighterController or not FighterController.Objects then return end
    for _, fo in FighterController.Objects do
        local p = fo.Player
        if not p then continue end
        if not fo.Entity or not fo.Entity:IsAlive() or fo:Get("IsSpectating") then
            deflecting[p] = false; continue
        end
        local eq       = fo.EquippedItem
        local isKatana = eq and eq.ViewModel and eq.ViewModel.Name == "Katana"
        deflecting[p]  = isKatana
            and (eq._attack_cooldown and eq._attack_cooldown > tick()) or false
    end
end
local function isEnemy(player)
    if player == Player then return false end
    if SpectateController then
        local duel = SpectateController.CurrentDuelSubject
        local ld   = duel and duel:GetDueler(Player)
        local lt   = ld  and ld:Get("TeamID") or nil
        if lt and duel and duel.Duelers then
            for _, d in duel.Duelers do
                if d.Player == player then return d:Get("TeamID") ~= lt end
            end
        end
    end
    local pt, lt2 = player:GetAttribute("TeamID"), Player:GetAttribute("TeamID")
    if pt and lt2 then return pt ~= lt2 end
    return true
end
local function hasKnifeViewModel(targetPlayer)
    if not targetPlayer then return false end
    local vm = ws:FindFirstChild("ViewModels")
    if not vm then return false end
    for _, m in vm:GetChildren() do
        if m:IsA("Model")
           and string.find(m.Name, targetPlayer.Name, 1, true)
           and string.find(m.Name, "Knife", 1, true) then
            return true
        end
    end
    return false
end
local function getClosestTarget(teamFilter)
    local char = Player.Character
    if not char then return nil, nil, nil end
    local myRoot = char:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil, nil, nil end
    local cp, cr, ch, cd = nil, nil, nil, 500
    for _, p in plrs:GetPlayers() do
        if teamFilter and not isEnemy(p) then continue end
        if not teamFilter and p == Player then continue end
        local pc  = p.Character; if not pc then continue end
        local pr  = pc:FindFirstChild("HumanoidRootPart")
        local ph  = pc:FindFirstChild("Head")
        local phm = pc:FindFirstChildWhichIsA("Humanoid")
        if not (pr and ph and phm and phm.Health > 0) then continue end
        local d = (myRoot.Position - pr.Position).Magnitude
        if d < cd then cd = d; cp = p; cr = pr; ch = ph end
    end
    return cp, cr, ch
end

local velHistory = {}
local function recordVelocity(char, root)
    local now, pos = tick(), root.Position
    if not velHistory[char] then
        velHistory[char] = { {pos=pos,t=now}, {pos=pos,t=now} }
    else
        velHistory[char][1] = velHistory[char][2]
        velHistory[char][2] = {pos=pos,t=now}
    end
end
local function predictPosition(char, root, lead)
    local h = velHistory[char]
    if not h then return root.Position end
    local dt = h[2].t - h[1].t
    if dt < 0.001 then return root.Position end
    local vel = (h[2].pos - h[1].pos) / dt
    return root.Position + vel * lead
end
local CDFIELDS = {
    "Cooldown","AttackCooldown","UseDelay","SpinCooldown",
    "HeavyAttackCooldown","AbilityCooldown","FireCooldown","DashCooldown",
}
local function zeroCDs()
    task.spawn(function()
        local mods = ReplicatedStorage:FindFirstChild("Modules")
        local lib  = mods and mods:FindFirstChild("ItemLibrary")
        if lib then
            local ok, t = pcall(require, lib)
            if ok and type(t) == "table" then
                local items = t.Items or t.Weapons or t.Melee or t.Utilities
                if type(items) == "table" then
                    for _, item in pairs(items) do
                        if type(item) == "table" then
                            local isM = item.Type=="Melee" or item.Category=="Melee"
                                     or (item.Damage and not item.AmmoType)
                            if isM then
                                for _, f in ipairs(CDFIELDS) do
                                    if item[f] ~= nil then item[f] = 0 end
                                end
                            end
                        end
                    end
                end
            end
        end
    end)
    local char = Player.Character
    if char then
        for _, v in ipairs(char:GetDescendants()) do
            for _, fn in ipairs(CDFIELDS) do
                if v.Name == fn and (v:IsA("NumberValue") or v:IsA("IntValue")) then
                    v.Value = 0
                end
            end
        end
    end
end
local function killVel(char)
    if not FlickCfg.AntiVelocity then return end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then
            p.Velocity                = Vector3.zero
            p.AssemblyLinearVelocity  = Vector3.zero
            p.AssemblyAngularVelocity = Vector3.zero
        end
    end
end

-- ── Heartbeat — flickbot only (ragebot runs its own loop) ─────────────────
RunService.Heartbeat:Connect(function()
    updateDeflection()
    local flickDesyncCF = nil
    do
        local fp, fr, fh = getClosestTarget(FlickCfg.TeamFilter)
        if fp and fr and fh then
            recordVelocity(fp.Character, fr)
            local hasKnife  = hasKnifeViewModel(fp)
            local rawOffset = hasKnife and CFrame.new(0, 6, 0) or CFrame.new(0, 1, 2)
            if FlickCfg.RandomizeOffset then
                FlickCfg.OffsetX = (math.random() * 2 - 1) * 10
                FlickCfg.OffsetY = (math.random() * 2 - 1) * 10
                FlickCfg.OffsetZ = (math.random() * 2 - 1) * 10
            end
            local basePos  = (fr.CFrame * rawOffset).Position
                           + Vector3.new(FlickCfg.OffsetX, FlickCfg.OffsetY, FlickCfg.OffsetZ)
            local finalPos = basePos
            if FlickCfg.PredictionOn and FlickCfg.PredictionScale > 0 then
                local drift = predictPosition(fp.Character, fr, FlickCfg.PredictionScale)
                            - fr.Position
                finalPos = basePos + drift
            end
            local predHead = FlickCfg.PredictionOn
                and (fh.Position
                     + (predictPosition(fp.Character, fr, FlickCfg.PredictionScale) - fr.Position))
                or fh.Position
            flickDesyncCF = CFrame.lookAt(finalPos, predHead)
            if FlickCfg.Active then
                local char   = Player.Character
                local myRoot = char and char:FindFirstChild("HumanoidRootPart")
                if myRoot then
                    if FlickCfg.Desync then
                        local oldCF  = myRoot.CFrame
                        local oldVel = myRoot.Velocity
                        local oldRot = myRoot.RotVelocity
                        RunService:UnbindFromRenderStep("__flickbot_restore")
                        local applyCF = (FlickCfg.FlickLerpAlpha >= 1.0)
                            and flickDesyncCF
                            or myRoot.CFrame:Lerp(flickDesyncCF, FlickCfg.FlickLerpAlpha)
                        myRoot.CFrame = applyCF
                        RunService:BindToRenderStep("__flickbot_restore", 101, function()
                            if myRoot and myRoot.Parent then
                                myRoot.CFrame      = oldCF
                                myRoot.Velocity    = oldVel
                                myRoot.RotVelocity = oldRot
                            end
                            RunService:UnbindFromRenderStep("__flickbot_restore")
                        end)
                    else
                        killVel(char)
                        local n = FlickCfg.WritesPerFrame
                        for i = 0, n - 1 do
                            local t  = tick() * FlickCfg.FlickSpeed + (i * (math.pi * 2 / n))
                            local ox = math.cos(t) * FlickCfg.FlickRadius
                            local oz = math.sin(t) * FlickCfg.FlickRadius
                            myRoot.CFrame = fr.CFrame * CFrame.new(ox, 0, oz)
                        end
                    end
                end
            end
        end
    end
end)

Player.CharacterAdded:Connect(function()
    velHistory = {}
    RunService:UnbindFromRenderStep("__flickbot_restore")
end)

-- ── Flickbot UI tab ───────────────────────────────────────────────────────
local FlickTab  = MakeTab("7059348016")
local FlickMain = FlickTab:Group("Flickbot")
FlickMain:Toggle({
    Name     = "Flickbot Active",
    Tooltip  = "Desync character to enemy position every tick",
    Callback = function(v) FlickCfg.Active = v end,
})
FlickMain:Toggle({
    Name     = "Desync Mode",
    Default  = true,
    Tooltip  = "Server sees you at target; client camera stays put",
    Callback = function(v) FlickCfg.Desync = v end,
})
FlickMain:Toggle({
    Name     = "Prediction",
    Default  = true,
    Tooltip  = "Lead moving targets to compensate RTT + server tick",
    Callback = function(v) FlickCfg.PredictionOn = v end,
})
FlickMain:Toggle({
    Name     = "Team Filter",
    Default  = true,
    Tooltip  = "Only target players on opposing teams",
    Callback = function(v) FlickCfg.TeamFilter = v end,
})
FlickMain:Toggle({
    Name     = "Anti-Velocity",
    Tooltip  = "Zero velocity each orbit write (orbit mode only)",
    Callback = function(v) FlickCfg.AntiVelocity = v end,
})
FlickMain:Button({
    Name     = "Zero Cooldowns",
    Variant  = "Primary",
    Tooltip  = "Strip cooldown values from ItemLibrary + live character",
    Callback = function() zeroCDs() end,
})
FlickMain:Slider({
    Name      = "Flick Lerp Speed",
    Min       = 1, Max = 100, Default = 100,
    Format    = function(v) return (v >= 100) and "Snap" or (v .. "%") end,
    RealValue = function(v) return v / 100 end,
    Tooltip   = "Speed desync CFrame approaches target per tick — 100 = instant snap (desync only)",
    Callback  = function(v) FlickCfg.FlickLerpAlpha = v / 100 end,
})

local PosGroup = FlickTab:Group("Position Offset")
PosGroup:Slider({
    Name    = "X Offset", Min = -10, Max = 10, Default = 0,
    Tooltip = "Horizontal offset from target (studs)",
    Callback = function(v)
        FlickCfg._SavedOffsetX = v
        if not FlickCfg.RandomizeOffset then FlickCfg.OffsetX = v end
    end,
})
PosGroup:Slider({
    Name    = "Y Offset", Min = -10, Max = 10, Default = 0,
    Tooltip = "Vertical offset from target (studs)",
    Callback = function(v)
        FlickCfg._SavedOffsetY = v
        if not FlickCfg.RandomizeOffset then FlickCfg.OffsetY = v end
    end,
})
PosGroup:Slider({
    Name    = "Z Offset", Min = -10, Max = 10, Default = 0,
    Tooltip = "Depth offset from target (studs)",
    Callback = function(v)
        FlickCfg._SavedOffsetZ = v
        if not FlickCfg.RandomizeOffset then FlickCfg.OffsetZ = v end
    end,
})
PosGroup:Toggle({
    Name    = "Randomize Offsets",
    Default = false,
    Tooltip = "Re-roll X/Y/Z randomly in [-10, 10] every Heartbeat tick",
    Callback = function(v)
        FlickCfg.RandomizeOffset = v
        if not v then
            FlickCfg.OffsetX = FlickCfg._SavedOffsetX
            FlickCfg.OffsetY = FlickCfg._SavedOffsetY
            FlickCfg.OffsetZ = FlickCfg._SavedOffsetZ
        end
    end,
})

local OrbitGroup = FlickTab:Group("Orbit (Desync off)")
OrbitGroup:Slider({
    Name    = "Flick Speed", Min = 100, Max = 999999, Default = 99999,
    Tooltip = "tick() multiplier for orbital spin speed",
    Callback = function(v) FlickCfg.FlickSpeed = v end,
})
OrbitGroup:Slider({
    Name      = "Flick Radius",
    Min       = 1, Max = 99, Default = 25,
    Format    = function(v) return string.format("%.2f", v / 100) end,
    RealValue = function(v) return v / 100 end,
    Tooltip   = "Orbit radius around target (studs)",
    Callback  = function(v) FlickCfg.FlickRadius = v end,
})
OrbitGroup:Slider({
    Name    = "Writes/Frame", Min = 1, Max = 10, Default = 3,
    Tooltip = "CFrame writes per Heartbeat tick (orbit only)",
    Callback = function(v) FlickCfg.WritesPerFrame = v end,
})

-- ── Input / visibility ────────────────────────────────────────────────────
Library.MenuKey = Enum.KeyCode.Insert
local Visible = true
UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Library.MenuKey then
        Visible = not Visible
        MainFrame.Visible = Visible
    end
end)
Create("ImageButton", {
    Parent          = ScreenGui,
    Size            = UDim2.new(0, 40, 0, 40),
    Position        = UDim2.new(0.5, 0, 0, 10),
    AnchorPoint     = Vector2.new(0.5, 0),
    BackgroundColor3 = CFG.MainColor,
    Image           = "rbxassetid://3926305904",
    ImageColor3     = CFG.AccentColor,
    AutoButtonColor = false,
}, {
    Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
    Create("UIStroke", { Color = CFG.AccentColor, Thickness = 2 }),
}).MouseButton1Click:Connect(function()
    Visible = not Visible
    MainFrame.Visible = Visible
end)

Notify("eclipse v6.3 × ragebot-fixed — Insert to toggle", "success")
print("[eclipse] v6.3 × ragebot-fixed | flickbot + full ragebot active")
