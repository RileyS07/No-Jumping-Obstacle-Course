-- Variables
local specificClientAnimation = {}
local coreModule = require(script:FindFirstAncestor("CoreModule"))

-- Methods
function specificClientAnimation.Play(sliderContainer)
    if typeof(sliderContainer) ~= "Instance" or not sliderContainer:IsA("GuiObject") then return end
    local sliderPercentage = (math.clamp(
        coreModule.Services.UserInputService:GetMouseLocation().X, sliderContainer.AbsolutePosition.X, sliderContainer.AbsolutePosition.X + sliderContainer.AbsoluteSize.X
    ) - sliderContainer.AbsolutePosition.X)/sliderContainer.AbsoluteSize.X

    sliderContainer:WaitForChild("Fill").Size = UDim2.fromScale(sliderPercentage, 1)
    return sliderPercentage
end


--
return specificClientAnimation