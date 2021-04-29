-- Variables
local gameplayMechanicManager = {}
gameplayMechanicManager.Assets = {}
gameplayMechanicManager.MechanicContainer = nil
gameplayMechanicManager.ObjectsBeingSimulated = {}

local coreModule = require(script:FindFirstAncestor("CoreModule"))
local mechanicsManager = require(coreModule.GetObject("/Parent"))
local clientEssentialsLibrary = require(coreModule.GetObject("Libraries.ClientEssentials"))
local clientAnimationsLibrary = require(coreModule.GetObject("Libraries.ClientAnimations"))
local utilitiesLibrary = require(coreModule.Shared.GetObject("Libraries.Utilities"))

-- Initialize
function gameplayMechanicManager.Initialize()
    gameplayMechanicManager.MechanicContainer = mechanicsManager.GetPlatformerMechanics():WaitForChild("CodeDoors")
    gameplayMechanicManager.Assets.CodeDoorProximityPrompt = coreModule.Shared.GetObject("//Assets.Objects.Miscellaneous.CodeDoorProximityPrompt")
    local doorInterfaceManager = require(coreModule.GetObject("Modules.GameplayManager.PlayerManager.UserInterfaceManager.DoorInterface"))

    -- Setting up the platform to be functional.
    for _, platformContainerFolder in next, gameplayMechanicManager.MechanicContainer:GetChildren() do
        for _, platformObject in next, platformContainerFolder:GetChildren() do

            -- This platform is required to be a Model with a PrimaryPart; We create the ProximityPrompt at run time.
            if platformObject:IsA("Model") and platformObject.PrimaryPart then

                -- Let's set up the ProximityPrompt.
                if gameplayMechanicManager.Assets.CodeDoorProximityPrompt then
                    gameplayMechanicManager.Assets.CodeDoorProximityPrompt:Clone().Parent = platformObject.PrimaryPart
                end

                -- Does the ProximityPrompt exist?
                if platformObject.PrimaryPart:FindFirstChild(gameplayMechanicManager.Assets.CodeDoorProximityPrompt.Name) then
                    coreModule.Services.ProximityPromptService.PromptTriggered:Connect(function(proximityPrompt, player)
                        if proximityPrompt ~= platformObject.PrimaryPart[gameplayMechanicManager.Assets.CodeDoorProximityPrompt.Name] then return end
                        if player ~= clientEssentialsLibrary.GetPlayer() then return end
                        if not utilitiesLibrary.IsPlayerAlive(player) then return end
                        if gameplayMechanicManager.IsObjectBeingSimulated(platformObject) then return end

                        -- So this long and confusing math just checks if they're in front of the door or not.
                        if math.round(platformObject.PrimaryPart.CFrame.LookVector:Dot(CFrame.lookAt(player.Character:GetPrimaryPartCFrame().Position, platformObject:GetPrimaryPartCFrame().Position).LookVector)) ~= -1 then return end
                        
                        doorInterfaceManager.OpenInterface(platformObject)
                    end)
                end

            elseif platformObject:IsA("Model") then
                coreModule.Debug(
					("Platform: %s, has PrimaryPart: %s."):format(platformObject:GetFullName(), tostring(platformObject.PrimaryPart ~= nil)),
					coreModule.Shared.Enums.DebugLevel.Exception,
					warn
				)
            end
        end
    end
end


-- Methods
function gameplayMechanicManager.IsObjectBeingSimulated(platformObject)
    if typeof(platformObject) ~= "Instance" then return end
    return gameplayMechanicManager.ObjectsBeingSimulated[platformObject]
end


function gameplayMechanicManager.SimulateObject(platformObject)
    if typeof(platformObject) ~= "Instance" then return end
    if not utilitiesLibrary.IsPlayerAlive(clientEssentialsLibrary.GetPlayer()) then return end
    if gameplayMechanicManager.IsObjectBeingSimulated(platformObject) then return end

    -- So this long and confusing math just checks if they're in front of the door or not.
    if math.round(platformObject.PrimaryPart.CFrame.LookVector:Dot(CFrame.lookAt(clientEssentialsLibrary.GetPlayer().Character:GetPrimaryPartCFrame().Position, platformObject:GetPrimaryPartCFrame().Position).LookVector)) ~= -1 then return end
    
    gameplayMechanicManager.ObjectsBeingSimulated[platformObject] = true

    -- Does the ProximityPrompt exist?
    if platformObject.PrimaryPart:FindFirstChild(gameplayMechanicManager.Assets.CodeDoorProximityPrompt.Name) then
        platformObject.PrimaryPart[gameplayMechanicManager.Assets.CodeDoorProximityPrompt.Name].Enabled = false
    end

    -- Play the animation.
    clientAnimationsLibrary.PlayAnimation("OpenDoor", platformObject)

    -- Clean up.
    if platformObject.PrimaryPart:FindFirstChild(gameplayMechanicManager.Assets.CodeDoorProximityPrompt.Name) then
        platformObject.PrimaryPart[gameplayMechanicManager.Assets.CodeDoorProximityPrompt.Name].Enabled = true
    end

    gameplayMechanicManager.ObjectsBeingSimulated[platformObject] = nil
end


--
return gameplayMechanicManager