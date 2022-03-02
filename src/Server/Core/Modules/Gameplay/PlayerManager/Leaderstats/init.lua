local coreModule = require(script:FindFirstAncestor("Core"))
local userDataManager = require(coreModule.GetObject("Modules.Gameplay.PlayerManager.UserDataManager"))
local checkpointsManager = require(coreModule.GetObject("Modules.Gameplay.MechanicsManager.TeleportationManager.Checkpoints"))

local LeaderstatsManager = {}

-- Initialize
function LeaderstatsManager.Initialize(player: Player)
    LeaderstatsManager.Update(player)

    checkpointsManager.CurrentCheckpointUpdated:Connect(function(thisPlayer: Player)
        LeaderstatsManager.Update(thisPlayer)
    end)
end

-- Updates a user's leaderstats.
function LeaderstatsManager.Update(player: Player)

    -- Do we need to create the leaderstats?
    if not player:FindFirstChild("leaderstats") then
        script.leaderstats:Clone().Parent = player
    end

    -- Updating the leaderstats values.
    local leaderstatsFolder: Folder = player.leaderstats
    local userData: {} = userDataManager.GetData(player)

    leaderstatsFolder.Stage.Value = userData.UserInformation.FarthestCheckpoint
end

return LeaderstatsManager
