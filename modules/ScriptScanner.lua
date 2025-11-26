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
            local script = rawget(getfenv(v), "script")

            if typeof(script) == "Instance" and not scripts[script] then
                local isScriptType = script:IsA("LocalScript") or script:IsA("Script")
                local isNilParent = script.Parent == nil
                local isWeirdName = hasWeirdCharacters(script.Name)
                local matchesQuery = query == "" or script.Name:lower():find(query:lower())
                
                local shouldAdd = isScriptType and (isNilParent or isWeirdName or matchesQuery)
                
                if shouldAdd then
                    local validClosure = pcall(function() return getScriptClosure(script) end)
                    local validSenv = pcall(function() return getsenv(script) end)
                    
                    if validClosure or validSenv or isNilParent then
                        scripts[script] = LocalScript.new(script)
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
