-- Variables
local utilitiesLibrary = {}
local coreModule = require(script:FindFirstAncestor("CoreModule"))

-- Methods
-- Mostly used in addition with IsPlayerAlive but is still a useful function for type checking for Player.
function utilitiesLibrary.IsPlayerValid(player)
	if typeof(player) ~= "Instance" or not player:IsA("Player") then return end
	if not player:IsDescendantOf(coreModule.Services.Players) then return end

	return true
end


-- A super useful function that leaves almost 0 room for error to check if a player is alive.
function utilitiesLibrary.IsPlayerAlive(player)
	if not utilitiesLibrary.IsPlayerValid(player) then return end

	if not player.Character then return end
	if not player.Character.PrimaryPart then return end
	if not player.Character:FindFirstChildOfClass("Humanoid") then return end
	if not player.Character:FindFirstChild("HumanoidRootPart") then return end
	if player.Character:FindFirstChildOfClass("Humanoid"):GetState() == Enum.HumanoidStateType.Dead then return end

	return true
end


-- TODO: Even while stopping the animations they will still play as normal even though they're anchored.
function utilitiesLibrary.FreezePlayer(player, thawInstead)
	if not utilitiesLibrary.IsPlayerAlive(player) then return end

	-- Freeze them; Anchor their PrimaryPart and stop all Animations.
	if not thawInstead then
		player.Character.PrimaryPart.Anchored = true

		-- Stop all Animations
		if player.Character.Humanoid:FindFirstChild("Animator") then
			for _, playingAnimationTrack in next, player.Character.Humanoid.Animator:GetPlayingAnimationTracks() do
				playingAnimationTrack:Stop()
			end
		end

	-- Thaw them; Just unanchor their PrimaryPart
	else
		player.Character.PrimaryPart.Anchored = false
	end
end


--
return utilitiesLibrary