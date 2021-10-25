-- Variables
local commandInformation = {}
commandInformation.CommandType = "Miscellaneous"

local coreModule = require(script:FindFirstAncestor("CoreModule"))
local adminManager = require(coreModule.GetObject("/Parent.Parent"))
local utilitiesLibrary = require(coreModule.Shared.GetObject("Libraries.Utilities"))

-- RunCommand; The function that runs the command
function commandInformation.RunCommand(commandSender, commandInformation)
	for _, targetPlayer in next, adminManager.GetTargetArrayFromRawString(commandSender, commandInformation.Arguments[1]) do
		if utilitiesLibrary.IsPlayerAlive(targetPlayer) then
			coreModule.Services.CollectionService:RemoveTag(targetPlayer.Character, "Forcefield")
		end
	end
end


--
return commandInformation