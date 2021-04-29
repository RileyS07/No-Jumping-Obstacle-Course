-- Variables
local specificInterfaceManager = {}
specificInterfaceManager.Interface = {}
specificInterfaceManager.CurrentPlatformObject = nil

local coreModule = require(script:FindFirstAncestor("CoreModule"))
local userInterfaceManager = require(coreModule.GetObject("/Parent"))
local soundEffectsManager = require(coreModule.GetObject("Modules.GameplayManager.PlayerManager.SoundEffects"))

-- Initialize
function specificInterfaceManager.Initialize()
	specificInterfaceManager.Interface.Container = userInterfaceManager.GetInterface("MainInterface"):WaitForChild("CodeInterface")
	specificInterfaceManager.Interface.Content = specificInterfaceManager.Interface.Container:WaitForChild("Content")
	specificInterfaceManager.Interface.Buttons = specificInterfaceManager.Interface.Content:WaitForChild("Buttons")
	specificInterfaceManager.Interface.CodeOutputText = specificInterfaceManager.Interface.Content:WaitForChild("CodeOutput"):WaitForChild("OutputText")
	specificInterfaceManager.Interface.HintText = specificInterfaceManager.Interface.Content:WaitForChild("Hint")
	specificInterfaceManager.Interface.KeypadContainer = specificInterfaceManager.Interface.Content:WaitForChild("Keypad")
	local doorMechanicManager = require(coreModule.GetObject("Modules.GameplayManager.MechanicsManager.Doors"))

	-- Attempting to open the door.
	specificInterfaceManager.Interface.Buttons:WaitForChild("Yes").Activated:Connect(function()
		if not specificInterfaceManager.CurrentPlatformObject then return end
		
		-- The code was valid?
		if specificInterfaceManager.Interface.CodeOutputText.Text == (specificInterfaceManager.CurrentPlatformObject:GetAttribute("Code") or "1234") then
			userInterfaceManager.UpdateActiveContainer(specificInterfaceManager.Interface.Container)
			doorMechanicManager.SimulateObject(specificInterfaceManager.CurrentPlatformObject)

		-- Invalid
		else
			soundEffectsManager.PlaySoundEffect("Error")
			specificInterfaceManager.Interface.CodeOutputText.Text = ""
		end
	end)

	-- Clearing the code.
	specificInterfaceManager.Interface.Buttons:WaitForChild("Clear").Activated:Connect(function()
		specificInterfaceManager.Interface.CodeOutputText.Text = ""
	end)

	-- Inputting numbers.
	for _, keyButton in next, specificInterfaceManager.Interface.KeypadContainer:GetChildren() do
		if keyButton:IsA("GuiButton") then
			keyButton.Activated:Connect(function()
				if specificInterfaceManager.Interface.CodeOutputText.Text:len() >= (script:GetAttribute("MaxCharacters") or 9) then
					soundEffectsManager.PlaySoundEffect("Error")
				else
					soundEffectsManager.PlaySoundEffect("KeypadPress")
					specificInterfaceManager.Interface.CodeOutputText.Text = specificInterfaceManager.Interface.CodeOutputText.Text..keyButton.Name
				end
			end)
		end
	end
end


-- Methods
function specificInterfaceManager.OpenInterface(platformObject)
	if typeof(platformObject) ~= "Instance" then return end

	-- Setup.
	specificInterfaceManager.CurrentPlatformObject = platformObject
	specificInterfaceManager.Interface.CodeOutputText.Text = ""
	specificInterfaceManager.Interface.HintText.Text = platformObject:GetAttribute("Hint") or "No hint..."
	userInterfaceManager.UpdateActiveContainer(specificInterfaceManager.Interface.Container)
end


--
return specificInterfaceManager