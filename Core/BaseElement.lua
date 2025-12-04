--[[
    [MODULE] Core/BaseElement.lua
    [ARCHITECT] Lead UI Architect
    [SYSTEM] Sirius Rayfield Framework
    [VERSION] 3.0.0-Alpha
    [TARGET] Delta Executor / Fluxus / Hydrogen / Roblox Luau

    [DESCRIPTION]
    The foundational abstract class for all User Interface elements within the library.
    This module provides a robust Object-Oriented base, handling:
    - Lifecycle Management (New, Mount, Destroy)
    - Event Dispatching (Custom Signal Implementation)
    - Visual State Management (Theme application, Tweening)
    - Input Processing (Hover, Click, Focus)
    - Hierarchy Logic (Parent/Child relationships)

    [DESIGN PATTERN]
    Uses a Metatable-based class system. All specific elements (Buttons, Sliders, etc.)
    should inherit from this BaseElement to ensure consistent behavior and API surface.

    [DEPENDENCIES]
    - Core/Utility.lua (Helper functions)
    - Core/Config.lua (Theme data)
]]

local BaseElement = {}
BaseElement.__index = BaseElement
BaseElement.__type = "BaseElement"

--// -----------------------------------------------------------------------------
--// IMPORTS
--// -----------------------------------------------------------------------------
local Utility = require(script.Parent.Utility)
local Config = require(script.Parent.Config)

--// -----------------------------------------------------------------------------
--// SERVICES
--// -----------------------------------------------------------------------------
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

--// -----------------------------------------------------------------------------
--// PRIVATE: SIGNAL IMPLEMENTATION
--// -----------------------------------------------------------------------------
-- A lightweight, robust event system for internal element communication.
-- This ensures we don't rely on Roblox BindableEvents which can be slow or insecure on some executors.

local Signal = {}
Signal.__index = Signal
Signal.__type = "Signal"

function Signal.new(name)
    local self = setmetatable({}, Signal)
    self.Name = name or "AnonymousSignal"
    self._connections = {}
    self._threads = {}
    return self
end

function Signal:Connect(handler)
    if typeof(handler) ~= "function" then
        warn("[BaseElement::Signal] Attempt to connect non-function handler.")
        return { Disconnect = function() end }
    end

    local connection = {
        Connected = true,
        _handler = handler,
        _signal = self
    }

    function connection:Disconnect()
        if not self.Connected then return end
        self.Connected = false
        
        -- Remove from parent signal list
        if self._signal and self._signal._connections then
            for i, conn in ipairs(self._signal._connections) do
                if conn == self then
                    table.remove(self._signal._connections, i)
                    break
                end
            end
        end
    end

    table.insert(self._connections, connection)
    return connection
end

function Signal:Fire(...)
    local args = {...}
    for _, conn in ipairs(self._connections) do
        if conn.Connected and conn._handler then
            -- Use task.spawn for non-blocking execution
            task.spawn(function()
                local success, err = pcall(conn._handler, unpack(args))
                if not success then
                    warn("[BaseElement::Signal] Error in handler for " .. self.Name .. ": " .. tostring(err))
                end
            end)
        end
    end
end

function Signal:Wait()
    local running = coroutine.running()
    table.insert(self._threads, running)
    self:Connect(function(...)
        -- This connection is temporary, handled by the coroutine resume
    end)
    return coroutine.yield()
end

function Signal:Destroy()
    self._connections = {}
    self._threads = {}
end

--// -----------------------------------------------------------------------------
--// BASE ELEMENT CLASS
--// -----------------------------------------------------------------------------

--[[
    [CONSTRUCTOR] BaseElement.new
    Initializes a new UI Element object.
    
    @param propertiesTable (table) - Initial configuration data.
    @return (BaseElement) - The new instance.
]]
function BaseElement.new(propertiesTable)
    local self = setmetatable({}, BaseElement)

    -- Identity
    self.ID = Utility.GenerateID(10) -- Assumes Utility has ID gen, otherwise uses random string
    self.Type = "Base"
    self.Name = propertiesTable.Name or "UnnamedElement"
    self.Class = "Frame" -- Default Roblox Class

    -- State
    self.Enabled = true
    self.Visible = true
    self.Hovered = false
    self.Focused = false
    self.Disposed = false

    -- Hierarchy
    self.Parent = nil -- The BaseElement parent
    self.Instance = nil -- The Roblox Instance
    self.Children = {} -- List of child BaseElements

    -- Events (Signals)
    self.Events = {
        OnHover = Signal.new("OnHover"),
        OnHoverEnd = Signal.new("OnHoverEnd"),
        OnClick = Signal.new("OnClick"),
        OnUpdate = Signal.new("OnUpdate"),
        OnDestroy = Signal.new("OnDestroy"),
        OnThemeChanged = Signal.new("OnThemeChanged")
    }

    -- Configuration
    self.Config = propertiesTable or {}
    self.ThemeOverride = self.Config.Theme or nil

    -- Initialize internal storage for generic data
    self._storage = {}
    
    return self
end

--[[
    [METHOD] BaseElement:Construct
    Builds the visual representation (Roblox Instance) of the element.
    Intended to be overridden by subclasses.
]]
function BaseElement:Construct()
    -- Base implementation creates a simple generic Frame
    local frame = Instance.new("Frame")
    frame.Name = self.Name
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.BorderSizePixel = 0
    frame.Size = UDim2.new(1, 0, 0, 30) -- Default size
    frame.Visible = self.Visible
    
    self.Instance = frame
    
    -- Setup basic event forwarding
    self:SetupInputEvents()
    
    return frame
end

--[[
    [METHOD] BaseElement:SetupInputEvents
    Binds internal Roblox input events to our custom Signals.
    Safe for Delta Executor (checks for signal existence).
]]
function BaseElement:SetupInputEvents()
    if not self.Instance then return end

    -- Hover Enter
    if self.Instance:IsA("GuiObject") then
        self.Instance.MouseEnter:Connect(function()
            if not self.Enabled then return end
            self.Hovered = true
            self.Events.OnHover:Fire()
            self:OnHoverStart() -- Internal hook
        end)

        -- Hover Leave
        self.Instance.MouseLeave:Connect(function()
            self.Hovered = false
            self.Events.OnHoverEnd:Fire()
            self:OnHoverEnd() -- Internal hook
        end)

        -- Click (Requires InputBegan for generic Frames or MouseButton1Click for Buttons)
        self.Instance.InputBegan:Connect(function(input)
            if not self.Enabled then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                self.Events.OnClick:Fire(input)
                self:OnClick(input) -- Internal hook
            end
        end)
    end
end

--[[
    [METHOD] BaseElement:SetParent
    Sets the parent of this element, both logically and visually.
    
    @param parent (BaseElement or Instance) - The new parent.
]]
function BaseElement:SetParent(parent)
    if self.Disposed then return end

    -- Handle logical parenting if parent is another BaseElement
    if type(parent) == "table" and parent.__type then
        self.Parent = parent
        table.insert(parent.Children, self)
        
        -- Apply visual parent
        if self.Instance and parent.Instance then
            self.Instance.Parent = parent.Instance
            -- If parent has a content container (e.g., ScrollingFrame), prefer that
            if parent.Container then
                self.Instance.Parent = parent.Container
            end
        end
        
    -- Handle raw Roblox Instance parenting
    elseif typeof(parent) == "Instance" then
        self.Parent = nil -- No logical parent
        if self.Instance then
            self.Instance.Parent = parent
        end
    else
        warn("[BaseElement] Invalid parent type provided: " .. tostring(parent))
    end
    
    self:UpdateTheme() -- Refresh theme in case parent affects it
end

--[[
    [METHOD] BaseElement:SetVisible
    Toggles the visibility of the element's instance.
    
    @param visible (bool)
]]
function BaseElement:SetVisible(visible)
    self.Visible = visible
    if self.Instance then
        self.Instance.Visible = visible
    end
end

--[[
    [METHOD] BaseElement:Enable
    Enables interaction.
]]
function BaseElement:Enable()
    self.Enabled = true
    -- Visual update could go here (e.g., un-fade)
    if self.Instance and self.Instance:IsA("GuiObject") then
        self:Tween({BackgroundTransparency = 0}, {Time = 0.2})
    end
end

--[[
    [METHOD] BaseElement:Disable
    Disables interaction.
]]
function BaseElement:Disable()
    self.Enabled = false
    -- Visual update could go here (e.g., fade out)
    if self.Instance and self.Instance:IsA("GuiObject") then
        self:Tween({BackgroundTransparency = 0.5}, {Time = 0.2})
    end
end

--[[
    [METHOD] BaseElement:GetTheme
    Retrieves the current active theme color/property for a specific key.
    Follows a hierarchy: Element Override -> Global Config -> Default Fallback.
    
    @param key (string) - The theme key (e.g., "Accent", "Background").
    @return (Color3/Value)
]]
function BaseElement:GetTheme(key)
    -- 1. Check local override
    if self.ThemeOverride and self.ThemeOverride[key] then
        return self.ThemeOverride[key]
    end
    
    -- 2. Check Global Config
    local globalTheme = Config.Current or Config.Default
    if globalTheme and globalTheme[key] then
        return globalTheme[key]
    end
    
    -- 3. Fallback (White)
    return Color3.fromRGB(255, 255, 255)
end

--[[
    [METHOD] BaseElement:UpdateTheme
    Virtual method. Should be implemented by subclasses to apply colors.
]]
function BaseElement:UpdateTheme()
    -- Base implementation does nothing
    -- Example for subclass:
    -- self.Instance.BackgroundColor3 = self:GetTheme("ElementBackground")
end

--[[
    [METHOD] BaseElement:Tween
    Safely tweens properties of the main Instance.
    
    @param goals (table) - The properties to tween.
    @param info (table) - TweenInfo parameters (Time, EasingStyle, etc.).
]]
function BaseElement:Tween(goals, info)
    if not self.Instance then return end
    
    info = info or {}
    local tweenInfo = TweenInfo.new(
        info.Time or 0.3,
        info.Style or Enum.EasingStyle.Quart,
        info.Direction or Enum.EasingDirection.Out,
        info.RepeatCount or 0,
        info.Reverse or false,
        info.DelayTime or 0
    )
    
    local success, tween = pcall(function()
        return TweenService:Create(self.Instance, tweenInfo, goals)
    end)
    
    if success and tween then
        tween:Play()
        return tween
    else
        -- Fallback: Instant set if tween fails (robustness)
        for prop, val in pairs(goals) do
            pcall(function() self.Instance[prop] = val end)
        end
    end
end

--[[
    [METHOD] BaseElement:Extend
    Creates a subclass inheriting from this BaseElement (or the current class).
    
    @param className (string) - Name of the new class.
    @return (table) - The new class table.
]]
function BaseElement:Extend(className)
    local newClass = {}
    for k, v in pairs(self) do
        if k:sub(1, 2) ~= "__" then
            newClass[k] = v
        end
    end
    
    newClass.__index = newClass
    newClass.__type = className or "UnknownElement"
    newClass.Super = self
    
    -- Constructor Wrapper
    function newClass.new(props)
        local instance = self.new(props) -- Call super constructor
        setmetatable(instance, newClass)
        instance.Type = className
        return instance
    end
    
    return newClass
end

--[[
    [METHOD] BaseElement:OnHoverStart
    Internal hook for hover effects. Can be overridden.
]]
function BaseElement:OnHoverStart()
    -- Default subtle hover effect
    if self.Config.DisableHover then return end
    
    -- Typically we darken or lighten the background slightly
    -- This relies on UpdateTheme logic usually, but here is a raw example:
    -- self:Tween({BackgroundColor3 = Utility.Lighten(self.Instance.BackgroundColor3, 0.1)})
end

--[[
    [METHOD] BaseElement:OnHoverEnd
    Internal hook for hover end.
]]
function BaseElement:OnHoverEnd()
    if self.Config.DisableHover then return end
    -- Reset logic would go here
end

--[[
    [METHOD] BaseElement:OnClick
    Internal hook for click effects.
]]
function BaseElement:OnClick(input)
    -- Default click ripple or scale effect
    -- self:Tween({Size = ...})
end

--[[
    [METHOD] BaseElement:Destroy
    Cleanup routine. Essential for preventing memory leaks in large UI libraries.
]]
function BaseElement:Destroy()
    if self.Disposed then return end
    self.Disposed = true
    
    -- Fire Destroy Event
    self.Events.OnDestroy:Fire()
    
    -- Destroy Children first
    for _, child in pairs(self.Children) do
        if child and child.Destroy then
            child:Destroy()
        end
    end
    self.Children = {}
    
    -- Destroy Signals
    for _, signal in pairs(self.Events) do
        if signal.Destroy then
            signal:Destroy()
        end
    end
    
    -- Destroy Roblox Instance
    if self.Instance then
        self.Instance:Destroy()
        self.Instance = nil
    end
    
    -- Cleanup References
    self.Parent = nil
    self.Config = nil
    self._storage = nil
    
    setmetatable(self, nil)
end

--[[
    [METHOD] BaseElement:SetZIndex
    Sets the ZIndex of the instance and recursively for children if needed.
]]
function BaseElement:SetZIndex(index)
    if self.Instance then
        self.Instance.ZIndex = index
    end
end

--[[
    [METHOD] BaseElement:GetAbsolutePosition
    Returns the absolute position of the element on screen.
]]
function BaseElement:GetAbsolutePosition()
    if self.Instance then
        return self.Instance.AbsolutePosition
    end
    return Vector2.new(0, 0)
end

--[[
    [METHOD] BaseElement:GetAbsoluteSize
    Returns the absolute size.
]]
function BaseElement:GetAbsoluteSize()
    if self.Instance then
        return self.Instance.AbsoluteSize
    end
    return Vector2.new(0, 0)
end

--[[
    [METHOD] BaseElement:ApplyStroke
    Helper to add a UIStroke to the element.
    
    @param config (table) - {Color, Thickness, Transparency, Mode}
]]
function BaseElement:ApplyStroke(config)
    if not self.Instance then return end
    
    local stroke = self.Instance:FindFirstChild("UIStroke")
    if not stroke then
        stroke = Instance.new("UIStroke")
        stroke.Parent = self.Instance
    end
    
    stroke.Color = config.Color or self:GetTheme("Outline") or Color3.new(1,1,1)
    stroke.Thickness = config.Thickness or 1
    stroke.Transparency = config.Transparency or 0
    stroke.ApplyStrokeMode = config.Mode or Enum.ApplyStrokeMode.Border
    
    return stroke
end

--[[
    [METHOD] BaseElement:ApplyCorner
    Helper to add a UICorner to the element.
    
    @param radius (number/UDim) - Corner radius.
]]
function BaseElement:ApplyCorner(radius)
    if not self.Instance then return end
    
    local corner = self.Instance:FindFirstChild("UICorner")
    if not corner then
        corner = Instance.new("UICorner")
        corner.Parent = self.Instance
    end
    
    if type(radius) == "number" then
        corner.CornerRadius = UDim.new(0, radius)
    else
        corner.CornerRadius = radius or UDim.new(0, 4) -- Default 4px
    end
    
    return corner
end

--[[
    [DEBUG] BaseElement:Log
    Prints debug info scoped to this element.
]]
function BaseElement:Log(msg)
    if Config.DebugMode then
        print(string.format("[%s::%s] %s", self.Type, self.Name, tostring(msg)))
    end
end

return BaseElement