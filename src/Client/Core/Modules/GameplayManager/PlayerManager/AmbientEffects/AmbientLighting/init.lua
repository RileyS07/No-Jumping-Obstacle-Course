-- Variables
local ambientEffectsManager = {}
local coreModule = require(script:FindFirstAncestor("CoreModule"))

-- Initialize
function ambientEffectsManager.Initialize()
    coreModule.LoadModule("/Zone9Transition")
end


--
return ambientEffectsManager