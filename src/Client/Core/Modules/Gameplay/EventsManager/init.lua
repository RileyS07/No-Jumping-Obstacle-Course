local coreModule = require(script:FindFirstAncestor("Core"))

local EventsManager = {}

-- Initialize
function EventsManager.Initialize()
	workspace.Map.Gameplay:WaitForChild("EventStorage")

	coreModule.LoadModule("/")
end

return EventsManager
