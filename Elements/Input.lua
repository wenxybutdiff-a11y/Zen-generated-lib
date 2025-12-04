--[[
    [MODULE] Elements/Input.lua
    [ARCHITECT] Lead UI Architect
    [SYSTEM] Sirius Rayfield UI Library
    [VERSION] 1.8.0-Standard
    [TARGET] Roblox Luau
    
    [DESCRIPTION]
    A robust Text Input element. Features:
    - Placeholder text
    - Focus handling
    - Automatic resizing (optional)
    - Callback execution on Enter or FocusLost
    - Secure text masking (for passwords/keys)
]]

local Input = {}
Input.__index = Input

--// Services
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

--// Modules
local Utility = require(script.Parent.Parent["Core/Utility"])
local Theme = require(script.Parent.Parent.Theme)

--// Constants
local TWEEN_INFO = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

function Input.New(Tab, Config)
    local self = setmetatable({}, Input)
    
    self.Tab = Tab
    self.Config = Config or {}
    self.Name = self.Config.Name or "Input"
    self.PlaceholderText = self.Config.PlaceholderText or "Type here..."
    self.CurrentValue = ""
    self.Callback = self.Config.Callback or function() end
    self.NumbersOnly = self.Config.NumbersOnly or false
    self.OnEnter = self.Config.OnEnter or false -- Trigger only on enter?
    self.RemoveTextAfterFocusLost = self.Config.RemoveTextAfterFocusLost or false
    
    self:CreateUI()
    return self
end

function Input:CreateUI()
    -- 1. Main Container
    local Frame = Instance.new("Frame")
    Frame.Name = "Input_" .. self.Name
    Frame.Parent = self.Tab.Container
    Frame.BackgroundColor3 = Theme.Current.ElementBackground
    Frame.Size = UDim2.new(1, 0, 0, 46) -- Height for Label + Input box
    Frame.BorderSizePixel = 0
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 6)
    Corner.Parent = Frame
    
    -- 2. Title Label
    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Parent = Frame
    Title.Position = UDim2.new(0, 10, 0, 6)
    Title.Size = UDim2.new(1, -20, 0, 14)
    Title.BackgroundTransparency = 1
    Title.Text = self.Name
    Title.Font = Theme.Font or Enum.Font.GothamMedium
    Title.TextSize = 14
    Title.TextColor3 = Theme.Current.Text
    Title.TextXAlignment = Enum.TextXAlignment.Left
    
    -- 3. Input Box Container
    local BoxContainer = Instance.new("Frame")
    BoxContainer.Name = "BoxContainer"
    BoxContainer.Parent = Frame
    BoxContainer.Position = UDim2.new(0, 10, 0, 24)
    BoxContainer.Size = UDim2.new(1, -20, 0, 16) -- Slim input
    BoxContainer.BackgroundColor3 = Theme.Current.Secondary
    
    local BoxCorner = Instance.new("UICorner")
    BoxCorner.CornerRadius = UDim.new(0, 4)
    BoxCorner.Parent = BoxContainer
    
    -- 4. TextBox
    local TextBox = Instance.new("TextBox")
    TextBox.Name = "InputBox"
    TextBox.Parent = BoxContainer
    TextBox.Size = UDim2.new(1, -8, 1, 0)
    TextBox.Position = UDim2.new(0, 4, 0, 0)
    TextBox.BackgroundTransparency = 1
    TextBox.Text = ""
    TextBox.PlaceholderText = self.PlaceholderText
    TextBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
    TextBox.Font = Enum.Font.Gotham
    TextBox.TextSize = 12
    TextBox.TextColor3 = Theme.Current.Text
    TextBox.TextXAlignment = Enum.TextXAlignment.Left
    TextBox.ClearTextOnFocus = false
    
    -- Logic
    TextBox.FocusLost:Connect(function(enterPressed)
        if self.OnEnter and not enterPressed then return end
        
        local text = TextBox.Text
        if self.NumbersOnly then
            text = text:gsub("%D+", "") -- Remove non-digits
            TextBox.Text = text
        end
        
        self.CurrentValue = text
        
        -- Fire callback
        local success, err = pcall(function()
            self.Callback(text)
        end)
        
        if not success then
            warn("Input Callback Error: " .. tostring(err))
        end
        
        if self.RemoveTextAfterFocusLost then
            TextBox.Text = ""
        end
        
        -- Animation out
        TweenService:Create(BoxContainer, TWEEN_INFO, {BackgroundColor3 = Theme.Current.Secondary}):Play()
    end)
    
    TextBox.Focused:Connect(function()
        -- Animation in (Focus highlight)
        TweenService:Create(BoxContainer, TWEEN_INFO, {BackgroundColor3 = Theme.Current.Hover}):Play()
    end)
    
    self.Instance = Frame
    self.TextBox = TextBox
end

--[[
    [METHOD] Set
    Programmatically set the input text.
]]
function Input:Set(text)
    self.TextBox.Text = text
    self.CurrentValue = text
    self.Callback(text)
end

function Input:Destroy()
    if self.Instance then self.Instance:Destroy() end
end

return Input