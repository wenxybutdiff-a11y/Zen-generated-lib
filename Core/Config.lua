--[[
    [MODULE] Core/Config.lua
    [ARCHITECT] Lead UI Architect
    [LIBRARY] Sirius Rayfield V2 (Delta Optimized)
    [DESCRIPTION]
        The Central Nervous System of the Sirius Rayfield UI Library.
        This module defines the visual identity, behavior constants, and 
        global configuration state for the interface.
        
        It includes:
        - Comprehensive Theme Repository (Amber, Amethyst, Ocean, etc.)
        - Asset Registry (Icons, Decals)
        - Layout & Typography Definitions
        - Animation Timing & TweenInfo
        - Delta Executor Compatibility Flags

    [DEPENDENCIES]
        - None (Stand-alone configuration module)
        
    [VERSION] 2.5.0-Production
    [LAST UPDATED] 2023-10-27
]]

local Config = {}
Config.__index = Config

--// -----------------------------------------------------------------------------
--// 1. SYSTEM METADATA & FLAGS
--// -----------------------------------------------------------------------------

Config.Metadata = {
    Name = "Sirius Rayfield",
    Version = "2.5.0",
    BuildType = "Release",
    Author = "Lead Architect",
    License = "MIT",
    TargetExecutor = "Delta" -- Optimized for Delta/Fluxus/Hydrogen
}

Config.Flags = {
    DebugMode = false,             -- Enables verbose logging
    UseCustomAssets = true,        -- Loads assets from rbxassetid://
    SafeMode = true,               -- Reduces complex animations for low-end devices
    InputDebounce = 0.05,          -- Seconds between input processing
    DragSpeed = 0.08,              -- Smoothing factor for window dragging
    TooltipDelay = 0.5,            -- Time before tooltip appears
    SaveConfigParams = true,       -- Auto-save window position/size
}

--// -----------------------------------------------------------------------------
--// 2. LAYOUT & DIMENSIONS
--// -----------------------------------------------------------------------------

-- precise pixel measurements for UI construction
Config.Layout = {
    Window = {
        DefaultSize = UDim2.new(0, 550, 0, 350),
        MinimizedSize = UDim2.new(0, 550, 0, 40),
        CornerRadius = UDim.new(0, 8),
        StrokeThickness = 1,
        ShadowTransparency = 0.4,
        ShadowSize = 25,
    },
    
    Header = {
        Height = 45,
        TitlePadding = UDim2.new(0, 15, 0, 0),
        IconSize = UDim2.new(0, 20, 0, 20),
        ButtonSize = UDim2.new(0, 24, 0, 24),
    },
    
    TabSystem = {
        ContainerWidth = 140, -- Width of the sidebar (if Vertical)
        ButtonHeight = 32,
        ButtonPadding = 4,
        IndicatorWidth = 3,   -- The glowing line next to active tab
    },
    
    Section = {
        HeaderHeight = 24,
        Padding = 10,         -- Padding inside the section container
        Spacing = 8,          -- Spacing between elements in a section
    },
    
    Element = {
        DefaultHeight = 36,
        CornerRadius = UDim.new(0, 6),
        TextPadding = UDim2.new(0, 10, 0, 0),
        IconPadding = UDim2.new(0, 8, 0, 0),
    }
}

--// -----------------------------------------------------------------------------
--// 3. TYPOGRAPHY
--// -----------------------------------------------------------------------------

Config.Typography = {
    Fonts = {
        Primary = Enum.Font.Gotham,
        Secondary = Enum.Font.GothamMedium,
        Bold = Enum.Font.GothamBold,
        Code = Enum.Font.Code,
    },
    
    Sizes = {
        WindowTitle = 18,
        TabTitle = 14,
        SectionTitle = 12,
        ElementTitle = 14,
        ElementDesc = 12,
        InputText = 14,
        NotificationTitle = 16,
        NotificationDesc = 14
    }
}

--// -----------------------------------------------------------------------------
--// 4. ASSET REGISTRY
--// -----------------------------------------------------------------------------

-- Common Lucide/Material icons uploaded to Roblox
Config.Icons = {
    General = {
        Home = "rbxassetid://3926305904",
        Settings = "rbxassetid://3926307971",
        Search = "rbxassetid://3926305904",
        Info = "rbxassetid://3926305904",
        Close = "rbxassetid://3926305904", -- Replace with actual IDs in prod
        Minimize = "rbxassetid://3926305904",
        Maximize = "rbxassetid://3926305904",
        User = "rbxassetid://3926305904",
    },
    
    Elements = {
        ToggleOn = "rbxassetid://3926309567",
        ToggleOff = "rbxassetid://3926309567",
        DropdownArrow = "rbxassetid://3926305904",
        Checkmark = "rbxassetid://3926305904",
        Copy = "rbxassetid://3926305904",
    },
    
    Notifications = {
        Info = "rbxassetid://3944703587",
        Warning = "rbxassetid://3944703587",
        Error = "rbxassetid://3944703587",
        Success = "rbxassetid://3944703587",
    }
}

--// -----------------------------------------------------------------------------
--// 5. ANIMATION SETTINGS
--// -----------------------------------------------------------------------------

Config.Animations = {
    Default = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
    Fast = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Slow = TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    Spring = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    
    -- Specific interaction timings
    Hover = 0.2,
    Click = 0.1,
    TabSwitch = 0.3,
    WindowOpen = 0.6,
    Ripple = 0.4
}

--// -----------------------------------------------------------------------------
--// 6. THEME REPOSITORY
--// -----------------------------------------------------------------------------

-- The library supports a comprehensive theme system.
-- Each theme defines colors for every aspect of the UI.
Config.Themes = {}

-- 6.1 Default Dark Theme (Sirius Standard)
Config.Themes.Default = {
    Name = "Default",
    Colors = {
        WindowBackground = Color3.fromRGB(32, 32, 32),
        WindowStroke = Color3.fromRGB(60, 60, 60),
        
        SidebarBackground = Color3.fromRGB(25, 25, 25),
        SidebarStroke = Color3.fromRGB(50, 50, 50),
        
        TextColor = Color3.fromRGB(240, 240, 240),
        TextSubColor = Color3.fromRGB(170, 170, 170),
        TextDisabled = Color3.fromRGB(100, 100, 100),
        
        Accent = Color3.fromRGB(0, 170, 255),  -- Standard Blue
        AccentText = Color3.fromRGB(255, 255, 255),
        
        ElementBackground = Color3.fromRGB(40, 40, 40),
        ElementHover = Color3.fromRGB(50, 50, 50),
        ElementStroke = Color3.fromRGB(70, 70, 70),
        
        InputBackground = Color3.fromRGB(20, 20, 20),
        InputFocused = Color3.fromRGB(0, 170, 255),
        
        Success = Color3.fromRGB(0, 200, 100),
        Warning = Color3.fromRGB(255, 180, 50),
        Error = Color3.fromRGB(220, 50, 50),
    }
}

-- 6.2 Light Theme (Clean)
Config.Themes.Light = {
    Name = "Light",
    Colors = {
        WindowBackground = Color3.fromRGB(245, 245, 245),
        WindowStroke = Color3.fromRGB(200, 200, 200),
        
        SidebarBackground = Color3.fromRGB(235, 235, 235),
        SidebarStroke = Color3.fromRGB(210, 210, 210),
        
        TextColor = Color3.fromRGB(30, 30, 30),
        TextSubColor = Color3.fromRGB(80, 80, 80),
        TextDisabled = Color3.fromRGB(150, 150, 150),
        
        Accent = Color3.fromRGB(45, 125, 240),
        AccentText = Color3.fromRGB(255, 255, 255),
        
        ElementBackground = Color3.fromRGB(255, 255, 255),
        ElementHover = Color3.fromRGB(240, 240, 240),
        ElementStroke = Color3.fromRGB(200, 200, 200),
        
        InputBackground = Color3.fromRGB(230, 230, 230),
        InputFocused = Color3.fromRGB(45, 125, 240),
        
        Success = Color3.fromRGB(40, 180, 80),
        Warning = Color3.fromRGB(230, 160, 40),
        Error = Color3.fromRGB(200, 60, 60),
    }
}

-- 6.3 Amber Theme (Warm)
Config.Themes.Amber = {
    Name = "Amber",
    Colors = {
        WindowBackground = Color3.fromRGB(35, 30, 30),
        WindowStroke = Color3.fromRGB(70, 60, 40),
        
        SidebarBackground = Color3.fromRGB(30, 25, 25),
        SidebarStroke = Color3.fromRGB(60, 50, 35),
        
        TextColor = Color3.fromRGB(250, 240, 230),
        TextSubColor = Color3.fromRGB(180, 170, 160),
        TextDisabled = Color3.fromRGB(100, 90, 80),
        
        Accent = Color3.fromRGB(255, 160, 0), -- Amber
        AccentText = Color3.fromRGB(20, 20, 20),
        
        ElementBackground = Color3.fromRGB(45, 40, 35),
        ElementHover = Color3.fromRGB(55, 50, 45),
        ElementStroke = Color3.fromRGB(80, 70, 50),
        
        InputBackground = Color3.fromRGB(25, 20, 15),
        InputFocused = Color3.fromRGB(255, 160, 0),
        
        Success = Color3.fromRGB(100, 200, 100),
        Warning = Color3.fromRGB(255, 200, 0),
        Error = Color3.fromRGB(200, 80, 80),
    }
}

-- 6.4 Amethyst Theme (Purple)
Config.Themes.Amethyst = {
    Name = "Amethyst",
    Colors = {
        WindowBackground = Color3.fromRGB(28, 24, 32),
        WindowStroke = Color3.fromRGB(60, 50, 70),
        
        SidebarBackground = Color3.fromRGB(22, 18, 26),
        SidebarStroke = Color3.fromRGB(50, 40, 60),
        
        TextColor = Color3.fromRGB(240, 235, 245),
        TextSubColor = Color3.fromRGB(160, 150, 170),
        TextDisabled = Color3.fromRGB(90, 80, 100),
        
        Accent = Color3.fromRGB(160, 100, 220), -- Purple
        AccentText = Color3.fromRGB(255, 255, 255),
        
        ElementBackground = Color3.fromRGB(38, 32, 44),
        ElementHover = Color3.fromRGB(48, 40, 56),
        ElementStroke = Color3.fromRGB(70, 60, 80),
        
        InputBackground = Color3.fromRGB(18, 14, 22),
        InputFocused = Color3.fromRGB(160, 100, 220),
        
        Success = Color3.fromRGB(100, 200, 140),
        Warning = Color3.fromRGB(220, 180, 80),
        Error = Color3.fromRGB(220, 80, 100),
    }
}

-- 6.5 Ocean Theme (Teal/Cyan)
Config.Themes.Ocean = {
    Name = "Ocean",
    Colors = {
        WindowBackground = Color3.fromRGB(24, 30, 36),
        WindowStroke = Color3.fromRGB(40, 60, 70),
        
        SidebarBackground = Color3.fromRGB(18, 24, 30),
        SidebarStroke = Color3.fromRGB(30, 50, 60),
        
        TextColor = Color3.fromRGB(230, 245, 255),
        TextSubColor = Color3.fromRGB(150, 170, 180),
        TextDisabled = Color3.fromRGB(80, 100, 110),
        
        Accent = Color3.fromRGB(0, 190, 200), -- Cyan
        AccentText = Color3.fromRGB(10, 30, 40),
        
        ElementBackground = Color3.fromRGB(32, 42, 50),
        ElementHover = Color3.fromRGB(40, 52, 62),
        ElementStroke = Color3.fromRGB(50, 75, 85),
        
        InputBackground = Color3.fromRGB(14, 20, 24),
        InputFocused = Color3.fromRGB(0, 190, 200),
        
        Success = Color3.fromRGB(80, 220, 150),
        Warning = Color3.fromRGB(230, 200, 60),
        Error = Color3.fromRGB(220, 80, 80),
    }
}

-- 6.6 Delta Special (High Contrast for Executors)
Config.Themes.Delta = {
    Name = "Delta",
    Colors = {
        WindowBackground = Color3.fromRGB(10, 10, 10), -- Very dark
        WindowStroke = Color3.fromRGB(255, 50, 50), -- Red outline
        
        SidebarBackground = Color3.fromRGB(15, 15, 15),
        SidebarStroke = Color3.fromRGB(40, 40, 40),
        
        TextColor = Color3.fromRGB(255, 255, 255),
        TextSubColor = Color3.fromRGB(200, 200, 200),
        TextDisabled = Color3.fromRGB(100, 100, 100),
        
        Accent = Color3.fromRGB(220, 20, 60), -- Crimson
        AccentText = Color3.fromRGB(255, 255, 255),
        
        ElementBackground = Color3.fromRGB(25, 25, 25),
        ElementHover = Color3.fromRGB(40, 40, 40),
        ElementStroke = Color3.fromRGB(80, 80, 80),
        
        InputBackground = Color3.fromRGB(5, 5, 5),
        InputFocused = Color3.fromRGB(255, 50, 50),
        
        Success = Color3.fromRGB(50, 255, 50),
        Warning = Color3.fromRGB(255, 255, 0),
        Error = Color3.fromRGB(255, 0, 0),
    }
}

--// -----------------------------------------------------------------------------
--// 7. KEYBIND CONFIGURATION
--// -----------------------------------------------------------------------------

Config.Keybinds = {
    ToggleUI = Enum.KeyCode.RightControl,
    CloseUI = Enum.KeyCode.Delete, -- Fail-safe close
    SearchFocus = Enum.KeyCode.F, -- While Ctrl is held
}

--// -----------------------------------------------------------------------------
--// 8. LOGIC & HELPER FUNCTIONS
--// -----------------------------------------------------------------------------

--[[
    Function: Config:GetTheme
    Description: Retrieves a theme table by name, defaulting to "Default" if not found.
    Params: 
        themeName (string) - The name of the theme to retrieve
    Returns:
        Table - The theme configuration table
]]
function Config:GetTheme(themeName)
    if not themeName then return Config.Themes.Default end
    
    local target = Config.Themes[themeName]
    if target then
        return target
    else
        warn("[Config] Theme '" .. tostring(themeName) .. "' not found. Reverting to Default.")
        return Config.Themes.Default
    end
end

--[[
    Function: Config:Validate
    Description: Ensures a user-provided configuration table has all necessary fields.
    Params:
        userConfig (table) - The raw configuration passed by the user
    Returns:
        Table - The sanitized configuration
]]
function Config:Validate(userConfig)
    userConfig = userConfig or {}
    
    local sanitized = {
        Name = userConfig.Name or "Rayfield UI",
        LoadingTitle = userConfig.LoadingTitle or "Loading...",
        LoadingSubtitle = userConfig.LoadingSubtitle or "by Sirius",
        ConfigurationSaving = userConfig.ConfigurationSaving or {
            Enabled = true,
            FolderName = nil, -- Uses game ID if nil
            FileName = "BigHub"
        },
        Discord = userConfig.Discord or {
            Enabled = false,
            Invite = "",
            RememberJoins = true
        },
        KeySystem = userConfig.KeySystem or false, -- Delta users prefer no key system usually
        KeySettings = userConfig.KeySettings or {
            Title = "Key System",
            Subtitle = "Link in Discord",
            Note = "Join the discord",
            FileName = "Key",
            SaveKey = true,
            GrabKeyFromSite = false,
            Key = {"Hello"}
        }
    }

    -- Theme Resolution
    if userConfig.Theme then
        if type(userConfig.Theme) == "string" then
            sanitized.Theme = Config:GetTheme(userConfig.Theme)
        elseif type(userConfig.Theme) == "table" then
            -- Custom theme table passed directly
            sanitized.Theme = userConfig.Theme
            -- Validate critical colors exist, else fill from Default
            local defaultColors = Config.Themes.Default.Colors
            for key, val in pairs(defaultColors) do
                if not sanitized.Theme[key] then
                    sanitized.Theme[key] = val
                end
            end
        end
    else
        sanitized.Theme = Config.Themes.Default
    end

    return sanitized
end

--[[
    Function: Config:ApplyFlags
    Description: Applies compatibility flags based on the executor environment.
    Params:
        executorName (string) - The name of the executor (e.g. "Delta")
]]
function Config:ApplyFlags(executorName)
    executorName = executorName and executorName:lower() or "unknown"
    
    if executorName:find("delta") then
        Config.Metadata.TargetExecutor = "Delta"
        Config.Flags.SafeMode = true -- Delta sometimes struggles with complex rendering
        Config.Animations.Default = TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
        
    elseif executorName:find("fluxus") then
        Config.Metadata.TargetExecutor = "Fluxus"
        Config.Flags.SafeMode = false -- Fluxus handles more
        
    elseif executorName:find("hydrogen") then
        Config.Metadata.TargetExecutor = "Hydrogen"
        
    else
        -- Standard Roblox or Unknown
        Config.Flags.SafeMode = true
    end
end

return Config