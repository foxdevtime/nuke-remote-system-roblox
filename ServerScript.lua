-- please, use releases only

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local Lighting = game:GetService("Lighting")

local NukeSystem = ReplicatedStorage:WaitForChild("NukeSystem")
local DropNuke = NukeSystem:WaitForChild("DropNuke")
local ShakeCameraEvent = NukeSystem:WaitForChild("ShakeCameraEvent")

local BOMB_HEIGHT = 500
local FALL_TIME = 11
local WAVE_SPEED = 200
local WAVE_MAX_RADIUS = 300
local FLASH_DURATION = 4
local NUKE_COOLDOWN = 30
local WAVE_HEIGHT = 800

local playerCooldowns = {}

local function createShockwave(startPosition)
	local wave = Instance.new("Part")
	wave.Position = startPosition + Vector3.new(0, 0.5, 0)
	wave.Size = Vector3.new(WAVE_HEIGHT, 1, 1)
	wave.Anchored = true
	wave.CanCollide = false
	wave.Transparency = 0.5
	wave.BrickColor = BrickColor.new("Bright red")
	wave.Shape = Enum.PartType.Cylinder
	wave.Orientation = Vector3.new(0, 0, 90)
	wave.Parent = workspace
	Debris:AddItem(wave, 3)
	return wave
end

local function applyShockwaveDamage(startPosition, wave)
	local startTime = tick()
	local radius = 0
	while radius < WAVE_MAX_RADIUS do
		radius = (tick() - startTime) * WAVE_SPEED
		wave.Size = Vector3.new(WAVE_HEIGHT, radius * 2, radius * 2)
		for _, player in pairs(Players:GetPlayers()) do
			if player.Character then
				local humanoid = player.Character:FindFirstChild("Humanoid")
				local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
				if humanoid and rootPart and humanoid.Health > 0 then
					local playerPos = rootPart.Position
					local distance = (Vector2.new(playerPos.X, playerPos.Z) - Vector2.new(startPosition.X, startPosition.Z)).Magnitude
					local heightDifference = math.abs(playerPos.Y - startPosition.Y)
					local waveThickness = 5
					if distance >= radius - waveThickness and distance <= radius + waveThickness and heightDifference <= WAVE_HEIGHT / 2 then
						humanoid.Health = 0
					end
				end
			end
		end
		wait()
	end
end

local function createFlashLight(targetPosition)
	local lightPart = Instance.new("Part")
	lightPart.Position = targetPosition
	lightPart.Size = Vector3.new(0.2, 0.2, 0.2)
	lightPart.Anchored = true
	lightPart.CanCollide = false
	lightPart.Transparency = 1
	lightPart.Parent = workspace
	Debris:AddItem(lightPart, FLASH_DURATION)

	local pointLight = Instance.new("PointLight")
	pointLight.Brightness = 10
	pointLight.Range = 1000
	pointLight.Color = Color3.new(1, 1, 1)
	pointLight.Parent = lightPart

	local startTime = tick()
	while tick() - startTime < FLASH_DURATION do
		local t = (tick() - startTime) / FLASH_DURATION
		pointLight.Brightness = 10 * (1 - t)
		pointLight.Range = 1000 * (1 - t)
		wait()
	end
end

local function createFlashEffect()
	for _, player in pairs(Players:GetPlayers()) do
		local playerGui = player:FindFirstChild("PlayerGui")
		if playerGui then
			local flashFrame = Instance.new("Frame")
			flashFrame.BackgroundColor3 = Color3.new(1, 1, 1)
			flashFrame.Size = UDim2.new(1, 0, 1, 0)
			flashFrame.BackgroundTransparency = 0
			flashFrame.Parent = playerGui

			local colorCorrection = Instance.new("ColorCorrectionEffect")
			colorCorrection.Brightness = 1
			colorCorrection.Contrast = 0
			colorCorrection.Saturation = 0
			colorCorrection.TintColor = Color3.new(1, 1, 1)
			colorCorrection.Parent = Lighting

			local startTime = tick()
			while tick() - startTime < FLASH_DURATION do
				local t = (tick() - startTime) / FLASH_DURATION
				flashFrame.BackgroundTransparency = t
				colorCorrection.Brightness = 1 - t
				wait()
			end

			flashFrame:Destroy()
			colorCorrection:Destroy()
		end
	end
end

local function dropBomb(targetPosition)
	local bombTemplate = NukeSystem:WaitForChild("NukeModel")
	local bomb = bombTemplate:Clone()

	local mainPart = bomb:GetChildren()[1]
	for _, part in pairs(bomb:GetChildren()) do
		if part:IsA("BasePart") and part ~= mainPart then
			local weld = Instance.new("Weld")
			weld.Part0 = mainPart
			weld.Part1 = part
			weld.C0 = mainPart.CFrame:Inverse() * part.CFrame
			weld.Parent = mainPart
			part.Anchored = false
		end
	end

	mainPart.Position = targetPosition + Vector3.new(0, BOMB_HEIGHT, 0)
	bomb.Parent = workspace

	local siren = Instance.new("Sound")
	siren.SoundId = "rbxassetid://433848566"
	siren.Volume = 3
	siren.Looped = false
	siren.Parent = mainPart
	siren:Play()

	local startTime = tick()
	local startHeight = BOMB_HEIGHT
	while tick() - startTime < FALL_TIME do
		local t = (tick() - startTime) / FALL_TIME
		local newHeight = startHeight * (1 - t)
		mainPart.Position = targetPosition + Vector3.new(0, newHeight, 0)
		wait()
	end

	mainPart.Position = targetPosition
	siren:Stop()
	siren:Destroy()

	local explosionSound = Instance.new("Sound")
	explosionSound.SoundId = "rbxassetid://245537790"
	explosionSound.Volume = 4
	explosionSound.Parent = workspace
	explosionSound:Play()
	Debris:AddItem(explosionSound, 9)

	ShakeCameraEvent:FireAllClients()
	spawn(function() createFlashLight(targetPosition) end)
	spawn(function() createFlashEffect() end)

	local explosion = Instance.new("Explosion")
	explosion.Position = targetPosition
	explosion.BlastRadius = 50
	explosion.BlastPressure = 0
	explosion.DestroyJointRadiusPercent = 0
	explosion.Parent = workspace

	local wave = createShockwave(targetPosition)
	spawn(function() applyShockwaveDamage(targetPosition, wave) end)

	bomb:Destroy()
end

DropNuke.OnServerEvent:Connect(function(player, hitPosition)
	local lastUse = playerCooldowns[player.UserId] or 0
	local currentTime = tick()

	if currentTime - lastUse < NUKE_COOLDOWN then
		warn("Cooldown.")
		return
	end

	playerCooldowns[player.UserId] = currentTime
	dropBomb(hitPosition)
end)

Players.PlayerRemoving:Connect(function(player)
	playerCooldowns[player.UserId] = nil
end)
