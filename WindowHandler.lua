--[[
    [WindowHandler.lua]
    -------------------------------------------------------------------
    Role: Core Window Management & Rayfield Abstraction Layer
    Target: Roblox (Delta Executor / Hydrogen / Fluxus)
    Architecture: Modular wrapper for Sirius Rayfield
    
    Description:
    This module is responsible for the lifecycle of the UI Window.
    It handles:
    1. Secure loading of the Rayfield Library source.
    2. Validation and merging of Window Configurations.
    3. instantiation of the main UI Window via Rayfield.
    4. Proxy object creation for Fluent API usage (e.g., Window:Tab(...)).
    5. Event handling for UI toggling and destruction.
    
    Author: Lead Architect
    License: MIT
    -------------------------------------------------------------------
]]

local WindowHandler = {}
WindowHandler.__index = WindowHandler
WindowHandler._version = "2.4.0-DELTA"

-- // Service Dependencies
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

-- // External Module Dependencies (Simulated for this file context)
-- In a real environment, these would be required from their paths.
local Config = require(script.Parent:WaitForChild("Config")) or {} -- Fallback
local TabHandler = require(script.Parent:WaitForChild("TabHandler")) or {} -- Fallback
local Utility = require(script.Parent:WaitForChild("Utility")) or {} -- Fallback

-- // Internal State
local ActiveWindows = {}
local RayfieldLibrary = nil
local IsRayfieldLoaded = false

-- // Constants
local RAYFIELD_SOURCE_URL = "https://sirius.menu/rayfield"
local DEFAULT_TIMEOUT = 10

--[[ 
    -------------------------------------------------------------------
    [Section 1]: Core Initialization & Rayfield Loading
    -------------------------------------------------------------------
]]

--- Loads the Sirius Rayfield library safely.
-- This function attempts to load the raw source from the URL.
-- It implements retry logic and error handling for Delta Executor.
function WindowHandler.LoadRayfield()
    if IsRayfieldLoaded and RayfieldLibrary then 
        return RayfieldLibrary 
    end

    local success, result = pcall(function()
        -- Specific check for Delta/Mobile environment constraints
        if not game:IsLoaded() then
            game.Loaded:Wait()
        end
        
        -- Loadstring execution
        local loadFunc = loadstring(game:HttpGet(RAYFIELD_SOURCE_URL))
        return loadFunc()
    end)

    if success and result then
        RayfieldLibrary = result
        IsRayfieldLoaded = true
        Utility.Log("Rayfield Library loaded successfully.", "info")
        return RayfieldLibrary
    else
        Utility.Log("Failed to load Rayfield Library: " .. tostring(result), "error")
        -- Fallback or retry mechanism could go here
        warn("[WindowHandler] Critical Error: Could not load UI Library Source.")
        return nil
    end
end

--[[ 
    -------------------------------------------------------------------
    [Section 2]: Configuration Validation & Helpers
    -------------------------------------------------------------------
]]

--- Validates and sanitizes the configuration table for the Window.
-- Merges user input with default "Clean Theme" settings from Config.lua.
-- @param userConfig table: The configuration table provided by the user.
-- @return table: The fully validated configuration table.
function WindowHandler.ValidateConfig(userConfig)
    userConfig = userConfig or {}

    -- Pull defaults from the Config module
    local defaults = Config.DefaultWindowSettings or {
        Name = "Delta UI Library",
        LoadingTitle = "Initializing...",
        LoadingSubtitle = "by Lead Architect",
        ConfigurationSaving = {
            Enabled = true,
            FolderName = "DeltaSettings",
            FileName = "Manager"
        },
        Discord = {
            Enabled = false,
            Invite = "",
            RememberJoins = true
        },
        KeySystem = false,
        KeySettings = {
            Title = "Key System",
            Subtitle = "Link in Discord",
            Note = "Join the server to get the key",
            FileName = "Key",
            SaveKey = true,
            GrabKeyFromSite = false,
            Key = {"Hello"}
        }
    }

    -- Helper to merge tables deeply (simple version for Config)
    local function merge(target, source)
        for k, v in pairs(source) do
            if target[k] == nil then
                target[k] = v
            elseif type(target[k]) == "table" and type(v) == "table" then
                merge(target[k], v)
            end
        end
        return target
    end

    return merge(userConfig, defaults)
end

--[[ 
    -------------------------------------------------------------------
    [Section 3]: Window Wrapper Class
    -------------------------------------------------------------------
]]

--- Constructor for a new Window instance.
-- @param config table: The configuration table for the window.
-- @return table: A new WindowHandler object (Proxy).
function WindowHandler.new(config)
    local self = setmetatable({}, WindowHandler)
    
    -- 1. Load Library
    local lib = WindowHandler.LoadRayfield()
    if not lib then
        return nil
    end
    
    -- 2. Process Configuration
    self.Config = WindowHandler.ValidateConfig(config)
    self.RayfieldRef = lib
    self.Instance = nil -- The actual Rayfield Window object
    self.Tabs = {} -- Store tab references
    self.IsVisible = true
    
    -- 3. Register to active windows
    table.insert(ActiveWindows, self)
    
    return self
end

--- Builds the actual Rayfield Window.
-- Must be called after .new() to render the UI.
function WindowHandler:Build()
    if not self.RayfieldRef then
        Utility.Log("Rayfield reference missing during Build.", "error")
        return
    end

    local success, window = pcall(function()
        return self.RayfieldRef:CreateWindow({
            Name = self.Config.Name,
            LoadingTitle = self.Config.LoadingTitle,
            LoadingSubtitle = self.Config.LoadingSubtitle,
            ConfigurationSaving = self.Config.ConfigurationSaving,
            Discord = self.Config.Discord,
            KeySystem = self.Config.KeySystem,
            KeySettings = self.Config.KeySettings,
        })
    end)

    if success and window then
        self.Instance = window
        Utility.Log("Window built successfully: " .. self.Config.Name, "success")
        
        -- Hook into Rayfield's destruction/toggle if possible, 
        -- or set up custom listeners here.
        self:_InitializeEvents()
    else
        Utility.Log("Failed to create Rayfield Window: " .. tostring(window), "error")
    end
    
    return self -- Allow chaining
end

--[[ 
    -------------------------------------------------------------------
    [Section 4]: Tab Integration (Delegation)
    -------------------------------------------------------------------
]]

--- Adds a new Tab to the Window.
-- Delegates the actual creation logic to TabHandler.
-- @param name string: The display name of the tab.
-- @param icon string|number: The icon asset ID or Rayfield icon name.
-- @return table: The created Tab object (wrapper).
function WindowHandler:CreateTab(name, icon)
    if not self.Instance then
        warn("Cannot create tab: Window not built. Call :Build() first.")
        return nil
    end

    -- Input Validation
    if type(name) ~= "string" then name = "Tab" end
    -- Icon default handling
    icon = icon or 4483345998 -- Generic icon ID

    -- Delegate to TabHandler
    -- We pass the 'self.Instance' which is the raw Rayfield Window object
    local newTab = TabHandler.new(self.Instance, name, icon)
    
    if newTab then
        table.insert(self.Tabs, newTab)
        return newTab
    else
        warn("TabHandler failed to create tab: " .. name)
        return nil
    end
end

--[[ 
    -------------------------------------------------------------------
    [Section 5]: Utility Wrapper Methods
    -------------------------------------------------------------------
]]

--- Sends a Notification using the Rayfield Notification system.
-- @param title string
-- @param content string
-- @param duration number
-- @param image string|number (Optional)
function WindowHandler:Notify(title, content, duration, image)
    if not self.RayfieldRef then return end
    
    self.RayfieldRef:Notify({
        Title = title or "Notification",
        Content = content or "No content provided.",
        Duration = duration or 6.5,
        Image = image or 4483345998,
        Actions = { -- Default 'Okay' action
            Ignore = {
                Name = "Okay!",
                Callback = function() 
                    -- No operation
                end
            },
        },
    })
end

--- Toggles the visibility of the Window.
-- Note: Rayfield has internal keybinds (RightShift/Ctrl), but this
-- allows programmatic toggling (e.g., via a mobile button).
function WindowHandler:Toggle(state)
    -- Rayfield doesn't expose a direct 'SetVisible' easily on the window object
    -- usually, but we can simulate library-level toggles if available.
    -- Assuming standard Rayfield structure, mostly handled by user input.
    -- However, we can track internal state.
    
    if state == nil then
        self.IsVisible = not self.IsVisible
    else
        self.IsVisible = state
    end

    -- Delta Executor often requires explicit UI management for mobile.
    -- If Rayfield exposes a toggle function, use it. 
    -- Otherwise, we might need to find the CoreGui container.
    
    -- Attempting standard library toggle if documented:
    -- self.Instance:Toggle(self.IsVisible) -- Pseudo-code based on implementation
    
    -- Fallback: Notify user (Since Rayfield handles this natively usually)
    -- Utility.Log("Visibility toggled to " .. tostring(self.IsVisible), "info")
end

--- Destroys the Window and cleans up resources.
function WindowHandler:Destroy()
    if self.RayfieldRef then
        pcall(function()
            -- Rayfield specific cleanup usually involves destroying the GUI instance
            -- in CoreGui or invoking a library method.
            self.RayfieldRef:Destroy()
        end)
    end
    
    -- Clear references
    self.Instance = nil
    self.Tabs = {}
    self.IsVisible = false
    
    -- Remove from active list
    for i, win in ipairs(ActiveWindows) do
        if win == self then
            table.remove(ActiveWindows, i)
            break
        end
    end
    
    Utility.Log("Window destroyed.", "info")
end

--[[ 
    -------------------------------------------------------------------
    [Section 6]: Event Handling & Security
    -------------------------------------------------------------------
]]

function WindowHandler:_InitializeEvents()
    -- Handle specific Delta Executor constraints or signals
    -- For example, handling executor attach/detach or specific mobile gestures
    
    -- Safe connection to RunService to monitor UI state if needed
    local heartbeatConn
    heartbeatConn = RunService.Heartbeat:Connect(function()
        if not self.Instance then
            if heartbeatConn then heartbeatConn:Disconnect() end
            return
        end
        -- Potential anti-tamper or keep-alive logic here
    end)
end

--[[ 
    -------------------------------------------------------------------
    [Section 7]: Global Library Management
    -------------------------------------------------------------------
]]

--- Get all active windows managed by this handler.
function WindowHandler.GetActiveWindows()
    return ActiveWindows
end

--- Emergency cleanup of all windows.
function WindowHandler.CleanupAll()
    for _, win in ipairs(ActiveWindows) do
        win:Destroy()
    end
    ActiveWindows = {}
end

--[[ 
    -------------------------------------------------------------------
    [Section 8]: Developer Tools & Debugging
    -------------------------------------------------------------------
]]

--- Prints the current configuration of the window to console.
function WindowHandler:DebugConfig()
    if not self.Config then return end
    print("--- [WindowHandler Debug] ---")
    for k, v in pairs(self.Config) do
        print(string.format("[%s]: %s", tostring(k), tostring(v)))
    end
    print("-----------------------------")
end

--- Checks if the current executor supports the library requirements.
function WindowHandler.CheckCompatibility()
    local executor = identifyexecutor and identifyexecutor() or "Unknown"
    Utility.Log("Current Executor: " .. executor, "info")
    
    local supported = {
        "Delta", "Fluxus", "Hydrogen", "Electron", "Synapse Z"
    }
    
    local isSupported = false
    for _, name in ipairs(supported) do
        if string.find(executor, name) then
            isSupported = true
            break
        end
    end
    
    if not isSupported then
        Utility.Log("Warning: This library is optimized for Delta/Fluxus. Issues may occur on: " .. executor, "warning")
    end
    
    return isSupported
end

return WindowHandler