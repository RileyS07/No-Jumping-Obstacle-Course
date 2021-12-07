-- Variables
local specificClientAnimation = {}
local coreModule = require(script:FindFirstAncestor("Core"))

-- Methods
function specificClientAnimation.Play(sliderContainer)
    if typeof(sliderContainer) ~= "Instance" or not sliderContainer:IsA("GuiObject") then return end
    local sliderPercentage = (math.clamp(
        game:GetService("UserInputService"):GetMouseLocation().X, sliderContainer.AbsolutePosition.X, sliderContainer.AbsolutePosition.X + sliderContainer.AbsoluteSize.X
    ) - sliderContainer.AbsolutePosition.X)/sliderContainer.AbsoluteSize.X

    -- Snap to the nearest multiple of 5?
    if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.LeftShift) or game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.RightShift) then
        sliderPercentage -= sliderPercentage%0.05
    end

    sliderContainer:WaitForChild("Fill").Size = UDim2.fromScale(sliderPercentage, 1)
    return sliderPercentage
end


--
return specificClientAnimation