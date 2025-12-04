--[[
    [MODULE] Core/Tab.lua
    [ARCHITECT] Lead UI Architect
    [SYSTEM] Sirius Rayfield Interface | Tab Management System
    [VERSION] 3.5.0-Stable
    [TARGET] Delta Executor / Fluxus / Hydrogen / Roblox Luau

    [DESCRIPTION]
    This module encapsulates the "Tab" concept within the UI Library.
    It is responsible for:
    1. Creating the interactive Tab Button in the Sidebar/Navigation area.
    2. Creating the content container (Page) for elements.
    3. Managing visibility states (Active vs Inactive).
    4. Orchestrating the creation of Sections and Elements within the tab.
    5. Handling dynamic resizing and layout logic for smooth scrolling.

    [DEPENDENCIES]
    - Core/Utility.lua (Instance creation, Tweening, Signals)
    - Core/Config.lua (Theme data, Sizing constants)
    - Core/Section.lua (Sub-container management)
]]

local Tab = {}
Tab.__index = Tab

--// Services
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

--// Module Dependencies
-- Assuming strict folder structure based on prompt
local Utility = require(script.Parent.Utility)
local Config = require(script.Parent.Config)
local Section = require(script.Parent.Section)
-- We might need to require specific Element modules later or rely on a central Element factory passed in.
-- For this architecture, we will assume a global or passed-down Element Factory to avoid circular deps.

--// Constants & Configuration
local TWEEN_INFO = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local HOVER_TWEEN = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

--// Types (Luau)
export type TabObject = {
    Name: string,
    Icon: string?,
    Window: any, -- Reference to parent Window object
    Instance: Frame, -- The Tab Button
    Container: ScrollingFrame, -- The Content Page
    Sections: {any},
    Elements: {any},
    IsActive: boolean,
    Activate: (self: TabObject) -> (),
    Deactivate: (self: TabObject) -> (),
}

--[[
    [CONSTRUCTOR] Tab.new
    Creates a new Tab instance, initializing both the navigation button and the content page.
    
    @param windowTable (table) - The parent Window object (must contain references to containers).
    @param name (string) - The display name of the tab.
    @param iconId (string|number) - Optional asset ID for the icon.
    @return (table) - The constructed Tab object.
]]
function Tab.new(windowTable, name, iconId)
    -- 1. Input Validation
    assert(windowTable, "[Tab.new] Window reference is missing.")
    assert(type(name) == "string", "[Tab.new] Tab name must be a string.")
    
    local self = setmetatable({}, Tab)
    
    -- 2. State Initialization
    self.Name = name
    self.Icon = iconId or nil
    self.Window = windowTable
    self.Sections = {}
    self.Elements = {}
    self.IsActive = false
    self.Hovered = false

    -- 3. Visual Component Creation
    self:_createVisuals()
    
    -- 4. Event Binding
    self:_bindEvents()

    -- 5. Register with Parent Window
    -- The window needs to know about this tab to handle switching.
    if self.Window.RegisterTab then
        self.Window:RegisterTab(self)
    end

    -- 6. Initial Layout Update
    self:UpdateLayout()

    Utility.Log("Info", string.format("Tab Created: %s", self.Name))

    return self
end

--[[
    [PRIVATE] _createVisuals
    Constructs the Roblox instances for the Tab Button and Content Page.
]]
function Tab:_createVisuals()
    local Theme = Config.Current or Config.GetDefault()
    
    --// A. The Content Page (The container holding sections/elements)
    -- This sits inside the Window's main content area.
    self.Container = Utility.Create("ScrollingFrame", {
        Name = self.Name .. "_Page",
        Parent = self.Window.ContainerHolder, -- Accessing parent's container holder
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Theme.Accent,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0), -- Auto-resizes
        Visible = false, -- Hidden by default
        ClipsDescendants = true,
        ElasticBehavior = Enum.ElasticBehavior.Never,
        ScrollingDirection = Enum.ScrollingDirection.Y
    })

    -- Add Padding to the page
    Utility.Create("UIPadding", {
        Parent = self.Container,
        PaddingTop = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10)
    })

    -- Add Layout for Sections/Elements
    self.Layout = Utility.Create("UIListLayout", {
        Parent = self.Container,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 12), -- Spacing between sections/elements
        HorizontalAlignment = Enum.HorizontalAlignment.Center
    })

    --// B. The Tab Button (Navigation)
    -- This sits in the Sidebar.
    self.Instance = Utility.Create("TextButton", {
        Name = self.Name .. "_Button",
        Parent = self.Window.TabHolder, -- Accessing parent's tab list container
        Size = UDim2.new(1, -10, 0, 32), -- Standard height
        BackgroundColor3 = Theme.TabBackground or Color3.fromRGB(30, 30, 30),
        BackgroundTransparency = 1, -- Usually transparent until hovered/active
        Text = "",
        AutoButtonColor = false,
        ClipsDescendants = true
    })

    -- Button Styling (Corners)
    Utility.Create("UICorner", {
        Parent = self.Instance,
        CornerRadius = UDim.new(0, 6)
    })

    -- Tab Icon
    local textOffset = 12
    if self.Icon and self.Icon ~= "" then
        textOffset = 34 -- Shift text if icon exists
        
        self.IconImage = Utility.Create("ImageLabel", {
            Name = "Icon",
            Parent = self.Instance,
            Size = UDim2.new(0, 18, 0, 18),
            Position = UDim2.new(0, 10, 0.5, -9),
            BackgroundTransparency = 1,
            Image = "rbxassetid://" .. tostring(self.Icon),
            ImageColor3 = Theme.TextDark, -- Inactive Color
            ScaleType = Enum.ScaleType.Fit
        })
    end

    -- Tab Title
    self.TitleLabel = Utility.Create("TextLabel", {
        Name = "Title",
        Parent = self.Instance,
        Size = UDim2.new(1, -textOffset - 10, 1, 0),
        Position = UDim2.new(0, textOffset, 0, 0),
        BackgroundTransparency = 1,
        Text = self.Name,
        TextColor3 = Theme.TextDark, -- Inactive Color
        TextSize = 13,
        Font = Config.Font or Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    -- Active Indicator (Optional side bar or underline)
    self.Indicator = Utility.Create("Frame", {
        Name = "Indicator",
        Parent = self.Instance,
        Size = UDim2.new(0, 3, 0, 16),
        Position = UDim2.new(0, 0, 0.5, -8),
        BackgroundColor3 = Theme.Accent,
        BackgroundTransparency = 1, -- Hidden by default
        BorderSizePixel = 0
    })
    
    Utility.Create("UICorner", {
        Parent = self.Indicator,
        CornerRadius = UDim.new(0, 4)
    })
end

--[[
    [PRIVATE] _bindEvents
    Connects input signals (Hover, Click) to the Tab Button.
]]
function Tab:_bindEvents()
    local Theme = Config.Current

    -- Hover Enter
    self.Instance.MouseEnter:Connect(function()
        if self.IsActive then return end
        self.Hovered = true
        
        TweenService:Create(self.TitleLabel, HOVER_TWEEN, {
            TextColor3 = Theme.TextLight
        }):Play()
        
        if self.IconImage then
            TweenService:Create(self.IconImage, HOVER_TWEEN, {
                ImageColor3 = Theme.TextLight
            }):Play()
        end
    end)

    -- Hover Leave
    self.Instance.MouseLeave:Connect(function()
        self.Hovered = false
        if self.IsActive then return end
        
        TweenService:Create(self.TitleLabel, HOVER_TWEEN, {
            TextColor3 = Theme.TextDark
        }):Play()
        
        if self.IconImage then
            TweenService:Create(self.IconImage, HOVER_TWEEN, {
                ImageColor3 = Theme.TextDark
            }):Play()
        end
    end)

    -- Click (Activation)
    self.Instance.MouseButton1Click:Connect(function()
        if self.IsActive then return end
        self:Activate()
    end)
    
    -- Monitor Layout Changes for Canvas Resize
    self.Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        self:UpdateCanvas()
    end)
end

--[[
    [METHOD] Activate
    Sets this tab as the currently visible tab. Triggers the Window to deactivate others.
]]
function Tab:Activate()
    if self.IsActive then return end
    
    -- 1. Deactivate other tabs via Window Controller
    if self.Window and self.Window.ActiveTab and self.Window.ActiveTab ~= self then
        self.Window.ActiveTab:Deactivate()
    end
    
    -- 2. Update Window State
    self.Window.ActiveTab = self
    self.IsActive = true
    
    local Theme = Config.Current

    -- 3. Animate Visuals (Active State)
    TweenService:Create(self.TitleLabel, TWEEN_INFO, {
        TextColor3 = Theme.Accent -- Highlight text with Accent color
    }):Play()
    
    if self.IconImage then
        TweenService:Create(self.IconImage, TWEEN_INFO, {
            ImageColor3 = Theme.Accent
        }):Play()
    end
    
    -- Show Indicator
    TweenService:Create(self.Indicator, TWEEN_INFO, {
        BackgroundTransparency = 0
    }):Play()
    
    -- 4. Show Content
    self.Container.Visible = true
    
    -- Animate Content Fade-in (Optional polish)
    self.Container.CanvasPosition = Vector2.new(0,0) -- Reset scroll? Optional.
end

--[[
    [METHOD] Deactivate
    Hides this tab's content and resets its visual state.
]]
function Tab:Deactivate()
    if not self.IsActive then return end
    
    self.IsActive = false
    local Theme = Config.Current

    -- 1. Animate Visuals (Inactive State)
    TweenService:Create(self.TitleLabel, TWEEN_INFO, {
        TextColor3 = Theme.TextDark
    }):Play()
    
    if self.IconImage then
        TweenService:Create(self.IconImage, TWEEN_INFO, {
            ImageColor3 = Theme.TextDark
        }):Play()
    end
    
    -- Hide Indicator
    TweenService:Create(self.Indicator, TWEEN_INFO, {
        BackgroundTransparency = 1
    }):Play()
    
    -- 2. Hide Content
    self.Container.Visible = false
end

--[[
    [METHOD] UpdateCanvas
    Recalculates the ScrollingFrame CanvasSize based on content.
    Essential for ScrollingFrames to work correctly with UIListLayouts.
]]
function Tab:UpdateCanvas()
    local contentSize = self.Layout.AbsoluteContentSize
    local padding = 20 -- Extra buffer
    
    self.Container.CanvasSize = UDim2.new(0, 0, 0, contentSize.Y + padding)
end

--[[
    [METHOD] UpdateLayout
    Force refreshes the layout order if needed.
]]
function Tab:UpdateLayout()
    self.Layout:ApplyLayout()
    self:UpdateCanvas()
end

--[[
    [METHOD] CreateSection
    Creates a grouping container (Section) within this tab.
    
    @param name (string) - The title of the section.
    @return (SectionObject) - The created section instance.
]]
function Tab:CreateSection(name)
    -- Delegate logic to Section module
    local newSection = Section.new(self, name)
    
    table.insert(self.Sections, newSection)
    
    -- Force canvas update after section creation
    self:UpdateCanvas()
    
    return newSection
end

--[[
    [METHOD] CreateElement
    Generic proxy to create UI elements.
    If the element is created directly on the Tab, it acts as a standalone element
    outside of a specific Section.
    
    @param elementType (string) - "Button", "Toggle", "Slider", etc.
    @param elementConfig (table) - The configuration table for the element.
    @return (ElementObject) - The created element.
]]
function Tab:CreateElement(elementType, elementConfig)
    -- We need to access the main Elements factory. 
    -- Assuming it's available via utility or a global registry.
    -- For modularity, we might require it dynamically or use a passed factory.
    
    -- NOTE: In this architecture, usually elements are children of Sections.
    -- However, if a user does Tab:CreateButton({...}), we create an anonymous section 
    -- or append to the tab's list layout directly.
    
    -- Let's try to load the Element module dynamically to avoid circular dependency issues at top level.
    local Elements = require(script.Parent.Parent.Elements.BaseElement) -- Hypothetical path
    -- Actually, based on "Elements.lua" in the prompt context, we use that.
    -- But since we are inside Core/, Elements is likely at Parent.Elements or similar.
    -- To keep it simple and robust, we assume the Window passes the Element Factory or we require the specific element file.
    
    local ElementModuleScript = script.Parent.Parent:FindFirstChild("Elements")
    if not ElementModuleScript then
        Utility.Log("Error", "Could not find Elements module!")
        return
    end
    
    local ElementsFactory = require(ElementModuleScript)
    
    -- Inject Parent as self.Container
    elementConfig.Parent = self.Container
    
    local newElement = ElementsFactory:Create(elementType, elementConfig)
    
    if newElement then
        table.insert(self.Elements, newElement)
        self:UpdateCanvas()
    end
    
    return newElement
end

--// =========================================================================
--// WRAPPER METHODS (Rayfield API Style)
--// These allow users to call Tab:CreateButton instead of Tab:CreateElement("Button")
--// =========================================================================

function Tab:CreateButton(config)
    return self:CreateElement("Button", config)
end

function Tab:CreateToggle(config)
    return self:CreateElement("Toggle", config)
end

function Tab:CreateSlider(config)
    return self:CreateElement("Slider", config)
end

function Tab:CreateInput(config)
    return self:CreateElement("Input", config)
end

function Tab:CreateDropdown(config)
    return self:CreateElement("Dropdown", config)
end

function Tab:CreateColorPicker(config)
    return self:CreateElement("ColorPicker", config)
end

function Tab:CreateKeybind(config)
    return self:CreateElement("Keybind", config)
end

function Tab:CreateLabel(config)
    return self:CreateElement("Label", config)
end

function Tab:CreateParagraph(config)
    return self:CreateElement("Paragraph", config)
end

--[[
    [METHOD] Show/Hide
    Programmatically control visibility.
]]
function Tab:Show()
    self:Activate()
end

function Tab:Hide()
    self.Instance.Visible = false
    self.Container.Visible = false
end

--[[
    [METHOD] Destroy
    Cleans up the tab, its button, its content, and all child elements.
]]
function Tab:Destroy()
    Utility.Log("Warning", "Destroying Tab: " .. self.Name)
    
    -- 1. Destroy Sections
    for _, section in ipairs(self.Sections) do
        if section.Destroy then section:Destroy() end
    end
    self.Sections = {}

    -- 2. Destroy Direct Elements
    for _, element in ipairs(self.Elements) do
        if element.Destroy then element:Destroy() end
    end
    self.Elements = {}
    
    -- 3. Destroy Roblox Instances
    if self.Instance then self.Instance:Destroy() end
    if self.Container then self.Container:Destroy() end
    
    -- 4. Nullify References
    self.Window = nil
    setmetatable(self, nil)
end

--[[
    [METHOD] GetSection
    Retrieves a section by name.
]]
function Tab:GetSection(name)
    for _, section in ipairs(self.Sections) do
        if section.Name == name then
            return section
        end
    end
    return nil
end

return Tab