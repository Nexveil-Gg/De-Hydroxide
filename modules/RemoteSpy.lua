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

local Config = {
    remoteMethods = {
        FireServer = true,
        InvokeServer = true,
        Fire = true,
        Invoke = true,
        fireServer = true,
        invokeServer = true,
        fire = true,
        invoke = true
    },
    remotesViewing = {
        RemoteEvent = true,
        RemoteFunction = true,
        BindableEvent = true,
        BindableFunction = true
    },
    methodHooks = {
        RemoteEvent = Instance.new("RemoteEvent").FireServer,
        RemoteFunction = Instance.new("RemoteFunction").InvokeServer,
        BindableEvent = Instance.new("BindableEvent").Fire,
        BindableFunction = Instance.new("BindableFunction").Invoke
    },
    namecallMethods = {
        fireServer = "FireServer",
        invokeServer = "InvokeServer",
        fire = "Fire",
        invoke = "Invoke",
        FireServer = "FireServer",
        InvokeServer = "InvokeServer",
        Fire = "Fire",
        Invoke = "Invoke"
    }
}

local State = {
    currentRemotes = {},
    remoteDataEvent = Instance.new("BindableEvent"),
    eventSet = false,
    weirdNameRemotes = {}
}

local Methods = {
    checkCaller = checkcaller,
    getNamecallMethod = getnamecallmethod,
    getCallingScript = getcallingscript,
    getInfo = debug.getinfo,
    newCClosure = newcclosure,
    hookFunction = hookfunction,
    hookMetaMethod = hookmetamethod
}

local function hasWeirdCharacters(name)
    if not name or name == "" then
        return true
    end
    
    for i = 1, #name do
        local byte = string.byte(name, i)
        if byte > 127 or byte < 32 then
            return true
        end
    end
    
    return false
end

local function connectEvent(callback)
    State.remoteDataEvent.Event:Connect(callback)
    State.eventSet = true
end

local function getOrCreateRemote(instance)
    local remote = State.currentRemotes[instance]
    if not remote then
        remote = Remote.new(instance)
        State.currentRemotes[instance] = remote
        
        if hasWeirdCharacters(instance.Name) then
            State.weirdNameRemotes[instance] = remote
            remote.HasWeirdName = true
        end
    end
    return remote
end

local function isValidRemote(instance)
    if typeof(instance) ~= "Instance" then
        return false
    end
    
    if instance == State.remoteDataEvent then
        return false
    end
    
    if not Config.remotesViewing[instance.ClassName] then
        return false
    end
    
    return true
end

local function handleCall(instance, method, vargs)
    local remote = getOrCreateRemote(instance)

    local remoteIgnored = remote.Ignored
    local argsIgnored = remote:AreArgsIgnored(vargs)
    local argsBlocked = remote:AreArgsBlocked(vargs)
    local remoteBlocked = remote.Blocked

    if State.eventSet and (not remoteIgnored and not argsIgnored) then
        local callingScript = nil
        pcall(function()
            callingScript = Methods.getCallingScript((PROTOSMASHER_LOADED and 2) or nil)
        end)
        
        local funcInfo = nil
        pcall(function()
            funcInfo = Methods.getInfo(3).func
        end)
        
        local call = {
            script = callingScript,
            args = vargs,
            func = funcInfo,
            method = method,
            isBindable = instance.ClassName == "BindableEvent" or instance.ClassName == "BindableFunction",
            hasWeirdName = hasWeirdCharacters(instance.Name)
        }

        remote:IncrementCalls(call)
        State.remoteDataEvent:Fire(instance, call)
    end

    if remoteBlocked or argsBlocked then
        return true
    end

    return false
end

local nmcTrampoline = nil
nmcTrampoline = Methods.hookMetaMethod(game, "__namecall", Methods.newCClosure(function(...)
    if Methods.checkCaller() then
        return nmcTrampoline(...)
    end

    local instance = ...
    if not isValidRemote(instance) then
        return nmcTrampoline(...)
    end

    local method = Methods.getNamecallMethod()
    local normalizedMethod = Config.namecallMethods[method]
    
    if normalizedMethod then
        local vargs = {select(2, ...)}
        local blocked = handleCall(instance, normalizedMethod, vargs)
        if blocked then 
            if instance.ClassName == "RemoteFunction" or instance.ClassName == "BindableFunction" then
                return nil
            end
            return 
        end
    end

    return nmcTrampoline(...)
end))

for className, hook in pairs(Config.methodHooks) do
    local originalMethod
    originalMethod = Methods.hookFunction(hook, Methods.newCClosure(function(...)
        local instance = ...
        
        if typeof(instance) ~= "Instance" then
            return originalMethod(...)
        end

        if instance.ClassName == className and isValidRemote(instance) then
            local vargs = {select(2, ...)}
            
            local methodName = "FireServer"
            if className == "RemoteFunction" then
                methodName = "InvokeServer"
            elseif className == "BindableEvent" then
                methodName = "Fire"
            elseif className == "BindableFunction" then
                methodName = "Invoke"
            end
            
            local blocked = handleCall(instance, methodName, vargs)
            if blocked then 
                if className == "RemoteFunction" or className == "BindableFunction" then
                    return nil
                end
                return 
            end
        end

        return originalMethod(...)
    end))
end

local function getWeirdNameRemotes()
    return State.weirdNameRemotes
end

local function getAllRemotes()
    return State.currentRemotes
end

local function getRemotesByType(remoteType)
    local result = {}
    for instance, remote in pairs(State.currentRemotes) do
        if instance.ClassName == remoteType then
            result[instance] = remote
        end
    end
    return result
end

local function getBindables()
    local result = {}
    for instance, remote in pairs(State.currentRemotes) do
        if instance.ClassName == "BindableEvent" or instance.ClassName == "BindableFunction" then
            result[instance] = remote
        end
    end
    return result
end

RemoteSpy.RemotesViewing = Config.remotesViewing
RemoteSpy.CurrentRemotes = State.currentRemotes
RemoteSpy.WeirdNameRemotes = State.weirdNameRemotes
RemoteSpy.ConnectEvent = connectEvent
RemoteSpy.GetWeirdNameRemotes = getWeirdNameRemotes
RemoteSpy.GetAllRemotes = getAllRemotes
RemoteSpy.GetRemotesByType = getRemotesByType
RemoteSpy.GetBindables = getBindables
RemoteSpy.HasWeirdCharacters = hasWeirdCharacters
RemoteSpy.RequiredMethods = requiredMethods

return RemoteSpy    local remoteIgnored = remote.Ignored
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
