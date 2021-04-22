-- Variables
local bonusStagesManager = {}

-- Initialize
function bonusStagesManager.Initialize()

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