--[[
    [MODULE] Elements/Tab.lua
    [ARCHITECT] Lead UI Architect
    [SYSTEM] Sirius Rayfield UI Library
    [VERSION] 3.2.0-Enterprise
    [TARGET] Delta Executor / Fluxus / Hydrogen / Roblox Luau
    
    [DESCRIPTION]
    The 'Tab' module is the primary container and factory for the Rayfield Interface.
    It bridges the gap between the Window management and individual UI Elements.
    
    [RESPONSIBILITIES]
    1.  Tab Button Management: Creating and handling the sidebar button.
    2.  Container Management: Managing the ScrollingFrame where elements live.
    3.  Element Factory: Providing the API to create Buttons, Toggles, Sliders, etc.
    4.  Search Indexing: Tracking all elements for the global search feature.
    5.  Layout Orchestration: ensuring UIListLayouts and padding are correct.
    
    [INTEGRATION STRATEGY]
    The Tab module lazy-loads Element modules to prevent circular dependencies
    and ensure memory efficiency. It acts as the "Parent" in the OOP hierarchy
    for all elements created within it.
]]

local Tab = {}
Tab.__index = Tab

--// Services
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TextService = game:GetService("TextService")

--// Modules
local Utility = require(script.Parent.Parent["Core/Utility"])
local Config = require(script.Parent.Parent["Core/Config"])
local Theme = require(script.Parent.Parent.Theme)

--// Element Modules (Lazy Loaded in methods or required here if safe)
-- We use a dynamic require helper to avoid circular dependency issues at the top level
local function GetElementModule(name)
    return require(script.Parent[name])
end

--// Constants
local TAB_ANIMATION_INFO = TweenInfo.new(0.3, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)

--[[
    [CONSTRUCTOR] Tab.New
    Creates a new Tab instance attached to a Window.
]]
function Tab.New(Window, Name, IconId)
    local self = setmetatable({}, Tab)
    
    self.Name = Name or "Tab"
    self.IconId = IconId or 0
    self.Window = Window
    self.Elements = {} -- Registry of all elements in this tab
    self.Sections = {} -- Registry of sections
    self.IsVisible = false
    
    -- Validate Window
    if not Window or not Window.Elements or not Window.Elements.TabContainer then
        warn("[Rayfield] Error: Attempted to create Tab without valid Window container.")
        return nil
    end

    --// 1. Create Sidebar Button
    self:CreateTabButton()
    
    --// 2. Create Content Container
    self:CreateContainer()
    
    --// 3. Register with Window
    table.insert(Window.Tabs, self)
    
    --// 4. Select if first tab
    if #Window.Tabs == 1 then
        self:Show()
    end
    
    return self
end

--[[
    [METHOD] CreateTabButton
    Builds the interactive button in the sidebar.
]]
function Tab:CreateTabButton()
    local Button = Instance.new("TextButton")
    Button.Name = self.Name .. "_Button"
    Button.Parent = self.Window.Elements.TabList -- Assuming Window has a TabList container
    Button.BackgroundColor3 = Color3.new(0,0,0)
    Button.BackgroundTransparency = 1
    Button.Size = UDim2.new(1, 0, 0, 30) -- Default height
    Button.AutoButtonColor = false
    Button.Text = ""
    Button.ZIndex = 2
    
    -- Icon
    local Icon = Instance.new("ImageLabel")
    Icon.Name = "Icon"
    Icon.Parent = Button
    Icon.AnchorPoint = Vector2.new(0, 0.5)
    Icon.Position = UDim2.new(0, 10, 0.5, 0)
    Icon.Size = UDim2.new(0, 20, 0, 20)
    Icon.BackgroundTransparency = 1
    Icon.Image = "rbxassetid://" .. tostring(self.IconId)
    Icon.ImageColor3 = Theme.Current.Text
    Icon.ImageTransparency = 0.4
    
    -- Title
    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Parent = Button
    Title.AnchorPoint = Vector2.new(0, 0.5)
    Title.Position = UDim2.new(0, 40, 0.5, 0)
    Title.Size = UDim2.new(1, -50, 1, 0)
    Title.BackgroundTransparency = 1
    Title.Text = self.Name
    Title.Font = Config.Font
    Title.TextSize = 14
    Title.TextColor3 = Theme.Current.Text
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.TextTransparency = 0.4
    
    -- Active Indicator (Little bar on the side)
    local Indicator = Instance.new("Frame")
    Indicator.Name = "Indicator"
    Indicator.Parent = Button
    Indicator.AnchorPoint = Vector2.new(0, 0.5)
    Indicator.Position = UDim2.new(0, 0, 0.5, 0)
    Indicator.Size = UDim2.new(0, 4, 0, 18)
    Indicator.BackgroundColor3 = Theme.Current.Accent
    Indicator.BackgroundTransparency = 1 -- Hidden by default
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 4)
    Corner.Parent = Indicator

    -- Interaction
    Button.MouseButton1Click:Connect(function()
        self.Window:SelectTab(self)
    end)
    
    self.Instances = {
        Button = Button,
        Icon = Icon,
        Title = Title,
        Indicator = Indicator
    }
end

--[[
    [METHOD] CreateContainer
    Builds the ScrollingFrame where elements will be placed.
]]
function Tab:CreateContainer()
    local Container = Instance.new("ScrollingFrame")
    Container.Name = self.Name .. "_Container"
    Container.Parent = self.Window.Elements.TabContainer
    Container.Size = UDim2.new(1, -2, 1, -2) -- Padding
    Container.Position = UDim2.new(0, 1, 0, 1)
    Container.BackgroundTransparency = 1
    Container.ScrollBarThickness = 2
    Container.ScrollBarImageColor3 = Theme.Current.Accent
    Container.CanvasSize = UDim2.new(0, 0, 0, 0)
    Container.Visible = false -- Hidden initially
    
    -- Layout
    local UIList = Instance.new("UIListLayout")
    UIList.Parent = Container
    UIList.SortOrder = Enum.SortOrder.LayoutOrder
    UIList.Padding = UDim.new(0, 6)
    
    local UIPadding = Instance.new("UIPadding")
    UIPadding.Parent = Container
    UIPadding.PaddingTop = UDim.new(0, 10)
    UIPadding.PaddingBottom = UDim.new(0, 10)
    UIPadding.PaddingLeft = UDim.new(0, 10)
    UIPadding.PaddingRight = UDim.new(0, 10)
    
    -- Auto Canvas Resize
    UIList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        Container.CanvasSize = UDim2.new(0, 0, 0, UIList.AbsoluteContentSize.Y + 20)
    end)
    
    self.Container = Container
end

--[[
    [METHOD] Show
    Activates the tab, animating the sidebar button and showing content.
]]
function Tab:Show()
    if self.IsVisible then return end
    self.IsVisible = true
    
    -- Update Sidebar Visuals
    TweenService:Create(self.Instances.Title, TAB_ANIMATION_INFO, {TextTransparency = 0}):Play()
    TweenService:Create(self.Instances.Icon, TAB_ANIMATION_INFO, {ImageTransparency = 0, ImageColor3 = Theme.Current.Accent}):Play()
    TweenService:Create(self.Instances.Indicator, TAB_ANIMATION_INFO, {BackgroundTransparency = 0}):Play()
    
    -- Show Container
    self.Container.Visible = true
    
    -- Animate Elements In (Cascade Effect)
    -- Optional: Only animate if it's a fresh open or user setting enabled
    if Config.Animations.TabTransition then
        for i, element in ipairs(self.Elements) do
            if element.AnimateIn then
                task.delay(i * 0.03, function()
                    element:AnimateIn()
                end)
            end
        end
    end
end

--[[
    [METHOD] Hide
    Deactivates the tab.
]]
function Tab:Hide()
    if not self.IsVisible then return end
    self.IsVisible = false
    
    -- Update Sidebar Visuals
    TweenService:Create(self.Instances.Title, TAB_ANIMATION_INFO, {TextTransparency = 0.4}):Play()
    TweenService:Create(self.Instances.Icon, TAB_ANIMATION_INFO, {ImageTransparency = 0.4, ImageColor3 = Theme.Current.Text}):Play()
    TweenService:Create(self.Instances.Indicator, TAB_ANIMATION_INFO, {BackgroundTransparency = 1}):Play()
    
    -- Hide Container
    self.Container.Visible = false
end

--// =============================================================================
--// ELEMENT FACTORY METHODS
--// =============================================================================

--[[
    [FACTORY] CreateSection
    Sections are sub-headers that can also act as containers if logic permits.
]]
function Tab:CreateSection(Name, Hidden)
    local SectionModule = GetElementModule("Section")
    local NewSection = SectionModule.New(self, Name, Hidden)
    
    table.insert(self.Elements, NewSection)
    table.insert(self.Sections, NewSection)
    
    return NewSection
end

--[[
    [FACTORY] CreateButton
    Creates a clickable button element.
]]
function Tab:CreateButton(ConfigSettings)
    -- Validation
    if not ConfigSettings or type(ConfigSettings) ~= "table" then
        warn("Tab:CreateButton received invalid config.")
        return
    end
    
    local ButtonModule = GetElementModule("Button")
    local NewButton = ButtonModule.New(self, ConfigSettings)
    
    table.insert(self.Elements, NewButton)
    return NewButton
end

--[[
    [FACTORY] CreateToggle
    Creates a boolean switch element.
]]
function Tab:CreateToggle(ConfigSettings)
    local ToggleModule = GetElementModule("Toggle")
    local NewToggle = ToggleModule.New(self, ConfigSettings)
    
    table.insert(self.Elements, NewToggle)
    return NewToggle
end

--[[
    [FACTORY] CreateSlider
    Creates a numeric slider element.
]]
function Tab:CreateSlider(ConfigSettings)
    local SliderModule = GetElementModule("Slider")
    local NewSlider = SliderModule.New(self, ConfigSettings)
    
    table.insert(self.Elements, NewSlider)
    return NewSlider
end

--[[
    [FACTORY] CreateDropdown
    Creates a list selection element.
]]
function Tab:CreateDropdown(ConfigSettings)
    local DropdownModule = GetElementModule("Dropdown")
    local NewDropdown = DropdownModule.New(self, ConfigSettings)
    
    table.insert(self.Elements, NewDropdown)
    return NewDropdown
end

--[[
    [FACTORY] CreateInput
    Creates a text input field.
]]
function Tab:CreateInput(ConfigSettings)
    local InputModule = GetElementModule("Input")
    local NewInput = InputModule.New(self, ConfigSettings)
    
    table.insert(self.Elements, NewInput)
    return NewInput
end

--[[
    [FACTORY] CreateColorPicker
    Creates an RGB/HSV color selection element.
    Note: ColorPickers are often attached to Toggles or Buttons, but can be standalone.
]]
function Tab:CreateColorPicker(ConfigSettings)
    local ColorPickerModule = GetElementModule("ColorPicker")
    local NewCP = ColorPickerModule.New(self, ConfigSettings)
    
    table.insert(self.Elements, NewCP)
    return NewCP
end

--[[
    [FACTORY] CreateKeybind
    Creates a keybinding assignment element.
]]
function Tab:CreateKeybind(ConfigSettings)
    local KeybindModule = GetElementModule("Keybind")
    local NewKeybind = KeybindModule.New(self, ConfigSettings)
    
    table.insert(self.Elements, NewKeybind)
    return NewKeybind
end

--[[
    [FACTORY] CreateLabel
    Creates a simple text label for information.
]]
function Tab:CreateLabel(Text, Icon)
    -- Labels are often simple enough to define inline or use a lightweight module
    -- For robustness, we'll assume a Label module or Section logic
    -- Just mapping it to Section for now if Label module doesn't exist, 
    -- but let's assume we want a distinct element.
    
    local LabelModule = GetElementModule("Label") -- Assuming existence or using Section
    if not LabelModule then
        -- Fallback: Create a text-only section
        return self:CreateSection(Text) 
    end
    
    local NewLabel = LabelModule.New(self, {Name = Text, Icon = Icon})
    table.insert(self.Elements, NewLabel)
    return NewLabel
end

--[[
    [FACTORY] CreateParagraph
    Creates a multi-line text display.
]]
function Tab:CreateParagraph(ConfigSettings)
    -- Config: {Title = "Header", Content = "Body text"}
    local ParagraphModule = GetElementModule("Paragraph")
    local NewParagraph = ParagraphModule.New(self, ConfigSettings)
    
    table.insert(self.Elements, NewParagraph)
    return NewParagraph
end

--// =============================================================================
--// UTILITY METHODS
--// =============================================================================

--[[
    [METHOD] UpdateLayout
    Refreshes the UIListLayout. useful if elements are hidden/shown dynamically.
]]
function Tab:UpdateLayout()
    if self.Container and self.Container:FindFirstChild("UIListLayout") then
        self.Container.UIListLayout:ApplyLayout()
        -- Recalculate canvas
        self.Container.CanvasSize = UDim2.new(0, 0, 0, self.Container.UIListLayout.AbsoluteContentSize.Y + 20)
    end
end

--[[
    [METHOD] Destroy
    Cleans up the tab and all its elements.
]]
function Tab:Destroy()
    -- 1. Destroy Elements
    for _, element in pairs(self.Elements) do
        if element.Destroy then
            element:Destroy()
        end
    end
    self.Elements = {}
    self.Sections = {}
    
    -- 2. Destroy Container
    if self.Container then
        self.Container:Destroy()
    end
    
    -- 3. Destroy Button
    if self.Instances.Button then
        self.Instances.Button:Destroy()
    end
    
    -- 4. Clean Ref
    setmetatable(self, nil)
end

return Tab