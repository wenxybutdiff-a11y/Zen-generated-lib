--[[
    [MODULE] Elements/Paragraph.lua
    [ARCHITECT] Lead UI Architect
    [SYSTEM] Sirius Rayfield UI Library
    [VERSION] 3.2.0-Enterprise
    [TARGET] Delta Executor / Fluxus / Hydrogen / Roblox Luau
    
    [DESCRIPTION]
    A text-display element designed for providing instructions, changelogs, or descriptions.
    Features:
    - Automatic Height Calculation (Dynamic Resizing)
    - Rich Text Support
    - Theming Compliance
    - Optional Header/Title
]]

local Paragraph = {}
Paragraph.__index = Paragraph

--// Services
local TextService = game:GetService("TextService")
local TweenService = game:GetService("TweenService")

--// Modules
local Theme = require(script.Parent.Parent.Theme)
local Config = require(script.Parent.Parent["Core/Config"])

--// Constants
local PADDING = 10
local TITLE_HEIGHT = 20
local BASE_FONT_SIZE = 14
local TITLE_FONT_SIZE = 16

--[[
    [CONSTRUCTOR] Paragraph.New
    Creates a new paragraph element in the specified tab.
]]
function Paragraph.New(Tab, ConfigData)
    local self = setmetatable({}, Paragraph)
    
    self.Tab = Tab
    self.Config = ConfigData or {}
    self.Title = self.Config.Title or nil
    self.Content = self.Config.Content or "Paragraph Content"
    self.Icon = self.Config.Icon or nil
    
    self:CreateUI()
    
    return self
end

--[[
    [METHOD] CreateUI
    Builds the visual components.
]]
function Paragraph:CreateUI()
    -- 1. Calculate Expected Height
    -- We need to know how tall the text content is to size the frame.
    local contentHeight = self:CalculateTextHeight(self.Content, BASE_FONT_SIZE, 30) -- 30 is approx padding width
    local totalHeight = contentHeight + (PADDING * 2)
    
    if self.Title then
        totalHeight = totalHeight + TITLE_HEIGHT + 4 -- Extra space for title
    end
    
    -- 2. Main Frame
    local Frame = Instance.new("Frame")
    Frame.Name = "Paragraph"
    Frame.Parent = self.Tab.Container
    Frame.BackgroundColor3 = Theme.Current.ElementBackground
    Frame.BorderSizePixel = 0
    Frame.Size = UDim2.new(1, 0, 0, totalHeight)
    Frame.ClipsDescendants = true
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 6)
    Corner.Parent = Frame
    
    local UIStroke = Instance.new("UIStroke")
    UIStroke.Parent = Frame
    UIStroke.Color = Theme.Current.Secondary
    UIStroke.Thickness = 1
    UIStroke.Transparency = 0.8
    
    -- 3. Title (Optional)
    local currentY = PADDING
    
    if self.Title then
        local TitleLabel = Instance.new("TextLabel")
        TitleLabel.Name = "Title"
        TitleLabel.Parent = Frame
        TitleLabel.BackgroundTransparency = 1
        TitleLabel.Position = UDim2.new(0, PADDING, 0, PADDING)
        TitleLabel.Size = UDim2.new(1, -(PADDING*2), 0, TITLE_HEIGHT)
        TitleLabel.Font = Enum.Font.GothamBold
        TitleLabel.Text = self.Title
        TitleLabel.TextColor3 = Theme.Current.Text
        TitleLabel.TextSize = TITLE_FONT_SIZE
        TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
        
        -- Optional Icon next to title
        if self.Icon then
            local IconImg = Instance.new("ImageLabel")
            IconImg.Parent = Frame
            IconImg.BackgroundTransparency = 1
            IconImg.Position = UDim2.new(0, PADDING, 0, PADDING)
            IconImg.Size = UDim2.new(0, 20, 0, 20)
            IconImg.Image = "rbxassetid://" .. tostring(self.Icon)
            IconImg.ImageColor3 = Theme.Current.Accent
            
            -- Shift title text
            TitleLabel.Position = UDim2.new(0, PADDING + 25, 0, PADDING)
            TitleLabel.Size = UDim2.new(1, -(PADDING*2 + 25), 0, TITLE_HEIGHT)
        end
        
        currentY = currentY + TITLE_HEIGHT + 4
    end
    
    -- 4. Content
    local ContentLabel = Instance.new("TextLabel")
    ContentLabel.Name = "Content"
    ContentLabel.Parent = Frame
    ContentLabel.BackgroundTransparency = 1
    ContentLabel.Position = UDim2.new(0, PADDING, 0, currentY)
    ContentLabel.Size = UDim2.new(1, -(PADDING*2), 0, contentHeight)
    ContentLabel.Font = Enum.Font.Gotham
    ContentLabel.Text = self.Content
    ContentLabel.TextColor3 = Theme.Current.Text
    ContentLabel.TextSize = BASE_FONT_SIZE
    ContentLabel.TextTransparency = 0.4
    ContentLabel.TextXAlignment = Enum.TextXAlignment.Left
    ContentLabel.TextYAlignment = Enum.TextYAlignment.Top
    ContentLabel.TextWrapped = true
    ContentLabel.RichText = true
    
    self.Instance = Frame
    self.ContentLabel = ContentLabel
    self.TitleLabel = Frame:FindFirstChild("Title")
end

--[[
    [METHOD] CalculateTextHeight
    Uses TextService to determine how tall the paragraph needs to be.
]]
function Paragraph:CalculateTextHeight(text, size, paddingX)
    local maxWidth = self.Tab.Container.AbsoluteSize.X - paddingX
    if maxWidth <= 0 then maxWidth = 400 end -- Fallback if container not rendered yet
    
    local params = Instance.new("GetTextBoundsParams")
    params.Text = text
    params.Size = size
    params.Font = Enum.Font.Gotham
    params.Width = maxWidth
    
    local bounds = TextService:GetTextBoundsAsync(params)
    return bounds.Y + 5 -- Buffer
end

--[[
    [METHOD] Set
    Updates the text content dynamically.
]]
function Paragraph:Set(NewProps)
    if NewProps.Title then
        self.Title = NewProps.Title
        if self.TitleLabel then self.TitleLabel.Text = self.Title end
    end
    
    if NewProps.Content then
        self.Content = NewProps.Content
        self.ContentLabel.Text = self.Content
        
        -- Recalculate size
        local contentHeight = self:CalculateTextHeight(self.Content, BASE_FONT_SIZE, 30)
        local totalHeight = contentHeight + (PADDING * 2)
        if self.Title then
            totalHeight = totalHeight + TITLE_HEIGHT + 4
        end
        
        self.Instance.Size = UDim2.new(1, 0, 0, totalHeight)
        self.ContentLabel.Size = UDim2.new(1, -(PADDING*2), 0, contentHeight)
        
        -- Trigger tab layout update
        if self.Tab and self.Tab.UpdateLayout then
            self.Tab:UpdateLayout()
        end
    end
end

function Paragraph:Destroy()
    if self.Instance then self.Instance:Destroy() end
    setmetatable(self, nil)
end

return Paragraph