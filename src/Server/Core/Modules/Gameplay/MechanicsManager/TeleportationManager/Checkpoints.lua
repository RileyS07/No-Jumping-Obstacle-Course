local players: Players = game:GetService("Players")

local coreModule = require(script:FindFirstAncestor("Core"))
local userDataManager = require(coreModule.GetObject("Modules.Gameplay.PlayerManager.UserDataManager"))
local teleportationManager = require(coreModule.GetObject("Modules.Gameplay.MechanicsManager.TeleportationManager"))
local badgeService = require(coreModule.Shared.GetObject("Libraries.Services.BadgeService"))
local playerUtilities = require(coreModule.Shared.GetObject("Libraries.Utilities.PlayerUtilities"))
local badgeList = require(coreModule.Shared.GetObject("Libraries.BadgeList"))
local zoneNames = require(coreModule.Shared.GetObject("Libraries.ZoneNames"))
local sharedConstants = require(coreModule.Shared.GetObject("Libraries.SharedConstants"))
local signal = require(coreModule.Shared.GetObject("Libraries.Signal"))

local checkpointInformationUpdatedRemote: RemoteEvent = coreModule.Shared.GetObject("//Remotes.Gameplay.Stages.CheckpointInformationUpdated")
local playSoundEffectRemote: RemoteEvent = coreModule.Shared.GetObject("//Remotes.Gameplay.Miscellaneous.PlaySoundEffect")
local makeSystemMessageRemote: RemoteEvent = coreModule.Shared.GetObject("//Remotes.Gameplay.Miscellaneous.MakeSystemMessage")
local teleportToStageRemote: RemoteEvent = coreModule.Shared.GetObject("//Remotes.Gameplay.Stages.TeleportToStage")
local thisPlatformContainer: Instance? = workspace.Map.Gameplay.LevelStorage:FindFirstChild("Checkpoints")

local CheckpointsManager = {}
CheckpointsManager.CurrentCheckpointUpdated = signal.new()

-- Initialize
function CheckpointsManager.Initialize()
	if not thisPlatformContainer then return end

	-- Every descendant that is a BasePart of this collection will respawn them.
	for _, thisPlatform: Instance in next, (thisPlatformContainer :: Instance):GetDescendants() do

		if thisPlatform:IsA("BasePart") and tonumber(thisPlatform.Name) then
			thisPlatform.Touched:Connect(function(hit: BasePart)

				local player: Player? = players:GetPlayerFromCharacter(hit.Parent)
				if not playerUtilities.IsPlayerAlive(player) then return end

				-- Update their Farthest and Current checkpoints.
				CheckpointsManager.UpdateFarthestCheckpoint(player, tonumber(thisPlatform.Name))
				CheckpointsManager.UpdateCurrentCheckpoint(player, tonumber(thisPlatform.Name))
			end)
		end
	end

	-- The client wants to teleport to a specific stage.
	-- We need make sure they've even reached this point.
	teleportToStageRemote.OnServerEvent:Connect(function(player: Player, checkpointNumber: number?)

		-- If these are invalid something has gone horrible wrong.
		if not playerUtilities.IsPlayerAlive(player) then return end
		if not userDataManager.GetData(player) then return end

		-- We need to make sure the number is correct.
		if typeof(checkpointNumber) ~= "number" then return end
		if math.floor(checkpointNumber) ~= checkpointNumber then return end

		-- Does this checkpoint even exist and have they reached this point?
		if not thisPlatformContainer:FindFirstChild(checkpointNumber) then return end
		if userDataManager.GetData(player).UserInformation.FarthestCheckpoint < checkpointNumber then return end

		-- Update their Farthest and Current checkpoints.
		CheckpointsManager.UpdateFarthestCheckpoint(player, checkpointNumber)
		CheckpointsManager.UpdateCurrentCheckpoint(player, checkpointNumber)
		teleportationManager.TeleportPlayer(player)
	end)
end

-- Updates the current checkpoint the user is at as long as everything is valid.
-- This is the checkpoint they will teleport to when they respawn.
function CheckpointsManager.UpdateCurrentCheckpoint(player: Player, checkpointNumber: number)

	if not playerUtilities.IsPlayerValid(player) then return end
	if not userDataManager.GetData(player) then return end

	-- This should be impossible but I still have it here just in case.
	if userDataManager.GetData(player).UserInformation.FarthestCheckpoint < checkpointNumber then return end

	-- We keep track of this so we aren't spamming remotes and such.
	local userData: {} = userDataManager.GetData(player)
	local originalCurrentCheckpoint: number = userData.UserInformation.CurrentCheckpoint

	-- Update their data to match their new current checkpoint.
	userData.UserInformation.CurrentCheckpoint = checkpointNumber
	userData.UserInformation.CurrentBonusStage = ""

	-- Backwards compatibility for things like badges and CompletedStages.
	if originalCurrentCheckpoint ~= userData.UserInformation.CurrentCheckpoint then

		-- We can fire the bindable and try to play any sound effects related.
		CheckpointsManager.CurrentCheckpointUpdated:Fire(player, originalCurrentCheckpoint, userData.UserInformation.CurrentCheckpoint)
		playSoundEffectRemote:FireClient(player, "CheckpointTouched")
		playSoundEffectRemote:FireClient(player, "Stage" .. tostring(checkpointNumber))

		-- Backwards compatibility for award trial badges.
		if checkpointNumber > 1 and checkpointNumber % 10 == 1 then

			local trialNumber: number = math.floor(checkpointNumber / 10)

			-- Can we award a badge for this?
			if badgeList.Trials[trialNumber] then
				badgeService.AwardBadge(player, badgeList.Trials[trialNumber])
			end

			-- We add this to the list so we only show the message once.
			if not table.find(userData.UserInformation.CompletedStages, checkpointNumber) then

				table.insert(userData.UserInformation.CompletedStages, checkpointNumber)

				-- We want the clapping to play for just them and then the message for everyone.
				playSoundEffectRemote:FireClient(player, "Clapping")
				makeSystemMessageRemote:FireAllClients(string.format(
					sharedConstants.FORMATS.TRIAL_COMPLETION_MESSAGE_FORMAT,
					player.Name,
					zoneNames[trialNumber] or "???"
				))
			end
		end

		-- Informing the client we have updated their data.
		checkpointInformationUpdatedRemote:FireClient(player, userData)
	end

	-- Backwards compatability for CompletedStages.
	-- Apparently we need to make sure it isn't a trial or else it'll be overwritten and our effects won't show.
	if checkpointNumber == 1 or checkpointNumber % 10 ~= 1 then
		if not table.find(userData.UserInformation.CompletedStages, checkpointNumber) then
			table.insert(userData.UserInformation.CompletedStages, checkpointNumber)
		end
	end

	-- Backwards compatability for No-Jumping-Zone-Completionist.
	if checkpointNumber == 101 then
		badgeService.AwardBadge(player, 2125036729)
	end
end

-- Updates the farthest checkpoint a user has ever reached is possible.
-- This is mainly used for visual purposes.
function CheckpointsManager.UpdateFarthestCheckpoint(player: Player, checkpointNumber: number)

	if not playerUtilities.IsPlayerValid(player) then return end
	if not userDataManager.GetData(player) then return end

	-- FarthestCheckpoint cannot regress.
	if userDataManager.GetData(player).UserInformation.FarthestCheckpoint >= checkpointNumber then return end

	-- Update their data to match their new farthest checkpoint.
	local userData: {} = userDataManager.GetData(player)
	userData.UserInformation.FarthestCheckpoint = checkpointNumber
	checkpointInformationUpdatedRemote:FireClient(player, userData)

	-- Did they just finish the game???
	if checkpointNumber == 101 then

		-- We want a little delay so it shows up after the trial completion message,
		task.delay(0.5, function()
			makeSystemMessageRemote:FireAllClients(string.format(
				sharedConstants.FORMATS.EXPERIENCE_COMPLETION_MESSAGE_FORMAT,
				player.Name
			))
		end)
	end
end

return CheckpointsManager
