-- Variables
local playerMouseLibrary = {}
playerMouseLibrary.InputListeners = {}

local coreModule = require(script:FindFirstAncestor("Core"))

-- Initialize
function playerMouseLibrary.Initialize()
	local function processInput(inputObject, gameProcessedEvent)
		if gameProcessedEvent then return end

		-- Look for an input listener waiting for this input.
		for _, inputInformation in next, playerMouseLibrary.InputListeners do
			if typeof(inputInformation.UserInputType) == "table" then
				
				-- It's ambigious because I don't know if it's a KeyCode or a UserInputType.
				for _, ambigiousInputType in next, inputInformation.UserInputType do
					if (ambigiousInputType == inputObject.KeyCode or ambigiousInputType == inputObject.UserInputType) and (inputInformation.UserInputState or inputObject.UserInputState) == inputObject.UserInputState  then
						inputInformation._BindableEvent:Fire(inputObject.Position, inputObject.Delta)
					end
				end

			-- Straight forward no ambiguity.
			elseif (inputInformation.UserInputType or inputObject.UserInputType) == inputObject.UserInputType and (inputInformation.UserInputState or inputObject.UserInputState) == inputObject.UserInputState then
				inputInformation._BindableEvent:Fire(inputObject.Position, inputObject.Delta)
			end
		end
	end

	game:GetService("UserInputService").InputBegan:Connect(processInput)
	game:GetService("UserInputService").InputEnded:Connect(processInput)
	game:GetService("UserInputService").InputChanged:Connect(processInput)
end


-- Methods
function playerMouseLibrary.SetInputListener(userInputType, userInputState)

	-- Let's check if it exists before creating a new one.
	for _, inputInformation in next, playerMouseLibrary.InputListeners do
		if inputInformation.UserInputType == userInputType and inputInformation.UserInputState == userInputState then
			return inputInformation._BindableEvent
		end
	end

	-- Create a new one.
	local bindableEvent = Instance.new("BindableEvent")
	table.insert(playerMouseLibrary.InputListeners, {
		UserInputType = userInputType, 
		UserInputState = userInputState, 
		_BindableEvent = bindableEvent
	})

	return bindableEvent.Event
end


function playerMouseLibrary.Raycast(raycastParameters, maxDistance)
	local viewportMouseRay = playerMouseLibrary.GetCurrentRay()
	return workspace:Raycast(viewportMouseRay.Origin, viewportMouseRay.Direction*(maxDistance or script:GetAttribute("DEFAULT_MAX_RAY_DISTANCE") or 1000), raycastParameters)
end


function playerMouseLibrary.GetCurrentRay()
	local mousePosition = playerMouseLibrary.GetPosition()
	return workspace.CurrentCamera:ViewportPointToRay(mousePosition.X, mousePosition.Y)
end


function playerMouseLibrary.GetPosition()
	return game:GetService("UserInputService"):GetMouseLocation()
end


--
return playerMouseLibrary