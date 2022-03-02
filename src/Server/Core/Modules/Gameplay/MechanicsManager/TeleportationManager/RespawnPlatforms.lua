local collectionService: CollectionService = game:GetService("CollectionService")
local players: Players = game:GetService("Players")

local coreModule = require(script:FindFirstAncestor("Core"))
local teleportationManager = require(coreModule.GetObject("Modules.Gameplay.MechanicsManager.TeleportationManager"))
local playerUtilities = require(coreModule.Shared.GetObject("Libraries.Utilities.PlayerUtilities"))

local thisPlatformContainer: Instance? = workspace.Map.Gameplay.PlatformerMechanics:FindFirstChild("RespawnPlatforms")

local ThisMechanicManager = {}

-- Initialize
function ThisMechanicManager.Initialize()
	if not thisPlatformContainer then return end

	-- Every descendant that is a BasePart of this collection will respawn them.
	for _, thisPlatform: Instance in next, (thisPlatformContainer :: Instance):GetDescendants() do

		if thisPlatform:IsA("BasePart") then
			thisPlatform.Touched:Connect(function(hit: BasePart)

				local player: Player? = players:GetPlayerFromCharacter(hit.Parent)
				if not playerUtilities.IsPlayerAlive(player) then return end
				if collectionService:HasTag(player.Character, "Forcefield") then return end

				-- Respawns them.
				teleportationManager.TeleportPlayer(player)
			end)
		end
	end
end

return ThisMechanicManager
