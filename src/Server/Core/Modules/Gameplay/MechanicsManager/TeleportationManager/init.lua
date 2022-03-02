local starterPlayer: StarterPlayer = game:GetService("StarterPlayer")

local coreModule = require(script:FindFirstAncestor("Core"))
local userDataManager = require(coreModule.GetObject("Modules.Gameplay.PlayerManager.UserDataManager"))
local playerUtilities = require(coreModule.Shared.GetObject("Libraries.Utilities.PlayerUtilities"))
local instanceUtilities = require(coreModule.Shared.GetObject("Libraries.Utilities.InstanceUtilities"))
local physicsService = require(coreModule.Shared.GetObject("Libraries.Services.PhysicsService"))
local sharedConstants = require(coreModule.Shared.GetObject("Libraries.SharedConstants"))
local signal = require(coreModule.Shared.GetObject("Libraries.Signal"))
local powerupsManager	-- This is required in Initialize to avoid cyclic behavior.

local teleportationStateUpdatedRemote: RemoteEvent = coreModule.Shared.GetObject("//Remotes.Gameplay.Stages.TeleportationStateUpdated")
local restoreDefaultPlayerConditionsRemote: RemoteEvent = coreModule.Shared.GetObject("//Remotes.Gameplay.Miscellaneous.RestoreDefaultPlayerConditions")
local levelStorage: Instance = workspace.Map.Gameplay.LevelStorage
local bonusStageStorage: Instance? = workspace.Map.Gameplay.LevelStorage:FindFirstChild("BonusStages")

local TeleportationManager = {}
TeleportationManager.DebuggingEnabled = true
TeleportationManager.PlayersBeingTeleported = {}
TeleportationManager.PlayerTeleported = signal.new()

-- Initialize
function TeleportationManager.Initialize()
	if not workspace.Map.Gameplay:FindFirstChild("LevelStorage") then return end

	-- This is required in Initialize to avoid cyclic behavior.
	powerupsManager = require(coreModule.GetObject("Modules.Gameplay.MechanicsManager.PowerupManager"))

	-- Client wants to respawn.
	coreModule.Shared.GetObject("//Remotes.RespawnUser").OnServerEvent:Connect(TeleportationManager.TeleportPlayer)

	-- Loading modules.
	coreModule.LoadModule("/")
end

-- This translates the user's information + given data into a format that the private functions can utilize.
function TeleportationManager.TeleportPlayer(player: Player, overlayColor: Color3?) : boolean

	-- If these aren't true something bad has gone down.
	if not playerUtilities.IsPlayerAlive(player) then return false end
	if TeleportationManager.GetIsPlayerBeingTeleported(player) then return false end
	if not userDataManager.GetData(player) then return end

	-- We can start teleporting them then!
	return TeleportationManager._StartTeleportingPlayer(
		player,
		TeleportationManager._DetermineTeleportationCFrameFromUserData(player),
		overlayColor
	)
end

-- This method teleports the user to be ontop of a specific BasePart.
-- Returns whether or not it was successful.
function TeleportationManager.TeleportPlayerToPart(player: Player, part: BasePart, overlayColor: Color3?) : boolean

	-- If these aren't true something bad has gone down.
	if not playerUtilities.IsPlayerAlive(player) then return false end
	if TeleportationManager.GetIsPlayerBeingTeleported(player) then return false end

	-- We can start teleporting them then!
	return TeleportationManager._StartTeleportingPlayer(
		player,
		playerUtilities.GetSeamlessCFrameAbovePart(player, part),
		overlayColor
	)
end

-- This will restore the users conditions to be the default conditions.
-- Removing any effects, powerups, etc.
function TeleportationManager.RestorePlayerConditions(player: Player)

	-- If these are wrong something has gone horribly wrong.
	if not playerUtilities.IsPlayerAlive(player) then return end
	if not userDataManager.GetData(player) then return end

	local userData: {} = userDataManager.GetData(player)
	local character: Model = player.Character
	local humanoid: Humanoid = character.Humanoid

	-- First we start by removing all of their tags and updating the collisions.
	instanceUtilities.RemoveTags(player.Character)
	physicsService.SetCollectionsCollisionGroup(
		player.Character:GetChildren(),
		"Players"
	)

	-- Theres a chance that this method is called before this module is initialized.
	if powerupsManager then
		powerupsManager.RemoveAllPowerups(player)
	end

	-- Then we go into the nitty gritty and change tiny things.
	humanoid.Sit = false												-- SpinningPlatforms.
	humanoid.Health = humanoid.MaxHealth								-- DamagePlatforms.
	character.PrimaryPart.Velocity = Vector3.new()						-- Speed Powerup.
	humanoid.WalkSpeed = starterPlayer.CharacterWalkSpeed				-- Speed Powerup.
	humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)	-- SpinningPlatforms.
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)		-- SpinningPlatforms.

	-- We want the client to know that everyone was just restored.
	restoreDefaultPlayerConditionsRemote:FireClient(player, userData)

	-- Therapy Zone is a special bonus level where they are allowed to jump.
	if userData.UserInformation.CurrentBonusStage ~= "Therapy Zone" then
		humanoid.JumpHeight = starterPlayer.CharacterJumpHeight
	end
end

-- Returns whether or not this player is in the process of being teleported.
function TeleportationManager.GetIsPlayerBeingTeleported(player: Player) : boolean
	return not not TeleportationManager.PlayersBeingTeleported[player]
end

-- Sets whether or not this player is in the process of being teleported.
function TeleportationManager.SetIsPlayerBeingTeleported(player: Player, isPlayerBeingTeleported: boolean?)
	TeleportationManager.PlayersBeingTeleported[player] = if isPlayerBeingTeleported then true else nil
end

-- This method is what all of the other teleportation methods eventually call.
-- It handles the animations and all of the logic involved with teleportation.
function TeleportationManager._StartTeleportingPlayer(player: Player, cframe: CFrame, overlayColor: Color3?) : boolean

	-- Something horrible went wrong!
	if not playerUtilities.IsPlayerAlive(player) then return false end
	if TeleportationManager.GetIsPlayerBeingTeleported(player) then return false end

	TeleportationManager.SetIsPlayerBeingTeleported(player, true)

	-- We need to figure out these before we can move forward with the animation.
	local teleportationAnimationLength: number = sharedConstants.MECHANICS.TELEPORTATION_OVERLAY_ANIMATION_LENGTH / 2
	local finalOverlayColor: Color3 = overlayColor or sharedConstants.MECHANICS.TELEPORTATION_DEFAULT_OVERLAY_COLOR

	-- We want to first start the overlay animation.
	teleportationStateUpdatedRemote:InvokeClient(player, true, teleportationAnimationLength, finalOverlayColor)
	task.wait(teleportationAnimationLength)

	-- We need to double check if they're still alive after yielding though.
	if not playerUtilities.IsPlayerAlive(player) then
		TeleportationManager.SetIsPlayerBeingTeleported(player, false)
		teleportationStateUpdatedRemote:InvokeClient(player, false, teleportationAnimationLength, finalOverlayColor)
		return false
	end

	-- We need to restore their conditions and then move them.
	TeleportationManager.RestorePlayerConditions(player)
	player.Character:SetPrimaryPartCFrame(cframe)

	-- Now we want to finish the overlay animation.
	teleportationStateUpdatedRemote:InvokeClient(player, false, teleportationAnimationLength, finalOverlayColor)
	task.wait(teleportationAnimationLength)

	-- Now the player can teleport again!
	TeleportationManager.SetIsPlayerBeingTeleported(player, false)
	TeleportationManager.PlayerTeleported:Fire(player)

	return true
end

-- This method will determine where the exact cframe a player should be teleported to
-- based on their userdata.
function TeleportationManager._DetermineTeleportationCFrameFromUserData(player: Player) : CFrame

	-- If these aren't true something bad has gone down.
	if not playerUtilities.IsPlayerAlive(player) then return false end
	if not userDataManager.GetData(player) then return end

	-- This is where all the important stuff is at.
	local userData: {} = userDataManager.GetData(player)
	local currentBonusStageName: string = userData.UserInformation.CurrentBonusStage
	local currentBonusStageCheckpoint: number = userData.UserInformation.CurrentBonusStageCheckpoint
	local currentCheckpoint: number = userData.UserInformation.CurrentCheckpoint

	-- First we want to check for bonus stages.
	if userData.UserInformation.CurrentBonusStage ~= "" then

		-- Bonus stages don't exist?
		if not bonusStageStorage then

			userData.UserInformation.CurrentBonusStage = ""
			TeleportationManager._Debug(levelStorage:GetFullName() .. ".BonusStages")
			return TeleportationManager._DetermineTeleportationCFrameFromUserData(player)

		-- This bonus stage doesn't exist?
		elseif not bonusStageStorage:FindFirstChild(currentBonusStageName) then

			userData.UserInformation.CurrentBonusStage = ""
			TeleportationManager._Debug(bonusStageStorage:GetFullName() .. "[\"" .. currentBonusStageName .. "\"]")
			return TeleportationManager._DetermineTeleportationCFrameFromUserData(player)

		-- This bonus stage has no checkpoints?
		elseif not bonusStageStorage[currentBonusStageName]:FindFirstChild("Checkpoints") then

			userData.UserInformation.CurrentBonusStage = ""
			TeleportationManager._Debug(bonusStageStorage[currentBonusStageName]:GetFullName() .. ".Checkpoints")
			return TeleportationManager._DetermineTeleportationCFrameFromUserData(player)

		-- The SPECIFIC checkpoint doesn't exist.
		elseif not bonusStageStorage[currentBonusStageName].Checkpoints:FindFirstChild(currentBonusStageCheckpoint) then

			userData.UserInformation.CurrentBonusStage = ""
			TeleportationManager._Debug(bonusStageStorage[currentBonusStageName].Checkpoints:GetFullName() .. "[\"" .. currentBonusStageCheckpoint .. "\"]")
			return TeleportationManager._DetermineTeleportationCFrameFromUserData(player)
		end

		-- If it reached this point all is good.
		return playerUtilities.GetSeamlessCFrameAbovePart(
			player,
			bonusStageStorage[currentBonusStageName].Checkpoints[currentBonusStageCheckpoint]
		)
	end

	-- If they aren't at a bonus stage they must be at a normal stage.
	-- So we need to account for designer issues with that.

	-- CurrentCheckpoint doesn't exist as a child of Checkpoints.
	if not levelStorage.Checkpoints:FindFirstChild(currentCheckpoint) then

		userData.UserInformation.CurrentCheckpoint = 1
		TeleportationManager._Debug(levelStorage.Checkpoints:GetFullName() .. "[\"" .. currentCheckpoint .. "\"]")
		return TeleportationManager._DetermineTeleportationCFrameFromUserData(player)
	end

	-- We can teleport them to the correct checkpoint now.
	return playerUtilities.GetSeamlessCFrameAbovePart(
		player,
		levelStorage.Checkpoints[currentCheckpoint]
	)
end

-- A small debug function that will only print if TeleportationManager.DebuggingEnabled is true.
function TeleportationManager._Debug(debugMessage: string)
	if TeleportationManager.DebuggingEnabled then
		warn(debugMessage)
	end
end

return TeleportationManager
