-- Variables
local timedStagesManager = {}
local coreModule = require(script:FindFirstAncestor("CoreModule"))
local userDataManager = require(coreModule.GetObject("Modules.GameplayManager.PlayerManager.UserDataManager"))
local teleportationManager = require(coreModule.GetObject("Modules.GameplayManager.MechanicsManager.TeleportationManager"))
local checkpointsManager = require(coreModule.GetObject("Modules.GameplayManager.MechanicsManager.TeleportationManager.Checkpoints"))
local utilitiesLibrary = require(coreModule.Shared.GetObject("Libraries.Utilities"))

-- Initialize
function timedStagesManager.Initialize()

    -- This is what we're gonna use to track when they touch a new checkpoint.
    checkpointsManager.CurrentCheckpointUpdated.Event:Connect(function(player, lastStage, currentStage)
        timedStagesManager.ValidateTimer(player)
    end)

    -- Reset the data.
    teleportationManager.PlayerTeleported.Event:Connect(function(player)
        timedStagesManager.ValidateTimer(player)
    end)
end


-- Methods
function timedStagesManager.ValidateTimer(player)
    if not utilitiesLibrary.IsPlayerAlive(player) then return end

    -- Do we have to wait till they move?
    if player.Character.Humanoid.WalkSpeed > (player.Character.PrimaryPart.Velocity*Vector3.new(1, 0, 1)).Magnitude then

        -- Running may fire for 0 which is cool you know.
        local currentSpeed = player.Character.Humanoid.Running:Wait()
        if currentSpeed == 0 then
            repeat currentSpeed = player.Character.Humanoid.Running:Wait() until currentSpeed > 0
        end

        timedStagesManager.StartTimer(player)
    else
        timedStagesManager.StartTimer(player)
    end
end


function timedStagesManager.StartTimer(player)

end


--
return timedStagesManager