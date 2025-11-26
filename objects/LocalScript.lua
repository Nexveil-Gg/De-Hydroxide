local LocalScript = {}

function LocalScript.new(instance)
    local localScript = {}
    
    local closure = nil
    local senv = nil
    
    pcall(function()
        closure = getScriptClosure(instance)
    end)
    
    pcall(function()
        senv = getsenv(instance)
    end)
    
    localScript.Instance = instance
    localScript.Name = instance.Name
    localScript.ClassName = instance.ClassName
    localScript.Parent = instance.Parent
    localScript.FullName = instance.Parent and instance:GetFullName() or "nil." .. instance.Name
    
    localScript.IsNilParent = instance.Parent == nil
    localScript.HasWeirdName = LocalScript.hasWeirdCharacters(instance.Name)
    
    localScript.Environment = senv
    localScript.Closure = closure
    
    local constants = {}
    local protos = {}
    
    if closure and type(closure) == "function" then
        pcall(function()
            constants = getConstants(closure)
        end)
        
        pcall(function()
            protos = getProtos(closure)
        end)
    end
    
    localScript.Constants = constants
    localScript.Protos = protos
    
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
