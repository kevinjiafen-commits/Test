--[[
    RAGEBOT — Standalone fixed build
    Error fixed: "attempt to index nil with 'MainScreenGui'" (line 167)
    Root cause: mainapi, Movement, run(), Gradients, buildGradientKeypoints,
                InterfaceMode, Config were all missing from the extracted file.
    Fix: stub every missing dependency so the ragebot logic runs self-contained.
--]]

-- ── cloneref ──────────────────────────────────────────────────────────────
local cloneref = cloneref or function(obj) return obj end

-- ── Services ──────────────────────────────────────────────────────────────
local UserInputService  = cloneref(game:GetService("UserInputService"))
local TweenService      = cloneref(game:GetService("TweenService"))
local GuiService        = cloneref(game:GetService("GuiService"))
local RunService        = cloneref(game:GetService("RunService"))
local Players           = cloneref(game:GetService("Players"))
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local VirtualInputManager = cloneref(game:GetService("VirtualInputManager"))
local LocalPlayer       = Players.LocalPlayer

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
            or text:find("firingrange", 1, true) ~= nil
            or text:find("사격장", 1, true) ~= nil
    end

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

-- ── mainapi stub ──────────────────────────────────────────────────────────
-- Builds the ScreenGui and provides just enough surface for the ragebot to
-- register itself, show its status indicator and fire notifications.

local MainScreenGui = Instance.new("ScreenGui")
MainScreenGui.Name             = "RagebotGui"
MainScreenGui.ResetOnSpawn     = false
MainScreenGui.ZIndexBehavior   = Enum.ZIndexBehavior.Sibling
MainScreenGui.IgnoreGuiInset   = true
MainScreenGui.DisplayOrder     = 999

-- Try CoreGui first (requires identity 6+), fall back to PlayerGui
local guiParented = false
pcall(function()
    MainScreenGui.Parent = game:GetService("CoreGui")
    guiParented = true
end)
if not guiParented then
    MainScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

-- Minimal ClickGui frame (used by makeDraggable to detect gui-open state)
local ClickGui = Instance.new("Frame")
ClickGui.Name            = "ClickGui"
ClickGui.Size            = UDim2.fromScale(0, 0)
ClickGui.BackgroundTransparency = 1
ClickGui.Parent          = MainScreenGui

local cleanupConns = {}
local mainapi = {
    Font          = Enum.Font.BuilderSans,
    ClickGuiStatus = false,
    ThreadFix     = false,
    Scale         = {Value = 1},
    MainScreenGui = MainScreenGui,
}

function mainapi:Clean(conn)
    if conn then table.insert(cleanupConns, conn) end
    return conn
end

function mainapi:Notify(arg)
    -- lightweight notification: print to output
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

-- ── Gradient system stubs (used by addGradient) ───────────────────────────
local Gradients      = {}
local InterfaceMode  = {Value = "Static"}
local uipallet       = {
    MainColor      = Color3.fromRGB(200, 118, 189),
    SecondaryColor = Color3.fromRGB(228, 196, 202),
}

local function buildGradientKeypoints(parent)
    return {
        ColorSequenceKeypoint.new(0, uipallet.MainColor),
        ColorSequenceKeypoint.new(1, uipallet.SecondaryColor),
    }
end

-- ── UI helpers ────────────────────────────────────────────────────────────
local function makeDraggable(obj, _window)
    obj.InputBegan:Connect(function(inputObj)
        if not mainapi.ClickGuiStatus then return end
        if inputObj.UserInputType == Enum.UserInputType.MouseButton1
            or inputObj.UserInputType == Enum.UserInputType.Touch then
            local dragPosition = Vector2.new(
                obj.AbsolutePosition.X - inputObj.Position.X,
                obj.AbsolutePosition.Y - inputObj.Position.Y + GuiService:GetGuiInset().Y
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

local function addCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = radius or UDim.new(0, 5)
    corner.Parent       = parent
    return corner
end

local function addBlur(parent)
    local blur = Instance.new("ImageLabel")
    blur.Name                = "Blur"
    blur.Size                = UDim2.new(1, 89, 1, 52)
    blur.Position            = UDim2.fromOffset(-48, -31)
    blur.BackgroundTransparency = 1
    blur.Image               = "rbxassetid://74663567791967"
    blur.ScaleType           = Enum.ScaleType.Slice
    blur.SliceCenter         = Rect.new(52, 31, 261, 502)
    blur.ZIndex              = -100
    blur.Parent              = parent
    return blur
end

local function addGradient(parent)
    local UIGradient = Instance.new("UIGradient")
    UIGradient.Color    = ColorSequence.new(buildGradientKeypoints(parent))
    table.insert(Gradients, UIGradient)
    UIGradient.Parent   = parent
    return UIGradient
end

-- ── RagebotStatus indicator GUI ───────────────────────────────────────────
local screenY = MainScreenGui.AbsoluteSize.Y > 0 and MainScreenGui.AbsoluteSize.Y or 600

local RagebotStatusMain = Instance.new("Frame")
RagebotStatusMain.Name               = "RagebotStatus"
RagebotStatusMain.AnchorPoint        = Vector2.new(0, 0)
RagebotStatusMain.Position           = UDim2.new(0.5, -(screenY / 8.4), 0.08, 0)
RagebotStatusMain.Size               = UDim2.new(0, screenY / 4.2, 0, screenY / 28)
RagebotStatusMain.BackgroundTransparency = 1
RagebotStatusMain.Visible            = false
RagebotStatusMain.Parent             = MainScreenGui
getgenv().RagebotStatusMain          = RagebotStatusMain

local RagebotStatusFrame = Instance.new("Frame")
RagebotStatusFrame.Size                  = UDim2.fromScale(1, 1)
RagebotStatusFrame.BackgroundColor3      = Color3.fromRGB(20, 20, 20)
RagebotStatusFrame.BackgroundTransparency = 0.12
RagebotStatusFrame.BorderSizePixel       = 0
RagebotStatusFrame.Parent               = RagebotStatusMain

local RagebotStatusAccent = Instance.new("Frame")
RagebotStatusAccent.AnchorPoint    = Vector2.new(0, 0.5)
RagebotStatusAccent.Position       = UDim2.fromScale(0.035, 0.5)
RagebotStatusAccent.Size           = UDim2.fromScale(0.022, 0.56)
RagebotStatusAccent.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
RagebotStatusAccent.BorderSizePixel = 0
RagebotStatusAccent.Parent          = RagebotStatusFrame
addGradient(RagebotStatusAccent)

local RagebotStatusText = Instance.new("TextLabel")
RagebotStatusText.BackgroundTransparency = 1
RagebotStatusText.Position          = UDim2.fromScale(0.085, 0)
RagebotStatusText.Size              = UDim2.fromScale(0.89, 1)
RagebotStatusText.Font              = mainapi.Font
RagebotStatusText.Text              = "Ragebot : void"
RagebotStatusText.TextColor3        = Color3.fromRGB(240, 240, 240)
RagebotStatusText.TextScaled        = true
RagebotStatusText.TextXAlignment    = Enum.TextXAlignment.Left
RagebotStatusText.TextYAlignment    = Enum.TextYAlignment.Center
RagebotStatusText.Parent            = RagebotStatusFrame

local RagebotStatusTextConstraint = Instance.new("UITextSizeConstraint")
RagebotStatusTextConstraint.MinTextSize = 8
RagebotStatusTextConstraint.MaxTextSize = 18
RagebotStatusTextConstraint.Parent      = RagebotStatusText

addCorner(RagebotStatusFrame)
addCorner(RagebotStatusAccent, UDim.new(1, 0))
addBlur(RagebotStatusFrame)
makeDraggable(RagebotStatusMain, ClickGui)

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
        RagebotStatusLastText = text
        RagebotStatusText.Text = text
    end

    if enabled ~= RagebotStatusVisible then
        RagebotStatusVisible = enabled
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

-- Resize status bar when screen size changes
mainapi:Clean(MainScreenGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
    RagebotStatusMain.Size = UDim2.new(
        0, MainScreenGui.AbsoluteSize.Y / 4.2,
        0, MainScreenGui.AbsoluteSize.Y / 28
    )
end))

-- ── Movement catalog stub ─────────────────────────────────────────────────
-- Mimics mainapi:AddCatalog() / AddModule() / AddToggle() / AddSlider() etc.
-- so all Ragebot:Add*() calls register cleanly.

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

local function makeControl(moduleObj, def)
    local ctrl = {
        Enabled  = def.Default == true or false,
        Value    = def.Default,
        _list    = def.List or {},
        _fn      = def.Function,
    }
    function ctrl:SetList(list) self._list = list end
    function ctrl:Set(val)
        self.Value   = val
        self.Enabled = (val == true)
        if self._fn then pcall(self._fn, val) end
    end
    -- fire default on creation
    if def.Function and def.Default ~= nil then
        pcall(def.Function, def.Default)
    end
    return ctrl
end

local function makeModule(catalogObj, def)
    local mod = makeCleanable()
    mod.Name    = def.Name
    mod.Enabled = false
    mod._fn     = def.Function

    function mod:AddToggle(d)     return makeControl(mod, d) end
    function mod:AddSlider(d)     return makeControl(mod, d) end
    function mod:AddDropdown(d)   return makeControl(mod, d) end
    function mod:AddInputBox(d)   return makeControl(mod, d) end
    function mod:AddLabel(d)      return {} end
    function mod:AddModule(d)     return makeModule(mod, d) end

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

-- ── run() shim ────────────────────────────────────────────────────────────
-- The original script uses a deferred queue; here we just call directly.
local function run(func)
    task.spawn(func)
end

-- ── RAGEBOT MODULE ────────────────────────────────────────────────────────

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

                cfg.on = true
                cfg.settleUntil = 0

                local players   = cloneref(game:GetService("Players"))
                local runservice = cloneref(game:GetService("RunService"))
                local vim       = cloneref(game:GetService("VirtualInputManager"))
                local ws        = cloneref(game:GetService("Workspace"))
                local rs        = cloneref(game:GetService("ReplicatedStorage"))
                local lplr      = players.LocalPlayer

                local util, enums, useItemRemote, fighterCtrl
                pcall(function()
                    util          = require(rs.Modules.Utility)
                    enums         = require(rs.Modules.EnumLibrary)
                    useItemRemote = rs.Remotes.Replication.Fighter.UseItem
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
                    local vms = ws:FindFirstChild("ViewModels")
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
                        cfg.mode            = "Underground"
                        cfg.hyper           = true
                        cfg.orbitDist       = 1.6
                        cfg.orbitHeight     = 0.6
                        cfg.strafeSpeed     = 8
                        cfg.teleportDelay   = 0.02
                        cfg.predictLead     = 0.08
                        cfg.behindDist      = 2.2
                        cfg.undergroundDepth = 4
                        cfg.randomMovement  = false
                        cfg.dirBack         = true
                        cfg.dirFront        = false
                        cfg.dirLeft         = true
                        cfg.dirRight        = true
                        cfg.dirDown         = true
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
                    if not util or not part then return nil end
                    local look = CFrame.new(fromPos, part.Position)
                    local data = {}
                    data[utf8.char(1)] = {
                        [utf8.char(0)] = util:EncodeCFrame(look),
                        [utf8.char(1)] = util:EncodeCFrame(look),
                        [utf8.char(2)] = part,
                        [utf8.char(3)] = util:EncodeCFrame(part.CFrame:ToObjectSpace(CFrame.new(part.Position)))
                    }
                    return data
                end

                local function doFire(part)
                    local fighter = getFighter()
                    local item    = fighter and fighter.EquippedItem
                    if not item or not part then return false end

                    local cam     = ws.CurrentCamera
                    local fromPos = (state.csyncCF and state.csyncCF.Position) or (cam and cam.CFrame.Position) or part.Position
                    local anyFired = false
                    local attempts = math.max(1, math.floor(cfg.shootAttempts or 1))

                    for _ = 1, attempts do
                        local fired = false
                        if cfg.useManipulation and useItemRemote and enums and util then
                            local ammo = item.Get and (item:Get("Ammo") or 0) or 0
                            if ammo > 0 then
                                local oid        = item:Get("ObjectID")
                                local shootEnum  = enums:ToEnum("StartShooting")
                                local data       = buildCameraData(fromPos, part)
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
                            state.csyncLocalCF  = root.CFrame
                            state.csyncLocalLV  = root.AssemblyLinearVelocity
                            state.csyncLocalAV  = root.AssemblyAngularVelocity
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
                        if state.active and cfg.on and cfg.mode == "Void" and cfg.useManipulation and action == enums:ToEnum("StartShooting") then
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
                            state.suspended  = true
                            state.target     = nil
                            state.randPos    = nil
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

    -- Enable by default so it runs immediately on inject
    Ragebot:SetEnabled(true)
end)
