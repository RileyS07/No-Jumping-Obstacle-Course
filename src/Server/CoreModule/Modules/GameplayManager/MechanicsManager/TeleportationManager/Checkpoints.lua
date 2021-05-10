-- Variables
local checkpointsManager = {}
checkpointsManager.Remotes = {}
checkpointsManager.CurrentCheckpointUpdated = Instance.new("BindableEvent")

local coreModule = require(script:FindFirstAncestor("CoreModule"))
local userDataManager = require(coreModule.GetObject("Modules.GameplayManager.PlayerManager.UserDataManager"))
local badgeLibrary = require(coreModule.GetObject("Libraries.BadgeLibrary"))
local utilitiesLibrary = require(coreModule.Shared.GetObject("Libraries.Utilities"))
local badgeStorageLibrary = require(coreModule.Shared.GetObject("Libraries.BadgeStorage"))

-- Initialize
function checkpointsManager.Initialize()
	if not workspace.Map.Gameplay.LevelStorage:FindFirstChild("Checkpoints") then return end
	
	-- Setting up the checkpoints to be functional.
	for _, checkpointPlatform in next, workspace.Map.Gameplay.LevelStorage.Checkpoints:GetChildren() do

		-- Checkpoints have to be numbers or else they do not matter.
		if checkpointPlatform:IsA("BasePart") and tonumber(checkpointPlatform.Name) then
			checkpointPlatform.Touched:Connect(function(hit)
				local player = coreModule.Services.Players:GetPlayerFromCharacter(hit.Parent)
				if not utilitiesLibrary.IsPlayerAlive(player) then return end
				
				-- Update their Farthest and Current checkpoints.
				checkpointsManager.UpdateFarthestCheckpoint(player, tonumber(checkpointPlatform.Name))
				checkpointsManager.UpdateCurrentCheckpoint(player, tonumber(checkpointPlatform.Name))
			end)
		end
	end

	-- The client wants to teleport to a specific stage.
	coreModule.Shared.GetObject("//Remotes.Gameplay.Stages.TeleportToStage").OnServerEvent:Connect(function(player, checkpointNumber)
		if not typeof(checkpointNumber) ~= "number" then return end
		if not workspace.Map.Gameplay.LevelStorage.Checkpoints:FindFirstChild(checkpointNumber) then return end
		if not utilitiesLibrary.IsPlayerAlive(player) then return end
		if not userDataManager.GetData(player) then return end
		if userDataManager.GetData(player).UserInformation.FarthestCheckpoint < checkpointNumber then return end

		-- Update their Farthest and Current checkpoints.
		checkpointsManager.UpdateFarthestCheckpoint(player, checkpointNumber)
		checkpointsManager.UpdateCurrentCheckpoint(player, checkpointNumber)
	end)

	-- Setting up remotes + assets.
	checkpointsManager.Remotes.CheckpointInformationUpdated = coreModule.Shared.GetObject("//Remotes.Gameplay.Stages.CheckpointInformationUpdated")
	checkpointsManager.Remotes.PlaySoundEffect = coreModule.Shared.GetObject("//Remotes.Gameplay.Miscellaneous.PlaySoundEffect")
	checkpointsManager.Remotes.MakeSystemMessage = coreModule.Shared.GetObject("//Remotes.Gameplay.Miscellaneous.MakeSystemMessage")
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
	table.insert(userData.UserInformation.CompletedStages, checkpointNumber)
	checkpointsManager.Remotes.CheckpointInformationUpdated:FireClient(player, userData)
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
		checkpointsManager.Remotes.PlaySoundEffect:FireClient(player, "CheckpointTouched", {Parent = workspace.Map.Gameplay.LevelStorage.Checkpoints[checkpointNumber]})
		checkpointsManager.Remotes.PlaySoundEffect:FireClient(player, "Stage"..tostring(checkpointNumber))

		-- Backwards compatability for CompletedStages.
		if not table.find(userData.UserInformation.CompletedStages, checkpointNumber) then
			table.insert(userData.UserInformation.CompletedStages, checkpointNumber, math.min(checkpointNumber, #userData.UserInformation.CompletedStages))
		end
		
		-- Backwards compatibility for award trial badges.
		if checkpointNumber > 1 and checkpointNumber%10 == 1 then
			if badgeStorageLibrary.GetBadgeList("Trials") then
				badgeLibrary.AwardBadge(player, badgeStorageLibrary.GetBadgeList("Trials")[math.floor(checkpointNumber/10)])
			end
			
			checkpointsManager.Remotes.PlaySoundEffect:FireClient(player, "Clapping")
			checkpointsManager.Remotes.MakeSystemMessage:FireAllClients(player.Name.." has completed Trial "..tostring(math.floor(checkpointNumber/10)).."!")
		end
		
		checkpointsManager.Remotes.CheckpointInformationUpdated:FireClient(player, userData)
	end
end


--
return checkpointsManager