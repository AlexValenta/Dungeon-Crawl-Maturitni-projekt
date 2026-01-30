local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ShowDialogue")
local triggersFolder = workspace:WaitForChild("DialogueParts")


local completedDialogues = {}


Players.PlayerRemoving:Connect(function(player)
	completedDialogues[player.UserId] = nil
end)

for _, part in ipairs(triggersFolder:GetChildren()) do
	if part:IsA("BasePart") then
		part.Touched:Connect(function(hit)
			local player = Players:GetPlayerFromCharacter(hit.Parent)

			if player then
				local dialogueID = part:GetAttribute("DialogueID")

				if dialogueID then
					
					if not completedDialogues[player.UserId] then
						completedDialogues[player.UserId] = {}
					end

					
					if completedDialogues[player.UserId][dialogueID] == true then
						return 
					end

					
					completedDialogues[player.UserId][dialogueID] = true

					
					remote:FireClient(player, dialogueID)

					
				else
					warn("Part " .. part.Name .. " nemá nastavený Attribute 'DialogueID'!")
				end
			end
		end)
	end
end