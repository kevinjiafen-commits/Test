local AIMBOT_SETTINGS = {
    Enabled = true,
    Smoothing = 0.2,
}

local FOV_SETTINGS = {
    Visible = true,
    Radius = 150,
    Color = Color3.fromRGB(0, 255, 0),
    Thickness = 1,
    NumSides = 64,
    Filled = false,
    Transparency = 1
}

local ESP_SETTINGS = {
    Enabled = true,
    Boxes = true,
    Names = true,
    BoxColor = Color3.fromRGB(255, 255, 255),
    TextColor = Color3.fromRGB(255, 255, 255)
}

local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = FOV_SETTINGS.Visible
FOVCircle.Radius = FOV_SETTINGS.Radius
FOVCircle.Color = FOV_SETTINGS.Color
FOVCircle.Thickness = FOV_SETTINGS.Thickness
FOVCircle.NumSides = FOV_SETTINGS.NumSides
FOVCircle.Filled = FOV_SETTINGS.Filled
FOVCircle.Transparency = FOV_SETTINGS.Transparency

local ESPCache = {}

local function ClearESP(character)
    if ESPCache[character] then
        if ESPCache[character].Box then ESPCache[character].Box:Remove() end
        if ESPCache[character].Text then ESPCache[character].Text:Remove() end
        ESPCache[character] = nil
    end
end

local Targeting = { target = nil }

function Targeting:GetClosestPlayer()
    local PlayersService = cloneref(game:GetService('Players'))
    local WorkspaceService = cloneref(game:GetService('Workspace'))
    local ReplicatedFirstService = cloneref(game:GetService('ReplicatedFirst'))
    local ReplicatedStorageService = cloneref(game:GetService('ReplicatedStorage'))
    
    local LocalPlayer = PlayersService.LocalPlayer
    local Camera = WorkspaceService.CurrentCamera
    
    local NeuronModule = require(game.FindFirstChild(ReplicatedFirstService, 'neuron', true))
    local StatesModule = require(game.FindFirstChild(ReplicatedStorageService, 'States', true))
    local EntitiesFolder = game.GetChildren(game.FindFirstChild(WorkspaceService, 'Entities', true))
    
    local ClosestDistance = FOV_SETTINGS.Radius 
    Targeting.target = nil
    
    local PotentialTargets = {}
    local RenderedThisFrame = {}
    
    for _, Player in PlayersService:GetPlayers() do
        if Player == LocalPlayer then continue end
        local Character = NeuronModule:get_character(Player)
        if Character then 
            table.insert(PotentialTargets, { char = Character, name = Player.Name }) 
        end
    end
    
    for _, Entity in EntitiesFolder do
        table.insert(PotentialTargets, { char = Entity, name = Entity.Name })
    end
    
    local ScreenCenter = Vector2.new((Camera.ViewportSize.X / 2), (Camera.ViewportSize.Y / 2))
    
    if FOV_SETTINGS.Visible then
        FOVCircle.Position = ScreenCenter
    end
    
    for _, TargetObj in PotentialTargets do
        local Character = TargetObj.char
        local TargetName = TargetObj.name
        
        local IsDead = StatesModule:GetStateValue(Character, 'Dead', false)
        if IsDead then 
            ClearESP(Character)
            continue 
        end
        
        local Head = game.FindFirstChild(Character, 'HitboxHead')
        local Root = game.FindFirstChild(Character, 'HumanoidRootPart') or game.FindFirstChild(Character, 'LowerTorso')
        
        if not Head then 
            ClearESP(Character)
            continue 
        end
        
        local ScreenPosition, OnScreen = Camera:WorldToViewportPoint(Head.Position)
        
        if OnScreen then
            local DistanceFromCenter = (Vector2.new(ScreenPosition.X, ScreenPosition.Y) - ScreenCenter).Magnitude
            if DistanceFromCenter < ClosestDistance then
                ClosestDistance = DistanceFromCenter
                Targeting.target = Head.Position
            end
        end
        
        if ESP_SETTINGS.Enabled and OnScreen and Root then
            RenderedThisFrame[Character] = true
            
            local RootPos, RootOnScreen = Camera:WorldToViewportPoint(Root.Position)
            local HeadPos = Camera:WorldToViewportPoint(Head.Position + Vector3.new(0, 0.5, 0))
            local LegPos = Camera:WorldToViewportPoint(Root.Position - Vector3.new(0, 3, 0))
            
            local BoxHeight = math.abs(HeadPos.Y - LegPos.Y)
            local BoxWidth = BoxHeight * 0.6
            
            if not ESPCache[Character] then
                ESPCache[Character] = {
                    Box = Drawing.new("Square"),
                    Text = Drawing.new("Text")
                }
            end
            
            local Visuals = ESPCache[Character]
            
            if ESP_SETTINGS.Boxes then
                Visuals.Box.Visible = true
                Visuals.Box.Size = Vector2.new(BoxWidth, BoxHeight)
                Visuals.Box.Position = Vector2.new(RootPos.X - (BoxWidth / 2), HeadPos.Y)
                Visuals.Box.Color = ESP_SETTINGS.BoxColor
                Visuals.Box.Thickness = 1
                Visuals.Box.Filled = false
            else
                Visuals.Box.Visible = false
            end
            
            if ESP_SETTINGS.Names then
                Visuals.Text.Visible = true
                Visuals.Text.Text = TargetName
                Visuals.Text.Size = 16
                Visuals.Text.Center = true
                Visuals.Text.Outline = true
                Visuals.Text.Position = Vector2.new(RootPos.X, HeadPos.Y - 20)
                Visuals.Text.Color = ESP_SETTINGS.TextColor
            else
                Visuals.Text.Visible = false
            end
        else
            ClearESP(Character)
        end
    end
    
    for CachedChar, _ in pairs(ESPCache) do
        if not RenderedThisFrame[CachedChar] then
            ClearESP(CachedChar)
        end
    end
end

local RunService = cloneref(game:GetService('RunService'))
local Camera = cloneref(game:GetService('Workspace')).CurrentCamera
local ReplicatedStorageService = cloneref(game:GetService('ReplicatedStorage'))
local CameraHandlerModule = require(game.FindFirstChild(ReplicatedStorageService, 'CameraHandler', true))

RunService.PreRender:Connect(function()
    Targeting:GetClosestPlayer()
    
    if AIMBOT_SETTINGS.Enabled and CameraHandlerModule.firstPerson and Targeting.target then
        local Direction = (Targeting.target - Camera.CFrame.p).Unit
        
        local TargetPitch = math.asin(Direction.Y)
        local TargetYaw = math.atan2(-Direction.X, -Direction.Z)
        local TargetVector = vector.create(TargetPitch, TargetYaw, 0)
        
        CameraHandlerModule.currentRotation = CameraHandlerModule.currentRotation:lerp(
            TargetVector, 
            1 - AIMBOT_SETTINGS.Smoothing
        )
    end
end)
