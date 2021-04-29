-- Variables
local mechanicsManager = {}
local coreModule = require(script:FindFirstAncestor("CoreModule"))

-- Initialize
function mechanicsManager.Initialize()
	if not workspace.Map.Gameplay:FindFirstChild("PlatformerMechanics") then return end

	-- Loading modules
	coreModule.LoadModule("/PowerupsManager")
	coreModule.LoadModule("/TeleportationManager")
	coreModule.LoadModule("/DamagePlatforms")
	coreModule.LoadModule("/HealingPlatforms")
	coreModule.LoadModule("/JumpPlatforms")
	coreModule.LoadModule("/StageInformationManager")
end


--
return mechanicsManager