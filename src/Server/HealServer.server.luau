local ReplicatedStorage = game:GetService("ReplicatedStorage")


local HealEvent = ReplicatedStorage.Remotes:WaitForChild("HealEvent")

HealEvent.OnServerEvent:Connect(function(player, amount)

	if player.Character then
		local humanoid = player.Character:FindFirstChild("Humanoid")
		if humanoid then
		
			humanoid.Health = math.clamp(humanoid.Health + amount, 0, humanoid.MaxHealth)
			print(player.Name .. " byl vyléčen o " .. amount .. " HP.")
		end
	end
end)