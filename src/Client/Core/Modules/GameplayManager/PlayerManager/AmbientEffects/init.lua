-- Variables
local ambientEffectsManager = {}
local coreModule = require(script:FindFirstAncestor("CoreModule"))

-- Initialize
function ambientEffectsManager.Initialize()
    coreModule.LoadModule("/AmbientSounds")
    coreModule.LoadModule("/AmbientLighting")
end


--
return ambientEffectsManager