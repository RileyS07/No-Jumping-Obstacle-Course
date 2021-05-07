-- Variables
local gameplayMechanicManager = {}
gameplayMechanicManager.MechanicContainer = nil

local coreModule = require(script:FindFirstAncestor("CoreModule"))
local mechanicsManager = require(coreModule.GetObject("/Parent"))
local clientEssentialsLibrary = require(coreModule.GetObject("Libraries.ClientEssentials"))
local clientAnimationsLibrary = require(coreModule.GetObject("Libraries.ClientAnimations"))
local utilitiesLibrary = require(coreModule.Shared.GetObject("Libraries.Utilities"))

-- Initialize
function gameplayMechanicManager.Initialize()
	gameplayMechanicManager.MechanicContainer = mechanicsManager.GetPlatformerMechanics():WaitForChild("RythmPlatforms")

	-- Setting up the platform to be functional.
	for _, platformContainer in next, gameplayMechanicManager.MechanicContainer:GetChildren() do
		for _, platformObject in next, platformContainer:GetChildren() do
			if platformObject:IsA("Model") then

				coroutine.wrap(function()
					local validBeatMap = gameplayMechanicManager.GenerateValidBeatmap(
						platformObject:FindFirstChild("Beatmap") and require(platformObject.Beatmap), 
						#platformObject:GetChildren()
					)

					while true do
						if utilitiesLibrary.IsPlayerAlive() and clientEssentialsLibrary.GetPlayer():DistanceFromCharacter(platformObject:GetBoundingBox().Position) <= 100 then
							gameplayMechanicManager.SimulatePlatform(platformObject, validBeatMap)
						end

						coreModule.Services.RunService.RenderStepped:Wait()
					end
				end)()
			end
		end
	end
end


-- Methods
function gameplayMechanicManager.SimulatePlatform(platformObject, validBeatMap)
	if typeof(platformObject) ~= "Instance" then return end
	if typeof(validBeatMap) ~= "table" or #validBeatMap == 0 then return end
	
	-- Setup.
	local blinkLength = script:GetAttribute("BlinkLength") or 0.45
	local numberOfBlinks = script:GetAttribute("NumberOfBlinks") or 3

	-- Goes through the beat map.
	for beatMapIndex = 1, #validBeatMap do
		
		-- So the idea is that we do this first to set us up for success even though it is the second half of the effect.
		for _, basePart in next, platformObject:GetDescendants() do
			if basePart:IsA("BasePart") and tonumber(basePart.Parent.Name) then
				clientAnimationsLibrary.PlayAnimation("SwitchTransformation", basePart, tonumber(basePart.Parent.Name) == beatMapIndex, true)
			end
		end

		-- Wait before starting the animation; duration - numBlinks*blinkLength.
		wait((validBeatMap[beatMapIndex].Duration or 3) - numberOfBlinks*blinkLength)

		-- Blinking animation.
		clientAnimationsLibrary.PlayAnimation("RythmBlinking", platformObject, beatMapIndex, numberOfBlinks, blinkLength)
		
		-- There's actually a final animation that happens before they switch.
		for _, basePart in next, platformObject:GetDescendants() do
			if basePart:IsA("BasePart") and tonumber(basePart.Parent.Name) then
				clientAnimationsLibrary.PlayAnimation("GeneralAppearanceChanged", basePart, 2)
			end
		end
	end
end


-- Outputs a valid beat map the simulator function can use.
function gameplayMechanicManager.GenerateValidBeatmap(possibleBeatMap, minimumNumberOfSequencesNeeded)
	minimumNumberOfSequencesNeeded = typeof(minimumNumberOfSequencesNeeded) == "number" and minimumNumberOfSequencesNeeded or 2
	local validBeatMap = {}

	-- Is the possibleBeatMap valid? If so let's try to salvage it.
	if typeof(possibleBeatMap) == "table" and #possibleBeatMap > 0 then
		for index = 1, #possibleBeatMap do
			if possibleBeatMap[index].Duration and tonumber(possibleBeatMap[index].Duration) then
				table.insert(validBeatMap, {Duration = tonumber(possibleBeatMap[index].Duration)})
			end
		end
	end

	-- Fill in the gaps?
	if #validBeatMap < minimumNumberOfSequencesNeeded then
		while #validBeatMap < minimumNumberOfSequencesNeeded do
			table.insert(validBeatMap, {Duration = 3})
		end
	end

	return validBeatMap
end


--
return gameplayMechanicManager