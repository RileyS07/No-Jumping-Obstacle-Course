-- Variables
local gameplayMechanicManager = {}
gameplayMechanicManager.Remotes = {}
gameplayMechanicManager.PlatformsBeingSimulated = {}

local coreModule = require(script:FindFirstAncestor("Core"))
local utilitiesLibrary = require(coreModule.Shared.GetObject("Libraries._Utilities"))

-- Initialize
function gameplayMechanicManager.Initialize()
    if not workspace.Map.Gameplay.PlatformerMechanics:FindFirstChild("HealingPlatforms") then return end

    -- Setting up the HealingPlatforms to be functional.
    for _, healingPlatformContainer in next, workspace.Map.Gameplay.PlatformerMechanics.HealingPlatforms:GetChildren() do
        for _, healingPlatform in next, healingPlatformContainer:GetChildren() do

            -- PrimaryPart is what the players will touch to heal themselves.
            if healingPlatform:IsA("Model") and healingPlatform.PrimaryPart then
                healingPlatform.PrimaryPart.Touched:Connect(function(hit)
                    local player = game:GetService("Players"):GetPlayerFromCharacter(hit.Parent)
                    if not utilitiesLibrary.IsPlayerAlive(player) then return end
                    if gameplayMechanicManager.IsPlatformBeingSimulated(player, healingPlatform) then return end

                    gameplayMechanicManager.SimulateHealingPlatform(player, healingPlatform)
                end)

            elseif healingPlatform:IsA("Model") then
                print(
					("HealingPlatform: %s, has PrimaryPart: %s."):format(healingPlatform:GetFullName(), tostring(healingPlatform.PrimaryPart ~= nil)),
					warn
				)
            end
        end
    end

    gameplayMechanicManager.Remotes.PlaySoundEffect = coreModule.Shared.GetObject("//Remotes.Gameplay.Miscellaneous.PlaySoundEffect")
end


-- Methods
function gameplayMechanicManager.SimulateHealingPlatform(player, healingPlatform)
    if not utilitiesLibrary.IsPlayerAlive(player) then return end
    if player.Character.Humanoid.Health == player.Character.Humanoid.MaxHealth then return end
    if typeof(healingPlatform) ~= "Instance" or not healingPlatform:IsA("Model") or not healingPlatform.PrimaryPart then return end
    if gameplayMechanicManager.IsPlatformBeingSimulated(player, healingPlatform) then return end

    gameplayMechanicManager.PlatformsBeingSimulated[healingPlatform] = gameplayMechanicManager.PlatformsBeingSimulated[healingPlatform] or {}
    gameplayMechanicManager.PlatformsBeingSimulated[healingPlatform][player] = true

    -- Healing time.
    gameplayMechanicManager.Remotes.PlaySoundEffect:FireClient(player, "Healing", {Parent = healingPlatform.PrimaryPart})
    for _ = 1, (healingPlatform:GetAttribute("Duration") or script:GetAttribute("DefaultDuration") or 1)*(healingPlatform:GetAttribute("Speed") or script:GetAttribute("DefaultSpeed") or 1) do
        if not utilitiesLibrary.IsPlayerAlive(player) then break end
        if player.Character.Humanoid.Health == player.Character.Humanoid.MaxHealth then break end

        player.Character.Humanoid.Health = math.clamp(
            player.Character.Humanoid.Health + (healingPlatform:GetAttribute("Amount") or script:GetAttribute("DefaultAmount") or 100),
            player.Character.Humanoid.Health,
            player.Character.Humanoid.MaxHealth
        )

        task.wait(1/(healingPlatform:GetAttribute("Duration") or script:GetAttribute("DefaultDuration") or 1))
    end

    task.wait(script:GetAttribute("Delay") or 1)
    gameplayMechanicManager.PlatformsBeingSimulated[healingPlatform][player] = nil
end


function gameplayMechanicManager.IsPlatformBeingSimulated(player, healingPlatform)
    if typeof(player) ~= "Instance" then return end
    if typeof(healingPlatform) ~= "Instance" then return end

    return gameplayMechanicManager.PlatformsBeingSimulated[healingPlatform] and gameplayMechanicManager.PlatformsBeingSimulated[healingPlatform][player]
end


--
return gameplayMechanicManager