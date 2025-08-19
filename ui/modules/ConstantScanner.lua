local TextService = game:GetService("TextService")

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

local Base = import("rbxassetid://11389137937").Base
local Prompts = Base.Prompts
local modifyConstant = Prompt.new(Prompts.ModifyUpvalue) -- aynı prompt'u kullanıyoruz

local Query = Page.Query
local Search = Query.Search
local SearchBox = Query.Query

local constantList = List.new(Page.Results.Clip.Content)
local constantLogs = {}
local selectedLog
local selectedConstant

local spyClosureContext = ContextMenuButton.new("rbxassetid://4666593447", "Spy Closure")
local viewConstantsContext = ContextMenuButton.new("rbxassetid://5179169654", "View All Constants")
local changeConstantContext = ContextMenuButton.new("rbxassetid://5458573463", "Change Constant")
local getScriptContext = ContextMenuButton.new("rbxassetid://4891705738", "Get Script Path")

local constants = {
    tempConstantColor = Color3.fromRGB(40, 20, 20),
    tempBorderColor = Color3.fromRGB(20, 0, 0)
}

constantList:BindContextMenu(ContextMenu.new({
    spyClosureContext,
    viewConstantsContext,
    changeConstantContext,
    getScriptContext
}))

-- Constant log
local function addConstant(constant, temporary)
    local constantLog = Assets.Constant:Clone()
    local index = constant.Index
    local value = constant.Value
    local valueType = type(value)

    if temporary then
        constantLog.ImageColor3 = constants.tempConstantColor
        constantLog.Border.ImageColor3 = constants.tempBorderColor
    end

    if valueType == "function" then
        local closureName = getInfo(value).name or ''
        constantLog.Value.Text = (closureName == '' and "Unnamed function") or closureName
    else
        constantLog.Value.Text = toString(value)
    end

    constantLog.Name = index
    constantLog.Index.Text = index
    constantLog.Value.TextColor3 = oh.Constants.Syntax[valueType]
    constantLog.Icon.Image = oh.Constants.Types[valueType]

    -- Menü (Change Constant)
    local constantContextMenu = ContextMenu.new({ changeConstantContext })

    -- PC sağ tık
    constantLog.MouseButton2Click:Connect(function()
        selectedConstant = constant
        constantContextMenu:Show()
    end)

    -- Mobil uzun basma
    local pressStart = 0
    constantLog.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            pressStart = tick()
        end
    end)

    constantLog.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            local heldTime = tick() - pressStart
            if heldTime > 0.5 then
                selectedConstant = constant
                constantContextMenu:Show()
            end
        end
    end)

    return constantLog
end

-- Log Object
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

-- UI Functionality
local function addConstants()
    local query = SearchBox.Text

    if query:gsub(' ', '') ~= '' then
        if not tonumber(query) and query:len() <= 1 then
            return
        end

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

-- Change Constant callback
changeConstantContext:SetCallback(function()
    if selectedLog and selectedConstant then
        local index = selectedConstant.Index
        local indexFrame = modifyConstant.Instance.Inner.Content.Index
        local indexNumber = indexFrame.Number
        local indexWidth = TextService:GetTextSize(
            tostring(index), 18, "SourceSans", indexFrame.AbsoluteSize
        ).X

        indexNumber.Text = index
        indexNumber.Size = UDim2.new(0, indexWidth, 0, 25)

        modifyConstant:Show()
    end
end)

-- Prompt "Set" butonu → debug.setconstant
modifyConstant.Instance.Inner.Buttons.SetCancel.Set.MouseButton1Click:Connect(function()
    if selectedLog and selectedConstant then
        local closure = selectedLog.Closure.Data
        local index = selectedConstant.Index
        local raw = modifyConstant.Instance.Inner.Content.Value.Input.Text
        local valueType = typeof(selectedConstant.Value)
        local newValue

        if valueType == "number" then
            newValue = tonumber(raw)
        elseif valueType == "boolean" then
            newValue = (raw == "true")
        else
            newValue = raw
        end

        if newValue ~= nil then
            setConstant(closure, index, newValue)
            modifyConstant:Hide()
        end
    end
end)

-- Prompt "Cancel" butonu
modifyConstant.Instance.Inner.Buttons.SetCancel.Cancel.MouseButton1Click:Connect(function()
    modifyConstant.Instance.Inner.Content.Value.Input.Text = ""
    modifyConstant:Hide()
end)

-- Arama
Search.MouseButton1Click:Connect(addConstants)
SearchBox.FocusLost:Connect(function(returned)
    if returned then
        addConstants()
    end
end)

return ConstantScanner
