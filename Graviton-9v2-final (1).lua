--[[
	Graviton-9v2
	movement · character · visuals · spoofing · settings
	toggle menu: RightShift (rebindable in settings)
	rivals spoofer integrated (identity · leaderboard · charms · currency · skinchanger)
]]

-- ── AC bypass (setmetatable hook) ────────────────────────────────────────────
do
	if getgenv and getgenv().__GV_SetmtBP ~= game
		and hookfunction and newcclosure and getrenv then
		getgenv().__GV_SetmtBP = game
		local ok = pcall(function()
			local oldsetmt
			local rawget_, rawlen_, type_ = rawget, rawlen, type
			oldsetmt = hookfunction(getrenv().setmetatable, newcclosure(function(t, mt)
				if type_(mt) == "table" and rawget_(mt, "__mode") == "kv"
				   and type_(t) == "table" and rawlen_(t) == 4
				   and type_(rawget_(t, 1)) == "table"
				   and rawget_(t, 2) == 1
				   and rawget_(t, 3) == "String"
				   and type_(rawget_(t, 4)) == "userdata" then
					return oldsetmt({ 1, 2, 3 }, {})
				end
				return oldsetmt(t, mt)
			end))
		end)
		if not ok then getgenv().__GV_SetmtBP = nil end
	end
end
-- ─────────────────────────────────────────────────────────────────────────────

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local Lighting = game:GetService("Lighting")
local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- unload any previous copy
if getgenv then
	for _, key in ipairs({"__Graviton9v2", "__Graviton9v1", "__VoidwareV2", "__TestPanel"}) do
		if getgenv()[key] then pcall(getgenv()[key].Destroy) getgenv()[key] = nil end
	end
end
local parent = (gethui and gethui()) or game:GetService("CoreGui")

local conns = {}
local function bind(c) table.insert(conns, c) return c end
local function tween(o, p, t) TweenService:Create(o, TweenInfo.new(t or 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), p):Play() end

local T = {
	bg = Color3.fromRGB(4, 3, 7), side = Color3.fromRGB(7, 5, 11), card = Color3.fromRGB(10, 8, 15),
	row = Color3.fromRGB(16, 13, 24), stroke = Color3.fromRGB(26, 21, 38), text = Color3.fromRGB(242, 238, 255),
	sub = Color3.fromRGB(120, 108, 150), off = Color3.fromRGB(28, 23, 40), accent = Color3.fromRGB(168, 85, 247),
}
-- fonts: Michroma for the logo / headers, Jura for everything else
local F = {
	title = Font.new("rbxasset://fonts/families/Michroma.json", Enum.FontWeight.Regular),
	body = Font.new("rbxasset://fonts/families/Jura.json", Enum.FontWeight.Medium),
	bold = Font.new("rbxasset://fonts/families/Jura.json", Enum.FontWeight.Bold),
}
local ACCENTS = {
	Color3.fromRGB(168, 85, 247), -- purple (default)
	Color3.fromRGB(56, 189, 248), -- cyan
	Color3.fromRGB(52, 211, 153), -- mint
	Color3.fromRGB(251, 113, 133), -- rose
	Color3.fromRGB(250, 204, 21), -- gold
}

local accentObjs, accentHooks = {}, {}
local function A(o, prop) table.insert(accentObjs, {o, prop}) o[prop] = T.accent return o end
local function setAccent(c)
	T.accent = c
	for _, v in ipairs(accentObjs) do if v[1].Parent then v[1][v[2]] = c end end
	for _, f in ipairs(accentHooks) do f() end
end
local function new(class, props, p)
	local o = Instance.new(class)
	for k, v in pairs(props or {}) do o[k] = v end
	o.Parent = p
	return o
end
local function corner(o, r) return new("UICorner", {CornerRadius = UDim.new(0, T.simple and math.min(r or 8, 3) or (r or 8))}, o) end
local function stroke(o, c) return new("UIStroke", {Color = c or T.stroke, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, o) end
local function text(p, props)
	local t = new("TextLabel", {BackgroundTransparency = 1, FontFace = F.body, TextSize = 16, TextColor3 = T.text, TextXAlignment = Enum.TextXAlignment.Left}, p)
	for k, v in pairs(props) do t[k] = v end
	if t.AutomaticSize == Enum.AutomaticSize.None and not t.TextScaled then
		new("UITextSizeConstraint", {MaxTextSize = t.TextSize, MinTextSize = math.min(8, t.TextSize)}, t)
		t.TextWrapped = false
		t.TextScaled = true
	end
	return t
end
local function hex(c) return string.format("#%02x%02x%02x", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5)) end
local function isPress(i) return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch end
local function isMove(i) return i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch end

---------------------------------------------------------------- window
local gui = new("ScreenGui", {Name = "Graviton9v2", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, IgnoreGuiInset = true}, parent)
-- dark backdrop behind the window while it's open
local DIM = {amount = 45}
local dim = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 0}, gui)
new("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 0.15)}), Rotation = 90}, dim)

-- the window is a CanvasGroup so the whole thing can fade as one
-- ui size: 1.25x by default, automatically capped so the window always fits on screen
local UI = {scale = 1.25, height = 440, minHeight = 440}
local function fitScale()
	local vp = Camera.ViewportSize
	return math.max(0.3, math.min(UI.scale, vp.X * 0.95 / 610, vp.Y * 0.95 / 440))
end
local main = new("CanvasGroup", {Size = UDim2.fromOffset(610, UI.height), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundColor3 = T.bg,
	GroupTransparency = 1, Visible = false, ZIndex = 2}, gui)
corner(main, 12) stroke(main)
local mainScale = new("UIScale", {Scale = fitScale() * 0.96}, main)
local glow = A(new("Frame", {Size = UDim2.new(1, 0, 0, 2), BorderSizePixel = 0, ZIndex = 5}, main), "BackgroundColor3")
new("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1)})}, glow)

-- sidebar
-- title bar across the top with the logo centered
local titleBar = new("Frame", {Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = T.side, BorderSizePixel = 0}, main)
new("Frame", {Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1), BackgroundColor3 = T.stroke, BorderSizePixel = 0}, titleBar)
-- narrow icon sidebar down the left
local side = new("Frame", {Size = UDim2.new(0, 60, 1, -38), Position = UDim2.fromOffset(0, 38), BackgroundColor3 = T.side, BorderSizePixel = 0}, main)
new("Frame", {Size = UDim2.new(0, 1, 1, 0), Position = UDim2.new(1, -1, 0, 0), BackgroundColor3 = T.stroke, BorderSizePixel = 0}, side)
local logo = text(titleBar, {RichText = true, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 38), AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 16, 0, 0), FontFace = F.title, TextSize = 18})
local LOGO_VOID = Color3.fromRGB(0, 0, 0) -- black "Graviton" (the glow outline keeps it readable)
local LOGO_V2 = Color3.fromRGB(217, 54, 162) -- reddish purple for "V2"
-- black hole next to the logo: a glowing accretion disk swirling around a pitch-black core.
-- the back of the disk passes behind the hole and the front passes over it, like the real thing,
-- with a bright photon ring hugging the core and specks of light spiralling in.
;(function() -- runs once in its own scope (keeps the top-level slot count low)
	local SZ = 30
	local bh = new("Frame", {Name = "Emblem_void", Size = UDim2.fromOffset(SZ, SZ), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(0, -8, 0.5, 0),
		BackgroundTransparency = 1}, logo)
	local HOT = Color3.fromRGB(255, 225, 250)
	local function circle(d, col, tr, z)
		local f = new("Frame", {Size = UDim2.fromOffset(d, d), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
			BackgroundColor3 = col, BackgroundTransparency = tr, BorderSizePixel = 0, ZIndex = z}, bh)
		new("UICorner", {CornerRadius = UDim.new(0.5, 0)}, f)
		return f
	end
	-- soft outer glow (stacked fading circles)
	local glows = {circle(30, T.accent, 0.92, 1), circle(24, T.accent, 0.85, 1), circle(18, LOGO_V2, 0.8, 1)}
	-- accretion disk: a flat ring with a swirling hot gradient
	local function disk(z, frontOnly)
		local holder, pos = bh, UDim2.fromScale(0.5, 0.5)
		if frontOnly then
			-- the near (lower) half of the ring is drawn in front of the core, clipped to the bottom half
			holder = new("Frame", {Size = UDim2.fromOffset(SZ + 4, SZ / 2 + 2), Position = UDim2.fromOffset(-2, SZ / 2),
				BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = z}, bh)
			pos = UDim2.new(0.5, 0, 0, 0)
		end
		local d = new("Frame", {Size = UDim2.fromOffset(30, 10), AnchorPoint = Vector2.new(0.5, 0.5), Position = pos,
			BackgroundTransparency = 1, ZIndex = z}, holder)
		new("UICorner", {CornerRadius = UDim.new(0.5, 0)}, d)
		local st = new("UIStroke", {Thickness = 2.6, Color = Color3.new(1, 1, 1)}, d)
		return new("UIGradient", {}, st)
	end
	local backDisk = disk(2, false)
	-- event horizon: pitch black core with a bright photon ring hugging it
	local photon = circle(12, HOT, 0, 3)
	local core = circle(10, Color3.new(0, 0, 0), 0, 4)
	local frontDisk = disk(5, true)
	-- specks of light spiralling inward
	local specks = {}
	for i = 1, 7 do
		local sp = circle(2, HOT, 0, 5)
		specks[i] = {f = sp, a = math.random() * math.pi * 2, r = 6 + math.random() * 9, sp = 1.5 + math.random() * 2}
	end
	local function paint(rot)
		local seq = ColorSequence.new({ColorSequenceKeypoint.new(0, T.accent), ColorSequenceKeypoint.new(0.3, HOT),
			ColorSequenceKeypoint.new(0.55, LOGO_V2), ColorSequenceKeypoint.new(0.8, T.accent), ColorSequenceKeypoint.new(1, T.accent)})
		backDisk.Color, frontDisk.Color = seq, seq
		backDisk.Rotation, frontDisk.Rotation = rot, rot
	end
	paint(0)
	table.insert(accentHooks, function()
		glows[1].BackgroundColor3, glows[2].BackgroundColor3 = T.accent, T.accent
		paint(backDisk.Rotation)
	end)
	bind(RunService.Heartbeat:Connect(function(dt)
		if not bh.Parent then return end
		local t = os.clock()
		paint((t * 160) % 360)
		local pulse = (math.sin(t * 2.4) + 1) / 2
		photon.BackgroundTransparency = 0.15 + pulse * 0.35
		photon.Size = UDim2.fromOffset(12 + pulse * 1.5, 12 + pulse * 1.5)
		glows[1].BackgroundTransparency = 0.94 - pulse * 0.05
		glows[3].BackgroundTransparency = 0.82 - pulse * 0.08
		for _, s in ipairs(specks) do
			s.a += dt * s.sp * (12 / math.max(s.r, 3))
			s.r -= dt * 3.5
			if s.r < 5.5 then s.r, s.a = 13 + math.random() * 3, math.random() * math.pi * 2 end
			s.f.Position = UDim2.new(0.5, math.cos(s.a) * s.r, 0.5, math.sin(s.a) * s.r * 0.34)
			s.f.BackgroundTransparency = 1 - math.clamp((s.r - 5.5) / 4, 0, 1) * 0.9
		end
	end))
end)()
local UIFX = {notifyOn = true, toggleAlerts = true, popups = {}}
;(function() -- runs once in its own scope (keeps the top-level slot count low)
	-- animated gradient border: purple -> reddish purple slowly rotating around the window edge
	local border = main:FindFirstChildOfClass("UIStroke")
	if border then
		border.Color, border.Thickness = Color3.new(1, 1, 1), 1.5
		local g = new("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.1),
			NumberSequenceKeypoint.new(0.5, 0.65), NumberSequenceKeypoint.new(1, 0.1)})}, border)
		local function paint()
			g.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, T.accent), ColorSequenceKeypoint.new(0.5, LOGO_V2), ColorSequenceKeypoint.new(1, T.accent)})
		end
		paint() table.insert(accentHooks, paint)
		bind(RunService.Heartbeat:Connect(function() g.Rotation = (os.clock() * 45) % 360 end))
		UIFX.setBorderSimple = function(on)
			g.Enabled = not on
			border.Color = on and T.stroke or Color3.new(1, 1, 1)
			border.Thickness = on and 1 or 1.5
		end
	end

	-- click ripple: a soft circle that expands from where you clicked
	function UIFX.ripple(btn)
		if T.simple then return end
		local sc = mainScale.Scale > 0 and mainScale.Scale or 1
		local m = UIS:GetMouseLocation() - btn.AbsolutePosition
		local pos = Vector2.new(m.X, m.Y) / sc
		local size = math.max(btn.AbsoluteSize.X, btn.AbsoluteSize.Y) / sc * 2.2
		local c = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(pos.X, pos.Y), Size = UDim2.fromOffset(0, 0),
			BackgroundColor3 = T.accent, BackgroundTransparency = 0.55, BorderSizePixel = 0, ZIndex = (btn.ZIndex or 1) + 1}, btn)
		new("UICorner", {CornerRadius = UDim.new(0.5, 0)}, c)
		local info = TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
		TweenService:Create(c, info, {Size = UDim2.fromOffset(size, size), BackgroundTransparency = 1}):Play()
		task.delay(0.5, function() c:Destroy() end)
	end

	-- toast notifications: slide in at the bottom-right, even while the menu is hidden
	local holder = new("Frame", {AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -18, 1, -18), Size = UDim2.fromOffset(260, 320),
		BackgroundTransparency = 1, ZIndex = 30}, gui)
	new("UIListLayout", {VerticalAlignment = Enum.VerticalAlignment.Bottom, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, holder)
	local hs = new("UIScale", {Scale = math.min(fitScale(), 1.3)}, holder)
	local count, live = 0, {}
	UIFX.notifyCount = 0
	function UIFX.notify(msg)
		UIFX.notifyCount += 1
		if not UIFX.notifyOn then return end
		count += 1
		hs.Scale = math.min(fitScale(), 1.3)
		local slot = new("Frame", {Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, LayoutOrder = count, ZIndex = 30}, holder)
		local box = new("Frame", {Size = UDim2.fromScale(1, 1), Position = UDim2.fromOffset(290, 0), BackgroundColor3 = T.card, ZIndex = 30}, slot)
		corner(box, 10)
		new("UIStroke", {Color = T.accent, Transparency = 0.55}, box)
		local bar = new("Frame", {Size = UDim2.new(0, 3, 1, -16), Position = UDim2.fromOffset(9, 8), BackgroundColor3 = T.accent, BorderSizePixel = 0, ZIndex = 31}, box)
		corner(bar, 2)
		text(box, {Text = msg, Size = UDim2.new(1, -32, 1, 0), Position = UDim2.fromOffset(22, 0), TextSize = 13, ZIndex = 31, TextTruncate = Enum.TextTruncate.AtEnd})
		local prog = new("Frame", {Size = UDim2.new(1, -20, 0, 2), Position = UDim2.new(0, 10, 1, -4), BackgroundColor3 = LOGO_V2, BorderSizePixel = 0, ZIndex = 31}, box)
		corner(prog, 1)
		table.insert(live, slot)
		if #live > 5 then local old = table.remove(live, 1) if old.Parent then old:Destroy() end end
		TweenService:Create(box, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.fromOffset(0, 0)}):Play()
		TweenService:Create(prog, TweenInfo.new(2.6, Enum.EasingStyle.Linear), {Size = UDim2.new(0, 0, 0, 2)}):Play()
		task.delay(2.6, function()
			if not slot.Parent then return end
			TweenService:Create(box, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = UDim2.fromOffset(290, 0)}):Play()
			task.wait(0.3)
			local i = table.find(live, slot) if i then table.remove(live, i) end
			slot:Destroy()
		end)
	end
end)()
;(function() -- runs once in its own scope (keeps the top-level slot count low)
	-- "Graviton" starry-night effects:
	--   * letters drift between black and deep midnight blue like a night sky
	--   * a soft pale starlight glow pulses around them
	--   * tiny stars twinkle over and around the word
	--   * a random letter sparkles bright every few seconds, and a shooting star streaks past now and then
	local NIGHT_HI = Color3.fromRGB(42, 32, 100)
	local STARLIGHT = Color3.fromRGB(205, 195, 255)
	local SPARKLE = Color3.fromRGB(240, 235, 255)
	local sparkle = {idx = 0, untilT = 0, nextT = os.clock() + 2}

	-- how much of the logo's width "Graviton" takes up (measured once, so the stars sit over the right letters)
	local VOID_RATIO = 0.4
	task.spawn(function()
		local ok, r = pcall(function()
			local TextService = game:GetService("TextService")
			local a = Instance.new("GetTextBoundsParams") a.Text, a.Font, a.Size, a.Width = "Graviton", F.title, 40, 10000
			local b = Instance.new("GetTextBoundsParams") b.Text, b.Font, b.Size, b.Width = "Graviton-9v2", F.title, 40, 10000
			return TextService:GetTextBoundsAsync(a).X / TextService:GetTextBoundsAsync(b).X
		end)
		if ok and r and r > 0 then VOID_RATIO = r end
	end)

	local starField = new("Frame", {BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, -4, 0.5, 0), ZIndex = 3}, logo)
	local stars = {}
	for i = 1, 18 do
		local big = math.random() < 0.25
		local s = big and 2 or 1
		local f = new("Frame", {Size = UDim2.fromOffset(s, s), AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0, ZIndex = 3,
			BackgroundColor3 = STARLIGHT:Lerp(Color3.new(1, 1, 1), math.random())}, starField)
		new("UICorner", {CornerRadius = UDim.new(0.5, 0)}, f)
		stars[i] = {f = f, x = math.random(), y = math.random(), sp = 1 + math.random() * 3, ph = math.random() * 6.28, big = big}
	end
	local shoot = new("Frame", {Size = UDim2.fromOffset(18, 1), AnchorPoint = Vector2.new(1, 0.5), BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0, Rotation = 20, Visible = false, ZIndex = 3}, starField)
	new("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0)})}, shoot)
	local shooting = {active = false, t0 = 0, nextT = os.clock() + 3}

	local function drawLogo()
		if T.simple then
			logo.Text = string.format('Graviton-9<font color="%s">v2</font>', hex(T.accent))
			return
		end
		local t = os.clock()
		if t > sparkle.nextT then
			sparkle.idx, sparkle.untilT, sparkle.nextT = math.random(1, 8), t + 0.18, t + 2 + math.random() * 3
		end
		local pulse = (math.sin(t * 1.8) + 1) / 2
		local letters = {}
		for i, ch in ipairs({"G", "r", "a", "v", "i", "t", "o", "n"}) do
			local wave = (math.sin(t * 1.6 - i * 0.9) + 1) / 2
			local col = LOGO_VOID:Lerp(NIGHT_HI, wave)
			if i == sparkle.idx and t < sparkle.untilT then col = SPARKLE end
			letters[i] = string.format('<font color="%s">%s</font>', hex(col), ch)
		end
		-- "ware" + "V2": a faint glimmer that sweeps across them every few seconds, plus a whisper of glow
		local sweep = 8 + ((t % 4.2) / 0.9) * 5 -- travels across letters 9..12 in 0.9s, then rests
		local rest = {}
		for i, ch in ipairs({"-", "9", "v", "2"}) do
			local idx = i + 8
			local base = idx <= 10 and T.accent or LOGO_V2
			local g = math.max(0, 1 - math.abs(idx - sweep) / 1.3)
			rest[i] = string.format('<font color="%s">%s</font>', hex(base:Lerp(Color3.new(1, 1, 1), g * 0.5)), ch)
		end
		local soft = (math.sin(t * 1.3 + 1) + 1) / 2
		logo.Text = string.format('<stroke color="%s" thickness="%.1f" transparency="%.2f">%s</stroke><stroke color="%s" thickness="1" transparency="%.2f">%s</stroke>',
			hex(STARLIGHT), 1 + pulse * 1.2, 0.55 - pulse * 0.35, table.concat(letters),
			hex(T.accent), 0.88 - soft * 0.12, table.concat(rest))
	end
	local function drawStars()
		starField.Visible = not T.simple
		if T.simple then return end
		local t = os.clock()
		local tb = logo.TextBounds
		local w, h = tb.X * VOID_RATIO + 8, tb.Y + 8
		starField.Size = UDim2.fromOffset(w, h)
		for _, s in ipairs(stars) do
			local tw = ((math.sin(t * s.sp + s.ph) + 1) / 2) ^ 3
			s.f.Position = UDim2.fromOffset(s.x * w, s.y * h)
			s.f.BackgroundTransparency = 1 - tw * (s.big and 1 or 0.85)
		end
		if not shooting.active and t > shooting.nextT then
			shooting.active, shooting.t0 = true, t
		end
		if shooting.active then
			local k = (t - shooting.t0) / 0.55
			if k >= 1 then
				shooting.active, shooting.nextT = false, t + 4 + math.random() * 4
				shoot.Visible = false
			else
				shoot.Visible = true
				shoot.Position = UDim2.fromOffset(-0.1 * w + k * 1.2 * w, 0.1 * h + k * 0.7 * h)
				shoot.BackgroundTransparency = 1 - math.sin(math.pi * k)
			end
		end
	end
	drawLogo() table.insert(accentHooks, drawLogo)
	bind(RunService.Heartbeat:Connect(function() if logo.Parent then drawLogo() drawStars() end end))
end)()
local navList = new("Frame", {Size = UDim2.new(1, -12, 1, -66), Position = UDim2.fromOffset(6, 10), BackgroundTransparency = 1}, side)
-- your roblox headshot at the bottom of the sidebar
task.spawn(function()
	local ok, img = pcall(function() return Players:GetUserThumbnailAsync(LP.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48) end)
	if not ok or not side.Parent then return end
	local av = new("ImageButton", {Size = UDim2.fromOffset(36, 36), AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -12),
		BackgroundColor3 = T.row, Image = (type(img) == "string" and img or ""), AutoButtonColor = false}, side)
	new("UICorner", {CornerRadius = UDim.new(0.5, 0)}, av)
	local ring = new("UIStroke", {Color = T.accent, Thickness = 1.5, Transparency = 0.3}, av)
	UIFX.avatarRing = ring
	table.insert(accentHooks, function() ring.Color = T.accent end)
	bind(av.MouseButton1Click:Connect(function() if UIFX.openProfile then UIFX.openProfile() end end))
	bind(av.MouseEnter:Connect(function()
		tween(ring, {Transparency = 0})
		if UIFX.tip then
			local sc = mainScale.Scale > 0 and mainScale.Scale or 1
			UIFX.tipText.Text = "profile"
			UIFX.tip.Position = UDim2.fromOffset(66, (av.AbsolutePosition.Y - main.AbsolutePosition.Y) / sc + 6)
			UIFX.tip.Visible = true
		end
	end))
	bind(av.MouseLeave:Connect(function()
		tween(ring, {Transparency = UIFX.current == "profile" and 0 or 0.3})
		if UIFX.tip then UIFX.tip.Visible = false end
	end))
end)
new("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, navList)

-- content
local content = new("Frame", {Size = UDim2.new(1, -60, 1, -38), Position = UDim2.fromOffset(60, 38), BackgroundTransparency = 1}, main)
local topbar = new("Frame", {Size = UDim2.new(1, 0, 0, 46), BackgroundTransparency = 1}, content)
new("Frame", {Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1), BackgroundColor3 = T.stroke, BorderSizePixel = 0}, topbar)
-- tab bar: shows the current page's tabs (pages like visuals have several attached tabs)
local tabBar = new("Frame", {Size = UDim2.new(1, -24, 1, 0), Position = UDim2.fromOffset(12, 0), BackgroundTransparency = 1}, topbar)
new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center,
	Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, tabBar)
local hint = text(topbar, {Size = UDim2.new(0, 140, 1, 0), Position = UDim2.new(1, -154, 0, 0), TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = T.sub, TextSize = 13})
local pagesHolder = new("Frame", {Size = UDim2.new(1, 0, 1, -46), Position = UDim2.fromOffset(0, 46), BackgroundTransparency = 1}, content)

-- keep the whole window on screen: clamps its offset from the center so no edge goes past the screen
local function clampOff(off)
	local sz = gui.AbsoluteSize
	local sc = fitScale()
	local maxX = math.max(0, sz.X / 2 - 610 * sc / 2 - 8)
	local maxY = math.max(0, sz.Y / 2 - UI.height * sc / 2 - 8)
	return Vector2.new(math.clamp(off.X, -maxX, maxX), math.clamp(off.Y, -maxY, maxY))
end
local function keepOnScreen()
	local off = clampOff(Vector2.new(main.Position.X.Offset, main.Position.Y.Offset))
	main.Position = UDim2.new(0.5, off.X, 0.5, off.Y)
end

-- resize handle along the bottom edge: drag it to make the window taller (the top stays put)
;(function() -- runs once in its own scope (keeps the top-level slot count low)
	local grip = new("TextButton", {Size = UDim2.new(1, -120, 0, 12), AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, 0),
		BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 8}, main)
	local pill = new("Frame", {Size = UDim2.fromOffset(46, 4), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		BackgroundColor3 = T.sub, BackgroundTransparency = 0.55, BorderSizePixel = 0, ZIndex = 8}, grip)
	new("UICorner", {CornerRadius = UDim.new(0.5, 0)}, pill)
	local function maxHeight()
		local sc = mainScale.Scale > 0 and mainScale.Scale or 1
		return math.max(UI.minHeight, math.floor((gui.AbsoluteSize.Y * 0.95) / sc))
	end
	-- change the height while keeping the top edge where it is
	function UI.setHeight(h, keepTop)
		h = math.clamp(math.floor(tonumber(h) or UI.minHeight), UI.minHeight, maxHeight())
		local sc = mainScale.Scale > 0 and mainScale.Scale or 1
		local dh = h - UI.height
		UI.height = h
		main.Size = UDim2.fromOffset(610, h)
		if keepTop ~= false then
			main.Position = UDim2.new(0.5, main.Position.X.Offset, 0.5, main.Position.Y.Offset + dh * sc / 2)
		end
		keepOnScreen()
	end
	local resizing, startY, startH, lastClick = false, 0, 0, 0
	bind(grip.InputBegan:Connect(function(i)
		if not isPress(i) then return end
		if os.clock() - lastClick < 0.35 then
			-- double-click: back to normal height
			TweenService:Create(pill, TweenInfo.new(0.2), {BackgroundColor3 = T.accent}):Play()
			UI.setHeight(UI.minHeight)
			UIFX.notify("window height reset")
			lastClick = 0
			return
		end
		lastClick = os.clock()
		resizing, startY, startH = true, UIS:GetMouseLocation().Y, UI.height
		tween(pill, {BackgroundColor3 = T.accent, BackgroundTransparency = 0, Size = UDim2.fromOffset(70, 4)})
	end))
	bind(UIS.InputChanged:Connect(function(i)
		if resizing and isMove(i) then
			local sc = mainScale.Scale > 0 and mainScale.Scale or 1
			UI.setHeight(startH + (UIS:GetMouseLocation().Y - startY) / sc)
		end
	end))
	bind(UIS.InputEnded:Connect(function(i)
		if resizing and isPress(i) then
			resizing = false
			tween(pill, {BackgroundColor3 = T.sub, BackgroundTransparency = 0.55, Size = UDim2.fromOffset(46, 4)})
			if UI.height ~= startH and UIFX.toggleAlerts then UIFX.notify("window height  ·  " .. UI.height) end
		end
	end))
	bind(grip.MouseEnter:Connect(function() if not resizing then tween(pill, {BackgroundColor3 = T.accent, BackgroundTransparency = 0.2}) end end))
	bind(grip.MouseLeave:Connect(function() if not resizing then tween(pill, {BackgroundColor3 = T.sub, BackgroundTransparency = 0.55}) end end))
end)()

-- drag trail: fading outlines of the window left behind while you drag it
local TRAIL = {
	on = true,
	length = 35,     -- how long each outline lingers (%)
	spacing = 6,     -- pixels the window must move before leaving another outline
	fill = 12,       -- how visible the inside of each outline is (%)
	outline = 15,    -- outline thickness (x10 px)
	shrink = 3,      -- how much each outline shrinks while fading (%)
	gradient = true, -- shift purple <-> reddish purple along the trail
	color = Color3.fromRGB(168, 85, 247),
	smooth = 50,     -- how much the window glides behind your mouse while dragging (0 = locked to mouse)
}
local ghostCount = 0
local function spawnGhostAt(off)
	ghostCount += 1
	local life = 0.12 + TRAIL.length / 100 * 0.55
	local col = TRAIL.gradient and T.accent:Lerp(LOGO_V2, (math.sin(ghostCount * 0.18) + 1) / 2) or TRAIL.color
	local mp = main.Position
	local g = new("Frame", {Size = main.Size, AnchorPoint = main.AnchorPoint, Position = UDim2.new(mp.X.Scale, off.X, mp.Y.Scale, off.Y), BackgroundColor3 = col,
		BackgroundTransparency = 1 - TRAIL.fill / 100, ZIndex = 1}, gui)
	corner(g, 12)
	local gs = new("UIStroke", {Color = col, Thickness = TRAIL.outline / 10, Transparency = TRAIL.outline > 0 and 0.3 or 1}, g)
	local sc = new("UIScale", {Scale = mainScale.Scale}, g)
	local info = TweenInfo.new(life, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	TweenService:Create(g, info, {BackgroundTransparency = 1}):Play()
	TweenService:Create(gs, info, {Transparency = 1}):Play()
	TweenService:Create(sc, info, {Scale = mainScale.Scale * (1 - TRAIL.shrink / 100)}):Play()
	task.delay(life, function() g:Destroy() end)
end

-- dragging: the window glides toward the mouse every frame, and the trail is laid down at even
-- spacing along the path it actually travelled, so fast drags don't leave gaps
;(function() -- runs once in its own scope (keeps the top-level slot count low)
	local dragging, start, startOff, targetOff, curOff, lastGhostOff = false, nil, nil, nil, nil, nil
	local function offsets() return Vector2.new(main.Position.X.Offset, main.Position.Y.Offset) end
	local function begin(i)
		if isPress(i) then
			dragging, start = true, i.Position
			startOff = offsets()
			targetOff, curOff, lastGhostOff = startOff, startOff, startOff
		end
	end
	bind(logo.InputBegan:Connect(begin)) bind(topbar.InputBegan:Connect(begin)) bind(titleBar.InputBegan:Connect(begin))
	bind(UIS.InputChanged:Connect(function(i)
		if dragging and isMove(i) then
			local d = i.Position - start
			targetOff = clampOff(startOff + Vector2.new(d.X, d.Y))
		end
	end))
	bind(UIS.InputEnded:Connect(function(i) if isPress(i) then dragging = false end end))
	bind(RunService.RenderStepped:Connect(function(dt)
		if not (curOff and targetOff) or (curOff - targetOff).Magnitude < 0.05 then return end
		local alpha = TRAIL.smooth <= 0 and 1 or 1 - math.exp(-dt * (45 - TRAIL.smooth * 0.35))
		curOff = curOff:Lerp(targetOff, alpha)
		main.Position = UDim2.new(main.Position.X.Scale, curOff.X, main.Position.Y.Scale, curOff.Y)
		if TRAIL.on and TRAIL.length > 0 and lastGhostOff and not T.simple then
			local delta = curOff - lastGhostOff
			local dist = delta.Magnitude
			if dist >= TRAIL.spacing then
				local n = math.min(math.floor(dist / TRAIL.spacing), 16)
				local dir = delta.Unit
				for k = 1, n do spawnGhostAt(lastGhostOff + dir * TRAIL.spacing * k) end
				lastGhostOff = lastGhostOff + dir * TRAIL.spacing * n
				if (curOff - lastGhostOff).Magnitude > TRAIL.spacing * 2 then lastGhostOff = curOff end
			end
		end
	end))
end)()

---------------------------------------------------------------- snowfall (drawn over the window, doesn't block clicks)
local snowLayer = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 4, ClipsDescendants = true}, main)
local SN = {on = true, amount = 60, speed = 100, size = 3, wind = 0, color = Color3.new(1, 1, 1)}
local flakes = {}
local function spawnFlake(randomY)
	local sz = SN.size * (0.6 + math.random() * 0.8)
	local f = new("Frame", {BackgroundColor3 = SN.color:Lerp(Color3.new(1, 1, 1), math.random() * 0.35), BackgroundTransparency = 0.2 + math.random() * 0.5,
		BorderSizePixel = 0, Size = UDim2.fromOffset(sz, sz), ZIndex = 4}, snowLayer)
	new("UICorner", {CornerRadius = UDim.new(0.5, 0)}, f)
	local W, H = main.Size.X.Offset, main.Size.Y.Offset
	if W < 1 then W, H = 610, 440 end
	table.insert(flakes, {f = f, sz = sz, x = math.random() * W, y = randomY and math.random() * H or -sz,
		vy = 22 + math.random() * 38, phase = math.random() * 6.28, sway = 3 + math.random() * 9})
end
local function syncFlakes()
	local want = SN.on and SN.amount or 0
	while #flakes < want do spawnFlake(true) end
	while #flakes > want do table.remove(flakes).f:Destroy() end
end
local function rebuildFlakes()
	for _, fl in ipairs(flakes) do fl.f:Destroy() end
	table.clear(flakes)
	syncFlakes()
end
bind(RunService.RenderStepped:Connect(function(dt)
	snowLayer.Visible = not T.simple
	if #flakes == 0 or not main.Visible or T.simple then return end
	local W, H = main.Size.X.Offset, main.Size.Y.Offset
	local spd, t = SN.speed / 100, os.clock()
	for _, fl in ipairs(flakes) do
		fl.y += fl.vy * spd * dt
		fl.x += SN.wind * 0.5 * dt
		if fl.y > H then fl.y = -fl.sz fl.x = math.random() * W end
		if fl.x > W then fl.x -= W elseif fl.x < -fl.sz then fl.x += W end
		fl.f.Position = UDim2.fromOffset(fl.x + math.sin(t * 1.4 + fl.phase) * fl.sway, fl.y)
	end
end))

-- sidebar icons drawn from shapes (so they always render, and recolor with the theme)
function UIFX.icon(name, parent)
	local holder = new("Frame", {Size = UDim2.fromOffset(22, 22), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		BackgroundTransparency = 1}, parent)
	local paint = {}
	-- outline box (x, y, w, h, corner radius in px or "round")
	local function ob(x, y, w, h, rad)
		local f = new("Frame", {Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), BackgroundTransparency = 1}, holder)
		new("UICorner", {CornerRadius = rad == "round" and UDim.new(0.5, 0) or UDim.new(0, rad or 1)}, f)
		table.insert(paint, {new("UIStroke", {Thickness = 1.5}, f), "Color"})
		return f
	end
	-- filled shape centered at (cx, cy), optionally rotated
	local function fb(cx, cy, w, h, rot, rad)
		local f = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(cx, cy), Size = UDim2.fromOffset(w, h),
			Rotation = rot or 0, BorderSizePixel = 0}, holder)
		if rad then new("UICorner", {CornerRadius = rad == "round" and UDim.new(0.5, 0) or UDim.new(0, rad)}, f) end
		table.insert(paint, {f, "BackgroundColor3"})
		return f
	end
	if name == "movement" then
		-- fast-forward double chevron
		for _, x in ipairs({5, 12}) do
			fb(x + 0.6, 8.4, 7.8, 2.4, 45, 1.2)
			fb(x + 0.6, 13.6, 7.8, 2.4, -45, 1.2)
		end
	elseif name == "character" then
		-- blocky roblox player outline
		ob(8, 0, 6, 6, 1.5)     -- head
		ob(6.5, 7, 9, 7.5, 1)   -- torso
		ob(2, 7, 3.5, 7.5, 1)   -- left arm
		ob(16.5, 7, 3.5, 7.5, 1) -- right arm
		ob(6.5, 15.5, 4, 6.5, 1) -- left leg
		ob(11.5, 15.5, 4, 6.5, 1) -- right leg
	elseif name == "visuals" then
		-- eye
		ob(1, 6, 20, 10, "round")
		ob(7, 7, 8, 8, "round")
		fb(11, 11, 3, 3, 0, "round")
	elseif name == "esp" then
		-- target
		ob(4, 4, 14, 14, "round")
		fb(11, 11, 3, 3, 0, "round")
		fb(11, 1.5, 1.6, 4) fb(11, 20.5, 1.6, 4) fb(1.5, 11, 4, 1.6) fb(20.5, 11, 4, 1.6)
	elseif name == "misc" then
		-- 4-square grid
		ob(2.5, 2.5, 7, 7, 2) ob(12.5, 2.5, 7, 7, 2) ob(2.5, 12.5, 7, 7, 2) ob(12.5, 12.5, 7, 7, 2)
	elseif name == "settings" then
		-- gear
		for i = 0, 7 do
			local a = i / 8 * math.pi * 2
			fb(11 + math.cos(a) * 8, 11 + math.sin(a) * 8, 3.2, 4, math.deg(a) + 90, 1)
		end
		ob(4.5, 4.5, 13, 13, "round")
		ob(8.5, 8.5, 5, 5, "round")
	elseif name == "combat" then
		-- pistol, facing right
		ob(1.5, 5, 18, 5.5, 1.5)          -- slide / barrel
		fb(20.5, 7.75, 1.6, 2.6, 0, 0.6)   -- muzzle tip
		fb(4.5, 5.6, 2, 1.6)               -- rear sight
		ob(3, 10, 6, 10, 1.5)              -- grip
		ob(9.5, 10, 4.5, 4.5, "round")     -- trigger guard
		fb(11.6, 12, 1.4, 2.6, 15, 0.6)    -- trigger
	elseif name == "ragebot" then
		-- crosshair with pulse ring: aim circle + 4 tick marks + center dot
		ob(3, 3, 16, 16, "round")                           -- outer ring
		fb(11, 1.5, 1.5, 4, 0, 0.5) fb(11, 20.5, 1.5, 4, 0, 0.5) -- top/bottom ticks
		fb(1.5, 11, 4, 1.5, 0, 0.5) fb(20.5, 11, 4, 1.5, 0, 0.5) -- left/right ticks
		fb(11, 11, 3.5, 3.5, 0, "round")                   -- center dot
	elseif name == "spoofing" then
		-- disguise mask
		ob(1.5, 6, 19, 9, 4.5)             -- mask band
		ob(4.5, 8.5, 4.5, 4, "round")      -- left eye hole
		ob(13, 8.5, 4.5, 4, "round")       -- right eye hole
		fb(11, 14.6, 4, 2.2, 0, 1)         -- nose bridge notch
		fb(1.2, 9.5, 3, 1.6, 20, 0.8)      -- left tie
		fb(20.8, 9.5, 3, 1.6, -20, 0.8)    -- right tie
	else
		local t = text(holder, {Text = string.upper(name:sub(1, 1)), Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center,
			FontFace = F.title, TextSize = 16})
		table.insert(paint, {t, "TextColor3"})
	end
	return function(c) for _, pp in ipairs(paint) do pp[1][pp[2]] = c end end
end

---------------------------------------------------------------- pages
local pages, navButtons, groups, navOrder, current = {}, {}, {}, 0, nil
local function navHeader(name)
	navOrder += 1
	local h = new("Frame", {Size = UDim2.new(1, 0, 0, 12), BackgroundTransparency = 1, LayoutOrder = navOrder}, navList)
	if navOrder > 1 then
		new("Frame", {Size = UDim2.new(0.5, 0, 0, 1), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
			BackgroundColor3 = T.stroke, BorderSizePixel = 0}, h)
	end
end
local function makePage()
	local pg = new("ScrollingFrame", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2,
		ScrollBarImageColor3 = T.off, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false}, pagesHolder)
	new("UIPadding", {PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10)}, pg)
	local cols = {}
	for i = 1, 2 do
		local col = new("Frame", {Size = UDim2.new(0.5, -5, 0, 0), Position = UDim2.new((i - 1) * 0.5, (i - 1) * 5, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1}, pg)
		new("UIListLayout", {Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder}, col)
		cols[i] = col
	end
	return pg, cols
end
local selectPage
-- page("name") makes a single page; page("name", {"a", "b"}) makes a page with attached tabs a and b
local function page(name, tabs)
	navOrder += 1
	local btn = new("TextButton", {Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = T.row, BackgroundTransparency = 1, AutoButtonColor = false, Text = "", LayoutOrder = navOrder}, navList)
	corner(btn, 8)
	local bar = A(new("Frame", {Size = UDim2.fromOffset(3, 20), Position = UDim2.new(0, 0, 0.5, -10), Visible = false, BorderSizePixel = 0}, btn), "BackgroundColor3")
	corner(bar, 3)
	-- the icon follows this hidden label's color, so the existing hover / select color animations drive it
	local lbl = text(btn, {Text = "", TextTransparency = 1, Size = UDim2.fromScale(1, 1), TextColor3 = T.sub})
	local paintIcon = UIFX.icon(name, btn)
	paintIcon(T.sub)
	lbl:GetPropertyChangedSignal("TextColor3"):Connect(function() paintIcon(lbl.TextColor3) end)
	if not UIFX.tip then
		UIFX.tip = new("Frame", {AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 24), BackgroundColor3 = T.card, Visible = false, ZIndex = 20}, main)
		corner(UIFX.tip, 6)
		new("UIStroke", {Color = T.stroke}, UIFX.tip)
		new("UIPadding", {PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)}, UIFX.tip)
		UIFX.tipText = text(UIFX.tip, {AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromScale(0, 1), TextSize = 12, ZIndex = 21, FontFace = F.title})
	end
	bind(btn.MouseEnter:Connect(function()
		local sc = mainScale.Scale > 0 and mainScale.Scale or 1
		local y = (btn.AbsolutePosition.Y - main.AbsolutePosition.Y) / sc + 8
		UIFX.tipText.Text = name
		UIFX.tip.Position = UDim2.fromOffset(66, y)
		UIFX.tip.Visible = true
	end))
	bind(btn.MouseLeave:Connect(function() UIFX.tip.Visible = false end))
	navButtons[name] = {btn = btn, lbl = lbl, bar = bar}
	groups[name] = {tabs = tabs or {name}, current = tabs and tabs[1] or name}
	local result
	if tabs then
		result = {}
		for _, s in ipairs(tabs) do
			local pg, cols = makePage()
			pages[name .. "/" .. s] = pg
			result[s] = cols
		end
	else
		local pg, cols = makePage()
		pages[name .. "/" .. name] = pg
		result = cols
	end
	btn.ClipsDescendants = true
	bind(btn.MouseButton1Down:Connect(function() UIFX.ripple(btn) end))
	bind(btn.MouseButton1Click:Connect(function() selectPage(name) end))
	bind(btn.MouseEnter:Connect(function() if current ~= name then tween(lbl, {TextColor3 = T.text}) end end))
	bind(btn.MouseLeave:Connect(function() if current ~= name then tween(lbl, {TextColor3 = T.sub}) end end))
	return result
end
local function renderTabs()
	for _, c in ipairs(tabBar:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
	local g = current and groups[current]
	if not g then return end
	for i, s in ipairs(g.tabs) do
		local on = s == g.current
		local b = new("TextButton", {AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 30), BackgroundColor3 = T.accent,
			BackgroundTransparency = on and 0.85 or 1, Text = s, FontFace = F.title, TextSize = 12, TextColor3 = on and T.accent or T.sub,
			AutoButtonColor = false, LayoutOrder = i}, tabBar)
		corner(b, 15)
		new("UIPadding", {PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12)}, b)
		if not on then
			b.MouseEnter:Connect(function() tween(b, {TextColor3 = T.text}) end)
			b.MouseLeave:Connect(function() tween(b, {TextColor3 = T.sub}) end)
			b.MouseButton1Click:Connect(function() g.current = s selectPage(current) end)
		end
	end
	task.defer(function()
		local layout = tabBar:FindFirstChildOfClass("UIListLayout")
		if not layout then return end
		local sc = mainScale.Scale > 0 and mainScale.Scale or 1
		local used = layout.AbsoluteContentSize.X / sc
		hint.Visible = used < tabBar.AbsoluteSize.X / sc - 150
	end)
end
table.insert(accentHooks, renderTabs)
function selectPage(name)
	current = name
	UIFX.current = name
	local key = name .. "/" .. groups[name].current
	for k, pg in pairs(pages) do
		local show = k == key
		if show and not pg.Visible and not T.simple then
			pg.Position = UDim2.fromOffset(0, 14)
			TweenService:Create(pg, TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.fromOffset(0, 0)}):Play()
		end
		pg.Visible = show
	end
	for n, nb in pairs(navButtons) do
		local on = n == name
		tween(nb.btn, {BackgroundTransparency = on and 0 or 1})
		tween(nb.lbl, {TextColor3 = on and T.text or T.sub})
		nb.bar.Visible = on
	end
	if UIFX.avatarRing then
		tween(UIFX.avatarRing, {Thickness = name == "profile" and 2.5 or 1.5, Transparency = name == "profile" and 0 or 0.3})
	end
	renderTabs()
end

---------------------------------------------------------------- components
-- every toggle / slider / color wheel / keybind registers here so configs can save and load it
local CONTROLS = {}
local function reg(id, getf, setf) CONTROLS[id] = {get = getf, set = setf} end
local cardOrder = 0
local function card(col, title)
	cardOrder += 1
	local c = new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = T.card, LayoutOrder = cardOrder}, col)
	corner(c, 10)
	local cardStroke = stroke(c)
	bind(c.MouseEnter:Connect(function() if not T.simple then tween(cardStroke, {Color = T.accent:Lerp(T.stroke, 0.55)}, 0.2) end end))
	bind(c.MouseLeave:Connect(function() tween(cardStroke, {Color = T.stroke}, 0.25) end))
	local head = new("Frame", {Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1}, c)
	local icon = A(new("Frame", {Size = UDim2.fromOffset(4, 14), Position = UDim2.new(0, 12, 0.5, -7)}, head), "BackgroundColor3")
	corner(icon, 2)
	text(head, {Text = title, Size = UDim2.new(1, -40, 1, 0), Position = UDim2.fromOffset(24, 0), FontFace = F.title, TextSize = 13})
	local body = new("Frame", {Size = UDim2.new(1, 0, 0, 0), Position = UDim2.fromOffset(0, 30), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1}, c)
	new("UIPadding", {PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 12)}, body)
	new("UIListLayout", {Padding = UDim.new(0, 7), SortOrder = Enum.SortOrder.LayoutOrder}, body)
	local rowOrder = 0
	local api = {}
	api.rows = {}
	api.frame, api.head, api.body = c, head, body
	local function row(h)
		rowOrder += 1
		local f = new("Frame", {Size = UDim2.new(1, 0, 0, h), BackgroundTransparency = 1, LayoutOrder = rowOrder}, body)
		table.insert(api.rows, f)
		return f
	end

	function api.toggle(label, default, cb)
		local r = row(26)
		text(r, {Text = label, Size = UDim2.new(1, -50, 1, 0)})
		local sw = new("TextButton", {Size = UDim2.fromOffset(32, 16), Position = UDim2.new(1, -32, 0.5, -8), BackgroundColor3 = T.off, Text = "", AutoButtonColor = false}, r)
		corner(sw, 8)
		local knob = new("Frame", {Size = UDim2.fromOffset(10, 10), Position = UDim2.fromOffset(3, 3), BackgroundColor3 = T.sub}, sw)
		corner(knob, 5)
		local glowS = new("UIStroke", {Color = T.accent, Thickness = 2, Transparency = 1}, sw)
		local state, t = false, {}
		local function paint(anim)
			local f = anim and tween or function(o, p) for k, v in pairs(p) do o[k] = v end end
			glowS.Color = T.accent
			f(glowS, {Transparency = (state and not T.simple) and 0.55 or 1})
			f(sw, {BackgroundColor3 = state and T.accent or T.off})
			f(knob, {Position = state and UDim2.fromOffset(19, 3) or UDim2.fromOffset(3, 3), BackgroundColor3 = state and T.bg or T.sub})
		end
		function t.set(v, silent) state = v paint(true) if not silent then cb(v) end end
		function t.get() return state end
		table.insert(accentHooks, function() paint(false) end)
		bind(sw.MouseButton1Click:Connect(function()
			t.set(not state)
			if UIFX.toggleAlerts then UIFX.notify(label .. (state and "  ·  on" or "  ·  off")) end
		end))
		if default then t.set(true) end
		reg(title .. "/" .. label, t.get, function(v) if v ~= state then t.set(v) end end)
		return t
	end

	function api.slider(label, min, max, default, cb, suffix, step)
		step = step or 1
		local r = row(22)
		local track = new("TextButton", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.row, Text = "", AutoButtonColor = false, ClipsDescendants = true}, r)
		corner(track, 11)
		local fill = new("Frame", {Size = UDim2.fromScale(0, 1), BorderSizePixel = 0, BackgroundColor3 = Color3.new(1, 1, 1)}, track)
		local fillGrad = new("UIGradient", {}, fill)
		local function paintFill() fillGrad.Color = T.simple and ColorSequence.new(T.accent) or ColorSequence.new(T.accent, T.accent:Lerp(LOGO_V2, 0.7)) end
		paintFill() table.insert(accentHooks, paintFill)
		local trackStroke = new("UIStroke", {Color = T.accent, Transparency = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, track)
		bind(track.MouseEnter:Connect(function() tween(trackStroke, {Transparency = 0.5}) end))
		bind(track.MouseLeave:Connect(function() tween(trackStroke, {Transparency = 1}) end))
		corner(fill, 11)
		text(track, {Text = label, Size = UDim2.new(1, -88, 1, 0), Position = UDim2.fromOffset(10, 0), TextSize = 13, ZIndex = 2})
		local valLbl = text(track, {Size = UDim2.new(0, 72, 1, 0), Position = UDim2.new(1, -82, 0, 0), TextSize = 13, ZIndex = 2, TextXAlignment = Enum.TextXAlignment.Right, FontFace = F.bold})
		local cur = default
		local function set(v)
			v = math.clamp(math.floor(v / step + 0.5) * step, min, max)
			cur = v
			tween(fill, {Size = UDim2.fromScale((v - min) / (max - min), 1)}, 0.08)
			valLbl.Text = (step < 1 and string.format("%.1f", v) or tostring(v)) .. (suffix or "")
			cb(v)
		end
		local sliding = false
		local function fromX(x) set(min + (max - min) * math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)) end
		bind(track.InputBegan:Connect(function(i) if isPress(i) then sliding = true fromX(i.Position.X) end end))
		bind(UIS.InputChanged:Connect(function(i) if sliding and isMove(i) then fromX(i.Position.X) end end))
		bind(UIS.InputEnded:Connect(function(i)
			if isPress(i) and sliding then
				sliding = false
				if UIFX.toggleAlerts then UIFX.notify(label .. "  ·  " .. valLbl.Text) end
			end
		end))
		set(default)
		reg(title .. "/" .. label, function() return cur end, set)
		return {set = set}
	end

	function api.button(label, cb)
		local r = row(30)
		local b = new("TextButton", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.row, Text = label, FontFace = F.bold, TextSize = 15, TextColor3 = T.text, AutoButtonColor = false, TextScaled = true}, r)
		new("UITextSizeConstraint", {MaxTextSize = 15, MinTextSize = 8}, b)
		new("UIPadding", {PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), PaddingTop = UDim.new(0, 5), PaddingBottom = UDim.new(0, 5)}, b)
		corner(b, 8)
		b.ClipsDescendants = true
		local s = stroke(b)
		bind(b.MouseButton1Down:Connect(function() UIFX.ripple(b) end))
		bind(b.MouseEnter:Connect(function() tween(s, {Color = T.accent}) end))
		bind(b.MouseLeave:Connect(function() tween(s, {Color = T.stroke}) end))
		bind(b.MouseButton1Click:Connect(function()
			local before = UIFX.notifyCount
			cb(b)
			if UIFX.toggleAlerts and UIFX.notifyCount == before then UIFX.notify(b.Text) end
		end))
		return b
	end

	function api.hotkey(label, cb)
		local r = row(26)
		r.ClipsDescendants = false
		text(r, {Text = label, Size = UDim2.new(1, -80, 1, 0)})
		local hkKey     = nil
		local hkMode    = "toggle"   -- "toggle" | "hold" | "always"
		local hkListening = false

		-- pill button
		local pill = new("TextButton", {
			Size = UDim2.fromOffset(70, 20), Position = UDim2.new(1, -70, 0.5, -10),
			BackgroundColor3 = T.row, BackgroundTransparency = 0.2,
			Text = "none", FontFace = F.body, TextSize = 11,
			TextColor3 = T.sub,
			AutoButtonColor = false, BorderSizePixel = 0, ZIndex = 5,
		}, r)
		corner(pill, 9)
		new("UIStroke", {Color = T.stroke, Thickness = 1, Transparency = 0.3}, pill)

		local function refreshPill()
			if hkListening then
				pill.Text = "..." pill.TextColor3 = T.text
			elseif hkKey then
				pill.Text = hkKey.Name .. " [" .. hkMode:sub(1,1) .. "]"
				pill.TextColor3 = T.accent
			else
				pill.Text = "none" pill.TextColor3 = T.sub
			end
		end

		-- right-click mode popup (parented to gui so it floats above everything)
		local modePopup = nil
		local closeConn  = nil
		local function closePopup()
			if closeConn then closeConn:Disconnect() closeConn = nil end
			if modePopup then modePopup:Destroy() modePopup = nil end
		end
		local function openPopup()
			closePopup()
			local MODES = { "toggle", "hold", "always" }
			-- compute screen position relative to gui origin
			local guiPos   = gui.AbsolutePosition
			local pillPos  = pill.AbsolutePosition
			local pillSize = pill.AbsoluteSize
			local px = pillPos.X - guiPos.X
			local py = pillPos.Y - guiPos.Y + pillSize.Y + 4
			local popH = #MODES * 26 + 8
			-- if popup would go below screen, flip above
			if pillPos.Y + pillSize.Y + 4 + popH > workspace.CurrentCamera.ViewportSize.Y then
				py = pillPos.Y - guiPos.Y - popH - 4
			end
			local popup = new("Frame", {
				Size = UDim2.fromOffset(82, popH),
				Position = UDim2.fromOffset(px - 12, py),
				BackgroundColor3 = T.card,
				BackgroundTransparency = 0,
				BorderSizePixel = 0,
				ZIndex = 200,
				Active = true,
			}, gui)
			corner(popup, 8)
			new("UIStroke", {Color = T.stroke, Thickness = 1, Transparency = 0.1}, popup)
			new("UIPadding", {PaddingLeft = UDim.new(0,5), PaddingRight = UDim.new(0,5),
				PaddingTop = UDim.new(0,4), PaddingBottom = UDim.new(0,4)}, popup)
			new("UIListLayout", {Padding = UDim.new(0,2), SortOrder = Enum.SortOrder.LayoutOrder}, popup)
			modePopup = popup
			for idx, m in ipairs(MODES) do
				local active = (m == hkMode)
				local btn = new("TextButton", {
					Size = UDim2.new(1, 0, 0, 22),
					BackgroundColor3 = active and T.accent or T.row,
					BackgroundTransparency = active and 0.7 or 0.4,
					Text = m,
					FontFace = F.body,
					TextSize = 11,
					TextColor3 = active and T.accent or T.sub,
					AutoButtonColor = false,
					BorderSizePixel = 0,
					LayoutOrder = idx,
					ZIndex = 201,
				}, popup)
				corner(btn, 6)
				if active then
					new("UIStroke", {Color = T.accent, Thickness = 1, Transparency = 0.2}, btn)
					-- soft outer glow frame behind the button
					local glow = new("Frame", {
						Size = UDim2.new(1, 6, 1, 6),
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.fromScale(0.5, 0.5),
						BackgroundColor3 = T.accent,
						BackgroundTransparency = 0.82,
						BorderSizePixel = 0,
						ZIndex = 200,
					}, btn)
					corner(glow, 8)
				end
				bind(btn.MouseButton1Click:Connect(function()
					hkMode = m
					closePopup()
					refreshPill()
				end))
			end
			-- close on MB1 click outside the popup bounds
			task.delay(0.05, function()
				if not modePopup then return end
				closeConn = UIS.InputBegan:Connect(function(i, gp)
					if i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
					local mp = modePopup
					if not mp then closePopup(); return end
					local pos  = mp.AbsolutePosition
					local size = mp.AbsoluteSize
					local mx   = i.Position.X
					local my   = i.Position.Y
					local inside = mx >= pos.X and mx <= pos.X + size.X
						and my >= pos.Y and my <= pos.Y + size.Y
					if not inside then
						closePopup()
					end
				end)
			end)
		end

		bind(pill.MouseButton1Click:Connect(function()
			closePopup()
			hkListening = true; refreshPill()
		end))
		bind(pill.MouseButton2Click:Connect(function()
			if hkListening then hkListening = false; refreshPill(); return end
			openPopup()
		end))

		-- input: set key while listening; fire while held for hold/always modes
		bind(UIS.InputBegan:Connect(function(i, gp)
			if gp then return end
			if hkListening then
				if i.UserInputType == Enum.UserInputType.Keyboard then
					hkListening = false
					hkKey = (i.KeyCode ~= Enum.KeyCode.Escape) and i.KeyCode or nil
					refreshPill()
				end
				return
			end
			if hkKey and i.UserInputType == Enum.UserInputType.Keyboard and i.KeyCode == hkKey then
				cb(hkKey, hkMode, true)  -- true = pressed
			end
		end))
		bind(UIS.InputEnded:Connect(function(i)
			if hkKey and i.UserInputType == Enum.UserInputType.Keyboard and i.KeyCode == hkKey then
				cb(hkKey, hkMode, false)  -- false = released
			end
		end))

		return function() return hkKey, hkMode end
	end

	function api.swatches(label, colors, cb)
		local r = row(26)
		text(r, {Text = label, Size = UDim2.new(1, -110, 1, 0)})
		local holder = new("Frame", {Size = UDim2.new(0, 110, 1, 0), Position = UDim2.new(1, -110, 0, 0), BackgroundTransparency = 1}, r)
		new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 5)}, holder)
		for _, c in ipairs(colors) do
			local s = new("TextButton", {Size = UDim2.fromOffset(14, 14), BackgroundColor3 = c, Text = "", AutoButtonColor = false}, holder)
			corner(s, 7)
			bind(s.MouseButton1Click:Connect(function() cb(c) if UIFX.toggleAlerts then UIFX.notify(label .. "  ·  " .. hex(c)) end end))
		end
	end

	-- color wheel: hue around the circle, saturation from center outward, brightness on the bar below
	function api.colorwheel(label, default, cb)
		local h, s, v = default:ToHSV()
		local D = 120 local R = D / 2
		local head = row(26)
		text(head, {Text = label, Size = UDim2.new(1, -110, 1, 0)})
		local hexLbl = text(head, {Size = UDim2.new(0, 70, 1, 0), Position = UDim2.new(1, -96, 0, 0), TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = T.sub, TextSize = 13, Font = Enum.Font.Code})
		local preview = new("Frame", {Size = UDim2.fromOffset(20, 14), Position = UDim2.new(1, -20, 0.5, -7)}, head)
		corner(preview, 4) stroke(preview)
		local r = row(D + 4)
		local wheel = new("Frame", {Size = UDim2.fromOffset(D, D), Position = UDim2.new(0.5, -R, 0, 2), BackgroundTransparency = 1}, r)
		local N = 120
		local wedgeH = 2 * math.pi * R / N + 1.5
		for i = 0, N - 1 do
			local th = i * 360 / N
			local rad = math.rad(th)
			local w = new("Frame", {Size = UDim2.fromOffset(R, wedgeH), AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromOffset(R + math.cos(rad) * R / 2, R + math.sin(rad) * R / 2), Rotation = th,
				BorderSizePixel = 0, BackgroundColor3 = Color3.new(1, 1, 1)}, wheel)
			new("UIGradient", {Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromHSV(i / N, 1, 1))}, w)
		end
		local shade = new("Frame", {Size = UDim2.fromOffset(D + 2, D + 2), Position = UDim2.fromOffset(-1, -1), BackgroundColor3 = Color3.new(0, 0, 0), ZIndex = 3}, wheel)
		corner(shade, R + 1)
		local ring = new("Frame", {Size = UDim2.fromOffset(D + 2, D + 2), Position = UDim2.fromOffset(-1, -1), BackgroundTransparency = 1, ZIndex = 4}, wheel)
		corner(ring, R + 1)
		new("UIStroke", {Color = T.stroke, Thickness = 2}, ring)
		local cursor = new("Frame", {Size = UDim2.fromOffset(10, 10), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, ZIndex = 5}, wheel)
		corner(cursor, 5)
		new("UIStroke", {Color = Color3.new(1, 1, 1), Thickness = 2}, cursor)
		local hit = new("TextButton", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 6}, wheel)
		local vr = row(14)
		local vTrack = new("TextButton", {Size = UDim2.new(1, 0, 0, 10), Position = UDim2.fromOffset(0, 2), BackgroundColor3 = Color3.new(1, 1, 1), Text = "", AutoButtonColor = false}, vr)
		corner(vTrack, 5)
		local vGrad = new("UIGradient", {}, vTrack)
		local vKnob = new("Frame", {Size = UDim2.fromOffset(6, 14), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 2}, vTrack)
		corner(vKnob, 3) new("UIStroke", {Color = T.bg, Thickness = 1}, vKnob)
		local function refresh(fire)
			local col = Color3.fromHSV(h, s, v)
			local a = h * 2 * math.pi
			cursor.Position = UDim2.fromOffset(R + math.cos(a) * s * R, R + math.sin(a) * s * R)
			shade.BackgroundTransparency = v
			vGrad.Color = ColorSequence.new(Color3.new(0, 0, 0), Color3.fromHSV(h, s, 1))
			vKnob.Position = UDim2.new(v, 0, 0.5, 0)
			preview.BackgroundColor3 = col
			hexLbl.Text = hex(col)
			if fire ~= false then cb(col) end
		end
		local function mouse() return UIS:GetMouseLocation() end
		local function fromWheel()
			local Ra = wheel.AbsoluteSize.X / 2
			local d = mouse() - (wheel.AbsolutePosition + Vector2.new(Ra, Ra))
			h = (math.atan2(d.Y, d.X) / (2 * math.pi)) % 1
			s = math.clamp(d.Magnitude / Ra, 0, 1)
			refresh()
		end
		local function fromBar()
			v = math.clamp((mouse().X - vTrack.AbsolutePosition.X) / vTrack.AbsoluteSize.X, 0, 1)
			refresh()
		end
		local dragW, dragV = false, false
		bind(hit.InputBegan:Connect(function(i) if isPress(i) then dragW = true fromWheel() end end))
		bind(vTrack.InputBegan:Connect(function(i) if isPress(i) then dragV = true fromBar() end end))
		bind(UIS.InputChanged:Connect(function(i) if isMove(i) then if dragW then fromWheel() elseif dragV then fromBar() end end end))
		bind(UIS.InputEnded:Connect(function(i)
			if isPress(i) and (dragW or dragV) then
				dragW, dragV = false, false
				if UIFX.toggleAlerts then UIFX.notify(label .. "  ·  " .. hex(Color3.fromHSV(h, s, v))) end
			end
		end))
		refresh()
		reg(title .. "/" .. label, function() return Color3.fromHSV(h, s, v) end, function(c) h, s, v = c:ToHSV() refresh() end)
		return {set = function(c) h, s, v = c:ToHSV() refresh() end}
	end

	-- a button (with a preview of the color) that opens the color wheel in its own floating window
	-- you can drag around; several can be open at once
	function api.colorPopup(label, default, cb)
		local current = default
		local isOpen, setPop = false, nil
		local b = api.button(label, function()
			UIFX.notifyCount += 1 -- opening a color window isn't worth a notification
			if setPop then setPop(not isOpen) end
		end)
		b.TextXAlignment = Enum.TextXAlignment.Left
		local sw = new("Frame", {Size = UDim2.fromOffset(28, 14), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
			BackgroundColor3 = current, ZIndex = 3}, b)
		corner(sw, 7)
		new("UIStroke", {Color = T.stroke}, sw)

		-- the floating window
		local pop = new("CanvasGroup", {Size = UDim2.fromOffset(250, 0), AutomaticSize = Enum.AutomaticSize.Y, AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundColor3 = T.bg, Visible = false, GroupTransparency = 1, ZIndex = 30}, gui)
		corner(pop, 12)
		local pst = new("UIStroke", {Color = T.accent, Transparency = 0.35, Thickness = 1.5}, pop)
		table.insert(accentHooks, function() pst.Color = T.accent end)
		local psc = new("UIScale", {Scale = 0.92}, pop)
		local bar = new("Frame", {Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = T.side, BorderSizePixel = 0, ZIndex = 30}, pop)
		new("Frame", {Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1), BackgroundColor3 = T.stroke, BorderSizePixel = 0, ZIndex = 30}, bar)
		local dotA = new("Frame", {Size = UDim2.fromOffset(8, 8), Position = UDim2.new(0, 12, 0.5, -4), BackgroundColor3 = current, ZIndex = 31}, bar)
		corner(dotA, 4)
		text(bar, {Text = label, Size = UDim2.new(1, -70, 1, 0), Position = UDim2.fromOffset(28, 0), FontFace = F.title, TextSize = 12, ZIndex = 31})
		local close = new("TextButton", {Size = UDim2.fromOffset(24, 24), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -6, 0.5, 0),
			BackgroundColor3 = T.row, Text = "X", FontFace = F.bold, TextSize = 12, TextColor3 = T.sub, AutoButtonColor = false, ZIndex = 31}, bar)
		corner(close, 6)
		local content = new("Frame", {Size = UDim2.new(1, 0, 0, 0), Position = UDim2.fromOffset(0, 34), AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1, ZIndex = 30}, pop)
		new("UIPadding", {PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 10)}, content)
		new("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder}, content)
		local inner = card(content, title) -- same card name, so configs keep the same keys
		inner.head.Visible = false
		inner.body.Position = UDim2.fromOffset(0, 0)
		inner.frame.BackgroundTransparency = 1
		local fs = inner.frame:FindFirstChildOfClass("UIStroke")
		if fs then fs.Enabled = false end
		local wheel = inner.colorwheel(label, default, function(c)
			current = c
			sw.BackgroundColor3, dotA.BackgroundColor3 = c, c
			cb(c)
		end)

		-- open / close with a fade + pop
		setPop = function(v)
			isOpen = v
			if v then
				UIFX.popZ = (UIFX.popZ or 30) + 1
				pop.ZIndex = UIFX.popZ
				local sc = mainScale.Scale > 0 and mainScale.Scale or 1
				if not pop:GetAttribute("placed") then
					-- first time: open just to the right of the panel
					pop:SetAttribute("placed", true)
					local mp = main.Position
					pop.Position = UDim2.new(0.5, mp.X.Offset + (610 / 2 + 140) * sc + (#UIFX.popups % 3) * 18, 0.5, mp.Y.Offset - 60 + (#UIFX.popups % 3) * 18)
				end
				pop.Visible = true
				psc.Scale = sc * 0.92
				TweenService:Create(pop, TweenInfo.new(0.22, Enum.EasingStyle.Quart), {GroupTransparency = 0}):Play()
				TweenService:Create(psc, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = sc}):Play()
			else
				TweenService:Create(pop, TweenInfo.new(0.18), {GroupTransparency = 1}):Play()
				task.delay(0.18, function() if not isOpen then pop.Visible = false end end)
			end
		end
		table.insert(UIFX.popups, setPop)
		bind(close.MouseButton1Click:Connect(function() setPop(false) end))
		bind(close.MouseEnter:Connect(function() tween(close, {TextColor3 = T.text, BackgroundColor3 = LOGO_V2}) end))
		bind(close.MouseLeave:Connect(function() tween(close, {TextColor3 = T.sub, BackgroundColor3 = T.row}) end))

		-- drag by the title bar; clicking anywhere on it brings it to the front
		local dragging, start, startPos = false, nil, nil
		bind(bar.InputBegan:Connect(function(i)
			if isPress(i) then
				dragging, start, startPos = true, UIS:GetMouseLocation(), pop.Position
				UIFX.popZ = (UIFX.popZ or 30) + 1
				pop.ZIndex = UIFX.popZ
			end
		end))
		bind(UIS.InputChanged:Connect(function(i)
			if dragging and isMove(i) then
				local d = UIS:GetMouseLocation() - start
				pop.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
			end
		end))
		bind(UIS.InputEnded:Connect(function(i) if isPress(i) then dragging = false end end))
		return wheel
	end

	-- a button that opens / closes a color wheel underneath it
	function api.colorButton(label, default, cb)
		local open, wheelRows = false, {}
		api.button(label .. "  +", function(b)
			open = not open
			for _, r in ipairs(wheelRows) do r.Visible = open end
			b.Text = label .. (open and "  -" or "  +")
			UIFX.notifyCount += 1 -- opening the wheel isn't worth a notification
		end)
		local before = #api.rows
		local wheel = api.colorwheel(label, default, cb)
		for i = before + 1, #api.rows do
			table.insert(wheelRows, api.rows[i])
			api.rows[i].Visible = false
		end
		return wheel
	end

	function api.keybind(label, default, cb)
		local r = row(26)
		text(r, {Text = label, Size = UDim2.new(1, -90, 1, 0)})
		local b = new("TextButton", {Size = UDim2.fromOffset(92, 22), Position = UDim2.new(1, -92, 0.5, -11), BackgroundColor3 = T.row, Text = default.Name, FontFace = F.body, TextSize = 14, TextColor3 = T.sub, AutoButtonColor = false, TextScaled = true}, r)
		new("UITextSizeConstraint", {MaxTextSize = 14, MinTextSize = 8}, b)
		new("UIPadding", {PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6), PaddingTop = UDim.new(0, 3), PaddingBottom = UDim.new(0, 3)}, b)
		corner(b, 11)
		local listening, key = false, default
		bind(b.MouseButton1Click:Connect(function() listening = true b.Text = "press key..." end))
		bind(UIS.InputBegan:Connect(function(i)
			if listening and i.UserInputType == Enum.UserInputType.Keyboard then listening = false key = i.KeyCode b.Text = key.Name cb(key) if UIFX.toggleAlerts then UIFX.notify(label .. "  ·  " .. key.Name) end end
		end))
		reg(title .. "/" .. label, function() return key end, function(k) key = k b.Text = k.Name cb(k) end)
	end

	-- text box (used for config names)
	function api.textbox(placeholder, cb)
		local r = row(32)
		local tb = new("TextBox", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.row, PlaceholderText = placeholder, PlaceholderColor3 = T.sub,
			Text = "", FontFace = F.body, TextSize = 15, TextColor3 = T.text, ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left}, r)
		corner(tb, 8)
		new("UIPadding", {PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)}, tb)
		local s = stroke(tb)
		bind(tb.Focused:Connect(function() tween(s, {Color = T.accent}) end))
		bind(tb.FocusLost:Connect(function() tween(s, {Color = T.stroke}) if cb then cb(tb.Text) end end))
		return tb
	end

	-- a container that grows with whatever is put in it (used for the saved configs list)
	function api.list()
		rowOrder += 1
		local f = new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = rowOrder}, body)
		new("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, f)
		return f
	end

	function api.note(str)
		local r = row(17)
		return text(r, {Text = str, Size = UDim2.fromScale(1, 1), TextColor3 = T.sub, TextSize = 13})
	end
	return api
end

---------------------------------------------------------------- state
local S = {
	fly = false, flySpeed = 60, noclip = false, infJump = false,
	walk = 16, jump = 50, lock = true,
	fullbright = false, brightness = 2,
	noFog = false, customFog = false, fogStart = 0, fogEnd = 500, fogColor = Color3.fromRGB(190, 200, 215),
	worldTint = false, tintColor = Color3.fromRGB(255, 170, 120), tintStrength = 60, saturation = 0, contrast = 0,
	menuKey = Enum.KeyCode.RightShift,
}
local function char() return LP.Character end
local function hum() local c = char() return c and c:FindFirstChildOfClass("Humanoid") end
local function root() local c = char() return c and c:FindFirstChild("HumanoidRootPart") end

-- original lighting, restored when visuals are turned off
local L0 = {Brightness = Lighting.Brightness, ClockTime = Lighting.ClockTime, GlobalShadows = Lighting.GlobalShadows,
	Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient, FogStart = Lighting.FogStart, FogEnd = Lighting.FogEnd, FogColor = Lighting.FogColor}
local atmos = {}
for _, a in ipairs(Lighting:GetChildren()) do if a:IsA("Atmosphere") then atmos[a] = {Density = a.Density, Haze = a.Haze} end end
local function restoreLight()
	if not S.fullbright then for _, k in ipairs({"Brightness", "ClockTime", "GlobalShadows", "Ambient", "OutdoorAmbient"}) do Lighting[k] = L0[k] end end
	if not S.noFog and not S.customFog then
		Lighting.FogStart, Lighting.FogEnd, Lighting.FogColor = L0.FogStart, L0.FogEnd, L0.FogColor
		for a, v in pairs(atmos) do if a.Parent then a.Density, a.Haze = v.Density, v.Haze end end
	end
end
local tintFx = new("ColorCorrectionEffect", {Name = "Graviton9v2Tint", Enabled = false}, Lighting)

-- fly
local flyAtt, flyLV, flyAO
local function stopFly()
	for _, o in ipairs({flyLV, flyAO, flyAtt}) do if o then o:Destroy() end end
	flyLV, flyAO, flyAtt = nil, nil, nil
	local h = hum() if h then h.PlatformStand = false end
end
local function startFly()
	stopFly()
	local r, h = root(), hum() if not (r and h) then return end
	flyAtt = new("Attachment", {}, r)
	flyLV = new("LinearVelocity", {Attachment0 = flyAtt, MaxForce = math.huge, VelocityConstraintMode = Enum.VelocityConstraintMode.Vector, RelativeTo = Enum.ActuatorRelativeTo.World, VectorVelocity = Vector3.zero}, r)
	flyAO = new("AlignOrientation", {Attachment0 = flyAtt, Mode = Enum.OrientationAlignmentMode.OneAttachment, RigidityEnabled = true}, r)
	h.PlatformStand = true
end

-- desync visual: a local-only ghost copy of your character that lags behind and jitters.
-- purely cosmetic - your real character and what the server sees are untouched.
local DS = {on = false, delay = 150, offset = 2, rate = 12, opacity = 55, flicker = true, color = Color3.fromRGB(168, 85, 247)}
local ghost, ghostHL, motorPairs, ghostParts, ghostDecals = nil, nil, {}, {}, {}
local history, jitterVec, nextJitter, lastBuild = {}, Vector3.zero, 0, 0
local function destroyGhost()
	if ghost then ghost:Destroy() end
	ghost, ghostHL = nil, nil
	table.clear(motorPairs) table.clear(ghostParts) table.clear(ghostDecals) table.clear(history)
end
local function applyGhostLook()
	if not ghost then return end
	local tr = 1 - DS.opacity / 100
	for _, p in ipairs(ghostParts) do p.Transparency = p.Name == "HumanoidRootPart" and 1 or tr end
	for _, d in ipairs(ghostDecals) do d.Transparency = tr end
	if ghostHL then ghostHL.FillColor = DS.color ghostHL.OutlineColor = DS.color end
end
local function buildGhost()
	destroyGhost()
	lastBuild = os.clock()
	local c, r = char(), root()
	if not (c and r) then return end
	local was = c.Archivable
	c.Archivable = true
	local ok, g = pcall(function() return c:Clone() end)
	c.Archivable = was
	if not ok or not g then return end
	for _, d in ipairs(g:GetDescendants()) do
		if d:IsA("LuaSourceContainer") or d:IsA("Animator") or d:IsA("Sound") or d:IsA("ForceField") or d:IsA("Constraint")
			or d:IsA("BodyMover") or d:IsA("BillboardGui") or d:IsA("Highlight") then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.CanCollide, d.CanQuery, d.CanTouch, d.Massless = false, false, false, true
			d.Anchored = d.Name == "HumanoidRootPart"
			table.insert(ghostParts, d)
		elseif d:IsA("Decal") then
			table.insert(ghostDecals, d)
		end
	end
	local gh = g:FindFirstChildOfClass("Humanoid")
	if gh then
		pcall(function()
			gh.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
			gh.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
			gh.EvaluateStateMachine = false
		end)
	end
	for _, m in ipairs(c:GetDescendants()) do
		if m:IsA("Motor6D") and m.Parent then
			local gp = g:FindFirstChild(m.Parent.Name)
			local gm = gp and gp:FindFirstChild(m.Name)
			if gm and gm:IsA("Motor6D") then table.insert(motorPairs, {m, gm}) end
		end
	end
	g.Name = "VoidwareGhost"
	ghostHL = new("Highlight", {FillTransparency = 0.55, OutlineTransparency = 0.15, DepthMode = Enum.HighlightDepthMode.Occluded}, g)
	g.Parent = workspace
	ghost = g
	applyGhostLook()
end
bind(RunService.RenderStepped:Connect(function()
	if not DS.on then return end
	local r = root()
	if not r then return end
	if not (ghost and ghost.Parent) then
		if os.clock() - lastBuild > 1 then buildGhost() end
		return
	end
	local now = os.clock()
	table.insert(history, {now, r.CFrame})
	local target = now - DS.delay / 1000
	while #history > 1 and history[2][1] <= target do table.remove(history, 1) end
	if now >= nextJitter then
		nextJitter = now + 1 / DS.rate
		local o = DS.offset
		jitterVec = Vector3.new((math.random() * 2 - 1) * o, (math.random() * 2 - 1) * o * 0.3, (math.random() * 2 - 1) * o)
	end
	ghost:PivotTo(history[1][2] + jitterVec)
	for _, pr in ipairs(motorPairs) do if pr[2].Parent then pr[2].Transform = pr[1].Transform end end
	if ghostHL then ghostHL.Enabled = not (DS.flicker and math.random() < 0.07) end
end))

-- auras: cosmetic glow / particles on characters. created on your client only, and the glow
-- uses Occluded depth so it only shows where the character is actually visible (not through walls)
local function auraCfg(col)
	return {on = false, color = col, fill = 35, outline = true, pulse = true, particles = false, rainbow = false,
		halo = false, haloSize = 1, haloHeight = 0.7, haloSpin = true}
end
local HALO_SEGMENTS = 20
local AURA = {others = auraCfg(Color3.fromRGB(217, 54, 162)), self = auraCfg(Color3.fromRGB(168, 85, 247))}
local auras = {}
local function removeAura(plr)
	local a = auras[plr]
	if a then
		if a.hl then a.hl:Destroy() end
		if a.att then a.att:Destroy() end
		if a.halo then a.halo:Destroy() end
		auras[plr] = nil
	end
end
local function makeAura(plr, c)
	removeAura(plr)
	local hrp = c:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	local hl = new("Highlight", {Name = "VoidwareAura", DepthMode = Enum.HighlightDepthMode.Occluded, Adornee = c}, c)
	local att = new("Attachment", {Name = "VoidwareAuraAtt"}, hrp)
	local em = new("ParticleEmitter", {Texture = "rbxasset://textures/particles/sparkles_main.dds", Rate = 16, Lifetime = NumberRange.new(0.8, 1.4),
		Speed = NumberRange.new(0.5, 2), SpreadAngle = Vector2.new(180, 180), LightEmission = 1, Enabled = false,
		Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0)}),
		Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1)})}, att)
	-- halo: a glowing ring of small neon pieces floating above the head (local only)
	local halo = new("Folder", {Name = "VoidwareHalo"}, workspace)
	local segs = {}
	for i = 1, HALO_SEGMENTS do
		segs[i] = new("Part", {Name = "Seg", Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false,
			Material = Enum.Material.Neon, Size = Vector3.new(0.14, 0.14, 0.4), Transparency = 1}, halo)
	end
	local glowPart = new("Part", {Name = "Glow", Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false,
		Transparency = 1, Size = Vector3.new(0.2, 0.2, 0.2)}, halo)
	local light = new("PointLight", {Range = 6, Brightness = 1.5, Enabled = false}, glowPart)
	auras[plr] = {hl = hl, att = att, em = em, char = c, halo = halo, segs = segs, glowPart = glowPart, light = light}
end
local function updateAuras()
	local t = os.clock()
	for _, plr in ipairs(Players:GetPlayers()) do
		local cfg = plr == LP and AURA.self or AURA.others
		local c = plr.Character
		if cfg.on and c and c.Parent then
			local a = auras[plr]
			if not a or a.char ~= c or not a.hl.Parent then makeAura(plr, c) a = auras[plr] end
			if a then
				local col = cfg.rainbow and Color3.fromHSV((t * 0.15 + (plr.UserId % 97) / 97) % 1, 0.75, 1) or cfg.color
				local k = cfg.pulse and (0.55 + 0.45 * (math.sin(t * 2.4) + 1) / 2) or 1
				a.hl.FillColor, a.hl.OutlineColor = col, col
				a.hl.FillTransparency = 1 - (cfg.fill / 100) * k
				a.hl.OutlineTransparency = cfg.outline and 0.1 or 1
				a.em.Enabled = cfg.particles
				a.em.Color = ColorSequence.new(col)
				local head = c:FindFirstChild("Head")
				if cfg.halo and head then
					local R = 0.9 * cfg.haloSize
					local center = head.Position + Vector3.new(0, head.Size.Y / 2 + cfg.haloHeight + math.sin(t * 2) * 0.08, 0)
					local spin = cfg.haloSpin and t * 1.2 or 0
					local segLen = 2 * math.pi * R / HALO_SEGMENTS * 1.15
					for i, seg in ipairs(a.segs) do
						local ang = i / HALO_SEGMENTS * math.pi * 2 + spin
						local pos = center + Vector3.new(math.cos(ang) * R, 0, math.sin(ang) * R)
						local tangent = Vector3.new(-math.sin(ang), 0, math.cos(ang))
						seg.Size = Vector3.new(0.14 * cfg.haloSize, 0.14 * cfg.haloSize, segLen)
						seg.CFrame = CFrame.lookAt(pos, pos + tangent)
						seg.Color = col
						seg.Transparency = 0.15 + (1 - k) * 0.4
					end
					a.glowPart.CFrame = CFrame.new(center)
					a.light.Color, a.light.Enabled = col, true
				elseif a.segs[1].Transparency < 1 then
					for _, seg in ipairs(a.segs) do seg.Transparency = 1 end
					a.light.Enabled = false
				end
			end
		elseif auras[plr] then
			removeAura(plr)
		end
	end
end
bind(Players.PlayerRemoving:Connect(removeAura))
bind(RunService.RenderStepped:Connect(updateAuras))

-- anti fling: protects YOU from being flung. other players' parts stop colliding with you (on your
-- screen only), and if your character suddenly gets launched or spun it's calmed and pulled back
local AF = {on = false, noCollide = true, guard = true, returnSafe = true, maxVel = 250, maxSpin = 40, flings = 0}
local lastSafe, afStatus = nil, nil
local touched = {}
bind(RunService.Stepped:Connect(function()
	if not (AF.on and AF.noCollide) then return end
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LP and p.Character then
			for _, part in ipairs(p.Character:GetDescendants()) do
				if part:IsA("BasePart") and part.CanCollide then
					part.CanCollide = false
					touched[part] = true
				end
			end
		end
	end
end))
local function restoreCollide()
	for part in pairs(touched) do if part.Parent then pcall(function() part.CanCollide = true end) end end
	table.clear(touched)
end
bind(RunService.Heartbeat:Connect(function()
	if not (AF.on and AF.guard) then return end
	local r = root()
	if not r then return end
	local limit = AF.maxVel
	if S.fly then limit = math.max(limit, S.flySpeed * 1.5) end
	local v, w = r.AssemblyLinearVelocity, r.AssemblyAngularVelocity
	if v.Magnitude > limit or w.Magnitude > AF.maxSpin then
		r.AssemblyLinearVelocity = Vector3.zero
		r.AssemblyAngularVelocity = Vector3.zero
		if AF.returnSafe and lastSafe and (r.Position - lastSafe.Position).Magnitude > 4 then r.CFrame = lastSafe end
		AF.flings += 1
		if afStatus then afStatus.Text = "flings blocked: " .. AF.flings end
	elseif v.Magnitude < limit * 0.4 then
		lastSafe = r.CFrame
	end
end))

-- effects page: camera, post-processing, your own trail, ambient weather. all local to your screen.
local FX = {
	fovOn = false, fov = 70, timeOn = false, time = 14, stretch = 1,
	bloom = false, bloomI = 1, bloomS = 24, bloomT = 1,
	rays = false, raysI = 0.15, raysS = 0.2,
	dof = false, dofFocus = 30, dofRadius = 20, dofBlur = 50,
	weather = false, wType = 1, wDensity = 60,
}
local fov0 = Camera.FieldOfView
-- camera stretch ("stretched res" look): squashes the view vertically right after the camera updates,
-- which makes everything look wider. 1 = normal, 10 = super stretched
RunService:BindToRenderStep("VoidwareStretch", Enum.RenderPriority.Camera.Value + 1, function()
	if FX.stretch > 1 then
		local y = 1 / (1 + (FX.stretch - 1) * 0.4)
		Camera.CFrame = Camera.CFrame * CFrame.new(0, 0, 0, 1, 0, 0, 0, y, 0, 0, 0, 1)
	end
end)
local bloomFx = new("BloomEffect", {Name = "VoidwareBloom", Enabled = false}, Lighting)
local raysFx = new("SunRaysEffect", {Name = "VoidwareRays", Enabled = false}, Lighting)
local dofFx = new("DepthOfFieldEffect", {Name = "VoidwareDOF", Enabled = false, NearIntensity = 0}, Lighting)

-- weather
local WEATHER = {
	{name = "snow", up = false, color = Color3.fromRGB(255, 255, 255), size = 0.25, speed = NumberRange.new(5, 9), accel = Vector3.new(0, -1, 0),
		life = NumberRange.new(7, 9), spread = 25, light = 0.2, height = 30},
	{name = "fireflies", up = false, color = Color3.fromRGB(220, 255, 120), size = 0.22, speed = NumberRange.new(0.5, 1.5), accel = Vector3.zero,
		life = NumberRange.new(3, 5), spread = 180, light = 1, height = 2},
	{name = "embers", up = true, color = Color3.fromRGB(255, 130, 40), size = 0.18, speed = NumberRange.new(2, 5), accel = Vector3.new(0, 2, 0),
		life = NumberRange.new(3, 5), spread = 35, light = 1, height = -12},
	{name = "stardust", up = false, color = Color3.fromRGB(190, 140, 255), size = 0.2, speed = NumberRange.new(0.3, 1), accel = Vector3.new(0, -0.3, 0),
		life = NumberRange.new(4, 7), spread = 180, light = 1, height = 6},
}
local wPart, wEm
local function removeWeather() if wPart then wPart:Destroy() end wPart, wEm = nil, nil end
local function buildWeather()
	removeWeather()
	local w = WEATHER[FX.wType]
	wPart = new("Part", {Name = "VoidwareWeather", Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false,
		Transparency = 1, Size = Vector3.new(90, 1, 90)}, workspace)
	if w.spread >= 180 then wPart.Size = Vector3.new(70, 24, 70) end
	wEm = new("ParticleEmitter", {Texture = "rbxasset://textures/particles/sparkles_main.dds",
		EmissionDirection = w.up and Enum.NormalId.Top or Enum.NormalId.Bottom, ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
		Color = ColorSequence.new(w.color), LightEmission = w.light, Speed = w.speed, Acceleration = w.accel, Lifetime = w.life,
		SpreadAngle = Vector2.new(w.spread, w.spread), RotSpeed = NumberRange.new(-60, 60), Rotation = NumberRange.new(0, 360),
		Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.15, w.size), NumberSequenceKeypoint.new(0.85, w.size), NumberSequenceKeypoint.new(1, 0)}),
		Rate = FX.wDensity * 2}, wPart)
end

bind(RunService.RenderStepped:Connect(function()
	local t = os.clock()
	if FX.fovOn then Camera.FieldOfView = FX.fov end
	if FX.timeOn and not S.fullbright then Lighting.ClockTime = FX.time end
	bloomFx.Enabled = FX.bloom
	if FX.bloom then bloomFx.Intensity, bloomFx.Size, bloomFx.Threshold = FX.bloomI, FX.bloomS, FX.bloomT end
	raysFx.Enabled = FX.rays
	if FX.rays then raysFx.Intensity, raysFx.Spread = FX.raysI, FX.raysS end
	dofFx.Enabled = FX.dof
	if FX.dof then dofFx.FocusDistance, dofFx.InFocusRadius, dofFx.FarIntensity = FX.dofFocus, FX.dofRadius, FX.dofBlur / 100 end
	for _, fx in ipairs({bloomFx, raysFx, dofFx}) do if fx.Parent ~= Lighting then fx.Parent = Lighting end end

	if FX.weather then
		if not (wPart and wPart.Parent) then buildWeather() end
		if wPart then
			wPart.CFrame = CFrame.new(Camera.CFrame.Position + Vector3.new(0, WEATHER[FX.wType].height, 0))
			wEm.Rate = FX.wDensity * 2
		end
	end
end))

---------------------------------------------------------------- loops
-- gamepad mode: movement eases in from a slower start speed up to full speed while you hold a direction
local GP = {on = false, start = 35, ramp = 0.6, fly = true, held = 0, useCurve = false, curve = 4}
-- speed-up curves: input 0..1 (how far into the ramp), output 0..1 (how much of the extra speed you have)
GP.CURVES = {
	{"linear", function(a) return a end},
	{"ease in", function(a) return a * a end},
	{"ease out", function(a) return 1 - (1 - a) ^ 2 end},
	{"smooth", function(a) return a * a * (3 - 2 * a) end},
	{"exponential", function(a) return a <= 0 and 0 or (2 ^ (10 * a) - 1) / 1023 end},
	{"snappy", function(a) return 1 - (1 - a) ^ 4 end},
}
local MOVE_KEYS = {Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D, Enum.KeyCode.Space, Enum.KeyCode.LeftControl}
local function rampFactor(dt)
	local moving = false
	local h0 = hum()
	if h0 and h0.MoveDirection.Magnitude > 0.05 then moving = true end
	if not moving and S.fly then
		for _, k in ipairs(MOVE_KEYS) do if UIS:IsKeyDown(k) then moving = true break end end
	end
	GP.held = moving and GP.held + dt or 0
	if not GP.on then return 1 end
	local a = math.clamp(GP.held / GP.ramp, 0, 1)
	a = GP.CURVES[GP.useCurve and GP.curve or 4][2](a) -- "smooth" unless a curve is picked
	local s = GP.start / 100
	return s + (1 - s) * a
end

bind(RunService.RenderStepped:Connect(function(dt)
	local ramp = rampFactor(dt)
	if S.fly and flyLV then
		local cf, dir = Camera.CFrame, Vector3.zero
		if UIS:IsKeyDown(Enum.KeyCode.W) then dir += cf.LookVector end
		if UIS:IsKeyDown(Enum.KeyCode.S) then dir -= cf.LookVector end
		if UIS:IsKeyDown(Enum.KeyCode.D) then dir += cf.RightVector end
		if UIS:IsKeyDown(Enum.KeyCode.A) then dir -= cf.RightVector end
		if UIS:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.yAxis end
		if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.yAxis end
		flyLV.VectorVelocity = dir.Magnitude > 0 and dir.Unit * S.flySpeed * (GP.fly and ramp or 1) or Vector3.zero
		local lv = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)
		if lv.Magnitude > 0.01 then flyAO.CFrame = CFrame.lookAt(Vector3.zero, lv) end
	end
	local h = hum()
	if h and (S.lock or GP.on) then
		local want = S.walk * ramp
		if math.abs(h.WalkSpeed - want) > 0.01 then h.WalkSpeed = want end
	end
	if h and S.lock and S.jump ~= 50 then
		-- skip forcing when jump is default (50) to avoid overriding game-set jump values (e.g. rivals)
		if h.UseJumpPower then if h.JumpPower ~= S.jump then h.JumpPower = S.jump end
		else local jh = S.jump * S.jump / (2 * workspace.Gravity) if math.abs(h.JumpHeight - jh) > 0.01 then h.JumpHeight = jh end end
	end
	if S.fullbright then
		Lighting.Brightness = S.brightness Lighting.ClockTime = 14 Lighting.GlobalShadows = false
		Lighting.Ambient = Color3.fromRGB(178, 178, 178) Lighting.OutdoorAmbient = Color3.fromRGB(178, 178, 178)
	end
	if S.noFog then
		Lighting.FogStart = 1e8 Lighting.FogEnd = 1e9
		for a in pairs(atmos) do if a.Parent then a.Density = 0 a.Haze = 0 end end
	elseif S.customFog then
		Lighting.FogStart = math.min(S.fogStart, S.fogEnd - 1) Lighting.FogEnd = S.fogEnd Lighting.FogColor = S.fogColor
		for a in pairs(atmos) do if a.Parent then a.Density = 0 a.Haze = 0 end end
	end
	if tintFx.Parent ~= Lighting then tintFx.Parent = Lighting end
	tintFx.Enabled = S.worldTint
	if S.worldTint then
		tintFx.TintColor = Color3.new(1, 1, 1):Lerp(S.tintColor, S.tintStrength / 100)
		tintFx.Saturation = S.saturation / 100
		tintFx.Contrast = S.contrast / 100
	end
end))
bind(Lighting.ChildAdded:Connect(function(a) if a:IsA("Atmosphere") then atmos[a] = {Density = a.Density, Haze = a.Haze} end end))
bind(RunService.Stepped:Connect(function()
	if S.noclip and char() then
		for _, p in ipairs(char():GetDescendants()) do if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end end
	end
end))
bind(UIS.JumpRequest:Connect(function() if S.infJump then local h = hum() if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end end end))
bind(LP.CharacterAdded:Connect(function()
	task.wait(0.3)
	if S.fly then startFly() end
	if DS.on then buildGhost() end
end))

---------------------------------------------------------------- player ESP
-- Drawing-based ESP: 2D bounding box, skeleton, name/distance/HP tags.
-- Optional Highlight (character fill) sits on top.
local function buildESPPage(cols)
	-- ── config ────────────────────────────────────────────────────────────
	local state = {
		enabled     = false,
		names       = true,
		distance    = true,
		health      = true,
		box         = true,
		skeleton    = true,
		chams       = true,    -- Highlight fill
		hideTeam    = false,
		color       = Color3.fromRGB(168, 85, 247),
		colorEnemy  = Color3.fromRGB(255, 65, 90),
		transparency= 0.45,
		boxThick    = 1.5,
		skelThick   = 1.0,
		teamColor   = false,   -- use team color instead of fixed color
	}

	-- ── skeleton joint pairs (part names) ────────────────────────────────
	-- Rivals uses standard R6 names; fall back gracefully if missing
	local SKEL_PAIRS = {
		{"Head",        "UpperTorso"  },
		{"Head",        "Torso"       },  -- R6
		{"UpperTorso",  "LowerTorso"  },
		{"Torso",       "HumanoidRootPart"}, -- R6 fallback
		{"UpperTorso",  "RightUpperArm"},
		{"RightUpperArm","RightLowerArm"},
		{"RightLowerArm","RightHand"  },
		{"UpperTorso",  "LeftUpperArm"},
		{"LeftUpperArm","LeftLowerArm"},
		{"LeftLowerArm","LeftHand"    },
		{"LowerTorso",  "RightUpperLeg"},
		{"RightUpperLeg","RightLowerLeg"},
		{"RightLowerLeg","RightFoot"  },
		{"LowerTorso",  "LeftUpperLeg"},
		{"LeftUpperLeg","LeftLowerLeg"},
		{"LeftLowerLeg","LeftFoot"    },
	}

	-- ── per-player drawing objects ────────────────────────────────────────
	local tracked = {}   -- [plr] = { highlight, box={}, skel={}, label, distLabel, hpLabel, hpBarBg, hpBar }

	local function mkLine(thick, col)
		local l = Drawing.new("Line")
		l.Visible   = false
		l.Thickness = thick or 1
		l.Color     = col or Color3.new(1,1,1)
		l.Transparency = 1
		l.ZIndex    = 2
		return l
	end
	local function mkText(size, col)
		local t = Drawing.new("Text")
		t.Visible  = false
		t.Size     = size or 13
		t.Color    = col or Color3.new(1,1,1)
		t.Outline  = true
		t.OutlineColor = Color3.new(0,0,0)
		t.Center   = true
		t.Font     = 3
		t.Transparency = 1
		t.ZIndex   = 3
		return t
	end
	local function mkQuad(thick, col)
		-- 4 lines: top, bottom, left, right
		return {
			mkLine(thick, col), mkLine(thick, col),
			mkLine(thick, col), mkLine(thick, col),
		}
	end

	local function destroyDrawings(d)
		if not d then return end
		if d.highlight then pcall(function() d.highlight:Destroy() end) d.highlight = nil end
		if d.box then for _, l in ipairs(d.box) do pcall(function() l:Remove() end) end d.box = nil end
		if d.skel then for _, l in ipairs(d.skel) do pcall(function() l:Remove() end) end d.skel = nil end
		if d.label    then pcall(function() d.label:Remove()    end) d.label    = nil end
		if d.distLabel then pcall(function() d.distLabel:Remove() end) d.distLabel= nil end
		if d.hpLabel  then pcall(function() d.hpLabel:Remove()  end) d.hpLabel  = nil end
		if d.hpBarBg  then pcall(function() d.hpBarBg:Remove()  end) d.hpBarBg  = nil end
		if d.hpBar    then pcall(function() d.hpBar:Remove()    end) d.hpBar    = nil end
	end

	local function hideAll(d)
		if not d then return end
		if d.highlight then pcall(function() d.highlight.Enabled = false end) end
		if d.box then for _, l in ipairs(d.box) do pcall(function() l.Visible = false end) end end
		if d.skel then for _, l in ipairs(d.skel) do pcall(function() l.Visible = false end) end end
		if d.label    then d.label.Visible    = false end
		if d.distLabel then d.distLabel.Visible = false end
		if d.hpLabel  then d.hpLabel.Visible  = false end
		if d.hpBarBg  then d.hpBarBg.Visible  = false end
		if d.hpBar    then d.hpBar.Visible     = false end
	end

	local function makeDrawings(col)
		return {
			box      = mkQuad(state.boxThick,  col),
			skel     = (function()
				local t = {}
				for i = 1, #SKEL_PAIRS do t[i] = mkLine(state.skelThick, col) end
				return t
			end)(),
			label    = mkText(13, col),
			distLabel= mkText(11, Color3.fromRGB(200,200,200)),
			hpLabel  = mkText(11, Color3.fromRGB(80,255,100)),
			hpBarBg  = (function()
				local r = Drawing.new("Square")
				r.Visible = false; r.Filled = true
				r.Color = Color3.new(0,0,0); r.Transparency = 0.5
				r.ZIndex = 1; return r
			end)(),
			hpBar    = (function()
				local r = Drawing.new("Square")
				r.Visible = false; r.Filled = true
				r.Color = Color3.fromRGB(80,255,100); r.Transparency = 1
				r.ZIndex = 2; return r
			end)(),
			highlight = nil,
		}
	end

	local function attachHighlight(plr, d)
		local ch = plr.Character
		if not ch then return end
		if d.highlight then pcall(function() d.highlight:Destroy() end) end
		local hl = Instance.new("Highlight")
		hl.Name              = "GravESPHL"
		hl.Adornee           = ch
		hl.DepthMode         = Enum.HighlightDepthMode.AlwaysOnTop
		hl.FillColor         = state.color
		hl.OutlineColor      = state.color:Lerp(Color3.new(1,1,1), 0.3)
		hl.FillTransparency  = state.transparency
		hl.OutlineTransparency = 0
		hl.Enabled           = false
		hl.Parent            = ch
		d.highlight          = hl
	end

	local function espColor(plr)
		if state.teamColor then
			local tc = plr.TeamColor
			if tc then return tc.Color end
		end
		return state.color
	end

	local function track(plr)
		if plr == LP or tracked[plr] then return end
		local col = espColor(plr)
		local d   = makeDrawings(col)
		tracked[plr] = d
		task.spawn(function()
			if plr.Character then attachHighlight(plr, d) end
			d.charConn = bind(plr.CharacterAdded:Connect(function()
				task.wait(0.1)
				attachHighlight(plr, d)
			end))
		end)
	end

	local function untrack(plr)
		local d = tracked[plr]
		if not d then return end
		if d.charConn then d.charConn:Disconnect() end
		destroyDrawings(d)
		tracked[plr] = nil
	end

	for _, plr in ipairs(Players:GetPlayers()) do track(plr) end
	bind(Players.PlayerAdded:Connect(track))
	bind(Players.PlayerRemoving:Connect(untrack))

	-- ── world-to-screen helper (returns nil if behind camera) ────────────
	local function w2s(pos)
		local sp, vis = Camera:WorldToViewportPoint(pos)
		if not vis or sp.Z <= 0 then return nil end
		return Vector2.new(sp.X, sp.Y)
	end

	-- ── get 2D bounding box from character BaseParts ──────────────────────
	local function charBounds(ch)
		local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
		local any = false
		for _, p in ipairs(ch:GetDescendants()) do
			if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
				-- sample 8 corners of the part's bounding box
				local cf, hs = p.CFrame, p.Size * 0.5
				for _, sx in ipairs({-1, 1}) do
					for _, sy in ipairs({-1, 1}) do
						for _, sz in ipairs({-1, 1}) do
							local corner = cf:PointToWorldSpace(Vector3.new(sx*hs.X, sy*hs.Y, sz*hs.Z))
							local s = w2s(corner)
							if s then
								minX = math.min(minX, s.X); minY = math.min(minY, s.Y)
								maxX = math.max(maxX, s.X); maxY = math.max(maxY, s.Y)
								any  = true
							end
						end
					end
				end
			end
		end
		if not any then return nil end
		return Vector2.new(minX, minY), Vector2.new(maxX, maxY)
	end

	-- ── draw a 4-line rect ────────────────────────────────────────────────
	local function drawBox(lines, tl, br, col, thick)
		local tr = Vector2.new(br.X, tl.Y)
		local bl = Vector2.new(tl.X, br.Y)
		local corners = { tl, tr, br, bl }
		-- top, right, bottom, left
		local segs = { {tl,tr}, {tr,br}, {br,bl}, {bl,tl} }
		for i, seg in ipairs(segs) do
			lines[i].From        = seg[1]
			lines[i].To          = seg[2]
			lines[i].Color       = col
			lines[i].Thickness   = thick
			lines[i].Visible     = true
		end
	end

	-- ── main render loop ──────────────────────────────────────────────────
	bind(RunService.RenderStepped:Connect(function()
		if not state.enabled then
			for _, d in pairs(tracked) do hideAll(d) end
			return
		end
		local myChar = LP.Character
		local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")

		for plr, d in pairs(tracked) do
			local ch  = plr.Character
			local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
			local hum = ch and ch:FindFirstChildOfClass("Humanoid")
			local skip = not (ch and hrp and hum)
				or hum.Health <= 0
				or (state.hideTeam and plr.Team == LP.Team)
			if skip then hideAll(d) continue end

			local col   = espColor(plr)
			local dist  = myRoot and math.floor((hrp.Position - myRoot.Position).Magnitude + 0.5) or 0
			local hp    = hum.Health
			local maxHp = hum.MaxHealth
			local hpFrac= maxHp > 0 and math.clamp(hp / maxHp, 0, 1) or 0

			-- ── highlight (chams) ────────────────────────────────────────
			if d.highlight then
				d.highlight.Enabled          = state.chams
				d.highlight.FillColor        = col
				d.highlight.OutlineColor     = col:Lerp(Color3.new(1,1,1), 0.3)
				d.highlight.FillTransparency = state.transparency
			end

			-- ── 2D bounding box ──────────────────────────────────────────
			local tl, br = charBounds(ch)
			if tl and br and state.box then
				local pad = 2
				local ptl = tl - Vector2.new(pad, pad)
				local pbr = br + Vector2.new(pad, pad)
				drawBox(d.box, ptl, pbr, col, state.boxThick)

				-- ── HP bar (left side of box) ────────────────────────────
				if state.health then
					local barW   = 3
					local barX   = ptl.X - barW - 2
					local barH   = pbr.Y - ptl.Y
					local hpH    = barH * hpFrac
					local hpCol  = Color3.fromHSV(hpFrac * 0.33, 0.9, 1)  -- red→green
					d.hpBarBg.Position = Vector2.new(barX, ptl.Y)
					d.hpBarBg.Size     = Vector2.new(barW, barH)
					d.hpBarBg.Visible  = true
					d.hpBar.Position   = Vector2.new(barX, ptl.Y + (barH - hpH))
					d.hpBar.Size       = Vector2.new(barW, hpH)
					d.hpBar.Color      = hpCol
					d.hpBar.Visible    = true
				else
					d.hpBarBg.Visible = false
					d.hpBar.Visible   = false
				end

				-- ── name + distance labels ───────────────────────────────
				local midX = (ptl.X + pbr.X) * 0.5
				if state.names then
					d.label.Text     = plr.DisplayName
					d.label.Color    = col
					d.label.Position = Vector2.new(midX, ptl.Y - 15)
					d.label.Visible  = true
				else
					d.label.Visible  = false
				end
				if state.distance then
					d.distLabel.Text     = dist .. "m"
					d.distLabel.Position = Vector2.new(midX, pbr.Y + 2)
					d.distLabel.Visible  = true
				else
					d.distLabel.Visible = false
				end
				if state.health then
					d.hpLabel.Text     = math.floor(hp + 0.5) .. " hp"
					d.hpLabel.Position = Vector2.new(pbr.X + 5, ptl.Y + (pbr.Y - ptl.Y) * 0.5 - 6)
					d.hpLabel.Visible  = true
				else
					d.hpLabel.Visible = false
				end
			else
				-- nothing on screen: hide box / labels
				if d.box then for _, l in ipairs(d.box) do l.Visible = false end end
				d.label.Visible = false; d.distLabel.Visible = false
				d.hpLabel.Visible = false; d.hpBarBg.Visible = false; d.hpBar.Visible = false
			end

			-- ── skeleton ─────────────────────────────────────────────────
			if state.skeleton then
				for i, pair in ipairs(SKEL_PAIRS) do
					local pa = ch:FindFirstChild(pair[1])
					local pb = ch:FindFirstChild(pair[2])
					local sa = pa and w2s(pa.Position)
					local sb = pb and w2s(pb.Position)
					if sa and sb and d.skel[i] then
						d.skel[i].From      = sa
						d.skel[i].To        = sb
						d.skel[i].Color     = col
						d.skel[i].Thickness = state.skelThick
						d.skel[i].Visible   = true
					elseif d.skel[i] then
						d.skel[i].Visible = false
					end
				end
			else
				if d.skel then for _, l in ipairs(d.skel) do l.Visible = false end end
			end
		end
	end))

	-- cleanup on unload
	bind({ Disconnect = function()
		for plr, _ in pairs(tracked) do untrack(plr) end
	end })

	-- ── UI ────────────────────────────────────────────────────────────────
	local main = card(cols[1], "player ESP")
	main.note("2D box · skeleton · HP bar · name · distance · chams")
	main.toggle("enabled",        false, function(v) state.enabled  = v end)
	main.toggle("box",            true,  function(v) state.box      = v end)
	main.toggle("skeleton",       true,  function(v) state.skeleton = v end)
	main.toggle("chams (highlight)", true, function(v) state.chams  = v end)
	main.toggle("names",          true,  function(v) state.names    = v end)
	main.toggle("distance",       true,  function(v) state.distance = v end)
	main.toggle("health bar",     true,  function(v) state.health   = v end)
	main.toggle("hide teammates", false, function(v) state.hideTeam = v end)
	main.toggle("team color",     false, function(v) state.teamColor= v end)

	local style = card(cols[2], "ESP style")
	style.colorwheel("color",        state.color,      function(c) state.color      = c end)
	style.slider("fill transparency", 0, 100, 45,      function(v) state.transparency = v / 100 end, "%")
	style.slider("box thickness",   0.5, 5, 1.5,       function(v) state.boxThick   = v end, " px", 0.5)
	style.slider("skeleton thick",  0.5, 4, 1.0,       function(v) state.skelThick  = v end, " px", 0.5)
	style.note("Drawing.new ESP — renders through walls, no camera dependency")
end

-- self fx: skin, footsteps, shockwaves, screen overlays, speed blur. all local to your screen.
local XFX = {
	skin = false, mat = 1, skinColor = Color3.fromRGB(168, 85, 247), skinRainbow = true,
	vignette = false, vigStrength = 55, vigColor = Color3.fromRGB(40, 10, 70),
	bars = false, barSize = 10,
	speedBlur = false, blurMax = 10,
	toggles = {},
}
;(function() -- runs once in its own scope (keeps the top-level slot count low)
	XFX.MATS = {{"forcefield", Enum.Material.ForceField}, {"neon", Enum.Material.Neon}, {"glass", Enum.Material.Glass}, {"foil", Enum.Material.Foil}}
	local orig, origChar = {}, nil
	local function restoreSkin()
		for part, o in pairs(orig) do if part.Parent then pcall(function() part.Material, part.Color = o[1], o[2] end) end end
		table.clear(orig)
	end
	XFX.restoreSkin = restoreSkin

	-- a glowing flat disc on the ground that grows and fades (used for footsteps and shockwaves)
	local function disc(pos, startD, endD, life, col, startT)
		local p = Instance.new("Part")
		p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
		p.Material, p.Shape, p.Color, p.Transparency = Enum.Material.Neon, Enum.PartType.Cylinder, col, startT
		p.Size = Vector3.new(0.06, startD, startD)
		p.CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.pi / 2)
		p.Parent = workspace
		TweenService:Create(p, TweenInfo.new(life, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = Vector3.new(0.06, endD, endD), Transparency = 1}):Play()
		task.delay(life, function() p:Destroy() end)
	end

	-- screen overlays: soft vignette around the edges + cinematic letterbox bars (behind the panel)
	local ov = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 0}, gui)
	local edges = {}
	local function edge(size, pos, rot)
		local f = new("Frame", {Size = size, Position = pos, BorderSizePixel = 0, BackgroundColor3 = XFX.vigColor, Visible = false, ZIndex = 0}, ov)
		local g = new("UIGradient", {Rotation = rot, Transparency = NumberSequence.new(1, 1)}, f)
		table.insert(edges, {f = f, g = g})
	end
	edge(UDim2.new(1, 0, 0.35, 0), UDim2.fromScale(0, 0), 90)
	edge(UDim2.new(1, 0, 0.35, 0), UDim2.fromScale(0, 0.65), -90)
	edge(UDim2.new(0.3, 0, 1, 0), UDim2.fromScale(0, 0), 0)
	edge(UDim2.new(0.3, 0, 1, 0), UDim2.fromScale(0.7, 0), 180)
	local barT = new("Frame", {Size = UDim2.new(1, 0, 0, 0), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, ZIndex = 0}, ov)
	local barB = new("Frame", {AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 0),
		BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, ZIndex = 0}, ov)
	local blur = new("BlurEffect", {Name = "VoidwareSpeedBlur", Size = 0, Enabled = false}, Lighting)

	XFX.disc = disc
	XFX.cleanup = function() restoreSkin() ov:Destroy() blur:Destroy() end

	local curBlur, curBar = 0, 0
	bind(RunService.RenderStepped:Connect(function(dt)
		local t = os.clock()
		local c, r, h = char(), root(), hum()
		local skinCol = XFX.skinRainbow and Color3.fromHSV((t * 0.2) % 1, 0.7, 1) or XFX.skinColor

		-- self skin
		if XFX.skin and c then
			if origChar ~= c then table.clear(orig) origChar = c end
			local mat = XFX.MATS[XFX.mat][2]
			for _, part in ipairs(c:GetDescendants()) do
				if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
					if not orig[part] then orig[part] = {part.Material, part.Color} end
					part.Material, part.Color = mat, skinCol
				end
			end
		elseif next(orig) then
			restoreSkin()
		end

		-- speed blur
		if r and h then
			local target = XFX.speedBlur and math.clamp((r.AssemblyLinearVelocity.Magnitude - 30) / 120, 0, 1) * XFX.blurMax or 0
			curBlur += (target - curBlur) * math.min(1, dt * 8)
			blur.Enabled = curBlur > 0.2
			blur.Size = curBlur
		end

		-- overlays
		local a = 1 - XFX.vigStrength / 100 * 0.9
		for _, e in ipairs(edges) do
			e.f.Visible = XFX.vignette
			if XFX.vignette then e.f.BackgroundColor3 = XFX.vigColor e.g.Transparency = NumberSequence.new(a, 1) end
		end
		curBar += ((XFX.bars and XFX.barSize / 100 or 0) - curBar) * math.min(1, dt * 6)
		barT.Size, barB.Size = UDim2.new(1, 0, curBar, 0), UDim2.new(1, 0, curBar, 0)
	end))
end)()


;(function() -- crosshair: a spinning, fully adjustable crosshair in the middle of the screen
	XFX.cross = {
		on = false, arms = 4, length = 10, thick = 2, gap = 6, spin = 90, opacity = 90,
		dot = true, outline = true, rainbow = false, dynamic = true, color = Color3.fromRGB(168, 85, 247),
		text = "", textSize = 14, textDist = 10, textSpin = false,
	}
	local C = XFX.cross
	local holder = new("Frame", {Size = UDim2.fromOffset(1, 1), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		BackgroundTransparency = 1, Visible = false, ZIndex = 1}, gui)
	local arms, kick = {}, 0
	local dot = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BorderSizePixel = 0, ZIndex = 2}, holder)
	new("UICorner", {CornerRadius = UDim.new(0.5, 0)}, dot)
	local dotStroke = new("UIStroke", {Color = Color3.new(0, 0, 0), Thickness = 1}, dot)
	-- custom text under the crosshair
	local label = new("TextLabel", {AnchorPoint = Vector2.new(0.5, 0), AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.fromOffset(0, 0),
		BackgroundTransparency = 1, FontFace = F.title, Text = "", TextSize = 14, TextStrokeColor3 = Color3.new(0, 0, 0), Visible = false, ZIndex = 2}, gui)
	local function syncArms()
		while #arms < C.arms do
			local a = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0, ZIndex = 2}, holder)
			new("UICorner", {CornerRadius = UDim.new(0, 1)}, a)
			table.insert(arms, {f = a, st = new("UIStroke", {Color = Color3.new(0, 0, 0), Thickness = 1}, a)})
		end
		while #arms > C.arms do table.remove(arms).f:Destroy() end
	end
	-- dynamic: the gap kicks open when you click, then eases back
	bind(UIS.InputBegan:Connect(function(i, gp)
		if not gp and C.on and C.dynamic and i.UserInputType == Enum.UserInputType.MouseButton1 then kick = 1 end
	end))
	bind(RunService.RenderStepped:Connect(function(dt)
		holder.Visible = C.on
		label.Visible = C.on and C.text ~= ""
		if not C.on then return end
		if #arms ~= C.arms then syncArms() end
		local t = os.clock()
		kick = math.max(0, kick - dt * 4)
		local col = C.rainbow and Color3.fromHSV((t * 0.2) % 1, 0.75, 1) or C.color
		local tr = 1 - C.opacity / 100
		local gap = C.gap + kick * 8
		holder.Rotation = (t * C.spin) % 360
		for i, arm in ipairs(arms) do
			local ang = (i - 1) / C.arms * 360
			local r = math.rad(ang)
			local dist = gap + C.length / 2
			arm.f.Size = UDim2.fromOffset(C.thick, C.length)
			arm.f.Position = UDim2.new(0.5, math.sin(r) * dist, 0.5, -math.cos(r) * dist)
			arm.f.Rotation = ang
			arm.f.BackgroundColor3 = col
			arm.f.BackgroundTransparency = tr
			arm.st.Transparency = C.outline and math.min(1, tr + 0.35) or 1
		end
		dot.Visible = C.dot
		local ds = C.thick + 1
		dot.Size = UDim2.fromOffset(ds, ds)
		dot.BackgroundColor3 = col
		dot.BackgroundTransparency = tr
		dotStroke.Transparency = C.outline and math.min(1, tr + 0.35) or 1

		-- text: sits under the crosshair, or orbits with it when "text spins" is on
		if label.Visible then
			label.Text = C.text
			label.TextSize = C.textSize
			label.TextColor3 = col
			label.TextTransparency = tr
			label.TextStrokeTransparency = C.outline and math.min(1, tr + 0.3) or 1
			local dist = gap + C.length + C.textDist
			if C.textSpin then
				local r = math.rad(holder.Rotation)
				label.AnchorPoint = Vector2.new(0.5, 0.5)
				local d2 = dist + C.textSize / 2
				label.Position = UDim2.new(0.5, -math.sin(r) * d2, 0.5, math.cos(r) * d2)
				label.Rotation = holder.Rotation
			else
				label.AnchorPoint = Vector2.new(0.5, 0)
				label.Position = UDim2.new(0.5, 0, 0.5, dist)
				label.Rotation = 0
			end
		end
	end))
end)()

;(function() -- skyboxes: swap the sky for built-in looks (your screen only); the game's own sky is restored when you pick "original"
	local SKY = {preset = 1, stars = 3000, bodies = true}
	XFX.sky = SKY
	local CLASSIC = "rbxasset://textures/sky/sky512_"
	local function classicFaces()
		return {Bk = CLASSIC .. "bk.tex", Dn = CLASSIC .. "dn.tex", Ft = CLASSIC .. "ft.tex", Lf = CLASSIC .. "lf.tex", Rt = CLASSIC .. "rt.tex", Up = CLASSIC .. "up.tex"}
	end
	SKY.PRESETS = {
		{name = "original"},
		{name = "classic roblox", faces = classicFaces()},
		{name = "gray", faces = classicFaces(), bodies = false, stars = 0,
			atmo = {Density = 0.55, Offset = 0.25, Color = Color3.fromRGB(165, 167, 172), Decay = Color3.fromRGB(130, 132, 138), Glare = 0, Haze = 3}},
		{name = "night", faces = classicFaces(), time = 0, stars = 5000,
			atmo = {Density = 0.2, Offset = 0, Color = Color3.fromRGB(40, 50, 90), Decay = Color3.fromRGB(20, 25, 50), Glare = 0, Haze = 0.5}},
		{name = "sunset", faces = classicFaces(), time = 17.8,
			atmo = {Density = 0.35, Offset = 0.1, Color = Color3.fromRGB(255, 170, 120), Decay = Color3.fromRGB(255, 110, 70), Glare = 1.2, Haze = 1.6}},
		{name = "deep space", faces = classicFaces(), time = 0, stars = 10000, bodies = false,
			atmo = {Density = 0, Offset = 0, Color = Color3.new(0, 0, 0), Decay = Color3.new(0, 0, 0), Glare = 0, Haze = 0}},
	}
	local stash = {} -- the game's own Sky / Atmosphere objects while ours is active
	local mySky, myAtmo, loaded = nil, nil, nil
	local function clearMine()
		if mySky then mySky:Destroy() mySky = nil end
		if myAtmo then myAtmo:Destroy() myAtmo = nil end
	end
	local function stashOriginal(kinds)
		for _, ch in ipairs(Lighting:GetChildren()) do
			for _, k in ipairs(kinds) do
				if ch:IsA(k) and ch ~= mySky and ch ~= myAtmo and ch ~= loaded then
					table.insert(stash, ch)
					ch.Parent = nil
				end
			end
		end
	end
	function SKY.restore()
		clearMine()
		if loaded then loaded:Destroy() loaded = nil end
		for _, ch in ipairs(stash) do pcall(function() ch.Parent = Lighting end) end
		table.clear(stash)
	end
	local function useSky(skyObj)
		stashOriginal({"Sky"})
		if mySky and mySky ~= skyObj then mySky:Destroy() end
		mySky = skyObj
		mySky.Parent = Lighting
	end
	function SKY.apply(i)
		local p = SKY.PRESETS[i]
		if not p then return end
		SKY.restore()
		SKY.preset = i
		if not p.faces then return end -- "original"
		local sky = Instance.new("Sky")
		sky.Name = "VoidwareSky"
		sky.SkyboxBk, sky.SkyboxDn, sky.SkyboxFt = p.faces.Bk, p.faces.Dn, p.faces.Ft
		sky.SkyboxLf, sky.SkyboxRt, sky.SkyboxUp = p.faces.Lf, p.faces.Rt, p.faces.Up
		if p.stars then SKY.stars = p.stars end
		if p.bodies ~= nil then SKY.bodies = p.bodies end
		useSky(sky)
		if p.atmo then
			stashOriginal({"Atmosphere"})
			myAtmo = Instance.new("Atmosphere")
			myAtmo.Name = "VoidwareSkyAtmosphere"
			for k, v in pairs(p.atmo) do myAtmo[k] = v end
			myAtmo.Parent = Lighting
		end
	end
	-- load any Sky from the catalog by asset id (needs an executor with game:GetObjects)
	function SKY.loadAsset(id)
		local ok, objs = pcall(function() return game:GetObjects("rbxassetid://" .. id) end)
		if not ok or type(objs) ~= "table" then return false end
		local found
		for _, o in ipairs(objs) do
			if o:IsA("Sky") then found = o break end
			local d = o:FindFirstChildWhichIsA("Sky", true)
			if d then found = d break end
		end
		if not found then return false end
		SKY.restore()
		SKY.preset = 0
		loaded = found
		stashOriginal({"Sky"})
		found.Parent = Lighting
		return true
	end
	bind(RunService.RenderStepped:Connect(function()
		local p = SKY.PRESETS[SKY.preset]
		local sky = mySky or loaded
		if sky then
			sky.StarCount = SKY.stars
			sky.CelestialBodiesShown = SKY.bodies
		end
		-- presets with a time of day hold it, unless fullbright or your own time lock is on
		if p and p.time and not S.fullbright and not FX.timeOn then Lighting.ClockTime = p.time end
	end))
end)()

-- seasonal emblems next to the logo (the black hole is "void"); only the active one is shown and animated
;(function() -- runs once in its own scope (keeps the top-level slot count low)
	local SZ = 30
	local function emblem(name)
		return new("Frame", {Name = "Emblem_" .. name, Size = UDim2.fromOffset(SZ, SZ), AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(0, -8, 0.5, 0), BackgroundTransparency = 1, Visible = false}, logo)
	end
	local function blob(parent, w, h, cx, cy, col, tr, z, rot)
		local f = new("Frame", {Size = UDim2.fromOffset(w, h), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(cx, cy),
			BackgroundColor3 = col, BackgroundTransparency = tr or 0, BorderSizePixel = 0, ZIndex = z or 2, Rotation = rot or 0}, parent)
		new("UICorner", {CornerRadius = UDim.new(0.5, 0)}, f)
		return f
	end
	local function bar(parent, w, h, cx, cy, rot, col, z)
		local f = new("Frame", {Size = UDim2.fromOffset(w, h), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(cx, cy),
			Rotation = rot, BackgroundColor3 = col, BorderSizePixel = 0, ZIndex = z or 2}, parent)
		new("UICorner", {CornerRadius = UDim.new(0, 1)}, f)
		return f
	end
	local anim = {}

	-- halloween: glowing jack-o'-lantern with flickering candle-lit face
	do
		local e = emblem("pumpkin")
		local g1 = blob(e, 34, 34, 15, 16, Color3.fromRGB(255, 120, 20), 0.88, 1)
		local g2 = blob(e, 26, 26, 15, 16, Color3.fromRGB(255, 150, 40), 0.8, 1)
		bar(e, 3, 7, 15.5, 6, 12, Color3.fromRGB(95, 140, 50), 2)
		blob(e, 13, 17, 9.5, 17, Color3.fromRGB(225, 100, 15), 0, 3)
		blob(e, 13, 17, 20.5, 17, Color3.fromRGB(225, 100, 15), 0, 3)
		blob(e, 14, 18, 15, 17, Color3.fromRGB(255, 140, 30), 0, 4)
		local face = {
			bar(e, 4, 4, 11.5, 15, 45, Color3.fromRGB(255, 225, 90), 5),
			bar(e, 4, 4, 18.5, 15, 45, Color3.fromRGB(255, 225, 90), 5),
			blob(e, 10, 3.5, 15, 21, Color3.fromRGB(255, 225, 90), 0, 5),
		}
		anim.pumpkin = function(t)
			local flick = 0.75 + math.noise(t * 6, 0.3) * 0.5 + math.random() * 0.08
			for _, f in ipairs(face) do f.BackgroundTransparency = math.clamp(1 - flick, 0, 0.6) end
			g1.BackgroundTransparency = 0.9 - flick * 0.06
			g2.BackgroundTransparency = 0.84 - flick * 0.1
		end
	end

	-- winter: a crisp snowflake that slowly turns and shimmers
	do
		local e = emblem("snowflake")
		local ICE = Color3.fromRGB(225, 242, 255)
		local glow = blob(e, 32, 32, 15, 15, Color3.fromRGB(140, 200, 255), 0.86, 1)
		local arms = new("Frame", {Size = UDim2.fromOffset(SZ, SZ), BackgroundTransparency = 1}, e)
		for k = 0, 2 do bar(arms, 2, 26, 15, 15, k * 60, ICE, 3) end
		for k = 0, 5 do
			local a = math.rad(k * 60)
			local dx, dy = math.sin(a), -math.cos(a)
			for _, dist in ipairs({7, 10.5}) do
				local px, py = 15 + dx * dist, 15 + dy * dist
				local len = dist == 7 and 6 or 4
				bar(arms, 1.6, len, px, py, k * 60 + 45, ICE, 3)
				bar(arms, 1.6, len, px, py, k * 60 - 45, ICE, 3)
			end
		end
		blob(arms, 5, 5, 15, 15, Color3.new(1, 1, 1), 0, 4)
		anim.snowflake = function(t)
			arms.Rotation = (t * 20) % 360
			glow.BackgroundTransparency = 0.88 - (math.sin(t * 2) + 1) / 2 * 0.08
		end
	end

	-- spring: a soft pink flower swaying gently
	do
		local e = emblem("flower")
		local glow = blob(e, 32, 32, 15, 15, Color3.fromRGB(255, 150, 200), 0.87, 1)
		local head = new("Frame", {Size = UDim2.fromOffset(SZ, SZ), BackgroundTransparency = 1}, e)
		for k = 0, 4 do
			local a = math.rad(k * 72)
			blob(head, 9, 13, 15 + math.sin(a) * 6.5, 15 - math.cos(a) * 6.5,
				k % 2 == 0 and Color3.fromRGB(255, 150, 200) or Color3.fromRGB(255, 180, 215), 0, 3, k * 72)
		end
		blob(head, 8, 8, 15, 15, Color3.fromRGB(255, 215, 80), 0, 4)
		blob(head, 4, 4, 14, 14, Color3.fromRGB(255, 240, 160), 0, 5)
		anim.flower = function(t)
			head.Rotation = math.sin(t * 1.4) * 12
			glow.BackgroundTransparency = 0.88 - (math.sin(t * 1.8) + 1) / 2 * 0.07
		end
	end

	-- summer: a warm sun with slowly turning, breathing rays
	do
		local e = emblem("sun")
		local g = blob(e, 34, 34, 15, 15, Color3.fromRGB(255, 190, 60), 0.86, 1)
		local rays = new("Frame", {Size = UDim2.fromOffset(SZ, SZ), BackgroundTransparency = 1}, e)
		local rayBars = {}
		for k = 0, 7 do
			local a = math.rad(k * 45)
			rayBars[k + 1] = bar(rays, 2.6, 6, 15 + math.sin(a) * 11.5, 15 - math.cos(a) * 11.5, k * 45, Color3.fromRGB(255, 200, 70), 2)
		end
		blob(e, 15, 15, 15, 15, Color3.fromRGB(255, 185, 50), 0, 3)
		blob(e, 10, 10, 14, 14, Color3.fromRGB(255, 235, 140), 0, 4)
		anim.sun = function(t)
			rays.Rotation = (t * 15) % 360
			local p = (math.sin(t * 2.5) + 1) / 2
			for _, r in ipairs(rayBars) do r.Size = UDim2.fromOffset(2.6, 5 + p * 2.5) end
			g.BackgroundTransparency = 0.88 - p * 0.08
		end
	end

	UIFX.emblem = "void"
	function UIFX.setEmblem(name)
		UIFX.emblem = name
		for _, ch in ipairs(logo:GetChildren()) do
			if ch.Name:sub(1, 7) == "Emblem_" then ch.Visible = (not T.simple) and ch.Name == "Emblem_" .. name end
		end
	end
	bind(RunService.Heartbeat:Connect(function()
		local f = anim[UIFX.emblem]
		if f then f(os.clock()) end
	end))
end)()

-- event alerts: death, respawn, players joining / leaving
UIFX.deathAlerts, UIFX.playerAlerts = true, true
;(function() -- runs once in its own scope (keeps the top-level slot count low)
	local function watch(c)
		local h = c:WaitForChild("Humanoid", 5)
		if not h then return end
		bind(h.Died:Connect(function()
			if UIFX.deathAlerts then UIFX.notify("you died") end
		end))
	end
	if LP.Character then task.spawn(watch, LP.Character) end
	local first = true
	bind(LP.CharacterAdded:Connect(function(c)
		if not first and UIFX.deathAlerts then UIFX.notify("respawned") end
		first = false
		task.spawn(watch, c)
	end))
	if LP.Character then first = false end
	bind(Players.PlayerAdded:Connect(function(p)
		if UIFX.playerAlerts then UIFX.notify(p.DisplayName .. " joined") end
	end))
	bind(Players.PlayerRemoving:Connect(function(p)
		if UIFX.playerAlerts and p ~= LP then UIFX.notify(p.DisplayName .. " left") end
	end))
end)()

---------------------------------------------------------------- build
-- everything below runs inside its own function so it gets a fresh variable budget
-- (Roblox allows at most 200 variables per function, counting temporary values)
local function buildUI()
	-- shared rivals module cache — used by combat tab and rivals block
	local mods      = {}
	local modsReady = false

	navHeader("combat")
	local CMBT = page("combat", {"aim", "aimbot", "triggerbot", "weapons", "ragebot"})
	local cmbt_aim, cmbt_aa, cmbt_tb, cmbt_wp, cmbt_rb = CMBT.aim, CMBT.aimbot, CMBT.triggerbot, CMBT.weapons, CMBT.ragebot

	navHeader("player")
	local mv = page("movement")
	local ch = page("character")
	local ESP = page("esp", {"players"})
	buildESPPage(ESP.players)
	navHeader("world")


	-- ── KILL SOUNDS ────────────────────────────────────────────────────────────
	local KS_SOUNDS = {
		{n="Ding",          id="rbxassetid://7149516994"},
		{n="Gamesense",     id="rbxassetid://4817809188"},
		{n="Neverlose",     id="rbxassetid://6607204501"},
		{n="CoD",           id="rbxassetid://160432334"},
		{n="TF2 HitSound",  id="rbxassetid://3455144981"},
		{n="Headshot",      id="rbxassetid://8418469749"},
		{n="CSGO",          id="rbxassetid://5764885315"},
		{n="Crit",          id="rbxassetid://296102734"},
		{n="Bonk",          id="rbxassetid://3765689841"},
		{n="Fatality",      id="rbxassetid://7347423703"},
		{n="Mario",         id="rbxassetid://2815207981"},
		{n="Minecraft",     id="rbxassetid://4018616850"},
		{n="Osu",           id="rbxassetid://7149919358"},
		{n="Quake",         id="rbxassetid://4868633804"},
		{n="Killing Spree", id="rbxassetid://6822465178"},
		{n="Double Kill",   id="rbxassetid://6818527307"},
		{n="Triple Kill",   id="rbxassetid://6818526855"},
		{n="Bruh",          id="rbxassetid://4275842574"},
		{n="Oof",           id="rbxassetid://4792539171"},
		{n="Fart",          id="rbxassetid://131314452"},
	}
	local ksEnabled   = false
	local ksSoundIdx  = 1      -- index into KS_SOUNDS
	local ksVolume    = 0.8
	local ksPitch     = 1.0
	local _ksLastTarget = nil  -- Player we most recently shot
	local _ksConns = {}        -- active Died connections

	local function ksPlay()
		if not ksEnabled then return end
		local entry = KS_SOUNDS[ksSoundIdx]
		if not entry then return end
		pcall(function()
			local s = Instance.new("Sound")
			s.SoundId  = entry.id
			s.Volume   = ksVolume
			s.PlaybackSpeed = ksPitch
			s.Parent   = workspace
			s:Play()
			game:GetService("Debris"):AddItem(s, 5)
		end)
	end

	local function ksWatch(pl)
		if not pl then return end
		-- clean up previous connection for this player
		if _ksConns[pl] then
			pcall(function() _ksConns[pl]:Disconnect() end)
			_ksConns[pl] = nil
		end
		local ch = pl.Character
		if not ch then return end
		local hum = ch:FindFirstChildOfClass("Humanoid")
		if not hum then return end
		_ksConns[pl] = hum.Died:Connect(function()
			if _ksLastTarget == pl then
				ksPlay()
				_ksLastTarget = nil
			end
			if _ksConns[pl] then
				pcall(function() _ksConns[pl]:Disconnect() end)
				_ksConns[pl] = nil
			end
		end)
	end

	local VIS = page("visuals", {"lighting", "auras", "effects", "fx", "world", "skins"})
	local vs, au, ef = VIS.lighting, VIS.auras, VIS.effects
	local sk_tab = VIS.skins
	local cosmeticChanger = nil  -- set by rivals block; referenced by skins tab buttons below

	-- ── skins tab (embedded — no separate window) ──────────────────────
	local skContainer  = nil  -- filled by makeCosmeticChanger once rivals modules load
	local skRefreshRef = nil  -- cosmeticGuiState.Refresh proxy (set after build)
	do
		local skc  = card(sk_tab[1], "skin changer")
		-- reparent card to the page's ScrollingFrame so it fills full width
		-- (cols are empty; the card is the only content on this tab)
		local pg = sk_tab[1].Parent
		skc.frame.Parent   = pg
		skc.frame.Size     = UDim2.new(1, 0, 0, 0)  -- AutomaticSize.Y handles height
		skc.frame.Position = UDim2.new(0, 0, 0, 0)
		skc.note("pick weapon  →  pick skin  →  applies live")
		-- placeholder: replaced with real content once rivals modules load
		local phRow = Instance.new("Frame")
		phRow.BackgroundTransparency = 1
		phRow.Size = UDim2.new(1, 0, 0, 18)
		phRow.LayoutOrder = 99
		phRow.Parent = skc.body
		local phLbl = Instance.new("TextLabel")
		phLbl.BackgroundTransparency = 1
		phLbl.Font = Enum.Font.Gotham
		phLbl.Text = "loading…"
		phLbl.TextColor3 = Color3.fromRGB(120, 110, 140)
		phLbl.TextSize = 13
		phLbl.Size = UDim2.new(1, 0, 1, 0)
		phLbl.TextXAlignment = Enum.TextXAlignment.Left
		phLbl.Parent = phRow
		skContainer = {card = skc, placeholder = phRow, phLbl = phLbl}
		-- "reset all skins" lives at the very bottom of the same card
		-- LayoutOrder 100 ensures it renders below the embedded changer (order 10)
		local resetAllRow = Instance.new("Frame")
		resetAllRow.BackgroundTransparency = 1
		resetAllRow.Size = UDim2.new(1, 0, 0, 26)
		resetAllRow.LayoutOrder = 100
		resetAllRow.Parent = skc.body
		local resetAllBtn = Instance.new("TextButton")
		resetAllBtn.AutoButtonColor = false
		resetAllBtn.BackgroundColor3 = Color3.fromRGB(27, 18, 39)
		resetAllBtn.BorderSizePixel = 0
		resetAllBtn.Size = UDim2.new(1, 0, 1, 0)
		resetAllBtn.Font = Enum.Font.Gotham
		resetAllBtn.Text = "reset all skins"
		resetAllBtn.TextColor3 = Color3.fromRGB(239, 228, 250)
		resetAllBtn.TextSize = 14
		resetAllBtn.Parent = resetAllRow
		local rab_corner = Instance.new("UICorner"); rab_corner.CornerRadius = UDim.new(0, 8); rab_corner.Parent = resetAllBtn
		local rab_stroke = Instance.new("UIStroke"); rab_stroke.Color = Color3.fromRGB(61, 39, 82); rab_stroke.Thickness = 1; rab_stroke.Parent = resetAllBtn
		resetAllBtn.MouseEnter:Connect(function() resetAllBtn.BackgroundColor3 = Color3.fromRGB(48, 27, 67); rab_stroke.Color = Color3.fromRGB(167, 75, 235) end)
		resetAllBtn.MouseLeave:Connect(function() resetAllBtn.BackgroundColor3 = Color3.fromRGB(27, 18, 39); rab_stroke.Color = Color3.fromRGB(61, 39, 82) end)
		resetAllBtn.MouseButton1Click:Connect(function()
			if not cosmeticChanger then return end
			cosmeticChanger.Reset()
		end)
	end

	-- ══════════════════════════════════════════════════════════════════
	-- COMBAT TAB LOGIC
	-- Target finding: Players:GetPlayers() + .Character (no FC dependency)
	-- Item: fc.LocalFighter.EquippedItem (direct, same as Harion)
	-- Hook args: self, obj, action, camdata — modify camdata, pass obj as-is
	-- ══════════════════════════════════════════════════════════════════
	do
		-- shared helpers ─────────────────────────────────────────────────
		local function getPlayers()
			-- returns list of enemy characters (Instance/Model with HRP+Head)
			local out = {}
			for _, plr in ipairs(game:GetService("Players"):GetPlayers()) do
				if plr ~= LP and plr.Character then
					local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
					local hum = plr.Character:FindFirstChildOfClass("Humanoid")
					if hrp and hum and hum.Health > 0 then
						table.insert(out, plr.Character)
					end
				end
			end
			return out
		end

		local function getUseItemRemote()
			return game:GetService("ReplicatedStorage"):FindFirstChild("UseItem", true)
		end

		local function getFC()
			return mods.FighterController  -- populated by rivals block (modsReady)
		end

		local function getEquippedItem()
			local fc = getFC()
			return fc and fc.LocalFighter and fc.LocalFighter.EquippedItem
		end

		-- cache enum after first successful resolve so hook doesn't depend on mods timing
		local _startShootCache = nil
		local function getStartShootEnum()
			if _startShootCache then return _startShootCache end
			local elib = mods.EnumLibrary
			if not elib then
				-- fallback: require directly
				local RSMods = game:GetService("ReplicatedStorage"):FindFirstChild("Modules")
				if RSMods then
					local ok, lib = pcall(require, RSMods:FindFirstChild("EnumLibrary"))
					if ok then elib = lib end
				end
			end
			if not elib then return nil end
			local ok, v = pcall(elib.ToEnum, elib, "StartShooting")
			if ok and v then _startShootCache = v end
			return _startShootCache
		end

		local function screenPos(hrp)
			local sp, vis = Camera:WorldToViewportPoint(hrp.Position)
			return vis, Vector2.new(sp.X, sp.Y)
		end

		-- closest enemy character to mouse within fov radius
		local function getTarget(fovRadius, visOnly)
			local mp   = UIS:GetMouseLocation()
			local best, bestD = nil, fovRadius
			for _, char in ipairs(getPlayers()) do
				local hrp = char:FindFirstChild("HumanoidRootPart")
				if not hrp then continue end
				local vis, sp2 = screenPos(hrp)
				if not vis then continue end
				if visOnly then
					-- already on screen = visible enough for rivals (no ray needed)
				end
				local d = (sp2 - mp).Magnitude
				if d < bestD then best, bestD = char, d end
			end
			return best
		end

		-- ── mode hotkey (aimbot / silent / triggerbot) ──────────────────
		-- setters hoisted here so the hotkey block can reach into each do-scope
		local _setSilent, _setAimbot, _setTrigger = nil, nil, nil

		-- ── SILENT AIM ───────────────────────────────────────────────────
		do
			local saOn      = false
			local saFovV    = 120
			local saHitV    = 100
			local saHsV     = 65
			local saBodyV   = 35
			local saManipV  = false
			local saAfireV  = false
			local saVisV    = false
			local saShowFov = true

			-- ── KATANA PROOF (sky desync) ────────────────────────────────────────────────
			-- Keeps you in sky at all times so melee/katana can never reach you.
			-- Pauses for the exact window of each shot so bullets fire from correct pos.
			local dsKatana  = false   -- master toggle
			local _dsFiring = false   -- true during FireServer call only
			local _dsActive = false   -- loop running flag

			local function _dsSkyLoop()
				if _dsActive then return end
				_dsActive = true
				task.spawn(function()
					while dsKatana do
						task.wait(0.05)
						if _dsFiring then continue end  -- pause during actual shot
						pcall(function()
							local ch = LP.Character
							if not ch then return end
							local hrp = ch:FindFirstChild("HumanoidRootPart")
							if not hrp then return end
							local rx = math.random(-600, 600)
							local rz = math.random(-600, 600)
							local ry = 9000 + math.random(0, 2000)
							hrp.CFrame = CFrame.new(rx, ry, rz)
						end)
					end
					_dsActive = false
				end)
			end

			-- ── DESYNC (shot + reload) ────────────────────────────────────────────────────
			local dsShot    = false   -- TP into target on each shot
			local dsReload  = false   -- thrash sky positions while reloading

			local _dsReloading = false

			local function dsShotTp(targetHRP)
				local myChar = LP.Character
				if not (myChar and targetHRP) then return end
				local myHRP = myChar:FindFirstChild("HumanoidRootPart")
				if not myHRP then return end
				pcall(function() myHRP.CFrame = targetHRP.CFrame end)
			end

			local function dsReloadLoop(item)
				if _dsReloading then return end
				_dsReloading = true
				task.spawn(function()
					local savedCF
					pcall(function()
						local ch = LP.Character
						local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
						if hrp then savedCF = hrp.CFrame end
					end)
					local t = 0
					while _dsReloading and t < 8 do
						task.wait(0.05)
						t = t + 0.05
						pcall(function()
							local ch = LP.Character
							if not ch then return end
							local hrp = ch:FindFirstChild("HumanoidRootPart")
							if hrp then
								hrp.CFrame = CFrame.new(
									math.random(-500, 500),
									9000 + math.random(0, 2000),
									math.random(-500, 500)
								)
							end
						end)
						local ok, reloading = pcall(function() return item:IsReloading() end)
						if ok and not reloading then break end
					end
					_dsReloading = false
					if savedCF then
						pcall(function()
							local ch = LP.Character
							local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
							if hrp then hrp.CFrame = savedCF end
						end)
					end
				end)
			end


			_setSilent = function(v) saOn = v end

			local sa1 = card(cmbt_aim[1], "silent aim")
			sa1.note("hooks UseItem remote — redirects shots to target within fov")
			sa1.toggle("enabled",                  false, function(v) saOn     = v end)
			sa1.slider("fov radius",  10, 500, 120, function(v) saFovV  = v end, " px")
			sa1.slider("hit chance",   0, 100, 100, function(v) saHitV  = v end, " %")
			sa1.slider("headshot %",   0, 100,  65, function(v) saHsV   = v end, " %")
			sa1.slider("body %",       0, 100,  35, function(v) saBodyV  = v end, " %")
			sa1.toggle("manipulation (prediction)",false, function(v) saManipV = v end)
			sa1.toggle("auto shoot",               false, function(v) saAfireV = v end)
			sa1.toggle("visible only",             false, function(v) saVisV   = v end)
			do
				sa1.hotkey("hotkey", function(k, mode, pressed)
					if not k then return end
					if mode == "toggle" then
						if pressed then saOn = not saOn; _setSilent(saOn) end
					else  -- hold / always
						saOn = pressed; _setSilent(pressed)
					end
				end)
			end
			local sa2 = card(cmbt_aim[2], "fov circle")
			sa2.toggle("show fov circle", true, function(v) saShowFov = v end)

			-- fov circle
			local saCircle
			bind(RunService.RenderStepped:Connect(function()
				if not saOn or not saShowFov then
					if saCircle then saCircle.Visible = false end return
				end
				if not saCircle then
					saCircle = Drawing.new("Circle")
					saCircle.Filled = false saCircle.Thickness = 1
					saCircle.Color  = Color3.new(1,1,1) saCircle.Visible = false
				end
				local mp = UIS:GetMouseLocation()
				saCircle.Position = mp saCircle.Radius = saFovV saCircle.Visible = true
			end))

			-- hook — installs immediately, saOn flag controls behavior
			local saOldFire, saHookDone = nil, false
			task.spawn(function()
				-- wait for RemoteEvent to exist (spawns on match load)
				local rem
				for _ = 1, 300 do
					rem = getUseItemRemote()
					if rem then break end
					task.wait(0.1)
				end
				if not rem or not hookfunction or not newcclosure then return end
				if saHookDone then return end
				saOldFire = hookfunction(rem.FireServer, newcclosure(function(self, obj, action, camdata, ...)
					if saOn then
						local startShot = getStartShootEnum()
						-- StartShooting (\x1A) + FinishAiming (\x22 sniper release)
						local isShot = startShot and (action == startShot or string.byte(action,1) == 0x22)
						if isShot then
							-- hit chance
							if math.random(0, 100) > saHitV then
								return saOldFire(self, obj, action, camdata, ...)
							end
							local target = getTarget(saFovV, saVisV)
							if target then
								local head = target:FindFirstChild("Head")
								local hrp2 = target:FindFirstChild("HumanoidRootPart")
								local tpart = (math.random(0, 100) <= saHsV and head) or hrp2
								tpart = tpart or head or hrp2
								if tpart then
									-- Rivals SA: fix both direction CFrame and hit part
									-- CameraData inner = {["\x00"]=encCamCF,["\x01"]=encDirCF,["\x02"]=hitPart,["\x03"]=hitOffset}
									-- EncodeCFrame: {["\x00"]=X,["\x01"]=Y,["\x02"]=Z,["\x03"]=RX,["\x04"]=RY,["\x05"]=RZ}
									-- head% / body% / miss split
									local _roll = math.random(0,100)
									local hitbox
									if _roll <= saHsV then
										hitbox = target:FindFirstChild("HitboxHead") or target:FindFirstChild("HitboxHeadSmall") or target:FindFirstChild("HitboxBody")
									elseif _roll <= saHsV + saBodyV then
										hitbox = target:FindFirstChild("HitboxBody")
									else
										hitbox = nil -- miss
									end
									if not hitbox then return saOldFire(self, obj, action, camdata, ...) end
									local function encodeCF(cf)
										local rx,ry,rz = cf:ToOrientation()
										return {["\x00"]=cf.X,["\x01"]=cf.Y,["\x02"]=cf.Z,["\x03"]=rx,["\x04"]=ry,["\x05"]=rz}
									end
									if type(camdata) == "table" and camdata["\x01"] then
										local inner = camdata["\x01"]
										inner["\x01"] = encodeCF(CFrame.lookAt(Camera.CFrame.Position, hitbox.Position))
										inner["\x02"] = hitbox
										inner["\x03"] = nil
									end
									return saOldFire(self, obj, action, camdata, ...)
								end
							end
						end
					end
				-- katana proof: while dsKatana, block manual shots during reload
				if dsKatana then
					local _gb = type(action) == "string" and string.byte(action, 1) or -1
					local _isShot = (_gb == 0x1A or _gb == 0x22 or (startShot and action == startShot))
					if _isShot then
						local _ritem = getEquippedItem()
						local ok, reloading = pcall(function() return _ritem and _ritem:IsReloading() end)
						if ok and reloading then return end
					end
				end
				-- desync reload: start sky thrash on StartReloading
				if dsReload then
					local _gb = type(action) == "string" and string.byte(action, 1) or -1
					if _gb == 0x00 then
						local _ritem = getEquippedItem()
						if _ritem then
							task.spawn(function() task.wait(0.05) dsReloadLoop(_ritem) end)
						end
					end
				end
					return saOldFire(self, obj, action, camdata, ...)
				end))
				saHookDone = true
			end)

			-- auto shoot: fire UseItem directly toward target
			bind(RunService.Heartbeat:Connect(function()
				if not saOn or not saAfireV then return end
				local rem = getUseItemRemote()
				if not rem then return end
				local item = getEquippedItem()
				if not item then return end
				local startShot = getStartShootEnum()
				if not startShot then return end
				local target = getTarget(saFovV, saVisV)
				if not target then return end
				local hrp2 = target:FindFirstChild("HumanoidRootPart")
				if not hrp2 then return end
				local camdata = {Camera={CFrame=CFrame.lookAt(Camera.CFrame.Position, hrp2.Position)}}
				pcall(rem.FireServer, rem, item, startShot, camdata, nil)
			end))
		end

		-- ── AIM ASSIST ──────────────────────────────────────────────────
		do
			local aaOn     = false
			local aaFovV   = 120
			local aaSpeedV = 50
			local aaLerpV  = 1
			local aaShowV  = true
			local aaDelayV = true
			local aaClosV  = false
			local aaSensV  = 1.0
			local aaWalls  = true   -- check walls
			local aaYOff   = 0.0    -- aim offset (studs up)

			_setAimbot = function(v) aaOn = v end

			local aa1 = card(cmbt_aa[1], "aim assist")
			aa1.note("moves mouse toward nearest target in fov — mousemoverel")
			aa1.toggle("enabled",                    false, function(v) aaOn     = v end)
			aa1.slider("fov radius",   0, 1000, 120, function(v) aaFovV   = v end, " px")
			aa1.slider("smoothing",    1,  100,  50, function(v) aaSpeedV = v end, " %")
			aa1.slider("lerp",         1,   10,   1, function(v) aaLerpV  = v end, "x")
			aa1.slider("sensitivity", 1,   20,   10, function(v) aaSensV  = v / 10 end, "x")
			aa1.slider("aim height",  -3,   3,    0, function(v) aaYOff   = v end, " st", 0.1)
			aa1.toggle("show fov circle",            true,  function(v) aaShowV  = v end)
			aa1.toggle("check walls",                true,  function(v) aaWalls  = v end)
			aa1.toggle("delay position (prediction)",true,  function(v) aaDelayV = v end)
			aa1.toggle("closest part",               false, function(v) aaClosV  = v end)
			do
				aa1.hotkey("hotkey", function(k, mode, pressed)
					if not k then return end
					if mode == "toggle" then
						if pressed then aaOn = not aaOn; _setAimbot(aaOn) end
					else
						aaOn = pressed; _setAimbot(pressed)
					end
				end)
			end

			local aaCircle
			bind(RunService.RenderStepped:Connect(function(dt)
				if not aaOn then
					if aaCircle then aaCircle.Visible = false end return
				end
				if not aaCircle then
					aaCircle = Drawing.new("Circle")
					aaCircle.Filled = false aaCircle.Thickness = 1
					aaCircle.Color  = Color3.fromRGB(180,220,255) aaCircle.Visible = false
				end
				local mp = UIS:GetMouseLocation()
				aaCircle.Position = mp aaCircle.Radius = aaFovV aaCircle.Visible = aaShowV

				if not mousemoverel then return end
				local char = getTarget(aaFovV, false)
				if not char then return end

				-- default: Head. closest part overrides.
				local part = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
				if aaClosV then
					local closest, closestD = nil, math.huge
					for _, p in ipairs(char:GetChildren()) do
						if p:IsA("BasePart") then
							local vis2, sp2 = screenPos(p)
							if vis2 then
								local d2 = (sp2 - UIS:GetMouseLocation()).Magnitude
								if d2 < closestD then closest, closestD = p, d2 end
							end
						end
					end
					if closest then part = closest end
				end
				if not part then return end

				local targetPos = part.Position + Vector3.new(0, aaYOff, 0)
				if aaDelayV then
					targetPos = targetPos + part.AssemblyLinearVelocity * math.clamp(aaSpeedV / 1000, 0, 0.2)
				end

				-- wall check: raycast camera → target, skip if blocked by terrain/parts
				if aaWalls then
					local camPos = Camera.CFrame.Position
					local dir    = targetPos - camPos
					local rp2    = RaycastParams.new()
					rp2.FilterType = Enum.RaycastFilterType.Exclude
					local myChar = LP.Character
					local excl   = myChar and {myChar, char} or {char}
					rp2.FilterDescendantsInstances = excl
					local hit2 = workspace:Raycast(camPos, dir * 0.99, rp2)
					if hit2 then return end  -- target is behind a wall
				end

				-- Harion-identical angle math
				-- moveConst = Vector2.new(1, 0.77) * math.rad(0.5)  (Y axis is 0.77x)
				local moveConst = Vector2.new(math.rad(0.5), 0.77 * math.rad(0.5))
				local facing = Camera.CFrame.LookVector
				local newDir = (targetPos - Camera.CFrame.Position).Unit
				if newDir == Vector3.zero then return end

				local function wrapA(a)
					while a > math.pi  do a -= 2*math.pi end
					while a < -math.pi do a += 2*math.pi end
					return a
				end
				local diffYaw   = wrapA(math.atan2(facing.X, facing.Z) - math.atan2(newDir.X, newDir.Z))
				local diffPitch = math.asin(facing.Y) - math.asin(newDir.Y)
				local sens      = UserSettings():GetService("UserGameSettings").MouseSensitivity
				local angle     = Vector2.new(diffYaw, diffPitch) / (moveConst * sens)
				angle = angle * math.min((aaSpeedV / 100) * aaLerpV * aaSensV * dt * 10, 1)
				mousemoverel(angle.X, angle.Y)
			end))
		end

		-- ── TRIGGERBOT ──────────────────────────────────────────────────
		do
			local tbOn      = false
			local tbConn    = nil
			local tbDelay   = 0      -- ms, wired to slider
			local tbMaxDist = 200    -- studs, wired to slider
			local tbFiredAt = 0      -- os.clock() of last fire, for cooldown
			local tbPending = false  -- delay task running

			-- walk up from hit instance until we find a player character
			local function resolveChar(inst)
				if not inst then return nil end
				local plrs = game:GetService("Players")
				local obj = inst
				for _ = 1, 6 do  -- max 6 levels up
					local plr = plrs:GetPlayerFromCharacter(obj)
					if plr and plr ~= LP then return plr, obj end
					obj = obj.Parent
					if not obj or obj == workspace then break end
				end
				return nil, nil
			end

			local function doFire(rem, item, startShot)
				tbFiredAt = os.clock()
				pcall(rem.FireServer, rem, item, startShot, {Camera={CFrame=Camera.CFrame}}, nil)
			end

			local function startTB()
				if tbConn then tbConn:Disconnect() end
				tbConn = RunService.Heartbeat:Connect(function()
					if tbPending then return end  -- delay task in flight, skip frame

					local item = getEquippedItem()
					if not item then return end
					local startShot = getStartShootEnum()
					if not startShot then return end
					local rem = getUseItemRemote()
					if not rem then return end

					-- raycast from crosshair, capped to tbMaxDist
					local vp = Camera.ViewportSize
					local unitRay = Camera:ScreenPointToRay(vp.X / 2, vp.Y / 2)
					local rp = RaycastParams.new()
					rp.FilterType = Enum.RaycastFilterType.Exclude
					if LP.Character then rp.FilterDescendantsInstances = {LP.Character} end
					local result = workspace:Raycast(unitRay.Origin, unitRay.Direction * tbMaxDist, rp)
					if not result then return end

					-- resolve player from hit part (handles Rivals hitbox hierarchy)
					local plr, char = resolveChar(result.Instance)
					if not plr or not char then return end

					-- alive check via Humanoid (may be nested in char)
					local hum = char:FindFirstChildOfClass("Humanoid")
							or char:FindFirstChild("Humanoid")
					if hum and hum.Health <= 0 then return end

					-- teammate check (TeammateLabel on any child of char)
					for _, v in ipairs(char:GetDescendants()) do
						if v.Name == "TeammateLabel" then return end
					end

					-- fire immediately or after delay
					if tbDelay <= 0 then
						doFire(rem, item, startShot)
					else
						tbPending = true
						task.delay(tbDelay / 1000, function()
							tbPending = false
							if not tbOn then return end
							-- re-check enemy still on crosshair after delay
							local vp2 = Camera.ViewportSize
							local ray2 = Camera:ScreenPointToRay(vp2.X / 2, vp2.Y / 2)
							local r2 = workspace:Raycast(ray2.Origin, ray2.Direction * tbMaxDist, rp)
							if not r2 then return end
							local p2, c2 = resolveChar(r2.Instance)
							if p2 ~= plr then return end  -- different target, abort
							local rem2  = getUseItemRemote()
							local item2 = getEquippedItem()
							local ss2   = getStartShootEnum()
							if rem2 and item2 and ss2 then
								doFire(rem2, item2, ss2)
							end
						end)
					end
				end)
				bind(tbConn)
			end

			_setTrigger = function(v)
				tbOn = v
				tbPending = false
				if tbConn then tbConn:Disconnect() tbConn = nil end
				if v then startTB() end
			end

			local tb1 = card(cmbt_tb[1], "triggerbot")
			tb1.note("fires when crosshair is on an enemy — raycast based")
			tb1.toggle("enabled", false, function(v)
				tbOn = v
				tbPending = false
				if tbConn then tbConn:Disconnect() tbConn = nil end
				if v then startTB() end
			end)
			tb1.slider("reaction delay", 0, 500, 0, function(v) tbDelay   = v end, " ms")
			tb1.slider("max distance",  25, 500, 200, function(v) tbMaxDist = v end, " studs")
			do
				tb1.hotkey("hotkey", function(k, mode, pressed)
					if not k then return end
					if mode == "toggle" then
						if pressed then _setTrigger(not tbOn) end
					else
						_setTrigger(pressed)
					end
				end)
			end
		end

		-- ── (mode hotkey widget removed — hotkeys are now inside each feature card) ──
		-- standalone floating widget — not a card
		-- MB1 on pill = next mode · MB2 = prev mode · hotkey (none by default) = next mode
		do
			local MODES = { "none", "aimbot", "silent", "triggerbot" }
			local modeCols = {
				Color3.fromRGB(110, 110, 130),   -- none
				Color3.fromRGB(80,  200, 120),   -- aimbot
				Color3.fromRGB(168,  85, 247),   -- silent
				Color3.fromRGB(255, 160,  60),   -- triggerbot
			}
			local modeIdx = 1   -- starts at "none"
			local hkKey   = nil -- no default hotkey
			local hkListening = false

			local function applyMode(idx)
				modeIdx = idx
				if _setAimbot  then _setAimbot(false)  end
				if _setSilent  then _setSilent(false)   end
				if _setTrigger then _setTrigger(false)  end
				local m = MODES[idx]
				if m == "aimbot"     and _setAimbot  then _setAimbot(true)  end
				if m == "silent"     and _setSilent  then _setSilent(true)   end
				if m == "triggerbot" and _setTrigger then _setTrigger(true)  end
			end

			-- ── floating pill widget ──────────────────────────────────────
			local HKW_W, HKW_H = 180, 52
			local hkWin = new("Frame", {
				Size        = UDim2.fromOffset(HKW_W, HKW_H),
				Position    = UDim2.fromOffset(20, 200),
				AnchorPoint = Vector2.new(0, 0),
				BackgroundColor3    = Color3.fromRGB(14, 12, 22),
				BackgroundTransparency = 0.08,
				BorderSizePixel     = 0,
				ZIndex              = 80,
				Active              = true,
				Draggable           = true,
				ClipsDescendants    = false,
			}, gui)
			corner(hkWin, 14)
			new("UIStroke", {Color = Color3.fromRGB(80,60,120), Thickness = 1, Transparency = 0.4}, hkWin)

			-- label row
			local hkLabel = new("TextLabel", {
				Size            = UDim2.new(1, -8, 0, 16),
				Position        = UDim2.fromOffset(8, 4),
				BackgroundTransparency = 1,
				Text            = "mode hotkey",
				FontFace        = F.body,
				TextSize        = 11,
				TextColor3      = Color3.fromRGB(140, 130, 160),
				TextXAlignment  = Enum.TextXAlignment.Left,
				ZIndex          = 81,
			}, hkWin)

			-- mode pill (left, wide) — MB1 next, MB2 prev
			local modePill = new("TextButton", {
				Size            = UDim2.fromOffset(112, 26),
				Position        = UDim2.fromOffset(6, 22),
				BackgroundColor3= modeCols[modeIdx],
				BackgroundTransparency = 0.55,
				Text            = "● " .. MODES[modeIdx],
				FontFace        = F.body,
				TextSize        = 13,
				TextColor3      = modeCols[modeIdx],
				AutoButtonColor = false,
				BorderSizePixel = 0,
				ZIndex          = 82,
			}, hkWin)
			corner(modePill, 10)
			new("UIStroke", {Color = modeCols[modeIdx], Thickness = 1, Transparency = 0.45}, modePill)
			local modePillStroke = modePill:FindFirstChildOfClass("UIStroke")

			local function refreshPill()
				local c = modeCols[modeIdx]
				modePill.Text             = "● " .. MODES[modeIdx]
				modePill.TextColor3       = c
				modePill.BackgroundColor3 = c
				if modePillStroke then modePillStroke.Color = c end
			end

			bind(modePill.MouseButton1Click:Connect(function()
				modeIdx = modeIdx % #MODES + 1
				applyMode(modeIdx)
				refreshPill()
			end))
			bind(modePill.MouseButton2Click:Connect(function()
				modeIdx = (modeIdx - 2) % #MODES + 1
				applyMode(modeIdx)
				refreshPill()
			end))

			-- keybind pill (right, small) — click to set, press key, Escape clears
			local hkPill = new("TextButton", {
				Size            = UDim2.fromOffset(54, 26),
				Position        = UDim2.fromOffset(122, 22),
				BackgroundColor3= Color3.fromRGB(30, 25, 45),
				BackgroundTransparency = 0.3,
				Text            = "none",
				FontFace        = F.body,
				TextSize        = 11,
				TextColor3      = Color3.fromRGB(140, 130, 160),
				AutoButtonColor = false,
				BorderSizePixel = 0,
				ZIndex          = 82,
			}, hkWin)
			corner(hkPill, 10)
			new("UIStroke", {Color = Color3.fromRGB(80,60,120), Thickness = 1, Transparency = 0.5}, hkPill)

			local function refreshHkPill()
				if hkListening then
					hkPill.Text      = "..."
					hkPill.TextColor3= Color3.fromRGB(220,200,255)
				elseif hkKey then
					hkPill.Text      = hkKey.Name
					hkPill.TextColor3= Color3.fromRGB(200,190,220)
				else
					hkPill.Text      = "none"
					hkPill.TextColor3= Color3.fromRGB(120,110,140)
				end
			end

			bind(hkPill.MouseButton1Click:Connect(function()
				hkListening = true
				refreshHkPill()
			end))
			bind(hkPill.MouseButton2Click:Connect(function()
				-- right-click clears keybind
				hkKey = nil
				hkListening = false
				refreshHkPill()
			end))

			-- input: key sets bind, Escape clears, mouse buttons ignored
			bind(UIS.InputBegan:Connect(function(i, gp)
				if gp then return end
				if hkListening then
					if i.UserInputType == Enum.UserInputType.Keyboard then
						hkListening = false
						if i.KeyCode == Enum.KeyCode.Escape then
							hkKey = nil
						else
							hkKey = i.KeyCode
						end
						refreshHkPill()
					end
					return
				end
				-- fire hotkey
				if hkKey and i.UserInputType == Enum.UserInputType.Keyboard and i.KeyCode == hkKey then
					modeIdx = modeIdx % #MODES + 1
					applyMode(modeIdx)
					refreshPill()
				end
			end))

			bind({ Disconnect = function() hkWin:Destroy() end })
		end

		-- ── WEAPONS ─────────────────────────────────────────────────────
		do
			local wpState = {
				noSpread=false, fastShoot=false, fullAuto=false,
				backstab=false, fireRate=100, enabled=false,
				infoCache = setmetatable({},{__mode="k"}),
			}

			local function remInfo(info, key)
				if type(info)~="table" or info[key]==nil then return nil end
				local c = wpState.infoCache[info]
				if not c then c={} wpState.infoCache[info]=c end
				if c[key]==nil then c[key]=info[key] end
				return c[key]
			end
			local function applyInfo(item)
				local info = item and item.Info
				if type(info)~="table" then return end
				local rate = math.max(wpState.fireRate/100, 0.01)
				local fs   = wpState.enabled and wpState.fastShoot
				local recoil = remInfo(info,"ShootRecoil")
				if recoil~=nil then info.ShootRecoil = fs and 0 or recoil end
				local spread = remInfo(info,"ShootSpread")
				if spread~=nil then info.ShootSpread = (wpState.enabled and wpState.noSpread) and 0 or spread end
				local ps = remInfo(info,"ProjectileSpeed")
				if ps~=nil then info.ProjectileSpeed = fs and 99999999 or ps end
				local fa = wpState.enabled and wpState.fullAuto
				for _,k in ipairs({"ShootCooldown","QuickShotCooldown","BurstCooldown","AttackCooldown","HeavyAttackCooldown","Cooldown"}) do
					local orig = remInfo(info,k)
					if orig~=nil then
						if fs or fa then info[k]=0
						elseif rate~=1 then info[k]=orig/rate
						else info[k]=orig end
					end
				end
			end
			local function restoreInfo()
				for info,vals in pairs(wpState.infoCache) do
					if type(info)=="table" then
						for k,v in pairs(vals) do pcall(function() info[k]=v end) end
					end
				end
			end
			local function refreshAll()
				-- apply to local fighter's equipped item
				local item = getEquippedItem()
				if item then applyInfo(item) end
				-- apply to all players' fighters if FC is loaded
				local fc = getFC()
				if fc and fc.Objects then
					pcall(function()
						for _,fighter in pairs(fc.Objects) do
							local fi = fighter and fighter.EquippedItem
							if fi then applyInfo(fi) end
						end
					end)
				end
			end
			local function updateWp()
				wpState.enabled = wpState.noSpread or wpState.fastShoot or wpState.fullAuto
					or wpState.backstab or wpState.fireRate~=100
				if wpState.enabled then refreshAll() else restoreInfo() end
			end

			local wp1 = card(cmbt_wp[1], "weapon options")
			wp1.note("patches item info tables — no recoil, full auto, fast shoot")
			wp1.toggle("no spread / no recoil", false, function(v) wpState.noSpread  = v updateWp() end)
			wp1.toggle("fast shoot",            false, function(v) wpState.fastShoot = v updateWp() end)
			wp1.toggle("full auto",             false, function(v) wpState.fullAuto  = v updateWp() end)
			wp1.toggle("always backstab",       false, function(v) wpState.backstab  = v updateWp() end)
			wp1.slider("fire rate", 1, 100, 100, function(v) wpState.fireRate = v updateWp() end, " %")
			wp1.toggle("katana proof (sky desync)", false, function(v)
				dsKatana = v
				if v then _dsSkyLoop() end
			end)
			wp1.toggle("desync shot (TP into target)", false, function(v) dsShot   = v end)
			wp1.toggle("desync reload (sky thrash)",   false, function(v) dsReload = v end)

			bind(RunService.Heartbeat:Connect(function()
				if not wpState.enabled then return end
				refreshAll()
			end))

			-- full auto: hold mouse1 → send FireServer on cooldown
			local _faLast = 0
			bind(RunService.Heartbeat:Connect(function()
				if not wpState.fullAuto then return end
				if not UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then return end
				local rem  = getUseItemRemote()
				local item = getEquippedItem()
				local ss   = getStartShootEnum()
				if not rem or not item or not ss then return end
				local info = item.Info
				local cd   = (type(info)=="table" and (info.ShootCooldown or info.Cooldown or info.AttackCooldown)) or 0.1
				local now  = os.clock()
				if now - _faLast < math.max(cd, 0.04) then return end
				_faLast = now
				pcall(rem.FireServer, rem, item, ss, {Camera={CFrame=Camera.CFrame}}, nil)
			end))

		end

		-- ── RAGEBOT ──────────────────────────────────────────────────────────────────
		do
			-- ── module cache ─────────────────────────────────────────────────────────
			-- warm once in background; hot path reads upvalue locals only
			local _FC     = false
			local _SC     = false
			local _util   = false
			local _enum   = false
			local _remote = false  -- UseItem RemoteEvent (cached)

			task.spawn(function()
				local rs = cloneref(game:GetService("ReplicatedStorage"))
				local pl = cloneref(game:GetService("Players"))
				for _ = 1, 60 do
					pcall(function()
						if not _util  then _util  = require(rs.Modules.Utility)     or false end
						if not _enum  then _enum  = require(rs.Modules.EnumLibrary) or false end
						if not _FC    then _FC    = require(pl.LocalPlayer.PlayerScripts.Controllers.FighterController) or false end
						if not _SC    then _SC    = require(pl.LocalPlayer.PlayerScripts.Controllers:WaitForChild("SpectateController", 3)) or false end
					end)
					if not _remote then
						pcall(function()
							_remote = rs.Remotes.Replication.Fighter.UseItem
						end)
					end
					if _util and _enum and _FC and _SC and _remote then break end
					task.wait(0.5)
				end
			end)



			-- ── settings ─────────────────────────────────────────────────────────────
			local rbEnabled       = false
			local rbFireRate      = 0.0005   -- seconds between shots (may be overridden by sgFast)
			local rbFireRateBase  = 0.0005   -- slider value; sgFast overrides rbFireRate when active
			local rbSlot          = 1        -- 1=Primary 2=Secondary 3=Melee
			local rbDesync        = true     -- physically move HRP server-side, restore before camera tick
			local rbKnifeCheck    = true     -- skip katana holders during deflect
			local rbHeadshot      = true     -- aim head; false = root (body)
			local rbFovRadius     = 9999     -- screen px; 9999 = unlimited (all angles, through walls)
			local rbAutoEquip     = true     -- re-equip slot every second
			local rbExtrapolation = true     -- lead moving targets based on ping
			local rbSgFast        = false    -- 3× fire speed when shotgun equipped (ShootPellets > 1)
			local _sgFastItem     = nil      -- cached EquippedItem for sgFast check
			local _sgFastIsSg     = false    -- cached result: is equipped item a shotgun?
			local _rbHoldUntil    = 0        -- tick() timestamp; ragebot suppressed until this time
			local rbHB            = nil

			-- ── shared enum keys (from source) ───────────────────────────────────────
			local K0 = utf8.char(0)
			local K1 = utf8.char(1)
			local K2 = utf8.char(2)
			local K3 = utf8.char(3)

			-- eye offset: shots originate from eye level, not feet (source: SHOOT_EYE_OFFSET)
			local EYE_OFFSET = Vector3.new(0, 1.5, 0)

			-- ── equip loop ───────────────────────────────────────────────────────────
			local _equipLoop = nil
			local function startEquipLoop()
				if _equipLoop then return end
				_equipLoop = task.spawn(function()
					while rbEnabled do
						if _FC and _FC.LocalFighter then
							pcall(function() _FC.LocalFighter:EquipItem(rbSlot) end)
						end
						task.wait(1)
					end
					_equipLoop = nil
				end)
			end

			-- ── katana deflect tracking ───────────────────────────────────────────────
			local deflecting = {}
			Players.PlayerRemoving:Connect(function(p) deflecting[p] = nil end)

			local _deflectAt = 0
			local function updateDeflection()
				local now = os.clock()
				if now - _deflectAt < 0.1 then return end
				_deflectAt = now
				if not _FC or not _FC.Objects then return end
				for _, fo in _FC.Objects do
					local pl = fo.Player
					if not pl then continue end
					local entity = fo.Entity
					if not entity or not entity:IsAlive() then
						deflecting[pl] = false; continue
					end
					local ok, spectating = pcall(function() return fo:Get("IsSpectating") == true end)
					if ok and spectating then deflecting[pl] = false; continue end
					local eq = fo.EquippedItem
					local vm = eq and eq.ViewModel
					local isDeflecting = false
					if vm and vm.Name == "Katana" then
						isDeflecting = (eq._attack_cooldown and eq._attack_cooldown > tick()) or false
					end
					deflecting[pl] = isDeflecting
				end
			end

			-- ── immunity check (invincible / spawn shield / forcefield) ───────────────
			local IMMUNE_ATTRS = { "IsInvincible", "Immune", "IsImmune", "SpawnProtection" }
			local function isImmune(pl)
				local ch = pl.Character
				if ch then
					if ch:FindFirstChildOfClass("ForceField") then return true end
					for _, a in IMMUNE_ATTRS do
						if ch:GetAttribute(a) == true then return true end
					end
				end
				for _, a in IMMUNE_ATTRS do
					if pl:GetAttribute(a) == true then return true end
				end
				return false
			end

			-- ── team / duel enemy check ───────────────────────────────────────────────
			local function isEnemy(pl)
				if pl == LP then return false end
				if _SC then
					local duel = _SC.CurrentDuelSubject
					local ld   = duel and duel:GetDueler(LP)
					local lt   = ld  and ld:Get("TeamID")
					if lt and duel and duel.Duelers then
						for _, d in duel.Duelers do
							if d.Player == pl then return d:Get("TeamID") ~= lt end
						end
					end
				end
				local pt = pl:GetAttribute("TeamID")
				local lt = LP:GetAttribute("TeamID")
				if pt and lt then return pt ~= lt end
				return true
			end

			-- ── screen-space FOV — position only, no wall occlusion ───────────────────
			local function rbInFov(hrp)
				if rbFovRadius >= 9999 then return true end
				local p3, onScreen = Camera:WorldToViewportPoint(hrp.Position)
				if not onScreen then return false end
				return (Vector2.new(p3.X, p3.Y) - UIS:GetMouseLocation()).Magnitude <= rbFovRadius
			end

			-- ── knife viewmodel / loadout detection ───────────────────────────────────
			local function hasKnifeViewModel(pl)
				if not pl then return false end
				local vm = workspace:FindFirstChild("ViewModels")
				if not vm then return false end
				for _, m in vm:GetChildren() do
					if m:IsA("Model")
					   and string.find(m.Name, pl.Name, 1, true)
					   and string.find(m.Name, "Knife", 1, true) then
						return true
					end
				end
				return false
			end

			-- ── ping-based extrapolation (source: getRageLookAhead) ───────────────────
			local _ping = 0.06
			local _pingAt = 0
			local function getLeadPos(hrp)
				if not rbExtrapolation then return hrp.Position end
				local now = os.clock()
				if now - _pingAt >= 1 then
					_pingAt = now
					pcall(function() _ping = math.clamp(LP:GetNetworkPing(), 0, 0.5) end)
				end
				local vel = Vector3.zero
				pcall(function() vel = hrp.AssemblyLinearVelocity end)
				if vel.Magnitude < 0.05 then return hrp.Position end
				local speed    = vel.Magnitude
				local lookAhead = (_ping * 1.2 + 0.016) * (1 + math.clamp(speed / 40, 0, 1.6) * 0.4)
				return hrp.Position + vel * math.clamp(lookAhead, 0, 0.5)
			end

			-- ── hitbox resolution (HitboxHead / HitboxBody if present) ───────────────
			local function resolveHitbox(ch, head, body)
				if ch then
					local hb = ch:FindFirstChild(body and "HitboxBody" or "HitboxHead")
					if hb and hb:IsA("BasePart") then return hb end
				end
				return body and head.Parent:FindFirstChild("HumanoidRootPart") or head
			end

			-- ── pellet count (shotguns fire extra times) ─────────────────────────────
			local _pelletItem, _pelletCount = nil, 1
			local function pelletCount(item)
				if item == _pelletItem then return _pelletCount end
				_pelletItem = item; _pelletCount = 1
				pcall(function()
					local n = item.Info and item.Info.ShootPellets
					if type(n) == "number" then _pelletCount = math.max(1, math.floor(n)) end
				end)
				return _pelletCount
			end

			-- ── shot cooldown (from item.Info) ────────────────────────────────────────
			local _cdItem, _cdVal = nil, 0
			local function itemCooldown(item)
				if item == _cdItem then return _cdVal end
				_cdItem = item; _cdVal = 0
				pcall(function()
					local info = item.Info
					if type(info) ~= "table" then return end
					local cd = tonumber(info.ShootCooldown) or 0
					local burst = tonumber(info.BurstCount) or 1
					local bcd   = tonumber(info.BurstCooldown)
					if burst > 1 and bcd then cd = math.min(cd, bcd) end
					_cdVal = math.clamp(cd, 0, 5)
				end)
				return _cdVal
			end

			-- ── void park ────────────────────────────────────────────────────────────
			-- while waiting for the next shot, desync HRP to a random point at VOID_R
			-- studs from world origin — server sees us as unreachable, enemies can't
			-- land shots on our real position.  We come back 2ms before the fire window
			-- so there is no gap in firing.
			local VOID_R    = 9000  -- studs from origin (source: ~8000–10000)
			local rbVoidPark = true  -- toggle
			local _voidBound = false

			local function voidParkCF()
				-- uniform random point on sphere surface
				local u     = math.random()
				local v     = math.random()
				local theta = math.pi * 2 * u
				local phi   = math.acos(math.clamp(2 * v - 1, -1, 1))
				local pos   = Vector3.new(
					VOID_R * math.sin(phi) * math.cos(theta),
					VOID_R * math.cos(phi),
					VOID_R * math.sin(phi) * math.sin(theta)
				)
				return CFrame.lookAt(pos, Vector3.zero)
			end

			local function parkInVoid()
				if not rbVoidPark then return end
				applyDesync(voidParkCF())
			end

			-- ── desync state ──────────────────────────────────────────────────────────
			-- source pattern: physically move HRP to desync CF, bind a RenderStep at
			-- Camera priority - 1 to restore it before the camera tick so there is
			-- zero camera drag (the camera never sees the moved position).
			local _dsRestoreRoot = nil
			local _dsRestoreCF   = nil
			local _dsRestoreVel  = Vector3.zero
			local _dsRestoreRot  = Vector3.zero
			local _dsBound       = false
			local _dsShownCF     = nil

			local function flushDesync()
				-- restore HRP to saved position; does NOT unbind RenderStep
				local root = _dsRestoreRoot
				local cf   = _dsRestoreCF
				_dsRestoreRoot = nil
				_dsRestoreCF   = nil
				_dsShownCF     = nil
				if root and root.Parent and cf then
					pcall(function()
						root.CFrame                  = cf
						root.AssemblyLinearVelocity  = _dsRestoreVel
						root.AssemblyAngularVelocity = _dsRestoreRot
					end)
				end
			end

			-- bind RenderStep once when ragebot starts, unbind once when it stops
			-- never bind/unbind per-frame — that's extremely expensive in Roblox
			local function stopDsRenderStep()
				if _dsBound then
					_dsBound = false
					pcall(function() RunService:UnbindFromRenderStep("__rb_ds_restore") end)
				end
				flushDesync()
			end

			local function startDsRenderStep()
				if not _dsBound then
					_dsBound = true
					local priority = Enum.RenderPriority.Camera.Value - 1
					RunService:BindToRenderStep("__rb_ds_restore", priority, function()
						if _dsRestoreCF then flushDesync() end
					end)
				end
			end

			-- also flush on PreSimulation so physics never runs on the desync position
			pcall(function()
				local pre = (RunService :: any).PreSimulation
				if typeof(pre) == "RBXScriptSignal" then
					bind(pre:Connect(function()
						if _dsRestoreCF then flushDesync() end
					end))
				end
			end)

			local function sameSpot(a, b)
				return a ~= nil and b ~= nil and (a.Position - b.Position).Magnitude < 0.2
			end

			local function applyDesync(desyncCF)
				local myChar = LP.Character
				local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
				if not myRoot or not myRoot:IsA("BasePart") then return false end

				-- only save original CFrame once per desync session
				local keepAnchor = _dsRestoreCF ~= nil
					and sameSpot(myRoot.CFrame, _dsShownCF)
				if not keepAnchor or _dsRestoreRoot ~= myRoot then
					_dsRestoreRoot = myRoot
					_dsRestoreCF   = myRoot.CFrame
					_dsRestoreVel  = myRoot.AssemblyLinearVelocity
					_dsRestoreRot  = myRoot.AssemblyAngularVelocity
				end

				myRoot.CFrame = desyncCF
				_dsShownCF    = desyncCF
				return true
			end


			-- ── target selection ──────────────────────────────────────────────────────
			local _rbPlayers = {}; local _rbPlayersAt = 0
			local function rbTarget()
				local now = os.clock()
				if now - _rbPlayersAt > 0.5 then
					_rbPlayersAt = now
					_rbPlayers = getPlayers()
				end
				local myChar = LP.Character
				local myHRP  = myChar and myChar:FindFirstChild("HumanoidRootPart")
				if not myHRP then return nil, nil, nil end
				local bestPl, bestHRP, bestHead, bestD = nil, nil, nil, math.huge
				for _, ch in ipairs(_rbPlayers) do
					local pl  = Players:GetPlayerFromCharacter(ch)
					if not pl or not isEnemy(pl) then continue end
					if isImmune(pl) then continue end
					local hrp  = ch:FindFirstChild("HumanoidRootPart")
					local head = ch:FindFirstChild("Head")
					local hum  = ch:FindFirstChildOfClass("Humanoid")
					if not hrp or not head or not hum or hum.Health <= 0 then continue end
					if not rbInFov(hrp) then continue end
					local d = (myHRP.Position - hrp.Position).Magnitude
					if d < bestD then
						bestPl, bestHRP, bestHead, bestD = pl, hrp, head, d
					end
				end
				return bestPl, bestHRP, bestHead
			end

			-- ── fire shot (source: fireRageShot pattern) ─────────────────────────────
			--
			-- Key decisions from source:
			--   K0 = encodedCam (camera look, same as aim for our purposes)
			--   K1 = encodedAim (aim CFrame from eye to target)
			--   K2 = targetPart (the BasePart being hit)
			--   K3 = encodedOffset (partCF:ToObjectSpace(hitPoint) — object-space hit loc)
			--
			-- Eye offset (+1.5 Y) keeps origin at eye level, not floor level.
			-- Desync puts HRP at a position near/above the target before the remote fires,
			-- so the server sees the shot originating from that position.
			-- Camera drag fix: desync is restored at Camera priority - 1, before camera
			-- updates, so the camera never snaps to the desync position.
			--
			local lastFire = 0
			local function rbFire(targetPl, targetHRP, targetHead)
				if not _util or not _enum or not _FC or not _remote then return end
				if not _FC.LocalFighter then return end
				local item = _FC.LocalFighter.EquippedItem
				if not item then return end
				local objectId
				pcall(function() objectId = item:Get("ObjectID") end)
				if not objectId then return end

				local ch = targetHRP and targetHRP.Parent
				if not (targetHRP and targetHRP.Parent and targetHead) then return end
				local hum = ch:FindFirstChildOfClass("Humanoid")
				if not hum or hum.Health <= 0 then return end
				if rbKnifeCheck and deflecting[targetPl] then return end

				-- target part: HitboxHead > Head for headshot, HitboxBody > HRP for body
				local targetPart = resolveHitbox(ch, targetHead, not rbHeadshot)

				-- lead position for extrapolation
				local leadPos  = getLeadPos(targetHRP)
				local hitPoint = targetPart.Position  -- actual hit location (object-space)
				local aimPos   = leadPos              -- where we aim (may be ahead of target)

				-- desync: move HRP to position above/behind target so server validates hit
				local knifeHolder = hasKnifeViewModel(targetPl)
				local desyncCF
				if knifeHolder then
					-- knife holder: go below so we avoid their deflect arc
					desyncCF = CFrame.lookAt(
						targetHRP.Position + Vector3.new(0, -5, 0),
						aimPos
					)
				else
					-- standard: step inside/above from their facing direction
					local facing = targetHRP.CFrame.LookVector
					local flat   = Vector3.new(facing.X, 0, facing.Z)
					if flat.Magnitude < 0.05 then flat = Vector3.new(0, 0, -1) end
					desyncCF = CFrame.lookAt(
						targetHRP.Position + flat.Unit * 1 + Vector3.new(0, 1, 0),
						aimPos
					)
				end

				if rbDesync then
					applyDesync(desyncCF)
				end

				-- eye origin: desync position + eye offset
				local eye = desyncCF.Position + EYE_OFFSET
				if (eye - aimPos).Magnitude < 0.1 then
					-- degenerate case: origin and target coincide, nudge slightly
					eye = aimPos + Vector3.new(0, 0.2, 0)
				end

				local aimCF    = CFrame.lookAt(eye, aimPos)
				local partCF   = targetPart.CFrame
				local offset   = partCF:ToObjectSpace(CFrame.new(hitPoint))

				local encodedAim, encodedOffset
				local ok = pcall(function()
					encodedAim    = _util:EncodeCFrame(aimCF)
					encodedOffset = _util:EncodeCFrame(offset)
				end)
				if not ok or not encodedAim then return end

				-- cameradata format (source-accurate):
				--   K0 = camera/aim CFrame (same for our use)
				--   K1 = aim CFrame
				--   K2 = target BasePart
				--   K3 = object-space hit offset
				local cameradata = {
					[K1] = {
						[K0] = encodedAim,
						[K1] = encodedAim,
						[K2] = targetPart,
						[K3] = encodedOffset,
					},
				}
				-- pellet flag for shotguns (source: cameradata[K2] = true)
				if pelletCount(item) > 1 then
					cameradata[K2] = true
				end

				local startEnum
				pcall(function() startEnum = _enum:ToEnum("StartShooting") end)
				if not startEnum then return end

				-- katana proof: TP into target, fire, go back to sky
				if dsKatana then
					_dsFiring = true
					pcall(function()
						local myChar = LP.Character
						if myChar and targetHRP then
							local myHRP = myChar:FindFirstChild("HumanoidRootPart")
							if myHRP then myHRP.CFrame = targetHRP.CFrame end
						end
					end)
				end

				-- desync shot: TP into target before firing (independent of katana)
				if dsShot and not dsKatana then
					pcall(function()
						local myChar = LP.Character
						if myChar and targetHRP then
							local myHRP = myChar:FindFirstChild("HumanoidRootPart")
							if myHRP then myHRP.CFrame = targetHRP.CFrame end
						end
					end)
				end

				pcall(function()
					_remote:FireServer(objectId, startEnum, cameradata, nil)
				end)

				_dsFiring = false
			-- kill sound: track last shot target
			_ksLastTarget = targetPl
			ksWatch(targetPl)
			end

			-- ── heartbeat loop ────────────────────────────────────────────────────────
			-- void park timing:
			--   fire window  = lastFire + rbFireRate
			--   park window  = (lastFire, fireWindow - RETURN_BEFORE)
			--   RETURN_BEFORE = 0.002s (2 ms) — come back just before fire so no gap
			local RETURN_BEFORE = 0.002

			local function startRB()
				if rbHB then rbHB:Disconnect() rbHB = nil end
				startDsRenderStep()  -- bind once; never bind/unbind per-frame
				_rbHoldUntil = tick() + 1  -- suppress on initial enable
				bind(LP.CharacterAdded:Connect(function()
					_rbHoldUntil = tick() + 1  -- 1s hold after each respawn / round start
				end))
				if rbAutoEquip then startEquipLoop() end
				rbHB = RunService.Heartbeat:Connect(function()
					if not rbEnabled then return end
					if tick() < _rbHoldUntil then return end  -- wait 1s after round start / respawn
					updateDeflection()

					-- shotgun fast: cache sg detection; only re-check when EquippedItem changes
					if rbSgFast then
						local item = _FC and _FC.LocalFighter and _FC.LocalFighter.EquippedItem
						if item ~= _sgFastItem then
							_sgFastItem = item
							local info  = item and rawget(item, "Info")
							_sgFastIsSg = type(info) == "table" and (tonumber(info.ShootPellets) or 0) > 1
						end
						if _sgFastIsSg and item then
							rbFireRate = math.max(itemCooldown(item) / 3, 0.0005)
						else
							rbFireRate = rbFireRateBase
						end
					else
						rbFireRate = rbFireRateBase
					end

					local now       = tick()
					local fireAt    = lastFire + rbFireRate
					local remaining = fireAt - now

					-- void park: during cooldown gap, send HRP to the void
					-- stop parking 2ms before the fire window so we're back in time
					if remaining > RETURN_BEFORE then
						-- only park if the equipped weapon has a meaningful cooldown
						-- (pellet weapons / shotguns have ShootCooldown > 0)
						local item = _FC and _FC.LocalFighter and _FC.LocalFighter.EquippedItem
						local cd   = item and itemCooldown(item) or 0
						if cd > 0.05 then
							parkInVoid()
						end
						return
					end

					local tPl, tHRP, tHead = rbTarget()
					if not tPl then return end
					lastFire = tick()
					task.spawn(rbFire, tPl, tHRP, tHead)
				end)
				bind({ Disconnect = function()
					if rbHB then rbHB:Disconnect() rbHB = nil end
					stopDsRenderStep()
				end })
			end

			local function applyRB(v)
				rbEnabled = v
				if v then startRB() else stopDsRenderStep() end
			end

			-- ── UI ────────────────────────────────────────────────────────────────────
			local rb1 = card(cmbt_rb[1], "ragebot")
			rb1.note("FighterController · real HRP desync · Camera priority restore · immunity + team + duel aware")
			rb1.toggle("enabled",            false, function(v) applyRB(v)          end)
			rb1.toggle("desync origin",      true,  function(v) rbDesync       = v  end)
			rb1.toggle("void park (shotgun)",true,  function(v) rbVoidPark     = v  end)
			rb1.toggle("aim head",           true,  function(v) rbHeadshot     = v  end)
			rb1.toggle("extrapolation",      true,  function(v) rbExtrapolation = v end)
			rb1.toggle("knife deflect check",true,  function(v) rbKnifeCheck   = v  end)
			rb1.toggle("auto equip slot",    true,  function(v) rbAutoEquip    = v  end)
			rb1.slider("fire rate (ms)", 1, 500, 1, function(v) rbFireRateBase = v / 1000; rbFireRate = rbFireRateBase end, " ms")
			rb1.toggle("shotgun 3× speed", false, function(v) rbSgFast = v end)
			rb1.slider("fov",            0, 9999, 9999, function(v) rbFovRadius = v end, " px")

			-- slot picker (radio toggles)
			local slotToggles = {}
			local slotNames = {"primary", "secondary", "melee"}
			local slotVals  = {1, 2, 3}
			for i, sn in ipairs(slotNames) do
				local sv = slotVals[i]
				local t = rb1.toggle("slot: " .. sn, sv == 1, function(v)
					if v then
						rbSlot = sv
						for j, ot in ipairs(slotToggles) do
							if j ~= i then pcall(function() ot.set(false, true) end) end
						end
					end
				end)
				slotToggles[i] = t
			end

			rb1.hotkey("hotkey", function(k, mode, pressed)
				if not k then return end
				if mode == "toggle" then
					if pressed then applyRB(not rbEnabled) end
				else
					applyRB(pressed)
				end
			end)


		end
		-- ── END RAGEBOT ──────────────────────────────────────────────────────────────
	end
	-- ══════════════════════════════════════════════════════════════════

	-- ████████████████████████████████████████████████████████████████████
	navHeader("misc")
	local mi = page("misc")
	navHeader("rivals")
	local SPF = page("spoofing", {"identity", "leaderboard", "charms", "currency"})
	local spf_id, spf_lb, spf_ch, spf_cur = SPF.identity, SPF.leaderboard, SPF.charms, SPF.currency
	navHeader("settings")
	local SET = page("settings", {"menu", "configs"})
	local st, cfgp = SET.menu, SET.configs

	-- profile page (opened by clicking your avatar; it has no sidebar icon of its own)
	do
		local PROF = page("profile")
		navButtons.profile.btn.Visible = false
		local MarketplaceService = game:GetService("MarketplaceService")
		local Http = game:GetService("HttpService")

		local function infoRow(holder, key, val, order)
			local r = new("Frame", {Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, LayoutOrder = order}, holder)
			text(r, {Text = key, Size = UDim2.new(0.42, 0, 1, 0), TextColor3 = T.sub, TextSize = 14})
			return text(r, {Text = val, Size = UDim2.new(0.58, 0, 1, 0), Position = UDim2.fromScale(0.42, 0), TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Right, FontFace = F.bold})
		end
		local function header(holder, image, title, sub)
			local r = new("Frame", {Size = UDim2.new(1, 0, 0, 72), BackgroundTransparency = 1, LayoutOrder = 0}, holder)
			local img = new("ImageLabel", {Size = UDim2.fromOffset(64, 64), Position = UDim2.fromOffset(0, 4), BackgroundColor3 = T.row, Image = image}, r)
			corner(img, 14)
			local ist = new("UIStroke", {Color = T.accent, Thickness = 1.5, Transparency = 0.3}, img)
			table.insert(accentHooks, function() ist.Color = T.accent end)
			local t1 = text(r, {Text = title, Size = UDim2.new(1, -78, 0, 24), Position = UDim2.fromOffset(78, 12), FontFace = F.bold, TextSize = 18})
			local t2 = text(r, {Text = sub, Size = UDim2.new(1, -78, 0, 18), Position = UDim2.fromOffset(78, 38), TextColor3 = T.sub, TextSize = 14})
			return img, t1, t2
		end

		-- you
		local you = card(PROF[1], "you")
		local yl = you.list()
		header(yl, "rbxthumb://type=AvatarHeadShot&id=" .. LP.UserId .. "&w=150&h=150", LP.DisplayName, "@" .. LP.Name)
		infoRow(yl, "user id", tostring(LP.UserId), 1)
		infoRow(yl, "account age", LP.AccountAge .. " days", 2)
		infoRow(yl, "membership", LP.MembershipType == Enum.MembershipType.Premium and "premium" or "standard", 3)

		-- place
		local pl = card(PROF[1], "place")
		local pll = pl.list()
		local _, pName, pSub = header(pll, "rbxthumb://type=GameIcon&id=" .. game.GameId .. "&w=150&h=150", "loading...", "")
		infoRow(pll, "place id", tostring(game.PlaceId), 1)
		infoRow(pll, "game id", tostring(game.GameId), 2)
		infoRow(pll, "server", game.JobId ~= "" and (game.JobId:sub(1, 8) .. "...") or "studio", 3)
		local playersLbl = infoRow(pll, "players", "", 4)
		local function updPlayers() if playersLbl.Parent then playersLbl.Text = #Players:GetPlayers() .. " / " .. Players.MaxPlayers end end
		updPlayers()
		bind(Players.PlayerAdded:Connect(updPlayers))
		bind(Players.PlayerRemoving:Connect(function() task.defer(updPlayers) end))
		task.spawn(function()
			local ok, info = pcall(function() return MarketplaceService:GetProductInfo(game.PlaceId) end)
			if ok and type(info) == "table" then
				pName.Text = info.Name or "unknown place"
				pSub.Text = "by " .. ((info.Creator and info.Creator.Name) or "unknown")
			else
				pName.Text = "unknown place"
			end
		end)

		-- join options
		local function servers()
			local ok, body = pcall(function()
				return game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")
			end)
			if not ok or type(body) ~= "string" then return nil end
			local ok2, data = pcall(function() return Http:JSONDecode(body) end)
			if not ok2 or type(data) ~= "table" or type(data.data) ~= "table" then return nil end
			local list = {}
			for _, sv in ipairs(data.data) do
				if sv.id ~= game.JobId and (sv.playing or 0) < (sv.maxPlayers or 0) then table.insert(list, sv) end
			end
			return list
		end
		local function goServer(pick, what)
			UIFX.notify("finding a server...")
			task.spawn(function()
				local list = servers()
				if not list or #list == 0 then UIFX.notify("no other open servers found") return end
				local sv = pick(list)
				UIFX.notify(what .. " (" .. sv.playing .. "/" .. sv.maxPlayers .. " players)")
				pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, sv.id, LP) end)
			end)
		end
		local jo = card(PROF[2], "join options")
		jo.button("rejoin this server", function()
			UIFX.notify("rejoining...")
			pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP) end)
		end)
		jo.button("server hop", function() goServer(function(l) return l[math.random(#l)] end, "joining a new server") end)
		jo.button("join smallest server", function()
			goServer(function(l) table.sort(l, function(a, b) return (a.playing or 0) < (b.playing or 0) end) return l[1] end, "joining smallest server")
		end)
		local pidBox = jo.textbox("place id to join...")
		jo.button("join place", function()
			local id = tonumber((pidBox.Text:gsub("%s", "")))
			if not id then UIFX.notify("enter a valid place id") return end
			UIFX.notify("joining place " .. id)
			pcall(function() TeleportService:Teleport(id, LP) end)
		end)
		local jobBox = jo.textbox("server id to join...")
		jo.button("join server id", function()
			local id = (jobBox.Text:gsub("%s", ""))
			if id == "" then UIFX.notify("enter a server id") return end
			UIFX.notify("joining server...")
			pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, id, LP) end)
		end)

		-- copy
		local function copy(str, what)
			if typeof(setclipboard) == "function" then
				pcall(setclipboard, str)
				UIFX.notify("copied " .. what)
			else
				UIFX.notify("clipboard isn't available")
			end
		end
		local cp = card(PROF[2], "copy")
		cp.button("copy place id", function() copy(tostring(game.PlaceId), "place id") end)
		cp.button("copy server id", function() copy(game.JobId, "server id") end)
		cp.button("copy join script", function()
			copy(('game:GetService("TeleportService"):TeleportToPlaceInstance(%d, "%s", game.Players.LocalPlayer)'):format(game.PlaceId, game.JobId), "join script")
		end)
		cp.button("copy game link", function() copy("https://www.roblox.com/games/" .. game.PlaceId, "game link") end)

		UIFX.openProfile = function() selectPage("profile") end
	end

	-- movement
	local fl = card(mv[1], "flight")
	local flyT = fl.toggle("fly", false, function(v) S.fly = v if v then startFly() else stopFly() end end)
	fl.slider("speed", 10, 300, 60, function(v) S.flySpeed = v end)
	fl.note("wasd · space up · ctrl down")
	local nc = card(mv[2], "collision")
	local noclipT = nc.toggle("noclip", false, function(v)
		S.noclip = v
		if not v and char() then
			for _, n in ipairs({"HumanoidRootPart", "Torso", "UpperTorso", "LowerTorso"}) do local p = char():FindFirstChild(n) if p then p.CanCollide = true end end
		end
	end)
	local ijT = nc.toggle("infinite jump", false, function(v) S.infJump = v end)

	local gpc = card(mv[2], "gamepad mode")
	local gpT = gpc.toggle("gamepad mode", false, function(v) GP.on = v end)
	gpc.slider("start speed", 10, 90, 35, function(v) GP.start = v end, "%")
	gpc.slider("ramp time", 0.1, 2, 0.6, function(v) GP.ramp = v end, " s", 0.1)
	gpc.toggle("apply to fly", true, function(v) GP.fly = v end)
	gpc.note("starts slow, builds to full speed as you hold")

	-- curve graph: pick how the speed builds up and see it live
	do
		local curveBtn, graph
		gpc.toggle("use curve graph", false, function(v)
			GP.useCurve = v
			if curveBtn then curveBtn.Parent.Visible = v end
			if graph then graph.Parent.Visible = v end
		end)
		curveBtn = gpc.button("curve: " .. GP.CURVES[GP.curve][1], function(b)
			GP.curve = GP.curve % #GP.CURVES + 1
			b.Text = "curve: " .. GP.CURVES[GP.curve][1]
		end)
		reg("gamepad mode/curve", function() return GP.curve end, function(v)
			GP.curve = math.clamp(tonumber(v) or 4, 1, #GP.CURVES)
			curveBtn.Text = "curve: " .. GP.CURVES[GP.curve][1]
		end)
		local holder = gpc.list()
		graph = new("Frame", {Size = UDim2.new(1, 0, 0, 96), BackgroundColor3 = T.row, BorderSizePixel = 0, ClipsDescendants = true}, holder)
		corner(graph, 8)
		new("UIStroke", {Color = T.stroke}, graph)
		curveBtn.Parent.Visible, holder.Visible = false, false
		-- grid
		for i = 1, 3 do
			new("Frame", {Size = UDim2.new(1, 0, 0, 1), Position = UDim2.fromScale(0, i / 4), BackgroundColor3 = T.stroke,
				BackgroundTransparency = 0.4, BorderSizePixel = 0}, graph)
			new("Frame", {Size = UDim2.new(0, 1, 1, 0), Position = UDim2.fromScale(i / 4, 0), BackgroundColor3 = T.stroke,
				BackgroundTransparency = 0.4, BorderSizePixel = 0}, graph)
		end
		local axisL = text(graph, {Text = "full", Size = UDim2.fromOffset(40, 12), Position = UDim2.fromOffset(5, 3), TextColor3 = T.sub, TextSize = 10, ZIndex = 3})
		local axisB = text(graph, {Text = "", Size = UDim2.new(0, 60, 0, 12), Position = UDim2.new(1, -65, 1, -15), TextColor3 = T.sub,
			TextSize = 10, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 3})
		local startLbl = text(graph, {Text = "", Size = UDim2.fromOffset(60, 12), TextColor3 = T.sub, TextSize = 10, ZIndex = 3})
		local drawn = {}
		local marker = new("Frame", {Size = UDim2.fromOffset(9, 9), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0, ZIndex = 5}, graph)
		new("UICorner", {CornerRadius = UDim.new(0.5, 0)}, marker)
		local mStroke = new("UIStroke", {Color = LOGO_V2, Thickness = 2}, marker)
		local mLine = new("Frame", {Size = UDim2.new(0, 1, 1, 0), BackgroundColor3 = T.accent, BackgroundTransparency = 0.5, BorderSizePixel = 0, ZIndex = 4}, graph)
		local PAD, N, lastKey = 10, 40, ""
		local function pt(a, gw, gh)
			local s0 = GP.start / 100
			local v = s0 + (1 - s0) * GP.CURVES[GP.curve][2](a)
			return Vector2.new(PAD + a * (gw - PAD * 2), PAD + (1 - v) * (gh - PAD * 2))
		end
		local function redraw(gw, gh)
			for _, f in ipairs(drawn) do f:Destroy() end
			table.clear(drawn)
			local prev = pt(0, gw, gh)
			for i = 1, N do
				local a = i / N
				local p = pt(a, gw, gh)
				local col = T.accent:Lerp(LOGO_V2, a)
				-- soft fill under the curve
				table.insert(drawn, new("Frame", {Size = UDim2.fromOffset(gw / N + 1, gh - p.Y), Position = UDim2.fromOffset(prev.X, p.Y),
					BackgroundColor3 = col, BackgroundTransparency = 0.86, BorderSizePixel = 0, ZIndex = 1}, graph))
				-- the curve line
				local mid, d = (prev + p) / 2, p - prev
				table.insert(drawn, new("Frame", {Size = UDim2.fromOffset(d.Magnitude + 1.5, 2.5), AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromOffset(mid.X, mid.Y), Rotation = math.deg(math.atan2(d.Y, d.X)), BackgroundColor3 = col,
					BorderSizePixel = 0, ZIndex = 2}, graph))
				prev = p
			end
			local sp = pt(0, gw, gh)
			startLbl.Text = "start " .. GP.start .. "%"
			startLbl.Position = UDim2.fromOffset(PAD + 4, math.min(sp.Y - 14, gh - 28))
			axisB.Text = string.format("%.1f s", GP.ramp)
		end
		bind(RunService.Heartbeat:Connect(function()
			if not (holder.Visible and graph.Parent) then return end
			local sc = mainScale.Scale > 0 and mainScale.Scale or 1
			local gw, gh = graph.AbsoluteSize.X / sc, graph.AbsoluteSize.Y / sc
			if gw < 10 then return end
			local key = table.concat({GP.curve, GP.start, GP.ramp, math.floor(gw), math.floor(gh), T.accent.R}, "|")
			if key ~= lastKey then lastKey = key redraw(gw, gh) end
			-- live dot: where you are on the curve right now
			local a = GP.on and math.clamp(GP.held / GP.ramp, 0, 1) or 0
			local p = pt(a, gw, gh)
			marker.Position = UDim2.fromOffset(p.X, p.Y)
			mLine.Position = UDim2.fromOffset(p.X, 0)
			mStroke.Color = LOGO_V2
			marker.BackgroundTransparency = GP.on and 0 or 0.5
		end))
	end

	-- character
	local hu = card(ch[1], "humanoid")
	local wsS = hu.slider("walkspeed", 16, 250, 16, function(v) S.walk = v end)
	local jpS = hu.slider("jumppower", 50, 300, 50, function(v) S.jump = v end)
	hu.toggle("lock values", true, function(v) S.lock = v end)
	hu.button("reset to default", function() wsS.set(16) jpS.set(50) end)

	local dsc = card(ch[2], "desync visual")
	local dsT = dsc.toggle("desync visual", false, function(v) DS.on = v if v then buildGhost() else destroyGhost() end end)
	dsc.slider("delay", 0, 500, 150, function(v) DS.delay = v end, " ms", 10)
	dsc.slider("offset", 0, 5, 2, function(v) DS.offset = v end, " st", 0.5)
	dsc.slider("jitter rate", 1, 30, 12, function(v) DS.rate = v end, " hz")
	dsc.slider("opacity", 10, 100, 55, function(v) DS.opacity = v applyGhostLook() end, "%")
	dsc.toggle("glitch flicker", true, function(v) DS.flicker = v end)
	dsc.colorwheel("ghost color", DS.color, function(c) DS.color = c applyGhostLook() end)
	dsc.note("cosmetic only · only you can see it")

	-- visuals
	local li = card(vs[1], "lighting")
	local fbT = li.toggle("fullbright", false, function(v) S.fullbright = v restoreLight() end)
	li.slider("brightness", 0, 10, 2, function(v) S.brightness = v end, nil, 0.5)
	li.note("brightness applies while fullbright is on")

	local wc = card(vs[1], "world color")
	local wcT = wc.toggle("world tint", false, function(v) S.worldTint = v end)
	wc.slider("strength", 0, 100, 60, function(v) S.tintStrength = v end, "%")
	local wcWheel = wc.colorwheel("tint color", S.tintColor, function(c) S.tintColor = c end)
	wc.swatches("presets", {Color3.fromRGB(255, 170, 120), Color3.fromRGB(120, 180, 255), Color3.fromRGB(255, 120, 200), Color3.fromRGB(140, 255, 160), Color3.fromRGB(200, 150, 255)}, function(c) wcWheel.set(c) end)
	local satS = wc.slider("saturation", -100, 100, 0, function(v) S.saturation = v end, "%")
	local conS = wc.slider("contrast", -100, 100, 0, function(v) S.contrast = v end, "%")

	local fg = card(vs[2], "fog")
	local nfT, cfT
	nfT = fg.toggle("no fog", false, function(v) S.noFog = v if v and cfT then cfT.set(false, true) S.customFog = false end restoreLight() end)
	cfT = fg.toggle("custom fog", false, function(v) S.customFog = v if v then nfT.set(false, true) S.noFog = false end restoreLight() end)
	fg.slider("fog start", 0, 1000, 0, function(v) S.fogStart = v end, " st", 10)
	fg.slider("fog end", 20, 5000, 500, function(v) S.fogEnd = v end, " st", 10)
	local fogWheel = fg.colorwheel("fog color", S.fogColor, function(c) S.fogColor = c end)
	local auraToggles = {}
	local function auraCard(col, title, cfg)
		local ac = card(col, title)
		table.insert(auraToggles, ac.toggle(title, false, function(v) cfg.on = v end))
		local wheel = ac.colorwheel("aura color", cfg.color, function(c) cfg.color = c end)
		ac.swatches("presets", {Color3.fromRGB(168, 85, 247), Color3.fromRGB(217, 54, 162), Color3.fromRGB(56, 189, 248),
			Color3.fromRGB(52, 211, 153), Color3.fromRGB(255, 255, 255)}, function(c) wheel.set(c) end)
		ac.slider("fill", 0, 100, cfg.fill, function(v) cfg.fill = v end, "%")
		ac.toggle("outline", cfg.outline, function(v) cfg.outline = v end)
		ac.toggle("pulse", cfg.pulse, function(v) cfg.pulse = v end)
		ac.toggle("particles", cfg.particles, function(v) cfg.particles = v end)
		ac.toggle("rainbow", cfg.rainbow, function(v) cfg.rainbow = v end)
		ac.toggle("halo", cfg.halo, function(v) cfg.halo = v end)
		ac.slider("halo size", 0.5, 2.5, cfg.haloSize, function(v) cfg.haloSize = v end, "x", 0.1)
		ac.slider("halo height", 0, 3, cfg.haloHeight, function(v) cfg.haloHeight = v end, " st", 0.1)
		ac.toggle("halo spin", cfg.haloSpin, function(v) cfg.haloSpin = v end)
		ac.note(cfg == AURA.self and "only you can see it" or "only you see these · hidden behind walls")
	end
	auraCard(au[1], "player auras", AURA.others)
	auraCard(au[2], "self aura", AURA.self)

	-- effects
	local cam = card(ef[1], "camera")
	local fovT = cam.toggle("custom fov", false, function(v) FX.fovOn = v if not v then Camera.FieldOfView = fov0 end end)
	cam.slider("field of view", 30, 120, 70, function(v) FX.fov = v end, "°")
	local timeT = cam.toggle("lock time of day", false, function(v) FX.timeOn = v if not v then restoreLight() end end)
	cam.slider("time", 0, 24, 14, function(v) FX.time = v end, " h", 0.5)
	cam.slider("stretch", 1, 10, 1, function(v) FX.stretch = v end, "x", 0.5)

	local pfx = card(ef[1], "post fx")
	local bloomT = pfx.toggle("bloom", false, function(v) FX.bloom = v end)
	pfx.slider("bloom intensity", 0, 3, 1, function(v) FX.bloomI = v end, nil, 0.1)
	pfx.slider("bloom size", 2, 56, 24, function(v) FX.bloomS = v end)
	pfx.slider("bloom threshold", 0, 2, 1, function(v) FX.bloomT = v end, nil, 0.1)
	local raysT = pfx.toggle("sun rays", false, function(v) FX.rays = v end)
	pfx.slider("ray intensity", 0, 1, 0.15, function(v) FX.raysI = v end, nil, 0.05)
	pfx.slider("ray spread", 0, 1, 0.2, function(v) FX.raysS = v end, nil, 0.05)
	local dofT = pfx.toggle("depth of field", false, function(v) FX.dof = v end)
	pfx.slider("focus distance", 0, 200, 30, function(v) FX.dofFocus = v end, " st")
	pfx.slider("focus radius", 0, 100, 20, function(v) FX.dofRadius = v end, " st")
	pfx.slider("background blur", 0, 100, 50, function(v) FX.dofBlur = v end, "%")


	local wth = card(ef[2], "weather")
	local weatherT = wth.toggle("weather", false, function(v) FX.weather = v if v then buildWeather() else removeWeather() end end)
	wth.button("type: snow", function(b)
		FX.wType = FX.wType % #WEATHER + 1
		b.Text = "type: " .. WEATHER[FX.wType].name
		if FX.weather then buildWeather() end
	end)
	wth.slider("density", 5, 200, 60, function(v) FX.wDensity = v end)
	wth.note("snow · fireflies · embers · stardust")

	local ksc = card(ef[2], "kill sounds")
	ksc.toggle("enabled", false, function(v) ksEnabled = v end)
	ksc.slider("volume", 0.0, 2.0, 0.8, function(v) ksVolume = v end, nil, 0.05)
	ksc.slider("pitch",  0.5, 2.0, 1.0, function(v) ksPitch  = v end, nil, 0.05)
	-- sound picker buttons
	local ksBtns = {}
	for i, s in ipairs(KS_SOUNDS) do
		local b = ksc.button(s.n, function(btn)
			ksSoundIdx = i
			for j, ob in ipairs(ksBtns) do
				pcall(function()
					ob.BackgroundColor3 = j == i and T.accent or T.row
				end)
			end
		end)
		table.insert(ksBtns, b)
	end
	ksc.note("plays when your last shot target dies")

	-- misc
	-- visuals → world: skyboxes
	do
		local W = VIS.world
		local SKY = XFX.sky
		local sk = card(W[1], "skybox")
		local status
		local function pick(i)
			SKY.apply(i)
			status.Text = "current: " .. SKY.PRESETS[i].name
		end
		for i, p in ipairs(SKY.PRESETS) do
			sk.button(p.name, function() pick(i) UIFX.notify("skybox  ·  " .. p.name) end)
		end
		status = sk.note("current: original")
		reg("skybox/preset", function() return SKY.preset end, function(v)
			v = tonumber(v) or 1
			if v >= 1 then pick(v) end
		end)

		local so = card(W[2], "sky options")
		so.slider("star count", 0, 10000, 3000, function(v) SKY.stars = v end, nil, 250)
		so.toggle("sun & moon", true, function(v) SKY.bodies = v end)
		so.note("presets set these too; adjust after")
		local idBox = so.textbox("skybox asset id...")
		so.button("load skybox from id", function()
			local id = tonumber((idBox.Text:gsub("%D", "")))
			if not id then UIFX.notify("enter a skybox asset id") return end
			if SKY.loadAsset(id) then
				status.Text = "current: asset " .. id
				UIFX.notify("loaded skybox " .. id)
			else
				UIFX.notify("couldn't load a skybox from " .. id)
			end
		end)
		so.note("works with sky assets from the catalog")
	end


	-- self fx
	do
		local sfx = VIS.fx
		local skc = card(sfx[1], "self skin")
		table.insert(XFX.toggles, skc.toggle("skin", false, function(v) XFX.skin = v end))
		skc.button("material: forcefield", function(b)
			XFX.mat = XFX.mat % #XFX.MATS + 1
			b.Text = "material: " .. XFX.MATS[XFX.mat][1]
		end)
		skc.toggle("rainbow", true, function(v) XFX.skinRainbow = v end)
		skc.colorwheel("skin color", XFX.skinColor, function(c) XFX.skinColor = c end)
		skc.note("color is used when rainbow is off")

		local scr = card(sfx[1], "screen")
		table.insert(XFX.toggles, scr.toggle("vignette", false, function(v) XFX.vignette = v end))
		scr.slider("vignette strength", 0, 100, 55, function(v) XFX.vigStrength = v end, "%")
		scr.colorwheel("vignette color", XFX.vigColor, function(c) XFX.vigColor = c end)
		table.insert(XFX.toggles, scr.toggle("cinematic bars", false, function(v) XFX.bars = v end))
		scr.slider("bar size", 2, 20, 10, function(v) XFX.barSize = v end, "%")
		table.insert(XFX.toggles, scr.toggle("speed blur", false, function(v) XFX.speedBlur = v end))
		scr.slider("max blur", 2, 24, 10, function(v) XFX.blurMax = v end)



		local cx = card(sfx[1], "crosshair")
		local C = XFX.cross
		table.insert(XFX.toggles, cx.toggle("crosshair", false, function(v) C.on = v end))
		cx.slider("arms", 2, 8, 4, function(v) C.arms = v end)
		cx.slider("arm length", 2, 40, 10, function(v) C.length = v end, " px")
		cx.slider("thickness", 1, 6, 2, function(v) C.thick = v end, " px", 0.5)
		cx.slider("center gap", 0, 30, 6, function(v) C.gap = v end, " px")
		cx.slider("spin speed", -360, 360, 90, function(v) C.spin = v end, "°/s", 10)
		cx.slider("opacity", 10, 100, 90, function(v) C.opacity = v end, "%")
		cx.toggle("center dot", true, function(v) C.dot = v end)
		cx.toggle("outline", true, function(v) C.outline = v end)
		cx.toggle("expand on click", true, function(v) C.dynamic = v end)
		cx.toggle("rainbow", false, function(v) C.rainbow = v end)
		cx.colorButton("crosshair color", C.color, function(c) C.color = c end)
		local textBox = cx.textbox("text under crosshair...", function(t) C.text = t:sub(1, 40) end)
		reg("crosshair/text", function() return C.text end, function(v) C.text = tostring(v or ""):sub(1, 40) textBox.Text = C.text end)
		cx.slider("text size", 8, 32, 14, function(v) C.textSize = v end, " px")
		cx.slider("text distance", 0, 60, 10, function(v) C.textDist = v end, " px")
		cx.toggle("text spins with crosshair", false, function(v) C.textSpin = v end)

		-- ── cursor ring ───────────────────────────────────────────────────
		do
			local CR = {
				on     = false,
				size   = 90,
				thick  = 2,
				fill   = 0.94,   -- BackgroundTransparency (0=opaque, 1=invisible)
				glow   = 0.7,    -- halo opacity fraction
				color  = Color3.fromRGB(168, 85, 247),
				breathe= 4,      -- % size breathe
				spin   = 60,     -- deg/s gradient rotation
			}

			-- holder frame that moves with the mouse
			local crHolder = new("Frame", {
				Size = UDim2.fromOffset(CR.size * 2, CR.size * 2),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromOffset(0, 0),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ZIndex = 1,
				Visible = false,
			}, gui)

			local WHITE = Color3.new(1,1,1)

			-- inner glow: soft bloom fill inside the ring
			-- two concentric circles faking a radial gradient: outer edge bright, center fades
			local crGlowOuter = new("Frame", {
				Size = UDim2.fromScale(1, 1),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				BackgroundColor3 = CR.color,
				BackgroundTransparency = 0.72,
				BorderSizePixel = 0, ZIndex = 1,
			}, crHolder)
			new("UICorner", {CornerRadius = UDim.new(0.5, 0)}, crGlowOuter)
			local crGlowInner = new("Frame", {
				Size = UDim2.fromScale(0.65, 0.65),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				BackgroundColor3 = CR.color,
				BackgroundTransparency = 0.88,
				BorderSizePixel = 0, ZIndex = 1,
			}, crHolder)
			new("UICorner", {CornerRadius = UDim.new(0.5, 0)}, crGlowInner)

			-- main circle fill (very subtle tint)
			local crFill = new("Frame", {
				Size = UDim2.fromScale(1, 1),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				BackgroundColor3 = CR.color,
				BackgroundTransparency = CR.fill,
				BorderSizePixel = 0,
				ZIndex = 2,
			}, crHolder)
			new("UICorner", {CornerRadius = UDim.new(0.5, 0)}, crFill)

			-- stroke ring
			local crStroke = new("UIStroke", {
				Color = CR.color,
				Thickness = CR.thick,
				Transparency = 0.05,
			}, crFill)
			-- gradient on the stroke: white shimmer sweeps around the ring as Rotation spins
			local crGrad = new("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0,    WHITE),
					ColorSequenceKeypoint.new(0.18, CR.color),
					ColorSequenceKeypoint.new(0.5,  WHITE),
					ColorSequenceKeypoint.new(0.82, CR.color),
					ColorSequenceKeypoint.new(1,    WHITE),
				}),
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0,    0),
					NumberSequenceKeypoint.new(0.18, 0.55),
					NumberSequenceKeypoint.new(0.5,  0),
					NumberSequenceKeypoint.new(0.82, 0.55),
					NumberSequenceKeypoint.new(1,    0),
				}),
				Rotation = 0,
			}, crStroke)

			-- glow halo
			local crHalo = new("Frame", {
				Size = UDim2.new(1, 14, 1, 14),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ZIndex = 1,
			}, crHolder)
			new("UICorner", {CornerRadius = UDim.new(0.5, 0)}, crHalo)
			local crHaloStroke = new("UIStroke", {
				Color = CR.color,
				Thickness = 6,
				Transparency = 1 - CR.glow * 0.3,
			}, crHalo)

			bind({ Disconnect = function() crHolder:Destroy() end })

			bind(RunService.RenderStepped:Connect(function()
				crHolder.Visible = CR.on
				if not CR.on then return end
				local t  = os.clock()
				local mp = UIS:GetMouseLocation()
				local r  = CR.size * (1 + CR.breathe / 100 * math.sin(t * 1.6))
				local d  = r * 2
				crHolder.Size     = UDim2.fromOffset(d, d)
				crHolder.Position = UDim2.fromOffset(mp.X, mp.Y)
				local pulse = (math.sin(t * 2.2) + 1) / 2
				-- inner glow breathes with pulse
				local glowBase = 0.72 - CR.glow * 0.28
				crGlowOuter.BackgroundColor3        = CR.color
				crGlowOuter.BackgroundTransparency  = glowBase + pulse * 0.08
				crGlowInner.BackgroundColor3        = CR.color
				crGlowInner.BackgroundTransparency  = math.min(0.97, glowBase + 0.16 + pulse * 0.06)
				crFill.BackgroundColor3       = CR.color
				crFill.BackgroundTransparency = CR.fill
				crStroke.Color     = CR.color
				crStroke.Thickness = CR.thick
				crStroke.Transparency = 0.05
				crGrad.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0,    WHITE),
					ColorSequenceKeypoint.new(0.18, CR.color),
					ColorSequenceKeypoint.new(0.5,  WHITE),
					ColorSequenceKeypoint.new(0.82, CR.color),
					ColorSequenceKeypoint.new(1,    WHITE),
				})
				crGrad.Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0,    0),
					NumberSequenceKeypoint.new(0.18, 0.55),
					NumberSequenceKeypoint.new(0.5,  0),
					NumberSequenceKeypoint.new(0.82, 0.55),
					NumberSequenceKeypoint.new(1,    0),
				})
				crGrad.Rotation = (t * CR.spin * 1.5) % 360
				crHaloStroke.Color = CR.color
				crHaloStroke.Transparency = 1 - CR.glow * (0.25 + pulse * 0.1)
			end))

			local crc = card(sfx[2], "cursor ring")
			table.insert(XFX.toggles, crc.toggle("cursor ring", false, function(v) CR.on = v end))
			crc.slider("size",      20, 400,  90, function(v) CR.size   = v end, " px", 5)
			crc.slider("thickness",  1,   8,   2, function(v) CR.thick  = v end, " px", 0.5)
			crc.slider("fill",       0, 100,   6, function(v) CR.fill   = 1 - v / 100 end, "%")
			crc.slider("glow",       0, 100,  70, function(v) CR.glow   = v / 100 end, "%")
			crc.slider("breathe",    0,  25,   4, function(v) CR.breathe= v end, "%")
			crc.slider("spin speed", -360, 360, 60, function(v) CR.spin = v end, "°/s", 10)
			crc.colorwheel("color", CR.color, function(v) CR.color = v end)
		end
	end


	-- ══════════════════════════════════════════════════════════════════
	-- RIVALS SPOOFER + SKINCHANGER  (rivals only — all pcall-guarded)
	-- ══════════════════════════════════════════════════════════════════
	do
		local _RS  = game:GetService("ReplicatedStorage")
		local _PS2 = game:GetService("Players")
		local _MkS = game:GetService("MarketplaceService")
		local _GS2 = game:GetService("GuiService")
		local _RF  = game:GetService("ReplicatedFirst")
		local _SC2 = game:GetService("ScriptContext")
		local _CG  = game:GetService("CoreGui")
		local _SS  = game:GetService("SoundService")

		-- rivals module cache (nil outside rivals)
		-- loaded async so buildUI() doesn't block waiting for rivals to init
		-- NOTE: mods/modsReady declared at buildUI() top; hoisted for combat tab access
		task.spawn(function()
			pcall(function()
				local PS = LP:WaitForChild("PlayerScripts", 15)
				local Controllers = PS and PS:FindFirstChild("Controllers")
				local RSMods = _RS:FindFirstChild("Modules")
				-- wait until controllers folder is populated
				if Controllers then
					for _ = 1, 60 do
						if Controllers:FindFirstChild("PlayerDataController") then break end
						task.wait(0.25)
					end
					pcall(function() mods.PlayerDataController   = require(Controllers:FindFirstChild("PlayerDataController"))   end)
					pcall(function() mods.LeaderboardController  = require(Controllers:FindFirstChild("LeaderboardController"))  end)
					pcall(function() mods.ControlsController     = require(Controllers:FindFirstChild("ControlsController"))     end)
					pcall(function() mods.MonetizationController = require(Controllers:FindFirstChild("MonetizationController")) end)
					pcall(function() mods.FighterController      = require(Controllers:FindFirstChild("FighterController"))      end)
					pcall(function() mods.WrapController         = require(Controllers:FindFirstChild("WrapController"))         end)
				end
				if RSMods then
					pcall(function() mods.SeasonLibrary       = require(RSMods:FindFirstChild("SeasonLibrary"))       end)
					pcall(function() mods.MonetizationLibrary = require(RSMods:FindFirstChild("MonetizationLibrary")) end)
					pcall(function() mods.CosmeticLibrary     = require(RSMods:FindFirstChild("CosmeticLibrary"))     end)
					pcall(function() mods.ShopLibrary         = require(RSMods:FindFirstChild("ShopLibrary"))         end)
					pcall(function() mods.ItemLibrary         = require(RSMods:FindFirstChild("ItemLibrary"))         end)
					pcall(function() mods.EnumLibrary         = require(RSMods:FindFirstChild("EnumLibrary"))         end)
				end
				pcall(function()
					if mods.PlayerDataController and mods.PlayerDataController.WaitUntilLoaded then
						mods.PlayerDataController:WaitUntilLoaded()
					end
				end)
			end)
			modsReady = true
		end)

		local function SafeGet(key, fallback)
			local ok, v = pcall(function()
				return mods.PlayerDataController and mods.PlayerDataController:Get(key)
			end)
			return (ok and v ~= nil) and v or fallback
		end

		-- ── spoofer state ─────────────────────────────────────────────
		local SS = {
			device = "Desktop",
			old_device = tostring(mods.ControlsController and mods.ControlsController.CurrentControls or "Desktop"),
			spoof_device = false, device_spam = false, spam_rate = 1,

			display_name_value = LP.DisplayName, username_value = LP.Name,
			display_name = false, username = false, name_spoof_conn = {},

			avatar_userid = LP.UserId, spoof_avatar = false, thumb_spoof_conn = {},

			anonymous_mode = false, fake_names = {}, anon_connections = {},

			leaderboard = {
				elo_value    = 0,
				streak_value = LP:GetAttribute("StatisticDuelsWinStreak") or 0,
				kills_value  = 0, wins_value = 0,
				level_value  = LP:GetAttribute("Level") or 0,
				old_streak_value = LP:GetAttribute("StatisticDuelsWinStreak"),
				old_level_value  = LP:GetAttribute("Level"),
				ELO = false, Streak = false, Kills = false, Wins = false, Level = false,
			},

			badges = {Premium = false, Verified = false, Influencer = false, Admin = false},

			charm = {
				charm_rank = "Use Spoofed ELO", arch_rank = 1,
				s0_charm = false, s1_charm = false, s2_charm = false, s3_charm = false,
			},

			currency = {
				weapon_keys = false, unlock_tokens = false, event_currency = false,
				glory = false, skin_tickets = false,
				weapon_keys_value    = SafeGet("WeaponKeys",    0),
				unlock_tokens_value  = SafeGet("UnlockTokens",  0),
				event_currency_value = SafeGet("EventCurrency", 0),
				glory_value          = SafeGet("Glory",         0),
				skin_tickets_value   = SafeGet("SkinTickets",   0),
			},

			duel_history = {
				duel_history_value  = SafeGet("DuelHistory",     {}),
				logged_elo_events   = SafeGet("LoggedELOEvents", {}),
				match_index = 1, mode = "Ranked", result = "Victory", map = "Factory",
				team1score = 5, team2score = 0, dueler_index = 1,
				username = "", display_name = "",
				kills = 15, deaths = 2, assists = 6, damage = 5000, elo = 2000, elo_change = 35,
			},

			marketplace = {
				fake_bundles_owned        = SafeGet("GamepassBundlesClaimed",       {}),
				fake_gift_robux_spent     = SafeGet("GiftRobuxSpentProgress",       0),
				fake_gift_rewards_claimed = SafeGet("GiftRobuxSpentRewardsClaimed", {}),
				fake_robux = false, robux_amount = 0, fake_gifting = false,
			},
		}

		-- ── skinchanger state (Harion) ────────────────────────────────
		local equip, favs = {}, {}  -- equip[wepName][cosType]=cosData, favs[wepName][cosName]=bool
		-- Forward-declare functions used by the config callback below. Without these
		-- declarations, the callback can resolve them as globals and silently fail.
		local applyCosmeticToWeapon, rebuildinv, saferep
		-- config: save/load equip table (skin names only — cosmetic data re-resolved on load)
		reg("skins/equip", function()
			local out = {}
			for wname, wtbl in pairs(equip) do
				if type(wtbl) == "table" then
					local row = {}
					for ctype, cdata_ in pairs(wtbl) do
						if type(cdata_) == "table" and cdata_.Name then
							row[ctype] = cdata_.Name
						end
					end
					if next(row) then out[wname] = row end
				end
			end
			return game:GetService("HttpService"):JSONEncode(out)
		end, function(v)
			-- decode + re-apply; modules may not be ready yet so defer
			task.spawn(function()
				local ok, data = pcall(function()
					return game:GetService("HttpService"):JSONDecode(tostring(v or "{}"))
				end)
				if not ok or type(data) ~= "table" then return end
				-- wait for modules
				for _ = 1, 200 do if modsReady then break end task.wait(0.1) end
				for wname, ctypes in pairs(data) do
					if type(ctypes) == "table" then
						for ctype, cosName in pairs(ctypes) do
							pcall(applyCosmeticToWeapon, wname, cosName, ctype)
						end
					end
				end
				rebuildinv()
				task.defer(function() saferep("CosmeticInventory") end)
				task.defer(function() saferep("WeaponInventory") end)
				if skRefreshRef then skRefreshRef() end
			end)
		end)
		local finv = {}             -- flat inventory: finv[cosName]=cosData
		local fcache = {}           -- finisher cache: fcache[wepName]=cosName
		local cwep = nil            -- weapon being constructed (CreateViewModel context)

		local coss = mods.CosmeticLibrary and mods.CosmeticLibrary.Cosmetics or {}
		local ilib = mods.ItemLibrary
		local elib = mods.EnumLibrary
		local dctrl = mods.PlayerDataController
		local cdata = dctrl and dctrl.CurrentData or nil
		local fctrl = mods.FighterController
		local wrapCtrl = mods.WrapController

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
			d.Owned = true; d.Unlocked = true; d.Locked = false
			d.Amount = math.max(1, tonumber(d.Amount) or 1)
			d.Count  = math.max(1, tonumber(d.Count)  or 1)
			local eid = toenum(name)
			if eid then d.Enum = eid; d.ObjectID = d.ObjectID or eid end
			if inv     ~= nil then d.Inverted         = inv     end
			if favonly ~= nil then d.OnlyUseFavorites = favonly end
			return d
		end

		rebuildinv = function()
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

		saferep = function(key)
			pcall(function()
				if not cdata and dctrl and dctrl.CurrentData then cdata = dctrl.CurrentData end
				if cdata then cdata:Replicate(key) end
			end)
		end

		-- legacy compat (weapon unlock helpers reference these)
		local SK = {
			fake_weapon_owned = SafeGet("WeaponInventory", {}),
			fake_weapon_names = {},
		}

		-- ── constants ─────────────────────────────────────────────────
		local kCharmEloMap = {
			["Unranked"]=-1,["Bronze 1"]=0,["Bronze 2"]=200,["Bronze 3"]=400,
			["Silver 1"]=600,["Silver 2"]=800,["Silver 3"]=1000,
			["Gold 1"]=1200,["Gold 2"]=1400,["Gold 3"]=1600,
			["Platinum 1"]=1800,["Platinum 2"]=2000,["Platinum 3"]=2200,
			["Diamond 1"]=2400,["Diamond 2"]=2600,["Diamond 3"]=2800,
			["Onyx 1"]=3000,["Onyx 2"]=3200,["Onyx 3"]=3400,
			["Nemesis"]=3600,["Archnemesis"]=3600,
		}
		local kSeasonNameMap = {[0]="Zero",[1]="Warp",[2]="Polar",[3]="Fame",Zero=0,Warp=1,Polar=2,Fame=3}
		local kSeasonToggleMap = {[0]="s0_charm",[1]="s1_charm",[2]="s2_charm",[3]="s3_charm"}
		local kWordList = {
			"late","couple","economic","obscure","landscape","spot","college","rainbow","leg","mixture",
			"frank","commitment","draft","motivation","fuss","settle","jelly","confine","pin","modernize",
			"velvet","quarter","physical","differ","dish","aisle","happen","council","appeal","depart",
			"urgency","vessel",
		}
		local kCosmeticTypes   = {"Skin","Wrap","Charm","Finisher"}
		local kCosmeticRarities = {"Common","Rare","Legendary","Mythical","Unique","Unobtainable"}

		-- ── PlayerDataController.Get patch ────────────────────────────
		local oget = nil
		pcall(function()
			if not mods.PlayerDataController then return end
			oget = mods.PlayerDataController.Get
			mods.PlayerDataController.Get = function(self, key, ...)
				local ok, data = pcall(oget, self, key, ...)
				if not ok then data = nil end
				local s = SS
				if key == "WeaponKeys"      and s.currency.weapon_keys      then return s.currency.weapon_keys_value    end
				if key == "UnlockTokens"    and s.currency.unlock_tokens     then return s.currency.unlock_tokens_value  end
				if key == "EventCurrency"   and s.currency.event_currency    then return s.currency.event_currency_value end
				if key == "Glory"           and s.currency.glory             then return s.currency.glory_value          end
				if key == "SkinTickets"     and s.currency.skin_tickets      then return s.currency.skin_tickets_value   end
				if key == "DuelHistory"            then return s.duel_history.duel_history_value  or data end
				if key == "LoggedELOEvents"        then return s.duel_history.logged_elo_events   or data end
				if key == "GamepassBundlesClaimed" then return s.marketplace.fake_bundles_owned   or data end
				if key == "GiftRobuxSpentProgress" then return s.marketplace.fake_gift_robux_spent       end
				if key == "GiftRobuxSpentRewardsClaimed" then return s.marketplace.fake_gift_rewards_claimed end
				-- CosmeticInventory: merge real inventory with equipped cosmetics (Harion approach)
				if key == "CosmeticInventory" then
					local proxy = {}
					if data then for k, v in data do if not banned(k) then proxy[k] = v end end end
					for name, cd in finv do
						if proxy[name] == nil or type(proxy[name]) == "boolean" then proxy[name] = cd end
					end
					return proxy
				end
				-- FavoritedCosmetics: merge real favorites with spoofed
				if key == "FavoritedCosmetics" then
					local res = data and table.clone(data) or {}
					for wep, fv in favs do
						local slot = res[wep] or {}; res[wep] = slot
						for name, isfav in fv do
							if not banned(name) then slot[name] = isfav end
						end
					end
					return res
				end
				if key == "WeaponInventory" or key == "FreeWeaponUnlockCheck" then
					return (#SK.fake_weapon_owned > 0) and SK.fake_weapon_owned or data
				end
				if key == "UnclaimedRewards" then return data end
				return data
			end
		end)

		-- ── CosmeticLibrary ownership patch ───────────────────────────
		pcall(function()
			if not mods.CosmeticLibrary then return end
			local cos = mods.CosmeticLibrary
			local function WrapOwnership(old, expected_args)
				return function(...)
					local args = {...}
					local name = args[expected_args]
					if type(name) == "string" and finv[name] then return true end
					if old then return old(...) end
					return false
				end
			end
			cos.OwnsCosmeticNormally     = WrapOwnership(cos.OwnsCosmeticNormally,     3)
			cos.OwnsCosmeticUniversally  = WrapOwnership(cos.OwnsCosmeticUniversally,  3)
			cos.OwnsCosmeticForSomething = WrapOwnership(cos.OwnsCosmeticForSomething, 3)
			cos.OwnsCosmeticForWeapon    = WrapOwnership(cos.OwnsCosmeticForWeapon,    3)
			local orig_owns = cos.OwnsCosmetic
			cos.OwnsCosmetic = function(self, inventory, name, weapon)
				if type(name) == "string" and finv[name] then return true end
				if orig_owns then return orig_owns(self, inventory, name, weapon) end
				return false
			end
		end)

		-- ── WeaponData patch ──────────────────────────────────────────
		pcall(function()
			if not mods.PlayerDataController then return end
			local pdc = mods.PlayerDataController
			if pdc.HasGamepass then
				local orig = pdc.HasGamepass
				pdc.HasGamepass = function(self, ...)
					local has = orig and orig(self, ...)
					local name = ({...})[1]
					return type(name) == "string" and SS.marketplace.fake_bundles_owned[name] or has
				end
			end
		end)
		-- ── GetWeaponData patch (Harion — direct merge of equip table) ──
		pcall(function()
			if not mods.PlayerDataController then return end
			local ogetwep = mods.PlayerDataController.GetWeaponData
			if not ogetwep then return end
			mods.PlayerDataController.GetWeaponData = function(self, wname)
				local data = ogetwep(self, wname)
				if not data then return nil end
				local merged = table.clone(data)
				merged.Name = wname
				local weq = equip[wname]
				if weq then for ct, cd in weq do merged[ct] = cd end end
				return merged
			end
		end)

		-- ── badge __index hook ────────────────────────────────────────
		pcall(function()
			local old_bi
			old_bi = hookmetamethod(game, "__index", function(self, key)
				if self == LP then
					if key == "MembershipType" and SS.badges.Premium then return Enum.MembershipType.Premium end
					if key == "HasVerifiedBadge" and SS.badges.Verified then return true end
				end
				return old_bi(self, key)
			end)
		end)

		-- ── NamecallDispatcher (shared) ───────────────────────────────
		local NCD = {Hooks = {}, Original = nil}
		function NCD:Register(cb)   self.Hooks[#self.Hooks+1] = cb return #self.Hooks end
		function NCD:Unregister(i)  table.remove(self.Hooks, i) end
		function NCD:Clear()        table.clear(self.Hooks) end
		function NCD:CallOriginal(obj, ...) if self.Original then return self.Original(obj, ...) end end
		pcall(function()
			NCD.Original = hookmetamethod(game, "__namecall", newcclosure(function(obj, ...)
				local hooks = NCD.Hooks
				if #hooks == 0 then return NCD.Original(obj, ...) end
				local method = getnamecallmethod()
				for i = 1, #hooks do
					local r = hooks[i](obj, method, ...)
					if r ~= nil and r ~= false then
						if r == true then return nil end
						return r
					end
				end
				return NCD.Original(obj, ...)
			end))
		end)

		-- ── ViewModel resolution helpers (Harion) ────────────────────
		local virtualViewModelClassOverrides = {
			["Operator"] = "Sniper",
			["Grenade (Custom Skin)"] = "Elixir",
			["Grenade Raze"] = "Glorious Grenade",
			["sky"] = "Shining Star",
			["Molotov (Custom Skin)"] = "Elixir",
			["Satchel (Custom Skin)"] = "Elixir",
			["Smoke Grenade (Custom Skin)"] = "Elixir",
			["Warpstone (Custom Skin)"] = "Elixir",
		}
		local function resolveViewModelName(weapon, cosmetics)
			local skin = cosmetics and cosmetics.Skin
			local skinName = skin and (skin.ViewModelName or skin.Name)
			return skinName or weapon
		end
		local function resolveViewModelClassName(_, cosmetics, resolvedName)
			return (resolvedName and virtualViewModelClassOverrides[resolvedName]) or resolvedName
		end
		local resolveViewModelClass
		local clientViewModelClass
		local constructingVirtualViewModelClass = false
		local viewModelClassCache = {}
		local function normalizeViewModelName(name)
			return tostring(name or ""):gsub("[%W_]+", ""):lower()
		end

		-- ── hookfunction: intercept EquipCosmetic / FavoriteCosmetic ──
		pcall(function()
			if not hookfunction then return end
			local rems  = _RS:FindFirstChild("Remotes")
			local drems = rems and rems:FindFirstChild("Data")
			local eqrem  = drems and drems:FindFirstChild("EquipCosmetic")
			local favrem = drems and drems:FindFirstChild("FavoriteCosmetic")
			if not eqrem then return end

			local oldFireServer
			oldFireServer = hookfunction(eqrem.FireServer, newcclosure(function(self, ...)
				local args = {...}

				if self == eqrem then
					local wname, ctype, cname, opts = args[1], args[2], args[3], args[4] or {}
					if not cname or cname == "None" or cname == "" then
						equip[wname] = equip[wname] or {}
						equip[wname][ctype] = nil
						if not next(equip[wname]) then equip[wname] = nil end
						rebuildinv()
						task.defer(function() saferep("WeaponInventory") end)
						return oldFireServer(self, ...)
					end
					if banned(cname) then return oldFireServer(self, ...) end
					-- if player already legitimately owns it, just pass through
					if oget then
						local rdata = oget(mods.PlayerDataController, "CosmeticInventory")
						if rdata and type(rdata[cname]) ~= "boolean" and rdata[cname] ~= nil then
							return oldFireServer(self, ...)
						end
					end
					equip[wname] = equip[wname] or {}
					local cloned = clonecos(cname, ctype, opts.IsInverted, opts.OnlyUseFavorites)
					if cloned then equip[wname][ctype] = cloned end
					if ctype == "Finisher" then fcache[wname] = cname end
					rebuildinv()
					task.defer(function() saferep("WeaponInventory") end)
					return
				end

				if favrem and self == favrem then
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
		end)

		-- ── ItemLibrary GetViewModelImage patch ───────────────────────
		pcall(function()
			if not mods.ItemLibrary then return end
			local orig = mods.ItemLibrary.GetViewModelImageFromWeaponData
			if not orig then return end
			mods.ItemLibrary.GetViewModelImageFromWeaponData = function(p1, p2, p3)
				if not p2 then return orig(p1, p2, p3) end
				local weq = equip[p2.Name]
				local skin = weq and weq.Skin
				if skin and p2.Skin then
					local info = p1.ViewModels and p1.ViewModels[skin.Name]
					if info then return info[p3 and "ImageHighResolution" or "Image"] or info.Image end
				end
				return orig(p1, p2, p3)
			end
		end)

		-- ── ClientItem._CreateViewModel + ClientViewModel (Harion) ────
		pcall(function()
			local lps = LP:FindFirstChild("PlayerScripts")
			if not lps then return end
			local cimod = lps.Modules.ClientReplicatedClasses.ClientFighter.ClientItem
			if not cimod then return end
			local citem = require(cimod)
			if not citem then return end

			if citem._CreateViewModel then
				local ocvm = citem._CreateViewModel
				citem._CreateViewModel = function(self, vmref)
					local wname = self.Name
					local wplr  = self.ClientFighter and self.ClientFighter.Player
					cwep = (wplr == LP) and wname or nil
					local directClass
					if wplr == LP and equip[wname] and vmref then
						local cos = equip[wname]
						local ok2, dk = pcall(function() return self:ToEnum("Data") end)
						if ok2 and dk then
							local data = vmref[dk] or vmref.Data or {}
							if vmref[dk] ~= nil or vmref.Data == nil then
								vmref[dk] = data; vmref.Data = nil
							else
								vmref.Data = data
							end
							local resolvedName = resolveViewModelName(wname, cos)
							local className    = resolveViewModelClassName(wname, cos, resolvedName)
							local ok3, sk3 = pcall(function() return self:ToEnum("Skin") end)
							local ok4, nk  = pcall(function() return self:ToEnum("Name") end)
							local ok5, wk  = pcall(function() return self:ToEnum("Wrap") end)
							local ok6, ck  = pcall(function() return self:ToEnum("Charm") end)
							if cos.Skin  and ok3 then data[sk3] = cos.Skin  end
							if ok4 then data[nk] = resolvedName end
							if cos.Wrap  and ok5 then data[wk]  = cos.Wrap  end
							if cos.Charm and ok6 then data[ck]  = cos.Charm end
							data.Skin = nil; data.Name = nil; data.Wrap = nil; data.Charm = nil
							if className ~= resolvedName and resolveViewModelClass then
								directClass = resolveViewModelClass(className)
							end
						end
					end
					if directClass and directClass ~= clientViewModelClass and directClass.new then
						local identity = getthreadidentity and getthreadidentity() or 8
						constructingVirtualViewModelClass = true
						local ok7, res = pcall(function()
							if setthreadidentity then pcall(setthreadidentity, 2) end
							return directClass.new(vmref, self)
						end)
						constructingVirtualViewModelClass = false
						if setthreadidentity then pcall(setthreadidentity, identity) end
						cwep = nil
						if ok7 then return res end
					end
					local res = ocvm(self, vmref)
					cwep = nil
					return res
				end
			end

			local vmmod = cimod:FindFirstChild("ClientViewModel")
			if vmmod then
				local cvm = require(vmmod)
				clientViewModelClass = cvm

				if cvm.GetWrap then
					local ogw = cvm.GetWrap
					cvm.GetWrap = function(self)
						local ci   = self.ClientItem
						local wname = ci and ci.Name
						local wplr  = ci and ci.ClientFighter and ci.ClientFighter.Player
						local weq   = wname and wplr == LP and equip[wname]
						return (weq and weq.Wrap) or ogw(self)
					end
				end

				local onew = cvm.new
				cvm.new = function(rdata, cliitm)
					if constructingVirtualViewModelClass then return onew(rdata, cliitm) end
					local wplr  = cliitm.ClientFighter and cliitm.ClientFighter.Player
					local wname = cwep or cliitm.Name
					local className = wname
					if wplr == LP and equip[wname] then
						local ok8, rcls = pcall(require, _RS.Modules.ReplicatedClass)
						if ok8 and rcls then
							local dk = rcls:ToEnum("Data")
							local slot = rdata[dk] or rdata.Data or {}
							if rdata[dk] ~= nil or rdata.Data == nil then
								rdata[dk] = slot; rdata.Data = nil
							else
								rdata.Data = slot
							end
							local cos = equip[wname]
							local resolvedName = resolveViewModelName(wname, cos)
							className = resolveViewModelClassName(wname, cos, resolvedName)
							if cos.Skin  then slot[rcls:ToEnum("Skin")]  = cos.Skin  end
							slot[rcls:ToEnum("Name")] = resolvedName
							if cos.Wrap  then slot[rcls:ToEnum("Wrap")]  = cos.Wrap  end
							if cos.Charm then slot[rcls:ToEnum("Charm")] = cos.Charm end
							slot.Skin = nil; slot.Name = nil; slot.Wrap = nil; slot.Charm = nil
						end
					end
					local targetNew = onew
					local targetClass = className ~= wname and resolveViewModelClass and resolveViewModelClass(className)
					if targetClass and targetClass ~= clientViewModelClass and targetClass.new then
						targetNew = targetClass.new
					end
					constructingVirtualViewModelClass = targetNew ~= onew
					local ok9, res = pcall(targetNew, rdata, cliitm)
					constructingVirtualViewModelClass = false
					if not ok9 and wplr == LP and equip[wname] and equip[wname].Skin then
						local ok10, rcls2 = pcall(require, _RS.Modules.ReplicatedClass)
						if ok10 and rcls2 then
							local dk = rcls2:ToEnum("Data")
							local slot = rdata[dk] or rdata.Data or {}
							rdata[dk] = slot; rdata.Data = nil
							slot[rcls2:ToEnum("Name")] = wname; slot.Name = nil
							ok9, res = pcall(onew, rdata, cliitm)
						end
					end
					if not ok9 then error(res) end
					if wplr == LP and equip[wname] and res then
						for _, method in ipairs({"_UpdateWrap","UpdateWrap","_UpdateCharm","UpdateCharm","_UpdateCosmetics","UpdateCosmetics"}) do
							if res[method] then pcall(res[method], res) end
						end
					end
					return res
				end

				-- resolveViewModelClass needs clientViewModelClass set, define after cvm is loaded
				resolveViewModelClass = function(name)
					if not clientViewModelClass then return nil end
					local key = normalizeViewModelName(name)
					if viewModelClassCache[key] ~= nil then
						return viewModelClassCache[key] or clientViewModelClass
					end
					local targetClass = clientViewModelClass
					local vmFolder = lps.Modules:FindFirstChild("ViewModels")
					if vmFolder then
						for _, module in ipairs(vmFolder:GetDescendants()) do
							if module:IsA("ModuleScript") and normalizeViewModelName(module.Name) == key then
								local okM, customClass = pcall(require, module)
								if okM and type(customClass) == "table" and type(customClass.new) == "function" then
									targetClass = customClass
								end
								break
							end
						end
					end
					viewModelClassCache[key] = targetClass
					return targetClass
				end
			end
		end)

		-- ── cosmetic query helpers ────────────────────────────────────
		local function GetCosmeticsByRarity(rarity)
			local r = {}
			if not mods.CosmeticLibrary or not mods.CosmeticLibrary.Cosmetics then return r end
			for name, cos in pairs(mods.CosmeticLibrary.Cosmetics) do
				if cos.Rarity == rarity then r[#r+1] = name end
			end
			return r
		end
		local function GetCosmeticsByType(type_name)
			local r = {}
			if not mods.CosmeticLibrary or not mods.CosmeticLibrary.Cosmetics then return r end
			for name, cos in pairs(mods.CosmeticLibrary.Cosmetics) do
				if cos.Type == type_name then r[#r+1] = name end
			end
			return r
		end
		local function GetAllCosmetics()
			local r = {}
			if not mods.CosmeticLibrary or not mods.CosmeticLibrary.Cosmetics then return r end
			for name in pairs(mods.CosmeticLibrary.Cosmetics) do r[#r+1] = name end
			return r
		end
		local function GetAllCosmeticsOfWeapon(weapon_name)
			local r = {}
			if not mods.CosmeticLibrary or not mods.CosmeticLibrary.Cosmetics then return r end
			for name, cos in pairs(mods.CosmeticLibrary.Cosmetics) do
				if cos.Type == "Skin" then
					if cos.ItemName == weapon_name then r[#r+1] = name end
				else r[#r+1] = name end
			end
			return r
		end
		local function GetSpecificCosmetic(type_name, cos_name, weapon_name)
			if not mods.CosmeticLibrary or not mods.CosmeticLibrary.Cosmetics then return nil end
			for name, cos in pairs(mods.CosmeticLibrary.Cosmetics) do
				if type_name == "Skin" then
					if name==cos_name and cos.Type==type_name and cos.ItemName==weapon_name then return name end
				else
					if name==cos_name and cos.Type==type_name then return name end
				end
			end
		end

		-- ── weapon unlock helpers ─────────────────────────────────────
		local function UnlockAllWeapons()
			if not mods.ShopLibrary or not mods.ShopLibrary.GetReleasedOwnableWeapons then return end
			local ownables = mods.ShopLibrary:GetReleasedOwnableWeapons()
			local existing = {}
			for _, wd in ipairs(SK.fake_weapon_owned) do
				if type(wd)=="table" and wd.Name then existing[wd.Name]=true end
			end
			for _, wn in pairs(ownables) do
				if not existing[wn] and not SK.fake_weapon_names[wn] then
					SK.fake_weapon_owned[#SK.fake_weapon_owned+1] = {Name=wn,Level=1,XP=0,IsFavorited=false,Skin=nil}
					SK.fake_weapon_names[wn] = true
				end
			end
		end
		local function LockAllWeapons()
			local fake, names = SK.fake_weapon_owned, SK.fake_weapon_names
			for i = #fake, 1, -1 do if names[fake[i].Name] then table.remove(fake,i) end end
			table.clear(names)
		end
		local function UnlockSpecificWeapon(wn)
			if not wn or wn=="" then return end
			local exists = false
			for _, wd in ipairs(SK.fake_weapon_owned) do if type(wd)=="table" and wd.Name==wn then exists=true break end end
			if not exists then
				SK.fake_weapon_owned[#SK.fake_weapon_owned+1] = {Name=wn,Level=1,XP=0,IsFavorited=false,Skin=nil}
				SK.fake_weapon_names[wn] = true
			end
		end
		local function EquipApplyAll(cosmeticType, cosmeticName, isInverted)
			if not mods.ItemLibrary or not mods.ItemLibrary.Items then return end
			local remote = _RS:FindFirstChild("Remotes") and _RS.Remotes:FindFirstChild("Data") and _RS.Remotes.Data:FindFirstChild("EquipCosmetic")
			if not remote then return end
			local nameToSend = (cosmeticName~="" and cosmeticName) or nil
			local options = {}
			if cosmeticType=="Wrap" then options.IsInverted = isInverted or nil end
			for wn, wd in pairs(mods.ItemLibrary.Items) do
				if cosmeticType=="Finisher" and not wd.CanEliminate then continue end
				if typeof(wn)~="string" or wn=="" then continue end
				remote:FireServer(wn, cosmeticType, nameToSend, options)
			end
		end

		-- ── leaderboard helpers ───────────────────────────────────────
		local spfConns = {}
		local function Bind2(name, signal, fn)
			if spfConns[name] then spfConns[name]:Disconnect() end
			spfConns[name] = signal:Connect(fn)
		end
		local function Unbind2(name)
			if spfConns[name] then spfConns[name]:Disconnect() spfConns[name] = nil end
		end
		local function InsertPlayerByValue(list, uid, value)
			for i = #list, 1, -1 do if tonumber(list[i].key)==uid then table.remove(list,i) break end end
			local rank = 1
			for i, e in ipairs(list) do if tonumber(e.value)>=value then rank=i+1 else break end end
			table.insert(list, rank, {key=tostring(uid), value=value})
		end
		local function ResetLeaderboard(name, config_idx)
			if not mods.LeaderboardController then return end
			Unbind2(config_idx)
			local serial = mods.LeaderboardController.LeaderboardSerials
				and mods.LeaderboardController.LeaderboardSerials[name]
			if serial and serial.Players then
				local uid = LP.UserId
				for i = #serial.Players, 1, -1 do
					local p = serial.Players[i]
					if p.UserId==uid or p.UserID==uid or p.PlayerId==uid then table.remove(serial.Players,i) end
				end
				if mods.LeaderboardController.Refreshed then
					mods.LeaderboardController.Refreshed:Fire(name) end
			end
		end
		local function ModifyLeaderboard(config_idx, name, value)
			if not mods.LeaderboardController then return end
			task.spawn(function()
				while not (mods.LeaderboardController.LeaderboardSerials[name]
					and mods.LeaderboardController.LeaderboardSerials[name].Players
					and #mods.LeaderboardController.LeaderboardSerials[name].Players > 0) do
					task.wait(0.5)
				end
				local uid = LP.UserId
				local serial = mods.LeaderboardController.LeaderboardSerials[name]
				if serial and serial.Players then
					InsertPlayerByValue(serial.Players, uid, value)
					if mods.LeaderboardController.Refreshed then mods.LeaderboardController.Refreshed:Fire(name) end
				end
				local upd = _RS:FindFirstChild("Remotes") and _RS.Remotes:FindFirstChild("Misc")
					and _RS.Remotes.Misc:FindFirstChild("UpdateLeaderboard")
				if not (upd and upd:IsA("RemoteEvent")) then return end
				Bind2(config_idx, upd.OnClientEvent, function(data)
					local lb_name = data and data.Name
					if not lb_name or lb_name~=name then return end
					if not SS.leaderboard[config_idx] then return end
					task.defer(function()
						local s2 = mods.LeaderboardController.LeaderboardSerials[name]
						if s2 and s2.Players then
							InsertPlayerByValue(s2.Players, uid, value)
							if mods.LeaderboardController.Refreshed then mods.LeaderboardController.Refreshed:Fire(name) end
						end
					end)
				end)
			end)
		end
		local function UpdateLeaderboardOptions()
			local lb = SS.leaderboard
			if lb.ELO    then Unbind2("ELO");    ModifyLeaderboard("ELO",    "Highest ELO",                lb.elo_value)    end
			if lb.Streak then Unbind2("Streak"); ModifyLeaderboard("Streak", "Current Highest Win Streak",  lb.streak_value)
				lb.old_streak_value = LP:GetAttribute("StatisticDuelsWinStreak")
				LP:SetAttribute("StatisticDuelsWinStreak", lb.streak_value) end
			if lb.Kills  then Unbind2("Kills");  ModifyLeaderboard("Kills",  "Most Eliminations",           lb.kills_value)  end
			if lb.Wins   then Unbind2("Wins");   ModifyLeaderboard("Wins",   "Most Wins",                   lb.wins_value)   end
			if lb.Level  then Unbind2("Level");  ModifyLeaderboard("Level",  "Highest Level",               lb.level_value)
				lb.old_level_value = LP:GetAttribute("Level")
				LP:SetAttribute("Level", lb.level_value) end
			if not lb.ELO    then ResetLeaderboard("Highest ELO",                "ELO")    end
			if not lb.Streak then ResetLeaderboard("Current Highest Win Streak",  "Streak")
				if lb.old_streak_value~=nil then LP:SetAttribute("StatisticDuelsWinStreak", lb.old_streak_value) end end
			if not lb.Kills  then ResetLeaderboard("Most Eliminations",           "Kills")  end
			if not lb.Wins   then ResetLeaderboard("Most Wins",                   "Wins")   end
			if not lb.Level  then ResetLeaderboard("Highest Level",               "Level")
				if lb.old_level_value~=nil then LP:SetAttribute("Level", lb.old_level_value) end end
		end

		-- ── SeasonLibrary charm patch ─────────────────────────────────
		pcall(function()
			if not mods.SeasonLibrary then return end
			local original = mods.SeasonLibrary.FormatSeasonRankCharm
			mods.SeasonLibrary.FormatSeasonRankCharm = function(self, p2, p3, p4, p5)
				local season_num = kSeasonNameMap[p3]
				local elo = kCharmEloMap[SS.charm.charm_rank] or SS.leaderboard.elo_value
				if season_num and kSeasonToggleMap[season_num] and SS.charm[kSeasonToggleMap[season_num]] then
					p4 = elo or p4
					p5 = SS.charm.arch_rank
				end
				return original(self, p2, p3, p4, p5)
			end
		end)

		-- ── badge attribute helper ────────────────────────────────────
		local function UpdateBadges()
			LP:SetAttribute("IsInfluencer",      SS.badges.Influencer and true or false)
			LP:SetAttribute("IsRobloxEmployee",  SS.badges.Admin      and true or false)
			LP:SetAttribute("IsPremium",         SS.badges.Premium    and true or false)
			LP:SetAttribute("HasVerifiedBadge",  SS.badges.Verified   and true or false)
		end

		-- ── device spoof ─────────────────────────────────────────────
		local dev_cancel = 0
		local devMap = {Desktop="MouseKeyboard",Mobile="Touch",Console="Gamepad",VR="VR"}
		local function SetDevice(use_old)
			local key = use_old and SS.old_device or SS.device
			pcall(function()
				_RS.Remotes.Replication.Fighter.SetControls:FireServer(devMap[key] or "MouseKeyboard")
			end)
		end
		local function DeviceSpam()
			dev_cancel += 1
			local token = dev_cancel
			task.spawn(function()
				local list = {"Desktop","Mobile","Console","VR"}
				while SS.device_spam and token==dev_cancel do
					SS.device = list[math.random(1,#list)]
					SetDevice(false)
					task.wait(SS.spam_rate)
				end
				SetDevice(true)
			end)
		end

		-- ── name / thumbnail spoof watchers ──────────────────────────
		local function IsTextObj(o)  return o:IsA("TextLabel")  or o:IsA("TextButton") or o:IsA("TextBox") end
		local function IsImageObj(o) return o:IsA("ImageLabel") end
		local nameAllowed = {DisplayName=true,Username=true,Name=true,Handle=true,
			TitleText=true,SubtitleText=true,HeaderText=true,Title=true,Wins=true,Value=true}

		local function ApplyNameSpoof(obj)
			if not IsTextObj(obj) then return end
			local t = obj.Text
			if SS.display_name and obj.Name=="DisplayName" then t=t:gsub(LP.DisplayName,SS.display_name_value) end
			if SS.username and obj.Name=="Username"         then t=t:gsub(LP.Name,SS.username_value) end
			if obj.Text~=t then obj.Text=t end
		end
		local function RegisterTextObj(obj)
			if not IsTextObj(obj) or not nameAllowed[obj.Name] then return end
			ApplyNameSpoof(obj)
			if SS.name_spoof_conn[obj] then return end
			SS.name_spoof_conn[obj] = obj:GetPropertyChangedSignal("Text"):Connect(function() ApplyNameSpoof(obj) end)
			obj.Destroying:Connect(function()
				if SS.name_spoof_conn[obj] then SS.name_spoof_conn[obj]:Disconnect() SS.name_spoof_conn[obj]=nil end
			end)
		end
		for _, o in ipairs(game:GetDescendants()) do RegisterTextObj(o) end
		bind(game.DescendantAdded:Connect(RegisterTextObj))

		local function ApplyThumbSpoof(obj)
			if not IsImageObj(obj) then return end
			local img = obj.Image
			if SS.spoof_avatar then img=img:gsub(LP.UserId, SS.avatar_userid) end
			if obj.Image~=img then obj.Image=img end
		end
		local thumbAllowed = {AvatarThumbnail=true, ImageLabel=true, Headshot=true}
		local function RegisterImageObj(obj)
			if not IsImageObj(obj) or not thumbAllowed[obj.Name] then return end
			ApplyThumbSpoof(obj)
			if SS.thumb_spoof_conn[obj] then return end
			SS.thumb_spoof_conn[obj] = obj:GetPropertyChangedSignal("Image"):Connect(function() ApplyThumbSpoof(obj) end)
			obj.Destroying:Connect(function()
				if SS.thumb_spoof_conn[obj] then SS.thumb_spoof_conn[obj]:Disconnect() SS.thumb_spoof_conn[obj]=nil end
			end)
		end
		for _, o in ipairs(game:GetDescendants()) do RegisterImageObj(o) end
		bind(game.DescendantAdded:Connect(RegisterImageObj))

		-- ── currency replicate helper ─────────────────────────────────
		local function UpdateCurrencyUI()
			pcall(function()
				local cd = mods.PlayerDataController and mods.PlayerDataController.CurrentData
				if not cd then return end
				for _, k in ipairs({"WeaponKeys","UnlockTokens","EventCurrency","Glory","SkinTickets"}) do
					pcall(cd.Replicate, cd, k)
				end
			end)
		end

		-- ══════════════════════════════════════════════════════════════
		-- SPOOFING PAGE  (rivals only)
		-- ══════════════════════════════════════════════════════════════

		-- col 1 = left, col 2 = right
		-- IDENTITY TAB
		do
			local id1 = card(spf_id[1], "display name")
			local dnBox = id1.textbox(LP.DisplayName)
			id1.toggle("spoof display name", false, function(v)
				SS.display_name_value = dnBox.Text~="" and dnBox.Text or LP.DisplayName
				SS.display_name = v
				for obj in pairs(SS.name_spoof_conn) do if obj and obj.Parent then ApplyNameSpoof(obj) end end
			end)

			local id2 = card(spf_id[1], "username")
			local unBox = id2.textbox(LP.Name)
			id2.toggle("spoof username", false, function(v)
				SS.username_value = unBox.Text~="" and unBox.Text or LP.Name
				SS.username = v
				for obj in pairs(SS.name_spoof_conn) do if obj and obj.Parent then ApplyNameSpoof(obj) end end
			end)

			local id3 = card(spf_id[1], "avatar spoof")
			local uidBox = id3.textbox(tostring(LP.UserId))
			id3.toggle("spoof avatar", false, function(v)
				local uid = tonumber(uidBox.Text)
				if not uid then UIFX.notify("enter a valid user id") return end
				SS.avatar_userid = uid
				SS.spoof_avatar = v
				for obj in pairs(SS.thumb_spoof_conn) do if obj and obj.Parent then ApplyThumbSpoof(obj) end end
			end)
			id3.note("replaces your avatar thumbnail client-side")

			local id4 = card(spf_id[2], "device spoof")
			id4.list({"Desktop","Mobile","Console","VR"}, "device", function(v) SS.device = v end)
			id4.toggle("spoof device", false, function(v)
				SS.spoof_device = v
				SetDevice(not v)
			end)
			id4.toggle("device spam", false, function(v)
				SS.device_spam = v
				if v then DeviceSpam() else SetDevice(true) end
			end)
			id4.slider("spam rate", 1, 20, 10, function(v) SS.spam_rate = v / 10 end, " s", 1)

			local id5 = card(spf_id[2], "badges")
			id5.toggle("premium",    false, function(v) SS.badges.Premium    = v UpdateBadges() end)
			id5.toggle("verified",   false, function(v) SS.badges.Verified   = v UpdateBadges() end)
			id5.toggle("influencer", false, function(v) SS.badges.Influencer = v UpdateBadges() end)
			id5.toggle("admin",      false, function(v) SS.badges.Admin      = v UpdateBadges() end)
			id5.note("sets player attributes · cosmetic only")
		end

		-- LEADERBOARD TAB
		do
			local lb = SS.leaderboard
			local lb1 = card(spf_lb[1], "elo")
			local eloBox = lb1.textbox("0")
			lb1.toggle("spoof elo", false, function(v) lb.elo_value = tonumber(eloBox.Text) or 0; lb.ELO = v; UpdateLeaderboardOptions() end)

			local lb2 = card(spf_lb[1], "streak & kills")
			local streakBox = lb2.textbox("0")
			lb2.toggle("spoof streak", false, function(v) lb.streak_value = tonumber(streakBox.Text) or 0; lb.Streak = v; UpdateLeaderboardOptions() end)
			local killsBox = lb2.textbox("0")
			lb2.toggle("spoof kills", false, function(v) lb.kills_value = tonumber(killsBox.Text) or 0; lb.Kills = v; UpdateLeaderboardOptions() end)

			local lb3 = card(spf_lb[2], "wins & level")
			local winsBox = lb3.textbox("0")
			lb3.toggle("spoof wins", false, function(v) lb.wins_value = tonumber(winsBox.Text) or 0; lb.Wins = v; UpdateLeaderboardOptions() end)
			local levelBox = lb3.textbox("0")
			lb3.toggle("spoof level", false, function(v) lb.level_value = tonumber(levelBox.Text) or 0; lb.Level = v; UpdateLeaderboardOptions() end)
			lb3.note("leaderboard changes refresh live · client-side only")
		end

		-- CHARMS TAB
		do
			local ch1 = card(spf_ch[1], "rank charm")
			local charmRanks = {
				"Unranked","Bronze 1","Bronze 2","Bronze 3",
				"Silver 1","Silver 2","Silver 3",
				"Gold 1","Gold 2","Gold 3",
				"Platinum 1","Platinum 2","Platinum 3",
				"Diamond 1","Diamond 2","Diamond 3",
				"Onyx 1","Onyx 2","Onyx 3",
				"Nemesis","Archnemesis","Use Spoofed ELO",
			}
			ch1.list(charmRanks, "rank", function(v) SS.charm.charm_rank = v end)
			local archBox = ch1.textbox("1")
			ch1.note("arch rank tier (1-10)")

			local ch2 = card(spf_ch[2], "season toggles")
			ch2.toggle("season 0 charm", false, function(v) SS.charm.s0_charm = v end)
			ch2.toggle("season 1 charm", false, function(v) SS.charm.s1_charm = v end)
			ch2.toggle("season 2 charm", false, function(v) SS.charm.s2_charm = v end)
			ch2.toggle("season 3 charm", false, function(v) SS.charm.s3_charm = v end)
			ch2.note("applies charm cosmetics for each season")
			ch2.button("apply charms now", function()
				local archTier = math.clamp(tonumber(archBox.Text) or 1, 1, 10)
				SS.charm.arch_rank = archTier
				task.spawn(function()
					task.wait(2)
					for _, d in ipairs(workspace:GetDescendants()) do
						if not d:IsA("Model") or not d:FindFirstChild("Extra") then continue end
						local sname = d.Name
						if sname:sub(1,7)~="Season " then continue end
						local snum = tonumber(sname:sub(8))
						if not snum or not kSeasonToggleMap[snum] then continue end
						if not SS.charm[kSeasonToggleMap[snum]] then continue end
						local snname = kSeasonNameMap[snum]
						if not snname or not mods.SeasonLibrary then continue end
						local elo = kCharmEloMap[SS.charm.charm_rank] or SS.leaderboard.elo_value
						pcall(function()
							mods.SeasonLibrary:FormatSeasonRankCharm(d, snname, elo, SS.charm.arch_rank)
						end)
					end
				end)
				UIFX.notify("applying charms…")
			end)
		end

		-- CURRENCY TAB
		do
			local cur = SS.currency
			local cu1 = card(spf_cur[1], "weapon keys")
			local wkBox = cu1.textbox("0")
			cu1.toggle("spoof weapon keys", false, function(v) cur.weapon_keys_value = tonumber(wkBox.Text) or 0; cur.weapon_keys = v; UpdateCurrencyUI() end)

			local cu2 = card(spf_cur[1], "unlock tokens")
			local utBox = cu2.textbox("0")
			cu2.toggle("spoof unlock tokens", false, function(v) cur.unlock_tokens_value = tonumber(utBox.Text) or 0; cur.unlock_tokens = v; UpdateCurrencyUI() end)

			local cu3 = card(spf_cur[2], "event currency & glory")
			local ecBox = cu3.textbox("0")
			cu3.toggle("spoof event currency", false, function(v) cur.event_currency_value = tonumber(ecBox.Text) or 0; cur.event_currency = v; UpdateCurrencyUI() end)
			local glBox = cu3.textbox("0")
			cu3.toggle("spoof glory", false, function(v) cur.glory_value = tonumber(glBox.Text) or 0; cur.glory = v; UpdateCurrencyUI() end)

			local cu4 = card(spf_cur[2], "skin tickets")
			local stBox = cu4.textbox("0")
			cu4.toggle("spoof skin tickets", false, function(v) cur.skin_tickets_value = tonumber(stBox.Text) or 0; cur.skin_tickets = v; UpdateCurrencyUI() end)
			cu4.note("client-side display only  ·  rivals only")
		end

		-- ══════════════════════════════════════════════════════════════
		-- SKIN CHANGER GUI  (Harion, ported)
		-- ══════════════════════════════════════════════════════════════

		local cosmeticGuiState = {
			Wanted = false, Gui = nil,
			WeaponSearch = "", CosmeticSearch = "",
			Mode = "Skin", SelectedWeapon = nil, SelectedCosmetic = nil,
			Weapons = {}, Cosmetics = {},
			Columns = 3, TileW = 130, TileH = 124,
			Refresh = nil,
		}

		-- display name + image for a cosmetic entry
		local function displayName(name, cdata_)
			if not cdata_ then return name end
			return cdata_.DisplayName or cdata_.Name or name
		end
		local function iconFrom(cdata_)
			local id = cdata_ and (cdata_.ThumbnailId or cdata_.ThumbnailID or cdata_.Icon)
			if not id then return "" end
			return ("rbxassetid://%s"):format(tostring(id):gsub("rbxassetid://",""))
		end
		local function sortByName(t)
			table.sort(t, function(a, b) return (a.Display or a.Name or "") < (b.Display or b.Name or "") end)
		end
		local function cosmeticMatchesWeapon(cosData, weaponName, mode)
			local t = cosData and cosData.Type or ""
			if mode == "Skin" then
				return t == "Skin" and (cosData.ItemName == weaponName or cosData.ItemName == nil or cosData.ItemName == "")
			end
			return t == mode
		end

		local function rebuildCosmeticLists()
			cosmeticGuiState.Weapons = {}
			cosmeticGuiState.Cosmetics = {}
			-- weapon list
			local wepNames = {}
			if ilib and ilib.Items then
				for wname in pairs(ilib.Items) do wepNames[#wepNames+1] = wname end
			elseif ilib and ilib.ItemsAlphabetized then
				for _, wname in ipairs(ilib.ItemsAlphabetized) do wepNames[#wepNames+1] = wname end
			end
			for _, wname in ipairs(wepNames) do
				local eq = equip[wname]
				local eqSkin = eq and eq[cosmeticGuiState.Mode]
				local display = wname
				local img = ""
				if ilib and ilib.Items and ilib.Items[wname] then
					local wd = ilib.Items[wname]
					display = wd.DisplayName or wd.Name or wname
					img = iconFrom(wd)
				end
				if eqSkin then
					display = display .. " [" .. (eqSkin.Name or "?") .. "]"
				end
				cosmeticGuiState.Weapons[#cosmeticGuiState.Weapons+1] = {
					Name = wname, Display = display, Image = img,
				}
			end
			sortByName(cosmeticGuiState.Weapons)
			-- cosmetic list for selected weapon + mode
			local selWep = cosmeticGuiState.SelectedWeapon
			for cosName, cosData in pairs(coss) do
				if banned(cosName) then continue end
				if cosmeticMatchesWeapon(cosData, selWep, cosmeticGuiState.Mode) then
					cosmeticGuiState.Cosmetics[#cosmeticGuiState.Cosmetics+1] = {
						Name = cosName,
						Display = displayName(cosName, cosData),
						Image = iconFrom(cosData),
						Data = cosData,
					}
				end
			end
			sortByName(cosmeticGuiState.Cosmetics)
		end

		local function forceCosmeticUpdate(weapon, ctype)
			pcall(function()
				if not fctrl or not fctrl.LocalFighterItem then return end
				local fitem = fctrl.LocalFighterItem
				if not fitem then return end
				local weq = equip[weapon]
				local cd  = weq and weq[ctype]
				if not cd then return end
				-- find the character model for this weapon
				local char = fitem:FindFirstChild(weapon, true) or fitem
				if wrapCtrl then
					pcall(function() wrapCtrl:UpdateWrap(char) end)
					pcall(function() wrapCtrl:UpdateCharm(char) end)
					pcall(function() wrapCtrl:UpdateCosmetics(char) end)
				end
			end)
		end

		applyCosmeticToWeapon = function(weapon, cosmeticName, ctype, skipRebuild)
			if not weapon or not cosmeticName then return end
			ctype = ctype or cosmeticGuiState.Mode
			if cosmeticName == "__random" then
				-- pick a random matching cosmetic
				local pool = {}
				for cosName, cosData in pairs(coss) do
					if not banned(cosName) and cosmeticMatchesWeapon(cosData, weapon, ctype) then
						pool[#pool+1] = cosName
					end
				end
				if #pool == 0 then return end
				cosmeticName = pool[math.random(1, #pool)]
			end
			equip[weapon] = equip[weapon] or {}
			local cloned = clonecos(cosmeticName, ctype)
			if cloned then equip[weapon][ctype] = cloned end
			if ctype == "Finisher" then fcache[weapon] = cosmeticName end
			if not skipRebuild then
				rebuildinv()
				task.defer(function() saferep("CosmeticInventory") end)
				task.defer(function() saferep("WeaponInventory") end)
				task.defer(function() forceCosmeticUpdate(weapon, ctype) end)
			end
		end

		local function makeCosmeticChanger()
			if cosmeticGuiState.Gui and cosmeticGuiState.Gui.Parent then
				return cosmeticGuiState.Gui
			end
			-- remove placeholder
			if skContainer and skContainer.placeholder then
				skContainer.placeholder:Destroy()
				skContainer.placeholder = nil
			end

			-- embed directly into the skins card body
			local cardBody = skContainer and skContainer.card and skContainer.card.body
			if not cardBody then return end

			-- wrapper frame — explicit height matches the last element bottom (hint text Y=868 + 18 + 8 pad)
			local EMBED_H = 900
			local gui = Instance.new("Frame")
			gui.Name = "SkinChangerEmbed"
			gui.BackgroundTransparency = 1
			gui.Size = UDim2.new(1, 0, 0, EMBED_H)
			gui.LayoutOrder = 10
			gui.Parent = cardBody
			cosmeticGuiState.Gui = gui

			local frame = gui

			local body = Instance.new("Frame")
			body.BackgroundTransparency = 1
			body.Size = UDim2.new(1, 0, 0, EMBED_H)
			body.ClipsDescendants = false
			body.Parent = gui

			-- helpers
			local function mkText(parent, text, pos, size, ts)
				local lbl = Instance.new("TextLabel")
				lbl.BackgroundTransparency = 1
				lbl.Font = Enum.Font.Gotham
				lbl.Text = text
				lbl.TextColor3 = Color3.fromRGB(171, 157, 193)
				lbl.TextSize = ts or 14
				lbl.TextXAlignment = Enum.TextXAlignment.Left
				lbl.Position = pos
				lbl.Size = size
				lbl.ZIndex = 902
				lbl.Parent = parent
				return lbl
			end
			local function mkBox(parent, placeholder, pos, size)
				local box = Instance.new("TextBox")
				box.BackgroundColor3 = Color3.fromRGB(20, 15, 29)
				box.BorderSizePixel = 0
				local corner = Instance.new("UICorner")
				corner.CornerRadius = UDim.new(0, 8)
				corner.Parent = box
				local stroke = Instance.new("UIStroke")
				stroke.Color = Color3.fromRGB(63, 42, 82)
				stroke.Thickness = 1
				stroke.Parent = box
				box.Focused:Connect(function() stroke.Color = Color3.fromRGB(177, 83, 245) end)
				box.FocusLost:Connect(function() stroke.Color = Color3.fromRGB(63, 42, 82) end)
				box.ClearTextOnFocus = false
				box.Font = Enum.Font.Gotham
				box.PlaceholderText = placeholder
				box.PlaceholderColor3 = Color3.fromRGB(121, 105, 143)
				box.Text = ""
				box.TextColor3 = Color3.fromRGB(237, 226, 248)
				box.TextSize = 14
				box.TextXAlignment = Enum.TextXAlignment.Left
				box.Position = pos
				box.Size = size
				box.ZIndex = 902
				box.Parent = parent
				local pad = Instance.new("UIPadding")
				pad.PaddingLeft = UDim.new(0, 6)
				pad.Parent = box
				return box
			end
			local function mkButton(parent, text_, pos, size)
				local btn = Instance.new("TextButton")
				btn.AutoButtonColor = false
				btn.BackgroundColor3 = Color3.fromRGB(27, 18, 39)
				btn.BorderSizePixel = 0
				local corner = Instance.new("UICorner")
				corner.CornerRadius = UDim.new(0, 9)
				corner.Parent = btn
				local stroke = Instance.new("UIStroke")
				stroke.Color = Color3.fromRGB(61, 39, 82)
				stroke.Thickness = 1
				stroke.Parent = btn
				btn.MouseEnter:Connect(function() btn.BackgroundColor3 = Color3.fromRGB(48, 27, 67); stroke.Color = Color3.fromRGB(167, 75, 235) end)
				btn.MouseLeave:Connect(function() btn.BackgroundColor3 = Color3.fromRGB(27, 18, 39); stroke.Color = Color3.fromRGB(61, 39, 82) end)
				btn.Font = Enum.Font.Gotham
				btn.Text = text_
				btn.TextColor3 = Color3.fromRGB(239, 228, 250)
				btn.TextSize = 14
				btn.Position = pos
				btn.Size = size
				btn.ZIndex = 902
				btn.Parent = parent
				return btn
			end

			-- grids
			local weaponGrid = Instance.new("ScrollingFrame")
			weaponGrid.BackgroundColor3 = Color3.fromRGB(13, 10, 19)
			weaponGrid.BorderSizePixel = 0
			local weaponGridCorner = Instance.new("UICorner")
			weaponGridCorner.CornerRadius = UDim.new(0, 10)
			weaponGridCorner.Parent = weaponGrid
			local weaponGridStroke = Instance.new("UIStroke")
			weaponGridStroke.Color = Color3.fromRGB(46, 32, 61)
			weaponGridStroke.Thickness = 1
			weaponGridStroke.Parent = weaponGrid
			weaponGrid.CanvasSize = UDim2.new()
			weaponGrid.ScrollBarThickness = 5
			weaponGrid.ScrollBarImageColor3 = Color3.fromRGB(145, 66, 205)
			weaponGrid.Position = UDim2.fromOffset(0, 54)
			weaponGrid.Size = UDim2.new(1, 0, 0, 320)
			weaponGrid.ZIndex = 902
			weaponGrid.Parent = body

			local cosmeticGrid = Instance.new("ScrollingFrame")
			cosmeticGrid.BackgroundColor3 = Color3.fromRGB(13, 10, 19)
			cosmeticGrid.BorderSizePixel = 0
			local cosmeticGridCorner = Instance.new("UICorner")
			cosmeticGridCorner.CornerRadius = UDim.new(0, 10)
			cosmeticGridCorner.Parent = cosmeticGrid
			local cosmeticGridStroke = Instance.new("UIStroke")
			cosmeticGridStroke.Color = Color3.fromRGB(46, 32, 61)
			cosmeticGridStroke.Thickness = 1
			cosmeticGridStroke.Parent = cosmeticGrid
			cosmeticGrid.CanvasSize = UDim2.new()
			cosmeticGrid.ScrollBarThickness = 5
			cosmeticGrid.ScrollBarImageColor3 = Color3.fromRGB(145, 66, 205)
			cosmeticGrid.Position = UDim2.fromOffset(0, 428)
			cosmeticGrid.Size = UDim2.new(1, 0, 0, 340)
			cosmeticGrid.ZIndex = 902
			cosmeticGrid.Parent = body

			-- labels + search boxes
			mkText(body, "weapon filter", UDim2.fromOffset(0, 6), UDim2.new(1, 0, 0, 18))
			local weaponSearch = mkBox(body, "grenade launcher...", UDim2.fromOffset(0, 28), UDim2.new(1, 0, 0, 24))
			mkText(body, "cosmetic filter", UDim2.fromOffset(0, 378), UDim2.new(1, 0, 0, 18))
			local cosmeticSearch = mkBox(body, "red...", UDim2.fromOffset(0, 400), UDim2.new(1, 0, 0, 24))

			-- mode dropdown
			local modeButton = mkButton(body, "skin                                                                                  >", UDim2.fromOffset(0, 778), UDim2.new(1, 0, 0, 26))
			local modeMenu = Instance.new("Frame")
			modeMenu.BackgroundColor3 = Color3.fromRGB(16, 11, 23)
			modeMenu.BorderSizePixel = 0
			local modeCorner = Instance.new("UICorner")
			modeCorner.CornerRadius = UDim.new(0, 8)
			modeCorner.Parent = modeMenu
			local modeStroke = Instance.new("UIStroke")
			modeStroke.Color = Color3.fromRGB(111, 51, 156)
			modeStroke.Parent = modeMenu
			modeMenu.Position = UDim2.fromOffset(0, 804)
			modeMenu.Size = UDim2.new(1, 0, 0, 104)
			modeMenu.Visible = false
			modeMenu.ZIndex = 910
			modeMenu.Parent = body

			local modes = {"Skin", "Wrap", "Charm", "Finisher"}
			for i, mode in ipairs(modes) do
				local row = mkButton(modeMenu, mode:lower(), UDim2.fromOffset(0, (i-1)*26), UDim2.new(1, 0, 0, 26))
				row.ZIndex = 911
				row.TextXAlignment = Enum.TextXAlignment.Left
				row.MouseButton1Click:Connect(function()
					cosmeticGuiState.Mode = mode
					if cosmeticGuiState.SelectedWeapon then
						local ceq = equip[cosmeticGuiState.SelectedWeapon]
						cosmeticGuiState.SelectedCosmetic = ceq and ceq[mode] and ceq[mode].Name or nil
					else
						cosmeticGuiState.SelectedCosmetic = nil
					end
					modeButton.Text = mode:lower() .. "                                                                                  >"
					modeMenu.Visible = false
					rebuildCosmeticLists()
					task.defer(function() if cosmeticGuiState.Refresh then cosmeticGuiState.Refresh() end end)
				end)
			end

			-- action buttons
			local applyAll = mkButton(body, "apply selected to all", UDim2.fromOffset(0, 808), UDim2.new(1, 0, 0, 26))
			local resetBtn = mkButton(body, "reset to defaults",      UDim2.fromOffset(0, 838), UDim2.new(1, 0, 0, 26))
			mkText(body, "right-click a weapon tile to apply the selected skin to it", UDim2.fromOffset(0, 868), UDim2.new(1, 0, 0, 18), 12).TextColor3 = Color3.fromRGB(125, 125, 125)

			-- tile helpers
			local function passes(entry, query)
				query = tostring(query or ""):lower()
				return query == "" or entry.Name:lower():find(query,1,true) or entry.Display:lower():find(query,1,true)
			end
			local function clearChildren(f)
				for _, c in ipairs(f:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
			end
			local function makeTile(parent, entry, index, selected, callback, rightCallback, largeImg)
				local col = (index-1) % cosmeticGuiState.Columns
				local row_ = math.floor((index-1) / cosmeticGuiState.Columns)
				local tile = Instance.new("TextButton")
				tile.AutoButtonColor = false
				tile.BackgroundColor3 = selected and Color3.fromRGB(43, 24, 61) or Color3.fromRGB(21, 15, 29)
				tile.BorderSizePixel = 0
				local tileCorner = Instance.new("UICorner")
				tileCorner.CornerRadius = UDim.new(0, 8)
				tileCorner.Parent = tile
				local tileStroke = Instance.new("UIStroke")
				tileStroke.Color = selected and Color3.fromRGB(185, 83, 255) or Color3.fromRGB(49, 34, 63)
				tileStroke.Thickness = selected and 1.5 or 1
				tileStroke.Parent = tile
				tile.MouseEnter:Connect(function() if not selected then tileStroke.Color = Color3.fromRGB(126, 62, 166) end end)
				tile.MouseLeave:Connect(function() if not selected then tileStroke.Color = Color3.fromRGB(49, 34, 63) end end)
				tile.Position = UDim2.fromOffset(col * cosmeticGuiState.TileW, row_ * cosmeticGuiState.TileH)
				tile.Size = UDim2.fromOffset(cosmeticGuiState.TileW, cosmeticGuiState.TileH)
				tile.ClipsDescendants = true
				tile.Text = ""
				tile.ZIndex = 903
				tile.Parent = parent

				local img = Instance.new("ImageLabel")
				img.BackgroundTransparency = 1
				img.Image = entry.Image or ""
				img.ScaleType = Enum.ScaleType.Fit
				img.Position = largeImg and UDim2.fromOffset(-61, -43) or UDim2.fromOffset(14, 9)
				img.Size     = largeImg and UDim2.fromOffset(252, 176) or UDim2.fromOffset(102, 76)
				img.ZIndex = 904
				img.Parent = tile

				local lbl = Instance.new("TextLabel")
				lbl.BackgroundTransparency = 1
				lbl.Font = Enum.Font.GothamMedium
				lbl.Text = entry.Display
				lbl.TextColor3 = Color3.fromRGB(225, 213, 239)
				lbl.TextScaled = true
				lbl.TextWrapped = true
				lbl.Position = UDim2.fromOffset(6, 86)
				lbl.Size = UDim2.fromOffset(118, 32)
				lbl.ZIndex = 904
				lbl.Parent = tile

				tile.MouseButton1Click:Connect(function() callback(entry) end)
				tile.MouseButton2Click:Connect(function() if rightCallback then rightCallback(entry) end end)
			end

			local function refresh()
				clearChildren(weaponGrid)
				clearChildren(cosmeticGrid)
				local wcount = 0
				for _, entry in ipairs(cosmeticGuiState.Weapons) do
					if passes(entry, cosmeticGuiState.WeaponSearch) then
						wcount += 1
						makeTile(weaponGrid, entry, wcount, cosmeticGuiState.SelectedWeapon == entry.Name,
							function(chosen)
								cosmeticGuiState.SelectedWeapon = chosen.Name
								local ceq = equip[chosen.Name]
								cosmeticGuiState.SelectedCosmetic = ceq and ceq[cosmeticGuiState.Mode] and ceq[cosmeticGuiState.Mode].Name or nil
								rebuildCosmeticLists()
								refresh()
							end,
							function(chosen)  -- right-click: quick-apply selected skin to this weapon
								cosmeticGuiState.SelectedWeapon = chosen.Name
								applyCosmeticToWeapon(chosen.Name, cosmeticGuiState.SelectedCosmetic, cosmeticGuiState.Mode)
								rebuildCosmeticLists()
								refresh()
							end, true)
					end
				end
				weaponGrid.CanvasSize = UDim2.fromOffset(0, math.max(264, math.ceil(wcount / cosmeticGuiState.Columns) * cosmeticGuiState.TileH))

				-- random tile
				local randomEntry = {Name = "__random", Display = "Random", Image = "rbxassetid://132973552546079"}
				makeTile(cosmeticGrid, randomEntry, 1, cosmeticGuiState.SelectedCosmetic == "__random", function()
					cosmeticGuiState.SelectedCosmetic = "__random"
					if cosmeticGuiState.SelectedWeapon then
						applyCosmeticToWeapon(cosmeticGuiState.SelectedWeapon, "__random", cosmeticGuiState.Mode)
					end
					rebuildCosmeticLists()
					refresh()
				end)

				local ccount = 1
				for _, entry in ipairs(cosmeticGuiState.Cosmetics) do
					if passes(entry, cosmeticGuiState.CosmeticSearch) then
						ccount += 1
						makeTile(cosmeticGrid, entry, ccount, cosmeticGuiState.SelectedCosmetic == entry.Name,
							function(chosen)
								cosmeticGuiState.SelectedCosmetic = chosen.Name
								if cosmeticGuiState.SelectedWeapon then
									applyCosmeticToWeapon(cosmeticGuiState.SelectedWeapon, chosen.Name, cosmeticGuiState.Mode)
								end
								rebuildCosmeticLists()
								refresh()
							end, nil, cosmeticGuiState.Mode == "Skin")
					end
				end
				cosmeticGrid.CanvasSize = UDim2.fromOffset(0, math.max(276, math.ceil(ccount / cosmeticGuiState.Columns) * cosmeticGuiState.TileH))
			end

			cosmeticGuiState.Refresh = refresh
			skRefreshRef = refresh  -- exposed for config load

			-- search debounce
			local wst, cst
			weaponSearch:GetPropertyChangedSignal("Text"):Connect(function()
				cosmeticGuiState.WeaponSearch = weaponSearch.Text
				if wst then task.cancel(wst) end
				wst = task.delay(0.1, refresh)
			end)
			cosmeticSearch:GetPropertyChangedSignal("Text"):Connect(function()
				cosmeticGuiState.CosmeticSearch = cosmeticSearch.Text
				if cst then task.cancel(cst) end
				cst = task.delay(0.1, refresh)
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
				task.defer(function() saferep("CosmeticInventory") end)
				task.defer(function() saferep("WeaponInventory") end)
				rebuildCosmeticLists()
				refresh()
			end)
			resetBtn.MouseButton1Click:Connect(function()
				table.clear(equip)
				table.clear(fcache)
				rebuildinv()
				task.defer(function() saferep("WeaponInventory") end)
				rebuildCosmeticLists()
				refresh()
			end)
			-- no close/heartbeat: embedded in card, always visible on skins tab
			rebuildCosmeticLists()
			refresh()
			return gui
		end

		-- build the changer once modules are ready (async init above)
		task.spawn(function()
			-- wait for the async require task to finish (max 20s)
			for _ = 1, 200 do
				if modsReady then break end
				task.wait(0.1)
			end
			if not mods.CosmeticLibrary then return end  -- not rivals
			-- refresh module-dependent upvalues now that mods are loaded
			coss     = mods.CosmeticLibrary and mods.CosmeticLibrary.Cosmetics or {}
			ilib     = mods.ItemLibrary
			elib     = mods.EnumLibrary
			dctrl    = mods.PlayerDataController
			cdata    = dctrl and dctrl.CurrentData or nil
			fctrl    = mods.FighterController
			wrapCtrl = mods.WrapController
			pcall(makeCosmeticChanger)
			cosmeticChanger = {
				Reset = function()
					table.clear(equip)
					table.clear(fcache)
					rebuildinv()
					task.defer(function() saferep("WeaponInventory") end)
					rebuildCosmeticLists()
					if cosmeticGuiState.Refresh then cosmeticGuiState.Refresh() end
				end,
				Refresh = function()
					rebuildCosmeticLists()
					if cosmeticGuiState.Refresh then cosmeticGuiState.Refresh() end
				end,
			}
		end)

	end -- end rivals spoofer + skinchanger block

	local afc = card(mi[1], "anti fling")
	local afT = afc.toggle("anti fling", false, function(v) AF.on = v if not v then restoreCollide() end end)
	afc.toggle("no collide players", true, function(v) AF.noCollide = v if not v then restoreCollide() end end)
	afc.toggle("velocity guard", true, function(v) AF.guard = v end)
	afc.toggle("return to safe spot", true, function(v) AF.returnSafe = v end)
	afc.slider("max speed", 100, 1000, 250, function(v) AF.maxVel = v end, " st/s", 10)
	afc.slider("max spin", 10, 120, 40, function(v) AF.maxSpin = v end, " rad/s")
	afStatus = afc.note("flings blocked: 0")

	-- void spam
	local VS = {
		on = false, holdMode = true, burstMode = false,
		interval = 0.08, burstN = 5, burstGap = 0.06,
		key = nil, _conn = nil, _held = false, _listening = false,
	}
	local function getVoidRemote()
		-- FILL: remote-spy in rivals -> filter "void"/"ability"/"skill" -> replace with exact path
		--       e.g.: return game:GetService("ReplicatedStorage").Remotes.ExactName
		local rs = game:GetService("ReplicatedStorage")
		for _, v in ipairs(rs:GetDescendants()) do
			if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
				local n = v.Name:lower()
				if n:find("void") or n:find("ability") or n:find("skill") or n:find("dash") then
					return v
				end
			end
		end
		return nil
	end
	local function fireVoid()
		local remote = getVoidRemote()
		if not remote then return end
		-- FILL: add rivals-specific args after spying  e.g. remote:FireServer(arg1, arg2)
		if remote:IsA("RemoteEvent") then
			pcall(function() remote:FireServer() end)
		elseif remote:IsA("RemoteFunction") then
			pcall(function() remote:InvokeServer() end)
		end
	end
	local function startVoidSpam()
		if VS._conn then return end
		VS._conn = RunService.Heartbeat:Connect(function()
			if not VS.on and not VS._held then
				VS._conn:Disconnect() VS._conn = nil return
			end
			if VS.burstMode then
				task.spawn(function()
					for i = 1, VS.burstN do
						if not VS.on and not VS._held then break end
						fireVoid()
						task.wait(VS.burstGap)
					end
				end)
				task.wait(VS.interval * VS.burstN + 0.05)
			else
				fireVoid()
				task.wait(VS.interval)
			end
		end)
	end
	local function stopVoidSpam()
		if VS._conn then VS._conn:Disconnect() VS._conn = nil end
	end

	local vsc = card(mi[1], "void spam")
	local vsToggle = vsc.toggle("void spam", false, function(v)
		VS.on = v
		if v then startVoidSpam() else if not VS._held then stopVoidSpam() end end
	end)
	vsc.slider("fire interval", 1, 100, 8, function(v) VS.interval = v / 100 end, " ms", 1)
	vsc.toggle("burst mode", false, function(v) VS.burstMode = v end)
	vsc.slider("burst count", 1, 20, 5, function(v) VS.burstN = v end)
	vsc.slider("burst gap", 1, 20, 6, function(v) VS.burstGap = v / 100 end, " ms", 1)
	vsc.toggle("hold mode", true, function(v)
		VS.holdMode = v
		if not v then VS._held = false if not VS.on then stopVoidSpam() end end
	end)

	-- custom keybind: none default, right-click clears, pill always visible, dot lights on hold
	-- get the card body by probing a note row then removing it
	local _probe = vsc.note("")
	local _vscBody = _probe.Parent.Parent
	_probe.Parent:Destroy()
	do
		local kbFrame = new("Frame", {
			Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1,
			LayoutOrder = 999,  -- always last in body
		}, _vscBody)
		text(kbFrame, {Text = "key bind", Size = UDim2.new(1, -100, 1, 0)})

		local keyPill = new("TextButton", {
			Size = UDim2.fromOffset(92, 22), Position = UDim2.new(1, -92, 0.5, -11),
			BackgroundColor3 = T.row, Text = "none", FontFace = F.body, TextSize = 14,
			TextColor3 = T.sub, AutoButtonColor = false,
		}, kbFrame)
		corner(keyPill, 11)
		local keyStroke = new("UIStroke", {Color = T.stroke, Thickness = 1}, keyPill)

		-- dot: dark when idle, accent while held
		local keyDot = new("Frame", {
			Size = UDim2.fromOffset(6, 6), AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 7, 0.5, 0), BackgroundColor3 = T.off, BorderSizePixel = 0,
		}, keyPill)
		corner(keyDot, 3)

		local function refreshPill()
			if VS._listening then
				keyPill.Text = "  press..."
				keyPill.TextColor3 = T.accent
				tween(keyStroke, {Color = T.accent})
			elseif VS.key then
				keyPill.Text = "  " .. VS.key.Name
				keyPill.TextColor3 = T.text
				tween(keyStroke, {Color = T.stroke})
			else
				keyPill.Text = "  none"
				keyPill.TextColor3 = T.sub
				tween(keyStroke, {Color = T.stroke})
			end
		end
		refreshPill()
		table.insert(accentHooks, refreshPill)

		bind(keyPill.MouseButton1Click:Connect(function()
			VS._listening = true refreshPill()
		end))
		bind(keyPill.MouseButton2Click:Connect(function()
			VS.key, VS._listening, VS._held = nil, false, false
			if not VS.on then stopVoidSpam() end
			refreshPill()
		end))
		bind(UIS.InputBegan:Connect(function(i, gp)
			if VS._listening and not gp and i.UserInputType == Enum.UserInputType.Keyboard then
				VS._listening = false VS.key = i.KeyCode refreshPill() return
			end
			if not VS._listening and VS.holdMode and VS.key and i.KeyCode == VS.key and not VS.on then
				VS._held = true
				tween(keyDot, {BackgroundColor3 = T.accent})
				startVoidSpam()
			end
		end))
		bind(UIS.InputEnded:Connect(function(i)
			if VS.key and i.KeyCode == VS.key then
				VS._held = false
				tween(keyDot, {BackgroundColor3 = T.off})
				if not VS.on then stopVoidSpam() end
			end
		end))

		-- hover hint
		bind(keyPill.MouseEnter:Connect(function()
			if VS.key then keyPill.Text = "  right-click clear" keyPill.TextColor3 = T.sub end
		end))
		bind(keyPill.MouseLeave:Connect(function() refreshPill() end))
	end
	vsc.note("toggle = always on  ·  hold mode = fires while key held")

	fg.swatches("presets", {Color3.fromRGB(190, 200, 215), Color3.fromRGB(20, 22, 28), Color3.fromRGB(255, 200, 150), Color3.fromRGB(120, 190, 255), Color3.fromRGB(150, 230, 170)}, function(c) fogWheel.set(c) end)

	-- settings
	local menu = card(st[1], "menu")
	-- accent: the preset swatches plus a button that opens a full color wheel
	do
		local wheel
		menu.swatches("menu accent", ACCENTS, function(c) setAccent(c) if wheel then wheel.set(c) end end)
		local open = false
		local wheelRows = {}
		local btn = menu.button("custom accent color  +", function(b)
			open = not open
			for _, r in ipairs(wheelRows) do r.Visible = open end
			b.Text = open and "custom accent color  -" or "custom accent color  +"
		end)
		local before = #menu.rows
		wheel = menu.colorwheel("accent color", T.accent, function(c) if c ~= T.accent then setAccent(c) end end)
		for i = before + 1, #menu.rows do
			table.insert(wheelRows, menu.rows[i])
			menu.rows[i].Visible = false
		end
	end
	menu.slider("opacity", 60, 100, 100, function(v)
		local tr = 1 - v / 100
		main.BackgroundTransparency = tr side.BackgroundTransparency = tr titleBar.BackgroundTransparency = tr
	end, "%")
	menu.keybind("menu bind", S.menuKey, function(k) S.menuKey = k hint.Text = k.Name .. " to hide" end)
	local opened = false
	menu.slider("ui size", 50, 250, 125, function(v)
		UI.scale = v / 100
		if opened then tween(mainScale, {Scale = fitScale()}, 0.2) keepOnScreen() end
	end, "%", 5)
	bind(Camera:GetPropertyChangedSignal("ViewportSize"):Connect(function() if opened then mainScale.Scale = fitScale() keepOnScreen() end end))
	-- simple mode: a flat, plain look (neutral grays, steel blue, monospace, square corners, no effects)
	do
		local FULL_T = {bg = Color3.fromRGB(4,3,7), side = Color3.fromRGB(7,5,11), card = Color3.fromRGB(10,8,15), row = Color3.fromRGB(16,13,24), stroke = Color3.fromRGB(26,21,38), text = Color3.fromRGB(242,238,255), sub = Color3.fromRGB(120,108,150), off = Color3.fromRGB(28,23,40)}
		local SIMPLE_T = {bg = Color3.fromRGB(18, 18, 18), side = Color3.fromRGB(22, 22, 22), card = Color3.fromRGB(25, 25, 25),
			row = Color3.fromRGB(35, 35, 35), stroke = Color3.fromRGB(52, 52, 52), text = Color3.fromRGB(222, 222, 222),
			sub = Color3.fromRGB(150, 150, 150), off = Color3.fromRGB(60, 60, 60)}
		local SIMPLE_ACCENT = Color3.fromRGB(78, 128, 210)
		local mono = Font.fromEnum(Enum.Font.Code)
		local FULL_F = {title = F.title, body = F.body, bold = F.bold}
		local SIMPLE_F = {title = mono, body = mono, bold = Font.new(mono.Family, Enum.FontWeight.Bold)}
		local savedAccent
		local function keyOf(map, c)
			for k, v in pairs(map) do if v == c then return k end end
		end
		local function applySimple(on)
			if (T.simple or false) == on then return end
			local fromT, toT = on and FULL_T or SIMPLE_T, on and SIMPLE_T or FULL_T
			local fromF, toF = on and FULL_F or SIMPLE_F, on and SIMPLE_F or FULL_F
			T.simple = on
			for k, v in pairs(toT) do T[k] = v end
			for k, v in pairs(toF) do F[k] = v end
			-- restyle everything that already exists
			for _, d in ipairs(gui:GetDescendants()) do
				if d:IsA("GuiObject") then
					local k = keyOf(fromT, d.BackgroundColor3)
					if k then d.BackgroundColor3 = toT[k] end
				end
				if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
					local k = keyOf(fromT, d.TextColor3)
					if k then d.TextColor3 = toT[k] end
					local fk = keyOf(fromF, d.FontFace)
					if fk then d.FontFace = toF[fk] end
				elseif d:IsA("UIStroke") then
					local k = keyOf(fromT, d.Color)
					if k then d.Color = toT[k] end
				elseif d:IsA("UICorner") and d.CornerRadius.Scale == 0 then
					if on then
						d:SetAttribute("vwRadius", d.CornerRadius.Offset)
						d.CornerRadius = UDim.new(0, math.min(d.CornerRadius.Offset, 3))
					elseif d:GetAttribute("vwRadius") then
						d.CornerRadius = UDim.new(0, d:GetAttribute("vwRadius"))
					end
				end
			end
			-- effects
			glow.Visible = not on
			if UIFX.setBorderSimple then UIFX.setBorderSimple(on) end
			for _, ch in ipairs(logo:GetChildren()) do
				if ch.Name:sub(1, 7) == "Emblem_" then ch.Visible = (not on) and ch.Name == "Emblem_" .. (UIFX.emblem or "void") end
			end
			if on then
				savedAccent = T.accent
				setAccent(SIMPLE_ACCENT)
			elseif savedAccent then
				setAccent(savedAccent)
			end
			if current then selectPage(current) end
		end
		menu.toggle("simple mode", false, function(v) applySimple(v) end)
		menu.note("flat look with fewer effects")
	end

	menu.toggle("notifications", true, function(v) UIFX.notifyOn = v end)
	menu.toggle("control alerts", true, function(v) UIFX.toggleAlerts = v end)
	menu.toggle("death alerts", true, function(v) UIFX.deathAlerts = v end)
	menu.toggle("player join/leave alerts", true, function(v) UIFX.playerAlerts = v end)
	menu.slider("backdrop dim", 0, 80, 45, function(v) DIM.amount = v if opened then dim.BackgroundTransparency = 1 - v / 100 end end, "%")

	do
		local sn = card(st[1], "snowfall")
		sn.toggle("snow", true, function(v) SN.on = v syncFlakes() end)
		sn.slider("amount", 0, 200, 60, function(v) SN.amount = v syncFlakes() end)
		sn.slider("fall speed", 10, 300, 100, function(v) SN.speed = v end, "%")
		sn.slider("flake size", 1, 8, 3, function(v) SN.size = v rebuildFlakes() end)
		sn.slider("wind", -100, 100, 0, function(v) SN.wind = v end)
	end

	do
		local tr = card(st[2], "drag trail")
		tr.toggle("drag trail", true, function(v) TRAIL.on = v end)
		tr.slider("length", 0, 100, 35, function(v) TRAIL.length = v end, "%")
		tr.slider("drag smoothing", 0, 100, 50, function(v) TRAIL.smooth = v end, "%")
		tr.slider("spacing", 2, 40, 6, function(v) TRAIL.spacing = v end, " px")
		tr.slider("fill", 0, 60, 12, function(v) TRAIL.fill = v end, "%")
		tr.slider("outline", 0, 40, 15, function(v) TRAIL.outline = v end)
		tr.slider("shrink", 0, 15, 3, function(v) TRAIL.shrink = v end, "%")
		tr.toggle("gradient colors", true, function(v) TRAIL.gradient = v end)
		tr.colorwheel("trail color", TRAIL.color, function(c) TRAIL.color = c end)
		tr.note("trail color is used when gradient is off")
	end

	reg("menu/accent", function() return T.accent end, setAccent)
	reg("menu/window height", function() return UI.height end, function(v) UI.setHeight(v, false) end)

	local api = {}
	do
		local sv = card(st[2], "session")
		sv.button("recenter window", function() main.Position = UDim2.fromScale(0.5, 0.5) end)
		sv.button("rejoin", function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP) end)
		sv.button("disable all", function()
			flyT.set(false) noclipT.set(false) ijT.set(false) fbT.set(false) nfT.set(false) cfT.set(false) wcT.set(false) dsT.set(false) gpT.set(false) afT.set(false)
			vsToggle.set(false) VS._held = false stopVoidSpam()
			for _, x in ipairs({fovT, timeT, bloomT, raysT, dofT, weatherT}) do x.set(false) end
			for _, at in ipairs(auraToggles) do at.set(false) end
			for _, x in ipairs(XFX.toggles) do x.set(false) end
			wsS.set(16) jpS.set(50) satS.set(0) conS.set(0)
		end)
		sv.button("unload", function() api.Destroy() end)
	end

	do
		---------------------------------------------------------------- configs
		local HttpService = game:GetService("HttpService")
		local FOLDER = "Graviton-9v2"
		local CFG_DIR = FOLDER .. "/configs"
		local AUTOLOAD_FILE = FOLDER .. "/autoload.txt"
		local hasFS = typeof(writefile) == "function" and typeof(readfile) == "function" and typeof(listfiles) == "function"
			and typeof(isfile) == "function" and typeof(isfolder) == "function" and typeof(makefolder) == "function"
		local memConfigs, memAutoload = {}, nil -- fallback when files aren't available (lasts this session only)
		if hasFS then
			pcall(function()
				if not isfolder(FOLDER) then makefolder(FOLDER) end
				if not isfolder(CFG_DIR) then makefolder(CFG_DIR) end
			end)
			-- one-time move: bring configs over from the previous version's folder if this one is still empty
			pcall(function()
				if #listfiles(CFG_DIR) > 0 then return end
				local OLD
				for _, name in ipairs({"Graviton-9v1", "voidwareV2"}) do
					if isfolder(name .. "/configs") and #listfiles(name .. "/configs") > 0 then OLD = name break end
				end
				if not OLD then return end
				for _, f in ipairs(listfiles(OLD .. "/configs")) do
					local n = tostring(f):match("([^/\\]+)%.json$")
					if n then writefile(CFG_DIR .. "/" .. n .. ".json", readfile(f)) end
				end
				if isfile(OLD .. "/autoload.txt") and not isfile(AUTOLOAD_FILE) then writefile(AUTOLOAD_FILE, readfile(OLD .. "/autoload.txt")) end
			end)
		end

		local function enc(v)
			local ty = typeof(v)
			if ty == "Color3" then return {c = {v.R, v.G, v.B}} end
			if ty == "EnumItem" then return {k = v.Name} end
			return v
		end
		local function dec(v)
			if type(v) == "table" then
				if v.c then return Color3.new(v.c[1], v.c[2], v.c[3]) end
				if v.k then return Enum.KeyCode[v.k] end
			end
			return v
		end
		local function cleanName(n) return (tostring(n or ""):gsub("[^%w%-_ ]", ""):gsub("^%s+", ""):gsub("%s+$", "")) end
		local function cfgPath(n) return CFG_DIR .. "/" .. n .. ".json" end

		local function snapshot()
			local data = {}
			for id, c in pairs(CONTROLS) do
				local ok, v = pcall(c.get)
				if ok and v ~= nil then data[id] = enc(v) end
			end
			return HttpService:JSONEncode(data)
		end
		local function apply(json)
			local ok, data = pcall(function() return HttpService:JSONDecode(json) end)
			if not ok or type(data) ~= "table" then return false end
			for id, v in pairs(data) do
				local c = CONTROLS[id]
				if c then pcall(c.set, dec(v)) end
			end
			return true
		end
		local function saveConfig(n)
			if hasFS then return pcall(writefile, cfgPath(n), snapshot()) end
			memConfigs[n] = snapshot() return true
		end
		local function loadConfig(n)
			local json
			if hasFS then
				local ok, r = pcall(function() return isfile(cfgPath(n)) and readfile(cfgPath(n)) end)
				json = ok and r or nil
			else
				json = memConfigs[n]
			end
			return json and apply(json) or false
		end
		local function deleteConfig(n)
			if hasFS then
				if typeof(delfile) ~= "function" then return false end
				return pcall(delfile, cfgPath(n))
			end
			memConfigs[n] = nil return true
		end
		local function listConfigs()
			local out = {}
			if hasFS then
				local ok, files = pcall(listfiles, CFG_DIR)
				for _, f in ipairs(ok and files or {}) do
					local n = tostring(f):match("([^/\\]+)%.json$")
					if n then table.insert(out, n) end
				end
			else
				for n in pairs(memConfigs) do table.insert(out, n) end
			end
			table.sort(out)
			return out
		end
		local function getAutoload()
			if hasFS then
				local ok, r = pcall(function() return isfile(AUTOLOAD_FILE) and readfile(AUTOLOAD_FILE) end)
				return ok and r and cleanName(r) ~= "" and cleanName(r) or nil
			end
			return memAutoload
		end
		local function setAutoload(n)
			if hasFS then
				if n then pcall(writefile, AUTOLOAD_FILE, n) elseif typeof(delfile) == "function" then pcall(function() if isfile(AUTOLOAD_FILE) then delfile(AUTOLOAD_FILE) end end) end
			else
				memAutoload = n
			end
		end

		local cfc = card(cfgp[1], "configs")
		local selected = ""
		local nameBox = cfc.textbox("config name...", function(t) selected = cleanName(t) end)
		local cfgStatus
		local function say(msg, good)
			if good ~= nil then UIFX.notify(msg) end
			cfgStatus.Text = msg
			cfgStatus.TextColor3 = good == false and LOGO_V2 or (good and T.accent or T.sub)
		end
		local listHolder
		local function refreshList()
			for _, ch in ipairs(listHolder:GetChildren()) do if ch:IsA("GuiObject") then ch:Destroy() end end
			local names = listConfigs()
			local auto = getAutoload()
			if #names == 0 then
				text(listHolder, {Text = "no saved configs yet", Size = UDim2.new(1, 0, 0, 20), TextColor3 = T.sub, TextSize = 12})
			end
			for i, n in ipairs(names) do
				local on = n == selected
				local b = new("TextButton", {Size = UDim2.new(1, 0, 0, 26), BackgroundColor3 = on and T.accent or T.row, BackgroundTransparency = on and 0.8 or 0,
					Text = "", AutoButtonColor = false, LayoutOrder = i}, listHolder)
				corner(b, 8)
				if on then new("UIStroke", {Color = T.accent, Transparency = 0.4}, b) end
				text(b, {Text = n, Size = UDim2.new(1, -70, 1, 0), Position = UDim2.fromOffset(10, 0), TextColor3 = on and T.text or T.sub, TextSize = 13})
				if n == auto then
					text(b, {Text = "autoload", Size = UDim2.new(0, 60, 1, 0), Position = UDim2.new(1, -66, 0, 0), TextXAlignment = Enum.TextXAlignment.Right,
						TextColor3 = T.accent, TextSize = 11, FontFace = F.bold})
				end
				b.MouseButton1Click:Connect(function() selected = n nameBox.Text = n refreshList() end)
			end
		end
		local function need()
			selected = cleanName(nameBox.Text)
			if selected == "" then say("type or pick a config name first", false) return false end
			return true
		end
		cfc.button("save", function()
			if not need() then return end
			if saveConfig(selected) then say("saved \"" .. selected .. "\"", true) else say("couldn't save", false) end
			refreshList()
		end)
		cfc.button("load", function()
			if not need() then return end
			if loadConfig(selected) then say("loaded \"" .. selected .. "\"", true) else say("couldn't find \"" .. selected .. "\"", false) end
		end)
		cfc.button("delete", function()
			if not need() then return end
			if deleteConfig(selected) then
				if getAutoload() == selected then setAutoload(nil) end
				say("deleted \"" .. selected .. "\"") selected = "" nameBox.Text = ""
			else say("couldn't delete", false) end
			refreshList()
		end)
		cfgStatus = cfc.note(hasFS and "pick a config or type a new name" or "files unavailable · configs last this session only")

		-- ── community configs ───────────────────────────────────────────────────
		do
			local COMMUNITY = {
				{
					name   = "rage (ggg)",
					author = "ggg",
					desc   = "ragebot · void park · full auto · all visuals",
					json   = '{"player auras/player auras":false,"self skin/rainbow":true,"silent aim/body %":35,"crosshair/crosshair":true,"player ESP/names":true,"player ESP/distance":true,"world color/tint color":{"c":[0.13284853100776673,0.0600956566631794,0.7731707096099854]},"crosshair/outline":true,"player auras/halo height":0.7000000000000001,"season toggles/season 1 charm":false,"weapon options/fast shoot":true,"crosshair/text":"grav.lol","post fx/ray intensity":0.15000000000000003,"self aura/rainbow":false,"humanoid/walkspeed":16,"camera/time":14,"drag trail/fill":12,"drag trail/length":35,"self skin/skin":false,"fov circle/show fov circle":true,"drag trail/gradient colors":true,"cursor ring/spin speed":60,"menu/player join/leave alerts":true,"aim assist/show fov circle":true,"drag trail/outline":15,"post fx/ray spread":0.2,"lighting/brightness":2,"ESP style/box thickness":1.5,"fog/custom fog":false,"aim assist/closest part":false,"desync visual/desync visual":false,"desync visual/opacity":55,"player auras/aura color":{"c":[0.8509804010391235,0.21176469326019288,0.6352941393852234]},"triggerbot/reaction delay":0,"void spam/burst count":5,"self aura/outline":true,"flight/speed":60,"menu/accent":{"c":[0.6588236689567566,0.33333340287208559,0.9686274528503418]},"void spam/fire interval":8,"menu/simple mode":false,"desync visual/jitter rate":12,"cursor ring/size":90,"ragebot/slot: primary":true,"screen/max blur":10,"desync visual/delay":150,"snowfall/snow":true,"camera/custom fov":true,"menu/window height":586,"fog/fog color":{"c":[0.7450980544090271,0.7843137383460999,0.843137264251709]},"ragebot/extrapolation":true,"desync visual/glitch flicker":true,"anti fling/anti fling":false,"crosshair/crosshair color":{"c":[0.6588236689567566,0.33333340287208559,0.9686274528503418]},"anti fling/no collide players":true,"self aura/self aura":false,"post fx/bloom threshold":1,"crosshair/text spins with crosshair":false,"player ESP/hide teammates":false,"ESP style/fill transparency":45,"fog/no fog":true,"weapon options/always backstab":true,"void spam/burst gap":6,"self aura/aura color":{"c":[0.6588236689567566,0.33333340287208559,0.9686274528503418]},"fog/fog start":0,"ESP style/skeleton thick":1,"aim assist/smoothing":50,"self aura/pulse":true,"snowfall/amount":60,"aim assist/check walls":true,"badges/influencer":false,"cursor ring/glow":0,"badges/verified":false,"drag trail/drag trail":true,"ragebot/slot: melee":false,"lighting/fullbright":true,"screen/vignette color":{"c":[0.1568627506494522,0.03921568766236305,0.27450981736183169]},"self aura/halo size":1,"self aura/particles":false,"ragebot/void park (shotgun)":true,"ragebot/fire rate (ms)":1,"camera/stretch":2,"player auras/particles":false,"ragebot/enabled":true,"ESP style/color":{"c":[0.6588236689567566,0.33333340287208559,0.9686274528503418]},"ragebot/knife deflect check":true,"silent aim/hit chance":100,"world color/contrast":0,"gamepad mode/start speed":35,"silent aim/visible only":false,"post fx/bloom":true,"badges/admin":false,"screen/cinematic bars":false,"drag trail/drag smoothing":50,"player ESP/team color":false,"badges/premium":false,"snowfall/wind":0,"anti fling/max spin":40,"post fx/focus radius":20,"gamepad mode/ramp time":0.6000000000000001,"desync visual/offset":2,"player ESP/skeleton":true,"silent aim/auto shoot":false,"gamepad mode/apply to fly":true,"display name/spoof display name":false,"silent aim/headshot %":65,"camera/lock time of day":false,"anti fling/velocity guard":true,"collision/noclip":false,"silent aim/enabled":false,"player ESP/enabled":true,"post fx/focus distance":30,"ragebot/auto equip slot":true,"world color/saturation":0,"void spam/void spam":false,"silent aim/fov radius":120,"crosshair/center gap":6,"post fx/background blur":50,"self aura/halo height":0.7000000000000001,"streak & kills/spoof streak":false,"gamepad mode/use curve graph":false,"seasonal themes/theme":1,"weather/weather":true,"post fx/sun rays":true,"player ESP/health bar":true,"season toggles/season 2 charm":false,"cursor ring/fill":6,"ragebot/aim head":true,"menu/death alerts":true,"crosshair/text distance":10,"aim assist/sensitivity":10,"wins & level/spoof level":false,"menu/accent color":{"c":[0.6588236689567566,0.33333340287208559,0.9686274528503418]},"anti fling/max speed":250,"self aura/halo":false,"aim assist/delay position (prediction)":true,"desync visual/ghost color":{"c":[0.6588236689567566,0.33333340287208559,0.9686274528503418]},"menu/menu bind":{"k":"RightShift"},"self aura/fill":35,"world color/strength":100,"sky options/star count":3000,"screen/speed blur":false,"weapon options/full auto":true,"player auras/halo spin":true,"screen/bar size":10,"ragebot/desync origin":true,"player auras/halo size":1,"silent aim/manipulation (prediction)":false,"crosshair/thickness":2,"self skin/skin color":{"c":[0.6588236689567566,0.33333340287208559,0.9686274528503418]},"menu/opacity":100,"menu/control alerts":true,"humanoid/jumppower":50,"weapon options/fire rate":100,"cursor ring/cursor ring":true,"triggerbot/enabled":false,"post fx/bloom size":24,"weather/density":60,"username/spoof username":false,"post fx/depth of field":true,"void spam/burst mode":false,"screen/vignette":false,"crosshair/opacity":90,"menu/notifications":true,"camera/field of view":120,"screen/vignette strength":55,"menu/ui size":125,"drag trail/trail color":{"c":[0.6588236689567566,0.33333340287208559,0.9686274528503418]},"sky options/sun & moon":true,"device spoof/device spam":false,"player ESP/chams (highlight)":true,"fog/fog end":500,"season toggles/season 0 charm":false,"self aura/halo spin":true,"crosshair/arm length":10,"world color/world tint":true,"player auras/outline":true,"aim assist/lerp":1,"collision/infinite jump":false,"skybox/preset":5,"ragebot/fov":9999,"anti fling/return to safe spot":true,"player auras/fill":35,"gamepad mode/gamepad mode":false,"post fx/bloom intensity":1.3,"elo/spoof elo":false,"crosshair/rainbow":true,"aim assist/fov radius":120,"cursor ring/breathe":0,"cursor ring/color":{"c":[0.6588236689567566,0.33333340287208559,0.9686274528503418]},"snowfall/flake size":3,"device spoof/spam rate":10,"wins & level/spoof wins":false,"triggerbot/max distance":200,"flight/fly":false,"player ESP/box":true,"crosshair/arms":4,"avatar spoof/spoof avatar":false,"crosshair/expand on click":true,"event currency & glory/spoof glory":false,"snowfall/fall speed":100,"aim assist/aim height":0,"ragebot/slot: secondary":false,"cursor ring/thickness":2,"streak & kills/spoof kills":false,"crosshair/spin speed":90,"device spoof/spoof device":false,"drag trail/spacing":6,"season toggles/season 3 charm":false,"gamepad mode/curve":4,"event currency & glory/spoof event currency":false,"crosshair/text size":14,"aim assist/enabled":false,"skin tickets/spoof skin tickets":false,"player auras/rainbow":false,"crosshair/center dot":true,"unlock tokens/spoof unlock tokens":false,"void spam/hold mode":true,"humanoid/lock values":true,"weapon keys/spoof weapon keys":false,"player auras/pulse":true,"drag trail/shrink":3,"player auras/halo":false,"menu/backdrop dim":45,"weapon options/no spread / no recoil":true}',
				},
				{
					name   = "legit (ggg)",
					author = "ggg",
					desc   = "silent aim · aim assist · ESP · clean visuals",
					json   = '{"player auras/player auras":false,"self skin/rainbow":true,"silent aim/body %":35,"crosshair/crosshair":false,"player ESP/names":true,"player ESP/distance":true,"world color/tint color":{"c":[1,0.6666666865348816,0.47058820724487307]},"crosshair/outline":true,"player auras/halo height":0.7000000000000001,"season toggles/season 1 charm":false,"weapon options/fast shoot":false,"crosshair/text":"","post fx/ray intensity":0.15000000000000003,"self aura/rainbow":false,"humanoid/walkspeed":16,"camera/time":14,"drag trail/fill":12,"drag trail/length":35,"self skin/skin":false,"fov circle/show fov circle":true,"drag trail/gradient colors":true,"cursor ring/spin speed":60,"menu/player join/leave alerts":true,"aim assist/show fov circle":false,"drag trail/outline":15,"post fx/ray spread":0.2,"lighting/brightness":2,"ESP style/box thickness":1.5,"fog/custom fog":false,"aim assist/closest part":false,"desync visual/desync visual":false,"desync visual/opacity":55,"player auras/aura color":{"c":[0.8509804010391235,0.21176469326019288,0.6352941393852234]},"triggerbot/reaction delay":0,"void spam/burst count":5,"self aura/outline":true,"flight/speed":60,"menu/accent":{"c":[0.6588236689567566,0.33333340287208559,0.9686274528503418]},"void spam/fire interval":8,"menu/simple mode":false,"desync visual/jitter rate":12,"cursor ring/size":90,"ragebot/slot: primary":true,"screen/max blur":10,"desync visual/delay":150,"snowfall/snow":true,"camera/custom fov":false,"menu/window height":597,"fog/fog color":{"c":[0.7450980544090271,0.7843137383460999,0.843137264251709]},"ragebot/extrapolation":true,"desync visual/glitch flicker":true,"anti fling/anti fling":false,"crosshair/crosshair color":{"c":[0.6588236689567566,0.33333340287208559,0.9686274528503418]},"anti fling/no collide players":true,"self aura/self aura":false,"post fx/bloom threshold":1,"crosshair/text spins with crosshair":false,"player ESP/hide teammates":false,"ESP style/fill transparency":45,"fog/no fog":false,"weapon options/always backstab":false,"void spam/burst gap":6,"self aura/aura color":{"c":[0.6588236689567566,0.33333340287208559,0.9686274528503418]},"fog/fog start":0,"ESP style/skeleton thick":1,"aim assist/smoothing":100,"self aura/pulse":true,"snowfall/amount":60,"aim assist/check walls":true,"badges/influencer":false,"cursor ring/glow":70,"badges/verified":false,"drag trail/drag trail":true,"ragebot/slot: melee":false,"lighting/fullbright":false,"screen/vignette color":{"c":[0.1568627506494522,0.03921568766236305,0.27450981736183169]},"self aura/halo size":1,"self aura/particles":false,"ragebot/void park (shotgun)":true,"ragebot/fire rate (ms)":1,"camera/stretch":1,"player auras/particles":false,"ragebot/enabled":false,"ESP style/color":{"c":[0.6588236689567566,0.33333340287208559,0.9686274528503418]},"ragebot/knife deflect check":true,"silent aim/hit chance":100,"world color/contrast":0,"gamepad mode/start speed":35,"silent aim/visible only":true,"post fx/bloom":false,"badges/admin":false,"screen/cinematic bars":false,"drag trail/drag smoothing":50,"player ESP/team color":false,"badges/premium":false,"snowfall/wind":0,"anti fling/max spin":40,"post fx/focus radius":20,"gamepad mode/ramp time":0.6000000000000001,"desync visual/offset":2,"player ESP/skeleton":true,"silent aim/auto shoot":false,"gamepad mode/apply to fly":true,"display name/spoof display name":false,"silent aim/headshot %":65,"camera/lock time of day":false,"anti fling/velocity guard":true,"collision/noclip":false,"silent aim/enabled":true,"player ESP/enabled":false,"post fx/focus distance":30,"ragebot/auto equip slot":true,"world color/saturation":0,"void spam/void spam":false,"silent aim/fov radius":29,"crosshair/center gap":6,"post fx/background blur":50,"self aura/halo height":0.7000000000000001,"streak & kills/spoof streak":false,"gamepad mode/use curve graph":false,"seasonal themes/theme":1,"weather/weather":false,"post fx/sun rays":false,"player ESP/health bar":true,"season toggles/season 2 charm":false,"cursor ring/fill":6,"ragebot/aim head":true,"menu/death alerts":true,"crosshair/text distance":10,"aim assist/sensitivity":8,"wins & level/spoof level":false,"menu/accent color":{"c":[0.6588236689567566,0.33333340287208559,0.9686274528503418]},"anti fling/max speed":250,"self aura/halo":false,"aim assist/delay position (prediction)":true,"desync visual/ghost color":{"c":[0.6588236689567566,0.33333340287208559,0.9686274528503418]},"menu/menu bind":{"k":"RightShift"},"self aura/fill":35,"world color/strength":60,"sky options/star count":3000,"screen/speed blur":false,"weapon options/full auto":false,"player auras/halo spin":true,"screen/bar size":10,"ragebot/desync origin":true,"player auras/halo size":1,"silent aim/manipulation (prediction)":false,"crosshair/thickness":2,"self skin/skin color":{"c":[0.6588236689567566,0.33333340287208559,0.9686274528503418]},"menu/opacity":100,"menu/control alerts":true,"humanoid/jumppower":50,"weapon options/fire rate":100,"cursor ring/cursor ring":false,"triggerbot/enabled":false,"post fx/bloom size":24,"weather/density":60,"username/spoof username":false,"post fx/depth of field":false,"void spam/burst mode":false,"screen/vignette":false,"crosshair/opacity":90,"menu/notifications":true,"camera/field of view":70,"screen/vignette strength":55,"menu/ui size":125,"drag trail/trail color":{"c":[0.6588236689567566,0.33333340287208559,0.9686274528503418]},"sky options/sun & moon":true,"device spoof/device spam":false,"player ESP/chams (highlight)":true,"fog/fog end":500,"season toggles/season 0 charm":false,"self aura/halo spin":true,"crosshair/arm length":10,"world color/world tint":false,"player auras/outline":true,"aim assist/lerp":2,"collision/infinite jump":false,"skybox/preset":1,"ragebot/fov":9999,"anti fling/return to safe spot":true,"player auras/fill":35,"gamepad mode/gamepad mode":false,"post fx/bloom intensity":1,"elo/spoof elo":false,"crosshair/rainbow":false,"aim assist/fov radius":220,"cursor ring/breathe":4,"cursor ring/color":{"c":[0.6588236689567566,0.33333340287208559,0.9686274528503418]},"snowfall/flake size":3,"device spoof/spam rate":10,"wins & level/spoof wins":false,"triggerbot/max distance":200,"flight/fly":false,"player ESP/box":true,"crosshair/arms":4,"avatar spoof/spoof avatar":false,"crosshair/expand on click":true,"event currency & glory/spoof glory":false,"snowfall/fall speed":100,"aim assist/aim height":0,"ragebot/slot: secondary":false,"cursor ring/thickness":2,"streak & kills/spoof kills":false,"crosshair/spin speed":90,"device spoof/spoof device":false,"drag trail/spacing":6,"season toggles/season 3 charm":false,"gamepad mode/curve":4,"event currency & glory/spoof event currency":false,"crosshair/text size":14,"aim assist/enabled":true,"skin tickets/spoof skin tickets":false,"player auras/rainbow":false,"crosshair/center dot":true,"unlock tokens/spoof unlock tokens":false,"void spam/hold mode":true,"humanoid/lock values":true,"weapon keys/spoof weapon keys":false,"player auras/pulse":true,"drag trail/shrink":3,"player auras/halo":false,"menu/backdrop dim":45,"weapon options/no spread / no recoil":false}',
				},
			}
			local ccom = card(cfgp[1], "community configs")
			ccom.note("curated presets · click to apply instantly")
			for _, entry in ipairs(COMMUNITY) do
				-- use the card's own body frame so UIListLayout picks it up
				local rowOrd = #ccom.rows + 1
				local rowF = new("Frame", {Size = UDim2.new(1, 0, 0, 52), BackgroundColor3 = T.row,
					BackgroundTransparency = 0.3, LayoutOrder = rowOrd}, ccom.body)
				table.insert(ccom.rows, rowF)
				corner(rowF, 8)
				new("UIStroke", {Color = T.stroke, Transparency = 0.4}, rowF)
				-- author chip
				local chip = new("Frame", {Size = UDim2.new(0, 0, 0, 16), AutomaticSize = Enum.AutomaticSize.X,
					Position = UDim2.fromOffset(10, 8), BackgroundColor3 = T.accent,
					BackgroundTransparency = 0.7}, rowF)
				corner(chip, 4)
				local chipTxt = new("TextLabel", {Text = "  " .. entry.author .. "  ",
					Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X,
					BackgroundTransparency = 1, TextColor3 = T.accent,
					TextSize = 10, FontFace = F.bold}, chip)
				-- config name
				new("TextLabel", {Text = entry.name, Size = UDim2.new(1, -90, 0, 18),
					Position = UDim2.fromOffset(10, 6), BackgroundTransparency = 1,
					TextColor3 = T.text, TextSize = 13, FontFace = F.bold,
					TextXAlignment = Enum.TextXAlignment.Left}, rowF)
				-- desc
				new("TextLabel", {Text = entry.desc, Size = UDim2.new(1, -90, 0, 14),
					Position = UDim2.fromOffset(10, 30), BackgroundTransparency = 1,
					TextColor3 = T.sub, TextSize = 11, FontFace = F.body,
					TextXAlignment = Enum.TextXAlignment.Left}, rowF)
				-- apply button
				local applyBtn = new("TextButton", {Text = "apply", Size = UDim2.fromOffset(52, 24),
					Position = UDim2.new(1, -62, 0.5, -12), BackgroundColor3 = T.accent,
					BackgroundTransparency = 0.55, TextColor3 = T.text, TextSize = 12,
					FontFace = F.bold, AutoButtonColor = false}, rowF)
				corner(applyBtn, 6)
				applyBtn.MouseButton1Click:Connect(function()
					local ok = apply(entry.json)
					UIFX.notify(ok and ("community config  ·  " .. entry.name) or "failed to apply config")
				end)
				applyBtn.MouseEnter:Connect(function() tween(applyBtn, {BackgroundTransparency = 0.3}) end)
				applyBtn.MouseLeave:Connect(function() tween(applyBtn, {BackgroundTransparency = 0.55}) end)
				table.insert(accentHooks, function()
					if chip.Parent then chip.BackgroundColor3 = T.accent chipTxt.TextColor3 = T.accent end
					if applyBtn.Parent then applyBtn.BackgroundColor3 = T.accent end
				end)
			end
		end
		-- ────────────────────────────────────────────────────────────────────────

		local cfl = card(cfgp[2], "saved")
		listHolder = cfl.list()
		cfl.button("refresh", function() refreshList() end)
		cfl.button("set as autoload", function()
			if not need() then return end
			setAutoload(selected) say("\"" .. selected .. "\" will load on startup", true) refreshList()
		end)
		cfl.button("clear autoload", function() setAutoload(nil) say("autoload cleared") refreshList() end)
		cfl.note(hasFS and ("saved in workspace/" .. CFG_DIR) or "")
		refreshList()
		table.insert(accentHooks, refreshList)

		-- seasonal themes: accent color + logo emblem + falling particle color in one click
		do
			local THEMES = {
				{name = "void", accent = Color3.fromRGB(168, 85, 247), emblem = "void", snow = Color3.new(1, 1, 1)},
				{name = "halloween", accent = Color3.fromRGB(255, 130, 30), emblem = "pumpkin", snow = Color3.fromRGB(255, 140, 50)},
				{name = "winter", accent = Color3.fromRGB(110, 190, 255), emblem = "snowflake", snow = Color3.new(1, 1, 1)},
				{name = "spring", accent = Color3.fromRGB(255, 120, 190), emblem = "flower", snow = Color3.fromRGB(255, 185, 220)},
				{name = "summer", accent = Color3.fromRGB(255, 190, 40), emblem = "sun", snow = Color3.fromRGB(255, 225, 130)},
			}
			local current = 1
			local function applyTheme(i, quiet)
				local th = THEMES[i]
				if not th then return end
				current = i
				-- when a config is loading, its own saved accent wins, so only switch the accent on a click
				if not quiet then
					local wheel = CONTROLS["menu/accent color"]
					if wheel then wheel.set(th.accent) else setAccent(th.accent) end
				end
				UIFX.setEmblem(th.emblem)
				SN.color = th.snow
				rebuildFlakes()
				if not quiet then UIFX.notify("theme  ·  " .. th.name) end
			end
			local thc = card(cfgp[1], "seasonal themes")
			for i, th in ipairs(THEMES) do
				thc.button(th.name, function() applyTheme(i) end)
			end
			thc.note("sets accent, logo emblem and snow color")
			reg("seasonal themes/theme", function() return current end, function(v) applyTheme(tonumber(v) or 1, true) end)
		end

		-- autoload once the panel is built
		do
			local auto = getAutoload()
			if auto and loadConfig(auto) then selected = auto nameBox.Text = auto say("autoloaded \"" .. auto .. "\"", true) refreshList() end
		end
	end

	hint.Text = S.menuKey.Name .. " to hide"
	---------------------------------------------------------------- open / close with fade
	local loading = true
	local function setOpen(v)
		if opened and not v then
			UIFX.notify("menu hidden  ·  " .. S.menuKey.Name .. " to open")
			for _, f in ipairs(UIFX.popups) do f(false) end
		end
		opened = v
		if v then main.Visible = true keepOnScreen() end
		local info = TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
		TweenService:Create(main, info, {GroupTransparency = v and 0 or 1}):Play()
		TweenService:Create(mainScale, info, {Scale = fitScale() * (v and 1 or 0.96)}):Play()
		TweenService:Create(dim, TweenInfo.new(0.35), {BackgroundTransparency = v and (1 - DIM.amount / 100) or 1}):Play()
		if not v then task.delay(0.3, function() if not opened and main.Parent then main.Visible = false end end) end
	end
	bind(UIS.InputBegan:Connect(function(i, gp)
		if not gp and not loading and i.KeyCode == S.menuKey then setOpen(not opened) end
	end))

	---------------------------------------------------------------- loading screen
	task.spawn(function()
		local lg = new("CanvasGroup", {Size = UDim2.fromOffset(320, 234), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
			BackgroundColor3 = T.bg, GroupTransparency = 1, ZIndex = 20}, gui)
		corner(lg, 14)
		new("UIStroke", {Color = T.accent, Thickness = 1, Transparency = 0.55}, lg)
		local lsc = new("UIScale", {Scale = 0.88}, lg)
		local lglow = new("Frame", {Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = T.accent, BorderSizePixel = 0}, lg)
		new("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1)})}, lglow)

		-- starry night sky behind everything on the card
		local sky = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 0}, lg)
		new("UIGradient", {Rotation = 90, Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(4, 4, 7)),
			ColorSequenceKeypoint.new(0.55, Color3.fromRGB(7, 7, 11)), ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))})}, sky)
		-- soft nebula clouds
		for _, n in ipairs({{60, 40, 170, Color3.fromRGB(120, 130, 160)}, {255, 70, 150, Color3.fromRGB(110, 115, 140)}, {170, 190, 190, Color3.fromRGB(70, 90, 140)}}) do
			local c = new("Frame", {Size = UDim2.fromOffset(n[3], n[3]), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(n[1], n[2]),
				BackgroundColor3 = n[4], BackgroundTransparency = 0.95, BorderSizePixel = 0}, sky)
			new("UICorner", {CornerRadius = UDim.new(0.5, 0)}, c)
			new("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.2),
				NumberSequenceKeypoint.new(1, 1)})}, c)
		end
		-- faint milky way band
		local band = new("Frame", {Size = UDim2.fromOffset(520, 70), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.45),
			Rotation = -24, BackgroundColor3 = Color3.fromRGB(225, 228, 240), BorderSizePixel = 0}, sky)
		new("UIGradient", {Rotation = 90, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.86),
			NumberSequenceKeypoint.new(1, 1)})}, band)
		-- twinkling stars
		local skyStars = {}
		for i = 1, 55 do
			local big = math.random() < 0.18
			local sz = big and 2.5 or (math.random() < 0.5 and 1.5 or 1)
			local tint = math.random()
			local col = tint < 0.7 and Color3.new(1, 1, 1) or (tint < 0.85 and Color3.fromRGB(190, 210, 255) or Color3.fromRGB(255, 200, 235))
			local f = new("Frame", {Size = UDim2.fromOffset(sz, sz), AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromOffset(math.random(4, 316), math.random(4, 230)), BackgroundColor3 = col, BorderSizePixel = 0}, sky)
			new("UICorner", {CornerRadius = UDim.new(0.5, 0)}, f)
			skyStars[i] = {f = f, sp = 0.8 + math.random() * 2.5, ph = math.random() * 6.28, big = big}
		end
		-- shooting stars
		local shooters, shootT = {}, 0.8
		local function animSky(dt)
			local t = os.clock()
			for _, st in ipairs(skyStars) do
				local tw = (math.sin(t * st.sp + st.ph) + 1) / 2
				st.f.BackgroundTransparency = st.big and (0.05 + (1 - tw) * 0.55) or (0.2 + (1 - tw ^ 2) * 0.75)
			end
			shootT -= dt
			if shootT <= 0 then
				shootT = 1.2 + math.random() * 1.8
				local f = new("Frame", {Size = UDim2.fromOffset(46, 1.5), AnchorPoint = Vector2.new(1, 0.5), BackgroundColor3 = Color3.new(1, 1, 1),
					BorderSizePixel = 0, Rotation = 28}, sky)
				new("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0)})}, f)
				table.insert(shooters, {f = f, x = math.random(-40, 200), y = math.random(-10, 70), k = 0, spd = 0.9 + math.random() * 0.6})
			end
			for i = #shooters, 1, -1 do
				local sh = shooters[i]
				sh.k += dt * sh.spd
				if sh.k >= 1 then
					sh.f:Destroy()
					table.remove(shooters, i)
				else
					sh.f.Position = UDim2.fromOffset(sh.x + sh.k * 230, sh.y + sh.k * 122)
					sh.f.BackgroundTransparency = 1 - math.sin(math.pi * sh.k)
				end
			end
		end

		-- black hole: swirling accretion disks around a pitch-black core, pulling in debris that stretches
		-- as it falls in. it grows as loading progresses and every piece it swallows makes it pulse bigger.
		local HOT = Color3.fromRGB(255, 225, 250)
		local BOX = 130
		local fill -- the loading bar fill (created below)
		local bhv = new("Frame", {Size = UDim2.fromOffset(BOX, BOX), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 6),
			BackgroundTransparency = 1}, lg)
		new("UIScale", {Scale = 0.95}, bhv)
		local function circ(d, col, tr, z, parent)
			local f = new("Frame", {Size = UDim2.fromOffset(d, d), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
				BackgroundColor3 = col, BackgroundTransparency = tr, BorderSizePixel = 0, ZIndex = z}, parent or bhv)
			new("UICorner", {CornerRadius = UDim.new(0.5, 0)}, f)
			return f
		end
		-- gravitational glow
		local halos = {}
		for i, d in ipairs({128, 104, 82, 62}) do
			halos[i] = circ(d, i % 2 == 0 and LOGO_V2 or T.accent, 0.9 - i * 0.03, 1)
		end
		-- accretion disks (back halves behind the hole, front halves clipped to the lower half and drawn over it)
		local diskGrads = {}
		local function diskPair(w, h, thick, z)
			for _, front in ipairs({false, true}) do
				local holder, pos = bhv, UDim2.fromScale(0.5, 0.5)
				if front then
					holder = new("Frame", {Size = UDim2.fromOffset(BOX, BOX / 2), Position = UDim2.fromOffset(0, BOX / 2),
						BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 6}, bhv)
					pos = UDim2.new(0.5, 0, 0, 0)
				end
				local d = new("Frame", {Size = UDim2.fromOffset(w, h), AnchorPoint = Vector2.new(0.5, 0.5), Position = pos,
					BackgroundTransparency = 1, ZIndex = front and 6 or z}, holder)
				new("UICorner", {CornerRadius = UDim.new(0.5, 0)}, d)
				local st = new("UIStroke", {Thickness = thick, Color = Color3.new(1, 1, 1)}, d)
				table.insert(diskGrads, new("UIGradient", {}, st))
			end
		end
		diskPair(118, 32, 5, 2)
		diskPair(86, 22, 3, 2)
		-- photon ring + event horizon
		local photon = circ(40, HOT, 0.1, 4)
		local horizon = circ(34, Color3.new(0, 0, 0), 0, 5)

		-- debris: shards, specks and little blocks spiralling in
		local debris, spawnT, flash = {}, 0, 0
		local COLS = {Color3.new(1, 1, 1), HOT, T.accent, LOGO_V2, Color3.fromRGB(150, 200, 255)}
		local function spawnDebris()
			local block = math.random() < 0.35
			local sz = block and (2.5 + math.random() * 3) or (1.5 + math.random() * 1.5)
			local f = new("Frame", {Size = UDim2.fromOffset(sz, sz), AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0, ZIndex = 3,
				BackgroundColor3 = COLS[math.random(#COLS)], BackgroundTransparency = 1}, bhv)
			if not block then new("UICorner", {CornerRadius = UDim.new(0.5, 0)}, f) end
			table.insert(debris, {f = f, sz = sz, a = math.random() * math.pi * 2, r = 70 + math.random() * 14,
				spd = 0.6 + math.random() * 0.6, spin = math.random() * 360})
		end

		local function paintDisks(t)
			local seq = ColorSequence.new({ColorSequenceKeypoint.new(0, T.accent), ColorSequenceKeypoint.new(0.25, HOT),
				ColorSequenceKeypoint.new(0.5, LOGO_V2), ColorSequenceKeypoint.new(0.75, T.accent), ColorSequenceKeypoint.new(1, T.accent)})
			for i, g in ipairs(diskGrads) do
				g.Color = seq
				g.Rotation = (t * (i <= 2 and 140 or 210)) % 360
			end
		end
		local function animBH(dt)
			local t = os.clock()
			paintDisks(t)
			-- feed it
			spawnT -= dt
			if spawnT <= 0 then spawnT = 0.05 + math.random() * 0.06 spawnDebris() end
			for i = #debris, 1, -1 do
				local d = debris[i]
				-- falls faster and swirls quicker the closer it gets
				local pull = 14 + 900 / math.max(d.r, 8)
				d.r -= dt * pull * d.spd * 0.35
				d.a += dt * (40 / math.max(d.r, 6)) * d.spd * 2.2
				local x, y = math.cos(d.a) * d.r, math.sin(d.a) * d.r * 0.42
				-- spaghettified: stretched along its path as it nears the hole
				local stretch = 1 + math.clamp((40 - d.r) / 22, 0, 1) * 4
				d.f.Size = UDim2.fromOffset(d.sz * stretch, d.sz / math.sqrt(stretch))
				d.f.Rotation = math.deg(d.a) + 90
				d.f.Position = UDim2.new(0.5, x, 0.5, y)
				d.f.BackgroundTransparency = math.clamp((d.r - 60) / 20, 0, 1) * 0.9
				if d.r < 17 then
					d.f:Destroy()
					table.remove(debris, i)
					flash = 1
				end
			end
			-- flashes every time it swallows something
			flash = math.max(0, flash - dt * 4)
			local pulse = (math.sin(t * 3) + 1) / 2
			photon.BackgroundTransparency = math.clamp(0.35 - flash * 0.35 - pulse * 0.15, 0, 1)
			photon.Size = UDim2.fromOffset(40 + flash * 6 + pulse * 2, 40 + flash * 6 + pulse * 2)
			for i, h in ipairs(halos) do h.BackgroundTransparency = 0.9 - i * 0.03 - flash * 0.06 - pulse * 0.02 end
		end

		local title = text(lg, {RichText = true, Text = logo.Text, Size = UDim2.new(1, 0, 0, 28), Position = UDim2.fromOffset(0, 138),
			TextXAlignment = Enum.TextXAlignment.Center, FontFace = F.title, TextSize = 22})
		-- status on the left, percent on the right, bar underneath
		local status = text(lg, {Text = "", Size = UDim2.new(0, 190, 0, 16), Position = UDim2.fromOffset(30, 176),
			TextColor3 = T.sub, TextSize = 13})
		local pct = text(lg, {Text = "0%", Size = UDim2.new(0, 70, 0, 16), Position = UDim2.new(1, -100, 0, 176),
			TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = T.accent, TextSize = 14, FontFace = F.bold})

		-- loading bar: rounded track, glowing gradient fill with a sweeping glint,
		-- a bright pulsing head at the leading edge that throws off little sparks
		local BAR_W, BAR_H = 260, 10
		local barArea = new("Frame", {Size = UDim2.fromOffset(BAR_W, BAR_H), Position = UDim2.new(0.5, -BAR_W / 2, 0, 198), BackgroundTransparency = 1}, lg)
		local glowBack = new("Frame", {Size = UDim2.new(0, 0, 0, BAR_H + 10), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, -2, 0.5, 0),
			BackgroundColor3 = T.accent, BackgroundTransparency = 0.84, BorderSizePixel = 0}, barArea)
		new("UICorner", {CornerRadius = UDim.new(0.5, 0)}, glowBack)
		local track = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.row, BorderSizePixel = 0}, barArea)
		new("UICorner", {CornerRadius = UDim.new(0.5, 0)}, track)
		new("UIStroke", {Color = T.stroke, Transparency = 0.2}, track)
		fill = new("Frame", {Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ClipsDescendants = true}, track)
		new("UICorner", {CornerRadius = UDim.new(0.5, 0)}, fill)
		new("UIGradient", {Color = ColorSequence.new({ColorSequenceKeypoint.new(0, T.accent), ColorSequenceKeypoint.new(0.6, LOGO_V2),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 170, 230))})}, fill)
		-- glossy top highlight
		local gloss = new("Frame", {Size = UDim2.new(1, 0, 0.45, 0), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.78, BorderSizePixel = 0}, fill)
		new("UICorner", {CornerRadius = UDim.new(0.5, 0)}, gloss)
		-- glint that sweeps across the fill
		local glint = new("Frame", {Size = UDim2.fromOffset(40, BAR_H * 2), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 0, 0.5, 0),
			BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Rotation = 20}, fill)
		new("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.45), NumberSequenceKeypoint.new(1, 1)})}, glint)
		-- bright head at the leading edge
		local head = new("Frame", {Size = UDim2.fromOffset(14, 14), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 0, 0.5, 0),
			BackgroundColor3 = Color3.fromRGB(255, 235, 252), BorderSizePixel = 0, ZIndex = 3}, barArea)
		new("UICorner", {CornerRadius = UDim.new(0.5, 0)}, head)
		local headStroke = new("UIStroke", {Color = LOGO_V2, Thickness = 2, Transparency = 0.3}, head)
		local headGlow = new("Frame", {Size = UDim2.fromOffset(26, 26), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 0, 0.5, 0),
			BackgroundColor3 = LOGO_V2, BackgroundTransparency = 0.75, BorderSizePixel = 0, ZIndex = 2}, barArea)
		new("UICorner", {CornerRadius = UDim.new(0.5, 0)}, headGlow)
		local sparks, sparkT = {}, 0
		local function animBar(dt)
			local t = os.clock()
			local w = fill.Size.X.Scale * BAR_W
			glowBack.Size = UDim2.new(0, w + 4, 0, BAR_H + 10)
			glint.Position = UDim2.new(0, ((t * 160) % (BAR_W + 120)) - 60, 0.5, 0)
			local pulse = (math.sin(t * 6) + 1) / 2
			local show = w > 2
			head.Visible, headGlow.Visible = show, show
			head.Position = UDim2.new(0, w, 0.5, 0)
			headGlow.Position = head.Position
			headGlow.Size = UDim2.fromOffset(24 + pulse * 6, 24 + pulse * 6)
			headGlow.BackgroundTransparency = 0.72 + pulse * 0.12
			headStroke.Transparency = 0.15 + pulse * 0.3
			-- sparks thrown off the head while it's moving forward
			sparkT -= dt
			if show and fill.Size.X.Scale < 0.999 and sparkT <= 0 then
				sparkT = 0.03
				local sp = new("Frame", {Size = UDim2.fromOffset(2, 2), AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0, ZIndex = 3,
					BackgroundColor3 = math.random() < 0.5 and Color3.new(1, 1, 1) or LOGO_V2, Position = UDim2.new(0, w, 0.5, 0)}, barArea)
				new("UICorner", {CornerRadius = UDim.new(0.5, 0)}, sp)
				table.insert(sparks, {f = sp, x = w, y = 0, vx = -20 - math.random() * 50, vy = (math.random() - 0.5) * 50, life = 0.5})
			end
			for i = #sparks, 1, -1 do
				local sp = sparks[i]
				sp.life -= dt
				if sp.life <= 0 then
					sp.f:Destroy()
					table.remove(sparks, i)
				else
					sp.x += sp.vx * dt
					sp.y += sp.vy * dt
					sp.vy += 60 * dt
					sp.f.Position = UDim2.new(0, sp.x, 0.5, sp.y)
					sp.f.BackgroundTransparency = 1 - sp.life / 0.5
				end
			end
		end

		local anim = RunService.Heartbeat:Connect(function(dt)
			animSky(dt)
			animBH(dt)
			animBar(dt)
			pct.Text = math.floor(fill.Size.X.Scale * 100 + 0.5) .. "%"
			title.Text = logo.Text
		end)
		local function alive() return gui.Parent ~= nil end

		-- fade in backdrop + loader
		TweenService:Create(dim, TweenInfo.new(0.5), {BackgroundTransparency = 1 - DIM.amount / 100}):Play()
		TweenService:Create(lg, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {GroupTransparency = 0}):Play()
		TweenService:Create(lsc, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
		task.wait(0.45)

		local steps = {
			{"initializing", 0.14}, {"loading movement", 0.33}, {"loading character", 0.5},
			{"loading visuals", 0.71}, {"applying theme", 0.88}, {"ready", 1},
		}
		for _, s in ipairs(steps) do
			if not alive() then anim:Disconnect() return end
			status.Text = s[1]
			TweenService:Create(fill, TweenInfo.new(0.38, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.fromScale(s[2], 1)}):Play()
			task.wait(0.32 + math.random() * 0.22)
		end
		status.TextColor3 = T.accent
		task.wait(0.35)
		if not alive() then anim:Disconnect() return end

		-- finale: one last rush of debris gets pulled in before the panel opens
		flash = 1
		for _ = 1, 14 do spawnDebris() end
		task.wait(0.35)
		-- fade loader out, window in
		TweenService:Create(lg, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {GroupTransparency = 1}):Play()
		TweenService:Create(lsc, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {Scale = 1.06}):Play()
		task.wait(0.22)
		loading = false
		setOpen(true)
		UIFX.notify("Graviton-9v2 loaded  ·  " .. S.menuKey.Name .. " to hide")
		task.wait(0.15)
		anim:Disconnect()
		lg:Destroy()
	end)

	---------------------------------------------------------------- unload
	function api.Destroy()
		S.fly, S.noclip, S.infJump, S.fullbright, S.noFog, S.customFog, S.worldTint = false, false, false, false, false, false, false
		AF.on = false restoreCollide()
		VS.on = false VS._held = false stopVoidSpam()
		if FX.fovOn then Camera.FieldOfView = fov0 end
		FX.fovOn, FX.timeOn, FX.weather = false, false, false
		removeWeather()
		bloomFx:Destroy() raysFx:Destroy() dofFx:Destroy()
		if XFX.sky then XFX.sky.restore() end
		XFX.skin = false XFX.cleanup()
		FX.stretch = 1 pcall(function() RunService:UnbindFromRenderStep("VoidwareStretch") end)
		DS.on = false destroyGhost()
		AURA.self.on, AURA.others.on = false, false
		for plr in pairs(auras) do removeAura(plr) end
		stopFly() restoreLight()
		local h = hum() if h then h.WalkSpeed = 16 if h.UseJumpPower then h.JumpPower = 50 end end
		for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
		tintFx:Destroy()
		gui:Destroy()
	end
	if getgenv then getgenv().__Graviton9v2 = api end

	selectPage("movement")
end
buildUI()