-- skyware ragebot+flickbot extract
local AUTO_EXECUTE = true
local COUNTDOWN_ON_FIRST_RUN = false
local LOAD_DELAY = 10

local SRC = [=====[
loadstring([[
    function LPH_NO_VIRTUALIZE(f) return f end
    function LPH_JIT_MAX(f) return f end
    function LPH_JIT(f) return f end
    function LPH_ENCFUNC(f) return f end
]])();

eli_inext = function(t, i)
    i = i + 1;
    local v = t[i];
    if v ~= nil then return i, v end;
end;
eli_ipairs = function(t) return eli_inext, t, 0 end;
eli_pairs = function(t) return next, t, nil end;
if not cloneref then cloneref = function(ref) return ref end end


getgenv().silent_load = false;

local Library = (function()

local InputService = game:GetService('UserInputService');
local TextService = game:GetService('TextService');
local HttpService = game:GetService('HttpService');
local CoreGui = cloneref(game:GetService('CoreGui'));
local Teams = game:GetService('Teams');
local Players = game:GetService('Players');
local RunService = game:GetService('RunService');
local TweenService = game:GetService('TweenService');
local SoundService = game:GetService('SoundService');
local RenderStepped = RunService.RenderStepped;
local LocalPlayer = Players.LocalPlayer;
local Mouse = cloneref(LocalPlayer:GetMouse());

local function IsPrimaryPress(Input)
    return Input.UserInputType == Enum.UserInputType.MouseButton1
        or Input.UserInputType == Enum.UserInputType.Touch;
end;

local function IsPressActive(Input)
    if Input.UserInputType == Enum.UserInputType.Touch then
        return Input.UserInputState ~= Enum.UserInputState.End
            and Input.UserInputState ~= Enum.UserInputState.Cancel;
    end;
    return InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1);
end;

local function GetPointerPosition(Input)
    if Input and Input.UserInputType == Enum.UserInputType.Touch then
        return Vector2.new(Input.Position.X, Input.Position.Y);
    end;
    return Vector2.new(Mouse.X, Mouse.Y);
end;

local IsTouchDevice = InputService.TouchEnabled and not InputService.MouseEnabled;

local ProtectGui = protectgui or (syn and syn.protect_gui) or (function() end);

local ScreenGui = Instance.new('ScreenGui');
ProtectGui(ScreenGui);

ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global;
ScreenGui.Parent = CoreGui;

local Toggles = {};
local Options = {};

getgenv().Toggles = Toggles;
getgenv().Options = Options;

local BaseGroupbox;

local ENUM_UI_FONT_ENTRIES = {
    { 'Legacy', 'Legacy' },
    { 'Arial', 'Arial' },
    { 'Arial Bold', 'ArialBold' },
    { 'Arimo', 'Arimo' },
    { 'Arimo Bold', 'ArimoBold' },
    { 'Gotham', 'Gotham' },
    { 'Gotham Medium', 'GothamMedium' },
    { 'Gotham Bold', 'GothamBold' },
    { 'Gotham Black', 'GothamBlack' },
    { 'Roboto', 'Roboto' },
    { 'Roboto Mono', 'RobotoMono' },
    { 'Roboto Condensed', 'RobotoCondensed' },
    { 'Source Sans', 'SourceSans' },
    { 'Source Sans Bold', 'SourceSansBold' },
    { 'Source Sans Semibold', 'SourceSansSemibold' },
    { 'Source Sans Light', 'SourceSansLight' },
    { 'Source Sans Italic', 'SourceSansItalic' },
    { 'Ubuntu', 'Ubuntu' },
    { 'Bangers', 'Bangers' },
    { 'Arcade', 'Arcade' },
    { 'Code', 'Code' },
    { 'Creepster', 'Creepster' },
    { 'Builder Sans', 'BuilderSans' },
    { 'Builder Sans Medium', 'BuilderSansMedium' },
    { 'Builder Sans Bold', 'BuilderSansBold' },
    { 'Builder Sans ExtraBold', 'BuilderSansExtraBold' },
    { 'SciFi', 'SciFi' },
    { 'Highway', 'Highway' },
    { 'Cartoon', 'Cartoon' },
    { 'Fantasy', 'Fantasy' },
    { 'Fondamento', 'Fondamento' },
    { 'Garamond', 'Garamond' },
    { 'Bodoni', 'Bodoni' },
    { 'Merriweather', 'Merriweather' },
    { 'Oswald', 'Oswald' },
    { 'Patrick Hand', 'PatrickHand' },
    { 'Permanent Marker', 'PermanentMarker' },
    { 'Special Elite', 'SpecialElite' },
    { 'Titillium Web', 'TitilliumWeb' },
    { 'Nunito', 'Nunito' },
    { 'Jura', 'Jura' },
    { 'Michroma', 'Michroma' },
    { 'Antique', 'Antique' },
    { 'Amatic SC', 'AmaticSC' },
    { 'Denk One', 'DenkOne' },
    { 'Josefin Sans', 'JosefinSans' },
    { 'Kalam', 'Kalam' },
    { 'Luckiest Guy', 'LuckiestGuy' },
    { 'Sarpanch', 'Sarpanch' },
};

local ENUM_UI_FONTS = {};
for _, entry in ENUM_UI_FONT_ENTRIES do
    local displayName, enumName = entry[1], entry[2];
    if not ENUM_UI_FONTS[displayName] then
        local ok, enumFont = pcall(function()
            return Enum.Font[enumName];
        end);
        if ok and enumFont then
            ENUM_UI_FONTS[displayName] = enumFont;
        end;
    end;
end;

local CUSTOM_UI_FONTS = {
    ['ProggyTiny'] = {
        Ttf = 'ProggyTiny.ttf',
        Url = 'https://github.com/ocornut/imgui/raw/master/misc/fonts/ProggyTiny.ttf',
    },
    ['ProggyClean'] = {
        Ttf = 'ProggyClean.ttf',
        Url = 'https://github.com/ocornut/imgui/raw/master/misc/fonts/ProggyClean.ttf',
    },
    ['XP Tahoma'] = {
        Ttf = 'XP Tahoma.ttf',
        Url = 'https://github.com/sametexe001/luas/raw/refs/heads/main/fonts/TAHOMA-8PT-BOLD-WINDOWS-XP.TTF',
    },
    ['Smallest Pixel'] = {
        Ttf = 'smallest_pixel-7.ttf',
        Url = 'https://raw.githubusercontent.com/sametexe001/luas/main/smallest_pixel-7.ttf',
    },
    ['Tahoma'] = {
        FontFile = 'Tahoma.font',
        AltFontFiles = { 'skyware/Tahoma.font', 'library/Tahoma.font', 'Tahoma.ttf', 'library/Tahoma.ttf' },
    },
};

local function tryFontFromAsset(path)
    if not isfile or not isfile(path) then
        return nil;
    end;

    local okAsset, assetPath = pcall(getcustomasset, path);
    if not okAsset or not assetPath then
        return nil;
    end;

    local okFont, face = pcall(Font.new, assetPath, Enum.FontWeight.Regular, Enum.FontStyle.Normal);
    if okFont and face then
        return face;
    end;

    return nil;
end;

local function registerDownloadedFont(name, entry)
    if not (writefile and isfile and getcustomasset and game.HttpGet) then
        return nil;
    end;

    local ok, face = pcall(function()
        local ttfName = entry.Ttf;
        if not isfile(ttfName) then
            writefile(ttfName, game:HttpGet(entry.Url));
        end;

        local fontFile = name .. '.font';
        if isfile(fontFile) then
            delfile(fontFile);
        end;

        local info = {
            name = name,
            faces = {
                {
                    name = 'Normal',
                    weight = 400,
                    style = 'Normal',
                    assetId = getcustomasset(ttfName),
                },
            },
        };

        writefile(fontFile, HttpService:JSONEncode(info));
        return Font.new(getcustomasset(fontFile), Enum.FontWeight.Regular, Enum.FontStyle.Normal);
    end);

    if ok and face then
        return face;
    end;

    return nil;
end;

local function loadCustomFontFace(name, entry)
    if entry.FontFile or entry.AltFontFiles then
        local paths = { entry.FontFile };
        if entry.AltFontFiles then
            for _, path in entry.AltFontFiles do
                table.insert(paths, path);
            end;
        end;

        for _, path in paths do
            local face = tryFontFromAsset(path);
            if face then
                return face;
            end;
        end;
    end;

    if entry.Ttf and entry.Url then
        return registerDownloadedFont(name, entry);
    end;

    return nil;
end;

local function resolveEnumFontFace(enumFont)
    local ok, face = pcall(Font.fromEnum, enumFont);
    if ok and face then
        return face, enumFont;
    end;

    return nil, enumFont;
end;

local DefaultUIFont = 'Builder Sans ExtraBold';
local InitialFontFace, InitialEnumFont = resolveEnumFontFace(Enum.Font.BuilderSansExtraBold);
if not InitialFontFace then
    InitialFontFace = loadCustomFontFace('XP Tahoma', CUSTOM_UI_FONTS['XP Tahoma'])
        or select(1, resolveEnumFontFace(Enum.Font.Code));
    InitialEnumFont = Enum.Font.Code;
end;

local Library = {
    Registry = {};
    RegistryMap = {};

    HudRegistry = {};

    FontColor = Color3.fromHex("ffffff");
    MainColor = Color3.fromHex("0d0d0d");
    BackgroundColor = Color3.fromHex("000000");
    AccentColor = Color3.fromHex("ffffff");
    OutlineColor = Color3.fromHex("2e2e2e");
    SelectedTabColor = Color3.fromHex("000000");
    GradientColor = Color3.fromHex("8c8c8c");
    ShadowColor = Color3.new(0, 0, 0);
    ShadowSize = 0;
    ShadowOffset = 0;
    RiskColor = Color3.fromRGB(255, 50, 50),

    Black = Color3.new(0, 0, 0);
    Font = InitialEnumFont or Enum.Font.BuilderSansExtraBold;
    FontFace = InitialFontFace;
    CurrentUIFont = DefaultUIFont;
    FontCache = {};
    EnumUIFonts = ENUM_UI_FONTS;
    CustomUIFonts = CUSTOM_UI_FONTS;

    OverlayGlowEnabled = false;
    OverlayGlowColor = Color3.fromHex('ffffff');

    OpenedFrames = {};
    DependencyBoxes = {};
    Overlays = {};
    EnemyPlayers = {};
    AllCloseOverlays = false;
    MenuOpen = true;
    NotificationSpot = 'Top Right';
    NotificationAnimation = 'Slide Right to Left';
    ToggleSoundEnabled = true;
    NotificationSoundEnabled = true;
    SliderSoundEnabled = true;
    ToggleSoundVolume = 1;
    ToggleSoundSpeed = 1;
    NotificationSoundVolume = 1;
    NotificationSoundSpeed = 1;
    SliderSoundVolume = 1;
    SliderSoundSpeed = 1;
    MobileOverlayScale = 0.55;
    MobilePickerScale = 0.6;
    ZIndexBase = nil;
    OverlayZIndexBase = nil;
    GradientLabels = {};
    AccentTitleLabels = {};
    PopupZIndexCache = setmetatable({}, { __mode = 'k' });

    Signals = {};
    ScreenGui = ScreenGui;
};

local RainbowStep = 0;
local Hue = 0;
local RainbowAccum = 0;

table.insert(Library.Signals, RenderStepped:Connect(LPH_NO_VIRTUALIZE(function(Delta)
    RainbowAccum += Delta;
    if RainbowAccum < 0.05 then
        return
    end;

    Hue = Hue + (RainbowAccum * 0.15);
    RainbowAccum = 0;

    if Hue > 1 then
        Hue = 0;
    end;

    Library.CurrentRainbowHue = Hue;
    Library.CurrentRainbowColor = Color3.fromHSV(Hue, 0.8, 1);
end)));

local function GetPlayersString()
    local PlayerList = Players:GetPlayers();

    for i = 1, #PlayerList do
        PlayerList[i] = PlayerList[i].Name;
    end;

    table.sort(PlayerList, function(str1, str2) return str1 < str2 end);

    return PlayerList;
end;

local function GetTeamsString()
    local TeamList = Teams:GetTeams();

    for i = 1, #TeamList do
        TeamList[i] = TeamList[i].Name;
    end;

    table.sort(TeamList, function(str1, str2) return str1 < str2 end);

    return TeamList;
end;

function Library:SafeCallback(f, ...)
    if (not f) then
        return;
    end;

    if not Library.NotifyOnError then
        return f(...);
    end;

    local success, event = pcall(f, ...);

    if not success then
        local _, i = event:find(":%d+: ");

        if not i then
            return Library:Notify(event);
        end;

        return Library:Notify(event:sub(i + 1), 3);
    end;
end;

Library.UDim2OffsetToString = function(udim2)
    return string.format('%d, %d', udim2.X.Offset, udim2.Y.Offset);
end;
Library.StringToUDim2Offset = function(str)
    local x, y = str:match('([^,]+),%s*([^,]+)');

    return UDim2.fromOffset(tonumber(x), tonumber(y));
end;

function Library:AttemptSave()
    if Library.SaveManager then
        Library.SaveManager:Save();
    end;
end;

function Library:Create(Class, Properties)
    local _Instance = Class;

    if type(Class) == 'string' then
        _Instance = Instance.new(Class);
    end;

    if Properties and type(Properties.ZIndex) == 'number' and Library.OverlayZIndexBase and Properties.ZIndex < 100 then
        Properties.ZIndex = Library.OverlayZIndexBase + Properties.ZIndex;
    end;

    for Property, Value in next, Properties do
        _Instance[Property] = Value;
    end;

    if Library.FontFace and (_Instance:IsA('TextLabel') or _Instance:IsA('TextButton') or _Instance:IsA('TextBox')) then
        if not Properties or not Properties.FontFace then
            pcall(function()
                _Instance.FontFace = Library.FontFace;
            end);
        end;
    elseif (_Instance:IsA('TextLabel') or _Instance:IsA('TextButton') or _Instance:IsA('TextBox')) and (not Properties or not Properties.Font) then
        _Instance.Font = Library.Font;
    end;

    return _Instance;
end;

function Library:ApplyTextStroke(Inst)
    Inst.TextStrokeTransparency = 1;

    Library:Create('UIStroke', {
        Color = Color3.new(0, 0, 0);
        Thickness = 1;
        LineJoinMode = Enum.LineJoinMode.Miter;
        Parent = Inst;
    });
end;

function Library:CreateLabel(Properties, IsHud)
    local _Instance = Library:Create('TextLabel', {
        BackgroundTransparency = 1;
        Font = Library.Font;
        Text = '';
        TextColor3 = Library.FontColor;
        TextSize = 13;
        TextStrokeTransparency = 0;
    });

    Library:ApplyTextStroke(_Instance);

    Library:AddToRegistry(_Instance, {
        TextColor3 = 'FontColor';
    }, IsHud);

    return Library:Create(_Instance, Properties);
end;

function Library:MakeDraggable(Instance, Cutoff)
    Instance.Active = true;
    local CutoffHeight = Cutoff or 40;

    local Dragging = false;
    local DragInput = nil;
    local DragPreview = nil;
    local DragStart = nil;
    local StartPos = nil;

    Instance.InputBegan:Connect(function(Input)
        if not IsPrimaryPress(Input) then return end;

        if Dragging then return end;

        local Pointer = GetPointerPosition(Input);

        if (Pointer.Y - Instance.AbsolutePosition.Y) > CutoffHeight then return end;

        if DragPreview then
            DragPreview:Destroy();
            DragPreview = nil;
        end;

        Dragging = true;
        DragInput = Input;
        DragStart = Pointer;
        StartPos = Instance.Position;

        DragPreview = Library:Create("Frame", {
            BackgroundColor3 = Library.AccentColor,
            BackgroundTransparency = 0.75,
            BorderColor3 = Library.AccentColor,
            BorderSizePixel = 5,
            Position = StartPos,
            Size = Instance.Size,
            AnchorPoint = Instance.AnchorPoint,
            ZIndex = 9999,
            Parent = Library.ScreenGui,
        });
    end);

    InputService.InputChanged:Connect(LPH_NO_VIRTUALIZE(function(Input)
        if not Dragging or not DragPreview then return end;

        if Input == DragInput or (Input.UserInputType == Enum.UserInputType.MouseMovement and DragInput.UserInputType == Enum.UserInputType.MouseButton1) then
            local Current = GetPointerPosition(Input);
            local Delta = Current - DragStart;

            DragPreview.Position = UDim2.new(
                StartPos.X.Scale,
                StartPos.X.Offset + Delta.X,
                StartPos.Y.Scale,
                StartPos.Y.Offset + Delta.Y
            );
        end;
    end));

    InputService.InputEnded:Connect(function(Input)
        if not Dragging or not DragPreview then return end;

        if Input == DragInput or (Input.UserInputType == Enum.UserInputType.MouseButton1 and DragInput.UserInputType == Enum.UserInputType.MouseButton1) then
            Dragging = false;
            DragInput = nil;

            Instance.Position = DragPreview.Position;

            DragPreview:Destroy();
            DragPreview = nil;
        end;
    end);
end;

function Library:AddToolTip(InfoStr, HoverInstance)
    local X, Y = Library:GetTextBounds(InfoStr, Library.Font, 14);
    local Tooltip = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor,
        BorderColor3 = Library.OutlineColor,

        Size = UDim2.fromOffset(X + 5, Y + 4),
        ZIndex = 100,
        Parent = Library.ScreenGui,

        Visible = false,
    });

    local Label = Library:CreateLabel({
        Position = UDim2.fromOffset(3, 1),
        Size = UDim2.fromOffset(X, Y);
        TextSize = 14;
        Text = InfoStr,
        TextColor3 = Library.FontColor,
        TextXAlignment = Enum.TextXAlignment.Left;
        ZIndex = Tooltip.ZIndex + 1,

        Parent = Tooltip;
    });

    Library:AddToRegistry(Tooltip, {
        BackgroundColor3 = 'MainColor';
        BorderColor3 = 'OutlineColor';
    });

    Library:AddToRegistry(Label, {
        TextColor3 = 'FontColor',
    });

    local IsHovering = false;

    HoverInstance.MouseEnter:Connect(function()
        if Library:MouseIsOverOpenedFrame() then
            return
        end;

        IsHovering = true;

        Tooltip.Position = UDim2.fromOffset(Mouse.X + 15, Mouse.Y + 12);
        Tooltip.Visible = true;

        while IsHovering do
            RunService.Heartbeat:Wait();
            Tooltip.Position = UDim2.fromOffset(Mouse.X + 15, Mouse.Y + 12);
        end;
    end);

    HoverInstance.MouseLeave:Connect(function()
        IsHovering = false;
        Tooltip.Visible = false;
    end);
end;

function Library:OnHighlight(HighlightInstance, Instance, Properties, PropertiesDefault)
    local activeTweens = {};

    HighlightInstance.MouseEnter:Connect(function()
        local Reg = Library.RegistryMap[Instance];

        for Property, ColorIdx in next, Properties do
            local targetValue = Library[ColorIdx] or ColorIdx;
            if typeof(targetValue) == "Color3" then
                if activeTweens[Property] then activeTweens[Property]:Cancel() end;
                local tween = TweenService:Create(Instance, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    [Property] = targetValue
                });
                activeTweens[Property] = tween;
                tween:Play();
            else
                Instance[Property] = targetValue;
            end;

            if Reg and Reg.Properties[Property] then
                Reg.Properties[Property] = ColorIdx;
            end;
        end;
    end);

    HighlightInstance.MouseLeave:Connect(function()
        local Reg = Library.RegistryMap[Instance];

        for Property, ColorIdx in next, PropertiesDefault do
            local targetValue = Library[ColorIdx] or ColorIdx;
            if typeof(targetValue) == "Color3" then
                if activeTweens[Property] then activeTweens[Property]:Cancel() end;
                local tween = TweenService:Create(Instance, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    [Property] = targetValue
                });
                activeTweens[Property] = tween;
                tween:Play();
            else
                Instance[Property] = targetValue;
            end;

            if Reg and Reg.Properties[Property] then
                Reg.Properties[Property] = ColorIdx;
            end;
        end;
    end);
end;

function Library:MouseIsOverOpenedFrame()
    for Frame, _ in next, Library.OpenedFrames do
        local AbsPos, AbsSize = Frame.AbsolutePosition, Frame.AbsoluteSize;

        if Mouse.X >= AbsPos.X and Mouse.X <= AbsPos.X + AbsSize.X
            and Mouse.Y >= AbsPos.Y and Mouse.Y <= AbsPos.Y + AbsSize.Y then

            return true;
        end;
    end;
end;

function Library:IsMouseOverFrame(Frame)
    local AbsPos, AbsSize = Frame.AbsolutePosition, Frame.AbsoluteSize;

    if Mouse.X >= AbsPos.X and Mouse.X <= AbsPos.X + AbsSize.X
        and Mouse.Y >= AbsPos.Y and Mouse.Y <= AbsPos.Y + AbsSize.Y then

        return true;
    end;
end;

function Library:UpdateDependencyBoxes()
    for _, Depbox in next, Library.DependencyBoxes do
        Depbox:Update();
    end;
end;

function Library:MapValue(Value, MinA, MaxA, MinB, MaxB)
    return (1 - ((Value - MinA) / (MaxA - MinA))) * MinB + ((Value - MinA) / (MaxA - MinA)) * MaxB;
end;

function Library:GetTextBounds(Text, Font, Size, Resolution)
    function RemoveTags(str)
        str = str:gsub('<br%s*/>', '\n');

        return (str:gsub('<[^<>]->', ''));
    end;

    local CleanText = RemoveTags(Text);
    local Bounds = TextService:GetTextSize(CleanText, Size, Font, Resolution or Vector2.new(1920, 1080));

    return Bounds.X, Bounds.Y;
end;

function Library:ScanCustomUIFonts()
    local found = {};

    local function scanDir(prefix)
        if not listfiles then
            return
        end;

        local ok, files = pcall(listfiles, prefix);
        if not ok or not files then
            return
        end;

        for _, path in files do
            local lower = string.lower(path);
            if lower:sub(-5) == '.font' or lower:sub(-4) == '.ttf' then
                local name = path:match('([^/\\]+)%.%w+$');
                if name and not ENUM_UI_FONTS[name] and not CUSTOM_UI_FONTS[name] then
                    found[name] = path;
                end;
            end;
        end;
    end;

    scanDir('');
    scanDir('library');

    return found;
end;

function Library:GetUIFontNames()
    local names = {};
    local seen = {};

    local function add(name)
        if name and not seen[name] then
            seen[name] = true;
            table.insert(names, name);
        end;
    end;

    for name in CUSTOM_UI_FONTS do
        add(name);
    end;

    for name in ENUM_UI_FONTS do
        add(name);
    end;

    for name in self:ScanCustomUIFonts() do
        add(name);
    end;

    table.sort(names, function(a, b)
        local aCustom = CUSTOM_UI_FONTS[a] ~= nil;
        local bCustom = CUSTOM_UI_FONTS[b] ~= nil;
        if aCustom ~= bCustom then
            return aCustom;
        end;
        return a < b;
    end);

    return names;
end;

function Library:LoadUIFont(name)
    if self.FontCache[name] then
        return self.FontCache[name].FontFace, self.FontCache[name].Font;
    end;

    local customEntry = CUSTOM_UI_FONTS[name];
    if customEntry then
        local face = loadCustomFontFace(name, customEntry);
        if face then
            self.FontCache[name] = { FontFace = face, Font = Enum.Font.Code };
            return face, Enum.Font.Code;
        end;
    end;

    local enumFont = ENUM_UI_FONTS[name];
    if enumFont then
        local face = select(1, resolveEnumFontFace(enumFont));
        self.FontCache[name] = { FontFace = face, Font = enumFont };
        return face, enumFont;
    end;

    local scanned = self:ScanCustomUIFonts();
    local path = scanned[name];
    if path then
        local face = tryFontFromAsset(path);

        if not face and string.lower(path):sub(-4) == '.ttf' and writefile and isfile and getcustomasset then
            local fontFile = name .. '.font';
            if not isfile(fontFile) then
                local info = {
                    name = name,
                    faces = {
                        {
                            name = 'Normal',
                            weight = 400,
                            style = 'Normal',
                            assetId = getcustomasset(path),
                        },
                    },
                };
                writefile(fontFile, HttpService:JSONEncode(info));
            end;
            face = tryFontFromAsset(fontFile);
        end;

        if face then
            self.FontCache[name] = { FontFace = face, Font = Enum.Font.Code };
            return face, Enum.Font.Code;
        end;
    end;

    return self:LoadUIFont(DefaultUIFont);
end;

function Library:ApplyFontToAll()
    for _, inst in ScreenGui:GetDescendants() do
        if inst:IsA('TextLabel') or inst:IsA('TextButton') or inst:IsA('TextBox') then
            if self.FontFace then
                pcall(function()
                    inst.FontFace = self.FontFace;
                end);
            else
                inst.Font = self.Font;
            end;
        end;
    end;

    if self.LastWatermarkText then
        self:SetWatermark(self.LastWatermarkText);
    end;

    self:UpdateKeybindOverlaySize();
    self:UpdateWindowTabLayout();
end;

function Library:UpdateWindowTabLayout()
    if Library.MainWindow and Library.MainWindow.UpdateTabLayout then
        Library.MainWindow:UpdateTabLayout();
    end;
end;

function Library:SetUIFont(name)
    if not name or name == '' then
        return
    end;

    local face, enumFont = self:LoadUIFont(name);
    self.FontFace = face;
    self.Font = enumFont or Enum.Font.Code;
    self.CurrentUIFont = name;
    self:ApplyFontToAll();
end;

function Library:GetDarkerColor(Color)
    local H, S, V = Color3.toHSV(Color);
    return Color3.fromHSV(H, S, V / 1.5);
end;

function Library:GetLighterColor(Color)
    local H, S, V = Color3.toHSV(Color);
    return Color3.fromHSV(H, S * 0.8, math.min(V * 1.2, 1));
end;

Library.AccentColorDark = Library:GetDarkerColor(Library.AccentColor);
Library.AccentColorLight = Library:GetLighterColor(Library.AccentColor);

function Library:AddToRegistry(Instance, Properties, IsHud)
    local Idx = #Library.Registry + 1;
    local Data = {
        Instance = Instance;
        Properties = Properties;
        Idx = Idx;
    };

    table.insert(Library.Registry, Data);
    Library.RegistryMap[Instance] = Data;

    if IsHud then
        table.insert(Library.HudRegistry, Data);
    end;
end;

function Library:RemoveFromRegistry(Instance)
    local Data = Library.RegistryMap[Instance];

    if Data then
        for Idx = #Library.Registry, 1, -1 do
            if Library.Registry[Idx] == Data then
                table.remove(Library.Registry, Idx);
            end;
        end;

        for Idx = #Library.HudRegistry, 1, -1 do
            if Library.HudRegistry[Idx] == Data then
                table.remove(Library.HudRegistry, Idx);
            end;
        end;

        Library.RegistryMap[Instance] = nil;
    end;
end;

function Library:IsGuiShown(GuiObject)
    if not GuiObject or not GuiObject:IsA('GuiObject') then
        return true;
    end;

    local current = GuiObject;
    while current and current ~= ScreenGui do
        if current:IsA('GuiObject') and not current.Visible then
            return false;
        end;
        current = current.Parent;
    end;

    return true;
end;

function Library:RefreshThemedControls()
    if Toggles then
        for _, toggle in Toggles do
            if toggle.UpdateColors then
                toggle:UpdateColors();
            elseif toggle.Display then
                toggle:Display();
            end;
        end;
    end;

    if Options then
        for _, option in Options do
            if option.Type == 'Slider' and option.UpdateColors then
                option:UpdateColors();
            elseif option.Type == 'Dropdown' and option.Display then
                option:Display();
            end;
        end;
    end;
end;

function Library:UpdateColorsUsingRegistry()
    Library.ThemeUpdating = true;

    for Idx, Object in next, Library.Registry do
        if Object.Instance and Object.Instance.Parent then
            for Property, ColorIdx in next, Object.Properties do
                if type(ColorIdx) == 'string' then
                    Object.Instance[Property] = Library[ColorIdx];
                elseif type(ColorIdx) == 'function' then
                    Object.Instance[Property] = ColorIdx();
                end;
            end;
        end;
    end;

    if Library.UpdateTitle then
        Library.UpdateTitle();
    end;

    Library:UpdateShadows();
    Library:UpdateScrollBars();

    if Library.LastWatermarkText and Library.WatermarkText then
        Library:SetAccentTitle(Library.WatermarkText, Library.LastWatermarkText, Library.WatermarkAccentPart or '.lol');
    end;

    for _, overlay in next, Library.Overlays do
        if overlay.UpdateTitle then
            overlay.UpdateTitle();
        end;
    end;

    Library:UpdateAllGradientTexts();
    Library:UpdateAllAccentTitles();
    Library:UpdateFooter();
    Library:RefreshThemedControls();
    Library:UpdateOverlayGlows();
    Library.ThemeUpdating = false;
end;

function Library:CreateOverlayGlowLayers(Parent, ZIndex)
    local Layers = {};
    local Thickness = 8;
    local InnerTransparency = 0.42;
    local CornerSpan = Thickness * 2;

    local Holder = Library:Create('Frame', {
        BackgroundTransparency = 1;
        BorderSizePixel = 0;
        ClipsDescendants = false;
        Size = UDim2.fromScale(1, 1);
        Position = UDim2.fromScale(0, 0);
        Visible = Library.OverlayGlowEnabled;
        ZIndex = math.max((ZIndex or 1) - 2, 0);
        Parent = Parent;
    });

    table.insert(Layers, Holder);

    local function OutwardFade(FromEdge)
        local Inner = InnerTransparency;

        if FromEdge then
            return NumberSequence.new({
                NumberSequenceKeypoint.new(0, Inner);
                NumberSequenceKeypoint.new(0.3, 0.58);
                NumberSequenceKeypoint.new(0.65, 0.78);
                NumberSequenceKeypoint.new(1, 1);
            });
        end;

        return NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1);
            NumberSequenceKeypoint.new(0.35, 0.78);
            NumberSequenceKeypoint.new(0.7, 0.58);
            NumberSequenceKeypoint.new(1, Inner);
        });
    end;

    local function AddEdge(Size, Position, GradientRotation, FromEdge)
        local Edge = Library:Create('Frame', {
            BackgroundColor3 = Library.OverlayGlowColor;
            BorderSizePixel = 0;
            Position = Position;
            Size = Size;
            ZIndex = Holder.ZIndex;
            Parent = Holder;
        });

        Library:Create('UIGradient', {
            Rotation = GradientRotation;
            Color = ColorSequence.new(Library.OverlayGlowColor);
            Transparency = OutwardFade(FromEdge);
            Parent = Edge;
        });

        Library:AddToRegistry(Edge, {
            BackgroundColor3 = 'OverlayGlowColor';
        }, true);

        table.insert(Layers, Edge);
    end;

    local function AddQuarterCorner(ClipAnchor, ClipPosition, CircleAnchor, GradientRotation)
        local Clip = Library:Create('Frame', {
            AnchorPoint = ClipAnchor;
            BackgroundTransparency = 1;
            BorderSizePixel = 0;
            ClipsDescendants = true;
            Position = ClipPosition;
            Size = UDim2.fromOffset(Thickness, Thickness);
            ZIndex = Holder.ZIndex;
            Parent = Holder;
        });

        local OffsetX = CircleAnchor.X == 1 and Thickness or -Thickness;
        local OffsetY = CircleAnchor.Y == 1 and Thickness or -Thickness;

        local Circle = Library:Create('Frame', {
            AnchorPoint = CircleAnchor;
            BackgroundColor3 = Library.OverlayGlowColor;
            BorderSizePixel = 0;
            Position = UDim2.new(CircleAnchor.X, OffsetX, CircleAnchor.Y, OffsetY);
            Size = UDim2.fromOffset(CornerSpan, CornerSpan);
            ZIndex = Holder.ZIndex;
            Parent = Clip;
        });

        Library:Create('UICorner', {
            CornerRadius = UDim.new(1, 0);
            Parent = Circle;
        });

        Library:Create('UIGradient', {
            Rotation = GradientRotation;
            Color = ColorSequence.new(Library.OverlayGlowColor);
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, InnerTransparency);
                NumberSequenceKeypoint.new(0.35, 0.55);
                NumberSequenceKeypoint.new(0.65, 0.78);
                NumberSequenceKeypoint.new(1, 1);
            });
            Parent = Circle;
        });

        Library:AddToRegistry(Circle, {
            BackgroundColor3 = 'OverlayGlowColor';
        }, true);

        table.insert(Layers, Clip);
        table.insert(Layers, Circle);
    end;

    AddEdge(UDim2.new(1, 0, 0, Thickness), UDim2.new(0, 0, 0, -Thickness), 270, true);
    AddEdge(UDim2.new(1, 0, 0, Thickness), UDim2.new(0, 0, 1, 0), 270, false);
    AddEdge(UDim2.new(0, Thickness, 1, 0), UDim2.new(0, -Thickness, 0, 0), 0, false);
    AddEdge(UDim2.new(0, Thickness, 1, 0), UDim2.new(1, 0, 0, 0), 0, true);

    AddQuarterCorner(Vector2.new(1, 1), UDim2.new(0, 0, 0, 0), Vector2.new(1, 1), 225);
    AddQuarterCorner(Vector2.new(0, 1), UDim2.new(1, 0, 0, 0), Vector2.new(0, 1), 315);
    AddQuarterCorner(Vector2.new(1, 0), UDim2.new(0, 0, 1, 0), Vector2.new(1, 0), 135);
    AddQuarterCorner(Vector2.new(0, 0), UDim2.new(1, 0, 1, 0), Vector2.new(0, 0), 45);

    return Layers;
end;

function Library:UpdateOverlayGlow(Overlay)
    if not Overlay or not Overlay.GlowLayers then
        return
    end;

    local Visible;
    if Overlay == Library.MainWindow then
        Visible = Library.OverlayGlowEnabled
            and Overlay.Outer
            and Overlay.Outer.Visible;
    else
        Visible = Overlay.Visible ~= false and Library.OverlayGlowEnabled;
    end;

    local GlowColor = Library.OverlayGlowColor;
    local ColorSequenceValue = ColorSequence.new(GlowColor);

    for _, Layer in Overlay.GlowLayers do
        Layer.Visible = Visible;

        if Layer:IsA('Frame') then
            local Gradient = Layer:FindFirstChildOfClass('UIGradient');
            if Gradient then
                Layer.BackgroundColor3 = GlowColor;
                Gradient.Color = ColorSequenceValue;
            end;
        end;
    end;
end;

function Library:UpdateOverlayGlows()
    for _, Overlay in Library.Overlays do
        Library:UpdateOverlayGlow(Overlay);
    end;

    if Library.MainWindow then
        Library:UpdateOverlayGlow(Library.MainWindow);
    end;
end;

function Library:SetOverlayGlowEnabled(Enabled)
    Library.OverlayGlowEnabled = not not Enabled;
    Library:UpdateOverlayGlows();
end;

function Library:SetOverlayGlowColor(Color)
    Library.OverlayGlowColor = Color;
    Library:UpdateOverlayGlows();
end;

function Library:GetGradientSequence()
    local White = Color3.new(1, 1, 1);
    local Accent = Library.AccentColor;

    return ColorSequence.new({
        ColorSequenceKeypoint.new(0, White),
        ColorSequenceKeypoint.new(0.35, White:Lerp(Accent, 0.4)),
        ColorSequenceKeypoint.new(0.65, White:Lerp(Accent, 0.75)),
        ColorSequenceKeypoint.new(1, Accent),
    });
end;

function Library:RegisterGradientLabel(Label)
    for _, existing in next, Library.GradientLabels do
        if existing == Label then
            return
        end;
    end;
    table.insert(Library.GradientLabels, Label);
end;

function Library:SetGradientText(Label, Text)
    if not Label then return end;

    for idx = #Library.AccentTitleLabels, 1, -1 do
        if Library.AccentTitleLabels[idx].Label == Label then
            table.remove(Library.AccentTitleLabels, idx);
        end;
    end;

    Label.RichText = false;
    Label.Text = Text or '';
    Label.TextColor3 = Color3.new(1, 1, 1);

    local gradient = Label:FindFirstChild('SkywareTextGradient');
    if not gradient then
        gradient = Library:Create('UIGradient', {
            Name = 'SkywareTextGradient';
            Parent = Label;
        });
        Library:RegisterGradientLabel(Label);
    end;

    gradient.Color = Library:GetGradientSequence();
    gradient.Rotation = 0;
end;

function Library:UpdateAllGradientTexts()
    local sequence = Library:GetGradientSequence();

    for idx = #Library.GradientLabels, 1, -1 do
        local label = Library.GradientLabels[idx];
        if not label or not label.Parent then
            table.remove(Library.GradientLabels, idx);
        else
            local gradient = label:FindFirstChild('SkywareTextGradient');
            if gradient then
                gradient.Color = sequence;
            end;
        end;
    end;
end;

function Library:FormatAccentTitle(Title, AccentPart)
    Title = Title or '';
    AccentPart = AccentPart or '';

    if AccentPart == '' or not string.find(Title, AccentPart, 1, true) then
        return Title;
    end;

    local startIndex = string.find(Title, AccentPart, 1, true);
    local before = string.sub(Title, 1, startIndex - 1);
    local after = string.sub(Title, startIndex + #AccentPart);
    local accentHex = Library.AccentColor:ToHex();

    return string.format(
        '<font color="#ffffff">%s</font><font color="#%s">%s</font><font color="#ffffff">%s</font>',
        before,
        accentHex,
        AccentPart,
        after
    );
end;

function Library:RegisterAccentTitleLabel(Label, Title, AccentPart)
    for _, entry in next, Library.AccentTitleLabels do
        if entry.Label == Label then
            entry.Title = Title;
            entry.AccentPart = AccentPart;
            return
        end;
    end;

    table.insert(Library.AccentTitleLabels, {
        Label = Label;
        Title = Title;
        AccentPart = AccentPart;
    });
end;

function Library:SetAccentTitle(Label, Title, AccentPart)
    if not Label then
        return
    end;

    Title = Title or '';
    AccentPart = AccentPart or '';

    local gradient = Label:FindFirstChild('SkywareTextGradient');
    if gradient then
        gradient:Destroy();
    end;

    for idx = #Library.GradientLabels, 1, -1 do
        if Library.GradientLabels[idx] == Label then
            table.remove(Library.GradientLabels, idx);
        end;
    end;

    Label.RichText = true;
    Label.TextColor3 = Color3.new(1, 1, 1);
    Label.Text = Library:FormatAccentTitle(Title, AccentPart);
    Library:RegisterAccentTitleLabel(Label, Title, AccentPart);
end;

function Library:UpdateAllAccentTitles()
    for idx = #Library.AccentTitleLabels, 1, -1 do
        local entry = Library.AccentTitleLabels[idx];
        if not entry.Label or not entry.Label.Parent then
            table.remove(Library.AccentTitleLabels, idx);
        else
            entry.Label.RichText = true;
            entry.Label.Text = Library:FormatAccentTitle(entry.Title, entry.AccentPart);
        end;
    end;
end;

function Library:ApplyPopupZIndex(Root, OriginZIndex)
    if not Root then
        return Library:GetPopupZIndex(0);
    end;

    local base = Library:GetPopupZIndex(0);
    OriginZIndex = OriginZIndex or Root.ZIndex or 15;

    local cache = Library.PopupZIndexCache[Root];
    if not cache then
        cache = {
            OriginZ = OriginZIndex;
            OriginalZ = {};
        };
        Library.PopupZIndexCache[Root] = cache;
    else
        cache.OriginZ = OriginZIndex;
    end;

    local delta = base - cache.OriginZ;

    local function Apply(instance)
        if not instance:IsA('GuiObject') then
            return
        end;

        if cache.OriginalZ[instance] == nil then
            cache.OriginalZ[instance] = instance.ZIndex;
        end;

        instance.ZIndex = cache.OriginalZ[instance] + delta;
    end;

    Apply(Root);

    for _, descendant in Root:GetDescendants() do
        Apply(descendant);
    end;

    return base;
end;

function Library:CreateTabBottomGlow(Parent, Options)
    Options = Options or {};

    local GlowHeight = Options.GlowHeight or 18;
    local LineHeight = Options.LineHeight or 2;
    local ZIndex = Options.ZIndex or 1;

    local TabGlow = Library:Create('Frame', {
        AnchorPoint = Vector2.new(0, 1);
        BackgroundColor3 = Library.AccentColor;
        BorderSizePixel = 0;
        Position = UDim2.new(0, 0, 1, 0);
        Size = UDim2.new(1, 0, 0, GlowHeight);
        Visible = false;
        ZIndex = ZIndex;
        Parent = Parent;
    });

    Library:AddToRegistry(TabGlow, {
        BackgroundColor3 = 'AccentColor';
    });

    Library:Create('UIGradient', {
        Rotation = 90;
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.38);
            NumberSequenceKeypoint.new(0.3, 0.62);
            NumberSequenceKeypoint.new(0.65, 0.86);
            NumberSequenceKeypoint.new(1, 1);
        });
        Parent = TabGlow;
    });

    local TabLine = Library:Create('Frame', {
        AnchorPoint = Vector2.new(0, 1);
        BackgroundColor3 = Library.AccentColor;
        BorderSizePixel = 0;
        Position = UDim2.new(0, 0, 1, 0);
        Size = UDim2.new(1, 0, 0, LineHeight);
        Visible = false;
        ZIndex = ZIndex + 2;
        Parent = Parent;
    });

    Library:AddToRegistry(TabLine, {
        BackgroundColor3 = 'AccentColor';
    });

    return TabGlow, TabLine;
end;

function Library:SetTabGlowVisible(TabGlow, TabLine, Visible)
    if TabGlow then
        TabGlow.Visible = Visible;
    end;

    if TabLine then
        TabLine.Visible = Visible;
    end;
end;

function Library:ApplyWindowShadow() end;

function Library:LinkWindowShadow() end;

function Library:LinkWindowShadow() end;

function Library:UpdateMenuBlur()
    local lighting = game:GetService('Lighting');
    local blur = lighting:FindFirstChild('SkywareMenuBlur');
    local enabled = Toggles and Toggles.MenuBlurToggle and Toggles.MenuBlurToggle.Value;
    local shouldBlur = enabled and Library.MenuOpen;

    if shouldBlur then
        if not blur then
            blur = Instance.new('BlurEffect');
            blur.Name = 'SkywareMenuBlur';
            blur.Size = 12;
            blur.Parent = lighting;
        end;
    elseif blur then
        blur:Destroy();
    end;
end;

function Library:UpdateFooter()
    if not Library.FooterLeft or not Library.FooterRight then
        return
    end;

    local username = Library.AnonymousMode and 'anonymous' or LocalPlayer.Name;
    local placeName = Library.PlaceName or 'Baseplate';
    local greyHex = '828282';
    local accentHex = Library.AccentColor:ToHex();

    Library.FooterLeft.RichText = true;
    Library.FooterLeft.TextTransparency = 0;
    Library.FooterLeft.Text = string.format(
        '<font color="#%s">welcome back, </font><font color="#%s">%s</font>',
        greyHex,
        accentHex,
        username
    );

    Library.FooterRight.RichText = true;
    Library.FooterRight.TextTransparency = 0;
    Library.FooterRight.Text = string.format(
        '<font color="#%s">[ </font><font color="#%s">%s</font><font color="#%s"> ]</font>',
        greyHex,
        accentHex,
        placeName,
        greyHex
    );
end;

function Library:GetKeybindRowZBase()
    if Library.KeybindOverlay and Library.KeybindOverlay.Outer then
        return Library.KeybindOverlay.Outer.ZIndex + 12;
    end;

    return 225;
end;

function Library:GetPopupZIndex(Offset)
    Offset = Offset or 0;
    local Z = 250 + Offset;

    if Library.KeybindOverlay and Library.KeybindOverlay.ZIndexBase then
        Z = math.max(Z, Library.KeybindOverlay.ZIndexBase + 50 + Offset);
    end;

    for _, Overlay in Library.Overlays do
        if Overlay and Overlay.ZIndexBase then
            Z = math.max(Z, Overlay.ZIndexBase + 50 + Offset);
        end;
    end;

    return Z;
end;

function Library:SyncKeybindRowsZIndex()
    if not Library.KeybindContainer then
        return
    end;

    local base = Library:GetKeybindRowZBase();

    for _, row in Library.KeybindContainer:GetChildren() do
        if row:IsA('Frame') then
            row.ZIndex = base;

            for _, child in row:GetChildren() do
                if child:IsA('TextLabel') then
                    child.ZIndex = base + 3;
                    child.TextTransparency = 0;
                elseif child:IsA('Frame') then
                    child.ZIndex = base + 3;

                    local valueLabel = child:FindFirstChildWhichIsA('TextLabel');
                    if valueLabel then
                        valueLabel.ZIndex = base + 5;
                        valueLabel.TextTransparency = 0;
                        valueLabel.TextColor3 = Color3.new(1, 1, 1);
                    end;
                end;
            end;
        end;
    end;

    Library.KeybindContainer.ZIndex = base;
end;

function Library:UpdateKeybindOverlaySize()
    if not Library.KeybindContainer or Library._UpdatingKeybindOverlaySize then
        return
    end;

    Library._UpdatingKeybindOverlaySize = true;

    Library:SyncKeybindRowsZIndex();

    local rowHeight = 0;
    local maxWidth = 170;
    local activeCount = 0;

    for _, row in Library.KeybindContainer:GetChildren() do
        if row:IsA('Frame') and row.Visible then
            activeCount += 1;
            rowHeight += 24;
            local nameLabel = row:FindFirstChildWhichIsA('TextLabel');
            local keyBox = row:FindFirstChildWhichIsA('Frame');
            if nameLabel and keyBox then
                local valueLabel = keyBox:FindFirstChildWhichIsA('TextLabel');
                local keyText = valueLabel and valueLabel.Text or '';
                local rowWidth = Library:GetTextBounds(nameLabel.Text, Library.Font, 13)
                    + Library:GetTextBounds(keyText, Library.Font, 12)
                    + 28;
                maxWidth = math.max(maxWidth, rowWidth);
            end;
        end;
    end;

    local compact = activeCount == 0;
    Library.KeybindOverlayCompact = compact;

    if compact then
        rowHeight = 0;
    else
        rowHeight = math.max(rowHeight, 22);
    end;

    local contentHeight = compact and 0 or math.max(rowHeight + 8, 22);

    Library.KeybindContainer.Size = UDim2.new(1, -12, 0, rowHeight);

    if Library.KeybindOverlay and Library.KeybindOverlay.Outer then
        local overlay = Library.KeybindOverlay;
        local overlayWidth = math.max(maxWidth + 24, 196);
        local targetSize;

        if overlay.ContentOuter then
            overlay.ContentOuter.Visible = not compact;
            overlay.ContentOuter.Size = UDim2.new(1, -12, 0, contentHeight);
        end;

        if overlay.ContentInner then
            overlay.ContentInner.Size = UDim2.new(1, -2, 1, -2);
        end;

        if overlay.Container then
            overlay.Container.Visible = false;
        end;

        if compact then
            targetSize = UDim2.fromOffset(overlayWidth, 32);
        else
            targetSize = UDim2.fromOffset(overlayWidth, 26 + contentHeight + 6);
        end;

        if Library.KeybindOverlayTween then
            Library.KeybindOverlayTween:Cancel();
        end;

        Library.KeybindOverlayTween = TweenService:Create(overlay.Outer, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = targetSize,
        });
        Library.KeybindOverlayTween:Play();
    end;

    Library._UpdatingKeybindOverlaySize = false;
end;

function Library:GetUIScaleFactor(Instance)
    local current = Instance;
    while current and current ~= ScreenGui do
        local scale = current:FindFirstChildOfClass('UIScale');
        if scale then
            return scale.Scale;
        end;
        current = current.Parent;
    end;
    return 1;
end;

function Library:UpdateShadows() end;

function Library:UpdateScrollBars()
    for _, desc in ScreenGui:GetDescendants() do
        if desc:IsA('ScrollingFrame') then
            desc.ScrollBarImageColor3 = Library.AccentColor;
        end;
    end;
end;

function Library:SetAllCloseEnabled(Enabled)
    Library.AllCloseOverlays = not not Enabled;
    if Library.AllCloseOverlays then
        Library:SyncOverlaysWithMenu(Library.MenuOpen);
    end;
end;

function Library:SyncOverlaysWithMenu(MenuVisible)
    for _, overlay in Library.Overlays do
        if overlay.SetVisible then
            if MenuVisible then
                if Library.AllCloseOverlays then
                    overlay:SetVisible(true);
                end;
            elseif not Library.KeepOverlaysOnClose then
                overlay:SetVisible(false);
            end;
        elseif overlay.Outer then
            if MenuVisible then
                if Library.AllCloseOverlays then
                    overlay.Outer.Visible = true;
                    overlay.Visible = true;
                end;
            elseif not Library.KeepOverlaysOnClose then
                overlay.Outer.Visible = false;
                overlay.Visible = false;
            end;
        end;
    end;
end;

function Library:BindHoldButton(Button, StepCallback)
    if not Button or not StepCallback then return end;

    local holding = false;

    local function stop()
        holding = false;
        Library:StopSliderSound();
    end;

    Button.MouseButton1Down:Connect(function()
        holding = true;
        StepCallback();
        task.spawn(function()
            task.wait(0.35);
            while holding and Button.Parent do
                StepCallback();
                task.wait(0.06);
            end;
        end);
    end);

    Button.MouseButton1Up:Connect(stop);
    Button.MouseLeave:Connect(stop);
end;

function Library:CreateOverlayWindow(Config)
    Config = Config or {};

    local Title = Config.Title or 'Overlay';
    local Size = typeof(Config.Size) == 'UDim2' and Config.Size or UDim2.fromOffset(260, 300);
    local Position = typeof(Config.Position) == 'UDim2' and Config.Position or UDim2.fromOffset(100, 100);
    local ZIndex = Config.ZIndex or 150;
    local Visible = Config.Visible == true;
    local AccentPart = Config.AccentPart;
    local ZIndexBase = ZIndex + 10;
    local PreviousOverlayBase = Library.OverlayZIndexBase;

    Library.OverlayZIndexBase = ZIndexBase;

    local Overlay = {
        Visible = Visible;
        Tabs = {};
        Groupboxes = {};
        ZIndexBase = ZIndexBase;
    };

    local Outer = Library:Create('Frame', {
        BackgroundTransparency = 1;
        BorderSizePixel = 0;
        ClipsDescendants = false;
        Position = Position;
        Size = Size;
        Visible = Visible;
        ZIndex = ZIndex;
        Parent = ScreenGui;
    });

    local OverlayScaleFactor = 1;
    if IsTouchDevice then
        OverlayScaleFactor = Library.MobileOverlayScale or 0.55;
        Library:Create('UIScale', {
            Scale = OverlayScaleFactor;
            Parent = Outer;
        });

        task.delay(0.1, function()
            if not Outer.Parent then
                return
            end;

            local screen = ScreenGui.AbsoluteSize;
            if screen.X <= 0 or screen.Y <= 0 then
                return
            end;

            local maxX = math.max(screen.X - Outer.AbsoluteSize.X, 0);
            local maxY = math.max(screen.Y - Outer.AbsoluteSize.Y, 0);
            local x = math.clamp(Outer.Position.X.Offset, 0, maxX);
            local y = math.clamp(Outer.Position.Y.Offset, 0, maxY);

            if x ~= Outer.Position.X.Offset or y ~= Outer.Position.Y.Offset then
                Outer.Position = UDim2.fromOffset(x, y);
            end;
        end);
    end;

    Overlay.GlowLayers = nil;

    local Inner = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderSizePixel = 0;
        ClipsDescendants = false;
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = ZIndex + 1;
        Parent = Outer;
    });

    Library:AddToRegistry(Inner, { BackgroundColor3 = 'MainColor' });

    Overlay.GlowLayers = Library:CreateOverlayGlowLayers(Inner, ZIndex);

    local TopAccent = Library:Create('Frame', {
        BackgroundColor3 = Library.AccentColor;
        BorderSizePixel = 0;
        Size = UDim2.new(1, 0, 0, 2);
        ZIndex = ZIndex + 5;
        Parent = Inner;
    });

    Library:AddToRegistry(TopAccent, { BackgroundColor3 = 'AccentColor' });

    local TitleLabel = Library:CreateLabel({
        Position = UDim2.new(0, 8, 0, 4);
        Size = UDim2.new(1, -16, 0, 20);
        TextSize = 14;
        TextXAlignment = Enum.TextXAlignment.Left;
        ZIndex = ZIndex + 2;
        Parent = Inner;
    });

    local function UpdateOverlayTitle()
        if AccentPart and AccentPart ~= '' then
            Library:SetAccentTitle(TitleLabel, Title, AccentPart);
        else
            Library:SetGradientText(TitleLabel, Title);
        end;
    end;

    local ContentOuter = Library:Create('Frame', {
        BackgroundColor3 = Library.BackgroundColor;
        BorderColor3 = Library.OutlineColor;
        BorderMode = Enum.BorderMode.Inset;
        ClipsDescendants = true;
        Position = UDim2.new(0, 6, 0, 26);
        Size = UDim2.new(1, -12, 0, 0);
        ZIndex = ZIndex + 1;
        Parent = Inner;
    });

    Library:AddToRegistry(ContentOuter, {
        BackgroundColor3 = 'BackgroundColor';
        BorderColor3 = 'OutlineColor';
    });

    local ContentInner = Library:Create('Frame', {
        BackgroundColor3 = Library.BackgroundColor;
        BorderSizePixel = 0;
        Position = UDim2.new(0, 1, 0, 1);
        Size = UDim2.new(1, -2, 1, -2);
        ZIndex = ZIndex + 2;
        Parent = ContentOuter;
    });

    Library:AddToRegistry(ContentInner, { BackgroundColor3 = 'BackgroundColor' });

    local Container = Library:Create('ScrollingFrame', {
        BackgroundTransparency = 1;
        BorderSizePixel = 0;
        ClipsDescendants = true;
        Position = UDim2.new(0, 4, 0, 4);
        Size = UDim2.new(1, -8, 1, -8);
        CanvasSize = UDim2.new(0, 0, 0, 0);
        ScrollBarThickness = 3;
        ScrollBarImageColor3 = Library.AccentColor;
        BottomImage = '';
        TopImage = '';
        ZIndex = ZIndex + 3;
        Parent = ContentInner;
    });

    Library:AddToRegistry(Container, {
        ScrollBarImageColor3 = 'AccentColor';
    });

    Library:Create('UIListLayout', {
        Padding = UDim.new(0, 6);
        FillDirection = Enum.FillDirection.Vertical;
        SortOrder = Enum.SortOrder.LayoutOrder;
        Parent = Container;
    });

    Container:WaitForChild('UIListLayout'):GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
        if Overlay.Resize then
            Overlay:Resize();
        end;
    end);

    function Overlay:Resize()
        local listLayout = Container:FindFirstChildOfClass('UIListLayout');
        if not listLayout then
            return
        end;

        local contentH = math.ceil(listLayout.AbsoluteContentSize.Y / OverlayScaleFactor);
        if contentH <= 0 then
            return
        end;

        local chromeTop = 26;
        local chromeBottom = 6;
        local containerPadding = 8;
        local width = Outer.Size.X.Offset;

        Container.Size = UDim2.new(1, -8, 0, contentH);
        Container.CanvasSize = UDim2.fromOffset(0, contentH);
        ContentOuter.Size = UDim2.new(1, -12, 0, contentH + containerPadding);

        local height = chromeTop + contentH + containerPadding + chromeBottom;
        Outer.Size = UDim2.fromOffset(width, math.max(height, 56));
    end;

    Library:MakeDraggable(Outer, 28);

    function Overlay:SetVisible(Bool)
        Overlay.Visible = not not Bool;
        Outer.Visible = Overlay.Visible;
        Library:UpdateOverlayGlow(Overlay);
    end;

    function Overlay:Show()
        Overlay:SetVisible(true);
    end;

    function Overlay:Hide()
        Overlay:SetVisible(false);
    end;

    function Overlay:Toggle()
        Overlay:SetVisible(not Overlay.Visible);
    end;

    function Overlay:SetTitle(NewTitle, NewAccentPart)
        Title = NewTitle or Title;
        AccentPart = NewAccentPart or AccentPart;
        UpdateOverlayTitle();
    end;

    function Overlay:AddGroupbox(Info)
        local Groupbox = {};
        local boxName = Info.Name or 'Section';

        local BoxOuter = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, -4, 0, 0);
            ZIndex = ZIndex + 4;
            Parent = Container;
        });

        Library:AddToRegistry(BoxOuter, {
            BackgroundColor3 = 'BackgroundColor';
            BorderColor3 = 'OutlineColor';
        });

        local BoxInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderSizePixel = 0;
            Size = UDim2.new(1, -2, 1, -2);
            Position = UDim2.new(0, 1, 0, 1);
            ZIndex = ZIndex + 5;
            Parent = BoxOuter;
        });

        Library:AddToRegistry(BoxInner, { BackgroundColor3 = 'BackgroundColor' });

        local Highlight = Library:Create('Frame', {
            BackgroundColor3 = Library.AccentColor;
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 0, 1);
            ZIndex = ZIndex + 6;
            Parent = BoxInner;
        });

        Library:AddToRegistry(Highlight, { BackgroundColor3 = 'AccentColor' });

        Library:CreateLabel({
            Size = UDim2.new(1, 0, 0, 16);
            Position = UDim2.new(0, 4, 0, 2);
            TextSize = 13;
            Text = boxName;
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = ZIndex + 6;
            Parent = BoxInner;
        });

        local GroupContainer = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Position = UDim2.new(0, 6, 0, 18);
            Size = UDim2.new(1, -10, 0, 0);
            ZIndex = ZIndex + 5;
            Parent = BoxInner;
        });

        Library:Create('UIListLayout', {
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = GroupContainer;
        });

        local GroupListLayout = GroupContainer:FindFirstChildOfClass('UIListLayout');
        if GroupListLayout then
            GroupListLayout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
                Groupbox:Resize();
            end);
        end;

        function Groupbox:Resize()
            local listLayout = GroupContainer:FindFirstChildOfClass('UIListLayout');
            local SizeY = listLayout and math.ceil(listLayout.AbsoluteContentSize.Y / OverlayScaleFactor) or 0;
            GroupContainer.Size = UDim2.new(1, -10, 0, SizeY);
            BoxOuter.Size = UDim2.new(1, -4, 0, 18 + SizeY + 4);
            task.defer(function()
                if Overlay.Resize then
                    Overlay:Resize();
                end;
            end);
        end;

        Groupbox.Container = GroupContainer;
        Groupbox.ContentBaseZIndex = ZIndex + 10;
        setmetatable(Groupbox, BaseGroupbox);
        Groupbox:AddBlank(3);
        Groupbox:Resize();

        Overlay.Groupboxes[boxName] = Groupbox;
        return Groupbox;
    end;

    Overlay.Outer = Outer;
    Overlay.Inner = Inner;
    Overlay.Container = Container;
    Overlay.ContentOuter = ContentOuter;
    Overlay.ContentInner = ContentInner;
    Overlay.TitleLabel = TitleLabel;
    Overlay.UpdateTitle = UpdateOverlayTitle;
    UpdateOverlayTitle();

    table.insert(Library.Overlays, Overlay);
    task.defer(function()
        Overlay:Resize();
    end);

    Library.OverlayZIndexBase = PreviousOverlayBase;

    return Overlay;
end;

function Library:CreateOverlayOpener(Items, ParentContainer, Groupbox)
    local Opener = {};
    local ContentZ = (Groupbox and Groupbox.ContentBaseZIndex or 10);

    local List = Library:Create('Frame', {
        BackgroundTransparency = 1;
        AutomaticSize = Enum.AutomaticSize.Y;
        Size = UDim2.new(1, 0, 0, 0);
        ZIndex = ContentZ + 6;
        Parent = ParentContainer;
    });

    local OpenerLayout = Library:Create('UIListLayout', {
        Padding = UDim.new(0, 4);
        FillDirection = Enum.FillDirection.Vertical;
        SortOrder = Enum.SortOrder.LayoutOrder;
        Parent = List;
    });

    for _, item in next, Items do
        local Row = Library:Create('TextButton', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            AutoButtonColor = false;
            Size = UDim2.new(1, -4, 0, 22);
            Text = '';
            ZIndex = ContentZ + 7;
            Parent = List;
        });

        Library:AddToRegistry(Row, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });

        local displayText = item.Text or item.Name or 'Open';

        local RowLabel = Library:CreateLabel({
            Size = UDim2.new(1, -8, 1, 0);
            Position = UDim2.new(0, 6, 0, 0);
            Text = displayText;
            TextSize = 13;
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = ContentZ + 8;
            Parent = Row;
        });

        Library:SetGradientText(RowLabel, displayText);

        Library:OnHighlight(Row, Row,
            { BackgroundColor3 = 'SelectedTabColor', BorderColor3 = 'AccentColor' },
            { BackgroundColor3 = 'MainColor', BorderColor3 = 'OutlineColor' }
        );

        Row.MouseButton1Click:Connect(function()
            if item.Overlay and item.Overlay.Toggle then
                item.Overlay:Toggle();
            elseif type(item.Callback) == 'function' then
                Library:SafeCallback(item.Callback);
            end;
        end);
    end;

    Opener.Frame = List;

    if Groupbox and Groupbox.Resize then
        Groupbox:Resize();
        OpenerLayout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
            Groupbox:Resize();
        end);
        task.defer(function()
            Groupbox:Resize();
        end);
    end;

    return Opener;
end;

function Library:CreatePlayerListOverlay(Config)
    Config = Config or {};
    local Overlay = Library:CreateOverlayWindow({
        Title = 'Player List';
        AccentPart = 'List';
        Size = UDim2.fromOffset(320, 392);
        Position = Config.Position or UDim2.fromOffset(40, 80);
        Visible = Config.Visible;
        ZIndex = Config.ZIndex or 160;
    });

    local Groupbox = Overlay:AddGroupbox({ Name = 'Players' });
    local PZ = Overlay.ZIndexBase + 15;

    Groupbox:AddInput('PlayerListSearch', {
        Text = 'Search';
        NoLabel = true;
        Default = '';
        Placeholder = 'Search...';
        Finished = false;
        ClearOnFocus = false;
    });

    local ListHolder = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.OutlineColor;
        BorderMode = Enum.BorderMode.Inset;
        Size = UDim2.new(1, -4, 0, 220);
        ClipsDescendants = true;
        ZIndex = PZ;
        Parent = Groupbox.Container;
    });

    Library:AddToRegistry(ListHolder, {
        BackgroundColor3 = 'MainColor';
        BorderColor3 = 'OutlineColor';
    });

    local PlayerScroll = Library:Create('ScrollingFrame', {
        BackgroundTransparency = 1;
        BorderSizePixel = 0;
        ClipsDescendants = true;
        Size = UDim2.new(1, 0, 1, 0);
        CanvasSize = UDim2.new(0, 0, 0, 0);
        ScrollBarThickness = 3;
        ScrollBarImageColor3 = Library.AccentColor;
        BottomImage = '';
        TopImage = '';
        ZIndex = PZ + 1;
        Parent = ListHolder;
    });

    Library:AddToRegistry(PlayerScroll, {
        ScrollBarImageColor3 = 'AccentColor';
    });

    Library:Create('UIListLayout', {
        Padding = UDim.new(0, 4);
        SortOrder = Enum.SortOrder.LayoutOrder;
        HorizontalAlignment = Enum.HorizontalAlignment.Center;
        Parent = PlayerScroll;
    });

    local SelectedPanel = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.OutlineColor;
        BorderMode = Enum.BorderMode.Inset;
        Size = UDim2.new(1, -4, 0, 82);
        ClipsDescendants = true;
        ZIndex = PZ;
        Parent = Groupbox.Container;
    });

    Library:AddToRegistry(SelectedPanel, {
        BackgroundColor3 = 'MainColor';
        BorderColor3 = 'OutlineColor';
    });

    local Avatar = Library:Create('ImageLabel', {
        BackgroundColor3 = Library.BackgroundColor;
        BorderColor3 = Library.OutlineColor;
        Position = UDim2.new(0, 8, 0, 6);
        Size = UDim2.fromOffset(64, 64);
        ZIndex = PZ + 1;
        Parent = SelectedPanel;
    });

    Library:AddToRegistry(Avatar, {
        BackgroundColor3 = 'BackgroundColor';
        BorderColor3 = 'OutlineColor';
    });

    local TeleportBtn = Library:Create('TextButton', {
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.OutlineColor;
        BorderMode = Enum.BorderMode.Inset;
        Position = UDim2.new(0, 80, 0, 6);
        Size = UDim2.fromOffset(88, 28);
        Text = 'Teleport';
        TextColor3 = Library.FontColor;
        TextSize = 13;
        AutoButtonColor = false;
        ZIndex = PZ + 1;
        Parent = SelectedPanel;
    });

    Library:AddToRegistry(TeleportBtn, {
        BackgroundColor3 = 'MainColor';
        BorderColor3 = 'OutlineColor';
        TextColor3 = 'FontColor';
    });

    local SpectateBtn = Library:Create('TextButton', {
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.OutlineColor;
        BorderMode = Enum.BorderMode.Inset;
        Position = UDim2.new(0, 80, 0, 38);
        Size = UDim2.fromOffset(88, 28);
        Text = 'Spectate';
        TextColor3 = Library.FontColor;
        TextSize = 13;
        AutoButtonColor = false;
        ZIndex = PZ + 1;
        Parent = SelectedPanel;
    });

    Library:AddToRegistry(SpectateBtn, {
        BackgroundColor3 = 'MainColor';
        BorderColor3 = 'OutlineColor';
        TextColor3 = 'FontColor';
    });

    local SelectedName = Library:CreateLabel({
        Position = UDim2.new(0, 176, 0, 6);
        Size = UDim2.new(1, -182, 0, 16);
        Text = 'No player selected';
        TextSize = 13;
        TextTruncate = Enum.TextTruncate.AtEnd;
        TextXAlignment = Enum.TextXAlignment.Left;
        ZIndex = PZ + 2;
        Parent = SelectedPanel;
    });

    Groupbox:AddDropdown('PlayerListStatus', {
        Values = { 'Enemy', 'Friendly', 'Neutral' };
        Default = 1;
    });

    if Options.PlayerListStatus and Options.PlayerListStatus.Outer then
        local StatusOuter = Options.PlayerListStatus.Outer;
        StatusOuter.Parent = SelectedPanel;
        StatusOuter.Position = UDim2.new(0, 176, 0, 28);
        StatusOuter.Size = UDim2.new(1, -182, 0, 20);
        StatusOuter.ZIndex = PZ + 2;
    end;

    Groupbox:Resize();

    local selectedPlayer;
    local playerButtons = {};
    local enemyPlayers = {};
    local clientGrey = Color3.fromRGB(140, 140, 140);
    local enemyRed = Color3.fromRGB(255, 80, 80);
    local statusUpdating = false;

    local function SelectPlayer(player)
        selectedPlayer = player;
        if player then
            SelectedName.Text = player.Name;
            if enemyPlayers[player] then
                SelectedName.TextColor3 = enemyRed;
            elseif player == LocalPlayer then
                SelectedName.TextColor3 = clientGrey;
            else
                SelectedName.TextColor3 = Library.FontColor;
            end;

            if Options.PlayerListStatus then
                local status = enemyPlayers[player] and 'Enemy' or 'Friendly';
                if Options.PlayerListStatus.Value ~= status then
                    statusUpdating = true;
                    Options.PlayerListStatus:SetValue(status);
                    statusUpdating = false;
                end;
            end;

            local ok, thumb = pcall(function()
                return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48);
            end);
            Avatar.Image = ok and thumb or '';
        else
            SelectedName.Text = 'No player selected';
            SelectedName.TextColor3 = Library.FontColor;
            Avatar.Image = '';
        end;
    end;

    local refreshPending = false;

    local function RefreshPlayers()
        if refreshPending then
            return
        end;

        refreshPending = true;
        task.defer(function()
            refreshPending = false;
            if not PlayerScroll.Parent then
                return
            end;

            for _, btn in playerButtons do
                btn:Destroy();
            end;
            table.clear(playerButtons);

            local filter = string.lower(Options.PlayerListSearch and Options.PlayerListSearch.Value or '');
            local layoutOrder = 0;

            for _, player in Players:GetPlayers() do
                local isLocal = player == LocalPlayer;
                local displayName = isLocal and (player.Name .. ' (Client)') or player.Name;
                if filter == '' or string.find(string.lower(displayName), filter, 1, true) then
                    layoutOrder += 1;
                    local isEnemy = enemyPlayers[player];
                    local Btn = Library:Create('TextButton', {
                        BackgroundTransparency = 1;
                        Size = UDim2.new(1, -8, 0, 22);
                        Text = displayName;
                        TextColor3 = isEnemy and enemyRed or (isLocal and clientGrey or (player == selectedPlayer and Library.AccentColor or Library.FontColor));
                        TextSize = 13;
                        Font = Library.Font;
                        TextXAlignment = Enum.TextXAlignment.Center;
                        LayoutOrder = layoutOrder;
                        AutoButtonColor = false;
                        ZIndex = PZ + 3;
                        Parent = PlayerScroll;
                    });

                    Btn.MouseButton1Click:Connect(function()
                        SelectPlayer(player);
                        RefreshPlayers();
                    end);

                    playerButtons[#playerButtons + 1] = Btn;
                end;
            end;

            PlayerScroll.CanvasSize = UDim2.fromOffset(0, math.max(layoutOrder * 26, 26));
            Groupbox:Resize();
        end);
    end;

    if Options.PlayerListSearch then
        Options.PlayerListSearch:OnChanged(RefreshPlayers);
    end;

    if Options.PlayerListStatus then
        Options.PlayerListStatus:OnChanged(function()
            if statusUpdating then
                return
            end;

            if selectedPlayer then
                enemyPlayers[selectedPlayer] = Options.PlayerListStatus.Value == 'Enemy';
                if enemyPlayers[selectedPlayer] then
                    SelectedName.TextColor3 = enemyRed;
                elseif selectedPlayer == LocalPlayer then
                    SelectedName.TextColor3 = clientGrey;
                else
                    SelectedName.TextColor3 = Library.FontColor;
                end;
                RefreshPlayers();
            end;
        end);
    end;

    Players.PlayerAdded:Connect(RefreshPlayers);
    Players.PlayerRemoving:Connect(function(player)
        enemyPlayers[player] = nil;
        if selectedPlayer == player then
            SelectPlayer(nil);
        end;
        RefreshPlayers();
    end);

    TeleportBtn.MouseButton1Click:Connect(function()
        if selectedPlayer and selectedPlayer.Character and selectedPlayer.Character:FindFirstChild('HumanoidRootPart') then
            local char = LocalPlayer.Character;
            if char and char:FindFirstChild('HumanoidRootPart') then
                char.HumanoidRootPart.CFrame = selectedPlayer.Character.HumanoidRootPart.CFrame;
            end;
        end;
    end);

    local spectating;
    local savedMinZoom, savedMaxZoom, savedCameraMode;

    local function StopSpectating()
        if not spectating then
            return
        end;

        spectating = nil;
        SpectateBtn.Text = 'Spectate';

        if savedMinZoom ~= nil then
            LocalPlayer.CameraMinZoomDistance = savedMinZoom;
            LocalPlayer.CameraMaxZoomDistance = savedMaxZoom;
            LocalPlayer.CameraMode = savedCameraMode;
            savedMinZoom, savedMaxZoom, savedCameraMode = nil, nil, nil;
        end;

        local camera = workspace.CurrentCamera;
        if camera then
            local char = LocalPlayer.Character;
            local hum = char and char:FindFirstChildOfClass('Humanoid');
            if hum then
                camera.CameraSubject = hum;
            end;
            camera.CameraType = Enum.CameraType.Custom;
        end;
    end;

    Library:GiveSignal(RunService.RenderStepped:Connect(LPH_NO_VIRTUALIZE(function()
        if not spectating then
            return
        end;

        if not spectating.Parent then
            StopSpectating();
            return
        end;

        local targetCharacter = spectating.Character;
        local targetHumanoid = targetCharacter and targetCharacter:FindFirstChildOfClass('Humanoid');
        local camera = workspace.CurrentCamera;
        if not targetHumanoid or not camera then
            return
        end;

        if camera.CameraSubject ~= targetHumanoid then
            camera.CameraSubject = targetHumanoid;
        end;
        if camera.CameraType ~= Enum.CameraType.Custom then
            camera.CameraType = Enum.CameraType.Custom;
        end;
    end)));

    SpectateBtn.MouseButton1Click:Connect(function()
        if spectating then
            StopSpectating();
            return
        end;

        if not selectedPlayer or selectedPlayer == LocalPlayer then
            return
        end;

        local targetCharacter = selectedPlayer.Character;
        local targetHumanoid = targetCharacter and targetCharacter:FindFirstChildOfClass('Humanoid');
        if not targetHumanoid then
            return
        end;

        savedMinZoom = LocalPlayer.CameraMinZoomDistance;
        savedMaxZoom = LocalPlayer.CameraMaxZoomDistance;
        savedCameraMode = LocalPlayer.CameraMode;

        LocalPlayer.CameraMode = Enum.CameraMode.Classic;
        LocalPlayer.CameraMinZoomDistance = 0.5;
        LocalPlayer.CameraMaxZoomDistance = 128;

        spectating = selectedPlayer;
        SpectateBtn.Text = 'Unspectate';

        local camera = workspace.CurrentCamera;
        if camera then
            camera.CameraSubject = targetHumanoid;
            camera.CameraType = Enum.CameraType.Custom;
        end;
    end);

    RefreshPlayers();
    task.defer(function()
        Groupbox:Resize();
        Overlay:Resize();
    end);
    Overlay.RefreshPlayers = RefreshPlayers;
    Overlay.SelectPlayer = SelectPlayer;
    Library.EnemyPlayers = enemyPlayers;
    Overlay.EnemyPlayers = enemyPlayers;
    return Overlay;
end;

function Library:CreateESPPreviewOverlay(Config)
    Config = Config or {};
    local Overlay = Library:CreateOverlayWindow({
        Title = 'ESP Preview';
        Size = UDim2.fromOffset(200, 254);
        Position = Config.Position or UDim2.fromOffset(940, 80);
        Visible = Config.Visible;
        ZIndex = Config.ZIndex or 160;
    });

    local Groupbox = Overlay:AddGroupbox({ Name = 'Preview' });

    local PreviewHolder = Library:Create('Frame', {
        BackgroundColor3 = Library.BackgroundColor;
        BorderColor3 = Library.OutlineColor;
        BorderMode = Enum.BorderMode.Inset;
        Size = UDim2.new(1, -4, 0, 210);
        ClipsDescendants = true;
        ZIndex = 8;
        Parent = Groupbox.Container;
    });

    Library:AddToRegistry(PreviewHolder, {
        BackgroundColor3 = 'BackgroundColor';
        BorderColor3 = 'OutlineColor';
    });

    local Viewport = Library:Create('ViewportFrame', {
        BackgroundColor3 = Color3.fromRGB(25, 25, 25);
        BorderColor3 = Color3.fromRGB(70, 70, 70);
        BorderSizePixel = 1;
        Size = UDim2.new(1, -2, 1, -2);
        Position = UDim2.new(0, 1, 0, 1);
        Ambient = Color3.fromRGB(200, 200, 200);
        LightColor = Color3.fromRGB(255, 255, 255);
        LightDirection = Vector3.new(-1, -1, -1);
        ZIndex = 9;
        Parent = PreviewHolder;
    });

    local worldModel = Instance.new('WorldModel');
    worldModel.Parent = Viewport;

    local camera = Instance.new('Camera');
    camera.Parent = Viewport;
    Viewport.CurrentCamera = camera;

    local clone;
    local previewOk = pcall(function()
        clone = Players:CreateHumanoidModelFromDescriptionAsync(
            Players:GetHumanoidDescriptionFromUserIdAsync(1),
            Enum.HumanoidRigType.R15
        );
    end);

    if not previewOk or not clone then
        pcall(function()
            clone = Players:CreateHumanoidModelFromDescription(
                Players:GetHumanoidDescriptionFromUserId(1),
                Enum.HumanoidRigType.R15
            );
        end);
    end;

    if clone then
        for _, obj in clone:GetDescendants() do
            if obj:IsA('LocalScript') or obj:IsA('Script') then
                obj:Destroy();
            end;
        end;
        clone.Parent = worldModel;

        local root = clone:WaitForChild('HumanoidRootPart');
        local target = root.Position + Vector3.new(0, -0.34, 0);
        local radius = 5.4;
        local height = 1;
        local angle = 0;
        local speed = math.rad(30);

        local previewAccum = 0;
        local previewStep = IsTouchDevice and 0.12 or 0.05;
        Library:GiveSignal(RunService.RenderStepped:Connect(LPH_NO_VIRTUALIZE(function(dt)
            if not Overlay.Visible or not Overlay.Outer or not Overlay.Outer.Visible then
                return
            end;

            previewAccum += dt;
            if previewAccum < previewStep then
                return
            end;

            angle += speed * previewAccum;
            previewAccum = 0;
            local offset = Vector3.new(
                math.sin(angle) * radius,
                height,
                math.cos(angle) * radius
            );
            camera.CFrame = CFrame.lookAt(target + offset, target);
        end)));
    end;

    local Box = Library:Create('Frame', {
        BackgroundTransparency = 1;
        BorderColor3 = Library.AccentColor;
        BorderSizePixel = 1;
        Position = UDim2.new(0.3, 0, 0.1, 0);
        Size = UDim2.new(0.4, 0, 0.78, 0);
        ZIndex = 12;
        Parent = PreviewHolder;
    });

    Library:AddToRegistry(Box, { BorderColor3 = 'AccentColor' });

    local HealthBarBg = Library:Create('Frame', {
        BackgroundColor3 = Color3.fromRGB(40, 40, 40);
        BorderSizePixel = 0;
        Position = UDim2.new(0.22, 0, 0.1, 0);
        Size = UDim2.new(0, 3, 0.78, 0);
        ZIndex = 12;
        Parent = PreviewHolder;
    });

    Library:Create('Frame', {
        BackgroundColor3 = Color3.fromRGB(80, 220, 80);
        BorderSizePixel = 0;
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 13;
        Parent = HealthBarBg;
    });

    Library:CreateLabel({
        Position = UDim2.new(0.16, 0, 0.42, 0);
        Size = UDim2.new(0, 20, 0, 14);
        Text = '100';
        TextSize = 11;
        TextXAlignment = Enum.TextXAlignment.Center;
        ZIndex = 13;
        Parent = PreviewHolder;
    });

    Library:CreateLabel({
        Position = UDim2.new(0.5, 0, 0.02, 0);
        Size = UDim2.new(0.5, 0, 0, 14);
        Text = 'dummy';
        TextColor3 = Color3.fromRGB(180, 120, 255);
        TextSize = 12;
        TextXAlignment = Enum.TextXAlignment.Center;
        ZIndex = 13;
        Parent = PreviewHolder;
    });

    Library:CreateLabel({
        Position = UDim2.new(0.72, 0, 0.4, 0);
        Size = UDim2.new(0.26, 0, 0, 14);
        Text = 'standing';
        TextColor3 = Color3.fromRGB(80, 220, 255);
        TextSize = 12;
        TextXAlignment = Enum.TextXAlignment.Left;
        ZIndex = 13;
        Parent = PreviewHolder;
    });

    Library:CreateLabel({
        Position = UDim2.new(0.3, 0, 0.9, 0);
        Size = UDim2.new(0.2, 0, 0, 14);
        Text = '12st';
        TextColor3 = Color3.fromRGB(255, 80, 80);
        TextSize = 12;
        TextXAlignment = Enum.TextXAlignment.Left;
        ZIndex = 13;
        Parent = PreviewHolder;
    });

    Library:CreateLabel({
        Position = UDim2.new(0.52, 0, 0.9, 0);
        Size = UDim2.new(0.3, 0, 0, 14);
        Text = 'preview';
        TextColor3 = Color3.fromRGB(80, 220, 120);
        TextSize = 12;
        TextXAlignment = Enum.TextXAlignment.Left;
        ZIndex = 13;
        Parent = PreviewHolder;
    });

    Overlay.Viewport = Viewport;
    Overlay.Box = Box;
    Groupbox:Resize();
    return Overlay;
end;

function Library:CreateClosestPlayerOverlay(Config)
    Config = Config or {};
    local Overlay = Library:CreateOverlayWindow({
        Title = 'Closest Player';
        AccentPart = 'Player';
        Size = UDim2.fromOffset(196, 56);
        Position = Config.Position or UDim2.fromOffset(40, 580);
        Visible = Config.Visible;
        ZIndex = Config.ZIndex or 165;
    });

    local Z = Overlay.ZIndexBase + 5;
    local AvatarSize = 48;
    local ColumnGap = 6;
    local NameHeight = 14;
    local DistanceHeight = 13;
    local HealthTextHeight = 12;
    local HealthBarHeight = 8;
    local RowGap = 2;
    local HealthBlockHeight = HealthTextHeight + RowGap + HealthBarHeight;
    local InfoHeight = NameHeight + RowGap + DistanceHeight + RowGap + HealthBlockHeight;
    local PanelHeight = math.max(AvatarSize, InfoHeight);

    local Panel = Library:Create('Frame', {
        BackgroundTransparency = 1;
        Size = UDim2.new(1, -4, 0, PanelHeight);
        ZIndex = Z;
        Parent = Overlay.Container;
    });

    local Avatar = Library:Create('ImageLabel', {
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.OutlineColor;
        BorderMode = Enum.BorderMode.Inset;
        Position = UDim2.new(0, 0, 0, math.floor((PanelHeight - AvatarSize) / 2));
        Size = UDim2.fromOffset(AvatarSize, AvatarSize);
        ZIndex = Z + 1;
        Parent = Panel;
    });

    Library:AddToRegistry(Avatar, {
        BackgroundColor3 = 'MainColor';
        BorderColor3 = 'OutlineColor';
    });

    local InfoColumn = Library:Create('Frame', {
        BackgroundTransparency = 1;
        Position = UDim2.new(0, AvatarSize + ColumnGap, 0, 0);
        Size = UDim2.new(1, -(AvatarSize + ColumnGap), 0, InfoHeight);
        ZIndex = Z + 1;
        Parent = Panel;
    });

    Library:Create('UIListLayout', {
        Padding = UDim.new(0, RowGap);
        FillDirection = Enum.FillDirection.Vertical;
        SortOrder = Enum.SortOrder.LayoutOrder;
        Parent = InfoColumn;
    });

    local NameLabel = Library:CreateLabel({
        Size = UDim2.new(1, 0, 0, NameHeight);
        LayoutOrder = 1;
        Text = 'None';
        TextSize = 13;
        TextTruncate = Enum.TextTruncate.AtEnd;
        TextXAlignment = Enum.TextXAlignment.Left;
        TextYAlignment = Enum.TextYAlignment.Center;
        ZIndex = Z + 2;
        Parent = InfoColumn;
    });

    local DistanceLabel = Library:CreateLabel({
        Size = UDim2.new(1, 0, 0, DistanceHeight);
        LayoutOrder = 2;
        Text = '—st';
        TextSize = 12;
        TextTransparency = 0.15;
        TextXAlignment = Enum.TextXAlignment.Left;
        TextYAlignment = Enum.TextYAlignment.Center;
        ZIndex = Z + 2;
        Parent = InfoColumn;
    });

    Library:AddToRegistry(DistanceLabel, {
        TextColor3 = 'AccentColor';
    }, true);

    local HealthBlock = Library:Create('Frame', {
        BackgroundTransparency = 1;
        Size = UDim2.new(1, 0, 0, HealthBlockHeight);
        LayoutOrder = 3;
        ZIndex = Z + 2;
        Parent = InfoColumn;
    });

    local HealthLabel = Library:CreateLabel({
        Size = UDim2.new(1, 0, 0, HealthTextHeight);
        Text = '0';
        TextSize = 12;
        TextXAlignment = Enum.TextXAlignment.Right;
        TextYAlignment = Enum.TextYAlignment.Center;
        ZIndex = Z + 3;
        Parent = HealthBlock;
    });

    local HealthBarOuter = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.OutlineColor;
        BorderMode = Enum.BorderMode.Inset;
        Position = UDim2.new(0, 0, 1, -HealthBarHeight);
        Size = UDim2.new(1, 0, 0, HealthBarHeight);
        ClipsDescendants = true;
        ZIndex = Z + 3;
        Parent = HealthBlock;
    });

    Library:AddToRegistry(HealthBarOuter, {
        BackgroundColor3 = 'MainColor';
        BorderColor3 = 'OutlineColor';
    });

    local HealthBarFill = Library:Create('Frame', {
        BackgroundColor3 = Library.AccentColor;
        BorderSizePixel = 0;
        Size = UDim2.new(0, 0, 1, 0);
        ZIndex = Z + 4;
        Parent = HealthBarOuter;
    });

    Library:AddToRegistry(HealthBarFill, {
        BackgroundColor3 = 'AccentColor';
    });

    local trackedThumbId;
    local healthTween;
    local refreshAccum = 0;

    local function FitOverlay()
        local nameWidth = select(1, Library:GetTextBounds(NameLabel.Text, Library.Font, 13));
        local width = math.ceil(nameWidth + AvatarSize + ColumnGap + 24);
        width = math.clamp(width, 180, 280);

        Panel.Size = UDim2.new(1, -4, 0, PanelHeight);
        Overlay.Container.Size = UDim2.new(1, -8, 0, PanelHeight);
        Overlay.Container.CanvasSize = UDim2.fromOffset(0, PanelHeight);

        if Overlay.ContentOuter then
            Overlay.ContentOuter.Size = UDim2.new(1, -12, 0, PanelHeight + 8);
        end;

        Overlay.Outer.Size = UDim2.fromOffset(width, 26 + PanelHeight + 8 + 6);
    end;

    function Overlay:Resize()
        FitOverlay();
    end;

    local function SetHealth(ratio, healthValue)
        ratio = math.clamp(ratio, 0, 1);
        HealthLabel.Text = tostring(math.floor(healthValue + 0.5));

        if healthTween then
            healthTween:Cancel();
        end;

        healthTween = TweenService:Create(HealthBarFill, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(ratio, 0, 1, 0);
        });
        healthTween:Play();
    end;

    local function ClearTarget()
        trackedThumbId = nil;
        Avatar.Image = '';
        NameLabel.Text = 'None';
        DistanceLabel.Text = '—st';
        SetHealth(0, 0);
        FitOverlay();
    end;

    local function UpdateAvatar(player)
        if not player or trackedThumbId == player.UserId then
            return
        end;

        trackedThumbId = player.UserId;
        local userId = player.UserId;

        task.spawn(function()
            local ok, thumb = pcall(function()
                return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48);
            end);

            if trackedThumbId == userId then
                Avatar.Image = ok and thumb or '';
            end;
        end);
    end;

    local function GetClosestPlayer()
        local localChar = LocalPlayer.Character;
        local localRoot = localChar and localChar:FindFirstChild('HumanoidRootPart');
        if not localRoot then
            return nil;
        end;

        local closestPlayer;
        local closestDistance = math.huge;

        for _, player in Players:GetPlayers() do
            if player ~= LocalPlayer then
                local character = player.Character;
                local root = character and character:FindFirstChild('HumanoidRootPart');
                if root then
                    local distance = (root.Position - localRoot.Position).Magnitude;
                    if distance < closestDistance then
                        closestDistance = distance;
                        closestPlayer = player;
                    end;
                end;
            end;
        end;

        return closestPlayer, closestDistance;
    end;

    function Overlay:Refresh()
        if not Overlay.Visible or not Overlay.Outer or not Overlay.Outer.Visible then
            return
        end;

        local player, distance = GetClosestPlayer();
        if not player then
            ClearTarget();
            return
        end;

        NameLabel.Text = player.DisplayName;
        DistanceLabel.Text = string.format('%dst', math.floor(distance + 0.5));
        UpdateAvatar(player);

        local humanoid = player.Character and player.Character:FindFirstChildOfClass('Humanoid');
        if humanoid and humanoid.MaxHealth > 0 then
            SetHealth(humanoid.Health / humanoid.MaxHealth, humanoid.Health);
        else
            SetHealth(0, 0);
        end;

        FitOverlay();
    end;

    Library:GiveSignal(RunService.Heartbeat:Connect(LPH_NO_VIRTUALIZE(function(Delta)
        if not Overlay.Visible or not Overlay.Outer or not Overlay.Outer.Visible then
            return
        end;

        refreshAccum += Delta;
        if refreshAccum < 0.1 then
            return
        end;

        refreshAccum = 0;
        Overlay:Refresh();
    end)));

    Library.ClosestPlayerOverlay = Overlay;

    task.defer(function()
        Overlay:Refresh();
        FitOverlay();
    end);

    return Overlay;
end;

function Library:CreateKeybindsOverlay(Config)
    Config = Config or {};
    local Overlay = Library:CreateOverlayWindow({
        Title = 'Keybinds';
        Size = UDim2.fromOffset(196, 86);
        Position = Config.Position or UDim2.fromOffset(40, 490);
        Visible = Config.Visible;
        ZIndex = Config.ZIndex or 170;
    });

    if Library.KeybindContainer then
        if Overlay.Container then
            Overlay.Container.Visible = false;
        end;

        Library.KeybindContainer.Parent = Overlay.ContentInner or Overlay.Inner;
        Library.KeybindContainer.Visible = true;
        Library.KeybindContainer.Position = UDim2.new(0, 6, 0, 4);
        Library.KeybindContainer.Size = UDim2.new(1, -12, 0, 0);
        Library.KeybindContainer.ZIndex = Overlay.Outer.ZIndex + 12;
        Library:SyncKeybindRowsZIndex();

        for _, option in Options do
            if type(option) == 'table' and option.Type == 'KeyPicker' and option.Update then
                option:Update();
            end;
        end;
    end;

    function Overlay:SetVisible(Bool)
        Overlay.Visible = not not Bool;
        Overlay.Outer.Visible = Overlay.Visible;
        Library:UpdateOverlayGlow(Overlay);
    end;

    Library.KeybindOverlay = Overlay;
    Library.KeybindTitleLabel = Overlay.TitleLabel;

    function Overlay:Resize()
        if Library.KeybindOverlayCompact or Library._UpdatingKeybindOverlaySize then
            return
        end;

        Library:UpdateKeybindOverlaySize();
    end;

    task.defer(function()
        Library:UpdateKeybindOverlaySize();
    end);
    return Overlay;
end;

function Library:CreateRadarOverlay(Config)
    Config = Config or {};

    local MapSize = Config.MapSize or 176;
    local Range = Config.Range or 120;
    local SampleGrid = Config.SampleGrid or (IsTouchDevice and 28 or 44);
    local FramePad = Config.FramePad or 12;
    local BlipPixel = Config.BlipPixel or 3;
    local ContentSize = MapSize + FramePad * 2;
    local OuterWidth = ContentSize + 12;
    local OuterHeight = 26 + ContentSize + 8;

    local Overlay = Library:CreateOverlayWindow({
        Title = 'Radar';
        AccentPart = 'ar';
        Size = UDim2.fromOffset(OuterWidth, OuterHeight);
        Position = Config.Position or UDim2.fromOffset(40, 40);
        Visible = Config.Visible;
        ZIndex = Config.ZIndex or 160;
    });

    local ListLayout = Overlay.Container:FindFirstChildOfClass('UIListLayout');
    if ListLayout then
        ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center;
        ListLayout.Padding = UDim.new(0, 0);
    end;

    Overlay.Container.ScrollBarThickness = 0;
    Overlay.Container.ScrollingEnabled = false;
    Overlay.Container.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Right;

    local Z = Overlay.ZIndexBase + 15;

    local Panel = Library:Create('Frame', {
        BackgroundTransparency = 1;
        Size = UDim2.fromOffset(ContentSize, ContentSize);
        ZIndex = Z;
        Parent = Overlay.Container;
    });

    local MapOuter = Library:Create('Frame', {
        AnchorPoint = Vector2.new(0.5, 0.5);
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.OutlineColor;
        BorderMode = Enum.BorderMode.Inset;
        Position = UDim2.fromScale(0.5, 0.5);
        Size = UDim2.fromOffset(MapSize, MapSize);
        ClipsDescendants = true;
        ZIndex = Z + 1;
        Parent = Panel;
    });

    Library:AddToRegistry(MapOuter, {
        BackgroundColor3 = 'MainColor';
        BorderColor3 = 'OutlineColor';
    });

    local MapCanvas = Library:Create('Frame', {
        AnchorPoint = Vector2.new(0.5, 0.5);
        BackgroundColor3 = Color3.fromRGB(10, 10, 12);
        BorderSizePixel = 0;
        ClipsDescendants = true;
        Position = UDim2.fromScale(0.5, 0.5);
        Size = UDim2.new(1, -4, 1, -4);
        ZIndex = Z + 2;
        Parent = MapOuter;
    });

    local MapImage = Library:Create('ImageLabel', {
        BackgroundColor3 = Color3.fromRGB(10, 10, 12);
        BorderSizePixel = 0;
        Size = UDim2.fromScale(1, 1);
        ZIndex = Z + 2;
        Parent = MapCanvas;
    });

    local PixelGrid = Library:Create('Frame', {
        BackgroundTransparency = 1;
        Size = UDim2.fromScale(1, 1);
        ZIndex = Z + 2;
        Visible = false;
        Parent = MapCanvas;
    });

    local PixelFrames = table.create(SampleGrid * SampleGrid);

    local function LayoutPixelGrid()
        local CanvasX = math.max(MapCanvas.AbsoluteSize.X, MapSize - 4);
        local CanvasY = math.max(MapCanvas.AbsoluteSize.Y, MapSize - 4);
        local PixelW = CanvasX / SampleGrid;
        local PixelH = CanvasY / SampleGrid;

        for row = 0, SampleGrid - 1 do
            for col = 0, SampleGrid - 1 do
                local Index = row * SampleGrid + col + 1;
                local Pixel = PixelFrames[Index];
                if Pixel then
                    Pixel.Position = UDim2.fromOffset(col * PixelW, row * PixelH);
                    Pixel.Size = UDim2.fromOffset(PixelW, PixelH);
                end;
            end;
        end;
    end;

    for row = 0, SampleGrid - 1 do
        for col = 0, SampleGrid - 1 do
            local Pixel = Library:Create('Frame', {
                BackgroundColor3 = Color3.fromRGB(10, 10, 12);
                BorderSizePixel = 0;
                ZIndex = Z + 2;
                Parent = PixelGrid;
            });
            table.insert(PixelFrames, Pixel);
        end;
    end;

    local CrosshairH = Library:Create('Frame', {
        AnchorPoint = Vector2.new(0.5, 0.5);
        BackgroundColor3 = Library.OutlineColor;
        BackgroundTransparency = 0.65;
        BorderSizePixel = 0;
        Position = UDim2.fromScale(0.5, 0.5);
        Size = UDim2.new(1, 0, 0, 1);
        ZIndex = Z + 3;
        Parent = MapCanvas;
    });

    local CrosshairV = Library:Create('Frame', {
        AnchorPoint = Vector2.new(0.5, 0.5);
        BackgroundColor3 = Library.OutlineColor;
        BackgroundTransparency = 0.65;
        BorderSizePixel = 0;
        Position = UDim2.fromScale(0.5, 0.5);
        Size = UDim2.new(0, 1, 1, 0);
        ZIndex = Z + 3;
        Parent = MapCanvas;
    });

    Library:AddToRegistry(CrosshairH, { BackgroundColor3 = 'OutlineColor' });
    Library:AddToRegistry(CrosshairV, { BackgroundColor3 = 'OutlineColor' });

    local BlipContainer = Library:Create('Frame', {
        BackgroundTransparency = 1;
        Size = UDim2.fromScale(1, 1);
        ZIndex = Z + 5;
        Parent = MapCanvas;
    });

    local MaxBlips = Config.MaxBlips or 32;
    local BlipPool = table.create(MaxBlips);
    local EnemyColor = Color3.fromRGB(255, 48, 48);

    for Index = 1, MaxBlips do
        BlipPool[Index] = Library:Create('Frame', {
            AnchorPoint = Vector2.new(0.5, 0.5);
            BackgroundColor3 = EnemyColor;
            BorderSizePixel = 0;
            Position = UDim2.fromScale(0.5, 0.5);
            Size = UDim2.fromOffset(BlipPixel, BlipPixel);
            Visible = false;
            ZIndex = Z + 6;
            Parent = BlipContainer;
        });
        Library:Create('UICorner', {
            CornerRadius = UDim.new(1, 0);
            Parent = BlipPool[Index];
        });
    end;

    local ArrowHolder = Library:Create('Frame', {
        AnchorPoint = Vector2.new(0.5, 0.5);
        BackgroundTransparency = 1;
        Position = UDim2.fromScale(0.5, 0.5);
        Size = UDim2.fromOffset(16, 16);
        ZIndex = Z + 7;
        Parent = MapCanvas;
    });

    local Arrow = Library:CreateLabel({
        AnchorPoint = Vector2.new(0.5, 0.5);
        Position = UDim2.fromScale(0.5, 0.5);
        Size = UDim2.fromOffset(16, 16);
        Text = '▲';
        TextSize = 13;
        TextXAlignment = Enum.TextXAlignment.Center;
        TextYAlignment = Enum.TextYAlignment.Center;
        ZIndex = Z + 8;
        Parent = ArrowHolder;
    }, true);

    Library:AddToRegistry(Arrow, {
        TextColor3 = 'AccentColor';
    }, true);

    local CenterDot = Library:Create('Frame', {
        AnchorPoint = Vector2.new(0.5, 0.5);
        BackgroundColor3 = Library.AccentColor;
        BorderSizePixel = 0;
        Position = UDim2.fromScale(0.5, 0.5);
        Size = UDim2.fromOffset(3, 3);
        ZIndex = Z + 8;
        Parent = MapCanvas;
    });

    Library:AddToRegistry(CenterDot, {
        BackgroundColor3 = 'AccentColor';
    });

    local RayParams = RaycastParams.new();
    RayParams.FilterType = Enum.RaycastFilterType.Exclude;

    local EditableImage;
    local UseEditableImage = false;

    pcall(function()
        local AssetService = game:GetService('AssetService');
        EditableImage = AssetService:CreateEditableImage(Vector2.new(SampleGrid, SampleGrid));
        MapImage.Image = EditableImage;
        UseEditableImage = true;
        PixelGrid.Visible = false;
    end);

    if not UseEditableImage then
        pcall(function()
            EditableImage = Instance.new('EditableImage');
            EditableImage.Size = Vector2.new(SampleGrid, SampleGrid);
            MapImage.Image = EditableImage;
            UseEditableImage = true;
            PixelGrid.Visible = false;
        end);
    end;

    if not UseEditableImage then
        PixelGrid.Visible = true;
        MapImage.Visible = false;
        task.defer(LayoutPixelGrid);
    end;

    local function GetRaycastFilter()
        local Filter = {};

        for _, Player in Players:GetPlayers() do
            if Player.Character then
                table.insert(Filter, Player.Character);
            end;
        end;

        return Filter;
    end;

    local function GetHitColor(Result)
        if not Result then
            return Color3.fromRGB(10, 10, 12);
        end;

        if Result.Instance == workspace.Terrain then
            return workspace.Terrain:GetMaterialColor(Result.Material);
        end;

        local Part = Result.Instance;
        if Part:IsA('BasePart') then
            return Part.Color;
        end;

        return Color3.fromRGB(10, 10, 12);
    end;

    local function IsEnemyPlayer(Player)
        if Player == LocalPlayer then
            return false;
        end;

        if Library.EnemyPlayers and Library.EnemyPlayers[Player] then
            return true;
        end;

        if type(Config.IsEnemy) == 'function' then
            return not not Config.IsEnemy(Player);
        end;

        local MyTeam = LocalPlayer.Team;
        local TheirTeam = Player.Team;
        if MyTeam and TheirTeam then
            return MyTeam ~= TheirTeam;
        end;

        return true;
    end;

    local function WorldToRadarNorm(Origin, WorldPos)
        local Offset = WorldPos - Origin;
        local NormX = Offset.X / Range;
        local NormZ = Offset.Z / Range;
        local DistSq = NormX * NormX + NormZ * NormZ;

        if DistSq > 1 then
            local Dist = math.sqrt(DistSq);
            NormX /= Dist;
            NormZ /= Dist;
        end;

        return NormX, NormZ;
    end;

    local function FitOverlay()
        Panel.Size = UDim2.fromOffset(ContentSize, ContentSize);
        Overlay.Container.Size = UDim2.new(1, -8, 0, ContentSize);
        Overlay.Container.CanvasSize = UDim2.fromOffset(0, ContentSize);

        if Overlay.ContentOuter then
            Overlay.ContentOuter.Size = UDim2.new(1, -12, 0, ContentSize + 8);
        end;

        Overlay.Outer.Size = UDim2.fromOffset(OuterWidth, OuterHeight);
        LayoutPixelGrid();
    end;

    function Overlay:Resize()
        FitOverlay();
    end;

    local terrainAccum = 0;
    local terrainInterval = 1;

    local function UpdateTerrain()
        local Character = LocalPlayer.Character;
        local Root = Character and Character:FindFirstChild('HumanoidRootPart');
        if not Root then
            return
        end;

        RayParams.FilterDescendantsInstances = GetRaycastFilter();

        local Origin = Root.Position;
        local HalfGrid = SampleGrid / 2;
        local Step = (Range * 2) / SampleGrid;

        for row = 0, SampleGrid - 1 do
            for col = 0, SampleGrid - 1 do
                local OffsetX = (col - HalfGrid + 0.5) * Step;
                local OffsetZ = (row - HalfGrid + 0.5) * Step;
                local SamplePos = Origin + Vector3.new(OffsetX, 0, OffsetZ);
                local RayOrigin = SamplePos + Vector3.new(0, 512, 0);
                local Result = workspace:Raycast(RayOrigin, Vector3.new(0, -1024, 0), RayParams);
                local Color = GetHitColor(Result);

                if UseEditableImage and EditableImage then
                    pcall(function()
                        EditableImage:SetRGB(col, row, Color);
                    end);
                else
                    local Pixel = PixelFrames[row * SampleGrid + col + 1];
                    if Pixel then
                        Pixel.BackgroundColor3 = Color;
                    end;
                end;
            end;
        end;
    end;

    local UpdateBlips = LPH_NO_VIRTUALIZE(function(Root, Camera)
        local Origin = Root.Position;
        local BlipIndex = 0;

        for _, Player in Players:GetPlayers() do
            if Player ~= LocalPlayer and IsEnemyPlayer(Player) then
                local Character = Player.Character;
                local OtherRoot = Character and Character:FindFirstChild('HumanoidRootPart');
                if OtherRoot then
                    BlipIndex += 1;
                    local Blip = BlipPool[BlipIndex];
                    if Blip then
                        local NormX, NormZ = WorldToRadarNorm(Origin, OtherRoot.Position);

                        Blip.BackgroundColor3 = EnemyColor;
                        Blip.Size = UDim2.fromOffset(BlipPixel, BlipPixel);
                        Blip.Position = UDim2.fromScale(NormX * 0.5 + 0.5, NormZ * 0.5 + 0.5);
                        Blip.Visible = true;
                    end;
                end;
            end;
        end;

        for Index = BlipIndex + 1, MaxBlips do
            local Blip = BlipPool[Index];
            if Blip then
                Blip.Visible = false;
            end;
        end;

        local Look = Camera.CFrame.LookVector;
        ArrowHolder.Rotation = math.deg(math.atan2(Look.X, -Look.Z));
    end);

    local UpdateRadar = LPH_NO_VIRTUALIZE(function(Delta)
        if not Overlay.Visible then
            return
        end;

        local Character = LocalPlayer.Character;
        local Root = Character and Character:FindFirstChild('HumanoidRootPart');
        local Camera = workspace.CurrentCamera;
        if not Root or not Camera then
            for Index = 1, MaxBlips do
                BlipPool[Index].Visible = false;
            end;
            return
        end;

        terrainAccum += Delta;
        if terrainAccum >= terrainInterval then
            terrainAccum = 0;
            UpdateTerrain();
        end;

        UpdateBlips(Root, Camera);
    end);

    function Overlay:SetVisible(Bool)
        Overlay.Visible = not not Bool;
        Overlay.Outer.Visible = Overlay.Visible;
        Library:UpdateOverlayGlow(Overlay);
    end;

    Overlay._RadarUpdate = RunService.RenderStepped:Connect(UpdateRadar);
    Library:GiveSignal(Overlay._RadarUpdate);

    Library.RadarOverlay = Overlay;

    task.defer(function()
        FitOverlay();
        UpdateTerrain();
    end);

    return Overlay;
end;

function Library:CreateVelocityGraphOverlay(Config)
    Config = Config or {};

    local BoxWidth = Config.Width or 200;
    local BoxHeight = Config.Height or 80;
    local LabelHeight = 16;
    local LabelGap = 4;
    local ContentHeight = LabelHeight + LabelGap + BoxHeight;
    local OuterWidth = BoxWidth + 24;
    local OuterHeight = 26 + ContentHeight + 14;

    local Overlay = Library:CreateOverlayWindow({
        Title = 'Velocity';
        AccentPart = 'ity';
        Size = UDim2.fromOffset(OuterWidth, OuterHeight);
        Position = Config.Position or UDim2.new(0.5, -OuterWidth / 2, 1, -240);
        Visible = Config.Visible;
        ZIndex = Config.ZIndex or 155;
    });

    local Z = Overlay.ZIndexBase + 15;

    local Content = Library:Create('Frame', {
        BackgroundTransparency = 1;
        Size = UDim2.new(1, -4, 0, ContentHeight);
        ZIndex = Z;
        Parent = Overlay.Container;
    });

    local SpeedLabel = Library:CreateLabel({
        Size = UDim2.new(1, 0, 0, LabelHeight);
        Text = 'SPEED: 0';
        TextSize = 13;
        TextXAlignment = Enum.TextXAlignment.Center;
        ZIndex = Z + 2;
        Parent = Content;
    });

    local GraphArea = Library:Create('Frame', {
        BackgroundTransparency = 1;
        BorderSizePixel = 0;
        ClipsDescendants = true;
        Position = UDim2.new(0, 0, 0, LabelHeight + LabelGap);
        Size = UDim2.new(1, 0, 0, BoxHeight);
        ZIndex = Z + 1;
        Parent = Content;
    });

    local GraphState = {
        Lines = {};
        LastY = BoxHeight - 2;
        LinePool = {};
        MaxLines = BoxWidth;
    };

    for Index = 1, GraphState.MaxLines do
        GraphState.LinePool[Index] = Library:Create('Frame', {
            AnchorPoint = Vector2.new(0, 0.5);
            BackgroundColor3 = Color3.fromRGB(220, 220, 220);
            BorderSizePixel = 0;
            Visible = false;
            ZIndex = Z + 3;
            Parent = GraphArea;
        });
    end;

    local function FitOverlay()
        Content.Size = UDim2.new(1, -4, 0, ContentHeight);
        Overlay.Container.Size = UDim2.new(1, -8, 0, ContentHeight);
        Overlay.Container.CanvasSize = UDim2.fromOffset(0, ContentHeight);

        if Overlay.ContentOuter then
            Overlay.ContentOuter.Size = UDim2.new(1, -12, 0, ContentHeight + 8);
        end;

        Overlay.Outer.Size = UDim2.fromOffset(OuterWidth, OuterHeight);
    end;

    function Overlay:Resize()
        FitOverlay();
    end;

    local function SetGraphVisible(Visible)
        for _, Segment in GraphState.LinePool do
            Segment.Visible = Visible;
        end;
    end;

    local function PlaceSegment(Segment, XFrom, YFrom, XTo, YTo, Transparency)
        local DeltaX = XTo - XFrom;
        local DeltaY = YTo - YFrom;
        local Length = math.sqrt(DeltaX * DeltaX + DeltaY * DeltaY);

        if Length < 0.35 then
            Segment.Visible = false;
            return
        end;

        local Angle = math.deg(math.atan2(DeltaY, DeltaX));
        local MidY = (YFrom + YTo) * 0.5;

        Segment.Size = UDim2.fromOffset(Length, 1.2);
        Segment.Position = UDim2.fromOffset(XFrom, MidY);
        Segment.Rotation = Angle;
        Segment.BackgroundTransparency = Transparency;
        Segment.Visible = true;
    end;

    local UpdateGraph = LPH_NO_VIRTUALIZE(function()
        if not Overlay.Visible or not Overlay.Outer or not Overlay.Outer.Visible then
            SetGraphVisible(false);
            return
        end;

        local Root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart');
        if not Root then
            SetGraphVisible(false);
            return
        end;

        local GraphWidth = math.max(math.floor(GraphArea.AbsoluteSize.X + 0.5), BoxWidth);
        local GraphBaseY = BoxHeight;

        local Velocity = Root.AssemblyLinearVelocity;
        local Vel = (Vector3.new(Velocity.X * 1.25, 0, Velocity.Z * 1.25)).Magnitude * 14;

        local Unit = GraphBaseY - (Vel / 7.5);
        Unit = math.clamp(Unit, 2, GraphBaseY - 2);

        SpeedLabel.Text = string.format('SPEED: %d', math.floor(Vel));

        if #GraphState.Lines >= GraphWidth then
            table.remove(GraphState.Lines, 1);
        end;

        for _, Line in GraphState.Lines do
            Line.XFrom -= 1;
            Line.XTo -= 1;
        end;

        table.insert(GraphState.Lines, {
            XFrom = GraphWidth - 1;
            YFrom = GraphState.LastY;
            XTo = GraphWidth;
            YTo = Unit;
        });

        GraphState.LastY = Unit;

        local Count = #GraphState.Lines;
        for Index, Line in GraphState.Lines do
            local AgeFromRight = Count - Index;
            local Transparency = math.clamp(AgeFromRight / 50, 0, 1) * 0.55;
            PlaceSegment(GraphState.LinePool[Index], Line.XFrom, Line.YFrom, Line.XTo, Line.YTo, Transparency);
        end;

        for Index = Count + 1, GraphState.MaxLines do
            local Segment = GraphState.LinePool[Index];
            if Segment then
                Segment.Visible = false;
            end;
        end;
    end);

    function Overlay:SetVisible(Bool)
        Overlay.Visible = not not Bool;
        Overlay.Outer.Visible = Overlay.Visible;
        Library:UpdateOverlayGlow(Overlay);

        if not Overlay.Visible then
            SetGraphVisible(false);
        end;
    end;

    function Overlay:CleanupDrawings()
        SetGraphVisible(false);
        table.clear(GraphState.Lines);
        GraphState.LastY = BoxHeight - 2;
    end;

    Overlay._GraphUpdate = RunService.RenderStepped:Connect(UpdateGraph);
    Library:GiveSignal(Overlay._GraphUpdate);

    Library.VelocityGraphOverlay = Overlay;

    task.defer(function()
        FitOverlay();
    end);

    return Overlay;
end;

function Library:WrapKeybindOverlay(Config)
    return Library:CreateKeybindsOverlay(Config or {});
end;

function Library:GiveSignal(Signal)
    table.insert(Library.Signals, Signal);
end;

function Library:Unload()
    for Idx = #Library.Signals, 1, -1 do
        local Connection = table.remove(Library.Signals, Idx);
        Connection:Disconnect();
    end;

    if Library.OnUnload then
        Library.OnUnload();
    end;

    if Library.VelocityGraphOverlay and Library.VelocityGraphOverlay.CleanupDrawings then
        Library.VelocityGraphOverlay:CleanupDrawings();
    end;

    ScreenGui:Destroy();
end;

function Library:OnUnload(Callback)
    Library.OnUnload = Callback;
end;

Library:GiveSignal(ScreenGui.DescendantRemoving:Connect(function(Instance)
    if Library.RegistryMap[Instance] then
        Library:RemoveFromRegistry(Instance);
    end;
end));

local BaseAddons = {};

do
    local Funcs = {};

    function Funcs:AddColorPicker(Idx, Info)
        local ToggleLabel = self.TextLabel;

        assert(Info.Default, 'AddColorPicker: Missing default value.');

        local ColorPicker = {
            Value = Info.Default;
            Transparency = Info.Transparency or 0;
            Type = 'ColorPicker';
            Title = type(Info.Title) == 'string' and Info.Title or 'Color picker',
            Callback = Info.Callback or function(Color) end;
        };

        function ColorPicker:SetHSVFromRGB(Color)
            local H, S, V = Color3.toHSV(Color);

            ColorPicker.Hue = H;
            ColorPicker.Sat = S;
            ColorPicker.Vib = V;
        end;

        ColorPicker:SetHSVFromRGB(ColorPicker.Value);

        local DisplayFrame = Library:Create('Frame', {
            BackgroundColor3 = ColorPicker.Value;
            BorderColor3 = Library.AccentColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = IsTouchDevice and UDim2.new(0, 18, 0, 10) or UDim2.new(0, 28, 0, 14);
            ZIndex = ToggleLabel.ZIndex + 1;
            Parent = ToggleLabel;
        });

        Library:AddToRegistry(DisplayFrame, { BorderColor3 = 'AccentColor' });

        local PickerFrameOuter = Library:Create('Frame', {
            Name = 'Color';
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.fromOffset(DisplayFrame.AbsolutePosition.X, DisplayFrame.AbsolutePosition.Y + 18),
            Size = UDim2.fromOffset(230, 226);
            Visible = false;
            ZIndex = 15;
            Parent = ScreenGui,
        });

        Library:MakeDraggable(PickerFrameOuter, 20);

        if IsTouchDevice then
            Library:Create('UIScale', {
                Scale = Library.MobilePickerScale or Library.MobileOverlayScale or 0.55;
                Parent = PickerFrameOuter;
            });
        end;

        local PickerFrameInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 16;
            Parent = PickerFrameOuter;
        });

        local Highlight = Library:Create('Frame', {
            BackgroundColor3 = Library.AccentColor;
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 0, 2);
            ZIndex = 17;
            Parent = PickerFrameInner;
        });

        local TitleLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 0, 20);
            Position = UDim2.new(0, 5, 0, 2);
            TextXAlignment = Enum.TextXAlignment.Left;
            Text = ColorPicker.Title;
            ZIndex = 17;
            Parent = PickerFrameInner;
        });

        local FlagLabel = Library:CreateLabel({
            Size = UDim2.new(1, -10, 0, 20);
            Position = UDim2.new(0, 5, 0, 2);
            TextXAlignment = Enum.TextXAlignment.Right;
            Text = "flagname";
            TextColor3 = Color3.fromRGB(80, 80, 80);
            ZIndex = 17;
            Parent = PickerFrameInner;
        });

        local Divider = Library:Create('Frame', {
            BackgroundColor3 = Library.OutlineColor;
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 0, 1);
            Position = UDim2.new(0, 0, 0, 22);
            ZIndex = 17;
            Parent = PickerFrameInner;
        });

        local SatVibMapOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.new(0, 4, 0, 25);
            Size = UDim2.new(1, -8, 0, 110);
            ZIndex = 17;
            Parent = PickerFrameInner;
        });

        local SatVibMapInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 18;
            Parent = SatVibMapOuter;
        });

        local SatVibMap = Library:Create('ImageLabel', {
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 18;
            Image = 'rbxassetid://4155801252';
            Parent = SatVibMapInner;
        });

        local CursorOuter = Library:Create('ImageLabel', {
            AnchorPoint = Vector2.new(0.5, 0.5);
            Size = UDim2.new(0, 6, 0, 6);
            BackgroundTransparency = 1;
            Image = 'http://www.roblox.com/asset/?id=9619665977';
            ImageColor3 = Color3.new(0, 0, 0);
            ZIndex = 19;
            Parent = SatVibMap;
        });

        local CursorInner = Library:Create('ImageLabel', {
            Size = UDim2.new(0, CursorOuter.Size.X.Offset - 2, 0, CursorOuter.Size.Y.Offset - 2);
            Position = UDim2.new(0, 1, 0, 1);
            BackgroundTransparency = 1;
            Image = 'http://www.roblox.com/asset/?id=9619665977';
            ZIndex = 20;
            Parent = CursorOuter;
        });

        local HueSelectorOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.new(0, 4, 0, 140);
            Size = UDim2.new(1, -8, 0, 10);
            ZIndex = 17;
            Parent = PickerFrameInner;
        });

        local HueSelectorInner = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(1, 1, 1);
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 18;
            Parent = HueSelectorOuter;
        });

        local HueCursor = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(1, 1, 1);
            AnchorPoint = Vector2.new(0.5, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(0, 2, 1, 0);
            ZIndex = 18;
            Parent = HueSelectorInner;
        });

        local InputWidth = 47;
        local InputHeight = 18;
        local InputSpacing = 4;

        local function CreateInputBox(posX, width, placeholder)
            local BoxOuter = Library:Create('Frame', {
                BorderColor3 = Color3.new(0, 0, 0);
                Position = UDim2.new(0, posX, 0, 155);
                Size = UDim2.new(0, width, 0, InputHeight);
                ZIndex = 18;
                Parent = PickerFrameInner;
            });
            local BoxInner = Library:Create('Frame', {
                BackgroundColor3 = Library.MainColor;
                BorderColor3 = Library.OutlineColor;
                BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.new(1, 0, 1, 0);
                ZIndex = 18;
                Parent = BoxOuter;
            });
            local TextBox = Library:Create('TextBox', {
                BackgroundTransparency = 1;
                Size = UDim2.new(1, 0, 1, 0);
                Font = Library.Font;
                PlaceholderColor3 = Color3.fromRGB(120, 120, 120);
                PlaceholderText = placeholder;
                Text = "";
                TextColor3 = Library.FontColor;
                TextSize = 13;
                TextStrokeTransparency = 0;
                TextXAlignment = Enum.TextXAlignment.Center;
                ZIndex = 20;
                Parent = BoxInner;
            });
            Library:ApplyTextStroke(TextBox);
            Library:AddToRegistry(BoxInner, { BackgroundColor3 = 'MainColor'; BorderColor3 = 'OutlineColor'; });
            Library:AddToRegistry(TextBox, { TextColor3 = 'FontColor' });
            return TextBox;
        end;

        local RBox = CreateInputBox(4, 48, "R");
        local GBox = CreateInputBox(4 + 48 + 4, 48, "G");
        local BBox = CreateInputBox(4 + 48*2 + 8, 48, "B");
        local HexBox = CreateInputBox(4 + 48*3 + 12, 66, "HEX");

        local function CreateButton(posX, width, text)
            local BtnOuter = Library:Create('Frame', {
                BorderColor3 = Color3.new(0, 0, 0);
                Position = UDim2.new(0, posX, 0, 177);
                Size = UDim2.new(0, width, 0, 18);
                ZIndex = 18;
                Parent = PickerFrameInner;
            });
            local BtnInner = Library:Create('Frame', {
                BackgroundColor3 = Library.MainColor;
                BorderColor3 = Library.OutlineColor;
                BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.new(1, 0, 1, 0);
                ZIndex = 18;
                Parent = BtnOuter;
            });
            local Label = Library:CreateLabel({
                Size = UDim2.new(1, 0, 1, 0);
                TextSize = 13;
                Text = text;
                ZIndex = 20;
                Parent = BtnInner;
            });
            Library:OnHighlight(BtnOuter, BtnOuter,
                { BorderColor3 = 'AccentColor' },
                { BorderColor3 = 'Black' }
            );
            Library:AddToRegistry(BtnInner, { BackgroundColor3 = 'MainColor'; BorderColor3 = 'OutlineColor'; });
            return BtnOuter;
        end;

        local CopyBtn = CreateButton(4, 109, "Copy");
        local PasteBtn = CreateButton(4 + 109 + 4, 109, "Paste");

        local ConfirmBtnOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.new(0, 4, 0, 199);
            Size = UDim2.new(1, -8, 0, 18);
            ZIndex = 18;
            Parent = PickerFrameInner;
        });
        local ConfirmBtnInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 18;
            Parent = ConfirmBtnOuter;
        });
        local ConfirmLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 1, 0);
            TextSize = 13;
            Text = "Confirm";
            ZIndex = 20;
            Parent = ConfirmBtnInner;
        });
        Library:OnHighlight(ConfirmBtnOuter, ConfirmBtnOuter,
            { BorderColor3 = 'AccentColor' },
            { BorderColor3 = 'Black' }
        );
        ConfirmBtnOuter.InputBegan:Connect(function(Input)
            if IsPrimaryPress(Input) then
                ColorPicker:Hide();
            end;
        end);
        Library:AddToRegistry(ConfirmBtnInner, { BackgroundColor3 = 'MainColor'; BorderColor3 = 'OutlineColor'; });

        local ContextMenu = {}
        do
            ContextMenu.Options = {};
            ContextMenu.Container = Library:Create('Frame', {
                BorderColor3 = Color3.new(),
                ZIndex = 14,
                Visible = false,
                Parent = ScreenGui
            });

            ContextMenu.Inner = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor;
                BorderColor3 = Library.OutlineColor;
                BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.fromScale(1, 1);
                ZIndex = 15;
                Parent = ContextMenu.Container;
            });

            Library:Create('UIListLayout', {
                Name = 'Layout',
                FillDirection = Enum.FillDirection.Vertical;
                SortOrder = Enum.SortOrder.LayoutOrder;
                Parent = ContextMenu.Inner;
            });

            Library:Create('UIPadding', {
                Name = 'Padding',
                PaddingLeft = UDim.new(0, 4),
                Parent = ContextMenu.Inner,
            });

            local function updateMenuPosition()
                ContextMenu.Container.Position = UDim2.fromOffset(
                    (DisplayFrame.AbsolutePosition.X + DisplayFrame.AbsoluteSize.X) + 4,
                    DisplayFrame.AbsolutePosition.Y + 1
                );
            end;

            local function updateMenuSize()
                local menuWidth = 60;
                for i, label in next, ContextMenu.Inner:GetChildren() do
                    if label:IsA('TextLabel') then
                        menuWidth = math.max(menuWidth, label.TextBounds.X);
                    end;
                end;

                ContextMenu.Container.Size = UDim2.fromOffset(
                    menuWidth + 8,
                    ContextMenu.Inner.Layout.AbsoluteContentSize.Y + 4
                );
            end;

            DisplayFrame:GetPropertyChangedSignal('AbsolutePosition'):Connect(updateMenuPosition);
            ContextMenu.Inner.Layout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(updateMenuSize);

            task.spawn(updateMenuPosition);
            task.spawn(updateMenuSize);

            Library:AddToRegistry(ContextMenu.Inner, {
                BackgroundColor3 = 'BackgroundColor';
                BorderColor3 = 'OutlineColor';
            });

            function ContextMenu:Show()
                self.Container.Visible = true;
            end;

            function ContextMenu:Hide()
                self.Container.Visible = false;
            end;

            function ContextMenu:AddOption(Str, Callback)
                if type(Callback) ~= 'function' then
                    Callback = function() end;
                end;

                local Button = Library:CreateLabel({
                    Active = false;
                    Size = UDim2.new(1, 0, 0, 15);
                    TextSize = 13;
                    Text = Str;
                    ZIndex = 16;
                    Parent = self.Inner;
                    TextXAlignment = Enum.TextXAlignment.Left,
                });

                Library:OnHighlight(Button, Button,
                    { TextColor3 = 'AccentColor' },
                    { TextColor3 = 'FontColor' }
                );

                Button.InputBegan:Connect(function(Input)
                    if not IsPrimaryPress(Input) then
                        return
                    end;

                    Callback();
                end);
            end;

            ContextMenu:AddOption('Copy color', function()
                Library.ColorClipboard = ColorPicker.Value;
                Library:Notify('Copied color!', 2);
            end);

            ContextMenu:AddOption('Paste color', function()
                if not Library.ColorClipboard then
                    return Library:Notify('You have not copied a color!', 2);
                end;
                ColorPicker:SetValueRGB(Library.ColorClipboard);
            end);

            ContextMenu:AddOption('Copy HEX', function()
                pcall(setclipboard, ColorPicker.Value:ToHex());
                Library:Notify('Copied hex code to clipboard!', 2);
            end);

            ContextMenu:AddOption('Copy RGB', function()
                pcall(setclipboard, table.concat({ math.floor(ColorPicker.Value.R * 255), math.floor(ColorPicker.Value.G * 255), math.floor(ColorPicker.Value.B * 255) }, ', '));
                Library:Notify('Copied RGB values to clipboard!', 2);
            end);

        end;

        Library:AddToRegistry(PickerFrameInner, { BackgroundColor3 = 'BackgroundColor'; BorderColor3 = 'OutlineColor'; });
        Library:AddToRegistry(Highlight, { BackgroundColor3 = 'AccentColor'; });
        Library:AddToRegistry(SatVibMapInner, { BackgroundColor3 = 'BackgroundColor'; BorderColor3 = 'OutlineColor'; });

        local SequenceTable = {};

        for Hue = 0, 1, 0.1 do
            table.insert(SequenceTable, ColorSequenceKeypoint.new(Hue, Color3.fromHSV(Hue, 1, 1)));
        end;

        local HueSelectorGradient = Library:Create('UIGradient', {
            Color = ColorSequence.new(SequenceTable);
            Rotation = 0;
            Parent = HueSelectorInner;
        });

        local function onRGBFocusLost()
            local r = tonumber(RBox.Text) or 255;
            local g = tonumber(GBox.Text) or 255;
            local b = tonumber(BBox.Text) or 255;
            ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = Color3.toHSV(Color3.fromRGB(r, g, b));
            ColorPicker:Display();
        end;
        RBox.FocusLost:Connect(onRGBFocusLost);
        GBox.FocusLost:Connect(onRGBFocusLost);
        BBox.FocusLost:Connect(onRGBFocusLost);

        HexBox.FocusLost:Connect(function()
            local success, result = pcall(Color3.fromHex, HexBox.Text);
            if success and typeof(result) == 'Color3' then
                ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = Color3.toHSV(result);
            end;
            ColorPicker:Display();
        end);

        CopyBtn.InputBegan:Connect(function(Input)
            if IsPrimaryPress(Input) then
                Library.ColorClipboard = ColorPicker.Value;
                Library:Notify('Copied color!', 2);
            end;
        end);

        PasteBtn.InputBegan:Connect(function(Input)
            if IsPrimaryPress(Input) then
                if Library.ColorClipboard then
                    ColorPicker:SetValueRGB(Library.ColorClipboard);
                else
                    Library:Notify('No color copied!', 2);
                end;
            end;
        end);

        function ColorPicker:Display()
            ColorPicker.Value = Color3.fromHSV(ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib);
            SatVibMap.BackgroundColor3 = Color3.fromHSV(ColorPicker.Hue, 1, 1);

            Library:Create(DisplayFrame, {
                BackgroundColor3 = ColorPicker.Value;
                BackgroundTransparency = ColorPicker.Transparency;
                BorderColor3 = Library:GetDarkerColor(ColorPicker.Value);
            });

            CursorOuter.Position = UDim2.new(ColorPicker.Sat, 0, 1 - ColorPicker.Vib, 0);
            HueCursor.Position = UDim2.new(ColorPicker.Hue, 0, 0, 0);

            RBox.Text = tostring(math.floor(ColorPicker.Value.R * 255));
            GBox.Text = tostring(math.floor(ColorPicker.Value.G * 255));
            BBox.Text = tostring(math.floor(ColorPicker.Value.B * 255));
            HexBox.Text = ColorPicker.Value:ToHex();

            if not Library.ThemeUpdating then
                Library:SafeCallback(ColorPicker.Callback, ColorPicker.Value);
                Library:SafeCallback(ColorPicker.Changed, ColorPicker.Value);
            end;
        end;

        function ColorPicker:OnChanged(Func)
            ColorPicker.Changed = Func;
            Func(ColorPicker.Value);
        end;

        function ColorPicker:Show()
            for Frame, Val in next, Library.OpenedFrames do
                if Frame.Name == 'Color' then
                    Frame.Visible = false;
                    Library.OpenedFrames[Frame] = nil;
                end;
            end;

            PickerFrameOuter.Position = UDim2.fromOffset(DisplayFrame.AbsolutePosition.X, DisplayFrame.AbsolutePosition.Y + 18);
            Library:ApplyPopupZIndex(PickerFrameOuter, 15);
            PickerFrameOuter.Visible = true;
            Library.OpenedFrames[PickerFrameOuter] = true;
        end;

        function ColorPicker:Hide()
            PickerFrameOuter.Visible = false;
            Library.OpenedFrames[PickerFrameOuter] = nil;
        end;

        function ColorPicker:SetValue(HSV, Transparency)
            local Color = Color3.fromHSV(HSV[1], HSV[2], HSV[3]);

            ColorPicker.Transparency = Transparency or 0;
            ColorPicker:SetHSVFromRGB(Color);
            ColorPicker:Display();
        end;

        function ColorPicker:SetValueRGB(Color, Transparency)
            ColorPicker.Transparency = Transparency or 0;
            ColorPicker:SetHSVFromRGB(Color);
            ColorPicker:Display();
        end;

        SatVibMap.InputBegan:Connect(function(Input)
            if IsPrimaryPress(Input) then
                while IsPressActive(Input) do
                    local Pos = GetPointerPosition(Input);
                    local MinX = SatVibMap.AbsolutePosition.X;
                    local MaxX = MinX + SatVibMap.AbsoluteSize.X;
                    local MouseX = math.clamp(Pos.X, MinX, MaxX);

                    local MinY = SatVibMap.AbsolutePosition.Y;
                    local MaxY = MinY + SatVibMap.AbsoluteSize.Y;
                    local MouseY = math.clamp(Pos.Y, MinY, MaxY);

                    ColorPicker.Sat = (MouseX - MinX) / (MaxX - MinX);
                    ColorPicker.Vib = 1 - ((MouseY - MinY) / (MaxY - MinY));
                    ColorPicker:Display();

                    RenderStepped:Wait();
                end;

                Library:AttemptSave();
            end;
        end);

        HueSelectorInner.InputBegan:Connect(function(Input)
            if IsPrimaryPress(Input) then
                while IsPressActive(Input) do
                    local Pos = GetPointerPosition(Input);
                    local MinX = HueSelectorInner.AbsolutePosition.X;
                    local MaxX = MinX + HueSelectorInner.AbsoluteSize.X;
                    local MouseX = math.clamp(Pos.X, MinX, MaxX);

                    ColorPicker.Hue = ((MouseX - MinX) / (MaxX - MinX));
                    ColorPicker:Display();

                    RenderStepped:Wait();
                end;

                Library:AttemptSave();
            end;
        end);

        DisplayFrame.InputBegan:Connect(function(Input)
            if IsPrimaryPress(Input) and not Library:MouseIsOverOpenedFrame() then
                if PickerFrameOuter.Visible then
                    ColorPicker:Hide();
                else
                    ContextMenu:Hide();
                    ColorPicker:Show();
                end;
            elseif Input.UserInputType == Enum.UserInputType.MouseButton2 and not Library:MouseIsOverOpenedFrame() then
                ContextMenu:Show();
                ColorPicker:Hide();
            end;
        end);

        Library:GiveSignal(InputService.InputBegan:Connect(function(Input)
            if IsPrimaryPress(Input) then
                local Pos = GetPointerPosition(Input);
                local AbsPos, AbsSize = PickerFrameOuter.AbsolutePosition, PickerFrameOuter.AbsoluteSize;

                if Pos.X < AbsPos.X or Pos.X > AbsPos.X + AbsSize.X
                    or Pos.Y < (AbsPos.Y - 20 - 1) or Pos.Y > AbsPos.Y + AbsSize.Y then

                    ColorPicker:Hide();
                end;

                if not Library:IsMouseOverFrame(ContextMenu.Container) then
                    ContextMenu:Hide();
                end;
            end;

            if Input.UserInputType == Enum.UserInputType.MouseButton2 and ContextMenu.Container.Visible then
                if not Library:IsMouseOverFrame(ContextMenu.Container) and not Library:IsMouseOverFrame(DisplayFrame) then
                    ContextMenu:Hide();
                end;
            end;
        end));

        ColorPicker:Display();
        ColorPicker.DisplayFrame = DisplayFrame;

        if type(ColorPicker)=="table" and ColorPicker.SetVisible==nil then ColorPicker.SetVisible=function() end end;
        Options[Idx] = ColorPicker;

        return self;
    end;

    function Funcs:AddKeyPicker(Idx, Info)
        local ParentObj = self;
        local ToggleLabel = self.TextLabel;
        local Container = self.Container;

        assert(Info.Default, 'AddKeyPicker: Missing default value.');

        local KeyPicker = {
            Value = Info.Default;
            Toggled = false;
            Mode = Info.Mode or 'Toggle';
            Type = 'KeyPicker';
            Callback = Info.Callback or function(Value) end;
            ChangedCallback = Info.ChangedCallback or function(New) end;

            SyncToggleState = Info.SyncToggleState or false;
        };

        if KeyPicker.SyncToggleState then
            Info.Modes = { 'Toggle' };
            Info.Mode = 'Toggle';

            if ParentObj.Type == 'Toggle' then
                KeyPicker.Toggled = not not ParentObj.Value;
            end;
        end;

        local PickOuter = Library:Create('Frame', {
            BackgroundTransparency = 1;
            BorderSizePixel = 0;
            Size = UDim2.new(0, 28, 0, 15);
            ZIndex = ToggleLabel.ZIndex + 1;
            Parent = ToggleLabel;
        });

        local PickInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = ToggleLabel.ZIndex + 2;
            Parent = PickOuter;
        });

        Library:AddToRegistry(PickInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });

        local DisplayLabel = Library:CreateLabel({
            Size = UDim2.new(1, -4, 1, 0);
            Position = UDim2.new(0, 2, 0, 0);
            TextSize = 12;
            TextColor3 = Color3.new(1, 1, 1);
            Text = Info.Default == 'None' and '( - )' or Info.Default;
            ZIndex = ToggleLabel.ZIndex + 3;
            Parent = PickInner;
        });

        local function UpdateDisplayWidth(text)
            local display = text == 'None' and '( - )' or text;
            DisplayLabel.Text = display;
            local textWidth = Library:GetTextBounds(display, Library.Font, 13);
            PickOuter.Size = UDim2.new(0, textWidth + 6, 0, 15);
        end;
        UpdateDisplayWidth(Info.Default);

        local ModeSelectOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.fromOffset(ToggleLabel.AbsolutePosition.X + ToggleLabel.AbsoluteSize.X + 4, ToggleLabel.AbsolutePosition.Y + 1);
            Size = UDim2.new(0, 60, 0, 45 + 2);
            Visible = false;
            ZIndex = Library:GetPopupZIndex(0);
            Parent = ScreenGui;
        });

        ToggleLabel:GetPropertyChangedSignal('AbsolutePosition'):Connect(function()
            ModeSelectOuter.Position = UDim2.fromOffset(ToggleLabel.AbsolutePosition.X + ToggleLabel.AbsoluteSize.X + 4, ToggleLabel.AbsolutePosition.Y + 1);
        end);

        local ModeSelectInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = Library:GetPopupZIndex(1);
            Parent = ModeSelectOuter;
        });

        Library:AddToRegistry(ModeSelectInner, {
            BackgroundColor3 = 'BackgroundColor';
            BorderColor3 = 'OutlineColor';
        });

        Library:Create('UIListLayout', {
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = ModeSelectInner;
        });

        local rowBase = Library:GetKeybindRowZBase();

        local KeybindRow = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, -4, 0, 22);
            Visible = false;
            ZIndex = rowBase;
            Parent = Library.KeybindContainer;
        });

        local NameLabel = Library:CreateLabel({
            Text = Info.Text or '';
            TextXAlignment = Enum.TextXAlignment.Left;
            Size = UDim2.new(1, -84, 1, 0);
            TextSize = 13;
            TextColor3 = Color3.new(1, 1, 1);
            ZIndex = rowBase + 3;
            Parent = KeybindRow;
        }, true);

        Library:SetGradientText(NameLabel, Info.Text or '');

        local KeyBox = Library:Create('Frame', {
            AnchorPoint = Vector2.new(1, 0.5);
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Position = UDim2.new(1, 0, 0.5, 0);
            Size = UDim2.fromOffset(52, 18);
            ZIndex = rowBase + 3;
            Parent = KeybindRow;
        });

        Library:AddToRegistry(KeyBox, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        }, true);

        local ValueLabel = Library:CreateLabel({
            Size = UDim2.new(1, -4, 1, 0);
            Position = UDim2.new(0, 2, 0, 0);
            TextSize = 12;
            TextColor3 = Color3.new(1, 1, 1);
            TextXAlignment = Enum.TextXAlignment.Center;
            ZIndex = rowBase + 5;
            Parent = KeyBox;
        }, true);

        KeyPicker.KeybindRow = KeybindRow;
        KeyPicker.NameLabel = NameLabel;
        KeyPicker.KeyBox = KeyBox;

        local Modes = Info.Modes or { 'Always', 'Toggle', 'Hold' };
        local ModeButtons = {};

        for Idx, Mode in next, Modes do
            local ModeButton = {};

            local Label = Library:CreateLabel({
                Active = false;
                Size = UDim2.new(1, 0, 0, 15);
                TextSize = 13;
                Text = Mode;
                ZIndex = Library:GetPopupZIndex(2);
                Parent = ModeSelectInner;
            });

            function ModeButton:Select()
                for _, Button in next, ModeButtons do
                    Button:Deselect();
                end;

                KeyPicker.Mode = Mode;

                Label.TextColor3 = Library.AccentColor;
                Library.RegistryMap[Label].Properties.TextColor3 = 'AccentColor';

                ModeSelectOuter.Visible = false;
            end;

            function ModeButton:Deselect()
                KeyPicker.Mode = nil;

                Label.TextColor3 = Library.FontColor;
                Library.RegistryMap[Label].Properties.TextColor3 = 'FontColor';
            end;

            Label.InputBegan:Connect(function(Input)
                if IsPrimaryPress(Input) then
                    ModeButton:Select();
                    Library:AttemptSave();
                end;
            end);

            if Mode == KeyPicker.Mode then
                ModeButton:Select();
            end;

            ModeButtons[Mode] = ModeButton;
        end;

        function KeyPicker:Update()
            if Info.NoUI then
                return;
            end;

            local State = KeyPicker:GetState();
            local keyText = KeyPicker.Value == 'None' and '-' or KeyPicker.Value;

            NameLabel.Text = Info.Text or '';
            ValueLabel.Text = keyText;
            ValueLabel.TextColor3 = Color3.new(1, 1, 1);
            ValueLabel.TextTransparency = 0;
            Library:SetGradientText(NameLabel, Info.Text or '');

            local textWidth = Library:GetTextBounds(keyText, Library.Font, 12);
            KeyBox.Size = UDim2.fromOffset(math.max(textWidth + 10, 36), 18);

            PickOuter.ZIndex = ToggleLabel.ZIndex + 1;
            PickInner.ZIndex = ToggleLabel.ZIndex + 2;
            DisplayLabel.ZIndex = ToggleLabel.ZIndex + 3;

            KeybindRow.Visible = State;
            Library:SyncKeybindRowsZIndex();
            Library:UpdateKeybindOverlaySize();
        end;

        function KeyPicker:GetState()
            if KeyPicker.Mode == 'Always' then
                return true;
            elseif KeyPicker.Mode == 'Hold' then
                if KeyPicker.Value == 'None' then
                    return false;
                end;

                local Key = KeyPicker.Value;

                if Key == 'MB1' or Key == 'MB2' then
                    return Key == 'MB1' and InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
                        or Key == 'MB2' and InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2);
                else
                    return InputService:IsKeyDown(Enum.KeyCode[KeyPicker.Value]);
                end;
            else
                return KeyPicker.Toggled;
            end;
        end;

        function KeyPicker:SetValue(Data)
            local Key, Mode = Data[1], Data[2];
            UpdateDisplayWidth(Key);
            ModeButtons[Mode]:Select();
            KeyPicker:Update();
        end;

        function KeyPicker:OnClick(Callback)
            KeyPicker.Clicked = Callback;
        end;

        function KeyPicker:OnChanged(Callback)
            KeyPicker.Changed = Callback;
            Callback(KeyPicker.Value);
        end;

        if ParentObj.Addons then
            table.insert(ParentObj.Addons, KeyPicker);
        end;

        function KeyPicker:DoClick()
            if ParentObj.Type == 'Toggle' and KeyPicker.SyncToggleState then
                ParentObj:SetValue(not ParentObj.Value);
            end;

            Library:SafeCallback(KeyPicker.Callback, KeyPicker.Toggled);
            Library:SafeCallback(KeyPicker.Clicked, KeyPicker.Toggled);
        end;

        local Picking = false;

        PickOuter.InputBegan:Connect(function(Input)
            if IsPrimaryPress(Input) and not Library:MouseIsOverOpenedFrame() then
                Picking = true;

                UpdateDisplayWidth('');

                local Break;
                local Text = '';

                task.spawn(function()
                    while (not Break) do
                        if Text == '...' then
                            Text = '';
                        end;

                        Text = Text .. '.';
                        UpdateDisplayWidth(Text);

                        wait(0.4);
                    end;
                end);

                wait(0.2);

                local Event;
                Event = InputService.InputBegan:Connect(function(Input)
                    local Key;

                    if Input.UserInputType == Enum.UserInputType.Keyboard then
                        Key = Input.KeyCode.Name;
                    elseif Input.UserInputType == Enum.UserInputType.MouseButton1 then
                        Key = 'MB1';
                    elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then
                        Key = 'MB2';
                    end;

                    if Key == 'Escape' or Key == 'Backspace' then
                        Key = 'None';
                    end;

                    Break = true;
                    Picking = false;

                    UpdateDisplayWidth(Key);
                    KeyPicker.Value = Key;

                    Library:SafeCallback(KeyPicker.ChangedCallback, Input.KeyCode or Input.UserInputType);
                    Library:SafeCallback(KeyPicker.Changed, Input.KeyCode or Input.UserInputType);

                    Library:AttemptSave();

                    Event:Disconnect();
                end);
            elseif Input.UserInputType == Enum.UserInputType.MouseButton2 and not Library:MouseIsOverOpenedFrame() then
                ModeSelectOuter.Visible = true;
            end;
        end);

        Library:GiveSignal(InputService.InputBegan:Connect(function(Input)
            if (not Picking) then
                if KeyPicker.Mode == 'Toggle' then
                    local Key = KeyPicker.Value;

                    if Key == 'MB1' or Key == 'MB2' then
                        if Key == 'MB1' and IsPrimaryPress(Input)
                        or Key == 'MB2' and Input.UserInputType == Enum.UserInputType.MouseButton2 then
                            KeyPicker.Toggled = not KeyPicker.Toggled;
                            KeyPicker:DoClick();
                        end;
                    elseif Input.UserInputType == Enum.UserInputType.Keyboard then
                        if Input.KeyCode.Name == Key then
                            KeyPicker.Toggled = not KeyPicker.Toggled;
                            KeyPicker:DoClick();
                        end;
                    end;
                end;

                KeyPicker:Update();
            end;

            if IsPrimaryPress(Input) then
                local Pos = GetPointerPosition(Input);
                local AbsPos, AbsSize = ModeSelectOuter.AbsolutePosition, ModeSelectOuter.AbsoluteSize;

                if Pos.X < AbsPos.X or Pos.X > AbsPos.X + AbsSize.X
                    or Pos.Y < (AbsPos.Y - 20 - 1) or Pos.Y > AbsPos.Y + AbsSize.Y then

                    ModeSelectOuter.Visible = false;
                end;
            end;
        end));

        Library:GiveSignal(InputService.InputEnded:Connect(function(Input)
            if (not Picking) then
                KeyPicker:Update();
            end;
        end));

        KeyPicker:Update();

        if type(KeyPicker)=="table" and KeyPicker.SetVisible==nil then KeyPicker.SetVisible=function() end end;
        Options[Idx] = KeyPicker;

        return self;
    end;

    BaseAddons.__index = Funcs;
    BaseAddons.__namecall = function(Table, Key, ...)
        return Funcs[Key](Table, ...);
    end;
end;

BaseGroupbox = {};

do
    local Funcs = {};

    local function Z(Groupbox, Layer)
        return (Groupbox.ContentBaseZIndex or 10) + Layer;
    end;

    function Funcs:AddBlank(Size)
        local Groupbox = self;
        local Container = Groupbox.Container;

        Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, 0, 0, Size);
            ZIndex = Z(Groupbox, 1);
            Parent = Container;
        });
    end;

    function Funcs:AddLabel(Text, DoesWrap)
        local Label = {};

        local Groupbox = self;
        local Container = Groupbox.Container;

        local TextLabel = Library:CreateLabel({
            Size = UDim2.new(1, -4, 0, 15);
            TextSize = 14;
            Text = Text;
            TextWrapped = DoesWrap or false,
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = Z(self, 5);
            Parent = Container;
        });

        if DoesWrap then
            local Y = select(2, Library:GetTextBounds(Text, Library.Font, 14, Vector2.new(TextLabel.AbsoluteSize.X, math.huge)));
            TextLabel.Size = UDim2.new(1, -4, 0, Y);
        else
            Library:Create('UIListLayout', {
                Padding = UDim.new(0, 4);
                FillDirection = Enum.FillDirection.Horizontal;
                HorizontalAlignment = Enum.HorizontalAlignment.Right;
                SortOrder = Enum.SortOrder.LayoutOrder;
                Parent = TextLabel;
            });
        end;

        Label.TextLabel = TextLabel;
        Label.Container = Container;

        function Label:SetText(Text)
            TextLabel.Text = Text;

            if DoesWrap then
                local Y = select(2, Library:GetTextBounds(Text, Library.Font, 14, Vector2.new(TextLabel.AbsoluteSize.X, math.huge)));
                TextLabel.Size = UDim2.new(1, -4, 0, Y);
            end;

            Groupbox:Resize();
        end;

        if (not DoesWrap) then
            setmetatable(Label, BaseAddons);
        end;

        Groupbox:AddBlank(5);
        Groupbox:Resize();

        return Label;
    end;

    function Funcs:AddButton(...)
        local Button = {};
        local function ProcessButtonParams(Class, Obj, ...)
            local Props = select(1, ...);
            if type(Props) == 'table' then
                Obj.Text = Props.Text;
                Obj.Func = Props.Func;
                Obj.DoubleClick = Props.DoubleClick;
                Obj.Tooltip = Props.Tooltip;
            else
                Obj.Text = select(1, ...);
                Obj.Func = select(2, ...);
            end;

            assert(type(Obj.Func) == 'function', 'AddButton: `Func` callback is missing.');
        end;

        ProcessButtonParams('Button', Button, ...);

        local Groupbox = self;
        local Container = Groupbox.Container;

        local function CreateBaseButton(Button)
            local Outer = Library:Create('Frame', {
                BackgroundColor3 = Color3.new(0, 0, 0);
                BorderColor3 = Color3.new(0, 0, 0);
                Size = UDim2.new(1, -4, 0, 20);
                ZIndex = Z(self, 5);
            });

            local Inner = Library:Create('Frame', {
                BackgroundColor3 = Library.MainColor;
                BorderColor3 = Library.OutlineColor;
                BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.new(1, 0, 1, 0);
                ZIndex = Z(self, 6);
                Parent = Outer;
            });

            local Label = Library:CreateLabel({
                Size = UDim2.new(1, 0, 1, 0);
                TextSize = 14;
                Text = Button.Text;
                ZIndex = Z(self, 6);
                Parent = Inner;
            });

            Library:Create('UIGradient', {
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))
                });
                Rotation = 90;
                Parent = Inner;
            });

            Library:AddToRegistry(Outer, {
                BorderColor3 = 'Black';
            });

            Library:AddToRegistry(Inner, {
                BackgroundColor3 = 'MainColor';
                BorderColor3 = 'OutlineColor';
            });

            Library:OnHighlight(Outer, Outer,
                { BorderColor3 = 'AccentColor' },
                { BorderColor3 = 'Black' }
            );

            return Outer, Inner, Label;
        end;

        local function InitEvents(Button)
            local function WaitForEvent(event, timeout, validator)
                local bindable = Instance.new('BindableEvent');
                local connection = event:Once(function(...)

                    if type(validator) == 'function' and validator(...) then
                        bindable:Fire(true);
                    else
                        bindable:Fire(false);
                    end;
                end);
                task.delay(timeout, function()
                    connection:disconnect();
                    bindable:Fire(false);
                end);
                return bindable.Event:Wait();
            end;

            local function ValidateClick(Input)
                if Library:MouseIsOverOpenedFrame() then
                    return false;
                end;

                return Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch;
            end;

            Button.Outer.InputBegan:Connect(function(Input)
                if not ValidateClick(Input) then return end;
                if Button.Locked then return end;

                if Button.DoubleClick then
                    Library:RemoveFromRegistry(Button.Label);
                    Library:AddToRegistry(Button.Label, { TextColor3 = 'AccentColor' });

                    Button.Label.TextColor3 = Library.AccentColor;
                    Button.Label.Text = 'Are you sure?';
                    Button.Locked = true;

                    local clicked = WaitForEvent(Button.Outer.InputBegan, 0.5, ValidateClick);

                    Library:RemoveFromRegistry(Button.Label);
                    Library:AddToRegistry(Button.Label, { TextColor3 = 'FontColor' });

                    Button.Label.TextColor3 = Library.FontColor;
                    Button.Label.Text = Button.Text;
                    task.defer(rawset, Button, 'Locked', false);

                    if clicked then
                        Library:SafeCallback(Button.Func);
                    end;

                    return
                end;

                Library:SafeCallback(Button.Func);
            end);
        end;

        Button.Outer, Button.Inner, Button.Label = CreateBaseButton(Button);
        Button.Outer.Parent = Container;

        InitEvents(Button);

        function Button:AddTooltip(tooltip)
            if type(tooltip) == 'string' then
                Library:AddToolTip(tooltip, self.Outer);
            end;
            return self;
        end;

        function Button:SetText(text)
            self.Text = text;
            self.Label.Text = text;
            return self;
        end;

        function Button:AddButton(...)
            local SubButton = {};

            ProcessButtonParams('SubButton', SubButton, ...);

            self.Outer.Size = UDim2.new(0.5, -2, 0, 20);

            SubButton.Outer, SubButton.Inner, SubButton.Label = CreateBaseButton(SubButton);

            SubButton.Outer.Position = UDim2.new(1, 3, 0, 0);
            SubButton.Outer.Size = UDim2.fromOffset(self.Outer.AbsoluteSize.X - 2, self.Outer.AbsoluteSize.Y);
            SubButton.Outer.Parent = self.Outer;

            function SubButton:AddTooltip(tooltip)
                if type(tooltip) == 'string' then
                    Library:AddToolTip(tooltip, self.Outer);
                end;
                return SubButton;
            end;

            function SubButton:SetText(text)
                self.Text = text;
                self.Label.Text = text;
                return self;
            end;

            if type(SubButton.Tooltip) == 'string' then
                SubButton:AddTooltip(SubButton.Tooltip);
            end;

            InitEvents(SubButton);
            return SubButton;
        end;

        if type(Button.Tooltip) == 'string' then
            Button:AddTooltip(Button.Tooltip);
        end;

        Groupbox:AddBlank(5);
        Groupbox:Resize();

        return Button;
    end;

    function Funcs:AddDivider()
        local Groupbox = self;
        local Container = self.Container;

        local Divider = {
            Type = 'Divider',
        };

        Groupbox:AddBlank(2);
        local DividerOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(1, -4, 0, 5);
            ZIndex = Z(self, 5);
            Parent = Container;
        });

        local DividerInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = Z(self, 6);
            Parent = DividerOuter;
        });

        Library:AddToRegistry(DividerOuter, {
            BorderColor3 = 'Black';
        });

        Library:AddToRegistry(DividerInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });

        Groupbox:AddBlank(9);
        Groupbox:Resize();
    end;

    function Funcs:AddInput(Idx, Info)
        assert(Info.Text, 'AddInput: Missing `Text` string.');

        local Textbox = {
            Value = Info.Default or '';
            Numeric = Info.Numeric or false;
            Finished = Info.Finished or false;
            Type = 'Input';
            Callback = Info.Callback or function(Value) end;
        };

        local Groupbox = self;
        local Container = Groupbox.Container;

        if not Info.NoLabel then
            Library:CreateLabel({
                Size = UDim2.new(1, 0, 0, 15);
                TextSize = 14;
                Text = Info.Text;
                TextXAlignment = Enum.TextXAlignment.Left;
                ZIndex = Z(self, 5);
                Parent = Container;
            });

            Groupbox:AddBlank(1);
        end;

        local TextBoxOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(1, -4, 0, 20);
            ZIndex = Z(self, 5);
            Parent = Container;
        });

        local TextBoxInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = Z(self, 6);
            Parent = TextBoxOuter;
        });

        Library:AddToRegistry(TextBoxInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });

        Library:OnHighlight(TextBoxOuter, TextBoxOuter,
            { BorderColor3 = 'AccentColor' },
            { BorderColor3 = 'Black' }
        );

        if type(Info.Tooltip) == 'string' then
            Library:AddToolTip(Info.Tooltip, TextBoxOuter);
        end;

        Library:Create('UIGradient', {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))
            });
            Rotation = 90;
            Parent = TextBoxInner;
        });

        local Container = Library:Create('Frame', {
            BackgroundTransparency = 1;

            Position = UDim2.new(0, 5, 0, 2);
            Size = UDim2.new(1, -10, 1, -4);

            ZIndex = Z(self, 7);
            Parent = TextBoxInner;
        });

        local Box = Library:Create('TextBox', {
            BackgroundTransparency = 1;

            Position = UDim2.fromOffset(0, 0),
            Size = UDim2.fromScale(5, 1),

            Font = Library.Font;
            PlaceholderColor3 = Color3.fromRGB(120, 120, 120);
            PlaceholderText = Info.Placeholder or '';

            Text = Info.Default or '';
            TextColor3 = Library.FontColor;
            TextSize = 14;
            TextStrokeTransparency = 1;
            TextTransparency = 1;
            ClearTextOnFocus = false;
            TextXAlignment = Enum.TextXAlignment.Left;

            ZIndex = Z(self, 7);
            Parent = Container;
        });

        local TextOverlay = Library:CreateLabel({
            BackgroundTransparency = 1;
            Position = UDim2.fromOffset(0, 0),
            Size = UDim2.fromScale(5, 1),
            Font = Library.Font;
            TextColor3 = Library.FontColor;
            TextSize = 14;
            TextStrokeTransparency = 0;
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = Z(self, 7);
            Parent = Container;
        });

        Box:GetPropertyChangedSignal('Position'):Connect(function()
            TextOverlay.Position = Box.Position;
        end);

        local CustomCaret = Library:Create('Frame', {
            BackgroundColor3 = Library.AccentColor;
            BorderSizePixel = 0;
            Size = UDim2.new(0, 2, 1, -4);
            Position = UDim2.fromOffset(2, 2);
            ZIndex = Z(self, 9);
            Visible = false;
            Parent = Container;
        });

        Library:AddToRegistry(CustomCaret, {
            BackgroundColor3 = 'AccentColor';
        });

        local CaretBlinkTween;
        local CaretBlinkConnection;
        local LastTextLength = #(Info.Default or '');
        local TextAnimTween;

        local function StopCaretBlink()
            if CaretBlinkTween then
                CaretBlinkTween:Cancel();
                CaretBlinkTween = nil;
            end;

            if CaretBlinkConnection then
                CaretBlinkConnection:Disconnect();
                CaretBlinkConnection = nil;
            end;

            CustomCaret.BackgroundTransparency = 0;
        end;

        local function StartCaretBlink()
            StopCaretBlink();

            CaretBlinkConnection = RunService.RenderStepped:Connect(LPH_NO_VIRTUALIZE(function()
                if not Box:IsFocused() then
                    StopCaretBlink();
                end;
            end));

            local function Blink()
                if not Box:IsFocused() then
                    return
                end;

                CaretBlinkTween = TweenService:Create(CustomCaret, TweenInfo.new(0.45, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                    BackgroundTransparency = 0.55,
                });

                CaretBlinkTween:Play();
                CaretBlinkTween.Completed:Connect(function()
                    if Box:IsFocused() then
                        CaretBlinkTween = TweenService:Create(CustomCaret, TweenInfo.new(0.45, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                            BackgroundTransparency = 0,
                        });
                        CaretBlinkTween:Play();
                        CaretBlinkTween.Completed:Connect(Blink);
                    end;
                end);
            end;

            Blink();
        end;

        local function PlayTextEntryAnimation()
            if TextAnimTween then
                TextAnimTween:Cancel();
            end;

            TextOverlay.TextTransparency = 0.45;
            TextOverlay.Position = UDim2.new(Box.Position.X.Scale, Box.Position.X.Offset, 0, -2);

            TextAnimTween = TweenService:Create(TextOverlay, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                TextTransparency = 0,
                Position = Box.Position,
            });
            TextAnimTween:Play();
        end;

        function Textbox:SetValue(Text)
            if Info.MaxLength and #Text > Info.MaxLength then
                Text = Text:sub(1, Info.MaxLength);
            end;

            if Textbox.Numeric then
                if (not tonumber(Text)) and Text:len() > 0 then
                    Text = Textbox.Value;
                end;
            end;

            Textbox.Value = Text;
            Box.Text = Text;
            LastTextLength = #Text;

            Library:SafeCallback(Textbox.Callback, Textbox.Value);
            Library:SafeCallback(Textbox.Changed, Textbox.Value);
        end;

        if Textbox.Finished then
            Box.FocusLost:Connect(function(enter)
                Textbox:SetValue(Box.Text);
                Library:AttemptSave();
            end);
        else
            Box:GetPropertyChangedSignal('Text'):Connect(function()
                Textbox:SetValue(Box.Text);
                Library:AttemptSave();
            end);
        end;

        local function Update()
            local PADDING = 2;
            local reveal = Container.AbsoluteSize.X;

            if Box.Text == "" then
                TextOverlay.Text = Box.PlaceholderText;
                TextOverlay.TextColor3 = Box.PlaceholderColor3;
            else
                TextOverlay.Text = Box.Text;
                TextOverlay.TextColor3 = Library.FontColor;
            end;

            if not Box:IsFocused() or Box.TextBounds.X <= reveal - 2 * PADDING then
                TweenService:Create(Box, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Position = UDim2.new(0, PADDING, 0, 0)
                }):Play();
            else
                local cursor = Box.CursorPosition;
                if cursor ~= -1 then
                    local subtext = string.sub(Box.Text, 1, cursor-1);
                    local width = TextService:GetTextSize(subtext, Box.TextSize, Box.Font, Vector2.new(math.huge, math.huge)).X;
                    local currentCursorPos = Box.Position.X.Offset + width;

                    local targetX = Box.Position.X.Offset;
                    if currentCursorPos < PADDING then
                        targetX = PADDING-width;
                    elseif currentCursorPos > reveal - PADDING - 1 then
                        targetX = reveal-width-PADDING-1;
                    end;

                    TweenService:Create(Box, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        Position = UDim2.fromOffset(targetX, 0)
                    }):Play();
                end;
            end;

            if Box:IsFocused() then
                CustomCaret.Visible = true;
                local cursor = Box.CursorPosition;
                if cursor ~= -1 then
                    local subtext = string.sub(Box.Text, 1, cursor-1);
                    local width = TextService:GetTextSize(subtext, Box.TextSize, Box.Font, Vector2.new(math.huge, math.huge)).X;
                    local caretTargetX = Box.Position.X.Offset + width + 1;
                    TweenService:Create(CustomCaret, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        Position = UDim2.fromOffset(math.clamp(caretTargetX, PADDING, reveal - PADDING), 2)
                    }):Play();
                else
                    CustomCaret.Visible = false;
                end;
            else
                CustomCaret.Visible = false;
                StopCaretBlink();
            end;
        end;

        local function OnTextChanged()
            local newLength = #Box.Text;
            if Box:IsFocused() and newLength > LastTextLength then
                PlayTextEntryAnimation();
            end;
            LastTextLength = newLength;
            Update();
        end;

        task.spawn(Update);

        Box:GetPropertyChangedSignal('Text'):Connect(OnTextChanged);
        Box:GetPropertyChangedSignal('CursorPosition'):Connect(Update);
        Box.FocusLost:Connect(function()
            StopCaretBlink();
            Update();
        end);
        Box.Focused:Connect(function()
            StartCaretBlink();
            Update();
        end);

        Library:AddToRegistry(Box, {
            TextColor3 = 'FontColor';
        });

        function Textbox:OnChanged(Func)
            Textbox.Changed = Func;
            Func(Textbox.Value);
        end;

        Groupbox:AddBlank(5);
        Groupbox:Resize();

        if type(Textbox)=="table" and Textbox.SetVisible==nil then Textbox.SetVisible=function() end end;
        Options[Idx] = Textbox;

        return Textbox;
    end;

    function Funcs:AddToggle(Idx, Info)
        assert(Info.Text, 'AddInput: Missing `Text` string.');

        local Toggle = {
            Value = Info.Default or false;
            Type = 'Toggle';

            Callback = Info.Callback or function(Value) end;
            Addons = {},
            Risky = Info.Risky,
        };

        local Groupbox = self;
        local Container = Groupbox.Container;

        local ToggleOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(0, 13, 0, 13);
            ZIndex = Z(self, 5);
            Parent = Container;
        });

        Library:AddToRegistry(ToggleOuter, {
            BorderColor3 = 'Black';
        });

        local ToggleInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = Z(self, 6);
            Parent = ToggleOuter;
        });

        Library:AddToRegistry(ToggleInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });

        local ToggleLabel = Library:CreateLabel({
            Size = UDim2.new(0, 216, 1, 0);
            Position = UDim2.new(1, 6, 0, 0);
            TextSize = 14;
            Text = Info.Text;
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = Z(self, 6);
            Parent = ToggleInner;
        });

        local function UpdateToggleLabelWidth()
            local available = Container.AbsoluteSize.X / Library:GetUIScaleFactor(Container) - (ToggleOuter.Size.X.Offset + 6) - 4;
            ToggleLabel.Size = UDim2.new(0, math.max(available, 60), 1, 0);
        end;

        Container:GetPropertyChangedSignal('AbsoluteSize'):Connect(UpdateToggleLabelWidth);
        task.spawn(UpdateToggleLabelWidth);

        Library:Create('UIListLayout', {
            Padding = UDim.new(0, 4);
            FillDirection = Enum.FillDirection.Horizontal;
            HorizontalAlignment = Enum.HorizontalAlignment.Right;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = ToggleLabel;
        });

        local ToggleRegion = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(0, 170, 1, 0);
            ZIndex = Z(self, 8);
            Parent = ToggleOuter;
        });

        Library:OnHighlight(ToggleRegion, ToggleOuter,
            { BorderColor3 = 'AccentColor' },
            { BorderColor3 = 'Black' }
        );

        function Toggle:UpdateColors()
            Toggle:Display();
        end;

        if type(Info.Tooltip) == 'string' then
            Library:AddToolTip(Info.Tooltip, ToggleRegion);
        end;

        function Toggle:Display()
            if Toggle.BgTween then Toggle.BgTween:Cancel() end;
            if Toggle.BorderTween then Toggle.BorderTween:Cancel() end;

            local targetBg = Toggle.Value and Library.AccentColor or Library.MainColor;
            local targetBorder = Toggle.Value and Library.AccentColorDark or Library.OutlineColor;

            local tweenInfo = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);
            Toggle.BgTween = TweenService:Create(ToggleInner, tweenInfo, { BackgroundColor3 = targetBg });
            Toggle.BorderTween = TweenService:Create(ToggleInner, tweenInfo, { BorderColor3 = targetBorder });

            Toggle.BgTween:Play();
            Toggle.BorderTween:Play();

            Library.RegistryMap[ToggleInner].Properties.BackgroundColor3 = Toggle.Value and 'AccentColor' or 'MainColor';
            Library.RegistryMap[ToggleInner].Properties.BorderColor3 = Toggle.Value and 'AccentColorDark' or 'OutlineColor';
        end;

        function Toggle:OnChanged(Func)
            Toggle.Changed = Func;
            Func(Toggle.Value);
        end;

        function Toggle:SetValue(Bool)
            Bool = (not not Bool);

            Toggle.Value = Bool;
            Toggle:Display();

            for _, Addon in next, Toggle.Addons do
                if Addon.Type == 'KeyPicker' and Addon.SyncToggleState then
                    Addon.Toggled = Bool;
                    Addon:Update();
                end;
            end;

            Library:SafeCallback(Toggle.Callback, Toggle.Value);
            Library:SafeCallback(Toggle.Changed, Toggle.Value);
            Library:UpdateDependencyBoxes();
        end;

        ToggleRegion.InputBegan:Connect(function(Input)
            if IsPrimaryPress(Input) and not Library:MouseIsOverOpenedFrame() then
                Library:PlayToggleSound();
                Toggle:SetValue(not Toggle.Value);
                Library:AttemptSave();
            end;
        end);

        if Toggle.Risky then
            Library:RemoveFromRegistry(ToggleLabel);
            ToggleLabel.TextColor3 = Library.RiskColor;
            Library:AddToRegistry(ToggleLabel, { TextColor3 = 'RiskColor' });
        end;

        Toggle:Display();
        Groupbox:AddBlank(Info.BlankSize or 5 + 2);
        Groupbox:Resize();

        Toggle.TextLabel = ToggleLabel;
        Toggle.Container = Container;
        setmetatable(Toggle, BaseAddons);

        if type(Toggle)=="table" and Toggle.SetVisible==nil then Toggle.SetVisible=function() end end;
        Toggles[Idx] = Toggle;

        Library:UpdateDependencyBoxes();

        return Toggle;
    end;

    function Funcs:AddSlider(Idx, Info)
        assert(Info.Default, 'AddSlider: Missing default value.');
        assert(Info.Text, 'AddSlider: Missing slider text.');
        assert(Info.Min, 'AddSlider: Missing minimum value.');
        assert(Info.Max, 'AddSlider: Missing maximum value.');
        assert(Info.Rounding, 'AddSlider: Missing rounding value.');

        local Slider = {
            Value = Info.Default;
            Min = Info.Min;
            Max = Info.Max;
            Rounding = math.clamp(Info.Rounding or 0, 0, 3);
            Type = 'Slider';
            Callback = Info.Callback or function(Value) end;
        };

        local Groupbox = self;
        local Container = Groupbox.Container;

        if not Info.Compact then
            Library:CreateLabel({
                Size = UDim2.new(1, 0, 0, 10);
                TextSize = 14;
                Text = Info.Text;
                TextXAlignment = Enum.TextXAlignment.Left;
                TextYAlignment = Enum.TextYAlignment.Bottom;
                ZIndex = Z(self, 5);
                Parent = Container;
            });

            Groupbox:AddBlank(3);
        end;

        local SliderContainer = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, -4, 0, 13);
            ZIndex = Z(self, 5);
            Parent = Container;
        });

        local DecrementBtn = Library:Create('TextButton', {
            BackgroundTransparency = 1;
            Position = UDim2.new(0, 0, 0, -1);
            Size = UDim2.new(0, 12, 1, 0);
            Font = Library.Font;
            Text = "-";
            TextColor3 = Library.FontColor;
            TextSize = 14;
            TextYAlignment = Enum.TextYAlignment.Center;
            ZIndex = Z(self, 8);
            Parent = SliderContainer;
        });

        local IncrementBtn = Library:Create('TextButton', {
            BackgroundTransparency = 1;
            Position = UDim2.new(1, -12, 0, -1);
            Size = UDim2.new(0, 12, 1, 0);
            Font = Library.Font;
            Text = "+";
            TextColor3 = Library.FontColor;
            TextSize = 14;
            TextYAlignment = Enum.TextYAlignment.Center;
            ZIndex = Z(self, 8);
            Parent = SliderContainer;
        });

        Library:OnHighlight(DecrementBtn, DecrementBtn,
            { TextColor3 = 'AccentColor' },
            { TextColor3 = 'FontColor' }
        );

        Library:OnHighlight(IncrementBtn, IncrementBtn,
            { TextColor3 = 'AccentColor' },
            { TextColor3 = 'FontColor' }
        );

        local SliderOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.new(0, 16, 0, 0);
            Size = UDim2.new(1, -32, 0, 13);
            ZIndex = Z(self, 5);
            Parent = SliderContainer;
        });

        Library:AddToRegistry(SliderOuter, {
            BorderColor3 = 'Black';
        });

        local SliderInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = Z(self, 6);
            Parent = SliderOuter;
        });

        function Slider:GetBarWidth()
            return math.max(SliderInner.AbsoluteSize.X, 1);
        end;

        Library:AddToRegistry(SliderInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });

        local Fill = Library:Create('Frame', {
            BackgroundColor3 = Library.AccentColor;
            BorderColor3 = Library.AccentColorDark;
            Size = UDim2.new(0, 0, 1, 0);
            ZIndex = Z(self, 7);
            Parent = SliderInner;
        });

        Library:AddToRegistry(Fill, {
            BackgroundColor3 = 'AccentColor';
            BorderColor3 = 'AccentColorDark';
        });

        local HideBorderRight = Library:Create('Frame', {
            BackgroundColor3 = Library.AccentColor;
            BorderSizePixel = 0;
            Position = UDim2.new(1, 0, 0, 0);
            Size = UDim2.new(0, 1, 1, 0);
            ZIndex = Z(self, 8);
            Parent = Fill;
        });

        Library:AddToRegistry(HideBorderRight, {
            BackgroundColor3 = 'AccentColor';
        });

        local DisplayLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 1, 0);
            TextSize = 14;
            Text = 'Infinite';
            ZIndex = Z(self, 9);
            Parent = SliderInner;
        });

        Library:OnHighlight(SliderOuter, SliderOuter,
            { BorderColor3 = 'AccentColor' },
            { BorderColor3 = 'Black' }
        );

        if type(Info.Tooltip) == 'string' then
            Library:AddToolTip(Info.Tooltip, SliderOuter);
        end;

        function Slider:UpdateColors()
            Fill.BackgroundColor3 = Library.AccentColor;
            Fill.BorderColor3 = Library.AccentColorDark;
        end;

        function Slider:Display()
            local Suffix = Info.Suffix or "";

            if Info.Compact then
                DisplayLabel.Text = Info.Text .. ": " .. Slider.Value .. Suffix;
            elseif Info.HideMax then
                DisplayLabel.Text = tostring(Slider.Value) .. Suffix;
            else
                DisplayLabel.Text = ("%s/%s"):format(Slider.Value .. Suffix, Slider.Max .. Suffix);
            end;

            local Width = Slider:GetBarWidth();

            local X = math.clamp(
                math.round(
                    Library:MapValue(
                        Slider.Value,
                        Slider.Min,
                        Slider.Max,
                        0,
                        Width
                    )
                ),
                0,
                Width
            );

            if Slider.Tween then
                Slider.Tween:Cancel();
            end;

            Slider.Tween = TweenService:Create(
                Fill,
                TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {
                    Size = UDim2.new(0, X, 1, 0)
                }
            );

            Slider.Tween:Play();

            HideBorderRight.Visible = X > 0 and X < Width;
        end;

        function Slider:OnChanged(Func)
            Slider.Changed = Func;
            Func(Slider.Value);
        end;

        local function Round(Value)
            if Slider.Rounding == 0 then
                return math.floor(Value + 0.5);
            end;

            return tonumber(string.format('%.' .. Slider.Rounding .. 'f', Value));
        end;

        function Slider:GetValueFromXOffset(X)
            return Round(
                Library:MapValue(
                    X,
                    0,
                    Slider:GetBarWidth(),
                    Slider.Min,
                    Slider.Max
                )
            );
        end;

        function Slider:SetValue(Str)
            local Num = tonumber(Str);

            if (not Num) then
                return;
            end;

            Num = math.clamp(Num, Slider.Min, Slider.Max);

            Slider.Value = Round(Num);
            Slider:Display();

            Library:SafeCallback(Slider.Callback, Slider.Value);
            Library:SafeCallback(Slider.Changed, Slider.Value);
        end;

        SliderInner.InputBegan:Connect(function(Input)
            if IsPrimaryPress(Input) and not Library:MouseIsOverOpenedFrame() then
                local mPos = GetPointerPosition(Input).X;
                local gPos = Fill.Size.X.Offset;
                local Diff = mPos - (Fill.AbsolutePosition.X + gPos);

                while IsPressActive(Input) do
                    local nMPos = GetPointerPosition(Input).X;
                    local nX = math.clamp(gPos + (nMPos - mPos) + Diff, 0, Slider:GetBarWidth());

                    local nValue = Slider:GetValueFromXOffset(nX);
                    local OldValue = Slider.Value;
                    Slider.Value = nValue;

                    Slider:Display();

                    if nValue ~= OldValue then
                        Library:PlaySliderSound();
                        Library:SafeCallback(Slider.Callback, Slider.Value);
                        Library:SafeCallback(Slider.Changed, Slider.Value);
                    end;

                    RenderStepped:Wait();
                end;

                Library:StopSliderSound();
                Library:AttemptSave();
            end;
        end);

        Library:BindHoldButton(DecrementBtn, function()
            local step = 10 ^ -Slider.Rounding;
            local OldValue = Slider.Value;
            Slider:SetValue(Slider.Value - step);
            if Slider.Value ~= OldValue then
                Library:PlaySliderSound();
            end;
            Library:AttemptSave();
        end);

        Library:BindHoldButton(IncrementBtn, function()
            local step = 10 ^ -Slider.Rounding;
            local OldValue = Slider.Value;
            Slider:SetValue(Slider.Value + step);
            if Slider.Value ~= OldValue then
                Library:PlaySliderSound();
            end;
            Library:AttemptSave();
        end);

        SliderInner:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
            Slider:Display();
        end);

        Slider:Display();
        Groupbox:AddBlank(Info.BlankSize or 6);
        Groupbox:Resize();

        if type(Slider)=="table" and Slider.SetVisible==nil then Slider.SetVisible=function() end end;
        Options[Idx] = Slider;

        return Slider;
    end;

    function Funcs:AddRangeSlider(Idx, Info)
        assert(Info.DefaultLower, 'AddRangeSlider: Missing default lower value.');
        assert(Info.DefaultUpper, 'AddRangeSlider: Missing default upper value.');
        assert(Info.Text, 'AddRangeSlider: Missing slider text.');
        assert(Info.Min, 'AddRangeSlider: Missing minimum value.');
        assert(Info.Max, 'AddRangeSlider: Missing maximum value.');
        assert(Info.Rounding, 'AddRangeSlider: Missing rounding value.');

        local Slider = {
            ValueLower = Info.DefaultLower;
            ValueUpper = Info.DefaultUpper;
            Min = Info.Min;
            Max = Info.Max;
            Rounding = math.clamp(Info.Rounding or 0, 0, 3);
            MaxSize = 200;
            Type = 'RangeSlider';
            Callback = Info.Callback or function(Lower, Upper) end;
        };

        Slider.Value = { Slider.ValueLower, Slider.ValueUpper };

        local Groupbox = self;
        local Container = Groupbox.Container;

        if not Info.Compact then
            Library:CreateLabel({
                Size = UDim2.new(1, 0, 0, 10);
                TextSize = 14;
                Text = Info.Text;
                TextXAlignment = Enum.TextXAlignment.Left;
                TextYAlignment = Enum.TextYAlignment.Bottom;
                ZIndex = Z(self, 5);
                Parent = Container;
            });

            Groupbox:AddBlank(3);
        end;

        local SliderContainer = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, -4, 0, 13);
            ZIndex = Z(self, 5);
            Parent = Container;
        });

        local SliderOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.new(0, 4, 0, 0);
            Size = UDim2.new(1, -8, 0, 13);
            ZIndex = Z(self, 5);
            Parent = SliderContainer;
        });

        Library:AddToRegistry(SliderOuter, {
            BorderColor3 = 'Black';
        });

        local SliderInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = Z(self, 6);
            Parent = SliderOuter;
        });

        Library:AddToRegistry(SliderInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });

        local Fill = Library:Create('Frame', {
            BackgroundColor3 = Library.AccentColor;
            BorderSizePixel = 0;
            ZIndex = Z(self, 7);
            Parent = SliderInner;
        });

        Library:AddToRegistry(Fill, {
            BackgroundColor3 = 'AccentColor';
        });

        local HeadLower = Library:Create('Frame', {
            BackgroundColor3 = Color3.fromRGB(200, 200, 200);
            BorderColor3 = Color3.fromRGB(0, 0, 0);
            Size = UDim2.new(0, 3, 1, 2);
            Position = UDim2.new(0, 0, 0, -1);
            ZIndex = Z(self, 8);
            Parent = SliderInner;
        });

        local HeadUpper = Library:Create('Frame', {
            BackgroundColor3 = Color3.fromRGB(200, 200, 200);
            BorderColor3 = Color3.fromRGB(0, 0, 0);
            Size = UDim2.new(0, 3, 1, 2);
            Position = UDim2.new(0, 0, 0, -1);
            ZIndex = Z(self, 8);
            Parent = SliderInner;
        });

        local DisplayLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 1, 0);
            TextSize = 14;
            ZIndex = Z(self, 9);
            Parent = SliderInner;
        });

        Library:OnHighlight(SliderOuter, SliderOuter,
            { BorderColor3 = 'AccentColor' },
            { BorderColor3 = 'Black' }
        );

        if type(Info.Tooltip) == 'string' then
            Library:AddToolTip(Info.Tooltip, SliderOuter);
        end;

        local function Round(Value)
            if Slider.Rounding == 0 then
                return math.floor(Value + 0.5);
            end;
            return tonumber(string.format('%.' .. Slider.Rounding .. 'f', Value));
        end;

        function Slider:Display()
            local Suffix = Info.Suffix or '';
            DisplayLabel.Text = string.format('%s%s - %s%s', tostring(Slider.ValueLower), Suffix, tostring(Slider.ValueUpper), Suffix);

            local barWidth = SliderInner.AbsoluteSize.X > 0 and SliderInner.AbsoluteSize.X or 222;
            local xLower = Library:MapValue(Slider.ValueLower, Slider.Min, Slider.Max, 0, barWidth);
            local xUpper = Library:MapValue(Slider.ValueUpper, Slider.Min, Slider.Max, 0, barWidth);

            if Slider.TweenFill then Slider.TweenFill:Cancel() end;
            if Slider.TweenHeadLower then Slider.TweenHeadLower:Cancel() end;
            if Slider.TweenHeadUpper then Slider.TweenHeadUpper:Cancel() end;

            local tInfo = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);
            Slider.TweenFill = TweenService:Create(Fill, tInfo, {
                Position = UDim2.new(0, xLower, 0, 0),
                Size = UDim2.new(0, xUpper - xLower, 1, 0)
            });
            Slider.TweenHeadLower = TweenService:Create(HeadLower, tInfo, {
                Position = UDim2.new(0, xLower - 1, 0, -1)
            });
            Slider.TweenHeadUpper = TweenService:Create(HeadUpper, tInfo, {
                Position = UDim2.new(0, xUpper - 1, 0, -1)
            });

            Slider.TweenFill:Play();
            Slider.TweenHeadLower:Play();
            Slider.TweenHeadUpper:Play();
        end;

        function Slider:UpdateColors()
            Fill.BackgroundColor3 = Library.AccentColor;
        end;

        function Slider:OnChanged(Func)
            Slider.Changed = Func;
            Func(Slider.ValueLower, Slider.ValueUpper);
        end;

        function Slider:GetValueFromXOffset(X)
            local barWidth = SliderInner.AbsoluteSize.X > 0 and SliderInner.AbsoluteSize.X or 222;
            return Round(Library:MapValue(X, 0, barWidth, Slider.Min, Slider.Max));
        end;

        function Slider:SetValue(Lower, Upper)
            local numLower = tonumber(Lower) or Slider.ValueLower;
            local numUpper = tonumber(Upper) or Slider.ValueUpper;

            numLower = math.clamp(numLower, Slider.Min, Slider.Max);
            numUpper = math.clamp(numUpper, Slider.Min, Slider.Max);

            if numLower > numUpper then
                numLower = numUpper;
            end;

            Slider.ValueLower = Round(numLower);
            Slider.ValueUpper = Round(numUpper);
            Slider.Value = { Slider.ValueLower, Slider.ValueUpper };

            Slider:Display();

            Library:SafeCallback(Slider.Callback, Slider.ValueLower, Slider.ValueUpper);
            Library:SafeCallback(Slider.Changed, Slider.ValueLower, Slider.ValueUpper);
        end;

        SliderInner.InputBegan:Connect(function(Input)
            if IsPrimaryPress(Input) and not Library:MouseIsOverOpenedFrame() then
                local relativeX = GetPointerPosition(Input).X - SliderInner.AbsolutePosition.X;
                local clickValue = Slider:GetValueFromXOffset(relativeX);

                local distToLower = math.abs(clickValue - Slider.ValueLower);
                local distToUpper = math.abs(clickValue - Slider.ValueUpper);
                local activeHead = (distToLower < distToUpper) and "Lower" or "Upper";

                while IsPressActive(Input) do
                    local curRelativeX = math.clamp(GetPointerPosition(Input).X - SliderInner.AbsolutePosition.X, 0, SliderInner.AbsoluteSize.X > 0 and SliderInner.AbsoluteSize.X or 222);
                    local curVal = Slider:GetValueFromXOffset(curRelativeX);

                    local oldLower = Slider.ValueLower;
                    local oldUpper = Slider.ValueUpper;

                    if activeHead == "Lower" then
                        curVal = math.clamp(curVal, Slider.Min, Slider.ValueUpper);
                        Slider.ValueLower = curVal;
                    else
                        curVal = math.clamp(curVal, Slider.ValueLower, Slider.Max);
                        Slider.ValueUpper = curVal;
                    end;

                    Slider.Value = { Slider.ValueLower, Slider.ValueUpper };
                    Slider:Display();

                    if Slider.ValueLower ~= oldLower or Slider.ValueUpper ~= oldUpper then
                        Library:PlaySliderSound();
                        Library:SafeCallback(Slider.Callback, Slider.ValueLower, Slider.ValueUpper);
                        Library:SafeCallback(Slider.Changed, Slider.ValueLower, Slider.ValueUpper);
                    end;

                    RenderStepped:Wait();
                end;

                Library:StopSliderSound();
                Library:AttemptSave();
            end;
        end);

        SliderInner:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
            Slider:Display();
        end);

        Slider:Display();
        Groupbox:AddBlank(Info.BlankSize or 6);
        Groupbox:Resize();

        if type(Slider)=="table" and Slider.SetVisible==nil then Slider.SetVisible=function() end end;
        Options[Idx] = Slider;

        return Slider;
    end;

    function Funcs:AddDropdown(Idx, Info)
        if Info.SpecialType == 'Player' then
            Info.Values = GetPlayersString();
            Info.AllowNull = true;
        elseif Info.SpecialType == 'Team' then
            Info.Values = GetTeamsString();
            Info.AllowNull = true;
        end;

        assert(Info.Values, 'AddDropdown: Missing dropdown value list.');
        assert(Info.AllowNull or Info.Default, 'AddDropdown: Missing default value. Pass `AllowNull` as true if this was intentional.');

        if (not Info.Text) then
            Info.Compact = true;
        end;

        local Dropdown = {
            Values = Info.Values;
            Value = Info.Multi and {};
            Multi = Info.Multi;
            Type = 'Dropdown';
            SpecialType = Info.SpecialType;
            Callback = Info.Callback or function(Value) end;
        };

        local Groupbox = self;
        local Container = Groupbox.Container;

        local RelativeOffset = 0;

        if not Info.Compact then
            local DropdownLabel = Library:CreateLabel({
                Size = UDim2.new(1, 0, 0, 10);
                TextSize = 14;
                Text = Info.Text;
                TextXAlignment = Enum.TextXAlignment.Left;
                TextYAlignment = Enum.TextYAlignment.Bottom;
                ZIndex = Z(self, 5);
                Parent = Container;
            });

            Groupbox:AddBlank(3);
        end;

        for _, Element in next, Container:GetChildren() do
            if not Element:IsA('UIListLayout') then
                RelativeOffset = RelativeOffset + Element.Size.Y.Offset;
            end;
        end;

        local DropdownOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(1, -4, 0, 20);
            ZIndex = Z(self, 5);
            Parent = Container;
        });

        Library:AddToRegistry(DropdownOuter, {
            BorderColor3 = 'Black';
        });

        local DropdownInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = Z(self, 6);
            Parent = DropdownOuter;
        });

        Library:AddToRegistry(DropdownInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });

        Library:Create('UIGradient', {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))
            });
            Rotation = 90;
            Parent = DropdownInner;
        });

        local DropdownArrow = Library:CreateLabel({
            AnchorPoint = Vector2.new(1, 0.5);
            BackgroundTransparency = 1;
            Position = UDim2.new(1, -5, 0.5, 0);
            Size = UDim2.new(0, 12, 1, 0);
            Text = '+';
            TextSize = 14;
            TextXAlignment = Enum.TextXAlignment.Right;
            ZIndex = Z(self, 8);
            Parent = DropdownInner;
        });

        local ItemList = Library:CreateLabel({
            Position = UDim2.new(0, 5, 0, 0);
            Size = UDim2.new(1, -20, 1, 0);
            TextSize = 14;
            Text = '--';
            TextXAlignment = Enum.TextXAlignment.Left;
            TextWrapped = true;
            ZIndex = Z(self, 7);
            Parent = DropdownInner;
        });

        Library:OnHighlight(DropdownOuter, DropdownOuter,
            { BorderColor3 = 'AccentColor' },
            { BorderColor3 = 'Black' }
        );

        if type(Info.Tooltip) == 'string' then
            Library:AddToolTip(Info.Tooltip, DropdownOuter);
        end;

        local MAX_DROPDOWN_ITEMS = 8;

        local ListOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            ZIndex = 20;
            Visible = false;
            Parent = ScreenGui;
        });

        local function RecalculateListPosition()
            ListOuter.Position = UDim2.fromOffset(DropdownOuter.AbsolutePosition.X, DropdownOuter.AbsolutePosition.Y + DropdownOuter.Size.Y.Offset + 1);
        end;

        local function RecalculateListSize(YSize)
            local height = YSize or (MAX_DROPDOWN_ITEMS * 20 + 2);
            Dropdown.ListHeight = height;
            if ListOuter.Visible then
                ListOuter.Size = UDim2.fromOffset(DropdownOuter.AbsoluteSize.X, height);
            end;
        end;

        RecalculateListPosition();
        RecalculateListSize();

        DropdownOuter:GetPropertyChangedSignal('AbsolutePosition'):Connect(RecalculateListPosition);

        local ListInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 21;
            Parent = ListOuter;
        });

        Library:AddToRegistry(ListInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });

        local Scrolling = Library:Create('ScrollingFrame', {
            BackgroundTransparency = 1;
            BorderSizePixel = 0;
            CanvasSize = UDim2.new(0, 0, 0, 0);
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 21;
            Parent = ListInner;

            TopImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png',
            BottomImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png',

            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Library.AccentColor,
        });

        Library:AddToRegistry(Scrolling, {
            ScrollBarImageColor3 = 'AccentColor'
        });

        Library:Create('UIListLayout', {
            Padding = UDim.new(0, 0);
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = Scrolling;
        });

        function Dropdown:Display()
            local Values = Dropdown.Values;
            local Str = '';

            if Info.Multi then
                for Idx, Value in next, Values do
                    if Dropdown.Value[Value] then
                        Str = Str .. Value .. ', ';
                    end;
                end;

                Str = Str:sub(1, #Str - 2);
            else
                Str = Dropdown.Value or '';
            end;

            ItemList.Text = (Str == '' and '...' or Str);
        end;

        function Dropdown:GetActiveValues()
            if Info.Multi then
                local T = {};

                for Value, Bool in next, Dropdown.Value do
                    table.insert(T, Value);
                end;

                return T;
            else
                return Dropdown.Value and 1 or 0;
            end;
        end;

        function Dropdown:BuildDropdownList()
            local Values = Dropdown.Values;
            local Buttons = {};

            for _, Element in next, Scrolling:GetChildren() do
                if not Element:IsA('UIListLayout') then
                    Element:Destroy();
                end;
            end;

            local Count = 0;

            for Idx, Value in next, Values do
                local Table = {};

                Count = Count + 1;

                local Button = Library:Create('Frame', {
                    BackgroundColor3 = Library.MainColor;
                    BorderColor3 = Library.OutlineColor;
                    BorderMode = Enum.BorderMode.Middle;
                    Size = UDim2.new(1, -1, 0, 20);
                    ZIndex = 23;
                    Active = true,
                    Parent = Scrolling;
                });

                Library:AddToRegistry(Button, {
                    BackgroundColor3 = 'MainColor';
                    BorderColor3 = 'OutlineColor';
                });

                local ButtonLabel = Library:CreateLabel({
                    Active = false;
                    Size = UDim2.new(1, -6, 1, 0);
                    Position = UDim2.new(0, 6, 0, 0);
                    TextSize = 14;
                    Text = Value;
                    TextXAlignment = Enum.TextXAlignment.Left;
                    ZIndex = 25;
                    Parent = Button;
                });

                Library:OnHighlight(Button, Button,
                    { BorderColor3 = 'AccentColor', ZIndex = 24 },
                    { BorderColor3 = 'OutlineColor', ZIndex = 23 }
                );

                local Selected;

                if Info.Multi then
                    Selected = Dropdown.Value[Value];
                else
                    Selected = Dropdown.Value == Value;
                end;

                function Table:UpdateButton()
                    if Info.Multi then
                        Selected = Dropdown.Value[Value];
                    else
                        Selected = Dropdown.Value == Value;
                    end;

                    ButtonLabel.TextColor3 = Selected and Library.AccentColor or Library.FontColor;
                    Library.RegistryMap[ButtonLabel].Properties.TextColor3 = Selected and 'AccentColor' or 'FontColor';
                end;

                ButtonLabel.InputBegan:Connect(function(Input)
                    if IsPrimaryPress(Input) then
                        local Try = not Selected;

                        if Dropdown:GetActiveValues() == 1 and (not Try) and (not Info.AllowNull) then
                        else
                            if Info.Multi then
                                Selected = Try;

                                if Selected then
                                    Dropdown.Value[Value] = true;
                                else
                                    Dropdown.Value[Value] = nil;
                                end;
                            else
                                Selected = Try;

                                if Selected then
                                    Dropdown.Value = Value;
                                else
                                    Dropdown.Value = nil;
                                end;

                                for _, OtherButton in next, Buttons do
                                    OtherButton:UpdateButton();
                                end;
                            end;

                            Table:UpdateButton();
                            Dropdown:Display();

                            Library:SafeCallback(Dropdown.Callback, Dropdown.Value);
                            Library:SafeCallback(Dropdown.Changed, Dropdown.Value);

                            Library:UpdateDependencyBoxes();

                            Library:AttemptSave();
                        end;
                    end;
                end);

                Table:UpdateButton();
                Dropdown:Display();

                Buttons[Button] = Table;
            end;

            Scrolling.CanvasSize = UDim2.fromOffset(0, (Count * 20) + 1);

            local Y = math.clamp(Count * 20, 0, MAX_DROPDOWN_ITEMS * 20) + 1;
            RecalculateListSize(Y);
        end;

        function Dropdown:SetValues(NewValues)
            if NewValues then
                Dropdown.Values = NewValues;
            end;

            Dropdown:BuildDropdownList();
        end;

        function Dropdown:OpenDropdown()
            if Dropdown.Tween then Dropdown.Tween:Cancel() end;

            RecalculateListPosition();
            Library:ApplyPopupZIndex(ListOuter, 20);
            ListOuter.Size = UDim2.fromOffset(DropdownOuter.AbsoluteSize.X, 0);
            ListOuter.Visible = true;
            ListOuter.ClipsDescendants = false;
            ListInner.ClipsDescendants = false;
            Library.OpenedFrames[ListOuter] = true;

            Dropdown.Tween = TweenService:Create(ListOuter, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(DropdownOuter.AbsoluteSize.X, Dropdown.ListHeight or 162)
            });
            DropdownArrow.Text = '-';

            Dropdown.Tween:Play();
        end;

        function Dropdown:CloseDropdown()
            if Dropdown.Tween then Dropdown.Tween:Cancel() end;

            Dropdown.Tween = TweenService:Create(ListOuter, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(DropdownOuter.AbsoluteSize.X, 0)
            });
            DropdownArrow.Text = '+';

            local connection;
            connection = Dropdown.Tween.Completed:Connect(function()
                ListOuter.Visible = false;
                Library.OpenedFrames[ListOuter] = nil;
                connection:Disconnect();
            end);

            Dropdown.Tween:Play();
        end;

        function Dropdown:OnChanged(Func)
            Dropdown.Changed = Func;
            Func(Dropdown.Value);
        end;

        function Dropdown:SetValue(Val)
            local previousValue = Dropdown.Value;

            if Dropdown.Multi then
                local nTable = {};

                for Value, Bool in next, Val do
                    if table.find(Dropdown.Values, Value) then
                        nTable[Value] = true;
                    end;
                end;

                Dropdown.Value = nTable;
            else
                if (not Val) then
                    Dropdown.Value = nil;
                elseif table.find(Dropdown.Values, Val) then
                    Dropdown.Value = Val;
                end;
            end;

            if Dropdown.Value == previousValue then
                Dropdown:Display();
                return;
            end;

            Dropdown:BuildDropdownList();

            Library:SafeCallback(Dropdown.Callback, Dropdown.Value);
            Library:SafeCallback(Dropdown.Changed, Dropdown.Value);
        end;

        DropdownOuter.InputBegan:Connect(function(Input)
            if IsPrimaryPress(Input) and not Library:MouseIsOverOpenedFrame() then
                if ListOuter.Visible then
                    Dropdown:CloseDropdown();
                else
                    Dropdown:OpenDropdown();
                end;
            end;
        end);

        InputService.InputBegan:Connect(function(Input)
            if IsPrimaryPress(Input) then
                local Pos = GetPointerPosition(Input);
                local AbsPos, AbsSize = ListOuter.AbsolutePosition, ListOuter.AbsoluteSize;

                if Pos.X < AbsPos.X or Pos.X > AbsPos.X + AbsSize.X
                    or Pos.Y < (AbsPos.Y - 20 - 1) or Pos.Y > AbsPos.Y + AbsSize.Y then

                    Dropdown:CloseDropdown();
                end;
            end;
        end);

        Dropdown:BuildDropdownList();
        Dropdown:Display();

        local Defaults = {};

        if type(Info.Default) == 'string' then
            local Idx = table.find(Dropdown.Values, Info.Default);
            if Idx then
                table.insert(Defaults, Idx);
            end;
        elseif type(Info.Default) == 'table' then
            for _, Value in next, Info.Default do
                local Idx = table.find(Dropdown.Values, Value);
                if Idx then
                    table.insert(Defaults, Idx);
                end;
            end;
        elseif type(Info.Default) == 'number' and Dropdown.Values[Info.Default] ~= nil then
            table.insert(Defaults, Info.Default);
        end;

        if next(Defaults) then
            for i = 1, #Defaults do
                local Index = Defaults[i];
                if Info.Multi then
                    Dropdown.Value[Dropdown.Values[Index]] = true;
                else
                    Dropdown.Value = Dropdown.Values[Index];
                end;

                if (not Info.Multi) then break end;
            end;

            Dropdown:BuildDropdownList();
            Dropdown:Display();
        end;

        Groupbox:AddBlank(Info.BlankSize or 5);
        Groupbox:Resize();

        if type(Dropdown)=="table" and Dropdown.SetVisible==nil then Dropdown.SetVisible=function() end end;
        Options[Idx] = Dropdown;
        Dropdown.Outer = DropdownOuter;
        Dropdown.ListOuter = ListOuter;

        Library:UpdateDependencyBoxes();

        return Dropdown;
    end;

    function Funcs:AddDependencyBox()
        local Depbox = {Dependencies = {}};
        local Groupbox = self;
        local Container = Groupbox.Container;
        local Holder = Library:Create('Frame', {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            Visible = false,
            Parent = Container,
        });
        local Frame = Library:Create('Frame', {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Visible = true,
            Parent = Holder,
        });
        local Layout = Library:Create('UIListLayout', {
            FillDirection = Enum.FillDirection.Vertical,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = Frame,
        });

        function Depbox:Resize()
            Holder.Size = NewUDim2(1, 0, 0, Layout.AbsoluteContentSize.Y);

            Groupbox:Resize();
        end;

        Layout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
            Depbox:Resize();
        end);
        Holder:GetPropertyChangedSignal('Visible'):Connect(function()
            Depbox:Resize();
        end);

        function Depbox:Update()
            for _, Dependency in next, Depbox.Dependencies do
                local Elem = Dependency[1];
                local Expected = Dependency[2];
                local CurrentValue = Elem.Value;

                if CurrentValue == nil then
                    Holder.Visible = false;

                    Depbox:Resize();

                    return
                end;
                if CurrentValue ~= Expected then
                    Holder.Visible = false;

                    Depbox:Resize();

                    return
                end;
            end;

            Holder.Visible = true;

            Depbox:Resize();
        end;
        function Depbox:SetupDependencies(Dependencies)
            for _, Dependency in next, Dependencies do
                assert(type(Dependency) == 'table', 'SetupDependencies: Dependency is not of type `table`.');
                assert(Dependency[1], 'SetupDependencies: Dependency is missing element argument.');
                assert(Dependency[2] ~= nil, 'SetupDependencies: Dependency is missing value argument.');
            end;

            Depbox.Dependencies = Dependencies;

            Depbox:Update();
        end;

        Depbox.Container = Frame;

        setmetatable(Depbox, BaseGroupbox);
        table.insert(Library.DependencyBoxes, Depbox);

        return Depbox;
    end;

    BaseGroupbox.__index = Funcs;
    BaseGroupbox.__namecall = function(Table, Key, ...)
        local Method = rawget(Table, Key) or Funcs[Key];
        return Method(Table, ...);
    end;
end;

function Library:UpdateNotificationArea()
    local area = Library.NotificationArea;
    local layout = Library.NotificationListLayout;
    if not area or not layout then
        return
    end;

    local margin = 12;
    local spot = Library.NotificationSpot or 'Top Right';

    if spot == 'Top Left' then
        area.AnchorPoint = Vector2.new(0, 0);
        area.Position = UDim2.new(0, margin, 0, margin);
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Left;
        layout.VerticalAlignment = Enum.VerticalAlignment.Top;
    elseif spot == 'Bottom Right' then
        area.AnchorPoint = Vector2.new(1, 1);
        area.Position = UDim2.new(1, -margin, 1, -margin);
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Right;
        layout.VerticalAlignment = Enum.VerticalAlignment.Bottom;
    elseif spot == 'Bottom Left' then
        area.AnchorPoint = Vector2.new(0, 1);
        area.Position = UDim2.new(0, margin, 1, -margin);
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Left;
        layout.VerticalAlignment = Enum.VerticalAlignment.Bottom;
    elseif spot == 'Center' then
        area.AnchorPoint = Vector2.new(0.5, 0.5);
        area.Position = UDim2.new(0.5, 0, 0.5, 0);
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Center;
        layout.VerticalAlignment = Enum.VerticalAlignment.Center;
    else
        area.AnchorPoint = Vector2.new(1, 0);
        area.Position = UDim2.new(1, -margin, 0, margin);
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Right;
        layout.VerticalAlignment = Enum.VerticalAlignment.Top;
    end;
end;

function Library:SetNotificationSpot(Spot)
    Library.NotificationSpot = Spot;
    Library:UpdateNotificationArea();
end;

function Library:SetNotificationAnimation(Animation)
    Library.NotificationAnimation = Animation;
end;

function Library:PlayNotificationEnter(NotifyInner, TotalW)
    local animation = Library.NotificationAnimation or 'Slide Right to Left';
    local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);

    NotifyInner.AnchorPoint = Vector2.new(0, 0);
    NotifyInner.Position = UDim2.fromOffset(0, 0);
    NotifyInner.Size = UDim2.new(1, 0, 1, 0);

    if animation == 'Slide Left to Right' then
        NotifyInner.Position = UDim2.fromOffset(-TotalW, 0);
        TweenService:Create(NotifyInner, tweenInfo, {
            Position = UDim2.fromOffset(0, 0),
        }):Play();
    elseif animation == 'Middle Outwards' then
        NotifyInner.AnchorPoint = Vector2.new(0.5, 0.5);
        NotifyInner.Position = UDim2.new(0.5, 0, 0.5, 0);
        NotifyInner.Size = UDim2.new(0, 0, 1, 0);
        TweenService:Create(NotifyInner, tweenInfo, {
            Size = UDim2.new(1, 0, 1, 0),
        }):Play();
    else
        NotifyInner.Position = UDim2.fromOffset(TotalW, 0);
        TweenService:Create(NotifyInner, tweenInfo, {
            Position = UDim2.fromOffset(0, 0),
        }):Play();
    end;
end;

function Library:PlayNotificationExit(NotifyInner, TotalW, Callback)
    local animation = Library.NotificationAnimation or 'Slide Right to Left';
    local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In);
    local tween;

    if animation == 'Slide Left to Right' then
        tween = TweenService:Create(NotifyInner, tweenInfo, {
            Position = UDim2.fromOffset(TotalW, 0),
        });
    elseif animation == 'Middle Outwards' then
        NotifyInner.AnchorPoint = Vector2.new(0.5, 0.5);
        NotifyInner.Position = UDim2.new(0.5, 0, 0.5, 0);
        tween = TweenService:Create(NotifyInner, tweenInfo, {
            Size = UDim2.new(0, 0, 1, 0),
        });
    else
        tween = TweenService:Create(NotifyInner, tweenInfo, {
            Position = UDim2.fromOffset(-TotalW, 0),
        });
    end;

    tween.Completed:Connect(function()
        if Callback then
            Callback();
        end;
    end);
    tween:Play();
end

do
    Library.NotificationArea = Library:Create('Frame', {
        BackgroundTransparency = 1;
        AnchorPoint = Vector2.new(1, 0);
        Position = UDim2.new(1, -12, 0, 12);
        Size = UDim2.new(0, 480, 1, -24);
        ZIndex = 100;
        Parent = ScreenGui;
    });

    Library.NotificationListLayout = Library:Create('UIListLayout', {
        Padding = UDim.new(0, 6);
        FillDirection = Enum.FillDirection.Vertical;
        SortOrder = Enum.SortOrder.LayoutOrder;
        HorizontalAlignment = Enum.HorizontalAlignment.Right;
        VerticalAlignment = Enum.VerticalAlignment.Top;
        Parent = Library.NotificationArea;
    });

    Library.NotificationIndex = 0;
    Library:UpdateNotificationArea();

    local WatermarkOuter = Library:Create('Frame', {
        AnchorPoint = Vector2.new(0.5, 0);
        BorderSizePixel = 0;
        Position = UDim2.new(0.5, 0, 0, 15);
        Size = UDim2.new(0, 213, 0, 20);
        ZIndex = 200;
        Visible = false;
        Parent = ScreenGui;
    });

    local WatermarkInner = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderSizePixel = 0;
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 201;
        Parent = WatermarkOuter;
    });

    Library:AddToRegistry(WatermarkInner, {
        BackgroundColor3 = 'MainColor';
    });

    local InnerFrame = Library:Create('Frame', {
        BackgroundColor3 = Color3.new(1, 1, 1);
        BorderSizePixel = 0;
        Position = UDim2.new(0, 0, 0, 0);
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 202;
        Parent = WatermarkInner;
    });

    local Gradient = Library:Create('UIGradient', {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),
            ColorSequenceKeypoint.new(1, Library.MainColor),
        });
        Rotation = -90;
        Parent = InnerFrame;
    });

    Library:AddToRegistry(Gradient, {
        Color = function()
            return ColorSequence.new({
                ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),
                ColorSequenceKeypoint.new(1, Library.MainColor),
            });
        end
    });

    local AccentLine = Library:Create('Frame', {
        BackgroundColor3 = Library.AccentColor;
        BorderSizePixel = 0;
        Position = UDim2.new(0, 0, 0, 0);
        Size = UDim2.new(1, 0, 0, 1);
        ZIndex = 205;
        Parent = InnerFrame;
    });

    Library:AddToRegistry(AccentLine, {
        BackgroundColor3 = 'AccentColor';
    });

    local WatermarkLabel = Library:CreateLabel({
        Position = UDim2.new(0, 5, 0, 0);
        Size = UDim2.new(1, -10, 1, -1);
        TextSize = 14;
        TextXAlignment = Enum.TextXAlignment.Center;
        ZIndex = 203;
        Parent = InnerFrame;
    });

    Library.Watermark = WatermarkOuter;
    Library.WatermarkText = WatermarkLabel;
    Library:MakeDraggable(Library.Watermark);

    local KeybindContainer = Library:Create('Frame', {
        BackgroundTransparency = 1;
        Size = UDim2.new(1, 0, 0, 0);
        Visible = false;
        ZIndex = 200;
        Parent = ScreenGui;
    });

    Library:Create('UIListLayout', {
        FillDirection = Enum.FillDirection.Vertical;
        SortOrder = Enum.SortOrder.LayoutOrder;
        Parent = KeybindContainer;
    });

    Library:Create('UIPadding', {
        PaddingLeft = UDim.new(0, 5),
        Parent = KeybindContainer,
    });

    Library.KeybindContainer = KeybindContainer;
end;

function Library:SetWatermarkVisibility(Bool)
    Library.Watermark.Visible = Bool;
end;

function Library:SetWatermark(Text)
    local rawText = Text or '';
    Library.LastWatermarkText = rawText;

    local X, Y = Library:GetTextBounds(rawText, Library.Font, 14);
    Library.Watermark.Size = UDim2.new(0, X + 16, 0, (Y * 1.5) + 3);
    Library:SetAccentTitle(Library.WatermarkText, rawText, Library.WatermarkAccentPart or '.lol');
end;

getgenv().skyware_wm = getgenv().skyware_wm or { ping = true, executor = false, fps = true, time = true };
task.spawn(function()
    local fps = 60;
    local execName = nil;

    local function getPing()
        local ok, v = pcall(function()
            return game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue();
        end);
        if ok and v then return math.floor(v + 0.5) end;
        return 0;
    end;

    local function getExecutor()
        if execName ~= nil then return execName end;
        local fn = identifyexecutor or getexecutorname;
        if fn then
            local ok, name, ver = pcall(fn);
            if ok and name then
                execName = tostring(name);
                if ver and tostring(ver) ~= "" then execName = execName .. " " .. tostring(ver) end;
            else
                execName = "";
            end;
        else
            execName = "";
        end;
        return execName;
    end;

    RunService.RenderStepped:Connect(LPH_NO_VIRTUALIZE(function(dt)
        if dt and dt > 0 then
            local instant = 1 / dt;
            fps = fps + (instant - fps) * 0.1;
        end;
    end));

    while task.wait(0.5) do
        if Library.Watermark and Library.Watermark.Visible then
            local wm = getgenv().skyware_wm or {};
            local parts = { "Skyware" };
            if wm.fps ~= false then
                parts[#parts + 1] = string.format("%d fps", math.floor(fps + 0.5));
            end;
            if wm.ping ~= false then
                parts[#parts + 1] = string.format("%d ms", getPing());
            end;
            if wm.executor then
                local ex = getExecutor();
                if ex ~= "" then parts[#parts + 1] = ex end;
            end;
            if wm.time ~= false then
                parts[#parts + 1] = os.date("%X");
            end;
            Library:SetWatermark(table.concat(parts, " | "));
        end;
    end;
end);

local SOUND_URLS = {
    Toggle = 'https://raw.githubusercontent.com/xhafodev/UI/main/pop%20UI%20sound.mp3',
    Notification = 'https://raw.githubusercontent.com/xhafodev/UI/main/notify.mp3',
    Slider = 'https://raw.githubusercontent.com/xhafodev/UI/main/slider.mp3',
};

function Library:EnsureSoundFile(Folder, FileName, Url)
    if not writefile or not isfile or not getcustomasset then
        return nil;
    end;

    local Path = Folder .. '/sounds/' .. FileName;
    if not isfile(Path) then
        if not game.HttpGet then
            return nil;
        end;

        local Success, Content = pcall(function()
            return game:HttpGet(Url);
        end);

        if not Success or not Content then
            return nil;
        end;

        writefile(Path, Content);
    end;

    return getcustomasset(Path);
end;

function Library:ApplySoundSettings(Settings)
    self.ToggleSoundEnabled = Settings.ToggleSoundEnabled ~= false;
    self.NotificationSoundEnabled = Settings.NotificationSoundEnabled ~= false;
    self.SliderSoundEnabled = Settings.SliderSoundEnabled ~= false;
    self.ToggleSoundVolume = math.clamp(tonumber(Settings.ToggleSoundVolume) or 1, 0, 1);
    self.ToggleSoundSpeed = math.clamp(tonumber(Settings.ToggleSoundSpeed) or 1, 0.25, 3);
    self.NotificationSoundVolume = math.clamp(tonumber(Settings.NotificationSoundVolume) or 1, 0, 1);
    self.NotificationSoundSpeed = math.clamp(tonumber(Settings.NotificationSoundSpeed) or 1, 0.25, 3);
    self.SliderSoundVolume = math.clamp(tonumber(Settings.SliderSoundVolume) or 1, 0, 1);
    self.SliderSoundSpeed = math.clamp(tonumber(Settings.SliderSoundSpeed) or 1, 0.25, 3);
end;

function Library:SaveSoundSettings()
    if not writefile then
        return;
    end;

    local SettingsPath = (self.SoundSettingsFolder or 'skyware') .. '/settings/sounds.json';
    local Data = {
        ToggleSoundEnabled = self.ToggleSoundEnabled;
        NotificationSoundEnabled = self.NotificationSoundEnabled;
        SliderSoundEnabled = self.SliderSoundEnabled;
        ToggleSoundVolume = self.ToggleSoundVolume;
        ToggleSoundSpeed = self.ToggleSoundSpeed;
        NotificationSoundVolume = self.NotificationSoundVolume;
        NotificationSoundSpeed = self.NotificationSoundSpeed;
        SliderSoundVolume = self.SliderSoundVolume;
        SliderSoundSpeed = self.SliderSoundSpeed;
    };

    local Success, Encoded = pcall(function()
        return HttpService:JSONEncode(Data);
    end);

    if Success then
        writefile(SettingsPath, Encoded);
    end;
end;

function Library:InitSoundSettings(Folder)
    local Defaults = {
        ToggleSoundEnabled = true;
        NotificationSoundEnabled = true;
        SliderSoundEnabled = true;
        ToggleSoundVolume = 1;
        ToggleSoundSpeed = 1;
        NotificationSoundVolume = 1;
        NotificationSoundSpeed = 1;
        SliderSoundVolume = 1;
        SliderSoundSpeed = 1;
    };

    self.SoundSettingsFolder = Folder or 'skyware';
    local SettingsPath = self.SoundSettingsFolder .. '/settings/sounds.json';
    local Settings = Defaults;

    if isfile and readfile and isfile(SettingsPath) then
        local Success, Decoded = pcall(function()
            return HttpService:JSONDecode(readfile(SettingsPath));
        end);

        if Success and type(Decoded) == 'table' then
            for Key, Value in next, Defaults do
                if Decoded[Key] ~= nil then
                    Settings[Key] = Decoded[Key];
                end;
            end;
        end;
    end;

    self:ApplySoundSettings(Settings);

    if not isfile or not isfile(SettingsPath) then
        self:SaveSoundSettings();
    end;

    self:InitSoundAssets();
end;

function Library:InitSoundAssets()
    local Folder = self.SoundSettingsFolder or 'skyware';

    if not self.ToggleSound then
        local ToggleAsset = self:EnsureSoundFile(Folder, 'toggle.mp3', SOUND_URLS.Toggle);
        if ToggleAsset then
            self.ToggleSound = Instance.new('Sound');
            self.ToggleSound.Name = 'SkywareToggleSound';
            self.ToggleSound.SoundId = ToggleAsset;
            self.ToggleSound.Volume = self.ToggleSoundVolume;
            self.ToggleSound.PlaybackSpeed = self.ToggleSoundSpeed;
            self.ToggleSound.Parent = SoundService;
        end;
    end;

    if not self.NotificationSound then
        local NotifyAsset = self:EnsureSoundFile(Folder, 'notify.mp3', SOUND_URLS.Notification);
        if NotifyAsset then
            self.NotificationSound = Instance.new('Sound');
            self.NotificationSound.Name = 'SkywareNotificationSound';
            self.NotificationSound.SoundId = NotifyAsset;
            self.NotificationSound.Volume = self.NotificationSoundVolume;
            self.NotificationSound.PlaybackSpeed = self.NotificationSoundSpeed;
            self.NotificationSound.Parent = SoundService;
        end;
    end;

    if not self.SliderSound then
        local SliderAsset = self:EnsureSoundFile(Folder, 'slider.mp3', SOUND_URLS.Slider);
        if SliderAsset then
            self.SliderSound = Instance.new('Sound');
            self.SliderSound.Name = 'SkywareSliderSound';
            self.SliderSound.SoundId = SliderAsset;
            self.SliderSound.Volume = self.SliderSoundVolume;
            self.SliderSound.PlaybackSpeed = self.SliderSoundSpeed;
            self.SliderSound.Parent = SoundService;
        end;
    end;

    self._SoundAssetsInitialized = true;
end;

function Library:PlaySliderSound()
    if not self.SliderSoundEnabled then
        return
    end;

    self:InitSoundAssets();

    local Sound = self.SliderSound;
    if not Sound then
        return
    end;

    Sound.Volume = self.SliderSoundVolume;
    Sound.PlaybackSpeed = self.SliderSoundSpeed;

    if Sound.IsPlaying then
        Sound:Stop();
    end;

    Sound.TimePosition = 0;
    Sound:Play();
end;

function Library:StopSliderSound()
    local Sound = self.SliderSound;
    if Sound and Sound.IsPlaying then
        Sound:Stop();
    end;
end;

function Library:PlayToggleSound()
    if not self.ToggleSoundEnabled then
        return;
    end;

    self:InitSoundAssets();

    local Sound = self.ToggleSound;
    if not Sound then
        return;
    end;

    Sound.Volume = self.ToggleSoundVolume;
    Sound.PlaybackSpeed = self.ToggleSoundSpeed;

    if Sound.IsPlaying then
        Sound:Stop();
    end;

    Sound.TimePosition = 0;
    Sound:Play();
end;

function Library:PlayNotificationSound()
    if not self.NotificationSoundEnabled then
        return;
    end;

    self:InitSoundAssets();

    local Sound = self.NotificationSound;
    if not Sound then
        return;
    end;

    Sound.Volume = self.NotificationSoundVolume;
    Sound.PlaybackSpeed = self.NotificationSoundSpeed;

    if Sound.IsPlaying then
        Sound:Stop();
    end;

    Sound.TimePosition = 0;
    Sound:Play();
end;

function Library:Notify(Text, Time)
    Library:PlayNotificationSound();

    local Duration = Time or 5;
    local TextSize = 13;
    local BarHeight = 2;
    local PadX = 10;
    local PadY = 6;

    local XSize, YSize = Library:GetTextBounds(Text, Library.Font, TextSize);
    local TotalW = math.ceil(XSize + PadX * 2 + 20);
    local TotalH = math.ceil(YSize + PadY * 2 + BarHeight + 4);

    Library.NotificationIndex = (Library.NotificationIndex or 0) + 1;

    local NotifyOuter = Library:Create('Frame', {
        BackgroundTransparency = 1;
        BorderSizePixel = 0;
        ClipsDescendants = true;
        LayoutOrder = Library.NotificationIndex;
        Size = UDim2.fromOffset(TotalW, TotalH);
        ZIndex = 100;
        Parent = Library.NotificationArea;
    });

    local NotifyInner = Library:Create('Frame', {
        BackgroundColor3 = Library.BackgroundColor;
        BorderColor3 = Library.OutlineColor;
        BorderMode = Enum.BorderMode.Inset;
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 101;
        Parent = NotifyOuter;
    });

    Library:AddToRegistry(NotifyInner, {
        BackgroundColor3 = 'BackgroundColor';
        BorderColor3 = 'OutlineColor';
    }, true);

    local function ApplySize(width, height)
        TotalW = width;
        TotalH = height;
        NotifyOuter.Size = UDim2.fromOffset(TotalW, TotalH);
    end;

    Library:PlayNotificationEnter(NotifyInner, TotalW);

    local NotifyLabel = Library:CreateLabel({
        Position = UDim2.new(0, PadX, 0, PadY);
        Size = UDim2.new(1, -PadX * 2, 1, -(PadY * 2 + BarHeight));
        Text = Text;
        RichText = true;
        TextSize = TextSize;
        TextWrapped = false;
        TextTruncate = Enum.TextTruncate.None;
        TextXAlignment = Enum.TextXAlignment.Left;
        TextYAlignment = Enum.TextYAlignment.Top;
        ZIndex = 103;
        Parent = NotifyInner;
    });

    Library:AddToRegistry(NotifyLabel, {
        TextColor3 = 'FontColor';
    }, true);

    task.defer(function()
        if not NotifyLabel.Parent then
            return
        end;

        local measuredW = NotifyLabel.TextBounds.X + PadX * 2 + 16;
        local measuredH = math.max(NotifyLabel.TextBounds.Y + PadY * 2 + BarHeight + 4, TotalH);
        if measuredW > TotalW then
            ApplySize(math.ceil(measuredW), measuredH);
        end;
    end);

    local ProgressBar = Library:Create('Frame', {
        BackgroundColor3 = Library.AccentColor;
        BorderSizePixel = 0;
        Position = UDim2.new(0, 0, 1, -BarHeight);
        Size = UDim2.new(1, 0, 0, BarHeight);
        ZIndex = 104;
        Parent = NotifyInner;
    });

    Library:AddToRegistry(ProgressBar, {
        BackgroundColor3 = 'AccentColor';
    }, true);

    TweenService:Create(ProgressBar, TweenInfo.new(Duration, Enum.EasingStyle.Linear), {
        Size = UDim2.new(0, 0, 0, BarHeight);
    }):Play();

    task.spawn(function()
        task.wait(Duration);

        Library:PlayNotificationExit(NotifyInner, TotalW, function()
            NotifyOuter:Destroy();
        end);
    end);
end;

function Library:CreateWindow(...)
    local Arguments = { ... };
    local Config = { AnchorPoint = Vector2.zero };

    if type(...) == 'table' then
        Config = ...;
    else
        Config.Title = Arguments[1];
        Config.AutoShow = Arguments[2] or false;
    end;

    if type(Config.Title) ~= 'string' then Config.Title = 'No title' end;
    if type(Config.TabPadding) ~= 'number' then Config.TabPadding = 10 end;
    if type(Config.MenuFadeTime) ~= 'number' then Config.MenuFadeTime = 0.2 end;

    if typeof(Config.Position) ~= 'UDim2' then Config.Position = UDim2.fromOffset(175, 50) end;
    if typeof(Config.Size) ~= 'UDim2' then Config.Size = UDim2.fromOffset(460, 400) end

    do
        local saved = getgenv().skyware_ui_size;
        if not saved then
            pcall(function()
                local f = (isfile and isfile('Skyware/ui_size.txt') and 'Skyware/ui_size.txt')
                    or (isfile and isfile('Elisium/ui_size.txt') and 'Elisium/ui_size.txt');
                if f then
                    local d = tostring(readfile(f));
                    local x, y = d:match('(%d+),(%d+)');
                    if x and y then saved = { tonumber(x), tonumber(y) } end;
                end;
            end);
        end;
        if type(saved) == 'table' and tonumber(saved[1]) and tonumber(saved[2]) then
            Config.Size = UDim2.fromOffset(tonumber(saved[1]), tonumber(saved[2]));
        end;
    end;

    if Config.Center then
        Config.AnchorPoint = Vector2.new(0.5, 0.5);
        Config.Position = UDim2.fromScale(0.5, 0.5);
    end;

    local Window = {
        Tabs = {};
    };

    Library.OverlayZIndexBase = nil;

    local Outer = Library:Create('Frame', {
        AnchorPoint = Config.AnchorPoint,
        BackgroundTransparency = 1;
        BorderSizePixel = 0;
        ClipsDescendants = false;
        Position = Config.Position,
        Size = Config.Size,
        Visible = false;
        ZIndex = 1;
        Parent = ScreenGui;
    });

    Window.Outer = Outer;
    Library.MainWindow = Window;

    Library:MakeDraggable(Outer, 25);

    local Inner = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderSizePixel = 0;
        ClipsDescendants = false;
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 1;
        Parent = Outer;
    });

    Library:AddToRegistry(Inner, {
        BackgroundColor3 = 'MainColor';
    });

    do
        local UIS = game:GetService('UserInputService');
        local MINW, MINH = 340, 300;
        Library.MainWindowOuter = Outer;
        local function persistSize()
            local s = Outer.AbsoluteSize;
            getgenv().skyware_ui_size = { math.floor(s.X), math.floor(s.Y) };
            pcall(function()
                if writefile then
                    if makefolder and isfolder and not isfolder('Skyware') then makefolder('Skyware') end;
                    writefile('Skyware/ui_size.txt', math.floor(s.X) .. ',' .. math.floor(s.Y));
                end;
            end);
        end;
        function Library:GetWindowSize()
            local s = Outer.AbsoluteSize;
            return math.floor(s.X), math.floor(s.Y);
        end;
        function Library:SetWindowSize(x, y)
            x, y = tonumber(x), tonumber(y);
            if not (x and y) then return end;
            Outer.Size = UDim2.fromOffset(math.max(MINW, x), math.max(MINH, y));
            persistSize();
        end;

        local Handle = Library:Create('TextButton', {
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(1, -3, 1, -3),
            Size = UDim2.fromOffset(20, 20),
            BackgroundTransparency = 1,
            Text = '',
            AutoButtonColor = false,
            ZIndex = 60,
            Parent = Outer,
        });
        for i = 1, 3 do
            local grip = Library:Create('Frame', {
                AnchorPoint = Vector2.new(1, 1),
                Position = UDim2.new(1, 0, 1, -(i - 1) * 4),
                Size = UDim2.fromOffset(4 + (i - 1) * 5, 2),
                BackgroundColor3 = Library.AccentColor,
                BorderSizePixel = 0,
                ZIndex = 61,
                Parent = Handle,
            });
            Library:AddToRegistry(grip, { BackgroundColor3 = 'AccentColor' });
        end;

        local resizing, startPos, startSize = false, nil, nil;
        Handle.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                resizing = true;
                startPos = UIS:GetMouseLocation();
                startSize = Outer.AbsoluteSize;
            end;
        end);
        Library:GiveSignal(UIS.InputChanged:Connect(LPH_NO_VIRTUALIZE(function(input)
            if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local cur = UIS:GetMouseLocation();
                local w = math.max(MINW, startSize.X + (cur.X - startPos.X));
                local h = math.max(MINH, startSize.Y + (cur.Y - startPos.Y));
                Outer.Size = UDim2.fromOffset(w, h);
            end;
        end)));
        Library:GiveSignal(UIS.InputEnded:Connect(function(input)
            if resizing and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
                resizing = false;
                persistSize();
            end;
        end));
    end;

    Window.ZIndexBase = 10;
    Window.GlowLayers = Library:CreateOverlayGlowLayers(Inner, 1);

    local AnimatedTopBar = Library:Create('Frame', {
        BackgroundColor3 = Library.AccentColor;
        BorderSizePixel = 0;
        Position = UDim2.new(0, 0, 0, 0);
        Size = UDim2.new(1, 0, 0, 2);
        ZIndex = 5;
        Parent = Inner;
    });

    Library:AddToRegistry(AnimatedTopBar, {
        BackgroundColor3 = 'AccentColor';
    });

    local WindowLabel = Library:CreateLabel({
        Position = UDim2.new(0, 8, 0, 4);
        Size = UDim2.new(1, -16, 0, 22);
        Text = "";
        TextSize = 15;
        TextXAlignment = Enum.TextXAlignment.Left;
        ZIndex = 6;
        Parent = Inner;
    });

    local AccentPart = Config.AccentPart or '.lol';

    local function UpdateTitle()
        local rawTitle = Config.Title or "Skyware";
        Library:SetAccentTitle(WindowLabel, rawTitle, AccentPart);
    end;

    Library.UpdateTitle = UpdateTitle;
    UpdateTitle();

    local MainSectionOuter = Library:Create('Frame', {
        BackgroundColor3 = Library.BackgroundColor;
        BorderColor3 = Library.OutlineColor;
        ClipsDescendants = true;
        Position = UDim2.new(0, 8, 0, 30);
        Size = UDim2.new(1, -16, 1, -52);
        ZIndex = 1;
        Parent = Inner;
    });

    Library:AddToRegistry(MainSectionOuter, {
        BackgroundColor3 = 'BackgroundColor';
        BorderColor3 = 'OutlineColor';
    });

    local MainSectionInner = Library:Create('Frame', {
        BackgroundColor3 = Library.BackgroundColor;
        BorderColor3 = Color3.new(0, 0, 0);
        BorderMode = Enum.BorderMode.Inset;
        Position = UDim2.new(0, 0, 0, 0);
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 1;
        Parent = MainSectionOuter;
    });

    Library:AddToRegistry(MainSectionInner, {
        BackgroundColor3 = 'BackgroundColor';
    });

    local TabArea = Library:Create('Frame', {
        BackgroundTransparency = 1;
        ClipsDescendants = false;
        Position = UDim2.new(0, 12, 0, 6);
        Size = UDim2.new(1, -24, 0, 22);
        ZIndex = 1;
        Parent = MainSectionInner;
    });

    Window.TabArea = TabArea;
    Window.TabPadding = Config.TabPadding;
    Window.TabEntries = {};
    Window.TabTextSize = 16;

    local TabListLayout = Library:Create('UIListLayout', {
        Padding = UDim.new(0, Config.TabPadding);
        FillDirection = Enum.FillDirection.Horizontal;
        SortOrder = Enum.SortOrder.LayoutOrder;
        Parent = TabArea;
    });

    Window.TabListLayout = TabListLayout;

    function Window:UpdateTabLayout()
        if not self.TabArea or not self.TabEntries then
            return
        end;

        local Count = #self.TabEntries;
        if Count == 0 then
            return
        end;

        local AreaWidth = self.TabArea.AbsoluteSize.X;
        if AreaWidth <= 0 then
            return
        end;

        local Padding = self.TabPadding or 10;
        local SidePadding = 12;
        local BaseTextSize = self.TabTextSize or 16;
        local MinTextSize = 11;

        local TotalPadding = Padding * (Count - 1);
        local EqualWidth = math.max(24, math.floor((AreaWidth - TotalPadding) / Count));
        local AvailableTextWidth = EqualWidth - SidePadding * 2;

        local function LongestTextWidth(Size)
            local Longest = 0;
            for _, Entry in self.TabEntries do
                local Width = select(1, Library:GetTextBounds(Entry.Name, Library.Font, Size));
                Longest = math.max(Longest, Width);
            end;
            return Longest;
        end;

        local TextSize = BaseTextSize;
        if LongestTextWidth(TextSize) > AvailableTextWidth then
            for Size = BaseTextSize, MinTextSize, -1 do
                TextSize = Size;
                if LongestTextWidth(Size) <= AvailableTextWidth then
                    break;
                end;
            end;
        end;

        for _, Entry in self.TabEntries do
            Entry.Label.TextSize = TextSize;
            Entry.Button.Size = UDim2.new(0, EqualWidth, 1, 0);
        end;
    end;

    TabArea:GetPropertyChangedSignal('AbsoluteSize'):Connect(function()
        Window:UpdateTabLayout();
    end);

    local TabContainer = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.OutlineColor;
        ClipsDescendants = true;
        Position = UDim2.new(0, 8, 0, 32);
        Size = UDim2.new(1, -16, 1, -40);
        ZIndex = 3;
        Parent = MainSectionInner;
    });

    local placeName = 'Baseplate';
    pcall(function()
        placeName = game:GetService('MarketplaceService'):GetProductInfo(game.PlaceId).Name;
    end);

    Library.PlaceName = placeName;
    Library.AnonymousMode = false;

    local FooterLeft = Library:CreateLabel({
        Position = UDim2.new(0, 10, 1, -18);
        Size = UDim2.new(0.5, -10, 0, 14);
        Text = '';
        TextSize = 12;
        TextXAlignment = Enum.TextXAlignment.Left;
        ZIndex = 6;
        Parent = Inner;
    });

    local FooterRight = Library:CreateLabel({
        Position = UDim2.new(0.5, 0, 1, -18);
        Size = UDim2.new(0.5, -10, 0, 14);
        Text = '';
        TextSize = 12;
        TextXAlignment = Enum.TextXAlignment.Right;
        ZIndex = 6;
        Parent = Inner;
    });

    Library.FooterLeft = FooterLeft;
    Library.FooterRight = FooterRight;
    Library:UpdateFooter();

    Library:AddToRegistry(TabContainer, {
        BackgroundColor3 = 'MainColor';
        BorderColor3 = 'OutlineColor';
    });

    function Window:SetWindowTitle(Title, NewAccentPart)
        Config.Title = Title;
        if NewAccentPart then
            Config.AccentPart = NewAccentPart;
            AccentPart = NewAccentPart;
        end;
        UpdateTitle();
    end;

    function Window:AddTab(Name)
        local Tab = {
            Groupboxes = {};
            Tabboxes = {};
        };

        local defaultLayoutOrder = 100;
        if Name == 'Main' then
            defaultLayoutOrder = 1;
        elseif Name == 'Misc' then
            defaultLayoutOrder = 500;
        elseif Name:lower():find('setting') then
            defaultLayoutOrder = 1000;
        end;

        local TabButton = Library:Create('TextButton', {
            BackgroundTransparency = 1;
            BorderSizePixel = 0;
            AutoButtonColor = false;
            Size = UDim2.new(0, 0, 1, 0);
            Text = '';
            ZIndex = 2;
            LayoutOrder = defaultLayoutOrder;
            Parent = TabArea;
        });

        local TabButtonLabel = Library:CreateLabel({
            Position = UDim2.new(0, 0, 0, 0);
            Size = UDim2.new(1, 0, 1, 0);
            Text = Name;
            TextSize = Window.TabTextSize or 16;
            TextColor3 = Color3.new(1, 1, 1);
            TextTransparency = 0.35;
            ZIndex = 3;
            Parent = TabButton;
        });

        Tab.TabButton = TabButton;
        Tab.TabButtonLabel = TabButtonLabel;
        Tab.Name = Name;

        table.insert(Window.TabEntries, {
            Name = Name;
            Button = TabButton;
            Label = TabButtonLabel;
        });

        task.defer(function()
            Window:UpdateTabLayout();
        end);

        local TabGlow, TabUnderline = Library:CreateTabBottomGlow(TabButton, {
            GlowHeight = 18;
            LineHeight = 2;
            ZIndex = 1;
        });

        Tab.TabGlow = TabGlow;
        Tab.TabUnderline = TabUnderline;

        local TabFrame = Library:Create('Frame', {
            Name = 'TabFrame',
            BackgroundTransparency = 1;
            Position = UDim2.new(0, 0, 0, 0);
            Size = UDim2.new(1, 0, 1, 0);
            Visible = false;
            ZIndex = 4;
            Parent = TabContainer;
        });

        local LeftSide = Library:Create('ScrollingFrame', {
            BackgroundTransparency = 1;
            BorderSizePixel = 0;
            ClipsDescendants = true;
            Position = UDim2.new(0, 8 - 1, 0, 8 - 1);
            Size = UDim2.new(0.5, -12 + 2, 1, -16);
            CanvasSize = UDim2.new(0, 0, 0, 0);
            BottomImage = '';
            TopImage = '';
            ScrollBarThickness = 3;
            ScrollBarImageColor3 = Library.AccentColor;
            ZIndex = 5;
            Parent = TabFrame;
        });

        local RightSide = Library:Create('ScrollingFrame', {
            BackgroundTransparency = 1;
            BorderSizePixel = 0;
            ClipsDescendants = true;
            Position = UDim2.new(0.5, 4 + 1, 0, 8 - 1);
            Size = UDim2.new(0.5, -12 + 2, 1, -16);
            CanvasSize = UDim2.new(0, 0, 0, 0);
            BottomImage = '';
            TopImage = '';
            ScrollBarThickness = 3;
            ScrollBarImageColor3 = Library.AccentColor;
            ZIndex = 5;
            Parent = TabFrame;
        });

        Library:AddToRegistry(LeftSide, { ScrollBarImageColor3 = 'AccentColor' });
        Library:AddToRegistry(RightSide, { ScrollBarImageColor3 = 'AccentColor' });

        Library:Create('UIListLayout', {
            Padding = UDim.new(0, 8);
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            HorizontalAlignment = Enum.HorizontalAlignment.Center;
            Parent = LeftSide;
        });

        Library:Create('UIListLayout', {
            Padding = UDim.new(0, 8);
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            HorizontalAlignment = Enum.HorizontalAlignment.Center;
            Parent = RightSide;
        });

        for _, Side in next, { LeftSide, RightSide } do
            Side:WaitForChild('UIListLayout'):GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
                Side.CanvasSize = UDim2.fromOffset(0, Side.UIListLayout.AbsoluteContentSize.Y + 8);
            end);
        end;

        function Tab:ShowTab()
            for _, Tab in next, Window.Tabs do
                Tab:HideTab();
            end;

            Library:SetTabGlowVisible(TabGlow, TabUnderline, true);
            TabButtonLabel.TextTransparency = 0;
            TabFrame.Visible = true;

            for _, Groupbox in next, Tab.Groupboxes do
                if Groupbox.Resize then
                    Groupbox:Resize();
                end;
            end;
        end;

        function Tab:HideTab()
            Library:SetTabGlowVisible(TabGlow, TabUnderline, false);
            TabButtonLabel.TextTransparency = 0.35;
            TabFrame.Visible = false;
        end;

        function Tab:SetLayoutOrder(Position)
            TabButton.LayoutOrder = Position;
            TabListLayout:ApplyLayout();
        end;

        function Tab:AddGroupbox(Info)
            local Groupbox = {};
            local PreviousOverlayBase = Library.OverlayZIndexBase;
            Library.OverlayZIndexBase = nil;

            local BoxOuter = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor;
                BorderColor3 = Library.OutlineColor;
                BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.new(1, 0, 0, 507 + 2);
                ZIndex = 6;
                Parent = Info.Side == 1 and LeftSide or RightSide;
            });

            Library:AddToRegistry(BoxOuter, {
                BackgroundColor3 = 'BackgroundColor';
                BorderColor3 = 'OutlineColor';
            });

            local BoxInner = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor;
                BorderColor3 = Color3.new(0, 0, 0);
                Size = UDim2.new(1, -2, 1, -2);
                Position = UDim2.new(0, 1, 0, 1);
                ZIndex = 7;
                Parent = BoxOuter;
            });

            Library:AddToRegistry(BoxInner, {
                BackgroundColor3 = 'BackgroundColor';
            });

            local Highlight = Library:Create('Frame', {
                BackgroundColor3 = Library.AccentColor;
                BorderSizePixel = 0;
                Size = UDim2.new(1, 0, 0, 2);
                ZIndex = 8;
                Parent = BoxInner;
            });

            Library:AddToRegistry(Highlight, {
                BackgroundColor3 = 'AccentColor';
            });

            local GroupboxLabel = Library:CreateLabel({
                Size = UDim2.new(1, 0, 0, 18);
                Position = UDim2.new(0, 4, 0, 2);
                TextSize = 14;
                Text = Info.Name;
                TextXAlignment = Enum.TextXAlignment.Left;
                ZIndex = 9;
                Parent = BoxInner;
            });

            local Container = Library:Create('Frame', {
                BackgroundTransparency = 1;
                Position = UDim2.new(0, 6, 0, 20);
                Size = UDim2.new(1, -8, 1, -20);
                ZIndex = 10;
                Parent = BoxInner;
            });

            Library:Create('UIListLayout', {
                FillDirection = Enum.FillDirection.Vertical;
                SortOrder = Enum.SortOrder.LayoutOrder;
                Parent = Container;
            });

            local ListLayout = Container:FindFirstChildOfClass('UIListLayout');

            function Groupbox:Resize()
                local Size = 0;
                local SumSize = 0;
                local ChildCount = 0;

                for _, Element in next, Groupbox.Container:GetChildren() do
                    if (not Element:IsA('UIListLayout')) and Element.Visible then
                        ChildCount += 1;
                        SumSize += Element.Size.Y.Offset;
                    end;
                end;

                if ListLayout and ChildCount > 1 then
                    SumSize += ListLayout.Padding.Offset * (ChildCount - 1);
                end;

                if ListLayout then
                    Size = ListLayout.AbsoluteContentSize.Y;
                end;

                Size = math.max(Size, SumSize);

                BoxOuter.Size = UDim2.new(1, 0, 0, 20 + Size + 4);
            end;

            if ListLayout then
                ListLayout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
                    Groupbox:Resize();
                end);
            end;

            Groupbox.Container = Container;
            Groupbox.ContentBaseZIndex = 10;
            setmetatable(Groupbox, BaseGroupbox);

            Groupbox:AddBlank(3);
            Groupbox:Resize();

            Tab.Groupboxes[Info.Name] = Groupbox;

            Library.OverlayZIndexBase = PreviousOverlayBase;
            return Groupbox;
        end;

        function Tab:AddLeftGroupbox(Name)
            return Tab:AddGroupbox({ Side = 1; Name = Name; });
        end;

        function Tab:AddRightGroupbox(Name)
            return Tab:AddGroupbox({ Side = 2; Name = Name; });
        end;

        function Tab:AddTabbox(Info)
            local Tabbox = {
                Tabs = {};
            };

            local BoxOuter = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor;
                BorderColor3 = Library.OutlineColor;
                BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.new(1, 0, 0, 0);
                ZIndex = 6;
                Parent = Info.Side == 1 and LeftSide or RightSide;
            });

            Library:AddToRegistry(BoxOuter, {
                BackgroundColor3 = 'BackgroundColor';
                BorderColor3 = 'OutlineColor';
            });

            local BoxInner = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor;
                BorderColor3 = Color3.new(0, 0, 0);
                Size = UDim2.new(1, -2, 1, -2);
                Position = UDim2.new(0, 1, 0, 1);
                ZIndex = 7;
                Parent = BoxOuter;
            });

            Library:AddToRegistry(BoxInner, {
                BackgroundColor3 = 'BackgroundColor';
            });

            local TabboxButtons = Library:Create('Frame', {
                BackgroundTransparency = 1;
                Position = UDim2.new(0, 0, 0, 0);
                Size = UDim2.new(1, 0, 0, 18);
                ZIndex = 8;
                Parent = BoxInner;
            });

            Library:Create('UIListLayout', {
                FillDirection = Enum.FillDirection.Horizontal;
                HorizontalAlignment = Enum.HorizontalAlignment.Left;
                SortOrder = Enum.SortOrder.LayoutOrder;
                Parent = TabboxButtons;
            });

            function Tabbox:AddTab(Name)
                local Tab = {};

                local Button = Library:Create('Frame', {
                    BackgroundColor3 = Library.MainColor;
                    BorderColor3 = Color3.new(0, 0, 0);
                    Size = UDim2.new(0.5, 0, 1, 0);
                    ZIndex = 6;
                    Parent = TabboxButtons;
                });

                Library:AddToRegistry(Button, {
                    BackgroundColor3 = 'MainColor';
                });

                local ButtonLabel = Library:CreateLabel({
                    Size = UDim2.new(1, 0, 1, 0);
                    TextSize = 14;
                    Text = Name;
                    TextXAlignment = Enum.TextXAlignment.Center;
                    ZIndex = 7;
                    Parent = Button;
                });

                local Block = Library:Create('Frame', {
                    BackgroundColor3 = Library.BackgroundColor;
                    BorderSizePixel = 0;
                    Position = UDim2.new(0, 0, 1, 0);
                    Size = UDim2.new(1, 0, 0, 1);
                    Visible = false;
                    ZIndex = 9;
                    Parent = Button;
                });

                Library:AddToRegistry(Block, {
                    BackgroundColor3 = 'BackgroundColor';
                });

                local Container = Library:Create('Frame', {
                    BackgroundTransparency = 1;
                    Position = UDim2.new(0, 6, 0, 20);
                    Size = UDim2.new(1, -8, 1, -20);
                    ZIndex = 10;
                    Visible = false;
                    Parent = BoxInner;
                });

                local TabUnderline = Library:Create('Frame', {
                    BackgroundColor3 = Library.AccentColor;
                    BorderSizePixel = 0;
                    Position = UDim2.new(0, 0, 0, 0);
                    Size = UDim2.new(1, 0, 0, 2);
                    Visible = false;
                    ZIndex = 10;
                    Parent = Button;
                });

                Library:AddToRegistry(TabUnderline, {
                    BackgroundColor3 = 'AccentColor';
                });

                Library:Create('UIListLayout', {
                    FillDirection = Enum.FillDirection.Vertical;
                    SortOrder = Enum.SortOrder.LayoutOrder;
                    Parent = Container;
                });

                function Tab:Show()
                    for _, Tab in next, Tabbox.Tabs do
                        Tab:Hide();
                    end;

                    Container.Visible = true;
                    Block.Visible = true;
                    TabUnderline.Visible = true;

                    Button.BackgroundColor3 = Library.BackgroundColor;
                    Library.RegistryMap[Button].Properties.BackgroundColor3 = 'BackgroundColor';

                    Tab:Resize();
                end;

                function Tab:Hide()
                    Container.Visible = false;
                    Block.Visible = false;
                    TabUnderline.Visible = false;

                    Button.BackgroundColor3 = Library.MainColor;
                    Library.RegistryMap[Button].Properties.BackgroundColor3 = 'MainColor';
                end;

                function Tab:Resize()
                    local TabCount = 0;

                    for _, Tab in next, Tabbox.Tabs do
                        TabCount = TabCount + 1;
                    end;

                    for _, Button in next, TabboxButtons:GetChildren() do
                        if not Button:IsA('UIListLayout') then
                            Button.Size = UDim2.new(1 / TabCount, 0, 1, 0);
                        end;
                    end;

                    if (not Container.Visible) then
                        return;
                    end;

                    local Size = 0;

                    for _, Element in next, Tab.Container:GetChildren() do
                        if (not Element:IsA('UIListLayout')) and Element.Visible then
                            Size = Size + Element.Size.Y.Offset;
                        end;
                    end;

                    BoxOuter.Size = UDim2.new(1, 0, 0, 20 + Size + 2 + 2);
                end;

                Button.InputBegan:Connect(function(Input)
                    if IsPrimaryPress(Input) and not Library:MouseIsOverOpenedFrame() then
                        Tab:Show();
                        Tab:Resize();
                    end;
                end);

                Tab.Container = Container;
                Tabbox.Tabs[Name] = Tab;

                setmetatable(Tab, BaseGroupbox);
                Tab.ContentBaseZIndex = 10;

                Tab:AddBlank(3);
                Tab:Resize();

                if #TabboxButtons:GetChildren() == 2 then
                    Tab:Show();
                end;

                return Tab;
            end;

            Tab.Tabboxes[Info.Name or ''] = Tabbox;

            return Tabbox;
        end;

        function Tab:AddLeftTabbox(Name)
            return Tab:AddTabbox({ Name = Name, Side = 1; });
        end;

        function Tab:AddRightTabbox(Name)
            return Tab:AddTabbox({ Name = Name, Side = 2; });
        end;

        TabButton.MouseButton1Click:Connect(function()
            Tab:ShowTab();
        end);

        if #TabContainer:GetChildren() == 1 then
            Tab:ShowTab();
        end;

        Window.Tabs[Name] = Tab;
        return Tab;
    end;

    local ModalElement = Library:Create('TextButton', {
        BackgroundTransparency = 1;
        Size = UDim2.new(0, 0, 0, 0);
        Visible = true;
        Text = '';
        Modal = false;
        Parent = ScreenGui;
    });

    local TransparencyCache = {};
    local Toggled = false;

    function Library:Toggle()
        Toggled = not Toggled;

        Library.MenuOpen = Toggled;
        ModalElement.Modal = Toggled;

        Outer.Visible = Toggled;

        Library:SyncOverlaysWithMenu(Toggled);
        Library:UpdateMenuBlur();
        Library:UpdateOverlayGlow(Library.MainWindow);

        if Library.OnToggle then
            task.spawn(Library.OnToggle, Toggled);
        end;
    end;

    Library.MenuBindPickers = Library.MenuBindPickers or {};

    Library:GiveSignal(InputService.InputBegan:Connect(function(Input, Processed)
        local pressed;
        if Input.UserInputType == Enum.UserInputType.Keyboard then
            pressed = Input.KeyCode.Name;
        elseif Input.UserInputType == Enum.UserInputType.MouseButton1 then
            pressed = 'MB1';
        elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then
            pressed = 'MB2';
        end;

        if not pressed then
            return
        end;

        local pickers = Library.MenuBindPickers or {};
        local bound = false;
        for _, picker in eli_ipairs(pickers) do
            if picker and picker.Value and picker.Value ~= 'None' then
                bound = true;
                if picker.Value == pressed then
                    task.spawn(Library.Toggle);
                    return
                end;
            end;
        end;

        if not bound and Input.KeyCode == Enum.KeyCode.RightShift then
            task.spawn(Library.Toggle);
        end;
    end));

    if Config.AutoShow then
        task.spawn(function()
            Library:Toggle();
            Library:UpdateMenuBlur();
        end);
    end;

    Window.Holder = Outer;

    return Window;
end;

local function OnPlayerChange()
    local PlayerList = GetPlayersString();

    for _, Value in next, Options do
        if Value.Type == 'Dropdown' and Value.SpecialType == 'Player' then
            Value:SetValues(PlayerList);
        end;
    end;
end;

Players.PlayerAdded:Connect(OnPlayerChange);
Players.PlayerRemoving:Connect(OnPlayerChange);

Library.Toggles = Toggles;
Library.Options = Options;

getgenv().Library = Library;

return Library;
end)();
local ThemeManager = (function()
local httpService = game:GetService('HttpService');
local ThemeManager = {} do
	ThemeManager.Folder = 'sugarpop';

	ThemeManager.Library = nil;
	ThemeManager.DefaultTheme = 'skyware';
	ThemeManager.BuiltInThemes = {
		['Default'] 		= { 1, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"181818","AccentColor":"4a9eff","SelectedTabColor":"1c1c1c","BackgroundColor":"141414","OutlineColor":"262626","GradientColor":"1a3a5c","ShadowColor":"000000"}') },
		['GameSense'] 		= { 2, httpService:JSONDecode('{"FontColor":"919191","MainColor":"101010","AccentColor":"9CB819","SelectedTabColor":"101010","BackgroundColor":"111111","OutlineColor":"2D2D2D","GradientColor":"242B05"}') },
		['Comet.pub'] 		= { 3, httpService:JSONDecode('{"FontColor":"5E5E5E","MainColor":"0F0F0F","AccentColor":"5D589D","SelectedTabColor":"1a191d","BackgroundColor":"0F0F0F","OutlineColor":"191919","GradientColor":"2b284e"}') },
		['Tokyohook.cc'] 	= { 4, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"191925","AccentColor":"6759b3","SelectedTabColor":"1a1a29","BackgroundColor":"16161f","OutlineColor":"433e58","GradientColor":"2f285c"}') },
		['pandahook.cc'] 	= { 5, httpService:JSONDecode('{"FontColor":"AEAEAE","MainColor":"0F0F0F","AccentColor":"30406A","SelectedTabColor":"151515","BackgroundColor":"0F0F0F","OutlineColor":"171717","GradientColor":"12192b"}') },
		['Mae.lua'] 	        = { 6, httpService:JSONDecode('{"FontColor":"c5c5c5","MainColor":"0F0F0F","AccentColor":"ffc6fe","SelectedTabColor":"171717","BackgroundColor":"0f0f0f","OutlineColor":"191919","GradientColor":"7d3c7a"}') },
		['fatality.win'] 	= { 7, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"1e1822","AccentColor":"c51a4a","SelectedTabColor":"151118","BackgroundColor":"1e1822","OutlineColor":"28212e","GradientColor":"640822"}') },
		['neverlose.cc'] 	= { 8, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"0a0f18","AccentColor":"00b0f0","SelectedTabColor":"060a10","BackgroundColor":"0a0f18","OutlineColor":"141d2f","GradientColor":"004b68"}') },
		['matcha'] 	        = { 9, httpService:JSONDecode('{"FontColor":"e4ebd4","MainColor":"1e231a","AccentColor":"8fa87b","SelectedTabColor":"171b14","BackgroundColor":"1e231a","OutlineColor":"2b3325","GradientColor":"414d38"}') },
		['oreo.yum'] 	    = { 10, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"141414","AccentColor":"ffffff","SelectedTabColor":"0d0d0d","BackgroundColor":"141414","OutlineColor":"262626","GradientColor":"333333"}') },
		['calamari.cc'] 	= { 11, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"0b1517","AccentColor":"39d3c4","SelectedTabColor":"070e10","BackgroundColor":"0b1517","OutlineColor":"152a2e","GradientColor":"146059"}') },
		['aimware.net'] 	= { 12, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"1c1c1c","AccentColor":"f9261a","SelectedTabColor":"141414","BackgroundColor":"1c1c1c","OutlineColor":"2e2e2e","GradientColor":"6b0c07"}') },
		['onetap.su'] 	    = { 13, httpService:JSONDecode('{"FontColor":"e3e3e3","MainColor":"1c1e22","AccentColor":"ff9900","SelectedTabColor":"131518","BackgroundColor":"1c1e22","OutlineColor":"2c2f36","GradientColor":"734500"}') },
		['skeet.cc'] 	    = { 14, httpService:JSONDecode('{"FontColor":"dcdcdc","MainColor":"111111","AccentColor":"569cd6","SelectedTabColor":"151515","BackgroundColor":"111111","OutlineColor":"222222","GradientColor":"1f466b"}') },
		['primordial.dev']  = { 15, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"0f1115","AccentColor":"1adbb2","SelectedTabColor":"08090b","BackgroundColor":"0f1115","OutlineColor":"1f242e","GradientColor":"095c4a"}') },
		['evon.cc'] 	    = { 16, httpService:JSONDecode('{"FontColor":"f0e6f2","MainColor":"140d1a","AccentColor":"d026f2","SelectedTabColor":"0a060d","BackgroundColor":"140d1a","OutlineColor":"2a1a36","GradientColor":"560a66"}') },
		['sentinel.co'] 	= { 17, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"1b1a17","AccentColor":"f2c811","SelectedTabColor":"11100e","BackgroundColor":"1b1a17","OutlineColor":"2e2b26","GradientColor":"665407"}') },
		['cherry.pink'] 	= { 18, httpService:JSONDecode('{"FontColor":"fff0f5","MainColor":"221518","AccentColor":"ff69b4","SelectedTabColor":"140c0e","BackgroundColor":"221518","OutlineColor":"3d262b","GradientColor":"80144f"}') },
		['mint.tea'] 	    = { 19, httpService:JSONDecode('{"FontColor":"f0f9f6","MainColor":"121c19","AccentColor":"4adea7","SelectedTabColor":"0a110f","BackgroundColor":"121c19","OutlineColor":"213630","GradientColor":"166b4d"}') },
		['vape.gg'] 	        = { 20, httpService:JSONDecode('{"FontColor":"d1f2e5","MainColor":"101b17","AccentColor":"2ca579","SelectedTabColor":"0a110f","BackgroundColor":"101b17","OutlineColor":"1f342d","GradientColor":"0f4f37"}') },
		['novoline.club'] 	= { 21, httpService:JSONDecode('{"FontColor":"eae0d5","MainColor":"1a1a1d","AccentColor":"c5a880","SelectedTabColor":"121214","BackgroundColor":"1a1a1d","OutlineColor":"2c2a29","GradientColor":"594630"}') },
		['phantom.blue'] 	= { 22, httpService:JSONDecode('{"FontColor":"e2ecf7","MainColor":"101520","AccentColor":"4f9bf2","SelectedTabColor":"090d14","BackgroundColor":"101520","OutlineColor":"1d2639","GradientColor":"17467e"}') },
		['rose.garden'] 	= { 23, httpService:JSONDecode('{"FontColor":"fceef0","MainColor":"221516","AccentColor":"d54f67","SelectedTabColor":"150d0e","BackgroundColor":"221516","OutlineColor":"382325","GradientColor":"6b1d2b"}') },
		['bumble.bee'] 	    = { 24, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"171714","AccentColor":"ffd60a","SelectedTabColor":"0f0f0d","BackgroundColor":"171714","OutlineColor":"2b2b26","GradientColor":"665200"}') },
		['lavender.field'] 	= { 25, httpService:JSONDecode('{"FontColor":"f3f0f7","MainColor":"191720","AccentColor":"b19ffb","SelectedTabColor":"100e14","BackgroundColor":"191720","OutlineColor":"2d293b","GradientColor":"4c3d82"}') },
		['cyberpunk.2077'] 	= { 26, httpService:JSONDecode('{"FontColor":"00f0ff","MainColor":"100f12","AccentColor":"f3f500","SelectedTabColor":"080709","BackgroundColor":"100f12","OutlineColor":"24222a","GradientColor":"5d5e00"}') },
		['solitaire.win'] 	= { 27, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"0e2016","AccentColor":"d4af37","SelectedTabColor":"08130d","BackgroundColor":"0e2016","OutlineColor":"1b3a27","GradientColor":"5c4c11"}') },
		['sakura.bloom'] 	= { 28, httpService:JSONDecode('{"FontColor":"3d3034","MainColor":"fff5f6","AccentColor":"ffa3b1","SelectedTabColor":"ebd5d8","BackgroundColor":"fff5f6","OutlineColor":"ffd6db","GradientColor":"e68190"}') },
		['abyss.deep'] 	    = { 29, httpService:JSONDecode('{"FontColor":"8da9c4","MainColor":"0b0c10","AccentColor":"66fcf1","SelectedTabColor":"050608","BackgroundColor":"0b0c10","OutlineColor":"1f2833","GradientColor":"0b7a75"}') },
		['sunset.glow'] 	= { 30, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"201115","AccentColor":"ff7e5f","SelectedTabColor":"140b0d","BackgroundColor":"201115","OutlineColor":"361d23","GradientColor":"feb47b"}') },
		['toxic.sludge'] 	= { 31, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"0d110d","AccentColor":"39ff14","SelectedTabColor":"060806","BackgroundColor":"0d110d","OutlineColor":"1c261c","GradientColor":"125c04"}') },
		['ice.age'] 	    = { 32, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"141d26","AccentColor":"a5f2f3","SelectedTabColor":"0d1319","BackgroundColor":"141d26","OutlineColor":"243447","GradientColor":"3f9ea0"}') },
		['dracula'] 	        = { 33, httpService:JSONDecode('{"FontColor":"f8f8f2","MainColor":"282a36","AccentColor":"bd93f9","SelectedTabColor":"1e1f29","BackgroundColor":"282a36","OutlineColor":"44475a","GradientColor":"6272a4"}') },
		['coffee.bean'] 	= { 34, httpService:JSONDecode('{"FontColor":"f5ebe0","MainColor":"221510","AccentColor":"d4a373","SelectedTabColor":"150d0a","BackgroundColor":"221510","OutlineColor":"3d251c","GradientColor":"855a30"}') },
		['vanta.black'] 	= { 35, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"0a0a0a","AccentColor":"ff3333","SelectedTabColor":"050505","BackgroundColor":"0a0a0a","OutlineColor":"141414","GradientColor":"3a0000"}') },
		['matrix.moe'] 	    = { 36, httpService:JSONDecode('{"FontColor":"00ff00","MainColor":"0d100d","AccentColor":"15ff00","SelectedTabColor":"070907","BackgroundColor":"0d100d","OutlineColor":"1a211a","GradientColor":"053d00"}') },
		['vector.pub'] 	    = { 37, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"121216","AccentColor":"ff4500","SelectedTabColor":"0a0a0d","BackgroundColor":"121216","OutlineColor":"22222b","GradientColor":"571700"}') },
		['initiate.win'] 	= { 38, httpService:JSONDecode('{"FontColor":"e2ebe7","MainColor":"1c1e1d","AccentColor":"00ffcc","SelectedTabColor":"131514","BackgroundColor":"1c1e1d","OutlineColor":"2b2f2d","GradientColor":"005443"}') },
		['exodus.private']  = { 39, httpService:JSONDecode('{"FontColor":"fbf7f0","MainColor":"131417","AccentColor":"d4af37","SelectedTabColor":"0c0d0f","BackgroundColor":"131417","OutlineColor":"24262c","GradientColor":"52410f"}') },
		['cryptic.xyz'] 	= { 40, httpService:JSONDecode('{"FontColor":"f3e5f5","MainColor":"0d001a","AccentColor":"9933ff","SelectedTabColor":"06000d","BackgroundColor":"0d001a","OutlineColor":"1f003d","GradientColor":"400080"}') },
		['plague.cc'] 	    = { 41, httpService:JSONDecode('{"FontColor":"eef7ee","MainColor":"111c11","AccentColor":"76ff03","SelectedTabColor":"0b120b","BackgroundColor":"111c11","OutlineColor":"223822","GradientColor":"255400"}') },
		['quantum.tech'] 	= { 42, httpService:JSONDecode('{"FontColor":"e0f7fa","MainColor":"121824","AccentColor":"00e5ff","SelectedTabColor":"0b0f17","BackgroundColor":"121824","OutlineColor":"222e45","GradientColor":"004d61"}') },
		['nemesis.technology'] = { 43, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"151515","AccentColor":"ff2222","SelectedTabColor":"0e0e0e","BackgroundColor":"151515","OutlineColor":"282828","GradientColor":"4c0000"}') },
		['lethality.io'] 	= { 44, httpService:JSONDecode('{"FontColor":"fff3e0","MainColor":"140e0b","AccentColor":"ff9100","SelectedTabColor":"0c0806","BackgroundColor":"140e0b","OutlineColor":"2b1e18","GradientColor":"613700"}') },
		['synapse.x'] 	    = { 45, httpService:JSONDecode('{"FontColor":"f3e8f5","MainColor":"1d1a24","AccentColor":"af52de","SelectedTabColor":"131118","BackgroundColor":"1d1a24","OutlineColor":"342f40","GradientColor":"4e1f6b"}') },
		['krnl.place'] 	    = { 46, httpService:JSONDecode('{"FontColor":"fffde7","MainColor":"1a1a15","AccentColor":"ffd600","SelectedTabColor":"11110e","BackgroundColor":"1a1a15","OutlineColor":"2e2e25","GradientColor":"6b5a00"}') },
		['fluxus.net'] 	    = { 47, httpService:JSONDecode('{"FontColor":"fcebf5","MainColor":"141224","AccentColor":"ff2a85","SelectedTabColor":"0c0b16","BackgroundColor":"141224","OutlineColor":"282447","GradientColor":"6e0d37"}') },
		['electron.vip'] 	= { 48, httpService:JSONDecode('{"FontColor":"e0f2f1","MainColor":"191d20","AccentColor":"00bfa5","SelectedTabColor":"101315","BackgroundColor":"191d20","OutlineColor":"2f383e","GradientColor":"005448"}') },
		['oxygen.u'] 	    = { 49, httpService:JSONDecode('{"FontColor":"e1f5fe","MainColor":"161e2b","AccentColor":"00b0ff","SelectedTabColor":"0e131b","BackgroundColor":"161e2b","OutlineColor":"2b3a52","GradientColor":"004463"}') },
		['nihon.tech'] 	    = { 50, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"191617","AccentColor":"e0115f","SelectedTabColor":"100e0f","BackgroundColor":"191617","OutlineColor":"302b2d","GradientColor":"5c0022"}') },
		['sirhurt.net'] 	= { 51, httpService:JSONDecode('{"FontColor":"fdfaf2","MainColor":"241e17","AccentColor":"f1a80a","SelectedTabColor":"17130e","BackgroundColor":"241e17","OutlineColor":"3f3529","GradientColor":"6b4700"}') },
		['sentinel.rip'] 	= { 52, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"1c1b1c","AccentColor":"cf142b","SelectedTabColor":"121112","BackgroundColor":"1c1b1c","OutlineColor":"363436","GradientColor":"59040d"}') },
		['wearedevs.net'] 	= { 53, httpService:JSONDecode('{"FontColor":"e0f7fa","MainColor":"1b1e22","AccentColor":"00bcd4","SelectedTabColor":"111315","BackgroundColor":"1b1e22","OutlineColor":"2f353d","GradientColor":"004d57"}') },
		['jjsploit.v5'] 	= { 54, httpService:JSONDecode('{"FontColor":"f5eefe","MainColor":"1c1626","AccentColor":"9026ff","SelectedTabColor":"120e19","BackgroundColor":"1c1626","OutlineColor":"302642","GradientColor":"3b0870"}') },
		['valkyrie.vip'] 	= { 55, httpService:JSONDecode('{"FontColor":"faf8f5","MainColor":"1b1d22","AccentColor":"d1a153","SelectedTabColor":"111215","BackgroundColor":"1b1d22","OutlineColor":"2d303a","GradientColor":"5e451d"}') },
		['zeus.cheat'] 	    = { 56, httpService:JSONDecode('{"FontColor":"f8f3fc","MainColor":"131017","AccentColor":"a020f0","SelectedTabColor":"0c0a0e","BackgroundColor":"131017","OutlineColor":"251f2d","GradientColor":"400c61"}') },
		['hydra.win'] 	    = { 57, httpService:JSONDecode('{"FontColor":"e8f4fc","MainColor":"0e141c","AccentColor":"1d8cf8","SelectedTabColor":"090d12","BackgroundColor":"0e141c","OutlineColor":"1b2737","GradientColor":"093761"}') },
		['phoenix.cc'] 	    = { 58, httpService:JSONDecode('{"FontColor":"fff5eb","MainColor":"241612","AccentColor":"ff5500","SelectedTabColor":"160d0b","BackgroundColor":"241612","OutlineColor":"402720","GradientColor":"732100"}') },
		['omega.pub'] 	    = { 59, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"101010","AccentColor":"ffcc00","SelectedTabColor":"0a0a0a","BackgroundColor":"101010","OutlineColor":"222222","GradientColor":"614e00"}') },
		['alpha.club'] 	    = { 60, httpService:JSONDecode('{"FontColor":"e0ffff","MainColor":"151b24","AccentColor":"00ffff","SelectedTabColor":"0d1117","BackgroundColor":"151b24","OutlineColor":"263142","GradientColor":"004d4d"}') },
		['beta.win'] 	    = { 61, httpService:JSONDecode('{"FontColor":"fff0f5","MainColor":"1c1619","AccentColor":"ff1493","SelectedTabColor":"120e10","BackgroundColor":"1c1619","OutlineColor":"362a30","GradientColor":"73003c"}') },
		['nebula.cc'] 	    = { 62, httpService:JSONDecode('{"FontColor":"e8eaf6","MainColor":"151728","AccentColor":"7c4dff","SelectedTabColor":"0d0e19","BackgroundColor":"151728","OutlineColor":"2c3054","GradientColor":"311b92"}') },
		['eclipse.dev'] 	= { 63, httpService:JSONDecode('{"FontColor":"ffebee","MainColor":"1c1a1a","AccentColor":"ff3d00","SelectedTabColor":"121111","BackgroundColor":"1c1a1a","OutlineColor":"363232","GradientColor":"731a00"}') },
		['aurora.win'] 	    = { 64, httpService:JSONDecode('{"FontColor":"e8f5e9","MainColor":"11221a","AccentColor":"00e676","SelectedTabColor":"0b1611","BackgroundColor":"11221a","OutlineColor":"224434","GradientColor":"005427"}') },
		['skyware'] 	    = { 65, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"0d0d0d","AccentColor":"ffffff","SelectedTabColor":"000000","BackgroundColor":"000000","OutlineColor":"2e2e2e","GradientColor":"8c8c8c"}') },
	};

	function ThemeManager:ApplyTheme(theme)
		local customThemeData = self:GetCustomTheme(theme);
		local data = customThemeData or self.BuiltInThemes[theme];

		if not data then return end;

		local scheme = data[2];
		for idx, col in next, customThemeData or scheme do
			if idx == 'ShadowColor' then
				self.Library.ShadowColor = Color3.fromHex(col);
			else
				self.Library[idx] = Color3.fromHex(col);
			end;

			if Options[idx] then
				if Options[idx].Type == 'ColorPicker' then
					Options[idx]:SetValueRGB(Color3.fromHex(col));
				end;
			end;
		end;

		if Options.ShadowColor then
			self.Library.ShadowColor = Options.ShadowColor.Value;
		end;
		if Options.ShadowSize then
			self.Library.ShadowSize = Options.ShadowSize.Value;
		end;
		if Options.ShadowOffset then
			self.Library.ShadowOffset = Options.ShadowOffset.Value;
		end;

		self:ThemeUpdate();
	end;

	function ThemeManager:ThemeUpdate()
		local options = { "FontColor", "MainColor", "AccentColor", "SelectedTabColor", "BackgroundColor", "OutlineColor", "GradientColor" };
		for i, field in next, options do
			if Options and Options[field] then
				self.Library[field] = Options[field].Value;
			end;
		end;

		if Options and Options.ShadowColor then
			self.Library.ShadowColor = Options.ShadowColor.Value;
		end;
		if Options and Options.ShadowSize then
			self.Library.ShadowSize = Options.ShadowSize.Value;
		end;
		if Options and Options.ShadowOffset then
			self.Library.ShadowOffset = Options.ShadowOffset.Value;
		end;

		self.Library.AccentColorDark = self.Library:GetDarkerColor(self.Library.AccentColor);
		self.Library.AccentColorLight = self.Library:GetLighterColor(self.Library.AccentColor);
		self.Library:UpdateColorsUsingRegistry();
	end;

	function ThemeManager:LoadDefault()
		local theme = self.DefaultTheme or 'skyware';
		local content = isfile(self.Folder .. '/themes/default.txt') and readfile(self.Folder .. '/themes/default.txt');

		if content then
			if self.BuiltInThemes[content] then
				theme = content;
			elseif self:GetCustomTheme(content) then
				theme = content;
			end;
		end;

		self:ApplyTheme(theme);
		if Options.ThemeManager_ThemeList then
			Options.ThemeManager_ThemeList:SetValue(theme);
		end;
	end;

	function ThemeManager:SaveDefault(theme)
		writefile(self.Folder .. '/themes/default.txt', theme);
	end;

	function ThemeManager:CreateAppearanceManager(groupbox, skipLoadDefault)
		groupbox:AddLabel('Accent Color'):AddColorPicker('AccentColor', { Default = self.Library.AccentColor });

		groupbox:AddToggle('MenuBlurToggle', {
			Text = 'Menu Blur',
			Default = false,
			Callback = function(Value)
				self.Library:UpdateMenuBlur();
			end,
		});

		groupbox:AddToggle('OverlayGlowToggle', {
			Text = 'Overlay glow',
			Default = self.Library.OverlayGlowEnabled,
			Callback = function(Value)
				self.Library:SetOverlayGlowEnabled(Value);
			end,
		});

		groupbox:AddLabel('Glow color'):AddColorPicker('OverlayGlowColor', {
			Default = self.Library.OverlayGlowColor,
		});

		groupbox:AddToggle('WatermarkToggle', {
			Text = 'Watermark',
			Default = false,
			Callback = function(Value)
				self.Library:SetWatermarkVisibility(Value);
			end,
		});

		groupbox:AddToggle('KeybindListToggle', {
			Text = 'Keybind list',
			Default = true,
			Callback = function(Value)
				if self.Library.KeybindOverlay then
					self.Library.KeybindOverlay:SetVisible(Value);
				end;
			end,
		});

		groupbox:AddToggle('AnonymousModeToggle', {
			Text = 'Anonymous mode',
			Default = false,
			Callback = function(Value)
				self.Library.AnonymousMode = Value;
				self.Library:UpdateFooter();
			end,
		});

		groupbox:AddLabel('Menu bind'):AddKeyPicker('MenuKeybind', {
			Default = 'RightShift',
			Text = 'Menu bind',
			Mode = 'Toggle',
			NoUI = true,
		});

		if Options.MenuKeybind then
			self.Library.ToggleKeybind = Options.MenuKeybind;
			self.Library.MenuBindPickers = self.Library.MenuBindPickers or {};
			table.insert(self.Library.MenuBindPickers, Options.MenuKeybind);
		end;

		local ThemesArray = {};
		for Name, Theme in next, self.BuiltInThemes do
			table.insert(ThemesArray, Name);
		end;

		table.sort(ThemesArray, function(a, b) return self.BuiltInThemes[a][1] < self.BuiltInThemes[b][1] end);

		groupbox:AddDropdown('ThemeManager_ThemeList', { Text = 'Presets', Values = ThemesArray, Default = 'skyware' });

		Options.ThemeManager_ThemeList:OnChanged(function()
			self:ApplyTheme(Options.ThemeManager_ThemeList.Value);
		end);

		local fontNames = self.Library:GetUIFontNames();
		groupbox:AddDropdown('ThemeManager_UIFont', {
			Text = 'UI font',
			Values = fontNames,
			Default = self.Library.CurrentUIFont or 'Builder Sans ExtraBold',
		});

		Options.ThemeManager_UIFont:OnChanged(function()
			self.Library:SetUIFont(Options.ThemeManager_UIFont.Value);
		end);

		if Options.OverlayGlowColor then
			Options.OverlayGlowColor:OnChanged(function()
				self.Library:SetOverlayGlowColor(Options.OverlayGlowColor.Value);
			end);
		end;

		if not skipLoadDefault then
			ThemeManager:LoadDefault();
		end;

		local function UpdateTheme()
			self:ThemeUpdate();
		end;

		Options.AccentColor:OnChanged(UpdateTheme);
	end;

	function ThemeManager:CreateThemeManager(groupbox)
        groupbox:AddDivider();
		groupbox:AddLabel('Background color'):AddColorPicker('BackgroundColor', { Default = self.Library.BackgroundColor });
		groupbox:AddLabel('Main color')	:AddColorPicker('MainColor', { Default = self.Library.MainColor });
		groupbox:AddLabel('Accent color'):AddColorPicker('AccentColor', { Default = self.Library.AccentColor });
		groupbox:AddLabel('Selected tab color'):AddColorPicker('SelectedTabColor', { Default = self.Library.SelectedTabColor });
		groupbox:AddLabel('Outline color'):AddColorPicker('OutlineColor', { Default = self.Library.OutlineColor });
		groupbox:AddLabel('Font color')	:AddColorPicker('FontColor', { Default = self.Library.FontColor });
		groupbox:AddLabel('Gradient color'):AddColorPicker('GradientColor', { Default = self.Library.GradientColor });

		local ThemesArray = {};
		for Name, Theme in next, self.BuiltInThemes do
			table.insert(ThemesArray, Name);
		end;

		table.sort(ThemesArray, function(a, b) return self.BuiltInThemes[a][1] < self.BuiltInThemes[b][1] end);

		groupbox:AddDivider();
		groupbox:AddDropdown('ThemeManager_ThemeList', { Text = 'Theme list', Values = ThemesArray, Default = 'Default' });

		groupbox:AddButton('Set as default', function()
			self:SaveDefault(Options.ThemeManager_ThemeList.Value);
			self.Library:Notify(string.format('Set default theme to %q', Options.ThemeManager_ThemeList.Value));
		end):AddButton('Test notification', function()
			self.Library:Notify('This is a test notification!');
		end);

		Options.ThemeManager_ThemeList:OnChanged(function()
			self:ApplyTheme(Options.ThemeManager_ThemeList.Value);
		end);

		groupbox:AddDivider();
		groupbox:AddDropdown('ThemeManager_CustomThemeList', { Text = 'Custom themes', Values = self:ReloadCustomThemes(), AllowNull = true, Default = 1 });
		groupbox:AddInput('ThemeManager_CustomThemeName', { Text = 'Custom theme name' });

		groupbox:AddButton('Load theme', function()
			self:ApplyTheme(Options.ThemeManager_CustomThemeList.Value);
		end):AddButton('Save theme', function()
			self:SaveCustomTheme(Options.ThemeManager_CustomThemeName.Value);

			Options.ThemeManager_CustomThemeList.Values = self:ReloadCustomThemes();
			Options.ThemeManager_CustomThemeList:SetValues();
			Options.ThemeManager_CustomThemeList:SetValue(nil);
		end);

		groupbox:AddButton('Refresh list', function()
			Options.ThemeManager_CustomThemeList.Values = self:ReloadCustomThemes();
			Options.ThemeManager_CustomThemeList:SetValues();
			Options.ThemeManager_CustomThemeList:SetValue(nil);
		end);

		groupbox:AddButton('Set as default', function()
			if Options.ThemeManager_CustomThemeList.Value ~= nil and Options.ThemeManager_CustomThemeList.Value ~= '' then
				self:SaveDefault(Options.ThemeManager_CustomThemeList.Value);
				self.Library:Notify(string.format('Set default theme to %q', Options.ThemeManager_CustomThemeList.Value));
			end;
		end);

		ThemeManager:LoadDefault();

		local function UpdateTheme()
			self:ThemeUpdate();
		end;

		Options.BackgroundColor:OnChanged(UpdateTheme);
		Options.MainColor:OnChanged(UpdateTheme);
		Options.AccentColor:OnChanged(UpdateTheme);
		Options.SelectedTabColor:OnChanged(UpdateTheme);
		Options.OutlineColor:OnChanged(UpdateTheme);
		Options.FontColor:OnChanged(UpdateTheme);
		Options.GradientColor:OnChanged(UpdateTheme);
	end;

	function ThemeManager:GetCustomTheme(file)
		local path = self.Folder .. '/themes/' .. file;
		if not isfile(path) then
			return nil;
		end;

		local data = readfile(path);
		local success, decoded = pcall(httpService.JSONDecode, httpService, data);

		if not success then
			return nil;
		end;

		return decoded;
	end;

	function ThemeManager:SaveCustomTheme(file)
		if file:gsub(' ', '') == '' then
			return self.Library:Notify('Invalid file name for theme (empty)', 3);
		end;

		local theme = {};
		local fields = { "FontColor", "MainColor", "AccentColor", "BackgroundColor", "OutlineColor", "SelectedTabColor", "GradientColor" };

		for _, field in next, fields do
			theme[field] = Options[field].Value:ToHex();
		end;

		writefile(self.Folder .. '/themes/' .. file .. '.json', httpService:JSONEncode(theme));
	end;

	function ThemeManager:ReloadCustomThemes()
		local list = listfiles(self.Folder .. '/themes');

		local out = {};
		for i = 1, #list do
			local file = list[i];
			if file:sub(-5) == '.json' then

				local pos = file:find('.json', 1, true);
				local char = file:sub(pos, pos);

				while char ~= '/' and char ~= '\\' and char ~= '' do
					pos = pos - 1;
					char = file:sub(pos, pos);
				end;

				if char == '/' or char == '\\' then
					table.insert(out, file:sub(pos + 1));
				end;
			end;
		end;

		return out;
	end;

	function ThemeManager:SetLibrary(lib)
		self.Library = lib;
	end;

	function ThemeManager:BuildFolderTree()
		local paths = {};

		local parts = self.Folder:split('/');
		for idx = 1, #parts do
			paths[#paths + 1] = table.concat(parts, '/', 1, idx);
		end;

		table.insert(paths, self.Folder .. '/themes');
		table.insert(paths, self.Folder .. '/settings');

		for i = 1, #paths do
			local str = paths[i];
			if not isfolder(str) then
				makefolder(str);
			end;
		end;
	end;

	function ThemeManager:SetFolder(folder)
		self.Folder = folder;
		self:BuildFolderTree();
	end;

	function ThemeManager:CreateGroupBox(tab)
		assert(self.Library, 'Must set ThemeManager.Library first!');
		return tab:AddLeftGroupbox('Themes');
	end;

	function ThemeManager:BuildAppearanceOverlay(Config)
		assert(self.Library, 'Must set ThemeManager.Library first!');

		Config = Config or {};
		local Overlay = self.Library:CreateOverlayWindow({
			Title = 'Appearance',
			AccentPart = 'ance',
			Size = UDim2.fromOffset(228, 72),
			Position = Config.Position or UDim2.fromOffset(700, 80),
			Visible = Config.Visible,
			ZIndex = Config.ZIndex or 165,
		});

		local Groupbox = Overlay:AddGroupbox({ Name = 'Overlay & theme' });
		self:CreateAppearanceManager(Groupbox, true);
		Groupbox:Resize();
		Overlay:Resize();
		self.AppearanceOverlay = Overlay;
		return Overlay;
	end;

	function ThemeManager:ApplyToTab(tab)
		assert(self.Library, 'Must set ThemeManager.Library first!');
		local groupbox = self:CreateGroupBox(tab);
		self:CreateThemeManager(groupbox);
	end;

	function ThemeManager:ApplyToGroupbox(groupbox)
		assert(self.Library, 'Must set ThemeManager.Library first!');
		self:CreateThemeManager(groupbox);
	end;

	ThemeManager:BuildFolderTree();
end;
return ThemeManager;
end)();
local SaveManager = (function()
    local httpService = game:GetService('HttpService');
    local SaveManager = {};

    SaveManager.Folder = 'skyware/rivals';
    SaveManager.Ignore = {};

    SaveManager.Parser = {
        Toggle = {
            Save = function(idx, object)
                return { type = 'Toggle', idx = idx, value = object.Value };
            end,
            Load = function(idx, data)
                local toggle = SaveManager.Library and SaveManager.Library.Toggles[idx];
                if toggle then
                    toggle:SetValue(data.value);
                end;
            end,
        },
        Slider = {
            Save = function(idx, object)
                return { type = 'Slider', idx = idx, value = tostring(object.Value) };
            end,
            Load = function(idx, data)
                local option = SaveManager.Library and SaveManager.Library.Options[idx];
                if option then
                    option:SetValue(data.value);
                end;
            end,
        },
        Dropdown = {
            Save = function(idx, object)
                return { type = 'Dropdown', idx = idx, value = object.Value, multi = object.Multi };
            end,
            Load = function(idx, data)
                local option = SaveManager.Library and SaveManager.Library.Options[idx];
                if option then
                    option:SetValue(data.value);
                end;
            end,
        },
        ColorPicker = {
            Save = function(idx, object)
                return { type = 'ColorPicker', idx = idx, value = object.Value:ToHex(), transparency = object.Transparency };
            end,
            Load = function(idx, data)
                local option = SaveManager.Library and SaveManager.Library.Options[idx];
                if option then
                    option:SetValueRGB(Color3.fromHex(data.value), data.transparency);
                end;
            end,
        },
        KeyPicker = {
            Save = function(idx, object)
                return { type = 'KeyPicker', idx = idx, mode = object.Mode, key = object.Value };
            end,
            Load = function(idx, data)
                local option = SaveManager.Library and SaveManager.Library.Options[idx];
                if option then
                    option:SetValue({ data.key, data.mode });
                end;
            end,
        },
        Input = {
            Save = function(idx, object)
                return { type = 'Input', idx = idx, text = object.Value };
            end,
            Load = function(idx, data)
                local option = SaveManager.Library and SaveManager.Library.Options[idx];
                if option and type(data.text) == 'string' then
                    option:SetValue(data.text);
                end;
            end,
        },
    };

    function SaveManager:SetLibrary(library)
        self.Library = library;
    end;

    -- ------------------------------------------------------------------
    -- Layout persistence: widgets, the Skyware (UI toggle) button and the
    -- mobile quick buttons. Saved as positions, restored on load.
    -- ------------------------------------------------------------------
    local function posToTable(p)
        return { p.X.Scale, p.X.Offset, p.Y.Scale, p.Y.Offset };
    end;

    local function validPos(t)
        return type(t) == 'table' and #t == 4
            and tonumber(t[1]) ~= nil and tonumber(t[2]) ~= nil
            and tonumber(t[3]) ~= nil and tonumber(t[4]) ~= nil;
    end;

    -- keep a restored position on screen (configs move between phone / PC / other window sizes)
    local function toUDim2(t)
        local sx, ox, sy, oy = tonumber(t[1]), tonumber(t[2]), tonumber(t[3]), tonumber(t[4]);
        local cam = workspace.CurrentCamera;
        if cam then
            local vp = cam.ViewportSize;
            if sx == 0 then ox = math.clamp(ox, 0, math.max(vp.X - 40, 0)); end;
            if sy == 0 then oy = math.clamp(oy, 0, math.max(vp.Y - 40, 0)); end;
        end;
        return UDim2.new(sx, ox, sy, oy);
    end;

    -- the Skyware toggle button + every mobile quick button that exists right now
    local function getButtons()
        local out = {};
        local toggleGui = getgenv().skyware_toggle_gui;
        local main = toggleGui and toggleGui:FindFirstChild('SkywareToggle');
        if main then out['__skyware'] = main; end;
        local quickGui = getgenv().skyware_quick_gui;
        if quickGui then
            for _, child in next, quickGui:GetChildren() do
                local key = child.Name:match('^SkywareQuick_(.+)$');
                if key and child:IsA('GuiObject') then
                    out[key] = child;
                end;
            end;
        end;
        return out;
    end;

    -- Applies widget / button positions. `done` remembers what was already applied, so
    -- calling this again only touches things that did not exist the first time.
    -- Returns how many entries are still waiting for their object to be created.
    function SaveManager:ApplyLayout(decoded, done)
        local waiting = 0;

        if type(decoded.widgets) == 'table' then
            local ws = getgenv().skyware_widgets;
            local vis = type(decoded.widget_visible) == 'table' and decoded.widget_visible or {};
            for wname, pos in next, decoded.widgets do
                local key = 'w:' .. tostring(wname);
                if not done[key] then
                    local overlay = type(ws) == 'table' and ws[wname] or nil;
                    if overlay and overlay.Outer then
                        if validPos(pos) then
                            pcall(function() overlay.Outer.Position = toUDim2(pos); end);
                        end;
                        if vis[wname] ~= nil and overlay.SetVisible then
                            pcall(function() overlay:SetVisible(vis[wname] == true); end);
                        end;
                        done[key] = true;
                    else
                        waiting = waiting + 1;
                    end;
                end;
            end;
        end;

        if type(decoded.buttons) == 'table' then
            local buttons = getButtons();
            for bname, pos in next, decoded.buttons do
                local key = 'b:' .. tostring(bname);
                if not done[key] then
                    local btn = buttons[bname];
                    if btn then
                        if validPos(pos) then
                            pcall(function() btn.Position = toUDim2(pos); end);
                        end;
                        done[key] = true;
                    else
                        waiting = waiting + 1;
                    end;
                end;
            end;
        end;

        return waiting;
    end;

    -- Controls that were in the config but did not exist yet when it loaded (built later
    -- during startup) are applied the moment they get created.
    SaveManager.PendingObjects = {};

    function SaveManager:InstallLateBinding()
        if self.LateBindingInstalled or not self.Library then return end;
        self.LateBindingInstalled = true;

        for _, registry in ipairs({ self.Library.Toggles, self.Library.Options }) do
            if type(registry) == 'table' and getmetatable(registry) == nil then
                setmetatable(registry, {
                    __newindex = function(tbl, idx, value)
                        rawset(tbl, idx, value);
                        local pending = SaveManager.PendingObjects[idx];
                        if pending then
                            SaveManager.PendingObjects[idx] = nil;
                            task.defer(function()
                                local parser = SaveManager.Parser[pending.type];
                                if parser then
                                    pcall(parser.Load, idx, pending);
                                end;
                            end);
                        end;
                    end;
                });
            end;
        end;
    end;

    function SaveManager:SetIgnoreIndexes(list)
        for _, key in next, list do
            self.Ignore[key] = true;
        end;
    end;

    function SaveManager:IgnoreThemeSettings()
        self:SetIgnoreIndexes({
            'BackgroundColor', 'MainColor', 'AccentColor', 'OutlineColor', 'FontColor', 'GradientColor', 'OverlayGlowColor',
            'ThemeManager_ThemeList', 'ThemeManager_CustomThemeList', 'ThemeManager_CustomThemeName',
        });
    end;

    function SaveManager:SetFolder(folder)
        self.Folder = folder;
        self:BuildFolderTree();
    end;

    function SaveManager:BuildFolderTree()
        local paths = {};
        local parts = self.Folder:split('/');
        for idx = 1, #parts do
            paths[#paths + 1] = table.concat(parts, '/', 1, idx);
        end;
        paths[#paths + 1] = self.Folder .. '/themes';
        paths[#paths + 1] = self.Folder .. '/settings';
        for i = 1, #paths do
            local str = paths[i];
            if not isfolder(str) then
                pcall(makefolder, str);
            end;
        end;
    end;

    function SaveManager:Save(name)
        if not name or name == '' then
            return false, 'no config file is selected';
        end;

        local fullPath = self.Folder .. '/settings/' .. name .. '.json';
        local data = { objects = {} };

        for idx, toggle in next, self.Library.Toggles do
            if self.Ignore[idx] or not self.Parser[toggle.Type] then
                continue;
            end;
            data.objects[#data.objects + 1] = self.Parser[toggle.Type].Save(idx, toggle);
        end;

        for idx, option in next, self.Library.Options do
            if self.Ignore[idx] or not self.Parser[option.Type] then
                continue;
            end;
            data.objects[#data.objects + 1] = self.Parser[option.Type].Save(idx, option);
        end;

        if self.Library.GetWindowSize then
            local x, y = self.Library:GetWindowSize();
            data.ui_size = { x, y };
        end

        do
            data.theme = {};
            local themeKeys = { 'AccentColor', 'BackgroundColor', 'MainColor', 'OutlineColor', 'FontColor', 'SelectedTabColor', 'GradientColor' };
            for _, k in next, themeKeys do
                local opt = self.Library.Options[k];
                if opt and opt.Value then
                    pcall(function() data.theme[k] = opt.Value:ToHex() end);
                end;
            end;
            if self.Library.Options.ThemeManager_ThemeList and self.Library.Options.ThemeManager_ThemeList.Value then
                data.theme.preset = self.Library.Options.ThemeManager_ThemeList.Value;
            end;
        end

        do
            data.widgets = {};
            data.widget_visible = {};
            local ws = getgenv().skyware_widgets;
            if type(ws) == 'table' then
                for wname, overlay in next, ws do
                    if overlay and overlay.Outer then
                        data.widgets[wname] = posToTable(overlay.Outer.Position);
                        data.widget_visible[wname] = not not overlay.Visible;
                    end;
                end;
            end;
        end;

        do
            -- Skyware (UI toggle) button + mobile quick buttons
            data.buttons = {};
            for bname, btn in next, getButtons() do
                data.buttons[bname] = posToTable(btn.Position);
            end;
        end;

        local success, encoded = pcall(httpService.JSONEncode, httpService, data);
        if not success then
            return false, 'failed to encode data';
        end;

        local okWrite = pcall(writefile, fullPath, encoded);
        if not okWrite then
            return false, 'failed to write file';
        end;
        return true;
    end;

    function SaveManager:Load(name)
        if not name or name == '' then
            return false, 'no config file is selected';
        end;

        local file = self.Folder .. '/settings/' .. name .. '.json';
        if not isfile(file) then
            return false, 'invalid file';
        end;

        local success, decoded = pcall(httpService.JSONDecode, httpService, readfile(file));
        if not success or type(decoded) ~= 'table' or type(decoded.objects) ~= 'table' then
            return false, 'decode error';
        end;

        self.LoadToken = (self.LoadToken or 0) + 1;
        local token = self.LoadToken;
        self.PendingObjects = {};
        self:InstallLateBinding();

        for _, option in next, decoded.objects do
            if type(option) == 'table' and option.type and self.Parser[option.type] then
                local registry = (option.type == 'Toggle') and self.Library.Toggles or self.Library.Options;
                if registry[option.idx] then
                    task.spawn(function()
                        pcall(self.Parser[option.type].Load, option.idx, option);
                    end);
                elseif option.idx ~= nil and not self.Ignore[option.idx] then
                    -- control is not built yet: remember it and apply on creation
                    self.PendingObjects[option.idx] = option;
                end;
            end;
        end;

        if type(decoded.ui_size) == 'table' and tonumber(decoded.ui_size[1]) and self.Library.SetWindowSize then
            pcall(function() self.Library:SetWindowSize(decoded.ui_size[1], decoded.ui_size[2]) end);
        end;

        if type(decoded.theme) == 'table' then
            local TM = getgenv().ThemeManager;
            if decoded.theme.preset and TM and TM.ApplyTheme then
                pcall(function()
                    TM:ApplyTheme(decoded.theme.preset);
                    if self.Library.Options.ThemeManager_ThemeList then
                        self.Library.Options.ThemeManager_ThemeList:SetValue(decoded.theme.preset);
                    end;
                end);
            end;
            for k, hex in next, decoded.theme do
                if k ~= 'preset' then
                    local opt = self.Library.Options[k];
                    if opt and opt.SetValueRGB then
                        pcall(function() opt:SetValueRGB(Color3.fromHex(hex)) end);
                    end;
                end;
            end;
        end;

        -- widgets + Skyware button + mobile quick buttons (retry for anything built late)
        local done = {};
        if self:ApplyLayout(decoded, done) > 0 then
            for _, delaySec in ipairs({ 0.5, 1.5, 4 }) do
                task.delay(delaySec, function()
                    if SaveManager.LoadToken == token then
                        pcall(function() SaveManager:ApplyLayout(decoded, done); end);
                    end;
                end);
            end;
        end;

        return true;
    end;

    function SaveManager:RefreshConfigList()
        local out = {};
        local ok, list = pcall(listfiles, self.Folder .. '/settings');
        if not ok or type(list) ~= 'table' then
            return out;
        end;

        for i = 1, #list do
            local file = list[i];
            if file:sub(-5) == '.json' then
                local stripped = file:sub(1, -6);
                local name = stripped:match('([^/\\]+)$');
                if name and name ~= '' then
                    out[#out + 1] = name;
                end;
            end;
        end;

        return out;
    end;

    function SaveManager:LoadAutoloadConfig()
        if isfile(self.Folder .. '/settings/autoload.txt') then
            local name = readfile(self.Folder .. '/settings/autoload.txt');
            name = (type(name) == 'string') and (name:gsub('^%s+', ''):gsub('%s+$', '')) or '';
            if name == '' then
                return
            end;

            local success, err = self:Load(name);
            if not success then
                if self.Library then
                    self.Library:Notify('Failed to load autoload config: ' .. tostring(err));
                end;
                return
            end;

            if self.Library then
                self.Library:Notify(string.format('Auto loaded config %q', name));
            end;
        end;
    end;

    function SaveManager:BuildConfigSection(tab)
        assert(self.Library, 'Must set SaveManager.Library');

        local section = tab:AddRightGroupbox('Configuration');

        section:AddInput('SaveManager_ConfigName', { Text = 'Config name' });
        section:AddDropdown('SaveManager_ConfigList', { Text = 'Config list', Values = self:RefreshConfigList(), AllowNull = true });

        local function refreshList()
            SaveManager.Library.Options.SaveManager_ConfigList:SetValues(SaveManager:RefreshConfigList());
            SaveManager.Library.Options.SaveManager_ConfigList:SetValue(nil);
        end;

        section:AddButton('Create config', function()
            local name = SaveManager.Library.Options.SaveManager_ConfigName.Value;
            if not name or name:gsub(' ', '') == '' then
                return SaveManager.Library:Notify('Invalid config name (empty)', 2);
            end;

            local success, err = SaveManager:Save(name);
            if not success then
                return SaveManager.Library:Notify('Failed to save config: ' .. tostring(err));
            end;

            SaveManager.Library:Notify(string.format('Created config %q', name));
            refreshList();
        end);

        section:AddButton('Load config', function()
            local name = SaveManager.Library.Options.SaveManager_ConfigList.Value;
            local success, err = SaveManager:Load(name);
            if not success then
                return SaveManager.Library:Notify('Failed to load config: ' .. tostring(err));
            end;

            SaveManager.Library:Notify(string.format('Loaded config %q', name));
        end);

        section:AddButton('Overwrite config', function()
            local name = SaveManager.Library.Options.SaveManager_ConfigList.Value;
            local success, err = SaveManager:Save(name);
            if not success then
                return SaveManager.Library:Notify('Failed to overwrite config: ' .. tostring(err));
            end;

            SaveManager.Library:Notify(string.format('Overwrote config %q', name));
        end);

        section:AddButton('Delete config', function()
            local name = SaveManager.Library.Options.SaveManager_ConfigList.Value;
            if not name then
                return SaveManager.Library:Notify('No config selected', 2);
            end;

            pcall(delfile, SaveManager.Folder .. '/settings/' .. name .. '.json');
            SaveManager.Library:Notify(string.format('Deleted config %q', name));
            refreshList();
        end);

        section:AddButton('Refresh list', refreshList);

        section:AddButton('Set as autoload', function()
            local name = SaveManager.Library.Options.SaveManager_ConfigList.Value;
            if not name then
                return SaveManager.Library:Notify('No config selected', 2);
            end;

            pcall(writefile, SaveManager.Folder .. '/settings/autoload.txt', name);
            SaveManager.AutoloadLabel:SetText('Current autoload config: ' .. name);
            SaveManager.Library:Notify(string.format('Set %q to auto load', name));
        end);

        section:AddButton('Clear autoload', function()
            pcall(delfile, SaveManager.Folder .. '/settings/autoload.txt');
            SaveManager.AutoloadLabel:SetText('Current autoload config: none');
            SaveManager.Library:Notify('Cleared autoload');
        end);

        SaveManager.AutoloadLabel = section:AddLabel('Current autoload config: none', true);

        if isfile(self.Folder .. '/settings/autoload.txt') then
            local name = readfile(self.Folder .. '/settings/autoload.txt');
            if name and name ~= '' then
                SaveManager.AutoloadLabel:SetText('Current autoload config: ' .. name);
            end;
        end;

        SaveManager:SetIgnoreIndexes({ 'SaveManager_ConfigName', 'SaveManager_ConfigList' });
    end;

    SaveManager:BuildFolderTree();

    return SaveManager;
end)();

local Trove = (function()
    local Trove = {};
    Trove.__index = Trove;

    function Trove.new()
        return setmetatable({ _objects = {} }, Trove);
    end;

    function Trove:Add(object)
        self._objects[#self._objects + 1] = object;
        return object;
    end;

    function Trove:Destroy()
        local objects = self._objects;
        self._objects = {};
        for i = #objects, 1, -1 do
            local object = objects[i];
            local objectType = typeof(object);
            pcall(function()
                if objectType == 'RBXScriptConnection' then
                    object:Disconnect();
                elseif objectType == 'Instance' then
                    object:Destroy();
                elseif objectType == 'thread' then
                    task.cancel(object);
                elseif objectType == 'function' then
                    object();
                elseif objectType == 'table' then
                    if object.Destroy then
                        object:Destroy();
                    elseif object.Disconnect then
                        object:Disconnect();
                    end;
                end;
            end);
        end;
    end;

    Trove.Clean = Trove.Destroy;

    return Trove;
end)();

if not (type(Library) == "table" and Library.Options) then
    Library = getgenv().Library or Library;
end;
getgenv().Library = Library;
local Options = Library.Options;
local Toggles = Library.Toggles;
getgenv().silent_load = getgenv().silent_load or false;
getgenv().auto_load_enable = getgenv().auto_load_enable or false;
local Window = Library:CreateWindow({
    Title = 'Skyware',
    AutoShow = false,
    BackgroundImage = "",
    SubTitle = "Rivals",
    Center = true,
    Resizable = true,
    Draggable = true,
    Size = ((game:GetService('UserInputService').TouchEnabled and not game:GetService('UserInputService').MouseEnabled) and UDim2.fromOffset(520, 420)) or UDim2.fromOffset(740, 660),
});

if GLOBAL_TROVE then
    pcall(function()
        GLOBAL_TROVE:Destroy();
    end);
end;
local trove = Trove.new();
getgenv().GLOBAL_TROVE = trove;

Library:OnUnload(function()
    pcall(function()
        GLOBAL_TROVE:Destroy();
    end);
    getgenv().skyware_loaded = false;
    getgenv().SkywareRan = nil;
    getgenv().Library.Unloaded = true;
    getgenv().Library = nil;
end);

local font_indexes = {"ProggyClean", "Tahoma", "Verdana", "SmallestPixel", "ProggyTiny", "Minecraftia", "Tahoma Bold"};

local font_files = {
    ["ProggyClean"] = "ProggyClean.ttf",
    ["Tahoma"] = "fs-tahoma-8px.ttf",
    ["Verdana"] = "Verdana-Font.ttf",
    ["SmallestPixel"] = "smallest_pixel-7.ttf",
    ["ProggyTiny"] = "ProggyTiny.ttf",
    ["Minecraftia"] = "Minecraftia-Regular.ttf",
    ["Tahoma Bold"] = "tahoma_bold.ttf",
};

getgenv().fonts = {};
local fonts = getgenv().fonts;

local Tabs = {};

Library.ToggleKeybind = { Value = 'RightShift' };
pcall(function()
    local UIS = game:GetService('UserInputService');
    UIS.InputBegan:Connect(function(input, processed)
        if not processed and input.KeyCode == Enum.KeyCode.RightShift then
            pcall(function() Library:Toggle() end);
        end;
    end);
end);

pcall(function()
    local gui = Instance.new('ScreenGui');
    gui.Name = 'skyware_toggle';
    gui.ResetOnSpawn = false;
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Global;
    gui.DisplayOrder = 100000;
    pcall(function() if syn and syn.protect_gui then syn.protect_gui(gui) end end);
    local ok = pcall(function() gui.Parent = (gethui and gethui()) or cloneref(game:GetService('CoreGui')) end);
    if not ok then pcall(function() gui.Parent = cloneref(game:GetService('CoreGui')) end) end;
    getgenv().skyware_toggle_gui = gui;

    local btn = Library:Create('TextButton', {
        Name = 'SkywareToggle';
        Size = UDim2.fromOffset(92, 24);
        Position = UDim2.fromOffset(12, 12);
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.OutlineColor;
        BorderSizePixel = 1;
        AutoButtonColor = false;
        Text = 'Skyware';
        TextColor3 = Library.FontColor;
        TextSize = 14;
        ZIndex = 5000;
        Parent = gui;
    });
    Library:AddToRegistry(btn, { BackgroundColor3 = 'MainColor'; BorderColor3 = 'OutlineColor'; TextColor3 = 'FontColor'; });
    local bar = Library:Create('Frame', {
        BackgroundColor3 = Library.AccentColor;
        BorderSizePixel = 0;
        Size = UDim2.new(1, 0, 0, 2);
        ZIndex = 5001;
        Parent = btn;
    });
    Library:AddToRegistry(bar, { BackgroundColor3 = 'AccentColor' });
    btn.MouseButton1Click:Connect(function() pcall(function() Library:Toggle() end) end);
    pcall(function() Library:MakeDraggable(btn) end);
    pcall(function() Library:OnUnload(function() gui:Destroy() end) end);
end);

pcall(function()
    local holder = Window and Window.Holder;
    if not holder or holder:FindFirstChild('SkywareResizer') then return end;
    local uis = game:GetService('UserInputService');
    local handle = Instance.new('Frame');
    handle.Name = 'SkywareResizer';
    handle.AnchorPoint = Vector2.new(1, 1);
    handle.Position = UDim2.new(1, 0, 1, 0);
    handle.Size = UDim2.fromOffset(14, 14);
    handle.BackgroundTransparency = 1;
    handle.BorderSizePixel = 0;
    handle.ZIndex = 9999;
    handle.Active = true;
    handle.Parent = holder;
    local dragging, startPos, startSize = false, nil, nil;
    local touchUi = uis.TouchEnabled and not uis.MouseEnabled;
    local minW, minH = touchUi and 320 or 480, touchUi and 260 or 360;
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging, startPos, startSize = true, i.Position, holder.AbsoluteSize;
        end;
    end);
    uis.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - startPos;
            holder.Size = UDim2.fromOffset(math.max(minW, startSize.X + d.X), math.max(minH, startSize.Y + d.Y));
        end;
    end);
    uis.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end;
    end);
end);


-- ======================================================================
--  Rivals feature set (merged from the old Skyware script)
-- ======================================================================
local okOld, errOld = xpcall(function()
local window = (function()
-- ======================================================================
--  Skyware bridge: runs the old feature code on this menu's Library.
--  Old API (window:CreateTab, tab:Section/Toggle/Slider/Cycle/...) is
--  translated to Tab:AddLeft/RightGroupbox + Add* controls.
-- ======================================================================
local HttpService = game:GetService("HttpService")
local DIR = "Skyware"
local CFG_DIR = DIR .. "/configs"
local EXPORT_DIR = DIR .. "/exports"
local IMPORT_DIR = DIR .. "/import"

local flags = {}
local loadingConfig = false
local autoId = 0
local window = { Tabs = {}, Flags = flags }

local function noop() end
local function noopObj()
    return setmetatable({}, { __index = function() return noop end })
end
local function uid(prefix)
    autoId += 1
    return prefix .. "_" .. autoId
end
local function registerFlag(name, get, set)
    if name and not flags[name] then flags[name] = { get = get, set = set } end
end
local function freeId(flag, prefix)
    if flag and not Library.Toggles[flag] and not Library.Options[flag] then return flag end
    return uid(prefix)
end

-- ---------------------------------------------------------------- tabs
local Tab = {}
Tab.__index = Tab

function window:CreateTab(o)
    local lt = Window:AddTab(o.name)
    getgenv().__SkywareTabs = getgenv().__SkywareTabs or {}
    getgenv().__SkywareTabs[o.name] = lt
    local tab = setmetatable({ _tab = lt, _name = o.name, _w = { 0, 0 }, _gb = nil, _side = 1 }, Tab)
    window.Tabs[#window.Tabs + 1] = tab
    return tab
end

function Tab:Select()
    pcall(function() self._tab:ShowTab() end)
end

function Tab:Section(name)
    local side = (self._w[1] <= self._w[2]) and 1 or 2
    local gb
    if side == 1 then gb = self._tab:AddLeftGroupbox(name) else gb = self._tab:AddRightGroupbox(name) end
    self._gb, self._side = gb, side
    self._w[side] += 2
    return self
end
function Tab:Divider(name) return self:Section(name) end

local function gbOf(self)
    if not self._gb then self:Section(self._name) end
    return self._gb
end

-- a Grid is just the group that was current when it was made
function Tab:Grid()
    local gb = gbOf(self)
    return setmetatable({ _tab = self._tab, _name = self._name, _w = self._w, _gb = gb, _side = self._side }, Tab)
end

function Tab:Toggle(o)
    local gb = gbOf(self)
    self._w[self._side] += 1
    local id = freeId(o.flag, "tg")
    local api = { value = o.value == true }
    local building, muted = true, false
    gb:AddToggle(id, {
        Text = o.name or "",
        Default = api.value,
        Tooltip = o.description,
        Callback = function(v)
            api.value = v
            if building or muted then return end
            if o.callback then task.spawn(o.callback, v) end
        end,
    })
    building = false
    local ctl = Library.Toggles[id]
    function api:Set(v, silent)
        v = v == true
        muted = silent == true
        if ctl then pcall(function() ctl:SetValue(v) end) end
        muted = false
        api.value = v
    end
    registerFlag(o.flag, function() return api.value end, function(v) api:Set(v) end)
    return api
end

function Tab:BigToggle(o)
    return self:Toggle({
        name = o.title, description = o.warning, flag = o.flag,
        value = o.value, callback = o.callback,
    })
end

function Tab:Slider(o)
    local gb = gbOf(self)
    self._w[self._side] += 2
    local id = freeId(o.flag, "sl")
    local min, max = o.range[1], o.range[2]
    local inc = o.increment or 1
    local rounding = 0
    if inc < 1 then rounding = math.clamp(math.ceil(-math.log10(inc) - 1e-9), 1, 3) end
    local api = { value = math.clamp(o.value or min, min, max) }
    local building, muted = true, false
    gb:AddSlider(id, {
        Text = o.name or "",
        Default = api.value,
        Min = min, Max = max,
        Rounding = rounding,
        Suffix = o.suffix or "",
        Callback = function(v)
            api.value = v
            if building or muted then return end
            if o.callback then task.spawn(o.callback, v, false) end
        end,
    })
    building = false
    local ctl = Library.Options[id]
    function api:Set(v, silent)
        muted = silent == true
        if ctl then pcall(function() ctl:SetValue(v) end) end
        muted = false
        api.value = v
    end
    registerFlag(o.flag, function() return api.value end, function(v) api:Set(v) end)
    return api
end

function Tab:Cycle(o)
    local gb = gbOf(self)
    self._w[self._side] += 2
    local id = freeId(o.flag, "cy")
    local opts = o.options or {}
    if #opts == 0 then opts = { "" } end
    local idx = table.find(opts, o.value) or 1
    local api = { options = opts, value = opts[idx] }
    local building, muted = true, false
    gb:AddDropdown(id, {
        Values = opts, Default = idx, Multi = false, Text = o.name or "",
        Callback = function(v)
            api.value = v
            if building or muted then return end
            if o.callback then task.spawn(o.callback, v) end
        end,
    })
    building = false
    local ctl = Library.Options[id]
    function api:Set(v, silent)
        if not table.find(api.options, v) then return end
        muted = silent == true
        if ctl then pcall(function() ctl:SetValue(v) end) end
        muted = false
        api.value = v
    end
    function api:Refresh(newOptions)
        if #newOptions == 0 then newOptions = { "" } end
        api.options = newOptions
        if ctl then pcall(function() ctl:SetValues(newOptions) end) end
    end
    if not o.forgetState then
        registerFlag(o.flag, function() return api.value end, function(v) api:Set(v) end)
    end
    return api
end

function Tab:Input(o)
    local gb = gbOf(self)
    self._w[self._side] += 2
    local id = freeId(o.flag, "in")
    local api = {}
    local building, muted = true, false
    gb:AddInput(id, {
        Text = o.name or "", Default = o.value or "", Numeric = o.numeric == true,
        Finished = true, Placeholder = o.placeholder or "", Tooltip = o.description,
        Callback = function(v)
            if building or muted then return end
            if o.callback then task.spawn(o.callback, v) end
        end,
    })
    building = false
    local ctl = Library.Options[id]
    function api:Set(v, silent)
        muted = silent == true
        if ctl then pcall(function() ctl:SetValue(tostring(v)) end) end
        muted = false
    end
    function api:Get() return ctl and ctl.Value or "" end
    if not o.forgetState then
        registerFlag(o.flag, function() return api:Get() end, function(v) api:Set(v) end)
    end
    return api
end

function Tab:Keybind(o)
    local gb = gbOf(self)
    self._w[self._side] += 1
    local id = freeId(o.flag, "kb")
    local kb = { key = o.value }
    local building, muted = true, false
    local label = gb:AddLabel(o.name or "Key")
    label:AddKeyPicker(id, {
        Default = (o.value and o.value.Name) or "None",
        Mode = o.hold and "Hold" or "Toggle",
        Text = o.name or "Key",
        Callback = function(state)
            if building or muted or not o.callback then return end
            if o.hold then task.spawn(o.callback, state and true or false) else task.spawn(o.callback) end
        end,
        ChangedCallback = function(new)
            kb.key = typeof(new) == "EnumItem" and new or nil
            if building or muted then return end
            if o.onChanged then task.spawn(o.onChanged, kb.key) end
        end,
    })
    building = false
    local ctl = Library.Options[id]
    function kb:SetKey(k, silent)
        muted = silent == true
        self.key = k
        if ctl then pcall(function() ctl:SetValue({ k and k.Name or "None", ctl.Mode or "Toggle" }) end) end
        muted = false
    end
    registerFlag(o.flag, function() return kb.key or false end,
        function(v) kb:SetKey(typeof(v) == "EnumItem" and v or nil, true) end)
    return kb
end

function Tab:Color(o)
    local gb = gbOf(self)
    self._w[self._side] += 1
    local id = freeId(o.flag, "co")
    local api = { value = o.color or Color3.new(1, 1, 1) }
    local building, muted = true, false
    local label = gb:AddLabel(o.name or "Color")
    label:AddColorPicker(id, {
        Default = api.value, Title = o.name or "Color",
        Callback = function(c)
            api.value = c
            if building or muted then return end
            if o.callback then task.spawn(o.callback, c) end
        end,
    })
    building = false
    local ctl = Library.Options[id]
    function api:Set(c, silent)
        muted = silent == true
        if ctl then pcall(function() ctl:SetValueRGB(c) end) end
        muted = false
        api.value = c
    end
    registerFlag(o.flag, function() return api.value end, function(v) api:Set(v) end)
    return api
end

-- several color pickers on one row: o.name label, o.items = { { flag, color, callback, title }, ... }
function Tab:Colors(o)
    local gb = gbOf(self)
    self._w[self._side] += 1
    local label = gb:AddLabel(o.name or "Colors")
    for _, it in ipairs(o.items) do
        local id = freeId(it.flag, "co")
        local api = { value = it.color or Color3.new(1, 1, 1) }
        local building, muted = true, false
        label:AddColorPicker(id, {
            Default = api.value, Title = it.title or o.name or "Color",
            Callback = function(c)
                api.value = c
                if building or muted then return end
                if it.callback then task.spawn(it.callback, c) end
            end,
        })
        building = false
        local ctl = Library.Options[id]
        function api:Set(c, silent)
            muted = silent == true
            if ctl then pcall(function() ctl:SetValueRGB(c) end) end
            muted = false
            api.value = c
        end
        registerFlag(it.flag, function() return api.value end, function(v) api:Set(v) end)
    end
end

function Tab:Buttons(defs)
    local gb = gbOf(self)
    for _, d in ipairs(defs) do
        self._w[self._side] += 1
        gb:AddButton({ Text = d.name or "Button", Func = d.callback or noop })
    end
end
function Tab:WideButton(o)
    local gb = gbOf(self)
    self._w[self._side] += 1
    gb:AddButton({ Text = o.name or "Button", Func = o.callback or noop })
end

function Tab:Text(o)
    local gb = gbOf(self)
    self._w[self._side] += 2
    local prefix = o.name and (o.name .. ": ") or ""
    local label = gb:AddLabel(prefix .. (o.text or ""), true)
    local last
    local api = {}
    function api:Set(t)
        t = tostring(t)
        if t == last then return end
        last = t
        pcall(function() label:SetText(prefix .. t) end)
    end
    return api
end

function Tab:Progress(o)
    local gb = gbOf(self)
    self._w[self._side] += 1
    local label = gb:AddLabel((o.name or "") .. ": -")
    local fmt = o.format or function(v) return string.format("%d", math.floor(v + 0.5)) end
    local last
    local api = { value = o.value or 0 }
    function api:Set(v)
        api.value = v
        local t
        if o.stageNames then
            t = o.stageNames[math.clamp(math.floor(v) + 1, 1, #o.stageNames)] or tostring(v)
        else
            t = fmt(v)
        end
        if t == last then return end
        last = t
        pcall(function() label:SetText((o.name or "") .. ": " .. t) end)
    end
    api:Set(api.value)
    return api
end

function Tab:Stats(defs)
    local gb = gbOf(self)
    local out = {}
    for i, d in ipairs(defs) do
        self._w[self._side] += 1
        local label = gb:AddLabel((d.name or "") .. ": -")
        local last
        out[i] = {
            Set = function(_, v)
                local t = tostring(v)
                if t == last then return end
                last = t
                pcall(function() label:SetText((d.name or "") .. ": " .. t) end)
            end,
        }
    end
    return out
end

function Tab:Console(o)
    local lines, max = {}, o.maxLines or 200
    local api = {}
    function api:Append(line)
        lines[#lines + 1] = tostring(line)
        if #lines > max then table.remove(lines, 1) end
    end
    function api:Clear() lines = {} end
    function api:Copy()
        local ok = pcall(function() setclipboard(table.concat(lines, "\n")) end)
        return ok
    end
    return api
end

-- ---------------------------------------------------------------- window
function window:Toast(o)
    o = o or {}
    local t = tostring(o.title or o.content or "")
    if o.subtitle then t = t .. ": " .. tostring(o.subtitle) end
    if o.content and o.title then t = t .. " - " .. tostring(o.content) end
    pcall(function() Library:Notify(t, o.duration or 3) end)
end
function window:Notify(o) return window:Toast(o) end

function window:Popup(o)
    local gui = Instance.new("ScreenGui")
    gui.Name = "SkywarePopup"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 100001
    gui.IgnoreGuiInset = true
    pcall(function() if syn and syn.protect_gui then syn.protect_gui(gui) end end)
    gui.Parent = (gethui and gethui()) or game:GetService("CoreGui")

    local function close() pcall(function() gui:Destroy() end) end

    local dim = Instance.new("TextButton")
    dim.Size = UDim2.fromScale(1, 1)
    dim.BackgroundColor3 = Color3.new(0, 0, 0)
    dim.BackgroundTransparency = 0.5
    dim.Text = ""
    dim.AutoButtonColor = false
    dim.Parent = gui
    if o.dismissable ~= false then dim.Activated:Connect(close) end

    local card = Instance.new("Frame")
    card.AnchorPoint = Vector2.new(0.5, 0.5)
    card.Position = UDim2.fromScale(0.5, 0.5)
    card.Size = UDim2.fromOffset(340, 0)
    card.AutomaticSize = Enum.AutomaticSize.Y
    card.BackgroundColor3 = Library.MainColor
    card.BorderColor3 = Library.AccentColor
    card.Parent = gui
    local pad = Instance.new("UIPadding", card)
    pad.PaddingLeft, pad.PaddingRight = UDim.new(0, 12), UDim.new(0, 12)
    pad.PaddingTop, pad.PaddingBottom = UDim.new(0, 12), UDim.new(0, 12)
    local list = Instance.new("UIListLayout", card)
    list.Padding = UDim.new(0, 8)
    list.SortOrder = Enum.SortOrder.LayoutOrder

    local order = 0
    local function label(text, size, color)
        order += 1
        local l = Instance.new("TextLabel")
        l.BackgroundTransparency = 1
        l.Size = UDim2.new(1, 0, 0, 0)
        l.AutomaticSize = Enum.AutomaticSize.Y
        l.TextWrapped = true
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.Font = Enum.Font.Code
        l.TextSize = size
        l.TextColor3 = color or Library.FontColor
        l.Text = text
        l.LayoutOrder = order
        l.Parent = card
    end
    if o.title then label(tostring(o.title), 16) end
    if o.subtitle then label(tostring(o.subtitle), 12, Color3.fromRGB(160, 160, 160)) end
    if o.content then label(tostring(o.content), 13) end
    for _, b in ipairs(o.boxes or {}) do
        label((b.title or "") .. " - " .. (b.description or ""), 12)
    end

    order += 1
    local row = Instance.new("Frame")
    row.BackgroundTransparency = 1
    row.Size = UDim2.new(1, 0, 0, 26)
    row.LayoutOrder = order
    row.Parent = card
    local rl = Instance.new("UIListLayout", row)
    rl.FillDirection = Enum.FillDirection.Horizontal
    rl.Padding = UDim.new(0, 6)
    rl.HorizontalAlignment = Enum.HorizontalAlignment.Right
    for _, opt in ipairs(o.options or { { text = "OK" } }) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.fromOffset(96, 26)
        btn.BackgroundColor3 = (opt.style == "danger") and Color3.fromRGB(160, 50, 50)
            or (opt.style == "primary") and Library.AccentColor or Library.MainColor
        btn.BorderColor3 = Library.OutlineColor
        btn.TextColor3 = Library.FontColor
        btn.Font = Enum.Font.Code
        btn.TextSize = 13
        btn.Text = opt.text or "OK"
        btn.Parent = row
        btn.Activated:Connect(function()
            close()
            if opt.callback then task.spawn(opt.callback) end
        end)
    end
    return { Close = close }
end

local quickGui, quickCount = nil, 0
-- positions of the Skyware button + quick buttons, saved/loaded with the config
local quickBtns, pendingPos = {}, {}
local function posGet(b)
    local p = b.Position
    return { p.X.Scale, p.X.Offset, p.Y.Scale, p.Y.Offset }
end
local function posSet(b, t)
    if b and type(t) == "table" and #t == 4 then
        b.Position = UDim2.new(t[1], t[2], t[3], t[4])
    end
end
local function skywareBtn()
    local g = getgenv().skyware_toggle_gui
    return g and g:FindFirstChild("SkywareToggle")
end
registerFlag("__ButtonPositions", function()
    local out = {}
    local sb = skywareBtn()
    if sb then out.__skyware = posGet(sb) end
    for key, b in pairs(quickBtns) do out[key] = posGet(b) end
    return out
end, function(v)
    if type(v) ~= "table" then return end
    for key, t in pairs(v) do
        if key == "__skyware" then posSet(skywareBtn(), t)
        elseif quickBtns[key] then posSet(quickBtns[key], t)
        else pendingPos[key] = t end
    end
end)
local function ensureQuickGui()
    if quickGui then return end
    quickGui = Instance.new("ScreenGui")
    quickGui.Name = "SkywareQuick"
    quickGui.ResetOnSpawn = false
    quickGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    quickGui.DisplayOrder = 99999
    pcall(function() if syn and syn.protect_gui then syn.protect_gui(quickGui) end end)
    quickGui.Parent = (gethui and gethui()) or game:GetService("CoreGui")
    getgenv().skyware_quick_gui = quickGui -- SaveManager reads button positions from here
    -- quick buttons only show while the menu is closed
    task.spawn(function()
        while quickGui and quickGui.Parent do
            quickGui.Enabled = not Library.MenuOpen
            task.wait(0.15)
        end
    end)
end

function window:QuickToggle(o)
    ensureQuickGui()
    quickCount += 1
    local state = false
    local enabled = o.visible ~= false
    -- identical build to the Skyware toggle button (size, colours, accent bar)
    local btn = Library:Create('TextButton', {
        Name = 'SkywareQuick_' .. tostring(o.key or quickCount);
        Size = UDim2.fromOffset(92, 24);
        Position = UDim2.fromOffset(12, 12 + quickCount * 30);
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.OutlineColor;
        BorderSizePixel = 1;
        AutoButtonColor = false;
        Text = tostring(o.label or o.key or "?");
        TextColor3 = Library.FontColor;
        TextSize = 14;
        ZIndex = 5000;
        Visible = enabled;
        Parent = quickGui;
    })
    Library:AddToRegistry(btn, { BackgroundColor3 = 'MainColor' })
    local posKey = tostring(o.key or quickCount)
    quickBtns[posKey] = btn
    if pendingPos[posKey] then posSet(btn, pendingPos[posKey]) pendingPos[posKey] = nil end
    local bar = Library:Create('Frame', {
        BackgroundColor3 = Library.AccentColor;
        BorderSizePixel = 0;
        Size = UDim2.new(1, 0, 0, 2);
        ZIndex = 5001;
        Parent = btn;
    })
    Library:AddToRegistry(bar, { BackgroundColor3 = 'AccentColor' })
    local function refresh()
        -- off = exactly the Skyware button, on = accent text + accent border
        btn.TextColor3 = state and Library.AccentColor or Library.FontColor
        btn.BorderColor3 = state and Library.AccentColor or Library.OutlineColor
    end
    refresh()

    -- same drag as the Skyware button (ghost preview, drops where you release)
    pcall(function() Library:MakeDraggable(btn) end)

    -- tap = toggle; a press that travelled is a drag and does not toggle
    local startPos
    btn.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
            startPos = Vector2.new(i.Position.X, i.Position.Y)
        end
    end)
    btn.InputEnded:Connect(function(i)
        if not startPos then return end
        if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
            local moved = (Vector2.new(i.Position.X, i.Position.Y) - startPos).Magnitude > 8
            startPos = nil
            if not moved and o.callback then task.spawn(o.callback, not state) end
        end
    end)
    return {
        Set = function(v) state = v == true refresh() end,
        Show = function(v) enabled = v == true btn.Visible = enabled end,
    }
end
function window:QuickCustomize()
    pcall(function() Library:Notify("Close the menu, then drag the quick buttons where you want them", 5) end)
end
function window:CreateTag() end
function window:Show() end
function window:Hide() pcall(function() Library:Toggle() end) end
function window:ToggleHide() pcall(function() Library:Toggle() end) end
function window:GetScale() return 1 end
function window:SetScale() end
function window:SetBlur() end
function window:SetLocale() end
function window:ChangeTheme() end
function window:Navigate(name)
    for _, t in ipairs(window.Tabs) do
        if t._name == name then t:Select() return end
    end
end

-- ---------------------------------------------------------------- configs

        local function ensureDirs()
            pcall(function()
                if makefolder then
                    if not isfolder(DIR) then makefolder(DIR) end
                    if not isfolder(CFG_DIR) then makefolder(CFG_DIR) end
                    if not isfolder(EXPORT_DIR) then makefolder(EXPORT_DIR) end
                    if not isfolder(IMPORT_DIR) then makefolder(IMPORT_DIR) end
                end
            end)
        end
        local function encode(v)
            local t = typeof(v)
            if t == "Color3" then return { c = { v.R, v.G, v.B } } end
            if t == "EnumItem" then return { k = v.Name } end
            return v
        end
        local function decode(v)
            if type(v) == "table" then
                if v.c then return Color3.new(v.c[1], v.c[2], v.c[3]) end
                if v.k then return Enum.KeyCode[v.k] end
            end
            return v
        end
        local function clean(name) return (tostring(name):gsub("[^%w%-_ ]", "")) end

        function window:Set(flag, value)
            local f = flags[flag]
            if f then f.set(value) end
        end
        function window:Save(name)
            ensureDirs()
            local data = {}
            for flag, f in pairs(flags) do data[flag] = encode(f.get()) end
            pcall(function() writefile(CFG_DIR .. "/" .. clean(name) .. ".json", HttpService:JSONEncode(data)) end)
        end
        function window:Load(name)
            local ok, raw = pcall(function() return readfile(CFG_DIR .. "/" .. clean(name) .. ".json") end)
            if not ok then return false end
            local ok2, data = pcall(function() return HttpService:JSONDecode(raw) end)
            if not ok2 then return false end
            loadingConfig = true
            for flag, val in pairs(data) do
                local f = flags[flag]
                if f then pcall(function() f.set(decode(val)) end) end
            end
            loadingConfig = false
            return true
        end
        -- true while a config is being applied (used to keep toggles from spamming toasts)
        function window:IsLoadingConfig() return loadingConfig end
        function window:ListConfigs()
            local out = {}
            pcall(function()
                for _, path in ipairs(listfiles(CFG_DIR)) do
                    local n = path:match("([^/\\]+)%.json$")
                    if n and n:sub(1, 1) ~= "_" then out[#out + 1] = n end
                end
            end)
            return out
        end
        function window:DeleteConfig(name)
            pcall(function() delfile(CFG_DIR .. "/" .. clean(name) .. ".json") end)
        end
        -- returns true, finalName  or  false, reason
        function window:RenameConfig(old, new)
            local newClean = clean(new)
            if newClean == "" then return false, "type a new name first" end
            if newClean:sub(1, 1) == "_" then return false, "names can't start with _" end
            if self:ConfigExists(newClean) then return false, "that name is already taken" end
            local ok, raw = pcall(readfile, CFG_DIR .. "/" .. clean(old) .. ".json")
            if not ok then return false, "couldn't read the old config" end
            local wrote = pcall(writefile, CFG_DIR .. "/" .. newClean .. ".json", raw)
            if not wrote then return false, "couldn't save the new name" end
            self:DeleteConfig(old)
            return true, newClean
        end
        function window:ConfigExists(name)
            local ok, exists = pcall(isfile, CFG_DIR .. "/" .. clean(name) .. ".json")
            return ok and exists == true
        end

        -- Export / import ------------------------------------------------------
        -- Config files are plain JSON (settings only, no code), so sharing one is safe.
        window.ImportDir = IMPORT_DIR
        window.ExportDir = EXPORT_DIR

        -- the settings you have on RIGHT NOW as JSON text
        function window:ExportConfigText()
            local data = {}
            for flag, f in pairs(flags) do data[flag] = encode(f.get()) end
            return HttpService:JSONEncode(data)
        end
        -- writes them to Skyware/exports/<name>.json, returns the path (or nil)
        function window:ExportConfig(name)
            ensureDirs()
            local base = clean(name)
            if base == "" then base = "Skyware Config" end
            local path = EXPORT_DIR .. "/" .. base .. ".json"
            local ok = pcall(function() writefile(path, self:ExportConfigText()) end)
            return ok and path or nil
        end
        -- files waiting in Skyware/import
        function window:ListImports()
            ensureDirs()
            local out = {}
            pcall(function()
                for _, path in ipairs(listfiles(IMPORT_DIR)) do
                    local n = path:match("([^/\\]+)%.json$")
                    if n then out[#out + 1] = n end
                end
            end)
            table.sort(out)
            return out
        end
        -- adds config text to your saved configs. returns name, settingsCount  or  nil, reason
        function window:ImportConfigText(raw, name)
            if type(raw) ~= "string" or raw == "" then return nil, "that file is empty" end
            local ok, data = pcall(function() return HttpService:JSONDecode(raw) end)
            if not ok or type(data) ~= "table" then return nil, "that isn't a valid config file" end
            local filtered, matched = {}, 0
            for flag, val in pairs(data) do
                if flags[flag] then filtered[flag] = val matched = matched + 1 end
            end
            if matched == 0 then return nil, "no Skyware settings found in that file" end
            ensureDirs()
            local base = clean(name or "")
            if base == "" then base = "Imported" end
            local final, n = base, 2
            while self:ConfigExists(final) do final = base .. " " .. n n = n + 1 end
            local saved = pcall(function()
                writefile(CFG_DIR .. "/" .. final .. ".json", HttpService:JSONEncode(filtered))
            end)
            if not saved then return nil, "couldn't save it" end
            return final, matched
        end
        function window:ImportConfig(path, name)
            local ok, raw = pcall(readfile, path)
            if not ok then return nil, "couldn't find that file" end
            return self:ImportConfigText(raw, name)
        end

        -- auto load: one config name remembered in Skyware/configs/_autoload.json
        -- (leading "_" keeps it out of the saved-configs list)
        local AUTOLOAD_FILE = CFG_DIR .. "/_autoload.json"
        function window:GetAutoLoad()
            local ok, raw = pcall(readfile, AUTOLOAD_FILE)
            if not ok then return nil end
            local ok2, data = pcall(function() return HttpService:JSONDecode(raw) end)
            if ok2 and type(data) == "table" and type(data.name) == "string" and data.name ~= "" then
                return data.name
            end
            return nil
        end
        function window:SetAutoLoad(name)
            ensureDirs()
            pcall(writefile, AUTOLOAD_FILE, HttpService:JSONEncode({ name = clean(name) }))
        end
        function window:ClearAutoLoad()
            pcall(function()
                if isfile(AUTOLOAD_FILE) then delfile(AUTOLOAD_FILE) end
            end)
        end


return window
end)()

local function notify(msg)
    warn("[Skyware] " .. msg)
    if getgenv().SkywareNotifications == false then return end
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", { Title = "Skyware", Text = msg, Duration = 8 })
    end)
end

local LOGO = "rbxassetid://121472117628036" -- your logo (circular header/sidebar + toasts + reopen orb)
local ICON = LOGO

getgenv().Config = {
getgenv().Config = {
    Enabled = false,
    Holding = false,
    OffOnDeath = false, -- turn silent aim off when you die
    HitChance = 100,        -- % of shots that get redirected
    HeadChance = 0,         -- % of redirected shots forced onto the head
    VisibleOnly = false,    -- ignore players behind walls
    TeamCheck = true,       -- never target teammates (silent aim, aimbot, flickbot, triggerbot)
    IncludeNPCs = false,    -- also draw/target dummies and bots (tagged entities that aren't players)
    VulnerableOnly = false, -- ignore spawn-protected / forcefielded players
    IgnoreDeflecting = false,
    IgnoreShielded = false,
    FOVPreview = false,
    HitPart = "Head",
    FOVRadius = 300,
    ShowFOV = false,
    Aimbot = { -- aimbot (separate from silent aim: own FOV circle, own keys, own range)
        Enabled = false,
        Holding = false,
        OffOnDeath = false, -- turn aimbot off when you die
        WallCheck = false,  -- ignore players with a wall between you and them
        IgnoreDeflecting = false, -- skip players deflecting (anti-katana)
        IgnoreShielded = false,   -- skip players with a shield up
        VulnerableOnly = false,   -- skip spawn-protected / forcefielded players
        ShowFOV = false,
        FOVPreview = false,
        FOVRadius = 80,
        Smooth = 1, -- 1 = instant lock, higher = softer
        MaxDist = 300, -- studs; players farther than this are ignored
        HitPart = "Head",
    },
    Ragebot = { -- elisium ragebot: desync onto the nearest enemy + auto-fire at the head
        Enabled = false,
        FFA = false,            -- ignore teams, target everyone
        X = 0, Y = 2, Z = 0,    -- desync offset from the target's root
        Prediction = true,
        PredictionAmount = 1,   -- multiplier on your ping lead
    },
    Loadout = { -- auto loadout: picks your weapons the moment the pick screen opens
        Enabled = false,
        Slots = { "Bow", "Handgun", "Fists", "Grenade" }, -- slot 1..4, blank = leave that slot alone
    },
    Trigger = { -- triggerbot: fires while an enemy is under the crosshair
        Enabled = false,
        Holding = false,
        HeadOnly = false,       -- only fire when the crosshair is on the head
        SkipProtected = false,  -- ignore spawn-protected / forcefielded players
        UseSilent = false,      -- also fire when silent aim has a target in its FOV
        Delay = 0,              -- ms the target must stay on the crosshair before firing
        MaxDist = 300,          -- studs
    },
    Detectors = {
        Moderator = {
            Enabled = true,  -- flag players in the game's staff group
            Notify = true,   -- show an alert when one is in your server
            Leave = false,   -- kick yourself out of the server when one is found
        },
        Hacker = {
            Enabled = true,  -- flag players moving at impossible speeds
            Notify = true,
        },
    },
    Flickbot = { -- ported from Kicia: key press = one human-like flick, optional shot, cooldown
        Enabled = false,
        Shoot = true,       -- fire once the flick lands
        ShotDelay = 40,     -- ms between landing and the shot
        Cooldown = 250,     -- ms before the next flick is allowed
        Duration = 120,     -- ms the flick takes
        Curvature = 15,     -- 0-50, sideways arc of the path
        Humanness = 40,     -- 0-100, path noise and tremor
        Pending = false,    -- set by the key, consumed by the render step
        Force = false,      -- set by the mobile Flick button: flick even if the toggle is off
    },
    QuickButtons = { -- which mobile quick buttons are shown (Hotkeys tab)
        Aimbot = false, SilentAim = false, Triggerbot = false, Flick = false,
        ESP = false, Chams = false,
    },
    Visuals = {
        ESP = false,
        ESPColor = Color3.fromRGB(255, 255, 255),
        MaxDistance = 500, -- fixed ESP range, no UI option
        Chams = false,
        ChamsColor = Color3.fromRGB(255, 60, 60),
        ChamsFillAlpha = 0,
        LockedColorOn = false,
        LockedColor = Color3.fromRGB(0, 220, 255),
        TargetLine = false,
        FOVColor = Color3.fromRGB(255, 255, 255),
        FOVThickness = 1,
        FOVFilled = false,
        FOVRainbow = false,
        Crosshair = false,
        CrossStyle = "Cross",       -- Cross / X / T / Circle / Dot
        CrossColor = Color3.fromRGB(0, 255, 170),
        CrossRainbow = false,
        CrossLength = 8,
        CrossThickness = 1,
        CrossGap = 3,
        CrossDot = false,
        CrossOutline = false,
        CrossOutlineColor = Color3.fromRGB(0, 0, 0),
        CrossSpin = false,
        CrossSpinSpeed = 120,       -- degrees per second
        CrossRotation = 0,          -- static angle
        CrossLines = true, CrossArmTop = true, CrossArmBottom = true, CrossArmLeft = true, CrossArmRight = true,
        CrossSpread = false, CrossSpreadScale = 1,
        CrossAnim = false, CrossAnimMode = "Pulse", CrossAnimSpeed = 3,
        CrossFade = false, CrossFadeColor = Color3.fromRGB(255, 0, 170),
        CrossFollow = false, CrossFollowSource = "Target",
        CrossShimmer = false, CrossShimmerSpeed = 4,
        CrossText = false,
        CrossTextContent = "skyware",
        CrossTextFont = "Plex",
        CrossTextSize = 16,
        CrossTextOffset = 18,
        CrossOffsetX = 0, CrossOffsetY = 0, CrossInsetFix = false,
        CrossTextX = 0, CrossTextY = 0, CrossTextAnchor = "Below",
        CrossTextColor = Color3.fromRGB(255, 255, 255),
        CrossTextOutline = true,
        CrossTextRainbow = false,
        CamFOVEnabled = false,
        CameraFOV = 90,
        Fullbright = false,
        Radar = false,
        Tracers = false,
        TracerColor = Color3.fromRGB(255, 255, 255),
        TracerOrigin = "Bottom",   -- Bottom / Center / Top / Mouse
        TracerTarget = "Feet",     -- Feet / Torso / Head
        TracerThickness = 1,
        TracerOpacity = 1,
        TracerRange = 500,
        TracerOffscreen = true,    -- keep lines for players behind you
        TracerFade = false,        -- fade lines with distance
    },
}


local reps = game:GetService("ReplicatedStorage")
local plrs = game:GetService("Players")
local runs = game:GetService("RunService")
local cs = game:GetService("CollectionService")
local lplr = plrs.LocalPlayer
local cam = workspace.CurrentCamera

-- bail quietly in places that don't have the game's modules (lobby, menus)
if not reps:WaitForChild("Modules", 15) then
    getgenv().SkywareLoaded = nil
    notify("Rivals modules not found - join a match/the game place, then execute again.")
    return
end
if not lplr.Character then lplr.CharacterAdded:Wait() end

local U = require(reps.Modules.Utility)
local EL = require(reps.Modules.EnumLibrary)
local GU = require(reps.Modules.GameplayUtility)

local e, gun = pcall(require, lplr.PlayerScripts.Modules.ItemTypes.Gun)
if e and gun and gun.IsFullyAiming then
    gun.IsFullyAiming = function() return true end
end

local C = getgenv().Config
local V = C.Visuals
local console
local lockedEntity -- set every frame while aim is active

local function log(line)
    if console then console:Append(string.format("[%s] %s", os.date("%H:%M:%S"), line)) end
end

local function aimActive() return C.Enabled or C.Holding end

-- World helpers
local Lighting = game:GetService("Lighting")
local originalFOV = cam.FieldOfView
local lightingOriginal = {
    Brightness = Lighting.Brightness, ClockTime = Lighting.ClockTime, FogEnd = Lighting.FogEnd,
    GlobalShadows = Lighting.GlobalShadows, Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient,
}
local fullbrightProps = {
    Brightness = 2, ClockTime = 14, FogEnd = 100000, GlobalShadows = false,
    Ambient = Color3.fromRGB(178, 178, 178), OutdoorAmbient = Color3.fromRGB(178, 178, 178),
}
local function applyFullbright(on)
    for k, v in (on and fullbrightProps or lightingOriginal) do Lighting[k] = v end
end



-- Window --------------------------------------------------------------
-- Tab icons: a symbol, or an "rbxassetid://..." string for an image icon.
local TAB_ICONS = { Aim = "aim", Weapons = "gun", Visuals = "eye", World = "globe", Movement = "move", Skins = "skins", Audio = "audio", Auto = "bolt", Safety = "shield", Hotkeys = "phone", Config = "config", Settings = "gear", Spoofer = "user" }

window:CreateTag({ text = "v1.0", order = 0 })

local TAB_ICONS = { Aim = "aim", Weapons = "gun", Visuals = "eye", World = "globe", Movement = "move", Skins = "skins", Audio = "audio", Auto = "bolt", Safety = "shield", Hotkeys = "phone", Config = "config", Settings = "gear", Spoofer = "user" }

window:CreateTag({ text = "v1.0", order = 0 })

-- Tabs, in sidebar order:
--   Aim      silent aim, aimbot, triggerbot, ragebot, live target readout
--   Weapons  gun / melee / grenade mods, bullet tracers + hit effects
--   Visuals  ESP, tracers, locked target, FOV circle
--   World    fullbright, radar, camera FOV, then presets: time of day, fog, look, skybox, weather, lightning
--   Movement speed, fly, slide boost, noclip, jump mods, long jump
--   Skins    cosmetic unlocks      Audio   hit / kill sounds, visualizer
--   Auto     map vote, queue       Safety  moderator + hacker detectors
--   Hotkeys  mobile quick buttons (pick which ones show up)
--   Config   save / load / import  Settings  interface, log
local aimTab = window:CreateTab({ name = "Aim", icon = TAB_ICONS.Aim })
local modsTab = window:CreateTab({ name = "Weapons", icon = TAB_ICONS.Weapons })
local function keyToast(label)
    return function(key)
        window:Toast({
            title = label .. " key set",
            subtitle = typeof(key) == "EnumItem" and key.Name or tostring(key or "none"),
        })
    end
end

-- Aim tab ---------------------------------------------------------------
-- Gradient FOV helpers (V fields so they cost no top-level locals) -------------
V.NewGrad = function()
    return {
        Enabled = false, Color2 = Color3.fromRGB(255, 255, 255),
        Fill = false, FillColor = Color3.fromRGB(120, 81, 166), FillColor2 = Color3.fromRGB(255, 255, 255),
        FillAlpha = 0.6, OutlineAlpha = 0.2, Thickness = 2, SpinSpeed = 90, Rainbow = false,
    }
end
-- two compact color rows: outline (color 1 / color 2) and fill (color 1 / color 2)
V.AddFovColors = function(tab, pre, outerFlag, getOuter, setOuter, G)
    tab:Colors({ name = "FOV Colors", items = {
        { flag = outerFlag, color = getOuter(), title = "FOV color", callback = setOuter },
        { flag = pre .. "Color2", color = G.Color2, title = "FOV color 2", callback = function(c) G.Color2 = c end },
    } })
    tab:Colors({ name = "Fill Colors", items = {
        { flag = pre .. "FillColor", color = G.FillColor, title = "Fill color", callback = function(c) G.FillColor = c end },
        { flag = pre .. "FillColor2", color = G.FillColor2, title = "Fill color 2", callback = function(c) G.FillColor2 = c end },
    } })
end
V.AddFovSliders = function(tab, pre, G)
    tab:Slider({ name = "FOV Thickness", flag = pre .. "Thickness", range = { 1, 10 }, increment = 1, value = G.Thickness, suffix = "px", callback = function(v) G.Thickness = v end })
    tab:Slider({ name = "Spin Speed", flag = pre .. "Spin", range = { 0, 360 }, increment = 5, value = G.SpinSpeed, suffix = "°/s", callback = function(v) G.SpinSpeed = v end })
    tab:Slider({ name = "Fill Transparency", flag = pre .. "FillAlpha", range = { 0, 1 }, increment = 0.05, value = G.FillAlpha, callback = function(v) G.FillAlpha = v end })
    tab:Slider({ name = "Outline Transparency", flag = pre .. "OutlineAlpha", range = { 0, 1 }, increment = 0.05, value = G.OutlineAlpha, callback = function(v) G.OutlineAlpha = v end })
end

C.Grad = C.Grad or V.NewGrad()
C.Aimbot.Grad = C.Aimbot.Grad or V.NewGrad()
C.FOVColor = C.FOVColor or V.FOVColor
C.Aimbot.FOVColor = C.Aimbot.FOVColor or V.FOVColor

local aimToggle, aimbotToggle -- used by the keybinds below and by the death handlers further down
local aimbotQuick -- mobile quick toggle, created after the toggle below
-- Flickbot -----------------------------------------------------------------
aimTab:Section("Flickbot")

local flickRow = aimTab:Grid(2)
flickRow:Toggle({
    name = "Flickbot",
    description = "Key press = one flick onto the best target",
    flag = "FlickEnabled",
    value = C.Flickbot.Enabled,
    callback = function(value)
        C.Flickbot.Enabled = value
        log(value and "flickbot on" or "flickbot off")
        window:Toast({ title = value and "Flickbot on" or "Flickbot off" })
    end,
})
flickRow:Toggle({
    name = "Shoot", description = "Fire once the flick lands",
    flag = "FlickShoot", value = C.Flickbot.Shoot,
    callback = function(v) C.Flickbot.Shoot = v end,
})

aimTab:Slider({
    name = "Shot Delay", flag = "FlickShotDelay", range = { 0, 250 }, increment = 5,
    value = C.Flickbot.ShotDelay, suffix = " ms",
    callback = function(v) C.Flickbot.ShotDelay = v end,
})
aimTab:Slider({
    name = "Flick Cooldown", flag = "FlickCooldown", range = { 0, 2000 }, increment = 25,
    value = C.Flickbot.Cooldown, suffix = " ms",
    callback = function(v) C.Flickbot.Cooldown = v end,
})
aimTab:Slider({
    name = "Flick Duration", flag = "FlickDuration", range = { 30, 400 }, increment = 5,
    value = C.Flickbot.Duration, suffix = " ms",
    callback = function(v) C.Flickbot.Duration = v end,
})
aimTab:Slider({
    name = "Curvature", flag = "FlickCurvature", range = { 0, 50 }, increment = 1,
    value = C.Flickbot.Curvature,
    callback = function(v) C.Flickbot.Curvature = v end,
})
aimTab:Slider({
    name = "Humanness", flag = "FlickHumanness", range = { 0, 100 }, increment = 1,
    value = C.Flickbot.Humanness,
    callback = function(v) C.Flickbot.Humanness = v end,
})

aimTab:Keybind({
    name = "Flick",
    description = "Uses the Aimbot FOV, range, wall check and lock part",
    flag = "FlickKey",
    value = Enum.KeyCode.H,
    callback = function() C.Flickbot.Pending = true end,
    onChanged = keyToast("Flick"),
local targetText = aimTab:Text({ name = "Status", text = "No target", height = 54 })
local healthBar = aimTab:Progress({
    name = "Target Health", range = { 0, 100 }, value = 0,
    format = function(v) return string.format("%d%%", math.floor(v + 0.5)) end,
})
local stageBar = aimTab:Progress({
    name = "Aim Stage", steps = 3, value = 0,
    stageNames = { "Idle", "Scanning", "Armed", "Locked" },
})

local stats = aimTab:Stats({
    { name = "In FOV" },
    { name = "Nearest" },
    { name = "Closing", delta = true },
    { name = "Locks", relative = true },
})
local inFovStat, nearestStat, closingStat, locksStat = stats[1], stats[2], stats[3], stats[4]

-- Mods tab ----------------------------------------------------------------
-- Ragebot (elisium) --------------------------------------------------------------
aimTab:Section("Ragebot")
local rageToggle
rageToggle = aimTab:BigToggle({
    title = "RAGEBOT",
    warning = "RISK OF GETTING BANNED. USE AT YOUR OWN RISK.",
    value = C.Ragebot.Enabled,
    callback = function(value)
        C.Ragebot.Enabled = value
        if _G.__skyware_rage then
            if value then _G.__skyware_rage.Start() else _G.__skyware_rage.Stop() end
        end
        log(value and "ragebot on" or "ragebot off")
        window:Toast({ title = value and "Ragebot on" or "Ragebot off" })
    end,
})
aimTab:Toggle({
    name = "Rage FFA Mode", flag = "RageFFA", value = C.Ragebot.FFA,
    callback = function(v) C.Ragebot.FFA = v end,
})
aimTab:Slider({
    name = "Rage X Offset", flag = "RageX", range = { -10, 10 }, increment = 1,
    value = C.Ragebot.X, callback = function(v) C.Ragebot.X = v end,
})
aimTab:Slider({
    name = "Rage Y Offset", flag = "RageY", range = { -10, 10 }, increment = 1,
    value = C.Ragebot.Y, callback = function(v) C.Ragebot.Y = v end,
})
aimTab:Slider({
    name = "Rage Z Offset", flag = "RageZ", range = { -10, 10 }, increment = 1,
    value = C.Ragebot.Z, callback = function(v) C.Ragebot.Z = v end,
})
aimTab:Toggle({
    name = "Rage Prediction", flag = "RagePrediction", value = C.Ragebot.Prediction,
    callback = function(v) C.Ragebot.Prediction = v end,
})
aimTab:Slider({
    name = "Rage Prediction Strength", flag = "RagePredictionAmount", range = { 0, 3 }, increment = 0.05,
    value = C.Ragebot.PredictionAmount, callback = function(v) C.Ragebot.PredictionAmount = v end,
})

-- Spoofer tab -------------------------------------------------------------
-- Clientside: these change what YOUR game client shows (names, boards, charms, currency).
-- The device spoofer is the exception, it tells the server which control scheme you use.
-- stubs for hook dependencies
MeleeMod = { Enabled = false, Range = 15 }
FuseMod = { RemoveFuse = false, ExplodeOnThrow = false }

window:Show()

-- FOV circle + crosshair
local FOV = Drawing.new("Circle")
FOV.Color = Color3.fromRGB(255, 255, 255)
FOV.Thickness = 1
FOV.Filled = false
FOV.NumSides = 64

-- Gradient FOV (elisium style): a round Frame whose UIStroke carries a two-color UIGradient and
-- whose fill carries its own gradient, both spinning. One instance per circle id ("main"/"aim").
do
    local gradCircles = {}
    local function build()
        local gui = Instance.new("ScreenGui")
        gui.Name = "skyware_fov"
        gui.ResetOnSpawn = false
        gui.IgnoreGuiInset = true
        gui.DisplayOrder = 998
        local ok = pcall(function() gui.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
        if not ok then pcall(function() gui.Parent = game:GetService("CoreGui") end) end
        local frame = Instance.new("Frame")
        frame.BorderSizePixel = 0
        frame.BackgroundTransparency = 1
        frame.Visible = false
        frame.Parent = gui
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = frame
        local stroke = Instance.new("UIStroke")
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Color = Color3.new(1, 1, 1)
        stroke.Parent = frame
        local fillGrad = Instance.new("UIGradient")
        fillGrad.Parent = frame
        local strokeGrad = Instance.new("UIGradient")
        strokeGrad.Parent = stroke
        return { gui = gui, frame = frame, stroke = stroke, fillGrad = fillGrad, strokeGrad = strokeGrad, rot = 0, last = os.clock() }
    end

    -- id: which circle, show: visible?, center/radius: screen placement, c1: outline color 1,
    -- G: that circle's gradient settings (C.Grad for silent aim, C.Aimbot.Grad for the aimbot)
    V.GradFOV = function(id, show, center, radius, c1, G)
        local g = gradCircles[id]
        if not g then
            if not show then return end
            g = build()
            gradCircles[id] = g
        end
        if not show or not G then
            g.frame.Visible = false
            return
        end
        local now = os.clock()
        g.rot = (g.rot + G.SpinSpeed * math.min(now - g.last, 0.1)) % 360
        g.last = now
        local f = g.frame
        f.Visible = true
        f.Size = UDim2.fromOffset(radius * 2, radius * 2)
        f.Position = UDim2.fromOffset(center.X - radius, center.Y - radius)
        f.Rotation = g.rot
        f.BackgroundColor3 = G.FillColor
        f.BackgroundTransparency = G.Fill and G.FillAlpha or 1
        g.fillGrad.Enabled = G.Fill
        g.fillGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, G.FillColor),
            ColorSequenceKeypoint.new(1, G.FillColor2),
        })
        g.fillGrad.Rotation = g.rot
        g.stroke.Thickness = G.Thickness
        g.stroke.Transparency = G.OutlineAlpha
        g.strokeGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, c1),
            ColorSequenceKeypoint.new(1, G.Color2),
        })
        g.strokeGrad.Rotation = g.rot
    end
end

local katanausers = {}
task.spawn(function()
    if not lplr:FindFirstChild("PlayerScripts") then
        lplr.PlayerScriptsAdded:Wait()
    end
    local katana, attempts = nil, 0
    while attempts < 10 do
        pcall(function()
            local m = lplr.PlayerScripts.Modules.Items:FindFirstChild("Katana", true)
            if m then katana = require(m) end
        end)
        if not katana then
            for _, m in pairs(lplr.PlayerScripts:GetDescendants()) do
                if m.Name == "Katana" and m:IsA("ModuleScript") then
                    local ok, res = pcall(require, m)
                    if ok then katana = res; break end
                end
            end
        end
        if katana and type(katana) == "table" and katana.StartAiming then break end
        attempts += 1
        task.wait(1)
    end
    if katana and type(katana) == "table" and katana.StartAiming then
        local old = katana.StartAiming
        katana.StartAiming = function(self, force)
            local fighter = self.ClientFighter
            local player  = fighter and fighter.Player
            if player then
                katanausers[player] = true
                local dur = self.Info.DeflectDuration or 0.6
                task.delay(dur, function() katanausers[player] = nil end)
            end
            return old(self, force)
        end
    end
end)

-- State checks for deflect (katana/parry), shield and spawn protection. Each scans every
-- attribute and child on the character and the player for matching names, ignores cooldown /
-- ready style flags, and is shared by silent aim, aimbot, flickbot and triggerbot.
local STATE_SKIP = { "cooldown", "cd", "ready", "unlock", "cost", "count", "max" }
local function nameHas(name, words)
    name = tostring(name):lower()
    for _, w in ipairs(words) do
        if name:find(w, 1, true) then return true end
    end
    return false
end
local function attrsMatch(inst, words)
    if not inst then return false end
    for k, v in pairs(inst:GetAttributes()) do
        if nameHas(k, words) and not nameHas(k, STATE_SKIP)
            and (v == true or (type(v) == "number" and v > 0)) then
            return true
        end
    end
    return false
end
local function hasState(entity, words)
    if attrsMatch(entity, words) then return true end
    local p = plrs:GetPlayerFromCharacter(entity)
    if p and attrsMatch(p, words) then return true end
    for _, child in ipairs(entity:GetChildren()) do
        if nameHas(child.Name, words) and not nameHas(child.Name, STATE_SKIP) then
            if child:IsA("BoolValue") then
                if child.Value then return true end
            else
                return true
            end
        end
    end
    return false
end
local DEFLECT_WORDS = { "deflect", "parry" }
local SHIELD_WORDS = { "shield", "barrier" }
local PROTECT_WORDS = { "immun", "invinc", "protect", "spawnshield" }
local function isDeflecting(entity)
    local p = plrs:GetPlayerFromCharacter(entity)
    if p and katanausers[p] then return true end
    return hasState(entity, DEFLECT_WORDS)
end
local function isShielded(entity)
    if entity:GetAttribute("Shielded") or entity:FindFirstChild("Shield") or entity:FindFirstChild("EnergyShield") then return true end
    return hasState(entity, SHIELD_WORDS)
end
local function isProtected(entity)
    if entity:GetAttribute("SpawnImmunity") or entity:FindFirstChildOfClass("ForceField") then return true end
    return hasState(entity, PROTECT_WORDS)
end

-- ESP + chams
local R15_BONES = {
    { "Head", "UpperTorso" }, { "UpperTorso", "LowerTorso" },
    { "UpperTorso", "LeftUpperArm" }, { "LeftUpperArm", "LeftLowerArm" }, { "LeftLowerArm", "LeftHand" },
    { "UpperTorso", "RightUpperArm" }, { "RightUpperArm", "RightLowerArm" }, { "RightLowerArm", "RightHand" },
    { "LowerTorso", "LeftUpperLeg" }, { "LeftUpperLeg", "LeftLowerLeg" }, { "LeftLowerLeg", "LeftFoot" },
    { "LowerTorso", "RightUpperLeg" }, { "RightUpperLeg", "RightLowerLeg" }, { "RightLowerLeg", "RightFoot" },
}
local R6_BONES = {
    { "Head", "Torso" }, { "Torso", "Left Arm" }, { "Torso", "Right Arm" },
    { "Torso", "Left Leg" }, { "Torso", "Right Leg" },
}

local chamsFolder = Instance.new("Folder")
chamsFolder.Name = "VisualCache"
chamsFolder.Parent = (gethui and gethui()) or game:GetService("CoreGui")

local function newDrawing(class, props)
    local d = Drawing.new(class)
    for k, v in props do d[k] = v end
    return d
end

local espObjects = {}
-- Off On Death: silent aim switches itself off the moment you die
do local function __blk0()
    local handled = setmetatable({}, { __mode = "k" })
    local function onDeath(hum)
        if handled[hum] then return end
        handled[hum] = true
        if C.OffOnDeath and (C.Enabled or C.Holding) then
            C.Holding = false
            aimToggle:Set(false)
        end
        local K = C.Aimbot
        if K.OffOnDeath and (K.Enabled or K.Holding) then
            K.Holding = false
            aimbotToggle:Set(false)
        end
    end
    local function watchDeath(char)
        local hum = char:WaitForChild("Humanoid", 10)
        if not hum then return end
        hum.Died:Connect(function() onDeath(hum) end)
        hum:GetPropertyChangedSignal("Health"):Connect(function()
            if hum.Health <= 0 then onDeath(hum) end
        end)
    end
    if lplr.Character then task.spawn(watchDeath, lplr.Character) end
    lplr.CharacterAdded:Connect(function(char) task.spawn(watchDeath, char) end)
end local __ok0, __er0 = xpcall(__blk0, debug.traceback) if not __ok0 then warn("[Skyware] block 0 failed: " .. tostring(__er0)) pcall(function() log("block 0 failed - see F9") end) pcall(function() window:Toast({ title = "Block 0 failed", subtitle = tostring(__er0):sub(1, 140) }) end) end end

local silentRay = RaycastParams.new()
silentRay.FilterType = Enum.RaycastFilterType.Exclude
silentRay.IgnoreWater = true

local function silentHead(entity)
    return entity:FindFirstChild("Head") or entity:FindFirstChild("HitboxHead")
end

local function silentPart(entity, center)
    local mode = C.HitPart
    local head = silentHead(entity)
    local body = entity:FindFirstChild("UpperTorso") or entity:FindFirstChild("HumanoidRootPart")
    local part
    if mode == "Head" then
        part = head or body
    elseif mode == "Body" then
        part = body or head
    elseif mode == "Closest" then
        if head and body then
            local hs = cam:WorldToViewportPoint(head.Position)
            local bs = cam:WorldToViewportPoint(body.Position)
            local hd = (Vector2.new(hs.X, hs.Y) - center).Magnitude
            local bd = (Vector2.new(bs.X, bs.Y) - center).Magnitude
            part = hd <= bd and head or body
        else
            part = head or body
        end
    else
        part = entity:FindFirstChild(mode, true)
    end
    if part and part:IsA("BasePart") then return part end
    return nil
end

local function findTarget()
    local center = cam.ViewportSize / 2
    local bestPart, bestEntity, bestDist = nil, nil, C.FOVRadius
    silentRay.FilterDescendantsInstances = { lplr.Character, cam }
    for _, entity in getEntities() do
        if entity == lplr.Character then continue end
        if C.TeamCheck and isTeammate(entity) then continue end
        if C.IgnoreDeflecting and isDeflecting(entity) then continue end
        if C.IgnoreShielded and isShielded(entity) then continue end
        if C.VulnerableOnly and isProtected(entity) then continue end
        local part = silentPart(entity, center)
        if not part then continue end
        local sp, onScreen = cam:WorldToViewportPoint(part.Position)
        if not onScreen then continue end
        local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
        if d < bestDist then
            if C.VisibleOnly then
                local res = workspace:Raycast(cam.CFrame.Position, part.Position - cam.CFrame.Position, silentRay)
                if res and not res.Instance:IsDescendantOf(entity) then continue end
            end
            bestDist, bestPart, bestEntity = d, part, entity
        end
    end
    return bestPart, bestEntity
end

local function target()
    if not aimActive() then return nil end
    local part, entity = findTarget()
    if not part then return nil end
    -- hit chance: roll per shot, a miss lets the shot go out untouched
    if C.HitChance < 100 and math.random(1, 100) > C.HitChance then return nil end
    -- head chance: sometimes force the head regardless of the selected part
    if C.HeadChance > 0 and entity and math.random(1, 100) <= C.HeadChance then
        local head = silentHead(entity)
        if head then return head end
    end
    return part
end

-- Crosshair "follow target": screen position the crosshair should sit at, or nil for center.
-- "Target" = enemy closest to screen center; "Gunpoint" = end of the equipped tool.
V.CrossGetAnchor = function(source)
    if source == "Gunpoint" then
        local tool = lplr.Character and lplr.Character:FindFirstChildOfClass("Tool")
        local handle = tool and (tool:FindFirstChild("Handle") or tool:FindFirstChildWhichIsA("BasePart"))
        if not handle then return nil end
        local att = handle:FindFirstChild("Muzzle", true) or handle:FindFirstChild("FirePoint", true) or handle:FindFirstChild("Barrel", true)
        local pos = (att and att:IsA("Attachment")) and att.WorldPosition or handle.Position
        local sp, on = cam:WorldToViewportPoint(pos)
        if on then return Vector2.new(sp.X, sp.Y) end
        return nil
    end
    local center = cam.ViewportSize / 2
    local best, bestD
    for _, entity in getEntities() do
        if entity == lplr.Character then continue end
        if C.TeamCheck and isTeammate(entity) then continue end
        local part = entity:FindFirstChild("Head") or entity:FindFirstChild("HumanoidRootPart")
        if not part then continue end
        local sp, on = cam:WorldToViewportPoint(part.Position)
        if not on then continue end
        local p = Vector2.new(sp.X, sp.Y)
        local d = (p - center).Magnitude
        if not bestD or d < bestD then best, bestD = p, d end
    end
    return best
end

-- Triggerbot: holds the fire button while an enemy is under the crosshair
-- (or, with "Use Silent Aim", while silent aim has a target in its FOV).
local trigPress, trigRelease = getgenv().mouse1press, getgenv().mouse1release
local trigVIM
local trigVIM
pcall(function() trigVIM = game:GetService("VirtualInputManager") end)
local trigRay = RaycastParams.new()
local aimbotFOV = Drawing.new("Circle")
aimbotFOV.Thickness = 1.5
aimbotFOV.Filled = false
aimbotFOV.NumSides = 64
aimbotFOV.Transparency = 0.7
aimbotFOV.Visible = false

-- Sticky lock: once a player is picked we stay on them until they die or leave range.
-- No FOV leash, a short grace period if their parts blip out (respawn, streaming), and the
-- camera is re-asserted whenever anything else writes to it, so the lock doesn't detach.
local lockedModel, lockedPart, lostAt
local aimbotPart -- the part we're aiming at this frame (read by the camera-write guard below)
local applyingLock = false
-- Hold-where-it-stopped: the game rewrites the camera from its own input every frame, so on
-- release it would snap back to where you were looking before the aimbot. Instead we keep a
-- rotation offset (our aim relative to the game's camera) and keep applying it after the aimbot
-- turns off, so the view stays put and your mouse movement still works from there.
local aimOffset -- {yaw, pitch} offset (radians) between the game's camera and ours, or nil
-- The game can write the camera AFTER our render step, which is what made the view snap back to
-- your mouse position on release. We remember the game's own value (gameRaw) and re-apply the
-- hold offset the moment any outside write lands, so the camera never shows the un-held view.
local gameRaw, gameRawAt, lastApplied

-- yaw/pitch helpers: the offset lives in angle space so it composes the same way the game's
-- own camera does (yaw around world up, then pitch), which keeps mouse input natural after release
local MAX_PITCH = math.rad(85)
local function lookAngles(look)
    return math.atan2(-look.X, -look.Z), math.asin(math.clamp(look.Y, -1, 1))
end
local function wrapAngle(a)
    return (a + math.pi) % (2 * math.pi) - math.pi
end
local function fromAngles(pos, yaw, pitch)
    return CFrame.new(pos) * CFrame.fromOrientation(math.clamp(pitch, -MAX_PITCH, MAX_PITCH), yaw, 0)
end

-- dying / respawning resets the game's camera, so a stored offset would throw the view off
local function clearAimOffset() aimOffset = nil end
lplr.CharacterAdded:Connect(clearAimOffset)
lplr.CharacterRemoving:Connect(clearAimOffset)

local function resolvePart(model, K)
    local p = model:FindFirstChild(K.HitPart, true)
    if p and p:IsA("BasePart") then return p end
    local root = model:FindFirstChild("HumanoidRootPart")
    return (root and root:IsA("BasePart")) and root or nil
end

-- Wall check: ray from the camera to the part; anything solid in between (other than you and
-- the target) means blocked. Re-checked every frame, so the lock engages the moment they're visible.
local wallParams = RaycastParams.new()
wallParams.FilterType = Enum.RaycastFilterType.Exclude
wallParams.RespectCanCollide = true
local function isVisible(part, model)
    local origin = cam.CFrame.Position
    wallParams.FilterDescendantsInstances = { lplr.Character, model, cam }
    return workspace:Raycast(origin, part.Position - origin, wallParams) == nil
end

-- "ok" | "missing" (grace period applies) | "drop" (dead / out of range / behind a wall)
local function lockState(K)
    if not lockedModel or not lockedModel.Parent or not lockedModel:IsDescendantOf(workspace) then return "missing" end
    local hum = lockedModel:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health <= 0 then return "drop" end
    if C.TeamCheck and isTeammate(lockedModel) then return "drop" end
    if K.IgnoreDeflecting and isDeflecting(lockedModel) then return "drop" end
    if K.IgnoreShielded and isShielded(lockedModel) then return "drop" end
    if K.VulnerableOnly and isProtected(lockedModel) then return "drop" end
    local part = resolvePart(lockedModel, K)
    if not part then return "missing" end
    if (part.Position - cam.CFrame.Position).Magnitude > K.MaxDist * 1.25 then return "drop" end
    if K.WallCheck and not isVisible(part, lockedModel) then return "drop" end
    lockedPart = part
    return "ok"
end

local function findAimbotTarget()
    local K = C.Aimbot
    local center = cam.ViewportSize / 2

    if lockedModel then
        local state = lockState(K)
        if state == "ok" then
            lostAt = nil
            return lockedPart
        elseif state == "missing" then
            lostAt = lostAt or os.clock()
            if os.clock() - lostAt < 0.4 and lockedPart and lockedPart.Parent then
                return lockedPart -- keep aiming at the last known spot during the blip
            end
        end
        lockedModel, lockedPart, lostAt = nil, nil, nil
    end

    local best, bestModel, bestDist = nil, nil, K.FOVRadius
    for _, entity in getEntities() do
        local hum = entity:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health <= 0 then continue end
        if C.TeamCheck and isTeammate(entity) then continue end
        if K.IgnoreDeflecting and isDeflecting(entity) then continue end
        if K.IgnoreShielded and isShielded(entity) then continue end
        if K.VulnerableOnly and isProtected(entity) then continue end
        local part = resolvePart(entity, K)
        if not part then continue end
        if (part.Position - cam.CFrame.Position).Magnitude > K.MaxDist then continue end
        local sp, onScreen = cam:WorldToViewportPoint(part.Position)
        if not onScreen then continue end
        if K.WallCheck and not isVisible(part, entity) then continue end
        local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
        if d < bestDist then bestDist, best, bestModel = d, part, entity end
    end
    lockedModel, lockedPart = bestModel, best
    return best
end

-- Flickbot (ported from Kicia) -----------------------------------------------
-- Idle -> Flicking (curved, human-like path onto the best target) -> PostShot (optional
-- shot after a delay) -> Cooldown -> Idle. Targeting uses the Aimbot's FOV, range,
-- shot after a delay) -> Cooldown -> Idle. Targeting uses the Aimbot's FOV, range,
-- wall check and lock part. The camera is written from the aimbot render step below,
-- so there is a single camera writer and the view holds where the flick ended.
local F = C.Flickbot
local flick = { state = "Idle", timer = 0, idx = 1, elapsed = 0, total = 0 }
local flickBusy = false
local TAU = math.pi * 2

local function randn() return (math.random() + math.random() + math.random() - 1.5) * 2 end

local function flickPick()
    local K = C.Aimbot
    local center = cam.ViewportSize / 2
    local best, bestDist = nil, K.FOVRadius
    for _, entity in getEntities() do
        local hum = entity:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health <= 0 then continue end
        if C.TeamCheck and isTeammate(entity) then continue end
        if K.IgnoreDeflecting and isDeflecting(entity) then continue end
        if K.IgnoreShielded and isShielded(entity) then continue end
        if K.VulnerableOnly and isProtected(entity) then continue end
        local part = resolvePart(entity, K)
        if not part then continue end
        if (part.Position - cam.CFrame.Position).Magnitude > K.MaxDist then continue end
        local sp, onScreen = cam:WorldToViewportPoint(part.Position)
        if not onScreen then continue end
        if K.WallCheck and not isVisible(part, entity) then continue end
        local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
        if d < bestDist then bestDist, best = d, part end
    end
    return best
end

-- screen-space path from (x0,y0) to (x1,y1): fast start, soft landing, sideways arc,
-- plus a little drifting noise and tremor that fades out so the path lands exactly
local function flickGenerate(x0, y0, x1, y1)
    local dur = math.max(F.Duration, 20)
    local dx, dy = x1 - x0, y1 - y0
    local dist = math.sqrt(dx * dx + dy * dy)
    local nx, ny = 0, 0
    if dist > 0 then nx, ny = -dy / dist, dx / dist end
    local h = math.clamp(F.Humanness, 0, 100) / 100
    local curve = dist * (math.clamp(F.Curvature, 0, 50) / 1000)
        * (0.6 + math.random() * 0.8) * (math.random() < 0.5 and -1 or 1)
    local tremAmp = (0.05 + math.random() * 0.13) * h
    local tremFreq = 7 + math.random() * 5
    local phX, phY = math.random() * TAU, math.random() * TAU
    local ouX, ouY = 0, 0
    local pts, t = { { X = x0, Y = y0, T = 0 } }, 0
    while t < dur do
        local stepMs = math.random(5, 11)
        t = math.min(t + stepMs, dur)
        local dts = stepMs / 1000
        ouX += -8 * ouX * dts + 0.5 * h * math.sqrt(dts) * randn()
        ouY += -8 * ouY * dts + 0.5 * h * math.sqrt(dts) * randn()
        local w = (t / dur) ^ 0.62 -- warps time so peak speed lands early in the flick
        local s = w * w * w * (w * (w * 6 - 15) + 10)
        local arc = curve * math.sin(math.pi * s)
        local fade = 1 - s
        local ts = t / 1000
        pts[#pts + 1] = {
            X = x0 + dx * s + nx * arc + fade * (ouX + tremAmp * math.sin(TAU * tremFreq * ts + phX)),
            Y = y0 + dy * s + ny * arc + fade * (ouY + tremAmp * math.sin(TAU * tremFreq * ts + phY)),
            T = t,
        }
    end
    return pts
end

local function flickStart()
    local part = flickPick()
    if not part then return end
    local sp = cam:WorldToViewportPoint(part.Position)
    if sp.Z <= 0 then return end
    local c = cam.ViewportSize / 2
    local pts = flickGenerate(c.X, c.Y, sp.X, sp.Y)
    local traj = table.create(#pts)
    for i, pt in ipairs(pts) do
        traj[i] = { Dir = cam:ViewportPointToRay(pt.X, pt.Y).Direction.Unit, T = pt.T }
    end
    flick.part, flick.traj = part, traj
    flick.idx, flick.elapsed = 1, 0
    flick.total = traj[#traj].T
    flick.endDir = traj[#traj].Dir
    flick.state = "Flicking"
end

local function flickFinish()
    flick.part, flick.traj = nil, nil
    if F.Cooldown > 0 then
        flick.state, flick.timer = "Cooldown", F.Cooldown / 1000
    else
        flick.state = "Idle"
    end
end

local function flickClick()
    local press, release = getgenv().mouse1press, getgenv().mouse1release
    if type(press) == "function" and type(release) == "function" then
        pcall(press)
        task.delay(0.04, function() pcall(release) end)
    elseif trigVIM then
        local c = cam.ViewportSize / 2
        pcall(function() trigVIM:SendMouseButtonEvent(c.X, c.Y, 0, true, game, 0) end)
        task.delay(0.04, function()
            pcall(function() trigVIM:SendMouseButtonEvent(c.X, c.Y, 0, false, game, 0) end)
        end)
    end
end

-- runs every frame; returns the aim direction while a flick is in progress, else nil
local function flickTick(dt)
    local hum = lplr.Character and lplr.Character:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health <= 0 then
        F.Pending = false
        flick.part, flick.traj, flick.state = nil, nil, "Idle"
        return nil
    end
    if F.Pending then
        local forced = F.Force
        F.Pending, F.Force = false, false
        if (F.Enabled or forced) and flick.state == "Idle" then flickStart() end
    end

    local st = flick.state
    if st == "Flicking" then
        local part, traj = flick.part, flick.traj
        if not part or not part.Parent or not traj then flickFinish() return nil end
        flick.elapsed += dt * 1000
        local i = flick.idx
        while i < #traj and traj[i + 1].T <= flick.elapsed do i += 1 end
        flick.idx = i
        local a, b = traj[i], traj[i + 1]
        local unit, done
        if not b then
            unit, done = traj[#traj].Dir, true
        else
            local span = b.T - a.T
            local f = span > 0 and math.clamp((flick.elapsed - a.T) / span, 0, 1) or 1
            unit, done = a.Dir:Lerp(b.Dir, f), false
        end
        if flick.total > 0 then
            -- the target keeps moving during the flick: blend the baked path toward where it is now
            local live = (part.Position - cam.CFrame.Position).Unit
            unit = (unit + (live - flick.endDir) * math.clamp(flick.elapsed / flick.total, 0, 1)).Unit
        end
        if done then
            if F.Shoot then
                flick.state, flick.timer = "PostShot", F.ShotDelay / 1000
            else
                flickFinish()
            end
        end
        return unit
    elseif st == "PostShot" then
        flick.timer -= dt
        if flick.timer <= 0 then
            flickClick()
            flickFinish()
        end
    elseif st == "Cooldown" then
        flick.timer -= dt
        if flick.timer <= 0 then flick.state = "Idle" end
    end
    return nil
end


runs:BindToRenderStep("SkywareAimbot", Enum.RenderPriority.Last.Value, function(dt)
    local K = C.Aimbot
    local active = K.Enabled or K.Holding
    aimbotFOV.Position = cam.ViewportSize / 2
    aimbotFOV.Radius = K.FOVRadius
    aimbotFOV.Color = (K.Grad and K.Grad.Rainbow) and Color3.fromHSV((os.clock() * 0.3) % 1, 1, 1) or K.FOVColor or V.FOVColor
    if K.Grad then aimbotFOV.Thickness = K.Grad.Thickness end
    local aimFovShown = (active and K.ShowFOV) or K.FOVPreview
    local aimGradOn = K.Grad and K.Grad.Enabled
    local aFill = K.Grad and K.Grad.Fill
    aimbotFOV.Filled = aFill == true
    aimbotFOV.Transparency = aFill and (1 - K.Grad.FillAlpha) or 0.7
    aimbotFOV.Visible = aimFovShown and not aimGradOn
    V.GradFOV("aim", aimFovShown and aimGradOn, cam.ViewportSize / 2, K.FOVRadius, aimbotFOV.Color, K.Grad)

    local raw = (gameRaw and os.clock() - gameRawAt < 0.1) and gameRaw or nil -- the game's own view (mouse input included)
    local rawYaw, rawPitch
    if raw then
        rawYaw, rawPitch = lookAngles(raw.LookVector)
    else
        -- game hasn't written the camera recently: cam.CFrame already includes our offset, so take it back out
        raw = cam.CFrame
        rawYaw, rawPitch = lookAngles(raw.LookVector)
        if aimOffset then
            rawYaw = wrapAngle(rawYaw - aimOffset.yaw)
            rawPitch = rawPitch - aimOffset.pitch
        end
    end

    -- a flick in progress owns the camera; the aimbot stands down until it is over
    local flickDir = flickTick(dt)
    flickBusy = flick.state == "Flicking" or flick.state == "PostShot"

    local part
    if active and not flickBusy then
        part = findAimbotTarget()
    else
        lockedModel, lockedPart, lostAt = nil, nil, nil
        if not active and not flickBusy and not flickDir and aimOffset then aimOffset = nil; gameRaw = nil end
    end
    aimbotPart = part

    -- where the camera is right now = the game's view plus whatever we're holding
    local curYaw = rawYaw + (aimOffset and aimOffset.yaw or 0)
    local curPitch = rawPitch + (aimOffset and aimOffset.pitch or 0)

    local newYaw, newPitch
    if flickDir then
        newYaw, newPitch = lookAngles(flickDir)
    elseif part then
        local goalYaw, goalPitch = lookAngles((part.Position - raw.Position).Unit)
        local alpha = 1 / math.max(K.Smooth, 1)
        if alpha >= 1 then
            newYaw, newPitch = goalYaw, goalPitch
        else
            -- soften from the camera's current heading, not from the mouse-drifted game view
            newYaw = curYaw + wrapAngle(goalYaw - curYaw) * alpha
            newPitch = curPitch + (goalPitch - curPitch) * alpha
        end
    elseif aimOffset then
        -- released / wall-check drop: bleed the offset off so the game's own camera takes back over
        local k = 1 - math.min(dt * 14, 1)
        aimOffset.yaw *= k
        aimOffset.pitch *= k
        if math.abs(aimOffset.yaw) < 0.002 and math.abs(aimOffset.pitch) < 0.002 then
            aimOffset = nil
            gameRaw = nil
        else
            newYaw, newPitch = rawYaw + aimOffset.yaw, rawPitch + aimOffset.pitch
        end
    end

    if newYaw then
        newPitch = math.clamp(newPitch, -MAX_PITCH, MAX_PITCH)
        aimOffset = { yaw = wrapAngle(newYaw - rawYaw), pitch = newPitch - rawPitch }
        applyingLock = true
        cam.CFrame = fromAngles(raw.Position, newYaw, newPitch)
        applyingLock = false
        lastApplied = cam.CFrame
    end
end)

-- Any write to the camera that isn't ours is the game's own update. Re-apply the lock (hard lock)
-- or the held view (after release / smoothed) right away, so a late game write never shows through.
cam:GetPropertyChangedSignal("CFrame"):Connect(function()
    if applyingLock then return end
    local cf = cam.CFrame
    if cf == lastApplied then return end -- our own write arriving late
    gameRaw, gameRawAt = cf, os.clock()
    if flickBusy then return end

    local K = C.Aimbot
    local yaw, pitch = lookAngles(cf.LookVector)
    local newYaw, newPitch
    local part = aimbotPart
    if part and part.Parent and K.Smooth <= 1 and (K.Enabled or K.Holding) then
        newYaw, newPitch = lookAngles((part.Position - cf.Position).Unit)
    elseif aimOffset then
        newYaw, newPitch = yaw + aimOffset.yaw, pitch + aimOffset.pitch
    else
        return
    end
    newPitch = math.clamp(newPitch, -MAX_PITCH, MAX_PITCH)
    aimOffset = { yaw = wrapAngle(newYaw - yaw), pitch = newPitch - pitch }
    applyingLock = true
    cam.CFrame = fromAngles(cf.Position, newYaw, newPitch)
    applyingLock = false
    lastApplied = cam.CFrame
end)

local function CFD(origin, part)
    local cf = part.CFrame
    local cf = part.CFrame
    local d = {}
    d[utf8.char(1)] = {
        [utf8.char(0)] = U:EncodeCFrame(CFrame.lookAt(origin, part.Position)),
        [utf8.char(1)] = U:EncodeCFrame(cf),
        [utf8.char(2)] = part,
        [utf8.char(3)] = U:EncodeCFrame(cf:ToObjectSpace(CFrame.new(part.Position))),
    }
    return d
end

local visual = GU.GetEntitiesFromRaycast
GU.GetEntitiesFromRaycast = function(self, envID, params, origin, dir, maxDist, ...)
    local t = target()
    if t then
        local dist = (t.Position - origin).Magnitude
        dir = (t.Position - origin).Unit
        if dist > maxDist then maxDist = dist + 5 end
    end
    return visual(self, envID, params, origin, dir, maxDist, ...)
end

local UseItem = reps.Remotes.Replication.Fighter.UseItem
-- Item behavior lookup (MeleeMod / FuseMod) ------------------------------------
-- The server only gets an object id, so we find the client-side behavior table for that id
-- Item behavior lookup (MeleeMod / FuseMod) ------------------------------------
-- The server only gets an object id, so we find the client-side behavior table for that id
-- (a Melee or Throwable instance) by scanning the GC once and caching the result.
-- Safe enum lookup: EnumLibrary:ToEnum throws on some clients (seen on iOS), so every lookup is
-- pcall'd, cached, and never runs inside the FireServer hook.
local enumCache = {}
local function safeEnum(name)
    local cached = enumCache[name]
    if cached ~= nil then return cached end
    local ok, v = pcall(function() return EL:ToEnum(name) end)
    if not ok or v == nil then
        ok, v = pcall(function() return EL.ToEnum(EL, name) end)
    end
    if not ok or v == nil then
        -- last resort: read the value straight out of the library table
        pcall(function()
            for _, key in ipairs({ "Enums", "_enums", "enums", "Map", "_map", "Values" }) do
                local t = rawget(EL, key)
                if type(t) == "table" and t[name] ~= nil then v = t[name] break end
            end
            if v == nil and rawget(EL, name) ~= nil then v = rawget(EL, name) end
        end)
    end
    if v ~= nil then enumCache[name] = v end
    return v
end
local ITEM_ENUM = {
    StartShooting = safeEnum("StartShooting"), StartAiming = safeEnum("StartAiming"),
    FinishShooting = safeEnum("FinishShooting"), FinishAiming = safeEnum("FinishAiming"),
}
local behaviorCache, behaviorMiss = {}, {}

local function typeClass(name)
    local ok, cls = pcall(function()
        return require(lplr.PlayerScripts.Modules.ItemTypes[name])
    end)
    return ok and type(cls) == "table" and cls or nil
end

local function findBehavior(objID, typeName)
    local key = typeName .. tostring(objID)
    local hit = behaviorCache[key]
    if hit then return hit end
    if behaviorMiss[key] and tick() - behaviorMiss[key] < 1 then return nil end
    if not getgc then return nil end
    local cls = typeClass(typeName)
    for _, t in ipairs(getgc(true)) do
        if type(t) == "table" then
            local ok, found = pcall(function()
                local mt = getmetatable(t)
                local isType = (cls and mt and (rawequal(mt, cls) or rawequal(mt.__index, cls)))
                    or t.__type == typeName
                if not isType then return false end
                for _, v in next, t do
                    if v == objID then return true end
                end
                return false
            end)
            if ok and found then
                behaviorCache[key] = t
                return t
            end
        end
    end
    behaviorMiss[key] = tick()
    return nil
end

local function nearestEnemyRoot(range)
    local root = lplr.Character and lplr.Character:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    local best, bestDist = nil, range
    for _, entity in getEntities() do
        if entity == lplr.Character then continue end
        local hum = entity:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health <= 0 then continue end
        local r = entity:FindFirstChild("HumanoidRootPart") or entity.PrimaryPart
        if not r then continue end
        local d = (r.Position - root.Position).Magnitude
        if d < bestDist then best, bestDist = r, d end
    end
    return best
end

local function meleeCamdata(enemyRoot)
    local cf = U:EncodeCFrame(CFrame.new(enemyRoot.Position) * CFrame.fromOrientation(-math.pi / 2, 0, 0))
    local d = {}
    d[utf8.char(1)] = { [utf8.char(0)] = cf, [utf8.char(1)] = cf }
    return d
end

-- Remove Fuse, part 2: the game's own throw code reads "_cook_detonate_delay"; pointing that
-- constant at a field that never exists means the delay is never applied. Needs debug.setconstant.
local FUSE_FIELD = "_cook_detonate_delay"
local fuseConstIndex
function setFuseConstant(on)
    pcall(function()
        local cls = typeClass("Throwable")
        local fn = cls and rawget(cls, "_StartThrow")
        if type(fn) ~= "function" or not (debug.getconstants and debug.setconstant) then return end
        if not fuseConstIndex then
            for i, c in ipairs(debug.getconstants(fn)) do
                if c == FUSE_FIELD then fuseConstIndex = i break end
            end
        end
        if fuseConstIndex then debug.setconstant(fn, fuseConstIndex, on and "\0" or FUSE_FIELD) end
    end)
end

local hook; hook = hookfunction(UseItem.FireServer, newcclosure(function(self, objID, enumVal, camdata, extra)
    local silentTook = false
    if enumVal ~= nil and enumVal == (ITEM_ENUM.StartShooting or safeEnum("StartShooting")) then
        local root = lplr.Character and lplr.Character:FindFirstChild("HumanoidRootPart")
        local t = target()
        if root and t then camdata = CFD(root.Position, t); silentTook = true end
    end

    local starting = enumVal == ITEM_ENUM.StartShooting or enumVal == ITEM_ENUM.StartAiming
    local finishing = enumVal == ITEM_ENUM.FinishShooting or enumVal == ITEM_ENUM.FinishAiming

    -- MeleeMod: snap the swing onto the nearest enemy inside MeleeMod.Range
    if MeleeMod.Enabled and starting and not silentTook and type(camdata) == "table" then
        pcall(function()
            if findBehavior(objID, "Melee") then
                local enemy = nearestEnemyRoot(MeleeMod.Range)
                if enemy then camdata = meleeCamdata(enemy) end
            end
        end)
    end

    -- FuseMod: Remove Fuse clears the cook timer when you start cooking; Explode On Throw
    -- sets the detonation delay to 0 when the grenade is released
    if (FuseMod.RemoveFuse and starting) or (FuseMod.ExplodeOnThrow and finishing) then
        pcall(function()
            local b = findBehavior(objID, "Throwable")
            if not b then return end
            if starting and FuseMod.RemoveFuse and b.Info and b.Info.CanCook then
                rawset(b, FUSE_FIELD, nil)
            elseif finishing and FuseMod.ExplodeOnThrow and type(camdata) == "table" then
                camdata[utf8.char(3)] = 0
            end
        end)
    end

    return hook(self, objID, enumVal, camdata, extra)
end))

-- Ragebot (elisium) --------------------------------------------------------------
-- Ported from elisium: DesyncService (teleports your root onto the nearest enemy server-side,
-- CameraController.Update puts it back client-side before render) + RagebotService (auto-fire
-- at the head, reload handling, deflect/riot-shield skip) + the slingshot projectile handler.
-- Settings live in C.Ragebot. Shots go through the ORIGINAL FireServer (`hook`) so silent aim /
-- MeleeMod above never rewrite the ragebot's camera data.
task.spawn(function()
    local R = C.Ragebot
    local ws = workspace
-- Ragebot (elisium) --------------------------------------------------------------
-- Ported from elisium: DesyncService (teleports your root onto the nearest enemy server-side,
-- CameraController.Update puts it back client-side before render) + RagebotService (auto-fire
-- at the head, reload handling, deflect/riot-shield skip) + the slingshot projectile handler.
-- Settings live in C.Ragebot. Shots go through the ORIGINAL FireServer (`hook`) so silent aim /
-- MeleeMod above never rewrite the ragebot's camera data.
task.spawn(function()
    local R = C.Ragebot
    local ws = workspace
    local util = U

    local scripts = lplr:WaitForChild("PlayerScripts", 15)
    local controllers = scripts and scripts:WaitForChild("Controllers", 15)
    local okF, fighter_controller = pcall(function()
        return require(controllers:WaitForChild("FighterController", 15))
    end)
    local okC, camera_controller = pcall(function()
        return require(controllers:WaitForChild("CameraController", 15))
    end)
    if not (okF and fighter_controller) then
        log("ragebot: FighterController not found, ragebot disabled")
        return
    end

    local setId = setthreadidentity or setidentity or function() end

    -- deflect tracking (hooks the katana's deflect start) ---------------------------
    local deflecting = {}
    local function is_deflecting(plr) return deflecting[plr] end
    pcall(function()
        local katana = require(scripts.Modules.Items.Katana)
        local oldDeflect = katana._StartDeflecting
        katana._StartDeflecting = function(...)
            local args = { ... }
            local fighter = args[1] and args[1].ClientFighter
            local player = fighter and fighter.Player
            if player then
                deflecting[player] = true
                task.delay((args[1].Info and args[1].Info.DeflectDuration) or 0.1, function()
                    deflecting[player] = false
                end)
            end
            return oldDeflect(table.unpack(args))
        end
    end)
    plrs.PlayerRemoving:Connect(function(p) deflecting[p] = nil end)

    local function has_riot(plr)
        local vm = ws:FindFirstChild("ViewModels")
        return vm ~= nil and vm:FindFirstChild(plr.Name .. " - Riot Shield - Riot Shield") ~= nil
    end

    -- DesyncService --------------------------------------------------------------------
    local Desync = { active = false, connection = nil, server = nil, client = nil }
    Desync.fighter = fighter_controller.LocalFighter

    if okC and camera_controller then
        local ref = camera_controller.Update
        camera_controller.Update = function(...)
            if Desync.active and Desync.fighter and Desync.fighter.Entity and Desync.fighter.Entity.RootPart and Desync.client then
                Desync.fighter.Entity.RootPart.CFrame = Desync.client
            end
            return ref(...)
        end
    else
        log("ragebot: CameraController not found, desync will show on your screen")
    end

    function Desync:Stop()
        if not self.active then return end
        if self.connection then self.connection:Disconnect(); self.connection = nil end
        if self.client and self.fighter and self.fighter.Entity and self.fighter.Entity.RootPart then
            self.fighter.Entity.RootPart.CFrame = self.client
        end
        self.active = false
        self.server = nil
        self.client = nil
    end

    function Desync:Start(target)
        if self.active then return end
        if not lplr.Character then return end
        self.fighter = fighter_controller.LocalFighter
        if not self.fighter or not self.fighter.Entity or not self.fighter.Entity.RootPart then return end

        self.active = true
        self.connection = runs.Heartbeat:Connect(function()
            if not self.active then
                if self.connection then self.connection:Disconnect(); self.connection = nil end
                return
            end
            if not target or not target.Character or not target.Character:FindFirstChild("HumanoidRootPart")
                or not self.fighter or not self.fighter.Entity.RootPart then
                if self.connection then self.connection:Disconnect(); self.connection = nil end
                if self.client and self.fighter and self.fighter.Entity.RootPart then
                    self.fighter.Entity.RootPart.CFrame = self.client
                end
                self.active, self.client, self.server = false, nil, nil
                return
            end

            self.client = self.fighter.Entity.RootPart.CFrame
            local item = self.fighter.EquippedItem
            if not item then return end

            local targetPos = target.Character.HumanoidRootPart.Position
            if is_deflecting(target) or has_riot(target) then
                self.server = Vector3.new(0, 2 ^ 26, 0)
                return
            end
            if item.Name == "Slingshot" then
                self.server = Vector3.new(0, 2 ^ 26, 0)
            else
                self.server = targetPos + Vector3.new(R.X, R.Y, R.Z)
            end
            self.fighter.Entity.RootPart.CFrame = CFrame.new(self.server)
        end)
    end

    -- RagebotService -------------------------------------------------------------------
    local Rage = { debounce = false, lastShot = os.clock(), connection = nil }

    function Rage:IsValid(player)
        if not (player and player.Character
            and player.Character:FindFirstChild("Humanoid")
            and player.Character.Humanoid.Health > 0
            and player.Character:FindFirstChild("HumanoidRootPart")
            and player:GetAttribute("EnvironmentID") == lplr:GetAttribute("EnvironmentID")) then
            return false
        end
        if R.FFA then return true end
        return lplr:GetAttribute("TeamID") ~= player:GetAttribute("TeamID")
    end

    function Rage:GetClosest()
        local closest, best = nil, math.huge
        for _, player in next, plrs:GetPlayers() do
            if player ~= lplr and self:IsValid(player) then
                local mag = lplr:DistanceFromCharacter(player.Character.HumanoidRootPart.Position)
                if mag < best then closest, best = player, mag end
            end
        end
        return closest
    end

    function Rage:FireWeapon(target)
        if not target or not target.Character then return end
        local fighter = fighter_controller.LocalFighter
        if not fighter then return end
        local item = fighter.EquippedItem
        if not item then return end
        if is_deflecting(target) or has_riot(target) then return end

        local head = target.Character:FindFirstChild("HitboxHead")
            or target.Character:FindFirstChild("HitboxTorso")
            or target.Character:FindFirstChild("HumanoidRootPart")
        if not head then return end

        local character = lplr.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then return end

        local shootPos = Desync.active and Desync.server or character.HumanoidRootPart.Position
        local aimPos = head.Position

        if R.Prediction then
            local troot = target.Character:FindFirstChild("HumanoidRootPart")
            if troot then
                local ping = 0.05
                pcall(function() ping = lplr:GetNetworkPing() end)
                local lead = math.clamp(ping, 0, 0.4) * (R.PredictionAmount or 1)
                aimPos = aimPos + troot.AssemblyLinearVelocity * lead
            end
        end

        local aimCF = util:EncodeCFrame(CFrame.new(shootPos, aimPos))
        -- same payload elisium sends (its duplicate [1] key collapses to the aim CFrame)
        local data = {
            [utf8.char(1)] = {
                [utf8.char(0)] = aimCF,
                [utf8.char(1)] = aimCF,
                [utf8.char(2)] = head,
            },
        }
        pcall(hook, UseItem, item:Get("ObjectID"), ITEM_ENUM.StartShooting or safeEnum("StartShooting"), data, nil)
    end

    -- slingshot / projectile follow-up: touches the nearest enemy's head with the projectile
    ws.DescendantAdded:Connect(function(child)
        if not R.Enabled then return end
        if child:IsA("BasePart") or child:IsA("Model") then
            if child.Name == "Slingshot" or child.Name == "CoreProjectile" or child.Name == "OuterProjectile" then
                task.spawn(function()
                    task.wait(0.03)
                    local proj = child:IsA("BasePart") and child or child:FindFirstChildWhichIsA("BasePart")
                    if not proj then return end
                    proj.CanTouch = true
                    for _ = 1, 45 do
                        if not R.Enabled then break end
                        local target = Rage:GetClosest()
                        if target and target.Character then
                            local hitpart = target.Character:FindFirstChild("HitboxHead")
                                or target.Character:FindFirstChild("HumanoidRootPart")
                            if hitpart and hitpart:IsA("BasePart") and hitpart.Parent and proj.Parent
                                and hitpart:IsDescendantOf(ws) and proj:IsDescendantOf(ws) then
                                pcall(firetouchinterest, hitpart, proj, 0)
                                pcall(firetouchinterest, hitpart, proj, 1)
                            end
                        end
                        task.wait()
                    end
                end)
            end
        end
    end)

    function Rage:Stop()
        if self.connection then self.connection:Disconnect(); self.connection = nil end
        self.debounce = false
        Desync:Stop()
    end

    function Rage:Start()
        if self.connection then return end
        self.connection = runs.Heartbeat:Connect(function()
            if not R.Enabled then self:Stop(); return end

            local target = self:GetClosest()
            if not target then Desync:Stop(); return end
            local fighter = fighter_controller.LocalFighter
            if not fighter then Desync:Stop(); return end
            local item = fighter.EquippedItem
            if not item then Desync:Stop(); return end
            local target_fighter = fighter_controller:GetFighter(target)
            if not target_fighter then Desync:Stop(); return end
            local viewmodel = item.ViewModel
            if not viewmodel then Desync:Stop(); return end
            local target_entity = target_fighter.Entity
            if not target_entity or target_entity:Get("IsInvincible") then Desync:Stop(); return end

            local ammo = item:Get("Ammo")
            if ammo and ammo > 0 and not viewmodel:IsAnimationPlaying("Reload") then
                if self.debounce == false then
                    self.debounce = os.clock() + 0.5
                    return
                end
                if typeof(self.debounce) == "number" and os.clock() < self.debounce then return end
                if typeof(self.debounce) == "number" then self.debounce = true end

                Desync:Start(target)
                if not target.Character then return end
                if Desync.server then
                    self.lastShot = os.clock()
                    self:FireWeapon(target)
                end
            else
                if not viewmodel:IsAnimationPlaying("Reload") then
                    setId(2)
                    pcall(function() item:Input("StartReloading") end)
                    setId(7)
                end
            end
        end)
    end

    _G.__skyware_rage = { Start = function() Rage:Start() end, Stop = function() Rage:Stop() end }
    if R.Enabled then Rage:Start() end
end)

-- Locked target: updated every frame so recoloring and the target line follow it instantly
local targetLine = newDrawing("Line", { Thickness = 1, Visible = false })

runs.RenderStepped:Connect(function()
    if aimActive() then
        local part, entity = findTarget()
        lockedEntity = entity
        if V.TargetLine and part then
            local sp = cam:WorldToViewportPoint(part.Position)
            targetLine.From = cam.ViewportSize / 2
            targetLine.To = Vector2.new(sp.X, sp.Y)
            targetLine.Color = V.LockedColor
            targetLine.Visible = true
        else
            targetLine.Visible = false
        end
    else
        lockedEntity = nil
        targetLine.Visible = false
    end
end)

-- Radar: top-left, rotates with your camera, range matches the ESP range
local RADAR_RADIUS = 80
local RADAR_CENTER = Vector2.new(RADAR_RADIUS + 20, RADAR_RADIUS + 120)
local radarBack = newDrawing("Circle", {
    Radius = RADAR_RADIUS, Filled = true, Color = Color3.new(0, 0, 0), Transparency = 0.5,
    NumSides = 48, Position = RADAR_CENTER, Visible = false,
})
local radarRing = newDrawing("Circle", {
    Radius = RADAR_RADIUS, Filled = false, Thickness = 1, Color = Color3.new(1, 1, 1),
    NumSides = 48, Position = RADAR_CENTER, Visible = false,
})
local radarSelf = newDrawing("Circle", {
    Radius = 3, Filled = true, Color = Color3.new(1, 1, 1), NumSides = 12,
    Position = RADAR_CENTER, Visible = false,
})
local radarDots = {}

local function updateRadar()
    local on = V.Radar
    radarBack.Visible, radarRing.Visible, radarSelf.Visible = on, on, on
    if not on then
        for _, d in radarDots do d.Visible = false end
        return
    end

    local camPos = cam.CFrame.Position
    local look = cam.CFrame.LookVector
    local fwd = Vector3.new(look.X, 0, look.Z)
    fwd = fwd.Magnitude < 1e-3 and Vector3.new(0, 0, -1) or fwd.Unit
    local right = fwd:Cross(Vector3.yAxis)
    local scale = RADAR_RADIUS / V.MaxDistance

    local used = 0
    for _, entity in getEntities() do
        local root = entity:FindFirstChild("HumanoidRootPart") or entity.PrimaryPart
        if not root then continue end
        local d = root.Position - camPos
        local x, z = d:Dot(right), d:Dot(fwd)
        if math.sqrt(x * x + z * z) > V.MaxDistance then continue end

        used += 1
        local dot = radarDots[used]
        if not dot then
            dot = newDrawing("Circle", { Radius = 3, Filled = true, NumSides = 12, Visible = false })
            radarDots[used] = dot
        end
        dot.Position = RADAR_CENTER + Vector2.new(x, -z) * scale
        dot.Color = (V.LockedColorOn and entity == lockedEntity) and V.LockedColor or V.ESPColor
        dot.Visible = true
    end
    for i = used + 1, #radarDots do radarDots[i].Visible = false end
end

-- World: camera FOV and fullbright are re-applied each frame because games love to reset them
runs.RenderStepped:Connect(function()
    pcall(updateRadar)
    if V.CamFOVEnabled then cam.FieldOfView = V.CameraFOV end
    if V.Fullbright then applyFullbright(true) end
end)
end)

-- Live target info (stats, stage, status text, health bar). No notifications here.
task.spawn(function()
    local lastName
    local locks = 0
    while task.wait(0.25) do
        local center = cam.ViewportSize / 2
        local inFov, nearest = 0, math.huge
        for _, entity in getEntities() do
            if entity == lplr.Character then continue end
            local root = entity:FindFirstChild("HumanoidRootPart") or entity.PrimaryPart
            if not root then continue end
            nearest = math.min(nearest, (cam.CFrame.Position - root.Position).Magnitude)
            local sp, on = cam:WorldToViewportPoint(root.Position)
            if on and (Vector2.new(sp.X, sp.Y) - center).Magnitude <= C.FOVRadius then
                inFov += 1
            end
        end

        local nearestStuds = nearest == math.huge and 0 or math.floor(nearest)
        inFovStat:Set(inFov)
        nearestStat:Set(nearestStuds)
        closingStat:Set(nearestStuds)

        local _, entity = findTarget()
        local plr = entity and plrs:GetPlayerFromCharacter(entity)
        local name, pct = nil, 0
        if entity then
            name = plr and plr.Name or entity.Name
            local hum = entity:FindFirstChildOfClass("Humanoid")
            local hp = hum and hum.Health or entity:GetAttribute("Health")
            local maxHp = hum and hum.MaxHealth or entity:GetAttribute("MaxHealth")
            if hp and maxHp and maxHp > 0 then pct = math.clamp(hp / maxHp, 0, 1) * 100 end
        end
        targetText:Set(name and ("Locked on " .. name) or "No target")
        healthBar:Set(pct)

        local active = aimActive()
        local stage = 0
        if inFov > 0 then stage = 1 end
        if stage >= 1 and active then stage = 2 end
        if active and entity then stage = 3 end
        stageBar:Set(stage)

        if not active then
            lastName = nil
        elseif name ~= lastName then
            lastName = name
            if name then
                locks += 1
                locksStat:Set(locks)
                log("target: " .. name)
            end
        end
    end
end)


Library:Toggle()
]=====]

local BOOT = [=====[
local SRC, AUTO, DELAY, BOOT, QUEUED = ...
if not game:IsLoaded() then game.Loaded:Wait() end
local jid = game.JobId ~= "" and game.JobId or "studio"
if getgenv().SkywareRan == jid then return end
getgenv().SkywareRan = jid

local f, e = loadstring(SRC)
if not f then warn("[Skyware] compile error: " .. tostring(e)) getgenv().SkywareRan = nil return end
local ok, err = xpcall(f, debug.traceback)
if not ok then warn("[Skyware] " .. tostring(err)) getgenv().SkywareRan = nil end
]=====]

loadstring(BOOT)(SRC, AUTO_EXECUTE, LOAD_DELAY, BOOT, COUNTDOWN_ON_FIRST_RUN)
