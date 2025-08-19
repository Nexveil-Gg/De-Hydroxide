local TextService = game:GetService("TextService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local ConstantScanner = {}
local ClosureSpy = import("modules/ClosureSpy")
local Methods = import("modules/ConstantScanner")

if not hasMethods(Methods.RequiredMethods) then
    return ConstantScanner
end

local Constant = import("objects/Constant")
local List, ListButton = import("ui/controls/List")
local MessageBox, MessageType = import("ui/controls/MessageBox")
local ContextMenu, ContextMenuButton = import("ui/controls/ContextMenu")
local TabSelector = import("ui/controls/TabSelector")
local Prompt = import("ui/controls/Prompt")

local Page = import("rbxassetid://11389137937").Base.Body.Pages.ConstantScanner
local Assets = import("rbxassetid://5042114982").ConstantScanner

local Query = Page.Query
local Search = Query.Search
local SearchBox = Query.Query

local constantList = List.new(Page.Results.Clip.Content)
local constantLogs = {}
local selectedLog
local selectedConstant
local selectedConstantLog
local pressHold = false

local spyClosureContext = ContextMenuButton.new("rbxassetid://4666593447", "Spy Closure")
local viewConstantsContext = ContextMenuButton.new("rbxassetid://5179169654", "View All Constants")
local changeConstantContext = ContextMenuButton.new("rbxassetid://5458573463", "Change Constant")

local constants = {
    tempConstantColor = Color3.fromRGB(40, 20, 20),
    tempBorderColor = Color3.fromRGB(20, 0, 0)
}

constantList:BindContextMenu(ContextMenu.new({ spyClosureContext, viewConstantsContext, getScriptContext, changeConstantContext }))

local modifyConstant = Prompt.new(Page.Prompts.ModifyUpvalue)
local modifyConstantInner = modifyConstant.Instance.Inner
local modifyConstantContent = modifyConstantInner.Content
local modifyConstantButtons = modifyConstantInner.Buttons.SetCancel
local modifyConstantValue = modifyConstantContent.Value.Input

local function setValue(valueText, value)
    local raw = valueText
    local valueType = typeof(value)
    local newValue

    if valueType == "string" then
        newValue = raw
    elseif valueType == "number" then
        local convert = tonumber(raw)
        if convert then
            newValue = convert
        else
            MessageBox.Show("Error", "Value does not match selected type", MessageType.OK)
        end
    elseif valueType == "boolean" then
        if raw == "true" then
            newValue = true
        elseif raw == "false" then
            newValue = false
        else
            MessageBox.Show("Error", "Value does not match selected type", MessageType.OK)
        end
    else
        local success, result = pcall(loadstring("return " .. raw))
        if success and typeof(result) == valueType then
            newValue = result
        else
            MessageBox.Show("Error", "There is an error in your input", MessageType.OK)
        end
    end

    return newValue
end

local function addConstant(constant, temporary)
    local constantLog = Assets.Constant:Clone()
    local index = constant.Index
    local value = constant.Value
    local valueType = type(value)
    local valueText = tostring(value)

    if temporary then
        constantLog.ImageColor3 = constants.tempConstantColor
        constantLog.Border.ImageColor3 = constants.tempBorderColor
    end

    if valueType == "function" then
        local closureName = getInfo(value).name or ''
        constantLog.Value.Text = (closureName == '' and "Unnamed function") or closureName
    else
        constantLog.Value.Text = valueText
    end

    constantLog.Name = index
    constantLog.Index.Text = index
    constantLog.Value.TextColor3 = oh.Constants.Syntax[valueType]
    constantLog.Icon.Image = oh.Constants.Types[valueType]

    -- Basılı tutma mobil/PC
    constantLog.MouseButton1Click:Connect(function()
        pressHold = true
        selectedConstant = constant
        selectedConstantLog = constantLog
        task.delay(0.5, function()
            if pressHold and selectedConstant then
                modifyConstantValue.Text = tostring(selectedConstant.Value)
                modifyConstant:Show()
            end
        end)
    end)

    constantLog.MouseButton1Up:Connect(function()
        pressHold = false
    end)

    -- Sağ tık açma
    constantLog.MouseButton2Click:Connect(function()
        selectedConstant = constant
        selectedConstantLog = constantLog
        modifyConstantValue.Text = tostring(selectedConstant.Value)
        modifyConstant:Show()
    end)

    return constantLog
end

local Log = {}

function Log.new(closure)
    local log = {}
    local button = Assets.ClosureLog:Clone()
    local listButton = ListButton.new(button, constantList)
    local constants = closure.Constants
    local logHeight = 30

    for _i, constant in pairs(constants) do
        local constantLog = addConstant(constant)
        constantLog.Parent = button.Constants
        logHeight = logHeight + constantLog.AbsoluteSize.Y + 5
    end

    if closure.Name == "Unnamed function" then
        button:FindFirstChild("Name").TextColor3 = Color3.fromRGB(127, 127, 127)
    end

    button:FindFirstChild("Name").Text = closure.Name
    button.Size = UDim2.new(1, 0, 0, logHeight)

    listButton:SetRightCallback(function()
        selectedLog = log
    end)

    constantLogs[closure.Data] = log
    log.Closure = closure
    log.Constants = constants
    log.Button = listButton
    return log
end

local function addConstants()
    local query = SearchBox.Text
    if query:gsub(' ', '') ~= '' then
        if not tonumber(query) and query:len() <= 1 then return end
        constantList:Clear()
        constantLogs = {}
        for _i, closure in pairs(Methods.Scan(query)) do
            Log.new(closure)
        end
        constantList:Recalculate()
    else
        MessageBox.Show("Invalid query", "Your query is too short", MessageType.OK)
    end
    SearchBox.Text = ''
end

modifyConstantButtons.Set.MouseButton1Click:Connect(function()
    if selectedConstant then
        local newValue = setValue(modifyConstantValue.Text, selectedConstant.Value)
        if newValue ~= nil then
            selectedConstant:Set(newValue)
            modifyConstantValue.Text = ""
            modifyConstant:Hide()
        end
    end
end)

modifyConstantButtons.Cancel.MouseButton1Click:Connect(function()
    modifyConstantValue.Text = ""
    modifyConstant:Hide()
end)

spyClosureContext:SetCallback(function()
    local selectedClosure = selectedLog.Closure
    if TabSelector.SelectTab("ClosureSpy") then
        local result = ClosureSpy.Hook.new(selectedClosure)
        if result == false then
            MessageBox.Show("Already hooked", "You are already spying " .. selectedClosure.Name)
        elseif result == nil then
            MessageBox.Show("Cannot hook", ('Cannot hook "%s" because there are no constants'):format(selectedClosure.Name))
        end
    end
end)

viewConstantsContext:SetCallback(function()
    if selectedLog then
        local temporaryConstants = selectedLog.TemporaryConstants
        local instance = selectedLog.Button.Instance
        local newHeight = 0

        if temporaryConstants then
            for _i, constantLog in pairs(temporaryConstants) do
                newHeight = newHeight - (constantLog.AbsoluteSize.Y + 5)
                constantLog:Destroy()
            end
            selectedLog.TemporaryConstants = nil
            selectedLog.Closure.TemporaryConstants = {}
        else
            local closure = selectedLog.Closure
            temporaryConstants = {}
            for i,v in pairs(getConstants(closure.Data)) do
                if not closure.Constants[i] then
                    local constant = Constant.new(closure, i, v)
                    local constantLog = addConstant(constant, true)
                    constantLog.Parent = instance.Constants
                    newHeight = newHeight + constantLog.AbsoluteSize.Y + 5
                    temporaryConstants[i] = constantLog
                    closure.TemporaryConstants[i] = constant
                end
            end
            selectedLog.TemporaryConstants = temporaryConstants
        end

        newHeight = UDim2.new(0, 0, 0, newHeight)
        instance.Constants.Size = instance.Constants.Size + newHeight
        instance.Size = instance.Size + newHeight
        constantList:Recalculate()
    end
end)

getScriptContext:SetCallback(function()
    if selectedLog then
        local script = getfenv(selectedLog.Closure.Data).script
        if typeof(script) == "Instance" then
            setClipboard(getInstancePath(script))
        end
    end
end)

Search.MouseButton1Click:Connect(addConstants)
SearchBox.FocusLost:Connect(function(returned)
    if returned then addConstants() end
end)

return ConstantScanner
