--[[
    [MODULE] Elements/Keybind.lua
    [ARCHITECT] Lead UI Architect
    [SYSTEM] Sirius Rayfield UI Library
    [VERSION] 2.1.0-Advanced
    [TARGET] Delta Executor / Fluxus / Hydrogen / Roblox Luau
    
    [DESCRIPTION]
    Manages key bindings for toggling features or executing functions.
    Supports:
    - Keyboard inputs (KeyCode)
    - Mouse inputs (UserInputType)
    - Blacklisted keys
    - Hold vs Toggle modes
]]

local Keybind = {}
Keybind.__index = Keybind

--// Services
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

--// Modules
local Utility = require(script.Parent.Parent["Core/Utility"])
local Theme = require(script.Parent.Parent.Theme)

--// Constants
local BLACKLISTED_KEYS = {
    Enum.KeyCode.Unknown,
    Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D,
    Enum.KeyCode.Slash, Enum.KeyCode.Tab, Enum.KeyCode.Backspace, Enum.KeyCode.Escape
}

function Keybind.New(Tab, Config)
    local self = setmetatable({}, Keybind)
    
    self.Tab = Tab
    self.Config = Config or {}
    self.Name = self.Config.Name or "Keybind"
    self.Callback = self.Config.Callback or function() end
    self.CurrentKey = self.Config.Default or self.Config.Keybind or Enum.KeyCode.None
    self.HoldToInteract = self.Config.HoldToInteract or false
    
    self.Binding = false -- State of binding mode
    self.Held = false -- State of key held
    
    self:CreateUI()
    self:StartListeners()
    
    return self
end

function Keybind:CreateUI()
    -- 1. Main Frame
    local Frame = Instance.new("Frame")
    Frame.Name = "Keybind_" .. self.Name
    Frame.Parent = self.Tab.Container
    Frame.BackgroundColor3 = Theme.Current.ElementBackground
    Frame.Size = UDim2.new(1, 0, 0, 40)
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 6)
    Corner.Parent = Frame
    
    -- 2. Title
    local Title = Instance.new("TextLabel")
    Title.Parent = Frame
    Title.Position = UDim2.new(0, 10, 0, 0)
    Title.Size = UDim2.new(0.6, 0, 1, 0)
    Title.BackgroundTransparency = 1
    Title.Text = self.Name
    Title.Font = Theme.Font or Enum.Font.GothamMedium
    Title.TextSize = 14
    Title.TextColor3 = Theme.Current.Text
    Title.TextXAlignment = Enum.TextXAlignment.Left
    
    -- 3. Bind Button (Display current key)
    local BindBtn = Instance.new("TextButton")
    BindBtn.Name = "BindButton"
    BindBtn.Parent = Frame
    BindBtn.AnchorPoint = Vector2.new(1, 0.5)
    BindBtn.Position = UDim2.new(1, -10, 0.5, 0)
    BindBtn.Size = UDim2.new(0, 80, 0, 24)
    BindBtn.BackgroundColor3 = Theme.Current.Secondary
    BindBtn.Text = self:GetKeyName(self.CurrentKey)
    BindBtn.Font = Enum.Font.Gotham
    BindBtn.TextSize = 12
    BindBtn.TextColor3 = Theme.Current.Text
    BindBtn.AutoButtonColor = false
    
    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 4)
    BtnCorner.Parent = BindBtn
    
    -- Stroke
    local Stroke = Instance.new("UIStroke")
    Stroke.Parent = BindBtn
    Stroke.Color = Theme.Current.Accent
    Stroke.Thickness = 1
    Stroke.Transparency = 1
    
    -- Interaction
    BindBtn.MouseButton1Click:Connect(function()
        self:ToggleBindMode()
    end)
    
    self.Instance = Frame
    self.BindButton = BindBtn
    self.Stroke = Stroke
end

function Keybind:GetKeyName(key)
    if not key or key == Enum.KeyCode.None then return "None" end
    local name = key.Name
    if name:find("Button") then -- Mouse buttons
        name = name:gsub("Button", "M")
    end
    return name
end

function Keybind:ToggleBindMode()
    self.Binding = not self.Binding
    
    if self.Binding then
        self.BindButton.Text = "..."
        TweenService:Create(self.Stroke, TweenInfo.new(0.2), {Transparency = 0}):Play()
    else
        self.BindButton.Text = self:GetKeyName(self.CurrentKey)
        TweenService:Create(self.Stroke, TweenInfo.new(0.2), {Transparency = 1}):Play()
    end
end

function Keybind:StartListeners()
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed and not self.Binding then return end
        
        -- Binding Logic
        if self.Binding then
            if input.UserInputType == Enum.UserInputType.Keyboard or input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 then
                
                -- Check blacklist
                local isBlacklisted = false
                for _, k in ipairs(BLACKLISTED_KEYS) do
                    if input.KeyCode == k then isBlacklisted = true break end
                end
                
                if not isBlacklisted then
                    self.CurrentKey = (input.UserInputType == Enum.UserInputType.Keyboard) and input.KeyCode or input.UserInputType
                    self:ToggleBindMode() -- Exit bind mode
                    return
                end
            end
        end
        
        -- Trigger Logic
        if not self.Binding and self.Callback then
            local trigger = false
            if input.KeyCode == self.CurrentKey or input.UserInputType == self.CurrentKey then
                trigger = true
            end
            
            if trigger then
                self.Held = true
                if self.HoldToInteract then
                     -- Hold mode start
                     self.Callback(true) -- Pass state
                else
                     -- Toggle mode
                     self.Callback()
                end
            end
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if self.HoldToInteract and self.Held then
             if input.KeyCode == self.CurrentKey or input.UserInputType == self.CurrentKey then
                 self.Held = false
                 self.Callback(false) -- Hold mode end
             end
        end
    end)
end

function Keybind:Destroy()
    if self.Instance then self.Instance:Destroy() end
    setmetatable(self, nil)
end

return Keybind