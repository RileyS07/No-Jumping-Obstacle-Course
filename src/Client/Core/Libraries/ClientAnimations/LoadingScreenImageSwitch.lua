-- Variables
local specificClientAnimation = {}
local coreModule = require(script:FindFirstAncestor("Core"))

-- Methods
function specificClientAnimation.Play(backgroundImage, referenceImage)
    if typeof(backgroundImage) ~= "Instance" or not backgroundImage:IsA("ImageLabel") then return end
    if typeof(referenceImage) ~= "Instance" or not referenceImage:IsA("ImageLabel") then return end

    -- Preload.
    game:GetService("ContentProvider"):PreloadAsync({backgroundImage, referenceImage})
    
    -- It's gonna fade between each of these images.
    local originalImageColor3 = referenceImage.ImageColor3
    local fadeToBlackTweenObject = game:GetService("TweenService"):Create(backgroundImage, TweenInfo.new(1, Enum.EasingStyle.Linear), {ImageColor3 = Color3.new()})
    fadeToBlackTweenObject:Play()
    fadeToBlackTweenObject.Completed:Wait()
    
    backgroundImage.Visible = false
    referenceImage.ImageColor3 = Color3.new()
    referenceImage.Visible = true

    local fadeToColorTweenObject = game:GetService("TweenService"):Create(referenceImage, TweenInfo.new(1, Enum.EasingStyle.Linear), {ImageColor3 = originalImageColor3})
    fadeToColorTweenObject:Play()
    fadeToColorTweenObject.Completed:Wait()
end


--
return specificClientAnimation