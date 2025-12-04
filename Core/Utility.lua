--[[
    [MODULE] Core/Utility.lua
    [ARCHITECT] Lead UI Architect
    [SYSTEM] Sirius Rayfield | Utility Belt
    [VERSION] 2.1.0
    
    [DESCRIPTION]
    Helper functions for UI interactions, File I/O, and Input Management.
]]

local Utility = {}

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

function Utility.RandomString(length)
    local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local str = ""
    for i = 1, length do
        local r = math.random(1, #chars)
        str = str .. string.sub(chars, r, r)
    end
    return str
end

--[[
    [FUNCTION] MakeDraggable
    Enables drag behavior on a UI frame.
    Delta Optimized: Supports Touch input.
]]
function Utility.MakeDraggable(Trigger, Object)
    local Dragging = false
    local DragInput, DragStart, StartPos
    
    Trigger.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            Dragging = true
            DragStart = input.Position
            StartPos = Object.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    Dragging = false
                end
            end)
        end
    end)
    
    Trigger.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            DragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == DragInput and Dragging then
            local Delta = input.Position - DragStart
            local NewPos = UDim2.new(
                StartPos.X.Scale, StartPos.X.Offset + Delta.X,
                StartPos.Y.Scale, StartPos.Y.Offset + Delta.Y
            )
            
            TweenService:Create(Object, TweenInfo.new(0.05), {Position = NewPos}):Play()
        end
    end)
end

--[[
    [FUNCTION] Log
    Prints formatted logs.
]]
function Utility.Log(Type, Message)
    local Color = ""
    if Type == "Error" then Color = "🛑"
    elseif Type == "Warning" then Color = "⚠️"
    else Color = "ℹ️" end
    
    print(string.format("[%s Rayfield]: %s %s", Color, Type, Message))
end

return Utility