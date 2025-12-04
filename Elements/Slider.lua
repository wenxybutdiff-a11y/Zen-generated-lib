--[[
    [MODULE] Elements/Slider.lua
    [ARCHITECT] Lead UI Architect
    [SYSTEM] Sirius Rayfield UI Library
    [VERSION] 4.5.0-DeltaOptimized
    [TARGET] Delta Executor / Fluxus / Hydrogen / Roblox Luau

    [DESCRIPTION]
    A high-precision numeric input slider designed for both desktop and mobile (touch) environments.
    
    [FEATURES]
    - precise fractional increments.
    - Manual value entry via TextBox.
    - Smooth Tweening for visual feedback.
    - Global Input Handling (prevents drag-loss when moving mouse fast).
    - Touch-compatible drag logic.
]]

local Slider = {}
Slider.__index = Slider

--// Services
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

--// Modules
local Theme = require(script.Parent.Parent.Theme)
local Utility = require(script.Parent.Parent["Core/Utility"])

--// Constants
local TWEEN_INFO = TweenInfo.new(0.08, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
local HOVER_TWEEN = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

--[[
    [CONSTRUCTOR] Slider.New
]]
function Slider.New(Tab, Config)
    local self = setmetatable({}, Slider)
    
    -- Configuration
    self.Tab = Tab
    self.Config = Config or {}
    self.Name = self.Config.Name or "Slider"
    self.Min = self.Config.Min or 0
    self.Max = self.Config.Max or 100
    self.Increment = self.Config.Increment or 1
    self.Suffix = self.Config.Suffix or ""
    self.Callback = self.Config.Callback or function() end
    
    -- Value Validation
    local defaultVal = self.Config.CurrentValue or self.Config.Default or self.Min
    self.CurrentValue = math.clamp(defaultVal, self.Min, self.Max)
    
    -- State
    self.Dragging = false
    self.Hovering = false
    
    self:CreateUI()
    self:InitLogic()
    
    return self
end

--[[
    [METHOD] CreateUI
    Builds the graphical interface for the slider.
]]
function Slider:CreateUI()
    -- 1. Main Container
    local Frame = Instance.new("Frame")
    Frame.Name = "Slider_" .. self.Name
    Frame.Parent = self.Tab.Container
    Frame.BackgroundColor3 = Theme.Current.ElementBackground
    Frame.Size = UDim2.new(1, 0, 0, 55)
    Frame.BorderSizePixel = 0
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 6)
    Corner.Parent = Frame
    
    -- 2. Header (Title)
    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Parent = Frame
    Title.Position = UDim2.new(0, 15, 0, 10)
    Title.Size = UDim2.new(0.5, 0, 0, 14)
    Title.BackgroundTransparency = 1
    Title.Text = self.Name
    Title.Font = Theme.Font or Enum.Font.GothamMedium
    Title.TextSize = 14
    Title.TextColor3 = Theme.Current.Text
    Title.TextXAlignment = Enum.TextXAlignment.Left
    
    -- 3. Value Input Box
    local ValueBox = Instance.new("TextBox")
    ValueBox.Name = "ValueBox"
    ValueBox.Parent = Frame
    ValueBox.AnchorPoint = Vector2.new(1, 0)
    ValueBox.Position = UDim2.new(1, -15, 0, 10)
    ValueBox.Size = UDim2.new(0, 60, 0, 18)
    ValueBox.BackgroundTransparency = 1
    ValueBox.Text = tostring(self.CurrentValue) .. self.Suffix
    ValueBox.Font = Theme.FontBold or Enum.Font.GothamBold
    ValueBox.TextSize = 12
    ValueBox.TextColor3 = Theme.Current.Text
    ValueBox.TextXAlignment = Enum.TextXAlignment.Right
    ValueBox.ClearTextOnFocus = true
    
    -- 4. Slider Track (Background)
    local Track = Instance.new("TextButton") -- TextButton for input capture
    Track.Name = "Track"
    Track.Parent = Frame
    Track.Position = UDim2.new(0, 15, 0, 35)
    Track.Size = UDim2.new(1, -30, 0, 6)
    Track.BackgroundColor3 = Theme.Current.Secondary
    Track.AutoButtonColor = false
    Track.Text = ""
    
    local TrackCorner = Instance.new("UICorner")
    TrackCorner.CornerRadius = UDim.new(1, 0)
    TrackCorner.Parent = Track
    
    -- 5. Fill Bar (Progress)
    local Fill = Instance.new("Frame")
    Fill.Name = "Fill"
    Fill.Parent = Track
    Fill.BackgroundColor3 = Theme.Current.Accent
    Fill.Size = UDim2.new(0, 0, 1, 0)
    Fill.BorderSizePixel = 0
    
    local FillCorner = Instance.new("UICorner")
    FillCorner.CornerRadius = UDim.new(1, 0)
    FillCorner.Parent = Fill
    
    -- 6. Knob (Visual Handle)
    local Knob = Instance.new("Frame")
    Knob.Name = "Knob"
    Knob.Parent = Fill
    Knob.AnchorPoint = Vector2.new(0.5, 0.5)
    Knob.Position = UDim2.new(1, 0, 0.5, 0) -- Positioned at the end of fill
    Knob.Size = UDim2.new(0, 12, 0, 12)
    Knob.BackgroundColor3 = Theme.Current.Text
    Knob.BorderSizePixel = 0
    
    local KnobCorner = Instance.new("UICorner")
    KnobCorner.CornerRadius = UDim.new(1, 0)
    KnobCorner.Parent = Knob
    
    -- Store References
    self.Instance = Frame
    self.Track = Track
    self.Fill = Fill
    self.Knob = Knob
    self.ValueBox = ValueBox
    self.TitleLabel = Title
    
    -- Initial Update
    self:UpdateVisuals(self.CurrentValue)
end

--[[
    [METHOD] InitLogic
    Sets up event listeners for interaction.
]]
function Slider:InitLogic()
    -- 1. Drag Start (Mouse/Touch)
    self.Track.MouseButton1Down:Connect(function()
        self.Dragging = true
        self:CalculateValue()
        
        -- Animation: Grow Knob
        TweenService:Create(self.Knob, HOVER_TWEEN, {Size = UDim2.new(0, 16, 0, 16)}):Play()
        TweenService:Create(self.Fill, HOVER_TWEEN, {BackgroundColor3 = Theme.Current.Accent}):Play()
    end)
    
    -- 2. Drag End (Global)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if self.Dragging then
                self.Dragging = false
                
                -- Animation: Shrink Knob
                TweenService:Create(self.Knob, HOVER_TWEEN, {Size = UDim2.new(0, 12, 0, 12)}):Play()
            end
        end
    end)
    
    -- 3. Dragging Loop (High Performance)
    RunService.RenderStepped:Connect(function()
        if self.Dragging then
            self:CalculateValue()
        end
    end)
    
    -- 4. Manual Input via TextBox
    self.ValueBox.FocusLost:Connect(function(enterPressed)
        local text = self.ValueBox.Text
        -- Remove suffix for parsing
        text = text:gsub(self.Suffix, "")
        local num = tonumber(text)
        
        if num then
            self:Set(num)
        else
            -- Invalid input, revert
            self.ValueBox.Text = tostring(self.CurrentValue) .. self.Suffix
        end
    end)
    
    -- 5. Hover Effects
    self.Track.MouseEnter:Connect(function()
        self.Hovering = true
        TweenService:Create(self.TitleLabel, HOVER_TWEEN, {TextColor3 = Theme.Current.Accent}):Play()
    end)
    
    self.Track.MouseLeave:Connect(function()
        self.Hovering = false
        if not self.Dragging then
            TweenService:Create(self.TitleLabel, HOVER_TWEEN, {TextColor3 = Theme.Current.Text}):Play()
        end
    end)
end

--[[
    [METHOD] CalculateValue
    Determines slider value based on mouse position relative to track.
]]
function Slider:CalculateValue()
    local MousePos = UserInputService:GetMouseLocation().X
    local TrackPos = self.Track.AbsolutePosition.X
    local TrackSize = self.Track.AbsoluteSize.X
    
    -- Determine percentage (0.0 to 1.0)
    local percent = (MousePos - TrackPos) / TrackSize
    percent = math.clamp(percent, 0, 1)
    
    -- Calculate raw value
    local value = self.Min + (self.Max - self.Min) * percent
    
    -- Round to nearest increment
    local remainder = value % self.Increment
    if remainder < self.Increment / 2 then
        value = value - remainder
    else
        value = value + (self.Increment - remainder)
    end
    
    -- Clamp final value
    value = math.clamp(value, self.Min, self.Max)
    
    -- Update if changed
    if value ~= self.CurrentValue then
        self:Set(value)
    end
end

--[[
    [METHOD] UpdateVisuals
    Updates the UI without triggering the callback.
]]
function Slider:UpdateVisuals(value)
    local percent = (value - self.Min) / (self.Max - self.Min)
    percent = math.clamp(percent, 0, 1)
    
    -- Tween the fill bar
    TweenService:Create(self.Fill, TWEEN_INFO, {Size = UDim2.new(percent, 0, 1, 0)}):Play()
    
    -- Update Text
    -- Format based on increment (integers vs decimals)
    if self.Increment % 1 == 0 then
        self.ValueBox.Text = string.format("%d%s", value, self.Suffix)
    else
        self.ValueBox.Text = string.format("%.2f%s", value, self.Suffix)
    end
end

--[[
    [METHOD] Set
    Public API to set the slider value.
]]
function Slider:Set(newValue)
    local old = self.CurrentValue
    self.CurrentValue = math.clamp(newValue, self.Min, self.Max)
    
    self:UpdateVisuals(self.CurrentValue)
    
    if self.CurrentValue ~= old then
        task.spawn(function()
            self.Callback(self.CurrentValue)
        end)
    end
end

--[[
    [METHOD] Destroy
]]
function Slider:Destroy()
    if self.Instance then
        self.Instance:Destroy()
    end
    setmetatable(self, nil)
end

return Slider