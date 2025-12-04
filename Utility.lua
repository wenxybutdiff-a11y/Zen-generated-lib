--[[
    [MODULE] Utility.lua
    [ARCHITECT] Lead UI Architect
    [SYSTEM] Sirius Rayfield Core Utilities
    [VERSION] 3.5.0-DeltaOptimized
    [TARGET] Delta Executor / Fluxus / Hydrogen / Roblox Luau

    [DESCRIPTION]
    This module serves as the foundational utility layer for the UI Library.
    It abstracts complex interactions with the Roblox API, handles file system operations
    safely across different executors, manages user input, and provides mathematical
    and color manipulation tools.

    [COMPATIBILITY]
    - Optimized for Delta Executor (Level 7/8).
    - Includes polyfills for standard Roblox Studio testing.
    - Secure Gui Mounting (GetHui/ProtectGui).
]]

local Utility = {}

--// -----------------------------------------------------------------------------
--// 1. SERVICES
--// -----------------------------------------------------------------------------
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

--// -----------------------------------------------------------------------------
--// 2. EXECUTOR COMPATIBILITY & ENVIRONMENT
--// -----------------------------------------------------------------------------
Utility.Executor = (identifyexecutor and identifyexecutor()) or "Unknown"

-- Check for File System support
local hasFileSystem = (isfile and writefile and readfile and isfolder and makefolder and delfolder)
if not hasFileSystem then
    warn("[Rayfield::Utility] File System functions missing. Config saving will be disabled.")
end

-- Secure GUI Parent
function Utility.GetUIContainer()
    local success, result = pcall(function()
        -- Attempt to use gethui() for hidden UI containment (anti-detection)
        if gethui then
            return gethui()
        elseif syn and syn.protect_gui then
            local sg = Instance.new("ScreenGui")
            syn.protect_gui(sg)
            sg.Parent = CoreGui
            return sg
        else
            return CoreGui
        end
    end)
    
    if success and result then
        return result
    else
        return LocalPlayer:WaitForChild("PlayerGui")
    end
end

--// -----------------------------------------------------------------------------
--// 3. LOGGING SYSTEM
--// -----------------------------------------------------------------------------
function Utility.Log(logType, message)
    local prefix = "[Rayfield]"
    local timeStamp = os.date("%X")
    
    if logType == "Info" then
        print(string.format("%s [INFO] [%s]: %s", prefix, timeStamp, tostring(message)))
    elseif logType == "Warn" then
        warn(string.format("%s [WARN] [%s]: %s", prefix, timeStamp, tostring(message)))
    elseif logType == "Error" then
        error(string.format("%s [ERROR] [%s]: %s", prefix, timeStamp, tostring(message)))
    end
end

--// -----------------------------------------------------------------------------
--// 4. INSTANCE & CREATION WRAPPERS
--// -----------------------------------------------------------------------------

--[[
    Create
    A wrapper for Instance.new that sets properties immediately.
    Example: Utility.Create("Frame", { Size = UDim2.new(1,0,1,0), Parent = gui })
]]
function Utility.Create(className, properties)
    local instance = Instance.new(className)
    local children = properties.Children or {}
    properties.Children = nil -- Remove children from props to avoid error

    -- Apply properties
    for property, value in pairs(properties) do
        -- Handle Signal Connections if passed as property
        if property == "Event" or property == "Events" then
            for eventName, callback in pairs(value) do
                instance[eventName]:Connect(callback)
            end
        else
            instance[property] = value
        end
    end

    -- Parent Children
    for _, child in ipairs(children) do
        child.Parent = instance
    end

    return instance
end

-- Helper to add standard UICorner
function Utility.AddCorner(instance, radius)
    return Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, radius or 6),
        Parent = instance
    })
end

-- Helper to add UIStroke
function Utility.AddStroke(instance, color, thickness, transparency)
    return Utility.Create("UIStroke", {
        Color = color or Color3.fromRGB(50, 50, 50),
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        Parent = instance,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    })
end

-- Helper to add UIPadding
function Utility.AddPadding(instance, uniformSize)
    local size = UDim.new(0, uniformSize or 5)
    return Utility.Create("UIPadding", {
        PaddingTop = size,
        PaddingBottom = size,
        PaddingLeft = size,
        PaddingRight = size,
        Parent = instance
    })
end

--// -----------------------------------------------------------------------------
--// 5. ANIMATION & VISUALS
--// -----------------------------------------------------------------------------

-- Wrapper for TweenService
function Utility.Tween(instance, tweenInfo, properties, callback)
    local tween = TweenService:Create(instance, tweenInfo, properties)
    tween:Play()
    
    if callback then
        tween.Completed:Connect(callback)
    end
    
    return tween
end

-- Material Design Ripple Effect
function Utility.CreateRipple(object, color)
    color = color or Color3.fromRGB(255, 255, 255)
    
    -- Ensure ClipsDescendants is on
    object.ClipsDescendants = true
    
    local ripple = Utility.Create("ImageLabel", {
        Name = "Ripple",
        Parent = object,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Image = "rbxassetid://266543268", -- Circle texture
        ImageColor3 = color,
        ImageTransparency = 0.8,
        ZIndex = 9
    })
    
    -- Calculate start position (Mouse relative to object)
    local mouseLoc = UserInputService:GetMouseLocation()
    local objectPos = object.AbsolutePosition
    local x = mouseLoc.X - objectPos.X
    local y = mouseLoc.Y - objectPos.Y - 36 -- Account for TopBar inset if necessary
    
    ripple.Position = UDim2.new(0, x, 0, y)
    ripple.Size = UDim2.new(0, 0, 0, 0)
    
    -- Animate
    local maxSize = math.max(object.AbsoluteSize.X, object.AbsoluteSize.Y) * 1.5
    
    Utility.Tween(ripple, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, maxSize, 0, maxSize),
        Position = UDim2.new(0, x - maxSize/2, 0, y - maxSize/2),
        ImageTransparency = 1
    }, function()
        ripple:Destroy()
    end)
end

-- Pop effect for opening windows/modals
function Utility.PopEffect(frame, duration)
    frame.Size = UDim2.new(0, 0, 0, 0)
    frame.Visible = true
    -- We assume the target size is stored or recalculated, 
    -- but for a generic pop we scale from 0 to 1 scale relative to parent or use a stored UDIm2.
    -- This is a simple scale pop:
    
    local endScale = frame:GetAttribute("TargetSize") or UDim2.new(1,0,1,0) -- requires attribute setting elsewhere
    -- If no attribute, we just tween transparency for safety
end

--// -----------------------------------------------------------------------------
--// 6. INTERACTION & INPUT
--// -----------------------------------------------------------------------------

-- Make a frame draggable
function Utility.MakeDraggable(frame, handle)
    handle = handle or frame
    
    local dragging = false
    local dragInput, mousePos, framePos

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            mousePos = input.Position
            framePos = frame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - mousePos
            local newPos = UDim2.new(
                framePos.X.Scale, 
                framePos.X.Offset + delta.X, 
                framePos.Y.Scale, 
                framePos.Y.Offset + delta.Y
            )
            
            Utility.Tween(frame, TweenInfo.new(0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                Position = newPos
            })
        end
    end)
end

-- Get readable string from KeyCode
function Utility.FormatKey(keyCode)
    if not keyCode then return "None" end
    
    local str = keyCode.Name
    
    -- Common Replacements for cleaner UI
    local replacements = {
        ["LeftControl"] = "L-Ctrl",
        ["RightControl"] = "R-Ctrl",
        ["LeftShift"] = "L-Shift",
        ["RightShift"] = "R-Shift",
        ["MouseButton1"] = "M1",
        ["MouseButton2"] = "M2",
        ["MouseButton3"] = "M3",
    }
    
    return replacements[str] or str
end

function Utility.IsMouseOver(frame)
    if not frame then return false end
    local mLoc = UserInputService:GetMouseLocation()
    local fPos = frame.AbsolutePosition
    local fSize = frame.AbsoluteSize
    
    return mLoc.X >= fPos.X and mLoc.X <= fPos.X + fSize.X
       and mLoc.Y >= fPos.Y and mLoc.Y <= fPos.Y + fSize.Y
end

--// -----------------------------------------------------------------------------
--// 7. MATH & COLOR UTILITIES
--// -----------------------------------------------------------------------------

function Utility.Lerp(a, b, t)
    return a + (b - a) * t
end

function Utility.Map(value, inMin, inMax, outMin, outMax)
    return (value - inMin) * (outMax - outMin) / (inMax - inMin) + outMin
end

-- Converts Color3 to Hex String
function Utility.ColorToHex(color)
    local r, g, b = math.floor(color.R * 255), math.floor(color.G * 255), math.floor(color.B * 255)
    return string.format("#%02X%02X%02X", r, g, b)
end

-- Converts Hex String to Color3
function Utility.HexToColor(hex)
    hex = hex:gsub("#","")
    local r = tonumber("0x"..hex:sub(1,2))
    local g = tonumber("0x"..hex:sub(3,4))
    local b = tonumber("0x"..hex:sub(5,6))
    return Color3.fromRGB(r, g, b)
end

-- Lightens a color by amount (0-1)
function Utility.Lighten(color, amount)
    local h, s, v = color:ToHSV()
    return Color3.fromHSV(h, s, math.clamp(v + amount, 0, 1))
end

-- Darkens a color by amount (0-1)
function Utility.Darken(color, amount)
    local h, s, v = color:ToHSV()
    return Color3.fromHSV(h, s, math.clamp(v - amount, 0, 1))
end

-- Check text bounds for dynamic sizing
function Utility.GetTextSize(text, font, size, fitWidth)
    local tempService = game:GetService("TextService")
    return tempService:GetTextSize(text, size, font, Vector2.new(fitWidth, 10000))
end

--// -----------------------------------------------------------------------------
--// 8. FILE SYSTEM & CONFIGURATION (Delta Optimized)
--// -----------------------------------------------------------------------------

function Utility.SaveConfig(name, tableData)
    if not hasFileSystem then return end
    
    local json = HttpService:JSONEncode(tableData)
    local fileName = name .. ".json"
    
    -- Delta requires specific folder structures sometimes, but usually writefile works in root workspace
    -- or a specific workspace folder.
    
    -- Ensure folder exists (if applicable)
    if not isfolder("Rayfield") then
        makefolder("Rayfield")
    end
    
    writefile("Rayfield/" .. fileName, json)
    Utility.Log("Info", "Configuration saved: " .. fileName)
end

function Utility.LoadConfig(name)
    if not hasFileSystem then return {} end
    
    local fileName = "Rayfield/" .. name .. ".json"
    
    if isfile(fileName) then
        local content = readfile(fileName)
        local success, result = pcall(function()
            return HttpService:JSONDecode(content)
        end)
        
        if success then
            return result
        else
            Utility.Log("Error", "Failed to decode JSON for config: " .. name)
            return {}
        end
    else
        Utility.Log("Warn", "Config file not found: " .. name)
        return {}
    end
end

function Utility.DeleteConfig(name)
    if not hasFileSystem then return end
    local fileName = "Rayfield/" .. name .. ".json"
    if isfile(fileName) then
        delfile(fileName)
    end
end

--// -----------------------------------------------------------------------------
--// 9. CLEANUP & DESTRUCTION
--// -----------------------------------------------------------------------------

-- A table to hold connections that need to be cleaned up on library unload
Utility.Connections = {}

function Utility.Connect(signal, callback)
    local conn = signal:Connect(callback)
    table.insert(Utility.Connections, conn)
    return conn
end

function Utility.Destroy()
    Utility.Log("Info", "Destroying Utility connections...")
    for _, conn in ipairs(Utility.Connections) do
        if conn and conn.Disconnect then
            conn:Disconnect()
        end
    end
    Utility.Connections = {}
end

--// -----------------------------------------------------------------------------
--// 10. GENERATION & RANDOMIZATION
--// -----------------------------------------------------------------------------

function Utility.RandomString(length)
    local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local str = ""
    for i = 1, length do
        local rand = math.random(1, #chars)
        str = str .. string.sub(chars, rand, rand)
    end
    return str
end

-- Unique ID generator for Elements
function Utility.GenerateID()
    return Utility.RandomString(8) .. "-" .. os.time()
end

--// -----------------------------------------------------------------------------
--// 11. DELTA/FLUXUS SAFE WRAPPERS
--// -----------------------------------------------------------------------------

-- Safe way to get global environment variable
function Utility.GetEnv()
    return (getgenv and getgenv()) or _G
end

-- Check if we can draw on screen (for visualizers later)
function Utility.CanDraw()
    return Drawing and Drawing.new
end

return Utility