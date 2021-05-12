-- Variables
local specificClientAnimation = {}
specificClientAnimation.SlidersInitialized = {}

local coreModule = require(script:FindFirstAncestor("CoreModule"))
local clientAnimationsLibrary = require(coreModule.GetObject("/Parent"))

-- Methods
function specificClientAnimation.Play(sliderContainer, startingValue, callbackFunction)
    if typeof(sliderContainer) ~= "Instance" or not sliderContainer:IsA("GuiObject") then return end
    if typeof(startingValue) ~= "number" then return end
    if typeof(callbackFunction) ~= "function" and typeof(callbackFunction) ~= "nil" then return end
    if specificClientAnimation.SlidersInitialized[sliderContainer] then return end
    specificClientAnimation.SlidersInitialized[sliderContainer] = true

    -- Setup.
    local fillContainer = sliderContainer:WaitForChild("Fill")
    local emptyContainer = sliderContainer:WaitForChild("Empty")
    fillContainer.Size = UDim2.fromScale(startingValue, 1)
    if callbackFunction then callbackFunction(startingValue) end

    -- Mouse support.
    fillContainer:WaitForChild("Button").InputBegan:Connect(function(inputObject, gameProcessedEvent)
        if gameProcessedEvent then return end
        if inputObject.UserInputType ~= Enum.UserInputType.MouseButton1 then return end

        while coreModule.Services.UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
            local sliderPercentage = clientAnimationsLibrary.PlayAnimation("UpdateSliderSize", sliderContainer)
            
            -- Update the callbackFunction.
            if callbackFunction then callbackFunction(sliderPercentage) end
            coreModule.Services.RunService.RenderStepped:Wait()
        end
    end)

    fillContainer.InputBegan:Connect(function(inputObject, gameProcessedEvent)
        if gameProcessedEvent then return end
        if inputObject.UserInputType ~= Enum.UserInputType.MouseButton1 then return end

        local sliderPercentage = clientAnimationsLibrary.PlayAnimation("UpdateSliderSize", sliderContainer)
        if callbackFunction then callbackFunction(sliderPercentage) end
    end)

    emptyContainer.InputBegan:Connect(function(inputObject, gameProcessedEvent)
        if gameProcessedEvent then return end
        if inputObject.UserInputType ~= Enum.UserInputType.MouseButton1 then return end

        local sliderPercentage = clientAnimationsLibrary.PlayAnimation("UpdateSliderSize", sliderContainer)
        if callbackFunction then callbackFunction(sliderPercentage) end
    end)
end


--
return specificClientAnimation