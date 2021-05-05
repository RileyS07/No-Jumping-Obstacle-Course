-- Variables
local specificClientAnimation = {}
local coreModule = require(script:FindFirstAncestor("CoreModule"))

-- Methods
function specificClientAnimation.Play(backgroundImage, referenceImage)
    if typeof(backgroundImage) ~= "Instance" or not backgroundImage:IsA("ImageLabel") then return end
    if typeof(referenceImage) ~= "Instance" or not referenceImage:IsA("ImageLabel") then return end

    -- It's gonna fade between each of these images.
    local fadeToBlackTweenObject = coreModule.Services.TweenService:Create(backgroundImage, TweenInfo.new(1, Enum.EasingStyle.Linear), {ImageColor3 = Color3.new()})
    fadeToBlackTweenObject:Play()
    fadeToBlackTweenObject.Completed:Wait()
    
    backgroundImage.Image = referenceImage.Image
    
    local fadeToColorTweenObject = coreModule.Services.TweenService:Create(backgroundImage, TweenInfo.new(1, Enum.EasingStyle.Linear), {ImageColor3 = referenceImage.ImageColor3})
    fadeToColorTweenObject:Play()
    fadeToColorTweenObject.Completed:Wait()
end


--
return specificClientAnimation