--[[
    [SCRIPT] Loader.lua
    [ARCHITECT] Lead UI Architect
    [PROJECT] Solaris Hub Enterprise
    [DESCRIPTION] 
        The primary execution entry point for the Solaris Hub. 
        This script orchestrates the UI Library modules, manages global state, 
        injects game logic (Aimbot, ESP, Movement), and handles the lifecycle of the cheat.

    [TARGET ENVIRONMENT]
        - Executor: Delta, Fluxus, Hydrogen, Synapse Z
        - Game Engine: Roblox Luau
        - UI Library: Sirius Rayfield (Custom Modular Build)

    [DEPENDENCIES]
        - Library.lua
        - Utility.lua
        - Config.lua (Implicitly loaded by Library)
]]

--// 1. SERVICES & OPTIMIZATION
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

--// 2. LIBRARY IMPORT
-- In a real execution environment, ensure these files are in the same folder or loaded via loadstring.
local Library = require(script.Parent.Library)
local Utility = require(script.Parent.Utility)

--// 3. GLOBAL STATE & CONFIGURATION
-- This table holds the runtime state of all features.
local Solaris = {
    Version = "2.5.0-Release",
    IsRunning = true,
    Threads = {},
    Connections = {},
    Visuals = {
        Drawings = {}, -- Container for Drawing API objects
        ESP_Container = Instance.new("Folder", CoreGui)
    },
    Settings = {
        -- Combat
        Aimbot = {
            Enabled = false,
            AimLock = false, -- Keybind holding
            Keybind = Enum.KeyCode.E,
            TargetPart = "Head",
            FOV = 150,
            ShowFOV = false,
            Smoothness = 10,
            CheckVisibility = true,
            TeamCheck = true,
            AliveCheck = true
        },
        SilentAim = {
            Enabled = false,
            Chance = 100,
            HeadshotOnly = false
        },
        -- Visuals
        ESP = {
            Enabled = false,
            Boxes = false,
            Tracers = false,
            Names = false,
            Health = false,
            TeamColor = false,
            MaxDistance = 2000,
            BoxColor = Color3.fromRGB(255, 255, 255),
            TracerColor = Color3.fromRGB(255, 255, 255)
        },
        World = {
            Fullbright = false,
            TimeChanger = false,
            Time = 14,
            Ambience = Color3.fromRGB(120, 120, 120)
        },
        -- Movement
        Speed = {
            Enabled = false,
            Value = 16,
            Method = "Humanoid" -- Humanoid or CFrame
        },
        Jump = {
            Enabled = false,
            Value = 50,
            Infinite = false
        },
        Flight = {
            Enabled = false,
            Speed = 1,
            VerticalSpeed = 1,
            Noclip = true
        }
    }
}
Solaris.Visuals.ESP_Container.Name = "Solaris_ESP_Holder"

--// 4. UTILITY FUNCTIONS (GAME LOGIC)

-- [Logic] Safe Member Check
local function IsAlive(plr)
    if not plr or not plr.Character then return false end
    local hum = plr.Character:FindFirstChild("Humanoid")
    local root = plr.Character:FindFirstChild("HumanoidRootPart")
    return hum and hum.Health > 0 and root
end

-- [Logic] Team Check
local function IsEnemy(plr)
    if not Solaris.Settings.Aimbot.TeamCheck then return true end
    if plr.Team == nil then return true end
    return plr.Team ~= LocalPlayer.Team
end

-- [Logic] Get Closest Player to Mouse
local function GetClosestPlayerToMouse()
    local target = nil
    local shortestDistance = Solaris.Settings.Aimbot.FOV
    
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and IsAlive(plr) and IsEnemy(plr) then
            local char = plr.Character
            local part = char:FindFirstChild(Solaris.Settings.Aimbot.TargetPart) or char:FindFirstChild("Head")
            
            if part then
                -- Visibility Check
                local isVisible = true
                if Solaris.Settings.Aimbot.CheckVisibility then
                    local origin = Camera.CFrame.Position
                    local direction = part.Position - origin
                    local rayParams = RaycastParams.new()
                    rayParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera, Solaris.Visuals.ESP_Container}
                    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
                    local result = Workspace:Raycast(origin, direction, rayParams)
                    
                    if result and not result.Instance:IsDescendantOf(char) then
                        isVisible = false
                    end
                end

                if isVisible then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                    if onScreen then
                        local mousePos = Vector2.new(Mouse.X, Mouse.Y)
                        local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                        
                        if dist < shortestDistance then
                            shortestDistance = dist
                            target = char
                        end
                    end
                end
            end
        end
    end
    
    return target
end

-- [Logic] ESP Management
-- Using BillboardGui for cross-executor compatibility (Delta/Mobile often struggle with Drawing API lines)
local function CreateESP(plr)
    if not plr or plr == LocalPlayer then return end
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = plr.Name .. "_ESP"
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(4, 0, 5.5, 0)
    billboard.StudsOffset = Vector3.new(0, 0, 0)
    billboard.Adornee = nil -- Set in loop
    
    local frame = Instance.new("Frame", billboard)
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    
    local stroke = Instance.new("UIStroke", frame)
    stroke.Thickness = 1.5
    stroke.Color = Solaris.Settings.ESP.BoxColor
    stroke.Transparency = 1 -- Hidden by default
    
    local nameLabel = Instance.new("TextLabel", frame)
    nameLabel.Size = UDim2.new(1, 0, 0, 20)
    nameLabel.Position = UDim2.new(0, 0, -0.2, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = plr.Name
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.TextStrokeTransparency = 0
    nameLabel.Visible = false
    
    billboard.Parent = Solaris.Visuals.ESP_Container
    return {Gui = billboard, Stroke = stroke, Name = nameLabel, Player = plr}
end

local ESP_Cache = {}

local function UpdateESP()
    -- Add new players
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and not ESP_Cache[plr] then
            ESP_Cache[plr] = CreateESP(plr)
        end
    end
    
    -- Update existing
    for plr, data in pairs(ESP_Cache) do
        if not plr or not plr.Parent then
            data.Gui:Destroy()
            ESP_Cache[plr] = nil
        elseif Solaris.Settings.ESP.Enabled and IsAlive(plr) then
            local char = plr.Character
            local root = char:FindFirstChild("HumanoidRootPart")
            
            if root then
                local dist = (root.Position - Camera.CFrame.Position).Magnitude
                if dist <= Solaris.Settings.ESP.MaxDistance then
                    data.Gui.Adornee = root
                    data.Gui.Enabled = true
                    
                    -- Box
                    data.Stroke.Transparency = Solaris.Settings.ESP.Boxes and 0 or 1
                    data.Stroke.Color = Solaris.Settings.ESP.BoxColor
                    
                    -- Name
                    data.Name.Visible = Solaris.Settings.ESP.Names
                    data.Name.Text = string.format("%s [%d]", plr.Name, math.floor(dist))
                else
                    data.Gui.Enabled = false
                end
            else
                data.Gui.Enabled = false
            end
        else
            data.Gui.Enabled = false
        end
    end
end

--// 5. MAIN LOOPS
local function MainLoop(dt)
    if not Solaris.IsRunning then return end

    -- Aimbot Logic
    if Solaris.Settings.Aimbot.Enabled and Solaris.Settings.Aimbot.AimLock then
        local target = GetClosestPlayerToMouse()
        if target then
            local part = target[Solaris.Settings.Aimbot.TargetPart]
            -- Smooth LookAt
            local currentCFrame = Camera.CFrame
            local targetCFrame = CFrame.new(currentCFrame.Position, part.Position)
            
            -- Interpolate
            Camera.CFrame = currentCFrame:Lerp(targetCFrame, Solaris.Settings.Aimbot.Smoothness * dt)
        end
    end

    -- Flight Logic (CFrame method)
    if Solaris.Settings.Flight.Enabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = LocalPlayer.Character.HumanoidRootPart
        local camCF = Camera.CFrame
        local speed = Solaris.Settings.Flight.Speed * (dt * 60)
        local bv = Vector3.new()
        
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then bv = bv + camCF.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then bv = bv - camCF.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then bv = bv - camCF.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then bv = bv + camCF.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then bv = bv + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then bv = bv - Vector3.new(0, 1, 0) end
        
        hrp.Velocity = Vector3.new(0,0,0) -- Cancel gravity
        hrp.CFrame = hrp.CFrame + (bv * speed)
    end
end

--// 6. UI CONSTRUCTION
Utility.Log("Info", "Building Interface...")

local Window = Library:CreateWindow({
    Name = "Solaris Hub | Enterprise Edition",
    LoadingTitle = "Initializing Core...",
    LoadingSubtitle = "Authenticating User...",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "SolarisHub",
        FileName = "SolarisConfig_V2"
    },
    Discord = {
        Enabled = true,
        Invite = "solaris-community", -- Example
        RememberJoins = true
    },
    KeySystem = false -- Disabled for ease of use in this demo
})

-- [TAB] Combat
local CombatTab = Window:CreateTab("Combat", 4483362458)

local AimSec = CombatTab:CreateSection("Aimbot Settings")

CombatTab:CreateToggle({
    Name = "Enable Aimbot",
    CurrentValue = false,
    Flag = "AimEnabled",
    Callback = function(v) Solaris.Settings.Aimbot.Enabled = v end
})

CombatTab:CreateKeybind({
    Name = "Aim Key",
    CurrentKeybind = "E",
    HoldToInteract = true,
    Flag = "AimKey",
    Callback = function(key) 
        -- Rayfield HoldToInteract handles state internally usually, 
        -- but we can track pressing manually if needed.
        Solaris.Settings.Aimbot.AimLock = true -- KeyDown
    end
    -- Note: Rayfield Keybind callback behavior varies. 
    -- Often better to use UserInputService manually for complex hold logic linked to the key.
})

-- Manual Input Hook for Aim Key (More reliable for Hold)
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Solaris.Settings.Aimbot.Keybind then
        Solaris.Settings.Aimbot.AimLock = true
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Solaris.Settings.Aimbot.Keybind then
        Solaris.Settings.Aimbot.AimLock = false
    end
end)

CombatTab:CreateSlider({
    Name = "FOV Radius",
    Range = {10, 800},
    Increment = 10,
    Suffix = "px",
    CurrentValue = 150,
    Flag = "AimFOV",
    Callback = function(v) Solaris.Settings.Aimbot.FOV = v end
})

CombatTab:CreateSlider({
    Name = "Smoothness",
    Range = {0.1, 1}, -- Lerp alpha usually 0-1, but we used dt multiplier earlier. Let's adjust.
    -- If using Lerp(a, b, alpha), alpha 1 is instant.
    -- Let's stick to a factor.
    Increment = 0.05,
    Suffix = "Step",
    CurrentValue = 0.2,
    Flag = "AimSmooth",
    Callback = function(v) Solaris.Settings.Aimbot.Smoothness = v end
})

CombatTab:CreateToggle({
    Name = "Visibility Check",
    CurrentValue = true,
    Flag = "AimWallCheck",
    Callback = function(v) Solaris.Settings.Aimbot.CheckVisibility = v end
})

-- [TAB] Visuals
local VisTab = Window:CreateTab("Visuals", 4483362458)
local ESPSection = VisTab:CreateSection("ESP Settings")

VisTab:CreateToggle({
    Name = "Master ESP Switch",
    CurrentValue = false,
    Flag = "ESPMaster",
    Callback = function(v) Solaris.Settings.ESP.Enabled = v end
})

VisTab:CreateToggle({
    Name = "Show Boxes",
    CurrentValue = false,
    Flag = "ESPBoxes",
    Callback = function(v) Solaris.Settings.ESP.Boxes = v end
})

VisTab:CreateToggle({
    Name = "Show Names",
    CurrentValue = false,
    Flag = "ESPNames",
    Callback = function(v) Solaris.Settings.ESP.Names = v end
})

VisTab:CreateSlider({
    Name = "Max Distance",
    Range = {100, 5000},
    Increment = 100,
    Suffix = "Studs",
    CurrentValue = 2000,
    Flag = "ESPMaxDist",
    Callback = function(v) Solaris.Settings.ESP.MaxDistance = v end
})

VisTab:CreateColorPicker({
    Name = "Box Color",
    Color = Color3.fromRGB(255, 255, 255),
    Flag = "BoxColor",
    Callback = function(v) Solaris.Settings.ESP.BoxColor = v end
})

local WorldSection = VisTab:CreateSection("World Adjustments")

VisTab:CreateToggle({
    Name = "Fullbright",
    CurrentValue = false,
    Flag = "Fullbright",
    Callback = function(v)
        Solaris.Settings.World.Fullbright = v
        if v then
            Lighting.Brightness = 2
            Lighting.ClockTime = 14
            Lighting.GlobalShadows = false
            Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
        else
            Lighting.Brightness = 1 -- Reset approx
            Lighting.GlobalShadows = true
        end
    end
})

-- [TAB] Movement
local MoveTab = Window:CreateTab("Movement", 4483362458)

MoveTab:CreateToggle({
    Name = "Speed Hack",
    CurrentValue = false,
    Flag = "SpeedToggle",
    Callback = function(v) 
        Solaris.Settings.Speed.Enabled = v 
        if not v and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = 16
        end
    end
})

MoveTab:CreateSlider({
    Name = "Walk Speed",
    Range = {16, 300},
    Increment = 1,
    Suffix = "",
    CurrentValue = 16,
    Flag = "SpeedVal",
    Callback = function(v) 
        Solaris.Settings.Speed.Value = v 
    end
})

MoveTab:CreateSection("Flight")

MoveTab:CreateToggle({
    Name = "Enable Flight",
    CurrentValue = false,
    Flag = "FlyToggle",
    Callback = function(v) Solaris.Settings.Flight.Enabled = v end
})

MoveTab:CreateSlider({
    Name = "Flight Speed",
    Range = {1, 10},
    Increment = 0.5,
    Suffix = "Multiplier",
    CurrentValue = 2,
    Flag = "FlySpeed",
    Callback = function(v) Solaris.Settings.Flight.Speed = v end
})

-- [TAB] Misc & Config
local MiscTab = Window:CreateTab("Settings", 4483362458)
local ConfigSec = MiscTab:CreateSection("Configuration")

MiscTab:CreateButton({
    Name = "Unload Solaris",
    Callback = function()
        Solaris.IsRunning = false
        -- Clean up threads
        for _, conn in pairs(Solaris.Connections) do
            if conn then conn:Disconnect() end
        end
        -- Clean up visuals
        Solaris.Visuals.ESP_Container:Destroy()
        -- Destroy UI
        Library:Destroy()
        Utility.Log("Warning", "Solaris Hub Unloaded.")
    end
})

--// 7. FINAL CONNECTIONS
table.insert(Solaris.Connections, RunService.RenderStepped:Connect(MainLoop))
table.insert(Solaris.Connections, RunService.RenderStepped:Connect(function()
    -- Speed Loop
    if Solaris.Settings.Speed.Enabled and LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
        if hum then hum.WalkSpeed = Solaris.Settings.Speed.Value end
    end
end))

-- ESP Loop (Optimized, run every 0.1s or every frame depending on performance needs)
task.spawn(function()
    while Solaris.IsRunning do
        if Solaris.Settings.ESP.Enabled then
            UpdateESP()
        else
            -- Hide all if disabled
            for _, data in pairs(ESP_Cache) do
                data.Gui.Enabled = false
            end
        end
        task.wait(0.1) -- Throttle ESP update
    end
end)

-- Infinite Jump Hook
table.insert(Solaris.Connections, UserInputService.JumpRequest:Connect(function()
    if Solaris.Settings.Jump.Infinite and LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end))

--// 8. NOTIFICATION
Library:Notify({
    Title = "Solaris Loaded",
    Content = "Welcome back, " .. LocalPlayer.Name,
    Duration = 5,
    Image = 4483362458,
})

Utility.Log("Success", "Solaris Hub initialization sequence complete.")

return Solaris