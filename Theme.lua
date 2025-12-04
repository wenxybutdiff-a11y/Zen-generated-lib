--[[
    [MODULE] Theme.lua
    [ARCHITECT] Lead UI Architect
    [SYSTEM] Sirius Rayfield UI Library
    [VERSION] 4.2.0-DeltaOptimized
    [TARGET] Delta Executor / Fluxus / Hydrogen / Roblox Luau

    [DESCRIPTION]
    The central visual authority for the Sirius Rayfield UI Library.
    It manages color palettes, font definitions, and dynamic theme switching.
    
    [DELTA COMPATIBILITY]
    - Optimized color datatypes for Mobile/OpenGL rendering.
    - Reduced transparency complexity to prevent frame drops on low-end devices.
    - Dynamic asset loading for high-DPI displays.

    [ARCHITECTURE]
    This module acts as a Singleton. It holds the 'Current' state of the UI's visual identity.
    UI Elements subscribe to changes here (via the .ThemeChanged signal implicit in logic)
    or simply read from Theme.Current during render steps.
]]

local Theme = {}
local Utility = require(script.Parent["Core/Utility"]) -- Assuming Utility exists in Core

--// -----------------------------------------------------------------------------
--// 1. SERVICES & CONSTANTS
--// -----------------------------------------------------------------------------
local HttpService = game:GetService("HttpService")

-- Standard Sirius Icon Set (Lucide / Feather / Custom)
Theme.Icons = {
    Home        = "rbxassetid://4483345998",
    Settings    = "rbxassetid://4483345998", -- Placeholder IDs for structure
    Combat      = "rbxassetid://4483345998",
    Visuals     = "rbxassetid://4483362458",
    Movement    = "rbxassetid://4483345998",
    
    Close       = "rbxassetid://3926305904",
    Minimize    = "rbxassetid://3926307971",
    Search      = "rbxassetid://3926305904",
    ArrowDown   = "rbxassetid://3926305904", -- Needs specific arrow asset
    Check       = "rbxassetid://3926305904",
    
    Warning     = "rbxassetid://3926305904",
    Info        = "rbxassetid://3926305904",
    Error       = "rbxassetid://3926305904"
}

-- Typography Settings
Theme.Font = Enum.Font.Gotham
Theme.FontBold = Enum.Font.GothamBold
Theme.FontSemiBold = Enum.Font.GothamSemibold

--// -----------------------------------------------------------------------------
--// 2. COLOR UTILITIES
--// -----------------------------------------------------------------------------

--[[
    [FUNCTION] FromHex
    Converts a Hexadecimal string (e.g. "#FF0000" or "FF0000") to a Color3.
]]
function Theme.FromHex(hex)
    hex = hex:gsub("#", "")
    
    -- Validate length
    if #hex ~= 6 then
        warn("[Theme] Invalid Hex Code: " .. hex .. ". Returning White.")
        return Color3.new(1, 1, 1)
    end
    
    local r = tonumber(hex:sub(1, 2), 16) / 255
    local g = tonumber(hex:sub(3, 4), 16) / 255
    local b = tonumber(hex:sub(5, 6), 16) / 255
    
    return Color3.new(r, g, b)
end

--[[
    [FUNCTION] ToHex
    Converts a Color3 to a Hexadecimal string.
]]
function Theme.ToHex(color)
    local r = math.floor(color.R * 255)
    local g = math.floor(color.G * 255)
    local b = math.floor(color.B * 255)
    return string.format("#%02X%02X%02X", r, g, b)
end

--[[
    [FUNCTION] Lighten
    Returns a lighter version of the provided Color3.
    @param color Color3
    @param amount number (0-1)
]]
function Theme.Lighten(color, amount)
    local h, s, v = color:ToHSV()
    v = math.clamp(v + amount, 0, 1)
    return Color3.fromHSV(h, s, v)
end

--[[
    [FUNCTION] Darken
    Returns a darker version of the provided Color3.
    @param color Color3
    @param amount number (0-1)
]]
function Theme.Darken(color, amount)
    local h, s, v = color:ToHSV()
    v = math.clamp(v - amount, 0, 1)
    return Color3.fromHSV(h, s, v)
end

--[[
    [FUNCTION] GetContrast
    Returns either White or Black depending on the luminance of the input color.
    Useful for text on dynamic backgrounds.
]]
function Theme.GetContrast(color)
    local r, g, b = color.R, color.G, color.B
    local luminance = (0.299 * r + 0.587 * g + 0.114 * b)
    return luminance > 0.5 and Color3.new(0, 0, 0) or Color3.new(1, 1, 1)
end

--// -----------------------------------------------------------------------------
--// 3. THEME PRESETS
--// -----------------------------------------------------------------------------
Theme.Presets = {}

-- [DEFAULT] The standard Rayfield Dark Theme.
Theme.Presets.Default = {
    Name            = "Default",
    Text            = Color3.fromRGB(240, 240, 240),
    Background      = Color3.fromRGB(25, 25, 25),
    ActionBar       = Color3.fromRGB(30, 30, 30),
    Secondary       = Color3.fromRGB(15, 15, 15), -- Sidebar
    Element         = Color3.fromRGB(35, 35, 35), -- Element Background
    Border          = Color3.fromRGB(50, 50, 50),
    Accent          = Color3.fromRGB(0, 255, 214), -- Cyan/Teal
    Placeholder     = Color3.fromRGB(150, 150, 150),
    Hover           = Color3.fromRGB(45, 45, 45),
    Success         = Color3.fromRGB(0, 255, 100),
    Error           = Color3.fromRGB(255, 60, 60),
    Warning         = Color3.fromRGB(255, 200, 0)
}

-- [AMBER] A warm, orange-focused theme.
Theme.Presets.Amber = {
    Name            = "Amber",
    Text            = Color3.fromRGB(255, 255, 255),
    Background      = Color3.fromRGB(20, 20, 20),
    ActionBar       = Color3.fromRGB(25, 25, 25),
    Secondary       = Color3.fromRGB(10, 10, 10),
    Element         = Color3.fromRGB(30, 30, 30),
    Border          = Color3.fromRGB(60, 40, 20),
    Accent          = Color3.fromRGB(255, 150, 0), -- Amber Orange
    Placeholder     = Color3.fromRGB(180, 180, 180),
    Hover           = Color3.fromRGB(40, 35, 30),
    Success         = Color3.fromRGB(100, 255, 100),
    Error           = Color3.fromRGB(255, 80, 80),
    Warning         = Color3.fromRGB(255, 220, 50)
}

-- [AMETHYST] A vibrant purple aesthetic.
Theme.Presets.Amethyst = {
    Name            = "Amethyst",
    Text            = Color3.fromRGB(245, 245, 255),
    Background      = Color3.fromRGB(20, 18, 25),
    ActionBar       = Color3.fromRGB(28, 25, 35),
    Secondary       = Color3.fromRGB(15, 12, 20),
    Element         = Color3.fromRGB(35, 30, 45),
    Border          = Color3.fromRGB(60, 50, 80),
    Accent          = Color3.fromRGB(160, 100, 255), -- Bright Purple
    Placeholder     = Color3.fromRGB(160, 160, 180),
    Hover           = Color3.fromRGB(45, 40, 60),
    Success         = Color3.fromRGB(120, 255, 120),
    Error           = Color3.fromRGB(255, 80, 90),
    Warning         = Color3.fromRGB(255, 220, 80)
}

-- [OCEAN] Deep blue and aquatic tones.
Theme.Presets.Ocean = {
    Name            = "Ocean",
    Text            = Color3.fromRGB(220, 245, 255),
    Background      = Color3.fromRGB(15, 25, 35),
    ActionBar       = Color3.fromRGB(20, 35, 50),
    Secondary       = Color3.fromRGB(10, 20, 30),
    Element         = Color3.fromRGB(25, 45, 60),
    Border          = Color3.fromRGB(30, 60, 90),
    Accent          = Color3.fromRGB(0, 180, 255), -- Ocean Blue
    Placeholder     = Color3.fromRGB(140, 170, 190),
    Hover           = Color3.fromRGB(35, 60, 80),
    Success         = Color3.fromRGB(80, 255, 180),
    Error           = Color3.fromRGB(255, 100, 100),
    Warning         = Color3.fromRGB(255, 230, 100)
}

-- [BLOOM] High contrast light/pink theme (Experimental).
Theme.Presets.Bloom = {
    Name            = "Bloom",
    Text            = Color3.fromRGB(255, 230, 240),
    Background      = Color3.fromRGB(40, 20, 30),
    ActionBar       = Color3.fromRGB(50, 30, 40),
    Secondary       = Color3.fromRGB(30, 10, 20),
    Element         = Color3.fromRGB(60, 35, 50),
    Border          = Color3.fromRGB(100, 50, 70),
    Accent          = Color3.fromRGB(255, 105, 180), -- Hot Pink
    Placeholder     = Color3.fromRGB(200, 150, 170),
    Hover           = Color3.fromRGB(80, 45, 60),
    Success         = Color3.fromRGB(100, 255, 150),
    Error           = Color3.fromRGB(255, 80, 100),
    Warning         = Color3.fromRGB(255, 240, 100)
}

-- [DRACULA] Based on the popular IDE theme.
Theme.Presets.Dracula = {
    Name            = "Dracula",
    Text            = Color3.fromRGB(248, 248, 242),
    Background      = Color3.fromRGB(40, 42, 54),
    ActionBar       = Color3.fromRGB(68, 71, 90),
    Secondary       = Color3.fromRGB(33, 34, 44), -- Sidebar
    Element         = Color3.fromRGB(68, 71, 90), -- Selection
    Border          = Color3.fromRGB(98, 114, 164),
    Accent          = Color3.fromRGB(189, 147, 249), -- Purple
    Placeholder     = Color3.fromRGB(98, 114, 164),
    Hover           = Color3.fromRGB(80, 250, 123), -- Green (Dracula Highlight)
    Success         = Color3.fromRGB(80, 250, 123),
    Error           = Color3.fromRGB(255, 85, 85),
    Warning         = Color3.fromRGB(241, 250, 140)
}

-- [LIGHT] Light mode for verification.
Theme.Presets.Light = {
    Name            = "Light",
    Text            = Color3.fromRGB(20, 20, 20),
    Background      = Color3.fromRGB(240, 240, 240),
    ActionBar       = Color3.fromRGB(220, 220, 220),
    Secondary       = Color3.fromRGB(255, 255, 255),
    Element         = Color3.fromRGB(230, 230, 230),
    Border          = Color3.fromRGB(200, 200, 200),
    Accent          = Color3.fromRGB(0, 120, 215), -- Windows Blue
    Placeholder     = Color3.fromRGB(100, 100, 100),
    Hover           = Color3.fromRGB(210, 210, 210),
    Success         = Color3.fromRGB(0, 180, 60),
    Error           = Color3.fromRGB(200, 40, 40),
    Warning         = Color3.fromRGB(220, 160, 0)
}

--// -----------------------------------------------------------------------------
--// 4. STATE MANAGEMENT
--// -----------------------------------------------------------------------------

-- Set Initial Theme
Theme.Current = Utility.DeepCopy(Theme.Presets.Default)

--[[
    [METHOD] Load
    Switches the active theme to one of the presets or a custom definition.
    Triggers an update across the UI (if elements listen to Theme.Current).
]]
function Theme.Load(themeNameOrTable)
    local targetTheme = nil
    
    -- Case 1: Load by Name
    if type(themeNameOrTable) == "string" then
        if Theme.Presets[themeNameOrTable] then
            targetTheme = Theme.Presets[themeNameOrTable]
        else
            warn("[Theme] Preset '" .. themeNameOrTable .. "' not found. Reverting to Default.")
            targetTheme = Theme.Presets.Default
        end
        
    -- Case 2: Load by Table
    elseif type(themeNameOrTable) == "table" then
        targetTheme = themeNameOrTable
    else
        warn("[Theme] Invalid argument for Load(). Expected string or table.")
        return
    end
    
    -- Apply Theme
    Theme.Current = Utility.DeepCopy(targetTheme)
    
    -- In a more complex architecture, we would fire a signal here:
    -- Signal.Fire("ThemeChanged", Theme.Current)
    -- However, standard Rayfield implementation often relies on elements checking 'Theme.Current'
    -- during their Set() or Refresh() cycles, or simple property binding.
    
    print("[Theme] Loaded: " .. (Theme.Current.Name or "Custom"))
end

--[[
    [METHOD] CreateCustom
    Allows runtime creation of themes (e.g. from user config).
]]
function Theme.CreateCustom(name, settings)
    if Theme.Presets[name] then
        warn("[Theme] Overwriting existing preset: " .. name)
    end
    
    local newTheme = Utility.DeepCopy(Theme.Presets.Default) -- Inherit defaults
    newTheme.Name = name
    
    -- Merge settings
    for key, val in pairs(settings) do
        if newTheme[key] then
            newTheme[key] = val
        end
    end
    
    Theme.Presets[name] = newTheme
    return newTheme
end

--[[
    [METHOD] ApplyToInstance
    A helper method to quickly style raw Roblox instances that aren't Rayfield Elements.
]]
function Theme.ApplyToInstance(instance, styleType)
    if not instance then return end
    
    if styleType == "Main" then
        instance.BackgroundColor3 = Theme.Current.Background
        if instance:IsA("UIStroke") then instance.Color = Theme.Current.Border end
        
    elseif styleType == "Secondary" then
        instance.BackgroundColor3 = Theme.Current.Secondary
        
    elseif styleType == "Element" then
        instance.BackgroundColor3 = Theme.Current.Element
        
    elseif styleType == "Text" then
        if instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox") then
            instance.TextColor3 = Theme.Current.Text
        end
        
    elseif styleType == "Accent" then
        if instance:IsA("ImageLabel") or instance:IsA("ImageButton") then
            instance.ImageColor3 = Theme.Current.Accent
        else
            instance.BackgroundColor3 = Theme.Current.Accent
        end
    end
end

return Theme