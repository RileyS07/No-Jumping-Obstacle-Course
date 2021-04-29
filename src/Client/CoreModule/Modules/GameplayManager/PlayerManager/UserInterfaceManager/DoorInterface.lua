-- Variables
local specificInterfaceManager = {}
specificInterfaceManager.Interface = {}

local coreModule = require(script:FindFirstAncestor("CoreModule"))
local userInterfaceManager = require(coreModule.GetObject("/Parent"))

-- Initialize
function specificInterfaceManager.Initialize()

end


-- Methods
function specificInterfaceManager.OpenInterface(platformObject)

end


--
return specificInterfaceManager

--[[

-- Variables
local doorsInterface = {}
doorsInterface.Interface = {}
doorsInterface.ActiveDoorModel = nil

local coreModule = require(script:FindFirstAncestor("CoreModule"))
local specificInterfaceManager = require(coreModule.GetObject("/Parent"))
local userInterfaceManager = require(coreModule.GetObject("/Parent.Parent"))
local doorsMechanic = require(coreModule.GetObject("Game.ClientMechanicsManager.Doors"))
local soundEffectsManager = require(coreModule.GetObject("Game.PlayerManager.SoundEffectsManager"))

-- Initialize
function doorsInterface.Initialize()
	doorsInterface.Interface.Container = specificInterfaceManager.GetInterface():WaitForChild("Frames"):WaitForChild("DoorInterface")
	doorsInterface.Interface.Content = doorsInterface.Interface.Container:WaitForChild("Container")
	doorsInterface.Interface.CodeEntry = doorsInterface.Interface.Content:WaitForChild("CodeEntry"):WaitForChild("Title")
	doorsInterface.Interface.Header = doorsInterface.Interface.Content:WaitForChild("Header")
	doorsInterface.Interface.Buttons = doorsInterface.Interface.Content:WaitForChild("Buttons")
	
	-- Setup
	doorsInterface.SetupEnterConnections()
	doorsInterface.SetupClearConnections()
	
	-- OpenConditionStatusUpdated
	doorsMechanic.OpenConditionStatusUpdated.Event:Connect(function(doorModel, openConditionStatus)
		doorsInterface.ActiveDoorModel = doorModel
		doorsInterface.Interface.Header:WaitForChild("Hint").Text = require(doorModel.Config).Hint or "No hint..."
		
		--
		if openConditionStatus and not userInterfaceManager.IsCurrentActiveContainer(doorsInterface.Interface.Container) then
			userInterfaceManager.UpdateCurrentActiveContainer(doorsInterface.Interface.Container)
		elseif not openConditionStatus and userInterfaceManager.IsCurrentActiveContainer(doorsInterface.Interface.Container) then
			userInterfaceManager.UpdateCurrentActiveContainer(doorsInterface.Interface.Container)
		end
	end)
end

-- Methods
function doorsInterface.SetupEnterConnections()
	local function submitCode(wasEnterPressed)
		if wasEnterPressed == false then return end
		if not doorsInterface.ActiveDoorModel then return end
		
		--
		if doorsInterface.Interface.CodeEntry.Text == require(doorsInterface.ActiveDoorModel.Config).Code then
			doorsInterface.Interface.CodeEntry.Text = ""
			doorsMechanic.OpenDoor(doorsInterface.ActiveDoorModel)
			userInterfaceManager.UpdateCurrentActiveContainer(doorsInterface.Interface.Container)
			soundEffectsManager.PlaySoundEffect("Success")
		else
			doorsInterface.Interface.CodeEntry.Text = ""
			soundEffectsManager.PlaySoundEffect("Error")
		end
	end
	
	--
	doorsInterface.Interface.Buttons:WaitForChild("Enter").Activated:Connect(submitCode)
	doorsInterface.Interface.CodeEntry.FocusLost:Connect(submitCode)
end

function doorsInterface.SetupClearConnections()
	doorsInterface.Interface.Buttons:WaitForChild("Clear").Activated:Connect(function()
		doorsInterface.Interface.CodeEntry.Text = ""
	end)
end

--
return doorsInterface
]]