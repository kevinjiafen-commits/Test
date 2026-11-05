if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local StarterGui = game:GetService("StarterGui")
local VirtualInputManager = game:GetService("VirtualInputManager")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer

if game.GameId ~= 7633926880 then
    LocalPlayer:Kick("Mario Hub: this script is for BloxStrike only")
    return
end

---@return function  the game's own print when the executor exposes it
local function RuntimePrint()
    local ok, renv = pcall(getrenv)
    return ok and type(renv) == "table" and type(renv.print) == "function" and renv.print or print
end

local MarioBanner = {
    Print = RuntimePrint(),
    Started = os.clock(),
    Last = os.clock(),
    Done = 0,
    Total = 4,
}

function MarioBanner.Show()
    local ok, executor = pcall(identifyexecutor)
    if not ok or type(executor) ~= "string" then executor = "Unknown" end
    local rule = string.rep("=", 54)
    MarioBanner.Print(table.concat({
        "",
        [[
                                                             @%@
                                                            @*-#@
                                      @@@@@@@@@@@@@          @@#+.:-*%@@      @@
                               @@@@@%##***********##%@@@@@   @*--:-==+*@@@@#*+==+*%@@
]],
        rule,
        "   MARIO HUB  //  BloxStrike by xDTaraZ  //  discord.gg/FHVfmeSceA",
        "   executor: " .. executor .. "   //   player: " .. game:GetService("Players").LocalPlayer.Name,
        rule,
    }, "\n"))
end

---@param label string  what just finished loading
function MarioBanner.Step(label)
    local now = os.clock()
    MarioBanner.Done = math.min(MarioBanner.Done + 1, MarioBanner.Total)
    local filled = math.floor(MarioBanner.Done / MarioBanner.Total * 20 + 0.5)
    MarioBanner.Print(string.format("[Mario Hub] [%s] %3d%%  %-24s +%dms",
        string.rep("#", filled) .. string.rep(".", 20 - filled),
        math.floor(MarioBanner.Done / MarioBanner.Total * 100), label, math.floor((now - MarioBanner.Last) * 1000)))
    MarioBanner.Last = now
end

function MarioBanner.Ready()
    local rule = string.rep("=", 54)
    MarioBanner.Print(table.concat({
        rule,
        string.format("   >> READY in %dms", math.floor((os.clock() - MarioBanner.Started) * 1000)),
        rule,
    }, "\n"))
end

pcall(MarioBanner.Show)
pcall(MarioBanner.Step, "Core")

local environment = getgenv and getgenv() or _G
if environment.BloxStrikeUnload then pcall(environment.BloxStrikeUnload) end

if not LPH_OBFUSCATED then
    local function Passthrough(fn) return fn end
    LPH_JIT, LPH_JIT_MAX, LPH_NO_VIRTUALIZE = Passthrough, Passthrough, Passthrough
end

local vector2New = Vector2.new
local cframeLookAt = CFrame.lookAt
local osClock = os.clock

-- Library will be set after loading Library_lua
local Library

local xDTaraZ = setmetatable({}, {
    __newindex = function(self, key, value)
        rawset(self, key, type(value) == "function" and LPH_JIT(value) or value)
    end,
})

xDTaraZ.Config = {
    -- Library_lua is loaded from the local loadstring path provided by user
    UiSource = "Library_lua",  -- placeholder; actual load is done in BuildInterface
    Discord = "https://discord.gg/FHVfmeSceA",
    UpdateLog = {
        { "2026-10-10", "Silent Aim and Ragebot hit again after the game update\nFixed the game crashing when you shoot\nFixed ESP Team Check and health\nAim and ESP now include bots\nSkin pictures, turning skins off restores the stock look\nAuto Rebuy works from round 1, No Flash/No Smoke/FOV restore when off" },
        { "2026-10-03", "Classic Mario Hub UI is back\nBetter executor support\nImproved Combat & Movement" },
    },
    SaveFolder = "BloxStrike",
    StatusInterval = 1,
    AimRenderPriority = Enum.RenderPriority.Camera.Value + 1,
    RefireGap = 0.12,
    TriggerRay = 2000,
    SilentFocusTime = 1,
    SeeThrough = { "Characters", "Debris", "ThirdPersonWeaponStash" },
    EspCacheMax = 256,
    SoundSelfRange = 6,
    GhostSnap = 45,
    LeadExtra = 0.02,
    LeadMaxSpeed = 60,
    SpreadMethods = { "getTrueSpread", "getSpreadForConfig", "getMovementSpreadForConfig", "getBaseSpreadForConfig", "getBaseSpread" },
    SoundMaxMarks = 24,
    SoundColor = Color3.fromRGB(255, 196, 64),
    RedeemGap = 1.1,
    RebuyGap = 0.25,
    AlertTries = 20,
    AlertGap = 0.5,
    RequireTimeout = 5,
    MaxFails = 5,
    FailWindow = 10,
    CombatToggles = { "Aimbot", "Triggerbot", "Ragebot", "AimbotShowFov", "SilentShowFov" },
    ModuleFeatures = {
        Net = { "AutoRebuy" },
        Character = { "BunnyHop" },
        Skins = { "SkinChanger" },
    },
    Codes = {
        "1MGROUPMEMBERS", "MYFAULTYALL", "RIANOMINATED2026", "LORE", "DUST_II", "MICHAELSRETURN",
        "FREEDOM", "HAPPYBDAYYUUTO", "GAMEBROKE318", "OHNEPIXEL", "NEBULA", "REACTORDELAY", "BUTTERFLYCASE", "TRADEUPS",
    },
    BoneParts = {
        Head = { "Head" },
        Torso = { "UpperTorso", "Torso", "HumanoidRootPart" },
    },
    BuyStates = { ["Buy Period"] = true, ["Warmup"] = true },
    StickySlack = 1.5,
    HopGap = 0.05,
    HookSettle = 1,
    SkinFile = "BloxStrike/skins.json",
    SkinWears = { "Factory New", "Minimal Wear", "Field-Tested", "Well-Worn", "Battle-Scarred" },
    SkinKinds = { Melee = "Knives", Glove = "Gloves", Grenade = "Grenades", C4 = "Gear", ["Zeus x27"] = "Gear" },
    SkinOrder = { "Pistol", "SMG", "Rifle", "Sniper", "Heavy", "Shotgun", "Machine Gun", "Knives", "Gloves", "Grenades", "Gear" },
    SkinRanks = { Forbidden = 9, Special = 8, Red = 7, Pink = 6, Purple = 5, Blue = 4, LightBlue = 3, Gray = 2, White = 1 },
    SkinMainRows = 5,
    SkinArms = { ["Left Arm"] = true, ["Right Arm"] = true },
    GloveKey = "@Glove",
    FovColors = {
        Aimbot = Color3.fromRGB(232, 160, 76),
        Silent = Color3.fromRGB(110, 170, 255),
    },
    EspFocusColor = Color3.fromRGB(255, 214, 64),
    FovLayer = 50,
}

xDTaraZ.State = {
    Alive = true,
    Connections = {},
    Halted = {},
    Notices = {},
    AimTarget = nil,
    AimPart = nil,
    RageTarget = nil,
    RagePart = nil,
    SilentTarget = nil,
    Firing = false,
    PressedAt = 0,
    LastShot = 0,
    Shots = 0,
    Redirected = 0,
    Bought = {},
    LightSaved = nil,
    FovSaved = nil,
    ViewSaved = nil,
    Hooks = {},
    TriggerWarned = false,
    HopAt = 0,
    HopCrouched = false,
    SpaceHeld = false,
    FovBound = false,
    FovBase = 0,
}

xDTaraZ.Options = {
    Aimbot = false,
    AimbotSmooth = 1,
    AimbotBone = "Head",
    AimbotPriority = "Crosshair",
    AimbotFov = 150,
    AimbotShowFov = false,
    AimbotVisible = true,
    AimbotSticky = true,
    AimbotMaxDistance = 1500,
    SilentAim = false,
    SilentHitChance = 100,
    SilentHeadChance = 100,
    SilentPriority = "Crosshair",
    SilentFov = 220,
    SilentShowFov = false,
    SilentVisible = true,
    SilentMaxDistance = 2000,
    SilentPredict = false,
    Triggerbot = false,
    TriggerDelay = 0,
    TriggerHitChance = 100,
    Ragebot = false,
    RageVisible = true,
    RageMaxDistance = 2000,
    NoRecoil = false,
    NoSpread = false,
    Fullbright = false,
    NoFlash = false,
    NoSmoke = false,
    SoundEsp = false,
    SoundEspLife = 3,
    EspMemory = 5,
    CameraFov = false,
    CameraFovValue = 100,
    InfiniteJump = false,
    BunnyHop = false,
    BunnyCrouch = true,
    SkinChanger = false,
    AutoRebuy = false,
    AntiAfk = false,
}

-- Caps: checks executor capabilities against Library's exposed Compat; replaced
-- with a simpler pcall-based check for the Linoria port.
xDTaraZ.Caps = setmetatable({}, {
    __index = function(_, name)
        if name == "Drawing" then return pcall(function() local _ = Drawing end) and true or false end
        if name == "HookFunction" then return type(hookfunction) == "function" end
        if name == "Gc" then return type(getgc) == "function" end
        if name == "Upvalues" then return type(getupvalues) == "function" end
        return false
    end,
})

xDTaraZ.Util = {}

function xDTaraZ.Util.HttpGet(url)
    local ok, body = pcall(game.HttpGet, game, url)
    if ok and type(body) == "string" then return body end
    local req = request or http_request or (syn and syn.request)
    if not req then error("no http") end

    local sent, response = pcall(req, { Url = url, Method = "GET" })
    if not sent then error(response) end
    local status = type(response) == "table" and tonumber(response.StatusCode)
    if status ~= 200 or type(response.Body) ~= "string" then error("http status " .. tostring(status)) end
    return response.Body
end

---@param detail any  extra context for the warn; the player only sees `text`
function xDTaraZ.Util.Alert(text, detail)
    warn("[BloxStrike] menu:", detail or text)
    task.spawn(function()
        for _ = 1, xDTaraZ.Config.AlertTries do
            if pcall(StarterGui.SetCore, StarterGui, "SendNotification", { Title = "Mario Hub", Text = text, Duration = 10 }) then return end
            task.wait(xDTaraZ.Config.AlertGap)
        end
    end)
end

function xDTaraZ.Util.Try(label, fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok then warn("[BloxStrike] " .. label .. ":", err) end
    return ok
end

function xDTaraZ.Util.Copy(text)
    local fn = setclipboard or toclipboard
    if not fn then return false end
    return pcall(fn, text)
end

---@return function?  original, nil when already hooked or the executor can't hook it
function xDTaraZ.Util.Hook(key, fn, replacement)
    if type(fn) ~= "function" or xDTaraZ.State.Hooks[key] or not xDTaraZ.Caps.HookFunction then return nil end
    local ok, original = pcall(hookfunction, fn, replacement)
    if not ok or type(original) ~= "function" then
        warn("[BloxStrike] hook " .. key .. ":", ok and "executor returned no original" or original)
        return nil
    end
    xDTaraZ.State.Hooks[key] = { Fn = fn, Original = original }
    return original
end

function xDTaraZ.Util.UnhookAll()
    for key, hook in pairs(xDTaraZ.State.Hooks) do
        local ok, err = pcall(function()
            hookfunction(hook.Fn, hook.Original)
        end)
        if not ok then warn("[BloxStrike] unhook " .. key .. ":", err) end
    end
    table.clear(xDTaraZ.State.Hooks)
end

function xDTaraZ.Util.Decode(raw)
    if type(raw) ~= "string" then return nil end
    local ok, decoded = pcall(HttpService.JSONDecode, HttpService, raw)
    return ok and decoded or nil
end

function xDTaraZ:Connect(signal, handler)
    local conn = signal:Connect(handler)
    table.insert(self.State.Connections, conn)
    return conn
end

xDTaraZ.GameLib = { Missing = {} }

---@param parent Instance?     where it lives today
---@param home string          parent name a moved copy must still have
---@return Instance?           nil after a warning that names it
function xDTaraZ.GameLib.Find(parent, name, class, home)
    local found = parent and parent:FindFirstChild(name)
    if found and found:IsA(class) then return found end
    for _, desc in ipairs(ReplicatedStorage:GetDescendants()) do
        if desc.Name == name and desc:IsA(class) and desc.Parent and desc.Parent.Name == home then return desc end
    end
    xDTaraZ.GameLib.Missing[name] = "Absent"
    warn("[BloxStrike] " .. home .. "." .. name .. " not found, features that need it are blocked")
    return nil
end

---@return any  module, or nil when this executor can't require it (never throws)
function xDTaraZ.GameLib.Require(inst)
    if not (inst and inst:IsA("ModuleScript")) then return nil end
    local ok, mod = pcall(require, inst)
    if ok then return mod end

    local done, okAgain, again = false, false, nil
    task.spawn(function()
        pcall(setthreadidentity, 2)
        local read, identity = pcall(getthreadidentity)
        if read and identity == 2 then okAgain, again = pcall(require, inst) end
        done = true
    end)
    local deadline = osClock() + xDTaraZ.Config.RequireTimeout
    while not done and osClock() < deadline do task.wait() end
    if okAgain then return again end
    warn("[BloxStrike] require " .. inst.Name .. ":", mod)
    return nil
end

do
    local database = ReplicatedStorage:FindFirstChild("Database")
    local security = database and database:FindFirstChild("Security")
    local custom = database and database:FindFirstChild("Custom")
    local controllers = ReplicatedStorage:FindFirstChild("Controllers")
    local find = xDTaraZ.GameLib.Find
    xDTaraZ.GameLib.Net = xDTaraZ.GameLib.Require(find(security, "Remotes", "ModuleScript", "Security"))
    xDTaraZ.GameLib.Character = xDTaraZ.GameLib.Require(find(controllers, "CharacterController", "ModuleScript", "Controllers"))
    xDTaraZ.GameLib.Camera = xDTaraZ.GameLib.Require(find(controllers, "CameraController", "ModuleScript", "Controllers"))
    xDTaraZ.GameLib.WeaponFolder = find(custom, "Weapons", "Folder", "Custom")
    xDTaraZ.GameLib.Rarities = xDTaraZ.GameLib.Require(find(custom, "Rarities", "ModuleScript", "GameStats"))
    local vfx = ReplicatedStorage:FindFirstChild("Components") and ReplicatedStorage.Components:FindFirstChild("VFXLibary", true)
    xDTaraZ.GameLib.Smoke = xDTaraZ.GameLib.Require(find(vfx, "CreateVoxelSmoke", "ModuleScript", "VFXLibary"))
    xDTaraZ.GameLib.Flash = xDTaraZ.GameLib.Require(find(vfx, "FlashEffect", "ModuleScript", "VFXLibary"))
end

xDTaraZ.Weapons = {}
do
    local folder = xDTaraZ.GameLib.WeaponFolder
    for _, module in ipairs(folder and folder:GetChildren() or {}) do
        local data = module:IsA("ModuleScript") and xDTaraZ.GameLib.Require(module)
        if type(data) == "table" and data.FireRate then xDTaraZ.Weapons[module.Name] = data end
    end
end

xDTaraZ.Player = {}

function xDTaraZ.Player.Character()
    local chars = Workspace:FindFirstChild("Characters")
    return (chars and chars:FindFirstChild(LocalPlayer.Name)) or LocalPlayer.Character
end

function xDTaraZ.Player.Alive()
    local char = xDTaraZ.Player.Character()
    return char ~= nil and char.Parent ~= nil and tostring(LocalPlayer:GetAttribute("Dead")) ~= "true"
end

function xDTaraZ.Player.Humanoid()
    local char = xDTaraZ.Player.Character()
    return char and char:FindFirstChildOfClass("Humanoid")
end

---@return table?  the game's own local character state; nil outside a round
function xDTaraZ.Player.Body()
    local controller = xDTaraZ.GameLib.Character
    if not controller then return nil end
    local ok, body = pcall(controller.getCurrentCharacter)
    return ok and body or nil
end

function xDTaraZ.Player.Equipped()
    return xDTaraZ.Util.Decode(LocalPlayer:GetAttribute("CurrentEquipped"))
end

xDTaraZ.Target = { Motion = setmetatable({}, { __mode = "k" }) }

local losParams = RaycastParams.new()
losParams.FilterType = Enum.RaycastFilterType.Exclude
local losFilter = table.create(3)
local wallParams = RaycastParams.new()
wallParams.FilterType = Enum.RaycastFilterType.Exclude

function xDTaraZ.Target.Candidates()
    local list = {}
    local chars = Workspace:FindFirstChild("Characters")
    if not chars then return list end
    for _, model in ipairs(chars:GetChildren()) do
        if model.Name ~= LocalPlayer.Name and model:IsA("Model") then list[#list + 1] = model end
    end
    return list
end

function xDTaraZ.Target.Owner(model)
    return Players:FindFirstChild(model.Name)
end

---@return string?  team of a character: owner's Team attribute, else the team that wears this character model
function xDTaraZ.Target.TeamOf(model)
    local owner = model and xDTaraZ.Target.Owner(model)
    local team = owner and owner:GetAttribute("Team")
    if team then return team end
    local look = model and model:GetAttribute("CharacterName")
    if not look then return nil end
    if look == Workspace:GetAttribute("CTCharacter") then return "Counter-Terrorists" end
    if look == Workspace:GetAttribute("TCharacter") then return "Terrorists" end
    return nil
end

function xDTaraZ.Target.MyTeam()
    return LocalPlayer:GetAttribute("Team") or xDTaraZ.Target.TeamOf(xDTaraZ.Player.Character())
end

function xDTaraZ.Target.IsEnemy(model)
    if tostring(model:GetAttribute("Dead")) == "true" then return false end
    if not xDTaraZ.Target.Owner(model) and model:GetAttribute("Health") == nil then return false end
    if xDTaraZ.Target.FreeForAll() then return true end
    local mine = xDTaraZ.Target.MyTeam()
    if mine == nil then return false end
    return xDTaraZ.Target.TeamOf(model) ~= mine
end

---Samples every enemy's head each frame so shots can lead a moving target.
function xDTaraZ.Target.Track()
    local motion, now = xDTaraZ.Target.Motion, osClock()
    for _, model in ipairs(xDTaraZ.Target.Candidates()) do
        local head = model:FindFirstChild("Head")
        if not head then continue end
        local last = motion[head]
        if last and now > last.Time then
            local step = (head.Position - last.Pos) / (now - last.Time)
            last.Vel = last.Vel and last.Vel:Lerp(step, 0.5) or step
            last.Pos, last.Time = head.Position, now
        else
            motion[head] = { Pos = head.Position, Time = now, Vel = Vector3.zero }
        end
    end
end

---@return Vector3  where the part will be once the shot reaches the server
function xDTaraZ.Target.Lead(part)
    if not xDTaraZ.Options.SilentPredict then return part.Position end
    local track = xDTaraZ.Target.Motion[part] or xDTaraZ.Target.Motion[part.Parent and part.Parent:FindFirstChild("Head")]
    local vel = track and track.Vel or Vector3.zero
    if vel.Magnitude > xDTaraZ.Config.LeadMaxSpeed then return part.Position end
    local ok, ping = pcall(LocalPlayer.GetNetworkPing, LocalPlayer)
    return part.Position + vel * ((ok and ping or 0.05) + xDTaraZ.Config.LeadExtra)
end

---@return boolean  true in Deathmatch, where the team picker is only cosmetic
function xDTaraZ.Target.FreeForAll()
    return tostring(Workspace:GetAttribute("Gamemode")):find("Deathmatch") ~= nil
end

function xDTaraZ.Target.Part(model, bone)
    for _, name in ipairs(xDTaraZ.Config.BoneParts[bone] or xDTaraZ.Config.BoneParts.Head) do
        local part = model:FindFirstChild(name)
        if part and part:IsA("BasePart") then return part end
    end
    return model:FindFirstChild("HumanoidRootPart")
end

function xDTaraZ.Target.Visible(from, model, point)
    local skip = { Workspace.CurrentCamera, model }
    for _, name in ipairs(xDTaraZ.Config.SeeThrough) do
        local folder = Workspace:FindFirstChild(name)
        if folder then skip[#skip + 1] = folder end
    end
    wallParams.FilterDescendantsInstances = skip
    return Workspace:Raycast(from, point - from, wallParams) == nil
end

---@param cfg table  { Bone, Fov?, Visible, MaxDistance, Priority }  Fov nil = whole map
---@return Model?, BasePart?
function xDTaraZ.Target.Pick(cfg)
    local cam = Workspace.CurrentCamera
    local origin = cam.CFrame.Position
    local center = cam.ViewportSize / 2
    local best, bestPart, bestScore

    for _, model in ipairs(xDTaraZ.Target.Candidates()) do
        if not xDTaraZ.Target.IsEnemy(model) then continue end
        local part = xDTaraZ.Target.Part(model, cfg.Bone)
        if not part then continue end
        local dist = (part.Position - origin).Magnitude
        if dist > cfg.MaxDistance then continue end

        local screen, onScreen = cam:WorldToViewportPoint(part.Position)
        local screenDist = (vector2New(screen.X, screen.Y) - center).Magnitude
        if cfg.Fov and (not onScreen or screenDist > cfg.Fov) then continue end
        if cfg.Visible and not xDTaraZ.Target.Visible(origin, model, part.Position) then continue end

        local score = dist
        if cfg.Priority == "Crosshair" then
            score = onScreen and screenDist or 1e6 + dist
        elseif cfg.Priority == "Health" then
            score = (tonumber(model:GetAttribute("Health")) or 100) * 1e4 + dist
        end
        if not bestScore or score < bestScore then best, bestPart, bestScore = model, part, score end
    end
    return best, bestPart
end

---@return boolean  still a valid lock, with a looser fov
function xDTaraZ.Target.StillValid(model, part, cfg)
    if not (model and part and part.Parent and xDTaraZ.Target.IsEnemy(model)) then return false end
    local cam = Workspace.CurrentCamera
    local origin = cam.CFrame.Position
    if (part.Position - origin).Magnitude > cfg.MaxDistance then return false end
    if cfg.Visible and not xDTaraZ.Target.Visible(origin, model, part.Position) then return false end
    if not cfg.Fov then return true end
    local screen, onScreen = cam:WorldToViewportPoint(part.Position)
    local center = cam.ViewportSize / 2
    return onScreen and (vector2New(screen.X, screen.Y) - center).Magnitude <= cfg.Fov * xDTaraZ.Config.StickySlack
end

---@return Model?  enemy under the crosshair right now
function xDTaraZ.Target.UnderCrosshair()
    local cam = Workspace.CurrentCamera
    losFilter[1], losFilter[2], losFilter[3] = xDTaraZ.Player.Character(), cam, nil
    losParams.FilterDescendantsInstances = losFilter
    local hit = Workspace:Raycast(cam.CFrame.Position, cam.CFrame.LookVector * xDTaraZ.Config.TriggerRay, losParams)
    if not hit then return nil end
    local chars = Workspace:FindFirstChild("Characters")
    local model = hit.Instance
    while model and model.Parent ~= chars do model = model.Parent end
    if model and model:IsA("Model") and xDTaraZ.Target.IsEnemy(model) then return model end
    return nil
end

local function roll(percent)
    return percent >= 100 or math.random() * 100 < percent
end

xDTaraZ.Aimbot = {}

function xDTaraZ.Aimbot.Config()
    local o = xDTaraZ.Options
    return { Bone = o.AimbotBone, Fov = o.AimbotFov, Visible = o.AimbotVisible, MaxDistance = o.AimbotMaxDistance, Priority = o.AimbotPriority }
end

function xDTaraZ.Aimbot.Step()
    local state, o = xDTaraZ.State, xDTaraZ.Options
    if not o.Aimbot then state.AimTarget, state.AimPart = nil, nil return end
    local cfg = xDTaraZ.Aimbot.Config()
    if o.AimbotSticky and xDTaraZ.Target.StillValid(state.AimTarget, state.AimPart, cfg) then return end
    state.AimTarget, state.AimPart = xDTaraZ.Target.Pick(cfg)
end

---@param dt number  frame time from RenderStep
function xDTaraZ.Aimbot.Lock(dt)
    local o, state = xDTaraZ.Options, xDTaraZ.State
    local part, smooth = nil, 1
    if o.Ragebot and state.RagePart and state.RagePart.Parent then
        part = state.RagePart
    elseif o.Aimbot and state.AimPart and state.AimPart.Parent then
        part, smooth = state.AimPart, math.max(o.AimbotSmooth, 1)
    end
    if not part then return end
    local cam = Workspace.CurrentCamera
    local origin = cam.CFrame.Position
    local want = (part.Position - origin).Unit
    local alpha = 1 - (1 - 1 / smooth) ^ ((dt or 1 / 60) * 60)
    local look = smooth <= 1 and want or cam.CFrame.LookVector:Lerp(want, alpha).Unit
    cam.CFrame = cframeLookAt(origin, origin + look)
end

xDTaraZ.Silent = {}

---@param forced boolean  ragebot shot: always hits, no fov
function xDTaraZ.Silent.Config(bone, forced)
    local o = xDTaraZ.Options
    if forced then return { Bone = bone, Visible = o.RageVisible, MaxDistance = o.RageMaxDistance, Priority = "Distance" } end
    return { Bone = bone, Fov = o.SilentFov, Visible = o.SilentVisible, MaxDistance = o.SilentMaxDistance, Priority = o.SilentPriority }
end

---@return BasePart?  part this shot should go to, nil = shoot where you look
function xDTaraZ.Silent.Aim()
    local o, state = xDTaraZ.Options, xDTaraZ.State
    state.SilentTarget = nil
    if not (o.SilentAim or o.Ragebot) then return nil end
    local forced = o.Ragebot
    if not forced and not roll(o.SilentHitChance) then return nil end
    local bone = (forced or roll(o.SilentHeadChance)) and "Head" or "Torso"
    local target, part = xDTaraZ.Target.Pick(xDTaraZ.Silent.Config(bone, forced))
    state.SilentTarget = target
    return part
end

function xDTaraZ.Silent.InstallHook()
    local gun = xDTaraZ.Guns.FindClass()
    if gun then
        local original
        original = xDTaraZ.Util.Hook("Shoot", gun.shoot, function(...)
            local state = xDTaraZ.State
            state.LastShot = osClock()
            state.Shots += 1
            return original(...)
        end)
    end
    local bullet = xDTaraZ.Guns.FindBullet()
    if bullet and type(bullet.create) == "function" then
        local create
        create = xDTaraZ.Util.Hook("Bullet", bullet.create, function(...)
            xDTaraZ.Silent.Flick()
            return create(...)
        end)
    end
    xDTaraZ.Guns.HookSpread()

    local net = xDTaraZ.GameLib.Net
    local packet = net and net.Inventory and net.Inventory.ShootWeapon
    if not packet then return end
    local send
    send = xDTaraZ.Util.Hook("Send", packet.Send, function(...)
        xDTaraZ.Silent.RestoreView()
        return send(...)
    end)
end

function xDTaraZ.Silent.Flick()
    local ok, part = pcall(xDTaraZ.Silent.Aim)
    local cam, state = Workspace.CurrentCamera, xDTaraZ.State
    if not (ok and part and cam) then return end
    state.ViewSaved = state.ViewSaved or cam.CFrame
    cam.CFrame = cframeLookAt(cam.CFrame.Position, xDTaraZ.Target.Lead(part))
    state.Redirected += 1
end

function xDTaraZ.Silent.RestoreView()
    local state, cam = xDTaraZ.State, Workspace.CurrentCamera
    if not state.ViewSaved then return end
    if cam then cam.CFrame = state.ViewSaved end
    state.ViewSaved = nil
end

xDTaraZ.Trigger = {}

function xDTaraZ.Trigger.Press(down)
    -- Use Library.Toggled to guard triggerbot when the UI is open
    if down and Library and Library.Toggled then return end
    xDTaraZ.State.Firing = down
    if down then xDTaraZ.State.PressedAt = osClock() end
    local center = Workspace.CurrentCamera.ViewportSize / 2
    pcall(VirtualInputManager.SendMouseButtonEvent, VirtualInputManager, center.X, center.Y, 0, down, game, 0)
end

---@param want boolean  holds auto guns and re-clicks semi-auto ones
function xDTaraZ.Trigger.Fire(want)
    local state, now = xDTaraZ.State, osClock()
    if not want then
        if state.Firing then xDTaraZ.Trigger.Press(false) end
        return
    end
    if not state.Firing then
        xDTaraZ.Trigger.Press(true)
        return
    end
    local gap = xDTaraZ.Config.RefireGap
    if now - state.PressedAt > gap and now - state.LastShot > gap then xDTaraZ.Trigger.Press(false) end
end

function xDTaraZ.Trigger.Wanted()
    local o, state = xDTaraZ.Options, xDTaraZ.State
    if not o.Triggerbot then return false end
    local model = xDTaraZ.Target.UnderCrosshair()
    if model ~= state.TriggerModel then
        state.TriggerModel = model
        state.TriggerSeen = model and osClock() or nil
        state.TriggerRoll = model ~= nil and roll(o.TriggerHitChance)
    end
    if not model or not state.TriggerRoll then return false end
    return osClock() - state.TriggerSeen >= o.TriggerDelay / 1000
end

xDTaraZ.Rage = {}

function xDTaraZ.Rage.Step()
    local state = xDTaraZ.State
    if not xDTaraZ.Options.Ragebot then state.RageTarget, state.RagePart = nil, nil return false end
    state.RageTarget, state.RagePart = xDTaraZ.Target.Pick(xDTaraZ.Silent.Config("Head", true))
    return state.RageTarget ~= nil
end

xDTaraZ.Combat = { Circles = {} }

---@return ScreenGui  made once; hidden gui first, then CoreGui, then PlayerGui
function xDTaraZ.Combat.Screen()
    local screen = xDTaraZ.Combat.Gui
    if screen and screen.Parent then return screen end

    screen = Instance.new("ScreenGui")
    screen.Name = "MarioHubFov"
    screen.IgnoreGuiInset = true
    screen.ResetOnSpawn = false
    screen.DisplayOrder = xDTaraZ.Config.FovLayer

    local function Mount(parent) screen.Parent = parent end
    local okHui, hui = pcall(gethui)
    local mounted = okHui and hui ~= nil and pcall(Mount, hui)
    if not mounted then mounted = pcall(Mount, game:GetService("CoreGui")) end
    if not mounted then Mount(LocalPlayer:FindFirstChildOfClass("PlayerGui")) end

    xDTaraZ.Combat.Gui = screen
    return screen
end

function xDTaraZ.Combat.NewCircle(color)
    if xDTaraZ.Caps.Drawing then
        local circle = Drawing.new("Circle")
        circle.Thickness, circle.NumSides, circle.Filled, circle.Color = 1.5, 64, false, color
        return { Drawing = circle }
    end
    local frame = Instance.new("Frame")
    frame.AnchorPoint = vector2New(0.5, 0.5)
    frame.BackgroundTransparency = 1
    local round = Instance.new("UICorner")
    round.CornerRadius = UDim.new(1, 0)
    round.Parent = frame
    local edge = Instance.new("UIStroke")
    edge.Thickness, edge.Color = 1.5, color
    edge.Parent = frame
    frame.Parent = xDTaraZ.Combat.Screen()
    return { Frame = frame }
end

function xDTaraZ.Combat.Circle(key, show, radius)
    local circle = xDTaraZ.Combat.Circles[key]
    if not circle then
        if not show then return end
        circle = xDTaraZ.Combat.NewCircle(xDTaraZ.Config.FovColors[key])
        xDTaraZ.Combat.Circles[key] = circle
    end
    local center = Workspace.CurrentCamera.ViewportSize / 2
    local drawing, frame = circle.Drawing, circle.Frame
    if drawing then
        drawing.Visible, drawing.Position, drawing.Radius = show, center, radius
        return
    end
    frame.Visible = show
    frame.Position = UDim2.fromOffset(center.X, center.Y)
    frame.Size = UDim2.fromOffset(radius * 2, radius * 2)
end

function xDTaraZ.Combat.Step()
    local o, state = xDTaraZ.Options, xDTaraZ.State
    xDTaraZ.Combat.Circle("Aimbot", o.AimbotShowFov, o.AimbotFov)
    xDTaraZ.Combat.Circle("Silent", o.SilentShowFov, o.SilentFov)
    if not xDTaraZ.Player.Alive() then
        state.AimTarget, state.AimPart, state.RageTarget, state.RagePart, state.SilentTarget = nil, nil, nil, nil, nil
        xDTaraZ.Trigger.Fire(false)
        return
    end
    if o.SilentAim or o.Ragebot then xDTaraZ.Target.Track() end
    xDTaraZ.Aimbot.Step()
    local rage = xDTaraZ.Rage.Step()
    xDTaraZ.Trigger.Fire(rage or xDTaraZ.Trigger.Wanted())
end

function xDTaraZ.Combat.Rest()
    local state = xDTaraZ.State
    state.AimTarget, state.AimPart, state.RageTarget, state.RagePart, state.SilentTarget = nil, nil, nil, nil, nil
    xDTaraZ.Trigger.Fire(false)
    for key in pairs(xDTaraZ.Combat.Circles) do
        xDTaraZ.Combat.Circle(key, false, 0)
    end
end

function xDTaraZ.Combat.Start()
    RunService:BindToRenderStep("xDTaraZView", Enum.RenderPriority.First.Value, xDTaraZ.Silent.RestoreView)
    RunService:BindToRenderStep("xDTaraZAim", xDTaraZ.Config.AimRenderPriority, xDTaraZ.Aimbot.Lock)
    xDTaraZ:Connect(RunService.Heartbeat, function()
        local ok, err = pcall(xDTaraZ.Combat.Step)
        if ok then
            xDTaraZ.Faults.Clear("Combat")
        else
            xDTaraZ.Faults.Report("Combat", err, xDTaraZ.Config.CombatToggles, xDTaraZ.Combat.Rest)
        end
    end)
end

function xDTaraZ.Combat.Unload()
    xDTaraZ.Trigger.Fire(false)
    pcall(RunService.UnbindFromRenderStep, RunService, "xDTaraZAim")
    pcall(RunService.UnbindFromRenderStep, RunService, "xDTaraZView")
    for key, circle in pairs(xDTaraZ.Combat.Circles) do
        xDTaraZ.Combat.Circles[key] = nil
        if circle.Frame then
            circle.Frame:Destroy()
        else
            pcall(function() circle.Drawing:Remove() end)
        end
    end
    if xDTaraZ.Combat.Gui then
        xDTaraZ.Combat.Gui:Destroy()
        xDTaraZ.Combat.Gui = nil
    end
end

xDTaraZ.Guns = { Signature = nil, Warned = false }

function xDTaraZ.Guns.HookKick()
    local cam = xDTaraZ.GameLib.Camera
    if not cam then return end
    local kick, aim, rotation
    kick = xDTaraZ.Util.Hook("Kick", cam.weaponKick, function(...)
        if xDTaraZ.Options.NoRecoil then return end
        return kick(...)
    end)
    aim = xDTaraZ.Util.Hook("Recoil", cam.setWeaponRecoil, function(...)
        if xDTaraZ.Options.NoRecoil then return end
        return aim(...)
    end)
    rotation = xDTaraZ.Util.Hook("KickRotation", cam.getWeaponKickRotation, function(...)
        if xDTaraZ.Options.NoRecoil then return Vector3.zero end
        return rotation(...)
    end)
end

---@return boolean  true while any scope or zoom is up
function xDTaraZ.Guns.Scoped()
    if LocalPlayer:GetAttribute("IsSniperScoped") == true then return true end
    local cam = xDTaraZ.GameLib.Camera
    local getter = cam and cam.getTargetFOV
    if type(getter) ~= "function" then return false end
    local ok, target = pcall(getter)
    if not ok or type(target) ~= "number" then return false end

    local state = xDTaraZ.State
    if target > state.FovBase then state.FovBase = target end
    return target < state.FovBase
end

function xDTaraZ.Guns.StepFov()
    local camera, state = Workspace.CurrentCamera, xDTaraZ.State
    if not camera then return end
    if not xDTaraZ.Options.CameraFov then
        if state.FovSaved then camera.FieldOfView, state.FovSaved = state.FovSaved, nil end
        state.FovBase = 0
        return
    end
    if xDTaraZ.Guns.Scoped() then return end
    state.FovSaved = state.FovSaved or camera.FieldOfView
    camera.FieldOfView = xDTaraZ.Options.CameraFovValue
end

function xDTaraZ.Guns.BindFov()
    local state = xDTaraZ.State
    if state.FovBound then return end
    state.FovBound = true
    RunService:BindToRenderStep("xDTaraZFov", Enum.RenderPriority.Camera.Value + 3, xDTaraZ.Guns.StepFov)
end

function xDTaraZ.Guns.UnbindFov()
    local state, camera = xDTaraZ.State, Workspace.CurrentCamera
    if state.FovSaved and camera then camera.FieldOfView, state.FovSaved = state.FovSaved, nil end
    state.FovBound = false
    pcall(RunService.UnbindFromRenderStep, RunService, "xDTaraZFov")
end

function xDTaraZ.Guns.FindClass()
    if not xDTaraZ.Caps.Gc or not xDTaraZ.Caps.HookFunction then return nil end
    for _, entry in ipairs(getgc(true)) do
        if type(entry) == "table" and rawget(entry, "getSpread") and rawget(entry, "shoot") and rawget(entry, "setupRecoil") then return entry end
    end
    return nil
end

---@return table?  the bullet class that rolls spread for every shot
function xDTaraZ.Guns.FindBullet()
    if not xDTaraZ.Caps.Gc or not xDTaraZ.Caps.HookFunction then return nil end
    for _, entry in ipairs(getgc(true)) do
        if type(entry) == "table" and rawget(entry, "getTrueSpread") and rawget(entry, "getSpreadForConfig") then return entry end
    end
    return nil
end

function xDTaraZ.Guns.HookSpread()
    local bullet = xDTaraZ.Guns.FindBullet()
    if not bullet then return end
    for _, method in ipairs(xDTaraZ.Config.SpreadMethods) do
        if type(bullet[method]) ~= "function" then continue end
        local original
        original = xDTaraZ.Util.Hook("Spread:" .. method, bullet[method], function(...)
            local value = original(...)
            if type(value) == "number" and (xDTaraZ.Options.NoSpread or xDTaraZ.State.ViewSaved) then return 0 end
            return value
        end)
    end
end

xDTaraZ.Esp = { Count = 0, Decoded = {}, CacheSize = 0, Ghosts = {}, Folder = nil }

---@return table?  JSON attribute decoded once per distinct raw string
function xDTaraZ.Esp.Attr(owner, key)
    local raw = owner:GetAttribute(key)
    if type(raw) ~= "string" then return nil end
    local esp = xDTaraZ.Esp
    if esp.Decoded[raw] == nil then
        esp.CacheSize += 1
        if esp.CacheSize > xDTaraZ.Config.EspCacheMax then table.clear(esp.Decoded) esp.CacheSize = 1 end
        esp.Decoded[raw] = xDTaraZ.Util.Decode(raw) or false
    end
    return esp.Decoded[raw] or nil
end

---@return string  " C4 Kit Helmet Scoped" style tags, "" when none
function xDTaraZ.Esp.Flags(owner)
    if not owner then return "" end
    local flags = {}
    local armor = xDTaraZ.Esp.Attr(owner, "Armor")
    local bomb = xDTaraZ.Esp.Attr(owner, "Slot5")
    if bomb and bomb.Weapon == "C4" then flags[#flags + 1] = "C4" end
    if owner:GetAttribute("HasDefuseKit") == true then table.insert(flags, "Kit") end
    if armor and type(armor.Type) == "string" and armor.Type:find("Helmet") then flags[#flags + 1] = "Helmet" end
    if owner:GetAttribute("IsSniperScoped") == true then flags[#flags + 1] = "Scoped" end
    return #flags > 0 and " " .. table.concat(flags, " ") or ""
end

---@return Model?  whatever aimbot, silent aim or ragebot is locked on
function xDTaraZ.Esp.Focus()
    local state = xDTaraZ.State
    local silent = osClock() - state.LastShot < xDTaraZ.Config.SilentFocusTime and state.SilentTarget or nil
    return state.AimTarget or silent or state.RageTarget
end

function xDTaraZ.Esp.Ghost(name)
    local esp = xDTaraZ.Esp
    local ghost = esp.Ghosts[name]
    if ghost and ghost.Model.Parent then return ghost end
    if not (esp.Folder and esp.Folder.Parent) then
        esp.Folder = Instance.new("Folder")
        esp.Folder.Name = "xDTaraZGhosts"
        esp.Folder.Parent = Workspace.CurrentCamera
    end
    local model = Instance.new("Model")
    model.Name = name
    local root = Instance.new("Part")
    root.Name, root.Size, root.Transparency = "HumanoidRootPart", Vector3.new(2, 2, 1), 1
    root.Anchored, root.CanCollide, root.CanQuery, root.CanTouch = true, false, false, false
    root.Parent = model
    model.PrimaryPart = root
    model.Parent = esp.Folder
    ghost = { Model = model, Root = root, Seen = 0, Heard = 0 }
    esp.Ghosts[name] = ghost
    return ghost
end

function xDTaraZ.Esp.Row(ghost, model, owner, mine, focus)
    local equipped = owner and xDTaraZ.Esp.Attr(owner, "CurrentEquipped")
    local label = owner and owner.DisplayName or ghost.Model.Name
    if equipped and equipped.Name then label = label .. " [" .. equipped.Name .. "]" end
    local live = model and model:FindFirstChild("HumanoidRootPart")
    if not live then label = label .. " ?" end
    return {
        Model = ghost.Model,
        Root = live or ghost.Root,
        Adornee = model or false,
        Name = label .. xDTaraZ.Esp.Flags(owner),
        Health = tonumber(owner and owner:GetAttribute("Health")) or tonumber(model and model:GetAttribute("Health")) or 100,
        MaxHealth = tonumber(model and model:GetAttribute("MaxHealth")) or 100,
        Friendly = ghost.Friendly,
        Color = model ~= nil and model == focus and xDTaraZ.Config.EspFocusColor or nil,
    }
end

function xDTaraZ.Esp.Targets()
    local esp, now = xDTaraZ.Esp, osClock()
    local list = {}
    local mine = xDTaraZ.Target.MyTeam()
    local ffa = xDTaraZ.Target.FreeForAll()
    local focus = xDTaraZ.Esp.Focus()
    pcall(xDTaraZ.Sound.Install)
    local live = {}
    for _, model in ipairs(xDTaraZ.Target.Candidates()) do
        if xDTaraZ.Esp.IsDead(model, xDTaraZ.Target.Owner(model)) then
            xDTaraZ.Esp.Forget(model.Name)
            continue
        end
        local hrp = model:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end
        local ghost = esp.Ghost(model.Name)
        ghost.Root.CFrame, ghost.Seen = hrp.CFrame, now
        ghost.Friendly = not ffa and mine ~= nil and xDTaraZ.Target.TeamOf(model) == mine
        live[model.Name] = true
        list[#list + 1] = esp.Row(ghost, model, xDTaraZ.Target.Owner(model), mine, focus)
    end
    local memory = xDTaraZ.Options.EspMemory
    for name, ghost in pairs(esp.Ghosts) do
        if live[name] then continue end
        local owner = Players:FindFirstChild(name)
        if owner and xDTaraZ.Esp.IsDead(nil, owner) then
            xDTaraZ.Esp.Forget(name)
            continue
        end
        local gone = not ghost.Model.Parent or (not owner and now - ghost.Seen > memory)
        if gone or now - math.max(ghost.Seen, ghost.Heard) > memory then
            if gone and not owner then
                ghost.Model:Destroy()
                esp.Ghosts[name] = nil
            end
            continue
        end
        list[#list + 1] = esp.Row(ghost, nil, owner, mine, focus)
    end
    esp.Count = #list
    return list
end

function xDTaraZ.Esp.IsDead(model, owner)
    if model and (tostring(model:GetAttribute("Dead")) == "true" or (tonumber(model:GetAttribute("Health")) or 1) <= 0) then return true end
    if owner and (owner:GetAttribute("Dead") == true or (tonumber(owner:GetAttribute("Health")) or 1) <= 0) then return true end
    return false
end

function xDTaraZ.Esp.Forget(name)
    local ghost = xDTaraZ.Esp.Ghosts[name]
    if ghost then ghost.Seen, ghost.Heard = 0, 0 end
end

function xDTaraZ.Esp.Hear(pos, weapon)
    local esp, now = xDTaraZ.Esp, osClock()
    local best, bestDist = nil, xDTaraZ.Config.GhostSnap
    for name, ghost in pairs(esp.Ghosts) do
        if ghost.Friendly or now - ghost.Seen < 0.3 then continue end
        local owner = Players:FindFirstChild(name)
        local equipped = owner and xDTaraZ.Esp.Attr(owner, "CurrentEquipped")
        if weapon and equipped and equipped.Name and equipped.Name ~= weapon then continue end
        local dist = (ghost.Root.Position - pos).Magnitude
        if dist < bestDist then best, bestDist = ghost, dist end
    end
    if not best then return end
    best.Root.CFrame = CFrame.new(pos + Vector3.new(0, 2.5, 0))
    best.Heard = now
end

xDTaraZ.Sound = { Marks = {}, Entry = nil, Original = nil, Folder = nil }

function xDTaraZ.Sound.Install()
    local sound = xDTaraZ.Sound
    if sound.Entry then return true end
    local net = xDTaraZ.GameLib.Net
    local packet = net and net.Sound and net.Sound.ReplicateSound
    if not (packet and xDTaraZ.Caps.Upvalues) then return false end
    local ok, listeners = pcall(function() return getupvalues(packet.Listen)[1] end)
    if not ok or type(listeners) ~= "table" then return false end
    for _, entry in ipairs(listeners) do
        if type(entry) == "table" and type(entry.callback) == "function" then
            sound.Entry, sound.Original = entry, entry.callback
            entry.callback = function(info, ...)
                xDTaraZ.Util.Try("sound esp", xDTaraZ.Sound.Heard, info)
                return sound.Original(info, ...)
            end
            return true
        end
    end
    return false
end

function xDTaraZ.Sound.Uninstall()
    local sound = xDTaraZ.Sound
    if sound.Entry then sound.Entry.callback = sound.Original end
    sound.Entry, sound.Original = nil, nil
    for _, mark in ipairs(sound.Marks) do mark.Gui:Destroy() end
    table.clear(sound.Marks)
end

function xDTaraZ.Sound.Friendly(pos)
    local range = xDTaraZ.Config.SoundSelfRange
    local me = xDTaraZ.Player.Character()
    if me and (me:GetPivot().Position - pos).Magnitude < range then return true end
    if xDTaraZ.Target.FreeForAll() then return false end
    for _, model in ipairs(xDTaraZ.Target.Candidates()) do
        if not xDTaraZ.Target.IsEnemy(model) and (model:GetPivot().Position - pos).Magnitude < range then return true end
    end
    return false
end

function xDTaraZ.Sound.Heard(info)
    if type(info) ~= "table" or typeof(info.Position) ~= "Vector3" then return end
    local floor = info.Class == "FloorSounds"
    if not floor and info.Name ~= "Shoot" then return end
    if xDTaraZ.Sound.Friendly(info.Position) then return end
    xDTaraZ.Esp.Hear(info.Position, not floor and tostring(info.Class) or nil)
    if xDTaraZ.Options.SoundEsp then xDTaraZ.Sound.Mark(info.Position, floor and "Steps" or tostring(info.Class)) end
end

function xDTaraZ.Sound.Mark(pos, label)
    local sound = xDTaraZ.Sound
    if not (sound.Folder and sound.Folder.Parent) then
        sound.Folder = Instance.new("Folder")
        sound.Folder.Name = "xDTaraZSounds"
        sound.Folder.Parent = Workspace.Terrain
    end
    if #sound.Marks >= xDTaraZ.Config.SoundMaxMarks then
        table.remove(sound.Marks, 1).Gui:Destroy()
    end
    local holder = Instance.new("Attachment")
    holder.WorldPosition = pos
    local gui = Instance.new("BillboardGui")
    gui.AlwaysOnTop, gui.Size, gui.LightInfluence = true, UDim2.fromOffset(120, 34), 0
    local text = Instance.new("TextLabel")
    text.BackgroundTransparency, text.Size, text.Font, text.TextSize = 1, UDim2.fromScale(1, 1), Enum.Font.GothamBold, 13
    text.TextColor3, text.TextStrokeTransparency = xDTaraZ.Config.SoundColor, 0.3
    text.Parent = gui
    gui.Parent = holder
    holder.Parent = Workspace.Terrain
    gui.Adornee = holder
    sound.Marks[#sound.Marks + 1] = { Gui = holder, Text = text, Label = label, Born = osClock() }
end

function xDTaraZ.Sound.Step()
    local sound, life = xDTaraZ.Sound, xDTaraZ.Options.SoundEspLife
    local cam = Workspace.CurrentCamera
    for index = #sound.Marks, 1, -1 do
        local mark = sound.Marks[index]
        local age = osClock() - mark.Born
        if age > life or not xDTaraZ.Options.SoundEsp then
            mark.Gui:Destroy()
            table.remove(sound.Marks, index)
        else
            local dist = cam and math.floor((mark.Gui.WorldPosition - cam.CFrame.Position).Magnitude) or 0
            mark.Text.Text = ("%s\n%dm"):format(mark.Label, dist)
            mark.Text.TextTransparency = age / life * 0.8
        end
    end
end

xDTaraZ.World = {}

function xDTaraZ.World.Step()
    local opts, state = xDTaraZ.Options, xDTaraZ.State
    if opts.Fullbright then
        state.LightSaved = state.LightSaved or { Lighting.Brightness, Lighting.ClockTime, Lighting.FogEnd, Lighting.GlobalShadows, Lighting.Ambient }
        Lighting.Brightness, Lighting.ClockTime, Lighting.FogEnd, Lighting.GlobalShadows = 2, 14, 1e6, false
        Lighting.Ambient = Color3.fromRGB(178, 178, 178)
    elseif state.LightSaved then
        Lighting.Brightness, Lighting.ClockTime, Lighting.FogEnd, Lighting.GlobalShadows, Lighting.Ambient = table.unpack(state.LightSaved)
        state.LightSaved = nil
    end
end

function xDTaraZ.World.HookEffects()
    local smoke, flash = xDTaraZ.GameLib.Smoke, xDTaraZ.GameLib.Flash
    if smoke and type(smoke.Create) == "function" then
        local create
        create = xDTaraZ.Util.Hook("Smoke", smoke.Create, function(...)
            if xDTaraZ.Options.NoSmoke then return nil end
            return create(...)
        end)
    end
    if flash and type(flash.Flash) == "function" then
        local blind
        blind = xDTaraZ.Util.Hook("Flash", flash.Flash, function(...)
            if xDTaraZ.Options.NoFlash then return nil end
            return blind(...)
        end)
    end
    if xDTaraZ.Options.NoSmoke and smoke then pcall(smoke.DestroyAll) end
    if xDTaraZ.Options.NoFlash and flash then pcall(flash.CancelFlash) end
end

function xDTaraZ.World.OnIdled()
    if not xDTaraZ.Options.AntiAfk then return end
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(vector2New())
    end)
end

function xDTaraZ.World.OnJump()
    if not xDTaraZ.Options.InfiniteJump or xDTaraZ.Player.Body() then return end
    local hum = xDTaraZ.Player.Humanoid()
    if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
end

function xDTaraZ.World.SetCrouch(down)
    local state = xDTaraZ.State
    if state.HopCrouched == down then return end
    state.HopCrouched = down
    local controller = xDTaraZ.GameLib.Character
    if not controller then return end
    if not down and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then return end
    controller.crouch(down)
end

function xDTaraZ.World.OnSpace(input, down, processed)
    if input.KeyCode ~= Enum.KeyCode.Space then return end
    if down and UserInputService:GetFocusedTextBox() then return end
    xDTaraZ.State.SpaceHeld = down
end

function xDTaraZ.World.Hop()
    local opts, state = xDTaraZ.Options, xDTaraZ.State
    local body = opts.BunnyHop and state.SpaceHeld and xDTaraZ.Player.Alive() and xDTaraZ.Player.Body()
    if not body or UserInputService:GetFocusedTextBox() then
        xDTaraZ.World.SetCrouch(false)
        return
    end
    local controller = xDTaraZ.GameLib.Character
    local grounded = body.OnGround == true
    xDTaraZ.World.SetCrouch(opts.BunnyCrouch and not grounded)
    controller.jump(false)
    if not grounded or osClock() - state.HopAt < xDTaraZ.Config.HopGap then return end
    state.HopAt = osClock()
    controller.jump()
end

function xDTaraZ.World.HopStep()
    local ok, err = pcall(xDTaraZ.World.Hop)
    if ok then
        xDTaraZ.Faults.Clear("Bunny Hop")
    else
        xDTaraZ.Faults.Report("Bunny Hop", err, { "BunnyHop" }, xDTaraZ.World.Hop)
    end
end

function xDTaraZ.World.Rejoin()
    pcall(TeleportService.TeleportToPlaceInstance, TeleportService, game.PlaceId, game.JobId, LocalPlayer)
end

function xDTaraZ.World.ServerHop()
    pcall(TeleportService.Teleport, TeleportService, game.PlaceId, LocalPlayer)
end

xDTaraZ.Skins = { Map = {}, Applied = setmetatable({}, { __mode = "k" }), Catalog = nil, Rarity = {}, Images = {}, Colors = {}, Originals = setmetatable({}, { __mode = "k" }) }

function xDTaraZ.Skins.Folder()
    local assets = ReplicatedStorage:FindFirstChild("Assets")
    return assets and assets:FindFirstChild("Skins")
end

function xDTaraZ.Skins.CategoryOf(name, kind)
    local mapped = xDTaraZ.Config.SkinKinds[kind]
    if mapped then return mapped end
    if kind ~= "Weapon" then return nil end
    local gun = xDTaraZ.Weapons[name]
    return gun and gun.Type or "Other"
end

function xDTaraZ.Skins.Build()
    local skins = xDTaraZ.Skins
    local folder = skins.Folder()
    local listing = xDTaraZ.Util.Decode(ReplicatedStorage:GetAttribute("AvaiableSkins")) or {}
    local ranks = xDTaraZ.Config.SkinRanks
    local catalog = {}
    for name, entries in pairs(listing) do
        if type(entries) ~= "table" or not (folder and folder:FindFirstChild(name)) then continue end
        local _, first = next(entries)
        local category = skins.CategoryOf(name, type(first) == "table" and first.type)
        if not category then continue end
        catalog[category] = catalog[category] or {}
        table.insert(catalog[category], name)
        skins.Rarity[name], skins.Images[name], skins.Colors[name] = {}, {}, {}
        for skin, entry in pairs(entries) do
            if type(entry) ~= "table" then continue end
            skins.Rarity[name][skin] = ranks[entry.rarity] or 0
            local look = type(entry.wearImages) == "table" and entry.wearImages[1]
            skins.Images[name][skin] = look and look.assetId
            local rarity = xDTaraZ.GameLib.Rarities and xDTaraZ.GameLib.Rarities[entry.rarity]
            skins.Colors[name][skin] = type(rarity) == "table" and rarity.Color or nil
        end
    end
    for _, names in pairs(catalog) do table.sort(names) end
    skins.Catalog = catalog
end

function xDTaraZ.Skins.Categories()
    if not xDTaraZ.Skins.Catalog then xDTaraZ.Skins.Build() end
    local list, seen = {}, {}
    for _, category in ipairs(xDTaraZ.Config.SkinOrder) do
        if xDTaraZ.Skins.Catalog[category] then list[#list + 1] = category seen[category] = true end
    end
    for category in pairs(xDTaraZ.Skins.Catalog) do
        if not seen[category] then list[#list + 1] = category end
    end
    if #list == 0 then list[1] = "-" end
    return list
end

function xDTaraZ.Skins.Items(category)
    if not xDTaraZ.Skins.Catalog then xDTaraZ.Skins.Build() end
    local names = xDTaraZ.Skins.Catalog[category or ""]
    return (names and #names > 0) and names or { "-" }
end

function xDTaraZ.Skins.List(weapon)
    local folder = xDTaraZ.Skins.Folder()
    local holder = folder and folder:FindFirstChild(weapon or "")
    if not holder then return { "-" } end
    local ranks = xDTaraZ.Skins.Rarity[weapon] or {}
    local names = {}
    for _, child in ipairs(holder:GetChildren()) do names[#names + 1] = child.Name end
    table.sort(names, function(a, b)
        local ra, rb = ranks[a] or 0, ranks[b] or 0
        if ra ~= rb then return ra > rb end
        return a < b
    end)
    return #names > 0 and names or { "-" }
end

function xDTaraZ.Skins.Source(weapon, skin, view)
    local folder = xDTaraZ.Skins.Folder()
    local paint = folder and folder:FindFirstChild(weapon) and folder[weapon]:FindFirstChild(skin)
    local side = paint and paint:FindFirstChild(view)
    if not side then return nil end
    for _, wear in ipairs(xDTaraZ.Config.SkinWears) do
        if side:FindFirstChild(wear) then return side[wear] end
    end
    return side:FindFirstChildOfClass("Folder")
end

function xDTaraZ.Skins.Paint(model, weapon, skin, view)
    local source = xDTaraZ.Skins.Source(weapon, skin, view)
    if not source then return false end
    local whole = source:FindFirstChild("SurfaceAppearance")
    local arms = xDTaraZ.Config.SkinArms
    for _, part in ipairs(model:GetDescendants()) do
        if not part:IsA("BasePart") then continue end
        local old = part:FindFirstChildOfClass("SurfaceAppearance")
        local look = source:FindFirstChild(part.Name)
        if not look and whole and old and not arms[part.Name] then look = whole end
        if not look then continue end
        local originals = xDTaraZ.Skins.Originals
        if originals[part] == nil then originals[part] = old and old:Clone() or false end
        if old then old:Destroy() end
        look:Clone().Parent = part
    end
    return true
end

function xDTaraZ.Skins.Reset(model)
    local originals = xDTaraZ.Skins.Originals
    for _, part in ipairs(model:GetDescendants()) do
        local saved = part:IsA("BasePart") and originals[part]
        if saved == nil then continue end
        local current = part:FindFirstChildOfClass("SurfaceAppearance")
        if current then current:Destroy() end
        if saved then saved:Clone().Parent = part end
        originals[part] = nil
    end
end

function xDTaraZ.Skins.WeaponOf(model)
    local folder = xDTaraZ.Skins.Folder()
    if folder and folder:FindFirstChild(model.Name) then return model.Name end
    local equipped = xDTaraZ.Player.Equipped()
    return equipped and (equipped.Weapon or equipped.Name)
end

function xDTaraZ.Skins.Models()
    local list = {}
    for _, child in ipairs(Workspace.CurrentCamera:GetChildren()) do
        if child:IsA("Model") then list[#list + 1] = { child, "Camera" } end
    end
    local char = xDTaraZ.Player.Character()
    local folder = xDTaraZ.Skins.Folder()
    if char and folder then
        for _, child in ipairs(char:GetChildren()) do
            if child:IsA("Model") and folder:FindFirstChild(child.Name) then list[#list + 1] = { child, "Character" } end
        end
    end
    return list
end

function xDTaraZ.Skins.Step()
    local skins = xDTaraZ.Skins
    local on = xDTaraZ.Options.SkinChanger
    local glove = on and skins.Map[xDTaraZ.Config.GloveKey]
    local gloveSkin = glove and skins.Map[glove]
    for _, entry in ipairs(skins.Models()) do
        local model, view = entry[1], entry[2]
        local weapon = skins.WeaponOf(model)
        local skin = on and weapon and skins.Map[weapon] or nil
        local key = (skin or gloveSkin) and (tostring(weapon) .. "|" .. tostring(skin) .. "|" .. tostring(gloveSkin)) or nil
        if skins.Applied[model] == key then continue end
        if skins.Applied[model] then skins.Reset(model) end
        if skin then skins.Paint(model, weapon, skin, view) end
        if gloveSkin and view == "Camera" then skins.Paint(model, glove, gloveSkin, view) end
        skins.Applied[model] = key
    end
end

function xDTaraZ.Skins.Set(weapon, skin, quiet)
    if not weapon or weapon == "-" or not skin or skin == "-" then return false end
    local map, gloveKey = xDTaraZ.Skins.Map, xDTaraZ.Config.GloveKey
    local isGlove = xDTaraZ.Skins.Catalog and table.find(xDTaraZ.Skins.Catalog.Gloves or {}, weapon)
    if skin == "Default" then
        if map[weapon] == nil then return false end
        map[weapon] = nil
        if map[gloveKey] == weapon then map[gloveKey] = nil end
    else
        if map[weapon] == skin then return false end
        map[weapon] = skin
        if isGlove then map[gloveKey] = weapon end
    end
    if not quiet then xDTaraZ.Skins.Save() end
    return true
end

function xDTaraZ.Skins.SetAll(pick)
    local count = 0
    for _, category in ipairs(xDTaraZ.Skins.Categories()) do
        if category == "Gloves" then continue end
        for _, weapon in ipairs(xDTaraZ.Skins.Items(category)) do
            xDTaraZ.Skins.Set(weapon, pick(xDTaraZ.Skins.List(weapon)), true)
            count += 1
        end
    end
    xDTaraZ.Skins.Save()
    return count
end

function xDTaraZ.Skins.Save()
    if type(writefile) ~= "function" then return end
    local ok, err = pcall(function()
        if type(isfolder) == "function" and not isfolder(xDTaraZ.Config.SaveFolder) then makefolder(xDTaraZ.Config.SaveFolder) end
        writefile(xDTaraZ.Config.SkinFile, HttpService:JSONEncode(xDTaraZ.Skins.Map))
    end)
    if not ok then warn("[BloxStrike] skins save:", err) end
end

function xDTaraZ.Skins.Load()
    if type(readfile) ~= "function" or type(isfile) ~= "function" then return end
    local ok, raw = pcall(function() return isfile(xDTaraZ.Config.SkinFile) and readfile(xDTaraZ.Config.SkinFile) end)
    local map = ok and xDTaraZ.Util.Decode(raw)
    if type(map) == "table" then xDTaraZ.Skins.Map = map end
end

xDTaraZ.Economy = {}

function xDTaraZ.Economy.RedeemAll()
    local net = xDTaraZ.GameLib.Net
    local packet = net and net.Dashboard and net.Dashboard.RedeemCode
    if not packet or xDTaraZ.State.Redeeming then return 0 end
    xDTaraZ.State.Redeeming = true
    local sent = 0
    for _, code in ipairs(xDTaraZ.Config.Codes) do
        if pcall(packet.Send, code) then sent += 1 end
        task.wait(xDTaraZ.Config.RedeemGap)
    end
    xDTaraZ.State.Redeeming = false
    return sent
end

function xDTaraZ.Economy.HookBuys()
    local net = xDTaraZ.GameLib.Net
    local packet = net and net.Inventory and net.Inventory.BuyMenuPurchase
    if not packet then return end
    local original
    original = xDTaraZ.Util.Hook("Buy", packet.Send, function(payload, ...)
        if type(payload) == "table" and payload.Name and not xDTaraZ.State.Replaying then
            local list = xDTaraZ.State.Bought
            for index, entry in ipairs(list) do
                if entry.Name == payload.Name then table.remove(list, index) break end
            end
            list[#list + 1] = { Equipment = payload.Equipment, Path = payload.Path, Name = payload.Name }
        end
        return original(payload, ...)
    end)
end

function xDTaraZ.Economy.Rebuy()
    local net = xDTaraZ.GameLib.Net
    local packet = net and net.Inventory and net.Inventory.BuyMenuPurchase
    if not packet or #xDTaraZ.State.Bought == 0 or xDTaraZ.State.Replaying then return 0 end
    xDTaraZ.State.Replaying = true
    local sent = 0
    for _, entry in ipairs(xDTaraZ.State.Bought) do
        if pcall(packet.Send, { Equipment = entry.Equipment, Path = entry.Path, Name = entry.Name }) then sent += 1 end
        task.wait(xDTaraZ.Config.RebuyGap)
    end
    xDTaraZ.State.Replaying = false
    return sent
end

function xDTaraZ.Economy.Step()
    local state = xDTaraZ.State
    local phase = Workspace:GetAttribute("GameState")
    local entered = xDTaraZ.Config.BuyStates[phase] and phase ~= state.LastPhase
    state.LastPhase = phase
    if not entered then state.RebuyPending = state.RebuyPending and xDTaraZ.Config.BuyStates[phase] return end
    state.RebuyPending = true
end

function xDTaraZ.Economy.Tick()
    local state = xDTaraZ.State
    xDTaraZ.Economy.Step()
    if not (xDTaraZ.Options.AutoRebuy and state.RebuyPending and xDTaraZ.Player.Alive()) then return end
    state.RebuyPending = false
    task.spawn(xDTaraZ.Economy.Rebuy)
end

function xDTaraZ.Economy.BoughtText()
    local names = {}
    for _, entry in ipairs(xDTaraZ.State.Bought) do names[#names + 1] = entry.Name end
    return #names > 0 and table.concat(names, ", ") or "-"
end

xDTaraZ.Spectators = {}

function xDTaraZ.Spectators.Text()
    local count = tonumber(LocalPlayer:GetAttribute("Spectators")) or 0
    if count == 0 then return "None" end
    local names = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and tostring(player:GetAttribute("IsSpectating")) == "true" and tostring(player:GetAttribute("Dead")) == "true" then
            names[#names + 1] = player.DisplayName
        end
    end
    return count .. " watching" .. (#names > 0 and (" (dead: " .. table.concat(names, ", ") .. ")") or "")
end

xDTaraZ.Faults = { Streaks = {} }

function xDTaraZ.Faults.Clear(name)
    xDTaraZ.Faults.Streaks[name] = nil
end

function xDTaraZ.Faults.AnyOn(toggles)
    for _, key in ipairs(toggles) do
        if xDTaraZ.Options[key] then return true end
    end
    return false
end

function xDTaraZ.Faults.Halt(name, err, toggles, restore)
    warn("[BloxStrike] " .. name .. " stopped:", err)
    for _, key in ipairs(toggles) do
        xDTaraZ.Options[key] = false
    end
    if restore then xDTaraZ.Util.Try(name .. " restore", restore) end
    local halted = xDTaraZ.State.Halted
    halted[#halted + 1] = { name, tostring(err):match("^[^\n]*"), toggles }
end

function xDTaraZ.Faults.Report(name, err, toggles, restore)
    local now, streaks = osClock(), xDTaraZ.Faults.Streaks
    local streak = streaks[name]
    if not streak or (streak.Halted and xDTaraZ.Faults.AnyOn(toggles)) then
        streak = { Count = 0, First = now, Warned = false, Halted = false }
        streaks[name] = streak
    end
    streak.Count += 1
    if streak.Warned then return streak.Halted end
    if streak.Count < xDTaraZ.Config.MaxFails or now - streak.First < xDTaraZ.Config.FailWindow then return false end

    streak.Warned = true
    if #toggles == 0 then
        warn("[BloxStrike] " .. name .. " keeps failing:", err)
        return false
    end
    streak.Halted = true
    xDTaraZ.Faults.Halt(name, err, toggles, restore)
    return true
end

xDTaraZ.Scheduler = { Jobs = {} }

function xDTaraZ.Scheduler.Every(name, interval, fn, toggles, restore)
    xDTaraZ.Scheduler.Jobs[name] = { Interval = interval, Fn = fn, Next = 0, Toggles = toggles, Restore = restore }
end

function xDTaraZ.Scheduler.Resume(name, job)
    if not xDTaraZ.Faults.AnyOn(job.Toggles) then return false end
    job.Halted = false
    xDTaraZ.Faults.Clear(name)
    return true
end

function xDTaraZ.Scheduler.Boot()
    xDTaraZ:Connect(RunService.Heartbeat, function()
        local now = osClock()
        for name, job in pairs(xDTaraZ.Scheduler.Jobs) do
            if now < job.Next then continue end
            job.Next = now + job.Interval
            if job.Halted and not xDTaraZ.Scheduler.Resume(name, job) then continue end

            local ok, err = pcall(job.Fn)
            if ok then
                xDTaraZ.Faults.Clear(name)
            else
                job.Halted = xDTaraZ.Faults.Report(name, err, job.Toggles, job.Restore)
            end
        end
    end)
end

-- ==========================================================================
--  UI — Linoria (Library_lua) port
-- ==========================================================================

xDTaraZ.UI = { Labels = {} }

-- Helper: run callback in a deferred task so UI thread stays clean
function xDTaraZ.UI.Detach(fn)
    return function(...)
        local packed = table.pack(...)
        task.defer(function()
            local ok, err = pcall(fn, table.unpack(packed, 1, packed.n))
            if not ok then warn("[BloxStrike] ui:", err) end
        end)
    end
end

-- Bind a Linoria widget to xDTaraZ.Options[key]
-- Toggles live in getgenv().Toggles; sliders/dropdowns in getgenv().Options
function xDTaraZ.UI.Bind(key)
    local t = getgenv().Toggles[key]
    local o = getgenv().Options[key]
    local widget = t or o
    if not widget then return end
    local function Apply(value) xDTaraZ.Options[key] = value end
    Apply(widget.Value)
    widget:OnChanged(Apply)
end

-- Retrieve a Linoria widget by key (toggle or option)
function xDTaraZ.UI.Widget(key)
    return getgenv().Toggles[key] or getgenv().Options[key]
end

-- Simple wrapped label pair used for status readouts (replaces AddParagraph)
function xDTaraZ.UI.StatusLabel(group, title, default)
    group:AddLabel(title .. ": " .. (default or "-"), false)
    local lbl = group:AddLabel(default or "-", true)
    return {
        SetText = function(_, text)
            lbl:SetText(text)
        end
    }
end

-- Paragraph-style: title on its own line, content below, both wrapping
function xDTaraZ.UI.Paragraph(group, title, content)
    group:AddLabel("[" .. title .. "]", false)
    local lbl = group:AddLabel(content or "-", true)
    return {
        SetText = function(_, text)
            lbl:SetText(text)
        end
    }
end

function xDTaraZ.UI.BuildMain(window)
    local tab = window:AddTab("Main")

    local status = tab:AddLeftGroupbox("Status")
    xDTaraZ.UI.Labels.Match      = xDTaraZ.UI.Paragraph(status, "Match", "-")
    xDTaraZ.UI.Labels.Combat     = xDTaraZ.UI.Paragraph(status, "Combat", "-")
    xDTaraZ.UI.Labels.Spectators = xDTaraZ.UI.Paragraph(status, "Spectators", "-")
    xDTaraZ.UI.Labels.Esp        = xDTaraZ.UI.Paragraph(status, "ESP", "-")

    local discord = tab:AddRightGroupbox("Discord")
    discord:AddLabel(xDTaraZ.Config.Discord, true)
    discord:AddButton({
        Text = "Copy Discord Link",
        Func = xDTaraZ.UI.Detach(function()
            if xDTaraZ.Util.Copy(xDTaraZ.Config.Discord) then
                Library:Notify("Discord link copied!", 3)
            else
                Library:Notify(xDTaraZ.Config.Discord, 6)
            end
        end)
    })

    local logBox = tab:AddRightGroupbox("Update Log")
    for i = 1, math.min(2, #xDTaraZ.Config.UpdateLog) do
        local entry = xDTaraZ.Config.UpdateLog[i]
        logBox:AddLabel("[" .. entry[1] .. "]", false)
        logBox:AddLabel(entry[2], true)
        logBox:AddDivider()
    end
end

local priorities = { "Crosshair", "Distance", "Health" }

function xDTaraZ.UI.BuildAimbot(window)
    local tab = window:AddTab("Aimbot")

    local main = tab:AddLeftGroupbox("Aimbot")
    main:AddToggle("Aimbot", { Text = "Aimbot", Default = false, Tooltip = "Locks your view onto the enemy in the FOV" })
        :AddKeyPicker("AimbotKey", { Default = "E", Mode = "Toggle" })
    main:AddSlider("AimbotSmooth", { Text = "Smoothness", Min = 1, Max = 20, Default = 1, Rounding = 0, Tooltip = "1 = instant snap" })
    main:AddToggle("AimbotSticky", { Text = "Sticky target", Default = true, Tooltip = "Keeps the same enemy until it is lost" })

    local target = tab:AddRightGroupbox("Aimbot Targeting")
    target:AddDropdown("AimbotBone",        { Text = "Aim part",     Values = { "Head", "Torso" }, Default = "Head" })
    target:AddDropdown("AimbotPriority",    { Text = "Priority",     Values = priorities,          Default = "Crosshair" })
    target:AddToggle("AimbotVisible",       { Text = "Visible only", Default = true })
    target:AddSlider("AimbotFov",           { Text = "FOV (px)",     Min = 20, Max = 800,  Default = 150, Rounding = 0, Suffix = "px" })
    target:AddToggle("AimbotShowFov",       { Text = "Show FOV circle", Default = false })
    target:AddSlider("AimbotMaxDistance",   { Text = "Max distance", Min = 50, Max = 3000, Default = 1500, Rounding = 0, Suffix = "m" })
end

function xDTaraZ.UI.BuildSilent(window)
    local tab = window:AddTab("Silent Aim")

    local main = tab:AddLeftGroupbox("Silent Aim")
    main:AddToggle("SilentAim", { Text = "Silent aim", Default = false, Tooltip = "Shots you fire go to the enemy in the FOV" })
        :AddKeyPicker("SilentKey", { Default = "None", Mode = "Toggle" })
    main:AddSlider("SilentHitChance",  { Text = "Hit chance %",     Min = 1, Max = 100, Default = 100, Rounding = 0, Suffix = "%" })
    main:AddSlider("SilentHeadChance", { Text = "Headshot chance %", Min = 0, Max = 100, Default = 100, Rounding = 0, Suffix = "%" })

    local target = tab:AddRightGroupbox("Silent Targeting")
    target:AddDropdown("SilentPriority",  { Text = "Priority",      Values = priorities,           Default = "Crosshair" })
    target:AddToggle("SilentVisible",     { Text = "Visible only",  Default = true,  Tooltip = "Off = through walls too" })
    target:AddSlider("SilentFov",         { Text = "FOV (px)",      Min = 20, Max = 1000, Default = 220, Rounding = 0, Suffix = "px" })
    target:AddToggle("SilentShowFov",     { Text = "Show FOV circle", Default = false })
    target:AddSlider("SilentMaxDistance", { Text = "Max distance",  Min = 50, Max = 3000, Default = 2000, Rounding = 0, Suffix = "m" })
    target:AddToggle("SilentPredict",     { Text = "Lead moving targets", Default = false })
end

function xDTaraZ.UI.BuildTrigger(window)
    local tab = window:AddTab("Trigger & Rage")

    local trigger = tab:AddLeftGroupbox("Triggerbot")
    trigger:AddToggle("Triggerbot", { Text = "Triggerbot", Default = false, Tooltip = "Fires the moment an enemy is under your crosshair" })
        :AddKeyPicker("TriggerKey", { Default = "T", Mode = "Toggle" })
    trigger:AddSlider("TriggerDelay",      { Text = "Reaction delay (ms)", Min = 0, Max = 400, Default = 0,   Rounding = 0, Suffix = "ms" })
    trigger:AddSlider("TriggerHitChance",  { Text = "Fire chance %",       Min = 1, Max = 100, Default = 100, Rounding = 0, Suffix = "%" })

    local rage = tab:AddRightGroupbox("Ragebot")
    rage:AddToggle("Ragebot", { Text = "Ragebot", Default = false, Tooltip = "Snaps to and kills any enemy it can reach" })
        :AddKeyPicker("RageKey", { Default = "None", Mode = "Toggle" })
    rage:AddToggle("RageVisible",     { Text = "Visible only", Default = true, Tooltip = "Off = through walls too" })
    rage:AddSlider("RageMaxDistance", { Text = "Max distance", Min = 50, Max = 3000, Default = 2000, Rounding = 0, Suffix = "m" })
end

function xDTaraZ.UI.BuildGuns(window)
    local tab = window:AddTab("Gun Mods")

    local mods = tab:AddLeftGroupbox("Gun Mods")
    mods:AddToggle("NoRecoil", { Text = "No recoil", Default = false, Tooltip = "Your view stays still while spraying" })
    mods:AddToggle("NoSpread", { Text = "No spread", Default = false, Tooltip = "Every bullet lands on the crosshair" })
end

function xDTaraZ.UI.BuildVisuals(window)
    local tab = window:AddTab("World / Sound")

    local world = tab:AddLeftGroupbox("World")
    world:AddToggle("Fullbright", { Text = "Fullbright",   Default = false })
    world:AddToggle("NoFlash",    { Text = "No flash",     Default = false, Tooltip = "Flashbangs do not blind you" })
    world:AddToggle("NoSmoke",    { Text = "No smoke",     Default = false, Tooltip = "See through smoke grenades" })

    local heard = tab:AddLeftGroupbox("Hidden Enemies (Sound ESP)")
    heard:AddToggle("SoundEsp",    { Text = "Sound ESP",           Default = false, Tooltip = "Shows where enemies walk/shoot behind walls" })
    heard:AddSlider("SoundEspLife",{ Text = "Show for (s)",        Min = 1, Max = 8,  Default = 3, Rounding = 0, Suffix = "s" })
    heard:AddSlider("EspMemory",   { Text = "Keep hidden enemies", Min = 0, Max = 15, Default = 5, Rounding = 0, Suffix = "s",
                                     Tooltip = "ESP keeps a box at last seen/heard position" })

    local cam = tab:AddRightGroupbox("Camera")
    cam:AddToggle("CameraFov",      { Text = "Custom FOV",  Default = false })
    cam:AddSlider("CameraFovValue", { Text = "FOV",         Min = 70, Max = 120, Default = 100, Rounding = 0 })
end

function xDTaraZ.UI.SkinGroup(tab, category, side)
    local titles = {
        Pistol        = "Pistols",
        SMG           = "SMGs",
        Rifle         = "Rifles",
        Sniper        = "Snipers",
        Heavy         = "Heavy",
        Shotgun       = "Shotguns",
        ["Machine Gun"] = "Machine Guns",
        Knives        = "Knives",
        Gloves        = "Gloves",
        Grenades      = "Grenades",
        Gear          = "Gear",
    }
    local name = titles[category] or category
    local group = side == "Left" and tab:AddLeftGroupbox(name) or tab:AddRightGroupbox(name)
    for _, weapon in ipairs(xDTaraZ.Skins.Items(category)) do
        if weapon == "-" then continue end
        local values = { "Default" }
        for _, skin in ipairs(xDTaraZ.Skins.List(weapon)) do values[#values + 1] = skin end
        group:AddDropdown("Skin_" .. weapon, {
            Text    = weapon,
            Values  = values,
            Default = xDTaraZ.Skins.Map[weapon] or "Default",
            Callback = function(skin)
                xDTaraZ.Skins.Set(weapon, skin)
            end
        })
    end
end

function xDTaraZ.UI.PlaceSkinGroup(tab, category, heights)
    local side = heights.Left <= heights.Right and "Left" or "Right"
    local rows = 1
    for _, weapon in ipairs(xDTaraZ.Skins.Items(category)) do
        if weapon ~= "-" then rows += 1 end
    end
    if rows == 1 then return end
    heights[side] += rows
    xDTaraZ.Util.Try("skins " .. category, xDTaraZ.UI.SkinGroup, tab, category, side)
end

function xDTaraZ.UI.SyncSkins()
    for _, category in ipairs(xDTaraZ.Skins.Categories()) do
        for _, weapon in ipairs(xDTaraZ.Skins.Items(category)) do
            local picker = xDTaraZ.UI.Widget("Skin_" .. weapon)
            if picker then picker:SetValue(xDTaraZ.Skins.Map[weapon] or "Default") end
        end
    end
end

function xDTaraZ.UI.BuildSkins(window)
    local tab = window:AddTab("Skins")

    local main = tab:AddLeftGroupbox("Skin Changer")
    main:AddToggle("SkinChanger", { Text = "Skin changer", Default = false, Tooltip = "Pick a skin below and it shows right away" })
    main:AddButton({
        Text = "Rarest On Everything",
        Func = xDTaraZ.UI.Detach(function()
            local count = xDTaraZ.Skins.SetAll(function(list) return list[1] end)
            xDTaraZ.UI.SyncSkins()
            Library:Notify("Set " .. count .. " items to rarest skin", 3)
        end)
    })
    main:AddButton({
        Text = "Random skins",
        Func = xDTaraZ.UI.Detach(function()
            xDTaraZ.Skins.SetAll(function(list) return list[math.random(#list)] end)
            xDTaraZ.UI.SyncSkins()
        end)
    }):AddButton({
        Text = "Reset All",
        Func = xDTaraZ.UI.Detach(function()
            table.clear(xDTaraZ.Skins.Map)
            xDTaraZ.Skins.Save()
            xDTaraZ.UI.SyncSkins()
        end)
    })

    local gear = { Knives = true, Gloves = true, Grenades = true, Gear = true }
    local heights = { Left = xDTaraZ.Config.SkinMainRows, Right = 0 }
    for _, category in ipairs({ "Knives", "Gloves", "Grenades", "Gear" }) do
        xDTaraZ.UI.PlaceSkinGroup(tab, category, heights)
    end

    local guns = window:AddTab("Gun Skins")
    heights = { Left = 0, Right = 0 }
    local ok, categories = pcall(xDTaraZ.Skins.Categories)
    for _, category in ipairs(ok and categories or {}) do
        if gear[category] then continue end
        xDTaraZ.UI.PlaceSkinGroup(guns, category, heights)
    end
end

function xDTaraZ.UI.BuildMisc(window)
    local tab = window:AddTab("Misc")

    local buy = tab:AddLeftGroupbox("Auto Buy")
    buy:AddToggle("AutoRebuy", { Text = "Auto rebuy", Default = false, Tooltip = "Buys your last loadout every round" })
    xDTaraZ.UI.Labels.Bought = xDTaraZ.UI.Paragraph(buy, "Saved loadout", "-")
    buy:AddButton({
        Text = "Rebuy Now",
        Func = xDTaraZ.UI.Detach(function()
            xDTaraZ.Util.Try("hook buys", xDTaraZ.Economy.HookBuys)
            local sent = xDTaraZ.Economy.Rebuy()
            Library:Notify(sent > 0 and ("Bought " .. sent .. " items") or "Buy something once first", 3)
        end)
    }):AddButton({
        Text = "Clear",
        Func = xDTaraZ.UI.Detach(function()
            table.clear(xDTaraZ.State.Bought)
        end)
    })

    local codes = tab:AddLeftGroupbox("Codes")
    codes:AddButton({
        Text = "Redeem All Codes",
        Func = xDTaraZ.UI.Detach(function()
            local sent = xDTaraZ.Economy.RedeemAll()
            Library:Notify("Sent " .. sent .. " codes (level 5+ needed)", 4)
        end)
    })

    local util = tab:AddRightGroupbox("Utility")
    util:AddToggle("InfiniteJump", { Text = "Infinite jump", Default = false, Tooltip = "Lobby only — use Bunny hop in rounds" })
    util:AddToggle("BunnyHop",     { Text = "Bunny hop",     Default = false, Tooltip = "Hold Space to keep hopping" })
    util:AddToggle("BunnyCrouch",  { Text = "Crouch jump",   Default = true,  Tooltip = "Crouches in the air like a CS crouch jump" })
    util:AddToggle("AntiAfk",      { Text = "Anti AFK",      Default = false })
    util:AddButton({ Text = "Rejoin",     Func = xDTaraZ.UI.Detach(xDTaraZ.World.Rejoin) })
        :AddButton({ Text = "Server Hop", Func = xDTaraZ.UI.Detach(xDTaraZ.World.ServerHop) })
end

function xDTaraZ.UI.RefreshStatus()
    local labels, state = xDTaraZ.UI.Labels, xDTaraZ.State
    if labels.Match then
        labels.Match:SetText(("%s | %s | $%s"):format(
            tostring(Workspace:GetAttribute("Map") or "-"),
            tostring(Workspace:GetAttribute("GameState") or "-"),
            tostring(LocalPlayer:GetAttribute("Money") or 0)))
    end
    if labels.Combat then
        local target = state.RageTarget or state.AimTarget or state.SilentTarget
        target = target and target.Name or "none"
        labels.Combat:SetText(("Target: %s | Kills %s | Shots %d | Aimed %d"):format(
            target,
            tostring(LocalPlayer:GetAttribute("Kills") or 0),
            state.Shots,
            state.Redirected))
    end
    if labels.Spectators then labels.Spectators:SetText(xDTaraZ.Spectators.Text()) end
    if labels.Esp then
        labels.Esp:SetText(xDTaraZ.Esp.Count .. " tracked")
    end
    if labels.Bought then labels.Bought:SetText(xDTaraZ.Economy.BoughtText()) end
end

-- Turn off toggles that the fault system halted; show queued notices.
function xDTaraZ.UI.Drain()
    local state = xDTaraZ.State
    if not (state.Halted[1] or state.Notices[1]) then return end
    local stopped, notices = table.clone(state.Halted), table.clone(state.Notices)
    table.clear(state.Halted)
    table.clear(state.Notices)

    for _, halt in ipairs(stopped) do
        for _, key in ipairs(halt[3]) do
            local toggle = xDTaraZ.UI.Widget(key)
            if toggle and toggle.Value == true then
                xDTaraZ.Util.Try("halt " .. key, toggle.SetValue, toggle, false)
            end
        end
        Library:Notify(halt[1] .. " stopped: " .. halt[2], 6)
    end
    for _, notice in ipairs(notices) do
        Library:Notify(notice[2], 5)
    end
end

-- Install hooks the first time each feature is switched on
function xDTaraZ.UI.HookOnDemand()
    local installers = {
        SilentAim   = xDTaraZ.Silent.InstallHook,
        Ragebot     = xDTaraZ.Silent.InstallHook,
        Triggerbot  = xDTaraZ.Silent.InstallHook,
        NoRecoil    = xDTaraZ.Guns.HookKick,
        CameraFov   = xDTaraZ.Guns.BindFov,
        NoSpread    = xDTaraZ.Guns.HookSpread,
        NoSmoke     = xDTaraZ.World.HookEffects,
        NoFlash     = xDTaraZ.World.HookEffects,
        AutoRebuy   = xDTaraZ.Economy.HookBuys,
        SoundEsp    = xDTaraZ.Sound.Install,
    }
    for idx, install in pairs(installers) do
        local widget = xDTaraZ.UI.Widget(idx)
        if not widget then continue end
        widget:OnChanged(function(on)
            if on then task.defer(xDTaraZ.Util.Try, "hook " .. idx, install) end
        end)
    end

    local trigger = xDTaraZ.UI.Widget("Triggerbot")
    if trigger then
        trigger:OnChanged(function(on)
            if on then task.delay(xDTaraZ.Config.HookSettle, xDTaraZ.UI.WarnReducedTrigger) end
        end)
    end
end

function xDTaraZ.UI.WarnReducedTrigger()
    local state = xDTaraZ.State
    if state.Hooks.Shoot or state.TriggerWarned then return end
    state.TriggerWarned = true
    table.insert(state.Notices, { "Triggerbot", "Running in reduced mode — shot pacing less exact on this executor" })
end

function xDTaraZ.UI.Build(window)
    for _, build in ipairs({
        xDTaraZ.UI.BuildMain,
        xDTaraZ.UI.BuildAimbot,
        xDTaraZ.UI.BuildSilent,
        xDTaraZ.UI.BuildTrigger,
        xDTaraZ.UI.BuildGuns,
        xDTaraZ.UI.BuildVisuals,
        xDTaraZ.UI.BuildSkins,
        xDTaraZ.UI.BuildMisc,
    }) do
        xDTaraZ.Util.Try("build", build, window)
    end

    -- Bind every option key to xDTaraZ.Options
    for key in pairs(xDTaraZ.Options) do
        xDTaraZ.Util.Try("bind " .. key, xDTaraZ.UI.Bind, key)
    end

    xDTaraZ.Util.Try("hooks", xDTaraZ.UI.HookOnDemand)

    -- Status & drain pump via scheduler (replaces Library:Every)
    xDTaraZ.Scheduler.Every("UI Status", xDTaraZ.Config.StatusInterval, xDTaraZ.UI.RefreshStatus, {})
    xDTaraZ.Scheduler.Every("UI Drain",  xDTaraZ.Config.StatusInterval, xDTaraZ.UI.Drain,          {})
end

function xDTaraZ.Boot()
    xDTaraZ.Util.Try("skins load", xDTaraZ.Skins.Load)
    xDTaraZ.Util.Try("combat", xDTaraZ.Combat.Start)
    xDTaraZ:Connect(LocalPlayer.Idled, xDTaraZ.World.OnIdled)
    xDTaraZ:Connect(UserInputService.JumpRequest, xDTaraZ.World.OnJump)
    xDTaraZ:Connect(RunService.Heartbeat, xDTaraZ.World.HopStep)
    xDTaraZ:Connect(UserInputService.InputBegan,  function(input, processed) xDTaraZ.World.OnSpace(input, true,  processed) end)
    xDTaraZ:Connect(UserInputService.InputEnded,  function(input)            xDTaraZ.World.OnSpace(input, false)            end)

    xDTaraZ.Scheduler.Every("World",      0.2,  xDTaraZ.World.Step,      { "Fullbright" }, xDTaraZ.World.Step)
    xDTaraZ.Scheduler.Every("Auto Rebuy", 0.5,  xDTaraZ.Economy.Tick,    { "AutoRebuy" })
    xDTaraZ.Scheduler.Every("Sound ESP",  0.1,  xDTaraZ.Sound.Step,      { "SoundEsp" }, xDTaraZ.Sound.Step)
    xDTaraZ.Scheduler.Every("Skin Changer", 0.15, xDTaraZ.Skins.Step,    { "SkinChanger" }, xDTaraZ.Skins.Step)
    xDTaraZ.Util.Try("scheduler", xDTaraZ.Scheduler.Boot)
end

function xDTaraZ:Unload()
    self.State.Alive = false
    pcall(xDTaraZ.Sound.Uninstall)
    if xDTaraZ.Esp.Folder then pcall(function() xDTaraZ.Esp.Folder:Destroy() end) end
    xDTaraZ.Combat.Unload()
    for _, key in ipairs({ "NoRecoil", "NoSpread", "Fullbright", "CameraFov", "BunnyHop", "SkinChanger" }) do
        xDTaraZ.Options[key] = false
    end
    pcall(xDTaraZ.World.Step)
    pcall(xDTaraZ.World.SetCrouch, false)
    xDTaraZ.Guns.UnbindFov()
    pcall(xDTaraZ.Skins.Step)
    for _, conn in ipairs(self.State.Connections) do pcall(function() conn:Disconnect() end) end
    table.clear(self.State.Connections)
    xDTaraZ.Util.UnhookAll()
    environment.BloxStrikeUnload = nil
end

-- ==========================================================================
--  Bootstrap — load Library_lua, build window, kick off the game systems
-- ==========================================================================

local function BuildInterface()
    -- Load Library_lua source.
    -- Change this HttpGet call to however you host Library_lua in your setup,
    -- or replace with: local Library = loadstring(readfile("Library.lua"))()
    local source
    local ok1, body = pcall(xDTaraZ.Util.HttpGet, "https://raw.githubusercontent.com/xDTaraZz/Roblox-Scripts/refs/heads/main/Library.lua")
    if ok1 and type(body) == "string" and #body > 1000 then
        source = body
    else
        -- Fallback: try to load from disk if injected locally
        if type(readfile) == "function" and type(isfile) == "function" and pcall(isfile, "Library.lua") then
            local ok2, raw = pcall(readfile, "Library.lua")
            if ok2 then source = raw end
        end
    end

    if not source then
        xDTaraZ.Util.Alert("Could not load Library.lua. Check your connection or place Library.lua in your executor folder.")
        return false
    end

    local chunk, err = loadstring(source)
    if type(chunk) ~= "function" then
        xDTaraZ.Util.Alert("Library.lua failed to compile: " .. tostring(err))
        return false
    end
    local ran, loaded = pcall(chunk)
    if not (ran and type(loaded) == "table") then
        xDTaraZ.Util.Alert("Library.lua failed to execute: " .. tostring(loaded))
        return false
    end

    Library = loaded
    xDTaraZ.Library = Library
    pcall(MarioBanner.Step, "UI library")

    -- Create window
    local ok, Win = pcall(Library.CreateWindow, Library, {
        Title = "Mario Hub — BloxStrike",
        AutoShow = true,
    })
    if not ok then
        xDTaraZ.Util.Alert("Window creation failed: " .. tostring(Win))
        return false
    end

    Library:OnUnload(function() xDTaraZ:Unload() end)

    xDTaraZ.Util.Try("build ui", xDTaraZ.UI.Build, Win)
    task.defer(xDTaraZ.Util.Try, "boot", xDTaraZ.Boot)

    return true
end

environment.BloxStrikeUnload = function()
    if xDTaraZ.Library and not xDTaraZ.Library.Unloaded then
        xDTaraZ.Library:Unload()
    else
        xDTaraZ:Unload()
    end
end

pcall(MarioBanner.Step, "Systems")
if not BuildInterface() then return end
pcall(MarioBanner.Step, "Interface")
pcall(MarioBanner.Ready)
