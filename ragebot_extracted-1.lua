local ragebot = {}
do
local replicatedstorage = cloneref(game:GetService("ReplicatedStorage"))
local players = cloneref(game:GetService("Players"))
local runsvc = cloneref(game:GetService("RunService"))
local userinput = cloneref(game:GetService("UserInputService"))
local workspace = cloneref(game:GetService("Workspace"))
local player = players.LocalPlayer
local camera = workspace.CurrentCamera
local modules = {
    enums = instanceSafeRequire(replicatedstorage.Modules.EnumLibrary),
    fighter = instanceSafeRequire(player.PlayerScripts.Controllers.FighterController),
    camcontrol = instanceSafeRequire(player.PlayerScripts.Controllers.CameraController),
    utility = instanceSafeRequire(replicatedstorage.Modules.Utility)
}
local MATCH_ID_ATTRS = {"MatchId", "DuelId", "RoundId", "GameId", "MatchUUID", "ArenaId", "InstanceId"}
local DUEL_STATE_ATTRS = {"InDuel", "InMatch", "InRound", "InGame", "InFight", "IsInMatch", "IsInDuel", "MatchActive", "Fighting"}
local SPAWN_SAFE_ATTRS = {"InSpawn", "InLobby", "IsSpectating", "InSafeZone", "InIntermission", "IsRespawning"}
local function inLive(targetPlr)
    if not targetPlr then return false end
    local live = workspace:FindFirstChild("Live")
    if not live then return false end
    if live:FindFirstChild(targetPlr.Name) then return true end
    if live:FindFirstChild(tostring(targetPlr.UserId)) then return true end
    for _, child in ipairs(live:GetChildren()) do
        if child.Name == targetPlr.Name or child.Name == tostring(targetPlr.UserId) then
            return true
        end
    end
    local char = targetPlr.Character
    if char and (char.Parent == live or char:IsDescendantOf(live)) then
        return true
    end
    local fc = modules.fighter
    if fc and type(fc.GetFighter) == "function" then
        local ok, fighter = pcall(fc.GetFighter, fc, targetPlr)
        if ok and fighter and fighter.Entity and fighter.Entity.Parent then
            if fighter.Entity.Parent == live or fighter.Entity:IsDescendantOf(live) then
                return true
            end
        end
    end
    return false
end
local function plrMid(targetPlr)
    if not targetPlr then return nil end
    for _, key in ipairs(MATCH_ID_ATTRS) do
        local v = targetPlr:GetAttribute(key)
        if v ~= nil and v ~= "" and v ~= 0 and v ~= false then
            return tostring(v)
        end
    end
    local char = targetPlr.Character
    if char then
        for _, key in ipairs(MATCH_ID_ATTRS) do
            local v = char:GetAttribute(key)
            if v ~= nil and v ~= "" and v ~= 0 and v ~= false then
                return tostring(v)
            end
        end
    end
    return nil
end
local function liveMatch()
    local lp = player
    if not lp then return false end
    for _, key in ipairs(SPAWN_SAFE_ATTRS) do
        local v = lp:GetAttribute(key)
        if v == true or v == 1 or v == "true" then
            return false
        end
    end
    local char = lp.Character
    if not char then return false end
    for _, key in ipairs(SPAWN_SAFE_ATTRS) do
        local cv = char:GetAttribute(key)
        if cv == true or cv == 1 or cv == "true" then
            return false
        end
    end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local myRoot = char:FindFirstChild("HumanoidRootPart")
    if not hum or hum.Health <= 0 or not myRoot then return false end
    for _, key in ipairs(DUEL_STATE_ATTRS) do
        local v = lp:GetAttribute(key)
        if v == true or v == 1 or v == "true" then
            return true
        end
        local cv = char:GetAttribute(key)
        if cv == true or cv == 1 or cv == "true" then
            return true
        end
    end
    if inLive(lp) then
        return true
    end
    local fc = modules.fighter
    if fc and fc.LocalFighter and fc.LocalFighter.Entity and fc.LocalFighter.Entity.Parent then
        return true
    end
    local myMatchId = plrMid(lp)
    if myMatchId then
        for _, plr in players:GetPlayers() do
            if plr ~= lp and plrMid(plr) == myMatchId then
                return true
            end
        end
    end
    if fc then
        for _, list in ipairs({ fc.Fighters, fc.AllFighters }) do
            if list then
                for _, f in pairs(list) do
                    if f and f.Player and f.Player ~= lp and (f.IsEnemy or f.Enemy) then
                        local fChar = f.Player.Character
                        local fHum = fChar and fChar:FindFirstChildOfClass("Humanoid")
                        if fHum and fHum.Health > 0 then
                            return true
                        end
                    end
                end
            end
        end
    end
    return false
end
local _instanceLobbyCache = { t = 0, v = true }
local function lobbyCache()
    local now = os.clock()
    if now - _instanceLobbyCache.t < 0.15 then
        return _instanceLobbyCache.v
    end
    _instanceLobbyCache.t = now
    _instanceLobbyCache.v = not liveMatch()
    return _instanceLobbyCache.v
end
getgenv().InstanceIsInActiveMatch = liveMatch
getgenv().InstanceIsInLobby = lobbyCache
local config = {
    target = {
        enabled = false,
        character = nil,
        auto = false,
        autoshoot = true,
        shootAttempts = 1,
        hitpart = "Head",
        lastchar = nil,
        lastplayer = nil,
        manualkey = false,
        immune = false,
        attackPosition = "default",
        attackCustomEnabled = false,
        weaponPick = "primary",
        forceWeapon = true,
        rageMasterOn = false,
        meleeFeetDrop = 3.5,
        underOffset = 4,
        customHeight = 2,
        customFront = 0,
        customSide = 0,
        customVertical = 0,
        customRadius = 0,
    },
    prediction = {
        enabled = false,
        multiplier = 1.2,
        velocity = Vector3.new(0, 0, 0),
        acceleration = Vector3.new(0, 0, 0),
        lastposition = nil,
        lasttime = 0,
        velbuffer = {},
        posbuffer = {},
        maxvelsamples = 15,
        maxpossamples = 5
    },
    orbit = {
        active = false,
        angle = 0,
        serverpos = nil,
        connection = nil,
        speed = 9000,
        height = 1,
        radius = 0,
        originalpos = nil
    },
    state = {
        reloading = false,
        outofammo = false,
        csyncactive = false,
        reloadStartedAt = 0,
    },
    voidhide = {
        enabled = true,
        originalPosition = nil,
        active = false,
        connection = nil
    },
    voidspam = {
        enabled = false,
        shoot_min = 1,
        shoot_max = 1,
        hide_min = 1,
        hide_max = 1,
        phase = nil,
        lastswitch = 0,
        currentduration = 0
    },
    visualizer = {
        enabled = true,
        tracer = {
            color = Color3.fromRGB(0, 186, 255),
            thickness = 1,
            transparency = 1,
            start_point = "cursor",
            outline = true,
            outline_color = Color3.fromRGB(0, 0, 0),
            outline_thickness = 1
        },
        indicator = {
            display_options = {"name", "position", "hit reg"},
            color = Color3.fromRGB(255, 255, 255),
            accent_color = Color3.fromRGB(0, 186, 255)
        }
    },
    hitNotifications = {
        enabled = true,
        color = Color3.fromRGB(235, 235, 235),
        textSize = 14,
        maxVisible = 8,
        duration = 3,
        stackGap = 6,
        position = "Top Left",
        offsetX = 12,
        offsetY = 12,
        inAnimation = "fade bounce",
        outAnimation = "fade",
        animInDuration = 0.52,
        animOutDuration = 0.38,
    },
    ragestatus = {
        enabled = false,
        mode = "static",
        color = Color3.fromRGB(235, 235, 235),
        staticOffsetX = 0,
        staticOffsetY = 40,
        showAmmo = true,
        hideOnReload = true,
        textSize = 15,
        lineGap = 15,
        fontName = "gotham",
    },
}
local ragePerf = {
    lastAttackTick = 0,
    hitPartByPlayer = {},
    lastHitAtByPlayer = {},
    targetHudAt = 0,
    rageStatusAt = 0,
    restoreVisualAt = 0,
    killStartAt = nil,
    rageStatusCacheAt = 0,
    cachedRageStatusLine = "",
    cachedRageStatusDetail = "",
    lastRageStatusText = "",
    lastRageDetailText = "",
    lastRageAmmoText = "",
    lastRageColor = nil,
}
local vhState = {
    active = false,
    hrp = nil,
    mainConnection = nil,
    restoreConnection = nil,
    currentVoidPos = nil,
    lastTeleportTime = 0
}
local localfighter = modules.fighter.LocalFighter
local oldpos
local indicator = Drawing.new("Circle")
indicator.Thickness = 1.5
indicator.NumSides = 36
indicator.Filled = false
indicator.Transparency = 1
indicator.Visible = false
indicator.Radius = 12
indicator.Color = Color3.fromRGB(255, 50, 50)
local indicatoroutline = Drawing.new("Circle")
indicatoroutline.Thickness = 4
indicatoroutline.NumSides = 36
indicatoroutline.Filled = false
indicatoroutline.Transparency = 1
indicatoroutline.Visible = false
indicatoroutline.Radius = 12
indicatoroutline.Color = Color3.fromRGB(0, 0, 0)
local tracerline = Drawing.new("Line")
tracerline.Visible = false
tracerline.Thickness = 2
tracerline.Transparency = 1
tracerline.Color = Color3.fromRGB(0, 186, 255)
local traceroutline = Drawing.new("Line")
traceroutline.Visible = false
traceroutline.Thickness = 4
traceroutline.Transparency = 1
traceroutline.Color = Color3.fromRGB(0, 0, 0)
local lastdamagetime = {}
local function getweapon()
    local viewmodels = workspace:FindFirstChild("ViewModels")
    if not viewmodels then return nil end
    local firstperson = viewmodels:FindFirstChild("FirstPerson")
    if not firstperson then return nil end
    for _, child in ipairs(firstperson:GetChildren()) do
        local parts = {}
        for part in child.Name:gmatch("[^-]+") do
            table.insert(parts, part:match("^%s*(.-)%s*$"))
        end
        if #parts >= 2 then
            return parts[2]
        end
    end
    return nil
end
local function muzzlepos()
    local viewModels = workspace:FindFirstChild("ViewModels")
    if not viewModels then return nil end
    local firstPerson = viewModels:FindFirstChild("FirstPerson")
    if not firstPerson then return nil end
    for _, model in pairs(firstPerson:GetChildren()) do
        if model.Name:find(player.Name) then
            local itemVisual = model:FindFirstChild("ItemVisual")
            if itemVisual then
                local body = itemVisual:FindFirstChild("Body")
                if body then
                    local bodyPrimary = body:FindFirstChild("BodyPrimary")
                    if bodyPrimary then
                        local muzzle = bodyPrimary:FindFirstChild("_muzzle")
                        if muzzle then
                            return muzzle.WorldPosition
                        end
                    end
                end
            end
        end
    end
    return nil
end
local SLOTS = { primary = 1, secondary = 2, melee = 3 }
local MELEE_NMS = {
    ["Battle Axe"] = true, ["Chainsaw"] = true, ["Daggers"] = true, ["Fists"] = true,
    ["Gunblade"] = true, ["Katana"] = true, ["Knife"] = true,
    ["Scythe"] = true, ["Trowel"] = true,
}
local INFINITE_AMMO_WEAPONS = {
    ["Energy Rifle"] = true,
    ["Energy Pistols"] = true,
}
local function isInfiniteWeapon()
    local w = getweapon()
    if not w then return false end
    return INFINITE_AMMO_WEAPONS[w] == true
end
local function wantSlot()
    return SLOTS[config.target.weaponPick or "primary"] or 1
end
local function pickMelee()
    return (config.target.weaponPick or "primary") == "melee"
end
local function getammo()
    if isInfiniteWeapon() then return nil, nil, false end
    local success, controller = pcall(function()
        return instanceSafeRequire(player.PlayerScripts.Controllers.FighterController)
    end)
    if success and controller and controller.LocalFighter and controller.LocalFighter.EquippedItem then
        local item = controller.LocalFighter.EquippedItem
        local itemName, current, maxAmmo = "", 0, 0
        local isMelee = false
        local ok = pcall(function()
            itemName = tostring(item:Get("Name") or item.Name or "")
            current = item:Get("CurrentAmmo") or item:Get("Ammo") or 0
            maxAmmo = item:Get("MaxAmmo") or item:Get("MaxBullets") or current
            if type(itemName) == "string" and itemName:lower():find("melee", 1, true) then
                isMelee = true
            end
            if MELEE_NMS[itemName] then isMelee = true end
        end)
        if not ok then
            return 0, 0, pickMelee()
        end
        if pickMelee() then isMelee = true end
        return tonumber(current) or 0, tonumber(maxAmmo) or 0, isMelee
    end
    return 0, 0, pickMelee()
end
local function meleeNm(nm)
    if type(nm) ~= "string" or nm == "" then return false end
    if nm:lower():find("melee", 1, true) then return true end
    return MELEE_NMS[nm] == true
end
local function itemMelee(item)
    if not item then return false end
    local nm = item:Get("Name") or item.Name
    if meleeNm(nm) then return true end
    local t = item:Get("ItemType") or item:Get("Type") or item:Get("Category")
    return type(t) == "string" and t:lower():find("melee", 1, true) ~= nil
end
local function isSling(weapon)
    return weapon and weapon:lower():find("slingshot", 1, true) ~= nil
end
local function lfItems()
    local lf = modules.fighter and modules.fighter.LocalFighter
    if not lf then return nil end
    return lf.Items
end
local function slotItem(slotIdx)
    local items = lfItems()
    if not items then return nil end
    if items[slotIdx] then return items[slotIdx] end
    if items[tostring(slotIdx)] then return items[tostring(slotIdx)] end
    for key, it in pairs(items) do
        if it and typeof(it) == "table" then
            local s = tonumber(it:Get("Slot") or it:Get("Index") or it:Get("ItemSlot") or key)
            if s == slotIdx then return it end
            local t = it:Get("ItemType") or it:Get("Type")
            if slotIdx == 3 and (t == "Melee" or (type(t) == "string" and t:lower():find("melee", 1, true))) then
                return it
            end
            if slotIdx == 1 and (t == "Primary" or t == 1 or t == "1") then return it end
            if slotIdx == 2 and (t == "Secondary" or t == 2 or t == "2") then return it end
        end
    end
    local ordered = {}
    for _, it in pairs(items) do
        if it then ordered[#ordered + 1] = it end
    end
    table.sort(ordered, function(a, b)
        local sa = tonumber(a:Get("Slot") or a:Get("Index")) or 99
        local sb = tonumber(b:Get("Slot") or b:Get("Index")) or 99
        return sa < sb
    end)
    return ordered[slotIdx]
end
local function whichSlot(item)
    if not item then return nil end
    local items = lfItems()
    local oid = item:Get("ObjectID")
    if items and oid then
        for idx = 1, 3 do
            local it = items[idx] or items[tostring(idx)]
            if it and it:Get("ObjectID") == oid then return idx end
        end
        for key, it in pairs(items) do
            if it and it:Get("ObjectID") == oid then
                local n = tonumber(key)
                if n and n >= 1 and n <= 3 then return n end
            end
        end
    end
    if itemMelee(item) then return 3 end
    return nil
end
local rageLastSlotForce = 0
local function pressSlot(slotIdx)
    if IS_MOBILE then
        return
    end
    pcall(function()
        local vim = game:GetService("VirtualInputManager")
        local kc = ({ Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three })[slotIdx]
        if not kc then return end
        vim:SendKeyEvent(true, kc, false, game)
        task.wait(0.02)
        vim:SendKeyEvent(false, kc, false, game)
    end)
    if keypress then
        pcall(keypress, ({ 0x31, 0x32, 0x33 })[slotIdx])
        task.wait(0.02)
        if keyrelease then pcall(keyrelease, ({ 0x31, 0x32, 0x33 })[slotIdx]) end
    end
end
local function rageOn()
    if Toggles and Toggles.TargetOn then
        return Toggles.TargetOn.Value == true
    end
    return config.target.rageMasterOn == true
end
local function eqSlot()
    if not rageOn() then return end
    local want = wantSlot()
    local lf = modules.fighter and modules.fighter.LocalFighter
    if not lf then return end
    local eq = lf.EquippedItem
    if eq and whichSlot(eq) == want then return end
    local now = tick()
    if now - rageLastSlotForce < 0.06 then return end
    rageLastSlotForce = now
    local item = slotItem(want)
    local oid = item and item:Get("ObjectID")
    if oid then
        local rm = replicatedstorage.Remotes.Replication.Fighter.UseItem
        for _, en in ipairs({ "Equip", "Switch", "Select", "EquipItem", "ChangeItem" }) do
            pcall(function()
                local ev = modules.enums:ToEnum(en)
                if ev then rm:FireServer(oid, ev, nil, nil) end
            end)
        end
    end
    pcall(function()
        if lf.EquipItem then lf:EquipItem(want) end
        if lf.Equip then lf:Equip(want) end
        if lf.SwitchToSlot then lf:SwitchToSlot(want) end
    end)
    pcall(function()
        local fc = modules.fighter
        if fc.EquipItem then fc:EquipItem(want) end
        if fc.SwitchItem then fc:SwitchItem(want) end
    end)
    if not IS_MOBILE then
        pressSlot(want)
    end
end
local function itemReload()
    if isInfiniteWeapon() then return false end
    local lf = modules.fighter and modules.fighter.LocalFighter
    if not lf or not lf.EquippedItem then return false end
    local result = false
    pcall(function()
        local item = lf.EquippedItem
        for _, key in ipairs({ "Reloading", "IsReloading", "IsReload" }) do
            local value = item:Get(key)
            if value == true or value == 1 or value == "true" then
                result = true
                return
            end
        end
    end)
    if result then return true end
    local started = config.state.reloadStartedAt or 0
    return started > 0 and (tick() - started) < 1.75
end
local function tickAmmo()
    if isInfiniteWeapon() then
        config.state.outofammo = false
        config.state.reloading = false
        config.state.reloadStartedAt = 0
        return
    end
    local current, maxAmmo, melee = getammo()
    local wasOutOfAmmo = config.state.outofammo
    if melee then
        config.state.outofammo = false
    else
        config.state.outofammo = (tonumber(current) or 0) <= 0
    end
    local reloading = itemReload()
    if reloading and not config.state.reloading then
        config.state.reloadStartedAt = tick()
    elseif not reloading then
        config.state.reloadStartedAt = 0
    end
    config.state.reloading = reloading
    if config.state.outofammo and not wasOutOfAmmo then
        if isSling(getweapon()) then
            config.voidspam.phase = "hide"
        end
    elseif not config.state.outofammo and wasOutOfAmmo then
        if config.voidspam.enabled then
            config.voidspam.phase = "shoot"
            config.voidspam.lastswitch = tick()
        else
            config.voidspam.phase = nil
        end
    end
end
local function reloadHide(sling)
    if not (config.state.reloading and config.ragestatus.hideOnReload) then
        return false
    end
    local hrp = voidHrp()
    if hrp and not sling then
        snapVoid(hrp)
        return true
    end
    local randomX = math.random(-10000, 10000)
    local randomZ = math.random(-10000, 10000)
    config.orbit.serverpos = Vector3.new(randomX, -99999999999, randomZ)
    if sling and localfighter and localfighter.Entity and localfighter.Entity.RootPart then
        pcall(function()
            localfighter.Entity.RootPart.CFrame = CFrame.new(config.orbit.serverpos)
        end)
    end
    return true
end
local function isteammate(targetplayer)
    if not targetplayer then return false end
    return player:GetAttribute("TeamID") == targetplayer:GetAttribute("TeamID")
end
local function valid(char)
    if not char or not char.Parent then return false end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end
    if not char:FindFirstChild("HumanoidRootPart") then return false end
    local targetplayer = players:GetPlayerFromCharacter(char)
    if not targetplayer or isteammate(targetplayer) then return false end
    return true
end
local function nearest()
    local cursorpos
    if IS_MOBILE then
        if MOBILE_TOUCH_STATE.touching then
            cursorpos = MOBILE_TOUCH_STATE.touchCurrentPos
        else
            local cam = workspace.CurrentCamera
            if cam then
                cursorpos = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
            else
                cursorpos = Vector2.zero
            end
        end
    else
        cursorpos = userinput:GetMouseLocation()
    end
    local besttarget = nil
    local bestdistance = math.huge
    for _, targetplayer in players:GetPlayers() do
        if targetplayer ~= player and targetplayer.Character then
            local char = targetplayer.Character
            if valid(char) then
                local root = char:FindFirstChild("HumanoidRootPart")
                if root then
                    local wts = getgenv().InstanceWorldToScreen or worldToScreen
                    local screenpos, onscreen = wts(root.Position, camera)
                    if onscreen and screenpos then
                        local distance = (Vector2.new(screenpos.X, screenpos.Y) - cursorpos).Magnitude
                        if distance < bestdistance then
                            besttarget = char
                            bestdistance = distance
                        end
                    end
                end
            end
        end
    end
    return besttarget
end
local function hitpartfromname(character, partname)
    if not character then return nil end
    if partname == "Closest" then
        local mypos = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if not mypos then return character:FindFirstChild("Head") end
        local closest, dist = nil, math.huge
        for _, part in pairs(character:GetChildren()) do
            if part:IsA("BasePart") then
                local d = (part.Position - mypos.Position).Magnitude
                if d < dist then
                    dist = d
                    closest = part
                end
            end
        end
        return closest or character:FindFirstChild("Head")
    elseif partname == "Random" then
        local parts = {"Head", "HumanoidRootPart", "UpperTorso"}
        return character:FindFirstChild(parts[math.random(#parts)]) or character:FindFirstChild("Head")
    else
        return character:FindFirstChild(partname) or character:FindFirstChild("Head")
    end
end
local function updatevel()
    if not config.target.character or not config.prediction.enabled then
        config.prediction.velocity = Vector3.new(0, 0, 0)
        config.prediction.lastposition = nil
        return
    end
    local root = config.target.character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local now = tick()
    local dt = now - config.prediction.lasttime
    if dt > 0 and dt < 0.1 then
        local currentpos = root.Position
        if config.prediction.lastposition then
            local instantvel = (currentpos - config.prediction.lastposition) / dt
            config.prediction.velocity = config.prediction.velocity:Lerp(instantvel, 0.6)
        end
        config.prediction.lastposition = currentpos
        config.prediction.lasttime = now
    end
end
local function predict(targetpart, origin)
    if not config.prediction.enabled or not targetpart then
        return targetpart and targetpart.Position or Vector3.new()
    end
    local basepos = targetpart.Position
    local distance = (basepos - origin).Magnitude
    local ping = 0
    pcall(function()
        ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue() / 1000
    end)
    local traveltime = distance / 3000
    local totaltime = (traveltime + ping) * config.prediction.multiplier
    return basepos + (config.prediction.velocity * totaltime)
end
local function canuse()
    local char = player.Character
    if not char then return false end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end
    if isInfiniteWeapon() then return true end
    local current, _, melee = getammo()
    if current == nil then return true end
    return current > 0 or melee
end
local function clampVs(v)
    return math.clamp(tonumber(v) or 1, 0.1, 2)
end
local function randVs(minT, maxT)
    local a = clampVs(minT)
    local b = clampVs(maxT)
    if b < a then
        a, b = b, a
    end
    if a == b then
        return a
    end
    return a + math.random() * (b - a)
end
local vfrLim, vfrDead = 2147483646, 1147483646
local vfrSnap = { cf = nil, lv = nil, av = nil }
local function clrVoidSnap()
    vfrSnap.cf, vfrSnap.lv, vfrSnap.av = nil, nil, nil
end
local function voidHrp()
    local char = player.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end
local function rndSkip(mi, ma, dmi, dma)
    local val = math.random(mi, ma)
    while val >= dmi and val <= dma do
        val = math.random(mi, ma)
    end
    return val
end
local function snapVoid(hrp)
    if not hrp then return end
    if lobbyCache() then return end
    vfrSnap.cf = hrp.CFrame
    vfrSnap.lv = hrp.AssemblyLinearVelocity
    vfrSnap.av = hrp.AssemblyAngularVelocity
    local lim, dead = vfrLim, vfrDead
    pcall(function()
        local p = Vector3.new(rndSkip(-lim, lim, -dead, dead), rndSkip(-lim, lim, -dead, dead), rndSkip(-lim, lim, -dead, dead))
        local v = Vector3.new(rndSkip(-lim, lim, -dead, dead), rndSkip(-lim, lim, -dead, dead), rndSkip(-lim, lim, -dead, dead))
        hrp.CFrame = CFrame.new(p) * CFrame.Angles(math.pi, math.pi, math.pi)
        hrp.AssemblyLinearVelocity = v
        hrp.AssemblyAngularVelocity = v
    end)
end
runsvc:BindToRenderStep("vfr_csync", Enum.RenderPriority.First.Value, function()
    if not vfrSnap.cf then return end
    local hrp = voidHrp()
    if not hrp then return end
    pcall(function()
        hrp.CFrame = vfrSnap.cf
        hrp.AssemblyLinearVelocity = vfrSnap.lv
        hrp.AssemblyAngularVelocity = vfrSnap.av
    end)
end)
local function atkCfg()
    if pickMelee() and not config.target.attackCustomEnabled then
        local drop = tonumber(config.target.meleeFeetDrop) or 3.5
        return {
            height = 0,
            front = 0,
            side = 0,
            vertical = -drop,
            radius = 0,
        }
    end
    if config.target.attackCustomEnabled then
        return {
            height = config.target.customHeight or 2,
            front = config.target.customFront or 0,
            side = config.target.customSide or 0,
            vertical = config.target.customVertical or 0,
            radius = config.target.customRadius or 0,
        }
    end
    local mode = config.target.attackPosition or "default"
    local weapon = getweapon()
    if mode == "under" then
        return {
            height = 0,
            front = 0,
            side = 0,
            vertical = -(config.target.underOffset or 4),
            radius = 0,
        }
    end
    return {
        height = (weapon and weapon:lower():find("sniper")) and 8 or 2,
        front = 0,
        side = 0,
        vertical = 0,
        radius = 0,
    }
end
local function setOrbH(weapon)
    local settings = atkCfg()
    config.orbit.height = settings.height
end
local function orbBase(root)
    if not root then
        return Vector3.zero
    end
    local settings = atkCfg()
    local pos = root.Position
    local look = root.CFrame.LookVector
    local right = root.CFrame.RightVector
    return pos
        + (look * settings.front)
        + (right * settings.side)
        + Vector3.new(0, settings.vertical, 0)
end
local function setOrbR()
    local settings = atkCfg()
    config.orbit.radius = settings.radius or 0
end
local function refreshAtk()
    setOrbH(getweapon())
    setOrbR()
end
local function stopsync()
    if not config.state.csyncactive then return end
    if config.orbit.connection then
        config.orbit.connection:Disconnect()
        config.orbit.connection = nil
    end
    config.state.csyncactive = false
    config.orbit.active = false
    clrVoidSnap()
    config.voidspam.phase = nil
    if config.orbit.savedpos and localfighter and localfighter.Entity and localfighter.Entity.RootPart and not getgenv().InstanceUndergroundEnabled then
        local ok, pos = pcall(function() return config.orbit.savedpos end)
        if ok and pos then
            local currentPos = localfighter.Entity.RootPart.CFrame
            local distance = (currentPos.Position - pos.Position).Magnitude
            pcall(function()
                localfighter.Entity.RootPart.CFrame = pos
            end)
        end
    end
    config.orbit.serverpos = nil
    config.orbit.savedpos = nil
    config.voidspam.phase = nil
    oldpos = nil
end
local function isHidingPhase()
    return config.voidspam.enabled and config.voidspam.phase == "hide"
end
local function tickVoidSpam()
    if not config.voidspam.enabled then return end
    local now = tick()
    local elapsed = now - config.voidspam.lastswitch
    if config.voidspam.phase == "shoot" then
        if elapsed >= config.voidspam.currentduration then
            config.voidspam.phase = "hide"
            config.voidspam.currentduration = randVs(config.voidspam.hide_min, config.voidspam.hide_max)
            config.voidspam.lastswitch = now
        end
    elseif config.voidspam.phase == "hide" then
        if elapsed >= config.voidspam.currentduration then
            config.voidspam.phase = "shoot"
            config.voidspam.currentduration = randVs(config.voidspam.shoot_min, config.voidspam.shoot_max)
            config.voidspam.lastswitch = now
        end
    else
        config.voidspam.phase = "shoot"
        config.voidspam.currentduration = randVs(config.voidspam.shoot_min, config.voidspam.shoot_max)
        config.voidspam.lastswitch = now
    end
end
local function voidOk(sling)
    if not sling then return false end
    return config.voidspam.enabled or config.state.outofammo
end
local function tickVoid(sling, root)
    if sling then
        clrVoidSnap()
        return false
    end
    if not voidOk(sling) then
        clrVoidSnap()
        return false
    end
    local isHiding = config.state.outofammo or (config.voidspam.enabled and config.voidspam.phase == "hide")
    if isHiding then
        if config.voidspam.enabled and config.voidspam.phase == "hide" and not config.state.outofammo then
            local elapsed = tick() - config.voidspam.lastswitch
            if elapsed >= config.voidspam.currentduration then
                config.voidspam.phase = "shoot"
                config.voidspam.currentduration = randVs(config.voidspam.shoot_min, config.voidspam.shoot_max)
                config.voidspam.lastswitch = tick()
                clrVoidSnap()
                return false
            end
        end
        clrVoidSnap()
        local hrp = voidHrp()
        if hrp then
            snapVoid(hrp)
        else
            if config.state.csyncactive then
                return true
            end
            local randomX = math.random(-10000, 10000)
            local randomZ = math.random(-10000, 10000)
            config.orbit.serverpos = Vector3.new(randomX, -99999999999, randomZ)
        end
        return true
    end
    if config.voidspam.enabled and config.voidspam.phase == "shoot" then
        local elapsed = tick() - config.voidspam.lastswitch
        if elapsed >= config.voidspam.currentduration then
            config.voidspam.phase = "hide"
            config.voidspam.currentduration = randVs(config.voidspam.hide_min, config.voidspam.hide_max)
            config.voidspam.lastswitch = tick()
        end
    end
    clrVoidSnap()
    return false
end
local function hideShot()
    if not config.voidspam.enabled then return end
    if isSling(getweapon()) then return end
end
local function voidhide()
    if vhState.active then return end
    vhState.active = true
    if not config.state.csyncactive then
        startsync()
    end
end
local stopvoid = function()
    vhState.active = false
    vhState.currentVoidPos = nil
    if vhState.mainConnection then
        vhState.mainConnection:Disconnect()
        vhState.mainConnection = nil
    end
end
local function startsync()
    if config.state.csyncactive then return end
    if config.target.immune then return end
    if not config.target.character or not valid(config.target.character) then return end
    eqSlot()
    config.state.csyncactive = true
    config.orbit.active = true
    local weapon = getweapon()
    setOrbH(weapon)
    setOrbR()
    if not config.orbit.savedpos then
        if localfighter and localfighter.Entity and localfighter.Entity.RootPart then
            config.orbit.savedpos = localfighter.Entity.RootPart.CFrame
        end
    end
    config.orbit.connection = runsvc.Heartbeat:Connect(function(dt)
        if not config.state.csyncactive then return end
        if config.target.immune then stopsync() return end
        if not config.target.character or not valid(config.target.character) then stopsync() return end
        if not localfighter or not localfighter.Entity or not localfighter.Entity.RootPart then stopsync() return end
        if config.target.immune then stopsync() return end
        setOrbR()
        oldpos = localfighter.Entity.RootPart.CFrame
        local function isQuickSwapActive()
            if pickMelee() then return false end
            local lf = modules.fighter and modules.fighter.LocalFighter
            if not lf or not lf.EquippedItem then return false end
            local name = tostring(lf.EquippedItem:Get("Name") or ""):lower()
            return name:find("fist", 1, true) or name:find("utility", 1, true)
        end
        local _weapon = getweapon()
        local checksling = isSling(_weapon)
        if isQuickSwapActive() then return end
        eqSlot()
        if reloadHide(checksling) then return end
        if not checksling and config.voidspam.enabled and not config.target.immune then
            tickVoidSpam()
            if config.voidspam.phase == "hide" then
                local randomX = math.random(-10000, 10000)
                local randomZ = math.random(-10000, 10000)
                config.orbit.serverpos = Vector3.new(randomX, -99999999999, randomZ)
                pcall(function()
                    localfighter.Entity.RootPart.CFrame = CFrame.new(config.orbit.serverpos)
                end)
                return
            end
        end
        if not config.target.character then stopsync() return end
        local root = config.target.character:FindFirstChild("HumanoidRootPart")
        if not root then stopsync() return end
        if not checksling and isHidingPhase() then
            local randomX = math.random(-10000, 10000)
            local randomZ = math.random(-10000, 10000)
            config.orbit.serverpos = Vector3.new(randomX, -99999999999, randomZ)
            pcall(function()
                localfighter.Entity.RootPart.CFrame = CFrame.new(config.orbit.serverpos)
            end)
            return
        end
        if checksling then
            if vhState and vhState.active then
                local trg = config.target.character:FindFirstChild("HumanoidRootPart")
                if trg then
                    local flat = Vector3.new(trg.CFrame.LookVector.X, 0, trg.CFrame.LookVector.Z).Unit
                    config.orbit.serverpos = trg.Position + Vector3.new(0, 15, 0) + (flat * 5)
                end
            end
        end
        if config.state.outofammo and not checksling and _weapon and not isInfiniteWeapon() then
            local hrp = voidHrp()
            if hrp then
                snapVoid(hrp)
            else
                local randomX = math.random(-10000, 10000)
                local randomZ = math.random(-10000, 10000)
                config.orbit.serverpos = Vector3.new(randomX, -99999999999, randomZ)
                pcall(function()
                    localfighter.Entity.RootPart.CFrame = CFrame.new(config.orbit.serverpos)
                end)
            end
            return
        end
        local targetpos = orbBase(root)
        config.orbit.angle = config.orbit.angle + (config.orbit.speed * dt)
        local offset = Vector3.new(
            math.cos(config.orbit.angle) * config.orbit.radius,
            config.orbit.height,
            math.sin(config.orbit.angle) * config.orbit.radius
        )
        config.orbit.serverpos = targetpos + offset
        if not getgenv().InstanceUndergroundEnabled then
            if localfighter and localfighter.Entity and localfighter.Entity.RootPart then
                local currentPos = localfighter.Entity.RootPart.CFrame
                local newPos = CFrame.new(config.orbit.serverpos)
                local distance = (newPos.Position - currentPos.Position).Magnitude
                if distance < 2000 then
                    localfighter.Entity.RootPart.CFrame = newPos
                    config.orbit.savedpos = currentPos
                end
            end
        end
    end)
end
local function autoshoot()
    if not isSling(getweapon()) and config.voidspam.enabled and config.voidspam.phase == "hide" then return end
    if not config.target.enabled or not config.target.character or not config.target.autoshoot then return end
    if config.target.immune then return end
    if not isSling(getweapon()) and config.voidspam.enabled and config.voidspam.phase == "hide" then return end
    if config.voidspam.enabled and config.voidspam.phase == "hide" then return end
    local weapon = getweapon()
    local checksling = isSling(weapon)
    eqSlot()
    local lf = modules.fighter and modules.fighter.LocalFighter
    if not lf or not lf.EquippedItem then return end
    if not isInfiniteWeapon() then
        if config.state.reloading or config.state.outofammo then return end
        if not canuse() then return end
    end
    local targetChar = config.target.character
    if not valid(targetChar) then return end
    local hitPart = hitpartfromname(targetChar, config.target.hitpart)
    if not hitPart then return end
    local shootPos
    local targetPos
    if vhState and vhState.active and checksling then
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		shootPos = root and root.Position or Vector3.new()
		targetPos = predict(hitPart, shootPos)
	else
        if vhState and vhState.active then
			local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			shootPos = myRoot and myRoot.Position or Vector3.new()
        elseif config.state.csyncactive and config.orbit.serverpos then
            shootPos = config.orbit.serverpos
        else
            local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            shootPos = root and root.Position or Vector3.new()
        end
        targetPos = predict(hitPart, shootPos)
    end
    local data = {
        [utf8.char(1)] = {
            [utf8.char(0)] = modules.utility:EncodeCFrame(CFrame.new(shootPos, targetPos)),
            [utf8.char(1)] = modules.utility:EncodeCFrame(CFrame.new(shootPos, targetPos)),
            [utf8.char(2)] = hitPart,
            [utf8.char(3)] = modules.utility:EncodeCFrame(CFrame.new(0.43, 0.25, 0.42)),
        },
    }
    local equipped = lf.EquippedItem
    if equipped and equipped:Get("ObjectID") then
        ragePerf.lastAttackTick = tick()
        local attempts = math.clamp(math.floor(tonumber(config.target.shootAttempts) or 1), 1, 3)
        for _ = 1, attempts do
            pcall(function()
                replicatedstorage.Remotes.Replication.Fighter.UseItem:FireServer(
                    equipped:Get("ObjectID"),
                    modules.enums:ToEnum("StartShooting"),
                    data,
                    nil
                )
            end)
        end
        hideShot()
    end
end
local oldcamupdate = modules.camcontrol.Update
modules.camcontrol.Update = function(...)
    if getgenv().InstanceUndergroundEnabled then
        return oldcamupdate(...)
    elseif config.state.csyncactive and localfighter and localfighter.Entity and localfighter.Entity.RootPart and oldpos then
        localfighter.Entity.RootPart.CFrame = oldpos
    end
    return oldcamupdate(...)
end
local immuneList = {}
local onImmune = {}
local onVulnerable = {}
local function bindimmune(callback)
    table.insert(onImmune, callback)
end
local function bindvulnerable(callback)
    table.insert(onVulnerable, callback)
end
runsvc.Heartbeat:Connect(function()
    for _, plr in pairs(players:GetPlayers()) do
        if plr == player then continue end
        local char = plr.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local immune = root and root:FindFirstChild("Attachment") ~= nil
        if immune and not immuneList[plr.Name] then
            immuneList[plr.Name] = true
            for _, cb in pairs(onImmune) do cb(plr) end
        elseif not immune and immuneList[plr.Name] then
            immuneList[plr.Name] = nil
            for _, cb in pairs(onVulnerable) do cb(plr) end
        end
    end
end)
bindimmune(function(plr)
    if config.target.lastplayer == plr then
        config.target.immune = true
        config.voidspam.phase = nil
        clrVoidSnap()
        indicator.Color = Color3.fromRGB(180, 0, 255)
        stopsync()
    end
end)
bindvulnerable(function(plr)
    if config.target.lastplayer == plr then
        config.target.immune = false
        indicator.Color = Color3.fromRGB(255, 50, 50)
        if config.target.enabled and config.target.character and valid(config.target.character) then
            startsync()
        end
    end
end)
local function cleartarget()
    config.target.enabled = false
    stopsync()
    config.target.character = nil
    config.target.lastchar = nil
    config.target.lastplayer = nil
    config.target.manualkey = false
    config.target.immune = false
    indicator.Color = Color3.fromRGB(255, 50, 50)
end
local function settarget(char)
    if not char then return end
    local targetplr = players:GetPlayerFromCharacter(char)
    config.target.enabled = true
    config.target.character = char
    config.target.lastchar = char
    config.target.lastplayer = targetplr
    config.target.immune = false
    indicator.Color = Color3.fromRGB(255, 50, 50)
    local root = char:FindFirstChild("HumanoidRootPart")
    if root and root:FindFirstChild("Attachment") then
        config.target.immune = true
        indicator.Color = Color3.fromRGB(180, 0, 255)
    else
        eqSlot()
        startsync()
    end
end
local sling = {
    enabled = false,
    connections = {}
}
local function checksling()
    return isSling(getweapon())
end
local function nearplr()
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    local found, best = nil, math.huge
    for _, p in ipairs(players:GetPlayers()) do
        if p == player or not p.Character then continue end
        local head = p.Character:FindFirstChild("HitboxHead") or p.Character:FindFirstChild("Head")
        if not head then continue end
        local d = (head.Position - root.Position).Magnitude
        if d < best then
            found = head
            best = d
        end
    end
    return found
end
local function slingshotTP()
    if sling.connections.touch then return end
    sling.connections.touch = workspace.DescendantAdded:Connect(function(d)
        if d:IsA("BasePart") or d:IsA("Model") then
            if d.Name == "Slingshot" or d.Name == "CoreProjectile" or d.Name == "OuterProjectile" then
                task.spawn(function()
					task.wait(0.06)
					local part = d:IsA("BasePart") and d or d:FindFirstChildWhichIsA("BasePart")
					if not part then return end
					part.CanTouch = true
					for i = 1, 60 do
						if not part.Parent or not part:IsDescendantOf(workspace) then break end
						local target = nearplr()
						if target and target:IsA("BasePart")
							and target.Parent
							and target:IsDescendantOf(workspace)
						then
							pcall(firetouchinterest, target, part, 0)
							pcall(firetouchinterest, target, part, 1)
						end
						task.wait()
					end
				end)
            end
        end
    end)
end
local function stopslingTP()
    if sling.connections.touch then
        sling.connections.touch:Disconnect()
        sling.connections.touch = nil
    end
end
local function targetpos()
    if not config.target.character then return nil end
    local root = config.target.character:FindFirstChild("HumanoidRootPart")
    return root and root.Position
end
local function updatesling()
    local slingon = checksling()
    local hastarget = config.target.enabled and config.target.character ~= nil
    if slingon then
        if not sling.enabled then
            sling.enabled = true
            slingshotTP()
        end
        if getgenv().InstanceSetUnderground then
            getgenv().InstanceSetUnderground(true)
        end
        vhState.active = hastarget
        if hastarget and not config.state.csyncactive then
            startsync()
        elseif not hastarget and config.state.csyncactive and not config.target.enabled then
            stopsync()
        end
    else
        if sling.enabled then
            sling.enabled = false
            stopslingTP()
        end
        if not Toggles.AntiAimUnderground.Value then
            if getgenv().InstanceSetUnderground then
                getgenv().InstanceSetUnderground(false)
            end
        end
        vhState.active = false
    end
end
local function fflag()
    local hastarget = config.target.enabled and config.target.character and valid(config.target.character)
    local slingon = checksling()
    if hastarget and slingon then
        pcall(function()
            setfflag("TargetTimeDelayFacctorTenths", "999999")
        end)
    else
        pcall(function()
            setfflag("TargetTimeDelayFacctorTenths", "1")
        end)
    end
end
local targetHudAnimLast = tick()
runsvc.RenderStepped:Connect(function()
    local inLobby = getgenv().InstanceIsInLobby and getgenv().InstanceIsInLobby()
    local hudNeeded = config.visualizer.enabled
        or (config.ragestatus and config.ragestatus.enabled)
        or (config.hitNotifications and config.hitNotifications.enabled)
        or (config.target.enabled and config.target.character and config.prediction.enabled)
    if inLobby and not hudNeeded then
        return
    end
    if shouldSuppressGameplayOverlays() then
        tracerline.Visible = false
        traceroutline.Visible = false
        if ragebot.hideRageStatus then
            ragebot.hideRageStatus()
        end
        if ragebot.updateHitNotifications then
            ragebot.updateHitNotifications(0)
        end
        return
    end
    local now = tick()
    local hudDt = math.clamp(now - targetHudAnimLast, 0, 0.05)
    targetHudAnimLast = now
    if config.ragestatus and config.ragestatus.enabled and ragebot.drawStatus then
        ragebot.drawStatus()
    elseif ragebot.hideRageStatus then
        ragebot.hideRageStatus()
    end
    if ragebot.updateHitNotifications then
        ragebot.updateHitNotifications(hudDt)
    end
    if config.target.enabled and config.target.character and config.prediction.enabled then
        updatevel()
    end
end)
runsvc.Heartbeat:Connect(function()
    fflag()
    updatesling()
    tickAmmo()
    if config.target.auto and not config.target.manualkey then
        local current, _, melee = getammo()
        local hasammo = current == nil or current > 0 or melee
        if hasammo and not config.state.reloading then
            if not config.target.enabled or not config.target.character or not valid(config.target.character) then
                local newtarget = nearest()
                if newtarget then
                    if config.target.enabled then stopsync() end
                    settarget(newtarget)
                end
            end
        end
    end
    if config.target.enabled and config.target.character then
        if not valid(config.target.character) then
            cleartarget()
            return
        end
        eqSlot()
        if config.target.autoshoot and not config.target.immune then
            autoshoot()
        end
    end
end)
ragebot.config = config
ragebot.nearest = nearest
ragebot.settarget = settarget
ragebot.cleartarget = cleartarget
ragebot.stopvoid = stopvoid
ragebot.vhState = vhState
ragebot.ragePerf = ragePerf
ragebot.getammo = getammo
ragebot.muzzlepos = muzzlepos
ragebot.valid = valid
ragebot.player = player
ragebot.eqSlot = eqSlot
ragebot.refreshAtk = refreshAtk
do
local config = ragebot.config
local ragePerf = ragebot.ragePerf
local getammo = ragebot.getammo
local muzzlepos = ragebot.muzzlepos
local valid = ragebot.valid
local player = ragebot.player
local vhState = ragebot.vhState
local camera = workspace.CurrentCamera
local function mkStatusLbl()
    local label = getgenv().InstanceTrackDrawingText(Drawing.new("Text"))
    label.Size = 13
    label.Font = 2
    label.Outline = true
    label.Center = true
    label.Visible = false
    label.Color = config.ragestatus.color
    pcall(function()
        label.OutlineColor = Color3.fromRGB(0, 0, 0)
    end)
    return label
end
local rageStatusLine1 = mkStatusLbl()
local rageStatusLine2 = mkStatusLbl()
local function styleStatusLbl(label)
    label.Size = 13
    label.Font = 2
    label.Outline = true
    label.Color = config.ragestatus.color
    pcall(function()
        label.OutlineColor = Color3.fromRGB(0, 0, 0)
    end)
end
local function statusAnchor()
    if config.ragestatus.mode == "muzzle" then
        local mp = muzzlepos and muzzlepos()
        if mp then
            local wts = getgenv().InstanceWorldToScreen or worldToScreen
            local screenPos, onScreen = wts(mp, camera)
            if onScreen and screenPos then
                return Vector2.new(screenPos.X, screenPos.Y)
            end
        end
    end
    local cam = camera or workspace.CurrentCamera
    if not cam then
        return Vector2.zero
    end
    return (cam.ViewportSize / 2) + Vector2.new(
        config.ragestatus.staticOffsetX or 0,
        config.ragestatus.staticOffsetY or 0
    )
end
local function rageActive()
    return config.target.enabled or config.target.auto or config.voidspam.enabled
end
local function killNm()
    if config.target.lastplayer then
        return config.target.lastplayer.Name
    end
    if config.target.character then
        local tp = game:GetService("Players"):GetPlayerFromCharacter(config.target.character)
        if tp then
            return tp.Name
        end
    end
    return "target"
end
local function inVoid()
    if vhState.active then return true end
    if config.voidspam.enabled and config.voidspam.phase == "hide" and isSling(getweapon()) then
        return true
    end
    if config.state.reloading and config.ragestatus.hideOnReload ~= false then
        return true
    end
    return false
end
local function isKilling()
    if not rageActive() then
        return false
    end
    if config.state.reloading or inVoid() then
        return false
    end
    if config.target.immune then
        return false
    end
    if not config.target.enabled or not config.target.character or not valid(config.target.character) then
        return false
    end
    if config.state.csyncactive then
        return true
    end
    if config.voidspam.enabled and config.voidspam.phase == "shoot" and isSling(getweapon()) then
        return true
    end
    if tick() - (ragePerf.lastAttackTick or 0) < 0.45 then
        return true
    end
    return false
end
local function hudAmmo()
    if isInfiniteWeapon() then return "∞" end
    local cur, maxAmmo, melee = getammo()
    if cur == nil then return "∞" end
    if melee then return "melee" end
    return string.format("%d/%d", math.floor(cur or 0), math.max(math.floor(maxAmmo or 0), 0))
end
local function fmtVsTime(minT, maxT)
    local a = clampVs(minT)
    local b = clampVs(maxT)
    if b < a then
        a, b = b, a
    end
    if math.abs(a - b) < 0.05 then
        return string.format("%.1fs", a)
    end
    return string.format("%.1f-%.1fs", a, b)
end
local function vsDetail()
    if not config.voidspam.enabled then
        return ""
    end
    local vs = config.voidspam
    return string.format(
        "void %s atk · %s hide",
        fmtVsTime(vs.shoot_min, vs.shoot_max),
        fmtVsTime(vs.hide_min, vs.hide_max)
    )
end
local function rageLines()
    local now = tick()
    if isKilling() then
        if not ragePerf.killStartAt then
            ragePerf.killStartAt = now
        end
    else
        ragePerf.killStartAt = nil
    end
    if config.state.reloading then
        return "ragebot: void hide", "reloading"
    end
    if inVoid() then
        local det = vsDetail()
        return "ragebot: void hide", det ~= "" and det or ""
    end
    if isKilling() then
        local name = killNm()
        local elapsed = now - (ragePerf.killStartAt or now)
        local hum = config.target.character and config.target.character:FindFirstChildOfClass("Humanoid")
        local main = string.format("ragebot : attacking (%s) · %.1fs", name, elapsed)
        local detailParts = {}
        local hpBit = hum and string.format("%.0f hp", hum.Health) or "hp ?"
        detailParts[#detailParts + 1] = hpBit
        local voidDetail = vsDetail()
        if voidDetail ~= "" then
            detailParts[#detailParts + 1] = voidDetail
        end
        return main, table.concat(detailParts, " · ")
    end
    if rageActive() and config.target.enabled and config.target.character then
        local hum = config.target.character:FindFirstChildOfClass("Humanoid")
        local hpBit = hum and string.format("%.0f hp", hum.Health) or "locked"
        return "ragebot: ready", hpBit
    end
    return "ragebot: idle", ""
end
local function drawStatus()
    if not config.ragestatus.enabled or shouldSuppressGameplayOverlays() then
        rageStatusLine1.Visible = false
        rageStatusLine2.Visible = false
        return
    end
    local anchor = statusAnchor()
    local gap = config.ragestatus.lineGap or 14
    local showAmmo = config.ragestatus.showAmmo ~= false
    if ragePerf.lastRageColor ~= config.ragestatus.color then
        ragePerf.lastRageColor = config.ragestatus.color
        styleStatusLbl(rageStatusLine1)
        styleStatusLbl(rageStatusLine2)
    end
    local mainLine, detailLine = rageLines()
    local ammoLine = showAmmo and hudAmmo() or ""
    local line2Text = detailLine
    if line2Text ~= "" and ammoLine ~= "" then
        line2Text = line2Text .. " · " .. ammoLine
    elseif line2Text == "" then
        line2Text = ammoLine
    end
    local lineCount = 1 + (line2Text ~= "" and 1 or 0)
    local topOffset = -(lineCount - 1) * (gap / 2)
    if mainLine ~= ragePerf.lastRageStatusText then
        ragePerf.lastRageStatusText = mainLine
        rageStatusLine1.Text = mainLine
    end
    rageStatusLine1.Position = anchor + Vector2.new(0, topOffset)
    rageStatusLine1.Visible = config.ragestatus.enabled
    local nextY = topOffset + gap
    if line2Text ~= "" then
        if line2Text ~= ragePerf.lastRageDetailText then
            ragePerf.lastRageDetailText = line2Text
            rageStatusLine2.Text = line2Text
        end
        rageStatusLine2.Position = anchor + Vector2.new(0, nextY)
        rageStatusLine2.Visible = config.ragestatus.enabled
    else
        ragePerf.lastRageDetailText = ""
        rageStatusLine2.Visible = false
    end
end
ragebot.drawStatus = drawStatus
ragebot.hideRageStatus = function()
    rageStatusLine1.Visible = false
    rageStatusLine2.Visible = false
end
ragebot.clrVoidSnap = clrVoidSnap
end
do
local config = ragebot.config
local nearest = ragebot.nearest
local settarget = ragebot.settarget
local cleartarget = ragebot.cleartarget
local stopvoid = ragebot.stopvoid
local function togglekey()
    if config.target.auto then return end
    if config.target.enabled and config.target.character then
        cleartarget()
    else
        local target = nearest()
        if target then
            config.target.manualkey = true
            settarget(target)
        end
    end
end
local rageui = {
    targetgroup = Tabs.Combat:AddRightTabbox()
}
rageui.ragebottab = rageui.targetgroup:AddTab('Ragebot')
rageui.ragebotvisualtab = rageui.targetgroup:AddTab('Visualizer')
rageui.ragebottab:AddToggle("TargetOn", {
    Text = "Enable",
    Default = false,
    Callback = function(val)
        config.target.rageMasterOn = val
        if config.target.auto then return end
        if val then
            local target = nearest()
            if target then
                config.target.manualkey = true
                settarget(target)
            end
        else
            cleartarget()
        end
    end
}):AddKeyPicker("TargetKey", {
    Text = "Ragebot",
    Default = "None",
    Mode = "Toggle",
    Callback = function() togglekey() end
})
rageui.ragebottab:AddToggle("AutoTarget", {
    Text = "Auto Target",
    Default = false,
    Callback = function(val) config.target.auto = val end
})
local attackUnderVisGate = { Type = "Toggle", Value = false }
local attackCustomVisGate = { Type = "Toggle", Value = false }
local function syncAtkDeps()
    local mode = config.target.attackPosition or "default"
    local custom = config.target.attackCustomEnabled == true
    attackUnderVisGate.Value = (mode == "under" and not custom)
    attackCustomVisGate.Value = custom
    if attackUnderDep and attackUnderDep.Update then
        attackUnderDep:Update()
    end
    if attackCustomDep and attackCustomDep.Update then
        attackCustomDep:Update()
    end
end
local attackPosDropdown = rageui.ragebottab:AddDropdown("AutoTargetAttackPos", {
    Text = "attack position",
    Default = "default",
    Values = { "default", "under" },
    Callback = function(val)
        config.target.attackPosition = val
        syncAtkDeps()
        if config.state.csyncactive and ragebot.refreshAtk then
            ragebot.refreshAtk()
        end
    end,
})
rageui.ragebottab:AddToggle("AttackCustomOverride", {
    Text = "attack position",
    Default = false,
    Tooltip = "overrides attack position dropdown when enabled",
    Callback = function(val)
        config.target.attackCustomEnabled = val
        syncAtkDeps()
        if config.state.csyncactive and ragebot.refreshAtk then
            ragebot.refreshAtk()
        end
    end,
})
local attackUnderDep = rageui.ragebottab:AddDependencyBox()
attackUnderDep:AddSlider("UnderAttackOffset", {
    Text = "Under Offset",
    Default = config.target.underOffset,
    Min = 1,
    Max = 25,
    Rounding = 1,
    Compact = true,
    Callback = function(val)
        config.target.underOffset = val
        if config.target.attackPosition == "under"
            and not config.target.attackCustomEnabled
            and config.state.csyncactive
            and ragebot.refreshAtk then
            ragebot.refreshAtk()
        end
    end,
})
attackUnderDep:SetupDependencies({
    { attackUnderVisGate, true },
})
local attackCustomDep = rageui.ragebottab:AddDependencyBox()
local function onAtkCustom()
    if config.target.attackCustomEnabled and config.state.csyncactive and ragebot.refreshAtk then
        ragebot.refreshAtk()
    end
end
attackCustomDep:AddSlider("CustomAttackHeight", {
    Text = "Orbit Height",
    Default = config.target.customHeight,
    Min = -25,
    Max = 30,
    Rounding = 1,
    Compact = true,
    Callback = function(val)
        config.target.customHeight = val
        onAtkCustom()
    end,
})
attackCustomDep:AddSlider("CustomAttackFront", {
    Text = "Front Offset",
    Default = config.target.customFront,
    Min = -20,
    Max = 20,
    Rounding = 1,
    Compact = true,
    Callback = function(val)
        config.target.customFront = val
        onAtkCustom()
    end,
})
attackCustomDep:AddSlider("CustomAttackSide", {
    Text = "Side Offset",
    Default = config.target.customSide,
    Min = -20,
    Max = 20,
    Rounding = 1,
    Compact = true,
    Callback = function(val)
        config.target.customSide = val
        onAtkCustom()
    end,
})
attackCustomDep:AddSlider("CustomAttackVertical", {
    Text = "Vertical Offset",
    Default = config.target.customVertical,
    Min = -25,
    Max = 30,
    Rounding = 1,
    Compact = true,
    Callback = function(val)
        config.target.customVertical = val
        onAtkCustom()
    end,
})
attackCustomDep:AddSlider("CustomAttackRadius", {
    Text = "Orbit Radius",
    Default = config.target.customRadius,
    Min = 0,
    Max = 25,
    Rounding = 1,
    Compact = true,
    Callback = function(val)
        config.target.customRadius = val
        onAtkCustom()
    end,
})
attackCustomDep:SetupDependencies({
    { attackCustomVisGate, true },
})
syncAtkDeps()
task.defer(syncAtkDeps)
rageui.ragebottab:AddDropdown("RageWeaponPick", {
    Text = "Weapon",
    Default = config.target.weaponPick or "primary",
    Values = { "primary", "secondary", "melee" },
    Callback = function(val)
        config.target.weaponPick = val
        if config.state.csyncactive and ragebot.refreshAtk then
            ragebot.refreshAtk()
        end
        if ragebot.eqSlot then
            ragebot.eqSlot()
        end
    end,
})
rageui.ragebottab:AddSlider("ShootAttempts", {
    Text = "Shoot Attempts",
    Default = 1,
    Min = 1,
    Max = 3,
    Rounding = 0,
    Suffix = "x",
    Callback = function(val)
        config.target.shootAttempts = math.clamp(math.floor(tonumber(val) or 1), 1, 3)
    end,
})
rageui.ragebottab:AddDropdown("TargetPart", {
    Text = "Hit Part",
    Default = "Head",
    Values = {"Head", "HumanoidRootPart", "Torso", "UpperTorso", "Closest", "Random"},
    Callback = function(val) config.target.hitpart = val end
})
rageui.ragebottab:AddToggle("PredictT", {
    Text = "Prediction",
    Default = false,
    Callback = function(val) config.prediction.enabled = val end
})
rageui.ragebottab:AddSlider("PredictMul", {
    Text = "Prediction Mult",
    Default = 1.2,
    Min = 0.1,
    Max = 3.0,
    Rounding = 1,
    Callback = function(val) config.prediction.multiplier = val end
})
rageui.ragebottab:AddToggle("VoidSpam", {
    Text = "Voidspam",
    Default = false,
    Callback = function(val)
        config.voidspam.enabled = val
        if val then
            if config.target.immune then
                config.voidspam.phase = nil
                return
            end
            if isSling(getweapon()) then
                config.voidspam.lastswitch = tick()
                config.voidspam.phase = "shoot"
                config.voidspam.currentduration = randVs(config.voidspam.shoot_min, config.voidspam.shoot_max)
            else
                config.voidspam.phase = nil
            end
        else
            config.voidspam.phase = nil
            if ragebot.clrVoidSnap then
                ragebot.clrVoidSnap()
            end
        end
    end
})
rageui.ragebottab:AddSlider('VoidShootTime', {
    Default = 1,
    Text = "Attack",
    Min = 0.1,
    Max = 2,
    Rounding = 1,
    Compact = true,
    Callback = function(val)
        val = clampVs(val)
        config.voidspam.shoot_min = val
        config.voidspam.shoot_max = val
    end
})
rageui.ragebottab:AddSlider('VoidHideTime', {
    Default = 1,
    Text = "Hide",
    Min = 0.1,
    Max = 2,
    Rounding = 1,
    Compact = true,
    Callback = function(val)
        val = clampVs(val)
        config.voidspam.hide_min = val
        config.voidspam.hide_max = val
    end
})
local rageStatusToggle = rageui.ragebotvisualtab:AddToggle("RageStatus", {
    Text = "Rage Status",
    Default = config.ragestatus.enabled,
    Callback = function(val)
        config.ragestatus.enabled = val
        if val then
            if ragebot.drawStatus then
                ragebot.drawStatus()
            end
        else
            if ragebot.hideRageStatus then
                ragebot.hideRageStatus()
            end
        end
    end,
}):AddColorPicker("RageStatusColor", {
    Title = "text color",
    Default = config.ragestatus.color,
    Callback = function(val)
        config.ragestatus.color = val
        if ragebot.ragePerf then
            ragebot.ragePerf.lastRageColor = nil
        end
    end,
})
local rageStatusDep = rageui.ragebotvisualtab:AddDependencyBox()
rageStatusDep:SetupDependencies({
    { rageStatusToggle, true },
})
rageStatusDep:AddDropdown("RageStatusMode", {
    Text = "Position",
    Default = "static",
    Values = { "static", "muzzle" },
    Callback = function(val)
        config.ragestatus.mode = val
    end,
})
rageStatusDep:AddSlider("RageStatusStaticX", {
    Text = "Static X",
    Default = config.ragestatus.staticOffsetX,
    Min = -500,
    Max = 500,
    Rounding = 0,
    Compact = true,
    Callback = function(val)
        config.ragestatus.staticOffsetX = val
    end,
})
rageStatusDep:AddSlider("RageStatusStaticY", {
    Text = "Static Y",
    Default = config.ragestatus.staticOffsetY,
    Min = -500,
    Max = 500,
    Rounding = 0,
    Compact = true,
    Callback = function(val)
        config.ragestatus.staticOffsetY = val
    end,
})
rageStatusDep:AddToggle("RageStatusAmmo", {
    Text = "Show Ammo Line",
    Default = true,
    Callback = function(val)
        config.ragestatus.showAmmo = val
    end,
})
rageStatusDep:AddToggle("RageStatusReloadHide", {
    Text = "Hide While Reloading",
    Default = true,
    Callback = function(val)
        config.ragestatus.hideOnReload = val
    end,
})
rageui.ragebotvisualtab:AddToggle("VisEnabled", {
    Text = "Enable",
    Default = false,
    Callback = function(val) config.visualizer.enabled = val end
})
rageui.ragebotvisualtab:AddToggle("VisTracerEnabled", {
    Text = "Tracer",
    Default = false,
    Callback = function(val) config.visualizer.tracer.enabled = val end
}):AddColorPicker("VisTracerColor", {
    Default = config.visualizer.tracer.color,
    Callback = function(val) config.visualizer.tracer.color = val end
})
rageui.ragebotvisualtab:AddDropdown("VisTracerStart", {
    Text = "Tracer Start",
    Default = "cursor",
    Values = {"cursor", "muzzle"},
    Callback = function(val) config.visualizer.tracer.start_point = val end
})
rageui.ragebotvisualtab:AddToggle("VisTracerOutline", {
    Text = "Tracer Outline",
    Default = true,
    Callback = function(val) config.visualizer.tracer.outline = val end
})
rageui.ragebotvisualtab:AddSlider("VisTracerThickness", {
    Text = "Tracer Thickness",
    Default = 1,
    Min = 0.1,
    Max = 3,
    Rounding = 1,
    Callback = function(val) config.visualizer.tracer.thickness = val end
})
end
end
do
local config = ragebot.config
local ragePerf = ragebot.ragePerf
local isRageEnabled = ragebot.isRageEnabled
local players = cloneref(game:GetService("Players"))
local player = players.LocalPlayer
local TextService = game:GetService("TextService")
local UserInputService = cloneref(game:GetService("UserInputService"))
local hitNotifEntries = {}
local hitNotifHpTrack = {}
local hitNotifHumConn = {}
local hitNotifCharConn = {}
local hitNotifResolveQueues = {}
local hitNotifResolveBusy = {}
local HIT_NOTIF_ANIM_STYLES = {
    "fade",
    "slide left",
    "slide right",
    "slide down",
    "bounce",
    "fade bounce",
    "scale",
}
local HIT_NOTIF_STACK_WIDTH = 300
local hitNotifRoot = Library:Create("Frame", {
    Name = "HitNotifications",
    BackgroundTransparency = 1,
    Size = UDim2.new(0, HIT_NOTIF_STACK_WIDTH, 1, -24),
    Position = UDim2.fromOffset(12, 12),
    ZIndex = 250,
    Parent = Library.ScreenGui,
})
local function getHitNotifScreenPosition()
    local hn = config.hitNotifications
    local preset = hn.position or "Top Left"
    if preset == "Custom" then
        return Vector2.new(hn.offsetX or 12, hn.offsetY or 12)
    end
    local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
    local margin = 12
    local stackH = 280
    local centerX = vp.X * 0.5 - HIT_NOTIF_STACK_WIDTH * 0.5
    local presets = {
        ["Top Left"] = Vector2.new(margin, margin),
        ["Top Center"] = Vector2.new(centerX, margin),
        ["Top Right"] = Vector2.new(vp.X - HIT_NOTIF_STACK_WIDTH - margin, margin),
        ["Center Left"] = Vector2.new(margin, vp.Y * 0.5 - stackH * 0.5),
        ["Center"] = Vector2.new(centerX, vp.Y * 0.5 - stackH * 0.5),
        ["Center Right"] = Vector2.new(vp.X - HIT_NOTIF_STACK_WIDTH - margin, vp.Y * 0.5 - stackH * 0.5),
        ["Bottom Left"] = Vector2.new(margin, vp.Y - stackH - margin),
        ["Bottom Center"] = Vector2.new(centerX, vp.Y - stackH - margin),
        ["Bottom Right"] = Vector2.new(vp.X - HIT_NOTIF_STACK_WIDTH - margin, vp.Y - stackH - margin),
    }
    return presets[preset] or presets["Top Left"]
end
local function applyHitNotifRootPosition()
    local pos = getHitNotifScreenPosition()
    hitNotifRoot.Position = UDim2.fromOffset(math.floor(pos.X), math.floor(pos.Y))
end
local function hnEaseOutCubic(t)
    return 1 - (1 - t) ^ 3
end
local function hnEaseInCubic(t)
    return t * t * t
end
local function hnEaseOutBack(t)
    local c1 = 1.70158
    return 1 + (c1 + 1) * (t - 1) ^ 3 + c1 * (t - 1) ^ 2
end
local HIT_NOTIF_IN_SAMPLERS = {}
local HIT_NOTIF_OUT_SAMPLERS = {}
HIT_NOTIF_IN_SAMPLERS.fade = function(t)
    return hnEaseOutCubic(t), 0, 0, 1
end
HIT_NOTIF_IN_SAMPLERS["slide left"] = function(t)
    local e = hnEaseOutCubic(t)
    return e, (1 - e) * -52, 0, 1
end
HIT_NOTIF_IN_SAMPLERS["slide right"] = function(t)
    local e = hnEaseOutCubic(t)
    return e, (1 - e) * 52, 0, 1
end
HIT_NOTIF_IN_SAMPLERS["slide down"] = function(t)
    local e = hnEaseOutCubic(t)
    return e, 0, (1 - e) * -32, 1
end
HIT_NOTIF_IN_SAMPLERS.bounce = function(t)
    return math.clamp(t * 6, 0, 1), 0, 0, hnEaseOutBack(t)
end
HIT_NOTIF_IN_SAMPLERS["fade bounce"] = function(t)
    return hnEaseOutCubic(t), 0, 0, 0.78 + hnEaseOutBack(t) * 0.28
end
HIT_NOTIF_IN_SAMPLERS.scale = function(t)
    local e = hnEaseOutCubic(t)
    return e, 0, 0, 0.62 + e * 0.38
end
HIT_NOTIF_OUT_SAMPLERS.fade = function(t)
    local e = hnEaseInCubic(t)
    return 1 - e, 0, 0, 1
end
HIT_NOTIF_OUT_SAMPLERS["slide left"] = function(t)
    local e = hnEaseInCubic(t)
    return 1 - e, e * -52, 0, 1
end
HIT_NOTIF_OUT_SAMPLERS["slide right"] = function(t)
    local e = hnEaseInCubic(t)
    return 1 - e, e * 52, 0, 1
end
HIT_NOTIF_OUT_SAMPLERS["slide down"] = function(t)
    local e = hnEaseInCubic(t)
    return 1 - e, 0, e * 32, 1
end
HIT_NOTIF_OUT_SAMPLERS.bounce = function(t)
    local e = hnEaseInCubic(t)
    return 1 - e, 0, 0, 1 - e * 0.1 + math.sin(t * math.pi) * 0.09 * (1 - e)
end
HIT_NOTIF_OUT_SAMPLERS["fade bounce"] = function(t)
    local e = hnEaseInCubic(t)
    return 1 - e, 0, 0, 1 - e * 0.08 + math.sin(t * math.pi * 1.5) * 0.07 * (1 - t)
end
HIT_NOTIF_OUT_SAMPLERS.scale = function(t)
    local e = hnEaseInCubic(t)
    return 1 - e, 0, 0, 1 - e * 0.4
end
local function sampleHitNotifAnim(style, t, isOut)
    t = math.clamp(t, 0, 1)
    local map = isOut and HIT_NOTIF_OUT_SAMPLERS or HIT_NOTIF_IN_SAMPLERS
    local fn = map[string.lower(style or "fade")] or map.fade
    local a, ox, oy, sc = fn(t)
    return math.clamp(a, 0, 1), ox, oy, math.clamp(sc, 0.01, 1.35)
end
local function applyHitNotifVisual(entry, alpha, ox, oy, scale)
    local tr = 1 - math.clamp(alpha, 0, 1)
    entry.outer.BackgroundTransparency = tr
    entry.inner.BackgroundTransparency = tr
    entry.label.TextTransparency = tr
    if entry.uiScale then
        entry.uiScale.Scale = scale
    end
    local y = (entry.displayY or entry.targetY or 0) + oy
    entry.outer.Position = UDim2.fromOffset(math.floor(ox + 0.5), math.floor(y + 0.5))
end
local function measureHitNotifBox(text, textSize)
    local bounds = TextService:GetTextSize(text, textSize, Enum.Font.Code, Vector2.new(1000, 40))
    return math.clamp(bounds.X + 20, 200, 540), math.max(bounds.Y + 12, 26)
end
local function removeHitNotifEntry(index)
    local entry = hitNotifEntries[index]
    if entry and entry.outer then
        pcall(function()
            entry.outer:Destroy()
        end)
    end
    table.remove(hitNotifEntries, index)
end
local function formatHitNotifLine(targetName, dmg, bodyPart)
    return string.format(
        "hit %s for %d in the %s",
        targetName,
        math.floor(dmg + 0.5),
        bodyPart or "Body"
    )
end
local function createHitNotifBox(text)
    local hn = config.hitNotifications
    local textSize = hn.textSize or 14
    local boxW, boxH = measureHitNotifBox(text, textSize)
    local outer = Library:Create("Frame", {
        Name = "HitNotifOuter",
        BackgroundColor3 = Library.MainColor,
        BorderColor3 = Library.OutlineColor,
        BorderMode = Enum.BorderMode.Inset,
        Size = UDim2.fromOffset(boxW, boxH),
        Position = UDim2.fromOffset(0, 0),
        BackgroundTransparency = 1,
        ZIndex = 251,
        Parent = hitNotifRoot,
    })
    Library:AddToRegistry(outer, {
        BackgroundColor3 = "MainColor",
        BorderColor3 = "OutlineColor",
    }, true)
    local uiScale = Instance.new("UIScale")
    uiScale.Scale = 0.75
    uiScale.Parent = outer
    local inner = Library:Create("Frame", {
        Name = "HitNotifInner",
        BackgroundColor3 = Library.BackgroundColor,
        BorderColor3 = Library.OutlineColor,
        BorderMode = Enum.BorderMode.Inset,
        Position = UDim2.fromOffset(1, 1),
        Size = UDim2.new(1, -2, 1, -2),
        BackgroundTransparency = 1,
        ZIndex = 252,
        Parent = outer,
    })
    Library:AddToRegistry(inner, {
        BackgroundColor3 = "BackgroundColor",
        BorderColor3 = "OutlineColor",
    }, true)
    local label = Library:CreateLabel({
        Size = UDim2.new(1, -12, 1, 0),
        Position = UDim2.fromOffset(6, 0),
        Text = text,
        Font = Enum.Font.Code,
        TextSize = textSize,
        TextColor3 = hn.color or Library.FontColor,
        TextTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        ZIndex = 254,
        Parent = inner,
    }, false)
    return {
        outer = outer,
        inner = inner,
        label = label,
        uiScale = uiScale,
        boxW = boxW,
        boxH = boxH,
    }
end
local function pushHitNotification(targetName, dmg, bodyPart)
    if not config.hitNotifications.enabled or dmg <= 0 then
        return
    end
    local hn = config.hitNotifications
    local now = tick()
    applyHitNotifRootPosition()
    hitNotifRoot.Visible = true
    local parts = createHitNotifBox(formatHitNotifLine(targetName, dmg, bodyPart))
    table.insert(hitNotifEntries, 1, {
        outer = parts.outer,
        inner = parts.inner,
        label = parts.label,
        uiScale = parts.uiScale,
        boxW = parts.boxW,
        boxH = parts.boxH,
        start = now,
        phaseStart = now,
        phase = "in",
        duration = hn.duration or 3,
        targetY = 0,
        displayY = 0,
    })
    while #hitNotifEntries > math.clamp(hn.maxVisible or 8, 1, 25) do
        removeHitNotifEntry(#hitNotifEntries)
    end
end
local function getPlayerFromHitPart(hitPart)
    if not hitPart then
        return nil, nil, nil
    end
    local char = hitPart:FindFirstAncestorOfClass("Model")
    if not char and hitPart.Parent and hitPart.Parent:IsA("Model") then
        char = hitPart.Parent
    end
    if not char then
        return nil, nil, nil
    end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local plr = players:GetPlayerFromCharacter(char)
    return plr, hum, hitPart.Name
end
local function shouldNotifyPlayerHit(plr)
    if not config.hitNotifications.enabled or plr == player then
        return false
    end
    local lastShot = getgenv().InstanceCombatLastShotAt or 0
    if tick() - lastShot < 4 then
        return true
    end
    if config.target.lastplayer == plr then
        return true
    end
    if config.target.enabled and config.target.character then
        local tp = players:GetPlayerFromCharacter(config.target.character)
        if tp == plr then
            return true
        end
    end
    local lastHit = ragePerf.lastHitAtByPlayer[plr]
    return lastHit ~= nil and tick() - lastHit < 4
end
local function tryClaimHitDamage(plr, hum, bodyPart, allowFallback)
    if not hum or not hum.Parent then
        return false
    end
    local last = hitNotifHpTrack[plr]
    if last == nil then
        last = hum.Health
        hitNotifHpTrack[plr] = last
    end
    local cur = hum.Health
    local dmg = last - cur
    if dmg >= 0.01 then
        pushHitNotification(plr.Name, dmg, bodyPart or ragePerf.hitPartByPlayer[plr] or config.target.hitpart or "Body")
        hitNotifHpTrack[plr] = cur
        ragePerf.lastHitAtByPlayer[plr] = tick()
        return true
    end
    if allowFallback then
        pushHitNotification(plr.Name, 1, bodyPart or ragePerf.hitPartByPlayer[plr] or config.target.hitpart or "Body")
        ragePerf.lastHitAtByPlayer[plr] = tick()
        return true
    end
    return false
end
local function resolveQueuedHitNotif(plr, job)
    local hum = job.hum
    local bodyPart = job.bodyPart
    if not hum or not hum.Parent then
        return
    end
    if tryClaimHitDamage(plr, hum, bodyPart, false) then
        return
    end
    for _ = 1, 15 do
        task.wait(0)
        if tryClaimHitDamage(plr, hum, bodyPart, false) then
            return
        end
    end
    for _ = 1, 8 do
        task.wait(0.03)
        if tryClaimHitDamage(plr, hum, bodyPart, false) then
            return
        end
    end
    tryClaimHitDamage(plr, hum, bodyPart, true)
end
local function enqueueHitNotifResolve(plr, hum, bodyPart)
    hitNotifResolveQueues[plr] = hitNotifResolveQueues[plr] or {}
    table.insert(hitNotifResolveQueues[plr], {
        hum = hum,
        bodyPart = bodyPart,
        queuedAt = tick(),
    })
    if hitNotifResolveBusy[plr] then
        return
    end
    hitNotifResolveBusy[plr] = true
    task.spawn(function()
        while hitNotifResolveQueues[plr] and #hitNotifResolveQueues[plr] > 0 do
            local job = table.remove(hitNotifResolveQueues[plr], 1)
            resolveQueuedHitNotif(plr, job)
        end
        hitNotifResolveBusy[plr] = false
    end)
end
local function pollHitNotifHealth()
    if not config.hitNotifications.enabled then
        return
    end
    for _, plr in ipairs(players:GetPlayers()) do
        if plr == player then
            continue
        end
        if not shouldNotifyPlayerHit(plr) then
            continue
        end
        local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
        if not hum then
            continue
        end
        local last = hitNotifHpTrack[plr]
        if last == nil then
            hitNotifHpTrack[plr] = hum.Health
            continue
        end
        local cur = hum.Health
        if cur < last - 0.01 then
            local bodyPart = ragePerf.hitPartByPlayer[plr] or config.target.hitpart or "Body"
            pushHitNotification(plr.Name, last - cur, bodyPart)
            hitNotifHpTrack[plr] = cur
            ragePerf.lastHitAtByPlayer[plr] = tick()
            if cur <= 0 then
                local tryKill = getgenv().InstanceTryKillSound
                if tryKill then
                    tryKill(plr, last, cur)
                end
            end
        elseif cur > last then
            hitNotifHpTrack[plr] = cur
        end
    end
end
local function recordLocalHitTarget(plr, hum, bodyPart)
    if not plr or not hum or plr == player then
        return
    end
    localHitTargets[hum] = {
        plr = plr,
        bodyPart = bodyPart,
        hitAt = tick(),
        lastHp = hum.Health,
    }
end
local function notifyProjectileImpact(hitPart)
    if not hitPart then
        return
    end
    local plr, hum, bodyPart = getPlayerFromHitPart(hitPart)
    if not plr or not hum or plr == player then
        return
    end
    ragePerf.hitPartByPlayer[plr] = bodyPart
    ragePerf.lastHitAtByPlayer[plr] = tick()
    recordLocalHitTarget(plr, hum, bodyPart)
    if not config.hitNotifications.enabled then
        return
    end
    if not shouldNotifyPlayerHit(plr) then
        return
    end
    enqueueHitNotifResolve(plr, hum, bodyPart)
end
ragebot.notifyProjectileImpact = notifyProjectileImpact
local function onTargetHealthChanged(plr, newHp)
    if not config.hitNotifications.enabled then
        return
    end
    if hitNotifHpTrack[plr] == nil then
        hitNotifHpTrack[plr] = newHp
        return
    end
    if newHp > (hitNotifHpTrack[plr] or newHp) then
        hitNotifHpTrack[plr] = newHp
    end
end
local function unbindHitNotifPlayer(plr)
    if hitNotifHumConn[plr] then
        hitNotifHumConn[plr]:Disconnect()
        hitNotifHumConn[plr] = nil
    end
    if hitNotifCharConn[plr] then
        hitNotifCharConn[plr]:Disconnect()
        hitNotifCharConn[plr] = nil
    end
    hitNotifHpTrack[plr] = nil
    hitNotifResolveQueues[plr] = nil
    hitNotifResolveBusy[plr] = nil
end
local function bindHitNotifCharacter(plr, char)
    if plr == player or not char then
        return
    end
    if hitNotifHumConn[plr] then
        hitNotifHumConn[plr]:Disconnect()
        hitNotifHumConn[plr] = nil
    end
    local hum = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 8)
    if not hum then
        return
    end
    hitNotifHpTrack[plr] = hum.Health
    hitNotifHumConn[plr] = hum.HealthChanged:Connect(function(newHp)
        local localHit = localHitTargets and localHitTargets[hum]
        if newHp <= 0 and localHit and localHit.plr and localHit.plr ~= player and not config.hitNotifications.enabled then
            local tryKill2 = getgenv().InstanceTryKillSound
            if tryKill2 then
                tryKill2(localHit.plr, hitNotifHpTrack[plr] or 0, newHp)
            end
            if localHitTargets then
                localHitTargets[hum] = nil
            end
        end
        if not config.hitNotifications.enabled then
            local last = hitNotifHpTrack[plr]
            if last == nil or newHp > last then
                hitNotifHpTrack[plr] = newHp
            end
            return
        end
        local last = hitNotifHpTrack[plr]
        if last == nil then
            hitNotifHpTrack[plr] = newHp
            return
        end
        if newHp < last - 0.01 then
            if shouldNotifyPlayerHit(plr) then
                local bodyPart = ragePerf.hitPartByPlayer[plr] or config.target.hitpart or "Body"
                pushHitNotification(plr.Name, last - newHp, bodyPart)
                ragePerf.lastHitAtByPlayer[plr] = tick()
            end
            if newHp <= 0 then
                local tryKill = getgenv().InstanceTryKillSound
                if tryKill then
                    tryKill(plr, last, newHp)
                end
            end
            hitNotifHpTrack[plr] = newHp
        elseif newHp > last then
            hitNotifHpTrack[plr] = newHp
        end
    end)
    hum.Died:Connect(function()
        local last = hitNotifHpTrack[plr]
        local tryKill = getgenv().InstanceTryKillSound
        if tryKill and last and last > 0 then
            tryKill(plr, last, 0)
        end
        local localHit = localHitTargets and localHitTargets[hum]
        if localHit then
            if not config.hitNotifications.enabled then
                local tryKill2 = getgenv().InstanceTryKillSound
                if tryKill2 and localHit.plr and localHit.plr ~= player then
                    tryKill2(localHit.plr, last or 0, 0)
                end
            end
            if localHitTargets then
                localHitTargets[hum] = nil
            end
        end
    end)
end
local function bindHitNotifPlayer(plr)
    if plr == player then
        return
    end
    if hitNotifCharConn[plr] then
        hitNotifCharConn[plr]:Disconnect()
    end
    hitNotifCharConn[plr] = plr.CharacterAdded:Connect(function(char)
        bindHitNotifCharacter(plr, char)
    end)
    if plr.Character then
        bindHitNotifCharacter(plr, plr.Character)
    end
end
players.PlayerAdded:Connect(bindHitNotifPlayer)
players.PlayerRemoving:Connect(unbindHitNotifPlayer)
for _, plr in players:GetPlayers() do
    bindHitNotifPlayer(plr)
end
local function updateHitNotifications(dt)
    local hn = config.hitNotifications
    if not hn.enabled or shouldSuppressGameplayOverlays() then
        hitNotifRoot.Visible = false
        if not hn.enabled then
            for i = #hitNotifEntries, 1, -1 do
                removeHitNotifEntry(i)
            end
        end
        return
    end
    pollHitNotifHealth()
    hitNotifRoot.Visible = #hitNotifEntries > 0
    applyHitNotifRootPosition()
    dt = dt or 0
    local now = tick()
    local inDur = math.clamp(hn.animInDuration or 0.52, 0.15, 2)
    local outDur = math.clamp(hn.animOutDuration or 0.38, 0.15, 2)
    local totalDur = hn.duration or 3
    local gap = hn.stackGap or 6
    local inStyle = hn.inAnimation or "fade bounce"
    local outStyle = hn.outAnimation or "fade"
    local y = 0
    for _, entry in ipairs(hitNotifEntries) do
        entry.targetY = y
        entry.displayY = entry.displayY or y
        if dt > 0 then
            entry.displayY = entry.displayY + (entry.targetY - entry.displayY) * (1 - math.exp(-dt * 14))
        else
            entry.displayY = entry.targetY
        end
        y = y + (entry.boxH or 26) + gap
    end
    local i = 1
    while i <= #hitNotifEntries do
        local entry = hitNotifEntries[i]
        local age = now - entry.start
        if entry.phase == "in" then
            local t = (now - entry.phaseStart) / inDur
            if t >= 1 then
                entry.phase = "hold"
                entry.phaseStart = now
                t = 1
            end
            local a, ox, oy, sc = sampleHitNotifAnim(inStyle, t, false)
            applyHitNotifVisual(entry, a, ox, oy, sc)
        elseif entry.phase == "hold" then
            applyHitNotifVisual(entry, 1, 0, 0, 1)
            if age >= totalDur - outDur then
                entry.phase = "out"
                entry.phaseStart = now
            end
        elseif entry.phase == "out" then
            local t = (now - entry.phaseStart) / outDur
            if t >= 1 then
                removeHitNotifEntry(i)
                continue
            end
            local a, ox, oy, sc = sampleHitNotifAnim(outStyle, t, true)
            applyHitNotifVisual(entry, a, ox, oy, sc)
        else
            entry.phase = "in"
            entry.phaseStart = now
        end
        i = i + 1
    end
end
ragebot.updateHitNotifications = updateHitNotifications
ragebot.clearHitNotifications = function()
    for i = #hitNotifEntries, 1, -1 do
        removeHitNotifEntry(i)
    end
    if hitNotifRoot then
        hitNotifRoot.Visible = false
    end
end
ragebot.hitNotifAnimStyles = HIT_NOTIF_ANIM_STYLES
ragebot.applyHitNotifRootPosition = applyHitNotifRootPosition
