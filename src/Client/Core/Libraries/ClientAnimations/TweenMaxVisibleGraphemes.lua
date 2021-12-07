-- Variables
local specificClientAnimation = {}
local coreModule = require(script:FindFirstAncestor("Core"))

-- Methods
function specificClientAnimation.Play(textLabel, maxVisibleGraphemes)
    if typeof(textLabel) ~= "Instance" or not textLabel:IsA("TextLabel") then return end
    if typeof(maxVisibleGraphemes) ~= "number" then return end
    
    local maxVisibleGraphemesTweenObject = game:GetService("TweenService"):Create(textLabel, TweenInfo.new(1, Enum.EasingStyle.Linear), {MaxVisibleGraphemes = maxVisibleGraphemes})
    maxVisibleGraphemesTweenObject:Play()
    return maxVisibleGraphemesTweenObject.Completed
end


--
return specificClientAnimation