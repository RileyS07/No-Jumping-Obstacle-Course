-- Variables
local gameplayMechanicManager = {}
gameplayMechanicManager.MechanicContainer = nil

local coreModule = require(script:FindFirstAncestor("CoreModule"))
local mechanicsManager = require(coreModule.GetObject("/Parent"))

-- Initialize
function gameplayMechanicManager.Initialize()
    gameplayMechanicManager.MechanicContainer = mechanicsManager.GetPlatformerMechanics():WaitForChild("MovingPlatforms")

    -- Setting up the MovingPlatforms to be functional.
    for _, movingPlatformContainer in next, gameplayMechanicManager.MechanicContainer:GetChildren() do
        for _, movingPlatform in next, movingPlatformContainer:GetChildren() do

            -- The PrimaryPart is the platform that will be moving and the nodes are what it will move between.
            if movingPlatform:IsA("Model") and movingPlatform.PrimaryPart and movingPlatform:FindFirstChild("Nodes") and #movingPlatform.Nodes:GetChildren() > 0 then
                
                -- We put each MovingPlatform into it's own coroutine so they all run separate from eachother.
                coroutine.wrap(function()
                    local weldOffsetValues = gameplayMechanicManager.GetWeldOffsetValues(movingPlatform)
                    local platformConfig = setmetatable(movingPlatform:FindFirstChild("Config") and require(movingPlatform.Config) or {}, {__index = {
                        [1] = { 
                            -- How many seconds it takes to get to the next node.
                            Speed = 5,
                            -- How many seconds it waits till moving to the next node.
                            Delay = 1
                        }
                    }})

                    -- This is where the magic happens; All of the logic for moving the platforms will be in here.
                    while true do
                        
                        -- I didn't check this in the initial check because I wanted a more unique warning.
                        if #movingPlatform.Nodes:GetChildren() > 0 then

                            -- Moving from node to node.
                            for index = 1, #movingPlatform.Nodes:GetChildren() do

                                -- We can only accept integer-named nodes.
                                if not movingPlatform.Nodes:FindFirstChild(index) then 
                                    coreModule.Debug("MovingPlatform: "..movingPlatform:GetFullName()..", has "..tostring(#movingPlatform.Nodes:GetChildren()).." children but is missing node: "..tostring(index)..".", coreModule.Shared.Enums.DebugLevel.Exception, warn) 
                                    break 
                                end

                                -- Now that we have our bases covered we can actually move forward.
                                local nodeTweenInfo = TweenInfo.new(
                                    gameplayMechanicManager.GetPlatformSpeed(platformConfig, index),
                                    Enum.EasingStyle.Linear,
                                    Enum.EasingDirection.Out,
                                    0,
                                    false,
                                    gameplayMechanicManager.GetPlatformDelay(platformConfig, index)
                                )

                                -- I go bottom up for how I move the entire model; So that means I'm moving the welded parts first.
                                if weldOffsetValues then
                                    for weldConstraint, objectSpaceCFrame in next, weldOffsetValues do
                                        coreModule.Services.TweenService:Create(
                                            weldConstraint.Part1,
                                            nodeTweenInfo,
                                            {CFrame = movingPlatform.Nodes[index].CFrame:ToWorldSpace(objectSpaceCFrame)}
                                        ):Play()
                                    end
                                end

                                -- Now we can finally move the actual platform.
                                local platformMovementTweenObject = coreModule.Services.TweenService:Create(
                                    movingPlatform.PrimaryPart, nodeTweenInfo, {CFrame = movingPlatform.Nodes[index].CFrame}
                                )
                                platformMovementTweenObject:Play()
                                platformMovementTweenObject.Completed:Wait()
                            end

                            coreModule.Services.RunService.RenderStepped:Wait()
                        else
                            coreModule.Debug(
                                ("MovingPlatform: %s, has 0 nodes to move between."):format(movingPlatform:GetFullName()), 
                                coreModule.Shared.Enums.DebugLevel.Exception, 
                                warn
                            )
                        end
                    end
                end)()
            elseif movingPlatform:IsA("Model") then
                coreModule.Debug(
                    ("MovingPlatform: %s, has PrimaryPart: %s, has Nodes: %s"):format(movingPlatform:GetFullName(), tostring(movingPlatform.PrimaryPart ~= nil), tostring(movingPlatform:FindFirstChild("Nodes") ~= nil)), 
                    coreModule.Shared.Enums.DebugLevel.Exception,	
                    warn
                )
            end
        end
    end
end


-- Private Methods
-- This method exists so we can support things being welded to the platforms moving with them.
function gameplayMechanicManager.GetWeldOffsetValues(movingPlatform)
    if not movingPlatform or not typeof(movingPlatform) == "Instance" then return end
    if not movingPlatform:IsA("Model") or not movingPlatform.PrimaryPart then return end

    -- Do an initial check before doing any needless computation.
    if movingPlatform.PrimaryPart:FindFirstChildOfClass("WeldConstraint") then
        local weldOffsetValues = {}

        -- We need to collect all of the WeldConstraints' information.
        for _, weldConstraint in next, movingPlatform.PrimaryPart:GetChildren() do
            if weldConstraint:IsA("WeldConstraint") and weldConstraint.Part1 then
                weldOffsetValues[weldConstraint] = movingPlatform:GetPrimaryPartCFrame():ToObjectSpace(weldConstraint.Part1.CFrame)
            end
        end

        return weldOffsetValues
    end
end 


-- This has to exist because I offer a lot of flexibility for how we can define speed.
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


-- This has to exist because I offer a lot of flexibility for how we can define delay.
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