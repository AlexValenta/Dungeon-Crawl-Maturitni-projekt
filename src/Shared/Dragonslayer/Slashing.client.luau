--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

--// Remotes
local SwingEvent = ReplicatedStorage.Remotes:WaitForChild("SwingEvent")

local tool = script.Parent
local player = Players.LocalPlayer

-- Settings
local COOLDOWN = 0.3
local FINAL_COOLDOWN = 0.7
local RESET_TIME = 3
local STAMINA_COST = 10
local ROLL_BLOCK_TIME = 1

local animations = {
	Attacks = {
		"rbxassetid://102187978723525",
		"rbxassetid://127860831293912",
		"rbxassetid://84452951426095",
	}
}

local swingTracks = {}
local comboStep = 1
local canSwing = true
local lastSwingTime = 0
local humanoid
local animator
local staminaValue
local lastRollTime = 0

------------------------------------------------------------
-- Lock movement
------------------------------------------------------------
local function lockMovement()
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0
end

local function unlockMovement()
	humanoid.WalkSpeed = 13
	humanoid.JumpPower = 50
end

------------------------------------------------------------
-- Disable inputs
------------------------------------------------------------
local function blockInputs()
	ContextActionService:BindAction(
		"DisableControls",
		function() return Enum.ContextActionResult.Sink end,
		false,
		unpack(Enum.PlayerActions:GetEnumItems())
	)
end

local function unblockInputs()
	ContextActionService:UnbindAction("DisableControls")
end


------------------------------------------------------------
-- Prepare
------------------------------------------------------------
tool.Equipped:Connect(function()
	local char = player.Character or player.CharacterAdded:Wait()
	humanoid = char:WaitForChild("Humanoid")
	animator = humanoid:WaitForChild("Animator")

	staminaValue = player:WaitForChild("Stamina")

	swingTracks = {}
	for i, animId in ipairs(animations.Attacks) do
		local anim = Instance.new("Animation")
		anim.AnimationId = animId
		swingTracks[i] = animator:LoadAnimation(anim)
		swingTracks[i].Priority = Enum.AnimationPriority.Action4
	end
end)


------------------------------------------------------------
-- Attack
------------------------------------------------------------
tool.Activated:Connect(function()
	if not canSwing then return end
	if staminaValue.Value < STAMINA_COST then return end
	if tick() - lastRollTime < ROLL_BLOCK_TIME then return end
	if #swingTracks == 0 then return end

	local now = tick()
	if now - lastSwingTime > RESET_TIME then
		comboStep = 1
	end

	local track = swingTracks[comboStep]

	-- Apply cost
	staminaValue.Value = math.max(0, staminaValue.Value - STAMINA_COST)

	-- Prevent spamming
	canSwing = false
	lockMovement()
	blockInputs()

	for _, t in ipairs(animator:GetPlayingAnimationTracks()) do
		if t ~= track and t.Priority.Value >= Enum.AnimationPriority.Action.Value then
			t:Stop()
		end
	end


	-- Play attack
	track:Play()
	SwingEvent:FireServer(tool, comboStep)

	lastSwingTime = now
	comboStep += 1
	if comboStep > #swingTracks then
		comboStep = 1
	end

	-- Cooldown
	local cd = comboStep == 1 and FINAL_COOLDOWN or COOLDOWN

	task.delay(cd, function()
		canSwing = true
		unlockMovement()
		unblockInputs()
	end)
end)

------------------------------------------------------------
-- Space detection for roll block
------------------------------------------------------------
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.Space then
		lastRollTime = tick()
	end
end)
