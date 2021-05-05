-- Variables
local specificClientAnimation = {}
specificClientAnimation.IsPlaying = false

local coreModule = require(script:FindFirstAncestor("CoreModule"))
local clientAnimationsLibrary = require(coreModule.GetObject("/Parent"))

-- Methods
function specificClientAnimation.Play(backgroundImage)
    if typeof(backgroundImage) ~= "Instance" or not backgroundImage:IsA("ImageLabel") then return end
    if not coreModule.Shared.GetObject("//Assets.Interfaces"):FindFirstChild("LoadingScreenBackgroundImages") then return end

    -- It's gonna fade between each of these images.
    local loadingScreenBackgroundImages = coreModule.Shared.GetObject("//Assets.Interfaces.LoadingScreenBackgroundImages"):GetChildren()
    table.sort(loadingScreenBackgroundImages, function(imageA, imageB) return imageA.Name < imageB.Name end)
    specificClientAnimation.IsPlaying = true

    if #loadingScreenBackgroundImages > 1 and specificClientAnimation.IsPlaying then
        coroutine.wrap(function()
            backgroundImage.ImageColor3 = Color3.new()
            
            for _ = 1, 3 do
                for index = 1, #loadingScreenBackgroundImages do
                    backgroundImage.Image = loadingScreenBackgroundImages[index].Image
                    coreModule.Services.RunService.RenderStepped:Wait()
                end
            end

            while specificClientAnimation.IsPlaying do
                for index = 1, #loadingScreenBackgroundImages do
                    if not specificClientAnimation.IsPlaying then return end
                    
                    -- This is where the magic happens.
                    coreModule.Services.ContentProvider:PreloadAsync({loadingScreenBackgroundImages[index]})
                    clientAnimationsLibrary.PlayAnimation("LoadingScreenImageSwitch", backgroundImage, loadingScreenBackgroundImages[index])
                    wait(script:GetAttribute("TimeBetweenImages") or 6)
                end
            end
        end)()
    end
end


function specificClientAnimation.Stop()
    specificClientAnimation.IsPlaying = false
end


--
return specificClientAnimation