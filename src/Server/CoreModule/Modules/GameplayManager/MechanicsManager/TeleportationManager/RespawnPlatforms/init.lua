-- Variables
local respawnPlatformsManager = {}
respawnPlatformsManager.PlatformMechanicContainer = nil

local coreModule = require(script:FindFirstAncestor("CoreModule"))
local userDataManager = require(coreModule.GetObject("Modules.GameplayManager.PlayerManager.UserDataManager"))
local badgeLibrary = require(coreModule.GetObject("Libraries.BadgeLibrary"))
local utilitiesLibrary = require(coreModule.Shared.GetObject("Libraries.Utilities"))

-- Initialize
function respawnPlatformsManager.Initialize()
	if not workspace.Map.Gameplay.PlatformerMechanics:FindFirstChild("RespawnPlatforms") then return end
	respawnPlatformsManager.PlatformMechanicContainer = workspace.Map.Gameplay.PlatformerMechanics.RespawnPlatforms
	
	-- Setup
	for _, respawnPlatform in next, respawnPlatformsManager.PlatformMechanicContainer:GetDescendants() do
		if respawnPlatform:IsA("BasePart") then
			respawnPlatform.Touched:Connect(function(hit)
				local player = coreModule.Services.Players:GetPlayerFromCharacter(hit.Parent)
				if not utilitiesLibrary.IsPlayerAlive(player) then return end
				
				if coreModule.Services.CollectionService:HasTag(player.Character, "RespawnPlatformExceptionTag") then return end
				if hit.Name:match("%a+ %a+") and respawnPlatformsManager.PlatformMechanicContainer:FindFirstChild("Miscellaneous") then
					
					-- So this section of code has to deal with your limbs touching a respawn platform due to your animation and not due to normal collision
					if not respawnPlatform:IsDescendantOf(respawnPlatformsManager.PlatformMechanicContainer.Miscellaneous) then
						local commonRaycastParameters = RaycastParams.new()
						commonRaycastParameters.FilterType = Enum.RaycastFilterType.Whitelist
						commonRaycastParameters.FilterDescendantsInstances = {respawnPlatform}
						
						local commonRaycastDirectionVector = Vector3.FromNormalId(Enum.NormalId.Bottom)*10
						
						-- PrimaryPart Test; We do this first to save on computation because if your primarypart is over the platform you are for sure properly colliding with it
						local primaryPartRaycastCheckResults = workspace:Raycast(player.Character:GetPrimaryPartCFrame().Position, commonRaycastDirectionVector, commonRaycastParameters)
						if not primaryPartRaycastCheckResults then
							
							-- So now we have to check at the secondary point of collision
							local secondaryPointPosition = player.Character:GetPrimaryPartCFrame().Position:Lerp(hit.Position, script:GetAttribute("InverseCollisionForgiveness"))
							local secondaryRaycastCheckResults = workspace:Raycast(secondaryPointPosition, commonRaycastDirectionVector, commonRaycastParameters)
							if not secondaryRaycastCheckResults then return end
						end
					end
				end
				
				-- 
				print("Collision passed all checks")
			end)
		end
	end
	 --[[
	 -- Variables
local resetStageProgressManager = {}

local coreModule = require(script:FindFirstAncestor("CoreModule"))
local generalTeleportationManager = require(coreModule.GetObject("/Parent"))
local utilitiesLibrary = require(coreModule.Shared.GetObject("Libraries.Utilities"))
local config = require(script.Config)

-- Initialize
function resetStageProgressManager.Initialize()
	if not workspace.Map:FindFirstChild("Sendbacks") then return end
	
	--
	for _, partThatResetsYourStageProgress in next, workspace.Map.Sendbacks:GetDescendants() do
		if partThatResetsYourStageProgress:IsA("BasePart") then
			partThatResetsYourStageProgress.Touched:Connect(function(hit)
				local player = coreModule.Services.Players:GetPlayerFromCharacter(hit.Parent)
				if not utilitiesLibrary.IsPlayerAlive(player) then return end
				if generalTeleportationManager.IsPlayerBeingTeleported(player) then return end
				if coreModule.Services.CollectionService:HasTag(player.Character, config.ResetStageProgressionExceptionTag) then return end
				if hit.Name:match("%a+ %a+") then
					if workspace.Map.Sendbacks:FindFirstChild("Baseplate") and not partThatResetsYourStageProgress:IsDescendantOf(workspace.Map.Sendbacks.Baseplate) then
						if math.abs(hit.CFrame.UpVector:Dot(Vector3.FromNormalId(Enum.NormalId.Top))) < 0.75 then
							return
						end
					end
				end
				
				--
				generalTeleportationManager.TeleportPlayer(player)
			end)
		end
	end
end

--
return resetStageProgressManager
	 ]]
end

--
return respawnPlatformsManager