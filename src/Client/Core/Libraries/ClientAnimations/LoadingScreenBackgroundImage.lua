-- Variables
local specificClientAnimation = {}
specificClientAnimation.IsPlaying = false

local coreModule = require(script:FindFirstAncestor("CoreModule"))
local clientAnimationsLibrary = require(coreModule.GetObject("/Parent"))

-- Methods
function specificClientAnimation.Play(backgroundImages)
    if typeof(backgroundImages) ~= "Instance" or #backgroundImages:GetChildren() <= 1 then return end

    -- It's gonna fade between each of these images.
    backgroundImages = backgroundImages:GetChildren()
    table.sort(backgroundImages, function(imageA, imageB) return imageA.Name < imageB.Name end)
    specificClientAnimation.IsPlaying = true
    
    if #backgroundImages > 1 and specificClientAnimation.IsPlaying then
        coroutine.wrap(function()

            -- The preset one.
            for _, backgroundImage in next, backgroundImages do
                backgroundImage.Visible = false
            end

            -- The main animation logic.
            while specificClientAnimation.IsPlaying do
                for index, backgroundImage in next, backgroundImages do
                    if not specificClientAnimation.IsPlaying then return end
                    
                    -- This is where the magic happens.
                    coreModule.Services.ContentProvider:PreloadAsync({backgroundImage})
                    clientAnimationsLibrary.PlayAnimation("LoadingScreenImageSwitch", backgroundImages[math.max(index - 1, 1)], backgroundImage)
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