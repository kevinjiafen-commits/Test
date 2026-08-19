-- This file was generated at discord.gg/syncrypt

local t1 = {}
local v2 = unpack or table.unpack
t1.value1 = game:GetService("Players")
t1.value2 = game:GetService("UserInputService")
t1.value3 = game:GetService("RunService")
t1.value4 = game:GetService("ReplicatedStorage")
t1.value5 = game:GetService("TweenService")
t1.value6 = game:GetService("Workspace")
t1.value7 = game:GetService("HttpService")
t1.value8 = t1.value1.LocalPlayer
local PlayerGui = t1.value8:WaitForChild("PlayerGui")
t1.value9 = t1.value2.TouchEnabled and not t1.value2.KeyboardEnabled
local v4 = not t1.value2.TouchEnabled
local color3 = Color3.fromRGB(100, 149, 237)
local color3_2 = Color3.fromRGB(18, 18, 24)
local color3_3 = Color3.fromRGB(28, 28, 38)
local color3_4 = Color3.fromRGB(38, 38, 50)
local color3_5 = Color3.fromRGB(240, 240, 245)
local color3_6 = Color3.fromRGB(160, 160, 175)
local color3_7 = Color3.fromRGB(46, 204, 113)
local color3_8 = Color3.fromRGB(60, 60, 70)
local color3_9 = Color3.fromRGB(100, 149, 237)
local color3_10 = Color3.fromRGB(40, 40, 50)
local color3_11 = Color3.fromRGB(45, 45, 58)
local GothamBold = Enum.Font.GothamBold
local GothamMedium = Enum.Font.GothamMedium
local color3_12 = Color3.fromRGB(130, 170, 255)
local color3_13 = Color3.fromRGB(50, 50, 65)
local color3_14 = Color3.fromRGB(70, 230, 130)
local color3_15 = Color3.fromRGB(80, 80, 95)
local color3_16 = Color3.fromRGB(70, 120, 210)
local color3_17 = Color3.fromRGB(35, 35, 45)
local color3_18 = Color3.fromRGB(35, 170, 95)
local color3_19 = Color3.fromRGB(45, 45, 55)
t1.value10 = {
	Accent = color3,
	Background = color3_2,
	Surface = color3_3,
	SurfaceLight = color3_4,
	Text = color3_5,
	TextSecondary = color3_6,
	ToggleOn = color3_7,
	ToggleOff = color3_8,
	TabActive = color3_9,
	TabInactive = color3_10,
	Border = color3_11,
	Font = GothamBold,
	FontMedium = GothamMedium,
	HoverAccent = color3_12,
	HoverSurface = color3_13,
	HoverToggleOn = color3_14,
	HoverToggleOff = color3_15,
	ClickAccent = color3_16,
	ClickSurface = color3_17,
	ClickToggleOn = color3_18,
	ClickToggleOff = color3_19
}
local t2 = {
	Ragebot = false,
	AutoShoot = false,
	AutoShootShootAttempt = 0,
	RapidFire = false,
	Fly = false,
	FlySpeed = 80,
	InfiniteJump = false,
	Noclip = false,
	Esp = false,
	EspBoxes = true,
	EspNames = true,
	EspHealth = true,
	EspDistance = false,
	EspHealthNumber = false,
	EspChams = false,
	AnimationEnabled = false,
	AnimationPreset = "Underground Glitch",
	AnimationSpeed = 2,
	AutoCollect = false,
	UnlockAll = false,
	FOVEnabled = false,
	FOVShow = true,
	FOVRadius = 100,
	FOVFollowMuzzle = false,
	FOVFilled = false,
	FOVSpin = false,
	FOVSpinSpeed = 1,
	FOVAnimated = false,
	AutoQueueEnabled = false,
	AutoQueueMode = "1v1",
	AutoLoadoutEnabled = false,
	PrimaryWeapon = "Assault Rifle",
	SecondaryWeapon = "Handgun",
	MeleeWeapon = "Katana",
	UtilityWeapon = "Medkit"
}
t1.value11 = nil
t1.value11 = t2
function t1.value12()
    pcall(function()
        if not isfolder or not makefolder then
            return
        end

        if not isfolder("private_scripts") then
            makefolder("private_scripts")
        end

        writefile("private_scripts/settings.json", t1.value7:JSONEncode(t1.value11))
    end)
end
local v27 = (function()
    local ok, result = pcall(function()
        if not isfolder or not makefolder then
            return nil
        end

        if not isfolder("private_scripts") then
            makefolder("private_scripts")
        end

        if isfile("private_scripts/settings.json") then
            local value7 = t1.value7
            local t3 = { readfile("private_scripts/settings.json") }

            return value7:JSONDecode(v2(t3))
        end

        return nil
    end)

    if ok and result then
        return result
    end

    return nil
end)()
if v27 then
    for k, _ in pairs(t1.value11) do
        local v30 = k

        if v27[v30] ~= nil then
            t1.value11[v30] = v27[v30]
        end
    end
end
function t1.value13(p1)
    if not p1 then
        return false
    end

    local Team = t1.value8.Team
    local v74 = Team and Team.TeamColor
    local TeamID = t1.value8:GetAttribute("TeamID")
    local Team2 = p1.Team
    local v77 = Team2 and Team2.TeamColor
    local TeamID2 = p1:GetAttribute("TeamID")

    if Team and (Team2 and Team == Team2) then
        return true
    end

    if v74 and (v77 and v74 == v77) then
        return true
    end

    if TeamID and (TeamID2 and TeamID == TeamID2) then
        return true
    end

    return false
end
if PlayerGui:FindFirstChild("private") then
    PlayerGui.private:Destroy()
end
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "private"
ScreenGui.Parent = PlayerGui
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 999999
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
local v32 = if not v4 then math.min(500, t1.value6.CurrentCamera.ViewportSize.X - 20) else 400
local v33 = if not v4 then math.min(350, t1.value6.CurrentCamera.ViewportSize.Y * 0.4) else 400
t1.value14 = Instance.new("Frame")
t1.value14.Size = UDim2.new(0, v32, 0, v33)
t1.value14.Position = UDim2.new(0.5, -v32 / 2, 0.5, -v33 / 2)
t1.value14.BackgroundColor3 = t1.value10.Background
t1.value14.BackgroundTransparency = 0
t1.value14.BorderSizePixel = 0
t1.value14.Active = true
t1.value14.Visible = true
t1.value14.ZIndex = 10
t1.value14.Parent = ScreenGui
local UIStroke = Instance.new("UIStroke")
UIStroke.Color = t1.value10.Border
UIStroke.Thickness = 1
UIStroke.Transparency = 0.4
UIStroke.Parent = t1.value14
local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(1, 0, 0, 24)
Frame.BackgroundColor3 = t1.value10.Surface
Frame.BackgroundTransparency = 0
Frame.BorderSizePixel = 0
Frame.ZIndex = 11
Frame.Parent = t1.value14
local TextLabel = Instance.new("TextLabel")
TextLabel.Size = UDim2.new(0, 100, 0, 14)
TextLabel.Position = UDim2.new(0, 10, 0, 5)
TextLabel.BackgroundTransparency = 1
TextLabel.Text = "PRIVATE"
TextLabel.Font = t1.value10.Font
TextLabel.TextSize = 11
TextLabel.TextColor3 = t1.value10.Text
TextLabel.TextXAlignment = Enum.TextXAlignment.Left
TextLabel.ZIndex = 12
TextLabel.Parent = Frame
local TextButton = Instance.new("TextButton")
TextButton.Size = UDim2.new(0, 16, 0, 16)
TextButton.Position = UDim2.new(1, -22, 0, 4)
TextButton.BackgroundTransparency = 1
TextButton.Text = "X"
TextButton.Font = t1.value10.Font
TextButton.TextSize = 9
TextButton.TextColor3 = t1.value10.TextSecondary
TextButton.ZIndex = 12
TextButton.Parent = Frame
TextButton.MouseButton1Click:Connect(function()
    t1.value14.Visible = false

    if t1.value9 and ToggleBtn then
        ToggleBtn.Text = ">"
    end
end)
local Frame2 = Instance.new("Frame")
Frame2.Size = UDim2.new(1, 0, 0, 22)
Frame2.Position = UDim2.new(0, 0, 0, 24)
Frame2.BackgroundColor3 = t1.value10.Surface
Frame2.BackgroundTransparency = 0
Frame2.BorderSizePixel = 0
Frame2.ZIndex = 11
Frame2.Parent = t1.value14
local t4 = {
	{
		name = "Ragebot"
	},
	{
		name = "FOV"
	},
	{
		name = "ESP"
	},
	{
		name = "Unlock All"
	},
	{
		name = "Auto"
	},
	{
		name = "Misc"
	},
	{
		name = "Settings"
	}
}
t1.value15 = "Ragebot"
t1.value16 = {}
t1.value17 = {}
for v42, v43 in ipairs(t4) do

    local v44 = v43
    local TextButton2 = Instance.new("TextButton")

    TextButton2.Size = UDim2.new(0.14285714285714, -1.5, 0, 18)
    TextButton2.Position = UDim2.new((v42 - 1) * 0.14285714285714, 0.75, 0, 2)
    TextButton2.BackgroundColor3 = v44.name == t1.value15 and t1.value10.TabActive or t1.value10.TabInactive
    TextButton2.BackgroundTransparency = v44.name ~= t1.value15 and 0.5 or 0.3
    TextButton2.BorderSizePixel = 0
    TextButton2.Text = v44.name
    TextButton2.Font = t1.value10.Font
    TextButton2.TextSize = 6
    TextButton2.TextColor3 = t1.value10.Text
    TextButton2.ZIndex = 12
    TextButton2.AutoButtonColor = false
    TextButton2.Parent = Frame2
    t1.value16[v44.name] = TextButton2
    TextButton2.MouseEnter:Connect(function()
        local v79 = t1.value15 == v44.name
        local value5 = t1.value5
        local v81 = TextButton2
        local tweenInfo = TweenInfo.new(0.2)
        local v83 = v79 and t1.value10.HoverAccent or t1.value10.HoverSurface
        local Create = value5.Create
        local v85 = not v79 and 0.3 or 0.2

        Create(value5, v81, tweenInfo, {
			BackgroundColor3 = v83,
			BackgroundTransparency = v85
		}):Play()
    end)
    TextButton2.MouseLeave:Connect(function()
        local v86 = t1.value15 == v44.name
        local value5 = t1.value5
        local v88 = TextButton2
        local tweenInfo = TweenInfo.new(0.2)
        local v90 = v86 and t1.value10.TabActive or t1.value10.TabInactive
        local v91 = not v86 and 0.5 or 0.3

        value5:Create(v88, tweenInfo, {
			BackgroundColor3 = v90,
			BackgroundTransparency = v91
		}):Play()
    end)
    TextButton2.MouseButton1Down:Connect(function()
        t1.value5:Create(TextButton2, TweenInfo.new(0.05), {
			BackgroundColor3 = t1.value10.ClickAccent,
			BackgroundTransparency = 0.1
		}):Play()
    end)
    TextButton2.MouseButton1Up:Connect(function()
        local v92 = t1.value15 == v44.name
        local value5 = t1.value5
        local v94 = TextButton2
        local tweenInfo = TweenInfo.new(0.1)
        local v96 = v92 and t1.value10.HoverAccent or t1.value10.HoverSurface
        local v97 = not v92 and 0.3 or 0.2

        value5:Create(v94, tweenInfo, {
			BackgroundColor3 = v96,
			BackgroundTransparency = v97
		}):Play()
    end)

    local Frame3 = Instance.new("Frame")

    Frame3.Size = UDim2.new(1, 0, 1, -46)
    Frame3.Position = UDim2.new(0, 0, 0, 46)
    Frame3.BackgroundTransparency = 1
    Frame3.BorderSizePixel = 0
    Frame3.Visible = v44.name == t1.value15
    Frame3.ZIndex = 11
    Frame3.Parent = t1.value14

    local ScrollingFrame = Instance.new("ScrollingFrame")

    ScrollingFrame.Size = UDim2.new(1, 0, 1, 0)
    ScrollingFrame.BackgroundTransparency = 1
    ScrollingFrame.BorderSizePixel = 0
    ScrollingFrame.ScrollBarThickness = 2
    ScrollingFrame.ScrollBarImageColor3 = t1.value10.Accent
    ScrollingFrame.ScrollBarImageTransparency = 0.5
    ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 200)
    ScrollingFrame.ZIndex = 12
    ScrollingFrame.Parent = Frame3

    local UIPadding = Instance.new("UIPadding")

    UIPadding.PaddingTop = UDim.new(0, 4)
    UIPadding.PaddingLeft = UDim.new(0, 8)
    UIPadding.PaddingRight = UDim.new(0, 8)
    UIPadding.Parent = ScrollingFrame

    local UIGridLayout = Instance.new("UIGridLayout")

    UIGridLayout.CellPadding = UDim2.new(0, 4, 0, 3)
    UIGridLayout.CellSize = UDim2.new(0.5, -6, 0, 32)
    UIGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    UIGridLayout.Parent = ScrollingFrame
    t1.value17[v44.name] = {
		frame = Frame3,
		scroll = ScrollingFrame,
		layout = UIGridLayout
	}
end
for k, v in pairs(t1.value16) do
    v.MouseButton1Click:Connect(function()

        for v100, v101 in pairs(t1.value16) do

            if v100 == k then
                t1.value5:Create(v101, TweenInfo.new(0.2), {
					BackgroundColor3 = t1.value10.TabActive,
					BackgroundTransparency = 0.3
				}):Play()
            else
                t1.value5:Create(v101, TweenInfo.new(0.2), {
					BackgroundColor3 = t1.value10.TabInactive,
					BackgroundTransparency = 0.5
				}):Play()
            end
        end
        for k2, v3 in pairs(t1.value17) do
            v3.frame.Visible = k2 == k
        end
    end)
end
local function v52(p2, p3, p4, p5, p6, p7, p8, p9, p10)
    local v113 = t1.value17[p2]

    if not v113 then
        return
    end

    local Frame4 = Instance.new("Frame")

    Frame4.Size = UDim2.new(1, 0, 0, 48)
    Frame4.BackgroundColor3 = t1.value10.Surface
    Frame4.BackgroundTransparency = 0
    Frame4.BorderSizePixel = 0
    Frame4.ZIndex = 12
    Frame4.Parent = v113.scroll

    local TextLabel2 = Instance.new("TextLabel")

    TextLabel2.Size = UDim2.new(0, 80, 0, 10)
    TextLabel2.Position = UDim2.new(0, 6, 0, 3)
    TextLabel2.BackgroundTransparency = 1
    TextLabel2.Text = p3
    TextLabel2.Font = t1.value10.FontMedium
    TextLabel2.TextSize = 8
    TextLabel2.TextColor3 = t1.value10.Text
    TextLabel2.TextXAlignment = Enum.TextXAlignment.Left
    TextLabel2.ZIndex = 13
    TextLabel2.Parent = Frame4

    local TextButton3 = Instance.new("TextButton")

    TextButton3.Size = UDim2.new(0, 28, 0, 16)
    TextButton3.Position = UDim2.new(1, -34, 0, 2)
    TextButton3.BackgroundColor3 = t1.value11[p4] and t1.value10.ToggleOn or t1.value10.ToggleOff
    TextButton3.BorderSizePixel = 0
    TextButton3.Text = ""
    TextButton3.AutoButtonColor = false
    TextButton3.ZIndex = 13
    TextButton3.Parent = Frame4

    local Frame5 = Instance.new("Frame")

    Frame5.Size = UDim2.new(0, 12, 0, 12)
    Frame5.Position = t1.value11[p4] and UDim2.new(0, 15, 0, 2) or UDim2.new(0, 1, 0, 2)
    Frame5.BackgroundColor3 = Color3.new(1, 1, 1)
    Frame5.BorderSizePixel = 0
    Frame5.ZIndex = 14
    Frame5.Parent = TextButton3

    local TextLabel3 = Instance.new("TextLabel")

    TextLabel3.Size = UDim2.new(0, 40, 0, 10)
    TextLabel3.Position = UDim2.new(1, -46, 0, 22)
    TextLabel3.BackgroundTransparency = 1

    local str = tostring(t1.value11[p7] or p5)
    local v120 = p8

    if not v120 then
        v120 = ""
    end

    TextLabel3.Text = str .. v120
    TextLabel3.Font = t1.value10.FontMedium
    TextLabel3.TextSize = 8
    TextLabel3.TextColor3 = t1.value10.Accent
    TextLabel3.TextXAlignment = Enum.TextXAlignment.Right
    TextLabel3.ZIndex = 13
    TextLabel3.Parent = Frame4

    local Frame6 = Instance.new("Frame")

    Frame6.Size = UDim2.new(1, -12, 0, 2)
    Frame6.Position = UDim2.new(0, 6, 0, 36)
    Frame6.BackgroundColor3 = t1.value10.SurfaceLight
    Frame6.BorderSizePixel = 0
    Frame6.ZIndex = 13
    Frame6.Parent = Frame4

    local Frame7 = Instance.new("Frame")
    local v123 = (t1.value11[p7] or p5 - p5) / (p6 - p5)

    Frame7.Size = UDim2.new(v123, 0, 1, 0)
    Frame7.BackgroundColor3 = t1.value10.Accent
    Frame7.BorderSizePixel = 0
    Frame7.ZIndex = 14
    Frame7.Parent = Frame6

    local Frame8 = Instance.new("Frame")

    Frame8.Size = UDim2.new(0, 10, 0, 10)
    Frame8.Position = UDim2.new(1, -5, 0.5, -5)
    Frame8.BackgroundColor3 = Color3.new(1, 1, 1)
    Frame8.BorderSizePixel = 0
    Frame8.ZIndex = 15
    Frame8.Parent = Frame7
    TextButton3.MouseButton1Click:Connect(function()
        local v481 = t1.value11[p4]

        t1.value11[p4] = not v481
        t1.value12()

        if t1.value11[p4] then
            t1.value5:Create(TextButton3, TweenInfo.new(0.2), {
				BackgroundColor3 = t1.value10.ToggleOn
			}):Play()
            t1.value5:Create(Frame5, TweenInfo.new(0.2), {
				Position = UDim2.new(0, 15, 0, 2)
			}):Play()
        else
            t1.value5:Create(TextButton3, TweenInfo.new(0.2), {
				BackgroundColor3 = t1.value10.ToggleOff
			}):Play()
            t1.value5:Create(Frame5, TweenInfo.new(0.2), {
				Position = UDim2.new(0, 1, 0, 2)
			}):Play()
        end

        if p9 then
            p9(t1.value11[p4])
        end
    end)

    local function v125(p11)
        local v483 = math.clamp((p11.Position.X - Frame6.AbsolutePosition.X) / Frame6.AbsoluteSize.X, 0, 1)
        local v484 = math.floor(p5 + (p6 - p5) * v483)

        t1.value11[p7] = v484
        t1.value12()
        TextLabel3.Text = tostring(v484) .. (p8 or "")
        t1.value5:Create(Frame7, TweenInfo.new(0.1), {
			Size = UDim2.new(v483, 0, 1, 0)
		}):Play()

        if p10 then
            p10(v484)
        end
    end

    Frame6.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            v125(input)
            local connection
            local connection2 = t1.value2.InputChanged:Connect(function(input2)
                if input2.UserInputType == Enum.UserInputType.MouseMovement or input2.UserInputType == Enum.UserInputType.Touch then
                    v125(input2)
                end
            end)
            connection = t1.value2.InputEnded:Connect(function(input3)
                if input3.UserInputType == Enum.UserInputType.MouseButton1 or input3.UserInputType == Enum.UserInputType.Touch then
                    if connection2 then
                        connection2:Disconnect()
                    end

                    if connection then
                        connection:Disconnect()
                    end
                end
            end)
        end
    end)

    return Frame4
end
local function v53(p12, p13, p14, p15)
    local v130 = t1.value17[p12]

    if not v130 then
        return
    end

    local Frame9 = Instance.new("Frame")

    Frame9.Size = UDim2.new(1, 0, 1, 0)
    Frame9.BackgroundColor3 = t1.value10.Surface
    Frame9.BackgroundTransparency = 0
    Frame9.BorderSizePixel = 0
    Frame9.ZIndex = 12
    Frame9.Parent = v130.scroll

    local TextLabel4 = Instance.new("TextLabel")

    TextLabel4.Size = UDim2.new(0, 80, 0, 12)
    TextLabel4.Position = UDim2.new(0, 6, 0, 4)
    TextLabel4.BackgroundTransparency = 1
    TextLabel4.Text = p13
    TextLabel4.Font = t1.value10.FontMedium
    TextLabel4.TextSize = 9
    TextLabel4.TextColor3 = t1.value10.Text
    TextLabel4.TextXAlignment = Enum.TextXAlignment.Left
    TextLabel4.ZIndex = 13
    TextLabel4.Parent = Frame9

    local TextButton4 = Instance.new("TextButton")

    TextButton4.Size = UDim2.new(0, 28, 0, 16)
    TextButton4.Position = UDim2.new(1, -34, 0, 4)
    TextButton4.BackgroundColor3 = t1.value11[p14] and t1.value10.ToggleOn or t1.value10.ToggleOff
    TextButton4.BorderSizePixel = 0
    TextButton4.Text = ""
    TextButton4.AutoButtonColor = false
    TextButton4.ZIndex = 13
    TextButton4.Parent = Frame9

    local Frame10 = Instance.new("Frame")

    Frame10.Size = UDim2.new(0, 12, 0, 12)
    Frame10.Position = t1.value11[p14] and UDim2.new(0, 15, 0, 2) or UDim2.new(0, 1, 0, 2)
    Frame10.BackgroundColor3 = Color3.new(1, 1, 1)
    Frame10.BorderSizePixel = 0
    Frame10.ZIndex = 14
    Frame10.Parent = TextButton4
    TextButton4.MouseButton1Click:Connect(function()
        local v488 = t1.value11[p14]

        t1.value11[p14] = not v488
        t1.value12()

        if t1.value11[p14] then
            t1.value5:Create(TextButton4, TweenInfo.new(0.2), {
				BackgroundColor3 = t1.value10.ToggleOn
			}):Play()
            t1.value5:Create(Frame10, TweenInfo.new(0.2), {
				Position = UDim2.new(0, 15, 0, 2)
			}):Play()
        else
            t1.value5:Create(TextButton4, TweenInfo.new(0.2), {
				BackgroundColor3 = t1.value10.ToggleOff
			}):Play()
            t1.value5:Create(Frame10, TweenInfo.new(0.2), {
				Position = UDim2.new(0, 1, 0, 2)
			}):Play()
        end

        if p15 then
            p15(t1.value11[p14])
        end
    end)

    return Frame9
end
local function v54(p16, p17, p18, p19, p20, p21, p22)
    local v142 = t1.value17[p16]

    if not v142 then
        return
    end

    local Frame11 = Instance.new("Frame")

    Frame11.Size = UDim2.new(1, 0, 1, 0)
    Frame11.BackgroundColor3 = t1.value10.Surface
    Frame11.BackgroundTransparency = 0
    Frame11.BorderSizePixel = 0
    Frame11.ZIndex = 12
    Frame11.Parent = v142.scroll

    local TextLabel5 = Instance.new("TextLabel")

    TextLabel5.Size = UDim2.new(0, 80, 0, 10)
    TextLabel5.Position = UDim2.new(0, 6, 0, 3)
    TextLabel5.BackgroundTransparency = 1
    TextLabel5.Text = p17
    TextLabel5.Font = t1.value10.FontMedium
    TextLabel5.TextSize = 8
    TextLabel5.TextColor3 = t1.value10.Text
    TextLabel5.TextXAlignment = Enum.TextXAlignment.Left
    TextLabel5.ZIndex = 13
    TextLabel5.Parent = Frame11

    local TextLabel6 = Instance.new("TextLabel")

    TextLabel6.Size = UDim2.new(0, 40, 0, 10)
    TextLabel6.Position = UDim2.new(1, -46, 0, 3)
    TextLabel6.BackgroundTransparency = 1

    local str = tostring(t1.value11[p20] or p18)
    local v147 = p21

    if not v147 then
        v147 = ""
    end

    TextLabel6.Text = str .. v147
    TextLabel6.Font = t1.value10.FontMedium
    TextLabel6.TextSize = 8
    TextLabel6.TextColor3 = t1.value10.Accent
    TextLabel6.TextXAlignment = Enum.TextXAlignment.Right
    TextLabel6.ZIndex = 13
    TextLabel6.Parent = Frame11

    local Frame12 = Instance.new("Frame")

    Frame12.Size = UDim2.new(1, -12, 0, 2)
    Frame12.Position = UDim2.new(0, 6, 0, 17)
    Frame12.BackgroundColor3 = t1.value10.SurfaceLight
    Frame12.BorderSizePixel = 0
    Frame12.ZIndex = 13
    Frame12.Parent = Frame11

    local Frame13 = Instance.new("Frame")
    local v150 = (t1.value11[p20] or p18 - p18) / (p19 - p18)

    Frame13.Size = UDim2.new(v150, 0, 1, 0)
    Frame13.BackgroundColor3 = t1.value10.Accent
    Frame13.BorderSizePixel = 0
    Frame13.ZIndex = 14
    Frame13.Parent = Frame12

    local Frame14 = Instance.new("Frame")

    Frame14.Size = UDim2.new(0, 10, 0, 10)
    Frame14.Position = UDim2.new(1, -5, 0.5, -5)
    Frame14.BackgroundColor3 = Color3.new(1, 1, 1)
    Frame14.BorderSizePixel = 0
    Frame14.ZIndex = 15
    Frame14.Parent = Frame13

    local function v152(p23)
        local v490 = math.clamp((p23.Position.X - Frame12.AbsolutePosition.X) / Frame12.AbsoluteSize.X, 0, 1)
        local v491 = math.floor(p18 + (p19 - p18) * v490)

        t1.value11[p20] = v491
        t1.value12()
        TextLabel6.Text = tostring(v491) .. (p21 or "")
        t1.value5:Create(Frame13, TweenInfo.new(0.1), {
			Size = UDim2.new(v490, 0, 1, 0)
		}):Play()

        if p22 then
            p22(v491)
        end
    end

    Frame12.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            v152(input)
            local connection
            local connection3 = t1.value2.InputChanged:Connect(function(input4)
                if input4.UserInputType == Enum.UserInputType.MouseMovement or input4.UserInputType == Enum.UserInputType.Touch then
                    v152(input4)
                end
            end)
            connection = t1.value2.InputEnded:Connect(function(input5)
                if input5.UserInputType == Enum.UserInputType.MouseButton1 or input5.UserInputType == Enum.UserInputType.Touch then
                    if connection3 then
                        connection3:Disconnect()
                    end

                    if connection then
                        connection:Disconnect()
                    end
                end
            end)
        end
    end)

    return Frame11
end
local function v55(p24, p25, p26, p27, p28)
    local v158 = t1.value17[p24]

    if not v158 then
        return
    end

    local Frame15 = Instance.new("Frame")

    Frame15.Size = UDim2.new(1, 0, 0, 48)
    Frame15.BackgroundColor3 = t1.value10.Surface
    Frame15.BackgroundTransparency = 0
    Frame15.BorderSizePixel = 0
    Frame15.ZIndex = 12
    Frame15.Parent = v158.scroll

    local TextLabel7 = Instance.new("TextLabel")

    TextLabel7.Size = UDim2.new(0, 80, 0, 10)
    TextLabel7.Position = UDim2.new(0, 6, 0, 3)
    TextLabel7.BackgroundTransparency = 1
    TextLabel7.Text = p25
    TextLabel7.Font = t1.value10.FontMedium
    TextLabel7.TextSize = 8
    TextLabel7.TextColor3 = t1.value10.Text
    TextLabel7.TextXAlignment = Enum.TextXAlignment.Left
    TextLabel7.ZIndex = 13
    TextLabel7.Parent = Frame15

    local TextButton5 = Instance.new("TextButton")

    TextButton5.Size = UDim2.new(1, -12, 0, 18)
    TextButton5.Position = UDim2.new(0, 6, 0, 16)
    TextButton5.BackgroundColor3 = t1.value10.SurfaceLight
    TextButton5.BorderSizePixel = 0
    TextButton5.Text = t1.value11[p26] or p27[1]
    TextButton5.Font = t1.value10.FontMedium
    TextButton5.TextSize = 8
    TextButton5.TextColor3 = t1.value10.Text
    TextButton5.ZIndex = 13
    TextButton5.AutoButtonColor = false
    TextButton5.Parent = Frame15

    local TextLabel8 = Instance.new("TextLabel")

    TextLabel8.Size = UDim2.new(0, 12, 0, 12)
    TextLabel8.Position = UDim2.new(1, -16, 0, 3)
    TextLabel8.BackgroundTransparency = 1
    TextLabel8.Text = "V"
    TextLabel8.Font = t1.value10.Font
    TextLabel8.TextSize = 7
    TextLabel8.TextColor3 = t1.value10.TextSecondary
    TextLabel8.ZIndex = 14
    TextLabel8.Parent = TextButton5

    local TextButton6 = Instance.new("TextButton")

    TextButton6.Size = UDim2.new(1, 0, 1, 0)
    TextButton6.BackgroundTransparency = 1
    TextButton6.Text = ""
    TextButton6.Visible = false
    TextButton6.ZIndex = 99
    TextButton6.Parent = v158.frame

    local Frame16 = Instance.new("Frame")

    Frame16.Size = UDim2.new(1, 0, 0, 0)
    Frame16.Position = UDim2.new(0, 0, 1, 2)
    Frame16.BackgroundColor3 = t1.value10.Surface
    Frame16.BackgroundTransparency = 0
    Frame16.BorderSizePixel = 0
    Frame16.ClipsDescendants = true
    Frame16.Visible = false
    Frame16.ZIndex = 100
    Frame16.Parent = v158.frame

    local ScrollingFrame = Instance.new("ScrollingFrame")

    ScrollingFrame.Size = UDim2.new(1, 0, 1, 0)
    ScrollingFrame.BackgroundTransparency = 1
    ScrollingFrame.BorderSizePixel = 0
    ScrollingFrame.ScrollBarThickness = 2
    ScrollingFrame.ScrollBarImageColor3 = t1.value10.Accent
    ScrollingFrame.ScrollBarImageTransparency = 0.5
    ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, #p27 * 22)
    ScrollingFrame.ZIndex = 101
    ScrollingFrame.ScrollingDirection = Enum.ScrollingDirection.Y
    ScrollingFrame.Parent = Frame16

    local UIListLayout = Instance.new("UIListLayout")

    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout.Padding = UDim.new(0, 1)
    UIListLayout.Parent = ScrollingFrame

    local u167 = false
    local t5 = {}

    local function v169()
        u167 = true

        local v495 = math.min(#p27 * 22, 150)

        Frame16.Size = UDim2.new(1, -12, 0, v495)
        Frame16.Position = UDim2.new(0, 6, 0, 36)
        Frame16.Visible = true
        TextButton6.Visible = true
        ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, #p27 * 22)
        Frame15.Size = UDim2.new(1, 0, 0, 48)
        TextLabel8.Text = "A"
    end

    TextButton6.MouseButton1Click:Connect(function()
        u167 = false
        Frame16.Visible = false
        TextButton6.Visible = false
        Frame15.Size = UDim2.new(1, 0, 0, 48)
        TextLabel8.Text = "V"
    end)

    for _, v in ipairs(p27) do
        local v172 = v
        local TextButton7 = Instance.new("TextButton")

        TextButton7.Size = UDim2.new(1, 0, 0, 20)
        TextButton7.BackgroundColor3 = v172 == t1.value11[p26] and t1.value10.Accent or t1.value10.SurfaceLight
        TextButton7.BackgroundTransparency = v172 ~= t1.value11[p26] and 0.2 or 0.4
        TextButton7.BorderSizePixel = 0
        TextButton7.Text = v172
        TextButton7.Font = t1.value10.FontMedium
        TextButton7.TextSize = 8
        TextButton7.TextColor3 = v172 == t1.value11[p26] and Color3.new(1, 1, 1) or t1.value10.Text
        TextButton7.ZIndex = 102
        TextButton7.AutoButtonColor = false
        TextButton7.Parent = ScrollingFrame
        TextButton7.MouseButton1Click:Connect(function()
            t1.value11[p26] = v172
            t1.value12()
            TextButton5.Text = v172

            for _, v5 in ipairs(t5) do
                if v5.Text == v172 then
                    v5.BackgroundColor3 = t1.value10.Accent
                    v5.BackgroundTransparency = 0.4
                    v5.TextColor3 = Color3.new(1, 1, 1)
                else
                    v5.BackgroundColor3 = t1.value10.SurfaceLight
                    v5.BackgroundTransparency = 0.2
                    v5.TextColor3 = t1.value10.Text
                end
            end

            u167 = false
            Frame16.Visible = false
            TextButton6.Visible = false
            Frame15.Size = UDim2.new(1, 0, 0, 48)
            TextLabel8.Text = "V"

            if p28 then
                p28(v172)
            end
        end)
        table.insert(t5, TextButton7)
    end

    TextButton5.MouseButton1Click:Connect(function()
        if u167 then
            u167 = false
            Frame16.Visible = false
            TextButton6.Visible = false
            Frame15.Size = UDim2.new(1, 0, 0, 48)
            TextLabel8.Text = "V"

            return
        end

        v169()
    end)
    v158.scroll:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
        if u167 then
            u167 = false
            Frame16.Visible = false
            TextButton6.Visible = false
            Frame15.Size = UDim2.new(1, 0, 0, 48)
            TextLabel8.Text = "V"
        end
    end)

    return Frame15
end
t1.value18 = nil
t1.value19 = nil
local vector3 = Vector3.new(0, -1000, 0)
t1.value20 = nil
t1.value20 = vector3
function t1.value21()
    if t1.value18 then
        return
    end

    local value4 = t1.value4
    local value8 = t1.value8
    local Gun = require(value8.PlayerScripts.Modules.ItemTypes.Gun)
    local Utility = require(value4.Modules.Utility)
    local self = setmetatable({}, {
		__index = function(_, p30)
        local Character = value8.Character

        if not Character then
            return nil
        end

        if p30 == "root" then
            return Character:FindFirstChild("HumanoidRootPart")
        end

        if p30 == "head" then
            return Character:FindFirstChild("Head")
        end

        return nil
    end
	})

    t1.value18 = {
		Active = true
	}

    local value18 = t1.value18

    function value18.FindTarget(_)
        local Character = value8.Character
        if not Character then
            return nil
        end
        local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
        if not HumanoidRootPart then
            return nil
        end
        local v504
        local n1 = 1e999
        local _next = next
        local v507, v508 = t1.value1:GetPlayers()
        while true do
            local v509

            v508, v509 = _next(v507, v508)

            if not v508 then
                break
            end

            if v509 ~= value8 and not t1.value13(v509) then
                local Character2 = v509.Character

                if Character2 then
                    local HumanoidRootPart2 = Character2:FindFirstChild("HumanoidRootPart")
                    local Head = Character2:FindFirstChild("Head")
                    local v513 = HumanoidRootPart2
                    local Humanoid = Character2:FindFirstChildWhichIsA("Humanoid")

                    if HumanoidRootPart2 then
                        if Head then
                            Head = Humanoid and Humanoid.Health > 0
                        end

                        v513 = Head
                    end

                    if v513 then
                        local Magnitude = (HumanoidRootPart.Position - HumanoidRootPart2.Position).Magnitude

                        if Magnitude < n1 then
                            v504 = v509
                            n1 = Magnitude
                        end
                    end
                end
            end
        end

        return v504
    end

    value18.Connection = t1.value3.Heartbeat:Connect(function()
        if not value18.Active then
            return
        end

        value18.Target = value18:FindTarget()

        if value18.Target and value18.Target.Character then
            local Head = value18.Target.Character:FindFirstChild("Head")

            if Head then
                local root = self.root

                if root then
                    local rootCFrame = root.CFrame
                    local rootVelocity = root.Velocity
                    local RotVelocity = root.RotVelocity

                    root.CFrame = Head.CFrame
                    root.Velocity = Vector3.zero
                    root.RotVelocity = Vector3.zero
                    t1.value19 = Head.Position
                    t1.value3:BindToRenderStep("WallbangRestore", 101, function()
                        root.CFrame = rootCFrame
                        root.Velocity = rootVelocity
                        root.RotVelocity = RotVelocity
                        t1.value3:UnbindFromRenderStep("WallbangRestore")
                    end)

                    return
                end
            end
        else
            local root = self.root

            if root then
                local rootCFrame = root.CFrame
                local rootVelocity = root.Velocity
                local RotVelocity = root.RotVelocity

                root.CFrame = CFrame.new(t1.value20)
                root.Velocity = Vector3.zero
                root.RotVelocity = Vector3.zero
                t1.value19 = t1.value20
                t1.value3:BindToRenderStep("WallbangVoid", 101, function()
                    root.CFrame = rootCFrame
                    root.Velocity = rootVelocity
                    root.RotVelocity = RotVelocity
                    t1.value3:UnbindFromRenderStep("WallbangVoid")
                end)
            end
        end
    end)

    local StartShooting = Gun.StartShooting

    value18.OldShootFunc = StartShooting

    function Gun.StartShooting(p32, ...)
        local t6 = { StartShooting(p32, ...) }
        local t7 = { v2(t6) }

        if not p32.ClientFighter or not p32.ClientFighter.IsLocalPlayer then
            return unpack(t7)
        end

        local v528 = t7[3]

        if not v528 or typeof(v528) ~= "table" then
            return unpack(t7)
        end

        t7[4] = true

        local value18Target = value18.Target

        if not value18.Active or (not value18Target or not value18Target.Character) then
            return unpack(t7)
        end

        local Head = value18Target.Character:FindFirstChild("Head")

        if not Head then
            return unpack(t7)
        end

        local HeadPosition = Head.Position
        local v532 = Head.CFrame:ToObjectSpace(CFrame.new(HeadPosition + Vector3.new(math.random() * 0.1, math.random() * 0.1, math.random() * 0.1)))

        v528[utf8.char(0)] = Utility:EncodeCFrame(CFrame.new(HeadPosition, HeadPosition + Head.CFrame.LookVector))
        v528[utf8.char(1)] = Utility:EncodeCFrame(CFrame.new(HeadPosition))
        v528[utf8.char(2)] = Head
        v528[utf8.char(3)] = Utility:EncodeCFrame(v532)

        return unpack(t7)
    end
    function value18.Shutdown(p33)
        p33.Active = false
        t1.value19 = nil

        if p33.Connection then
            p33.Connection:Disconnect()
        end

        if p33.OldShootFunc then
            Gun.StartShooting = p33.OldShootFunc
        end

        t1.value3:UnbindFromRenderStep("WallbangRestore")
        t1.value3:UnbindFromRenderStep("WallbangVoid")
    end
end
function t1.value22()
    if t1.value18 then
        t1.value18:Shutdown()
    end

    t1.value19 = nil
end
t1.value23 = false
t1.value24 = nil
t1.value25 = 0
t1.value26 = false
t1.value27 = 0
t1.value28 = t1.value6.CurrentCamera
t1.value29 = require(t1.value4.Modules.Utility)
t1.value30 = require(t1.value4.Modules.EnumLibrary)
t1.value31 = {
	"Medkit",
	"Grenade",
	"Flashbang",
	"Jump Pad",
	"Molotov",
	"Satchel",
	"Smoke Grenade",
	"War Horn",
	"Subspace Tripmine",
	"Warpstone"
}
function t1.value32(p34)
    if not p34 then
        return false
    end

    for _, v in ipairs(t1.value31) do
        if p34 == v then
            return true
        end
    end

    return false
end
function t1.value33(p35, p36)
    if not p35 or not p36 then
        return true
    end

    local Character = p36.Character

    if not Character then
        return true
    end

    local Head = Character:FindFirstChild("Head")

    if not Head then
        return true
    end

    local Unit = (Head.Position - p35).Unit
    local Magnitude = (Head.Position - p35).Magnitude
    local raycastParams = RaycastParams.new()

    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

    local t8 = {}

    for _, player in ipairs(t1.value1:GetPlayers()) do
        if player.Character then
            table.insert(t8, player.Character)
        end
    end

    raycastParams.FilterDescendantsInstances = t8

    return t1.value6:Raycast(p35, Unit * Magnitude, raycastParams) ~= nil
end
function t1.value34()
    local Character = t1.value8.Character
    if not Character then
        return nil
    end
    local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
    if not HumanoidRootPart then
        return nil
    end
    local value19 = t1.value19
    if not value19 then
        local Head = Character:FindFirstChild("Head")

        value19 = Head and Head.Position or HumanoidRootPart.Position
    end
    local v207
    local n2 = 1e999
    for _, player in ipairs(t1.value1:GetPlayers()) do
        if player ~= t1.value8 and not t1.value13(player) then
            local Character3 = player.Character

            if Character3 then
                local Humanoid = Character3:FindFirstChildOfClass("Humanoid")

                if Humanoid and (Humanoid.Health > 0 and not Character3:FindFirstChildOfClass("ForceField")) then
                    local HumanoidRootPart3 = Character3:FindFirstChild("HumanoidRootPart")

                    if HumanoidRootPart3 then
                        local Magnitude = (HumanoidRootPart.Position - HumanoidRootPart3.Position).Magnitude

                        if Magnitude < n2 and (t1.value19 or not t1.value33(value19, player)) then
                            n2 = Magnitude
                            v207 = Character3
                        end
                    end
                end
            end
        end
    end

    return v207
end
function t1.value35()
    local ViewModels = t1.value6:FindFirstChild("ViewModels")

    if not ViewModels then
        return nil
    end

    local FirstPerson = ViewModels:FindFirstChild("FirstPerson")

    if not FirstPerson then
        return nil
    end

    for _, child in ipairs(FirstPerson:GetChildren()) do
        local v201 = child.Name:find("-")

        if v201 then
            return child.Name:sub(v201 + 1):match("^%s*(.-)%s*$")
        end
    end

    return nil
end
function t1.value36()
    local v182 = t1.value11.AutoShootShootAttempt or 0

    if v182 <= 0 then
        return true
    end

    if v182 >= 100 then
        return math.random(1, 100) <= 1
    end

    local _math = math

    return 100 - v182 >= _math.random(1, 100)
end
function t1.value37()
    local v202 = t1.value11.AutoShootShootAttempt or 0

    if v202 <= 0 then
        return 0
    end

    return v202 / 100 * 0.5
end
function t1.value38()
    t1.value26 = true
    t1.value27 = tick() + 5
    task.delay(5, function()
        t1.value26 = false
    end)
end
t1.value8.CharacterAdded:Connect(function(character)
    if t1.value23 then
        t1.value38()
    end

    local Humanoid = character:WaitForChild("Humanoid", 10)

    if Humanoid then
        Humanoid.Died:Connect(function()
            if t1.value23 then
                t1.value38()
            end
        end)
    end
end)
if t1.value8.Character then
    local Humanoid = t1.value8.Character:FindFirstChildOfClass("Humanoid")

    if Humanoid then
        Humanoid.Died:Connect(function()
            if t1.value23 then
                t1.value38()
            end
        end)
    end
end
t1.value39 = nil
t1.value40 = nil
function t1.value40()
    if not t1.value23 then
        return
    end

    if t1.value26 and tick() < t1.value27 then
        return
    end

    local Character = t1.value8.Character
    local v220

    if not Character then
        v220 = false
    else
        local Humanoid = Character:FindFirstChildOfClass("Humanoid")

        v220 = not (not Humanoid or Humanoid.Health <= 0)
    end

    if not v220 then
        return
    end

    local v222 = t1.value35()

    if v222 and t1.value32(v222) then
        return
    end

    local timestamp = tick()

    if t1.value37() > timestamp - t1.value25 then
        return
    end

    if not t1.value36() then
        return
    end

    local v224 = t1.value34()

    if not v224 then
        return
    end

    local Head = v224:FindFirstChild("Head")

    if not Head then
        return
    end

    local player = t1.value1:GetPlayerFromCharacter(v224)

    if not player or t1.value13(player) then
        return
    end

    pcall(function()
        local FighterController = require(t1.value8.PlayerScripts.Controllers.FighterController)
        local v535 = FighterController.LocalFighter and FighterController.LocalFighter.EquippedItem

        if not v535 then
            return
        end

        local v536 = v535:Get("ObjectID")

        if not v536 then
            return
        end

        local Character4 = t1.value8.Character
        local v538 = Character4 and Character4:FindFirstChild("HumanoidRootPart")
        local v539 = t1.value19 or (v538 and v538.Position or Head.Position)
        local v540 = utf8.char(1)
        local v541 = utf8.char(0)
        local v542 = t1.value29:EncodeCFrame(CFrame.new(v539, Head.Position))
        local v543 = utf8.char(1)
        local value29 = t1.value29
        local t9 = { CFrame.new(v539, Head.Position) }
        local v546 = value29:EncodeCFrame(v2(t9))
        local v547 = utf8.char(2)
        local v548 = Head
        local v549 = utf8.char(3)
        local v550 = t1.value29:EncodeCFrame(CFrame.new(0.43, 0.25, 0.42))
        local t10 = {
			[v540] = {
				[v541] = v542,
				[v543] = v546,
				[v547] = v548,
				[v549] = v550
			}
		}

        t1.value4.Remotes.Replication.Fighter.UseItem:FireServer(v536, t1.value30:ToEnum("StartShooting"), t10, nil)
    end)
end
function t1.value41()
    if t1.value23 then
        return
    end

    t1.value23 = true
    t1.value24 = t1.value3.Heartbeat:Connect(function()
        if t1.value23 then
            t1.value40()
        end
    end)
end
function t1.value42()
    if t1.value24 then
        t1.value24:Disconnect()
    end
end
t1.value43 = nil
t1.value44 = nil
t1.value45 = nil
t1.value46 = nil
t1.value44 = false
function t1.value47()
    if t1.value44 then
        return
    end

    t1.value44 = true
    pcall(function()
        local Items = require(game:GetService("ReplicatedStorage").Modules.ItemLibrary).Items

        for _, v in pairs(Items) do
            if typeof(v) == "table" then
                if v.ShootSpread then
                    v.ShootSpread = 0
                end

                if v.ShootAccuracy then
                    v.ShootAccuracy = 0
                end

                if v.ShootRecoil then
                    v.ShootRecoil = 0
                end

                if v.ShootCooldown then
                    v.ShootCooldown = 0.001
                end

                if v.ShootBurstCooldown then
                    v.ShootBurstCooldown = 0.001
                end

                if v.AttackCooldown then
                    v.AttackCooldown = 0.001
                end

                if v.SwingCooldown then
                    v.SwingCooldown = 0.001
                end

                if v.MeleeCooldown then
                    v.MeleeCooldown = 0.001
                end

                if v.Cooldown then
                    v.Cooldown = 0.001
                end

                if v.RecoveryTime then
                    v.RecoveryTime = 0.001
                end

                if v.ResetTime then
                    v.ResetTime = 0.001
                end

                if v.ReloadTime then
                    v.ReloadTime = 0.001
                end

                if v.ChargeTime then
                    v.ChargeTime = 0.001
                end
            end
        end
    end)
end
function t1.value48()
    t1.value44 = false
end
t1.value49 = false
t1.value50 = nil
t1.value51 = nil
t1.value52 = nil
t1.value53 = nil
t1.value54 = nil
function t1.value55()
    local v238 = t1.value8.Character or t1.value8.CharacterAdded:Wait()

    t1.value53 = v238:WaitForChild("Humanoid")
    t1.value54 = v238:WaitForChild("HumanoidRootPart")

    if t1.value49 then
        if t1.value50 then
            t1.value50:Destroy()
        end

        t1.value53.PlatformStand = true
        t1.value50 = Instance.new("Attachment", t1.value54)
        t1.value51 = Instance.new("LinearVelocity", t1.value50)
        t1.value51.MaxForce = 9000000000
        t1.value51.VectorVelocity = Vector3.zero
        t1.value51.Attachment0 = t1.value50
        t1.value52 = Instance.new("AlignOrientation", t1.value50)
        t1.value52.MaxTorque = 9000000000
        t1.value52.Responsiveness = 200
        t1.value52.Mode = Enum.OrientationAlignmentMode.OneAttachment
        t1.value52.Attachment0 = t1.value50
    end
end
t1.value8.CharacterAdded:Connect(function()
    task.wait(0.1)
    t1.value55()
end)
t1.value55()
t1.value56 = require(t1.value8.PlayerScripts:WaitForChild("PlayerModule")):GetControls()
t1.value3.RenderStepped:Connect(function()
    local value49 = t1.value49

    if value49 then
        value49 = t1.value54 and (t1.value6.CurrentCamera and (t1.value51 and t1.value52))
    end

    if value49 then
        local CurrentCamera = t1.value6.CurrentCamera
        local MoveVector = t1.value56:GetMoveVector()
        local v250 = t1.value11.FlySpeed or 80

        if MoveVector.Magnitude > 0 then
            t1.value51.VectorVelocity = (CurrentCamera.CFrame.LookVector * -MoveVector.Z + CurrentCamera.CFrame.RightVector * MoveVector.X).Unit * v250
        else
            t1.value51.VectorVelocity = Vector3.zero
        end

        t1.value52.CFrame = CurrentCamera.CFrame
    end
end)
function t1.value57()
    t1.value55()
end
function t1.value58()
    if t1.value53 then
        t1.value53.PlatformStand = false
    end

    if t1.value50 then
        t1.value50:Destroy()
    end
end
t1.value59 = false
t1.value60 = nil
t1.value60 = nil
function t1.value61()
    if t1.value59 then
        return
    end

    t1.value59 = true
    t1.value60 = t1.value2.JumpRequest:Connect(function()
        if not t1.value59 then
            return
        end

        local Character = t1.value8.Character

        if not Character then
            return
        end

        local Humanoid = Character:FindFirstChildOfClass("Humanoid")

        if Humanoid and Humanoid.Health > 0 then
            Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
end
function t1.value62()
    if t1.value60 then
        t1.value60:Disconnect()
    end
end
t1.value39 = false
t1.value45 = nil
function t1.value63()
    if t1.value39 then
        return
    end

    t1.value39 = true
    t1.value45 = t1.value3.Stepped:Connect(function()
        if not t1.value39 then
            return
        end

        local Character = t1.value8.Character

        if not Character then
            return
        end

        for _, descendant in pairs(Character:GetDescendants()) do
            if descendant:IsA("BasePart") then
                descendant.CanCollide = false
            end
        end
    end)
end
function t1.value64()
    t1.value39 = false

    if t1.value45 then
        t1.value45:Disconnect()
        t1.value45 = nil
    end
end
t1.value65 = false
t1.value66 = {}
t1.value67 = nil
function t1.value43(p37, p38)
    local drawing = Drawing.new(p37)

    for k, v in pairs(p38) do
        drawing[k] = v
    end

    return drawing
end
function t1.value68(_)
    local t11 = {}

    if t1.value11.EspBoxes then
        local value43 = t1.value43
        local color3_20 = Color3.new(0, 0, 0)

        t11.BoxOutline = value43("Square", {
			Visible = false,
			Thickness = 3,
			Filled = false,
			Color = color3_20
		})

        local value43_2 = t1.value43
        local color3_21 = Color3.new(1, 1, 1)

        t11.Box = value43_2("Square", {
			Visible = false,
			Thickness = 1.5,
			Filled = false,
			Color = color3_21
		})
    end

    if t1.value11.EspNames then
        local value43 = t1.value43
        local color3_22 = Color3.new(0, 0, 0)
        local color3_23 = Color3.new(1, 1, 1)

        t11.Name = value43("Text", {
			Visible = false,
			Center = true,
			Outline = true,
			OutlineColor = color3_22,
			Size = 13,
			Font = 2,
			Color = color3_23
		})
    end

    if t1.value11.EspHealth then
        local value43 = t1.value43
        local color3_24 = Color3.new(0, 0, 0)

        t11.HealthBarBG = value43("Line", {
			Visible = false,
			Thickness = 5,
			Color = color3_24
		})

        local value43_3 = t1.value43
        local color3_25 = Color3.new(0, 1, 0)

        t11.HealthBar = value43_3("Line", {
			Visible = false,
			Thickness = 3,
			Color = color3_25
		})
    end

    if t1.value11.EspDistance then
        local value43 = t1.value43
        local color3_26 = Color3.new(0, 0, 0)
        local color3_27 = Color3.new(1, 1, 1)

        t11.Distance = value43("Text", {
			Visible = false,
			Center = true,
			Outline = true,
			OutlineColor = color3_26,
			Size = 11,
			Font = 2,
			Color = color3_27
		})
    end

    if t1.value11.EspHealthNumber then
        local value43 = t1.value43
        local color3_28 = Color3.new(0, 0, 0)
        local color3_29 = Color3.new(1, 1, 1)

        t11.HealthNumber = value43("Text", {
			Visible = false,
			Center = true,
			Outline = true,
			OutlineColor = color3_28,
			Size = 11,
			Font = 2,
			Color = color3_29
		})
    end

    return t11
end
function t1.value69(p40, p41)
    local v279 = p41 / 2
    local t12 = {}
    local v281 = true

    for i = -1, 1, 2 do
        for j = -1, 1, 2 do
            for k = -1, 1, 2 do
                local v285 = p40 * Vector3.new(v279.X * i, v279.Y * j, v279.Z * k)
                local v286, v287 = t1.value28:WorldToViewportPoint(v285)

                if not v287 then
                    v281 = false
                end

                table.insert(t12, Vector2.new(v286.X, v286.Y))
            end
        end
    end

    return t12, v281
end
function t1.value70(p42)
    for _, v in pairs(p42) do
        if v and v.Visible then
            v.Visible = false
        end
    end
end
function t1.value71(p43)
    if not t1.value11.EspChams then
        return
    end

    for _, descendant in pairs(p43:GetDescendants()) do
        if descendant:IsA("BasePart") and descendant.Transparency < 1 then
            descendant.Transparency = 0.5
            descendant.Material = Enum.Material.ForceField
            descendant.Color = Color3.fromRGB(255, 0, 0)
        end
    end
end
function t1.value72(p44)
    if not p44 then
        return
    end

    local GetDescendants = p44.GetDescendants

    for _, v in pairs(GetDescendants(p44)) do
        if v:IsA("BasePart") then
            v.Transparency = 0
            v.Material = Enum.Material.Plastic
        end
    end
end
local function v58()
    if not t1.value65 then

        for v298, v299 in pairs(t1.value66) do

            t1.value70(v299)
        end
        for _, player in ipairs(t1.value1:GetPlayers()) do
            if player ~= t1.value8 and player.Character then
                t1.value72(player.Character)
            end
        end

        return
    end

    for _, player in ipairs(t1.value1:GetPlayers()) do
        if player ~= t1.value8 then
            if t1.value13(player) then
                if t1.value66[player] then
                    t1.value70(t1.value66[player])
                end

                if player.Character then
                    t1.value72(player.Character)
                end
            else
                local Character = player.Character
                local v305 = Character and Character:FindFirstChildOfClass("Humanoid")

                if Character and (v305 and v305.Health > 0) then
                    if t1.value11.EspChams then
                        t1.value71(Character)
                    else
                        t1.value72(Character)
                    end

                    local ok, result, v308 = pcall(Character.GetBoundingBox, Character)

                    if ok then
                        ok = result and v308
                    end

                    if ok then
                        local v310, t13Result = t1.value69(result, v308)
                        if not t13Result then
                            if t1.value66[player] then
                                t1.value70(t1.value66[player])
                            end
                        else
                            local v311 = t1.value66[player] or t1.value68(player)

                            t1.value66[player] = v311

                            local n3 = 1e999
                            local n4 = -1e999
                            local n5 = -1e999
                            local n6 = 1e999

                            for _, v in ipairs(v310) do
                                n6 = math.min(n6, v.X)
                                n3 = math.min(n3, v.Y)
                                n4 = math.max(n4, v.X)
                                n5 = math.max(n5, v.Y)
                            end

                            local v318 = n4 - n6
                            local v319 = n5 - n3
                            local v320 = v318 * 0.7
                            local v321 = n6 + (v318 - v320) / 2
                            local v322 = math.clamp(v305.Health / v305.MaxHealth, 0, 1)
                            local Head = Character:FindFirstChild("Head")

                            if v311.BoxOutline and t1.value11.EspBoxes then
                                v311.BoxOutline.Visible = true
                                v311.BoxOutline.Position = Vector2.new(v321 - 1, n3 - 1)
                                v311.BoxOutline.Size = Vector2.new(v320 + 2, v319 + 2)
                            end

                            if v311.Box and t1.value11.EspBoxes then
                                v311.Box.Visible = true
                                v311.Box.Position = Vector2.new(v321, n3)
                                v311.Box.Size = Vector2.new(v320, v319)
                            end

                            if v311.Name and t1.value11.EspNames then
                                v311.Name.Visible = true
                                v311.Name.Text = player.Name
                                v311.Name.Position = Vector2.new(v321 + v320 / 2, n3 - 16)
                            end

                            local v324 = v319 * v322

                            if v311.HealthBarBG and t1.value11.EspHealth then
                                v311.HealthBarBG.Visible = true
                                v311.HealthBarBG.From = Vector2.new(v321 - 6, n5)
                                v311.HealthBarBG.To = Vector2.new(v321 - 6, n3)
                            end

                            if v311.HealthBar and t1.value11.EspHealth then
                                v311.HealthBar.Visible = true

                                if v322 > 0.7 then
                                    v311.HealthBar.Color = Color3.fromRGB(0, 255, 0)
                                elseif v322 > 0.3 then
                                    v311.HealthBar.Color = Color3.fromRGB(255, 165, 0)
                                else
                                    v311.HealthBar.Color = Color3.fromRGB(255, 0, 0)
                                end

                                v311.HealthBar.From = Vector2.new(v321 - 6, n5)
                                v311.HealthBar.To = Vector2.new(v321 - 6, n5 - v324)
                            end

                            if v311.Distance and (t1.value11.EspDistance and Head) then
                                local v325 = t1.value8.Character and t1.value8.Character:FindFirstChild("HumanoidRootPart")

                                if v325 then
                                    local v326 = math.floor((v325.Position - Head.Position).Magnitude)

                                    v311.Distance.Visible = true
                                    v311.Distance.Text = v326 .. "m"
                                    v311.Distance.Position = Vector2.new(v321 + v320 / 2, n5 + 4)
                                end
                            end

                            if v311.HealthNumber and t1.value11.EspHealthNumber then
                                v311.HealthNumber.Visible = true
                                v311.HealthNumber.Text = math.floor(v305.Health) .. "/" .. math.floor(v305.MaxHealth)
                                v311.HealthNumber.Position = Vector2.new(v321 + v320 / 2, n5 + 16)
                            end
                        end
                    end
                else
                    if t1.value66[player] then
                        t1.value70(t1.value66[player])
                    end

                    if Character then
                        t1.value72(Character)
                    end
                end
            end
        end
    end
end
function t1.value73()
    t1.value65 = true

    if t1.value67 then
        t1.value67:Disconnect()
    end

    t1.value3.RenderStepped:Connect(v58)
end
t1.value74 = nil
function t1.value74()
    t1.value65 = false
    if t1.value67 then
        t1.value67:Disconnect()
        t1.value67 = nil
    end
    for v291, v292 in pairs(t1.value66) do

        local v293 = v292

        pcall(function()
            for _, v in pairs(v293) do
                if v and v.Remove then
                    v:Remove()
                end
            end
        end)
    end
    t1.value66 = {}
    for _, player in ipairs(t1.value1:GetPlayers()) do
        if player.Character then
            t1.value72(player.Character)
        end
    end
end
function t1.value46()
    if t1.value65 then
        t1.value74()
        t1.value73()
    end
end
t1.value1.PlayerRemoving:Connect(function(player)
    if t1.value66[player] then
        for _, v in pairs(t1.value66[player]) do
            local v332 = v

            pcall(function()
                if v332 and v332.Remove then
                    v332:Remove()
                end
            end)
        end

        t1.value66[player] = nil
    end

    if player.Character then
        t1.value72(player.Character)
    end
end)
t1.value75 = {
	enabled = false,
	animationId = "",
	loop = true,
	speed = 2,
	serverSide = true,
	jitter = false,
	jitterId = "",
	jitterSpeed = 0.1,
	spawnProof = true
}
t1.value76 = {}
t1.value77 = 1
t1.value78 = 0
t1.value79 = {
	["Underground Glitch"] = "138847307095534",
	Orbit = "133811691098518",
	Tweaking = "114353590132838",
	["Kicking Feet"] = "131879764029003",
	["Low Cortisol"] = "125822752810863",
	Floss = "72174079036035",
	["Take the L"] = "112884830175040",
	["Upside Down"] = "128616002281906",
	["Michael Myers Shake"] = "123682198526131",
	Headless = "74738520664045",
	["Wall Peek L"] = "123671647250039",
	["Glitch Through"] = "85364072005108"
}
function t1.value80()
    for _, v in ipairs(t1.value76) do
        local v338 = v

        pcall(function()
            v338:Stop(0)
            v338:Destroy()
        end)
    end

    t1.value76 = {}
end
function t1.value81(p45)
    if not p45 then
        return nil
    end

    local Humanoid = p45:FindFirstChildOfClass("Humanoid")

    if not Humanoid then
        return nil
    end

    local Animator = Humanoid:FindFirstChildOfClass("Animator")

    if not Animator then
        Animator = Instance.new("Animator")
        Animator.Parent = Humanoid
    end

    return Animator
end
function t1.value82(p46)
    local ok, result = pcall(function()
        return game:GetObjects("rbxassetid://" .. p46)
    end)
    local v342 = not ok

    if not v342 then
        v342 = not result or #result == 0
    end

    if v342 then
        return nil
    end

    local v343, v344, v345 = ipairs(result)
    local v346

    repeat
        v345, v346 = v343(v344, v345)

        if not v345 then
            for _, v in ipairs(result) do
                local GetDescendants = v.GetDescendants

                for _, v6 in ipairs(GetDescendants(v)) do
                    if v6:IsA("Animation") and v6.AnimationId ~= "" then
                        return v6
                    end
                end
            end

            return nil
        end
    until v346:IsA("Animation") and v346.AnimationId ~= ""

    return v346
end
function t1.value83(p47, p48, p49, p50)
    local v356 = not p47

    if not v356 then
        v356 = p48 == ""
    end

    if v356 then
        return nil
    end

    local v357 = t1.value81(p47)

    if not v357 then
        return nil
    end

    local u358 = t1.value82(p48)

    if not u358 then
        u358 = Instance.new("Animation")
        u358.AnimationId = "rbxassetid://" .. p48
    end

    local ok, result = pcall(function()
        return v357:LoadAnimation(u358)
    end)
    local v361 = not ok

    if not v361 then
        v361 = not result
    end

    if v361 then
        pcall(function()
            u358:Destroy()
        end)

        return nil
    end

    result.Looped = p50
    result.Priority = Enum.AnimationPriority.Action4
    result:Play(0.1, 1, p49)

    return result
end
local function v59()
    t1.value80()

    if not t1.value75.enabled or t1.value75.animationId == "" then
        return
    end

    local Character = t1.value8.Character

    if Character then
        local v369 = t1.value83(Character, t1.value75.animationId, t1.value75.speed, t1.value75.loop)

        if v369 then
            table.insert(t1.value76, v369)
        end
    end

    local Live = t1.value6:FindFirstChild("Live")

    if Live then
        local t1value8Name = Live:FindFirstChild(t1.value8.Name)

        if t1value8Name then
            local v372 = t1.value83(t1value8Name, t1.value75.animationId, t1.value75.speed, t1.value75.loop)

            if v372 then
                table.insert(t1.value76, v372)
            end
        end
    end
end
function t1.value84()
    if not t1.value75.jitter or t1.value75.jitterId == "" then
        return
    end

    if tick() - t1.value78 >= t1.value75.jitterSpeed then
        t1.value77 = t1.value77 ~= 1 and 1 or 2
        t1.value80()

        local Character = t1.value8.Character

        if Character then
            local v363 = t1.value77 == 1 and t1.value75.animationId or t1.value75.jitterId
            local v364 = t1.value83(Character, v363, t1.value75.speed, t1.value75.loop)

            if v364 then
                table.insert(t1.value76, v364)
            end

            local Live = t1.value6:FindFirstChild("Live")

            if Live then
                local t1value8Name = Live:FindFirstChild(t1.value8.Name)

                if t1value8Name then
                    local v367 = t1.value83(t1value8Name, v363, t1.value75.speed, t1.value75.loop)

                    if v367 then
                        table.insert(t1.value76, v367)
                    end
                end
            end
        end
    end
end
t1.value3.Heartbeat:Connect(function()
    if not t1.value75.enabled then
        return
    end

    if t1.value75.jitter then
        t1.value84()
    end

    if #t1.value76 == 0 and t1.value75.animationId ~= "" then
        v59()
    end

    for _, v in ipairs(t1.value76) do
        local v375 = v

        pcall(function()
            v375:AdjustSpeed(t1.value75.speed)
        end)
    end
end)
t1.value8.CharacterAdded:Connect(function()
    task.wait(0.5)

    if t1.value75.enabled and t1.value75.spawnProof then
        v59()
    end
end)
getgenv().AnimPlayer = {
	Enable = function()
    t1.value75.enabled = true
    v59()
end,
	Disable = function()
    t1.value75.enabled = false
    t1.value80()
end,
	SetAnimation = function(p51)
    t1.value75.animationId = p51

    if t1.value75.enabled then
        v59()
    end
end,
	SetSpeed = function(p52)
    t1.value75.speed = p52
end,
	Play = v59,
	Stop = t1.value80,
	Presets = t1.value79,
	Config = t1.value75
}
local function v60(p53)
    if p53 then
        t1.value75.enabled = true

        local v392 = t1.value79[t1.value11.AnimationPreset]

        if v392 then
            t1.value75.animationId = v392
        end

        t1.value75.speed = t1.value11.AnimationSpeed
        t1.value75.loop = true
        t1.value75.serverSide = true
        v59()

        return
    end

    t1.value75.enabled = false
    t1.value80()
end
t1.value85 = nil
function t1.value86()
    local LocalPlayer = game.Players.LocalPlayer
    local Modules = game:GetService("ReplicatedStorage"):FindFirstChild("Modules")

    if not Modules then
        return
    end

    local CosmeticLibrary = Modules:FindFirstChild("CosmeticLibrary")
    local v381 = not CosmeticLibrary
    local ItemLibrary = Modules:FindFirstChild("ItemLibrary")

    if not v381 then
        v381 = not ItemLibrary
    end

    if v381 then
        return
    end

    local Cosmetics = CosmeticLibrary.Cosmetics
    local Items = ItemLibrary.Items

    for k, _ in pairs(Items) do
        if k ~= "MISSING_WEAPON" then
            for k3, v in pairs(Cosmetics) do
                if v.Type == "Skin" and k == v.ItemName then
                    local _, _ = pcall(function()
                        local Equipment = LocalPlayer.PlayerScripts.Controllers.Equipment

                        if Equipment then
                            Equipment:SetCosmetic(k, "Skin", k3)
                        end
                    end)
                end
            end
        end
    end

    print("All cosmetics unlocked!")
end
local function v61(p54)
    if p54 then
        t1.value85 = t1.value3.RenderStepped:Connect(function()
            local Character = t1.value8.Character

            if not Character then
                return
            end

            local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")

            if not HumanoidRootPart then
                return
            end

            local Humanoid = Character:FindFirstChild("Humanoid")
            local v566 = Humanoid and Humanoid.Health < Humanoid.MaxHealth

            for _, child in pairs(workspace:GetChildren()) do
                if child.Name == "_drop" and child:IsA("BasePart") then
                    if child:FindFirstChild("Health") and v566 then
                        firetouchinterest(HumanoidRootPart, child, 0)
                        firetouchinterest(HumanoidRootPart, child, 1)
                    end

                    if child:FindFirstChild("Ammo") then
                        firetouchinterest(HumanoidRootPart, child, 0)
                        firetouchinterest(HumanoidRootPart, child, 1)
                    end
                end
            end
        end)

        return
    end

    if t1.value85 then
        t1.value85:Disconnect()
    end
end
local color3_30 = Color3.fromRGB(255, 255, 255)
local color3_31 = Color3.fromRGB(255, 255, 255)
local color3_32 = Color3.fromRGB(255, 255, 255)
local color3_33 = Color3.fromRGB(0, 0, 0)
t1.value87 = {
	enabled = false,
	radius = 100,
	followMuzzle = false,
	OutlineColor1 = color3_30,
	OutlineColor2 = color3_31,
	OutlineRotation = 0,
	OutlineThickness = 1.5,
	OutlineTransparency = 0,
	FilledEnabled = false,
	FilledColor1 = color3_32,
	FilledColor2 = color3_33,
	FilledRotation = 0,
	FilledTransparency = 0.7,
	FilledAnimated = false,
	FilledSpeed = 1,
	SpinOn = false,
	SpinSpd = 1
}
t1.value88 = Instance.new("ScreenGui")
t1.value88.Name = "AimbotFOV"
t1.value88.ResetOnSpawn = false
t1.value88.IgnoreGuiInset = true
t1.value88.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
t1.value88.Parent = game.CoreGui
local v66 = (function(p55, p56)
    local Frame17 = Instance.new("Frame")

    Frame17.Name = p55
    Frame17.BackgroundTransparency = 1
    Frame17.BorderSizePixel = 0
    Frame17.Visible = false
    Frame17.Parent = t1.value88

    local Frame18 = Instance.new("Frame")

    Frame18.Size = UDim2.new(1, 0, 1, 0)
    Frame18.BackgroundColor3 = Color3.new(1, 1, 1)
    Frame18.BackgroundTransparency = p56.FilledTransparency
    Frame18.BorderSizePixel = 0
    Frame18.Visible = false
    Frame18.ZIndex = 1
    Frame18.Parent = Frame17

    local UICorner = Instance.new("UICorner")

    UICorner.CornerRadius = UDim.new(1, 0)
    UICorner.Parent = Frame18

    local UIGradient = Instance.new("UIGradient")

    UIGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, p56.FilledColor1),
		ColorSequenceKeypoint.new(1, p56.FilledColor2)
	})
    UIGradient.Rotation = p56.FilledRotation
    UIGradient.Parent = Frame18

    local Frame19 = Instance.new("Frame")

    Frame19.Size = UDim2.new(1, 0, 1, 0)
    Frame19.BackgroundTransparency = 1
    Frame19.BorderSizePixel = 0
    Frame19.ZIndex = 2
    Frame19.Parent = Frame17

    local UICorner2 = Instance.new("UICorner")

    UICorner2.CornerRadius = UDim.new(1, 0)
    UICorner2.Parent = Frame19

    local UIStroke2 = Instance.new("UIStroke")

    UIStroke2.Color = Color3.new(1, 1, 1)
    UIStroke2.Thickness = p56.OutlineThickness
    UIStroke2.Transparency = p56.OutlineTransparency
    UIStroke2.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    UIStroke2.Parent = Frame19

    local UIGradient2 = Instance.new("UIGradient")

    UIGradient2.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, p56.OutlineColor1),
		ColorSequenceKeypoint.new(1, p56.OutlineColor2)
	})
    UIGradient2.Rotation = p56.OutlineRotation
    UIGradient2.Parent = UIStroke2

    return {
		container = Frame17,
		fill = Frame18,
		fillgrad = UIGradient,
		stroke = UIStroke2,
		strokegrad = UIGradient2
	}
end)("AimbotFOV", t1.value87)
t1.value89 = v66.container
t1.value90 = v66.fill
t1.value91 = v66.fillgrad
t1.value92 = v66.stroke
t1.value93 = v66.strokegrad
function t1.value94()
    local Character = t1.value8.Character

    if not Character then
        local CurrentCamera = workspace.CurrentCamera

        return CurrentCamera and CurrentCamera.CFrame.Position + CurrentCamera.CFrame.LookVector * 4 or Vector3.zero
    end

    local ViewModels = t1.value6:FindFirstChild("ViewModels")

    if ViewModels then
        local FirstPerson = ViewModels:FindFirstChild("FirstPerson")

        if FirstPerson then
            local GetChildren = FirstPerson.GetChildren

            for _, v in ipairs(GetChildren(FirstPerson)) do
                if not v:IsA("Model") then
                    continue
                end

                local ItemVisual = v:FindFirstChild("ItemVisual")

                if ItemVisual then
                    local Body = ItemVisual:FindFirstChild("Body")

                    if Body then
                        local BodyPrimary = Body:FindFirstChild("BodyPrimary")

                        if BodyPrimary then
                            local _muzzle = BodyPrimary:FindFirstChild("_muzzle")

                            if _muzzle and _muzzle:IsA("Attachment") then
                                return _muzzle.WorldPosition
                            end
                        end
                    end
                end

                local Muzzle = v:FindFirstChild("Muzzle")

                if not Muzzle then
                    Muzzle = v:FindFirstChild("MuzzleFlash")

                    if not Muzzle then
                        Muzzle = v:FindFirstChild("Barrel") or v:FindFirstChild("GunTip")
                    end
                end

                if Muzzle then
                    if Muzzle:IsA("Attachment") then
                        return Muzzle.WorldPosition
                    end

                    if Muzzle:IsA("BasePart") then
                        return Muzzle.Position
                    end
                end

                for _, child in ipairs(v:GetChildren()) do
                    if not child:IsA("BasePart") then
                        continue
                    end

                    local v425 = child.Name:lower()

                    if v425:find("tip") or (v425:find("barrel") or v425:find("muzzle")) then
                        return child.Position
                    end
                end

                local v426 = v.PrimaryPart or v:FindFirstChildWhichIsA("BasePart")

                if v426 then
                    return v426.Position
                end
            end
        end
    end

    local CurrentCamera = workspace.CurrentCamera

    if CurrentCamera then
        return CurrentCamera.CFrame.Position + CurrentCamera.CFrame.LookVector * 4
    end

    local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")

    return HumanoidRootPart and HumanoidRootPart.Position or Vector3.zero
end
function t1.value95(p57)
    local v408, v409 = t1.value28:WorldToViewportPoint(p57)
    local v410 = not v409

    if not v410 then
        v410 = v408.Z <= 0
    end

    if v410 then
        return nil, false
    end

    return Vector2.new(v408.X, v408.Y), true
end
function t1.value96()
    if t1.value87.followMuzzle then
        local v429 = t1.value94()
        local v430, v431 = t1.value95(v429)

        if v431 then
            return v430
        end
    end

    local ViewportSize = t1.value28.ViewportSize

    return Vector2.new(ViewportSize.X * 0.5, ViewportSize.Y * 0.5)
end
t1.value3.RenderStepped:Connect(function()
    if not t1.value87.enabled or not t1.value11.FOVShow then
        t1.value89.Visible = false

        return
    end

    t1.value89.Visible = true

    local v433 = t1.value96()
    local radius = t1.value87.radius

    t1.value89.Size = UDim2.fromOffset(radius * 2, radius * 2)
    t1.value89.Position = UDim2.fromOffset(v433.X - radius, v433.Y - radius)
    t1.value92.Thickness = t1.value87.OutlineThickness
    t1.value92.Transparency = t1.value87.OutlineTransparency
    t1.value93.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, t1.value87.OutlineColor1),
		ColorSequenceKeypoint.new(1, t1.value87.OutlineColor2)
	})
    t1.value90.Visible = t1.value87.FilledEnabled
    t1.value90.BackgroundTransparency = t1.value87.FilledTransparency
    t1.value91.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, t1.value87.FilledColor1),
		ColorSequenceKeypoint.new(1, t1.value87.FilledColor2)
	})

    if t1.value87.FilledAnimated then
        t1.value91.Rotation = math.sin(tick() * t1.value87.FilledSpeed) * 180 + t1.value87.FilledRotation
    elseif t1.value87.SpinOn then
        t1.value91.Rotation = t1.value87.FilledRotation + tick() * t1.value87.SpinSpd * 90 % 360
    end

    if t1.value87.SpinOn then
        t1.value93.Rotation = t1.value87.OutlineRotation + tick() * t1.value87.SpinSpd * 90 % 360
    end
end)
t1.value97 = {
	enabled = false,
	mode = "1v1",
	ranked = false
}
t1.value98 = {
	[1] = "Assault Rifle",
	[2] = "Handgun",
	[3] = "Katana",
	[4] = "Medkit"
}
function t1.value99()
    local Remotes = t1.value4:FindFirstChild("Remotes")
    if not Remotes then
        return nil, nil
    end
    local PickWeapons
    local PickWeaponsAheadOfTime
    pcall(function()
        PickWeapons = Remotes.Replication.Fighter.PickWeapons
        PickWeaponsAheadOfTime = Remotes.Duels.PickWeaponsAheadOfTime
    end)

    return PickWeapons, nil
end
local function v67()
    local v450, v451 = t1.value99()
    local v452 = v450
    local v453 = v451

    if not v452 then
        return
    end

    local t14 = {}

    for k, v in pairs(t1.value98) do
        if v and v ~= "" then
            t14[k] = v
        end
    end

    if not next(t14) then
        return
    end

    pcall(function()
        v452:FireServer(t14)
    end)
    pcall(function()
        v453:FireServer(t14)
    end)
end
function t1.value100()
    local Vote
    pcall(function()
        Vote = t1.value4.Remotes.Duels.Vote
    end)
    if not Vote then
        return
    end
    for _, v in pairs(t1.value98) do
        local v449 = v

        if v449 and v449 ~= "" then
            pcall(function()
                Vote:FireServer(v449)
            end)
        end
    end
end
task.spawn(function()
    while true do
        if t1.value97.enabled then
            pcall(function()
                game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Matchmaking"):WaitForChild("JoinQueue"):InvokeServer(t1.value97.mode, t1.value97.ranked)
            end)
        end

        task.wait(1)
    end
end)
task.spawn(function()
    while true do
        task.wait(0.1)

        local PlayerGui2 = t1.value8:FindFirstChildOfClass("PlayerGui")
        local v458 = PlayerGui2 and PlayerGui2:FindFirstChild("PickWeapons", true)

        if v458 and v458.Visible then
            v67()

            if v458 then
                local _ = v458.Visible
            end

            repeat
                task.wait(0.1)
            until not v458 or not v458.Visible
        end
    end
end)
task.spawn(function()
    while true do
        task.wait(5)
        t1.value100()
    end
end)
t1.value98[1] = t1.value11.PrimaryWeapon or "Assault Rifle"
t1.value98[2] = t1.value11.SecondaryWeapon or "Handgun"
t1.value98[3] = t1.value11.MeleeWeapon or "Katana"
t1.value98[4] = t1.value11.UtilityWeapon or "Medkit"
t1.value97.mode = t1.value11.AutoQueueMode or "1v1"
t1.value97.ranked = t1.value97.mode:find("ranked") ~= nil
v53("Ragebot", "Ragebot", "Ragebot", function(p58)
    if p58 then
        t1.value21()

        return
    end

    t1.value22()
end)
v52("Ragebot", "Auto Shoot", "AutoShoot", 0, 100, "AutoShootShootAttempt", "%", function(p59)
    if p59 then
        t1.value41()

        return
    end

    t1.value42()
end, function(p60)
    t1.value11.AutoShootShootAttempt = p60
    t1.value12()
end)
v53("Ragebot", "Rapid Fire", "RapidFire", function(p61)
    if p61 then
        t1.value47()

        return
    end

    t1.value48()
end)
v53("FOV", "Enable FOV", "FOVEnabled", function(p62)
    t1.value87.enabled = p62
    t1.value11.FOVEnabled = p62
    t1.value12()
end)
v53("FOV", "Show FOV", "FOVShow", function(p63)
    t1.value11.FOVShow = p63
    t1.value12()
end)
v54("FOV", "FOV Size", 50, 300, "FOVRadius", "", function(p64)
    t1.value87.radius = p64
    t1.value11.FOVRadius = p64
    t1.value12()
end)
v53("FOV", "Follow Muzzle", "FOVFollowMuzzle", function(p65)
    t1.value87.followMuzzle = p65
    t1.value11.FOVFollowMuzzle = p65
    t1.value12()
end)
v53("FOV", "Fill FOV", "FOVFilled", function(p66)
    t1.value87.FilledEnabled = p66
    t1.value90.Visible = p66
    t1.value11.FOVFilled = p66
    t1.value12()
end)
v53("FOV", "Spin FOV", "FOVSpin", function(p67)
    t1.value87.SpinOn = p67
    t1.value11.FOVSpin = p67
    t1.value12()
end)
v54("FOV", "Spin Speed", 1, 20, "FOVSpinSpeed", "x", function(p68)
    t1.value87.SpinSpd = p68
    t1.value11.FOVSpinSpeed = p68
    t1.value12()
end)
v53("FOV", "Animated FOV", "FOVAnimated", function(p69)
    t1.value87.FilledAnimated = p69
    t1.value11.FOVAnimated = p69
    t1.value12()
end)
v53("ESP", "Enable ESP", "Esp", function(p70)
    if p70 then
        t1.value73()

        return
    end

    t1.value74()
end)
v53("ESP", "Box ESP", "EspBoxes", function(p71)
    t1.value11.EspBoxes = p71
    t1.value12()
    t1.value46()
end)
v53("ESP", "Health Bar ESP", "EspHealth", function(p72)
    t1.value11.EspHealth = p72
    t1.value12()
    t1.value46()
end)
v53("ESP", "Name ESP", "EspNames", function(p73)
    t1.value11.EspNames = p73
    t1.value12()
    t1.value46()
end)
v53("ESP", "Distance ESP", "EspDistance", function(p74)
    t1.value11.EspDistance = p74
    t1.value12()
    t1.value46()
end)
v53("ESP", "Health Number", "EspHealthNumber", function(p75)
    t1.value11.EspHealthNumber = p75
    t1.value12()
    t1.value46()
end)
v53("ESP", "Cham", "EspChams", function(p76)
    t1.value11.EspChams = p76
    t1.value12()
    t1.value46()
end)
v53("Unlock All", "Unlock All", "UnlockAll", function(p77)
    if p77 then
        t1.value86()
    end
end)
v53("Auto", "Auto Collect", "AutoCollect", v61)
v53("Auto", "Auto Queue", "AutoQueueEnabled", function(p78)
    t1.value97.enabled = p78
    t1.value11.AutoQueueEnabled = p78
    t1.value12()
end)
v55("Auto", "Queue Mode", "AutoQueueMode", {
	"1v1",
	"2v2",
	"3v3",
	"4v4",
	"5v5",
	"ranked 1v1",
	"ranked 2v2",
	"ranked 3v3"
}, function(p79)
    t1.value97.mode = p79
    t1.value97.ranked = p79:find("ranked") ~= nil
    t1.value11.AutoQueueMode = p79
    t1.value12()
end)
v53("Auto", "Auto Loadout", "AutoLoadoutEnabled", function(p80)
    t1.value11.AutoLoadoutEnabled = p80
    t1.value12()
end)
v55("Auto", "Primary", "PrimaryWeapon", {
	"Assault Rifle",
	"Burst Rifle",
	"SMG",
	"Shotgun",
	"Sniper",
	"Revolver",
	"RPG",
	"Crossbow",
	"Minigun",
	"Plasma Rifle"
}, function(p81)
    t1.value98[1] = p81
    t1.value11.PrimaryWeapon = p81
    t1.value12()
end)
v55("Auto", "Secondary", "SecondaryWeapon", {
	"Handgun",
	"Machine Pistol",
	"Sawed Off",
	"Uzi",
	"Revolver"
}, function(p82)
    t1.value98[2] = p82
    t1.value11.SecondaryWeapon = p82
    t1.value12()
end)
v55("Auto", "Melee", "MeleeWeapon", {
	"Katana",
	"Baseball Bat",
	"Knife",
	"Sledgehammer",
	"Fists"
}, function(p83)
    t1.value98[3] = p83
    t1.value11.MeleeWeapon = p83
    t1.value12()
end)
v55("Auto", "Utility", "UtilityWeapon", {
	"Medkit",
	"Grenade",
	"Flashbang",
	"Jump Pad",
	"Molotov",
	"Satchel",
	"Smoke Grenade",
	"War Horn",
	"Subspace Tripmine",
	"Warpstone"
}, function(p84)
    t1.value98[4] = p84
    t1.value11.UtilityWeapon = p84
    t1.value12()
end)
v52("Misc", "Fly Mode", "Fly", 20, 200, "FlySpeed", "", function(p85)
    if p85 then
        t1.value57()

        return
    end

    t1.value58()
end, function(p86)
    t1.value11.FlySpeed = p86
    t1.value12()
end)
v53("Misc", "Infinite Jump", "InfiniteJump", function(p87)
    if p87 then
        t1.value61()

        return
    end

    t1.value62()
end)
v53("Misc", "Noclip", "Noclip", function(p88)
    if p88 then
        t1.value63()

        return
    end

    t1.value64()
end)
v53("Settings", "Enable Animation", "AnimationEnabled", v60)
v55("Settings", "Anim Preset", "AnimationPreset", {
	"Underground Glitch",
	"Orbit",
	"Tweaking",
	"Kicking Feet",
	"Low Cortisol",
	"Floss",
	"Take the L",
	"Upside Down",
	"Michael Myers Shake",
	"Headless",
	"Wall Peek L",
	"Glitch Through"
}, function(p89)
    t1.value11.AnimationPreset = p89
    t1.value12()

    local v394 = t1.value79[p89]

    if v394 then
        t1.value75.animationId = v394

        if t1.value75.enabled then
            v59()
        end
    end
end)
task.wait(0.1)
for _, v in pairs(t1.value17) do
    v.scroll.CanvasSize = UDim2.new(0, 0, 0, v.layout.AbsoluteContentSize.Y + 10)
end
t1.value101 = false
t1.value102 = nil
t1.value103 = nil
t1.value14.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        t1.value101 = true
        t1.value102 = input.Position
        t1.value103 = t1.value14.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                t1.value101 = false
            end
        end)
    end
end)
t1.value2.InputChanged:Connect(function(input)
    local value101 = t1.value101

    if value101 then
        value101 = input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch
    end

    if value101 then
        local v470 = input.Position - t1.value102

        t1.value14.Position = UDim2.new(t1.value103.X.Scale, t1.value103.X.Offset + v470.X, t1.value103.Y.Scale, t1.value103.Y.Offset + v470.Y)
    end
end)
t1.value104 = nil
if t1.value9 then
    t1.value104 = Instance.new("TextButton")
    t1.value104.Size = UDim2.new(0, 24, 0, 24)
    t1.value104.Position = UDim2.new(0, 6, 0.5, -12)
    t1.value104.BackgroundColor3 = t1.value10.Surface
    t1.value104.BackgroundTransparency = 0
    t1.value104.BorderSizePixel = 0
    t1.value104.Text = "X"
    t1.value104.Font = t1.value10.Font
    t1.value104.TextSize = 12
    t1.value104.TextColor3 = t1.value10.Text
    t1.value104.ZIndex = 999999
    t1.value104.AutoButtonColor = false
    t1.value104.Parent = ScreenGui
    t1.value104.MouseButton1Click:Connect(function()
        t1.value14.Visible = not t1.value14.Visible
        t1.value104.Text = not t1.value14.Visible and ">" or "X"
    end)
end
if v4 then
    t1.value2.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then
            return
        end

        if input.KeyCode == Enum.KeyCode.RightShift then
            t1.value14.Visible = not t1.value14.Visible
        end
    end)
end
if t1.value11.Ragebot then
    t1.value21()
end
if t1.value11.AutoShoot then
    t1.value41()
end
if t1.value11.RapidFire then
    t1.value47()
end
if t1.value11.Fly then
    t1.value57()
end
if t1.value11.InfiniteJump then
    t1.value61()
end
if t1.value11.Noclip then
    t1.value63()
end
if t1.value11.Esp then
    t1.value73()
end
if t1.value11.AnimationEnabled then
    v60(true)
end
if t1.value11.AutoCollect then
    v61(true)
end
if t1.value11.UnlockAll then
    t1.value86()
end
if t1.value11.FOVEnabled then
    t1.value87.enabled = true
end
if t1.value11.FOVRadius then
    t1.value87.radius = t1.value11.FOVRadius
end
if t1.value11.FOVFollowMuzzle then
    t1.value87.followMuzzle = true
end
if t1.value11.FOVFilled then
    t1.value87.FilledEnabled = true
    t1.value90.Visible = true
end
if t1.value11.FOVSpin then
    t1.value87.SpinOn = true
end
if t1.value11.FOVSpinSpeed then
    t1.value87.SpinSpd = t1.value11.FOVSpinSpeed
end
if t1.value11.FOVAnimated then
    t1.value87.FilledAnimated = true
end
if t1.value11.AutoQueueEnabled then
    t1.value97.enabled = true
end
pcall(function()
    if writefile and (isfolder and makefolder) then
        if not isfolder("autoexec") then
            makefolder("autoexec")
        end

        local source = debug.getinfo(1, "S").source

        if source and source:sub(1, 1) == "@" then
            local v474 = source:sub(2)

            if isfile(v474) then
                local v475 = readfile(v474)

                writefile("autoexec/private_ui.lua", v475)
            end
        end
    end
end)
