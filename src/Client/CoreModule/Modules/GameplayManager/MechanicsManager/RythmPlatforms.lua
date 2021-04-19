-- Variables
local gameplayMechanicManager = {}
gameplayMechanicManager.MechanicContainer = nil

local coreModule = require(script:FindFirstAncestor("CoreModule"))
local mechanicsManager = require(coreModule.GetObject("/Parent"))

-- Initialize
function gameplayMechanicManager.Initialize()
	gameplayMechanicManager.MechanicContainer = mechanicsManager.GetPlatformerMechanics():WaitForChild("RythmPlatforms")

	-- Setting up the RythmPlatforms to be functional.
	for _, rythmPlatformContainer in next, gameplayMechanicManager.MechanicContainer:GetChildren() do
		for _, rythmPlatform in next, rythmPlatformContainer:GetChildren() do

			-- We put each RythmPlatform into it's own coroutine so they all run separate from eachother.
			coroutine.wrap(function()
				local validBeatMap = gameplayMechanicManager.GenerateValidBeatmap(
					rythmPlatform:FindFirstChild("Beatmap") and require(rythmPlatform.Beatmap), 
					#rythmPlatform:GetChildren()
				)

				while true do
					gameplayMechanicManager.SimulateBeatMap(rythmPlatform, validBeatMap)
				end
			end)()
		end
	end
end


-- Methods
function gameplayMechanicManager.SimulateBeatMap(rythmPlatform, beatMap)
	if typeof(rythmPlatform) ~= "Instance" then return end
	if typeof(beatMap) ~= "table" or #beatMap == 0 then return end
	
	for beatMapIndex = 1, #beatMap do
		
		-- So the idea is that we do this first to set us up for success even though it is the second half of the effect.
		for _, basePart in next, rythmPlatform:GetDescendants() do
			if basePart:IsA("BasePart") and tonumber(basePart.Parent.Name) then
				basePart.CanCollide = tonumber(basePart.Parent.Name) == beatMapIndex
				basePart.Transparency = 
					-- Visible
					basePart.CanCollide and (rythmPlatform:GetAttribute("VisibleTransparency") or script:GetAttribute("DefaultVisibleTransparency") or 0) 
					-- Invisible
					or (rythmPlatform:GetAttribute("InvisibleTransparency") or script:GetAttribute("DefaultInvisibleTransparency") or 0.5)
			end
		end

		-- Wait before starting the animation; duration - numBlinks*blinkLength.
		wait((beatMap[beatMapIndex].Duration or 3) - (script:GetAttribute("NumberOfBlinks") or 3)*(script:GetAttribute("BlinkLength") or 0.45))

		-- Blinking animation.
		for blinkIndex = 1, (script:GetAttribute("NumberOfBlinks") or 3) do
			for _, basePart in next, rythmPlatform:GetDescendants() do
				if basePart:IsA("BasePart") and tonumber(basePart.Parent.Name) == beatMapIndex then
					coreModule.Services.TweenService:Create(
						basePart, 
						TweenInfo.new((script:GetAttribute("BlinkLength") or 0.45)/2, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, true), 
						{
							Transparency = script:GetAttribute("GoalTransparency") or 0.5, 
							Color = script:GetAttribute("GoalColor") or Color3.new(1, 1, 1)
						}
					):Play()
				end

				-- The blinking animation plays only for baseparts about to switch; This one plays for all of them that are valid.
				if basePart:IsA("BasePart") and tonumber(basePart.Parent.Name) then
					mechanicsManager.PlayAppearanceChangedEffect(basePart, 2)
				end
			end

			wait(script:GetAttribute("BlinkLength") or 0.45)
		end

		-- There's actually a final animation that happens before they switch.
		for _, basePart in next, rythmPlatform:GetDescendants() do
			if basePart:IsA("BasePart") and tonumber(basePart.Parent.Name) then
				mechanicsManager.PlayAppearanceChangedEffect(basePart, 2)
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