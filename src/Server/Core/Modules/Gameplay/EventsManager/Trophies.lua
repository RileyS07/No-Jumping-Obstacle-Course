local players: Players = game:GetService("Players")

local coreModule = require(script:FindFirstAncestor("Core"))
local userDataManager = require(coreModule.GetObject("Modules.Gameplay.PlayerManager.UserDataManager"))
local badgeService = require(coreModule.Shared.GetObject("Libraries.Services.BadgeService"))
local instanceUtilities = require(coreModule.Shared.GetObject("Libraries.Utilities.InstanceUtilities"))
local playerUtilities = require(coreModule.Shared.GetObject("Libraries.Utilities.PlayerUtilities"))

local thisEventStorage: Instance = workspace.Map.Gameplay.EventStorage.Trophies
local collectableTrophies: {Instance} = instanceUtilities.GetChildrenWhichAre(thisEventStorage, "BasePart")
local trophyCollectedRemote: RemoteEvent = coreModule.Shared.GetObject("//Remotes.Gameplay.Events.TrophyCollected")
local playSoundEffectRemote: RemoteEvent = coreModule.Shared.GetObject("//Remotes.Gameplay.Miscellaneous.PlaySoundEffect")
local makeSystemMessageRemote: RemoteEvent = coreModule.Shared.GetObject("//Remotes.Gameplay.Miscellaneous.MakeSystemMessage")

local ThisEventManager = {}

-- Initialize
function ThisEventManager.Initialize()
	if not workspace.Map.Gameplay.EventStorage:FindFirstChild(script.Name) then return end

	-- Setting up the Trophies to be collectable.
	for _, trophy: BasePart in next, collectableTrophies do
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
			if not table.find(userEventInformation.Trophy_Event.TrophiesCollected, trophy.Name) then

				table.insert(userEventInformation.Trophy_Event.TrophiesCollected, trophy.Name)
				trophyCollectedRemote:FireClient(player, trophy)
				ThisEventManager.ValidateEventData(player)
			end
		end)
	end
end

-- This function preserves event data integrity. Removing trophies that do not exist.
function ThisEventManager.ValidateEventData(player: Player)

	local userData: {} = userDataManager.GetData(player)
	local eventInformation: {} = userData.UserEventInformation.Trophy_Event or {}
	userData.UserEventInformation.Trophy_Event = eventInformation

	-- Making sure the data is up to date.
	eventInformation.Name = "Trophy Scavenger Hunt"
	eventInformation.Description = "Collect " .. tostring(#collectableTrophies) .. " scattered around the map!"
	eventInformation.IsProgressBound = true
	eventInformation.Completed = not not eventInformation.Completed
	eventInformation.TrophiesCollected = eventInformation.TrophiesCollected or {}

	-- Checking to see if the trophies saved in data are still valid.
	for index = #eventInformation.TrophiesCollected, 1, -1 do

		-- If they aren't then we remove them.
		if not thisEventStorage:FindFirstChild(eventInformation.TrophiesCollected[index]) then
			table.remove(eventInformation.TrophiesCollected, index)
		end
	end

	-- Updating their progress.
	eventInformation.Progress = #eventInformation.TrophiesCollected / #collectableTrophies
	eventInformation.ProgressText = tostring(#eventInformation.TrophiesCollected) .. " out of " .. tostring(#collectableTrophies)

	-- Did they just complete it?
	if #eventInformation.TrophiesCollected == #collectableTrophies and not eventInformation.Completed then
		eventInformation.Completed = true

		-- We do this in here so that we can back track.
		badgeService.AwardBadge(player, 2124575093)
		playSoundEffectRemote:FireClient(player, "Clapping")
		makeSystemMessageRemote:FireClient(player, player.Name .. " has finished the Trophy event!")
	end
end

return ThisEventManager
