local coreModule = require(script:FindFirstAncestor("Core"))
local userDataManager = require(coreModule.GetObject("Modules.Gameplay.PlayerManager.UserDataManager"))
local skippingStagesManager = require(coreModule.GetObject("Modules.Gameplay.MechanicsManager.SkippingStages"))

local ThisPurchaseManager = {}

-- Processes the purchase, gives rewards, etc.
function ThisPurchaseManager.Process(player: Player)

    -- Let's update FarthestCheckpoint.
    local userData = userDataManager.GetData(player)
    userData.UserInformation.SavedSkips += 1
    skippingStagesManager.SkipStage(player)
end

return ThisPurchaseManager
