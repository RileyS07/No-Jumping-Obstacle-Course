-- Variables
local mechanicsManager = {}
local coreModule = require(script:FindFirstAncestor("CoreModule"))

-- Initialize
function mechanicsManager.Initialize()
	workspace.Map.Gameplay:WaitForChild("PlatformerMechanics")
	
	-- Loading modules
	coreModule.LoadModule("/Buttons")
end

--
return mechanicsManager