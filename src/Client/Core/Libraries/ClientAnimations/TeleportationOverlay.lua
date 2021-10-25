-- Variables
local specificClientAnimation = {}
local coreModule = require(script:FindFirstAncestor("CoreModule"))

-- Methods
function specificClientAnimation.Play(overlayObject, animationLength, isTeleporting)
    if not overlayObject or typeof(overlayObject) ~= "Instance" or not overlayObject:IsA("GuiObject") then return end
    
    local overlayTweenObject = coreModule.Services.TweenService:Create(
        overlayObject,
        TweenInfo.new(animationLength, Enum.EasingStyle.Linear),
        {BackgroundTransparency = isTeleporting and 0 or 1}
    )

    overlayTweenObject:Play()
    return overlayTweenObject
end


--
return specificClientAnimation