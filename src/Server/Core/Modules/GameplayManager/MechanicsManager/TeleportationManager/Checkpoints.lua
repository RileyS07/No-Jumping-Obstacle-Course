-- Variables
local checkpointsManager = {}
checkpointsManager.Remotes = {}
checkpointsManager.CurrentCheckpointUpdated = Instance.new("BindableEvent")

local coreModule = require(script:FindFirstAncestor("Core"))
local userDataManager = require(coreModule.GetObject("Modules.GameplayManager.PlayerManager.UserDataManager"))
local teleportationManager = require(coreModule.GetObject("Modules.GameplayManager.MechanicsManager.TeleportationManager"))
local badgeLibrary = require(coreModule.GetObject("Libraries.BadgeLibrary"))
local utilitiesLibrary = require(coreModule.Shared.GetObject("Libraries.Utilities"))
local badgeStorageLibrary = require(coreModule.Shared.GetObject("Libraries.BadgeStorage"))

-- Initialize
function checkpointsManager.Initialize()
	if not workspace.Map.Gameplay.LevelStorage:FindFirstChild("Checkpoints") then return end

	-- Setting up remotes + assets.
	checkpointsManager.Remotes.CheckpointInformationUpdated = coreModule.Shared.GetObject("//Remotes.Gameplay.Stages.CheckpointInformationUpdated")
	checkpointsManager.Remotes.PlaySoundEffect = coreModule.Shared.GetObject("//Remotes.Gameplay.Miscellaneous.PlaySoundEffect")
	checkpointsManager.Remotes.MakeSystemMessage = coreModule.Shared.GetObject("//Remotes.Gameplay.Miscellaneous.MakeSystemMessage")

	-- Setting up the checkpoints to be functional.
	for _, checkpointPlatform in next, workspace.Map.Gameplay.LevelStorage.Checkpoints:GetChildren() do

		-- Checkpoints have to be numbers or else they do not matter.
		if checkpointPlatform:IsA("BasePart") and tonumber(checkpointPlatform.Name) then
			checkpointPlatform.Touched:Connect(function(hit)
				local player = game:GetService("Players"):GetPlayerFromCharacter(hit.Parent)
				if not utilitiesLibrary.IsPlayerAlive(player) then return end

				-- Update their Farthest and Current checkpoints.
				checkpointsManager.UpdateFarthestCheckpoint(player, tonumber(checkpointPlatform.Name))
				checkpointsManager.UpdateCurrentCheckpoint(player, tonumber(checkpointPlatform.Name))
			end)
		end
	end

	-- The client wants to teleport to a specific stage.
	coreModule.Shared.GetObject("//Remotes.Gameplay.Stages.TeleportToStage").OnServerEvent:Connect(function(player, checkpointNumber)
		if typeof(checkpointNumber) ~= "number" then return end
		if not workspace.Map.Gameplay.LevelStorage.Checkpoints:FindFirstChild(checkpointNumber) then return end
		if not utilitiesLibrary.IsPlayerAlive(player) then return end
		if not userDataManager.GetData(player) then return end
		if userDataManager.GetData(player).UserInformation.FarthestCheckpoint < checkpointNumber then return end

		-- Update their Farthest and Current checkpoints.
		checkpointsManager.UpdateFarthestCheckpoint(player, checkpointNumber)
		checkpointsManager.UpdateCurrentCheckpoint(player, checkpointNumber)
		teleportationManager.TeleportPlayer(player)
	end)
end


-- Methods
-- Updates the farthest checkpoint a user has ever reached is possible.
function checkpointsManager.UpdateFarthestCheckpoint(player, checkpointNumber)
	if not utilitiesLibrary.IsPlayerValid(player) then return end
	if not userDataManager.GetData(player) then return end

	-- FarthestCheckpoint cannot regress.
	if userDataManager.GetData(player).UserInformation.FarthestCheckpoint >= checkpointNumber then return end

	-- Update their data to match their new farthest checkpoint.
	local userData = userDataManager.GetData(player)
	userData.UserInformation.FarthestCheckpoint = checkpointNumber
	checkpointsManager.Remotes.CheckpointInformationUpdated:FireClient(player, userData)

	-- Did they just finish the game???
	if checkpointNumber == 101 then
		checkpointsManager.Remotes.MakeSystemMessage:FireAllClients(player.Name .. " has just beat No Jumping Zone!")
	end
end


-- Updates the current checkpoint the user is at as long as everything is valid.
function checkpointsManager.UpdateCurrentCheckpoint(player, checkpointNumber)
	if not utilitiesLibrary.IsPlayerValid(player) then return end
	if not userDataManager.GetData(player) then return end

	-- This should be impossible but I still have it here just in case.
	if userDataManager.GetData(player).UserInformation.FarthestCheckpoint < checkpointNumber then return end

	-- Update their data to match their new current checkpoint.
	local userData = userDataManager.GetData(player)
	local originalCurrentCheckpoint = userData.UserInformation.CurrentCheckpoint
	userData.UserInformation.CurrentCheckpoint = checkpointNumber
	userData.UserInformation.CurrentBonusStage = ""

	-- Backwards compatibility for things like badges and CompletedStages.
	if originalCurrentCheckpoint ~= userData.UserInformation.CurrentCheckpoint then
		checkpointsManager.CurrentCheckpointUpdated:Fire(player, originalCurrentCheckpoint, userData.UserInformation.CurrentCheckpoint)
		checkpointsManager.Remotes.PlaySoundEffect:FireClient(player, "CheckpointTouched")--, {Parent = workspace.Map.Gameplay.LevelStorage.Checkpoints[checkpointNumber]})
		checkpointsManager.Remotes.PlaySoundEffect:FireClient(player, "Stage"..tostring(checkpointNumber))

		-- Backwards compatibility for award trial badges.
		if checkpointNumber > 1 and checkpointNumber%10 == 1 then
			if badgeStorageLibrary.GetBadgeList("Trials") then
				badgeLibrary.AwardBadge(player, badgeStorageLibrary.GetBadgeList("Trials")[math.floor(checkpointNumber/10)])
			end

			-- Fixing their data.
			userData.UserInformation.CompletedStages = checkpointsManager._CorrectCompletedStagesArray(userData.UserInformation.CompletedStages)

			if not table.find(userData.UserInformation.CompletedStages, checkpointNumber) then
				table.insert(userData.UserInformation.CompletedStages, checkpointNumber)
				checkpointsManager.Remotes.PlaySoundEffect:FireClient(player, "Clapping")
				checkpointsManager.Remotes.MakeSystemMessage:FireAllClients(player.Name.." has completed Trial "..tostring(math.floor(checkpointNumber/10)).."!")
			end
		end

		checkpointsManager.Remotes.CheckpointInformationUpdated:FireClient(player, userData)
	end

	-- Backwards compatability for CompletedStages.
	if not table.find(userData.UserInformation.CompletedStages, checkpointNumber) then
		table.insert(userData.UserInformation.CompletedStages, checkpointNumber)
	end
end

-- Corrects CompletedStages.
function checkpointsManager._CorrectCompletedStagesArray(completedStagesArray: {}) : {}

	local newCompletedStagesArray: {} = {}

	for _, stageNumber: number in next, completedStagesArray do
		if tonumber(stageNumber) and not table.find(newCompletedStagesArray, tonumber(stageNumber)) then
			table.insert(newCompletedStagesArray, tonumber(stageNumber))
		end
	end

	-- Sorting it.
	table.sort(newCompletedStagesArray, function(stageNumberA: number, stageNumberB: number)
		return stageNumberA < stageNumberB
	end)

	return newCompletedStagesArray
end

--
return checkpointsManager