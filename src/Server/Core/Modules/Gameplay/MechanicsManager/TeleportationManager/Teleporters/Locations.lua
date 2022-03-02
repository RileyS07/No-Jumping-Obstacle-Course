local coreModule = require(script:FindFirstAncestor("Core"))
local teleportersManager = require(coreModule.GetObject("Modules.Gameplay.MechanicsManager.TeleportationManager.Teleporters"))
local teleportationManager = require(coreModule.GetObject("Modules.Gameplay.MechanicsManager.TeleportationManager"))
local playerUtilities = require(coreModule.Shared.GetObject("Libraries.Utilities.PlayerUtilities"))
local sharedConstants = require(coreModule.Shared.GetObject("Libraries.SharedConstants"))

local teleporterInterface: GuiObject = coreModule.Shared.GetObject("//Assets.Interfaces.TeleporterInterface")

local ThisTeleporterManager = {}

-- Initialize
function ThisTeleporterManager.Initialize()
	if not teleportersManager.GetTeleportersContainer():FindFirstChild("Locations") then return end

    -- We need to make sure all of these teleporters have a PrimaryPart and a valid Destination value.
    for _, teleporterObject: Instance in next, teleportersManager.GetTeleportersContainer().Locations:GetChildren() do
		if teleporterObject:IsA("Model") and teleporterObject.PrimaryPart and teleporterObject:FindFirstChild("Destination") then

			-- We need to make sure that the Destination is valid as well.
			local destinationValue: ObjectValue? = teleporterObject.Destination

			if not destinationValue:IsA("ObjectValue") or not destinationValue.Value or not destinationValue.Value:IsA("BasePart") then
				continue
			end

			-- Setting up the teleporter with the BonusStageTeleporterInterface; I do this procedurally so that it's easy for us to make changes to it.
			local teleporterInterfaceClone: GuiObject = teleporterInterface:Clone()

			-- All we want to do is show the destination.
			teleporterInterfaceClone.Container.Content.Author.Text = ""
			teleporterInterfaceClone.Container.Content.Title.Text = teleporterObject.Name
			teleporterInterfaceClone.Container.Content.StarContainer:Destroy()
			teleporterInterfaceClone.Parent = teleporterObject.PrimaryPart

            -- A player has touched this teleporter.
			-- So we want to ask them if they want to go to it's destination.
			teleporterObject.PrimaryPart.Touched:Connect(function(hit: BasePart)

				local player: Player? = game:GetService("Players"):GetPlayerFromCharacter(hit.Parent)

				if not playerUtilities.IsPlayerAlive(player) then return end
				if teleportersManager.GetIsWaitingOnPlayerConsent(player :: Player) then return end

				-- Here is where we ask if they want to teleport.
				local doesPlayerConsent: boolean = teleportersManager.GetTeleportationConsent(
					player,
					teleporterObject.Name,
					string.format(sharedConstants.TELEPORTERS.LOCATION_TELEPORTER_CONSENT_FORMAT, teleporterObject.Name)
				)

				-- Well do they?
				if doesPlayerConsent then
					teleportationManager.TeleportPlayerToPart(
						player,
						teleporterObject.Destination.Value,
						sharedConstants.TELEPORTERS.ANY_TELEPORTER_DEFAULT_OVERLAY_COLOR
					)
				end
			end)
		end
    end
end

return ThisTeleporterManager
