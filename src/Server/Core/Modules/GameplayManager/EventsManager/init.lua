-- Variables
local eventsManager = {}
local coreModule = require(script:FindFirstAncestor("CoreModule"))

-- Initialize
function eventsManager.Initialize()
	if not workspace.Map.Gameplay:FindFirstChild("EventStorage") then return end
	
	-- Loading Modules
	coreModule.LoadModule("/Trophies")
end


--
return eventsManager