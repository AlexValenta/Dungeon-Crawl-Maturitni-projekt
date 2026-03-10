local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local tagName = "Highlight"
local maxDistance = 10 -- Vzdálenost ve studech

-- Funkce pro získání pozice itemu (funguje pro Part i Model)
local function getItemPosition(item)
	if item:IsA("BasePart") then
		return item.Position
	elseif item:IsA("Model") then
		-- Pokud je to Model, zkusíme najít PrimaryPart, jinak použijeme Pivot
		if item.PrimaryPart then
			return item.PrimaryPart.Position
		else
			return item:GetPivot().Position
		end
	end
	return nil
end

-- Hlavní smyčka, která běží každý snímek
RunService.Heartbeat:Connect(function()
	local character = player.Character
	if not character then return end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	-- Získáme všechny objekty s tagem "Highlightable"
	local items = CollectionService:GetTagged(tagName)

	for _, item in ipairs(items) do
		local itemPos = getItemPosition(item)

		if itemPos then
			local distance = (rootPart.Position - itemPos).Magnitude

			-- Hledáme Highlight uvnitř itemu
			local highlight = item:FindFirstChildWhichIsA("Highlight")

			-- Pokud Highlight neexistuje, můžeme ho volitelně vytvořit (pojistka)
			if not highlight then
				highlight = Instance.new("Highlight")
				highlight.Name = "InteractionHighlight"
				highlight.FillTransparency = 1 -- Průhledný vnitřek
				highlight.OutlineColor = Color3.new(1, 1, 1) -- Bílá obrysová barva
				highlight.Parent = item
			end

			-- Logika zapnutí/vypnutí
			if distance <= maxDistance then
				highlight.Enabled = true
			else
				highlight.Enabled = false
			end
		end
	end
end)
