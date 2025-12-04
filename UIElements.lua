--[[
    [MODULE] UIElements.lua
    [ARCHITECT] Lead UI Architect
    [SYSTEM] Sirius Rayfield Component Factory
    [VERSION] 2.1.0-Production
    
    [DESCRIPTION]
        This module serves as the abstraction layer between the logic core and the Sirius Rayfield Interface.
        It standardizes the creation of UI components (Buttons, Toggles, Sliders, etc.), ensures 
        type safety, manages state flags automatically, and provides a central registry for 
        config saving/loading.

    [DEPENDENCIES]
        - Utility.lua (For logging, deep copying, and validation helpers)
        - Rayfield (The global library instance, expected to be initialized in Main)

    [TARGET EXECUTOR]
        - Delta, Fluxus, Hydrogen, Synapse Z
]]

local UIElements = {}
UIElements.__index = UIElements

--// SERVICES
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

--// IMPORTS
-- Safely attempt to require Utility, fallback if running in a raw environment
local Utility
local success, result = pcall(function()
    return require(script.Parent.Utility)
end)
if success then
    Utility = result
else
    -- Minimal fallback if Utility is missing during isolated testing
    Utility = {
        Log = function(type, msg) print(string.upper(type) .. ": " .. msg) end,
        GenerateGUID = function() return HttpService:GenerateGUID(false) end
    }
end

--// STATE REGISTRY
-- Stores references to all created elements for bulk operations and state management
UIElements.Registry = {}
UIElements.Flags = {} -- Maps Flag String -> Element Object
UIElements.Tabs = {} -- Maps Tab Name -> Tab Object

--// CONSTANTS
local DEFAULT_TOGGLE_STATE = false
local DEFAULT_SLIDER_RANGE = {0, 100}
local DEFAULT_SLIDER_INCREMENT = 1
local ERROR_COLOR = Color3.fromRGB(255, 50, 50)

--[[
    [HELPER] ValidateConfig
    Ensures the configuration table passed to an element contains necessary keys.
    Returns a sanitized config table with defaults applied.
]]
local function ValidateConfig(elementType, config, requiredKeys)
    config = config or {}
    
    -- basic validation
    for _, key in ipairs(requiredKeys) do
        if config[key] == nil then
            Utility.Log("warning", string.format("UIElements: %s missing required key '%s'. Using default.", elementType, key))
            config[key] = "Unknown " .. elementType
        end
    end

    -- Auto-Generate Flag if missing
    if not config.Flag then
        -- Create a safe flag name from the element name
        local safeName = string.gsub(config.Name or "Element", "%s+", "")
        config.Flag = safeName .. "_" .. Utility.GenerateGUID()
    end

    -- Register flag to prevent collisions (simple check)
    if UIElements.Flags[config.Flag] then
        Utility.Log("warning", "UIElements: Duplicate Flag detected '"..config.Flag.."'. Appending GUID.")
        config.Flag = config.Flag .. "_" .. Utility.GenerateGUID()
    end

    return config
end

--[[
    [HELPER] WrapCallback
    Wraps the user-provided callback function with error handling (pcall).
    Prevents the UI from crashing if a script error occurs within a button press.
]]
local function WrapCallback(func, elementName)
    return function(...)
        if not func then return end
        local args = {...}
        local success, err = pcall(function()
            func(unpack(args))
        end)
        
        if not success then
            Utility.Log("error", string.format("Error in %s callback: %s", elementName, tostring(err)))
        end
    end
end

--================================================================================
-- ELEMENT CREATORS
--================================================================================

--[[
    [FUNCTION] UIElements:CreateButton
    Creates a standard clickable button.
    
    @param parent (Table) - The Rayfield Tab or Section object.
    @param config (Table) - { Name, Callback }
]]
function UIElements:CreateButton(parent, config)
    config = ValidateConfig("Button", config, {"Name", "Callback"})
    
    -- Wrap callback for safety
    local originalCallback = config.Callback
    config.Callback = WrapCallback(originalCallback, config.Name)

    local button
    local success, err = pcall(function()
        button = parent:CreateButton({
            Name = config.Name,
            Callback = config.Callback,
            Interact = config.Interact or 'Click', -- Optional Rayfield property
        })
    end)

    if not success then
        Utility.Log("error", "Failed to create Button: " .. tostring(err))
        return nil
    end

    -- Register
    local elementData = {
        Type = "Button",
        Instance = button,
        Config = config
    }
    -- Buttons don't typically have state flags to save, but we track them
    table.insert(UIElements.Registry, elementData)
    
    return button
end

--[[
    [FUNCTION] UIElements:CreateToggle
    Creates a boolean switch.
    
    @param parent (Table) - The Rayfield Tab or Section object.
    @param config (Table) - { Name, CurrentValue, Flag, Callback }
]]
function UIElements:CreateToggle(parent, config)
    config = ValidateConfig("Toggle", config, {"Name"})
    
    -- Defaults
    if config.CurrentValue == nil then config.CurrentValue = DEFAULT_TOGGLE_STATE end
    
    local originalCallback = config.Callback
    config.Callback = function(newValue)
        -- Update internal flag registry immediately
        UIElements.Flags[config.Flag] = newValue
        
        if originalCallback then
            WrapCallback(originalCallback, config.Name)(newValue)
        end
    end

    local toggle
    local success, err = pcall(function()
        toggle = parent:CreateToggle({
            Name = config.Name,
            CurrentValue = config.CurrentValue,
            Flag = config.Flag,
            Callback = config.Callback,
        })
    end)

    if not success then
        Utility.Log("error", "Failed to create Toggle: " .. tostring(err))
        return nil
    end

    -- Register
    UIElements.Flags[config.Flag] = config.CurrentValue -- Initial state
    table.insert(UIElements.Registry, {
        Type = "Toggle",
        Instance = toggle,
        Config = config,
        Flag = config.Flag
    })

    return toggle
end

--[[
    [FUNCTION] UIElements:CreateSlider
    Creates a numerical slider.
    
    @param parent (Table) - The Rayfield Tab or Section object.
    @param config (Table) - { Name, Range, Increment, Suffix, CurrentValue, Flag, Callback }
]]
function UIElements:CreateSlider(parent, config)
    config = ValidateConfig("Slider", config, {"Name"})
    
    -- Defaults
    config.Range = config.Range or DEFAULT_SLIDER_RANGE
    config.Increment = config.Increment or DEFAULT_SLIDER_INCREMENT
    config.Suffix = config.Suffix or ""
    config.CurrentValue = config.CurrentValue or config.Range[1]
    
    local originalCallback = config.Callback
    config.Callback = function(newValue)
        UIElements.Flags[config.Flag] = newValue
        if originalCallback then
            WrapCallback(originalCallback, config.Name)(newValue)
        end
    end

    local slider
    local success, err = pcall(function()
        slider = parent:CreateSlider({
            Name = config.Name,
            Range = config.Range,
            Increment = config.Increment,
            Suffix = config.Suffix,
            CurrentValue = config.CurrentValue,
            Flag = config.Flag,
            Callback = config.Callback,
        })
    end)

    if not success then
        Utility.Log("error", "Failed to create Slider: " .. tostring(err))
        return nil
    end

    UIElements.Flags[config.Flag] = config.CurrentValue
    table.insert(UIElements.Registry, {
        Type = "Slider",
        Instance = slider,
        Config = config,
        Flag = config.Flag
    })

    return slider
end

--[[
    [FUNCTION] UIElements:CreateInput
    Creates a text input field.
    
    @param parent (Table) - The Rayfield Tab or Section object.
    @param config (Table) - { Name, PlaceholderText, NumbersOnly, OnEnter, RemoveTextAfterFocusLost, Callback }
]]
function UIElements:CreateInput(parent, config)
    config = ValidateConfig("Input", config, {"Name"})
    
    config.PlaceholderText = config.PlaceholderText or "Input..."
    config.RemoveTextAfterFocusLost = config.RemoveTextAfterFocusLost or false
    
    local originalCallback = config.Callback
    config.Callback = function(text)
        -- Sanitization could happen here if needed
        if config.NumbersOnly and not tonumber(text) then
            return -- reject non-numbers silently or warn
        end
        
        UIElements.Flags[config.Flag] = text
        if originalCallback then
            WrapCallback(originalCallback, config.Name)(text)
        end
    end

    local input
    local success, err = pcall(function()
        input = parent:CreateInput({
            Name = config.Name,
            PlaceholderText = config.PlaceholderText,
            RemoveTextAfterFocusLost = config.RemoveTextAfterFocusLost,
            Callback = config.Callback,
            Flag = config.Flag -- Inputs utilize flags in updated Rayfield versions
        })
    end)

    if not success then
        Utility.Log("error", "Failed to create Input: " .. tostring(err))
        return nil
    end

    table.insert(UIElements.Registry, {
        Type = "Input",
        Instance = input,
        Config = config,
        Flag = config.Flag
    })

    return input
end

--[[
    [FUNCTION] UIElements:CreateDropdown
    Creates a selection dropdown.
    
    @param parent (Table) - The Rayfield Tab or Section object.
    @param config (Table) - { Name, Options, CurrentOption, MultipleOptions, Flag, Callback }
]]
function UIElements:CreateDropdown(parent, config)
    config = ValidateConfig("Dropdown", config, {"Name", "Options"})
    
    -- Ensure Options is a table
    if type(config.Options) ~= "table" then
        Utility.Log("error", "UIElements: Dropdown options must be a table.")
        config.Options = {"Error"}
    end

    -- Default selection
    if not config.CurrentOption then
        if type(config.Options[1]) == "string" then
            config.CurrentOption = config.Options[1]
        else
            -- If options are complex, just stringify
            config.CurrentOption = tostring(config.Options[1])
        end
    end
    
    -- Handle MultipleOptions flag from newer Rayfield versions
    local isMulti = config.MultipleOptions or false

    local originalCallback = config.Callback
    config.Callback = function(option)
        -- 'option' can be a table if MultipleOptions is true
        UIElements.Flags[config.Flag] = option
        if originalCallback then
            WrapCallback(originalCallback, config.Name)(option)
        end
    end

    local dropdown
    local success, err = pcall(function()
        dropdown = parent:CreateDropdown({
            Name = config.Name,
            Options = config.Options,
            CurrentOption = config.CurrentOption,
            MultipleOptions = isMulti,
            Flag = config.Flag,
            Callback = config.Callback,
        })
    end)

    if not success then
        Utility.Log("error", "Failed to create Dropdown: " .. tostring(err))
        return nil
    end

    UIElements.Flags[config.Flag] = config.CurrentOption
    table.insert(UIElements.Registry, {
        Type = "Dropdown",
        Instance = dropdown,
        Config = config,
        Flag = config.Flag
    })

    return dropdown
end

--[[
    [FUNCTION] UIElements:CreateColorPicker
    Creates a color selection tool.
    
    @param parent (Table) - The Rayfield Tab or Section object.
    @param config (Table) - { Name, Color, Flag, Callback }
]]
function UIElements:CreateColorPicker(parent, config)
    config = ValidateConfig("ColorPicker", config, {"Name"})
    
    config.Color = config.Color or Color3.fromRGB(255, 255, 255)
    
    local originalCallback = config.Callback
    config.Callback = function(color)
        UIElements.Flags[config.Flag] = color
        if originalCallback then
            WrapCallback(originalCallback, config.Name)(color)
        end
    end

    local picker
    local success, err = pcall(function()
        picker = parent:CreateColorPicker({
            Name = config.Name,
            Color = config.Color,
            Flag = config.Flag,
            Callback = config.Callback,
        })
    end)

    if not success then
        Utility.Log("error", "Failed to create ColorPicker: " .. tostring(err))
        return nil
    end

    UIElements.Flags[config.Flag] = config.Color
    table.insert(UIElements.Registry, {
        Type = "ColorPicker",
        Instance = picker,
        Config = config,
        Flag = config.Flag
    })

    return picker
end

--[[
    [FUNCTION] UIElements:CreateKeybind
    Creates a keybinding assignment element.
    
    @param parent (Table) - The Rayfield Tab or Section object.
    @param config (Table) - { Name, CurrentKeybind, HoldToInteract, Flag, Callback }
]]
function UIElements:CreateKeybind(parent, config)
    config = ValidateConfig("Keybind", config, {"Name"})
    
    config.CurrentKeybind = config.CurrentKeybind or Enum.KeyCode.E
    config.HoldToInteract = config.HoldToInteract or false
    
    local originalCallback = config.Callback
    config.Callback = function(inputState)
        -- inputState is usually passed by Rayfield keybinds? 
        -- Actually Rayfield usually just fires on press unless HoldToInteract is on.
        if originalCallback then
            WrapCallback(originalCallback, config.Name)(inputState)
        end
    end

    local keybind
    local success, err = pcall(function()
        keybind = parent:CreateKeybind({
            Name = config.Name,
            CurrentKeybind = config.CurrentKeybind,
            HoldToInteract = config.HoldToInteract,
            Flag = config.Flag,
            Callback = config.Callback,
        })
    end)

    if not success then
        Utility.Log("error", "Failed to create Keybind: " .. tostring(err))
        return nil
    end

    -- We store the Enum code in flags for saving
    UIElements.Flags[config.Flag] = config.CurrentKeybind
    table.insert(UIElements.Registry, {
        Type = "Keybind",
        Instance = keybind,
        Config = config,
        Flag = config.Flag
    })

    return keybind
end

--[[
    [FUNCTION] UIElements:CreateLabel
    Creates a text label.
    
    @param parent (Table) - The Rayfield Tab or Section object.
    @param config (Table) - { Text, Color } OR string "Text"
]]
function UIElements:CreateLabel(parent, config)
    local text = "Label"
    local color = nil
    
    if type(config) == "string" then
        text = config
    elseif type(config) == "table" then
        text = config.Text or "Label"
        color = config.Color
    end

    local label
    local success, err = pcall(function()
        label = parent:CreateLabel(text)
        if color and label and label.Set then 
            -- Some versions of Rayfield allow setting props immediately, 
            -- otherwise we might need to access the instance directly if returned
            label:Set(text, color) 
        end
    end)

    if not success then
        Utility.Log("error", "Failed to create Label: " .. tostring(err))
        return nil
    end
    
    return label
end

--[[
    [FUNCTION] UIElements:CreateParagraph
    Creates a header + content text block.
    
    @param parent (Table) - The Rayfield Tab or Section object.
    @param config (Table) - { Title, Content }
]]
function UIElements:CreateParagraph(parent, config)
    config = ValidateConfig("Paragraph", config, {"Title"})
    config.Content = config.Content or ""

    local paragraph
    local success, err = pcall(function()
        paragraph = parent:CreateParagraph({
            Title = config.Title,
            Content = config.Content
        })
    end)

    if not success then
        Utility.Log("error", "Failed to create Paragraph: " .. tostring(err))
        return nil
    end
    
    return paragraph
end

--================================================================================
-- CONFIGURATION MANAGEMENT
--================================================================================

--[[
    [FUNCTION] UIElements:GetConfiguration
    Exports a serializable table of all current UI states (Flags).
    Useful for saving settings to a file.
]]
function UIElements:GetConfiguration()
    local export = {}
    for flag, value in pairs(UIElements.Flags) do
        -- Convert Enums and Color3s to serializable formats
        if typeof(value) == "EnumItem" then
            export[flag] = {__type = "Enum", value = tostring(value)}
        elseif typeof(value) == "Color3" then
            export[flag] = {__type = "Color3", r=value.R, g=value.G, b=value.B}
        else
            export[flag] = value
        end
    end
    return export
end

--[[
    [FUNCTION] UIElements:LoadConfiguration
    Loads a configuration table and updates the UI elements.
    
    @param configData (Table) - The loaded data from file.
]]
function UIElements:LoadConfiguration(configData)
    if type(configData) ~= "table" then return end
    
    for flag, value in pairs(configData) do
        -- Restore complex types
        local restoredValue = value
        if type(value) == "table" and value.__type then
            if value.__type == "Enum" then
                -- Try to find the EnumItem (simplified, assumes KeyCode for now)
                -- Parsing "Enum.KeyCode.E" -> E
                local parts = string.split(value.value, ".")
                if parts[3] and Enum.KeyCode[parts[3]] then
                    restoredValue = Enum.KeyCode[parts[3]]
                end
            elseif value.__type == "Color3" then
                restoredValue = Color3.new(value.r, value.g, value.b)
            end
        end
        
        -- Update the UI Element via Rayfield's Set method if possible
        -- Or just update the internal state
        UIElements.Flags[flag] = restoredValue
        
        -- Find the element instance
        for _, el in ipairs(UIElements.Registry) do
            if el.Flag == flag and el.Instance then
                -- Most Rayfield elements have a :Set(val) method
                pcall(function()
                    if el.Type == "Toggle" or el.Type == "Slider" or el.Type == "Input" or el.Type == "Dropdown" or el.Type == "ColorPicker" then
                        el.Instance:Set(restoredValue)
                    end
                end)
            end
        end
    end
    
    Utility.Log("success", "Configuration loaded successfully.")
end

--[[
    [FUNCTION] UIElements:Destroy
    Cleans up all references.
]]
function UIElements:Destroy()
    UIElements.Registry = {}
    UIElements.Flags = {}
    UIElements.Tabs = {}
end

Utility.Log("info", "UIElements Module Loaded")

return UIElements