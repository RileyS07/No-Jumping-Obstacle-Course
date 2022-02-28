local coreModule = require(script:FindFirstAncestor("Core"))

local EventsManager = {}

-- Initialize
function EventsManager.Initialize()

	coreModule.LoadModule("/")
end

-- Validates all event data possible for this player.
function EventsManager.ValidateAllEventData(player: Player)
	for _, moduleScript: Instance in next, script:GetChildren() do
		if moduleScript:IsA("ModuleScript") then
			require(moduleScript).ValidateEventData(player)
		end
	end
end

return EventsManager
