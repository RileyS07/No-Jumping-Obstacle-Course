-- Variables
local respawnPlatformsManager = {}
respawnPlatformsManager.MechanicContainer = nil

local coreModule = require(script:FindFirstAncestor("Core"))
local teleportationManager = require(coreModule.GetObject("Modules.Gameplay.MechanicsManager.TeleportationManager"))
--local userDataManager = require(coreModule.GetObject("Modules.Gameplay.PlayerManager.UserDataManager"))
--local badgeLibrary = require(coreModule.GetObject("Libraries.BadgeLibrary"))
local utilitiesLibrary = require(coreModule.Shared.GetObject("Libraries._Utilities"))

-- Initialize
function respawnPlatformsManager.Initialize()
	if not workspace.Map.Gameplay.PlatformerMechanics:FindFirstChild("RespawnPlatforms") then return end
	respawnPlatformsManager.MechanicContainer = workspace.Map.Gameplay.PlatformerMechanics.RespawnPlatforms

	-- Setting up the platforms to be functional.
	for _, respawnPlatform in next, respawnPlatformsManager.MechanicContainer:GetDescendants() do
		if respawnPlatform:IsA("BasePart") then

			-- When they're touched you'll respawn.
			respawnPlatform.Touched:Connect(function(hit)

				-- Guard clauses to make sure the player is alive and doesn't have an exception tag.
				local player = game:GetService("Players"):GetPlayerFromCharacter(hit.Parent)
				if not utilitiesLibrary.IsPlayerAlive(player) then return end
				if game:GetService("CollectionService"):HasTag(player.Character, "Forcefield") then return end

				--[[
					This is where the fun stuff happens.
					The following code is an attempt to find a compromise between normal collisions and animation caused collisions.
				]]

				if hit.Name:match("%a+ %a+") and respawnPlatformsManager.MechanicContainer:FindFirstChild("Miscellaneous") and script:GetAttribute("InverseCollisionForgiveness") then

					-- Miscellaneous contains things such as the Baseplate which will never be accidentally collided with.
					if not respawnPlatform:IsDescendantOf(respawnPlatformsManager.MechanicContainer.Miscellaneous) then
						local commonRaycastParameters = RaycastParams.new()
						commonRaycastParameters.FilterType = Enum.RaycastFilterType.Whitelist
						commonRaycastParameters.FilterDescendantsInstances = {respawnPlatform}

						local commonRaycastDirectionVector = Vector3.FromNormalId(Enum.NormalId.Bottom)*10

						-- PrimaryPart Test; We do this first to save on computation because if your primarypart is over the platform you are for sure properly colliding with it.
						local primaryPartRaycastCheckResults = workspace:Raycast(player.Character:GetPrimaryPartCFrame().Position, commonRaycastDirectionVector, commonRaycastParameters)
						if not primaryPartRaycastCheckResults then

							-- So now we have to check at the secondary point of collision.
							local secondaryPointPosition = player.Character:GetPrimaryPartCFrame().Position:Lerp(hit.Position, script:GetAttribute("InverseCollisionForgiveness"))
							local secondaryRaycastCheckResults = workspace:Raycast(secondaryPointPosition, commonRaycastDirectionVector, commonRaycastParameters)
							if not secondaryRaycastCheckResults then return end
						end
					end
				end

				-- Respawns them.
				teleportationManager.TeleportPlayer(player)
			end)
		end
	end
end


--
return respawnPlatformsManager