-- Variables
local gameplayMechanicManager = {}
gameplayMechanicManager.MechanicContainer = nil
gameplayMechanicManager.PlatformsBeingSimulated = {}

local coreModule = require(script:FindFirstAncestor("Core"))
local mechanicsManager = require(coreModule.GetObject("Modules.GameplayManager.MechanicsManager"))
local clientEssentialsLibrary = require(coreModule.GetObject("Libraries.ClientEssentials"))
local utilitiesLibrary = require(coreModule.Shared.GetObject("Libraries._Utilities"))

-- Initialize
function gameplayMechanicManager.Initialize()
	gameplayMechanicManager.MechanicContainer = mechanicsManager.GetPlatformerMechanics():WaitForChild("SpinningPlatforms")

	-- Setting up the platform to be functional.
	for _, platformContainer in next, gameplayMechanicManager.MechanicContainer:GetChildren() do
		for _, platformObject in next, platformContainer:GetChildren() do
			if platformObject:IsA("Model") and platformObject.PrimaryPart and platformObject:FindFirstChild("Stand") then
				gameplayMechanicManager.SimulatePlatform(platformObject)

			elseif platformObject:IsA("Model") then
				print(
					("SpinningPlatform: %s, has PrimaryPart: %s, has Stand: %s."):format(platformObject:GetFullName(), tostring(platformObject.PrimaryPart ~= nil), tostring(platformObject:FindFirstChild("Stand") ~= nil)),
					warn
				)
			end
		end
	end
end


-- Methods
function gameplayMechanicManager.SimulatePlatform(platformObject)
	if typeof(platformObject) ~= "Instance" or not platformObject:IsA("Model") then return end
	if not platformObject.PrimaryPart or not platformObject:FindFirstChild("Stand") then return end

	-- Setup.
	local offsetFromCenter = gameplayMechanicManager.GetOffsetFromCenter(platformObject)
	local weldOffsetValues = gameplayMechanicManager.GetWeldOffsetValues(platformObject)
	local fullSpinLength = platformObject:GetAttribute("Length") or script:GetAttribute("DefaultLength") or 3
	local storedRotationInDegrees = 0

	coroutine.wrap(function()
		gameplayMechanicManager.SetupTrippingFunctionality(platformObject)

		while true do
			if not utilitiesLibrary.IsPlayerValid() then return end
			local deltaTime = game:GetService("RunService").RenderStepped:Wait()

			-- This resets the position to the ideal center position.
			-- This is so that when we reapply the offset from the center it doesn't gradually fly off into the distance.
			platformObject.PrimaryPart.Position = (platformObject.Stand.CFrame*CFrame.new(0, platformObject.Stand.Size.Y/2 + platformObject.PrimaryPart.Size.Y/2, 0)).Position

			-- The final CFrame matrix of where the spinner will be and how it will be oriented.
			-- This supports all angles and all offsets.
			local goalFinalCFrameMatrix: CFrame = CFrame.fromMatrix(
				platformObject.PrimaryPart.Position,
				platformObject.Stand.CFrame.RightVector,
				platformObject.Stand.CFrame.UpVector
			) * CFrame.Angles(
				0,
				math.rad(storedRotationInDegrees) + math.rad(360 / fullSpinLength * deltaTime),
				0
			) * CFrame.new(
				offsetFromCenter
			)

			-- Update.
			platformObject.PrimaryPart.CFrame = goalFinalCFrameMatrix
			storedRotationInDegrees = math.deg(math.rad(storedRotationInDegrees) + math.rad(360/fullSpinLength*deltaTime))%360

			-- Moving the welded parts.
			if weldOffsetValues then
				for weldConstraint, objectSpaceCFrame in next, weldOffsetValues do
					weldConstraint.Part1.CFrame = platformObject:GetPrimaryPartCFrame():ToWorldSpace(objectSpaceCFrame)
				end
			end
		end
	end)()
end


function gameplayMechanicManager.IsPlatformBeingSimulated(platformObject)
	if not platformObject then return end
	return gameplayMechanicManager.PlatformsBeingSimulated[platformObject]
end


function gameplayMechanicManager.UpdatePlatformBeingSimulated(platformObject, newValue)
	if not platformObject then return end
	gameplayMechanicManager.PlatformsBeingSimulated[platformObject] = newValue
end


-- Private Methods
function gameplayMechanicManager.GetOffsetFromCenter(platformObject)
	if typeof(platformObject) ~= "Instance" or not platformObject:IsA("Model") then return end
	if not platformObject.PrimaryPart or not platformObject:FindFirstChild("Stand") then return end

	-- Calculate the offset from the idealCenterCFrame to the actual center cframe.
	local idealCenterCFrame = platformObject.Stand.CFrame*CFrame.new(0, platformObject.Stand.Size.Y/2 + platformObject.PrimaryPart.Size.Y/2, 0)
	local actualCenterCFrame = platformObject:GetPrimaryPartCFrame()
	local offsetFromCenterVector = actualCenterCFrame:ToObjectSpace(idealCenterCFrame).Position

	-- Return a rounded version of that offset to avoid annoying values.
	return Vector3.new(math.round(offsetFromCenterVector.X), math.round(offsetFromCenterVector.Y), math.round(offsetFromCenterVector.Z))
end


function gameplayMechanicManager.GetWeldOffsetValues(platformObject)
	if not platformObject or typeof(platformObject) ~= "Instance" then return end
	if not platformObject:IsA("Model") or not platformObject.PrimaryPart then return end

	-- Do an initial check before doing any needless computation.
	if platformObject.PrimaryPart:FindFirstChildOfClass("WeldConstraint") then
		local weldOffsetValues = {}

		-- We need to collect all of the WeldConstraints' information.
		for _, weldConstraint in next, platformObject.PrimaryPart:GetChildren() do
			if weldConstraint:IsA("WeldConstraint") and weldConstraint.Part1 then
				weldOffsetValues[weldConstraint] = platformObject:GetPrimaryPartCFrame():ToObjectSpace(weldConstraint.Part1.CFrame)
			end
		end

		return weldOffsetValues
	end
end


-- When you touch a spinning platform you should trip depending on the config.
function gameplayMechanicManager.SetupTrippingFunctionality(platformObject)
	if typeof(platformObject) ~= "Instance" or not platformObject:IsA("Model") or not platformObject.PrimaryPart then return end
	if not platformObject:GetAttribute("TripPlayers") then return end

	-- I have this separate so that when welded parts that are inside of the PrimaryPart also extend this functionality.
	local function onTouched(hit)
		local player = game:GetService("Players"):GetPlayerFromCharacter(hit.Parent)

		-- Guard clauses.
		if player ~= clientEssentialsLibrary.GetPlayer() or not utilitiesLibrary.IsPlayerAlive(player) then return end
		if gameplayMechanicManager.IsPlatformBeingSimulated(platformObject) then return end
		gameplayMechanicManager.UpdatePlatformBeingSimulated(platformObject, true)

		-- The tripping logic.
		local humanoidObject = player.Character.Humanoid
		humanoidObject:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
		humanoidObject.Sit = true

		wait(script:GetAttribute("TripLength") or 3)

		-- They might've died so we need to check just incase.
		if utilitiesLibrary.IsPlayerAlive(player) then
			humanoidObject.Sit = false
			humanoidObject:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
		end

		gameplayMechanicManager.UpdatePlatformBeingSimulated(platformObject, nil)
	end

	-- Connecting up the listeners.
	platformObject.PrimaryPart.Touched:Connect(onTouched)
	for _, basePart in next, platformObject.PrimaryPart:GetChildren() do
		if basePart:IsA("BasePart") then
			basePart.Touched:Connect(onTouched)
		end
	end
end

--
return gameplayMechanicManager