local coreModule = require(script:FindFirstAncestor("Core"))
local teleportationManager = require(coreModule.GetObject("Modules.Gameplay.MechanicsManager.TeleportationManager"))

local CharacterManager = {}

-- Initialize
function CharacterManager.Initialize(player: Player, character: Model)

    -- Any setup that happens right when a player spawns.
    teleportationManager.TeleportPlayer(player)

    -- We don't want health regen. Health regernation is handeled by us.
    character:WaitForChild("Health"):Destroy()
end

return CharacterManager
