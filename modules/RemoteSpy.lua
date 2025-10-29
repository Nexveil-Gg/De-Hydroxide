-- RemoteSpy.lua
local RemoteSpy = {}
local Remote = import("objects/Remote")

local requiredMethods = {
    ["checkCaller"] = true,
    ["newCClosure"] = true,
    ["hookFunction"] = true,
    ["isReadOnly"] = true,
    ["setReadOnly"] = true,
    ["getInfo"] = true,
    ["getMetatable"] = true,
    ["setClipboard"] = true,
    ["getNamecallMethod"] = true,
    ["getCallingScript"] = true,
}

local remoteMethods = {
    FireServer = true,
    InvokeServer = true,
    Fire = true,
    Invoke = true
}

local remotesViewing = {
    RemoteEvent = true,
    RemoteFunction = false,
    BindableEvent = false,
    BindableFunction = false
}

local methodHooks = {
    RemoteEvent = Instance.new("RemoteEvent").FireServer,
    RemoteFunction = Instance.new("RemoteFunction").InvokeServer,
    BindableEvent = Instance.new("BindableEvent").Fire,
    BindableFunction = Instance.new("BindableFunction").Invoke
}

local currentRemotes = {}
local remoteDataEvent = Instance.new("BindableEvent")
local eventSet = false

-- Utility getter once, so it doesn't become upvalue in closures
local getNamecallMethod = getNamecallMethod
local getCallingScript = getCallingScript
local getInfo = getInfo
local hookFunction = hookFunction
local newCClosure = newCClosure
local pcall = pcall

-- Connect callback externally
local function connectEvent(callback)
    remoteDataEvent.Event:Connect(callback)
    if not eventSet then
        eventSet = true
    end
end

-- Handle remote call
local function handleRemote(instance, method, vargs)
    local remote = currentRemotes[instance]

    if not remote then
        remote = Remote.new(instance)
        currentRemotes[instance] = remote
    end

    local remoteIgnored = remote.Ignored
    local remoteBlocked = remote.Blocked
    local argsIgnored = remote:AreArgsIgnored(vargs)
    local argsBlocked = remote:AreArgsBlocked(vargs)

    if eventSet and not remoteIgnored and not argsIgnored then
        local call = {
            script = getCallingScript((PROTOSMASHER_LOADED ~= nil and 2) or nil),
            args = vargs,
            func = getInfo(3).func
        }

        remote:IncrementCalls(call)
        remoteDataEvent:Fire(instance, call)
    end

    if remoteBlocked or argsBlocked then
        return true -- Block the call
    end

    return false -- Allow the call
end

-- Hook __namecall
local function setupNamecallHook()
    local original
    original = hookmetamethod(game, "__namecall", newCClosure(function(self, ...)
        if not checkcaller() and typeof(self) == "Instance" then
            local method = getNamecallMethod()

            if method == "fireServer" then method = "FireServer"
            elseif method == "invokeServer" then method = "InvokeServer" end

            if remotesViewing[self.ClassName] and remoteMethods[method] and self ~= remoteDataEvent then
                local args = { ... }
                table.remove(args, 1) -- remove instance

                if handleRemote(self, method, args) then
                    return nil -- Blocked
                end
            end
        end

        return original(self, ...)
    end))
end

-- Permission check function
local function checkPermission(instance)
    if instance.ClassName then
        -- Possibly you check className logic here, empty for now
    end
end

-- Hook individual methods
local function setupMethodHook(instanceType, method)
    local originalMethod
    originalMethod = hookFunction(method, newCClosure(function(self, ...)
        if typeof(self) ~= "Instance" then
            return originalMethod(self, ...)
        end

        local success = pcall(checkPermission, self)
        if not success then
            return originalMethod(self, ...)
        end

        if self.ClassName == instanceType and remotesViewing[self.ClassName] and self ~= remoteDataEvent then
            local args = { ... }

            if handleRemote(self, method, args) then
                return nil -- Block this call
            end
        end

        return originalMethod(self, ...)
    end))

    return originalMethod
end

-- Setup all method hooks
local function setupAllHooks()
    setupNamecallHook()

    for instanceType, method in pairs(methodHooks) do
        local original = setupMethodHook(instanceType, method)
        -- Example of storing original if needed later:
        -- oh.Hooks[original] = method
    end
end

-- run setup
setupAllHooks()

-- Public API
RemoteSpy.RemotesViewing = remotesViewing
RemoteSpy.CurrentRemotes = currentRemotes
RemoteSpy.ConnectEvent = connectEvent
RemoteSpy.RequiredMethods = requiredMethods

return RemoteSpy
