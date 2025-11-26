local ScriptScanner = {}
local LocalScript = import("objects/LocalScript")

local requiredMethods = {
    ["getGc"] = true,
    ["getSenv"] = true,
    ["getProtos"] = true,
    ["getConstants"] = true,
    ["getScriptClosure"] = true,
    ["isXClosure"] = true
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

local function scan(query)
    local scripts = {}
    query = query or ""

    for _i, v in pairs(getGc()) do
        if type(v) == "function" and not isXClosure(v) then
            local scriptInstance = nil
            
            pcall(function()
                scriptInstance = rawget(getfenv(v), "script")
            end)

            if scriptInstance and typeof(scriptInstance) == "Instance" and not scripts[scriptInstance] then
                local isScriptType = scriptInstance:IsA("LocalScript") or scriptInstance:IsA("Script")
                
                if isScriptType then
                    local isNilParent = scriptInstance.Parent == nil
                    local isWeirdName = hasWeirdCharacters(scriptInstance.Name)
                    local matchesQuery = query == "" or scriptInstance.Name:lower():find(query:lower())
                    
                    if isNilParent or isWeirdName or matchesQuery then
                        pcall(function()
                            scripts[scriptInstance] = LocalScript.new(scriptInstance)
                        end)
                    end
                end
            end
        end
    end

    return scripts
end

ScriptScanner.RequiredMethods = requiredMethods
ScriptScanner.Scan = scan
return ScriptScanner
