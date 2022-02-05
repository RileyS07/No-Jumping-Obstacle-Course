-- Variables
local leaderstatsManager = {}
local coreModule = require(script:FindFirstAncestor("Core"))
local userDataManager = require(coreModule.GetObject("Modules.GameplayManager.PlayerManager.UserDataManager"))
local checkpointsManager = require(coreModule.GetObject("Modules.GameplayManager.MechanicsManager.TeleportationManager.Checkpoints"))

-- Initialize
function leaderstatsManager.Initialize(player: Player)
    leaderstatsManager.Update(player)

    checkpointsManager.CurrentCheckpointUpdated.Event:Connect(function(player: Player)
        leaderstatsManager.Update(player)
    end)
end

-- Public Methods

-- Updates a user's leaderstats.
function leaderstatsManager.Update(player: Player)

    -- Do we need to create the leaderstats?
    if not player:FindFirstChild("leaderstats") then
        local leaderstatsFolder = Instance.new("Folder")
        leaderstatsFolder.Name = "leaderstats"

        local stageValue = Instance.new("IntValue")
        stageValue.Name = "Stage"
        stageValue.Parent = leaderstatsFolder
        leaderstatsFolder.Parent = player
    end

    -- Updating the leaderstats values.
    local leaderstatsFolder = player.leaderstats
    local userData = userDataManager.GetData(player)

    leaderstatsFolder.Stage.Value = userData.UserInformation.FarthestCheckpoint
end

--
return leaderstatsManager