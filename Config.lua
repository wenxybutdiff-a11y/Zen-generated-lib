--[[
    [MODULE] Config.lua
    [ARCHITECT] Lead UI Architect
    [SYSTEM] Solaris Hub Configuration Core
    [VERSION] 3.2.0-Clean
    
    [DESCRIPTION]
        Defines the visual identity of the 'Solaris Clean' theme.
        This file serves as the centralized source of truth for all colors, 
        animations, and asset references used by the ThemeManager.
]]

local Config = {}

--// SYSTEM METADATA
Config.Metadata = {
    Name = "SolarisHub_Config",
    Version = "3.2.0",
    Build = "Release_Clean",
    LastUpdated = os.time()
}

--// THEME DEFINITIONS
-- "Solaris Clean" is a dark, high-contrast theme with neon accents and glass-like transparency.
Config.Themes = {
    Solaris_Clean = {
        -- Main Container
        WindowBackground = Color3.fromRGB(12, 12, 16),
        WindowTransparency = 0.1, -- Slight see-through for glass effect
        
        -- Headers & Navigation
        ActionBar = Color3.fromRGB(18, 18, 24),
        TabContainer = Color3.fromRGB(15, 15, 20),
        
        -- Elements (Buttons, Inputs)
        ElementBackground = Color3.fromRGB(24, 24, 32),
        ElementStroke = Color3.fromRGB(40, 40, 55),
        
        -- Text
        TextColor = Color3.fromRGB(240, 240, 255),
        SubTextColor = Color3.fromRGB(160, 160, 180),
        
        -- Interaction Colors
        Accent = Color3.fromRGB(0, 220, 180), -- Cyan/Teal Neon
        Hover = Color3.fromRGB(35, 35, 45),
        Active = Color3.fromRGB(0, 180, 150),
        
        -- Functional Colors
        Success = Color3.fromRGB(100, 255, 120),
        Warning = Color3.fromRGB(255, 200, 80),
        Error = Color3.fromRGB(255, 80, 80),
        
        -- Advanced Effects
        Gradients = {
            Enabled = true,
            Primary = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 220, 180)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 150, 255))
            },
            DarkFade = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 150, 150)) -- Used for brightness gradient
            }
        }
    }
}

--// ACTIVE THEME
Config.Current = Config.Themes.Solaris_Clean

--// STYLING CONSTANTS
Config.Styling = {
    -- Geometry
    CornerRadius = UDim.new(0, 6),
    CornerRadiusSmall = UDim.new(0, 4),
    StrokeThickness = 1,
    
    -- Layout
    Padding = UDim.new(0, 10),
    Spacing = UDim.new(0, 5),
    
    -- Typography
    Fonts = {
        Title = Enum.Font.GothamBold,
        Body = Enum.Font.GothamMedium,
        Light = Enum.Font.Gotham,
        Code = Enum.Font.Code
    },
    
    -- Text Sizes
    TextSize = {
        Title = 18,
        Header = 16,
        Body = 14,
        Small = 12
    }
}

--// ANIMATION SETTINGS
Config.Animations = {
    Default = TweenInfo.new(0.25, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out),
    Spring = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    Linear = TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
}

--// ASSETS (Roblox IDs)
Config.Assets = {
    ShadowBlob = "rbxassetid://6015897843", -- Soft shadow texture
    NoiseTexture = "rbxassetid://300623259", -- Subtle grain for background
    Icons = {
        Check = "rbxassetid://6031094667",
        Close = "rbxassetid://6031094678",
        Settings = "rbxassetid://6031280882"
    }
}

--// RAYFIELD COMPATIBILITY MAP
-- Converts the complex theme to the flat table Rayfield expects.
function Config.GetRayfieldTheme()
    local c = Config.Current
    return {
        TextColor = c.TextColor,
        Background = c.WindowBackground,
        ActionBar = c.ActionBar,
        Main = c.TabContainer,
        Element = c.ElementBackground,
        Secondary = c.ElementBackground, -- Rayfield uses this for some backgrounds
        Accent = c.Accent,
        Interact = c.Hover
    }
end

return Config