-- Variables
local gameplayMechanicManager = {}
gameplayMechanicManager.Remotes = {}
gameplayMechanicManager.PlatformsBeingSimulated = {}

local coreModule = require(script:FindFirstAncestor("Core"))
local utilitiesLibrary = require(coreModule.Shared.GetObject("Libraries.Utilities"))

-- Initialize
function gameplayMechanicManager.Initialize()
    if not workspace.Map.Gameplay.PlatformerMechanics:FindFirstChild("JumpPlatforms") then return end

    -- Setting up the JumpPlatforms to be functional.
    for _, jumpPlatformContainer in next, workspace.Map.Gameplay.PlatformerMechanics.JumpPlatforms:GetChildren() do
        for _, jumpPlatform in next, jumpPlatformContainer:GetChildren() do

            -- jumpPlatform should be a BasePart that they can touch.
            if jumpPlatform:IsA("BasePart") then
                jumpPlatform.Touched:Connect(function(hit)
                    local player = game:GetService("Players"):GetPlayerFromCharacter(hit.Parent)
                    if not utilitiesLibrary.IsPlayerAlive(player) then return end
                    if gameplayMechanicManager.IsPlatformBeingSimulated(player, jumpPlatform) then return end

                    gameplayMechanicManager.SimulateJumpPlatform(player, jumpPlatform)
                end)
            end
        end
    end

    gameplayMechanicManager.Remotes.PlaySoundEffect = coreModule.Shared.GetObject("//Remotes.Gameplay.Miscellaneous.PlaySoundEffect")
end


-- Methods
function gameplayMechanicManager.SimulateJumpPlatform(player, jumpPlatform)
    if not utilitiesLibrary.IsPlayerAlive(player) then return end
    if typeof(jumpPlatform) ~= "Instance" then return end
    if gameplayMechanicManager.IsPlatformBeingSimulated(player, jumpPlatform) then return end

    gameplayMechanicManager.PlatformsBeingSimulated[jumpPlatform] = gameplayMechanicManager.PlatformsBeingSimulated[jumpPlatform] or {}
    gameplayMechanicManager.PlatformsBeingSimulated[jumpPlatform][player] = true

    -- Make them jump once then revert.
    local humanoid = player.Character.Humanoid
    local previousJumpHeight = humanoid.JumpHeight
    local goalJumpHeight = jumpPlatform:GetAttribute("JumpHeight") or script:GetAttribute("DefaultJumpHeight") or 20

    humanoid.JumpHeight = goalJumpHeight
    humanoid.Jump = true

    gameplayMechanicManager.Remotes.PlaySoundEffect:FireClient(player, "JumpPowerup", {Parent = jumpPlatform})

    -- Revert it; The time is ambigious but is just some delay to give physics time to actually let them jump.
    delay(0.5, function()
        if not gameplayMechanicManager.IsPlatformBeingSimulated(player, jumpPlatform) then return end
        if not utilitiesLibrary.IsPlayerAlive(player) then
            gameplayMechanicManager.PlatformsBeingSimulated[jumpPlatform][player] = nil
            return
        end

        if player.Character.Humanoid.JumpHeight ~= goalJumpHeight then
            gameplayMechanicManager.PlatformsBeingSimulated[jumpPlatform][player] = nil
            return
        end

        player.Character.Humanoid.JumpHeight = previousJumpHeight
        task.wait(0.5)
        gameplayMechanicManager.PlatformsBeingSimulated[jumpPlatform][player] = nil
    end)
end


function gameplayMechanicManager.IsPlatformBeingSimulated(player, jumpPlatform)
    if typeof(player) ~= "Instance" then return end
    if typeof(jumpPlatform) ~= "Instance" then return end

    return gameplayMechanicManager.PlatformsBeingSimulated[jumpPlatform] and gameplayMechanicManager.PlatformsBeingSimulated[jumpPlatform][player]
end


--
return gameplayMechanicManager