-- Variables
local specificClientAnimation = {}
specificClientAnimation.Sliders = {}
specificClientAnimation.TouchMovedListener = nil

local coreModule = require(script:FindFirstAncestor("CoreModule"))
local clientAnimationsLibrary = require(coreModule.GetObject("/Parent"))

-- Methods
function specificClientAnimation.Play(sliderContainer, startingValue, callbackFunction)
    if typeof(sliderContainer) ~= "Instance" or not sliderContainer:IsA("GuiObject") then return end
    if typeof(startingValue) ~= "number" then return end
    if typeof(callbackFunction) ~= "function" and typeof(callbackFunction) ~= "nil" then return end
    if specificClientAnimation.Sliders[sliderContainer] then return end
    specificClientAnimation.Sliders[sliderContainer] = {}

    -- Setup.
    specificClientAnimation.Sliders[sliderContainer].CallbackFunction = callbackFunction or (function() end)
    specificClientAnimation.Sliders[sliderContainer].IsBeingTouched = false

    specificClientAnimation.Sliders[sliderContainer].Interface = {}
    specificClientAnimation.Sliders[sliderContainer].Interface.Slider = sliderContainer
    specificClientAnimation.Sliders[sliderContainer].Interface.Fill = specificClientAnimation.Sliders[sliderContainer].Interface.Slider:WaitForChild("Fill")
    specificClientAnimation.Sliders[sliderContainer].Interface.Button = specificClientAnimation.Sliders[sliderContainer].Interface.Fill:WaitForChild("Button")
    specificClientAnimation.Sliders[sliderContainer].Interface.Empty = specificClientAnimation.Sliders[sliderContainer].Interface.Slider:WaitForChild("Empty")
    specificClientAnimation.Sliders[sliderContainer].Interface.Fill.Size = UDim2.fromScale(startingValue, 1)
    specificClientAnimation.Sliders[sliderContainer].CallbackFunction(startingValue)

    -- Mouse support.
    specificClientAnimation.UpdateSliderWithMouse(sliderContainer, specificClientAnimation.Sliders[sliderContainer].Interface.Button.InputBegan)
    specificClientAnimation.UpdateSliderWithMouse(sliderContainer, specificClientAnimation.Sliders[sliderContainer].Interface.Fill.InputBegan)
    specificClientAnimation.UpdateSliderWithMouse(sliderContainer, specificClientAnimation.Sliders[sliderContainer].Interface.Empty.InputBegan)

    -- Mobile support.
    specificClientAnimation.UpdateSliderWithTouch(sliderContainer, specificClientAnimation.Sliders[sliderContainer].Interface.Button.InputBegan)
    specificClientAnimation.UpdateSliderWithTouch(sliderContainer, specificClientAnimation.Sliders[sliderContainer].Interface.Fill.InputBegan)
    specificClientAnimation.UpdateSliderWithTouch(sliderContainer, specificClientAnimation.Sliders[sliderContainer].Interface.Empty.InputBegan)

    if not specificClientAnimation.TouchMovedListener then
        specificClientAnimation.TouchMovedListener = coreModule.Services.UserInputService.TouchMoved:Connect(function()
            for _, sliderInformation in next, specificClientAnimation.Sliders do
                if sliderInformation.IsBeingTouched then
                    local sliderPercentage = clientAnimationsLibrary.PlayAnimation("UpdateSliderSize", sliderInformation.Interface.Slider)
                    
                    -- Update the callbackFunction.
                    sliderInformation.CallbackFunction(sliderPercentage)
                end
            end
        end)

        -- TouchEnded.
        coreModule.Services.UserInputService.TouchEnded:Connect(function()
            for _, sliderInformation in next, specificClientAnimation.Sliders do
                sliderInformation.IsBeingTouched = false
            end
        end)
    end
end


-- Private Methods
function specificClientAnimation.UpdateSliderWithMouse(sliderContainer, inputEventSignal)
    if typeof(sliderContainer) ~= "Instance" or not specificClientAnimation.Sliders[sliderContainer] then return end
    if typeof(inputEventSignal) ~= "RBXScriptSignal" then return end

    -- Connect the event.
    inputEventSignal:Connect(function(inputObject)
        if inputObject.UserInputType ~= Enum.UserInputType.MouseButton1 then return end

        -- Keeps moving it till you let go of your mouse.
        while coreModule.Services.UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
            local sliderPercentage = clientAnimationsLibrary.PlayAnimation("UpdateSliderSize", specificClientAnimation.Sliders[sliderContainer].Interface.Slider)
            
            -- Update the callbackFunction.
            specificClientAnimation.Sliders[sliderContainer].CallbackFunction(sliderPercentage)
            coreModule.Services.RunService.RenderStepped:Wait()
        end
    end)
end


function specificClientAnimation.UpdateSliderWithTouch(sliderContainer, inputEventSignal)
    if typeof(sliderContainer) ~= "Instance" or not specificClientAnimation.Sliders[sliderContainer] then return end
    if typeof(inputEventSignal) ~= "RBXScriptSignal" then return end

    -- Connect the event.
    inputEventSignal:Connect(function(inputObject)
        if inputObject.UserInputType ~= Enum.UserInputType.Touch then return end
        specificClientAnimation.Sliders[sliderContainer].IsBeingTouched = true

        local sliderPercentage = clientAnimationsLibrary.PlayAnimation("UpdateSliderSize", specificClientAnimation.Sliders[sliderContainer].Interface.Slider)
        specificClientAnimation.Sliders[sliderContainer].CallbackFunction(sliderPercentage)
    end)
end


--
return specificClientAnimation