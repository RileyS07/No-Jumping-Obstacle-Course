local players: Players = game:GetService("Players")

local coreModule = require(script:FindFirstAncestor("Core"))
local teleportersManager = require(coreModule.GetObject("Modules.Gameplay.MechanicsManager.TeleportationManager.Teleporters"))
local teleportationManager = require(coreModule.GetObject("Modules.Gameplay.MechanicsManager.TeleportationManager"))
local userDataManager = require(coreModule.GetObject("Modules.Gameplay.PlayerManager.UserDataManager"))
local playerUtilities = require(coreModule.Shared.GetObject("Libraries.Utilities.PlayerUtilities"))
local sharedConstants = require(coreModule.Shared.GetObject("Libraries.SharedConstants"))

local checkpointInformationUpdatedRemote: RemoteEvent = coreModule.Shared.GetObject("//Remotes.Gameplay.Stages.CheckpointInformationUpdated")
local teleporterInterface: GuiObject? = coreModule.Shared.GetObject("//Assets.Interfaces.TeleporterInterface")
local bonusStageStorage: Instance? = workspace.Map.Gameplay.LevelStorage:FindFirstChild("BonusStages")

local ThisTeleporterManager = {}

-- Initialize
function ThisTeleporterManager.Initialize()
	if not teleportersManager.GetTeleportersContainer():FindFirstChild("BonusStages") then return end
	if not bonusStageStorage then return end

	-- We need to make sure all of these teleporters have a PrimaryPart and a corresponding bonus stage.
	for _, teleporterObject: Instance in next, teleportersManager.GetTeleportersContainer().BonusStages:GetChildren() do
		if teleporterObject:IsA("Model") and teleporterObject.PrimaryPart and bonusStageStorage:FindFirstChild(teleporterObject.Name) then

			-- We need to keep track of what bonus stage this corresponds to.
			local correspondingBonusStage: Instance = bonusStageStorage:FindFirstChild(teleporterObject.Name) :: Instance
			local bonusStageDifficultyRating: number = correspondingBonusStage:GetAttribute("Difficulty") or sharedConstants.TELEPORTERS.ANY_TELEPORTER_DEFAULT_DIFFICULTY

			-- Setting up the teleporter with the BonusStageTeleporterInterface; I do this procedurally so that it's easy for us to make changes to it.
			local teleporterInterfaceClone: GuiObject = teleporterInterface:Clone()
			local starContainer: GuiObject = teleporterInterfaceClone.Container.Content.StarContainer

			teleporterInterfaceClone.Container.Content.Author.Text = correspondingBonusStage:GetAttribute("Author") or sharedConstants.TELEPORTERS.ANY_TELEPORTER_DEFAULT_AUTHOR
			teleporterInterfaceClone.Container.Content.Title.Text = teleporterObject.Name
			teleporterInterfaceClone.Parent = teleporterObject.PrimaryPart

			-- Creating the stars.
			for index = 1, sharedConstants.TELEPORTERS.ANY_TELEPORTER_MAXIMUM_DIFFICULTY do

				-- If the index > the difficulty rating we want an empty star.
				-- If its less than or equal to we want the full star.
				local starObject: GuiObject = if index <= bonusStageDifficultyRating then starContainer.FullStar else starContainer.EmptyStar
				starObject = starObject:Clone()

				starObject.LayoutOrder = index
				starObject.Visible = true
				starObject.Parent = starContainer
			end

            -- A player has touched this teleporter.
			-- So we want to ask them if they want to go to it's destination.
			teleporterObject.PrimaryPart.Touched:Connect(function(hit: BasePart)

				local player: Player? = players:GetPlayerFromCharacter(hit.Parent)

				if not playerUtilities.IsPlayerAlive(player) then return end
				if teleportersManager.GetIsWaitingOnPlayerConsent(player :: Player) then return end

				-- We need attempt to teleport the player to the bonus stage.
				ThisTeleporterManager._AttemptTeleportationToBonusStage(player, teleporterObject)
			end)
		end
	end

	-- The client wants to teleport to a specific bonus stage.
	coreModule.Shared.GetObject("//Remotes.Gameplay.Stages.TeleportToBonusStage").OnServerEvent:Connect(function(player: Player, bonusStageName: string)

		if not playerUtilities.IsPlayerAlive(player) then return end
		if not bonusStageStorage:FindFirstChild(bonusStageName) then return end
		if not teleportersManager.GetTeleportersContainer().BonusStages:FindFirstChild(bonusStageName) then return end
		if teleportersManager.GetIsWaitingOnPlayerConsent(player) then return end

		-- We can attempt to teleport them now.
		local teleporterObject: Instance = teleportersManager.GetTeleportersContainer().BonusStages:FindFirstChild(bonusStageName) :: Instance

		ThisTeleporterManager._AttemptTeleportationToBonusStage(player, teleporterObject)
	end)
end

-- Attempts to teleport the user to the given bonus stage.
function ThisTeleporterManager._AttemptTeleportationToBonusStage(player: Player, teleporterObject: Instance)

	if not playerUtilities.IsPlayerAlive(player) then return end
	if not userDataManager.GetData(player) then return end

	-- Here is where we ask if they want to teleport.
	local userData: {} = userDataManager.GetData(player)
	local doesPlayerConsent: boolean = teleportersManager.GetTeleportationConsent(
		player,
		teleporterObject.Name,
		string.format(sharedConstants.FORMATS.BONUS_STAGE_TELEPORTER_CONSENT_FORMAT, teleporterObject.Name)
	)

	-- Well do they?
	if doesPlayerConsent then

		-- We need to update their data first and foremost.
		userData.UserInformation.CurrentBonusStageCheckpoint = 1
		userData.UserInformation.CurrentBonusStage = teleporterObject.Name

		-- Now that we updated the data we can actually teleport them.
		teleportationManager.TeleportPlayer(player)
		checkpointInformationUpdatedRemote:FireClient(player, userData)
	end
end

return ThisTeleporterManager
