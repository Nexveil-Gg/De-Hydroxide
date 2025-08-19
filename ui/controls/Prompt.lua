local Prompts = import("rbxassetid://11389137937").Base.Prompts

local Prompt = {}
local currentPrompt

function Prompt.new(instance)
    local prompt = {}

    prompt.Instance = instance
    prompt.Show = Prompt.show
    prompt.Hide = Prompt.hide

    return prompt
end

function Prompt.show(prompt)
    currentPrompt = prompt

    Prompts.PromptShadow.Visible = true
    prompt.Instance.Visible = true
end

function Prompt.hide(prompt)
    Prompts.PromptShadow.Visible = false
    prompt.Instance.Visible = false

    currentPrompt = nil
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = import("rbxassetid://5042114982") 
local ModifyConstant = Assets.ModifyUpvalue:Clone()

ModifyConstant.Name = "ModifyConstant"

ModifyConstant.Inner.Title.Text = "Modify Constant"

return ModifyConstant


return Prompt
