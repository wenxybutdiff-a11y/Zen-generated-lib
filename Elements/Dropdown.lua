--[[
    [MODULE] Elements/Dropdown.lua
    [ARCHITECT] Lead UI Architect
    [SYSTEM] Sirius Rayfield UI Library
    [VERSION] 4.2.0-Enterprise
    [TARGET] Delta Executor / Fluxus / Hydrogen / Roblox Luau

    [DESCRIPTION]
    A robust Dropdown element supporting search filtering, scrolling, and safe layout handling.
    
    [FEATURES]
    - Dynamic Height Calculation.
    - Search Filter (Real-time).
    - Multi-select support flag.
    - ZIndex layering management for overlay effects.
]]

local Dropdown = {}
Dropdown.__index = Dropdown

--// Services
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local TextService = game:GetService("TextService")

--// Modules
local Theme = require(script.Parent.Parent.Theme)
local Utility = require(script.Parent.Parent["Core/Utility"])

--// Constants
local OPEN_TWEEN = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local ITEM_HEIGHT = 28
local MAX_VISIBLE_ITEMS = 6

--[[
    [CONSTRUCTOR] Dropdown.New
]]
function Dropdown.New(Tab, Config)
    local self = setmetatable({}, Dropdown)
    
    self.Tab = Tab
    self.Config = Config or {}
    self.Name = self.Config.Name or "Dropdown"
    self.Options = self.Config.Options or {}
    self.CurrentOption = self.Config.CurrentOption or self.Config.Default or self.Options[1] or ""
    self.Callback = self.Config.Callback or function() end
    self.MultipleOptions = self.Config.MultipleOptions or false
    
    -- State
    self.Open = false
    self.SearchText = ""
    self.FilteredOptions = self.Options
    self.IsSearching = false
    
    self:CreateUI()
    return self
end

--[[
    [METHOD] CreateUI
]]
function Dropdown:CreateUI()
    -- 1. Main Header Frame
    local Frame = Instance.new("Frame")
    Frame.Name = "Dropdown_" .. self.Name
    Frame.Parent = self.Tab.Container
    Frame.BackgroundColor3 = Theme.Current.ElementBackground
    Frame.Size = UDim2.new(1, 0, 0, 46)
    Frame.ZIndex = 2
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 6)
    Corner.Parent = Frame
    
    -- 2. Title Label
    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Parent = Frame
    Title.Position = UDim2.new(0, 15, 0, 6)
    Title.Size = UDim2.new(1, -50, 0, 14)
    Title.BackgroundTransparency = 1
    Title.Text = self.Name
    Title.Font = Theme.Font or Enum.Font.GothamMedium
    Title.TextSize = 12
    Title.TextColor3 = Theme.Current.Text
    Title.TextTransparency = 0.4
    Title.TextXAlignment = Enum.TextXAlignment.Left
    
    -- 3. Selected Value / Search Input
    local ValueLabel = Instance.new("TextBox") -- TextBox to double as Search Bar
    ValueLabel.Name = "Value"
    ValueLabel.Parent = Frame
    ValueLabel.Position = UDim2.new(0, 15, 0, 24)
    ValueLabel.Size = UDim2.new(1, -50, 0, 14)
    ValueLabel.BackgroundTransparency = 1
    ValueLabel.Text = tostring(self.CurrentOption)
    ValueLabel.PlaceholderText = "Search..."
    ValueLabel.Font = Theme.FontBold or Enum.Font.GothamBold
    ValueLabel.TextSize = 14
    ValueLabel.TextColor3 = Theme.Current.Text
    ValueLabel.TextXAlignment = Enum.TextXAlignment.Left
    ValueLabel.ClearTextOnFocus = false
    
    -- 4. Arrow Icon
    local Arrow = Instance.new("ImageLabel")
    Arrow.Name = "Arrow"
    Arrow.Parent = Frame
    Arrow.AnchorPoint = Vector2.new(1, 0.5)
    Arrow.Position = UDim2.new(1, -15, 0.5, 0)
    Arrow.Size = UDim2.new(0, 20, 0, 20)
    Arrow.BackgroundTransparency = 1
    Arrow.Image = "rbxassetid://6031091004" -- Chevron Down
    Arrow.ImageColor3 = Theme.Current.Text
    
    -- 5. List Container (Hidden)
    local ListFrame = Instance.new("Frame")
    ListFrame.Name = "List"
    ListFrame.Parent = Frame
    ListFrame.BackgroundColor3 = Theme.Current.Secondary
    ListFrame.Position = UDim2.new(0, 0, 1, 0)
    ListFrame.Size = UDim2.new(1, 0, 0, 0) -- Height 0 initially
    ListFrame.ClipsDescendants = true
    ListFrame.BorderSizePixel = 0
    ListFrame.ZIndex = 5 -- Floats above other elements
    ListFrame.Visible = false
    
    local ListCorner = Instance.new("UICorner")
    ListCorner.CornerRadius = UDim.new(0, 6)
    ListCorner.Parent = ListFrame
    
    -- 6. Scrollable List
    local Scroll = Instance.new("ScrollingFrame")
    Scroll.Name = "Scroll"
    Scroll.Parent = ListFrame
    Scroll.Position = UDim2.new(0, 5, 0, 5)
    Scroll.Size = UDim2.new(1, -10, 1, -10)
    Scroll.BackgroundTransparency = 1
    Scroll.ScrollBarThickness = 3
    Scroll.ScrollBarImageColor3 = Theme.Current.Accent
    Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    Scroll.ZIndex = 6
    
    local UIList = Instance.new("UIListLayout")
    UIList.Parent = Scroll
    UIList.SortOrder = Enum.SortOrder.LayoutOrder
    UIList.Padding = UDim.new(0, 4)
    
    -- 7. Interaction Logic
    local Interact = Instance.new("TextButton")
    Interact.Parent = Frame
    Interact.Size = UDim2.new(1, -40, 1, 0) -- Leave space for search typing if needed?
    -- Actually, if using SearchBox, we need to handle clicks differently.
    -- Strategy: Interact button covers area. When clicked, opens dropdown.
    -- Once open, ValueLabel becomes focusable for typing search.
    Interact.BackgroundTransparency = 1
    Interact.Text = ""
    Interact.ZIndex = 3
    
    Interact.MouseButton1Click:Connect(function()
        self:Toggle()
    end)
    
    -- Search Logic
    ValueLabel.Focused:Connect(function()
        if not self.Open then self:Toggle() end
        self.IsSearching = true
        ValueLabel.Text = "" -- Clear for typing
    end)
    
    ValueLabel.FocusLost:Connect(function()
        self.IsSearching = false
        -- If no selection made, revert text
        if ValueLabel.Text == "" then
             ValueLabel.Text = tostring(self.CurrentOption)
        end
    end)
    
    ValueLabel:GetPropertyChangedSignal("Text"):Connect(function()
        if self.IsSearching then
            self:Filter(ValueLabel.Text)
        end
    end)
    
    self.Instance = Frame
    self.ListFrame = ListFrame
    self.Scroll = Scroll
    self.Arrow = Arrow
    self.ValueLabel = ValueLabel
    self.UIList = UIList
    
    -- Init Items
    self:Refresh(self.Options)
end

--[[
    [METHOD] Toggle
]]
function Dropdown:Toggle()
    self.Open = not self.Open
    
    if self.Open then
        -- Open State
        self.ListFrame.Visible = true
        self.Instance.ZIndex = 20 -- Bring to front
        
        -- Calculate Dynamic Height
        local itemCount = #self.FilteredOptions
        local displayCount = math.min(itemCount, MAX_VISIBLE_ITEMS)
        local contentHeight = (displayCount * ITEM_HEIGHT) + ((displayCount + 1) * 4) + 6
        if itemCount == 0 then contentHeight = 30 end -- Min height for "No results"
        
        -- Animate
        TweenService:Create(self.ListFrame, OPEN_TWEEN, {Size = UDim2.new(1, 0, 0, contentHeight)}):Play()
        TweenService:Create(self.Arrow, OPEN_TWEEN, {Rotation = 180, ImageColor3 = Theme.Current.Accent}):Play()
        
    else
        -- Close State
        local closeTween = TweenService:Create(self.ListFrame, OPEN_TWEEN, {Size = UDim2.new(1, 0, 0, 0)})
        closeTween:Play()
        TweenService:Create(self.Arrow, OPEN_TWEEN, {Rotation = 0, ImageColor3 = Theme.Current.Text}):Play()
        
        closeTween.Completed:Connect(function()
            if not self.Open then
                self.ListFrame.Visible = false
                self.Instance.ZIndex = 2 -- Reset ZIndex
                -- Reset Filter
                self:Refresh(self.Options)
                self.ValueLabel.Text = tostring(self.CurrentOption)
            end
        end)
    end
end

--[[
    [METHOD] Filter
]]
function Dropdown:Filter(query)
    query = query:lower()
    local newOptions = {}
    
    for _, opt in ipairs(self.Options) do
        if tostring(opt):lower():find(query) then
            table.insert(newOptions, opt)
        end
    end
    
    self.FilteredOptions = newOptions
    self:Refresh(self.FilteredOptions)
end

--[[
    [METHOD] Refresh
    Rebuilds the list of buttons.
]]
function Dropdown:Refresh(list)
    -- Cleanup
    for _, child in ipairs(self.Scroll:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    
    -- Rebuild
    for _, option in ipairs(list) do
        local Btn = Instance.new("TextButton")
        Btn.Name = tostring(option)
        Btn.Parent = self.Scroll
        Btn.Size = UDim2.new(1, 0, 0, ITEM_HEIGHT)
        Btn.BackgroundColor3 = Theme.Current.ElementBackground
        Btn.Text = "  " .. tostring(option)
        Btn.Font = Enum.Font.Gotham
        Btn.TextSize = 13
        Btn.TextColor3 = Theme.Current.Text
        Btn.TextXAlignment = Enum.TextXAlignment.Left
        Btn.AutoButtonColor = false
        Btn.ZIndex = 10
        
        local Corner = Instance.new("UICorner")
        Corner.CornerRadius = UDim.new(0, 4)
        Corner.Parent = Btn
        
        -- Selection Logic
        Btn.MouseButton1Click:Connect(function()
            self:Select(option)
        end)
        
        -- Hover Logic
        Btn.MouseEnter:Connect(function()
            TweenService:Create(Btn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Current.Hover, TextColor3 = Theme.Current.Accent}):Play()
        end)
        Btn.MouseLeave:Connect(function()
            TweenService:Create(Btn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Current.ElementBackground, TextColor3 = Theme.Current.Text}):Play()
        end)
    end
    
    -- Update Canvas Size
    self.Scroll.CanvasSize = UDim2.new(0, 0, 0, (#list * (ITEM_HEIGHT + 4)))
end

--[[
    [METHOD] Select
]]
function Dropdown:Select(option)
    self.CurrentOption = option
    self.ValueLabel.Text = tostring(option)
    self.Callback(option)
    self:Toggle() -- Close
end

--[[
    [METHOD] Destroy
]]
function Dropdown:Destroy()
    if self.Instance then self.Instance:Destroy() end
    setmetatable(self, nil)
end

return Dropdown