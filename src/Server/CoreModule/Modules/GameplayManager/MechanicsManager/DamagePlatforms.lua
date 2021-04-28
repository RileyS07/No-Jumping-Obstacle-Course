-- Variables
local gameplayMechanicManager = {}
gameplayMechanicManager.Remotes = {}
gameplayMechanicManager.PlatformsBeingSimulated = {}
gameplayMechanicManager.ValidDamageTypes = { Poison = true, Instant = true }

local coreModule = require(script:FindFirstAncestor("CoreModule"))
local teleportationManager = require(coreModule.GetObject("Modules.GameplayManager.MechanicsManager.TeleportationManager"))
local utilitiesLibrary = require(coreModule.Shared.GetObject("Libraries.Utilities"))

-- Initialize
function gameplayMechanicManager.Initialize()
    if not workspace.Map.Gameplay.PlatformerMechanics:FindFirstChild("DamagePlatforms") then return end

    -- Setting up the DamagePlatforms to be functional.
    for _, damagePlatformContainer in next, workspace.Map.Gameplay.PlatformerMechanics.DamagePlatforms:GetChildren() do
        if gameplayMechanicManager.ValidDamageTypes[damagePlatformContainer.Name] then
            for _, damagePlatform in next, damagePlatformContainer:GetChildren() do

                -- The platform itself is what the players will touch to be damaged.
                if damagePlatform:IsA("BasePart") then
                    damagePlatform.Touched:Connect(function(hit)
                        local player = coreModule.Services.Players:GetPlayerFromCharacter(hit.Parent)
                        if not utilitiesLibrary.IsPlayerAlive(player) then return end
                        if gameplayMechanicManager.IsPlatformBeingSimulated(player, damagePlatform) then return end
                        
                        coroutine.wrap(gameplayMechanicManager.SimulateDamagePlatform)(player, damagePlatform)
                    end)
                end
            end
        end
    end

    gameplayMechanicManager.Remotes.PlaySoundEffect = coreModule.Shared.GetObject("//Remotes.Gameplay.Miscellaneous.PlaySoundEffect")
end


-- Methods
function gameplayMechanicManager.SimulateDamagePlatform(player, damagePlatform)
    if not utilitiesLibrary.IsPlayerAlive(player) then return end
    if typeof(damagePlatform) ~= "Instance" then return end
    if gameplayMechanicManager.IsPlatformBeingSimulated(player, damagePlatform) then return end
    if not gameplayMechanicManager.ValidDamageTypes[damagePlatform.Parent.Name] then return end
    if coreModule.Services.CollectionService:HasTag(player.Character, "Forcefield") then return end

    gameplayMechanicManager.PlatformsBeingSimulated[damagePlatform] = gameplayMechanicManager.PlatformsBeingSimulated[damagePlatform] or {}
    gameplayMechanicManager.PlatformsBeingSimulated[damagePlatform][player] = true

    -- Damage time.
    gameplayMechanicManager.Remotes.PlaySoundEffect:FireClient(player, damagePlatform.Parent.Name.."Damage", {Parent = damagePlatform})
    
    -- How do we apply the damage?
    if damagePlatform.Parent.Name == "Poison" then
        coreModule.Services.CollectionService:AddTag(player.Character, "Poisoned")

        for index = 1, (damagePlatform:GetAttribute("Duration") or script:GetAttribute("DefaultDuration") or 1)*(damagePlatform:GetAttribute("Speed") or script:GetAttribute("DefaultSpeed") or 1) do
            if not utilitiesLibrary.IsPlayerAlive(player) then break end
            if not coreModule.Services.CollectionService:HasTag(player.Character, "Poisoned") then break end

            -- Can they survive this?
            local damageAmount = damagePlatform:GetAttribute("Damage") or script:GetAttribute("DefaultDamage") or 10
            if player.Character.Humanoid.Health - damageAmount > 0 then
                player.Character.Humanoid:TakeDamage(damageAmount)
            else
                teleportationManager.TeleportPlayer(player)
                break
            end

            wait(1/(damagePlatform:GetAttribute("Speed") or script:GetAttribute("DefaultSpeed") or 1))
        end

        coreModule.Services.CollectionService:RemoveTag(player.Character, "Poisoned")

    -- Instant damage is a little more complicated.
    elseif damagePlatform.Parent.Name == "Instant" then
        while true do
            if not utilitiesLibrary.IsPlayerAlive(player) then break end
		    if coreModule.Services.CollectionService:HasTag(player.Character, "Forcefield") then break end
            if not gameplayMechanicManager.IsInstancesDescendantsInArray(player.Character, damagePlatform:GetTouchingParts()) then break end

            -- Can they survive this?
            local damageAmount = damagePlatform:GetAttribute("Damage") or script:GetAttribute("DefaultDamage") or 10
            if player.Character.Humanoid.Health - damageAmount > 0 then
                player.Character.Humanoid:TakeDamage(damageAmount)
            else
                teleportationManager.TeleportPlayer(player)
                break
            end

            wait(1/(damagePlatform:GetAttribute("Speed") or script:GetAttribute("DefaultSpeed") or 1))
        end
    end

    wait(script:GetAttribute("Delay") or 1)
    gameplayMechanicManager.PlatformsBeingSimulated[damagePlatform][player] = nil
end


function gameplayMechanicManager.IsPlatformBeingSimulated(player, damagePlatform)
    if typeof(player) ~= "Instance" then return end
    if typeof(damagePlatform) ~= "Instance" then return end
    
    return gameplayMechanicManager.PlatformsBeingSimulated[damagePlatform] and gameplayMechanicManager.PlatformsBeingSimulated[damagePlatform][player]
end


-- Private Methods
function gameplayMechanicManager.IsInstancesDescendantsInArray(instanceObject, array)
    if typeof(instanceObject) ~= "Instance" then return end
    if typeof(array) ~= "table" then return end

    for _, descendant in next, array do
        if descendant:IsDescendantOf(instanceObject) then
            return true
        end
    end
end


--
return gameplayMechanicManager