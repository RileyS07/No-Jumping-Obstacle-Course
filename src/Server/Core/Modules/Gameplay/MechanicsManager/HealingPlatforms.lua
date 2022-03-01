local coreModule = require(script:FindFirstAncestor("Core"))
local playerUtilities = require(coreModule.Shared.GetObject("Libraries.Utilities.PlayerUtilities"))
local sharedConstants = require(coreModule.Shared.GetObject("Libraries.SharedConstants"))

local playSoundEffectRemote: RemoteEvent = coreModule.Shared.GetObject("//Remotes.Gameplay.Miscellaneous.PlaySoundEffect")

local ThisMechanicManager = {}
ThisMechanicManager.ActivePlatforms = {}

-- Initialize
function ThisMechanicManager.Initialize()
    if not workspace.Map.Gameplay.PlatformerMechanics:FindFirstChild("HealingPlatforms") then return end

    -- Setting up this platform to be functional.
    for _, platformContainer: Instance in next, workspace.Map.Gameplay.PlatformerMechanics.HealingPlatforms:GetChildren() do
        for _, thisPlatform: Instance in next, platformContainer:GetChildren() do

            -- thisPlatform should be a Model with a PrimaryPart that they can touch.
            if thisPlatform:IsA("Model") and thisPlatform.PrimaryPart then
                thisPlatform.PrimaryPart.Touched:Connect(function(hit: BasePart)

                    local player: Player? = game:GetService("Players"):GetPlayerFromCharacter(hit.Parent)
                    if not playerUtilities.IsPlayerAlive(player) then return end
                    if ThisMechanicManager.IsMechanicEffectActiveFor(player, thisPlatform) then return end

                    task.spawn(ThisMechanicManager.StartMechanic, player :: Player, thisPlatform)
                end)
            end
        end
    end
end

-- Activates the effects that this platform does.
function ThisMechanicManager.StartMechanic(player: Player, thisPlatform: Instance)

    -- We need to make sure that we can apply the effect.
    if player.Character.Humanoid.Health == player.Character.Humanoid.MaxHealth then return end
    if ThisMechanicManager.IsMechanicEffectActiveFor(player, thisPlatform) then return end
    if not playerUtilities.IsPlayerAlive(player) then
        ThisMechanicManager.SetMechanicEffectActiveFor(player, thisPlatform, false)
        return
    end

    -- We can apply it!
    ThisMechanicManager.SetMechanicEffectActiveFor(player, thisPlatform, true)
    playSoundEffectRemote:FireClient(player, "Healing", {Parent = thisPlatform.PrimaryPart})

    local humanoid: Humanoid = player.Character.Humanoid
    local thisDuration: number = thisPlatform:GetAttribute("Duration") or sharedConstants.MECHANICS.ANY_PLATFORM_DEFAULT_DURATION

    -- We want to heal them a certain amount of times.
    -- The duration is how many seconds the healing process will take.
    for _ = 1, math.max(thisDuration, 1) do

        if not playerUtilities.IsPlayerAlive(player) then break end
        if player.Character.Humanoid.Health == player.Character.Humanoid.MaxHealth then break end

        -- Updating their health!
        humanoid.Health = math.clamp(
            humanoid.Health + (thisPlatform:GetAttribute("Amount") or sharedConstants.MECHANICS.HEALING_PLATFORM_DEFAULT_HEAL_AMOUNT),
            humanoid.Health,
            humanoid.MaxHealth
        )

        -- Waiting till the next step.
        task.wait(math.min(1, thisDuration))
    end

    task.wait(1)
    ThisMechanicManager.SetMechanicEffectActiveFor(player, thisPlatform, false)
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
