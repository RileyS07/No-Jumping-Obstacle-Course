-- Variables
local stageInformationManager = {}
stageInformationManager.StageInformation = {}

local coreModule = require(script:FindFirstAncestor("CoreModule"))
local userDataManager = require(coreModule.GetObject("Modules.GameplayManager.PlayerManager.UserDataManager"))
local teleportationManager = require(coreModule.GetObject("Modules.GameplayManager.MechanicsManager.TeleportationManager"))
local checkpointsManager = require(coreModule.GetObject("Modules.GameplayManager.MechanicsManager.TeleportationManager.Checkpoints"))

-- Initialize
function stageInformationManager.Initialize()

    -- This is what we're gonna use to track when they touch a new checkpoint.
    checkpointsManager.CurrentCheckpointUpdated.Event:Connect(function(player, lastStage, currentStage)
        stageInformationManager.StageInformation[player] = stageInformationManager.StageInformation[player] or {}

        if stageInformationManager.StageInformation[player].Stage == lastStage and currentStage == lastStage + 1 then
            local timeBetweenStages = math.floor((os.clock() - stageInformationManager.StageInformation[player].Start)*100)/100
            print("It took "..player.Name.." "..timeBetweenStages.." seconds to go from stage "..lastStage.." to stage "..currentStage..".")
            stageInformationManager.StageInformation[player].Stage = currentStage
            stageInformationManager.StageInformation[player].Start = os.clock()

        -- Setup the data.
        else
            stageInformationManager.StageInformation[player] = {
                Stage = currentStage,
                Start = os.clock()
            }
        end
    end)

    -- Reset the data.
    teleportationManager.PlayerTeleported.Event:Connect(function(player)
        if not userDataManager.GetData(player) then return end
        stageInformationManager.StageInformation[player] = {
            Stage = userDataManager.GetData(player).UserInformation.CurrentCheckpoint,
            Start = os.clock()
        }
    end)
end


--
return stageInformationManager