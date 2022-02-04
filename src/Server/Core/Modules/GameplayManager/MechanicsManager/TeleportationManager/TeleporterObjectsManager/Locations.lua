-- Variables
local locationTeleporterManager = {}
local coreModule = require(script:FindFirstAncestor("Core"))
local teleporterObjectsManager = require(coreModule.GetObject("Modules.GameplayManager.MechanicsManager.TeleportationManager.TeleporterObjectsManager"))
local teleportationManager = require(coreModule.GetObject("Modules.GameplayManager.MechanicsManager.TeleportationManager"))
local utilitiesLibrary = require(coreModule.Shared.GetObject("Libraries.Utilities"))

-- Initialize
function locationTeleporterManager.Initialize()

    -- Fetching assets.
    local bonusStageTeleporterInterface = coreModule.Shared.GetObject("//Assets.Interfaces.BonusStageTeleporterInterface")

    -- Checking all of the teleporters.
    for _, teleporterObject in next, teleporterObjectsManager.GetTeleportersContainer().Locations:GetChildren() do
        if teleporterObject.PrimaryPart and teleporterObject:FindFirstChild("Destination") and teleporterObject.Destination.Value then
            print(teleporterObject)

            -- Setting up the teleporter with the BonusStageTeleporterInterface; I do this procedurally so that it's easy for us to make changes to it.
            if bonusStageTeleporterInterface then
				local bonusStageTeleporterInterfaceClone = bonusStageTeleporterInterface:Clone()

				-- Author, BackgroundImage, Title.
				bonusStageTeleporterInterfaceClone.Container.BackgroundImage.Image = teleporterObject:GetAttribute("BackgroundImage") or "http://www.roblox.com/asset/?id=5632150459"
				bonusStageTeleporterInterfaceClone.Container.Content.Author.Text = ""
				bonusStageTeleporterInterfaceClone.Container.Content.Title.Text = teleporterObject.Name
                bonusStageTeleporterInterfaceClone.Container.Content.StarContainer.Star:Destroy()
				bonusStageTeleporterInterfaceClone.Parent = teleporterObject.PrimaryPart
			end

            -- Player touched the teleporter.
			teleporterObject.PrimaryPart.Touched:Connect(function(hit)
				local player = game:GetService("Players"):GetPlayerFromCharacter(hit.Parent)

				-- Guard clauses to make sure everything is valid.
				if not utilitiesLibrary.IsPlayerAlive(player) then return end
				if teleporterObjectsManager.IsWaitingOnPlayerConsent(player) then return end

				locationTeleporterManager.SimulateTeleportation(player, teleporterObject)
			end)
        end
    end
end

-- This method was copied straight from BonusStages.lua; Just teleports them if possible.
function locationTeleporterManager.SimulateTeleportation(player: Player, teleporterObject: Model)
	if not utilitiesLibrary.IsPlayerAlive(player) then return end
	if typeof(teleporterObject) ~= "Instance" or not teleporterObject.PrimaryPart then return end

	-- Now that we have the guard clauses we have to get consent to teleport them.
	if teleporterObjectsManager.GetTeleportationConsent(player, teleporterObject.Name, "Are you sure you want to teleport to <font color=\"#5352ed\"><b>"..teleporterObject.Name.."</b></font>?", teleporterObject:GetAttribute("BackgroundImage")) then

		-- Now that we updated the data we can actually teleport them.
		teleportationManager.TeleportPlayer(player, {
            ManualTeleportationLocation = teleportationManager.GetSeamlessCFrameAboveBasePart(player, teleporterObject.Destination.Value),
            OverlayColor = Color3.new(1, 1, 1)
        })
	end
end

--
return locationTeleporterManager