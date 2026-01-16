local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local remote = ReplicatedStorage.Remotes:WaitForChild("ShowHintEvent")
local popUpSound = workspace.GameSounds.PlayerSounds:FindFirstChild("PopUpSound")


local screenGui = Instance.new("ScreenGui")
screenGui.Name = "HintGui"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local textLabel = Instance.new("TextLabel")
textLabel.Name = "HintLabel"
textLabel.Parent = screenGui
textLabel.Text = "" 
textLabel.Font = Enum.Font.Antique
textLabel.TextSize = 30
textLabel.TextColor3 = Color3.new(1, 1, 1)
textLabel.TextStrokeTransparency = 0.5
textLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
textLabel.AnchorPoint = Vector2.new(0.5, 1)
textLabel.Position = UDim2.new(0.5, 0, 0.9, 0)
textLabel.Size = UDim2.new(0, 600, 0, 50) 
textLabel.BackgroundTransparency = 1
textLabel.TextTransparency = 1 
textLabel.TextStrokeTransparency = 1


local fadeTime = 0.5
local showTime = 3 

local tweenInfo = TweenInfo.new(fadeTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

local goalShow = {TextTransparency = 0, TextStrokeTransparency = 0.5}
local goalHide = {TextTransparency = 1, TextStrokeTransparency = 1}

local currentTween = nil 



remote.OnClientEvent:Connect(function(receivedText)
	
	if currentTween then
		currentTween:Cancel()
	end

	-- 2. Nastavíme nový text
	textLabel.Text = receivedText
	popUpSound:Play()

	-- 3. Okamžitě nastavíme label na "začátek" (neviditelný), pokud chceme efekt rozednění
	-- Nebo můžeme nechat plynulý přechod. Pro jistotu resetujeme na neviditelno a pak Fade In:
	textLabel.TextTransparency = 1
	textLabel.TextStrokeTransparency = 1

	-- 4. Fade In (Objevení)
	currentTween = TweenService:Create(textLabel, tweenInfo, goalShow)
	currentTween:Play()
	currentTween.Completed:Wait()

	-- 5. Čekání
	task.wait(showTime)

	-- 6. Fade Out (Zmizení)
	-- Zkontrolujeme, jestli se mezitím text nezměnil (hráč vběhl do jiného triggeru)
	if textLabel.Text == receivedText then
		currentTween = TweenService:Create(textLabel, tweenInfo, goalHide)
		currentTween:Play()
	end
end)