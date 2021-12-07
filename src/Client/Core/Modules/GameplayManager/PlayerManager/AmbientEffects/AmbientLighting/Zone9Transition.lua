-- Variables
local specificAmbientLighting = {}
specificAmbientLighting.UserData = nil
specificAmbientLighting.EffectPlaying = false

local coreModule = require(script:FindFirstAncestor("Core"))
local gameplayLightingManager = require(coreModule.GetObject("Modules.GameplayManager.PlayerManager.GameplayLighting"))
local clientEssentialsLibrary = require(coreModule.GetObject("Libraries.ClientEssentials"))
local utilitiesLibrary = require(coreModule.Shared.GetObject("Libraries.Utilities"))

-- Initialize
function specificAmbientLighting.Initialize()
    local startingPoint = workspace:WaitForChild("Map"):WaitForChild("Misc"):WaitForChild("Ambient"):WaitForChild("SaturationBlock")
    local endingPoint = workspace:WaitForChild("Map"):WaitForChild("Gameplay"):WaitForChild("LevelStorage"):WaitForChild("Checkpoints"):WaitForChild("81")
    specificAmbientLighting.UserData = coreModule.Shared.GetObject("//Remotes.Data.GetUserData"):InvokeServer()

    -- Stage updated.
    coreModule.Shared.GetObject("//Remotes.Gameplay.Stages.CheckpointInformationUpdated").OnClientEvent:Connect(function(userData)
        specificAmbientLighting.UserData = userData
    end)

    -- Touched.
    startingPoint.Touched:Connect(function(hit)
        local player = game:GetService("Players"):GetPlayerFromCharacter(hit.Parent)
        if player ~= clientEssentialsLibrary.GetPlayer() or not utilitiesLibrary.IsPlayerAlive() then return end
        if specificAmbientLighting.EffectPlaying then return end
        specificAmbientLighting.EffectPlaying = true

        -- Update the ColorCorrection.
        while true do
            if not clientEssentialsLibrary.GetPlayer() then break end
            if not utilitiesLibrary.IsPlayerAlive() then gameplayLightingManager.UpdateLighting(specificAmbientLighting.UserData) break end
            if specificAmbientLighting.UserData.UserInformation.CurrentCheckpoint ~= 80 then gameplayLightingManager.UpdateLighting(specificAmbientLighting.UserData) break end

            -- We only care about the X and Z components.
            local currentPosition = clientEssentialsLibrary.GetPlayer().Character:GetPrimaryPartCFrame().Position*Vector3.new(1, 0, 1)
            local startingPositionVector, endingPositionVector = startingPoint.Position*Vector3.new(1, 0, 1), endingPoint.Position*Vector3.new(1, 0, 1)

            -- We have to make sure they're on the right side.
            if math.sign((startingPositionVector - currentPosition).Unit.X) == -1 then
                game:GetService("Lighting").ColorCorrection.Saturation = math.clamp(-(startingPositionVector - currentPosition).Magnitude/(startingPositionVector - endingPositionVector).Magnitude, -1, 0)
            else
                gameplayLightingManager.UpdateLighting(specificAmbientLighting.UserData) 
                break
            end

            game:GetService("RunService").RenderStepped:Wait()
        end

        specificAmbientLighting.EffectPlaying = false
    end)
end


--
return specificAmbientLighting