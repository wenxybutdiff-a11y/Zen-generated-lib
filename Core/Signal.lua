--[[
    [MODULE] Core/Signal.lua
    [ARCHITECT] Lead UI Architect
    [SYSTEM] Sirius Rayfield Framework
    [VERSION] 1.5.0-Optimized
    
    [DESCRIPTION]
    A lightweight, high-performance Lua-native event signal implementation.
    Designed to replace Roblox 'BindableEvent' for internal library communication to:
    1. Reduce instance overhead.
    2. Eliminate crossing the C++/Lua boundary for internal events.
    3. Provide immediate (synchronous) or deferred execution control.
]]

local Signal = {}
Signal.__index = Signal

--// Connection Class
local Connection = {}
Connection.__index = Connection

function Connection.New(signal, fn)
    local self = setmetatable({}, Connection)
    self.Signal = signal
    self.Fn = fn
    self.Connected = true
    return self
end

function Connection:Disconnect()
    if not self.Connected then return end
    self.Connected = false
    
    -- Remove from signal's listener list
    if self.Signal and self.Signal.Listeners then
        for i, conn in ipairs(self.Signal.Listeners) do
            if conn == self then
                table.remove(self.Signal.Listeners, i)
                break
            end
        end
    end
end

--// Signal Class
function Signal.New()
    local self = setmetatable({}, Signal)
    self.Listeners = {}
    return self
end

--[[
    [METHOD] Connect
    Subscribes a function to the signal.
]]
function Signal:Connect(fn)
    if type(fn) ~= "function" then
        error("[Signal] Attempt to connect non-function: " .. tostring(fn))
    end
    
    local cn = Connection.New(self, fn)
    table.insert(self.Listeners, cn)
    return cn
end

--[[
    [METHOD] Fire
    Executes all connected listeners with the provided arguments.
    Execution is protected (pcall) to prevent one error from breaking the loop.
]]
function Signal:Fire(...)
    for _, cn in ipairs(self.Listeners) do
        if cn.Connected then
            task.spawn(cn.Fn, ...)
        end
    end
end

--[[
    [METHOD] FireSync
    Executes immediately without task.spawn. Use with caution.
]]
function Signal:FireSync(...)
    for _, cn in ipairs(self.Listeners) do
        if cn.Connected then
            cn.Fn(...)
        end
    end
end

--[[
    [METHOD] Wait
    Yields the current thread until the signal is fired.
]]
function Signal:Wait()
    local running = coroutine.running()
    local cn
    
    cn = self:Connect(function(...)
        cn:Disconnect()
        task.spawn(running, ...)
    end)
    
    return coroutine.yield()
end

--[[
    [METHOD] Destroy
    Cleans up all connections.
]]
function Signal:Destroy()
    for _, cn in ipairs(self.Listeners) do
        cn.Connected = false
    end
    self.Listeners = {}
    setmetatable(self, nil)
end

return Signal