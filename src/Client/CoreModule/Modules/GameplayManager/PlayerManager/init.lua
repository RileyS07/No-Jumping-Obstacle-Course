-- Variables
local playerManager = {}
local coreModule = require(script:FindFirstAncestor("CoreModule"))

-- Initialize
function playerManager.Initialize()
	coreModule.LoadModule("/UserInterfaceManager")
	coreModule.LoadModule("/GameplayLighting")
	coreModule.LoadModule("/GameplayMusic")
	coreModule.LoadModule("/SoundEffects")
	coreModule.LoadModule("/CutsceneManager")
end

--
return playerManager