-- Variables
local mechanicsManager = {}
local coreModule = require(script:FindFirstAncestor("CoreModule"))

-- Initialize
function mechanicsManager.Initialize()
	if not workspace.Map.Gameplay:FindFirstChild("PlatformerMechanics") then return end
	coreModule.LoadModule("/TeleportationManager")
end

--
return mechanicsManager