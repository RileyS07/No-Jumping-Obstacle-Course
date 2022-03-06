local coreModule = require(script:FindFirstAncestor("Core"))
local userDataManager = require(coreModule.GetObject("Modules.Gameplay.PlayerManager.UserDataManager"))
local teleportationManager = require(coreModule.GetObject("Modules.Gameplay.MechanicsManager.TeleportationManager"))

local userInformationUpdatedRemote: RemoteEvent = coreModule.Shared.GetObject("//Remotes.UserInformationUpdated")

local ThisPurchaseManager = {}

-- Processes the purchase, gives rewards, etc.
function ThisPurchaseManager.Process(player: Player)

    -- Let's update FarthestCheckpoint.
    local userData = userDataManager.GetData(player)
    userData.UserInformation.FarthestCheckpoint = math.clamp(userData.UserInformation.FarthestCheckpoint + 1, 1, #workspace.Map.Gameplay.LevelStorage.Checkpoints:GetChildren())
    userData.UserInformation.CurrentCheckpoint = userData.UserInformation.FarthestCheckpoint

    userInformationUpdatedRemote:FireClient(player, userData)
    teleportationManager.TeleportPlayer(player)
end

return ThisPurchaseManager
