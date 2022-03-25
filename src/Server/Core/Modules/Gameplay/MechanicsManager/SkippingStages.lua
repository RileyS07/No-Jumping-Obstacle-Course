local CoreModule = require(script:FindFirstAncestor("Core"))
local userDataManager = require(CoreModule.GetObject("Modules.Gameplay.PlayerManager.UserDataManager"))
local teleportationManager = require(CoreModule.GetObject("Modules.Gameplay.MechanicsManager.TeleportationManager"))
local leaderstatsManager = require(CoreModule.GetObject("Modules.Gameplay.PlayerManager.Leaderstats"))
local checkpointsManager = require(CoreModule.GetObject("Modules.Gameplay.MechanicsManager.TeleportationManager.Checkpoints"))

local userInformationUpdatedRemote: RemoteEvent = CoreModule.Shared.GetObject("//Remotes.UserInformationUpdated")
local playSoundEffectRemote: RemoteEvent = CoreModule.Shared.GetObject("//Remotes.PlaySoundEffect")

local SkippingStagesManager = {}

-- Initialization
function SkippingStagesManager.Initialize()
    CoreModule.Shared.GetObject("//Remotes.SkipStage").OnServerEvent:Connect(SkippingStagesManager.SkipStage)
end

-- Skips a stage
function SkippingStagesManager.SkipStage(Player: Player)

    -- Let's update FarthestCheckpoint.
    local userData = userDataManager.GetData(Player)

    if not userData or userData.UserInformation.SavedSkips <= 0 then
        return
    end

    local original = userData.UserInformation.CurrentCheckpoint
    userData.UserInformation.SavedSkips -= 1
    userData.UserInformation.FarthestCheckpoint = math.clamp(userData.UserInformation.FarthestCheckpoint + 1, 1, #workspace.Map.Gameplay.LevelStorage.Checkpoints:GetChildren())
    userData.UserInformation.CurrentCheckpoint = userData.UserInformation.FarthestCheckpoint
    checkpointsManager.CurrentCheckpointUpdated:Fire(Player, original, userData.UserInformation.CurrentCheckpoint)
    playSoundEffectRemote:FireClient(Player, "CheckpointTouched")
    playSoundEffectRemote:FireClient(Player, "Stage" .. tostring(userData.UserInformation.CurrentCheckpoint))
    leaderstatsManager.Update(Player)

    userInformationUpdatedRemote:FireClient(Player, userData)
    teleportationManager.TeleportPlayer(Player)
end

return SkippingStagesManager
