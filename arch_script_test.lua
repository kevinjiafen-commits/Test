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
    Name = "Arch script test",
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
    Text = "Arch script test | fallen",
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
        '', 'A', 'Ar', 'Arc', 'Arch', 'Arch ', 'Arch s', 'Arch sc', 'Arch scr',
        'Arch scri', 'Arch scrip', 'Arch script', 'Arch script ',
        'Arch script t', 'Arch script te', 'Arch script tes', 'Arch script test',
        'Arch script test |', 'Arch script test | f', 'Arch script test | fa',
        'Arch script test | fal', 'Arch script test | fall', 'Arch script test | falle',
        'Arch script test | fallen',
        'Arch script test | falle', 'Arch script test | fall', 'Arch script test | fal',
        'Arch script test | fa', 'Arch script test | f', 'Arch script test |',
        'Arch script test', 'Arch script tes', 'Arch script te', 'Arch script t',
        'Arch script ', 'Arch script', 'Arch scrip', 'Arch scri', 'Arch scr',
        'Arch sc', 'Arch s', 'Arch ', 'Arch', 'Arc', 'Ar', 'A'
    }
    while not Library.Unloaded do
        for _, text in ipairs(textList) do
            if Library.Unloaded then break end
            local display = text
            if string.find(text, "fallen") then
                display = string.gsub(text, "fallen", '<font color="#bdacff">fallen</font>')
            elseif string.find(text, "test") then
                display = string.gsub(text, "test", '<font color="#bdacff">test</font>')
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
            local Enabled = false
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
                BackgroundTransparency = 1
            })

            local Label = Create("TextLabel", {
                Parent = Frame,
                Text = cfg.Name,
                TextColor3 = CFG.TextDark,
                TextSize = 11,
                Font = CFG.Font,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 18, 0, 0),
                Size = UDim2.new(1, -18, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left
            })

            if cfg.Risky then Label.TextColor3 = Color3.fromRGB(200, 80, 80) end
            if cfg.Tooltip then AddTooltip(Frame, cfg.Tooltip) end

            local function Update()
                Enabled = not Enabled
                Tween(Check, {BackgroundTransparency = Enabled and 0 or 1}, 0.1)
                Tween(Label, {TextColor3 = Enabled and CFG.TextColor or (cfg.Risky and Color3.fromRGB(200, 80, 80) or CFG.TextDark)}, 0.1)
                if cfg.Callback then cfg.Callback(Enabled) end
            end

            Frame.MouseButton1Click:Connect(Update)
            return {Set = function(v) if v ~= Enabled then Update() end end}
        end

        function ItemFuncs:Slider(cfg)
            local Value = cfg.Default or cfg.Min
            local DraggingSlider = false

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
                if cfg.Callback then cfg.Callback(Value) end
            end

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

            local percent = (Value - cfg.Min) / (cfg.Max - cfg.Min)
            Fill.Size = UDim2.new(percent, 0, 1, 0)
            if cfg.Tooltip then AddTooltip(Frame, cfg.Tooltip) end
        end

        function ItemFuncs:Dropdown(cfg)
            local Expanded = false
            local Current = cfg.Default or cfg.Options[1]

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
                if cfg.Callback then cfg.Callback(Box.Text) end
            end)
            if cfg.Tooltip then AddTooltip(Frame, cfg.Tooltip) end
        end

        function ItemFuncs:Keybind(cfg)
            local Key = cfg.Default or Enum.KeyCode.Insert
            local Waiting = false

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
    function GroupFunctions:GetPageFrame() return PageFrame end
    return GroupFunctions
end


-- ─── Skins Tab ────────────────────────────────────────────────────────────────
local SkinsTab = Library:Tab("Skins", 4483362458)
-- cosmetic changer is built inline into this tab page — no separate floating window
local _SkinsPageFrame = SkinsTab:GetPageFrame()

-- ─── Key binding & mobile toggle ──────────────────────────────────────────────
Library.MenuKey = Enum.KeyCode.RightShift
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

Library:Notify("Arch script test loaded", "success")

-- ─── Skinchanger Backend ──────────────────────────────────────────────────────
task.spawn(function()

            -- Unlock All module removed
local plrs = game:GetService("Players")
local reps = game:GetService("ReplicatedStorage")
local http = game:GetService("HttpService")
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

local KNIFE_CUSTOM_SKIN = "Knife (Custom Skin)"
local REAVER_KNIFE_CUSTOM_SKIN = "reaver"
local DAGGERS_CUSTOM_SKIN = "Jett"
local SATCHEL_CUSTOM_SKIN = "Raze"
local SNIPER_CUSTOM_SKIN = "Chamber"
local RPG_CUSTOM_SKIN = "RPG Raze"
local FISTS_CUSTOM_SKIN = "Agent"
local BOW_CUSTOM_SKIN = "Sova"
local ASSAULT_RIFLE_CUSTOM_SKIN = "Vandal"
local DICE_TRIPMINE_SKIN = "Subspace Tripmine (Custom Skin)"
local DICE_TRIPMINE_OUTER_MESH_ID = "rbxassetid://5555691474"
local DICE_TRIPMINE_INNER_MESH_ID = "rbxassetid://5555691356"
local DICE_TRIPMINE_IMAGE_ID = "rbxassetid://98372867049331"
local DICE_TRIPMINE_IMAGE_HIGH_RES_ID = "rbxassetid://75601061529918"
local DICE_TRIPMINE_MESH_SCALE = 3.35
local DICE_TRIPMINE_WORLD_MESH_SCALE = 3.25
local SPIKE_TRIPMINE_SKIN = "Spike"
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

local RPG_MESH_SKIN_OVERRIDES = {
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

local FISTS_MESH_SKIN_OVERRIDES = {
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

local TRIPMINE_MESH_SKIN_OVERRIDES = {
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

local function meshMatchesAnyAssetId(inst, assetIds)
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

local function namePathContains(inst, needle)
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

local function applySatchelReplacementToObject(obj, profile)
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

local function applyRpgMeshProfile(root, profile, options)
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

local function applyFistsMeshProfile(root, profile)
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

function __LionHideSniperMeshAnchor(part, anchorType)
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

function __LionOffsetSniperVisibleAnchor(part, anchorType, offset)
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

function __LionCreateSniperReplacementMeshPart(root, anchor, replacementName, meshId, textureId, cframe, profile)
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

function __LionApplySniperMultiMeshProfile(root, profile)
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

local function applyTripmineMeshProfile(root, profile, worldVisual)
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

local cdata = dctrl.CurrentData
if not cdata then
	task.spawn(function()
		repeat task.wait() until dctrl.CurrentData
		cdata = dctrl.CurrentData
	end)
end

local equip, favs = {}, {}
local cwep, vprof, lwep
local lpname = lp.Name
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
	if eid then d.Enum = eid d.ObjectID = d.ObjectID or eid end
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

local function resolveViewModelSourceName(weapon, cosmetics)
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
								lwep = item.Name
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

local function installRpgProjectileSkinHook()
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
			vprof = tplr
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

-- ─── Skin Config — auto-save / auto-load ──────────────────────────────────────
local SKIN_CONFIG_FILE = "eclipse_skinconfig.json"

local function saveConfig()
	local export = {}
	for w, cats in pairs(equip) do
		export[w] = {}
		for cat, data in pairs(cats) do
			export[w][cat] = data and data.Name or nil
		end
	end
	pcall(writefile, SKIN_CONFIG_FILE, http:JSONEncode(export))
end

local function loadConfig()
	local ok, raw = pcall(readfile, SKIN_CONFIG_FILE)
	if not ok or type(raw) ~= "string" or raw == "" then return end
	local ok2, data = pcall(function() return http:JSONDecode(raw) end)
	if not ok2 or type(data) ~= "table" then return end
	for w, cats in pairs(data) do
		if type(cats) == "table" then
			for cat, name in pairs(cats) do
				if type(name) == "string" and name ~= "" then
					applyCosmeticToWeapon(w, name, cat, true)
					task.defer(function() pcall(forceCosmeticUpdate, w, cat) end)
				end
			end
		end
	end
	rebuildinv()
	saferep("CosmeticInventory")
	saferep("WeaponInventory")
end

-- load saved skins immediately so they're live before the UI renders
task.defer(loadConfig)
-- ──────────────────────────────────────────────────────────────────────────────

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
	TileH = 124
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

		local rebuilt = false
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
				rebuilt = true
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

	-- inline: embed directly into the Skins tab PageFrame — no floating window
	cosmeticGuiState.Columns = 3  -- 3 × 130 = 390px, fits the tab's ~510px width

	-- container frame that fills the tab page
	local gui = Instance.new("Frame")
	gui.Name = "LionCosmeticChangerInline"
	gui.BackgroundTransparency = 1
	gui.BorderSizePixel = 0
	gui.Size = UDim2.new(1, 0, 0, 810)
	gui.ZIndex = 1
	gui.Parent = _SkinsPageFrame
	cosmeticGuiState.Gui = gui

	local body = Instance.new("Frame")
	body.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
	body.BorderSizePixel = 0
	body.Position = UDim2.fromOffset(0, 0)
	body.Size = UDim2.new(1, 0, 1, 0)
	body.ZIndex = 1
	body.Parent = gui
	do
		Instance.new("UIStroke", body).Color = Color3.fromRGB(40, 40, 40)
		Instance.new("UICorner", body).CornerRadius = UDim.new(0, 3)
	end

	local function mkText(parent, text, pos, size, fontSize)
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.Code
		label.Text = text
		label.TextColor3 = Color3.fromRGB(200, 200, 200)
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
		box.BackgroundColor3 = Color3.fromRGB(26, 26, 26)
		box.BorderSizePixel = 0
		box.ClearTextOnFocus = false
		box.Font = Enum.Font.Code
		box.PlaceholderText = placeholder
		box.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
		box.Text = ""
		box.TextColor3 = Color3.fromRGB(200, 200, 200)
		box.TextSize = 12
		box.TextXAlignment = Enum.TextXAlignment.Left
		box.Position = pos
		box.Size = size
		box.ZIndex = 902
		box.Parent = parent
		Instance.new("UIStroke", box).Color = Color3.fromRGB(40, 40, 40)
		Instance.new("UICorner", box).CornerRadius = UDim.new(0, 3)
		Instance.new("UIPadding", box).PaddingLeft = UDim.new(0, 5)
		return box
	end

	local function mkButton(parent, text, pos, size)
		local btn = Instance.new("TextButton")
		btn.AutoButtonColor = false
		btn.BackgroundColor3 = Color3.fromRGB(26, 26, 26)
		btn.BorderSizePixel = 0
		btn.Font = Enum.Font.Code
		btn.Text = text
		btn.TextColor3 = Color3.fromRGB(120, 120, 120)
		btn.TextSize = 12
		btn.Position = pos
		btn.Size = size
		btn.ZIndex = 902
		btn.Parent = parent
		Instance.new("UIStroke", btn).Color = Color3.fromRGB(40, 40, 40)
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 3)
		return btn
	end

	local weaponGrid = Instance.new("ScrollingFrame")
	weaponGrid.BackgroundColor3 = Color3.fromRGB(11, 11, 11)
	weaponGrid.BorderSizePixel = 0
	weaponGrid.CanvasSize = UDim2.new()
	weaponGrid.ScrollBarThickness = 4
	weaponGrid.ScrollBarImageColor3 = Color3.fromRGB(189, 172, 255)
	weaponGrid.Position = UDim2.fromOffset(10, 54)
	weaponGrid.Size = UDim2.new(1, -20, 0, 264)
	weaponGrid.ZIndex = 902
	weaponGrid.Parent = body
	Instance.new("UIStroke", weaponGrid).Color = Color3.fromRGB(40, 40, 40)
	Instance.new("UICorner", weaponGrid).CornerRadius = UDim.new(0, 3)

	local cosmeticGrid = Instance.new("ScrollingFrame")
	cosmeticGrid.BackgroundColor3 = Color3.fromRGB(11, 11, 11)
	cosmeticGrid.BorderSizePixel = 0
	cosmeticGrid.CanvasSize = UDim2.new()
	cosmeticGrid.ScrollBarThickness = 4
	cosmeticGrid.ScrollBarImageColor3 = Color3.fromRGB(189, 172, 255)
	cosmeticGrid.Position = UDim2.fromOffset(10, 374)
	cosmeticGrid.Size = UDim2.new(1, -20, 0, 276)
	cosmeticGrid.ZIndex = 902
	cosmeticGrid.Parent = body
	Instance.new("UIStroke", cosmeticGrid).Color = Color3.fromRGB(40, 40, 40)
	Instance.new("UICorner", cosmeticGrid).CornerRadius = UDim.new(0, 3)

	mkText(body, "weapon filter", UDim2.fromOffset(10, 6), UDim2.new(1, -20, 0, 18))
	local weaponSearch = mkBox(body, "grenade launcher...", UDim2.fromOffset(10, 28), UDim2.new(1, -20, 0, 24))
	mkText(body, "cosmetic filter", UDim2.fromOffset(10, 326), UDim2.new(1, -20, 0, 18))
	local cosmeticSearch = mkBox(body, "red...", UDim2.fromOffset(10, 348), UDim2.new(1, -20, 0, 24))

	local modeButton = mkButton(body, "skin                                                                                  >", UDim2.fromOffset(10, 658), UDim2.new(1, -20, 0, 26))
	local modeMenu = Instance.new("Frame")
	modeMenu.BackgroundColor3 = Color3.fromRGB(26, 26, 26)
	modeMenu.BorderSizePixel = 0
	modeMenu.Position = UDim2.fromOffset(10, 684)
	modeMenu.Size = UDim2.new(1, -20, 0, 104)
	modeMenu.Visible = false
	modeMenu.ZIndex = 910
	modeMenu.Parent = body
	Instance.new("UIStroke", modeMenu).Color = Color3.fromRGB(40, 40, 40)
	Instance.new("UICorner", modeMenu).CornerRadius = UDim.new(0, 3)

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
	applyAll.TextColor3 = Color3.fromRGB(189, 172, 255)
	do local s=Instance.new("UIStroke",applyAll); s.Color=Color3.fromRGB(189,172,255); s.Transparency=0.3 end
	local reset = mkButton(body, "reset to defaults", UDim2.fromOffset(10, 720), UDim2.new(0.5, -12, 0, 26))
	local close = mkButton(body, "close", UDim2.new(0.5, 2, 0, 720), UDim2.new(0.5, -12, 0, 26))
	mkText(body, "right click a weapon to toggle the skin changer for it.", UDim2.fromOffset(10, 750), UDim2.new(1, -20, 0, 18), 12).TextColor3 = Color3.fromRGB(125, 125, 125)

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
		viewport.Ambient = Color3.fromRGB(180, 180, 180)
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
		badge.BorderSizePixel = 0
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
		tile.BackgroundColor3 = selected and Color3.fromRGB(40, 30, 80) or Color3.fromRGB(26, 26, 26)
		tile.BorderSizePixel = 1
		tile.BorderColor3 = selected and Color3.fromRGB(189, 172, 255) or Color3.fromRGB(40, 40, 40)
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
		name.TextColor3 = Color3.fromRGB(200, 200, 200)
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
					saveConfig()
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
			saveConfig()
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
					saveConfig()
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
		saveConfig()
		rebuildCosmeticLists()
		refresh()
	end)
	reset.MouseButton1Click:Connect(function()
		table.clear(equip)
		table.clear(fcache)
		rebuildinv()
		saferep("WeaponInventory")
		saveConfig()
		rebuildCosmeticLists()
		refresh()
	end)
	-- close repurposed: no separate window to close; wire to a no-op so button is inert
	close.MouseButton1Click:Connect(function()
		-- inline mode: cosmetic changer is always visible in the Skins tab
	end)

	refresh()
	return gui
end

shared.LionCosmeticChanger = {
	SetVisible = function(_visible)
		-- inline mode: changer lives in the Skins tab, always present
		makeCosmeticChanger()
		rebuildCosmeticLists()
		if cosmeticGuiState.Refresh then cosmeticGuiState.Refresh() end
	end,
	Toggle = function()
		-- inline mode: nothing to toggle; just refresh
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

-- auto-build inline UI into the Skins tab immediately
makeCosmeticChanger()

end) -- end task.spawn skinchanger backend
