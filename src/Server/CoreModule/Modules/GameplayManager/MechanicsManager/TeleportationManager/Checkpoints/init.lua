-- Variables
local checkpointsManager = {}
local coreModule = require(script:FindFirstAncestor("CoreModule"))
local userDataManager = require(coreModule.GetObject("Modules.GameplayManager.PlayerManager.UserDataManager"))
local badgeLibrary = require(coreModule.GetObject("Libraries.BadgeLibrary"))
local utilitiesLibrary = require(coreModule.Shared.GetObject("Libraries.Utilities"))
local badgeConfig = require(script.Badges)

-- Initialize
function checkpointsManager.Initialize()
	if not workspace.Map.Gameplay.PlatformerMechanics:FindFirstChild("Checkpoints") then return end
	
	-- Setup
	for _, checkpointPlatform in next, workspace.Map.Gameplay.PlatformerMechanics.Checkpoints:GetChildren() do
		if checkpointPlatform:IsA("BasePart") and tonumber(checkpointPlatform.Name) then	-- The data requires them to be numbers or else uh oh
			checkpointPlatform.Touched:Connect(function(hit)
				local player = coreModule.Services.Players:GetPlayerFromCharacter(hit.Parent)
				if not utilitiesLibrary.IsPlayerAlive(player) then return end
				
				--
				checkpointsManager.UpdateFarthestCheckpoint(player, tonumber(checkpointPlatform.Name))
				checkpointsManager.UpdateCurrentCheckpoint(player, tonumber(checkpointPlatform.Name))
			end)
		end
	end
end

-- Methods
function checkpointsManager.UpdateFarthestCheckpoint(player, checkpointNumber)
	local userData = userDataManager.GetData(player)
	if userData.UserInformation.FarthestCheckpoint >= checkpointNumber then return end	-- Can't beat what you've already beaten

	-- Update data
	userData.UserInformation.FarthestCheckpoint = checkpointNumber
	table.insert(userData.UserInformation.CompletedStages, checkpointNumber)
	coreModule.Shared.GetObject("//Remotes.Gameplay.Stages.CheckpointInformationUpdated"):FireClient(player, userData)
end


function checkpointsManager.UpdateCurrentCheckpoint(player, checkpointNumber)
	local userData = userDataManager.GetData(player)
	if userData.UserInformation.FarthestCheckpoint < checkpointNumber then return end	-- This is impossible
	
	-- Setup
	local originalCurrentCheckpoint = userData.UserInformation.CurrentCheckpoint
	userData.UserInformation.CurrentCheckpoint = checkpointNumber
	userData.UserInformation.SpecialLocationIdentifier = coreModule.Shared.Enums.SpecialLocation.None
	
	-- This is so it doesn't spam remote/api calls
	if originalCurrentCheckpoint ~= userData.UserInformation.CurrentCheckpoint then
		coreModule.Shared.GetObject("//Remotes.Gameplay.Miscellaneous.PlaySoundEffect"):FireClient(player, "CheckpointTouched", {Parent = workspace.Map.Gameplay.PlatformerMechanics.Checkpoints[checkpointNumber]})
		
		-- Backwards compatability for CompletedStages
		if not table.find(userData.UserInformation.CompletedStages, checkpointNumber) then
			table.insert(userData.UserInformation.CompletedStages, checkpointNumber, math.min(checkpointNumber, #userData.UserInformation.CompletedStages))
		end
		
		-- Awarding players for completing a trial level
		if checkpointNumber > 1 and checkpointNumber%10 == 1 then
			badgeLibrary.AwardBadge(player, badgeConfig.TrialBadges[math.floor(checkpointNumber/10)])
		end
		
		-- If they're the same then UpdateFarthestCheckpoint has already made the remote call
		if userData.UserInformation.CurrentCheckpoint ~= userData.UserInformation.FarthestCheckpoint then
			coreModule.Shared.GetObject("//Remotes.Gameplay.Stages.CheckpointInformationUpdated"):FireClient(player, userData)
		end
	end
end


--
return checkpointsManager