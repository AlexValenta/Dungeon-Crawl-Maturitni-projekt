local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

UserInputService.MouseIconEnabled = false

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local character
local humanoid
local rootPart

local CameraState = {
	Free = 1,
	LockOn = 2
}
local currentState = CameraState.Free

local MAX_LOCK_ON_DISTANCE = 40
local LOCKON_OFFSET = CFrame.new(0, 3, 12)
local CAMERA_SMOOTHNESS = 0.15
local CAMERA_WALL_OFFSET = 0.5
local CHARACTER_ROTATION_SPEED = 0.2

local BOB_SPEED = 6
local BOB_INTENSITY = 0.3
local TILT_ANGLE = 2.5
local TILT_SPEED = 6

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local currentTarget = nil
local isMouseUnlocked = false
local bobTime = 0
local currentTilt = 0

-- Deklarace funkcí
local findNearestEnemy
local updateCamera
local updateLockOn
local updateFreeCam
local transitionToFreeCam
local toggleLockOn
local onCharacterAdded
local updateMouseBehavior

-- Funkce pro nalezení NEJBLIŽŠÍHO živého nepřítele v dosahu
findNearestEnemy = function()
	local bestTarget = nil
	local minDistance = MAX_LOCK_ON_DISTANCE

	if not rootPart then return nil end
	local playerPos = rootPart.Position

	local findTargetRayParams = RaycastParams.new()
	findTargetRayParams.FilterType = Enum.RaycastFilterType.Exclude

	for _, enemy in pairs(CollectionService:GetTagged("Enemy")) do
		local enemyHumanoid = enemy:FindFirstChild("Humanoid")
		local enemyRoot = enemy:FindFirstChild("HumanoidRootPart")

		-- Hledáme pouze ty, kteří mají více než 0 HP
		if enemyHumanoid and enemyRoot and enemyHumanoid.Health > 0 then
			local dist = (playerPos - enemyRoot.Position).Magnitude

			if dist < minDistance then
				findTargetRayParams.FilterDescendantsInstances = {character}

				local direction = (enemyRoot.Position - camera.CFrame.Position)
				local ray = workspace:Raycast(camera.CFrame.Position, direction.Unit * direction.Magnitude, findTargetRayParams)

				-- Kontrola viditelnosti (aby nebyl za zdí)
				if not ray or ray.Instance:IsDescendantOf(enemy) then
					minDistance = dist
					bestTarget = enemyRoot
				end
			end
		end
	end

	return bestTarget
end

updateMouseBehavior = function()
	UserInputService.MouseIconEnabled = false

	if isMouseUnlocked then
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	else
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	end
end

updateCamera = function(dt)
	updateMouseBehavior()

	if not character or not humanoid or humanoid.Health <= 0 or not rootPart then
		return
	end

	if currentState == CameraState.LockOn then
		updateLockOn(dt)
	elseif currentState == CameraState.Free then
		updateFreeCam(dt)
	end
end

updateLockOn = function(dt)
	-- Zkontrolujeme, jestli aktuální target stále existuje a JESTLI ŽIJE
	local targetIsDead = false
	if not currentTarget or not currentTarget.Parent then
		targetIsDead = true
	else
		local targetHum = currentTarget.Parent:FindFirstChild("Humanoid")
		if not targetHum or targetHum.Health <= 0 then
			targetIsDead = true
		end
	end

	-- Pokud cíl umřel nebo zmizel, najdeme nového
	if targetIsDead then
		local newTarget = findNearestEnemy()
		if newTarget then
			currentTarget = newTarget -- Našli jsme dalšího, plynule na něj navážeme
		else
			transitionToFreeCam() -- Nikdo nablízku, odemykáme kameru
			return
		end
	end

	-- Výpočet pozice pro Lock-On
	local lookVector = (currentTarget.Position - rootPart.Position).Unit
	local targetCFrame = CFrame.new(rootPart.Position, rootPart.Position + Vector3.new(lookVector.X, 0, lookVector.Z))
	rootPart.CFrame = rootPart.CFrame:Lerp(targetCFrame, CAMERA_SMOOTHNESS)

	local cameraFocus = currentTarget.Position + Vector3.new(0, 1.5, 0)

	local cameraPivotPos = (rootPart.CFrame * CFrame.new(LOCKON_OFFSET.X, LOCKON_OFFSET.Y, 0)).Position
	local idealCamPos = (rootPart.CFrame * LOCKON_OFFSET).Position
	local camDirection = (idealCamPos - cameraPivotPos).Unit
	local camDistance = LOCKON_OFFSET.Z

	rayParams.FilterDescendantsInstances = {character}

	local ray = workspace:Raycast(cameraPivotPos, camDirection * camDistance, rayParams)

	local finalCamPos
	if ray then
		finalCamPos = ray.Position - (camDirection * CAMERA_WALL_OFFSET)
	else
		finalCamPos = idealCamPos
	end

	-- ViewBob (pohupování při chůzi)
	local moveDir = humanoid.MoveDirection
	local isMoving = moveDir.Magnitude > 0.1

	if isMoving then
		bobTime = bobTime + dt * BOB_SPEED
	else
		bobTime = 0
	end

	local bobX = math.cos(bobTime / 2) * (BOB_INTENSITY * 0.5)
	local bobY = math.sin(bobTime) * BOB_INTENSITY

	if not isMoving then
		bobX = 0
		bobY = 0
	end

	-- Tilt (naklánění při pohybu do stran)
	local targetTilt = 0
	if isMoving then
		local rightVector = camera.CFrame.RightVector
		local dot = moveDir:Dot(rightVector)
		targetTilt = -dot * math.rad(TILT_ANGLE)
	end

	currentTilt = math.lerp(currentTilt, targetTilt, dt * TILT_SPEED)

	-- Spojení všeho dohromady
	local newCamCFrame = CFrame.lookAt(finalCamPos, cameraFocus)
	newCamCFrame = newCamCFrame * CFrame.Angles(0, 0, currentTilt) * CFrame.new(bobX, bobY, 0)

	camera.CFrame = camera.CFrame:Lerp(newCamCFrame, CAMERA_SMOOTHNESS)
end

updateFreeCam = function(dt)
	local moveDirection = humanoid.MoveDirection

	if moveDirection.Magnitude > 0.1 then
		local targetCFrame = CFrame.new(rootPart.Position, rootPart.Position + moveDirection)
		rootPart.CFrame = rootPart.CFrame:Lerp(targetCFrame, CHARACTER_ROTATION_SPEED)
	end
end

transitionToFreeCam = function()
	if currentState == CameraState.Free then return end

	currentState = CameraState.Free
	currentTarget = nil
	bobTime = 0
	currentTilt = 0

	if humanoid then
		humanoid.AutoRotate = false
	end

	camera.CameraType = Enum.CameraType.Custom
	camera.CameraSubject = humanoid
end

toggleLockOn = function()
	if currentState == CameraState.LockOn then
		transitionToFreeCam()

	elseif currentState == CameraState.Free then
		local target = findNearestEnemy()
		if target then
			currentState = CameraState.LockOn
			currentTarget = target
			humanoid.AutoRotate = false
			camera.CameraType = Enum.CameraType.Scriptable
			camera.CameraSubject = nil
		end
	end
end

onCharacterAdded = function(newChar)
	character = newChar
	humanoid = newChar:WaitForChild("Humanoid")
	rootPart = newChar:WaitForChild("HumanoidRootPart")

	humanoid.Died:Connect(function()
		transitionToFreeCam()
		isMouseUnlocked = true
	end)

	transitionToFreeCam()
	if humanoid then humanoid.AutoRotate = false end

	isMouseUnlocked = false
end

-- Vstupy od hráče
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.C then
		toggleLockOn()
	elseif input.KeyCode == Enum.KeyCode.LeftAlt then
		isMouseUnlocked = not isMouseUnlocked
	end
end)

-- Hlavní RenderStep smyčka kamery
RunService:BindToRenderStep("SoulsCameraUpdate", Enum.RenderPriority.Camera.Value, updateCamera)

-- Inicializace hráče
player.CharacterAdded:Connect(onCharacterAdded)
if player.Character then
	onCharacterAdded(player.Character)
end