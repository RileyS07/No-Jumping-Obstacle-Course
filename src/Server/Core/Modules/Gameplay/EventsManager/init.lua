local coreModule = require(script:FindFirstAncestor("Core"))

local EventsManager = {}

-- Initialize
function EventsManager.Initialize()

	coreModule.LoadModule("/")
end

-- Creates the default event information.
function EventsManager.CreateEventInformation(eventName: string, eventDescription: string, isProgressBound: boolean) : {}
	return {
		Name = eventName,
		Completed = false,
		Description = eventDescription,
		IsProgressBound = isProgressBound,
		Progress = 0,
		ProgressText = ""
	}
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
