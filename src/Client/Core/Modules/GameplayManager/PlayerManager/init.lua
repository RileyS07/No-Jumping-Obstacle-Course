-- Variables
local playerManager = {}
local coreModule = require(script:FindFirstAncestor("Core"))
local clientEssentialsLibrary = require(coreModule.GetObject("Libraries.ClientEssentials"))

-- Initialize
function playerManager.Initialize()
	coreModule.LoadModule("/UserInterfaceManager")
	coreModule.LoadModule("/GameplayLighting")
	coreModule.LoadModule("/GameplayMusic")
	--coreModule.LoadModule("/ForceShiftLock")
	coreModule.LoadModule("/SoundEffects")
	coreModule.LoadModule("/AmbientEffects")
	--coreModule.LoadModule("/CutsceneManager")

	-- Miscellaneous setup.
	coreModule.Shared.GetObject("//Remotes.Gameplay.Miscellaneous.MakeSystemMessage").OnClientEvent:Connect(function(messageText, messageColor)
		if typeof(messageText) ~= "string" then return end

		-- [Server]: Hello!
		clientEssentialsLibrary.SetCore(
			"ChatMakeSystemMessage",
			{Text = "[System]: "..messageText, Color = messageColor or Color3.fromRGB(228, 74, 70)}
		)
	end)
end

--
return playerManager