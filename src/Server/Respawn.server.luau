local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")


local remote = ReplicatedStorage.Remotes:WaitForChild("RespawnEvent")

remote.OnServerEvent:Connect(function(player)
	print("Restartuji hru pro hráče: " .. player.Name)

	
	local success, err = pcall(function()
		TeleportService:Teleport(game.PlaceId, player)
	end)

	if not success then
		warn("Teleport selhal: " .. err)
		
		player:LoadCharacter()
	end

	
end)