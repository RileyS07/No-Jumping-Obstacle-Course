-- Variables
local purchaseManager = {}
local coreModule = require(script:FindFirstAncestor("Core"))
local userDataManager = require(coreModule.GetObject("Modules.GameplayManager.PlayerManager.UserDataManager"))
local teleportationManager = require(coreModule.GetObject("Modules.GameplayManager.MechanicsManager.TeleportationManager"))

-- Initialize
function purchaseManager.Initialize()

    -- Skips
    game:GetService("MarketplaceService").ProcessReceipt = function(receiptInformation: {})

        -- If this player is valid and it's the correct id let's go forward.
        local player = game:GetService("Players"):GetPlayerByUserId(receiptInformation.PlayerId)

        if player and receiptInformation.ProductId == 976456113 then

            -- Let's update FarthestCheckpoint.
            local userData = userDataManager.GetData(player)
            userData.UserInformation.FarthestCheckpoint = math.clamp(userData.UserInformation.FarthestCheckpoint + 1, 1, #workspace.Map.Gameplay.LevelStorage.Checkpoints:GetChildren())
            userData.UserInformation.CurrentCheckpoint = userData.UserInformation.FarthestCheckpoint

            coreModule.Shared.GetObject("//Remotes.Gameplay.Stages.CheckpointInformationUpdated"):FireClient(player, userData)
            teleportationManager.TeleportPlayer(player)
        end

        return Enum.ProductPurchaseDecision.PurchaseGranted
    end
end

--
return purchaseManager