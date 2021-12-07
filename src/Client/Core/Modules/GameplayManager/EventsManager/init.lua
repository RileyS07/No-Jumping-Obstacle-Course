-- Variables
local eventsManager = {}
local coreModule = require(script:FindFirstAncestor("Core"))

-- Initialize
function eventsManager.Initialize()
	workspace.Map.Gameplay:WaitForChild("EventStorage")
	
	-- Loading modules
	coreModule.LoadModule("/Trophies")
end

--
return eventsManager