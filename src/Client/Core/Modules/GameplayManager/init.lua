-- Variables
local gameplayManager = {}
local coreModule = require(script:FindFirstAncestor("CoreModule"))

-- Initialize
function gameplayManager.Initialize()
	workspace:WaitForChild("Map"):WaitForChild("Gameplay")
	
	-- Loading modules
	coreModule.LoadModule("/MechanicsManager")
	coreModule.LoadModule("/PlayerManager")
	coreModule.LoadModule("/EventsManager")
end

--
return gameplayManager