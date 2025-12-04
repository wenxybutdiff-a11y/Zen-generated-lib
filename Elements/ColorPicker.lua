--[[
    [MODULE] Elements/ColorPicker.lua
    [ARCHITECT] Lead UI Architect
    [SYSTEM] Sirius Rayfield UI Library
    [VERSION] 4.6.0-Enterprise
    [TARGET] Delta Executor / Fluxus / Hydrogen / Roblox Luau

    [DESCRIPTION]
    A full-featured HSV Color Picker with Rainbow Mode and Hex Input.
    
    [FEATURES]
    - Saturation/Value SV Map interaction.
    - Hue Slider interaction.
    - Rainbow Mode (Looping Hue).
    - Hex Code text input/display.
    - Live Preview window.
]]

local ColorPicker = {}
ColorPicker.__index = ColorPicker

--// Services
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

--// Modules
local Theme = require(script.Parent.Parent.Theme)
local Utility = require(script.Parent.Parent["Core/Utility"])

--// Constants
local PICKER_HEIGHT_CLOSED = 42
local PICKER_HEIGHT_OPEN = 180

function ColorPicker.New(Tab, Config)
    local self = setmetatable({}, ColorPicker)
    
    self.Tab = Tab
    self.Config = Config or {}
    self.Name = self.Config.Name or "ColorPicker"
    self.Default = self.Config.Default or self.Config.Color or Color3.fromRGB(255, 255, 255)
    self.Callback = self.Config.Callback or function() end
    
    -- HSV State
    local h, s, v = self.Default:ToHSV()
    self.HSV = {H = h, S = s, V = v}
    self.CurrentColor = self.Default
    self.RainbowMode = false
    self.RainbowConnection = nil
    
    -- UI State
    self.Open = false
    self.DraggingSV = false
    self.DraggingHue = false
    
    self:CreateUI()
    self:InitLogic()
    
    return self
end

function ColorPicker:CreateUI()
    -- 1. Main Frame
    local Frame = Instance.new("Frame")
    Frame.Name = "ColorPicker_" .. self.Name
    Frame.Parent = self.Tab.Container
    Frame.BackgroundColor3 = Theme.Current.ElementBackground
    Frame.Size = UDim2.new(1, 0, 0, PICKER_HEIGHT_CLOSED)
    Frame.ClipsDescendants = true
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 6)
    Corner.Parent = Frame
    
    -- 2. Header
    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Parent = Frame
    Title.Position = UDim2.new(0, 15, 0, 0)
    Title.Size = UDim2.new(0.5, 0, 0, PICKER_HEIGHT_CLOSED)
    Title.BackgroundTransparency = 1
    Title.Text = self.Name
    Title.Font = Theme.Font or Enum.Font.GothamMedium
    Title.TextSize = 14
    Title.TextColor3 = Theme.Current.Text
    Title.TextXAlignment = Enum.TextXAlignment.Left
    
    -- 3. Color Preview / Toggle Button
    local PreviewBtn = Instance.new("TextButton")
    PreviewBtn.Name = "Preview"
    PreviewBtn.Parent = Frame
    PreviewBtn.AnchorPoint = Vector2.new(1, 0.5)
    PreviewBtn.Position = UDim2.new(1, -15, 0, PICKER_HEIGHT_CLOSED/2)
    PreviewBtn.Size = UDim2.new(0, 40, 0, 20)
    PreviewBtn.BackgroundColor3 = self.CurrentColor
    PreviewBtn.Text = ""
    PreviewBtn.AutoButtonColor = false
    
    local PreviewCorner = Instance.new("UICorner")
    PreviewCorner.CornerRadius = UDim.new(0, 4)
    PreviewCorner.Parent = PreviewBtn
    
    local Stroke = Instance.new("UIStroke")
    Stroke.Parent = PreviewBtn
    Stroke.Color = Color3.new(1,1,1)
    Stroke.Thickness = 1
    Stroke.Transparency = 0.8
    
    -- 4. Expanded Content Container
    local Content = Instance.new("Frame")
    Content.Name = "Content"
    Content.Parent = Frame
    Content.Position = UDim2.new(0, 0, 0, PICKER_HEIGHT_CLOSED)
    Content.Size = UDim2.new(1, 0, 0, 138)
    Content.BackgroundTransparency = 1
    Content.Visible = true
    
    -- 5. SV Map (Saturation/Value)
    local SVMap = Instance.new("ImageButton")
    SVMap.Name = "SVMap"
    SVMap.Parent = Content
    SVMap.Position = UDim2.new(0, 15, 0, 10)
    SVMap.Size = UDim2.new(1, -60, 0, 100) -- Takes up most width
    SVMap.BackgroundColor3 = Color3.fromHSV(self.HSV.H, 1, 1)
    SVMap.Image = "rbxassetid://4155801252" -- SV Gradient Overlay
    SVMap.AutoButtonColor = false
    
    local SVCorner = Instance.new("UICorner")
    SVCorner.CornerRadius = UDim.new(0, 4)
    SVCorner.Parent = SVMap
    
    -- Cursor
    local SVCursor = Instance.new("Frame")
    SVCursor.Name = "Cursor"
    SVCursor.Parent = SVMap
    SVCursor.Size = UDim2.new(0, 6, 0, 6)
    SVCursor.AnchorPoint = Vector2.new(0.5, 0.5)
    SVCursor.BackgroundColor3 = Color3.new(1,1,1)
    SVCursor.BorderColor3 = Color3.new(0,0,0)
    SVCursor.Position = UDim2.new(self.HSV.S, 0, 1 - self.HSV.V, 0)
    
    local SVCursorCorner = Instance.new("UICorner")
    SVCursorCorner.CornerRadius = UDim.new(1,0)
    SVCursorCorner.Parent = SVCursor
    
    -- 6. Hue Slider
    local HueMap = Instance.new("ImageButton")
    HueMap.Name = "HueMap"
    HueMap.Parent = Content
    HueMap.AnchorPoint = Vector2.new(1, 0)
    HueMap.Position = UDim2.new(1, -15, 0, 10)
    HueMap.Size = UDim2.new(0, 20, 0, 100)
    HueMap.BackgroundColor3 = Color3.new(1,1,1)
    HueMap.Image = "rbxassetid://4155801252" -- Will be covered by gradient
    HueMap.AutoButtonColor = false
    
    local HueGradient = Instance.new("UIGradient")
    HueGradient.Rotation = 90
    HueGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
        ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 0, 255)),
        ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 0, 255)),
        ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
        ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 255, 0)),
        ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 255, 0)),
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0))
    }
    HueGradient.Parent = HueMap
    
    local HueCorner = Instance.new("UICorner")
    HueCorner.CornerRadius = UDim.new(0, 4)
    HueCorner.Parent = HueMap
    
    -- Hue Cursor
    local HueCursor = Instance.new("Frame")
    HueCursor.Parent = HueMap
    HueCursor.Size = UDim2.new(1, 0, 0, 2)
    HueCursor.AnchorPoint = Vector2.new(0, 0.5)
    HueCursor.Position = UDim2.new(0, 0, self.HSV.H, 0)
    HueCursor.BackgroundColor3 = Color3.new(1,1,1)
    HueCursor.BorderSizePixel = 0
    
    -- 7. Bottom Controls (Rainbow Button & Hex Input)
    local RainbowBtn = Instance.new("TextButton")
    RainbowBtn.Name = "Rainbow"
    RainbowBtn.Parent = Content
    RainbowBtn.Position = UDim2.new(0, 15, 0, 115)
    RainbowBtn.Size = UDim2.new(0, 60, 0, 18)
    RainbowBtn.BackgroundColor3 = Theme.Current.Secondary
    RainbowBtn.Text = "Rainbow"
    RainbowBtn.Font = Theme.Font or Enum.Font.Gotham
    RainbowBtn.TextSize = 10
    RainbowBtn.TextColor3 = Theme.Current.Text
    
    local RCorner = Instance.new("UICorner")
    RCorner.CornerRadius = UDim.new(0, 4)
    RCorner.Parent = RainbowBtn
    
    local HexInput = Instance.new("TextBox")
    HexInput.Name = "Hex"
    HexInput.Parent = Content
    HexInput.AnchorPoint = Vector2.new(1, 0)
    HexInput.Position = UDim2.new(1, -15, 0, 115)
    HexInput.Size = UDim2.new(0, 80, 0, 18)
    HexInput.BackgroundColor3 = Theme.Current.Secondary
    HexInput.Text = "#" .. self.CurrentColor:ToHex()
    HexInput.Font = Enum.Font.Code
    HexInput.TextSize = 12
    HexInput.TextColor3 = Theme.Current.Text
    
    local HCorner = Instance.new("UICorner")
    HCorner.CornerRadius = UDim.new(0, 4)
    HCorner.Parent = HexInput
    
    -- Store Refs
    self.Instance = Frame
    self.PreviewBtn = PreviewBtn
    self.SVMap = SVMap
    self.SVCursor = SVCursor
    self.HueMap = HueMap
    self.HueCursor = HueCursor
    self.HexInput = HexInput
    self.RainbowBtn = RainbowBtn
    
    -- Event Bindings
    PreviewBtn.MouseButton1Click:Connect(function() self:Toggle() end)
    
    RainbowBtn.MouseButton1Click:Connect(function()
        self.RainbowMode = not self.RainbowMode
        if self.RainbowMode then
            self:StartRainbow()
            RainbowBtn.TextColor3 = Theme.Current.Accent
        else
            self:StopRainbow()
            RainbowBtn.TextColor3 = Theme.Current.Text
        end
    end)
    
    HexInput.FocusLost:Connect(function()
        local hex = HexInput.Text:gsub("#", "")
        -- Basic hex validation
        local success, color = pcall(function() return Color3.fromHex(hex) end)
        if success then
            self:Set(color)
        else
            HexInput.Text = "#" .. self.CurrentColor:ToHex()
        end
    end)
end

--[[
    [METHOD] InitLogic
    Handles Dragging for SV and Hue.
]]
function ColorPicker:InitLogic()
    -- SV Drag
    self.SVMap.MouseButton1Down:Connect(function() self.DraggingSV = true end)
    
    -- Hue Drag
    self.HueMap.MouseButton1Down:Connect(function() self.DraggingHue = true end)
    
    -- Global Mouse Up
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            self.DraggingSV = false
            self.DraggingHue = false
        end
    end)
    
    -- Update Loop
    RunService.RenderStepped:Connect(function()
        if not self.Open then return end
        
        local Mouse = UserInputService:GetMouseLocation()
        
        if self.DraggingSV then
            local Pos = self.SVMap.AbsolutePosition
            local Size = self.SVMap.AbsoluteSize
            
            local S = math.clamp((Mouse.X - Pos.X) / Size.X, 0, 1)
            local V = 1 - math.clamp((Mouse.Y - Pos.Y) / Size.Y, 0, 1)
            
            self.HSV.S = S
            self.HSV.V = V
            
            self.SVCursor.Position = UDim2.new(S, 0, 1 - V, 0)
            self:UpdateColor(true)
        end
        
        if self.DraggingHue then
            local Pos = self.HueMap.AbsolutePosition
            local Size = self.HueMap.AbsoluteSize
            
            local H = 1 - math.clamp((Mouse.Y - Pos.Y) / Size.Y, 0, 1)
            -- Note: Standard HSV gradients usually run top to bottom or bottom to top.
            -- Our gradient keypoints were 0->1. 
            
            self.HSV.H = H
            self.HueCursor.Position = UDim2.new(0, 0, 1 - H, 0)
            self.SVMap.BackgroundColor3 = Color3.fromHSV(H, 1, 1)
            
            self:UpdateColor(true)
        end
    end)
end

function ColorPicker:UpdateColor(triggerCallback)
    self.CurrentColor = Color3.fromHSV(self.HSV.H, self.HSV.S, self.HSV.V)
    
    -- Update UI
    self.PreviewBtn.BackgroundColor3 = self.CurrentColor
    self.HexInput.Text = "#" .. self.CurrentColor:ToHex()
    
    if triggerCallback then
        self.Callback(self.CurrentColor)
    end
end

function ColorPicker:Toggle()
    self.Open = not self.Open
    
    if self.Open then
        TweenService:Create(self.Instance, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {Size = UDim2.new(1, 0, 0, PICKER_HEIGHT_OPEN)}):Play()
        if self.Tab and self.Tab.UpdateLayout then
            task.delay(0.2, function() self.Tab:UpdateLayout() end)
        end
    else
        TweenService:Create(self.Instance, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {Size = UDim2.new(1, 0, 0, PICKER_HEIGHT_CLOSED)}):Play()
        if self.Tab and self.Tab.UpdateLayout then
            task.delay(0.2, function() self.Tab:UpdateLayout() end)
        end
    end
end

function ColorPicker:StartRainbow()
    if self.RainbowConnection then return end
    self.RainbowConnection = RunService.Heartbeat:Connect(function()
        local h = tick() % 5 / 5
        self.HSV.H = h
        self.HueCursor.Position = UDim2.new(0, 0, 1 - h, 0)
        self.SVMap.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        self:UpdateColor(true)
    end)
end

function ColorPicker:StopRainbow()
    if self.RainbowConnection then
        self.RainbowConnection:Disconnect()
        self.RainbowConnection = nil
    end
end

function ColorPicker:Set(color)
    local h, s, v = color:ToHSV()
    self.HSV = {H = h, S = s, V = v}
    self.CurrentColor = color
    
    self.SVCursor.Position = UDim2.new(s, 0, 1 - v, 0)
    self.HueCursor.Position = UDim2.new(0, 0, 1 - h, 0)
    self.SVMap.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
    
    self:UpdateColor(false)
end

function ColorPicker:Destroy()
    self:StopRainbow()
    if self.Instance then self.Instance:Destroy() end
    setmetatable(self, nil)
end

return ColorPicker