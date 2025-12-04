--[[
    TabHandler.lua
    Author: Lead Architect
    Description: 
        Manages the creation, lifecycle, and element organization of UI Tabs within the Sirius Rayfield environment.
        Acts as a high-level wrapper around the Rayfield 'CreateTab' API, offering enhanced state tracking,
        input validation, and strict typing for robust integration with Delta Executor.
    
    Dependencies:
        - Config.lua (Theme and default settings)
        - Elements.lua (Factory for individual UI components)
        - Utility.lua (Helper functions for logging and validation)
]]

local TabHandler = {}
TabHandler.__index = TabHandler

--// Services
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

--// Dependencies (Dynamic Loading for Architecture Flexibility)
local function safeRequire(moduleName)
    local success, result = pcall(function()
        return require(script.Parent:FindFirstChild(moduleName))
    end)
    if success then return result end
    return nil
end

local Config = safeRequire("Config") or { 
    -- Fallback defaults if Config is missing during partial load
    DebugMode = true,
    DefaultIcon = 4483345998
}
local Elements = safeRequire("Elements")
local Utility = safeRequire("Utility")

--// Types
export type TabObject = {
    Instance: any, -- The Rayfield Tab Instance/Object
    Name: string,
    Icon: string | number,
    Elements: { [string]: any }, -- Registry of elements in this tab
    Sections: { [string]: any }, -- Registry of sections
    IsVisible: boolean
}

export type ElementOptions = {
    Name: string,
    Callback: (any) -> any,
    [any]: any
}

--// Logging Helper
local function log(level: string, message: string)
    if Config.DebugMode then
        print(string.format("[TabHandler] [%s]: %s", level:upper(), message))
    end
end

--// Constructor
-- Creates a new Tab within the provided Rayfield Window
function TabHandler.new(Window: any, name: string, icon: number | string | nil)
    if not Window then
        warn("[TabHandler] Critical Error: Attempted to create tab with nil Window.")
        return nil
    end

    local self = setmetatable({}, TabHandler)
    
    self.Name = name or "Unnamed Tab"
    self.Icon = icon or Config.DefaultIcon
    self.Elements = {}
    self.Sections = {}
    self.IsVisible = true

    -- Safely attempt to create the tab via Rayfield API
    local success, tabInstance = pcall(function()
        return Window:CreateTab(self.Name, self.Icon)
    end)

    if not success or not tabInstance then
        warn("[TabHandler] Failed to create Rayfield Tab: " .. tostring(self.Name))
        return nil
    end

    self.Instance = tabInstance
    log("info", "Successfully created tab: " .. self.Name)

    return self
end

--// SECTION MANAGEMENT

-- Creates a section divider within the tab to organize elements
function TabHandler:CreateSection(name: string)
    if not self.Instance then return end
    
    if not name or type(name) ~= "string" then
        warn("[TabHandler] Invalid section name provided.")
        name = "Section"
    end

    local success, section = pcall(function()
        return self.Instance:CreateSection(name)
    end)

    if success then
        self.Sections[name] = section
        log("info", "Created Section [" .. name .. "] in Tab [" .. self.Name .. "]")
    else
        warn("[TabHandler] Failed to create section: " .. name)
    end
    
    return section
end

--// ELEMENT CREATION WRAPPERS
-- These methods wrap the Elements.lua factories, providing an additional layer of
-- validation and state tracking. This ensures that even if the low-level library updates,
-- our API surface remains consistent.

-- [BUTTON]
function TabHandler:CreateButton(options: { Name: string, Callback: () -> (), Interact: string? })
    -- Validation
    if not options or type(options) ~= "table" then
        warn("[TabHandler] CreateButton: Options table missing.")
        return
    end
    if not options.Name then options.Name = "Button" end
    if not options.Callback then 
        options.Callback = function() 
            log("warning", "Button pressed but no callback defined.") 
        end 
    end

    -- Construct Element
    local elementData = {
        Name = options.Name,
        Callback = options.Callback,
        Interact = options.Interact or "Click"
    }

    local createdElement
    if Elements and Elements.CreateButton then
        -- Delegate to Element Factory
        createdElement = Elements.CreateButton(self.Instance, elementData)
    else
        -- Fallback direct Rayfield call if Elements module is unavailable or bypass requested
        createdElement = self.Instance:CreateButton({
            Name = elementData.Name,
            Callback = elementData.Callback,
        })
    end

    -- Registry
    table.insert(self.Elements, { Type = "Button", Instance = createdElement, Data = elementData })
    return createdElement
end

-- [TOGGLE]
function TabHandler:CreateToggle(options: { Name: string, CurrentValue: boolean, Flag: string?, Callback: (boolean) -> () })
    -- Validation
    if not options or type(options) ~= "table" then return end
    
    local elementData = {
        Name = options.Name or "Toggle",
        CurrentValue = options.CurrentValue or false,
        Flag = options.Flag or (options.Name .. "_Toggle"),
        Callback = options.Callback or function(val) end
    }

    local createdElement
    if Elements and Elements.CreateToggle then
        createdElement = Elements.CreateToggle(self.Instance, elementData)
    else
        createdElement = self.Instance:CreateToggle({
            Name = elementData.Name,
            CurrentValue = elementData.CurrentValue,
            Flag = elementData.Flag,
            Callback = elementData.Callback,
        })
    end

    table.insert(self.Elements, { Type = "Toggle", Instance = createdElement, Data = elementData })
    return createdElement
end

-- [SLIDER]
function TabHandler:CreateSlider(options: { Name: string, Range: {number}, Increment: number, Suffix: string?, CurrentValue: number, Flag: string?, Callback: (number) -> () })
    if not options then return end

    local minVal = options.Range and options.Range[1] or 0
    local maxVal = options.Range and options.Range[2] or 100
    
    local elementData = {
        Name = options.Name or "Slider",
        Range = {minVal, maxVal},
        Increment = options.Increment or 1,
        Suffix = options.Suffix or "",
        CurrentValue = options.CurrentValue or minVal,
        Flag = options.Flag or (options.Name .. "_Slider"),
        Callback = options.Callback or function(val) end
    }

    local createdElement
    if Elements and Elements.CreateSlider then
        createdElement = Elements.CreateSlider(self.Instance, elementData)
    else
        createdElement = self.Instance:CreateSlider({
            Name = elementData.Name,
            Range = elementData.Range,
            Increment = elementData.Increment,
            Suffix = elementData.Suffix,
            CurrentValue = elementData.CurrentValue,
            Flag = elementData.Flag,
            Callback = elementData.Callback,
        })
    end

    table.insert(self.Elements, { Type = "Slider", Instance = createdElement, Data = elementData })
    return createdElement
end

-- [INPUT]
function TabHandler:CreateInput(options: { Name: string, PlaceholderText: string?, RemoveTextAfterFocusLost: boolean?, Callback: (string) -> () })
    if not options then return end

    local elementData = {
        Name = options.Name or "Input",
        PlaceholderText = options.PlaceholderText or "Type here...",
        RemoveTextAfterFocusLost = options.RemoveTextAfterFocusLost or false,
        Callback = options.Callback or function(txt) end
    }

    local createdElement
    if Elements and Elements.CreateInput then
        createdElement = Elements.CreateInput(self.Instance, elementData)
    else
        createdElement = self.Instance:CreateInput({
            Name = elementData.Name,
            PlaceholderText = elementData.PlaceholderText,
            RemoveTextAfterFocusLost = elementData.RemoveTextAfterFocusLost,
            Callback = elementData.Callback,
        })
    end

    table.insert(self.Elements, { Type = "Input", Instance = createdElement, Data = elementData })
    return createdElement
end

-- [DROPDOWN]
function TabHandler:CreateDropdown(options: { Name: string, Options: {string}, CurrentOption: string | {string}, MultipleOptions: boolean?, Flag: string?, Callback: (any) -> () })
    if not options then return end

    local elementData = {
        Name = options.Name or "Dropdown",
        Options = options.Options or {},
        CurrentOption = options.CurrentOption or "",
        MultipleOptions = options.MultipleOptions or false,
        Flag = options.Flag or (options.Name .. "_Dropdown"),
        Callback = options.Callback or function(opt) end
    }

    local createdElement
    if Elements and Elements.CreateDropdown then
        createdElement = Elements.CreateDropdown(self.Instance, elementData)
    else
        createdElement = self.Instance:CreateDropdown({
            Name = elementData.Name,
            Options = elementData.Options,
            CurrentOption = elementData.CurrentOption,
            MultipleOptions = elementData.MultipleOptions,
            Flag = elementData.Flag,
            Callback = elementData.Callback,
        })
    end

    table.insert(self.Elements, { Type = "Dropdown", Instance = createdElement, Data = elementData })
    return createdElement
end

-- [COLOR PICKER]
function TabHandler:CreateColorPicker(options: { Name: string, Color: Color3, Flag: string?, Callback: (Color3) -> () })
    if not options then return end

    local elementData = {
        Name = options.Name or "Color Picker",
        Color = options.Color or Color3.fromRGB(255, 255, 255),
        Flag = options.Flag or (options.Name .. "_ColorPicker"),
        Callback = options.Callback or function(col) end
    }

    local createdElement
    if Elements and Elements.CreateColorPicker then
        createdElement = Elements.CreateColorPicker(self.Instance, elementData)
    else
        createdElement = self.Instance:CreateColorPicker({
            Name = elementData.Name,
            Color = elementData.Color,
            Flag = elementData.Flag,
            Callback = elementData.Callback,
        })
    end

    table.insert(self.Elements, { Type = "ColorPicker", Instance = createdElement, Data = elementData })
    return createdElement
end

-- [KEYBIND]
function TabHandler:CreateKeybind(options: { Name: string, CurrentKeybind: string, HoldToInteract: boolean?, Flag: string?, Callback: (boolean) -> () })
    if not options then return end

    local elementData = {
        Name = options.Name or "Keybind",
        CurrentKeybind = options.CurrentKeybind or "None",
        HoldToInteract = options.HoldToInteract or false,
        Flag = options.Flag or (options.Name .. "_Keybind"),
        Callback = options.Callback or function(bool) end
    }

    local createdElement
    if Elements and Elements.CreateKeybind then
        createdElement = Elements.CreateKeybind(self.Instance, elementData)
    else
        createdElement = self.Instance:CreateKeybind({
            Name = elementData.Name,
            CurrentKeybind = elementData.CurrentKeybind,
            HoldToInteract = elementData.HoldToInteract,
            Flag = elementData.Flag,
            Callback = elementData.Callback,
        })
    end

    table.insert(self.Elements, { Type = "Keybind", Instance = createdElement, Data = elementData })
    return createdElement
end

-- [LABEL]
function TabHandler:CreateLabel(text: string)
    if not text then text = "Label" end

    local createdElement
    if Elements and Elements.CreateLabel then
        createdElement = Elements.CreateLabel(self.Instance, { Text = text })
    else
        createdElement = self.Instance:CreateLabel(text)
    end

    table.insert(self.Elements, { Type = "Label", Instance = createdElement, Data = { Text = text } })
    return createdElement
end

-- [PARAGRAPH]
function TabHandler:CreateParagraph(options: { Title: string, Content: string })
    if not options then return end

    local elementData = {
        Title = options.Title or "Paragraph",
        Content = options.Content or "Content"
    }

    local createdElement
    if Elements and Elements.CreateParagraph then
        createdElement = Elements.CreateParagraph(self.Instance, elementData)
    else
        createdElement = self.Instance:CreateParagraph(elementData)
    end

    table.insert(self.Elements, { Type = "Paragraph", Instance = createdElement, Data = elementData })
    return createdElement
end


--// UTILITY & LIFECYCLE

-- Updates the name of the tab dynamically if supported by underlying Rayfield
-- Note: Rayfield might not support dynamic tab renaming natively in all versions, 
-- so this attempts to access the GUI object if possible.
function TabHandler:SetName(newName: string)
    self.Name = newName
    -- Implementation depends on Rayfield internals; placeholder logic for safety
    pcall(function()
        if self.Instance and self.Instance.TabButton and self.Instance.TabButton.Title then
            self.Instance.TabButton.Title.Text = newName
        end
    end)
end

-- Destroys all elements within the tab (Logic simulation)
-- Since Rayfield doesn't expose a 'ClearTab' easily, we might need to rely on 
-- destroying the actual instances if we have access, or just recreating the window.
-- For this architecture, we will simply flag the elements as destroyed in our registry.
function TabHandler:ClearElements()
    -- In a real scenario, we would loop through self.Elements and call :Destroy() on them
    -- if Rayfield returned Instance wrappers.
    log("info", "Clearing elements registry for Tab: " .. self.Name)
    self.Elements = {}
end

-- Validates that the current execution environment is safe for UI creation
-- Specifically checks for Delta Executor compatibility flags if present in Config
function TabHandler:CheckEnvironment()
    -- Delta Executor specific checks (if any)
    if Config.DeltaCompatibilityMode then
        -- Ensure getgenv exists
        if not getgenv then
            warn("[TabHandler] Delta Executor mode enabled but getgenv() is missing.")
        end
    end
    return true
end

-- Debug: Print all registered elements in this tab
function TabHandler:DebugDump()
    print("=== Tab Debug Dump: " .. self.Name .. " ===")
    for idx, el in pairs(self.Elements) do
        print(string.format("[%d] Type: %s | Name: %s", idx, el.Type, el.Data.Name or "N/A"))
    end
    print("==========================================")
end

-- Returns the raw Rayfield Tab Instance
function TabHandler:GetRawInstance()
    return self.Instance
end

return TabHandler