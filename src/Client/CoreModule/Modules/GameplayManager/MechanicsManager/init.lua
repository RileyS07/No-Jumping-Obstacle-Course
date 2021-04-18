-- Variables
local mechanicsManager = {}
local coreModule = require(script:FindFirstAncestor("CoreModule"))
local playerMouseLibrary = require(coreModule.GetObject("Libraries.UserInput.Mouse"))

-- Initialize
function mechanicsManager.Initialize()
	mechanicsManager.GetPlatformerMechanics()
	playerMouseLibrary.Initialize()

	-- Loading modules
	coreModule.LoadModule("/Buttons")
	coreModule.LoadModule("/ForcedCameraView")
	coreModule.LoadModule("/ManualSwitchPlatforms")
	coreModule.LoadModule("/MovingPlatforms")
	coreModule.LoadModule("/SpinningPlatforms")
	coreModule.LoadModule("/SwitchPlatforms")
end


-- Methods
function mechanicsManager.GetPlatformerMechanics()
	return workspace.Map.Gameplay:WaitForChild("PlatformerMechanics")
end


--
return mechanicsManager