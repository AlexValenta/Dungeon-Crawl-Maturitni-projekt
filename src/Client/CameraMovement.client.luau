--[[
    Zjednodušený Souls-like Camera Systém
    Vytvořeno pro: Požadavek uživatele
    Umístění: StarterPlayer > StarterPlayerScripts > LocalScript
    
    AKTUALIZOVANÁ VERZE: Přidána ochrana kamery proti zdem (Raycasting).
    
    Funkce:
    1. (C) - Přepínání LockOn na nejbližšího nepřítele.
    2. (OSTATNÍ) - Výchozí FreeCam.
]]

-- Služby (Services)
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

-- Základní proměnné
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Proměnné pro postavu (načtou se po připojení)
local character
local humanoid
local rootPart

-- Stavy kamery
local CameraState = {
	Free = 1,
	LockOn = 2
}
local currentState = CameraState.Free

-- Nastavení
local MAX_LOCK_ON_DISTANCE = 60
local LOCKON_OFFSET = CFrame.new(0, 3, 12) -- Ideální pozice (X, Y, Z)
local CAMERA_SMOOTHNESS = 0.15
local CAMERA_WALL_OFFSET = 0.5 -- Jak daleko bude kamera od zdi, kterou zasáhne

-- NOVÁ PROMĚNNÁ: Parametry pro náš raycast (budeme je opakovaně používat)
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude -- Budeme ignorovat postavu

-- Proměnné pro stav
local currentTarget = nil

--[[ -------------------------
    DEKLARACE FUNKCÍ
------------------------- ]]
local findNearestEnemy
local updateCamera
local updateLockOn
local transitionToFreeCam
local toggleLockOn
local onCharacterAdded

--[[ -------------------------
    DEFINICE FUNKCÍ
------------------------- ]]

--- HLEDÁNÍ NEPŘÁTEL
findNearestEnemy = function()
	local bestTarget = nil
	local minDistance = MAX_LOCK_ON_DISTANCE

	if not rootPart then return nil end
	local playerPos = rootPart.Position

	-- Zde se používá jiný raycast (pro hledání cíle), ten je v pořádku
	local findTargetRayParams = RaycastParams.new()
	findTargetRayParams.FilterType = Enum.RaycastFilterType.Exclude

	for _, enemy in pairs(CollectionService:GetTagged("Enemy")) do
		local enemyHumanoid = enemy:FindFirstChild("Humanoid")
		local enemyRoot = enemy:FindFirstChild("HumanoidRootPart")

		if enemyHumanoid and enemyRoot and enemyHumanoid.Health > 0 then
			local dist = (playerPos - enemyRoot.Position).Magnitude

			if dist < minDistance then
				-- Aktualizujeme findTargetRayParams, aby ignoroval postavu
				findTargetRayParams.FilterDescendantsInstances = {character}

				local direction = (enemyRoot.Position - camera.CFrame.Position)
				local ray = workspace:Raycast(camera.CFrame.Position, direction.Unit * direction.Magnitude, findTargetRayParams)

				if not ray or ray.Instance:IsDescendantOf(enemy) then
					minDistance = dist
					bestTarget = enemy
				end
			end
		end
	end

	if bestTarget then
		return bestTarget:FindFirstChild("HumanoidRootPart")
	end

	return nil
end

--- AKTUALIZACE KAMERY (RENDER STEP)
updateCamera = function(dt)
	if not character or not humanoid or humanoid.Health <= 0 or not rootPart then
		return
	end

	if currentState == CameraState.LockOn then
		updateLockOn(dt)
	end
end

--- Logika pro stav LockOn (TATO ČÁST BYLA UPRAVENA)
updateLockOn = function(dt)
	if not currentTarget or not currentTarget.Parent or not currentTarget.Parent:FindFirstChild("Humanoid") or currentTarget.Parent:FindFirstChild("Humanoid").Health <= 0 then
		transitionToFreeCam()
		return
	end

	-- 1. Otáčení postavy
	local lookVector = (currentTarget.Position - rootPart.Position).Unit
	local targetCFrame = CFrame.new(rootPart.Position, rootPart.Position + Vector3.new(lookVector.X, 0, lookVector.Z))
	rootPart.CFrame = rootPart.CFrame:Lerp(targetCFrame, CAMERA_SMOOTHNESS)

	-- 2. Na co se kamera dívá
	local cameraFocus = currentTarget.Position + Vector3.new(0, 1.5, 0)

	-- 3. Výpočet pozice kamery (NOVÁ LOGIKA)

	-- Bod, odkud "vystřelíme" paprsek. Je to v podstatě hlava hráče,
	-- posunutá o X a Y offsetu kamery.
	local cameraPivotPos = (rootPart.CFrame * CFrame.new(LOCKON_OFFSET.X, LOCKON_OFFSET.Y, 0)).Position

	-- Pozice, kde by kamera *chtěla* být (ideální)
	local idealCamPos = (rootPart.CFrame * LOCKON_OFFSET).Position

	-- Směr a vzdálenost od pivotu k ideální pozici
	local camDirection = (idealCamPos - cameraPivotPos).Unit
	-- Vzdálenost je Z složka z LOCKON_OFFSET
	local camDistance = LOCKON_OFFSET.Z

	-- Než spustíme raycast, řekneme mu, aby ignoroval naši postavu
	rayParams.FilterDescendantsInstances = {character}

	-- 4. Vystřelení paprsku (Raycast)
	local ray = workspace:Raycast(cameraPivotPos, camDirection * camDistance, rayParams)

	local finalCamPos
	if ray then
		-- ZASÁHLI JSME ZEĎ!
		-- Umístíme kameru těsně PŘED bod zásahu (ray.Position)
		finalCamPos = ray.Position - (camDirection * CAMERA_WALL_OFFSET)
	else
		-- Žádná překážka, použijeme ideální pozici
		finalCamPos = idealCamPos
	end

	-- 5. Aplikace pozice
	-- Použijeme CFrame.lookAt pro vytvoření CFrame z finální pozice, která se dívá na cíl
	local newCamCFrame = CFrame.lookAt(finalCamPos, cameraFocus)
	camera.CFrame = camera.CFrame:Lerp(newCamCFrame, CAMERA_SMOOTHNESS)
end


--- PŘECHODY MEZI STAVY
transitionToFreeCam = function()
	if currentState == CameraState.Free then return end

	currentState = CameraState.Free
	currentTarget = nil

	if humanoid then
		humanoid.AutoRotate = true
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


--[[ -------------------------
    INICIALIZACE A VSTUPY
------------------------- ]]

--- Funkce pro načtení proměnných postavy
onCharacterAdded = function(newChar)
	character = newChar
	humanoid = newChar:WaitForChild("Humanoid")
	rootPart = newChar:WaitForChild("HumanoidRootPart")

	humanoid.Died:Connect(function()
		transitionToFreeCam()
	end)

	transitionToFreeCam()
end

--- Sledování vstupů od hráče
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.C then
		toggleLockOn()
	end
end)

--- Připojení k RenderStep
RunService:BindToRenderStep("SoulsCameraUpdate", Enum.RenderPriority.Camera.Value, updateCamera)

--- Sledování načtení a respawnu postavy
player.CharacterAdded:Connect(onCharacterAdded)
if player.Character then
	onCharacterAdded(player.Character)
end