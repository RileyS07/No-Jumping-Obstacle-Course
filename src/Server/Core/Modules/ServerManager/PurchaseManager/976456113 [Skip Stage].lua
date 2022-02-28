local coreModule = require(script:FindFirstAncestor("Core"))
local userDataManager = require(coreModule.GetObject("Modules.GameplayManager.PlayerManager.UserDataManager"))
local teleportationManager = require(coreModule.GetObject("Modules.GameplayManager.MechanicsManager.TeleportationManager"))

local ThisPurchaseManager = {}

-- Processes the purchase, gives rewards, etc.
function ThisPurchaseManager.Process(player: Player)

    -- Let's update FarthestCheckpoint.
    local userData = userDataManager.GetData(player)
    userData.UserInformation.FarthestCheckpoint = math.clamp(userData.UserInformation.FarthestCheckpoint + 1, 1, #workspace.Map.Gameplay.LevelStorage.Checkpoints:GetChildren())
    userData.UserInformation.CurrentCheckpoint = userData.UserInformation.FarthestCheckpoint

    coreModule.Shared.GetObject("//Remotes.Gameplay.Stages.CheckpointInformationUpdated"):FireClient(player, userData)
    teleportationManager.TeleportPlayer(player)
end

return ThisPurchaseManager
