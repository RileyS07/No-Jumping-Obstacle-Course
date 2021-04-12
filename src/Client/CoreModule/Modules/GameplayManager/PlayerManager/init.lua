-- Variables
local playerManager = {}
local coreModule = require(script:FindFirstAncestor("CoreModule"))

-- Initialize
function playerManager.Initialize()
	coreModule.LoadModule("/UserInterfaceManager")
	coreModule.LoadModule("/SoundEffects")
	coreModule.LoadModule("/CutsceneManager")
end

--
return playerManager