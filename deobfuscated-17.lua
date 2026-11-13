---@source Тһіѕ Fіle Ԝаѕ Dеоbfuscаteԁ Ву LеаκD
---@see https://leakd.fr

print("Aurora Addons is loading..")

if not game:IsLoaded() then
	game.Loaded:Wait()
end

task.wait(5)
local v1 = request or http_request or syn and syn.request or fluxus and fluxus.request
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local Stats = game:GetService("Stats")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local TouchEnabled = UserInputService.TouchEnabled
local v2 = TouchEnabled and 0.8 or 1
local v3 = TouchEnabled and 32 or 40
local vector2 = Vector2.new(0, 0)
local tbl = {}

if game.GameId ~= 6035872082 then
	warn("Aurora: wrong game")
	return
end

local tbl1 = {
	current = "default",
	profiles = {default = {}},
	theme = "Halloween",
	keybind = "RightControl",
	rage = {weaponSlot = "Melee", fireRateIdx = 1, rangeIdx = 3, desync = true, underground = false},
}

if readfile and isfile and isfile("aurora_config.json") then
	local ok, result = pcall(function()
		return HttpService:JSONDecode(readfile("aurora_config.json"))
	end)
	if ok and type(result) == "table" then
		if type(result.profiles) == "table" then
			tbl1.current = result.current or tbl1.current
			tbl1.profiles = result.profiles
		else
			local tbl2 = {}

			for k, v4 in pairs(result) do
				if k ~= "theme" and k ~= "keybind" then
					tbl2[k] = v4
				end
			end

			tbl1.profiles = {default = tbl2}
			tbl1.current = "default"
		end

		tbl1.theme = result.theme or tbl1.theme
		tbl1.keybind = result.keybind or tbl1.keybind

		if type(result.rage) == "table" then
			for k1, v5 in pairs(result.rage) do
				tbl1.rage[k1] = v5
			end
		end
	end
end

if not tbl1.profiles[tbl1.current] then
	tbl1.profiles[tbl1.current] = {}
end

local function func()
	if not writefile then
		warn("Aurora: executor has no writefile, config not saved")
		return
	end

	local ok, result = pcall(writefile, "aurora_config.json", HttpService:JSONEncode(tbl1))

	if not ok then
		warn("Aurora: config save failed: " .. tostring(result))
	end
end

local function func1()
	local tbl = {}

	for k in pairs(tbl1.profiles) do
		table.insert(tbl, k)
	end

	table.sort(tbl)
	return tbl
end

local function func2(arg1, arg2)
	tbl1.profiles[tbl1.current] = tbl1.profiles[tbl1.current] or {}
	tbl1.profiles[tbl1.current][arg1] = arg2
	func()
end

local tbl3 = {}
local tbl4 = {}
local tbl5 = {}
local tbl6 = {}

local function func3(arg1, arg2)
	if tbl3[arg1] == arg2 then
		return
	end

	tbl3[arg1] = arg2

	for _, v1 in ipairs(tbl6[arg1] or {}) do
		v1()
	end

	if tbl5[arg1] then
		tbl5[arg1](arg2)
	end
end

local function func4()
	local tbl = {}

	for k in pairs(tbl4) do
		tbl[k] = tbl3[k] == true
	end

	return tbl
end

local Modules = ReplicatedStorage:WaitForChild("Modules", 15)
local v6 = Modules and Modules:WaitForChild("ItemLibrary", 15)

if not v6 then
	warn("Aurora: ItemLibrary not found, gun and melee stats disabled")
end

local v7 = v6 and require(v6).Items or {}
local tbl7 = {}

local tbl8 = {
	Gun = {
		skipExceptions = true,
		fields = {
			ShootSpread = 0,
			ShootAccuracy = 0,
			ShootRecoil = 0,
			ShootCooldown = 0.001,
			ShootBurstCooldown = 0.001,
		},
	},
	Cooldown = {
		skipExceptions = false,
		fields = {
			AttackCooldown = 0.001,
			SwingCooldown = 0.001,
			MeleeCooldown = 0.001,
			Cooldown = 0.001,
			RecoveryTime = 0.001,
			ResetTime = 0.001,
		},
	},
}

local function func5(arg1, arg2)
	local v1 = tbl8[arg1]
	for k, v2 in pairs(v7) do
		if typeof(v2) == "table" and not (v1.skipExceptions and tbl[k]) then
			for k1, field in pairs(v1.fields) do
				if arg2 then
					if v2[k1] ~= nil then
						tbl7[v2] = tbl7[v2] or {}

						if tbl7[v2][k1] == nil then
							tbl7[v2][k1] = v2[k1]
						end

						v2[k1] = field
					end
				else
					local v3 = tbl7[v2] and tbl7[v2][k1]
					if v3 ~= nil then
						v2[k1] = v3
					end
				end
			end
		end
	end
end

local function func6(player)
	if player == LocalPlayer then
		return false
	end

	if LocalPlayer.Team and player.Team then
		return LocalPlayer.Team ~= player.Team
	end

	if LocalPlayer.Neutral or player.Neutral then
		return true
	end

	return player.TeamColor ~= LocalPlayer.TeamColor
end

local function func7(player)
	local Character = player.Character

	if not Character then
		return false
	end

	local Humanoid = Character:FindFirstChildOfClass("Humanoid")
	return Humanoid and Humanoid.Health > 0 and Character:FindFirstChild("HumanoidRootPart") and Character:FindFirstChild("Head")
end

local function func8()
	local Character = LocalPlayer.Character
	local v1 = Character and Character:FindFirstChild("HumanoidRootPart")

	if not v1 then
		return nil
	end

	local v2
	local v3

	for _, player in ipairs(Players:GetPlayers()) do
		if func6(player) and func7(player) then
			local Magnitude = (player.Character.HumanoidRootPart.Position - v1.Position).Magnitude
			if not v3 or Magnitude < v3 then
				v2 = player
				v3 = Magnitude
			end
		end
	end

	return v2
end

local connection
local num = 0

local function func9(arg1)
	if arg1 then
		connection = RunService.Heartbeat:Connect(function(deltaTime)
			local Character = LocalPlayer.Character
			local v1 = Character and Character:FindFirstChild("HumanoidRootPart")

			if not v1 then
				return
			end

			local v2 = func8()

			if not v2 then
				return
			end

			local HumanoidRootPart = v2.Character.HumanoidRootPart
			num = (num + 100000000000 * deltaTime) % (2 * math.pi)
			v1.CFrame = CFrame.new(HumanoidRootPart.Position) * CFrame.Angles(0, num, 0) * CFrame.new(0, 0, 6)
			v1.AssemblyLinearVelocity = Vector3.zero
		end)
	elseif connection then
		connection:Disconnect()
		connection = nil
	end
end

local flag = false

local function func10(arg1)
	flag = arg1

	if not arg1 then
		return
	end

	task.spawn(function()
		while flag do
			local Character = LocalPlayer.Character
			local v1 = Character and Character:FindFirstChild("HumanoidRootPart")

			if v1 then
				local CFrame1 = v1.CFrame
				v1.CFrame = CFrame.new(CFrame1.Position.X, -100000000, CFrame1.Position.Z)
				RunService.Heartbeat:Wait()
				local Character1 = LocalPlayer.Character
				local v2 = Character1 and Character1:FindFirstChild("HumanoidRootPart")

				if v2 then
					v2.CFrame = CFrame1
					v2.AssemblyLinearVelocity = Vector3.zero
				end

				RunService.Heartbeat:Wait()
			else
				task.wait(0.1)
			end
		end
	end)
end

local connection1
local v21

local function func11(arg1)
	if arg1 then
		connection1 = RunService.Heartbeat:Connect(function()
			local Character = LocalPlayer.Character
			local v1 = Character and Character:FindFirstChild("HumanoidRootPart")

			if not v1 then
				return
			end

			if not v21 or not func7(v21) then
				v21 = func8()
			end

			if not v21 then
				return
			end

			local Head = v21.Character:FindFirstChild("Head")

			if not Head then
				v21 = nil
				return
			end

			v1.CFrame = Head.CFrame * CFrame.new(0, 3, 0)
			v1.AssemblyLinearVelocity = Vector3.zero
		end)
	else
		if connection1 then
			connection1:Disconnect()
			connection1 = nil
		end
		v21 = nil
	end
end

local tbl9 = {"Primary", "Secondary", "Melee"}
local tbl10 = {Primary = 1, Secondary = 2, Melee = 3}
local tbl11 = {0.0005, 0.005, 0.05, 0.2}
local tbl12 = {150, 300, 500, 1000}
local rage = tbl1.rage
local v22
local flag1 = false
local v23
local num1 = 0
local num2 = 0
local tbl13 = {}

local function func12()
	if v22 then
		return v22
	end

	local ok, result = pcall(function()
		local Controllers = LocalPlayer.PlayerScripts:WaitForChild("Controllers", 5)
		return {
			util = require(ReplicatedStorage.Modules.Utility),
			enum = require(ReplicatedStorage.Modules.EnumLibrary),
			fc = require(Controllers.FighterController),
			sc = require(Controllers:WaitForChild("SpectateController", 5)),
		}
	end)

	if ok then
		v22 = result
	else
		warn("Aurora ragebot: modules not found in this game: " .. tostring(result))
	end

	return v22
end

local function func13()
	num1 = num1 + 1
	local v1 = num1

	task.spawn(function()
		while flag1 and num1 == v1 do
			local v2 = v22
			v2 = v2 and v22.fc
			v2 = v2 and v22.fc.LocalFighter

			if v2 then
				pcall(function()
					v2:EquipItem(tbl10[rage.weaponSlot] or 3)
				end)
			end

			task.wait(1)
		end
	end)
end

local function func14(arg1)
	local sc = v22.sc

	if arg1 == LocalPlayer then
		return false
	end

	local CurrentDuelSubject = sc.CurrentDuelSubject
	local v1 = CurrentDuelSubject and CurrentDuelSubject:GetDueler(LocalPlayer)
	local v2 = v1 and v1:Get("TeamID") or nil

	if v2 and CurrentDuelSubject and CurrentDuelSubject.Duelers then
		for _, v3 in CurrentDuelSubject.Duelers do
			if v3.Player == arg1 then
				return v3:Get("TeamID") ~= v2
			end
		end
	end

	local teamID = arg1:GetAttribute("TeamID")
	local teamID1 = LocalPlayer:GetAttribute("TeamID")

	if teamID and teamID1 then
		return teamID ~= teamID1
	end

	return true
end

local function func15()
	local fc = v22.fc

	if not fc or not fc.Objects then
		return
	end

	for _, v1 in fc.Objects do
		local Player = v1.Player
		if Player then
			if not v1.Entity or not v1.Entity:IsAlive() or v1:Get("IsSpectating") then
				tbl13[Player] = false
			else
				local EquippedItem = v1.EquippedItem
				local flag = false

				if EquippedItem and EquippedItem.ViewModel and EquippedItem.ViewModel.Name == "Katana" then
					flag = EquippedItem._attack_cooldown and EquippedItem._attack_cooldown > tick() or false
				end

				tbl13[Player] = flag
			end
		end
	end
end

local function func16()
	local Character = LocalPlayer.Character

	if not Character then
		return nil, nil, nil
	end

	local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")

	if not HumanoidRootPart then
		return nil, nil, nil
	end

	local v2
	local v3
	local v4
	local v1 = tbl12[rage.rangeIdx] or 500

	for _, player in ipairs(Players:GetPlayers()) do
		if func14(player) then
			local Character1 = player.Character
			if Character1 then
				local HumanoidRootPart1 = Character1:FindFirstChild("HumanoidRootPart")
				local Head = Character1:FindFirstChild("Head")
				local Humanoid = Character1:FindFirstChildWhichIsA("Humanoid")

				if HumanoidRootPart1 and Head and Humanoid and Humanoid.Health > 0 then
					local Magnitude = (HumanoidRootPart.Position - HumanoidRootPart1.Position).Magnitude
					if Magnitude < v1 then
						v1 = Magnitude
						v2 = player
						v3 = HumanoidRootPart1
						v4 = Head
					end
				end
			end
		end
	end

	return v2, v3, v4
end

local function func17(arg1)
	if not arg1 then
		return false
	end

	local ViewModels = Workspace:FindFirstChild("ViewModels")

	if not ViewModels then
		return false
	end

	local Name = arg1.Name

	for _, v1 in ViewModels:GetChildren() do
		if v1:IsA("Model") and string.find(v1.Name, Name, 1, true) and string.find(v1.Name, "Knife", 1, true) then
			return true
		end
	end

	return false
end

local function func18(arg1)
	local tbl = {"shoot", "fire", "swing", "attack", "slash", "gunshot", "stab"}
	pcall(function()
		local ViewModels = Workspace:FindFirstChild("ViewModels")

		if not ViewModels then
			return
		end

		local v1 = arg1.Get and arg1:Get("Name") or nil
		local v3

		for _, v2 in ViewModels:GetChildren() do
			if v2:IsA("Model") and string.find(v2.Name, LocalPlayer.Name, 1, true) then
				if v1 and string.find(v2.Name, tostring(v1), 1, true) then
					v3 = v2
					break
				end
				v3 = v3 or v2
			end
		end

		if not v3 then
			return
		end

		local Debris = game:GetService("Debris")

		for _, v4 in v3:GetDescendants() do
			local v5 = v4:IsA("Sound")

			if v5 then
				local v6 = string.lower(v4.Name)
				local v7, v8, v9 = ipairs(tbl)
				v5 = false

				for _, v10 in v7, v8, v9 do
					if string.find(v6, v10, 1, true) then
						v5 = true
						break
					end
				end
			end

			if v5 then
				local v11 = v4:Clone()
				v11.Looped = false
				v11.Parent = v4.Parent or v3
				v11:Play()
				Debris:AddItem(v11, math.max(v11.TimeLength, 2) + 1)
			end
		end

		local Animator = v3:FindFirstChildWhichIsA("Animator", true)

		if Animator then
			for _, v12 in v3:GetDescendants() do
				local v13 = v12:IsA("Animation")

				if v13 then
					local v14 = string.lower(v12.Name)
					local v15, v16, v17 = ipairs(tbl)
					v13 = false

					for _, v18 in v15, v16, v17 do
						if string.find(v14, v18, 1, true) then
							v13 = true
							break
						end
					end
				end

				if v13 then
					Animator:LoadAnimation(v12):Play()
				end
			end
		end
	end)
end

local function func19()
	if not v22 then
		return
	end

	func15()
	local v1, v2, v3 = func16()
	local v4

	if v2 and v3 then
		local Position

		if func17(v1) then
			Position = (v2.CFrame * CFrame.new(0, 6, 0)).Position
		else
			Position = (v2.CFrame * CFrame.new(0, 1, 2)).Position
		end

		v4 = CFrame.lookAt(Position, v3.Position)
	end

	local v5 = rage.desync and v4 and LocalPlayer.Character

	if v5 then
		v5 = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		if v5 then
			local CFrame1 = v5.CFrame
			local AssemblyLinearVelocity = v5.AssemblyLinearVelocity
			local AssemblyAngularVelocity = v5.AssemblyAngularVelocity
			v5.CFrame = v4
			pcall(RunService.UnbindFromRenderStep, RunService, "__restore")

			RunService:BindToRenderStep("__restore", 101, function()
				v5.CFrame = CFrame1
				v5.AssemblyLinearVelocity = AssemblyLinearVelocity
				v5.AssemblyAngularVelocity = AssemblyAngularVelocity
				RunService:UnbindFromRenderStep("__restore")
			end)
		end
	end

	v5 = not v1
	v5 = v5 or not v3
	v5 = v5 or not v2

	if v5 then
		return
	end

	v5 = tbl13[v1]

	if v5 then
		return
	end

	v5 = not LocalPlayer.Character
	v5 = v5 or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

	if v5 then
		return
	end

	v5 = v22.fc.LocalFighter

	if not v5 then
		return
	end

	local EquippedItem = v5.EquippedItem

	if not EquippedItem then
		return
	end

	local v6 = tbl11[rage.fireRateIdx]

	if tick() - num2 < (v6 or 0.0005) then
		return
	end

	num2 = tick()
	local v7 = CFrame.lookAt(v4 and v4.Position or v2.Position, v3.Position)
	local vector3 = Vector3.new((math.random() - 0.5) * 0.1, (math.random() - 0.5) * 0.1, (math.random() - 0.5) * 0.1)
	local v8 = v3.Position + vector3
	local v9 = v3.CFrame:ToObjectSpace(CFrame.new(v8))
	local util = v22.util
	local enum = v22.enum
	local tbl = {}
	local v10 = utf8.char(1)
	local tbl1 = {}
	tbl1[utf8.char(0)] = util:EncodeCFrame(v7)
	tbl1[utf8.char(1)] = util:EncodeCFrame(v3.CFrame)
	tbl1[utf8.char(2)] = v3
	tbl1[utf8.char(3)] = util:EncodeCFrame(v9)
	tbl[v10] = tbl1
	ReplicatedStorage.Remotes.Replication.Fighter.UseItem:FireServer(EquippedItem:Get("ObjectID"), enum:ToEnum("StartShooting"), tbl, nil)
	func18(EquippedItem)
end

local connection2
local v24

local function func20()
	if v24 then
		local Character = LocalPlayer.Character
		local v1 = Character and Character:FindFirstChild("HumanoidRootPart")

		if v1 then
			local Position = v1.Position
			v1.CFrame = CFrame.new(Position.X, v24, Position.Z) * v1.CFrame.Rotation
			v1.AssemblyLinearVelocity = Vector3.zero
		end
	end
	v24 = nil
end

local function func21()
	local v1 = flag1 and rage.underground
	if v1 and not connection2 then
		connection2 = RunService.Heartbeat:Connect(function()
			local Character = LocalPlayer.Character
			local v1 = Character and Character:FindFirstChild("HumanoidRootPart")

			if not v1 then
				return
			end

			v24 = v24 or v1.Position.Y
			local Position = v1.Position
			v1.CFrame = CFrame.new(Position.X, v24 - 25, Position.Z) * v1.CFrame.Rotation
			v1.AssemblyLinearVelocity = Vector3.zero
		end)
	elseif not v1 and connection2 then
		connection2:Disconnect()
		connection2 = nil
		func20()
	end
end

local function func22(arg1)
	flag1 = arg1

	if not arg1 then
		if v23 then
			v23:Disconnect()
			v23 = nil
		end

		num1 = num1 + 1
		func21()
		return
	end

	if not func12() then
		func3("rage", false)
		return
	end

	v23 = RunService.Heartbeat:Connect(function()
		pcall(func19)
	end)

	func13()
	func21()
end

local tbl14 = {}
local flag2 = false
local num3 = 0

local function func23(arg1, arg2)
	if not v1 then
		warn("Aurora sync: executor has no request function")
		return nil
	end

	local ok, result = pcall(v1, {
		Url = arg1,
		Method = "POST",
		Headers = {["Content-Type"] = "application/json"},
		Body = HttpService:JSONEncode(arg2),
	})

	if not ok then
		warn("Aurora sync: request errored: " .. tostring(result))
		return nil
	end

	if result.StatusCode ~= 200 then
		warn("Aurora sync: status " .. tostring(result.StatusCode))
		return nil
	end

	return result.Body
end

local function func24()
	flag2 = true
	num3 = num3 + 1
	local v1 = num3

	for _, v2 in ipairs(tbl14) do
		v2.Text = "checking..."
	end

	task.spawn(function()
		while flag2 and num3 == v1 do
			local v2 = func23(
				"https://rockstar-yoie.onrender.com/ping",
				{user = LocalPlayer.Name, job = game.JobId, version = "1"}
			)

			if v2 then
				local ok, result = pcall(HttpService.JSONDecode, HttpService, v2)
				if ok and type(result) == "table" and type(result.users) == "table" then
					local tbl = {}

					for _, user in ipairs(result.users) do
						if user ~= LocalPlayer.Name then
							table.insert(tbl, user)
						end
					end

					local str

					if #tbl == 0 then
						str = "Nobody in this server is using Aurora Addons go dominate!"
					elseif #tbl == 1 then
						str = tbl[1] .. " is using Aurora Addons"
					else
						str = table.concat(tbl, ", ") .. " are using Aurora Addons"
					end

					for _, v3 in ipairs(tbl14) do
						v3.Text = str
					end
				end
			end

			task.wait(15)
		end
	end)
end

local flag3 = false

local function func25(arg1)
	if getgenv then
		getgenv().AuroraAutoLoadOff = not arg1
	end

	if not arg1 or flag3 then
		return
	end

	if not queue_on_teleport then
		pcall(function() end)
		return
	end

	queue_on_teleport(([[
if getgenv().AuroraAutoLoadOff then return end
if not game:IsLoaded() then game.Loaded:Wait() end
task.wait(5)
local ok, err = pcall(function()
    loadstring(game:HttpGet("%s"))()
end)
if not ok then warn("Aurora autoload: " .. tostring(err)) end
]]):format("https://lualarp.vercel.app/api/load/307b74d2781eb685838c66f2fd1b6a1df086"))

	flag3 = true
	local str = "Aurora Addons"
	local str1 = "Auto load queued for teleports"
	local num = 3

	pcall(function()
		StarterGui:SetCore("SendNotification", {Title = str, Text = str1, Duration = num or 3})
	end)
end

local tbl15 = {
	Halloween = {
		BG = Color3.fromRGB(18, 12, 8),
		ROW = Color3.fromRGB(32, 20, 14),
		LINE = Color3.fromRGB(90, 45, 12),
		TEXT = Color3.fromRGB(170, 140, 110),
		TEXT_ON = Color3.fromRGB(255, 232, 200),
		TRACK_OFF = Color3.fromRGB(45, 30, 20),
		KNOB_OFF = Color3.fromRGB(110, 80, 50),
		ACCENT = Color3.fromRGB(255, 117, 24),
		KNOB_ON = Color3.fromRGB(18, 12, 8),
	},
	Israel = {
		BG = Color3.fromRGB(14, 20, 34),
		ROW = Color3.fromRGB(22, 32, 52),
		LINE = Color3.fromRGB(40, 70, 130),
		TEXT = Color3.fromRGB(150, 170, 205),
		TEXT_ON = Color3.fromRGB(240, 244, 255),
		TRACK_OFF = Color3.fromRGB(34, 48, 76),
		KNOB_OFF = Color3.fromRGB(110, 140, 190),
		ACCENT = Color3.fromRGB(60, 130, 235),
		KNOB_ON = Color3.fromRGB(14, 20, 34),
	},
	Greece = {
		BG = Color3.fromRGB(12, 20, 38),
		ROW = Color3.fromRGB(20, 32, 58),
		LINE = Color3.fromRGB(50, 90, 160),
		TEXT = Color3.fromRGB(160, 180, 215),
		TEXT_ON = Color3.fromRGB(245, 248, 255),
		TRACK_OFF = Color3.fromRGB(32, 50, 84),
		KNOB_OFF = Color3.fromRGB(120, 150, 200),
		ACCENT = Color3.fromRGB(30, 100, 210),
		KNOB_ON = Color3.fromRGB(12, 20, 38),
	},
	Aurora = {
		BG = Color3.fromRGB(22, 22, 24),
		ROW = Color3.fromRGB(30, 30, 33),
		LINE = Color3.fromRGB(55, 55, 60),
		TEXT = Color3.fromRGB(150, 150, 156),
		TEXT_ON = Color3.fromRGB(230, 230, 234),
		TRACK_OFF = Color3.fromRGB(44, 44, 48),
		KNOB_OFF = Color3.fromRGB(95, 95, 102),
		ACCENT = Color3.fromRGB(140, 190, 120),
		KNOB_ON = Color3.fromRGB(22, 22, 24),
	},
	Ice = {
		BG = Color3.fromRGB(20, 24, 28),
		ROW = Color3.fromRGB(28, 34, 40),
		LINE = Color3.fromRGB(50, 60, 70),
		TEXT = Color3.fromRGB(140, 155, 170),
		TEXT_ON = Color3.fromRGB(228, 238, 245),
		TRACK_OFF = Color3.fromRGB(40, 48, 56),
		KNOB_OFF = Color3.fromRGB(90, 105, 118),
		ACCENT = Color3.fromRGB(120, 180, 230),
		KNOB_ON = Color3.fromRGB(20, 24, 28),
	},
	Ember = {
		BG = Color3.fromRGB(24, 20, 20),
		ROW = Color3.fromRGB(34, 28, 28),
		LINE = Color3.fromRGB(65, 52, 50),
		TEXT = Color3.fromRGB(165, 145, 140),
		TEXT_ON = Color3.fromRGB(240, 230, 226),
		TRACK_OFF = Color3.fromRGB(48, 40, 40),
		KNOB_OFF = Color3.fromRGB(110, 92, 88),
		ACCENT = Color3.fromRGB(230, 140, 90),
		KNOB_ON = Color3.fromRGB(24, 20, 20),
	},
	Mono = {
		BG = Color3.fromRGB(18, 18, 18),
		ROW = Color3.fromRGB(26, 26, 26),
		LINE = Color3.fromRGB(48, 48, 48),
		TEXT = Color3.fromRGB(135, 135, 135),
		TEXT_ON = Color3.fromRGB(235, 235, 235),
		TRACK_OFF = Color3.fromRGB(40, 40, 40),
		KNOB_OFF = Color3.fromRGB(90, 90, 90),
		ACCENT = Color3.fromRGB(230, 230, 230),
		KNOB_ON = Color3.fromRGB(18, 18, 18),
	},
	Rose = {
		BG = Color3.fromRGB(24, 18, 21),
		ROW = Color3.fromRGB(34, 25, 30),
		LINE = Color3.fromRGB(66, 46, 56),
		TEXT = Color3.fromRGB(170, 140, 155),
		TEXT_ON = Color3.fromRGB(244, 232, 238),
		TRACK_OFF = Color3.fromRGB(48, 36, 42),
		KNOB_OFF = Color3.fromRGB(110, 84, 98),
		ACCENT = Color3.fromRGB(230, 120, 160),
		KNOB_ON = Color3.fromRGB(24, 18, 21),
	},
	Violet = {
		BG = Color3.fromRGB(20, 18, 26),
		ROW = Color3.fromRGB(29, 26, 38),
		LINE = Color3.fromRGB(52, 46, 70),
		TEXT = Color3.fromRGB(145, 138, 165),
		TEXT_ON = Color3.fromRGB(232, 228, 244),
		TRACK_OFF = Color3.fromRGB(40, 36, 54),
		KNOB_OFF = Color3.fromRGB(92, 84, 120),
		ACCENT = Color3.fromRGB(170, 140, 235),
		KNOB_ON = Color3.fromRGB(20, 18, 26),
	},
}

local tbl16 = {"Halloween", "Israel", "Greece", "Aurora", "Ice", "Ember", "Mono", "Rose", "Violet"}
local v8 = tbl15[tbl1.theme] and tbl1.theme or "Halloween"
local v9 = tbl15[v8]
local GothamMedium = Enum.Font.GothamMedium
local tbl17 = {}
local tbl18 = {}
local tbl19 = {Halloween = "🎃", Israel = "🇮🇱", Greece = "🇬🇷"}
local tbl20 = {}

local function func26(className, arg2, parent)
	local instance = Instance.new(className)

	for k, v1 in pairs(arg2 or {}) do
		instance[k] = v1
	end

	if parent then
		instance.Parent = parent
	end

	return instance
end

local function func27(arg1)
	v8 = arg1
	v9 = tbl15[arg1]

	for _, v1 in ipairs(tbl17) do
		v1[1][v1[2]] = v9[v1[3]]
	end

	for _, v2 in ipairs(tbl18) do
		v2()
	end

	for k, v3 in pairs(tbl20) do
		for _, v4 in ipairs(v3) do
			v4.Visible = k == arg1
		end
	end
end

local function func28(arg1)
	local v1 = func26(
		"Frame",
		{Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 0},
		arg1
	)

-- https://leakd.fr
	for k, v2 in pairs(tbl19) do
		local tbl = {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Visible = false, ZIndex = 0}
		local frame = Instance.new("Frame")

		for k1, v3 in pairs(tbl or {}) do
			frame[k1] = v3
		end

		if v1 then
			frame.Parent = v1
		end

		for i = 0, 5 do
			local tbl1 = {
				Size = UDim2.fromOffset(40, 40),
				Position = UDim2.fromOffset(0 + i % 2 * 28 - 8, i * 56 - 10),
				BackgroundTransparency = 1,
				Text = v2,
				Font = GothamMedium,
				TextSize = 26,
				TextTransparency = 0.82,
				ZIndex = 0,
			}

			local textLabel = Instance.new("TextLabel")

			for k2, v4 in pairs(tbl1 or {}) do
				textLabel[k2] = v4
			end

			if frame then
				textLabel.Parent = frame
			end

			local tbl2 = {
				Size = UDim2.fromOffset(40, 40),
				Position = UDim2.fromOffset(56 + i % 2 * 28 - 8, i * 56 - 10),
				BackgroundTransparency = 1,
				Text = v2,
				Font = GothamMedium,
				TextSize = 26,
				TextTransparency = 0.82,
				ZIndex = 0,
			}

			local textLabel1 = Instance.new("TextLabel")

			for k3, v5 in pairs(tbl2 or {}) do
				textLabel1[k3] = v5
			end

			if frame then
				textLabel1.Parent = frame
			end

			local tbl3 = {
				Size = UDim2.fromOffset(40, 40),
				Position = UDim2.fromOffset(112 + i % 2 * 28 - 8, i * 56 - 10),
				BackgroundTransparency = 1,
				Text = v2,
				Font = GothamMedium,
				TextSize = 26,
				TextTransparency = 0.82,
				ZIndex = 0,
			}

			local textLabel2 = Instance.new("TextLabel")

			for k4, v6 in pairs(tbl3 or {}) do
				textLabel2[k4] = v6
			end

			if frame then
				textLabel2.Parent = frame
			end

			local tbl4 = {
				Size = UDim2.fromOffset(40, 40),
				Position = UDim2.fromOffset(168 + i % 2 * 28 - 8, i * 56 - 10),
				BackgroundTransparency = 1,
				Text = v2,
				Font = GothamMedium,
				TextSize = 26,
				TextTransparency = 0.82,
				ZIndex = 0,
			}

			local textLabel3 = Instance.new("TextLabel")

			for k5, v7 in pairs(tbl4 or {}) do
				textLabel3[k5] = v7
			end

			if frame then
				textLabel3.Parent = frame
			end

			local tbl5 = {
				Size = UDim2.fromOffset(40, 40),
				Position = UDim2.fromOffset(224 + i % 2 * 28 - 8, i * 56 - 10),
				BackgroundTransparency = 1,
				Text = v2,
				Font = GothamMedium,
				TextSize = 26,
				TextTransparency = 0.82,
				ZIndex = 0,
			}

			local textLabel4 = Instance.new("TextLabel")

			for k6, v8 in pairs(tbl5 or {}) do
				textLabel4[k6] = v8
			end

			if frame then
				textLabel4.Parent = frame
			end
		end

		tbl20[k] = tbl20[k] or {}
		table.insert(tbl20[k], frame)
	end

	return v1
end

local function func29(arg1, arg2, arg3, arg4)
	local v1 = func26("TextButton", {
		Position = arg3,
		Size = arg4,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = arg2,
		Font = GothamMedium,
		TextSize = 11,
	}, arg1)

	func26("UICorner", {CornerRadius = UDim.new(0, 6)}, v1)
	table.insert(tbl17, {v1, "BackgroundColor3", "ROW"})
	v1.BackgroundColor3 = v9.ROW
	table.insert(tbl17, {v1, "TextColor3", "TEXT"})
	v1.TextColor3 = v9.TEXT
	return v1
end

local function func30(arg1, arg2, arg3, arg4, arg5)
	local v1 = func26("TextLabel", {
		Position = arg3,
		Size = arg4,
		BackgroundTransparency = 1,
		Text = arg2,
		Font = GothamMedium,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, arg1)

	local v2 = arg5 or "TEXT"
	table.insert(tbl17, {v1, "TextColor3", v2})
	v1.TextColor3 = v9[v2]
	return v1
end

local function func31(arg1)
	return arg1.UserInputType == Enum.UserInputType.MouseButton1 or arg1.UserInputType == Enum.UserInputType.Touch
end

local function func32(arg1)
	return arg1.UserInputType == Enum.UserInputType.MouseMovement or arg1.UserInputType == Enum.UserInputType.Touch
end

local function func33(arg1, arg2)
	local flag
	local Position
	local Position1

	arg2.InputBegan:Connect(function(input)
		if func31(input) then
			flag = true
			Position = input.Position
			Position1 = arg1.Position
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if func31(input) then
			flag = false
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if flag and func32(input) then
			local v1 = input.Position - Position
			arg1.Position = UDim2.new(Position1.X.Scale, Position1.X.Offset + v1.X, Position1.Y.Scale, Position1.Y.Offset + v1.Y)
		end
	end)
end

local function func34(arg1, arg2, arg3, arg4, arg5, arg6)
	if arg4 then
		tbl5[arg3] = arg4
	end

	if tbl3[arg3] == nil then
		tbl3[arg3] = false
	end

	tbl6[arg3] = tbl6[arg3] or {}

	local v1 = func26("TextButton", {
		Size = UDim2.new(1, 0, 0, 30),
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
		LayoutOrder = arg2,
	}, arg5)

	func26("UICorner", {CornerRadius = UDim.new(0, 8)}, v1)
	local v2 = func26("UIStroke", {Thickness = 1}, v1)

	local tbl = {
		Size = UDim2.new(1, -50, 1, 0),
		Position = UDim2.new(0, 10, 0, 0),
		BackgroundTransparency = 1,
		Text = arg1,
		Font = GothamMedium,
		TextSize = 12,
	}

	tbl.TextXAlignment = Enum.TextXAlignment.Left
	tbl.TextTruncate = Enum.TextTruncate.AtEnd
	local v3 = func26("TextLabel", tbl, v1)

	local v4 = func26(
		"Frame",
		{Size = UDim2.new(0, 24, 0, 12), Position = UDim2.new(1, -34, 0.5, -6), BorderSizePixel = 0},
		v1
	)

	func26("UICorner", {CornerRadius = UDim.new(1, 0)}, v4)

	local v5 = func26(
		"Frame",
		{Size = UDim2.new(0, 8, 0, 8), Position = UDim2.new(0, 2, 0.5, -4), BorderSizePixel = 0},
		v4
	)

	func26("UICorner", {CornerRadius = UDim.new(1, 0)}, v5)
	table.insert(tbl17, {v1, "BackgroundColor3", "ROW"})
	v1.BackgroundColor3 = v9.ROW
	table.insert(tbl17, {v2, "Color", "LINE"})
	v2.Color = v9.LINE
	table.insert(tbl17, {v3, "TextColor3", "TEXT"})
	v3.TextColor3 = v9.TEXT

	local function func()
		local v1 = tbl3[arg3]
		v4.BackgroundColor3 = v1 and v9.ACCENT or v9.TRACK_OFF
		v5.BackgroundColor3 = v1 and v9.KNOB_ON or v9.KNOB_OFF
		v5.Position = v1 and UDim2.new(1, -10, 0.5, -4) or UDim2.new(0, 2, 0.5, -4)
		v3.TextColor3 = v1 and v9.TEXT_ON or v9.TEXT
	end

	table.insert(tbl6[arg3], func)
	table.insert(tbl18, func)
	func()

	v1.MouseButton1Click:Connect(function()
		func3(arg3, not tbl3[arg3])
		func2(arg3, tbl3[arg3])
	end)

	if arg6 then
		v1.MouseButton2Click:Connect(arg6)
	end

	tbl4[arg3] = function(arg1)
		func3(arg3, arg1)
	end

	return v1
end

local v10 = gethui and gethui() or LocalPlayer:WaitForChild("PlayerGui")

for _, v11 in ipairs({
	"AuroraUI",
	"AuroraToggle",
	"AuroraWatermark",
	"AuroraPresence",
	"AuroraSettings",
	"AuroraCursor",
	"AuroraRagebot",
}) do
	local v12 = v10:FindFirstChild(v11)
	if v12 then
		v12:Destroy()
	end
end

local v13 = func26("ScreenGui", {
	Name = "AuroraUI",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 500,
}, v10)

local v14 = func26("ScreenGui", {
	Name = "AuroraToggle",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 600,
}, v10)

local v15 = func26("ScreenGui", {
	Name = "AuroraWatermark",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 400,
}, v10)

local v16 = func26("ScreenGui", {
	Name = "AuroraPresence",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 400,
}, v10)

local v17 = func26("ScreenGui", {
	Name = "AuroraSettings",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 501,
}, v10)

local v18 = func26("ScreenGui", {
	Name = "AuroraRagebot",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 502,
}, v10)

local v19 = func26(
	"ScreenGui",
	{Name = "AuroraCursor", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 10000},
	v10
)

v17.Enabled = false
v18.Enabled = false
v13.Enabled = false
v19.Enabled = false

local v20 = func26("Frame", {
	Size = UDim2.new(0, 8, 0, 8),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromOffset(0, 0),
	BackgroundColor3 = Color3.fromRGB(240, 240, 240),
	BorderSizePixel = 0,
}, v19)

func26("UICorner", {CornerRadius = UDim.new(1, 0)}, v20)
func26("UIStroke", {Thickness = 1, Color = Color3.fromRGB(10, 10, 10)}, v20)
local v25
local v26

local function func35(arg1, arg2)
	v20.Position = UDim2.fromOffset(arg1 + vector2.X, arg2 + vector2.Y)
end

UserInputService.InputChanged:Connect(function(input)
	if TouchEnabled or not v13.Enabled then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		func35(input.Position.X, input.Position.Y)
	end
end)

local function func36()
	if v13.Enabled then
		v25 = v25 or {UserInputService.MouseBehavior, UserInputService.MouseIconEnabled}

		v26 = v26 or RunService.RenderStepped:Connect(function()
			if not v13.Enabled then
				return
			end

			UserInputService.MouseBehavior = Enum.MouseBehavior.Default

			if not TouchEnabled then
				UserInputService.MouseIconEnabled = false
				local MouseLocation = UserInputService:GetMouseLocation()
				func35(MouseLocation.X, MouseLocation.Y)
			end
		end)

		v19.Enabled = not TouchEnabled

		if not TouchEnabled then
			local MouseLocation = UserInputService:GetMouseLocation()
			func35(MouseLocation.X, MouseLocation.Y)
		end
	else
		if v26 then
			v26:Disconnect()
			v26 = nil
		end

		v19.Enabled = false

		if v25 then
			UserInputService.MouseBehavior = v25[1]
			UserInputService.MouseIconEnabled = v25[2]
			v25 = nil
		end
	end
end

local v27
local tbl21 = {}

local function func37(current)
	tbl1.current = current
	local v1 = tbl1.profiles[current] or {}

	for k, v2 in pairs(tbl4) do
		v2(v1[k] == true)
	end

	func()

	for _, v3 in ipairs(tbl21) do
		v3.Text = tbl1.current
	end
end

local function func38(arg1)
	local v1 = func1()
	local num = 1

	for i, v2 in ipairs(v1) do
		if v2 == tbl1.current then
			num = i
		end
	end

	func37(v1[(num - 1 + arg1) % #v1 + 1])
end

local function func39()
	local v1 = v27.Text:gsub("^%s+", ""):gsub("%s+$", "")
	local v2 = v1

	if v1 == "" then
		v2 = tbl1.current
	end

	tbl1.profiles[v2] = func4()
	tbl1.current = v2
	func()

	for _, v3 in ipairs(tbl21) do
		v3.Text = tbl1.current
	end
end

local function func40()
	local v1 = v27.Text:gsub("^%s+", ""):gsub("%s+$", "")
	if tbl1.profiles[v1] then
		func37(v1)
	else
		warn("Aurora: no config named " .. v1)
	end
end

local function func41()
	local v1 = v27.Text:gsub("^%s+", ""):gsub("%s+$", "")

	if v1 == "" or tbl1.profiles[v1] then
		warn("Aurora: name empty or already taken")
		return
	end

	tbl1.profiles[v1] = {}
	func37(v1)
end

local function func42()
	local v1 = v27.Text:gsub("^%s+", ""):gsub("%s+$", "")

	if v1 == "" or tbl1.profiles[v1] then
		warn("Aurora: name empty or already taken")
		return
	end

	tbl1.profiles[v1] = tbl1.profiles[tbl1.current]
	tbl1.profiles[tbl1.current] = nil
	tbl1.current = v1
	func()

	for _, v2 in ipairs(tbl21) do
		v2.Text = tbl1.current
	end
end

local function func43()
	if #func1() <= 1 then
		warn("Aurora: can't delete the last config")
		return
	end

	tbl1.profiles[tbl1.current] = nil
	func37(func1()[1])
end

local function func44(arg1, arg2, arg3, arg4, arg5)
	for i, v1 in ipairs(tbl16) do
		local v2 = (i - 1) % 3
		local v3 = math.floor((i - 1) / 3)
		local v4 = func29(arg1, v1:lower(), UDim2.new(0, arg2 + v2 * arg5, 0, arg3 + v3 * 28), UDim2.new(0, arg4, 0, 24))

		table.insert(tbl18, function()
			v4.TextColor3 = v8 == v1 and v9.TEXT_ON or v9.TEXT
		end)

		v4.MouseButton1Click:Connect(function()
			func27(v1)
			tbl1.theme = v1
			func()
		end)
	end
end

local tbl22 = {
	{
		label = "Gun Bypass",
		key = "gun",
		cb = function(arg1)
			func5("Gun", arg1)
		end,
	},
	{
		label = "Melee Bypass",
		key = "melee",
		cb = function(arg1)
			func5("Cooldown", arg1)
		end,
	},
	{label = "Orbit", key = "orbit", cb = func9},
	{label = "Void Spam", key = "void", cb = func10},
	{label = "TP To Enemy", key = "tp", cb = func11},
	{
		label = "ragebot (not recommended)",
		key = "rage",
		cb = func22,
		right = (function()
			local v1 = func26(
				"Frame",
				{Size = UDim2.new(0, 220, 0, 232), Position = UDim2.new(0, 520, 0, 120), BorderSizePixel = 0},
				v18
			)

			func26("UICorner", {CornerRadius = UDim.new(0, 20)}, v1)
			local v3 = func26("UIStroke", {Thickness = 1}, v1)
			table.insert(tbl17, {v1, "BackgroundColor3", "BG"})
			v1.BackgroundColor3 = v9.BG
			table.insert(tbl17, {v3, "Color", "LINE"})
			v3.Color = v9.LINE

			if TouchEnabled then
				func26("UIScale", {Scale = v2}, v1)
			end

			func28(v1)

			local v4 = func26("TextLabel", {
				Size = UDim2.new(1, -50, 0, 30),
				BackgroundTransparency = 1,
				Text = "ragebot settings",
				Font = GothamMedium,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
			}, v1)

			func26("UIPadding", {PaddingLeft = UDim.new(0, 12)}, v4)
			table.insert(tbl17, {v4, "TextColor3", "TEXT_ON"})
			v4.TextColor3 = v9.TEXT_ON
			func33(v1, v4)

			func29(v1, "x", UDim2.new(1, -34, 0, 5), UDim2.new(0, 24, 0, 20)).MouseButton1Click:Connect(function()
				v18.Enabled = false
			end)

			local v5 = func26(
				"Frame",
				{Size = UDim2.new(1, -24, 0, 1), Position = UDim2.new(0, 12, 0, 30), BorderSizePixel = 0},
				v1
			)

			table.insert(tbl17, {v5, "BackgroundColor3", "LINE"})
			v5.BackgroundColor3 = v9.LINE
			local v6 = func29(v1, "", UDim2.new(0, 12, 0, 44), UDim2.new(1, -24, 0, 28))
			local v7 = func29(v1, "", UDim2.new(0, 12, 0, 80), UDim2.new(1, -24, 0, 28))
			local v8 = func29(v1, "", UDim2.new(0, 12, 0, 116), UDim2.new(1, -24, 0, 28))
			local v10 = func29(v1, "", UDim2.new(0, 12, 0, 152), UDim2.new(1, -24, 0, 28))
			local v11 = func29(v1, "", UDim2.new(0, 12, 0, 188), UDim2.new(1, -24, 0, 28))

			local function func1()
				v6.Text = "weapon: " .. rage.weaponSlot:lower()
				v7.Text = "fire rate: " .. tostring(tbl11[rage.fireRateIdx])
				v8.Text = "range: " .. tostring(tbl12[rage.rangeIdx])
				v10.Text = "desync: " .. (rage.desync and "on" or "off")
				v11.Text = "underground: " .. (rage.underground and "on" or "off")
			end

			v6.MouseButton1Click:Connect(function()
				local num = 1

				for i, v1 in ipairs(tbl9) do
					if v1 == rage.weaponSlot then
						num = i
					end
				end

				rage.weaponSlot = tbl9[num % #tbl9 + 1]
				func1()
				func()
			end)

			v7.MouseButton1Click:Connect(function()
				rage.fireRateIdx = rage.fireRateIdx % #tbl11 + 1
				func1()
				func()
			end)

			v8.MouseButton1Click:Connect(function()
				rage.rangeIdx = rage.rangeIdx % #tbl12 + 1
				func1()
				func()
			end)

			v10.MouseButton1Click:Connect(function()
				rage.desync = not rage.desync
				func1()
				func()
			end)

			v11.MouseButton1Click:Connect(function()
				rage.underground = not rage.underground
				func1()
				func()
				func21()
			end)

			func1()

			return function()
				func1()
				v18.Enabled = true
			end
		end)(),
	},
	{label = "Auto Load", key = "autoload", cb = func25},
}

local function func45()
	local v1 = func26(
		"Frame",
		{Size = UDim2.new(0, 240, 0, 290), Position = UDim2.new(0, 40, 0, 120), BorderSizePixel = 0},
		v13
	)

	func26("UICorner", {CornerRadius = UDim.new(0, 20)}, v1)
	local v3 = func26("UIStroke", {Thickness = 1}, v1)
	table.insert(tbl17, {v1, "BackgroundColor3", "BG"})
	v1.BackgroundColor3 = v9.BG
	table.insert(tbl17, {v3, "Color", "LINE"})
	v3.Color = v9.LINE

	if TouchEnabled then
		func26("UIScale", {Scale = v2}, v1)
	end

	func28(v1)

	local v4 = func26("TextLabel", {
		Size = UDim2.new(1, -50, 0, 30),
		BackgroundTransparency = 1,
		Text = "Aurora Addons",
		Font = GothamMedium,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, v1)

	func26("UIPadding", {PaddingLeft = UDim.new(0, 12)}, v4)
	table.insert(tbl17, {v4, "TextColor3", "TEXT_ON"})
	v4.TextColor3 = v9.TEXT_ON

	local v5 = func26("TextButton", {
		Size = UDim2.new(0, 32, 0, 20),
		Position = UDim2.new(1, -42, 0, 5),
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "⚙️",
		Font = GothamMedium,
		TextSize = 11,
	}, v1)

	func26("UICorner", {CornerRadius = UDim.new(0, 6)}, v5)
	table.insert(tbl17, {v5, "BackgroundColor3", "ROW"})
	v5.BackgroundColor3 = v9.ROW
	table.insert(tbl17, {v5, "TextColor3", "TEXT"})
	v5.TextColor3 = v9.TEXT

	v5.MouseButton1Click:Connect(function()
		v17.Enabled = true
	end)

	local v6 = func26(
		"Frame",
		{Size = UDim2.new(1, -24, 0, 1), Position = UDim2.new(0, 12, 0, 30), BorderSizePixel = 0},
		v1
	)

	table.insert(tbl17, {v6, "BackgroundColor3", "LINE"})
	v6.BackgroundColor3 = v9.LINE

	local v7 = func26(
		"Frame",
		{Size = UDim2.new(1, -16, 1, -40), Position = UDim2.new(0, 8, 0, 38), BackgroundTransparency = 1},
		v1
	)

	func26("UIListLayout", {Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder}, v7)
	func33(v1, v4)

	for i, v8 in ipairs(tbl22) do
		func34(v8.label, i, v8.key, v8.cb, v7, v8.right)
	end

	if TouchEnabled then
		local v10 = func26("TextButton", {
			Size = UDim2.new(0, 58, 0, 58),
			Position = UDim2.new(0, 10, 0.5, -29),
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Text = "Addons",
			Font = GothamMedium,
			TextSize = 11,
		}, v14)

		func26("UICorner", {CornerRadius = UDim.new(1, 0)}, v10)
		local v11 = func26("UIStroke", {Thickness = 1}, v10)
		table.insert(tbl17, {v10, "BackgroundColor3", "BG"})
		v10.BackgroundColor3 = v9.BG
		table.insert(tbl17, {v10, "TextColor3", "TEXT_ON"})
		v10.TextColor3 = v9.TEXT_ON
		table.insert(tbl17, {v11, "Color", "LINE"})
		v11.Color = v9.LINE
		local flag
		local Position
		local Position1
		local flag1

		v10.InputBegan:Connect(function(input)
			if func31(input) then
				flag = true
				flag1 = false
				Position = input.Position
				Position1 = v10.Position
			end
		end)

		UserInputService.InputChanged:Connect(function(input)
			if flag and func32(input) then
				local v1 = input.Position - Position

				if v1.Magnitude > 5 then
					flag1 = true
				end

				v10.Position = UDim2.new(Position1.X.Scale, Position1.X.Offset + v1.X, Position1.Y.Scale, Position1.Y.Offset + v1.Y)
			end
		end)

		UserInputService.InputEnded:Connect(function(input)
			if func31(input) then
				flag = false
			end
		end)

		v10.MouseButton1Click:Connect(function()
			if not flag1 then
				v13.Enabled = not v13.Enabled
				func36()
			end
		end)
	end
end

local function func46()
	local v1 = func26("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 8),
		Size = UDim2.new(0, 260, 0, 24),
		BorderSizePixel = 0,
	}, v15)

	func26("UICorner", {CornerRadius = UDim.new(0, 8)}, v1)
	local v4 = func26("UIStroke", {Thickness = 1}, v1)
	table.insert(tbl17, {v1, "BackgroundColor3", "BG"})
	v1.BackgroundColor3 = v9.BG
	table.insert(tbl17, {v4, "Color", "LINE"})
	v4.Color = v9.LINE

	if TouchEnabled then
		func26("UIScale", {Scale = v2}, v1)
	end

	local v5 = func26("TextLabel", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = "Aurora Addons",
		Font = GothamMedium,
		TextSize = 12,
	}, v1)

	table.insert(tbl17, {v5, "TextColor3", "TEXT_ON"})
	v5.TextColor3 = v9.TEXT_ON

	local v6 = func26("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, v3),
		Size = UDim2.new(0, 300, 0, 26),
		BorderSizePixel = 0,
		Font = GothamMedium,
		TextSize = 12,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Text = "checking...",
	}, v16)

	func26("UICorner", {CornerRadius = UDim.new(0, 8)}, v6)
	local v7 = func26("UIStroke", {Thickness = 1}, v6)
	table.insert(tbl17, {v6, "BackgroundColor3", "BG"})
	v6.BackgroundColor3 = v9.BG
	table.insert(tbl17, {v6, "TextColor3", "TEXT_ON"})
	v6.TextColor3 = v9.TEXT_ON
	table.insert(tbl17, {v7, "Color", "LINE"})
	v7.Color = v9.LINE

	if TouchEnabled then
		func26("UIScale", {Scale = v2}, v6)
	end

	table.insert(tbl14, v6)
	local num = 0
	local num1 = 0

	RunService.RenderStepped:Connect(function()
		num = num + 1
	end)

	task.spawn(function()
		while true do
			num1 = math.floor(num / 0.5 + 0.5)
			num = 0
			local format = string.format
			local v1 = num1

			local ok, result = pcall(function()
				return math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
			end)

			v5.Text = format("Aurora Addons | %d fps | %d ms", v1, ok and result or 0)
			task.wait(0.5)
		end
	end)
end;

(function()
	local v1 = func26(
		"Frame",
		{Size = UDim2.new(0, 220, 0, 330), Position = UDim2.new(0, 290, 0, 120), BorderSizePixel = 0},
		v17
	)

	func26("UICorner", {CornerRadius = UDim.new(0, 20)}, v1)
	local v3 = func26("UIStroke", {Thickness = 1}, v1)
	table.insert(tbl17, {v1, "BackgroundColor3", "BG"})
	v1.BackgroundColor3 = v9.BG
	table.insert(tbl17, {v3, "Color", "LINE"})
	v3.Color = v9.LINE

	if TouchEnabled then
		func26("UIScale", {Scale = v2}, v1)
	end

	func28(v1)

	local v4 = func26("TextLabel", {
		Size = UDim2.new(1, -50, 0, 30),
		BackgroundTransparency = 1,
		Text = "settings",
		Font = GothamMedium,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, v1)

	func26("UIPadding", {PaddingLeft = UDim.new(0, 12)}, v4)
	table.insert(tbl17, {v4, "TextColor3", "TEXT_ON"})
	v4.TextColor3 = v9.TEXT_ON

	func29(v1, "x", UDim2.new(1, -34, 0, 5), UDim2.new(0, 24, 0, 20)).MouseButton1Click:Connect(function()
		v17.Enabled = false
	end)

	local v5 = func26(
		"Frame",
		{Size = UDim2.new(1, -24, 0, 1), Position = UDim2.new(0, 12, 0, 30), BorderSizePixel = 0},
		v1
	)

	table.insert(tbl17, {v5, "BackgroundColor3", "LINE"})
	v5.BackgroundColor3 = v9.LINE
	func30(v1, "theme", UDim2.new(0, 12, 0, 38), UDim2.new(0, 120, 0, 18))
	func44(v1, 12, 56, 62, 66)
	func30(v1, "keybind", UDim2.new(0, 12, 0, 150), UDim2.new(0, 120, 0, 18))
	local v6 = func29(v1, tbl1.keybind, UDim2.new(0, 124, 0, 148), UDim2.new(0, 84, 0, 22))
	local flag = false

	v6.MouseButton1Click:Connect(function()
		flag = true
		v6.Text = "press key"
	end)

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if flag then
			if input.UserInputType == Enum.UserInputType.Keyboard then
				flag = false

				if input.KeyCode ~= Enum.KeyCode.Escape then
					tbl1.keybind = input.KeyCode.Name
					func()
				end

				v6.Text = tbl1.keybind
			end
			return
		end

		if gameProcessed then
			return
		end

		if input.KeyCode.Name == tbl1.keybind then
			v13.Enabled = not v13.Enabled
			func36()
		end
	end)

	func30(v1, "config", UDim2.new(0, 12, 0, 180), UDim2.new(0, 120, 0, 18))
	local v7 = func29(v1, "<", UDim2.new(0, 12, 0, 198), UDim2.new(0, 28, 0, 24))
	local v8 = func29(v1, ">", UDim2.new(0, 180, 0, 198), UDim2.new(0, 28, 0, 24))

	local v10 = func26("TextLabel", {
		Size = UDim2.new(0, 132, 0, 24),
		Position = UDim2.new(0, 44, 0, 198),
		BackgroundTransparency = 1,
		Text = tbl1.current,
		Font = GothamMedium,
		TextSize = 11,
	}, v1)

	table.insert(tbl17, {v10, "TextColor3", "TEXT_ON"})
	v10.TextColor3 = v9.TEXT_ON
	table.insert(tbl21, v10)

	v27 = func26("TextBox", {
		Size = UDim2.new(0, 196, 0, 24),
		Position = UDim2.new(0, 12, 0, 228),
		BorderSizePixel = 0,
		Text = "",
		PlaceholderText = "config name",
		ClearTextOnFocus = false,
		Font = GothamMedium,
		TextSize = 11,
	}, v1)

	local tbl = {CornerRadius = UDim.new(0, 6)}
	local v11 = v27
	func26("UICorner", tbl, v11)
	table.insert(tbl17, {v11, "BackgroundColor3", "ROW"})
	v11.BackgroundColor3 = v9.ROW
	local v12 = v27
	table.insert(tbl17, {v12, "TextColor3", "TEXT_ON"})
	v12.TextColor3 = v9.TEXT_ON
	local v14 = v27
	table.insert(tbl17, {v14, "PlaceholderColor3", "TEXT"})
	v14.PlaceholderColor3 = v9.TEXT
	local v15 = func29(v1, "save", UDim2.new(0, 12, 0, 258), UDim2.new(0, 62, 0, 24))
	local v16 = func29(v1, "load", UDim2.new(0, 79, 0, 258), UDim2.new(0, 62, 0, 24))
	local v18 = func29(v1, "new", UDim2.new(0, 146, 0, 258), UDim2.new(0, 62, 0, 24))
	local v19 = func29(v1, "rename", UDim2.new(0, 12, 0, 288), UDim2.new(0, 96, 0, 24))
	local v20 = func29(v1, "delete", UDim2.new(0, 112, 0, 288), UDim2.new(0, 96, 0, 24))
	func33(v1, v4)

	v7.MouseButton1Click:Connect(function()
		func38(-1)
	end)

	v8.MouseButton1Click:Connect(function()
		func38(1)
	end)

	v15.MouseButton1Click:Connect(func39)
	v16.MouseButton1Click:Connect(func40)
	v18.MouseButton1Click:Connect(func41)
	v19.MouseButton1Click:Connect(func42)
	v20.MouseButton1Click:Connect(func43)
end)()

func45()
func46()
func27(v8)
func37(tbl1.current)
func36()
func24()
print("Aurora Addons Loaded!")

-- https://leakd.fr
