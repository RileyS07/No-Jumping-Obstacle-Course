-- Variables
local characterManager = {}
local coreModule = require(script:FindFirstAncestor("CoreModule"))
local teleportationManager = require(coreModule.GetObject("Modules.GameplayManager.MechanicsManager.TeleportationManager"))

-- Initialize
function characterManager.Initialize(player, character)
    teleportationManager.TeleportPlayer(player)
end


--
return characterManager