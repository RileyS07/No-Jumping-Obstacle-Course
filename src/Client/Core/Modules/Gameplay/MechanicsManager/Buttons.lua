-- Variables
local gameplayMechanicManager = {}
gameplayMechanicManager.Assets = {}
gameplayMechanicManager.MechanicContainer = nil
gameplayMechanicManager.PlatformsBeingSimulated = {}

local coreModule = require(script:FindFirstAncestor("Core"))
local mechanicsManager = require(coreModule.GetObject("Modules.Gameplay.MechanicsManager"))
local clientEssentialsLibrary = require(coreModule.GetObject("Libraries.ClientEssentials"))
local clientAnimationsLibrary = require(coreModule.GetObject("Libraries.ClientAnimations"))
local utilitiesLibrary = require(coreModule.Shared.GetObject("Libraries._Utilities"))

-- Initialize
function gameplayMechanicManager.Initialize()
	gameplayMechanicManager.MechanicContainer = mechanicsManager.GetPlatformerMechanics():WaitForChild("Buttons")
	gameplayMechanicManager.Assets.TimerInterface = coreModule.Shared.GetObject("//Assets.Interfaces.TimerInterface")

	-- Setting up the Platform to be functional.
	for _, platformContainer in next, gameplayMechanicManager.MechanicContainer:GetChildren() do
		for _, platformObject in next, platformContainer:GetChildren() do
			if platformObject:IsA("Model") and platformObject.PrimaryPart and platformObject:FindFirstChild("TransformationModel") then
				
				-- Setting up the platform with the TimerInterface; I do this procedurally so that it's easy for us to make changes to it.
				if gameplayMechanicManager.Assets.TimerInterface then
					gameplayMechanicManager.Assets.TimerInterface:Clone().Parent = platformObject.PrimaryPart
					platformObject.PrimaryPart.TimerInterface.TimerState.Text = script:GetAttribute("InactiveStateText") or "Press me!"
				end

				-- Player touched the platform.
				platformObject.PrimaryPart.Touched:Connect(function(hit)
					local player = game:GetService("Players"):GetPlayerFromCharacter(hit.Parent)

					if player ~= clientEssentialsLibrary.GetPlayer() or not utilitiesLibrary.IsPlayerAlive() then return end
					if gameplayMechanicManager.IsPlatformBeingSimulated(platformObject) then return end

					gameplayMechanicManager.SimulatePlatform(platformObject)
				end)
			elseif platformObject:IsA("Model") then
				print(
					("Button: %s, has PrimaryPart: %s, has TransformationModel: %s."):format(platformObject:GetFullName(), tostring(platformObject.PrimaryPart ~= nil), tostring(platformObject:FindFirstChild("TransformationModel") ~= nil)),
					warn
				)
			end
		end
	end
end


-- Methods
function gameplayMechanicManager.SimulatePlatform(platformObject, functionParameters)
	functionParameters = setmetatable(functionParameters or {}, {__index = {
		ShowTimerCountdown = true,
		ManualSimulationLength = 0
	}})	

	-- Guard clauses.
	if typeof(platformObject) ~= "Instance" or not platformObject:IsA("Model") then return end
	if gameplayMechanicManager.IsPlatformBeingSimulated(platformObject) then return end
	gameplayMechanicManager.UpdatePlatformBeingSimulated(platformObject, true)
	
	-- Defining the simulationLength from most unique to least unique.
	local simulationLength = math.floor(
		(functionParameters.ManualSimulationLength > 0 and functionParameters.ManualSimulationLength) 
		or platformObject:GetAttribute("TransformationLength")
		or script:GetAttribute("DefaultTransformationLength")
		or 10
	)
	
	-- Setting up all of the animations behind the platforms.
	coroutine.wrap(clientAnimationsLibrary.PlayAnimation)("ButtonMovement", platformObject, simulationLength)
	coroutine.wrap(clientAnimationsLibrary.PlayAnimation)("ButtonTimer", platformObject, simulationLength, functionParameters.ShowTimerCountdown)
	coroutine.wrap(function()
		clientAnimationsLibrary.PlayAnimation("ButtonTransformation", platformObject, simulationLength)
		wait(0.5)
		
		gameplayMechanicManager.UpdatePlatformBeingSimulated(platformObject, nil)
	end)()
	
	-- Returns true so we know that the simulation was ran
	return true
end


function gameplayMechanicManager.IsPlatformBeingSimulated(platformObject)
	if not platformObject then return end
	return gameplayMechanicManager.PlatformsBeingSimulated[platformObject]
end


function gameplayMechanicManager.UpdatePlatformBeingSimulated(platformObject, newValue)
	if not platformObject then return end
	gameplayMechanicManager.PlatformsBeingSimulated[platformObject] = newValue
end


--
return gameplayMechanicManager