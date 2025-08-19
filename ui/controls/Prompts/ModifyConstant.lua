local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ModifyUpvalue şablonunu kullanıyoruz
local Assets = import("rbxassetid://5042114982") 
local ModifyConstant = Assets.ModifyUpvalue:Clone()

ModifyConstant.Name = "ModifyConstant"

-- Başlığı değiştiriyoruz
ModifyConstant.Inner.Title.Text = "Modify Constant"

return ModifyConstant
