-- Variables
local teleportationManager = {}
teleportationManager.PlayersBeingTeleported = {}
teleportationManager.Remotes = {}
teleportationManager.PlayerTeleported = Instance.new("BindableEvent")

local coreModule = require(script:FindFirstAncestor("Core"))
local userDataManager = require(coreModule.GetObject("Modules.GameplayManager.PlayerManager.UserDataManager"))
local utilitiesLibrary = require(coreModule.Shared.GetObject("Libraries.Utilities"))

-- Initialize
function teleportationManager.Initialize()
	if not workspace.Map.Gameplay:FindFirstChild("LevelStorage") then return end
	teleportationManager.Remotes.TeleportationStateUpdated = coreModule.Shared.GetObject("//Remotes.Gameplay.Stages.TeleportationStateUpdated")
	teleportationManager.Remotes.RestoreDefaultPlayerConditions = coreModule.Shared.GetObject("//Remotes.Gameplay.Miscellaneous.RestoreDefaultPlayerConditions")

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
	if not utilitiesLibrary.IsPlayerAlive(player) then return end
	if not userDataManager.GetData(player) then return end
	local userData = userDataManager.GetData(player)

	-- If ManualTeleportationLocation is nil that means we assume they want to be teleported based on their userdata.
	if typeof(functionParamaters.ManualTeleportationLocation) == "nil" then

		-- Bonus Stages.
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
	if not utilitiesLibrary.IsPlayerAlive(player) then return end
	if not userDataManager.GetData(player) then return end

	-- Local imports.
	local powerupsManager = require(coreModule.GetObject("Modules.GameplayManager.MechanicsManager.PowerupsManager"))
	local collisionsLibrary = require(coreModule.Shared.GetObject("Libraries.Collisions"))
	local userData = userDataManager.GetData(player)

	-- Restoration.
	powerupsManager.RemoveAllPowerups(player)
	collisionsLibrary.SetDescendantsCollisionGroup(player.Character, "Players")

	player.Character.Humanoid.Health = player.Character.Humanoid.MaxHealth
	player.Character.PrimaryPart.Velocity = Vector3.new()
	player.Character.Humanoid.Sit = false
	player.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)

	teleportationManager.Remotes.RestoreDefaultPlayerConditions:FireClient(player, userData)

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
	if not utilitiesLibrary.IsPlayerAlive(player) then return end
	if not typeof(goalCFrame) == "CFrame" then return end
	if teleportationManager.IsPlayerBeingTeleported(player) then return end
	teleportationManager.PlayersBeingTeleported[player] = true

	-- We can start the effect.
	teleportationManager.Remotes.TeleportationStateUpdated:InvokeClient(player, true, script:GetAttribute("TeleportationAnimationLength") or 0.25, overlayColor or Color3.new(0, 0, 0))
	task.wait(script:GetAttribute("TeleportationAnimationLength") or 0.25)

	-- We need to double check if they're still alive after yielding though.
	if not utilitiesLibrary.IsPlayerAlive(player) then teleportationManager.PlayersBeingTeleported[player] = nil return end
	player.Character:SetPrimaryPartCFrame(goalCFrame)

	task.wait(script:GetAttribute("TeleportationAnimationLength") or 0.25)
	teleportationManager.Remotes.TeleportationStateUpdated:InvokeClient(player, false, script:GetAttribute("TeleportationAnimationLength") or 0.25, overlayColor or Color3.new(0, 0, 0))
	teleportationManager.PlayersBeingTeleported[player] = nil
	teleportationManager.PlayerTeleported:Fire(player)

	-- Do we restore player conditions?
	if restorePlayerConditions then
		teleportationManager.RestorePlayerConditions(player)
	end
end


function teleportationManager.TeleportPlayerPostTranslationToPlaceId(player, goalPlaceId, teleportOptions)
	if game:GetService("RunService"):IsStudio() then return end
	if not utilitiesLibrary.IsPlayerValid(player) then return end
	if not goalPlaceId or not tonumber(goalPlaceId) or tonumber(goalPlaceId) <= 0 then return end
	if teleportationManager.IsPlayerBeingTeleported(player) then return end
	teleportationManager.PlayersBeingTeleported[player] = true

	-- Setting up TeleportOptions.
	local validTeleportOptions = Instance.new("TeleportOptions")
	validTeleportOptions.ReservedServerAccessCode = teleportOptions and teleportOptions.ReservedServerAccessCode
	validTeleportOptions.ShouldReserveServer = teleportOptions and teleportOptions.ShouldReserveServer or false

	-- We can start the effect.
	teleportationManager.Remotes.TeleportationStateUpdated:InvokeClient(player, true)
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
		if utilitiesLibrary.IsPlayerValid(player) and not teleportationManager.IsPlayerBeingTeleported(player) then

			-- We can start the effect.
			teleportationManager.PlayersBeingTeleported[player] = true
			if teleportationManager.Remotes.TeleportationStateUpdated then
				teleportationManager.Remotes.TeleportationStateUpdated:InvokeClient(player, true)
			end

			pcall(game:GetService("TeleportService").TeleportAsync, game:GetService("TeleportService"), goalPlaceId, {player}, validTeleportOptions)
		end
	end
end


-- Get the perfect CFrame above a basepart using a little math.
function teleportationManager.GetSeamlessCFrameAboveBasePart(player, basePart)
	if not utilitiesLibrary.IsPlayerAlive(player) then return end
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