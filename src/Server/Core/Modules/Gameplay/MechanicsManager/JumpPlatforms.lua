local coreModule = require(script:FindFirstAncestor("Core"))
local playerUtilities = require(coreModule.Shared.GetObject("Libraries.Utilities.PlayerUtilities"))
local spatialQueryUtilities = require(coreModule.Shared.GetObject("Libraries.Utilities.SpatialQueryUtilities"))
local sharedConstants = require(coreModule.Shared.GetObject("Libraries.SharedConstants"))

local playSoundEffectRemote: RemoteEvent = coreModule.Shared.GetObject("//Remotes.Gameplay.Miscellaneous.PlaySoundEffect")

local ThisMechanicManager = {}
ThisMechanicManager.ActivePlatforms = {}

-- Initialize
function ThisMechanicManager.Initialize()
    if not workspace.Map.Gameplay.PlatformerMechanics:FindFirstChild("JumpPlatforms") then return end

    -- Setting up this platform to be functional.
    for _, platformContainer: Instance in next, workspace.Map.Gameplay.PlatformerMechanics.JumpPlatforms:GetChildren() do
        for _, thisPlatform: Instance in next, platformContainer:GetChildren() do

            -- thisPlatform should be a BasePart that they can touch.
            if thisPlatform:IsA("BasePart") then

                -- We want to create a loop to catch any players within this box.
                -- This is to avoid a bug where if you land on it before the debounce is finished it won't jump you again.
                task.spawn(function()
                    while true do

                        debug.profilebegin("JumpPlatform")

                        -- We want to check for players every frame.
                        for _, player: Player in next, spatialQueryUtilities.GetPlayersWithinBox(thisPlatform.CFrame, thisPlatform.Size) do
                            if not playerUtilities.IsPlayerAlive(player) then continue end
                            if ThisMechanicManager.IsMechanicEffectActiveFor(player, thisPlatform) then continue end

                            task.spawn(ThisMechanicManager.StartMechanic, player :: Player, thisPlatform)
                        end

                        debug.profileend()
                        task.wait()
                    end
                end)
            end
        end
    end
end

-- Activates the effects that this platform does.
function ThisMechanicManager.StartMechanic(player: Player, thisPlatform: Instance)

    -- We need to make sure that we can apply the effect.
    if ThisMechanicManager.IsMechanicEffectActiveFor(player, thisPlatform) then return end
    if not playerUtilities.IsPlayerAlive(player) then
        ThisMechanicManager.SetMechanicEffectActiveFor(player, thisPlatform, false)
        return
    end

    -- We can apply it!
    ThisMechanicManager.SetMechanicEffectActiveFor(player, thisPlatform, true)
    playSoundEffectRemote:FireClient(player, "JumpPowerup", {Parent = thisPlatform})

    -- Make them jump once then revert.
    local humanoid: Humanoid = player.Character.Humanoid
    local previousJumpHeight: number = humanoid.JumpHeight
    local goalJumpHeight: number = thisPlatform:GetAttribute("JumpHeight") or sharedConstants.MECHANICS.JUMP_PLATFORM_DEFAULT_JUMP_HEIGHT

    humanoid.JumpHeight = goalJumpHeight
    humanoid.Jump = true

    -- Revert it; The time is ambigious but is just some delay to give physics time to actually let them jump.
    task.delay(0.5, function()
        if not ThisMechanicManager.IsMechanicEffectActiveFor(player, thisPlatform) then return end
        if not playerUtilities.IsPlayerAlive(player) then
            ThisMechanicManager.SetMechanicEffectActiveFor(player, thisPlatform, false)
            return
        end

        if player.Character.Humanoid.JumpHeight ~= goalJumpHeight then
            ThisMechanicManager.SetMechanicEffectActiveFor(player, thisPlatform, false)
            return
        end

        player.Character.Humanoid.JumpHeight = previousJumpHeight
        task.delay(0.5, ThisMechanicManager.SetMechanicEffectActiveFor, player, thisPlatform, false)
    end)
end

-- Returns whether or not that this player has an active effect for this platform.
function ThisMechanicManager.IsMechanicEffectActiveFor(player: Player, thisPlatform: Instance)
    return ThisMechanicManager.ActivePlatforms[thisPlatform] and ThisMechanicManager.ActivePlatforms[thisPlatform][player]
end

-- Sets the active value for this mechanic effect for this platform.
function ThisMechanicManager.SetMechanicEffectActiveFor(player: Player, thisPlatform: Instance, isActive: boolean)
    ThisMechanicManager.ActivePlatforms[thisPlatform] = ThisMechanicManager.ActivePlatforms[thisPlatform] or {}
    ThisMechanicManager.ActivePlatforms[thisPlatform][player] = if isActive then true else nil
end

return ThisMechanicManager
