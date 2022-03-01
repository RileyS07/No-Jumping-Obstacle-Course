local coreModule = require(script:FindFirstAncestor("Core"))

local MechanicsManager = {}

-- Initialize
function MechanicsManager.Initialize()
	coreModule.LoadModule("/")
end

return MechanicsManager
