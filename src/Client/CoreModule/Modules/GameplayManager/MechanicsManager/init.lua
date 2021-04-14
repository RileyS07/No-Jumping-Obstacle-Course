-- Variables
local mechanicsManager = {}
local coreModule = require(script:FindFirstAncestor("CoreModule"))

-- Initialize
function mechanicsManager.Initialize()
	mechanicsManager.GetPlatformerMechanics()
	
	-- Loading modules
	coreModule.LoadModule("/Buttons")
	coreModule.LoadModule("/MovingPlatforms")
	coreModule.LoadModule("/SpinningPlatforms")
end


-- Methods
function mechanicsManager.GetPlatformerMechanics()
	return workspace.Map.Gameplay:WaitForChild("PlatformerMechanics")
end


--
return mechanicsManager