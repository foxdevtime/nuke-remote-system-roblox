-- please, use releases only

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local NukeSystem = ReplicatedStorage:WaitForChild("NukeSystem")
local DropNuke = NukeSystem:WaitForChild("DropNuke")

local tool = script.Parent
local player = Players.LocalPlayer
local mouse = player:GetMouse()

tool.Equipped:Connect(function()
	mouse.Button1Down:Connect(function()
		local rayOrigin = player.Character.HumanoidRootPart.Position
		local rayDirection = mouse.Hit.Position - rayOrigin
		local raycastParams = RaycastParams.new()
		raycastParams.FilterDescendantsInstances = {player.Character}
		raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

		local raycastResult = workspace:Raycast(rayOrigin, rayDirection * 1000, raycastParams)
		if raycastResult then
			local hitPosition = raycastResult.Position
			DropNuke:FireServer(hitPosition)
		end
	end)
end)
