local players: Players = game:GetService("Players")

local coreModule = require(script:FindFirstAncestor("Core"))
local userInterfaceManager = require(coreModule.GetObject("Modules.Gameplay.PlayerManager.UserInterfaceManager"))
local soundEffectsManager = require(coreModule.GetObject("Modules.Gameplay.PlayerManager.SoundEffects"))
local playerUtilities = require(coreModule.Shared.GetObject("Libraries.Utilities.PlayerUtilities"))
local doorMechanicManager

local thisInterface: ScreenGui = userInterfaceManager.GetInterface("CodeEntry")
local contentFrame: Frame = thisInterface:WaitForChild("Container"):WaitForChild("Content")
local buttonsContainer: Frame = contentFrame:WaitForChild("Buttons")
local keypadContainer: Frame = contentFrame:WaitForChild("Keypad")
local codeOutputText: TextLabel = contentFrame:WaitForChild("CodeOutput"):WaitForChild("OutputText")
local hintText: TextLabel = contentFrame:WaitForChild("Hint")

local ThisInterfaceManager = {}
ThisInterfaceManager.CurrentPlatform = nil

-- Initialize
function ThisInterfaceManager.Initialize()

	-- Cyclic dependencies.
	doorMechanicManager = require(coreModule.GetObject("Modules.Gameplay.MechanicsManager.Doors"))

	-- We need to setup the interface so it's ready for when the mechanic opens it.
	ThisInterfaceManager._SetupInterfaceComponents()

	-- We need to remove CurrentPlatform if they've closed the interface through another means.
	userInterfaceManager.ActiveInterfaceUpdated:Connect(function(interface: GuiBase2d)
		if interface ~= thisInterface then
			ThisInterfaceManager.CurrentPlatform = nil
		end
	end)
end

-- Opens this interface, this should only be called by the mechanic portion of this.
function ThisInterfaceManager.OpenInterface(thisPlatform: Instance)

	-- We need to clear the text and apply the hint.
	codeOutputText.Text = ""
	hintText.Text = thisPlatform:GetAttribute("Hint") or "No hint..."
	ThisInterfaceManager.CurrentPlatform = thisPlatform

	-- We don't want to accidentally close this interface.
	if userInterfaceManager.ActiveInterface ~= thisInterface then
		userInterfaceManager.UpdateInterfaceShown(thisInterface)
	end

	-- When the player walks too far away from the platform we want to close this interface.
	if userInterfaceManager.ActiveInterface == thisInterface then
		if thisPlatform:IsA("Model") and thisPlatform.PrimaryPart then

			task.spawn(function()
				while true do

					-- These need to be true before we can do any distance checking.
					if userInterfaceManager.ActiveInterface ~= thisInterface then break end
					if ThisInterfaceManager.CurrentPlatform ~= thisPlatform then break end
					if not playerUtilities.IsPlayerAlive() then break end

					-- Are they too far from the platform?
					if players.LocalPlayer:DistanceFromCharacter(thisPlatform:GetPrimaryPartCFrame().Position) > 25 then
						userInterfaceManager.UpdateInterfaceShown(thisInterface, true)
					end

					task.wait()
				end
			end)
		end
	end
end


-- Initializes the interface components.
function ThisInterfaceManager._SetupInterfaceComponents()

	-- When they press yes we want to check if the code is correct or not.
	-- If it is correct then we turn on the platform.
	-- If not then we make an error sound.
	buttonsContainer:WaitForChild("Yes").Activated:Connect(function()

		soundEffectsManager.PlaySoundEffect("Click")

		-- We only want to perform this logic if there is a platform currently.
		if ThisInterfaceManager.CurrentPlatform then

			-- The code was valid?
			if codeOutputText.Text == (ThisInterfaceManager.CurrentPlatform:GetAttribute("Code") or "1234") then
				soundEffectsManager.PlaySoundEffect("Success")
				task.defer(doorMechanicManager.SimulatePlatform, ThisInterfaceManager.CurrentPlatform)
				task.defer(userInterfaceManager.UpdateInterfaceShown, thisInterface, true)

			-- Invalid
			else
				soundEffectsManager.PlaySoundEffect("Error")
				codeOutputText.Text = ""
			end
		end
	end)

	-- When they press clear we want to clear the text.
	buttonsContainer:WaitForChild("Clear").Activated:Connect(function()
		codeOutputText.Text = ""
		soundEffectsManager.PlaySoundEffect("Click")
	end)

	-- This is the method of inputting numbers.
	-- When they press a key it adds its corresponding value to the string.
	for _, keyButton: GuiObject in next, keypadContainer:GetChildren() do
		if keyButton:IsA("GuiButton") then

			keyButton.Activated:Connect(function()

				-- We want to make sure the code length isn't longer than it can be.
				if string.len(codeOutputText.Text) >= codeOutputText.MaxVisibleGraphemes then
					soundEffectsManager.PlaySoundEffect("Error")
				else
					soundEffectsManager.PlaySoundEffect("KeypadPress")
					codeOutputText.Text = codeOutputText.Text .. keyButton.Name
				end
			end)
		end
	end
end

return ThisInterfaceManager
