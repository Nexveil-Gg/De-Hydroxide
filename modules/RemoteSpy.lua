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
    RemoteFunction = true,
    BindableEvent = true,
    BindableFunction = true
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

local checkCaller = checkcaller
local getNamecallMethod = getnamecallmethod
local getCallingScript = getcallingscript
local getInfo = debug.getinfo
local newCClosure = newcclosure
local hookFunction = hookfunction
local hookMetaMethod = hookmetamethod
local typeOf = typeof
local pcall = pcall

local function connectEvent(callback)
    remoteDataEvent.Event:Connect(callback)
    eventSet = true
end

local function getOrCreateRemote(instance)
    local remote = currentRemotes[instance]
    if not remote then
        remote = Remote.new(instance)
        currentRemotes[instance] = remote
    end
    return remote
end

local function handleCall(instance, method, vargs)
    local remote = getOrCreateRemote(instance)

    local remoteIgnored = remote.Ignored
    local argsIgnored = remote:AreArgsIgnored(vargs)
    local argsBlocked = remote:AreArgsBlocked(vargs)
    local remoteBlocked = remote.Blocked

    if eventSet and (not remoteIgnored and not argsIgnored) then
        local call = {
            script = getCallingScript((PROTOSMASHER_LOADED and 2) or nil),
            args = vargs,
            func = getInfo(3).func
        }

        remote:IncrementCalls(call)
        remoteDataEvent:Fire(instance, call)
    end

    if remoteBlocked or argsBlocked then
        return true
    end

    return false
end

local function isValidRemote(instance)
    return typeOf(instance) == "Instance" and remotesViewing[instance.ClassName] and instance ~= remoteDataEvent
end

local nmcTrampoline = nil
nmcTrampoline = hookMetaMethod(game, "__namecall", newCClosure(function(...)
    if checkCaller() then
        return nmcTrampoline(...)
    end

    local instance = ...
    if not isValidRemote(instance) then
        return nmcTrampoline(...)
    end

    local method = getNamecallMethod()
    if method == "fireServer" then
        method = "FireServer"
    elseif method == "invokeServer" then
        method = "InvokeServer"
    end

    if remoteMethods[method] then
        local vargs = {select(2, ...)}
        local blocked = handleCall(instance, method, vargs)
        if blocked then return end
    end

    return nmcTrampoline(...)
end))

local function checkPermission(instance)
    if instance and instance.ClassName then
        -- Optional permission logic (boş bırakıldı çünkü yoktu)
    end
end

for _name, hook in pairs(methodHooks) do
    local originalMethod

    originalMethod = hookFunction(hook, newCClosure(function(...)
        local instance = ...
        if typeOf(instance) ~= "Instance" then
            return originalMethod(...)
        end

        local success = pcall(checkPermission, instance)
        if not success then
            return originalMethod(...)
        end

        if instance.ClassName == _name and isValidRemote(instance) then
            local vargs = {select(2, ...)}

            local blocked = handleCall(instance, "Direct", vargs)
            if blocked then return end
        end

        return originalMethod(...)
    end))
end

RemoteSpy.RemotesViewing = remotesViewing
RemoteSpy.CurrentRemotes = currentRemotes
RemoteSpy.ConnectEvent = connectEvent
RemoteSpy.RequiredMethods = requiredMethods

return RemoteSpy
