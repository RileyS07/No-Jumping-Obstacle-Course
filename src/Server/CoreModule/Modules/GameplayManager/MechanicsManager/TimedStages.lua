-- Variables
local timedStagesManager = {}
timedStagesManager.TimerInformation = {}

local coreModule = require(script:FindFirstAncestor("CoreModule"))
local userDataManager = require(coreModule.GetObject("Modules.GameplayManager.PlayerManager.UserDataManager"))
local teleportationManager = require(coreModule.GetObject("Modules.GameplayManager.MechanicsManager.TeleportationManager"))
local checkpointsManager = require(coreModule.GetObject("Modules.GameplayManager.MechanicsManager.TeleportationManager.Checkpoints"))
local powerupsManager = require(coreModule.GetObject("Modules.GameplayManager.MechanicsManager.PowerupsManager"))
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
    timedStagesManager.TimerInformation[player] = nil
    powerupsManager.RemovePowerup(player, "Timer")
    
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
    if not userDataManager.GetData(player) then return end

    -- Check if it's timed.
    local currentCheckpoint = userDataManager.GetData(player).UserInformation.CurrentCheckpoint
    local timedLevelInformation = workspace.Map.Gameplay.LevelStorage.Stages:FindFirstChild("Level "..currentCheckpoint, true)
    if timedLevelInformation and timedLevelInformation:GetAttribute("Timer") and timedLevelInformation:GetAttribute("Timer") > 0 then
        timedStagesManager.TimerInformation[player] = timedStagesManager.TimerInformation[player] or {}
        timedStagesManager.TimerInformation[player].Duration = timedLevelInformation:GetAttribute("Timer")
        timedStagesManager.TimerInformation[player].Start = os.clock()
        timedStagesManager.TimerInformation[player].IsFresh = timedStagesManager.TimerInformation[player].IsActive ~= true
        powerupsManager.UpdatePowerup(player, "Timer", timedStagesManager.TimerInformation[player])

        -- Debouncing.
        if timedStagesManager.TimerInformation[player].IsActive then return end
        timedStagesManager.TimerInformation[player].IsActive = true

        -- Starting the timer.
        coroutine.wrap(function()
            while timedStagesManager.TimerInformation[player] ~= nil do
                local timeDifference = timedStagesManager.TimerInformation[player].Duration - (os.clock() - timedStagesManager.TimerInformation[player].Start)
                print(math.ceil(timeDifference))

                if timeDifference <= 0 then
                    timedStagesManager.TimerInformation[player].IsActive = false
                    teleportationManager.TeleportPlayer(player)
                    break
                end

                wait(1)
            end
        end)()
    else
        timedStagesManager.TimerInformation[player] = nil
        powerupsManager.RemovePowerup(player, "Timer")
        print("They're not at a timed level")
    end
end


--
return timedStagesManager