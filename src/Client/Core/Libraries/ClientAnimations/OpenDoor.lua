-- Variables
local specificClientAnimation = {}
local coreModule = require(script:FindFirstAncestor("Core"))

-- Methods
function specificClientAnimation.Play(platformObject)
    if typeof(platformObject) ~= "Instance" or not platformObject:IsA("Model") or not platformObject.PrimaryPart then return end
    
    platformObject.PrimaryPart.CanCollide = false

    -- Tween the transparency.
    local tweenObject = game:GetService("TweenService"):Create(
        platformObject.PrimaryPart,
        TweenInfo.new(script:GetAttribute("Length") or 2, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, true),
        {Transparency = script:GetAttribute("GoalTransparency") or 0.7}
    )

    tweenObject:Play()
    tweenObject.Completed:Wait()

    platformObject.PrimaryPart.CanCollide = true
end


--
return specificClientAnimation