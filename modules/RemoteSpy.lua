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

local G = {
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
    namecallMap = {
        fireServer = "FireServer",
        invokeServer = "InvokeServer",
        fire = "Fire",
        invoke = "Invoke",
        FireServer = "FireServer",
        InvokeServer = "InvokeServer",
        Fire = "Fire",
        Invoke = "Invoke"
    },
    methodNames = {
        RemoteEvent = "FireServer",
        RemoteFunction = "InvokeServer",
        BindableEvent = "Fire",
        BindableFunction = "Invoke"
    },
    currentRemotes = {},
    weirdNameRemotes = {},
    remoteDataEvent = Instance.new("BindableEvent"),
    eventSet = false,
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
        local b = string.byte(name, i)
        if b > 127 or b < 32 then
            return true
        end
    end
    return false
end

local function isValidRemote(instance)
    if typeof(instance) ~= "Instance" then
        return false
    end
    if instance == G.remoteDataEvent then
        return false
    end
    if not G.remotesViewing[instance.ClassName] then
        return false
    end
    return true
end

local function getOrCreateRemote(instance)
    local remote = G.currentRemotes[instance]
    if not remote then
        remote = Remote.new(instance)
        G.currentRemotes[instance] = remote
        if hasWeirdCharacters(instance.Name) then
            G.weirdNameRemotes[instance] = remote
        end
    end
    return remote
end

local function handleCall(instance, method, vargs)
    local remote = getOrCreateRemote(instance)
    if remote.Blocked or remote:AreArgsBlocked(vargs) then
        return true
    end
    if G.eventSet and not remote.Ignored and not remote:AreArgsIgnored(vargs) then
        local cs, fi = nil, nil
        pcall(function() cs = G.getCallingScript() end)
        pcall(function() fi = G.getInfo(3).func end)
        remote:IncrementCalls({
            script = cs,
            args = vargs,
            func = fi,
            method = method
        })
        G.remoteDataEvent:Fire(instance, {script = cs, args = vargs, method = method})
    end
    return false
end

local nmc = nil
nmc = G.hookMetaMethod(game, "__namecall", G.newCClosure(function(self, ...)
    if G.checkCaller() then
        return nmc(self, ...)
    end
    if not isValidRemote(self) then
        return nmc(self, ...)
    end
    local m = G.namecallMap[G.getNamecallMethod()]
    if m then
        if handleCall(self, m, {...}) then
            return nil
        end
    end
    return nmc(self, ...)
end))

for cn, hk in pairs(G.methodHooks) do
    local orig
    orig = G.hookFunction(hk, G.newCClosure(function(self, ...)
        if typeof(self) ~= "Instance" then
            return orig(self, ...)
        end
        if self.ClassName == cn and isValidRemote(self) then
            if handleCall(self, G.methodNames[cn], {...}) then
                return nil
            end
        end
        return orig(self, ...)
    end))
end

local function connectEvent(callback)
    G.remoteDataEvent.Event:Connect(callback)
    G.eventSet = true
end

RemoteSpy.RemotesViewing = G.remotesViewing
RemoteSpy.CurrentRemotes = G.currentRemotes
RemoteSpy.WeirdNameRemotes = G.weirdNameRemotes
RemoteSpy.ConnectEvent = connectEvent
RemoteSpy.RequiredMethods = requiredMethods

RemoteSpy.GetWeirdNameRemotes = function()
    return G.weirdNameRemotes
end

RemoteSpy.GetBindables = function()
    local r = {}
    for i, v in pairs(G.currentRemotes) do
        if i.ClassName == "BindableEvent" or i.ClassName == "BindableFunction" then
            r[i] = v
        end
    end
    return r
end

RemoteSpy.HasWeirdCharacters = hasWeirdCharacters

return RemoteSpy
