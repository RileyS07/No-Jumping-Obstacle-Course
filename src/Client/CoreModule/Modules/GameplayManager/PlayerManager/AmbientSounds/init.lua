-- Variables
local ambientSoundsManager = {}
local coreModule = require(script:FindFirstAncestor("CoreModule"))

-- Initialize
function ambientSoundsManager.Initialize()
    coreModule.Shared.GetObject("//Remotes.Gameplay.Stages.CheckpointInformationUpdated").OnClientEvent:Connect(function(userData)
        for _, specificAmbientSoundManager in next, script:GetChildren() do
            if specificAmbientSoundManager:IsA("ModuleScript") then
                specificAmbientSoundManager = require(specificAmbientSoundManager)

                -- We need to check if the current stage is within the applicable range.
                if userData.UserInformation.CurrentCheckpoint >= specificAmbientSoundManager.ApplicableRange.Min and userData.UserInformation.CurrentCheckpoint <= specificAmbientSoundManager.ApplicableRange.Max then
                    specificAmbientSoundManager.Start()
                else
                    specificAmbientSoundManager.Stop()
                end
            end
        end
    end)
end


--
return ambientSoundsManager