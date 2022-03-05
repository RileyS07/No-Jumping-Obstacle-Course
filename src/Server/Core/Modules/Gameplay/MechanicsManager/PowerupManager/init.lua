local collectionService: CollectionService = game:GetService("CollectionService")
local players: Players = game:GetService("Players")

local coreModule = require(script:FindFirstAncestor("Core"))
local playerUtilities = require(coreModule.Shared.GetObject("Libraries.Utilities.PlayerUtilities"))
local spatialQueryUtilities = require(coreModule.Shared.GetObject("Libraries.Utilities.SpatialQueryUtilities"))
local sharedConstants = require(coreModule.Shared.GetObject("Libraries.SharedConstants"))
local signal = require(coreModule.Shared.GetObject("Libraries.Signal"))

local playSoundEffectRemote: RemoteEvent = coreModule.Shared.GetObject("//Remotes.PlaySoundEffect")
local timerInformationUpdatedRemote: RemoteEvent = coreModule.Shared.GetObject("//Remotes.Gameplay.Miscellaneous.TimerInformationUpdated")

local PowerupManager = {}
PowerupManager.PowerupInformationUpdated = signal.new()
PowerupManager.Information = {}

-- Initialize
function PowerupManager.Initialize()
    if not workspace.Map.Gameplay.PlatformerMechanics:FindFirstChild("Powerups") then return end

    -- Setting up the powerup handler before loading the powerups themselves.
    PowerupManager._SetupPowerups()
    coreModule.LoadModule("/")

    -- We listen to this for easier client communication.
    PowerupManager.PowerupInformationUpdated:Connect(function(player: Player)
        timerInformationUpdatedRemote:FireClient(player, PowerupManager.GetPowerupInformation(player))
    end)
end

-- This function returns the powerup information of the given user.
-- If the powerupName is not nil this function will return all of the user's information.
function PowerupManager.GetPowerupInformation(player: Player, powerupName: string?) : {}?

    -- We don't want this to be nil.
    PowerupManager.Information[player] = PowerupManager.Information[player] or {}

    if typeof(powerupName) == "string" then
        return PowerupManager.Information[player] and PowerupManager.Information[player][powerupName]
    else
        return PowerupManager.Information[player]
    end
end

-- Updates the powerup information for this user.
function PowerupManager.UpdatePowerupInformation(player: Player, powerupName: string, newInformation: {})
    PowerupManager.GetPowerupInformation(player)[powerupName] = {
        Start = newInformation.Start or os.clock(),
        Duration = newInformation.Duration or sharedConstants.MECHANICS.ANY_POWERUP_DEFAULT_DURATION,
        IsFresh = newInformation.IsFresh,
        PlatformName = newInformation.PlatformName,

        -- Specific information.
        Color = newInformation.Color,
    }

    PowerupManager.PowerupInformationUpdated:Fire(player)
end

-- Attempts to apply a powerup, returns whether or not it was successful.
function PowerupManager.ApplyPowerup(player: Player, powerupName: string, thisPowerup: Instance) : boolean

    -- We need to make sure we can actually apply the powerup.
    if not playerUtilities.IsPlayerAlive(player) then return false end
    if not script:FindFirstChild(powerupName) then return false end
    if not PowerupManager.GetPowerupInformation(player, powerupName) then return false end

    local thisPowerupInformation: {} = PowerupManager.GetPowerupInformation(player, powerupName)

    -- Is it fresh? Is it the first new time that this powerup has been applied to this player?
    if thisPowerupInformation.IsFresh then
        task.spawn(function()

            -- We want to yield till the powerup should be removed.
            repeat
                task.wait()
            until PowerupManager._ShouldRemovePowerup(player, powerupName)

            -- Remove it.
            PowerupManager.RemovePowerup(player, powerupName)
        end)
    end

    -- Try to apply the powerup.
    require(script:FindFirstChild(powerupName)).Apply(player, thisPowerup)
    return true
end

-- Removes a single powerup from the user if possible.
-- Returns whether or not it was successful.
function PowerupManager.RemovePowerup(player: Player, powerupName: string) : boolean

    -- Time to start the removal process.
    if playerUtilities.IsPlayerAlive(player) then
        collectionService:RemoveTag(player.Character, powerupName)
    else
        return false
    end

    if PowerupManager.GetPowerupInformation(player) then
        PowerupManager.GetPowerupInformation(player)[powerupName] = nil
    end

    PowerupManager.PowerupInformationUpdated:Fire(player)
    playSoundEffectRemote:FireClient(player, powerupName .. "PowerupRemoved")
end

-- Removes all powerups from this user and updates them.
function PowerupManager.RemoveAllPowerups(player: Player)
    PowerupManager.Information[player] = nil
    PowerupManager.PowerupInformationUpdated:Fire(player)
end

-- Sets the Touched listeners for all of the powerups and handles the interactions.
function PowerupManager._SetupPowerups()

    -- Setting up these platform to be functional.
    for _, powerupContainer: Instance in next, workspace.Map.Gameplay.PlatformerMechanics.Powerups:GetChildren() do
        for _, thisPowerup: Instance in next, powerupContainer:GetChildren() do

            -- We need to make sure that the handler for this powerup exists.
            if not script:FindFirstChild(powerupContainer.Name) then
                continue
            end

            -- Now we need to determine the hitbox for this platform.
            -- Some are a Model with a PrimaryPart and some are just a BasePart.
            local thisHitbox: BasePart? = thisPowerup:IsA("Model") and thisPowerup.PrimaryPart or thisPowerup

            if not thisHitbox or not thisHitbox:IsA("BasePart") then
                continue
            end

            -- We have confirmed everything is valid so we can now go from here.
            (thisHitbox :: BasePart).Touched:Connect(function(hit: BasePart)

                local player: Player? = players:GetPlayerFromCharacter(hit.Parent)

                -- We have to make sure they're alive and still within the powerup box.
                -- The last part is needed because of a bug where if a player touches a powerup
                -- and then teleports it would apply the powerup where it's not meant to be.
                if not playerUtilities.IsPlayerAlive(player) then return end
                if not thisPowerup:GetAttribute("Reset") and not PowerupManager._IsPlayerWithinPowerupRange(player, thisPowerup) then
                    return
                end

                -- You can reapply powerups but we want to add a little delay as to not stress the system.
                if PowerupManager.GetPowerupInformation(player, powerupContainer.Name) then

                    local thisPowerupInformation: {} = PowerupManager.GetPowerupInformation(player, powerupContainer.Name)

                    if os.clock() - thisPowerupInformation.Start < sharedConstants.MECHANICS.ANY_POWERUP_REAPPLICATION_DELAY then
                        return
                    end
                end

                -- We've made it to this point so we're either apply or removing this powerup.
                if thisPowerup:GetAttribute("Reset") then
                    PowerupManager.RemovePowerup(player, powerupContainer.Name)
                else

                    PowerupManager.UpdatePowerupInformation(player, powerupContainer.Name, {
                        Start = os.clock(),
                        Duration = thisPowerup:GetAttribute("Duration") or sharedConstants.MECHANICS.ANY_POWERUP_DEFAULT_DURATION,
                        IsFresh = PowerupManager.GetPowerupInformation(player, powerupContainer.Name) == nil,
                        PlatformName = thisPowerup.Name,
                        Color = thisPowerup:GetAttribute("Color")
                    })

                    collectionService:AddTag(player.Character, powerupContainer.Name)
                    playSoundEffectRemote:FireClient(player, powerupContainer.Name .. "Powerup")
                    PowerupManager.ApplyPowerup(player, powerupContainer.Name, thisPowerup)
                end
            end)
        end
    end
end

-- Determines if the player is within a certain area of the powerup.
function PowerupManager._IsPlayerWithinPowerupRange(player: Player, thisPowerup: Instance) : boolean
    if not playerUtilities.IsPlayerAlive(player) then return false end

    -- Determining where the center of the box is as well as the size.
    local cframe: CFrame, size : Vector3 = CFrame.new(), Vector3.new()

    if thisPowerup:IsA("Model") then
        cframe, size = (thisPowerup :: Model):GetBoundingBox()
    else
        cframe, size = thisPowerup.CFrame, thisPowerup.Size
    end

    -- We want to increase the hitbox a little to make it easier to touch.
    local playersWithinBox: {Player} = spatialQueryUtilities.GetPlayersWithinBox(
        cframe,
        size * sharedConstants.MECHANICS.ANY_POWERUP_HIT_BOX_SIZE_MULTIPLIER,
        spatialQueryUtilities.CreateCharacterWhitelistOverlapParams()
    )

    return table.find(playersWithinBox, player) ~= nil
end

-- Returns whether or not that the powerup should still be active.
function PowerupManager._ShouldRemovePowerup(player: Player, powerupName: string) : boolean

    local thisPowerupInformation: {} = PowerupManager.GetPowerupInformation(player, powerupName)

    return
        not playerUtilities.IsPlayerAlive(player)
        or not game:GetService("CollectionService"):HasTag(player.Character, powerupName)
        or not thisPowerupInformation
        or os.clock() - thisPowerupInformation.Start >= thisPowerupInformation.Duration
end

return PowerupManager
