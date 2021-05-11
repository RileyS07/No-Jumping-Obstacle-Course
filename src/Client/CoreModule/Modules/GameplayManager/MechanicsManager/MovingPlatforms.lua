-- Variables
local gameplayMechanicManager = {}
gameplayMechanicManager.MechanicContainer = nil

local coreModule = require(script:FindFirstAncestor("CoreModule"))
local mechanicsManager = require(coreModule.GetObject("/Parent"))
local utilitiesLibrary = require(coreModule.Shared.GetObject("Libraries.Utilities"))

-- Initialize
function gameplayMechanicManager.Initialize()
    gameplayMechanicManager.MechanicContainer = mechanicsManager.GetPlatformerMechanics():WaitForChild("MovingPlatforms")

    -- Setting up the MovingPlatforms to be functional.
    for _, platformContainer in next, gameplayMechanicManager.MechanicContainer:GetChildren() do
        for _, platformObject in next, platformContainer:GetChildren() do
            if platformObject:IsA("Model") and platformObject.PrimaryPart and platformObject:FindFirstChild("Nodes") and #platformObject.Nodes:GetChildren() > 0 then
                
                coroutine.wrap(function()
                    local weldOffsetValues = gameplayMechanicManager.GetWeldOffsetValues(platformObject)
                    local validNodesArray = gameplayMechanicManager.GetPlatformNodesArray(
                        platformObject:FindFirstChild("Config") and require(platformObject.Config), 
                        #platformObject.Nodes:GetChildren()
                    )

                    -- This is where the magic happens.
                    while true do
                        if not utilitiesLibrary.IsPlayerValid() then return end

                        gameplayMechanicManager.SimulatePlatform(platformObject, validNodesArray, weldOffsetValues)
                        coreModule.Services.RunService.RenderStepped:Wait()
                    end
                end)()
            elseif platformObject:IsA("Model") then
                coreModule.Debug(
                    ("MovingPlatform: %s, has PrimaryPart: %s, has Nodes: %s, # of Nodes: %s"):format(platformObject:GetFullName(), tostring(platformObject.PrimaryPart ~= nil), tostring(platformObject:FindFirstChild("Nodes") ~= nil), tostring(platformObject:FindFirstChild("Nodes") and #platformObject.Nodes:GetChildren() or 0)), 
                    coreModule.Shared.Enums.DebugLevel.Exception,	
                    warn
                )
            end
        end
    end
end


-- Methods
function gameplayMechanicManager.SimulatePlatform(platformObject, validNodesArray, weldOffsetValues)
    if typeof(platformObject) ~= "Instance" or not platformObject:IsA("Model") or not platformObject.PrimaryPart then return end
    if not platformObject:FindFirstChild("Nodes") or #platformObject.Nodes:GetChildren() == 0 then return end
    if typeof(validNodesArray) ~= "table" or #validNodesArray == 0 then return end
    
    for index = 1, #platformObject.Nodes:GetChildren() do
        if not platformObject.Nodes:FindFirstChild(index) then 
            coreModule.Debug("MovingPlatform: "..platformObject:GetFullName()..", has "..tostring(#platformObject.Nodes:GetChildren()).." children but is missing node: "..tostring(index)..".", coreModule.Shared.Enums.DebugLevel.Exception, warn) 
            break 
        end

        -- Common tween information.
        local nodeTweenInfo = TweenInfo.new(
            gameplayMechanicManager.GetPlatformSpeed(validNodesArray, index),
            Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, false,
            gameplayMechanicManager.GetPlatformDelay(validNodesArray, index)
        )

        -- Tweening the welded objects.
        -- This really isn't ideal because in some circumstances the path the welded objects isn't the same as the path the platform takes and it can look really bad.
        if weldOffsetValues then
            for weldConstraint, objectSpaceCFrame in next, weldOffsetValues do
                coreModule.Services.TweenService:Create(
                    weldConstraint.Part1,
                    nodeTweenInfo,
                    {CFrame = platformObject.Nodes[index].CFrame:ToWorldSpace(objectSpaceCFrame)}
                ):Play()
            end
        end

        -- Now we can finally move the actual platform.
        local platformMovementTweenObject = coreModule.Services.TweenService:Create(platformObject.PrimaryPart, nodeTweenInfo, {CFrame = platformObject.Nodes[index].CFrame})
        platformMovementTweenObject:Play()
        platformMovementTweenObject.Completed:Wait()
    end
end


-- Private Methods
function gameplayMechanicManager.GetWeldOffsetValues(platformObject)
    if not platformObject or not typeof(platformObject) == "Instance" then return end
    if not platformObject:IsA("Model") or not platformObject.PrimaryPart then return end

    -- Do an initial check before doing any needless computation.
    if platformObject.PrimaryPart:FindFirstChildOfClass("WeldConstraint") then
        local weldOffsetValues = {}

        -- We need to collect all of the WeldConstraints' information.
        for _, weldConstraint in next, platformObject.PrimaryPart:GetChildren() do
            if weldConstraint:IsA("WeldConstraint") and weldConstraint.Part1 then
                weldOffsetValues[weldConstraint] = platformObject:GetPrimaryPartCFrame():ToObjectSpace(weldConstraint.Part1.CFrame)
            end
        end

        return weldOffsetValues
    end
end 


function gameplayMechanicManager.GetPlatformNodesArray(possibleNodesArray, minimumNumberOfSequencesNeeded)
    minimumNumberOfSequencesNeeded = typeof(minimumNumberOfSequencesNeeded) and minimumNumberOfSequencesNeeded or 1
    local validNodesArray = {}

    -- Is the possibleNodesArray valid? If so let's try to salvage it.
    if typeof(possibleNodesArray) == "table" and #possibleNodesArray > 0 then
        for index = 1, #possibleNodesArray do
            table.insert(validNodesArray, {
                Speed = tonumber(possibleNodesArray[index].Speed) or 5,
                Delay = tonumber(possibleNodesArray[index].Delay) or 1
            })
        end
    end

    -- Fill in the gaps?
    if #validNodesArray < minimumNumberOfSequencesNeeded then
        while #validNodesArray < minimumNumberOfSequencesNeeded do
            table.insert(validNodesArray, {Speed = 5, Delay = 1})
        end
    end

    return validNodesArray
end


function gameplayMechanicManager.GetPlatformSpeed(platformConfig, index)
    local targetNodeValues = platformConfig[math.min(index, 1)]
    targetNodeValues.Speed = targetNodeValues.Speed or 5

    -- We have to figure out what to return based on the Speed type.
    if typeof(targetNodeValues.Speed) == "number" then
        return targetNodeValues.Speed
    elseif typeof(targetNodeValues.Speed) == "NumberRange" then
        return Random.new():NextNumber(targetNodeValues.Speed.Min, targetNodeValues.Speed.Max)
    else
        return 5
    end
end


function gameplayMechanicManager.GetPlatformDelay(platformConfig, index)
    local targetNodeValues = platformConfig[math.min(index, 1)]
    targetNodeValues.Delay = targetNodeValues.Delay or 1

    -- We have to figure out what to return based on the Delay type.
    if typeof(targetNodeValues.Delay) == "number" then
        return targetNodeValues.Delay
    elseif typeof(targetNodeValues.Delay) == "NumberRange" then
        return Random.new():NextNumber(targetNodeValues.Delay.Min, targetNodeValues.Delay.Max)
    else
        return 1
    end
end


--
return gameplayMechanicManager