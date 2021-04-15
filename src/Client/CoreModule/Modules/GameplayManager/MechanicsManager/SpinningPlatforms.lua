-- Variables
local gameplayMechanicManager = {}
gameplayMechanicManager.MechanicContainer = nil
gameplayMechanicManager.SpinningPlatformsActive = {}

local coreModule = require(script:FindFirstAncestor("CoreModule"))
local mechanicsManager = require(coreModule.GetObject("/Parent"))
local clientEssentialsLibrary = require(coreModule.GetObject("Libraries.ClientEssentials"))
local utilitiesLibrary = require(coreModule.Shared.GetObject("Libraries.Utilities"))

-- Initialize
function gameplayMechanicManager.Initialize()
	gameplayMechanicManager.MechanicContainer = mechanicsManager.GetPlatformerMechanics():WaitForChild("SpinningPlatforms")

	-- Setting up the SpinningPlatforms to be functional.
	for _, spinningPlatformContainer in next, gameplayMechanicManager.MechanicContainer:GetChildren() do
		for _, spinningPlatform in next, spinningPlatformContainer:GetChildren() do

			-- The PrimaryPart is the spinner that hits players, the Stand is required so we have a base to do math off of.
			if spinningPlatform:IsA("Model") and spinningPlatform.PrimaryPart and spinningPlatform:FindFirstChild("Stand") then

				-- We put each SpinningPlatform into it's own coroutine so they all run separate from eachother.
				coroutine.wrap(function()
					local offsetFromCenter = gameplayMechanicManager.GetOffsetFromCenter(spinningPlatform)
					local weldOffsetValues = gameplayMechanicManager.GetWeldOffsetValues(spinningPlatform)
					gameplayMechanicManager.SetupTrippingFunctionality(spinningPlatform)

					-- The actual spinning math.
					while true do
						local deltaTime = coreModule.Services.RunService.Heartbeat:Wait()

						-- This resets the position to the ideal center position; This is so that when we reapply the offset from the center it doesn't gradually fly off into the distance.
						spinningPlatform.PrimaryPart.Position = (spinningPlatform.Stand.CFrame*CFrame.new(0, spinningPlatform.Stand.Size.Y/2 + spinningPlatform.PrimaryPart.Size.Y/2, 0)).Position
						-- This rotates a little based on the desired length and frame time and then applies the offset from the center.
						local goalUnphasedPrimaryPartCFrame = spinningPlatform.PrimaryPart.CFrame*CFrame.Angles(0, math.rad(360/(spinningPlatform:GetAttribute("Length") or 3)*deltaTime), 0)*CFrame.new(offsetFromCenter)
						local goalFinalCFrameMatrix = CFrame.fromMatrix(
							goalUnphasedPrimaryPartCFrame.Position, 
							goalUnphasedPrimaryPartCFrame.RightVector, 
							spinningPlatform.Stand.CFrame.UpVector
						)

						spinningPlatform.PrimaryPart.CFrame = goalFinalCFrameMatrix

						-- Temporary Debugging
						if spinningPlatform.Name == "Special" then
							print("FinalUp = ", goalFinalCFrameMatrix.UpVector, "GoalUp = ", spinningPlatform.Stand.CFrame.UpVector, "ActualUp = ", spinningPlatform.PrimaryPart.CFrame.UpVector, "UnphasedUp = ", goalUnphasedPrimaryPartCFrame.UpVector)
						end

						-- Moving the welded parts.
						if weldOffsetValues then
							for weldConstraint, objectSpaceCFrame in next, weldOffsetValues do
								weldConstraint.Part1.CFrame = spinningPlatform:GetPrimaryPartCFrame():ToWorldSpace(objectSpaceCFrame)
							end
						end
					end
				end)()
			elseif spinningPlatform:IsA("Model") then
				coreModule.Debug(
					("SpinningPlatform: %s, has PrimaryPart: %s, has Stand: %s."):format(spinningPlatform:GetFullName(), tostring(spinningPlatform.PrimaryPart ~= nil), tostring(spinningPlatform:FindFirstChild("Stand") ~= nil)), 
					coreModule.Shared.Enums.DebugLevel.Exception, 
					warn
				)
			end
		end
	end
end


-- Private Methods
-- This is so we can support lopsided beams but has other benefits.
function gameplayMechanicManager.GetOffsetFromCenter(spinningPlatform)
	if not spinningPlatform or typeof(spinningPlatform) ~= "Instance" then return end
	if not spinningPlatform:IsA("Model") or not spinningPlatform.PrimaryPart or not spinningPlatform:FindFirstChild("Stand") then return end

	-- Calculate the offset from the idealCenterCFrame to the actual center cframe.
	local idealCenterCFrame = spinningPlatform.Stand.CFrame*CFrame.new(0, spinningPlatform.Stand.Size.Y/2 + spinningPlatform.PrimaryPart.Size.Y/2, 0)
	local actualCenterCFrame = spinningPlatform:GetPrimaryPartCFrame()
	local offsetFromCenterVector = actualCenterCFrame:ToObjectSpace(idealCenterCFrame).Position

	-- Return a rounded version of that offset to avoid annoying values.
	return Vector3.new(math.round(offsetFromCenterVector.X), math.round(offsetFromCenterVector.Y), math.round(offsetFromCenterVector.Z))
end


-- This method exists so we can support things being welded to the platforms moving with them.
function gameplayMechanicManager.GetWeldOffsetValues(spinningPlatform)
	if not spinningPlatform or typeof(spinningPlatform) ~= "Instance" then return end
	if not spinningPlatform:IsA("Model") or not spinningPlatform.PrimaryPart then return end

	-- Do an initial check before doing any needless computation.
	if spinningPlatform.PrimaryPart:FindFirstChildOfClass("WeldConstraint") then
		local weldOffsetValues = {}

		-- We need to collect all of the WeldConstraints' information.
		for _, weldConstraint in next, spinningPlatform.PrimaryPart:GetChildren() do
			if weldConstraint:IsA("WeldConstraint") and weldConstraint.Part1 then
				weldOffsetValues[weldConstraint] = spinningPlatform:GetPrimaryPartCFrame():ToObjectSpace(weldConstraint.Part1.CFrame)
			end
		end

		return weldOffsetValues
	end
end


-- When you touch a spinning platform you should trip depending on the config.
function gameplayMechanicManager.SetupTrippingFunctionality(spinningPlatform)
	if not spinningPlatform or typeof(spinningPlatform) ~= "Instance" then return end
	if not spinningPlatform:IsA("Model") or not spinningPlatform.PrimaryPart then return end
	if not spinningPlatform:GetAttribute("TripPlayers") then return end

	-- I have this separate so that when welded parts that are inside of the PrimaryPart also extend this functionality.
	local function onTouched(hit)
		local player = coreModule.Services.Players:GetPlayerFromCharacter(hit.Parent)

		-- Guard clause #1 is checking if the player is actually the LocalPlayer and that they're alive; #2 is checking to see if the spinning platform has already tripped the client.
		if player ~= clientEssentialsLibrary.GetPlayer() or not utilitiesLibrary.IsPlayerAlive(player) then return end
		if gameplayMechanicManager.SpinningPlatformsActive[spinningPlatform] then return end
		gameplayMechanicManager.SpinningPlatformsActive[spinningPlatform] = true

		-- The tripping logic.
		local humanoidObject = player.Character.Humanoid
		humanoidObject:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
		humanoidObject.Sit = true

		wait(spinningPlatform:GetAttribute("TripLength") or 3)

		-- They might've died so we need to check just incase.
		if utilitiesLibrary.IsPlayerAlive(player) then
			humanoidObject.Sit = false
			humanoidObject:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
		end

		gameplayMechanicManager.SpinningPlatformsActive[spinningPlatform] = nil
	end

	-- Connecting up the listeners.
	spinningPlatform.PrimaryPart.Touched:Connect(onTouched)
	for _, basePart in next, spinningPlatform.PrimaryPart:GetChildren() do
		if basePart:IsA("BasePart") then
			basePart.Touched:Connect(onTouched)
		end
	end
end	

--
return gameplayMechanicManager