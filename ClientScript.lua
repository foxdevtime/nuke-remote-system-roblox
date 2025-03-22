-- please, use releases only

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local NukeSystem = ReplicatedStorage:WaitForChild("NukeSystem")
local ShakeCameraEvent = NukeSystem:WaitForChild("ShakeCameraEvent")

local SHAKE_DURATION = 1
local SHAKE_INTENSITY = 0.5
local SHAKE_FREQUENCY = 15

local function shakeCamera()
	local camera = workspace.CurrentCamera
	local originalCFrame = camera.CFrame
	local startTime = tick()

	while tick() - startTime < SHAKE_DURATION do
		local time = tick() - startTime
		local offset = Vector3.new(
			math.noise(time * SHAKE_FREQUENCY, 0) * SHAKE_INTENSITY,
			math.noise(0, time * SHAKE_FREQUENCY) * SHAKE_INTENSITY,
			0
		) * (1 - time / SHAKE_DURATION)

		camera.CFrame = originalCFrame * CFrame.new(offset)
		RunService.RenderStepped:Wait()
	end

	camera.CFrame = originalCFrame
end

ShakeCameraEvent.OnClientEvent:Connect(shakeCamera)
