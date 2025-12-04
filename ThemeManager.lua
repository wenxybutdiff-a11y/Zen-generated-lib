--[[
    [MODULE] ThemeManager.lua
    [ARCHITECT] Lead UI Architect
    [DESCRIPTION] 
        The aesthetic engine of Solaris.
        This module injects itself into the Rayfield UI at runtime to apply
        properties that Rayfield does not support natively (Gradients, Custom Shadows, Glass Material).
        
    [MECHANICS]
        1. recursive scanning of the UI hierarchy.
        2. Pattern matching element names (Button, Section, Tab).
        3. Injecting UIStroke, UICorner, and UIGradient instances.
        4. Binding custom TweenService animations to MouseEnter/Leave.
]]

local ThemeManager = {}

--// SERVICES
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")

--// DEPENDENCIES
local Config = require(script.Parent.Config)
local Utility = require(script.Parent.Utility)

--// STATE
ThemeManager.Active = false
ThemeManager.TargetInterface = nil
ThemeManager.Connections = {}

--// HELPER: CREATE OR GET INSTANCE
local function GetOrAdd(parent, className, props)
    local inst = parent:FindFirstChildOfClass(className)
    if not inst then
        inst = Instance.new(className)
        inst.Parent = parent
    end
    if props then
        for k, v in pairs(props) do
            inst[k] = v
        end
    end
    return inst
end

--// HELPER: APPLY GLASS EFFECT
local function ApplyGlass(frame)
    if not frame:IsA("Frame") then return end
    
    -- 1. Adjust Background
    frame.BackgroundColor3 = Config.Current.WindowBackground
    frame.BackgroundTransparency = Config.Current.WindowTransparency
    
    -- 2. Add Gradient
    local grad = GetOrAdd(frame, "UIGradient", {
        Rotation = 45,
        Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.new(1,1,1)),
            ColorSequenceKeypoint.new(1, Color3.new(0.8, 0.8, 0.9)) -- Slight dimming
        }
    })
    
    -- 3. Add Stroke (Border)
    GetOrAdd(frame, "UIStroke", {
        Thickness = 1,
        Color = Config.Current.ElementStroke,
        Transparency = 0.5
    })
end

--// HELPER: ANIMATE ELEMENT
local function AttachHoverAnimation(instance, normalColor, hoverColor, strokeInstance)
    local connEnter = instance.MouseEnter:Connect(function()
        TweenService:Create(instance, Config.Animations.Default, {BackgroundColor3 = hoverColor}):Play()
        if strokeInstance then
            TweenService:Create(strokeInstance, Config.Animations.Default, {Color = Config.Current.Accent}):Play()
        end
    end)
    
    local connLeave = instance.MouseLeave:Connect(function()
        TweenService:Create(instance, Config.Animations.Default, {BackgroundColor3 = normalColor}):Play()
        if strokeInstance then
            TweenService:Create(strokeInstance, Config.Animations.Default, {Color = Config.Current.ElementStroke}):Play()
        end
    end)
    
    table.insert(ThemeManager.Connections, connEnter)
    table.insert(ThemeManager.Connections, connLeave)
end

--// CORE: REFINE SPECIFIC ELEMENT TYPES
local Refiners = {}

Refiners.Button = function(instance)
    if not instance:IsA("TextButton") then return end
    
    -- Style
    instance.BackgroundColor3 = Config.Current.ElementBackground
    instance.Font = Config.Styling.Fonts.Body
    instance.TextColor3 = Config.Current.TextColor
    
    -- Geometry
    GetOrAdd(instance, "UICorner", { CornerRadius = Config.Styling.CornerRadius })
    local stroke = GetOrAdd(instance, "UIStroke", {
        Color = Config.Current.ElementStroke,
        Thickness = Config.Styling.StrokeThickness,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    })
    
    -- Interaction
    AttachHoverAnimation(instance, Config.Current.ElementBackground, Config.Current.Hover, stroke)
end

Refiners.Toggle = function(instance)
    -- Rayfield Toggles usually have a 'Check' frame or image
    -- We assume 'instance' is the container button
    GetOrAdd(instance, "UICorner", { CornerRadius = Config.Styling.CornerRadius })
    
    local title = instance:FindFirstChild("Title")
    if title and title:IsA("TextLabel") then
        title.Font = Config.Styling.Fonts.Body
        title.TextColor3 = Config.Current.TextColor
    end
    
    -- Look for the checkmark box
    local box = instance:FindFirstChild("Box") or instance:FindFirstChild("CheckFrame") -- Hypothetical name based on Rayfield structure
    if box then
        GetOrAdd(box, "UICorner", { CornerRadius = Config.Styling.CornerRadiusSmall })
        GetOrAdd(box, "UIStroke", { Color = Config.Current.Accent, Thickness = 1 })
    end
end

Refiners.Slider = function(instance)
    -- Slider logic
    GetOrAdd(instance, "UICorner", { CornerRadius = Config.Styling.CornerRadius })
    local stroke = GetOrAdd(instance, "UIStroke", {
        Color = Config.Current.ElementStroke,
        Thickness = 1
    })
    
    -- Find the fill bar
    for _, child in ipairs(instance:GetDescendants()) do
        if child.Name == "SliderPoint" or child.Name == "Fill" then
            child.BackgroundColor3 = Config.Current.Accent
            GetOrAdd(child, "UICorner", { CornerRadius = Config.Styling.CornerRadiusSmall })
        end
    end
end

Refiners.Section = function(instance)
    -- Sections are usually TextLabels acting as headers
    if instance:IsA("TextLabel") and instance.Name == "SectionTitle" then
        instance.TextColor3 = Config.Current.Accent
        instance.Font = Config.Styling.Fonts.Title
        instance.TextUppercase = true
    end
end

--// MAIN: PROCESS DESCENDANT
local function ProcessElement(instance)
    -- 1. Identify Type based on naming conventions or hierarchy
    -- Rayfield specific naming checks:
    
    if instance:IsA("TextButton") and instance.Name == "Button" then
        Refiners.Button(instance)
    elseif instance.Name == "Toggle" then
        Refiners.Toggle(instance)
    elseif instance.Name == "Slider" then
        Refiners.Slider(instance)
    elseif instance.Name == "Section" then
        Refiners.Section(instance)
    elseif instance:IsA("Frame") and instance.Name == "Main" then
        -- This is the main window
        ApplyGlass(instance)
        
        -- Add Drop Shadow
        local shadow = GetOrAdd(instance, "ImageLabel", {
            Name = "SolarisShadow",
            BackgroundTransparency = 1,
            Image = Config.Assets.ShadowBlob,
            ImageColor3 = Color3.new(0,0,0),
            ImageTransparency = 0.4,
            Size = UDim2.new(1, 60, 1, 60),
            Position = UDim2.new(0, -30, 0, -30),
            ZIndex = instance.ZIndex - 1
        })
    end
end

--// PUBLIC API
function ThemeManager.Inject(windowInstance)
    if ThemeManager.Active then ThemeManager.Stop() end
    ThemeManager.Active = true
    ThemeManager.TargetInterface = windowInstance
    
    Utility.Log("Info", "Injecting Solaris Clean Theme into Interface...")
    
    -- 1. Initial Pass
    for _, desc in ipairs(windowInstance:GetDescendants()) do
        ProcessElement(desc)
    end
    
    -- 2. Watch for new elements (e.g. searching, dynamic tabs)
    local conn = windowInstance.DescendantAdded:Connect(function(desc)
        -- Debounce slightly
        task.delay(0.01, function()
            if not desc or not desc.Parent then return end
            ProcessElement(desc)
        end)
    end)
    
    table.insert(ThemeManager.Connections, conn)
end

function ThemeManager.Stop()
    ThemeManager.Active = false
    for _, conn in ipairs(ThemeManager.Connections) do
        conn:Disconnect()
    end
    ThemeManager.Connections = {}
end

return ThemeManager