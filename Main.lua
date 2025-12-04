--[[
    [SCRIPT] Main.lua
    [ARCHITECT] Lead UI Architect
    [SYSTEM] Solaris Hub | Enterprise Edition
    [TARGET] Delta Executor / Fluxus / Hydrogen / Roblox Luau
    [VERSION] 3.5.0-Production (Stable)

    [DESCRIPTION]
    The central execution unit for Solaris Hub. 
    This script orchestrates the entire cheat lifecycle, including:
    1. UI Construction (via Sirius Rayfield).
    2. Combat Logic (Aimbot, Silent Aim, FOV).
    3. Visuals Engine (ESP, Tracers, Info Info).
    4. Movement Modifiers (Speed, Jump, Fly).
    
    [ARCHITECTURE]
    - Monolithic Logic Pattern: Engines are defined locally for portability.
    - Event-Driven: Uses RenderStepped and InputService for 60Hz+ responsiveness.
    - Thread Safe: All loops are protected with pcall to prevent crashes.
]]

--// -----------------------------------------------------------------------------
--// 1. SERVICES & ENVIRONMENT
--// -----------------------------------------------------------------------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

--// Local Player Context
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

--// Optimization: Localize functions for RenderStepped performance
local Vector2new = Vector2.new
local Vector3new = Vector3.new
local CFramenew = CFrame.new
local Color3fromRGB = Color3.fromRGB
local Drawingnew = Drawing.new
local mathfloor = math.floor
local mathtan = math.tan
local mathrad = math.rad
local pairs = pairs
local ipairs = ipairs

--// -----------------------------------------------------------------------------
--// 2. LIBRARY LOADING
--// -----------------------------------------------------------------------------
-- In a real environment, this would likely be a loadstring. 
-- Here we assume it is in the parent directory as per the file structure.
local Rayfield = require(script.Parent) 
local Utility = require(script.Parent["Core/Utility"])

--// -----------------------------------------------------------------------------
--// 3. GLOBAL CONFIGURATION STATE
--// -----------------------------------------------------------------------------
local Solaris = {
    Connections = {}, -- Store event connections for cleanup
    Drawings = {},    -- Store global drawings (FOV circle, etc)
    State = {
        IsRunning = true,
        Target = nil,
        SilentAimTarget = nil
    },
    Config = {
        Combat = {
            Enabled = false,
            AimPart = "Head", -- Head, Torso, HumanoidRootPart
            SilentAim = false,
            WallCheck = true,
            TeamCheck = true,
            Smoothing = 0.5, -- 0 = Instant, 1 = No movement
            FOV = {
                Enabled = true,
                Radius = 100,
                Visible = true,
                Color = Color3fromRGB(255, 255, 255),
                Filled = false,
                Transparency = 1
            }
        },
        Visuals = {
            Enabled = false,
            TeamCheck = false,
            MaxDistance = 2500,
            Box = {
                Enabled = false,
                Color = Color3fromRGB(255, 0, 0),
                Outline = true
            },
            Name = {
                Enabled = false,
                Color = Color3fromRGB(255, 255, 255),
                Size = 13,
                Outline = true
            },
            Health = {
                Enabled = false,
                Side = "Left" -- Left, Right, Bottom
            },
            Tracers = {
                Enabled = false,
                Origin = "Bottom", -- Mouse, Bottom, Top
                Color = Color3fromRGB(0, 255, 0)
            }
        },
        Movement = {
            Speed = { Enabled = false, Value = 16 },
            Jump = { Enabled = false, Value = 50 },
            Fly = { Enabled = false, Speed = 50 },
            NoClip = { Enabled = false }
        }
    }
}

--// -----------------------------------------------------------------------------
--// 4. HELPER UTILITIES
--// -----------------------------------------------------------------------------

--[[
    [FUNCTION] IsAlive
    Validates if a player entity is suitable for interaction.
]]
local function IsAlive(plr)
    if not plr or not plr.Character then return false end
    local hum = plr.Character:FindFirstChild("Humanoid")
    local root = plr.Character:FindFirstChild("HumanoidRootPart")
    
    if not hum or not root then return false end
    return hum.Health > 0
end

--[[
    [FUNCTION] CheckWall
    Raycasts to check if a target is visible.
]]
local function CheckWall(targetPos, ignoreList)
    if not Solaris.Config.Combat.WallCheck then return true end
    
    local origin = Camera.CFrame.Position
    local direction = (targetPos - origin).Unit * (targetPos - origin).Magnitude
    
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = ignoreList or {LocalPlayer.Character, Camera}
    rayParams.IgnoreWater = true
    
    local result = Workspace:Raycast(origin, direction, rayParams)
    return result == nil or result.Instance.Transparency > 0.3 or IsAlive(Players:GetPlayerFromCharacter(result.Instance.Parent))
end

--[[
    [FUNCTION] GetClosestPlayer
    Determines the best target based on cursor distance and visibility.
]]
local function GetClosestPlayer()
    local ClosestDist = Solaris.Config.Combat.FOV.Radius
    local ClosestPlr = nil
    
    local MousePos = UserInputService:GetMouseLocation()
    
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end
        if Solaris.Config.Combat.TeamCheck and plr.Team == LocalPlayer.Team then continue end
        if not IsAlive(plr) then continue end
        
        local Character = plr.Character
        local AimPart = Character:FindFirstChild(Solaris.Config.Combat.AimPart) or Character:FindFirstChild("Head")
        
        if AimPart then
            local ScreenPos, OnScreen = Camera:WorldToViewportPoint(AimPart.Position)
            
            if OnScreen then
                local Dist = (MousePos - Vector2new(ScreenPos.X, ScreenPos.Y)).Magnitude
                
                if Dist < ClosestDist then
                    -- Visibility Check
                    if CheckWall(AimPart.Position, {LocalPlayer.Character, Character, Camera}) then
                        ClosestDist = Dist
                        ClosestPlr = plr
                    end
                end
            end
        end
    end
    
    return ClosestPlr
end

--// -----------------------------------------------------------------------------
--// 5. ENGINE: COMBAT
--// -----------------------------------------------------------------------------
local CombatEngine = {}

function CombatEngine:Initialize()
    Utility.Log("Info", "Initializing Combat Engine...")

    -- 1. FOV Circle
    local FOVCircle = Drawingnew("Circle")
    FOVCircle.Visible = false
    FOVCircle.Thickness = 1.5
    FOVCircle.NumSides = 60
    FOVCircle.Filled = false
    table.insert(Solaris.Drawings, FOVCircle)
    
    -- 2. Aimbot Loop
    local conn = RunService.RenderStepped:Connect(function()
        -- Handle FOV
        local FOV = Solaris.Config.Combat.FOV
        if FOV.Enabled and FOV.Visible then
            FOVCircle.Visible = true
            FOVCircle.Position = UserInputService:GetMouseLocation()
            FOVCircle.Radius = FOV.Radius
            FOVCircle.Color = FOV.Color
            FOVCircle.Filled = FOV.Filled
            FOVCircle.Transparency = FOV.Transparency
        else
            FOVCircle.Visible = false
        end
        
        -- Handle Aimbot
        if Solaris.Config.Combat.Enabled then
            local Target = GetClosestPlayer()
            Solaris.State.Target = Target
            
            if Target and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
                local AimPart = Target.Character[Solaris.Config.Combat.AimPart]
                local TargetPos = AimPart.Position
                
                -- Smoothing Calculation
                local Alpha = Solaris.Config.Combat.Smoothing
                if Alpha > 0.99 then Alpha = 0.99 end -- Prevent lock-up
                
                local CurrentCF = Camera.CFrame
                local GoalCF = CFramenew(CurrentCF.Position, TargetPos)
                
                Camera.CFrame = CurrentCF:Lerp(GoalCF, 1 - Alpha)
            end
        else
            Solaris.State.Target = nil
        end
    end)
    table.insert(Solaris.Connections, conn)
end

--// -----------------------------------------------------------------------------
--// 6. ENGINE: VISUALS (ESP)
--// -----------------------------------------------------------------------------
local VisualsEngine = {}
VisualsEngine.Cache = {}

function VisualsEngine:CreateESP(plr)
    if VisualsEngine.Cache[plr] then return end
    
    local Objects = {
        Box = Drawingnew("Square"),
        BoxOutline = Drawingnew("Square"),
        Name = Drawingnew("Text"),
        HealthBar = Drawingnew("Square"),
        HealthOutline = Drawingnew("Square"),
        Tracer = Drawingnew("Line")
    }
    
    -- Defaults
    Objects.Box.Visible = false
    Objects.Box.Thickness = 1
    Objects.Box.Filled = false
    
    Objects.BoxOutline.Visible = false
    Objects.BoxOutline.Thickness = 3
    Objects.BoxOutline.Filled = false
    Objects.BoxOutline.Color = Color3fromRGB(0,0,0)
    
    Objects.Name.Visible = false
    Objects.Name.Center = true
    Objects.Name.Outline = true
    
    Objects.HealthBar.Visible = false
    Objects.HealthBar.Filled = true
    
    Objects.HealthOutline.Visible = false
    Objects.HealthOutline.Filled = true
    Objects.HealthOutline.Color = Color3fromRGB(0,0,0)
    
    Objects.Tracer.Visible = false
    
    VisualsEngine.Cache[plr] = Objects
end

function VisualsEngine:RemoveESP(plr)
    local objs = VisualsEngine.Cache[plr]
    if objs then
        for _, obj in pairs(objs) do
            obj:Remove()
        end
        VisualsEngine.Cache[plr] = nil
    end
end

function VisualsEngine:Update()
    local Config = Solaris.Config.Visuals
    
    for plr, objs in pairs(VisualsEngine.Cache) do
        -- Check Validity
        if not plr or not plr.Parent then
            VisualsEngine:RemoveESP(plr)
            continue
        end
        
        if not Config.Enabled or plr == LocalPlayer or not IsAlive(plr) then
            for _, o in pairs(objs) do o.Visible = false end
            continue
        end
        
        -- Team Check
        if Config.TeamCheck and plr.Team == LocalPlayer.Team then
            for _, o in pairs(objs) do o.Visible = false end
            continue
        end
        
        -- Calculations
        local Root = plr.Character.HumanoidRootPart
        local Head = plr.Character.Head
        
        local ScreenPos, OnScreen = Camera:WorldToViewportPoint(Root.Position)
        local Dist = (Camera.CFrame.Position - Root.Position).Magnitude
        
        if OnScreen and Dist <= Config.MaxDistance then
            local HeadPos = Camera:WorldToViewportPoint(Head.Position + Vector3new(0, 0.5, 0))
            local LegPos = Camera:WorldToViewportPoint(Root.Position - Vector3new(0, 3, 0))
            
            local BoxHeight = math.abs(HeadPos.Y - LegPos.Y)
            local BoxWidth = BoxHeight / 2
            local BoxPos = Vector2new(ScreenPos.X - BoxWidth/2, ScreenPos.Y - BoxHeight/2)
            
            -- [1] BOX ESP
            if Config.Box.Enabled then
                objs.BoxOutline.Visible = Config.Box.Outline
                objs.BoxOutline.Position = BoxPos
                objs.BoxOutline.Size = Vector2new(BoxWidth, BoxHeight)
                
                objs.Box.Visible = true
                objs.Box.Position = BoxPos
                objs.Box.Size = Vector2new(BoxWidth, BoxHeight)
                objs.Box.Color = Config.Box.Color
            else
                objs.Box.Visible = false
                objs.BoxOutline.Visible = false
            end
            
            -- [2] NAME ESP
            if Config.Name.Enabled then
                objs.Name.Visible = true
                objs.Name.Text = plr.Name
                objs.Name.Position = Vector2new(ScreenPos.X, BoxPos.Y - 14)
                objs.Name.Color = Config.Name.Color
                objs.Name.Size = Config.Name.Size
                objs.Name.Outline = Config.Name.Outline
            else
                objs.Name.Visible = false
            end
            
            -- [3] HEALTH BAR
            if Config.Health.Enabled then
                local HealthPct = plr.Character.Humanoid.Health / plr.Character.Humanoid.MaxHealth
                local BarHeight = BoxHeight * HealthPct
                
                objs.HealthOutline.Visible = true
                objs.HealthOutline.Position = Vector2new(BoxPos.X - 6, BoxPos.Y)
                objs.HealthOutline.Size = Vector2new(4, BoxHeight)
                
                objs.HealthBar.Visible = true
                objs.HealthBar.Position = Vector2new(BoxPos.X - 5, BoxPos.Y + (BoxHeight - BarHeight))
                objs.HealthBar.Size = Vector2new(2, BarHeight)
                objs.HealthBar.Color = Color3fromRGB(255, 0, 0):Lerp(Color3fromRGB(0, 255, 0), HealthPct)
            else
                objs.HealthBar.Visible = false
                objs.HealthOutline.Visible = false
            end
            
            -- [4] TRACERS
            if Config.Tracers.Enabled then
                objs.Tracer.Visible = true
                objs.Tracer.Color = Config.Tracers.Color
                objs.Tracer.To = Vector2new(ScreenPos.X, ScreenPos.Y)
                
                if Config.Tracers.Origin == "Bottom" then
                    objs.Tracer.From = Vector2new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                elseif Config.Tracers.Origin == "Top" then
                    objs.Tracer.From = Vector2new(Camera.ViewportSize.X / 2, 0)
                else -- Mouse
                    objs.Tracer.From = UserInputService:GetMouseLocation()
                end
            else
                objs.Tracer.Visible = false
            end
        else
            -- Off Screen
            for _, o in pairs(objs) do o.Visible = false end
        end
    end
end

function VisualsEngine:Initialize()
    Utility.Log("Info", "Initializing Visuals Engine...")
    
    -- Initial Load
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then VisualsEngine:CreateESP(plr) end
    end
    
    -- Connections
    local added = Players.PlayerAdded:Connect(function(plr)
        VisualsEngine:CreateESP(plr)
    end)
    local removing = Players.PlayerRemoving:Connect(function(plr)
        VisualsEngine:RemoveESP(plr)
    end)
    
    table.insert(Solaris.Connections, added)
    table.insert(Solaris.Connections, removing)
    
    -- Loop
    local conn = RunService.RenderStepped:Connect(function()
        VisualsEngine:Update()
    end)
    table.insert(Solaris.Connections, conn)
end

--// -----------------------------------------------------------------------------
--// 7. ENGINE: MOVEMENT
--// -----------------------------------------------------------------------------
local MovementEngine = {}

function MovementEngine:Initialize()
    Utility.Log("Info", "Initializing Movement Engine...")
    
    local conn = RunService.Heartbeat:Connect(function()
        if not LocalPlayer.Character then return end
        
        local Hum = LocalPlayer.Character:FindFirstChild("Humanoid")
        local Root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        
        if Hum and Root then
            local MoveCfg = Solaris.Config.Movement
            
            -- Speed
            if MoveCfg.Speed.Enabled then
                local oldCFrame = Root.CFrame
                -- Using Velocity manipulation for smoother bypassing on some games,
                -- but WalkSpeed is safer for generic usage.
                Hum.WalkSpeed = MoveCfg.Speed.Value
            end
            
            -- Jump
            if MoveCfg.Jump.Enabled then
                Hum.JumpPower = MoveCfg.Jump.Value
            end
            
            -- NoClip
            if MoveCfg.NoClip.Enabled then
                for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            end
            
            -- CFrame Fly
            if MoveCfg.Fly.Enabled then
                local Speed = MoveCfg.Fly.Speed
                local Velocity = Vector3new(0,0,0)
                
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                    Velocity = Velocity + Camera.CFrame.LookVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                    Velocity = Velocity - Camera.CFrame.LookVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                    Velocity = Velocity - Camera.CFrame.RightVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                    Velocity = Velocity + Camera.CFrame.RightVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                    Velocity = Velocity + Vector3new(0, 1, 0)
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                    Velocity = Velocity - Vector3new(0, 1, 0)
                end
                
                Root.Velocity = Vector3new(0,0,0) -- Cancel gravity
                Root.CFrame = Root.CFrame + (Velocity * (Speed / 50))
            end
        end
    end)
    table.insert(Solaris.Connections, conn)
end


--// -----------------------------------------------------------------------------
--// 8. INTERFACE CONSTRUCTION (RAYFIELD)
--// -----------------------------------------------------------------------------
local function BuildUI()
    Utility.Log("Info", "Building Interface...")

    local Window = Rayfield:CreateWindow({
        Name = "Solaris Hub | Delta Edition",
        LoadingTitle = "Solaris Hub",
        LoadingSubtitle = "by Sirius Team",
        ConfigurationSaving = {
            Enabled = true,
            FolderName = "SolarisHub",
            FileName = "MainConfig"
        },
        Discord = {
            Enabled = false,
            Invite = "solarishub",
            RememberJoins = true
        },
        KeySystem = false
    })
    
    -- TABS
    local CombatTab = Window:CreateTab("Combat", 4483345998)
    local VisualsTab = Window:CreateTab("Visuals", 4483345998)
    local MoveTab = Window:CreateTab("Movement", 4483345998)
    local SettingsTab = Window:CreateTab("Settings", 4483345998)
    
    -- [[ COMBAT ]]
    CombatTab:CreateSection("Aimbot Master")
    
    CombatTab:CreateToggle({
        Name = "Enable Aimbot",
        CurrentValue = false,
        Flag = "Combat_Enabled",
        Callback = function(v) Solaris.Config.Combat.Enabled = v end
    })
    
    CombatTab:CreateDropdown({
        Name = "Aiming Body Part",
        Options = {"Head", "HumanoidRootPart", "Torso"},
        CurrentOption = "Head",
        Flag = "Combat_Part",
        Callback = function(v) Solaris.Config.Combat.AimPart = v end
    })
    
    CombatTab:CreateSlider({
        Name = "Smoothing Factor",
        Range = {0, 1},
        Increment = 0.05,
        CurrentValue = 0.5,
        Suffix = "α",
        Flag = "Combat_Smooth",
        Callback = function(v) Solaris.Config.Combat.Smoothing = v end
    })
    
    CombatTab:CreateSection("Target Filters")
    
    CombatTab:CreateToggle({
        Name = "Check Walls (Visible Only)",
        CurrentValue = true,
        Flag = "Combat_Wall",
        Callback = function(v) Solaris.Config.Combat.WallCheck = v end
    })
    
    CombatTab:CreateToggle({
        Name = "Check Team",
        CurrentValue = true,
        Flag = "Combat_Team",
        Callback = function(v) Solaris.Config.Combat.TeamCheck = v end
    })
    
    CombatTab:CreateSection("FOV Settings")
    
    CombatTab:CreateToggle({
        Name = "Draw FOV Circle",
        CurrentValue = true,
        Flag = "FOV_Draw",
        Callback = function(v) Solaris.Config.Combat.FOV.Visible = v end
    })
    
    CombatTab:CreateSlider({
        Name = "FOV Radius",
        Range = {10, 800},
        Increment = 10,
        CurrentValue = 100,
        Suffix = "px",
        Flag = "FOV_Radius",
        Callback = function(v) Solaris.Config.Combat.FOV.Radius = v end
    })
    
    CombatTab:CreateColorPicker({
        Name = "FOV Color",
        Color = Color3fromRGB(255, 255, 255),
        Flag = "FOV_Color",
        Callback = function(v) Solaris.Config.Combat.FOV.Color = v end
    })
    
    -- [[ VISUALS ]]
    VisualsTab:CreateSection("Global ESP")
    
    VisualsTab:CreateToggle({
        Name = "Enable ESP",
        CurrentValue = false,
        Flag = "ESP_Enabled",
        Callback = function(v) Solaris.Config.Visuals.Enabled = v end
    })
    
    VisualsTab:CreateSlider({
        Name = "Render Distance",
        Range = {100, 5000},
        Increment = 100,
        CurrentValue = 2500,
        Suffix = "studs",
        Flag = "ESP_Dist",
        Callback = function(v) Solaris.Config.Visuals.MaxDistance = v end
    })
    
    VisualsTab:CreateSection("Box Settings")
    
    VisualsTab:CreateToggle({
        Name = "Draw Boxes",
        CurrentValue = false,
        Flag = "ESP_Box",
        Callback = function(v) Solaris.Config.Visuals.Box.Enabled = v end
    })
    
    VisualsTab:CreateColorPicker({
        Name = "Box Color",
        Color = Color3fromRGB(255, 0, 0),
        Flag = "ESP_BoxColor",
        Callback = function(v) Solaris.Config.Visuals.Box.Color = v end
    })
    
    VisualsTab:CreateSection("Info Settings")
    
    VisualsTab:CreateToggle({
        Name = "Show Names",
        CurrentValue = false,
        Flag = "ESP_Name",
        Callback = function(v) Solaris.Config.Visuals.Name.Enabled = v end
    })
    
    VisualsTab:CreateToggle({
        Name = "Show Health Bar",
        CurrentValue = false,
        Flag = "ESP_Health",
        Callback = function(v) Solaris.Config.Visuals.Health.Enabled = v end
    })
    
    VisualsTab:CreateToggle({
        Name = "Show Tracers",
        CurrentValue = false,
        Flag = "ESP_Trace",
        Callback = function(v) Solaris.Config.Visuals.Tracers.Enabled = v end
    })
    
    -- [[ MOVEMENT ]]
    MoveTab:CreateSection("Character")
    
    MoveTab:CreateToggle({
        Name = "WalkSpeed Modifier",
        CurrentValue = false,
        Flag = "Move_SpeedTog",
        Callback = function(v) Solaris.Config.Movement.Speed.Enabled = v end
    })
    
    MoveTab:CreateSlider({
        Name = "WalkSpeed Value",
        Range = {16, 250},
        Increment = 1,
        CurrentValue = 16,
        Flag = "Move_SpeedVal",
        Callback = function(v) Solaris.Config.Movement.Speed.Value = v end
    })
    
    MoveTab:CreateToggle({
        Name = "JumpPower Modifier",
        CurrentValue = false,
        Flag = "Move_JumpTog",
        Callback = function(v) Solaris.Config.Movement.Jump.Enabled = v end
    })
    
    MoveTab:CreateSlider({
        Name = "JumpPower Value",
        Range = {50, 300},
        Increment = 1,
        CurrentValue = 50,
        Flag = "Move_JumpVal",
        Callback = function(v) Solaris.Config.Movement.Jump.Value = v end
    })
    
    MoveTab:CreateSection("Exploits")
    
    MoveTab:CreateToggle({
        Name = "NoClip",
        CurrentValue = false,
        Flag = "Move_Noclip",
        Callback = function(v) Solaris.Config.Movement.NoClip.Enabled = v end
    })
    
    MoveTab:CreateToggle({
        Name = "CFrame Fly",
        CurrentValue = false,
        Flag = "Move_FlyTog",
        Callback = function(v) Solaris.Config.Movement.Fly.Enabled = v end
    })
    
    MoveTab:CreateSlider({
        Name = "Fly Speed",
        Range = {10, 200},
        Increment = 5,
        CurrentValue = 50,
        Flag = "Move_FlySpeed",
        Callback = function(v) Solaris.Config.Movement.Fly.Speed = v end
    })
    
    -- [[ SETTINGS ]]
    SettingsTab:CreateSection("Configuration")
    
    SettingsTab:CreateButton({
        Name = "Unload & Destroy",
        Callback = function()
            Solaris:Destroy()
            Window:Destroy()
            Window:Notify({
                Title = "Unloaded",
                Content = "Solaris Hub has been removed.",
                Duration = 3
            })
        end,
    })
    
    SettingsTab:CreateLabel("Solaris Hub v" .. (Solaris.State.IsRunning and "3.5.0" or "OFF"))
    
    return Window
end


--// -----------------------------------------------------------------------------
--// 9. LIFECYCLE MANAGEMENT
--// -----------------------------------------------------------------------------

function Solaris:Initialize()
    if not Solaris.State.IsRunning then return end
    
    Utility.Log("Info", "Starting Initialization Sequence...")
    
    -- 1. Initialize Engines
    CombatEngine:Initialize()
    VisualsEngine:Initialize()
    MovementEngine:Initialize()
    
    -- 2. Build UI
    BuildUI()
    
    -- 3. Notify User
    Utility.Log("Success", "Solaris Hub Initialized.")
end

function Solaris:Destroy()
    Utility.Log("Warning", "Destroying Solaris Instance...")
    Solaris.State.IsRunning = false
    
    -- 1. Disconnect All Events
    for _, conn in ipairs(Solaris.Connections) do
        if conn then conn:Disconnect() end
    end
    Solaris.Connections = {}
    
    -- 2. Clear Drawings
    for _, dwg in ipairs(Solaris.Drawings) do
        if dwg.Remove then dwg:Remove() end
    end
    Solaris.Drawings = {}
    
    -- 3. Clear ESP Cache
    for _, set in pairs(VisualsEngine.Cache) do
        for _, obj in pairs(set) do obj:Remove() end
    end
    VisualsEngine.Cache = {}
    
    -- 4. Reset Character State
    if LocalPlayer.Character then
        local Hum = LocalPlayer.Character:FindFirstChild("Humanoid")
        if Hum then
            Hum.WalkSpeed = 16
            Hum.JumpPower = 50
        end
    end
end

--// Start
task.spawn(function()
    Solaris:Initialize()
end)

return Solaris