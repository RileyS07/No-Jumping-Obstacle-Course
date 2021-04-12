-- Variables
local eventsManager = {}
local coreModule = require(script:FindFirstAncestor("CoreModule"))

-- Initialize
function eventsManager.Initialize()
	workspace.Map.Gameplay:WaitForChild("EventStorage")
	
	--
	coreModule.LoadModule("/Trophies")
end

--
return eventsManager