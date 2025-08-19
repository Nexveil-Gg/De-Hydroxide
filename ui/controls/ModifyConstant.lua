local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = import("rbxassetid://5042114982") 
local ModifyConstant = Assets.ModifyUpvalue:Clone()

ModifyConstant.Name = "ModifyConstant"

ModifyConstant.Inner.Title.Text = "Modify Constant"

return ModifyConstant
