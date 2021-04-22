-- Variables
local teleportationManager = {}
teleportationManager.PlayersBeingTeleported = {}
teleportationManager.Remotes = {}

local coreModule = require(script:FindFirstAncestor("CoreModule"))
local userDataManager = require(coreModule.GetObject("Modules.GameplayManager.PlayerManager.UserDataManager"))
local utilitiesLibrary = require(coreModule.Shared.GetObject("Libraries.Utilities"))

-- Initialize
function teleportationManager.Initialize()
	if not workspace.Map.Gameplay:FindFirstChild("LevelStorage") then return end
	teleportationManager.Remotes.TeleportationStateUpdated = coreModule.Shared.GetObject("//Remotes.Gameplay.Stages.TeleportationStateUpdated")

	-- Loading modules.
	coreModule.LoadModule("/Checkpoints")
	coreModule.LoadModule("/RespawnPlatforms")
	coreModule.LoadModule("/TeleporterObjectsManager")
end


-- Methods
-- This translates the user's information + given data into a format that the private functions can utilize.
function teleportationManager.TeleportPlayer(player, functionParamaters)
	functionParamaters = setmetatable(functionParamaters or {}, {__index = {
		ManualTeleportationLocation = nil,	-- This can be a Vector3/CFrame or a PlaceId.
		RestoreConditions = true
	}})

	-- Only two guard clauses here to see if they're alive and they have valid data; The individual specific sections will have their own guard clauses.
	if not utilitiesLibrary.IsPlayerAlive(player) then return end
	if not userDataManager.GetData(player) then return end
	local userData = userDataManager.GetData(player)

	-- If ManualTeleportationLocation is nil that means we assume they want to be teleported based on their userdata.
	if not functionParamaters.ManualTeleportationLocation then
		
		-- TherapyZone.
		if userData.UserInformation.SpecialLocationIdentifier == coreModule.Shared.Enums.SpecialLocation.TherapyZone then

			-- TherapyZone doesn't exist.
			if not workspace.Map.Gameplay.LevelStorage:FindFirstChild("TherapyZone") then
				coreModule.Debug("Workspace.Map.Gameplay.LevelStorage.TherapyZone doesn't exist.", nil, warn)
				userData.UserInformation.SpecialLocationIdentifier = coreModule.Shared.Enums.SpecialLocation.None
				teleportationManager.TeleportPlayer(player, functionParamaters)
				return

			-- Teleporter doesn't exist.
			elseif workspace.Map.Gameplay.LevelStorage.TherapyZone:FindFirstChild("Teleporter") then
				coreModule.Debug("Workspace.Map.Gameplay.LevelStorage.TherapyZone.Teleporter doesn't exist.", nil, warn)
				userData.UserInformation.SpecialLocationIdentifier = coreModule.Shared.Enums.SpecialLocation.None
				teleportationManager.TeleportPlayer(player, functionParamaters)
				return
			end

			-- If it reached this point all is good.
			return teleportationManager.TeleportPlayerPostTranslationToCFrame(
				player, 
				teleportationManager.GetSeamlessCFrameAboveBasePart(player, workspace.Map.Gameplay.LevelStorage.TherapyZone.Teleporter),
				functionParamaters.RestoreConditions
			)

		-- VictoryZone.
		elseif userData.UserInformation.SpecialLocationIdentifier == coreModule.Shared.Enums.SpecialLocation.VictoryZone then
			
			-- VictoryZone doesn't exist.
			if not workspace.Map.Gameplay.LevelStorage:FindFirstChild("VictoryZone") then
				coreModule.Debug("Workspace.Map.Gameplay.LevelStorage.VictoryZone doesn't exist.", nil, warn)
				userData.UserInformation.SpecialLocationIdentifier = coreModule.Shared.Enums.SpecialLocation.None
				teleportationManager.TeleportPlayer(player, functionParamaters)
				return

			-- Teleporter doesn't exist.
			elseif workspace.Map.Gameplay.LevelStorage.VictoryZone:FindFirstChild("Teleporter") then
				coreModule.Debug("Workspace.Map.Gameplay.LevelStorage.VictoryZone.Teleporter doesn't exist.", nil, warn)
				userData.UserInformation.SpecialLocationIdentifier = coreModule.Shared.Enums.SpecialLocation.None
				teleportationManager.TeleportPlayer(player, functionParamaters)
				return
			end

			-- If it reached this point all is good.
			return teleportationManager.TeleportPlayerPostTranslationToCFrame(
				player, 
				teleportationManager.GetSeamlessCFrameAboveBasePart(player, workspace.Map.Gameplay.LevelStorage.VictoryZone.Teleporter),
				functionParamaters.RestoreConditions
			)
		end

		-- If the code reached this point that means userData.UserInformation.SpecialLocationIdentifier == coreModule.Shared.Enums.SpecialLocation.None.

		-- Bonus Stage.
		if userData.UserInformation.CurrentBonusStage ~= "" then
			
			-- BonusStages doesn't exist.
			if not workspace.Map.Gameplay.LevelStorage:FindFirstChild("BonusStages") then
				coreModule.Debug("Workspace.Map.Gameplay.LevelStorage.BonusStages doesn't exist.", nil, warn)
				userData.UserInformation.CurrentBonusStage = ""
				teleportationManager.TeleportPlayer(player, functionParamaters)
				return

			-- CurrentBonusStage doesn't exist as a child of BonusStages.
			elseif not workspace.Map.Gameplay.LevelStorage.BonusStages:FindFirstChild(userData.UserInformation.CurrentBonusStage) then
				coreModule.Debug("Workspace.Map.Gameplay.LevelStorage.BonusStages[\""..userData.UserInformation.CurrentBonusStage.."\"] doesn't exist.", nil, warn)
				userData.UserInformation.CurrentBonusStage = ""
				teleportationManager.TeleportPlayer(player, functionParamaters)
				return

			-- Checkpoints doesn't exist in the currentBonusStage
			elseif not workspace.Map.Gameplay.LevelStorage.BonusStages[userData.UserInformation.CurrentBonusStage]:FindFirstChild("Checkpoints") then
				coreModule.Debug("Workspace.Map.Gameplay.LevelStorage.BonusStages[\""..userData.UserInformation.CurrentBonusStage.."\"].Checkpoints doesn't exist.", nil, warn)
				userData.UserInformation.CurrentBonusStage = ""
				teleportationManager.TeleportPlayer(player, functionParamaters)
				return

			-- The SPECIFIC checkpoint doesn't exist.
			elseif not workspace.Map.Gameplay.LevelStorage.BonusStages[userData.UserInformation.CurrentBonusStage].Checkpoints:FindFirstChild(userData.UserInformation.CurrentBonusStageCheckpoint) then
				coreModule.Debug("Workspace.Map.Gameplay.LevelStorage.BonusStages[\""..userData.UserInformation.CurrentBonusStage.."\"].Checkpoints[\""..userData.UserInformation.CurrentBonusStageCheckpoint.."\"] doesn't exist.", nil, warn)
				userData.UserInformation.CurrentBonusStage = ""
				teleportationManager.TeleportPlayer(player, functionParamaters)
				return
			end

			-- If it reached this point all is good.
			return teleportationManager.TeleportPlayerPostTranslationToCFrame(
				player, 
				teleportationManager.GetSeamlessCFrameAboveBasePart(player, workspace.Map.Gameplay.LevelStorage.BonusStages[userData.UserInformation.CurrentBonusStage].Checkpoints[userData.UserInformation.CurrentBonusStageCheckpoint]),
				functionParamaters.RestoreConditions
			)
		end

		-- If the code reaches this point it assumes that they are nowhere special and not in a bonus stage, so it goes to their current checkpoint.

		-- Checkpoints doesn't exist.
		if not workspace.Map.Gameplay.LevelStorage:FindFirstChild("Checkpoints") then
			coreModule.Debug("Workspace.Map.Gameplay.LevelStorage.Checkpoints doesn't exist.", nil, warn)
			return

		-- CurrentCheckpoint doesn't exist as a child of Checkpoints.
		elseif not workspace.Map.Gameplay.LevelStorage.Checkpoints:FindFirstChild(userData.UserInformation.CurrentCheckpoint) then
			coreModule.Debug("Workspace.Map.Gameplay.LevelStorage.Checkpoints[\""..userData.UserInformation.CurrentCheckpoint.."\"] doesn't exist.", nil, warn)
			return
		end

		-- If it reached this point all is good.
		return teleportationManager.TeleportPlayerPostTranslationToCFrame(
			player, 
			teleportationManager.GetSeamlessCFrameAboveBasePart(player, workspace.Map.Gameplay.LevelStorage.Checkpoints[userData.UserInformation.CurrentCheckpoint]),
			functionParamaters.RestoreConditions
		)
	
	-- CFrame/Vector3 manually passed.
	elseif typeof(functionParamaters.ManualTeleportationLocation) == "CFrame" or typeof(functionParamaters.ManualTeleportationLocation) == "Vector3" then
		return teleportationManager.TeleportPlayerPostTranslationToCFrame(
			player, 
			typeof(functionParamaters.ManualTeleportationLocation) == "Vector3" and CFrame.new(functionParamaters.ManualTeleportationLocation) or functionParamaters.ManualTeleportationLocation,
			functionParamaters.RestoreConditions
		)

	-- PlaceId
	elseif tonumber(functionParamaters.ManualTeleportationLocation) then
		return teleportationManager.TeleportPlayerPostTranslationToPlaceId(player, functionParamaters.ManualTeleportationLocation)
	end
end


-- This will restore the client to what it was like the second they joined with no modifiers.
function teleportationManager.RestorePlayerConditions()

end


function teleportationManager.IsPlayerBeingTeleported(player)
	return teleportationManager.PlayersBeingTeleported[player]
end


-- Private Methods
-- TeleportPlayer translates the data given into a format this method/TeleportPlayerPostTranslationToPlace can use.
function teleportationManager.TeleportPlayerPostTranslationToCFrame(player, goalCFrame, restorePlayerConditions)
	if not utilitiesLibrary.IsPlayerAlive(player) then return end
	if not typeof(goalCFrame) == "CFrame" then return end
	if teleportationManager.IsPlayerBeingTeleported(player) then return end
	teleportationManager.PlayersBeingTeleported[player] = true

	-- We can start the effect.
	teleportationManager.Remotes.TeleportationStateUpdated:InvokeClient(player, true)
	wait(script:GetAttribute("TeleportationAnimationLength") or 0.5)

	-- We need to double check if they're still alive after yielding though.
	if not utilitiesLibrary.IsPlayerAlive(player) then teleportationManager.PlayersBeingTeleported[player] = nil return end
	player.Character:SetPrimaryPartCFrame(goalCFrame)

	wait(script:GetAttribute("TeleportationAnimationLength") or 0.5)
	teleportationManager.Remotes.TeleportationStateUpdated:InvokeClient(player, false)
	teleportationManager.PlayersBeingTeleported[player] = nil

	-- Do we restore player conditions?
	if restorePlayerConditions then
		teleportationManager.RestorePlayerConditions()
	end
end


function teleportationManager.TeleportPlayerPostTranslationToPlaceId(player, goalPlaceId)
	if coreModule.Services.RunService:IsStudio() then return end
	if not utilitiesLibrary.IsPlayerValid(player) then return end
	if not goalPlaceId or not tonumber(goalPlaceId) or tonumber(goalPlaceId) <= 0 then return end
	if teleportationManager.IsPlayerBeingTeleported(player) then return end
	teleportationManager.PlayersBeingTeleported[player] = true

	-- We can start the effect.
	teleportationManager.Remotes.TeleportationStateUpdated:InvokeClient(player, true)
	pcall(coreModule.Services.TeleportService.TeleportAsync, coreModule.Services.TeleportService, goalPlaceId, {player})
end


-- Get the perfect CFrame above a basepart using a little math.
function teleportationManager.GetSeamlessCFrameAboveBasePart(player, basePart)
	if not utilitiesLibrary.IsPlayerAlive(player) then return end
	if typeof(basePart) ~= "Instance" or not basePart:IsA("BasePart") then return end

	-- No need to yield just give a possible answer.
	if player.Character:FindFirstChild("Left Leg") then
		return basePart.CFrame*CFrame.new(0, 5, 0)
	end

	-- sizeY/2 + legY + rootPartY + hipHeight
	return basePart.CFrame*CFrame.new(
		0, 
		basePart.Size.Y/2 + player.Character["Left Leg"].Size.Y + player.Character.HumanoidRootPart.Size.Y + player.Character.Humanoid.HipHeight,
		0
	)
end


--
return teleportationManager