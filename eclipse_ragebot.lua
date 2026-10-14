-- eclipse.wtf | fallen — full ragebot build
-- UI lib: eclipse (pastebin-11) + ragebot engine merged
-- target: Rivals / Fallen (Roblox)

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()
local ViewportSize = workspace.CurrentCamera.ViewportSize

local CFG = {
    MainColor = Color3.fromRGB(14, 14, 14),
    SecondaryColor = Color3.fromRGB(26, 26, 26),
    AccentColor = Color3.fromRGB(189, 172, 255),
    TextColor = Color3.fromRGB(200, 200, 200),
    TextDark = Color3.fromRGB(120, 120, 120),
    StrokeColor = Color3.fromRGB(40, 40, 40),
    Font = Enum.Font.Code,
    BaseSize = Vector2.new(600, 450)
}

local Library = {
    Flags = {},
    Connections = {},
    Unloaded = false
}

local function Create(class, props, children)
    local inst = Instance.new(class)
    for i, v in pairs(props or {}) do
        inst[i] = v
    end
    for _, child in pairs(children or {}) do
        child.Parent = inst
    end
    return inst
end

local function Tween(obj, props, time, style, dir)
    TweenService:Create(obj, TweenInfo.new(time or 0.2, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props):Play()
end

local function GetTextSize(text, size, font)
    return game:GetService("TextService"):GetTextSize(text, size, font, Vector2.new(10000, 10000))
end

local ScreenGui = Create("ScreenGui", {
    Name = "EclipseUI",
    Parent = game:GetService("CoreGui"),
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    ResetOnSpawn = false,
    IgnoreGuiInset = true
})

local UIScale = Create("UIScale", {Parent = ScreenGui})

local function UpdateScale()
    local vp = workspace.CurrentCamera.ViewportSize
    local widthRatio = (vp.X - 40) / CFG.BaseSize.X
    local heightRatio = (vp.Y - 40) / CFG.BaseSize.Y
    local scale = math.min(widthRatio, heightRatio, 1)
    UIScale.Scale = math.max(scale, 0.6)
end

workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateScale)
UpdateScale()

local NotificationContainer = Create("Frame", {
    Parent = ScreenGui,
    Position = UDim2.new(1, -20, 0, 20),
    AnchorPoint = Vector2.new(1, 0),
    Size = UDim2.new(0, 300, 1, 0),
    BackgroundTransparency = 1,
    ZIndex = 100
})
local UIListNotif = Create("UIListLayout", {
    Parent = NotificationContainer,
    Padding = UDim.new(0, 5),
    HorizontalAlignment = Enum.HorizontalAlignment.Right,
    VerticalAlignment = Enum.VerticalAlignment.Top
})

function Library:Notify(msg, type)
    local color = (type == "success" and Color3.fromRGB(100, 255, 100)) or
                  (type == "warning" and Color3.fromRGB(255, 100, 100)) or
                  CFG.AccentColor

    local Frame = Create("Frame", {
        Parent = NotificationContainer,
        Size = UDim2.new(0, 0, 0, 30),
        BackgroundColor3 = CFG.MainColor,
        BorderSizePixel = 0,
        ClipsDescendants = true
    }, {
        Create("UIStroke", {Color = CFG.AccentColor, Thickness = 1, Transparency = 0.5}),
        Create("Frame", {
            Size = UDim2.new(0, 2, 1, 0),
            BackgroundColor3 = color
        }),
        Create("TextLabel", {
            Text = msg,
            TextColor3 = CFG.TextColor,
            Font = CFG.Font,
            TextSize = 12,
            Size = UDim2.new(1, -10, 1, 0),
            Position = UDim2.new(0, 10, 0, 0),
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left
        })
    })

    Tween(Frame, {Size = UDim2.new(0, 250, 0, 35)}, 0.5, Enum.EasingStyle.Back)

    task.delay(3, function()
        Tween(Frame, {Size = UDim2.new(0, 250, 0, 0), BackgroundTransparency = 1}, 0.5)
        task.wait(0.5)
        Frame:Destroy()
    end)
end

local TooltipLabel = Create("TextLabel", {
    Parent = ScreenGui,
    Size = UDim2.new(0, 0, 0, 20),
    BackgroundColor3 = CFG.SecondaryColor,
    TextColor3 = CFG.TextColor,
    TextSize = 11,
    Font = CFG.Font,
    BorderSizePixel = 0,
    Visible = false,
    ZIndex = 200
}, {
    Create("UIPadding", {PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5)}),
    Create("UIStroke", {Color = CFG.StrokeColor})
})

local function AddTooltip(obj, text)
    obj.MouseEnter:Connect(function()
        TooltipLabel.Text = text
        TooltipLabel.Size = UDim2.fromOffset(GetTextSize(text, 11, CFG.Font).X + 12, 20)
        TooltipLabel.Visible = true
    end)
    obj.MouseLeave:Connect(function()
        TooltipLabel.Visible = false
    end)
end

RunService.RenderStepped:Connect(function()
    if TooltipLabel.Visible then
        local m = UserInputService:GetMouseLocation()
        TooltipLabel.Position = UDim2.fromOffset(m.X + 15, m.Y + 15)
    end
end)

local MainFrame = Create("Frame", {
    Name = "MainFrame",
    Parent = ScreenGui,
    Size = UDim2.fromOffset(CFG.BaseSize.X, CFG.BaseSize.Y),
    Position = UDim2.new(0.5, -300, 0.5, -225),
    BackgroundColor3 = CFG.MainColor,
    BorderSizePixel = 0
}, {
    Create("UIStroke", {Color = CFG.StrokeColor}),
    Create("UICorner", {CornerRadius = UDim.new(0, 3)})
})

local Dragging, DragInput, DragStart, StartPos = false, nil, nil, nil

MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        Dragging = true
        DragStart = input.Position
        StartPos = MainFrame.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                Dragging = false
            end
        end)
    end
end)

MainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        DragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == DragInput and Dragging then
        local delta = input.Position - DragStart
        Tween(MainFrame, {Position = UDim2.new(StartPos.X.Scale, StartPos.X.Offset + delta.X, StartPos.Y.Scale, StartPos.Y.Offset + delta.Y)}, 0.05)
    end
end)

local TopBar = Create("Frame", {
    Parent = MainFrame,
    Size = UDim2.new(1, 0, 0, 30),
    BackgroundColor3 = CFG.MainColor,
    BorderSizePixel = 0
}, {
    Create("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = CFG.StrokeColor
    })
})

local TitleLabel = Create("TextLabel", {
    Parent = TopBar,
    Text = "eclipse.wtf | fallen",
    TextColor3 = CFG.TextDark,
    TextSize = 13,
    Font = CFG.Font,
    BackgroundTransparency = 1,
    Size = UDim2.new(0, 200, 1, 0),
    Position = UDim2.new(0, 10, 0, 0),
    TextXAlignment = Enum.TextXAlignment.Left,
    RichText = true
})

task.spawn(function()
    local textList = {
        '', 'e', 'ec', 'ecl', 'ecli', 'eclip', 'eclipse', 'eclipse.', 'eclipse.w',
        'eclipse.wt', 'eclipse.wtf', 'eclipse.wtf |', 'eclipse.wtf | u',
        'eclipse.wtf | un', 'eclipse.wtf | uni', 'eclipse.wtf | univ', 'eclipse.wtf | univers',
        'eclipse.wtf | universa', 'eclipse.wtf | universal', 'eclipse.wtf | universa',
        'eclipse.wtf | univers', 'eclipse.wtf | univer', 'eclipse.wtf | unive',
        'eclipse.wtf | univ', 'eclipse.wtf | uni', 'eclipse.wtf | un', 'eclipse.wtf | u',
        'eclipse.wtf |', 'eclipse.wtf', 'eclipse.wt', 'eclipse.w', 'eclipse.',
        'eclipse', 'eclips', 'eclip', 'ecli', 'ecl', 'ec', 'e'
    }
    while not Library.Unloaded do
        for _, text in ipairs(textList) do
            if Library.Unloaded then break end
            local display = text
            if string.find(text, "fallen") then
                display = string.gsub(text, "fallen", '<font color="#bdacff">fallen</font>')
            elseif string.find(text, "wtf") then
                display = string.gsub(text, "wtf", '<font color="#bdacff">wtf</font>')
            end
            TitleLabel.Text = display
            task.wait(0.2)
        end
    end
end)

local ContentContainer = Create("Frame", {
    Parent = MainFrame,
    Size = UDim2.new(1, 0, 1, -30),
    Position = UDim2.new(0, 0, 0, 30),
    BackgroundTransparency = 1
})

local Sidebar = Create("Frame", {
    Parent = ContentContainer,
    Size = UDim2.new(0, 60, 1, 0),
    BackgroundColor3 = Color3.fromRGB(17, 17, 17),
    BorderSizePixel = 0,
    Position = UDim2.new(0, 0, 0, 0)
}, {
    Create("Frame", {Size = UDim2.new(0, 1, 0, 0), Position = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, BackgroundColor3 = CFG.StrokeColor}),
    Create("UIListLayout", {Padding = UDim.new(0, 10), HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Top}),
    Create("UIPadding", {PaddingTop = UDim.new(0, 15)})
})

local PagesContainer = Create("Frame", {
    Parent = ContentContainer,
    Size = UDim2.new(1, -60, 1, 0),
    Position = UDim2.new(0, 60, 0, 0),
    BackgroundTransparency = 1
})

local Tabs = {}
local CurrentTab = nil

function Library:Tab(name, icon)
    local TabButton = Create("TextButton", {
        Parent = Sidebar,
        Size = UDim2.new(0, 40, 0, 40),
        BackgroundColor3 = CFG.MainColor,
        Text = "",
        TextSize = 20,
        TextColor3 = CFG.TextDark,
        Font = CFG.Font,
        AutoButtonColor = false
    }, {
        Create("ImageLabel", {
            Name = "Icon",
            Size = UDim2.new(0.6, 0, 0.6, 0),
            Position = UDim2.new(0.2, 0, 0.2, 0),
            BackgroundTransparency = 1,
            Image = "rbxassetid://" .. icon,
            ImageColor3 = CFG.TextDark
        }),
        Create("UICorner", {CornerRadius = UDim.new(0, 6)})
    })

    local PageFrame = Create("ScrollingFrame", {
        Parent = PagesContainer,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Visible = false,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = CFG.AccentColor,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y
    }, {
        Create("UIPadding", {PaddingTop = UDim.new(0, 15), PaddingLeft = UDim.new(0, 15), PaddingRight = UDim.new(0, 15), PaddingBottom = UDim.new(0, 15)}),
        Create("UIGridLayout", {
            CellSize = UDim2.new(0.48, 0, 0, 0),
            CellPadding = UDim2.new(0.02, 0, 0, 10),
            FillDirectionMaxCells = 2
        })
    })

    PageFrame:ClearAllChildren()
    local Padding = Create("UIPadding", {Parent = PageFrame, PaddingTop = UDim.new(0, 15), PaddingLeft = UDim.new(0, 15), PaddingRight = UDim.new(0, 15), PaddingBottom = UDim.new(0, 15)})

    local LeftCol = Create("Frame", {Parent = PageFrame, Size = UDim2.new(0.48, 0, 1, 0), BackgroundTransparency = 1}, {
        Create("UIListLayout", {Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder})
    })
    local RightCol = Create("Frame", {Parent = PageFrame, Size = UDim2.new(0.48, 0, 1, 0), Position = UDim2.new(0.52, 0, 0, 0), BackgroundTransparency = 1}, {
        Create("UIListLayout", {Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder})
    })

    TabButton.MouseButton1Click:Connect(function()
        for _, t in pairs(Tabs) do
            Tween(t.Btn, {TextColor3 = CFG.TextDark, BackgroundColor3 = CFG.MainColor}, 0.2)
            t.Page.Visible = false
        end
        Tween(TabButton, {TextColor3 = CFG.AccentColor, BackgroundColor3 = CFG.SecondaryColor}, 0.2)
        PageFrame.Visible = true
        CurrentTab = PageFrame
    end)

    table.insert(Tabs, {Btn = TabButton, Page = PageFrame})

    if #Tabs == 1 then
        Tween(TabButton, {TextColor3 = CFG.AccentColor, BackgroundColor3 = CFG.SecondaryColor}, 0.2)
        PageFrame.Visible = true
    end

    local GroupFunctions = {}
    local LeftSide = true

    function GroupFunctions:Group(title)
        local ParentCol = LeftSide and LeftCol or RightCol
        LeftSide = not LeftSide

        local GroupFrame = Create("Frame", {
            Parent = ParentCol,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = Color3.fromRGB(17, 17, 17),
            BorderSizePixel = 0
        }, {
            Create("UIStroke", {Color = CFG.StrokeColor}),
            Create("UICorner", {CornerRadius = UDim.new(0, 2)})
        })

        Create("Frame", {
            Parent = GroupFrame,
            Size = UDim2.new(1, 0, 0, 25),
            BackgroundColor3 = CFG.SecondaryColor,
            BorderSizePixel = 0
        }, {
            Create("UICorner", {CornerRadius = UDim.new(0, 2)}),
            Create("Frame", {
                Size = UDim2.new(1, 0, 0, 5),
                Position = UDim2.new(0, 0, 1, -5),
                BackgroundColor3 = CFG.SecondaryColor,
                BorderSizePixel = 0
            }),
            Create("TextLabel", {
                Text = title,
                Size = UDim2.new(1, -20, 1, 0),
                Position = UDim2.new(0, 8, 0, 0),
                BackgroundTransparency = 1,
                TextColor3 = CFG.TextColor,
                Font = Enum.Font.GothamBold,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left
            }),
            Create("Frame", {
                Size = UDim2.new(0, 4, 0, 4),
                Position = UDim2.new(1, -10, 0.5, -2),
                BackgroundColor3 = CFG.AccentColor,
                BorderSizePixel = 0
            }, {Create("UICorner", {CornerRadius = UDim.new(1, 0)})})
        })

        local Content = Create("Frame", {
            Parent = GroupFrame,
            Size = UDim2.new(1, 0, 0, 0),
            Position = UDim2.new(0, 0, 0, 25),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1
        }, {
            Create("UIListLayout", {Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder}),
            Create("UIPadding", {PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)})
        })

        local ItemFuncs = {}

        function ItemFuncs:Toggle(cfg)
            local Enabled = cfg.Default or false
            local Frame = Create("TextButton", {
                Parent = Content,
                Size = UDim2.new(1, 0, 0, 20),
                BackgroundTransparency = 1,
                Text = ""
            })

            local Box = Create("Frame", {
                Parent = Frame,
                Size = UDim2.new(0, 12, 0, 12),
                Position = UDim2.new(0, 0, 0.5, -6),
                BackgroundColor3 = CFG.SecondaryColor,
                BorderSizePixel = 0
            }, {Create("UIStroke", {Color = CFG.StrokeColor})})

            local Check = Create("Frame", {
                Parent = Box,
                Size = UDim2.new(1, -4, 1, -4),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = CFG.AccentColor,
                BackgroundTransparency = Enabled and 0 or 1
            })

            local Label = Create("TextLabel", {
                Parent = Frame,
                Text = cfg.Name,
                TextColor3 = Enabled and CFG.TextColor or (cfg.Risky and Color3.fromRGB(200, 80, 80) or CFG.TextDark),
                TextSize = 11,
                Font = CFG.Font,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 18, 0, 0),
                Size = UDim2.new(1, -18, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left
            })

            if cfg.Risky then Label.TextColor3 = Color3.fromRGB(200, 80, 80) end
            if cfg.Tooltip then AddTooltip(Frame, cfg.Tooltip) end

            if cfg.Flag then Library.Flags[cfg.Flag] = Enabled end

            local function Update()
                Enabled = not Enabled
                Tween(Check, {BackgroundTransparency = Enabled and 0 or 1}, 0.1)
                Tween(Label, {TextColor3 = Enabled and CFG.TextColor or (cfg.Risky and Color3.fromRGB(200, 80, 80) or CFG.TextDark)}, 0.1)
                if cfg.Flag then Library.Flags[cfg.Flag] = Enabled end
                if cfg.Callback then cfg.Callback(Enabled) end
            end

            Frame.MouseButton1Click:Connect(Update)
            return {Set = function(v) if v ~= Enabled then Update() end end}
        end

        function ItemFuncs:Slider(cfg)
            local Value = cfg.Default or cfg.Min
            local DraggingSlider = false

            if cfg.Flag then Library.Flags[cfg.Flag] = Value end

            local Frame = Create("Frame", {
                Parent = Content,
                Size = UDim2.new(1, 0, 0, 32),
                BackgroundTransparency = 1
            })

            local Label = Create("TextLabel", {
                Parent = Frame,
                Text = cfg.Name,
                TextColor3 = CFG.TextDark,
                TextSize = 11,
                Font = CFG.Font,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 15),
                TextXAlignment = Enum.TextXAlignment.Left
            })

            local ValueLabel = Create("TextLabel", {
                Parent = Frame,
                Text = Value .. (cfg.Unit or ""),
                TextColor3 = CFG.TextDark,
                TextSize = 11,
                Font = CFG.Font,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 15),
                TextXAlignment = Enum.TextXAlignment.Right
            })

            local SliderBG = Create("Frame", {
                Parent = Frame,
                Size = UDim2.new(1, 0, 0, 6),
                Position = UDim2.new(0, 0, 0, 20),
                BackgroundColor3 = CFG.SecondaryColor,
                BorderSizePixel = 0
            }, {
                Create("UIStroke", {Color = CFG.StrokeColor}),
                Create("UICorner", {CornerRadius = UDim.new(1, 0)})
            })

            local Fill = Create("Frame", {
                Parent = SliderBG,
                Size = UDim2.new(0, 0, 1, 0),
                BackgroundColor3 = CFG.AccentColor
            }, {Create("UICorner", {CornerRadius = UDim.new(1, 0)})})

            local function Update(input)
                local SizeX = SliderBG.AbsoluteSize.X
                local PosX = SliderBG.AbsolutePosition.X
                local InputX = input.Position.X

                local Percent = math.clamp((InputX - PosX) / SizeX, 0, 1)
                Value = math.floor(cfg.Min + (cfg.Max - cfg.Min) * Percent)

                Fill.Size = UDim2.new(Percent, 0, 1, 0)
                ValueLabel.Text = Value .. (cfg.Unit or "")
                if cfg.Flag then Library.Flags[cfg.Flag] = Value end
                if cfg.Callback then cfg.Callback(Value) end
            end

            local percent = (Value - cfg.Min) / (cfg.Max - cfg.Min)
            Fill.Size = UDim2.new(percent, 0, 1, 0)

            Frame.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    DraggingSlider = true
                    Update(input)
                end
            end)

            UserInputService.InputChanged:Connect(function(input)
                if DraggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    Update(input)
                end
            end)

            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    DraggingSlider = false
                end
            end)

            if cfg.Tooltip then AddTooltip(Frame, cfg.Tooltip) end
        end

        function ItemFuncs:Dropdown(cfg)
            local Expanded = false
            local Current = cfg.Default or cfg.Options[1]

            if cfg.Flag then Library.Flags[cfg.Flag] = Current end

            local Frame = Create("Frame", {
                Parent = Content,
                Size = UDim2.new(1, 0, 0, 36),
                BackgroundTransparency = 1,
                ZIndex = 20
            })

            Create("TextLabel", {
                Parent = Frame,
                Text = cfg.Name,
                TextColor3 = CFG.TextDark,
                TextSize = 11,
                Font = CFG.Font,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 15),
                TextXAlignment = Enum.TextXAlignment.Left
            })

            local MainBox = Create("TextButton", {
                Parent = Frame,
                Size = UDim2.new(1, 0, 0, 20),
                Position = UDim2.new(0, 0, 0, 16),
                BackgroundColor3 = CFG.SecondaryColor,
                BorderSizePixel = 0,
                Text = "",
                AutoButtonColor = false
            }, {
                Create("UIStroke", {Color = CFG.StrokeColor}),
                Create("UICorner", {CornerRadius = UDim.new(0, 3)}),
                Create("TextLabel", {
                    Name = "Val",
                    Text = Current,
                    Size = UDim2.new(1, -20, 1, 0),
                    Position = UDim2.new(0, 5, 0, 0),
                    BackgroundTransparency = 1,
                    TextColor3 = CFG.TextColor,
                    TextSize = 11,
                    Font = CFG.Font,
                    TextXAlignment = Enum.TextXAlignment.Left
                }),
                Create("TextLabel", {
                    Text = "▼",
                    Size = UDim2.new(0, 20, 1, 0),
                    Position = UDim2.new(1, -20, 0, 0),
                    BackgroundTransparency = 1,
                    TextColor3 = CFG.TextDark,
                    TextSize = 10
                })
            })

            local ListFrame = Create("ScrollingFrame", {
                Parent = MainBox,
                Size = UDim2.new(1, 0, 0, 0),
                Position = UDim2.new(0, 0, 1, 2),
                BackgroundColor3 = CFG.SecondaryColor,
                BorderSizePixel = 0,
                Visible = false,
                ZIndex = 50,
                CanvasSize = UDim2.new(0, 0, 0, 0),
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                ScrollBarThickness = 2
            }, {
                Create("UIStroke", {Color = CFG.StrokeColor}),
                Create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder}),
                Create("UICorner", {CornerRadius = UDim.new(0, 3)})
            })

            for _, opt in pairs(cfg.Options) do
                local Btn = Create("TextButton", {
                    Parent = ListFrame,
                    Size = UDim2.new(1, 0, 0, 20),
                    BackgroundTransparency = 1,
                    Text = opt,
                    TextColor3 = (opt == Current) and CFG.AccentColor or CFG.TextDark,
                    TextSize = 11,
                    Font = CFG.Font
                })
                Btn.MouseButton1Click:Connect(function()
                    Current = opt
                    MainBox.Val.Text = opt
                    if cfg.Flag then Library.Flags[cfg.Flag] = opt end
                    if cfg.Callback then cfg.Callback(opt) end
                    Expanded = false
                    Tween(ListFrame, {Size = UDim2.new(1, 0, 0, 0)}, 0.1)
                    task.wait(0.1)
                    ListFrame.Visible = false
                end)
            end

            MainBox.MouseButton1Click:Connect(function()
                Expanded = not Expanded
                if Expanded then
                    ListFrame.Visible = true
                    Tween(ListFrame, {Size = UDim2.new(1, 0, 0, math.min(#cfg.Options * 20, 100))}, 0.1)
                else
                    Tween(ListFrame, {Size = UDim2.new(1, 0, 0, 0)}, 0.1)
                    task.wait(0.1)
                    ListFrame.Visible = false
                end
            end)
            if cfg.Tooltip then AddTooltip(Frame, cfg.Tooltip) end
        end

        function ItemFuncs:ColorPicker(cfg)
            local Color = cfg.Default or Color3.fromRGB(255, 255, 255)
            local Opened = false

            local Frame = Create("Frame", {
                Parent = Content,
                Size = UDim2.new(1, 0, 0, 20),
                BackgroundTransparency = 1,
                ZIndex = 15
            })

            Create("TextLabel", {
                Parent = Frame,
                Text = cfg.Name,
                TextColor3 = CFG.TextDark,
                TextSize = 11,
                Font = CFG.Font,
                BackgroundTransparency = 1,
                Size = UDim2.new(0.6, 0, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left
            })

            local Preview = Create("TextButton", {
                Parent = Frame,
                Size = UDim2.new(0, 30, 0, 14),
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, 0, 0.5, 0),
                BackgroundColor3 = Color,
                Text = "",
                AutoButtonColor = false
            }, {
                Create("UIStroke", {Color = CFG.StrokeColor}),
                Create("UICorner", {CornerRadius = UDim.new(0, 3)})
            })

            local PickerFrame = Create("Frame", {
                Parent = Preview,
                Size = UDim2.new(0, 180, 0, 0),
                Position = UDim2.new(1, 0, 1, 5),
                AnchorPoint = Vector2.new(1, 0),
                BackgroundColor3 = CFG.MainColor,
                BorderSizePixel = 0,
                ClipsDescendants = true,
                ZIndex = 60
            }, {
                Create("UIStroke", {Color = CFG.StrokeColor}),
                Create("UICorner", {CornerRadius = UDim.new(0, 3)})
            })

            local SatValPanel = Create("TextButton", {
                Parent = PickerFrame,
                Size = UDim2.new(1, -20, 0, 100),
                Position = UDim2.new(0, 10, 0, 10),
                BackgroundColor3 = Color3.fromHSV(0, 1, 1),
                Text = "",
                AutoButtonColor = false
            }, {
                Create("ImageLabel", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Image = "rbxassetid://4801885019"
                }),
                Create("ImageLabel", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Image = "rbxassetid://4801885019",
                    ImageColor3 = Color3.new(0,0,0),
                    Rotation = 90
                })
            })

            local Cursor = Create("Frame", {
                Parent = SatValPanel,
                Size = UDim2.new(0, 4, 0, 4),
                BackgroundColor3 = Color3.new(1,1,1),
                AnchorPoint = Vector2.new(0.5, 0.5)
            }, {Create("UICorner", {CornerRadius = UDim.new(1, 0)})})

            local HueSlider = Create("TextButton", {
                Parent = PickerFrame,
                Size = UDim2.new(1, -20, 0, 10),
                Position = UDim2.new(0, 10, 0, 120),
                Text = "",
                AutoButtonColor = false
            }, {
                Create("UIGradient", {
                    Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Color3.fromHSV(0,1,1)),
                        ColorSequenceKeypoint.new(0.17, Color3.fromHSV(0.17,1,1)),
                        ColorSequenceKeypoint.new(0.33, Color3.fromHSV(0.33,1,1)),
                        ColorSequenceKeypoint.new(0.5, Color3.fromHSV(0.5,1,1)),
                        ColorSequenceKeypoint.new(0.67, Color3.fromHSV(0.67,1,1)),
                        ColorSequenceKeypoint.new(0.83, Color3.fromHSV(0.83,1,1)),
                        ColorSequenceKeypoint.new(1, Color3.fromHSV(1,1,1))
                    })
                }),
                Create("UICorner", {CornerRadius = UDim.new(0, 2)})
            })

            local H, S, V = 0, 1, 1
            local DraggingHSV, DraggingHue = false, false

            local function UpdateColor()
                Color = Color3.fromHSV(H, S, V)
                Preview.BackgroundColor3 = Color
                SatValPanel.BackgroundColor3 = Color3.fromHSV(H, 1, 1)
                Cursor.Position = UDim2.new(S, 0, 1 - V, 0)
                if cfg.Flag then Library.Flags[cfg.Flag] = Color end
                if cfg.Callback then cfg.Callback(Color) end
            end

            SatValPanel.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                    DraggingHSV = true
                end
            end)
            HueSlider.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                    DraggingHue = true
                end
            end)

            UserInputService.InputEnded:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                    DraggingHSV = false; DraggingHue = false
                end
            end)

            UserInputService.InputChanged:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then
                    if DraggingHSV then
                        local size = SatValPanel.AbsoluteSize
                        local pos = SatValPanel.AbsolutePosition
                        local x = math.clamp((inp.Position.X - pos.X) / size.X, 0, 1)
                        local y = math.clamp((inp.Position.Y - pos.Y) / size.Y, 0, 1)
                        S = x
                        V = 1 - y
                        UpdateColor()
                    elseif DraggingHue then
                        local size = HueSlider.AbsoluteSize
                        local pos = HueSlider.AbsolutePosition
                        local x = math.clamp((inp.Position.X - pos.X) / size.X, 0, 1)
                        H = x
                        UpdateColor()
                    end
                end
            end)

            Preview.MouseButton1Click:Connect(function()
                Opened = not Opened
                if Opened then
                    Tween(PickerFrame, {Size = UDim2.new(0, 180, 0, 170)}, 0.2)
                else
                    Tween(PickerFrame, {Size = UDim2.new(0, 180, 0, 0)}, 0.2)
                end
            end)
            if cfg.Tooltip then AddTooltip(Frame, cfg.Tooltip) end
        end

        function ItemFuncs:Textbox(cfg)
            local Frame = Create("Frame", {
                Parent = Content,
                Size = UDim2.new(1, 0, 0, 35),
                BackgroundTransparency = 1
            })

            Create("TextLabel", {
                Parent = Frame,
                Text = cfg.Name,
                TextColor3 = CFG.TextDark,
                TextSize = 11,
                Font = CFG.Font,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 15),
                TextXAlignment = Enum.TextXAlignment.Left
            })

            local Box = Create("TextBox", {
                Parent = Frame,
                Size = UDim2.new(1, 0, 0, 20),
                Position = UDim2.new(0, 0, 0, 15),
                BackgroundColor3 = CFG.SecondaryColor,
                TextColor3 = CFG.TextColor,
                PlaceholderText = cfg.Placeholder or "...",
                Text = "",
                Font = CFG.Font,
                TextSize = 11,
                BorderSizePixel = 0
            }, {
                Create("UIStroke", {Color = CFG.StrokeColor}),
                Create("UICorner", {CornerRadius = UDim.new(0, 3)}),
                Create("UIPadding", {PaddingLeft = UDim.new(0, 5)})
            })

            Box.FocusLost:Connect(function()
                if cfg.Flag then Library.Flags[cfg.Flag] = Box.Text end
                if cfg.Callback then cfg.Callback(Box.Text) end
            end)
            if cfg.Tooltip then AddTooltip(Frame, cfg.Tooltip) end
        end

        function ItemFuncs:Keybind(cfg)
            local Key = cfg.Default or Enum.KeyCode.Insert
            local Waiting = false

            if cfg.Flag then Library.Flags[cfg.Flag] = Key end

            local Frame = Create("Frame", {
                Parent = Content,
                Size = UDim2.new(1, 0, 0, 20),
                BackgroundTransparency = 1
            })

            Create("TextLabel", {
                Parent = Frame,
                Text = cfg.Name,
                TextColor3 = CFG.TextDark,
                TextSize = 11,
                Font = CFG.Font,
                BackgroundTransparency = 1,
                Size = UDim2.new(0.6, 0, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left
            })

            local Btn = Create("TextButton", {
                Parent = Frame,
                Size = UDim2.new(0, 60, 1, 0),
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, 0, 0, 0),
                BackgroundColor3 = CFG.SecondaryColor,
                Text = Key.Name,
                TextColor3 = CFG.TextDark,
                TextSize = 10,
                Font = CFG.Font
            }, {
                Create("UIStroke", {Color = CFG.StrokeColor}),
                Create("UICorner", {CornerRadius = UDim.new(0, 3)})
            })

            Btn.MouseButton1Click:Connect(function()
                Waiting = true
                Btn.Text = "..."
                Btn.TextColor3 = CFG.AccentColor
            end)

            UserInputService.InputBegan:Connect(function(inp)
                if Waiting and inp.UserInputType == Enum.UserInputType.Keyboard then
                    Waiting = false
                    Key = inp.KeyCode
                    Btn.Text = Key.Name
                    Btn.TextColor3 = CFG.TextDark
                    if cfg.Flag then Library.Flags[cfg.Flag] = Key end
                    if cfg.Callback then cfg.Callback(Key) end
                end
            end)
            if cfg.Tooltip then AddTooltip(Frame, cfg.Tooltip) end
        end

        function ItemFuncs:Button(cfg)
            local Btn = Create("TextButton", {
                Parent = Content,
                Size = UDim2.new(1, 0, 0, 22),
                BackgroundColor3 = CFG.SecondaryColor,
                Text = cfg.Name,
                TextColor3 = CFG.TextDark,
                Font = Enum.Font.GothamBold,
                TextSize = 10
            }, {
                Create("UIStroke", {Color = CFG.StrokeColor}),
                Create("UICorner", {CornerRadius = UDim.new(0, 3)})
            })

            if cfg.Variant == "Primary" then
                Btn.BackgroundColor3 = CFG.AccentColor
                Btn.TextColor3 = Color3.new(0,0,0)
            elseif cfg.Variant == "Danger" then
                Btn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
                Btn.TextColor3 = Color3.new(0,0,0)
            end

            Btn.MouseButton1Click:Connect(function()
                if cfg.Callback then cfg.Callback() end
            end)
            if cfg.Tooltip then AddTooltip(Btn, cfg.Tooltip) end
        end

        return ItemFuncs
    end
    return GroupFunctions
end

-- ============================================================
--  TABS
-- ============================================================
local Legit   = Library:Tab("Legit",   98159911363596)
local Rage    = Library:Tab("Rage",    10455604811)
local Visuals = Library:Tab("Visuals", 10455603612)
local Misc    = Library:Tab("Misc",    11888734334)
local CfgTab  = Library:Tab("Cfg",     12403097620)

-- ============================================================
--  LEGIT TAB
-- ============================================================
local AimGroup = Legit:Group("Aimbot")
AimGroup:Toggle({Name = "Enabled", Flag = "Legit_Aim_Enabled", Tooltip = "Camera-based aim assistance"})
AimGroup:Dropdown({Name = "Priority", Flag = "Legit_Aim_Priority", Options = {"Closest", "Health", "Distance"}, Default = "Closest"})
AimGroup:Slider({Name = "FOV Radius", Flag = "Legit_Aim_FOV", Min = 0, Max = 360, Default = 100, Unit = "°"})
AimGroup:Slider({Name = "Smoothness", Flag = "Legit_Aim_Smooth", Min = 1, Max = 50, Default = 10, Tooltip = "Higher = smoother / slower aim"})
AimGroup:Dropdown({Name = "Target Part", Flag = "Legit_Aim_Part", Options = {"Head", "HumanoidRootPart", "Torso"}, Default = "Head"})
AimGroup:Toggle({Name = "Visible Only", Flag = "Legit_Aim_VisOnly", Tooltip = "Only aim at visible targets"})
AimGroup:Keybind({Name = "Aim Key", Flag = "Legit_Aim_Key", Default = Enum.KeyCode.RightControl})
AimGroup:ColorPicker({Name = "FOV Color", Flag = "Legit_FOV_Color", Default = CFG.AccentColor})

local SilentGroup = Legit:Group("Silent Aim")
SilentGroup:Toggle({Name = "Enabled", Flag = "Legit_Silent_Enabled", Tooltip = "Redirect projectiles to target"})
SilentGroup:Slider({Name = "Prediction", Flag = "Legit_Silent_Pred", Min = 0, Max = 100, Default = 90, Unit = "%", Tooltip = "Velocity prediction multiplier"})
SilentGroup:Dropdown({Name = "Target Part", Flag = "Legit_Silent_Part", Options = {"Head", "HumanoidRootPart"}, Default = "Head"})
SilentGroup:Slider({Name = "Hitchance", Flag = "Legit_Silent_Hit", Min = 1, Max = 100, Default = 100, Unit = "%"})

-- ============================================================
--  RAGE TAB
-- ============================================================

-- § ACTIVATION (Left)
local RageActivation = Rage:Group("Activation")
RageActivation:Toggle({
    Name = "Ragebot Enabled",
    Flag = "Rage_Enabled",
    Tooltip = "Master switch for all ragebot features"
})
RageActivation:Dropdown({
    Name = "Keybind Mode",
    Flag = "Rage_KeyMode",
    Options = {"Always", "Toggle", "Hold"},
    Default = "Always",
    Tooltip = "How the ragebot key activates"
})
RageActivation:Keybind({
    Name = "Ragebot Key",
    Flag = "Rage_Key",
    Default = Enum.KeyCode.RightShift
})
RageActivation:Toggle({
    Name = "Prioritize Hackers",
    Flag = "Rage_PrioritizeHackers",
    Tooltip = "Target detected cheaters first"
})
RageActivation:Toggle({
    Name = "Utilize Health Lead",
    Flag = "Rage_HealthLead",
    Tooltip = "Factor in target health when selecting"
})
RageActivation:Slider({
    Name = "Stability",
    Flag = "Rage_Stability",
    Min = 0, Max = 50, Default = 2,
    Tooltip = "Ragebot position stability (x0.1 internally)"
})
RageActivation:Slider({
    Name = "Shoot Frames",
    Flag = "Rage_ShootFrames",
    Min = 1, Max = 50, Default = 1,
    Tooltip = "Frames to hold fire per attack"
})

-- § WEAPON STRATEGY (Right)
local RageWeaponStrat = Rage:Group("Weapon Strategy")
RageWeaponStrat:Toggle({
    Name = "Primary Enabled",
    Flag = "Rage_Weap_Primary",
    Default = true,
    Tooltip = "Ragebot uses Primary slot weapons"
})
RageWeaponStrat:Toggle({
    Name = "Secondary Enabled",
    Flag = "Rage_Weap_Secondary",
    Default = true,
    Tooltip = "Ragebot uses Secondary slot weapons"
})
RageWeaponStrat:Toggle({
    Name = "Melee Enabled",
    Flag = "Rage_Weap_Melee",
    Default = true,
    Tooltip = "Ragebot uses Melee weapons"
})
RageWeaponStrat:Dropdown({
    Name = "On Empty",
    Flag = "Rage_OnEmpty",
    Options = {"Reload", "Swap", "Swap or Reload"},
    Default = "Swap or Reload",
    Tooltip = "What to do when ammo runs out"
})
RageWeaponStrat:Dropdown({
    Name = "Weapon Priority",
    Flag = "Rage_Priority",
    Options = {"Primary First", "Secondary First", "Melee First"},
    Default = "Primary First",
    Tooltip = "Which weapon slot gets preferred"
})

-- § MELEE (Left)
local RageMelee = Rage:Group("Melee")
RageMelee:Toggle({
    Name = "Melee Ragebot",
    Flag = "Rage_Melee_Enabled",
    Default = true,
    Tooltip = "Enable ragebot behaviour for melee weapons"
})
RageMelee:Dropdown({
    Name = "Target Part",
    Flag = "Rage_Melee_Part",
    Options = {"HumanoidRootPart", "Head"},
    Default = "HumanoidRootPart"
})
RageMelee:Slider({
    Name = "Max Engage Distance",
    Flag = "Rage_Melee_MaxDist",
    Min = 5, Max = 60, Default = 20,
    Unit = " st",
    Tooltip = "Max studs to engage a melee target"
})
RageMelee:Toggle({
    Name = "Extend Melee Range",
    Flag = "Rage_Melee_ExtendEnabled",
    Tooltip = "Patch attack CFrame to reach further"
})
RageMelee:Slider({
    Name = "Extra Range",
    Flag = "Rage_Melee_ExtendRange",
    Min = 1, Max = 30, Default = 10,
    Unit = " st",
    Tooltip = "Studs of extra reach (Extend Range must be on)"
})
RageMelee:Toggle({
    Name = "Reduce Melee Cooldown",
    Flag = "Rage_Melee_CdEnabled",
    Tooltip = "Reduce attack cooldown via server patch"
})
RageMelee:Slider({
    Name = "Melee Cooldown %",
    Flag = "Rage_Melee_CdPct",
    Min = 1, Max = 100, Default = 25,
    Unit = "%",
    Tooltip = "Cooldown percentage of base (lower = faster)"
})
RageMelee:Toggle({
    Name = "Always Backstab",
    Flag = "Rage_Melee_Backstab",
    Tooltip = "Rotate to face away from target before hitting"
})
RageMelee:Toggle({
    Name = "Auto Spin",
    Flag = "Rage_Melee_AutoSpin",
    Tooltip = "Continuously spin to land backstabs",
    Risky = true
})

-- § KNIFE (Right)
local RageKnife = Rage:Group("Knife")
RageKnife:Toggle({
    Name = "Knife Ragebot",
    Flag = "Rage_Knife_Enabled",
    Default = true,
    Tooltip = "Enable ragebot for knife (throwable)"
})
RageKnife:Toggle({
    Name = "Auto Throw",
    Flag = "Rage_Knife_AutoThrow",
    Default = true,
    Tooltip = "Automatically throw knife at best target"
})
RageKnife:Dropdown({
    Name = "Target Part",
    Flag = "Rage_Knife_Part",
    Options = {"Head", "HumanoidRootPart"},
    Default = "Head"
})
RageKnife:Slider({
    Name = "Prediction",
    Flag = "Rage_Knife_Pred",
    Min = 0, Max = 100, Default = 90,
    Unit = "%",
    Tooltip = "Velocity lead compensation (0=off, 100=full)"
})
RageKnife:Toggle({
    Name = "Arc Compensation",
    Flag = "Rage_Knife_Arc",
    Default = true,
    Tooltip = "Compensate for projectile gravity drop"
})
RageKnife:Slider({
    Name = "Max Throw Distance",
    Flag = "Rage_Knife_MaxDist",
    Min = 10, Max = 120, Default = 50,
    Unit = " st"
})
RageKnife:Toggle({
    Name = "Reduce Knife Cooldown",
    Flag = "Rage_Knife_CdEnabled",
    Tooltip = "Reduce throw cooldown",
    Risky = true
})
RageKnife:Slider({
    Name = "Knife Cooldown %",
    Flag = "Rage_Knife_CdPct",
    Min = 1, Max = 100, Default = 25,
    Unit = "%"
})

-- § PRIMARY GUN (Left)
local RagePrimary = Rage:Group("Primary")
RagePrimary:Toggle({
    Name = "Primary Ragebot",
    Flag = "Rage_Primary_Enabled",
    Default = true
})
RagePrimary:Dropdown({
    Name = "Target Part",
    Flag = "Rage_Primary_Part",
    Options = {"Head", "HumanoidRootPart"},
    Default = "Head"
})
RagePrimary:Slider({
    Name = "FOV",
    Flag = "Rage_Primary_FOV",
    Min = 1, Max = 360, Default = 90,
    Unit = "°"
})
RagePrimary:Slider({
    Name = "Hitchance",
    Flag = "Rage_Primary_Hit",
    Min = 1, Max = 100, Default = 100,
    Unit = "%"
})
RagePrimary:Slider({
    Name = "Prediction",
    Flag = "Rage_Primary_Pred",
    Min = 0, Max = 100, Default = 90,
    Unit = "%"
})
RagePrimary:Toggle({
    Name = "No Spread",
    Flag = "Rage_Primary_NoSpread",
    Tooltip = "Remove weapon spread angle",
    Risky = true
})
RagePrimary:Toggle({
    Name = "Full Auto",
    Flag = "Rage_Primary_FullAuto",
    Tooltip = "Force weapon to fire fully automatic",
    Risky = true
})
RagePrimary:Toggle({
    Name = "Reduce Fire Cooldown",
    Flag = "Rage_Primary_FireCdEnabled"
})
RagePrimary:Slider({
    Name = "Fire Cooldown %",
    Flag = "Rage_Primary_FireCdPct",
    Min = 1, Max = 100, Default = 25,
    Unit = "%"
})
RagePrimary:Toggle({
    Name = "Reduce Aim Cooldown",
    Flag = "Rage_Primary_AimCdEnabled"
})
RagePrimary:Slider({
    Name = "Aim Cooldown %",
    Flag = "Rage_Primary_AimCdPct",
    Min = 1, Max = 100, Default = 50,
    Unit = "%"
})

-- § SECONDARY GUN (Right)
local RageSecondary = Rage:Group("Secondary")
RageSecondary:Toggle({
    Name = "Secondary Ragebot",
    Flag = "Rage_Secondary_Enabled",
    Default = true
})
RageSecondary:Dropdown({
    Name = "Target Part",
    Flag = "Rage_Secondary_Part",
    Options = {"Head", "HumanoidRootPart"},
    Default = "Head"
})
RageSecondary:Slider({
    Name = "FOV",
    Flag = "Rage_Secondary_FOV",
    Min = 1, Max = 360, Default = 90,
    Unit = "°"
})
RageSecondary:Slider({
    Name = "Hitchance",
    Flag = "Rage_Secondary_Hit",
    Min = 1, Max = 100, Default = 100,
    Unit = "%"
})
RageSecondary:Slider({
    Name = "Prediction",
    Flag = "Rage_Secondary_Pred",
    Min = 0, Max = 100, Default = 90,
    Unit = "%"
})
RageSecondary:Toggle({
    Name = "No Spread",
    Flag = "Rage_Secondary_NoSpread",
    Risky = true
})
RageSecondary:Toggle({
    Name = "Full Auto",
    Flag = "Rage_Secondary_FullAuto",
    Risky = true
})
RageSecondary:Toggle({
    Name = "Reduce Fire Cooldown",
    Flag = "Rage_Secondary_FireCdEnabled"
})
RageSecondary:Slider({
    Name = "Fire Cooldown %",
    Flag = "Rage_Secondary_FireCdPct",
    Min = 1, Max = 100, Default = 25,
    Unit = "%"
})
RageSecondary:Toggle({
    Name = "Reduce Aim Cooldown",
    Flag = "Rage_Secondary_AimCdEnabled"
})
RageSecondary:Slider({
    Name = "Aim Cooldown %",
    Flag = "Rage_Secondary_AimCdPct",
    Min = 1, Max = 100, Default = 50,
    Unit = "%"
})

-- § EVASION (Left)
local RageEvasion = Rage:Group("Evasion")
RageEvasion:Dropdown({
    Name = "Evasion Mode",
    Flag = "Rage_Evasion_Mode",
    Options = {"Off", "Random", "Translocate", "Projectile Breaker"},
    Default = "Random",
    Tooltip = "How ragebot moves your character to avoid hits"
})
RageEvasion:Slider({
    Name = "Base Radius",
    Flag = "Rage_Evasion_Radius",
    Min = 5, Max = 500, Default = 100,
    Unit = " st",
    Tooltip = "Random mode: how far from current pos to teleport"
})
RageEvasion:Slider({
    Name = "Random Factor",
    Flag = "Rage_Evasion_RandFactor",
    Min = 0, Max = 50, Default = 5,
    Tooltip = "Extra randomness added to each teleport position"
})
RageEvasion:Slider({
    Name = "Translocate Offset",
    Flag = "Rage_Evasion_Offset",
    Min = -50, Max = 50, Default = -5,
    Tooltip = "Forward/back offset for Translocate mode"
})
RageEvasion:Toggle({
    Name = "Fallback Char Origin",
    Flag = "Rage_Evasion_FallbackOrigin",
    Tooltip = "Anchor random positions to your character"
})
RageEvasion:Slider({
    Name = "PB Forward Depth Max",
    Flag = "Rage_PB_FwdMax",
    Min = 0, Max = 100, Default = 40,
    Tooltip = "Projectile Breaker: max forward dodge depth x0.1"
})
RageEvasion:Slider({
    Name = "PB Forward Frequency",
    Flag = "Rage_PB_FwdFreq",
    Min = 0, Max = 20, Default = 5,
    Tooltip = "How often to dodge forward (Projectile Breaker)"
})
RageEvasion:Slider({
    Name = "PB Upward Depth Max",
    Flag = "Rage_PB_UpMax",
    Min = 0, Max = 55, Default = 28,
    Tooltip = "Projectile Breaker: max upward dodge depth x0.2"
})
RageEvasion:Slider({
    Name = "PB Upward Frequency",
    Flag = "Rage_PB_UpFreq",
    Min = 0, Max = 20, Default = 5,
    Tooltip = "How often to dodge upward (Projectile Breaker)"
})
RageEvasion:Slider({
    Name = "Reposition Interval",
    Flag = "Rage_Evasion_ReposInterval",
    Min = 5, Max = 200, Default = 30,
    Unit = " ms",
    Tooltip = "Time between each evasion repositioning (x0.01s)"
})

-- § FLICKBOT (Right)
local RageFlick = Rage:Group("Flickbot")
RageFlick:Toggle({
    Name = "Flickbot Enabled",
    Flag = "Rage_Flick_Enabled",
    Tooltip = "Fast camera flick to aim at targets"
})
RageFlick:Dropdown({
    Name = "Activate Mode",
    Flag = "Rage_Flick_Mode",
    Options = {"Hold", "Toggle"},
    Default = "Hold"
})
RageFlick:Toggle({
    Name = "Auto Shoot",
    Flag = "Rage_Flick_Shoot",
    Tooltip = "Fire after each flick"
})
RageFlick:Slider({
    Name = "Shot Delay",
    Flag = "Rage_Flick_ShotDelay",
    Min = 0, Max = 250, Default = 0,
    Unit = " ms",
    Tooltip = "Delay between flick and fire"
})
RageFlick:Slider({
    Name = "Cooldown",
    Flag = "Rage_Flick_Cooldown",
    Min = 0, Max = 2000, Default = 250,
    Unit = " ms",
    Tooltip = "Delay between flicks"
})
RageFlick:Slider({
    Name = "Flick Duration",
    Flag = "Rage_Flick_Duration",
    Min = 30, Max = 400, Default = 110,
    Unit = " ms",
    Tooltip = "How long the flick motion takes"
})
RageFlick:Slider({
    Name = "Curvature",
    Flag = "Rage_Flick_Curvature",
    Min = 0, Max = 50, Default = 12,
    Tooltip = "Arc curve amount during flick"
})
RageFlick:Slider({
    Name = "Humanness",
    Flag = "Rage_Flick_Humanness",
    Min = 0, Max = 100, Default = 30,
    Unit = "%",
    Tooltip = "Adds random micro-error to look human"
})

-- ============================================================
--  VISUALS TAB
-- ============================================================
local ESPGroup = Visuals:Group("ESP")
ESPGroup:Toggle({Name = "Enabled", Flag = "ESP_Enabled"})
ESPGroup:Toggle({Name = "Boxes", Flag = "ESP_Boxes"})
ESPGroup:Toggle({Name = "Names", Flag = "ESP_Names"})
ESPGroup:Toggle({Name = "Health Bar", Flag = "ESP_Health"})
ESPGroup:Toggle({Name = "Distance", Flag = "ESP_Distance"})
ESPGroup:Toggle({Name = "Held Weapon", Flag = "ESP_Weapon"})
ESPGroup:Toggle({Name = "Tracers", Flag = "ESP_Tracers"})
ESPGroup:Toggle({Name = "Team Check", Flag = "ESP_TeamCheck", Default = true})
ESPGroup:ColorPicker({Name = "Enemy Color", Flag = "ESP_EnemyColor", Default = Color3.fromRGB(255, 80, 80)})
ESPGroup:ColorPicker({Name = "Team Color", Flag = "ESP_TeamColor", Default = Color3.fromRGB(80, 180, 255)})

local ChamsGroup = Visuals:Group("Chams")
ChamsGroup:Toggle({Name = "Enabled", Flag = "Chams_Enabled"})
ChamsGroup:Dropdown({Name = "Style", Flag = "Chams_Style", Options = {"Ghost", "Neon", "Flat"}, Default = "Ghost"})
ChamsGroup:Toggle({Name = "Team Chams", Flag = "Chams_Team"})
ChamsGroup:Toggle({Name = "Always On Top", Flag = "Chams_AOT"})
ChamsGroup:ColorPicker({Name = "Enemy Fill", Flag = "Chams_EnemyFill", Default = Color3.fromRGB(255, 50, 50)})
ChamsGroup:ColorPicker({Name = "Enemy Outline", Flag = "Chams_EnemyOutline", Default = Color3.fromRGB(100, 0, 0)})

local FOVCircleGroup = Visuals:Group("FOV Circle")
FOVCircleGroup:Toggle({Name = "Enabled", Flag = "FOV_Circle_Enabled"})
FOVCircleGroup:Slider({Name = "Radius", Flag = "FOV_Circle_Radius", Min = 10, Max = 360, Default = 90, Unit = "°"})
FOVCircleGroup:ColorPicker({Name = "Color", Flag = "FOV_Circle_Color", Default = CFG.AccentColor})
FOVCircleGroup:Toggle({Name = "Fill", Flag = "FOV_Circle_Fill"})
FOVCircleGroup:Slider({Name = "Thickness", Flag = "FOV_Circle_Thick", Min = 1, Max = 5, Default = 1})

local WorldGroup = Visuals:Group("World")
WorldGroup:Toggle({Name = "Fullbright", Flag = "Vis_Fullbright"})
WorldGroup:Toggle({Name = "Remove Fog", Flag = "Vis_NoFog"})
WorldGroup:Toggle({Name = "Custom Sky", Flag = "Vis_Sky"})
WorldGroup:Slider({Name = "Ambient", Flag = "Vis_Ambient", Min = 0, Max = 255, Default = 128})

-- ============================================================
--  MISC TAB
-- ============================================================
local MiscMovement = Misc:Group("Movement")
MiscMovement:Toggle({Name = "Speed Hack", Flag = "Misc_Speed", Risky = true})
MiscMovement:Slider({Name = "Walk Speed", Flag = "Misc_WalkSpeed", Min = 16, Max = 200, Default = 16})
MiscMovement:Toggle({Name = "Infinite Jump", Flag = "Misc_InfJump"})
MiscMovement:Toggle({Name = "Noclip", Flag = "Misc_Noclip", Risky = true})
MiscMovement:Toggle({Name = "Flight", Flag = "Misc_Flight", Risky = true})
MiscMovement:Slider({Name = "Flight Speed", Flag = "Misc_FlightSpeed", Min = 10, Max = 300, Default = 100})

local MiscAntiAim = Misc:Group("Anti-Aim")
MiscAntiAim:Toggle({Name = "Enabled", Flag = "AA_Enabled"})
MiscAntiAim:Dropdown({Name = "Pitch", Flag = "AA_Pitch", Options = {"Off", "Down", "Up", "Random"}, Default = "Down"})
MiscAntiAim:Dropdown({Name = "Yaw", Flag = "AA_Yaw", Options = {"Off", "Spin", "Jitter", "Static"}, Default = "Spin"})
MiscAntiAim:Slider({Name = "Spin Speed", Flag = "AA_SpinSpeed", Min = 1, Max = 720, Default = 360, Unit = "°/s"})
MiscAntiAim:Toggle({Name = "Fake Lag", Flag = "AA_FakeLag", Risky = true})
MiscAntiAim:Slider({Name = "Fake Lag Amount", Flag = "AA_FakeLagAmt", Min = 1, Max = 15, Default = 5})

local MiscMisc = Misc:Group("Miscellaneous")
MiscMisc:Toggle({Name = "Anti-Katana", Flag = "Misc_AntiKatana", Default = true, Tooltip = "Block katana deflect"})
MiscMisc:Toggle({Name = "Auto Queue", Flag = "Misc_AutoQueue"})
MiscMisc:Toggle({Name = "Auto Respawn", Flag = "Misc_AutoRespawn"})
MiscMisc:Toggle({Name = "No Camera Shake", Flag = "Misc_NoCamShake"})
MiscMisc:Toggle({Name = "No Muzzle Flash", Flag = "Misc_NoMuzzle"})
MiscMisc:Toggle({Name = "Bullet Tracers", Flag = "Misc_Tracers"})
MiscMisc:ColorPicker({Name = "Tracer Color", Flag = "Misc_TracerColor", Default = Color3.fromRGB(120, 220, 255)})

local MiscNotify = Misc:Group("Notifications")
MiscNotify:Toggle({Name = "Hit Notification", Flag = "Notif_Hit", Default = true})
MiscNotify:Toggle({Name = "Kill Notification", Flag = "Notif_Kill", Default = true})
MiscNotify:Toggle({Name = "Hacker Detector", Flag = "Notif_Hacker"})
MiscNotify:Toggle({Name = "Mod Detector", Flag = "Notif_Mod"})

-- ============================================================
--  CFG TAB
-- ============================================================
local CfgSave = CfgTab:Group("Config")
CfgSave:Textbox({Name = "Config Name", Flag = "Cfg_Name", Placeholder = "my_config"})
CfgSave:Button({
    Name = "Save Config",
    Variant = "Primary",
    Callback = function()
        local name = Library.Flags["Cfg_Name"] or "config"
        local ok, err = pcall(function()
            writefile(name .. ".json", HttpService:JSONEncode(Library.Flags))
        end)
        Library:Notify(ok and ("Saved: " .. name) or "Save failed: " .. tostring(err), ok and "success" or "warning")
    end
})
CfgSave:Button({
    Name = "Load Config",
    Callback = function()
        local name = Library.Flags["Cfg_Name"] or "config"
        local ok, data = pcall(function()
            return HttpService:JSONDecode(readfile(name .. ".json"))
        end)
        if ok then
            for k, v in pairs(data) do Library.Flags[k] = v end
            Library:Notify("Loaded: " .. name, "success")
        else
            Library:Notify("Load failed: " .. name, "warning")
        end
    end
})
CfgSave:Button({
    Name = "Reset Config",
    Variant = "Danger",
    Callback = function()
        for k in pairs(Library.Flags) do Library.Flags[k] = nil end
        Library:Notify("Config reset", "warning")
    end
})

local CfgInfo = CfgTab:Group("Info")
CfgInfo:Button({Name = "Copy Flags (JSON)", Callback = function()
    pcall(function() setclipboard(HttpService:JSONEncode(Library.Flags)) end)
    Library:Notify("Flags copied to clipboard", "success")
end})

-- ============================================================
--  MENU TOGGLE
-- ============================================================
Library.MenuKey = Enum.KeyCode.Insert
local Visible = true

UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Library.MenuKey then
        Visible = not Visible
        MainFrame.Visible = Visible
    end
end)

local MobileToggle = Create("ImageButton", {
    Parent = ScreenGui,
    Size = UDim2.new(0, 40, 0, 40),
    Position = UDim2.new(0.5, 0, 0, 10),
    AnchorPoint = Vector2.new(0.5, 0),
    BackgroundColor3 = CFG.MainColor,
    Image = "rbxassetid://3926305904",
    ImageColor3 = CFG.AccentColor,
    AutoButtonColor = false
}, {
    Create("UICorner", {CornerRadius = UDim.new(1, 0)}),
    Create("UIStroke", {Color = CFG.AccentColor, Thickness = 2})
})

MobileToggle.MouseButton1Click:Connect(function()
    Visible = not Visible
    MainFrame.Visible = Visible
end)

-- ============================================================
--  RAGEBOT RUNTIME ENGINE
-- ============================================================

local F = Library.Flags   -- shorthand

local function flag(k, default)
    local v = F[k]
    if v == nil then return default end
    return v
end

local function getMyChar()
    local char = Player and Player.Character
    if not char then return nil end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum  = char:FindFirstChildOfClass("Humanoid")
    if not root or not hum or hum.Health <= 0 then return nil end
    return char, root, hum
end

local function getEnemies()
    local list = {}
    local myTeam = Player and Player.Team
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Player then
            local sameteam = myTeam and p.Team == myTeam
            if not sameteam then
                local char = p.Character
                if char then
                    local root = char:FindFirstChild("HumanoidRootPart")
                    local hum  = char:FindFirstChildOfClass("Humanoid")
                    if root and hum and hum.Health > 0 then
                        list[#list+1] = {player=p, char=char, root=root, hum=hum}
                    end
                end
            end
        end
    end
    return list
end

local function getBestTarget(originPos, fovDeg, maxDist)
    local cam       = workspace.CurrentCamera
    local best, bestScore = nil, math.huge
    for _, e in ipairs(getEnemies()) do
        local dist = (e.root.Position - originPos).Magnitude
        if dist <= maxDist then
            local sp, onScreen = cam:WorldToScreenPoint(e.root.Position)
            if onScreen then
                local cx = cam.ViewportSize.X / 2
                local cy = cam.ViewportSize.Y / 2
                local pxDist = math.sqrt((sp.X-cx)^2 + (sp.Y-cy)^2)
                local fovPx  = math.tan(math.rad(fovDeg/2)) * cam.ViewportSize.Y * 0.5 * 2
                if pxDist <= fovPx / 2 and pxDist < bestScore then
                    bestScore = pxDist
                    best      = e
                end
            end
        end
    end
    return best
end

local function predictPos(root, pct)
    local vel  = root.AssemblyLinearVelocity
    local ping = (Player:GetAttribute("Ping") or 100) / 1000
    return root.Position + vel * ping * (pct / 100)
end

local function arcCompensate(from, to)
    local g     = math.abs(workspace.Gravity)
    local delta = to - from
    local hDist = math.sqrt(delta.X^2 + delta.Z^2)
    local speed = 80
    local t     = hDist / speed
    return Vector3.new(to.X, to.Y + 0.5 * g * t * t, to.Z)
end

local function getTargetPos(enemy, partFlag, predFlag)
    local pct  = flag(predFlag, 90)
    local part = flag(partFlag, "Head")
    local rp   = enemy.root
    if part == "Head" then
        local head = enemy.char:FindFirstChild("Head")
        if head then rp = head end
    end
    return predictPos(rp, pct)
end

-- timing state
local lastKnife   = 0
local lastFlick   = 0
local flickActive = false
local flickKey    = Enum.KeyCode.RightAlt

UserInputService.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    local key = flag("Rage_Key", Enum.KeyCode.RightShift)
    local mode = flag("Rage_KeyMode", "Always")
    if mode == "Toggle" and inp.KeyCode == key then
        flickActive = not flickActive
    end
    if inp.KeyCode == flag("Rage_Flick_Mode", nil) then
        -- hold handled below
    end
end)

-- ── KNIFE LOGIC ─────────────────────────────────────────────
local function doKnife(char, root, dt)
    if not flag("Rage_Knife_Enabled", false) then return end
    if not flag("Rage_Enabled", false) then return end

    local heldTool = char:FindFirstChildOfClass("Tool")
    if not heldTool then return end
    if not string.find(heldTool.Name:lower(), "knife") then return end

    if not flag("Rage_Knife_AutoThrow", false) then return end

    local cdBase = 1.2
    local cdPct  = flag("Rage_Knife_CdEnabled", false)
        and (flag("Rage_Knife_CdPct", 100) / 100) or 1
    local cd = cdBase * cdPct

    local now = os.clock()
    if now - lastKnife < cd then return end

    local maxDist = flag("Rage_Knife_MaxDist", 50)
    local enemy = getBestTarget(root.Position, 180, maxDist)
    if not enemy then return end

    local aimPos = getTargetPos(enemy, "Rage_Knife_Part", "Rage_Knife_Pred")
    if flag("Rage_Knife_Arc", true) then
        aimPos = arcCompensate(root.Position, aimPos)
    end

    local cam = workspace.CurrentCamera
    cam.CFrame = CFrame.new(cam.CFrame.Position, aimPos)

    local remote = heldTool:FindFirstChildOfClass("RemoteEvent")
    if remote then
        pcall(function() remote:FireServer(aimPos) end)
    else
        pcall(function()
            if heldTool.Activated then heldTool.Activated:Fire() end
        end)
    end

    lastKnife = now
end

-- ── MELEE LOGIC ─────────────────────────────────────────────
local function doMelee(char, root, dt)
    if not flag("Rage_Melee_Enabled", false) then return end
    if not flag("Rage_Enabled", false) then return end

    local heldTool = char:FindFirstChildOfClass("Tool")
    if not heldTool then return end
    local tName = heldTool.Name:lower()
    local isKnife = string.find(tName, "knife")
    local isMelee = not isKnife and (
        string.find(tName, "sword") or string.find(tName, "bat")   or
        string.find(tName, "katana") or string.find(tName, "blade") or
        string.find(tName, "fist") or string.find(tName, "melee") or
        heldTool:FindFirstChild("MeleeTag") ~= nil
    )
    if not isMelee then return end

    local maxDist = flag("Rage_Melee_MaxDist", 20)
    local enemy = getBestTarget(root.Position, 360, maxDist)
    if not enemy then return end

    -- backstab spin
    if flag("Rage_Melee_Backstab", false) and flag("Rage_Melee_AutoSpin", false) then
        local toEnemy = (enemy.root.Position - root.Position).Unit
        local backDir = -toEnemy
        local newCF   = CFrame.new(root.Position, root.Position + backDir)
        pcall(function()
            if sethiddenproperty then
                sethiddenproperty(root, "CFrame", newCF)
            end
        end)
    end

    -- extend range attack patch
    if flag("Rage_Melee_ExtendEnabled", false) then
        local rng = flag("Rage_Melee_ExtendRange", 10)
        local dir = (enemy.root.Position - root.Position).Unit
        local shiftedPos = root.Position + dir * rng
        local attackCF = CFrame.new(shiftedPos) * CFrame.fromOrientation(-math.pi/2, 0, 0)
        local remote = heldTool:FindFirstChildOfClass("RemoteEvent")
        if remote then
            pcall(function() remote:FireServer(attackCF, attackCF) end)
        end
    end

    -- cooldown reduction
    if flag("Rage_Melee_CdEnabled", false) then
        local pct = flag("Rage_Melee_CdPct", 25) / 100
        pcall(function()
            if sethiddenproperty then
                local atkCd = heldTool:GetAttribute("AttackCooldown")
                if atkCd then
                    sethiddenproperty(heldTool, "AttackCooldown", atkCd * pct)
                end
            end
        end)
    end
end

-- ── GUN LOGIC ───────────────────────────────────────────────
local function doGun(char, root, dt)
    if not flag("Rage_Enabled", false) then return end

    local heldTool = char:FindFirstChildOfClass("Tool")
    if not heldTool then return end
    local tName = heldTool.Name:lower()
    local isKnife = string.find(tName, "knife")
    local isMelee = heldTool:FindFirstChild("MeleeTag") ~= nil or
        string.find(tName, "sword") or string.find(tName, "bat") or
        string.find(tName, "katana") or string.find(tName, "blade") or
        string.find(tName, "fist")

    if isKnife or isMelee then return end

    -- detect slot
    local slot = heldTool:GetAttribute("WeaponSlot") or "Primary"
    local prefix = (slot == "Secondary") and "Rage_Secondary" or "Rage_Primary"

    if not flag(prefix .. "_Enabled", false) then return end

    local fov     = flag(prefix .. "_FOV", 90)
    local maxDist = 1000
    local enemy   = getBestTarget(root.Position, fov, maxDist)
    if not enemy then return end

    -- hitchance gate
    local hitChance = flag(prefix .. "_Hit", 100)
    if math.random(1, 100) > hitChance then return end

    local aimPos = getTargetPos(enemy, prefix .. "_Part", prefix .. "_Pred")

    -- aim camera
    local cam = workspace.CurrentCamera
    cam.CFrame = CFrame.new(cam.CFrame.Position, aimPos)

    -- no spread
    if flag(prefix .. "_NoSpread", false) then
        pcall(function()
            if sethiddenproperty then
                sethiddenproperty(heldTool, "SpreadAngle", Vector2.new(0,0))
            end
        end)
    end

    -- full auto
    if flag(prefix .. "_FullAuto", false) then
        pcall(function()
            local attr = heldTool:GetAttribute("InputSpammingEnabled")
            if attr and type(attr) == "table" then
                local clone = table.clone(attr)
                clone.StartShooting = 0
                if sethiddenproperty then
                    sethiddenproperty(heldTool, "InputSpammingEnabled", clone)
                end
            end
        end)
    end

    -- fire cooldown reduction
    if flag(prefix .. "_FireCdEnabled", false) then
        local pct = flag(prefix .. "_FireCdPct", 25) / 100
        pcall(function()
            if sethiddenproperty then
                local base = heldTool:GetAttribute("ShootCooldown")
                if base then sethiddenproperty(heldTool, "ShootCooldown", base * pct) end
            end
        end)
    end

    -- aim cooldown reduction
    if flag(prefix .. "_AimCdEnabled", false) then
        local pct = flag(prefix .. "_AimCdPct", 50) / 100
        pcall(function()
            if sethiddenproperty then
                local base = heldTool:GetAttribute("AimCooldown")
                if base then sethiddenproperty(heldTool, "AimCooldown", base * pct) end
            end
        end)
    end
end

-- ── EVASION LOGIC ───────────────────────────────────────────
local lastEvasion   = 0
local evasionTarget = nil

local function doEvasion(root, dt)
    if not flag("Rage_Enabled", false) then return end
    local mode = flag("Rage_Evasion_Mode", "Off")
    if mode == "Off" then return end

    local interval = flag("Rage_Evasion_ReposInterval", 30) * 0.01
    local now = os.clock()
    if now - lastEvasion < interval then return end
    lastEvasion = now

    local pos = root.Position

    if mode == "Random" then
        local radius = flag("Rage_Evasion_Radius", 100)
        local rndFactor = flag("Rage_Evasion_RandFactor", 5)
        local r = radius + math.random(-rndFactor * 10, rndFactor * 10) / 10
        local angle = math.random() * math.pi * 2
        local origin = flag("Rage_Evasion_FallbackOrigin", false) and pos or pos
        local newPos = origin + Vector3.new(math.cos(angle)*r, 0, math.sin(angle)*r)
        pcall(function()
            if sethiddenproperty then
                sethiddenproperty(root, "CFrame", CFrame.new(newPos))
            end
        end)

    elseif mode == "Translocate" then
        local offset = flag("Rage_Evasion_Offset", -5)
        local cam = workspace.CurrentCamera
        local look = cam.CFrame.LookVector
        local newPos = pos + look * offset
        pcall(function()
            if sethiddenproperty then
                sethiddenproperty(root, "CFrame", CFrame.new(newPos))
            end
        end)

    elseif mode == "Projectile Breaker" then
        local fwdMax  = flag("Rage_PB_FwdMax", 40) * 0.1
        local fwdFreq = flag("Rage_PB_FwdFreq", 5)
        local upMax   = flag("Rage_PB_UpMax", 28) * 0.2
        local upFreq  = flag("Rage_PB_UpFreq", 5)

        local cam  = workspace.CurrentCamera
        local look = cam.CFrame.LookVector
        local fwdD = (math.random() < fwdFreq / 20) and math.random() * fwdMax or 0
        local upD  = (math.random() < upFreq / 20) and math.random() * upMax or 0
        local newPos = pos + look * fwdD + Vector3.new(0, upD, 0)
        pcall(function()
            if sethiddenproperty then
                sethiddenproperty(root, "CFrame", CFrame.new(newPos))
            end
        end)
    end
end

-- ── FLICKBOT ────────────────────────────────────────────────
local function doFlickbot(char, root, dt)
    if not flag("Rage_Flick_Enabled", false) then return end
    if not flag("Rage_Enabled", false) then return end

    local mode = flag("Rage_Flick_Mode", "Hold")
    local active = false
    if mode == "Hold" then
        active = UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
    else
        active = flickActive
    end
    if not active then return end

    local now = os.clock()
    local cooldown = flag("Rage_Flick_Cooldown", 250) / 1000
    if now - lastFlick < cooldown then return end

    local enemy = getBestTarget(root.Position, 360, 500)
    if not enemy then return end

    local aimPos = getTargetPos(enemy, "Rage_Primary_Part", "Rage_Primary_Pred")

    local cam       = workspace.CurrentCamera
    local humanness = flag("Rage_Flick_Humanness", 30)
    local noise     = humanness / 100 * 3
    local jitter    = Vector3.new(
        (math.random() - 0.5) * noise,
        (math.random() - 0.5) * noise,
        0
    )
    aimPos = aimPos + jitter

    local duration = flag("Rage_Flick_Duration", 110) / 1000
    local startCF  = cam.CFrame
    local targetCF = CFrame.new(cam.CFrame.Position, aimPos)

    task.spawn(function()
        local elapsed = 0
        while elapsed < duration do
            local dt2 = RunService.RenderStepped:Wait()
            elapsed = elapsed + dt2
            local alpha = math.clamp(elapsed / duration, 0, 1)
            -- ease in-out
            alpha = alpha < 0.5 and 2*alpha*alpha or 1 - (-2*alpha+2)^2/2
            cam.CFrame = startCF:Lerp(targetCF, alpha)
        end
        cam.CFrame = targetCF

        if flag("Rage_Flick_Shoot", false) then
            local shotDelay = flag("Rage_Flick_ShotDelay", 0) / 1000
            if shotDelay > 0 then task.wait(shotDelay) end
            local tool = char:FindFirstChildOfClass("Tool")
            if tool then
                local remote = tool:FindFirstChildOfClass("RemoteEvent")
                if remote then
                    pcall(function() remote:FireServer(aimPos) end)
                end
            end
        end
    end)

    lastFlick = now
end

-- ── VISUALS RUNTIME ─────────────────────────────────────────
local ESPObjects = {}

local function clearESP()
    for _, v in pairs(ESPObjects) do
        for _, d in pairs(v) do
            if d.Remove then d:Remove() end
        end
    end
    ESPObjects = {}
end

RunService.RenderStepped:Connect(function(dt)
    -- update ESP
    if not flag("ESP_Enabled", false) then
        clearESP()
        return
    end

    local cam = workspace.CurrentCamera
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Player then
            local char = p.Character
            if char then
                local root = char:FindFirstChild("HumanoidRootPart")
                local hum  = char:FindFirstChildOfClass("Humanoid")
                if root and hum and hum.Health > 0 then
                    local sp, onScreen = cam:WorldToScreenPoint(root.Position)
                    if not onScreen then
                        if ESPObjects[p] then
                            for _, d in pairs(ESPObjects[p]) do
                                if d.Visible ~= nil then d.Visible = false end
                            end
                        end
                    else
                        if not ESPObjects[p] then
                            local nameTag = Drawing.new("Text")
                            nameTag.Size  = 13
                            nameTag.Font  = 2
                            nameTag.Outline = true
                            nameTag.Color = flag("ESP_EnemyColor", Color3.fromRGB(255,80,80))
                            ESPObjects[p] = {nameTag = nameTag}
                        end
                        local obj = ESPObjects[p]
                        obj.nameTag.Position = Vector2.new(sp.X, sp.Y - 20)
                        obj.nameTag.Text = flag("ESP_Names", false) and p.DisplayName or ""
                        obj.nameTag.Visible = flag("ESP_Names", false)
                        obj.nameTag.Color = flag("ESP_EnemyColor", Color3.fromRGB(255,80,80))
                    end
                end
            end
        end
    end
end)

-- ── MOVEMENT MISC ───────────────────────────────────────────
RunService.Heartbeat:Connect(function(dt)
    local char, root, hum = getMyChar()
    if not char then return end

    -- speed hack
    if flag("Misc_Speed", false) then
        pcall(function() hum.WalkSpeed = flag("Misc_WalkSpeed", 16) end)
    end

    -- infinite jump
    if flag("Misc_InfJump", false) then
        pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
    end

    -- noclip
    if flag("Misc_Noclip", false) then
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then
                pcall(function() p.CanCollide = false end)
            end
        end
    end

    -- fullbright
    if flag("Vis_Fullbright", false) then
        pcall(function()
            local lighting = game:GetService("Lighting")
            lighting.Ambient = Color3.new(1,1,1)
            lighting.Brightness = 2
        end)
    end

    -- ragebot per-frame tick
    pcall(doKnife,  char, root, dt)
    pcall(doMelee,  char, root, dt)
    pcall(doGun,    char, root, dt)
    pcall(doEvasion, root, dt)
    pcall(doFlickbot, char, root, dt)
end)

-- ── FLIGHT ──────────────────────────────────────────────────
local flightBody = nil
RunService.Heartbeat:Connect(function()
    local char, root, hum = getMyChar()
    if not char or not root then
        if flightBody then flightBody:Destroy(); flightBody = nil end
        return
    end

    if flag("Misc_Flight", false) then
        if not flightBody then
            flightBody = Instance.new("BodyVelocity")
            flightBody.MaxForce = Vector3.new(1e5, 1e5, 1e5)
            flightBody.Parent   = root
        end
        local cam   = workspace.CurrentCamera
        local speed = flag("Misc_FlightSpeed", 100)
        local dir   = Vector3.new(0,0,0)
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0,1,0) end
        flightBody.Velocity = dir.Magnitude > 0 and dir.Unit * speed or Vector3.new(0,0,0)
        pcall(function() hum.PlatformStand = true end)
    else
        if flightBody then flightBody:Destroy(); flightBody = nil end
        pcall(function() if hum then hum.PlatformStand = false end end)
    end
end)

-- ── ANTI-AIM ────────────────────────────────────────────────
local spinAngle = 0
RunService.Heartbeat:Connect(function(dt)
    if not flag("AA_Enabled", false) then return end
    local char, root, hum = getMyChar()
    if not char or not root then return end

    local yaw = flag("AA_Yaw", "Spin")
    local pitch = flag("AA_Pitch", "Down")

    local yawAngle = 0
    if yaw == "Spin" then
        spinAngle = spinAngle + flag("AA_SpinSpeed", 360) * dt
        yawAngle  = spinAngle
    elseif yaw == "Jitter" then
        yawAngle = (math.floor(os.clock() * 20) % 2 == 0) and 180 or 0
    elseif yaw == "Static" then
        yawAngle = 180
    end

    local pitchAngle = 0
    if pitch == "Down" then pitchAngle = 89
    elseif pitch == "Up" then pitchAngle = -89
    elseif pitch == "Random" then pitchAngle = math.random(-89, 89)
    end

    pcall(function()
        if sethiddenproperty then
            local cf = root.CFrame
            sethiddenproperty(root, "CFrame",
                CFrame.new(cf.Position)
                * CFrame.fromOrientation(math.rad(pitchAngle), math.rad(yawAngle), 0))
        end
    end)
end)

-- ============================================================
--  STARTUP
-- ============================================================
Library:Notify("eclipse loaded", "success")
Library:Notify("ragebot ready — press " .. Library.MenuKey.Name .. " to toggle", nil)
