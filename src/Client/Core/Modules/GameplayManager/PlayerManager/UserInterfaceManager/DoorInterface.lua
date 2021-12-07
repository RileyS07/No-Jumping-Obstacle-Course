-- Variables
local specificInterfaceManager = {}
specificInterfaceManager.Interface = {}
specificInterfaceManager.CurrentPlatformObject = nil

local coreModule = require(script:FindFirstAncestor("Core"))
local userInterfaceManager = require(coreModule.GetObject("Modules.GameplayManager.PlayerManager.UserInterfaceManager"))
local clientEssentialsLibrary = require(coreModule.GetObject("Libraries.ClientEssentials"))
local soundEffectsManager = require(coreModule.GetObject("Modules.GameplayManager.PlayerManager.SoundEffects"))
local utilitiesLibrary = require(coreModule.Shared.GetObject("Libraries.Utilities"))

-- Initialize
function specificInterfaceManager.Initialize()
	specificInterfaceManager.Interface.Container = userInterfaceManager.GetInterface("MainInterface"):WaitForChild("Containers"):WaitForChild("CodeInterface")
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
			soundEffectsManager.PlaySoundEffect("Success")
			userInterfaceManager.UpdateActiveContainer(specificInterfaceManager.Interface.Container)
			doorMechanicManager.SimulatePlatform(specificInterfaceManager.CurrentPlatformObject)

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

	-- Go away.
	if userInterfaceManager.IsActiveContainer(specificInterfaceManager.Interface.Container) then
		if not platformObject:IsA("Model") or not platformObject.PrimaryPart then return end

		coroutine.wrap(function()
			while true do
				if not userInterfaceManager.IsActiveContainer(specificInterfaceManager.Interface.Container) then return end
				if specificInterfaceManager.CurrentPlatformObject ~= platformObject then return end
				if not utilitiesLibrary.IsPlayerAlive(clientEssentialsLibrary.GetPlayer()) then return end

				-- Close it.
				if clientEssentialsLibrary.GetPlayer():DistanceFromCharacter(platformObject:GetPrimaryPartCFrame().Position) > 25 then
					userInterfaceManager.UpdateActiveContainer(specificInterfaceManager.Interface.Container)
				end

				game:GetService("RunService").Stepped:Wait()
			end
		end)()
	end
end


--
return specificInterfaceManager