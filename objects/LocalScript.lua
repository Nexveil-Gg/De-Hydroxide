local LocalScript = {}

function LocalScript.new(instance)
    local localScript = {}
    
    local closureSuccess, closure = pcall(function()
        return getScriptClosure(instance)
    end)
    
    local senvSuccess, senv = pcall(function()
        return getsenv(instance)
    end)
    
    localScript.Instance = instance
    localScript.Name = instance.Name
    localScript.ClassName = instance.ClassName
    localScript.Parent = instance.Parent
    localScript.FullName = instance.Parent and instance:GetFullName() or "nil." .. instance.Name
    
    localScript.IsNilParent = instance.Parent == nil
    localScript.HasWeirdName = LocalScript.hasWeirdCharacters(instance.Name)
    
    localScript.Environment = senvSuccess and senv or nil
    localScript.Closure = closureSuccess and closure or nil
    localScript.Constants = closureSuccess and closure and getConstants(closure) or {}
    localScript.Protos = closureSuccess and closure and getProtos(closure) or {}
    
    return localScript
end

function LocalScript.hasWeirdCharacters(name)
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

return LocalScript
