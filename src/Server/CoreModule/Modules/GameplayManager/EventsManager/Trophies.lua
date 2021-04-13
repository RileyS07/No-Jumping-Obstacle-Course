-- Variables
local specificEventManager = {}
specificEventManager.Remotes = {}

local coreModule = require(script:FindFirstAncestor("CoreModule"))
local userDataManager = require(coreModule.GetObject("Modules.GameplayManager.PlayerManager.UserDataManager"))
local utilitiesLibrary = require(coreModule.Shared.GetObject("Libraries.Utilities"))

-- Initialize
function specificEventManager.Initialize()
	if not workspace.Map.Gameplay.EventStorage:FindFirstChild(script.Name) then return end

	-- Setup; Better than a GetObject call everytime they touch a new trophy.
	specificEventManager.Remotes.TrophyCollected = coreModule.Shared.GetObject("//Remotes.Gameplay.Events.TrophyCollected")
	
	-- Setting up the Trophies to be collectable.
	for _, tropyObject in next, workspace.Map.Gameplay.EventStorage.Trophies:GetChildren() do
		if tropyObject:IsA("BasePart") then

			-- Trophies will be collected when touched, if possible.
			tropyObject.Touched:Connect(function(hit)

				-- Guard clauses to make sure the player is alive, valid, and their data exists.
				local player = coreModule.Services.Players:GetPlayerFromCharacter(hit.Parent)
				if not utilitiesLibrary.IsPlayerAlive(player) then return end
				if not userDataManager.GetData(player) then return end
				
				local userData = userDataManager.GetData(player)
				local userEventInformation = userData.UserEventInformation

				-- Create the default data for the event if it doesn't exist.
				if not userEventInformation.Trophy_Event then
					userEventInformation.Trophy_Event = {
						Name = "Trophy_Event",
						Description = "Collect 10 trophies scattered around the map!",
						Completed = false,
						Progress = 0,
						
						-- Event Specific
						TrophiesCollected = {}
					}
				end
				
				-- Data evaluation + updating if possible.
				specificEventManager.ValidateEventData(player)
				if not table.find(userEventInformation.Trophy_Event.TrophiesCollected, tropyObject.Name) then
					table.insert(userEventInformation.Trophy_Event.TrophiesCollected, tropyObject.Name)
					specificEventManager.Remotes.TrophyCollected:FireClient(player, tropyObject)
				end
			end)
		end
	end
end


-- Methods
function specificEventManager.ValidateEventData(player)
	
	-- Guard clauses to make sure the player is valid, their data exists, and is in a format we can use.
	if not utilitiesLibrary.IsValidPlayer(player) then return end
	if not userDataManager.GetData(player) then return end
	if not userDataManager.GetData(player).UserEventInformation.Trophy_Event then return end
	
	local userData = userDataManager.GetData(player)
	local userEventInformation = userData.UserEventInformation

	-- Checking to see if the trophies saved in data are still valid.
	for index = #userEventInformation.Trophy_Event.TrophiesCollected, 1, -1 do

		-- If they aren't then we remove them.
		if not workspace.Map.Gameplay.EventStorage[script.Name]:FindFirstChild(userEventInformation.Trophy_Event.TrophiesCollected[index]) then
			table.remove(userEventInformation.Trophy_Event.TrophiesCollected, index)
		end
	end
end


--
return specificEventManager