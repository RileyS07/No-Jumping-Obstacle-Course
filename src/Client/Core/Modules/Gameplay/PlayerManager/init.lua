local coreModule = require(script:FindFirstAncestor("Core"))
local playerUtilities = require(coreModule.Shared.GetObject("Libraries.Utilities.PlayerUtilities"))
local sharedConstants = require(coreModule.Shared.GetObject("Libraries.SharedConstants"))

local makeSystemMessageRemote: RemoteEvent = coreModule.Shared.GetObject("//Remotes.MakeSystemMessage")

local PlayerManager = {}

-- Initialize
function PlayerManager.Initialize()

	-- We load this first for the loading screen.
	coreModule.LoadModule("/UserInterfaceManager")

	-- Loading all other modules.
	coreModule.LoadModule("/GameplayMusic")
	coreModule.LoadModule("/StageLighting")
	coreModule.LoadModule("/ForcedShiftLock")
	coreModule.LoadModule("/SoundEffects")
	--coreModule.LoadModule("/AmbientEffects")
	coreModule.LoadModule("/RespawnOverride")
	--coreModule.LoadModule("/CutsceneManager")

	-- The server wants to send a message out, this event is called for all players.
	makeSystemMessageRemote.OnClientEvent:Connect(PlayerManager.MakeSystemMessage)
end

-- Creates a system message for this user.
function PlayerManager.MakeSystemMessage(messageText: string, messageColor: Color3?)

	playerUtilities.SetCore(
		"ChatMakeSystemMessage",
		{
			Text = string.format(sharedConstants.FORMATS.SYSTEM_MESSAGE_FORMAT, messageText),
			Color = messageColor or sharedConstants.INTERFACE.SYSTEM_MESSAGE_DEFAULT_COLOR
		}
	)
end

return PlayerManager
