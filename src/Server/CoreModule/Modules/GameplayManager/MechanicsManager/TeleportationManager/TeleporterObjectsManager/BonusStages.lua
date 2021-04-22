-- Variables
local bonusStagesManager = {}
bonusStagesManager.Assets = {}
bonusStagesManager.Remotes = {}

local coreModule = require(script:FindFirstAncestor("CoreModule"))
local teleporterObjectsManager = require(coreModule.GetObject("/Parent"))
local teleportationManager = require(coreModule.GetObject("/Parent.Parent"))
local userDataManager = require(coreModule.GetObject("Modules.GameplayManager.PlayerManager.UserDataManager"))
local badgeLibrary = require(coreModule.GetObject("Libraries.BadgeLibrary"))
local utilitiesLibrary = require(coreModule.Shared.GetObject("Libraries.Utilities"))
local badgeStorageLibrary = require(coreModule.Shared.GetObject("Libraries.BadgeStorage"))

-- Initialize
function bonusStagesManager.Initialize()
	if not teleporterObjectsManager.GetTeleportersContainer():FindFirstChild("BonusStages") then return end
	if not workspace.Map.Gameplay:FindFirstChild("LevelStorage") or not workspace.Map.Gameplay.LevelStorage:FindFirstChild("BonusStages") then return end
	bonusStagesManager.Assets.BonusStageTeleporterInterface = coreModule.Shared.GetObject("//Assets.Interfaces.BonusStageTeleporterInterface")
	bonusStagesManager.Remotes.CheckpointInformationUpdated = coreModule.Shared.GetObject("//Remotes.Gameplay.Stages.CheckpointInformationUpdated")
	bonusStagesManager.Remotes.PlaySoundEffect = coreModule.Shared.GetObject("//Remotes.Gameplay.Miscellaneous.PlaySoundEffect")

	-- Setting up the teleporters.
	for _, teleporterObject in next, teleporterObjectsManager.GetTeleportersContainer().BonusStages:GetChildren() do
		
		-- PrimaryPart is what the players will touch and what we'll put the gui into; We also have to make sure the level even exists.
		if teleporterObject:IsA("Model") and teleporterObject.PrimaryPart and workspace.Map.Gameplay.LevelStorage.BonusStages:FindFirstChild(teleporterObject.Name) then
			local bonusStageLevelReference = workspace.Map.Gameplay.LevelStorage.BonusStages:FindFirstChild(teleporterObject.Name)

			-- Setting up the teleporter with the BonusStageTeleporterInterface; I do this procedurally so that it's easy for us to make changes to it.
			if bonusStagesManager.Assets.BonusStageTeleporterInterface then
				local bonusStageTeleporterInterfaceClone = bonusStagesManager.Assets.BonusStageTeleporterInterface:Clone()
				
				-- Author, BackgroundImage, Title.
				bonusStageTeleporterInterfaceClone.Container.BackgroundImage.Image = bonusStageLevelReference:GetAttribute("BackgroundImage") or "http://www.roblox.com/asset/?id=5632150459"
				bonusStageTeleporterInterfaceClone.Container.Content.Author.Text = bonusStageLevelReference:GetAttribute("Author") or "???"
				bonusStageTeleporterInterfaceClone.Container.Content.Title.Text = teleporterObject.Name

				-- Difficulty; 1 star = 1 level of difficulty.
				for index = 1, math.max(bonusStageLevelReference:GetAttribute("Difficulty") or 1) - 1 do
					bonusStageTeleporterInterfaceClone.Container.Content.StarContainer.Star:Clone().Parent = bonusStageTeleporterInterfaceClone.Container.Content.StarContainer
				end

				bonusStageTeleporterInterfaceClone.Parent = teleporterObject.PrimaryPart
			end

			-- Player touched the teleporter.
			teleporterObject.PrimaryPart.Touched:Connect(function(hit)
				local player = coreModule.Services.Players:GetPlayerFromCharacter(hit.Parent)

				-- Guard clauses to make sure everything is valid.
				if not utilitiesLibrary.IsPlayerAlive(player) then return end
				if teleporterObjectsManager.IsWaitingOnPlayerConsent(player) then return end

				bonusStagesManager.SimulateTeleportation(player, teleporterObject, bonusStageLevelReference)
			end)
		elseif teleporterObject:IsA("Model") then
			coreModule.Debug(
				("Teleporter: %s, has PrimaryPart: %s, exists in LevelStorage.BonusStages: %s"):format(teleporterObject:GetFullName(), tostring(teleporterObject.PrimaryPart ~= nil), tostring(workspace.Map.Gameplay.LevelStorage.BonusStages:FindFirstChild(teleporterObject.Name) ~= nil)),
				coreModule.Shared.Enums.DebugLevel.Exception,
				warn
			)
		end
	end

	-- Setting up the checkpoints.
	for _, bonusStageLevelReference in next, workspace.Map.Gameplay.LevelStorage.BonusStages:GetChildren() do
		if bonusStageLevelReference:FindFirstChild("Checkpoints") then

			-- Checkpoints have to be integer named and a BasePart; 1 - start, # - end.
			for _, checkpoint in next, bonusStageLevelReference.Checkpoints:GetChildren() do
				if checkpoint:IsA("BasePart") and tonumber(checkpoint.Name) then

					checkpoint.Touched:Connect(function(hit)
						local player = coreModule.Services.Players:GetPlayerFromCharacter(hit.Parent)

						-- Guard clauses to make sure everything is valid.
						if not utilitiesLibrary.IsPlayerAlive(player) then return end
						if not userDataManager.GetData(player) then return end
						if userDataManager.GetData(player).UserInformation.CurrentBonusStage ~= bonusStageLevelReference.Name then return end
						if userDataManager.GetData(player).UserInformation.CurrentBonusStageCheckpoint >= tonumber(checkpoint.Name) then return end
						local userData = userDataManager.GetData(player)

						-- Is this the end?
						if tonumber(checkpoint.Name) == #bonusStageLevelReference.Checkpoints:GetChildren() then
							if teleporterObjectsManager.IsWaitingOnPlayerConsent(player) then return end
							if player:DistanceFromCharacter(checkpoint.Position) > 50 then return end	-- Just an ambigious number to defend against exploiters.

							-- Update their data before we teleport them back.
							userData.UserInformation.CurrentBonusStage = ""
							userData.UserInformation.CurrentBonusStageCheckpoint = 1
							table.insert(userData.UserInformation.CompletedBonusStages, bonusStageLevelReference.Name)

							-- Do we award any badges?
							if badgeStorageLibrary.GetBadgeList("BonusStages") and badgeStorageLibrary.GetBadgeList("BonusStages")[bonusStageLevelReference.Name] then
								badgeLibrary.AwardBadge(player, badgeStorageLibrary.GetBadgeList("BonusStages")[bonusStageLevelReference.Name])
							end

							-- Send them back.
							bonusStagesManager.Remotes.PlaySoundEffect:FireClient(player, "Clapping")
							bonusStagesManager.Remotes.CheckpointInformationUpdated:FireClient(player, userData)
							teleportationManager.TeleportPlayer(player)
						else
							userData.UserInformation.CurrentBonusStageCheckpoint = tonumber(checkpoint.Name)
							checkpointsManager.Remotes.PlaySoundEffect:FireClient(player, "CheckpointTouched", {Parent = checkpoint}) 
						end

						-- Updated.
						bonusStagesManager.Remotes.CheckpointInformationUpdated:FireClient(player, userData)
					end)
				end
			end
		end
	end

	-- The client wants to teleport to a specific bonus stage.
	coreModule.Shared.GetObject("//Remotes.Gameplay.Stages.TeleportToBonusStage").OnServerEvent:Connect(function(player, bonusStageName)
		if typeof(bonusStageName) ~= "string" then return end
		if not workspace.Map.Gameplay.LevelStorage.BonusStages:FindFirstChild(bonusStageName) then return end
		if not teleporterObjectsManager.GetTeleportersContainer().BonusStages:FindFirstChild(bonusStageName) then return end
		if not utilitiesLibrary.IsPlayerAlive(player) then return end
		if teleporterObjectsManager.IsWaitingOnPlayerConsent(player) then return end

		-- All clear, let's do it!
		bonusStagesManager.SimulateTeleportation(
			player, 
			teleporterObjectsManager.GetTeleportersContainer().BonusStages:FindFirstChild(bonusStageName) , 
			workspace.Map.Gameplay.LevelStorage.BonusStages:FindFirstChild(bonusStageName)
		)
	end)
end


-- Methods
function bonusStagesManager.SimulateTeleportation(player, teleporterObject, bonusStageLevelReference)
	if not utilitiesLibrary.IsPlayerAlive(player) then return end
	if typeof(teleporterObject) ~= "Instance" or not teleporterObject.PrimaryPart then return end
	if typeof(bonusStageLevelReference) ~= "Instance" or not bonusStageLevelReference:FindFirstChild("Checkpoints") or not bonusStageLevelReference.Checkpoints:FindFirstChild("1") then return end
	if not userDataManager.GetData(player) then return end
	local userData = userDataManager.GetData(player)

	-- Now that we have the guard clauses we have to get consent to teleport them.
	if teleporterObjectsManager.GetTeleportationConsent(player, teleporterObject.Name, "Are you sure you want to teleport to <font color=\"#5352ed\"><b>"..teleporterObject.Name.."</b></font> bonus level?", bonusStageLevelReference:GetAttribute("BackgroundImage") or "http://www.roblox.com/asset/?id=5632150459") then
		userData.UserInformation.SpecialLocationIdentifier = coreModule.Shared.Enums.SpecialLocation.None
		userData.UserInformation.CurrentBonusStageCheckpoint = 1
		userData.UserInformation.CurrentBonusStage = teleporterObject.Name

		-- Now that we updated the data we can actually teleport them.
		teleportationManager.TeleportPlayer(player)
		bonusStagesManager.Remotes.CheckpointInformationUpdated:FireClient(player, userData)
	end
end


--
return bonusStagesManager
--[[

-- Variables
local bonusLevelTeleportersManager = {}

local coreModule = require(script:FindFirstAncestor("CoreModule"))
local teleporterManager = require(coreModule.GetObject("/Parent"))
local generalTeleportationManager = require(coreModule.GetObject("/Parent.Parent"))
local persistentDataManager = require(coreModule.GetObject("Game.PlayerManager.UserDataManager.PersistentData"))
local currencyLibrary = require(coreModule.GetObject("Libraries.CurrencyLibrary"))
local badgeLibrary = require(coreModule.GetObject("Libraries.BadgeLibrary"))
local utilitiesLibrary = require(coreModule.Shared.GetObject("Libraries.Utilities"))
local config = require(script.Config)

-- Initialize
function bonusLevelTeleportersManager.Initialize()
	if not workspace.Map.Teleporters:FindFirstChild("BonusLevels") then return end
	if not workspace.Map:FindFirstChild("Levels") then return end
	
	--
	coreModule.Shared.GetObject("//Remotes.TeleportToBonusLevel").OnServerEvent:Connect(function(player, bonusLevelName)
		if not workspace.Map.Levels:FindFirstChild(bonusLevelName) then return end
		if not utilitiesLibrary.IsPlayerAlive(player) then return end
		if generalTeleportationManager.IsPlayerBeingTeleported(player) then return end
		if not teleporterManager.IsTeleportationConsentGranted(player, coreModule.Shared.Enums.TeleportationConsentMode.Level, nil, bonusLevelName) then return end

		--
		local userData = persistentDataManager.GetData(player)
		userData.CurrentStats.IsInTherapy = false
		userData.CurrentStats.IsInVictory = false
		userData.CurrentStats.BonusLevelName = bonusLevelName
		userData.CurrentStats.CurrentUsingBonusLevelCheckpoint = 0
		generalTeleportationManager.TeleportPlayer(player)
		coreModule.Shared.GetObject("//Remotes.StageInformationUpdated"):FireClient(player, userData)
	end)
	
	--
	for _, teleporterContainer in next, workspace.Map.Teleporters.BonusLevels:GetChildren() do
		if teleporterContainer.PrimaryPart then
			teleporterContainer.PrimaryPart.Touched:Connect(function(hit)
				local player = coreModule.Services.Players:GetPlayerFromCharacter(hit.Parent)
				if not utilitiesLibrary.IsPlayerAlive(player) then return end
				if generalTeleportationManager.IsPlayerBeingTeleported(player) then return end
				if not teleporterManager.IsTeleportationConsentGranted(player, coreModule.Shared.Enums.TeleportationConsentMode.Level, teleporterContainer, teleporterContainer.Name) then return end
				
				--
				local userData = persistentDataManager.GetData(player)
				userData.CurrentStats.IsInTherapy = false
				userData.CurrentStats.IsInVictory = false
				userData.CurrentStats.BonusLevelName = teleporterContainer.Name
				userData.CurrentStats.CurrentUsingBonusLevelCheckpoint = 0
				generalTeleportationManager.TeleportPlayer(player)
				coreModule.Shared.GetObject("//Remotes.StageInformationUpdated"):FireClient(player, userData)
			end)
		end
	end
	
	--
	for _, levelContainer in next, workspace.Map.Levels:GetChildren() do
		if levelContainer:FindFirstChild("FinishingPoint") then
			levelContainer.FinishingPoint.Touched:Connect(function(hit)
				local player = coreModule.Services.Players:GetPlayerFromCharacter(hit.Parent)
				if not utilitiesLibrary.IsPlayerAlive(player) then return end
				if generalTeleportationManager.IsPlayerBeingTeleported(player) then return end
				if player:DistanceFromCharacter(levelContainer.FinishingPoint.Position) > 50 then return end
				
				--
				local userData = persistentDataManager.GetData(player)
				userData.CurrentStats.BonusLevelName = ""
				generalTeleportationManager.TeleportPlayer(player)
				coreModule.Shared.GetObject("//Remotes.StageInformationUpdated"):FireClient(player, userData)
				coreModule.Shared.GetObject("//Remotes.PlaySoundEffect"):FireClient(player, "Clapping")
				
				--
				if not userData.CurrentStats.BonusLevelsCompleted[levelContainer.Name] then
					userData.CurrentStats.BonusLevelsCompleted[levelContainer.Name] = true
					if game.GameId == 1626627486 then badgeLibrary.AwardBadge(player, config.BonusLevelBadgeIds[levelContainer.Name]) end
					if levelContainer:FindFirstChild("Config") then
						local bonusLevelConfig = require(levelContainer.Config)
						currencyLibrary.GiveCurrency(player, bonusLevelConfig.ManualReward or config.BonusLevelDifficultyRate*(bonusLevelConfig.Difficulty or 1))
					end
				end
			end)
			
			--
			if levelContainer:FindFirstChild("Checkpoints") then
				for _, v in next, levelContainer.Checkpoints:GetChildren() do
					if v:IsA("BasePart") and tonumber(v.Name) then
						v.Touched:Connect(function(hit)
							local player = coreModule.Services.Players:GetPlayerFromCharacter(hit.Parent)
							if not utilitiesLibrary.IsPlayerAlive(player) then return end
							if tonumber(v.Name) < persistentDataManager.GetData(player).CurrentStats.CurrentUsingBonusLevelCheckpoint then return end
							
							--
							coreModule.Shared.GetObject("//Remotes.PlaySoundEffect"):FireClient(player, "Checkpoint Touched")
							persistentDataManager.GetData(player).CurrentStats.CurrentUsingBonusLevelCheckpoint = tonumber(v.Name)
						end)
					end
				end
			end
		end
	end
end

--
return bonusLevelTeleportersManager
]]