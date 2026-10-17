-- ============================================================
-- arch script — ENHANCED
-- Patches applied over original base:
--   [1] setthreadidentity(8) bootstrap → real internal modules
--   [2] True desync: flickbot RenderStep at priority 100 (First)
--       + _CameraReplicationLoop hook → fake camera angle sent
--   [3] PhysicsRepRootRef manipulation → server hitbox lock
--   [4] rbPressKey replaced with direct FighterController calls
--   [5] Target filter: State.Alive + shield/katana angle checks
-- ============================================================

-- ── Thread identity bootstrap ─────────────────────────────────────────────
local _setthreadidentity = (getfenv and getfenv().setthreadidentity)
    or (getgenv and getgenv().setthreadidentity)
    or (setthreadidentity)
    or nil
local _getthreadidentity = (getfenv and getfenv().getthreadidentity)
    or (getgenv and getgenv().getthreadidentity)
    or (getthreadidentity)
    or nil
local _sethiddenproperty = (getfenv and getfenv().sethiddenproperty)
    or (getgenv and getgenv().sethiddenproperty)
    or (sethiddenproperty)
    or nil
local _hookfunction = (getfenv and getfenv().hookfunction)
    or (getgenv and getgenv().hookfunction)
    or (hookfunction)
    or nil
local _newcclosure = (getfenv and getfenv().newcclosure)
    or (getgenv and getgenv().newcclosure)
    or (newcclosure)
    or function(f) return f end
local _debug_setupvalue  = debug and debug.setupvalue  or nil
local _debug_setconstant = debug and debug.setconstant  or nil
local _debug_getupvalues = debug and debug.getupvalues  or nil
local _debug_getprotos   = debug and debug.getprotos    or nil

-- elevate → require protected modules → restore
local function withIdentity(n, fn)
    if not _setthreadidentity then return fn() end
    local old = _getthreadidentity and _getthreadidentity() or 2
    pcall(_setthreadidentity, n)
    local ok, v = pcall(fn)
    pcall(_setthreadidentity, old)
    return ok and v or nil
end

-- ── Services ─────────────────────────────────────────────────────────────
local Players           = game:GetService("Players")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")

local Player = Players.LocalPlayer
local function cref(s) return (cloneref and cloneref(s)) or s end
local repS = cref(ReplicatedStorage)
local plrs = cref(Players)
local ws   = cref(Workspace)
local vim  = cref(VirtualInputManager)

-- ── Module acquisition with identity(8) ──────────────────────────────────
-- identity(8) lets require() reach protected PlayerScripts modules that
-- pcall+require at identity(2) silently fails on.
local FighterController, SpectateController, util, enumLib, itemLib
local CamRepLoop_fn   = nil   -- _CameraReplicationLoop upvalue, patched below
local utilEncodeCF    = nil   -- Utility.EncodeCameraRotation, patched below

local function tryRequire(path)
    return withIdentity(8, function()
        return require(path)
    end)
end

do
    local ps  = Player:FindFirstChild("PlayerScripts")
    local ctl = ps and ps:FindFirstChild("Controllers")
    if ctl then
        FighterController  = tryRequire(ctl:FindFirstChild("FighterController"))
                          or (function()
                                 local ok, v = pcall(require, ctl.FighterController)
                                 return ok and v or nil
                             end)()
        local sc = ctl:WaitForChild("SpectateController", 3)
        if sc then
            SpectateController = tryRequire(sc)
        end
    end
    local mods = repS:FindFirstChild("Modules")
    if mods then
        util    = tryRequire(mods:FindFirstChild("Utility"))
        enumLib = tryRequire(mods:FindFirstChild("EnumLibrary"))
        itemLib = tryRequire(mods:FindFirstChild("ItemLibrary"))
    end
    -- Fallback to identity-2 pcall
    if not util    then local ok,v = pcall(require, repS.Modules.Utility);    if ok then util    = v end end
    if not enumLib then local ok,v = pcall(require, repS.Modules.EnumLibrary); if ok then enumLib = v end end
end

-- ── _CameraReplicationLoop hook ───────────────────────────────────────────
-- After acquiring FighterController with identity(8) we can walk its protos
-- to find _CameraReplicationLoop and redirect EncodeCameraRotation to a
-- function that returns our fake CFrame instead of the real camera angle.
-- This makes the server see whatever facing direction we want.
local fakeCameraRotation = nil   -- set per-frame by flickbot / ragebot
local origEncodeCamera   = nil

local function patchCameraLoop()
    if not _debug_getprotos or not FighterController then return end
    if not util or type(util.EncodeCameraRotation) ~= "function" then return end
    origEncodeCamera = util.EncodeCameraRotation
    -- Replace EncodeCameraRotation in the util table with a shim.
    -- _CameraReplicationLoop calls util.EncodeCameraRotation(cameraRotation).
    -- We intercept when fakeCameraRotation is set.
    pcall(function()
        util.EncodeCameraRotation = _newcclosure(function(rot)
            if fakeCameraRotation then
                return origEncodeCamera(fakeCameraRotation)
            end
            return origEncodeCamera(rot)
        end)
    end)
    -- Also try to patch the upvalue directly inside FighterController
    if _debug_getupvalues then
        pcall(function()
            local ups = _debug_getupvalues(FighterController)
            if not ups then return end
            for k, v in pairs(ups) do
                if type(v) == "table" and type(v.EncodeCameraRotation) == "function" then
                    local old = v.EncodeCameraRotation
                    origEncodeCamera = origEncodeCamera or old
                    v.EncodeCameraRotation = _newcclosure(function(rot)
                        if fakeCameraRotation then
                            return old(fakeCameraRotation)
                        end
                        return old(rot)
                    end)
                end
            end
        end)
    end
end

task.defer(patchCameraLoop)

-- ── Theme ─────────────────────────────────────────────────────────────────
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

-- ── Flickbot config ───────────────────────────────────────────────────────
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

-- ── Flickbot rage config ──────────────────────────────────────────────────
local RageCfg = {
    Active          = false,
    FireRate        = 0.0005,
    WeaponPrimary   = true,
    WeaponSecondary = true,
    WeaponMelee     = true,
    OnEmpty         = "SwapOrReload",
}

-- ── Ragebot config ────────────────────────────────────────────────────────
local RagebotSettings = {
    on                     = false,
    targetMode             = "Closest",
    autoSwitch             = true,
    autoSwapSecondary      = true,
    autoReloadPrimary      = true,
    preferredWeapon        = "primary",
    primarySlot            = 1,
    secondarySlot          = 2,
    meleeSlot              = 3,
    weaponSpecialize       = true,
    autoEquipPreferred     = true,
    preferProjectile       = false,
    autoPriority           = false,
    priorityAttackers      = true,
    priorityVoided         = true,
    sendNotification       = false,
    prioritizedPlayer      = nil,
    acSpd                  = 0.05,
    shootDelay             = 0,
    teleportDelay          = 0.04,
    orbitDist              = 3,
    orbitHeight            = 2,
    randomMovement         = false,
    randomRefresh          = 0.08,
    mode                   = "Orbit",
    strafeSpeed            = 5,
    undergroundDepth       = 6,
    behindDist             = 4,
    antiAim                = false,
    hyper                  = false,
    useManipulation        = true,
    voidSpam               = true,
    voidHideTime           = 0.25,
    voidShootTime          = 0.03,
    shootAttempts          = 1,
    otherMatchAvoidDistance = 1000,
    settleUntil            = 0,
    dirBack                = true,
    dirFront               = false,
    dirLeft                = true,
    dirRight               = true,
    dirUp                  = true,
    dirDown                = false,
}

local function markRagebotSettingsDirty()
    RagebotSettings.settleUntil = 0
end

_G.FlickCfg         = FlickCfg
_G.RageCfg          = RageCfg
_G.RagebotSettings  = RagebotSettings

-- ── Item helpers ──────────────────────────────────────────────────────────
local ItemCache = {}
local function RefreshItemCache()
    ItemCache = {}
    if not FighterController then return end
    local lf = FighterController.LocalFighter
    if not lf then return end
    if lf.Items then
        for i = 1, 3 do
            local item = lf.Items[i]
            if item then ItemCache[i] = item end
        end
        return
    end
    for i = 1, 3 do
        pcall(function() lf:EquipItem(i) end)
        task.wait(0.05)
        local item = lf.EquippedItem
        if item then ItemCache[i] = item end
    end
end

local function itemCategory(idx)
    if idx == 1 then return "Primary"
    elseif idx == 2 then return "Secondary"
    elseif idx == 3 then return "Melee" end
    return nil
end

local function isCategoryEnabled(cat)
    if cat == "Primary"   then return RageCfg.WeaponPrimary end
    if cat == "Secondary" then return RageCfg.WeaponSecondary end
    if cat == "Melee"     then return RageCfg.WeaponMelee end
    return false
end

local function getFirstEnabledSlot()
    if RageCfg.WeaponPrimary   then return 1 end
    if RageCfg.WeaponSecondary then return 2 end
    if RageCfg.WeaponMelee     then return 3 end
    return 3
end

local function ReadItemValue(item, key)
    if not item then return nil end
    if type(item.Get) == "function" then
        local ok, v = pcall(item.Get, item, key)
        if ok then return v end
    end
    return item[key]
end

local function itemObjectId(item)
    local data = item.Data
    return data and data.ObjectID or nil
end

local function itemIsReloading(item)
    local now = tick()
    local cd  = item._reload_cooldown
    if type(cd) == "number" and now < cd then return true end
    local noAmmo = item._shoot_cooldown_no_ammo
    return type(noAmmo) == "number" and now < noAmmo
end

-- [PATCH 4] equip: direct FighterController call, no VIM key press
local function equipItemByIndex(item, index)
    if not item then return end
    if item.IsEquipped then return end
    -- Try the item's own ClientFighter reference first
    local fighter = item.ClientFighter
    if fighter and type(fighter.EquipItem) == "function" then
        pcall(fighter.EquipItem, fighter, index)
        return
    end
    -- Fallback: go through FighterController.LocalFighter
    local lf = FighterController and FighterController.LocalFighter
    if lf and type(lf.EquipItem) == "function" then
        pcall(lf.EquipItem, lf, index)
    end
end

-- [PATCH 4] reload: write _reload_cooldown + FireServer directly, no rbPressKey(R)
local function reloadItem(item)
    if not item then return end
    if itemIsReloading(item) then return end
    local reserve = ReadItemValue(item, "AmmoReserve")
    if type(reserve) == "number" and reserve <= 0 then return end
    local maxAmmo = ReadItemValue(item, "Info.MaxAmmo") or ReadItemValue(item, "MaxAmmo")
    local ammo    = ReadItemValue(item, "Ammo")
    if maxAmmo and ammo and ammo >= maxAmmo then return end
    local remote = repS:FindFirstChild("Remotes")
    remote = remote and remote:FindFirstChild("Replication")
    remote = remote and remote:FindFirstChild("Fighter")
    remote = remote and remote:FindFirstChild("UseItem")
    if not remote or not enumLib then return end
    local startRld = enumLib:ToEnum("StartReloading")
    local reload   = enumLib:ToEnum("Reload")
    if not startRld or not reload then return end
    -- Derive animation length from ItemLibrary if available and set _reload_cooldown
    local animLen = 1.8  -- safe fallback
    if itemLib then
        pcall(function()
            local info = itemLib and itemLib.GetItemInfo and itemLib:GetItemInfo(item)
            if not info then info = itemLib[item.Info and item.Info.Id] end
            if type(info) == "table" then
                local anims = info.Animations or info.ReloadAnimations
                if type(anims) == "table" then
                    local anim = anims["Reload"] or anims[1]
                    if type(anim) == "table" and type(anim.Length) == "number" then
                        animLen = anim.Length
                    end
                end
            end
        end)
    end
    -- Write the cooldown so itemIsReloading() blocks duplicate reloads
    item._reload_cooldown = tick() + animLen
    pcall(function()
        remote:FireServer(itemObjectId(item), startRld, { ["\1"] = reload, ["\2"] = reload }, nil)
    end)
end

local function getAction()
    if not FighterController then return nil end
    local lf = FighterController.LocalFighter
    if not lf then return nil end
    local items = lf.Items
    if type(items) ~= "table" then return nil end
    local onEmpty = RageCfg.OnEmpty
    local bestAttack, bestAttackPri, bestAttackIdx = nil, math.huge, nil
    local bestSwap,   bestSwapPri,   bestSwapIdx   = nil, math.huge, nil
    local anyEnabled = false
    for slotKey, item in next, items do
        if type(item) == "table" then
            local cat = itemCategory(slotKey)
            if cat and isCategoryEnabled(cat) then
                anyEnabled = true
                local prio   = 1
                local itType = item.Info and item.Info.Type or "Gun"
                local ammo   = ReadItemValue(item, "Ammo")
                if itType == "Gun" and (ammo == nil or ammo == 0) then
                    local reserve = ReadItemValue(item, "AmmoReserve")
                    if reserve and reserve > 0 then
                        if onEmpty == "Reload" then
                            if prio < bestAttackPri then
                                bestAttack = item; bestAttackPri = prio; bestAttackIdx = slotKey
                            end
                        else
                            if prio < bestSwapPri then
                                bestSwap = item; bestSwapPri = prio; bestSwapIdx = slotKey
                            end
                        end
                    end
                elseif bestAttack == nil or prio < bestAttackPri then
                    bestAttack = item; bestAttackPri = prio; bestAttackIdx = slotKey
                end
            end
        end
    end
    if not anyEnabled then return nil end
    if bestAttack == nil then
        if onEmpty == "Swap" or bestSwap == nil then return nil end
        if bestSwap.IsEquipped then
            return { type = "Reload", item = bestSwap, index = bestSwapIdx }
        else
            return { type = "Swap",   item = bestSwap, index = bestSwapIdx }
        end
    end
    if not bestAttack.IsEquipped then
        return { type = "Swap", item = bestAttack, index = bestAttackIdx }
    end
    local ammo = ReadItemValue(bestAttack, "Ammo")
    if ammo == 0 then
        return { type = "Reload", item = bestAttack, index = bestAttackIdx }
    end
    return { type = "Attack", item = bestAttack, index = bestAttackIdx }
end

local function forceSwap()
    if not FighterController then return end
    local lf = FighterController.LocalFighter
    if not lf or type(lf.Items) ~= "table" then return end
    for slotKey, item in next, lf.Items do
        if type(item) == "table" then
            local cat = itemCategory(slotKey)
            if cat and isCategoryEnabled(cat) and not item.IsEquipped then
                equipItemByIndex(item, slotKey)
                return
            end
        end
    end
end

local Library = { Unloaded = false }

task.spawn(function()
    if not FighterController then return end
    local lf = FighterController.LocalFighter
    while not lf do task.wait(0.1); lf = FighterController.LocalFighter end
    RefreshItemCache()
    pcall(function() lf:EquipItem(getFirstEnabledSlot()) end)
end)

task.spawn(function()
    while not Library.Unloaded do
        task.wait(1)
        if not RageCfg.Active then continue end
        local lf = FighterController and FighterController.LocalFighter
        if lf then
            pcall(function() lf:EquipItem(getFirstEnabledSlot()) end)
        end
    end
end)

Player.CharacterAdded:Connect(function()
    task.wait(1)
    RefreshItemCache()
    local lf = FighterController and FighterController.LocalFighter
    if lf then pcall(function() lf:EquipItem(getFirstEnabledSlot()) end) end
end)

-- ── GUI helpers ───────────────────────────────────────────────────────────
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

-- ── ScreenGui ─────────────────────────────────────────────────────────────
-- Use identity(8) to parent into CoreGui reliably
if _G.ArchScriptGui then _G.ArchScriptGui:Destroy() end
local ScreenGui = withIdentity(8, function()
    local sg = Instance.new("ScreenGui")
    sg.Name             = "ArchScriptGui"
    sg.ZIndexBehavior   = Enum.ZIndexBehavior.Sibling
    sg.ResetOnSpawn     = false
    sg.IgnoreGuiInset   = true
    sg.Parent           = game:GetService("CoreGui")
    return sg
end) or Create("ScreenGui", {
    Name           = "ArchScriptGui",
    Parent         = game:GetService("CoreGui"),
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    ResetOnSpawn   = false,
    IgnoreGuiInset = true,
})
_G.ArchScriptGui = ScreenGui

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

-- ── Notification container ────────────────────────────────────────────────
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

-- ── Tooltip ───────────────────────────────────────────────────────────────
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
    Create("UIStroke",  { Color = CFG.StrokeColor }),
    Create("UICorner",  { CornerRadius = UDim.new(0, 3) }),
    Create("UIPadding", {
        PaddingLeft  = UDim.new(0, 5),
        PaddingRight = UDim.new(0, 5),
    }),
})

local function AddTooltip(obj, text)
    obj.MouseEnter:Connect(function()
        local sz = GetTextSize(text, 11, CFG.Font)
        TooltipLabel.Text    = text
        TooltipLabel.Size    = UDim2.new(0, sz.X + 12, 0, 20)
        TooltipLabel.Visible = true
    end)
    obj.MouseLeave:Connect(function() TooltipLabel.Visible = false end)
    UserInputService.InputChanged:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseMovement then
            TooltipLabel.Position = UDim2.new(
                0, i.Position.X + 12,
                0, i.Position.Y - 24)
        end
    end)
end

-- ── Main frame ────────────────────────────────────────────────────────────
local MainFrame = Create("Frame", {
    Parent           = ScreenGui,
    Size             = UDim2.new(0, CFG.BaseSize.X, 0, CFG.BaseSize.Y),
    Position         = UDim2.new(0.5, -CFG.BaseSize.X / 2, 0.5, -CFG.BaseSize.Y / 2),
    BackgroundColor3 = CFG.MainColor,
    BorderSizePixel  = 0,
    ClipsDescendants = false,
}, {
    Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
    Create("UIStroke", { Color = CFG.StrokeColor }),
})

-- drag
do
    local dragging, dragStart, origPos
    MainFrame.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = i.Position
            origPos  = MainFrame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if not dragging then return end
        if i.UserInputType == Enum.UserInputType.MouseMovement
        or i.UserInputType == Enum.UserInputType.Touch then
            local d = i.Position - dragStart
            MainFrame.Position = UDim2.new(
                origPos.X.Scale, origPos.X.Offset + d.X,
                origPos.Y.Scale, origPos.Y.Offset + d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

-- ── Tab bar ───────────────────────────────────────────────────────────────
local TabBar = Create("Frame", {
    Parent           = MainFrame,
    Size             = UDim2.new(0, 38, 1, 0),
    BackgroundColor3 = CFG.SecondaryColor,
    BorderSizePixel  = 0,
}, {
    Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
    Create("UIListLayout", {
        Padding           = UDim.new(0, 4),
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment   = Enum.VerticalAlignment.Top,
    }),
    Create("UIPadding", {
        PaddingTop  = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 4),
        PaddingRight = UDim.new(0, 4),
    }),
})

local ContentArea = Create("Frame", {
    Parent           = MainFrame,
    Position         = UDim2.new(0, 42, 0, 0),
    Size             = UDim2.new(1, -42, 1, 0),
    BackgroundTransparency = 1,
    ClipsDescendants = true,
})

local tabs    = {}
local tabBtns = {}
local current = nil

local function switchTab(id)
    current = id
    for tid, page in tabs do
        page.Visible = (tid == id)
    end
    for tid, btn in tabBtns do
        Tween(btn, {
            BackgroundColor3 = (tid == id) and CFG.AccentColor or CFG.SecondaryColor
        }, 0.1)
    end
end

local function MakeTab(icon)
    local id = icon
    local Btn = Create("ImageButton", {
        Parent          = TabBar,
        Size            = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = CFG.SecondaryColor,
        Image           = "rbxassetid://" .. icon,
        ImageColor3     = CFG.TextColor,
        AutoButtonColor = false,
    }, {
        Create("UICorner", { CornerRadius = UDim.new(0, 4) }),
    })
    local Page = Create("ScrollingFrame", {
        Parent           = ContentArea,
        Size             = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel  = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = CFG.AccentColor,
        Visible          = false,
        CanvasSize       = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
    }, {
        Create("UIListLayout", {
            Padding   = UDim.new(0, 6),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }),
        Create("UIPadding", {
            PaddingTop    = UDim.new(0, 8),
            PaddingBottom = UDim.new(0, 8),
            PaddingLeft   = UDim.new(0, 8),
            PaddingRight  = UDim.new(0, 8),
        }),
    })
    tabs[id]    = Page
    tabBtns[id] = Btn
    Btn.MouseButton1Click:Connect(function() switchTab(id) end)
    if not current then switchTab(id) end

    local IF = {}
    function IF:Group(name)
        local GFrame = Create("Frame", {
            Parent           = Page,
            Size             = UDim2.new(1, 0, 0, 0),
            AutomaticSize    = Enum.AutomaticSize.Y,
            BackgroundColor3 = CFG.SecondaryColor,
            BorderSizePixel  = 0,
        }, {
            Create("UICorner",  { CornerRadius = UDim.new(0, 4) }),
            Create("UIStroke",  { Color = CFG.StrokeColor }),
        })
        Create("TextLabel", {
            Parent         = GFrame,
            Text           = name,
            TextColor3     = CFG.AccentColor,
            Font           = CFG.Font,
            TextSize       = 10,
            Size           = UDim2.new(1, -16, 0, 16),
            Position       = UDim2.new(0, 8, 0, 4),
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left,
        })
        local GContent = Create("Frame", {
            Parent           = GFrame,
            Position         = UDim2.new(0, 0, 0, 20),
            Size             = UDim2.new(1, 0, 0, 0),
            AutomaticSize    = Enum.AutomaticSize.Y,
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
        local GIF = {}
        function GIF:Toggle(cfg)
            local Enabled = cfg.Default or false
            local Frame = Create("TextButton", {
                Parent                = GContent,
                Size                  = UDim2.new(1, 0, 0, 20),
                BackgroundTransparency = 1,
                Text                  = "",
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
                Text           = cfg.Name,
                TextColor3     = Enabled and CFG.TextColor or CFG.TextDark,
                TextSize       = 11,
                Font           = CFG.Font,
                BackgroundTransparency = 1,
                Position       = UDim2.new(0, 18, 0, 0),
                Size           = UDim2.new(1, -18, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
            })
            if cfg.Risky then Label.TextColor3 = Color3.fromRGB(200, 80, 80) end
            if cfg.Tooltip then AddTooltip(Frame, cfg.Tooltip) end
            local function Update()
                Enabled = not Enabled
                Tween(Check, { BackgroundTransparency = Enabled and 0 or 1 }, 0.1)
                Tween(Label, {
                    TextColor3 = Enabled and CFG.TextColor
                              or (cfg.Risky and Color3.fromRGB(200, 80, 80) or CFG.TextDark)
                }, 0.1)
                if cfg.Callback then cfg.Callback(Enabled) end
            end
            Frame.MouseButton1Click:Connect(Update)
            return { Set = function(v) if v ~= Enabled then Update() end end }
        end
        function GIF:Slider(cfg)
            local Value = cfg.Default or cfg.Min
            local Drag2 = false
            local F = Create("Frame", {
                Parent                = GContent,
                Size                  = UDim2.new(1, 0, 0, 32),
                BackgroundTransparency = 1,
            })
            Create("TextLabel", {
                Parent         = F,
                Text           = cfg.Name,
                TextColor3     = CFG.TextDark,
                TextSize       = 11,
                Font           = CFG.Font,
                BackgroundTransparency = 1,
                Size           = UDim2.new(1, 0, 0, 15),
                TextXAlignment = Enum.TextXAlignment.Left,
            })
            local function GetDisplay(v)
                return cfg.Format and cfg.Format(v) or (v .. (cfg.Unit or ""))
            end
            local function GetReal(v)
                return cfg.RealValue and cfg.RealValue(v) or v
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
                    (input.Position.X - BG.AbsolutePosition.X) / BG.AbsoluteSize.X, 0, 1)
                Value     = math.floor(cfg.Min + (cfg.Max - cfg.Min) * Pct)
                Fill.Size = UDim2.new(Pct, 0, 1, 0)
                VL.Text   = GetDisplay(Value)
                if cfg.Callback then cfg.Callback(GetReal(Value)) end
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
            local ip = math.clamp((Value - cfg.Min) / (cfg.Max - cfg.Min), 0, 1)
            Fill.Size = UDim2.new(ip, 0, 1, 0)
            if cfg.Tooltip then AddTooltip(F, cfg.Tooltip) end
        end
        function GIF:Dropdown(cfg)
            local current2 = cfg.Default or cfg.Options[1]
            local Open      = false
            local Wrapper   = Create("Frame", {
                Parent            = GContent,
                Size              = UDim2.new(1, 0, 0, 0),
                AutomaticSize     = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
            })
            Create("TextLabel", {
                Parent         = Wrapper,
                Text           = cfg.Name,
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
                Text             = current2,
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
                ClipsDescendants = true,
            }, {
                Create("UIStroke",   { Color = CFG.StrokeColor }),
                Create("UICorner",   { CornerRadius = UDim.new(0, 3) }),
                Create("UIListLayout", { Padding = UDim.new(0, 1) }),
            })
            local function SetOpt(v)
                current2    = v
                DropBtn.Text = v
                Open         = false
                Tween(ListFrame, { Size = UDim2.new(1, 0, 0, 0) }, 0.15)
                if cfg.Callback then cfg.Callback(v) end
            end
            local function Rebuild()
                for _, c in ListFrame:GetChildren() do
                    if c:IsA("TextButton") then c:Destroy() end
                end
                for _, opt in ipairs(cfg.Options) do
                    local B = Create("TextButton", {
                        Parent           = ListFrame,
                        Size             = UDim2.new(1, 0, 0, 20),
                        BackgroundColor3 = CFG.SecondaryColor,
                        Text             = opt,
                        TextColor3       = CFG.TextColor,
                        Font             = Enum.Font.GothamBold,
                        TextSize         = 10,
                        AutoButtonColor  = false,
                    })
                    B.MouseButton1Click:Connect(function() SetOpt(opt) end)
                end
            end
            Rebuild()
            DropBtn.MouseButton1Click:Connect(function()
                Open = not Open
                Tween(ListFrame,
                      { Size = UDim2.new(1, 0, 0, Open and (#cfg.Options * 21) or 0) },
                      0.15)
            end)
            if cfg.Tooltip then AddTooltip(DropBtn, cfg.Tooltip) end
            return {
                SetOptions = function(opts)
                    cfg.Options = opts
                    Rebuild()
                    if not table.find(opts, current2) then SetOpt(opts[1] or "") end
                end
            }
        end
        function GIF:Button(cfg)
            local Clr = cfg.Variant == "Danger" and Color3.fromRGB(180, 60, 60)
                     or cfg.Variant == "Primary" and CFG.AccentColor
                     or CFG.SecondaryColor
            local Btn = Create("TextButton", {
                Parent           = GContent,
                Size             = UDim2.new(1, 0, 0, 22),
                BackgroundColor3 = Clr,
                Text             = cfg.Name,
                TextColor3       = CFG.TextColor,
                Font             = Enum.Font.GothamBold,
                TextSize         = 11,
                AutoButtonColor  = false,
            }, {
                Create("UICorner", { CornerRadius = UDim.new(0, 3) }),
                Create("UIStroke", { Color = CFG.StrokeColor }),
            })
            if cfg.Tooltip then AddTooltip(Btn, cfg.Tooltip) end
            Btn.MouseButton1Click:Connect(function()
                Tween(Btn, { BackgroundTransparency = 0.5 }, 0.05)
                task.delay(0.1, function()
                    Tween(Btn, { BackgroundTransparency = 0 }, 0.1)
                end)
                if cfg.Callback then cfg.Callback() end
            end)
        end
        return GIF
    end
    return IF
end

-- ── Deflection tracker (katana) ───────────────────────────────────────────
local deflecting = {}
local function updateDeflection()
    local vms = ws:FindFirstChild("ViewModels")
    if not vms then deflecting = {}; return end
    local newD = {}
    for _, m in vms:GetChildren() do
        if m:IsA("Model") and m.Name:lower():find("katana", 1, true) then
            for _, plr in plrs:GetPlayers() do
                if plr ~= Player and m.Name:find(plr.Name, 1, true) then
                    -- Check if the katana animation is actively deflecting:
                    -- look for a "Deflect" or "Parry" animation playing
                    local isDeflecting = false
                    pcall(function()
                        for _, anim in m:GetDescendants() do
                            if anim:IsA("AnimationTrack")
                            and (anim.Name:lower():find("deflect") or anim.Name:lower():find("parry"))
                            and anim.IsPlaying then
                                isDeflecting = true
                            end
                        end
                    end)
                    newD[plr] = isDeflecting
                end
            end
        end
    end
    deflecting = newD
end

-- ── [PATCH 5] Target validity — State-based instead of hardcoded names ────
local function rbGetFighterState(plr)
    -- Try FighterController path first
    if FighterController then
        local lf = FighterController.LocalFighter
        if lf and type(lf.GetFighterForPlayer) == "function" then
            local ok, f = pcall(lf.GetFighterForPlayer, lf, plr)
            if ok and f then return f.State or f.Character and f.Character.State end
        end
        if type(FighterController.GetFighter) == "function" then
            local ok, f = pcall(FighterController.GetFighter, FighterController, plr)
            if ok and f then return f.State or (f.Character and f.Character.State) end
        end
    end
    -- Fallback: walk the character for a State folder/value
    local char = plr and plr.Character
    if char then
        local s = char:FindFirstChild("State")
        return s
    end
    return nil
end

local function rbIsAliveViaState(plr)
    -- Try State.Alive (kiciahook method)
    local state = rbGetFighterState(plr)
    if state then
        if type(state) == "table" then
            if type(state.Alive) == "boolean" then return state.Alive end
        end
        if typeof(state) == "Instance" then
            local alive = state:FindFirstChild("Alive")
            if alive then return alive.Value == true end
        end
    end
    -- Fallback: humanoid Health
    local char = plr and plr.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

local function rbIsInvincibleState(plr)
    -- Try State.Invincible
    local state = rbGetFighterState(plr)
    if state then
        if type(state) == "table" then
            if type(state.Invincible) == "boolean" then return state.Invincible end
            if type(state.IsInvincible) == "function" then
                local ok, v = pcall(state.IsInvincible, state)
                if ok then return v end
            end
        end
        if typeof(state) == "Instance" then
            local inv = state:FindFirstChild("Invincible") or state:FindFirstChild("IsInvincible")
            if inv then return inv.Value == true end
        end
    end
    -- Fallback hardcoded checks (kept as secondary)
    local char = plr and plr.Character
    if not char then return true end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return true end
    if char:FindFirstChild("InvincibilityParticles", true) then return true end
    for _, obj in root:GetChildren() do
        if obj:IsA("Attachment") and obj.Name == "Attachment" then return true end
    end
    return false
end

-- ── Riot shield: is target currently shielding (facing us) ───────────────
-- kiciahook uses ItemBehaviors + isShielded angle check.
-- We approximate with a dot-product angle test on the LookVector.
local function rbIsShieldedAngle(targetRoot, shooterPos)
    if not targetRoot then return false end
    local toShooter = (shooterPos - targetRoot.Position).Unit
    local look      = targetRoot.CFrame.LookVector
    -- Shield blocks shots from the front: dot > 0.6 means shooter is in front arc
    return look:Dot(toShooter) > 0.55
end

-- ── [PATCH 3] PhysicsRepRootRef manipulation ─────────────────────────────
-- After setting our CFrame in csync, we also push the target's
-- PhysicsRepRootRef to a controlled fake part so the server sees the
-- target at our chosen position during the raycast for hit validation.
-- sethiddenproperty is required; if unavailable, this is a no-op.
local physRepGlue = {}   -- [targetRoot] = fake BasePart used as anchor

local function rbAcquirePhysRef(targetRoot)
    if not _sethiddenproperty then return nil end
    if physRepGlue[targetRoot] then return physRepGlue[targetRoot] end
    local fake = Instance.new("Part")
    fake.Name       = "PhysicsAnchor"
    fake.Anchored   = true
    fake.CanCollide = false
    fake.Size       = Vector3.new(0.1, 0.1, 0.1)
    fake.CFrame     = targetRoot.CFrame
    fake.Transparency = 1
    withIdentity(8, function()
        fake.Parent = workspace
    end)
    pcall(_sethiddenproperty, targetRoot, "PhysicsRepRootRef", fake)
    physRepGlue[targetRoot] = fake
    return fake
end

local function rbSetPhysRef(targetRoot, cf)
    if not _sethiddenproperty then return end
    local fake = physRepGlue[targetRoot] or rbAcquirePhysRef(targetRoot)
    if not fake then return end
    fake.CFrame = cf
    pcall(_sethiddenproperty, targetRoot, "PhysicsRepRootRef", fake)
end

local function rbClearPhysRef(targetRoot)
    if not targetRoot then return end
    local fake = physRepGlue[targetRoot]
    if fake then
        pcall(_sethiddenproperty, targetRoot, "PhysicsRepRootRef", nil)
        pcall(function() fake:Destroy() end)
        physRepGlue[targetRoot] = nil
    end
end

-- clean up fake parts when player leaves
plrs.PlayerRemoving:Connect(function(plr)
    local char = plr.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if root then rbClearPhysRef(root) end
end)

-- ── Team / enemy check ────────────────────────────────────────────────────
local function isEnemy(player)
    if player == Player then return false end
    local char = player.Character
    if not char then return false end
    local duel = nil
    pcall(function()
        if not rbDuelMod then return end
        local ok, d = pcall(rbDuelMod.GetDuel, rbDuelMod, Player)
        if ok then duel = d end
    end)
    if duel then
        local lt = nil
        for _, d in duel.Duelers do
            if d.Player == Player then lt = d:Get("TeamID"); break end
        end
        for _, d in duel.Duelers do
            if d.Player == player then return d:Get("TeamID") ~= lt end
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
        if not (pr and ph) then continue end
        -- [PATCH 5] use State.Alive instead of Humanoid.Health
        if not rbIsAliveViaState(p) then continue end
        local d = (myRoot.Position - pr.Position).Magnitude
        if d < cd then cd = d; cp = p; cr = pr; ch = ph end
    end
    return cp, cr, ch
end

-- ── Rage fire ─────────────────────────────────────────────────────────────
local lastFire = 0
local function rageFireThisFrame(targetPlayer, targetRoot, targetHead, desyncCF)
    if not RageCfg.Active then return end
    if not (targetPlayer and targetHead and targetRoot) then return end
    if deflecting[targetPlayer] then return end
    local char = Player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    if not util or not enumLib then return end
    local action = getAction()
    if not action then return end
    if action.type == "Swap" then
        equipItemByIndex(action.item, action.index)
        return
    end
    if action.type == "Reload" then
        reloadItem(action.item)
        return
    end
    if tick() - lastFire < RageCfg.FireRate then return end
    lastFire = tick()
    local item = action.item
    if not item then return end
    local originPos = desyncCF and desyncCF.Position or targetRoot.Position
    local aimCF     = CFrame.lookAt(originPos, targetHead.Position)
    local targetCF  = targetHead.CFrame

    -- [PATCH 3] lock PhysicsRepRootRef to head position before we fire
    rbSetPhysRef(targetRoot, targetHead.CFrame)

    local rng = Vector3.new(
        (math.random() - 0.5) * 0.1,
        (math.random() - 0.5) * 0.1,
        (math.random() - 0.5) * 0.1)
    local aimedPos  = targetHead.Position + rng
    local objOffset = targetHead.CFrame:ToObjectSpace(CFrame.new(aimedPos))
    local cameradata = {}
    cameradata[utf8.char(1)] = {
        [utf8.char(0)] = util:EncodeCFrame(aimCF),
        [utf8.char(1)] = util:EncodeCFrame(targetCF),
        [utf8.char(2)] = targetHead,
        [utf8.char(3)] = util:EncodeCFrame(objOffset),
    }
    local remote = repS.Remotes.Replication.Fighter.UseItem
    pcall(function()
        remote:FireServer(
            item:Get("ObjectID"),
            enumLib:ToEnum("StartShooting"),
            cameradata,
            nil
        )
    end)
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

-- ── [PATCH 2] True desync: Heartbeat write + RenderStep at priority 100 ───
-- Roblox pipeline order per frame:
--   Heartbeat fires → physics step → replication → RenderStepped fires
-- Writing fake CFrame in Heartbeat means the replication sees it.
-- Restoring in RenderStep at priority 100 (First) runs AFTER replication,
-- so client renders the real position while server sees the fake one.
-- Original used priority 101 which is correct directionally, but
-- we also now inject fakeCameraRotation for the _CameraReplicationLoop patch.

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
                        -- Write fake in Heartbeat (before replication)
                        local applyCF = (FlickCfg.FlickLerpAlpha >= 1.0)
                            and flickDesyncCF
                            or myRoot.CFrame:Lerp(flickDesyncCF, FlickCfg.FlickLerpAlpha)
                        myRoot.CFrame = applyCF
                        -- Set fake camera rotation for _CameraReplicationLoop hook
                        fakeCameraRotation = applyCF
                        -- [PATCH 2] priority 100 (RenderPriority.First) — restore AFTER replication
                        RunService:UnbindFromRenderStep("__flickbot_restore")
                        RunService:BindToRenderStep("__flickbot_restore",
                            Enum.RenderPriority.First.Value, function()
                            if myRoot and myRoot.Parent then
                                myRoot.CFrame      = oldCF
                                myRoot.Velocity    = oldVel
                                myRoot.RotVelocity = oldRot
                            end
                            fakeCameraRotation = nil
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
        else
            fakeCameraRotation = nil
        end
    end
    if RageCfg.Active then
        local rp, rr, rh = getClosestTarget(true)
        if rp and rr and rh then
            local rageCF = flickDesyncCF
            if not rageCF then
                local hasKnife  = hasKnifeViewModel(rp)
                local rawOffset = hasKnife and CFrame.new(0, 6, 0) or CFrame.new(0, 1, 2)
                local ragePos   = (rr.CFrame * rawOffset).Position
                rageCF = CFrame.lookAt(ragePos, rh.Position)
            end
            rageFireThisFrame(rp, rr, rh, rageCF)
        end
    end
end)

Player.CharacterAdded:Connect(function()
    velHistory = {}
    fakeCameraRotation = nil
    RunService:UnbindFromRenderStep("__flickbot_restore")
end)

-- ============================================================
-- RAGEBOT ENGINE
-- ============================================================

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
    end
    for _, object in ipairs({workspace, Player}) do
        for _, attribute in ipairs({"Map","MapName","Mode","GameMode","Arena","Environment","EnvironmentName","ShootingRange"}) do
            local value = object:GetAttribute(attribute)
            if (value == true and attribute == "ShootingRange") or matches(value) then
                shootingRangeCache = true; return true
            end
        end
    end
    local character = Player.Character
    local current   = character
    while current and current ~= workspace do
        if matches(current.Name) then shootingRangeCache = true; return true end
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
        if matchingAreaIsNear(child) then shootingRangeCache = true; return true end
        for _, grandchild in ipairs(child:GetChildren()) do
            if matchingAreaIsNear(grandchild) then shootingRangeCache = true; return true end
        end
    end
    shootingRangeCache = false
    return false
end

-- [PATCH 4] rbPressKey → direct FighterController equip, VIM only as final fallback
local rbSlotKey = {
    [1] = Enum.KeyCode.One,
    [2] = Enum.KeyCode.Two,
    [3] = Enum.KeyCode.Three,
    [4] = Enum.KeyCode.Four,
}

local function rbPressKey(kc)
    -- Try direct equip first if it's a slot key
    local slotIdx = nil
    for idx, code in rbSlotKey do
        if code == kc then slotIdx = idx; break end
    end
    if slotIdx then
        local lf = FighterController and FighterController.LocalFighter
        if lf and type(lf.EquipItem) == "function" then
            pcall(lf.EquipItem, lf, slotIdx)
            return
        end
    end
    -- Reload key: call reloadItem on equipped
    if kc == Enum.KeyCode.R then
        local lf   = FighterController and FighterController.LocalFighter
        local item = lf and lf.EquippedItem
        if item then reloadItem(item); return end
    end
    -- VIM fallback (last resort)
    vim:SendKeyEvent(true,  kc, false, game)
    task.wait(0.015)  -- reduced from 0.03 → 15 ms
    vim:SendKeyEvent(false, kc, false, game)
end

-- ── Ragebot status bar ────────────────────────────────────────────────────
local screenY = ScreenGui.AbsoluteSize.Y > 0 and ScreenGui.AbsoluteSize.Y or 600

local RbStatusMain = Create("Frame", {
    Name               = "RagebotStatus",
    AnchorPoint        = Vector2.new(0, 0),
    Position           = UDim2.new(0.5, -(screenY / 8.4), 0.08, 0),
    Size               = UDim2.new(0, screenY / 4.2, 0, screenY / 28),
    BackgroundTransparency = 1,
    Visible            = false,
    Parent             = ScreenGui,
})

local RbStatusFrame = Create("Frame", {
    Size                  = UDim2.fromScale(1, 1),
    BackgroundColor3      = Color3.fromRGB(20, 20, 20),
    BackgroundTransparency = 0.12,
    BorderSizePixel       = 0,
    Parent                = RbStatusMain,
}, {
    Create("UICorner", { CornerRadius = UDim.new(0, 5) }),
})

Create("Frame", {
    AnchorPoint    = Vector2.new(0, 0.5),
    Position       = UDim2.fromScale(0.035, 0.5),
    Size           = UDim2.fromScale(0.022, 0.56),
    BackgroundColor3 = CFG.AccentColor,
    BorderSizePixel = 0,
    Parent          = RbStatusFrame,
}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })

local RbStatusText = Create("TextLabel", {
    BackgroundTransparency = 1,
    Position    = UDim2.fromScale(0.085, 0),
    Size        = UDim2.fromScale(0.89, 1),
    Font        = Enum.Font.BuilderSans,
    Text        = "Ragebot : void",
    TextColor3  = Color3.fromRGB(240, 240, 240),
    TextScaled  = true,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Center,
    Parent      = RbStatusFrame,
}, {
    Create("UITextSizeConstraint", { MinTextSize = 8, MaxTextSize = 18 }),
})

local RbStatusScale = Create("UIScale", { Scale = 0, Parent = RbStatusFrame })

do
    local rbDragging, rbDragStart, rbDragOrigPos
    RbStatusMain.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            rbDragging    = true
            rbDragStart   = inp.Position
            rbDragOrigPos = RbStatusMain.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if not rbDragging then return end
        if inp.UserInputType == Enum.UserInputType.MouseMovement
        or inp.UserInputType == Enum.UserInputType.Touch then
            local d = inp.Position - rbDragStart
            RbStatusMain.Position = UDim2.new(
                rbDragOrigPos.X.Scale, rbDragOrigPos.X.Offset + d.X,
                rbDragOrigPos.Y.Scale, rbDragOrigPos.Y.Offset + d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            rbDragging = false
        end
    end)
end

ScreenGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
    RbStatusMain.Size = UDim2.new(
        0, ScreenGui.AbsoluteSize.Y / 4.2,
        0, ScreenGui.AbsoluteSize.Y / 28)
end)

local rbStatusLastText, rbStatusVisible = "", false
local function setRagebotStatus(enabled, target, voiding)
    shared.RagebotActive = enabled
    local text = "ragebot : void"
    if enabled and target and not voiding then
        text = "ragebot : " .. (target.Name or "target")
    end
    if rbStatusLastText ~= text then
        rbStatusLastText  = text
        RbStatusText.Text = text
    end
    if enabled ~= rbStatusVisible then
        rbStatusVisible = enabled
        RbStatusMain.Visible = true
        TweenService:Create(RbStatusScale, TweenInfo.new(0.18, Enum.EasingStyle.Exponential),
            { Scale = enabled and 1 or 0 }):Play()
        if not enabled then
            task.delay(0.2, function()
                if not rbStatusVisible then RbStatusMain.Visible = false end
            end)
        end
    end
end

-- ── Ragebot state ─────────────────────────────────────────────────────────
local rbGen                           = 0
local rbDuelMod, rbInMatchT, rbInMatch = nil, 0, false
local rbTgtT                          = 0
local rbActiveState                   = nil
local rbCharConn                      = nil

local function rbGetRoot(char)
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function rbGetFighter()
    if FighterController and FighterController.LocalFighter then
        return FighterController.LocalFighter
    end
    if FighterController and FighterController.GetFighter then
        local ok, f = pcall(FighterController.GetFighter, FighterController, Player)
        if ok then return f end
    end
    return nil
end

local function rbScanWeapon(plr)
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

-- [PATCH 5] use State-based alive check
local function rbPlayerIsDead(plr)
    if not rbIsAliveViaState(plr) then return true end
    local char = plr and plr.Character
    return not char or not rbGetRoot(char)
end

local function rbIsInvincible(plr)
    return rbIsInvincibleState(plr)
end

local function rbIsKatana(plr)
    return rbScanWeapon(plr):find("katana", 1, true) ~= nil
end

local function rbIsRiotShield(plr)
    local w = rbScanWeapon(plr)
    return w:find("riot", 1, true) ~= nil or w:find("shield", 1, true) ~= nil
end

-- [PATCH 5] shield deflection angle check
local function rbIsKatanaDeflecting(plr)
    -- active katana deflect: check if the target's katana viewmodel is in deflect anim
    return deflecting[plr] == true
end

local function rbIsValidEnvMatch(player)
    return player:GetAttribute("EnvironmentID") == Player:GetAttribute("EnvironmentID")
end

local function rbIsNearOtherMatch(pos, ignorePlayer)
    local avoidDistance = RagebotSettings.otherMatchAvoidDistance or 1000
    if typeof(pos) ~= "Vector3" or avoidDistance <= 0 then return false end
    for _, plr in plrs:GetPlayers() do
        if plr ~= Player and plr ~= ignorePlayer and not rbIsValidEnvMatch(plr) then
            local otherRoot = rbGetRoot(plr.Character)
            if otherRoot and (otherRoot.Position - pos).Magnitude <= avoidDistance then
                return true
            end
        end
    end
    return false
end

local function rbIsSafePos(pos, targetPlayer)
    return not rbIsNearOtherMatch(pos, targetPlayer)
end

-- [PATCH 5] updated skip: use State.Alive, drop hardcoded TeammateLabel
local function rbShouldSkip(plr)
    if plr == Player then return true end
    if rbPlayerIsDead(plr) then return true end
    if not rbIsValidEnvMatch(plr) then return true end
    if rbIsInvincible(plr) then return true end
    -- team check via TeamID attribute (more reliable than looking for GUI label)
    local myTeam  = Player:GetAttribute("TeamID")
    local theirTeam = plr:GetAttribute("TeamID")
    if myTeam and theirTeam and myTeam == theirTeam then return true end
    local root = rbGetRoot(plr.Character)
    if root and rbIsNearOtherMatch(root.Position, plr) then return true end
    return false
end

local function rbGetBestTarget()
    local root = rbGetRoot(Player.Character)
    if not root then return nil end
    if RagebotSettings.prioritizedPlayer then
        local pp = plrs:FindFirstChild(RagebotSettings.prioritizedPlayer)
        if pp and not rbShouldSkip(pp) then return pp end
    end
    local best, bestV = nil, math.huge
    local useHP = RagebotSettings.targetMode == "Lowest Health"
    for _, plr in plrs:GetPlayers() do
        if not rbShouldSkip(plr) then
            local char  = plr.Character
            local tr    = rbGetRoot(char)
            local hum   = char and char:FindFirstChildOfClass("Humanoid")
            local value = useHP and (hum and hum.Health or math.huge)
                       or (tr and (tr.Position - root.Position).Magnitude or math.huge)
            if RagebotSettings.autoPriority then
                if RagebotSettings.priorityVoided and tr and tr.Position.Magnitude > 1000000 then
                    value -= 2000000000
                end
                if RagebotSettings.priorityAttackers and rbScanWeapon(plr) ~= "" then
                    value -= 1000000000
                end
            end
            if value < bestV then bestV = value; best = plr end
        end
    end
    return best
end

local function rbIsLobby()
    local playerGui = Player:FindFirstChild("PlayerGui")
    local mainGui   = playerGui and playerGui:FindFirstChild("MainGui")
    local mainFrame = mainGui   and mainGui:FindFirstChild("MainFrame")
    local lobby     = mainFrame and mainFrame:FindFirstChild("Lobby")
    local currency  = lobby     and lobby:FindFirstChild("Currency")
    return currency and currency.Visible == true
end

local function rbGetDuel()
    if not rbDuelMod then
        local ps = Player:FindFirstChild("PlayerScripts")
        local ct = ps and ps:FindFirstChild("Controllers")
        local dc = ct and ct:FindFirstChild("DuelController")
        if dc then
            local ok, mod = tryRequire(dc) or pcall(require, dc)
            if ok and mod then rbDuelMod = ok == true and mod or ok end
            if type(rbDuelMod) ~= "table" then rbDuelMod = nil end
        end
    end
    if rbDuelMod and rbDuelMod.GetDuel then
        local ok, duel = pcall(rbDuelMod.GetDuel, rbDuelMod, Player)
        if ok then return duel end
    end
end

local function rbIsValidMatch()
    if rbIsLobby() or isShootingRange() then return false end
    local char = Player.Character
    local root = rbGetRoot(char)
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if not char or not root or not hum or hum.Health <= 0 then return false end
    local duel = rbGetDuel()
    if duel ~= nil then return true end
    return rbGetFighter() ~= nil
end

local function rbInMatchFn()
    local now = tick()
    if now - rbInMatchT < 0.25 then return rbInMatch end
    rbInMatchT = now
    rbInMatch  = rbIsValidMatch()
    return rbInMatch
end

local function rbBuildCameraData(fromPos, part)
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

local function rbDoFire(st, part)
    local fighter = rbGetFighter()
    local item    = fighter and fighter.EquippedItem
    if not item or not part then return false end

    local cam     = ws.CurrentCamera
    local fromPos = (st.csyncCF and st.csyncCF.Position)
                    or (cam and cam.CFrame.Position)
                    or part.Position

    -- [PATCH 3] lock target PhysicsRepRootRef to head CFrame before firing
    local targetPlayer = st.target
    if targetPlayer then
        local tc  = targetPlayer.Character
        local tr  = rbGetRoot(tc)
        if tr then
            rbSetPhysRef(tr, part.CFrame)
        end
    end

    local anyFired = false
    local attempts = math.max(1, math.floor(RagebotSettings.shootAttempts or 1))
    local useItemRemote = repS.Remotes.Replication.Fighter.UseItem
    for _ = 1, attempts do
        local fired = false
        if RagebotSettings.useManipulation and useItemRemote and enumLib and util then
            local ammo = item.Get and (item:Get("Ammo") or 0) or 0
            if ammo > 0 then
                local oid       = item:Get("ObjectID")
                local shootEnum = enumLib:ToEnum("StartShooting")
                local data      = rbBuildCameraData(fromPos, part)
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

-- [PATCH 4] rbHandleAmmo: direct EquipItem calls, no VIM key presses
local function rbHandleAmmo(st)
    local fighter = rbGetFighter()
    local item    = fighter and fighter.EquippedItem
    if not fighter or not item then return false end

    local ammo = item:Get("Ammo") or 0
    local slot = item:Get("Slot") or 1
    local now  = tick()

    if fighter:Get("Reloading") then
        st.hideOrbitUntil = math.max(st.hideOrbitUntil or 0, now + 0.25)
        st.ammoActionAt   = math.max(st.ammoActionAt   or 0, now + 0.1)
        return true
    end

    if ammo > 0 then return false end
    if now < (st.ammoActionAt or 0) then return true end

    local primary   = RagebotSettings.primarySlot   or 1
    local secondary = RagebotSettings.secondarySlot or 2

    if slot == primary and RagebotSettings.autoSwapSecondary then
        st.ammoActionAt   = now + 0.45
        st.hideOrbitUntil = math.max(st.hideOrbitUntil or 0, now + 0.45)
        st.ammoFallbackSlot = secondary
        -- Direct equip instead of key press
        pcall(function()
            local lf = rbGetFighter()
            if lf and type(lf.EquipItem) == "function" then
                lf:EquipItem(secondary)
            else
                rbPressKey(rbSlotKey[secondary] or Enum.KeyCode.Two)
            end
        end)
        return true
    end

    if slot == secondary and RagebotSettings.autoReloadPrimary then
        st.ammoActionAt   = now + 0.8
        st.hideOrbitUntil = math.max(st.hideOrbitUntil or 0, now + 0.9)
        st.ammoFallbackSlot = primary
        -- Direct equip primary then direct reload
        pcall(function()
            local lf = rbGetFighter()
            if lf and type(lf.EquipItem) == "function" then
                lf:EquipItem(primary)
            else
                rbPressKey(rbSlotKey[primary] or Enum.KeyCode.One)
            end
        end)
        task.delay(0.18, function()
            if not st.active then return end
            local f2   = rbGetFighter()
            local i2   = f2 and f2.EquippedItem
            if f2 and i2 and (i2:Get("Slot") or 1) == primary
               and (i2:Get("Ammo") or 0) <= 0
               and not f2:Get("Reloading") then
                reloadItem(i2)
            end
        end)
        return true
    end

    if slot == primary and RagebotSettings.autoReloadPrimary then
        st.ammoActionAt   = now + 0.8
        st.hideOrbitUntil = math.max(st.hideOrbitUntil or 0, now + 0.9)
        local lf = rbGetFighter()
        local ei = lf and lf.EquippedItem
        if ei then reloadItem(ei) end
        return true
    end

    return true
end

local function rbEquipSlot(slot)
    slot = tonumber(slot) or 1
    local lf = rbGetFighter()
    if lf and type(lf.EquipItem) == "function" then
        pcall(lf.EquipItem, lf, slot)
    else
        rbPressKey(rbSlotKey[slot] or Enum.KeyCode.One)
    end
end

local function rbApplyWeaponProfile(st)
    if RagebotSettings.weaponSpecialize == false then return "default" end
    local fighter = rbGetFighter()
    local item    = fighter and fighter.EquippedItem
    local slot    = item and item:Get("Slot") or nil
    local pref    = RagebotSettings.preferredWeapon or "primary"
    if RagebotSettings.autoEquipPreferred ~= false and not st.preferredEquipped then
        local want = (pref == "secondary" and (RagebotSettings.secondarySlot or 2))
            or (pref == "melee" and (RagebotSettings.meleeSlot or 3))
            or (RagebotSettings.primarySlot or 1)
        if slot ~= want then
            rbEquipSlot(want)
            slot = want
        end
        st.preferredEquipped = true
    end
    local kind
    if slot == (RagebotSettings.meleeSlot or 3) or pref == "melee" then kind = "melee"
    elseif slot == (RagebotSettings.secondarySlot or 2) or pref == "secondary" then kind = "secondary"
    else kind = "primary" end
    if kind == "primary" then
        RagebotSettings.mode           = "Orbit"
        RagebotSettings.hyper          = true
        RagebotSettings.orbitDist      = 3.2
        RagebotSettings.orbitHeight    = 2.2
        RagebotSettings.strafeSpeed    = 6
        RagebotSettings.teleportDelay  = 0.035
        RagebotSettings.behindDist     = 3.5
        RagebotSettings.randomMovement = false
        RagebotSettings.dirBack        = true
        RagebotSettings.dirFront       = false
        RagebotSettings.dirLeft        = true
        RagebotSettings.dirRight       = true
    elseif kind == "secondary" then
        RagebotSettings.mode           = "Teleport"
        RagebotSettings.hyper          = false
        RagebotSettings.orbitDist      = 2.6
        RagebotSettings.orbitHeight    = 1.6
        RagebotSettings.strafeSpeed    = 4
        RagebotSettings.teleportDelay  = 0.028
        RagebotSettings.behindDist     = 3.0
        RagebotSettings.randomMovement = true
        RagebotSettings.randomRefresh  = 0.07
        RagebotSettings.dirBack        = true
        RagebotSettings.dirFront       = true
        RagebotSettings.dirLeft        = true
        RagebotSettings.dirRight       = true
    else
        RagebotSettings.mode             = "Underground"
        RagebotSettings.hyper            = true
        RagebotSettings.orbitDist        = 1.6
        RagebotSettings.orbitHeight      = 0.6
        RagebotSettings.strafeSpeed      = 8
        RagebotSettings.teleportDelay    = 0.02
        RagebotSettings.behindDist       = 2.2
        RagebotSettings.undergroundDepth = 4
        RagebotSettings.randomMovement   = false
        RagebotSettings.dirBack          = true
        RagebotSettings.dirFront         = false
        RagebotSettings.dirLeft          = true
        RagebotSettings.dirRight         = true
        RagebotSettings.dirDown          = true
    end
    st.weaponKind = kind
    return kind
end

-- csync helpers
local function rbSetCsync(st, cf, pos, dt)
    local old      = st.lastFakePos
    st.csyncCF     = cf
    st.csyncLV     = old and dt and dt > 0 and (pos - old) / dt or Vector3.zero
    st.csyncAV     = Vector3.zero
    st.lastFakePos = pos
end

local function rbSetVoidCsync(st, cf, lv, av)
    st.csyncCF     = cf
    st.csyncLV     = lv  or Vector3.zero
    st.csyncAV     = av  or Vector3.zero
    st.lastFakePos = cf and cf.Position or nil
end

local function rbClearCsync(st)
    st.csyncCF     = nil
    st.csyncLV     = nil
    st.csyncAV     = nil
    st.lastFakePos = nil
end

local function rbVoidRand()
    local n = math.random(-2147483646, 2147483646)
    repeat n = math.random(-2147483646, 2147483646)
    until n < -1147483646 or n > 1147483646
    return n
end

local function rbVoidRandCF()
    return CFrame.new(rbVoidRand(), rbVoidRand(), rbVoidRand())
         * CFrame.Angles(math.pi, math.pi, math.pi)
end

local function rbIsSettling()
    return os.clock() < (RagebotSettings.settleUntil or 0)
end

local function rbRestoreLocalRoot(st, root)
    if not root or not st.csyncLocalCF then return false end
    local liveV = root.AssemblyLinearVelocity
    root.CFrame  = st.csyncLocalCF
    if st.csyncLocalLV then
        root.AssemblyLinearVelocity = Vector3.new(
            st.csyncLocalLV.X, liveV.Y, st.csyncLocalLV.Z)
    end
    if st.csyncLocalAV then
        root.AssemblyAngularVelocity = st.csyncLocalAV
    end
    return true
end

local function rbHasValidTarget(st)
    return st.target and not rbPlayerIsDead(st.target) and not rbIsInvincible(st.target)
end

local function rbUpdateStatus(st)
    local target  = rbHasValidTarget(st) and st.target or nil
    local voiding = not target or ((RagebotSettings.mode == "Void" or RagebotSettings.mode == "Orbit") and not st.voidExposed)
    setRagebotStatus(st.active and RagebotSettings.on, target, voiding)
end

-- [PATCH 5] updated should-shoot: add katana deflect angle check
local function rbShouldShoot(st)
    if not rbHasValidTarget(st) then return false end
    if rbIsKatana(st.target) then
        if rbIsKatanaDeflecting(st.target) then return false end
        -- If katana isn't actively deflecting, we can try to shoot
    end
    if rbIsRiotShield(st.target) and st.csyncCF then
        -- Check if shield is facing us; skip if it is
        local tc = st.target.Character
        local tr = rbGetRoot(tc)
        if tr and rbIsShieldedAngle(tr, st.csyncCF.Position) then return false end
    end
    if RagebotSettings.mode == "Void" and not st.voidExposed then return false end
    return true
end

-- csync loop
local function rbStartCsync(st, myGen)
    if st.csyncHbConn then return end
    st.csyncHbConn = RunService.Heartbeat:Connect(function()
        local root = rbGetRoot(Player.Character)
        if not root then return end
        if st.csyncWroteFake and st.csyncLocalCF then
            rbRestoreLocalRoot(st, root)
        end
        if rbIsSettling() then
            st.csyncLocalCF   = root.CFrame
            st.csyncLocalLV   = root.AssemblyLinearVelocity
            st.csyncLocalAV   = root.AssemblyAngularVelocity
            st.csyncWroteFake = false
            return
        end
        st.csyncLocalCF = root.CFrame
        st.csyncLocalLV = root.AssemblyLinearVelocity
        st.csyncLocalAV = root.AssemblyAngularVelocity
        if st.csyncCF then
            root.CFrame = st.csyncCF
            local fakeVelocity  = st.csyncLV or st.csyncLocalLV or root.AssemblyLinearVelocity
            local localVelocity = st.csyncLocalLV or root.AssemblyLinearVelocity
            root.AssemblyLinearVelocity  = Vector3.new(fakeVelocity.X, localVelocity.Y, fakeVelocity.Z)
            root.AssemblyAngularVelocity = st.csyncAV or st.csyncLocalAV or root.AssemblyAngularVelocity
            st.csyncWroteFake = true
            -- [PATCH 2] also update fake camera angle for replication loop
            if not fakeCameraRotation then
                fakeCameraRotation = st.csyncCF
            end
        else
            st.csyncWroteFake = false
            if fakeCameraRotation and not FlickCfg.Active then
                fakeCameraRotation = nil
            end
        end
    end)
    -- [PATCH 2] restore at RenderPriority.First (100) — after replication, before render
    RunService:BindToRenderStep("RB_Csync_" .. myGen, Enum.RenderPriority.First.Value, function()
        local root = rbGetRoot(Player.Character)
        if not root or not st.csyncLocalCF then return end
        if st.csyncWroteFake and rbRestoreLocalRoot(st, root) then
            st.csyncWroteFake = false
            if not FlickCfg.Active then fakeCameraRotation = nil end
        end
    end)
end

local function rbStopCsync(st, myGen)
    if st.csyncHbConn then st.csyncHbConn:Disconnect(); st.csyncHbConn = nil end
    pcall(function() RunService:UnbindFromRenderStep("RB_Csync_" .. myGen) end)
    rbRestoreLocalRoot(st, rbGetRoot(Player.Character))
    rbClearCsync(st)
    st.csyncLocalCF   = nil
    st.csyncLocalLV   = nil
    st.csyncLocalAV   = nil
    st.csyncWroteFake = false
    if not FlickCfg.Active then fakeCameraRotation = nil end
end

-- void csync
local function rbEnterVoidState(st)
    st.voidTargetCF  = nil
    st.voidExposed   = false
    st.orbitClientCF = nil
    if not st.active or not RagebotSettings.on then
        rbClearCsync(st)
        rbUpdateStatus(st)
        return
    end
    if RagebotSettings.voidSpam then
        rbSetVoidCsync(st, rbVoidRandCF())
    else
        rbClearCsync(st)
    end
    rbUpdateStatus(st)
end

local function rbEnableVoidCsync(st, myGen)
    if st.voidHbConn then return end
    rbStartCsync(st, myGen)
    st.voidHbConn = RunService.Heartbeat:Connect(function()
        if rbIsSettling() then
            st.voidTargetCF = nil
            st.voidExposed  = false
            rbClearCsync(st)
            return
        end
        local targetCF = st.voidTargetCF
        if targetCF then
            rbSetVoidCsync(st, targetCF, Vector3.zero, Vector3.zero)
        elseif RagebotSettings.voidSpam then
            rbSetVoidCsync(st, rbVoidRandCF())
        else
            rbClearCsync(st)
        end
    end)
end

local function rbDisableVoidCsync(st, myGen)
    if st.voidHbConn then st.voidHbConn:Disconnect(); st.voidHbConn = nil end
    pcall(function() RunService:UnbindFromRenderStep("RB_VoidCsync_" .. myGen) end)
    st.voidTargetCF = nil
    st.voidThread   = nil
    st.voidExposed  = false
end

-- orbit render fix
local function rbStartOrbitRender(st, myGen)
    if st.orbitRenderRunning then return end
    st.orbitRenderRunning = true
    RunService:BindToRenderStep("RB_Orbit_" .. myGen, Enum.RenderPriority.First.Value, function()
        if not st.orbitClientCF then return end
        local root = rbGetRoot(Player.Character)
        if not root then return end
        root.CFrame = st.orbitClientCF
    end)
end

local function rbStopOrbitRender(st, myGen)
    if not st.orbitRenderRunning then return end
    pcall(function() RunService:UnbindFromRenderStep("RB_Orbit_" .. myGen) end)
    st.orbitRenderRunning = false
    st.orbitClientCF      = nil
end

-- void loop
local function rbStartVoidLoop(st, myGen)
    if st.voidThread then return end
    rbEnableVoidCsync(st, myGen)
    local thread
    thread = task.spawn(function()
        while st.active and RagebotSettings.on and rbGen == myGen and not st.suspended do
            if rbIsSettling() then
                st.voidTargetCF = nil
                st.voidExposed  = false
                rbClearCsync(st)
                task.wait(0.03)
                continue
            end
            if not rbInMatchFn() or not rbHasValidTarget(st) or rbIsKatana(st.target) then
                rbEnterVoidState(st)
                task.wait(0.1)
                continue
            end
            rbEnterVoidState(st)
            if RagebotSettings.voidHideTime > 0 then task.wait(RagebotSettings.voidHideTime) end
            if not st.active or not RagebotSettings.on or rbGen ~= myGen or st.suspended or not rbInMatchFn() then break end
            local target = st.target
            if rbHasValidTarget(st) and not rbIsKatana(target) then
                local tc   = target.Character
                local tr   = rbGetRoot(tc)
                local head = tc and (tc:FindFirstChild("Head") or tr)
                if tr and head then
                    local shootPos = rbIsRiotShield(target)
                        and (tr.Position - tr.CFrame.LookVector * (RagebotSettings.behindDist or 4))
                        or  (tr.Position - tr.CFrame.LookVector * 2.5 + Vector3.new(0, 1.5, 0))
                    if not rbIsSafePos(shootPos, target) then
                        rbEnterVoidState(st)
                        task.wait(0.1)
                        continue
                    end
                    local shootCF      = CFrame.new(shootPos, head.Position)
                    st.voidExposed     = true
                    st.voidTargetCF    = shootCF
                    rbSetVoidCsync(st, shootCF, Vector3.zero, Vector3.zero)
                    -- [PATCH 3] lock PhysicsRepRootRef during void exposure
                    rbSetPhysRef(tr, head.CFrame)
                    rbUpdateStatus(st)
                    if RagebotSettings.voidShootTime > 0 then task.wait(RagebotSettings.voidShootTime) end
                    if rbHasValidTarget(st) and not rbIsKatana(target) then
                        rbDoFire(st, head)
                    end
                    task.wait(0.05)
                    rbEnterVoidState(st)
                    rbClearPhysRef(tr)
                end
            end
        end
        if st.voidThread == thread then st.voidThread = nil end
        if rbGen == myGen and not st.suspended and st.voidThread == nil then
            rbDisableVoidCsync(st, myGen)
        end
    end)
    st.voidThread = thread
end

-- noclip
local function rbEnableNoclip(st)
    if st.noclipConn then return end
    st.noclipConn = RunService.Stepped:Connect(function()
        local char = Player.Character
        if not char then return end
        for _, part in char:GetDescendants() do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end)
end

-- ammo loop
local function rbStartAmmoLoop(st)
    if st.ammoThread then return end
    st.ammoThread = task.spawn(function()
        while st.active do
            if isShootingRange() then task.wait(0.1); continue end
            if not rbHandleAmmo(st) and rbShouldShoot(st) and not RagebotSettings.hyper then
                local tc   = st.target and st.target.Character
                local head = tc and (tc:FindFirstChild("Head") or rbGetRoot(tc))
                if head then
                    if RagebotSettings.shootDelay > 0 then task.wait(RagebotSettings.shootDelay) end
                    rbDoFire(st, head)
                end
            end
            task.wait(math.max(0.01, RagebotSettings.acSpd))
        end
        st.ammoThread = nil
    end)
end

-- offset helpers
local function rbGetDirs(targetRoot)
    local dirs  = {}
    local look  = targetRoot.CFrame.LookVector
    local right = targetRoot.CFrame.RightVector
    if RagebotSettings.dirBack  then table.insert(dirs, -look)  end
    if RagebotSettings.dirFront then table.insert(dirs, look)   end
    if RagebotSettings.dirLeft  then table.insert(dirs, -right) end
    if RagebotSettings.dirRight then table.insert(dirs, right)  end
    if #dirs == 0 then dirs[1] = -look; dirs[2] = right; dirs[3] = -right end
    return dirs
end

local function rbPickOffset(targetRoot, head)
    local dirs   = rbGetDirs(targetRoot)
    local dir    = dirs[math.random(1, #dirs)]
    local radius = math.clamp(RagebotSettings.orbitDist  or 3,  1.25, 5)
    local height = math.clamp(RagebotSettings.orbitHeight or 2, -2,   6)
    local pos    = head.Position + dir * radius + Vector3.new(0, height, 0)
    if RagebotSettings.dirUp   and math.random() < 0.2  then
        pos += Vector3.new(0,  math.max(1, height), 0)
    elseif RagebotSettings.dirDown and math.random() < 0.15 then
        pos += Vector3.new(0, -math.max(1, math.min(3, RagebotSettings.undergroundDepth or 2)), 0)
    end
    return pos
end

local function rbUndergroundPos(head, targetRoot)
    local depth  = math.clamp(RagebotSettings.undergroundDepth or 6, 3, 8)
    local radius = math.clamp(RagebotSettings.orbitDist        or 3, 1.25, 4)
    return head.Position - targetRoot.CFrame.LookVector * radius + Vector3.new(0, -depth, 0)
end

-- UseItem hook (void mode)
local rbHookInstalled = false
local rbOldFireServer = nil

local function rbInstallHook(st)
    if rbHookInstalled then return end
    local useItemRemote = repS.Remotes.Replication.Fighter.UseItem
    if not useItemRemote then return end
    if not _hookfunction then return end
    rbHookInstalled = true
    rbOldFireServer = _hookfunction(useItemRemote.FireServer, _newcclosure(function(self, oid, action, cameradata, ...)
        if st.active and RagebotSettings.on
           and RagebotSettings.mode == "Void"
           and RagebotSettings.useManipulation
           and enumLib and action == enumLib:ToEnum("StartShooting") then
            if rbIsLobby() or not rbInMatchFn() then
                return rbOldFireServer(self, oid, action, cameradata, ...)
            end
            local target = st.target
            if rbHasValidTarget(st) and not rbIsKatana(target) then
                local tc   = target.Character
                local tr   = rbGetRoot(tc)
                local head = tc and (tc:FindFirstChild("Head") or tr)
                if tr and head then
                    local shootPos = rbIsRiotShield(target)
                        and (tr.Position - tr.CFrame.LookVector * (RagebotSettings.behindDist or 4))
                        or  (tr.Position - tr.CFrame.LookVector * 2.5 + Vector3.new(0, 1.5, 0))
                    if not rbIsSafePos(shootPos, target) then
                        rbEnterVoidState(st)
                        return rbOldFireServer(self, oid, action, cameradata, ...)
                    end
                    local shootCF  = CFrame.new(shootPos, head.Position)
                    st.voidExposed  = true
                    st.voidTargetCF = shootCF
                    rbSetVoidCsync(st, shootCF, Vector3.zero, Vector3.zero)
                    rbSetPhysRef(tr, head.CFrame)
                    rbUpdateStatus(st)
                    task.wait(0.02)
                    local newData = rbBuildCameraData(shootPos, head) or cameradata
                    task.spawn(function()
                        task.wait(0.05)
                        rbEnterVoidState(st)
                        rbClearPhysRef(tr)
                    end)
                    return rbOldFireServer(self, oid, action, newData, ...)
                end
            end
        end
        return rbOldFireServer(self, oid, action, cameradata, ...)
    end))
end

-- Main ragebot start/stop
local function stopRagebot()
    rbGen += 1
    if rbActiveState then
        local st = rbActiveState
        st.active             = false
        RagebotSettings.on    = false
        setRagebotStatus(false)
        if st.conn       then st.conn:Disconnect();       st.conn       = nil end
        if st.noclipConn then st.noclipConn:Disconnect(); st.noclipConn = nil end
        st.target             = nil
        st.voidExposed        = false
        st.nextTeleportAt     = 0
        st.ammoActionAt       = 0
        st.hideOrbitUntil     = 0
        st.randPos            = nil
        st.randT              = 0
        st.lastFakePos        = nil
        rbInMatchT            = 0
        rbInMatch             = false
        -- clean up all PhysicsRepRootRef fakes on stop
        for root, _ in physRepGlue do
            rbClearPhysRef(root)
        end
        rbStopCsync(st, rbGen - 1)
        rbDisableVoidCsync(st, rbGen - 1)
        rbStopOrbitRender(st, rbGen - 1)
        local char = Player.Character
        if char then
            for _, part in char:GetDescendants() do
                if part:IsA("BasePart") then part.CanCollide = true end
            end
        end
        rbActiveState = nil
    end
    if rbCharConn then rbCharConn:Disconnect(); rbCharConn = nil end
    fakeCameraRotation = nil
end

local function startRagebot()
    if rbActiveState then stopRagebot() end
    RagebotSettings.on       = true
    RagebotSettings.settleUntil = 0
    rbGen += 1
    local myGen = rbGen

    local st = {
        active           = true,
        target           = nil,
        conn             = nil,
        ammoThread       = nil,
        voidThread       = nil,
        voidHbConn       = nil,
        csyncHbConn      = nil,
        voidExposed      = false,
        voidTargetCF     = nil,
        nextTeleportAt   = 0,
        ammoActionAt     = 0,
        ammoFallbackSlot = nil,
        hideOrbitUntil   = 0,
        preferredEquipped = false,
        randPos          = nil,
        randT            = 0,
        lastFakePos      = nil,
        csyncCF          = nil,
        csyncLV          = nil,
        csyncAV          = nil,
        csyncLocalCF     = nil,
        csyncLocalLV     = nil,
        csyncLocalAV     = nil,
        csyncWroteFake   = false,
        noclipConn       = nil,
        suspended        = isShootingRange(),
        weaponKind       = nil,
        orbitRenderRunning = false,
        orbitClientCF    = nil,
    }
    rbActiveState = st

    setRagebotStatus(true, nil, true)
    rbStartAmmoLoop(st)
    rbInstallHook(st)

    if not st.suspended then
        rbEnableNoclip(st)
        local mode = RagebotSettings.mode
        if mode == "Void" then
            rbStartVoidLoop(st, myGen)
        elseif mode == "Orbit" then
            rbEnableVoidCsync(st, myGen)
            rbStartOrbitRender(st, myGen)
        else
            rbStartCsync(st, myGen)
        end
    end

    local aaPhase    = 0
    local orbitAngle = math.random() * math.pi * 2
    local function rnd()    return math.random() * 2 - 1 end
    local function rndDir()
        local angle = math.random() * math.pi * 2
        return Vector3.new(math.cos(angle), 0, math.sin(angle))
    end

    st.conn = RunService.Stepped:Connect(function(_, dt)
        if not st.active or not RagebotSettings.on then
            if st.conn then st.conn:Disconnect(); st.conn = nil end
            return
        end
        if isShootingRange() then
            if not st.suspended then
                st.suspended    = true
                st.target       = nil
                st.randPos      = nil
                st.voidTargetCF = nil
                st.voidExposed  = false
                if st.noclipConn then st.noclipConn:Disconnect(); st.noclipConn = nil end
                rbStopCsync(st, myGen)
                rbDisableVoidCsync(st, myGen)
                rbStopOrbitRender(st, myGen)
                rbUpdateStatus(st)
            end
            return
        end
        if st.suspended then
            st.suspended = false
            rbEnableNoclip(st)
            local mode = RagebotSettings.mode
            if mode == "Void" then
                rbStartVoidLoop(st, myGen)
            elseif mode == "Orbit" then
                rbEnableVoidCsync(st, myGen)
                rbStartOrbitRender(st, myGen)
            else
                rbStartCsync(st, myGen)
            end
        end

        local root = rbGetRoot(Player.Character)
        if not root then return end

        if rbIsSettling() then
            st.voidTargetCF  = nil
            st.voidExposed   = false
            st.orbitClientCF = nil
            rbClearCsync(st)
            rbUpdateStatus(st)
            return
        end

        if not rbInMatchFn() then
            rbClearCsync(st)
            st.target = nil
            if RagebotSettings.mode == "Orbit" then rbEnterVoidState(st)
            else rbUpdateStatus(st) end
            return
        end

        local now = tick()

        if st.target and rbPlayerIsDead(st.target) then st.target = nil end
        if st.target and rbIsInvincible(st.target) then
            rbClearCsync(st)
            if RagebotSettings.mode == "Orbit" then rbEnterVoidState(st)
            else rbUpdateStatus(st) end
            return
        end

        if now - rbTgtT >= 0.05 and (RagebotSettings.autoSwitch or not st.target) then
            rbTgtT = now
            if RagebotSettings.autoSwitch then
                local target = rbGetBestTarget()
                if target then
                    if RagebotSettings.sendNotification and st.target ~= target then
                        task.spawn(function()
                            Notify("ragebot → " .. target.Name, "success")
                        end)
                    end
                    st.target = target
                end
            elseif not st.target then
                st.target = rbGetBestTarget()
            end
        end

        if not st.target then
            rbClearCsync(st)
            if RagebotSettings.mode == "Orbit" then rbEnterVoidState(st)
            else rbUpdateStatus(st) end
            return
        end

        local tc   = st.target.Character
        local tr   = rbGetRoot(tc)
        local head = tc and (tc:FindFirstChild("Head") or tr)
        if not tc or not tr or not head then
            st.target = nil; rbUpdateStatus(st); return
        end

        if rbIsNearOtherMatch(tr.Position, st.target) then
            st.target  = nil
            st.randPos = nil
            if RagebotSettings.mode == "Orbit" or RagebotSettings.mode == "Void" then
                rbEnterVoidState(st)
            else
                rbClearCsync(st); rbUpdateStatus(st)
            end
            return
        end

        rbUpdateStatus(st)
        rbApplyWeaponProfile(st)

        if RagebotSettings.mode == "Void" then return end

        if RagebotSettings.mode == "Orbit"
           and (now < (st.hideOrbitUntil or 0) or rbHandleAmmo(st)) then
            st.voidTargetCF  = nil
            st.voidExposed   = false
            st.orbitClientCF = nil
            rbEnterVoidState(st)
            return
        end

        local isUnderground = RagebotSettings.mode == "Underground"
        local isShield      = rbIsRiotShield(st.target)
        local height        = math.clamp(RagebotSettings.orbitHeight or 2,  -2, 6)
        local radius        = math.clamp(RagebotSettings.orbitDist   or 3, 1.25, 5)
        local targetPos

        if isShield then
            targetPos = tr.Position - tr.CFrame.LookVector * (RagebotSettings.behindDist or 3)
        elseif isUnderground then
            targetPos = rbUndergroundPos(head, tr)
        elseif RagebotSettings.mode == "Teleport" then
            if RagebotSettings.randomMovement then
                if not st.randPos or (now - (st.randT or 0)) >= (RagebotSettings.randomRefresh or 0.08) then
                    st.randT   = now
                    st.randPos = rbPickOffset(tr, head)
                               + rndDir() * (math.random() * 1.05)
                               + Vector3.new(0, rnd() * 0.7, 0)
                end
                targetPos = st.randPos
            else
                targetPos = rbPickOffset(tr, head)
            end
        elseif RagebotSettings.mode == "Orbit" then
            orbitAngle += dt * math.max(1, (RagebotSettings.strafeSpeed or 5) * 1.5)
            targetPos   = head.Position
                        + Vector3.new(math.cos(orbitAngle) * radius, height, math.sin(orbitAngle) * radius)
        else
            targetPos = rbUndergroundPos(head, tr)
        end

        if not rbIsSafePos(targetPos, st.target) then
            st.randPos = nil
            if RagebotSettings.mode == "Orbit" then
                st.voidTargetCF  = nil
                st.voidExposed   = false
                st.orbitClientCF = nil
                rbEnterVoidState(st)
            else
                rbClearCsync(st); rbUpdateStatus(st)
            end
            return
        end

        local faceCF = CFrame.new(targetPos, head.Position)
        if RagebotSettings.antiAim then
            aaPhase += dt * 20
            faceCF   = CFrame.new(targetPos, head.Position)
                      * CFrame.Angles(0, math.rad(math.sin(aaPhase) * 70), 0)
        end

        if RagebotSettings.mode == "Orbit" then
            if RagebotSettings.hyper or not isUnderground then
                st.voidExposed   = true
                st.voidTargetCF  = faceCF
                st.orbitClientCF = faceCF
                rbSetCsync(st, faceCF, targetPos, dt)
                rbUpdateStatus(st)
                if rbShouldShoot(st) then rbDoFire(st, head) end
            end
        else
            rbSetCsync(st, faceCF, targetPos, dt)
            if RagebotSettings.hyper then
                if rbShouldShoot(st) then rbDoFire(st, head) end
            elseif RagebotSettings.mode == "Teleport" and not isUnderground then
                if now >= (st.nextTeleportAt or 0) then
                    st.nextTeleportAt = now + math.max(0.01, RagebotSettings.teleportDelay or 0.04)
                    if rbShouldShoot(st) then rbDoFire(st, head) end
                end
            end
        end
    end)

    rbCharConn = Player.CharacterAdded:Connect(function()
        rbStopCsync(st, myGen)
        rbDisableVoidCsync(st, myGen)
        rbStopOrbitRender(st, myGen)
        st.target         = nil
        rbClearCsync(st)
        st.csyncLocalCF   = nil
        st.csyncLocalLV   = nil
        st.csyncLocalAV   = nil
        st.csyncWroteFake = false
        st.voidExposed    = false
        st.hideOrbitUntil = 0
        if st.active then
            task.wait(0.5)
            if st.active then
                local mode = RagebotSettings.mode
                if mode == "Void" then
                    rbStartVoidLoop(st, myGen)
                elseif mode == "Orbit" then
                    rbEnableVoidCsync(st, myGen)
                    rbStartOrbitRender(st, myGen)
                else
                    rbStartCsync(st, myGen)
                end
            end
        end
    end)
end

-- ============================================================
-- TABS — Flickbot
-- ============================================================
local FlickTab = MakeTab("7733960981")
local FkMain   = FlickTab:Group("Flickbot")
FkMain:Toggle({
    Name    = "Active",
    Default = false,
    Callback = function(v) FlickCfg.Active = v end,
})
FkMain:Toggle({
    Name    = "Desync (True Replic. Spoof)",
    Default = true,
    Tooltip = "Write fake CFrame in Heartbeat; restore at RenderPriority.First after replication",
    Callback = function(v) FlickCfg.Desync = v end,
})
FkMain:Toggle({
    Name    = "Prediction",
    Default = true,
    Callback = function(v) FlickCfg.PredictionOn = v end,
})
FkMain:Slider({
    Name = "Prediction Scale", Min = 0, Max = 100, Default = 8,
    Format = function(v) return string.format("%.2f", v/100) end,
    RealValue = function(v) return v/100 end,
    Callback = function(v) FlickCfg.PredictionScale = v end,
})
FkMain:Toggle({
    Name    = "Team Filter",
    Default = true,
    Callback = function(v) FlickCfg.TeamFilter = v end,
})
FkMain:Toggle({
    Name    = "Anti Velocity",
    Default = true,
    Callback = function(v) FlickCfg.AntiVelocity = v end,
})
FkMain:Toggle({
    Name    = "Randomize Offset",
    Default = false,
    Callback = function(v) FlickCfg.RandomizeOffset = v end,
})

local FkOffset = FlickTab:Group("Position Offset")
FkOffset:Slider({ Name="Offset X", Min=-500, Max=500, Default=0,
    Format=function(v) return string.format("%.1f",v/10) end,
    RealValue=function(v) return v/10 end,
    Callback=function(v) FlickCfg.OffsetX=v end })
FkOffset:Slider({ Name="Offset Y", Min=-500, Max=500, Default=0,
    Format=function(v) return string.format("%.1f",v/10) end,
    RealValue=function(v) return v/10 end,
    Callback=function(v) FlickCfg.OffsetY=v end })
FkOffset:Slider({ Name="Offset Z", Min=-500, Max=500, Default=0,
    Format=function(v) return string.format("%.1f",v/10) end,
    RealValue=function(v) return v/10 end,
    Callback=function(v) FlickCfg.OffsetZ=v end })

local FkAdv = FlickTab:Group("Flick Params")
FkAdv:Slider({ Name="Flick Speed", Min=100, Max=100000, Default=99999,
    Callback=function(v) FlickCfg.FlickSpeed=v end })
FkAdv:Slider({ Name="Flick Radius", Min=1, Max=200, Default=25,
    Format=function(v) return string.format("%.2f",v/100) end,
    RealValue=function(v) return v/100 end,
    Callback=function(v) FlickCfg.FlickRadius=v end })
FkAdv:Slider({ Name="Writes Per Frame", Min=1, Max=10, Default=3,
    Callback=function(v) FlickCfg.WritesPerFrame=math.floor(v) end })
FkAdv:Slider({ Name="Lerp Alpha", Min=1, Max=100, Default=100,
    Format=function(v) return string.format("%.2f",v/100) end,
    RealValue=function(v) return v/100 end,
    Callback=function(v) FlickCfg.FlickLerpAlpha=v end })
FkAdv:Button({
    Name="Zero Melee CDs", Variant="Primary",
    Tooltip="Clear cooldowns on all melee items in ItemLibrary",
    Callback=function() zeroCDs(); Notify("cooldowns zeroed","success") end
})

-- ============================================================
-- TABS — Rage (flickbot)
-- ============================================================
local RageTab  = MakeTab("6022668800")
local RgMain   = RageTab:Group("Flick-Rage")
RgMain:Toggle({
    Name="Active", Default=false,
    Callback=function(v) RageCfg.Active=v end,
})
RgMain:Slider({ Name="Fire Rate", Min=0, Max=100, Default=0,
    Format=function(v) return string.format("%.4f",v/10000) end,
    RealValue=function(v) return v/10000 end,
    Callback=function(v) RageCfg.FireRate=v end })

local RgWeapon = RageTab:Group("Weapons")
RgWeapon:Toggle({ Name="Primary",   Default=true,  Callback=function(v) RageCfg.WeaponPrimary=v end })
RgWeapon:Toggle({ Name="Secondary", Default=true,  Callback=function(v) RageCfg.WeaponSecondary=v end })
RgWeapon:Toggle({ Name="Melee",     Default=true,  Callback=function(v) RageCfg.WeaponMelee=v end })
RgWeapon:Dropdown({
    Name="On Empty", Options={"SwapOrReload","Swap","Reload"}, Default="SwapOrReload",
    Callback=function(v) RageCfg.OnEmpty=v end,
})
RgWeapon:Button({
    Name="Swap Now", Variant="Primary",
    Callback=function() forceSwap() end,
})
RgWeapon:Button({
    Name="Refresh Item Cache",
    Callback=function() task.spawn(RefreshItemCache); Notify("item cache refreshed","success") end,
})

-- ============================================================
-- TABS — Ragebot
-- ============================================================
local RbTab  = MakeTab("6022668888")
local RbMain = RbTab:Group("Ragebot")
RbMain:Toggle({
    Name="Ragebot Active",
    Tooltip="Orbit / Void / Teleport / Underground movement engine",
    Callback=function(v)
        if v then
            startRagebot()
            Notify("arch script — ragebot active","success")
        else
            stopRagebot()
        end
    end,
})
RbMain:Dropdown({
    Name="Mode", Options={"Orbit","Void","Teleport","Underground"}, Default="Orbit",
    Callback=function(v) RagebotSettings.mode=v; markRagebotSettingsDirty() end,
})
RbMain:Dropdown({
    Name="Target Mode", Options={"Closest","Lowest Health"}, Default="Closest",
    Callback=function(v) RagebotSettings.targetMode=v; markRagebotSettingsDirty() end,
})

local RbVoid = RbTab:Group("Void Settings")
RbVoid:Toggle({ Name="Void Spam", Default=true,
    Callback=function(v) RagebotSettings.voidSpam=v; markRagebotSettingsDirty() end })
RbVoid:Slider({ Name="Hide Time", Min=0, Max=100, Default=25,
    Format=function(v) return string.format("%.2f",v/100).."s" end,
    RealValue=function(v) return v/100 end,
    Callback=function(v) RagebotSettings.voidHideTime=v; markRagebotSettingsDirty() end })
RbVoid:Slider({ Name="Attack Time", Min=0, Max=100, Default=3,
    Format=function(v) return string.format("%.2f",v/100).."s" end,
    RealValue=function(v) return v/100 end,
    Callback=function(v) RagebotSettings.voidShootTime=v; markRagebotSettingsDirty() end })
RbVoid:Slider({ Name="Shoot Attempts", Min=1, Max=10, Default=1,
    Callback=function(v) RagebotSettings.shootAttempts=math.floor(v); markRagebotSettingsDirty() end })
RbVoid:Toggle({ Name="Use Remote Manipulation", Default=true,
    Callback=function(v) RagebotSettings.useManipulation=v; markRagebotSettingsDirty() end })

local RbWeapon = RbTab:Group("Weapon Slots")
RbWeapon:Toggle({ Name="Use Primary",   Default=true,  Callback=function(v) RageCfg.WeaponPrimary=v end })
RbWeapon:Toggle({ Name="Use Secondary", Default=true,  Callback=function(v) RageCfg.WeaponSecondary=v end })
RbWeapon:Toggle({ Name="Use Melee",     Default=true,  Callback=function(v) RageCfg.WeaponMelee=v end })

local RbSwap = RbTab:Group("Swap or Reload")
RbSwap:Dropdown({
    Name="On Empty", Options={"SwapOrReload","Swap","Reload"}, Default="SwapOrReload",
    Callback=function(v) RageCfg.OnEmpty=v end,
})
RbSwap:Button({ Name="Swap Now", Variant="Primary", Callback=function() forceSwap() end })
RbSwap:Button({ Name="Refresh Item Cache",
    Callback=function() task.spawn(RefreshItemCache); Notify("item cache refreshed","success") end })

local RbPos = RbTab:Group("Position Offset")
RbPos:Slider({ Name="Orbit Distance", Min=125, Max=500, Default=300,
    Format=function(v) return string.format("%.2f",v/100) end,
    RealValue=function(v) return v/100 end,
    Callback=function(v) RagebotSettings.orbitDist=v; markRagebotSettingsDirty() end })
RbPos:Slider({ Name="Orbit Height", Min=-200, Max=600, Default=200,
    Format=function(v) return string.format("%.1f",v/100) end,
    RealValue=function(v) return v/100 end,
    Callback=function(v) RagebotSettings.orbitHeight=v; markRagebotSettingsDirty() end })
RbPos:Slider({ Name="Behind Distance", Min=100, Max=600, Default=400,
    Format=function(v) return string.format("%.1f",v/100) end,
    RealValue=function(v) return v/100 end,
    Callback=function(v) RagebotSettings.behindDist=v; markRagebotSettingsDirty() end })
RbPos:Slider({ Name="Underground Depth", Min=3, Max=8, Default=6,
    Callback=function(v) RagebotSettings.undergroundDepth=math.floor(v); markRagebotSettingsDirty() end })
RbPos:Slider({ Name="Strafe Speed", Min=1, Max=15, Default=5,
    Callback=function(v) RagebotSettings.strafeSpeed=math.floor(v); markRagebotSettingsDirty() end })
RbPos:Slider({ Name="Teleport Delay", Min=0, Max=20, Default=4,
    Format=function(v) return string.format("%.2f",v/100).."s" end,
    RealValue=function(v) return v/100 end,
    Callback=function(v) RagebotSettings.teleportDelay=v; markRagebotSettingsDirty() end })

local RbPri = RbTab:Group("Priority")
RbPri:Toggle({ Name="Auto Prioritize", Default=false,
    Callback=function(v) RagebotSettings.autoPriority=v; RagebotSettings.autoSwitch=v; markRagebotSettingsDirty() end })
RbPri:Toggle({ Name="Priority: Attackers", Default=true,
    Callback=function(v) RagebotSettings.priorityAttackers=v; markRagebotSettingsDirty() end })
RbPri:Toggle({ Name="Priority: Voided", Default=true,
    Callback=function(v) RagebotSettings.priorityVoided=v; markRagebotSettingsDirty() end })
RbPri:Toggle({ Name="Send Notification", Default=false,
    Callback=function(v) RagebotSettings.sendNotification=v; markRagebotSettingsDirty() end })

local RbPriGroup2 = RbTab:Group("Prioritized Player")
local function getPlayerNames()
    local names = {}
    for _, p in plrs:GetPlayers() do
        if p ~= Player then table.insert(names, p.Name) end
    end
    table.sort(names)
    return names
end
local rbPrioritizedDropdown = RbPriGroup2:Dropdown({
    Name="Force Target", Options=getPlayerNames(), Default="(none)",
    Callback=function(v) RagebotSettings.prioritizedPlayer=(v=="(none)") and nil or v; markRagebotSettingsDirty() end,
})
local function refreshRbPriorityList()
    local names = getPlayerNames()
    table.insert(names, 1, "(none)")
    if rbPrioritizedDropdown and rbPrioritizedDropdown.SetOptions then
        rbPrioritizedDropdown.SetOptions(names)
    end
end
plrs.PlayerAdded:Connect(refreshRbPriorityList)
plrs.PlayerRemoving:Connect(refreshRbPriorityList)

local RbMisc = RbTab:Group("Misc")
RbMisc:Toggle({ Name="Anti-Aim", Default=false,
    Callback=function(v) RagebotSettings.antiAim=v; markRagebotSettingsDirty() end })
RbMisc:Toggle({ Name="Hyper Fire", Default=false,
    Callback=function(v) RagebotSettings.hyper=v; markRagebotSettingsDirty() end })
RbMisc:Toggle({ Name="Random Movement", Default=false,
    Callback=function(v) RagebotSettings.randomMovement=v; markRagebotSettingsDirty() end })
RbMisc:Slider({ Name="Avoid Other Match Dist", Min=0, Max=2000, Default=1000, Unit=" st",
    Callback=function(v) RagebotSettings.otherMatchAvoidDistance=math.floor(v); markRagebotSettingsDirty() end })
RbMisc:Button({
    Name="Stop Ragebot", Variant="Danger",
    Callback=function() stopRagebot(); Notify("ragebot stopped","warning") end,
})

-- ============================================================
-- Keybind / toggle
-- ============================================================
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

Notify("arch script enhanced — Insert to toggle", "success")
print("[arch script enhanced] loaded")
print("  identity(8) bootstrap : " .. ((_setthreadidentity and "ok") or "unavailable — executor may limit"))
print("  PhysicsRepRootRef      : " .. ((_sethiddenproperty and "ok") or "unavailable"))
print("  hookfunction           : " .. ((_hookfunction and "ok") or "unavailable"))
print("  debug.setupvalue       : " .. ((_debug_setupvalue and "ok") or "unavailable"))
