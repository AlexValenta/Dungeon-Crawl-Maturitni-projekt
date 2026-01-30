--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local ClientReplicator = ReplicatedStorage.Remotes:WaitForChild("ClientReplicator")

ClientReplicator.OnClientEvent:Connect(function(args, target)
	if not args or not target then return end
	
	if args == "Slash" then
		--// VFX particles
		local vfx = script.HitVFX:Clone()
		vfx.Parent = target
		for _, v in pairs(vfx:GetChildren()) do
			if v:IsA("ParticleEmitter") then
				v:Emit(v:GetAttribute("EmitCount"))
			end
		end
		game.Debris:AddItem(vfx, 2)
		
		--// Flash red highlight
		local model = target.Parent
		if model and model:IsA("Model") then
			local highlight = Instance.new("Highlight")
			highlight.FillColor = Color3.fromRGB(255, 0, 0)
			highlight.FillTransparency = 0.5 -- start visible
			highlight.OutlineTransparency = 1
			highlight.Parent = model

			-- Tween FillTransparency to 1 (fully invisible)
			local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			local tween = TweenService:Create(highlight, tweenInfo, {FillTransparency = 1})
			tween:Play()

			-- Cleanup after tween finishes
			tween.Completed:Connect(function()
				highlight:Destroy()
			end)
		end
	end
end)