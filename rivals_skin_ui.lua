--[[
    RIVALS SKIN UI  v1.0
    Multi-skin loader with draggable GUI

    Skins included:
      Knife / Sniper : Archrambit · ArchKeyper
      Assault Rifle  : Draconic Wildcat · Key Aug
      Vandal         : Reaver
      Satchel        : Keychel
      Various        : Monster

    Toggle visibility : RightControl
    Close button      : hides window (re-open with RightControl)
]]

------------------------------------------------------------------------
-- SERVICES
------------------------------------------------------------------------
local Players = game:GetService("Players")
local UIS     = game:GetService("UserInputService")
local TS      = game:GetService("TweenService")
local RS      = game:GetService("RunService")
local lp      = Players.LocalPlayer

local GUI_PARENT = (type(gethui) == "function" and gethui())
                or lp:WaitForChild("PlayerGui")

------------------------------------------------------------------------
-- THEME
------------------------------------------------------------------------
local C = {
    bg    = Color3.fromRGB(14,  14,  20),
    panel = Color3.fromRGB(22,  22,  32),
    item  = Color3.fromRGB(28,  28,  42),
    bdr   = Color3.fromRGB(50,  50,  72),
    text  = Color3.fromRGB(230, 230, 240),
    dim   = Color3.fromRGB(120, 120, 145),
    knife = Color3.fromRGB(255, 165, 80),
    ar    = Color3.fromRGB(80,  160, 255),
    other = Color3.fromRGB(180, 100, 255),
    idle  = Color3.fromRGB(100, 180, 255),
    busy  = Color3.fromRGB(255, 200,  60),
    done  = Color3.fromRGB(80,  220, 120),
    err   = Color3.fromRGB(255,  90,  90),
}

------------------------------------------------------------------------
-- SKIN CATALOGUE
------------------------------------------------------------------------
-- cat drives the section header grouping
local SKINS = {
    { id = "archrambit", name = "Archrambit",       weapon = "Knife",   cat = "KNIFE / SNIPER", acol = C.knife },
    { id = "archkeyper", name = "ArchKeyper",        weapon = "Sniper",  cat = "KNIFE / SNIPER", acol = C.knife },
    { id = "draconic",   name = "Draconic Wildcat",  weapon = "AR",      cat = "ASSAULT RIFLE",  acol = C.ar    },
    { id = "keyaug",     name = "Key Aug",           weapon = "AR",      cat = "ASSAULT RIFLE",  acol = C.ar    },
    { id = "reaver",     name = "Reaver Vandal",     weapon = "Vandal",  cat = "OTHER",          acol = C.other },
    { id = "keychel",    name = "Keychel",           weapon = "Satchel", cat = "OTHER",          acol = C.other },
    { id = "monster",    name = "Monster",           weapon = "Various", cat = "OTHER",          acol = C.other },
}

local STATE = {}                   -- id → "idle"|"busy"|"done"|"error"
for _, s in ipairs(SKINS) do STATE[s.id] = "idle" end

local SCRIPTS = {}                 -- populated at the bottom of this file

------------------------------------------------------------------------
-- HELPERS
------------------------------------------------------------------------
local function corner(r, p)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r)
    c.Parent = p
end

local function statColor(st)
    return C[st] or C.idle
end

local function statText(st)
    if st == "done"  then return "✓ Loaded"  end
    if st == "busy"  then return "Loading…"  end
    if st == "error" then return "✕ Error"   end
    return "Load"
end

------------------------------------------------------------------------
-- LOAD SKIN
------------------------------------------------------------------------
local function loadSkin(id)
    if STATE[id] ~= "idle" and STATE[id] ~= "error" then return end
    local src = SCRIPTS[id]
    if not src then
        warn("[RivalsUI] no script registered for: " .. id)
        STATE[id] = "error"
        return
    end
    STATE[id] = "busy"
    task.spawn(function()
        local fn, err = loadstring(src)
        if not fn then
            warn("[RivalsUI] parse error (" .. id .. "): " .. tostring(err))
            STATE[id] = "error"
            return
        end
        local ok, lerr = pcall(fn)
        if not ok then
            warn("[RivalsUI] runtime error (" .. id .. "): " .. tostring(lerr))
            STATE[id] = "error"
        else
            STATE[id] = "done"
        end
    end)
end

------------------------------------------------------------------------
-- BUILD GUI
------------------------------------------------------------------------
pcall(function()
    local prev = GUI_PARENT:FindFirstChild("RivalsSkinUI")
    if prev then prev:Destroy() end
end)

local gui = Instance.new("ScreenGui")
gui.Name           = "RivalsSkinUI"
gui.ResetOnSpawn   = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder   = 999
gui.Parent         = GUI_PARENT

-- ── Main window ────────────────────────────────────────────────────────
local win = Instance.new("Frame")
win.Name               = "Win"
win.Size               = UDim2.new(0, 310, 0, 420)
win.Position           = UDim2.new(0, 80, 0, 80)
win.BackgroundColor3   = C.bg
win.BorderSizePixel    = 0
win.ClipsDescendants   = true
win.Parent             = gui
corner(10, win)

local winStroke = Instance.new("UIStroke")
winStroke.Color     = C.bdr
winStroke.Thickness = 1
winStroke.Parent    = win

-- ── Title bar ───────────────────────────────────────────────────────────
local bar = Instance.new("Frame")
bar.Name            = "Bar"
bar.Size            = UDim2.new(1, 0, 0, 38)
bar.BackgroundColor3 = C.panel
bar.BorderSizePixel = 0
bar.Parent          = win
corner(10, bar)

-- fill lower-corner gap left by UICorner
local barFix = Instance.new("Frame")
barFix.Size             = UDim2.new(1, 0, 0, 12)
barFix.Position         = UDim2.new(0, 0, 1, -12)
barFix.BackgroundColor3 = C.panel
barFix.BorderSizePixel  = 0
barFix.Parent           = bar

local titleLbl = Instance.new("TextLabel")
titleLbl.Text                = "RIVALS SKINS"
titleLbl.Font                = Enum.Font.GothamBold
titleLbl.TextSize            = 14
titleLbl.TextColor3          = C.text
titleLbl.BackgroundTransparency = 1
titleLbl.Position            = UDim2.new(0, 14, 0, 0)
titleLbl.Size                = UDim2.new(1, -50, 1, 0)
titleLbl.TextXAlignment      = Enum.TextXAlignment.Left
titleLbl.Parent              = bar

-- RightControl hint
local hintLbl = Instance.new("TextLabel")
hintLbl.Text                = "[RCtrl] toggle"
hintLbl.Font                = Enum.Font.Gotham
hintLbl.TextSize            = 10
hintLbl.TextColor3          = C.dim
hintLbl.BackgroundTransparency = 1
hintLbl.Position            = UDim2.new(0, 14, 0.55, 0)
hintLbl.Size                = UDim2.new(0.5, 0, 0, 12)
hintLbl.TextXAlignment      = Enum.TextXAlignment.Left
hintLbl.Parent              = bar

local closeBtn = Instance.new("TextButton")
closeBtn.Text              = "✕"
closeBtn.Font              = Enum.Font.GothamBold
closeBtn.TextSize          = 13
closeBtn.TextColor3        = C.dim
closeBtn.BackgroundColor3  = Color3.fromRGB(50, 20, 20)
closeBtn.BorderSizePixel   = 0
closeBtn.AutoButtonColor   = false
closeBtn.Size              = UDim2.new(0, 24, 0, 24)
closeBtn.Position          = UDim2.new(1, -32, 0.5, -12)
closeBtn.Parent            = bar
corner(6, closeBtn)

closeBtn.MouseButton1Click:Connect(function() win.Visible = false end)
closeBtn.MouseEnter:Connect(function()
    TS:Create(closeBtn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(180,40,40)}):Play()
end)
closeBtn.MouseLeave:Connect(function()
    TS:Create(closeBtn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(50,20,20)}):Play()
end)

-- ── Scroll area ─────────────────────────────────────────────────────────
local scroll = Instance.new("ScrollingFrame")
scroll.Name                  = "Scroll"
scroll.Size                  = UDim2.new(1, 0, 1, -38)
scroll.Position              = UDim2.new(0, 0, 0, 38)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel       = 0
scroll.ScrollBarThickness    = 3
scroll.ScrollBarImageColor3  = C.bdr
scroll.CanvasSize            = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize   = Enum.AutomaticSize.Y
scroll.Parent                = win

local listLayout = Instance.new("UIListLayout")
listLayout.Padding       = UDim.new(0, 6)
listLayout.FillDirection = Enum.FillDirection.Vertical
listLayout.SortOrder     = Enum.SortOrder.LayoutOrder
listLayout.Parent        = scroll

local pad = Instance.new("UIPadding")
pad.PaddingTop    = UDim.new(0, 10)
pad.PaddingBottom = UDim.new(0, 10)
pad.PaddingLeft   = UDim.new(0, 10)
pad.PaddingRight  = UDim.new(0, 10)
pad.Parent        = scroll

-- ── Category header factory ────────────────────────────────────────────
local function mkHeader(txt, order)
    local hf = Instance.new("Frame")
    hf.Size               = UDim2.new(1, 0, 0, 24)
    hf.BackgroundTransparency = 1
    hf.LayoutOrder        = order
    hf.Parent             = scroll

    local hl = Instance.new("TextLabel")
    hl.Text               = txt
    hl.Font               = Enum.Font.GothamBold
    hl.TextSize           = 10
    hl.TextColor3         = C.dim
    hl.BackgroundTransparency = 1
    hl.Size               = UDim2.new(1, 0, 1, 0)
    hl.TextXAlignment     = Enum.TextXAlignment.Left
    hl.Parent             = hf
end

-- ── Skin row factory ───────────────────────────────────────────────────
local BTN_REFS = {}   -- id → TextButton

local function mkRow(skin, order)
    local row = Instance.new("Frame")
    row.Name             = skin.id
    row.Size             = UDim2.new(1, 0, 0, 56)
    row.BackgroundColor3 = C.item
    row.BorderSizePixel  = 0
    row.LayoutOrder      = order
    row.Parent           = scroll
    corner(8, row)

    -- left accent stripe
    local stripe = Instance.new("Frame")
    stripe.Size             = UDim2.new(0, 3, 0.65, 0)
    stripe.Position         = UDim2.new(0, 0, 0.175, 0)
    stripe.BackgroundColor3 = skin.acol
    stripe.BorderSizePixel  = 0
    stripe.Parent           = row
    corner(2, stripe)

    -- skin name
    local nameL = Instance.new("TextLabel")
    nameL.Text               = skin.name
    nameL.Font               = Enum.Font.GothamBold
    nameL.TextSize           = 14
    nameL.TextColor3         = C.text
    nameL.BackgroundTransparency = 1
    nameL.Position           = UDim2.new(0, 14, 0, 9)
    nameL.Size               = UDim2.new(0.65, 0, 0, 20)
    nameL.TextXAlignment     = Enum.TextXAlignment.Left
    nameL.Parent             = row

    -- weapon tag
    local wepL = Instance.new("TextLabel")
    wepL.Text               = skin.weapon
    wepL.Font               = Enum.Font.Gotham
    wepL.TextSize           = 11
    wepL.TextColor3         = skin.acol
    wepL.BackgroundTransparency = 1
    wepL.Position           = UDim2.new(0, 14, 0, 30)
    wepL.Size               = UDim2.new(0.65, 0, 0, 16)
    wepL.TextXAlignment     = Enum.TextXAlignment.Left
    wepL.Parent             = row

    -- load button
    local btn = Instance.new("TextButton")
    btn.Text              = statText("idle")
    btn.Font              = Enum.Font.GothamBold
    btn.TextSize          = 12
    btn.TextColor3        = Color3.fromRGB(10, 10, 20)
    btn.BackgroundColor3  = C.idle
    btn.BorderSizePixel   = 0
    btn.AutoButtonColor   = false
    btn.Size              = UDim2.new(0, 82, 0, 32)
    btn.Position          = UDim2.new(1, -92, 0.5, -16)
    btn.Parent            = row
    corner(7, btn)

    BTN_REFS[skin.id] = btn

    -- button click
    btn.MouseButton1Click:Connect(function()
        loadSkin(skin.id)
    end)

    -- hover
    btn.MouseEnter:Connect(function()
        local st = STATE[skin.id]
        if st == "idle" or st == "error" then
            TS:Create(btn, TweenInfo.new(0.12),
                {BackgroundColor3 = Color3.fromRGB(130, 200, 255)}):Play()
        end
    end)
    btn.MouseLeave:Connect(function()
        TS:Create(btn, TweenInfo.new(0.12),
            {BackgroundColor3 = statColor(STATE[skin.id])}):Play()
    end)
end

-- ── Populate list ──────────────────────────────────────────────────────
local order   = 1
local prevCat = nil
for _, skin in ipairs(SKINS) do
    if skin.cat ~= prevCat then
        mkHeader(skin.cat, order)
        order  = order + 1
        prevCat = skin.cat
    end
    mkRow(skin, order)
    order = order + 1
end

-- ── Poll state → update buttons ───────────────────────────────────────
RS.Heartbeat:Connect(function()
    for _, skin in ipairs(SKINS) do
        local btn = BTN_REFS[skin.id]
        if btn then
            local st  = STATE[skin.id]
            local col = statColor(st)
            if btn.BackgroundColor3 ~= col then
                btn.BackgroundColor3 = col
                btn.Text             = statText(st)
            end
        end
    end
end)

------------------------------------------------------------------------
-- DRAGGING
------------------------------------------------------------------------
local dragging, dragStart, winStart = false, nil, nil

bar.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1
    or inp.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = inp.Position
        winStart  = win.Position
    end
end)

UIS.InputChanged:Connect(function(inp)
    if not dragging then return end
    if inp.UserInputType == Enum.UserInputType.MouseMovement
    or inp.UserInputType == Enum.UserInputType.Touch then
        local d = inp.Position - dragStart
        win.Position = UDim2.new(
            winStart.X.Scale, winStart.X.Offset + d.X,
            winStart.Y.Scale, winStart.Y.Offset + d.Y
        )
    end
end)

UIS.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1
    or inp.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

------------------------------------------------------------------------
-- TOGGLE KEY
------------------------------------------------------------------------
UIS.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.KeyCode == Enum.KeyCode.RightControl then
        win.Visible = not win.Visible
    end
end)

------------------------------------------------------------------------
-- ╔══════════════════════════════════════════════════════════════════╗
-- ║                        SKIN SCRIPTS                              ║
-- ║  Each script is the original source stored as a Lua string and   ║
-- ║  executed via loadstring() when the player clicks Load.          ║
-- ╚══════════════════════════════════════════════════════════════════╝
------------------------------------------------------------------------

------------------------------------------------------------------------
-- 1. ARCHRAMBIT  (Knife  — Keyrambit cosmetic unlocker + green enforcer
--                         + Archrambit mesh/texture/anim replacer)
------------------------------------------------------------------------
SCRIPTS.archrambit = [====[
local frontOk, frontErr = pcall(function()
local KEYWORD = "keyrambit"
local PICK    = nil
local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local lp      = Players.LocalPlayer
local ctrl = lp.PlayerScripts:WaitForChild("Controllers", 10)
local mods = RS:WaitForChild("Modules", 10)
local enumLib = require(mods:WaitForChild("EnumLibrary", 10))
if enumLib then pcall(function() enumLib:WaitForEnumBuilder() end) end
local cosLib  = require(mods:WaitForChild("CosmeticLibrary", 10))
local datCtrl = require(ctrl:WaitForChild("PlayerDataController", 10))
local Cosmetics = cosLib.Cosmetics
local function wepName(w) if type(w)=="table" then w=w.Name end return w end
local function isKnife(w)
    w=wepName(w); if type(w)~="string" then return false end
    return (w:lower():gsub("%s+",""))=="knife"
end
local function isKeyName(n)
    return type(n)=="string" and (n:lower():gsub("%s+","")):find(KEYWORD,1,true)~=nil
end
local function isKeySkin(n)
    local c=isKeyName(n) and Cosmetics[n]
    return c and c.Type=="Skin" or false
end
local function mkSkin(name)
    local base=Cosmetics[name]; if not base then return nil end
    local d={}; for k,v in pairs(base) do d[k]=v end
    d.Name=name; d.Type=d.Type or "Skin"; d.Seed=d.Seed or math.random(1,1000000)
    if enumLib then
        local ok,id=pcall(enumLib.ToEnum,enumLib,name)
        if ok and id then d.Enum=id; d.ObjectID=d.ObjectID or id end
    end
    return d
end
local matches={}
for name,c in pairs(Cosmetics) do
    if type(name)=="string" and c.Type=="Skin" and isKeyName(name) then
        table.insert(matches,name)
    end
end
table.sort(matches)
if #matches==0 then warn("[Knife-Key] no skins containing '"..KEYWORD.."' found"); return end
local chosen=matches[1]
if PICK and isKeySkin(PICK) then chosen=PICK end
local knifeSkin=mkSkin(chosen)
print(("[Knife-Key] %d matching skin(s); equipping '%s'"):format(#matches,chosen))
for _,key in ipairs({"OwnsCosmetic","OwnsCosmeticNormally","OwnsCosmeticUniversally","OwnsCosmeticForWeapon"}) do
    local orig=cosLib[key]
    if type(orig)=="function" then
        cosLib[key]=function(self,inv,nm,wep,...)
            if isKnife(wep) and isKeySkin(nm) then return true end
            return orig(self,inv,nm,wep,...)
        end
    end
end
local origGet=datCtrl.Get
datCtrl.Get=function(self,key,...)
    local val=origGet(self,key,...)
    if key=="CosmeticInventory" then
        local prx={}
        if val then for k,v in pairs(val) do prx[k]=v end end
        return setmetatable(prx,{__index=function(_,k) if isKeySkin(k) then return true end return nil end})
    end
    return val
end
local origGetWep=datCtrl.GetWeaponData
datCtrl.GetWeaponData=function(self,wn,...)
    local d=origGetWep(self,wn,...)
    if not d then return nil end
    if isKnife(wn) and knifeSkin then
        local m={}; for k,v in pairs(d) do m[k]=v end
        m.Name=wn; m.Skin=knifeSkin; return m
    end
    return d
end
if hookmetamethod and getnamecallmethod then
    local remotes=RS:FindFirstChild("Remotes")
    local dataRem=remotes and remotes:FindFirstChild("Data")
    local equipRem=dataRem and dataRem:FindFirstChild("EquipCosmetic")
    if equipRem then
        local old
        old=hookmetamethod(game,"__namecall",function(self,...)
            if self==equipRem and getnamecallmethod()=="FireServer" then
                local a={...}; local wn,ct,cn=a[1],a[2],a[3]
                if isKnife(wn) and ct=="Skin" and isKeySkin(cn) then
                    knifeSkin=mkSkin(cn)
                    task.defer(function() pcall(function() datCtrl.CurrentData:Replicate("WeaponInventory") end) end)
                    return
                end
            end
            return old(self,...)
        end)
    end
else
    warn("[Knife-Key] hookmetamethod not available; UI equips will still hit the server")
end
local function applySkin(data,enumFn)
    if not (knifeSkin and data) then return end
    if enumFn then data[enumFn("Skin")]=knifeSkin; data[enumFn("Name")]=knifeSkin.Name
    else data.Skin=knifeSkin; data.Name=knifeSkin.Name end
end
local buildingWep
local cliItem
pcall(function() cliItem=require(lp.PlayerScripts.Modules.ClientReplicatedClasses.ClientFighter.ClientItem) end)
if cliItem and cliItem._CreateViewModel then
    local origCVM=cliItem._CreateViewModel
    cliItem._CreateViewModel=function(self,vmRef,...)
        local owner=self.ClientFighter and self.ClientFighter.Player
        buildingWep=(owner==lp) and self.Name or nil
        if owner==lp and isKnife(self.Name) then
            local dk=self:ToEnum("Data")
            if vmRef[dk] then applySkin(vmRef[dk],function(n) return self:ToEnum(n) end)
            elseif vmRef.Data then applySkin(vmRef.Data) end
        end
        local r=origCVM(self,vmRef,...); buildingWep=nil; return r
    end
end
pcall(function()
    local vmMod=lp.PlayerScripts.Modules.ClientReplicatedClasses.ClientFighter.ClientItem:FindFirstChild("ClientViewModel")
    if not vmMod then return end
    local CVM=require(vmMod)
    local origNew=CVM.new
    CVM.new=function(repData,cliItm,...)
        local owner=cliItm.ClientFighter and cliItm.ClientFighter.Player
        local wn=buildingWep or cliItm.Name
        if owner==lp and isKnife(wn) and knifeSkin then
            local RC=require(RS.Modules.ReplicatedClass)
            local dk=RC:ToEnum("Data")
            repData[dk]=repData[dk] or {}
            repData[dk][RC:ToEnum("Skin")]=knifeSkin
        end
        return origNew(repData,cliItm,...)
    end
end)
task.defer(function() pcall(function() datCtrl.CurrentData:Replicate("WeaponInventory") end) end)
print("[Knife-Key] loaded")
end)
if not frontOk then warn("[Knife-Key] front block failed: "..tostring(frontErr)) end

local GREEN=Color3.fromRGB(110,255,140)
local GREEN_ALL_CAMERA=false
pcall(function()
    local Players=game:GetService("Players"); local lp=Players.LocalPlayer
    local ws=game:GetService("Workspace"); local tinted=setmetatable({},{__mode="k"})
    local function nameHit(inst)
        local p=inst
        for _=1,10 do
            if not p or p==ws then break end
            local n=p.Name:lower()
            if n:find("knife",1,true) or n:find("rambit",1,true) then return true end
            p=p.Parent
        end
        return false
    end
    local function inMine(inst)
        local cam=ws.CurrentCamera
        return (cam and inst:IsDescendantOf(cam)) or (lp.Character and inst:IsDescendantOf(lp.Character))
    end
    local function tint(inst)
        if tinted[inst] or not (inst:IsA("MeshPart") or inst:IsA("SpecialMesh")) then return end
        if not inMine(inst) then return end
        if not (GREEN_ALL_CAMERA or nameHit(inst)) then return end
        tinted[inst]=true
        local prop=inst:IsA("MeshPart") and "Color" or "VertexColor"
        local function set()
            pcall(function()
                if prop=="Color" then inst.Color=GREEN
                else inst.VertexColor=Vector3.new(GREEN.R,GREEN.G,GREEN.B) end
            end)
        end
        set()
        pcall(function() inst:GetPropertyChangedSignal(prop):Connect(set) end)
    end
    ws.DescendantAdded:Connect(function(d) task.defer(tint,d) end)
    task.spawn(function()
        while true do
            local cam=ws.CurrentCamera
            if cam then for _,d in ipairs(cam:GetDescendants()) do tint(d) end end
            if lp.Character then for _,d in ipairs(lp.Character:GetDescendants()) do tint(d) end end
            task.wait(0.5)
        end
    end)
end)

local MESH_URL    = "https://raw.githubusercontent.com/mrbeanissohot/Archrambit/main/archrambiyt.mesh"
local TEXTURE_URL = "https://raw.githubusercontent.com/mrbeanissohot/Archrambit/main/arch_texture.png"
local MESH_CACHE    = "Archrambit/archrambiyt.mesh"
local TEXTURE_CACHE = "Archrambit/arch_texture.png"
local CONFIG=[==[
{"replacement_rules":[
  {"name":"re","replace_ids":[12482022259,12482022363],"mode":"id","enabled":true},
  {"name":"xd","replace_ids":[105653154583773],"mode":"local","enabled":true,"local_path":"Archrambit/archrambiyt.mesh"},
  {"name":"an","replace_ids":[12613363718],"mode":"id","enabled":true,"with_id":18742841521},
  {"name":"in / inspect","replace_ids":[12613329711],"mode":"id","enabled":true,"with_id":18742879471},
  {"name":"hravy","replace_ids":[12613354440],"mode":"id","enabled":true,"with_id":18742868264},
  {"name":"idle","replace_ids":[12613190591],"mode":"id","enabled":true,"with_id":18742849437},
  {"name":"sprint","replace_ids":[12886796453],"mode":"id","enabled":true,"with_id":18742894186}
]}
]==]
local URL_FOR_PATH={[MESH_CACHE]=MESH_URL,[TEXTURE_CACHE]=TEXTURE_URL}
local SCALE=1.45
local SCALE_BY_ID={}
local HttpService=game:GetService("HttpService")
local AssetService=game:GetService("AssetService")
local rules=HttpService:JSONDecode(CONFIG).replacement_rules
local lookup,cache,meshCache={},{},{}
local registered,skipped,swapped=0,0,0
local function parseId(v) return tonumber(tostring(v):match("(%d+)")) end
local function download(url,path)
    local body
    local req=request or http_request or (syn and syn.request) or (http and http.request)
    if req then
        local ok,res=pcall(req,{Url=url,Method="GET"})
        if ok and res and res.Success~=false and (res.StatusCode==nil or res.StatusCode==200) then body=res.Body end
    end
    if not body then local ok,res=pcall(function() return game:HttpGet(url,true) end); if ok then body=res end end
    if not body or #body==0 then return false end
    pcall(function()
        local folder=path:match("^(.*)/[^/]+$")
        if folder and makefolder and not isfolder(folder) then makefolder(folder) end
    end)
    return (pcall(writefile,path,body))
end
local function loadAsset(path)
    if cache[path] then return cache[path] end
    local url=URL_FOR_PATH[path]
    if url then if not download(url,path) then warn("[Replacer] download failed: "..url..(isfile(path) and " (using cached copy)" or "")) end end
    for _=1,5 do
        if isfile(path) then
            local ok,asset=pcall(getcustomasset,path)
            if ok and asset then cache[path]=asset; return asset end
        end
        task.wait(0.3)
    end
    return nil
end
local function resolve(rule)
    if rule.mode=="local" then
        local asset=loadAsset(rule.local_path)
        if not asset then warn("[Replacer] failed to load: "..rule.local_path) end
        return asset
    end
    if rule.with_id then return "rbxassetid://"..rule.with_id end
    return ""
end
local function register(rule)
    if rule.type=="group" then for _,c in ipairs(rule.children or {}) do register(c) end
    elseif rule.enabled then
        local target=resolve(rule)
        if target==nil then skipped=skipped+1; return end
        registered=registered+1
        for _,id in ipairs(rule.replace_ids) do local n=parseId(id); if n then lookup[n]=target end end
    end
end
for _,r in ipairs(rules) do register(r) end
print(("[Replacer] rules registered: %d, skipped: %d"):format(registered,skipped))
local TEXTURE=loadAsset(TEXTURE_CACHE)
if not TEXTURE then warn("[Replacer] texture not loaded: "..TEXTURE_URL) end
local PROPS={MeshPart={"MeshId"},SpecialMesh={"MeshId"},Animation={"AnimationId"},Sound={"SoundId"},Decal={"Texture"},Texture={"Texture"},ImageLabel={"Image"},ImageButton={"Image"}}
local seen=setmetatable({},{__mode="k"})
local lastScaled=setmetatable({},{__mode="k"})
local watched=setmetatable({},{__mode="k"})
local fitted=setmetatable({},{__mode="k"})
local function scaleMesh(inst,mult)
    local m=mult or SCALE; if m==1 then return end
    pcall(function()
        if inst:IsA("MeshPart") then
            local last=lastScaled[inst]; if last and (inst.Size-last).Magnitude<0.001 then return end
            local target=inst.Size*m; inst.Size=target; lastScaled[inst]=target
        elseif inst:IsA("SpecialMesh") then
            local last=lastScaled[inst]; if last and (inst.Scale-last).Magnitude<0.001 then return end
            local target=inst.Scale*m; inst.Scale=target; lastScaled[inst]=target
        end
    end)
end
local function hideMesh(inst)
    pcall(function()
        if inst:IsA("MeshPart") then inst.Transparency=1
        elseif inst:IsA("SpecialMesh") then inst.Scale=Vector3.new(0,0,0) end
    end)
end
local function applyMesh(inst,asset)
    if inst:IsA("MeshPart") then
        local ok,err=pcall(function()
            local mp=meshCache[asset]
            if not mp then mp=AssetService:CreateMeshPartAsync(asset); meshCache[asset]=mp end
            inst:ApplyMesh(mp)
        end)
        if not ok then warn("[Replacer] ApplyMesh failed: "..tostring(err)); pcall(function() inst.MeshId=asset end) end
    else pcall(function() inst.MeshId=asset end) end
end
local function fitMesh(inst,asset,mult)
    if not inst:IsA("MeshPart") then scaleMesh(inst,mult); return end
    if not fitted[inst] then fitted[inst]=inst.Size end
    local ref=fitted[inst]
    task.spawn(function()
        task.wait(0.1)
        pcall(function()
            local mp=meshCache[asset]; if not mp then return end
            local nat=mp.Size
            local f=math.max(ref.X,ref.Y,ref.Z)/math.max(nat.X,nat.Y,nat.Z)
            inst.Size=nat*f*(mult or SCALE)
        end)
    end)
end
local function forceGreen(inst)
    pcall(function()
        if inst:IsA("MeshPart") then inst.Color=GREEN
        elseif inst:IsA("SpecialMesh") then inst.VertexColor=Vector3.new(GREEN.R,GREEN.G,GREEN.B) end
    end)
end
local function applyTexture(inst)
    local prop=inst:IsA("MeshPart") and "TextureID" or "TextureId"
    if TEXTURE then pcall(function() inst[prop]=TEXTURE end) end
    forceGreen(inst)
    for _,c in ipairs(inst:GetChildren()) do if c:IsA("SurfaceAppearance") then c:Destroy() end end
    if not watched[inst] then
        watched[inst]=true
        inst.ChildAdded:Connect(function(c) if c:IsA("SurfaceAppearance") then task.defer(function() pcall(function() c:Destroy() end) end) end end)
        pcall(function() inst:GetPropertyChangedSignal(prop):Connect(function() if TEXTURE and inst[prop]~=TEXTURE then pcall(function() inst[prop]=TEXTURE end) end end) end)
        pcall(function()
            local cp=inst:IsA("MeshPart") and "Color" or "VertexColor"
            inst:GetPropertyChangedSignal(cp):Connect(function() forceGreen(inst) end)
        end)
    end
end
local function handle(inst,p)
    local ok,cur=pcall(function() return inst[p] end); if not ok then return end
    local id=parseId(cur); local new=id and lookup[id]; if new==nil then return end
    swapped=swapped+1
    if swapped<=10 then print("[Replacer] swapped "..inst.ClassName.."."..p.." ("..tostring(id)..")") end
    if p=="MeshId" then
        if new=="" then hideMesh(inst)
        else applyMesh(inst,new); fitMesh(inst,new,SCALE_BY_ID[id]); applyTexture(inst) end
    else pcall(function() inst[p]=new end) end
end
local function apply(inst)
    local props=PROPS[inst.ClassName]; if not props or seen[inst] then return end
    seen[inst]=true
    for _,p in ipairs(props) do
        handle(inst,p)
        pcall(function() inst:GetPropertyChangedSignal(p):Connect(function() handle(inst,p) end) end)
    end
end
local function scan()
    local n=0
    for _,d in ipairs(game:GetDescendants()) do
        apply(d); n=n+1; if n%2000==0 then task.wait() end
    end
end
scan()
game.DescendantAdded:Connect(apply)
task.spawn(function() while true do task.wait(5); scan() end end)
print("[Replacer] loaded")
]====]

------------------------------------------------------------------------
-- 2. ARCHKEYPER  (Sniper — mesh + void-event-horizon animation pack)
------------------------------------------------------------------------
SCRIPTS.archkeyper = [====[
local CONFIG=[==[
{"replacement_rules":[
  {"name":"Profile 1","replace_ids":[13188892761],"mode":"local","enabled":true,"url":"https://github.com/mrbeanissohot/ArchKeyperr/blob/main/arch_keyper_v4.mesh"},
  {"name":"Profile 2","replace_ids":[14778413014,13188893115,13188893017,14774727092,13188892855,13188893310,14002915797,13188892651,13188892532],"mode":"id","enabled":true},
  {"name":"Equip",       "replace_ids":[13269929260],"mode":"cdn","enabled":true,"cdn_url":"https://cdn.jsdelivr.net/gh/Plusnoctonia/Void-Sniper-Event-Horizon@main/EventHorizonEquip.rbxm"},
  {"name":"Idle",        "replace_ids":[13269931582],"mode":"cdn","enabled":true,"cdn_url":"https://cdn.jsdelivr.net/gh/Plusnoctonia/Void-Sniper-Event-Horizon@main/EventHorizonIdle.rbxm"},
  {"name":"Sprint",      "replace_ids":[13321899382],"mode":"cdn","enabled":true,"cdn_url":"https://cdn.jsdelivr.net/gh/Plusnoctonia/Void-Sniper-Event-Horizon@main/EventHorizonSprint.rbxm"},
  {"name":"Inspect",     "replace_ids":[13269934368],"mode":"cdn","enabled":true,"cdn_url":"https://cdn.jsdelivr.net/gh/Plusnoctonia/Void-Sniper-Event-Horizon@main/EventHorizonInspect.rbxm"},
  {"name":"Shoot",       "replace_ids":[13269963346],"mode":"cdn","enabled":true,"cdn_url":"https://cdn.jsdelivr.net/gh/Plusnoctonia/Void-Sniper-Event-Horizon@main/EventHorizonShoot.rbxm"},
  {"name":"Reload",      "replace_ids":[13642104835],"mode":"cdn","enabled":true,"cdn_url":"https://cdn.jsdelivr.net/gh/Plusnoctonia/Void-Sniper-Event-Horizon@main/EventHorizonReload.rbxm"},
  {"name":"ReloadEmpty", "replace_ids":[13269951125],"mode":"cdn","enabled":true,"cdn_url":"https://cdn.jsdelivr.net/gh/Plusnoctonia/Void-Sniper-Event-Horizon@main/EventHorizonEmptyReload.rbxm"}
]}
]==]
local CACHE_DIR = "AWildcat"
local HttpService=game:GetService("HttpService")
local AssetService=game:GetService("AssetService")
local Players=game:GetService("Players")
local rules=HttpService:JSONDecode(CONFIG).replacement_rules
local lookup,cache,meshCache,animCache={},{},{},{}
local registered,skipped,swapped=0,0,0
local function parseId(v) return tonumber(tostring(v):match("(%d+)")) end
local function toRaw(url) return (url:gsub("github%.com/([^/]+)/([^/]+)/blob/","raw.githubusercontent.com/%1/%2/")) end
local function cachePathFor(url) local name=url:match("([^/]+)$"):gsub("%%20","_"); return CACHE_DIR.."/"..name end
local function download(url,path)
    if isfile(path) then return true end
    local ok,body=pcall(function() return game:HttpGet(toRaw(url)) end)
    if not ok or type(body)~="string" or #body==0 then warn("[ArchKeyper] download failed: "..url); return false end
    if makefolder and isfolder and not isfolder(CACHE_DIR) then pcall(makefolder,CACHE_DIR) end
    return (pcall(writefile,path,body))
end
local function loadAsset(path)
    if cache[path] then return cache[path] end
    for _=1,5 do
        if isfile(path) then local ok,a=pcall(getcustomasset,path); if ok and a then cache[path]=a; return a end end
        task.wait(0.3)
    end
    return nil
end
local function loadAnim(url)
    if animCache[url] then return animCache[url] end
    local path=cachePathFor(url)
    download(url,path)
    local ok,objs=pcall(function() return game:GetObjects(loadAsset(path)) end)
    if not ok or type(objs)~="table" then return nil end
    local kfs=nil
    for _,o in ipairs(objs) do
        if o:IsA("KeyframeSequence") then kfs=o; break end
        local c=o:FindFirstChildWhichIsA("KeyframeSequence",true); if c then kfs=c; break end
    end
    if not kfs then return nil end
    if kfs.Priority==Enum.AnimationPriority.Idle or kfs.Priority==Enum.AnimationPriority.Movement or kfs.Priority==Enum.AnimationPriority.Core then
        kfs.Priority=Enum.AnimationPriority.Action4
    end
    local ok2,id=pcall(function() return game:GetService("KeyframeSequenceProvider"):RegisterKeyframeSequence(kfs) end)
    if ok2 and id and tostring(id)~="" then animCache[url]=id; return id end
    return nil
end
local function resolve(rule)
    if rule.mode=="local" then
        local path=cachePathFor(rule.url); download(rule.url,path); return loadAsset(path)
    end
    if rule.mode=="cdn" then
        -- try animation first
        local id=loadAnim(rule.cdn_url)
        if id then return id end
        -- else treat as regular asset
        local path=cachePathFor(rule.cdn_url); download(rule.cdn_url,path); return loadAsset(path)
    end
    if rule.with_id then return "rbxassetid://"..rule.with_id end
    return ""
end
local function register(rule)
    if rule.type=="group" then for _,c in ipairs(rule.children or {}) do register(c) end
    elseif rule.enabled then
        local target=resolve(rule)
        if target==nil then skipped=skipped+1; return end
        registered=registered+1
        for _,id in ipairs(rule.replace_ids) do local n=parseId(id); if n then lookup[n]=target end end
    end
end
for _,r in ipairs(rules) do register(r) end
print(("[ArchKeyper] rules registered: %d, skipped: %d"):format(registered,skipped))
local PROPS={MeshPart={"MeshId"},SpecialMesh={"MeshId"},Animation={"AnimationId"},Sound={"SoundId"},Decal={"Texture"},Texture={"Texture"},ImageLabel={"Image"},ImageButton={"Image"}}
local seen=setmetatable({},{__mode="k"})
local function handle(inst,p)
    local ok,cur=pcall(function() return inst[p] end); if not ok then return end
    local id=parseId(cur); local new=id and lookup[id]; if new==nil then return end
    swapped=swapped+1
    if swapped<=10 then print("[ArchKeyper] swapped "..inst.ClassName.."."..p.." ("..tostring(id)..")") end
    pcall(function() inst[p]=new end)
end
local function apply(inst)
    local props=PROPS[inst.ClassName]; if not props or seen[inst] then return end
    seen[inst]=true
    for _,p in ipairs(props) do handle(inst,p); pcall(function() inst:GetPropertyChangedSignal(p):Connect(function() handle(inst,p) end) end) end
end
local function scan() local n=0; for _,d in ipairs(game:GetDescendants()) do apply(d); n=n+1; if n%2000==0 then task.wait() end end end
scan(); game.DescendantAdded:Connect(apply)
task.spawn(function() while true do task.wait(5); scan() end end)
print("[ArchKeyper] loaded")
]====]

------------------------------------------------------------------------
-- 3. DRACONIC WILDCAT  (AR — mesh + texture + sound replacer)
------------------------------------------------------------------------
SCRIPTS.draconic = [====[
local CONFIG=[==[
{"replacement_rules":[
  {"name":"ar15-body","replace_ids":[83884702080665],"mode":"local","enabled":true,"url":"https://github.com/mrbeanissohot/DraconicWildcat/blob/main/roar.mesh"},
  {"name":"Profile 6","replace_ids":[13158330555],"mode":"local","enabled":true,"url":"https://github.com/mrbeanissohot/DraconicWildcat/blob/main/draload.mp3"},
  {"name":"Reload 2?","replace_ids":[13236549962],"mode":"id","enabled":true},
  {"name":"Profile 9","replace_ids":[13158735106],"mode":"local","enabled":true,"url":"https://github.com/mrbeanissohot/DraconicWildcat/blob/main/m4a1 dragon.mp3"},
  {"name":"remove","replace_ids":[75392286602848,131204076200915,85569047699564],"mode":"id","enabled":true},
  {"name":"Profile 10","replace_ids":[72815891526849,134260292117186,101461115963186],"mode":"local","enabled":true,"url":"https://github.com/mrbeanissohot/DraconicWildcat/blob/main/bow_dreag.mp3"},
  {"name":"Profile 12","replace_ids":[88813579505134],"mode":"id","enabled":true,"with_id":13010870236},
  {"name":"Profile 13","replace_ids":[88813579505134],"mode":"id","enabled":true,"with_id":13010885336},
  {"name":"Profile 14","replace_ids":[120946011201823],"mode":"id","enabled":true,"with_id":13010893629},
  {"name":"Profile 17","replace_ids":[92222928077393],"mode":"id","enabled":true,"with_id":13010870236},
  {"name":"Profile 18","replace_ids":[134773461791727],"mode":"id","enabled":true,"with_id":13010885336},
  {"name":"Profile 19","replace_ids":[135764895692827],"mode":"id","enabled":true,"with_id":13010904196},
  {"name":"mag 2","replace_ids":[95562281570535],"mode":"local","enabled":true,"url":"https://github.com/mrbeanissohot/DraconicWildcat/blob/main/magazine_roar.mesh"},
  {"name":"low","replace_ids":[77401164737509],"mode":"local","enabled":true,"url":"https://github.com/mrbeanissohot/DraconicWildcat/blob/main/dragon_thumbnail.png"},
  {"name":"high","replace_ids":[124155708481848],"mode":"local","enabled":true,"url":"https://github.com/mrbeanissohot/DraconicWildcat/blob/main/dragon_gun_thumbnail_2.png"},
  {"name":"up mag remo","replace_ids":[83070615292783],"mode":"id","enabled":true}
]}
]==]
local SCALE=2
local SCALE_BY_ID={[95562281570535]=1.3}
local VOLUME={[13158330555]=2.5,[13158735106]=0.4}
local TEXTURE_URL_BY_ID={
    [83884702080665]="https://github.com/mrbeanissohot/DraconicWildcat/blob/main/roar_texture_2048.png",
    [95562281570535]="https://github.com/mrbeanissohot/DraconicWildcat/blob/main/magazine_texture_2048.png",
}
local CACHE_DIR="AWildcat"
local function toRaw(url) return (url:gsub("github%.com/([^/]+)/([^/]+)/blob/","raw.githubusercontent.com/%1/%2/")) end
local function cachePathFor(url) local name=url:match("([^/]+)$"):gsub("%%20","_"); return CACHE_DIR.."/"..name end
local function download(url,path)
    if isfile(path) then return true end
    local ok,body=pcall(function() return game:HttpGet(toRaw(url)) end)
    if not ok or type(body)~="string" or #body==0 then warn("[Draconic] download failed: "..url); return false end
    if makefolder and isfolder and not isfolder(CACHE_DIR) then pcall(makefolder,CACHE_DIR) end
    return (pcall(writefile,path,body))
end
local HttpService=game:GetService("HttpService")
local AssetService=game:GetService("AssetService")
local rules=HttpService:JSONDecode(CONFIG).replacement_rules
local lookup,cache,meshCache={},{},{}
local registered,skipped,swapped=0,0,0
local function parseId(v) return tonumber(tostring(v):match("(%d+)")) end
local function loadAsset(path)
    if cache[path] then return cache[path] end
    for _=1,5 do
        if isfile(path) then local ok,a=pcall(getcustomasset,path); if ok and a then cache[path]=a; return a end end
        task.wait(0.3)
    end
    return nil
end
local TEXTURES={}
for id,url in pairs(TEXTURE_URL_BY_ID) do
    local path=cachePathFor(url); download(url,path)
    local asset=loadAsset(path)
    if asset then TEXTURES[id]=asset else warn("[Draconic] texture not loaded: "..url) end
end
local function resolve(rule)
    if rule.mode=="local" then
        local path=cachePathFor(rule.url); download(rule.url,path)
        local asset=loadAsset(path); if not asset then warn("[Draconic] failed to load: "..rule.url) end; return asset
    end
    if rule.with_id then return "rbxassetid://"..rule.with_id end
    return ""
end
local function register(rule)
    if rule.type=="group" then for _,c in ipairs(rule.children or {}) do register(c) end
    elseif rule.enabled then
        local target=resolve(rule)
        if target==nil then skipped=skipped+1; return end
        registered=registered+1
        for _,id in ipairs(rule.replace_ids) do local n=parseId(id); if n then lookup[n]=target end end
    end
end
for _,r in ipairs(rules) do register(r) end
print(("[Draconic] rules registered: %d, skipped: %d"):format(registered,skipped))
local PROPS={MeshPart={"MeshId","TextureID"},SpecialMesh={"MeshId","TextureId"},Sound={"SoundId"},Decal={"Texture"},Texture={"Texture"},ImageLabel={"Image"},ImageButton={"Image"},SurfaceAppearance={"ColorMap","NormalMap","MetalnessMap","RoughnessMap"}}
local seen=setmetatable({},{__mode="k"})
local watched=setmetatable({},{__mode="k"})
local lastScaled=setmetatable({},{__mode="k"})
local volState=setmetatable({},{__mode="k"})
local texFor=setmetatable({},{__mode="k"})
local function scaleMesh(inst,mult)
    local m=mult or SCALE
    pcall(function()
        if inst:IsA("MeshPart") then
            local last=lastScaled[inst]; if last and (inst.Size-last).Magnitude<0.001 then return end
            local target=inst.Size*m; inst.Size=target; lastScaled[inst]=target
        elseif inst:IsA("SpecialMesh") then
            local last=lastScaled[inst]; if last and (inst.Scale-last).Magnitude<0.001 then return end
            local target=inst.Scale*m; inst.Scale=target; lastScaled[inst]=target
        end
    end)
end
local function applyVolume(inst,mult)
    if not mult then return end
    pcall(function()
        local st=volState[inst]
        if not st then
            st={mult=mult,target=inst.Volume}; volState[inst]=st
            inst:GetPropertyChangedSignal("Volume"):Connect(function()
                if math.abs(inst.Volume-st.target)>0.001 then
                    st.target=math.clamp(inst.Volume*st.mult,0,10); inst.Volume=st.target
                end
            end)
        end
        if math.abs(inst.Volume-st.target)>0.001 or (st.target==inst.Volume and not st.done) then
            st.target=math.clamp(inst.Volume*mult,0,10); inst.Volume=st.target; st.done=true
        end
    end)
end
local function applyTexture(inst,tex)
    if not tex then return end; texFor[inst]=tex
    pcall(function() if inst:IsA("MeshPart") then inst.TextureID=tex else inst.TextureId=tex end end)
    for _,c in ipairs(inst:GetChildren()) do if c:IsA("SurfaceAppearance") then c:Destroy() end end
    if not watched[inst] then
        watched[inst]=true
        inst.ChildAdded:Connect(function(c) if c:IsA("SurfaceAppearance") then task.defer(function() pcall(function() c:Destroy() end) end) end end)
        local prop=inst:IsA("MeshPart") and "TextureID" or "TextureId"
        pcall(function() inst:GetPropertyChangedSignal(prop):Connect(function()
            local want=texFor[inst]; if want and inst[prop]~=want then pcall(function() inst[prop]=want end) end
        end) end)
    end
end
local function hideMesh(inst)
    pcall(function() if inst:IsA("MeshPart") then inst.Transparency=1 elseif inst:IsA("SpecialMesh") then inst.Scale=Vector3.new(0,0,0) end end)
end
local function applyMesh(inst,asset)
    if inst:IsA("MeshPart") then
        local ok,err=pcall(function()
            local mp=meshCache[asset]; if not mp then mp=AssetService:CreateMeshPartAsync(asset); meshCache[asset]=mp end
            inst:ApplyMesh(mp)
        end)
        if not ok then warn("[Draconic] ApplyMesh failed: "..tostring(err)); pcall(function() inst.MeshId=asset end) end
    else pcall(function() inst.MeshId=asset end) end
end
local function handle(inst,p)
    local ok,cur=pcall(function() return inst[p] end); if not ok then return end
    local id=parseId(cur); local new=id and lookup[id]; if new==nil then return end
    swapped=swapped+1
    if swapped<=10 then print("[Draconic] swapped "..inst.ClassName.."."..p.." ("..tostring(id)..")") end
    if p=="MeshId" then
        if new=="" then hideMesh(inst)
        else applyMesh(inst,new); scaleMesh(inst,SCALE_BY_ID[id]); applyTexture(inst,TEXTURES[id]) end
    else
        pcall(function() inst[p]=new end)
        if p=="SoundId" then applyVolume(inst,VOLUME[id]) end
    end
end
local function apply(inst)
    local props=PROPS[inst.ClassName]; if not props or seen[inst] then return end
    seen[inst]=true
    for _,p in ipairs(props) do handle(inst,p); pcall(function() inst:GetPropertyChangedSignal(p):Connect(function() handle(inst,p) end) end) end
end
local function scan() local n=0; for _,d in ipairs(game:GetDescendants()) do apply(d); n=n+1; if n%2000==0 then task.wait() end end end
scan(); game.DescendantAdded:Connect(apply)
task.spawn(function() while true do task.wait(5); scan() end end)
print("[Draconic] loaded")
]====]

------------------------------------------------------------------------
-- 4. KEY AUG  (AR — cosmetic unlocker + CDN mesh/sound replacer)
------------------------------------------------------------------------
SCRIPTS.keyaug = [====[
local frontOk, frontErr = pcall(function()
local KEYWORD="aug"; local PICK=nil
local Players=game:GetService("Players"); local RS=game:GetService("ReplicatedStorage"); local lp=Players.LocalPlayer
local ctrl=lp.PlayerScripts:WaitForChild("Controllers",10); local mods=RS:WaitForChild("Modules",10)
local enumLib=require(mods:WaitForChild("EnumLibrary",10))
if enumLib then pcall(function() enumLib:WaitForEnumBuilder() end) end
local cosLib=require(mods:WaitForChild("CosmeticLibrary",10))
local datCtrl=require(ctrl:WaitForChild("PlayerDataController",10))
local Cosmetics=cosLib.Cosmetics
local arCache,augCache={},{}
local function isAR(w)
    if type(w)=="table" then w=w.Name end; if type(w)~="string" then return false end
    local r=arCache[w]; if r==nil then r=(w:lower():gsub("%s+",""))=="assaultrifle"; arCache[w]=r end; return r
end
local function isAugSkin(n)
    if type(n)~="string" then return false end
    local r=augCache[n]; if r==nil then local c=Cosmetics[n]; r=(n:lower():find(KEYWORD,1,true)~=nil) and c~=nil and c.Type=="Skin"; augCache[n]=r end; return r
end
local function mkSkin(name)
    local base=Cosmetics[name]; if not base then return nil end
    local d={}; for k,v in pairs(base) do d[k]=v end
    d.Name=name; d.Type=d.Type or "Skin"; d.Seed=d.Seed or math.random(1,1000000)
    if enumLib then local ok,id=pcall(enumLib.ToEnum,enumLib,name); if ok and id then d.Enum=id; d.ObjectID=d.ObjectID or id end end
    return d
end
local matches={}
for name,c in pairs(Cosmetics) do
    if type(name)=="string" and c.Type=="Skin" and name:lower():find(KEYWORD,1,true) then table.insert(matches,name) end
end
table.sort(matches)
if #matches==0 then warn("[AR-Aug] no skins containing '"..KEYWORD.."' found"); return end
local chosen=matches[1]; if PICK and isAugSkin(PICK) then chosen=PICK end
local arSkin=mkSkin(chosen)
print(("[AR-Aug] %d matching skin(s); equipping '%s'"):format(#matches,chosen))
for _,key in ipairs({"OwnsCosmetic","OwnsCosmeticNormally","OwnsCosmeticUniversally","OwnsCosmeticForWeapon"}) do
    local orig=cosLib[key]
    if type(orig)=="function" then cosLib[key]=function(self,inv,nm,wep,...) if isAR(wep) and isAugSkin(nm) then return true end; return orig(self,inv,nm,wep,...) end end
end
local origGet=datCtrl.Get; local invSrc,invProxy
local invMeta={__index=function(_,k) if isAugSkin(k) then return true end; return nil end}
datCtrl.Get=function(self,key,...)
    local val=origGet(self,key,...)
    if key=="CosmeticInventory" then
        if invProxy and invSrc==val then return invProxy end
        local prx={}; if val then for k,v in pairs(val) do prx[k]=v end end
        invSrc,invProxy=val,setmetatable(prx,invMeta); return invProxy
    end; return val
end
local origGetWep=datCtrl.GetWeaponData; local wepCache={}
datCtrl.GetWeaponData=function(self,wn,...)
    local d=origGetWep(self,wn,...); if not d then return nil end
    if arSkin and isAR(wn) then
        local c=wepCache[wn]; if c and c.src==d and c.skin==arSkin then return c.out end
        local m={}; for k,v in pairs(d) do m[k]=v end; m.Name=wn; m.Skin=arSkin
        wepCache[wn]={src=d,skin=arSkin,out=m}; return m
    end; return d
end
if hookmetamethod and getnamecallmethod then
    local remotes=RS:FindFirstChild("Remotes"); local dataRem=remotes and remotes:FindFirstChild("Data"); local equipRem=dataRem and dataRem:FindFirstChild("EquipCosmetic")
    if equipRem then
        local old; old=hookmetamethod(game,"__namecall",function(self,...)
            if self==equipRem and getnamecallmethod()=="FireServer" then
                local wn,ct,cn=...
                if isAR(wn) and ct=="Skin" and isAugSkin(cn) then
                    arSkin=mkSkin(cn); task.defer(function() pcall(function() datCtrl.CurrentData:Replicate("WeaponInventory") end) end); return
                end
            end; return old(self,...)
        end)
    end
else warn("[AR-Aug] hookmetamethod not available") end
print("[AR-Aug] loaded")
end)
if not frontOk then warn("[AR-Aug] front block failed: "..tostring(frontErr)) end

local CONFIG=[==[
{"replacement_rules":[
  {"name":"Body","replace_ids":[18687757654],"mode":"cdn","enabled":true,"cdn_url":"https://raw.githubusercontent.com/boxyghosly/RivalsSkinChanger/refs/heads/main/KeyaugBody9.obj","scale":"aug","texture":"key"},
  {"name":"Remove","replace_ids":[18687757291,18687757011,18687756555,18687757157],"mode":"id","enabled":true},
  {"name":"shootingsound","replace_ids":[17662574783],"mode":"cdn","enabled":true,"cdn_url":"https://raw.githubusercontent.com/boxyghosly/RivalsSkinChanger/main/kaug.mp3"},
  {"name":"Removeshootsound","replace_ids":[18764343961],"mode":"id","enabled":true},
  {"name":"Removebolt","replace_ids":[18687757424],"mode":"id","enabled":true},
  {"name":"Removemag","replace_ids":[18687756845],"mode":"id","enabled":true},
  {"name":"Mag","replace_ids":[18687756685],"mode":"cdn","enabled":true,"cdn_url":"https://raw.githubusercontent.com/boxyghosly/RivalsSkinChanger/refs/heads/main/KeyaugMag1.obj","scale":"mag","texture":"key"},
  {"name":"Reloadsound1","replace_ids":[13455395017],"mode":"cdn","enabled":true,"cdn_url":"https://raw.githubusercontent.com/boxyghosly/RivalsSkinChanger/main/kaug reload 17.mp3"},
  {"name":"Reloadsound2","replace_ids":[13236549929],"mode":"cdn","enabled":true,"cdn_url":"https://raw.githubusercontent.com/boxyghosly/RivalsSkinChanger/main/kaug reload 29.mp3"},
  {"name":"Reloadsound3","replace_ids":[13236549962],"mode":"cdn","enabled":true,"cdn_url":"https://raw.githubusercontent.com/boxyghosly/RivalsSkinChanger/main/kaug reload 62.mp3"},
  {"name":"icon","replace_ids":[18770201102,18770192853],"mode":"cdn","enabled":true,"cdn_url":"https://raw.githubusercontent.com/boxyghosly/RivalsSkinChanger/main/iconkeyaug.png"}
]}
]==]
local CDN_FOLDER="AWildcat/keyaug"
local MESH_METHOD="both"; local CONVERT_OBJ=true
local SCALES={aug=1.2,mag=0.7}
local TEXTURE_VERSION="v2"
local KEY_BASE={255,196,40}; local KEY_DARK={150,100,10}; local KEY_EDGE={255,240,170}
local missing={}
for _,p in ipairs({{"isfile",isfile},{"writefile",writefile},{"getcustomasset",getcustomasset},{"makefolder",makefolder},{"isfolder",isfolder}}) do
    if type(p[2])~="function" then missing[#missing+1]=p[1] end
end
if #missing>0 then warn("[Keyaug] Delta is missing: "..table.concat(missing,", ").." - cannot run"); return end
if not isfolder("AWildcat") then pcall(makefolder,"AWildcat") end
if not isfolder(CDN_FOLDER) then pcall(makefolder,CDN_FOLDER) end
local function hashStr(s) local h=5381; for i=1,#s do h=(h*33+s:byte(i))%4294967296 end; return string.format("%08x",h) end
local function download(url) local ok,res=pcall(function() return game:HttpGet(url) end); if ok and type(res)=="string" and #res>0 then return res end; local req=request or http_request or (syn and syn.request); if req then local ok2,r=pcall(req,{Url=url,Method="GET"}); if ok2 and r and r.StatusCode==200 and type(r.Body)=="string" and #r.Body>0 then return r.Body end end; return nil end
local function objToMesh(text)
    local v,vt,vn,out={},{},{},{}; local tris,faces=0,0
    local function idx(s,n) if s==nil or s=="" then return nil end; local i=tonumber(s); if not i then return nil end; if i<0 then return n+i+1 end; return i end
    local function corner(a,b,c) local p=v[idx(a,#v) or 0]; if not p then return nil end; local n=vn[idx(c,#vn) or 0] or {0,1,0}; local t=vt[idx(b,#vt) or 0] or {0,0}; return string.format("[%.5f,%.5f,%.5f][%.4f,%.4f,%.4f][%.5f,%.5f,0]",p[1],p[2],p[3],n[1],n[2],n[3],t[1],1-t[2]) end
    for line in text:gmatch("[^\r\n]+") do
        local c=line:sub(1,2)
        if c=="v " then local x,y,z=line:match("^v%s+(%S+)%s+(%S+)%s+(%S+)"); v[#v+1]={tonumber(x) or 0,tonumber(y) or 0,tonumber(z) or 0}
        elseif c=="vt" then local u,w=line:match("^vt%s+(%S+)%s+(%S+)"); vt[#vt+1]={tonumber(u) or 0,tonumber(w) or 0}
        elseif c=="vn" then local x,y,z=line:match("^vn%s+(%S+)%s+(%S+)%s+(%S+)"); vn[#vn+1]={tonumber(x) or 0,tonumber(y) or 1,tonumber(z) or 0}
        elseif c=="f " then
            local corners={}
            for tok in line:gmatch("%S+") do if tok~="f" then local a,b,cc=tok:match("^(%-?%d+)/?(%-?%d*)/?(%-?%d*)"); local s=a and corner(a,b,cc); if s then corners[#corners+1]=s end end end
            for i=2,#corners-1 do out[#out+1]=corners[1]; out[#out+1]=corners[i]; out[#out+1]=corners[i+1]; tris=tris+1 end
            faces=faces+1; if faces%4000==0 then task.wait() end
        end
    end
    if tris==0 then return nil,0 end; return "version 1.00\n"..tris.."\n"..table.concat(out),tris
end
local stats={cached=0,downloaded=0,failed=0}; local failedList={}; local cdnAssets={}
local function loadAsset(path) for _=1,5 do if isfile(path) then local ok,a=pcall(getcustomasset,path); if ok and a then return a end end; task.wait(0.3) end; return nil end
local loading={}; local loadCdnInner
local function loadCdn(url) if cdnAssets[url] then return cdnAssets[url] end; if loading[url] then while loading[url] do task.wait() end; return cdnAssets[url] end; loading[url]=true; local ok,res=pcall(loadCdnInner,url); loading[url]=nil; if ok then return res end; return nil end
loadCdnInner=function(url)
    local name=url:match("[^/]+$") or url; local ext=(url:match("%.(%w+)$") or "bin"):lower()
    local convert=(ext=="obj" and CONVERT_OBJ); local path=CDN_FOLDER.."/"..hashStr(url)..".".. (convert and "mesh" or ext)
    if isfile(path) then stats.cached=stats.cached+1
    else
        print("[Keyaug] downloading "..name); local data=download(url)
        if not data then stats.failed=stats.failed+1; failedList[#failedList+1]=name.." (download failed)"; return nil end
        if #data<200 and data:find("404") then stats.failed=stats.failed+1; failedList[#failedList+1]=name.." (404 not found)"; return nil end
        if convert then
            local mesh,tris=objToMesh(data)
            if not mesh then stats.failed=stats.failed+1; failedList[#failedList+1]=name.." (no faces in obj)"; return nil end
            print(("[Keyaug] %s -> %d triangles"):format(name,tris))
            if tris>20000 then warn("[Keyaug] "..name.." has over 20k triangles, Roblox may refuse it") end
            data=mesh
        end
        if not pcall(writefile,path,data) then stats.failed=stats.failed+1; failedList[#failedList+1]=name.." (could not save)"; return nil end
        stats.downloaded=stats.downloaded+1
    end
    local asset=loadAsset(path); if not asset then stats.failed=stats.failed+1; failedList[#failedList+1]=name.." (getcustomasset failed)"; return nil end
    cdnAssets[url]=asset; return asset
end
local function crc32(s) local crcTable={}; for i=0,255 do local c=i; for _=1,8 do if bit32.band(c,1)==1 then c=bit32.bxor(bit32.rshift(c,1),0xEDB88320) else c=bit32.rshift(c,1) end end; crcTable[i]=c end; local c=0xFFFFFFFF; for i=1,#s do c=bit32.bxor(crcTable[bit32.band(bit32.bxor(c,s:byte(i)),0xFF)],bit32.rshift(c,8)) end; return bit32.bxor(c,0xFFFFFFFF) end
local function adler32(s) local a,b=1,0; for i=1,#s do a=(a+s:byte(i))%65521; b=(b+a)%65521 end; return b*65536+a end
local function pngChunk(kind,data) return string.pack(">I4",#data)..kind..data..string.pack(">I4",crc32(kind..data)) end
local function makePng(w,h,pixel)
    local rows={}
    for y=0,h-1 do local row={"\0"}; for x=0,w-1 do local r,g,b=pixel(x,y); row[#row+1]=string.char(r,g,b) end; rows[#rows+1]=table.concat(row) end
    local raw=table.concat(rows); local blocks={"\120\1"}; local pos=1
    while pos<=#raw do
        local piece=raw:sub(pos,pos+65534); pos=pos+#piece; local final=(pos>#raw) and 1 or 0
        blocks[#blocks+1]=string.char(final)..string.pack("<I2",#piece)..string.pack("<I2",bit32.band(bit32.bnot(#piece),0xFFFF))..piece
    end
    blocks[#blocks+1]=string.pack(">I4",adler32(raw))
    return "\137PNG\r\n\26\n"..pngChunk("IHDR",string.pack(">I4I4",w,h).."\8\2\0\0\0")..pngChunk("IDAT",table.concat(blocks))..pngChunk("IEND","")
end
local TEXTURES={
    key=function(x,y)
        local c=KEY_BASE
        if x<6 or y<6 or x>=250 or y>=250 then c=KEY_EDGE
        elseif ((x+y)//24)%2==0 then c=KEY_DARK end
        return c[1],c[2],c[3]
    end,
}
local textureAssets={}
local function texAsset(key)
    if textureAssets[key] then return textureAssets[key] end
    local gen=TEXTURES[key]; if not gen then warn("[Keyaug] unknown texture: "..tostring(key)); return nil end
    local path=CDN_FOLDER.."/tex_"..key.."_"..TEXTURE_VERSION..".png"
    if not isfile(path) then
        local ok,png=pcall(makePng,256,256,gen)
        if not ok or not pcall(writefile,path,png) then stats.failed=stats.failed+1; failedList[#failedList+1]="texture "..key.." (could not build)"; return nil end
        print("[Keyaug] built texture: "..key)
    end
    local asset=loadAsset(path); if not asset then stats.failed=stats.failed+1; failedList[#failedList+1]="texture "..key.." (getcustomasset failed)"; return nil end
    textureAssets[key]=asset; return asset
end
local HttpService=game:GetService("HttpService"); local AssetService=game:GetService("AssetService")
local rules=HttpService:JSONDecode(CONFIG).replacement_rules
local lookup,meshCache={},{}; local registered,swapped=0,0
local function parseId(v) return tonumber(tostring(v):match("(%d+)")) end
local function resolve(rule)
    if rule.mode=="texture" then return texAsset(rule.texture) end
    if rule.mode=="cdn" then return loadCdn(rule.cdn_url) end
    if rule.with_id then return "rbxassetid://"..rule.with_id end; return ""
end
local function flatten(list,out)
    for _,r in ipairs(list) do
        if r.type=="group" then flatten(r.children or {},out)
        elseif r.enabled then out[#out+1]=r end
    end; return out
end
local active=flatten(rules,{}); local targets={}; local pendingCount=#active
for i,rule in ipairs(active) do task.spawn(function() local ok,res=pcall(resolve,rule); if ok then targets[i]=res end; pendingCount=pendingCount-1 end) end
while pendingCount>0 do task.wait() end
local meshAssets={}
for i,rule in ipairs(active) do
    local target=targets[i]
    if target~=nil then
        registered=registered+1
        local entry={target=target}
        if rule.scale then entry.scale=SCALES[rule.scale] end
        if rule.texture and rule.mode~="texture" then entry.texture=texAsset(rule.texture) end
        if target~="" and rule.mode~="texture" and (rule.texture or rule.scale) then meshAssets[target]=true end
        for _,id in ipairs(rule.replace_ids) do local n=parseId(id); if n then lookup[n]=entry end end
    end
end
if MESH_METHOD~="direct" then
    local warming=0
    for asset in pairs(meshAssets) do warming=warming+1; task.spawn(function() pcall(function() meshCache[asset]=AssetService:CreateMeshPartAsync(asset) end); warming=warming-1 end) end
    local t0=os.clock(); while warming>0 and os.clock()-t0<15 do task.wait() end
end
print(("[Keyaug] rules ready: %d | cached: %d | downloaded: %d | failed: %d"):format(registered,stats.cached,stats.downloaded,stats.failed))
for _,f in ipairs(failedList) do warn("[Keyaug] FAILED: "..f) end
local PROPS={MeshPart={"MeshId","TextureID"},SpecialMesh={"MeshId","TextureId"},Sound={"SoundId"},Decal={"Texture"},Texture={"Texture"},ImageLabel={"Image"},ImageButton={"Image"},SurfaceAppearance={"ColorMap","NormalMap","MetalnessMap","RoughnessMap"}}
local seen=setmetatable({},{__mode="k"}); local seenNil=setmetatable({},{__mode="k"}); local forcedTexture=setmetatable({},{__mode="k"}); local scaleState=setmetatable({},{__mode="k"})
local function hideMesh(inst) pcall(function() if inst:IsA("MeshPart") then inst.Transparency=1 elseif inst:IsA("SpecialMesh") then inst.Scale=Vector3.new(0,0,0) end end) end
local function applyMesh(inst,asset)
    if not inst:IsA("MeshPart") then pcall(function() inst.MeshId=asset end); return end
    if MESH_METHOD~="apply" then pcall(function() inst.MeshId=asset end) end
    if MESH_METHOD~="direct" then
        local ok,err=pcall(function() local mp=meshCache[asset]; if not mp then mp=AssetService:CreateMeshPartAsync(asset); meshCache[asset]=mp end; inst:ApplyMesh(mp) end)
        if not ok then warn("[Keyaug] ApplyMesh failed: "..tostring(err)) end
    end
end
local function setTarget(inst,value) pcall(function() if inst:IsA("MeshPart") then inst.Size=value else inst.Scale=value end end) end
local function applyScale(inst,factor)
    if not factor or factor==1 then return end
    local st=scaleState[inst]; if st~=nil then if st then task.defer(setTarget,inst,st) end; return end
    scaleState[inst]=false
    task.spawn(function()
        task.wait(0.1); local target
        pcall(function() if inst:IsA("MeshPart") then target=inst.Size*factor elseif inst:IsA("SpecialMesh") then target=inst.Scale*factor end end)
        if target then scaleState[inst]=target; setTarget(inst,target) end
    end)
end
local function setTexture(inst,asset)
    local prop=inst:IsA("SpecialMesh") and "TextureId" or "TextureID"; forcedTexture[inst]=asset; pcall(function() inst[prop]=asset end)
end
local Players=game:GetService("Players"); local lp=Players.LocalPlayer
local camera=workspace.CurrentCamera; local playerGui=lp:FindFirstChildOfClass("PlayerGui")
local function shouldWatch(inst) if not inst:IsDescendantOf(game) then return true end; if camera and inst:IsDescendantOf(camera) then return true end; if playerGui and inst:IsDescendantOf(playerGui) then return true end; return false end
local function handle(inst,p)
    local ok,cur=pcall(function() return inst[p] end); if not ok then return false end
    local forced=forcedTexture[inst]
    if forced and (p=="TextureID" or p=="TextureId") then if cur~=forced then pcall(function() inst[p]=forced end) end; return true end
    if cur=="" or cur==nil then return false end
    local id=parseId(cur); local entry=id and lookup[id]; if entry==nil then return false end
    local new=entry.target; swapped=swapped+1
    if swapped<=15 then print("[Keyaug] swapped "..inst.ClassName.."."..p.." ("..tostring(id)..")") end
    if p=="MeshId" then
        if new=="" then hideMesh(inst)
        else applyMesh(inst,new); if entry.texture then setTexture(inst,entry.texture) end; applyScale(inst,entry.scale) end
    else pcall(function() inst[p]=new end) end
    return true
end
local function apply(inst)
    local props=PROPS[inst.ClassName]; if not props or seen[inst] then return end; seen[inst]=true
    local watching=shouldWatch(inst)
    for _,p in ipairs(props) do
        local matched=handle(inst,p)
        if matched or watching then pcall(function() inst:GetPropertyChangedSignal(p):Connect(function() handle(inst,p) end) end) end
    end
end
local function scan() local n=0; for _,d in ipairs(game:GetDescendants()) do apply(d); n=n+1; if n%2000==0 then task.wait() end end end
local function scanNil()
    if type(getnilinstances)~="function" then return end
    pcall(function() for _,d in ipairs(getnilinstances()) do if not seenNil[d] then seenNil[d]=true; apply(d); for _,c in ipairs(d:GetDescendants()) do apply(c) end end end end)
end
game.DescendantAdded:Connect(apply); scan(); scanNil()
task.spawn(function() while true do task.wait(10); scanNil() end end)
print("[Keyaug] loaded")
]====]

------------------------------------------------------------------------
-- 5. REAVER VANDAL
------------------------------------------------------------------------
SCRIPTS.reaver = [====[
local CONFIG=[==[
{"replacement_rules":[
  {"type":"group","name":"Model","children":[
    {"name":"Body Replace",   "replace_ids":[12613284036],"mode":"cdn","enabled":true,"cdn_url":"https://github.com/mrbeanissohot/Bean-sVandal/raw/refs/heads/main/reaver_body.mesh"},
    {"name":"Upper Replace",  "replace_ids":[12613284249],"mode":"cdn","enabled":true,"cdn_url":"https://github.com/mrbeanissohot/Bean-sVandal/raw/refs/heads/main/reaver_bits.mesh"},
    {"name":"Bolt Replace",   "replace_ids":[12613283355],"mode":"cdn","enabled":true,"cdn_url":"https://github.com/mrbeanissohot/Bean-sVandal/raw/refs/heads/main/reaver_bolt.mesh"},
    {"name":"Mag Replace",    "replace_ids":[12613284529],"mode":"cdn","enabled":true,"cdn_url":"https://github.com/mrbeanissohot/Bean-sVandal/raw/refs/heads/main/reaver_mag.mesh"},
    {"name":"Hide Extras",    "replace_ids":[12613283569,14652718299,12613284768],"mode":"id","enabled":true}
  ]},
  {"type":"group","name":"Sound","children":[
    {"name":"Shoot Replace",   "replace_ids":[13087362838],"mode":"cdn","enabled":true,"cdn_url":"https://github.com/mrbeanissohot/Bean-sVandal/raw/refs/heads/main/reaver shoot.mp3"},
    {"name":"Reload Replace1", "replace_ids":[13236549929,13236549962],"mode":"cdn","enabled":true,"cdn_url":"https://github.com/mrbeanissohot/Bean-sVandal/raw/refs/heads/main/reaver load1.mp3"},
    {"name":"Reload Replace",  "replace_ids":[13455395017],"mode":"cdn","enabled":true,"cdn_url":"https://github.com/mrbeanissohot/Bean-sVandal/raw/refs/heads/main/reaver load2.mp3"}
  ]},
  {"type":"group","name":"Icon","children":[
    {"name":"Icon Replace 1","replace_ids":[17160682738],"mode":"cdn","enabled":true,"cdn_url":"https://github.com/mrbeanissohot/Bean-sVandal/raw/refs/heads/main/reaver vandel thumbnail.png"},
    {"name":"Icon Replace 2","replace_ids":[13197584241],"mode":"cdn","enabled":true,"cdn_url":"https://github.com/mrbeanissohot/Bean-sVandal/raw/refs/heads/main/reaver vandel thumbnail 2.png"}
  ]}
]}
]==]
local v1="Vandal"; local v2=1.35; local v3="native"; local v4=false; local v5=0; local v6=15
local v8={}; for _,p in ipairs({{"isfile",isfile},{"writefile",writefile},{"getcustomasset",getcustomasset},{"makefolder",makefolder},{"isfolder",isfolder}}) do if type(p[2])~="function" then v8[#v8+1]=p[1] end end
if #v8>0 then warn("[Vandal] executor is missing: "..table.concat(v8,", ").." - cannot run"); return end
if not isfolder(v1) then pcall(makefolder,v1) end
local v9=game:GetService("HttpService"); local v10=game:GetService("AssetService")
local v11=v9:JSONDecode(CONFIG).replacement_rules
local v12,v13,v14={},{},{}; local v15,v16,v17=0,0,0; local v18={}
local function v19(v50) return tonumber(tostring(v50):match("(%d+)")) end
local function v20(v51) if v13[v51] then return v13[v51] end; for _=1,5 do if isfile(v51) then local v137,v138=pcall(getcustomasset,v51); if v137 and v138 then v13[v51]=v138; return v138 end end; task.wait(0.3) end; return nil end
local function v21(v52) local v53=5381; for v106=1,#v52 do v53=((v53*33)+v52:byte(v106))%4294967296 end; return string.format("%08x",v53) end
local function v22(v54) local v55,v56=pcall(function() return game:HttpGet(v54) end); if v55 and type(v56)=="string" and #v56>0 then return v56 end; local v57=request or http_request or (syn and syn.request); if v57 then local v125,v126=pcall(v57,{Url=v54,Method="GET"}); if v125 and v126 and v126.StatusCode==200 and type(v126.Body)=="string" and #v126.Body>0 then return v126.Body end end; return nil end
local function v23(v58) local v59=v58:gsub("%?.*$",""); local v60=v59:match("[^/]+$") or v59; local v61=(v59:match("%.(%w+)$") or "bin"):lower(); local v62=v1.."/"..v21(v58).."."..v61; if not isfile(v62) then print("[Vandal] downloading "..v60); local v127=v22(v58); if not v127 then v18[#v18+1]=v60.." (download failed)"; return nil end; if #v127<200 and v127:find("404") then v18[#v18+1]=v60.." (404 not found)"; return nil end; if not pcall(writefile,v62,v127) then v18[#v18+1]=v60.." (could not save)"; return nil end end; local v63=v20(v62); if not v63 then v18[#v18+1]=v60.." (getcustomasset failed)" end; return v63 end
local function v24(v64) if v64.mode=="local" then local v129=v20(v64.local_path); if not v129 then v18[#v18+1]=v64.local_path.." (not found in workspace)" end; return v129 end; if v64.mode=="cdn" then return v23(v64.cdn_url) end; if v64.with_id then return "rbxassetid://"..v64.with_id end; return "" end
local function v25(v65,v66) for _,v108 in ipairs(v65) do if v108.type=="group" then v25(v108.children or {},v66) elseif v108.enabled then v66[#v66+1]=v108 end end; return v66 end
local v26=v25(v11,{}); local v27={}; local v28=#v26
for v67,v68 in ipairs(v26) do task.spawn(function() local v109,v110=pcall(v24,v68); if v109 then v27[v67]=v110 end; v28=v28-1 end) end
while v28>0 do task.wait() end
local v29={}
for v69,v70 in ipairs(v26) do local v71=v27[v69]; if v71==nil then v16=v16+1 else v15=v15+1; local v130=(v70.mode=="cdn") and (tostring(v70.cdn_url):lower():gsub("%?.*$",""):find("%.mesh$")~=nil); if v130 then v29[v71]=true end; for _,v141 in ipairs(v70.replace_ids) do local v142=v19(v141); if v142 then v12[v142]={target=v71,baked=v130} end end end end
local v30=0
for v72 in pairs(v29) do v30=v30+1; task.spawn(function() pcall(function() v14[v72]=v10:CreateMeshPartAsync(v72) end); v30=v30-1 end) end
local v31=os.clock(); while v30>0 and (os.clock()-v31)<15 do task.wait() end
print(("[Vandal] rules registered: %d, skipped: %d"):format(v15,v16))
for _,v74 in ipairs(v18) do warn("[Vandal] FAILED: "..v74) end
local v32={MeshPart={"MeshId"},SpecialMesh={"MeshId"},Sound={"SoundId"},Decal={"Texture"},Texture={"Texture"},ImageLabel={"Image"},ImageButton={"Image"}}
local v33={Sound=true,ImageLabel=true,ImageButton=true}
local v34=setmetatable({},{__mode="k"}); local v35=setmetatable({},{__mode="k"}); local v36=setmetatable({},{__mode="k"}); local v37=setmetatable({},{__mode="k"})
local function v38(v75,v76) return v75[v76] end
local function v39(v77) pcall(function() if v77:IsA("MeshPart") then v77.Transparency=1 elseif v77:IsA("SpecialMesh") then v77.Scale=Vector3.new(0,0,0) end end) end
local function v40(v78,v79)
    if v78:IsA("MeshPart") then
        local v132,v133=pcall(function() local v144=v14[v79]; if not v144 then v144=v10:CreateMeshPartAsync(v79); v14[v79]=v144 end; v78:ApplyMesh(v144) end)
        if not v132 then warn("[Vandal] ApplyMesh failed: "..tostring(v133)); pcall(function() v78.MeshId=v79 end) end
    else pcall(function() v78.MeshId=v79 end) end
end
local function v41(v80,v81) if not v80:IsA("MeshPart") then return end; if not v36[v80] then v36[v80]=v80.Size end; local v82=v36[v80]; task.wait(0.1); pcall(function() if v3=="keep" then v80.Size=v82*v2 else local v147=v14[v81]; if v147 then v80.Size=v147.Size*v2 end end end) end
local function v42(v83) local v84=v83:IsA("MeshPart"); local v85=(v84 and "TextureID") or "TextureId"; pcall(function() v83[v85]="" end); pcall(function() if v84 then v83.Color=Color3.new(1,1,1) else v83.VertexColor=Vector3.new(1,1,1) end end); for _,v113 in ipairs(v83:GetChildren()) do if v113:IsA("SurfaceAppearance") then v113:Destroy() end end; if not v35[v83] then v35[v83]=true; v83.ChildAdded:Connect(function(v150) if v150:IsA("SurfaceAppearance") then task.defer(function() pcall(function() v150:Destroy() end) end) end end); pcall(function() v83:GetPropertyChangedSignal(v85):Connect(function() if v83[v85]~="" then pcall(function() v83[v85]="" end) end end) end) end end
local function v43(v86,v87,v88,v89) local v90=v88.target; v17=v17+1; if v17<=15 then print("[Vandal] swapped "..v86.ClassName.."."..v87.." ("..tostring(v89)..")") end; if v87=="MeshId" then if v90=="" then v39(v86) else v40(v86,v90); if v88.baked then v42(v86); v41(v86,v90) end end else pcall(function() v86[v87]=v90 end) end end
local function v44(v91,v92) local v93,v94=pcall(v38,v91,v92); if not v93 or v94=="" then return false end; local v95=v19(v94); local v96=v95 and v12[v95]; if not v96 then return false end; task.spawn(v43,v91,v92,v96,v95); return true end
local function v45(v97) local v98=v32[v97.ClassName]; if not v98 or v34[v97] then return end; v34[v97]=true; local v100=v4 or v33[v97.ClassName]; for v114=1,#v98 do local v115=v98[v114]; local v116=v44(v97,v115); if v116 or v100 then pcall(function() v97:GetPropertyChangedSignal(v115):Connect(function() v44(v97,v115) end) end) end end end
local function v46() local v101=0; for _,v118 in ipairs(game:GetDescendants()) do v45(v118); v101=v101+1; if v101%1000==0 then task.wait() end end end
local function v47() if type(getnilinstances)~="function" then return end; local v102,v103=pcall(getnilinstances); if not v102 then return end; local v104=0; for _,v120 in ipairs(v103) do if not v37[v120] then v37[v120]=true; v45(v120); for _,v159 in ipairs(v120:GetDescendants()) do v45(v159); v104=v104+1; if v104%1000==0 then task.wait() end end end end end
game.DescendantAdded:Connect(v45)
task.spawn(function() v46(); v47(); print("[Vandal] initial scan done") end)
if v5>0 then task.spawn(function() while true do task.wait(v5); v46() end end) end
if v6>0 then task.spawn(function() while true do task.wait(v6); v47() end end) end
print("[Vandal] loaded")
]====]

------------------------------------------------------------------------
-- 6. KEYCHEL  (Satchel — mesh + animation + sound replacer)
------------------------------------------------------------------------
SCRIPTS.keychel = [====[
local CONFIG=[==[
{"replacement_rules":[
  {"name":"satchel",          "replace_ids":[111319295872696],"mode":"cdn","enabled":true,"cdn_url":"https://raw.githubusercontent.com/mrbeanissohot/Keychel/main/KEYCHELBODYNEW1.mesh"},
  {"name":"satchel detonator","replace_ids":[123563845986019],"mode":"cdn","enabled":true,"cdn_url":"https://raw.githubusercontent.com/mrbeanissohot/Keychel/main/KEYCHELBUTTONNEW2.mesh"},
  {"name":"ImageIconOfSatchel","replace_ids":[82237471151891],"mode":"cdn","enabled":true,"cdn_url":"https://raw.githubusercontent.com/boxyghosly/Keychel/main/Untitled49_20260527123520.png"},
  {"name":"ExplodingSound",   "replace_ids":[13455969017],"mode":"cdn","enabled":true,"cdn_url":"https://raw.githubusercontent.com/boxyghosly/RPKEY/main/RPGKYNEW.mp3"},
  {"name":"ThrowStartPinpull","replace_ids":[14510062019],"mode":"id","enabled":true,"with_id":123368854506447},
  {"name":"ThrowIdle",        "replace_ids":[14510038568],"mode":"id","enabled":true,"with_id":95887720657783},
  {"name":"ThrowFinish",      "replace_ids":[14510046795],"mode":"id","enabled":true,"with_id":98498351754343},
  {"name":"Sprint",           "replace_ids":[14580328848],"mode":"id","enabled":true,"with_id":119518299690405},
  {"name":"Inspect",          "replace_ids":[14509964565],"mode":"id","enabled":true,"with_id":118832975932987},
  {"name":"LobFinish",        "replace_ids":[14580368724],"mode":"id","enabled":true,"with_id":116760723605331},
  {"name":"Equip",            "replace_ids":[14509948480],"mode":"id","enabled":true,"with_id":99784649946058},
  {"name":"Idle",             "replace_ids":[14509967864],"mode":"id","enabled":true,"with_id":138613177890181}
]}
]==]
local v1=1; local v2=Color3.fromRGB(255,205,45); local v3=0.28; local v4=0.01
local v5={[138805549853994]=true,[129504437671598]=true,[104440368867933]=true,[129357957202626]=true,[87546390135975]=true}
local v6={MeshPart=true,SpecialMesh=true,Sound=true,Animation=true,Decal=true,Texture=true,ImageLabel=true,ImageButton=true,SurfaceAppearance=true}
local v7={Terrain=true,Camera=true}
local v8={MeshPart={"MeshId","TextureID"},SpecialMesh={"MeshId","TextureId"},Sound={"SoundId"},Animation={"AnimationId"},Decal={"Texture"},Texture={"Texture"},ImageLabel={"Image"},ImageButton={"Image"},SurfaceAppearance={"ColorMap","NormalMap","MetalnessMap","RoughnessMap"}}
local v9="Keychel"
local function v10(v44) return (v44:gsub("github%.com/([^/]+)/([^/]+)/blob/","raw.githubusercontent.com/%1/%2/")) end
local function v11(v45) local v46=v45:match("([^/]+)$"):gsub("%%20","_"); return v9.."/"..v46 end
local function v12(v47,v48) if isfile(v48) then return true end; local v49,v50=pcall(function() return game:HttpGet(v10(v47)) end); if not v49 or type(v50)~="string" or #v50==0 then return false end; if makefolder and isfolder and not isfolder(v9) then pcall(makefolder,v9) end; return (pcall(writefile,v48,v50)) end
local v13=v9.."/keychel_gold_v2.png"
local function v14(v51,v52,v53) local v54=math.clamp((v53-v51)/(v52-v51),0,1); return v54*v54*(3-(2*v54)) end
local v15={{0.16,0.2,0.04},{0.72,0.14,0.05},{0.44,0.38,0.032},{0.86,0.46,0.04},{0.28,0.62,0.048},{0.6,0.7,0.034},{0.1,0.86,0.036},{0.9,0.88,0.044}}
local v16={{0.28,0.05,0.85},{0.52,0.018,0.6},{0.66,0.03,0.35}}
local function v17(v55,v56)
    local v57=(v55*0.55)+(v56*0.45); local v58=255+((246-255)*v57); local v59=224+((182-224)*v57); local v60=45+((22-45)*v57)
    local v61=0.96+(0.04*(0.5+(0.5*math.sin(((v55*0.8)+v56)*40))))
    v58,v59,v60=v58*v61,v59*v61,v60*v61
    local v62=v14(0.15,0,v56)*0.35; v58=v58+((255-v58)*v62); v59=v59+((250-v59)*v62); v60=v60+((200-v60)*v62)
    local v63=0
    for v112=1,#v16 do local v113=v16[v112]; local v114=(v55-(v56*0.7))-v113[1]; v63=math.max(v63,math.exp(-((v114/v113[2])^2))*v113[3]) end
    v58=v58+((255-v58)*v63); v59=v59+((248-v59)*v63); v60=v60+((196-v60)*v63)
    for v115=1,#v15 do
        local v116=v15[v115]; local v117,v118,v119=v55-v116[1],v56-v116[2],v116[3]; local v120=math.sqrt((v117*v117)+(v118*v118))
        local v121=math.max(0,1-(v120/v119))^3
        local v122=((math.max(0,1-(math.abs(v117)/(v119*2.6)))^2)*(math.max(0,1-(math.abs(v118)/(v119*0.22)))^2))+((math.max(0,1-(math.abs(v118)/(v119*2.6)))^2)*(math.max(0,1-(math.abs(v117)/(v119*0.22)))^2))
        local v123=math.min(1,v121+(v122*0.9)); v58=v58+((255-v58)*v123); v59=v59+((255-v59)*v123); v60=v60+((235-v60)*v123)
    end
    return math.floor(math.clamp(v58,0,255)),math.floor(math.clamp(v59,0,255)),math.floor(math.clamp(v60,0,255))
end
local function v18(v64)
    if isfile and isfile(v64) then return true end
    if not (writefile and bit32) then return false end
    local v65=128; local v66=math.floor; local v67,v68,v69={},1,0
    for v124=0,v65-1 do
        local v125={0}; local v126=1
        for v163=0,v65-1 do local v164,v165,v166=v17((v163+0.5)/v65,(v124+0.5)/v65); v125[v126+1]=v164; v125[v126+2]=v165; v125[v126+3]=v166; v126=v126+3 end
        for v170=1,v126 do v68=(v68+v125[v170])%65521; v69=(v69+v68)%65521 end
        v67[#v67+1]=string.char(table.unpack(v125))
        if (v124%32)==31 then task.wait() end
    end
    local v70=table.concat(v67); local v71,v72,v73={},1,#v70
    while v72<=v73 do
        local v128=v70:sub(v72,v72+65534); local v129=#v128; local v130=(((v72+65534)>=v73) and 1) or 0; local v131=65535-v129
        v71[#v71+1]=string.char(v130,v129%256,v66(v129/256),v131%256,v66(v131/256))..v128; v72=v72+65535
    end
    local function v74(v133) return string.char(v66(v133/16777216)%256,v66(v133/65536)%256,v66(v133/256)%256,v133%256) end
    local v75="\120\1"..table.concat(v71)..v74((v69*65536)+v68)
    local v76={}; for v134=0,255 do local v135=v134; for _=1,8 do if bit32.band(v135,1)==1 then v135=bit32.bxor(3988292384,bit32.rshift(v135,1)) else v135=bit32.rshift(v135,1) end end; v76[v134]=v135 end
    local function v77(v137) local v138=4294967295; for v172=1,#v137 do v138=bit32.bxor(v76[bit32.band(bit32.bxor(v138,v137:byte(v172)),255)],bit32.rshift(v138,8)) end; return bit32.bxor(v138,4294967295) end
    local function v78(v139,v140) return v74(#v140)..v139..v140..v74(v77(v139..v140)) end
    local v79="\137PNG\r\n\26\n"..v78("IHDR",v74(v65)..v74(v65)..string.char(8,2,0,0,0))..v78("IDAT",v75)..v78("IEND","")
    if makefolder and isfolder and not isfolder(v9) then pcall(makefolder,v9) end
    return (pcall(writefile,v64,v79))
end
local v19=game:GetService("HttpService"); local v20=game:GetService("AssetService")
local v21=v19:JSONDecode(CONFIG).replacement_rules
local v22,v23,v24={},{},{}; local v25={}; local v26
local function v27(v80) return tonumber(tostring(v80):match("(%d+)")) end
local function v28(v81) if v23[v81] then return v23[v81] end; for _=1,5 do if isfile(v81) then local v183,v184=pcall(getcustomasset,v81); if v183 and v184 then v23[v81]=v184; return v184 end end; task.wait(0.2) end; return nil end
local function v29(v82) if (v82.mode=="cdn") or (v82.mode=="local") then local v173=v82.cdn_url or v82.url; if not v173 then return nil end; local v174=v11(v173); v12(v173,v174); return v28(v174) end; if v82.with_id then return "rbxassetid://"..v82.with_id end; return nil end
local function v30(v83) if not v83.enabled then return end; local v84=v29(v83); if v84==nil then return end; if (v83.mode=="cdn") or (v83.mode=="local") then v25[v84]=true end; for _,v143 in ipairs(v83.replace_ids) do local v144=v27(v143); if v144 then v22[v144]=v84 end end end
local v31=false
local function v32()
    local v85=task.spawn(function() pcall(v18,v13); v26=v28(v13) end)
    local v86={}; for v145,v146 in ipairs(v21) do table.insert(v86,task.spawn(function() pcall(v30,v146) end)) end
    for _ in ipairs(v86) do pcall(task.wait,0) end; pcall(task.wait,0)
    local v87=tick()+20; local v88=false
    while (tick()<v87) and not v88 do
        v88=true
        for _,v177 in ipairs(v21) do
            if ((v177.mode=="cdn") or (v177.mode=="local")) and v177.enabled then
                local v199=v177.cdn_url or v177.url
                if v199 then local v210=v11(v199); if not v23[v210] then v88=false; break end end
            end
        end
        if not v88 then task.wait(0.1) end
    end
    local v89={}; for v149 in pairs(v25) do table.insert(v89,task.spawn(function() if v24[v149] then return end; local v178,v179=pcall(function() return v20:CreateMeshPartAsync(v149) end); if v178 and v179 then v24[v149]=v179 end end)) end
    for _ in ipairs(v89) do pcall(task.wait,0) end
    local v90=tick()+30; local v91=false
    while (tick()<v90) and not v91 do v91=true; for v180 in pairs(v25) do if not v24[v180] then v91=false; break end end; if not v91 then task.wait(0.1) end end
    pcall(task.wait,0); v31=true; print("[Replacer] preload complete — scanning")
end
local v33=setmetatable({},{__mode="k"}); local v34=setmetatable({},{__mode="k"})
local function v35(v92) pcall(function() if v92:IsA("BasePart") then v92.Material=Enum.Material.Metal; v92.Reflectance=v3; v92.Color=v2 elseif v92:IsA("SpecialMesh") then local v203=v92.Parent; if v203 and v203:IsA("BasePart") then v203.Material=Enum.Material.Metal; v203.Reflectance=v3; v203.Color=v2 end end end) end
local function v36(v93,v94) if v93:IsA("MeshPart") then local v181=v24[v94]; if not v181 then local v201=pcall(function() local v204=v20:CreateMeshPartAsync(v94); v24[v94]=v204; v93:ApplyMesh(v204) end); if not v201 then pcall(function() v93.MeshId=v94 end); return false end; return true end; local v182=pcall(function() v93:ApplyMesh(v181) end); if not v182 then pcall(function() v93.MeshId=v94 end); return false end; return true end; return (pcall(function() v93.MeshId=v94 end)) end
local function v37(v95) if not v26 then return end; pcall(function() if v95:IsA("MeshPart") then v95.TextureID=v26 elseif v95:IsA("SpecialMesh") then v95.TextureId=v26 end end) end
local function v38(v96) if v34[v96] then return end; v34[v96]=true; local v98=v8[v96.ClassName]; if not v98 then return end; for _,v154 in ipairs(v98) do pcall(function() v96:GetPropertyChangedSignal(v154):Connect(function() local v191,v192=pcall(function() return v96[v154] end); if not v191 then return end; local v193=v27(v192); if not v193 then return end; if v5[v193] then pcall(function() if v96:IsA("BasePart") then v96.Transparency=1 elseif v96:IsA("SpecialMesh") then v96.Scale=Vector3.new(0,0,0) end end); return end; local v194=v22[v193]; if v194==nil then return end; if v154=="MeshId" then v36(v96,v194); v37(v96); v35(v96) else pcall(function() v96[v154]=v194 end) end end) end) end end
local function v39(v99,v100) local v101,v102=pcall(function() return v99[v100] end); if not v101 then return end; local v103=v27(v102); if not v103 then return end; if v5[v103] then pcall(function() if v99:IsA("BasePart") then v99.Transparency=1; v99.LocalTransparencyModifier=1 elseif v99:IsA("SpecialMesh") then v99.Scale=Vector3.new(0,0,0) end end); return end; local v104=v22[v103]; if v104==nil then return end; if v100=="MeshId" then v36(v99,v104); if v1~=1 then pcall(function() if v99:IsA("MeshPart") then v99.Size=v99.Size*v1 elseif v99:IsA("SpecialMesh") then v99.Scale=v99.Scale*v1 end end) end; v37(v99); v35(v99) else pcall(function() v99[v100]=v104 end) end end
local function v40(v105) if v33[v105] then return end; local v106=v8[v105.ClassName]; if not v106 then return end; v33[v105]=true; for _,v156 in ipairs(v106) do v39(v105,v156) end; v38(v105) end
local function v41(v108) if not v108 then return end; local v109={v108}; local v110=tick()+v4; while #v109>0 do local v157=v109[#v109]; v109[#v109]=nil; if not v7[v157.ClassName] then if v6[v157.ClassName] then pcall(v40,v157) end; local v196,v197=pcall(function() return v157:GetChildren() end); if v196 and v197 then for v212=1,#v197 do v109[#v109+1]=v197[v212] end end end; if tick()>v110 then task.wait(); v110=tick()+v4 end end end
local function v42() local v111={workspace}; pcall(function() table.insert(v111,game:GetService("Players")) end); pcall(function() table.insert(v111,game:GetService("ReplicatedStorage")) end); pcall(function() table.insert(v111,game:GetService("Lighting")) end); pcall(function() table.insert(v111,game:GetService("SoundService")) end); return v111 end
local function v43() for _,v160 in ipairs(v42()) do pcall(function() v160.DescendantAdded:Connect(function(v198) if not v6[v198.ClassName] then return end; pcall(v40,v198) end) end) end end
task.spawn(function() v32(); for _,v162 in ipairs(v42()) do v41(v162) end; v43(); print("[Replacer] scan complete") end)
print("[Keychel] loaded")
]====]

------------------------------------------------------------------------
-- 7. MONSTER  (Various — CDN OBJ mesh + procedural textures + sound)
------------------------------------------------------------------------
SCRIPTS.monster = [====[
local CONFIG=[==[
{"replacement_rules":[
  {"type":"group","name":"Body","children":[
    {"name":"Monster Body","replace_ids":[70494501482896],"mode":"cdn","enabled":true,"scale":"body","texture":"white","role":"body","cdn_url":"https://raw.githubusercontent.com/elcalzoskineitorfunk/Monster-Skin/refs/heads/main/MONSTER BODYY ver3.obj"},
    {"name":"Monster Logo","replace_ids":[70528849669897],"mode":"cdn","enabled":true,"scale":"logo","texture":"black","color":[0,0,0],"role":"logo","cdn_url":"https://raw.githubusercontent.com/elcalzoskineitorfunk/Monster-Skin/refs/heads/main/MONSTER LOGO ver10.obj"}
  ]},
  {"type":"group","name":"Animation","children":[
    {"name":"Mns Animation [1]","replace_ids":[81951883744250],"mode":"id","enabled":true,"with_id":106136416209642},
    {"name":"Mns Animation [2]","replace_ids":[78544849697314],"mode":"id","enabled":true,"with_id":134840101984538},
    {"name":"Mns Animation [3]","replace_ids":[108185321380462],"mode":"id","enabled":true,"with_id":116339164768827},
    {"name":"Mns Animation [4]","replace_ids":[118241731290742],"mode":"id","enabled":true,"with_id":134433050302557},
    {"name":"Mns Use","replace_ids":[73325703605178,94406584083681],"mode":"cdn","enabled":true,"cdn_url":"https://raw.githubusercontent.com/elcalzoskineitorfunk/Monster-Skin/refs/heads/main/monster-energy.mp3"}
  ]},
  {"type":"group","name":"Icon","children":[
    {"name":"Monster Icon","replace_ids":[104600246515190],"mode":"cdn","enabled":true,"cdn_url":"https://raw.githubusercontent.com/mrbeanissohot/Bean-sValorant/main/white_monster_icon.png"}
  ]}
]}
]==]
local CDN_FOLDER="AWildcat/monster_cache"
local MESH_METHOD="both"; local CONVERT_OBJ=true; local REFRESH=false
local SCALES={body=0.6,logo=0.45}
local ICONS_USE_TEXTURES=false; local TEXTURE_VERSION="v2"
local missing={}
for _,p in ipairs({{"isfile",isfile},{"writefile",writefile},{"getcustomasset",getcustomasset},{"makefolder",makefolder},{"isfolder",isfolder}}) do if type(p[2])~="function" then missing[#missing+1]=p[1] end end
if #missing>0 then warn("[Monster] Delta is missing: "..table.concat(missing,", ").." - cannot run"); return end
if not isfolder("AWildcat") then pcall(makefolder,"AWildcat") end
if not isfolder("AWildcat/monster") then pcall(makefolder,"AWildcat/monster") end
if not isfolder(CDN_FOLDER) then pcall(makefolder,CDN_FOLDER) end
if REFRESH and listfiles and delfile then for _,f in ipairs(listfiles(CDN_FOLDER)) do pcall(delfile,f) end; print("[Monster] cache cleared") end
local function hashStr(s) local h=5381; for i=1,#s do h=(h*33+s:byte(i))%4294967296 end; return string.format("%08x",h) end
local function download(url) local ok,res=pcall(function() return game:HttpGet(url) end); if ok and type(res)=="string" and #res>0 then return res end; local req=request or http_request or (syn and syn.request); if req then local ok2,r=pcall(req,{Url=url,Method="GET"}); if ok2 and r and r.StatusCode==200 and type(r.Body)=="string" and #r.Body>0 then return r.Body end end; return nil end
local function objToMesh(text)
    local v,vt,vn,out={},{},{},{}; local tris,faces=0,0
    local function idx(s,n) if s==nil or s=="" then return nil end; local i=tonumber(s); if not i then return nil end; if i<0 then return n+i+1 end; return i end
    local function corner(a,b,c) local p=v[idx(a,#v) or 0]; if not p then return nil end; local n=vn[idx(c,#vn) or 0] or {0,1,0}; local t=vt[idx(b,#vt) or 0] or {0,0}; return string.format("[%.5f,%.5f,%.5f][%.4f,%.4f,%.4f][%.5f,%.5f,0]",p[1],p[2],p[3],n[1],n[2],n[3],t[1],1-t[2]) end
    for line in text:gmatch("[^\r\n]+") do
        local c=line:sub(1,2)
        if c=="v " then local x,y,z=line:match("^v%s+(%S+)%s+(%S+)%s+(%S+)"); v[#v+1]={tonumber(x) or 0,tonumber(y) or 0,tonumber(z) or 0}
        elseif c=="vt" then local u,w=line:match("^vt%s+(%S+)%s+(%S+)"); vt[#vt+1]={tonumber(u) or 0,tonumber(w) or 0}
        elseif c=="vn" then local x,y,z=line:match("^vn%s+(%S+)%s+(%S+)%s+(%S+)"); vn[#vn+1]={tonumber(x) or 0,tonumber(y) or 1,tonumber(z) or 0}
        elseif c=="f " then
            local corners={}; for tok in line:gmatch("%S+") do if tok~="f" then local a,b,cc=tok:match("^(%-?%d+)/?(%-?%d*)/?(%-?%d*)"); local s=a and corner(a,b,cc); if s then corners[#corners+1]=s end end end
            for i=2,#corners-1 do out[#out+1]=corners[1]; out[#out+1]=corners[i]; out[#out+1]=corners[i+1]; tris=tris+1 end
            faces=faces+1; if faces%4000==0 then task.wait() end
        end
    end
    if tris==0 then return nil,0 end; return "version 1.00\n"..tris.."\n"..table.concat(out),tris
end
local stats={cached=0,downloaded=0,failed=0}; local failedList={}; local cdnAssets={}
local function loadAsset(path) for _=1,5 do if isfile(path) then local ok,a=pcall(getcustomasset,path); if ok and a then return a end end; task.wait(0.3) end; return nil end
local loading={}; local loadCdnInner
local function loadCdn(url) if cdnAssets[url] then return cdnAssets[url] end; if loading[url] then while loading[url] do task.wait() end; return cdnAssets[url] end; loading[url]=true; local ok,res=pcall(loadCdnInner,url); loading[url]=nil; if ok then return res end; return nil end
loadCdnInner=function(url)
    local name=url:match("[^/]+$") or url; local ext=(url:match("%.(%w+)$") or "bin"):lower()
    local convert=(ext=="obj" and CONVERT_OBJ); local path=CDN_FOLDER.."/"..hashStr(url)..".".. (convert and "mesh" or ext)
    if isfile(path) then stats.cached=stats.cached+1
    else
        print("[Monster] downloading "..name); local data=download(url)
        if not data then stats.failed=stats.failed+1; failedList[#failedList+1]=name.." (download failed)"; return nil end
        if #data<200 and data:find("404") then stats.failed=stats.failed+1; failedList[#failedList+1]=name.." (404 not found)"; return nil end
        if convert then
            local mesh,tris=objToMesh(data); if not mesh then stats.failed=stats.failed+1; failedList[#failedList+1]=name.." (no faces in obj)"; return nil end
            print(("[Monster] %s -> %d triangles"):format(name,tris)); if tris>20000 then warn("[Monster] "..name.." has over 20k triangles") end; data=mesh
        end
        if not pcall(writefile,path,data) then stats.failed=stats.failed+1; failedList[#failedList+1]=name.." (could not save)"; return nil end
        stats.downloaded=stats.downloaded+1
    end
    local asset=loadAsset(path); if not asset then stats.failed=stats.failed+1; failedList[#failedList+1]=name.." (getcustomasset failed)"; return nil end
    cdnAssets[url]=asset; return asset
end
local crcTable={}; for i=0,255 do local c=i; for _=1,8 do if bit32.band(c,1)==1 then c=bit32.bxor(bit32.rshift(c,1),0xEDB88320) else c=bit32.rshift(c,1) end end; crcTable[i]=c end
local function crc32(s) local c=0xFFFFFFFF; for i=1,#s do c=bit32.bxor(crcTable[bit32.band(bit32.bxor(c,s:byte(i)),0xFF)],bit32.rshift(c,8)) end; return bit32.bxor(c,0xFFFFFFFF) end
local function adler32(s) local a,b=1,0; for i=1,#s do a=(a+s:byte(i))%65521; b=(b+a)%65521 end; return b*65536+a end
local function pngChunk(kind,data) return string.pack(">I4",#data)..kind..data..string.pack(">I4",crc32(kind..data)) end
local function makePng(w,h,pixel)
    local rows={}; for y=0,h-1 do local row={"\0"}; for x=0,w-1 do local r,g,b=pixel(x,y); row[#row+1]=string.char(r,g,b) end; rows[#rows+1]=table.concat(row) end
    local raw=table.concat(rows); local blocks={"\120\1"}; local pos=1
    while pos<=#raw do local piece=raw:sub(pos,pos+65534); pos=pos+#piece; local final=(pos>#raw) and 1 or 0; blocks[#blocks+1]=string.char(final)..string.pack("<I2",#piece)..string.pack("<I2",bit32.band(bit32.bnot(#piece),0xFFFF))..piece end
    blocks[#blocks+1]=string.pack(">I4",adler32(raw))
    return "\137PNG\r\n\26\n"..pngChunk("IHDR",string.pack(">I4I4",w,h).."\8\2\0\0\0")..pngChunk("IDAT",table.concat(blocks))..pngChunk("IEND","")
end
local RED={205,20,30}; local WHITE={245,245,245}; local BLACK={0,0,0}
local TEXTURES={
    white=function(x,y) local v=252; for k=-1,1 do local cx=128+k*40+(y-128)*0.35; if y>40 and y<216 and math.abs(x-cx)<6 then v=210 end end; return v,v,v end,
    black=function() return 0,0,0 end,
}
local textureAssets={}
local function texAsset(key)
    if textureAssets[key] then return textureAssets[key] end
    local gen=TEXTURES[key]; if not gen then warn("[Monster] unknown texture: "..tostring(key)); return nil end
    local path=CDN_FOLDER.."/tex_"..key.."_"..TEXTURE_VERSION..".png"
    if not isfile(path) then local ok,png=pcall(makePng,256,256,gen); if not ok or not pcall(writefile,path,png) then stats.failed=stats.failed+1; failedList[#failedList+1]="texture "..key.." (could not build)"; return nil end; print("[Monster] built texture: "..key) end
    local asset=loadAsset(path); if not asset then stats.failed=stats.failed+1; failedList[#failedList+1]="texture "..key.." (getcustomasset failed)"; return nil end
    textureAssets[key]=asset; return asset
end
local HttpService=game:GetService("HttpService"); local AssetService=game:GetService("AssetService")
local rules=HttpService:JSONDecode(CONFIG).replacement_rules
local lookup,meshCache={},{}; local registered,swapped=0,0
local function parseId(v) return tonumber(tostring(v):match("(%d+)")) end
local function resolve(rule)
    if rule.mode=="texture" then return texAsset(rule.texture) end
    if rule.mode=="cdn" then return loadCdn(rule.cdn_url) end
    if rule.with_id then return "rbxassetid://"..rule.with_id end; return ""
end
local function flatten(list,out) for _,r in ipairs(list) do if r.type=="group" then flatten(r.children or {},out) elseif r.enabled then local skip=(r.icon=="texture" and not ICONS_USE_TEXTURES) or (r.icon=="original" and ICONS_USE_TEXTURES); if not skip then out[#out+1]=r end end end; return out end
local active=flatten(rules,{}); local targets={}; local pendingCount=#active
for i,rule in ipairs(active) do task.spawn(function() local ok,res=pcall(resolve,rule); if ok then targets[i]=res end; pendingCount=pendingCount-1 end) end
while pendingCount>0 do task.wait() end
local meshAssets={}
for i,rule in ipairs(active) do
    local target=targets[i]
    if target~=nil then
        registered=registered+1
        local entry={target=target}; if rule.scale then entry.scale=SCALES[rule.scale] end; entry.fit=rule.fit; entry.role=rule.role
        if rule.color then entry.color=Color3.fromRGB(rule.color[1],rule.color[2],rule.color[3]) end
        if rule.texture and rule.mode~="texture" then entry.texture=texAsset(rule.texture) end
        if target~="" and rule.mode~="texture" and (rule.texture or rule.scale) then meshAssets[target]=true end
        for _,id in ipairs(rule.replace_ids) do local n=parseId(id); if n then lookup[n]=entry end end
    end
end
if MESH_METHOD~="direct" then
    local warming=0; for asset in pairs(meshAssets) do warming=warming+1; task.spawn(function() pcall(function() meshCache[asset]=AssetService:CreateMeshPartAsync(asset) end); warming=warming-1 end) end
    local t0=os.clock(); while warming>0 and os.clock()-t0<15 do task.wait() end
end
print(("[Monster] rules ready: %d | cached: %d | downloaded: %d | failed: %d"):format(registered,stats.cached,stats.downloaded,stats.failed))
for _,f in ipairs(failedList) do warn("[Monster] FAILED: "..f) end
local PROPS={MeshPart={"MeshId","TextureID"},SpecialMesh={"MeshId","TextureId"},Sound={"SoundId"},Animation={"AnimationId"},Decal={"Texture"},Texture={"Texture"},ImageLabel={"Image"},ImageButton={"Image"},SurfaceAppearance={"ColorMap","NormalMap","MetalnessMap","RoughnessMap"}}
local seen=setmetatable({},{__mode="k"}); local forcedTexture=setmetatable({},{__mode="k"}); local scaleState=setmetatable({},{__mode="k"})
local origSize=setmetatable({},{__mode="k"}); local fitState=setmetatable({},{__mode="k"})
local function hideMesh(inst) pcall(function() if inst:IsA("MeshPart") then inst.Transparency=1 elseif inst:IsA("SpecialMesh") then inst.Scale=Vector3.new(0,0,0) end end) end
local function fitMesh(inst,asset)
    pcall(function()
        local target=fitState[inst]
        if not target then
            local mp=meshCache[asset]
            if not mp then local ok,res=pcall(function() return AssetService:CreateMeshPartAsync(asset) end); if ok then mp=res; meshCache[asset]=mp end end
            local o=origSize[inst]
            if mp and o then local n=mp.Size; local nMax=math.max(n.X,n.Y,n.Z); if nMax>0 then local f=math.max(o.X,o.Y,o.Z)/nMax; target=n*f; fitState[inst]=target end end
        end
        if target then inst.Size=target end
    end)
end
local function applyMesh(inst,asset,entry)
    if not inst:IsA("MeshPart") then pcall(function() inst.MeshId=asset end); return end
    if not origSize[inst] then origSize[inst]=inst.Size end
    if MESH_METHOD~="apply" then pcall(function() inst.MeshId=asset end) end
    if MESH_METHOD~="direct" then
        local ok,err=pcall(function() local mp=meshCache[asset]; if not mp then mp=AssetService:CreateMeshPartAsync(asset); meshCache[asset]=mp end; inst:ApplyMesh(mp) end)
        if not ok then warn("[Monster] ApplyMesh failed: "..tostring(err)) end
    end
    if not entry or entry.fit~=false then fitMesh(inst,asset) end
end
local function setTarget(inst,value) pcall(function() if inst:IsA("MeshPart") then inst.Size=value else inst.Scale=value end end) end
local function applyScale(inst,factor)
    if not factor or factor==1 then return end
    local st=scaleState[inst]; if st~=nil then if st then task.defer(setTarget,inst,st) end; return end
    scaleState[inst]=false
    task.spawn(function() task.wait(0.1); local target; pcall(function() if inst:IsA("MeshPart") then target=inst.Size*factor elseif inst:IsA("SpecialMesh") then target=inst.Scale*factor end end); if target then scaleState[inst]=target; setTarget(inst,target) end end)
end
local function setTexture(inst,asset)
    local prop=inst:IsA("SpecialMesh") and "TextureId" or "TextureID"; forcedTexture[inst]=asset; pcall(function() inst[prop]=asset end)
end
local roleOf=setmetatable({},{__mode="k"}); local glueStarted=setmetatable({},{__mode="k"})
local function tryGlue(inst)
    if glueStarted[inst] then return end; glueStarted[inst]=true
    for _=1,40 do
        task.wait(1)
        local ok=pcall(function()
            local root=inst:FindFirstAncestorWhichIsA("Tool") or inst:FindFirstAncestorWhichIsA("Model") or inst.Parent
            if not root then error("no root") end
            local body,logo
            for _,d in ipairs(root:GetDescendants()) do if roleOf[d]=="body" and not body then body=d end; if roleOf[d]=="logo" and not logo then logo=d end end
            if not body or not logo then error("pair not ready") end
            if scaleState[body]==false then error("body still scaling") end
            if not body:IsDescendantOf(workspace) then error("not in workspace") end
            pcall(function() body.CollisionFidelity=Enum.CollisionFidelity.PreciseConvexDecomposition end)
            pcall(function() body.CanQuery=true end)
            local center=body.Position; local offset=logo.Position-center
            if offset.Magnitude<0.001 then error("logo at center") end
            local dir=offset.Unit; local rp=RaycastParams.new(); rp.FilterType=Enum.RaycastFilterType.Include; rp.FilterDescendantsInstances={body}
            local far=body.Size.Magnitude+offset.Magnitude+2; local res=workspace:Raycast(center+dir*far,-dir*far*2,rp)
            if not res then error("no hit") end
            local n,cf,sz=res.Normal,logo.CFrame,logo.Size
            local half=(math.abs(n:Dot(cf.RightVector))*sz.X+math.abs(n:Dot(cf.UpVector))*sz.Y+math.abs(n:Dot(cf.LookVector))*sz.Z)/2
            local newCf=CFrame.new(res.Position+n*(half-0.01))*(cf-cf.Position)
            for _,d in ipairs(root:GetDescendants()) do if (d:IsA("JointInstance") or d:IsA("WeldConstraint")) and (d.Part0==logo or d.Part1==logo) then pcall(function() d.Enabled=false end) end end
            logo.CFrame=newCf; local w=Instance.new("WeldConstraint"); w.Part0=body; w.Part1=logo; w.Parent=logo
            print("[Monster] logo glued to can")
        end)
        if ok then return end
    end
    glueStarted[inst]=nil; warn("[Monster] could not glue the logo")
end
local function handle(inst,p)
    local ok,cur=pcall(function() return inst[p] end); if not ok then return end
    local forced=forcedTexture[inst]
    if forced and (p=="TextureID" or p=="TextureId") then if cur~=forced then pcall(function() inst[p]=forced end) end; return end
    local id=parseId(cur); local entry=id and lookup[id]; if entry==nil then return end
    local new=entry.target; swapped=swapped+1
    if swapped<=15 then print("[Monster] swapped "..inst.ClassName.."."..p.." ("..tostring(id)..")") end
    if p=="MeshId" then
        if new=="" then hideMesh(inst)
        else applyMesh(inst,new,entry); if entry.texture then setTexture(inst,entry.texture) end; if entry.color then pcall(function() inst.Color=entry.color end) end; applyScale(inst,entry.scale); if entry.role then roleOf[inst]=entry.role; task.spawn(tryGlue,inst) end end
    else pcall(function() inst[p]=new end) end
end
local function apply(inst)
    local props=PROPS[inst.ClassName]; if not props or seen[inst] then return end; seen[inst]=true
    for _,p in ipairs(props) do task.spawn(handle,inst,p); pcall(function() inst:GetPropertyChangedSignal(p):Connect(function() handle(inst,p) end) end) end
end
local function scan() local n=0; for _,d in ipairs(game:GetDescendants()) do apply(d); n=n+1; if n%2000==0 then task.wait() end end end
local function scanNil() if type(getnilinstances)~="function" then return end; pcall(function() for _,d in ipairs(getnilinstances()) do apply(d); for _,c in ipairs(d:GetDescendants()) do apply(c) end end end) end
game.DescendantAdded:Connect(apply); scan(); scanNil()
task.spawn(function() while true do task.wait(2); scan(); scanNil() end end)
print("[Monster] loaded")
]====]

------------------------------------------------------------------------
-- END OF FILE
------------------------------------------------------------------------
print("[RivalsSkinUI] ready — " .. #SKINS .. " skins registered. Press RightControl to toggle.")
