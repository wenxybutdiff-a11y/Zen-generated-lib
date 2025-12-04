--[[
    [MODULE] Elements/Label.lua
    [ARCHITECT] Lead UI Architect
    [SYSTEM] Sirius Rayfield UI Library
    [VERSION] 3.2.0-Enterprise
    
    [DESCRIPTION]
    A lightweight element for displaying status text, headers, or warnings.
    Differs from Paragraph by being single-line focused (mostly) and having 
    different interaction properties (clipboard copy).
]]

local Label = {}
Label.__index = Label

--// Services
local TweenService = game:GetService("TweenService")

--// Modules
local Theme = require(script.Parent.Parent.Theme)
local Utility = require(script.Parent.Parent["Core/Utility"])

function Label.New(Tab, Config)
    local self = setmetatable({}, Label)
    
    self.Tab = Tab
    self.Config = Config or {}
    -- Support passing just string or table
    if type(self.Config) == "string" then
        self.Text = self.Config
        self.Icon = nil
        self.Color = nil
    else
        self.Text = self.Config.Text or "Label"
        self.Icon = self.Config.Icon or nil
        self.Color = self.Config.Color or nil
    end
    
    self:CreateUI()
    return self
end

function Label:CreateUI()
    local Frame = Instance.new("Frame")
    Frame.Name = "Label"
    Frame.Parent = self.Tab.Container
    Frame.BackgroundColor3 = Color3.new(0,0,0)
    Frame.BackgroundTransparency = 1 -- Transparent by default
    Frame.Size = UDim2.new(1, 0, 0, 26)
    
    -- Icon (if present)
    local TextXOffset = 10
    if self.Icon then
        local IconImg = Instance.new("ImageLabel")
        IconImg.Parent = Frame
        IconImg.AnchorPoint = Vector2.new(0, 0.5)
        IconImg.Position = UDim2.new(0, 10, 0.5, 0)
        IconImg.Size = UDim2.new(0, 18, 0, 18)
        IconImg.BackgroundTransparency = 1
        IconImg.Image = "rbxassetid://" .. tostring(self.Icon)
        IconImg.ImageColor3 = self.Color or Theme.Current.Accent
        
        TextXOffset = 35
    end
    
    -- Text
    local TextLabel = Instance.new("TextLabel")
    TextLabel.Name = "Text"
    TextLabel.Parent = Frame
    TextLabel.AnchorPoint = Vector2.new(0, 0.5)
    TextLabel.Position = UDim2.new(0, TextXOffset, 0.5, 0)
    TextLabel.Size = UDim2.new(1, -TextXOffset, 1, 0)
    TextLabel.BackgroundTransparency = 1
    TextLabel.Font = Enum.Font.GothamMedium
    TextLabel.Text = self.Text
    TextLabel.TextColor3 = self.Color or Theme.Current.Text
    TextLabel.TextSize = 14
    TextLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Optional interaction: Copy on click?
    -- Creating a button wrapper if user clicks it for feedback
    local Interactive = Instance.new("TextButton")
    Interactive.Parent = Frame
    Interactive.Size = UDim2.new(1,0,1,0)
    Interactive.BackgroundTransparency = 1
    Interactive.Text = ""
    Interactive.ZIndex = 2
    
    Interactive.MouseButton1Click:Connect(function()
        if setclipboard then
            setclipboard(self.Text)
            -- Feedback Pulse
            TweenService:Create(TextLabel, TweenInfo.new(0.1), {TextColor3 = Theme.Current.Accent}):Play()
            task.delay(0.2, function()
                TweenService:Create(TextLabel, TweenInfo.new(0.3), {TextColor3 = self.Color or Theme.Current.Text}):Play()
            end)
        end
    end)
    
    self.Instance = Frame
    self.TextLabel = TextLabel
end

function Label:Set(text)
    self.Text = text
    self.TextLabel.Text = text
end

function Label:Destroy()
    if self.Instance then self.Instance:Destroy() end
    setmetatable(self, nil)
end

return Label