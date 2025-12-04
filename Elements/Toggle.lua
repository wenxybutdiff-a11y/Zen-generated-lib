--[[
    [MODULE] Elements/Toggle.lua
    [ARCHITECT] Lead UI Architect
    [SYSTEM] Sirius Rayfield UI Library
    [VERSION] 3.2.0-Enterprise
    [TARGET] Delta Executor / Fluxus / Hydrogen / Roblox Luau
    
    [DESCRIPTION]
    A robust boolean switch element. 
    State is managed internally and communicated via callbacks.
    Animations are handled via TweenService for smooth 60fps transitions.
]]

local Toggle = {}
Toggle.__index = Toggle

--// Services
local TweenService = game:GetService("TweenService")

--// Modules
local Theme = require(script.Parent.Parent.Theme)

--// Constants
local TWEEN_INFO = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

function Toggle.New(Tab, Config)
    local self = setmetatable({}, Toggle)
    
    self.Tab = Tab
    self.Config = Config or {}
    self.Name = self.Config.Name or "Toggle"
    self.CurrentValue = self.Config.CurrentValue or self.Config.Default or false
    self.Callback = self.Config.Callback or function() end
    
    self:CreateUI()
    return self
end

function Toggle:CreateUI()
    -- 1. Main Frame
    local Frame = Instance.new("Frame")
    Frame.Name = "Toggle_" .. self.Name
    Frame.Parent = self.Tab.Container
    Frame.BackgroundColor3 = Theme.Current.ElementBackground
    Frame.Size = UDim2.new(1, 0, 0, 36)
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 6)
    Corner.Parent = Frame
    
    -- 2. Title
    local Title = Instance.new("TextLabel")
    Title.Parent = Frame
    Title.Position = UDim2.new(0, 12, 0, 0)
    Title.Size = UDim2.new(1, -60, 1, 0)
    Title.BackgroundTransparency = 1
    Title.Text = self.Name
    Title.Font = Theme.Font or Enum.Font.GothamMedium
    Title.TextSize = 14
    Title.TextColor3 = Theme.Current.Text
    Title.TextXAlignment = Enum.TextXAlignment.Left
    
    -- 3. Switch Background (The Pill)
    local Switch = Instance.new("Frame")
    Switch.Name = "Switch"
    Switch.Parent = Frame
    Switch.AnchorPoint = Vector2.new(1, 0.5)
    Switch.Position = UDim2.new(1, -12, 0.5, 0)
    Switch.Size = UDim2.new(0, 40, 0, 20)
    Switch.BackgroundColor3 = self.CurrentValue and Theme.Current.Accent or Theme.Current.Secondary
    
    local SwitchCorner = Instance.new("UICorner")
    SwitchCorner.CornerRadius = UDim.new(1, 0)
    SwitchCorner.Parent = Switch
    
    -- 4. Switch Knob (The Circle)
    local Knob = Instance.new("Frame")
    Knob.Name = "Knob"
    Knob.Parent = Switch
    Knob.AnchorPoint = Vector2.new(0, 0.5)
    -- Position calculation based on state
    if self.CurrentValue then
        Knob.Position = UDim2.new(1, -18, 0.5, 0)
    else
        Knob.Position = UDim2.new(0, 2, 0.5, 0)
    end
    Knob.Size = UDim2.new(0, 16, 0, 16)
    Knob.BackgroundColor3 = Theme.Current.Text
    
    local KnobCorner = Instance.new("UICorner")
    KnobCorner.CornerRadius = UDim.new(1, 0)
    KnobCorner.Parent = Knob
    
    -- 5. Interaction
    local Interact = Instance.new("TextButton")
    Interact.Parent = Frame
    Interact.Size = UDim2.new(1, 0, 1, 0)
    Interact.BackgroundTransparency = 1
    Interact.Text = ""
    
    Interact.MouseButton1Click:Connect(function()
        self:Toggle()
    end)
    
    -- Hover effect
    Interact.MouseEnter:Connect(function()
        TweenService:Create(Frame, TWEEN_INFO, {BackgroundColor3 = Theme.Current.Hover}):Play()
    end)
    Interact.MouseLeave:Connect(function()
        TweenService:Create(Frame, TWEEN_INFO, {BackgroundColor3 = Theme.Current.ElementBackground}):Play()
    end)
    
    self.Instance = Frame
    self.Switch = Switch
    self.Knob = Knob
end

function Toggle:Toggle(forceState)
    if forceState ~= nil then
        self.CurrentValue = forceState
    else
        self.CurrentValue = not self.CurrentValue
    end
    
    -- Animate
    if self.CurrentValue then
        -- ON State
        TweenService:Create(self.Switch, TWEEN_INFO, {BackgroundColor3 = Theme.Current.Accent}):Play()
        TweenService:Create(self.Knob, TWEEN_INFO, {Position = UDim2.new(1, -18, 0.5, 0)}):Play()
        TweenService:Create(self.Knob, TWEEN_INFO, {BackgroundColor3 = Color3.new(1,1,1)}):Play()
    else
        -- OFF State
        TweenService:Create(self.Switch, TWEEN_INFO, {BackgroundColor3 = Theme.Current.Secondary}):Play()
        TweenService:Create(self.Knob, TWEEN_INFO, {Position = UDim2.new(0, 2, 0.5, 0)}):Play()
        TweenService:Create(self.Knob, TWEEN_INFO, {BackgroundColor3 = Theme.Current.Text}):Play()
    end
    
    -- Callback
    task.spawn(function()
        self.Callback(self.CurrentValue)
    end)
end

function Toggle:Set(value)
    self:Toggle(value)
end

function Toggle:Destroy()
    if self.Instance then self.Instance:Destroy() end
    setmetatable(self, nil)
end

return Toggle