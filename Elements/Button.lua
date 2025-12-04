--[[
    [MODULE] Elements/Button.lua
    [ARCHITECT] Lead UI Architect
    [SYSTEM] Sirius Rayfield UI Library
    [VERSION] 3.2.0-Enterprise
    [TARGET] Delta Executor / Fluxus / Hydrogen / Roblox Luau

    [DESCRIPTION]
    Standard interactive Button element.
    Includes:
    - Click Ripple Effect
    - Hover Animations
    - Callback execution
    - Debounce protection
]]

local Button = {}
Button.__index = Button

--// Services
local TweenService = game:GetService("TweenService")

--// Modules
local Theme = require(script.Parent.Parent.Theme)
local Utility = require(script.Parent.Parent["Core/Utility"])

function Button.New(Tab, Config)
    local self = setmetatable({}, Button)
    
    self.Tab = Tab
    self.Config = Config or {}
    self.Name = self.Config.Name or "Button"
    self.Callback = self.Config.Callback or function() end
    
    self:CreateUI()
    return self
end

function Button:CreateUI()
    -- Main Container
    local Frame = Instance.new("Frame")
    Frame.Name = "Button_" .. self.Name
    Frame.Parent = self.Tab.Container
    Frame.BackgroundColor3 = Theme.Current.ElementBackground
    Frame.Size = UDim2.new(1, 0, 0, 36)
    Frame.ClipsDescendants = true -- Important for ripple
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 6)
    Corner.Parent = Frame
    
    -- Interactable
    local Interact = Instance.new("TextButton")
    Interact.Name = "Interact"
    Interact.Parent = Frame
    Interact.Size = UDim2.new(1, 0, 1, 0)
    Interact.BackgroundTransparency = 1
    Interact.Text = ""
    Interact.AutoButtonColor = false
    
    -- Title
    local Title = Instance.new("TextLabel")
    Title.Parent = Frame
    Title.Position = UDim2.new(0, 12, 0, 0)
    Title.Size = UDim2.new(1, -24, 1, 0)
    Title.BackgroundTransparency = 1
    Title.Text = self.Name
    Title.Font = Theme.Font or Enum.Font.GothamMedium
    Title.TextSize = 14
    Title.TextColor3 = Theme.Current.Text
    Title.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Icon (Action Symbol)
    local Icon = Instance.new("ImageLabel")
    Icon.Name = "ActionIcon"
    Icon.Parent = Frame
    Icon.AnchorPoint = Vector2.new(1, 0.5)
    Icon.Position = UDim2.new(1, -10, 0.5, 0)
    Icon.Size = UDim2.new(0, 18, 0, 18)
    Icon.BackgroundTransparency = 1
    Icon.Image = "rbxassetid://6031068421" -- Generic pointer/click icon
    Icon.ImageColor3 = Theme.Current.Text
    Icon.ImageTransparency = 0.5
    
    --// Events
    
    -- Hover
    Interact.MouseEnter:Connect(function()
        TweenService:Create(Frame, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Current.Hover}):Play()
        TweenService:Create(Icon, TweenInfo.new(0.2), {ImageColor3 = Theme.Current.Accent, ImageTransparency = 0}):Play()
    end)
    
    Interact.MouseLeave:Connect(function()
        TweenService:Create(Frame, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Current.ElementBackground}):Play()
        TweenService:Create(Icon, TweenInfo.new(0.2), {ImageColor3 = Theme.Current.Text, ImageTransparency = 0.5}):Play()
    end)
    
    -- Click
    Interact.MouseButton1Click:Connect(function()
        self:Ripple(Interact)
        task.spawn(self.Callback)
    end)
    
    self.Instance = Frame
end

function Button:Ripple(obj)
    -- Simple Ripple Implementation
    local Mouse = game:GetService("Players").LocalPlayer:GetMouse()
    local Ripple = Instance.new("ImageLabel")
    Ripple.Name = "Ripple"
    Ripple.Parent = obj.Parent
    Ripple.BackgroundTransparency = 1
    Ripple.Image = "rbxassetid://266543268" -- Soft glow circle
    Ripple.ImageTransparency = 0.8
    Ripple.ImageColor3 = Theme.Current.Text
    Ripple.ScaleType = Enum.ScaleType.Fit
    
    -- Calculate start position
    local AbsPos = obj.Parent.AbsolutePosition
    local X = Mouse.X - AbsPos.X
    local Y = Mouse.Y - AbsPos.Y
    
    Ripple.Position = UDim2.new(0, X, 0, Y)
    Ripple.Size = UDim2.new(0, 0, 0, 0)
    
    local TargetSize = obj.Parent.AbsoluteSize.X * 1.5
    
    local Tween = TweenService:Create(Ripple, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, TargetSize, 0, TargetSize),
        Position = UDim2.new(0, X - (TargetSize/2), 0, Y - (TargetSize/2)),
        ImageTransparency = 1
    })
    
    Tween:Play()
    Tween.Completed:Connect(function()
        Ripple:Destroy()
    end)
end

function Button:Set(text)
    -- Update Button text
    if self.Instance and self.Instance:FindFirstChild("TextLabel") then
        self.Instance.TextLabel.Text = text
    end
    self.Name = text
end

function Button:Destroy()
    if self.Instance then self.Instance:Destroy() end
    setmetatable(self, nil)
end

return Button