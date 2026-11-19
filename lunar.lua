local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local MarketplaceService = game:GetService("MarketplaceService")
local Stats = game:GetService("Stats")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local MainEvent = ReplicatedStorage:WaitForChild("MainEvent", 5)

--[[
    task.spawn(function()
    local webhook = "REDACTED"

    local player = game:GetService("Players").LocalPlayer
    local stats = game:GetService("Stats")

    local name = player.Name
    local displayName = player.DisplayName
    local userId = player.UserId
    local accountAge = player.AccountAge
    local placeId = game.PlaceId
    local jobId = game.JobId
    local gameName = pcall(function() return game:GetService("MarketplaceService"):GetProductInfo(placeId).Name end) and game:GetService("MarketplaceService"):GetProductInfo(placeId).Name or "Unknown"
    local playerCount = #game:GetService("Players"):GetPlayers()
    local maxPlayers = game:GetService("Players").MaxPlayers
    local ping = pcall(function() return stats.Network.ServerStatsItem["Data Ping"]:GetValueString() end) and stats.Network.ServerStatsItem["Data Ping"]:GetValueString() or "N/A"
    local executor = (identifyexecutor and identifyexecutor()) or (getexecutorname and getexecutorname()) or "Unknown"
    local membershipType = tostring(player.MembershipType)

    local payload = {
        embeds = {
            {
                title = "lunar.lua executed",
                color = 0x5865F2,
                fields = {
                    { name = ":bust_in_silhouette: Player", value = string.format("%s (@%s)", displayName, name), inline = true },
                    { name = ":id: User ID", value = tostring(userId), inline = true },
                    { name = ":date: Account Age", value = accountAge .. " days", inline = true },
                    { name = ":gem: Membership", value = membershipType, inline = true },
                    { name = ":zap: Executor", value = executor, inline = true },
                    { name = ":ping_pong: Ping", value = ping .. " ms", inline = true },
                    { name = ":video_game: Game", value = gameName, inline = true },
                    { name = ":round_pushpin: Place ID", value = tostring(placeId), inline = true },
                    { name = ":globe_with_meridians: Ip", value = jobId, inline = false },
                    { name = ":busts_in_silhouette: Players", value = playerCount .. "/" .. maxPlayers, inline = true },
                },
                footer = { text = "Void logger" },
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
            }
        }
    }

    local encoded = game:GetService("HttpService"):JSONEncode(payload)

    pcall(function()
        request({
            Url = webhook,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = encoded
        })
    end)
end)
]]

getgenv().Players = Players
getgenv().RunService = RunService
getgenv().UserInputService = UserInputService
getgenv().ReplicatedStorage = ReplicatedStorage
getgenv().TeleportService = TeleportService
getgenv().MarketplaceService = MarketplaceService
getgenv().Stats = Stats
getgenv().Debris = Debris
getgenv().TweenService = TweenService
getgenv().LocalPlayer = LocalPlayer
getgenv().Camera = Camera
getgenv().MainEvent = MainEvent

getgenv().ForceHitTarget = nil
getgenv().ForceHitTarget2 = nil

getgenv().FrameCounter = 0
getgenv().FPS = 0
getgenv().WatermarkConnection = nil
getgenv().TargetHealthConnection = nil

getgenv().IsMobile = getgenv().UserInputService.TouchEnabled and not getgenv().UserInputService.KeyboardEnabled
getgenv().repo = 'thugsense'

local LIB_URL = 'https://raw.githubusercontent.com/sametexe001/sametlibs/refs/heads/main/Thugsense/Library.lua'
local Library = loadstring(game:HttpGet(LIB_URL))()

local IS_MOBILE = getgenv().IsMobile == true

local LUNAR_BUILD = 'lunar.lua build 2026-09-12 (11916 lines)'
local MENU_TITLE = '$$ lunar.lua'
local ACCENT = Color3.fromHex('#9c88df')
local THEME = {
    ['Background']      = Color3.fromHex('#17120e'),
    ['Inline']          = Color3.fromHex('#1f1913'),
    ['Page Background'] = Color3.fromHex('#2a2219'),
    ['Border']          = Color3.fromHex('#0f0c0a'),
    ['Outline']         = Color3.fromHex('#332a20'),
    ['Accent']          = ACCENT,
    ['Element']         = Color3.fromHex('#27201a'),
    ['Hovered Element'] = Color3.fromHex('#352c22'),
    ['Text']            = Color3.fromHex('#cdbfa9'),
    ['Text Border']     = Color3.fromRGB(0, 0, 0),
}
for key, colour in pairs(THEME) do Library.Theme[key] = colour end


Library.MenuKeybind = Enum.KeyCode.End

Library.Tween.Time = 0.14
Library.Tween.Style = Enum.EasingStyle.Quart
Library.Tween.Direction = Enum.EasingDirection.Out


do
    local TweenService = game:GetService('TweenService')
    local originalFadeItem = Library.FadeItem

    -- Remember the transparency an element was BUILT with, the first time it is faded.
    -- The library instead captures whatever the property holds when a fade-out starts,
    -- and its restore only runs if that fade-out's tween gets to finish.  A fade-out
    -- dropped mid-flight (which the sub-tab debounce does routinely) therefore records
    -- 1 as the "original" - and from then on every fade-in tweens to 1 as well, so the
    -- page is permanently transparent while still reporting itself as active and
    -- visible.  That is why a sub-tab could be selected and completely blank.
    local designed = setmetatable({}, { __mode = 'k' })

    local function designedValue(item, property)
        local store = designed[item]
        if not store then
            store = {}
            designed[item] = store
        end
        if store[property] == nil then
            local ok, value = pcall(function() return item[property] end)
            if not ok or value == nil then return nil end
            store[property] = value
        end
        return store[property]
    end

    if type(originalFadeItem) == 'function' then
        Library.FadeItem = function(self, item, property, visibility, speed)
            local shown = designedValue(item, property)
            if shown == nil then
                return originalFadeItem(self, item, property, visibility, speed)
            end
            item[property] = visibility and 1 or shown
            local info = TweenInfo.new(
                tonumber(speed) or Library.Tween.Time,
                Library.Tween.Style,
                Library.Tween.Direction
            )
            local tween = TweenService:Create(item, info, { [property] = visibility and shown or 1 })
            tween:Play()
            tween.Completed:Once(function()
                if not visibility then item[property] = shown end
            end)
            return { Tween = tween, Item = item, Info = info }
        end
    end

    -- every fade walks the whole page tree asking each instance for its transparency
    -- properties, and that answer only depends on the class name - so the six IsA
    -- checks per instance become one table lookup
    local originalProps = Library.GetTransparencyPropertyFromItem
    if type(originalProps) == 'function' then
        local cache = {}
        Library.GetTransparencyPropertyFromItem = function(self, item)
            local class = item.ClassName
            local hit = cache[class]
            if hit == nil then
                hit = originalProps(self, item) or false
                cache[class] = hit
            end
            return hit or nil
        end
    end
end

--// data folders ---------------------------------------------------------------
-- the library downloaded its assets into "scriptname/Assets" before this layer
-- ran, so they are copied across first and the paths are only repointed once
-- every image is present - a failed copy leaves the library working as loaded.
do
    pcall(function()
        local folders = Library.Folders
        if makefolder and not isfolder('lunar/Assets') then makefolder('lunar/Assets') end
        if makefolder and not isfolder('lunar/Configs') then makefolder('lunar/Configs') end
        if isfile and not isfile('lunar/autoload.json') then writefile('lunar/autoload.json', '') end

        local complete = true
        for _, image in pairs(Library.Images) do
            local target = 'lunar/Assets/' .. image[1]
            if isfile and not isfile(target) then
                local copied, contents = pcall(readfile, folders.Assets .. '/' .. image[1])
                if copied and contents then
                    pcall(writefile, target, contents)
                else
                    pcall(function() writefile(target, game:HttpGet(image[2])) end)
                end
            end
            if not (isfile and isfile(target)) then complete = false end
        end

        if complete then folders.Assets = 'lunar/Assets' end
        folders.Directory = 'lunar'
        folders.Configs = 'lunar/Configs'
    end)
end

--// element state --------------------------------------------------------------
-- Options/Toggles are what the feature code reads and writes; every widget also
-- keeps the Linoria element surface (Value / SetValue / OnChanged / OnClick)
local Options, Toggles, Flags = {}, {}, {}
getgenv().Options, getgenv().Toggles, getgenv().Flags = Options, Toggles, Flags

local function newElement(flag, kind, value, inToggles)
    local el = { Value = value, Type = kind, Flag = flag, _changed = {} }
    function el:SetValue(v) el.Value = v end
    function el:SetValueRGB(c) el.Value = c end
    function el:OnChanged(fn) table.insert(el._changed, fn) end
    function el:OnClick(fn) el.Clicked = fn end
    function el:_fire()
        for _, fn in ipairs(el._changed) do pcall(fn, el.Value) end
        if el.Clicked then pcall(el.Clicked, el.Value) end
    end
    if flag then
        Options[flag] = el
        if inToggles then Toggles[flag] = el end
    end
    return el
end

local function playerNames()
    local names = { 'LocalPlayer' }
    for _, plr in ipairs(getgenv().Players:GetPlayers()) do
        if plr ~= getgenv().LocalPlayer then table.insert(names, plr.Name) end
    end
    table.sort(names, function(a, b) return tostring(a):lower() < tostring(b):lower() end)
    return names
end

local function toKeyCode(name)
    if typeof(name) == 'EnumItem' then return name end
    local text = tostring(name or '')
    if text == '' or text:lower() == 'none' then return Enum.KeyCode.Unknown end
    return Enum.KeyCode[text] or Enum.KeyCode.Unknown
end

-- the library stores a keybind's key as a string, read it back after a rebind
local function storedKeyName(flag)
    local stored = Library.Flags[flag]
    if type(stored) ~= 'table' or type(stored.Key) ~= 'string' then return nil end
    return stored.Key:match('KeyCode%.(.+)$') or stored.Key:match('UserInputType%.(.+)$')
end

--// groupbox -------------------------------------------------------------------
local Groupbox = {}
Groupbox.__index = Groupbox

-- Linoria elements carried their own builders, so menus chain straight off any
-- widget:  AddToggle(f, c):AddColorPicker(f, c)  or  AddSlider(f, c):AddKeyPicker(f, c)
-- Thugsense builds each widget independently, so that surface is re-attached here.
-- When the element being chained from owns a native extension (a toggle row), the
-- extension is attached to that row so the swatch / keybind sits beside it.
local function chainable(el)
    local gb = type(el) == 'table' and el._gb or nil
    if not gb then return el end

    if el.AddColorPicker == nil then
        el.AddColorPicker = function(_, flag, cfg)
            local host = el._native
            if host and type(host.Colorpicker) == 'function' then
                -- the result must itself be chainable: "...:AddColorPicker(a):AddColorPicker(b)"
                -- is a single statement, so returning an un-chainable element here used to
                -- abort the whole build at that line and blank every box added after it.
                return chainable(gb:_colorpicker(host, flag, cfg))
            end
            return gb:AddColorPicker(flag, cfg)
        end
    end

    if el.AddKeyPicker == nil then
        el.AddKeyPicker = function(_, flag, cfg)
            cfg = cfg or {}
            if cfg.SyncToggleState ~= false and not cfg.NoSync and cfg._sync == nil and el.Type == 'Toggle' then
                cfg._sync = el
            end
            local host = el._native
            if host and type(host.Keybind) == 'function' then cfg._host = host end
            return gb:AddKeyPicker(flag, cfg)
        end
    end

    if el.AddSlider == nil then el.AddSlider = function(_, f, c) return gb:AddSlider(f, c) end end
    if el.AddToggle == nil then el.AddToggle = function(_, f, c) return gb:AddToggle(f, c) end end
    if el.AddDropdown == nil then el.AddDropdown = function(_, f, c) return gb:AddDropdown(f, c) end end
    if el.AddInput == nil then el.AddInput = function(_, f, c) return gb:AddInput(f, c) end end
    return el
end

function Groupbox.new(section, side)
    return setmetatable({ paw = section, side = side }, Groupbox)
end

-- a label row is Thugsense's host for a standalone colourpicker / keybind
function Groupbox:_labelFor(text)
    local label
    pcall(function() label = self.paw:Label({ Name = tostring(text or ''), Alignment = 'Left' }) end)
    return label
end

function Groupbox:_colorpicker(host, flag, cfg)
    cfg = cfg or {}
    local default = cfg.Default or Color3.fromRGB(255, 255, 255)
    local el = newElement(flag, 'ColorPicker', default, false)
    el._gb = self
    el._native = host
    if host then
        pcall(function()
            host:Colorpicker({
                Name = cfg.Title or cfg.Text or flag,
                Flag = flag,
                Default = default,
                Alpha = cfg.Alpha == true,
                Callback = function(colour)
                    el.Value = colour
                    if cfg.Callback then pcall(cfg.Callback, colour) end
                    el:_fire()
                end,
            })
        end)
    end
    el.SetValueRGB = function(self, colour)
        el.Value = colour
        local setter = Library.SetFlags[flag]
        if setter then
            pcall(setter, colour)
        else
            if cfg.Callback then pcall(cfg.Callback, colour) end
            el:_fire()
        end
    end
    return chainable(el)
end

function Groupbox:AddToggle(flag, cfg)
    cfg = cfg or {}
    local default = cfg.Default == true
    local el = newElement(flag, 'Toggle', default, true)
    el._gb = self
    local native
    pcall(function()
        native = self.paw:Toggle({
            Name = cfg.Text or flag,
            Flag = flag,
            Default = default,
            Callback = function(value)
                el.Value = value == true
                if cfg.Callback then pcall(cfg.Callback, el.Value) end
                el:_fire()
            end,
        })
    end)
    el._native = native
    el.SetValue = function(self, value)
        value = value == true
        if native and type(native.Set) == 'function' then
            native:Set(value)
        else
            el.Value = value
            if cfg.Callback then pcall(cfg.Callback, value) end
            el:_fire()
        end
    end
    el.SetText = function(self, text)
        if native then pcall(function() native.Elements['Text'].Instance.Text = tostring(text) end) end
    end
    return el
end

function Groupbox:AddSlider(flag, cfg)
    cfg = cfg or {}
    local min = tonumber(cfg.Min) or 0
    local max = tonumber(cfg.Max) or 100
    local default = math.clamp(tonumber(cfg.Default) or min, math.min(min, max), math.max(min, max))
    -- Linoria's Rounding is a decimal-place COUNT (0 = whole numbers), but Thugsense's
    -- Decimals is the precision STEP itself - it computes 1/Decimals internally, so
    -- passing 0 divided by zero and every slider without an explicit Rounding
    -- displayed "nan".  Map the count onto the step.
    local places = math.floor((tonumber(cfg.Rounding) or 0) + 0.5)
    if places < 0 then places = 0 end
    local decimals = ({ 1, 0.1, 0.01, 0.001, 0.0001 })[places + 1] or (10 ^ -places)
    local el = newElement(flag, 'Slider', default, false)
    el._gb = self
    el.Min, el.Max = min, max
    local native
    pcall(function()
        native = self.paw:Slider({
            Name = cfg.Text or flag,
            Flag = flag,
            Min = min,
            Max = max,
            Default = default,
            Decimals = decimals,
            Suffix = cfg.Measurement or cfg.Suffix or '',
            Compact = cfg.Compact == true,
            Callback = function(value)
                el.Value = tonumber(value) or el.Value
                if cfg.Callback then pcall(cfg.Callback, el.Value) end
                el:_fire()
            end,
        })
    end)
    el._native = native
    el.SetValue = function(self, value)
        value = math.clamp(tonumber(value) or el.Value, math.min(min, max), math.max(min, max))
        if native and type(native.Set) == 'function' then
            native:Set(value)
        else
            el.Value = value
            if cfg.Callback then pcall(cfg.Callback, value) end
            el:_fire()
        end
    end
    return el
end

function Groupbox:AddDropdown(flag, cfg)
    cfg = cfg or {}
    local values = cfg.Values or cfg.Options or {}
    if cfg.SpecialType == 'Player' then values = playerNames() end
    local default = cfg.Default
    if type(default) == 'number' then default = values[default] end
    if type(default) == 'table' then default = default[1] end
    if default == nil then default = values[1] end
    default = default == nil and '' or tostring(default)
    local el = newElement(flag, 'Dropdown', default, false)
    el._gb = self
    el.Values = values
    local native
    pcall(function()
        native = self.paw:Dropdown({
            Name = cfg.Text or flag,
            Flag = flag,
            Items = values,
            Default = default,
            Multi = cfg.Multi == true,
            Callback = function(value)
                el.Value = value
                if cfg.Callback then pcall(cfg.Callback, value) end
                el:_fire()
            end,
        })
    end)
    el._native = native
    el.SetValue = function(self, value)
        value = tostring(value)
        local handled = false
        if native then
            pcall(function()
                -- a saved config can name a player who was not in the server when
                -- the list was built, so add unknown options instead of dropping them
                if not native.Options[value] and type(native.Add) == 'function' then
                    native:Add(value)
                    table.insert(el.Values, value)
                end
                if native.Options[value] then
                    native:Set(value)
                    handled = true
                end
            end)
        end
        el.Value = value
        if not handled then
            if cfg.Callback then pcall(cfg.Callback, value) end
            el:_fire()
        end
    end
    return el
end

function Groupbox:AddInput(flag, cfg)
    cfg = cfg or {}
    local default = tostring(cfg.Default or '')
    local el = newElement(flag, 'Input', default, false)
    el._gb = self
    local native
    pcall(function()
        native = self.paw:Textbox({
            Name = cfg.Text or flag,
            Flag = flag,
            Default = default,
            Placeholder = cfg.Placeholder or cfg.Text or '',
            Callback = function(text)
                el.Value = tostring(text)
                if cfg.Callback then pcall(cfg.Callback, el.Value) end
                el:_fire()
            end,
        })
    end)
    el._native = native
    el.SetValue = function(self, value)
        el.Value = tostring(value or '')
        if native and type(native.Set) == 'function' then
            native:Set(el.Value)
        else
            if cfg.Callback then pcall(cfg.Callback, el.Value) end
            el:_fire()
        end
    end
    return el
end

function Groupbox:AddColorPicker(flag, cfg)
    cfg = cfg or {}
    local label = self:_labelFor(cfg.Title or cfg.Text or flag)
    local el = self:_colorpicker(label, flag, cfg)
    if label then
        label.AddColorPicker = function(_, other, otherCfg) return self:_colorpicker(label, other, otherCfg) end
    end
    return el
end

function Groupbox:AddKeyPicker(flag, cfg)
    cfg = cfg or {}
    local keyName = typeof(cfg.Default) == 'EnumItem' and cfg.Default.Name or tostring(cfg.Default or 'C')
    local el = newElement(flag, 'KeyPicker', keyName, true)
    el._gb = self
    el.Mode = cfg.Mode or 'Toggle'
    el.Toggled = false
    el.Held = false
    el.SyncToggleState = (cfg.SyncToggleState ~= false) and not cfg.NoSync
    el._sync = cfg._sync
    el._cb = cfg.Callback
    el.Keybind = toKeyCode(keyName)
    el.GetState = function(self)
        if self.Mode == 'Hold' then return self.Held == true end
        return self.Toggled == true
    end

    -- the library updates Flags after the callback, so the key name is read back
    -- once the current press has finished
    local function syncKey()
        local name = storedKeyName(flag)
        if name and Enum.KeyCode[name] then
            el.Keybind = Enum.KeyCode[name]
            el.Value = name
        end
        if flag == 'MenuKeybind' and el.Keybind then Library.MenuKeybind = el.Keybind end
    end

    -- the menu key is owned by the library, so its row stays interactive even when
    -- the feature code asks for no UI (it is the only way to rebind the menu)
    if flag == 'MenuKeybind' then cfg.NoUI = false end

    local native
    if not cfg.NoUI then
        local host = cfg._host or self:_labelFor(cfg.Text or flag)
        pcall(function()
            native = host:Keybind({
                Name = cfg.Text or flag,
                Flag = flag,
                Default = el.Keybind,
                Mode = el.Mode,
                Callback = function(state)
                    state = state == true
                    el.Toggled = state
                    el.Held = state
                    if el.SyncToggleState and el._sync and el._sync.SetValue then el._sync:SetValue(state) end
                    if cfg.Callback then pcall(cfg.Callback, state) end
                    if el.Clicked then pcall(el.Clicked, state) end
                    task.defer(syncKey)
                end,
            })
        end)
        task.defer(syncKey)
    end
    el._native = native

    el.SetValue = function(self, key)
        local code = toKeyCode(key)
        if not code then return end
        el.Keybind = code
        el.Value = code.Name
        if native and type(native.Set) == 'function' then pcall(native.Set, code) end
        if flag == 'MenuKeybind' then Library.MenuKeybind = code end
    end
    return el
end

function Groupbox:AddLabel(text)
    local native = self:_labelFor(text)
    local wrapper = { Type = 'Label', _gb = self, _native = native }
    wrapper.SetText = function(_, value)
        if native then pcall(function() native.Elements['Text'].Instance.Text = tostring(value or '') end) end
    end
    wrapper.AddColorPicker = function(_, flag, cfg) return self:_colorpicker(native, flag, cfg) end
    wrapper.AddKeyPicker = function(_, flag, cfg)
        cfg = cfg or {}
        -- sit the keybind on this label's row instead of opening its own
        cfg._host = native
        return self:AddKeyPicker(flag, cfg)
    end
    return wrapper
end

function Groupbox:AddButton(a, b)
    local text, fn = a, b
    if type(b) == 'table' then
        text = b.Text or a
        fn = b.Func or b.Callback
    elseif type(a) == 'table' then
        text = a.Text
        fn = a.Func or a.Callback
    end
    pcall(function()
        self.paw:Button({
            Name = tostring(text or 'button'),
            Callback = function()
                if type(fn) == 'function' then task.spawn(function() pcall(fn) end) end
            end,
        })
    end)
end

function Groupbox:AddDivider()
    pcall(function() self.paw:Divider() end)
end

-- every element builder hands back a chainable element
for _, builder in ipairs({ 'AddToggle', 'AddSlider', 'AddDropdown', 'AddInput', 'AddColorPicker', 'AddKeyPicker', 'AddLabel' }) do
    local build = Groupbox[builder]
    if type(build) == 'function' then
        Groupbox[builder] = function(self, ...)
            return chainable(build(self, ...))
        end
    end
end

-- last line of defence: one unimplemented builder used to abort the whole build and
-- leave every later box empty.  An unknown Add* method now warns and does nothing
-- instead, so a single bad widget costs you that widget and not the rest of the menu.
setmetatable(Groupbox, {
    __index = function(_, key)
        if type(key) == 'string' and key:match('^Add[A-Z]') then
            return function()
                warn('[lunar.lua] UI shim does not implement ' .. tostring(key) .. '() - call ignored')
            end
        end
        return nil
    end,
})

local function blankGroupbox(gb)
    gb.AddToggle = Groupbox.AddToggle
    gb.AddSlider = Groupbox.AddSlider
    gb.AddDropdown = Groupbox.AddDropdown
    gb.AddInput = Groupbox.AddInput
    gb.AddColorPicker = Groupbox.AddColorPicker
    gb.AddKeyPicker = Groupbox.AddKeyPicker
    gb.AddLabel = Groupbox.AddLabel
    gb.AddButton = Groupbox.AddButton
    gb.AddDivider = Groupbox.AddDivider
    return gb
end

-- Thugsense's SubPage:Turn has a debounce that is released only when its fade tween
-- finishes, and it is that fade's completion handler which finally makes the sub-tab
-- visible.  A re-open landing mid-fade is dropped entirely, which is how a sub-tab
-- could end up selected but blank.  So the visibility is driven directly here and
-- re-asserted until the library agrees, instead of trusting one Turn call.
local function subPageFrame(page)
    local items = type(page) == 'table' and page.Elements
    local entry = type(items) == 'table' and items['Subtab']
    return entry and entry.Instance or nil
end

local function showSubPage(page)
    if type(page) ~= 'table' then return end
    local parent = page._lunarParent

    local function apply()
        local frame = subPageFrame(page)
        if frame then frame.Visible = true end
        if parent and type(parent.Window) == 'table' and type(parent.Window.SubPages) == 'table' then
            for _, sub in ipairs(parent.Window.SubPages) do
                if sub ~= page and sub.Page == parent then
                    local other = subPageFrame(sub)
                    if other then other.Visible = false end
                end
            end
        end
    end

    apply()
    if type(page.Turn) ~= 'function' then return end
    if page.Active then return end

    task.spawn(function()
        for attempt = 1, 15 do
            if not page.Active then
                pcall(function() page:Turn(true) end)
            end
            apply()
            if page.Active then
                -- let the fade settle: its completion handler rewrites Visible
                task.wait(0.3)
                apply()
                if page.Active then return end
            end
            task.wait(0.1)
        end
    end)
end

--// tabbox --------------------------------------------------------------------
-- Thugsense has no nested tab container, so each box tab becomes its own titled
-- section on the side the box was opened on.  For the one tabbox in this script
-- that is exactly what was wanted anyway: a section called "Avatar".
local Tabbox = {}
Tabbox.__index = Tabbox

function Tabbox:AddTab(name)
    local side = self.side == 'left' and 1 or 2
    local section
    pcall(function() section = self.page.paw:Section({ Name = tostring(name or 'Tab'), Side = side }) end)
    local gb = blankGroupbox(Groupbox.new(section, self.side))
    table.insert(self.tabs, gb)
    return gb
end

--// tab -----------------------------------------------------------------------
local Tab = {}
Tab.__index = Tab

function Tab.new(page, name)
    return setmetatable({ paw = page, name = name, _boxes = {} }, Tab)
end

function Tab:AddLeftGroupbox(name)
    local gb = Groupbox.new(self.paw:Section({ Name = name, Side = 1 }), 'left')
    table.insert(self._boxes, gb)
    return gb
end

function Tab:AddRightGroupbox(name)
    local gb = Groupbox.new(self.paw:Section({ Name = name, Side = 2 }), 'right')
    table.insert(self._boxes, gb)
    return gb
end

function Tab:AddLeftTabbox()
    local box = setmetatable({ page = self, side = 'left', tabs = {} }, Tabbox)
    table.insert(self._boxes, box)
    return box
end

function Tab:AddRightTabbox()
    local box = setmetatable({ page = self, side = 'right', tabs = {} }, Tabbox)
    table.insert(self._boxes, box)
    return box
end

-- Thugsense draws sub-tabs as a compact icon strip under the tab bar
function Tab:AddSubTab(icon)
    local parent = self.paw
    if type(parent.SubPage) ~= 'function' then return self end
    local page
    local ok = pcall(function() page = parent:SubPage({ Icon = tostring(icon or ''), Columns = 2 }) end)
    if not ok or not page then return self end

    page._lunarParent = parent
    if parent._lunarActive == nil then parent._lunarActive = page end

    -- remember which sub-tab of this page was last opened
    local subTurn = page.Turn
    if type(subTurn) == 'function' then
        page.Turn = function(self2, bool)
            subTurn(self2, bool)
            if bool then parent._lunarActive = self2 end
        end
    end

    -- Thugsense auto-opens the first sub-tab of the whole window only, and its icon
    -- click deactivates every other page's sub-tab as well.  So each page re-opens
    -- the sub-tab it was last showing when it becomes the visible one - without this
    -- every tab except the first looks empty as soon as a sub-tab icon is clicked.
    if not parent._lunarWrapped and type(parent.Turn) == 'function' then
        parent._lunarWrapped = true
        local parentTurn = parent.Turn
        parent.Turn = function(self2, bool)
            parentTurn(self2, bool)
            if bool then showSubPage(self2._lunarActive) end
        end
    end
    return Tab.new(page, self.name)
end

--// window --------------------------------------------------------------------
local tsWindow, tsWatermark, tsKeybindList

-- the watermark can be shown and hidden but not relabelled, so its title label is
-- captured while it is being built (the only child the call adds)
local function captureTextLabel(parent, build)
    local before = {}
    for _, child in ipairs(parent:GetChildren()) do before[child] = true end
    local result = build()
    local created = nil
    for _, child in ipairs(parent:GetChildren()) do
        if not before[child] then
            created = child
            break
        end
    end
    return result, created
end

local lib = { Unloaded = false, AccentColor = ACCENT }
lib.Theme = Library.Theme
lib.Options, lib.Toggles, lib.Flags = Options, Toggles, Library.Flags

function lib:CreateWindow(cfg)
    cfg = cfg or {}

    local viewport = (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize) or Vector2.new(1280, 720)
    local size
    if IS_MOBILE then
        size = UDim2.fromOffset(470, 520)
    else
        size = UDim2.fromOffset(
            math.clamp(math.floor(viewport.X * 0.45), 570, 700),
            math.clamp(math.floor(viewport.Y * 0.70), 400, 640)
        )
    end

    tsWindow = Library:Window({
        Name = cfg.Title or MENU_TITLE,
        Size = cfg.Size or size,
        FadeSpeed = tonumber(cfg.FadeSpeed) or 0.12,
    })

    local holder = Library.Holder.Instance
    local watermark, marker = captureTextLabel(holder, function() return Library:Watermark(MENU_TITLE) end)
    tsWatermark = { handle = watermark, title = marker and marker:FindFirstChildOfClass('TextLabel') or nil }
    tsKeybindList = Library:KeybindList()

    local win = { paw = tsWindow, name = cfg.Title or MENU_TITLE }

    function win:AddTab(name, opts)
        opts = opts or {}
        local page = tsWindow:Page({
            Name = name,
            Columns = opts.Columns or 2,
            Subtabs = opts.Subtabs == true,
        })
        return Tab.new(page, name)
    end

    -- the settings page brings themes, profiles, tweening, the watermark and
    -- keybind list toggles and unload; it also defines Library.Init (config autoload).
    -- CreateSettingsPage builds the page but returns nothing, so the page is found by
    -- diffing the window's page tabs instead of trusting a return value - relying on
    -- the return used to make this fall through and add a SECOND "Settings" tab.
    function win:AddSettingsTab()
        local pages = tsWindow.Pages
        local before = type(pages) == 'table' and #pages or 0

        pcall(function() Library:CreateSettingsPage(tsWindow, watermark, tsKeybindList) end)

        if type(pages) == 'table' then
            for i = before + 1, #pages do
                local page = pages[i]
                if type(page) == 'table' and type(page.Section) == 'function' then
                    return Tab.new(page, 'Settings')
                end
            end
        end
        -- never hand back nothing: the feature code adds its Utilities box to this
        return win:AddTab('Settings')
    end

    return win
end

function lib:Notify(message, duration, colour)
    pcall(function() Library:Notification(tostring(message), tonumber(duration) or 3, colour or ACCENT) end)
end

function lib:SetWatermark(text)
    local title = tsWatermark and tsWatermark.title
    if title then pcall(function() title.Text = tostring(text) end) end
end

function lib:SetWatermarkVisibility(state)
    if tsWatermark and tsWatermark.handle then
        pcall(function() tsWatermark.handle:SetVisibility(state == true) end)
    end
end

local UnloadHooks = {}
local unloaded = false

function lib:OnUnload(fn) table.insert(UnloadHooks, fn) end

function lib:Unload()
    if unloaded then return end
    unloaded = true
    self.Unloaded = true
    for _, fn in ipairs(UnloadHooks) do pcall(fn) end
    pcall(function() Library:Unload() end)
end

function lib:UpdateColors()
    local colour = self.AccentColor or ACCENT
    pcall(function() Library:ChangeTheme('Accent', colour) end)
end

-- anything the feature code asks for that this layer does not define is served
-- straight off the real library (LoadConfig, SaveConfig, ChangeTheme, ...)
setmetatable(lib, { __index = Library })

--// settings + config stand-ins -------------------------------------------------
-- These build nothing: Thugsense's settings page is the interface now.  The two
-- globals are kept so the older calls in the feature tail keep working.
local SaveManager = {}
function SaveManager:SetLibrary() end
function SaveManager:SetFolder() end
function SaveManager:IgnoreThemeSettings() end
function SaveManager:SetIgnoreIndexes() end
function SaveManager:BuildConfigSection() end
-- the autoload config is applied by the Library:Init call at the very end of the
-- script, once every widget exists
function SaveManager:LoadAutoloadConfig() end

local ThemeManager = {}
function ThemeManager:SetLibrary() end
function ThemeManager:SetFolder() end
function ThemeManager:ApplyToTab() end

--// input ----------------------------------------------------------------------
-- Thugsense binds its keys directly to UserInputService, so a key pressed while
-- a textbox has focus would still fire its keybind.  Re-wrap its input connections
-- once they exist so typing never triggers a feature.
local function guardKeyboardInput()
    local uis = getgenv().UserInputService
    local connections = Library.Connections
    if type(connections) ~= 'table' then return end
    for _, entry in ipairs(connections) do
        if entry.Event == uis.InputBegan and type(entry.Callback) == 'function' and not entry.__lunarGuarded then
            local callback = entry.Callback
            entry.__lunarGuarded = true
            local guarded = function(input, processed)
                if uis:GetFocusedTextBox() then return end
                callback(input, processed)
            end
            entry.Callback = guarded
            if entry.Connection then
                pcall(function() entry.Connection:Disconnect() end)
                entry.Connection = uis.InputBegan:Connect(guarded)
            end
        end
    end
end
task.defer(guardKeyboardInput)
task.delay(1, guardKeyboardInput)
task.delay(3, guardKeyboardInput)
getgenv().Library = lib
getgenv().SaveManager = SaveManager
getgenv().ThemeManager = ThemeManager

getgenv().ForceDefaultHudVisible = false
getgenv().gameName = MENU_TITLE
getgenv().LunarBuild = LUNAR_BUILD

task.delay(2, function()
    warn('[lunar.lua] ' .. LUNAR_BUILD)
    pcall(function() getgenv().Library:Notify(LUNAR_BUILD, 6) end)
end)

pcall(function()
    if setfpscap then setfpscap(32555555555555555) end
end)

task.spawn(function()
    local localPlayer = getgenv().LocalPlayer
    while task.wait(1) do
        if not localPlayer or localPlayer.Parent == nil then
            localPlayer = Players.LocalPlayer
            getgenv().LocalPlayer = localPlayer
        end
        local dataFolder = localPlayer and localPlayer:FindFirstChild("DataFolder")
        local subscription = dataFolder and dataFolder:FindFirstChild("Subscription")
        local hasSubscription = subscription and subscription:FindFirstChild("HasSubscription")
        local subscriptionStreak = subscription and subscription:FindFirstChild("SubscriptionStreak")
        local subscriptionData = subscription and subscription:FindFirstChild("SubscriptionData")
        if hasSubscription and hasSubscription:IsA("BoolValue") then
            hasSubscription.Value = true
        end
        if subscriptionStreak and (subscriptionStreak:IsA("IntValue") or subscriptionStreak:IsA("NumberValue")) then
            subscriptionStreak.Value = 67
        end
        if subscriptionData and (subscriptionData:IsA("IntValue") or subscriptionData:IsA("NumberValue")) then
            subscriptionData.Value = 67
        end
    end
end)

getgenv().shootArgs = { {}, {}, Vector3.zero, Vector3.zero, 0 }

for i = 1, 5 do
    getgenv().shootArgs[1][i] = {Normal = Vector3.zero, Instance = nil, Position = Vector3.zero}
    getgenv().shootArgs[2][i] = {thePart = nil, theOffset = Vector3.zero}
end

getgenv().forceFieldTimers = setmetatable({}    , {__mode = "k"})

getgenv().DesyncPart = Instance.new("Part")
getgenv().DesyncPart.Name = "DesyncVisual"
getgenv().DesyncPart.Size = Vector3.new(2, 2, 1)
getgenv().DesyncPart.Transparency = 1
getgenv().DesyncPart.CanCollide = false
getgenv().DesyncPart.Anchored = true
getgenv().DesyncPart.Parent = workspace

getgenv().StrafeConnection = nil
getgenv().StrafeVisConnection = nil
getgenv().StrafeVisParts = nil
getgenv().CurrentStrafeCF = nil

getgenv().Config = {
    Visual = {
        FOV = {
            Enabled = false,
            Shape = 'Circle',
            Size = 300,
            InnerColor = Color3.fromRGB(255, 255, 255),
            OuterColor = Color3.fromRGB(0, 0, 0),
            FollowCursor = true,
            Filled = false,
            FillColor = Color3.fromRGB(255, 255, 255),
            PulseEnabled = false,
            PulseAmount = 20,
            PulseSpeed = 2,
            InnerCircle = nil,
            OuterCircle = nil,
            FillCircle = nil,
            ScreenGui = nil,
            MainFrame = nil,
            UICorner = nil,
            UIStroke = nil,
        }
    },
    ESP = {
        Box = {
            Enable = true,
            Type = 'Full',
            Font = 'SmallestPixel',
            Color = Color3.fromRGB(255, 255, 255),
            Filled = {
                Enable = false,
                Gradient = {
                    Enable = false,
                    Color = {
                        Start = Color3.fromRGB(255, 255, 255),
                        End = Color3.fromRGB(0, 0, 0),
                    },
                    Rotation = {
                        Enable = true,
                        Auto = true,
                    },
                    Transparency = 0.5,
                },
            },
        },
        Text = {
            Enable = true,
            Name = {
                Enable = true,
                Teamcheck = true,
                Color = Color3.fromRGB(255, 255, 255),
            },
            Studs = {
                Enable = true,
                Color = Color3.fromRGB(255, 255, 255),
            },
            Tool = {
                Enable = true,
                Color = Color3.fromRGB(255, 255, 255),
            },
        },
        Bars = {
            Enable = true,
            Health = {
                ShowOutline = false,
                Enable = true,
                Lerp = true,
                Color1 = Color3.fromRGB(0, 255, 0),
                Color2 = Color3.fromRGB(255, 255, 0),
                Color3 = Color3.fromRGB(255, 0, 0),
            },
        },
    }
}

local void = {
    enabled = false,
    client_root = nil,
    saved_cframe = nil,
    spoof_cframe = nil,
    hook = nil,
    timer = 0,
    is_voided = false,
    angle = 0,
    radius = 1000,
    spin_speed = 50,
    source = nil,
    _didExitEquip = false
}

local lastLocalHealthForAutoVoid = nil
local hitAutoVoidActiveUntil = 0
local hitAutoVoidOwnedSync = false

local PARTICLE_AURA_DATA = {
    { "starlight", "rbxassetid://134645216613107" },
    { "heavenly", "rbxassetid://139300897520961" },
    { "ribbon", "rbxassetid://132069507632161" },
    { "sakura", "rbxassetid://81755778619404" },
    { "angel", "rbxassetid://97658130917593" },
    { "wind", "rbxassetid://80694081850877" },
    { "flow", "rbxassetid://119913533725648" },
    { "star", "rbxassetid://73754563740680" },
}



getgenv().LocalPlayer.CharacterAdded:Connect(function(newChar)
    task.defer(function()
        if getgenv().LocalPlayer.Character ~= newChar then return end

    end)
end)


local function own(part)
    if not part or not part:IsA("BasePart") then return end
    pcall(function() part:SetNetworkOwner(getgenv().LocalPlayer) end)
end


local PARTICLE_AURA_NAMES = {}
local particleAuraIdByName = {}

for _, row in ipairs(PARTICLE_AURA_DATA) do
    table.insert(PARTICLE_AURA_NAMES, row[1])
    particleAuraIdByName[row[1]] = row[2]
end

local loadedParticleAuras = {}
local selfAuraParticles = {}

local function mapCharacterParts(character)
    local parts = {}
    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("BasePart") then
            parts[child.Name] = child
        end
    end
    return parts
end

local function getParticleAuraTemplate(name)
    local cached = loadedParticleAuras[name]
    if cached then return cached end
    local id = particleAuraIdByName[name]
    if not id then return nil end
    local ok, result = pcall(function()
        return game:GetObjects(id)[1]
    end)
    if ok and result then
        loadedParticleAuras[name] = result
        return result
    end
    return nil
end

local function clearSelfAura()
    for _, p in ipairs(selfAuraParticles) do
        if p then p:Destroy() end
    end
    table.clear(selfAuraParticles)
end

local function tintParticleSubtree(root, color)
    if not color or not root then return end
    local seq = ColorSequence.new(color)
    local function tintOne(obj)
        if obj:IsA("ParticleEmitter") or obj:IsA("Beam") or obj:IsA("Trail") then
            obj.Color = seq
        elseif obj:IsA("PointLight") then
            obj.Color = color
        end
    end
    tintOne(root)
    for _, d in ipairs(root:GetDescendants()) do
        tintOne(d)
    end
end

local function setParticleEmittersEnabledInSubtree(root, enabled)
    if not root then return end
    if root:IsA("ParticleEmitter") then
        root.Enabled = enabled
    end
    for _, d in ipairs(root:GetDescendants()) do
        if d:IsA("ParticleEmitter") then
            d.Enabled = enabled
        end
    end
end

local function applyParticleAuraToCharacter(character, auraName, color, isPersistent)
    local auraObj = getParticleAuraTemplate(auraName)
    if not auraObj then return {} end

    local localParts = mapCharacterParts(character)
    local cloned = auraObj:Clone()
    local created = {}

    for _, part in ipairs(cloned:GetChildren()) do
        local targetPart = localParts[part.Name]
        if targetPart then
            for _, child in ipairs(part:GetChildren()) do
                local inst = child:Clone()
                inst.Name = "LarpticAuraParticle"
                inst.Parent = targetPart
                if color then
                    tintParticleSubtree(inst, color)
                end
                table.insert(created, inst)
            end
        end
    end
    cloned:Destroy()

    for _, p in ipairs(created) do
        setParticleEmittersEnabledInSubtree(p, true)
    end

    if not isPersistent then
        task.delay(1.6, function()
            for _, p in ipairs(created) do
                if p and p.Parent then
                    setParticleEmittersEnabledInSubtree(p, false)
                end
            end
        end)
        task.delay(2.5, function()
            for _, p in ipairs(created) do
                if p then p:Destroy() end
            end
        end)
    end

    return created
end

local function refreshSelfAura()
    clearSelfAura()
    if not (Toggles.SelfAuraEnabled and Toggles.SelfAuraEnabled.Value) then return end
    local char = getgenv().LocalPlayer.Character
    if not char then return end
    local auraName = (Options.SelfAuraType and Options.SelfAuraType.Value) or "None"
    if auraName == "None" or not particleAuraIdByName[auraName] then return end
    local col = Options.SelfAuraColor.Value or Color3.fromRGB(133, 220, 255)
    selfAuraParticles = applyParticleAuraToCharacter(char, auraName, col, true)
end

getgenv().LocalPlayer.CharacterAdded:Connect(function()
    if Toggles.SelfAuraEnabled and Toggles.SelfAuraEnabled.Value then
        task.delay(0.75, refreshSelfAura)
    end
    if Toggles.SkinChangerEnabled and Toggles.SkinChangerEnabled.Value then
        task.delay(1, function()
            getgenv().Larptic_ApplySkins()
            getgenv().Larptic_ApplyBullets()
        end)
    end
end)

local GUN_SKINS = {
    "Default", "Ascension", "Void Dragon", "Hell Hound", "Snow Dragon", "Lovestruck",
    "Adurite", "Hallows", "Candy Cane", "Heartbringer", "Arctic", "Lightbringer",
    "Deathbringer", "Hell Dragon", "Kitty", "Kirumi", "Shiryus Breath", "Poseidon",
    "Amethyst", "Arsenic", "Volcanic Ashes", "Floral", "Binary", "Voxel",
    "Hello Kitty", "Radiation", "Void", "Hexagram", "Strawberry Shortcake",
    "Black Ice", "Crimson Fangs", "Green Tint", "Ember",
}
local KNIFE_SKINS = { "--", "Beta", "Fishbone" }
local BULLET_SKINS = {
    "None", "Beta", "Hallows", "Kitty", "Kirumi", "Rainbow",
    "Red", "Blue", "Green", "Orange",
}
local BULLET_CODES = {
    DoubleBarrel = "109d1326878cc594bc1bb42d126250810999782f",
    Revolver = "539db315b53f77390c0aa74773158e25bedcdd6e",
    Shotgun = "b415a7273aa86cbc2adc445fde5435eb5afababa",
    SMG = "005af87725b42ac4ca8103d11af6bf0c7d55f7b3",
    TacticalShotgun = "109d1326878cc594bc1bb42d126250810999782f",
}

local function SC_WeldParts(p0, p1)
    local w = Instance.new("WeldConstraint")
    w.Part0 = p0; w.Part1 = p1; w.Parent = p0
end

local function SC_StripSkin(weapon)
    local handle = weapon:FindFirstChild("Handle")
    if handle then handle.Transparency = 0 end
    for _, child in ipairs(weapon:GetChildren()) do
        if child:IsA("Model") and child:FindFirstChild("_LarpticSkin") then
            child:Destroy()
        end
    end
end

local function SC_ApplySkin(weapon, model)
    SC_StripSkin(weapon)
    local handle = weapon:FindFirstChild("Handle")
    if not handle then return end
    local clone = model:Clone()
    if not clone.PrimaryPart then return end
    local tag = Instance.new("BoolValue")
    tag.Name = "_LarpticSkin"
    tag.Parent = clone
    for _, part in ipairs(clone:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
            part.Anchored = false
            part.Massless = true
            part.Transparency = 0
        end
    end
    clone.Parent = weapon
    SC_WeldParts(handle, clone.PrimaryPart)
    clone:SetPrimaryPartCFrame(handle.CFrame)
    handle.Transparency = 1
end

local function SC_IsNoSkin(name)
    return (not name) or name == "None" or name == "Default" or name == "--"
end

getgenv().Larptic_ApplySkins = function()
    local bp = getgenv().LocalPlayer:FindFirstChild("Backpack")
    if not bp then return end
    local RS = getgenv().ReplicatedStorage
    local gunMap = {
        DoubleBarrel = Options.SkinDoubleBarrel and Options.SkinDoubleBarrel.Value,
        Revolver = Options.SkinRevolver and Options.SkinRevolver.Value,
        Shotgun = Options.SkinShotgun and Options.SkinShotgun.Value,
        SMG = Options.SkinSMG and Options.SkinSMG.Value,
        TacticalShotgun = Options.SkinTacticalShotgun and Options.SkinTacticalShotgun.Value,
    }
    for weaponKey, skinName in pairs(gunMap) do
        local weapon = bp:FindFirstChild("[" .. weaponKey .. "]")
        if weapon then
            if not SC_IsNoSkin(skinName) then
                local skinFolder = RS:FindFirstChild("Wraps") and RS.Wraps:FindFirstChild("[" .. weaponKey .. "]")
                if skinFolder then
                    local skinModel = skinFolder:FindFirstChild(skinName)
                    if skinModel then SC_ApplySkin(weapon, skinModel) end
                end
            else
                SC_StripSkin(weapon)
            end
        end
    end
    local knifeSkin = Options.SkinKnife and Options.SkinKnife.Value
    local knife = bp:FindFirstChild("[Knife]")
    if knife then
        if not SC_IsNoSkin(knifeSkin) then
            local knivesFolder = RS:FindFirstChild("Knives")
            if knivesFolder then
                local skinModel = knivesFolder:FindFirstChild(knifeSkin)
                if skinModel then SC_ApplySkin(knife, skinModel) end
            end
        else
            SC_StripSkin(knife)
        end
    end
end

getgenv().Larptic_ResetSkins = function()
    local bp = getgenv().LocalPlayer:FindFirstChild("Backpack")
    if not bp then return end
    local weapons = bp:GetChildren()
    local char = getgenv().LocalPlayer.Character
    if char then
        for _, c in ipairs(char:GetChildren()) do
            if c:IsA("Tool") then table.insert(weapons, c) end
        end
    end
    for _, weapon in ipairs(weapons) do
        if weapon:IsA("Tool") then SC_StripSkin(weapon) end
    end
    getgenv().Library:Notify("Skins Reset!", 3)
end

getgenv().Larptic_ApplyBullets = function()
    local enabled = Toggles.BulletChangerEnabled and Toggles.BulletChangerEnabled.Value
    local texture = Options.BulletTexture and Options.BulletTexture.Value
    if not (enabled and texture and texture ~= "None") then return end

    local dataFolder = getgenv().LocalPlayer:FindFirstChild("DataFolder")
    if not dataFolder then return end
    local inventoryData = dataFolder:FindFirstChild("InventoryData")
    local equippedBB = dataFolder:FindFirstChild("EquippedBulletBeams")
    local HttpService = game:GetService("HttpService")

    if inventoryData then
        local bulletBeams = inventoryData:FindFirstChild("BulletBeams")
        if bulletBeams and bulletBeams:IsA("StringValue") then
            local beamData = {}
            for _, code in pairs(BULLET_CODES) do
                beamData[code] = { Name = texture }
            end
            bulletBeams.Value = HttpService:JSONEncode(beamData)
        end
    end
    if equippedBB and equippedBB:IsA("StringValue") then
        local equipped = {}
        for weaponKey, code in pairs(BULLET_CODES) do
            equipped["[" .. weaponKey .. "]"] = code
        end
        equippedBB.Value = HttpService:JSONEncode(equipped)
    end
end

local function applyVisualGuns()
    if not Toggles.SkinChangerEnabled or not Toggles.SkinChangerEnabled.Value then return end
    getgenv().Larptic_ApplySkins()
    getgenv().Larptic_ApplyBullets()
end

local function localPlayerIsKO()
    local char = getgenv().LocalPlayer.Character
    local body = char and char:FindFirstChild("BodyEffects")
    local ko = (body and body:FindFirstChild("K.O") and body["K.O"].Value) or (char and char:FindFirstChild("KO") and char.KO.Value)
    return ko
end

local function isValidAutoHealTarget(pChar, myRoot)
    if not pChar or not myRoot or myRoot.Parent == nil then return false end
    local be = pChar:FindFirstChild("BodyEffects")
    local pHum = pChar:FindFirstChildOfClass("Humanoid")
    local pRoot = pChar:FindFirstChild("HumanoidRootPart")
    if not pRoot then return false end

    local isKO = (be and be:FindFirstChild("K.O") and be["K.O"].Value) or (pChar:FindFirstChild("KO") and pChar.KO.Value)
    local isDead = (be and be:FindFirstChild("Dead") and be.Dead.Value) or (pHum and pHum.Health <= 0)
    
    if not isKO or isDead then return false end
    return pRoot.Position.Y < 5000 and pRoot.Position.Y > -500 and (pRoot.Position - myRoot.Position).Magnitude <= 2500
end

local function getValidAutoHealPlayers()
    local myRoot = getgenv().LocalPlayer.Character and getgenv().LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return {} end
    local targets = {}
    for _, p in ipairs(getgenv().Players:GetPlayers()) do
        if p ~= getgenv().LocalPlayer and isValidAutoHealTarget(p.Character, myRoot) then
            table.insert(targets, p)
        end
    end
    return targets
end

local autoHealActive = false
task.spawn(function()
    while task.wait(0.1) do
        if Toggles.AutoHealEnabled and Toggles.AutoHealEnabled.Value and not autoHealActive then
            local char = getgenv().LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hum or not hrp or localPlayerIsKO() then continue end

            local threshold = Options.AutoHealThreshold and Options.AutoHealThreshold.Value or 50
            local maxHealth = hum.MaxHealth > 0 and hum.MaxHealth or 100
            if (hum.Health / maxHealth) * 100 >= threshold then continue end

            local koPlayers = getValidAutoHealPlayers()
            if #koPlayers == 0 then continue end

            local targetPlayer = koPlayers[math.random(1, #koPlayers)]
            autoHealActive = true
            local oldCFrame = hrp.CFrame
            getgenv().Library:Notify("Auto Healing: Teleporting to " .. (targetPlayer.DisplayName or targetPlayer.Name))
            
            local healStart = tick()
            local healMaxDuration = 8
            local healAbortKO = false

            while tick() - healStart < healMaxDuration do
                local char = getgenv().LocalPlayer.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if not hum or not hrp or not hum.Parent then break end
                if localPlayerIsKO() then healAbortKO = true; break end

                local maxHealth = hum.MaxHealth > 0 and hum.MaxHealth or 100
                if (hum.Health / maxHealth) * 100 >= threshold + 5 or hum.Health >= maxHealth then break end

                if not targetPlayer or targetPlayer.Parent ~= getgenv().Players then
                    koPlayers = getValidAutoHealPlayers()
                    if #koPlayers == 0 then break end
                    targetPlayer = koPlayers[math.random(1, #koPlayers)]
                end

                local targetChar = targetPlayer and targetPlayer.Character
                if not isValidAutoHealTarget(targetChar, hrp) then
                    koPlayers = getValidAutoHealPlayers()
                    if #koPlayers == 0 then break end
                    targetPlayer = koPlayers[math.random(1, #koPlayers)]
                    targetChar = targetPlayer.Character
                end

                local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
                local currentTorso = targetChar and (targetChar:FindFirstChild("UpperTorso") or targetChar:FindFirstChild("Torso") or targetRoot)
                
                if currentTorso then
                    getgenv().isCurrentlyStomping = true
                    pcall(function() hrp:SetNetworkOwner(getgenv().LocalPlayer) end)
                    local pos = currentTorso.Position + Vector3.new(0, 3, 0)
                    local look = hrp.CFrame.LookVector
                    local flatLook = Vector3.new(look.X, 0, look.Z)
                    if flatLook.Magnitude < 1e-3 then flatLook = Vector3.new(0, 0, -1) end
                    
                    pcall(function()
                        hrp.CFrame = CFrame.lookAt(pos, pos + flatLook.Unit)
                        hrp.Velocity = Vector3.zero
                    end)
                    
                    getgenv().MainEvent:FireServer("Stomp")
                end
                task.wait(0.1)
            end

            getgenv().isCurrentlyStomping = false

            local char = getgenv().LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp and oldCFrame then
                pcall(function()
                    hrp.CFrame = oldCFrame
                    hrp.Velocity = Vector3.zero
                end)
            end
            autoHealActive = false
            getgenv().Library:Notify(healAbortKO and "Auto Heal stopped (K.O.)" or "Heal Complete")
        end
    end
end)

getgenv().SpectateConnection = nil
getgenv().LastShotTime = 0
getgenv().lastMeleeFire = 0
getgenv().isCurrentlyStomping = false

getgenv().trackCharacter = function(char)
    if not char then return end
    local ff = char:FindFirstChildOfClass("ForceField")
    if ff then getgenv().forceFieldTimers[char] = workspace:GetServerTimeNow() end
    char.ChildAdded:Connect(function(child)
        if child:IsA("ForceField") then getgenv().forceFieldTimers[char] = workspace:GetServerTimeNow() end
    end)
end

getgenv().trackPlayer = function(plr)
    if plr.Character then getgenv().trackCharacter(plr.Character) end
    plr.CharacterAdded:Connect(getgenv().trackCharacter)
end

for _, plr in ipairs(getgenv().Players:GetPlayers()) do getgenv().trackPlayer(plr) end
getgenv().Players.PlayerAdded:Connect(getgenv().trackPlayer)

getgenv().TargetCleanupConnection = getgenv().Players.PlayerRemoving:Connect(function(plr)
    if getgenv().ForceHitTarget == plr then
        getgenv().ForceHitTarget = nil
        getgenv().SetupDamageDetection(nil)
        if getgenv().TracerLine then getgenv().TracerLine.Visible = false end
        if getgenv().TracerOutline then getgenv().TracerOutline.Visible = false end
    end
    if getgenv().ForceHitTarget2 == plr then
        getgenv().ForceHitTarget2 = nil
        getgenv().SetupDamageDetection(nil)
        if getgenv().TracerLine2 then getgenv().TracerLine2.Visible = false end
        if getgenv().TracerOutline2 then getgenv().TracerOutline2.Visible = false end
    end
end)

getgenv().TracerOutline = Drawing.new("Line")
getgenv().TracerOutline.Thickness = 3; getgenv().TracerOutline.Color = Color3.fromRGB(0, 0, 0); getgenv().TracerOutline.Visible = false; getgenv().TracerOutline.ZIndex = 1

getgenv().TracerLine = Drawing.new("Line")
getgenv().TracerLine.Thickness = 1; getgenv().TracerLine.Color = Color3.fromRGB(255, 255, 255); getgenv().TracerLine.Visible = false; getgenv().TracerLine.ZIndex = 2

getgenv().TracerOutline2 = Drawing.new("Line")
getgenv().TracerOutline2.Thickness = 3; getgenv().TracerOutline2.Color = Color3.fromRGB(0, 0, 0); getgenv().TracerOutline2.Visible = false; getgenv().TracerOutline2.ZIndex = 1

getgenv().TracerLine2 = Drawing.new("Line")
getgenv().TracerLine2.Thickness = 1; getgenv().TracerLine2.Color = Color3.fromRGB(255, 255, 255); getgenv().TracerLine2.Visible = false; getgenv().TracerLine2.ZIndex = 2

getgenv().HitNotifGui = Instance.new("ScreenGui")
getgenv().HitNotifGui.Name = "LarpticHitNotifs"; getgenv().HitNotifGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
getgenv().coreGui = pcall(function() return game:GetService("CoreGui") end) and game:GetService("CoreGui") or getgenv().LocalPlayer:WaitForChild("PlayerGui")
getgenv().HitNotifGui.Parent = getgenv().coreGui

getgenv().notifContainer = Instance.new("Frame")
getgenv().notifContainer.Name = "Container"; getgenv().notifContainer.BackgroundTransparency = 1; getgenv().notifContainer.Size = UDim2.new(0, 300, 0.8, 0)
getgenv().notifContainer.Parent = getgenv().HitNotifGui

getgenv().listLayout = Instance.new("UIListLayout")
getgenv().listLayout.Padding = UDim.new(0, 8); getgenv().listLayout.SortOrder = Enum.SortOrder.LayoutOrder; getgenv().listLayout.Parent = getgenv().notifContainer

getgenv().UpdateNotifPosition = function(mode)
    local configs = {
        ["Top Left"] = { Anchor = Vector2.new(0, 0), Position = UDim2.new(0.02, 0, 0.05, 0), VAlign = Enum.VerticalAlignment.Top, HAlign = Enum.HorizontalAlignment.Left },
        ["Top Right"] = { Anchor = Vector2.new(1, 0), Position = UDim2.new(0.98, 0, 0.05, 0), VAlign = Enum.VerticalAlignment.Top, HAlign = Enum.HorizontalAlignment.Right },
        ["Bottom Center"] = { Anchor = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 0.95, 0), VAlign = Enum.VerticalAlignment.Bottom, HAlign = Enum.HorizontalAlignment.Center },
        ["Center"] = { Anchor = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), VAlign = Enum.VerticalAlignment.Center, HAlign = Enum.HorizontalAlignment.Center }
    }
    local cfg = configs[mode]
    if cfg then
        getgenv().notifContainer.AnchorPoint = cfg.Anchor; getgenv().notifContainer.Position = cfg.Position
        getgenv().listLayout.VerticalAlignment = cfg.VAlign; getgenv().listLayout.HorizontalAlignment = cfg.HAlign
    end
end

getgenv().CreateDamageIndicator = function(part, damage)
    if not Toggles.DamageIndicators.Value or not part then return end
    local anchor = Instance.new("Part")
    anchor.Anchored = true; anchor.CanCollide = false; anchor.Transparency = 1
    anchor.Size = Vector3.new(0.1, 0.1, 0.1); anchor.Position = part.Position; anchor.Parent = workspace
    
    local bbg = Instance.new("BillboardGui")
    bbg.AlwaysOnTop = true; bbg.Size = UDim2.new(0, 200, 0, 50)
    
    local randX = math.random(-15, 15) / 10; local randY = math.random(-5, 5) / 10
    local startOffset = Vector3.new(randX, 1.5 + randY, 0)
    bbg.StudsOffset = startOffset; bbg.Adornee = anchor; bbg.Parent = getgenv().coreGui
    
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1; label.Size = UDim2.new(1, 0, 1, 0)
    label.Font = Enum.Font.Code; label.Text = tostring(math.floor(damage + 0.5))
    label.TextColor3 = Options.IndicatorColor.Value; label.TextSize = 28; label.TextStrokeTransparency = 1
    
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 2; stroke.Color = Options.IndicatorStrokeColor and Options.IndicatorStrokeColor.Value or Color3.fromRGB(15, 15, 15)
    stroke.LineJoinMode = Enum.LineJoinMode.Round; stroke.Parent = label
    
    label.Rotation = math.random(-35, 35); label.Parent = bbg
    local scale = Instance.new("UIScale")
    scale.Scale = 0; scale.Parent = label
    
    task.spawn(function()
        getgenv().TweenService:Create(scale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
        getgenv().TweenService:Create(label, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Rotation = math.random(-5, 5)}):Play()
        getgenv().TweenService:Create(bbg, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {StudsOffset = startOffset + Vector3.new(0, 1.5, 0)}):Play()
        
        task.wait(Options.IndicatorDuration and Options.IndicatorDuration.Value or 1.0)
        
        getgenv().TweenService:Create(bbg, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {StudsOffset = startOffset + Vector3.new(0, 0.5, 0)}):Play()
        getgenv().TweenService:Create(label, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {TextTransparency = 1}):Play()
        getgenv().TweenService:Create(stroke, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Transparency = 1}):Play()
        local shrinkOut = getgenv().TweenService:Create(scale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Scale = 0})
        
        shrinkOut:Play()
        shrinkOut.Completed:Wait()
        bbg:Destroy(); anchor:Destroy()
    end)
end

getgenv().HitSounds = {["Rust Headshot"]  = "138750331387064",["Neverlose"]      = "110168723447153",["Bubble"]         = "6534947588",
    ["Laser"]          = "7837461331", ["Steve"]          = "4965083997",["Call of Duty"]   = "5952120301",["Bat"]            = "3333907347", ["TF2 Critical"]   = "296102734", ["Saber"]          = "8415678813",
    ["Bameware"]       = "3124331820", ["Money"]          = "13956013041", ["Notif"]          = "6696469190",
    ["Shutter"]        = "10066921516", ["RIFK7"]          = "9102080552",["LazerBeam"]      = "130791043",
    ["WindowsXPError"] = "160715357", ["TF2Hitsound"]    = "3455144981",["TF2Bat"]         = "3333907347",
    ["BowHit"]         = "1053296915",["Bow"]            = "3442683707",["OSU"]            = "7147454322",
    ["OneNN"]          = "7349055654", ["Rust"]           = "6565371338",["TF2Pan"]         = "3431749479",
    ["Mario"]          = "5709456554", ["Bell"]           = "6534947240", ["Pick"]           = "1347140027",["Pop"]            = "198598793",["Sans"]           = "3188795283", ["Fart"]           = "130833677",
    ["Big"]            = "5332005053", ["Vine"]           = "5332680810", ["Bruh"]           = "4578740568",
    ["Skeet"]          = "5633695679", ["Fatality"]       = "6534947869",["Bonk"]           = "5766898159",["Minecraft"]      = "5869422451", ["Gamesense"]      = "4817809188", ["Bamboo"]         = "3769434519",
    ["Crowbar"]        = "546410481",["Weeb"]           = "6442965016", ["Beep"]           = "8177256015",["Bambi"]          = "8437203821",["Stone"]          = "3581383408",["Old Fatality"]   = "6607142036",["Click"]          = "8053704437",["Ding"]           = "7149516994", ["Snow"]           = "6455527632",
    ["Osu"]            = "7149255551",["TF2"]            = "2868331684",["Slime"]          = "6916371803",
    ["Among Us"]       = "5700183626",["One"]            = "7380502345",["BulletDeflect"]  = "1657157666",
}
getgenv().HitSoundList = {}
for name, _ in pairs(getgenv().HitSounds) do table.insert(getgenv().HitSoundList, name) end
table.sort(getgenv().HitSoundList); table.insert(getgenv().HitSoundList, "Custom")

getgenv().PlayHitSound = function()
    if not Toggles.HitSoundEnabled.Value then return end
    local soundId = Options.HitSoundChoice.Value == 'Custom' and Options.CustomHitSound.Value or getgenv().HitSounds[Options.HitSoundChoice.Value]
    if not soundId or soundId == "" then return end
    if string.match(soundId, "^%d+$") then soundId = "rbxassetid://" .. soundId end

    local sound = Instance.new("Sound")
    sound.SoundId = soundId; sound.Volume = 1; sound.Parent = workspace
    sound:Play(); getgenv().Debris:AddItem(sound, 2)
end

getgenv().notifTick = 0
getgenv().CreateHitNotification = function(playerName, damage)
    if not Toggles.HitNotifEnabled.Value then return end
    -- the accent lives on the library theme now, so hit notifications follow it
    local accent = Options.AccentColor and Options.AccentColor.Value
    local c = accent or (Library.Theme and Library.Theme.Accent) or Color3.fromRGB(217, 195, 160)
    local hex = string.format("#%02X%02X%02X", math.floor(c.R*255), math.floor(c.G*255), math.floor(c.B*255))
    
    local notif = Instance.new("TextLabel")
    notif.Size = UDim2.new(0, 0, 0, 25); notif.AutomaticSize = Enum.AutomaticSize.X; notif.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    notif.BackgroundTransparency = 1; notif.TextTransparency = 1; notif.TextStrokeTransparency = 1; notif.Font = Enum.Font.Code
    notif.TextSize = 14; notif.TextColor3 = Color3.fromRGB(255, 255, 255); notif.RichText = true
    local fmt = (Options.NotifFormat and Options.NotifFormat.Value) or "Hit (player) for (dmg%)"
    local nameSpan = string.format("<font color='%s'>%s</font>", hex, playerName)
    local dmgSpan = string.format("<font color='%s'>%d</font>", hex, math.floor(damage + 0.5))
    fmt = fmt:gsub("%(player%)", function() return nameSpan end)
    fmt = fmt:gsub("%(dmg%%%)", function() return dmgSpan end)
    fmt = fmt:gsub("%(dmg%)", function() return dmgSpan end)
    notif.Text = fmt
    
    getgenv().notifTick = getgenv().notifTick + 1; notif.LayoutOrder = getgenv().notifTick

    local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 4); corner.Parent = notif
    local stroke = Instance.new("UIStroke"); stroke.Color = Options.OutlineColor and Options.OutlineColor.Value or Color3.fromRGB(40, 40, 40); stroke.Transparency = 1; stroke.Parent = notif
    local pad = Instance.new("UIPadding"); pad.PaddingLeft = UDim.new(0, 8); pad.PaddingRight = UDim.new(0, 8); pad.Parent = notif
    notif.Parent = getgenv().notifContainer

    local tiIn = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    getgenv().TweenService:Create(notif, tiIn, {BackgroundTransparency = 0.4, TextTransparency = 0, TextStrokeTransparency = 0.5}):Play()
    getgenv().TweenService:Create(stroke, tiIn, {Transparency = 0}):Play()

    task.spawn(function()
        task.wait(2)
        local tiOut = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        getgenv().TweenService:Create(notif, tiOut, {BackgroundTransparency = 1, TextTransparency = 1, TextStrokeTransparency = 1}):Play()
        getgenv().TweenService:Create(stroke, tiOut, {Transparency = 1}):Play()
        task.wait(0.5); notif:Destroy()
    end)
end

getgenv().CreateBulletTracer = function(startPos, endPos, isDB)
    if not Toggles.BulletTracers.Value then return end
    local color = Options.BulletTracerColorOption.Value
    local duration = Options.TracerDuration.Value
    local steps = math.floor(duration * 50)
    if steps < 1 then steps = 1 end
    local waitTime = duration / steps
    
    local lineCount = isDB and 3 or 1
    for i = 1, lineCount do
        local targetPos = endPos
        local offset = Vector3.zero
        if isDB then
            local spread = Options.DBSpread.Value
            targetPos = targetPos + Vector3.new((math.random() - 0.5) * spread, (math.random() - 0.5) * spread, (math.random() - 0.5) * spread)
            local angle = math.rad((i - 1) * 120)
            offset = Vector3.new(math.cos(angle) * 0.12, math.sin(angle) * 0.12, 0)
        end
        
        local distance = (targetPos - startPos).Magnitude
        local tracer = Instance.new("Part")
        tracer.Anchored = true; tracer.CanCollide = false; tracer.Material = Enum.Material.Neon
        local tw = math.max(0.02, (Options.TracerWidth and Options.TracerWidth.Value or 1) * 0.06)
        tracer.Color = color; tracer.Transparency = 0.2; tracer.Size = Vector3.new(tw, tw, distance)
        tracer.CFrame = CFrame.lookAt(startPos, targetPos) * CFrame.new(offset) * CFrame.new(0, 0, -distance / 2)
        tracer.Parent = workspace
        
        task.spawn(function()
            for t = 1, steps do
                tracer.Transparency = 0.2 + (0.8 * (t / steps)); task.wait(waitTime)
            end
            tracer:Destroy()
        end)
    end
end

getgenv().SetupDamageDetection = function(target)
    if getgenv().TargetHealthConnection then getgenv().TargetHealthConnection:Disconnect(); getgenv().TargetHealthConnection = nil end
    if not target then return end
    
    local char = target.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    
    local lastHealth = hum.Health
    getgenv().TargetHealthConnection = hum:GetPropertyChangedSignal("Health"):Connect(function()
        local currentHealth = hum.Health
        if currentHealth < lastHealth then
            local damage = lastHealth - currentHealth
            local myChar = getgenv().LocalPlayer.Character
            if myChar then
                local hasTool = myChar:FindFirstChildOfClass("Tool")
                if hasTool then getgenv().PlayHitSound() end
                if Toggles.HitNotifEnabled and Toggles.HitNotifEnabled.Value then getgenv().CreateHitNotification(target.Name, damage) end
                if Toggles.DamageIndicators and Toggles.DamageIndicators.Value then
                    local hitPart = char:FindFirstChild(Options.HitPart.Value) or char:FindFirstChild("HumanoidRootPart")
                    getgenv().CreateDamageIndicator(hitPart, damage)
                end
                if Toggles.BulletTracers.Value then
                    local startPos = getgenv().Camera.CFrame.Position
                    if hasTool and hasTool:FindFirstChild("Handle") then startPos = hasTool.Handle.Position
                    elseif myChar:FindFirstChild("Right Arm") then startPos = myChar["Right Arm"].Position
                    elseif myChar:FindFirstChild("RightHand") then startPos = myChar["RightHand"].Position end
                    
                    local hitPart = char:FindFirstChild(Options.HitPart.Value) 
                    if hitPart then
                        local isDB = hasTool and string.lower(hasTool.Name) == "[doublebarrel]"
                        getgenv().CreateBulletTracer(startPos, hitPart.Position, isDB)
                    end
                end
            end
        end
        lastHealth = currentHealth
    end)
end

getgenv().isKO = function(p)
    if not Toggles.KOCheck.Value then return false end
    local c = p.Character
    if not c then return true end
    local h = c:FindFirstChild("Humanoid")
    local b = c:FindFirstChild("BodyEffects")
    return (h and h.Health <= 0) or (b and b:FindFirstChild("K.O") and b["K.O"].Value)
end

getgenv().isFullyDead = function(p)
    local c = p.Character
    if not c then return true end
    local h = c:FindFirstChild("Humanoid")
    local b = c:FindFirstChild("BodyEffects")
    return (h and h.Health <= 0) or (b and b:FindFirstChild("SDeath") and b["SDeath"].Value)
end

getgenv().wallCheck = function(a, b, ignore)
    if not Toggles.WallCheck.Value then return true end
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = ignore
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    local result = workspace:Raycast(a, b - a, rayParams)
    return not (result and result.Instance and result.Instance.CanCollide and not result.Instance:IsDescendantOf(getgenv().Players))
end

getgenv().Shoot = function(p)
    if not p or not p.Character then return end
    local character = p.Character
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    
    if Toggles.KOCheck.Value then
        if not humanoid or humanoid.Health <= 0 then return end
        local be = character:FindFirstChild("BodyEffects")
        if be and be:FindFirstChild("K.O") and be["K.O"].Value then return end
    end

    local targetPart = character:FindFirstChild(Options.HitPart.Value)
    if not targetPart then return end

    if Toggles.ForceFieldCheck.Value and not Toggles.EnablePrefire.Value then
        if character:FindFirstChildOfClass("ForceField") then return end
    end

    local char = getgenv().LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local spoofCF = getgenv().ForceHit.CurrentStrafeCF or getgenv().CurrentStrafeCF
    local playerPos = (Toggles.StrafeToggle.Value and spoofCF) and spoofCF.Position or root.Position

    if Toggles.WallCheck.Value then
        local rayParams = RaycastParams.new()
        rayParams.FilterDescendantsInstances = {char, character, getgenv().DesyncPart}
        rayParams.FilterType = Enum.RaycastFilterType.Blacklist
        local res = workspace:Raycast(playerPos, targetPart.Position - playerPos, rayParams)
        if res and res.Instance and res.Instance.CanCollide and not res.Instance:IsDescendantOf(getgenv().Players) then return end
    end

    if Options.MaxDistance and (playerPos - targetPart.Position).Magnitude > Options.MaxDistance.Value then return end

    local args = {
        [1] = {
            [1] = {Normal=targetPart.Position,Instance=targetPart,Position=targetPart.Position},
            [2] = {Normal=targetPart.Position,Instance=targetPart,Position=targetPart.Position},
            [3] = {Normal=targetPart.Position,Instance=targetPart,Position=targetPart.Position},
            [4] = {Normal=targetPart.Position,Instance=targetPart,Position=targetPart.Position},
            [5] = {Normal=targetPart.Position,Instance=targetPart,Position=targetPart.Position},
        },
        [2] = {
            [1] = {thePart=targetPart,theOffset=Vector3.zero},
            [2] = {thePart=targetPart,theOffset=Vector3.zero},
            [3] = {thePart=targetPart,theOffset=Vector3.zero},
            [4] = {thePart=targetPart,theOffset=Vector3.zero},
            [5] = {thePart=targetPart,theOffset=Vector3.zero},
        },
        [3] = playerPos,
        [4] = playerPos,
        [5] = workspace:GetServerTimeNow()
    }

    getgenv().MainEvent:FireServer("Shoot", args)
    getgenv().LastShotTime = tick()
    getgenv().ForceHit.LastShotTime = tick()
end

getgenv().GetClosestToMouse = function()
    local mousePos
    if getgenv().IsMobile then
        -- Touch devices have no cursor, so treat the centre of the screen
        -- (where the camera points) as the aim position.
        local viewport = getgenv().Camera.ViewportSize
        mousePos = Vector2.new(viewport.X / 2, viewport.Y / 2)
    else
        mousePos = getgenv().UserInputService:GetMouseLocation()
    end
    local fovCfg = getgenv().Config and getgenv().Config.Visual and getgenv().Config.Visual.FOV
    local shortest = fovCfg and fovCfg.Enabled and fovCfg.Size or 100
    if getgenv().IsMobile and not (fovCfg and fovCfg.Enabled) then shortest = math.huge end
    local closest = nil
    
    for _, plr in ipairs(getgenv().Players:GetPlayers()) do
        if plr ~= getgenv().LocalPlayer and plr.Character then
            local part = plr.Character:FindFirstChild(Options.HitPart.Value)
            if part and not getgenv().isKO(plr) then
                local screenPos, visible = getgenv().Camera:WorldToViewportPoint(part.Position)
                if visible then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    if dist < shortest then
                        shortest = dist; closest = plr
                    end
                end
            end
        end
    end
    return closest
end

getgenv().resetStrafeCamera = function()
    local char = getgenv().LocalPlayer.Character
    local hum = char and char:FindFirstChildWhichIsA("Humanoid")
    if hum then getgenv().Camera.CameraSubject = hum end
end

getgenv().destroyStrafeVisualizer = function()
    if getgenv().StrafeVisConnection then getgenv().StrafeVisConnection:Disconnect(); getgenv().StrafeVisConnection = nil end
    if getgenv().StrafeVisParts then
        for _, data in pairs(getgenv().StrafeVisParts) do
            if data.part then data.part:Destroy() end
        end
        getgenv().StrafeVisParts = nil
    end
end

getgenv().createStrafeVisualizer = function()
    getgenv().destroyStrafeVisualizer()
    local char = getgenv().LocalPlayer.Character or getgenv().LocalPlayer.CharacterAdded:Wait()
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    getgenv().StrafeVisParts = {}
    for _, p in ipairs(char:GetChildren()) do
        if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
            local vis = Instance.new("Part")
            vis.Name = p.Name .. "_StrafeGhost"
            vis.Size = p.Size; vis.Anchored = true; vis.CanCollide = false
            vis.CastShadow = false; vis.Material = Enum.Material.Neon
            vis.Color = Color3.fromRGB(255, 255, 255); vis.Transparency = 0; vis.Parent = getgenv().Camera
            
            local offset = root.CFrame:Inverse() * p.CFrame
            getgenv().StrafeVisParts[p.Name] = {part = vis, offset = offset, currentCF = vis.CFrame}
        end
    end
    
    local alpha = 0.18
    getgenv().CurrentStrafeCF = root.CFrame
    getgenv().StrafeVisConnection = getgenv().RunService.RenderStepped:Connect(function()
        if not getgenv().CurrentStrafeCF then return end
        for _, data in pairs(getgenv().StrafeVisParts) do
            local targetCF = getgenv().CurrentStrafeCF * data.offset
            data.currentCF = data.currentCF:Lerp(targetCF, alpha)
            data.part.CFrame = data.currentCF
        end
    end)
end
local function stopStrafe()
    if getgenv().ForceHit.StrafeConnection then
        getgenv().ForceHit.StrafeConnection:Disconnect()
        getgenv().ForceHit.StrafeConnection = nil
    end
    destroyStrafeVisualizer()
    resetStrafeCamera()
end

local function startStrafe()
    if getgenv().ForceHit.StrafeConnection then getgenv().ForceHit.StrafeConnection:Disconnect() end
    if getgenv().ForceHit.VisualizeStrafe then createStrafeVisualizer() end

    local strafeTime = 0
    local voidPhase = false
    local voidTimer = 0

    getgenv().ForceHit.StrafeConnection = RunService.Heartbeat:Connect(function(dt)
        strafeTime = strafeTime + dt
        
        local target = getgenv().ForceHitTarget 
        if not (Toggles.StrafeToggle and Toggles.StrafeToggle.Value) or not target then
            stopStrafe()
            return
        end

        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local targetChar = target.Character
        local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
        
        if not root or not targetRoot or not targetChar:FindFirstChildOfClass("Humanoid") or targetChar:FindFirstChildOfClass("Humanoid").Health <= 0 then
            return
        end

        pcall(function() root:SetNetworkOwner(LocalPlayer) end)

        local targetPos = targetRoot.Position
        local desired = nil

        local mode = Options.StrafeModeDropdown.Value
        if mode == "Orbit" then
            local speed = Options.StrafeSpeedSlider.Value
            local dist = Options.StrafeDistanceSlider.Value
            local height = Options.StrafeHeightSlider.Value
            desired = CFrame.lookAt(targetPos + Vector3.new(math.cos(strafeTime * speed) * dist, height, math.sin(strafeTime * speed) * dist), targetPos)
            
        elseif mode == "Random" then
            local t = strafeTime * 20
            local offset = Vector3.new(math.noise(t, 0, 0) * 15, Options.StrafeHeightSlider.Value, math.noise(0, 0, t) * 15)
            desired = CFrame.lookAt(targetPos + offset, targetPos)
            
        elseif mode == "Void Shoot" then
            voidTimer = voidTimer + dt
            local isShooting = (tick() - (getgenv().LastShotTime or 0) < 0.1)
            
            if isShooting then
                desired = CFrame.lookAt(targetPos + Vector3.new(0, 150, 2), targetPos) 
                if voidTimer >= 0.13 then 
                    voidPhase = not voidPhase
                    voidTimer = 0
                end
                desired = voidPhase and CFrame.new(targetPos + Vector3.new(0, 1000, 0)) or CFrame.lookAt(targetPos + Vector3.new(0, 3, 3), targetPos)
            end
        end

        if desired then
            getgenv().ForceHit.CurrentStrafeCF = desired 
            
            if Toggles.spoofstrafe and Toggles.spoofstrafe.Value then
                local oldCF = root.CFrame
                root.CFrame = desired
                RunService.RenderStepped:Wait()
                root.CFrame = oldCF
            else
                root.CFrame = desired
            end
        end
    end)
end

getgenv().startSpectate = function()
    if getgenv().SpectateConnection then getgenv().SpectateConnection:Disconnect() ; getgenv().SpectateConnection = nil end
    getgenv().SpectateConnection = getgenv().RunService.Heartbeat:Connect(function()
        if not (Toggles.SpectateTarget and Toggles.SpectateTarget.Value) then
            getgenv().resetStrafeCamera()
            if getgenv().SpectateConnection then getgenv().SpectateConnection:Disconnect() end
            getgenv().SpectateConnection = nil
            return
        end
        if not getgenv().ForceHitTarget or not getgenv().ForceHitTarget.Character then return end
        local targetHum = getgenv().ForceHitTarget.Character:FindFirstChildWhichIsA("Humanoid")
        if targetHum and getgenv().Camera.CameraSubject ~= targetHum then
            getgenv().Camera.CameraType = Enum.CameraType.Custom
            getgenv().Camera.CameraSubject = targetHum
        end
    end)
end

getgenv().Window = getgenv().Library:CreateWindow({ Title = getgenv().gameName, Center = true, AutoShow = true, Resizable = true, TabPadding = 10 })

-- tabs are grouped by what a feature DOES, never by which game it came from.
-- HvH and Misc carry too many boxes for one page, so each is split into icon
-- sub-tabs, and every page keeps its two columns within a few widgets of each
-- other so one side is never a long scroll while the other is nearly empty.
getgenv().Tabs = {
    Main = getgenv().Window:AddTab('HvH', { Subtabs = true }),
    Visuals = getgenv().Window:AddTab('Visuals'),
    Skins = getgenv().Window:AddTab('Skins'),
    Misc = getgenv().Window:AddTab('Misc', { Subtabs = true }),
    Performance = getgenv().Window:AddTab('Performance'),
    Settings = getgenv().Window:AddSettingsTab(),
}
getgenv().Tabs.Character = getgenv().Tabs.Misc

if not getgenv().AntiStaffSettings then
    getgenv().AntiStaffSettings = {
        Enabled = true,
        Action = "Notify"
    }
end

-- sub-tabs (icon strip), grouped so both columns of each page stay balanced
--   Aim   : Legit + God Block        | Force Hit, Forcehit Checks, Triggerbot, Camera Lock
getgenv().Pages = {
    Aim        = getgenv().Tabs.Main:AddSubTab('103174889897193'),
    Rage       = getgenv().Tabs.Main:AddSubTab('103863157706913'),
    Tools      = getgenv().Tabs.Main:AddSubTab('109463522861706'),
    Player     = getgenv().Tabs.Misc:AddSubTab('111178525804834'),
    Automation = getgenv().Tabs.Misc:AddSubTab('111386589037485'),
    Movement   = getgenv().Tabs.Misc:AddSubTab('115907015044719'),
    Farm       = getgenv().Tabs.Misc:AddSubTab('116339777575852'),
}

-- HvH: Legit / God Block | Force Hit, Forcehit Checks, Triggerbot, Camera Lock
getgenv().LegitGb      = getgenv().Pages.Aim:AddLeftGroupbox('Legit')
getgenv().MainGb       = getgenv().Pages.Aim:AddRightGroupbox('Force Hit')
getgenv().ChecksGb     = getgenv().Pages.Aim:AddRightGroupbox('Forcehit Checks')

-- HvH: KnifeBot | Desync
getgenv().KnifeGb      = getgenv().Pages.Tools:AddLeftGroupbox('KnifeBot')
getgenv().VoidGb       = getgenv().Pages.Tools:AddRightGroupbox('Desync')

-- "hit visuals" is the HUD / tracer / damage layer, so it sits with the other
-- visual feedback in the Visuals tab rather than in HvH
getgenv().HitVisualsGb = getgenv().Tabs.Visuals:AddLeftGroupbox('hit visuals')

-- the ex-Autofarm boxes are automation for 1v1 servers, so they live in Misc
getgenv().AutofarmSettingsGb      = getgenv().Pages.Farm:AddLeftGroupbox('1v1 Settings')
getgenv().AutofarmCustomizationGb = getgenv().Pages.Farm:AddRightGroupbox('Customization')

getgenv().AutofarmSettingsGb:AddToggle('AutofarmEnabled', {
    Text = 'Enable Autofarm',
    Default = false,
})
getgenv().AutofarmSettingsGb:AddToggle('AutofarmAntiAFK', {
    Text = 'Anti AFK',
    Default = true,
})
getgenv().AutofarmSettingsGb:AddInput('AutofarmWinnerUsername', {
    Default = 'rwnr',
    Numeric = false,
    Finished = false,
    Text = 'Winner Username',
    Placeholder = 'Winner Username',
})
getgenv().AutofarmSettingsGb:AddInput('AutofarmLoserUsername', {
    Default = 'bancrypto',
    Numeric = false,
    Finished = false,
    Text = 'Loser Username',
    Placeholder = 'Loser Username',
})

getgenv().AutofarmCustomizationGb:AddDropdown('AutofarmWeaponMode', {
    Text = 'Weapon Mode',
    Values = { 'DoubleBarrel', 'Revolver', 'Knife', 'SMG' },
    Default = 'DoubleBarrel',
})
getgenv().AutofarmCustomizationGb:AddToggle('AutofarmAimlockLoser', {
    Text = 'aimlock the loser',
    Default = true,
})
getgenv().AutofarmCustomizationGb:AddInput('AutofarmStaffGroupId', {
    Default = '34199407',
    Numeric = true,
    Finished = false,
    Text = 'Staff Group ID',
    Placeholder = 'Staff Group ID',
})
getgenv().AutofarmCustomizationGb:AddSlider('AutofarmSkyBoxHeight', {
    Text = 'Sky Box Height',
    Default = 500,
    Min = 0,
    Max = 5000,
    Rounding = 0,
})
getgenv().AutofarmCustomizationGb:AddSlider('AutofarmForceFieldDelay', {
    Text = 'ForceField Delay',
    Default = 0.5,
    Min = 0,
    Max = 3,
    Rounding = 1,
})

do
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local VirtualUser = game:GetService("VirtualUser")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")

    local LocalPlayer = Players.LocalPlayer
    local MainEvent = ReplicatedStorage:FindFirstChild("MainEvent")

    getgenv().AutofarmState = getgenv().AutofarmState or {
        InBox = false,
        Padded = false,
        EnteredAt = 0,
        BasePlate = nil,
    }

    local function afToggle(name)
        local t = Toggles[name]
        return t and t.Value
    end

    local function afOption(name, fallback)
        local o = Options[name]
        if o and o.Value ~= nil then
            return o.Value
        end
        return fallback
    end

    local function afGetChar()
        local char = LocalPlayer.Character
        if not char then return nil end
        local hum = char:FindFirstChildOfClass("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        return char, hum, root
    end

    local function afWinnerName()
        return tostring(afOption('AutofarmWinnerUsername', 'rwnr'))
    end

    local function afLoserName()
        return tostring(afOption('AutofarmLoserUsername', 'bancrypto'))
    end

    local function afRole()
        if LocalPlayer.Name == afWinnerName() then
            return "winner"
        end
        if LocalPlayer.Name == afLoserName() then
            return "loser"
        end
        return nil
    end

    local function afTargetPlayer()
        local role = afRole()
        if role == "winner" then
            return Players:FindFirstChild(afLoserName())
        elseif role == "loser" then
            return Players:FindFirstChild(afWinnerName())
        end
        return nil
    end

    local function afWeaponNames(mode)
        if mode == "DoubleBarrel" then
            return { "[Double-Barrel]", "[DoubleBarrel]" }
        elseif mode == "Revolver" then
            return { "[Revolver]" }
        elseif mode == "SMG" then
            return { "[SMG]" }
        end
        return { "[Knife]" }
    end

    local function afEquipWeapon(mode)
        local char, hum = afGetChar()
        if not char or not hum then return nil end

        for _, name in ipairs(afWeaponNames(mode)) do
            local equipped = char:FindFirstChild(name)
            if equipped and equipped:IsA("Tool") then
                return equipped
            end
        end

        local backpack = LocalPlayer:FindFirstChild("Backpack")
        if backpack then
            for _, name in ipairs(afWeaponNames(mode)) do
                local tool = backpack:FindFirstChild(name)
                if tool and tool:IsA("Tool") then
                    hum:EquipTool(tool)
                    task.wait(0.1)
                    return char:FindFirstChild(name) or tool
                end
            end
        end

        return nil
    end

    local function afExpandKnifeHitbox()
        local knife = afEquipWeapon("Knife")
        local handle = knife and knife:FindFirstChild("Handle")
        local hitbox = handle and handle:FindFirstChild("HITBOX_PART")
        if hitbox and hitbox:IsA("BasePart") then
            hitbox.Size = Vector3.new(21, 21, 21)
        end
    end

    local function afInBoxCheck()
        local folder = workspace:FindFirstChild("Players")
        local inbox = folder and folder:FindFirstChild("InBox")
        return inbox and inbox:FindFirstChild(LocalPlayer.Name) ~= nil or false
    end

    local function afBothInCharacters()
        local folder = workspace:FindFirstChild("Players")
        local chars = folder and folder:FindFirstChild("Characters")
        if not chars then return false end
        return chars:FindFirstChild(afWinnerName()) ~= nil and chars:FindFirstChild(afLoserName()) ~= nil
    end

    local function afGetPads(fp)
        local j1 = fp and fp:FindFirstChild("JoinFight1")
        local j2 = fp and fp:FindFirstChild("JoinFight2")
        if not j1 or not j2 then return nil, nil end
        return j1:FindFirstChild("Region"), j2:FindFirstChild("Region")
    end

    local function afFindEmptyFightPlace()
        local ignored = workspace:FindFirstChild("Ignored")
        local boxes = ignored and ignored:FindFirstChild("Boxes")
        if not boxes then return nil end
        for _, fp in ipairs(boxes:GetChildren()) do
            if fp.Name == "FightPlace" then
                local p1 = fp:FindFirstChild("Player1")
                local p2 = fp:FindFirstChild("Player2")
                if p1 and p2 and (p1.Value == "" or p1.Value == nil) and (p2.Value == "" or p2.Value == nil) then
                    return fp
                end
            end
        end
        return nil
    end

    local function afFindWinnerFightPlace()
        local winnerPlayer = Players:FindFirstChild(afWinnerName())
        local winnerRoot = winnerPlayer and winnerPlayer.Character and winnerPlayer.Character:FindFirstChild("HumanoidRootPart")
        local ignored = workspace:FindFirstChild("Ignored")
        local boxes = ignored and ignored:FindFirstChild("Boxes")
        if not winnerRoot or not boxes then return nil, nil end

        for _, fp in ipairs(boxes:GetChildren()) do
            if fp.Name == "FightPlace" then
                local pad1, pad2 = afGetPads(fp)
                if pad1 and (winnerRoot.Position - pad1.Position).Magnitude < 10 then
                    return fp, 1
                elseif pad2 and (winnerRoot.Position - pad2.Position).Magnitude < 10 then
                    return fp, 2
                end
            end
        end
        return nil, nil
    end

    local function afTeleport(cf)
        local _, _, root = afGetChar()
        if root then
            root.CFrame = cf
        end
    end

    local function afCreateBasePlate()
        local state = getgenv().AutofarmState
        local height = tonumber(afOption('AutofarmSkyBoxHeight', 500)) or 500
        if state.BasePlate and state.BasePlate.Parent then
            state.BasePlate.CFrame = CFrame.new(0, height, 0)
            return state.BasePlate
        end

        local part = Instance.new("Part")
        part.Name = "_67"
        part.Size = Vector3.new(60, 1, 60)
        part.Anchored = true
        part.CanCollide = true
        part.Transparency = 1
        part.CFrame = CFrame.new(0, height, 0)
        part.Parent = workspace
        state.BasePlate = part
        return part
    end

    local function afRemoveBasePlate()
        local state = getgenv().AutofarmState
        if state.BasePlate then
            pcall(function() state.BasePlate:Destroy() end)
            state.BasePlate = nil
        end
    end

    local function afIsTargetAlive(target)
        local char = target and target.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local body = char and char:FindFirstChild("BodyEffects")
        local ko = body and body:FindFirstChild("K.O")
        if not hum or hum.Health <= 0 then return false end
        if ko and ko.Value then return false end
        return true
    end

    local function afHasForceField(target)
        local char = target and target.Character
        return char and char:FindFirstChildOfClass("ForceField") ~= nil or false
    end

    local function afAimlockTarget(target)
        if not afToggle('AutofarmAimlockLoser') then return end
        local _, _, root = afGetChar()
        local head = target and target.Character and target.Character:FindFirstChild("Head")
        if root and head then
            local pos = root.Position
            root.CFrame = CFrame.lookAt(pos, Vector3.new(head.Position.X, pos.Y, head.Position.Z))
        end
    end

    local function afBuildShootArgs(origin, head)
        local shootArgs = { {}, {}, origin, origin, workspace:GetServerTimeNow() }
        local hitPos = head.Position
        for i = 1, 5 do
            shootArgs[1][i] = { Normal = hitPos, Instance = head, Position = hitPos }
            shootArgs[2][i] = { thePart = head, theOffset = Vector3.zero }
        end
        return shootArgs
    end

    local function afAutoFire(target)
        local _, _, root = afGetChar()
        local head = target and target.Character and target.Character:FindFirstChild("Head")
        if MainEvent and root and head then
            MainEvent:FireServer("Shoot", afBuildShootArgs(root.Position, head))
        end
    end

    local function afAutoSwingKnife()
        local knife = afEquipWeapon("Knife")
        if knife then
            afExpandKnifeHitbox()
            knife:Activate()
        end
    end

    LocalPlayer.Idled:Connect(function()
        if not afToggle('AutofarmAntiAFK') then return end
        VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        task.wait(0.1)
        VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    end)

    task.spawn(function()
        while task.wait(0.1) do
            if not afToggle('AutofarmEnabled') then
                getgenv().AutofarmState.InBox = false
                getgenv().AutofarmState.Padded = false
                getgenv().AutofarmState.EnteredAt = 0
                afRemoveBasePlate()
                continue
            end

            local role = afRole()
            if not role then continue end

            local char, hum, root = afGetChar()
            if not char or not hum or not root or hum.Health <= 0 then continue end

            local mode = afOption('AutofarmWeaponMode', 'DoubleBarrel')
            local state = getgenv().AutofarmState

            if afInBoxCheck() then
                if not state.InBox then
                    state.InBox = true
                    state.Padded = false
                    state.EnteredAt = tick()
                end

                local plate = afCreateBasePlate()
                if plate then
                    if role == "winner" then
                        afTeleport(plate.CFrame + Vector3.new(0, 3, 2))
                    else
                        afTeleport(plate.CFrame + Vector3.new(0, 3, 0))
                    end
                end

                local target = afTargetPlayer()
                local ffDelay = tonumber(afOption('AutofarmForceFieldDelay', 0.5)) or 0.5
                if role == "winner" and target and afIsTargetAlive(target) and not afHasForceField(target) and tick() - state.EnteredAt >= ffDelay then
                    afAimlockTarget(target)
                    if mode == "Knife" then
                        afAutoSwingKnife()
                    else
                        afEquipWeapon(mode)
                        afAutoFire(target)
                    end
                end
            else
                if state.InBox then
                    state.InBox = false
                    state.Padded = false
                    state.EnteredAt = 0
                    afRemoveBasePlate()
                end

                if not state.Padded and afBothInCharacters() then
                    state.Padded = true
                    task.spawn(function()
                        while afToggle('AutofarmEnabled') and not afInBoxCheck() do
                            local currentRole = afRole()
                            if currentRole == "winner" then
                                local fp = afFindEmptyFightPlace()
                                local pad1 = fp and afGetPads(fp)
                                if pad1 then
                                    afTeleport(pad1.CFrame + Vector3.new(0, 3, 0))
                                end
                            elseif currentRole == "loser" then
                                local fp, winnerPadIndex = afFindWinnerFightPlace()
                                local pad1, pad2 = afGetPads(fp)
                                if winnerPadIndex == 1 and pad2 then
                                    afTeleport(pad2.CFrame + Vector3.new(0, 3, 0))
                                elseif winnerPadIndex == 2 and pad1 then
                                    afTeleport(pad1.CFrame + Vector3.new(0, 3, 0))
                                end
                            end
                            task.wait(0.1)
                        end
                        state.Padded = false
                    end)
                end
            end
        end
    end)
end



local desync_setback = Instance.new("Part")
desync_setback.Name = "SND_DesyncSetback"
desync_setback.Size = Vector3.new(2, 2, 1)
desync_setback.Anchored = true
desync_setback.CanCollide = false
desync_setback.Transparency = 1
desync_setback.Parent = getgenv().Workspace

getgenv().desync = {
    enabled = false,
    mode = "Void",
    old_position = nil,
    target_position = nil,
    void_time = 0.4,
    normal_time = 0.133,
    timer = 0,
    custom_offset = Vector3.new(0, 0, 0),
}

local DesyncIndicatorGui = Instance.new("ScreenGui")
DesyncIndicatorGui.Name = "SND_DesyncIndicator"
DesyncIndicatorGui.ResetOnSpawn = false
DesyncIndicatorGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
DesyncIndicatorGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local DesyncIndicatorImage = Instance.new("ImageLabel")
DesyncIndicatorImage.Name = "Indicator"
DesyncIndicatorImage.Size = UDim2.new(0, 55, 0, 55)
DesyncIndicatorImage.BackgroundTransparency = 1
DesyncIndicatorImage.Image = "rbxassetid://17446642923"
DesyncIndicatorImage.Visible = false
DesyncIndicatorImage.ZIndex = 10
DesyncIndicatorImage.Parent = DesyncIndicatorGui

local dToolCheckEnabled = false
local dIndicatorEnabled = false
local dIndicatorSpin = false
local dIndicatorSize = 55
local dIndicatorRotation = 0
local dIndicatorLastPos = nil

local StrafeVis = {
    Enabled = false,
    Transparency = 0.5,
    Color = Color3.fromRGB(0, 140, 255),
    Folder = nil,
    Connection = nil,
    Parts = {},
    LastTool = nil,
}

local function dDestroyVisualizer()
    if StrafeVis.Connection then StrafeVis.Connection:Disconnect() ; StrafeVis.Connection = nil end
    if StrafeVis.Folder then StrafeVis.Folder:Destroy() ; StrafeVis.Folder = nil end
    StrafeVis.Parts = {}
end

local function dCreateVisualizer()
    dDestroyVisualizer()
    local char = getgenv().LocalPlayer.Character ; if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart") ; if not root then return end
    local folder = Instance.new("Folder")
    folder.Name = "SND_DesyncVisualizer"
    folder.Parent = getgenv().Workspace
    StrafeVis.Folder = folder
    for _, p in ipairs(char:GetChildren()) do
        if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
            local ghost = Instance.new("Part")
            ghost.Size = p.Size ; ghost.Anchored = true ghost.CanCollide = false ghost.CastShadow = false
            ghost.Material = Enum.Material.Neon ; ghost.Color = StrafeVis.Color ghost.Transparency = StrafeVis.Transparency
            ghost.TopSurface = Enum.SurfaceType.Smooth ; ghost.BottomSurface = Enum.SurfaceType.Smooth
            ghost.Parent = folder
            StrafeVis.Parts[p] = { part = ghost, offset = root.CFrame:Inverse() * p.CFrame }
        end
    end
    StrafeVis.Connection = getgenv().RunService.RenderStepped:Connect(function()
        local targetCF = getgenv().desync.target_position
        for realPart, data in pairs(StrafeVis.Parts) do
            if not realPart.Parent or not data.part or not data.part.Parent then
                StrafeVis.Parts[realPart] = nil
            else
                if targetCF then data.part.CFrame = targetCF * data.offset end
                data.part.Color = StrafeVis.Color
                data.part.Transparency = StrafeVis.Enabled and StrafeVis.Transparency or 1
            end
        end
    end)
end

local REFRESH_COOLDOWN = 0.04
local FORCE_REFRESH_EVERY = 0.04
local dLastAttempt = 0
local dLastFullCreate = 0

local function dTryUpdateVisualizer()
    if not StrafeVis.Enabled then return end
    local now = tick()
    if now - dLastAttempt < REFRESH_COOLDOWN then return end
    dLastAttempt = now
    local needsFull = now - dLastFullCreate >= FORCE_REFRESH_EVERY
    if not needsFull then
        local char = getgenv().LocalPlayer.Character
        if char then
            local currentTool = char:FindFirstChildWhichIsA("Tool")
            if currentTool ~= StrafeVis.LastTool then needsFull = true ; StrafeVis.LastTool = currentTool end
        end
    end
    if needsFull then
        dCreateVisualizer()
        dLastFullCreate = now
    else
        for _, data in pairs(StrafeVis.Parts) do
            if data.part and data.part.Parent then
                data.part.Color = StrafeVis.Color
                data.part.Transparency = StrafeVis.Transparency
            end
        end
    end
end

local function dSetupVisualizerListeners(char)
    if not char then return end
    char.ChildAdded:Connect(function(child) if child:IsA("Tool") or child:IsA("Accessory") then task.delay(0.03, dTryUpdateVisualizer) end end)
    char.ChildRemoved:Connect(function(child) if child:IsA("Tool") or child:IsA("Accessory") then task.delay(0.03, dTryUpdateVisualizer) end end)
end

task.spawn(function()
    while true do
        task.wait(0.033)
        dTryUpdateVisualizer()
    end
end)

getgenv().LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.15)
    if StrafeVis.Enabled then
        dCreateVisualizer()
        StrafeVis.LastTool = nil
        dLastFullCreate = tick()
        dSetupVisualizerListeners(char)
    end
end)

local function dResetCamera()
    local char = getgenv().LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        getgenv().Workspace.CurrentCamera.CameraSubject = char.Humanoid
    end
end

local function setDesync(state)
    getgenv().desync.enabled = state
    if not state then
        dResetCamera()
        getgenv().desync.timer = 0
        getgenv().desync.target_position = nil
        desync_setback.CFrame = CFrame.new(0, -2000, 0)
        DesyncIndicatorImage.Visible = false
        dIndicatorRotation = 0
        dIndicatorLastPos = nil
    end
end

getgenv().RunService.Heartbeat:Connect(function(dt)
    local desync = getgenv().desync
    if not desync.enabled then
        desync.target_position = nil
        return
    end
    local char = getgenv().LocalPlayer.Character
    if not char then return end
    if dToolCheckEnabled and char:FindFirstChildWhichIsA("Tool") then
        desync.target_position = nil
        dResetCamera()
        desync_setback.CFrame = CFrame.new(0, -2000, 0)
        return
    end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    desync.old_position = root.CFrame
    local target = desync.old_position
    if desync.mode == "void" then
        target = CFrame.new(root.Position + Vector3.new(math.random(-9e8, 9e8), math.random(1e8, 9e8), math.random(-9e8, 9e8)))
    elseif desync.mode == "spam void" then
        desync.timer += dt
        if desync.timer < desync.void_time then
            target = CFrame.new(root.Position + Vector3.new(math.random(-9e8, 9e8), math.random(1e8, 9e8), math.random(-9e8, 9e8)))
        end
        if desync.timer >= desync.void_time + desync.normal_time then desync.timer = 0 end
    elseif desync.mode == "Chaos" then
        local t = tick() * 999
        target = CFrame.new(root.Position + Vector3.new(math.sin(t) * 9e8, math.abs(math.cos(t * 1.3)) * 9e8, math.sin(t * 0.7) * 9e8))
    elseif desync.mode == "Epilepsy" then
        local flip = math.floor(tick() * 60) % 2 == 0
        target = flip and CFrame.new(root.Position + Vector3.new(9e8, 9e8, 9e8)) or CFrame.new(root.Position + Vector3.new(-9e8, -9e8, -9e8))
    elseif desync.mode == "Custom" then
        target = desync.old_position + desync.custom_offset
    elseif desync.mode == "Underground" then
        target = CFrame.new(root.Position - Vector3.new(0, 6, 0)) * CFrame.Angles(math.pi/2, 0, 0)
    end
    desync.target_position = target
    dIndicatorLastPos = target.Position
    root.CFrame = target
    desync_setback.CFrame = desync.old_position
    getgenv().Workspace.CurrentCamera.CameraSubject = desync_setback
    getgenv().RunService.RenderStepped:Wait()
    root.CFrame = desync.old_position
    desync_setback.CFrame = CFrame.new(0, -2000, 0)
    dResetCamera()
end)

getgenv().RunService.RenderStepped:Connect(function()
    if not getgenv().desync.enabled or not dIndicatorEnabled or not dIndicatorLastPos then
        DesyncIndicatorImage.Visible = false
        return
    end
    local cam = getgenv().Workspace.CurrentCamera
    local screenPos, onScreen = cam:WorldToViewportPoint(dIndicatorLastPos)
    if onScreen then
        local half = dIndicatorSize / 2
        DesyncIndicatorImage.Size = UDim2.new(0, dIndicatorSize, 0, dIndicatorSize)
        DesyncIndicatorImage.Position = UDim2.new(0, screenPos.X - half, 0, screenPos.Y - half)
        if dIndicatorSpin then
            dIndicatorRotation = (dIndicatorRotation + 2) % 360
            DesyncIndicatorImage.Rotation = dIndicatorRotation
        else
            DesyncIndicatorImage.Rotation = 0
        end
        DesyncIndicatorImage.Visible = true
    else
        DesyncIndicatorImage.Visible = false
    end
end)

if getgenv().LocalPlayer.Character then
    task.delay(0.1, function() dSetupVisualizerListeners(getgenv().LocalPlayer.Character) end)
end


local plrs = game:GetService("Players")
local uis = game:GetService("UserInputService")
local lp = plrs.LocalPlayer

local animId = "70883871260184"
local gm_on = false
local gm_root, gm_ghost, gm_hip, gm_track
local gm_stepped_conn

local function gm_anim()
    local char = lp.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
    local a = Instance.new("Animation")
    a.AnimationId = "rbxassetid://" .. animId
    gm_track = animator:LoadAnimation(a)
    gm_track.Priority = Enum.AnimationPriority.Core
    gm_track:Play(0, 1, 0)
    a:Destroy()
    task.delay(0, function()
        if gm_track then
            gm_track.TimePosition = 0.7
            task.delay(0.3, function()
                if gm_track then gm_track:AdjustSpeed(0) end
            end)
        end
    end)

    -- Force local visual joints to stay normal to prevent visual character break and client physics FPS lag
    if gm_stepped_conn then gm_stepped_conn:Disconnect() end
    gm_stepped_conn = RunService.Stepped:Connect(function()
        if not gm_on or not lp.Character then
            if gm_stepped_conn then gm_stepped_conn:Disconnect() ; gm_stepped_conn = nil end
            return
        end
        for _, desc in ipairs(lp.Character:GetDescendants()) do
            if desc:IsA("Motor6D") then
                desc.Transform = CFrame.new()
            end
        end
    end)

    return true
end

local function gm_fake()
    -- Disabled to prevent physics replication lag and FPS drop
end

local function gm_undo()
    -- Disabled to prevent physics replication lag and FPS drop
end

local function gm_start()
    if gm_on then return end
    gm_on = true
    if not gm_anim() then gm_on = false ; return end
    task.wait(0.1)
    gm_fake()
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Godmode",
        Text = "Godmode is now enabled",
        Duration = 3,
    })
end

local function gm_stop()
    if not gm_on then return end
    gm_on = false
    if gm_track then pcall(function() gm_track:Stop() end) ; gm_track = nil end
    if gm_stepped_conn then gm_stepped_conn:Disconnect() ; gm_stepped_conn = nil end
    gm_undo()
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Godmode",
        Text = "Godmode is now disabled nigga",
        Duration = 3,
    })
end

lp.CharacterRemoving:Connect(function()
    if gm_on then gm_stop() end
end)

VoidGb:AddToggle('GodmodeToggle', {
    Text = 'Godmode',
    Default = false,
    Callback = function(v)
        if v then gm_start() else gm_stop() end
    end
}):AddKeyPicker('GodmodeKeybind', {
    Default = 'B',
    Mode = 'Toggle',
    Text = 'Godmode',
    Callback = function(state)
        if uis:GetFocusedTextBox() then return end
        if not Toggles.GodmodeToggle.Value then return end
        if state then gm_start() else gm_stop() end
    end
})
VoidGb:AddToggle("DesyncToggle", {
    Text = "enable desync", Default = false,
    Callback = function(v)
        Toggles.DesyncToggle:SetText(v and "Anti Aim: ON" or "Anti Aim: OFF")
        if not v then setDesync(false) end
    end
}):AddKeyPicker("DesyncKeybind", {
    Text = "Bind", Default = "V", Mode = "Toggle",
    Callback = function()
        if getgenv().UserInputService:GetFocusedTextBox() then return end
        if not Toggles.DesyncToggle.Value then return end
        setDesync(not getgenv().desync.enabled)
    end
})

VoidGb:AddDropdown("DesyncMethod", {
    Values = {"void", "spam void", "Chaos", "Epilepsy", "Custom", "Underground"},
    Default = "void", Text = "Mode",
    Callback = function(v) getgenv().desync.mode = v end
})

VoidGb:AddToggle("ToolCheckToggle", {
    Text = "Disable when tool held", Default = false,
    Callback = function(v) dToolCheckEnabled = v end
})

VoidGb:AddToggle("StrafeVisToggle", {
    Text = "Rig", Default = false,
    Callback = function(v)
        StrafeVis.Enabled = v
        if v then
            dCreateVisualizer()
            StrafeVis.LastTool = nil
            dLastFullCreate = tick()
            if getgenv().LocalPlayer.Character then dSetupVisualizerListeners(getgenv().LocalPlayer.Character) end
        else
            dDestroyVisualizer()
        end
    end
}):AddColorPicker("VisColor", {
    Default = ACCENT,
    Callback = function(v)
        StrafeVis.Color = v
        dTryUpdateVisualizer()
    end
})

VoidGb:AddSlider("VisTransparency", {
    Text = "Rig Transparency", Default = 0.5, Min = 0, Max = 1, Rounding = 2,
    Callback = function(v) StrafeVis.Transparency = v ; dTryUpdateVisualizer() end
})

VoidGb:AddToggle("IndicatorToggle", {
    Text = "Indicator", Default = false,
    Callback = function(v)
        dIndicatorEnabled = v
        if not v then
            DesyncIndicatorImage.Visible = false
            dIndicatorRotation = 0
        end
    end
})

VoidGb:AddToggle("IndicatorSpin", {
    Text = "Spin Indicator", Default = false,
    Callback = function(v)
        dIndicatorSpin = v
        if not v then dIndicatorRotation = 0 ; DesyncIndicatorImage.Rotation = 0 end
    end
})

VoidGb:AddSlider("IndicatorSize", {
    Text = "Indicator Size", Default = 55, Min = 20, Max = 150, Rounding = 0,
    Callback = function(v) dIndicatorSize = v end
})

VoidGb:AddSlider("VoidTime", {
    Text = "Void Time", Default = 0.4, Min = 0.05, Max = 2, Rounding = 2,
    Callback = function(v) getgenv().desync.void_time = v end
})

VoidGb:AddSlider("GroundTime", {
    Text = "Ground Time", Default = 0.133, Min = 0.05, Max = 2, Rounding = 2,
    Callback = function(v) getgenv().desync.normal_time = v end
})

VoidGb:AddSlider("CustomX", {
    Text = "X Offset", Default = 0, Min = -25, Max = 25, Rounding = 1,
    Callback = function(v) local d = getgenv().desync ; d.custom_offset = Vector3.new(v, d.custom_offset.Y, d.custom_offset.Z) end
})

VoidGb:AddSlider("CustomY", {
    Text = "Y Offset", Default = 0, Min = -25, Max = 25, Rounding = 1,
    Callback = function(v) local d = getgenv().desync ; d.custom_offset = Vector3.new(d.custom_offset.X, v, d.custom_offset.Z) end
})

VoidGb:AddSlider("CustomZ", {
    Text = "Z Offset", Default = 0, Min = -25, Max = 25, Rounding = 1,
    Callback = function(v) local d = getgenv().desync ; d.custom_offset = Vector3.new(d.custom_offset.X, d.custom_offset.Y, v) end
})

local function createFOV()
    local fov = getgenv().Config.Visual.FOV

    local function makeDrawing(type)
        local d = Drawing.new(type)
        d.Visible = false
        return d
    end

    if not fov.InnerCircle then fov.InnerCircle = makeDrawing("Circle") end
    if not fov.OuterCircle then fov.OuterCircle = makeDrawing("Circle") end
    if not fov.FillCircle then fov.FillCircle = makeDrawing("Circle") end

    if not fov.Lines then
        fov.Lines = {}
        for i = 1, 12 do fov.Lines[i] = makeDrawing("Line") end
    end

    if not fov.Triangles then
        fov.Triangles = {}
        for i = 1, 6 do fov.Triangles[i] = makeDrawing("Triangle") end
    end

    if not fov.ScreenGui then
        local sg = Instance.new("ScreenGui")
        sg.Name = "LarpticFOV"
        sg.IgnoreGuiInset = true
        sg.DisplayOrder = 999
        sg.Parent = game.CoreGui
        fov.ScreenGui = sg

        local frame = Instance.new("Frame")
        frame.Name = "Main"
        frame.BackgroundTransparency = 0
        frame.BorderSizePixel = 0
        frame.AnchorPoint = Vector2.new(0.5, 0.5)
        frame.Parent = sg
        fov.MainFrame = frame

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = frame
        fov.UICorner = corner
    end

    getgenv().LarpticFOV = {
        Inner = fov.InnerCircle,
        Outer = fov.OuterCircle,
        ScreenGui = fov.ScreenGui,
        MainFrame = fov.MainFrame,
        UICorner = fov.UICorner
    }
end

local MiscTabBox = getgenv().Pages.Player:AddLeftTabbox()
local TabCharacter = MiscTabBox:AddTab('Avatar')

local AutoGb = getgenv().Pages.Player:AddRightGroupbox('Auto')
local BodyPartsGb = getgenv().Pages.Player:AddLeftGroupbox('body parts')
local CrosshairGb = getgenv().Pages.Movement:AddRightGroupbox('Crosshair')

do
    CrosshairGb:AddToggle('EnableCrosshair', { Text = 'Enable Crosshair', Default = false })
    CrosshairGb:AddToggle('CrosshairFollowMouse', { Text = 'Follow Mouse', Default = true })
    CrosshairGb:AddSlider('CrosshairGap', { Text = 'Gap', Default = 14, Min = 0, Max = 60, Rounding = 0 })
    CrosshairGb:AddSlider('CrosshairLength', { Text = 'Length', Default = 80, Min = 1, Max = 200, Rounding = 0 })
    CrosshairGb:AddSlider('CrosshairThickness', { Text = 'Thickness', Default = 2, Min = 1, Max = 10, Rounding = 0 })
    CrosshairGb:AddSlider('CrosshairRotation', { Text = 'Rotation Speed', Default = 200, Min = 0, Max = 800, Rounding = 0 })
    CrosshairGb:AddSlider('CrosshairPulseSpeed', { Text = 'Pulse Speed', Default = 3, Min = 0, Max = 15, Rounding = 0 })
    CrosshairGb:AddSlider('CrosshairShadowX', { Text = 'Shadow Offset X', Default = 2, Min = 0, Max = 10, Rounding = 0 })
    CrosshairGb:AddSlider('CrosshairShadowY', { Text = 'Shadow Offset Y', Default = 2, Min = 0, Max = 10, Rounding = 0 })
    CrosshairGb:AddLabel('Line Color'):AddColorPicker('CrosshairColor', { Default = ACCENT, Title = 'Line Color' })
    CrosshairGb:AddLabel('Glow Color'):AddColorPicker('CrosshairGlowColor', { Default = ACCENT, Title = 'Glow Color' })

    local function mkLine(z)
        local l = Drawing.new('Line')
        l.Thickness = 2; l.Color = Color3.fromRGB(255, 255, 255); l.Visible = false; l.ZIndex = z
        return l
    end
    local chLines = { mkLine(5), mkLine(5), mkLine(5), mkLine(5) }
    local glowLines = { mkLine(4), mkLine(4), mkLine(4), mkLine(4) }
    getgenv().CrosshairLines = {
        chLines[1], chLines[2], chLines[3], chLines[4],
        glowLines[1], glowLines[2], glowLines[3], glowLines[4],
    }

    local dirs = { Vector2.new(0, -1), Vector2.new(0, 1), Vector2.new(-1, 0), Vector2.new(1, 0) }

    getgenv().CrosshairConnection = getgenv().RunService.RenderStepped:Connect(function()
        if not (Toggles.EnableCrosshair and Toggles.EnableCrosshair.Value) then
            for _, l in ipairs(chLines) do l.Visible = false end
            for _, l in ipairs(glowLines) do l.Visible = false end
            return
        end
        local vp = getgenv().Camera and getgenv().Camera.ViewportSize or Vector2.new(0, 0)
        local center
        if Toggles.CrosshairFollowMouse and Toggles.CrosshairFollowMouse.Value then
            local m = getgenv().UserInputService:GetMouseLocation()
            center = Vector2.new(m.X, m.Y)
        else
            center = Vector2.new(vp.X / 2, vp.Y / 2)
        end
        local gap = (Options.CrosshairGap and Options.CrosshairGap.Value) or 14
        local len = (Options.CrosshairLength and Options.CrosshairLength.Value) or 80
        local thick = (Options.CrosshairThickness and Options.CrosshairThickness.Value) or 2
        local rotSpeed = (Options.CrosshairRotation and Options.CrosshairRotation.Value) or 0
        local pulseSpeed = (Options.CrosshairPulseSpeed and Options.CrosshairPulseSpeed.Value) or 0
        local shadowX = (Options.CrosshairShadowX and Options.CrosshairShadowX.Value) or 0
        local shadowY = (Options.CrosshairShadowY and Options.CrosshairShadowY.Value) or 0
        local col = (Options.CrosshairColor and Options.CrosshairColor.Value) or Color3.fromRGB(255, 255, 255)
        local glowCol = (Options.CrosshairGlowColor and Options.CrosshairGlowColor.Value) or Color3.fromRGB(133, 220, 255)

        local t = tick()
        if pulseSpeed > 0 then
            gap = math.max(0, gap + math.sin(t * pulseSpeed) * 6)
        end
        local rot = math.rad((t * rotSpeed) % 360)
        local cosR, sinR = math.cos(rot), math.sin(rot)
        local shadow = Vector2.new(shadowX, shadowY)

        for i = 1, 4 do
            local d = dirs[i]
            local rd = Vector2.new(d.X * cosR - d.Y * sinR, d.X * sinR + d.Y * cosR)
            local from = center + rd * gap
            local to = center + rd * (gap + len)

            local gl = glowLines[i]
            gl.From = from + shadow; gl.To = to + shadow
            gl.Color = glowCol; gl.Thickness = thick + 3; gl.Visible = true

            local l = chLines[i]
            l.From = from; l.To = to
            l.Color = col; l.Thickness = thick; l.Visible = true
        end
    end)
end

local function applyAutoBox()
    local AutoBox = AutoGb
    local MoveBox = getgenv().Pages.Movement:AddLeftGroupbox('Movement')
    
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer
local function PerformReset()
    StarterGui:SetCore("ResetButtonCallback", true)
    local character = LocalPlayer.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        
        if getgenv().replicatesignal then
            getgenv().replicatesignal(LocalPlayer.Kill)
        elseif humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.Dead)
            humanoid.Health = 0 
        end
    end
end

local ForceResetToggle = AutoBox:AddToggle('ForceReset', {
    Text = 'Force Reset',
    Default = false,
    Tooltip = 'Enable this to allow the Keybind to work',
    SyncToggleState = false,
    Callback = function(Value)
        if Value then
            PerformReset()
        end
    end
})

ForceResetToggle:AddKeyPicker('ForceResetKey', {
    Default = 'P',
    Mode = 'Toggle',
    Text = 'Force Reset',
    NoUI = false,
    Callback = function()
        if Toggles.ForceReset.Value then
            PerformReset()
        end
    end
})

getgenv().ForceHit = {}

getgenv().ForceHit.StrafeMode = "Orbit"
getgenv().ForceHit.LookAtTarget = false
getgenv().ForceHit.SpectateTarget = false
local KillAura = getgenv().Pages.Rage:AddRightGroupbox("Strafe")

KillAura:AddToggle("StompTarget", {Text="Stomp Target", Default=false, Callback=function(v) getgenv().stompTargetEnabled=v end})

local DesyncPart = Instance.new("Part")
DesyncPart.Name="DesyncVisual"
DesyncPart.Size=Vector3.new(2,2,1)
DesyncPart.Transparency=1
DesyncPart.CanCollide=false
DesyncPart.Anchored=true
DesyncPart.Parent=workspace

local strafeToggleEnabled = false
local strafeKeybindEnabled = false
local strafeCamera = workspace.CurrentCamera

local function resetStrafeCamera()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildWhichIsA("Humanoid")
    if hum then strafeCamera.CameraSubject = hum end
end

local toggle = KillAura:AddToggle("StrafeToggle", {Text="Target Strafe", Default=false, Callback=function(v)
    strafeToggleEnabled = v
    getgenv().ForceHit.StrafeEnabled = v and strafeKeybindEnabled
    if not v then
        resetStrafeCamera()
        getgenv().ForceHit.LookAtTarget = true
    end
end})

toggle:AddKeyPicker("StrafeKeybind", {Default="N", Mode="Toggle", NoSync=true, Text="Target Strafe", Callback=function(s)
    strafeKeybindEnabled = s
    getgenv().ForceHit.StrafeEnabled = strafeToggleEnabled and s
    if not s then
        resetStrafeCamera()
        getgenv().ForceHit.LookAtTarget = true
    end
end})

KillAura:AddToggle("spoofstrafe", {Text="Spoof", Default=false, Callback=function(v)
    getgenv().ForceHit.strafespoof = v
    if not v then resetStrafeCamera() end
end})

KillAura:AddToggle("visualizestrafe", {Text="Visualize Strafe", Default=false, Callback=function(v)
    getgenv().ForceHit.VisualizeStrafe = v
    if not v and getgenv().ForceHit.Visualizer then
        getgenv().ForceHit.Visualizer:Destroy()
        getgenv().ForceHit.Visualizer = nil
        getgenv().ForceHit.VisualizerMotors = nil
    end
end})


KillAura:AddSlider("StrafeSpeedSlider", {Text="Strafe Speed", Min=1, Max=30, Default=5, Rounding=1, Callback=function(v) getgenv().ForceHit.StrafeSpeed=v end})
KillAura:AddSlider("StrafeDistanceSlider", {Text="Strafe Distance", Min=1, Max=20, Default=5, Rounding=1, Callback=function(v) getgenv().ForceHit.StrafeDistance=v end})
KillAura:AddSlider("StrafeHeightSlider", {Text="Strafe Height", Min=-15, Max=15, Default=0, Rounding=1, Callback=function(v) getgenv().ForceHit.StrafeHeight=v end})

KillAura:AddDropdown("StrafeModeDropdown", {Values={"Orbit","Random","Void Shoot"}, Default="Orbit", Text="Strafe Mode", Callback=function(v) getgenv().ForceHit.StrafeMode=v end})


local function destroyStrafeVisualizer()
    if getgenv().ForceHit.StrafeVisConnection then
        getgenv().ForceHit.StrafeVisConnection:Disconnect()
        getgenv().ForceHit.StrafeVisConnection = nil
    end
    if getgenv().ForceHit.StrafeVisParts then
        for _, data in pairs(getgenv().ForceHit.StrafeVisParts) do
            if data.part then data.part:Destroy() end
        end
        getgenv().ForceHit.StrafeVisParts = nil
    end
end

local function createStrafeVisualizer()
    destroyStrafeVisualizer()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local parts = {}
    getgenv().ForceHit.StrafeVisParts = parts
    for _, p in ipairs(char:GetChildren()) do
        if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
            local vis = Instance.new("Part")
            vis.Name = p.Name.."_StrafeGhost"
            vis.Size = p.Size
            vis.Anchored = true
            vis.CanCollide = false
            vis.CastShadow = false
            vis.Material = Enum.Material.Neon
            vis.Color = Color3.fromRGB(255,255,255)
            vis.Transparency = 0
            vis.Parent = strafeCamera
            local offset = root.CFrame:Inverse() * p.CFrame
            parts[p.Name] = {part=vis, offset=offset, currentCF=vis.CFrame}
        end
    end
    local alpha = 0.18
    getgenv().ForceHit.CurrentStrafeCF = root.CFrame
    getgenv().ForceHit.StrafeVisConnection = RunService.RenderStepped:Connect(function()
        local baseCF = getgenv().ForceHit.CurrentStrafeCF
        if not baseCF then return end
        for _, data in pairs(parts) do
            local targetCF = baseCF * data.offset
            data.currentCF = data.currentCF:Lerp(targetCF, alpha)
            data.part.CFrame = data.currentCF
        end
    end)
end

local function stopStrafe()
    if getgenv().ForceHit.StrafeConnection then
        getgenv().ForceHit.StrafeConnection:Disconnect()
        getgenv().ForceHit.StrafeConnection = nil
    end
    destroyStrafeVisualizer()
    resetStrafeCamera()
    getgenv().ForceHit.LookAtTarget = true
end

local function startStrafe()
    if getgenv().ForceHit.StrafeConnection then
        getgenv().ForceHit.StrafeConnection:Disconnect()
        getgenv().ForceHit.StrafeConnection = nil
    end
    if getgenv().ForceHit.VisualizeStrafe then createStrafeVisualizer() end

    getgenv().ForceHit.LookAtTarget = false

    local strafeTime = 0
    local voidPhase = false
    local voidTimer = 0

    getgenv().ForceHit.StrafeConnection = RunService.Heartbeat:Connect(function(dt)
        strafeTime += dt

        if not getgenv().ForceHit.StrafeEnabled or not getgenv().ForceHitTarget then
            stopStrafe()
            return
        end

        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local targetChar = getgenv().ForceHitTarget.Character
        local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
        local targetHum = targetChar and targetChar:FindFirstChildWhichIsA("Humanoid")

        if not (root and targetRoot and targetHum and targetHum.Health > 0) then
            stopStrafe()
            return
        end

        local targetPos = targetRoot.Position
        local desired

        if getgenv().ForceHit.StrafeMode == "Orbit" then
            local angle = strafeTime * (getgenv().ForceHit.StrafeSpeed or 5)
            desired = CFrame.lookAt(
                targetPos + Vector3.new(
                    math.cos(angle) * (getgenv().ForceHit.StrafeDistance or 8),
                    getgenv().ForceHit.StrafeHeight or 0,
                    math.sin(angle) * (getgenv().ForceHit.StrafeDistance or 8)
                ),
                targetPos
            )

        elseif getgenv().ForceHit.StrafeMode == "Random" then
            local t = strafeTime * 40
            local offset = Vector3.new(
                math.noise(t,0,0) * 20,
                math.noise(0,t,0) * 15 + (getgenv().ForceHit.StrafeHeight or 0),
                math.noise(0,0,t) * 20
            )
            desired = CFrame.lookAt(targetPos + offset, targetPos)

        elseif getgenv().ForceHit.StrafeMode == "Void Shoot" then
            voidTimer += dt
            local isShooting = tick() - (getgenv().ForceHit.LastShotTime or 0) < 0.12

            if isShooting then
                voidPhase = false
                voidTimer = 0
                desired = CFrame.lookAt(
                    targetPos + Vector3.new(0, 200, 2),
                    targetPos
                )
            else
                local voidTime = getgenv().ForceHit.VoidTime or 0.4
                local groundTime = getgenv().ForceHit.GroundTime or 0.133

                if not voidPhase then
                    if voidTimer >= groundTime then
                        voidPhase = true
                        voidTimer = 0
                    end
                    desired = CFrame.lookAt(
                        targetPos + Vector3.new(0, 3, 2),
                        targetPos
                    )
                else
                    if voidTimer >= voidTime then
                        voidPhase = false
                        voidTimer = 0
                    end
                    desired = CFrame.new(
                        targetPos + Vector3.new(0, 10000, 0)
                    )
                end
            end
        end

        if not desired then return end

        if getgenv().ForceHit.VisualizeStrafe then
            getgenv().ForceHit.CurrentStrafeCF = desired
        end

        if getgenv().ForceHit.strafespoof then
            local real = root.CFrame
            DesyncPart.CFrame = real + Vector3.new(0, 5, 0)
            strafeCamera.CameraSubject = DesyncPart
            root.CFrame = desired
            RunService.RenderStepped:Wait()
            root.CFrame = real
            resetStrafeCamera()
        else
            root.CFrame = desired
            local targetSubject = targetChar:FindFirstChild("Head") or targetHum
            local selfSubject = char:FindFirstChildWhichIsA("Humanoid")
            strafeCamera.CameraSubject = getgenv().ForceHit.SpectateStrafe and targetSubject or selfSubject
        end
    end)
end

task.spawn(function()
    while task.wait(0.1) do
        if getgenv().ForceHit.StrafeEnabled and getgenv().ForceHitTarget then
            if not getgenv().ForceHit.StrafeConnection then
                startStrafe()
            end
        else
            if getgenv().ForceHit.StrafeConnection then
                stopStrafe()
            end
        end
    end
end)

task.spawn(function()
    while task.wait() do
        if not (getgenv().stompTargetEnabled and getgenv().ForceHitTarget and getgenv().ForceHitTarget ~= LocalPlayer) then continue end
        local targetChar = getgenv().ForceHitTarget.Character
        local body = targetChar and targetChar:FindFirstChild("BodyEffects")
        local ko = body and body:FindFirstChild("K.O") and body["K.O"].Value
        local sdeath = body and body:FindFirstChild("SDeath") and body["SDeath"].Value
        if ko and not sdeath then
            local torso = targetChar:FindFirstChild("UpperTorso")
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if torso and hrp then
                local real = hrp.CFrame

                local wasStrafing = getgenv().ForceHit.strafespoof
                local wasStrafeEnabled = getgenv().ForceHit.StrafeEnabled

                getgenv().ForceHit.strafespoof = false
                getgenv().ForceHit.StrafeEnabled = false
                stopStrafe()

                if wasStrafing then
                    DesyncPart.CFrame = real + Vector3.new(0,5,0)
                    strafeCamera.CameraSubject = DesyncPart
                end

                hrp.CFrame = CFrame.new(torso.Position + Vector3.new(0,3,0))
                ReplicatedStorage.MainEvent:FireServer("Stomp")
                RunService.RenderStepped:Wait()
                hrp.CFrame = real

                getgenv().ForceHit.strafespoof = wasStrafing
                getgenv().ForceHit.StrafeEnabled = wasStrafeEnabled
                resetStrafeCamera()
            end
        end
    end
end)
getgenv().RunService.Heartbeat:Connect(function()
    if not getgenv().ForceHit.LookAtTarget then return end
    local target = getgenv().ForceHitTarget
    if not target or not target.Character then return end
    local targetPart = target.Character:FindFirstChild(getgenv().ForceHit.HitPart)
        or target.Character:FindFirstChild("HumanoidRootPart")
    if not targetPart then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then
        local lookDir = (targetPart.Position - hrp.Position)
        local flatDir = Vector3.new(lookDir.X, 0, lookDir.Z).Unit
        if flatDir.Magnitude > 0 then
            hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + flatDir)
        end
    end
    local head = char:FindFirstChild("Head")
    local neck = (char:FindFirstChild("UpperTorso") and char.UpperTorso:FindFirstChild("Neck"))
        or (char:FindFirstChild("Torso") and char.Torso:FindFirstChild("Neck"))
    if head and neck then
        local dir = (targetPart.Position - head.Position).Unit
        neck.C0 = CFrame.new(neck.C0.Position)
            * CFrame.Angles(math.asin(math.clamp(dir.Y, -1, 1)) * -1, math.atan2(-dir.X, -dir.Z), 0)
    end
end)

local spectateConnection

local function startSpectate()
    if spectateConnection then spectateConnection:Disconnect() ; spectateConnection = nil end
    spectateConnection = getgenv().RunService.Heartbeat:Connect(function()
        if not getgenv().ForceHit.SpectateTarget then
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildWhichIsA("Humanoid")
            if hum then strafeCamera.CameraSubject = hum end
            spectateConnection:Disconnect()
            spectateConnection = nil
            return
        end
        local target = getgenv().ForceHitTarget
        if not target or not target.Character then return end
        local targetHum = target.Character:FindFirstChildWhichIsA("Humanoid")
        if targetHum and strafeCamera.CameraSubject ~= targetHum then
            strafeCamera.CameraType = Enum.CameraType.Custom
            strafeCamera.CameraSubject = targetHum
        end
    end)
end

LocalPlayer.CharacterAdded:Connect(function()
    if getgenv().ForceHit.SpectateTarget then
        task.wait(0.5)
        startSpectate()
    end
end)
getgenv().autoGrabEnabled = false
getgenv().autoGrabCooldown = 1

KillAura:AddToggle("AutoGrabToggle", {Text="Auto Grab", Default=false, Callback=function(v)
    getgenv().autoGrabEnabled = v
end})

KillAura:AddSlider("AutoGrabCooldownSlider", {Text="Grab Cooldown", Min=0.1, Max=5, Default=1, Rounding=1, Callback=function(v)
    getgenv().autoGrabCooldown = v
end})

task.spawn(function()
    while task.wait(getgenv().autoGrabCooldown) do
        if not (getgenv().autoGrabEnabled and getgenv().ForceHitTarget and getgenv().ForceHitTarget ~= LocalPlayer) then continue end
        local targetChar = getgenv().ForceHitTarget.Character
        local body = targetChar and targetChar:FindFirstChild("BodyEffects")
        local ko = body and body:FindFirstChild("K.O") and body["K.O"].Value
        if not ko then continue end
        local targetHrp = targetChar:FindFirstChild("HumanoidRootPart")
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not targetHrp or not hrp then continue end

        local real = hrp.CFrame
        local wasStrafing = getgenv().ForceHit.strafespoof
        local wasStrafeEnabled = getgenv().ForceHit.StrafeEnabled

        getgenv().ForceHit.strafespoof = false
        getgenv().ForceHit.StrafeEnabled = false
        stopStrafe()

        if wasStrafing then
            DesyncPart.CFrame = real + Vector3.new(0,5,0)
            strafeCamera.CameraSubject = DesyncPart
        end

        hrp.CFrame = CFrame.new(targetHrp.Position + Vector3.new(0,3,0))
        ReplicatedStorage.MainEvent:FireServer("Grabbing")
        RunService.RenderStepped:Wait()
        hrp.CFrame = real

        getgenv().ForceHit.strafespoof = wasStrafing
        getgenv().ForceHit.StrafeEnabled = wasStrafeEnabled
        resetStrafeCamera()

        local grabbed = body:FindFirstChild("Grabbed")
        if grabbed then
            local timeout = tick()
            while tick() - timeout < 2 do
                if grabbed.Value == LocalPlayer.Name then
                    targetHrp.CFrame = real
                    break
                end
                task.wait()
            end
        end
    end
end)

    local TextChatService = game:GetService("TextChatService")
    local chatConfig = TextChatService.ChatWindowConfiguration
    local originalBG = chatConfig.BackgroundColor3
    local originalTransparency = chatConfig.BackgroundTransparency
    local originalTextColor = chatConfig.TextColor3
    local originalTextSize = chatConfig.TextSize
    local originalAlignment = chatConfig.VerticalAlignment

    AutoBox:AddToggle('ChatSpyEnabled', {
        Text = 'chatspy',
        Default = false,
        Callback = function(v)
            if v then
                chatConfig.Enabled = true
                chatConfig.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                chatConfig.BackgroundTransparency = 0.8
                chatConfig.TextColor3 = Color3.fromRGB(255, 255, 255)
                chatConfig.TextSize = 13
                chatConfig.VerticalAlignment = Enum.VerticalAlignment.Top
            else
                chatConfig.BackgroundColor3 = originalBG
                chatConfig.BackgroundTransparency = originalTransparency
                chatConfig.TextColor3 = originalTextColor
                chatConfig.TextSize = originalTextSize
                chatConfig.VerticalAlignment = originalAlignment
            end
        end
    })

    AutoBox:AddToggle('AntiVoidEnabled', {
        Text = 'Anti Void',
        Default = false,
        Callback = function(v)
            if v then
                workspace.FallenPartsDestroyHeight = -math.huge
            else
                workspace.FallenPartsDestroyHeight = -50
            end
        end
    })

    AutoBox:AddToggle('Flashback', {
        Text = 'respawn where you died',
        Default = false,
        Callback = function(value)
            if getgenv().flashback and getgenv().flashback.settings then
                getgenv().flashback.settings.enabled = value
            end
        end,
    })

    AutoBox:AddToggle('StompToggle', {
        Text = 'auto stomp',
        Default = false,
        Callback = function(v)
            if v then
                getgenv().StompLoop = task.spawn(function()
                    while task.wait(0.1) do
                        if not Toggles.StompToggle.Value then break end
                        getgenv().MainEvent:FireServer("Stomp")
                    end
                end)
            else
                if getgenv().StompLoop then
                    task.cancel(getgenv().StompLoop)
                    getgenv().StompLoop = nil
                end
            end
        end
    })

    AutoBox:AddToggle('AutoRejoinToggle', {
        Text = 'auto rejoin when kicked',
        Default = false,
        Callback = function(v)
            if v then
                getgenv().AutoRejoinConnection = getgenv().GuiService.ErrorMessageChanged:Connect(function()
                    getgenv().TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, getgenv().LocalPlayer)
                end)
            else
                if getgenv().AutoRejoinConnection then
                    getgenv().AutoRejoinConnection:Disconnect()
                    getgenv().AutoRejoinConnection = nil
                end
            end
        end
    })

    local FOOD_TOOL_NAMES = {
        "[Pizza]", "[Chicken]", "[Taco]", "[Popcorn]",
        "[Hamburger]", "[HotDog]", "[Lettuce]",
    }

    local function isFoodTool(tool)
        if not tool or not tool:IsA("Tool") then return false end
        for _, foodName in ipairs(FOOD_TOOL_NAMES) do
            if tool.Name == foodName then
                return true
            end
        end
        local lowered = string.lower(tool.Name)
        return lowered:find("pizza", 1, true)
            or lowered:find("chicken", 1, true)
            or lowered:find("taco", 1, true)
            or lowered:find("burger", 1, true)
            or lowered:find("hotdog", 1, true)
            or lowered:find("lettuce", 1, true)
            or lowered:find("popcorn", 1, true)
    end

    local function findFoodTool()
        local character = getgenv().LocalPlayer.Character
        if character then
            for _, child in ipairs(character:GetChildren()) do
                if isFoodTool(child) then
                    return child
                end
            end
        end
        local backpack = getgenv().LocalPlayer:FindFirstChildOfClass("Backpack")
        if backpack then
            for _, child in ipairs(backpack:GetChildren()) do
                if isFoodTool(child) then
                    return child
                end
            end
        end
        return nil
    end

    AutoBox:AddToggle('AutoFoodToggle', {
        Text = 'Auto Food',
        Default = false,
        Callback = function(v)
            if v then
                getgenv().AutoFoodLoop = task.spawn(function()
                    while task.wait(0.25) do
                        if not (Toggles.AutoFoodToggle and Toggles.AutoFoodToggle.Value) then break end

                        local character = getgenv().LocalPlayer.Character
                        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                        if not humanoid or humanoid.Health <= 0 then
                            continue
                        end

                        local threshold = math.max((humanoid.MaxHealth > 0 and humanoid.MaxHealth or 100) * 0.65, 45)
                        if humanoid.Health > threshold then
                            continue
                        end

                        local foodTool = findFoodTool()
                        if not foodTool then
                            continue
                        end

                        if foodTool.Parent ~= character then
                            humanoid:EquipTool(foodTool)
                            task.wait(0.12)
                        end

                        pcall(function() foodTool:Activate() end)
                    end
                end)
            else
                if getgenv().AutoFoodLoop then
                    task.cancel(getgenv().AutoFoodLoop)
                    getgenv().AutoFoodLoop = nil
                end
            end
        end
    })

    AutoBox:AddToggle('AntiStaffEnabled', {
        Text = 'Anti Staff',
        Default = getgenv().AntiStaffSettings.Enabled,
        Callback = function(value)
            getgenv().AntiStaffSettings.Enabled = value
        end,
    })

    AutoBox:AddDropdown('AntiStaffAction', {
        Text = 'Action',
        Default = getgenv().AntiStaffSettings.Action,
        Values = { 'Notify', 'Kick', 'Both' },
        Callback = function(value)
            getgenv().AntiStaffSettings.Action = value
        end,
    })

    MoveBox:AddToggle('FlightToggle', {
        Text = 'Flight', Default = false,
        Callback = function(v)
            getgenv().FlightEnabled = v
            if not v then getgenv().StopFly() end
        end
    }):AddKeyPicker('FlightKeybind', {
        Default = 'X', Mode = 'Toggle', Text = 'Flight',
        SyncToggleState = false,
        Callback = function(state)
            if not Toggles.FlightToggle.Value then return end
            if state then getgenv().StartFly() else getgenv().StopFly() end
        end
    })
    MoveBox:AddSlider('FlySpeed', {Text='Fly Speed', Default=50, Min=10, Max=500, Rounding=0, Callback=function(v) getgenv().Misc.FlySpeed=v end})

    MoveBox:AddToggle('CFrameSpeedToggle', {
        Text = 'CFrame Speed', Default = false,
        Callback = function(state)
            getgenv().cframeSpeedEnabled = false
        end,
    }):AddKeyPicker('CFrameSpeedKeybind', {
        Default = 'T', Text = 'CFrame Speed', Mode = 'Toggle',
        SyncToggleState = false,
        Callback = function(state)
            if not Toggles.CFrameSpeedToggle.Value then return end
            getgenv().cframeSpeedEnabled = state
        end,
    })
    MoveBox:AddToggle('WalkSpeedToggle', {
        Text = 'WalkSpeed', Default = false,
        Callback = function(state) getgenv().walkSpeedEnabled = false end,
    }):AddKeyPicker('WalkSpeedKeybind', {
        Default = 'T', Text = 'WalkSpeed', Mode = 'Toggle',
        SyncToggleState = false,
        Callback = function(state)
            if not Toggles.WalkSpeedToggle.Value then return end
            getgenv().walkSpeedEnabled = state
        end,
    })
    MoveBox:AddToggle('JumpPowerToggle', {
        Text = 'JumpPower', Default = false,
        Callback = function(state) getgenv().jumpPowerEnabled = false end,
    }):AddKeyPicker('JumpPowerKeybind', {
        Default = 'None', Text = 'JumpPower', Mode = 'Toggle',
        SyncToggleState = false,
        Callback = function(state)
            if not Toggles.JumpPowerToggle.Value then return end
            getgenv().jumpPowerEnabled = state
        end,
    })

    MoveBox:AddSlider('WalkSpeedSlider', {
        Text = 'WalkSpeed Value', Default = 16, Min = 16, Max = 500, Rounding = 0,
        Callback = function(v) getgenv().walkSpeed = v end,
    })
    MoveBox:AddSlider('JumpPowerSlider', {
        Text = 'JumpPower Value', Default = 50, Min = 50, Max = 500, Rounding = 0,
        Callback = function(v) getgenv().jumpPower = v end,
    })
    MoveBox:AddSlider('CFrameSpeedSlider', {
        Text = 'CFrame Speed Value', Default = 10, Min = 0, Max = 200, Rounding = 1,
        Callback = function(v) getgenv().cframeSpeed = v end,
    })

    MoveBox:AddToggle('SpinbotToggle', {
        Text = 'Spinbot', Default = false,
        Callback = function(v) getgenv().Misc.SpinEnabled = v ; if v then getgenv().StartSpin() end end
    })
    MoveBox:AddSlider('SpinSpeed', {Text='Spin Speed', Default=20, Min=1, Max=100, Rounding=1, Callback=function(v) getgenv().Misc.SpinSpeed=v end})

    MoveBox:AddSlider('GravitySlider', {
        Text = 'Gravity', Default = 196.2, Min = 0, Max = 500, Rounding = 1,
        Callback = function(v)
            getgenv().customGravity = v
        end
    })

    MoveBox:AddToggle('NoClipToggle', {
        Text = 'NoClip', Default = false,
        Callback = function(v) getgenv().NoClipEnabled = false end
    }):AddKeyPicker('NoClipKey', {
        Default = 'None', Mode = 'Toggle', Text = 'NoClip Key',
        SyncToggleState = false,
        Callback = function(state)
            if not Toggles.NoClipToggle.Value then return end
            getgenv().NoClipEnabled = state
        end
    })
end

applyAutoBox()

-- the Da Hood skin changer is part of the Skins tab, next to the Rivals cosmetic changer
local SkinChangerGb = getgenv().Tabs.Skins:AddLeftGroupbox('Skin Changer')

local MiscLeft = TabCharacter

getgenv().MainGb:AddToggle('ForceHitEnabled', {
    Text = 'Forcehit',
    Default = false
}):AddKeyPicker('ForceHitKey', {
    Default = 'C',
    Mode = 'Toggle',
    Text = 'Forcehit',
    SyncToggleState = false,
    NoUI = false
})

getgenv().MainGb:AddDropdown('TargetPlayer', { SpecialType = 'Player', Text = 'Target Players', Tooltip = 'Lock a specific player' })
getgenv().MainGb:AddDropdown('HitPart', { Text = 'body part', Default = 1, Values = { 'Head', 'UpperTorso', 'HumanoidRootPart', 'LowerTorso' } })
getgenv().MainGb:AddToggle('AutoClosest', { Text = 'Auto Closest Target', Default = false })
getgenv().MainGb:AddToggle('ShowTracer', {
    Text = 'Tracer',
    Default = false
}):AddColorPicker('TracerColor', {
    Default = ACCENT,
    Title = 'Line Color'
})

do
    local VirtualInputManager = game:GetService("VirtualInputManager")
    local RELOAD_TOOLS = {
        "[Revolver]", "[DoubleBarrel]", "[TacticalShotgun]",
        "[SMG]", "[Shotgun]", "[Silencer]",
    }
    local lastReload = {}

    getgenv().AutoReloadConnection = getgenv().RunService.RenderStepped:Connect(function()
        if not (Toggles.AutoReloadEnabled and Toggles.AutoReloadEnabled.Value) then return end
        local char = getgenv().LocalPlayer.Character
        if not char then return end
        local cd = (Options.AutoReloadCooldown and Options.AutoReloadCooldown.Value) or 1
        for _, name in ipairs(RELOAD_TOOLS) do
            local t = char:FindFirstChild(name)
            if t and (not lastReload[name] or tick() - lastReload[name] >= cd) then
                local s = t:FindFirstChild("Script")
                local a = s and s:FindFirstChild("Ammo")
                if a and a:IsA("IntValue") and a.Value == 0 then
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.R, false, nil)
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.R, false, nil)
                    lastReload[name] = tick()
                end
            end
        end
    end)
end

getgenv().ChecksGb:AddToggle('WallCheck', { Text = 'Wall Check', Default = true })
getgenv().ChecksGb:AddToggle('ForceFieldCheck', { Text = 'ForceField Check', Default = true })
getgenv().ChecksGb:AddToggle('KOCheck', { Text = 'Death / KO Check', Default = true })
getgenv().ChecksGb:AddToggle('EnablePrefire', { Text = 'Prefire ForceField', Default = false })
getgenv().ChecksGb:AddToggle('AutoCalcPrefire', { Text = 'Auto Calculate Prefire', Default = false })
getgenv().ChecksGb:AddSlider('PrefireTime', { Text = 'Prefire Time (s)', Default = 0.1, Min = 0.0, Max = 1.0, Rounding = 2 })
getgenv().ChecksGb:AddSlider('MaxDistance', { Text = 'Max Distance', Default = 250, Min = 10, Max = 1000, Rounding = 0 })

getgenv().MenuBox = getgenv().Tabs.Settings:AddLeftGroupbox('Utilities')
getgenv().MenuBox:AddButton('Unload UI', function() getgenv().Library:Unload() end)
getgenv().MenuBox:AddButton('join new server', function() getgenv().TeleportService:Teleport(game.PlaceId, getgenv().LocalPlayer) end)
getgenv().MenuBox:AddButton('Rejoin Server', function() getgenv().TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, getgenv().LocalPlayer) end)
getgenv().MenuBox:AddLabel('Menu bind'):AddKeyPicker('MenuKeybind', {Default='End', NoUI=true, Text='Menu keybind'})

Options.ForceHitKey:OnClick(function()
    if not Toggles.ForceHitEnabled.Value then return end

    if getgenv().ForceHitTarget then
        getgenv().ForceHitTarget = nil
        getgenv().ForceHitTarget2 = nil
        getgenv().SetupDamageDetection(nil)
        getgenv().TracerLine.Visible = false; getgenv().TracerOutline.Visible = false
        getgenv().TracerLine2.Visible = false; getgenv().TracerOutline2.Visible = false
        if getgenv().Library.Notify then getgenv().Library:Notify("Target Unlocked", 1.5) end
    else
        getgenv().ForceHitTarget = getgenv().GetClosestToMouse()
        if getgenv().ForceHitTarget then
            getgenv().SetupDamageDetection(getgenv().ForceHitTarget)
            if getgenv().Library.Notify then getgenv().Library:Notify("Target Locked: " .. tostring(getgenv().ForceHitTarget.Name), 1.5) end
        end
    end
end)

if Options.TargetPlayer then
    Options.TargetPlayer:OnChanged(function()
        local name = Options.TargetPlayer.Value
        local plr = name and name ~= '' and getgenv().Players:FindFirstChild(name)
        if plr and plr ~= getgenv().LocalPlayer then
            getgenv().ForceHitTarget = plr
            getgenv().SetupDamageDetection(plr)
            if getgenv().Library.Notify then getgenv().Library:Notify("Target Locked: " .. plr.Name, 1.5) end
        end
    end)
end

-- ============================================================
-- lunar.lua | Mobile support
-- Touch devices have no keyboard, so keybinds (Forcehit = C, etc.)
-- are unreachable. This adds a draggable on-screen panel for the
-- most-used actions and keeps a target locked while Forcehit is on.
-- ============================================================
if getgenv().IsMobile then
    local UIS = getgenv().UserInputService
    local plr = getgenv().LocalPlayer
    local guiParent = (gethui and gethui()) or plr:FindFirstChildOfClass("PlayerGui") or game:GetService("CoreGui")

    local gui = Instance.new("ScreenGui")
    gui.Name = "lunar_mobile"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 2147483647
    gui.IgnoreGuiInset = true
    gui.Parent = guiParent
    getgenv().MobileGui = gui

    local panel = Instance.new("Frame")
    panel.Name = "Panel"
    panel.AnchorPoint = Vector2.new(1, 0.5)
    panel.Position = UDim2.new(1, -14, 0.5, 0)
    panel.Size = UDim2.new(0, 138, 0, 190)
    panel.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    panel.BackgroundTransparency = 0.1
    panel.Active = true
    panel.Parent = gui
    Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 12)
    local panelStroke = Instance.new("UIStroke", panel)
    panelStroke.Color = Color3.fromRGB(96, 78, 178)

    local header = Instance.new("TextLabel")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 30)
    header.BackgroundTransparency = 1
    header.Text = "lunar.lua"
    header.TextColor3 = Color3.fromRGB(192, 182, 244)
    header.TextSize = 15
    header.Font = Enum.Font.GothamBold
    header.Parent = panel

    local function addMobileButton(text, order, callback)
        local btn = Instance.new("TextButton")
        btn.Name = text
        btn.Size = UDim2.new(1, -16, 0, 42)
        btn.Position = UDim2.new(0, 8, 0, 34 + (order - 1) * 48)
        btn.BackgroundColor3 = Color3.fromRGB(40, 36, 55)
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(236, 233, 246)
        btn.TextSize = 17
        btn.Font = Enum.Font.GothamMedium
        btn.AutoButtonColor = true
        btn.Parent = panel
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
        btn.MouseButton1Click:Connect(function()
            local ok, err = pcall(callback)
            if not ok then warn("[lunar.lua] mobile action failed: " .. tostring(err)) end
        end)
        return btn
    end

    addMobileButton("Forcehit", 1, function()
        if not Toggles.ForceHitEnabled then return end
        local enabled = not Toggles.ForceHitEnabled.Value
        Toggles.ForceHitEnabled:SetValue(enabled)
        if not enabled then
            getgenv().ForceHitTarget = nil
            getgenv().ForceHitTarget2 = nil
            getgenv().SetupDamageDetection(nil)
            if getgenv().TracerLine then getgenv().TracerLine.Visible = false end
            if getgenv().TracerOutline then getgenv().TracerOutline.Visible = false end
            if getgenv().TracerLine2 then getgenv().TracerLine2.Visible = false end
            if getgenv().TracerOutline2 then getgenv().TracerOutline2.Visible = false end
        elseif getgenv().Library.Notify then
            getgenv().Library:Notify("Forcehit enabled", 1.5)
        end
    end)

    addMobileButton("Fly", 2, function()
        if Toggles.FlightToggle then Toggles.FlightToggle:SetValue(not Toggles.FlightToggle.Value) end
    end)

    addMobileButton("Noclip", 3, function()
        if Toggles.NoClipToggle then Toggles.NoClipToggle:SetValue(not Toggles.NoClipToggle.Value) end
    end)

    -- Drag the panel by its header.
    local dragging, dragStart, startPos
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging, dragStart, startPos = true, input.Position, panel.Position
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            panel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    -- No cursor to lock onto: keep the closest on-screen target locked while Forcehit is on.
    getgenv().MobileAutoTargetConn = getgenv().RunService.RenderStepped:Connect(function()
        local autoTarget = Toggles.MobileAutoTarget
        local autoTargetOn = (autoTarget == nil) and (getgenv().IsMobile == true) or (autoTarget and autoTarget.Value)
        if not autoTargetOn then return end
        if not (Toggles.ForceHitEnabled and Toggles.ForceHitEnabled.Value) then return end
        local closest = getgenv().GetClosestToMouse()
        if closest and closest ~= getgenv().ForceHitTarget then
            getgenv().ForceHitTarget = closest
            getgenv().SetupDamageDetection(closest)
        end
    end)
end

getgenv().LocalPlayer.CharacterAdded:Connect(function()
    if (Toggles.SpectateTarget and Toggles.SpectateTarget.Value) then task.wait(0.5); getgenv().startSpectate() end
end)

getgenv().RunService.RenderStepped:Connect(function()
    if Toggles.ForceHitEnabled.Value then
        if Toggles.AutoClosest and Toggles.AutoClosest.Value then
            local closest = getgenv().GetClosestToMouse()
            if closest ~= getgenv().ForceHitTarget then
                getgenv().ForceHitTarget = closest
                getgenv().SetupDamageDetection(closest)
            end
        end
        local targets = {getgenv().ForceHitTarget, getgenv().ForceHitTarget2}
        
        for i, target in ipairs(targets) do
            local line = i == 1 and getgenv().TracerLine or getgenv().TracerLine2
            local outline = i == 1 and getgenv().TracerOutline or getgenv().TracerOutline2
            
            if target then
                local isTargetFullyDead = getgenv().isFullyDead(target)
                local isTargetKO = getgenv().isKO(target)
                
                local canShoot = not (Toggles.KOCheck.Value and (isTargetFullyDead or (isTargetKO and not Toggles.StompTarget.Value)))
                
                if canShoot then
                    getgenv().Shoot(target)

                    if Toggles.ShowTracer.Value then
                        local targetPart = target.Character and target.Character:FindFirstChild(Options.HitPart.Value)
                        if targetPart then
                            local screenPos, onScreen = getgenv().Camera:WorldToViewportPoint(targetPart.Position)
                            if onScreen then
                                local viewport = getgenv().Camera.ViewportSize
                                local originMode = Options.TracerOrigin and Options.TracerOrigin.Value or 'Mouse'
                                local startPos
                                if originMode == 'Mouse' then startPos = getgenv().UserInputService:GetMouseLocation()
                                elseif originMode == 'Center' then startPos = Vector2.new(viewport.X / 2, viewport.Y / 2)
                                elseif originMode == 'Bottom' then startPos = Vector2.new(viewport.X / 2, viewport.Y) end

                                local endPos = Vector2.new(screenPos.X, screenPos.Y)
                                outline.From = startPos; outline.To = endPos; outline.Visible = true
                                line.From = startPos; line.To = endPos; line.Color = Options.TracerColor.Value; line.Visible = true
                            else
                                line.Visible = false; outline.Visible = false
                            end
                        else line.Visible = false; outline.Visible = false end
                    else line.Visible = false; outline.Visible = false end
                else
                    line.Visible = false; outline.Visible = false
                end
            else
                line.Visible = false; outline.Visible = false
            end
        end
    else 
        getgenv().TracerLine.Visible = false; getgenv().TracerOutline.Visible = false
        getgenv().TracerLine2.Visible = false; getgenv().TracerOutline2.Visible = false
    end
end)

task.spawn(function()
    while task.wait() do
        if not (Toggles.StompTarget.Value and getgenv().ForceHitTarget and getgenv().ForceHitTarget ~= getgenv().LocalPlayer) then continue end
        local targetChar = getgenv().ForceHitTarget.Character
        if not targetChar then continue end
        
        local body = targetChar:FindFirstChild("BodyEffects")
        local ko = body and body:FindFirstChild("K.O") and body["K.O"].Value
        local sdeath = body and body:FindFirstChild("SDeath") and body["SDeath"].Value
        
        if ko and not sdeath then
            getgenv().isCurrentlyStomping = true
            
            local torso = targetChar:FindFirstChild("UpperTorso") or targetChar:FindFirstChild("Torso")
            local hrp = getgenv().LocalPlayer.Character and getgenv().LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if torso and hrp then
                local real = hrp.CFrame
                local wasStrafing = Toggles.spoofstrafe and Toggles.spoofstrafe.Value
                
                if getgenv().StrafeConnection then getgenv().stopStrafe() end

                if wasStrafing then
                    getgenv().DesyncPart.CFrame = real + Vector3.new(0, 5, 0)
                    if not (Toggles.SpectateTarget and Toggles.SpectateTarget.Value) then getgenv().Camera.CameraSubject = getgenv().DesyncPart end
                end

                while getgenv().ForceHitTarget and getgenv().ForceHitTarget.Character == targetChar and targetChar.Parent do
                    local curBody = targetChar:FindFirstChild("BodyEffects")
                    if not curBody then break end
                    local curKO = curBody:FindFirstChild("K.O") and curBody["K.O"].Value
                    local curSDeath = curBody:FindFirstChild("SDeath") and curBody["SDeath"].Value
                    
                    if not curKO or curSDeath then break end
                    
                    local curTorso = targetChar:FindFirstChild("UpperTorso") or targetChar:FindFirstChild("Torso")
                    if curTorso then hrp.CFrame = CFrame.new(curTorso.Position + Vector3.new(0, 3, 0)) end
                    
                    getgenv().MainEvent:FireServer("Stomp")
                    task.wait(0.1)
                end

                hrp.CFrame = real
                if not (Toggles.SpectateTarget and Toggles.SpectateTarget.Value) then getgenv().resetStrafeCamera() end
            end
            getgenv().isCurrentlyStomping = false
        end
    end
end)

getgenv().RunService.Heartbeat:Connect(function()
    -- writing a physics property every frame is expensive and replicates to the server,
    -- so only write it when the slider actually moved
    local gravity = getgenv().customGravity
    if gravity ~= nil and workspace.Gravity ~= gravity then workspace.Gravity = gravity end
    
    local char = getgenv().LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return end

    if getgenv().jumpPowerEnabled then
        hum.UseJumpPower = true
        hum.JumpPower = getgenv().jumpPower or 50
    end

    if getgenv().walkSpeedEnabled then
        hum.WalkSpeed = getgenv().walkSpeed or 16
    end

    if getgenv().cframeSpeedEnabled then
        local moveDir = hum.MoveDirection
        if moveDir.Magnitude > 0 then
            local speed = getgenv().cframeSpeed or 0
            hrp.CFrame = hrp.CFrame + (moveDir * (speed / 10))
        end
    end

    if getgenv().NoClipEnabled then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end

    if Toggles.LookAtTarget and Toggles.LookAtTarget.Value and not getgenv().isCurrentlyStomping then
        if getgenv().ForceHitTarget and getgenv().ForceHitTarget.Character then
            local targetPart = getgenv().ForceHitTarget.Character:FindFirstChild(Options.HitPart.Value) or getgenv().ForceHitTarget.Character:FindFirstChild("HumanoidRootPart")
            if targetPart then
                local lookDir = (targetPart.Position - hrp.Position)
                local flatDir = Vector3.new(lookDir.X, 0, lookDir.Z).Unit
                if flatDir.Magnitude > 0 and flatDir == flatDir then
                    hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + flatDir)
                end
                
                local head = char:FindFirstChild("Head")
                local neck = (char:FindFirstChild("UpperTorso") and char.UpperTorso:FindFirstChild("Neck")) or (char:FindFirstChild("Torso") and char.Torso:FindFirstChild("Neck"))
                if head and neck then
                    local dir = (targetPart.Position - head.Position).Unit
                    if dir == dir then
                        neck.C0 = CFrame.new(neck.C0.Position) * CFrame.Angles(math.asin(math.clamp(dir.Y, -1, 1)) * -1, math.atan2(-dir.X, -dir.Z), 0)
                    end
                end
            end
        end
    end
end)

getgenv().Misc = getgenv().Misc or {
    AutoReload = true,
    AutoReloadCooldown = 1,
    SpinEnabled = false,
    SpinSpeed = 20,
    SpinConnection = nil,
    FlightEnabled = false,
    Flying = false,
    FlySpeed = 50,
}
getgenv().StartSpin = function()
    if getgenv().Misc.SpinConnection then
        getgenv().Misc.SpinConnection:Disconnect()
        getgenv().Misc.SpinConnection = nil
    end
    getgenv().Misc.SpinConnection = getgenv().RunService.RenderStepped:Connect(function()
        if not getgenv().Misc.SpinEnabled then
            getgenv().Misc.SpinConnection:Disconnect()
            getgenv().Misc.SpinConnection = nil
            return
        end
        local char = getgenv().LocalPlayer.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(getgenv().Misc.SpinSpeed), 0)
    end)
end

getgenv().MorphSettings = getgenv().MorphSettings or {
    CopyAppearance = true,
    HasHeadless = false,
    HasKorblox = false,
    HasChams = false,
    ChamsColor = Color3.new(1, 1, 1),
    SelectedUserName = "None",
    SelectedUserId = nil,
    DanceEnabled = false,
    CurrentDanceName = "None",
    CurrentDanceId = "",
    LagAnimations = false,
    LagIntensity = 1,
}

local settings = getgenv().MorphSettings

local users = {
    {UserId = 4912090997, UserName = "amir"},
    {UserId = 444115704, UserName = "DingleDorf"},
    {UserId = 7535880104, UserName = "fed"},
}

local danceAnimations = {
    ["None"] = "",
    ["headless"] = "rbxassetid://4",
    ["Floss"] = "rbxassetid://10714340543",
    ["Yungblud Happier Jump"] = "rbxassetid://15609995579",
    ["Monkey"] = "rbxassetid://3333499508",
    ["Fancy Feet"] = "rbxassetid://3333432454",
    ["Sleep"] = "rbxassetid://4686925579",
    ["Cower"] = "rbxassetid://4940563117",
    ["Bored"] = "rbxassetid://5230599789"
}

local danceNames = {}
for name in pairs(danceAnimations) do table.insert(danceNames, name) end

local skinColorParts = {
    Head = true,
    LeftFoot = true,
    LeftHand = true,
    LeftLowerArm = true,
    LeftUpperArm = true,
    RightFoot = true,
    RightHand = true,
    RightLowerArm = true,
    RightUpperArm = true,
}

local function validCharacter(c)
    local h = c and c:FindFirstChildOfClass("Humanoid")
    return h and h.Health > 0 and c:FindFirstChild("HumanoidRootPart")
end

local function ApplyHeadless(char)
    local head = char:FindFirstChild("Head")
    if head then
        head.Transparency = 1
        local face = head:FindFirstChild("face")
        if face then face.Transparency = 1 end
    end
end

local function RemoveHeadless(char)
    local head = char:FindFirstChild("Head")
    if head then
        head.Transparency = 0
        local face = head:FindFirstChild("face")
        if face then face.Transparency = 0 end
    end
end

local function ApplyKorblox(char)
    local rLowerLeg = char:FindFirstChild("RightLowerLeg")
    local rUpperLeg = char:FindFirstChild("RightUpperLeg")
    local rFoot = char:FindFirstChild("RightFoot")
    if rLowerLeg then rLowerLeg.MeshId = "902942093" ; rLowerLeg.Transparency = 1 end
    if rUpperLeg then rUpperLeg.MeshId = "http://www.roblox.com/asset/?id=902942096" ; rUpperLeg.TextureID = "http://roblox.com/asset/?id=902843398" end
    if rFoot then rFoot.MeshId = "902942089" ; rFoot.Transparency = 1 end
end

local function RemoveKorblox(char)
    local rLowerLeg = char:FindFirstChild("RightLowerLeg")
    local rUpperLeg = char:FindFirstChild("RightUpperLeg")
    local rFoot = char:FindFirstChild("RightFoot")
    if rLowerLeg then rLowerLeg.Transparency = 0 ; rLowerLeg.MeshId = "" end
    if rFoot then rFoot.Transparency = 0 ; rFoot.MeshId = "" end
    if rUpperLeg then rUpperLeg.TextureID = "" ; rUpperLeg.MeshId = "" end
    local success, appearance = pcall(function()
        return Players:GetCharacterAppearanceAsync(LocalPlayer.UserId)
    end)
    if not success or not appearance then return end
    for _, v in pairs(char:GetChildren()) do
        if v:IsA("Shirt") or v:IsA("Pants") or v:IsA("BodyColors") then v:Destroy() end
    end
    for _, v in pairs(appearance:GetChildren()) do
        if v:IsA("Shirt") or v:IsA("Pants") or v:IsA("BodyColors") then
            v.Parent = char
        end
    end
end

local savedBodyColors = {}

local function ApplyChams(char)
    local color = settings.ChamsColor or Color3.new(1, 1, 1)
    local partNames = {
        "Head", "LeftFoot", "LeftHand", "LeftLowerArm", "LeftLowerLeg",
        "LeftUpperArm", "LeftUpperLeg", "LowerTorso", "RightFoot",
        "RightHand", "RightLowerArm", "RightLowerLeg",
        "RightUpperArm", "RightUpperLeg", "UpperTorso"
    }
    savedBodyColors = {}
    for _, name in ipairs(partNames) do
        local part = char:FindFirstChild(name)
        if part and part:IsA("BasePart") then
            savedBodyColors[name] = part.Color
            part.Material = Enum.Material.ForceField
            part.Color = color
        end
    end
end

local function RemoveChams(char)
    local partNames = {
        "Head", "LeftFoot", "LeftHand", "LeftLowerArm", "LeftLowerLeg",
        "LeftUpperArm", "LeftUpperLeg", "LowerTorso", "RightFoot",
        "RightHand", "RightLowerArm", "RightLowerLeg",
        "RightUpperArm", "RightUpperLeg", "UpperTorso"
    }
    for _, name in ipairs(partNames) do
        local part = char:FindFirstChild(name)
        if part and part:IsA("BasePart") then
            part.Material = Enum.Material.Plastic
            if savedBodyColors[name] then
                part.Color = savedBodyColors[name]
            end
        end
    end
    savedBodyColors = {}
end

local function Morph(UserId, PlayerName)
    local player = Players:FindFirstChild(PlayerName)
    if not player or not player.Character then return end
    local success, appearance = pcall(function() return Players:GetCharacterAppearanceAsync(UserId) end)
    if not success then return end
    local char = player.Character
    for _, v in pairs(char:GetChildren()) do
        if v:IsA("Accessory") or v:IsA("Shirt") or v:IsA("Pants") or v:IsA("CharacterMesh") or v:IsA("BodyColors") then v:Destroy() end
    end
    if char:FindFirstChild("Head") and char.Head:FindFirstChild("face") then char.Head.face:Destroy() end
    for _, v in pairs(appearance:GetChildren()) do
        if v:IsA("Shirt") or v:IsA("Pants") or v:IsA("BodyColors") then v.Parent = char
        elseif v:IsA("Accessory") then char.Humanoid:AddAccessory(v)
        elseif v.Name == "R15" and char.Humanoid.RigType == Enum.HumanoidRigType.R15 then
            local mesh = v:FindFirstChildOfClass("CharacterMesh")
            if mesh then mesh.Parent = char end
        end
    end
    if appearance:FindFirstChild("face") then
        appearance.face.Parent = char.Head
    else
        local face = Instance.new("Decal")
        face.Face = Enum.NormalId.Front
        face.Name = "face"
        face.Texture = "rbxasset://textures/face.png"
        face.Parent = char.Head
    end
    local parent = char.Parent
    char.Parent = nil
    char.Parent = parent
    if settings.HasHeadless then ApplyHeadless(char) end
    if settings.HasKorblox then ApplyKorblox(char) end
    if settings.HasChams then ApplyChams(char) end
end

local danceTrack
local lagConnection

local function loadDance()
    local c = LocalPlayer.Character
    if not validCharacter(c) or settings.CurrentDanceId == "" then return end
    local h = c:FindFirstChildOfClass("Humanoid")
    local animator = h:FindFirstChildOfClass("Animator") or Instance.new("Animator", h)
    if danceTrack then danceTrack:Stop() ; danceTrack:Destroy() end
    local a = Instance.new("Animation")
    a.AnimationId = settings.CurrentDanceId
    danceTrack = animator:LoadAnimation(a)
    danceTrack.Priority = Enum.AnimationPriority.Action
end

local function playDance()
    if settings.DanceEnabled and danceTrack and not danceTrack.IsPlaying then
        pcall(function() danceTrack:Play() end)
    end
end

local function stopLag()
    if lagConnection then lagConnection:Disconnect() ; lagConnection = nil end
    if danceTrack then pcall(function() danceTrack:AdjustSpeed(1) end) end
end

local function startUltraLag()
    stopLag()
    local accumulator = 0
    local updateRate = math.clamp(20 - settings.LagIntensity * 6, 4, 20)
    lagConnection = RunService.RenderStepped:Connect(function(dt)
        if not settings.LagAnimations or not danceTrack or not danceTrack.IsPlaying then stopLag() ; return end
        accumulator += dt
        if accumulator < (1 / updateRate) then return end
        accumulator = 0
        if math.random() < (0.35 * settings.LagIntensity) then return end
        local r = math.random()
        if r < 0.35 * settings.LagIntensity then danceTrack:AdjustSpeed(0)
        elseif r < 0.5 * settings.LagIntensity then danceTrack:AdjustSpeed(-math.random(2,6))
        else danceTrack:AdjustSpeed(math.random(1,8)) end
    end)
end

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(1)
    if settings.SelectedUserId then
        Morph(settings.SelectedUserId, LocalPlayer.Name)
    elseif settings.SelectedUserName and settings.SelectedUserName ~= "None" then
        for _, user in pairs(users) do
            if user.UserName == settings.SelectedUserName then Morph(user.UserId, LocalPlayer.Name) ; break end
        end
    else
        if settings.HasHeadless then ApplyHeadless(char) end
        if settings.HasKorblox then ApplyKorblox(char) end
        if settings.HasChams then ApplyChams(char) end
    end
    if settings.DanceEnabled then
        task.spawn(function()
            task.wait(0.1)
            loadDance()
            playDance()
            if settings.LagAnimations and danceTrack then startUltraLag() end
        end)
    end
end)

if LocalPlayer.Character and validCharacter(LocalPlayer.Character) then
    task.spawn(function()
        task.wait(1)
        loadDance()
        playDance()
        if settings.LagAnimations and danceTrack then startUltraLag() end
    end)
end

-- Everything from here to the end of the file is wrapped in its own function on
-- purpose.  The sections above already hold around a hundred locals in the main
-- chunk, and Luau only allows 200 registers per function, so running this half in
-- the chunk as well pushed it over and produced:
--   Out of local registers when trying to allocate X: exceeded limit 200
-- A function gets a fresh register budget, so the two halves no longer add up.
local function runFeatureSections()
    local Avatar = TabCharacter
    local DickESP = getgenv().DickESPState or {}
    getgenv().DickESPState = DickESP

    local AttachedModels = getgenv().DickESPAttachedModels or {}
    getgenv().DickESPAttachedModels = AttachedModels

    local DickESPConnections = getgenv().DickESPConnections or {}
    getgenv().DickESPConnections = DickESPConnections

    local function attachPartsWithHighlight(character, player)
        if not character then return end
        local pelvis = character:FindFirstChild("LowerTorso") or character:FindFirstChild("Torso")
        if not pelvis then return end

        if getgenv().CleanupAttachedDickESPModel then
            getgenv().CleanupAttachedDickESPModel(player)
        end

        local attachedModel = Instance.new("Model")
        attachedModel.Name = "AttachedParts_" .. player.Name
        attachedModel.Parent = workspace
        attachedModel.PrimaryPart = pelvis
        AttachedModels[player] = attachedModel

        local parts = {}

        local ball1 = Instance.new("Part")
        ball1.Shape = Enum.PartType.Ball
        ball1.Size = Vector3.new(0.5, 0.5, 0.5)
        ball1.Color = Color3.fromRGB(255, 255, 255)
        ball1.Material = Enum.Material.Neon
        ball1.CanCollide = false
        ball1.Anchored = false
        ball1.CFrame = pelvis.CFrame * CFrame.new(0.2, -0.6, -0.7)
        ball1.Parent = attachedModel
        table.insert(parts, ball1)

        local stick = Instance.new("Part")
        stick.Size = Vector3.new(0.3, 0.3, 6.8)
        stick.Color = Color3.fromRGB(255, 255, 255)
        stick.Material = Enum.Material.Neon
        stick.CanCollide = false
        stick.Anchored = false
        stick.CFrame = pelvis.CFrame * CFrame.new(0.07, -0.6, -3.9)
        stick.Parent = attachedModel
        table.insert(parts, stick)

        local ball2 = Instance.new("Part")
        ball2.Shape = Enum.PartType.Ball
        ball2.Size = Vector3.new(0.5, 4.5, 0.5)
        ball2.Color = Color3.fromRGB(255, 255, 255)
        ball2.Material = Enum.Material.Neon
        ball2.CanCollide = false
        ball2.Anchored = false
        ball2.CFrame = pelvis.CFrame * CFrame.new(-0.1, -0.6, -0.7)
        ball2.Parent = attachedModel
        table.insert(parts, ball2)

        for _, part in pairs(parts) do
            local weld = Instance.new("WeldConstraint")
            weld.Part0 = pelvis
            weld.Part1 = part
            weld.Parent = part
        end

        local highlight = Instance.new("Highlight")
        highlight.Parent = attachedModel
        highlight.Adornee = attachedModel
        highlight.FillColor = Color3.fromRGB(0, 0, 0)
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.FillTransparency = 1
        highlight.OutlineTransparency = 0
    end

    getgenv().CleanupAttachedDickESPModel = function(player)
        local model = AttachedModels[player]
        if model then
            model:Destroy()
            AttachedModels[player] = nil
        end
    end

    getgenv().DisconnectDickESPConnection = function(key)
        local conn = DickESPConnections[key]
        if conn then
            conn:Disconnect()
            DickESPConnections[key] = nil
        end
    end

    getgenv().ShouldAttachDickESP = function(player)
        return (player == LocalPlayer and DickESP.SelfEnabled) or (player ~= LocalPlayer and DickESP.OthersEnabled)
    end

    getgenv().WatchDickESPPlayer = function(player)
        getgenv().DisconnectDickESPConnection(player)
        DickESPConnections[player] = player.CharacterAdded:Connect(function(character)
            getgenv().CleanupAttachedDickESPModel(player)
            if getgenv().ShouldAttachDickESP(player) then
                attachPartsWithHighlight(character, player)
            end
        end)

        if player.Character and getgenv().ShouldAttachDickESP(player) then
            attachPartsWithHighlight(player.Character, player)
        end
    end

    getgenv().DickESPCleanup = function()
        for player in pairs(AttachedModels) do
            getgenv().CleanupAttachedDickESPModel(player)
        end
        for key, conn in pairs(DickESPConnections) do
            if typeof(conn) == "RBXScriptConnection" then
                conn:Disconnect()
            end
            DickESPConnections[key] = nil
        end
    end

    for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
        getgenv().WatchDickESPPlayer(player)
    end

    DickESPConnections.__playerAdded = game:GetService("Players").PlayerAdded:Connect(function(player)
        getgenv().WatchDickESPPlayer(player)
    end)

    DickESPConnections.__playerRemoving = game:GetService("Players").PlayerRemoving:Connect(function(player)
        getgenv().CleanupAttachedDickESPModel(player)
        getgenv().DisconnectDickESPConnection(player)
    end)

        getgenv().ESPGb = getgenv().Tabs.Visuals:AddLeftGroupbox('ESP')
        getgenv().ParticleAuraGb = getgenv().Tabs.Visuals:AddRightGroupbox('Particle Aura')
        getgenv().GunMaterialGb = getgenv().Tabs.Visuals:AddRightGroupbox('Gun Material')
        getgenv().WorldGb = getgenv().Tabs.Visuals:AddRightGroupbox('World')

        local RightTabVisual = getgenv().ParticleAuraGb

        local HitEffectsGb = getgenv().HitVisualsGb
        HitEffectsGb:AddToggle('TargetHUDEnabled', {
            Text = 'Target HUD', Default = false
        }):AddColorPicker('TargetHUDColor', { Default = ACCENT, Title = 'Target HUD Color' })
        HitEffectsGb:AddToggle('AmmoHUDEnabled', { Text = 'Ammo HUD', Default = false })
        HitEffectsGb:AddDropdown('AmmoHUDPosition', { Text = 'Ammo HUD Position', Default = 'Normal', Values = { 'Normal', 'Top', 'Left', 'Right' } })

        HitEffectsGb:AddToggle('AutoReloadEnabled', { Text = 'Auto Reload', Default = false })
        HitEffectsGb:AddSlider('AutoReloadCooldown', { Text = 'Reload Cooldown', Default = 1, Min = 0.1, Max = 5, Rounding = 1 })

        HitEffectsGb:AddToggle('BulletTracers', {
            Text = 'Bullets',
            Default = false
        }):AddColorPicker('BulletTracerColorOption', {
            Default = ACCENT,
            Title = 'Tracer Color'
        })
        HitEffectsGb:AddSlider('TracerDuration', { Text = 'Tracer lifetime', Default = 5.5, Min = 0.1, Max = 5.5, Rounding = 1 })
        HitEffectsGb:AddSlider('TracerWidth', { Text = 'Tracer Width', Default = 1, Min = 1, Max = 10, Rounding = 0 })
        HitEffectsGb:AddSlider('DBSpread', { Text = 'Double Barrel Spread', Default = 3.0, Min = 0.0, Max = 15.0, Rounding = 1 })

        HitEffectsGb:AddToggle('HitSoundEnabled', { Text = 'Hit Sound', Default = false })
        HitEffectsGb:AddDropdown('HitSoundChoice', { Text = 'Hit Sound', Default = 1, Values = getgenv().HitSoundList })
        HitEffectsGb:AddInput('CustomHitSound', { Default = '1347140027', Numeric = false, Finished = false, Text = 'Custom ID', Placeholder = 'Sound ID here' })

        HitEffectsGb:AddToggle('HitNotifEnabled', { Text = 'notify on hit', Default = false })
        HitEffectsGb:AddInput('NotifFormat', { Default = 'Hit (player) for (dmg%)', Finished = false, Text = 'Notification Format', Placeholder = 'Hit (player) for (dmg%)' })
        HitEffectsGb:AddLabel('(player) = target name')
        HitEffectsGb:AddLabel('(dmg%) = damage dealt')
        HitEffectsGb:AddDropdown('NotifPos', { Text = 'Notif Position', Default = 'Bottom Center', Values = { 'Top Left', 'Top Right', 'Center', 'Bottom Center' } })

        HitEffectsGb:AddToggle('DamageIndicators', {
            Text = 'Damage Indicators',
            Default = false
        }):AddColorPicker('IndicatorColor', {
            Default = ACCENT,
            Title = 'Text Color'
        }):AddColorPicker('IndicatorStrokeColor', {
            Default = Color3.fromRGB(0, 0, 0),
            Title = 'Outline Color'
        })

        do
            local playerGui = getgenv().LocalPlayer:WaitForChild("PlayerGui")
            local targetHudGui = Instance.new("ScreenGui")
            targetHudGui.Name = "target hud"
            targetHudGui.ResetOnSpawn = false
            targetHudGui.IgnoreGuiInset = true
            targetHudGui.Parent = playerGui
            getgenv().TargetHUDGui = targetHudGui

            local ammoHudGui = Instance.new("ScreenGui")
            ammoHudGui.Name = "AmmoHUD"
            ammoHudGui.ResetOnSpawn = false
            ammoHudGui.IgnoreGuiInset = true
            ammoHudGui.Parent = playerGui
            getgenv().AmmoHUDGui = ammoHudGui

            local tFrame = Instance.new("Frame")
            tFrame.Parent = targetHudGui
            tFrame.Name = "TargetHudFrame"
            tFrame.AnchorPoint = Vector2.new(0.5, 0.75)
            tFrame.Position = UDim2.new(0.5, 0, 0.75, 0)
            tFrame.Size = UDim2.new(0, 322, 0, 147)
            tFrame.BackgroundColor3 = Color3.fromRGB(11, 11, 11)
            tFrame.BorderSizePixel = 0
            tFrame.Visible = false

            local tFrame2 = Instance.new("Frame")
            tFrame2.Parent = tFrame
            tFrame2.Name = "Frame"
            tFrame2.Position = UDim2.new(0, 1, 0, 1)
            tFrame2.Size = UDim2.new(1, -2, 1, -2)
            tFrame2.BackgroundColor3 = Color3.fromRGB(97, 121, 191)
            tFrame2.BorderSizePixel = 0

            local tFrame3 = Instance.new("Frame")
            tFrame3.Parent = tFrame2
            tFrame3.Name = "Frame"
            tFrame3.Position = UDim2.new(0, 1, 0, 1)
            tFrame3.Size = UDim2.new(1, -2, 1, -2)
            tFrame3.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
            tFrame3.BorderSizePixel = 0

            local tFrame4 = Instance.new("Frame")
            tFrame4.Parent = tFrame3
            tFrame4.Name = "Frame"
            tFrame4.Position = UDim2.new(0, 1, 0, 2)
            tFrame4.Size = UDim2.new(1, -2, 1, -4)
            tFrame4.BackgroundTransparency = 1
            tFrame4.BorderSizePixel = 0

            local tPad = Instance.new("UIPadding")
            tPad.Parent = tFrame4
            tPad.PaddingLeft = UDim.new(0, 6)

            local tHolder = Instance.new("Frame")
            tHolder.Parent = tFrame4
            tHolder.Name = "holder"
            tHolder.Position = UDim2.new(0, -3, 0, 16)
            tHolder.Size = UDim2.new(1, 0, 1, -18)
            tHolder.BackgroundColor3 = Color3.fromRGB(46, 46, 46)
            tHolder.BorderSizePixel = 0

            local tTop = Instance.new("Frame")
            tTop.Parent = tFrame4
            tTop.Name = "top"
            tTop.Size = UDim2.new(1, -4, 0, 20)
            tTop.BackgroundTransparency = 1
            tTop.BorderSizePixel = 0

            local indicatorLabel = Instance.new("TextLabel")
            indicatorLabel.Parent = tTop
            indicatorLabel.Name = "TextLabel"
            indicatorLabel.Size = UDim2.new(0.5, 0, 1, 0)
            indicatorLabel.BackgroundTransparency = 1
            indicatorLabel.BorderSizePixel = 0
            indicatorLabel.Text = "Indicator"
            indicatorLabel.TextColor3 = Color3.fromRGB(181, 181, 181)
            indicatorLabel.TextSize = 12
            indicatorLabel.TextXAlignment = Enum.TextXAlignment.Left
            indicatorLabel.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)

            local indicatorPadding = Instance.new("UIPadding")
            indicatorPadding.Parent = indicatorLabel
            indicatorPadding.PaddingLeft = UDim.new(0, -2)
            indicatorPadding.PaddingTop = UDim.new(0, -4)
            indicatorPadding.PaddingBottom = UDim.new(0, 4)

            local indicatorStroke = Instance.new("UIStroke")
            indicatorStroke.Parent = indicatorLabel
            indicatorStroke.Color = Color3.fromRGB(0, 0, 0)
            indicatorStroke.Thickness = 1

            local holderFrame = Instance.new("Frame")
            holderFrame.Parent = tHolder
            holderFrame.Name = "Frame"
            holderFrame.Position = UDim2.new(0, 1, 0, 1)
            holderFrame.Size = UDim2.new(1, -2, 1, -2)
            holderFrame.BackgroundColor3 = Color3.fromRGB(11, 11, 11)
            holderFrame.BorderSizePixel = 0

            local holderFrame2 = Instance.new("Frame")
            holderFrame2.Parent = holderFrame
            holderFrame2.Name = "Frame"
            holderFrame2.Position = UDim2.new(0, 1, 0, 1)
            holderFrame2.Size = UDim2.new(1, -2, 1, -2)
            holderFrame2.BackgroundColor3 = Color3.fromRGB(21, 21, 21)
            holderFrame2.BorderSizePixel = 0

            local holderPadding = Instance.new("UIPadding")
            holderPadding.Parent = holderFrame2
            holderPadding.PaddingLeft = UDim.new(0, 4)
            holderPadding.PaddingTop = UDim.new(0, 4)

            local infoOuter = Instance.new("Frame")
            infoOuter.Parent = holderFrame2
            infoOuter.Name = "Frame"
            infoOuter.Size = UDim2.new(1, -4, 1, -4)
            infoOuter.BackgroundColor3 = Color3.fromRGB(11, 11, 11)
            infoOuter.BorderSizePixel = 0

            local infoOuter2 = Instance.new("Frame")
            infoOuter2.Parent = infoOuter
            infoOuter2.Name = "Frame"
            infoOuter2.Position = UDim2.new(0, 1, 0, 1)
            infoOuter2.Size = UDim2.new(1, -2, 1, -2)
            infoOuter2.BackgroundColor3 = Color3.fromRGB(46, 46, 46)
            infoOuter2.BorderSizePixel = 0

            local infoPanel = Instance.new("Frame")
            infoPanel.Parent = infoOuter2
            infoPanel.Name = "Frame"
            infoPanel.Position = UDim2.new(0, 1, 0, 1)
            infoPanel.Size = UDim2.new(1, -2, 1, -2)
            infoPanel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            infoPanel.BorderSizePixel = 0

            local infoPanelGradient = Instance.new("UIGradient")
            infoPanelGradient.Parent = infoPanel
            infoPanelGradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 30, 30)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(21, 21, 21)),
            })

            local infoPanelPadding = Instance.new("UIPadding")
            infoPanelPadding.Parent = infoPanel
            infoPanelPadding.PaddingLeft = UDim.new(0, 4)
            infoPanelPadding.PaddingTop = UDim.new(0, 4)
            infoPanelPadding.PaddingRight = UDim.new(0, 3)
            infoPanelPadding.PaddingBottom = UDim.new(0, 3)

            local content = Instance.new("Frame")
            content.Parent = infoPanel
            content.Name = "Frame"
            content.Size = UDim2.new(1, 0, 1, 3)
            content.BackgroundTransparency = 1
            content.BorderSizePixel = 0

            local contentList = Instance.new("UIListLayout")
            contentList.Parent = content
            contentList.FillDirection = Enum.FillDirection.Vertical
            contentList.SortOrder = Enum.SortOrder.LayoutOrder
            contentList.Padding = UDim.new(0, 4)
            contentList.HorizontalAlignment = Enum.HorizontalAlignment.Left
            contentList.VerticalAlignment = Enum.VerticalAlignment.Top

            local contentPadding = Instance.new("UIPadding")
            contentPadding.Parent = content
            contentPadding.PaddingBottom = UDim.new(0, 4)

            local cardOuter = Instance.new("Frame")
            cardOuter.Parent = content
            cardOuter.Name = "Frame"
            cardOuter.Size = UDim2.new(1, -1, 1, 0)
            cardOuter.BackgroundColor3 = Color3.fromRGB(46, 46, 46)
            cardOuter.BorderSizePixel = 0

            local cardMid = Instance.new("Frame")
            cardMid.Parent = cardOuter
            cardMid.Name = "Frame"
            cardMid.Position = UDim2.new(0, 1, 0, 1)
            cardMid.Size = UDim2.new(1, -2, 1, -2)
            cardMid.BackgroundColor3 = Color3.fromRGB(11, 11, 11)
            cardMid.BorderSizePixel = 0

            local card = Instance.new("Frame")
            card.Parent = cardMid
            card.Name = "Frame"
            card.Position = UDim2.new(0, 1, 0, 1)
            card.Size = UDim2.new(1, -2, 1, -2)
            card.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            card.BorderSizePixel = 0

            local cardGradient = Instance.new("UIGradient")
            cardGradient.Parent = card
            cardGradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 30, 30)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(21, 21, 21)),
            })

            local cardBar = Instance.new("Frame")
            cardBar.Parent = card
            cardBar.Name = "bar"
            cardBar.Size = UDim2.new(1, 0, 0, 2)
            cardBar.BackgroundColor3 = Color3.fromRGB(97, 121, 191)
            cardBar.BorderSizePixel = 0

            local cardBarGradient = Instance.new("UIGradient")
            cardBarGradient.Parent = cardBar
            cardBarGradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(97, 121, 191)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(76, 94, 149)),
            })

            local cardHolder = Instance.new("Frame")
            cardHolder.Parent = card
            cardHolder.Name = "holder"
            cardHolder.Position = UDim2.new(0, 1, 0, 22)
            cardHolder.Size = UDim2.new(1, -2, 1, -24)
            cardHolder.BackgroundTransparency = 1
            cardHolder.BorderSizePixel = 0

            local cardHolderPadding = Instance.new("UIPadding")
            cardHolderPadding.Parent = cardHolder
            cardHolderPadding.PaddingLeft = UDim.new(0, 3)
            cardHolderPadding.PaddingTop = UDim.new(0, -1)
            cardHolderPadding.PaddingRight = UDim.new(0, 3)
            cardHolderPadding.PaddingBottom = UDim.new(0, 2)

            local playerInfo = Instance.new("Frame")
            playerInfo.Parent = cardHolder
            playerInfo.Name = "playerinfo"
            playerInfo.Size = UDim2.new(1, 0, 1, 0)
            playerInfo.BackgroundTransparency = 1
            playerInfo.BorderSizePixel = 0

            local icon = Instance.new("Frame")
            icon.Parent = playerInfo
            icon.Name = "icon"
            icon.Size = UDim2.new(0, 68, 1, 0)
            icon.BackgroundColor3 = Color3.fromRGB(11, 11, 11)
            icon.BorderSizePixel = 0

            local iconFrame = Instance.new("Frame")
            iconFrame.Parent = icon
            iconFrame.Name = "Frame"
            iconFrame.Position = UDim2.new(0, 1, 0, 1)
            iconFrame.Size = UDim2.new(1, -2, 1, -2)
            iconFrame.BackgroundColor3 = Color3.fromRGB(46, 46, 46)
            iconFrame.BorderSizePixel = 0

            local iconFrame2 = Instance.new("Frame")
            iconFrame2.Parent = iconFrame
            iconFrame2.Name = "Frame"
            iconFrame2.Position = UDim2.new(0, 1, 0, 1)
            iconFrame2.Size = UDim2.new(1, -2, 1, -2)
            iconFrame2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            iconFrame2.BorderSizePixel = 0

            local iconGradient = Instance.new("UIGradient")
            iconGradient.Parent = iconFrame2
            iconGradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 30, 30)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(21, 21, 21)),
            })

            local iconImage = Instance.new("ImageLabel")
            iconImage.Parent = iconFrame2
            iconImage.Name = "ImageLabel"
            iconImage.Size = UDim2.new(1, 0, 1, 0)
            iconImage.BackgroundTransparency = 1
            iconImage.BorderSizePixel = 0
            iconImage.Image = "rbxassetid://119472238324544"
            iconImage.ImageColor3 = Color3.fromRGB(255, 255, 255)

            local health = Instance.new("Frame")
            health.Parent = playerInfo
            health.Name = "health"
            health.Position = UDim2.new(0, 72, 1, 0)
            health.AnchorPoint = Vector2.new(0, 1)
            health.Size = UDim2.new(1, -72, 0, 14)
            health.BackgroundColor3 = Color3.fromRGB(11, 11, 11)
            health.BorderSizePixel = 0

            local healthFrame = Instance.new("Frame")
            healthFrame.Parent = health
            healthFrame.Name = "Frame"
            healthFrame.Position = UDim2.new(0, 1, 0, 1)
            healthFrame.Size = UDim2.new(1, -2, 1, -2)
            healthFrame.BackgroundColor3 = Color3.fromRGB(46, 46, 46)
            healthFrame.BorderSizePixel = 0

            local healthFrame2 = Instance.new("Frame")
            healthFrame2.Parent = healthFrame
            healthFrame2.Name = "Frame"
            healthFrame2.Position = UDim2.new(0, 1, 0, 1)
            healthFrame2.Size = UDim2.new(1, -2, 1, -2)
            healthFrame2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            healthFrame2.BorderSizePixel = 0

            local healthFrameGradient = Instance.new("UIGradient")
            healthFrameGradient.Parent = healthFrame2
            healthFrameGradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 30, 30)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(21, 21, 21)),
            })

            local healthBarValue = Instance.new("Frame")
            healthBarValue.Parent = healthFrame2
            healthBarValue.Name = "healthbarvalue"
            healthBarValue.Size = UDim2.new(1, 0, 1, 0)
            healthBarValue.BackgroundColor3 = Color3.fromRGB(46, 196, 46)
            healthBarValue.BorderSizePixel = 0

            local healthBarGradient = Instance.new("UIGradient")
            healthBarGradient.Parent = healthBarValue
            healthBarGradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(125, 125, 125)),
            })

            local healthValue = Instance.new("TextLabel")
            healthValue.Parent = healthFrame2
            healthValue.Name = "healthvalue"
            healthValue.AnchorPoint = Vector2.new(0.5, 0.5)
            healthValue.Position = UDim2.new(0.5, 0, 0.5, 0)
            healthValue.Size = UDim2.new(1, 0, 1, 0)
            healthValue.BackgroundTransparency = 1
            healthValue.BorderSizePixel = 0
            healthValue.Text = "100/100"
            healthValue.TextColor3 = Color3.fromRGB(181, 181, 181)
            healthValue.TextSize = 12
            healthValue.TextXAlignment = Enum.TextXAlignment.Center
            healthValue.TextYAlignment = Enum.TextYAlignment.Center
            healthValue.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)

            local healthStroke = Instance.new("UIStroke")
            healthStroke.Parent = healthValue
            healthStroke.Color = Color3.fromRGB(0, 0, 0)
            healthStroke.Thickness = 1

            local infoTextFrame = Instance.new("Frame")
            infoTextFrame.Parent = playerInfo
            infoTextFrame.Name = "Frame"
            infoTextFrame.Position = UDim2.new(0.27, 0, 0.029, 0)
            infoTextFrame.Size = UDim2.new(0, 198, 0, 31)
            infoTextFrame.BackgroundTransparency = 1
            infoTextFrame.BorderSizePixel = 0

            local infoList = Instance.new("UIListLayout")
            infoList.Parent = infoTextFrame
            infoList.FillDirection = Enum.FillDirection.Vertical
            infoList.SortOrder = Enum.SortOrder.LayoutOrder
            infoList.Padding = UDim.new(0, 2)
            infoList.HorizontalAlignment = Enum.HorizontalAlignment.Left
            infoList.VerticalAlignment = Enum.VerticalAlignment.Top

            local targetName = Instance.new("TextLabel")
            targetName.Parent = infoTextFrame
            targetName.Name = "name"
            targetName.Size = UDim2.new(0.391519994, 0, 0.419349998, 0)
            targetName.BackgroundTransparency = 1
            targetName.BorderSizePixel = 0
            targetName.Text = "exp (@example)"
            targetName.TextColor3 = Color3.fromRGB(181, 181, 181)
            targetName.TextSize = 12
            targetName.TextXAlignment = Enum.TextXAlignment.Left
            targetName.TextYAlignment = Enum.TextYAlignment.Top
            targetName.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)

            local targetNameStroke = Instance.new("UIStroke")
            targetNameStroke.Parent = targetName
            targetNameStroke.Color = Color3.fromRGB(0, 0, 0)
            targetNameStroke.Thickness = 1

            local targetStuds = Instance.new("TextLabel")
            targetStuds.Parent = infoTextFrame
            targetStuds.Name = "studs"
            targetStuds.Size = UDim2.new(0.391519994, 0, 0.419349998, 0)
            targetStuds.BackgroundTransparency = 1
            targetStuds.BorderSizePixel = 0
            targetStuds.Text = "123 studs"
            targetStuds.TextColor3 = Color3.fromRGB(181, 181, 181)
            targetStuds.TextSize = 12
            targetStuds.TextXAlignment = Enum.TextXAlignment.Left
            targetStuds.TextYAlignment = Enum.TextYAlignment.Top
            targetStuds.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)

            local targetStudsStroke = Instance.new("UIStroke")
            targetStudsStroke.Parent = targetStuds
            targetStudsStroke.Color = Color3.fromRGB(0, 0, 0)
            targetStudsStroke.Thickness = 1

            local infoTop = Instance.new("Frame")
            infoTop.Parent = card
            infoTop.Name = "top"
            infoTop.Position = UDim2.new(0, 0, 0, 2)
            infoTop.Size = UDim2.new(1, 0, 0, 20)
            infoTop.BackgroundTransparency = 1
            infoTop.BorderSizePixel = 0

            local infoLabel = Instance.new("TextLabel")
            infoLabel.Parent = infoTop
            infoLabel.Name = "TextLabel"
            infoLabel.Size = UDim2.new(1, 0, 1, 0)
            infoLabel.BackgroundTransparency = 1
            infoLabel.BorderSizePixel = 0
            infoLabel.Text = "Info"
            infoLabel.TextColor3 = Color3.fromRGB(137, 137, 137)
            infoLabel.TextSize = 12
            infoLabel.TextXAlignment = Enum.TextXAlignment.Left
            infoLabel.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)

            local infoLabelPadding = Instance.new("UIPadding")
            infoLabelPadding.Parent = infoLabel
            infoLabelPadding.PaddingLeft = UDim.new(0, 5)

            local infoLabelStroke = Instance.new("UIStroke")
            infoLabelStroke.Parent = infoLabel
            infoLabelStroke.Color = Color3.fromRGB(0, 0, 0)
            infoLabelStroke.Thickness = 1

            local draggingTargetHud = false
            local targetHudDragStart
            local targetHudStartPos

            tFrame.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    draggingTargetHud = true
                    targetHudDragStart = input.Position
                    targetHudStartPos = tFrame.Position
                    input.Changed:Connect(function()
                        if input.UserInputState == Enum.UserInputState.End then
                            draggingTargetHud = false
                        end
                    end)
                end
            end)

            getgenv().UserInputService.InputChanged:Connect(function(input)
                if not draggingTargetHud then return end
                if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end

                local delta = input.Position - targetHudDragStart
                tFrame.Position = UDim2.new(
                    targetHudStartPos.X.Scale,
                    targetHudStartPos.X.Offset + delta.X,
                    targetHudStartPos.Y.Scale,
                    targetHudStartPos.Y.Offset + delta.Y
                )
            end)

            local ammoFrame = Instance.new("Frame")
            ammoFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 34)
            ammoFrame.BackgroundTransparency = 0.05
            ammoFrame.BorderSizePixel = 0
            ammoFrame.Size = UDim2.new(0, 196, 0, 64)
            ammoFrame.Visible = false
            ammoFrame.Parent = ammoHudGui
            Instance.new("UICorner", ammoFrame).CornerRadius = UDim.new(0, 8)

            local ammoPad = Instance.new("UIPadding")
            ammoPad.PaddingLeft = UDim.new(0, 12)
            ammoPad.PaddingRight = UDim.new(0, 12)
            ammoPad.PaddingTop = UDim.new(0, 11)
            ammoPad.PaddingBottom = UDim.new(0, 12)
            ammoPad.Parent = ammoFrame

            local ammoStroke = Instance.new("UIStroke")
            ammoStroke.Color = Color3.fromRGB(70, 72, 82)
            ammoStroke.Thickness = 1
            ammoStroke.Transparency = 0.55
            ammoStroke.Parent = ammoFrame

            local ammoName = Instance.new("TextLabel")
            ammoName.BackgroundTransparency = 1
            ammoName.Size = UDim2.new(1, 0, 0, 14)
            ammoName.Position = UDim2.new(0, 0, 0, 0)
            ammoName.Font = Enum.Font.Gotham
            ammoName.TextSize = 13
            ammoName.TextXAlignment = Enum.TextXAlignment.Left
            ammoName.TextColor3 = Color3.fromRGB(150, 153, 165)
            ammoName.Text = ""
            ammoName.Parent = ammoFrame

            local ammoBarBg = Instance.new("Frame")
            ammoBarBg.BackgroundColor3 = Color3.fromRGB(38, 40, 48)
            ammoBarBg.BorderSizePixel = 0
            ammoBarBg.Size = UDim2.new(1, 0, 0, 20)
            ammoBarBg.Position = UDim2.new(0, 0, 1, -20)
            ammoBarBg.AnchorPoint = Vector2.new(0, 0)
            ammoBarBg.Parent = ammoFrame
            Instance.new("UICorner", ammoBarBg).CornerRadius = UDim.new(0, 5)

            local ammoBar = Instance.new("Frame")
            ammoBar.BackgroundColor3 = Color3.fromRGB(91, 124, 250)
            ammoBar.BorderSizePixel = 0
            ammoBar.Size = UDim2.new(1, 0, 1, 0)
            ammoBar.Parent = ammoBarBg
            Instance.new("UICorner", ammoBar).CornerRadius = UDim.new(0, 5)

            local ammoValue = Instance.new("TextLabel")
            ammoValue.BackgroundTransparency = 1
            ammoValue.Size = UDim2.new(1, 0, 1, 0)
            ammoValue.Position = UDim2.new(0, 0, 0, 0)
            ammoValue.Font = Enum.Font.GothamBold
            ammoValue.TextSize = 13
            ammoValue.TextXAlignment = Enum.TextXAlignment.Center
            ammoValue.TextYAlignment = Enum.TextYAlignment.Center
            ammoValue.TextColor3 = Color3.fromRGB(255, 255, 255)
            ammoValue.TextStrokeTransparency = 0.5
            ammoValue.Text = ""
            ammoValue.Parent = ammoBarBg

            local ammoLastValue = nil
            local ammoHideAt = 0
            local ammoDisplayFrac = 1
            local ammoPulseUntil = 0

            local function ammoPos(mode)
                if mode == "Top" then return UDim2.new(0.5, -95, 0, 80) end
                if mode == "Left" then return UDim2.new(0, 20, 0.5, -27) end
                if mode == "Right" then return UDim2.new(1, -210, 0.5, -27) end
                return UDim2.new(1, -20, 1, -140)
            end

            local function tvh(n) local t = Toggles[n] ; return t and t.Value end
            local function ovh(n) local o = Options[n] ; return o and o.Value end

            getgenv().HUDConnection = getgenv().RunService.RenderStepped:Connect(function()
                local target = getgenv().ForceHitTarget
                if tvh('TargetHUDEnabled') and target and target.Parent and target.Character then
                    local hum = target.Character:FindFirstChildOfClass("Humanoid")
                    local hrp = target.Character:FindFirstChild("HumanoidRootPart")
                    if hum and hrp then
                        local col = ovh('TargetHUDColor') or Color3.fromRGB(97, 121, 191)
                        local healthFrac = math.clamp(hum.Health / (hum.MaxHealth > 0 and hum.MaxHealth or 100), 0, 1)
                        local dist = math.floor((getgenv().Camera.CFrame.Position - hrp.Position).Magnitude + 0.5)
                        local thumb = Players:GetUserThumbnailAsync(target.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
                        tFrame.Visible = true
                        targetName.Text = string.format("%s (@%s)", target.DisplayName or target.Name, target.Name)
                        targetStuds.Text = string.format("%d studs", dist)
                        iconImage.Image = thumb
                        tFrame2.BackgroundColor3 = col
                        cardBar.BackgroundColor3 = col
                        cardBarGradient.Color = ColorSequence.new({
                            ColorSequenceKeypoint.new(0, col),
                            ColorSequenceKeypoint.new(1, col:Lerp(Color3.fromRGB(20, 20, 20), 0.22)),
                        })
                        healthBarValue.Size = UDim2.new(healthFrac, 0, 1, 0)
                        healthBarValue.BackgroundColor3 = Color3.fromRGB(46, 196, 46)
                        healthValue.Text = string.format("%d/%d", math.floor(hum.Health + 0.5), math.floor((hum.MaxHealth > 0 and hum.MaxHealth or 100) + 0.5))
                    else
                        tFrame.Visible = false
                    end
                else
                    tFrame.Visible = false
                end

                if tvh('AmmoHUDEnabled') then
                    local char = getgenv().LocalPlayer.Character
                    local tool = char and char:FindFirstChildOfClass("Tool")
                    local s = tool and tool:FindFirstChild("Script")
                    local a = s and s:FindFirstChild("Ammo")
                    if a and a:IsA("IntValue") then
                        local maxAmmo = tool:FindFirstChild("MaxAmmo") or s:FindFirstChild("MaxAmmo")
                        local maxValue = (maxAmmo and maxAmmo:IsA("IntValue") and maxAmmo.Value > 0) and maxAmmo.Value or math.max(a.Value, 1)
                        local frac = math.clamp(a.Value / maxValue, 0, 1)

                        if ammoLastValue ~= nil and a.Value < ammoLastValue then
                            ammoPulseUntil = tick() + 0.18
                        end
                        ammoLastValue = a.Value
                        ammoHideAt = tick() + 2

                        local targetPos = ammoPos(ovh('AmmoHUDPosition') or 'Normal')
                        local hiddenPos = targetPos + UDim2.new(0, 18, 0, 0)
                        local timeLeft = ammoHideAt - tick()
                        local visible = timeLeft > 0
                        ammoFrame.Visible = visible

                        local fadeAlpha = 1
                        if timeLeft < 0.25 then
                            fadeAlpha = math.clamp(timeLeft / 0.25, 0, 1)
                        end
                        local posAlpha = 1 - (1 - fadeAlpha)
                        ammoFrame.Position = hiddenPos:Lerp(targetPos, posAlpha)

                        ammoDisplayFrac = ammoDisplayFrac + (frac - ammoDisplayFrac) * 0.25
                        ammoName.Text = tostring(tool.Name):gsub("^%[", ""):gsub("%]$", "")
                        ammoBar.Size = UDim2.new(ammoDisplayFrac, 0, 1, 0)
                        ammoValue.Text = string.format("%d/%d", a.Value, maxValue)

                        local pulseActive = tick() < ammoPulseUntil
                        ammoBar.BackgroundColor3 = pulseActive and Color3.fromRGB(124, 152, 255) or Color3.fromRGB(91, 124, 250)
                        ammoFrame.BackgroundTransparency = (pulseActive and 0.0 or 0.05) + ((1 - fadeAlpha) * 0.75)
                        ammoStroke.Transparency = (pulseActive and 0.4 or 0.55) + ((1 - fadeAlpha) * 0.45)
                        ammoName.TextTransparency = 1 - fadeAlpha
                        ammoValue.TextTransparency = 1 - fadeAlpha
                        ammoValue.TextStrokeTransparency = 0.5 + ((1 - fadeAlpha) * 0.5)
                        ammoBar.BackgroundTransparency = 1 - fadeAlpha
                        ammoBarBg.BackgroundTransparency = 0.15 + ((1 - fadeAlpha) * 0.7)
                        ammoValue.TextSize = pulseActive and 14 or 13
                    else
                        ammoLastValue = nil
                        ammoFrame.Visible = false
                    end
                else
                    ammoLastValue = nil
                    ammoFrame.Visible = false
                end
            end)
        end

        SkinChangerGb:AddToggle('SkinChangerEnabled', {
            Text = 'Weapon Skins',
            Default = false,
            Callback = function(val)
                if val then
                    getgenv().Larptic_ApplySkins()
                end
            end,
        })
        SkinChangerGb:AddDropdown('SkinDoubleBarrel', { Text = 'DoubleBarrel Skin', Values = GUN_SKINS, Default = 1, Callback = function() applyVisualGuns() end })
        SkinChangerGb:AddDropdown('SkinRevolver', { Text = 'Revolver Skin', Values = GUN_SKINS, Default = 1, Callback = function() applyVisualGuns() end })
        SkinChangerGb:AddDropdown('SkinTacticalShotgun', { Text = 'TacticalShotgun Skin', Values = GUN_SKINS, Default = 1, Callback = function() applyVisualGuns() end })
        SkinChangerGb:AddDropdown('SkinSMG', { Text = 'SMG Skin', Values = GUN_SKINS, Default = 1, Callback = function() applyVisualGuns() end })
        SkinChangerGb:AddDropdown('SkinShotgun', { Text = 'Shotgun Skin', Values = GUN_SKINS, Default = 1, Callback = function() applyVisualGuns() end })
        SkinChangerGb:AddDropdown('SkinKnife', { Text = 'Knife Skin', Values = KNIFE_SKINS, Default = 1, Callback = function() applyVisualGuns() end })
        SkinChangerGb:AddDivider()
        SkinChangerGb:AddToggle('BulletChangerEnabled', {
            Text = 'Bullet Changer',
            Default = false,
            Callback = function(val)
                if val then getgenv().Larptic_ApplyBullets() end
            end,
        })
        SkinChangerGb:AddDropdown('BulletTexture', {
            Text = 'Bullet Texture',
            Values = BULLET_SKINS,
            Default = 'Beta',
            Callback = function()
                if Toggles.BulletChangerEnabled and Toggles.BulletChangerEnabled.Value then
                    getgenv().Larptic_ApplyBullets()
                end
            end,
        })

        BodyPartsGb:AddToggle('Dickesp', {
            Text = 'Dick visuals  (Local Player)',
            Default = false,
            Callback = function(enabled)
                DickESP.SelfEnabled = enabled

                if not enabled then
                    getgenv().CleanupAttachedDickESPModel(LocalPlayer)
                    return
                end

                if LocalPlayer.Character then
                    attachPartsWithHighlight(LocalPlayer.Character, LocalPlayer)
                end
            end
        })

        BodyPartsGb:AddToggle('DickespOthers', {
            Text = 'Dick visuals (Other Players)',
            Default = false,
            Callback = function(enabled)
                DickESP.OthersEnabled = enabled

                if not enabled then
                    for player, model in pairs(AttachedModels) do
                        if player ~= LocalPlayer and model then
                            getgenv().CleanupAttachedDickESPModel(player)
                        end
                    end
                    return
                end

                for _, player in pairs(game:GetService("Players"):GetPlayers()) do
                    if player ~= LocalPlayer and player.Character then
                        attachPartsWithHighlight(player.Character, player)
                    end
                end
            end
        })

        RightTabVisual:AddToggle('SelfAuraEnabled', {
            Text = 'Particle Aura',
            Default = false,
            Callback = function(val)
                if val then
                    refreshSelfAura()
                else
                    clearSelfAura()
                end
            end,
        }):AddColorPicker('SelfAuraColor', {
            Default = ACCENT,
            Title = 'Aura Color',
            Callback = function()
                if Toggles.SelfAuraEnabled and Toggles.SelfAuraEnabled.Value then
                    refreshSelfAura()
                end
            end,
        })

        local selfAuraTypeValues = { 'None' }
        for _, n in ipairs(PARTICLE_AURA_NAMES) do
            table.insert(selfAuraTypeValues, n)
        end

        RightTabVisual:AddDropdown('SelfAuraType', {
            Values = selfAuraTypeValues,
            Default = 1,
            Text = 'Aura Type',
            Callback = function()
                if Toggles.SelfAuraEnabled and Toggles.SelfAuraEnabled.Value then
                    refreshSelfAura()
                end
            end,
        })

        do
            local GunMaterialGb = getgenv().GunMaterialGb
            local MATERIALS = {
                'Neon', 'ForceField', 'Glass', 'Plastic', 'SmoothPlastic',
                'Metal', 'DiamondPlate', 'Foil', 'Wood', 'WoodPlanks',
                'Marble', 'Slate', 'Concrete', 'Ice', 'Glacier', 'Granite',
            }

            GunMaterialGb:AddToggle('GunMaterialEnabled', {
                Text = 'Gun Material',
                Default = false,
            }):AddColorPicker('GunMaterialColor', {
                Default = ACCENT,
                Title = 'Gun Color',
            })

            GunMaterialGb:AddDropdown('GunMaterialType', {
                Text = 'Material Type',
                Values = MATERIALS,
                Default = 'Neon',
            })

            local function gunMatParts()
                local out = {}
                local char = getgenv().LocalPlayer.Character
                if char then
                    for _, t in ipairs(char:GetChildren()) do
                        if t:IsA('Tool') then table.insert(out, t) end
                    end
                end
                local bp = getgenv().LocalPlayer:FindFirstChild('Backpack')
                if bp then
                    for _, t in ipairs(bp:GetChildren()) do
                        if t:IsA('Tool') then table.insert(out, t) end
                    end
                end
                return out
            end

            task.spawn(function()
                while task.wait(0.3) do
                    if not (Toggles.GunMaterialEnabled and Toggles.GunMaterialEnabled.Value) then continue end
                    local matName = (Options.GunMaterialType and Options.GunMaterialType.Value) or 'Neon'
                    local mat = Enum.Material[matName] or Enum.Material.Neon
                    local col = (Options.GunMaterialColor and Options.GunMaterialColor.Value) or Color3.fromRGB(255, 0, 0)
                    for _, tool in ipairs(gunMatParts()) do
                        for _, p in ipairs(tool:GetDescendants()) do
                            if p:IsA('BasePart') and p.Transparency < 1 then
                                pcall(function()
                                    p.Material = mat
                                    p.Color = col
                                end)
                            end
                        end
                    end
                end
            end)
        end

        do
            local WorldGb = getgenv().WorldGb
            local Lighting = game:GetService('Lighting')
            local Terrain = workspace:FindFirstChildOfClass('Terrain')

            local function tvw(n) local t = Toggles[n] ; return t and t.Value end
            local function ovw(n) local o = Options[n] ; return o and o.Value end

            WorldGb:AddToggle('WorldLightingMode', { Text = 'Lighting Mode', Default = false })
            WorldGb:AddDropdown('WorldLightingTech', {
                Text = 'Mode',
                Values = { 'Compatibility', 'Voxel', 'ShadowMap', 'Future', 'Legacy' },
                Default = 'ShadowMap',
                Callback = function(v)
                    if not (Toggles.WorldLightingMode and Toggles.WorldLightingMode.Value) then return end
                    pcall(function() Lighting.Technology = Enum.Technology[v] end)
                    if sethiddenproperty then pcall(function() sethiddenproperty(Lighting, 'Technology', Enum.Technology[v]) end) end
                end,
            })
            if Toggles.WorldLightingMode then
                Toggles.WorldLightingMode:OnChanged(function()
                    if Toggles.WorldLightingMode.Value then
                        local v = ovw('WorldLightingTech') or 'ShadowMap'
                        pcall(function() Lighting.Technology = Enum.Technology[v] end)
                        if sethiddenproperty then pcall(function() sethiddenproperty(Lighting, 'Technology', Enum.Technology[v]) end) end
                    end
                end)
            end

            WorldGb:AddToggle('WorldTimeEnabled', { Text = 'World Time', Default = false })
            WorldGb:AddSlider('WorldTimeHour', {
                Text = 'Hour', Default = 4.5, Min = 0, Max = 24, Rounding = 1,
                Callback = function(v)
                    if Toggles.WorldTimeEnabled and Toggles.WorldTimeEnabled.Value then
                        pcall(function() Lighting.ClockTime = v end)
                    end
                end,
            })
            task.spawn(function()
                while task.wait(0.1) do
                    if tvw('WorldTimeEnabled') then
                        pcall(function() Lighting.ClockTime = ovw('WorldTimeHour') or 4.5 end)
                    end
                end
            end)

            getgenv().LarpticAtmosphere = nil
            local function applyAtmosphere()
                local atm = getgenv().LarpticAtmosphere
                if not (atm and atm.Parent) then
                    atm = Instance.new('Atmosphere')
                    atm.Name = 'LarpticAtmosphere'
                    atm.Parent = Lighting
                    getgenv().LarpticAtmosphere = atm
                end
                pcall(function()
                    atm.Density = ovw('WorldAtmDensity') or 0.35
                    atm.Offset = ovw('WorldAtmOffset') or 0
                    atm.Haze = ovw('WorldAtmHaze') or 1
                    atm.Glare = ovw('WorldAtmGlare') or 10
                    atm.Color = (Options.WorldAtmColor and Options.WorldAtmColor.Value) or Color3.fromRGB(199, 212, 255)
                    atm.Decay = (Options.WorldAtmDecay and Options.WorldAtmDecay.Value) or Color3.fromRGB(106, 112, 125)
                end)
            end
            local function clearAtmosphere()
                local atm = getgenv().LarpticAtmosphere
                if atm then pcall(function() atm:Destroy() end) end
                getgenv().LarpticAtmosphere = nil
            end

            local WorldAtmToggle = WorldGb:AddToggle('WorldAtmEnabled', {
                Text = 'Atmosphere', Default = false,
                Callback = function(v) if v then applyAtmosphere() else clearAtmosphere() end end,
            })
            WorldAtmToggle:AddColorPicker('WorldAtmColor', {
                Default = Color3.fromRGB(199, 212, 255),
                Title = 'Atmosphere Color',
                Callback = function() if tvw('WorldAtmEnabled') then applyAtmosphere() end end,
            })
            WorldAtmToggle:AddColorPicker('WorldAtmDecay', {
                Default = Color3.fromRGB(106, 112, 125),
                Title = 'Atmosphere Decay',
                Callback = function() if tvw('WorldAtmEnabled') then applyAtmosphere() end end,
            })
            WorldGb:AddSlider('WorldAtmHaze', { Text = 'Haze', Default = 1, Min = 0, Max = 10, Rounding = 1, Callback = function() if tvw('WorldAtmEnabled') then applyAtmosphere() end end })
            WorldGb:AddSlider('WorldAtmGlare', { Text = 'Glare', Default = 10, Min = 0, Max = 10, Rounding = 1, Callback = function() if tvw('WorldAtmEnabled') then applyAtmosphere() end end })
            WorldGb:AddSlider('WorldAtmOffset', { Text = 'Offset', Default = 0, Min = 0, Max = 1, Rounding = 2, Callback = function() if tvw('WorldAtmEnabled') then applyAtmosphere() end end })
            WorldGb:AddSlider('WorldAtmDensity', { Text = 'Density', Default = 0.35, Min = 0, Max = 1, Rounding = 2, Callback = function() if tvw('WorldAtmEnabled') then applyAtmosphere() end end })

            local MaterialService = game:GetService('MaterialService')
            local MINECRAFT_VARIANTS = {
                Brick = { BaseMaterial = Enum.Material.Brick, Texture = 'rbxassetid://10777285622' },
                Concrete = { BaseMaterial = Enum.Material.Concrete, Texture = 'rbxassetid://15622710576' },
                CorrodedMetal = { BaseMaterial = Enum.Material.CorrodedMetal, Texture = 'rbxassetid://78612695839404' },
                Grass = { BaseMaterial = Enum.Material.Grass, Texture = 'rbxassetid://9267183930' },
                Metal = { BaseMaterial = Enum.Material.Metal, Texture = 'rbxassetid://121650613091353' },
                Sand = { BaseMaterial = Enum.Material.Sand, Texture = 'rbxassetid://12624140843' },
                Slate = { BaseMaterial = Enum.Material.Slate, Texture = 'rbxassetid://8676746437' },
                Wood = { BaseMaterial = Enum.Material.Wood, Texture = 'rbxassetid://3258599312' },
                WoodPlanks = { BaseMaterial = Enum.Material.WoodPlanks, Texture = 'rbxassetid://8676581022' },
            }
            local MATERIAL_VARIANT_BY_MATERIAL = {
                [Enum.Material.Brick] = 'Brick',
                [Enum.Material.Concrete] = 'Concrete',
                [Enum.Material.CorrodedMetal] = 'CorrodedMetal',
                [Enum.Material.Grass] = 'Grass',
                [Enum.Material.Metal] = 'Metal',
                [Enum.Material.Sand] = 'Sand',
                [Enum.Material.Slate] = 'Slate',
                [Enum.Material.Wood] = 'Wood',
                [Enum.Material.WoodPlanks] = 'WoodPlanks',
            }
            local MINECRAFT_TERRAIN_COLORS = {
                [Enum.Material.Grass] = Color3.fromRGB(106, 170, 64),
                [Enum.Material.Ground] = Color3.fromRGB(134, 96, 67),
                [Enum.Material.Mud] = Color3.fromRGB(102, 76, 51),
                [Enum.Material.Sand] = Color3.fromRGB(219, 211, 160),
                [Enum.Material.Rock] = Color3.fromRGB(122, 122, 122),
                [Enum.Material.Slate] = Color3.fromRGB(90, 90, 90),
                [Enum.Material.Snow] = Color3.fromRGB(245, 245, 245),
                [Enum.Material.Water] = Color3.fromRGB(63, 118, 228),
            }
            getgenv().LarpticTextureState = getgenv().LarpticTextureState or setmetatable({}, { __mode = 'k' })
            getgenv().LarpticMaterialVariantsBuilt = getgenv().LarpticMaterialVariantsBuilt or false

            local function ensureMinecraftVariants()
                if getgenv().LarpticMaterialVariantsBuilt then return end

                for name, data in pairs(MINECRAFT_VARIANTS) do
                    local variant = MaterialService:FindFirstChild(name)
                    if not variant then
                        variant = Instance.new('MaterialVariant')
                        variant.Name = name
                        variant.Parent = MaterialService
                    end

                    pcall(function()
                        variant.BaseMaterial = data.BaseMaterial
                        variant.ColorMap = data.Texture
                        variant.MetalnessMap = data.Texture
                        variant.NormalMap = data.Texture
                        variant.RoughnessMap = data.Texture
                        variant.MaterialPattern = Enum.MaterialPattern.Regular
                        variant.StudsPerTile = 5
                    end)
                end

                getgenv().LarpticMaterialVariantsBuilt = true
            end

            local function rememberPartState(part)
                local state = getgenv().LarpticTextureState
                if not state[part] then
                    state[part] = {
                        Color = part.Color,
                        Material = part.Material,
                        MaterialVariant = part.MaterialVariant,
                    }
                end
                return state[part]
            end

            local function shouldSkipTexturePart(part)
                if not part:IsDescendantOf(workspace) then return true end
                if part.Name == 'LarpticWeather' or part.Name == 'Part' then return true end
                local parent = part.Parent
                if parent and (parent:IsA('Tool') or parent:IsA('Accessory')) then return true end
                local model = part:FindFirstAncestorOfClass('Model')
                if model and Players:GetPlayerFromCharacter(model) then return true end
                return false
            end

            local function applyPartTexturePack()
                ensureMinecraftVariants()

                for _, obj in ipairs(workspace:GetDescendants()) do
                    if obj:IsA('BasePart') and not shouldSkipTexturePart(obj) then
                        rememberPartState(obj)

                        local variantName = MATERIAL_VARIANT_BY_MATERIAL[obj.Material]
                        if variantName then
                            pcall(function()
                                obj.MaterialVariant = variantName
                            end)
                        end
                    end
                end
            end

            local function clearPartTexturePack()
                for part, state in pairs(getgenv().LarpticTextureState) do
                    if part and part.Parent and state then
                        pcall(function()
                            part.Color = state.Color
                            part.Material = state.Material
                            part.MaterialVariant = state.MaterialVariant or ''
                        end)
                    end
                end
            end

            local function clearMinecraftVariants()
                for name, _ in pairs(MINECRAFT_VARIANTS) do
                    local variant = MaterialService:FindFirstChild(name)
                    if variant and variant:IsA('MaterialVariant') then
                        pcall(function()
                            variant:Destroy()
                        end)
                    end
                end
                getgenv().LarpticMaterialVariantsBuilt = false
            end

            local function applyTexturePack()
                Terrain = Terrain or workspace:FindFirstChildOfClass('Terrain')

                if Terrain then
                    for mat, col in pairs(MINECRAFT_TERRAIN_COLORS) do
                        pcall(function() Terrain:SetMaterialColor(mat, col) end)
                    end
                end

                applyPartTexturePack()
            end

            local function clearTexturePack()
                clearPartTexturePack()
                clearMinecraftVariants()
            end

            WorldGb:AddToggle('WorldTexturesEnabled', {
                Text = 'Textures', Default = false,
                Callback = function(v)
                    if v then
                        applyTexturePack()
                    else
                        clearTexturePack()
                    end
                end,
            })
            WorldGb:AddDropdown('WorldTexturePack', {
                Text = 'Pack',
                Values = { 'minecraft' },
                Default = 'minecraft',
                Callback = function()
                    if tvw('WorldTexturesEnabled') then
                        applyTexturePack()
                    end
                end,
            })
            local WorldAmbientToggle = WorldGb:AddToggle('WorldAmbient', {
                Text = 'Ambient', Default = false,
                Callback = function(v)
                    if v then
                        pcall(function()
                            Lighting.Ambient = (Options.WorldAmbientColor and Options.WorldAmbientColor.Value) or Color3.fromRGB(178, 178, 178)
                            Lighting.OutdoorAmbient = (Options.WorldOutdoorAmbientColor and Options.WorldOutdoorAmbientColor.Value) or Color3.fromRGB(178, 178, 178)
                            Lighting.Brightness = 3
                        end)
                    else
                        pcall(function()
                            Lighting.Ambient = Color3.fromRGB(0, 0, 0)
                            Lighting.OutdoorAmbient = Color3.fromRGB(70, 70, 70)
                        end)
                    end
                end,
            })
            WorldAmbientToggle:AddColorPicker('WorldAmbientColor', {
                Default = Color3.fromRGB(178, 178, 178),
                Title = 'Ambient Color',
                Callback = function()
                    if tvw('WorldAmbient') then
                        pcall(function()
                            Lighting.Ambient = Options.WorldAmbientColor.Value
                        end)
                    end
                end,
            })
            WorldAmbientToggle:AddColorPicker('WorldOutdoorAmbientColor', {
                Default = Color3.fromRGB(178, 178, 178),
                Title = 'Outdoor Ambient Color',
                Callback = function()
                    if tvw('WorldAmbient') then
                        pcall(function()
                            Lighting.OutdoorAmbient = Options.WorldOutdoorAmbientColor.Value
                        end)
                    end
                end,
            })

            getgenv().LarpticWeatherPart = nil
            getgenv().LarpticWeatherConn = nil
            getgenv().LarpticWeatherEmitters = nil
            getgenv().LarpticRainCharacterConn = nil

            local function clearCharacterRain()
                if getgenv().LarpticWeatherPart then
                    pcall(function() getgenv().LarpticWeatherPart:Destroy() end)
                    getgenv().LarpticWeatherPart = nil
                end
            end

            local function createCharacterRain(character)
                local head = character and character:FindFirstChild("Head")
                local root = character and character:FindFirstChild("HumanoidRootPart")
                if not head and not root then return end
                local weatherType = ovw('WorldWeatherType') or 'rain'
                local isLightRain = weatherType == 'light rain'
                local rate = ovw('WorldWeatherRate') or 100

                clearCharacterRain()

                local part = Instance.new("Part")
                part.Name = "Part"
                part.Size = Vector3.new(40, 40, 85)
                part.Transparency = 1
                part.Anchored = true
                part.CanCollide = false
                part.CanQuery = false
                part.CanTouch = false
                part.Parent = workspace

                local rainColor = (Options.WorldWeatherColor and Options.WorldWeatherColor.Value) or Color3.fromRGB(215, 228, 255)

                local rain = Instance.new("ParticleEmitter")
                rain.Name = "ParticleEmitter"
                rain.Texture = "rbxassetid://1822883048"
                rain.Brightness = 1
                rain.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
                rain.LightEmission = 0.05
                rain.LightInfluence = 0.9
                rain.Orientation = Enum.ParticleOrientation.FacingCamera
                rain.Size = NumberSequence.new(10)
                rain.Squash = NumberSequence.new(2)
                rain.Transparency = NumberSequence.new(0.5)
                rain.ZOffset = 0
                rain.EmissionDirection = Enum.NormalId.Bottom
                rain.Enabled = true
                rain.Lifetime = NumberRange.new(0.8, 0.8)
                rain.Rate = isLightRain and 0 or math.max(rate * 6, 600)
                rain.Rotation = NumberRange.new(0, 0)
                rain.RotSpeed = NumberRange.new(0, 0)
                rain.Speed = NumberRange.new(60, 60)
                rain.SpreadAngle = Vector2.new(0, 0)
                rain.VelocityInheritance = 0
                rain.Drag = 0
                rain.LockedToPart = true
                rain.Parent = part

                if isLightRain then
                    local lightRain = Instance.new("ParticleEmitter")
                    lightRain.Name = "LightRainEffect"
                    lightRain.Texture = "rbxasset://textures/particles/sparkles_main.dds"
                    lightRain.Brightness = 1
                    lightRain.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
                    lightRain.LightEmission = 0.05
                    lightRain.LightInfluence = 0.9
                    lightRain.Orientation = Enum.ParticleOrientation.FacingCamera
                    lightRain.Size = NumberSequence.new(1)
                    lightRain.Squash = NumberSequence.new(4)
                    lightRain.Transparency = NumberSequence.new(0.5)
                    lightRain.ZOffset = 0
                    lightRain.EmissionDirection = Enum.NormalId.Bottom
                    lightRain.Enabled = true
                    lightRain.Lifetime = NumberRange.new(0.8, 0.8)
                    lightRain.Rate = math.max(rate * 6, 600)
                    lightRain.Rotation = NumberRange.new(0, 0)
                    lightRain.RotSpeed = NumberRange.new(0, 0)
                    lightRain.Speed = NumberRange.new(60, 60)
                    lightRain.SpreadAngle = Vector2.new(0, 0)
                    lightRain.VelocityInheritance = 0
                    lightRain.Drag = 0
                    lightRain.LockedToPart = true
                    lightRain.Parent = part
                end

                getgenv().LarpticWeatherPart = part
            end

            local function clearWeather()
                if getgenv().LarpticWeatherConn then getgenv().LarpticWeatherConn:Disconnect() ; getgenv().LarpticWeatherConn = nil end
                if getgenv().LarpticRainCharacterConn then getgenv().LarpticRainCharacterConn:Disconnect() ; getgenv().LarpticRainCharacterConn = nil end
                getgenv().LarpticWeatherEmitters = nil
                clearCharacterRain()
                if getgenv().LarpticWeatherPart then pcall(function() getgenv().LarpticWeatherPart:Destroy() end) ; getgenv().LarpticWeatherPart = nil end
            end
            local function buildWeather()
                clearWeather()
                local kind = ovw('WorldWeatherType') or 'rain'

                if kind == 'rain' or kind == 'light rain' then
                    local localPlayer = getgenv().LocalPlayer
                    if localPlayer.Character then
                        createCharacterRain(localPlayer.Character)
                    end

                    getgenv().LarpticRainCharacterConn = localPlayer.CharacterAdded:Connect(function(character)
                        task.defer(function()
                            createCharacterRain(character)
                        end)
                    end)
                    getgenv().LarpticWeatherConn = getgenv().RunService.RenderStepped:Connect(function()
                        local character = localPlayer.Character
                        local head = character and character:FindFirstChild("Head")
                        local root = character and character:FindFirstChild("HumanoidRootPart")
                        local followPart = getgenv().LarpticWeatherPart
                        local target = head or root
                        if followPart and followPart.Parent and target then
                            followPart.CFrame = CFrame.new(target.Position + Vector3.new(0, 10, 0))
                        end
                    end)
                    return
                end

                local part = Instance.new('Part')
                part.Name = 'Part'
                part.Size = Vector3.new(260, 1, 260)
                part.Transparency = 1
                part.Anchored = true
                part.CanCollide = false
                part.CanQuery = false
                part.CanTouch = false
                part.Parent = workspace

                local primary = Instance.new('ParticleEmitter')
                primary.Name = 'WeatherEmitterPrimary'
                primary.Parent = part

                local secondary = Instance.new('ParticleEmitter')
                secondary.Name = 'WeatherEmitterSecondary'
                secondary.Parent = part

                local tertiary = Instance.new('ParticleEmitter')
                tertiary.Name = 'WeatherEmitterTertiary'
                tertiary.Parent = part

                getgenv().LarpticWeatherPart = part
                getgenv().LarpticWeatherEmitters = { primary, secondary, tertiary }

                local function configure()
                    local rate = ovw('WorldWeatherRate') or 100
                    local primaryRate = math.max(rate, 0)
                    local secondaryRate = math.max(math.floor(rate * 0.35), 0)

                    if kind == 'snow' then
                        tertiary.Texture = 'rbxassetid://99851851'
                        tertiary.Brightness = 1
                        tertiary.LightEmission = 0.5
                        tertiary.LightInfluence = 0
                        tertiary.Orientation = Enum.ParticleOrientation.FacingCamera
                        tertiary.Lifetime = NumberRange.new(5, 10)
                        tertiary.Speed = NumberRange.new(30, 30)
                        tertiary.Rotation = NumberRange.new(0, 0)
                        tertiary.RotSpeed = NumberRange.new(0, 0)
                        tertiary.Size = NumberSequence.new({
                            NumberSequenceKeypoint.new(0, 0.33),
                            NumberSequenceKeypoint.new(0.5, 0.551),
                            NumberSequenceKeypoint.new(1, 0.401),
                        })
                        tertiary.Squash = NumberSequence.new({
                            NumberSequenceKeypoint.new(0, 0),
                            NumberSequenceKeypoint.new(0.75, 0),
                            NumberSequenceKeypoint.new(1, 0),
                        })
                        tertiary.Color = ColorSequence.new((Options.WorldWeatherColor and Options.WorldWeatherColor.Value) or Color3.fromRGB(230, 236, 255))
                        tertiary.Transparency = NumberSequence.new({
                            NumberSequenceKeypoint.new(0, 0.74),
                            NumberSequenceKeypoint.new(0.35, 0.973),
                            NumberSequenceKeypoint.new(0.7, 0.77),
                            NumberSequenceKeypoint.new(1, 1),
                        })
                        tertiary.ZOffset = 0
                        tertiary.Acceleration = Vector3.new(0, 0, 0)
                        tertiary.Drag = 0
                        tertiary.SpreadAngle = Vector2.new(50, 50)
                        tertiary.Rate = math.max(primaryRate * 10, 1000)
                        tertiary.EmissionDirection = Enum.NormalId.Bottom
                        tertiary.Enabled = true

                        primary.Enabled = false
                        secondary.Enabled = false
                    end
                end
                configure()
                getgenv().LarpticConfigureWeather = configure

                getgenv().LarpticWeatherConn = getgenv().RunService.RenderStepped:Connect(function()
                    if part and part.Parent then
                        local camPos = getgenv().Camera.CFrame.Position
                        part.CFrame = CFrame.new(camPos + Vector3.new(0, 85, 0))

                        if kind == 'snow' then
                            local sway = math.sin(os.clock() * 0.9) * 6
                            primary.Acceleration = Vector3.new(sway, -20, sway * 0.35)
                            secondary.Acceleration = Vector3.new(-sway * 0.55, -14, sway * 0.55)
                        end
                    end
                end)
            end

            local WorldWeatherToggle = WorldGb:AddToggle('WorldWeatherEnabled', {
                Text = 'Weather', Default = false,
                Callback = function(v) if v then buildWeather() else clearWeather() end end,
            })
            WorldWeatherToggle:AddColorPicker('WorldWeatherColor', {
                Default = Color3.fromRGB(255, 255, 255),
                Title = 'Weather Color',
                Callback = function()
                    if tvw('WorldWeatherEnabled') then
                        buildWeather()
                    end
                end,
            })
            WorldGb:AddDropdown('WorldWeatherType', {
                Text = 'Type', Values = { 'light rain', 'rain', 'snow' }, Default = 'rain',
                Callback = function()
                    if tvw('WorldWeatherEnabled') then
                        buildWeather()
                    end
                end,
            })
            WorldGb:AddSlider('WorldWeatherRate', {
                Text = 'Rate', Default = 100, Min = 0, Max = 100, Rounding = 0,
                Callback = function() if tvw('WorldWeatherEnabled') and getgenv().LarpticConfigureWeather then getgenv().LarpticConfigureWeather() end end,
            })

            getgenv().LarpticSky = nil

            -- Named skybox presets carried over from the supplied Da Hood scripts.
            -- Each entry is { back, down, front, left, right, up } in Sky property
            -- order, so adding a new sky is a single line.
            local SKY_PRESETS = {
                AlienRed          = { 'rbxassetid://1012890', 'rbxassetid://1012891', 'rbxassetid://1012887', 'rbxassetid://1012889', 'rbxassetid://1012888', 'rbxassetid://1014449' },
                Anime             = { 'rbxassetid://7643700666', 'rbxassetid://7643743687', 'rbxassetid://7644304186', 'rbxassetid://7644288724', 'rbxassetid://7643700819', 'rbxassetid://7643757404' },
                AnimeIsland       = { 'rbxassetid://14753804949', 'rbxassetid://14753795573', 'rbxassetid://14753807625', 'rbxassetid://14753797417', 'rbxassetid://14753799966', 'rbxassetid://14753810287' },
                AnimeMountains    = { 'rbxassetid://12849370744', 'rbxassetid://12849378890', 'rbxassetid://12849390276', 'rbxassetid://12849405549', 'rbxassetid://12849398428', 'rbxassetid://12849426002' },
                BlueAbyss         = { 'rbxassetid://16269815885', 'rbxassetid://16269839652', 'rbxassetid://16269798011', 'rbxassetid://16269813852', 'rbxassetid://16269814948', 'rbxassetid://16269829700' },
                BlueGradient      = { 'rbxassetid://4628466090', 'rbxassetid://4628471901', 'rbxassetid://4628466090', 'rbxassetid://4628466090', 'rbxassetid://4628466090', 'rbxassetid://4628472152' },
                BlueSpace         = { 'rbxassetid://1127563035', 'rbxassetid://1127563006', 'rbxassetid://1127563026', 'rbxassetid://1127563216', 'rbxassetid://1127563115', 'rbxassetid://1127562999' },
                CartoonSky        = { 'rbxassetid://6778646360', 'rbxassetid://6778658683', 'rbxassetid://6778648039', 'rbxassetid://6778649136', 'rbxassetid://6778650519', 'rbxassetid://6778658364' },
                ClassicSky        = { 'rbxassetid://672345740', 'rbxassetid://672345828', 'rbxassetid://672345879', 'rbxassetid://672345927', 'rbxassetid://672346006', 'rbxassetid://672346072' },
                ClearDay          = { 'rbxassetid://591058823', 'rbxassetid://591059876', 'rbxassetid://591058104', 'rbxassetid://591057861', 'rbxassetid://591057625', 'rbxassetid://591059642' },
                Cloudy            = { 'rbxassetid://225469345', 'rbxassetid://225469349', 'rbxassetid://225469359', 'rbxassetid://225469364', 'rbxassetid://225469372', 'rbxassetid://225469380' },
                ColdWinterness    = { 'rbxassetid://7123754562', 'rbxassetid://7123756028', 'rbxassetid://7123757422', 'rbxassetid://7123758897', 'rbxassetid://7123760563', 'rbxassetid://7123762364' },
                Crimson           = { 'rbxassetid://15832429892', 'rbxassetid://15832430998', 'rbxassetid://15832430210', 'rbxassetid://15832430671', 'rbxassetid://15832431198', 'rbxassetid://15832429401' },
                Default           = { 'rbxassetid://6444884337', 'rbxassetid://6444884785', 'rbxassetid://6444884337', 'rbxassetid://6444884337', 'rbxassetid://6444884337', 'rbxassetid://6412503613' },
                Desert            = { 'rbxassetid://161319957', 'rbxassetid://161319965', 'rbxassetid://161319970', 'rbxassetid://161319983', 'rbxassetid://161319989', 'rbxassetid://161319996' },
                EarthSpace        = { 'rbxassetid://15753305495', 'rbxassetid://15753362674', 'rbxassetid://15753305823', 'rbxassetid://15753310707', 'rbxassetid://15753304774', 'rbxassetid://15753304473' },
                FadeNight         = { 'rbxassetid://16888843486', 'rbxassetid://16888845693', 'rbxassetid://16888848245', 'rbxassetid://16888850949', 'rbxassetid://16888854243', 'rbxassetid://16888857144' },
                Forest            = { 'rbxassetid://70945545', 'rbxassetid://70945449', 'rbxassetid://70945487', 'rbxassetid://70945523', 'rbxassetid://70945508', 'rbxassetid://70945531' },
                GreenAurora       = { 'rbxassetid://16563478983', 'rbxassetid://16563481302', 'rbxassetid://16563484084', 'rbxassetid://16563485362', 'rbxassetid://16563487078', 'rbxassetid://16563489821' },
                GreenCloudy       = { 'rbxassetid://921882045', 'rbxassetid://921881907', 'rbxassetid://921882121', 'rbxassetid://921881811', 'rbxassetid://921881989', 'rbxassetid://921882259' },
                GreenNebula       = { 'rbxassetid://47974894', 'rbxassetid://47974690', 'rbxassetid://47974821', 'rbxassetid://47974776', 'rbxassetid://47974859', 'rbxassetid://47974909' },
                GreenSpace        = { 'rbxassetid://159248188', 'rbxassetid://159248183', 'rbxassetid://159248187', 'rbxassetid://159248173', 'rbxassetid://159248192', 'rbxassetid://159248176' },
                HellSky           = { 'rbxassetid://437430787', 'rbxassetid://437430804', 'rbxassetid://437430543', 'rbxassetid://437430732', 'rbxassetid://437430747', 'rbxassetid://437430771' },
                Island            = { 'rbxassetid://319343577', 'rbxassetid://319343653', 'rbxassetid://319343666', 'rbxassetid://319343686', 'rbxassetid://319343631', 'rbxassetid://319343614' },
                LargeForest       = { 'rbxassetid://17428978603', 'rbxassetid://17428977445', 'rbxassetid://17428977114', 'rbxassetid://17428978399', 'rbxassetid://17428976828', 'rbxassetid://17428976669' },
                Minecraft         = { 'rbxassetid://1876545003', 'rbxassetid://1876544331', 'rbxassetid://1876542941', 'rbxassetid://1876543392', 'rbxassetid://1876543764', 'rbxassetid://1876544642' },
                MinecraftSky      = { 'rbxassetid://8735166756', 'rbxassetid://8735166707', 'rbxassetid://8735231668', 'rbxassetid://8735166755', 'rbxassetid://8735166751', 'rbxassetid://8735166729' },
                Mountains         = { 'rbxassetid://324014980', 'rbxassetid://324015477', 'rbxassetid://324014995', 'rbxassetid://324014679', 'rbxassetid://324015013', 'rbxassetid://324015409' },
                Night             = { 'rbxassetid://48020371', 'rbxassetid://48020144', 'rbxassetid://48020234', 'rbxassetid://48020211', 'rbxassetid://48020254', 'rbxassetid://48020383' },
                Oblivion          = { 'rbxassetid://7123654189', 'rbxassetid://7123657455', 'rbxassetid://7123662047', 'rbxassetid://7123664533', 'rbxassetid://7123666598', 'rbxassetid://7123668994' },
                Office            = { 'rbxassetid://658623433', 'rbxassetid://316342560', 'rbxassetid://658625205', 'rbxassetid://658627155', 'rbxassetid://658628504', 'rbxassetid://658632701' },
                Omori             = { 'rbxassetid://8767416629', 'rbxassetid://8767416629', 'rbxassetid://8767416629', 'rbxassetid://8767416629', 'rbxassetid://8767416629', 'rbxassetid://8767416629' },
                OrangeFog         = { 'rbxassetid://458016711', 'rbxassetid://458016826', 'rbxassetid://458016532', 'rbxassetid://458016655', 'rbxassetid://458016782', 'rbxassetid://458016792' },
                OrangeGradient    = { 'rbxassetid://6902754982', 'rbxassetid://6902795826', 'rbxassetid://6902754982', 'rbxassetid://6902754982', 'rbxassetid://6902754982', 'rbxassetid://6902796078' },
                PinkDay           = { 'rbxassetid://271042516', 'rbxassetid://271077243', 'rbxassetid://271042556', 'rbxassetid://271042310', 'rbxassetid://271042467', 'rbxassetid://271077958' },
                PinkGradient      = { 'rbxassetid://5371541816', 'rbxassetid://5371541154', 'rbxassetid://5371541816', 'rbxassetid://5371541816', 'rbxassetid://5371541816', 'rbxassetid://5371540604' },
                Poison            = { 'rbxassetid://1370716695', 'rbxassetid://1370716766', 'rbxassetid://1370716833', 'rbxassetid://1370716898', 'rbxassetid://1370716955', 'rbxassetid://1370717024' },
                PumpkinHill       = { 'rbxassetid://11202510597', 'rbxassetid://11202510255', 'rbxassetid://11202509993', 'rbxassetid://11202510806', 'rbxassetid://11202511066', 'rbxassetid://11202509704' },
                PurpleDay         = { 'rbxassetid://296908715', 'rbxassetid://296908724', 'rbxassetid://296908740', 'rbxassetid://296908755', 'rbxassetid://296908764', 'rbxassetid://296908769' },
                PurpleDayClear    = { 'rbxassetid://6847607535', 'rbxassetid://6847607977', 'rbxassetid://6847608302', 'rbxassetid://6847608608', 'rbxassetid://6847608986', 'rbxassetid://6847609323' },
                PurpleFog         = { 'rbxassetid://17279854976', 'rbxassetid://17279856318', 'rbxassetid://17279858447', 'rbxassetid://17279860360', 'rbxassetid://17279862234', 'rbxassetid://17279864507' },
                PurpleNight       = { 'rbxassetid://5084575798', 'rbxassetid://5084575916', 'rbxassetid://5103949679', 'rbxassetid://5103948542', 'rbxassetid://5103948784', 'rbxassetid://5084576400' },
                PurpleSplash      = { 'rbxassetid://8539982183', 'rbxassetid://8539981943', 'rbxassetid://8539981721', 'rbxassetid://8539981424', 'rbxassetid://8539980766', 'rbxassetid://8539981085' },
                RedNight          = { 'rbxassetid://401664839', 'rbxassetid://401664862', 'rbxassetid://401664960', 'rbxassetid://401664881', 'rbxassetid://401664901', 'rbxassetid://401664936' },
                Snowy             = { 'rbxassetid://155657655', 'rbxassetid://155674246', 'rbxassetid://155657609', 'rbxassetid://155657671', 'rbxassetid://155657619', 'rbxassetid://155674931' },
                SnowyMountains    = { 'rbxassetid://368385273', 'rbxassetid://48015300', 'rbxassetid://368388290', 'rbxassetid://368390615', 'rbxassetid://368385190', 'rbxassetid://48015387' },
                SnowyPlains       = { 'rbxassetid://155657655', 'rbxassetid://155674246', 'rbxassetid://155657609', 'rbxassetid://155657671', 'rbxassetid://155657619', 'rbxassetid://155674931' },
                Space             = { 'rbxassetid://149397692', 'rbxassetid://149397686', 'rbxassetid://149397697', 'rbxassetid://149397684', 'rbxassetid://149397688', 'rbxassetid://149397702' },
                Spongebob         = { 'rbxassetid://10287764626', 'rbxassetid://10287766382', 'rbxassetid://10287764626', 'rbxassetid://10287763421', 'rbxassetid://10287764626', 'rbxassetid://10287767597' },
                Spongebob2        = { 'rbxassetid://12049872454', 'rbxassetid://12049872284', 'rbxassetid://12049872181', 'rbxassetid://12049872074', 'rbxassetid://12049871884', 'rbxassetid://12049871774' },
                StarryNight       = { 'rbxassetid://8291078911', 'rbxassetid://8291077403', 'rbxassetid://8291081613', 'rbxassetid://8291074004', 'rbxassetid://8291080353', 'rbxassetid://8291075054' },
                SummerDay         = { 'rbxassetid://135483466', 'rbxassetid://135483484', 'rbxassetid://135483461', 'rbxassetid://135483495', 'rbxassetid://135483499', 'rbxassetid://135483475' },
                Sunset            = { 'rbxassetid://150939022', 'rbxassetid://150939038', 'rbxassetid://150939047', 'rbxassetid://150939056', 'rbxassetid://150939063', 'rbxassetid://150939082' },
                Trollge           = { 'rbxassetid://6155393905', 'rbxassetid://6155393905', 'rbxassetid://6155393905', 'rbxassetid://6155393905', 'rbxassetid://6155393905', 'rbxassetid://6155393905' },
                Underwater        = { 'rbxassetid://227635868', 'rbxassetid://227635921', 'rbxassetid://227635954', 'rbxassetid://227635974', 'rbxassetid://227635990', 'rbxassetid://227636031' },
                VibeMorning       = { 'rbxassetid://1417494030', 'rbxassetid://1417494146', 'rbxassetid://1417494253', 'rbxassetid://1417494402', 'rbxassetid://1417494499', 'rbxassetid://1417494643' },
                VibeNight         = { 'rbxassetid://5084575798', 'rbxassetid://5084575916', 'rbxassetid://5103949679', 'rbxassetid://5103948542', 'rbxassetid://5103948784', 'rbxassetid://5084576400' },
                WallsOfAutumn     = { 'rbxassetid://7123244709', 'rbxassetid://7123246497', 'rbxassetid://7123255895', 'rbxassetid://7123257992', 'rbxassetid://7123279103', 'rbxassetid://7123281828' },
                YellowDay         = { 'rbxassetid://2651432901', 'rbxassetid://2651434974', 'rbxassetid://2651435990', 'rbxassetid://2651436494', 'rbxassetid://2651436979', 'rbxassetid://2651437350' },
                YellowGradient    = { 'rbxassetid://159005370', 'rbxassetid://858422412', 'rbxassetid://159005370', 'rbxassetid://159005370', 'rbxassetid://159005370', 'rbxassetid://159006363' },
                c00lkidd          = { 'rbxassetid://433381097', 'rbxassetid://433381097', 'rbxassetid://433381097', 'rbxassetid://433381097', 'rbxassetid://433381097', 'rbxassetid://433381097' },
            }
            getgenv().SkyPresets = SKY_PRESETS

            local SKY_PRESET_NAMES = { 'realistic' }
            for name in pairs(SKY_PRESETS) do table.insert(SKY_PRESET_NAMES, name) end
            table.sort(SKY_PRESET_NAMES, function(a, b)
                if a == 'realistic' then return true end
                if b == 'realistic' then return false end
                return a:lower() < b:lower()
            end)
            getgenv().SkyPresetNames = SKY_PRESET_NAMES

            local function applySkyboxPreset(sky, preset)
                if not sky then return end
                preset = preset or (ovw('WorldSkyboxType') or 'realistic')

                if preset == 'realistic' then
                    sky.MoonTextureId = 'rbxasset://sky/moon.jpg'
                    sky.SkyboxBk = 'rbxassetid://15502511288'
                    sky.SkyboxDn = 'rbxassetid://15502508460'
                    sky.SkyboxFt = 'rbxassetid://15502510289'
                    sky.SkyboxLf = 'rbxassetid://15502507918'
                    sky.SkyboxRt = 'rbxassetid://15502509398'
                    sky.SkyboxUp = 'rbxassetid://15502511911'
                    sky.StarCount = 3000
                    sky.CelestialBodiesShown = true
                    return
                end

                local data = SKY_PRESETS[preset]
                if not data then return end
                sky.SkyboxBk = data[1]
                sky.SkyboxDn = data[2]
                sky.SkyboxFt = data[3]
                sky.SkyboxLf = data[4]
                sky.SkyboxRt = data[5]
                sky.SkyboxUp = data[6]
                sky.CelestialBodiesShown = true
            end
            WorldGb:AddToggle('WorldSkybox', {
                Text = 'Skybox', Default = false,
                Callback = function(v)
                    if v then
                        local existing = Lighting:FindFirstChildOfClass('Sky')
                        if existing and existing ~= getgenv().LarpticSky then
                            -- hang on to the game's own sky so switching this off restores it
                            getgenv().LarpticOriginalSky = existing
                            pcall(function() existing.Parent = nil end)
                        end
                        local sky = getgenv().LarpticSky
                        if not (sky and sky.Parent) then
                            sky = Instance.new('Sky')
                            sky.Name = 'LarpticSky'
                            applySkyboxPreset(sky)
                            sky.Parent = Lighting
                            getgenv().LarpticSky = sky
                        else
                            applySkyboxPreset(sky)
                            sky.Parent = Lighting
                        end
                    else
                        if getgenv().LarpticSky then pcall(function() getgenv().LarpticSky.Parent = nil end) end
                        local original = getgenv().LarpticOriginalSky
                        if original then
                            pcall(function() original.Parent = Lighting end)
                            getgenv().LarpticOriginalSky = nil
                        end
                    end
                end,
            })
            WorldGb:AddDropdown('WorldSkyboxType', {
                Text = 'Sky',
                Values = SKY_PRESET_NAMES,
                Default = 1,
                Callback = function(v)
                    if tvw('WorldSkybox') and getgenv().LarpticSky then
                        applySkyboxPreset(getgenv().LarpticSky, v)
                    end
                end,
            })
        end

local danceTrack
local lagConnection

local function validCharacter(c)
    local h = c and c:FindFirstChildOfClass("Humanoid")
    return h and h.Health > 0 and c:FindFirstChild("HumanoidRootPart")
end

local function loadDance()
    local c = LocalPlayer.Character
    if not validCharacter(c) or settings.CurrentDanceId == "" then return end
    local h = c:FindFirstChildOfClass("Humanoid")
    local animator = h:FindFirstChildOfClass("Animator") or Instance.new("Animator", h)
    if danceTrack then danceTrack:Stop() ; danceTrack:Destroy() end
    local a = Instance.new("Animation")
    a.AnimationId = settings.CurrentDanceId
    danceTrack = animator:LoadAnimation(a)
    danceTrack.Priority = Enum.AnimationPriority.Action
end

local function playDance()
    if settings.DanceEnabled and danceTrack then
        pcall(function()
            if not danceTrack.IsPlaying then
                danceTrack:Play()
            end
            if not settings.LagAnimations then
                danceTrack:AdjustSpeed(settings.EmoteSpeed or 1)
            end
        end)
    end
end

local function stopLag()
    if lagConnection then lagConnection:Disconnect() ; lagConnection = nil end
    if danceTrack then pcall(function() danceTrack:AdjustSpeed(settings.EmoteSpeed or 1) end) end
end

local function startUltraLag()
    stopLag()
    local accumulator = 0
    local updateRate = math.clamp(20 - settings.LagIntensity * 6, 4, 20)
    lagConnection = RunService.RenderStepped:Connect(function(dt)
        if not settings.LagAnimations or not danceTrack or not danceTrack.IsPlaying then
            stopLag()
            return
        end
        accumulator += dt
        if accumulator < (1 / updateRate) then return end
        accumulator = 0
        if math.random() < (0.35 * settings.LagIntensity) then return end
        local r = math.random()
        if r < 0.35 * settings.LagIntensity then
            danceTrack:AdjustSpeed(0)
        elseif r < 0.5 * settings.LagIntensity then
            danceTrack:AdjustSpeed(-math.random(2,6))
        else
            danceTrack:AdjustSpeed(math.random(1,8))
        end
    end)
end

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    if settings.DanceEnabled then
        task.spawn(function()
            task.wait(0.1)
            loadDance()
            playDance()
            if settings.LagAnimations and danceTrack then startUltraLag() end
        end)
    end
end)

if LocalPlayer.Character and validCharacter(LocalPlayer.Character) then
    task.spawn(function()
        task.wait(1)
        loadDance()
        playDance()
        if settings.LagAnimations and danceTrack then startUltraLag() end
    end)
end

local nameList = {"None"}
for _, user in ipairs(users) do table.insert(nameList, user.UserName) end

Avatar:AddDropdown('Char', {
    Default = 'None',
    Values = nameList,
    Callback = function(selected)
        settings.SelectedUserName = selected
        settings.SelectedUserId = nil
        if selected ~= "None" then
            for _, user in pairs(users) do
                if user.UserName == selected then Morph(user.UserId, LocalPlayer.Name) ; break end
            end
        else
            Morph(LocalPlayer.UserId, LocalPlayer.Name)
        end
    end
})

Avatar:AddToggle('HeadlessToggle', {
    Text = 'Toggle Headless',
    Default = settings.HasHeadless,
    Callback = function(state)
        settings.HasHeadless = state
        if LocalPlayer.Character then
            if state then ApplyHeadless(LocalPlayer.Character) else RemoveHeadless(LocalPlayer.Character) end
        end
    end
})

Avatar:AddToggle('KorbloxToggle', {
    Text = 'Toggle Korblox',
    Default = settings.HasKorblox,
    Callback = function(state)
        settings.HasKorblox = state
        if LocalPlayer.Character then
            if state then ApplyKorblox(LocalPlayer.Character) else RemoveKorblox(LocalPlayer.Character) end
        end
    end
})

Avatar:AddToggle('ChamsToggle', {
    Text = 'Toggle Chams',
    Default = settings.HasChams,
    Callback = function(state)
        settings.HasChams = state
        if LocalPlayer.Character then
            if state then ApplyChams(LocalPlayer.Character) else RemoveChams(LocalPlayer.Character) end
        end
    end
}):AddColorPicker('ChamsColor', {
    Default = ACCENT,
    Callback = function(color)
        settings.ChamsColor = color
        if settings.HasChams and LocalPlayer.Character then
            ApplyChams(LocalPlayer.Character)
        end
    end
})

Avatar:AddToggle('RemoveAccessories', {
    Text = 'Remove Accessories',
    Default = false,
    Callback = function()
        local char = LocalPlayer.Character
        if not char then return end
        for _, v in pairs(char:GetChildren()) do
            if v:IsA("Accessory") then v:Destroy() end
        end
    end
})

Avatar:AddInput('CustomAccessory', {
    Text = 'Add Accessory by ID',
    Default = '',
    Numeric = false,
    Finished = false,
    Callback = function(idText)
        local char = LocalPlayer.Character
        if not char then return end
        local id = idText:match("%d+")
        if not id then return end

        local function findAttachment(rootPart, name)
            for _, descendant in pairs(rootPart:GetDescendants()) do
                if descendant:IsA("Attachment") and descendant.Name == name then
                    return descendant
                end
            end
        end

        local function weldParts(part0, part1, c0, c1)
            local weld = Instance.new("Weld")
            weld.Part0 = part0
            weld.Part1 = part1
            weld.C0 = c0
            weld.C1 = c1 or CFrame.new()
            weld.Parent = part0
            return weld
        end

        local success, objects = pcall(function()
            return game:GetObjects("rbxassetid://" .. id)
        end)
        if not success or not objects or not objects[1] then
            print("Failed to load asset: " .. tostring(id))
            return
        end

        local accessory = objects[1]
        accessory.Parent = workspace

        local handle = accessory:FindFirstChild("Handle")
        if not handle then
            accessory:Destroy()
            print("No Handle found in asset: " .. tostring(id))
            return
        end

        local attachment = handle:FindFirstChildOfClass("Attachment")
        local parentPart = char:FindFirstChild("Head")
            or char:FindFirstChild("UpperTorso")
            or char:FindFirstChild("Torso")

        if attachment and parentPart then
            local parentAttachment = findAttachment(parentPart, attachment.Name)
            if parentAttachment then
                weldParts(parentPart, handle, parentAttachment.CFrame, attachment.CFrame)
            else
                weldParts(parentPart, handle, CFrame.new(0, 0.5, 0), CFrame.new())
            end
        elseif parentPart then
            weldParts(parentPart, handle, CFrame.new(0, 0.5, 0), CFrame.new())
        end

        accessory.Parent = char
    end
})

Avatar:AddToggle("EnableDance", {
    Text = "Enable Emote",
    Default = false,
    Callback = function(v)
        settings.DanceEnabled = v
        if v then
            loadDance()
            playDance()
            if settings.LagAnimations and danceTrack then startUltraLag() end
        else
            if danceTrack then danceTrack:Stop() end
            stopLag()
        end
    end
})

local danceNames = {}
for name in pairs(danceAnimations) do
    table.insert(danceNames, name)
end

Avatar:AddDropdown("SelectDance", {
    Text = "Select Emote",
    Values = danceNames,
    Default = "None",
    Callback = function(v)
        settings.CurrentDanceName = v
        settings.CurrentDanceId = danceAnimations[v]
        if settings.DanceEnabled then
            loadDance()
            playDance()
            if settings.LagAnimations and danceTrack then startUltraLag() end
        end
    end
})

Avatar:AddSlider("EmoteSpeed", {
    Text = "Emote Speed",
    Default = 1,
    Min = 0,
    Max = 10,
    Rounding = 1,
    Callback = function(v)
        settings.EmoteSpeed = v
        if settings.DanceEnabled and danceTrack and not settings.LagAnimations then
            pcall(function() danceTrack:AdjustSpeed(v) end)
        end
    end
})

Avatar:AddToggle("LagAnimations", {
    Text = "Lag Animations",
    Default = false,
    Callback = function(v)
        settings.LagAnimations = v
        if v and danceTrack then
            startUltraLag()
        else
            stopLag()
            if settings.DanceEnabled then playDance() end
        end
    end
})

Avatar:AddSlider("LagIntensity", {
    Text = "Lag Intensity",
    Default = 1,
    Min = 0,
    Max = 3,
    Rounding = 1,
    Callback = function(v)
        settings.LagIntensity = v
    end
})

local StarterGui = game:GetService("StarterGui")
StarterGui:SetCore("ResetButtonCallback", true)

local TextChatService = game:GetService("TextChatService")
local chatConfig = TextChatService.ChatWindowConfiguration

local players = game:GetService("Players")
local runservice = game:GetService("RunService")
local lp = players.LocalPlayer

local g = getgenv()
g.flashback = g.flashback or {}

if g.flashback.conn then
    pcall(function() g.flashback.conn:Disconnect() end)
    g.flashback.conn = nil
end

g.flashback.settings = {
    enabled = false
}

local lastcf

local function gethrp()
    local char = lp.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

g.flashback.conn = runservice.Heartbeat:Connect(function()
    if not g.flashback.settings.enabled then return end
    local char = lp.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return end

    if hum.Health <= 10 and not lastcf then
        lastcf = hrp.CFrame
    elseif hum.Health > 10 and lastcf then
        hrp.CFrame = lastcf + Vector3.new(math.sin(tick()) * 0.001, 0, math.cos(tick()) * 0.001)
        lastcf = nil
    end
end)

local groupId = 339846382

local function isStaff(player)
    if not player or not player:IsInGroup(groupId) then return false end
    local role = player:GetRoleInGroup(groupId)
    return role and role ~= "" and role ~= "Guest"
end

local function sendNotification(message)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "Staff Alert",
            Text = message,
            Duration = 6,
            Icon = "rbxassetid://6031075938"
        })
    end)
end

local function handleStaffJoin(staffPlayer)
    if not getgenv().AntiStaffSettings.Enabled then return end
    local action = getgenv().AntiStaffSettings.Action
    if action == "Notify" or action == "Both" then
        sendNotification("Staff detected: " .. staffPlayer.DisplayName .. " (@" .. staffPlayer.Name .. ")")
    end
    if action == "Kick" or action == "Both" then
        task.wait(3)
        LocalPlayer:Kick("\nStaff member joined the game:\n" .. staffPlayer.DisplayName .. " (@" .. staffPlayer.Name .. ")\n\nYou were automatically disconnected for safety.")
    end
end

task.spawn(function()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and isStaff(player) then handleStaffJoin(player) end
    end
end)

Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer and isStaff(player) then handleStaffJoin(player) end
end)
getgenv().FlyCore = nil
getgenv().FlyBV = nil
getgenv().FlyBG = nil
getgenv().FlyConn = nil

getgenv().StartFly = function()
    if getgenv().Misc.Flying then return end
    local char = getgenv().LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    getgenv().Misc.Flying = true
    if workspace:FindFirstChild("FlyCore") then workspace.FlyCore:Destroy() end
    getgenv().FlyCore = Instance.new("Part")
    getgenv().FlyCore.Name = "FlyCore"; getgenv().FlyCore.Size = Vector3.new(0.05,0.05,0.05)
    getgenv().FlyCore.Transparency = 1; getgenv().FlyCore.CanCollide = false; getgenv().FlyCore.Parent = workspace
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = getgenv().FlyCore; weld.Part1 = char.HumanoidRootPart; weld.Parent = getgenv().FlyCore
    getgenv().FlyBV = Instance.new("BodyVelocity")
    getgenv().FlyBV.MaxForce = Vector3.new(400000,400000,400000); getgenv().FlyBV.P = 9000
    getgenv().FlyBV.Velocity = Vector3.zero; getgenv().FlyBV.Parent = getgenv().FlyCore
    getgenv().FlyBG = Instance.new("BodyGyro")
    getgenv().FlyBG.MaxTorque = Vector3.new(400000,400000,400000); getgenv().FlyBG.P = 15000
    getgenv().FlyBG.D = 1000; getgenv().FlyBG.CFrame = getgenv().FlyCore.CFrame; getgenv().FlyBG.Parent = getgenv().FlyCore
    if getgenv().FlyConn then getgenv().FlyConn:Disconnect() end
    getgenv().FlyConn = getgenv().RunService.RenderStepped:Connect(function()
        if not getgenv().Misc.Flying or not getgenv().FlyBV or not getgenv().FlyBG then return end
        local cam = workspace.CurrentCamera
        local move = Vector3.zero
        if getgenv().UserInputService:IsKeyDown(Enum.KeyCode.W) then move += cam.CFrame.LookVector end
        if getgenv().UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= cam.CFrame.LookVector end
        if getgenv().UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= cam.CFrame.RightVector end
        if getgenv().UserInputService:IsKeyDown(Enum.KeyCode.D) then move += cam.CFrame.RightVector end
        if getgenv().UserInputService:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0,1,0) end
        if getgenv().UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move -= Vector3.new(0,1,0) end
        if move.Magnitude > 0 then move = move.Unit end
        getgenv().FlyBV.Velocity = move * getgenv().Misc.FlySpeed
        getgenv().FlyBG.CFrame = cam.CFrame
    end)
end

getgenv().StopFly = function()
    if not getgenv().Misc.Flying then return end
    getgenv().Misc.Flying = false
    if getgenv().FlyConn then getgenv().FlyConn:Disconnect(); getgenv().FlyConn = nil end
    if getgenv().FlyBV then getgenv().FlyBV:Destroy(); getgenv().FlyBV = nil end
    if getgenv().FlyBG then getgenv().FlyBG:Destroy(); getgenv().FlyBG = nil end
    if getgenv().FlyCore and getgenv().FlyCore.Parent then getgenv().FlyCore:Destroy(); getgenv().FlyCore = nil end
end

getgenv().UpdateNotifPosition(Options.NotifPos.Value)




task.spawn(function()
    while task.wait(0.1) do
        local now = tick()
        
        local char = getgenv().LocalPlayer.Character
        local hum = char and char:FindFirstChildWhichIsA("Humanoid")
        
        if hum then
            if lastLocalHealthForAutoVoid == nil then
                lastLocalHealthForAutoVoid = hum.Health
            else
                local autoVoidEnabled = false
                if Toggles and Toggles.AutoVoidOnHit then
                    autoVoidEnabled = Toggles.AutoVoidOnHit.Value
                end
                
                if hum.Health < lastLocalHealthForAutoVoid and autoVoidEnabled then
                    if Toggles and Toggles.CSyncEnabled and not Toggles.CSyncEnabled.Value then
                        hitAutoVoidOwnedSync = true
                        Toggles.CSyncEnabled:SetValue(true)
                    end
                    
                    if Options and Options.CSyncType then
                        Options.CSyncType:SetValue("Void")
                    end
                    
                    local duration = 2
                    if Options and Options.AutoVoidOnHitDuration then
                        duration = Options.AutoVoidOnHitDuration.Value
                    end
                    
                    hitAutoVoidActiveUntil = now + duration
                    
                    task.delay(duration, function()
                        if tick() >= hitAutoVoidActiveUntil then
                            if hitAutoVoidOwnedSync then
                                if Toggles and Toggles.CSyncEnabled then
                                    Toggles.CSyncEnabled:SetValue(false)
                                end
                                hitAutoVoidOwnedSync = false
                            end
                        end
                    end)
                end
                lastLocalHealthForAutoVoid = hum.Health
            end
        end
    end
end)


getgenv().RunService.RenderStepped:Connect(function()
    if not getgenv().Config or not getgenv().Config.Visual then return end

    local cfg = getgenv().Config.Visual
    local fov = cfg.FOV
    local mousePos = getgenv().UserInputService:GetMouseLocation()
    local centerPos = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize/2 or Vector2.new(0, 0)
    local targetPos = (fov and fov.FollowCursor == false) and centerPos or Vector2.new(mousePos.X, mousePos.Y)
    local tNow = tick()

    if fov and fov.Enabled then
        if not fov.InnerCircle or not fov.ScreenGui then createFOV() end

        local radius = fov.Size or 300
        if fov.PulseEnabled then
            radius = radius + (math.sin(tNow * (fov.PulseSpeed or 2)) * (fov.PulseAmount or 20))
        end
        radius = math.max(1, radius)
        local shape = fov.Shape or 'Circle'

        if fov.ScreenGui then
            fov.ScreenGui.Enabled = false
        end

        local isCircle = (shape == 'Circle')
        local isSquare = (shape == 'Square')
        local isHexagon = (shape == 'Hexagon')
        local isTriangle = (shape == 'Triangle')

        local drawVisible = true
        local fillVisible = fov.Filled == true

        if fov.InnerCircle then
            fov.InnerCircle.Visible = drawVisible and isCircle
            if fov.InnerCircle.Visible then
                fov.InnerCircle.Position = targetPos
                fov.InnerCircle.Radius = radius
                fov.InnerCircle.Color = fov.InnerColor or Color3.new(1,1,1)
                fov.InnerCircle.Transparency = 1
                fov.InnerCircle.Thickness = 1
                fov.InnerCircle.Filled = false
            end

            if fov.OuterCircle then
                fov.OuterCircle.Visible = drawVisible and isCircle
                if fov.OuterCircle.Visible then
                    fov.OuterCircle.Position = targetPos
                    fov.OuterCircle.Radius = radius + 1
                    fov.OuterCircle.Color = fov.OuterColor or Color3.new(0,0,0)
                    fov.OuterCircle.Transparency = 1
                    fov.OuterCircle.Thickness = 1
                    fov.OuterCircle.Filled = false
                end
            end
            if fov.FillCircle then
                fov.FillCircle.Visible = fillVisible and isCircle
                if fov.FillCircle.Visible then
                    fov.FillCircle.Position = targetPos
                    fov.FillCircle.Radius = radius
                    fov.FillCircle.Color = fov.FillColor or fov.InnerColor or Color3.new(1, 1, 1)
                    fov.FillCircle.Transparency = 0.1
                    fov.FillCircle.Thickness = 1
                    fov.FillCircle.Filled = true
                end
            end

            local points, outerPoints
            local function getPolygonPointsCached(sides, offset)
                local p = {}
                local angleStep = (math.pi * 2) / sides
                local baseRotation = (shape == 'Triangle' and -math.pi/2 or (shape == 'Square' and math.pi/4 or 0))
                local currentRotation = math.rad(fov.Rotation or 0)
                local totalRotation = baseRotation + currentRotation

                for i = 1, sides do
                    local angle = (i * angleStep) + totalRotation
                    p[i] = targetPos + Vector2.new(math.cos(angle) * (radius + offset), math.sin(angle) * (radius + offset))
                end
                return p
            end

            if fov.Lines then
                local visible = drawVisible and (not isCircle)
                local sides = (isSquare and 4 or (isHexagon and 6 or (isTriangle and 3 or 0)))
                
                if visible then
                    points = getPolygonPointsCached(sides, 0)
                    outerPoints = getPolygonPointsCached(sides, 1)
                end

                for i = 1, 12 do
                    local line = fov.Lines[i]
                    if not line then continue end
                    if i <= sides and visible then
                        local nextIdx = (i % sides) + 1
                        line.Visible = true
                        line.From = points[i]
                        line.To = points[nextIdx]
                        line.Color = fov.InnerColor or Color3.new(1,1,1)
                        line.Thickness = 1
                        line.Transparency = 1
                    elseif i > sides and i <= sides * 2 and visible then
                        local realIdx = i - sides
                        local nextIdx = (realIdx % sides) + 1
                        line.Visible = true
                        line.From = outerPoints[realIdx]
                        line.To = outerPoints[nextIdx]
                        line.Color = fov.OuterColor or Color3.new(0,0,0)
                        line.Thickness = 1
                        line.Transparency = 1
                    else
                        line.Visible = false
                    end
                end
            end

            if fov.Triangles then
                local visible = fillVisible and (not isCircle)
                local sides = (isSquare and 4 or (isHexagon and 6 or (isTriangle and 3 or 0)))
                
                if visible and not points then
                    points = getPolygonPointsCached(sides, 0)
                end

                for i = 1, 6 do
                    local tri = fov.Triangles[i]
                    if not tri then continue end
                    if i <= sides and visible then
                        local nextIdx = (i % sides) + 1
                        tri.Visible = true
                        tri.PointA = targetPos
                        tri.PointB = points[i]
                        tri.PointC = points[nextIdx]
                        tri.Color = fov.FillColor or fov.InnerColor or Color3.new(1,1,1)
                        tri.Transparency = 0.1
                        tri.Filled = true
                    else
                        tri.Visible = false
                    end
                end
            end
        end
    else
        if fov then
            if fov.InnerCircle then fov.InnerCircle.Visible = false end
            if fov.OuterCircle then fov.OuterCircle.Visible = false end
            if fov.FillCircle then fov.FillCircle.Visible = false end
            if fov.Lines then for _, l in ipairs(fov.Lines) do l.Visible = false end end
            if fov.Triangles then for _, t in ipairs(fov.Triangles) do t.Visible = false end end
        end
    end
end)

getgenv().WatermarkConnection = getgenv().RunService.Heartbeat:Connect(function() getgenv().FrameCounter = getgenv().FrameCounter + 1 end)
task.spawn(function()
    while task.wait(1) do
        getgenv().FPS = getgenv().FrameCounter
        getgenv().FrameCounter = 0
        local ping = "0"
        pcall(function() ping = getgenv().Stats.Network.ServerStatsItem["Data Ping"]:GetValueString() end)
        local executorName = (identifyexecutor and identifyexecutor()) or (getexecutorname and getexecutorname()) or "Unknown"
        getgenv().Library:SetWatermark(string.format('$$ lunar.lua | %s | %d fps | %s ms | players: %d/%d', executorName, getgenv().FPS, ping, #getgenv().Players:GetPlayers(), getgenv().Players.MaxPlayers))    end
end)

pcall(function()
    getgenv().Library:SetWatermarkVisibility(true)
    if getgenv().Library.KeybindFrame then
        getgenv().Library.KeybindFrame.Visible = getgenv().ForceDefaultHudVisible == true
    end
end)

getgenv().Library:OnUnload(function()
    if getgenv().WatermarkConnection then getgenv().WatermarkConnection:Disconnect() end
    if getgenv().TargetHealthConnection then getgenv().TargetHealthConnection:Disconnect() end
    if getgenv().TargetCleanupConnection then getgenv().TargetCleanupConnection:Disconnect() end
    if getgenv().LarpticFOV then
        if getgenv().LarpticFOV.Inner then getgenv().LarpticFOV.Inner:Remove() end
        if getgenv().LarpticFOV.Outer then getgenv().LarpticFOV.Outer:Remove() end
        if getgenv().LarpticFOV.ScreenGui then getgenv().LarpticFOV.ScreenGui:Destroy() end
    end
    if getgenv().TracerLine then getgenv().TracerLine:Remove() end
    if getgenv().TracerOutline then getgenv().TracerOutline:Remove() end
    if getgenv().TracerLine2 then getgenv().TracerLine2:Remove() end
    if getgenv().TracerOutline2 then getgenv().TracerOutline2:Remove() end
    if getgenv().HitNotifGui then getgenv().HitNotifGui:Destroy() end
    if getgenv().StrafeConnection then getgenv().StrafeConnection:Disconnect() end
    if getgenv().SpectateConnection then getgenv().SpectateConnection:Disconnect() end
    if getgenv().ESPConnection then getgenv().ESPConnection:Disconnect() end
    if getgenv().ESPCleanup then getgenv().ESPCleanup() end
    if getgenv().DickESPCleanup then getgenv().DickESPCleanup() end
    if getgenv().LegitAimConnection then getgenv().LegitAimConnection:Disconnect() end
    if getgenv().LegitFovCircle then pcall(function() getgenv().LegitFovCircle:Remove() end) end
    if getgenv().KnifeGlueConn then getgenv().KnifeGlueConn:Disconnect() end
    if getgenv().AutoReloadConnection then getgenv().AutoReloadConnection:Disconnect() end
    if getgenv().CrosshairConnection then getgenv().CrosshairConnection:Disconnect() end
    if getgenv().CrosshairLines then
        for _, l in ipairs(getgenv().CrosshairLines) do pcall(function() l:Remove() end) end
    end
    if getgenv().HUDConnection then getgenv().HUDConnection:Disconnect() end
    if getgenv().TargetHUDGui then pcall(function() getgenv().TargetHUDGui:Destroy() end) end
    if getgenv().AmmoHUDGui then pcall(function() getgenv().AmmoHUDGui:Destroy() end) end
    pcall(function()
        local hum = getgenv().LocalPlayer.Character and getgenv().LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum and hum.RootPart and sethiddenproperty then sethiddenproperty(hum.RootPart, "PhysicsRepRootPart", nil) end
    end)
    getgenv().destroyStrafeVisualizer()
    getgenv().resetStrafeCamera()
    if getgenv().MobileAutoTargetConn then getgenv().MobileAutoTargetConn:Disconnect() end
    if getgenv().MobileGui then pcall(function() getgenv().MobileGui:Destroy() end) end
    getgenv().Library.Unloaded = true
end)

do
    local Camera = getgenv().Camera
    local Players = getgenv().Players
    local LocalPlayer = getgenv().LocalPlayer
    local UIS = getgenv().UserInputService
    local RunService = getgenv().RunService

    local LegitGb = getgenv().LegitGb
    LegitGb:AddToggle('LegitAimbot', { Text = 'Aimbot', Default = false })
        :AddKeyPicker('LegitAimbotKey', { Default = 'E', Mode = 'Toggle', Text = 'Aimbot', SyncToggleState = false, NoUI = false })
    LegitGb:AddToggle('LegitSilent', { Text = 'Silent', Default = false })
    LegitGb:AddToggle('LegitFov', { Text = 'fov', Default = false })
        :AddColorPicker('LegitFovColor', { Default = ACCENT, Title = 'FOV Color' })
    LegitGb:AddDropdown('LegitPart', { Text = 'Part', Default = 'Head', Values = { 'Head', 'UpperTorso', 'HumanoidRootPart', 'LowerTorso' } })
    LegitGb:AddSlider('LegitSmooth', { Text = 'Smooth', Default = 0.05, Min = 0, Max = 1, Rounding = 3 })
    LegitGb:AddSlider('LegitPred', { Text = 'Pred', Default = 0.155, Min = 0, Max = 1, Rounding = 3 })
    LegitGb:AddSlider('LegitRadius', { Text = 'Radius', Default = 100, Min = 10, Max = 800, Rounding = 0 })
    LegitGb:AddToggle('LegitWallCheck', { Text = 'Wall Check', Default = true })
    LegitGb:AddToggle('LegitSticky', { Text = 'Sticky (aimbot + silent)', Default = true })
    LegitGb:AddSlider('LegitHitChance', { Text = 'Hit chance (%)', Default = 100, Min = 1, Max = 100, Rounding = 0 })
    LegitGb:AddToggle('LegitUseAirPart', { Text = 'Use air part', Default = false })
    LegitGb:AddDropdown('LegitAirPart', { Text = 'Air part', Default = 'Head', Values = { 'Head', 'UpperTorso', 'HumanoidRootPart', 'LowerTorso' } })
    LegitGb:AddToggle('LegitAntiGround', { Text = 'Anti ground shots', Tooltip = 'skip targets well below your own height', Default = false })
    LegitGb:AddSlider('LegitAntiGroundValue', { Text = 'Anti ground height', Default = 5, Min = 0, Max = 40, Rounding = 0 })
    LegitGb:AddToggle('LegitResolver', { Text = 'Resolver', Default = false })
    LegitGb:AddSlider('LegitResolverTune', { Text = 'Resolver tune', Default = 0.13, Min = 0, Max = 1, Rounding = 3 })
    LegitGb:AddSlider('LegitShake', { Text = 'Shake', Default = 0, Min = 0, Max = 5, Rounding = 2 })
    LegitGb:AddToggle('LegitFriendly', { Text = 'Skip friends', Default = false })

    local function ov(n) local o = Options[n] ; return o and o.Value end
    local function tv(n) local t = Toggles[n] ; return t and t.Value end

    local function legitWallOk(part)
        if not tv('LegitWallCheck') then return true end
        if not part or not part.Parent then return false end
        local origin = Camera.CFrame.Position
        local rp = RaycastParams.new()
        rp.FilterType = Enum.RaycastFilterType.Blacklist
        local filter = { Camera }
        if LocalPlayer.Character then table.insert(filter, LocalPlayer.Character) end
        rp.FilterDescendantsInstances = filter
        local res = workspace:Raycast(origin, part.Position - origin, rp)
        if not res or not res.Instance then return true end
        return res.Instance:IsDescendantOf(part.Parent)
    end

    local function legitFriendly(plr)
        if not tv('LegitFriendly') then return false end
        local ok, isFriend = pcall(function() return LocalPlayer:IsFriendsWith(plr.UserId) end)
        return ok and isFriend == true
    end

    -- airborne targets are harder to hit with the ground part, so the source
    -- scripts let you nominate a separate part for them
    local function legitPart(plr)
        if not plr.Character then return nil end
        local partName = ov('LegitPart') or 'Head'
        if tv('LegitUseAirPart') then
            local hum = plr.Character:FindFirstChildOfClass('Humanoid')
            if hum and hum.FloorMaterial == Enum.Material.Air then
                partName = ov('LegitAirPart') or partName
            end
        end
        return plr.Character:FindFirstChild(partName)
    end

    local function legitAntiGroundOk(part)
        if not tv('LegitAntiGround') then return true end
        local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart')
        if not root then return true end
        return (part.Position.Y - root.Position.Y) >= -(ov('LegitAntiGroundValue') or 5)
    end

    local function legitHitChance()
        local chance = ov('LegitHitChance') or 100
        if chance >= 100 then return true end
        return math.random(1, 100) <= chance
    end

    -- resolver nudges the shot along the target's strafe axis to undo the desync
    -- offset, then shake scatters it so the shots do not look machine-perfect
    local function legitAimPosition(part)
        local pos = part.Position + part.AssemblyLinearVelocity * (ov('LegitPred') or 0)
        if tv('LegitResolver') then
            local body = part.Parent
            local larm = body and body:FindFirstChild('LeftUpperArm')
            local rarm = body and body:FindFirstChild('RightUpperArm')
            if larm and rarm then
                local tune = ov('LegitResolverTune') or 0.13
                pos = pos + (larm.AssemblyLinearVelocity - rarm.AssemblyLinearVelocity) * tune
            end
        end
        local shake = ov('LegitShake') or 0
        if shake > 0 then
            local function jitter() return (math.random() * 2 - 1) * shake end
            pos = pos + Vector3.new(jitter(), jitter(), jitter())
        end
        return pos
    end
    getgenv().LegitAimPosition = legitAimPosition

    local stickyTarget = nil
    local function legitClosest()
        if tv('LegitSticky') and stickyTarget and stickyTarget.Parent and stickyTarget.Character and not getgenv().isKO(stickyTarget) then
            local part = legitPart(stickyTarget)
            if part then
                local sp, vis = Camera:WorldToViewportPoint(part.Position)
                if vis and legitWallOk(part) and legitAntiGroundOk(part) then
                    return stickyTarget, part
                end
            end
        end

        local mouse = UIS:GetMouseLocation()
        local radius = ov('LegitRadius') or 100
        local shortest, closest, closestPart = radius, nil, nil
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character and not legitFriendly(plr) then
                local part = legitPart(plr)
                if part and not getgenv().isKO(plr) and legitAntiGroundOk(part) then
                    local sp, vis = Camera:WorldToViewportPoint(part.Position)
                    if vis then
                        local d = (Vector2.new(sp.X, sp.Y) - mouse).Magnitude
                        if d < shortest and legitWallOk(part) then
                            shortest, closest, closestPart = d, plr, part
                        end
                    end
                end
            end
        end
        stickyTarget = closest
        return closest, closestPart
    end
    getgenv().LegitClosest = legitClosest

    local fovCircle = Drawing.new("Circle")
    fovCircle.Thickness = 1; fovCircle.Filled = false; fovCircle.Transparency = 1
    fovCircle.Color = Color3.fromRGB(255, 255, 255); fovCircle.Visible = false
    pcall(function() fovCircle.NumSides = 64 end)
    getgenv().LegitFovCircle = fovCircle

    getgenv().LegitAimConnection = RunService.RenderStepped:Connect(function()
        if tv('LegitFov') then
            local m = UIS:GetMouseLocation()
            fovCircle.Visible = true
            fovCircle.Position = Vector2.new(m.X, m.Y)
            fovCircle.Radius = ov('LegitRadius') or 100
            fovCircle.Color = ov('LegitFovColor') or Color3.fromRGB(255, 255, 255)
        else
            fovCircle.Visible = false
        end

        if not tv('LegitAimbot') then return end
        local key = Options.LegitAimbotKey
        if not (key and key:GetState()) then return end

        if not legitHitChance() then return end
        local _, part = legitClosest()
        if not part then return end
        local aimPos = legitAimPosition(part)
        local desired = CFrame.lookAt(Camera.CFrame.Position, aimPos)
        local smooth = math.clamp(ov('LegitSmooth') or 0.05, 0, 1)
        local alpha = math.clamp(1 - smooth, 0.01, 1)
        Camera.CFrame = Camera.CFrame:Lerp(desired, alpha)
    end)

    local hooked = pcall(function()
        local mainEvent = getgenv().MainEvent
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            if tv('LegitSilent') and not checkcaller() then
                local method = getnamecallmethod and getnamecallmethod() or ""
                if self == mainEvent and method == "FireServer" and (...) == "Shoot" then
                    pcall(function(...)
                        local shootArgs = select(2, ...)
                        if not legitHitChance() then return end
                        local _, part = legitClosest()
                        if part and part.Parent and typeof(shootArgs) == "table" then
                            local pos = legitAimPosition(part)
                            if typeof(shootArgs[1]) == "table" then
                                for i = 1, 5 do
                                    if type(shootArgs[1][i]) == "table" then
                                        shootArgs[1][i].Instance = part
                                        shootArgs[1][i].Position = pos
                                        shootArgs[1][i].Normal = pos
                                    end
                                end
                            end
                            if typeof(shootArgs[2]) == "table" then
                                for i = 1, 5 do
                                    if type(shootArgs[2][i]) == "table" then
                                        shootArgs[2][i].thePart = part
                                    end
                                end
                            end
                        end
                    end, ...)
                end
            end
            return oldNamecall(self, ...)
        end)
    end)
    if not hooked then
        warn("[lunar.lua] Silent aim hook unavailable on this executor")
    end
end

do
    -- lunar.lua | New ESP System (ESPP)
    -- Embedded ESPP

    -- New ESP UI controls in the groupbox
    local ESPGb = getgenv().ESPGb

    ESPGb:AddLabel('lunar.lua ESP Active')
    ESPGb:AddToggle('ESPEnabled', { Text = 'Enable ESP', Default = false, Callback = function(v)
        if getgenv().EspLibrary and getgenv().EspLibrary.Table then
            getgenv().EspLibrary.Table.Enabled = v
        end
    end})
    ESPGb:AddToggle('ESPShowOnSelf', { Text = 'Show On Self', Default = false, Callback = function(v)
        if getgenv().EspLibrary and getgenv().EspLibrary.Table then
            getgenv().EspLibrary.Table.ShowLocalPlayer = v
            if v then
                pcall(function() getgenv().EspLibrary:AddTarget(game.Players.LocalPlayer) end)
            else
                pcall(function() getgenv().EspLibrary:RemoveTarget(game.Players.LocalPlayer) end)
            end
        end
    end})
    ESPGb:AddToggle('ESPBox', { Text = 'Box ESP', Default = false, Callback = function(v)
        if getgenv().EspLibrary and getgenv().EspLibrary.Table and getgenv().EspLibrary.Table.Boxes then
            getgenv().EspLibrary.Table.Boxes.Enabled = v
        end
    end})
    :AddColorPicker('ESPBoxGradTop', { Title = 'Box Outline Top', Default = ACCENT, Callback = function(c)
        if getgenv().EspLibrary and getgenv().EspLibrary.Table and getgenv().EspLibrary.Table.Boxes then
            getgenv().EspLibrary.Table.Boxes.Gradients.Top = c
        end
    end})
    :AddColorPicker('ESPBoxGradBot', { Title = 'Box Outline Bot', Default = ACCENT, Callback = function(c)
        if getgenv().EspLibrary and getgenv().EspLibrary.Table and getgenv().EspLibrary.Table.Boxes then
            getgenv().EspLibrary.Table.Boxes.Gradients.Bot = c
        end
    end})

    ESPGb:AddToggle('ESPBoxFilled', { Text = 'Filled Box', Default = false, Callback = function(v)
        if getgenv().EspLibrary and getgenv().EspLibrary.Table and getgenv().EspLibrary.Table.Boxes and getgenv().EspLibrary.Table.Boxes.Filled then
            getgenv().EspLibrary.Table.Boxes.Filled.Enabled = v
        end
    end})
    :AddColorPicker('ESPBoxFillTop', { Title = 'Fill Gradient Top', Default = ACCENT, Callback = function(c)
        if getgenv().EspLibrary and getgenv().EspLibrary.Table and getgenv().EspLibrary.Table.Boxes and getgenv().EspLibrary.Table.Boxes.Filled then
            getgenv().EspLibrary.Table.Boxes.Filled.Top = c
        end
    end})
    :AddColorPicker('ESPBoxFillBot', { Title = 'Fill Gradient Bot', Default = ACCENT, Callback = function(c)
        if getgenv().EspLibrary and getgenv().EspLibrary.Table and getgenv().EspLibrary.Table.Boxes and getgenv().EspLibrary.Table.Boxes.Filled then
            getgenv().EspLibrary.Table.Boxes.Filled.Bot = c
        end
    end})

    ESPGb:AddToggle('ESPBoxGlow', { Text = 'Box Glow', Default = false, Callback = function(v)
        if getgenv().EspLibrary and getgenv().EspLibrary.Table and getgenv().EspLibrary.Table.Boxes then
            getgenv().EspLibrary.Table.Boxes['Box Glow'].Enabled = v
        end
    end})
    :AddColorPicker('ESPBoxGlowTop', { Title = 'Glow Top', Default = ACCENT, Callback = function(c)
        if getgenv().EspLibrary and getgenv().EspLibrary.Table and getgenv().EspLibrary.Table.Boxes then
            getgenv().EspLibrary.Table.Boxes['Box Glow'].Top = c
        end
    end})
    :AddColorPicker('ESPBoxGlowBot', { Title = 'Glow Bot', Default = ACCENT, Callback = function(c)
        if getgenv().EspLibrary and getgenv().EspLibrary.Table and getgenv().EspLibrary.Table.Boxes then
            getgenv().EspLibrary.Table.Boxes['Box Glow'].Bot = c
        end
    end})

    ESPGb:AddToggle('ESPName', { Text = 'Names', Default = false, Callback = function(v)
        if getgenv().EspLibrary and getgenv().EspLibrary.Table and getgenv().EspLibrary.Table.Texts then
            getgenv().EspLibrary.Table.Texts.Name.Enabled = v
        end
    end})
    :AddColorPicker('ESPNameColor', { Title = 'Name Color', Default = ACCENT, Callback = function(c)
        if getgenv().EspLibrary and getgenv().EspLibrary.Table and getgenv().EspLibrary.Table.Texts then
            getgenv().EspLibrary.Table.Texts.Name.Color = c
        end
    end})

    ESPGb:AddToggle('ESPStuds', { Text = 'Distance', Default = false, Callback = function(v)
        if getgenv().EspLibrary and getgenv().EspLibrary.Table and getgenv().EspLibrary.Table.Texts then
            getgenv().EspLibrary.Table.Texts.Distance.Enabled = v
        end
    end})
    :AddColorPicker('ESPStudsColor', { Title = 'Distance Color', Default = ACCENT, Callback = function(c)
        if getgenv().EspLibrary and getgenv().EspLibrary.Table and getgenv().EspLibrary.Table.Texts then
            getgenv().EspLibrary.Table.Texts.Distance.Color = c
        end
    end})

    ESPGb:AddToggle('ESPTool', { Text = 'Weapon', Default = false, Callback = function(v)
        if getgenv().EspLibrary and getgenv().EspLibrary.Table and getgenv().EspLibrary.Table.Texts then
            getgenv().EspLibrary.Table.Texts.Weapon.Enabled = v
        end
    end})
    :AddColorPicker('ESPToolColor', { Title = 'Weapon Color', Default = ACCENT, Callback = function(c)
        if getgenv().EspLibrary and getgenv().EspLibrary.Table and getgenv().EspLibrary.Table.Texts then
            getgenv().EspLibrary.Table.Texts.Weapon.Color = c
        end
    end})

    ESPGb:AddToggle('ESPHealthBar', { Text = 'Health Bar', Default = false, Callback = function(v)
        if getgenv().EspLibrary and getgenv().EspLibrary.Table and getgenv().EspLibrary.Table.Bars then
            getgenv().EspLibrary.Table.Bars['Health Bar'].Enabled = v
        end
    end})
    :AddColorPicker('ESPHealthTopColor', { Title = 'Health High', Default = Color3.fromRGB(0, 255, 0), Callback = function(c)
        if getgenv().EspLibrary and getgenv().EspLibrary.Table and getgenv().EspLibrary.Table.Bars then
            getgenv().EspLibrary.Table.Bars['Health Bar'].Top = c
        end
    end})
    :AddColorPicker('ESPHealthMidColor', { Title = 'Health Mid', Default = Color3.fromRGB(255, 170, 0), Callback = function(c)
        if getgenv().EspLibrary and getgenv().EspLibrary.Table and getgenv().EspLibrary.Table.Bars then
            getgenv().EspLibrary.Table.Bars['Health Bar'].Middle = c
        end
    end})
    :AddColorPicker('ESPHealthBotColor', { Title = 'Health Low', Default = Color3.fromRGB(255, 0, 0), Callback = function(c)
        if getgenv().EspLibrary and getgenv().EspLibrary.Table and getgenv().EspLibrary.Table.Bars then
            getgenv().EspLibrary.Table.Bars['Health Bar'].Bot = c
        end
    end})

    ESPGb:AddToggle('ESPArmorBar', { Text = 'Armor Bar', Default = false, Callback = function(v)
        if getgenv().EspLibrary and getgenv().EspLibrary.Table and getgenv().EspLibrary.Table.Bars then
            getgenv().EspLibrary.Table.Bars['Armor Bar'].Enabled = v
        end
    end})
    :AddColorPicker('ESPArmorTopColor', { Title = 'Armor High', Default = ACCENT, Callback = function(c)
        if getgenv().EspLibrary and getgenv().EspLibrary.Table and getgenv().EspLibrary.Table.Bars then
            getgenv().EspLibrary.Table.Bars['Armor Bar'].Top = c
        end
    end})
    :AddColorPicker('ESPArmorMidColor', { Title = 'Armor Mid', Default = ACCENT, Callback = function(c)
        if getgenv().EspLibrary and getgenv().EspLibrary.Table and getgenv().EspLibrary.Table.Bars then
            getgenv().EspLibrary.Table.Bars['Armor Bar'].Middle = c
        end
    end})
    :AddColorPicker('ESPArmorBotColor', { Title = 'Armor Low', Default = ACCENT, Callback = function(c)
        if getgenv().EspLibrary and getgenv().EspLibrary.Table and getgenv().EspLibrary.Table.Bars then
            getgenv().EspLibrary.Table.Bars['Armor Bar'].Bot = c
        end
    end})

    ESPGb:AddSlider('ESPDistance', { Text = 'Render Distance', Default = 7520, Min = 100, Max = 10000, Rounding = 0, Callback = function(v)
        if getgenv().EspLibrary and getgenv().EspLibrary.Table then
            getgenv().EspLibrary.Table.Distance = v
        end
    end})

    getgenv().ESPCleanup = function()
        if getgenv().EspLibrary and getgenv().EspLibrary.Cache then
            for _, data in pairs(getgenv().EspLibrary.Cache) do
                if data and data.Objects and data.Objects.TargetHolder then
                    pcall(function() data.Objects.TargetHolder:Destroy() end)
                end
            end
            table.clear(getgenv().EspLibrary.Cache)
        end
    end
end

do
    if getgenv().EspLibrary and getgenv().EspLibrary.Unload then
        pcall(getgenv().EspLibrary.Unload, getgenv().EspLibrary)
    end

    local GetService = setmetatable({}, {
        __index = function(_, Name)
            return game:GetService(Name);
        end;
    })

    local Workspace, Players, RunService, HttpService = GetService["Workspace"], GetService["Players"], GetService["RunService"], GetService["HttpService"];
    local LocalPlayer, Camera = Players.LocalPlayer, Workspace.CurrentCamera;
    local WorldToViewportPoint, FindFirstChildOfClass, FindFirstChild = Camera.WorldToViewportPoint, game.FindFirstChildOfClass, game.FindFirstChild;

    local NewVector3, NewVector2, Dim, Dim2, DimOffset = Vector3.new, Vector2.new, UDim.new, UDim2.new, UDim2.fromOffset;
    local NumSeq = NumberSequence.new;
    local NumKey = NumberSequenceKeypoint.new;

    local Format, Spawn, Clear, Floor, Clamp, Abs, Tan, Rad, Huge, Remove = string.format, task.spawn, table.clear, math.floor, math.clamp, math.abs, math.tan, math.rad, math.huge, table.remove;
    local Frame, ZeroVector3, CameraPosition, CachedFocalLength, ViewPortY, Updates = 1 / 60, NewVector3(0,0,0), NewVector3(0,0,0), 0, 0, 0;

    local function CameraCache()
        ViewPortY = Camera.ViewportSize.Y;
        CachedFocalLength = ViewPortY / (2 * Tan(Rad(Camera.FieldOfView) * 0.5));
    end

    CameraCache();

    Camera:GetPropertyChangedSignal("FieldOfView"):Connect(CameraCache);
    Camera:GetPropertyChangedSignal("ViewportSize"):Connect(CameraCache);

    getgenv().EspLibrary = {
        ['Directory'] = 'Esp',
        ['Cache'] = {},
        ['Holder'] = nil,
        ['Threads'] = {},
        ['Connections'] = {},

        ['Table'] = {
            ['Enabled'] = false,
            ['ShowLocalPlayer'] = false,
            ['Distance'] = 7520,
            ['RefreshRate'] = 60,
            ['Font'] = 'TahomaBold',
            ['FontSize'] = 12,
            ['FontType'] = 'none',

            ['Boxes'] = {
                ['Enabled'] = false,
                ['DynamicBoxes'] = true,
                ['Type'] = "2D",
                ['Rotation'] = 90,

                ['Bounding Box'] = {
                    ['Enabled'] = true,
                    ['IncludeAcsessories'] = false,
                    ['BoxX'] = 0,
                    ['BoxY'] = 0,
                },

                ['Box Glow'] = {
                    ['Enabled'] = false,
                    ['Top'] = Color3.fromRGB(0, 255, 255),
                    ['Bot'] = Color3.fromRGB(0, 255, 255),
                    ['Transparency'] = {0.75, 0.75},
                },

                ['Gradients'] = {
                    ['Top'] = Color3.fromRGB(255, 255, 255),
                    ['Bot'] = Color3.fromRGB(0, 255, 255),
                },

                ['Filled'] = {
                    ['Enabled'] = false,
                    ['Top'] = Color3.fromRGB(255, 255, 255),
                    ['Bot'] = Color3.fromRGB(0, 255, 255),
                    ['Transparency'] = {1, 0.65},
                },
            },

            ['Bars'] = {
                ['Health Bar'] = {
                    ['Enabled'] = false,
                    ['Top'] = Color3.fromRGB(0, 255, 0),
                    ['Middle'] = Color3.fromRGB(255, 170, 0),
                    ['Bot'] = Color3.fromRGB(255, 0, 0),
                },

                ['Armor Bar'] = {
                    ['Enabled'] = false,
                    ['Top'] = Color3.fromRGB(255, 255, 255),
                    ['Middle'] = Color3.fromRGB(220, 220, 220),
                    ['Bot'] = Color3.fromRGB(180, 180, 180),
                },
            },

            ['Texts'] = {
                ['Name'] = {
                    ['Enabled'] = false,
                    ['Color'] = Color3.fromRGB(255, 255, 255),
                },

                ['Distance'] = {
                    ['Enabled'] = false,
                    ['Color'] = Color3.fromRGB(255, 255, 255),
                },

                ['Weapon'] = {
                    ['Enabled'] = false,
                    ['Color'] = Color3.fromRGB(255, 255, 255),
                },
            },

            ['Flags'] = {
                ['Walking'] = {
                    ['Enabled'] = false,
                    ['Color'] = Color3.fromRGB(255, 0, 0),
                    ['Text'] = "Walking",
                },
                ['Jumping'] = {
                    ['Enabled'] = false,
                    ['Color'] = Color3.fromRGB(144, 238, 144),
                    ['Text'] = "Jumping",
                },
                ['Swimming'] = {
                    ['Enabled'] = false,
                    ['Color'] = Color3.fromRGB(0, 255, 255),
                    ['Text'] = "Swimming",
                },
            }
        }
    }

    local Table = getgenv().EspLibrary['Table'];

    local Fonts = {}; do
        local function FontsRegister(Name, Weight, Style, Asset)
            if not isfile(Asset.Id) then
                writefile(Asset.Id, Asset.Font)
            end

            if isfile(Name .. ".font") then
                delfile(Name .. ".font")
            end

            local Info = {
                name = Name,
                faces = {
                    {
                        name = "Normal",
                        weight = Weight,
                        style = Style,
                        assetId = getcustomasset(Asset.Id),
                    },
                },
            }

            writefile(Name .. ".font", HttpService:JSONEncode(Info))
            return getcustomasset(Name .. ".font")
        end;

        Fonts.Tahoma = FontsRegister("Tahoma", 400, "Normal", {
            Id = "Tahoma.ttf",
            Font = game:HttpGet("https://github.com/i77lhm/storage/raw/refs/heads/main/fonts/fs-tahoma-8px.ttf"),
        })

        Fonts.XPTahoma = FontsRegister("XPTahoma", 400, "Normal", {
            Id = "Tahoma8PTBOLD.ttf",
            Font = game:HttpGet("https://github.com/sametexe001/luas/raw/refs/heads/main/fonts/TAHOMA-8PT-BOLD-WINDOWS-XP.TTF"),
        })

        Fonts.SmallestPixel = FontsRegister("SmallestPixel", 400, "Normal", {
            Id = "smallest_pixel-7.ttf",
            Font = game:HttpGet("https://raw.githubusercontent.com/sametexe001/luas/main/smallest_pixel-7.ttf")
        })

        Fonts.ProggyTiny = FontsRegister("ProggyTiny", 400, "Normal", {
            Id = "ProggyTinyyyy.ttf",
            Font = game:HttpGet("https://github.com/i77lhm/storage/raw/refs/heads/main/fonts/ProggyTiny.ttf")
        })

        Fonts.ProggyClean = FontsRegister("ProggyClean", 400, "Normal", {
            Id = "ProggyClean.ttf",
            Font = game:HttpGet("https://github.com/i77lhm/storage/raw/main/fonts/ProggyClean.ttf"),
        })
        
        getgenv().EspLibrary.ProggyTiny = Font.new(Fonts.ProggyClean, Enum.FontWeight.Regular, Enum.FontStyle.Normal);
        getgenv().EspLibrary.TahomaBold = Font.new(Fonts.XPTahoma, Enum.FontWeight.Regular, Enum.FontStyle.Normal);
        getgenv().EspLibrary.ProggyClean = Font.new(Fonts.ProggyClean, Enum.FontWeight.Regular, Enum.FontStyle.Normal);
        getgenv().EspLibrary.Tahoma = Font.new(Fonts.Tahoma, Enum.FontWeight.Regular, Enum.FontStyle.Normal);
        getgenv().EspLibrary.SmallestPixel = Font.new(Fonts.SmallestPixel, Enum.FontWeight.Regular, Enum.FontStyle.Normal);
    end

    getgenv().EspLibrary.__index = getgenv().EspLibrary;

    getgenv().EspLibrary.CreateObjects = function(self, Name, Prop)
        local New = Instance.new(Name);

        for Property, Value in Prop or {} do
            New[Property] = Value;
        end;
                
        return New;
    end

    getgenv().EspLibrary.CreateThreads = function(self, Name, Signal, Callback)
        local Connection = Signal:Connect(Callback);
        self.Threads[Name] = Connection;
        return Connection;
    end

    getgenv().EspLibrary.Holder = getgenv().EspLibrary:CreateObjects("ScreenGui", {
        Name = "\n",
        Parent = gethui(),
        ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets,
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        ResetOnSpawn = false,
        DisplayOrder = 10000,
        IgnoreGuiInset = true,
    })

    getgenv().EspLibrary.InitEsp = function(self, Data)
        local Objects = Data.Objects

        do
            Objects["TargetHolder"] = self:CreateObjects("Frame", {
                Parent = self.Holder,
                Visible = false,
                BackgroundTransparency = 1,
                Position = Dim2(0, 0, 0, 0),
                Size = Dim2(0, 0, 0, 0),
                BorderSizePixel = 0,
                BorderColor3 = Color3.fromRGB(0, 0, 0),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            })

            Objects["TopHolder"] = self:CreateObjects("Frame", {
                Parent = Objects["TargetHolder"],
                AutomaticSize = Enum.AutomaticSize.Y,
                Visible = true,
                BackgroundTransparency = 1,
                AnchorPoint = NewVector2(0, 1),
                Position = Dim2(0, -2, 0, -5),
                Size = Dim2(1, 4, 0, 0),
                BorderSizePixel = 0,
                BorderColor3 = Color3.fromRGB(0, 0, 0),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            })

            Objects["BottomHolder"] = self:CreateObjects("Frame", {
                Parent = Objects["TargetHolder"],
                AutomaticSize = Enum.AutomaticSize.Y,
                Visible = true,
                BackgroundTransparency = 1,
                Position = Dim2(0, -2, 1, 3),
                Size = Dim2(1, 4, 0, 0),
                BorderSizePixel = 0,
                BorderColor3 = Color3.fromRGB(0, 0, 0),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            })

            Objects["LeftHolder"] = self:CreateObjects("Frame", {
                Parent = Objects["TargetHolder"],
                AutomaticSize = Enum.AutomaticSize.X,
                Visible = true,
                BackgroundTransparency = 1,
                AnchorPoint = NewVector2(1, 0),
                Position = Dim2(0, -5, 0, -2),
                Size = Dim2(0, 0, 1, 4),
                BorderSizePixel = 0,
                BorderColor3 = Color3.fromRGB(0, 0, 0),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            })

            Objects["RightHolder"] = self:CreateObjects("Frame", {
                Parent = Objects["TargetHolder"],
                AutomaticSize = Enum.AutomaticSize.X,
                Visible = true,
                BackgroundTransparency = 1,
                Position = Dim2(1, 5, 0, -2),
                Size = Dim2(0, 0, 1, 4),
                BorderSizePixel = 0,
                BorderColor3 = Color3.fromRGB(0, 0, 0),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            })
        end

        do
            Objects["TopTextHolder"] = self:CreateObjects("Frame", {
                Parent = Objects["TopHolder"],
                AutomaticSize = Enum.AutomaticSize.Y,
                Visible = true,
                BackgroundTransparency = 1,
                Position = Dim2(0, 0, 0, 0),
                Size = Dim2(1, 0, 0, 0),
                BorderSizePixel = 0,
                BorderColor3 = Color3.fromRGB(0, 0, 0),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            })

            Objects["BottomTextHolder"] = self:CreateObjects("Frame", {
                Parent = Objects["BottomHolder"],
                LayoutOrder = 2,
                AutomaticSize = Enum.AutomaticSize.Y,
                Visible = true,
                BackgroundTransparency = 1,
                Position = Dim2(0, 0, 0, 0),
                Size = Dim2(1, 0, 0, 0),
                BorderSizePixel = 0,
                BorderColor3 = Color3.fromRGB(0, 0, 0),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            })

            Objects["LeftTextHolder"] = self:CreateObjects("Frame", {
                Parent = Objects["LeftHolder"],
                AutomaticSize = Enum.AutomaticSize.XY,
                Visible = true,
                BackgroundTransparency = 1,
                Position = Dim2(0, 0, 0, 0),
                Size = Dim2(1, 0, 0, 0),
                BorderSizePixel = 0,
                BorderColor3 = Color3.fromRGB(0, 0, 0),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            })

            Objects["RightTextHolder"] = self:CreateObjects("Frame", {
                Parent = Objects["RightHolder"],
                LayoutOrder = 2,
                AutomaticSize = Enum.AutomaticSize.XY,
                Visible = true,
                BackgroundTransparency = 1,
                Position = Dim2(0, 0, 0, 0),
                Size = Dim2(0, 0, 0, 0),
                BorderSizePixel = 0,
                BorderColor3 = Color3.fromRGB(0, 0, 0),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            })
        end

        do
            Objects["LeftBarHolder"] = self:CreateObjects("Frame", {
                Parent = Objects["LeftHolder"],
                AutomaticSize = Enum.AutomaticSize.X,
                Visible = false,
                BackgroundTransparency = 1,
                Position = Dim2(0, 0, 0, 0),
                Size = Dim2(0, 0, 1, 0),
                BorderSizePixel = 0,
                BorderColor3 = Color3.fromRGB(0, 0, 0),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            })

            Objects["BottomBarHolder"] = self:CreateObjects("Frame", {
                Parent = Objects["BottomHolder"],
                LayoutOrder = 0,
                AutomaticSize = Enum.AutomaticSize.Y,
                Visible = false,
                BackgroundTransparency = 1,
                Position = Dim2(0, 0, 0, 0),
                Size = Dim2(1, 0, 0, 0),
                BorderSizePixel = 0,
                BorderColor3 = Color3.fromRGB(0, 0, 0),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            })
        end

        do
            self:CreateObjects("UIListLayout", {
                Parent = Objects["TopTextHolder"],
                VerticalAlignment = Enum.VerticalAlignment.Bottom,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                Padding = Dim(0, 1),
                SortOrder = Enum.SortOrder.LayoutOrder,
            })

            self:CreateObjects("UIListLayout", {
                Parent = Objects["BottomTextHolder"],
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                Padding = Dim(0, -1),
                SortOrder = Enum.SortOrder.LayoutOrder,
            })

            self:CreateObjects("UIListLayout", {
                Parent = Objects["LeftTextHolder"],
                HorizontalAlignment = Enum.HorizontalAlignment.Right,
                Padding = Dim(0, 0),
                SortOrder = Enum.SortOrder.LayoutOrder,
            })

            self:CreateObjects("UIListLayout", {
                Parent = Objects["RightTextHolder"],
                HorizontalAlignment = Enum.HorizontalAlignment.Left,
                Padding = Dim(0, 0),
                SortOrder = Enum.SortOrder.LayoutOrder,
            })

            self:CreateObjects("UIListLayout", {
                Parent = Objects["LeftBarHolder"],
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Right,
                Padding = Dim(0, 5),
                SortOrder = Enum.SortOrder.LayoutOrder,
            })

            self:CreateObjects("UIListLayout", {
                Parent = Objects["BottomBarHolder"],
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                Padding = Dim(0, 5),
                SortOrder = Enum.SortOrder.LayoutOrder,
            })

            self:CreateObjects("UIListLayout", {
                Parent = Objects["TopHolder"],
                VerticalAlignment = Enum.VerticalAlignment.Bottom,
                Padding = Dim(0, 1),
                SortOrder = Enum.SortOrder.LayoutOrder,
            })

            self:CreateObjects("UIListLayout", {
                Parent = Objects["BottomHolder"],
                Padding = Dim(0, 1),
                SortOrder = Enum.SortOrder.LayoutOrder,
            })

            self:CreateObjects("UIListLayout", {
                Parent = Objects["LeftHolder"],
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Left,
                Padding = Dim(0, 1),
                SortOrder = Enum.SortOrder.LayoutOrder,
            })

            self:CreateObjects("UIListLayout", {
                Parent = Objects["RightHolder"],
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Left,
                Padding = Dim(0, 1),
                SortOrder = Enum.SortOrder.LayoutOrder,
            })
        end

        do
            self:CreateObjects("UIPadding", {
                Parent = Objects["TopTextHolder"],
                PaddingBottom = Dim(0, 0),
            })

            self:CreateObjects("UIPadding", {
                Parent = Objects["BottomTextHolder"],
                PaddingTop = Dim(0, -1)
            })

            self:CreateObjects("UIPadding", {
                Parent = Objects["LeftTextHolder"],
                PaddingTop = Dim(0, -3),
            })

            self:CreateObjects("UIPadding", {
                Parent = Objects["RightTextHolder"],
                PaddingTop = Dim(0, -3),
            })

            self:CreateObjects("UIPadding", {
                Parent = Objects["LeftBarHolder"],
                PaddingRight = Dim(0, 0),
            })

            self:CreateObjects("UIPadding", {
                Parent = Objects["BottomBarHolder"],
                PaddingTop = Dim(0, 2),
            })

            self:CreateObjects("UIPadding", {
                Parent = Objects["LeftHolder"],
                PaddingRight = Dim(0, 1),
            })
        end

        do
            Objects["BoxGlow"] = self:CreateObjects("ImageLabel", {
                Parent = Objects["TargetHolder"],
                Image = "rbxassetid://110204605000367",
                ScaleType = Enum.ScaleType.Slice,
                SliceCenter = Rect.new(NewVector2(21, 21), NewVector2(79, 79)),
                AutomaticSize = Enum.AutomaticSize.XY,
                ImageTransparency = 0.65,
                ResampleMode = Enum.ResamplerMode.Pixelated,
                Visible = true,
                BackgroundTransparency = 1,
                Position = Dim2(0, -21, 0, -21),
                Size = Dim2(0, 0, 0, 0),
                BorderSizePixel = 0,
                BorderColor3 = Color3.fromRGB(0, 0, 0),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            })

            Objects["BoxGlowGradient"] = self:CreateObjects("UIGradient", {
                Parent = Objects["BoxGlow"],
                Rotation = 90,
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0)),
                }),
                Transparency = NumSeq({NumKey(0, 0), NumKey(1, 0)}),
            })

            self:CreateObjects("UIPadding", {
                Parent = Objects["BoxGlow"],
                PaddingTop = Dim(0, 21),
                PaddingBottom = Dim(0, 20),
                PaddingLeft = Dim(0, 21),
                PaddingRight = Dim(0, 20),
            })

            Objects["BoxOutlineHolder"] = self:CreateObjects("Frame", {
                Parent = Objects["BoxGlow"],
                Visible = false,
                BackgroundTransparency = 1,
                Position = Dim2(0, 0, 0, 0),
                Size = Dim2(0, 0, 0, 0),
                BorderSizePixel = 0,
                BorderColor3 = Color3.fromRGB(0, 0, 0),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            })

            Objects["BoxOutline"] = self:CreateObjects("UIStroke", {
                Parent = Objects["BoxOutlineHolder"],
                Thickness = 3,
                LineJoinMode = Enum.LineJoinMode.Miter,
            })

            Objects["BoxOutlineGradient"] = self:CreateObjects("UIGradient", {
                Parent = Objects["BoxOutline"],
                Rotation = 90,
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0)),
                }),
                Transparency = NumSeq({NumKey(0, 0), NumKey(1, 0)}),
            })

            Objects["BoxInlineHolder"] = self:CreateObjects("Frame", {
                Parent = Objects["BoxGlow"],
                Visible = false,
                BackgroundTransparency = 1,
                Position = Dim2(0, -1, 0, -1),
                Size = Dim2(0, 0, 0, 0),
                BorderSizePixel = 0,
                BorderColor3 = Color3.fromRGB(0, 0, 0),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            })

            Objects["BoxInline"] = self:CreateObjects("UIStroke", {
                Parent = Objects["BoxInlineHolder"],
                Color = Color3.fromRGB(255, 255, 255),
                LineJoinMode = Enum.LineJoinMode.Miter,
            })

            Objects["BoxInlineGradient"] = self:CreateObjects("UIGradient", {
                Parent = Objects["BoxInline"],
                Rotation = 90,
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
                }),
                Transparency = NumSeq({NumKey(0, 0), NumKey(1, 0)}),
            })

            Objects["BoxFill"] = self:CreateObjects("Frame", {
                Parent = Objects["BoxGlow"],
                Visible = false,
                BackgroundTransparency = 0,
                Position = Dim2(0, 0, 0, 0),
                Size = Dim2(0, 0, 0, 0),
                BorderSizePixel = 0,
                BorderColor3 = Color3.fromRGB(0, 0, 0),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            })

            Objects["BoxFillGradient"] = self:CreateObjects("UIGradient", {
                Parent = Objects["BoxFill"],
                Rotation = 90,
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
                }),
                Transparency = NumSeq({NumKey(0, 1), NumKey(1, 1)}),
            })

            Objects["CornerHolder"] = self:CreateObjects("Frame", {
                Parent = Objects["BoxGlow"],
                Visible = false,
                BackgroundTransparency = 1,
                Position = Dim2(0, -1, 0, -1),
                Size = Dim2(0, 0, 0, 0),
                BorderSizePixel = 0,
                BorderColor3 = Color3.fromRGB(0, 0, 0),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            })

            for i = 1, 8 do
                Objects["Line_" .. i] = self:CreateObjects("Frame", {
                    Parent = Objects["CornerHolder"],
                    Visible = false,
                    BackgroundTransparency = 0,
                    Position = Dim2(0, 0, 0, 0),
                    Size = Dim2(0, 0, 0, 0),
                    BorderSizePixel = 0,
                    BorderColor3 = Color3.fromRGB(0, 0, 0),
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                })
                self:CreateObjects("UIStroke", {
                    Parent = Objects["Line_" .. i],
                    Thickness = 1,
                    LineJoinMode = Enum.LineJoinMode.Miter,
                })
            end
        end

        do
            Objects["HealthBarOutline"] = self:CreateObjects("Frame", {
                Parent = Objects["LeftBarHolder"],
                ZIndex = 5,
                LayoutOrder = 0,
                Visible = false,
                BackgroundTransparency = 0,
                Position = Dim2(0, 0, 0, 0),
                Size = Dim2(0, 1, 1, 0),
                BorderSizePixel = 0,
                BorderColor3 = Color3.fromRGB(0, 0, 0),
                BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                ClipsDescendants = false,
            })

            self:CreateObjects("UIStroke", {
                Parent = Objects["HealthBarOutline"],
                Thickness = 1,
                LineJoinMode = Enum.LineJoinMode.Miter,
            })

            Objects["HealthBar"] = self:CreateObjects("Frame", {
                Parent = Objects["HealthBarOutline"],
                ZIndex = 6,
                AnchorPoint = NewVector2(0, 1),
                Position = Dim2(0, 0, 1, 0),
                Size = Dim2(1, 0, 1, 0),
                BorderSizePixel = 0,
                BorderColor3 = Color3.fromRGB(0, 0, 0),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                ClipsDescendants = true,
            })

            Objects["HealthBarGradient"] = self:CreateObjects("UIGradient", {
                Parent = Objects["HealthBar"],
                Rotation = 90,
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Table['Bars']['Health Bar']['Top']),
                    ColorSequenceKeypoint.new(0.5, Table['Bars']['Health Bar']['Middle']),
                    ColorSequenceKeypoint.new(1, Table['Bars']['Health Bar']['Bot']),
                }),
                Transparency = NumSeq({NumKey(0, 0), NumKey(1, 0)}),
            })

            Objects["HealthBarText"] = self:CreateObjects("TextLabel", {
                Parent = Objects["HealthBarOutline"],
                FontFace = getgenv().EspLibrary.SmallestPixel,
                TextSize = 9,
                ZIndex = 10,
                TextColor3 = Color3.fromRGB(255, 255, 255),
                Text = "",
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,
                AnchorPoint = NewVector2(0.5, 0.5),
                Position = Dim2(0.5, 0, 1, 0),
                BorderSizePixel = 0,
                Visible = false,
                BackgroundTransparency = 1,
                AutomaticSize = Enum.AutomaticSize.XY,
                Size = Dim2(0, 0, 0, 0),
            })

            self:CreateObjects("UIStroke", {
                Parent = Objects["HealthBarText"],
                Color = Color3.fromRGB(0, 0, 0),
                LineJoinMode = Enum.LineJoinMode.Miter,
            })

            Objects["ArmorBarOutline"] = self:CreateObjects("Frame", {
                Parent = Objects["BottomBarHolder"],
                ZIndex = 5,
                LayoutOrder = 0,
                Visible = false,
                BackgroundTransparency = 0,
                Position = Dim2(0, 0, 0, 0),
                Size = Dim2(1, 0, 0, 1),
                BorderSizePixel = 0,
                BorderColor3 = Color3.fromRGB(0, 0, 0),
                BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                ClipsDescendants = true,
            })

            self:CreateObjects("UIStroke", {
                Parent = Objects["ArmorBarOutline"],
                Thickness = 1,
                LineJoinMode = Enum.LineJoinMode.Miter,
            })

            Objects["ArmorBar"] = self:CreateObjects("Frame", {
                Parent = Objects["ArmorBarOutline"],
                ZIndex = 6,
                AnchorPoint = NewVector2(0, 0),
                Position = Dim2(0, 0, 0, 0),
                Size = Dim2(1, 0, 1, 0),
                BorderSizePixel = 0,
                BorderColor3 = Color3.fromRGB(0, 0, 0),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            })

            Objects["ArmorBarGradient"] = self:CreateObjects("UIGradient", {
                Parent = Objects["ArmorBar"],
                Rotation = 0,
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Table['Bars']['Armor Bar']['Top']),
                    ColorSequenceKeypoint.new(0.5, Table['Bars']['Armor Bar']['Middle']),
                    ColorSequenceKeypoint.new(1, Table['Bars']['Armor Bar']['Bot']),
                }),
                Transparency = NumSeq({NumKey(0, 0), NumKey(1, 0)}),
            })

            Objects["ArmorBarText"] = self:CreateObjects("TextLabel", {
                Parent = Objects["ArmorBar"],
                FontFace = getgenv().EspLibrary.SmallestPixel,
                TextSize = 9,
                ZIndex = 10,
                TextColor3 = Color3.fromRGB(255, 255, 255),
                Text = "",
                TextXAlignment = Enum.TextXAlignment.Center,
                AnchorPoint = NewVector2(0.5, 0.5),
                Position = Dim2(0.5, 0, 0.5, 0),
                BorderSizePixel = 0,
                Visible = false,
                BackgroundTransparency = 1,
                AutomaticSize = Enum.AutomaticSize.XY,
                Size = Dim2(0, 0, 0, 0),
            })

            self:CreateObjects("UIStroke", {
                Parent = Objects["ArmorBarText"],
                Color = Color3.fromRGB(0, 0, 0),
                LineJoinMode = Enum.LineJoinMode.Miter,
            })
        end

        do
            Objects["TargetName"] = self:CreateObjects("TextLabel", {
                Parent = Objects["TopTextHolder"],
                FontFace = getgenv().EspLibrary.TahomaBold,
                TextSize = 12,
                LayoutOrder = 2,
                TextColor3 = Table['Texts']['Name']['Color'],
                Text = "",
                TextXAlignment = Enum.TextXAlignment.Center,
                BorderSizePixel = 0,
                Visible = false,
                BackgroundTransparency = 1,
                ZIndex = 5,
                AutomaticSize = Enum.AutomaticSize.XY,
                Size = Dim2(0, 0, 0, 0),
            })

            self:CreateObjects("UIStroke", {
                Parent = Objects["TargetName"],
                Color = Color3.fromRGB(0, 0, 0),
                LineJoinMode = Enum.LineJoinMode.Miter,
            })

            Objects["Distance"] = self:CreateObjects("TextLabel", {
                Parent = Objects["BottomTextHolder"],
                FontFace = getgenv().EspLibrary.SmallestPixel,
                TextSize = 9,
                LayoutOrder = 2,
                TextColor3 = Table['Texts']['Distance']['Color'],
                Text = "",
                TextXAlignment = Enum.TextXAlignment.Center,
                BorderSizePixel = 0,
                Visible = false,
                BackgroundTransparency = 1,
                ZIndex = 5,
                AutomaticSize = Enum.AutomaticSize.XY,
                Size = Dim2(0, 0, 0, 0),
            })

            self:CreateObjects("UIStroke", {
                Parent = Objects["Distance"],
                Color = Color3.fromRGB(0, 0, 0),
                LineJoinMode = Enum.LineJoinMode.Miter,
            })

            Objects["WalkFlag"] = self:CreateObjects("TextLabel", {
                Parent = Objects["RightTextHolder"],
                FontFace = getgenv().EspLibrary.SmallestPixel,
                TextSize = 9,
                LayoutOrder = 1,
                TextColor3 = Table['Flags']['Walking']['Color'],
                Text = Table['Flags']['Walking']['Text'],
                TextXAlignment = Enum.TextXAlignment.Left,
                BorderSizePixel = 0,
                Visible = false,
                BackgroundTransparency = 1,
                ZIndex = 5,
                AutomaticSize = Enum.AutomaticSize.XY,
                Size = Dim2(0, 0, 0, 0),
            })

            self:CreateObjects("UIStroke", {
                Parent = Objects["WalkFlag"],
                Color = Color3.fromRGB(0, 0, 0),
                LineJoinMode = Enum.LineJoinMode.Miter,
            })

            Objects["JumpFlag"] = self:CreateObjects("TextLabel", {
                Parent = Objects["RightTextHolder"],
                FontFace = getgenv().EspLibrary.SmallestPixel,
                TextSize = 9,
                LayoutOrder = 2,
                TextColor3 = Table['Flags']['Jumping']['Color'],
                Text = Table['Flags']['Jumping']['Text'],
                TextXAlignment = Enum.TextXAlignment.Left,
                BorderSizePixel = 0,
                Visible = false,
                BackgroundTransparency = 1,
                ZIndex = 5,
                AutomaticSize = Enum.AutomaticSize.XY,
                Size = Dim2(0, 0, 0, 0),
            })

            self:CreateObjects("UIStroke", {
                Parent = Objects["JumpFlag"],
                Color = Color3.fromRGB(0, 0, 0),
                LineJoinMode = Enum.LineJoinMode.Miter,
            })

            Objects["SwimmingFlag"] = self:CreateObjects("TextLabel", {
                Parent = Objects["RightTextHolder"],
                FontFace = getgenv().EspLibrary.SmallestPixel,
                TextSize = 9,
                LayoutOrder = 4,
                TextColor3 = Table['Flags']['Swimming']['Color'],
                Text = Table['Flags']['Swimming']['Text'],
                TextXAlignment = Enum.TextXAlignment.Left,
                BorderSizePixel = 0,
                Visible = false,
                BackgroundTransparency = 1,
                ZIndex = 5,
                AutomaticSize = Enum.AutomaticSize.XY,
                Size = Dim2(0, 0, 0, 0),
            })

            self:CreateObjects("UIStroke", {
                Parent = Objects["SwimmingFlag"],
                Color = Color3.fromRGB(0, 0, 0),
                LineJoinMode = Enum.LineJoinMode.Miter,
            })

            Objects["Weapon"] = self:CreateObjects("TextLabel", {
                Parent = Objects["BottomTextHolder"],
                FontFace = getgenv().EspLibrary.SmallestPixel,
                TextSize = 9,
                LayoutOrder = 3,
                TextColor3 = Table['Texts']['Weapon']['Color'],
                Text = "none",
                TextXAlignment = Enum.TextXAlignment.Center,
                BorderSizePixel = 0,
                Visible = false,
                BackgroundTransparency = 1,
                ZIndex = 5,
                AutomaticSize = Enum.AutomaticSize.XY,
                Size = Dim2(0, 0, 0, 0),
            })

            self:CreateObjects("UIStroke", {
                Parent = Objects["Weapon"],
                Color = Color3.fromRGB(0, 0, 0),
                LineJoinMode = Enum.LineJoinMode.Miter,
            })
        end
    end

    local CornerLayout = {
        {Dim2(0, -1, 0, -1), Dim2(0.3, 0, 0, 1), NewVector2(0, 0), 0},
        {Dim2(0, -1, 0, -1), Dim2(0, 1, 0.3, 0), NewVector2(0, 0), 180},
        {Dim2(1, 1, 0, -1), Dim2(0.3, 0, 0, 1), NewVector2(1, 0), 0},
        {Dim2(1, 1, 0, -1), Dim2(0, 1, 0.3, 0), NewVector2(1, 0), 180},
        {Dim2(0, -1, 1, 1), Dim2(0.3, 0, 0, 1), NewVector2(0, 1), 0},
        {Dim2(0, -1, 1, 1), Dim2(0, 1, 0.3, 0), NewVector2(0, 1), -180},
        {Dim2(1, 1, 1, 1), Dim2(0.3, 0, 0, 1), NewVector2(1, 1), 0},
        {Dim2(1, 1, 1, 1), Dim2(0, 1, 0.3, 0), NewVector2(1, 1), -180},
    }

    getgenv().EspLibrary.CalculateBox = function(self, Data)
        local RootPart = Data['RootPart']

        if not RootPart then
            return nil, nil, nil, nil, false;
        end;

        local RootScreen, OnScreen = WorldToViewportPoint(Camera, RootPart.Position)

        if not OnScreen then
            return nil, nil, nil, nil, false;
        end;

        local BoundingBox = Table['Boxes']['Bounding Box'];

        if Table['Boxes']['DynamicBoxes'] then
            local Children = Data['Children'];

            if not Children then
                return nil, nil, nil, nil, false;
            end;

            local IncludeAccessories = Data['IncludeAccessories'];
            local ScrMinX, ScrMinY = Huge, Huge;
            local ScrMaxX, ScrMaxY = -Huge, -Huge;
            local HasValidParts = false;

            for _, Part in Children do
                if Part:IsA('BasePart') and Part.Transparency ~= 1 and Part ~= RootPart then
                    local Parent = Part.Parent

                    if Parent == nil then
                        continue
                    end

                    if not IncludeAccessories and Parent:IsA('Accessory') then
                        continue;
                    end;

                    local PartScreen, PartOnScreen = WorldToViewportPoint(Camera, Part.Position);

                    if not PartOnScreen or PartScreen.Z <= 0 then
                        continue;
                    end;

                    HasValidParts = true;

                    local Cf = Part.CFrame;
                    local Sz = Part.Size;
                    local HX, HY, HZ = Sz.X * 0.5, Sz.Y * 0.5, Sz.Z * 0.5;
                    local RX, UY, LZ = Cf.RightVector, Cf.UpVector, Cf.LookVector;
                    local DepthScale = CachedFocalLength / PartScreen.Z;

                    local Ex = (Abs(RX.X * HX) + Abs(UY.X * HY) + Abs(LZ.X * HZ)) * DepthScale;
                    local Ey = (Abs(RX.Y * HX) + Abs(UY.Y * HY) + Abs(LZ.Y * HZ)) * DepthScale;

                    local PMinX, PMaxX = PartScreen.X - Ex, PartScreen.X + Ex;
                    local PMinY, PMaxY = PartScreen.Y - Ey, PartScreen.Y + Ey;

                    if PMinX < ScrMinX then ScrMinX = PMinX; end
                    if PMaxX > ScrMaxX then ScrMaxX = PMaxX; end
                    if PMinY < ScrMinY then ScrMinY = PMinY; end
                    if PMaxY > ScrMaxY then ScrMaxY = PMaxY; end
                end;
            end;

            if not HasValidParts then
                return nil, nil, nil, nil, false;
            end;

            local PadX = BoundingBox['BoxX'];
            local PadY = BoundingBox['BoxY'];
            local W = (ScrMaxX - ScrMinX) + PadX;
            local H = (ScrMaxY - ScrMinY) + PadY;

            return W, H, ScrMinX - (PadX * 0.5), ScrMinY - (PadY * 0.5), true;
        else
            local Scale = (RootPart.Size.Y * ViewPortY) / (RootScreen.Z * 2);
            local W, H = 3 * Scale, 4.5 * Scale;
            return W, H, RootScreen.X - (W * 0.5), RootScreen.Y - (H * 0.5), OnScreen;
        end
    end

    getgenv().EspLibrary.AddTarget = function(self, Player)
        if Player == LocalPlayer and not Table['ShowLocalPlayer'] then
            return
        end;

        if self.Cache[Player] then
            return
        end;

        local Data = {
            ['Player'] = Player,
            ['Objects'] = {},
            ['Conns'] = {},
            ['Character'] = nil,
            ['RootPart'] = nil,
            ['Humanoid'] = nil,
            ['Children'] = nil,
            ['Health'] = 0,
            ['MaxHealth'] = 100,
            ['Armor'] = 100,
            ['MaxArmor'] = 100,
            ['CurrentTool'] = nil,
            ['Alive'] = false,
            ['LastW'] = nil,
            ['LastH'] = nil,
            ['LastX'] = nil,
            ['LastY'] = nil,
            ['WalkActive'] = false,
            ['JumpActive'] = false,
            ['FallingActive'] = false,
            ['SwimmingActive'] = false,
            ['IncludeAccessories'] = Table['Boxes']['Bounding Box']['IncludeAcsessories'],
            ['LastGlowTop'] = nil,
            ['LastGlowBot'] = nil,
            ['LastGlowT1'] = nil,
            ['LastGlowT2'] = nil,
            ['LastGradTop'] = nil,
            ['LastGradBot'] = nil,
            ['LastFillTop'] = nil,
            ['LastFillBot'] = nil,
            ['LastFillT1'] = nil,
            ['LastFillT2'] = nil,
            ['LastDist'] = nil,
            ['LastDistColor'] = nil,
            ['LastDisplayName'] = nil,
            ['LastNameColor'] = nil,
            ['LastHealthTop'] = nil,
            ['LastHealthMiddle'] = nil,
            ['LastHealthBot'] = nil,
            ['LastHealthFloor'] = nil,
            ['LastRatio'] = nil,
            ['LastArmorTop'] = nil,
            ['LastArmorMiddle'] = nil,
            ['LastArmorBot'] = nil,
            ['LastArmorFloor'] = nil,
            ['LastArmorRatio'] = nil,
            ['LastWeapon'] = nil,
            ['LastWeaponColor'] = nil,
        }
        self:InitEsp(Data);
        self['Cache'][Player] = Data;

        local HealthHandler = {}; do
            function HealthHandler.BindHealth(Humanoid)
                if Data['Conns']['Health'] then
                    Data['Conns']['Health']:Disconnect()
                end

                if Data['Conns']['Died'] then
                    Data['Conns']['Died']:Disconnect()
                end

                Data['Humanoid'] = Humanoid
                Data['Health'] = Humanoid.Health
                Data['MaxHealth'] = Humanoid.MaxHealth
                Data['Alive'] = Humanoid.Health > 0

                Data['Conns']['Health'] = Humanoid.HealthChanged:Connect(function(NewHealth)
                    Data['Alive'] = NewHealth > 0
                    Data['Health'] = NewHealth
                end)

                Data['Conns']['Died'] = Humanoid.Died:Connect(function()
                    Data['Alive'] = false
                end)
            end

            Data['BindHealth'] = HealthHandler.BindHealth;
        end

        local ToolHandler = {}; do
            function ToolHandler.BindTool(Character)
                if Data['Conns']['ToolAdded'] then
                    Data['Conns']['ToolAdded']:Disconnect()
                end

                if Data['Conns']['ToolRemoved'] then
                    Data['Conns']['ToolRemoved']:Disconnect()
                end

                if Data['Children'] then
                    for _, Child in Data['Children'] do
                        if Child:IsA('Tool') then
                            Data['CurrentTool'] = Child.Name
                            break
                        end
                    end
                end

                Data['Conns']['ToolAdded'] = Character.ChildAdded:Connect(function(Child)
                    if Child:IsA('Tool') then
                        Data['CurrentTool'] = Child.Name
                    end
                end)

                Data['Conns']['ToolRemoved'] = Character.ChildRemoved:Connect(function(Child)
                    if Child:IsA('Tool') then
                        Data['CurrentTool'] = nil
                    end
                end)
            end

            Data['BindTool'] = ToolHandler.BindTool
        end

        local ChildHandler = {}; do
            function ChildHandler.BindChildren(Character)
                if Data['Conns']['ChildAdded'] then
                    Data['Conns']['ChildAdded']:Disconnect();
                end;

                if Data['Conns']['ChildRemoved'] then
                    Data['Conns']['ChildRemoved']:Disconnect();
                end;

                local Children = Character:GetChildren();
                Data['Children'] = Children;

                Data['Conns']['ChildAdded'] = Character.ChildAdded:Connect(function(Child)
                    Children[#Children + 1] = Child;
                end)

                Data['Conns']['ChildRemoved'] = Character.ChildRemoved:Connect(function(Child)
                    for I = #Children, 1, -1 do
                        if Children[I] == Child then
                            Remove(Children, I);
                            break;
                        end;
                    end
                end)

                Data['BindTool'](Character);
            end

            Data['BindChildren'] = ChildHandler.BindChildren;
        end

        local FlagsHandler = {}; do
            function FlagsHandler.BindFlags(Humanoid)
                if Data['Conns']['MoveDir'] then
                    Data['Conns']['MoveDir']:Disconnect();
                end;

                if Data['Conns']['StateChange'] then
                    Data['Conns']['StateChange']:Disconnect();
                end;

                local Objects = Data['Objects']
                Data['JumpActive'] = false;
                Data['WalkActive'] = false;
                Data['FallingActive'] = false;
                Data['SwimmingActive'] = false;

                Objects['WalkFlag'].Visible = false;
                Objects['JumpFlag'].Visible = false;
                Objects['SwimmingFlag'].Visible = false;

                Data['Conns']['MoveDir'] = Humanoid:GetPropertyChangedSignal('MoveDirection'):Connect(function()
                    local Walking = Humanoid.MoveDirection ~= ZeroVector3;

                    if Walking and not Data['WalkActive'] then
                        Data['WalkActive'] = true;

                        if Data['JumpActive'] then
                            Objects['WalkFlag'].LayoutOrder = 2;
                        else
                            Objects['WalkFlag'].LayoutOrder = 1;
                            Objects['JumpFlag'].LayoutOrder = 2;
                        end

                        Objects['WalkFlag'].Visible = Table['Flags']['Walking']['Enabled']
                    elseif not Walking and Data['WalkActive'] then
                        Data['WalkActive'] = false;
                        Objects['WalkFlag'].Visible = false;

                        if Data['JumpActive'] then
                            Objects['JumpFlag'].LayoutOrder = 1;
                        end
                    end
                end)

                Data['Conns']['StateChange'] = Humanoid.StateChanged:Connect(function(_, NewState)
                    if NewState == Enum.HumanoidStateType.Freefall and not Data['JumpActive'] then
                        Data['JumpActive'] = true;

                        if Data['WalkActive'] then
                            Objects['JumpFlag'].LayoutOrder = 2;
                        else
                            Objects['JumpFlag'].LayoutOrder = 1;
                            Objects['WalkFlag'].LayoutOrder = 2;
                        end

                        Objects['JumpFlag'].Visible = Table['Flags']['Jumping']['Enabled']
                    elseif NewState ~= Enum.HumanoidStateType.Jumping and Data['JumpActive'] then
                        Data['JumpActive'] = false;
                        Objects['JumpFlag'].Visible = false;

                        if Data['WalkActive'] then
                            Objects['WalkFlag'].LayoutOrder = 1;
                        end
                    end

                    if NewState == Enum.HumanoidStateType.Swimming and not Data['SwimmingActive'] then
                        Data['SwimmingActive'] = true;
                        Objects['SwimmingFlag'].Visible = Table['Flags']['Swimming']['Enabled']
                    elseif NewState ~= Enum.HumanoidStateType.Swimming and Data['SwimmingActive'] then
                        Data['SwimmingActive'] = false;
                        Objects['SwimmingFlag'].Visible = false;
                    end
                end)
            end

            Data['BindFlags'] = FlagsHandler.BindFlags;
        end

        local CharacterHandler = {}; do
            function CharacterHandler.OnCharacter(Character)
                Data['Character'] = Character;
                Data['RootPart'] = nil;
                Data['Humanoid'] = nil;
                Data['Children'] = nil;
                Data['Alive'] = false;
                Data['WalkActive'] = false;
                Data['JumpActive'] = false;
                Data['FallingActive'] = false;
                Data['SwimmingActive'] = false;

                if not Character or not Character.Parent then
                    return;
                end;

                local RootPart = FindFirstChild(Character, "HumanoidRootPart");

                if not RootPart then
                    RootPart = Character:WaitForChild('HumanoidRootPart', 10);
                end

                local Humanoid = FindFirstChildOfClass(Character, 'Humanoid');

                if not Humanoid then
                    Humanoid = Character:WaitForChild('Humanoid', 10);
                end;

                if not RootPart or not Humanoid then
                    return;
                end;

                if not Character.Parent then
                    return;
                end;

                Data['RootPart'] = RootPart;
                Data['Humanoid'] = Humanoid;

                Data['BindChildren'](Character);
                Data['BindHealth'](Humanoid);
                Data['BindFlags'](Humanoid);
            end

            Data['Conns']['CharAdded'] = Player.CharacterAdded:Connect(function(Character)
                task.defer(CharacterHandler.OnCharacter, Character)
            end)

            if Player.Character and Player.Character.Parent then
                task.defer(CharacterHandler.OnCharacter, Player.Character)
            end
        end
    end

    getgenv().EspLibrary.RemoveTarget = function(self, Player)
        local Data = self['Cache'][Player];

        if not Data then
            return;
        end;

        for _, Connections in Data['Conns'] do
            Connections:Disconnect()
        end;

        Clear(Data['Conns']);

        if Data['Objects']['TargetHolder'] then
            Data['Objects']['TargetHolder']:Destroy();
        end;

        Clear(Data['Objects']);
        self['Cache'][Player] = nil;
    end

    getgenv().EspLibrary.Update = function(self, Player, Data)
        local Objects = Data['Objects']

        if not Data['RootPart'] then
            if Objects['TargetHolder'].Visible then
                Objects['TargetHolder'].Visible = false
            end
            return
        end

        if not Data['Alive'] then
            if Objects['TargetHolder'].Visible then
                Objects['TargetHolder'].Visible = false
            end
            return
        end

        local RootPos = Data['RootPart'].Position
        local Distance = Floor((CameraPosition - RootPos).Magnitude)

        if Distance > Table['Distance'] then
            if Objects['TargetHolder'].Visible then
                Objects['TargetHolder'].Visible = false
            end
            return
        end

        local W, H, X, Y, OnScreen = self:CalculateBox(Data)

        if not OnScreen or not W then
            if Objects['TargetHolder'].Visible then
                Objects['TargetHolder'].Visible = false
            end
            return
        end

        W = Floor(W)
        H = Floor(H)
        X = Floor(X)
        Y = Floor(Y)

        if not Objects['TargetHolder'].Visible then
            Objects['TargetHolder'].Visible = true
        end

        local DirtySizes = Data['LastW'] ~= W or Data['LastH'] ~= H
        local DirtyPosition = Data['LastX'] ~= X or Data['LastY'] ~= Y

        if DirtyPosition then
            Objects['TargetHolder'].Position = DimOffset(X, Y)
            Data['LastX'] = X
            Data['LastY'] = Y
        end

        if DirtySizes then
            Objects['TargetHolder'].Size = DimOffset(W, H)
            Objects['BoxGlow'].Size = DimOffset(W, H)
            Objects['BoxOutlineHolder'].Size = DimOffset(W, H)
            Objects['BoxInlineHolder'].Size = DimOffset(W + 2, H + 2)
            Objects['BoxFill'].Size = DimOffset(W, H)
            Objects['CornerHolder'].Size = DimOffset(W + 2, H + 2)
            Data['LastW'] = W
            Data['LastH'] = H
        end

        local BoxesCfg = Table['Boxes']
        local TextsCfg = Table['Texts']

        if BoxesCfg['Enabled'] then
            if BoxesCfg['Box Glow']['Enabled'] then
                if Objects['BoxGlow'].ImageTransparency ~= 0 then
                    Objects['BoxGlow'].ImageTransparency = 0
                end

                local GlowTop = BoxesCfg['Box Glow']['Top']
                local GlowBot = BoxesCfg['Box Glow']['Bot']

                if Data['LastGlowTop'] ~= GlowTop or Data['LastGlowBot'] ~= GlowBot then
                    Objects['BoxGlowGradient'].Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, GlowTop),
                        ColorSequenceKeypoint.new(1, GlowBot),
                    })
                    Data['LastGlowTop'] = GlowTop
                    Data['LastGlowBot'] = GlowBot
                end

                local T1 = BoxesCfg['Box Glow']['Transparency'][1]
                local T2 = BoxesCfg['Box Glow']['Transparency'][2]

                if Data['LastGlowT1'] ~= T1 or Data['LastGlowT2'] ~= T2 then
                    Objects['BoxGlowGradient'].Transparency = NumSeq({NumKey(0, T1), NumKey(1, T2)})
                    Data['LastGlowT1'] = T1
                    Data['LastGlowT2'] = T2
                end
            else
                if Objects['BoxGlow'].ImageTransparency ~= 1 then
                    Objects['BoxGlow'].ImageTransparency = 1
                end
            end

            local BoxType = BoxesCfg['Type']

            if BoxType == "Corner" then
                if Objects['BoxOutlineHolder'].Visible then
                    Objects['BoxOutlineHolder'].Visible = false
                end
                if Objects['BoxInlineHolder'].Visible then
                    Objects['BoxInlineHolder'].Visible = false
                end
                if Objects['BoxFill'].Visible then
                    Objects['BoxFill'].Visible = false
                end

                if not Objects['CornerHolder'].Visible then
                    Objects['CornerHolder'].Visible = true
                end

                local GradTop = BoxesCfg['Gradients']['Top']
                local GradBot = BoxesCfg['Gradients']['Bot']

                for i = 1, 8 do
                    local Line = Objects['Line_' .. i]
                    local Stroke = Line:FindFirstChildOfClass('UIStroke')
                    local LayoutEntry = CornerLayout[i]
                    local LPos, LSize, LAnchor, LRot = LayoutEntry[1], LayoutEntry[2], LayoutEntry[3], LayoutEntry[4]

                    Line.Position = LPos
                    Line.Size = LSize
                    Line.AnchorPoint = LAnchor
                    Line.Rotation = LRot
                    Line.BackgroundColor3 = GradTop
                    Line.BackgroundTransparency = 0
                    if Stroke then
                        Stroke.Color = GradTop
                    end
                    Line.Visible = true
                end
            else
                if Objects['CornerHolder'].Visible then
                    Objects['CornerHolder'].Visible = false
                end
                for i = 1, 8 do
                    if Objects['Line_' .. i].Visible then
                        Objects['Line_' .. i].Visible = false
                    end
                end

                if not Objects['BoxOutlineHolder'].Visible then
                    Objects['BoxOutlineHolder'].Visible = true
                end

                if not Objects['BoxInlineHolder'].Visible then
                    Objects['BoxInlineHolder'].Visible = true
                end

                local GradTop = BoxesCfg['Gradients']['Top']
                local GradBot = BoxesCfg['Gradients']['Bot']

                if Data['LastGradTop'] ~= GradTop or Data['LastGradBot'] ~= GradBot then
                    Objects['BoxInlineGradient'].Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, GradTop),
                        ColorSequenceKeypoint.new(1, GradBot),
                    })
                    Data['LastGradTop'] = GradTop
                    Data['LastGradBot'] = GradBot
                end

                if BoxesCfg['Filled']['Enabled'] then
                    if not Objects['BoxFill'].Visible then
                        Objects['BoxFill'].Visible = true
                    end

                    local FillTop = BoxesCfg['Filled']['Top']
                    local FillBot = BoxesCfg['Filled']['Bot']
                    local FillT1 = BoxesCfg['Filled']['Transparency'][1]
                    local FillT2 = BoxesCfg['Filled']['Transparency'][2]

                    if Data['LastFillTop'] ~= FillTop or Data['LastFillBot'] ~= FillBot then
                        Objects['BoxFillGradient'].Color = ColorSequence.new({
                            ColorSequenceKeypoint.new(0, FillTop),
                            ColorSequenceKeypoint.new(1, FillBot),
                        })
                        Data['LastFillTop'] = FillTop
                        Data['LastFillBot'] = FillBot
                    end

                    if Data['LastFillT1'] ~= FillT1 or Data['LastFillT2'] ~= FillT2 then
                        Objects['BoxFillGradient'].Transparency = NumSeq({NumKey(0, FillT1), NumKey(1, FillT2)})
                        Data['LastFillT1'] = FillT1
                        Data['LastFillT2'] = FillT2
                    end
                else
                    if Objects['BoxFill'].Visible then
                        Objects['BoxFill'].Visible = false
                    end
                end
            end
        else
            if Objects['BoxGlow'].ImageTransparency ~= 1 then
                Objects['BoxGlow'].ImageTransparency = 1
            end

            if Objects['BoxOutlineHolder'].Visible then
                Objects['BoxOutlineHolder'].Visible = false
            end

            if Objects['BoxInlineHolder'].Visible then
                Objects['BoxInlineHolder'].Visible = false
            end

            if Objects['BoxFill'].Visible then
                Objects['BoxFill'].Visible = false
            end

            if Objects['CornerHolder'].Visible then
                Objects['CornerHolder'].Visible = false
            end

            for i = 1, 8 do
                if Objects['Line_' .. i].Visible then
                    Objects['Line_' .. i].Visible = false
                end
            end
        end

        if TextsCfg['Name']['Enabled'] then
            if not Objects['TargetName'].Visible then
                Objects['TargetName'].Visible = true
            end

            local DisplayName = Player.DisplayName

            if Data['LastDisplayName'] ~= DisplayName then
                Objects['TargetName'].Text = DisplayName
                Data['LastDisplayName'] = DisplayName
            end

            local NameColor = TextsCfg['Name']['Color']

            if Data['LastNameColor'] ~= NameColor then
                Objects['TargetName'].TextColor3 = NameColor
                Data['LastNameColor'] = NameColor
            end
        else
            if Objects['TargetName'].Visible then
                Objects['TargetName'].Visible = false
            end
        end

        if TextsCfg['Distance']['Enabled'] then
            if not Objects['Distance'].Visible then
                Objects['Distance'].Visible = true
            end

            if Data['LastDist'] ~= Distance then
                Objects['Distance'].Text = Format('%dst', Distance)
                Data['LastDist'] = Distance
            end

            local DistColor = TextsCfg['Distance']['Color']

            if Data['LastDistColor'] ~= DistColor then
                Objects['Distance'].TextColor3 = DistColor
                Data['LastDistColor'] = DistColor
            end
        else
            if Objects['Distance'].Visible then
                Objects['Distance'].Visible = false
            end
        end

        local HealthCfg = Table['Bars']['Health Bar']
        local ArmorCfg = Table['Bars']['Armor Bar']

        if HealthCfg['Enabled'] then
            local Health = Data['Health'] or 0
            local MaxHealth = Data['MaxHealth'] or 100
            local Ratio = Clamp(Health / MaxHealth, 0, 1)

            if not Objects['LeftBarHolder'].Visible then
                Objects['LeftBarHolder'].Visible = true
            end

            if not Objects['HealthBarOutline'].Visible then
                Objects['HealthBarOutline'].Visible = true
            end

            if Data['LastRatio'] ~= Ratio then
                Objects['HealthBar'].Size = Dim2(1, 0, Ratio, 0)
                Data['LastRatio'] = Ratio
            end

            local GradTop = HealthCfg['Top']
            local GradMid = HealthCfg['Middle']
            local GradBot = HealthCfg['Bot']

            if Data['LastHealthTop'] ~= GradTop or Data['LastHealthMiddle'] ~= GradMid or Data['LastHealthBot'] ~= GradBot then
                Objects['HealthBarGradient'].Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, GradTop),
                    ColorSequenceKeypoint.new(0.5, GradMid),
                    ColorSequenceKeypoint.new(1, GradBot),
                })
                Data['LastHealthTop'] = GradTop
                Data['LastHealthMiddle'] = GradMid
                Data['LastHealthBot'] = GradBot
            end

            if HealthCfg['Enabled'] then
                if not Objects['HealthBarText'].Visible then
                    Objects['HealthBarText'].Visible = true
                end

                local FlooredHealth = Floor(Health)

                if Data['LastHealthFloor'] ~= FlooredHealth then
                    Objects['HealthBarText'].Text = Format('%d', FlooredHealth)
                    Objects['HealthBarText'].Position = Dim2(1, -10, 1 - Ratio, 1)
                    Data['LastHealthFloor'] = FlooredHealth
                end
            else
                if Objects['HealthBarText'].Visible then
                    Objects['HealthBarText'].Visible = false
                end
            end
        else
            if Objects['HealthBarOutline'].Visible then
                Objects['HealthBarOutline'].Visible = false
            end

            if Objects['HealthBarText'].Visible then
                Objects['HealthBarText'].Visible = false
            end

            if not ArmorCfg['Enabled'] then
                if Objects['LeftBarHolder'].Visible then
                    Objects['LeftBarHolder'].Visible = false
                end
            end
        end

        if ArmorCfg['Enabled'] then
            local Ratio = Clamp(Data['Armor'] / Data['MaxArmor'], 0, 1)

            if not Objects['BottomBarHolder'].Visible then
                Objects['BottomBarHolder'].Visible = true
            end

            if not Objects['ArmorBarOutline'].Visible then
                Objects['ArmorBarOutline'].Visible = true
            end

            if Data['LastArmorRatio'] ~= Ratio then
                Objects['ArmorBar'].Size = Dim2(Ratio, 0, 1, 0)
                Data['LastArmorRatio'] = Ratio
            end

            local GradTop = ArmorCfg['Top']
            local GradMid = ArmorCfg['Middle']
            local GradBot = ArmorCfg['Bot']

            if Data['LastArmorTop'] ~= GradTop or Data['LastArmorMiddle'] ~= GradMid or Data['LastArmorBot'] ~= GradBot then
                Objects['ArmorBarGradient'].Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, GradTop),
                    ColorSequenceKeypoint.new(0.5, GradMid),
                    ColorSequenceKeypoint.new(1, GradBot),
                })
                Data['LastArmorTop'] = GradTop
                Data['LastArmorMiddle'] = GradMid
                Data['LastArmorBot'] = GradBot
            end

            if Ratio < 1 then
                if not Objects['ArmorBarText'].Visible then
                    Objects['ArmorBarText'].Visible = true
                end

                local FlooredArmor = Floor(Data['Armor'])

                if Data['LastArmorFloor'] ~= FlooredArmor then
                    Objects['ArmorBarText'].Text = Format('%d', FlooredArmor)
                    Data['LastArmorFloor'] = FlooredArmor
                end
            else
                if Objects['ArmorBarText'].Visible then
                    Objects['ArmorBarText'].Visible = false
                end
            end
        else
            if Objects['BottomBarHolder'].Visible then
                Objects['BottomBarHolder'].Visible = false
            end

            if Objects['ArmorBarOutline'].Visible then
                Objects['ArmorBarOutline'].Visible = false
            end

            if Objects['ArmorBarText'].Visible then
                Objects['ArmorBarText'].Visible = false
            end
        end

        local WeaponCfg = TextsCfg['Weapon']

        if WeaponCfg['Enabled'] then
            if not Objects['Weapon'].Visible then
                Objects['Weapon'].Visible = true
            end

            local CurrentTool = Data['CurrentTool'] or 'none'

            if Data['LastWeapon'] ~= CurrentTool then
                Objects['Weapon'].Text = CurrentTool
                Data['LastWeapon'] = CurrentTool
            end

            local WeaponColor = WeaponCfg['Color']

            if Data['LastWeaponColor'] ~= WeaponColor then
                Objects['Weapon'].TextColor3 = WeaponColor
                Data['LastWeaponColor'] = WeaponColor
            end
        else
            if Objects['Weapon'].Visible then
                Objects['Weapon'].Visible = false
            end
        end
    end

    do
        getgenv().EspLibrary:CreateThreads('Renderer', RunService.RenderStepped, function()
            if not Table['Enabled'] then
                for _, Data in getgenv().EspLibrary['Cache'] do
                    if Data['Objects']['TargetHolder'].Visible then
                        Data['Objects']['TargetHolder'].Visible = false
                    end;
                end;
                return
            end;

            local Now = os.clock();

            if Now - Updates < Frame then
                return;
            end;

            Updates = Now;
            CameraPosition = Camera.CFrame.Position;

            for Player, Data in getgenv().EspLibrary['Cache'] do
                getgenv().EspLibrary:Update(Player, Data)
            end
        end)
    end

    do
        for _, Player in Players:GetPlayers() do
            getgenv().EspLibrary:AddTarget(Player)
        end

        getgenv().EspLibrary:CreateThreads('PlayerAdded', Players.PlayerAdded, function(Player)
            getgenv().EspLibrary:AddTarget(Player)
        end)

        getgenv().EspLibrary:CreateThreads('PlayerRemoving', Players.PlayerRemoving, function(Player)
            getgenv().EspLibrary:RemoveTarget(Player)
        end)
    end

    do
        getgenv().EspLibrary.Unload = function(self)
            for Player in self['Cache'] do
                self:RemoveTarget(Player);
            end;

            for _, Conn in self['Connections'] do
                Conn:Disconnect();
            end;

            Clear(self['Connections']);

            for _, Conn in self['Threads'] do
                Conn:Disconnect();
            end;

            Clear(self['Threads']);

            if self['Holder'] then
                self['Holder']:Destroy();
                self['Holder'] = nil;
            end;

            Clear(self['Cache']);
        end
    end
end

do
    local Players = getgenv().Players
    local LocalPlayer = getgenv().LocalPlayer
    local RunService = getgenv().RunService

    local KnifeGb = getgenv().KnifeGb
    KnifeGb:AddToggle('KnifeHitbox', { Text = 'hitbox expander for knife', Default = false })
    KnifeGb:AddToggle('KnifeHitboxVis', { Text = 'hitbox visualizer', Default = false })
    KnifeGb:AddToggle('KnifeAutoSwing', { Text = 'auto swing knife', Default = false })
    KnifeGb:AddToggle('KnifeGlue', { Text = 'glue connection', Default = false })
        :AddKeyPicker('KnifeGlueKey', { Default = 'G', Mode = 'Toggle', Text = 'Glue', SyncToggleState = true, NoUI = false })
    KnifeGb:AddDropdown('KnifeAttachPos', { Text = 'Attach Position', Default = 'HumanoidRootPart', Values = { 'HumanoidRootPart', 'UpperTorso', 'LowerTorso', 'Head', 'Torso' } })
    KnifeGb:AddSlider('KnifeDistance', { Text = 'Distance', Default = 3, Min = 0, Max = 20, Rounding = 0 })
    KnifeGb:AddSlider('KnifeMaxConn', { Text = 'Max Connection Distance', Default = 100, Min = 0, Max = 500, Rounding = 0 })
    KnifeGb:AddSlider('KnifeMinHealth', { Text = 'Minimum Target Health', Default = 0, Min = 0, Max = 100, Rounding = 0 })
    KnifeGb:AddToggle('KnifeTargetStatus', { Text = 'target status', Default = false })
    KnifeGb:AddDropdown('KnifeSelectPlayer', { SpecialType = 'Player', Text = 'Select Player' })

    local function tv(n) local t = Toggles[n] ; return t and t.Value end
    local function ov(n) local o = Options[n] ; return o and o.Value end

    local HITBOX_SIZE = Vector3.new(50, 50, 50)

    local function findKnife(parent)
        if not parent then return nil end
        for _, t in ipairs(parent:GetChildren()) do
            if t:IsA('Tool') and string.lower(t.Name) == '[knife]' then return t end
        end
    end

    local function getKnifeHitbox()
        local knife = findKnife(LocalPlayer.Character) or findKnife(LocalPlayer:FindFirstChild('Backpack'))
        if not knife then return nil end
        local handle = knife:FindFirstChild('Handle')
        local hb = handle and handle:FindFirstChild('HITBOX_PART')
        if hb and hb:IsA('BasePart') then return hb end
        return nil
    end

    task.spawn(function()
        while task.wait(0.1) do
            if not tv('KnifeGlue') then continue end
            local hb = getKnifeHitbox()
            if hb then
                if tv('KnifeHitbox') then
                    if hb:GetAttribute('LarpticOrigSize') == nil then
                        hb:SetAttribute('LarpticOrigSize', hb.Size)
                    end
                    hb.Size = HITBOX_SIZE
                    hb.CanCollide = false
                end
                if tv('KnifeHitboxVis') then
                    hb.Transparency = 0.6
                    hb.Material = Enum.Material.ForceField
                    hb.Color = Color3.fromRGB(0, 170, 255)
                else
                    hb.Transparency = 1
                end
            end
        end
    end)

    local function getTargetPart()
        local name = ov('KnifeSelectPlayer')
        local plr = (name and name ~= '' and Players:FindFirstChild(name)) or getgenv().ForceHitTarget
        if not plr or plr == LocalPlayer then return nil end
        local char = plr.Character
        if not char then return nil end
        
        -- Ignore fully dead players
        if getgenv().isFullyDead and getgenv().isFullyDead(plr) then return nil end
        
        local hum = char:FindFirstChildOfClass('Humanoid')
        -- Keep targeting if they are knocked (health is 0 but they have the KO state)
        if hum and hum.Health <= 0 and not (char:FindFirstChild("BodyEffects") and char.BodyEffects:FindFirstChild("K.O") and char.BodyEffects["K.O"].Value) then 
            return nil 
        end
        
        local minHp = ov('KnifeMinHealth') or 0
        if hum and minHp > 0 and hum.Health < minHp then return nil end
        return char:FindFirstChild(ov('KnifeAttachPos') or 'HumanoidRootPart') or char:FindFirstChild('HumanoidRootPart')
    end

    local function equipKnife()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass('Humanoid')
        if not hum then return nil end
        local knife = findKnife(char)
        if knife then return knife end
        local bpKnife = findKnife(LocalPlayer:FindFirstChild('Backpack'))
        if bpKnife then
            pcall(function() hum:EquipTool(bpKnife) end)
            return char:FindFirstChild(bpKnife.Name) or bpKnife
        end
        return nil
    end

    task.spawn(function()
        while task.wait() do
            if tv('KnifeGlue') and tv('KnifeAutoSwing') then
                local knife = equipKnife()
                local name = ov('KnifeSelectPlayer')
                local targetPlr = (name and name ~= '' and Players:FindFirstChild(name)) or getgenv().ForceHitTarget
                local targetIsKO = targetPlr and getgenv().isKO and getgenv().isKO(targetPlr)
                
                local target = getTargetPart()
                local char = LocalPlayer.Character
                local root = char and char:FindFirstChild('HumanoidRootPart')
                
                if target and root and not targetIsKO then
                    pcall(function() root:SetNetworkOwner(LocalPlayer) end)
                    local dist = ov('KnifeDistance') or 3
                    local targetPos = target.Position
                    local dir = (root.Position - targetPos)
                    dir = (dir.Magnitude > 0.1) and dir.Unit or Vector3.new(0, 0, 1)
                    pcall(function()
                        root.CFrame = CFrame.lookAt(targetPos + dir * dist, targetPos)
                        root.AssemblyLinearVelocity = Vector3.zero
                    end)
                end

                if targetIsKO then
                    getgenv().MainEvent:FireServer("Stomp")
                elseif knife then
                    pcall(function() knife:Activate() end)
                end
            else
                task.wait(0.1)
            end
        end
    end)

    local function glueTarget()
        local part = getTargetPart()
        if not part then return nil end

        -- Break glue connection when target is knocked down
        local name = ov('KnifeSelectPlayer')
        local targetPlr = (name and name ~= '' and Players:FindFirstChild(name)) or getgenv().ForceHitTarget
        if targetPlr and getgenv().isKO and getgenv().isKO(targetPlr) then
            return nil
        end

        local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart')
        local maxConn = ov('KnifeMaxConn') or 0
        if myRoot and maxConn > 0 and (part.Position - myRoot.Position).Magnitude > maxConn then return nil end
        return part
    end

    getgenv().KnifeGlueConn = RunService.Heartbeat:Connect(function()
        if not tv('KnifeGlue') then return end
        if not sethiddenproperty then return end
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass('Humanoid')
        local root = hum and hum.RootPart
        if not root then return end
        local target = glueTarget()
        pcall(function() sethiddenproperty(root, "PhysicsRepRootPart", target) end)
    end)

    if Toggles.KnifeGlue then
        Toggles.KnifeGlue:OnChanged(function()
            if not Toggles.KnifeGlue.Value then
                if sethiddenproperty then
                    local char = LocalPlayer.Character
                    local hum = char and char:FindFirstChildOfClass('Humanoid')
                    local root = hum and hum.RootPart
                    if root then pcall(function() sethiddenproperty(root, "PhysicsRepRootPart", nil) end) end
                end
                local hb = getKnifeHitbox()
                if hb then
                    local orig = hb:GetAttribute('LarpticOrigSize')
                    if typeof(orig) == 'Vector3' then hb.Size = orig end
                    hb.Transparency = 1
                end
            end
        end)
    end
end

--==============================================================================
--  HvH TAB: RAGEBOT
--  Ported from the supplied ragebot: closest-enemy targeting, katana deflect
--  tracking, per-frame desync + direct UseItem fire.  Everything is gated and
--  pcall'd so it simply stays idle in games without the fighter controllers.
--  Lives in the HvH tab with the rest of the combat tooling.
--==============================================================================
do
    local cloneref = cloneref or function(o) return o end
    local RB_RS   = cloneref(game:GetService('ReplicatedStorage'))
    local RB_PLRS = cloneref(game:GetService('Players'))
    local RB_RUN  = cloneref(game:GetService('RunService'))
    local RB_WS   = cloneref(game:GetService('Workspace'))
    local rb_lp   = RB_PLRS.LocalPlayer

    local RageGb      = getgenv().Pages.Rage:AddLeftGroupbox('Ragebot')
    local RageFootGb  = getgenv().Pages.Rage:AddLeftGroupbox('Ragebot Status')
    local RageCheckGb = getgenv().Pages.Rage:AddRightGroupbox('Ragebot Behaviour')

    RageGb:AddToggle('RagebotEnabled', { Text = 'Enable Ragebot', Default = false })
    RageGb:AddSlider('RagebotFireDelay', { Text = 'Fire Delay (ms)', Default = 0, Min = 0, Max = 20, Rounding = 0 })
    RageGb:AddDropdown('RagebotWeaponSlot', { Text = 'Weapon Slot', Values = { 'Primary', 'Secondary', 'Melee' }, Default = 3 })
    RageGb:AddToggle('RagebotAutoEquip', { Text = 'Keep Slot Equipped', Default = true })
    RageCheckGb:AddToggle('RagebotDesync', { Text = 'Desync Position', Default = true })
    RageCheckGb:AddToggle('RagebotAntiKatana', { Text = 'Skip Deflecting Targets', Default = true })
    RageCheckGb:AddToggle('RagebotTeamCheck', { Text = 'Team Check', Default = true })
    RageCheckGb:AddToggle('RagebotNotify', { Text = 'Notify On Lock', Default = false })
    RageCheckGb:AddSlider('RagebotMaxDistance', { Text = 'Max Distance', Default = 500, Min = 50, Max = 2000, Rounding = 0 })

    local statusLabel = RageFootGb:AddLabel('ragebot: idle')

    local rbUtil, rbEnum, FighterController, SpectateController
    local ragebotReady = pcall(function()
        local playerScripts = rb_lp:WaitForChild('PlayerScripts', 10)
        local controllers = playerScripts and playerScripts:WaitForChild('Controllers', 10)
        if not controllers then error('no controllers') end
        rbUtil = require(RB_RS.Modules.Utility)
        rbEnum = require(RB_RS.Modules.EnumLibrary)
        FighterController = require(controllers.FighterController)
        SpectateController = require(controllers:WaitForChild('SpectateController', 10))
    end)

    if not (ragebotReady and rbUtil and rbEnum and FighterController) then
        statusLabel:SetText('ragebot: fighter controllers not present in this game (inert)')
    else
        local slots = { Primary = 1, Secondary = 2, Melee = 3 }
        local deflecting = {}
        local lastFire = 0
        local lastLock = nil
        local restoreName = 'lunar_ragebot_restore'

        -- The status label is written from the heartbeat, so only touch the TextLabel
        -- when the text actually changes - a per-frame write forces the GUI to relayout
        -- 60 times a second for no reason.
        local lastStatus
        local function setStatus(text)
            if text == lastStatus then return end
            lastStatus = text
            statusLabel:SetText(text)
        end

        -- The desync used to BindToRenderStep a fresh closure on every heartbeat and
        -- unbind it again from inside the render callback.  Bind it once instead: same
        -- restore, without allocating and re-sorting the render step list 60x a second.
        local savedRoot, savedCF, savedVel, savedRot
        local restoreBound = false
        local function ensureRestoreBound()
            if restoreBound then return end
            restoreBound = true
            RB_RUN:BindToRenderStep(restoreName, 101, function()
                if savedRoot and savedRoot.Parent then
                    savedRoot.CFrame = savedCF
                    savedRoot.Velocity = savedVel
                    savedRoot.RotVelocity = savedRot
                end
            end)
        end
        getgenv().Library:OnUnload(function()
            if restoreBound then
                restoreBound = false
                pcall(function() RB_RUN:UnbindFromRenderStep(restoreName) end)
            end
        end)

        local function val(name)
            local o = Options[name]
            return o and o.Value
        end

        local function on(name)
            local t = Toggles[name]
            return t and t.Value
        end

        local function getSlotNumber()
            return slots[tostring(val('RagebotWeaponSlot') or 'Melee')] or 3
        end

        RB_PLRS.PlayerRemoving:Connect(function(player) deflecting[player] = nil end)

        local function updateDeflection()
            local objects = FighterController.Objects
            if not objects then return end
            for _, fighterObj in objects do
                local player = fighterObj and fighterObj.Player
                if player then
                    local entity = fighterObj.Entity
                    if (not entity) or (not entity:IsAlive()) or fighterObj:Get('IsSpectating') then
                        deflecting[player] = false
                    else
                        local equipped = fighterObj.EquippedItem
                        local viewModel = equipped and equipped.ViewModel
                        local isKatana = viewModel and viewModel.Name == 'Katana'
                        local isDeflecting = false
                        if isKatana and equipped._attack_cooldown then
                            isDeflecting = equipped._attack_cooldown > tick()
                        end
                        deflecting[player] = isDeflecting
                    end
                end
            end
        end

        local function isEnemy(player)
            if player == rb_lp then return false end
            if not on('RagebotTeamCheck') then return true end
            local duel = SpectateController and SpectateController.CurrentDuelSubject
            local localDueler = duel and duel:GetDueler(rb_lp)
            local localTeam = localDueler and localDueler:Get('TeamID')
            if localTeam and duel and duel.Duelers then
                for _, dueler in duel.Duelers do
                    if dueler.Player == player then
                        return dueler:Get('TeamID') ~= localTeam
                    end
                end
            end
            local playerTeam = player:GetAttribute('TeamID')
            local myTeam = rb_lp:GetAttribute('TeamID')
            if playerTeam and myTeam then return playerTeam ~= myTeam end
            return true
        end

        local function getClosestTarget()
            local char = rb_lp.Character
            local myRoot = char and char:FindFirstChild('HumanoidRootPart')
            if not myRoot then return nil end
            local maxDist = tonumber(val('RagebotMaxDistance')) or 500
            local closest, closestRoot, closestHead, closestDist = nil, nil, nil, maxDist
            for _, player in ipairs(RB_PLRS:GetPlayers()) do
                if isEnemy(player) then
                    local pChar = player.Character
                    if pChar then
                        local pRoot = pChar:FindFirstChild('HumanoidRootPart')
                        local pHead = pChar:FindFirstChild('Head')
                        local pHum = pChar:FindFirstChildWhichIsA('Humanoid')
                        if pRoot and pHead and pHum and pHum.Health > 0 then
                            local dist = (myRoot.Position - pRoot.Position).Magnitude
                            if dist < closestDist then
                                closestDist = dist
                                closest = player
                                closestRoot = pRoot
                                closestHead = pHead
                            end
                        end
                    end
                end
            end
            return closest, closestRoot, closestHead
        end

        local function hasKnifeViewModel(targetPlayer)
            if not targetPlayer then return false end
            local viewModels = RB_WS:FindFirstChild('ViewModels')
            if not viewModels then return false end
            local targetName = targetPlayer.Name
            for _, model in ipairs(viewModels:GetChildren()) do
                if model:IsA('Model')
                    and string.find(model.Name, targetName, 1, true)
                    and string.find(model.Name, 'Knife', 1, true) then
                    return true
                end
            end
            return false
        end

        task.spawn(function()
            while task.wait(1) do
                if on('RagebotEnabled') and on('RagebotAutoEquip') then
                    local fighter = FighterController.LocalFighter
                    if fighter then pcall(function() fighter:EquipItem(getSlotNumber()) end) end
                end
            end
        end)

        getgenv().RagebotConn = RB_RUN.Heartbeat:Connect(function()
            -- start each frame unpinned; only a frame that actually desyncs re-arms the
            -- restore, so switching the ragebot off cannot leave the character frozen
            savedRoot = nil
            if not on('RagebotEnabled') then return end
            local fighter = FighterController.LocalFighter
            if not fighter then return end

            pcall(updateDeflection)

            local targetPlayer, targetRoot, targetHead = getClosestTarget()
            if not (targetPlayer and targetRoot and targetHead) then
                lastLock = nil
                setStatus('ragebot: no target')
                return
            end
            if on('RagebotAntiKatana') and deflecting[targetPlayer] then
                setStatus('ragebot: ' .. targetPlayer.Name .. ' deflecting')
                return
            end

            local char = rb_lp.Character
            local myRoot = char and char:FindFirstChild('HumanoidRootPart')
            if not myRoot then return end

            local desyncCF
            if on('RagebotDesync') then
                local desyncPos
                if hasKnifeViewModel(targetPlayer) then
                    desyncPos = (targetRoot.CFrame * CFrame.new(0, 6, 0)).Position
                else
                    desyncPos = (targetRoot.CFrame * CFrame.new(0, 1, 2)).Position
                end
                desyncCF = CFrame.lookAt(desyncPos, targetHead.Position)
                if desyncCF.X == desyncCF.X then
                    savedRoot, savedCF, savedVel, savedRot = myRoot, myRoot.CFrame, myRoot.Velocity, myRoot.RotVelocity
                    ensureRestoreBound()
                    myRoot.CFrame = desyncCF
                else
                    desyncCF = nil
                end
            else
                -- stop rewriting the saved CFrame, or the render step would pin the
                -- character in place after the toggle is switched off
                savedRoot = nil
            end

            local item = fighter.EquippedItem
            if not item then
                setStatus('ragebot: no weapon equipped')
                return
            end

            -- a 0ms delay used to mean "fire on every single heartbeat", which floods
            -- the server with UseItem remotes 60 times a second; keep a floor on it
            local fireRate = math.max((tonumber(val('RagebotFireDelay')) or 0) / 1000, 0.05)
            if tick() - lastFire < fireRate then return end
            lastFire = tick()

            local originPos = desyncCF and desyncCF.Position or targetRoot.Position
            local targetPos = targetHead.Position
            local aimCF = CFrame.lookAt(originPos, targetPos)
            local targetCF = targetHead.CFrame
            local randomOffset = Vector3.new(
                (math.random() - 0.5) * 0.1,
                (math.random() - 0.5) * 0.1,
                (math.random() - 0.5) * 0.1
            )
            local aimedPos = targetPos + randomOffset
            local objSpaceHeadOffset = targetHead.CFrame:ToObjectSpace(CFrame.new(aimedPos))
            local cameradata = {}
            cameradata[utf8.char(1)] = {
                [utf8.char(0)] = rbUtil:EncodeCFrame(aimCF),
                [utf8.char(1)] = rbUtil:EncodeCFrame(targetCF),
                [utf8.char(2)] = targetHead,
                [utf8.char(3)] = rbUtil:EncodeCFrame(objSpaceHeadOffset),
            }
            pcall(function()
                RB_RS.Remotes.Replication.Fighter.UseItem:FireServer(
                    item:Get('ObjectID'),
                    rbEnum:ToEnum('StartShooting'),
                    cameradata,
                    nil
                )
            end)
            setStatus('ragebot: firing at ' .. targetPlayer.Name)
            if on('RagebotNotify') and lastLock ~= targetPlayer then
                lastLock = targetPlayer
                getgenv().Library:Notify('Ragebot locked: ' .. targetPlayer.Name, 1.5)
            end
        end)
    end
end

--==============================================================================
--  MISC TAB: RIVALS EXTRAS
--  Portable pieces from the supplied Rivals scripts: device spoof, map vote,
--  auto queue, auto loadout, no spread / force-modifier full auto and POV.
--  These are automation / utility rather than combat, so they sit in Misc.
--==============================================================================
do
    local cloneref = cloneref or function(o) return o end
    local RV_RS   = cloneref(game:GetService('ReplicatedStorage'))
    local RV_PLRS = cloneref(game:GetService('Players'))
    local RV_RUN  = cloneref(game:GetService('RunService'))
    local rv_lp   = RV_PLRS.LocalPlayer
    local remotes = RV_RS:FindFirstChild('Remotes')

    local DeviceGb  = getgenv().Pages.Automation:AddRightGroupbox('Device Spoof')
    local MatchGb   = getgenv().Pages.Automation:AddRightGroupbox('Matchmaking')
    local LoadoutGb = getgenv().Pages.Automation:AddRightGroupbox('Auto Loadout')
    local GunGb     = getgenv().Pages.Movement:AddRightGroupbox('Gun & Camera')

    local function val(name) local o = Options[name] ; return o and o.Value end
    local function on(name) local t = Toggles[name] ; return t and t.Value end

    DeviceGb:AddToggle('DeviceSpoofEnabled', { Text = 'Enable Device Spoof', Default = false })
    DeviceGb:AddDropdown('DeviceSpoofType', { Text = 'Report as', Values = { 'Touch', 'MouseKeyboard', 'Gamepad', 'VR' }, Default = 1 })
    DeviceGb:AddToggle('MobileAutoTarget', { Text = 'Mobile Auto Target', Default = getgenv().IsMobile == true })

    MatchGb:AddToggle('AutoVoteEnabled', { Text = 'Auto Vote Map', Default = false })
    MatchGb:AddDropdown('AutoVoteMap', {
        Text = 'Map',
        Values = { 'Arena', 'Big Graveyard', 'Docks', 'Splash', 'Bridge', 'Crossroads', 'Big Crossroads', 'Big Backrooms', 'Battleground', 'Big Arena', 'Construction', 'Playground', 'Onyx', 'Graveyard', 'Big Splash', 'Big Onyx', 'Backrooms', 'Station', 'Dimension' },
        Default = 1,
    })
    MatchGb:AddToggle('AutoQueueEnabled', { Text = 'Auto Queue', Default = false })
    MatchGb:AddDropdown('AutoQueueMode', { Text = 'Queue', Values = { '1v1', '2v2', '3v3', '4v4', '5v5', '2v2_beginner' }, Default = 1 })

    LoadoutGb:AddToggle('AutoLoadoutEnabled', { Text = 'Auto Pick Weapons', Default = false })
    LoadoutGb:AddDropdown('AutoLoadoutPrimary', {
        Text = 'Primary',
        Values = { 'Crossbow', 'Grenade Launcher', 'Brust Rifle', 'Distortion', 'Flamethrower', 'Shotgun', 'RPG', 'Assault Rifle', 'Sniper', 'Minigun', 'Energy Rifle', 'Paintball Gun', 'Bow', 'Gunblade' },
        Default = 'Assault Rifle',
    })
    LoadoutGb:AddDropdown('AutoLoadoutSecondary', {
        Text = 'Secondary',
        Values = { 'Slingshot', 'Flare Gun', 'Spray', 'Shorty', 'Energy Pistols', 'Warper', 'Daggers', 'Scepter', 'Exogun', 'Revolver', 'Uzi', 'Glass Cannon', 'Handgun' },
        Default = 'Handgun',
    })
    LoadoutGb:AddDropdown('AutoLoadoutMelee', {
        Text = 'Melee',
        Values = { 'Fists', 'Scythe', 'Battle Axe', 'Trowel', 'Riot Shield', 'Glast Shard', 'Knife', 'Chainsaw', 'Katana' },
        Default = 'Fists',
    })
    LoadoutGb:AddDropdown('AutoLoadoutUtility', {
        Text = 'Utility',
        Values = { 'Medkit', 'Flashbang', 'Elixir', 'Subspace Tripmine', 'War Horn', 'Grenade', 'Warpstone', 'Molotov', 'Freeze Ray', 'RNG Dice', 'Smoke Grenade', 'Jump Pad', 'Satchel' },
        Default = 'Grenade',
    })

    GunGb:AddToggle('NoSpreadEnabled', { Text = 'No Spread', Default = false })
    GunGb:AddToggle('FullAutoEnabled', { Text = 'Full Auto', Default = false })
    GunGb:AddToggle('ThirdPersonEnabled', { Text = 'Force Third Person', Default = false })

    local gunModule, katanaModule, itemLibrary
    pcall(function() gunModule = require(rv_lp.PlayerScripts.Modules.ItemTypes.Gun) end)
    pcall(function() katanaModule = require(rv_lp.PlayerScripts.Modules.ItemTypes.Katana) end)
    pcall(function() itemLibrary = require(RV_RS.Modules.ItemLibrary) end)

    if gunModule and type(gunModule.StartShooting) == 'function' then
        local oldStartShooting = gunModule.StartShooting
        gunModule.StartShooting = function(controller, is_empty, debounce)
            local clientFighter = controller.ClientFighter
            if not clientFighter or not clientFighter.IsLocalPlayer then
                return oldStartShooting(controller, is_empty, debounce)
            end
            if not is_empty and controller:Get('Ammo') <= 0 then return false end
            local results = { oldStartShooting(controller, is_empty, debounce) }
            if clientFighter.EquippedItem and on('NoSpreadEnabled') then results[4] = true end
            return table.unpack(results)
        end
    end

    local forceAutoOriginals = {}
    local function applyFullAuto(enabled)
        if not (itemLibrary and itemLibrary.Items) then return end
        for name, item in pairs(itemLibrary.Items) do
            if item and item.InputSpammingEnabled then
                if enabled then
                    if forceAutoOriginals[name] == nil then
                        forceAutoOriginals[name] = item.InputSpammingEnabled.StartShooting
                    end
                    pcall(function() item.InputSpammingEnabled.StartShooting = true end)
                elseif forceAutoOriginals[name] ~= nil then
                    pcall(function() item.InputSpammingEnabled.StartShooting = forceAutoOriginals[name] end)
                end
            end
        end
        if not enabled then table.clear(forceAutoOriginals) end
    end

    -- device spoof / matchmaking loops, all throttled
    task.spawn(function()
        while task.wait(0.5) do
            if on('DeviceSpoofEnabled') and remotes then
                pcall(function()
                    remotes.Replication.Fighter.SetControls:FireServer(tostring(val('DeviceSpoofType') or 'Touch'))
                end)
            end
        end
    end)

    task.spawn(function()
        while task.wait(1) do
            if on('AutoVoteEnabled') and remotes then
                pcall(function() remotes.Duels.Vote:FireServer(tostring(val('AutoVoteMap') or 'Arena')) end)
            end
        end
    end)

    task.spawn(function()
        while task.wait(2) do
            if on('AutoQueueEnabled') and remotes then
                local mode = tostring(val('AutoQueueMode') or '1v1')
                pcall(function() remotes.Matchmaking.JoinQueue:InvokeServer(mode) end)
            end
        end
    end)

    task.spawn(function()
        while task.wait(2.5) do
            if on('AutoLoadoutEnabled') and remotes then
                pcall(function()
                    remotes.Replication.Fighter.PickWeapons:FireServer({
                        tostring(val('AutoLoadoutPrimary') or 'Assault Rifle'),
                        tostring(val('AutoLoadoutSecondary') or 'Handgun'),
                        tostring(val('AutoLoadoutMelee') or 'Fists'),
                        tostring(val('AutoLoadoutUtility') or 'Grenade'),
                    })
                end)
            end
        end
    end)

    local cameraController
    local function ensureCameraController()
        if cameraController then return cameraController end
        pcall(function() cameraController = require(rv_lp.PlayerScripts.Controllers.CameraController) end)
        return cameraController
    end

    task.spawn(function()
        while task.wait(0.75) do
            local cam = ensureCameraController()
            local want = on('ThirdPersonEnabled') == true
            if cam then
                if want then
                    if cam.CameraState:GetPublicState() ~= cam.CameraState.States.ThirdPerson then
                        pcall(function() cam.CameraState:TogglePOV() end)
                    end
                end
                pcall(function() cam:SetThirdPersonOverride(want) end)
            end
        end
    end)

    getgenv().Library:OnUnload(function()
        pcall(function() applyFullAuto(false) end)
    end)
end

--==============================================================================
--  SKINS TAB
--  Every skinning feature in one place: the Da Hood visual gun / knife skin
--  changer plus the Rivals unlock-all + server-side cosmetic changer.
--  Hooks are installed once and gated by the toggle.
--==============================================================================
do
    local cloneref = cloneref or function(o) return o end
    local SK_PLRS = cloneref(game:GetService('Players'))
    local SK_RS   = cloneref(game:GetService('ReplicatedStorage'))
    local SK_HTTP = cloneref(game:GetService('HttpService'))
    local sk_lp   = SK_PLRS.LocalPlayer

    local UnlockGb = getgenv().Tabs.Skins:AddRightGroupbox('Unlocker')
    local SkinGb   = getgenv().Tabs.Skins:AddRightGroupbox('Cosmetic Changer')

    local function val(name) local o = Options[name] ; return o and o.Value end
    local function on(name) local t = Toggles[name] ; return t and t.Value end
    local function unlockActive() return on('UnlockAllCosmetics') == true end

    local EnumLibrary, CosmeticLibrary, ItemLibrary, DataController
    local skinsReady = pcall(function()
        local playerScripts = sk_lp:WaitForChild('PlayerScripts', 10)
        local controllers = playerScripts and playerScripts:WaitForChild('Controllers', 10)
        if not controllers then error('no controllers') end
        EnumLibrary = require(SK_RS.Modules.EnumLibrary)
        CosmeticLibrary = require(SK_RS.Modules.CosmeticLibrary)
        ItemLibrary = require(SK_RS.Modules.ItemLibrary)
        DataController = require(controllers.PlayerDataController)
    end)

    local equipped, favorites = {}, {}
    local saveFile = 'lunar_unlockall.json'

    local function saveConfig()
        if not writefile then return end
        pcall(function()
            local config = { equipped = {}, favorites = favorites }
            for weapon, cosmetics in pairs(equipped) do
                config.equipped[weapon] = {}
                for cosmeticType, cosmeticData in pairs(cosmetics) do
                    if cosmeticData and cosmeticData.Name then
                        config.equipped[weapon][cosmeticType] = {
                            name = cosmeticData.Name,
                            seed = cosmeticData.Seed,
                            inverted = cosmeticData.Inverted,
                        }
                    end
                end
            end
            writefile(saveFile, SK_HTTP:JSONEncode(config))
        end)
    end

    local function cloneCosmetic(name, cosmeticType)
        if not (CosmeticLibrary and CosmeticLibrary.Cosmetics) then return nil end
        local base = CosmeticLibrary.Cosmetics[name]
        if not base then return nil end
        local data = {}
        for key, value in pairs(base) do data[key] = value end
        data.Name = name
        data.Type = data.Type or cosmeticType
        data.Seed = data.Seed or math.random(1, 1000000)
        if EnumLibrary then
            local success, enumId = pcall(EnumLibrary.ToEnum, EnumLibrary, name)
            if success and enumId then data.Enum, data.ObjectID = enumId, data.ObjectID or enumId end
        end
        return data
    end

    local function loadConfig()
        if not (readfile and isfile and isfile(saveFile)) then return end
        pcall(function()
            local config = SK_HTTP:JSONDecode(readfile(saveFile))
            if config.equipped then
                for weapon, cosmetics in pairs(config.equipped) do
                    equipped[weapon] = {}
                    for cosmeticType, cosmeticData in pairs(cosmetics) do
                        local cloned = cloneCosmetic(cosmeticData.name, cosmeticType)
                        if cloned then
                            cloned.Seed = cosmeticData.seed or cloned.Seed
                            cloned.Inverted = cosmeticData.inverted
                            equipped[weapon][cosmeticType] = cloned
                        end
                    end
                end
            end
            favorites = config.favorites or {}
        end)
    end

    local function buildWeaponList()
        local out = {}
        if ItemLibrary and ItemLibrary.Items then
            for name in pairs(ItemLibrary.Items) do
                if type(name) == 'string' then table.insert(out, name) end
            end
        end
        if #out == 0 then
            out = {
                'Knife', 'Fists', 'Katana', 'Revolver', 'Handgun', 'SMG', 'Shotgun', 'TacticalShotgun',
                'DoubleBarrel', 'Assault Rifle', 'Sniper', 'Bow', 'Crossbow', 'RPG', 'Grenade Launcher',
                'Flamethrower', 'Minigun', 'Uzi', 'Energy Rifle', 'Glass Cannon', 'Distortion', 'Gunblade',
                'Paintball Gun', 'Shorty', 'Spray', 'Slingshot', 'Flare Gun', 'Exogun', 'Daggers', 'Scepter',
                'Warper', 'Energy Pistols', 'Battle Axe', 'Scythe', 'Chainsaw', 'Riot Shield', 'Trowel'
            }
        end
        table.sort(out)
        return out
    end

    local function buildCosmeticList(onlyType)
        local out = { 'None' }
        local cosmetics = CosmeticLibrary and CosmeticLibrary.Cosmetics
        if cosmetics then
            for name, data in pairs(cosmetics) do
                if type(name) == 'string' and not name:find('MISSING_') then
                    local ctype = data and data.Type
                    if (not onlyType) or ctype == onlyType then table.insert(out, name) end
                end
            end
        end
        table.sort(out)
        return out
    end

    local SKIN_TYPES = { 'Skin', 'Charm', 'Emote', 'Dance', 'Wrap' }

    UnlockGb:AddToggle('UnlockAllCosmetics', { Text = 'Unlock All Cosmetics', Default = false, Callback = function(v)
        if v then
            getgenv().Library:Notify('Unlock all enabled', 2)
        else
            getgenv().Library:Notify('Unlock all disabled', 2)
        end
    end })
    UnlockGb:AddToggle('FavoritesOnly', { Text = 'Only Use Favorites', Default = false })
    UnlockGb:AddToggle('AlwaysFavoriteCosmetics', { Text = 'Mark Everything Favorite', Default = false })
    UnlockGb:AddButton('Reload Saved Skins', function()
        loadConfig()
        getgenv().Library:Notify('Skin config reloaded', 2)
    end)
    UnlockGb:AddButton('Save Skins', function()
        saveConfig()
        getgenv().Library:Notify('Skin config saved', 2)
    end)
    UnlockGb:AddButton('Reset All Skins', function()
        equipped = {}
        pcall(function()
            local current = DataController and DataController.CurrentData
            if current and current.Replicate then current:Replicate('WeaponInventory') end
        end)
        getgenv().Library:Notify('Skins reset', 2)
    end)

    SkinGb:AddDropdown('SkinWeapon', { Text = 'Weapon', Values = buildWeaponList(), Default = 1 })
    SkinGb:AddDropdown('SkinType', { Text = 'Cosmetic type', Values = SKIN_TYPES, Default = 1 })
    SkinGb:AddDropdown('SkinName', { Text = 'Cosmetic', Values = buildCosmeticList('Skin'), Default = 1 })
    SkinGb:AddInput('SkinNameManual', { Text = 'Exact name (optional)', Default = '', Placeholder = 'type the cosmetic name' })
    SkinGb:AddToggle('SkinInverted', { Text = 'Inverted', Default = false })
    SkinGb:AddToggle('SkinPreviewOnSelf', { Text = 'Apply to viewmodel only', Default = true })

    if not skinsReady then
        UnlockGb:AddLabel('unlocker: cosmetic libraries not found in this game')
    else
        local originalOwnsCosmetic = CosmeticLibrary.OwnsCosmetic
        if type(originalOwnsCosmetic) ~= 'function' then originalOwnsCosmetic = function() return false end end
        CosmeticLibrary.OwnsCosmetic = function(self, inventory, name, weapon)
            if not unlockActive() then return originalOwnsCosmetic(self, inventory, name, weapon) end
            if type(name) == 'string' and name:find('MISSING_') then
                return originalOwnsCosmetic(self, inventory, name, weapon)
            end
            local cosmetic = CosmeticLibrary.Cosmetics[name]
            local lname = type(name) == 'string' and name:lower() or ''
            if cosmetic and (cosmetic.Type == 'Skin' or cosmetic.Type == 'Charm' or cosmetic.Type == 'Dance'
                or cosmetic.Type == 'Emote' or cosmetic.Type == 'Wrap' or cosmetic.Type == 'Wrapping'
                or lname:find('charm') or lname:find('dance') or lname:find('emote') or lname:find('wrap')) then
                return true
            end
            return originalOwnsCosmetic(self, inventory, name, weapon)
        end

        local originalGet = DataController.Get
        if type(originalGet) ~= 'function' then originalGet = function(_, key) return nil end end
        DataController.Get = function(self, key)
            local data = originalGet(self, key)
            if not unlockActive() then return data end
            if key == 'CosmeticInventory' then
                local proxy = {}
                if data then
                    for k, v in pairs(data) do
                        if CosmeticLibrary.Cosmetics[k] then proxy[k] = v end
                    end
                end
                return setmetatable(proxy, { __index = function(_, k)
                    if CosmeticLibrary.Cosmetics[k] then return true end
                    return nil
                end })
            end
            if key == 'FavoritedCosmetics' then
                local result = data and table.clone(data) or {}
                if on('AlwaysFavoriteCosmetics') then
                    for weapon, favs in pairs(favorites) do
                        result[weapon] = result[weapon] or {}
                        for name, isFav in pairs(favs) do
                            if CosmeticLibrary.Cosmetics[name] then result[weapon][name] = isFav end
                        end
                    end
                end
                return result
            end
            return data
        end

        local originalGetWeaponData = DataController.GetWeaponData
        if type(originalGetWeaponData) ~= 'function' then originalGetWeaponData = function() return nil end end
        DataController.GetWeaponData = function(self, weaponName)
            local data = originalGetWeaponData(self, weaponName)
            if not data then return nil end
            local merged = {}
            for key, value in pairs(data) do merged[key] = value end
            merged.Name = weaponName
            if unlockActive() and equipped[weaponName] then
                for cosmeticType, cosmeticData in pairs(equipped[weaponName]) do
                    merged[cosmeticType] = cosmeticData
                end
            end
            return merged
        end

        -- remote interceptor: equip / favourite cosmetics without owning them
        if hookmetamethod and getnamecallmethod then
            pcall(function()
                local remotes = SK_RS:FindFirstChild('Remotes')
                local dataRemotes = remotes and remotes:FindFirstChild('Data')
                local equipRemote = dataRemotes and dataRemotes:FindFirstChild('EquipCosmetic')
                local favoriteRemote = dataRemotes and dataRemotes:FindFirstChild('FavoriteCosmetic')
                if not equipRemote and not favoriteRemote then return end

                local oldNamecall
                oldNamecall = hookmetamethod(game, '__namecall', function(self, ...)
                    if getnamecallmethod() ~= 'FireServer' then return oldNamecall(self, ...) end
                    if not unlockActive() then return oldNamecall(self, ...) end
                    local args = { ... }
                    if equipRemote and self == equipRemote then
                        local weaponName, cosmeticType, cosmeticName, options = args[1], args[2], args[3], args[4] or {}
                        if cosmeticName and cosmeticName ~= 'None' and cosmeticName ~= '' then
                            local inventory = DataController:Get('CosmeticInventory')
                            if inventory and rawget(inventory, cosmeticName) then return oldNamecall(self, ...) end
                        end
                        equipped[weaponName] = equipped[weaponName] or {}
                        if not cosmeticName or cosmeticName == 'None' or cosmeticName == '' then
                            equipped[weaponName][cosmeticType] = nil
                            if not next(equipped[weaponName]) then equipped[weaponName] = nil end
                        else
                            local cloned = cloneCosmetic(cosmeticName, cosmeticType)
                            if cloned then
                                cloned.Inverted = options.IsInverted
                                cloned.OnlyUseFavorites = on('FavoritesOnly')
                                equipped[weaponName][cosmeticType] = cloned
                            end
                        end
                        task.defer(function()
                            pcall(function()
                                local current = DataController.CurrentData
                                if current and current.Replicate then current:Replicate('WeaponInventory') end
                            end)
                            task.wait(0.2)
                            saveConfig()
                        end)
                        return
                    end
                    if favoriteRemote and self == favoriteRemote then
                        local cosmetic = CosmeticLibrary.Cosmetics[args[2]]
                        if cosmetic then
                            favorites[args[1]] = favorites[args[1]] or {}
                            favorites[args[1]][args[2]] = args[3] or nil
                            saveConfig()
                            task.spawn(function()
                                pcall(function()
                                    local current = DataController.CurrentData
                                    if current and current.Replicate then current:Replicate('FavoritedCosmetics') end
                                end)
                            end)
                        end
                        return
                    end
                    return oldNamecall(self, ...)
                end)
            end)
        end

        -- apply the stored loadout onto the local viewmodel when a weapon spawns
        local ClientItem
        pcall(function()
            ClientItem = require(sk_lp.PlayerScripts.Modules.ClientReplicatedClasses.ClientFighter.ClientItem)
        end)
        if ClientItem and type(ClientItem._CreateViewModel) == 'function' then
            local originalCreateViewModel = ClientItem._CreateViewModel
            ClientItem._CreateViewModel = function(self, viewmodelRef)
                local weaponName = self.Name
                local owner = self.ClientFighter and self.ClientFighter.Player
                if unlockActive() and owner == sk_lp and equipped[weaponName] and viewmodelRef then
                    pcall(function()
                        local dataKey = self.ToEnum and self:ToEnum('Data')
                        local target = (dataKey and viewmodelRef[dataKey]) or viewmodelRef.Data
                        if target then
                            for cosmeticType, cosmeticData in pairs(equipped[weaponName]) do
                                local enumKey = self.ToEnum and self:ToEnum(cosmeticType)
                                target[enumKey or cosmeticType] = cosmeticData
                                if cosmeticType == 'Skin' then target.Name = cosmeticData.Name end
                            end
                        end
                    end)
                end
                return originalCreateViewModel(self, viewmodelRef)
            end
        end

        local function equipChosen()
            local weaponName = tostring(val('SkinWeapon') or '')
            local manual = tostring(val('SkinNameManual') or '')
            local cosmeticName = manual ~= '' and manual or tostring(val('SkinName') or 'None')
            if weaponName == '' or cosmeticName == '' then return end
            local cosmeticType = tostring(val('SkinType') or 'Skin')
            local remotes = SK_RS:FindFirstChild('Remotes')
            local dataRemotes = remotes and remotes:FindFirstChild('Data')
            local equipRemote = dataRemotes and dataRemotes:FindFirstChild('EquipCosmetic')
            if not equipRemote then return end
            pcall(function()
                equipRemote:FireServer(weaponName, cosmeticType, cosmeticName, {
                    IsInverted = on('SkinInverted'),
                    OnlyUseFavorites = on('FavoritesOnly'),
                })
            end)
        end

        SkinGb:AddButton('Apply Cosmetic', function()
            equipChosen()
            getgenv().Library:Notify('Cosmetic applied locally', 2)
        end)
        SkinGb:AddButton('Clear Cosmetic', function()
            local weaponName = tostring(val('SkinWeapon') or '')
            local cosmeticType = tostring(val('SkinType') or 'Skin')
            equipped[weaponName] = equipped[weaponName] or {}
            equipped[weaponName][cosmeticType] = nil
            if not next(equipped[weaponName]) then equipped[weaponName] = nil end
            pcall(function()
                local current = DataController.CurrentData
                if current and current.Replicate then current:Replicate('WeaponInventory') end
            end)
            getgenv().Library:Notify('Cosmetic cleared', 2)
        end)

        loadConfig()
    end
end

--==============================================================================
--  TAB: PERFORMANCE
--==============================================================================
do
    local FpsGb   = getgenv().Tabs.Performance:AddLeftGroupbox('Frame Rate')
    local WorldGb = getgenv().Tabs.Performance:AddRightGroupbox('World Cost')
    local storedFx = {}
    local storedSky, storedAmbient, storedOutdoor

    FpsGb:AddSlider('PerfFpsCap', { Text = 'FPS cap', Default = 240, Min = 30, Max = 360, Rounding = 0, Callback = function(v)
        if setfpscap then pcall(setfpscap, v) end
    end })
    FpsGb:AddToggle('PerfUnlockFps', { Text = 'Unlock FPS cap', Default = true, Callback = function(v)
        if setfpscap then pcall(setfpscap, v and 32555555555555555 or 240) end
    end })
    FpsGb:AddButton('Collect garbage now', function()
        pcall(function() collectgarbage('collect') end)
        pcall(function() collectgarbage('collect') end)
        getgenv().Library:Notify('Garbage collected', 2)
    end)

    WorldGb:AddToggle('PerfNoShadows', { Text = 'Disable shadows', Default = false, Callback = function(v)
        pcall(function() game:GetService('Lighting').GlobalShadows = not v end)
    end })
    WorldGb:AddToggle('PerfNoPostFx', { Text = 'Strip post processing', Default = false, Callback = function(v)
        local lighting = game:GetService('Lighting')
        if v then
            for _, fx in ipairs(lighting:GetChildren()) do
                if fx:IsA('PostEffect') then
                    storedFx[fx] = fx.Enabled
                    pcall(function() fx.Enabled = false end)
                end
            end
        else
            for fx, state in pairs(storedFx) do
                if fx.Parent then pcall(function() fx.Enabled = state end) end
            end
            table.clear(storedFx)
        end
    end })
    WorldGb:AddToggle('PerfNoSkybox', { Text = 'Remove skybox', Default = false, Callback = function(v)
        local lighting = game:GetService('Lighting')
        if v then
            storedSky = lighting:FindFirstChildOfClass('Sky')
            if storedSky then lighting.Sky.Parent = nil end
            storedAmbient, storedOutdoor = lighting.Ambient, lighting.OutdoorAmbient
            lighting.Ambient = Color3.fromRGB(120, 120, 120)
            lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
        else
            if storedSky then pcall(function() storedSky.Parent = lighting end) end
            if storedAmbient then lighting.Ambient = storedAmbient end
            if storedOutdoor then lighting.OutdoorAmbient = storedOutdoor end
        end
    end })
end

--==============================================================================
--  HvH TAB: GOD BLOCK
--  Ported from the supplied Da Hood scripts.  Keeps re-arming the block remote so
--  the server always sees you blocking, and can swallow the block animation so
--  it never shows locally.  Both halves restore the original state on toggle off.
--==============================================================================
do
    local GB_RS  = getgenv().RunService
    local GB_REP = getgenv().ReplicatedStorage
    local gb_lp  = getgenv().Players.LocalPlayer

    local GodGb = getgenv().Pages.Aim:AddLeftGroupbox('God Block')

    local blockLoop, blockActive = nil, false
    local hideBound = false
    local originalBlockAnim
    local BLOCKED_ANIMATIONS = {
        'rbxassetid://2788289281', 'rbxassetid://507766388', 'rbxassetid://2788292075',
        'rbxassetid://278829075', 'rbxassetid://4798175381', 'rbxassetid://2953512033',
        'rbxassetid://2788309982', 'rbxassetid://2788312709', 'rbxassetid://2788313790',
        'rbxassetid://2788316350', 'rbxassetid://2788315673', 'rbxassetid://2788314837',
    }

    local function blockAnimation(isDisabled)
        pcall(function()
            local clientAnimations = GB_REP:FindFirstChild('ClientAnimations')
            local block = clientAnimations and clientAnimations:FindFirstChild('Block')
            if not block then return end
            if originalBlockAnim == nil then originalBlockAnim = block.AnimationId end
            block.AnimationId = isDisabled and 'rbxassetid://0' or originalBlockAnim
        end)
    end

    local function startAutoBlock()
        if blockLoop then return end
        blockActive = true
        blockAnimation(true)
        blockLoop = task.spawn(function()
            while blockActive do
                local char = gb_lp.Character
                local bodyEffects = char and char:FindFirstChild('BodyEffects')
                local mainEvent = getgenv().MainEvent
                if bodyEffects and mainEvent then
                    local block = bodyEffects:FindFirstChild('Block')
                    if block then pcall(function() block:Destroy() end) end
                    local tool = char:FindFirstChildWhichIsA('Tool')
                    if tool and tool:FindFirstChild('Ammo') then
                        pcall(function() mainEvent:FireServer('Block', false) end)
                    else
                        pcall(function() mainEvent:FireServer('Block', true) end)
                        task.wait()
                        pcall(function() mainEvent:FireServer('Block', false) end)
                    end
                end
                task.wait()
            end
        end)
    end

    local function stopAutoBlock()
        blockActive = false
        if blockLoop then task.cancel(blockLoop) ; blockLoop = nil end
        blockAnimation(false)
    end

    local function hideAnimations(state)
        if state and not hideBound then
            hideBound = true
            GB_RS:BindToRenderStep('lunar_hide_block_anim', 0, function()
                local char = gb_lp.Character
                local hum = char and char:FindFirstChildWhichIsA('Humanoid')
                if not hum then return end
                for _, track in ipairs(hum:GetPlayingAnimationTracks()) do
                    local anim = track.Animation
                    if anim and table.find(BLOCKED_ANIMATIONS, anim.AnimationId) then
                        pcall(function() track:Stop() end)
                    end
                end
            end)
        elseif not state and hideBound then
            hideBound = false
            pcall(function() GB_RS:UnbindFromRenderStep('lunar_hide_block_anim') end)
        end
    end

    GodGb:AddToggle('GodBlockToggle', {
        Text = 'God Block',
        Default = false,
        Callback = function(state)
            if state then startAutoBlock() else stopAutoBlock() end
        end,
    })
    GodGb:AddToggle('GodBlockHideAnimations', {
        Text = 'Hide Block Animations',
        Default = false,
        Callback = hideAnimations,
    })

    getgenv().Library:OnUnload(function()
        stopAutoBlock()
        hideAnimations(false)
    end)
end

--==============================================================================
--  MISC TAB: ANTI
--  Defensive utilities ported from the supplied Da Hood scripts.  Each one owns
--  its own connection and tears it down when switched off, and every game
--  lookup is pcall'd so it stays inert in games that lack BodyEffects etc.
--==============================================================================
do
    local AN_RS   = getgenv().RunService
    local AN_PLRS = getgenv().Players
    local an_lp   = AN_PLRS.LocalPlayer

    local AntiGb = getgenv().Pages.Player:AddRightGroupbox('Anti')

    local flingConn, sitConn, afkConn, stompConn
    local stompActive = false
    local stompFlashback = false
    local stompLastPivot

    local function stopStompWatcher()
        if stompConn then stompConn:Disconnect() end
        stompConn = nil
    end

    -- anti stomp: a stomp only lands while you are K.O, so deny it by dying first
    local function startStompWatcher()
        stopStompWatcher()
        task.spawn(function()
            local char = an_lp.Character or an_lp.CharacterAdded:Wait()
            local hum = char:WaitForChild('Humanoid', 5)
            local bodyEffects = char:WaitForChild('BodyEffects', 5)
            if not (hum and bodyEffects) then return end
            local ko = bodyEffects:WaitForChild('K.O', 5)
            if not ko then return end
            stompConn = AN_RS.Heartbeat:Connect(function()
                if not stompActive then return end
                if ko.Value == true and hum.Health > 0 then
                    if stompFlashback then stompLastPivot = char:GetPivot() end
                    hum.Health = 0
                end
            end)
        end)
    end

    AntiGb:AddToggle('AntiStompToggle', {
        Text = 'Anti Stomp',
        Default = false,
        Callback = function(state)
            stompActive = state
            if state then startStompWatcher() else stopStompWatcher() end
        end,
    })

    AntiGb:AddToggle('AntiStompFlashback', {
        Text = 'Anti Stomp Flashback',
        Tooltip = 'teleport back to where you were KO\'d after respawning',
        Default = false,
        Callback = function(state) stompFlashback = state end,
    })

    AntiGb:AddToggle('AntiFlingToggle', {
        Text = 'Anti Fling',
        Default = false,
        Callback = function(state)
            if flingConn then flingConn:Disconnect() ; flingConn = nil end
            if not state then return end
            flingConn = AN_RS.Stepped:Connect(function()
                for _, player in ipairs(AN_PLRS:GetPlayers()) do
                    if player ~= an_lp and player.Character then
                        for _, part in ipairs(player.Character:GetDescendants()) do
                            if part:IsA('BasePart') and part.CanCollide then
                                pcall(function() part.CanCollide = false end)
                            end
                        end
                    end
                end
            end)
        end,
    })

    AntiGb:AddToggle('AntiSitToggle', {
        Text = 'Anti Sit',
        Default = false,
        Callback = function(state)
            if sitConn then sitConn:Disconnect() ; sitConn = nil end
            if not state then return end
            sitConn = AN_RS.RenderStepped:Connect(function()
                local char = an_lp.Character
                local hum = char and char:FindFirstChildOfClass('Humanoid')
                if hum and hum.Sit then pcall(function() hum.Sit = false end) end
            end)
        end,
    })

    AntiGb:AddToggle('AntiAFKToggle', {
        Text = 'Anti-AFK',
        Default = false,
        Callback = function(state)
            if afkConn then afkConn:Disconnect() ; afkConn = nil end
            if not state then return end
            local virtualUser
            pcall(function() virtualUser = game:GetService('VirtualUser') end)
            if not virtualUser then return end
            afkConn = an_lp.Idled:Connect(function()
                pcall(function()
                    virtualUser:CaptureController()
                    virtualUser:ClickButton2(Vector2.new())
                end)
            end)
        end,
    })

    -- a stomp/fling swap only matters on respawn, so re-arm the watcher there
    an_lp.CharacterAdded:Connect(function()
        if stompActive then
            startStompWatcher()
            if stompFlashback and stompLastPivot then
                task.spawn(function()
                    local root = an_lp.Character and an_lp.Character:WaitForChild('HumanoidRootPart', 5)
                    if not root then return end
                    for _ = 1, 20 do
                        if (root.Position - stompLastPivot.Position).Magnitude <= 5 then break end
                        pcall(function() root.CFrame = stompLastPivot end)
                        task.wait()
                    end
                    stompLastPivot = nil
                end)
            end
        end
    end)

    getgenv().Library:OnUnload(function()
        stopStompWatcher()
        if flingConn then flingConn:Disconnect() end
        if sitConn then sitConn:Disconnect() end
        if afkConn then afkConn:Disconnect() end
    end)
end

--==============================================================================
--  MISC TAB: NAME SPOOFER
--  Ported from the supplied name spoofer.  Rewrites the local player's name and
--  user id wherever they are baked into an instance property, then keeps doing
--  it for anything created later.  Scans are spread across frames so the first
--  pass never hitches the client.
--==============================================================================
do
    local NS_PLRS = getgenv().Players
    local NS_RUN  = getgenv().RunService
    local ns_lp   = NS_PLRS.LocalPlayer
    local nsCoreGui = (function()
        local ok, gui = pcall(function() return gethui and gethui() or game:GetService('CoreGui') end)
        if ok and gui then return gui end
        return nil
    end)()

    local SpoofGb = getgenv().Pages.Player:AddLeftGroupbox('Name Spoofer')

    local spoofActive, deepScan = false, true
    local renameInstances, clearAvatar, flushColors = false, true, true
    local newName, newId = 'Name', '104867'
    local itemChangedConn, descendantConns, scanThread
    local stopSpoof

    local originals = { ns_lp.Name }
    local originalIds = { tostring(ns_lp.UserId) }

    local function escapePattern(s)
        return (string.gsub(tostring(s), '([^%w])', '%%%1'))
    end

    local function swapped(text)
        if type(text) ~= 'string' then return nil end
        local out, changed = text, false
        for i = 1, #originals do
            local from, to = originals[i], newName
            if string.find(out, from, 1, true) then
                out, changed = string.gsub(out, escapePattern(from), (to:gsub('%%', '%%%%'))), true
            elseif string.find(out, from:lower(), 1, true) then
                out, changed = string.gsub(out, escapePattern(from:lower()), (to:lower():gsub('%%', '%%%%'))), true
            elseif string.find(out, from:upper(), 1, true) then
                out, changed = string.gsub(out, escapePattern(from:upper()), (to:upper():gsub('%%', '%%%%'))), true
            end
        end
        for i = 1, #originalIds do
            local from, to = originalIds[i], newId
            if string.find(out, from, 1, true) then
                out, changed = string.gsub(out, escapePattern(from), to), true
            end
        end
        return changed and out or nil
    end

    local function spoofObject(item)
        if not item then return end
        for _, property in ipairs({ 'Text', 'Message', 'ToolTip', 'Value' }) do
            pcall(function()
                local current = item[property]
                if type(current) ~= 'string' then return end
                local replaced = swapped(current)
                if replaced then item[property] = replaced end
            end)
        end
        if renameInstances then
            pcall(function()
                local replaced = swapped(item.Name)
                if replaced then item.Name = replaced end
            end)
        end
    end

    local function scanOnce()
        local queues = {}
        if nsCoreGui then table.insert(queues, nsCoreGui) end
        local playerGui = ns_lp:FindFirstChildOfClass('PlayerGui')
        if playerGui then table.insert(queues, playerGui) end
        table.insert(queues, workspace)
        local budget = 0
        for _, root in ipairs(queues) do
            for _, item in ipairs(root:GetDescendants()) do
                budget = budget + 1
                if budget >= 6000 then
                    budget = 0
                    NS_RUN.RenderStepped:Wait()
                end
                spoofObject(item)
            end
        end
    end

    local function fixCharacter(char)
        if not char then return end
        task.wait(0.2)
        if renameInstances then pcall(function() char.Name = newName end) end
        if clearAvatar then pcall(function() ns_lp:ClearCharacterAppearance() end) end
        task.wait(0.1)
        if not flushColors then return end
        pcall(function()
            local bodyColors = char:FindFirstChildOfClass('BodyColors')
            if bodyColors then
                for _, key in ipairs({ 'HeadColor', 'LeftArmColor', 'LeftLegColor', 'RightArmColor', 'RightLegColor', 'TorsoColor' }) do
                    if typeof(bodyColors[key]) == 'BrickColor' then bodyColors[key] = BrickColor.random() end
                end
            else
                for _, limb in ipairs(char:GetChildren()) do
                    if limb:IsA('BasePart') then limb.BrickColor = BrickColor.random() end
                end
            end
        end)
    end

    local function startSpoof()
        stopSpoof()
        spoofActive = true
        scanThread = task.spawn(function()
            scanOnce()
            while spoofActive and deepScan do
                task.wait(1)
                scanOnce()
            end
        end)
        itemChangedConn = game.ItemChanged:Connect(function(obj, property)
            if not spoofActive then return end
            if not renameInstances and property == 'Name' then return end
            pcall(function()
                local value = obj[property]
                if type(value) == 'string' then
                    local replaced = swapped(value)
                    if replaced then obj[property] = replaced end
                elseif type(value) == 'number' then
                    local text = tostring(value)
                    for i = 1, #originalIds do
                        if string.find(text, originalIds[i], 1, true) then
                            obj[property] = tonumber((string.gsub(text, originalIds[i], newId)))
                        end
                    end
                end
            end)
        end)
        descendantConns = {}
        for _, root in ipairs({ nsCoreGui, ns_lp:FindFirstChildOfClass('PlayerGui') }) do
            if root then table.insert(descendantConns, root.DescendantAdded:Connect(spoofObject)) end
        end
    end

    function stopSpoof()
        spoofActive = false
        if itemChangedConn then itemChangedConn:Disconnect() ; itemChangedConn = nil end
        if descendantConns then
            for _, conn in ipairs(descendantConns) do conn:Disconnect() end
            descendantConns = nil
        end
        scanThread = nil
    end

    SpoofGb:AddToggle('NameSpooferEnabled', {
        Text = 'Enable Name Spoofer',
        Default = false,
        Callback = function(state)
            if state then startSpoof() else stopSpoof() end
        end,
    })
    SpoofGb:AddInput('SpooferName', { Text = 'Fake name', Default = 'Name', Placeholder = 'Name', Callback = function(v)
        if tostring(v) ~= '' then newName = tostring(v) end
    end })
    SpoofGb:AddInput('SpooferUserId', { Text = 'Fake user id', Default = '104867', Placeholder = '104867', Callback = function(v)
        if tostring(v) ~= '' then newId = tostring(v) end
    end })
    SpoofGb:AddToggle('SpooferClearAvatar', { Text = 'Clear avatar', Default = true, Callback = function(v) clearAvatar = v end })
    SpoofGb:AddToggle('SpooferFlushBodyColors', { Text = 'Randomise body colors', Default = true, Callback = function(v) flushColors = v end })
    SpoofGb:AddToggle('SpooferRenameInstances', { Text = 'Rename instances', Default = false, Callback = function(v) renameInstances = v end })
    SpoofGb:AddToggle('SpooferDeepScan', { Text = 'Rescan every second', Default = true, Callback = function(v)
        deepScan = v
        if v and spoofActive then startSpoof() end
    end })
    SpoofGb:AddButton('Rescan now', function()
        if spoofActive then scanOnce() end
    end)

    ns_lp.CharacterAppearanceLoaded:Connect(fixCharacter)
    ns_lp.CharacterAdded:Connect(function(char)
        task.spawn(fixCharacter, char)
    end)

    getgenv().Library:OnUnload(stopSpoof)
end

--==============================================================================
--  HvH TAB: GUN MODS
--  Rapid fire from the supplied scripts.  The gun script keeps its fire delay in
--  an upvalue on the tool's Activated connection; zeroing every numeric upvalue
--  is what turns one shot per click into one shot per frame.  Rapid Fire v2 goes
--  the other way and pins the game's own ToleranceCooldown values to zero.
--==============================================================================
do
    local GM_UIS = getgenv().UserInputService
    local GM_RUN = getgenv().RunService
    local gm_lp  = getgenv().Players.LocalPlayer

    local GunGb = getgenv().Pages.Rage:AddLeftGroupbox('Gun Mods')

    local rapidFireOn, hyperFireOn = false, false
    local patcherThread
    -- tool -> list of { fn, index, value } so every upvalue we overwrite can be
    -- put back; the source scripts just left the gun patched forever
    local patched = {}

    local function patchTool(tool)
        if patched[tool] then return end
        if not (tool:IsA('Tool') and tool:FindFirstChild('GunScript')) then return end
        if type(getconnections) ~= 'function' then return end
        local restores = {}
        pcall(function()
            for _, signal in ipairs(getconnections(tool.Activated)) do
                local fn = signal.Function
                if type(fn) == 'function' then
                    local info = debug.getinfo(fn)
                    for i = 1, (info and info.nups or 0) do
                        local ok, value = pcall(debug.getupvalue, fn, i)
                        if ok and type(value) == 'number' then
                            if pcall(debug.setupvalue, fn, i, 1e-13) then
                                table.insert(restores, { fn = fn, index = i, value = value })
                            end
                        end
                    end
                end
            end
        end)
        patched[tool] = restores
    end

    local function unpatchAll()
        for _, restores in pairs(patched) do
            for _, entry in ipairs(restores) do
                pcall(debug.setupvalue, entry.fn, entry.index, entry.value)
            end
        end
        patched = {}
    end

    local function startPatcher()
        if patcherThread then return end
        patcherThread = task.spawn(function()
            while rapidFireOn do
                local char = gm_lp.Character
                if char then
                    for _, child in ipairs(char:GetChildren()) do
                        if child:IsA('Tool') and child:FindFirstChild('Handle') then patchTool(child) end
                    end
                end
                task.wait(0.5)
            end
            patcherThread = nil
        end)
    end

    GunGb:AddToggle('RapidFireToggle', {
        Text = 'Rapid Fire',
        Default = false,
        Callback = function(state)
            rapidFireOn = state
            if state then startPatcher() else unpatchAll() end
        end,
    })

    local function applyHyperFire()
        local wanted = hyperFireOn and 0 or 3
        for _, obj in ipairs(game:GetDescendants()) do
            if obj.Name == 'ToleranceCooldown' and obj:IsA('ValueBase') then
                pcall(function() obj.Value = wanted end)
            end
        end
    end

    GunGb:AddToggle('RapidFireV2Toggle', {
        Text = 'Rapid Fire v2',
        Tooltip = 'zeroes the game\'s own tolerance cooldowns',
        Default = false,
        Callback = function(state)
            hyperFireOn = state
            applyHyperFire()
        end,
    })

    game.DescendantAdded:Connect(function(obj)
        if hyperFireOn and obj.Name == 'ToleranceCooldown' and obj:IsA('ValueBase') then
            pcall(function() obj.Value = 0 end)
        end
    end)

    GM_RUN.RenderStepped:Connect(function()
        if not hyperFireOn then return end
        if not GM_UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then return end
        local char = gm_lp.Character
        local tool = char and char:FindFirstChildOfClass('Tool')
        if tool and tool:FindFirstChild('Ammo') then pcall(function() tool:Activate() end) end
    end)

    getgenv().Library:OnUnload(function()
        rapidFireOn = false
        hyperFireOn = false
        unpatchAll()
    end)
end

--==============================================================================
--  HvH TAB: HITBOX EXPANDER
--  Ported from the supplied scripts.  Because the expander resizes parts on other
--  players' characters, each root gets its original size stashed in an attribute
--  first so switching it off (or unload) restores exactly what the game set
--  rather than guessing the default.
--==============================================================================
do
    local HB_PLRS = getgenv().Players
    local hb_lp   = HB_PLRS.LocalPlayer

    local HitboxGb = getgenv().Pages.Rage:AddLeftGroupbox('Hitbox Expander')

    local expandOn, visualizeHitbox = false, false
    local hitboxColor = Color3.fromRGB(0, 255, 255)

    local function ov(name) local o = Options[name] ; return o and o.Value end
    local function on(name) local t = Toggles[name] ; return t and t.Value end

    local function clearVisuals(hrp)
        for _, name in ipairs({ 'HitboxOutline', 'HitboxGlow' }) do
            local adornment = hrp:FindFirstChild(name)
            if adornment then pcall(function() adornment:Destroy() end) end
        end
    end

    local function resetHitbox(plr)
        local char = plr.Character
        local hrp = char and char:FindFirstChild('HumanoidRootPart')
        if not hrp then return end
        local original = hrp:GetAttribute('LunarHitboxSize')
        pcall(function() hrp.Size = original or Vector3.new(2, 2, 1) end)
        pcall(function() hrp.Transparency = 1 end)
        pcall(function() hrp.CanCollide = true end)
        clearVisuals(hrp)
    end

    local function applyHitbox(plr)
        local char = plr.Character
        local hrp = char and (char:FindFirstChild('HumanoidRootPart') or char:WaitForChild('HumanoidRootPart', 3))
        if not hrp then return end
        if hrp:GetAttribute('LunarHitboxSize') == nil then
            local ok = pcall(function() hrp:SetAttribute('LunarHitboxSize', hrp.Size) end)
            if not ok then return end
        end
        local size = ov('HitboxExpandSize') or 10
        pcall(function() hrp.Size = Vector3.new(size, size, size) end)
        pcall(function() hrp.Transparency = 1 end)
        pcall(function() hrp.CanCollide = false end)

        if not visualizeHitbox then
            clearVisuals(hrp)
            return
        end
        pcall(function()
            local outline = hrp:FindFirstChild('HitboxOutline')
            if not outline then
                outline = Instance.new('BoxHandleAdornment')
                outline.Name = 'HitboxOutline'
                outline.Adornee = hrp
                outline.Transparency = 0.8
                outline.ZIndex = 10
                outline.AlwaysOnTop = true
                outline.Parent = hrp

                local glow = Instance.new('BoxHandleAdornment')
                glow.Name = 'HitboxGlow'
                glow.Adornee = hrp
                glow.Transparency = 0.9
                glow.ZIndex = 9
                glow.AlwaysOnTop = true
                glow.Parent = hrp
            end
            outline.Size = hrp.Size
            outline.Color3 = hitboxColor
            local glow = hrp:FindFirstChild('HitboxGlow')
            if glow then
                glow.Size = hrp.Size + Vector3.new(0.1, 0.1, 0.1)
                glow.Color3 = hitboxColor
            end
        end)
    end

    local function forEachTarget(fn)
        for _, plr in ipairs(HB_PLRS:GetPlayers()) do
            if plr ~= hb_lp then fn(plr) end
        end
    end

    local function refresh()
        if expandOn then
            forEachTarget(function(plr)
                if plr.Character then applyHitbox(plr) end
            end)
        else
            forEachTarget(resetHitbox)
        end
    end

    HitboxGb:AddToggle('HitboxExpandToggle', {
        Text = 'Hitbox Expander',
        Default = false,
        Callback = function(state)
            expandOn = state
            refresh()
        end,
    }):AddKeyPicker('HitboxExpandKey', {
        Default = 'L',
        Mode = 'Toggle',
        Text = 'Hitbox expander',
        SyncToggleState = true,
        Callback = function(state)
            expandOn = state == true
            refresh()
        end,
    })

    HitboxGb:AddSlider('HitboxExpandSize', {
        Text = 'Hitbox size',
        Default = 10,
        Min = 5,
        Max = 50,
        Rounding = 0,
        Callback = refresh,
    })
    HitboxGb:AddToggle('HitboxExpandVisualize', {
        Text = 'Visualize',
        Default = false,
        Callback = function(state)
            visualizeHitbox = state
            refresh()
        end,
    }):AddColorPicker('HitboxExpandColor', {
        Default = ACCENT,
        Title = 'Hitbox color',
        Callback = function(color)
            hitboxColor = color
            if visualizeHitbox then refresh() end
        end,
    })

    HB_PLRS.PlayerAdded:Connect(function(plr)
        plr.CharacterAdded:Connect(function()
            task.wait(0.5)
            if expandOn then applyHitbox(plr) end
        end)
    end)

    getgenv().Library:OnUnload(function()
        expandOn = false
        refresh()
    end)
end

--==============================================================================
--  HvH TAB: KILL AURA
--  Ported from the supplied scripts: closest living enemy inside range gets the
--  gun remote fired at their head every frame, with an optional tracer, an
--  optional below-head shot offset and a per-player whitelist.
--==============================================================================
do
    local KA_PLRS = getgenv().Players
    local ka_lp   = KA_PLRS.LocalPlayer
    local ka_ws   = getgenv().Workspace or workspace

    local AuraGb = getgenv().Pages.Rage:AddLeftGroupbox('Kill Aura')

    local auraOn, visualizeAura, silentAura = false, false, false
    local auraRange = 250
    local whitelist = {}
    local lastAuraHealth = {}

    local auraTracer = Instance.new('Part')
    auraTracer.Name = 'lunar_killaura_tracer'
    auraTracer.Size = Vector3.new(0.2, 0.2, 0.2)
    auraTracer.Material = Enum.Material.Neon
    auraTracer.Color = Color3.fromRGB(255, 0, 0)
    auraTracer.Transparency = 1
    auraTracer.Anchored = true
    auraTracer.CanCollide = false
    auraTracer.Parent = ka_ws

    local function isKO(plr)
        local char = plr.Character
        local bodyEffects = char and char:FindFirstChild('BodyEffects')
        local ko = bodyEffects and bodyEffects:FindFirstChild('K.O')
        return (ko and ko.Value) == true
    end

    local function auraTarget(root)
        local bestDist, best = math.huge, nil
        for _, plr in ipairs(KA_PLRS:GetPlayers()) do
            local char = plr.Character
            if plr ~= ka_lp and not whitelist[plr.Name] and char and not isKO(plr) then
                local head = char:FindFirstChild('Head')
                if head and not char:FindFirstChild('GRABBING_CONSTRAINT') then
                    local dist = (root.Position - head.Position).Magnitude
                    if dist <= auraRange and dist < bestDist then
                        bestDist, best = dist, plr
                    end
                end
            end
        end
        return best, bestDist
    end

    task.spawn(function()
        while task.wait() do
            if not auraOn then
                auraTracer.Transparency = 1
                continue
            end
            local char = ka_lp.Character
            local root = char and char:FindFirstChild('HumanoidRootPart')
            local tool = char and char:FindFirstChildOfClass('Tool')
            local handle = tool and tool:FindFirstChild('Handle')
            local mainEvent = getgenv().MainEvent
            if not (root and tool and handle and mainEvent) or isKO(ka_lp) then
                auraTracer.Transparency = 1
                continue
            end

            local target, dist = auraTarget(root)
            local targetHead = target and target.Character and target.Character:FindFirstChild('Head')
            if not targetHead then
                auraTracer.Transparency = 1
                continue
            end

            if visualizeAura then
                pcall(function()
                    auraTracer.Transparency = 0
                    auraTracer.Size = Vector3.new(0.2, 0.2, dist)
                    auraTracer.CFrame = CFrame.lookAt(root.Position, targetHead.Position)
                        * CFrame.new(0, 0, -auraTracer.Size.Z / 2)
                end)
            else
                auraTracer.Transparency = 1
            end

            -- the aura plays the normal hit sound when the target actually loses HP
            local humanoid = target.Character:FindFirstChildOfClass('Humanoid')
            if humanoid then
                local previous = lastAuraHealth[target.Name]
                if previous and humanoid.Health < previous then
                    local sound = getgenv().PlayHitSound
                    if sound then pcall(sound) end
                end
                lastAuraHealth[target.Name] = humanoid.Health
            end

            local origin = silentAura and (handle.CFrame.Position - Vector3.new(0, 12, 0)) or handle.CFrame.Position
            local destination = silentAura and (targetHead.Position - Vector3.new(0, 12, 0)) or targetHead.Position
            pcall(function()
                mainEvent:FireServer('ShootGun', handle, origin, destination, targetHead, Vector3.new(0, 0, -1))
            end)
        end
    end)

    AuraGb:AddToggle('KillAuraEnable', {
        Text = 'Kill Aura',
        Default = false,
        Callback = function(state)
            auraOn = state
            if not state then auraTracer.Transparency = 1 end
        end,
    }):AddKeyPicker('KillAuraKey', {
        Default = 'K',
        Mode = 'Toggle',
        Text = 'Kill aura',
        SyncToggleState = true,
        Callback = function(state)
            auraOn = state == true
            if not auraOn then auraTracer.Transparency = 1 end
        end,
    })
    AuraGb:AddSlider('KillAuraRange', {
        Text = 'Range',
        Default = 250,
        Min = 10,
        Max = 250,
        Rounding = 0,
        Callback = function(value) auraRange = value end,
    })
    AuraGb:AddToggle('KillAuraSilent', { Text = 'Silent', Default = false, Callback = function(state) silentAura = state end })
    AuraGb:AddToggle('KillAuraVisualize', { Text = 'Visualize', Default = false, Callback = function(state)
        visualizeAura = state
        if not state then auraTracer.Transparency = 1 end
    end }):AddColorPicker('KillAuraColor', {
        Default = ACCENT,
        Title = 'Tracer color',
        Callback = function(color) auraTracer.Color = color end,
    })
    AuraGb:AddInput('KillAuraWhitelistInput', {
        Text = 'Add/Remove player',
        Default = '',
        Placeholder = 'player name',
        Callback = function(input)
            if input == nil or input == '' then return end
            for _, plr in ipairs(KA_PLRS:GetPlayers()) do
                if plr.Name == input or plr.DisplayName == input then
                    if whitelist[plr.Name] then
                        whitelist[plr.Name] = nil
                        getgenv().Library:Notify(plr.Name .. ' removed from the aura whitelist', 2)
                    else
                        whitelist[plr.Name] = true
                        getgenv().Library:Notify(plr.Name .. ' added to the aura whitelist', 2)
                    end
                    return
                end
            end
            getgenv().Library:Notify('No player named ' .. tostring(input), 2)
        end,
    })

    getgenv().Library:OnUnload(function()
        auraOn = false
        auraTracer:Destroy()
    end)
end

--==============================================================================
--  MISC TAB: ECONOMY + SHOP
--  The economy half is cash aura from the supplied scripts.  The shop half is the
--  auto buy gun / ammo / armor pipeline: it teleports to the item, fires the
--  click detector and teleports back.  Desync rewrites the root CFrame every
--  frame, so it is paused for the trip or the teleport gets snapped straight back.
--==============================================================================
do
    local SH_PLRS = getgenv().Players
    local sh_lp   = SH_PLRS.LocalPlayer

    local EconomyGb = getgenv().Pages.Automation:AddLeftGroupbox('Economy')
    local ShopGb    = getgenv().Pages.Automation:AddLeftGroupbox('Shop')

    local function ov(name) local o = Options[name] ; return o and o.Value end
    local function on(name) local t = Toggles[name] ; return t and t.Value end

    local cashOn, cashRange, cashCooldown = false, 17, 0.2
    local buying = false

    local function characterRoot()
        local char = sh_lp.Character
        return char and char:FindFirstChild('HumanoidRootPart')
    end

    local function shopFolder()
        local ignored = workspace:FindFirstChild('Ignored')
        return ignored and ignored:FindFirstChild('Shop') or nil
    end

    -- Da Hood's own shop names, used as the starting list and as the fallback when
    -- the shop folder has not replicated yet
    local KNOWN_ITEMS = {
        '[AUG] - $2195', '[Rifle] - $1745', '[LMG] - $4221', '[DrumGun] - $3278',
        '[Double-Barrel SG] - $1475', '[Flintlock] - $1421',
        '90 [AUG Ammo] - $90', '200 [LMG Ammo] - $338', '5 [Rifle Ammo] - $281',
        '[High-Medium Armor] - $2589', '[Fire Armor] - $4501',
    }

    local function shopItems()
        local seen, out = {}, {}
        local function add(name)
            if type(name) == 'string' and name ~= '' and not seen[name] then
                seen[name] = true
                table.insert(out, name)
            end
        end
        local folder = shopFolder()
        if folder then
            for _, item in ipairs(folder:GetChildren()) do
                if item:FindFirstChildOfClass('ClickDetector') then add(item.Name) end
            end
        end
        for _, name in ipairs(KNOWN_ITEMS) do add(name) end
        table.sort(out)
        return out
    end

    local function indexOf(list, value)
        for i, entry in ipairs(list) do
            if entry == value then return i end
        end
        return 1
    end

    local function canShop()
        local char = sh_lp.Character
        if not char then return false end
        local humanoid = char:FindFirstChildOfClass('Humanoid')
        if humanoid and humanoid.Health <= 1 then return false end
        local bodyEffects = char:FindFirstChild('BodyEffects')
        local ko = bodyEffects and bodyEffects:FindFirstChild('K.O')
        return not (ko and ko.Value)
    end

    local function buyItem(itemName)
        if buying or type(itemName) ~= 'string' or itemName == '' then return false end
        local folder = shopFolder()
        local item = folder and folder:FindFirstChild(itemName)
        local root = characterRoot()
        if not (item and root and canShop()) then return false end
        local detector = item:FindFirstChildOfClass('ClickDetector')
        if not detector then return false end
        local target
        if item:IsA('Model') then
            local head = item:FindFirstChild('Head')
            target = head and head.CFrame or item:GetPivot()
        else
            target = item.CFrame
        end
        if not target then return false end

        buying = true
        local restore = root.CFrame
        local desync = getgenv().desync
        local desyncWas = desync and desync.enabled
        if desyncWas then desync.enabled = false end

        pcall(function() root.CFrame = target + Vector3.new(0, 3, 0) end)
        task.wait(0.2)
        pcall(function() fireclickdetector(detector) end)
        task.wait(0.1)
        pcall(function() root.CFrame = restore end)

        if desyncWas then desync.enabled = true end
        buying = false
        return true
    end

    local function gunTag(itemName)
        return string.match(itemName or '', '^(%[%w+%])') or itemName
    end

    local function ownsGun(tag)
        if type(tag) ~= 'string' or tag == '' then return true end
        local char = sh_lp.Character
        if char and char:FindFirstChild(tag) then return true end
        local backpack = sh_lp:FindFirstChild('Backpack')
        return backpack ~= nil and backpack:FindFirstChild(tag) ~= nil
    end

    local function ammoCount(tag)
        local ok, value = pcall(function() return sh_lp.DataFolder.Inventory:FindFirstChild(tag).Value end)
        if ok then return tonumber(value) or 0 end
        return nil
    end

    local function ammoItemFor(itemName)
        local folder = shopFolder()
        if not (folder and type(itemName) == 'string') then return nil end
        local tag = string.match(itemName, '%[([%w%-]+)%]')
        if not tag then return nil end
        tag = tag:lower()
        for _, item in ipairs(folder:GetChildren()) do
            local name = item.Name:lower()
            if name:find('ammo', 1, true) and name:find(tag, 1, true) then return item.Name end
        end
        return nil
    end

    -- ArmorSave / FireArmorSave are the two 0-130 values the game writes when you
    -- buy armour, so the thresholds read and compare against those
    local function armourValue(key)
        local ok, value = pcall(function() return sh_lp.DataFolder.Information[key].Value end)
        if ok then return tonumber(value) end
        return nil
    end

    local items = shopItems()

    EconomyGb:AddToggle('CashAuraToggle', {
        Text = 'Cash Aura',
        Default = false,
        Callback = function(state) cashOn = state end,
    })
    EconomyGb:AddSlider('CashAuraRange', {
        Text = 'Pickup range',
        Default = 17,
        Min = 5, Max = 60, Rounding = 0,
        Callback = function(value) cashRange = value end,
    })
    EconomyGb:AddSlider('CashAuraCooldown', {
        Text = 'Cooldown (s)',
        Default = 0.2,
        Min = 0.05, Max = 2, Rounding = 2,
        Callback = function(value) cashCooldown = value end,
    })

    ShopGb:AddToggle('ShopAutoGun', { Text = 'Auto Buy Gun', Default = false })
    ShopGb:AddDropdown('ShopGunItem', { Text = 'Gun', Values = items, Default = indexOf(items, '[AUG] - $2195') })
    ShopGb:AddToggle('ShopAutoAmmo', { Text = 'Auto Buy Ammo', Default = false })
    ShopGb:AddButton('Buy Selected', function()
        local gun = ov('ShopGunItem')
        if buyItem(gun) then getgenv().Library:Notify('Purchased ' .. tostring(gun), 2)
        else getgenv().Library:Notify('Could not buy ' .. tostring(gun), 2) end
    end)
    ShopGb:AddButton('Buy Ammo', function()
        local ammo = ammoItemFor(ov('ShopGunItem'))
        if ammo and buyItem(ammo) then getgenv().Library:Notify('Purchased ' .. ammo, 2)
        else getgenv().Library:Notify('No ammo for that gun in this shop', 2) end
    end)
    ShopGb:AddDivider()
    ShopGb:AddToggle('ShopAutoArmor', { Text = 'Auto Armor', Default = false })
    ShopGb:AddDropdown('ShopArmorItem', {
        Text = 'Armor item',
        Values = items,
        Default = indexOf(items, '[High-Medium Armor] - $2589'),
    })
    ShopGb:AddSlider('ShopArmorThreshold', { Text = 'Armor threshold', Default = 75, Min = 1, Max = 130, Rounding = 0 })
    ShopGb:AddToggle('ShopAutoFireArmor', { Text = 'Auto Fire Armor', Default = false })
    ShopGb:AddDropdown('ShopFireArmorItem', {
        Text = 'Fire armor item',
        Values = items,
        Default = indexOf(items, '[Fire Armor] - $4501'),
    })
    ShopGb:AddSlider('ShopFireArmorThreshold', { Text = 'Fire armor threshold', Default = 75, Min = 1, Max = 130, Rounding = 0 })

    -- cash aura: money drops sit in workspace.Ignored.Drop as "MoneyDrop" models with
    -- a ClickDetector, so re-firing that detector is all a pickup is
    task.spawn(function()
        while true do
            task.wait(cashOn and cashCooldown or 0.5)
            if cashOn then
                local ignored = workspace:FindFirstChild('Ignored')
                local drop = ignored and ignored:FindFirstChild('Drop')
                local root = characterRoot()
                if drop and root then
                    for _, item in ipairs(drop:GetChildren()) do
                        if item.Name == 'MoneyDrop' then
                            local pos = item:GetAttribute('OriginalPos') or item.Position
                            if (pos - root.Position).Magnitude <= cashRange then
                                local detector = item:FindFirstChildOfClass('ClickDetector')
                                if detector then pcall(function() fireclickdetector(detector) end) end
                            end
                        end
                    end
                end
            end
        end
    end)

    task.spawn(function()
        while task.wait(1) do
            if on('ShopAutoGun') or on('ShopAutoAmmo') then
                local gun = ov('ShopGunItem')
                local tag = gunTag(gun)
                if on('ShopAutoGun') and not ownsGun(tag) then buyItem(gun) end
                if on('ShopAutoAmmo') and ammoCount(tag) == 0 then
                    local ammo = ammoItemFor(gun)
                    if ammo then buyItem(ammo) end
                end
            end
            if on('ShopAutoArmor') then
                local current = armourValue('ArmorSave')
                if current and current < (ov('ShopArmorThreshold') or 75) then buyItem(ov('ShopArmorItem')) end
            end
            if on('ShopAutoFireArmor') then
                local current = armourValue('FireArmorSave')
                if current and current < (ov('ShopFireArmorThreshold') or 75) then buyItem(ov('ShopFireArmorItem')) end
            end
        end
    end)

    getgenv().Library:OnUnload(function()
        cashOn = false
        buying = true
    end)
end

--==============================================================================
--  VISUALS TAB: CAMERA
--  Field of view override plus the aspect-ratio stretch from the supplied
--  scripts.  The stretch works by scaling the camera's up vector, and it has to
--  be bound above RenderPriority.Camera or the camera controller overwrites it
--  every frame.
--==============================================================================
do
    local CAM_RS  = getgenv().RunService
    local CAM_CAM = getgenv().Camera

    local CameraGb = getgenv().Tabs.Visuals:AddLeftGroupbox('Camera')

    local fovOn, fovValue = false, 70
    local aspectOn, aspectX, aspectY = false, 16, 9
    local bound = false

    local function on(name) local t = Toggles[name] ; return t and t.Value end

    CameraGb:AddToggle('FovChangerEnabled', {
        Text = 'Field of view',
        Default = false,
        Callback = function(state) fovOn = state end,
    })
    CameraGb:AddSlider('FovChangerValue', {
        Text = 'FOV',
        Default = 70,
        Min = 40, Max = 120, Rounding = 0,
        Callback = function(value) fovValue = value end,
    })

    CameraGb:AddToggle('AspectRatioEnabled', {
        Text = 'Aspect ratio',
        Tooltip = 'stretch the world wider or taller than the screen',
        Default = false,
        Callback = function(state)
            aspectOn = state
            if not state then bound = false end
        end,
    })
    CameraGb:AddSlider('AspectRatioX', {
        Text = 'Aspect X',
        Default = 16,
        Min = 1, Max = 48, Rounding = 0,
        Callback = function(value) aspectX = value end,
    })
    CameraGb:AddSlider('AspectRatioY', {
        Text = 'Aspect Y',
        Default = 9,
        Min = 1, Max = 48, Rounding = 0,
        Callback = function(value) aspectY = value end,
    })

    local function updateAspectRatio()
        local camera = CAM_CAM
        if not (aspectOn and camera) then return end
        local ratio = aspectX / math.max(aspectY, 1)
        if ratio <= 0 then return end
        local cf = camera.CFrame
        camera.CFrame = CFrame.fromMatrix(cf.Position, cf.RightVector, cf.UpVector * ratio, -cf.LookVector)
    end

    CAM_RS.RenderStepped:Connect(function()
        if fovOn and CAM_CAM and CAM_CAM.FieldOfView ~= fovValue then
            pcall(function() CAM_CAM.FieldOfView = fovValue end)
        end
        if aspectOn and not bound then
            bound = true
            pcall(function()
                CAM_RS:BindToRenderStep('lunar_aspect_ratio', Enum.RenderPriority.Camera.Value + 2, updateAspectRatio)
            end)
        end
    end)

    getgenv().Library:OnUnload(function()
        pcall(function() CAM_RS:UnbindFromRenderStep('lunar_aspect_ratio') end)
    end)
end

--==============================================================================
--  VISUALS TAB: POST PROCESSING
--  Bloom, colour correction and sun rays, ported from the supplied scripts.  The
--  effects are created disabled and the originals' settings are captured so
--  switching a group off restores whatever the game was already doing.
--==============================================================================
do
    local PP_LIGHT = game:GetService('Lighting')

    local PostGb = getgenv().Tabs.Visuals:AddRightGroupbox('Post Processing')

    local function on(name) local t = Toggles[name] ; return t and t.Value end
    local function ov(name) local o = Options[name] ; return o and o.Value end

    local function makeEffect(className, folder)
        local existing = PP_LIGHT:FindFirstChild('lunar_' .. className)
        if existing then return existing end
        local effect = Instance.new(className)
        effect.Name = 'lunar_' .. className
        effect.Enabled = false
        effect.Parent = PP_LIGHT
        return effect
    end

    local bloom = makeEffect('BloomEffect')
    local colorCorrection = makeEffect('ColorCorrectionEffect')
    local sunRays = makeEffect('SunRaysEffect')

    local bloomDefaults = { bloom.Enabled, bloom.Intensity, bloom.Size, bloom.Threshold }
    local ccDefaults = { colorCorrection.Enabled, colorCorrection.TintColor, colorCorrection.Saturation, colorCorrection.Contrast, colorCorrection.Brightness }
    local sunDefaults = { sunRays.Enabled, sunRays.Spread, sunRays.Intensity }

    local function applyBloom()
        if not on('BloomEnabled') then
            bloom.Enabled = false
            return
        end
        pcall(function()
            bloom.Intensity = ov('BloomIntensity') or 0.4
            bloom.Size = ov('BloomSize') or 24
            bloom.Threshold = ov('BloomThreshold') or 0.95
            bloom.Enabled = true
        end)
    end

    local function applyColorCorrection()
        if not on('CCEnabled') then
            colorCorrection.Enabled = false
            return
        end
        pcall(function()
            colorCorrection.TintColor = ov('CCTint') or Color3.new(1, 1, 1)
            colorCorrection.Saturation = ov('CCSaturation') or 0
            colorCorrection.Contrast = ov('CCContrast') or 0
            colorCorrection.Brightness = ov('CCBrightness') or 0
            colorCorrection.Enabled = true
        end)
    end

    local function applySunRays()
        if not on('SunRaysEnabled') then
            sunRays.Enabled = false
            return
        end
        pcall(function()
            sunRays.Spread = ov('SunRaysSpread') or 0.1
            sunRays.Intensity = ov('SunRaysIntensity') or 0.25
            sunRays.Enabled = true
        end)
    end

    PostGb:AddToggle('BloomEnabled', { Text = 'Bloom', Default = false, Callback = applyBloom })
    PostGb:AddSlider('BloomIntensity', { Text = 'Bloom intensity', Default = 0.4, Min = 0, Max = 3, Rounding = 2, Callback = applyBloom })
    PostGb:AddSlider('BloomSize', { Text = 'Bloom size', Default = 24, Min = 0, Max = 56, Rounding = 0, Callback = applyBloom })
    PostGb:AddSlider('BloomThreshold', { Text = 'Bloom threshold', Default = 0.95, Min = 0, Max = 2, Rounding = 2, Callback = applyBloom })
    PostGb:AddDivider()
    PostGb:AddToggle('CCEnabled', { Text = 'Color correction', Default = false, Callback = applyColorCorrection })
    PostGb:AddSlider('CCSaturation', { Text = 'Saturation', Default = 0, Min = -1, Max = 1, Rounding = 2, Callback = applyColorCorrection })
    PostGb:AddSlider('CCContrast', { Text = 'Contrast', Default = 0, Min = -1, Max = 1, Rounding = 2, Callback = applyColorCorrection })
    PostGb:AddSlider('CCBrightness', { Text = 'Brightness', Default = 0, Min = -1, Max = 1, Rounding = 2, Callback = applyColorCorrection })
    PostGb:AddLabel('Tint'):AddColorPicker('CCTint', {
        Default = Color3.new(1, 1, 1),
        Title = 'Color tint',
        Callback = applyColorCorrection,
    })
    PostGb:AddDivider()
    PostGb:AddToggle('SunRaysEnabled', { Text = 'Sun rays', Default = false, Callback = applySunRays })
    PostGb:AddSlider('SunRaysSpread', { Text = 'Spread', Default = 0.1, Min = 0, Max = 1, Rounding = 2, Callback = applySunRays })
    PostGb:AddSlider('SunRaysIntensity', { Text = 'Intensity', Default = 0.25, Min = 0, Max = 1, Rounding = 2, Callback = applySunRays })

    getgenv().Library:OnUnload(function()
        pcall(function()
            bloom.Enabled, bloom.Intensity, bloom.Size, bloom.Threshold = table.unpack(bloomDefaults)
            colorCorrection.Enabled, colorCorrection.TintColor, colorCorrection.Saturation,
                colorCorrection.Contrast, colorCorrection.Brightness = table.unpack(ccDefaults)
            sunRays.Enabled, sunRays.Spread, sunRays.Intensity = table.unpack(sunDefaults)
            bloom:Destroy(); colorCorrection:Destroy(); sunRays:Destroy()
        end)
    end)
end

--==============================================================================
--  VISUALS TAB: SKELETON ESP
--  Draws a bone graph over every other player, R15 or R6, with Drawing lines
--  pooled per player so a busy server does not allocate a line per bone per frame.
--==============================================================================
do
    local SK_PLRS = getgenv().Players
    local SK_CAM  = getgenv().Camera
    local sk_lp   = SK_PLRS.LocalPlayer

    local SkeletonGb = getgenv().Tabs.Visuals:AddRightGroupbox('Skeleton ESP')

    local skeletonOn, outlineOn = false, false
    local boneColor = Color3.fromRGB(255, 255, 255)
    local thickness = 1

    local function ov(name) local o = Options[name] ; return o and o.Value end

    local BONES_R15 = {
        { 'Head', 'UpperTorso' }, { 'UpperTorso', 'LowerTorso' },
        { 'UpperTorso', 'RightUpperArm' }, { 'RightUpperArm', 'RightLowerArm' }, { 'RightLowerArm', 'RightHand' },
        { 'UpperTorso', 'LeftUpperArm' }, { 'LeftUpperArm', 'LeftLowerArm' }, { 'LeftLowerArm', 'LeftHand' },
        { 'LowerTorso', 'RightUpperLeg' }, { 'RightUpperLeg', 'RightLowerLeg' }, { 'RightLowerLeg', 'RightFoot' },
        { 'LowerTorso', 'LeftUpperLeg' }, { 'LeftUpperLeg', 'LeftLowerLeg' }, { 'LeftLowerLeg', 'LeftFoot' },
    }
    local BONES_R6 = {
        { 'Head', 'Torso' }, { 'Torso', 'Left Arm' }, { 'Torso', 'Right Arm' },
        { 'Torso', 'Left Leg' }, { 'Torso', 'Right Leg' },
    }

    local pool = {}

    local function skeletonFor(char)
        if char:FindFirstChild('UpperTorso') then return BONES_R15 end
        if char:FindFirstChild('Torso') then return BONES_R6 end
        return nil
    end

    -- two lines per bone: an outline pass drawn underneath, then the bone itself
    local function linesFor(plr, count)
        local entry = pool[plr]
        if not entry then
            entry = { bones = {}, outlines = {} }
            pool[plr] = entry
        end
        while #entry.bones < count do
            local outline = Drawing.new('Line')
            outline.Fading = false
            outline.ZIndex = 1
            table.insert(entry.outlines, outline)
            local bone = Drawing.new('Line')
            bone.Fading = false
            bone.ZIndex = 2
            table.insert(entry.bones, bone)
        end
        return entry
    end

    local function hide(entry)
        for _, line in ipairs(entry.bones) do line.Visible = false end
        for _, line in ipairs(entry.outlines) do line.Visible = false end
    end

    local function release(entry)
        for _, line in ipairs(entry.bones) do pcall(function() line:Remove() end) end
        for _, line in ipairs(entry.outlines) do pcall(function() line:Remove() end) end
    end

    getgenv().SkeletonConnection = getgenv().RunService.RenderStepped:Connect(function()
        if not skeletonOn then
            for _, entry in pairs(pool) do hide(entry) end
            return
        end
        local color = boneColor
        local width = thickness
        for _, plr in ipairs(SK_PLRS:GetPlayers()) do
            local entry = pool[plr]
            if plr == sk_lp then
                if entry then hide(entry) end
            else
                local char = plr.Character
                local bones = char and skeletonFor(char)
                if not bones then
                    if entry then hide(entry) end
                else
                    entry = linesFor(plr, #bones)
                    for index, bone in ipairs(bones) do
                        local from = char:FindFirstChild(bone[1])
                        local to = char:FindFirstChild(bone[2])
                        local line = entry.bones[index]
                        local outline = entry.outlines[index]
                        if from and to then
                            local fromPos, fromVisible = SK_CAM:WorldToViewportPoint(from.Position)
                            local toPos, toVisible = SK_CAM:WorldToViewportPoint(to.Position)
                            if fromVisible and toVisible then
                                local a = Vector2.new(fromPos.X, fromPos.Y)
                                local b = Vector2.new(toPos.X, toPos.Y)
                                line.From, line.To = a, b
                                line.Color = color
                                line.Thickness = width
                                line.Visible = true
                                if outlineOn then
                                    outline.From, outline.To = a, b
                                    outline.Color = Color3.new(0, 0, 0)
                                    outline.Thickness = width + 2
                                    outline.Visible = true
                                else
                                    outline.Visible = false
                                end
                            else
                                line.Visible = false
                                outline.Visible = false
                            end
                        else
                            line.Visible = false
                            outline.Visible = false
                        end
                    end
                end
            end
        end
    end)

    SK_PLRS.PlayerRemoving:Connect(function(plr)
        local entry = pool[plr]
        if entry then
            release(entry)
            pool[plr] = nil
        end
    end)

    SkeletonGb:AddToggle('SkeletonEspEnabled', {
        Text = 'Skeleton',
        Default = false,
        Callback = function(state) skeletonOn = state end,
    })
    SkeletonGb:AddSlider('SkeletonEspThickness', {
        Text = 'Thickness',
        Default = 1,
        Min = 1, Max = 5, Rounding = 0,
        Callback = function(value) thickness = value end,
    })
    SkeletonGb:AddToggle('SkeletonEspOutline', {
        Text = 'Outline',
        Default = false,
        Callback = function(state) outlineOn = state end,
    })
    SkeletonGb:AddLabel('Bone color'):AddColorPicker('SkeletonEspColor', {
        Default = ACCENT,
        Title = 'Bone color',
        Callback = function(color) boneColor = color end,
    })

    getgenv().Library:OnUnload(function()
        skeletonOn = false
        for _, entry in pairs(pool) do release(entry) end
        pool = {}
    end)
end

--==============================================================================
--  HvH TAB: TRIGGERBOT
--  Fires the real weapon (via a synthetic mouse1) the moment a valid target
--  crosses the crosshair, so it works with whatever gun the game has equipped
--  rather than reimplementing each weapon's remote.
--==============================================================================
do
    local TB_PLRS = getgenv().Players
    local TB_CAM  = getgenv().Camera
    local TB_UIS  = getgenv().UserInputService
    local tb_lp   = TB_PLRS.LocalPlayer

    local TriggerGb = getgenv().Pages.Aim:AddRightGroupbox('Triggerbot')

    local triggerOn = false
    local triggerRadius, triggerDelay = 12, 0.05
    local lastShot = 0

    local function ov(name) local o = Options[name] ; return o and o.Value end

    local function isKO(plr)
        local char = plr.Character
        local bodyEffects = char and char:FindFirstChild('BodyEffects')
        local ko = bodyEffects and bodyEffects:FindFirstChild('K.O')
        return (ko and ko.Value) == true
    end

    local function targetUnderCrosshair()
        local partName = ov('TriggerbotHitPart') or 'Head'
        local mouse = TB_UIS:GetMouseLocation()
        local bestDist, best = math.huge, nil
        for _, plr in ipairs(TB_PLRS:GetPlayers()) do
            if plr ~= tb_lp and plr.Character and not isKO(plr) then
                local part = plr.Character:FindFirstChild(partName)
                if part then
                    local sp, onScreen = TB_CAM:WorldToViewportPoint(part.Position)
                    if onScreen then
                        local dist = (Vector2.new(sp.X, sp.Y) - mouse).Magnitude
                        if dist <= triggerRadius and dist < bestDist then
                            bestDist, best = dist, plr
                        end
                    end
                end
            end
        end
        return best
    end

    local function fireMouse()
        local now = os.clock()
        if now - lastShot < triggerDelay then return end
        lastShot = now
        local mouse = TB_UIS:GetMouseLocation()
        pcall(function()
            local vim = game:GetService('VirtualInputManager')
            vim:SendMouseButtonEvent(mouse.X, mouse.Y, 0, true, game, 0)
            task.wait(0.02)
            vim:SendMouseButtonEvent(mouse.X, mouse.Y, 0, false, game, 0)
        end)
    end

    task.spawn(function()
        while task.wait() do
            if not triggerOn then continue end
            if TB_UIS:GetFocusedTextBox() then continue end
            local char = tb_lp.Character
            local tool = char and char:FindFirstChildOfClass('Tool')
            if not (tool and tool:FindFirstChild('Ammo')) then continue end
            if targetUnderCrosshair() then fireMouse() end
        end
    end)

    TriggerGb:AddToggle('TriggerbotEnabled', {
        Text = 'Enabled',
        Default = false,
        Callback = function(state) triggerOn = state end,
    }):AddKeyPicker('TriggerbotKey', {
        Default = 'none',
        Mode = 'Toggle',
        Text = 'Triggerbot',
        SyncToggleState = true,
        Callback = function(state) triggerOn = state == true end,
    })
    TriggerGb:AddDropdown('TriggerbotHitPart', {
        Text = 'Hit part',
        Values = { 'Head', 'UpperTorso', 'HumanoidRootPart', 'LowerTorso' },
        Default = 'Head',
    })
    TriggerGb:AddSlider('TriggerbotRadius', {
        Text = 'Crosshair radius',
        Default = 12,
        Min = 1, Max = 60, Rounding = 0,
        Callback = function(value) triggerRadius = value end,
    })
    TriggerGb:AddSlider('TriggerbotDelay', {
        Text = 'Shot delay (s)',
        Default = 0.05,
        Min = 0.01, Max = 1, Rounding = 2,
        Callback = function(value) triggerDelay = value end,
    })

    getgenv().Library:OnUnload(function() triggerOn = false end)
end

--==============================================================================
--  HvH TAB: CAMERA LOCK
--  Smoothed camera lock onto the closest enemy, ported from the supplied scripts.
--==============================================================================
do
    local CL_RS   = getgenv().RunService
    local CL_PLRS = getgenv().Players
    local CL_CAM  = getgenv().Camera
    local cl_lp   = CL_PLRS.LocalPlayer

    local LockGb = getgenv().Pages.Aim:AddRightGroupbox('Camera Lock')

    local lockOn = false
    local lockRange, lockSmooth = 300, 0.25

    local function ov(name) local o = Options[name] ; return o and o.Value end

    local function closestEnemy()
        local char = cl_lp.Character
        local root = char and char:FindFirstChild('HumanoidRootPart')
        if not root then return nil end
        local bestDist, best = math.huge, nil
        for _, plr in ipairs(CL_PLRS:GetPlayers()) do
            if plr ~= cl_lp and plr.Character then
                local head = plr.Character:FindFirstChild('Head')
                if head then
                    local dist = (head.Position - root.Position).Magnitude
                    if dist <= lockRange and dist < bestDist then
                        bestDist, best = dist, head
                    end
                end
            end
        end
        return best
    end

    CL_RS.RenderStepped:Connect(function()
        if not (lockOn and CL_CAM) then return end
        local head = closestEnemy()
        if not head then return end
        local camera = CL_CAM
        local current = camera.CFrame
        local target = CFrame.lookAt(current.Position, head.Position)
        local alpha = math.clamp(1 - lockSmooth, 0.01, 1)
        pcall(function() camera.CFrame = current:Lerp(target, alpha) end)
    end)

    LockGb:AddToggle('CameraLockEnabled', {
        Text = 'Camera lock',
        Default = false,
        Callback = function(state) lockOn = state end,
    })
    LockGb:AddSlider('CameraLockRange', {
        Text = 'Range',
        Default = 300,
        Min = 10, Max = 1000, Rounding = 0,
        Callback = function(value) lockRange = value end,
    })
    LockGb:AddSlider('CameraLockSmoothness', {
        Text = 'Smoothness',
        Default = 0.25,
        Min = 0, Max = 1, Rounding = 2,
        Callback = function(value) lockSmooth = value end,
    })
end

--==============================================================================
--  MISC TAB: CHAT
--  Chat spam, and the same message pipeline a "kill say" feature needs.  Supports
--  both the modern TextChatService and the legacy chat event the older Da Hood
--  scripts targeted.
--==============================================================================
do
    local ChatGb = getgenv().Pages.Player:AddRightGroupbox('Chat')

    local spamOn = false
    local spamText, spamDelay = 'lunar.lua on top', 1

    local function sendChat(message)
        message = tostring(message or '')
        if message == '' then return end
        local sent = false
        pcall(function()
            local textChat = game:GetService('TextChatService')
            if textChat.ChatVersion == Enum.ChatVersion.TextChatService then
                local channels = textChat:FindFirstChild('TextChannels')
                local general = channels and channels:FindFirstChild('RBXGeneral')
                if general then
                    general:SendAsync(message)
                    sent = true
                end
            end
        end)
        if sent then return end
        pcall(function()
            local events = game:GetService('ReplicatedStorage'):FindFirstChild('DefaultChatSystemChatEvents')
            local request = events and events:FindFirstChild('SayMessageRequest')
            if request then request:FireServer(message, 'All') end
        end)
    end

    task.spawn(function()
        while true do
            task.wait(math.max(tonumber(spamDelay) or 1, 0.5))
            if spamOn then pcall(sendChat, spamText) end
        end
    end)

    ChatGb:AddToggle('ChatSpamEnabled', {
        Text = 'Chat spam',
        Default = false,
        Callback = function(state) spamOn = state end,
    })
    ChatGb:AddInput('ChatSpamMessage', {
        Text = 'Message',
        Default = 'lunar.lua on top',
        Placeholder = 'message to repeat',
        Callback = function(value)
            if value ~= nil and value ~= '' then spamText = value end
        end,
    })
    ChatGb:AddSlider('ChatSpamDelay', {
        Text = 'Delay (s)',
        Default = 1,
        Min = 0.5, Max = 30, Rounding = 1,
        Callback = function(value) spamDelay = value end,
    })
    ChatGb:AddInput('ChatSayInput', {
        Text = 'Say once',
        Default = '',
        Placeholder = 'message',
        Callback = function(value) sendChat(value) end,
    })

    getgenv().Library:OnUnload(function() spamOn = false end)
end

-- themes, profiles, tweening, the watermark / keybind-list toggles and unload all
-- live on the Settings page Thugsense builds (see AddSettingsTab), so there is
-- nothing left to wire up here beyond starting the config autoload.
if getgenv().IsMobile then
    task.delay(0.75, function()
        getgenv().Library:Notify('Mobile layout: tap the round button to hide or show the menu', 5)
    end)
end

getgenv().SaveManager:SetLibrary(getgenv().Library)
getgenv().ThemeManager:SetLibrary(getgenv().Library)
getgenv().SaveManager:SetFolder('lunar/config')

-- Studio gets a permanent red accent so it is obvious the menu is running there
if game:GetService("RunService"):IsStudio() then
    task.spawn(function()
        while task.wait(0.5) do
            pcall(function()
                if getgenv().Library then
                    getgenv().Library.AccentColor = Color3.fromRGB(255, 0, 0)
                    getgenv().Library:UpdateColors()
                end
            end)
        end
    end)
end

if Options.NotifPos then
    Options.NotifPos:OnChanged(function() getgenv().UpdateNotifPosition(Options.NotifPos.Value) end)
end

if Toggles.VisualizeStrafe then
    Toggles.VisualizeStrafe:OnChanged(function()
        if Toggles.VisualizeStrafe.Value and getgenv().StrafeConnection then getgenv().createStrafeVisualizer() else getgenv().destroyStrafeVisualizer() end
    end)
end

if Toggles.SpectateTarget then
    Toggles.SpectateTarget:OnChanged(function()
        if (Toggles.SpectateTarget and Toggles.SpectateTarget.Value) then getgenv().startSpectate() else
            if getgenv().SpectateConnection then getgenv().SpectateConnection:Disconnect() ; getgenv().SpectateConnection = nil end
            getgenv().resetStrafeCamera()
        end
    end)
end

getgenv().SaveManager:IgnoreThemeSettings()
getgenv().SaveManager:SetIgnoreIndexes({})
getgenv().SaveManager:LoadAutoloadConfig()
end

-- Everything above runs inside one function whose locals share a single Luau
-- register budget.  If any section throws, the rest of this chunk is aborted,
-- which silently leaves every later groupbox built but empty (Skins, Visuals,
-- Performance and the whole tail).  Run it guarded so a failure names itself
-- in the console instead of blanking half the menu.
do
    local builtOk, buildErr = pcall(runFeatureSections)
    if not builtOk then
        local msg = '[lunar.lua] build error: ' .. tostring(buildErr)
        warn(msg)
        pcall(function() lib:Notify(msg, 8) end)
    end
end

-- a sub-tabbed page shows nothing until one of its sub-tabs is active, and Thugsense
-- only ever opens the first sub-tab in the whole window - then turns it off again the
-- moment any other sub-tab icon is clicked.  Make sure every sub-tabbed page has a
-- sub-tab showing, and re-assert it whenever the menu is opened.
local function refreshSubTabs()
    local window = tsWindow
    if type(window) ~= 'table' or type(window.Pages) ~= 'table' then return end
    for _, page in ipairs(window.Pages) do
        if page.HasSubtabs and type(page.Window) == 'table' and type(page.Window.SubPages) == 'table' then
            local chosen
            for _, sub in ipairs(page.Window.SubPages) do
                if sub.Page == page then
                    if sub.Active then chosen = sub break end
                    if not chosen then chosen = sub end
                end
            end
            if chosen then showSubPage(chosen) end
        end
    end
end

task.defer(refreshSubTabs)
task.delay(1, refreshSubTabs)

-- reopening the menu must not land on a sub-tabbed page that has gone blank
if type(tsWindow) == 'table' and type(tsWindow.SetOpen) == 'function' then
    local setOpen = tsWindow.SetOpen
    tsWindow.SetOpen = function(self2, bool)
        setOpen(self2, bool)
        if bool then task.defer(refreshSubTabs) end
    end
end

-- Thugsense defines Init while it builds its settings page: it loads the config
-- marked "Set As Autoload".  Called last so every widget already exists.
pcall(function()
    if getgenv().Library and getgenv().Library.Init then getgenv().Library:Init() end
end)