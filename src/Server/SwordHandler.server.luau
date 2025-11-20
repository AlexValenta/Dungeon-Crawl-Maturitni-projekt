--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

--// Modules
local Weapons = require(ServerStorage.WeaponTemplates)

--// Remotes
local SwingEvent = ReplicatedStorage.Remotes.SwingEvent
local ClientReplicator = ReplicatedStorage.Remotes.ClientReplicator

--// Helpers
local function getTargetsInFront(player, range)
	local char = player.Character
	if not char then return {} end

	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return {} end

	local found = {}
	
	-- Predictive offset based on player velocity (optional)
	local velocityOffset = hrp.Velocity * 0.2
	
	-- Define the hitbox in front of the player, slightly ahead based on velocity
	local forwardOffset = hrp.CFrame.LookVector * (range / 1.9) -- box in front
	local boxCenter = hrp.Position + forwardOffset + velocityOffset
	
	--- Define the hitbox in front of the player, slightly ahead based on velocity
	local boxSize = Vector3.new(8, 8, range) -- hitbox (width, height, depth)
	local boxCFrame = CFrame.new(boxCenter, boxCenter + hrp.CFrame.LookVector)

	local parts = workspace:GetPartBoundsInBox(boxCFrame, boxSize)

	for _, part in ipairs(parts) do
		if part.Name == "HumanoidRootPart" then
			local model = part:FindFirstAncestorOfClass("Model")
			if model and model.Parent and model ~= char then
				local humanoid = model:FindFirstChildOfClass("Humanoid")
				if humanoid and humanoid.Health > 0 then
					table.insert(found, humanoid)
				end
			end
		end
	end

	return found
end

--// Main
SwingEvent.OnServerEvent:Connect(function(player, sword)
	local char = player.Character
	if not char or not sword then return end

	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	
	-- Look up sword properties
	local swordStats = Weapons[sword.Name]
	if not swordStats then return end

	local DAMAGE = swordStats.damage or 20
	local RANGE = swordStats.range or 8
	local KNOCKBACK = swordStats.knockback or 0
	local MOMENTUM = swordStats.momentum

	-- Ensure sword has sounds set up
	local swingSound = sword.Handle:FindFirstChild("SwingSound")
	local hitSound = sword.Handle:FindFirstChild("HitSound")

	-- Always play swing sound
	if swingSound then swingSound:Play() end
	
	-- Slash momentum
	if MOMENTUM and MOMENTUM > 0 then
		local direction = hrp.CFrame.LookVector.Unit
		local bv = Instance.new("BodyVelocity")
		bv.Velocity = direction * MOMENTUM
		bv.MaxForce = Vector3.new(1e6, 0, 1e6)
		bv.Parent = hrp

		game:GetService("Debris"):AddItem(bv, 0.15)
	end
	
	task.wait(0.1)

	-- Check for targets
	local targets = getTargetsInFront(player, RANGE)
	local hitSomething = false

	for _, humanoid in ipairs(targets) do
		humanoid:TakeDamage(DAMAGE)
		hitSomething = true

		-- Knockback based on player facing
		local targetRoot = humanoid.Parent:FindFirstChild("HumanoidRootPart")
		if targetRoot and hrp then
			local direction = hrp.CFrame.LookVector.Unit

			-- Create BodyVelocity
			local bv = Instance.new("BodyVelocity")
			bv.Velocity = direction * KNOCKBACK
			bv.MaxForce = Vector3.new(1e6, 0, 1e6)
			bv.Parent = targetRoot

			-- Remove BodyVelocity after a short duration
			game:GetService("Debris"):AddItem(bv, 0.2)
			
			ClientReplicator:FireAllClients("Slash", targetRoot)
		end
	end

	-- Play hit sound once if we damaged someone
	if hitSomething and hitSound then
		hitSound:Play()
	end
end)