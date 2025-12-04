--[[
    [MODULE] Library.lua
    [ARCHITECT] Lead UI Architect
    [DESCRIPTION] 
        Core Library wrapper for Sirius Rayfield. 
        This module initializes the Rayfield instance, injects the Solaris configuration,
        and triggers the ThemeManager to apply aesthetic overrides.
        
    [DEPENDENCIES]
        - Config.lua
        - ThemeManager.lua
        - Utility.lua
        - Elements.lua
]]

local Library = {}

--// Services
local CoreGui = game:GetService("CoreGui")

--// Modules
local Config = require(script.Parent.Config)
local Utility = require(script.Parent.Utility)
local ThemeManager = require(script.Parent.ThemeManager)
local TabHandler = require(script.Parent.TabHandler) -- Assuming existence from previous context
-- Note: Elements are created via TabHandler usually

--// Internal Reference to the Real Rayfield
-- In a real scenario, this would be `loadstring(game:HttpGet('...'))()`
-- For this "Build", we assume we have a module or we are mocking the constructor.
-- We will simulate the Rayfield Object creation.

local Rayfield = {
    CreateWindow = function(self, settings)
        -- 1. Validate Settings
        settings = settings or {}
        local theme = settings.Theme or Config.GetRayfieldTheme()
        
        -- 2. Create the ScreenGui (Mocking internal Rayfield behavior)
        local gui = Instance.new("ScreenGui")
        gui.Name = settings.ConfigurationSaving.FolderName or "Rayfield"
        
        -- Attempt to protect GUI
        if gethui then
            gui.Parent = gethui()
        elseif syn and syn.protect_gui then
            gui.Parent = CoreGui
            syn.protect_gui(gui)
        else
            gui.Parent = CoreGui
        end
        
        -- 3. Create Main Frame
        local main = Instance.new("Frame")
        main.Name = "Main"
        main.Size = UDim2.new(0, 500, 0, 350)
        main.Position = UDim2.new(0.5, -250, 0.5, -175)
        main.BackgroundColor3 = theme.Background
        main.BorderSizePixel = 0
        main.Parent = gui
        
        -- Add Header
        local topbar = Instance.new("Frame")
        topbar.Name = "Topbar"
        topbar.Size = UDim2.new(1, 0, 0, 40)
        topbar.BackgroundColor3 = theme.ActionBar
        topbar.Parent = main
        
        local title = Instance.new("TextLabel")
        title.Text = settings.Name or "Rayfield"
        title.Font = Config.Styling.Fonts.Title
        title.TextColor3 = theme.TextColor
        title.Size = UDim2.new(1, -20, 1, 0)
        title.Position = UDim2.new(0, 20, 0, 0)
        title.BackgroundTransparency = 1
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Parent = topbar
        
        -- Add Container for Tabs
        local container = Instance.new("Frame")
        container.Name = "Container"
        container.Size = UDim2.new(1, 0, 1, -40)
        container.Position = UDim2.new(0, 0, 0, 40)
        container.BackgroundColor3 = theme.Main
        container.Parent = main
        
        -- 4. Return the Window Object
        local windowObj = {
            Instance = gui,
            MainFrame = main,
            Container = container,
            Tabs = {},
            
            CreateTab = function(self, name, icon)
                -- Call TabHandler to create a new tab
                -- In a real Rayfield loadstring, this is internal.
                -- Here we simulate the return.
                local newTab = TabHandler.Create(self, name, icon)
                table.insert(self.Tabs, newTab)
                return newTab
            end,
            
            Destroy = function(self)
                ThemeManager.Stop()
                gui:Destroy()
            end
        }
        
        -- 5. Trigger Theme Refinement
        -- This is the critical step for "Refining Aesthetics"
        ThemeManager.StartRefinement(gui)
        
        return windowObj
    end,
    
    Notify = function(self, config)
        -- Notification Logic
        Utility.Log("Info", "Notification: " .. (config.Title or "") .. " - " .. (config.Content or ""))
    end
}

--// Public API
function Library:CreateWindow(config)
    -- Inject Config Theme if not provided
    if not config.Theme then
        config.Theme = Config.GetRayfieldTheme()
    end
    
    -- Create Window
    local window = Rayfield:CreateWindow(config)
    
    -- Additional setup if needed
    Utility.Log("Success", "Window Created via Library Wrapper")
    
    return window
end

function Library:Notify(config)
    Rayfield:Notify(config)
end

function Library:Destroy()
    -- Cleanup global state if necessary
end

return Library