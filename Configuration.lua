--[[
    [MODULE] Configuration.lua
    [ARCHITECT] Lead UI Architect
    [SYSTEM] Sirius Rayfield Configuration Matrix
    [VERSION] 2.4.0-Stable
    [TARGET] Delta Executor / Fluxus / Hydrogen / Roblox Luau

    [DESCRIPTION]
        This module serves as the central nervous system for the UI Library's configuration.
        It defines the initial state, window properties, security settings, and aesthetic 
        presets for the Sirius Rayfield instance.
        
        It is designed to be 100% compatible with Delta Executor, utilizing
        specific flags to ensure stability on mobile and PC exploits.

    [USAGE]
        local Configuration = require(path.to.Configuration)
        local WindowSettings = Configuration.Window
        local CurrentTheme = Configuration.Themes.Amethyst
]]

local Configuration = {}

--// -----------------------------------------------------------------------------
--// 1. METADATA & BUILD INFO
--// -----------------------------------------------------------------------------
Configuration.Metadata = {
    Name = "Solaris UI Library",
    Build = "2405.11-Delta",
    Author = "Lead Architect",
    License = "MIT",
    DebugMode = true, -- Enables verbose logging in console
}

--// -----------------------------------------------------------------------------
--// 2. EXECUTOR COMPATIBILITY FLAGS
--// -----------------------------------------------------------------------------
-- Specific settings to handle the quirks of different executors (Delta, Fluxus, etc.)
Configuration.Compatibility = {
    -- Delta Executor often requires specific yielding for UI to render correctly on Android
    YieldOnLoad = true,
    YieldTime = 1.5,
    
    -- Safe Mode prevents the use of unsafe functions like gethui() if not supported
    SafeMode = true,
    
    -- Auto-detect if running on Mobile to adjust UI scaling
    AutoDetectMobile = true,
    
    -- If true, forces the UI to reside in CoreGui (requires Lvl 8). 
    -- If false, falls back to PlayerGui (safer for lower levels).
    ForceCoreGui = true,
}

--// -----------------------------------------------------------------------------
--// 3. MAIN WINDOW SETTINGS
--// -----------------------------------------------------------------------------
-- These settings are passed directly into Rayfield:CreateWindow()
Configuration.Window = {
    Name = "Solaris Hub | Delta Edition",
    LoadingTitle = "Initializing Solaris...",
    LoadingSubtitle = "by Lead Architect",
    
    -- Configuration Saving
    -- Allows Rayfield to automatically save and load flags
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "SolarisSettings",
        FileName = "MainConfiguration"
    },
    
    -- Discord Integration
    Discord = {
        Enabled = false,
        Invite = "solarishub", -- Discord invite code
        RememberJoins = true 
    },
    
    -- Key System (Security)
    KeySystem = false, -- Set to true to enable
    KeySettings = {
        Title = "Solaris | Key System",
        Subtitle = "Link in Discord",
        Note = "Join the Discord to get your key.",
        FileName = "SolarisKey",
        SaveKey = true,
        GrabKeyFromSite = false, -- If true, uses Key as a URL
        Key = { "Hello" } -- List of valid keys
    }
}

--// -----------------------------------------------------------------------------
--// 4. GLOBAL UI SETTINGS
--// -----------------------------------------------------------------------------
Configuration.Settings = {
    -- The default toggle key for the UI
    UIDefaultKeybind = Enum.KeyCode.RightControl,
    
    -- Notification Settings
    Notifications = {
        Enabled = true,
        Duration = 5, -- Default duration in seconds
        Sound = true, -- Play sound on notification
    },
    
    -- Animation Speeds (TweenInfo params)
    Animations = {
        HoverTime = 0.3,
        ClickTime = 0.1,
        WindowOpenTime = 0.5,
        EasingStyle = Enum.EasingStyle.Quint,
        EasingDirection = Enum.EasingDirection.Out
    }
}

--// -----------------------------------------------------------------------------
--// 5. THEME DEFINITIONS
--// -----------------------------------------------------------------------------
-- Pre-configured themes to ensure a "clean" look.
-- Rayfield expects: TextColor, Background, ActionBar, Main, Element, Secondary, Accent, Interact
Configuration.Themes = {
    -- The default "Solaris Clean" theme (Dark Blue/Grey)
    Default = {
        TextColor = Color3.fromRGB(240, 240, 240),
        Background = Color3.fromRGB(25, 25, 35),
        ActionBar = Color3.fromRGB(30, 30, 45),
        Main = Color3.fromRGB(25, 25, 35),
        Element = Color3.fromRGB(35, 35, 50),
        Secondary = Color3.fromRGB(25, 25, 35),
        Accent = Color3.fromRGB(0, 255, 214), -- Cyan/Teal
        Interact = Color3.fromRGB(45, 45, 60)
    },
    
    -- High Contrast "Amber" Theme
    Amber = {
        TextColor = Color3.fromRGB(255, 255, 255),
        Background = Color3.fromRGB(20, 20, 20),
        ActionBar = Color3.fromRGB(40, 40, 40),
        Main = Color3.fromRGB(20, 20, 20),
        Element = Color3.fromRGB(30, 30, 30),
        Secondary = Color3.fromRGB(25, 25, 25),
        Accent = Color3.fromRGB(255, 170, 0), -- Amber/Gold
        Interact = Color3.fromRGB(50, 50, 50)
    },
    
    -- Soft "Amethyst" Theme
    Amethyst = {
        TextColor = Color3.fromRGB(245, 245, 255),
        Background = Color3.fromRGB(30, 25, 35),
        ActionBar = Color3.fromRGB(45, 35, 55),
        Main = Color3.fromRGB(30, 25, 35),
        Element = Color3.fromRGB(45, 40, 60),
        Secondary = Color3.fromRGB(30, 25, 35),
        Accent = Color3.fromRGB(180, 100, 255), -- Purple
        Interact = Color3.fromRGB(60, 50, 80)
    },
    
    -- "Midnight" Theme (Ultra Dark)
    Midnight = {
        TextColor = Color3.fromRGB(180, 180, 180),
        Background = Color3.fromRGB(10, 10, 12),
        ActionBar = Color3.fromRGB(15, 15, 18),
        Main = Color3.fromRGB(10, 10, 12),
        Element = Color3.fromRGB(20, 20, 24),
        Secondary = Color3.fromRGB(10, 10, 12),
        Accent = Color3.fromRGB(60, 100, 200), -- Muted Blue
        Interact = Color3.fromRGB(30, 30, 40)
    }
}

-- Select the active theme here
Configuration.ActiveTheme = Configuration.Themes.Default

--// -----------------------------------------------------------------------------
--// 6. ASSET LIBRARY (ICONS)
--// -----------------------------------------------------------------------------
-- A centralized repository of icons (Lucide / Phosphor) via rbxassetid.
-- This allows UIElements.lua to reference icons by name (e.g., "Home", "Combat").
Configuration.Icons = {
    -- General
    Home        = "rbxassetid://4483345998",
    Settings    = "rbxassetid://4483345998", -- Placeholder, replace with actual ID
    User        = "rbxassetid://4483345998",
    Info        = "rbxassetid://4483345998",
    
    -- Combat / Weapons
    Sword       = "rbxassetid://4483345998",
    Target      = "rbxassetid://4483345998",
    Shield      = "rbxassetid://4483345998",
    
    -- Visuals
    Eye         = "rbxassetid://4483345998",
    Paint       = "rbxassetid://4483345998",
    
    -- Misc
    Script      = "rbxassetid://4483345998",
    Cloud       = "rbxassetid://4483345998",
    Warning     = "rbxassetid://4483345998",
}

--// -----------------------------------------------------------------------------
--// 7. UTILITY METHODS
--// -----------------------------------------------------------------------------
-- Helper functions attached to the Configuration table for runtime checks.

--[ CheckExecutor ]
-- Verifies if the current environment matches the target compatibility settings.
function Configuration:CheckExecutor()
    local executorName = (identifyexecutor and identifyexecutor()) or "Unknown"
    
    if self.Metadata.DebugMode then
        print("[Solaris Config] Detected Executor:", executorName)
    end
    
    -- Specific Delta Handling
    if string.find(executorName, "Delta") then
        self.Compatibility.YieldOnLoad = true
        self.Compatibility.SafeMode = false -- Delta usually supports full API
    end
    
    return executorName
end

--[ GetTheme ]
-- Safely retrieves a theme table. Falls back to Default if the requested name is missing.
function Configuration:GetTheme(themeName)
    local target = self.Themes[themeName]
    if not target then
        warn("[Solaris Config] Theme '" .. tostring(themeName) .. "' not found. Reverting to Default.")
        return self.Themes.Default
    end
    return target
end

--[ GetIcon ]
-- Safely retrieves an icon ID.
function Configuration:GetIcon(iconName)
    return self.Icons[iconName] or "rbxassetid://4483345998" -- Fallback icon
end

--[ Validate ]
-- Validates the integrity of the Configuration table before startup.
-- This ensures critical fields (like Window Name) are present.
function Configuration:Validate()
    local log = {}
    local valid = true
    
    if not self.Window.Name or self.Window.Name == "" then
        table.insert(log, "[Error] Window Name is missing.")
        valid = false
    end
    
    if not self.ActiveTheme or not self.ActiveTheme.Accent then
        table.insert(log, "[Error] Active Theme is invalid or missing Accent color.")
        valid = false
    end
    
    if valid then
        table.insert(log, "[Success] Configuration validated.")
    end
    
    return valid, log
end

--[ ApplyOverrides ]
-- Applies overrides from a saved config file (if loaded externally).
function Configuration:ApplyOverrides(savedSettings)
    if type(savedSettings) ~= "table" then return end
    
    for key, value in pairs(savedSettings) do
        if self.Settings[key] ~= nil then
            self.Settings[key] = value
        elseif self.Window[key] ~= nil then
            self.Window[key] = value
        end
    end
end

--// -----------------------------------------------------------------------------
--// 8. ELEMENT DEFAULTS
--// -----------------------------------------------------------------------------
-- Default configurations for individual UI elements to ensure consistency.
Configuration.ElementDefaults = {
    Toggle = {
        Default = false,
    },
    Slider = {
        Min = 0,
        Max = 100,
        Default = 50,
        Increment = 1,
        Suffix = ""
    },
    Dropdown = {
        Options = {"Option 1", "Option 2"},
        Default = "Option 1",
        Flag = "DropdownFlag"
    },
    ColorPicker = {
        Default = Color3.fromRGB(255, 255, 255)
    }
}

--// -----------------------------------------------------------------------------
--// 9. STRING CONSTANTS & TEXT
--// -----------------------------------------------------------------------------
-- Centralized strings for localization or easy updates.
Configuration.Strings = {
    KeySystem = {
        Success = "Key Validated. Loading Solaris...",
        Failure = "Invalid Key. Please try again.",
        CopyLink = "Link Copied to Clipboard!"
    },
    Errors = {
        Generic = "An error occurred.",
        ScriptMissing = "Script logic missing for this element."
    }
}

--// -----------------------------------------------------------------------------
--// 10. DEBUGGING & LOGGING WRAPPERS
--// -----------------------------------------------------------------------------
function Configuration:Log(msg)
    if self.Metadata.DebugMode then
        print("[Solaris::Config] " .. tostring(msg))
    end
end

-- Initialize check on require
Configuration:CheckExecutor()

return Configuration