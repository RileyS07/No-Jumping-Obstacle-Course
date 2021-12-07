-- Variables
local specificClientAnimation = {}
specificClientAnimation.IsPlaying = false

local coreModule = require(script:FindFirstAncestor("Core"))

-- Methods
function specificClientAnimation.Play(textLabel)
    if typeof(textLabel) ~= "Instance" or not textLabel:IsA("TextLabel") then return end
    specificClientAnimation.IsPlaying = true

    -- Just does like Loading game... -> .. -> . <<<.
    coroutine.wrap(function()
        while specificClientAnimation.IsPlaying do
            for index = 1, 3 do
                textLabel.Text = textLabel.Text:match("[%w+%s?]+")..("."):rep(index)
                wait(1)
            end
        end
    end)()
end


function specificClientAnimation.Stop()
    specificClientAnimation.IsPlaying = false
end


--
return specificClientAnimation