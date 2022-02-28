local players: Players = game:GetService("Players")
local starterGui: StarterGui = game:GetService("StarterGui")

local PlayerUtilities = {}

-- This method is meant to counter a common issue that plagues developers.
-- Where the PlayerAdded connector won't be set in time before the first player joins.
-- Possibly creating game-breaking bugs.
function PlayerUtilities.CreatePlayerAddedWrapper(callbackFunction: (Player) -> ())  : RBXScriptConnection

    for _, player in next, players:GetPlayers() do
        callbackFunction(player)
    end

    return players.PlayerAdded:Connect(callbackFunction)
end

-- This method is meant to counter a common issue that plagues developers.
-- Where the CharacterAdded connector won't be set in time before the character is first added.
-- Possibly creating game-breaking bugs.
function PlayerUtilities.CreateCharacterAddedWrapper(player: Player, callbackFunction: (Model) -> ()) : RBXScriptConnection

    local function internalCharacterAddedWrapper(character: Model)
        if not PlayerUtilities.IsPlayerAlive(player) then
            repeat
                task.wait()
            until PlayerUtilities.IsPlayerAlive(player)
        end

        callbackFunction(character)
    end

    if player.Character then
        internalCharacterAddedWrapper(player.Character)
    end

    return player.CharacterAdded:Connect(internalCharacterAddedWrapper)
end

-- Returns whether or not the player's character is alive and valid.
function PlayerUtilities.IsPlayerAlive(player: Player?) : boolean
    player = player or players.LocalPlayer

    -- Now we start checking xP.
    if typeof(player) ~= "Instance" then return false end
    if not player:IsA("Player") then return false end
    if not player:IsDescendantOf(players) then return false end
    if not player.Character then return false end
    if not player.Character.PrimaryPart then return false end
    if not player.Character:IsDescendantOf(workspace) then return false end
    if not player.Character:FindFirstChild("Humanoid") then return false end
    if player.Character.Humanoid:GetState() == Enum.HumanoidStateType.Dead then return false end

    return true
end

-- Returns whether or not the player is an actual player.
function PlayerUtilities.IsPlayerValid(player: Player?) : boolean
	if typeof(player) ~= "Instance" then return false end
	if not player:IsA("Player") then return false end
	if not player:IsDescendantOf(players) then return false end

	return true
end

-- Reliably calls SetCore;
-- SetCore has a chance to not go through if the core was not registered yet.
function PlayerUtilities.SetCore(...)
    repeat
        task.wait()
    until pcall(starterGui.SetCore, starterGui, ...)
end

-- Reliably calls SetCoreGuiEnabled;
-- SetCoreGuiEnabled has a chance to not go through if the core was no registered yet.
function PlayerUtilities.SetCoreGuiEnabled(...)
    repeat
        task.wait()
    until pcall(starterGui.SetCoreGuiEnabled, starterGui, ...)
end

return PlayerUtilities
