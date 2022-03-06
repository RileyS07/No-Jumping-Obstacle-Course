local players: Players = game:GetService("Players")

local coreModule = require(script:FindFirstAncestor("Core"))
local eventManager = require(coreModule.GetObject("Modules.Gameplay.EventsManager"))
local userDataManager = require(coreModule.GetObject("Modules.Gameplay.PlayerManager.UserDataManager"))
local badgeService = require(coreModule.Shared.GetObject("Libraries.Services.BadgeService"))
local instanceUtilities = require(coreModule.Shared.GetObject("Libraries.Utilities.InstanceUtilities"))
local playerUtilities = require(coreModule.Shared.GetObject("Libraries.Utilities.PlayerUtilities"))

local thisEventStorage: Instance? = workspace.Map.Gameplay.EventStorage:FindFirstChild(script.Name)
local collectableInstances: {Instance} = instanceUtilities.GetChildrenWhichAre(thisEventStorage, "BasePart")
local eventItemCollectedRemote: RemoteEvent = coreModule.Shared.GetObject("//Remotes.Gameplay.Events.EventItemCollected")
local playSoundEffectRemote: RemoteEvent = coreModule.Shared.GetObject("//Remotes.PlaySoundEffect")
local makeSystemMessageRemote: RemoteEvent = coreModule.Shared.GetObject("//Remotes.MakeSystemMessage")

local ThisEventManager = {}

-- Initialize
function ThisEventManager.Initialize()
	if not thisEventStorage then return end

	-- Setting up the Trophies to be collectable.
	for _, trophy: BasePart in next, collectableInstances do
		trophy.Touched:Connect(function(hit: BasePart)

			-- Guard clauses to make sure the player is alive, valid, and their data exists.
			local player: Player? = players:GetPlayerFromCharacter(hit.Parent)
			if not playerUtilities.IsPlayerAlive(player) then return end
			if not userDataManager.GetData(player) then return end

			-- It's a valid player so let's update their data!
			player = player :: Player
			local userData = userDataManager.GetData(player)
			local userEventInformation = userData.UserEventInformation

			-- We evaluate before any updates to maintain backwards compatability.
			ThisEventManager.ValidateEventData(player)

			-- Data evaluation + updating if possible.
			if not table.find(userEventInformation[script.Name].TrophiesCollected, trophy.Name) then

				table.insert(userEventInformation[script.Name].TrophiesCollected, trophy.Name)
				eventItemCollectedRemote:FireClient(player, trophy)
				ThisEventManager.ValidateEventData(player)
			end
		end)
	end
end

-- This function preserves event data integrity. Removing trophies that do not exist.
function ThisEventManager.ValidateEventData(player: Player)

	local userData: {} = userDataManager.GetData(player)

	-- Does this event information exist?
	if not userData.UserEventInformation[script.Name] then

		-- Creating the default information.
		local eventInformation: {} = eventManager.CreateEventInformation(
			"Trophy Scavenger Hunt",
			"Collect " .. tostring(#collectableInstances) .. " trophied scattered around the map!",
			true
		)

		-- Creating custom information.
		-- Besides ProgressText, it is not custom.
		eventInformation.TrophiesCollected = {}
		eventInformation.ProgressText = tostring(#eventInformation.TrophiesCollected) .. " out of " .. tostring(#collectableInstances)

		userData.UserEventInformation[script.Name] = eventInformation
	end

	local eventInformation: {} = userData.UserEventInformation[script.Name]

	-- Checking to see if the trophies saved in data are still valid.
	for index = #eventInformation.TrophiesCollected, 1, -1 do

		-- If they aren't then we remove them.
		if not thisEventStorage:FindFirstChild(eventInformation.TrophiesCollected[index]) then
			table.remove(eventInformation.TrophiesCollected, index)
		end
	end

	-- Updating their progress.
	eventInformation.Progress = #eventInformation.TrophiesCollected / #collectableInstances
	eventInformation.ProgressText = tostring(#eventInformation.TrophiesCollected) .. " out of " .. tostring(#collectableInstances)

	-- Did they just complete it?
	if #eventInformation.TrophiesCollected == #collectableInstances and not eventInformation.Completed then
		eventInformation.Completed = true

		-- We do this in here so that we can back track.
		badgeService.AwardBadge(player, 2124575093)
		playSoundEffectRemote:FireClient(player, "Clapping")
		makeSystemMessageRemote:FireClient(player, player.Name .. " has finished the " .. eventInformation.Name .. "!")
	end
end

return ThisEventManager
