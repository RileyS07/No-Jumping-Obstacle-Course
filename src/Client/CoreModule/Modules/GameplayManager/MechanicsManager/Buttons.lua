-- Variables
local gameplayMechanicManager = {}
gameplayMechanicManager.ButtonsBeingSimulated = {}

local coreModule = require(script:FindFirstAncestor("CoreModule"))
local soundEffectsManager = require(coreModule.GetObject("Modules.GameplayManager.PlayerManager.SoundEffects"))
local clientEssentialsLibrary = require(coreModule.GetObject("Libraries.ClientEssentials"))
local utilitiesLibrary = require(coreModule.Shared.GetObject("Libraries.Utilities"))

-- Initialize
function gameplayMechanicManager.Initialize()
	workspace.Map.Gameplay.PlatformerMechanics:WaitForChild("Buttons")
	
	-- Setup
	for _, buttonsContainer in next, workspace.Map.Gameplay.PlatformerMechanics.Buttons:GetChildren() do
		for _, buttonObject in next, buttonsContainer:GetChildren() do
			if buttonObject.PrimaryPart and buttonObject:FindFirstChild("TransformationModel") then
				coreModule.Shared.GetObject("//Assets.Interfaces.TimerInterface"):Clone().Parent = buttonObject.PrimaryPart
				buttonObject.PrimaryPart.TimerInterface.TimerState.Text = (script:GetAttribute("InactiveStateText") or "UwU")
				
				-- When they touch the button we simulate a button press (even though they're actually doing it...)
				buttonObject.PrimaryPart.Touched:Connect(function(hit)
					local player = coreModule.Services.Players:GetPlayerFromCharacter(hit.Parent)
					if not utilitiesLibrary.IsPlayerAlive(player) then return end
					if player ~= clientEssentialsLibrary.GetPlayer() then return end
					if gameplayMechanicManager.ButtonsBeingSimulated[buttonObject] then return end
					
					-- Simulate it
					gameplayMechanicManager.SimulateButtonPress(buttonObject)
				end)
			end
		end
	end
end

-- Methods
function gameplayMechanicManager.SimulateButtonPress(buttonObject, functionParameters)
	if not buttonObject then return end
	if not buttonObject.PrimaryPart then return end
	if not buttonObject:FindFirstChild("TransformationModel") then return end
	if gameplayMechanicManager.ButtonsBeingSimulated[buttonObject] then return end
	gameplayMechanicManager.ButtonsBeingSimulated[buttonObject] = true
	functionParameters = setmetatable(functionParameters or {}, {__index = {
		ShowTimerCountdown = true,
		ManualSimulationLength = 0
	}})	
	
	-- This is Important!
	local simulationLength = math.floor(
		(functionParameters.ManualSimulationLength > 0 and functionParameters.ManualSimulationLength)
			or buttonObject:GetAttribute("TransformationLength") 
			or script:GetAttribute("DefaultTransformationLength")
	)
	
	-- Button Movement and Colors
	coroutine.wrap(function()
		-- Button going down
		buttonObject.PrimaryPart.Color = script:GetAttribute("ActiveStateColor")
		coreModule.Services.TweenService:Create(
			buttonObject.PrimaryPart, 
			TweenInfo.new(math.min(1, simulationLength/2), Enum.EasingStyle.Linear), 
			{CFrame = buttonObject:GetPrimaryPartCFrame()*CFrame.new(-script:GetAttribute("ActiveStateOffset"))}
		):Play()
		
		soundEffectsManager.PlaySoundEffect("ButtonActivated", {Parent = buttonObject.PrimaryPart})
		wait(simulationLength - math.min(1, simulationLength/2))
		
		-- Button going up
		coreModule.Services.TweenService:Create(
			buttonObject.PrimaryPart, 
			TweenInfo.new(math.min(1, simulationLength/2), Enum.EasingStyle.Linear), 
			{CFrame = buttonObject:GetPrimaryPartCFrame()*CFrame.new(script:GetAttribute("ActiveStateOffset"))}
		):Play()
		buttonObject.PrimaryPart.Color = script:GetAttribute("InactiveStateColor")
	end)()

	-- Counter; 30 -> 29 -> 28 -> ...
	coroutine.wrap(function()
		if not functionParameters.ShowTimerCountdown then return end
		if not buttonObject.PrimaryPart:FindFirstChild("TimerInterface") then return end
		if not buttonObject.PrimaryPart.TimerInterface:FindFirstChild("TimerState") then return end
		for index = simulationLength, 1, -1 do
			buttonObject.PrimaryPart.TimerInterface.TimerState.Text = index
			wait(1)
		end

		buttonObject.PrimaryPart.TimerInterface.TimerState.Text = script:GetAttribute("InactiveStateText")
	end)()
	
	-- Transformation time BABEY
	coroutine.wrap(function()
		local function transformButtonTransformationModel()
			for _, basePart in next, buttonObject.TransformationModel:GetDescendants() do
				if basePart:IsA("BasePart") then
					basePart.CanCollide = not basePart.CanCollide
					basePart.Transparency = basePart.CanCollide and (buttonObject:GetAttribute("VisibleTransparency") or script:GetAttribute("DefaultVisibleTransparency")) or (buttonObject:GetAttribute("InvisibleTransparency") or script:GetAttribute("DefaultInvisibleTransparency"))
					
					-- Poof! Smoke animation when they change + sound effect
					local smokeParticleEmitter = coreModule.Shared.GetObject("//Assets.Objects.ParticleEmitters.Smoke"):Clone()
					smokeParticleEmitter.Parent = basePart
					smokeParticleEmitter:Emit(script:GetAttribute("SmokeParticleEmittance"))
					coreModule.Services.Debris:AddItem(smokeParticleEmitter, smokeParticleEmitter.Lifetime.Max)
					soundEffectsManager.PlaySoundEffect("Poof", {Parent = basePart})
				end
			end
		end

		transformButtonTransformationModel()
		wait(simulationLength)
		transformButtonTransformationModel()

		-- Cleanup
		wait(script:GetAttribute("MarginOfErrorYieldValue"))
		gameplayMechanicManager.ButtonsBeingSimulated[buttonObject] = nil
	end)()
	
	-- Returns true so we know that the simulation was ran
	return true
end

function gameplayMechanicManager.IsButtonBeingSimulated(buttonObject)
	if not buttonObject then return end
	return gameplayMechanicManager.ButtonsBeingSimulated[buttonObject]
end

--
return gameplayMechanicManager