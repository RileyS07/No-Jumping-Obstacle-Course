-- Variables
local gameplayMechanicManager = {}
gameplayMechanicManager.Assets = {}
gameplayMechanicManager.MechanicContainer = nil
gameplayMechanicManager.ButtonsBeingSimulated = {}

local coreModule = require(script:FindFirstAncestor("CoreModule"))
local mechanicsManager = require(coreModule.GetObject("/Parent"))
local soundEffectsManager = require(coreModule.GetObject("Modules.GameplayManager.PlayerManager.SoundEffects"))
local clientEssentialsLibrary = require(coreModule.GetObject("Libraries.ClientEssentials"))
local utilitiesLibrary = require(coreModule.Shared.GetObject("Libraries.Utilities"))

-- Initialize
function gameplayMechanicManager.Initialize()
	gameplayMechanicManager.MechanicContainer = mechanicsManager.GetPlatformerMechanics():WaitForChild("Buttons")
	gameplayMechanicManager.Assets.TimerInterface = coreModule.Shared.GetObject("//Assets.Interfaces.TimerInterface")

	-- Setting up the Buttons to be functional.
	for _, buttonsContainer in next, gameplayMechanicManager.MechanicContainer:GetChildren() do
		for _, buttonObject in next, buttonsContainer:GetChildren() do

			-- The PrimaryPart is what the player will touch, and TransformationModel is what is transformed by the button press.
			if buttonObject:IsA("Model") and buttonObject.PrimaryPart and buttonObject:FindFirstChild("TransformationModel") then
				
				-- Setting up the button with the TimerInterface; I do this procedurally so that it's easy for us to make changes to it.
				if gameplayMechanicManager.Assets.TimerInterface then
					gameplayMechanicManager.Assets.TimerInterface:Clone().Parent = buttonObject.PrimaryPart
					buttonObject.PrimaryPart.TimerInterface.TimerState.Text = script:GetAttribute("InactiveStateText") or "Press me!"
				end

				-- Player touched the button.
				buttonObject.PrimaryPart.Touched:Connect(function(hit)
					local player = coreModule.Services.Players:GetPlayerFromCharacter(hit.Parent)

					-- Guard clause #1 is checking if the player is actually the LocalPlayer and that they're alive; #2 is checking to see if the button is already being simulated by the client.
					if player ~= clientEssentialsLibrary.GetPlayer() or not utilitiesLibrary.IsPlayerAlive(player) then return end
					if gameplayMechanicManager.IsButtonBeingSimulated(buttonObject) then return end

					gameplayMechanicManager.SimulateButtonPress(buttonObject)
				end)
			elseif buttonObject:IsA("Model") then
				coreModule.Debug(
					("Button: %s, has PrimaryPart: %s, has TransformationModel: %s."):format(buttonObject:GetFullName(), tostring(buttonObject.PrimaryPart ~= nil), tostring(buttonObject:FindFirstChild("TransformationModel") ~= nil)),
					coreModule.Shared.Enums.DebugLevel.Exception,
					warn
				)
			end
		end
	end
end


-- Methods
function gameplayMechanicManager.SimulateButtonPress(buttonObject, functionParameters)
	functionParameters = setmetatable(functionParameters or {}, {__index = {
		ShowTimerCountdown = true,
		ManualSimulationLength = 0
	}})	

	-- Guard clause #1-2 is checking if the buttonObject is in a valid format we can work with; #3 is checking to see if the button is already being simulated by the client.
	if not buttonObject or typeof(buttonObject) ~= "Instance" or not buttonObject:IsA("Model") then return end
	if not buttonObject.PrimaryPart or not buttonObject:FindFirstChild("TransformationModel") then return end
	if gameplayMechanicManager.IsButtonBeingSimulated(buttonObject) then return end
	gameplayMechanicManager.ButtonsBeingSimulated[buttonObject] = true
	
	-- Defining the simulationLength from most unique to least unique
	local simulationLength = math.floor(
		(functionParameters.ManualSimulationLength > 0 and functionParameters.ManualSimulationLength) 
		or buttonObject:GetAttribute("TransformationLength")
		or script:GetAttribute("DefaultTransformationLength")
		or 10
	)
	
	-- Button visuals; Colors changing + movement.
	coroutine.wrap(function()
		local buttonMovementTweenInfo = TweenInfo.new(math.min(1, simulationLength/2), Enum.EasingStyle.Linear)

		-- Downwards animation
		buttonObject.PrimaryPart.Color = script:GetAttribute("ActiveStateColor") or Color3.fromRGB(255, 0, 0)
		soundEffectsManager.PlaySoundEffect("ButtonActivated", {Parent = buttonObject.PrimaryPart})
		coreModule.Services.TweenService:Create(
			buttonObject.PrimaryPart, buttonMovementTweenInfo, {
				CFrame = buttonObject:GetPrimaryPartCFrame()*CFrame.new(-(script:GetAttribute("ActiveStateOffset") or Vector3.new(0, 0.3, 0)))
			}
		):Play()
		
		wait(simulationLength - math.min(1, simulationLength/2))
		
		-- Upwards animation
		local upwardsTweenObject = coreModule.Services.TweenService:Create(
			buttonObject.PrimaryPart, buttonMovementTweenInfo, {
				CFrame = buttonObject:GetPrimaryPartCFrame()*CFrame.new(script:GetAttribute("ActiveStateOffset") or Vector3.new(0, 0.3, 0))
			}
		)

		upwardsTweenObject:Play()
		upwardsTweenObject.Completed:Wait()
		buttonObject.PrimaryPart.Color = script:GetAttribute("InactiveStateColor") or Color3.fromRGB(104, 212, 113)
	end)()

	-- Button timer; 30 -> 29 -> 28 -> ...
	coroutine.wrap(function()
		local buttonTimerInterface = buttonObject.PrimaryPart:FindFirstChild("TimerInterface")

		-- Guard clause #1 is checking to see if the countdown was manually overridden; #2 is checking if the button is in a valid format we can work with.
		if not functionParameters.ShowTimerCountdown then return end
		if not buttonTimerInterface or not buttonTimerInterface:FindFirstChild("TimerState") then return end
		
		-- 30 -> 29 -> 28 -> ...
		for index = simulationLength, 1, -1 do
			buttonTimerInterface.TimerState.Text = index
			wait(1)
		end

		buttonTimerInterface.TimerState.Text = script:GetAttribute("InactiveStateText") or "Press me!"
	end)()
	
	-- This is where the transformation happens; CanCollide is inversed and the transparency is changed based on the attributes/defaults.
	coroutine.wrap(function()

		-- The magic function where the above takes place.
		local function transformButtonTransformationModel()
			for _, basePart in next, buttonObject.TransformationModel:GetDescendants() do
				if basePart:IsA("BasePart") then
					basePart.CanCollide = not basePart.CanCollide
					basePart.Transparency = 
						-- Visible
						basePart.CanCollide and (buttonObject:GetAttribute("VisibleTransparency") or script:GetAttribute("DefaultVisibleTransparency") or 0) 
						-- Invisible
						or (buttonObject:GetAttribute("InvisibleTransparency") or script:GetAttribute("DefaultInvisibleTransparency") or 0.5)
					
					mechanicsManager.PlayAppearanceChangedEffect(basePart)
				end
			end
		end

		transformButtonTransformationModel()
		wait(simulationLength)
		transformButtonTransformationModel()

		-- Cleanup; There may be several reasons why the button might not sync perfectly well but this small yield helps avoid that without going for a much more complex solution.
		wait(0.5)
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