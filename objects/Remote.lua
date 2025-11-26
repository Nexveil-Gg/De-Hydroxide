local Remote = {}

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

function Remote.new(instance)
    local remote = {}

    remote.Instance = instance
    remote.Name = instance.Name
    remote.ClassName = instance.ClassName
    remote.Parent = instance.Parent
    remote.FullName = instance.Parent and instance:GetFullName() or "nil." .. instance.Name
    
    remote.IsBindable = instance.ClassName == "BindableEvent" or instance.ClassName == "BindableFunction"
    remote.IsRemote = instance.ClassName == "RemoteEvent" or instance.ClassName == "RemoteFunction"
    remote.IsFunction = instance.ClassName == "RemoteFunction" or instance.ClassName == "BindableFunction"
    remote.IsEvent = instance.ClassName == "RemoteEvent" or instance.ClassName == "BindableEvent"
    
    remote.HasWeirdName = hasWeirdCharacters(instance.Name)
    remote.IsNilParent = instance.Parent == nil
    
    remote.Logs = {}
    remote.Calls = 0
    remote.Blocked = false
    remote.Ignored = false
    remote.BlockedArgs = {}
    remote.IgnoredArgs = {}
    
    remote.Clear = Remote.clear
    remote.Block = Remote.block
    remote.Ignore = Remote.ignore
    remote.BlockArg = Remote.blockArg
    remote.IgnoreArg = Remote.ignoreArg
    remote.UnblockArg = Remote.unblockArg
    remote.UnignoreArg = Remote.unignoreArg
    remote.AreArgsBlocked = Remote.areArgsBlocked
    remote.AreArgsIgnored = Remote.areArgsIgnored
    remote.IncrementCalls = Remote.incrementCalls
    remote.DecrementCalls = Remote.decrementCalls
    remote.GetInfo = Remote.getInfo

    return remote
end

function Remote.clear(remote)
    remote.Calls = 0
    remote.Logs = {}
end

function Remote.block(remote)
    remote.Blocked = not remote.Blocked
end

function Remote.ignore(remote)  
    remote.Ignored = not remote.Ignored
end

function Remote.blockArg(remote, index, value, byType)
    local blockedArgs = remote.BlockedArgs
    local blockedIndex = blockedArgs[index]

    if not blockedIndex then
        blockedIndex = {
            types = {},
            values = {}
        }
        blockedArgs[index] = blockedIndex
    end

    if byType then
        blockedIndex.types[value] = true
    else
        blockedIndex.values[value] = true
    end
end

function Remote.ignoreArg(remote, index, value, byType)
    local ignoredArgs = remote.IgnoredArgs
    local indexIgnore = ignoredArgs[index]

    if not indexIgnore then
        indexIgnore = {
            types = {},
            values = {}
        }
        ignoredArgs[index] = indexIgnore
    end

    if byType then
        indexIgnore.types[value] = true
    else
        indexIgnore.values[value] = true
    end
end

function Remote.unblockArg(remote, index, value, byType)
    local blockedArgs = remote.BlockedArgs
    local blockedIndex = blockedArgs[index]

    if blockedIndex then
        if byType then
            blockedIndex.types[value] = nil
        else
            blockedIndex.values[value] = nil
        end
    end
end

function Remote.unignoreArg(remote, index, value, byType)
    local ignoredArgs = remote.IgnoredArgs
    local indexIgnore = ignoredArgs[index]

    if indexIgnore then
        if byType then
            indexIgnore.types[value] = nil
        else
            indexIgnore.values[value] = nil
        end
    end
end

function Remote.areArgsBlocked(remote, args)
    local blockedArgs = remote.BlockedArgs

    for index, value in pairs(args) do
        local indexBlock = blockedArgs[index]
        
        if indexBlock then
            if indexBlock.types[typeof(value)] then
                return true
            end
            if indexBlock.values[value] ~= nil then
                return true
            end
        end
    end
    
    return false
end

function Remote.areArgsIgnored(remote, args)
    local ignoredArgs = remote.IgnoredArgs

    for index, value in pairs(args) do
        local indexIgnore = ignoredArgs[index]

        if indexIgnore then
            if indexIgnore.types[typeof(value)] then
                return true
            end
            if indexIgnore.values[value] ~= nil then
                return true
            end
        end
    end
    
    return false
end

function Remote.incrementCalls(remote, callData)
    remote.Calls = remote.Calls + 1
    table.insert(remote.Logs, callData)
end

function Remote.decrementCalls(remote, callData)
    local logs = remote.Logs

    remote.Calls = remote.Calls - 1
    local index = table.find(logs, callData)
    if index then
        table.remove(logs, index)
    end
end

function Remote.getInfo(remote)
    return {
        Name = remote.Name,
        ClassName = remote.ClassName,
        FullName = remote.FullName,
        IsBindable = remote.IsBindable,
        IsRemote = remote.IsRemote,
        IsFunction = remote.IsFunction,
        IsEvent = remote.IsEvent,
        HasWeirdName = remote.HasWeirdName,
        IsNilParent = remote.IsNilParent,
        Calls = remote.Calls,
        Blocked = remote.Blocked,
        Ignored = remote.Ignored
    }
end

Remote.HasWeirdCharacters = hasWeirdCharacters

return Remote    if byType then
        indexIgnore.types[value] = true
    else
        indexIgnore.values[value] = true
    end
end

function Remote.areArgsBlocked(remote, args)
    local blockedArgs = remote.BlockedArgs

    for index, value in pairs(args) do
        local indexBlock = blockedArgs[index]
        
        if indexBlock and ( indexBlock.types[typeof(value)] or indexBlock.values[value] ~= nil ) then
            return true
        end
    end
end

function Remote.areArgsIgnored(remote, args)
    local ignoredArgs = remote.IgnoredArgs

    for index, value in pairs(args) do
        local indexIgnore = ignoredArgs[index]

        if indexIgnore and ( indexIgnore.types[typeof(value)] or indexIgnore.values[value] ~= nil ) then
            return true
        end
    end
end

function Remote.incrementCalls(remote, vargs)
    remote.Calls = remote.Calls + 1
    table.insert(remote.Logs, vargs)
end

function Remote.decrementCalls(remote, vargs)
    local logs = remote.Logs

    remote.Calls = remote.Calls - 1
    table.remove(logs, table.find(logs, vargs))
end

return Remote
