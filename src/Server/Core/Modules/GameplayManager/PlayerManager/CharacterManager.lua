-- Variables
local characterManager = {}
local coreModule = require(script:FindFirstAncestor("Core"))
local teleportationManager = require(coreModule.GetObject("Modules.GameplayManager.MechanicsManager.TeleportationManager"))

-- Initialize
function characterManager.Initialize(player, character)
    teleportationManager.TeleportPlayer(player)

    -- Setup.
    character:WaitForChild("Health"):Destroy()
end


--
return characterManager