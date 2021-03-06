-- Variables
local specificClientAnimation = {}
specificClientAnimation.Sliders = {}
specificClientAnimation.TouchMovedListener = nil

local coreModule = require(script:FindFirstAncestor("Core"))
local clientAnimationsLibrary = require(coreModule.GetObject("Libraries.ClientAnimations"))

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
    specificClientAnimation.UpdateSlider(sliderContainer, specificClientAnimation.Sliders[sliderContainer].Interface.Button.InputBegan)
    specificClientAnimation.UpdateSlider(sliderContainer, specificClientAnimation.Sliders[sliderContainer].Interface.Fill.InputBegan)
    specificClientAnimation.UpdateSlider(sliderContainer, specificClientAnimation.Sliders[sliderContainer].Interface.Empty.InputBegan)

    -- Mobile support.
    if not specificClientAnimation.TouchMovedListener then
        specificClientAnimation.TouchMovedListener = game:GetService("UserInputService").TouchMoved:Connect(function()
            for _, sliderInformation in next, specificClientAnimation.Sliders do
                if sliderInformation.IsBeingTouched then
                    local sliderPercentage = clientAnimationsLibrary.PlayAnimation("UpdateSliderSize", sliderInformation.Interface.Slider)
                    sliderInformation.CallbackFunction(sliderPercentage)
                end
            end
        end)

        -- TouchEnded.
        game:GetService("UserInputService").TouchEnded:Connect(function()
            for _, sliderInformation in next, specificClientAnimation.Sliders do
                sliderInformation.IsBeingTouched = false
            end
        end)
    end
end


-- Private Methods
function specificClientAnimation.UpdateSlider(sliderContainer, inputEventSignal)
    if typeof(sliderContainer) ~= "Instance" or not specificClientAnimation.Sliders[sliderContainer] then return end
    if typeof(inputEventSignal) ~= "RBXScriptSignal" then return end

    -- Connect the event.
    inputEventSignal:Connect(function(inputObject)
        if inputObject.UserInputType == Enum.UserInputType.MouseButton1 then

            -- Keeps moving it till you let go of your mouse.
            while game:GetService("UserInputService"):IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                local sliderPercentage = clientAnimationsLibrary.PlayAnimation("UpdateSliderSize", specificClientAnimation.Sliders[sliderContainer].Interface.Slider)
                
                -- Update the callbackFunction.
                specificClientAnimation.Sliders[sliderContainer].CallbackFunction(sliderPercentage)
                game:GetService("RunService").RenderStepped:Wait()
            end
        elseif inputObject.UserInputType == Enum.UserInputType.Touch then
            specificClientAnimation.Sliders[sliderContainer].IsBeingTouched = true
        end
    end)
end


--
return specificClientAnimation