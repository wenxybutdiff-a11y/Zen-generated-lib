--[[
    [MODULE] Visuals.lua
    [ARCHITECT] Lead UI Architect
    [DESCRIPTION] 
        Handles the 3D rendering aspects of the cheat (ESP, Tracers, Chams).
        Ensures that the 'Clean' aesthetic extends from the 2D UI into the 3D world.
        Uses BillboardGuis for reliability across executors (Fluxus/Delta Mobile support).

    [FEATURES]
        - Adaptive Box ESP (Corners or Full)
        - Clean Text Rendering
        - Health Bar Gradients
        - Team Coloring
]]

local Visuals = {}

--// SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")

--// DEPENDENCIES
local Config = require(script.Parent.Config)
local Utility = require(script.Parent.Utility)

--// STATE
Visuals.Enabled = false
Visuals.Container = nil
Visuals.Cache = {} -- Stores ESP Objects per player

--// CONSTANTS
local ESP_FONT = Config.Styling.Fonts.Code
local ESP_TEXT_SIZE = 12

--[[
    [Class] ESP Object
    Represents the visual elements for a single player.
]]
local ESPObject = {}
ESPObject.__index = ESPObject

function ESPObject.new(player, container)
    local self = setmetatable({}, ESPObject)
    self.Player = player
    
    -- Main Billboard
    self.Billboard = Instance.new("BillboardGui")
    self.Billboard.Name = player.Name .. "_ESP"
    self.Billboard.AlwaysOnTop = true
    self.Billboard.Size = UDim2.new(4, 0, 5.5, 0)
    self.Billboard.StudsOffset = Vector3.new(0, 0, 0)
    self.Billboard.ResetOnSpawn = false
    self.Billboard.Parent = container
    
    -- Box Frame
    self.Box = Instance.new("Frame")
    self.Box.Size = UDim2.new(1, 0, 1, 0)
    self.Box.BackgroundTransparency = 1
    self.Box.Parent = self.Billboard
    
    -- Box Stroke (The visual line)
    self.Stroke = Instance.new("UIStroke")
    self.Stroke.Parent = self.Box
    self.Stroke.Thickness = 1.5
    self.Stroke.Color = Config.Current.Accent
    self.Stroke.Transparency = 0
    
    -- Name Label
    self.NameLabel = Instance.new("TextLabel")
    self.NameLabel.Parent = self.Billboard
    self.NameLabel.BackgroundTransparency = 1
    self.NameLabel.Size = UDim2.new(1, 0, 0, 14)
    self.NameLabel.Position = UDim2.new(0, 0, 0, -16)
    self.NameLabel.Font = ESP_FONT
    self.NameLabel.TextSize = ESP_TEXT_SIZE
    self.NameLabel.TextColor3 = Config.Current.TextColor
    self.NameLabel.TextStrokeTransparency = 0.5
    self.NameLabel.TextStrokeColor3 = Color3.new(0,0,0)
    self.NameLabel.Text = player.Name
    
    -- Health Bar (Left Side)
    self.HealthBarBg = Instance.new("Frame")
    self.HealthBarBg.Size = UDim2.new(0, 3, 1, 0)
    self.HealthBarBg.Position = UDim2.new(0, -5, 0, 0)
    self.HealthBarBg.BackgroundColor3 = Color3.new(0,0,0)
    self.HealthBarBg.BorderSizePixel = 0
    self.HealthBarBg.Parent = self.Billboard
    
    self.HealthBarFill = Instance.new("Frame")
    self.HealthBarFill.Size = UDim2.new(1, 0, 1, 0) -- Scaled via code
    self.HealthBarFill.Position = UDim2.new(0, 0, 1, 0) -- Anchor bottom
    self.HealthBarFill.AnchorPoint = Vector2.new(0, 1)
    self.HealthBarFill.BackgroundColor3 = Config.Current.Success
    self.HealthBarFill.BorderSizePixel = 0
    self.HealthBarFill.Parent = self.HealthBarBg

    self.Visible = false
    return self
end

function ESPObject:Update(settings)
    if not self.Player or not self.Player.Parent then
        self:Destroy()
        return false
    end
    
    local char = self.Player.Character
    if not char then 
        self.Billboard.Enabled = false
        return true 
    end
    
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")
    
    if not root or not hum or hum.Health <= 0 then
        self.Billboard.Enabled = false
        return true
    end
    
    -- Distance Check
    local cam = Workspace.CurrentCamera
    local dist = (cam.CFrame.Position - root.Position).Magnitude
    if dist > settings.MaxDistance then
        self.Billboard.Enabled = false
        return true
    end
    
    -- Visibility Logic
    self.Billboard.Enabled = true
    self.Billboard.Adornee = root
    
    -- 1. Box Style
    if settings.Boxes then
        self.Box.Visible = true
        self.Stroke.Color = settings.TeamColor and self.Player.TeamColor.Color or settings.BoxColor
    else
        self.Box.Visible = false
    end
    
    -- 2. Name
    if settings.Names then
        self.NameLabel.Visible = true
        self.NameLabel.Text = string.format("%s [%dm]", self.Player.Name, math.floor(dist))
    else
        self.NameLabel.Visible = false
    end
    
    -- 3. Health
    if settings.Health then
        self.HealthBarBg.Visible = true
        local healthPct = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
        self.HealthBarFill.Size = UDim2.new(1, 0, healthPct, 0)
        self.HealthBarFill.BackgroundColor3 = Color3.fromRGB(255, 50, 50):Lerp(Color3.fromRGB(50, 255, 50), healthPct)
    else
        self.HealthBarBg.Visible = false
    end
    
    return true
end

function ESPObject:Destroy()
    self.Billboard:Destroy()
end

--// VISUALS MANAGER API

function Visuals.Init()
    if Visuals.Container then Visuals.Container:Destroy() end
    Visuals.Container = Instance.new("Folder")
    Visuals.Container.Name = "Solaris_ESP_Container"
    Visuals.Container.Parent = CoreGui
    
    -- Hook Player Added
    Players.PlayerAdded:Connect(function(v)
        if v ~= Players.LocalPlayer then
            Visuals.Cache[v] = ESPObject.new(v, Visuals.Container)
        end
    end)
    
    -- Load Existing
    for _, v in ipairs(Players:GetPlayers()) do
        if v ~= Players.LocalPlayer then
            Visuals.Cache[v] = ESPObject.new(v, Visuals.Container)
        end
    end
    
    -- Start Loop
    RunService.RenderStepped:Connect(Visuals.Render)
end

function Visuals.Render()
    if not Visuals.Enabled then 
        -- Hide all if master switch is off
        for _, esp in pairs(Visuals.Cache) do
            esp.Billboard.Enabled = false
        end
        return 
    end
    
    -- Access global settings (assumed passed or accessible via Config/State)
    -- Ideally, we read from `Solaris.Settings.ESP` passed in via `Visuals.Configure`
    -- For now, we use defaults or mock access.
    local Settings = {
        MaxDistance = 2000,
        Boxes = true,
        Names = true,
        Health = true,
        BoxColor = Config.Current.Accent,
        TeamColor = false
    }
    
    for player, esp in pairs(Visuals.Cache) do
        esp:Update(Settings)
    end
end

function Visuals.SetEnabled(bool)
    Visuals.Enabled = bool
end

return Visuals