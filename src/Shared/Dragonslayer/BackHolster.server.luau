local Tool = script.Parent
local Handle = Tool:WaitForChild("Handle")


local holsterOffset = CFrame.new(0, 0, 0.5) * CFrame.Angles(math.rad(180), 0, math.rad(45))

-- 🧩 Najde UpperTorso nebo Torso
local function getTorso(character)
	return character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
end

local cachedCharacter = nil

-- 🟦 Animace (nahraď ID svými vlastními, pokud máš jiné)
local Animations = {
	Idle = 102527123263771,
	Sheathe = 101740792444351,
	Unsheathe = 77408311768736
}

-- 🟧 Zvuky
local unsheatheSound = workspace.GameSounds.WeaponSounds:FindFirstChild("Equip")
local sheatheSound = workspace.GameSounds.WeaponSounds:FindFirstChild("Unequip")

local tracks = {}

-- 🔁 Načte animace pro humanoida
local function loadAnimations(character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	for name, id in pairs(Animations) do
		local anim = Instance.new("Animation")
		anim.AnimationId = "rbxassetid://" .. id
		local track = humanoid:LoadAnimation(anim)
		track.Priority = Enum.AnimationPriority.Action
		track.Looped = (name == "Idle")
		tracks[name] = track
	end
end


local function createHolster(character)
	if not character or not character:IsDescendantOf(workspace) then return end
	if character:FindFirstChild(Tool.Name .. "_Holster") then return end

	local torso = getTorso(character)
	if not torso then return end

	local holsterModel = Handle:Clone()
	holsterModel.Name = Tool.Name .. "_Holster"
	holsterModel.CanCollide = false
	holsterModel.Massless = true
	holsterModel.Parent = character

	local weld = Instance.new("Motor6D")
	weld.Name = "BackWeld"
	weld.Part0 = torso
	weld.Part1 = holsterModel
	weld.C0 = holsterOffset
	weld.Parent = holsterModel
end


local function removeHolster(character)
	local holster = character:FindFirstChild(Tool.Name .. "_Holster")
	if holster then holster:Destroy() end
end

-- 🟦 Spustí animaci, pokud existuje
local function playAnim(name)
	local track = tracks[name]
	if not track then return end
	for _, t in pairs(tracks) do
		if t.IsPlaying and t ~= track then
			t:Stop()
		end
	end
	track:Play()
end

-- ⚔️ Při equipnutí zbraně
Tool.Equipped:Connect(function()
	local character = Tool.Parent
	cachedCharacter = character

	-- Načti animace
	loadAnimations(character)

	-- Přehrát unsheathe animaci + zvuk
	if unsheatheSound then unsheatheSound:Play() end
	playAnim("Unsheathe")

	-- Po skončení unsheathe přepne na idle
	local t = tracks["Unsheathe"]
	if t then
		t.Stopped:Connect(function()
			if Tool.Parent == character then
				playAnim("Idle")
			end
		end)
	end

	-- Odstranit holster z modelu, pokud existuje
	removeHolster(character)
end)

-- 🗡️ Při unequipnutí zbraně
Tool.Unequipped:Connect(function()
	local character = cachedCharacter
	if not character or not character:IsDescendantOf(workspace) then return end

	-- Přehrát sheathe animaci + zvuk
	playAnim("Sheathe")
	if sheatheSound then sheatheSound:Play() end

	local t = tracks["Sheathe"]
	if t then
		t.Stopped:Connect(function()
			if Tool.Parent ~= character then
				createHolster(character)
			end
		end)
	else
		task.wait()
		createHolster(character)
	end
end)

-- 🧹 Když Tool zmizí (např. smazán nebo zničen), odstraní i holster
Tool.AncestryChanged:Connect(function(_, parent)
	if not parent then
		local character = cachedCharacter
		if character and character:IsDescendantOf(workspace) then
			removeHolster(character)
		end
	end
end)
