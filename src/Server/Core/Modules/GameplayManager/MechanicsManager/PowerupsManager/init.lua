-- Variables
local powerupsManager = {}
powerupsManager.PowerupsUpdated = Instance.new("BindableEvent")
powerupsManager.PowerupInformation = {}
powerupsManager.Remotes = {}

local coreModule = require(script:FindFirstAncestor("Core"))
local utilitiesLibrary = require(coreModule.Shared.GetObject("Libraries.Utilities"))

-- Initialize
function powerupsManager.Initialize()
    if not workspace.Map.Gameplay.PlatformerMechanics:FindFirstChild("Powerups") then return end

    -- Setup + loading modules.
    powerupsManager.SetupPowerups()
    coreModule.LoadModule("/Ghost")
    coreModule.LoadModule("/Gravity")
    coreModule.LoadModule("/Forcefield")
    coreModule.LoadModule("/Jump")
    coreModule.LoadModule("/Paint")
    coreModule.LoadModule("/Radar")
    coreModule.LoadModule("/Speed")
end


-- Methods
function powerupsManager.GetPowerupInformation(player, powerupName)
    if not utilitiesLibrary.IsPlayerValid(player) then return end

    -- If you pass a string it's a specific one, if it's nil it's all.
    if typeof(powerupName) == "string" then
        return powerupsManager.PowerupInformation[player] and powerupsManager.PowerupInformation[player][powerupName]
    else
        return powerupsManager.PowerupInformation[player]
    end
end


-- Private methods
function powerupsManager.SetupPowerups()
    local teleportationManager = require(coreModule.GetObject("Modules.GameplayManager.MechanicsManager.TeleportationManager"))
    powerupsManager.Remotes.PlaySoundEffect = coreModule.Shared.GetObject("//Remotes.Gameplay.Miscellaneous.PlaySoundEffect")
    powerupsManager.Remotes.TimerInformationUpdated = coreModule.Shared.GetObject("//Remotes.Gameplay.Miscellaneous.TimerInformationUpdated")

    -- Let's start this long process of making them functional.
    for _, powerupContainer in next, workspace.Map.Gameplay.PlatformerMechanics.Powerups:GetChildren() do
        for _, powerupPlatform in next, powerupContainer:GetChildren() do
            if script:FindFirstChild(powerupContainer.Name) then

                -- Some platforms are just the BasePart and some are a model with a PrimaryPart.
                if (powerupPlatform:IsA("Model") and powerupPlatform.PrimaryPart) or powerupPlatform:IsA("BasePart") then
                    local powerupPlatformHitbox = (powerupPlatform:IsA("Model") and powerupPlatform.PrimaryPart) or powerupPlatform

                    powerupPlatformHitbox.Touched:Connect(function(hit)
                        local player = game:GetService("Players"):GetPlayerFromCharacter(hit.Parent)
                        local maximumDistanceFromCenter: number = math.max(
                            math.max(math.max(powerupPlatformHitbox.Size.X, powerupPlatformHitbox.Size.Y), powerupPlatformHitbox.Size.Z),
                            30
                        )

                        -- We have to make sure they're valid and within a reasonable distance from the hitbox.
                        if not utilitiesLibrary.IsPlayerAlive(player) then return end
                        if player:DistanceFromCharacter(teleportationManager.GetSeamlessCFrameAboveBasePart(player, powerupPlatformHitbox).Position) > maximumDistanceFromCenter then return end

                        -- You can reapply powerups but we want to add this so they don't spam and take up a lot of excessive resources.
                        if powerupsManager.GetPowerupInformation(player, powerupContainer.Name) and os.clock() - powerupsManager.GetPowerupInformation(player, powerupContainer.Name).Start < 1 then return end

                        -- Do we want to reset this powerup?
                        if not powerupPlatform:GetAttribute("Reset") then
                            powerupsManager.UpdatePowerup(player, powerupContainer.Name, {
                                Start = os.clock(),
                                Duration = powerupPlatform:GetAttribute("Duration") or script:GetAttribute("DefaultDuration") or 30,
                                IsFresh = powerupsManager.GetPowerupInformation(player, powerupContainer.Name) == nil,
                                Color = powerupPlatform:GetAttribute("Color")
                            })

                            game:GetService("CollectionService"):AddTag(player.Character, powerupContainer.Name)
                            powerupsManager.Remotes.PlaySoundEffect:FireClient(player, powerupContainer.Name.."Powerup")
                            powerupsManager.ApplyPowerup(player, powerupContainer.Name, powerupPlatform)

                        -- We do want to reset it.
                        elseif powerupsManager.GetPowerupInformation(player, powerupContainer.Name) then
                            powerupsManager.RemovePowerup(player, powerupContainer.Name)
                        end
                    end)
                end
            end
        end
    end
end


function powerupsManager.UpdatePowerup(player, powerupName, powerupInformation)
    powerupsManager.PowerupInformation[player] = powerupsManager.PowerupInformation[player] or {}
    powerupsManager.PowerupInformation[player][powerupName] = powerupInformation
    powerupsManager.Remotes.TimerInformationUpdated:FireClient(player, powerupsManager.GetPowerupInformation(player))
end


function powerupsManager.ApplyPowerup(player, powerupName, powerupPlatform)
    if not utilitiesLibrary.IsPlayerAlive(player) then return end
    if typeof(powerupPlatform) ~= "Instance" then return end
    if typeof(powerupName) ~= "string" or not script:FindFirstChild(powerupName) then return end
    if not script:FindFirstChild(powerupName):IsA("ModuleScript") then return end
    if not powerupsManager.GetPowerupInformation(player, powerupName) then return end

    -- Is it fresh; Is it the first new time that this powerup has been applied to this player?
    if powerupsManager.GetPowerupInformation(player, powerupName).IsFresh then
        coroutine.wrap(function()

            -- Yield till we can proceed to remove the powerup.
            repeat game:GetService("RunService").Stepped:Wait()
            until
            not utilitiesLibrary.IsPlayerAlive(player)
            or not game:GetService("CollectionService"):HasTag(player.Character, powerupName)
            or not powerupsManager.GetPowerupInformation(player, powerupName)
            or os.clock() - powerupsManager.GetPowerupInformation(player, powerupName).Start >= powerupsManager.GetPowerupInformation(player, powerupName).Duration

            -- Remove it.
            powerupsManager.RemovePowerup(player, powerupName)
        end)()
    end

    -- Try to apply the powerup.
    pcall(function()
        require(script:FindFirstChild(powerupName)).Apply(player, powerupPlatform)
    end)
end


function powerupsManager.RemovePowerup(player, powerupName)
    if not utilitiesLibrary.IsPlayerValid(player) then return end
    if typeof(powerupName) ~= "string" then return end

    -- Time to start the removal process.
    if utilitiesLibrary.IsPlayerAlive(player) then
        game:GetService("CollectionService"):RemoveTag(player.Character, powerupName)
    end

    if powerupsManager.GetPowerupInformation(player) then
        powerupsManager.GetPowerupInformation(player)[powerupName] = nil
    end

    powerupsManager.Remotes.TimerInformationUpdated:FireClient(player, powerupsManager.GetPowerupInformation(player))
    powerupsManager.Remotes.PlaySoundEffect:FireClient(player, powerupName.."PowerupRemoved")
end


function powerupsManager.RemoveAllPowerups(player)
    powerupsManager.PowerupInformation[player] = nil
    powerupsManager.Remotes.TimerInformationUpdated:FireClient(player, powerupsManager.GetPowerupInformation(player))
end


--
return powerupsManager