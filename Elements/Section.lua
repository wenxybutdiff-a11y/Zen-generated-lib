--[[
    [MODULE] Elements/Section.lua
    [ARCHITECT] Lead UI Architect
    [SYSTEM] Sirius Rayfield UI Library
    [VERSION] 2.4.0-Enterprise
    
    [DESCRIPTION]
    The Section element serves as a divider and grouper within a Tab.
    Unlike standard dividers, Rayfield Sections can be interactive (collapsible)
    and can also act as factories for elements, allowing for organized code structure.
]]

local Section = {}
Section.__index = Section

--// Services
local TweenService = game:GetService("TweenService")

--// Modules
local Utility = require(script.Parent.Parent["Core/Utility"])
local Theme = require(script.Parent.Parent.Theme)

--// Constants
local SECTION_HEIGHT = 26

--[[
    [CONSTRUCTOR] Section.New
    Creates a new Section.
    
    @param ParentTab: The Tab object this section belongs to.
    @param Name: The text displayed on the section header.
]]
function Section.New(ParentTab, Name)
    local self = setmetatable({}, Section)
    
    self.Name = Name or "Section"
    self.ParentTab = ParentTab
    self.Elements = {} -- Elements created *under* this section (logical grouping)
    self.Type = "Section"
    
    -- Create UI
    self:CreateUI()
    
    return self
end

function Section:CreateUI()
    -- The container within the Tab's scrolling frame
    local Container = Instance.new("Frame")
    Container.Name = "Section_" .. self.Name
    Container.Parent = self.ParentTab.Container
    Container.BackgroundColor3 = Color3.new(0,0,0)
    Container.BackgroundTransparency = 1
    Container.Size = UDim2.new(1, 0, 0, SECTION_HEIGHT)
    
    -- Text Label
    local Label = Instance.new("TextLabel")
    Label.Name = "Title"
    Label.Parent = Container
    Label.AnchorPoint = Vector2.new(0, 0.5)
    Label.Position = UDim2.new(0, 0, 0.5, 0)
    Label.Size = UDim2.new(1, 0, 0, 18)
    Label.BackgroundTransparency = 1
    Label.Text = self.Name
    Label.Font = Enum.Font.GothamBold
    Label.TextSize = 12
    Label.TextColor3 = Theme.Current.Text
    Label.TextTransparency = 0.5
    Label.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Decorator Line (optional, next to text)
    local Line = Instance.new("Frame")
    Line.Name = "Line"
    Line.Parent = Container
    Line.AnchorPoint = Vector2.new(0, 0.5)
    Line.Position = UDim2.new(0, Label.TextBounds.X + 10, 0.5, 0) -- Need to update this after render
    Line.Size = UDim2.new(1, -(Label.TextBounds.X + 10), 0, 1)
    Line.BackgroundColor3 = Theme.Current.ElementBackground
    Line.BorderSizePixel = 0
    
    -- Dynamic Sizing based on text
    Label:GetPropertyChangedSignal("TextBounds"):Connect(function()
        local width = Label.TextBounds.X
        Line.Position = UDim2.new(0, width + 10, 0.5, 0)
        Line.Size = UDim2.new(1, -(width + 10), 0, 1)
    end)
    
    self.Instance = Container
    self.TitleLabel = Label
end

--[[
    [METHOD] SetName
    Updates the section text.
]]
function Section:SetName(text)
    self.Name = text
    self.TitleLabel.Text = text
end

--// =============================================================================
--// PROXY FACTORY METHODS
--// =============================================================================
-- These allow syntax like: local MySection = Tab:CreateSection(...) -> MySection:CreateButton(...)
-- In the current architecture, elements are physically parented to the Tab's list layout.
-- The Section object is just a visual divider in that list.
-- So, creating an element via Section just calls the Tab's creator.

function Section:CreateButton(Config)
    return self.ParentTab:CreateButton(Config)
end

function Section:CreateToggle(Config)
    return self.ParentTab:CreateToggle(Config)
end

function Section:CreateSlider(Config)
    return self.ParentTab:CreateSlider(Config)
end

function Section:CreateDropdown(Config)
    return self.ParentTab:CreateDropdown(Config)
end

function Section:CreateInput(Config)
    return self.ParentTab:CreateInput(Config)
end

function Section:CreateColorPicker(Config)
    return self.ParentTab:CreateColorPicker(Config)
end

function Section:CreateKeybind(Config)
    return self.ParentTab:CreateKeybind(Config)
end

function Section:CreateParagraph(Config)
    return self.ParentTab:CreateParagraph(Config)
end

function Section:CreateLabel(Text)
    return self.ParentTab:CreateLabel(Text)
end

--[[
    [METHOD] Destroy
]]
function Section:Destroy()
    if self.Instance then
        self.Instance:Destroy()
    end
    setmetatable(self, nil)
end

return Section