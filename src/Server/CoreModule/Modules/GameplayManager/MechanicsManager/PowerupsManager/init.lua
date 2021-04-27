-- Variables
local powerupsManager = {}
powerupsManager.PowerupsUpdated = Instance.new("BindableEvent")
powerupsManager.PowerupInformation = {}
powerupsManager.Remotes = {}

local coreModule = require(script:FindFirstAncestor("CoreModule"))
local utilitiesLibrary = require(coreModule.Shared.GetObject("Libraries.Utilities"))

-- Initialize
function powerupsManager.Initialize()
    if not workspace.Map.Gameplay.PlatformerMechanics:FindFirstChild("Powerups") then return end

    -- Setup + loading modules.
    powerupsManager.SetupPowerups()
    coreModule.LoadModule("/Ghost")
    coreModule.LoadModule("/Forcefield")
    coreModule.LoadModule("/Paint")
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
    powerupsManager.Remotes.PowerupInformationUpdated = coreModule.Shared.GetObject("//Remotes.Gameplay.Miscellaneous.PowerupInformationUpdated")

    -- Let's start this long process of making them functional.
    for _, powerupContainer in next, workspace.Map.Gameplay.PlatformerMechanics.Powerups:GetChildren() do
        for _, powerupPlatform in next, powerupContainer:GetChildren() do
            if script:FindFirstChild(powerupContainer.Name) then

                -- Some platforms are just the BasePart and some are a model with a PrimaryPart.
                if (powerupPlatform:IsA("Model") and powerupPlatform.PrimaryPart) or powerupPlatform:IsA("BasePart") then
                    local powerupPlatformHitbox = (powerupPlatform:IsA("Model") and powerupPlatform.PrimaryPart) or powerupPlatform
                    
                    powerupPlatformHitbox.Touched:Connect(function(hit)
                        local player = coreModule.Services.Players:GetPlayerFromCharacter(hit.Parent)

                        -- We have to make sure they're valid and within a reasonable distance from the hitbox.
                        if not utilitiesLibrary.IsPlayerAlive(player) then return end
                        if player:DistanceFromCharacter(teleportationManager.GetSeamlessCFrameAboveBasePart(player, powerupPlatformHitbox).Position) > 25 then return end

                        -- You can reapply powerups but we want to add this so they don't spam and take up a lot of excessive resources.
                        if powerupsManager.GetPowerupInformation(player, powerupContainer.Name) and os.clock() - powerupsManager.GetPowerupInformation(player, powerupContainer.Name).Start < 1 then return end

                        -- Do we want to reset this powerup?
                        if not powerupPlatform:GetAttribute("Reset") then
                            powerupsManager.PowerupInformation[player] = powerupsManager.PowerupInformation[player] or {}
                            powerupsManager.PowerupInformation[player][powerupContainer.Name] = {
                                Start = os.clock(),
                                Duration = powerupPlatform:GetAttribute("Duration") or script:GetAttribute("DefaultDuration") or 30,
                                IsFresh = powerupsManager.GetPowerupInformation(player, powerupContainer.Name) == nil
                            }

                            coreModule.Services.CollectionService:AddTag(player.Character, powerupContainer.Name)
                            powerupsManager.Remotes.PowerupInformationUpdated:FireClient(player, powerupContainer.Name, powerupsManager.GetPowerupInformation(player))
                            powerupsManager.Remotes.PlaySoundEffect:FireClient(player, powerupContainer.Name.."Powerup")
                            powerupsManager.ApplyPowerup(player, powerupContainer.Name, powerupPlatform)
                            
                        -- We do want to reset it.
                        else
                            powerupsManager.RemovePowerup(player, powerupContainer.Name)
                        end
                    end)
                end
            end
        end
    end
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
            repeat coreModule.Services.RunService.Stepped:Wait()
            until
            not utilitiesLibrary.IsPlayerAlive(player)
            or not coreModule.Services.CollectionService:HasTag(player.Character, powerupName)
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
    if utilitiesLibrary.IsPlayerAlive(player) then coreModule.Services.CollectionService:RemoveTag(player.Character, powerupName) end
    if powerupsManager.PowerupInformation[player] then powerupsManager.PowerupInformation[player][powerupName] = nil end
    powerupsManager.Remotes.PowerupInformationUpdated:FireClient(player, powerupName, powerupsManager.PowerupInformation[player])
    powerupsManager.Remotes.PlaySoundEffect:FireClient(player, powerupName.."Powerup")
end


function powerupsManager.RemoveAllPowerups(player)
    powerupsManager.PowerupInformation[player] = nil
    powerupsManager.Remotes.PowerupInformationUpdated:FireClient(player, nil, powerupsManager.PowerupInformation[player])
end


--
return powerupsManager