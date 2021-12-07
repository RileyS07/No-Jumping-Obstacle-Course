-- Variables
local specificAmbientSoundManager = {}
specificAmbientSoundManager.ApplicableRange = NumberRange.new(61, 70)
specificAmbientSoundManager.IsRunning = false

local coreModule = require(script:FindFirstAncestor("Core"))
local soundEffectsManager = require(coreModule.GetObject("Modules.GameplayManager.PlayerManager.SoundEffects"))

-- Methods
function specificAmbientSoundManager.Start()
    specificAmbientSoundManager.IsRunning = true

    -- Setup.
    local crowObjectsArray = workspace:WaitForChild("Map"):WaitForChild("Gameplay"):WaitForChild("LevelStorage"):WaitForChild("Stages"):WaitForChild("The Eerie"):WaitForChild("Decoration Model"):WaitForChild("Crows"):GetChildren()

    coroutine.wrap(function()
        while specificAmbientSoundManager.IsRunning do
            wait(Random.new():NextInteger(15, 30))

            soundEffectsManager.PlaySoundEffect("Crow", {Parent = crowObjectsArray[Random.new():NextInteger(1, #crowObjectsArray)]})
        end
    end)()
end


function specificAmbientSoundManager.Stop()
    specificAmbientSoundManager.IsRunning = false
end


--
return specificAmbientSoundManager