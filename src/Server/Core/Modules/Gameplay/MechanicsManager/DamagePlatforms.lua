local collectionService: CollectionService = game:GetService("CollectionService")
local players: Players = game:GetService("Players")

local coreModule = require(script:FindFirstAncestor("Core"))
local teleportationManager = require(coreModule.GetObject("Modules.Gameplay.MechanicsManager.TeleportationManager"))
local respawnPlatformManager = require(coreModule.GetObject("Modules.Gameplay.MechanicsManager.TeleportationManager.RespawnPlatforms"))
local playerUtilities = require(coreModule.Shared.GetObject("Libraries.Utilities.PlayerUtilities"))
local spatialQueryUtilities = require(coreModule.Shared.GetObject("Libraries.Utilities.SpatialQueryUtilities"))
local sharedConstants = require(coreModule.Shared.GetObject("Libraries.SharedConstants"))

local poisonParticleEmitter: ParticleEmitter = coreModule.Shared.GetObject("//Assets.Objects.ParticleEmitters.Poison")
local poisonGlowParticleEmitter: ParticleEmitter = coreModule.Shared.GetObject("//Assets.Objects.ParticleEmitters.PoisonGlow")
local playSoundEffectRemote: RemoteEvent = coreModule.Shared.GetObject("//Remotes.Gameplay.Miscellaneous.PlaySoundEffect")

local ThisMechanicManager = {}
ThisMechanicManager.ActivePlatforms = {}

-- Initialize
function ThisMechanicManager.Initialize()
    if not workspace.Map.Gameplay.PlatformerMechanics:FindFirstChild("DamagePlatforms") then return end

    -- Setting up this platform to be functional.
    for _, platformContainer: Instance in next, workspace.Map.Gameplay.PlatformerMechanics.DamagePlatforms:GetChildren() do
        for _, thisPlatform: Instance in next, platformContainer:GetChildren() do

            -- thisPlatform should be a BasePart that they can touch.
            if thisPlatform:IsA("BasePart") then
                thisPlatform.Touched:Connect(function(hit: BasePart)

                    local player: Player? = players:GetPlayerFromCharacter(hit.Parent)
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
    if collectionService:HasTag(player.Character, "Forcefield") then return end
    if ThisMechanicManager.IsMechanicEffectActiveFor(player, thisPlatform) then return end
    if thisPlatform:GetAttribute("IsPoison") and collectionService:HasTag(player.Character, "Poisoned") then return end
    if not playerUtilities.IsPlayerAlive(player) then
        ThisMechanicManager.SetMechanicEffectActiveFor(player, thisPlatform, false)
        return
    end

    -- We can apply it!
    ThisMechanicManager.SetMechanicEffectActiveFor(player, thisPlatform, true)

    -- How do we apply the damage?
    if thisPlatform:GetAttribute("IsPoison") then
        ThisMechanicManager._ApplyPoisonEffect(player, thisPlatform)
    else
        ThisMechanicManager._ApplyInstantDamageEffect(player, thisPlatform)
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

-- Applies the poison effects and handles all logic.
function ThisMechanicManager._ApplyPoisonEffect(player: Player, thisPlatform: Instance)

    -- We give them the tag 'Poisoned' so the system can easily track it.
    -- It also has the benefit of being able to be removed by TeleportationManager.RestoreConditions.
    collectionService:AddTag(player.Character, "Poisoned")

    local humanoid: Humanoid = player.Character.Humanoid
    local damageAmount: number = thisPlatform:GetAttribute("Damage") or sharedConstants.MECHANICS.DAMAGE_PLATFORM_DEFAULT_DAMAGE
    local thisDuration: number = thisPlatform:GetAttribute("Duration") or sharedConstants.MECHANICS.ANY_PLATFORM_DEFAULT_DURATION

    local clonedPosionParticleEmitter: ParticleEmitter = poisonParticleEmitter:Clone()
    local clonedPoisonGlowParticleEmitter: ParticleEmitter = poisonGlowParticleEmitter:Clone()
    clonedPosionParticleEmitter.Parent = player.Character.Head
    clonedPoisonGlowParticleEmitter.Parent = player.Character.HumanoidRootPart

    -- We want to damagee them a certain amount of times.
    -- The duration is how many seconds the poison process will take.
    for _ = 1, math.max(thisDuration, 1) do

        if not playerUtilities.IsPlayerAlive(player) then break end
        if not collectionService:HasTag(player.Character, "Poisoned") then break end
        playSoundEffectRemote:FireClient(player, "PoisonDamage")

        -- If they can't survive this we want to teleport them back to the start.
        if humanoid.Health - damageAmount > 0 then
            humanoid:TakeDamage(damageAmount)
        else
            respawnPlatformManager.RegisterRespawnOf(player)
            teleportationManager.TeleportPlayer(player)
            break
        end

        task.wait(math.min(1, thisDuration))
    end

    -- We want to get rid of our particle emitters and the `Poisoned` tag.
    if playerUtilities.IsPlayerAlive(player) then
        clonedPosionParticleEmitter.Enabled = false
        clonedPoisonGlowParticleEmitter.Enabled = false
        collectionService:RemoveTag(player.Character, "Poisoned")

        task.delay(1, function()
            clonedPosionParticleEmitter:Destroy()
            clonedPoisonGlowParticleEmitter:Destroy()
        end)
    end
end

-- Applies the instance damage effect and handles all logic.
function ThisMechanicManager._ApplyInstantDamageEffect(player: Player, thisPlatform: Instance)
    while true do

        -- We need to make sure we can keep doing damage.
        if not playerUtilities.IsPlayerAlive(player) then return end
        if collectionService:HasTag(player.Character, "Forcefield") then return end
        if not table.find(spatialQueryUtilities.GetPlayersWithinParts(thisPlatform), player) then return end

        -- We can do this so let's go forward.
        local humanoid: Humanoid = player.Character.Humanoid
        local damageAmount: number = thisPlatform:GetAttribute("Damage") or sharedConstants.MECHANICS.DAMAGE_PLATFORM_DEFAULT_DAMAGE
        local thisDuration: number = thisPlatform:GetAttribute("Duration") or sharedConstants.MECHANICS.ANY_PLATFORM_DEFAULT_DURATION

        playSoundEffectRemote:FireClient(player, "InstantDamage")

        -- If they can't survive this we want to teleport them back to the start.
        if humanoid.Health - damageAmount > 0 then
            humanoid:TakeDamage(damageAmount)
        else
            respawnPlatformManager.RegisterRespawnOf(player)
            teleportationManager.TeleportPlayer(player)
            break
        end

        task.wait(thisDuration)
    end
end

return ThisMechanicManager
