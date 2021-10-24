-- Variables
local playerUtilitiesLibrary = {}
local playersService = game:GetService("Players")
local starterGuiService = game:GetService("StarterGui")

-- Public Wrappers

-- This method is meant to counter a common issue that plagues developers.
-- Where the PlayerAdded connector won't be set in time before the first player joins.
-- Possibly creating game-breaking bugs.
function playerUtilitiesLibrary.CreatePlayerAddedWrapper(callbackFunction: (Player) -> ())  : RBXScriptConnection
    assert(typeof(callbackFunction) == "function", "Argument #1 expected function. Got " .. typeof(callbackFunction))

    for _, player: Player in next, playersService:GetPlayers() do
        callbackFunction(player)
    end

    return playersService.PlayerAdded:Connect(callbackFunction)
end

-- This method is meant to counter a common issue that plagues developers.
-- Where the CharacterAdded connector won't be set in time before the character is first added.
-- Possibly creating game-breaking bugs.
function playerUtilitiesLibrary.CreateCharacterAddedWrapper(player: Player, callbackFunction: (Model) -> ()) : RBXScriptConnection
    assert(typeof(player) == "Instance" and player:IsA("Player"), "Argument #1 expected Player. Got " .. typeof(player))
    assert(typeof(callbackFunction) == "function", "Argument #2 expected function. Got " .. typeof(callbackFunction))

    local function internalCharacterAddedWrapper(character: Model)
        if not playerUtilitiesLibrary.IsPlayerAlive(player) then
            repeat task.wait() until playerUtilitiesLibrary.IsPlayerAlive(player)
        end

        callbackFunction(character)
    end

    if player.Character then
        internalCharacterAddedWrapper(player.Character)
    end

    return player.CharacterAdded:Connect(internalCharacterAddedWrapper)
end

-- Public Methods

-- Returns whether or not the player's character is alive and valid.
function playerUtilitiesLibrary.IsPlayerAlive(player: Player?) : boolean
    player = player or playersService.LocalPlayer

    -- Now we start checking xP.
    if typeof(player) ~= "Instance" then return false end
    if not player:IsA("Player") then return false end
    if not player:IsDescendantOf(playersService) then return false end
    if not player.Character then return false end
    if not player.Character.PrimaryPart then return false end
    if not player.Character:IsDescendantOf(workspace) then return false end
    if not player.Character:FindFirstChild("Humanoid") then return false end
    if player.Character.Humanoid:GetState() == Enum.HumanoidStateType.Dead then return false end

    return true
end

-- Reliably calls SetCore;
-- SetCore has a chance to not go through if the core was not registered yet.
function playerUtilitiesLibrary.SetCore(...)
    repeat task.wait() until pcall(starterGuiService.SetCore, starterGuiService, ...)
end

-- Reliably calls SetCoreGuiEnabled;
-- SetCoreGuiEnabled has a chance to not go through if the core was no registered yet.
function playerUtilitiesLibrary.SetCoreGuiEnabled(...)
    repeat task.wait() until pcall(starterGuiService.SetCoreGuiEnabled, starterGuiService, ...)
end

--
return playerUtilitiesLibrary