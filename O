local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local function getHRP()
    local c = player.Character; return c and c:FindFirstChild("HumanoidRootPart")
end
local function getHum()
    local c = player.Character; return c and c:FindFirstChildOfClass("Humanoid")
end
local advancedSpeedConn, advancedNoclipConn, advancedIJConn
local function applyAdvancedSpeed()
    if advancedSpeedConn then advancedSpeedConn:Disconnect(); advancedSpeedConn=nil end
    local h=getHum(); if h then pcall(function() h.WalkSpeed=CFG.SPEED_ENABLED and CFG.WALK_SPEED or 16 end) end
    if not CFG.SPEED_ENABLED then return end
    advancedSpeedConn=RunService.Heartbeat:Connect(function()
        if not CFG.SPEED_ENABLED then advancedSpeedConn:Disconnect(); advancedSpeedConn=nil; return end
        local hum=getHum(); if hum and hum.WalkSpeed~=CFG.WALK_SPEED then pcall(function() hum.WalkSpeed=CFG.WALK_SPEED end) end
    end)
end
local function startAdvancedNoclip()
    if advancedNoclipConn then advancedNoclipConn:Disconnect(); advancedNoclipConn=nil end
    advancedNoclipConn=RunService.Stepped:Connect(function()
        if not CFG.NOCLIP then advancedNoclipConn:Disconnect(); advancedNoclipConn=nil; return end
        local c=player.Character; if not c then return end
        for _,p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") then pcall(function() p.CanCollide=false end) end
        end
    end)
end
local function startAdvancedIJ()
    if advancedIJConn then advancedIJConn:Disconnect(); advancedIJConn=nil end
    advancedIJConn=UserInputService.JumpRequest:Connect(function()
        if not CFG.INF_JUMP then advancedIJConn:Disconnect(); advancedIJConn=nil; return end
        local h=getHum(); if h then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end
    end)
end
local function applyAdvancedGravity()
    pcall(function() workspace.Gravity=CFG.LOW_GRAVITY and CFG.GRAVITY_VAL or 196.2 end)
end
local function applyAdvancedFPSBoost()
    pcall(function()
        local l=game:GetService("Lighting")
        l.GlobalShadows=false; l.FogEnd=9e9; l.Brightness=0
        workspace.Terrain.WaterWaveSize=0; workspace.Terrain.WaterWaveSpeed=0
        for _,v in ipairs(l:GetChildren()) do
            if v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("BloomEffect") then v.Enabled=false end
        end
        for _,v in ipairs(workspace:GetDescendants()) do
            pcall(function()
                if v:IsA("ParticleEmitter") or v:IsA("Trail") then v.Lifetime=NumberRange.new(0)
                elseif v:IsA("Fire") or v:IsA("SpotLight") or v:IsA("Smoke") then v.Enabled=false end
            end)
        end
    end)
end
local player = Players.LocalPlayer
if autoload == nil then autoload = true end
if autoleave == nil then autoleave = true end
local rapidFireEnabled = false
local oldInputFunc = nil
local function StartRapidFire()
    if rapidFireEnabled then return end
    rapidFireEnabled = true
    local clientItemModule = require(game:GetService("Players").LocalPlayer.PlayerScripts.Modules.ClientReplicatedClasses.ClientFighter.ClientItem)
    local inputFunc = clientItemModule.Input
    oldInputFunc = hookfunction(inputFunc, function(...)
        local args = {...}
        if type(args[1]) == "table" then
            args[1].Info.ShootRecoil = 0
            args[1].Info.ShootSpread = 0
            args[1].Info.ProjectileSpeed = 99999999
            args[1].Info.ShootCooldown = 0
            args[1].Info.QuickShotCooldown = 0
        end
        return oldInputFunc(...)
    end)
end
local function StopRapidFire()
    if not rapidFireEnabled then return end
    rapidFireEnabled = false
    if oldInputFunc then
        local clientItemModule = require(game:GetService("Players").LocalPlayer.PlayerScripts.Modules.ClientReplicatedClasses.ClientFighter.ClientItem)
        hookfunction(clientItemModule.Input, oldInputFunc)
        oldInputFunc = nil
    end
end
local Wallbang = {Enabled = false, HitPart = "Head"}
local __a1b2c3 = setmetatable({}, {
    __index = function(__d4e5f6, __g7h8i9)
        local __j0k1l2, __m3n4o5 = pcall(function()
            return game:GetService(__g7h8i9)
        end)
        if __m3n4o5 then
            return cloneref(__m3n4o5)
        end
        return nil
    end
})
local __p6q7r8 = getgenv()
if __p6q7r8.__s9t0u1 then
    __p6q7r8.__s9t0u1:Shutdown()
end
local __v2w3x4 = __a1b2c3.Players
local __y5z6a7 = __a1b2c3.RunService
local __b8c9d0 = __a1b2c3.ReplicatedStorage
local __e1f2g3 = __a1b2c3.Workspace
local __h4i5j6 = __a1b2c3.UserInputService
local __k7l8m9 = __v2w3x4.LocalPlayer
local __n0o1p2 = __e1f2g3.CurrentCamera
local __q3r4s5 = __k7l8m9.PlayerScripts
local __t6u7v8 = require(__q3r4s5.Modules.ItemTypes.Gun)
local __w9x0y1 = require(__b8c9d0.Modules.Utility)
local __z2a3b4 = setmetatable({}, {
    __index = function(_, __c5d6e7)
        local __f8g9h0 = __k7l8m9.Character
        if not __f8g9h0 then return nil end
        if __c5d6e7 == "__root" then
            return __f8g9h0:FindFirstChild("HumanoidRootPart")
        elseif __c5d6e7 == "__head" then
            return __f8g9h0:FindFirstChild("Head")
        end
        return nil
    end
})
__p6q7r8.__s9t0u1 = {}
do
    local __i1j2k3 = __p6q7r8.__s9t0u1
    function __i1j2k3:__init()
        self.__active = false
        self.__target = nil
        self.__desync = false
        self.__conn1 = nil
        self.__conn2 = nil
        self.__task1 = nil
        self.__oldfunc = nil
        self.__autoshootConnection = nil
    end
    function __i1j2k3:__find()
        local __s7t8u9 = nil
        local __v0w1x2 = math.huge
        for _, __b6c7d8 in next, __v2w3x4:GetPlayers() do
            if __b6c7d8 == __k7l8m9 then continue end
            if __b6c7d8:GetAttribute("TeamID") == __k7l8m9:GetAttribute("TeamID") then continue end
            local __e9f0g1 = __b6c7d8.Character
            if not __e9f0g1 then continue end
            local Tete = __e9f0g1:FindFirstChild("Head")
            local __n8o9p0 = __e9f0g1:FindFirstChildWhichIsA("Humanoid")
            if not (Tete and __n8o9p0 and __n8o9p0.Health > 0) then continue end
            local Distance = (__n0o1p2.CFrame.Position - Tete.Position).Magnitude
            if Distance < __v0w1x2 then
                __v0w1x2 = Distance
                __s7t8u9 = __b6c7d8
            end
        end
        return __s7t8u9
    end
    function __i1j2k3:__getHitPart(char)
        if Wallbang.HitPart == "Head" then
            return char:FindFirstChild("Head")
        else
            return char:FindFirstChild("UpperTorso")
                or char:FindFirstChild("Torso")
                or char:FindFirstChild("HumanoidRootPart")
        end
    end
    function __i1j2k3:__startAutoShoot()
        if self.__autoshootConnection then
            self.__autoshootConnection:Disconnect()
        end
        self.__autoshootConnection = __y5z6a7.Heartbeat:Connect(function()
            if not self.__active then return end
            if not self.__target then return end
            local target = self.__target
            local targetChar = target.Character
            if not targetChar then return end
            local targetHumanoid = targetChar:FindFirstChildWhichIsA("Humanoid")
            if not targetHumanoid or targetHumanoid.Health <= 0 then return end
            local aimPart = self:__getHitPart(targetChar)
            if not aimPart then return end
            __n0o1p2.CFrame = CFrame.new(__n0o1p2.CFrame.Position, aimPart.Position)
            local character = __k7l8m9.Character
            if not character then return end
            local currentTool = character:FindFirstChildWhichIsA("Tool")
            if not currentTool then return end
            local remote = __b8c9d0:FindFirstChild("ShootEvent") or __b8c9d0:FindFirstChild("FireEvent")
            if remote and remote:IsA("RemoteEvent") then
                remote:FireServer()
            end
            local VirtualUser = game:GetService("VirtualUser")
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton1(Vector2.new(0, 0))
            end)
            pcall(function()
                if currentTool:FindFirstChild("GunModule") then
                    local gun = require(currentTool.GunModule)
                    if gun and gun.Shoot then
                        gun:Shoot()
                    elseif gun and gun.Fire then
                        gun:Fire()
                    end
                end
            end)
        end)
    end
    function __i1j2k3:__setup()
        if self.__conn1 then self.__conn1:Disconnect() end
        self.__conn1 = __y5z6a7.Heartbeat:Connect(function()
            if not self.__active then return end
            self.__target = self:__find()
        end)
        local __l4m5n6 = __t6u7v8.StartShooting
        self.__oldfunc = __l4m5n6
        __t6u7v8.StartShooting = function(__o7p8q9, ...)
            local __r0s1t2 = {__l4m5n6(__o7p8q9, ...)}
            if not __o7p8q9.ClientFighter or not __o7p8q9.ClientFighter.IsLocalPlayer then
                return unpack(__r0s1t2)
            end
            local __u3v4w5 = __r0s1t2[3]
            if not __u3v4w5 or typeof(__u3v4w5) ~= "table" then
                return unpack(__r0s1t2)
            end
            __r0s1t2[4] = true
            local __x6y7z8 = self.__target
            if not self.__active or not __x6y7z8 or not __x6y7z8.Character then
                return unpack(__r0s1t2)
            end
            self:__desync_start(__x6y7z8)
            task.wait(0.1)
            if self.__task1 then
                task.cancel(self.__task1)
                self.__task1 = nil
            end
            local TargetPart = self:__getHitPart(__x6y7z8.Character)
            if not TargetPart then
                return unpack(__r0s1t2)
            end
            local TargetPos = TargetPart.Position
            local TargetCF  = TargetPart.CFrame
            local OriginPos = TargetPos - Vector3.new(0, 3, 0)
            __u3v4w5[utf8.char(0)] = __w9x0y1:EncodeCFrame(CFrame.new(OriginPos, TargetPos))
            __u3v4w5[utf8.char(1)] = __w9x0y1:EncodeCFrame(CFrame.new(TargetPos))
            __u3v4w5[utf8.char(2)] = TargetPart
            local RandomOffset = TargetCF:ToObjectSpace(
                CFrame.new(TargetPos + Vector3.new(
                    math.random(-1, 1) * 0.5,
                    math.random(-1, 1) * 0.5,
                    math.random(-1, 1) * 0.5
                ))
            )
            __u3v4w5[utf8.char(3)] = __w9x0y1:EncodeCFrame(RandomOffset)
            if __u3v4w5.Hitbox then
                __u3v4w5.Hitbox = Wallbang.HitPart == "Head" and "Head" or "Body"
            end
            self.__task1 = task.delay(0.15, function()
                self:__desync_stop()
            end)
            return unpack(__r0s1t2)
        end
        self:__startAutoShoot()
    end
    function __i1j2k3:__desync_start(__c3d4e5)
        if self.__conn2 then self.__conn2:Disconnect() end
        self.__desync = true
        self.__curr = __c3d4e5
        self.__conn2 = __y5z6a7.Heartbeat:Connect(function()
            if not self.__desync then return end
            local __f6g7h8 = __z2a3b4.__root
            if not __f6g7h8 then return end
            local TeteCible = __c3d4e5.Character and __c3d4e5.Character:FindFirstChild("Head")
            if not TeteCible then
                self:__desync_stop()
                return
            end
            local __l2m3n4 = __f6g7h8.CFrame
            local __o5p6q7 = __f6g7h8.Velocity
            local __r8s9t0 = __f6g7h8.RotVelocity
            __f6g7h8.CFrame = TeteCible.CFrame * CFrame.new(0, -5, 0)
            __y5z6a7:BindToRenderStep("__restore", 101, function()
                __f6g7h8.CFrame = __l2m3n4
                __f6g7h8.Velocity = __o5p6q7
                __f6g7h8.RotVelocity = __r8s9t0
                __y5z6a7:UnbindFromRenderStep("__restore")
            end)
        end)
    end
    function __i1j2k3:__desync_stop()
        self.__desync = false
        self.__curr = nil
        if self.__conn2 then
            self.__conn2:Disconnect()
            self.__conn2 = nil
        end
    end
    function __i1j2k3:Start()
        self.__active = true
        self:__setup()
    end
    function __i1j2k3:Shutdown()
        self.__active = false
        if self.__autoshootConnection then
            self.__autoshootConnection:Disconnect()
            self.__autoshootConnection = nil
        end
        if self.__conn1 then self.__conn1:Disconnect() end
        if self.__conn2 then self.__conn2:Disconnect() end
        if self.__task1 then task.cancel(self.__task1) end
        if self.__oldfunc then
            __t6u7v8.StartShooting = self.__oldfunc
        end
    end
end
local AA = {Enabled=false, Speed=50, Connection=nil}
local function StartAntiAim()
    if AA.Connection then AA.Connection:Disconnect() end
    AA.Enabled = true
    local angle = 0
    AA.Connection = RunService.RenderStepped:Connect(function()
        if not AA.Enabled then return end
        local char = player.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        angle = (angle + AA.Speed) % 360
        local currentCF = hrp.CFrame
        local newRotation = CFrame.Angles(0, math.rad(angle), 0)
        local jitter = math.random(-20, 20)
        newRotation = newRotation * CFrame.Angles(math.rad(jitter), 0, math.rad(jitter))
        hrp.CFrame = CFrame.new(currentCF.Position) * newRotation
    end)
end
local function StopAntiAim()
    AA.Enabled = false
    if AA.Connection then AA.Connection:Disconnect(); AA.Connection = nil end
end
local D = {On=false, Device="Touch"}
local spoofThread = nil
local function StartSpoof()
    if spoofThread then task.cancel(spoofThread) end
    spoofThread = task.spawn(function()
        while D.On do
            pcall(function()
                local rs = game:GetService("ReplicatedStorage")
                local remote = rs and rs:FindFirstChild("Remotes")
                if remote then
                    local setControls = remote:FindFirstChild("Replication") and remote.Replication:FindFirstChild("Fighter") and remote.Replication.Fighter:FindFirstChild("SetControls")
                    if setControls then setControls:FireServer(D.Device) end
                end
            end)
            task.wait(5)
        end
    end)
end
local function StopSpoof()
    if spoofThread then task.cancel(spoofThread); spoofThread = nil end
end
local function UpdateSkeletonESP()
    for i, drawing in pairs(SkeletonDrawings) do
        pcall(function() drawing:Remove() end)
    end
    SkeletonDrawings = {}
    local camera = workspace.CurrentCamera
    if not camera then return end
    for _, plr in pairs(Players:GetPlayers()) do
        if plr == player then continue end
        local character = plr.Character
        if not character or not character.Parent then continue end
        local humanoid = character:FindFirstChild("Humanoid")
        if not humanoid or humanoid.Health <= 0 then continue end
        local isR15 = IsR15(character)
        local points = isR15 and SkeletonPoints or SkeletonPointsR6
        local parts = GetCharacterParts(character)
        for _, point in pairs(points) do
            local fromPart = parts[point.From]
            local toPart = parts[point.To]
            if fromPart and toPart then
                local fromScreen, fromVis = camera:WorldToViewportPoint(fromPart.Position)
                local toScreen, toVis = camera:WorldToViewportPoint(toPart.Position)
                if fromVis and toVis then
                    local lineOutline = Drawing.new("Line")
                    lineOutline.From = Vector2.new(fromScreen.X, fromScreen.Y)
                    lineOutline.To = Vector2.new(toScreen.X, toScreen.Y)
                    lineOutline.Color = Color3.new(0, 0, 0)
                    lineOutline.Thickness = 4
                    lineOutline.Visible = true
                    table.insert(SkeletonDrawings, lineOutline)
                    local line = Drawing.new("Line")
                    line.From = Vector2.new(fromScreen.X, fromScreen.Y)
                    line.To = Vector2.new(toScreen.X, toScreen.Y)
                    line.Color = Color3.new(1, 1, 1)
                    line.Thickness = 2
                    line.Visible = true
                    table.insert(SkeletonDrawings, line)
                end
            end
        end
    end
end
local TracerDrawings = {}
local TracerColor = Color3.fromRGB(160, 80, 255)
local function UpdateTracers()
    for i, drawing in pairs(TracerDrawings) do
        pcall(function() drawing:Remove() end)
    end
    TracerDrawings = {}
    local camera = workspace.CurrentCamera
    if not camera then return end
    local centerX = camera.ViewportSize.X / 2
    local centerY = camera.ViewportSize.Y
    if centerX <= 0 or centerY <= 0 then return end
    for _, plr in pairs(Players:GetPlayers()) do
        if plr == player then continue end
        local character = plr.Character
        if not character or not character.Parent then continue end
        local humanoid = character:FindFirstChild("Humanoid")
        local head = character:FindFirstChild("Head")
        if humanoid and head and humanoid.Health > 0 then
            local headScreen, onScreen = camera:WorldToViewportPoint(head.Position)
            if onScreen then
                local tracerOutline = Drawing.new("Line")
                tracerOutline.Visible = true
                tracerOutline.From = Vector2.new(centerX, centerY)
                tracerOutline.To = Vector2.new(headScreen.X, headScreen.Y)
                tracerOutline.Color = Color3.new(0, 0, 0)
                tracerOutline.Thickness = 4
                table.insert(TracerDrawings, tracerOutline)
                local tracer = Drawing.new("Line")
                tracer.Visible = true
                tracer.From = Vector2.new(centerX, centerY)
                tracer.To = Vector2.new(headScreen.X, headScreen.Y)
                tracer.Color = TracerColor
                tracer.Thickness = 2
                table.insert(TracerDrawings, tracer)
            end
        end
    end
end
local HealthBarDrawings = {}
local WeaponTagDrawings = {}
local function getPlayerWeapon(plr)
    local char = plr.Character
    if not char then return "Unknown" end
    local tool = char:FindFirstChildOfClass("Tool")
    if tool then return tool.Name end
    local bp = plr:FindFirstChild("Backpack")
    if bp then
        local equipped = bp:FindFirstChildOfClass("Tool")
        if equipped then return equipped.Name end
    end
    local weaponName = "Unknown"
    pcall(function()
        for _, v in ipairs(getgc(true)) do
            if type(v) == "table" then
                if rawget(v, "WeaponName") ~= nil and rawget(v, "Player") == plr then
                    weaponName = v.WeaponName
                    return
                end
                if rawget(v, "ItemName") ~= nil and rawget(v, "Player") == plr then
                    weaponName = v.ItemName
                    return
                end
            end
        end
    end)
    return weaponName
end
local function UpdateHealthWeaponESP()
    for _, d in pairs(HealthBarDrawings) do pcall(function() d:Remove() end) end
    for _, d in pairs(WeaponTagDrawings) do pcall(function() d:Remove() end) end
    HealthBarDrawings = {}
    WeaponTagDrawings = {}
    if not SETTINGS.ENABLE_HEALTH_ESP and not SETTINGS.ENABLE_NAME_ESP and not SETTINGS.ENABLE_BOXES_ESP then return end
    local camera = workspace.CurrentCamera
    if not camera then return end
    for _, plr in pairs(Players:GetPlayers()) do
        if plr == player then continue end
        local char = plr.Character
        if not char or not char.Parent then continue end
        local hum = char:FindFirstChild("Humanoid")
        local head = char:FindFirstChild("Head")
        local root = char:FindFirstChild("HumanoidRootPart")
        if not hum or not head or not root or hum.Health <= 0 then continue end
        local headSP, headVis = camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.7, 0))
        local rootSP, rootVis = camera:WorldToViewportPoint(root.Position)
        local footSP = camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3.2, 0))
        if not headVis and not rootVis then continue end
        local boxH = math.abs(headSP.Y - footSP.Y)
        local boxW = boxH * 0.5
        local boxX = headSP.X - boxW / 2
        local boxY = headSP.Y
        local hpPct = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
        local white = Color3.fromRGB(255, 255, 255)
        if SETTINGS.ENABLE_BOXES_ESP then
            local boxOutline = Drawing.new("Square")
            boxOutline.Visible = true
            boxOutline.Filled = false
            boxOutline.Color = Color3.fromRGB(0, 0, 0)
            boxOutline.Thickness = 3
            boxOutline.Position = Vector2.new(boxX - 1, boxY - 1)
            boxOutline.Size = Vector2.new(boxW + 2, boxH + 2)
            table.insert(HealthBarDrawings, boxOutline)
            local box = Drawing.new("Square")
            box.Visible = true
            box.Filled = false
            box.Color = white
            box.Thickness = 1.5
            box.Position = Vector2.new(boxX, boxY)
            box.Size = Vector2.new(boxW, boxH)
            table.insert(HealthBarDrawings, box)
        end
        if SETTINGS.ENABLE_NAME_ESP then
            local nameTag = Drawing.new("Text")
            nameTag.Visible = true
            nameTag.Text = plr.Name
            nameTag.Size = 12
            nameTag.Font = Drawing.Fonts.UI
            nameTag.Center = true
            nameTag.Outline = true
            nameTag.Color = white
            nameTag.Position = Vector2.new(headSP.X, boxY - 16)
            table.insert(HealthBarDrawings, nameTag)
        end
        if SETTINGS.ENABLE_HEALTH_ESP then
            local hpBg = Drawing.new("Square")
            hpBg.Visible = true
            hpBg.Filled = true
            hpBg.Color = Color3.fromRGB(0, 0, 0)
            hpBg.Transparency = 0.5
            hpBg.Position = Vector2.new(boxX - 8, boxY)
            hpBg.Size = Vector2.new(5, boxH)
            table.insert(HealthBarDrawings, hpBg)
            local hpFill = Drawing.new("Square")
            hpFill.Visible = true
            hpFill.Filled = true
            hpFill.Color = Color3.new(1 - hpPct, hpPct, 0)
            hpFill.Transparency = 1
            hpFill.Position = Vector2.new(boxX - 8, boxY + boxH - boxH * hpPct)
            hpFill.Size = Vector2.new(5, boxH * hpPct)
            table.insert(HealthBarDrawings, hpFill)
            local hpText = Drawing.new("Text")
            hpText.Visible = true
            hpText.Text = tostring(math.floor(hum.Health)) .. " HP"
            hpText.Size = 11
            hpText.Font = Drawing.Fonts.UI
            hpText.Center = true
            hpText.Outline = true
            hpText.Color = white
            hpText.Position = Vector2.new(headSP.X, boxY - 14)
            table.insert(HealthBarDrawings, hpText)
        end
    end
end
local highlights = {}
local XRayColor = Color3.fromRGB(160, 80, 255)
local xrayActive = false
local function ApplyXRayToCharacter(character, plr)
    if not xrayActive then return end
    if plr == player then return end
    if not character or not character.Parent then return end
    if highlights[plr] then
        pcall(function() highlights[plr]:Destroy() end)
        highlights[plr] = nil
    end
    local hl = Instance.new("Highlight")
    hl.FillColor = XRayColor
    hl.FillTransparency = 0.5
    hl.OutlineTransparency = 1
    hl.Adornee = character
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = character
    highlights[plr] = hl
end
local function UpdateAllXRay()
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player then
            local character = plr.Character
            if character and character.Parent then
                local humanoid = character:FindFirstChild("Humanoid")
                if humanoid and humanoid.Health > 0 then
                    ApplyXRayToCharacter(character, plr)
                else
                    if highlights[plr] then
                        pcall(function() highlights[plr]:Destroy() end)
                        highlights[plr] = nil
                    end
                end
            else
                if highlights[plr] then
                    pcall(function() highlights[plr]:Destroy() end)
                    highlights[plr] = nil
                end
            end
        end
    end
end
local function SetupXRayWatcher(plr)
    if plr == player then return end
    plr.CharacterAdded:Connect(function(character)
        repeat task.wait() until character and character.Parent
        task.wait(0.3)
        if xrayActive then
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health > 0 then
                ApplyXRayToCharacter(character, plr)
            end
        end
    end)
    if plr.Character then
        local humanoid = plr.Character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.Died:Connect(function()
                if highlights[plr] then
                    pcall(function() highlights[plr]:Destroy() end)
                    highlights[plr] = nil
                end
            end)
        end
    end
end
local function StartXRay()
    xrayActive = true
    UpdateAllXRay()
end
local function StopXRay()
    xrayActive = false
    for _, plr in pairs(Players:GetPlayers()) do
        if highlights[plr] then
            pcall(function() highlights[plr]:Destroy() end)
            highlights[plr] = nil
        end
    end
end
local noRecoilEnabled = false
local noRecoilConnection = nil
local startPitch, startYaw
local function getAngles()
    local camera = workspace.CurrentCamera
    local lv = camera.CFrame.LookVector
    local pitch = math.asin(-lv.Y)
    local yaw = math.atan2(lv.X, lv.Z)
    return pitch, yaw
end
local function normalize(angle)
    while angle > math.pi do angle = angle - 2 * math.pi end
    while angle < -math.pi do angle = angle + 2 * math.pi end
    return angle
end
local function startNoRecoil()
    if noRecoilEnabled then return end
    if noRecoilConnection then 
        noRecoilConnection:Disconnect()
        noRecoilConnection = nil
    end
    noRecoilEnabled = true
    UserInputService.InputBegan:Connect(function(input, gp)
        if gp or not noRecoilEnabled then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            startPitch, startYaw = getAngles()
            if noRecoilConnection then noRecoilConnection:Disconnect() end
            noRecoilConnection = RunService.RenderStepped:Connect(function()
                if not noRecoilEnabled or not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
                    if noRecoilConnection then 
                        noRecoilConnection:Disconnect()
                        noRecoilConnection = nil
                    end
                    return
                end
                local curPitch, curYaw = getAngles()
                local deltaPitch = curPitch - startPitch
                local deltaYaw = normalize(curYaw - startYaw)
                local newPitch = curPitch - deltaPitch
                local newYaw = curYaw - deltaYaw
                local lv = Vector3.new(
                    math.cos(newPitch) * math.sin(newYaw),
                    -math.sin(newPitch),
                    math.cos(newPitch) * math.cos(newYaw)
                )
                local camera = workspace.CurrentCamera
                camera.CFrame = CFrame.new(camera.CFrame.Position, camera.CFrame.Position + lv)
            end)
        end
    end)
end
local function stopNoRecoil()
    noRecoilEnabled = false
    if noRecoilConnection then
        noRecoilConnection:Disconnect()
        noRecoilConnection = nil
    end
end
local textureColorActive = false
local textureColorConnection = nil
local currentTextureColor = Color3.fromRGB(255, 0, 0)
local function applyTextureColor(color)
    for _, obj in pairs(workspace:GetDescendants()) do
        pcall(function()
            if obj:IsA("BasePart") then
                local parentModel = obj:FindFirstAncestorOfClass("Model")
                if not (parentModel and parentModel:FindFirstChildOfClass("Humanoid")) then
                    obj.Color = color
                end
            end
            if obj:IsA("Decal") or obj:IsA("Texture") then
                obj.Color3 = color
            end
        end)
    end
end
local function startTextureColorChanger(color)
    if textureColorConnection then textureColorConnection:Disconnect() end
    textureColorActive = true
    currentTextureColor = color
    applyTextureColor(color)
    textureColorConnection = workspace.DescendantAdded:Connect(function(desc)
        if textureColorActive then
            task.wait(0.05)
            pcall(function()
                if desc:IsA("BasePart") then
                    local parentModel = desc:FindFirstAncestorOfClass("Model")
                    if not (parentModel and parentModel:FindFirstChildOfClass("Humanoid")) then
                        desc.Color = currentTextureColor
                    end
                end
                if desc:IsA("Decal") or desc:IsA("Texture") then
                    desc.Color3 = currentTextureColor
                end
            end)
        end
    end)
end
local function stopTextureColorChanger()
    textureColorActive = false
    if textureColorConnection then
        textureColorConnection:Disconnect()
        textureColorConnection = nil
    end
end
local function setupGameplayFunctions(ctx)
    local Library = ctx.Library
    local lp = ctx.lp
    local cam = ctx.cam
    local SETTINGS = ctx.SETTINGS
    local Workspace = ctx.Workspace
    local ReplicatedStorage = ctx.ReplicatedStorage
    local Players = ctx.Players
    local RunService = ctx.RunService
    local UserInputService = ctx.UserInputService
    local function cleanupFly()
        if ctx.flyThread then task.cancel(ctx.flyThread); ctx.flyThread = nil end
        if ctx.bodyVelocity then ctx.bodyVelocity:Destroy(); ctx.bodyVelocity = nil end
        if ctx.bodyGyro then ctx.bodyGyro:Destroy(); ctx.bodyGyro = nil end
    end
    ctx.cleanupFly = cleanupFly
    ctx.startFly = function()
        if ctx.followActive then return end
        local char = lp.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not root or not hum then return end
        cleanupFly()
        ctx.bodyVelocity = Instance.new("BodyVelocity", root)
        ctx.bodyVelocity.MaxForce = Vector3.new(1e6, 1e6, 1e6)
        ctx.bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        ctx.bodyGyro = Instance.new("BodyGyro", root)
        ctx.bodyGyro.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
        ctx.bodyGyro.P = 10000
        hum:ChangeState(Enum.HumanoidStateType.Swimming)
        ctx.flyEnabled = true
        ctx.flyThread = task.spawn(function()
            while ctx.flyEnabled and char and char.Parent and root and root.Parent do
                local humCurrent = char:FindFirstChildOfClass("Humanoid")
                if humCurrent then
                    local moveDir = humCurrent.MoveDirection
                    if ctx.bodyVelocity then
                        ctx.bodyVelocity.Velocity = moveDir.Magnitude > 0 and moveDir * ctx.flySpeed or Vector3.new(0, 0, 0)
                    end
                    if ctx.bodyGyro then ctx.bodyGyro.CFrame = cam.CFrame end
                    if humCurrent:GetState() ~= Enum.HumanoidStateType.Swimming then
                        humCurrent:ChangeState(Enum.HumanoidStateType.Swimming)
                    end
                end
                task.wait()
            end
            cleanupFly()
        end)
    end
    ctx.stopFly = function()
        ctx.flyEnabled = false
        cleanupFly()
        local char = lp.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum:GetState() == Enum.HumanoidStateType.Swimming then
                hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
        end
    end
    ctx.startNoclip = function()
        if ctx.noclipConnection then ctx.noclipConnection:Disconnect() end
        ctx.noclipActive = true
        ctx.noclipConnection = RunService.Stepped:Connect(function()
            if SETTINGS.ENABLE_NOCLIP and lp.Character and not ctx.followActive then
                for _, part in pairs(lp.Character:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end
        end)
    end
    ctx.stopNoclip = function()
        ctx.noclipActive = false
        if ctx.noclipConnection then ctx.noclipConnection:Disconnect(); ctx.noclipConnection = nil end
        if lp.Character and not ctx.followActive then
            for _, part in pairs(lp.Character:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = true end
            end
        end
    end
    ctx.stopFollow = function()
        ctx.followActive = false
        if ctx.followConnection then ctx.followConnection:Disconnect(); ctx.followConnection = nil end
        ctx.followTarget = nil
    end
    local function isPlayerAliveForTP(plr)
        if not plr.Character then return false end
        local hum = plr.Character:FindFirstChildOfClass("Humanoid")
        return hum and hum.Health > 0
    end
    local function getNearestEnemy()
        local closestDistance = math.huge
        local closestPlr = nil
        local myPos = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") and lp.Character.HumanoidRootPart.Position
        if not myPos then return nil end
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= lp and isPlayerAliveForTP(plr) and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = plr.Character.HumanoidRootPart
                local distance = (myPos - hrp.Position).Magnitude
                if distance < closestDistance then
                    closestDistance = distance
                    closestPlr = plr
                end
            end
        end
        return closestPlr
    end
    ctx.startFollow = function()
        if ctx.followActive then ctx.stopFollow(); return end
        ctx.followActive = true
        ctx.followConnection = RunService.RenderStepped:Connect(function()
            if not ctx.followActive then return end
            local char = lp.Character
            if not char then return end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if not hum then return end
            if hum.Health <= 0 then
                if SETTINGS.AUTO_RETARGET then
                    task.wait(SETTINGS.RETARGET_DELAY)
                    ctx.followTarget = getNearestEnemy()
                end
                return
            end
            if not ctx.followTarget or not isPlayerAliveForTP(ctx.followTarget) then
                ctx.followTarget = getNearestEnemy()
                if not ctx.followTarget then return end
            end
            if ctx.followTarget and ctx.followTarget.Character then
                local targetHrp = ctx.followTarget.Character:FindFirstChild("HumanoidRootPart")
                if targetHrp then
                    local myHrp = char:FindFirstChild("HumanoidRootPart")
                    if myHrp then
                        myHrp.CFrame = targetHrp.CFrame + Vector3.new(0, SETTINGS.FOLLOW_HEIGHT, 0)
                    end
                end
            end
        end)
    end
    local function isMapPart(part)
        if not part:IsA("BasePart") then return false end
        if part:FindFirstAncestorOfClass("Tool") then return false end
        local parentModel = part:FindFirstAncestorOfClass("Model")
        if parentModel and parentModel:FindFirstChildOfClass("Humanoid") then return false end
        if part.Size.Magnitude < 5 then return false end
        if not part.Anchored then return false end
        return true
    end
    ctx.startDarkTexture = function()
        if ctx.darkTextureConnection then ctx.darkTextureConnection:Disconnect() end
        ctx.darkTextureActive = true
        for _, part in pairs(Workspace:GetDescendants()) do
            if isMapPart(part) then
                pcall(function() part.Color = Color3.fromRGB(50,50,50); part.Material = Enum.Material.SmoothPlastic end)
            end
        end
        ctx.darkTextureConnection = Workspace.DescendantAdded:Connect(function(desc)
            if ctx.darkTextureActive and isMapPart(desc) then
                task.wait(0.1)
                pcall(function() desc.Color = Color3.fromRGB(50,50,50); desc.Material = Enum.Material.SmoothPlastic end)
            end
        end)
    end
    ctx.stopDarkTexture = function()
        ctx.darkTextureActive = false
        if ctx.darkTextureConnection then ctx.darkTextureConnection:Disconnect(); ctx.darkTextureConnection = nil end
    end
    ctx.startFPSBoost = function()
        if ctx.fpsBoostConnection then return end
        pcall(function()
            for _, v in pairs(Workspace:GetDescendants()) do
                if v:IsA("Decal") or v:IsA("Texture") then v:Destroy() end
                if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles") then v:Destroy() end
                if v:IsA("PointLight") or v:IsA("SpotLight") or v:IsA("SurfaceLight") then v:Destroy() end
                if v:IsA("BloomEffect") or v:IsA("BlurEffect") or v:IsA("SunRaysEffect") then v:Destroy() end
                if v:IsA("Water") then v.Material = Enum.Material.SmoothPlastic end
            end
            local sky = Workspace:FindFirstChildOfClass("Sky")
            if sky then sky:Destroy() end
            ctx.Lighting.ClockTime = 12
            ctx.Lighting.GlobalShadows = false
            ctx.Lighting.Brightness = 1
            ctx.Lighting.Ambient = Color3.fromRGB(80, 80, 80)
        end)
        ctx.fpsBoostConnection = Workspace.DescendantAdded:Connect(function(desc)
            task.wait(0.1)
            pcall(function()
                if desc:IsA("Decal") or desc:IsA("Texture") then desc:Destroy() end
                if desc:IsA("ParticleEmitter") or desc:IsA("Trail") or desc:IsA("Fire") or desc:IsA("Smoke") or desc:IsA("Sparkles") then desc:Destroy() end
                if desc:IsA("PointLight") or desc:IsA("SpotLight") or desc:IsA("SurfaceLight") then desc:Destroy() end
            end)
        end)
    end
    ctx.stopFPSBoost = function()
        if ctx.fpsBoostConnection then ctx.fpsBoostConnection:Disconnect(); ctx.fpsBoostConnection = nil end
    end
    ctx.startStretchRes = function()
        if ctx.stretchConnection then ctx.stretchConnection:Disconnect() end
        if SETTINGS.ENABLE_STRETCH_RES then
            ctx.stretchConnection = RunService.RenderStepped:Connect(function()
                cam.CFrame = cam.CFrame * CFrame.new(0, 0, 0, 1, 0, 0, 0, SETTINGS.STRETCH_AMOUNT, 0, 0, 0, 1)
            end)
        end
    end
    ctx.stopStretchRes = function()
        if ctx.stretchConnection then ctx.stretchConnection:Disconnect(); ctx.stretchConnection = nil end
    end
    local KILL_REPLACEMENT = 8941612531
    local SHOOT_REPLACEMENT = 5043539486
    local WIN_REPLACEMENT = 140314442804013
    local OTHER_REPLACEMENT = 97859770743369
    local soundReplacements = {
        [16530229616]=KILL_REPLACEMENT,[16530229541]=KILL_REPLACEMENT,[16530229695]=KILL_REPLACEMENT,
        [16537337310]=SHOOT_REPLACEMENT,[16537449730]=SHOOT_REPLACEMENT,
        [16810041280]=WIN_REPLACEMENT,[13110130082]=OTHER_REPLACEMENT
    }
    local function replaceSound(obj)
        for oldId, newId in pairs(soundReplacements) do
            local oldFormatted = "rbxassetid://" .. tostring(oldId)
            if obj.SoundId == oldFormatted or obj.SoundId:find(tostring(oldId)) then
                obj.SoundId = "rbxassetid://" .. tostring(newId); break
            end
        end
    end
    ctx.setupSoundReplacer = function()
        if not SETTINGS.ENABLE_SOUND_REPLACER then return end
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Sound") then replaceSound(obj) end
        end
        game.DescendantAdded:Connect(function(child)
            if child:IsA("Sound") then replaceSound(child) end
        end)
    end
    ctx.setupSkyChanger = function()
        if SETTINGS.ENABLE_SKY_CHANGER then
            pcall(function() loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-Cosmos-sky-60497"))() end)
        else
            for _, v in pairs(ctx.Lighting:GetChildren()) do if v:IsA("Sky") then v:Destroy() end end
        end
    end
    ctx.setupCustomSky1 = function()
        for _, v in pairs(ctx.Lighting:GetChildren()) do if v:IsA("Sky") then v:Destroy() end end
        local s = Instance.new("Sky")
        s.SkyboxBk="rbxassetid://159454299"; s.SkyboxDn="rbxassetid://159454296"
        s.SkyboxFt="rbxassetid://159454293"; s.SkyboxLf="rbxassetid://159454286"
        s.SkyboxRt="rbxassetid://159454288"; s.SkyboxUp="rbxassetid://159454300"
        s.SunAngularSize=0; s.MoonAngularSize=0; s.Name="CustomSky1"; s.Parent=ctx.Lighting
        ctx.Lighting.Ambient=Color3.fromRGB(150,150,150); ctx.Lighting.OutdoorAmbient=Color3.fromRGB(100,100,100)
    end
    ctx.setupCustomSky2 = function()
        for _, v in pairs(ctx.Lighting:GetChildren()) do if v:IsA("Sky") then v:Destroy() end end
        local sky = Instance.new("Sky")
        sky.SkyboxBk="rbxassetid://678556371"; sky.SkyboxDn="rbxassetid://678556361"
        sky.SkyboxFt="rbxassetid://678556368"; sky.SkyboxLf="rbxassetid://678556373"
        sky.SkyboxRt="rbxassetid://678556360"; sky.SkyboxUp="rbxassetid://678556362"
        sky.Name="CustomSky2"; sky.Parent=ctx.Lighting
    end
    local function getTargetPart(character, boneType)
        boneType = boneType or SETTINGS.HITBOX_TARGET
        return character:FindFirstChild(boneType) or character:FindFirstChild("Head")
    end
    ctx.getTargetPart = getTargetPart
    local function getPredictedPosition(targetPart, targetVelocity)
        if not SETTINGS.ENABLE_PREDICTION then return targetPart.Position end
        local currentPos = targetPart.Position
        local distance = (currentPos - cam.CFrame.Position).Magnitude
        local travelTime = distance / 999999
        return currentPos + (targetVelocity * travelTime * SETTINGS.PREDICTION_STRENGTH)
    end
    ctx.getTargetInFOV = function(useSilentBone)
        local center = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/2)
        local bestTarget, bestPos, bestDist = nil, nil, SETTINGS.FOV/2
        local boneToUse = useSilentBone and SETTINGS.SILENT_AIM_BONE or SETTINGS.HITBOX_TARGET
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= lp and plr.Character then
                local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    local targetPart = getTargetPart(plr.Character, boneToUse)
                    if targetPart then
                        local rootPart = plr.Character:FindFirstChild("HumanoidRootPart")
                        local velocity = rootPart and rootPart.AssemblyLinearVelocity or Vector3.new(0,0,0)
                        local aimPos = getPredictedPosition(targetPart, velocity)
                        local screenPos, onScreen = cam:WorldToViewportPoint(aimPos)
                        if onScreen then
                            local rp = RaycastParams.new()
                            rp.FilterType = Enum.RaycastFilterType.Blacklist
                            rp.FilterDescendantsInstances = {lp.Character}
                            local ray = Workspace:Raycast(cam.CFrame.Position, aimPos - cam.CFrame.Position, rp)
                            local visible = not ray or ray.Instance:IsDescendantOf(plr.Character)
                            if visible then
                                local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                                if dist < bestDist then
                                    bestDist = dist; bestTarget = plr; bestPos = aimPos
                                end
                            end
                        end
                    end
                end
            end
        end
        return bestPos, bestTarget
    end
    ctx.startAimbot = function()
        if ctx.aimbotConnection then return end
        ctx.aimbotConnection = RunService:BindToRenderStep("VeytoksProject_Aimbot", Enum.RenderPriority.Camera.Value+1, function()
            if not SETTINGS.ENABLE_AIMBOT then ctx.currentLockTarget = nil; return end
            if ctx.followActive then return end
            if SETTINGS.USE_KEYBIND then
                if not UserInputService:IsKeyDown(Enum.KeyCode[SETTINGS.AIMBOT_KEY]) then
                    ctx.currentLockTarget = nil; return
                end
            end
            if not lp.Character then return end
            local targetPos, targetPlayer = ctx.getTargetInFOV(false)
            if targetPlayer and targetPos then
                ctx.currentLockTarget = targetPlayer
                if SETTINGS.AIMBOT_MODE == "Smooth" then
                    cam.CFrame = cam.CFrame:Lerp(CFrame.new(cam.CFrame.Position, targetPos), SETTINGS.SMOOTHNESS)
                else
                    cam.CFrame = CFrame.new(cam.CFrame.Position, targetPos)
                end
            else
                ctx.currentLockTarget = nil
            end
        end)
    end
    ctx.stopAimbot = function()
        if ctx.aimbotConnection then
            RunService:UnbindFromRenderStep("VeytoksProject_Aimbot")
            ctx.aimbotConnection = nil
        end
        ctx.currentLockTarget = nil
    end
    ctx.setupSilentAim = function()
        for _, module in pairs(ReplicatedStorage:GetDescendants()) do
            if module:IsA("ModuleScript") and module.Name == "Utility" then
                local success, utility = pcall(function() return require(module) end)
                if success and utility and utility.Raycast then
                    ctx.originalRaycast = utility.Raycast
                    utility.Raycast = function(...)
                        local args = {...}
                        if SETTINGS.ENABLE_SILENT_AIM then
                            local targetPos, targetPlayer = ctx.getTargetInFOV(true)
                            if targetPlayer and targetPlayer.Character then
                                local targetPart = getTargetPart(targetPlayer.Character, SETTINGS.SILENT_AIM_BONE)
                                if targetPart and #args >= 4 then args[3] = targetPart.Position end
                            end
                        end
                        return ctx.originalRaycast(table.unpack(args))
                    end
                end
                break
            end
        end
    end
    ctx.StartSkeletonESP = function()
        if ctx.skeletonEspConnection then ctx.skeletonEspConnection:Disconnect() end
        ctx.skeletonEspConnection = RunService.RenderStepped:Connect(function()
            if SETTINGS.ENABLE_SKELETON_ESP then pcall(UpdateSkeletonESP) end
        end)
    end
    ctx.StopSkeletonESP = function()
        if ctx.skeletonEspConnection then ctx.skeletonEspConnection:Disconnect(); ctx.skeletonEspConnection = nil end
        for i, drawing in pairs(SkeletonDrawings) do pcall(function() drawing:Remove() end) end
        SkeletonDrawings = {}
    end
    ctx.StartTracers = function()
        if ctx.tracersConnection then ctx.tracersConnection:Disconnect() end
        ctx.tracersConnection = RunService.RenderStepped:Connect(function()
            if SETTINGS.ENABLE_TRACERS then pcall(UpdateTracers) end
        end)
    end
    ctx.StopTracers = function()
        if ctx.tracersConnection then ctx.tracersConnection:Disconnect(); ctx.tracersConnection = nil end
        for i, drawing in pairs(TracerDrawings) do pcall(function() drawing:Remove() end) end
        TracerDrawings = {}
    end
    ctx.StartHealthWeaponESP = function()
        if ctx.healthWeaponConn then ctx.healthWeaponConn:Disconnect() end
        ctx.healthWeaponConn = RunService.RenderStepped:Connect(function()
            if SETTINGS.ENABLE_HEALTH_ESP or SETTINGS.ENABLE_NAME_ESP or SETTINGS.ENABLE_BOXES_ESP then
                pcall(UpdateHealthWeaponESP)
            end
        end)
    end
    ctx.StopHealthWeaponESP = function()
        if ctx.healthWeaponConn then ctx.healthWeaponConn:Disconnect(); ctx.healthWeaponConn = nil end
        for _, d in pairs(HealthBarDrawings) do pcall(function() d:Remove() end) end
        for _, d in pairs(WeaponTagDrawings) do pcall(function() d:Remove() end) end
        HealthBarDrawings = {}; WeaponTagDrawings = {}
    end
    ctx.StartXRayPersistant = function()
        xrayActive = true
        UpdateAllXRay()
        if ctx.xrayThread then task.cancel(ctx.xrayThread) end
        ctx.xrayThread = task.spawn(function()
            while xrayActive do
                task.wait(0.5)
                if xrayActive then
                    for _, plr in pairs(Players:GetPlayers()) do
                        if plr ~= lp and plr.Character and plr.Character.Parent then
                            local humanoid = plr.Character:FindFirstChild("Humanoid")
                            if humanoid and humanoid.Health > 0 then
                                if not highlights[plr] or highlights[plr].Adornee ~= plr.Character then
                                    ApplyXRayToCharacter(plr.Character, plr)
                                end
                            end
                        end
                    end
                end
            end
        end)
    end
    ctx.StopXRayPersistant = function()
        xrayActive = false
        if ctx.xrayThread then task.cancel(ctx.xrayThread); ctx.xrayThread = nil end
        for _, plr in pairs(Players:GetPlayers()) do
            if highlights[plr] then
                pcall(function() highlights[plr]:Destroy() end)
                highlights[plr] = nil
            end
        end
    end
    task.spawn(function()
        while true do
            if SETTINGS.ENABLE_TRIGGERBOT then
                local targetPos, _ = ctx.getTargetInFOV(false)
                if targetPos then
                    pcall(function()
                        mouse1press(); task.wait(SETTINGS.TRIGGER_DELAY); mouse1release()
                    end)
                end
            end
            task.wait()
        end
    end)
    lp.CharacterAdded:Connect(function(character)
        task.wait(0.5)
        if SETTINGS.ENABLE_FLY then ctx.stopFly(); ctx.startFly() end
    end)
    UserInputService.JumpRequest:Connect(function()
        if SETTINGS.ENABLE_INFJUMP and lp.Character and not SETTINGS.ENABLE_FLY then
            local hum = lp.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum:GetState() ~= Enum.HumanoidStateType.Jumping then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end)
end
local function setupFOVCircle(ctx)
    local SETTINGS = ctx.SETTINGS
    local cam = ctx.cam
    local RunService = ctx.RunService
    local circleGui = Instance.new("ScreenGui", game.CoreGui)
    circleGui.Name = "VeytoksProject_FOVCircle"
    circleGui.ResetOnSpawn = false
    circleGui.IgnoreGuiInset = true
    ctx.circleGui = circleGui
    local circle = Instance.new("Frame", circleGui)
    circle.Size = UDim2.new(0, SETTINGS.FOV, 0, SETTINGS.FOV)
    circle.AnchorPoint = Vector2.new(0.5, 0.5)
    circle.BackgroundTransparency = 1
    circle.Visible = false
    local circleCorner = Instance.new("UICorner", circle)
    circleCorner.CornerRadius = UDim.new(1, 0)
    local circleStroke = Instance.new("UIStroke", circle)
    circleStroke.Thickness = 2
    circleStroke.Color = Color3.fromRGB(160, 80, 255)
    local FOVCircleColor = Color3.fromRGB(160, 80, 255)
    ctx.FOVCircleColor = FOVCircleColor
    local function centerCircle()
        if not circle then return end
        circle.Position = UDim2.new(0.5, 0, 0.5, 0)
    end
    ctx.updateCircleSize = function()
        if circle then circle.Size = UDim2.new(0, SETTINGS.FOV, 0, SETTINGS.FOV) end
    end
    ctx.updateCircleColor = function()
        if circle and circleStroke then circleStroke.Color = ctx.FOVCircleColor end
    end
    ctx.updateCircleVisibility = function()
        if circle then circle.Visible = SETTINGS.ENABLE_FOV_CIRCLE end
    end
    centerCircle()
    cam:GetPropertyChangedSignal("ViewportSize"):Connect(centerCircle)
    RunService.RenderStepped:Connect(centerCircle)
end
local function setupCleanupAll(ctx)
    ctx.cleanupAll = function()
        ctx.stopFollow()
        ctx.stopFly()
        ctx.stopNoclip()
        ctx.stopDarkTexture()
        ctx.stopStretchRes()
        ctx.stopFPSBoost()
        stopTextureColorChanger()
        ctx.StopSkeletonESP()
        ctx.StopTracers()
        ctx.StopHealthWeaponESP()
        ctx.stopAimbot()
        ctx.StopXRayPersistant()
        stopNoRecoil()
        StopRapidFire()
        if __p6q7r8.__s9t0u1 then __p6q7r8.__s9t0u1:Shutdown() end
        StopAntiAim()
        StopSpoof()
        if ctx.circleGui then ctx.circleGui:Destroy() end
    end
end
local function loadMainScript()
    local repo = "https://raw.githubusercontent.com/mstudio45/LinoriaLib/main/"
    local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
    local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
    local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()
    local Lighting = game:GetService("Lighting")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Workspace = game:GetService("Workspace")
    local lp = player
    local cam = workspace.CurrentCamera
    local Options = Library.Options
    local Toggles = Library.Toggles
    Library.ShowToggleFrameInKeybinds = true
    Library.ShowCustomCursor = true
    Library.NotifySide = "Left"
    local Window = Library:CreateWindow({
        Title = "VEYTOKS PROJECT",
        Center = true,
        AutoShow = true,
        Resizable = true,
        ShowCustomCursor = true,
        UnlockMouseWhileOpen = true,
        NotifySide = "Left",
        TabPadding = 8,
        MenuFadeTime = 0.2
    })
    local Tabs = {
        Combat = Window:AddTab("Combat"),
        World = Window:AddTab("World"),
        Visual = Window:AddTab("Visual"),
        Character = Window:AddTab("Character"),
        Misc = Window:AddTab("Misc"),
        ["UI Settings"] = Window:AddTab("UI Settings"),
        Rage = Window:AddTab("Rage"),
    }
    SETTINGS = {
        ENABLE_AIMBOT = false, AIMBOT_MODE = "Smooth", SMOOTHNESS = 0.3,
        USE_KEYBIND = false, AIMBOT_KEY = "E", ENABLE_SILENT_AIM = false,
        ENABLE_TRIGGERBOT = false, ENABLE_PREDICTION = false, FOV = 120,
        ENABLE_FOV_CIRCLE = true, PREDICTION_STRENGTH = 1, TRIGGER_DELAY = 0.05,
        HITBOX_TARGET = "Head", ENABLE_XRAY = false, ENABLE_TRACERS = false,
        ENABLE_SKELETON_ESP = false, ENABLE_HEALTH_ESP = false, ENABLE_NAME_ESP = false,
        ENABLE_BOXES_ESP = false, AUTO_GRAB_DROPS = false, ENABLE_DARK_TEXTURE = false,
        ENABLE_INFJUMP = false, ENABLE_FLY = false, ENABLE_NOCLIP = false,
        FLY_SPEED = 70, FOLLOW_HEIGHT = 18, ENABLE_UNLOCK_ALL = false,
        ENABLE_ANTI_MOD = false, ENABLE_SKY_CHANGER = false, ENABLE_CUSTOM_SKY_1 = false,
        ENABLE_CUSTOM_SKY_2 = false, ENABLE_STRETCH_RES = false, STRETCH_AMOUNT = 0.81,
        ENABLE_SOUND_REPLACER = false, ENABLE_FPS_BOOST = false, ENABLE_TEXTURE_COLOR = false,
        AUTO_RETARGET = true, RETARGET_DELAY = 1, SILENT_AIM_BONE = "Head",
        ENABLE_NO_RECOIL = false, ENABLE_RAPID_FIRE = false, ENABLE_WALLBANG = false,
        WALLBANG_HIT = "Head", ENABLE_ANTIAIM = false, ANTIAIM_SPEED = 5,
        ENABLE_SPOOF = false, SPOOF_DEVICE = "Touch",
    }
    local ctx = {
        Library = Library, Lighting = Lighting, ReplicatedStorage = ReplicatedStorage,
        Workspace = Workspace, lp = lp, cam = cam, SETTINGS = SETTINGS,
        Tabs = Tabs, Options = Options, Toggles = Toggles,
        Players = Players, RunService = RunService, UserInputService = UserInputService,
        flyEnabled = false, flySpeed = 70, bodyVelocity = nil, bodyGyro = nil, flyThread = nil,
        noclipActive = false, noclipConnection = nil,
        followActive = false, followTarget = nil, followConnection = nil,
        darkTextureActive = false, darkTextureConnection = nil,
        originalRaycast = nil, stretchConnection = nil, fpsBoostConnection = nil,
        skeletonEspConnection = nil, tracersConnection = nil,
        aimbotConnection = nil, currentLockTarget = nil,
        healthWeaponConn = nil, xrayThread = nil,
        unlockAllExecuted = false,
    }
    local HITBOX_PARTS = {"Head", "UpperTorso", "LowerTorso", "HumanoidRootPart"}
    local SILENT_AIM_BONES = {"Head", "UpperTorso", "LowerTorso", "HumanoidRootPart", "LeftArm", "RightArm", "LeftLeg", "RightLeg"}
    local RAGEBOT_MODES = {"Forward", "Up", "Down", "Behind", "Fling"}
    local DEVICE_TYPES = {"Touch", "MouseKeyboard", "Gamepad", "VR"}
    setupGameplayFunctions(ctx)
    setupFOVCircle(ctx)
    setupCleanupAll(ctx)
    local startFly = ctx.startFly
    local stopFly = ctx.stopFly
    local startNoclip = ctx.startNoclip
    local stopNoclip = ctx.stopNoclip
    local startFollow = ctx.startFollow
    local stopFollow = ctx.stopFollow
    local startDarkTexture = ctx.startDarkTexture
    local stopDarkTexture = ctx.stopDarkTexture
    local startFPSBoost = ctx.startFPSBoost
    local stopFPSBoost = ctx.stopFPSBoost
    local startStretchRes = ctx.startStretchRes
    local stopStretchRes = ctx.stopStretchRes
    local setupSoundReplacer = ctx.setupSoundReplacer
    local setupSkyChanger = ctx.setupSkyChanger
    local setupCustomSky1 = ctx.setupCustomSky1
    local setupCustomSky2 = ctx.setupCustomSky2
    local startAimbot = ctx.startAimbot
    local stopAimbot = ctx.stopAimbot
    local setupSilentAim = ctx.setupSilentAim
    local StartSkeletonESP = ctx.StartSkeletonESP
    local StopSkeletonESP = ctx.StopSkeletonESP
    local StartTracers = ctx.StartTracers
    local StopTracers = ctx.StopTracers
    local StartHealthWeaponESP = ctx.StartHealthWeaponESP
    local StopHealthWeaponESP = ctx.StopHealthWeaponESP
    local StartXRayPersistant = ctx.StartXRayPersistant
    local StopXRayPersistant = ctx.StopXRayPersistant
    local updateCircleSize = ctx.updateCircleSize
    local updateCircleColor = ctx.updateCircleColor
    local updateCircleVisibility = ctx.updateCircleVisibility
    local cleanupAll = ctx.cleanupAll
    local FOVCircleColor = ctx.FOVCircleColor
    local circleGui = ctx.circleGui
    local followActive = false
    local unlockAllExecuted = false
    local CombatGroup = Tabs.Combat:AddLeftGroupbox("Aimbot")
    local CombatGroup2 = Tabs.Combat:AddRightGroupbox("World")
    local CombatGroup3 = Tabs.Combat:AddLeftGroupbox("Silent Aim Settings")
    local CombatGroup4 = Tabs.Combat:AddRightGroupbox("Rapid Fire & No Recoil")
    local CombatGroup5 = Tabs.Combat:AddLeftGroupbox("Wallbang & AntiAim")
    local CombatGroup6 = Tabs.Combat:AddRightGroupbox("Device Spoofer")
    local CombatGroup7 = Tabs.Combat:AddLeftGroupbox("Knife Settings")
    local backstabEnabled = false
    local backstabRange = 30
    CombatGroup7:AddToggle("ALWAYS_BACKSTAB", {
        Text = "Always Backstab",
        Default = false,
        Callback = function(Value)
            backstabEnabled = Value
            if Value then
                pcall(function()
                    local knife = require(player.PlayerScripts.Modules.ItemTypes.Knife)
                        or require(player.PlayerScripts.Modules.ItemTypes.Melee)
                    if not knife then return end
                    for _, fname in ipairs({"IsBackstab", "CheckBackstab", "GetHitType", "CanBackstab"}) do
                        if rawget(knife, fname) and type(knife[fname]) == "function" then
                            local old = knife[fname]
                            knife[fname] = function(...)
                                if backstabEnabled then return true end
                                return old(...)
                            end
                            break
                        end
                    end
                end)
                pcall(function()
                    for _, v in ipairs(getgc(true)) do
                        if type(v) == "table" then
                            if rawget(v, "IsBackstab") and type(v.IsBackstab) == "function" then
                                local old = v.IsBackstab
                                v.IsBackstab = function(...)
                                    if backstabEnabled then return true end
                                    return old(...)
                                end
                            end
                            if rawget(v, "CheckBackstab") and type(v.CheckBackstab) == "function" then
                                local old = v.CheckBackstab
                                v.CheckBackstab = function(...)
                                    if backstabEnabled then return true end
                                    return old(...)
                                end
                            end
                            if rawget(v, "StartShooting") and rawget(v, "IsKnife") then
                                local old = v.StartShooting
                                v.StartShooting = function(self2, ...)
                                    local results = {old(self2, ...)}
                                    if backstabEnabled and results[3] and type(results[3]) == "table" then
                                        results[3].IsBackstab = true
                                        results[3].Backstab = true
                                    end
                                    return unpack(results)
                                end
                            end
                        end
                    end
                end)
                task.spawn(function()
                    while backstabEnabled do
                        pcall(function()
                            local char = player.Character
                            if not char then return end
                            local hrp = char:FindFirstChild("HumanoidRootPart")
                            if not hrp then return end
                            local tool = char:FindFirstChildOfClass("Tool")
                            if not tool then return end
                            local n = tool.Name:lower()
                            if not (n:find("knife") or n:find("dagger") or n:find("blade") or n:find("melee") or n:find("sword") or n:find("axe") or n:find("bat")) then return end
                            local closest, closestDist = nil, backstabRange
                            for _, p in ipairs(Players:GetPlayers()) do
                                if p == player then continue end
                                if not isAlive(p) then continue end
                                local tHrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
                                if not tHrp then continue end
                                local d = (tHrp.Position - hrp.Position).Magnitude
                                if d < closestDist then
                                    closestDist = d
                                    closest = tHrp
                                end
                            end
                            if closest then
                                local backPos = closest.Position + closest.CFrame.LookVector * -2.5
                                hrp.CFrame = CFrame.new(backPos, closest.Position)
                                    * CFrame.new(0, 0, -1)
                            end
                        end)
                        task.wait(0.05)
                    end
                end)
            else
            end
        end
    })
    CombatGroup7:AddSlider("BACKSTAB_RANGE", {
        Text = "Backstab Range",
        Default = 30, Min = 5, Max = 200, Rounding = 0,
        Suffix = " studs",
        Callback = function(Value)
            backstabRange = Value
        end
    })
    CombatGroup:AddToggle("ENABLE_AIMBOT", {
        Text = "Aimbot",
        Default = false,
        Callback = function(Value)
            SETTINGS.ENABLE_AIMBOT = Value
            updateCircleVisibility()
            if Value then startAimbot() else stopAimbot() end
        end
    }):AddKeyPicker("AIMBOT_KEY_PICKER", {
        Default = "MB2",
        Mode = "Hold",
        Text = "Aimbot Key",
        Callback = function(Value) end
    })
    CombatGroup:AddToggle("COMBAT_VISIBLE_ONLY", {
        Text = "Visible Only",
        Default = true,
        Callback = function(Value)
            SETTINGS.VISIBLE_ONLY = Value
        end
    })
    CombatGroup:AddToggle("ENABLE_NO_SPREAD_COMBAT", {
        Text = "No Spread",
        Default = false,
        Callback = function(Value)
            if Value then StartRapidFire() else StopRapidFire() end
        end
    })
    CombatGroup:AddDropdown("AIMBOT_MODE", {
        Text = "Aimbot Mode",
        Values = {"Smooth", "Instalock"},
        Default = "Smooth",
        Callback = function(Value)
            SETTINGS.AIMBOT_MODE = Value
        end
    })
    CombatGroup:AddSlider("SMOOTHNESS", {
        Text = "Smoothness",
        Default = 30,
        Min = 5,
        Max = 80,
        Rounding = 0,
        Suffix = "%",
        Callback = function(Value)
            SETTINGS.SMOOTHNESS = Value / 100
        end
    })
    CombatGroup:AddToggle("ENABLE_FOV_CIRCLE", {
        Text = "Afficher FOV",
        Default = SETTINGS.ENABLE_FOV_CIRCLE,
        Callback = function(Value)
            SETTINGS.ENABLE_FOV_CIRCLE = Value
            updateCircleVisibility()
        end
    })
    CombatGroup:AddSlider("FOV", {
        Text = "FOV",
        Default = SETTINGS.FOV,
        Min = 10,
        Max = 800,
        Rounding = 0,
        Suffix = "px",
        Callback = function(Value)
            SETTINGS.FOV = Value
            updateCircleSize()
        end
    })
    CombatGroup3:AddToggle("ENABLE_SILENT_AIM", {
        Text = "Silent Aim",
        Default = false,
        Callback = function(Value)
            SETTINGS.ENABLE_SILENT_AIM = Value
            updateCircleVisibility()
            if Value then task.spawn(setupSilentAim) end
        end
    })
    CombatGroup3:AddSlider("SILENT_AIM_RADIUS", {
        Text = "Rayon",
        Min = 0,
        Max = 500,
        Default = 100,
        Rounding = 0,
        Suffix = "px",
        Callback = function(Value)
            SETTINGS.FOV = Value
        end
    })
    CombatGroup3:AddSlider("SILENT_AIM_HITCHANCE", {
        Text = "Hit Chance",
        Min = 0,
        Max = 100,
        Default = 100,
        Rounding = 0,
        Suffix = "%",
        Callback = function(Value)
            SETTINGS.SILENT_HITCHANCE = Value
        end
    })
    CombatGroup3:AddDropdown("SILENT_AIM_BONE", {
        Text = "Bone",
        Values = SILENT_AIM_BONES,
        Default = "Head",
        Callback = function(Value)
            SETTINGS.SILENT_AIM_BONE = Value
        end
    })
    CombatGroup:AddToggle("ENABLE_TRIGGERBOT", {
        Text = "Triggerbot",
        Default = SETTINGS.ENABLE_TRIGGERBOT,
        Callback = function(Value)
            SETTINGS.ENABLE_TRIGGERBOT = Value
        end
    })
    CombatGroup:AddToggle("ENABLE_PREDICTION", {
        Text = "Prediction",
        Default = SETTINGS.ENABLE_PREDICTION,
        Callback = function(Value)
            SETTINGS.ENABLE_PREDICTION = Value
        end
    })
    CombatGroup:AddSlider("TRIGGER_DELAY", {
        Text = "Triggerbot Delay",
        Default = SETTINGS.TRIGGER_DELAY,
        Min = 0.01,
        Max = 0.5,
        Rounding = 2,
        Suffix = "s",
        Callback = function(Value)
            SETTINGS.TRIGGER_DELAY = Value
        end
    })
    CombatGroup:AddSlider("PREDICTION_STRENGTH", {
        Text = "Prediction Strength",
        Default = SETTINGS.PREDICTION_STRENGTH,
        Min = 0.5,
        Max = 2,
        Rounding = 1,
        Suffix = "x",
        Callback = function(Value)
            SETTINGS.PREDICTION_STRENGTH = Value
        end
    })
    CombatGroup:AddDropdown("HITBOX_TARGET", {
        Text = "Hitbox",
        Values = HITBOX_PARTS,
        Default = "Head",
        Callback = function(Value)
            SETTINGS.HITBOX_TARGET = Value
        end
    })
    CombatGroup2:AddToggle("ENABLE_INFJUMP", {
        Text = "Infinite Jump",
        Default = SETTINGS.ENABLE_INFJUMP,
        Callback = function(Value)
            SETTINGS.ENABLE_INFJUMP = Value
        end
    })
    CombatGroup2:AddToggle("ENABLE_FLY", {
        Text = "Fly Mode",
        Default = SETTINGS.ENABLE_FLY,
        Callback = function(Value)
            SETTINGS.ENABLE_FLY = Value
            if Value then startFly() else stopFly() end
        end
    })
    CombatGroup2:AddSlider("FLY_SPEED", {
        Text = "Fly Speed",
        Default = SETTINGS.FLY_SPEED,
        Min = 20,
        Max = 200,
        Rounding = 0,
        Suffix = "studs/s",
        Callback = function(Value)
            SETTINGS.FLY_SPEED = Value
            flySpeed = Value
        end
    })
    CombatGroup2:AddToggle("ENABLE_NOCLIP", {
        Text = "Noclip",
        Default = SETTINGS.ENABLE_NOCLIP,
        Callback = function(Value)
            SETTINGS.ENABLE_NOCLIP = Value
            if Value and not followActive then startNoclip() else stopNoclip() end
        end
    })
    CombatGroup4:AddToggle("ENABLE_RAPID_FIRE", {
        Text = "Rapid Fire",
        Default = SETTINGS.ENABLE_RAPID_FIRE,
        Callback = function(Value)
            SETTINGS.ENABLE_RAPID_FIRE = Value
            if Value then StartRapidFire() else StopRapidFire() end
        end
    })
    CombatGroup4:AddToggle("ENABLE_NO_RECOIL", {
        Text = "No Recoil",
        Default = SETTINGS.ENABLE_NO_RECOIL,
        Callback = function(Value)
            SETTINGS.ENABLE_NO_RECOIL = Value
            if Value then startNoRecoil() else stopNoRecoil() end
        end
    })
    CombatGroup5:AddToggle("ENABLE_ANTIAIM", {
        Text = "AntiAim",
        Default = SETTINGS.ENABLE_ANTIAIM,
        Callback = function(Value)
            SETTINGS.ENABLE_ANTIAIM = Value
            if Value then StartAntiAim() else StopAntiAim() end
        end
    })
    CombatGroup5:AddSlider("ANTIAIM_SPEED", {
        Text = "AntiAim Speed",
        Default = SETTINGS.ANTIAIM_SPEED,
        Min = 1,
        Max = 20,
        Rounding = 1,
        Callback = function(Value)
            SETTINGS.ANTIAIM_SPEED = Value
            AA.Speed = Value
        end
    })
    CombatGroup6:AddToggle("ENABLE_SPOOF", {
        Text = "Device Spoofer",
        Default = SETTINGS.ENABLE_SPOOF,
        Callback = function(Value)
            SETTINGS.ENABLE_SPOOF = Value
            D.On = Value
            if Value then StartSpoof() else StopSpoof() end
        end
    })
    CombatGroup6:AddDropdown("SPOOF_DEVICE", {
        Text = "Device Type",
        Values = DEVICE_TYPES,
        Default = "Touch",
        Callback = function(Value)
            SETTINGS.SPOOF_DEVICE = Value
            D.Device = Value
        end
    })
    local CharGroup = Tabs.Character:AddLeftGroupbox("Animation Player")
    local CharGroup3 = Tabs.Character:AddLeftGroupbox("Movement")
    local velocityEnabled = false
    local velocitySpeed = 45
    local velocityConn = nil
    CharGroup3:AddToggle("CHAR_VELOCITY", {
        Text = "Velocity",
        Default = false,
        Keybind = "G",
        Callback = function(Value)
            velocityEnabled = Value
            if Value then
                if velocityConn then velocityConn:Disconnect() end
                velocityConn = RunService.Heartbeat:Connect(function()
                    if not velocityEnabled then return end
                    local char = player.Character
                    if not char then return end
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if not hum then return end
                    local moveDir = hum.MoveDirection
                    if moveDir.Magnitude > 0 then
                        hrp.AssemblyLinearVelocity = moveDir * velocitySpeed
                    end
                end)
            else
                if velocityConn then velocityConn:Disconnect(); velocityConn = nil end
            end
        end
    })
    CharGroup3:AddSlider("CHAR_VELOCITY_SPEED", {
        Text = "Velocity Speed",
        Default = 45, Min = 1, Max = 200, Rounding = 0,
        Suffix = "s",
        Callback = function(Value)
            velocitySpeed = Value
        end
    })
    local slideBoostEnabled = false
    local slideBoostSpeed = 45
    local slideBoostConn = nil
    CharGroup3:AddToggle("CHAR_SLIDE_BOOST", {
        Text = "Slide Boost",
        Default = false,
        Callback = function(Value)
            slideBoostEnabled = Value
            if Value then
                if slideBoostConn then slideBoostConn:Disconnect() end
                slideBoostConn = RunService.Heartbeat:Connect(function()
                    if not slideBoostEnabled then return end
                    local char = player.Character
                    if not char then return end
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if not hrp or not hum then return end
                    local isSliding = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
                        or UserInputService:IsKeyDown(Enum.KeyCode.ButtonR3)
                    if isSliding then
                        local moveDir = hum.MoveDirection
                        if moveDir.Magnitude > 0 then
                            hrp.AssemblyLinearVelocity = moveDir * slideBoostSpeed
                        else
                            hrp.AssemblyLinearVelocity = hrp.CFrame.LookVector * slideBoostSpeed
                        end
                    end
                end)
            else
                if slideBoostConn then slideBoostConn:Disconnect(); slideBoostConn = nil end
            end
        end
    })
    CharGroup3:AddSlider("CHAR_SLIDE_BOOST_SPEED", {
        Text = "Slide Boost Speed",
        Default = 45, Min = 1, Max = 200, Rounding = 0,
        Suffix = "s",
        Callback = function(Value)
            slideBoostSpeed = Value
        end
    })
    local CharGroup2 = Tabs.Character:AddRightGroupbox("Character Settings")
    local CharGroupVM = Tabs.Character:AddRightGroupbox("Viewmodels")
    local animEnabled = false
    local animTrack = nil
    local currentAnimId = ""
    local animSpeed = 1
    local animStart = 0
    local animEnd = 1
    local presetAnimations = {
        ["crawling in a circle"] = "rbxassetid://4049646104",
        ["dance"] = "rbxassetid://507771019",
        ["laugh"] = "rbxassetid://507770818",
        ["point"] = "rbxassetid://507770453",
        ["wave"] = "rbxassetid://507770239",
        ["cheer"] = "rbxassetid://507770677",
        ["sit"] = "rbxassetid://2506281703",
        ["sleep"] = "rbxassetid://6576285862",
        ["idle"] = "rbxassetid://180435571",
        ["run"] = "rbxassetid://180426354",
        ["walk"] = "rbxassetid://180426354",
        ["swim"] = "rbxassetid://180435417",
        ["fall"] = "rbxassetid://180436148",
        ["jump"] = "rbxassetid://125750702",
    }
    local presetNames = {}
    for k in pairs(presetAnimations) do table.insert(presetNames, k) end
    table.sort(presetNames)
    local selectedPreset = presetNames[1]
    local customAnimId = ""
    local function stopAnim()
        if animTrack then
            pcall(function() animTrack:Stop(0) end)
            animTrack = nil
        end
    end
    local function playAnim(id)
        stopAnim()
        task.spawn(function()
            task.wait(0.1)
            local char = player.Character
            if not char then return end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if not hum then return end
            local animator = hum:FindFirstChildOfClass("Animator")
            if not animator then animator = hum:WaitForChild("Animator", 5) end
            if not animator then return end
            local anim = Instance.new("Animation")
            anim.AnimationId = id
            local ok, track = pcall(function() return animator:LoadAnimation(anim) end)
            anim:Destroy()
            if not ok or not track then return end
            animTrack = track
            track.Looped = true
            track:Play()
            track:AdjustSpeed(animSpeed)
        end)
    end
    local function getAnimId()
        if customAnimId ~= "" then return customAnimId end
        return presetAnimations[selectedPreset] or presetAnimations[presetNames[1]]
    end
    CharGroup:AddToggle("ANIM_ENABLED", {
        Text = "Enabled",
        Default = false,
        Callback = function(Value)
            animEnabled = Value
            if Value then
                playAnim(getAnimId())
            else
                stopAnim()
            end
        end
    })
    CharGroup:AddDropdown("ANIM_PRESET", {
        Text = "Animation",
        Values = presetNames,
        Default = presetNames[1],
        Callback = function(Value)
            selectedPreset = Value
            if animEnabled then
                playAnim(getAnimId())
            end
        end
    })
    CharGroup:AddInput("ANIM_CUSTOM_ID", {
        Text = "Custom Animation",
        Default = "",
        Placeholder = "id... (ex: 4049646104)",
        Callback = function(Value)
            if Value ~= "" then
                customAnimId = "rbxassetid://" .. Value:gsub("rbxassetid://", "")
            else
                customAnimId = ""
            end
            if animEnabled then
                playAnim(getAnimId())
            end
        end
    })
    CharGroup:AddSlider("ANIM_SPEED", {
        Text = "Speed",
        Default = 10, Min = 1, Max = 50, Rounding = 0,
        Callback = function(Value)
            animSpeed = Value / 10
            if animTrack then
                pcall(function() animTrack:AdjustSpeed(animSpeed) end)
            end
        end
    })
    CharGroup:AddSlider("ANIM_START", {
        Text = "Start %",
        Default = 0, Min = 0, Max = 100, Rounding = 0,
        Suffix = "%",
        Callback = function(Value)
            animStart = Value / 100
        end
    })
    CharGroup:AddSlider("ANIM_END", {
        Text = "End %",
        Default = 100, Min = 0, Max = 100, Rounding = 0,
        Suffix = "%",
        Callback = function(Value)
            animEnd = Value / 100
        end
    })
    CharGroup2:AddToggle("CHAR_INVISIBLE", {
        Text = "Invisible",
        Default = false,
        Callback = function(Value)
            local char = player.Character
            if not char then return end
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    part.Transparency = Value and 1 or 0
                end
                if part:IsA("Decal") then
                    part.Transparency = Value and 1 or 0
                end
            end
        end
    })
    CharGroup2:AddToggle("CHAR_BIG_HEAD", {
        Text = "Big Head",
        Default = false,
        Callback = function(Value)
            local char = player.Character
            if not char then return end
            local head = char:FindFirstChild("Head")
            if head then
                head.Size = Value and Vector3.new(4, 4, 4) or Vector3.new(2, 1, 1)
            end
        end
    })
    player.CharacterAdded:Connect(function()
        task.wait(1)
        if animEnabled then
            playAnim(getAnimId())
        end
    end)
    local vmEnabled = true
    local vmTransparency = 0
    local vmSize = 1
    local vmOffset = Vector3.new(0, 0, 0)
    local function applyViewmodelSettings()
        pcall(function()
            local viewmodels = player.PlayerScripts:FindFirstChild("Assets")
                and player.PlayerScripts.Assets:FindFirstChild("ViewModels")
            if not viewmodels then return end
            for _, vm in ipairs(viewmodels:GetDescendants()) do
                if vm:IsA("BasePart") then
                    vm.LocalTransparencyModifier = vmEnabled and vmTransparency or 1
                end
                if vm:IsA("MeshPart") or vm:IsA("SpecialMesh") then
                    if vm:IsA("SpecialMesh") then
                        vm.Scale = Vector3.new(vmSize, vmSize, vmSize)
                    end
                end
            end
        end)
    end
    CharGroupVM:AddToggle("VM_ENABLED", {
        Text = "Show Viewmodel",
        Default = false,
        Callback = function(Value)
            vmEnabled = Value
            applyViewmodelSettings()
        end
    })
    CharGroupVM:AddSlider("VM_TRANSPARENCY", {
        Text = "Transparency",
        Default = 0, Min = 0, Max = 10, Rounding = 0,
        Suffix = "",
        Callback = function(Value)
            vmTransparency = Value / 10
            applyViewmodelSettings()
        end
    })
    CharGroupVM:AddSlider("VM_SIZE", {
        Text = "Size",
        Default = 10, Min = 1, Max = 30, Rounding = 0,
        Callback = function(Value)
            vmSize = Value / 10
            applyViewmodelSettings()
        end
    })
    CharGroupVM:AddSlider("VM_OFFSET_X", {
        Text = "Offset X",
        Default = 0, Min = -50, Max = 50, Rounding = 0,
        Callback = function(Value)
            vmOffset = Vector3.new(Value / 10, vmOffset.Y, vmOffset.Z)
            pcall(function()
                workspace.CurrentCamera.CFrame = workspace.CurrentCamera.CFrame * CFrame.new(vmOffset)
            end)
        end
    })
    CharGroupVM:AddSlider("VM_OFFSET_Y", {
        Text = "Offset Y",
        Default = 0, Min = -50, Max = 50, Rounding = 0,
        Callback = function(Value)
            vmOffset = Vector3.new(vmOffset.X, Value / 10, vmOffset.Z)
        end
    })
    CharGroupVM:AddSlider("VM_OFFSET_Z", {
        Text = "Offset Z (FOV Feel)",
        Default = 0, Min = -50, Max = 50, Rounding = 0,
        Callback = function(Value)
            vmOffset = Vector3.new(vmOffset.X, vmOffset.Y, Value / 10)
        end
    })
    RunService.RenderStepped:Connect(function()
        if not vmEnabled then return end
        pcall(function()
            local viewmodels = player.PlayerScripts.Assets.ViewModels
            for _, vm in ipairs(viewmodels:GetDescendants()) do
                if vm:IsA("BasePart") then
                    vm.LocalTransparencyModifier = vmTransparency
                end
            end
        end)
    end)
    local Lighting = game:GetService("Lighting")
    local WorldLeft  = Tabs.World:AddLeftGroupbox("Color Correction")
    local WorldRight = Tabs.World:AddRightGroupbox("Atmosphere")
    local WorldRight2 = Tabs.World:AddRightGroupbox("Lighting")
    local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
    local ccEnabled = cc ~= nil
    local function getCC()
        if not cc or not cc.Parent then
            cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
            if not cc then
                cc = Instance.new("ColorCorrectionEffect")
                cc.Parent = Lighting
            end
        end
        return cc
    end
    WorldLeft:AddToggle("CC_ENABLED", {
        Text = "Enabled",
        Default = false,
        Callback = function(Value)
            ccEnabled = Value
            local c = getCC()
            c.Enabled = Value
        end
    })
    WorldLeft:AddSlider("CC_SATURATION", {
        Text = "Saturation",
        Default = 10, Min = -100, Max = 100, Rounding = 0,
        Callback = function(Value)
            getCC().Saturation = Value / 10
        end
    })
    WorldLeft:AddSlider("CC_CONTRAST", {
        Text = "Contrast",
        Default = -5, Min = -100, Max = 100, Rounding = 0,
        Callback = function(Value)
            getCC().Contrast = Value / 10
        end
    })
    WorldLeft:AddSlider("CC_BRIGHTNESS", {
        Text = "Brightness",
        Default = -1, Min = -100, Max = 100, Rounding = 0,
        Callback = function(Value)
            getCC().Brightness = Value / 100
        end
    })
    local atmoEnabled = false
    local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
    local function getAtmo()
        if not atmo or not atmo.Parent then
            atmo = Lighting:FindFirstChildOfClass("Atmosphere")
            if not atmo then
                atmo = Instance.new("Atmosphere")
                atmo.Parent = Lighting
            end
        end
        return atmo
    end
    WorldRight:AddToggle("ATMO_ENABLED", {
        Text = "Enabled",
        Default = false,
        Callback = function(Value)
            atmoEnabled = Value
            local a = getAtmo()
            if not Value then
                a.Density = 0
                a.Haze = 0
                a.Glare = 0
                a.Offset = 0
            end
        end
    })
    WorldRight:AddLabel("Color"):AddColorPicker("ATMO_COLOR", {
        Default = Color3.fromRGB(255, 255, 255),
        Callback = function(Value)
            getAtmo().Color = Value
        end
    })
    WorldRight:AddLabel("Decay"):AddColorPicker("ATMO_DECAY", {
        Default = Color3.fromRGB(255, 255, 255),
        Callback = function(Value)
            getAtmo().Decay = Value
        end
    })
    WorldRight:AddSlider("ATMO_GLARE", {
        Text = "Glare",
        Default = 25, Min = 0, Max = 100, Rounding = 0,
        Callback = function(Value)
            getAtmo().Glare = Value / 10
        end
    })
    WorldRight:AddSlider("ATMO_HAZE", {
        Text = "Haze",
        Default = 10, Min = 0, Max = 100, Rounding = 0,
        Callback = function(Value)
            getAtmo().Haze = Value
        end
    })
    WorldRight:AddSlider("ATMO_OFFSET", {
        Text = "Offset",
        Default = 37, Min = 0, Max = 100, Rounding = 0,
        Callback = function(Value)
            getAtmo().Offset = Value / 100
        end
    })
    WorldRight:AddSlider("ATMO_DENSITY", {
        Text = "Density",
        Default = 49, Min = 0, Max = 100, Rounding = 0,
        Callback = function(Value)
            getAtmo().Density = Value / 100
        end
    })
    WorldRight2:AddToggle("L_AMBIENT", {
        Text = "Ambient",
        Default = false,
        Callback = function(Value)
            if not Value then Lighting.Ambient = Color3.fromRGB(70, 70, 70) end
        end
    })
    WorldRight2:AddLabel("Ambient Color"):AddColorPicker("L_AMBIENT_COLOR", {
        Default = Color3.fromRGB(255, 255, 255),
        Callback = function(Value)
            Lighting.Ambient = Value
        end
    })
    WorldRight2:AddToggle("L_COLORSHIFT_BOT", {
        Text = "ColorShift_Bottom",
        Default = false,
        Callback = function(Value)
            if not Value then Lighting.ColorShift_Bottom = Color3.fromRGB(0, 0, 0) end
        end
    })
    WorldRight2:AddLabel("ColorShift_Bottom"):AddColorPicker("L_CSB_COLOR", {
        Default = Color3.fromRGB(255, 255, 255),
        Callback = function(Value)
            Lighting.ColorShift_Bottom = Value
        end
    })
    WorldRight2:AddToggle("L_COLORSHIFT_TOP", {
        Text = "ColorShift_Top",
        Default = false,
        Callback = function(Value)
            if not Value then Lighting.ColorShift_Top = Color3.fromRGB(0, 0, 0) end
        end
    })
    WorldRight2:AddLabel("ColorShift_Top"):AddColorPicker("L_CST_COLOR", {
        Default = Color3.fromRGB(255, 255, 255),
        Callback = function(Value)
            Lighting.ColorShift_Top = Value
        end
    })
    WorldRight2:AddToggle("L_FOGCOLOR", {
        Text = "FogColor",
        Default = false,
        Callback = function(Value)
            if not Value then Lighting.FogColor = Color3.fromRGB(192, 192, 192) end
        end
    })
    WorldRight2:AddLabel("Fog Color"):AddColorPicker("L_FOG_COLOR", {
        Default = Color3.fromRGB(200, 200, 200),
        Callback = function(Value)
            Lighting.FogColor = Value
        end
    })
    WorldRight2:AddToggle("L_FOGEND", {
        Text = "FogEnd",
        Default = false,
        Callback = function(Value)
            if not Value then Lighting.FogEnd = 100000 end
        end
    })
    WorldRight2:AddSlider("L_FOGEND_VAL", {
        Text = "FogEnd",
        Default = 2510, Min = 0, Max = 10000, Rounding = 0,
        Suffix = "studs",
        Callback = function(Value)
            Lighting.FogEnd = Value
        end
    })
    WorldRight2:AddToggle("L_FOGSTART", {
        Text = "FogStart",
        Default = false,
        Callback = function(Value)
            if not Value then Lighting.FogStart = 0 end
        end
    })
    WorldRight2:AddSlider("L_FOGSTART_VAL", {
        Text = "FogStart",
        Default = 0, Min = 0, Max = 5000, Rounding = 0,
        Suffix = "studs",
        Callback = function(Value)
            Lighting.FogStart = Value
        end
    })
    WorldRight2:AddToggle("L_EXPOSURE", {
        Text = "ExposureCompensation",
        Default = false,
        Callback = function(Value)
            if not Value then Lighting.ExposureCompensation = 0 end
        end
    })
    WorldRight2:AddSlider("L_EXPOSURE_VAL", {
        Text = "ExposureCompensation",
        Default = -11, Min = -100, Max = 100, Rounding = 0,
        Callback = function(Value)
            Lighting.ExposureCompensation = Value / 10
        end
    })
    WorldRight2:AddToggle("L_BRIGHTNESS", {
        Text = "Brightness",
        Default = false,
        Callback = function(Value)
            if not Value then Lighting.Brightness = 2 end
        end
    })
    WorldRight2:AddSlider("L_BRIGHTNESS_VAL", {
        Text = "Brightness",
        Default = 17, Min = 0, Max = 50, Rounding = 0,
        Callback = function(Value)
            Lighting.Brightness = Value / 10
        end
    })
    WorldRight2:AddToggle("L_CLOCKTIME", {
        Text = "ClockTime",
        Default = false,
        Callback = function(Value)
            if not Value then Lighting.ClockTime = 14 end
        end
    })
    WorldRight2:AddSlider("L_CLOCKTIME_VAL", {
        Text = "ClockTime",
        Default = 114, Min = 0, Max = 240, Rounding = 0,
        Suffix = "h",
        Callback = function(Value)
            Lighting.ClockTime = Value / 10
        end
    })
    WorldRight2:AddToggle("L_GLOBALSHADOWS", {
        Text = "GlobalShadows",
        Default = false,
        Callback = function(Value)
            Lighting.GlobalShadows = Value
        end
    })
    WorldRight2:AddDropdown("L_TECHNOLOGY", {
        Text = "Technology",
        Values = {"Compatibility", "Voxel", "ShadowMap", "Future"},
        Default = "ShadowMap",
        Callback = function(Value)
            Lighting.Technology = Enum.Technology[Value]
        end
    })
    local VisualGroup = Tabs.Visual:AddLeftGroupbox("ESP and Vision")
    local VisualGroup2 = Tabs.Visual:AddRightGroupbox("Effects")
    local VisualGroup3 = Tabs.Visual:AddLeftGroupbox("Sky & Visuals")
    local VisualGroup4 = Tabs.Visual:AddRightGroupbox("Unlock")
    local HitSoundGroup = Tabs.Visual:AddRightGroupbox("Hit Sounds")
    local hitSoundEnabled = false
    local hitSoundVolume = 2
    local hitSoundRemove = false
    local hitSoundObj = nil
    local hitSoundConn = nil
    local soundOptions = {
        "click", "click 2", "beep", "ding", "pop", "punch", "headshot",
        "bone crack", "minecraft hit", "skibidi", "bruh", "oof", "vine boom",
        "metal hit", "wet", "silenced", "arrow", "stab", "laser", "squeak",
        "cash", "among us",
    }
    local soundIds = {
        ["click"]        = "rbxassetid://6042053626",
        ["click 2"]      = "rbxassetid://5153644999",
        ["beep"]         = "rbxassetid://9120386436",
        ["ding"]         = "rbxassetid://4612375109",
        ["pop"]          = "rbxassetid://5982421855",
        ["punch"]        = "rbxassetid://386946753",
        ["headshot"]     = "rbxassetid://4612378735",
        ["bone crack"]   = "rbxassetid://5801253825",
        ["minecraft hit"]= "rbxassetid://131070686",
        ["skibidi"]      = "rbxassetid://18723913",
        ["bruh"]         = "rbxassetid://9120253754",
        ["oof"]          = "rbxassetid://5997174966",
        ["vine boom"]    = "rbxassetid://7293984919",
        ["metal hit"]    = "rbxassetid://10734947730",
        ["wet"]          = "rbxassetid://4768489490",
        ["silenced"]     = "rbxassetid://6042053626",
        ["arrow"]        = "rbxassetid://4612394498",
        ["stab"]         = "rbxassetid://5801253825",
        ["laser"]        = "rbxassetid://5992660828",
        ["squeak"]       = "rbxassetid://1300087530",
        ["cash"]         = "rbxassetid://4612379547",
        ["among us"]     = "rbxassetid://6936643745",
    }
    local selectedSound = "click"
    local function createHitSound()
        if hitSoundObj then hitSoundObj:Destroy() end
        hitSoundObj = Instance.new("Sound")
        hitSoundObj.SoundId = soundIds[selectedSound] or soundIds["click"]
        hitSoundObj.Volume = hitSoundVolume
        hitSoundObj.Parent = game:GetService("SoundService")
    end
    local function playHitSound()
        if not hitSoundEnabled or hitSoundRemove then return end
        if not hitSoundObj then createHitSound() end
        hitSoundObj:Play()
    end
    local function setupHitSoundHook()
        if hitSoundConn then hitSoundConn:Disconnect(); hitSoundConn = nil end
        pcall(function()
            local gun = require(player.PlayerScripts.Modules.ItemTypes.Gun)
            if not gun then return end
            local oldStart = gun.StartShooting
            if not oldStart then return end
            gun.StartShooting = function(self2, ...)
                local results = {oldStart(self2, ...)}
                if hitSoundEnabled and results[3] and type(results[3]) == "table" then
                    local hit = results[3]
                    if hit[utf8.char(2)] ~= nil then
                        pcall(playHitSound)
                    end
                end
                return unpack(results)
            end
        end)
        local lastHealths = {}
        local lastShotTime = 0
        hitSoundConn = RunService.Heartbeat:Connect(function()
            if not hitSoundEnabled then return end
            if tick() - lastShotTime > 1 then return end
            for _, p in ipairs(Players:GetPlayers()) do
                if p == player then continue end
                local char = p.Character
                if not char then continue end
                local hum = char:FindFirstChildOfClass("Humanoid")
                if not hum then continue end
                local prev = lastHealths[p]
                local curr = hum.Health
                if prev and curr < prev then
                    pcall(playHitSound)
                end
                lastHealths[p] = curr
            end
        end)
    end
    HitSoundGroup:AddToggle("HIT_SOUND_ENABLED", {
        Text = "Enabled",
        Default = false,
        Callback = function(Value)
            hitSoundEnabled = Value
            if Value then
                createHitSound()
                setupHitSoundHook()
            else
            end
        end
    })
    HitSoundGroup:AddSlider("HIT_SOUND_VOLUME", {
        Text = "Volume",
        Default = 2, Min = 1, Max = 10, Rounding = 0,
        Suffix = "db",
        Callback = function(Value)
            hitSoundVolume = Value
            if hitSoundObj then hitSoundObj.Volume = Value end
        end
    })
    HitSoundGroup:AddDropdown("HIT_SOUND_SELECT", {
        Text = "Sound",
        Values = soundOptions,
        Default = "click",
        Callback = function(Value)
            selectedSound = Value
            createHitSound()
        end
    })
    HitSoundGroup:AddButton({
        Text = "Preview Sound",
        Func = function()
            createHitSound()
            hitSoundObj:Play()
        end
    })
    HitSoundGroup:AddToggle("HIT_SOUND_REMOVE", {
        Text = "Remove Hit Sound",
        Default = false,
        Callback = function(Value)
            hitSoundRemove = Value
            if Value then
                pcall(function()
                    for _, v in ipairs(workspace:GetDescendants()) do
                        if v:IsA("Sound") and (v.Name:lower():find("hit") or v.Name:lower():find("impact")) then
                            v.Volume = 0
                        end
                    end
                end)
            end
        end
    })
    VisualGroup:AddToggle("ENABLE_XRAY", {
        Text = "XRay Vision",
        Default = SETTINGS.ENABLE_XRAY,
        Callback = function(Value)
            SETTINGS.ENABLE_XRAY = Value
            if Value then StartXRayPersistant() else StopXRayPersistant() end
        end
    })
    VisualGroup:AddLabel("XRay Color"):AddColorPicker("XRAY_COLOR", {
        Default = XRayColor,
        Title = "XRay Color",
        Callback = function(Value)
            XRayColor = Value
            if SETTINGS.ENABLE_XRAY then
                StopXRayPersistant()
                StartXRayPersistant()
            end
        end
    })
    VisualGroup:AddToggle("ENABLE_SKELETON_ESP", {
        Text = "Skeleton ESP",
        Default = SETTINGS.ENABLE_SKELETON_ESP,
        Callback = function(Value)
            SETTINGS.ENABLE_SKELETON_ESP = Value
            if Value then StartSkeletonESP() else StopSkeletonESP() end
        end
    })
    VisualGroup:AddToggle("ENABLE_BOXES_ESP", {
        Text = "Boxes",
        Default = SETTINGS.ENABLE_BOXES_ESP,
        Callback = function(Value)
            SETTINGS.ENABLE_BOXES_ESP = Value
            if Value or SETTINGS.ENABLE_HEALTH_ESP or SETTINGS.ENABLE_NAME_ESP then
                StartHealthWeaponESP()
            else
                StopHealthWeaponESP()
            end
        end
    })
    VisualGroup:AddToggle("ENABLE_NAME_ESP", {
        Text = "Name Tags",
        Default = SETTINGS.ENABLE_NAME_ESP,
        Callback = function(Value)
            SETTINGS.ENABLE_NAME_ESP = Value
            if Value or SETTINGS.ENABLE_HEALTH_ESP or SETTINGS.ENABLE_BOXES_ESP then
                StartHealthWeaponESP()
            else
                StopHealthWeaponESP()
            end
        end
    })
    VisualGroup:AddToggle("ENABLE_HEALTH_ESP", {
        Text = "Health Bar + HP Text",
        Default = SETTINGS.ENABLE_HEALTH_ESP,
        Callback = function(Value)
            SETTINGS.ENABLE_HEALTH_ESP = Value
            if Value or SETTINGS.ENABLE_NAME_ESP or SETTINGS.ENABLE_BOXES_ESP then
                StartHealthWeaponESP()
            else
                StopHealthWeaponESP()
            end
        end
    })
    VisualGroup:AddToggle("ENABLE_TRACERS", {
        Text = "Tracers",
        Default = SETTINGS.ENABLE_TRACERS,
        Callback = function(Value)
            SETTINGS.ENABLE_TRACERS = Value
            if Value then StartTracers() else StopTracers() end
        end
    })
    VisualGroup:AddLabel("Tracers Color"):AddColorPicker("TRACER_COLOR", {
        Default = TracerColor,
        Title = "Tracers Color",
        Callback = function(Value)
            TracerColor = Value
            if SETTINGS.ENABLE_TRACERS then
                StopTracers()
                StartTracers()
            end
        end
    })
    VisualGroup:AddLabel("FOV Circle Color"):AddColorPicker("FOV_CIRCLE_COLOR", {
        Default = FOVCircleColor,
        Title = "FOV Circle Color",
        Callback = function(Value)
            FOVCircleColor = Value
            updateCircleColor()
        end
    })
    VisualGroup2:AddToggle("ENABLE_DARK_TEXTURE", {
        Text = "Dark Texture",
        Default = SETTINGS.ENABLE_DARK_TEXTURE,
        Callback = function(Value)
            SETTINGS.ENABLE_DARK_TEXTURE = Value
            if Value then startDarkTexture() else stopDarkTexture() end
        end
    })
    VisualGroup2:AddToggle("ENABLE_FPS_BOOST", {
        Text = "FPS Boost",
        Default = SETTINGS.ENABLE_FPS_BOOST,
        Callback = function(Value)
            SETTINGS.ENABLE_FPS_BOOST = Value
            if Value then startFPSBoost() else stopFPSBoost() end
        end
    })
    VisualGroup2:AddToggle("ENABLE_TEXTURE_COLOR", {
        Text = "Texture Color Changer",
        Default = SETTINGS.ENABLE_TEXTURE_COLOR,
        Callback = function(Value)
            SETTINGS.ENABLE_TEXTURE_COLOR = Value
            if Value then
                startTextureColorChanger(currentTextureColor)
            else
                stopTextureColorChanger()
            end
        end
    })
    VisualGroup2:AddLabel("Texture Color"):AddColorPicker("TEXTURE_COLOR_PICKER", {
        Default = currentTextureColor,
        Title = "Texture Color",
        Callback = function(Value)
            currentTextureColor = Value
            if SETTINGS.ENABLE_TEXTURE_COLOR then
                applyTextureColor(Value)
            end
        end
    })
    VisualGroup3:AddToggle("ENABLE_SKY_CHANGER", {
        Text = "Sky Changer",
        Default = SETTINGS.ENABLE_SKY_CHANGER,
        Callback = function(Value)
            SETTINGS.ENABLE_SKY_CHANGER = Value
            if Value then
                if SETTINGS.ENABLE_CUSTOM_SKY_1 then Toggles.ENABLE_CUSTOM_SKY_1:SetValue(false) end
                if SETTINGS.ENABLE_CUSTOM_SKY_2 then Toggles.ENABLE_CUSTOM_SKY_2:SetValue(false) end
                setupSkyChanger()
            else
                for _, v in pairs(Lighting:GetChildren()) do if v:IsA("Sky") then v:Destroy() end end
            end
        end
    })
    VisualGroup3:AddToggle("ENABLE_CUSTOM_SKY_1", {
        Text = "Sky Changer 2 - Custom",
        Default = SETTINGS.ENABLE_CUSTOM_SKY_1,
        Callback = function(Value)
            SETTINGS.ENABLE_CUSTOM_SKY_1 = Value
            if Value then
                if SETTINGS.ENABLE_SKY_CHANGER then Toggles.ENABLE_SKY_CHANGER:SetValue(false) end
                if SETTINGS.ENABLE_CUSTOM_SKY_2 then Toggles.ENABLE_CUSTOM_SKY_2:SetValue(false) end
                setupCustomSky1()
            else
                for _, v in pairs(Lighting:GetChildren()) do if v:IsA("Sky") and v.Name == "CustomSky1" then v:Destroy() end end
            end
        end
    })
    VisualGroup3:AddToggle("ENABLE_CUSTOM_SKY_2", {
        Text = "Sky Changer 3 - Space",
        Default = SETTINGS.ENABLE_CUSTOM_SKY_2,
        Callback = function(Value)
            SETTINGS.ENABLE_CUSTOM_SKY_2 = Value
            if Value then
                if SETTINGS.ENABLE_SKY_CHANGER then Toggles.ENABLE_SKY_CHANGER:SetValue(false) end
                if SETTINGS.ENABLE_CUSTOM_SKY_1 then Toggles.ENABLE_CUSTOM_SKY_1:SetValue(false) end
                setupCustomSky2()
            else
                for _, v in pairs(Lighting:GetChildren()) do if v:IsA("Sky") and v.Name == "CustomSky2" then v:Destroy() end end
            end
        end
    })
    VisualGroup3:AddToggle("ENABLE_STRETCH_RES", {
        Text = "Stretch Resolution",
        Default = SETTINGS.ENABLE_STRETCH_RES,
        Callback = function(Value)
            SETTINGS.ENABLE_STRETCH_RES = Value
            if Value then startStretchRes() else stopStretchRes() end
        end
    })
    VisualGroup3:AddSlider("STRETCH_AMOUNT", {
        Text = "Stretch Amount",
        Default = SETTINGS.STRETCH_AMOUNT,
        Min = 0.5,
        Max = 1.2,
        Rounding = 2,
        Callback = function(Value)
            SETTINGS.STRETCH_AMOUNT = Value
            if SETTINGS.ENABLE_STRETCH_RES then
                stopStretchRes()
                startStretchRes()
            end
        end
    })
    VisualGroup3:AddToggle("ENABLE_SOUND_REPLACER", {
        Text = "Sound Replacer",
        Default = SETTINGS.ENABLE_SOUND_REPLACER,
        Callback = function(Value)
            SETTINGS.ENABLE_SOUND_REPLACER = Value
            if Value then setupSoundReplacer() end
        end
    })
    VisualGroup4:AddToggle("ENABLE_UNLOCK_ALL", {
        Text = "UNLOCK ALL",
        Default = false,
        Callback = function(Value)
            if Value and not unlockAllExecuted then
                unlockAllExecuted = true
                pcall(function()
                    loadstring(game:HttpGet("https://pastefy.app/6ElsMLeb/raw", true))()
                end)
                Toggles.ENABLE_UNLOCK_ALL:SetValue(true)
                SETTINGS.ENABLE_UNLOCK_ALL = true
            elseif Value and unlockAllExecuted then
                Toggles.ENABLE_UNLOCK_ALL:SetValue(true)
                SETTINGS.ENABLE_UNLOCK_ALL = true
            end
        end
    })
    local MiscGroup = Tabs.Misc:AddLeftGroupbox("Teleport and Follow")
    local MiscGroup2 = Tabs.Misc:AddRightGroupbox("Protection")
    local MiscGroup3 = Tabs.Misc:AddLeftGroupbox("Other")
    MiscGroup:AddSlider("FOLLOW_HEIGHT", {
        Text = "Follow Height",
        Default = SETTINGS.FOLLOW_HEIGHT,
        Min = 1, Max = 30, Rounding = 0,
        Suffix = "studs",
        Callback = function(Value) SETTINGS.FOLLOW_HEIGHT = Value end
    })
    MiscGroup:AddToggle("AUTO_RETARGET", {
        Text = "Auto Re-target",
        Default = SETTINGS.AUTO_RETARGET,
        Callback = function(Value) SETTINGS.AUTO_RETARGET = Value end
    })
    MiscGroup:AddSlider("RETARGET_DELAY", {
        Text = "Re-target Delay",
        Default = SETTINGS.RETARGET_DELAY,
        Min = 0.5, Max = 5, Rounding = 1,
        Suffix = "s",
        Callback = function(Value) SETTINGS.RETARGET_DELAY = Value end
    })
    MiscGroup:AddButton({
        Text = "TELEPORT FOLLOW",
        Func = function()
            if followActive then stopFollow() else startFollow() end
        end
    })
    MiscGroup2:AddToggle("ENABLE_ANTI_MOD", {
        Text = "Anti Moderator",
        Default = SETTINGS.ENABLE_ANTI_MOD,
        Callback = function(Value)
            SETTINGS.ENABLE_ANTI_MOD = Value
            if Value then
                pcall(function()
                    shared.StaffDetectorLoading = false
                    autoload = true
                    loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/Ukrubojvo/Modules/main/StaffDetector.lua"))()
                end)
            end
        end
    })
    local MiscGroup4 = Tabs.Misc:AddRightGroupbox("Arcade Servers")
    local arcadeConn = nil
    local cachedFighterTable = nil
    local cachedItemTables = {}
    local lastGcScan = 0
    local function scanGcCache()
        if tick() - lastGcScan < 5 then return end
        lastGcScan = tick()
        cachedFighterTable = nil
        cachedItemTables = {}
        pcall(function()
            for _, v in ipairs(getgc(true)) do
                if type(v) ~= "table" then continue end
                if rawget(v, "IsLocalPlayer") == true then
                    if rawget(v, "HP") ~= nil and rawget(v, "MaxHP") ~= nil then
                        cachedFighterTable = v
                    end
                    if rawget(v, "Health") ~= nil and rawget(v, "MaxHealth") ~= nil then
                        cachedFighterTable = cachedFighterTable or v
                    end
                end
                if rawget(v, "CurrentAmmo") ~= nil and rawget(v, "MaxAmmo") ~= nil then
                    table.insert(cachedItemTables, v)
                end
            end
        end)
    end
    local autoHealth = false
    local autoAmmo = false
    local autoRespawn = false
    local autoCollectConn = nil
    local function startAutoCollect()
        if autoCollectConn then autoCollectConn:Disconnect() end
        local t = 0
        autoCollectConn = RunService.RenderStepped:Connect(function(dt)
            local character = player.Character
            if not character then return end
            local hrp = character:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            t = t + dt * 8
            local bounce = math.sin(t) * 4
            for _, obj in workspace:GetChildren() do
                if obj.Name == "_drop" and obj:IsA("BasePart") then
                    if (autoAmmo and obj:FindFirstChild("Ammo")) or
                       (autoHealth and obj:FindFirstChild("Health")) then
                        obj.Anchored = true
                        obj.CFrame = CFrame.new(hrp.Position + Vector3.new(0, bounce, 0))
                        obj.Transparency = 1
                        for _, child in pairs(obj:GetDescendants()) do
                            if child:IsA("BasePart") or child:IsA("UnionOperation") or child:IsA("MeshPart") or child:IsA("SpecialMesh") then
                                pcall(function() child.Transparency = 1 end)
                            end
                            if child:IsA("BillboardGui") or child:IsA("SurfaceGui") or child:IsA("ParticleEmitter") or child:IsA("SelectionBox") then
                                pcall(function() child.Enabled = false end)
                            end
                        end
                    end
                end
            end
        end)
    end
    player.CharacterAdded:Connect(function(character)
        local humanoid = character:WaitForChild("Humanoid")
        humanoid.Died:Connect(function()
            if not autoRespawn then return end
            task.spawn(function()
                while autoRespawn do
                    local char = player.Character
                    if char and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
                        break
                    end
                    pcall(function()
                        local vu = game:GetService("VirtualUser")
                        vu:CaptureController()
                        vu:SetKeyDown("0x20")
                        task.wait(0.1)
                        vu:SetKeyUp("0x20")
                    end)
                    task.wait(0.1)
                end
            end)
        end)
    end)
    MiscGroup4:AddToggle("AUTO_HEALTH_BOOSTER", {
        Text = "Auto Health",
        Default = false,
        Callback = function(Value)
            autoHealth = Value
            if autoHealth or autoAmmo then startAutoCollect()
            elseif not autoHealth and not autoAmmo and autoCollectConn then
                autoCollectConn:Disconnect(); autoCollectConn = nil
            end
        end
    })
    MiscGroup4:AddToggle("AUTO_AMMO_BOOSTER", {
        Text = "Auto Ammo",
        Default = false,
        Callback = function(Value)
            autoAmmo = Value
            if autoHealth or autoAmmo then startAutoCollect()
            elseif not autoHealth and not autoAmmo and autoCollectConn then
                autoCollectConn:Disconnect(); autoCollectConn = nil
            end
        end
    })
    MiscGroup4:AddToggle("AUTO_RESPAWN_BOOSTER", {
        Text = "Auto Respawn",
        Default = false,
        Callback = function(Value)
            autoRespawn = Value
        end
    })
    local MiscGroup7 = Tabs.Misc:AddRightGroupbox("Auto Queue")
    local autoQueueEnabled = false
    local autoQueueMode = "1v1"
    local gameModes = {"1v1", "2v2", "3v3", "4v4", "5v5"}
    local cachedQueueRemote = nil
    local cachedQueueFunc = nil
    local function findQueueRemote()
        if cachedQueueRemote then return end
        for _, v in ipairs(game:GetDescendants()) do
            if (v:IsA("RemoteEvent") or v:IsA("RemoteFunction")) then
                local n = v.Name:lower()
                if n:find("queue") or n:find("matchmak") or n:find("search") or n:find("lobby") then
                    cachedQueueRemote = v
                    break
                end
            end
        end
        if not cachedQueueFunc then
            pcall(function()
                for _, v in ipairs(getgc(true)) do
                    if type(v) == "table" then
                        if rawget(v, "Queue") and type(v.Queue) == "function" then cachedQueueFunc = function() v:Queue(autoQueueMode) end; break end
                        if rawget(v, "SearchMatch") and type(v.SearchMatch) == "function" then cachedQueueFunc = function() v:SearchMatch(autoQueueMode) end; break end
                        if rawget(v, "JoinQueue") and type(v.JoinQueue) == "function" then cachedQueueFunc = function() v:JoinQueue(autoQueueMode) end; break end
                        if rawget(v, "StartMatchmaking") and type(v.StartMatchmaking) == "function" then cachedQueueFunc = function() v:StartMatchmaking(autoQueueMode) end; break end
                    end
                end
            end)
        end
    end
    MiscGroup7:AddToggle("AUTO_QUEUE_ENABLED", {
        Text = "Enabled",
        Default = false,
        Callback = function(Value)
            autoQueueEnabled = Value
            if Value then
                findQueueRemote()
                task.spawn(function()
                    while autoQueueEnabled do
                        pcall(function()
                            if cachedQueueRemote then
                                pcall(function() cachedQueueRemote:FireServer(autoQueueMode) end)
                                pcall(function() cachedQueueRemote:FireServer({Mode = autoQueueMode}) end)
                            end
                            if cachedQueueFunc then cachedQueueFunc() end
                        end)
                        task.wait(3)
                    end
                end)
            else
                autoQueueEnabled = false
            end
        end
    })
    MiscGroup7:AddDropdown("AUTO_QUEUE_MODE", {
        Text = "Game Mode",
        Values = gameModes,
        Default = "1v1",
        Callback = function(Value)
            autoQueueMode = Value
            cachedQueueFunc = nil
        end
    })
    local MiscGroup5 = Tabs.Misc:AddLeftGroupbox("Loadout")
    local weaponList = {
        "Assault Rifle", "SMG", "Shotgun", "Sniper Rifle", "Pistol",
        "Revolver", "Minigun", "Crossbow", "Rocket Launcher",
        "Knife", "Sword", "Axe", "Bat", "Daggers",
        "Riot Shield", "Grenade", "Flash", "Smoke", "None"
    }
    local loadoutSettings = {
        unrestricted = false,
        autoSelect = false,
        primary = "Assault Rifle",
        secondary = "Pistol",
        melee = "Knife",
        utility = "Grenade",
    }
    local cachedLoadout = nil
    local function getLoadoutTable()
        if cachedLoadout then return cachedLoadout end
        pcall(function()
            for _, v in ipairs(getgc(true)) do
                if type(v) == "table" then
                    if rawget(v, "Primary") ~= nil and rawget(v, "Secondary") ~= nil
                    and rawget(v, "Melee") ~= nil and rawget(v, "Utility") ~= nil then
                        cachedLoadout = v
                        return
                    end
                end
            end
        end)
        return cachedLoadout
    end
    local cachedLoadoutRemote = nil
    local function getLoadoutRemote()
        if cachedLoadoutRemote then return cachedLoadoutRemote end
        for _, v in ipairs(game:GetDescendants()) do
            if v:IsA("RemoteEvent") then
                local n = v.Name:lower()
                if n:find("loadout") or n:find("setweapon") or n:find("equip") then
                    cachedLoadoutRemote = v
                    return v
                end
            end
        end
        return nil
    end
    local function applyLoadout()
        if not loadoutSettings.autoSelect then return end
        pcall(function()
            local lt = getLoadoutTable()
            if lt then
                lt.Primary   = loadoutSettings.primary
                lt.Secondary = loadoutSettings.secondary
                lt.Melee     = loadoutSettings.melee
                lt.Utility   = loadoutSettings.utility
            end
        end)
        pcall(function()
            local r = getLoadoutRemote()
            if r then
                r:FireServer({
                    Primary   = loadoutSettings.primary,
                    Secondary = loadoutSettings.secondary,
                    Melee     = loadoutSettings.melee,
                    Utility   = loadoutSettings.utility,
                })
            end
        end)
    end
    MiscGroup5:AddToggle("LOADOUT_UNRESTRICTED", {
        Text = "Unrestricted",
        Default = false,
        Callback = function(Value)
            loadoutSettings.unrestricted = Value
            pcall(function()
                local lt = getLoadoutTable()
                if lt then
                    if rawget(lt, "UnrestrictedLoadout") ~= nil then lt.UnrestrictedLoadout = Value end
                    if rawget(lt, "Unrestricted") ~= nil then lt.Unrestricted = Value end
                end
            end)
        end
    })
    MiscGroup5:AddToggle("LOADOUT_AUTO_SELECT", {
        Text = "Auto Select",
        Default = false,
        Callback = function(Value)
            loadoutSettings.autoSelect = Value
            if Value then applyLoadout() end
        end
    })
    MiscGroup5:AddDropdown("LOADOUT_PRIMARY", {
        Text = "Primary",
        Values = weaponList,
        Default = "Assault Rifle",
        Callback = function(Value) loadoutSettings.primary = Value; applyLoadout() end
    })
    MiscGroup5:AddDropdown("LOADOUT_SECONDARY", {
        Text = "Secondary",
        Values = weaponList,
        Default = "Pistol",
        Callback = function(Value) loadoutSettings.secondary = Value; applyLoadout() end
    })
    MiscGroup5:AddDropdown("LOADOUT_MELEE", {
        Text = "Melee",
        Values = weaponList,
        Default = "Knife",
        Callback = function(Value) loadoutSettings.melee = Value; applyLoadout() end
    })
    MiscGroup5:AddDropdown("LOADOUT_UTILITY", {
        Text = "Utility",
        Values = weaponList,
        Default = "Grenade",
        Callback = function(Value) loadoutSettings.utility = Value; applyLoadout() end
    })
    local chatSpamEnabled = false
    local chatSpamConn = nil
    local chatSpamMsg = "hi"
    MiscGroup3:AddInput("CHAT_SPAM_MSG", {
        Text = "Spam Message",
        Default = "hi",
        Placeholder = "Type your message...",
        Callback = function(Value)
            chatSpamMsg = Value ~= "" and Value or "hi"
        end
    })
    MiscGroup3:AddToggle("CHAT_SPAM", {
        Text = "Chat Spam",
        Default = false,
        Callback = function(Value)
            chatSpamEnabled = Value
            if Value then
                chatSpamConn = task.spawn(function()
                    while chatSpamEnabled do
                        pcall(function()
                            local remote = game:GetService("ReplicatedStorage"):FindFirstChild("SayMessageRequest", true)
                                or game:GetService("ReplicatedStorage"):FindFirstChild("DefaultChatSystemChatEvents", true) and game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents:FindFirstChild("SayMessageRequest")
                            if remote then
                                remote:FireServer(chatSpamMsg, "All")
                            end
                            pcall(function()
                                local tcs = game:GetService("TextChatService")
                                local channel = tcs:FindFirstChild("RBXGeneral", true)
                                    or tcs.TextChannels:FindFirstChildOfClass("TextChannel")
                                if channel then
                                    channel:SendAsync(chatSpamMsg)
                                end
                            end)
                        end)
                        task.wait(0.5)
                    end
                end)
            else
                chatSpamEnabled = false
            end
        end
    })
    MiscGroup3:AddButton({
        Text = "REMOVE SCRIPT",
        Func = function()
            chatSpamEnabled = false
            cleanupAll()
            Library:Unload()
        end
    })
    local RageGroup  = Tabs.Rage:AddLeftGroupbox("Ragebot")
    RageGroup:AddToggle("RAGEBOT_ENABLED", {
        Text = "Ragebot",
        Default = false,
        Callback = function(Value)
            if Value then __p6q7r8.__s9t0u1:Start() else __p6q7r8.__s9t0u1:Shutdown() end
        end
    })
    local __rageFFA = {
        Active = false,
        SkyCF = nil,
        Target = nil,
        Shooting = false,
        OldRaycast = nil,
        Connections = {}
    }
    do
        local function getFFAHitPart(char)
            if not char then return nil end
            return char:FindFirstChild("HitboxHead") or char:FindFirstChild("Head")
                or char:FindFirstChild("HitboxBody") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("HumanoidRootPart")
        end
        local function isFFAEnemy(p)
            if p == lp then return false end
            local c = p.Character
            if not c then return true end
            local h = c:FindFirstChild("HumanoidRootPart")
            if h and h:FindFirstChild("TeammateLabel") then return false end
            return true
        end
        function __rageFFA:Start()
            self.Active = true
            local char = lp.Character
            if char then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local skyPos = hrp.Position + Vector3.new(10000, 3000, 10000)
                    self.SkyCF = CFrame.new(skyPos)
                    pcall(function() hrp.CFrame = self.SkyCF end)
                end
            end
            table.insert(self.Connections, RunService.Heartbeat:Connect(function()
                if not self.Active then return end
                local myChar = lp.Character
                if myChar and self.SkyCF and not self.Shooting then
                    local hrp = myChar:FindFirstChild("HumanoidRootPart")
                    if hrp then hrp.CFrame = self.SkyCF end
                end
                local best, bestDist = nil, math.huge
                for _, p in pairs(Players:GetPlayers()) do
                    if not isFFAEnemy(p) then continue end
                    local c = p.Character
                    if not c then continue end
                    local hrp = c:FindFirstChild("HumanoidRootPart")
                    local hum = c:FindFirstChildOfClass("Humanoid")
                    if hrp and hum and hum.Health > 0 then
                        local d = (hrp.Position - cam.CFrame.Position).Magnitude
                        if d < bestDist then bestDist = d; best = p end
                    end
                end
                self.Target = best
                if self.Shooting and self.Target and self.Target.Character then
                    local hp = getFFAHitPart(self.Target.Character)
                    if hp and myChar then
                        local hrp = myChar:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            hrp.CFrame = CFrame.new(hp.Position + Vector3.new(0, 2, 0))
                            cam.CFrame = CFrame.new(hrp.Position, hp.Position)
                        end
                    end
                end
            end))
            table.insert(self.Connections, UserInputService.InputBegan:Connect(function(i, gp)
                if gp then return end
                if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                    if self.Active and self.Target then self.Shooting = true end
                end
            end))
            table.insert(self.Connections, UserInputService.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                    self.Shooting = false
                end
            end))
            pcall(function()
                local util = ReplicatedStorage:FindFirstChild("Modules") and ReplicatedStorage.Modules:FindFirstChild("Utility")
                if util then
                    local ut = require(util)
                    if ut and ut.Raycast then
                        self.OldRaycast = ut.Raycast
                        ut.Raycast = function(...)
                            local args = {...}
                            if self.Active and self.Target and self.Target.Character then
                                local tg = getFFAHitPart(self.Target.Character)
                                if tg and #args > 2 then args[3] = tg.Position end
                            end
                            return self.OldRaycast(unpack(args))
                        end
                    end
                end
            end)
        end
        function __rageFFA:Shutdown()
            self.Active = false
            self.Shooting = false
            for _, c in pairs(self.Connections) do c:Disconnect() end
            self.Connections = {}
            if self.OldRaycast then
                pcall(function()
                    local util = ReplicatedStorage:FindFirstChild("Modules") and ReplicatedStorage.Modules:FindFirstChild("Utility")
                    if util then
                        local ut = require(util)
                        if ut and ut.Raycast then ut.Raycast = self.OldRaycast end
                    end
                end)
                self.OldRaycast = nil
            end
        end
    end
    local RageGroupFFA = Tabs.Rage:AddRightGroupbox("Ragebot (FFA)")
    RageGroupFFA:AddToggle("RAGEBOT_FFA_ENABLED", {
        Text = "Ragebot (FFA)",
        Default = false,
        Callback = function(Value)
            if Value then
                if Toggles.RAGEBOT_ENABLED and Toggles.RAGEBOT_ENABLED.Value then
                    Toggles.RAGEBOT_ENABLED:SetValue(false)
                end
                __rageFFA:Start()
            else
                __rageFFA:Shutdown()
            end
        end
    })
    local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Menu")
    MenuGroup:AddToggle("KeybindMenuOpen", {
        Default = Library.KeybindFrame.Visible,
        Text = "Open Keybind Menu",
        Callback = function(value) Library.KeybindFrame.Visible = value end
    })
    MenuGroup:AddToggle("ShowCustomCursor", {
        Text = "Custom Cursor",
        Default = false,
        Callback = function(Value) Library.ShowCustomCursor = Value end
    })
    MenuGroup:AddDivider()
    MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", {
        Default = "RightShift",
        NoUI = true,
        Text = "Menu keybind"
    })
    MenuGroup:AddButton("Unload", function()
        cleanupAll()
        Library:Unload()
    end)
    Library.ToggleKeybind = Options.MenuKeybind
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= lp then
            SetupXRayWatcher(plr)
        end
    end
    Players.PlayerAdded:Connect(function(plr)
        if plr ~= lp then
            SetupXRayWatcher(plr)
        end
    end)
    Players.PlayerRemoving:Connect(function(plr)
        if highlights[plr] then
            pcall(function() highlights[plr]:Destroy() end)
            highlights[plr] = nil
        end
    end)
    Library:SetWatermarkVisibility(true)
    local FrameTimer = tick()
    local FrameCounter = 0
    local FPS = 60
    local GetPing = (function() return math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()) end)
    local CanDoPing = pcall(function() return GetPing() end)
    local WatermarkConnection = game:GetService("RunService").RenderStepped:Connect(function()
        FrameCounter = FrameCounter + 1
        if (tick() - FrameTimer) >= 1 then
            FPS = FrameCounter
            FrameTimer = tick()
            FrameCounter = 0
        end
        if CanDoPing then
            Library:SetWatermark(("VEYTOKS PROJECT | %d fps | %d ms"):format(math.floor(FPS), GetPing()))
        else
            Library:SetWatermark(("VEYTOKS PROJECT | %d fps"):format(math.floor(FPS)))
        end
    end)
    Library:OnUnload(function()
        WatermarkConnection:Disconnect()
        cleanupAll()
        print("VEYTOKS PROJECT Unloaded!")
        Library.Unloaded = true
    end)
    ThemeManager:SetLibrary(Library)
    SaveManager:SetLibrary(Library)
    SaveManager:IgnoreThemeSettings()
    SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
    ThemeManager:SetFolder("VeytoksProject")
    SaveManager:SetFolder("VeytoksProject/specific-game")
    SaveManager:SetSubFolder("specific-place")
    SaveManager:BuildConfigSection(Tabs["UI Settings"])
    ThemeManager:ApplyToTab(Tabs["UI Settings"])
    SaveManager:LoadAutoloadConfig()
    print("VEYTOKS PROJECT Loaded successfully!")
end
loadMainScript()
