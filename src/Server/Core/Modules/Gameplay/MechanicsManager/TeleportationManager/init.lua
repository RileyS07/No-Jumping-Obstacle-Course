-- Variables
local teleportationManager = {}
teleportationManager.PlayersBeingTeleported = {}
teleportationManager.Remotes = {}
teleportationManager.PlayerTeleported = Instance.new("BindableEvent")

local coreModule = require(script:FindFirstAncestor("Core"))
local userDataManager = require(coreModule.GetObject("Modules.Gameplay.PlayerManager.UserDataManager"))
local playerUtilities = require(coreModule.Shared.GetObject("Libraries.Utilities.PlayerUtilities"))

local teleportationStateUpdatedRemote: RemoteEvent = coreModule.Shared.GetObject("//Remotes.Gameplay.Stages.TeleportationStateUpdated")
local restoreDefaultPlayerConditionsRemote: RemoteEvent = coreModule.Shared.GetObject("//Remotes.Gameplay.Miscellaneous.RestoreDefaultPlayerConditions")

-- Initialize
function teleportationManager.Initialize()
	if not workspace.Map.Gameplay:FindFirstChild("LevelStorage") then return end

	-- Loading modules.
	coreModule.LoadModule("/Checkpoints")
	coreModule.LoadModule("/RespawnPlatforms")
	coreModule.LoadModule("/TeleporterObjectsManager")

	-- Client wants to respawn.
	coreModule.Shared.GetObject("//Remotes.RespawnUser").OnServerEvent:Connect(function(player: Player)
		teleportationManager.TeleportPlayer(player)
	end)
end


-- Methods
-- This translates the user's information + given data into a format that the private functions can utilize.
function teleportationManager.TeleportPlayer(player, functionParamaters)
	functionParamaters = setmetatable(functionParamaters or {}, {__index = {
		ManualTeleportationLocation = nil,	-- This can be a Vector3/CFrame or a PlaceId.
		RestoreConditions = true,
		TeleportOptions = {},
		OverlayColor = nil
	}})

	-- Only two guard clauses here to see if they're alive and they have valid data; The individual specific sections will have their own guard clauses.
	if not playerUtilities.IsPlayerAlive(player) then return end
	if not userDataManager.GetData(player) then return end
	local userData = userDataManager.GetData(player)

	-- If ManualTeleportationLocation is nil that means we assume they want to be teleported based on their userdata.
	if typeof(functionParamaters.ManualTeleportationLocation) == "nil" then

		-- Bonus Stages.
		if userData.UserInformation.CurrentBonusStage ~= "" then

			-- BonusStages doesn't exist.
			if not workspace.Map.Gameplay.LevelStorage:FindFirstChild("BonusStages") then
				print("Workspace.Map.Gameplay.LevelStorage.BonusStages doesn't exist.", nil, warn)
				userData.UserInformation.CurrentBonusStage = ""
				teleportationManager.TeleportPlayer(player, functionParamaters)
				return

			-- CurrentBonusStage doesn't exist as a child of BonusStages.
			elseif not workspace.Map.Gameplay.LevelStorage.BonusStages:FindFirstChild(userData.UserInformation.CurrentBonusStage) then
				print("Workspace.Map.Gameplay.LevelStorage.BonusStages[\""..userData.UserInformation.CurrentBonusStage.."\"] doesn't exist.", nil, warn)
				userData.UserInformation.CurrentBonusStage = ""
				teleportationManager.TeleportPlayer(player, functionParamaters)
				return

			-- Checkpoints doesn't exist in the currentBonusStage
			elseif not workspace.Map.Gameplay.LevelStorage.BonusStages[userData.UserInformation.CurrentBonusStage]:FindFirstChild("Checkpoints") then
				print("Workspace.Map.Gameplay.LevelStorage.BonusStages[\""..userData.UserInformation.CurrentBonusStage.."\"].Checkpoints doesn't exist.", nil, warn)
				userData.UserInformation.CurrentBonusStage = ""
				teleportationManager.TeleportPlayer(player, functionParamaters)
				return

			-- The SPECIFIC checkpoint doesn't exist.
			elseif not workspace.Map.Gameplay.LevelStorage.BonusStages[userData.UserInformation.CurrentBonusStage].Checkpoints:FindFirstChild(userData.UserInformation.CurrentBonusStageCheckpoint) then
				print("Workspace.Map.Gameplay.LevelStorage.BonusStages[\""..userData.UserInformation.CurrentBonusStage.."\"].Checkpoints[\""..userData.UserInformation.CurrentBonusStageCheckpoint.."\"] doesn't exist.", nil, warn)
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
			print("Workspace.Map.Gameplay.LevelStorage.Checkpoints doesn't exist.", nil, warn)
			return

		-- CurrentCheckpoint doesn't exist as a child of Checkpoints.
		elseif not workspace.Map.Gameplay.LevelStorage.Checkpoints:FindFirstChild(userData.UserInformation.CurrentCheckpoint) then
			print("Workspace.Map.Gameplay.LevelStorage.Checkpoints[\""..userData.UserInformation.CurrentCheckpoint.."\"] doesn't exist.", nil, warn)
			return
		end

		-- Quick fix 2/3/2022. Just clamps their current checkpoint to their furthest.
		userData.UserInformation.CurrentCheckpoint = math.clamp(userData.UserInformation.CurrentCheckpoint, 1, userData.UserInformation.FarthestCheckpoint)

		-- If it reached this point all is good.
		return teleportationManager.TeleportPlayerPostTranslationToCFrame(
			player,
			teleportationManager.GetSeamlessCFrameAboveBasePart(player, workspace.Map.Gameplay.LevelStorage.Checkpoints[userData.UserInformation.CurrentCheckpoint]),
			functionParamaters.RestoreConditions,
			functionParamaters.OverlayColor
		)

	-- CFrame/Vector3 manually passed.
	elseif typeof(functionParamaters.ManualTeleportationLocation) == "CFrame" or typeof(functionParamaters.ManualTeleportationLocation) == "Vector3" then
		return teleportationManager.TeleportPlayerPostTranslationToCFrame(
			player,
			typeof(functionParamaters.ManualTeleportationLocation) == "Vector3" and CFrame.new(functionParamaters.ManualTeleportationLocation) or functionParamaters.ManualTeleportationLocation,
			functionParamaters.RestoreConditions,
			functionParamaters.OverlayColor
		)

	-- PlaceId.
	elseif tonumber(functionParamaters.ManualTeleportationLocation) then
		return teleportationManager.TeleportPlayerPostTranslationToPlaceId(player, functionParamaters.ManualTeleportationLocation, functionParamaters.TeleportOptions)
	end
end


-- This will restore the client to what it was like the second they joined with no modifiers.
function teleportationManager.RestorePlayerConditions(player)
	if not playerUtilities.IsPlayerAlive(player) then return end
	if not userDataManager.GetData(player) then return end

	-- Local imports.
	local powerupsManager = require(coreModule.GetObject("Modules.Gameplay.MechanicsManager.PowerupManager"))
	local physicsService = require(coreModule.Shared.GetObject("Libraries.Services.PhysicsService"))

	local userData = userDataManager.GetData(player)

	-- Restoration.
	powerupsManager.RemoveAllPowerups(player)
	physicsService.SetCollectionsCollisionGroup(player.Character:GetChildren(), "Players")

	player.Character.Humanoid.Health = player.Character.Humanoid.MaxHealth
	player.Character.PrimaryPart.Velocity = Vector3.new()
	player.Character.Humanoid.Sit = false
	player.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)

	restoreDefaultPlayerConditionsRemote:FireClient(player, userData)

	-- Remove tags.
	for _, collectionServiceTagName in next, game:GetService("CollectionService"):GetTags(player.Character) do
		game:GetService("CollectionService"):RemoveTag(player.Character, collectionServiceTagName)
	end

	-- Should we allow them to keep jumping?
	if userData.UserInformation.CurrentBonusStage ~= "Therapy Zone" then
		player.Character.Humanoid.JumpHeight = 0
		player.Character.Humanoid.JumpPower = 0
	end
end


function teleportationManager.IsPlayerBeingTeleported(player)
	return teleportationManager.PlayersBeingTeleported[player]
end


-- Private Methods
-- TeleportPlayer translates the data given into a format this method/TeleportPlayerPostTranslationToPlace can use.
function teleportationManager.TeleportPlayerPostTranslationToCFrame(player, goalCFrame, restorePlayerConditions, overlayColor: Color3?)
	if not playerUtilities.IsPlayerAlive(player) then return end
	if not typeof(goalCFrame) == "CFrame" then return end
	if teleportationManager.IsPlayerBeingTeleported(player) then return end
	teleportationManager.PlayersBeingTeleported[player] = true

	-- We can start the effect.
	local teleportationAnimationLength: number = script:GetAttribute("TeleportationAnimationLength") or 0.25
	teleportationStateUpdatedRemote:InvokeClient(player, true, teleportationAnimationLength, overlayColor or Color3.new(0, 0, 0))
	task.wait(teleportationAnimationLength)

	-- We need to double check if they're still alive after yielding though.
	if not playerUtilities.IsPlayerAlive(player) then
		teleportationManager.PlayersBeingTeleported[player] = nil
		teleportationStateUpdatedRemote:InvokeClient(player, false, teleportationAnimationLength, overlayColor or Color3.new(0, 0, 0))
		return
	end

	player.Character:SetPrimaryPartCFrame(goalCFrame)

	teleportationStateUpdatedRemote:InvokeClient(player, false, teleportationAnimationLength, overlayColor or Color3.new(0, 0, 0))
	task.wait(teleportationAnimationLength)
	teleportationManager.PlayersBeingTeleported[player] = nil
	teleportationManager.PlayerTeleported:Fire(player)

	-- Do we restore player conditions?
	if restorePlayerConditions then
		teleportationManager.RestorePlayerConditions(player)
	end
end


function teleportationManager.TeleportPlayerPostTranslationToPlaceId(player, goalPlaceId, teleportOptions)
	if game:GetService("RunService"):IsStudio() then return end
	if not playerUtilities.IsPlayerValid(player) then return end
	if not goalPlaceId or not tonumber(goalPlaceId) or tonumber(goalPlaceId) <= 0 then return end
	if teleportationManager.IsPlayerBeingTeleported(player) then return end
	teleportationManager.PlayersBeingTeleported[player] = true

	-- Setting up TeleportOptions.
	local validTeleportOptions = Instance.new("TeleportOptions")
	validTeleportOptions.ReservedServerAccessCode = teleportOptions and teleportOptions.ReservedServerAccessCode
	validTeleportOptions.ShouldReserveServer = teleportOptions and teleportOptions.ShouldReserveServer or false

	-- We can start the effect.
	teleportationStateUpdatedRemote:InvokeClient(player, true)
	pcall(game:GetService("TeleportService").TeleportAsync, game:GetService("TeleportService"), goalPlaceId, {player}, validTeleportOptions)
end


-- This is less secure than TeleportPlayerPostTranslationToPlaceId.
function teleportationManager.TeleportPlayerListPostTranslationToPlaceId(players, goalPlaceId, teleportOptions)
	if game:GetService("RunService"):IsStudio() then return end
	if typeof(players) ~= "table" then return end
	if not goalPlaceId or not tonumber(goalPlaceId) or tonumber(goalPlaceId) <= 0 then return end
	if typeof(teleportOptions) ~= "table" and typeof(teleportOptions) ~= "nil" then return end

	-- Setting up TeleportOptions.
	local validTeleportOptions = Instance.new("TeleportOptions")
	validTeleportOptions.ReservedServerAccessCode = teleportOptions and teleportOptions.ReservedServerAccessCode or ""
	validTeleportOptions.ShouldReserveServer = teleportOptions and teleportOptions.ShouldReserveServer or false

	-- We can start the effect.
	for _, player in next, players do
		if playerUtilities.IsPlayerValid(player) and not teleportationManager.IsPlayerBeingTeleported(player) then

			-- We can start the effect.
			teleportationManager.PlayersBeingTeleported[player] = true
			if teleportationStateUpdatedRemote then
				teleportationStateUpdatedRemote:InvokeClient(player, true)
			end

			pcall(game:GetService("TeleportService").TeleportAsync, game:GetService("TeleportService"), goalPlaceId, {player}, validTeleportOptions)
		end
	end
end


-- Get the perfect CFrame above a basepart using a little math.
function teleportationManager.GetSeamlessCFrameAboveBasePart(player, basePart)
	if not playerUtilities.IsPlayerAlive(player) then return end
	if typeof(basePart) ~= "Instance" or not basePart:IsA("BasePart") then return end

	-- No need to yield just give a possible answer.
	if player.Character:FindFirstChild("Left Leg") then
		return basePart.CFrame * CFrame.new(0, 5, 0)
	end

	-- sizeY/2 + legY + rootPartY + hipHeight
	return basePart.CFrame * CFrame.new(
		0,
		basePart.Size.Y/2 + player.Character["Left Leg"].Size.Y + player.Character.HumanoidRootPart.Size.Y + player.Character.Humanoid.HipHeight,
		0
	)
end


--
return teleportationManager