-- Variables
local teleportationManager = {}
teleportationManager.PlayersBeingTeleported = {}

local coreModule = require(script:FindFirstAncestor("CoreModule"))

-- Initialize
function teleportationManager.Initialize()
	coreModule.LoadModule("/Checkpoints")
	coreModule.LoadModule("/RespawnPlatforms")
end

-- Methods
function teleportationManager.TeleportPlayer(player)
	
end

function teleportationManager.IsPlayerBeingTeleported(player)
	return teleportationManager.PlayersBeingTeleported[player]
end

--
return teleportationManager