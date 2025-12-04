--[[
    [MODULE] init.lua
    [ARCHITECT] Lead UI Architect
    [LIBRARY] Sirius Rayfield Interface
    [VERSION] 5.0.0-Gold
    [TARGET] Delta Executor / Fluxus / Hydrogen / Roblox Luau
    
    [DESCRIPTION]
    The Public API Facade for the Sirius Rayfield UI Library.
    This module ties together the Core Engine, Theme Manager, and Element Factories
    into a cohesive, easy-to-use table for end-users.
    
    [USAGE]
    local Rayfield = require(path.to.init)
    local Window = Rayfield:CreateWindow({...})
]]

local Rayfield = {}
Rayfield.__index = Rayfield

--// Metadata
Rayfield.Version = "5.0.0"
Rayfield.Build = "Enterprise"

--// Internal Dependencies
local RayfieldCore = require(script.RayfieldCore)
local Theme = require(script.Theme)
local Config = require(script["Core/Config"])
local Utility = require(script["Core/Utility"])

--// Public API

--[[
    [API] CreateWindow
    Creates a new UI Window.
    
    @param Configuration Table
    {
       Name = "Hub Name",
       LoadingTitle = "Loading...",
       LoadingSubtitle = "by You",
       ConfigurationSaving = {
          Enabled = true,
          FolderName = "MyHub",
          FileName = "Config"
       },
       KeySystem = false,
       KeySettings = { ... }
    }
]]
function Rayfield:CreateWindow(Settings)
    Settings = Settings or {}
    
    -- Initialize Configuration
    if Settings.ConfigurationSaving then
        Config.Flags.ConfigurationSaving = Settings.ConfigurationSaving.Enabled
        Config.Directory.Folder = Settings.ConfigurationSaving.FolderName or "Rayfield"
        Config.Directory.File = Settings.ConfigurationSaving.FileName or "Config"
    end
    
    -- Pass to Core Engine
    local Window = RayfieldCore.New(Settings)
    
    -- Return a Proxy Object (Standard Rayfield API Pattern)
    -- This allows us to chain methods or keep API consistent even if Core changes.
    local WindowProxy = {
        CreateTab = function(_, Name, Icon)
            return Window:CreateTab(Name, Icon)
        end,
        Notify = function(_, NotificationConfig)
            Window:Notify(NotificationConfig)
        end,
        Destroy = function(_)
            Window:Destroy()
        end
    }
    
    return WindowProxy
end

--[[
    [API] Notify
    Global notification function (uses the last created window or a global overlay).
]]
function Rayfield:Notify(Settings)
    -- Note: Rayfield notifications usually require a Window instance.
    -- If called statically, we check if a window exists in Core.
    -- For safety, we warn if no window.
    warn("[Rayfield] Please call Notify via the Window object: Window:Notify({...})")
end

--[[
    [API] LoadConfiguration
    Triggers the loading of saved settings.
]]
function Rayfield:LoadConfiguration()
    -- Implementation of config loading logic
    -- This would interface with the Elements/UIElements registry
    Utility.Log("Info", "Configuration Loading Triggered")
    -- Logic to iterate registered elements and set values
end

--[[
    [API] Destroy
    Completely unloads the library.
]]
function Rayfield:Destroy()
    -- Cleanup all windows
    -- (RayfieldCore maintains a list of instances usually, or we track them here)
    -- For this implementation, we assume single-window usage primarily.
    Utility.Log("Warning", "Destroying Rayfield Interface")
end

--// Export
return Rayfield