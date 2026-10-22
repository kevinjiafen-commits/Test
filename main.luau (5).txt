-- Errors --
-- 1: no local player found
-- 2: player gui not loading

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")
local Lighting = game:GetService("Lighting")
local Stats = game:GetService("Stats")

if _G.__LilacCleanup then pcall(_G.__LilacCleanup) end

print("[Lilac Premium] starting...")
local LILAC_FULL_PLACE = 17625359962
local lilacFullGame = (game.PlaceId == LILAC_FULL_PLACE)
shared.LilacFullGame = lilacFullGame
print("lilac loaded")

local player = Players.LocalPlayer
if not player then
	warn("error: make a ticket error code: 1")
	return
end
local playerGui = player:WaitForChild("PlayerGui", 10)
if not playerGui then
	warn("error: make a ticket error code: 2")
	return
end
for _, n in ipairs({ "LilacUI", "LilacHUD", "LilaecCursor" }) do
	local s = playerGui:FindFirstChild(n)
	if s then s:Destroy() end
end

--------------------------------------------------------------------------
-- lifecycle
--------------------------------------------------------------------------
local connections = {}
local cleanups = {}
local gui

local function connect(signal, fn)
	local c = signal:Connect(fn)
	table.insert(connections, c)
	return c
end

local function unload()
	for _, f in ipairs(cleanups) do pcall(f) end
	table.clear(cleanups)
	for _, c in ipairs(connections) do
		pcall(function() c:Disconnect() end)
	end
	table.clear(connections)
	if gui then gui:Destroy() end
	_G.__LilacBinding = nil
	_G.__LilacCleanup = nil
end
_G.__LilacCleanup = unload

--------------------------------------------------------------------------
-- platform
--------------------------------------------------------------------------
local forcedPlatform = _G.LilacPlatform
local function deviceClass()
	if forcedPlatform then return forcedPlatform end
	local U = UserInputService
	if U.TouchEnabled and not U.KeyboardEnabled then return "Mobile" end
	if U.GamepadEnabled and not U.KeyboardEnabled and not U.MouseEnabled and not U.TouchEnabled then return "Console" end
	return "PC"
end
local platform = deviceClass() -- device class, used for layout
local isMobile = platform == "Mobile"
local activePlat = platform -- input class, follows the last input you used
local Hooks: { setOpen: ((boolean) -> ())?, platform: (() -> ())? } = {}
local Menu = { open = false }

local function inputClass()
	if forcedPlatform then return forcedPlatform end
	local n = UserInputService:GetLastInputType().Name
	if n == "Touch" then return "Mobile" end
	if n:sub(1, 7) == "Gamepad" then return "Console" end
	if n:sub(1, 5) == "Mouse" or n == "Keyboard" then return "PC" end
	return activePlat
end
local function defKey(pc, pad)
	return platform == "Console" and pad or pc
end

--------------------------------------------------------------------------
-- constants / theme
--------------------------------------------------------------------------
local RW, RH = 1360, 650
local MAIN_W = 1080
local SIDEBAR_W = 200
if isMobile then RW, RH, MAIN_W, SIDEBAR_W = 820, 400, 820, 150 end
local PREVIEW_W = 260
local CONTENT_W = MAIN_W - SIDEBAR_W

local BODY = Enum.Font.GothamMedium
local LIGHT = Enum.Font.Gotham
local BOLD = Enum.Font.GothamBold
local HEAD = Enum.Font.Merriweather

local Theme = {
	Bg = Color3.fromRGB(10, 6, 14),
	Sidebar = Color3.fromRGB(14, 8, 18),
	Card = Color3.fromRGB(22, 12, 28),
	CardHead = Color3.fromRGB(32, 18, 40),
	Field = Color3.fromRGB(12, 7, 16),
	Border = Color3.fromRGB(78, 42, 78),
	Text = Color3.fromRGB(250, 240, 250),
	Muted = Color3.fromRGB(160, 130, 165),
	Off = Color3.fromRGB(48, 32, 52),
	Accent = Color3.fromRGB(245, 140, 210),
	Accent2 = Color3.fromRGB(180, 100, 240),
	Glow = Color3.fromRGB(255, 160, 230),
	Glass = Color3.fromRGB(30, 16, 36),
}

local Presets = {
	Lilac = { Color3.fromRGB(240, 130, 200), Color3.fromRGB(176, 92, 232) },
	Rose = { Color3.fromRGB(255, 110, 140), Color3.fromRGB(255, 160, 110) },
	Violet = { Color3.fromRGB(150, 110, 255), Color3.fromRGB(100, 150, 255) },
	Ice = { Color3.fromRGB(110, 200, 255), Color3.fromRGB(150, 130, 255) },
	Mint = { Color3.fromRGB(110, 235, 190), Color3.fromRGB(90, 170, 255) },
	Amber = { Color3.fromRGB(255, 190, 90), Color3.fromRGB(255, 120, 90) },
}

local Environments = {
	Default = Color3.fromRGB(9, 8, 13),
	Night = Color3.fromRGB(4, 6, 18),
	Soft = Color3.fromRGB(44, 32, 50),
	Neon = Color3.fromRGB(14, 4, 26),
}

local FontMap = {
	Gotham = Enum.Font.GothamMedium,
	Code = Enum.Font.Code,
	Merriweather = Enum.Font.Merriweather,
}

--------------------------------------------------------------------------
-- settings registry
--------------------------------------------------------------------------
local Settings, Defaults, Controls, Handlers = {}, {}, {}, {}
local TabKeys = {}
local bulk = false
local previewDirty = true

local function commit(key, value)
	Settings[key] = value
	previewDirty = true
	local h = Handlers[key]
	if h then h(value) end
end

local function applySetting(key, value)
	local c = Controls[key]
	if c then c.apply(value) end
	commit(key, value)
end

--------------------------------------------------------------------------
-- helpers
--------------------------------------------------------------------------
local function create(className, props, parent)
	local obj = Instance.new(className)
	if props then
		for k, v in pairs(props) do obj[k] = v end
	end
	if parent then obj.Parent = parent end
	return obj
end

local function corner(parent, r)
	return create("UICorner", { CornerRadius = UDim.new(0, r or 8) }, parent)
end

local function round(parent)
	return create("UICorner", { CornerRadius = UDim.new(1, 0) }, parent)
end

local function stroke(parent, color, thickness, transparency)
	return create("UIStroke", {
		Color = color or Theme.Border,
		Thickness = thickness or 1,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, parent)
end

local function pad(parent, t, r, b, l)
	return create("UIPadding", {
		PaddingTop = UDim.new(0, t or 0),
		PaddingRight = UDim.new(0, r or t or 0),
		PaddingBottom = UDim.new(0, b or t or 0),
		PaddingLeft = UDim.new(0, l or r or t or 0),
	}, parent)
end

local function tween(obj, props, dur, style, dir)
	local t = TweenService:Create(
		obj,
		TweenInfo.new(dur or 0.18, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out),
		props
	)
	t:Play()
	return t
end

local function text(parent, str, size, color, font, align)
	return create("TextLabel", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = str,
		TextSize = size,
		TextColor3 = color or Theme.Text,
		Font = font or BODY,
		TextXAlignment = align or Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		Size = UDim2.new(1, 0, 0, size + 6),
	}, parent)
end

local function contrast(c)
	local lum = c.R * 0.299 + c.G * 0.587 + c.B * 0.114
	return lum > 0.6 and Color3.fromRGB(20, 10, 24) or Color3.new(1, 1, 1)
end

local function hex(c)
	return "#" .. c:ToHex():upper()
end

local function prettyKey(n)
	n = tostring(n or "None")
	n = n:gsub("MouseButton", "Mouse "):gsub("^Button", "Pad ")
	return n
end

local function pointer(i)
	if i.UserInputType == Enum.UserInputType.Touch then
		local inset = GuiService:GetGuiInset()
		return Vector2.new(i.Position.X + inset.X, i.Position.Y + inset.Y)
	end
	return UserInputService:GetMouseLocation()
end

local function isPress(i)
	return i.UserInputType == Enum.UserInputType.MouseButton1
		or i.UserInputType == Enum.UserInputType.Touch
end

local function isMove(i)
	return i.UserInputType == Enum.UserInputType.MouseMovement
		or i.UserInputType == Enum.UserInputType.Touch
end

local function lastInputIsPad()
	return UserInputService:GetLastInputType().Name:sub(1, 7) == "Gamepad"
end

-- universal binds: keyboard key name, MouseButtonN, or controller button name, all in one string
local function matchesBind(i, name)
	if not name or name == "None" then return false end
	local ut = i.UserInputType
	if ut == Enum.UserInputType.Keyboard or ut.Name:sub(1, 7) == "Gamepad" then return i.KeyCode.Name == name end
	return ut.Name == name
end

local keyEnumCache = {}
local function bindDown(name)
	if not name or name == "None" then return false end
	if name:sub(1, 11) == "MouseButton" then
		local ok, ut = pcall(function() return Enum.UserInputType[name] end)
		return (ok and ut and UserInputService:IsMouseButtonPressed(ut)) or false
	end
	local kc = keyEnumCache[name]
	if kc == nil then
		local ok, v = pcall(function() return Enum.KeyCode[name] end)
		kc = ok and v or false
		keyEnumCache[name] = kc
	end
	if not kc then return false end
	if UserInputService:IsKeyDown(kc) then return true end
	local okG, down = pcall(UserInputService.IsGamepadButtonDown, UserInputService, Enum.UserInputType.Gamepad1, kc)
	return (okG and down) or false
end

local accentBinds = {}
local function bindAccent(fn)
	table.insert(accentBinds, fn)
	fn()
end
local function refreshAccent()
	for _, fn in ipairs(accentBinds) do fn() end
end

-- vector icons built from frames (no unicode glyphs, so nothing renders as a box)
local function makeIcon(kind, parent)
	local holder = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(20, 20),
	}, parent)
	local fills, strokes = {}, {}

	local function shape(o)
		local f = create("Frame", {
			BackgroundTransparency = o.fill and 0 or 1,
			BackgroundColor3 = Theme.Muted,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(o.x, o.y),
			Size = UDim2.fromOffset(o.w, o.h),
			Rotation = o.rot or 0,
		}, holder)
		if o.round then round(f) elseif o.r then corner(f, o.r) end
		if o.fill then
			table.insert(fills, f)
		else
			table.insert(strokes, stroke(f, Theme.Muted, o.th or 1.5))
		end
	end

	if kind == "Combat" then
		shape({ x = 10, y = 10, w = 12, h = 12, round = true, th = 1.5 })
		shape({ x = 10, y = 2.5, w = 2, h = 5, fill = true })
		shape({ x = 10, y = 17.5, w = 2, h = 5, fill = true })
		shape({ x = 2.5, y = 10, w = 5, h = 2, fill = true })
		shape({ x = 17.5, y = 10, w = 5, h = 2, fill = true })
		shape({ x = 10, y = 10, w = 2.5, h = 2.5, round = true, fill = true })
	elseif kind == "ESP" then
		shape({ x = 10, y = 10, w = 18, h = 11, r = 6, th = 1.5 })
		shape({ x = 10, y = 10, w = 5, h = 5, round = true, fill = true })
	elseif kind == "Visuals" then
		shape({ x = 10, y = 10, w = 11, h = 11, r = 2, th = 1.5, rot = 45 })
		shape({ x = 10, y = 10, w = 4, h = 4, r = 1, fill = true, rot = 45 })
	elseif kind == "World" then
		shape({ x = 10, y = 10, w = 16, h = 16, round = true, th = 1.5 })
		shape({ x = 10, y = 10, w = 16, h = 1.5, fill = true })
		shape({ x = 10, y = 10, w = 7, h = 16, round = true, th = 1.2 })
	elseif kind == "Character" then
		shape({ x = 10, y = 5.5, w = 7, h = 7, round = true, th = 1.5 })
		shape({ x = 10, y = 14.5, w = 14, h = 7, r = 4, th = 1.5 })
	elseif kind == "Misc" then
		for _, p in ipairs({ { 5, 5 }, { 15, 5 }, { 5, 15 }, { 15, 15 } }) do
			shape({ x = p[1], y = p[2], w = 7, h = 7, r = 2, th = 1.5 })
		end
	elseif kind == "Settings" then
		shape({ x = 10, y = 10, w = 11, h = 11, round = true, th = 2 })
		shape({ x = 10, y = 2, w = 3, h = 4, fill = true })
		shape({ x = 10, y = 18, w = 3, h = 4, fill = true })
		shape({ x = 2, y = 10, w = 4, h = 3, fill = true })
		shape({ x = 18, y = 10, w = 4, h = 3, fill = true })
	end

	local function setColor(c)
		for _, f in ipairs(fills) do f.BackgroundColor3 = c end
		for _, s in ipairs(strokes) do s.Color = c end
	end
	return holder, setColor
end

local function chevron(parent, pos)
	local h = create("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = pos,
		Size = UDim2.fromOffset(10, 10),
	}, parent)
	for _, d in ipairs({ { 3.2, 45 }, { 6.8, -45 } }) do
		create("Frame", {
			BackgroundColor3 = Theme.Muted,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(d[1], 4.5),
			Size = UDim2.fromOffset(6, 1.6),
			Rotation = d[2],
		}, h)
	end
	return h
end

-- chevron-style direction arrow. holder.Position = tip, holder.Rotation = direction in degrees (0 = right)
local function makeArrow(parent, z)
	local holder = create("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(0, 0),
		Visible = false,
		ZIndex = z or 6,
	}, parent)
	local arms = {}
	local L, a = 14, math.rad(38)
	for _, sgn in ipairs({ 1, -1 }) do
		local f = create("Frame", {
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(L, 3),
			Position = UDim2.fromOffset(-math.cos(a) * L / 2, sgn * math.sin(a) * L / 2),
			Rotation = -sgn * math.deg(a),
			ZIndex = z or 6,
		}, holder)
		corner(f, 2)
		table.insert(arms, f)
	end
	return holder, function(c)
		for _, f in ipairs(arms) do f.BackgroundColor3 = c end
	end
end

local function makeButton(parent, label, w, h, primary)
	local b = create("TextButton", {
		Text = label,
		Font = BODY,
		TextSize = 11,
		AutoButtonColor = false,
		TextColor3 = primary and Color3.fromRGB(24, 10, 28) or Theme.Text,
		BackgroundColor3 = primary and Theme.Accent or Theme.CardHead,
		Size = UDim2.fromOffset(w, h),
		BorderSizePixel = 0,
	}, parent)
	corner(b, 8)
	local s = stroke(b, primary and Theme.Accent or Theme.Border, 1)
	bindAccent(function()
		if primary then
			b.BackgroundColor3 = Theme.Accent
			s.Color = Theme.Accent
		end
	end)
	b.MouseEnter:Connect(function()
		tween(b, { BackgroundTransparency = 0.25 }, 0.1)
	end)
	b.MouseLeave:Connect(function()
		tween(b, { BackgroundTransparency = 0 }, 0.1)
	end)
	return b
end

local function dragInput(guiObject, onPos, bag)
	bag = bag or connections
	local active = false
	table.insert(bag, guiObject.InputBegan:Connect(function(i)
		if isPress(i) then
			active = true
			onPos(pointer(i))
		end
	end))
	table.insert(bag, UserInputService.InputChanged:Connect(function(i)
		if active and isMove(i) then onPos(pointer(i)) end
	end))
	table.insert(bag, UserInputService.InputEnded:Connect(function(i)
		if isPress(i) then active = false end
	end))
end

--------------------------------------------------------------------------
-- screen guis
--------------------------------------------------------------------------
gui = create("ScreenGui", {
	Name = "LilacUI",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 1000,
}, playerGui)

-- ESP / FOV / HUD live here so they keep working while the menu is closed
local hudGui = create("ScreenGui", {
	Name = "LilacHUD",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 500,
}, playerGui)

-- software cursor, always drawn above the menu (fixes the cursor hiding under the UI in first person)
local cursorGui = create("ScreenGui", {
	Name = "LilacCursor",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 2000,
}, playerGui)
table.insert(cleanups, function()
	hudGui:Destroy()
	cursorGui:Destroy()
end)

local root = create("Frame", {
	Name = "Root",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(RW, RH),
	BackgroundTransparency = 1,
}, gui)

local dim = create("TextButton", {
	Name = "Dim",
	Selectable = false,
	Text = "",
	AutoButtonColor = false,
	BackgroundColor3 = Color3.new(0, 0, 0),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Size = UDim2.fromScale(1, 1),
	ZIndex = 0,
	Visible = false,
}, gui)
local uiScale = create("UIScale", {}, root)
local userScale = 1
local openAnim = 1
local function fit()
	local v = gui.AbsoluteSize
	local s = math.min(1, (v.X - 32) / RW, (v.Y - 32) / RH)
	uiScale.Scale = math.max(0.4, s) * userScale * openAnim
end
local animVal = create("NumberValue", { Value = 1 })
connect(animVal.Changed, function(v)
	openAnim = v
	fit()
end)
connect(gui:GetPropertyChangedSignal("AbsoluteSize"), fit)
fit()

-- layered glow behind the window
local glowOuter = create("Frame", {
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(-5, -5),
	Size = UDim2.fromOffset(MAIN_W + 10, RH + 10),
}, root)
corner(glowOuter, 20)
local glowOuterStroke = stroke(glowOuter, Theme.Accent, 10, 0.78)

local glowInner = create("Frame", {
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(-2, -2),
	Size = UDim2.fromOffset(MAIN_W + 4, RH + 4),
}, root)
corner(glowInner, 17)
local glowInnerStroke = stroke(glowInner, Theme.Accent, 4, 0.45)

local main = create("Frame", {
	Name = "Main",
	BackgroundColor3 = Color3.new(1, 1, 1),
	Size = UDim2.fromOffset(MAIN_W, RH),
	BorderSizePixel = 0,
	ClipsDescendants = true,
}, root)
corner(main, 15)
create("UIGradient", {
	Rotation = 125,
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(28, 14, 34)),
		ColorSequenceKeypoint.new(0.45, Color3.fromRGB(16, 9, 20)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 4, 12)),
	}),
}, main)
local mainStroke = stroke(main, Theme.Accent, 1.5, 0.05)

bindAccent(function()
	glowOuterStroke.Color = Theme.Accent
	glowInnerStroke.Color = Theme.Accent
	mainStroke.Color = Theme.Accent
end)

-- falling petals layer (behind everything else in the window)
local petals = {}
do
	local fx = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ClipsDescendants = true,
	}, main)
	for i = 1, 30 do
		local f = create("Frame", {
			BackgroundColor3 = Theme.Accent,
			BackgroundTransparency = 0.5,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(math.random(7, 11), math.random(5, 8)),
			Visible = false,
		}, fx)
		corner(f, 5)
		petals[i] = {
			f = f,
			x = math.random(0, MAIN_W),
			y = math.random(-40, RH),
			vy = math.random(16, 36),
			vx = math.random(-10, 6),
			rot = math.random(0, 360),
			vr = math.random(-60, 60),
			ph = math.random() * 6,
		}
	end
	bindAccent(function()
		for _, p in ipairs(petals) do p.f.BackgroundColor3 = Theme.Accent end
	end)
end

--------------------------------------------------------------------------
-- sidebar
--------------------------------------------------------------------------
local sidebar, navHolder, pSub
do
	sidebar = create("Frame", {
		Name = "Sidebar",
		BackgroundColor3 = Theme.Sidebar,
		BackgroundTransparency = 0.15,
		Size = UDim2.new(0, SIDEBAR_W, 1, 0),
		BorderSizePixel = 0,
	}, main)
	create("Frame", {
		BackgroundColor3 = Theme.Border,
		BackgroundTransparency = 0.4,
		BorderSizePixel = 0,
		Position = UDim2.new(1, -1, 0, 0),
		Size = UDim2.new(0, 1, 1, 0),
	}, sidebar)

	local logo = create("Frame", {
		BackgroundColor3 = Theme.CardHead,
		Position = UDim2.fromOffset(14, 13),
		Size = UDim2.fromOffset(38, 38),
		BorderSizePixel = 0,
	}, sidebar)
	corner(logo, 11)
	local logoStroke = stroke(logo, Theme.Accent, 1.2)
	local logoText = text(logo, "L", 21, Theme.Accent, HEAD, Enum.TextXAlignment.Center)
	logoText.Size = UDim2.fromScale(1, 1)
	bindAccent(function()
		logoStroke.Color = Theme.Accent
		logoText.TextColor3 = Theme.Accent
	end)

	local brand = text(sidebar, "Lilac", 18, Theme.Text, HEAD)
	brand.Position = UDim2.fromOffset(62, 12)
	brand.Size = UDim2.new(1, -70, 0, 24)
	local brandSub = text(sidebar, "PREMIUM  ·  v4.0", 8, Theme.Muted, LIGHT)
	brandSub.Position = UDim2.fromOffset(63, 36)
	brandSub.Size = UDim2.new(1, -70, 0, 14)

	local modulesLbl = text(sidebar, "MODULES", 9, Theme.Muted, BOLD)
	modulesLbl.Position = UDim2.fromOffset(20, 58)
	modulesLbl.Size = UDim2.new(1, -40, 0, 14)

	navHolder = create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, isMobile and 62 or 78),
		Size = UDim2.new(1, -24, 0, 380),
	}, sidebar)
	create("UIListLayout", { Padding = UDim.new(0, isMobile and 4 or 6), SortOrder = Enum.SortOrder.LayoutOrder }, navHolder)

	local profile = create("Frame", {
		BackgroundColor3 = Theme.Card,
		Position = UDim2.new(0, 12, 1, -68),
		Size = UDim2.new(1, -24, 0, 54),
		BorderSizePixel = 0,
	}, sidebar)
	corner(profile, 12)
	stroke(profile, Theme.Border, 1, 0.2)

	local avatar = create("ImageLabel", {
		BackgroundColor3 = Theme.CardHead,
		Position = UDim2.fromOffset(8, 8),
		Size = UDim2.fromOffset(38, 38),
		BorderSizePixel = 0,
		Image = "",
	}, profile)
	corner(avatar, 9)
	task.spawn(function()
		local ok, img = pcall(function()
			return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
		end)
		if ok and avatar.Parent then avatar.Image = img end
	end)

	local pName = text(profile, player.DisplayName, 12, Theme.Text, BODY)
	pName.Position = UDim2.fromOffset(56, 9)
	pName.Size = UDim2.new(1, -62, 0, 18)
	pName.TextTruncate = Enum.TextTruncate.AtEnd
	pSub = text(profile, "Lilac Premium  ·  " .. (lilacFullGame and "FULL" or "UNI") .. "  ·  " .. activePlat, 10, Theme.Muted, LIGHT)
	pSub.Position = UDim2.fromOffset(56, 28)
	pSub.Size = UDim2.new(1, -62, 0, 14)
	if isMobile then profile.Visible = false; modulesLbl.Visible = false end
end

--------------------------------------------------------------------------
-- top bar (inside main so minimizing keeps it)
--------------------------------------------------------------------------
local pageTitle, searchBox, fpsLabel, minButton
do
	local dragBar = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 56),
		Active = true,
	}, main)

	pageTitle = text(main, "ESP", 17, Theme.Text, HEAD)
	pageTitle.Position = UDim2.fromOffset(SIDEBAR_W + 22, 0)
	pageTitle.Size = UDim2.fromOffset(120, 56)
	local topLine = create("Frame", {
		BackgroundColor3 = Theme.Accent,
		BackgroundTransparency = 0.6,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(SIDEBAR_W, 55),
		Size = UDim2.fromOffset(MAIN_W - SIDEBAR_W, 1),
	}, main)
	create("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(0.6, 0.7), NumberSequenceKeypoint.new(1, 1),
		}),
	}, topLine)
	bindAccent(function() topLine.BackgroundColor3 = Theme.Accent end)
	fpsLabel = text(main, "", 10, Theme.Muted, BODY, Enum.TextXAlignment.Right)
	fpsLabel.Position = UDim2.new(1, -250, 0, 0)
	fpsLabel.Size = UDim2.fromOffset(160, 56)

	searchBox = create("TextBox", {
		Name = "Search",
		Text = "",
		PlaceholderText = "Search settings...",
		ClearTextOnFocus = false,
		Font = LIGHT,
		TextSize = 12,
		TextColor3 = Theme.Text,
		PlaceholderColor3 = Theme.Muted,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundColor3 = Theme.Field,
		Position = UDim2.fromOffset(SIDEBAR_W + 140, 12),
		Size = UDim2.fromOffset(isMobile and 330 or 440, 32),
		BorderSizePixel = 0,
	}, main)
	corner(searchBox, 10)
	local searchStroke = stroke(searchBox, Theme.Border, 1)
	pad(searchBox, 0, 10, 0, 36)
	local ring = create("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(-19, 15),
		Size = UDim2.fromOffset(10, 10),
	}, searchBox)
	round(ring)
	stroke(ring, Theme.Muted, 1.5)
	create("Frame", {
		BackgroundColor3 = Theme.Muted,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(-12.5, 21),
		Size = UDim2.fromOffset(6, 1.6),
		Rotation = 45,
	}, searchBox)
	connect(searchBox.Focused, function() tween(searchStroke, { Color = Theme.Accent }, 0.12) end)
	connect(searchBox.FocusLost, function() tween(searchStroke, { Color = Theme.Border }, 0.12) end)

	local function windowButton(offsetX, kind)
		local b = create("TextButton", {
			Text = "",
			AutoButtonColor = false,
			BackgroundColor3 = Theme.CardHead,
			BackgroundTransparency = 1,
			Position = UDim2.new(1, offsetX, 0, 13),
			Size = UDim2.fromOffset(30, 30),
			BorderSizePixel = 0,
		}, main)
		corner(b, 8)
		local bars = {}
		local function bar(rot)
			local f = create("Frame", {
				BackgroundColor3 = Theme.Muted,
				BorderSizePixel = 0,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(12, 1.6),
				Rotation = rot,
			}, b)
			table.insert(bars, f)
		end
		if kind == "close" then bar(45); bar(-45) else bar(0) end
		b.MouseEnter:Connect(function()
			tween(b, { BackgroundTransparency = 0 }, 0.1)
			for _, f in ipairs(bars) do f.BackgroundColor3 = Theme.Text end
		end)
		b.MouseLeave:Connect(function()
			tween(b, { BackgroundTransparency = 1 }, 0.1)
			for _, f in ipairs(bars) do f.BackgroundColor3 = Theme.Muted end
		end)
		return b
	end

	minButton = windowButton(-76, "min")
	local closeButton = windowButton(-42, "close")
	closeButton.Activated:Connect(function()
		if Hooks.setOpen then Hooks.setOpen(false) end
	end)

	-- window dragging
	local drag = { active = false }
	connect(dragBar.InputBegan, function(i)
		if Settings["set.lock"] then return end
		if isPress(i) then
			drag.active = true
			drag.start = Vector2.new(i.Position.X, i.Position.Y)
			drag.origin = root.Position
		end
	end)
	connect(UserInputService.InputChanged, function(i)
		if drag.active and isMove(i) then
			local d = Vector2.new(i.Position.X, i.Position.Y) - drag.start
			root.Position = UDim2.new(
				drag.origin.X.Scale, drag.origin.X.Offset + d.X,
				drag.origin.Y.Scale, drag.origin.Y.Offset + d.Y
			)
		end
	end)
	connect(UserInputService.InputEnded, function(i)
		if isPress(i) then drag.active = false end
	end)
end

--------------------------------------------------------------------------
-- content container
--------------------------------------------------------------------------
local content = create("Frame", {
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(SIDEBAR_W, 0),
	Size = UDim2.fromOffset(CONTENT_W, RH),
}, main)

local moduleLabel = text(content, "", 11, Theme.Muted, LIGHT)
moduleLabel.Position = UDim2.fromOffset(22, 56)
moduleLabel.Size = UDim2.fromOffset(300, 20)

--------------------------------------------------------------------------
-- overlay: popups, tooltip, toasts, confirm
--------------------------------------------------------------------------
local overlay = create("Frame", {
	Name = "Overlay",
	BackgroundTransparency = 1,
	Size = UDim2.fromScale(1, 1),
	ZIndex = 100,
}, root)

local catcher = create("TextButton", {
	Selectable = false,
	Text = "",
	AutoButtonColor = false,
	BackgroundTransparency = 1,
	Size = UDim2.fromScale(1, 1),
	ZIndex = 50,
	Visible = false,
}, overlay)

local popup
local popupConns = {}
local function closePopup()
	if popup then popup:Destroy(); popup = nil end
	catcher.Visible = false
	for _, c in ipairs(popupConns) do c:Disconnect() end
	table.clear(popupConns)
end
catcher.Activated:Connect(closePopup)

local function openPopup(anchor, size, build)
	closePopup()
	catcher.Visible = true
	local s = uiScale.Scale
	local rel = (anchor.AbsolutePosition - root.AbsolutePosition) / s
	local asz = anchor.AbsoluteSize / s
	local x = math.clamp(rel.X + asz.X - size.X, 8, RW - size.X - 8)
	local y = rel.Y + asz.Y + 6
	if y + size.Y > RH - 8 then y = rel.Y - size.Y - 6 end
	popup = create("Frame", {
		BackgroundColor3 = Theme.Card,
		Position = UDim2.fromOffset(x, y),
		Size = UDim2.fromOffset(size.X, size.Y),
		BorderSizePixel = 0,
		ZIndex = 60,
	}, overlay)
	corner(popup, 11)
	stroke(popup, Theme.Accent, 1, 0.4)
	build(popup)
	return popup
end

-- tooltip
local tipActive = false
local tipFrame = create("Frame", {
	BackgroundColor3 = Theme.CardHead,
	AutomaticSize = Enum.AutomaticSize.XY,
	Size = UDim2.fromOffset(0, 0),
	Visible = false,
	ZIndex = 300,
	BorderSizePixel = 0,
}, gui)
corner(tipFrame, 7)
stroke(tipFrame, Theme.Border, 1)
pad(tipFrame, 6, 10, 6, 10)
local tipLabel = create("TextLabel", {
	BackgroundTransparency = 1,
	AutomaticSize = Enum.AutomaticSize.XY,
	Size = UDim2.fromOffset(0, 0),
	Font = LIGHT,
	TextSize = 11,
	TextColor3 = Theme.Text,
	Text = "",
}, tipFrame)

-- toasts (live in the HUD gui so they show with the menu closed too)
local toastHolder = create("Frame", {
	BackgroundTransparency = 1,
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -20, 1, -20),
	Size = UDim2.fromOffset(300, 400),
	ZIndex = 50,
}, hudGui)
create("UIListLayout", {
	VerticalAlignment = Enum.VerticalAlignment.Bottom,
	HorizontalAlignment = Enum.HorizontalAlignment.Right,
	Padding = UDim.new(0, 8),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, toastHolder)

local toastCount = 0
local function notify(title, msg)
	if Settings["misc.notify"] == false then return end
	toastCount += 1
	local holder = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(290, 56),
		LayoutOrder = toastCount,
		ZIndex = 50,
	}, toastHolder)
	local card = create("Frame", {
		BackgroundColor3 = Theme.Card,
		Position = UDim2.fromOffset(320, 0),
		Size = UDim2.fromScale(1, 1),
		BorderSizePixel = 0,
		ZIndex = 51,
	}, holder)
	corner(card, 11)
	stroke(card, Theme.Border, 1)
	local bar = create("Frame", {
		BackgroundColor3 = Theme.Accent,
		Position = UDim2.fromOffset(8, 12),
		Size = UDim2.new(0, 3, 1, -24),
		BorderSizePixel = 0,
		ZIndex = 52,
	}, card)
	round(bar)
	local t = text(card, title, 12, Theme.Text, HEAD)
	t.Position = UDim2.fromOffset(22, 8)
	t.Size = UDim2.new(1, -30, 0, 18)
	t.ZIndex = 52
	local m = text(card, msg, 11, Theme.Muted, LIGHT)
	m.Position = UDim2.fromOffset(22, 28)
	m.Size = UDim2.new(1, -30, 0, 16)
	m.ZIndex = 52
	tween(card, { Position = UDim2.fromOffset(0, 0) }, 0.35, Enum.EasingStyle.Back)
	task.delay(3.2, function()
		if card.Parent then
			tween(card, { Position = UDim2.fromOffset(320, 0) }, 0.3)
			task.wait(0.32)
			holder:Destroy()
		end
	end)
end

-- confirm dialog
local function confirm(title, msg, yes)
	if not Settings["set.confirm"] then
		yes()
		return
	end
	closePopup()
	local cdim = create("TextButton", {
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.45,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 80,
		BorderSizePixel = 0,
	}, overlay)
	local box = create("Frame", {
		BackgroundColor3 = Theme.Card,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(MAIN_W / 2, RH / 2),
		Size = UDim2.fromOffset(360, 160),
		BorderSizePixel = 0,
	}, cdim)
	corner(box, 14)
	stroke(box, Theme.Accent, 1.2, 0.2)
	local t = text(box, title, 15, Theme.Text, HEAD)
	t.Position = UDim2.fromOffset(20, 16)
	t.Size = UDim2.new(1, -40, 0, 24)
	local m = text(box, msg, 12, Theme.Muted, LIGHT)
	m.Position = UDim2.fromOffset(20, 46)
	m.Size = UDim2.new(1, -40, 0, 40)
	m.TextWrapped = true
	m.TextYAlignment = Enum.TextYAlignment.Top
	local no = makeButton(box, "Cancel", 100, 32, false)
	no.AnchorPoint = Vector2.new(1, 1)
	no.Position = UDim2.new(1, -132, 1, -16)
	local ok = makeButton(box, "Confirm", 100, 32, true)
	ok.AnchorPoint = Vector2.new(1, 1)
	ok.Position = UDim2.new(1, -20, 1, -16)
	no.Activated:Connect(function() cdim:Destroy() end)
	ok.Activated:Connect(function()
		cdim:Destroy()
		yes()
	end)
end

--------------------------------------------------------------------------
-- color picker
--------------------------------------------------------------------------
local quickColors = {
	Color3.fromRGB(255, 255, 255), Color3.fromRGB(240, 130, 200), Color3.fromRGB(176, 92, 232),
	Color3.fromRGB(100, 170, 255), Color3.fromRGB(255, 80, 80), Color3.fromRGB(120, 230, 140),
	Color3.fromRGB(255, 210, 90), Color3.fromRGB(20, 20, 24),
}

local function openColorPicker(anchor, key)
	local h, s, v = Settings[key]:ToHSV()
	local pop = openPopup(anchor, Vector2.new(214, 240), function() end)

	local svBox = create("TextButton", {
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = Color3.fromHSV(h, 1, 1),
		Position = UDim2.fromOffset(12, 12),
		Size = UDim2.fromOffset(190, 120),
		BorderSizePixel = 0,
	}, pop)
	corner(svBox, 8)
	local white = create("Frame", {
		BackgroundColor3 = Color3.new(1, 1, 1),
		Size = UDim2.fromScale(1, 1),
		BorderSizePixel = 0,
	}, svBox)
	corner(white, 8)
	create("UIGradient", {
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }),
	}, white)
	local black = create("Frame", {
		BackgroundColor3 = Color3.new(0, 0, 0),
		Size = UDim2.fromScale(1, 1),
		BorderSizePixel = 0,
	}, svBox)
	corner(black, 8)
	create("UIGradient", {
		Rotation = 90,
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) }),
	}, black)
	local svKnob = create("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(11, 11),
	}, svBox)
	round(svKnob)
	stroke(svKnob, Color3.new(1, 1, 1), 2)

	local hueBar = create("TextButton", {
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = Color3.new(1, 1, 1),
		Position = UDim2.fromOffset(12, 142),
		Size = UDim2.fromOffset(190, 12),
		BorderSizePixel = 0,
	}, pop)
	round(hueBar)
	local kps = {}
	for i = 0, 6 do
		table.insert(kps, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6 == 1 and 0.999 or i / 6, 1, 1)))
	end
	create("UIGradient", { Color = ColorSequence.new(kps) }, hueBar)
	local hueKnob = create("Frame", {
		BackgroundColor3 = Color3.new(1, 1, 1),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(6, 18),
		BorderSizePixel = 0,
	}, hueBar)
	corner(hueKnob, 3)
	stroke(hueKnob, Color3.fromRGB(20, 10, 24), 1)

	local hexBox = create("TextBox", {
		Text = hex(Settings[key]),
		ClearTextOnFocus = false,
		Font = BODY,
		TextSize = 11,
		TextColor3 = Theme.Text,
		BackgroundColor3 = Theme.Field,
		Position = UDim2.fromOffset(12, 166),
		Size = UDim2.fromOffset(110, 26),
		BorderSizePixel = 0,
	}, pop)
	corner(hexBox, 7)
	stroke(hexBox, Theme.Border, 1)
	local prev = create("Frame", {
		BackgroundColor3 = Settings[key],
		Position = UDim2.fromOffset(130, 166),
		Size = UDim2.fromOffset(72, 26),
		BorderSizePixel = 0,
	}, pop)
	corner(prev, 7)

	local function update(fromHex)
		local c = Color3.fromHSV(h, s, v)
		svBox.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
		svKnob.Position = UDim2.fromScale(s, 1 - v)
		hueKnob.Position = UDim2.fromScale(h, 0.5)
		prev.BackgroundColor3 = c
		if not fromHex then hexBox.Text = hex(c) end
		applySetting(key, c)
	end

	dragInput(svBox, function(p)
		s = math.clamp((p.X - svBox.AbsolutePosition.X) / svBox.AbsoluteSize.X, 0, 1)
		v = 1 - math.clamp((p.Y - svBox.AbsolutePosition.Y) / svBox.AbsoluteSize.Y, 0, 1)
		update()
	end, popupConns)
	dragInput(hueBar, function(p)
		h = math.clamp((p.X - hueBar.AbsolutePosition.X) / hueBar.AbsoluteSize.X, 0, 0.999)
		update()
	end, popupConns)

	table.insert(popupConns, hexBox.FocusLost:Connect(function()
		local ok, c = pcall(Color3.fromHex, hexBox.Text)
		if ok and c then
			h, s, v = c:ToHSV()
			update(false)
		else
			hexBox.Text = hex(Settings[key])
		end
	end))

	for i, qc in ipairs(quickColors) do
		local q = create("TextButton", {
			Text = "",
			AutoButtonColor = false,
			BackgroundColor3 = qc,
			Position = UDim2.fromOffset(12 + (i - 1) * 24, 205),
			Size = UDim2.fromOffset(20, 20),
			BorderSizePixel = 0,
		}, pop)
		round(q)
		stroke(q, Theme.Border, 1)
		q.Activated:Connect(function()
			h, s, v = qc:ToHSV()
			update()
		end)
	end
	update()
end

--------------------------------------------------------------------------
-- live preview panel
--------------------------------------------------------------------------
local preview, previewGlow, previewGlowStroke, char, parts, renderPreview, updatePreviewVisible
do -- preview scope (keeps the main chunk under the 200-local limit)
local SW, SH = 240, 504
local PH = 560

previewGlow = create("Frame", {
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(MAIN_W + 14 - 3, -3),
	Size = UDim2.fromOffset(PREVIEW_W + 6, PH + 6),
}, root)
corner(previewGlow, 17)
previewGlowStroke = stroke(previewGlow, Theme.Accent, 6, 0.84)

preview = create("Frame", {
	Name = "Preview",
	BackgroundColor3 = Theme.Bg,
	Position = UDim2.fromOffset(MAIN_W + 14, 0),
	Size = UDim2.fromOffset(PREVIEW_W, PH),
	BorderSizePixel = 0,
	ClipsDescendants = true,
}, root)
corner(preview, 14)
local previewStroke = stroke(preview, Theme.Accent, 1.5, 0.05)
bindAccent(function()
	previewGlowStroke.Color = Theme.Accent
	previewStroke.Color = Theme.Accent
end)

do
	local ic, setIc = makeIcon("Misc", preview)
	ic.Position = UDim2.fromOffset(14, 13)
	bindAccent(function() setIc(Theme.Accent) end)
end
local pvTitle = text(preview, "Live Preview", 13, Theme.Text, HEAD)
pvTitle.Position = UDim2.fromOffset(42, 8)
pvTitle.Size = UDim2.new(1, -90, 0, 28)

local pvMin = create("TextButton", {
	Text = "",
	AutoButtonColor = false,
	BackgroundTransparency = 1,
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -8, 0, 8),
	Size = UDim2.fromOffset(28, 28),
}, preview)
create("Frame", {
	BackgroundColor3 = Theme.Muted,
	BorderSizePixel = 0,
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(11, 1.6),
}, pvMin)

local screen = create("Frame", {
	BackgroundColor3 = Environments.Default,
	Position = UDim2.fromOffset(10, 46),
	Size = UDim2.fromOffset(SW, SH),
	BorderSizePixel = 0,
	ClipsDescendants = true,
}, preview)
corner(screen, 11)
stroke(screen, Theme.Border, 1)

local pvBadge = text(screen, "LILAC · PREVIEW", 8, Theme.Muted, BOLD)
pvBadge.Position = UDim2.fromOffset(10, 8)
pvBadge.Size = UDim2.fromOffset(150, 12)

local function newLine(parent, z)
	return create("Frame", {
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(0, 1),
		ZIndex = z or 1,
	}, parent)
end

local function setLine(f, x1, y1, x2, y2, th, col)
	local dx, dy = x2 - x1, y2 - y1
	f.Position = UDim2.fromOffset((x1 + x2) / 2, (y1 + y2) / 2)
	f.Size = UDim2.fromOffset(math.sqrt(dx * dx + dy * dy), th)
	f.Rotation = math.deg(math.atan2(dy, dx))
	if col then f.BackgroundColor3 = col end
end

-- floor grid
local gridHolder = create("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) }, screen)
local gridLines = {}
do
	local hy = SH * 0.62
	for i = 0, 8 do
		local l = newLine(gridHolder)
		l.BackgroundTransparency = 0.82
		local x = -160 + i * (SW + 320) / 8
		setLine(l, SW / 2, hy, x, SH, 1)
		table.insert(gridLines, l)
	end
	for i = 1, 6 do
		local l = newLine(gridHolder)
		l.BackgroundTransparency = 0.82
		local y = hy + (SH - hy) * ((i / 6) ^ 1.7)
		setLine(l, 0, y, SW, y, 1)
		table.insert(gridLines, l)
	end
end

-- tracer (below the character)
local tracer = newLine(screen, 2)

-- character
char = create("Frame", {
	Name = "Char",
	BackgroundTransparency = 1,
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromOffset(SW / 2, SH / 2 + 6),
	Size = UDim2.fromOffset(150, 180),
	ZIndex = 3,
}, screen)
local charScale = create("UIScale", {}, char)

parts = {}
local function part(name, x, y, w, h, r)
	local f = create("Frame", {
		Name = name,
		Position = UDim2.fromOffset(x, y),
		Size = UDim2.fromOffset(w, h),
		BorderSizePixel = 0,
	}, char)
	corner(f, r)
	local st = stroke(f, Color3.new(1, 1, 1), 1.5)
	st.Enabled = false
	parts[name] = { frame = f, stroke = st }
	return f
end
part("legL", 46, 108, 28, 70, 3)
part("legR", 76, 108, 28, 70, 3)
part("torso", 44, 38, 62, 68, 3)
local armL = part("armL", 21, 38, 22, 68, 3)
local armR = part("armR", 107, 38, 22, 68, 3)
local head = part("head", 57, 0, 36, 36, 7)

local function sleeve(parent)
	local f = create("Frame", { Size = UDim2.new(1, 0, 0, 40), BorderSizePixel = 0 }, parent)
	corner(f, 3)
	return f
end
local sleeveL, sleeveR = sleeve(armL), sleeve(armR)
local hair = create("Frame", { Size = UDim2.new(1, 0, 0, 11), BorderSizePixel = 0 }, head)
corner(hair, 5)
for _, ex in ipairs({ 9, 23 }) do
	local eye = create("Frame", {
		BackgroundColor3 = Color3.fromRGB(18, 14, 22),
		Position = UDim2.fromOffset(ex, 19),
		Size = UDim2.fromOffset(4, 5),
		BorderSizePixel = 0,
	}, head)
	corner(eye, 2)
end

-- ESP: box
local box = create("Frame", {
	BackgroundColor3 = Color3.new(1, 1, 1),
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(-8, -8),
	Size = UDim2.fromOffset(166, 196),
	BorderSizePixel = 0,
	ZIndex = 4,
}, char)
local boxStroke = stroke(box, Color3.new(1, 1, 1), 1)
local boxCorners = {}
for _, a in ipairs({ { 0, 0 }, { 1, 0 }, { 0, 1 }, { 1, 1 } }) do
	for _, horizontal in ipairs({ true, false }) do
		local f = create("Frame", {
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(a[1], a[2]),
			Position = UDim2.fromScale(a[1], a[2]),
			Visible = false,
		}, box)
		table.insert(boxCorners, { frame = f, h = horizontal })
	end
end

-- ESP: skeleton
local skelDefs = {
	{ 75, 36, 75, 108, 1 }, { 33, 50, 117, 50, 1 }, { 60, 108, 90, 108, 1 },
	{ 32, 50, 32, 104, 2 }, { 118, 50, 118, 104, 2 },
	{ 60, 108, 60, 178, 3 }, { 90, 108, 90, 178, 3 },
}
local skelLines = {}
for _, d in ipairs(skelDefs) do
	local l = newLine(char, 5)
	table.insert(skelLines, { f = l, d = d })
end

-- ESP: head marker
local crossH = create("Frame", { BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(75, 18), ZIndex = 6 }, char)
local crossV = create("Frame", { BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(75, 18), ZIndex = 6 }, char)
local circleM = create("Frame", { BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(75, 18), ZIndex = 6 }, char)
round(circleM)
local circleStroke = stroke(circleM, Color3.new(1, 1, 1), 1)
local squareM = create("Frame", { BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(75, 18), ZIndex = 6 }, char)
corner(squareM, 1)
local squareStroke = stroke(squareM, Color3.new(1, 1, 1), 1)

-- ESP: text
local function espLabel(parent)
	return create("TextLabel", {
		BackgroundTransparency = 1,
		Text = "",
		Font = BODY,
		TextSize = 12,
		TextColor3 = Color3.new(1, 1, 1),
		TextStrokeColor3 = Color3.new(0, 0, 0),
		TextStrokeTransparency = 0.35,
		ZIndex = 6,
	}, parent)
end
local nameLbl = espLabel(char)
nameLbl.AnchorPoint = Vector2.new(0.5, 0)
local hpTxt = espLabel(char)
hpTxt.AnchorPoint = Vector2.new(1, 0.5)
hpTxt.TextXAlignment = Enum.TextXAlignment.Right
hpTxt.Size = UDim2.fromOffset(34, 14)

local infoList = create("Frame", {
	BackgroundTransparency = 1,
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.fromOffset(75, 192),
	Size = UDim2.fromOffset(220, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	ZIndex = 6,
}, char)
create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center }, infoList)
local weaponLbl, ammoLbl, distLbl = espLabel(infoList), espLabel(infoList), espLabel(infoList)
weaponLbl.LayoutOrder, ammoLbl.LayoutOrder, distLbl.LayoutOrder = 1, 2, 3
weaponLbl.Text, ammoLbl.Text = "AK-47", "24 / 90"
for _, l in ipairs({ weaponLbl, ammoLbl, distLbl }) do l.Size = UDim2.new(1, 0, 0, 16) end

-- ESP: health bar
local hpBack = create("Frame", {
	BackgroundColor3 = Color3.fromRGB(10, 8, 12),
	BorderSizePixel = 0,
	ZIndex = 5,
}, char)
corner(hpBack, 2)
local hpFill = create("Frame", {
	BackgroundColor3 = Color3.new(1, 1, 1),
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.fromScale(0, 1),
	BorderSizePixel = 0,
}, hpBack)
corner(hpFill, 2)
local hpGrad = create("UIGradient", { Rotation = 90, Enabled = false }, hpFill)

-- ESP: look direction + arrows
local lookLine = newLine(char, 6)
local lookDot = create("Frame", {
	BorderSizePixel = 0,
	AnchorPoint = Vector2.new(0.5, 0.5),
	Size = UDim2.fromOffset(6, 6),
	Position = UDim2.fromOffset(113, 12),
	ZIndex = 6,
}, char)
round(lookDot)
setLine(lookLine, 75, 18, 113, 12, 1.5)

local pvArrows = {}
local function addArrow(x, y, rot)
	local h, set = makeArrow(screen, 6)
	h.Position = UDim2.fromOffset(x, y)
	h.Rotation = rot
	table.insert(pvArrows, { h = h, set = set })
end
addArrow(SW - 18, 130, 0)
addArrow(SW / 2 + 40, 18, -90)
addArrow(18, 400, 180)

-- hit marker
local hitBars = {}
for i = 1, 4 do
	hitBars[i] = create("Frame", {
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(SW / 2, SH / 2 + 6),
		Visible = false,
		ZIndex = 9,
	}, screen)
end
local hitCatcher = create("TextButton", {
	Selectable = false,
	Text = "",
	AutoButtonColor = false,
	BackgroundTransparency = 1,
	Size = UDim2.fromScale(1, 1),
	ZIndex = 20,
}, screen)
local hitHint = text(screen, "click the preview to test the hit marker", 8, Theme.Muted, LIGHT, Enum.TextXAlignment.Center)
hitHint.Position = UDim2.new(0, 0, 1, -18)
hitHint.Size = UDim2.new(1, 0, 0, 12)

local hitToken = 0
hitCatcher.Activated:Connect(function()
	if not Settings["hit.enabled"] then return end
	hitToken += 1
	local my = hitToken
	local size = Settings["hit.size"]
	local col = Settings["hit.color"]
	local cx, cy = SW / 2, SH / 2 + 6
	local off = size * 0.9
	local dirs = { { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } }
	for i, b in ipairs(hitBars) do
		b.BackgroundColor3 = col
		b.BackgroundTransparency = 0
		b.Size = UDim2.fromOffset(size, 2)
		b.Rotation = (dirs[i][1] * dirs[i][2] > 0) and 45 or -45
		b.Position = UDim2.fromOffset(cx + dirs[i][1] * off, cy + dirs[i][2] * off)
		b.Visible = true
	end
	task.delay(0.12, function()
		if my ~= hitToken then return end
		for _, b in ipairs(hitBars) do
			tween(b, { BackgroundTransparency = 1 }, 0.25)
		end
		task.wait(0.26)
		if my == hitToken then
			for _, b in ipairs(hitBars) do b.Visible = false end
		end
	end)
end)

-- preview collapse
local pvCollapsed = false
function updatePreviewVisible()
	local show = Settings["set.preview"] ~= false and not (main.Size.Y.Offset < 100)
	preview.Visible = show
	previewGlow.Visible = show
end
pvMin.Activated:Connect(function()
	pvCollapsed = not pvCollapsed
	screen.Visible = not pvCollapsed
	local h = pvCollapsed and 46 or PH
	tween(preview, { Size = UDim2.fromOffset(PREVIEW_W, h) }, 0.25)
	tween(previewGlow, { Size = UDim2.fromOffset(PREVIEW_W + 6, h + 6) }, 0.25)
end)

-- render everything from Settings
function renderPreview()
	local S = Settings
	if S["esp.enabled"] == nil then return end
	local on = S["esp.enabled"]
	local sc = S["char.scale"] / 100
	charScale.Scale = sc

	-- scene
	local base = (Environments[S["world.env"]] or Environments.Default):Lerp(S["world.tint"], 0.12)
	local f = 0.45 + (S["world.brightness"] / 100) * 0.8
	screen.BackgroundColor3 = Color3.new(math.min(base.R * f, 1), math.min(base.G * f, 1), math.min(base.B * f, 1))
	gridHolder.Visible = S["world.grid"]
	for _, l in ipairs(gridLines) do l.BackgroundColor3 = Theme.Accent2 end

	-- body + chams
	local cham = on and S["esp.highlight"]
	local cf, co = S["cham.fill"], S["cham.opacity"] / 100
	local function tint(c) return cham and c:Lerp(cf, co) or c end
	parts.head.frame.BackgroundColor3 = tint(S["char.skin"])
	parts.armL.frame.BackgroundColor3 = tint(S["char.skin"])
	parts.armR.frame.BackgroundColor3 = tint(S["char.skin"])
	parts.torso.frame.BackgroundColor3 = tint(S["char.shirt"])
	sleeveL.BackgroundColor3 = tint(S["char.shirt"])
	sleeveR.BackgroundColor3 = tint(S["char.shirt"])
	parts.legL.frame.BackgroundColor3 = tint(S["char.pants"])
	parts.legR.frame.BackgroundColor3 = tint(S["char.pants"])
	hair.BackgroundColor3 = tint(S["char.hair"])
	for _, p in pairs(parts) do
		p.stroke.Enabled = cham
		p.stroke.Color = S["cham.outline"]
	end

	-- box
	local th = S["bars.boxthick"]
	local asCorners = S["bars.boxstyle"] == "Corners"
	box.Visible = on and S["esp.box"]
	boxStroke.Enabled = not asCorners
	boxStroke.Thickness = th
	boxStroke.Color = S["bars.boxcolor"]
	box.BackgroundColor3 = S["bars.fillcolor"]
	box.BackgroundTransparency = S["bars.fillbox"] and (1 - S["bars.fillopacity"] / 100) or 1
	for _, c in ipairs(boxCorners) do
		c.frame.Visible = asCorners
		c.frame.BackgroundColor3 = S["bars.boxcolor"]
		c.frame.Size = c.h and UDim2.fromOffset(24, th) or UDim2.fromOffset(th, 24)
	end

	-- text styling
	local font = FontMap[S["fmt.font"]] or BODY
	local ts = S["fmt.size"]
	local tst = S["fmt.outline"] and 0.35 or 1
	for _, l in ipairs({ nameLbl, hpTxt, weaponLbl, ammoLbl, distLbl }) do
		l.Font = font
		l.TextSize = ts
		l.TextColor3 = S["fmt.color"]
		l.TextStrokeTransparency = tst
	end
	nameLbl.Visible = on and S["esp.names"]
	nameLbl.Text = player.DisplayName .. (S["esp.team"] and "  [TEAM]" or "")
	nameLbl.Size = UDim2.fromOffset(220, ts + 6)
	nameLbl.Position = UDim2.fromOffset(75, -12 - (ts + 6))
	weaponLbl.Visible = on and S["esp.weapon"]
	ammoLbl.Visible = on and S["esp.ammo"]
	distLbl.Visible = on and S["esp.distance"]
	distLbl.Text = S["fmt.unit"] == "Meters" and "42 m" or "150 studs"
	for _, l in ipairs({ weaponLbl, ammoLbl, distLbl }) do l.Size = UDim2.new(1, 0, 0, ts + 4) end

	-- health
	local hp = S["fmt.hp"] / 100
	local bw = S["bars.width"]
	local col = S["bars.low"]:Lerp(S["bars.high"], hp)
	local showBar = on and S["esp.vhealth"]
	hpBack.Visible = showBar
	hpBack.Size = UDim2.fromOffset(bw, 196)
	hpBack.Position = UDim2.fromOffset(-12 - bw, -8)
	hpFill.Size = UDim2.new(1, 0, hp, 0)
	hpGrad.Enabled = S["bars.gradient"]
	hpGrad.Color = ColorSequence.new(S["bars.high"], S["bars.low"])
	hpFill.BackgroundColor3 = S["bars.gradient"] and Color3.new(1, 1, 1) or col
	hpTxt.Visible = on and S["esp.healthinfo"]
	hpTxt.Text = tostring(S["fmt.hp"])
	hpTxt.TextColor3 = col
	hpTxt.Size = UDim2.fromOffset(34, ts + 2)
	hpTxt.Position = UDim2.fromOffset(-15 - (showBar and bw or 0), math.clamp(-8 + 196 * (1 - hp), 0, 180))

	-- look + arrows
	lookLine.Visible = on and S["esp.look"]
	lookDot.Visible = on and S["esp.look"]
	lookLine.BackgroundColor3 = Theme.Accent
	lookDot.BackgroundColor3 = Theme.Accent
	for _, a in ipairs(pvArrows) do
		a.h.Visible = on and S["esp.arrows"]
		a.set(Theme.Accent)
	end

	-- skeleton
	local sk = on and S["skel.enabled"]
	local colors = { S["skel.c1"], S["skel.c2"], S["skel.c3"] }
	for _, l in ipairs(skelLines) do
		local d = l.d
		l.f.Visible = sk
		setLine(l.f, d[1], d[2], d[3], d[4], S["skel.thick"], colors[d[5]])
	end

	-- head marker
	local hm = on and S["head.enabled"]
	local px = 4 + S["head.size"] * 2.2
	local ht = S["head.thick"]
	local hc = S["head.color"]
	local shape = S["head.shape"]
	local fillOn = S["head.fill"]
	crossH.Visible = hm and shape == "Cross"
	crossV.Visible = hm and shape == "Cross"
	crossH.BackgroundColor3, crossV.BackgroundColor3 = hc, hc
	crossH.Size = UDim2.fromOffset(px, ht)
	crossV.Size = UDim2.fromOffset(ht, px)
	circleM.Visible = hm and shape == "Circle"
	circleM.Size = UDim2.fromOffset(px, px)
	circleM.BackgroundColor3 = hc
	circleM.BackgroundTransparency = fillOn and 0 or 1
	circleStroke.Thickness, circleStroke.Color = ht, hc
	squareM.Visible = hm and shape == "Square"
	squareM.Size = UDim2.fromOffset(px, px)
	squareM.BackgroundColor3 = hc
	squareM.BackgroundTransparency = fillOn and 0 or 1
	squareStroke.Thickness, squareStroke.Color = ht, hc

	-- tracer
	tracer.Visible = on and S["tr.enabled"]
	local feetY = SH / 2 + 6 + 90 * sc + 2
	local oy = SH
	if S["tr.origin"] == "Center" then oy = SH / 2 elseif S["tr.origin"] == "Top" then oy = 0 end
	setLine(tracer, SW / 2, oy, SW / 2, feetY, S["tr.thick"], S["tr.color"])
end

end -- preview scope

--------------------------------------------------------------------------
-- rows
--------------------------------------------------------------------------
local sliderNudge = {}
local allRows = {}
local cardFrames = {}
local buildingKeys

local function reg(def)
	Settings[def.key] = def.default
	Defaults[def.key] = def.default
	if buildingKeys then table.insert(buildingKeys, def.key) end
end

local function makeRow(body, def)
	local height = def.type == "config" and 84 or 36
	local row = create("Frame", {
		Name = def.name or def.type,
		BackgroundColor3 = Theme.Accent,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, height),
		BorderSizePixel = 0,
	}, body)
	bindAccent(function() row.BackgroundColor3 = Theme.Accent end)
	row:SetAttribute("Search", ((def.name or "") .. " " .. (def.tip or "")):lower())
	row:SetAttribute("Plat", def.plat or "")
	row:SetAttribute("Game", def.game or "")
	table.insert(allRows, { frame = row, base = height })

	create("Frame", {
		BackgroundColor3 = Theme.Border,
		BackgroundTransparency = 0.7,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 12, 1, -1),
		Size = UDim2.new(1, -24, 0, 1),
	}, row)

	row.MouseEnter:Connect(function()
		tween(row, { BackgroundTransparency = 0.93 }, 0.12)
		if Settings["misc.tips"] and activePlat == "PC" and def.tip and def.tip ~= "" then
			tipLabel.Text = def.tip
			tipFrame.Visible = true
			tipActive = true
		end
	end)
	row.MouseLeave:Connect(function()
		tween(row, { BackgroundTransparency = 1 }, 0.12)
		tipActive = false
		tipFrame.Visible = false
	end)

	if def.type ~= "config" then
		local lbl = text(row, def.name, 12, Theme.Text, BODY)
		lbl.Position = UDim2.fromOffset(14, 0)
		lbl.Size = UDim2.new(0.42, -14, 1, 0)
	end

	local kind = def.type
	local key = def.key

	if kind == "toggle" then
		reg(def)
		local track = create("TextButton", {
			Text = "",
			AutoButtonColor = false,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -14, 0.5, 0),
			Size = UDim2.fromOffset(40, 20),
			BorderSizePixel = 0,
			BackgroundColor3 = Theme.Off,
		}, row)
		round(track)
		local glow = stroke(track, Theme.Accent, 3, 1)
		local knob = create("Frame", {
			BackgroundColor3 = Color3.new(1, 1, 1),
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 3, 0.5, 0),
			Size = UDim2.fromOffset(14, 14),
			BorderSizePixel = 0,
		}, track)
		round(knob)
		local function render(v)
			tween(track, { BackgroundColor3 = v and Theme.Accent or Theme.Off })
			tween(knob, { Position = v and UDim2.new(1, -17, 0.5, 0) or UDim2.new(0, 3, 0.5, 0) }, 0.22, Enum.EasingStyle.Back)
			tween(glow, { Transparency = v and 0.72 or 1 })
		end
		Controls[key] = { apply = render }
		bindAccent(function()
			track.BackgroundColor3 = Settings[key] and Theme.Accent or Theme.Off
			glow.Color = Theme.Accent
			knob.Position = Settings[key] and UDim2.new(1, -17, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
			glow.Transparency = Settings[key] and 0.72 or 1
		end)
		track.Activated:Connect(function()
			local v = not Settings[key]
			render(v)
			commit(key, v)
		end)

	elseif kind == "slider" then
		reg(def)
		local mn, mx, step = def.min, def.max, def.step or 1
		local function fmt(v)
			if step >= 1 then return tostring(math.floor(v + 0.5)) end
			if step >= 0.1 then return string.format("%.1f", v) end
			return string.format("%.2f", v)
		end
		local box = create("TextBox", {
			Text = fmt(def.default),
			ClearTextOnFocus = false,
			Font = BODY,
			TextSize = 11,
			TextColor3 = Theme.Text,
			BackgroundColor3 = Theme.Field,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -14, 0.5, 0),
			Size = UDim2.fromOffset(46, 24),
			BorderSizePixel = 0,
		}, row)
		corner(box, 7)
		stroke(box, Theme.Border, 1)
		local tPos = UDim2.new(0.42, 0, 0.5, 0)
		local tSize = UDim2.new(0.58, -84, 0, 6)
		local track = create("Frame", {
			BackgroundColor3 = Theme.Off,
			AnchorPoint = Vector2.new(0, 0.5),
			Position = tPos,
			Size = tSize,
			BorderSizePixel = 0,
		}, row)
		round(track)
		local fill = create("Frame", {
			BackgroundColor3 = Color3.new(1, 1, 1),
			Size = UDim2.fromScale(0, 1),
			BorderSizePixel = 0,
		}, track)
		round(fill)
		local grad = create("UIGradient", {}, fill)
		local knob = create("Frame", {
			BackgroundColor3 = Color3.new(1, 1, 1),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0, 0.5),
			Size = UDim2.fromOffset(13, 13),
			BorderSizePixel = 0,
		}, track)
		round(knob)
		local kglow = stroke(knob, Theme.Accent, 3, 0.6)
		bindAccent(function()
			grad.Color = ColorSequence.new(Theme.Accent2, Theme.Accent)
			kglow.Color = Theme.Accent
		end)
		local hit = create("TextButton", {
			Text = "",
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0, 0.5),
			Position = tPos,
			Size = UDim2.new(0.58, -84, 0, 26),
		}, row)

		local function render(v)
			local frac = (v - mn) / (mx - mn)
			fill.Size = UDim2.fromScale(frac, 1)
			knob.Position = UDim2.fromScale(frac, 0.5)
			box.Text = fmt(v)
		end
		local function snap(v)
			v = mn + math.floor((v - mn) / step + 0.5) * step
			v = math.clamp(v, mn, mx)
			return math.floor(v * 1000 + 0.5) / 1000
		end
		Controls[key] = { apply = render }
		render(def.default)
		dragInput(hit, function(p)
			local frac = math.clamp((p.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
			local v = snap(mn + frac * (mx - mn))
			if v ~= Settings[key] then
				render(v)
				commit(key, v)
			end
		end)
		sliderNudge[hit] = function(dir)
			local v = snap(Settings[key] + dir * math.max(step, (mx - mn) * 0.05))
			render(v)
			commit(key, v)
		end
		connect(box.FocusLost, function()
			local n = tonumber(box.Text)
			if n then
				n = snap(n)
				render(n)
				commit(key, n)
			else
				render(Settings[key])
			end
		end)

	elseif kind == "dropdown" then
		reg(def)
		local opts = def.options
		local btn = create("TextButton", {
			Text = "",
			AutoButtonColor = false,
			BackgroundColor3 = Theme.Field,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -14, 0.5, 0),
			Size = UDim2.fromOffset(128, 26),
			BorderSizePixel = 0,
		}, row)
		corner(btn, 8)
		local btnStroke = stroke(btn, Theme.Border, 1)
		btn.MouseEnter:Connect(function() tween(btnStroke, { Color = Theme.Accent }, 0.12) end)
		btn.MouseLeave:Connect(function() tween(btnStroke, { Color = Theme.Border }, 0.12) end)
		local lab = text(btn, def.default, 11, Theme.Text, BODY)
		lab.Position = UDim2.fromOffset(11, 0)
		lab.Size = UDim2.new(1, -30, 1, 0)
		chevron(btn, UDim2.new(1, -15, 0.5, 0))
		Controls[key] = { apply = function(v) lab.Text = v end }
		btn.Activated:Connect(function()
			local useOpts = opts
			if key == "cfg.selected" and type(listConfigNames) == "function" then
				useOpts = listConfigNames()
			end
			openPopup(btn, Vector2.new(140, math.max(#useOpts, 1) * 28 + 10), function(pop)
				local list = create("Frame", {
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(5, 5),
					Size = UDim2.new(1, -10, 1, -10),
				}, pop)
				create("UIListLayout", {}, list)
				for _, o in ipairs(useOpts) do
					local ob = create("TextButton", {
						Text = o,
						Font = BODY,
						TextSize = 11,
						TextXAlignment = Enum.TextXAlignment.Left,
						TextColor3 = (o == Settings[key]) and Theme.Accent or Theme.Text,
						AutoButtonColor = false,
						BackgroundColor3 = Theme.CardHead,
						BackgroundTransparency = 1,
						Size = UDim2.new(1, 0, 0, 28),
						BorderSizePixel = 0,
					}, list)
					corner(ob, 7)
					pad(ob, 0, 8, 0, 10)
					ob.MouseEnter:Connect(function() tween(ob, { BackgroundTransparency = 0.2 }, 0.08) end)
					ob.MouseLeave:Connect(function() tween(ob, { BackgroundTransparency = 1 }, 0.08) end)
					ob.Activated:Connect(function()
						lab.Text = o
						commit(key, o)
						closePopup()
					end)
				end
			end)
		end)

	elseif kind == "color" then
		reg(def)
		local sw = create("TextButton", {
			Text = hex(def.default),
			AutoButtonColor = false,
			Font = BOLD,
			TextSize = 10,
			BackgroundColor3 = def.default,
			TextColor3 = contrast(def.default),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -14, 0.5, 0),
			Size = UDim2.fromOffset(84, 24),
			BorderSizePixel = 0,
		}, row)
		corner(sw, 8)
		local swGlow = stroke(sw, def.default, 3, 0.75)
		Controls[key] = {
			apply = function(c)
				sw.BackgroundColor3 = c
				sw.Text = hex(c)
				sw.TextColor3 = contrast(c)
				swGlow.Color = c
			end,
		}
		sw.Activated:Connect(function() openColorPicker(sw, key) end)

	elseif kind == "keybind" then
		reg(def)
		local btn = create("TextButton", {
			Text = prettyKey(Settings[key]),
			AutoButtonColor = false,
			Font = BODY,
			TextSize = 11,
			TextColor3 = Theme.Text,
			BackgroundColor3 = Theme.Field,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -14, 0.5, 0),
			Size = UDim2.fromOffset(128, 26),
			BorderSizePixel = 0,
		}, row)
		corner(btn, 8)
		local kbStroke = stroke(btn, Theme.Border, 1)
		btn.MouseEnter:Connect(function() tween(kbStroke, { Color = Theme.Accent }, 0.12) end)
		btn.MouseLeave:Connect(function() tween(kbStroke, { Color = Theme.Border }, 0.12) end)
		Controls[key] = { apply = function(v) btn.Text = prettyKey(v) end }
		btn.Activated:Connect(function()
			_G.__LilacBinding = true
			_G.__LilacBindStart = os.clock()
			btn.Text = "press any key..."
		end)
		connect(UserInputService.InputBegan, function(i)
			if not _G.__LilacBinding or btn.Text ~= "press any key..." then return end
			local name
			local ut = i.UserInputType
			if ut == Enum.UserInputType.Keyboard then
				name = i.KeyCode.Name
			elseif ut == Enum.UserInputType.MouseButton1 or ut == Enum.UserInputType.MouseButton2 or ut == Enum.UserInputType.MouseButton3 then
				name = ut.Name
			elseif ut.Name:sub(1, 7) == "Gamepad" and i.KeyCode ~= Enum.KeyCode.Thumbstick1
				and i.KeyCode ~= Enum.KeyCode.Thumbstick2 and i.KeyCode ~= Enum.KeyCode.Unknown then
				name = i.KeyCode.Name
			end
			if not name then return end
			if os.clock() - (_G.__LilacBindStart or 0) < 0.15 then return end
			_G.__LilacBinding = false
			_G.__LilacBindTime = os.clock()
			if name == "Escape" or name == "ButtonB" then
				btn.Text = prettyKey(Settings[key])
			elseif name == "Backspace" then
				btn.Text = "None"
				commit(key, "None")
			else
				btn.Text = prettyKey(name)
				commit(key, name)
			end
		end)

	elseif kind == "button" then
		local b = makeButton(row, def.label or def.name, 128, 26, def.primary)
		b.AnchorPoint = Vector2.new(1, 0.5)
		b.Position = UDim2.new(1, -14, 0.5, 0)
		b.Activated:Connect(function() def.fn() end)

	elseif kind == "config" then
		local tb = create("TextBox", {
			Text = "",
			PlaceholderText = "Export to generate a config string, or paste one and press Import",
			PlaceholderColor3 = Theme.Muted,
			ClearTextOnFocus = false,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Font = Enum.Font.Code,
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = Theme.Text,
			BackgroundColor3 = Theme.Field,
			Position = UDim2.fromOffset(12, 8),
			Size = UDim2.new(1, -24, 0, 30),
			BorderSizePixel = 0,
		}, row)
		corner(tb, 8)
		stroke(tb, Theme.Border, 1)
		pad(tb, 0, 10, 0, 10)
		local exp = makeButton(row, "Export", 100, 26, false)
		exp.Position = UDim2.fromOffset(12, 48)
		local imp = makeButton(row, "Import", 100, 26, true)
		imp.Position = UDim2.fromOffset(120, 48)
		def.hook(tb, exp, imp)
	end

	return row
end

--------------------------------------------------------------------------
-- cards + pages
--------------------------------------------------------------------------
local pages = {}
local currentTab = "ESP"

local function buildCard(col, def)
	if def.game == "full" and not lilacFullGame then
		return nil
	end
	local card = create("Frame", {
		Name = def.title,
		BackgroundColor3 = Theme.Card,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BorderSizePixel = 0,
		LayoutOrder = def.order or 1,
	}, col)
	corner(card, 12)
	stroke(card, Theme.Border, 1, 0.1)
	create("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(205, 195, 212)),
	}, card)
	create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, card)
	table.insert(cardFrames, card)

	local header = create("Frame", {
		BackgroundColor3 = Theme.CardHead,
		Size = UDim2.new(1, 0, 0, 40),
		BorderSizePixel = 0,
		LayoutOrder = 1,
	}, card)
	corner(header, 12)
	create("Frame", {
		BackgroundColor3 = Theme.CardHead,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 1, -12),
		Size = UDim2.new(1, 0, 0, 12),
	}, header)
	local dia = create("Frame", {
		BackgroundColor3 = Theme.Accent,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(20, 20),
		Size = UDim2.fromOffset(7, 7),
		Rotation = 45,
	}, header)
	corner(dia, 1)
	bindAccent(function() dia.BackgroundColor3 = Theme.Accent end)
	local headLine = create("Frame", {
		BackgroundColor3 = Theme.Accent,
		BackgroundTransparency = 0.7,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 1, -1),
		Size = UDim2.new(1, 0, 0, 1),
		ZIndex = 2,
	}, header)
	create("UIGradient", {
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }),
	}, headLine)
	bindAccent(function() headLine.BackgroundColor3 = Theme.Accent end)
	local title = text(header, def.title, 13, Theme.Text, HEAD)
	title.Position = UDim2.fromOffset(36, 0)
	title.Size = UDim2.new(1, -80, 1, 0)

	local obj = { frame = card, title = def.title, bodies = {}, active = 1, searching = false, collapsed = false }
	local strip
	local pills = {}

	local function newBody(order)
		local b = create("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = order,
		}, card)
		create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, b)
		pad(b, 4, 0, 6, 0)
		return b
	end

	obj.layout = function()
		for i, b in ipairs(obj.bodies) do
			local show
			if obj.collapsed then show = false
			elseif obj.searching then show = b.hit
			else show = (i == obj.active) end
			b.frame.Visible = show
		end
		if strip then strip.Visible = (not obj.collapsed) and (not obj.searching) end
	end

	local function styleBody(tbl, rows)
		for _, r in ipairs(rows) do
			table.insert(tbl.rows, makeRow(tbl.frame, r))
		end
	end

	if def.tabs then
		strip = create("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 36),
			LayoutOrder = 2,
		}, card)
		pad(strip, 6, 10, 0, 10)
		create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 5),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, strip)
		local function stylePills()
			for i, p in ipairs(pills) do
				local a = i == obj.active
				p.btn.TextColor3 = a and Theme.Accent or Theme.Muted
				p.btn.BackgroundColor3 = a and Theme.CardHead or Theme.Field
				p.stroke.Color = a and Theme.Accent or Theme.Border
				p.stroke.Transparency = a and 0.15 or 0
			end
		end
		for i, tdef in ipairs(def.tabs) do
			local body = { frame = newBody(2 + i), rows = {}, hit = false }
			table.insert(obj.bodies, body)
			styleBody(body, tdef.rows)
			local pill = create("TextButton", {
				Text = tdef.name,
				Font = BODY,
				TextSize = 9,
				AutoButtonColor = false,
				Size = UDim2.fromOffset(#tdef.name * 5.6 + 18, 24),
				BorderSizePixel = 0,
				LayoutOrder = i,
			}, strip)
			round(pill)
			local ps = stroke(pill, Theme.Border, 1)
			table.insert(pills, { btn = pill, stroke = ps })
			pill.Activated:Connect(function()
				obj.active = i
				stylePills()
				obj.layout()
			end)
		end
		bindAccent(stylePills)
	else
		local body = { frame = newBody(3), rows = {}, hit = false }
		table.insert(obj.bodies, body)
		styleBody(body, def.rows)
	end
	obj.layout()

	-- collapse button
	local cb = create("TextButton", {
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.fromOffset(28, 28),
	}, header)
	create("Frame", {
		BackgroundColor3 = Theme.Muted,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(11, 1.6),
	}, cb)
	local v1 = create("Frame", {
		BackgroundColor3 = Theme.Muted,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(1.6, 11),
		Visible = false,
	}, cb)
	cb.Activated:Connect(function()
		obj.collapsed = not obj.collapsed
		v1.Visible = obj.collapsed
		obj.layout()
	end)

	return obj
end

local function buildPage(name, cardDefs)
	local scroll = create("ScrollingFrame", {
		Name = name,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(22, 84),
		Size = UDim2.new(1, -44, 1, -96),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Theme.Accent,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ElasticBehavior = Enum.ElasticBehavior.Never,
		Visible = false,
	}, content)
	bindAccent(function() scroll.ScrollBarImageColor3 = Theme.Accent end)

	local wrap = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -12, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
	}, scroll)
	pad(wrap, 2, 0, 16, 0)

	local cols = {}
	for i = 1, 2 do
		cols[i] = create("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.new((i - 1) * 0.5, (i - 1) * 6, 0, 0),
			Size = UDim2.new(0.5, -6, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
		}, wrap)
		create("UIListLayout", { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }, cols[i])
	end

	local empty = text(scroll, "No settings match your search.", 12, Theme.Muted, LIGHT, Enum.TextXAlignment.Center)
	empty.Position = UDim2.fromOffset(0, 40)
	empty.Visible = false

	local page = { scroll = scroll, cards = {}, empty = empty, visible = 0 }
	buildingKeys = {}
	TabKeys[name] = buildingKeys
	for _, cd in ipairs(cardDefs) do
		local card = buildCard(cols[cd.col or 1], cd)
		if card then table.insert(page.cards, card) end
	end
	buildingKeys = nil
	pages[name] = page
end

local function platOk(r)
	local p = r:GetAttribute("Plat")
	if not (p == nil or p == "" or p:find(activePlat, 1, true) ~= nil) then return false end
	local g = r:GetAttribute("Game")
	if g == "full" and not lilacFullGame then return false end
	if g == "universal" and lilacFullGame then return false end
	return true
end

local function applySearch(page, q)
	if not page then return end
	q = q:lower()
	local searching = q ~= ""
	local visibleCards = 0
	for _, card in ipairs(page.cards) do
		local titleHit = searching and card.title:lower():find(q, 1, true) ~= nil
		local any = false
		for _, b in ipairs(card.bodies) do
			b.hit = false
			for _, r in ipairs(b.rows) do
				local m = platOk(r)
					and ((not searching) or titleHit or ((r:GetAttribute("Search") or ""):find(q, 1, true) ~= nil))
				r.Visible = m
				if m then b.hit = true end
			end
			if b.hit then any = true end
		end
		card.searching = searching
		card.frame.Visible = any
		card.layout()
		if any then visibleCards += 1 end
	end
	page.visible = visibleCards
	page.empty.Visible = visibleCards == 0
	if not searching then
		moduleLabel.Text = visibleCards .. (visibleCards == 1 and " module" or " modules")
	end
end

connect(searchBox:GetPropertyChangedSignal("Text"), function()
	applySearch(pages[currentTab], searchBox.Text)
end)

--------------------------------------------------------------------------
-- actions used by buttons
--------------------------------------------------------------------------
local tabOrder = { "Combat", "ESP", "Visuals", "World", "Character", "Misc", "Settings" }

local function resetKeys(keys)
	bulk = true
	for _, k in ipairs(keys) do applySetting(k, Defaults[k]) end
	bulk = false
end

local function resetAll()
	local keys = {}
	for k in pairs(Defaults) do table.insert(keys, k) end
	resetKeys(keys)
end

local function serialize()
	local out = {}
	for k, v in pairs(Settings) do
		if typeof(v) == "Color3" then out[k] = hex(v) else out[k] = v end
	end
	return HttpService:JSONEncode(out)
end

local function importConfig(str)
	local ok, data = pcall(function() return HttpService:JSONDecode(str) end)
	if not ok or type(data) ~= "table" then return false end
	bulk = true
	for k, v in pairs(data) do
		local cur = Settings[k]
		if cur ~= nil then
			local t = typeof(cur)
			if t == "Color3" and type(v) == "string" then
				local ok2, c = pcall(Color3.fromHex, v)
				if ok2 and c then applySetting(k, c) end
			elseif t == type(v) and (t == "boolean" or t == "number" or t == "string") then
				applySetting(k, v)
			end
		end
	end
	bulk = false
	return true
end

--------------------------------------------------------------------------
-- named configs (Lilac/configs/<name>.json)
--------------------------------------------------------------------------
local CFG_DIR = "Lilac/configs"
local CFG_META = "Lilac/autoload.txt"
local _configListCache = { "default" }
local refreshConfigDropdown = nil -- optional UI refresh hook

local function ensureCfgDir()
	if type(makefolder) ~= "function" then return end
	pcall(function()
		if type(isfolder) == "function" and not isfolder("Lilac") then makefolder("Lilac") end
		if type(isfolder) == "function" and not isfolder(CFG_DIR) then makefolder(CFG_DIR) end
	end)
end

local function listConfigNames()
	ensureCfgDir()
	local names = {}
	local seen = {}
	local function add(n)
		n = tostring(n or ""):gsub("%.json$", ""):gsub("[^%w%-_ ]", ""):sub(1, 32)
		if n ~= "" and not seen[n] then
			seen[n] = true
			table.insert(names, n)
		end
	end
	add("default")
	if type(listfiles) == "function" then
		local ok, files = pcall(listfiles, CFG_DIR)
		if ok and type(files) == "table" then
			for _, f in ipairs(files) do
				local base = tostring(f):match("([^/\\]+)%.json$") or tostring(f):match("([^/\\]+)$")
				if base then add(base) end
			end
		end
	end
	table.sort(names, function(a, b) return a:lower() < b:lower() end)
	_configListCache = names
	return names
end

local function configPath(name)
	name = tostring(name or "default"):gsub("[^%w%-_ ]", ""):sub(1, 32)
	if name == "" then name = "default" end
	return CFG_DIR .. "/" .. name .. ".json", name
end

local function saveNamedConfig(name)
	local path, clean = configPath(name)
	ensureCfgDir()
	if type(writefile) ~= "function" then return false, "writefile unavailable" end
	local ok, err = pcall(writefile, path, serialize())
	if not ok then return false, tostring(err) end
	listConfigNames()
	Settings["cfg.selected"] = clean
	return true, clean
end

local function loadNamedConfig(name)
	local path, clean = configPath(name)
	if type(readfile) ~= "function" then return false end
	if type(isfile) == "function" and not isfile(path) then return false end
	local ok, body = pcall(readfile, path)
	if not ok or type(body) ~= "string" or body == "" then return false end
	if not importConfig(body) then return false end
	Settings["cfg.selected"] = clean
	return true
end

local function setAutoloadName(name)
	ensureCfgDir()
	local _, clean = configPath(name)
	Settings["cfg.autoloadname"] = clean
	if type(writefile) == "function" then
		pcall(writefile, CFG_META, clean)
	end
end

local function getAutoloadName()
	if type(readfile) == "function" and type(isfile) == "function" and isfile(CFG_META) then
		local ok, n = pcall(readfile, CFG_META)
		if ok and type(n) == "string" and n ~= "" then
			return n:gsub("%s+", ""):sub(1, 32)
		end
	end
	return Settings["cfg.autoloadname"] or "default"
end

--------------------------------------------------------------------------
-- page definitions
--------------------------------------------------------------------------
local function T(key, name, default, tip, plat) return { type = "toggle", key = key, name = name, default = default, tip = tip, plat = plat } end
local function S(key, name, min, max, default, tip, step, plat) return { type = "slider", key = key, name = name, min = min, max = max, default = default, tip = tip, step = step, plat = plat } end
local function C(key, name, default, tip) return { type = "color", key = key, name = name, default = default, tip = tip } end
local function D(key, name, options, tip) return { type = "dropdown", key = key, name = name, options = options, default = options[1], tip = tip } end
local function B(name, label, fn, tip, primary) return { type = "button", name = name, label = label, fn = fn, tip = tip, primary = primary } end
-- universal keybind: keyboard, mouse button or controller button. Hidden on mobile.
local function K(key, name, default, tip) return { type = "keybind", key = key, name = name, default = default, tip = tip, plat = "PC,Console" } end

local rgb = Color3.fromRGB
local MODES = { "Hold", "Toggle", "Always" }

buildPage("Combat", {
	{ title = "Aimbot", col = 1, tabs = {
		{ name = "General", rows = {
			T("aim.enabled", "Aimbot", false, lilacFullGame and "Full-game aim assist (mouse + advanced targeting)" or "Universal aim assist — mouse move toward target"),
			K("aim.key", "Aim Key", defKey("MouseButton2", "ButtonL2"), "One bind for keyboard, mouse AND controller. Backspace clears it"),
			D("aim.mode", "Activation", MODES, "Hold the key, toggle it, or always on"),
			D("aim.method", "Method", { "Mouse", "Camera" }, "Mouse = natural mouse move (recommended). Camera = force CFrame (some games fight this)"),
			S("aim.smooth", "Smoothness", 1, 100, 35, "Higher = slower. 1–15 = snappy, 40–100 = soft"),
			S("aim.xsmooth", "X Smooth %", 1, 100, 100, "Horizontal strength"),
			S("aim.ysmooth", "Y Smooth %", 1, 100, 100, "Vertical strength"),
			S("aim.speed", "Aim Speed %", 10, 200, 100, "Overall turn rate multiplier"),
			D("aim.sync", "Camera Sync", { "Early", "Late" }, "Only used for Camera method"),
			T("aim.sticky", "Sticky Target", true, "Stay on one player while locked instead of hopping"),
		} },
		{ name = "Targeting", rows = {
			D("aim.bone", "Aim Part", { "Head", "Torso", "Closest" }, "Closest picks whichever part is nearest the crosshair"),
			D("aim.priority", "Priority", { "Crosshair", "Distance", "Lowest HP" }, "How to choose between several targets"),
			S("aim.maxdist", "Max Distance", 50, 2000, 1000, "Studs"),
			T("aim.wall", "Wall Check", true, "Ignore targets behind geometry"),
			T("aim.team", "Team Check", true, "Ignore teammates"),
			T("aim.hpcheck", "Health Check", true, "Skip dead targets and targets with a ForceField"),
			S("aim.minhp", "Min Target HP %", 0, 100, 0, "Ignore targets below this health percent"),
		} },
		{ name = "Advanced", rows = {
			S("aim.pred", "Prediction", 0, 0.3, 0, "Leads moving targets (seconds of velocity)", 0.01),
			S("aim.deadzone", "Deadzone", 0, 10, 0, "Stop correcting when already this close (degrees)", 0.5),
			S("aim.humanize", "Humanize", 0, 10, 0, "Adds slow wobble so the aim is less robotic"),
			S("aim.reaction", "Reaction (ms)", 0, 400, 0, "Delay before locking a new target"),
			S("aim.forget", "Forget (ms)", 0, 800, 150, "How long to keep a target after leaving FOV"),
		} },
	} },
	{ title = "Silent Aim", col = 1, game = "full", tabs = {
		{ name = "Main", rows = {
			T("silent.enabled", "Silent Aim", false, "Premium silent lock — no hard camera snap. Soft assist + auto-fire options"),
			K("silent.key", "Silent Key", defKey("MouseButton2", "ButtonL2"), "Activation bind"),
			D("silent.mode", "Activation", MODES, "Hold, toggle, or always"),
			D("silent.bone", "Aim Part", { "Head", "Torso", "Closest", "Hitscan" }, "Hitscan prefers head then body"),
			D("silent.priority", "Priority", { "Crosshair", "Distance", "Lowest HP" }, "Target ranking"),
			S("silent.maxdist", "Max Distance", 50, 2000, 900, "Studs"),
			T("silent.wall", "Wall Check", true, "Require line of sight"),
			T("silent.team", "Team Check", true, "Ignore teammates"),
		} },
		{ name = "Behavior", rows = {
			S("silent.fov", "Silent FOV", 20, 400, 140, "Pixel radius around crosshair"),
			S("silent.smooth", "Assist Strength", 0, 30, 12, "0 = pure silent (no camera), higher = soft camera assist"),
			S("silent.headchance", "Headshot %", 0, 100, 70, "Chance to prefer head over body"),
			S("silent.reaction", "Reaction (ms)", 0, 400, 40, "Delay before accepting a new target"),
			S("silent.forget", "Forget (ms)", 0, 800, 200, "Keep target after leaving FOV"),
			T("silent.autofire", "Auto Fire", false, "Activate equipped tool when a target is valid"),
			S("silent.firerate", "Fire Rate (ms)", 40, 600, 90, "Delay between auto shots"),
			T("silent.drawfov", "Draw FOV", true, "Show silent FOV ring"),
		} },
	} },
	{ title = "Ragebot", col = 1, game = "full", tabs = {
		{ name = "Main", rows = {
			T("rage.enabled", "Ragebot", false, "Premium rage — instant lock, wide FOV, autofire. Overrides aimbot while active"),
			K("rage.key", "Rage Key", defKey("Z", "ButtonR1"), "One bind for keyboard, mouse AND controller"),
			D("rage.mode", "Activation", MODES, "Hold the key, toggle it, or always on"),
			S("rage.fov", "Rage FOV", 5, 180, 180, "Degrees from the crosshair (180 = all around you)"),
			D("rage.priority", "Priority", { "Crosshair", "Distance", "Lowest HP", "Highest HP" }, "How to choose between several targets"),
			S("rage.maxdist", "Max Distance", 50, 3000, 2000, "Studs"),
		} },
		{ name = "Hitscan", rows = {
			D("rage.bone", "Hit Part", { "Hitscan", "Head", "Torso" }, "Hitscan: head first, then body, then limbs, first visible wins"),
			T("rage.wall", "Wall Check", true, "Only lock onto visible parts"),
			T("rage.team", "Team Check", true, "Ignore teammates"),
			T("rage.hpcheck", "Health Check", true, "Skip dead targets and targets with a ForceField"),
			S("rage.pred", "Prediction", 0, 0.3, 0, "Leads moving targets (seconds of velocity)", 0.01),
			T("rage.autofire", "Auto Fire", true, "Activates your equipped Tool whenever a target is locked"),
			S("rage.firerate", "Fire Delay (ms)", 20, 1000, 100, "Minimum time between shots"),
		} },
		{ name = "Anti-Aim", rows = {
			D("rage.aa", "Anti-Aim", { "Off", "Spin", "Jitter", "Backwards" }, "Rotates your character while the ragebot is enabled"),
			S("rage.aaspeed", "Spin Speed", 60, 2000, 720, "Degrees per second"),
			S("rage.aajit", "Jitter Angle", 10, 180, 90, "Degrees either side of your view"),
		} },
	} },
	{ title = "FOV", col = 2, rows = {
		S("fov.size", "FOV Radius", 20, 600, 120, "Pixels around the crosshair that can be targeted"),
		T("fov.draw", "Draw FOV Circle", true, "Always visible while the aimbot is enabled"),
		C("fov.color", "FOV Color", rgb(240, 130, 200), "Circle color"),
		C("fov.lockcolor", "Locked Color", rgb(120, 255, 150), "Circle color while a target is locked"),
		T("fov.fill", "Fill Circle", false, "Faint fill inside the circle"),
	} },
	{ title = "Triggerbot", col = 2, rows = {
		T("trig.enabled", "Triggerbot", false, "Activates your equipped Tool when the crosshair is on an enemy"),
		K("trig.key", "Trigger Key", defKey("E", "ButtonR2"), "One bind for keyboard, mouse AND controller"),
		D("trig.mode", "Activation", MODES, "Hold the key, toggle it, or always on"),
		S("trig.delay", "Delay (ms)", 0, 300, 60, "Wait before firing"),
		T("trig.wall", "Wall Check", true, "Only fire at targets you can actually see"),
		T("trig.team", "Team Check", true, "Ignore teammates"),
		T("trig.hpcheck", "Health Check", true, "Skip dead targets and targets with a ForceField"),
	} },
	{ title = "Hitbox", col = 1, rows = {
		T("hb.enabled", "Hitbox Expander", false, "Enlarges enemy root parts on YOUR client only"),
		S("hb.size", "Hitbox Size", 2, 20, 6, "Studs"),
		S("hb.trans", "Transparency", 0, 1, 0.7, "Hitbox visibility", 0.05),
		T("hb.team", "Include Teammates", false, "Also expand teammates"),
	} },
	{ title = "Hit Feedback", col = 2, rows = {
		T("hit.enabled", "Hit Marker", true, "Click the preview to flash a hit marker"),
		C("hit.color", "Hit Color", rgb(255, 80, 100), "Hit marker color"),
		S("hit.size", "Hit Size", 4, 18, 8, "Hit marker size"),
	} },
	{ title = "Touch Controls", col = 2, rows = {
		T("mob.buttons", "On-Screen Buttons", true, "AIM / FIRE / RAGE buttons while the menu is closed", "Mobile"),
		S("mob.size", "Button Size", 50, 110, 66, "Pixels", 1, "Mobile"),
		S("mob.opacity", "Button Opacity", 20, 100, 90, "Percent", 1, "Mobile"),
	} },
})

buildPage("ESP", {
	{ title = "ESP Options", col = 1, rows = {
		T("live.esp", "In-Game ESP", true, "Apply the ESP settings to real players (uses every ESP option here)"),
		T("esp.enabled", "ESP Enabled", true, "Master switch for every overlay"),
		S("esp.maxdist", "ESP Max Distance", 100, 5000, 2500, "Studs"),
		T("esp.highlight", "Highlight", false, "Tint and outline the body (see Tracers / Chams)"),
		T("esp.box", "Box", true, "Bounding box around the model"),
		T("esp.names", "Names", true, "Name label above the box"),
		T("esp.healthinfo", "Health Info", true, "Numeric health next to the bar"),
		T("esp.vhealth", "Vertical Health", true, "Vertical health bar on the left"),
		T("esp.weapon", "Weapon Info", false, "Equipped item label"),
		T("esp.ammo", "Ammo Text", false, "Ammo counter label (reads the Tool's Ammo attribute)"),
		T("esp.distance", "Distance", false, "Distance label"),
		T("esp.look", "Look Direction", false, "Facing indicator from the head"),
		T("esp.arrows", "Arrows", false, "Edge arrows pointing at players who are off screen"),
		T("esp.team", "Show Teammates", false, "Draw teammates too and tag them"),
	} },
	{ title = "Extra ESP", col = 2, tabs = {
		{ name = "Skeleton / Head", rows = {
			T("skel.enabled", "Skeleton", true, "Draw bones over the model"),
			S("skel.thick", "Skeleton thickness", 1, 5, 1, "Bone line thickness"),
			C("skel.c1", "Skeleton color 1", rgb(255, 255, 255), "Spine, shoulders, hips"),
			C("skel.c2", "Skeleton color 2", rgb(160, 100, 255), "Arms"),
			C("skel.c3", "Skeleton color 3", rgb(90, 160, 255), "Legs"),
			T("head.enabled", "Head marker", true, "Marker over the head"),
			C("head.color", "Head marker color", rgb(255, 80, 80), "Marker color"),
			D("head.shape", "Marker shape", { "Cross", "Circle", "Square" }, "Marker appearance"),
			T("head.fill", "Fill circle marker", false, "Fill circle / square shapes"),
			S("head.size", "Marker size", 1, 12, 5, "Marker size"),
			S("head.thick", "Marker thickness", 1, 5, 1, "Marker line thickness"),
		} },
		{ name = "Bars / Fill", rows = {
			S("bars.width", "Bar width", 2, 8, 3, "Health bar width"),
			C("bars.high", "Health high color", rgb(120, 255, 120), "Color at full health"),
			C("bars.low", "Health low color", rgb(255, 80, 100), "Color at low health"),
			T("bars.gradient", "Gradient bar", false, "Blend high and low colors along the bar"),
			D("bars.boxstyle", "Box style", { "Full", "Corners" }, "Outline or corner brackets"),
			C("bars.boxcolor", "Box color", rgb(255, 255, 255), "Box outline color"),
			S("bars.boxthick", "Box thickness", 1, 4, 1, "Box line thickness"),
			T("bars.fillbox", "Fill box", false, "Shade the inside of the box"),
			C("bars.fillcolor", "Fill color", rgb(160, 100, 255), "Box fill color"),
			S("bars.fillopacity", "Fill opacity", 5, 70, 20, "Box fill opacity"),
		} },
		{ name = "Tracers / Chams", rows = {
			T("tr.enabled", "Tracers", false, "Line from a screen anchor to the feet"),
			D("tr.origin", "Tracer origin", { "Bottom", "Center", "Top" }, "Where tracers start"),
			C("tr.color", "Tracer color", rgb(240, 130, 200), "Tracer color"),
			S("tr.thick", "Tracer thickness", 1, 4, 1, "Tracer line thickness"),
			C("cham.fill", "Chams fill", rgb(160, 100, 255), "Requires Highlight in ESP Options"),
			C("cham.outline", "Chams outline", rgb(255, 255, 255), "Requires Highlight in ESP Options"),
			S("cham.opacity", "Chams opacity", 0, 100, 45, "How strongly the fill tints the body"),
			T("cham.pulse", "Chams pulse", false, "Animate the outline"),
		} },
		{ name = "Formatting", rows = {
			S("fmt.size", "Text size", 9, 18, 12, "ESP text size"),
			C("fmt.color", "Text color", rgb(255, 255, 255), "ESP text color"),
			D("fmt.font", "Font", { "Gotham", "Code", "Merriweather" }, "ESP text font"),
			T("fmt.outline", "Text outline", true, "Outline ESP text"),
			D("fmt.unit", "Distance unit", { "Meters", "Studs" }, "Distance format"),
			S("fmt.hp", "Preview health", 0, 100, 75, "Health value shown in the preview"),
		} },
	} },
})

buildPage("Visuals", {
	{ title = "Interface", col = 1, rows = {
		T("vis.glow", "Glow Effects", true, "Window glow"),
		S("vis.glowstr", "Glow Strength", 0, 100, 70, "Glow intensity"),
		T("vis.anim", "Animated Glow", true, "Pulse the glow"),
		T("vis.petals", "Falling Petals", true, "Decorative petals"),
		S("vis.petalcount", "Petal Count", 1, 30, 14, "How many petals"),
		S("vis.opacity", "UI Opacity", 40, 100, 100, "Card opacity"),
	} },
	{ title = "Colors", col = 2, rows = {
		D("vis.preset", "Theme Preset", { "Lilac", "Rose", "Violet", "Ice", "Mint", "Amber" }, "Applies a color pair"),
		C("vis.accent", "Accent Color", Presets.Lilac[1], "Primary accent"),
		C("vis.accent2", "Secondary Accent", Presets.Lilac[2], "Secondary accent"),
	} },
	{ title = "HUD", col = 2, rows = {
		T("vis.watermark", "Watermark", true, "Name, FPS and ping, top left"),
		T("vis.keylist", "Keybind List", true, "Shows enabled features and their binds"),
		T("vis.targethud", "Target Info", true, "Name, health and distance of the locked target"),
		T("vis.targetline", "Target Line", true, "Line from the crosshair to the locked target"),
		T("vis.arraylist", "Array List", true, "Enabled modules, top right"),
	} },
	{ title = "Hit Effects", col = 1, rows = {
		D("hfx.source", "Trigger", { "Any Damage", "Locked Target" }, "When a hit effect plays"),
		T("hfx.text", "Damage Text", true, "Floating damage numbers"),
		T("hfx.ring", "Hit Ring", true, "Expanding ring on the hit"),
		T("hfx.slash", "Hit Slash", false, "Slash mark on the hit"),
		T("hfx.notify", "Hit Notifier", false, "Toast with the victim and damage"),
		C("hfx.color", "Effect Color", rgb(255, 80, 100), "Hit effect color"),
	} },
})

buildPage("World", {
	{ title = "Scene", col = 1, rows = {
		D("world.env", "Environment", { "Default", "Night", "Soft", "Neon" }, "Preview backdrop"),
		S("world.brightness", "Brightness", 20, 100, 70, "Preview brightness"),
		T("world.grid", "Grid Floor", true, "Perspective grid"),
	} },
	{ title = "Lighting", col = 2, rows = {
		C("world.tint", "Ambient Tint", rgb(255, 255, 255), "Tints the preview backdrop"),
	} },
	{ title = "Ambiance", col = 2, rows = {
		T("amb.override", "Override Time", false, "Force the time of day"),
		S("amb.clock", "Clock Time", 0, 24, 14, "0 = midnight, 12 = noon", 0.5),
	} },
	{ title = "Camera / Lighting", col = 1, rows = {
		T("world.fovon", "Camera FOV", false, "Override the camera field of view"),
		S("world.fov", "Field of View", 30, 120, 70, "Degrees"),
		T("world.fullbright", "Fullbright", false, "Removes shadows and darkness"),
		T("world.nofog", "No Fog", false, "Pushes the fog away"),
	} },
	{ title = "Post Processing", col = 2, rows = {
		T("fx.bloom", "Bloom", false, "Soft glow on bright areas"),
		S("fx.bloomint", "Bloom Intensity", 0, 3, 1, "Glow strength", 0.1),
		T("fx.cc", "Color Correction", false, "Grade the whole screen"),
		S("fx.sat", "Saturation", -1, 2, 0, "-1 = grayscale", 0.05),
		S("fx.con", "Contrast", -1, 1, 0, "Screen contrast", 0.05),
		S("fx.bri", "Brightness", -0.5, 0.5, 0, "Screen brightness", 0.05),
		C("fx.tint", "Screen Tint", rgb(255, 255, 255), "Color grade tint"),
		T("fx.rays", "Sun Rays", false, "God rays from the sun"),
		S("fx.raysint", "Rays Intensity", 0, 1, 0.25, "Ray strength", 0.05),
		T("fx.menublur", "Menu Blur", true, "Blur the game behind the menu"),
	} },
	{ title = "Atmosphere / Weather", col = 1, rows = {
		T("fx.atmo", "Atmosphere Override", false, "Control density, haze and color"),
		S("fx.density", "Density", 0, 1, 0.3, "Atmosphere density", 0.05),
		S("fx.haze", "Haze", 0, 10, 0, "Haze amount", 0.5),
		C("fx.atmocolor", "Atmosphere Color", rgb(199, 170, 214), "Atmosphere color"),
		D("fx.weather", "Weather", { "None", "Rain", "Snow" }, "Particles that follow your camera"),
		S("fx.weatherrate", "Weather Intensity", 10, 300, 100, "Particle amount"),
	} },
})

buildPage("Character", {
	{ title = "Appearance", col = 1, rows = {
		C("char.skin", "Skin", rgb(226, 190, 150), "Preview skin color"),
		C("char.shirt", "Shirt", rgb(24, 22, 30), "Preview shirt color"),
		C("char.pants", "Pants", rgb(70, 76, 66), "Preview pants color"),
		C("char.hair", "Hair", rgb(30, 24, 30), "Preview hair color"),
	} },
	{ title = "Animation", col = 2, rows = {
		T("char.sway", "Idle Sway", true, "Gentle idle motion"),
		S("char.speed", "Sway Speed", 0.5, 4, 1.5, "Sway speed", 0.1),
		S("char.scale", "Model Scale", 60, 130, 100, "Preview model scale"),
	} },
	{ title = "Movement", col = 1, rows = {
		T("mv.speed", "Speed", false, "Override WalkSpeed"),
		S("mv.speedval", "Walk Speed", 16, 120, 40, "Studs / second"),
		D("mv.speedmode", "Speed Mode", { "WalkSpeed", "CFrame" }, "CFrame moves you directly and ignores WalkSpeed limits"),
		T("mv.float", "Float", false, "Hover in place"),
		T("mv.jump", "Jump Power", false, "Override jump power"),
		S("mv.jumpval", "Jump Power Value", 50, 250, 90, "Studs / second"),
		T("mv.fly", "Fly", false, "Move stick / WASD, Jump = up, Shift or B = down"),
		S("mv.flyspeed", "Fly Speed", 10, 150, 50, "Studs / second"),
		T("mv.infjump", "Infinite Jump", false, "Jump in mid-air"),
		T("mv.bhop", "Bunny Hop", false, "Hold jump to keep hopping"),
		T("mv.noclip", "Noclip", false, "Walk through walls"),
		T("fc.enabled", "Freecam", false, "Detach camera — WASD/QE, RMB look"),
		S("fc.speed", "Freecam Speed", 5, 200, 40, "Studs / second (Shift = 3x)"),
	} },
})

buildPage("Misc", {
	{ title = "Configs", col = 1, rows = {
		D("cfg.selected", "Config", { "default" }, "Choose a named config to load / save"),
		B("Save Config", "Save", function()
			local name = Settings["cfg.selected"] or "default"
			local ok, res = saveNamedConfig(name)
			if ok then
				notify("Config saved", "Saved as \"" .. res .. "\"")
				if refreshConfigDropdown then refreshConfigDropdown() end
			else
				notify("Save failed", tostring(res or "executor has no writefile"))
			end
		end, "Save current settings under the selected name"),
		B("Load Config", "Load", function()
			local name = Settings["cfg.selected"] or "default"
			if loadNamedConfig(name) then
				notify("Config loaded", "Loaded \"" .. name .. "\"")
			else
				notify("Load failed", "No file for \"" .. name .. "\"")
			end
		end, "Apply the selected named config"),
		B("New Config Name", "Create", function()
			local sg = create("ScreenGui", { Name = "LilacCfgName", ResetOnSpawn = false, DisplayOrder = 3000 }, playerGui)
			local f = create("Frame", {
				BackgroundColor3 = Theme.Card, AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(380, 130), BorderSizePixel = 0,
			}, sg)
			corner(f, 12); stroke(f, Theme.Accent, 1.2, 0.2)
			local t = text(f, "Name this config", 13, Theme.Text, HEAD)
			t.Position = UDim2.fromOffset(16, 12); t.Size = UDim2.new(1, -32, 0, 22)
			local tb = create("TextBox", {
				Text = "", PlaceholderText = "e.g. rage, legit, lobby",
				ClearTextOnFocus = false, Font = LIGHT, TextSize = 12, TextColor3 = Theme.Text,
				PlaceholderColor3 = Theme.Muted, BackgroundColor3 = Theme.Field,
				Position = UDim2.fromOffset(16, 44), Size = UDim2.new(1, -32, 0, 32), BorderSizePixel = 0,
			}, f)
			corner(tb, 8); stroke(tb, Theme.Border, 1)
			local okb = makeButton(f, "Save", 90, 30, true)
			okb.Position = UDim2.new(1, -106, 1, -40)
			local cancel = makeButton(f, "Cancel", 90, 30, false)
			cancel.Position = UDim2.new(1, -204, 1, -40)
			cancel.Activated:Connect(function() sg:Destroy() end)
			okb.Activated:Connect(function()
				local name = tb.Text
				local ok, res = saveNamedConfig(name)
				sg:Destroy()
				if ok then
					Settings["cfg.selected"] = res
					if refreshConfigDropdown then refreshConfigDropdown() end
					notify("Config created", res)
				else
					notify("Create failed", tostring(res))
				end
			end)
		end, "Create a new named config from current settings"),
		T("cfg.autoload", "Auto Load Config", true, "On inject, load the autoload config name"),
		B("Set as Autoload", "Set", function()
			local name = Settings["cfg.selected"] or "default"
			setAutoloadName(name)
			notify("Autoload set", "Will load \"" .. name .. "\" on inject")
		end, "Remember selected config as the one to auto-load"),
	} },
	{ title = "Startup", col = 2, rows = {
		T("misc.notify", "Notifications", true, "Show toast messages"),
		T("misc.loadnotify", "Load Toast", true, "Toast when Lilac finishes loading"),
		T("misc.silentload", "Silent Load", false, "Skip load toast"),
		T("misc.tpautoload", "Reload After TP", true, "Re-inject after teleport (uses GitHub URL if set)"),
		B("TP / Script URL", "Set", function()
			local sg = create("ScreenGui", { Name = "LilacTpUrlPrompt", ResetOnSpawn = false, DisplayOrder = 3000 }, playerGui)
			local f = create("Frame", {
				BackgroundColor3 = Theme.Card, AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(440, 150), BorderSizePixel = 0,
			}, sg)
			corner(f, 12); stroke(f, Theme.Accent, 1.2, 0.2)
			local t = text(f, "Optional GitHub raw URL (re-inject after TP)", 12, Theme.Text, HEAD)
			t.Position = UDim2.fromOffset(16, 12); t.Size = UDim2.new(1, -32, 0, 22)
			local tb = create("TextBox", {
				Text = tostring(Settings["misc.tploadurl"] or ""), PlaceholderText = "https://raw.githubusercontent.com/.../lilac.lua",
				ClearTextOnFocus = false, Font = LIGHT, TextSize = 11, TextColor3 = Theme.Text,
				PlaceholderColor3 = Theme.Muted, BackgroundColor3 = Theme.Field,
				Position = UDim2.fromOffset(16, 44), Size = UDim2.new(1, -32, 0, 32), BorderSizePixel = 0,
			}, f)
			corner(tb, 8); stroke(tb, Theme.Border, 1)
			local okb = makeButton(f, "Save", 90, 30, true)
			okb.Position = UDim2.new(1, -106, 1, -40)
			local cancel = makeButton(f, "Cancel", 90, 30, false)
			cancel.Position = UDim2.new(1, -204, 1, -40)
			cancel.Activated:Connect(function() sg:Destroy() end)
			okb.Activated:Connect(function()
				Settings["misc.tploadurl"] = tb.Text
				notify("URL saved", tb.Text == "" and "Cleared" or "TP reload armed")
				sg:Destroy()
			end)
		end, "Only needed for place teleports; configs still auto-load by name"),
		T("misc.antiafk", "Anti-AFK", false, "Prevents idle kick"),
		T("misc.togglenotify", "Module Toasts", false, "Toast when modules toggle"),
		T("misc.tips", "Tooltips", true, "Hover tips", "PC"),
		B("Skin Changer", "Open", function()
			if not lilacFullGame then
				notify("Skin Changer", "Only available in the full-feature place")
				return
			end
			if shared.LilacCosmeticChanger and shared.LilacCosmeticChanger.Toggle then
				shared.LilacCosmeticChanger.Toggle()
				notify("Skin Changer", "Toggled")
			else
				notify("Skin Changer", "Not available yet")
			end
		end, "Open cosmetic / skin window"),
	} },
})

buildPage("Settings", {
	{ title = "Menu", col = 1, rows = {
		K("set.menukey", "Menu Key", "RightShift", "Show / hide the window. Controllers can always use Select"),
		S("set.scale", "Interface Scale", 70, 120, 100, "Window scale (%)"),
		T("set.preview", "Show Live Preview", platform == "PC", "Show the preview panel", "PC"),
		T("set.lock", "Lock Window", false, "Disable dragging", "PC,Mobile"),
		T("set.confirm", "Confirm Resets", true, "Ask before resetting"),
		T("set.cursor", "Custom Cursor", true, "Draws its own cursor above the menu (fixes the cursor hiding in first person)", "PC"),
		T("set.hints", "Controller Hints", true, "Show the controller button hint bar", "Console"),
	} },
	{ title = "Reset", col = 2, rows = {
		D("set.resettab", "Section", tabOrder, "Which section to reset"),
		B("Reset Section", "Reset", function()
			local tab = Settings["set.resettab"]
			confirm("Reset " .. tab .. "?", "This restores every " .. tab .. " setting to its default.", function()
				resetKeys(TabKeys[tab])
				notify("Reset complete", tab .. " restored to defaults.")
			end)
		end, "Reset the selected section"),
		B("Reset All Settings", "Reset all", function()
			confirm("Reset everything?", "Every setting returns to its default.", function()
				resetAll()
				notify("Reset complete", "All settings restored.")
			end)
		end, "Reset every setting", true),
		B("Unload Interface", "Unload", function()
			confirm("Unload Lilac?", "This removes the menu and turns every feature off.", function()
				unload()
			end)
		end, "Remove Lilac completely"),
	} },
})

--------------------------------------------------------------------------
-- navigation
--------------------------------------------------------------------------
local navButtons = {}
local function styleNav()
	for name, nb in pairs(navButtons) do
		local a = name == currentTab
		tween(nb.btn, { BackgroundTransparency = a and 0 or 1 }, 0.15)
		tween(nb.stroke, { Transparency = a and 0.05 or 1 }, 0.15)
		tween(nb.bar, { BackgroundTransparency = a and 0 or 1 }, 0.15)
		nb.label.TextColor3 = a and Theme.Text or Theme.Muted
		nb.stroke.Color = Theme.Accent
		nb.icon(a and Theme.Accent or Theme.Muted)
	end
end

local function selectTab(name)
	closePopup()
	currentTab = name
	pageTitle.Text = name
	searchBox.Text = ""
	for n, p in pairs(pages) do
		p.scroll.Visible = n == name
	end
	local p = pages[name]
	applySearch(p, "")
	p.scroll.CanvasPosition = Vector2.new(0, 0)
	p.scroll.Position = UDim2.fromOffset(22, 94)
	tween(p.scroll, { Position = UDim2.fromOffset(22, 84) }, 0.25)
	styleNav()
end

for i, name in ipairs(tabOrder) do
	if name == "Settings" then
		create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 14), LayoutOrder = 99 }, navHolder)
	end
	local btn = create("TextButton", {
		Name = name,
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = Theme.CardHead,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, isMobile and 34 or 42),
		LayoutOrder = name == "Settings" and 100 or i,
		BorderSizePixel = 0,
	}, navHolder)
	corner(btn, 12)
	local st = stroke(btn, Theme.Accent, 1.5, 1)
	local bar = create("Frame", {
		BackgroundColor3 = Theme.Accent,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 3, 0.5, -9),
		Size = UDim2.fromOffset(3, 18),
	}, btn)
	round(bar)
	bindAccent(function() bar.BackgroundColor3 = Theme.Accent end)
	local ic, setIc = makeIcon(name, btn)
	ic.Position = UDim2.new(0, 14, 0.5, -10)
	local lb = text(btn, name, 13, Theme.Muted, BODY)
	lb.Position = UDim2.fromOffset(46, 0)
	lb.Size = UDim2.new(1, -50, 1, 0)
	navButtons[name] = { btn = btn, stroke = st, icon = setIc, label = lb, bar = bar }
	btn.Activated:Connect(function() selectTab(name) end)
	btn.MouseEnter:Connect(function()
		if currentTab ~= name then tween(btn, { BackgroundTransparency = 0.6 }, 0.1) end
	end)
	btn.MouseLeave:Connect(function()
		if currentTab ~= name then tween(btn, { BackgroundTransparency = 1 }, 0.1) end
	end)
end
bindAccent(styleNav)

--------------------------------------------------------------------------
-- handlers
--------------------------------------------------------------------------
Handlers["vis.accent"] = function(c) Theme.Accent = c; refreshAccent() end
Handlers["vis.accent2"] = function(c) Theme.Accent2 = c; refreshAccent() end
Handlers["vis.preset"] = function(v)
	if bulk then return end
	local p = Presets[v]
	if p then
		applySetting("vis.accent", p[1])
		applySetting("vis.accent2", p[2])
	end
end
Handlers["vis.opacity"] = function(v)
	local t = (100 - v) / 100 * 0.85
	for _, c in ipairs(cardFrames) do c.BackgroundTransparency = t end
	sidebar.BackgroundTransparency = 0.15 + (100 - v) / 100 * 0.6
end
Handlers["misc.compact"] = function(v)
	for _, r in ipairs(allRows) do
		r.frame.Size = UDim2.new(1, 0, 0, r.base - (v and 6 or 0))
	end
end
Handlers["set.scale"] = function(v) userScale = v / 100; fit() end
Handlers["set.preview"] = function() updatePreviewVisible() end

-- minimize
local minimized = false
minButton.Activated:Connect(function()
	minimized = not minimized
	closePopup()
	local h = minimized and 56 or RH
	tween(main, { Size = UDim2.fromOffset(MAIN_W, h) }, 0.28)
	tween(glowOuter, { Size = UDim2.fromOffset(MAIN_W + 10, h + 10) }, 0.28)
	tween(glowInner, { Size = UDim2.fromOffset(MAIN_W + 4, h + 4) }, 0.28)
	if minimized then
		preview.Visible = false
		previewGlow.Visible = false
	else
		task.delay(0.2, updatePreviewVisible)
	end
end)

--------------------------------------------------------------------------
-- open / close with animation, custom cursor, mouse unlock
--------------------------------------------------------------------------
local cursor = create("Frame", {
	BackgroundTransparency = 1,
	AnchorPoint = Vector2.new(0.5, 0.5),
	Size = UDim2.fromOffset(0, 0),
	Visible = false,
	ZIndex = 10,
}, cursorGui)
do
	local ringC = create("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(18, 18),
		ZIndex = 10,
	}, cursor)
	round(ringC)
	local ringS = stroke(ringC, Theme.Accent, 2, 0)
	local dot = create("Frame", {
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(4, 4),
		ZIndex = 11,
	}, cursor)
	round(dot)
	stroke(dot, Color3.new(0, 0, 0), 1, 0.4)
	bindAccent(function() ringS.Color = Theme.Accent end)
end

local prevMouseIcon = UserInputService.MouseIconEnabled
local cursorHidden = false
RunService:BindToRenderStep("LilacMouse", Enum.RenderPriority.Last.Value + 2, function()
	local pcMenu = Menu.open and activePlat == "PC"
	if pcMenu then UserInputService.MouseBehavior = Enum.MouseBehavior.Default end
	local show = pcMenu and Settings["set.cursor"] ~= false
	cursor.Visible = show
	if show then
		local m = UserInputService:GetMouseLocation()
		cursor.Position = UDim2.fromOffset(m.X, m.Y)
		if not cursorHidden then
			prevMouseIcon = UserInputService.MouseIconEnabled
			UserInputService.MouseIconEnabled = false
			cursorHidden = true
		end
	elseif cursorHidden then
		UserInputService.MouseIconEnabled = prevMouseIcon
		cursorHidden = false
	end
end)
table.insert(cleanups, function()
	RunService:UnbindFromRenderStep("LilacMouse")
	if cursorHidden then UserInputService.MouseIconEnabled = prevMouseIcon end
end)

local openToken = 0
local function setMenuOpen(open)
	if Menu.open == open then return end
	Menu.open = open
	openToken += 1
	local my = openToken
	closePopup()
	dim.Modal = open
	if open then
		root.Visible = true
		dim.Visible = true
		animVal.Value = 0.92
		tween(animVal, { Value = 1 }, 0.32, Enum.EasingStyle.Back)
		dim.BackgroundTransparency = 1
		tween(dim, { BackgroundTransparency = 0.45 }, 0.25)
		if lastInputIsPad() then GuiService.SelectedObject = navButtons[currentTab].btn end
	else
		tween(animVal, { Value = 0.94 }, 0.14)
		tween(dim, { BackgroundTransparency = 1 }, 0.14)
		GuiService.SelectedObject = nil
		task.delay(0.16, function()
			if my == openToken then
				root.Visible = false
				dim.Visible = false
				animVal.Value = 1
			end
		end)
	end
end
Hooks.setOpen = setMenuOpen

-- floating open/close button (mobile only)
if isMobile then
	local mt = create("TextButton", {
		Name = "LilacToggle",
		Text = "L",
		Font = HEAD,
		TextSize = 20,
		TextColor3 = Theme.Accent,
		AutoButtonColor = false,
		Selectable = false,
		BackgroundColor3 = Theme.Card,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 64),
		Size = UDim2.fromOffset(46, 46),
		ZIndex = 400,
	}, hudGui)
	round(mt)
	local mtStroke = stroke(mt, Theme.Accent, 1.5, 0.1)
	bindAccent(function() mt.TextColor3 = Theme.Accent; mtStroke.Color = Theme.Accent end)
	mt.Activated:Connect(function() setMenuOpen(not Menu.open) end)
end

-- controller hint bar
local padHint = text(content, "A select    B back    LB / RB tabs    X / Y adjust sliders", 10, Theme.Muted, LIGHT, Enum.TextXAlignment.Right)
padHint.Position = UDim2.fromOffset(22, RH - 20)
padHint.Size = UDim2.fromOffset(CONTENT_W - 44, 14)
padHint.ZIndex = 5
padHint.Visible = false

-- live platform switching: rows for other platforms hide themselves
Hooks.platform = function()
	pSub.Text = "Lilac Premium  ·  " .. (lilacFullGame and "FULL" or "UNI") .. "  ·  " .. activePlat
	applySearch(pages[currentTab], searchBox.Text)
	padHint.Visible = activePlat == "Console" and Settings["set.hints"] ~= false
	if Menu.open and activePlat == "Console" and not GuiService.SelectedObject then
		GuiService.SelectedObject = navButtons[currentTab].btn
	end
end
connect(UserInputService.LastInputTypeChanged, function()
	local np = inputClass()
	if np ~= activePlat then
		activePlat = np
		Hooks.platform()
	end
end)
Handlers["set.hints"] = function() if Hooks.platform and pages.Combat then Hooks.platform() end end

-- menu key (universal bind) + controller Select fallback
connect(UserInputService.InputBegan, function(i)
	if _G.__LilacBinding or UserInputService:GetFocusedTextBox() then return end
	if os.clock() - (_G.__LilacBindTime or 0) < 0.3 then return end
	if matchesBind(i, Settings["set.menukey"]) or i.KeyCode == Enum.KeyCode.ButtonSelect then
		setMenuOpen(not Menu.open)
	end
end)

-- controller navigation: LB/RB tabs, B back, X/Y nudge the selected slider
connect(UserInputService.InputBegan, function(i)
	if not Menu.open or _G.__LilacBinding then return end
	if i.UserInputType.Name:sub(1, 7) ~= "Gamepad" then return end
	local kc = i.KeyCode
	if kc == Enum.KeyCode.ButtonR1 or kc == Enum.KeyCode.ButtonL1 then
		local idx = table.find(tabOrder, currentTab) or 1
		idx = (idx - 1 + (kc == Enum.KeyCode.ButtonR1 and 1 or -1)) % #tabOrder + 1
		selectTab(tabOrder[idx])
	elseif kc == Enum.KeyCode.ButtonB then
		if popup then closePopup() else setMenuOpen(false) end
	elseif kc == Enum.KeyCode.ButtonX or kc == Enum.KeyCode.ButtonY then
		local fn = sliderNudge[GuiService.SelectedObject]
		if fn then fn(kc == Enum.KeyCode.ButtonY and 1 or -1) end
	end
end)

--------------------------------------------------------------------------
-- UI frame loop
--------------------------------------------------------------------------
local t0 = os.clock()
local fpsSmooth = 60
connect(RunService.Heartbeat, function(dt)
	fpsSmooth = fpsSmooth + (1 / math.max(dt, 1e-3) - fpsSmooth) * 0.05
	if not root.Visible then return end
	local t = os.clock() - t0
	fpsLabel.Text = string.format("%s  ·  %d FPS", activePlat, math.floor(fpsSmooth + 0.5))

	-- glow
	local strength = Settings["vis.glow"] and (Settings["vis.glowstr"] / 100) or 0
	local pulse = Settings["vis.anim"] and (0.78 + 0.22 * math.sin(t * 1.8)) or 1
	glowOuterStroke.Transparency = 1 - 0.34 * strength * pulse
	glowInnerStroke.Transparency = 1 - 0.6 * strength * pulse
	previewGlowStroke.Transparency = 1 - 0.3 * strength * pulse

	-- petals
	local show = Settings["vis.petals"]
	local count = Settings["vis.petalcount"]
	for i, p in ipairs(petals) do
		local vis = show and i <= count
		p.f.Visible = vis
		if vis then
			p.y += p.vy * dt
			p.x += (p.vx + 10 * math.sin(t * 1.1 + p.ph)) * dt
			p.rot += p.vr * dt
			if p.y > RH + 20 or p.x < -20 then
				p.y = -20
				p.x = math.random(0, MAIN_W)
			end
			p.f.Position = UDim2.fromOffset(p.x, p.y)
			p.f.Rotation = p.rot
		end
	end

	-- preview
	if previewDirty then
		previewDirty = false
		renderPreview()
	end
	if Settings["char.sway"] then
		char.Rotation = math.sin(t * Settings["char.speed"]) * 1.6
	elseif char.Rotation ~= 0 then
		char.Rotation = 0
	end
	if Settings["esp.enabled"] and Settings["esp.highlight"] and Settings["cham.pulse"] then
		local a = 0.45 + 0.35 * math.sin(t * 3)
		for _, p in pairs(parts) do p.stroke.Transparency = a end
	else
		for _, p in pairs(parts) do p.stroke.Transparency = 0 end
	end

	padHint.Visible = activePlat == "Console" and Settings["set.hints"] ~= false

	-- tooltip
	if tipActive then
		local m = UserInputService:GetMouseLocation()
		tipFrame.Position = UDim2.fromOffset(m.X + 16, m.Y + 18)
	end
end)

--------------------------------------------------------------------------
-- features (act on real players in your test game)
--------------------------------------------------------------------------
do -- features scope
local lp = player
local cam = workspace.CurrentCamera
connect(workspace:GetPropertyChangedSignal("CurrentCamera"), function() cam = workspace.CurrentCamera end)

local worldLayer = create("Frame", {
	Name = "World",
	BackgroundTransparency = 1,
	Size = UDim2.fromScale(1, 1),
	ZIndex = 1,
	Active = false,
}, hudGui)

local function myChar() return lp.Character end
local function myHum()
	local c = myChar()
	return c and c:FindFirstChildOfClass("Humanoid")
end
local function myRoot()
	local c = myChar()
	return c and c:FindFirstChild("HumanoidRootPart")
end
local function sameTeam(plr)
	return lp.Team ~= nil and plr.Team == lp.Team
end
local function alive(plr)
	local c = plr.Character
	local h = c and c:FindFirstChildOfClass("Humanoid")
	return c, h, (h ~= nil and h.Health > 0)
end

-- Lobby / menu detection: combat + ESP stay off in lobbies
local _lobbyCache, _lobbyAt = true, 0
local function inLobby()
	local now = os.clock()
	if now - _lobbyAt < 0.5 then return _lobbyCache end
	_lobbyAt = now
	local function hit(text)
		if text == nil then return false end
		local s = tostring(text):lower():gsub("[%s_%-]", "")
		return s:find("lobby", 1, true) or s:find("menu", 1, true) or s:find("hub", 1, true)
			or s:find("afk", 1, true) or s:find("queue", 1, true) or s:find("mainmenu", 1, true)
	end
	local attrs = { "Map", "MapName", "Mode", "GameMode", "Arena", "Environment", "State", "GameState", "Phase", "Status" }
	for _, root in ipairs({ workspace, lp }) do
		for _, a in ipairs(attrs) do
			if hit(root:GetAttribute(a)) then _lobbyCache = true; return true end
		end
	end
	-- folder / model names near player
	local char = lp.Character
	local root = char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart)
	for _, child in ipairs(workspace:GetChildren()) do
		if hit(child.Name) then
			if not root then _lobbyCache = true; return true end
			local part = child:IsA("BasePart") and child or child:FindFirstChildWhichIsA("BasePart", true)
			if part and (part.Position - root.Position).Magnitude < 2500 then
				_lobbyCache = true; return true
			end
		end
	end
	-- place name (async API avoided for sync path)
	local placeName = game.Name
	if hit(placeName) then _lobbyCache = true; return true end
	-- Soft lobby signal
	_lobbyCache = false
	return false
end

local function combatAllowed()
	return not inLobby() and not Menu.open
end
local function typing() return UserInputService:GetFocusedTextBox() ~= nil end

-- shared state the HUD reads
local Track = { part = nil, plr = nil, mode = nil, trigT = 0 }
local fc = { on = false, yaw = 0, pitch = 0, pos = Vector3.zero, s1 = Vector2.zero, s2 = Vector2.zero, prevType = nil }
local hitStep = function() end

-- activation (universal binds: same key row works for keyboard / mouse / controller) -------
local toggled = { aim = false, silent = false, trig = false, rage = false }
local touchHeld = { aim = false, silent = false, trig = false, rage = false }
local function modeActive(p)
	local mode = Settings[p .. ".mode"]
	if mode == "Always" then return true end
	if mode == "Toggle" then return toggled[p] end
	return bindDown(Settings[p .. ".key"]) or touchHeld[p]
end
connect(UserInputService.InputBegan, function(i)
	if _G.__LilacBinding or typing() or Menu.open then return end
	for p in pairs(toggled) do
		if Settings[p .. ".mode"] == "Toggle" and matchesBind(i, Settings[p .. ".key"]) then
			toggled[p] = not toggled[p]
		end
	end
end)

-- on-screen buttons (mobile only) ---------------------------------------------------
local touchBtns = {}
if isMobile then
	local function isTap(i)
		return i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1
	end
	for idx, d in ipairs({ { "aim", "AIM" }, { "silent", "SIL" }, { "trig", "FIRE" }, { "rage", "RAGE" } }) do
		local p = d[1]
		local b = create("TextButton", {
			Text = d[2],
			Font = BOLD,
			TextSize = 13,
			TextColor3 = Theme.Text,
			AutoButtonColor = false,
			Selectable = false,
			BackgroundColor3 = Theme.Card,
			AnchorPoint = Vector2.new(1, 1),
			Size = UDim2.fromOffset(66, 66),
			Visible = false,
			ZIndex = 5,
		}, hudGui)
		round(b)
		stroke(b, Theme.Accent, 2, 0.2)
		b.InputBegan:Connect(function(i)
			if not isTap(i) then return end
			if Settings[p .. ".mode"] == "Toggle" then toggled[p] = not toggled[p] else touchHeld[p] = true end
		end)
		b.InputEnded:Connect(function(i)
			if isTap(i) then touchHeld[p] = false end
		end)
		touchBtns[p] = { b = b, idx = idx }
	end
end

local function targetOk(plr, c, hum, p)
	if not hum or hum.Health <= 0 then return false end
	if Settings[p .. ".team"] and sameTeam(plr) then return false end
	local hpcheck = Settings[p .. ".hpcheck"]
	if hpcheck == nil and p == "silent" then hpcheck = Settings["aim.hpcheck"] end
	if hpcheck then
		if c:FindFirstChildOfClass("ForceField") then return false end
		if (p == "aim" or p == "silent") and Settings["aim.minhp"] and hum.Health / math.max(hum.MaxHealth, 1) * 100 < Settings["aim.minhp"] then return false end
	end
	return true
end

local function lineBetween(f, a, b, th, col)
	local d = b - a
	f.Position = UDim2.fromOffset((a.X + b.X) / 2, (a.Y + b.Y) / 2)
	f.Size = UDim2.fromOffset(d.Magnitude, th)
	f.Rotation = math.deg(math.atan2(d.Y, d.X))
	if col then f.BackgroundColor3 = col end
end

local function aimRef()
	local vs = cam.ViewportSize
	local firstPerson = (cam.Focus.Position - cam.CFrame.Position).Magnitude < 1.5
	if UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter or firstPerson or activePlat ~= "PC" then
		return Vector2.new(vs.X / 2, vs.Y / 2), true
	end
	return UserInputService:GetMouseLocation(), false
end

	-- step callbacks filled by setup* functions (keeps each under Luau register limit)
	local Steps = { esp = function() end, fov = function() end, trig = function() end, hud = function() end, hit = function() end }

	local function setupEsp()
	-- ESP (screen space: box, health, text and everything else line up with the real character) ----
	local espObjs = {}

	local BONES_R15 = {
		{ "Head", "UpperTorso", 1 }, { "UpperTorso", "LowerTorso", 1 },
		{ "UpperTorso", "LeftUpperArm", 2 }, { "LeftUpperArm", "LeftLowerArm", 2 }, { "LeftLowerArm", "LeftHand", 2 },
		{ "UpperTorso", "RightUpperArm", 2 }, { "RightUpperArm", "RightLowerArm", 2 }, { "RightLowerArm", "RightHand", 2 },
		{ "LowerTorso", "LeftUpperLeg", 3 }, { "LeftUpperLeg", "LeftLowerLeg", 3 }, { "LeftLowerLeg", "LeftFoot", 3 },
		{ "LowerTorso", "RightUpperLeg", 3 }, { "RightUpperLeg", "RightLowerLeg", 3 }, { "RightLowerLeg", "RightFoot", 3 },
	}
	local BONES_R6 = {
		{ "Head", "Torso", 1 }, { "Torso", "Left Arm", 2 }, { "Torso", "Right Arm", 2 },
		{ "Torso", "Left Leg", 3 }, { "Torso", "Right Leg", 3 },
	}

	local function destroyEsp(o)
		if not o then return end
		for _, k in ipairs({ "hl", "holder", "tracer", "lookLine", "lookDot", "arrow" }) do
			if o[k] then o[k]:Destroy() end
		end
		for _, f in pairs(o.headM) do
			if typeof(f) == "Instance" then f:Destroy() end
		end
		for _, f in ipairs(o.bones) do f:Destroy() end
	end

	local function buildEsp(plr, c)
		local rootPart = c:FindFirstChild("HumanoidRootPart")
		local hum = c:FindFirstChildOfClass("Humanoid")
		if not rootPart or not hum then return nil end
		local o = { char = c, root = rootPart, hum = hum, bones = {} }
		o.hl = create("Highlight", {
			Adornee = c, DepthMode = Enum.HighlightDepthMode.AlwaysOnTop, Enabled = false,
		}, c)
		o.holder = create("Frame", { BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false }, worldLayer)
		o.box = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0 }, o.holder)
		o.boxStroke = stroke(o.box, Color3.new(1, 1, 1), 1)
		o.corners = {}
		for _, a in ipairs({ { 0, 0 }, { 1, 0 }, { 0, 1 }, { 1, 1 } }) do
			for _, h in ipairs({ true, false }) do
				local f = create("Frame", {
					BorderSizePixel = 0, AnchorPoint = Vector2.new(a[1], a[2]),
					Position = UDim2.fromScale(a[1], a[2]), Visible = false,
				}, o.holder)
				table.insert(o.corners, { f = f, h = h })
			end
		end
		o.hpBack = create("Frame", { BackgroundColor3 = Color3.fromRGB(10, 8, 12), BorderSizePixel = 0 }, o.holder)
		o.hpFill = create("Frame", {
			AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), BorderSizePixel = 0,
		}, o.hpBack)
		o.hpGrad = create("UIGradient", { Rotation = 90, Enabled = false }, o.hpFill)
		local function lbl(parent)
			return create("TextLabel", {
				BackgroundTransparency = 1, Text = "", TextColor3 = Color3.new(1, 1, 1),
				TextStrokeColor3 = Color3.new(0, 0, 0),
			}, parent)
		end
		o.name = lbl(o.holder)
		o.name.AnchorPoint = Vector2.new(0.5, 1)
		o.name.Position = UDim2.new(0.5, 0, 0, -2)
		o.hpTxt = lbl(o.holder)
		o.hpTxt.AnchorPoint = Vector2.new(1, 0.5)
		o.hpTxt.TextXAlignment = Enum.TextXAlignment.Right
		o.info = create("Frame", {
			BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 1, 2),
			Size = UDim2.fromOffset(220, 0), AutomaticSize = Enum.AutomaticSize.Y,
		}, o.holder)
		create("UIListLayout", { HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }, o.info)
		o.weapon, o.ammo, o.dist = lbl(o.info), lbl(o.info), lbl(o.info)
		o.weapon.LayoutOrder, o.ammo.LayoutOrder, o.dist.LayoutOrder = 1, 2, 3

		o.tracer = create("Frame", {
			BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0.5), Visible = false,
		}, worldLayer)
		local function sq()
			return create("Frame", { BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Visible = false }, worldLayer)
		end
		o.headM = { h = sq(), v = sq(), circle = sq(), square = sq() }
		round(o.headM.circle)
		corner(o.headM.square, 1)
		o.headM.circleStroke = stroke(o.headM.circle, Color3.new(1, 1, 1), 1)
		o.headM.squareStroke = stroke(o.headM.square, Color3.new(1, 1, 1), 1)
		o.lookLine = sq()
		o.lookDot = sq()
		o.lookDot.Size = UDim2.fromOffset(6, 6)
		round(o.lookDot)
		o.arrow, o.arrowSet = makeArrow(worldLayer, 6)
		return o
	end

	local function hideEsp(o)
		o.hl.Enabled = false
		o.holder.Visible = false
		o.tracer.Visible = false
		o.lookLine.Visible = false
		o.lookDot.Visible = false
		o.arrow.Visible = false
		for _, f in pairs(o.headM) do
			if typeof(f) == "Instance" and f:IsA("GuiObject") then f.Visible = false end
		end
		for _, f in ipairs(o.bones) do f.Visible = false end
	end

	-- 2D box from head top to feet, centered on the root part
	local function projectBox(o)
		local rootPart, hum, c = o.root, o.hum, o.char
		local head = c:FindFirstChild("Head")
		local rp = rootPart.Position
		local top = head and (head.Position + Vector3.new(0, head.Size.Y / 2 + 0.15, 0)) or (rp + Vector3.new(0, 2.7, 0))
		local feetOff = (hum.RigType == Enum.HumanoidRigType.R6) and 3 or (hum.HipHeight + rootPart.Size.Y / 2)
		local bottom = rp - Vector3.new(0, feetOff, 0)
		local t = cam:WorldToViewportPoint(top)
		local b = cam:WorldToViewportPoint(bottom)
		if t.Z <= 0 or b.Z <= 0 then return nil end
		local h = math.max(math.abs(b.Y - t.Y), 6)
		local w = h * 0.55
		local cx = (t.X + b.X) / 2
		return cx - w / 2, math.min(t.Y, b.Y), w, h, Vector2.new(b.X, b.Y)
	end

	local function updateEsp(plr, o, t)
		local S = Settings
		local d = (cam.CFrame.Position - o.root.Position).Magnitude
		if d > S["esp.maxdist"] then
			hideEsp(o)
			return
		end

		-- chams
		o.hl.Enabled = S["esp.highlight"]
		o.hl.FillColor = S["cham.fill"]
		o.hl.FillTransparency = 1 - S["cham.opacity"] / 100
		o.hl.OutlineColor = S["cham.outline"]
		o.hl.OutlineTransparency = S["cham.pulse"] and (0.45 + 0.35 * math.sin(t * 3)) or 0

		local bx, by, bw, bh, feet = projectBox(o)
		local vs = cam.ViewportSize

		-- off-screen arrow
		local rv = cam:WorldToViewportPoint(o.root.Position)
		local offscreen = rv.Z <= 0 or rv.X < 0 or rv.Y < 0 or rv.X > vs.X or rv.Y > vs.Y
		if S["esp.arrows"] and offscreen then
			local center = vs / 2
			local dir = Vector2.new(rv.X, rv.Y) - center
			if rv.Z <= 0 then dir = -dir end
			if dir.Magnitude < 1 then dir = Vector2.new(0, 1) end
			dir = dir.Unit
			local sc = math.min((vs.X / 2 - 30) / math.max(math.abs(dir.X), 1e-3), (vs.Y / 2 - 30) / math.max(math.abs(dir.Y), 1e-3))
			local p = center + dir * sc
			o.arrow.Position = UDim2.fromOffset(p.X, p.Y)
			o.arrow.Rotation = math.deg(math.atan2(dir.Y, dir.X))
			o.arrowSet(Theme.Accent)
			o.arrow.Visible = true
		else
			o.arrow.Visible = false
		end

		if not bx then
			o.holder.Visible = false
			o.tracer.Visible = false
			o.lookLine.Visible = false
			o.lookDot.Visible = false
			for _, f in pairs(o.headM) do
				if typeof(f) == "Instance" and f:IsA("GuiObject") then f.Visible = false end
			end
			for _, f in ipairs(o.bones) do f.Visible = false end
			return
		end

		o.holder.Visible = true
		o.holder.Position = UDim2.fromOffset(bx, by)
		o.holder.Size = UDim2.fromOffset(bw, bh)

		-- box
		local th = S["bars.boxthick"]
		local asCorners = S["bars.boxstyle"] == "Corners"
		local cl = math.clamp(bw * 0.28, 5, 22)
		o.box.Visible = S["esp.box"]
		o.boxStroke.Enabled = not asCorners
		o.boxStroke.Thickness = th
		o.boxStroke.Color = S["bars.boxcolor"]
		o.box.BackgroundColor3 = S["bars.fillcolor"]
		o.box.BackgroundTransparency = S["bars.fillbox"] and (1 - S["bars.fillopacity"] / 100) or 1
		for _, c in ipairs(o.corners) do
			c.f.Visible = S["esp.box"] and asCorners
			c.f.BackgroundColor3 = S["bars.boxcolor"]
			c.f.Size = c.h and UDim2.fromOffset(cl, th) or UDim2.fromOffset(th, cl)
		end

		-- text
		local font, ts = FontMap[S["fmt.font"]] or BODY, S["fmt.size"]
		local tst = S["fmt.outline"] and 0.35 or 1
		for _, l in ipairs({ o.name, o.hpTxt, o.weapon, o.ammo, o.dist }) do
			l.Font, l.TextSize, l.TextColor3, l.TextStrokeTransparency = font, ts, S["fmt.color"], tst
		end
		o.name.Visible = S["esp.names"]
		o.name.Text = plr.DisplayName .. ((S["esp.team"] and sameTeam(plr)) and "  [TEAM]" or "")
		o.name.Size = UDim2.fromOffset(220, ts + 6)
		local tool = o.char:FindFirstChildOfClass("Tool")
		o.weapon.Visible = S["esp.weapon"]
		o.weapon.Text = tool and tool.Name or "None"
		o.ammo.Visible = S["esp.ammo"]
		o.ammo.Text = tool and tostring(tool:GetAttribute("Ammo") or "-") or "-"
		o.dist.Visible = S["esp.distance"]
		o.dist.Text = S["fmt.unit"] == "Meters" and string.format("%d m", math.floor(d * 0.28 + 0.5)) or string.format("%d studs", math.floor(d + 0.5))
		for _, l in ipairs({ o.weapon, o.ammo, o.dist }) do l.Size = UDim2.new(1, 0, 0, ts + 4) end

		-- health
		local hp = math.clamp(o.hum.Health / math.max(o.hum.MaxHealth, 1), 0, 1)
		local hw = S["bars.width"]
		local col = S["bars.low"]:Lerp(S["bars.high"], hp)
		o.hpBack.Visible = S["esp.vhealth"]
		o.hpBack.Size = UDim2.new(0, hw, 1, 0)
		o.hpBack.Position = UDim2.new(0, -4 - hw, 0, 0)
		o.hpFill.Size = UDim2.fromScale(1, hp)
		o.hpGrad.Enabled = S["bars.gradient"]
		o.hpGrad.Color = ColorSequence.new(S["bars.high"], S["bars.low"])
		o.hpFill.BackgroundColor3 = S["bars.gradient"] and Color3.new(1, 1, 1) or col
		o.hpTxt.Visible = S["esp.healthinfo"]
		o.hpTxt.Text = tostring(math.floor(o.hum.Health))
		o.hpTxt.TextColor3 = col
		o.hpTxt.Size = UDim2.fromOffset(34, ts + 2)
		o.hpTxt.Position = UDim2.new(0, -8 - (S["esp.vhealth"] and hw or 0), 1 - hp, 0)

		-- tracer
		if S["tr.enabled"] then
			local origin = Vector2.new(vs.X / 2, vs.Y)
			if S["tr.origin"] == "Center" then origin = vs / 2 elseif S["tr.origin"] == "Top" then origin = Vector2.new(vs.X / 2, 0) end
			o.tracer.Visible = true
			lineBetween(o.tracer, origin, feet, S["tr.thick"], S["tr.color"])
		else
			o.tracer.Visible = false
		end

		-- skeleton
		local sk = S["skel.enabled"]
		local list = o.char:FindFirstChild("UpperTorso") and BONES_R15 or BONES_R6
		local cols = { S["skel.c1"], S["skel.c2"], S["skel.c3"] }
		for idx, bn in ipairs(list) do
			local fr = o.bones[idx]
			if not fr then
				fr = create("Frame", { BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Visible = false }, worldLayer)
				o.bones[idx] = fr
			end
			local p1, p2 = o.char:FindFirstChild(bn[1]), o.char:FindFirstChild(bn[2])
			if sk and p1 and p2 then
				local a = cam:WorldToViewportPoint(p1.Position)
				local c2 = cam:WorldToViewportPoint(p2.Position)
				if a.Z > 0 and c2.Z > 0 then
					lineBetween(fr, Vector2.new(a.X, a.Y), Vector2.new(c2.X, c2.Y), S["skel.thick"], cols[bn[3]])
					fr.Visible = true
				else
					fr.Visible = false
				end
			else
				fr.Visible = false
			end
		end
		for idx = #list + 1, #o.bones do o.bones[idx].Visible = false end

		-- head marker
		local M = o.headM
		local headPart = o.char:FindFirstChild("Head")
		local showHead = false
		if S["head.enabled"] and headPart then
			local v = cam:WorldToViewportPoint(headPart.Position)
			if v.Z > 0 then
				showHead = true
				local px = 4 + S["head.size"] * 2.2
				local ht, hc, shape, fillOn = S["head.thick"], S["head.color"], S["head.shape"], S["head.fill"]
				local pos = UDim2.fromOffset(v.X, v.Y)
				M.h.Position, M.v.Position, M.circle.Position, M.square.Position = pos, pos, pos, pos
				M.h.Visible, M.v.Visible = shape == "Cross", shape == "Cross"
				M.h.BackgroundColor3, M.v.BackgroundColor3 = hc, hc
				M.h.Size, M.v.Size = UDim2.fromOffset(px, ht), UDim2.fromOffset(ht, px)
				M.circle.Visible = shape == "Circle"
				M.circle.Size = UDim2.fromOffset(px, px)
				M.circle.BackgroundColor3 = hc
				M.circle.BackgroundTransparency = fillOn and 0 or 1
				M.circleStroke.Thickness, M.circleStroke.Color = ht, hc
				M.square.Visible = shape == "Square"
				M.square.Size = UDim2.fromOffset(px, px)
				M.square.BackgroundColor3 = hc
				M.square.BackgroundTransparency = fillOn and 0 or 1
				M.squareStroke.Thickness, M.squareStroke.Color = ht, hc
			end
		end
		if not showHead then
			M.h.Visible, M.v.Visible, M.circle.Visible, M.square.Visible = false, false, false, false
		end

		-- look direction
		local lookShown = false
		if S["esp.look"] and headPart then
			local a = cam:WorldToViewportPoint(headPart.Position)
			local b = cam:WorldToViewportPoint(headPart.Position + headPart.CFrame.LookVector * 4)
			if a.Z > 0 and b.Z > 0 then
				lookShown = true
				lineBetween(o.lookLine, Vector2.new(a.X, a.Y), Vector2.new(b.X, b.Y), 1.5, Theme.Accent)
				o.lookDot.Position = UDim2.fromOffset(b.X, b.Y)
				o.lookDot.BackgroundColor3 = Theme.Accent
			end
		end
		o.lookLine.Visible, o.lookDot.Visible = lookShown, lookShown
	end

	local function espStep()
		local S = Settings
		local t = os.clock()
		local want = S["live.esp"] and S["esp.enabled"] and not inLobby()
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= lp then
				local o = espObjs[plr]
				local c, _, ok = alive(plr)
				if o and o.char ~= c then destroyEsp(o); o = nil; espObjs[plr] = nil end
				if want and c and ok then
					if not o then o = buildEsp(plr, c); espObjs[plr] = o end
					if o then
						if sameTeam(plr) and not S["esp.team"] then
							hideEsp(o)
						else
							local okU, errU = pcall(updateEsp, plr, o, t)
							if not okU and not _G.__LilacEspWarned then
								_G.__LilacEspWarned = true
								warn("[Lilac] ESP error: " .. tostring(errU))
							end
						end
					end
				elseif o then
					hideEsp(o)
				end
			end
		end
		for plr, o in pairs(espObjs) do
			if not plr.Parent then destroyEsp(o); espObjs[plr] = nil end
		end
	end
	table.insert(cleanups, function()
		for _, o in pairs(espObjs) do destroyEsp(o) end
		table.clear(espObjs)
	end)

		Steps.esp = espStep
	end
	setupEsp()

	local function setupAim()
	-- targeting -------------------------------------------------------------------------------
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.RespectCanCollide = true
	local filterT = 0
	local function refreshFilter()
		local now = os.clock()
		if now - filterT < 0.2 then return end
		filterT = now
		local list = {}
		for _, pl in ipairs(Players:GetPlayers()) do
			if pl.Character then list[#list + 1] = pl.Character end
		end
		rayParams.FilterDescendantsInstances = list
	end
	local function visibleFrom(pos)
		local origin = cam.CFrame.Position
		return workspace:Raycast(origin, pos - origin, rayParams) == nil
	end

	local TORSO = { "UpperTorso", "Torso", "HumanoidRootPart" }
	local EXTRA = {
		"HumanoidRootPart", "LowerTorso", "LeftUpperArm", "RightUpperArm", "LeftUpperLeg", "RightUpperLeg",
		"Left Arm", "Right Arm", "Left Leg", "Right Leg",
	}
	local function firstOf(c, names)
		for _, n in ipairs(names) do
			local p = c:FindFirstChild(n)
			if p and p:IsA("BasePart") then return p end
		end
		return nil
	end
	local function partList(c, mode)
		local out = {}
		local head = c:FindFirstChild("Head")
		local torso = firstOf(c, TORSO)
		if mode == "Head" then
			if head then out[1] = head end
		elseif mode == "Torso" then
			if torso then out[1] = torso end
		else
			if head then out[#out + 1] = head end
			if torso then out[#out + 1] = torso end
			if mode == "Hitscan" then
				for _, n in ipairs(EXTRA) do
					local p = c:FindFirstChild(n)
					if p and p:IsA("BasePart") and p ~= torso then out[#out + 1] = p end
				end
			end
		end
		return out
	end

	local function pxToDeg(px)
		local vs = cam.ViewportSize
		local focal = (vs.Y / 2) / math.tan(math.rad(cam.FieldOfView) / 2)
		return math.deg(math.atan(px / focal))
	end

	local function angleTo(ray, pos)
		local dir = pos - cam.CFrame.Position
		if dir.Magnitude < 0.01 then return 180 end
		return math.deg(math.acos(math.clamp(ray:Dot(dir.Unit), -1, 1)))
	end

	-- p = "aim" or "rage"; fovDeg = max angle from the crosshair
	local function findTarget(p, fovDeg)
		local S = Settings
		refreshFilter()
		local ref = aimRef()
		local ray = cam:ViewportPointToRay(ref.X, ref.Y).Direction.Unit
		local camPos = cam.CFrame.Position
		local maxD = S[p .. ".maxdist"]
		local pred = S[p .. ".pred"] or S["aim.pred"] or 0
		local mode = S[p .. ".bone"]
		local prio = S[p .. ".priority"]
		if p == "silent" and mode == "Closest" then mode = "Hitscan" end
		if p == "silent" and type(S["silent.headchance"]) == "number" then
			if math.random(1, 100) <= S["silent.headchance"] then mode = "Head" end
		end
		local best, bestScore, bestPlr
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= lp then
				local c, hum, ok = alive(plr)
				if ok and targetOk(plr, c, hum, p) then
					local chosen, chosenAng
					for _, part in ipairs(partList(c, mode)) do
						local pos = part.Position + part.AssemblyLinearVelocity * pred
						local dist = (pos - camPos).Magnitude
						if dist <= maxD then
							local ang = angleTo(ray, pos)
							if ang <= fovDeg and ((not S[p .. ".wall"]) or visibleFrom(part.Position)) then
								if mode == "Hitscan" then
									chosen, chosenAng = part, ang
									break
								end
								if not chosenAng or ang < chosenAng then chosen, chosenAng = part, ang end
							end
						end
					end
					if chosen then
						local score
						if prio == "Distance" then score = (chosen.Position - camPos).Magnitude
						elseif prio == "Lowest HP" then score = hum.Health
						elseif prio == "Highest HP" then score = -hum.Health
						else score = chosenAng end
						if not bestScore or score < bestScore then best, bestScore, bestPlr = chosen, score, plr end
					end
				end
			end
		end
		return best, bestPlr
	end

	local function stillValid(part, plr, p, fovDeg)
		if not part or not part.Parent or not plr or plr.Parent ~= Players then return false end
		local c, hum, ok = alive(plr)
		if not ok or part.Parent ~= c or not targetOk(plr, c, hum, p) then return false end
		local ref = aimRef()
		local ray = cam:ViewportPointToRay(ref.X, ref.Y).Direction.Unit
		if angleTo(ray, part.Position) > fovDeg * 1.5 then return false end
		if (part.Position - cam.CFrame.Position).Magnitude > Settings[p .. ".maxdist"] then return false end
		if Settings[p .. ".wall"] then
			refreshFilter()
			if not visibleFrom(part.Position) then return false end
		end
		return true
	end

	-- aimbot + ragebot: rotates the view toward the target relative to the crosshair/cursor.
	-- Works whether your game's camera keeps our rotation or recomputes it every frame.
	-- Packed into one table so this scope stays under Luau's ~200 local-register limit.
	local AS = { lastAim = os.clock(), aimF = 0, lastBase = nil, lastSet = nil, sticky = nil, stickyPlr = nil, prevTarget = nil, lastFire = 0, candPart = nil, candT = 0 }

	local function aimStep(which)
		local S = Settings
		if S["aim.sync"] ~= which then return end
		local nowT = os.clock()
		local dtA = math.min(nowT - AS.lastAim, 0.1)
		AS.lastAim = nowT

		local p
		if combatAllowed() and not typing() and not fc.on and not inLobby() then
			if lilacFullGame and S["rage.enabled"] and modeActive("rage") then p = "rage"
			elseif lilacFullGame and S["silent.enabled"] and modeActive("silent") then p = "silent"
			elseif S["aim.enabled"] and modeActive("aim") then p = "aim" end
		end
		if not p then
			AS.sticky, AS.stickyPlr, AS.prevTarget = nil, nil, nil
			AS.aimF, AS.lastBase, AS.lastSet, AS.candT, AS.candPart = 0, nil, nil, 0, nil
			Track.part, Track.plr, Track.mode = nil, nil, nil
			return
		end

		local fovDeg = p == "rage" and S["rage.fov"] or pxToDeg(p == "silent" and S["silent.fov"] or S["fov.size"])
		local target, plr
		if p == "aim" and S["aim.sticky"] and stillValid(AS.sticky, AS.stickyPlr, p, fovDeg) then
			target, plr = AS.sticky, AS.stickyPlr
		elseif p == "silent" and stillValid(AS.sticky, AS.stickyPlr, "silent", fovDeg) then
			target, plr = AS.sticky, AS.stickyPlr
		else
			-- map silent settings into findTarget keys via temporary aliases
			if p == "silent" then
				S["silent.bone"] = S["silent.bone"]
				S["silent.pred"] = S["aim.pred"] or 0
			end
			target, plr = findTarget(p == "silent" and "silent" or p, fovDeg)
			-- reaction delay for silent / aim
			local reactMs = p == "silent" and (S["silent.reaction"] or 0) or (S["aim.reaction"] or 0)
			if reactMs > 0 and target then
				if target ~= AS.prevTarget then
					AS.candT = AS.candT or 0
					if (AS.candPart ~= target) then
						AS.candPart, AS.candT = target, nowT
						target, plr = AS.sticky, AS.stickyPlr
					elseif (nowT - AS.candT) * 1000 < reactMs then
						target, plr = AS.sticky, AS.stickyPlr
					end
				end
			end
			if p == "aim" or p == "silent" then AS.sticky, AS.stickyPlr = target, plr end
		end
		if target ~= AS.prevTarget then AS.aimF = 0 end
		AS.prevTarget = target
		Track.part, Track.plr, Track.mode = target, plr, target and p or nil

		if not target then
			AS.lastBase, AS.lastSet, AS.aimF = nil, nil, 0
			return
		end

		local ref, centered = aimRef()
		local cf = cam.CFrame
		local pred = S[p .. ".pred"] or S["aim.pred"] or 0
		local aimPos = target.Position + target.AssemblyLinearVelocity * pred
		if p == "aim" and (S["aim.humanize"] or 0) > 0 then
			local hz = S["aim.humanize"] * 0.15
			aimPos += Vector3.new(
				math.noise(nowT * 2.1, 1.3, 0), math.noise(nowT * 1.7, 5.1, 0), math.noise(nowT * 2.5, 9.7, 0)
			) * hz
		end

		-- Premium aim: yaw/pitch delta → mousemoverel (respects game camera controllers)
		local function wrapAngle(num)
			num = num % math.pi
			num -= num >= (math.pi / 2) and math.pi or 0
			num += num < -(math.pi / 2) and math.pi or 0
			return num
		end

		local silentPure = p == "silent" and (S["silent.smooth"] or 0) <= 0
		local method = (p == "rage" and "Camera") or (S["aim.method"] or "Mouse")
		if p == "silent" and (S["silent.smooth"] or 0) > 0 then
			method = S["aim.method"] or "Mouse"
		end

		if silentPure then
			AS.lastBase, AS.lastSet = cf, cf
		else
			local facing = cf.LookVector
			local newDir = (aimPos - cf.Position)
			if newDir.Magnitude < 1e-4 then
				AS.lastBase, AS.lastSet = cf, cf
			else
				newDir = newDir.Unit
				local dead = (p == "aim") and (S["aim.deadzone"] or 0) or 0
				local angDeg = math.deg(math.acos(math.clamp(facing:Dot(newDir), -1, 1)))
				if dead > 0 and angDeg < dead then
					AS.lastBase, AS.lastSet = cf, cf
				elseif method == "Mouse" and type(mousemoverel) == "function" then
					local diffYaw = wrapAngle(math.atan2(facing.X, facing.Z) - math.atan2(newDir.X, newDir.Z))
					local diffPitch = math.asin(math.clamp(facing.Y, -1, 1)) - math.asin(math.clamp(newDir.Y, -1, 1))
					local moveConst = Vector2.new(1, 0.77) * math.rad(0.5)
					local sens = 1
					pcall(function()
						sens = UserSettings():GetService("UserGameSettings").MouseSensitivity
						if typeof(sens) ~= "number" or sens <= 0 then sens = 1 end
					end)
					local sm = p == "rage" and 1 or math.max(S["aim.smooth"] or 35, 1)
					local xSm = (p == "rage") and 1 or ((S["aim.xsmooth"] or 100) / 100)
					local ySm = (p == "rage") and 1 or ((S["aim.ysmooth"] or 100) / 100)
					local spd = (p == "rage") and 2 or ((S["aim.speed"] or 100) / 100)
					if p == "silent" then
						sm = math.max(S["silent.smooth"] or 12, 1)
						spd = spd * 0.85
					end
					-- map smoothness: low = fast
					local lerp = (sm <= 1) and 1 or math.clamp((100 / sm) * spd * dtA * 10, 0.02, 1)
					local angle = Vector2.new(diffYaw, diffPitch) / (moveConst * sens)
					angle = Vector2.new(angle.X * xSm, angle.Y * ySm) * lerp
					pcall(mousemoverel, angle.X, angle.Y)
					AS.lastBase, AS.lastSet = cf, cam.CFrame
				else
					-- Camera CFrame fallback (and when mousemoverel missing)
					local under = cam:ViewportPointToRay(ref.X, ref.Y).Direction.Unit
					local want = newDir
					local axis = under:Cross(want)
					local angle = math.acos(math.clamp(under:Dot(want), -1, 1))
					local smooth = p == "rage" and 1 or math.max((S["aim.smooth"] or 35) / 10, 0.1)
					if p == "silent" then smooth = math.max((S["silent.smooth"] or 12) / 5, 0.15) end
					local alpha = smooth <= 0.15 and 1 or (1 - math.exp(-dtA * 40 / smooth))
					if axis.Magnitude > 1e-5 and angle > 1e-4 then
						local rot = CFrame.fromAxisAngle(axis.Unit, angle * alpha)
						local newCf = CFrame.new(cf.Position) * rot * (cf - cf.Position)
						if centered then
							newCf = CFrame.lookAt(cf.Position, cf.Position + newCf.LookVector)
						end
						AS.lastBase, AS.lastSet = cf, newCf
						cam.CFrame = newCf
					else
						AS.lastBase, AS.lastSet = cf, cf
					end
				end
			end
		end

		-- silent / rage auto fire
		if p == "silent" and S["silent.autofire"] and nowT - AS.lastFire >= (S["silent.firerate"] or 90) / 1000 then
			local ch = myChar()
			local tool = ch and ch:FindFirstChildOfClass("Tool")
			if tool then
				AS.lastFire = nowT
				tool:Activate()
				task.delay(0.04, function()
					if tool.Parent then tool:Deactivate() end
				end)
			end
		end
		if p == "rage" and S["rage.autofire"] and nowT - AS.lastFire >= S["rage.firerate"] / 1000 then
			local ch = myChar()
			local tool = ch and ch:FindFirstChildOfClass("Tool")
			if tool then
				AS.lastFire = nowT
				tool:Activate()
				task.delay(0.04, function()
					if tool.Parent then tool:Deactivate() end
				end)
			end
		end
	end
	RunService:BindToRenderStep("LilacAimE", Enum.RenderPriority.Camera.Value + 1, function() aimStep("Early") end)
	RunService:BindToRenderStep("LilacAimL", Enum.RenderPriority.Last.Value, function() aimStep("Late") end)
	table.insert(cleanups, function()
		RunService:UnbindFromRenderStep("LilacAimE")
		RunService:UnbindFromRenderStep("LilacAimL")
	end)

	-- FOV circle (always drawn, menu open or not) --------------------------------------------
	local fovCircle = create("Frame", {
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Visible = false,
	}, worldLayer)
	round(fovCircle)
	local fovStroke = stroke(fovCircle, Color3.new(1, 1, 1), 1.5)

	local function fovStep()
		local S = Settings
		local ref = aimRef()
		local show = (S["aim.enabled"] and S["fov.draw"] and Track.mode ~= "rage" and Track.mode ~= "silent")
			or (S["silent.enabled"] and S["silent.drawfov"] and Track.mode == "silent")
		if S["silent.enabled"] and S["silent.drawfov"] and not Menu.open then
			-- also show silent FOV even when no target yet
			if modeActive("silent") then show = true end
		end
		fovCircle.Visible = show
		if not show then return end
		local locked = Track.mode == "aim"
		local col = locked and S["fov.lockcolor"] or S["fov.color"]
		fovCircle.Position = UDim2.fromOffset(ref.X, ref.Y)
		local fr = (Track.mode == "silent" or (S["silent.enabled"] and modeActive("silent") and not (S["aim.enabled"] and modeActive("aim")))) and S["silent.fov"] or S["fov.size"]
		fovCircle.Size = UDim2.fromOffset(fr * 2, fr * 2)
		fovCircle.BackgroundColor3 = col
		fovCircle.BackgroundTransparency = S["fov.fill"] and 0.9 or 1
		fovStroke.Color = col
	end

	-- triggerbot -----------------------------------------------------------------------------
	local trigBusy = false
	local function trigStep()
		local S = Settings
		if not S["trig.enabled"] or trigBusy or Menu.open or typing() or not modeActive("trig") or inLobby() then return end
		local ref = aimRef()
		local ray = cam:ViewportPointToRay(ref.X, ref.Y)
		local params = RaycastParams.new()
		if S["trig.wall"] then
			params.FilterType = Enum.RaycastFilterType.Exclude
			params.FilterDescendantsInstances = { myChar() }
		else
			local list = {}
			for _, pl in ipairs(Players:GetPlayers()) do
				if pl ~= lp and pl.Character then table.insert(list, pl.Character) end
			end
			params.FilterType = Enum.RaycastFilterType.Include
			params.FilterDescendantsInstances = list
		end
		local hit = workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
		if not hit then return end
		local model = hit.Instance:FindFirstAncestorOfClass("Model")
		local plr = model and Players:GetPlayerFromCharacter(model)
		if not plr or plr == lp then return end
		local c, hum, ok = alive(plr)
		local ch = myChar()
		local tool = ch and ch:FindFirstChildOfClass("Tool")
		if ok and tool and targetOk(plr, c, hum, "trig") then
			trigBusy = true
			task.delay(S["trig.delay"] / 1000, function()
				if tool.Parent then
					Track.trigT = os.clock()
					tool:Activate()
					task.wait(0.04)
					if tool.Parent then tool:Deactivate() end
				end
				task.wait(0.08)
				trigBusy = false
			end)
		end
	end

		Steps.fov = fovStep
		Steps.trig = trigStep
	end
	setupAim()

	local function setupHud()
	-- HUD: watermark, keybind list, target info, target line ---------------------------------------
	local hudStep
	do
		local function hexOf(c) return "#" .. c:ToHex() end

		local wm = create("Frame", {
			BackgroundColor3 = Theme.Card,
			BackgroundTransparency = 0.08,
			Position = UDim2.fromOffset(14, 56),
			AutomaticSize = Enum.AutomaticSize.XY,
			Size = UDim2.fromOffset(0, 0),
			BorderSizePixel = 0,
			ZIndex = 20,
		}, hudGui)
		corner(wm, 9)
		local wmStroke = stroke(wm, Theme.Accent, 1, 0.45)
		pad(wm, 6, 12, 6, 12)
		local wmLbl = create("TextLabel", {
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.XY,
			Size = UDim2.fromOffset(0, 0),
			Font = BODY,
			TextSize = 12,
			TextColor3 = Theme.Text,
			RichText = true,
			Text = "",
			ZIndex = 21,
		}, wm)

		local kl = create("Frame", {
			BackgroundColor3 = Theme.Card,
			BackgroundTransparency = 0.1,
			Position = UDim2.new(0, 14, 0.4, 0),
			Size = UDim2.fromOffset(200, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BorderSizePixel = 0,
			ZIndex = 20,
		}, hudGui)
		corner(kl, 10)
		local klStroke = stroke(kl, Theme.Accent, 1, 0.5)
		pad(kl, 6, 10, 6, 10)
		create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2) }, kl)
		local klHead = text(kl, "KEYBINDS", 9, Theme.Muted, BOLD)
		klHead.Size = UDim2.new(1, 0, 0, 14)
		klHead.ZIndex = 21
		klHead.LayoutOrder = 0

		local klDefs = {
			{ "Aimbot", "aim.enabled", "aim" },
			lilacFullGame and { "Silent", "silent.enabled", "silent" } or nil,
			lilacFullGame and { "Ragebot", "rage.enabled", "rage" } or nil,
			{ "Triggerbot", "trig.enabled", "trig" },
			{ "Fly", "mv.fly" }, { "Speed", "mv.speed" }, { "Noclip", "mv.noclip" },
			{ "Inf Jump", "mv.infjump" }, { "Hitbox", "hb.enabled" }, { "ESP", "live.esp" },
		}
		do
			local cleaned = {}
			for _, d in ipairs(klDefs) do if d then table.insert(cleaned, d) end end
			klDefs = cleaned
		end
		local klRows = {}
		for i, d in ipairs(klDefs) do
			local row = create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 16), LayoutOrder = i, ZIndex = 21 }, kl)
			local n = text(row, d[1], 11, Theme.Muted, BODY)
			n.Size = UDim2.new(0.5, 0, 1, 0)
			n.ZIndex = 22
			local s = text(row, "", 10, Theme.Muted, LIGHT, Enum.TextXAlignment.Right)
			s.Size = UDim2.new(0.5, 0, 1, 0)
			s.Position = UDim2.fromScale(0.5, 0)
			s.ZIndex = 22
			klRows[i] = { row = row, name = n, state = s, def = d }
		end

		local al = create("Frame", {
			BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -14, 0, isMobile and 116 or 56), Size = UDim2.fromOffset(220, 0),
			AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 20,
		}, hudGui)
		create("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Right, Padding = UDim.new(0, 2),
		}, al)
		local alRows = {}
		for _, d in ipairs({
			{ "Aimbot", "aim.enabled" }, { "Silent", "silent.enabled" }, { "Ragebot", "rage.enabled" }, { "Triggerbot", "trig.enabled" }, { "ESP", "live.esp" },
			{ "Fly", "mv.fly" }, { "Speed", "mv.speed" }, { "Float", "mv.float" }, { "Noclip", "mv.noclip" },
			{ "Inf Jump", "mv.infjump" }, { "Bhop", "mv.bhop" }, { "Hitbox", "hb.enabled" }, { "Freecam", "fc.enabled" },
			{ "Fullbright", "world.fullbright" }, { "No Fog", "world.nofog" },
		}) do
			local l = create("TextLabel", {
				BackgroundColor3 = Theme.Card, BackgroundTransparency = 0.25, BorderSizePixel = 0,
				AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 18), Font = BODY, TextSize = 12,
				TextColor3 = Theme.Accent, Text = d[1], Visible = false, ZIndex = 21,
			}, al)
			pad(l, 0, 8, 0, 8)
			table.insert(alRows, { l = l, key = d[2] })
		end

		local tp = create("Frame", {
			BackgroundColor3 = Theme.Card,
			BackgroundTransparency = 0.08,
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -150),
			Size = UDim2.fromOffset(240, 52),
			BorderSizePixel = 0,
			Visible = false,
			ZIndex = 20,
		}, hudGui)
		corner(tp, 10)
		local tpStroke = stroke(tp, Theme.Accent, 1, 0.3)
		local tpName = text(tp, "", 12, Theme.Text, BODY)
		tpName.Position = UDim2.fromOffset(12, 5)
		tpName.Size = UDim2.new(1, -24, 0, 18)
		tpName.ZIndex = 21
		local tpInfo = text(tp, "", 10, Theme.Muted, LIGHT, Enum.TextXAlignment.Right)
		tpInfo.Position = UDim2.fromOffset(12, 5)
		tpInfo.Size = UDim2.new(1, -24, 0, 18)
		tpInfo.ZIndex = 21
		local tpBack = create("Frame", {
			BackgroundColor3 = Theme.Off, BorderSizePixel = 0,
			Position = UDim2.fromOffset(12, 32), Size = UDim2.new(1, -24, 0, 8), ZIndex = 21,
		}, tp)
		round(tpBack)
		local tpFill = create("Frame", { BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = 22 }, tpBack)
		round(tpFill)

		local tline = create("Frame", {
			BackgroundColor3 = Theme.Accent,
			BackgroundTransparency = 0.3,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Visible = false,
			ZIndex = 3,
		}, worldLayer)

		local lastSlow = 0
		hudStep = function()
			local S = Settings
			local now = os.clock()
			wm.Visible = S["vis.watermark"]
			kl.Visible = S["vis.keylist"]

			if now - lastSlow > 0.2 then
				lastSlow = now
				local pingTxt = "-"
				local okP, pv = pcall(function() return Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
				if okP and pv then pingTxt = tostring(math.floor(pv + 0.5)) end
				local ac = hexOf(Theme.Accent)
				wmLbl.Text = string.format(
					'<font color="%s">Lilac</font>  |  %s  |  %d fps  |  %s ms',
					ac, player.DisplayName, math.floor(fpsSmooth + 0.5), pingTxt
				)
				wmStroke.Color = Theme.Accent
				klStroke.Color = Theme.Accent
				tpStroke.Color = Theme.Accent
				tline.BackgroundColor3 = Theme.Accent
				al.Visible = S["vis.arraylist"]
				for _, r in ipairs(alRows) do
					r.l.Visible = S[r.key] == true
					r.l.TextColor3 = Theme.Accent
					r.l.LayoutOrder = -#r.l.Text
				end

				for _, r in ipairs(klRows) do
					local d = r.def
					local on = S[d[2]]
					r.row.Visible = on
					if on then
						local p = d[3]
						local stateTxt, active = "ON", true
						if p then
							local mode = S[p .. ".mode"]
							stateTxt = mode == "Always" and "Always" or (mode .. " · " .. prettyKey(S[p .. ".key"]))
							if p == "trig" then active = now - Track.trigT < 0.4 else active = Track.mode == p end
						end
						r.state.Text = stateTxt
						r.state.TextColor3 = active and Theme.Accent or Theme.Muted
						r.name.TextColor3 = active and Theme.Text or Theme.Muted
					end
				end
			end

			-- target info + line
			local part, plr = Track.part, Track.plr
			local showT = part and plr and plr.Parent and part.Parent
			tp.Visible = (showT and S["vis.targethud"]) and true or false
			tline.Visible = false
			if showT then
				local c = plr.Character
				local hum = c and c:FindFirstChildOfClass("Humanoid")
				if hum then
					local hp = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
					tpName.Text = plr.DisplayName
					tpInfo.Text = string.format(
						"%s  ·  %d HP  ·  %d studs", string.upper(Track.mode or ""),
						math.floor(hum.Health), math.floor((part.Position - cam.CFrame.Position).Magnitude)
					)
					tpFill.Size = UDim2.fromScale(hp, 1)
					tpFill.BackgroundColor3 = S["bars.low"]:Lerp(S["bars.high"], hp)
				end
				if S["vis.targetline"] then
					local v = cam:WorldToViewportPoint(part.Position)
					if v.Z > 0 then
						local ref = aimRef()
						tline.Visible = true
						lineBetween(tline, ref, Vector2.new(v.X, v.Y), 1.5)
					end
				end
			end
		end
	end

		Steps.hud = hudStep
	end
	setupHud()

	-- one render-step pass after the camera and the aimbot so everything lines up with the final view
	RunService:BindToRenderStep("LilacVisuals", Enum.RenderPriority.Last.Value + 1, function()
		Steps.esp()
		Steps.fov()
		Steps.trig()
		Steps.hud()
		Steps.hit()
	end)
	table.insert(cleanups, function() RunService:UnbindFromRenderStep("LilacVisuals") end)

	local function setupRest()
	-- hitbox expander (client-side only) ---------------------------------------------------------
	local origSizes = {}
	local function restoreHitboxes()
		for part, o in pairs(origSizes) do
			if part.Parent then part.Size, part.Transparency, part.CanCollide = o.size, o.trans, o.collide end
		end
		table.clear(origSizes)
	end
	table.insert(cleanups, restoreHitboxes)

	-- value overrides that restore themselves --------------------------------------------------
	local ovr = {}
	local function ovSet(group, inst, prop, val)
		local g = ovr[group]
		if not g then g = {}; ovr[group] = g end
		local found
		for _, e in ipairs(g) do
			if e.inst == inst and e.prop == prop then found = e; break end
		end
		if not found then g[#g + 1] = { inst = inst, prop = prop, orig = inst[prop] } end
		inst[prop] = val
	end
	local function ovRestore(group)
		local g = ovr[group]
		if not g then return end
		for _, e in ipairs(g) do
			pcall(function() e.inst[e.prop] = e.orig end)
		end
		ovr[group] = nil
	end
	table.insert(cleanups, function()
		for grp in pairs(ovr) do ovRestore(grp) end
	end)


	-- post processing, weather, freecam, hit effects ----------------------------------------------
	local CAS = game:GetService("ContextActionService")
	local fxObjs = {}
	local function fxGet(class, name)
		local o = fxObjs[name]
		if not o or not o.Parent then
			o = Instance.new(class)
			o.Name = name
			o.Parent = Lighting
			fxObjs[name] = o
		end
		return o
	end
	local function fxDrop(name)
		local o = fxObjs[name]
		if o then o:Destroy(); fxObjs[name] = nil end
	end
	table.insert(cleanups, function()
		for n in pairs(fxObjs) do fxDrop(n) end
	end)

	local function fxStep()
		local S = Settings
		local want = (Menu.open and S["fx.menublur"]) and 18 or 0
		local blur = fxObjs["LilacBlur"]
		if want > 0 then blur = fxGet("BlurEffect", "LilacBlur") end
		if blur then
			blur.Size = blur.Size + (want - blur.Size) * 0.2
			if want == 0 and blur.Size < 0.2 then fxDrop("LilacBlur") end
		end
		if S["fx.bloom"] then
			local b = fxGet("BloomEffect", "LilacBloom")
			b.Intensity, b.Size, b.Threshold = S["fx.bloomint"], 24, 0.9
		else
			fxDrop("LilacBloom")
		end
		if S["fx.cc"] then
			local c = fxGet("ColorCorrectionEffect", "LilacCC")
			c.Saturation, c.Contrast, c.Brightness, c.TintColor = S["fx.sat"], S["fx.con"], S["fx.bri"], S["fx.tint"]
		else
			fxDrop("LilacCC")
		end
		if S["fx.rays"] then
			local r = fxGet("SunRaysEffect", "LilacRays")
			r.Intensity, r.Spread = S["fx.raysint"], 0.8
		else
			fxDrop("LilacRays")
		end
		if S["fx.atmo"] then
			local atm = Lighting:FindFirstChildOfClass("Atmosphere") or fxGet("Atmosphere", "LilacAtmo")
			ovSet("atmo", atm, "Density", S["fx.density"])
			ovSet("atmo", atm, "Haze", S["fx.haze"])
			ovSet("atmo", atm, "Color", S["fx.atmocolor"])
		elseif ovr.atmo then
			ovRestore("atmo")
			fxDrop("LilacAtmo")
		end
	end

	local weatherPart, weatherEm, weatherKind
	local function weatherStep()
		local kind = Settings["fx.weather"]
		if kind == "None" then
			if weatherPart then weatherPart:Destroy(); weatherPart, weatherEm, weatherKind = nil, nil, nil end
			return
		end
		if not weatherPart or not weatherPart.Parent or weatherKind ~= kind then
			if weatherPart then weatherPart:Destroy() end
			weatherPart = create("Part", {
				Name = "LilacWeather", Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false,
				Transparency = 1, Size = Vector3.new(70, 1, 70),
			}, workspace)
			weatherEm = create("ParticleEmitter", { EmissionDirection = Enum.NormalId.Bottom }, weatherPart)
			if kind == "Rain" then
				weatherEm.Speed = NumberRange.new(90, 110)
				weatherEm.Lifetime = NumberRange.new(0.6, 0.8)
				weatherEm.Size = NumberSequence.new(0.18)
				weatherEm.Transparency = NumberSequence.new(0.35)
				weatherEm.Orientation = Enum.ParticleOrientation.VelocityParallel
				weatherEm.Acceleration = Vector3.new(0, -40, 0)
				weatherEm.Color = ColorSequence.new(Color3.fromRGB(170, 190, 230))
				weatherEm.LightEmission = 0.2
			else
				weatherEm.Speed = NumberRange.new(6, 10)
				weatherEm.Lifetime = NumberRange.new(5, 7)
				weatherEm.Size = NumberSequence.new(0.28)
				weatherEm.Transparency = NumberSequence.new(0.15)
				weatherEm.SpreadAngle = Vector2.new(25, 25)
				weatherEm.RotSpeed = NumberRange.new(-60, 60)
				weatherEm.Color = ColorSequence.new(Color3.new(1, 1, 1))
				weatherEm.LightEmission = 0.5
			end
			weatherKind = kind
		end
		weatherEm.Rate = Settings["fx.weatherrate"] * (kind == "Rain" and 4 or 1.5)
		weatherPart.CFrame = CFrame.new(cam.CFrame.Position + Vector3.new(0, 40, 0))
	end
	table.insert(cleanups, function()
		if weatherPart then weatherPart:Destroy() end
	end)

	-- freecam
	connect(UserInputService.InputChanged, function(i)
		if not fc.on then return end
		if i.UserInputType == Enum.UserInputType.MouseMovement then
			if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
				fc.yaw -= i.Delta.X * 0.0035
				fc.pitch = math.clamp(fc.pitch - i.Delta.Y * 0.0035, -1.5, 1.5)
			end
		elseif i.KeyCode == Enum.KeyCode.Thumbstick1 then
			fc.s1 = Vector2.new(i.Position.X, i.Position.Y)
		elseif i.KeyCode == Enum.KeyCode.Thumbstick2 then
			fc.s2 = Vector2.new(i.Position.X, i.Position.Y)
		end
	end)
	local function fcStop()
		if not fc.on then return end
		fc.on = false
		cam.CameraType = fc.prevType or Enum.CameraType.Custom
		CAS:UnbindAction("LilacFreecam")
		fc.s1, fc.s2 = Vector2.zero, Vector2.zero
	end
	table.insert(cleanups, fcStop)
	local function fcStep(dt)
		local S = Settings
		if not S["fc.enabled"] then
			fcStop()
			return
		end
		local U = UserInputService
		if not fc.on then
			fc.on = true
			fc.prevType = cam.CameraType
			fc.pos = cam.CFrame.Position
			fc.pitch, fc.yaw = cam.CFrame:ToOrientation()
			cam.CameraType = Enum.CameraType.Scriptable
			CAS:BindActionAtPriority("LilacFreecam", function() return Enum.ContextActionResult.Sink end, false, 3000,
				Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D, Enum.KeyCode.E, Enum.KeyCode.Q,
				Enum.KeyCode.Space, Enum.KeyCode.LeftShift, Enum.KeyCode.Thumbstick1)
		end
		fc.yaw -= fc.s2.X * dt * 2.5
		fc.pitch = math.clamp(fc.pitch + fc.s2.Y * dt * 2.5, -1.5, 1.5)
		local cf0 = CFrame.new(fc.pos) * CFrame.Angles(0, fc.yaw, 0) * CFrame.Angles(fc.pitch, 0, 0)
		local mv = Vector3.zero
		if not typing() and not Menu.open then
			if U:IsKeyDown(Enum.KeyCode.W) then mv += Vector3.new(0, 0, -1) end
			if U:IsKeyDown(Enum.KeyCode.S) then mv += Vector3.new(0, 0, 1) end
			if U:IsKeyDown(Enum.KeyCode.A) then mv += Vector3.new(-1, 0, 0) end
			if U:IsKeyDown(Enum.KeyCode.D) then mv += Vector3.new(1, 0, 0) end
			if U:IsKeyDown(Enum.KeyCode.E) then mv += Vector3.new(0, 1, 0) end
			if U:IsKeyDown(Enum.KeyCode.Q) then mv += Vector3.new(0, -1, 0) end
			mv += Vector3.new(fc.s1.X, 0, -fc.s1.Y)
		end
		if mv.Magnitude > 1 then mv = mv.Unit end
		local speed = S["fc.speed"] * (U:IsKeyDown(Enum.KeyCode.LeftShift) and 3 or 1)
		fc.pos += (cf0:VectorToWorldSpace(Vector3.new(mv.X, 0, mv.Z)) + Vector3.new(0, mv.Y, 0)) * speed * dt
		cam.CFrame = CFrame.new(fc.pos) * CFrame.Angles(0, fc.yaw, 0) * CFrame.Angles(fc.pitch, 0, 0)
	end

	-- hit effects: damage text, ring, slash, notifier
	local fxLayer = create("Frame", {
		BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 30, Active = false,
	}, hudGui)
	local hitFX = {}
	local function addHit(pos, dmg, plr)
		local S = Settings
		local col = S["hfx.color"]
		local e = { pos = pos, born = os.clock() }
		if S["hfx.text"] then
			e.text = create("TextLabel", {
				BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(100, 20),
				Font = BOLD, TextSize = 18, TextColor3 = col, TextStrokeTransparency = 0.4,
				Text = tostring(math.floor(dmg + 0.5)), ZIndex = 31,
			}, fxLayer)
		end
		if S["hfx.ring"] then
			e.ring = create("Frame", {
				BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(10, 10), ZIndex = 31,
			}, fxLayer)
			round(e.ring)
			e.ringStroke = stroke(e.ring, col, 2)
		end
		if S["hfx.slash"] then
			e.slash = create("Frame", {
				BackgroundColor3 = col, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5),
				Size = UDim2.fromOffset(0, 2), Rotation = -35, ZIndex = 31,
			}, fxLayer)
		end
		if S["hfx.notify"] then notify("Hit", plr.DisplayName .. "  -" .. math.floor(dmg + 0.5)) end
		table.insert(hitFX, e)
	end
	hitStep = function()
		local now = os.clock()
		for i = #hitFX, 1, -1 do
			local e = hitFX[i]
			local a = (now - e.born) / 0.9
			if a >= 1 then
				for _, k in ipairs({ "text", "ring", "slash" }) do
					if e[k] then e[k]:Destroy() end
				end
				table.remove(hitFX, i)
			else
				local v = cam:WorldToViewportPoint(e.pos)
				local vis = v.Z > 0
				local p = UDim2.fromOffset(v.X, v.Y)
				if e.text then
					e.text.Visible = vis
					e.text.Position = UDim2.fromOffset(v.X, v.Y - 30 * a)
					e.text.TextTransparency = a * a
					e.text.TextStrokeTransparency = 0.4 + 0.6 * a * a
				end
				if e.ring then
					e.ring.Visible = vis
					e.ring.Position = p
					local s = 10 + 50 * a
					e.ring.Size = UDim2.fromOffset(s, s)
					e.ringStroke.Transparency = a
				end
				if e.slash then
					e.slash.Visible = vis
					e.slash.Position = p
					e.slash.Size = UDim2.fromOffset(80 * math.sin(math.min(a * 2, 1) * math.pi / 2), 2)
					e.slash.BackgroundTransparency = a
				end
			end
		end
	end
	table.insert(cleanups, function()
		for _, e in ipairs(hitFX) do
			for _, k in ipairs({ "text", "ring", "slash" }) do
				if e[k] then e[k]:Destroy() end
			end
		end
		fxLayer:Destroy()
	end)

	local hpLast = setmetatable({}, { __mode = "k" })
	local function hitWatch()
		local S = Settings
		if not (S["hfx.text"] or S["hfx.ring"] or S["hfx.slash"] or S["hfx.notify"]) then
			table.clear(hpLast)
			return
		end
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= lp then
				local c, hum = alive(plr)
				if hum then
					local prev = hpLast[hum]
					if prev and hum.Health < prev - 0.5 and (S["hfx.source"] == "Any Damage" or Track.plr == plr) then
						local head = c:FindFirstChild("Head") or c:FindFirstChild("HumanoidRootPart")
						if head then addHit(head.Position, prev - hum.Health, plr) end
					end
					hpLast[hum] = hum.Health
				end
			end
		end
	end

	-- movement ---------------------------------------------------------------------------------
	local flyVel
	local function stopFly()
		if flyVel then flyVel:Destroy(); flyVel = nil end
	end
	table.insert(cleanups, stopFly)

	connect(UserInputService.JumpRequest, function()
		if Settings["mv.infjump"] then
			local h = myHum()
			if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
		end
	end)

	local noclipSaved = {}
	connect(RunService.Stepped, function()
		local c = myChar()
		if Settings["mv.noclip"] and c then
			for _, p in ipairs(c:GetDescendants()) do
				if p:IsA("BasePart") and p.CanCollide then
					noclipSaved[p] = true
					p.CanCollide = false
				end
			end
		elseif next(noclipSaved) then
			for p in pairs(noclipSaved) do
				if p.Parent then p.CanCollide = true end
			end
			table.clear(noclipSaved)
		end
	end)

	-- anti-aim state
	local aaSaved, aaAng, aaFlip = nil, 0, false
	table.insert(cleanups, function()
		local h = myHum()
		if h and aaSaved ~= nil then h.AutoRotate = aaSaved end
	end)

	connect(lp.Idled, function()
		if Settings["misc.antiafk"] then
			local ok, vu = pcall(function() return game:GetService("VirtualUser") end)
			if ok and vu then
				vu:CaptureController()
				vu:ClickButton2(Vector2.new())
			end
		end
	end)

	-- main feature loop --------------------------------------------------------------------------
	connect(RunService.Heartbeat, function(dt)
		local S = Settings

		-- mobile on-screen buttons
		if isMobile then
			local show = (not Menu.open) and S["mob.buttons"]
			local sz = S["mob.size"]
			for p, tb in pairs(touchBtns) do
				local b = tb.b
				b.Visible = show and (S[p .. ".enabled"] == true) and S[p .. ".mode"] ~= "Always"
				b.Size = UDim2.fromOffset(sz, sz)
				b.Position = UDim2.new(1, -24 - (tb.idx - 1) * (sz + 10), 1, -170)
				local on = toggled[p] or touchHeld[p]
				b.BackgroundColor3 = on and Theme.Accent or Theme.Card
				b.BackgroundTransparency = 1 - S["mob.opacity"] / 100
				b.TextColor3 = on and Color3.fromRGB(24, 10, 28) or Theme.Text
			end
		end

		-- hitboxes
		if S["hb.enabled"] then
			for _, plr in ipairs(Players:GetPlayers()) do
				if plr ~= lp and (S["hb.team"] or not sameTeam(plr)) then
					local c, _, ok = alive(plr)
					local r = c and c:FindFirstChild("HumanoidRootPart")
					if r and ok then
						origSizes[r] = origSizes[r] or { size = r.Size, trans = r.Transparency, collide = r.CanCollide }
						r.Size = Vector3.new(S["hb.size"], S["hb.size"], S["hb.size"])
						r.Transparency, r.CanCollide = S["hb.trans"], false
					end
				end
			end
		elseif next(origSizes) then
			restoreHitboxes()
		end

		local hum, rootPart = myHum(), myRoot()
		if hum then
			if S["mv.speed"] and S["mv.speedmode"] == "WalkSpeed" then
				ovSet("speed", hum, "WalkSpeed", S["mv.speedval"])
			elseif ovr.speed then
				ovRestore("speed")
			end
			if S["mv.speed"] and S["mv.speedmode"] == "CFrame" and rootPart then
				rootPart.CFrame += hum.MoveDirection * math.max(S["mv.speedval"] - 16, 0) * dt
			end
			if S["mv.float"] and rootPart then
				ovSet("float", workspace, "Gravity", 0)
				local v = rootPart.AssemblyLinearVelocity
				rootPart.AssemblyLinearVelocity = Vector3.new(v.X, 0, v.Z)
			elseif ovr.float then
				ovRestore("float")
			end
			if S["mv.jump"] then
				ovSet("jump", hum, "UseJumpPower", true)
				ovSet("jump", hum, "JumpPower", S["mv.jumpval"])
			elseif ovr.jump then
				ovRestore("jump")
			end
			local jumpHeld = UserInputService:IsKeyDown(Enum.KeyCode.Space)
				or bindDown("ButtonA")
			if S["mv.bhop"] and not typing() and jumpHeld then hum.Jump = true end
		end

		-- fly (works with WASD, controller stick and the mobile thumbstick through MoveDirection)
		if S["mv.fly"] and rootPart and hum then
			if not flyVel or flyVel.Parent ~= rootPart then
				stopFly()
				flyVel = create("BodyVelocity", { MaxForce = Vector3.new(1e5, 1e5, 1e5), Velocity = Vector3.zero }, rootPart)
			end
			local dir = hum.MoveDirection
			local flat = Vector3.new(cam.CFrame.LookVector.X, 0, cam.CFrame.LookVector.Z)
			if flat.Magnitude > 0.01 and dir.Magnitude > 0.01 then
				local fwd = dir:Dot(flat.Unit)
				dir += Vector3.new(0, cam.CFrame.LookVector.Y * fwd, 0)
			end
			if not typing() then
				if UserInputService:IsKeyDown(Enum.KeyCode.Space) or bindDown("ButtonA") or hum.Jump then dir += Vector3.yAxis end
				if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or bindDown("ButtonB") then dir -= Vector3.yAxis end
			end
			flyVel.Velocity = dir.Magnitude > 0.05 and dir.Unit * S["mv.flyspeed"] or Vector3.zero
		else
			stopFly()
		end

		-- anti-aim (ragebot)
		local aaMode = S["rage.enabled"] and S["rage.aa"] or "Off"
		if aaMode ~= "Off" and rootPart and hum and hum.Health > 0 then
			if aaSaved == nil then aaSaved = hum.AutoRotate end
			hum.AutoRotate = false
			local look = cam.CFrame.LookVector
			local base = math.atan2(-look.X, -look.Z)
			local yaw
			if aaMode == "Spin" then
				aaAng = (aaAng + dt * math.rad(S["rage.aaspeed"])) % (math.pi * 2)
				yaw = aaAng
			elseif aaMode == "Jitter" then
				aaFlip = not aaFlip
				yaw = base + (aaFlip and 1 or -1) * math.rad(S["rage.aajit"])
			else
				yaw = base + math.pi
			end
			rootPart.CFrame = CFrame.new(rootPart.Position) * CFrame.Angles(0, yaw, 0)
		elseif aaSaved ~= nil then
			if hum then hum.AutoRotate = aaSaved end
			aaSaved = nil
		end

		-- world
		if S["amb.override"] then ovSet("clock", Lighting, "ClockTime", S["amb.clock"]) elseif ovr.clock then ovRestore("clock") end
		if S["world.fullbright"] then
			ovSet("fb", Lighting, "Brightness", 2)
			ovSet("fb", Lighting, "Ambient", Color3.fromRGB(178, 178, 178))
			ovSet("fb", Lighting, "OutdoorAmbient", Color3.fromRGB(178, 178, 178))
			ovSet("fb", Lighting, "GlobalShadows", false)
		elseif ovr.fb then
			ovRestore("fb")
		end
		if S["world.nofog"] then
			ovSet("fog", Lighting, "FogEnd", 1e6)
			ovSet("fog", Lighting, "FogStart", 1e6 - 1)
			local atm = Lighting:FindFirstChildOfClass("Atmosphere")
			if atm then ovSet("fog", atm, "Density", 0) end
		elseif ovr.fog then
			ovRestore("fog")
		end
		if S["world.fovon"] then ovSet("fov", cam, "FieldOfView", S["world.fov"]) elseif ovr.fov then ovRestore("fov") end

		fxStep()
		weatherStep()
		fcStep(dt)
		hitWatch()
	end)

		Steps.hit = hitStep
	end
	setupRest()


-- export combat state for premium hooks
shared.LilacTrack = Track
shared.LilacInLobby = inLobby

end -- features scope

--------------------------------------------------------------------------
-- Lilac Premium combat engine (game-aware silent + rage)
-- Uses camera/mouse assist everywhere; upgrades to shot redirection when
-- the place exposes fighter remotes / enum modules.
--------------------------------------------------------------------------
do
	local Premium = {
		silentHook = false,
		rageOn = false,
	}

	local function tryRequire(path)
		local ok, mod = pcall(require, path)
		return ok and mod or nil
	end

	local function getFighterModules()
		local rs = game:GetService("ReplicatedStorage")
		local lp = Players.LocalPlayer
		local mods = rs:FindFirstChild("Modules")
		local remotes = rs:FindFirstChild("Remotes")
		if not mods or not remotes then return nil end
		local util = tryRequire(mods:FindFirstChild("Utility"))
		local enums = tryRequire(mods:FindFirstChild("EnumLibrary"))
		local useItem = remotes:FindFirstChild("Replication")
		useItem = useItem and useItem:FindFirstChild("Fighter")
		useItem = useItem and useItem:FindFirstChild("UseItem")
		local scripts = lp and (lp:FindFirstChild("PlayerScripts") or lp:FindFirstChild("PlayerScripts "))
		local fctrl = scripts and scripts:FindFirstChild("Controllers")
		fctrl = fctrl and fctrl:FindFirstChild("FighterController")
		fctrl = fctrl and tryRequire(fctrl)
		if not (enums and useItem) then return nil end
		return { util = util, enums = enums, useItem = useItem, fighter = fctrl }
	end

	-- Install once: redirect fire camera data toward silent/rage target
	task.spawn(function()
		if not lilacFullGame then return end
		task.wait(1)
		local M = getFighterModules()
		if not M or not hookfunction or not newcclosure then return end
		local enums, remote = M.enums, M.useItem
		if typeof(remote) ~= "Instance" or not remote:IsA("RemoteEvent") then return end
		pcall(function()
			if enums and enums.ToEnum then enums:ToEnum("StartShooting") end
		end)
		local old
		local ok = pcall(function()
			old = hookfunction(remote.FireServer, newcclosure(function(self, ...)
				local args = { ... }
				if Settings["silent.enabled"] or Settings["rage.enabled"] then
					local Tr = shared.LilacTrack
					local lobbyFn = shared.LilacInLobby
					if type(lobbyFn) == "function" and lobbyFn() then
						return old(self, ...)
					end
					local part = Tr and Tr.part
					local mode = Tr and Tr.mode
					local want = (Settings["rage.enabled"] and mode == "rage")
						or (Settings["silent.enabled"] and (mode == "silent" or mode == "aim" or mode == "rage"))
					if want and part and part.Parent and typeof(args[3]) == "table" then
						local origin = workspace.CurrentCamera and workspace.CurrentCamera.CFrame.Position
						if origin then
							local dest = part.Position
							pcall(function()
								dest = dest + part.AssemblyLinearVelocity * (Settings["aim.pred"] or 0)
							end)
							local dir = (dest - origin)
							if dir.Magnitude > 0.01 then
								dir = dir.Unit
								args[3].LookVector = dir
								args[3].lookVector = dir
								args[3].Origin = origin
								args[3].Position = origin
								local cf = CFrame.lookAt(origin, origin + dir)
								args[3].CFrame = cf
								args[3].CameraCFrame = cf
							end
						end
					end
				end
				return old(self, table.unpack(args))
			end))
		end)
		if ok then
			Premium.silentHook = true
			table.insert(cleanups, function()
				pcall(function()
					if old then hookfunction(remote.FireServer, old) end
				end)
			end)
		end
	end)
end


-- module toasts
do
	local names = {
		["aim.enabled"] = "Aimbot", ["silent.enabled"] = "Silent Aim", ["rage.enabled"] = "Ragebot", ["trig.enabled"] = "Triggerbot", ["mv.fly"] = "Fly",
		["mv.speed"] = "Speed", ["mv.float"] = "Float", ["mv.noclip"] = "Noclip", ["hb.enabled"] = "Hitbox",
		["fc.enabled"] = "Freecam", ["world.fullbright"] = "Fullbright", ["live.esp"] = "ESP",
	}
	for k, n in pairs(names) do
		local old = Handlers[k]
		Handlers[k] = function(v)
			if old then old(v) end
			if not bulk and Settings["misc.togglenotify"] then notify(n, v and "Enabled" or "Disabled") end
		end
	end
end

--------------------------------------------------------------------------
-- go
--------------------------------------------------------------------------
bulk = true
for key, h in pairs(Handlers) do h(Settings[key]) end
bulk = false
renderPreview()
updatePreviewVisible()

-- Universal mode: force off full-only combat
if not lilacFullGame then
	Settings["silent.enabled"] = false
	Settings["rage.enabled"] = false
	-- keep them off if a config tries to re-enable
	local prevSilent = Handlers["silent.enabled"]
	local prevRage = Handlers["rage.enabled"]
	Handlers["silent.enabled"] = function(v)
		if prevSilent then prevSilent(false) end
		Settings["silent.enabled"] = false
	end
	Handlers["rage.enabled"] = function(v)
		if prevRage then prevRage(false) end
		Settings["rage.enabled"] = false
	end
end
selectTab("Combat")
setMenuOpen(true)

-- Named config auto-load
do
	Settings["cfg.selected"] = Settings["cfg.selected"] or "default"
	Settings["cfg.autoload"] = Settings["cfg.autoload"] ~= false
	Settings["cfg.autoloadname"] = getAutoloadName()
	listConfigNames()
	if Settings["cfg.autoload"] then
		local name = Settings["cfg.autoloadname"] or "default"
		if loadNamedConfig(name) then
			if not Settings["misc.silentload"] and Settings["misc.loadnotify"] ~= false then
				notify("Auto Load", "Loaded config \"" .. name .. "\"")
			end
		end
	end
	-- configs must not enable full-only modules in universal places
	if not lilacFullGame then
		Settings["silent.enabled"] = false
		Settings["rage.enabled"] = false
	end
end

-- Re-inject after teleport (optional GitHub raw URL)
do
	Settings["misc.tploadurl"] = Settings["misc.tploadurl"] or ""
	local function queueReload()
		if Settings["misc.tpautoload"] == false then return end
		local url = tostring(Settings["misc.tploadurl"] or "")
		if url == "" then return end
		local q = (syn and syn.queue_on_teleport)
			or queue_on_teleport
			or (fluxus and fluxus.queue_on_teleport)
			or queueonteleport
		if type(q) ~= "function" then return end
		local src = string.format(
			"local u=%q; local ok,err=pcall(function() loadstring(game:HttpGet(u))() end); if not ok then warn('[Lilac] TP reload failed',err) end",
			url
		)
		pcall(q, src)
	end
	pcall(function()
		player.OnTeleport:Connect(function(state)
			if state == Enum.TeleportState.Started or state == Enum.TeleportState.InProgress then
				queueReload()
			end
		end)
	end)
	task.defer(queueReload)
end

print("[Lilac Premium] loaded")
if not Settings["misc.silentload"] and Settings["misc.loadnotify"] ~= false and Settings["misc.notify"] ~= false then
	local mode = lilacFullGame and "FULL mode · silent + rage + skins" or "UNIVERSAL mode · aimbot + shared features"
	notify("Lilac Premium", mode .. " · " .. prettyKey(Settings["set.menukey"]) .. " toggles menu")
end


--------------------------------------------------------------------------
-- Lilac Premium · Skin / Cosmetic Changer
-- Activates when the current game exposes item/cosmetic modules.
--------------------------------------------------------------------------
do
	-- Stubs when a host UI framework is not present
	local mainapi = rawget(shared, "Modern") or rawget(_G, "mainapi")
	if type(mainapi) ~= "table" then
		mainapi = {
			MainScreenGui = nil,
			ClickGuiStatus = false,
			Connections = {},
		}
		function mainapi:Clean(conn)
			if typeof(conn) == "RBXScriptConnection" then
				table.insert(self.Connections, conn)
			elseif type(conn) == "function" then
				table.insert(self.Connections, { Disconnect = conn })
			end
		end
		shared.__LilacSkinMainapi = mainapi
	end

	-- Prefer Lilac HUD/playerGui for parenting the cosmetic window
	local function ensureSkinGuiParent()
		if mainapi.MainScreenGui and mainapi.MainScreenGui.Parent then
			return mainapi.MainScreenGui
		end
		local pg = game:GetService("Players").LocalPlayer and game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
		local existing = pg and pg:FindFirstChild("LilacSkinChangerGui")
		if existing then
			mainapi.MainScreenGui = existing
			return existing
		end
		local sg = Instance.new("ScreenGui")
		sg.Name = "LilacSkinChangerGui"
		sg.ResetOnSpawn = false
		sg.IgnoreGuiInset = true
		sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		sg.DisplayOrder = 1500
		sg.Parent = pg
		mainapi.MainScreenGui = sg
		-- fake ClickGui child for makeDraggable second arg
		local click = Instance.new("Frame")
		click.Name = "ClickGui"
		click.BackgroundTransparency = 1
		click.Size = UDim2.fromScale(1, 1)
		click.Parent = sg
		return sg
	end
	ensureSkinGuiParent()

	-- simple drag helper if missing
	if not makeDraggable then
		function makeDraggable(obj, _window)
			local UIS = game:GetService("UserInputService")
			local dragging, dragStart, startPos
			obj.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					dragging = true
					dragStart = input.Position
					startPos = obj.Position
					local ended
					ended = input.Changed:Connect(function()
						if input.UserInputState == Enum.UserInputState.End then
							dragging = false
							if ended then ended:Disconnect() end
						end
					end)
				end
			end)
			UIS.InputChanged:Connect(function(input)
				if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
					local delta = input.Position - dragStart
					obj.Position = UDim2.new(
						startPos.X.Scale, startPos.X.Offset + delta.X,
						startPos.Y.Scale, startPos.Y.Offset + delta.Y
					)
				end
			end)
		end
	end

	-- keep ClickGuiStatus in sync with Lilac menu if present
	task.spawn(function()
		while true do
			task.wait(0.15)
			local ok, open = pcall(function()
				return Menu and Menu.open
			end)
			if ok then
				mainapi.ClickGuiStatus = open == true
			end
		end
	end)


task.spawn(function()

            -- Unlock All module removed
local plrs = game:GetService("Players")
local reps = game:GetService("ReplicatedStorage")
local _http = game:GetService("HttpService")
local collectionService = game:GetService("CollectionService")

local lp = plrs.LocalPlayer
if not lp then return end

local lps = lp:FindFirstChild("PlayerScripts") or lp:WaitForChild("PlayerScripts", 10)
if not lps then return end

local ctrls = lps:FindFirstChild("Controllers") or lps:WaitForChild("Controllers", 10)
local rmods = reps:FindFirstChild("Modules") or reps:WaitForChild("Modules", 10)
if not ctrls or not rmods then return end

local function safeRequireModule(module)
	if not module then return nil end
	local ok, result = pcall(require, module)
	return ok and result or nil
end

local elib = safeRequireModule(rmods:WaitForChild("EnumLibrary", 10))
if elib and elib.WaitForEnumBuilder then
	pcall(function()
		elib:WaitForEnumBuilder()
	end)
end
local clib = safeRequireModule(rmods:WaitForChild("CosmeticLibrary", 10))
local ilib = safeRequireModule(rmods:WaitForChild("ItemLibrary", 10))
local consts = safeRequireModule(rmods:WaitForChild("CONSTANTS", 10))
local dctrl = safeRequireModule(ctrls:WaitForChild("PlayerDataController", 10))
if not (elib and clib and ilib and consts and dctrl and clib.Cosmetics) then return end
local coss = clib.Cosmetics

local function findDescendantByName(parent, name)
	if not parent then return nil end
	local direct = parent:FindFirstChild(name)
	if direct then return direct end
	for _, descendant in ipairs(parent:GetDescendants()) do
		if descendant.Name == name then
			return descendant
		end
	end
	return nil
end

local KNIFE_CUSTOM_SKIN
local REAVER_KNIFE_CUSTOM_SKIN
local DAGGERS_CUSTOM_SKIN
local SATCHEL_CUSTOM_SKIN
local SNIPER_CUSTOM_SKIN
local RPG_CUSTOM_SKIN
local FISTS_CUSTOM_SKIN
local BOW_CUSTOM_SKIN
local ASSAULT_RIFLE_CUSTOM_SKIN
local DICE_TRIPMINE_SKIN
local SPIKE_TRIPMINE_SKIN
local RPG_MESH_SKIN_OVERRIDES
local FISTS_MESH_SKIN_OVERRIDES
local TRIPMINE_MESH_SKIN_OVERRIDES
local meshMatchesAnyAssetId
local namePathContains
local applyRpgMeshProfile
local applyFistsMeshProfile
local applyTripmineMeshProfile

(function() -- mesh/skin helpers (own register pool)
KNIFE_CUSTOM_SKIN = "Knife (Custom Skin)"
REAVER_KNIFE_CUSTOM_SKIN = "reaver"
DAGGERS_CUSTOM_SKIN = "Jett"
SATCHEL_CUSTOM_SKIN = "Raze"
SNIPER_CUSTOM_SKIN = "Chamber"
RPG_CUSTOM_SKIN = "RPG Raze"
FISTS_CUSTOM_SKIN = "Agent"
BOW_CUSTOM_SKIN = "Sova"
ASSAULT_RIFLE_CUSTOM_SKIN = "Vandal"
DICE_TRIPMINE_SKIN = "Subspace Tripmine (Custom Skin)"
local DICE_TRIPMINE_OUTER_MESH_ID = "rbxassetid://5555691474"
local DICE_TRIPMINE_INNER_MESH_ID = "rbxassetid://5555691356"
local DICE_TRIPMINE_IMAGE_ID = "rbxassetid://98372867049331"
local DICE_TRIPMINE_IMAGE_HIGH_RES_ID = "rbxassetid://75601061529918"
local DICE_TRIPMINE_MESH_SCALE = 3.35
local DICE_TRIPMINE_WORLD_MESH_SCALE = 3.25
SPIKE_TRIPMINE_SKIN = "Spike"
local SPIKE_TRIPMINE_MESH_ID = "rbxassetid://97754746098028"
local TRIPMINE_STAR_REMOVE_MESH_ID = "rbxassetid://13792525075"
local SPIKE_TRIPMINE_MESH_SCALE = 85
local SPIKE_TRIPMINE_WORLD_MESH_SCALE = 50
local SNIPER_CUSTOM_REPLACEMENT_MESH_ID = "rbxassetid://98786413608787"
local SNIPER_CUSTOM_REPLACEMENT_TEXTURE_ID = "rbxassetid://131686603013672"
local SNIPER_CUSTOM_REPLACEMENT_SIZE = Vector3.new(0.025, 0.025, 0.025)
local SNIPER_CUSTOM_REPLACEMENT_OFFSET = Vector3.new(0, -0.25, 0)
local DAGGERS_CUSTOM_SOURCE_MESH_ID = "rbxassetid://94772705561955"
local DAGGERS_CUSTOM_REPLACEMENT_MESH_ID = "rbxassetid://128075492497238"
local DAGGERS_CUSTOM_REPLACEMENT_TEXTURE_ID = "rbxassetid://79246900644201"
local DAGGERS_CUSTOM_REPLACEMENT_SIZE = Vector3.new(0.03, 0.03, 0.03)
local DAGGERS_CUSTOM_REPLACEMENT_ROTATION = Vector3.new(0, 90, -90)
local SATCHEL_CUSTOM_REPLACEMENT_MESH_ID = "rbxassetid://129982008330139"
local SATCHEL_CUSTOM_REPLACEMENT_TEXTURE_ID = "rbxassetid://121713947189258"
local SATCHEL_CUSTOM_REPLACEMENT_SIZE = Vector3.new(0.5, 0.5, 0.5)
local SATCHEL_CUSTOM_WORLD_REPLACEMENT_SIZE = Vector3.new(0.6, 0.6, 0.6)
local SATCHEL_CUSTOM_REPLACEMENT_ROTATION = Vector3.new(0, -90, 0)
local RPG_CUSTOM_BODY_REPLACEMENT_MESH_ID = "rbxassetid://81554047161707"
local RPG_CUSTOM_BODY_REPLACEMENT_TEXTURE_ID = "rbxassetid://133257377819985"
local RPG_CUSTOM_REPLACEMENT_SCALE = 0.5
local RPG_CUSTOM_REPLACEMENT_ROTATION = Vector3.new(0, 90, 0)
local RPG_CUSTOM_REPLACEMENT_OFFSET = Vector3.new(0.04, 0, 0)
local FISTS_CUSTOM_LEFT_MESH_ID = "rbxassetid://120273083766829"
local FISTS_CUSTOM_LEFT_TEXTURE_ID = "rbxassetid://124608382264962"
local FISTS_CUSTOM_RIGHT_MESH_ID = "rbxassetid://129220833982000"
local FISTS_CUSTOM_RIGHT_TEXTURE_ID = "rbxassetid://118482605175566"
local FISTS_CUSTOM_MESH_SCALE = Vector3.new(0.1, 0.1, 0.1)
local FISTS_CUSTOM_LEFT_ROTATION = Vector3.new(45, 0, 0)
local FISTS_CUSTOM_RIGHT_ROTATION = Vector3.new(-45, 0, 0)
local BOW_CUSTOM_BODY_REPLACEMENT_MESH_ID = "rbxassetid://80147707463344"
local BOW_CUSTOM_BODY_REPLACEMENT_TEXTURE_ID = "rbxassetid://87690225474067"
local BOW_CUSTOM_ARROW_REPLACEMENT_MESH_ID = "rbxassetid://97839236861642"
local BOW_CUSTOM_ARROW_REPLACEMENT_TEXTURE_ID = "rbxassetid://82458179247269"
local BOW_CUSTOM_REPLACEMENT_SIZE = Vector3.new(0.25, 0.25, 0.25)

local CUSTOM_SKIN_IMAGE_OVERRIDES = {
	[REAVER_KNIFE_CUSTOM_SKIN] = { Image = "", ImageHighResolution = "" },
	["sky"] = { Image = "", ImageHighResolution = "" },
	["Camera"] = { Image = "", ImageHighResolution = "" },
	["Grenade Raze"] = { Image = "", ImageHighResolution = "" },
	[DAGGERS_CUSTOM_SKIN] = { Image = "", ImageHighResolution = "" },
	[SATCHEL_CUSTOM_SKIN] = { Image = "", ImageHighResolution = "" },
	[SNIPER_CUSTOM_SKIN] = { Image = "", ImageHighResolution = "" },
	["Operator"] = { Image = "", ImageHighResolution = "" },
	[RPG_CUSTOM_SKIN] = { Image = "", ImageHighResolution = "" },
	[FISTS_CUSTOM_SKIN] = { Image = "", ImageHighResolution = "" },
	[BOW_CUSTOM_SKIN] = { Image = "", ImageHighResolution = "" },
	[ASSAULT_RIFLE_CUSTOM_SKIN] = { Image = "", ImageHighResolution = "" },
	[DICE_TRIPMINE_SKIN] = { Image = DICE_TRIPMINE_IMAGE_ID, ImageHighResolution = DICE_TRIPMINE_IMAGE_HIGH_RES_ID },
	[SPIKE_TRIPMINE_SKIN] = { Image = "", ImageHighResolution = "" }
}

local SNIPER_MESH_SKIN_OVERRIDES = {
	[SNIPER_CUSTOM_SKIN] = {
		Skin = SNIPER_CUSTOM_SKIN,
		BodyMeshIds = {
			"rbxassetid://95497877882755",
			"rbxassetid://118920880889483",
			"rbxassetid://80662423119419"
		},
		RemoveMeshIds = {
			"rbxassetid://100168191352015",
			"rbxassetid://82935541182957",
			"rbxassetid://95388370230390",
			"rbxassetid://84918196407550"
		},
		ReplacementMeshId = SNIPER_CUSTOM_REPLACEMENT_MESH_ID,
		ReplacementTextureId = SNIPER_CUSTOM_REPLACEMENT_TEXTURE_ID,
		ReplacementSize = SNIPER_CUSTOM_REPLACEMENT_SIZE,
		ReplacementOffset = SNIPER_CUSTOM_REPLACEMENT_OFFSET
	},
	["Operator"] = {
		Skin = "Operator",
		BodyMeshIds = {
			"rbxassetid://13188893115",
			"rbxassetid://13188892761",
			"rbxassetid://14778413014",
			"rbxassetid://13188893017",
			"rbxassetid://14774727092"
		},
		RemoveMeshIds = {
			"rbxassetid://13188893310",
			"rbxassetid://13188892855"
		},
		BulletMeshIds = {
			"rbxassetid://14002915797"
		},
		MagazineMeshIds = {
			"rbxassetid://13188892532",
			"rbxassetid://13188892651"
		},
		BodyReplacementMeshId = "rbxassetid://132995629661821",
		BodyReplacementTextureId = "rbxassetid://80634410259243",
		ScopeReplacementMeshId = "rbxassetid://103988563532751",
		ScopeReplacementTextureId = "rbxassetid://136789986141252",
		MagazineReplacementMeshId = "rbxassetid://80074307887476",
		MagazineReplacementTextureId = "rbxassetid://80634410259243",
		ReplacementSize = Vector3.new(0.3, 0.3, 0.3),
		ReplacementOffset = Vector3.new(0, -0.25, 0),
		ScopeOffset = Vector3.new(0.175, 0.5, 0.005),
		MagazineOffset = Vector3.new(0.7, 0, 0.05),
		BulletOffset = Vector3.new(-1.25, 0, 0),
		ReplacementVersion = 9
	}
}

local DAGGERS_MESH_SKIN_OVERRIDES = {
	[DAGGERS_CUSTOM_SKIN] = {
		Skin = DAGGERS_CUSTOM_SKIN,
		SourceMeshIds = { DAGGERS_CUSTOM_SOURCE_MESH_ID },
		ReplacementMeshId = DAGGERS_CUSTOM_REPLACEMENT_MESH_ID,
		ReplacementTextureId = DAGGERS_CUSTOM_REPLACEMENT_TEXTURE_ID,
		ReplacementSize = DAGGERS_CUSTOM_REPLACEMENT_SIZE,
		ReplacementRotation = DAGGERS_CUSTOM_REPLACEMENT_ROTATION,
		ReplacementVersion = 6,
		FallbackBodyNames = { "LeftBody", "RightBody" }
	}
}

local SATCHEL_MESH_SKIN_OVERRIDES = {
	[SATCHEL_CUSTOM_SKIN] = {
		Skin = SATCHEL_CUSTOM_SKIN,
		SourceMeshIds = {
			"rbxassetid://138805549853994",
			"rbxassetid://125258747465100",
			"rbxassetid://111319295872696",
			"rbxassetid://129504437671598",
			"rbxassetid://104440368867933"
		},
		ReplacementMeshId = SATCHEL_CUSTOM_REPLACEMENT_MESH_ID,
		ReplacementTextureId = SATCHEL_CUSTOM_REPLACEMENT_TEXTURE_ID,
		ReplacementSize = SATCHEL_CUSTOM_REPLACEMENT_SIZE,
		WorldReplacementSize = SATCHEL_CUSTOM_WORLD_REPLACEMENT_SIZE,
		ReplacementRotation = SATCHEL_CUSTOM_REPLACEMENT_ROTATION,
		ReplacementVersion = 5
	},
	[REAVER_KNIFE_CUSTOM_SKIN] = {
		Skin = REAVER_KNIFE_CUSTOM_SKIN,
		SourceMeshIds = {
			"rbxassetid://85166039303292",
			"rbxassetid://125674590013235",
			"rbxassetid://97042702941502",
			"rbxassetid://116723276788898",
			"rbxassetid://99266754879173"
		},
		ReplacementMeshId = "rbxassetid://76054449109492",
		ReplacementTextureId = "rbxassetid://117578984602503",
		ReplacementSize = Vector3.new(0.3, 0.3, 0.3),
		ReplacementRotation = Vector3.new(0, 90, 0),
		ReplacementOffset = Vector3.new(0, 0.5, 0),
		ReplacementVersion = 3
	},
	["sky"] = {
		Skin = "sky",
		SourceMeshIds = { "rbxassetid://140203670599306" },
		ReplacementMeshId = "rbxassetid://78577370691269",
		ReplacementTextureId = "rbxassetid://130284287910497",
		ReplacementSize = Vector3.new(0.6, 0.6, 0.6),
		ReplacementRotation = Vector3.new(0, 90, 0),
		WorldSourceMeshIds = { "rbxassetid://140203670599306" },
		WorldReplacementMeshId = "rbxassetid://111122607123480",
		WorldReplacementTextureId = "rbxassetid://86629139856581",
		WorldReplacementSize = Vector3.new(0.3, 0.3, 0.3),
		WorldReplacementRotation = Vector3.zero,
		ReplacementVersion = 2
	},
	["Grenade Raze"] = {
		Skin = "Grenade Raze",
		SourceMeshIds = {
			"rbxassetid://87132852844264",
			"rbxassetid://96681677373844",
			"rbxassetid://121396126155803",
			"rbxassetid://121842208464560"
		},
		ReplacementMeshId = "rbxassetid://80612596590820",
		ReplacementTextureId = "rbxassetid://123233413518598",
		ReplacementSize = Vector3.new(0.8, 0.8, 0.8),
		ReplacementVersion = 2
	},
	["Camera"] = {
		Skin = "Camera",
		SourceMeshIds = {
			"rbxassetid://17835823024",
			"rbxassetid://17835823121",
			"rbxassetid://17835823211"
		},
		ReplacementMeshId = "rbxassetid://112849634500139",
		ReplacementTextureId = "rbxassetid://126465878813440",
		ReplacementSize = Vector3.new(0.5, 0.5, 0.5),
		ReplacementRotation = Vector3.new(0, 0, -90),
		WorldSourceMeshIds = {
			"rbxassetid://17835823024",
			"rbxassetid://17835823121",
			"rbxassetid://17835823211"
		},
		WorldReplacementSize = Vector3.new(2, 2, 2),
		WorldReplacementRotation = Vector3.new(0, 90, -90),
		ReplacementVersion = 2
	}
}

RPG_MESH_SKIN_OVERRIDES = {
	[RPG_CUSTOM_SKIN] = {
		Skin = RPG_CUSTOM_SKIN,
		BodyMeshIds = {
			"rbxassetid://17638908187",
			"rbxassetid://17638908626"
		},
		JuggleMeshIds = {
			"rbxassetid://17638908803",
			"rbxassetid://17638907818"
		},
		RocketMeshIds = {
			"rbxassetid://17638908803",
			"rbxassetid://17638907818"
		},
		BodyReplacementMeshId = RPG_CUSTOM_BODY_REPLACEMENT_MESH_ID,
		BodyReplacementTextureId = RPG_CUSTOM_BODY_REPLACEMENT_TEXTURE_ID,
		ReplacementScale = RPG_CUSTOM_REPLACEMENT_SCALE,
		ReplacementRotation = RPG_CUSTOM_REPLACEMENT_ROTATION,
		ReplacementOffset = RPG_CUSTOM_REPLACEMENT_OFFSET,
		ReplacementVersion = 3
	}
}

FISTS_MESH_SKIN_OVERRIDES = {
	[FISTS_CUSTOM_SKIN] = {
		Skin = FISTS_CUSTOM_SKIN,
		LeftPartName = "LeftItem",
		RightPartName = "RightItem",
		LeftMeshId = FISTS_CUSTOM_LEFT_MESH_ID,
		LeftTextureId = FISTS_CUSTOM_LEFT_TEXTURE_ID,
		RightMeshId = FISTS_CUSTOM_RIGHT_MESH_ID,
		RightTextureId = FISTS_CUSTOM_RIGHT_TEXTURE_ID,
		MeshScale = FISTS_CUSTOM_MESH_SCALE,
		LeftRotation = FISTS_CUSTOM_LEFT_ROTATION,
		RightRotation = FISTS_CUSTOM_RIGHT_ROTATION,
		ReplacementVersion = 1
	}
}

local BOW_MESH_SKIN_OVERRIDES = {
	[BOW_CUSTOM_SKIN] = {
		Skin = BOW_CUSTOM_SKIN,
		BodyMeshIds = {
			"rbxassetid://116947825701555",
			"rbxassetid://80510746199823"
		},
		ArrowMeshIds = {
			"rbxassetid://108027163190911",
			"rbxassetid://114261802270550"
		},
		BodyReplacementMeshId = BOW_CUSTOM_BODY_REPLACEMENT_MESH_ID,
		BodyReplacementTextureId = BOW_CUSTOM_BODY_REPLACEMENT_TEXTURE_ID,
		ArrowReplacementMeshId = BOW_CUSTOM_ARROW_REPLACEMENT_MESH_ID,
		ArrowReplacementTextureId = BOW_CUSTOM_ARROW_REPLACEMENT_TEXTURE_ID,
		ReplacementSize = BOW_CUSTOM_REPLACEMENT_SIZE,
		ReplacementVersion = 2
	}
}

local ASSAULT_RIFLE_MESH_SKIN_OVERRIDES = {
	[ASSAULT_RIFLE_CUSTOM_SKIN] = {
		Skin = ASSAULT_RIFLE_CUSTOM_SKIN,
		BodyMeshIds = {
			"rbxassetid://17661950733",
			"rbxassetid://17661950585",
			"rbxassetid://17662005180",
			"rbxassetid://17662016762"
		},
		BoltMeshIds = {
			"rbxassetid://17661950452"
		},
		MagazineMeshIds = {
			"rbxassetid://17662005301",
			"rbxassetid://17662005453"
		},
		ReloadMagazineMeshIds = {
			"rbxassetid://17662005453",
			"rbxassetid://17662005301"
		},
		BodyReplacementMeshId = "rbxassetid://138100951261312",
		BodyReplacementTextureId = "rbxassetid://84167100219585",
		MagazineReplacementMeshId = "rbxassetid://92935167277909",
		MagazineReplacementTextureId = "rbxassetid://84167100219585",
		ReloadMagazineReplacementMeshId = "rbxassetid://92935167277909",
		ReloadMagazineReplacementTextureId = "rbxassetid://84167100219585",
		ReplacementSize = Vector3.new(0.35, 0.35, 0.35),
		ReplacementOffset = Vector3.new(0.1, -0.25, 0.04),
		MagazineOffset = Vector3.new(-0.135, -0.2, -0.03),
		ReplacementVersion = 6
	}
}

TRIPMINE_MESH_SKIN_OVERRIDES = {
	[DICE_TRIPMINE_SKIN] = {
		Skin = DICE_TRIPMINE_SKIN,
		MeshIds = { DICE_TRIPMINE_OUTER_MESH_ID, DICE_TRIPMINE_INNER_MESH_ID },
		RemoveMeshId = TRIPMINE_STAR_REMOVE_MESH_ID,
		Scale = DICE_TRIPMINE_MESH_SCALE,
		WorldScale = DICE_TRIPMINE_WORLD_MESH_SCALE,
		WorldGroundOffset = 0.5,
		ExtraMeshScale = 1.15,
		WorldExtraMeshScale = 1,
		Color = Color3.fromRGB(255, 255, 255),
		Material = Enum.Material.SmoothPlastic,
		Reflectance = 0,
		ClearTexture = true
	},
	[SPIKE_TRIPMINE_SKIN] = {
		Skin = SPIKE_TRIPMINE_SKIN,
		MeshId = SPIKE_TRIPMINE_MESH_ID,
		RemoveMeshId = TRIPMINE_STAR_REMOVE_MESH_ID,
		Scale = SPIKE_TRIPMINE_MESH_SCALE,
		WorldScale = SPIKE_TRIPMINE_WORLD_MESH_SCALE,
		WorldGroundOffset = 0.5,
		Color = Color3.fromRGB(163, 162, 165),
		ClearTexture = true
	}
}

local function normalizeAssetId(assetId)
	return tostring(assetId or ""):match("%d+") or ""
end

local function getTripmineMeshIds(profile)
	local ids = {}
	if type(profile and profile.MeshIds) == "table" then
		for _, meshId in ipairs(profile.MeshIds) do
			if normalizeAssetId(meshId) ~= "" then
				table.insert(ids, meshId)
			end
		end
	elseif profile and normalizeAssetId(profile.MeshId) ~= "" then
		table.insert(ids, profile.MeshId)
	end
	return ids
end

local function getTripmineExtraMeshScale(profile, worldVisual)
	if worldVisual then
		return profile and profile.WorldExtraMeshScale or 1
	end
	return profile and profile.ExtraMeshScale or 1
end

local function getTripmineMeshSignature(profile, worldVisual)
	local normalized = {}
	for _, meshId in ipairs(getTripmineMeshIds(profile)) do
		table.insert(normalized, normalizeAssetId(meshId))
	end
	return table.concat(normalized, ",") .. "|" .. tostring(getTripmineExtraMeshScale(profile, worldVisual))
end

local function scaleTripmineMeshVector(scale, multiplier)
	multiplier = multiplier or 1
	if typeof(scale) == "Vector3" then
		return scale * multiplier
	end
	return Vector3.new(scale, scale, scale) * multiplier
end

local function meshMatchesAssetId(inst, assetId)
	local id = normalizeAssetId(assetId)
	if id == "" or typeof(inst) ~= "Instance" then return false end
	if inst:IsA("SpecialMesh") then
		return normalizeAssetId(inst.MeshId) == id or normalizeAssetId(inst.TextureId) == id
	elseif inst:IsA("MeshPart") then
		return normalizeAssetId(inst.MeshId) == id or normalizeAssetId(inst.TextureID) == id
	end
	return false
end

local function isCustomTripmineMeshIgnored(inst)
	local current = inst
	while current do
		if current:GetAttribute("__LionHiddenTripmineMesh") then
			return true
		end
		local compactName = tostring(current.Name or ""):lower():gsub("[%s_%-%p]", "")
		if compactName:find("arm", 1, true)
			or compactName:find("hand", 1, true)
			or compactName:find("fake", 1, true)
			or compactName:find("charm", 1, true)
			or compactName:find("hitbox", 1, true) then
			return true
		end
		current = current.Parent
	end
	return false
end

local function scoreCustomTripmineMeshTarget(root, meshLike, removedMeshId)
	if removedMeshId and meshMatchesAssetId(meshLike, removedMeshId) then return nil end
	local part = meshLike:IsA("SpecialMesh") and meshLike.Parent or meshLike
	if not (part and part:IsA("BasePart")) or isCustomTripmineMeshIgnored(part) then return nil end
	local score = part.Size.Magnitude
	local name = tostring(part.Name or ""):lower()
	if root:IsA("Model") and part == root.PrimaryPart then score += 1000 end
	if name:find("mesh", 1, true) then score += 500 end
	if name:find("body", 1, true) then score += 250 end
	if name:find("mine", 1, true) or name:find("trip", 1, true) then score += 250 end
	return score
end

local function findCustomTripmineMeshTarget(root, profile)
	if typeof(root) ~= "Instance" then return nil end
	local best, bestScore = nil, -math.huge
	local removedMeshId = profile and (profile.RemoveMeshId or profile.HideMeshId)
	local function consider(obj)
		if obj:IsA("SpecialMesh") or obj:IsA("MeshPart") then
			local score = scoreCustomTripmineMeshTarget(root, obj, removedMeshId)
			if score and score > bestScore then
				best = obj
				bestScore = score
			end
		end
	end
	consider(root)
	for _, descendant in ipairs(root:GetDescendants()) do
		consider(descendant)
	end
	return best
end

local function removeTripmineMeshAsset(root, assetId)
	if typeof(root) ~= "Instance" or not assetId then return end
	local remove = {}
	local function queueIfMatch(obj)
		if meshMatchesAssetId(obj, assetId) then
			local part = obj:IsA("SpecialMesh") and obj.Parent or obj
			if part and part:IsA("BasePart") then
				table.insert(remove, part)
			elseif obj:IsA("SpecialMesh") then
				table.insert(remove, obj)
			end
		end
	end
	queueIfMatch(root)
	for _, obj in ipairs(root:GetDescendants()) do
		queueIfMatch(obj)
	end
	for _, obj in ipairs(remove) do
		if obj and obj.Parent then
			obj:SetAttribute("__LionRemovedTripmineMesh", true)
			obj:Destroy()
		end
	end
end

local function removeCustomTripmineExtraMeshes(root)
	if typeof(root) ~= "Instance" then return end
	for _, obj in ipairs(root:GetDescendants()) do
		if obj:GetAttribute("__LionCustomTripmineExtraMesh") then
			obj:Destroy()
		end
	end
end

local function getMeshLikePart(obj)
	if typeof(obj) ~= "Instance" then return nil end
	if obj:IsA("SpecialMesh") then
		return obj.Parent and obj.Parent:IsA("BasePart") and obj.Parent or nil
	end
	return obj:IsA("BasePart") and obj or nil
end

meshMatchesAnyAssetId = function(inst, assetIds)
	for _, assetId in ipairs(assetIds or {}) do
		if meshMatchesAssetId(inst, assetId) then
			return true
		end
	end
	return false
end

local function rotationCFrameFromDegrees(rotation)
	if typeof(rotation) ~= "Vector3" then return CFrame.identity end
	return CFrame.Angles(math.rad(rotation.X), math.rad(rotation.Y), math.rad(rotation.Z))
end

namePathContains = function(inst, needle)
	needle = tostring(needle or ""):lower()
	if needle == "" then return false end
	local current = inst
	while current and current ~= game do
		if tostring(current.Name or ""):lower():find(needle, 1, true) then
			return true
		end
		current = current.Parent
	end
	return false
end

local function hideDaggerMeshAnchor(part)
	if not (part and part:IsA("BasePart")) then return end
	part.Transparency = 1
	part.LocalTransparencyModifier = 1
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Massless = true
	pcall(function() part.CastShadow = false end)
	pcall(function() part.Size = Vector3.new(0.001, 0.001, 0.001) end)
	part:SetAttribute("__LionDaggerHiddenAnchor", true)
	part:SetAttribute("IgnoreObject", true)
	part:SetAttribute("IgnoreTransparency", true)
	pcall(function() collectionService:RemoveTag(part, "Wrappable") end)
	if part:IsA("MeshPart") then
		pcall(function() part.TextureID = "" end)
	end
	for _, child in ipairs(part:GetDescendants()) do
		if child:IsA("Decal") or child:IsA("Texture") then
			child.Transparency = 1
		elseif child:IsA("SurfaceAppearance") then
			child:Destroy()
		elseif child:IsA("SpecialMesh") then
			child.Scale = Vector3.zero
			pcall(function() child.TextureId = "" end)
		end
	end
end

local function addReplacementSpecialMesh(part, profile, defaultScale)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.FileMesh
	mesh.MeshId = profile.ReplacementMeshId
	pcall(function() mesh.TextureId = profile.ReplacementTextureId or "" end)
	mesh.Scale = profile.ReplacementMeshScale or profile.ReplacementSize or defaultScale or Vector3.new(1, 1, 1)
	pcall(function() mesh.VertexColor = Vector3.new(1, 1, 1) end)
	mesh.Parent = part
	return mesh
end

local function createDaggerReplacementMeshPart(anchor, profile)
	if not (anchor and anchor:IsA("BasePart")) then return false end
	if anchor:GetAttribute("__LionDaggerReplacementMeshPart") then return true end

	local parent = anchor.Parent
	if not parent then return false end
	local originalName = anchor.Name
	anchor.Name = "__LionDaggerAnchor_" .. originalName

	local replacement = Instance.new("Part")
	replacement.Name = originalName
	replacement.Size = Vector3.new(1, 1, 1)
	replacement.CFrame = anchor.CFrame * rotationCFrameFromDegrees(profile.ReplacementRotation)
	replacement.Anchored = anchor.Anchored
	replacement.CanCollide = false
	replacement.CanTouch = false
	replacement.CanQuery = false
	replacement.Massless = true
	replacement.Color = Color3.fromRGB(255, 255, 255)
	pcall(function() replacement.Material = anchor.Material end)
	pcall(function() replacement.CastShadow = false end)
	replacement:SetAttribute("__LionCustomDaggerMesh", true)
	replacement:SetAttribute("__LionDaggerReplacementMeshPart", true)
	replacement:SetAttribute("IgnoreTransparency", true)
	addReplacementSpecialMesh(replacement, profile)
	local wrapGroup = anchor:GetAttribute("WrapGroup")
	if wrapGroup ~= nil then
		replacement:SetAttribute("WrapGroup", wrapGroup)
	end
	pcall(function()
		if collectionService:HasTag(anchor, "Wrappable") then
			collectionService:AddTag(replacement, "Wrappable")
		end
	end)
	replacement.Parent = parent

	local weld = Instance.new("WeldConstraint")
	weld.Name = "__LionDaggerReplacementWeld"
	weld.Part0 = anchor
	weld.Part1 = replacement
	weld.Parent = replacement

	hideDaggerMeshAnchor(anchor)
	return true
end

local function applyMeshReplacementToObject(obj, profile)
	if typeof(obj) ~= "Instance" then return false end
	if obj:GetAttribute("__LionDaggerReplacementMeshPart") or obj:GetAttribute("__LionDaggerHiddenAnchor") then
		return false
	end
	local part = getMeshLikePart(obj)
	if obj:IsA("MeshPart") then
		return createDaggerReplacementMeshPart(obj, profile)
	elseif obj:IsA("SpecialMesh") then
		if part then
			part.Transparency = 0
			part.LocalTransparencyModifier = 0
			part.Color = Color3.fromRGB(255, 255, 255)
			pcall(function() part.CastShadow = false end)
			if profile.ReplacementRotation then
				part.CFrame = part.CFrame * rotationCFrameFromDegrees(profile.ReplacementRotation)
			end
		end
		pcall(function() obj.MeshId = profile.ReplacementMeshId end)
		pcall(function() obj.TextureId = profile.ReplacementTextureId or "" end)
		if profile.ReplacementSize then
			pcall(function() obj.Scale = profile.ReplacementSize end)
		end
		obj:SetAttribute("__LionCustomDaggerMesh", true)
		return true
	end
	return false
end

local function getDaggerMeshSignature(profile)
	local size = profile.ReplacementSize or Vector3.zero
	local rotation = profile.ReplacementRotation or Vector3.zero
	return table.concat({
		table.concat(profile.SourceMeshIds or {}, ","),
		tostring(profile.ReplacementMeshId or ""),
		tostring(profile.ReplacementTextureId or ""),
		tostring(size.X),
		tostring(size.Y),
		tostring(size.Z),
		tostring(rotation.X),
		tostring(rotation.Y),
		tostring(rotation.Z),
		tostring(profile.ReplacementVersion or 1)
	}, "|")
end

local function applyDaggerMeshProfile(root, profile)
	if typeof(root) ~= "Instance" or not profile then return false end
	local signature = getDaggerMeshSignature(profile)
	if root:GetAttribute("__LionDaggerMeshSkin") == profile.Skin
		and root:GetAttribute("__LionDaggerMeshSignature") == signature then
		return true
	end

	local replaced, seen = 0, {}
	local function replaceIfTarget(obj)
		if seen[obj] or not meshMatchesAnyAssetId(obj, profile.SourceMeshIds) then return end
		seen[obj] = true
		if applyMeshReplacementToObject(obj, profile) then
			replaced += 1
		end
	end

	replaceIfTarget(root)
	for _, obj in ipairs(root:GetDescendants()) do
		replaceIfTarget(obj)
	end

	for _, bodyName in ipairs(profile.FallbackBodyNames or {}) do
		for _, obj in ipairs(root:GetDescendants()) do
			if obj.Name == bodyName then
				local target = obj:FindFirstChild("MeshPart")
				if target and not seen[target] and target:IsA("MeshPart") then
					seen[target] = true
					if applyMeshReplacementToObject(target, profile) then
						replaced += 1
					end
				end
			end
		end
	end

	root:SetAttribute("__LionDaggerMeshSkin", profile.Skin)
	root:SetAttribute("__LionDaggerMeshSignature", signature)
	root:SetAttribute("__LionDaggerMeshCount", replaced)
	return replaced > 0
end

local function hideSatchelMeshAnchor(part)
	if not (part and part:IsA("BasePart")) then return end
	part.Transparency = 1
	part.LocalTransparencyModifier = 1
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Massless = true
	pcall(function() part.CastShadow = false end)
	pcall(function() part.Size = Vector3.new(0.001, 0.001, 0.001) end)
	part:SetAttribute("__LionSatchelHiddenAnchor", true)
	part:SetAttribute("IgnoreObject", true)
	part:SetAttribute("IgnoreTransparency", true)
	pcall(function() collectionService:RemoveTag(part, "Wrappable") end)
	if part:IsA("MeshPart") then
		pcall(function() part.TextureID = "" end)
		pcall(function() part.MeshId = "" end)
	end
	for _, child in ipairs(part:GetDescendants()) do
		if child:IsA("Decal") or child:IsA("Texture") then
			child.Transparency = 1
		elseif child:IsA("SurfaceAppearance") then
			child:Destroy()
		elseif child:IsA("SpecialMesh") then
			child.Scale = Vector3.zero
			pcall(function() child.MeshId = "" end)
			pcall(function() child.TextureId = "" end)
		end
	end
end

local function getReplacementAverageCFrame(parts)
	local first = parts and parts[1]
	if not first then return CFrame.identity end
	local position = Vector3.zero
	for _, part in ipairs(parts) do
		position += part.Position
	end
	position /= #parts
	return CFrame.new(position) * (first.CFrame - first.CFrame.Position)
end

local function createSatchelReplacementMeshPart(root, profile, anchors)
	local anchor = anchors and anchors[1]
	if not (anchor and anchor:IsA("BasePart")) then return false end
	local parent = anchor.Parent
	if not parent then return false end

	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant:GetAttribute("__LionSatchelReplacementMeshPart") then
			descendant:Destroy()
		end
	end

	local replacement = Instance.new("Part")
	replacement.Name = "__LionCustomSatchelReplacement"
	replacement.Size = Vector3.new(1, 1, 1)
	replacement.CFrame = getReplacementAverageCFrame(anchors)
		* CFrame.new(profile.ReplacementOffset or Vector3.zero)
		* rotationCFrameFromDegrees(profile.ReplacementRotation)
	replacement.Anchored = anchor.Anchored
	replacement.CanCollide = false
	replacement.CanTouch = false
	replacement.CanQuery = false
	replacement.Massless = true
	replacement.Color = Color3.fromRGB(255, 255, 255)
	pcall(function() replacement.Material = anchor.Material end)
	pcall(function() replacement.CastShadow = false end)
	replacement:SetAttribute("__LionCustomSatchelMesh", true)
	replacement:SetAttribute("__LionSatchelReplacementMeshPart", true)
	replacement:SetAttribute("IgnoreTransparency", true)
	addReplacementSpecialMesh(replacement, profile, Vector3.new(1, 1, 1))
	local wrapGroup = anchor:GetAttribute("WrapGroup")
	if wrapGroup ~= nil then
		replacement:SetAttribute("WrapGroup", wrapGroup)
	end
	pcall(function()
		if collectionService:HasTag(anchor, "Wrappable") then
			collectionService:AddTag(replacement, "Wrappable")
		end
	end)
	replacement.Parent = parent

	local weld = Instance.new("WeldConstraint")
	weld.Name = "__LionSatchelReplacementWeld"
	weld.Part0 = anchor
	weld.Part1 = replacement
	weld.Parent = replacement

	for _, part in ipairs(anchors) do
		if part and part.Parent then
			if not part.Name:find("__LionSatchelAnchor_", 1, true) then
				part.Name = "__LionSatchelAnchor_" .. part.Name
			end
			hideSatchelMeshAnchor(part)
		end
	end
	return true
end

local function _applySatchelReplacementToObject(obj, profile)
	if typeof(obj) ~= "Instance" then return false end
	if obj:GetAttribute("__LionSatchelReplacementMeshPart") then return false end
	local part = getMeshLikePart(obj)
	if part and part:GetAttribute("__LionSatchelHiddenAnchor") then return false end
	return part and createSatchelReplacementMeshPart(part.Parent or part, profile, { part }) or false
end

local function getSatchelMeshSignature(profile)
	local rotation = profile.ReplacementRotation or Vector3.zero
	local offset = profile.ReplacementOffset or Vector3.zero
	local size = profile.ReplacementSize or Vector3.zero
	return table.concat({
		table.concat(profile.SourceMeshIds or {}, ","),
		tostring(profile.ReplacementMeshId or ""),
		tostring(profile.ReplacementTextureId or ""),
		tostring(size.X),
		tostring(size.Y),
		tostring(size.Z),
		tostring(offset.X),
		tostring(offset.Y),
		tostring(offset.Z),
		tostring(rotation.X),
		tostring(rotation.Y),
		tostring(rotation.Z),
		tostring(profile.ReplacementVersion or 1)
	}, "|")
end

local function applySatchelMeshProfile(root, profile)
	if typeof(root) ~= "Instance" or not profile then return false end
	local signature = getSatchelMeshSignature(profile)
	if root:GetAttribute("__LionSatchelMeshSkin") == profile.Skin
		and root:GetAttribute("__LionSatchelMeshSignature") == signature then
		return true
	end

	local bodyParts, seenObjects, seenParts = {}, {}, {}
	local function replaceIfTarget(obj)
		if seenObjects[obj] or not meshMatchesAnyAssetId(obj, profile.SourceMeshIds) then return end
		seenObjects[obj] = true
		local part = getMeshLikePart(obj)
		if part and not seenParts[part] then
			seenParts[part] = true
			table.insert(bodyParts, part)
		end
	end

	replaceIfTarget(root)
	for _, obj in ipairs(root:GetDescendants()) do
		replaceIfTarget(obj)
	end

	local replaced = createSatchelReplacementMeshPart(root, profile, bodyParts) and 1 or 0

	root:SetAttribute("__LionSatchelMeshSkin", profile.Skin)
	root:SetAttribute("__LionSatchelMeshSignature", signature)
	root:SetAttribute("__LionSatchelMeshCount", replaced)
	return replaced > 0
end

local function getSatchelMeshProfileForAsset(cosmeticName, worldAsset)
	local profile = SATCHEL_MESH_SKIN_OVERRIDES[cosmeticName]
	if profile and worldAsset and (
		profile.WorldSourceMeshIds
		or profile.WorldReplacementMeshId
		or profile.WorldReplacementTextureId
		or profile.WorldReplacementSize
		or profile.WorldReplacementRotation
		or profile.WorldReplacementOffset
	) then
		local worldProfile = table.clone(profile)
		worldProfile.SourceMeshIds = profile.WorldSourceMeshIds or profile.SourceMeshIds
		worldProfile.ReplacementMeshId = profile.WorldReplacementMeshId or profile.ReplacementMeshId
		worldProfile.ReplacementTextureId = profile.WorldReplacementTextureId or profile.ReplacementTextureId
		worldProfile.ReplacementSize = profile.WorldReplacementSize or profile.ReplacementSize
		worldProfile.ReplacementRotation = profile.WorldReplacementRotation or profile.ReplacementRotation
		worldProfile.ReplacementOffset = profile.WorldReplacementOffset or profile.ReplacementOffset
		return worldProfile
	end
	return profile
end

local function hideRpgMeshPart(part)
	if not (part and part:IsA("BasePart")) then return false end
	if part:GetAttribute("__LionRpgHiddenPart") then return true end
	part.Transparency = 1
	part.LocalTransparencyModifier = 1
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Massless = true
	pcall(function() part.CastShadow = false end)
	pcall(function() part.Size = Vector3.new(0.001, 0.001, 0.001) end)
	part:SetAttribute("__LionRpgHiddenPart", true)
	part:SetAttribute("IgnoreObject", true)
	part:SetAttribute("IgnoreTransparency", true)
	part:SetAttribute("WrapGroup", 0)
	pcall(function() part:RemoveTag("Wrappable") end)
	pcall(function() collectionService:RemoveTag(part, "Wrappable") end)
	if part:IsA("MeshPart") then
		pcall(function() part.TextureID = "" end)
		pcall(function() part.MeshId = "" end)
	end
	for _, child in ipairs(part:GetDescendants()) do
		if child:IsA("Decal") or child:IsA("Texture") then
			child.Transparency = 1
		elseif child:IsA("SurfaceAppearance") then
			child:Destroy()
		elseif child:IsA("SpecialMesh") then
			child.Scale = Vector3.zero
			pcall(function() child.MeshId = "" end)
			pcall(function() child.TextureId = "" end)
		elseif child:IsA("Highlight") then
			child.Enabled = false
		end
	end
	return true
end

local function applyRpgMeshReplacement(obj, meshId, textureId, profile)
	local part = getMeshLikePart(obj)
	if not part or part:GetAttribute("__LionRpgHiddenPart") then return false end
	part.Transparency = 0
	part.LocalTransparencyModifier = 0
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Massless = true
	part:SetAttribute("__LionCustomRpgMesh", true)
	part:SetAttribute("IgnoreTransparency", true)
	if not part:GetAttribute("__LionRpgReplacementAdjusted") then
		local scale = tonumber(profile and profile.ReplacementScale) or 1
		if scale ~= 1 then
			pcall(function()
				part.Size = part.Size * scale
			end)
		end
		if profile and profile.ReplacementOffset then
			pcall(function()
				part.CFrame = part.CFrame * CFrame.new(profile.ReplacementOffset)
			end)
		end
		if profile and profile.ReplacementRotation then
			pcall(function()
				part.CFrame = part.CFrame * rotationCFrameFromDegrees(profile.ReplacementRotation)
			end)
		end
		part:SetAttribute("__LionRpgReplacementAdjusted", true)
	end
	if obj:IsA("MeshPart") then
		pcall(function() obj.MeshId = meshId end)
		pcall(function() obj.TextureID = textureId or "" end)
		return true
	elseif obj:IsA("SpecialMesh") then
		pcall(function() obj.MeshType = Enum.MeshType.FileMesh end)
		pcall(function() obj.MeshId = meshId end)
		pcall(function() obj.TextureId = textureId or "" end)
		pcall(function() obj.VertexColor = Vector3.new(1, 1, 1) end)
		return true
	end
	return false
end

local function getRpgMeshSignature(profile)
	local rotation = profile.ReplacementRotation or Vector3.zero
	local offset = profile.ReplacementOffset or Vector3.zero
	return table.concat({
		table.concat(profile.BodyMeshIds or {}, ","),
		table.concat(profile.JuggleMeshIds or {}, ","),
		table.concat(profile.RocketMeshIds or {}, ","),
		tostring(profile.BodyReplacementMeshId or ""),
		tostring(profile.BodyReplacementTextureId or ""),
		tostring(profile.ReplacementScale or 1),
		tostring(rotation.X),
		tostring(rotation.Y),
		tostring(rotation.Z),
		tostring(offset.X),
		tostring(offset.Y),
		tostring(offset.Z),
		tostring(profile.ReplacementVersion or 1)
	}, "|")
end

applyRpgMeshProfile = function(root, profile, options)
	if typeof(root) ~= "Instance" or not profile then return false end
	options = options or {}
	local signature = getRpgMeshSignature(profile)
	if root:GetAttribute("__LionRpgMeshSkin") == profile.Skin
		and root:GetAttribute("__LionRpgMeshSignature") == signature
		and root:GetAttribute("__LionRpgRocketVisible") == false then
		return true
	end

	local changed, removed, seen = 0, 0, {}
	local function applyIfTarget(obj)
		if seen[obj] then return end
		if not (meshMatchesAnyAssetId(obj, profile.BodyMeshIds)
			or meshMatchesAnyAssetId(obj, profile.JuggleMeshIds)
			or meshMatchesAnyAssetId(obj, profile.RocketMeshIds)) then
			return
		end
		seen[obj] = true
		local part = getMeshLikePart(obj)
		if not part then return end
		if (namePathContains(obj, "rocket") and meshMatchesAnyAssetId(obj, profile.RocketMeshIds))
			or (namePathContains(obj, "juggle") and meshMatchesAnyAssetId(obj, profile.JuggleMeshIds)) then
			if hideRpgMeshPart(part) then removed += 1 end
		elseif meshMatchesAnyAssetId(obj, profile.BodyMeshIds) then
			if applyRpgMeshReplacement(obj, profile.BodyReplacementMeshId, profile.BodyReplacementTextureId, profile) then
				changed += 1
			end
		end
	end

	applyIfTarget(root)
	for _, obj in ipairs(root:GetDescendants()) do
		applyIfTarget(obj)
	end

	root:SetAttribute("__LionRpgMeshSkin", profile.Skin)
	root:SetAttribute("__LionRpgMeshSignature", signature)
	root:SetAttribute("__LionRpgRocketVisible", false)
	root:SetAttribute("__LionRpgMeshCount", changed)
	root:SetAttribute("__LionRpgHiddenCount", removed)
	return changed > 0 or removed > 0
end

local function createFistsReplacementPart(part, meshId, textureId, meshScale, rotation)
	if not (part and part:IsA("BasePart")) then return false end
	for _, child in ipairs(part:GetChildren()) do
		child:Destroy()
	end

	part.Transparency = 1
	part.LocalTransparencyModifier = 1
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Massless = true
	part:SetAttribute("__LionFistsHiddenAnchor", true)
	part:SetAttribute("IgnoreTransparency", true)

	local replacement = Instance.new("Part")
	replacement.Name = "__LionCustomFistsMesh"
	replacement.Size = part.Size
	replacement.CFrame = part.CFrame * rotationCFrameFromDegrees(rotation)
	replacement.Anchored = false
	replacement.CanCollide = false
	replacement.CanTouch = false
	replacement.CanQuery = false
	replacement.Massless = true
	replacement.Transparency = 0
	replacement.LocalTransparencyModifier = 0
	replacement:SetAttribute("__LionCustomFistsMesh", true)
	replacement:SetAttribute("IgnoreTransparency", true)
	replacement.Parent = part

	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.FileMesh
	mesh.MeshId = meshId
	pcall(function() mesh.TextureId = textureId or "" end)
	mesh.Scale = meshScale or Vector3.new(0.1, 0.1, 0.1)
	pcall(function() mesh.VertexColor = Vector3.new(1, 1, 1) end)
	mesh.Parent = replacement

	local weld = Instance.new("WeldConstraint")
	weld.Name = "__LionCustomFistsMeshWeld"
	weld.Part0 = part
	weld.Part1 = replacement
	weld.Parent = replacement
	return true
end

local function getFistsMeshSignature(profile)
	local scale = profile.MeshScale or Vector3.zero
	local leftRotation = profile.LeftRotation or Vector3.zero
	local rightRotation = profile.RightRotation or Vector3.zero
	return table.concat({
		tostring(profile.LeftMeshId or ""),
		tostring(profile.LeftTextureId or ""),
		tostring(profile.RightMeshId or ""),
		tostring(profile.RightTextureId or ""),
		tostring(scale.X),
		tostring(scale.Y),
		tostring(scale.Z),
		tostring(leftRotation.X),
		tostring(leftRotation.Y),
		tostring(leftRotation.Z),
		tostring(rightRotation.X),
		tostring(rightRotation.Y),
		tostring(rightRotation.Z),
		tostring(profile.ReplacementVersion or 1)
	}, "|")
end

applyFistsMeshProfile = function(root, profile)
	if typeof(root) ~= "Instance" or not profile then return false end
	local signature = getFistsMeshSignature(profile)
	if root:GetAttribute("__LionFistsMeshSkin") == profile.Skin
		and root:GetAttribute("__LionFistsMeshSignature") == signature
		and (root:GetAttribute("__LionFistsMeshCount") or 0) > 0 then
		return true
	end

	local left = findDescendantByName(root, profile.LeftPartName or "LeftItem")
	local right = findDescendantByName(root, profile.RightPartName or "RightItem")
	local applied = 0
	if createFistsReplacementPart(left, profile.LeftMeshId, profile.LeftTextureId, profile.MeshScale, profile.LeftRotation) then
		applied += 1
	end
	if createFistsReplacementPart(right, profile.RightMeshId, profile.RightTextureId, profile.MeshScale, profile.RightRotation) then
		applied += 1
	end

	root:SetAttribute("__LionFistsMeshSkin", profile.Skin)
	root:SetAttribute("__LionFistsMeshSignature", signature)
	root:SetAttribute("__LionFistsMeshCount", applied)
	return applied > 0
end

local function hideBowMeshAnchor(part)
	if not (part and part:IsA("BasePart")) then return false end
	if part:GetAttribute("__LionBowHiddenAnchor") then return true end
	part.Transparency = 1
	part.LocalTransparencyModifier = 1
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Massless = true
	pcall(function() part.CastShadow = false end)
	pcall(function() part.Size = Vector3.new(0.001, 0.001, 0.001) end)
	part:SetAttribute("__LionBowHiddenAnchor", true)
	part:SetAttribute("IgnoreObject", true)
	part:SetAttribute("IgnoreTransparency", true)
	pcall(function() part:RemoveTag("Wrappable") end)
	pcall(function() collectionService:RemoveTag(part, "Wrappable") end)
	if part:IsA("MeshPart") then
		pcall(function() part.TextureID = "" end)
		pcall(function() part.MeshId = "" end)
	end
	for _, child in ipairs(part:GetDescendants()) do
		if child:IsA("Decal") or child:IsA("Texture") then
			child.Transparency = 1
		elseif child:IsA("SurfaceAppearance") then
			child:Destroy()
		elseif child:IsA("SpecialMesh") then
			child.Scale = Vector3.zero
			pcall(function() child.MeshId = "" end)
			pcall(function() child.TextureId = "" end)
		elseif child:IsA("Highlight") then
			child.Enabled = false
		end
	end
	return true
end

local function createBowReplacementMeshPart(root, anchors, replacementName, meshId, textureId, profile)
	local anchor = anchors and anchors[1]
	if not (anchor and anchor:IsA("BasePart")) then return false end
	local parent = anchor.Parent or root
	if not parent then return false end

	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant:GetAttribute("__LionBowReplacementMeshPart") and descendant.Name == replacementName then
			descendant:Destroy()
		end
	end

	local replacement = Instance.new("Part")
	replacement.Name = replacementName
	replacement.Size = Vector3.new(1, 1, 1)
	replacement.CFrame = getReplacementAverageCFrame(anchors)
	replacement.Anchored = anchor.Anchored
	replacement.CanCollide = false
	replacement.CanTouch = false
	replacement.CanQuery = false
	replacement.Massless = true
	replacement.Transparency = 0
	replacement.LocalTransparencyModifier = 0
	replacement:SetAttribute("__LionCustomBowMesh", true)
	replacement:SetAttribute("__LionBowReplacementMeshPart", true)
	replacement:SetAttribute("IgnoreTransparency", true)

	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.FileMesh
	mesh.MeshId = meshId
	pcall(function() mesh.TextureId = textureId or "" end)
	mesh.Scale = profile.ReplacementSize or Vector3.new(0.5, 0.5, 0.5)
	pcall(function() mesh.VertexColor = Vector3.new(1, 1, 1) end)
	mesh.Parent = replacement

	local wrapGroup = anchor:GetAttribute("WrapGroup")
	if wrapGroup ~= nil then
		replacement:SetAttribute("WrapGroup", wrapGroup)
	end
	pcall(function()
		if collectionService:HasTag(anchor, "Wrappable") then
			collectionService:AddTag(replacement, "Wrappable")
		end
	end)
	replacement.Parent = parent

	if not replacement.Anchored then
		local weld = Instance.new("WeldConstraint")
		weld.Name = "__LionBowReplacementWeld"
		weld.Part0 = anchor
		weld.Part1 = replacement
		weld.Parent = replacement
	end

	for _, part in ipairs(anchors) do
		hideBowMeshAnchor(part)
	end
	return true
end

local function getBowMeshSignature(profile)
	local size = profile.ReplacementSize or Vector3.zero
	return table.concat({
		table.concat(profile.BodyMeshIds or {}, ","),
		table.concat(profile.ArrowMeshIds or {}, ","),
		tostring(profile.BodyReplacementMeshId or ""),
		tostring(profile.BodyReplacementTextureId or ""),
		tostring(profile.ArrowReplacementMeshId or ""),
		tostring(profile.ArrowReplacementTextureId or ""),
		tostring(size.X),
		tostring(size.Y),
		tostring(size.Z),
		tostring(profile.ReplacementVersion or 1)
	}, "|")
end

local function applyBowMeshProfile(root, profile)
	if typeof(root) ~= "Instance" or not profile then return false end
	local signature = getBowMeshSignature(profile)
	if root:GetAttribute("__LionBowMeshSkin") == profile.Skin
		and root:GetAttribute("__LionBowMeshSignature") == signature
		and (root:GetAttribute("__LionBowMeshCount") or 0) > 0 then
		return true
	end

	local bodyParts, arrowParts, seenParts = {}, {}, {}
	local function collectIfTarget(obj)
		local part = getMeshLikePart(obj)
		if not part or seenParts[part] then return end
		if meshMatchesAnyAssetId(obj, profile.BodyMeshIds) then
			seenParts[part] = true
			table.insert(bodyParts, part)
		elseif meshMatchesAnyAssetId(obj, profile.ArrowMeshIds) then
			seenParts[part] = true
			table.insert(arrowParts, part)
		end
	end

	collectIfTarget(root)
	for _, obj in ipairs(root:GetDescendants()) do
		collectIfTarget(obj)
	end

	local applied = 0
	if createBowReplacementMeshPart(root, bodyParts, "__LionCustomBowBody", profile.BodyReplacementMeshId, profile.BodyReplacementTextureId, profile) then
		applied += 1
	end
	if createBowReplacementMeshPart(root, arrowParts, "__LionCustomBowArrow", profile.ArrowReplacementMeshId, profile.ArrowReplacementTextureId, profile) then
		applied += 1
	end

	root:SetAttribute("__LionBowMeshSkin", profile.Skin)
	root:SetAttribute("__LionBowMeshSignature", signature)
	root:SetAttribute("__LionBowMeshCount", applied)
	return applied > 0
end

local function hideAssaultRifleMeshAnchor(part, anchorType)
	if not (part and part:IsA("BasePart")) then return false end
	part.Transparency = 1
	part.LocalTransparencyModifier = 1
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Massless = true
	pcall(function() part.CastShadow = false end)
	pcall(function() part.Size = Vector3.new(0.001, 0.001, 0.001) end)
	part:SetAttribute("__LionAssaultRifleHiddenAnchor", true)
	part:SetAttribute("__LionAssaultRifleAnchorType", anchorType or "Part")
	part:SetAttribute("IgnoreObject", true)
	part:SetAttribute("IgnoreTransparency", true)
	pcall(function() part:RemoveTag("Wrappable") end)
	pcall(function() collectionService:RemoveTag(part, "Wrappable") end)
	if part:IsA("MeshPart") then
		pcall(function() part.TextureID = "" end)
		pcall(function() part.MeshId = "" end)
	end
	for _, child in ipairs(part:GetDescendants()) do
		if child:IsA("Decal") or child:IsA("Texture") then
			child.Transparency = 1
		elseif child:IsA("SurfaceAppearance") then
			child:Destroy()
		elseif child:IsA("SpecialMesh") then
			child.Scale = Vector3.zero
			pcall(function() child.MeshId = "" end)
			pcall(function() child.TextureId = "" end)
		elseif child:IsA("Highlight") then
			child.Enabled = false
		end
	end
	return true
end

local function createAssaultRifleReplacementMeshPart(root, anchor, replacementName, meshId, textureId, cframe, profile)
	if not (anchor and anchor:IsA("BasePart")) then return false end
	local parent = anchor.Parent or root
	if not parent then return false end

	local replacement = Instance.new("MeshPart")
	replacement.Name = replacementName
	replacement.Size = profile.ReplacementSize or Vector3.new(0.35, 0.35, 0.35)
	replacement.CFrame = cframe or anchor.CFrame
	replacement.Anchored = anchor.Anchored
	replacement.CanCollide = false
	replacement.CanTouch = false
	replacement.CanQuery = false
	replacement.Massless = true
	replacement.Transparency = 0
	replacement.LocalTransparencyModifier = 0
	replacement.Color = Color3.fromRGB(255, 255, 255)
	pcall(function() replacement.MeshId = meshId end)
	pcall(function() replacement.TextureID = textureId or "" end)
	pcall(function() replacement.Material = anchor.Material end)
	pcall(function() replacement.CastShadow = false end)
	replacement:SetAttribute("__LionCustomAssaultRifleMesh", true)
	replacement:SetAttribute("__LionAssaultRifleReplacementMeshPart", true)
	replacement:SetAttribute("IgnoreTransparency", true)

	local wrapGroup = anchor:GetAttribute("WrapGroup")
	if wrapGroup ~= nil then
		replacement:SetAttribute("WrapGroup", wrapGroup)
	end
	pcall(function()
		if collectionService:HasTag(anchor, "Wrappable") then
			collectionService:AddTag(replacement, "Wrappable")
		end
	end)
	replacement.Parent = parent

	if not replacement.Anchored then
		local weld = Instance.new("WeldConstraint")
		weld.Name = "__LionAssaultRifleReplacementWeld"
		weld.Part0 = anchor
		weld.Part1 = replacement
		weld.Parent = replacement
	end

	return true
end

local function getAssaultRifleMeshSignature(profile)
	local size = profile.ReplacementSize or Vector3.zero
	local replacementOffset = profile.ReplacementOffset or Vector3.zero
	local magazineOffset = profile.MagazineOffset or Vector3.zero
	return table.concat({
		table.concat(profile.BodyMeshIds or {}, ","),
		table.concat(profile.BoltMeshIds or {}, ","),
		table.concat(profile.MagazineMeshIds or {}, ","),
		table.concat(profile.ReloadMagazineMeshIds or {}, ","),
		tostring(profile.BodyReplacementMeshId or ""),
		tostring(profile.BodyReplacementTextureId or ""),
		tostring(profile.MagazineReplacementMeshId or ""),
		tostring(profile.MagazineReplacementTextureId or ""),
		tostring(profile.ReloadMagazineReplacementMeshId or ""),
		tostring(profile.ReloadMagazineReplacementTextureId or ""),
		tostring(size.X),
		tostring(size.Y),
		tostring(size.Z),
		tostring(replacementOffset.X),
		tostring(replacementOffset.Y),
		tostring(replacementOffset.Z),
		tostring(magazineOffset.X),
		tostring(magazineOffset.Y),
		tostring(magazineOffset.Z),
		tostring(profile.ReplacementVersion or 1)
	}, "|")
end

local function applyAssaultRifleMeshProfile(root, profile)
	if typeof(root) ~= "Instance" or not profile then return false end
	local signature = getAssaultRifleMeshSignature(profile)
	if root:GetAttribute("__LionAssaultRifleMeshSkin") == profile.Skin
		and root:GetAttribute("__LionAssaultRifleMeshSignature") == signature
		and (root:GetAttribute("__LionAssaultRifleMeshCount") or 0) > 0 then
		return true
	end

	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant:GetAttribute("__LionAssaultRifleReplacementMeshPart") then
			descendant:Destroy()
		end
	end

	local bodyParts, magazineParts, reloadMagazineParts, boltParts, seenParts = {}, {}, {}, {}, {}
	local function collectIfTarget(obj)
		local part = getMeshLikePart(obj)
		if not part or seenParts[part] then return end
		local previousType = part:GetAttribute("__LionAssaultRifleAnchorType")
		local isReloadMagazine = previousType == "ReloadMagazine"
			or (meshMatchesAnyAssetId(obj, profile.ReloadMagazineMeshIds) and namePathContains(obj, "reload"))
		if previousType == "Body" or meshMatchesAnyAssetId(obj, profile.BodyMeshIds) then
			seenParts[part] = true
			table.insert(bodyParts, part)
		elseif isReloadMagazine then
			seenParts[part] = true
			table.insert(reloadMagazineParts, part)
		elseif previousType == "Magazine" or meshMatchesAnyAssetId(obj, profile.MagazineMeshIds) or meshMatchesAnyAssetId(obj, profile.ReloadMagazineMeshIds) then
			seenParts[part] = true
			table.insert(magazineParts, part)
		elseif previousType == "Bolt" or meshMatchesAnyAssetId(obj, profile.BoltMeshIds) then
			seenParts[part] = true
			table.insert(boltParts, part)
		end
	end

	collectIfTarget(root)
	for _, obj in ipairs(root:GetDescendants()) do
		collectIfTarget(obj)
	end

	local bodyAnchor = bodyParts[1] or magazineParts[1] or boltParts[1]
	local magazineAnchor = magazineParts[1] or bodyAnchor
	local reloadMagazineAnchor = reloadMagazineParts[1] or magazineAnchor
	local bodyCFrame = bodyParts[1] and getReplacementAverageCFrame(bodyParts) or (bodyAnchor and bodyAnchor.CFrame) or CFrame.identity
	local reloadMagazineCFrame = reloadMagazineParts[1] and getReplacementAverageCFrame(reloadMagazineParts) or bodyCFrame
	local replacementOffset = profile.ReplacementOffset or Vector3.zero
	local magazineOffset = profile.MagazineOffset or Vector3.zero
	bodyCFrame = bodyCFrame * CFrame.new(replacementOffset)
	reloadMagazineCFrame = reloadMagazineCFrame * CFrame.new(replacementOffset)
	local applied = 0
	if createAssaultRifleReplacementMeshPart(root, bodyAnchor, "__LionCustomAssaultRifleBody", profile.BodyReplacementMeshId, profile.BodyReplacementTextureId, bodyCFrame, profile) then
		applied += 1
	end
	if createAssaultRifleReplacementMeshPart(root, magazineAnchor, "__LionCustomAssaultRifleMagazine", profile.MagazineReplacementMeshId, profile.MagazineReplacementTextureId, bodyCFrame * CFrame.new(magazineOffset), profile) then
		applied += 1
	end
	if reloadMagazineParts[1] and createAssaultRifleReplacementMeshPart(root, reloadMagazineAnchor, "__LionCustomAssaultRifleReloadMagazine", profile.ReloadMagazineReplacementMeshId or profile.MagazineReplacementMeshId, profile.ReloadMagazineReplacementTextureId or profile.MagazineReplacementTextureId, reloadMagazineCFrame, profile) then
		applied += 1
	end

	for _, part in ipairs(bodyParts) do
		hideAssaultRifleMeshAnchor(part, "Body")
	end
	for _, part in ipairs(magazineParts) do
		hideAssaultRifleMeshAnchor(part, "Magazine")
	end
	for _, part in ipairs(reloadMagazineParts) do
		hideAssaultRifleMeshAnchor(part, "ReloadMagazine")
	end
	for _, part in ipairs(boltParts) do
		hideAssaultRifleMeshAnchor(part, "Bolt")
	end

	root:SetAttribute("__LionAssaultRifleMeshSkin", profile.Skin)
	root:SetAttribute("__LionAssaultRifleMeshSignature", signature)
	root:SetAttribute("__LionAssaultRifleMeshCount", applied)
	return applied > 0
end

local function __LionHideSniperMeshAnchor(part, anchorType)
	if not (part and part:IsA("BasePart")) then return false end
	part.Transparency = 1
	part.LocalTransparencyModifier = 1
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Massless = true
	pcall(function() part.CastShadow = false end)
	pcall(function() part.Material = Enum.Material.SmoothPlastic end)
	pcall(function() part.Reflectance = 0 end)
	pcall(function() part.Size = Vector3.new(0.001, 0.001, 0.001) end)
	part:SetAttribute("__LionHiddenSniperMesh", true)
	part:SetAttribute("__LionCustomSniperHiddenPart", true)
	part:SetAttribute("__LionSniperAnchorType", anchorType or "Part")
	part:SetAttribute("IgnoreObject", true)
	part:SetAttribute("IgnoreTransparency", true)
	part:SetAttribute("WrapGroup", 0)
	pcall(function() part:RemoveTag("Wrappable") end)
	pcall(function() collectionService:RemoveTag(part, "Wrappable") end)
	if part:IsA("MeshPart") then
		pcall(function() part.TextureID = "" end)
		pcall(function() part.MeshId = "" end)
	end
	for _, child in ipairs(part:GetDescendants()) do
		if child:IsA("Decal") or child:IsA("Texture") then
			child.Transparency = 1
		elseif child:IsA("SurfaceAppearance") then
			child:Destroy()
		elseif child:IsA("SpecialMesh") then
			child.Scale = Vector3.zero
			pcall(function() child.MeshId = "" end)
			pcall(function() child.TextureId = "" end)
		elseif child:IsA("Highlight") then
			child.Enabled = false
		end
	end
	return true
end

local function __LionOffsetSniperVisibleAnchor(part, anchorType, offset)
	if not (part and part:IsA("BasePart")) then return false end
	local originalCFrame = part:GetAttribute("__LionSniperOriginalCFrame")
	if typeof(originalCFrame) ~= "CFrame" then
		originalCFrame = part.CFrame
		part:SetAttribute("__LionSniperOriginalCFrame", originalCFrame)
	end
	part.CFrame = originalCFrame * CFrame.new(offset or Vector3.zero)
	part:SetAttribute("__LionSniperAnchorType", anchorType or "Part")
	part:SetAttribute("__LionSniperVisibleOffset", true)
	return true
end

local function hideSniperMeshId(root, assetId)
	local parts = {}
	if typeof(root) ~= "Instance" or not assetId then return parts end
	local seen = {}

	local function hideIfMatch(obj)
		if not meshMatchesAssetId(obj, assetId) then return end
		local part = getMeshLikePart(obj)
		if part and not seen[part] then
			seen[part] = true
			if __LionHideSniperMeshAnchor(part) then
				table.insert(parts, part)
			end
		elseif obj:IsA("SpecialMesh") then
			obj.Scale = Vector3.zero
		end
	end

	hideIfMatch(root)
	for _, obj in ipairs(root:GetDescendants()) do
		hideIfMatch(obj)
	end
	return parts
end

local function getAverageCFrame(parts)
	local first = parts[1]
	if not first then return CFrame.identity end
	local position = Vector3.zero
	for _, part in ipairs(parts) do
		position += part.Position
	end
	position /= #parts
	return CFrame.new(position) * (first.CFrame - first.CFrame.Position)
end

local function __LionCreateSniperReplacementMeshPart(root, anchor, replacementName, meshId, textureId, cframe, profile)
	if not (anchor and anchor:IsA("BasePart")) then return false end
	local parent = anchor.Parent or root
	if not parent then return false end

	local replacement = Instance.new("MeshPart")
	replacement.Name = replacementName
	pcall(function() replacement.MeshId = meshId end)
	pcall(function() replacement.TextureID = textureId or "" end)
	replacement.Size = profile.ReplacementSize or Vector3.new(0.05, 0.05, 0.05)
	replacement.CFrame = cframe or anchor.CFrame
	replacement.Anchored = anchor.Anchored
	replacement.CanCollide = false
	replacement.CanTouch = false
	replacement.CanQuery = false
	replacement.Massless = true
	replacement.Transparency = 0
	replacement.LocalTransparencyModifier = 0
	replacement.Color = Color3.fromRGB(255, 255, 255)
	pcall(function() replacement.Material = anchor.Material end)
	pcall(function() replacement.CastShadow = false end)
	replacement:SetAttribute("__LionCustomSniperReplacement", true)
	replacement:SetAttribute("WrapGroup", 1)
	replacement:SetAttribute("IgnoreTransparency", true)
	pcall(function() replacement:AddTag("Wrappable") end)
	pcall(function() collectionService:AddTag(replacement, "Wrappable") end)
	replacement.Parent = parent

	if not replacement.Anchored then
		local weld = Instance.new("WeldConstraint")
		weld.Name = "__LionCustomSniperReplacementWeld"
		weld.Part0 = anchor
		weld.Part1 = replacement
		weld.Parent = replacement
	end
	return true
end

local function setupSniperReplacementPart(root, profile, bodyParts)
	local anchor = bodyParts[1]
	if not anchor then return false end
	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant:GetAttribute("__LionCustomSniperReplacement") then
			descendant:Destroy()
		end
	end

	return __LionCreateSniperReplacementMeshPart(
		root,
		anchor,
		"__LionCustomSniperReplacement",
		profile.ReplacementMeshId,
		profile.ReplacementTextureId,
		getAverageCFrame(bodyParts) * CFrame.new(profile.ReplacementOffset or Vector3.zero),
		profile
	)
end

local function getSniperMeshSignature(profile)
	local body = table.concat(profile.BodyMeshIds or {}, ",")
	local remove = table.concat(profile.RemoveMeshIds or {}, ",")
	local magazine = table.concat(profile.MagazineMeshIds or {}, ",")
	local bullet = table.concat(profile.BulletMeshIds or {}, ",")
	local size = profile.ReplacementSize or Vector3.zero
	local offset = profile.ReplacementOffset or Vector3.zero
	local bulletOffset = profile.BulletOffset or Vector3.zero
	return table.concat({
		body,
		remove,
		magazine,
		bullet,
		tostring(profile.ReplacementMeshId or ""),
		tostring(profile.ReplacementTextureId or ""),
		tostring(profile.BodyReplacementMeshId or ""),
		tostring(profile.BodyReplacementTextureId or ""),
		tostring(profile.ScopeReplacementMeshId or ""),
		tostring(profile.ScopeReplacementTextureId or ""),
		tostring(profile.MagazineReplacementMeshId or ""),
		tostring(profile.MagazineReplacementTextureId or ""),
		tostring(size.X),
		tostring(size.Y),
		tostring(size.Z),
		tostring(offset.X),
		tostring(offset.Y),
		tostring(offset.Z),
		tostring((profile.ScopeOffset or Vector3.zero).X),
		tostring((profile.ScopeOffset or Vector3.zero).Y),
		tostring((profile.ScopeOffset or Vector3.zero).Z),
		tostring((profile.MagazineOffset or Vector3.zero).X),
		tostring((profile.MagazineOffset or Vector3.zero).Y),
		tostring((profile.MagazineOffset or Vector3.zero).Z),
		tostring(bulletOffset.X),
		tostring(bulletOffset.Y),
		tostring(bulletOffset.Z),
		tostring(profile.ReplacementVersion or 1)
	}, "|")
end

local function __LionApplySniperMultiMeshProfile(root, profile)
	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant:GetAttribute("__LionCustomSniperReplacement") then
			descendant:Destroy()
		end
	end

	local bodyParts, magazineParts, bulletParts, removeParts, seenParts = {}, {}, {}, {}, {}
	local function collectIfTarget(obj)
		local part = getMeshLikePart(obj)
		if not part or seenParts[part] then return end
		local previousType = part:GetAttribute("__LionSniperAnchorType")
		if previousType == "Body" or meshMatchesAnyAssetId(obj, profile.BodyMeshIds) then
			seenParts[part] = true
			table.insert(bodyParts, part)
		elseif previousType == "Magazine" or meshMatchesAnyAssetId(obj, profile.MagazineMeshIds) then
			seenParts[part] = true
			table.insert(magazineParts, part)
		elseif previousType == "Bullet" or meshMatchesAnyAssetId(obj, profile.BulletMeshIds) then
			seenParts[part] = true
			table.insert(bulletParts, part)
		elseif previousType == "Remove" or meshMatchesAnyAssetId(obj, profile.RemoveMeshIds) then
			seenParts[part] = true
			table.insert(removeParts, part)
		end
	end

	collectIfTarget(root)
	for _, obj in ipairs(root:GetDescendants()) do
		collectIfTarget(obj)
	end

	local bodyAnchor = bodyParts[1] or magazineParts[1]
	local magazineAnchor = magazineParts[1] or bodyAnchor
	if not bodyAnchor then return false end

	local offset = profile.ReplacementOffset or Vector3.zero
	local bodyCFrame = (bodyParts[1] and getReplacementAverageCFrame(bodyParts) or bodyAnchor.CFrame) * CFrame.new(offset)
	local scopeCFrame = bodyCFrame * CFrame.new(profile.ScopeOffset or Vector3.zero)
	local magazineCFrame = bodyCFrame * CFrame.new(profile.MagazineOffset or Vector3.zero)
	local applied = 0
	if __LionCreateSniperReplacementMeshPart(root, bodyAnchor, "__LionCustomSniperReplacement", profile.BodyReplacementMeshId, profile.BodyReplacementTextureId, bodyCFrame, profile) then
		applied += 1
	end
	if __LionCreateSniperReplacementMeshPart(root, bodyAnchor, "__LionCustomSniperScope", profile.ScopeReplacementMeshId, profile.ScopeReplacementTextureId, scopeCFrame, profile) then
		applied += 1
	end
	if __LionCreateSniperReplacementMeshPart(root, magazineAnchor, "__LionCustomSniperMagazine", profile.MagazineReplacementMeshId, profile.MagazineReplacementTextureId, magazineCFrame, profile) then
		applied += 1
	end

	for _, part in ipairs(bodyParts) do
		__LionHideSniperMeshAnchor(part, "Body")
	end
	for _, part in ipairs(magazineParts) do
		__LionHideSniperMeshAnchor(part, "Magazine")
	end
	for _, part in ipairs(bulletParts) do
		__LionOffsetSniperVisibleAnchor(part, "Bullet", profile.BulletOffset or Vector3.zero)
	end
	for _, part in ipairs(removeParts) do
		__LionHideSniperMeshAnchor(part, "Remove")
	end
	return applied > 0
end

local function applySniperMeshProfile(root, profile)
	if typeof(root) ~= "Instance" or not profile then return false end
	local signature = getSniperMeshSignature(profile)
	if root:GetAttribute("__LionSniperMeshSkin") == profile.Skin
		and root:GetAttribute("__LionSniperMeshSignature") == signature then
		return true
	end

	local applied
	if profile.BodyReplacementMeshId or profile.ScopeReplacementMeshId or profile.MagazineReplacementMeshId then
		applied = __LionApplySniperMultiMeshProfile(root, profile)
		if not applied then return false end
		root:SetAttribute("__LionSniperMeshSkin", profile.Skin)
		root:SetAttribute("__LionSniperMeshSignature", signature)
		return true
	end

	local bodyParts = {}
	for _, meshId in ipairs(profile.BodyMeshIds or {}) do
		for _, part in ipairs(hideSniperMeshId(root, meshId)) do
			table.insert(bodyParts, part)
		end
	end
	for _, meshId in ipairs(profile.RemoveMeshIds or {}) do
		hideSniperMeshId(root, meshId)
	end

	if not setupSniperReplacementPart(root, profile, bodyParts) then
		return false
	end
	root:SetAttribute("__LionSniperMeshSkin", profile.Skin)
	root:SetAttribute("__LionSniperMeshSignature", signature)
	return true
end

local function applyTripminePartVisual(part, profile)
	if not (part and part:IsA("BasePart")) then return end
	local color = profile.Color
	if color then
		part.Color = color
		part.BrickColor = BrickColor.new(color)
	end
	part.Material = profile.Material or Enum.Material.SmoothPlastic
	if profile.Reflectance then
		part.Reflectance = profile.Reflectance
	end
	part.Transparency = 0
	part.LocalTransparencyModifier = 0
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Massless = true
	if part:GetAttribute("WrapGroup") == nil then
		part:SetAttribute("WrapGroup", 1)
	end
	part:SetAttribute("IgnoreTransparency", true)
	pcall(function() part:AddTag("Wrappable") end)
	pcall(function() collectionService:AddTag(part, "Wrappable") end)
end

local function addTripmineExtraMeshPart(basePart, meshId, meshScale, profile, index)
	if not (basePart and basePart:IsA("BasePart") and basePart.Parent) then return nil end
	local overlay = Instance.new("Part")
	overlay.Name = "__LionCustomTripmineMeshExtra" .. tostring(index or "")
	overlay.Anchored = basePart.Anchored
	overlay.CFrame = basePart.CFrame
	overlay.Size = basePart.Size
	overlay:SetAttribute("__LionCustomTripmineMeshPart", true)
	overlay:SetAttribute("__LionCustomTripmineExtraMesh", true)
	applyTripminePartVisual(overlay, profile)

	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.FileMesh
	mesh.MeshId = meshId
	if profile.ClearTexture then
		pcall(function() mesh.TextureId = "" end)
	elseif profile.TextureId then
		pcall(function() mesh.TextureId = profile.TextureId end)
	end
	mesh.Scale = meshScale
	pcall(function() mesh.VertexColor = Vector3.new(1, 1, 1) end)
	mesh.Parent = overlay
	overlay.Parent = basePart.Parent

	local weld = Instance.new("WeldConstraint")
	weld.Name = "__LionCustomTripmineMeshExtraWeld"
	weld.Part0 = basePart
	weld.Part1 = overlay
	weld.Parent = overlay
	return overlay
end

applyTripmineMeshProfile = function(root, profile, worldVisual)
	if typeof(root) ~= "Instance" then return false end
	if not profile then return false end
	local meshIds = getTripmineMeshIds(profile)
	if #meshIds == 0 then return false end
	local extraMeshScale = getTripmineExtraMeshScale(profile, worldVisual)
	local meshSignature = getTripmineMeshSignature(profile, worldVisual)
	local meshScale = (worldVisual and profile.WorldScale) or profile.Scale or 1
	if root:GetAttribute("__LionTripmineMeshSkin") == profile.Skin
		and root:GetAttribute("__LionCustomTripmineMeshIds") == meshSignature
		and root:GetAttribute("__LionCustomTripmineMeshScale") == meshScale then
		return true
	end
	removeCustomTripmineExtraMeshes(root)
	removeTripmineMeshAsset(root, profile.RemoveMeshId or profile.HideMeshId)
	local target = findCustomTripmineMeshTarget(root, profile)
	if not target then return false end
	local customPart

	if target:IsA("SpecialMesh") then
		pcall(function() target.MeshType = Enum.MeshType.FileMesh end)
		target.MeshId = meshIds[1]
		if profile.TextureId then
			pcall(function() target.TextureId = profile.TextureId end)
		elseif profile.ClearTexture then
			pcall(function() target.TextureId = "" end)
		end
		target.Scale = target.Scale * meshScale
		pcall(function() target.VertexColor = Vector3.new(1, 1, 1) end)
		customPart = target.Parent
		applyTripminePartVisual(customPart, profile)
		for index = 2, #meshIds do
			addTripmineExtraMeshPart(customPart, meshIds[index], scaleTripmineMeshVector(target.Scale, extraMeshScale), profile, index)
		end
	elseif target:IsA("MeshPart") then
		local originalSize = target.Size
		local okMesh = pcall(function()
			target.MeshId = meshIds[1]
		end)
		if profile.TextureId then
			pcall(function() target.TextureID = profile.TextureId end)
		elseif profile.ClearTexture then
			pcall(function() target.TextureID = "" end)
		end
		applyTripminePartVisual(target, profile)
		if okMesh then
			pcall(function()
				target.Size = originalSize * meshScale
			end)
			customPart = target
			for index = 2, #meshIds do
				addTripmineExtraMeshPart(target, meshIds[index], scaleTripmineMeshVector(Vector3.new(1, 1, 1), extraMeshScale), profile, index)
			end
		elseif target.Parent then
			pcall(function()
				target.Transparency = 1
				target.LocalTransparencyModifier = 1
			end)
			local overlay = target.Parent:FindFirstChild("__LionCustomTripmineMesh")
			if not (overlay and overlay:IsA("BasePart")) then
				overlay = Instance.new("Part")
				overlay.Name = "__LionCustomTripmineMesh"
				overlay.Anchored = target.Anchored
				overlay.CanCollide = false
				overlay.CanTouch = false
				overlay.CanQuery = false
				overlay.Massless = true
				overlay.Parent = target.Parent
			end
			overlay.Size = originalSize
			overlay.CFrame = target.CFrame
			applyTripminePartVisual(overlay, profile)
			local mesh = overlay:FindFirstChildOfClass("SpecialMesh") or Instance.new("SpecialMesh")
			mesh.MeshType = Enum.MeshType.FileMesh
			mesh.MeshId = meshIds[1]
			if profile.TextureId then
				pcall(function() mesh.TextureId = profile.TextureId end)
			elseif profile.ClearTexture then
				pcall(function() mesh.TextureId = "" end)
			end
			mesh.Scale = Vector3.new(meshScale, meshScale, meshScale)
			pcall(function() mesh.VertexColor = Vector3.new(1, 1, 1) end)
			mesh.Parent = overlay
			overlay:SetAttribute("__LionCustomTripmineMeshPart", true)
			customPart = overlay
			for index = 2, #meshIds do
				addTripmineExtraMeshPart(overlay, meshIds[index], scaleTripmineMeshVector(meshScale, extraMeshScale), profile, index)
			end
			if not overlay:FindFirstChild("__LionCustomTripmineMeshWeld") then
				local weld = Instance.new("WeldConstraint")
				weld.Name = "__LionCustomTripmineMeshWeld"
				weld.Part0 = target
				weld.Part1 = overlay
				weld.Parent = overlay
			end
		end
	end

	if customPart and customPart:IsA("BasePart") then
		customPart:SetAttribute("__LionCustomTripmineMeshPart", true)
	end
	root:SetAttribute("__LionTripmineMeshSkin", profile.Skin)
	root:SetAttribute("__LionCustomTripmineMeshId", meshIds[1])
	root:SetAttribute("__LionCustomTripmineMeshIds", meshSignature)
	root:SetAttribute("__LionCustomTripmineMeshScale", meshScale)
	return true
end

local function applyVirtualViewModelAssetOverrides(cosmeticName, asset, worldAsset)
	local profile = TRIPMINE_MESH_SKIN_OVERRIDES[cosmeticName]
	if profile then
		applyTripmineMeshProfile(asset, profile)
	end
	local daggerProfile = DAGGERS_MESH_SKIN_OVERRIDES[cosmeticName]
	if daggerProfile then
		applyDaggerMeshProfile(asset, daggerProfile)
	end
	local satchelProfile = getSatchelMeshProfileForAsset(cosmeticName, worldAsset)
	if satchelProfile then
		applySatchelMeshProfile(asset, satchelProfile)
	end
	local rpgProfile = RPG_MESH_SKIN_OVERRIDES[cosmeticName]
	if rpgProfile then
		applyRpgMeshProfile(asset, rpgProfile)
	end
	local fistsProfile = FISTS_MESH_SKIN_OVERRIDES[cosmeticName]
	if fistsProfile then
		applyFistsMeshProfile(asset, fistsProfile)
	end
	local bowProfile = BOW_MESH_SKIN_OVERRIDES[cosmeticName]
	if bowProfile then
		applyBowMeshProfile(asset, bowProfile)
	end
	local assaultRifleProfile = ASSAULT_RIFLE_MESH_SKIN_OVERRIDES[cosmeticName]
	if assaultRifleProfile then
		applyAssaultRifleMeshProfile(asset, assaultRifleProfile)
	end
	local sniperProfile = SNIPER_MESH_SKIN_OVERRIDES[cosmeticName]
	if sniperProfile then
		applySniperMeshProfile(asset, sniperProfile)
	end
end

local function shouldRebuildVirtualViewModelAsset(cosmeticName, asset, worldAsset)
	local profile = TRIPMINE_MESH_SKIN_OVERRIDES[cosmeticName]
	if profile then
		local meshIds = getTripmineMeshIds(profile)
		return not asset
			or asset:GetAttribute("__LionTripmineMeshSkin") ~= profile.Skin
			or asset:GetAttribute("__LionCustomTripmineMeshIds") ~= getTripmineMeshSignature(profile)
			or asset:GetAttribute("__LionCustomTripmineMeshScale") ~= (profile.Scale or 1)
			or asset:GetAttribute("__LionCustomTripmineMeshId") ~= meshIds[1]
	end
	local sniperProfile = SNIPER_MESH_SKIN_OVERRIDES[cosmeticName]
	if sniperProfile then
		return not asset
			or asset:GetAttribute("__LionSniperMeshSkin") ~= sniperProfile.Skin
			or asset:GetAttribute("__LionSniperMeshSignature") ~= getSniperMeshSignature(sniperProfile)
			or not asset:FindFirstChild("__LionCustomSniperReplacement", true)
	end
	local daggerProfile = DAGGERS_MESH_SKIN_OVERRIDES[cosmeticName]
	if daggerProfile then
		return not asset
			or asset:GetAttribute("__LionDaggerMeshSkin") ~= daggerProfile.Skin
			or asset:GetAttribute("__LionDaggerMeshSignature") ~= getDaggerMeshSignature(daggerProfile)
			or (asset:GetAttribute("__LionDaggerMeshCount") or 0) <= 0
	end
	local satchelProfile = getSatchelMeshProfileForAsset(cosmeticName, worldAsset)
	if satchelProfile then
		return not asset
			or asset:GetAttribute("__LionSatchelMeshSkin") ~= satchelProfile.Skin
			or asset:GetAttribute("__LionSatchelMeshSignature") ~= getSatchelMeshSignature(satchelProfile)
			or (asset:GetAttribute("__LionSatchelMeshCount") or 0) <= 0
	end
	local rpgProfile = RPG_MESH_SKIN_OVERRIDES[cosmeticName]
	if rpgProfile then
		return not asset
			or asset:GetAttribute("__LionRpgMeshSkin") ~= rpgProfile.Skin
			or asset:GetAttribute("__LionRpgMeshSignature") ~= getRpgMeshSignature(rpgProfile)
			or asset:GetAttribute("__LionRpgRocketVisible") ~= false
			or ((asset:GetAttribute("__LionRpgMeshCount") or 0) + (asset:GetAttribute("__LionRpgHiddenCount") or 0)) <= 0
	end
	local fistsProfile = FISTS_MESH_SKIN_OVERRIDES[cosmeticName]
	if fistsProfile then
		return not asset
			or asset:GetAttribute("__LionFistsMeshSkin") ~= fistsProfile.Skin
			or asset:GetAttribute("__LionFistsMeshSignature") ~= getFistsMeshSignature(fistsProfile)
			or (asset:GetAttribute("__LionFistsMeshCount") or 0) <= 0
	end
	local bowProfile = BOW_MESH_SKIN_OVERRIDES[cosmeticName]
	if bowProfile then
		return not asset
			or asset:GetAttribute("__LionBowMeshSkin") ~= bowProfile.Skin
			or asset:GetAttribute("__LionBowMeshSignature") ~= getBowMeshSignature(bowProfile)
			or (asset:GetAttribute("__LionBowMeshCount") or 0) <= 0
	end
	local assaultRifleProfile = ASSAULT_RIFLE_MESH_SKIN_OVERRIDES[cosmeticName]
	if assaultRifleProfile then
		return not asset
			or asset:GetAttribute("__LionAssaultRifleMeshSkin") ~= assaultRifleProfile.Skin
			or asset:GetAttribute("__LionAssaultRifleMeshSignature") ~= getAssaultRifleMeshSignature(assaultRifleProfile)
			or (asset:GetAttribute("__LionAssaultRifleMeshCount") or 0) <= 0
	end
	return cosmeticName == DICE_TRIPMINE_SKIN
		and asset
		and asset:GetAttribute("__LionRightArmRetargeted")
end

local function ensureVirtualViewModel(cosmeticName, itemName, viewModelName)
	local sourceInfo = ilib.ViewModels and ilib.ViewModels[viewModelName]
	if not sourceInfo then return nil end

	if cosmeticName ~= viewModelName then
		local usesSourceAnimations = SNIPER_MESH_SKIN_OVERRIDES[cosmeticName] or DAGGERS_MESH_SKIN_OVERRIDES[cosmeticName] or SATCHEL_MESH_SKIN_OVERRIDES[cosmeticName] or RPG_MESH_SKIN_OVERRIDES[cosmeticName] or FISTS_MESH_SKIN_OVERRIDES[cosmeticName] or BOW_MESH_SKIN_OVERRIDES[cosmeticName] or ASSAULT_RIFLE_MESH_SKIN_OVERRIDES[cosmeticName] or cosmeticName == KNIFE_CUSTOM_SKIN or cosmeticName == "Grenade (Custom Skin)" or cosmeticName == "Molotov (Custom Skin)" or cosmeticName == "Satchel (Custom Skin)" or cosmeticName == "Smoke Grenade (Custom Skin)" or cosmeticName == "Warpstone (Custom Skin)" or cosmeticName == "sky"
		local animationInfo = usesSourceAnimations and sourceInfo or ilib.ViewModels[itemName]
		local baseInfo = animationInfo or sourceInfo
		local virtualInfo = table.clone(sourceInfo)
		if type(baseInfo.Animations) == "table" then
			virtualInfo.Animations = table.clone(baseInfo.Animations)
		end
		ilib.ViewModels[cosmeticName] = virtualInfo

		pcall(function()
			local viewModelAssets = lps.Assets and lps.Assets:FindFirstChild("ViewModels")
			if not viewModelAssets then return end
			local existingAsset = findDescendantByName(viewModelAssets, cosmeticName)
			if existingAsset then
				if shouldRebuildVirtualViewModelAsset(cosmeticName, existingAsset, false) then
					existingAsset:Destroy()
				else
					applyVirtualViewModelAssetOverrides(cosmeticName, existingAsset, false)
					return
				end
			end

			local sourceAsset = findDescendantByName(viewModelAssets, viewModelName)
			if sourceAsset then
				local clonedAsset = sourceAsset:Clone()
				clonedAsset.Name = cosmeticName
				applyVirtualViewModelAssetOverrides(cosmeticName, clonedAsset, false)
				clonedAsset.Parent = viewModelAssets
			end
		end)

		pcall(function()
			local throwables = lps.Assets and lps.Assets:FindFirstChild("Throwables")
			if not throwables then return end
			local existingThrowable = throwables:FindFirstChild(cosmeticName)
			if existingThrowable then
				if shouldRebuildVirtualViewModelAsset(cosmeticName, existingThrowable, true) then
					existingThrowable:Destroy()
				else
					applyVirtualViewModelAssetOverrides(cosmeticName, existingThrowable, true)
					return
				end
			end
			local sourceThrowable = findDescendantByName(throwables, viewModelName)
			if sourceThrowable then
				local clonedThrowable = sourceThrowable:Clone()
				clonedThrowable.Name = cosmeticName
				applyVirtualViewModelAssetOverrides(cosmeticName, clonedThrowable, true)
				clonedThrowable.Parent = throwables
			end
		end)

		pcall(function()
			if itemName ~= "Jump Pad" then return end
			local misc = lps.Assets and lps.Assets:FindFirstChild("Misc")
			local jumpPads = misc and misc:FindFirstChild("JumpPads")
			if not jumpPads then return end
			local existingJumpPad = jumpPads:FindFirstChild(cosmeticName)
			if existingJumpPad then
				if shouldRebuildVirtualViewModelAsset(cosmeticName, existingJumpPad, true) then
					existingJumpPad:Destroy()
				else
					applyVirtualViewModelAssetOverrides(cosmeticName, existingJumpPad, true)
					return
				end
			end
			local sourceJumpPad = jumpPads:FindFirstChild(viewModelName) or jumpPads:FindFirstChild("Default")
			if sourceJumpPad then
				local clonedJumpPad = sourceJumpPad:Clone()
				clonedJumpPad.Name = cosmeticName
				applyVirtualViewModelAssetOverrides(cosmeticName, clonedJumpPad, true)
				clonedJumpPad.Parent = jumpPads
			end
		end)
	end

	return sourceInfo
end

local function registerVirtualWeaponSkin(cosmeticName, itemName, viewModelName, rarity, displayName, worldViewModelName)
	local viewModelInfo = ensureVirtualViewModel(cosmeticName, itemName, viewModelName)
	if not viewModelInfo then return end
	local imageInfo = cosmeticName == DICE_TRIPMINE_SKIN and ilib.ViewModels and ilib.ViewModels["RNG Dice"] or viewModelInfo
	local image = imageInfo.Image or ""
	local imageHighResolution = imageInfo.ImageHighResolution or imageInfo.Image or ""
	local imageOverride = CUSTOM_SKIN_IMAGE_OVERRIDES[cosmeticName]
	if imageOverride then
		image = imageOverride.Image or ""
		imageHighResolution = imageOverride.ImageHighResolution or imageOverride.Image or ""
	end

	if ilib.ViewModels and ilib.ViewModels[cosmeticName] then
		ilib.ViewModels[cosmeticName].Image = image
		ilib.ViewModels[cosmeticName].ImageHighResolution = imageHighResolution
	end

	coss[cosmeticName] = {
		Rarity = rarity or "Contraband",
		Type = "Skin",
		DisplayName = displayName or cosmeticName,
		ViewModelName = cosmeticName,
		SourceViewModelName = viewModelName,
		WorldViewModelName = worldViewModelName or viewModelName,
		Image = image,
		ImageHighResolution = imageHighResolution,
		ImageScale = 3,
		ItemName = itemName,
		Owned = true,
		Unlocked = true,
		Locked = false
	}
end

local function registerVirtualWeaponSkins()
	coss["Flashbang (Custom Skin)"] = nil
	if ilib.ViewModels then
		ilib.ViewModels["Flashbang (Custom Skin)"] = nil
	end
	registerVirtualWeaponSkin(KNIFE_CUSTOM_SKIN, "Knife", "Glast Shard", "Contraband")
	registerVirtualWeaponSkin(REAVER_KNIFE_CUSTOM_SKIN, "Knife", "Pencil", "Contraband", "reaver")
	registerVirtualWeaponSkin(DAGGERS_CUSTOM_SKIN, "Daggers", "Keynais", "Contraband")
	registerVirtualWeaponSkin("Grenade (Custom Skin)", "Grenade", "Elixir", "Contraband")
	registerVirtualWeaponSkin("Grenade Raze", "Grenade", "Glorious Grenade", "Contraband", "Raze")
	registerVirtualWeaponSkin("sky", "Flashbang", "Shining Star", "Contraband")
	registerVirtualWeaponSkin("Molotov (Custom Skin)", "Molotov", "Elixir", "Contraband", "Elixir")
	registerVirtualWeaponSkin("Satchel (Custom Skin)", "Satchel", "Elixir", "Contraband")
	registerVirtualWeaponSkin(SATCHEL_CUSTOM_SKIN, "Satchel", "Satchel", "Contraband", "Raze", SATCHEL_CUSTOM_SKIN)
	registerVirtualWeaponSkin("Smoke Grenade (Custom Skin)", "Smoke Grenade", "Elixir", "Contraband")
	registerVirtualWeaponSkin("Warpstone (Custom Skin)", "Warpstone", "Elixir", "Contraband")
	registerVirtualWeaponSkin("Scythe (Custom Skin)", "Scythe", "Scepter", "Contraband")
	registerVirtualWeaponSkin("Katana (Custom Skin)", "Katana", "Scepter", "Contraband")
	registerVirtualWeaponSkin("Spear (Custom Skin)", "Spear", "Scepter", "Contraband")
	registerVirtualWeaponSkin("Handgun (Custom Skin)", "Handgun", "Glass Cannon", "Contraband")
	registerVirtualWeaponSkin(SNIPER_CUSTOM_SKIN, "Sniper", "Keyper", "Contraband")
	registerVirtualWeaponSkin("Operator", "Sniper", "Sniper", "Contraband")
	registerVirtualWeaponSkin("Medkit (Custom Skin)", "Medkit", "RNG Dice", "Contraband")
	registerVirtualWeaponSkin(RPG_CUSTOM_SKIN, "RPG", "Nuke Launcher", "Contraband", "Raze", RPG_CUSTOM_SKIN)
	registerVirtualWeaponSkin(FISTS_CUSTOM_SKIN, "Fists", "Fists", "Contraband", "Agent")
	registerVirtualWeaponSkin(BOW_CUSTOM_SKIN, "Bow", "Frostbite Bow", "Contraband")
	registerVirtualWeaponSkin(ASSAULT_RIFLE_CUSTOM_SKIN, "Assault Rifle", "AK-47", "Contraband")
	registerVirtualWeaponSkin("Camera", "Jump Pad", "Jump Pad", "Contraband", "Camera", "Camera")
	registerVirtualWeaponSkin(DICE_TRIPMINE_SKIN, "Subspace Tripmine", "Subspace Tripmine", "Contraband", nil, DICE_TRIPMINE_SKIN)
	registerVirtualWeaponSkin(SPIKE_TRIPMINE_SKIN, "Subspace Tripmine", "Subspace Tripmine", "Contraband", "Spike", SPIKE_TRIPMINE_SKIN)
end

registerVirtualWeaponSkins()
end)() -- mesh/skin helpers

local cdata = dctrl.CurrentData
if not cdata then
	task.spawn(function()
		repeat task.wait() until dctrl.CurrentData
		cdata = dctrl.CurrentData
	end)
end

local equip, favs = {}, {}
local cwep, _vprof, _lwep
local _lpname = lp.Name
local fcache = {}

local function banned(n)
	if type(n) ~= "string" then return true end
	return n:find("MISSING_") or n:find("Bubblegum") or n:find("Ragdoll") or n:find("Fall Apart") or n:find("Every Finisher Ever")
end

local function toenum(n)
	if not elib then return nil end
	local ok, id = pcall(elib.ToEnum, elib, n)
	return ok and id or nil
end

local function clonecos(name, ctype, inv, favonly)
	if banned(name) then return nil end
	local base = coss[name]
	if not base then return nil end
	local d = table.clone(base)
	d.Name = name
	d.Type = d.Type or ctype
	d.Seed = d.Seed or math.random(1, 1000000)
	d.Owned = true
	d.Unlocked = true
	d.Locked = false
	d.Amount = math.max(1, tonumber(d.Amount) or 1)
	d.Count = math.max(1, tonumber(d.Count) or 1)
	local eid = toenum(name)
	if eid then d.Enum = eid; d.ObjectID = d.ObjectID or eid end
	if inv ~= nil then d.Inverted = inv end
	if favonly ~= nil then d.OnlyUseFavorites = favonly end
	return d
end

-- savecfg and loadcfg removed

local finv = {}
local function rebuildinv()
	table.clear(finv)
	for _, cos in equip do
		for _, cd in cos do
			if cd and cd.Name and not banned(cd.Name) then
				finv[cd.Name] = cd
			end
		end
	end
end

rebuildinv()

local oget = dctrl.Get
dctrl.Get = function(self, key)
	local data = oget(self, key)
	if key == "CosmeticInventory" then
		local proxy = {}
		if data then for k, v in data do if not banned(k) then proxy[k] = v end end end
		for name, cosmetic in finv do
			if proxy[name] == nil or type(proxy[name]) == "boolean" then
				proxy[name] = cosmetic
			end
		end
		return proxy
	end
	if key == "FavoritedCosmetics" then
		local res = data and table.clone(data) or {}
		for wep, fv in favs do
			local slot = res[wep] or {}
			res[wep] = slot
			for name, isfav in fv do
				if not banned(name) then slot[name] = isfav end
			end
		end
		return res
	end
	return data
end

local ogetwep = dctrl.GetWeaponData
dctrl.GetWeaponData = function(self, wname)
	local data = ogetwep(self, wname)
	if not data then return nil end
	local merged = table.clone(data)
	merged.Name = wname
	local weq = equip[wname]
	if weq then for ct, cd in weq do merged[ct] = cd end end
	return merged
end

local function saferep(key)
	pcall(function()
		if not cdata and dctrl.CurrentData then cdata = dctrl.CurrentData end
		if cdata then cdata:Replicate(key) end
	end)
end

local fctrl, wrapController
pcall(function() fctrl = require(ctrls:WaitForChild("FighterController", 10)) end)
pcall(function() wrapController = require(ctrls:WaitForChild("WrapController", 10)) end)
local replicatedClass
pcall(function()
	local identity = getthreadidentity and getthreadidentity()
	if setthreadidentity then pcall(setthreadidentity, 2) end
	local ok, result = pcall(require, reps.Modules.ReplicatedClass)
	if identity and setthreadidentity then pcall(setthreadidentity, identity) end
	if ok then replicatedClass = result end
end)
local charmAssets, wrapPreviewAsset, wrapTextureAssets
pcall(function()
	charmAssets = lps.Assets:WaitForChild("Charms", 10)
	wrapPreviewAsset = lps.Assets:WaitForChild("Misc", 10):WaitForChild("Wrap", 10)
	wrapTextureAssets = lps.Assets:WaitForChild("WrapTextures", 10)
end)

local function resolveViewModelName(weapon, cosmetics)
	local skin = cosmetics and cosmetics.Skin
	local skinName = skin and (skin.ViewModelName or skin.Name)
	return skinName or weapon
end

local function _resolveViewModelSourceName(weapon, cosmetics)
	local skin = cosmetics and cosmetics.Skin
	return skin and (skin.SourceViewModelName or skin.ViewModelName or skin.Name) or weapon
end

local virtualViewModelClassOverrides = {
	[KNIFE_CUSTOM_SKIN] = "Knife",
	[REAVER_KNIFE_CUSTOM_SKIN] = "Knife",
	[DAGGERS_CUSTOM_SKIN] = "Keynais",
	[SNIPER_CUSTOM_SKIN] = "Keyper",
	["Operator"] = "Sniper",
	[RPG_CUSTOM_SKIN] = "Nuke Launcher",
	[FISTS_CUSTOM_SKIN] = "Fists",
		[BOW_CUSTOM_SKIN] = "Frostbite Bow",
		[ASSAULT_RIFLE_CUSTOM_SKIN] = "AK-47",
		["Grenade (Custom Skin)"] = "Elixir",
		["Grenade Raze"] = "Glorious Grenade",
		["sky"] = "Shining Star",
	["Molotov (Custom Skin)"] = "Elixir",
	["Satchel (Custom Skin)"] = "Elixir",
	["Smoke Grenade (Custom Skin)"] = "Elixir",
	["Warpstone (Custom Skin)"] = "Elixir",
	[SATCHEL_CUSTOM_SKIN] = "BaseSatchel",
	[DICE_TRIPMINE_SKIN] = "SubspaceTripmine",
	[SPIKE_TRIPMINE_SKIN] = "SubspaceTripmine"
}

local function resolveViewModelClassName(_, cosmetics, resolvedName)
	return (resolvedName and virtualViewModelClassOverrides[resolvedName]) or resolvedName
end

local resolveViewModelClass
local clientViewModelClass
local clientViewModelBaseNew
local constructingVirtualViewModelClass = false

local function getewep()
	if not fctrl then return nil end
	local fighter = fctrl:GetFighter(lp)
	if not fighter or not fighter.Items then return nil end
	for _, item in fighter.Items do
		if item.IsEquipped then return item.Name end
	end
	return nil
end

if hookfunction then
	local rems = reps:FindFirstChild("Remotes")
	local drems = rems and rems:FindFirstChild("Data")
	local eqrem = drems and drems:FindFirstChild("EquipCosmetic")
	local favrem = drems and drems:FindFirstChild("FavoriteCosmetic")
	local rrems = rems and rems:FindFirstChild("Replication")
	local frems = rrems and rrems:FindFirstChild("Fighter")
	local uirem = frems and frems:FindFirstChild("UseItem")

	if eqrem then
		local oldFireServer
		oldFireServer = hookfunction(eqrem.FireServer, newcclosure(function(self, ...)
			local args = { ... }

			if uirem and self == uirem and fctrl then
				pcall(function()
					local fighter = fctrl:GetFighter(lp)
					if fighter and fighter.Items then
						local oid = args[1]
						for _, item in fighter.Items do
							if item:Get("ObjectID") == oid then
								_lwep = item.Name
								break
							end
						end
					end
				end)
			end

			if self == eqrem then
				local wname, ctype, cname, opts = args[1], args[2], args[3], args[4] or {}
				if not cname or cname == "None" or cname == "" then
					equip[wname] = equip[wname] or {}
					equip[wname][ctype] = nil
					if not next(equip[wname]) then equip[wname] = nil end
					rebuildinv()
					task.defer(function()
						saferep("WeaponInventory")
					end)
					return oldFireServer(self, ...)
				end
				if banned(cname) then return oldFireServer(self, ...) end
				local rdata = oget(dctrl, "CosmeticInventory")
				if rdata and type(rdata[cname]) ~= "boolean" and rdata[cname] ~= nil then
					return oldFireServer(self, ...)
				end
				equip[wname] = equip[wname] or {}
				local cloned = clonecos(cname, ctype, opts.IsInverted, opts.OnlyUseFavorites)
				if cloned then equip[wname][ctype] = cloned end
				if ctype == "Finisher" then fcache[wname] = cname end
				rebuildinv()
				task.defer(function()
					saferep("WeaponInventory")
				end)
				return
			end

			if self == favrem then
				local fwep, fname, fstate = args[1], args[2], args[3]
				if not fname or fname == "None" or fname == "" then return oldFireServer(self, ...) end
				if banned(fname) then return oldFireServer(self, ...) end
				favs[fwep] = favs[fwep] or {}
				favs[fwep][fname] = fstate or nil
				task.spawn(saferep, "FavoritedCosmetics")
				return
			end

			return oldFireServer(self, ...)
		end))
	end
end

local citem
pcall(function() citem = require(lps.Modules.ClientReplicatedClasses.ClientFighter.ClientItem) end)

local function applyLiveFistsMeshProfile(wname, viewModel)
	if wname ~= "Fists" then return end
	local skin = equip[wname] and equip[wname].Skin
	local skinName = skin and (skin.ViewModelName or skin.Name)
	local profile = skinName and FISTS_MESH_SKIN_OVERRIDES[skinName]
	if not profile then return end

	task.spawn(function()
		for _ = 1, 30 do
			local model
			if typeof(viewModel) == "Instance" then
				model = viewModel
			elseif type(viewModel) == "table" then
				model = viewModel.Model or viewModel.ItemModel
			end
			if typeof(model) == "Instance" then
				if applyFistsMeshProfile(model, profile) then
					return
				end
			end
			task.wait()
		end
	end)
end

if citem and citem._CreateViewModel then
	local ocvm = citem._CreateViewModel
	citem._CreateViewModel = function(self, vmref)
		local wname = self.Name
		local wplr = self.ClientFighter and self.ClientFighter.Player
		cwep = (wplr == lp) and wname or nil
		local directClass
		if wplr == lp and equip[wname] and vmref then
			local cos = equip[wname]
			local dk = self:ToEnum("Data")
			local data = vmref[dk] or vmref.Data or {}
			if data then
				if vmref[dk] ~= nil or vmref.Data == nil then
					vmref[dk] = data
					vmref.Data = nil
				else
					vmref.Data = data
				end
				local resolvedName = resolveViewModelName(wname, cos)
				local className = resolveViewModelClassName(wname, cos, resolvedName)
				if cos.Skin then
					data[self:ToEnum("Skin")] = cos.Skin
				end
				data[self:ToEnum("Name")] = resolvedName
				if cos.Wrap then
					data[self:ToEnum("Wrap")] = cos.Wrap
				end
				if cos.Charm then
					data[self:ToEnum("Charm")] = cos.Charm
				end
				data.Skin = nil
				data.Name = nil
				data.Wrap = nil
				data.Charm = nil
				if className ~= resolvedName and resolveViewModelClass then
					directClass = resolveViewModelClass(className)
				end
			end
		end
		if directClass and directClass ~= clientViewModelClass and directClass.new then
			local identity = getthreadidentity and getthreadidentity() or 8
			constructingVirtualViewModelClass = true
			local ok, res = pcall(function()
				if setthreadidentity then pcall(setthreadidentity, 2) end
				return directClass.new(vmref, self)
			end)
			constructingVirtualViewModelClass = false
			if setthreadidentity then pcall(setthreadidentity, identity) end
			cwep = nil
			if ok then
				applyLiveFistsMeshProfile(wname, res)
				return res
			end
		end
		local res = ocvm(self, vmref)
		cwep = nil
		applyLiveFistsMeshProfile(wname, res)
		return res
	end
end

local vmmod = lps.Modules.ClientReplicatedClasses.ClientFighter.ClientItem:FindFirstChild("ClientViewModel")
if vmmod then
	local cvm = require(vmmod)
	clientViewModelClass = cvm
	if cvm.GetWrap then
		local ogw = cvm.GetWrap
		cvm.GetWrap = function(self)
			local ci = self.ClientItem
			local wname = ci and ci.Name
			local wplr = ci and ci.ClientFighter and ci.ClientFighter.Player
			local weq = wname and wplr == lp and equip[wname]
			return (weq and weq.Wrap) or ogw(self)
		end
	end
	if cvm._UpdateWrap and wrapController then
		local oldUpdateWrap = cvm._UpdateWrap
		local function isCustomTripmineViewModel(self)
			if not self then return false end
			if TRIPMINE_MESH_SKIN_OVERRIDES[self.Name] then
				return true
			end
			local ci = self.ClientItem
			local weapon = ci and ci.Name
			local skin = weapon and equip[weapon] and equip[weapon].Skin
			local skinName = skin and (skin.ViewModelName or skin.Name)
			return weapon == "Subspace Tripmine" and TRIPMINE_MESH_SKIN_OVERRIDES[skinName] ~= nil
		end
		local function collectCustomTripmineWrapTargets(model)
			local targets = {}
			for _, descendant in ipairs(model:GetDescendants()) do
				if descendant:IsA("BasePart") and descendant:GetAttribute("__LionCustomTripmineMeshPart") then
					if descendant:GetAttribute("WrapGroup") == nil then
						descendant:SetAttribute("WrapGroup", 1)
					end
					descendant:SetAttribute("IgnoreTransparency", true)
					pcall(function() descendant:AddTag("Wrappable") end)
					pcall(function() collectionService:AddTag(descendant, "Wrappable") end)
					table.insert(targets, descendant)
				end
			end
			return targets
		end
		cvm._UpdateWrap = function(self, ...)
			if isCustomTripmineViewModel(self) and self.Model then
				local targets = collectCustomTripmineWrapTargets(self.Model)
				if #targets > 0 then
					local wrap = self.GetWrap and self:GetWrap() or nil
					if self._original_wrap_properties then
						pcall(wrapController.ResetWrap, wrapController, self._original_wrap_properties)
						self._original_wrap_properties = nil
					end
					if self.__LionCustomTripmineWrapProperties then
						pcall(wrapController.ResetWrap, wrapController, self.__LionCustomTripmineWrapProperties)
						self.__LionCustomTripmineWrapProperties = nil
					end
					if wrap then
						self.__LionCustomTripmineWrapProperties = wrapController:RecordOriginalWrapProperties(targets)
						wrapController:ApplyWrap(self.__LionCustomTripmineWrapProperties, wrap, true)
					end
					if self._UpdateLocalTransparencyModifiers then
						pcall(self._UpdateLocalTransparencyModifiers, self)
					end
					return
				end
			end
			return oldUpdateWrap(self, ...)
		end
	end
	local onew = cvm.new
	clientViewModelBaseNew = onew
	cvm.new = function(rdata, cliitm)
		if constructingVirtualViewModelClass then
			return onew(rdata, cliitm)
		end
		local wplr = cliitm.ClientFighter and cliitm.ClientFighter.Player
		local wname = cwep or cliitm.Name
		local className = wname
		if wplr == lp and equip[wname] then
			local rcls = require(reps.Modules.ReplicatedClass)
			local dk = rcls:ToEnum("Data")
			local slot = rdata[dk] or rdata.Data or {}
			if rdata[dk] ~= nil or rdata.Data == nil then
				rdata[dk] = slot
				rdata.Data = nil
			else
				rdata.Data = slot
			end
			local cos = equip[wname]
			local resolvedName = resolveViewModelName(wname, cos)
			className = resolveViewModelClassName(wname, cos, resolvedName)
			if cos.Skin then
				slot[rcls:ToEnum("Skin")] = cos.Skin
			end
			slot[rcls:ToEnum("Name")] = resolvedName
			if cos.Wrap then
				slot[rcls:ToEnum("Wrap")] = cos.Wrap
			end
			if cos.Charm then
				slot[rcls:ToEnum("Charm")] = cos.Charm
			end
			slot.Skin = nil
			slot.Name = nil
			slot.Wrap = nil
			slot.Charm = nil
		end
		local targetNew = onew
		local targetClass = className ~= wname and resolveViewModelClass and resolveViewModelClass(className)
		if targetClass and targetClass ~= clientViewModelClass and targetClass.new then
			targetNew = targetClass.new
		end
		constructingVirtualViewModelClass = targetNew ~= onew
		local ok, res = pcall(targetNew, rdata, cliitm)
		constructingVirtualViewModelClass = false
		if not ok and wplr == lp and equip[wname] and equip[wname].Skin then
			local rcls = require(reps.Modules.ReplicatedClass)
			local dk = rcls:ToEnum("Data")
			local slot = rdata[dk] or rdata.Data or {}
			rdata[dk] = slot
			rdata.Data = nil
			slot[rcls:ToEnum("Name")] = wname
			slot.Name = nil
			ok, res = pcall(onew, rdata, cliitm)
		end
		if not ok then error(res) end
		if wplr == lp and equip[wname] and res then
			for _, method in ipairs({"_UpdateWrap", "UpdateWrap", "_UpdateCharm", "UpdateCharm", "_UpdateCosmetics", "UpdateCosmetics"}) do
				if res[method] then
					pcall(res[method], res)
				end
			end
			applyLiveFistsMeshProfile(wname, res)
		end
		return res
	end
end

local viewModelClassCache = {}
local function normalizeViewModelName(name)
	return tostring(name or ""):gsub("[%W_]+", ""):lower()
end

resolveViewModelClass = function(name)
	if not clientViewModelClass then return nil end
	local key = normalizeViewModelName(name)
	if viewModelClassCache[key] ~= nil then
		return viewModelClassCache[key] or clientViewModelClass
	end
	local targetClass = clientViewModelClass
	local vmFolder = lps.Modules:FindFirstChild("ViewModels")
	if vmFolder then
		for _, module in pairs(vmFolder:GetDescendants()) do
			if module:IsA("ModuleScript") and normalizeViewModelName(module.Name) == key then
				local ok, customClass = pcall(require, module)
				if ok and type(customClass) == "table" and type(customClass.new) == "function" then
					targetClass = customClass
				end
				break
			end
		end
	end
	viewModelClassCache[key] = targetClass
	return targetClass
end

local function getLocalItem(weapon)
	local fighter = fctrl and fctrl:GetFighter(lp)
	for _, item in pairs(fighter and fighter.Items or {}) do
		if item.Name == weapon then
			return item
		end
	end
	return nil
end

local function getWorldSkinName(weapon)
	local skin = equip[weapon] and equip[weapon].Skin
	return skin and (skin.WorldViewModelName or skin.SourceViewModelName or skin.ViewModelName or skin.Name)
end

local function getEquippedWeaponWrap(weapon)
	local item = getLocalItem(weapon)
	if item and item.GetWrap then
		local ok, wrap = pcall(item.GetWrap, item)
		if ok then
			return wrap
		end
	end
	return equip[weapon] and equip[weapon].Wrap
end

local function isInsideWorkspaceViewModels(inst)
	local viewModels = workspace:FindFirstChild("ViewModels")
	return viewModels and inst:IsDescendantOf(viewModels)
end

local function isRpgRazeEquipped()
	return getWorldSkinName("RPG") == RPG_CUSTOM_SKIN
end

local function tryApplyRpgProjectileSkin(inst)
	local profile = RPG_MESH_SKIN_OVERRIDES[RPG_CUSTOM_SKIN]
	if not (profile and isRpgRazeEquipped() and typeof(inst) == "Instance") then return end
	if isInsideWorkspaceViewModels(inst) then return end
	if inst:GetAttribute("__LionRpgProjectileSkinChecked") then return end

	local shouldApply = false
	if inst:IsA("MeshPart") or inst:IsA("SpecialMesh") then
		shouldApply = meshMatchesAnyAssetId(inst, profile.RocketMeshIds) or meshMatchesAnyAssetId(inst, profile.JuggleMeshIds)
	elseif inst:IsA("Model") then
		shouldApply = namePathContains(inst, "rocket") or namePathContains(inst, "projectile")
	end
	if not shouldApply then return end

	inst:SetAttribute("__LionRpgProjectileSkinChecked", true)
	applyRpgMeshProfile(inst, profile, {
		ShowRocket = true,
		ForceRocket = true
	})
end

local function _installRpgProjectileSkinHook()
	local env = getgenv and getgenv() or _G
	local state = env.__LionRpgProjectileSkinHookState or {}
	env.__LionRpgProjectileSkinHookState = state
	local version = 2
	if state.Version == version and state.Connection then return end
	if state.Connection then
		pcall(function() state.Connection:Disconnect() end)
	end
	state.Version = version
	state.Connection = workspace.DescendantAdded:Connect(function(inst)
		task.defer(tryApplyRpgProjectileSkin, inst)
	end)
	task.defer(function()
		for _, inst in ipairs(workspace:GetDescendants()) do
			tryApplyRpgProjectileSkin(inst)
		end
	end)
end

local function disableRpgProjectileSkinHook()
	local env = getgenv and getgenv() or _G
	local state = env.__LionRpgProjectileSkinHookState
	if state and state.Connection then
		pcall(function() state.Connection:Disconnect() end)
	end
	env.__LionRpgProjectileSkinHookState = {
		Version = 3,
		Connection = nil
	}
end

local function ensurePlacedTripmineWrapTargets(visual)
	if typeof(visual) ~= "Instance" then return end
	for _, descendant in ipairs(visual:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant:GetAttribute("__LionCustomTripmineMeshPart") then
			if descendant:GetAttribute("WrapGroup") == nil then
				descendant:SetAttribute("WrapGroup", 1)
			end
			descendant:SetAttribute("IgnoreTransparency", true)
			pcall(function() descendant:AddTag("Wrappable") end)
			pcall(function() collectionService:AddTag(descendant, "Wrappable") end)
		end
	end
end

local function applyPlacedTripmineWrap(visual)
	if not wrapController or typeof(visual) ~= "Instance" then return end
	ensurePlacedTripmineWrapTargets(visual)
	local wrap = getEquippedWeaponWrap("Subspace Tripmine")
	pcall(function()
		local originalWrapProperties = wrapController:RecordOriginalWrapProperties(visual)
		wrapController:ApplyWrap(originalWrapProperties, wrap, true)
	end)
end

local function isLocalPlacedObject(object, weapon)
	local userId = object:GetAttribute("PlacedByUserID")
		or object:GetAttribute("ThrownByUserID")
		or object:GetAttribute("OwnerUserID")
	if userId ~= nil then
		return tonumber(userId) == lp.UserId
	end

	local objectId = object:GetAttribute("ObjectID")
	local item = getLocalItem(weapon)
	return objectId ~= nil and item and item.Get and item:Get("ObjectID") == objectId
end

local function isInsidePlacedSkinVisual(inst)
	local current = inst
	while current do
		if current.Name == "__LionPlacedSkin" or current:GetAttribute("__LionPlacedSkin") then
			return true
		end
		current = current.Parent
	end
	return false
end

local function hideOriginalTripmineVisual(object)
	if typeof(object) ~= "Instance" then return end

	local function hide(inst)
		if isInsidePlacedSkinVisual(inst) then return end
		if inst:IsA("BasePart") then
			inst.Transparency = 1
			inst.LocalTransparencyModifier = 1
		elseif inst:IsA("Decal") or inst:IsA("Texture") then
			inst.Transparency = 1
		elseif inst:IsA("ParticleEmitter") or inst:IsA("Trail") or inst:IsA("Beam") then
			inst.Enabled = false
		end
	end

	for _, descendant in ipairs(object:GetDescendants()) do
		hide(descendant)
	end

	if not object:GetAttribute("__LionHideOriginalTripmineHook") then
		object:SetAttribute("__LionHideOriginalTripmineHook", true)
		local connection
		connection = object.DescendantAdded:Connect(function(descendant)
			task.defer(hide, descendant)
		end)
		task.delay(8, function()
			if connection then
				connection:Disconnect()
			end
		end)
	end

	if not object:GetAttribute("__LionHideOriginalTripmineLoop") then
		object:SetAttribute("__LionHideOriginalTripmineLoop", true)
		task.spawn(function()
			for _ = 1, 80 do
				if not object.Parent then break end
				for _, descendant in ipairs(object:GetDescendants()) do
					hide(descendant)
				end
				task.wait(0.1)
			end
			if object.Parent then
				object:SetAttribute("__LionHideOriginalTripmineLoop", nil)
			end
		end)
	end
end

local function prunePlacedTripmineVisualToCustomMesh(visual)
	if typeof(visual) ~= "Instance" then return end
	local primaryPart
	for _, descendant in ipairs(visual:GetDescendants()) do
		if descendant:IsA("BasePart") then
			if descendant:GetAttribute("__LionCustomTripmineMeshPart") then
				primaryPart = primaryPart or descendant
			else
				descendant:Destroy()
			end
		end
	end
	if visual:IsA("Model") and primaryPart then
		visual.PrimaryPart = primaryPart
	end
end

local function isInsideCustomTripmineMeshPart(inst)
	local current = inst
	while current do
		if current:IsA("BasePart") and current:GetAttribute("__LionCustomTripmineMeshPart") then
			return true
		end
		current = current.Parent
	end
	return false
end

local function forcePlacedSkinVisualVisible(visual)
	if typeof(visual) ~= "Instance" then return end

	local function show(inst)
		if inst:IsA("BasePart") and inst:GetAttribute("__LionCustomTripmineMeshPart") then
			inst.Transparency = 0
			inst.LocalTransparencyModifier = 0
		elseif (inst:IsA("Decal") or inst:IsA("Texture")) and isInsideCustomTripmineMeshPart(inst) then
			inst.Transparency = 0
		end
	end

	for _, descendant in ipairs(visual:GetDescendants()) do
		show(descendant)
	end

	if not visual:GetAttribute("__LionShowPlacedSkinLoop") then
		visual:SetAttribute("__LionShowPlacedSkinLoop", true)
		local connection
		connection = visual.DescendantAdded:Connect(function(descendant)
			task.defer(show, descendant)
		end)
		task.spawn(function()
			for _ = 1, 100 do
				if not visual.Parent then break end
				for _, descendant in ipairs(visual:GetDescendants()) do
					show(descendant)
				end
				task.wait(0.1)
			end
			if connection then
				connection:Disconnect()
			end
			if visual.Parent then
				visual:SetAttribute("__LionShowPlacedSkinLoop", nil)
			end
		end)
	end
end

local function pivotPlacedTripmineVisual(visual, hitbox, profile)
	if not (visual and visual:IsA("Model") and hitbox and hitbox:IsA("BasePart")) then return end
	local boundsCFrame, boundsSize = visual:GetBoundingBox()
	local centerOffset = visual:GetPivot():ToObjectSpace(boundsCFrame)
	local groundOffset = profile and profile.WorldGroundOffset or 0
	local targetCenterOffsetY = (-hitbox.Size.Y * 0.5) + (boundsSize.Y * 0.5) + groundOffset
	local targetBoundsCFrame = hitbox.CFrame * CFrame.new(0, targetCenterOffsetY, 0)
	visual:PivotTo(targetBoundsCFrame * centerOffset:Inverse())
end

local function installPlacedCosmeticHooks()
	local components = lps.Modules:FindFirstChild("GameComponents")
	if not components then return end

	pcall(function()
		local jumpPads = require(components:WaitForChild("JumpPads", 10))
		if jumpPads.__LionSkinHook then return end
		jumpPads.__LionSkinHook = true
		local oldObjectAdded = jumpPads._ObjectAdded
		jumpPads._ObjectAdded = function(self, object)
			local skinName = getWorldSkinName("Jump Pad")
			if skinName and isLocalPlacedObject(object, "Jump Pad") then
				object:SetAttribute("ViewModelName", skinName)
			end
			return oldObjectAdded(self, object)
		end
	end)

	pcall(function()
		local tripmines = require(components:WaitForChild("SubspaceTripmines", 10))
		if tripmines.__LionSkinHook then return end
		tripmines.__LionSkinHook = true
		local oldObjectAdded = tripmines._ObjectAdded
		tripmines._ObjectAdded = function(self, object)
			local skinName = getWorldSkinName("Subspace Tripmine")
			local placedSkinName = skinName == "RNG Dice" and DICE_TRIPMINE_SKIN or skinName
			local meshProfile = TRIPMINE_MESH_SKIN_OVERRIDES[placedSkinName]
			if meshProfile and isLocalPlacedObject(object, "Subspace Tripmine") then
				task.defer(function()
					if not object.Parent or object:FindFirstChild("__LionPlacedSkin") then return end
					hideOriginalTripmineVisual(object)

					local throwables = lps.Assets:FindFirstChild("Throwables")
					local viewModels = lps.Assets:FindFirstChild("ViewModels")
					local sourceName = meshProfile.BaseAssetName or "Subspace Tripmine"
					local source = (throwables and findDescendantByName(throwables, sourceName)) or (viewModels and findDescendantByName(viewModels, sourceName))
					local hitbox = object:FindFirstChild("Hitbox", true)
					if not source or not hitbox or not hitbox:IsA("BasePart") then return end

					local visual = source:Clone()
					if not applyTripmineMeshProfile(visual, meshProfile, true) then
						visual:Destroy()
						return
					end
					prunePlacedTripmineVisualToCustomMesh(visual)
					if visual:IsA("BasePart") then
						local model = Instance.new("Model")
						model.Name = visual.Name
						visual.Parent = model
						model.PrimaryPart = visual
						visual = model
					end
					if not visual:IsA("Model") then return end
					for _, descendant in pairs(visual:GetDescendants()) do
						if descendant.Name == "_right_arm" or descendant.Name == "_left_arm" or descendant.Name == "_fake" then
							descendant:Destroy()
						end
					end
					visual.Name = "__LionPlacedSkin"
					visual:SetAttribute("__LionPlacedSkin", true)
					visual.Parent = object
					hideOriginalTripmineVisual(object)
					pivotPlacedTripmineVisual(visual, hitbox, meshProfile)
					forcePlacedSkinVisualVisible(visual)
					for _, part in pairs(visual:GetDescendants()) do
						if part:IsA("BasePart") then
							part.Anchored = false
							part.CanCollide = false
							part.CanTouch = false
							part.CanQuery = false
							part.Massless = true
							local weld = Instance.new("WeldConstraint")
							weld.Part0 = hitbox
							weld.Part1 = part
							weld.Parent = part
						end
					end
					applyPlacedTripmineWrap(visual)
					forcePlacedSkinVisualVisible(visual)
				end)
			end
			return oldObjectAdded(self, object)
		end
	end)

	pcall(function()
		local fireHitboxes = require(components:WaitForChild("FireHitboxes", 10))
		local fireAssets = lps.Assets:WaitForChild("Misc", 10):WaitForChild("FireHitboxes", 10)
		if not fireAssets:FindFirstChild("Elixir") then
			local elixirEffect = lps.Assets.Misc:FindFirstChild("ElixirExplosionEffect")
			local defaultFire = fireAssets:FindFirstChild("Default")
			if elixirEffect and defaultFire then
				local elixirFire = defaultFire:Clone()
				elixirFire.Name = "Elixir"
				for _, effect in pairs(elixirFire:GetDescendants()) do
					if effect:IsA("ParticleEmitter") or effect:IsA("Trail") or effect:IsA("Beam") then
						effect:Destroy()
					end
				end
				local primary = elixirFire:FindFirstChild("Primary")
				local attachment = elixirEffect:FindFirstChild("Attachment")
				if primary and attachment then
					attachment:Clone().Parent = primary
				end
				elixirFire.Parent = fireAssets
			end
		end

		local collectionService = game:GetService("CollectionService")
		local function replaceFireVisual(object)
			local skinName = getWorldSkinName("Molotov")
			if not skinName or not isLocalPlacedObject(object, "Molotov") then return end
			object:SetAttribute("ViewModelName", skinName)
			task.spawn(function()
				local entry
				for _ = 1, 20 do
					entry = fireHitboxes._fire_hitboxes and fireHitboxes._fire_hitboxes[object]
					if entry and entry.Visual then break end
					task.wait()
				end
				if not entry or not entry.Visual or not object.Parent then return end
				local source = fireAssets:FindFirstChild(skinName) or fireAssets:FindFirstChild("Default")
				if not source then return end

				local visual = source:Clone()
				visual.Name = skinName
				visual.PrimaryPart = visual:FindFirstChild("Primary")
				if not visual.PrimaryPart then return end
				visual.PrimaryPart.Size = object.Size
				visual:PivotTo(object.CFrame)
				visual.Parent = workspace
				for _, sound in ipairs({entry.Sound1, entry.Sound2}) do
					if sound then sound.Parent = visual.PrimaryPart end
				end
				local oldVisual = entry.Visual
				entry.Visual = visual
				oldVisual:Destroy()
			end)
		end

		collectionService:GetInstanceAddedSignal("FireHitbox"):Connect(replaceFireVisual)
		for _, object in pairs(collectionService:GetTagged("FireHitbox")) do
			task.defer(replaceFireVisual, object)
		end
	end)

	pcall(function()
		local smokeModule = lps.Modules:FindFirstChild("SmokeCloud")
		if not smokeModule then return end
		local smokeCloud = require(smokeModule)
		if smokeCloud.__LionSkinHook or type(smokeCloud.new) ~= "function" then return end
		smokeCloud.__LionSkinHook = true

		local oldNew = smokeCloud.new
		smokeCloud.new = function(...)
			local args = { ... }
			local cloud = oldNew(...)
			task.defer(function()
				local skinName = getWorldSkinName("Smoke Grenade")
				if skinName ~= "Elixir" or type(cloud) ~= "table" then return end

				local ownerObject
				for _, value in ipairs(args) do
					if typeof(value) == "Instance" and isLocalPlacedObject(value, "Smoke Grenade") then
						ownerObject = value
						break
					end
				end

				local model = cloud.Model
				if not ownerObject then
					for _, value in pairs(cloud) do
						if typeof(value) == "Instance" and isLocalPlacedObject(value, "Smoke Grenade") then
							ownerObject = value
							break
						end
					end
				end
				if not ownerObject and typeof(model) == "Instance" and isLocalPlacedObject(model, "Smoke Grenade") then
					ownerObject = model
				end
				if not ownerObject then
					local item = getLocalItem("Smoke Grenade")
					local localObjectId = item and item.Get and item:Get("ObjectID")
					local cloudObjectId = rawget(cloud, "ObjectID") or rawget(cloud, "_object_id")
					if localObjectId ~= nil and cloudObjectId == localObjectId then
						ownerObject = model
					end
				end
				if not ownerObject or typeof(model) ~= "Instance" or not model.Parent then return end
				if model:FindFirstChild("__LionSmokeSkin") then return end

				for _, descendant in pairs(model:GetDescendants()) do
					if descendant:IsA("BasePart") then
						descendant.LocalTransparencyModifier = 1
					end
				end

				local throwables = lps.Assets:FindFirstChild("Throwables")
				local source = throwables and throwables:FindFirstChild(skinName)
				if not source then return end

				local visual = source:Clone()
				visual.Name = "__LionSmokeSkin"
				local anchor = model:IsA("BasePart") and model or model:FindFirstChildWhichIsA("BasePart", true)
				if not anchor then
					anchor = Instance.new("Part")
					anchor.Name = "__LionSmokeAnchor"
					anchor.Size = Vector3.new(0.1, 0.1, 0.1)
					anchor.Transparency = 1
					anchor.Anchored = true
					anchor.CanCollide = false
					anchor.CanTouch = false
					anchor.CanQuery = false
					anchor.CFrame = model:IsA("Model") and model:GetPivot() or CFrame.new()
					anchor.Parent = model
				end

				visual.Parent = model
				visual:PivotTo(anchor.CFrame)
				for _, part in pairs(visual:GetDescendants()) do
					if part:IsA("BasePart") then
						part.Anchored = false
						part.CanCollide = false
						part.CanTouch = false
						part.CanQuery = false
						part.Massless = true
						local weld = Instance.new("WeldConstraint")
						weld.Part0 = anchor
						weld.Part1 = part
						weld.Parent = part
					end
				end
			end)
			return cloud
		end
	end)
end

disableRpgProjectileSkinHook()
installPlacedCosmeticHooks()

local function isValidViewModel(viewModel)
	return type(viewModel) == "table"
		and viewModel._destroyed ~= true
		and typeof(viewModel.Model) == "Instance"
		and typeof(viewModel.ItemModel) == "Instance"
end

local ogvi = ilib.GetViewModelImageFromWeaponData
ilib.GetViewModelImageFromWeaponData = function(self, wdata, hires)
	if not wdata then return ogvi(self, wdata, hires) end
	local wname = wdata.Name
	local weq = equip[wname]
	if weq and weq.Skin then
		local skinViewModelName = weq.Skin.ViewModelName or weq.Skin.Name
		local skinSourceName = weq.Skin.SourceViewModelName or skinViewModelName
		local sinfo = self.ViewModels[skinViewModelName] or self.ViewModels[skinSourceName]
		if sinfo then return sinfo[hires and "ImageHighResolution" or "Image"] or sinfo.Image end
		return weq.Skin[hires and "ImageHighResolution" or "Image"] or weq.Skin.Image or ""
	end
	return ogvi(self, wdata, hires)
end

pcall(function()
	local vpmod = require(lps.Modules.Pages.ViewProfile)
	if vpmod and vpmod.Fetch then
		local ofetch = vpmod.Fetch
		vpmod.Fetch = function(self, tplr)
			_vprof = tplr
			return ofetch(self, tplr)
		end
	end
end)

local cent
pcall(function() cent = require(lps.Modules.ClientReplicatedClasses.ClientEntity) end)

if cent and cent._PlayFinisher then
	local ofin = cent._PlayFinisher
	cent._PlayFinisher = function(self, fname, ...)
		local ewep = getewep()
		local tfin = ewep and (fcache[ewep] or (equip[ewep] and equip[ewep].Finisher and equip[ewep].Finisher.Name))
		return ofin(self, tfin or fname, ...)
	end
end

rebuildinv()

for wname, wdata in equip do
	if wdata.Finisher and wdata.Finisher.Name then
		fcache[wname] = wdata.Finisher.Name
	end
end

local cosmeticGuiState = {
	Wanted = false,
	Gui = nil,
	WeaponSearch = "",
	CosmeticSearch = "",
	Mode = "Skin",
	SelectedWeapon = nil,
	SelectedCosmetic = nil,
	Weapons = {},
	Cosmetics = {},
	Columns = 6,
	TileW = 130,
	TileH = 124,
	Refresh = function() end,
}

local function displayName(name, data)
	return tostring((data and (data.DisplayName or data.Name)) or name or "")
end

local function iconFrom(data, fallback, name)
	if not data then return fallback or "" end
	local cosmeticImage = name and consts and consts.COSMETIC_IMAGES and consts.COSMETIC_IMAGES[name]
	local typeInfo = data.Type and clib.Types and clib.Types[data.Type]
	return cosmeticImage
		or data.ImageHighResolution
		or data.Image
		or data.Icon
		or data.Texture
		or fallback
		or (typeInfo and typeInfo.Image)
		or ""
end

local function sortByName(list)
	table.sort(list, function(a, b)
		return tostring(a.Name):lower() < tostring(b.Name):lower()
	end)
	return list
end

local function cosmeticMatchesWeapon(data, weapon)
	if not data then return false end
	local itemName = data.ItemName or data.WeaponName or data.Weapon or data.Item
	if itemName then
		return tostring(itemName):lower() == tostring(weapon or ""):lower()
	end
	return data.Type ~= "Skin"
end

local function rebuildCosmeticLists()
	table.clear(cosmeticGuiState.Weapons)
	table.clear(cosmeticGuiState.Cosmetics)

	for name, data in pairs(coss) do
		if not banned(name) and data.Type == "Weapon" then
			local dispName = displayName(name, data)
			local dispImg = iconFrom(data, ilib.Items and ilib.Items[name] and ilib.Items[name].Image, name)
			if equip[name] and equip[name].Skin then
				local skinData = equip[name].Skin
				dispName = displayName(skinData.Name, skinData)
				dispImg = iconFrom(skinData, nil, skinData.Name)
			end
			table.insert(cosmeticGuiState.Weapons, {
				Name = name,
				Display = dispName,
				Image = dispImg,
				Data = data
			})
		end
	end

	if #cosmeticGuiState.Weapons == 0 and ilib.ItemsAlphabetized then
		for _, name in ipairs(ilib.ItemsAlphabetized) do
			local data = ilib.Items and ilib.Items[name]
			if data and not banned(name) then
				local dispName = displayName(name, data)
				local dispImg = iconFrom(data, nil, name)
				if equip[name] and equip[name].Skin then
					local skinData = equip[name].Skin
					dispName = displayName(skinData.Name, skinData)
					dispImg = iconFrom(skinData, nil, skinData.Name)
				end
				table.insert(cosmeticGuiState.Weapons, {
					Name = name,
					Display = dispName,
					Image = dispImg,
					Data = data
				})
			end
		end
	end

	sortByName(cosmeticGuiState.Weapons)
	if not cosmeticGuiState.SelectedWeapon and cosmeticGuiState.Weapons[1] then
		cosmeticGuiState.SelectedWeapon = cosmeticGuiState.Weapons[1].Name
	end

	local mode = cosmeticGuiState.Mode
	for name, data in pairs(coss) do
		if not banned(name) and data.Type == mode and cosmeticMatchesWeapon(data, cosmeticGuiState.SelectedWeapon) then
			table.insert(cosmeticGuiState.Cosmetics, {
				Name = name,
				Display = displayName(name, data),
				Image = iconFrom(data, nil, name),
				Data = data
			})
		end
	end

	sortByName(cosmeticGuiState.Cosmetics)
end

local function forceCosmeticUpdate(weapon, ctype)
	task.spawn(function()
		saferep("CosmeticInventory")
		saferep("WeaponInventory")

		local selected = equip[weapon] and equip[weapon][ctype]
		local fighter = fctrl and fctrl:GetFighter(lp)
		if not fighter then return end
		local item
		for _, fighterItem in fighter.Items or {} do
			if fighterItem.Name == weapon then
				item = fighterItem
				break
			end
		end
		if not item then return end
		local wasEquipped = fighter.EquippedItem == item or item.IsEquipped == true

		local function refreshHotbar()
			local hotbar = fighter.FighterInterface and fighter.FighterInterface.Hotbar
			for _, hotbarSlot in pairs(hotbar and hotbar._hotbar_slots or {}) do
				if hotbarSlot.ClientItem == item then
					if hotbarSlot._Setup then
						pcall(hotbarSlot._Setup, hotbarSlot)
					end
					if hotbarSlot.UpdateVisuals then
						pcall(hotbarSlot.UpdateVisuals, hotbarSlot)
					end
					break
				end
			end
		end

		pcall(function()
			if item.Set then item:Set(ctype, selected) end
		end)
		pcall(function()
			if item.Data then item.Data[ctype] = selected end
		end)

		local _rebuilt = false
		local oldViewModel = item.ViewModel
		if oldViewModel and oldViewModel._serial and replicatedClass and clientViewModelClass then
			local serial = table.clone(oldViewModel._serial)
			local dataKey = replicatedClass:ToEnum("Data")
			local data = table.clone(serial.Data or serial[dataKey] or {})
			serial[dataKey] = data
			serial.Data = nil

			local cosmetics = equip[weapon] or {}
			for _, cosmeticType in ipairs({"Skin", "Wrap", "Charm"}) do
				local cosmetic = cosmetics[cosmeticType]
				data[replicatedClass:ToEnum(cosmeticType)] = cosmetic
				data[cosmeticType] = nil
				if oldViewModel.Data then
					oldViewModel.Data[cosmeticType] = cosmetic
				end
			end
			local resolvedName = resolveViewModelName(weapon, cosmetics)
			data[replicatedClass:ToEnum("Name")] = resolvedName
			data.Name = nil

			local className = resolveViewModelClassName(weapon, cosmetics, resolvedName)
			local targetClass = resolveViewModelClass(className) or clientViewModelClass
			local identity = getthreadidentity and getthreadidentity() or 8
			constructingVirtualViewModelClass = targetClass ~= clientViewModelClass
			local ok, newViewModel = pcall(function()
				if setthreadidentity then pcall(setthreadidentity, 2) end
				return targetClass.new(serial, item)
			end)
			constructingVirtualViewModelClass = false
			if setthreadidentity then pcall(setthreadidentity, identity) end

			if (not ok or not isValidViewModel(newViewModel)) and resolvedName ~= weapon then
				if newViewModel and type(newViewModel) == "table" and newViewModel.Destroy then
					pcall(newViewModel.Destroy, newViewModel)
				end
				data[replicatedClass:ToEnum("Name")] = weapon
				data.Name = nil
				ok, newViewModel = pcall(function()
					if setthreadidentity then pcall(setthreadidentity, 2) end
					return (clientViewModelBaseNew or clientViewModelClass.new)(serial, item)
				end)
				if setthreadidentity then pcall(setthreadidentity, identity) end
			end

			if ok and isValidViewModel(newViewModel) then
				if wasEquipped and oldViewModel.Unequip then
					pcall(oldViewModel.Unequip, oldViewModel)
				end
				item.ViewModel = newViewModel
				if wasEquipped and newViewModel.Equip then
					pcall(newViewModel.Equip, newViewModel, true)
				end
				if oldViewModel ~= newViewModel and oldViewModel.Destroy then
					pcall(oldViewModel.Destroy, oldViewModel)
				end
				refreshHotbar()
				_rebuilt = true
			elseif newViewModel and type(newViewModel) == "table" and newViewModel.Destroy then
				pcall(newViewModel.Destroy, newViewModel)
			end
		end

		local vm = item.ViewModel
		for _, obj in ipairs({item, vm}) do
			if obj then
				for _, method in ipairs({
					"_UpdateWrap",
					"UpdateWrap",
					"_UpdateCharm",
					"UpdateCharm",
					"_UpdateCosmetics",
					"UpdateCosmetics",
					"_RefreshViewModel",
					"RefreshViewModel",
					"UpdateViewModel"
				}) do
					if obj[method] then
						pcall(obj[method], obj)
					end
				end
			end
		end

		task.wait(0.1)
		saferep("WeaponInventory")
		refreshHotbar()
	end)
end

local function applyCosmeticToWeapon(weapon, cosmeticName, ctype, skipRebuild)
	if not weapon or weapon == "" then return end
	ctype = ctype or cosmeticGuiState.Mode
	equip[weapon] = equip[weapon] or {}

	if not cosmeticName or cosmeticName == "" or cosmeticName == "None" then
		equip[weapon][ctype] = nil
	else
		if cosmeticName == "__random" then
			local pool = cosmeticGuiState.Cosmetics
			local pick = pool[math.random(1, math.max(1, #pool))]
			cosmeticName = pick and pick.Name or nil
		end
		local cloned = cosmeticName and clonecos(cosmeticName, ctype)
		if cloned then
			equip[weapon][ctype] = cloned
			if ctype == "Finisher" then
				fcache[weapon] = cloned.Name
			end
		end
	end

	if equip[weapon] and not next(equip[weapon]) then
		equip[weapon] = nil
	end
	if not skipRebuild then
		rebuildinv()
		task.defer(function()
			saferep("CosmeticInventory")
			saferep("WeaponInventory")
			forceCosmeticUpdate(weapon, ctype)
		end)
	end
end

local function makeCosmeticChanger()
	if cosmeticGuiState.Gui then return cosmeticGuiState.Gui end
	rebuildCosmeticLists()

	local gui = Instance.new("Frame")
	gui.Name = "LilacCosmeticChanger"
	gui.BackgroundColor3 = Theme.Bg
	gui.BorderSizePixel = 0
	gui.Position = UDim2.new(0.5, -410, 0.5, -420)
	gui.Size = UDim2.fromOffset(820, 840)
	gui.Visible = false
	gui.ZIndex = 900
	gui.Parent = mainapi.MainScreenGui
	cosmeticGuiState.Gui = gui
	local guiCorner = Instance.new("UICorner")
	guiCorner.CornerRadius = UDim.new(0, 16)
	guiCorner.Parent = gui
	local guiStroke = Instance.new("UIStroke")
	guiStroke.Color = Theme.Accent
	guiStroke.Thickness = 1.5
	guiStroke.Transparency = 0.15
	guiStroke.Parent = gui

	makeDraggable(gui, mainapi.MainScreenGui.ClickGui)

	local title = Instance.new("TextLabel")
	title.BackgroundColor3 = Theme.CardHead
	title.BorderSizePixel = 0
	title.Font = Enum.Font.GothamBold
	title.Text = "  Lilac Premium  ·  Skins"
	title.TextColor3 = Theme.Text
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextSize = 15
	title.Size = UDim2.new(1, 0, 0, 40)
	title.ZIndex = 901
	title.Parent = gui
	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0, 16)
	titleCorner.Parent = title
	local titleAccent = Instance.new("Frame")
	titleAccent.BackgroundColor3 = Theme.Accent
	titleAccent.BorderSizePixel = 0
	titleAccent.Size = UDim2.new(1, 0, 0, 2)
	titleAccent.Position = UDim2.new(0, 0, 1, -2)
	titleAccent.ZIndex = 902
	titleAccent.Parent = title

	local body = Instance.new("Frame")
	body.BackgroundColor3 = Theme.Card
	body.BackgroundTransparency = 0.15
	body.BorderSizePixel = 0
	body.Position = UDim2.fromOffset(12, 50)
	body.Size = UDim2.new(1, -24, 1, -62)
	body.ZIndex = 901
	body.Parent = gui
	local bodyCorner = Instance.new("UICorner")
	bodyCorner.CornerRadius = UDim.new(0, 12)
	bodyCorner.Parent = body

	local function mkText(parent, text, pos, size, fontSize)
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.GothamMedium
		label.Text = text
		label.TextColor3 = Theme.Text
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextSize = fontSize or 13
		label.Position = pos
		label.Size = size
		label.ZIndex = 902
		label.Parent = parent
		return label
	end

	local function mkBox(parent, placeholder, pos, size)
		local box = Instance.new("TextBox")
		box.BackgroundColor3 = Theme.Field
		box.BorderSizePixel = 0
		box.ClearTextOnFocus = false
		box.Font = Enum.Font.Gotham
		box.PlaceholderText = placeholder
		box.PlaceholderColor3 = Theme.Muted
		box.Text = ""
		box.TextColor3 = Theme.Text
		box.TextSize = 13
		box.TextXAlignment = Enum.TextXAlignment.Left
		box.Position = pos
		box.Size = size
		box.ZIndex = 902
		box.Parent = parent
		return box
	end

	local function mkButton(parent, text, pos, size)
		local btn = Instance.new("TextButton")
		btn.AutoButtonColor = false
		btn.BackgroundColor3 = Theme.CardHead
		btn.BorderSizePixel = 0
		btn.Font = Enum.Font.GothamMedium
		btn.Text = text
		btn.TextColor3 = Theme.Text
		btn.TextSize = 13
		btn.Position = pos
		btn.Size = size
		btn.ZIndex = 902
		btn.Parent = parent
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 8)
		c.Parent = btn
		local s = Instance.new("UIStroke")
		s.Color = Theme.Border
		s.Thickness = 1
		s.Transparency = 0.3
		s.Parent = btn
		return btn
	end

	local weaponGrid = Instance.new("ScrollingFrame")
	weaponGrid.BackgroundColor3 = Theme.Field
	weaponGrid.BorderSizePixel = 0
	weaponGrid.CanvasSize = UDim2.new()
	weaponGrid.ScrollBarThickness = 6
	weaponGrid.Position = UDim2.fromOffset(10, 54)
	weaponGrid.Size = UDim2.new(1, -20, 0, 264)
	weaponGrid.ZIndex = 902
	weaponGrid.Parent = body

	local cosmeticGrid = Instance.new("ScrollingFrame")
	cosmeticGrid.BackgroundColor3 = Theme.Field
	cosmeticGrid.BorderSizePixel = 0
	cosmeticGrid.CanvasSize = UDim2.new()
	cosmeticGrid.ScrollBarThickness = 6
	cosmeticGrid.Position = UDim2.fromOffset(10, 374)
	cosmeticGrid.Size = UDim2.new(1, -20, 0, 276)
	cosmeticGrid.ZIndex = 902
	cosmeticGrid.Parent = body

	mkText(body, "weapon filter", UDim2.fromOffset(10, 6), UDim2.new(1, -20, 0, 18))
	local weaponSearch = mkBox(body, "grenade launcher...", UDim2.fromOffset(10, 28), UDim2.new(1, -20, 0, 24))
	mkText(body, "cosmetic filter", UDim2.fromOffset(10, 326), UDim2.new(1, -20, 0, 18))
	local cosmeticSearch = mkBox(body, "red...", UDim2.fromOffset(10, 348), UDim2.new(1, -20, 0, 24))

	local modeButton = mkButton(body, "skin                                                                                  >", UDim2.fromOffset(10, 658), UDim2.new(1, -20, 0, 26))
	local modeMenu = Instance.new("Frame")
	modeMenu.BackgroundColor3 = Theme.Field
	modeMenu.BorderColor3 = Theme.Border
	modeMenu.Position = UDim2.fromOffset(10, 684)
	modeMenu.Size = UDim2.new(1, -20, 0, 104)
	modeMenu.Visible = false
	modeMenu.ZIndex = 910
	modeMenu.Parent = body

	local modes = {"Skin", "Wrap", "Charm", "Finisher"}
	for i, mode in ipairs(modes) do
		local row = mkButton(modeMenu, mode:lower(), UDim2.fromOffset(0, (i - 1) * 26), UDim2.new(1, 0, 0, 26))
		row.ZIndex = 911
		row.TextXAlignment = Enum.TextXAlignment.Left
		row.MouseButton1Click:Connect(function()
			cosmeticGuiState.Mode = mode
			if cosmeticGuiState.SelectedWeapon then
				local currentEquip = equip[cosmeticGuiState.SelectedWeapon]
				if currentEquip and currentEquip[mode] then
					cosmeticGuiState.SelectedCosmetic = currentEquip[mode].Name
				else
					cosmeticGuiState.SelectedCosmetic = nil
				end
			else
				cosmeticGuiState.SelectedCosmetic = nil
			end
			modeButton.Text = mode:lower() .. "                                                                                  >"
			modeMenu.Visible = false
			rebuildCosmeticLists()
			task.defer(function()
				if cosmeticGuiState.Refresh then cosmeticGuiState.Refresh() end
			end)
		end)
	end

	local applyAll = mkButton(body, "apply selected to all", UDim2.fromOffset(10, 690), UDim2.new(1, -20, 0, 26))
	local reset = mkButton(body, "reset to defaults", UDim2.fromOffset(10, 720), UDim2.new(0.5, -12, 0, 26))
	local close = mkButton(body, "close", UDim2.new(0.5, 2, 0, 720), UDim2.new(0.5, -12, 0, 26))
	mkText(body, "right click a weapon to toggle the skin changer for it.", UDim2.fromOffset(10, 750), UDim2.new(1, -20, 0, 18), 12).TextColor3 = Theme.Muted

	local function passes(entry, query)
		query = tostring(query or ""):lower()
		return query == "" or entry.Name:lower():find(query, 1, true) or entry.Display:lower():find(query, 1, true)
	end

	local function clearChildren(frame)
		for _, child in ipairs(frame:GetChildren()) do
			if child:IsA("GuiObject") then child:Destroy() end
		end
	end

	local function makeWrapPreview(parent, entry)
		local data = entry and entry.Data
		local groups = data and data.WrapGroups
		if not groups then return false end

		local viewport = Instance.new("ViewportFrame")
		viewport.BackgroundTransparency = 1
		viewport.Position = UDim2.fromOffset(2, 1)
		viewport.Size = UDim2.fromOffset(126, 90)
		viewport.LightColor = Color3.fromRGB(255, 255, 255)
		viewport.Ambient = Theme.Muted
		viewport.ZIndex = 904
		viewport.Parent = parent

		local camera = Instance.new("Camera")
		camera.CFrame = CFrame.new(0, 0.15, 0.75) * CFrame.Angles(math.rad(-8), 0, 0)
		camera.Parent = viewport
		viewport.CurrentCamera = camera

		local model
		if wrapPreviewAsset then
			local ok, cloned = pcall(function()
				return wrapPreviewAsset:Clone()
			end)
			if ok and cloned then
				model = cloned
				model.Parent = viewport
			end
		end

		if model then
			for _, obj in ipairs(model:GetDescendants()) do
				if obj:IsA("BasePart") then
					obj.Anchored = true
					obj.CanCollide = false
				end
			end
			for _, obj in ipairs(model:GetDescendants()) do
				if obj:IsA("BasePart") then
					local wrapGroup = obj:GetAttribute("WrapGroup")
					local group = groups[wrapGroup] or groups[1] or {}
					if typeof(group.Color) == "Color3" then obj.Color = group.Color end
					if group.Transparency ~= nil then obj.Transparency = group.Transparency end
					if group.Reflectance ~= nil then obj.Reflectance = group.Reflectance end
					if group.Material then obj.Material = group.Material end
					pcall(function()
						obj.MaterialVariant = group.MaterialVariant or ""
					end)
					if obj:IsA("MeshPart") then
						pcall(function()
							obj.TextureID = ""
						end)
					end
					if group.Textures and wrapTextureAssets then
						local folder = wrapTextureAssets:FindFirstChild(group.Textures)
						if folder then
							for _, texture in ipairs(folder:GetChildren()) do
								pcall(function()
									local clonedTexture = texture:Clone()
									if clonedTexture.LocalTransparencyModifier ~= nil then
										clonedTexture.LocalTransparencyModifier = obj.LocalTransparencyModifier
									end
									clonedTexture.Parent = obj
								end)
							end
						end
					end
				end
			end
			pcall(function()
				model:PivotTo(CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-10), math.rad(24), math.rad(-8)))
				local _, size = model:GetBoundingBox()
				local scale = math.max(size.X, size.Y, size.Z)
				camera.CFrame = CFrame.new(0, 0.05, math.clamp(scale * 0.41, 0.43, 1.15)) * CFrame.Angles(math.rad(-7), 0, 0)
			end)
			return true
		end

		model = Instance.new("Model")
		model.Name = "WrapPreview"
		model.Parent = viewport

		local sliceCount = math.max(1, math.min(3, #groups))
		for i = 1, sliceCount do
			local group = groups[i]
			local color = group and group.Color or Color3.fromRGB(150, 150, 150)
			if typeof(color) ~= "Color3" then color = Color3.fromRGB(150, 150, 150) end
			local slice = Instance.new("Part")
			slice.Anchored = true
			slice.CanCollide = false
			slice.Material = (group and group.Material) or Enum.Material.SmoothPlastic
			slice.Color = color
			slice.Transparency = group and group.Transparency or 0
			slice.Reflectance = group and group.Reflectance or 0
			slice.Size = Vector3.new(1.8 / sliceCount, 1.55, 0.22)
			slice.CFrame = CFrame.new((i - (sliceCount + 1) / 2) * (1.8 / sliceCount), 0, 0) * CFrame.Angles(0, math.rad(-18), math.rad(-8))
			slice.Parent = model
		end

		return true
	end

	local function makeCharmPreview(parent, entry)
		if not entry or not entry.Data or entry.Data.Type ~= "Charm" then return false end
		if charmAssets then
			local source = charmAssets:FindFirstChild(entry.Name)
			if source then
				local ok = pcall(function()
					local viewport = Instance.new("ViewportFrame")
					viewport.BackgroundTransparency = 1
					viewport.Position = UDim2.fromOffset(2, 1)
					viewport.Size = UDim2.fromOffset(126, 90)
					viewport.LightColor = Color3.fromRGB(255, 255, 255)
					viewport.Ambient = Color3.fromRGB(190, 190, 190)
					viewport.ZIndex = 904
					viewport.Parent = parent

					local camera = Instance.new("Camera")
					camera.CFrame = CFrame.new(0, 0, 0.2)
					camera.Parent = viewport
					viewport.CurrentCamera = camera

					local clone = source:Clone()
					clone.Parent = viewport
					local hook = clone:FindFirstChild("Hook", true)
					if hook then hook:Destroy() end

					if clone:IsA("Model") then
						local primary = clone.PrimaryPart or clone:FindFirstChild("Primary") or clone:FindFirstChildWhichIsA("BasePart", true)
						if primary then clone.PrimaryPart = primary end
						clone:PivotTo(CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-12), math.rad(35), 0))
						local _, size = clone:GetBoundingBox()
						local scale = math.max(size.X, size.Y, size.Z)
						if scale > 0 then
							camera.CFrame = CFrame.new(0, 0, math.clamp(scale * 0.107, 0.113, 0.333))
						end
					elseif clone:IsA("BasePart") then
						clone.Anchored = true
						clone.CFrame = CFrame.new()
					end
				end)
				if ok then return true end
			end
		end

		local hash = 0
		for i = 1, #entry.Name do
			hash = (hash + string.byte(entry.Name, i) * i) % 255
		end
		local color = Color3.fromHSV(hash / 255, 0.65, 1)

		local badge = Instance.new("Frame")
		badge.BackgroundColor3 = color
		badge.BorderColor3 = Theme.Text
		badge.Position = UDim2.fromOffset(30, 8)
		badge.Size = UDim2.fromOffset(70, 70)
		badge.Rotation = 45
		badge.ZIndex = 904
		badge.Parent = parent

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 10)
		corner.Parent = badge

		local text = Instance.new("TextLabel")
		text.BackgroundTransparency = 1
		text.Font = Enum.Font.SourceSansBold
		text.Text = string.sub(entry.Display or entry.Name or "C", 1, 1):upper()
		text.TextColor3 = Color3.fromRGB(255, 255, 255)
		text.TextScaled = true
		text.Rotation = -45
		text.Position = UDim2.fromOffset(10, 10)
		text.Size = UDim2.fromOffset(50, 50)
		text.ZIndex = 905
		text.Parent = badge
		return true
	end

	local function makeTile(parent, entry, index, selected, callback, rightCallback, largeWeaponPreview)
		local col = (index - 1) % cosmeticGuiState.Columns
		local row = math.floor((index - 1) / cosmeticGuiState.Columns)
		local tile = Instance.new("TextButton")
		tile.AutoButtonColor = false
		tile.BackgroundColor3 = selected and Color3.fromRGB(28, 44, 35) or Theme.Card
		tile.BorderColor3 = selected and Color3.fromRGB(70, 140, 95) or Theme.CardHead
		tile.Position = UDim2.fromOffset(col * cosmeticGuiState.TileW, row * cosmeticGuiState.TileH)
		tile.Size = UDim2.fromOffset(cosmeticGuiState.TileW, cosmeticGuiState.TileH)
		tile.ClipsDescendants = true
		tile.Text = ""
		tile.ZIndex = 903
		tile.Parent = parent

		local hasCustomPreview = false
		if not hasCustomPreview and (entry.Image == nil or entry.Image == "") and entry.Data and entry.Data.Type == "Wrap" then
			hasCustomPreview = makeWrapPreview(tile, entry)
		end
		if not hasCustomPreview and (entry.Image == nil or entry.Image == "") and entry.Data and entry.Data.Type == "Charm" then
			hasCustomPreview = makeCharmPreview(tile, entry)
		end
		if not hasCustomPreview then
			local img = Instance.new("ImageLabel")
			img.BackgroundTransparency = 1
			img.Image = entry.Image or ""
			img.ScaleType = Enum.ScaleType.Fit
			img.Position = largeWeaponPreview and UDim2.fromOffset(-61, -43) or UDim2.fromOffset(14, 9)
			img.Size = largeWeaponPreview and UDim2.fromOffset(252, 176) or UDim2.fromOffset(102, 76)
			img.ZIndex = 904
			img.Parent = tile
		end

		local name = Instance.new("TextLabel")
		name.BackgroundTransparency = 1
		name.Font = Enum.Font.SourceSansBold
		name.Text = entry.Display
		name.TextColor3 = Color3.fromRGB(245, 245, 245)
		name.TextScaled = true
		name.TextWrapped = true
		name.Position = UDim2.fromOffset(6, 86)
		name.Size = UDim2.fromOffset(118, 32)
		name.ZIndex = 904
		name.Parent = tile

		tile.MouseButton1Click:Connect(function()
			callback(entry)
		end)
		tile.MouseButton2Click:Connect(function()
			if rightCallback then rightCallback(entry) end
		end)
	end

	local function refresh()
		clearChildren(weaponGrid)
		clearChildren(cosmeticGrid)
		local wcount = 0
		for _, entry in ipairs(cosmeticGuiState.Weapons) do
			if passes(entry, cosmeticGuiState.WeaponSearch) then
				wcount += 1
				makeTile(weaponGrid, entry, wcount, cosmeticGuiState.SelectedWeapon == entry.Name, function(chosen)
					cosmeticGuiState.SelectedWeapon = chosen.Name
					local currentEquip = equip[chosen.Name]
					if currentEquip and currentEquip[cosmeticGuiState.Mode] then
						cosmeticGuiState.SelectedCosmetic = currentEquip[cosmeticGuiState.Mode].Name
					else
						cosmeticGuiState.SelectedCosmetic = nil
					end
					rebuildCosmeticLists()
					refresh()
				end, function(chosen)
					cosmeticGuiState.SelectedWeapon = chosen.Name
					applyCosmeticToWeapon(chosen.Name, cosmeticGuiState.SelectedCosmetic, cosmeticGuiState.Mode)
					rebuildCosmeticLists()
					refresh()
				end, true)
			end
		end
		weaponGrid.CanvasSize = UDim2.fromOffset(0, math.max(264, math.ceil(wcount / cosmeticGuiState.Columns) * cosmeticGuiState.TileH))

		local randomEntry = {Name = "__random", Display = "Random", Image = "rbxassetid://132973552546079"}
		makeTile(cosmeticGrid, randomEntry, 1, cosmeticGuiState.SelectedCosmetic == "__random", function()
			cosmeticGuiState.SelectedCosmetic = "__random"
			if cosmeticGuiState.SelectedWeapon then applyCosmeticToWeapon(cosmeticGuiState.SelectedWeapon, "__random", cosmeticGuiState.Mode) end
			rebuildCosmeticLists()
			refresh()
		end)

		local ccount = 1
		for _, entry in ipairs(cosmeticGuiState.Cosmetics) do
			if passes(entry, cosmeticGuiState.CosmeticSearch) then
				ccount += 1
				makeTile(cosmeticGrid, entry, ccount, cosmeticGuiState.SelectedCosmetic == entry.Name, function(chosen)
					cosmeticGuiState.SelectedCosmetic = chosen.Name
					if cosmeticGuiState.SelectedWeapon then applyCosmeticToWeapon(cosmeticGuiState.SelectedWeapon, chosen.Name, cosmeticGuiState.Mode) end
					rebuildCosmeticLists()
					refresh()
				end, nil, cosmeticGuiState.Mode == "Skin")
			end
		end
		cosmeticGrid.CanvasSize = UDim2.fromOffset(0, math.max(276, math.ceil(ccount / cosmeticGuiState.Columns) * cosmeticGuiState.TileH))
	end

	cosmeticGuiState.Refresh = refresh

	local wSearchThread, cSearchThread
	weaponSearch:GetPropertyChangedSignal("Text"):Connect(function()
		cosmeticGuiState.WeaponSearch = weaponSearch.Text
		if wSearchThread then task.cancel(wSearchThread) end
		wSearchThread = task.delay(0.1, refresh)
	end)
	cosmeticSearch:GetPropertyChangedSignal("Text"):Connect(function()
		cosmeticGuiState.CosmeticSearch = cosmeticSearch.Text
		if cSearchThread then task.cancel(cSearchThread) end
		cSearchThread = task.delay(0.1, refresh)
	end)
	modeButton.MouseButton1Click:Connect(function()
		modeMenu.Visible = not modeMenu.Visible
	end)
	applyAll.MouseButton1Click:Connect(function()
		local selected = cosmeticGuiState.SelectedCosmetic
		if not selected then return end
		for _, weapon in ipairs(cosmeticGuiState.Weapons) do
			applyCosmeticToWeapon(weapon.Name, selected, cosmeticGuiState.Mode, true)
			task.defer(forceCosmeticUpdate, weapon.Name, cosmeticGuiState.Mode)
		end
		rebuildinv()
		saferep("CosmeticInventory")
		saferep("WeaponInventory")
		rebuildCosmeticLists()
		refresh()
	end)
	reset.MouseButton1Click:Connect(function()
		table.clear(equip)
		table.clear(fcache)
		rebuildinv()
		saferep("WeaponInventory")
		rebuildCosmeticLists()
		refresh()
	end)
	close.MouseButton1Click:Connect(function()
		cosmeticGuiState.Wanted = false
		if shared.LilacCosmeticChangerToggle and shared.LilacCosmeticChangerToggle.Toggle then
			shared.LilacCosmeticChangerToggle:Toggle(false)
		else
			gui.Visible = false
		end
	end)

	local nextCosmeticGuiUpdate = 0
	mainapi:Clean(RunService.Heartbeat:Connect(function()
		local now = os.clock()
		if now < nextCosmeticGuiUpdate then return end
		nextCosmeticGuiUpdate = now + 0.1
		local menuOpen = mainapi.ClickGuiStatus == true
		pcall(function()
			if LionWindow and LionWindow.Holder then
				menuOpen = LionWindow.Holder.Visible == true
			end
		end)
		gui.Visible = cosmeticGuiState.Wanted and menuOpen
	end))

	refresh()
	return gui
end

shared.LilacCosmeticChanger = {
	SetVisible = function(visible)
		cosmeticGuiState.Wanted = visible == true
		makeCosmeticChanger()
		if visible then
			rebuildCosmeticLists()
			if cosmeticGuiState.Refresh then cosmeticGuiState.Refresh() end
		end
	end,
	Toggle = function()
		cosmeticGuiState.Wanted = not cosmeticGuiState.Wanted
		makeCosmeticChanger()
		rebuildCosmeticLists()
		if cosmeticGuiState.Refresh then cosmeticGuiState.Refresh() end
	end,
	Refresh = function()
		rebuildCosmeticLists()
		if cosmeticGuiState.Refresh then cosmeticGuiState.Refresh() end
	end,
	GetEquipData = function()
		local export = {}
		for w, cats in pairs(equip) do
			export[w] = {}
			for cat, data in pairs(cats) do
				export[w][cat] = data and data.Name or nil
			end
		end
		return export
	end,
	LoadEquipData = function(data)
		if type(data) ~= "table" then return end
		for w, cats in pairs(data) do
			if type(cats) == "table" then
				for cat, name in pairs(cats) do
					applyCosmeticToWeapon(w, name, cat, true)
					task.defer(function()
						pcall(forceCosmeticUpdate, w, cat)
					end)
				end
			end
		end
		rebuildinv()
		saferep("CosmeticInventory")
		saferep("WeaponInventory")
		if cosmeticGuiState.SelectedWeapon then
			local currentEquip = equip[cosmeticGuiState.SelectedWeapon]
			if currentEquip and currentEquip[cosmeticGuiState.Mode] then
				cosmeticGuiState.SelectedCosmetic = currentEquip[cosmeticGuiState.Mode].Name
			else
				cosmeticGuiState.SelectedCosmetic = nil
			end
		end
		rebuildCosmeticLists()
		if cosmeticGuiState.Refresh then cosmeticGuiState.Refresh() end
	end,
	Apply = applyCosmeticToWeapon,
	State = cosmeticGuiState
}

end)


end -- skin changer scope
