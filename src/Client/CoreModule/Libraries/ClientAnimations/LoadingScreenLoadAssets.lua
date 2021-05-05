-- Variables
local specificClientAnimation = {}
specificClientAnimation.IsPlaying = false

local coreModule = require(script:FindFirstAncestor("CoreModule"))
local clientEssentialsLibrary = require(coreModule.GetObject("Libraries.ClientEssentials"))
local clientAnimationsLibrary = require(coreModule.GetObject("/Parent"))

-- Methods
function specificClientAnimation.Play(textLabel)
    if typeof(textLabel) ~= "Instance" or not textLabel:IsA("TextLabel") then return end

    local assetsArray = coreModule.Shared.GetObject("//Assets"):GetDescendants()

    -- Loads in all of the assets and plays a little text animation for it.
    specificClientAnimation.IsPlaying = true
    textLabel.Text = "Welcome, "..clientEssentialsLibrary.GetPlayer().Name
    textLabel.MaxVisibleGraphemes = textLabel.Text:len()

    wait(5)
    clientAnimationsLibrary.PlayAnimation("TweenMaxVisibleGraphemes", textLabel, 0):Wait()
    wait(1)

    if #assetsArray > 0 and specificClientAnimation.IsPlaying then
        textLabel.Text = "Loading asset 1/"..#assetsArray
        clientAnimationsLibrary.PlayAnimation("TweenMaxVisibleGraphemes", textLabel, #textLabel.Text):Wait()

        for index = 1, #assetsArray do
            if not specificClientAnimation.IsPlaying then return end

            textLabel.Text = "Loading asset "..index.."/"..#assetsArray
            textLabel.MaxVisibleGraphemes = textLabel.Text:len()
            coreModule.Services.ContentProvider:PreloadAsync({assetsArray[index]})
            wait(1/20)
        end

        wait(1)

        clientAnimationsLibrary.PlayAnimation("TweenMaxVisibleGraphemes", textLabel, 0):Wait()

        wait(1)

        textLabel.Text = "Assets loaded!"
        clientAnimationsLibrary.PlayAnimation("TweenMaxVisibleGraphemes", textLabel, #textLabel.Text):Wait()
    end
end


function specificClientAnimation.Stop()
    specificClientAnimation.IsPlaying = false
end


--
return specificClientAnimation