-- Variables
local bonusStagesManager = {}
bonusStagesManager.Assets = {}
bonusStagesManager.Remotes = {}

local coreModule = require(script:FindFirstAncestor("Core"))
local teleporterObjectsManager = require(coreModule.GetObject("Modules.GameplayManager.MechanicsManager.TeleportationManager.TeleporterObjectsManager"))
local teleportationManager = require(coreModule.GetObject("Modules.GameplayManager.MechanicsManager.TeleportationManager"))
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
	bonusStagesManager.Remotes.MakeSystemMessage = coreModule.Shared.GetObject("//Remotes.Gameplay.Miscellaneous.MakeSystemMessage")

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
				if (bonusStageLevelReference:GetAttribute("Difficulty") or 1) > 0 then
					for index = 1, (bonusStageLevelReference:GetAttribute("Difficulty") or 1) - 1 do
						bonusStageTeleporterInterfaceClone.Container.Content.StarContainer.Star:Clone().Parent = bonusStageTeleporterInterfaceClone.Container.Content.StarContainer
					end
				else
					bonusStageTeleporterInterfaceClone.Container.Content.StarContainer.Star:Destroy()
				end

				bonusStageTeleporterInterfaceClone.Parent = teleporterObject.PrimaryPart
			end

			-- Player touched the teleporter.
			teleporterObject.PrimaryPart.Touched:Connect(function(hit)
				local player = game:GetService("Players"):GetPlayerFromCharacter(hit.Parent)

				-- Guard clauses to make sure everything is valid.
				if not utilitiesLibrary.IsPlayerAlive(player) then return end
				if teleporterObjectsManager.IsWaitingOnPlayerConsent(player) then return end

				bonusStagesManager.SimulateTeleportation(player, teleporterObject, bonusStageLevelReference)
			end)
		end
	end

	-- Setting up the checkpoints.
	for _, bonusStageLevelReference in next, workspace.Map.Gameplay.LevelStorage.BonusStages:GetChildren() do
		if bonusStageLevelReference:FindFirstChild("Checkpoints") then

			-- Checkpoints have to be integer named and a BasePart; 1 - start, # - end.
			for _, checkpoint in next, bonusStageLevelReference.Checkpoints:GetChildren() do
				if checkpoint:IsA("BasePart") and tonumber(checkpoint.Name) then

					checkpoint.Touched:Connect(function(hit)
						local player = game:GetService("Players"):GetPlayerFromCharacter(hit.Parent)

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
								bonusStagesManager.Remotes.MakeSystemMessage:FireAllClients(player.Name.." has completed "..bonusStageLevelReference.Name.."!")
							end

							-- Send them back.
							bonusStagesManager.Remotes.PlaySoundEffect:FireClient(player, "Clapping")
							bonusStagesManager.Remotes.CheckpointInformationUpdated:FireClient(player, userData)
							teleportationManager.TeleportPlayer(player)
						else
							userData.UserInformation.CurrentBonusStageCheckpoint = tonumber(checkpoint.Name)
							bonusStagesManager.Remotes.PlaySoundEffect:FireClient(player, "CheckpointTouched", {Parent = checkpoint}) 
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
		userData.UserInformation.CurrentBonusStageCheckpoint = 1
		userData.UserInformation.CurrentBonusStage = teleporterObject.Name

		-- Now that we updated the data we can actually teleport them.
		teleportationManager.TeleportPlayer(player)
		bonusStagesManager.Remotes.CheckpointInformationUpdated:FireClient(player, userData)
	end
end


--
return bonusStagesManager